DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vm_cod_tran	CHAR(2)
DEFINE vm_num_tran	LIKE cxpt028.p28_num_ret



MAIN

	IF num_args() <> 6 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE SERVIDOR COMPANIA',
			' LOCALIDAD COD_TRAN NUM_TRAN.'
		EXIT PROGRAM
	END IF
	LET base_ori    = arg_val(1)
	LET serv_ori    = arg_val(2)
	LET vg_codcia   = arg_val(3)
	LET vg_codloc   = arg_val(4)
	LET vm_cod_tran = arg_val(5)
	LET vm_num_tran = arg_val(6)
	CALL ejecuta_proceso()

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE r_reg		RECORD
				razonsocial		VARCHAR(60),
				ruc			CHAR(13),
				estab			CHAR(3),
				ptoemi			CHAR(3),
				secuencial		CHAR(9),
				dirmatriz		VARCHAR(100),
				fechaemision		CHAR(10),
				direstablecimiento	VARCHAR(100),
				contribuyenteespe	VARCHAR(5),
				obligadocontabili	VARCHAR(2),
				tipoidentificacio	VARCHAR(2),
				razonsocialcompra	VARCHAR(100),
				identificacioncom	VARCHAR(13),
				periodofiscal		VARCHAR(7),
				codigoiva		VARCHAR(1),
				codigoretencion		VARCHAR(5),
				baseimponible		DECIMAL(12,2),
				porcentajereten		DECIMAL(5,2),
				valorreten		DECIMAL(12,2),
				codsustento		VARCHAR(2),
				numfacsri		VARCHAR(15),
				fecemifact		VARCHAR(10),
				emailprov		VARCHAR(100),
				telfprov		VARCHAR(10),
				codprov			VARCHAR(6)
			END RECORD
DEFINE query		CHAR(4000)
DEFINE marc		CHAR(6)
DEFINE i, cont, lim	SMALLINT
DEFINE correo		LIKE cxct002.z02_email
DEFINE dirmat		LIKE gent002.g02_direccion

CALL activar_base(base_ori, serv_ori)
SET ISOLATION TO DIRTY READ
SELECT g02_direccion
	INTO dirmat
	FROM gent002
	WHERE g02_compania  = vg_codcia
	  AND g02_localidad = 3
LET query = 'SELECT g01_razonsocial AS razonsocial, ',
		'g02_numruc AS ruc, ',
		'LPAD(g02_serie_cia, 3, 0) AS estab, ',
		'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
		--'LPAD(NVL(TRIM(p29_num_sri[9,21]),0),9, 0) AS secuencial, ',
		'LPAD(p27_num_ret, 9, 0) AS secuencial, ',
		'"', dirmat CLIPPED, '" AS dirmatriz, ',
		'TO_CHAR(p27_fecing, "%d/%m/%Y") AS fechaemision, ',
		'CASE WHEN g02_localidad = 3 ',
			'THEN "AV. LA PRENSA - MATRIZ QUITO" ',
			'ELSE g02_direccion ',
		'END AS direstablecimiento, ',
		'"5368" AS contribuyenteespecial, ',
		'"SI" AS obligadocontabilidad, ',
		'(SELECT s03_codigo ',
			'FROM srit003 ',
			'WHERE s03_compania     = p28_compania ',
			'  AND s03_cod_ident    = p01_tipo_doc ',
			'  AND YEAR(s03_fecing) < 2007) AS tipoidentificacio, ',
		'p01_nomprov AS razonsocialcompra, ',
		'p01_num_doc AS identificacioncom, ',
		'TO_CHAR(p27_fecing, "%m/%Y") AS periodofiscal, ',
		'CASE WHEN p28_tipo_ret = "F" ',
			'THEN 1 ',
			'ELSE 2 ',
		'END AS codigoiva, ',
		'CASE WHEN p28_tipo_ret = "I" ',
			'THEN CASE WHEN p28_porcentaje = 30 THEN "1" ',
			'          WHEN p28_porcentaje = 70 THEN "2" ',
			'          WHEN p28_porcentaje = 100 THEN "3" ',
			'ELSE "" ',
			'END ',
			'ELSE p28_codigo_sri ',
		'END AS codigoretencion, ',
		'p28_valor_base AS baseimponible, ',
		'p28_porcentaje AS porcentajereten, ',
		'p28_valor_ret AS valorreten, ',
		'"01" AS codsustento, ',
		'p28_num_doc[1, 3] || ',
		'p28_num_doc[5, 7] || ',
		'LPAD(CAST(TRIM(p28_num_doc[9, 21]) AS INTEGER), ',
			'9, 0) AS numfacsri, ',
		'TO_CHAR(p20_fecha_emi, "%d/%m/%Y") AS fecemifact, ',
		'p02_email AS emailprov, ',
		'p01_telefono1 AS telfprov, ',
		'LPAD(p01_codprov, 6, 0) AS codprov ',
		'FROM cxpt027, cxpt028, cxpt029, cxpt020, cxpt001, cxpt002, ',
			'gent002, gent001 ',
		'WHERE p27_compania  = ', vg_codcia,
		'  AND p27_localidad = ', vg_codloc,
		'  AND p27_num_ret   = ', vm_num_tran,
		'  AND p27_estado    = "A" ',
		'  AND p28_compania  = p27_compania ',
		'  AND p28_localidad = p27_localidad ',
		'  AND p28_num_ret   = p27_num_ret ',
		'  AND p29_compania  = p27_compania ',
		'  AND p29_localidad = p27_localidad ',
		'  AND p29_num_ret   = p27_num_ret ',
		'  AND p20_compania  = p28_compania ',
		'  AND p20_localidad = p28_localidad ',
		'  AND p20_codprov   = p28_codprov ',
		'  AND p20_tipo_doc  = p28_tipo_doc ',
		'  AND p20_num_doc   = p28_num_doc ',
		'  AND p20_dividendo = p28_dividendo ',
		'  AND p02_compania  = p20_compania ',
		'  AND p02_localidad = p20_localidad ',
		'  AND p02_codprov   = p20_codprov ',
		'  AND p01_codprov   = p02_codprov ',
		'  AND g02_compania  = p02_compania ',
		'  AND g02_localidad = p02_localidad ',
		'  AND g01_compania  = g02_compania ',
		'INTO TEMP t1'
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
DISPLAY '<comprobanteRetencion id="comprobante" version="1.0.0">'
DECLARE q_cons CURSOR FOR
	SELECT * FROM t1
INITIALIZE r_reg.* TO NULL
OPEN q_cons
FETCH q_cons INTO r_reg.*
CLOSE q_cons
DISPLAY '<infoTributaria>'
DISPLAY '<razonSocial>', r_reg.razonsocial CLIPPED, '</razonSocial>'
DISPLAY '<nombreComercial>ACERO COMERCIAL</nombreComercial>'
DISPLAY '<ruc>', r_reg.ruc, '</ruc>'
DISPLAY '<estab>', r_reg.estab, '</estab>'
DISPLAY '<ptoEmi>', r_reg.ptoemi, '</ptoEmi>'
DISPLAY '<secuencial>', r_reg.secuencial, '</secuencial>'
DISPLAY '<dirMatriz>', r_reg.dirmatriz CLIPPED, '</dirMatriz>'
DISPLAY '</infoTributaria>'
DISPLAY '<infoCompRetencion>'
DISPLAY '<fechaEmision>', r_reg.fechaemision, '</fechaEmision>'
DISPLAY '<dirEstablecimiento>', r_reg.direstablecimiento CLIPPED, '</dirEstablecimiento>'
DISPLAY '<contribuyenteEspecial>', r_reg.contribuyenteespe CLIPPED, '</contribuyenteEspecial>'
DISPLAY '<obligadoContabilidad>', r_reg.obligadocontabili CLIPPED, '</obligadoContabilidad>'
DISPLAY '<tipoIdentificacionSujetoRetenido>', r_reg.tipoidentificacio, '</tipoIdentificacionSujetoRetenido>'
DISPLAY '<razonSocialSujetoRetenido>', r_reg.razonsocialcompra CLIPPED, '</razonSocialSujetoRetenido>'
DISPLAY '<identificacionSujetoRetenido>', r_reg.identificacioncom CLIPPED, '</identificacionSujetoRetenido>'
DISPLAY '<periodoFiscal>', r_reg.periodofiscal, '</periodoFiscal>'
DISPLAY '</infoCompRetencion>'
DISPLAY '<impuestos>'
INITIALIZE r_reg.* TO NULL
FOREACH q_cons INTO r_reg.*
	DISPLAY '<impuesto>'
	DISPLAY '<codigo>', r_reg.codigoiva CLIPPED, '</codigo>'
	IF r_reg.codigoretencion IS NOT NULL THEN
		DISPLAY '<codigoRetencion>', r_reg.codigoretencion CLIPPED, '</codigoRetencion>'
	END IF
	DISPLAY '<baseImponible>', r_reg.baseimponible USING "<<<<<<<<<&.##", '</baseImponible>'
	DISPLAY '<porcentajeRetener>', r_reg.porcentajereten USING "<<&.##", '</porcentajeRetener>'
	DISPLAY '<valorRetenido>', r_reg.valorreten USING "<<<<<<<<<&.##", '</valorRetenido>'
	DISPLAY '<codDocSustento>', r_reg.codsustento, '</codDocSustento>'
	DISPLAY '<numDocSustento>', r_reg.numfacsri, '</numDocSustento>'
	DISPLAY '<fechaEmisionDocSustento>', r_reg.fecemifact, '</fechaEmisionDocSustento>'
	DISPLAY '</impuesto>'
END FOREACH
DISPLAY '</impuestos>'
DISPLAY '<infoAdicional>'
IF r_reg.emailprov IS NULL THEN
	LET r_reg.emailprov = "facturacionelectronica@acerocomercial.com"
END IF
LET lim  = LENGTH(r_reg.emailprov)
LET cont = 0
FOR i = 1 TO lim
	IF r_reg.emailprov[i, i] = ";" THEN
		EXIT FOR
	END IF
	LET cont = cont + 1
END FOR
LET correo = r_reg.emailprov[1, cont] CLIPPED
DISPLAY '<campoAdicional nombre="Email">', correo CLIPPED, '</campoAdicional>'
IF cont < lim THEN
	LET cont   = cont + 2
	LET correo = r_reg.emailprov[cont, lim] CLIPPED
	IF correo IS NOT NULL THEN
		DISPLAY '<campoAdicional nombre="Email">', correo CLIPPED, '</campoAdicional>'
	END IF
END IF
DISPLAY '<campoAdicional nombre="telefono-movil">', r_reg.telfprov CLIPPED, '</campoAdicional>'
DISPLAY '<campoAdicional nombre="CodInternoSAP">', r_reg.codprov CLIPPED, '</campoAdicional>'
DISPLAY '</infoAdicional>'
DISPLAY '</comprobanteRetencion>'

END FUNCTION

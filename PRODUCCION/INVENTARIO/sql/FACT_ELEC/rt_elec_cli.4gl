DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vm_cod_tran	LIKE cajt014.j14_tipo_fuente
DEFINE vm_num_tran	LIKE cajt014.j14_num_fuente



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
				emailcli		VARCHAR(100),
				telfcli			VARCHAR(10),
				codcli			VARCHAR(6)
			END RECORD
DEFINE query		CHAR(5000)
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
		--'LPAD(NVL(TRIM(j14_num_ret_sri[9,21]),0),9, 0) AS secuencial, ',
		'LPAD(j14_num_fuente, 9, 0) AS secuencial, ',
		'"', dirmat CLIPPED, '" AS dirmatriz, ',
		'TO_CHAR(j14_fecha_emi, "%d/%m/%Y") AS fechaemision, ',
		'CASE WHEN g02_localidad = 3 ',
			'THEN "AV. LA PRENSA - MATRIZ QUITO" ',
			'ELSE g02_direccion ',
		'END AS direstablecimiento, ',
		'"5368" AS contribuyenteespecial, ',
		'"SI" AS obligadocontabilidad, ',
		'CASE WHEN z01_codcli = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = j14_compania) ',
			'THEN "07" ',
			'ELSE ',
			'(SELECT s03_codigo ',
			'FROM srit003 ',
			'WHERE s03_compania     = j14_compania ',
			'  AND s03_cod_ident    = z01_tipo_doc_id ',
			'  AND YEAR(s03_fecing) < 2007) ',
		'END AS tipoidentificacio, ',
		'j14_razon_social AS razonsocialcompra, ',
		'CASE WHEN z01_codcli = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = j14_compania) ',
			'THEN "9999999999999" ',
			'ELSE j14_cedruc ',
		'END AS identificacioncom, ',
		'TO_CHAR(j14_fecha_emi, "%m/%Y") AS periodofiscal, ',
		'CASE WHEN j14_tipo_ret = "F" ',
			'THEN 1 ',
			'ELSE 2 ',
		'END AS codigoiva, ',
		'CASE WHEN j14_tipo_ret = "I" ',
			'THEN CASE WHEN j14_porc_ret = 30 THEN "1" ',
			'          WHEN j14_porc_ret = 70 THEN "2" ',
			'          WHEN j14_porc_ret = 100 THEN "3" ',
			'ELSE "" ',
			'END ',
			'ELSE j14_codigo_sri ',
		'END AS codigoretencion, ',
		'j14_base_imp AS baseimponible, ',
		'j14_porc_ret AS porcentajereten, ',
		'j14_valor_ret AS valorreten, ',
		'"01" AS codsustento, ',
		'CASE WHEN j14_fec_emi_fact <= MDY(12, 31, 2014) ',
			'THEN ',
				'j14_num_fact_sri[1, 3] || ',
				'j14_num_fact_sri[5, 7] || ',
				'LPAD(CAST(TRIM(j14_num_fact_sri[9, 21]) ',
					'AS INTEGER), 9, 0) ',
			'ELSE ',
				'LPAD(g02_serie_cia, 3, 0) || ',
				'LPAD(g02_serie_loc, 3, 0) || ',
				'LPAD(j14_num_tran, 9, 0) ',
		'END AS numfacsri, ',
		'TO_CHAR(j14_fec_emi_fact, "%d/%m/%Y") AS fecemifact, ',
		'z02_email AS emailcli, ',
		'z01_telefono1 AS telfcli, ',
		'LPAD(z01_codcli, 6, 0) AS codcli ',
		'FROM cajt014, cajt010, cxct001, cxct002, gent002, gent001 ',
		'WHERE j14_compania    = ', vg_codcia,
		'  AND j14_localidad   = ', vg_codloc,
		'  AND j14_tipo_fuente = "', vm_cod_tran, '" ',
		'  AND j14_num_fuente  = ', vm_num_tran,
		'  AND j10_compania    = j14_compania ',
		'  AND j10_localidad   = j14_localidad ',
		'  AND j10_tipo_fuente = j14_tipo_fuente ',
		'  AND j10_num_fuente  = j14_num_fuente ',
		'  AND z02_compania    = j10_compania ',
		'  AND z02_localidad   = j10_localidad ',
		'  AND z02_codcli      = j10_codcli ',
		'  AND z01_codcli      = z02_codcli ',
		'  AND g02_compania    = z02_compania ',
		'  AND g02_localidad   = z02_localidad ',
		'  AND g01_compania    = g02_compania ',
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
IF r_reg.emailcli IS NULL THEN
	LET r_reg.emailcli = "facturacionelectronica@acerocomercial.com"
END IF
LET lim  = LENGTH(r_reg.emailcli)
LET cont = 0
FOR i = 1 TO lim
	IF r_reg.emailcli[i, i] = ";" THEN
		EXIT FOR
	END IF
	LET cont = cont + 1
END FOR
LET correo = r_reg.emailcli[1, cont] CLIPPED
DISPLAY '<campoAdicional nombre="Email">', correo CLIPPED, '</campoAdicional>'
IF cont < lim THEN
	LET cont   = cont + 2
	LET correo = r_reg.emailcli[cont, lim] CLIPPED
	IF correo IS NOT NULL THEN
		DISPLAY '<campoAdicional nombre="Email">', correo CLIPPED, '</campoAdicional>'
	END IF
END IF
DISPLAY '<campoAdicional nombre="telefono-movil">', r_reg.telfcli CLIPPED, '</campoAdicional>'
DISPLAY '<campoAdicional nombre="CodInternoSAP">', r_reg.codcli CLIPPED, '</campoAdicional>'
DISPLAY '</infoAdicional>'
DISPLAY '</comprobanteRetencion>'

END FUNCTION

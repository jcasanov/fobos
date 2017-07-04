DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vm_cod_tran	CHAR(2)
DEFINE vm_num_tran	LIKE rept095.r95_guia_remision



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
				direstablecimiento	VARCHAR(100),
				dirpartida		VARCHAR(150),
				razonsocialtransp	VARCHAR(100),
				tipoidentificacio	VARCHAR(2),
				ructransp		VARCHAR(13),
				obligadocontabili	VARCHAR(2),
				contribuyenteespe	VARCHAR(5),
				fechaini		CHAR(10),
				fechafin		CHAR(10),
				placa			VARCHAR(10),
				identificaciondest	CHAR(15),
				razonrsocialdest	VARCHAR(100),
				dirdestinatario		VARCHAR(150),
				motivotraslado		VARCHAR(100),
				fechaemidocsu		CHAR(10),
				codigointerno		VARCHAR(15),
				descripcion		VARCHAR(125),
				cantidad		DECIMAL(12,2),
				marca			VARCHAR(40),
				unid_med		VARCHAR(10),
				emailcli		VARCHAR(100),
				telfcli			VARCHAR(10),
				codcli			VARCHAR(6),
				proc_orden		VARCHAR(60)
			END RECORD
DEFINE query		CHAR(9000)
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
		--'LPAD(NVL(TRIM(r95_num_sri[9, 21]), 0), 9, 0) AS secuencial, ',
		'LPAD(r95_guia_remision, 9, 0) AS secuencial, ',
		'"', dirmat CLIPPED, '" AS dirmatriz, ',
		'CASE WHEN g02_localidad = 3 ',
			'THEN "AV. LA PRENSA - MATRIZ QUITO" ',
			'ELSE g02_direccion ',
		'END AS direstablecimiento, ',
		'r95_punto_part AS dirpartida, ',
		'r95_persona_guia AS razonsocialtransp, ',
		'(SELECT s03_codigo ',
			'FROM srit003 ',
			'WHERE s03_compania     = r95_compania ',
			'  AND s03_cod_ident    = ',
				'CASE WHEN LENGTH(r95_persona_id) = 13 ',
					'THEN "R" ',
					'ELSE "C" ',
				'END ',
			'  AND YEAR(s03_fecing) < 2007) AS tipoidentificacio, ',
		'r95_persona_id AS ructransp, ',
		'"SI" AS obligadocontabili, ',
		'"5368" AS contribuyenteespe, ',
		'TO_CHAR(r95_fecha_initras, "%d/%m/%Y") AS fechaini, ',
		'TO_CHAR(NVL(r95_fecha_fintras, r95_fecha_initras), "%d/%m/%Y") AS fechafin, ',
		'r95_placa AS placa, ',
		'r95_pers_id_dest AS identificaciondest, ',
		'r95_persona_dest AS razonrsocialdest, ',
		'r95_punto_lleg AS dirdestinatario, ',
		'CASE WHEN r95_motivo = "V" THEN "VENTA" ',
		'     WHEN r95_motivo = "D" THEN "DEVOLUCION" ',
		'     WHEN r95_motivo = "I" THEN "IMPORTACION" ',
		'     WHEN r95_motivo = "N" THEN "TRANSFERENCIAS ENTRE LOCALIDADES" ',
		'END AS motivotraslado, ',
		'TO_CHAR(r19_fecing, "%d/%m/%Y") AS fechaemidocsu, ',
		'r37_item AS codigointerno, ',
		'(SELECT r72_desc_clase ',
			'FROM rept072 ',
			'WHERE r72_compania  = r10_compania ',
			'  AND r72_linea     = r10_linea ',
			'  AND r72_sub_linea = r10_sub_linea ',
			'  AND r72_cod_grupo = r10_cod_grupo ',
			'  AND r72_cod_clase = r10_cod_clase) ',
			'|| " " || r10_nombre AS descripcion, ',
		'r37_cant_ent AS cantidad, ',
		'(SELECT r73_desc_marca ',
			'FROM rept073 ',
			'WHERE r73_compania = r10_compania ',
			'  AND r73_marca    = r10_marca) AS marca, ',
		'r10_uni_med AS unid_med, ',
		'(SELECT z02_email ',
			'FROM cxct002 ',
			'WHERE z02_compania  = r19_compania ',
			'  AND z02_localidad = r19_localidad ',
			'  AND z02_codcli    = r19_codcli) AS emailcli, ',
		'r19_telcli AS telfcli, ',
		'LPAD(r19_codcli, 6, 0) AS codcli, ',
		'r95_proc_orden AS proc_orden ',
		'FROM rept095, rept096, rept037, rept010, rept036, rept034, ',
			'rept019, gent002, gent001 ',
		'WHERE r95_compania      = ', vg_codcia,
		'  AND r95_localidad     = ', vg_codloc,
		'  AND r95_guia_remision = ', vm_num_tran,
		'  AND r95_estado        = "C" ',
		'  AND r96_compania      = r95_compania ',
		'  AND r96_localidad     = r95_localidad ',
		'  AND r96_guia_remision = r95_guia_remision ',
		'  AND r37_compania      = r96_compania ',
		'  AND r37_localidad     = r96_localidad ',
		'  AND r37_bodega        = r96_bodega ',
		'  AND r37_num_entrega   = r96_num_entrega ',
		'  AND r10_compania      = r37_compania ',
		'  AND r10_codigo        = r37_item ',
		'  AND r36_compania      = r37_compania ',
		'  AND r36_localidad     = r37_localidad ',
		'  AND r36_bodega        = r37_bodega ',
		'  AND r36_num_entrega   = r37_num_entrega ',
		'  AND r34_compania      = r36_compania ',
		'  AND r34_localidad     = r36_localidad ',
		'  AND r34_bodega        = r36_bodega ',
		'  AND r34_num_ord_des   = r36_num_ord_des ',
		'  AND r19_compania      = r34_compania ',
		'  AND r19_localidad     = r34_localidad ',
		'  AND r19_cod_tran      = r34_cod_tran ',
		'  AND r19_num_tran      = r34_num_tran ',
		'  AND g02_compania      = r19_compania ',
		'  AND g02_localidad     = r19_localidad ',
		'  AND g01_compania      = g02_compania ',
		'UNION ',
		'SELECT g01_razonsocial AS razonsocial, ',
		'g02_numruc AS ruc, ',
		'LPAD(g02_serie_cia, 3, 0) AS estab, ',
		'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
		--'LPAD(NVL(TRIM(r95_num_sri[9, 21]), 0), 9, 0) AS secuencial, ',
		'LPAD(r95_guia_remision, 9, 0) AS secuencial, ',
		'g02_direccion AS dirmatriz, ',
		'g02_direccion AS direstablecimiento, ',
		'r95_punto_part AS dirpartida, ',
		'r95_persona_guia AS razonsocialtransp, ',
		'(SELECT s03_codigo ',
			'FROM srit003 ',
			'WHERE s03_compania     = r95_compania ',
			'  AND s03_cod_ident    = ',
				'CASE WHEN LENGTH(r95_persona_id) = 13 ',
					'THEN "R" ',
					'ELSE "C" ',
				'END ',
			'  AND YEAR(s03_fecing) < 2007) AS tipoidentificacio, ',
		'r95_persona_id AS ructransp, ',
		'"SI" AS obligadocontabili, ',
		'"5368" AS contribuyenteespe, ',
		'TO_CHAR(r95_fecha_initras, "%d/%m/%Y") AS fechaini, ',
		'TO_CHAR(NVL(r95_fecha_fintras, r95_fecha_initras), "%d/%m/%Y") AS fechafin, ',
		'r95_placa AS placa, ',
		'r95_pers_id_dest AS identificaciondest, ',
		'r95_persona_dest AS razonrsocialdest, ',
		'r95_punto_lleg AS dirdestinatario, ',
		'CASE WHEN r95_motivo = "V" THEN "VENTA" ',
		'     WHEN r95_motivo = "D" THEN "DEVOLUCION" ',
		'     WHEN r95_motivo = "I" THEN "IMPORTACION" ',
		'     WHEN r95_motivo = "N" THEN "TRANSFERENCIAS ENTRE LOCALIDADES" ',
		'END AS motivotraslado, ',
		'TO_CHAR(r20_fecing, "%d/%m/%Y") AS fechaemidocsu, ',
		'r20_item AS codigointerno, ',
		'(SELECT r72_desc_clase ',
			'FROM rept072 ',
			'WHERE r72_compania  = r10_compania ',
			'  AND r72_linea     = r10_linea ',
			'  AND r72_sub_linea = r10_sub_linea ',
			'  AND r72_cod_grupo = r10_cod_grupo ',
			'  AND r72_cod_clase = r10_cod_clase) ',
			'|| " " || r10_nombre AS descripcion, ',
		'r20_cant_ven AS cantidad, ',
		'(SELECT r73_desc_marca ',
			'FROM rept073 ',
			'WHERE r73_compania = r10_compania ',
			'  AND r73_marca    = r10_marca) AS marca, ',
		'r10_uni_med AS unid_med, ',
		'CASE WHEN r19_codcli IS NULL ',
			'THEN g02_correo ',
			'ELSE (SELECT z02_email ',
				'FROM cxct002 ',
				'WHERE z02_compania  = r19_compania ',
				'  AND z02_localidad = r19_localidad ',
				'  AND z02_codcli    = r19_codcli) ',
		'END AS emailcli, ',
		'CASE WHEN r19_codcli IS NULL ',
			'THEN g02_telefono1 ',
			'ELSE r19_telcli ',
		'END AS telfcli, ',
		'LPAD(CASE WHEN r19_codcli IS NULL ',
			'THEN g02_localidad ',
			'ELSE r19_codcli ',
		'END, 6, 0) AS codcli, ',
		'r95_proc_orden AS proc_orden ',
		'FROM rept095, rept097, rept019, rept020, rept010, gent002,',
			' gent001 ',
		'WHERE r95_compania      = ', vg_codcia,
		'  AND r95_localidad     = ', vg_codloc,
		'  AND r95_guia_remision = ', vm_num_tran,
		'  AND r95_estado        = "C" ',
		'  AND r97_compania      = r95_compania ',
		'  AND r97_localidad     = r95_localidad ',
		'  AND r97_guia_remision = r95_guia_remision ',
		'  AND r97_cod_tran      = "TR" ',
		'  AND r19_compania      = r97_compania ',
		'  AND r19_localidad     = r97_localidad ',
		'  AND r19_cod_tran      = r97_cod_tran ',
		'  AND r19_num_tran      = r97_num_tran ',
		'  AND r20_compania      = r19_compania ',
		'  AND r20_localidad     = r19_localidad ',
		'  AND r20_cod_tran      = r19_cod_tran ',
		'  AND r20_num_tran      = r19_num_tran ',
		'  AND r10_compania      = r20_compania ',
		'  AND r10_codigo        = r20_item ',
		'  AND g02_compania      = r20_compania ',
		'  AND g02_localidad     = r20_localidad ',
		'  AND g01_compania      = g02_compania ',
		'INTO TEMP t1'
--display query clipped
--exit program
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
DISPLAY '<guiaRemision id="comprobante" version="1.0.0">'
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
DISPLAY '<infoGuiaRemision>'
DISPLAY '<dirEstablecimiento>', r_reg.direstablecimiento CLIPPED, '</dirEstablecimiento>'
DISPLAY '<dirPartida>', r_reg.dirpartida CLIPPED, '</dirPartida>'
DISPLAY '<razonSocialTransportista>', r_reg.razonsocialtransp CLIPPED, '</razonSocialTransportista>'
DISPLAY '<tipoIdentificacionTransportista>', r_reg.tipoidentificacio CLIPPED, '</tipoIdentificacionTransportista>'
DISPLAY '<rucTransportista>', r_reg.ructransp CLIPPED, '</rucTransportista>'
DISPLAY '<obligadoContabilidad>', r_reg.obligadocontabili CLIPPED, '</obligadoContabilidad>'
DISPLAY '<contribuyenteEspecial>', r_reg.contribuyenteespe CLIPPED, '</contribuyenteEspecial>'
DISPLAY '<fechaIniTransporte>', r_reg.fechaini CLIPPED, '</fechaIniTransporte>'
DISPLAY '<fechaFinTransporte>', r_reg.fechafin CLIPPED, '</fechaFinTransporte>'
DISPLAY '<placa>', r_reg.placa CLIPPED, '</placa>'
DISPLAY '</infoGuiaRemision>'
DISPLAY '<destinatarios>'
DISPLAY '<destinatario>'
DISPLAY '<identificacionDestinatario>', r_reg.identificaciondest CLIPPED, '</identificacionDestinatario>'
DISPLAY '<razonSocialDestinatario>', r_reg.razonrsocialdest CLIPPED, '</razonSocialDestinatario>'
DISPLAY '<dirDestinatario>', r_reg.dirdestinatario CLIPPED, '</dirDestinatario>'
DISPLAY '<motivoTraslado>', r_reg.motivotraslado CLIPPED, '</motivoTraslado>'
{-- CONSULTAR A INMOBEE
DISPLAY '<docAduaneroUnico>', r_reg. CLIPPED, '</docAduaneroUnico>'
DISPLAY '<codEstabDestino>', r_reg. CLIPPED, '</codEstabDestino>'
DISPLAY '<ruta>', r_reg. CLIPPED, '</ruta>'
DISPLAY '<codDocSustento>', r_reg. CLIPPED, '</codDocSustento>'
DISPLAY '<numDocSustento>', r_reg. CLIPPED, '</numDocSustento>'
DISPLAY '<numAutDocSustento>', r_reg. CLIPPED, '</numAutDocSustento>'
--}
DISPLAY '<fechaEmisionDocSustento>', r_reg.fechaemidocsu CLIPPED, '</fechaEmisionDocSustento>'
DISPLAY '<detalles>'
INITIALIZE r_reg.* TO NULL
FOREACH q_cons INTO r_reg.*
	DISPLAY '<detalle>'
	DISPLAY '<codigoInterno>', r_reg.codigointerno CLIPPED, '</codigoInterno>'
	DISPLAY '<descripcion>', r_reg.descripcion CLIPPED, '</descripcion>'
	DISPLAY '<cantidad>', r_reg.cantidad USING "<<<<<<<<<&.##", '</cantidad>'
	DISPLAY '<detallesAdicionales>'
	LET marc = r_reg.marca[1, 6]
	DISPLAY '<detAdicional nombre="MARCA" valor="', marc CLIPPED, '"/>'
	DISPLAY '<detAdicional nombre="UNIDAD" valor="', r_reg.unid_med CLIPPED, '"/>'
	DISPLAY '</detallesAdicionales>'
	DISPLAY '</detalle>'
END FOREACH
DISPLAY '</detalles>'
DISPLAY '</destinatario>'
DISPLAY '</destinatarios>'
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
IF r_reg.proc_orden IS NOT NULL THEN
	DISPLAY '<campoAdicional nombre="Proceso-Orden">', r_reg.proc_orden CLIPPED, '</campoAdicional>'
END IF
DISPLAY '</infoAdicional>'
DISPLAY '</guiaRemision>'

END FUNCTION

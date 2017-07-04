DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vm_estado	LIKE talt023.t23_estado
DEFINE vm_num_tran	LIKE talt023.t23_num_factura



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
	LET vm_estado   = arg_val(5)
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
				tipdocmodificado	VARCHAR(2),
				docmodificado		VARCHAR(17),
				fechafact		CHAR(10),
				razonsocialcompra	VARCHAR(100),
				identificacioncom	VARCHAR(13),
				totalsinimpuestos	DECIMAL(12,2),
				codigoiva		VARCHAR(1),
				codigoporcentaje	VARCHAR(4),
				baseimponible2		DECIMAL(12,2),
				valorimpuesto		DECIMAL(12,2),
				valormodifica		DECIMAL(12,2),
				motivo			VARCHAR(40),
				moneda			VARCHAR(6),
				codigointerno		VARCHAR(15),
				codigoadicional		VARCHAR(20),
				descripcion		VARCHAR(125),
				cantidad		DECIMAL(12,2),
				preciounitario		DECIMAL(12,2),
				descuento		DECIMAL(12,2),
				preciototalsinimp	DECIMAL(12,2),
				marca			VARCHAR(40),
				unidad			VARCHAR(10),
				codigoivadet		VARCHAR(1),
				codigoporcentdet	VARCHAR(4),
				tarifa			DECIMAL(5,2),
				baseimponibledet	DECIMAL(12,2),
				valorimpuestodet	DECIMAL(12,2),
				emailcli		VARCHAR(100),
				telfcli			VARCHAR(10),
				codcli			VARCHAR(6)
			END RECORD
DEFINE query		CHAR(5000)
DEFINE marc		CHAR(6)
DEFINE i, cont, lim	SMALLINT
DEFINE valor_det_mo	DECIMAL(16,2)
DEFINE valor_oc		DECIMAL(16,2)
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
		'LPAD(NVL((SELECT z21_num_doc ',
			'FROM cxct021 ',
			'WHERE z21_compania  = a.t23_compania ',
			'  AND z21_localidad = a.t23_localidad ',
			'  AND z21_codcli    = a.t23_cod_cliente ',
			'  AND z21_tipo_doc  = "NC" ',
			'  AND z21_cod_tran  = "FA" ',
			'  AND z21_num_tran  = a.t23_num_factura), ',
			'0), 9, 0) AS secuencial, ',
		'"', dirmat CLIPPED, '" AS dirmatriz, ',
		'TO_CHAR(t28_fec_anula, "%d/%m/%Y") AS fechaemision, ',
		'CASE WHEN g02_localidad = 3 ',
			'THEN "AV. LA PRENSA - MATRIZ QUITO" ',
			'ELSE g02_direccion ',
		'END AS direstablecimiento, ',
		'"5368" AS contribuyenteespe, ',
		'"SI" AS obligadocontabili, ',
		'CASE WHEN a.t23_cod_cliente = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = a.t23_compania) ',
			'THEN "07" ',
			'ELSE ',
			'(SELECT s03_codigo ',
			'FROM cxct001, srit003 ',
			'WHERE z01_codcli       = a.t23_cod_cliente ',
			'  AND s03_compania     = a.t23_compania ',
			'  AND s03_cod_ident    = z01_tipo_doc_id ',
			'  AND YEAR(s03_fecing) < 2007) ',
		'END AS tipoidentificacio, ',
		'"01" AS tipdocmodificado, ',
		'CASE WHEN DATE(a.t23_fec_factura) <= MDY(12, 31, 2014) ',
			'THEN ',
			'NVL((SELECT r38_num_sri[1, 8] || ',
			'LPAD(CAST(TRIM(r38_num_sri[9,21]) AS INTEGER), 9, 0) ',
				'FROM rept038 ',
				'WHERE r38_compania    = a.t23_compania ',
				'  AND r38_localidad   = a.t23_localidad ',
				'  AND r38_tipo_doc    = "FA" ',
				'  AND r38_tipo_fuente = "OT" ',
				'  AND r38_cod_tran    = "FA" ',
				'  AND r38_num_tran    = a.t23_num_factura), ',
			'"") ',
			'ELSE ',
				'LPAD(g02_serie_cia, 3, 0) || "-" || ',
				'LPAD(g02_serie_loc, 3, 0) || "-" || ',
				'LPAD(a.t23_num_factura, 9, 0) ',
		'END AS docmodificado, ',
		'TO_CHAR(a.t23_fec_factura, "%d/%m/%Y") AS fechafact, ',
		'a.t23_nom_cliente AS razonsocialcompra, ',
		'CASE WHEN a.t23_cod_cliente = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = a.t23_compania) ',
			'THEN "9999999999999" ',
			'ELSE a.t23_cedruc ',
		'END AS identificacioncom, ',
		'(a.t23_tot_bruto - a.t23_tot_dscto) AS totalsinimpuestos, ',
		'2 AS codigoiva, ',
		'CASE WHEN a.t23_porc_impto = 0  THEN 0 ',
		'     WHEN a.t23_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentaje, ',
		'(a.t23_tot_bruto - a.t23_tot_dscto) AS baseimponible2, ',
		'(a.t23_tot_neto - ',
		'(a.t23_tot_bruto - a.t23_tot_dscto)) AS valorimpuesto, ',
		'a.t23_tot_neto AS valormodifica, ',
		'"DEVOLUCION TALLER" AS motivo, ',
		'"DOLAR" AS moneda, ',
		'LPAD(a.t23_orden, 5, 0) AS codigointerno, ',
		'LPAD(a.t23_orden, 5, 0) AS codigoadicional, ',
		'"TOTAL OTROS REPUESTOS, MATERIALES Y MANO DE OBRA" AS descripcion, ',
		'1.00 AS cantidad, ',
		'(a.t23_val_mo_ext + a.t23_val_mo_cti + a.t23_val_rp_tal + ',
		'a.t23_val_rp_ext + a.t23_val_rp_cti + ',
		'a.t23_val_otros2 + a.t23_val_mo_tal) AS preciounitario, ',
		'a.t23_tot_dscto AS descuento, ',
		'((a.t23_val_mo_ext + a.t23_val_mo_cti + a.t23_val_rp_tal + ',
		'a.t23_val_rp_ext + a.t23_val_rp_cti + ',
		'a.t23_val_otros2 + a.t23_val_mo_tal) ',
		'- a.t23_tot_dscto) AS preciototalsinimp, ',
		'a.t23_modelo AS marca, ',
		'"UNI" AS unidad, ',
		'2 AS codigoivadet, ',
		'CASE WHEN a.t23_porc_impto = 0  THEN 0 ',
		'     WHEN a.t23_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentajedet, ',
		'a.t23_porc_impto AS tarifa, ',
		'((a.t23_val_mo_ext + a.t23_val_mo_cti + a.t23_val_rp_tal + ',
		'a.t23_val_rp_ext + a.t23_val_rp_cti + ',
		'a.t23_val_otros2 + a.t23_val_mo_tal) ',
		'- a.t23_tot_dscto) AS baseimponibledet, ',
		'a.t23_val_impto AS valorimpuestodet, ',
		'z02_email AS emailcli, ',
		'a.t23_tel_cliente AS telfcli, ',
		'a.t23_cod_cliente AS codcli ',
		'FROM talt028, talt023 a, cxct002, gent002, gent001 ',
		'WHERE t28_compania      = ', vg_codcia,
		'  AND t28_localidad     = ', vg_codloc,
		'  AND t28_num_dev       = ', vm_num_tran,
		'  AND a.t23_compania    = t28_compania ',
		'  AND a.t23_localidad   = t28_localidad ',
		'  AND a.t23_orden       = t28_ot_ant ',
		'  AND a.t23_num_factura = t28_factura ',
		'  AND a.t23_estado      = "', vm_estado, '" ',
		'  AND z02_compania      = a.t23_compania ',
		'  AND z02_localidad     = a.t23_localidad ',
		'  AND z02_codcli        = a.t23_cod_cliente ',
		'  AND g02_compania      = z02_compania ',
		'  AND g02_localidad     = z02_localidad ',
		'  AND g01_compania      = g02_compania ',
		'INTO TEMP t1'
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
DISPLAY '<notaCredito id="comprobante" version="1.0.0">'
DECLARE q_cons CURSOR FOR
	SELECT * FROM t1
INITIALIZE r_reg.* TO NULL
OPEN q_cons
FETCH q_cons INTO r_reg.*
CLOSE q_cons
-- OJO REVISAR EN FUTURAS OT (DIO PROBLEMAS CON FA-7821 LOC 3)
--CALL obtener_valor_oc() RETURNING valor_oc
LET valor_oc = 0.00
DISPLAY '<infoTributaria>'
DISPLAY '<razonSocial>', r_reg.razonsocial CLIPPED, '</razonSocial>'
DISPLAY '<nombreComercial>ACERO COMERCIAL</nombreComercial>'
DISPLAY '<ruc>', r_reg.ruc, '</ruc>'
DISPLAY '<estab>', r_reg.estab, '</estab>'
DISPLAY '<ptoEmi>', r_reg.ptoemi, '</ptoEmi>'
DISPLAY '<secuencial>', r_reg.secuencial, '</secuencial>'
DISPLAY '<dirMatriz>', r_reg.dirmatriz CLIPPED, '</dirMatriz>'
DISPLAY '</infoTributaria>'
DISPLAY '<infoNotaCredito>'
DISPLAY '<fechaEmision>', r_reg.fechaemision, '</fechaEmision>'
DISPLAY '<dirEstablecimiento>', r_reg.direstablecimiento CLIPPED, '</dirEstablecimiento>'
DISPLAY '<tipoIdentificacionComprador>', r_reg.tipoidentificacio, '</tipoIdentificacionComprador>'
DISPLAY '<razonSocialComprador>', r_reg.razonsocialcompra CLIPPED, '</razonSocialComprador>'
DISPLAY '<identificacionComprador>', r_reg.identificacioncom CLIPPED, '</identificacionComprador>'
DISPLAY '<contribuyenteEspecial>', r_reg.contribuyenteespe CLIPPED, '</contribuyenteEspecial>'
DISPLAY '<obligadoContabilidad>', r_reg.obligadocontabili CLIPPED, '</obligadoContabilidad>'
DISPLAY '<codDocModificado>', r_reg.tipdocmodificado CLIPPED, '</codDocModificado>'
DISPLAY '<numDocModificado>', r_reg.docmodificado CLIPPED, '</numDocModificado>'
DISPLAY '<fechaEmisionDocSustento>', r_reg.fechafact CLIPPED, '</fechaEmisionDocSustento>'
DISPLAY '<totalSinImpuestos>', r_reg.totalsinimpuestos USING "<<<<<<<<<&.##", '</totalSinImpuestos>'
DISPLAY '<valorModificacion>', r_reg.valormodifica USING "<<<<<<<<<&.##", '</valorModificacion>'
DISPLAY '<moneda>', r_reg.moneda, '</moneda>'
DISPLAY '<totalConImpuestos>'
DISPLAY '<totalImpuesto>'
DISPLAY '<codigo>', r_reg.codigoiva, '</codigo>'
DISPLAY '<codigoPorcentaje>', r_reg.codigoporcentaje, '</codigoPorcentaje>'
DISPLAY '<baseImponible>', r_reg.baseimponible2 USING "<<<<<<<<<&.##", '</baseImponible>'
DISPLAY '<valor>', r_reg.valorimpuesto USING "<<<<<<<<<&.##", '</valor>'
DISPLAY '</totalImpuesto>'
DISPLAY '</totalConImpuestos>'
DISPLAY '<motivo>', r_reg.motivo CLIPPED, '</motivo>'
DISPLAY '</infoNotaCredito>'
DISPLAY '<detalles>'
INITIALIZE r_reg.* TO NULL
FOREACH q_cons INTO r_reg.*
	DISPLAY '<detalle>'
	DISPLAY '<codigoInterno>', r_reg.codigointerno CLIPPED, '</codigoInterno>'
	--DISPLAY '<codigoAdicional>', r_reg.codigoadicional CLIPPED, '</codigoAdicional>'
	DISPLAY '<descripcion>', r_reg.descripcion CLIPPED, '</descripcion>'
	DISPLAY '<cantidad>', r_reg.cantidad USING "<<<<<<<<<&.##", '</cantidad>'
	LET valor_det_mo = r_reg.preciounitario + valor_oc
	DISPLAY '<precioUnitario>', valor_det_mo USING "<<<<<<<<<&.##", '</precioUnitario>'
	DISPLAY '<descuento>', r_reg.descuento USING "<<<<<<<<<&.##", '</descuento>'
	LET valor_det_mo = r_reg.preciototalsinimp + valor_oc
	DISPLAY '<precioTotalSinImpuesto>', valor_det_mo USING "<<<<<<<<<&.##", '</precioTotalSinImpuesto>'
	DISPLAY '<detallesAdicionales>'
	LET marc = r_reg.marca[1, 6]
	DISPLAY '<detAdicional nombre="MARCA" valor="', marc CLIPPED, '"/>'
	DISPLAY '<detAdicional nombre="UNIDAD" valor="', r_reg.unidad CLIPPED, '"/>'
	DISPLAY '</detallesAdicionales>'
	DISPLAY '<impuestos>'
	DISPLAY '<impuesto>'
	DISPLAY '<codigo>', r_reg.codigoivadet CLIPPED, '</codigo>'
	DISPLAY '<codigoPorcentaje>', r_reg.codigoporcentdet CLIPPED, '</codigoPorcentaje>'
	DISPLAY '<tarifa>', r_reg.tarifa USING "<<&.##", '</tarifa>'
	LET valor_det_mo = r_reg.baseimponibledet + valor_oc
	DISPLAY '<baseImponible>', valor_det_mo USING "<<<<<<<<<&.##", '</baseImponible>'
	DISPLAY '<valor>', r_reg.valorimpuestodet USING "<<<<<<<<<&.##", '</valor>'
	DISPLAY '</impuesto>'
	DISPLAY '</impuestos>'
	DISPLAY '</detalle>'
END FOREACH
DISPLAY '</detalles>'
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
DISPLAY '</notaCredito>'

END FUNCTION



FUNCTION obtener_valor_oc()
DEFINE valor_oc		DECIMAL(16,2)
DEFINE ot_nue		LIKE talt023.t23_orden

LET valor_oc = 0
INITIALIZE ot_nue TO NULL
SELECT t28_ot_nue INTO ot_nue
	FROM talt028
	WHERE t28_compania  = vg_codcia
	  AND t28_localidad = vg_codloc
	  AND t28_num_dev   = vm_num_tran
IF ot_nue IS NULL THEN
	RETURN valor_oc
END IF
SELECT NVL(((SELECT NVL(SUM((c11_precio - c11_val_descto) *
		(1 + c10_recargo / 100)), 0)
		FROM ordt010, ordt011
		WHERE c10_compania    = t23_compania
		  AND c10_localidad   = t23_localidad
		  AND c10_ord_trabajo = t23_orden
		  AND c10_estado      = 'C'
		  AND c11_compania    = c10_compania
		  AND c11_localidad   = c10_localidad
		  AND c11_numero_oc   = c10_numero_oc
		  AND c11_tipo        = 'S') +
		(SELECT NVL(SUM(((c11_cant_ped * c11_precio) - c11_val_descto)
			* (1 + c10_recargo / 100)), 0)
		 FROM ordt010, ordt011
		 WHERE c10_compania    = t23_compania
		   AND c10_localidad   = t23_localidad
		   AND c10_ord_trabajo = t23_orden
		   AND c10_estado      = 'C'
		   AND c11_compania    = c10_compania
		   AND c11_localidad   = c10_localidad
		   AND c11_numero_oc   = c10_numero_oc
		   AND c11_tipo        = 'B')), 0)
	INTO valor_oc
	FROM talt023
	WHERE t23_compania  = vg_codcia
	  AND t23_localidad = vg_codloc
	  AND t23_orden     = ot_nue
RETURN valor_oc

END FUNCTION

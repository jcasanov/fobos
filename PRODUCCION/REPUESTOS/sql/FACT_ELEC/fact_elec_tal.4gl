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
				guiaremision		VARCHAR(17),
				razonsocialcompra	VARCHAR(100),
				identificacioncom	VARCHAR(13),
				totalsinimpuestos	DECIMAL(12,2),
				totaldescuento		DECIMAL(12,2),
				codigoiva		VARCHAR(1),
				codigoporcentaje	VARCHAR(4),
				descuentoadicional	DECIMAL(5,2),
				baseimponible2		DECIMAL(12,2),
				valorimpuesto		DECIMAL(12,2),
				propina			DECIMAL(12,2),
				importetotal		DECIMAL(12,2),
				moneda			VARCHAR(6),
				codigoprincipal		VARCHAR(15),
				codigoauxiliar		VARCHAR(20),
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
DEFINE query		CHAR(7000)
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
		{--
		'LPAD(NVL((SELECT TRIM(r38_num_sri[9, 21]) ',
			'FROM rept038 ',
			'WHERE r38_compania    = t23_compania ',
			'  AND r38_localidad   = t23_localidad ',
			'  AND r38_tipo_doc    = "FA" ',
			'  AND r38_tipo_fuente = "OT" ',
			'  AND r38_cod_tran    = "FA" ',
			'  AND r38_num_tran    = t23_num_factura), ',
			'0), 9, 0) AS secuencial, ',
		--}
		'LPAD(t23_num_factura, 9, 0) AS secuencial, ',
		'"', dirmat CLIPPED, '" AS dirmatriz, ',
		'TO_CHAR(DATE(t23_fec_factura), "%d/%m/%Y") AS fechaemision, ',
		'CASE WHEN g02_localidad = 3 ',
			'THEN "AV. LA PRENSA - MATRIZ QUITO" ',
			'ELSE g02_direccion ',
		'END AS direstablecimiento, ',
		'"5368" AS contribuyenteespecial, ',
		'"SI" AS obligadocontabilidad, ',
		'CASE WHEN t23_cod_cliente = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = t23_compania) ',
			'THEN "07" ',
			'ELSE ',
			'(SELECT s03_codigo ',
			'FROM cxct001, srit003 ',
			'WHERE z01_codcli       = t23_cod_cliente ',
			'  AND s03_compania     = t23_compania ',
			'  AND s03_cod_ident    = z01_tipo_doc_id ',
			'  AND YEAR(s03_fecing) < 2007) ',
		'END AS tipoidentificacioncomprador, ',
		{--
		'NVL((SELECT r38_num_sri[1, 8] || ',
			'LPAD(TRIM(r38_num_sri[9, 21]), 9, 0) ',
			'FROM rept038 ',
			'WHERE r38_compania    = t23_compania ',
			'  AND r38_localidad   = t23_localidad ',
			'  AND r38_tipo_doc    = "FA" ',
			'  AND r38_tipo_fuente = "OT" ',
			'  AND r38_cod_tran    = "FA" ',
			'  AND r38_num_tran    = t23_num_factura), ',
		'"") AS guiaremision, ',
		--}
		'LPAD(g02_serie_cia, 3, 0) || "-" || ',
		'LPAD(g02_serie_loc, 3, 0) || "-" || ',
		'LPAD(t23_num_factura, 9, 0) AS guiaremision, ',
		't23_nom_cliente AS razonsocialcomprador, ',
		'CASE WHEN t23_cod_cliente = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = t23_compania) ',
			'THEN "9999999999999" ',
			'ELSE t23_cedruc ',
		'END AS identificacioncomprador, ',
		'(t23_tot_bruto - t23_tot_dscto) AS totalsinimpuestos, ',
		't23_tot_dscto AS totaldescuento, ',
		'2 AS codigoiva, ',
		'CASE WHEN t23_porc_impto = 0  THEN 0 ',
		'     WHEN t23_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentaje, ',
		'0.00 AS descuentoadicional, ',
		'(t23_tot_bruto - t23_tot_dscto) AS baseimponible2, ',
		'(t23_tot_neto - ',
			'(t23_tot_bruto - t23_tot_dscto)) AS valorimpuesto, ',
		'0.00 AS propina, ',
		't23_tot_neto AS importetotal, ',
		'"DOLAR" AS moneda, ',
		'CAST(t24_codtarea AS CHAR(15)) AS codigoPrincipal, ',
		'CAST(t24_codtarea AS CHAR(15)) AS codigoauxiliar, ',
		't24_descripcion AS descripcion, ',
		'1.00 AS cantidad, ',
		't24_valor_tarea AS preciounitario, ',
		't24_val_descto AS descuento, ',
		'(t24_valor_tarea - t24_val_descto) AS preciototalsinimpuesto,',
		't23_modelo AS marca, ',
		'"UNI" AS unidad, ',
		'2 AS codigoivadet, ',
		'CASE WHEN t23_porc_impto = 0  THEN 0 ',
		'     WHEN t23_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentajedet, ',
		't23_porc_impto AS tarifa, ',
		'(t24_valor_tarea - t24_val_descto) AS baseimponibledet, ',
		'(t24_valor_tarea * t23_porc_impto / 100) AS valorimpuestodet,',
		'(SELECT z02_email ',
			'FROM cxct002 ',
			'WHERE z02_compania  = t23_compania ',
			'  AND z02_localidad = t23_localidad ',
			'  AND z02_codcli    = t23_cod_cliente) AS emailcli, ',
		't23_tel_cliente AS telfcli, ',
		'LPAD(t23_cod_cliente, 6, 0) AS codcli ',
		'FROM talt023, talt024, gent002, gent001 ',
		'WHERE t23_compania    = ', vg_codcia,
		'  AND t23_localidad   = ', vg_codloc,
		'  AND t23_estado      = "', vm_estado, '" ',
		'  AND t23_num_factura = ', vm_num_tran,
		'  AND t24_compania    = t23_compania ',
		'  AND t24_localidad   = t23_localidad ',
		'  AND t24_orden       = t23_orden ',
		'  AND g02_compania    = t23_compania ',
		'  AND g02_localidad   = t23_localidad ',
		'  AND g01_compania    = g02_compania ',
		'UNION ',
		'SELECT g01_razonsocial AS razonsocial, ',
		'g02_numruc AS ruc, ',
		'LPAD(g02_serie_cia, 3, 0) AS estab, ',
		'LPAD(g02_serie_loc, 3, 0) AS ptoemi, ',
		{--
		'LPAD(NVL((SELECT TRIM(r38_num_sri[9, 21]) ',
			'FROM rept038 ',
			'WHERE r38_compania    = t23_compania ',
			'  AND r38_localidad   = t23_localidad ',
			'  AND r38_tipo_doc    = "FA" ',
			'  AND r38_tipo_fuente = "OT" ',
			'  AND r38_cod_tran    = "FA" ',
			'  AND r38_num_tran    = t23_num_factura), ',
			'0), 9, 0) AS secuencial, ',
		--}
		'LPAD(t23_num_factura, 9, 0) AS secuencial, ',
		'g02_direccion AS dirmatriz, ',
		'TO_CHAR(DATE(t23_fec_factura), "%d/%m/%Y") AS fechaemision, ',
		't23_dir_cliente AS direstablecimiento, ',
		'"5368" AS contribuyenteespecial, ',
		'"SI" AS obligadocontabilidad, ',
		'CASE WHEN t23_cod_cliente = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = t23_compania) ',
			'THEN "07" ',
			'ELSE ',
			'(SELECT s03_codigo ',
			'FROM cxct001, srit003 ',
			'WHERE z01_codcli       = t23_cod_cliente ',
			'  AND s03_compania     = t23_compania ',
			'  AND s03_cod_ident    = z01_tipo_doc_id ',
			'  AND YEAR(s03_fecing) < 2007) ',
		'END AS tipoidentificacioncomprador, ',
		{--
		'NVL((SELECT r38_num_sri[1, 8] || ',
			'LPAD(TRIM(r38_num_sri[9, 21]), 9, 0) ',
			'FROM rept038 ',
			'WHERE r38_compania    = t23_compania ',
			'  AND r38_localidad   = t23_localidad ',
			'  AND r38_tipo_doc    = "FA" ',
			'  AND r38_tipo_fuente = "OT" ',
			'  AND r38_cod_tran    = "FA" ',
			'  AND r38_num_tran    = t23_num_factura), ',
		'"") AS guiaremision, ',
		--}
		'LPAD(g02_serie_cia, 3, 0) || "-" || ',
		'LPAD(g02_serie_loc, 3, 0) || "-" || ',
		'LPAD(t23_num_factura, 9, 0) AS guiaremision, ',
		't23_nom_cliente AS razonsocialcomprador, ',
		'CASE WHEN t23_cod_cliente = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = t23_compania) ',
			'THEN "9999999999999" ',
			'ELSE t23_cedruc ',
		'END AS identificacioncomprador, ',
		'(t23_tot_bruto - t23_tot_dscto) AS totalsinimpuestos, ',
		't23_tot_dscto AS totaldescuento, ',
		'2 AS codigoiva, ',
		'CASE WHEN t23_porc_impto = 0  THEN 0 ',
		'     WHEN t23_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentaje, ',
		'0.00 AS descuentoadicional, ',
		'(t23_tot_bruto - t23_tot_dscto) AS baseimponible2, ',
		'(t23_tot_neto - ',
			'(t23_tot_bruto - t23_tot_dscto)) AS valorimpuesto, ',
		'0.00 AS propina, ',
		't23_tot_neto AS importetotal, ',
		'"DOLAR" AS moneda, ',
		'c11_codigo AS codigoPrincipal, ',
		'c11_codigo AS codigoauxiliar, ',
		'c11_descrip AS descripcion, ',
		'1.00 AS cantidad, ',
		'(((c11_cant_ped * c11_precio) - c11_val_descto) * ',
			'(1 + c10_recargo / 100)) AS preciounitario, ',
		'0.00 AS descuento, ',
		'(((c11_cant_ped * c11_precio) - c11_val_descto) * ',
			'(1 + c10_recargo / 100)) AS preciototalsinimpuesto, ',
		't23_modelo AS marca, ',
		'"UNI" AS unidad, ',
		'2 AS codigoivadet, ',
		'CASE WHEN t23_porc_impto = 0  THEN 0 ',
		'     WHEN t23_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentajedet, ',
		't23_porc_impto AS tarifa, ',
		'(((c11_cant_ped * c11_precio) - c11_val_descto) * ',
			'(1 + c10_recargo / 100)) AS baseimponibledet, ',
		'((((c11_cant_ped * c11_precio) - c11_val_descto) * ',
			'(1 + c10_recargo / 100)) ',
			'* t23_porc_impto / 100) AS valorimpuestodet,',
		'(SELECT z02_email ',
			'FROM cxct002 ',
			'WHERE z02_compania  = t23_compania ',
			'  AND z02_localidad = t23_localidad ',
			'  AND z02_codcli    = t23_cod_cliente) AS emailcli, ',
		't23_tel_cliente AS telfcli, ',
		'LPAD(t23_cod_cliente, 6, 0) AS codcli ',
		'FROM talt023, ordt010, ordt011, gent002, gent001 ',
		'WHERE t23_compania    = ', vg_codcia,
		'  AND t23_localidad   = ', vg_codloc,
		'  AND t23_estado      = "', vm_estado, '" ',
		'  AND t23_num_factura = ', vm_num_tran,
		'  AND c10_compania    = t23_compania ',
		'  AND c10_localidad   = t23_localidad ',
		'  AND c10_ord_trabajo = t23_orden ',
		'  AND c10_estado      = "C" ',
		'  AND c11_compania    = c10_compania ',
		'  AND c11_localidad   = c10_localidad ',
		'  AND c11_numero_oc   = c10_numero_oc ',
		'  AND g02_compania    = t23_compania ',
		'  AND g02_localidad   = t23_localidad ',
		'  AND g01_compania    = g02_compania ',
		'INTO TEMP t1'
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
DISPLAY '<factura id="comprobante" version="1.0.0">'
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
DISPLAY '<infoFactura>'
DISPLAY '<fechaEmision>', r_reg.fechaemision, '</fechaEmision>'
DISPLAY '<dirEstablecimiento>', r_reg.direstablecimiento CLIPPED, '</dirEstablecimiento>'
--DISPLAY '<dirEstablecimiento>', r_reg.dirmatriz CLIPPED, '</dirEstablecimiento>'
DISPLAY '<contribuyenteEspecial>', r_reg.contribuyenteespe CLIPPED, '</contribuyenteEspecial>'
DISPLAY '<obligadoContabilidad>', r_reg.obligadocontabili CLIPPED, '</obligadoContabilidad>'
DISPLAY '<tipoIdentificacionComprador>', r_reg.tipoidentificacio, '</tipoIdentificacionComprador>'
DISPLAY '<guiaRemision>', r_reg.guiaremision CLIPPED, '</guiaRemision>'
DISPLAY '<razonSocialComprador>', r_reg.razonsocialcompra CLIPPED, '</razonSocialComprador>'
DISPLAY '<identificacionComprador>', r_reg.identificacioncom CLIPPED, '</identificacionComprador>'
DISPLAY '<totalSinImpuestos>', r_reg.totalsinimpuestos USING "<<<<<<<<<&.##", '</totalSinImpuestos>'
DISPLAY '<totalDescuento>', r_reg.totaldescuento USING "<<<<<<<<<&.##", '</totalDescuento>'
DISPLAY '<totalConImpuestos>'
DISPLAY '<totalImpuesto>'
DISPLAY '<codigo>', r_reg.codigoiva, '</codigo>'
DISPLAY '<codigoPorcentaje>', r_reg.codigoporcentaje, '</codigoPorcentaje>'
DISPLAY '<descuentoAdicional>', r_reg.descuentoadicional USING "<<&.##", '</descuentoAdicional>'
DISPLAY '<baseImponible>', r_reg.baseimponible2 USING "<<<<<<<<<&.##", '</baseImponible>'
DISPLAY '<valor>', r_reg.valorimpuesto USING "<<<<<<<<<&.##", '</valor>'
DISPLAY '</totalImpuesto>'
DISPLAY '</totalConImpuestos>'
DISPLAY '<propina>', r_reg.propina USING "<<<<<<<<<&.##", '</propina>'
DISPLAY '<importeTotal>', r_reg.importetotal USING "<<<<<<<<<&.##", '</importeTotal>'
DISPLAY '<moneda>', r_reg.moneda, '</moneda>'
DISPLAY '</infoFactura>'
DISPLAY '<detalles>'
INITIALIZE r_reg.* TO NULL
FOREACH q_cons INTO r_reg.*
	DISPLAY '<detalle>'
	DISPLAY '<codigoPrincipal>', r_reg.codigoprincipal CLIPPED, '</codigoPrincipal>'
	DISPLAY '<descripcion>', r_reg.descripcion CLIPPED, '</descripcion>'
	DISPLAY '<cantidad>', r_reg.cantidad USING "<<<<<<<<<&.##", '</cantidad>'
	DISPLAY '<precioUnitario>', r_reg.preciounitario USING "<<<<<<<<<&.##", '</precioUnitario>'
	DISPLAY '<descuento>', r_reg.descuento USING "<<<<<<<<<&.##", '</descuento>'
	DISPLAY '<precioTotalSinImpuesto>', r_reg.preciototalsinimp USING "<<<<<<<<<&.##", '</precioTotalSinImpuesto>'
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
	DISPLAY '<baseImponible>', r_reg.baseimponibledet USING "<<<<<<<<<&.##", '</baseImponible>'
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
DISPLAY '</factura>'

END FUNCTION

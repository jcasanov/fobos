DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran



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
				guiaremision		VARCHAR(17),
				razonsocialcompra	VARCHAR(100),
				identificacioncom	VARCHAR(13),
				totalsinimpuestos	DECIMAL(12,2),
				totaldescuento		DECIMAL(12,2),
				{--
				codigoivafact		VARCHAR(1),
				codigoporcentajef	VARCHAR(4),
				baseimponible1		DECIMAL(12,2),
				valor			DECIMAL(12,2),
				--}
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
				codcli			VARCHAR(6),
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran,
				observac		VARCHAR(40)
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
		{--
		'LPAD(NVL((SELECT TRIM(r38_num_sri[9, 21]) ',
			'FROM rept038 ',
			'WHERE r38_compania    = r19_compania ',
			'  AND r38_localidad   = r19_localidad ',
			'  AND r38_tipo_doc    = "FA" ',
			'  AND r38_tipo_fuente = "PR" ',
			'  AND r38_cod_tran    = r19_cod_tran ',
			'  AND r38_num_tran    = r19_num_tran), ',
			'0), 9, 0) AS secuencial, ',
		--}
		'LPAD(r19_num_tran, 9, 0) AS secuencial, ',
		'"', dirmat CLIPPED, '" AS dirmatriz, ',
		'TO_CHAR(r19_fecing, "%d/%m/%Y") AS fechaemision, ',
		'CASE WHEN g02_localidad = 3 ',
			'THEN "AV. LA PRENSA - MATRIZ QUITO" ',
			'ELSE g02_direccion ',
		'END AS direstablecimiento, ',
		'"5368" AS contribuyenteespecial, ',
		'"SI" AS obligadocontabilidad, ',
		'CASE WHEN r19_codcli = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = r19_compania) ',
			'THEN "07" ',
			'ELSE ',
			'(SELECT s03_codigo ',
			'FROM cxct001, srit003 ',
			'WHERE z01_codcli       = r19_codcli ',
			'  AND s03_compania     = r19_compania ',
			'  AND s03_cod_ident    = z01_tipo_doc_id ',
			'  AND YEAR(s03_fecing) < 2007) ',
		'END AS tipoidentificacioncomprador, ',
		{--
		'NVL((SELECT r38_num_sri[1, 8] || ',
			'LPAD(TRIM(r38_num_sri[9, 21]), 9, 0) ',
			'FROM rept038 ',
			'WHERE r38_compania    = r19_compania ',
			'  AND r38_localidad   = r19_localidad ',
			'  AND r38_tipo_doc    = "FA" ',
			'  AND r38_tipo_fuente = "PR" ',
			'  AND r38_cod_tran    = r19_cod_tran ',
			'  AND r38_num_tran    = r19_num_tran), ',
		'"") AS guiaremision, ',
		--}
		'LPAD(g02_serie_cia, 3, 0) || "-" || ',
		'LPAD(g02_serie_loc, 3, 0) || "-" || ',
		'LPAD(r19_num_tran, 9, 0) AS guiaremision, ',
		'r19_nomcli AS razonsocialcompra, ',
		'CASE WHEN r19_codcli = ',
			'(SELECT r00_codcli_tal ',
				'FROM rept000 ',
				'WHERE r00_compania = r19_compania) ',
			'THEN "9999999999999" ',
			'ELSE r19_cedruc ',
		'END AS identificacioncom, ',
		'(r19_tot_bruto - r19_tot_dscto) AS totalsinimpuestos, ',
		'r19_tot_dscto AS totaldescuento, ',
		{--
		'2 AS codigoivafact, ',
		'CASE WHEN r19_porc_impto = 0  THEN 0 ',
		'     WHEN r19_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentajefact, ',
		'(r19_tot_bruto - r19_tot_dscto) AS baseimponible1, ',
		'r19_tot_neto AS valor, ',
		--}
		'2 AS codigoiva, ',
		'CASE WHEN r19_porc_impto = 0  THEN 0 ',
		'     WHEN r19_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentaje, ',
		'0.00 AS descuentoadicional, ',
		'(r19_tot_bruto - r19_tot_dscto) AS baseimponible2, ',
		'((r19_tot_neto - r19_flete) - ',
			'(r19_tot_bruto - r19_tot_dscto)) AS valorimpuesto, ',
		'0.00 AS propina, ',
		'(r19_tot_neto + r19_flete) AS importetotal, ',
		'"DOLAR" AS moneda, ',
		'r20_item AS codigoPrincipal, ',
		'r10_cod_pedido AS codigoauxiliar, ',
		'(SELECT r72_desc_clase ',
			'FROM rept072 ',
			'WHERE r72_compania  = r10_compania ',
			'  AND r72_linea     = r10_linea ',
			'  AND r72_sub_linea = r10_sub_linea ',
			'  AND r72_cod_grupo = r10_cod_grupo ',
			'  AND r72_cod_clase = r10_cod_clase) ',
			'|| " " || r10_nombre AS descripcion, ',
		'r20_cant_ven AS cantidad, ',
		'r20_precio AS preciounitario, ',
		'r20_val_descto AS descuento, ',
		'((r20_cant_ven * r20_precio) ',
			'- r20_val_descto) AS preciototalsinimpuesto, ',
		'(SELECT r73_desc_marca ',
			'FROM rept073 ',
			'WHERE r73_compania = r10_compania ',
			'  AND r73_marca    = r10_marca) AS marca, ',
		'r10_uni_med AS unidad, ',
		'2 AS codigoivadet, ',
		'CASE WHEN r19_porc_impto = 0  THEN 0 ',
		'     WHEN r19_porc_impto = 12 THEN 2 ',
		'END AS codigoporcentajedet, ',
		'r19_porc_impto AS tarifa, ',
		'((r20_cant_ven * r20_precio) ',
			'- r20_val_descto) AS baseimponibledet, ',
		'r20_val_impto AS valorimpuestodet, ',
		'(SELECT z02_email ',
			'FROM cxct002 ',
			'WHERE z02_compania  = r19_compania ',
			'  AND z02_localidad = r19_localidad ',
			'  AND z02_codcli    = r19_codcli) AS emailcli, ',
		'r19_telcli AS telfcli, ',
		'LPAD(r19_codcli, 6, 0) AS codcli, ',
		'r19_cod_tran AS cod_tran, ',
		'r19_num_tran AS num_tran ',
		'FROM rept019, rept020, rept010, gent002, gent001 ',
		'WHERE r19_compania  = ', vg_codcia,
		'  AND r19_localidad = ', vg_codloc,
		'  AND r19_cod_tran  = "', vm_cod_tran, '" ',
		'  AND r19_num_tran  = ', vm_num_tran,
		'  AND r20_compania  = r19_compania ',
		'  AND r20_localidad = r19_localidad ',
		'  AND r20_cod_tran  = r19_cod_tran ',
		'  AND r20_num_tran  = r19_num_tran ',
		'  AND r10_compania  = r20_compania ',
		'  AND r10_codigo    = r20_item ',
		'  AND g02_compania  = r19_compania ',
		'  AND g02_localidad = r19_localidad ',
		'  AND g01_compania  = g02_compania ',
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
{--
DISPLAY '<totalImpuesto>'
DISPLAY '<codigo>', r_reg.codigoivafact CLIPPED, '</codigo>'
DISPLAY '<codigoPorcentaje>', r_reg.codigoporcentajef CLIPPED, '</codigoPorcentaje>'
DISPLAY '<baseImponible>', r_reg.baseimponible1 USING "<<<<<<<<<&.##", '</baseImponible>'
DISPLAY '<valor>', r_reg.valor USING "<<<<<<<<<&.##", '</valor>'
DISPLAY '</totalImpuesto>'
--}
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
	--DISPLAY '<codigoAuxiliar>', r_reg.codigoauxiliar CLIPPED, '</codigoAuxiliar>'
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
INITIALIZE r_reg.observac TO NULL
SELECT r21_atencion
	INTO r_reg.observac
	FROM rept021
	WHERE r21_compania  = vg_codcia
	  AND r21_localidad = vg_codloc
	  AND r21_cod_tran  = r_reg.cod_tran
	  AND r21_num_tran  = r_reg.num_tran
IF r_reg.observac IS NOT NULL THEN
	DISPLAY '<campoAdicional nombre="Observaciones">', r_reg.observac CLIPPED, '</campoAdicional>'
END IF
DISPLAY '</infoAdicional>'
DISPLAY '</factura>'

END FUNCTION

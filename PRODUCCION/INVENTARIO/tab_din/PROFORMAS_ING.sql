SELECT r21_numprof AS numero,
	r21_cod_tran AS codtran,
	r21_num_tran AS numtran,
	r21_num_presup AS numpre,
	r21_num_ot AS num_ot,
	r21_fecing AS fecha,
	r21_codcli AS codcli,
	r21_nomcli AS nomcli,
	r21_cedruc AS cedruc,
	r21_dircli AS direccion,
	r21_telcli AS telefono,
	r21_vendedor AS codven,
	r01_nombres AS vendedor,
	(r21_porc_impto / 100) AS iva,
	r21_dias_prof AS dias_p,
	r21_flete AS flete,
	CASE WHEN r21_forma_pago = 'C'
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS for_pago,
	r22_orden AS secuencia,
	r22_bodega AS bodega,
	r22_item AS item,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	r22_cantidad AS cantidad,
	(r22_porc_descto / 100) AS porc_desc,
	r22_val_descto AS val_desc,
	r22_precio AS precio,
	r22_val_impto AS val_impto,
	NVL(
		ROUND(
			((r22_cantidad * r22_precio) - r22_val_descto),
		2),
	0) AS subtotal,
	NVL(
		SUM(CASE WHEN r02_localidad <> r21_localidad
				THEN r11_stock_act
				ELSE 0
			END),
	0) stock_nac,
	NVL(
		SUM(CASE WHEN r02_localidad = r21_localidad
				THEN r11_stock_act
				ELSE 0
			END),
	0) stock_loc
	FROM rept021, rept022, rept001, rept010, rept072,
		rept011, rept002
	WHERE r21_compania      = 1
	  AND r21_localidad     = 1
	  AND EXTEND(r21_fecing, YEAR TO MONTH) >=
		EXTEND(DATE(TODAY - 90 UNITS DAY), YEAR TO MONTH)
	  AND r21_vendedor     IN (8, 25, 37, 41, 10)
	  AND r22_compania      = r21_compania
	  AND r22_localidad     = r21_localidad
	  AND r22_numprof       = r21_numprof
	  AND r01_compania      = r21_compania
	  AND r01_codigo        = r21_vendedor
	  AND r10_compania      = r22_compania
	  AND r10_codigo        = r22_item
	  AND r72_compania      = r10_compania
	  AND r72_linea         = r10_linea
	  AND r72_sub_linea     = r10_sub_linea
	  AND r72_cod_grupo     = r10_cod_grupo
	  AND r72_cod_clase     = r10_cod_clase
	  AND r11_compania      = r10_compania
	  AND r11_item          = r10_codigo
	  AND r02_compania      = r11_compania
	  AND r02_codigo        = r11_bodega
	  AND r02_estado        = 'A'
	  AND r02_tipo         <> 'S'
	  AND r02_tipo_ident    = 'V'
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
			18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
	ORDER BY 12, 1, 18;

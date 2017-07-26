SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm:gent002
		WHERE g02_compania  = r20_compania
		  AND g02_localidad = r20_localidad) AS local,
	YEAR(r20_fecing) AS anio,
	CASE WHEN MONTH(r20_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r20_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r20_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r20_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r20_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r20_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r20_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r20_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r20_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r20_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r20_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r20_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CAST(r10_codigo AS INTEGER) AS item,
	r10_nombre AS descrip,
	r10_cod_clase AS clas,
	r72_desc_clase AS nom_cla,
	r10_marca AS marc,
	r10_modelo AS model,
	r20_costo AS preci,
	DATE(r20_fecing) AS fec_pre,
	NVL(r19_usuario, "SIN USUARIO") AS usua,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_qm:rept011, acero_qm:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 3
		  AND r02_tipo      <> "S"), 0) AS sto
	FROM acero_qm:rept019, acero_qm:rept020, acero_qm:rept010,
		acero_qm:rept072
	WHERE r19_compania  = 1
	  AND r19_localidad = 3
	  AND r19_cod_tran  = "IM"
	  AND r20_compania  = r19_compania
	  AND r20_localidad = r19_localidad
	  AND r20_cod_tran  = r19_cod_tran
	  AND r20_num_tran  = r19_num_tran
	  AND r10_compania  = r20_compania
	  AND r10_codigo    = r20_item
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase;

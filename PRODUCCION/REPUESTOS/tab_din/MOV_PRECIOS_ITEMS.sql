SELECT NVL((SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r87_compania
		  AND g02_localidad = r87_localidad), "01 J T M") AS local,
	YEAR(NVL(r87_fec_camprec, r10_fec_camprec)) AS anio,
	CASE WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 01
		THEN "ENERO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 02
		THEN "FEBRERO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 03
		THEN "MARZO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 04
		THEN "ABRIL"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 05
		THEN "MAYO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 06
		THEN "JUNIO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 07
		THEN "JULIO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 08
		THEN "AGOSTO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 09
		THEN "SEPTIEMBRE"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 10
		THEN "OCTUBRE"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 11
		THEN "NOVIEMBRE"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 12
		THEN "DICIEMBRE"
	END AS mes,
	NVL(r87_secuencia, 0) AS secuen,
	CAST(r10_codigo AS INTEGER) AS item,
	r10_nombre AS descrip,
	r10_cod_clase AS clas,
	r72_desc_clase AS nom_cla,
	r10_marca AS marc,
	r10_modelo AS model,
	NVL(r87_precio_ant, r10_precio_ant) AS pre_ant,
	NVL(r87_precio_act, r10_precio_mb) AS preci,
	DATE(NVL(r87_fec_camprec, r10_fec_camprec)) AS fec_pre,
	NVL(r87_usu_camprec, "SIN USUARIO") AS usua,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM rept011, rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 1
		  AND r02_tipo      <> "S"), 0) AS sto
	FROM rept010, rept072, OUTER rept087
	WHERE r10_compania  = 1
and r10_codigo = '1200'
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND r87_compania  = r10_compania
	  AND r87_item      = r10_codigo
{
UNION
SELECT NVL((SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm:gent002
		WHERE g02_compania  = r87_compania
		  AND g02_localidad = r87_localidad), "03 MATRIZ UIO") AS local,
	YEAR(NVL(r87_fec_camprec, r10_fec_camprec)) AS anio,
	CASE WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 01
		THEN "ENERO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 02
		THEN "FEBRERO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 03
		THEN "MARZO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 04
		THEN "ABRIL"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 05
		THEN "MAYO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 06
		THEN "JUNIO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 07
		THEN "JULIO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 08
		THEN "AGOSTO"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 09
		THEN "SEPTIEMBRE"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 10
		THEN "OCTUBRE"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 11
		THEN "NOVIEMBRE"
	     WHEN MONTH(NVL(r87_fec_camprec, r10_fec_camprec)) = 12
		THEN "DICIEMBRE"
	END AS mes,
	NVL(r87_secuencia, 0) AS secuen,
	CAST(r10_codigo AS INTEGER) AS item,
	r10_nombre AS descrip,
	r10_cod_clase AS clas,
	r72_desc_clase AS nom_cla,
	r10_marca AS marc,
	r10_modelo AS model,
	NVL(r87_precio_ant, r10_precio_ant) AS pre_ant,
	NVL(r87_precio_act, r10_precio_mb) AS preci,
	DATE(NVL(r87_fec_camprec, r10_fec_camprec)) AS fec_pre,
	NVL(r87_usu_camprec, "SIN USUARIO") AS usua,
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
	FROM acero_qm:rept010, acero_qm:rept072, OUTER acero_qm:rept087
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND r87_compania  = r10_compania
	  AND r87_item      = r10_codigo;
}

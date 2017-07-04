SELECT CAST(a.r10_codigo AS INTEGER) AS codigo,
	r72_desc_clase AS desc_cl,
	a.r10_nombre AS descrip,
	a.r10_marca AS marc,
	a.r10_precio_mb AS prec_l,
	NVL(DATE(a.r10_fec_camprec), "") AS fec_c_p,
	CASE WHEN a.r10_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS est,
	(SELECT b.r10_precio_mb
		FROM acero_qm:rept010 b
		WHERE b.r10_compania  = a.r10_compania
		  AND b.r10_codigo    = a.r10_codigo) AS prec_m,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_qs:rept011
		WHERE r11_compania   = a.r10_compania
		  AND r11_bodega    IN
			(SELECT r02_codigo
				FROM acero_qs:rept002
				WHERE r02_compania  = r11_compania
				  AND r02_localidad = 4)
		  AND r11_item       = a.r10_codigo
		  AND r11_stock_act <> 0), 0.00) AS stoc
	FROM acero_qs:rept010 a, acero_qs:rept072
	WHERE a.r10_compania = 1
	  AND r72_compania   = a.r10_compania
	  AND r72_linea      = a.r10_linea
	  AND r72_sub_linea  = a.r10_sub_linea
	  AND r72_cod_grupo  = a.r10_cod_grupo
	  AND r72_cod_clase  = a.r10_cod_clase
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm:rept010 b
			WHERE b.r10_compania  = a.r10_compania
			  AND b.r10_codigo    = a.r10_codigo
			  AND b.r10_precio_mb = a.r10_precio_mb);

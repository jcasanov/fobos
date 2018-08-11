unload to "inventario.unl"
SELECT "ACERO GYE" AS localidad, r10_codigo AS item, r10_nombre AS descripcion,
	r03_nombre AS division, r70_desc_sub AS linea, r71_desc_grupo AS grupo,
	r72_desc_clase AS clase, r10_precio_mb AS precio_act,
	r10_costo_mb AS costo,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_gm:rept011
		WHERE r11_compania  = r10_compania
		  AND r11_bodega   IN
			(SELECT r02_codigo
				FROM acero_gm:rept002
				WHERE r02_compania   = r11_compania
				  AND r02_localidad IN (1, 2)
				  AND r02_tipo      <> 'S')
		  AND r11_item      = r10_codigo), 0) AS stock_tot,
	NVL((SELECT SUM(CASE WHEN b.r20_cod_tran = 'CL'
				THEN b.r20_precio
				ELSE b.r20_costo
			END)
		FROM acero_gm:rept019 a, acero_gm:rept020 b
		WHERE a.r19_compania  = r10_compania
		  AND a.r19_localidad = 1
		  AND a.r19_cod_tran  = 'CL'
		  AND b.r20_compania  = a.r19_compania
		  AND b.r20_localidad = a.r19_localidad
		  AND b.r20_cod_tran  = a.r19_cod_tran
		  AND b.r20_num_tran  = a.r19_num_tran
		  AND b.r20_item      = r10_codigo
		  AND b.r20_fecing    =
			(SELECT MAX(d.r20_fecing)
				FROM acero_gm:rept019 c, acero_gm:rept020 d
				WHERE c.r19_compania  = a.r19_compania
				  AND c.r19_localidad = a.r19_localidad
				  AND c.r19_cod_tran  = a.r19_cod_tran
				  AND d.r20_compania  = c.r19_compania
				  AND d.r20_localidad = c.r19_localidad
				  AND d.r20_cod_tran  = c.r19_cod_tran
				  AND d.r20_num_tran  = c.r19_num_tran
				  AND d.r20_item      = b.r20_item)),
		r10_costult_mb) AS ult_costo_comp,
		CASE WHEN r10_estado = 'A'
			THEN "ACTIVO GYE"
			ELSE "BLOQUEADO GYE"
		END AS estado
	FROM acero_gm:rept010, acero_gm:rept003, acero_gm:rept070,
		acero_gm:rept071, acero_gm:rept072
	WHERE r10_compania  = 1
	  AND r03_compania  = r10_compania
	  AND r03_codigo    = r10_linea
	  AND r70_compania  = r10_compania
	  AND r70_linea     = r10_linea
	  AND r70_sub_linea = r10_sub_linea
	  AND r71_compania  = r10_compania
	  AND r71_linea     = r10_linea
	  AND r71_sub_linea = r10_sub_linea
	  AND r71_cod_grupo = r10_cod_grupo
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
UNION
SELECT "ACERO UIO" AS localidad, r10_codigo AS item, r10_nombre AS descripcion,
	r03_nombre AS division, r70_desc_sub AS linea, r71_desc_grupo AS grupo,
	r72_desc_clase AS clase, r10_precio_mb AS precio_act,
	r10_costo_mb AS costo,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_qm:rept011
		WHERE r11_compania  = r10_compania
		  AND r11_bodega   IN
			(SELECT r02_codigo
				FROM acero_qm:rept002
				WHERE r02_compania   = r11_compania
				  AND r02_localidad IN (3, 4, 5)
				  AND r02_tipo      <> 'S')
		  AND r11_item      = r10_codigo), 0) AS stock_tot,
	NVL((SELECT SUM(CASE WHEN b.r20_cod_tran = 'CL'
				THEN b.r20_precio
				ELSE b.r20_costo
			END)
		FROM acero_qm:rept019 a, acero_qm:rept020 b
		WHERE a.r19_compania  = r10_compania
		  AND a.r19_localidad = 3
		  AND a.r19_cod_tran  IN ('CL', 'IM')
		  AND b.r20_compania  = a.r19_compania
		  AND b.r20_localidad = a.r19_localidad
		  AND b.r20_cod_tran  = a.r19_cod_tran
		  AND b.r20_num_tran  = a.r19_num_tran
		  AND b.r20_item      = r10_codigo
		  AND b.r20_fecing    =
			(SELECT MAX(d.r20_fecing)
				FROM acero_qm:rept019 c, acero_qm:rept020 d
				WHERE c.r19_compania  = a.r19_compania
				  AND c.r19_localidad = a.r19_localidad
				  AND c.r19_cod_tran  = a.r19_cod_tran
				  AND d.r20_compania  = c.r19_compania
				  AND d.r20_localidad = c.r19_localidad
				  AND d.r20_cod_tran  = c.r19_cod_tran
				  AND d.r20_num_tran  = c.r19_num_tran
				  AND d.r20_item      = b.r20_item)),
		r10_costult_mb) AS ult_costo_comp,
		CASE WHEN r10_estado = 'A'
			THEN "ACTIVO UIO"
			ELSE "BLOQUEADO UIO"
		END AS estado
	FROM acero_qm:rept010, acero_qm:rept003, acero_qm:rept070,
		acero_qm:rept071, acero_qm:rept072
	WHERE r10_compania  = 1
	  AND r03_compania  = r10_compania
	  AND r03_codigo    = r10_linea
	  AND r70_compania  = r10_compania
	  AND r70_linea     = r10_linea
	  AND r70_sub_linea = r10_sub_linea
	  AND r71_compania  = r10_compania
	  AND r71_linea     = r10_linea
	  AND r71_sub_linea = r10_sub_linea
	  AND r71_cod_grupo = r10_cod_grupo
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
--	INTO TEMP t1;
--DROP TABLE t1;

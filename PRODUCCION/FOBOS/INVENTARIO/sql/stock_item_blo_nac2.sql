SELECT "J T M MATRIZ" AS LOCALIDAD, r11_item AS ITEMS, r72_desc_clase AS CLASE,
	b.r10_nombre AS DESCRIPCION, r11_bodega AS BODEGA,
	r11_stock_act AS STOCK,
	CASE WHEN b.r10_estado = 'A'
		THEN "ACTIVO JTM"
		ELSE "BLOQUEADO JTM"
	END AS ESTADO, b.r10_marca AS MARCA
	FROM rept010 b, rept072, rept011
	WHERE b.r10_compania  = 1
	  AND b.r10_codigo   IN
		(SELECT a.r10_codigo
			FROM acero_qm@acgyede:rept010 a
			WHERE a.r10_compania = b.r10_compania
			  AND a.r10_codigo   = b.r10_codigo
			  AND a.r10_estado   = 'B')
	  AND r72_compania    = b.r10_compania
	  AND r72_linea       = b.r10_linea
	  AND r72_sub_linea   = b.r10_sub_linea
	  AND r72_cod_grupo   = b.r10_cod_grupo
	  AND r72_cod_clase   = b.r10_cod_clase
	  AND r11_compania    = b.r10_compania
	  AND r11_bodega     IN (SELECT r02_codigo
				FROM rept002
				WHERE r02_compania  = r11_compania
				  AND r02_estado    = 'A'
				  AND r02_localidad = 1)
	  AND r11_item        = b.r10_codigo
	  AND r11_stock_act  <> 0
	UNION
	SELECT "J T M MATRIZ" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, b.r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN b.r10_estado = 'A'
			THEN "ACTIVO JTM"
			ELSE "BLOQUEADO JTM"
		END AS ESTADO, b.r10_marca AS MARCA
		FROM rept010 b, rept072, rept011
		WHERE b.r10_compania  = 1
		  AND b.r10_estado    = 'B'
		  AND b.r10_codigo   IN
			(SELECT a.r10_codigo
				FROM acero_qm@acgyede:rept010 a
				WHERE a.r10_compania = b.r10_compania
				  AND a.r10_codigo   = b.r10_codigo
				  AND a.r10_estado   = 'A')
		  AND r72_compania    = b.r10_compania
		  AND r72_linea       = b.r10_linea
		  AND r72_sub_linea   = b.r10_sub_linea
		  AND r72_cod_grupo   = b.r10_cod_grupo
		  AND r72_cod_clase   = b.r10_cod_clase
		  AND r11_compania    = b.r10_compania
		  AND r11_bodega     IN
			(SELECT r02_codigo
				FROM rept002
				WHERE r02_compania  = r11_compania
				  AND r02_estado    = 'A'
				  AND r02_localidad = 1)
		  AND r11_item        = b.r10_codigo
		  AND r11_stock_act  <> 0
	UNION
	SELECT "GYE CENTRO" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, b.r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN b.r10_estado = 'A'
			THEN "ACTIVO CEN"
			ELSE "BLOQUEADO CEN"
		END AS ESTADO, b.r10_marca AS MARCA
		FROM acero_gc:rept010 b, acero_gc:rept072, acero_gc:rept011
		WHERE b.r10_compania   = 1
		  AND b.r10_codigo    IN
			(SELECT a.r10_codigo
				FROM acero_gm:rept010 a
				WHERE a.r10_compania = b.r10_compania
				  AND a.r10_codigo   = b.r10_codigo
				  AND a.r10_estado   = 'B')
		  AND r72_compania   = b.r10_compania
		  AND r72_linea      = b.r10_linea
		  AND r72_sub_linea  = b.r10_sub_linea
		  AND r72_cod_grupo  = b.r10_cod_grupo
		  AND r72_cod_clase  = b.r10_cod_clase
		  AND r11_compania   = b.r10_compania
		  AND r11_bodega    IN
			(SELECT r02_codigo
				FROM acero_gc:rept002
				WHERE r02_compania  = r11_compania
				  AND r02_estado    = 'A'
				  AND r02_localidad = 2)
		  AND r11_item       = b.r10_codigo
		  AND r11_stock_act <> 0
	UNION
	SELECT "GYE CENTRO" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, b.r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN b.r10_estado = 'A'
			THEN "ACTIVO CEN"
			ELSE "BLOQUEADO CEN"
		END AS ESTADO, b.r10_marca AS MARCA
		FROM acero_gc:rept010 b, acero_gc:rept072, acero_gc:rept011
		WHERE b.r10_compania   = 1
		  AND b.r10_estado     = 'B'
		  AND b.r10_codigo    IN
			(SELECT a.r10_codigo
				FROM acero_gm:rept010 a
				WHERE a.r10_compania = b.r10_compania
				  AND a.r10_codigo   = b.r10_codigo
				  AND a.r10_estado   = 'A')
		  AND r72_compania   = b.r10_compania
		  AND r72_linea      = b.r10_linea
		  AND r72_sub_linea  = b.r10_sub_linea
		  AND r72_cod_grupo  = b.r10_cod_grupo
		  AND r72_cod_clase  = b.r10_cod_clase
		  AND r11_compania   = b.r10_compania
		  AND r11_bodega    IN
			(SELECT r02_codigo
				FROM acero_gc:rept002
				WHERE r02_compania  = r11_compania
				  AND r02_estado    = 'A'
				  AND r02_localidad = 2)
		  AND r11_item       = b.r10_codigo
		  AND r11_stock_act <> 0
	UNION
	SELECT "UIO MATRIZ" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, b.r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN b.r10_estado = 'A'
			THEN "ACTIVO UIO"
			ELSE "BLOQUEADO UIO"
		END AS ESTADO, b.r10_marca AS MARCA
		FROM acero_qm@acgyede:rept010 b, acero_qm@acgyede:rept072,
			acero_qm@acgyede:rept011
		WHERE b.r10_compania   = 1
		  AND b.r10_codigo    IN
			(SELECT a.r10_codigo
				FROM acero_gm:rept010 a
				WHERE a.r10_compania = b.r10_compania
				  AND a.r10_codigo   = b.r10_codigo
				  AND a.r10_estado   = 'B')
		  AND r72_compania   = b.r10_compania
		  AND r72_linea      = b.r10_linea
		  AND r72_sub_linea  = b.r10_sub_linea
		  AND r72_cod_grupo  = b.r10_cod_grupo
		  AND r72_cod_clase  = b.r10_cod_clase
		  AND r11_compania   = b.r10_compania
		  AND r11_bodega    IN (SELECT r02_codigo
					FROM acero_gc:rept002
					WHERE r02_compania  = r11_compania
					  AND r02_estado    = 'A'
					  AND r02_localidad IN (3, 5))
		  AND r11_item       = b.r10_codigo
		  AND r11_stock_act <> 0
	UNION
	SELECT "UIO MATRIZ" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, b.r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN b.r10_estado = 'A'
			THEN "ACTIVO UIO"
			ELSE "BLOQUEADO UIO"
		END AS ESTADO, b.r10_marca AS MARCA
		FROM acero_qm@acgyede:rept010 b, acero_qm@acgyede:rept072,
			acero_qm@acgyede:rept011
		WHERE b.r10_compania   = 1
		  AND b.r10_estado     = 'B'
		  AND b.r10_codigo    IN
			(SELECT a.r10_codigo
				FROM acero_gm:rept010 a
				WHERE a.r10_compania = b.r10_compania
				  AND a.r10_codigo   = b.r10_codigo
				  AND a.r10_estado   = 'A')
		  AND r72_compania   = b.r10_compania
		  AND r72_linea      = b.r10_linea
		  AND r72_sub_linea  = b.r10_sub_linea
		  AND r72_cod_grupo  = b.r10_cod_grupo
		  AND r72_cod_clase  = b.r10_cod_clase
		  AND r11_compania   = b.r10_compania
		  AND r11_bodega    IN (SELECT r02_codigo
					FROM acero_gc:rept002
					WHERE r02_compania  = r11_compania
					  AND r02_estado    = 'A'
					  AND r02_localidad IN (3, 5))
		  AND r11_item       = b.r10_codigo
		  AND r11_stock_act <> 0
	UNION
	SELECT "UIO SUR" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, b.r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN b.r10_estado = 'A'
			THEN "ACTIVO SUR"
			ELSE "BLOQUEADO SUR"
		END AS ESTADO, b.r10_marca AS MARCA
		FROM acero_qs@acgyede:rept010 b, acero_qs@acgyede:rept072,
			acero_qs@acgyede:rept011
		WHERE b.r10_compania   = 1
		  AND b.r10_codigo    IN
			(SELECT a.r10_codigo
				FROM acero_qm@acgyede:rept010 a
				WHERE a.r10_compania = b.r10_compania
				  AND a.r10_codigo   = b.r10_codigo
				  AND a.r10_estado   = 'B')
		  AND r72_compania   = b.r10_compania
		  AND r72_linea      = b.r10_linea
		  AND r72_sub_linea  = b.r10_sub_linea
		  AND r72_cod_grupo  = b.r10_cod_grupo
		  AND r72_cod_clase  = b.r10_cod_clase
		  AND r11_compania   = b.r10_compania
		  AND r11_bodega    IN (SELECT r02_codigo
					FROM acero_gc:rept002
					WHERE r02_compania  = r11_compania
					  AND r02_estado    = 'A'
					  AND r02_localidad = 4)
		  AND r11_item       = b.r10_codigo
		  AND r11_stock_act <> 0
	UNION
	SELECT "UIO SUR" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, b.r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN b.r10_estado = 'A'
			THEN "ACTIVO SUR"
			ELSE "BLOQUEADO SUR"
		END AS ESTADO, b.r10_marca AS MARCA
		FROM acero_qs@acgyede:rept010 b, acero_qs@acgyede:rept072,
			acero_qs@acgyede:rept011
		WHERE b.r10_compania   = 1
		  AND b.r10_estado     = 'B'
		  AND b.r10_codigo    IN 
			(SELECT a.r10_codigo
				FROM acero_qm@acgyede:rept010 a
				WHERE a.r10_compania = b.r10_compania
				  AND a.r10_codigo   = b.r10_codigo
				  AND a.r10_estado   = 'A')
		  AND r72_compania   = b.r10_compania
		  AND r72_linea      = b.r10_linea
		  AND r72_sub_linea  = b.r10_sub_linea
		  AND r72_cod_grupo  = b.r10_cod_grupo
		  AND r72_cod_clase  = b.r10_cod_clase
		  AND r11_compania   = b.r10_compania
		  AND r11_bodega    IN (SELECT r02_codigo
					FROM acero_gc:rept002
					WHERE r02_compania  = r11_compania
					  AND r02_estado    = 'A'
					  AND r02_localidad = 4)
		  AND r11_item       = b.r10_codigo
		  AND r11_stock_act <> 0;

SELECT a.r10_codigo AS item, a.r10_nombre AS descripcion,
        a.r10_cod_clase AS cod_cla, r72_desc_clase AS desc_clase,
        a.r10_marca AS marca, a.r10_precio_mb AS precio,
	a.r10_costo_mb AS costo,
        CASE WHEN a.r10_estado = "A" THEN "ACTIVO"
             WHEN a.r10_estado = "B" THEN "BLOQUEADO"
        END AS estado,
        a.r10_cantveh act_precio_gye,
	(SELECT b.r10_cantveh
		FROM acero_qm:rept010 b
		WHERE b.r10_compania = a.r10_compania
		  AND b.r10_codigo   = a.r10_codigo) act_precio_uio
        FROM rept010 a, rept072
        WHERE a.r10_compania = 1
          AND r72_linea      = a.r10_linea
          AND r72_sub_linea  = a.r10_sub_linea
          AND r72_cod_grupo  = a.r10_cod_grupo
          AND r72_cod_clase  = a.r10_cod_clase
	  AND a.r10_cantveh  NOT IN
			(SELECT b.r10_cantveh
				FROM acero_qm:rept010 b
				WHERE b.r10_compania = a.r10_compania
				  AND b.r10_codigo   = a.r10_codigo);

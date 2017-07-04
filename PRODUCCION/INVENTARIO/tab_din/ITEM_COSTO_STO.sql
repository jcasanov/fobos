SELECT "GYE" AS localidad, r10_codigo AS item, r10_nombre AS descripcion,
        r10_cod_clase AS cod_cla, r72_desc_clase AS desc_clase,
        r10_marca AS marca, r11_precio AS precio, r10_costo_mb AS costo,
        CASE WHEN r10_estado = "A" THEN "ACTIVO"
             WHEN r10_estado = "B" THEN "BLOQUEADO"
        END AS estado,
        NVL(SUM(r11_stock_act), 0) AS stock_act
        FROM aceros@acgyede:rept010, clase, stock
        WHERE r10_compania   = 1
          AND r72_linea      = r10_linea
          AND r72_sub_linea  = r10_sub_linea
          AND r72_cod_grupo  = r10_cod_grupo
          AND r72_cod_clase  = r10_cod_clase
          AND r11_localidad IN (1, 2)
          AND r11_item       = r10_codigo
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT "UIO" AS localidad, r10_codigo AS item, r10_nombre AS descripcion,
        r10_cod_clase AS cod_cla, r72_desc_clase AS desc_clase,
        r10_marca AS marca, r11_precio AS precio, r10_costo_mb AS costo,
        CASE WHEN r10_estado = "A" THEN "ACTIVO"
             WHEN r10_estado = "B" THEN "BLOQUEADO"
        END AS estado,
        NVL(SUM(r11_stock_act), 0) AS stock_act
        FROM acero_qm@acgyede:rept010, clase, stock
        WHERE r10_compania   = 1
          AND r72_linea      = r10_linea
          AND r72_sub_linea  = r10_sub_linea
          AND r72_cod_grupo  = r10_cod_grupo
          AND r72_cod_clase  = r10_cod_clase
          AND r11_localidad IN (3, 4, 5)
          AND r11_item       = r10_codigo
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9;

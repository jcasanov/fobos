unload to "stock_cen.unl"
SELECT 
	r11_stock_act stcok, r11_bodega bodega,
	r70_desc_sub linea, r73_desc_marca marca, 
	r10_codigo codigo, r10_nombre item, r10_precio_mb precio,
	r72_cod_clase clase, r72_desc_clase clase_nombre 
FROM 
	rept073, rept070, rept010, rept011, rept072
WHERE
	r11_compania = 1 and
	r11_bodega   = '70' and
	r10_compania = r11_compania
--	and r10_estado = "A"
	and r11_item = r10_codigo
	and r73_marca = r10_marca
	and r10_linea = r70_linea
	and r10_sub_linea = r70_sub_linea
	and r72_compania = r10_compania
	and r72_linea = r10_linea
	and r72_sub_linea = r10_sub_linea
	and r72_cod_grupo = r10_cod_grupo
	and r72_cod_clase = r10_cod_clase
and r11_stock_act > 0

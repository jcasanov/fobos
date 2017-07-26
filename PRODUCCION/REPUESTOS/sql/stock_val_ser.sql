unload to "stock_val_ser.txt"
select r31_item, r03_nombre, r70_desc_sub, r71_desc_grupo, r72_cod_clase,
	r72_desc_clase, r10_marca, r10_nombre, r31_bodega, r02_nombre,
	r31_stock, r31_costo_mb, (r31_costo_mb * r31_stock) costo_tot,
	r31_precio_mb, (r31_precio_mb * r31_stock) prec_tot
	from sermaco_qm@acgyede:rept031, sermaco_qm@acgyede:rept002,
		sermaco_qm@acgyede:rept010, sermaco_qm@acgyede:rept003,
		sermaco_qm@acgyede:rept070, sermaco_qm@acgyede:rept071,
		sermaco_qm@acgyede:rept072
	where r31_compania     = 2
	  and r31_ano          = 2006
	  and r31_mes          = 12
	  and r02_compania     = r31_compania
	  and r02_codigo       = r31_bodega
	  and r10_compania     = r31_compania
	  and r10_codigo       = r31_item
	  and r03_compania     = r10_compania
	  and r03_codigo       = r10_linea
	  and r70_compania     = r10_compania
	  and r70_linea        = r10_linea
	  and r70_sub_linea    = r10_sub_linea
	  and r71_compania     = r10_compania
	  and r71_linea        = r10_linea
	  and r71_sub_linea    = r10_sub_linea
	  and r71_cod_grupo    = r10_cod_grupo
	  and r72_compania     = r10_compania
	  and r72_linea        = r10_linea
	  and r72_sub_linea    = r10_sub_linea
	  and r72_cod_grupo    = r10_cod_grupo
	  and r72_cod_clase    = r10_cod_clase
union
select r31_item, r03_nombre, r70_desc_sub, r71_desc_grupo, r72_cod_clase,
	r72_desc_clase, r10_marca, r10_nombre, r31_bodega, r02_nombre,
	r31_stock, r31_costo_mb, (r31_costo_mb * r31_stock) costo_tot,
	r31_precio_mb, (r31_precio_mb * r31_stock) prec_tot
	from sermaco_gm@acgyede:rept031, sermaco_gm@acgyede:rept002,
		sermaco_gm@acgyede:rept010, sermaco_gm@acgyede:rept003,
		sermaco_gm@acgyede:rept070, sermaco_gm@acgyede:rept071,
		sermaco_gm@acgyede:rept072
	where r31_compania     = 2
	  and r31_ano          = 2006
	  and r31_mes          = 12
	  and r02_compania     = r31_compania
	  and r02_codigo       = r31_bodega
	  and r10_compania     = r31_compania
	  and r10_codigo       = r31_item
	  and r03_compania     = r10_compania
	  and r03_codigo       = r10_linea
	  and r70_compania     = r10_compania
	  and r70_linea        = r10_linea
	  and r70_sub_linea    = r10_sub_linea
	  and r71_compania     = r10_compania
	  and r71_linea        = r10_linea
	  and r71_sub_linea    = r10_sub_linea
	  and r71_cod_grupo    = r10_cod_grupo
	  and r72_compania     = r10_compania
	  and r72_linea        = r10_linea
	  and r72_sub_linea    = r10_sub_linea
	  and r72_cod_grupo    = r10_cod_grupo
	  and r72_cod_clase    = r10_cod_clase
	order by 1;

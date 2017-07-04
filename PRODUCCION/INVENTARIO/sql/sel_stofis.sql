unload to "inventar_gc.txt" 
	select te_localidad, te_bodega, r03_nombre, r70_desc_sub,
		r71_desc_grupo, r72_desc_clase, r73_desc_marca, te_item,
		r10_nombre, te_stock_act, te_bueno, te_incompleto, te_mal_est,
		te_suma, te_fecha, te_fec_modifi
		from te_stofis, rept010 , rept003, rept070, rept071, rept072,
			rept073
		where te_compania   = 1
		  and r10_compania  = te_compania 
		  and r10_codigo    = te_item
		  and r03_compania  = r10_compania
		  and r03_codigo    = r10_linea
		  and r70_compania  = r10_compania
		  and r70_linea     = r10_linea
		  and r70_sub_linea = r10_sub_linea 
		  and r71_compania  = r10_compania
		  and r71_linea     = r10_linea
		  and r71_sub_linea = r10_sub_linea 
		  and r71_cod_grupo = r10_cod_grupo
		  and r72_compania  = r10_compania
		  and r72_linea     = r10_linea
		  and r72_sub_linea = r10_sub_linea 
		  and r72_cod_grupo = r10_cod_grupo
		  and r72_cod_clase = r10_cod_clase
		  and r73_compania  = r10_compania
		  and r73_marca     = r10_marca;

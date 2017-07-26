unload to "items_bombas.txt"
	select r03_nombre, r70_desc_sub, r71_desc_grupo, r72_desc_clase,
		r73_desc_marca, r10_codigo[1, 6], r10_nombre
		from rept010, rept003, rept070, rept071, rept072, rept073
		where r10_compania  = 1
		  and r10_linea     = '2'
		  and r10_sub_linea = '22'
		  and r03_compania  = r10_compania
		  and r03_codigo    = r10_linea
		  and r70_compania  = r03_compania
		  and r70_linea     = r03_codigo
		  and r70_sub_linea = r10_sub_linea
		  and r71_compania  = r70_compania
		  and r71_linea     = r70_linea
		  and r71_sub_linea = r70_sub_linea
		  and r71_cod_grupo = r10_cod_grupo
		  and r72_compania  = r71_compania
		  and r72_linea     = r71_linea
		  and r72_sub_linea = r71_sub_linea
		  and r72_cod_grupo = r71_cod_grupo
		  and r72_cod_clase = r10_cod_clase
		  and r73_compania  = r10_compania
		  and r73_marca     = r10_marca
		order by 1, 2, 3, 4, 5, 6;

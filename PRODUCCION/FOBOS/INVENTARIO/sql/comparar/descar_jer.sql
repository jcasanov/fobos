unload to "lineas.txt"
	select r70_linea, r70_sub_linea, r70_desc_sub
		from rept070
		where r70_compania = 1;
unload to "grupos.txt"
	select r71_linea, r71_sub_linea, r71_cod_grupo, r71_desc_grupo
		from rept071
		where r71_compania = 1;
unload to "clases.txt"
	select r72_linea, r72_sub_linea, r72_cod_grupo, r72_cod_clase,
			r72_desc_clase
		from rept072
		where r72_compania = 1;
unload to "marcas.txt"
	select r73_marca, r73_desc_marca
		from rept073
		where r73_compania = 1;
unload to "items.txt"
	select r10_codigo, r10_estado
		from rept010
		where r10_compania = 1;

unload to "item_marca_dif.txt"
	select a.r10_codigo, c.r72_desc_clase, d.r72_desc_clase, a.r10_nombre,
		a.r10_marca marca_gye, b.r10_marca marca_uio, a.r10_estado,
		b.r10_estado
		from rept010 a, acero_qm:rept010 b,
			rept072 c, acero_qm:rept072 d
		where a.r10_compania   = 1
		  and c.r72_compania   = a.r10_compania
		  and c.r72_linea      = a.r10_linea
		  and c.r72_sub_linea  = a.r10_sub_linea
		  and c.r72_cod_grupo  = a.r10_cod_grupo
		  and c.r72_cod_clase  = a.r10_cod_clase
		  and b.r10_compania   = a.r10_compania
		  and b.r10_codigo     = a.r10_codigo
		  and b.r10_marca     <> a.r10_marca
		  and d.r72_compania   = b.r10_compania
		  and d.r72_linea      = b.r10_linea
		  and d.r72_sub_linea  = b.r10_sub_linea
		  and d.r72_cod_grupo  = b.r10_cod_grupo
		  and d.r72_cod_clase  = b.r10_cod_clase
		order by 1;

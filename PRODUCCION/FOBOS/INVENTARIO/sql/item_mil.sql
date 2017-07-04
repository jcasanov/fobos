unload to "item_mil.unl"
        select r10_codigo, r72_desc_clase, r10_nombre
		from rept010, rept072
		where r10_compania  = 1
		  and r10_marca     = 'MILWAU'
		  and r72_compania  = r10_compania
		  and r72_linea     = r10_linea
		  and r72_sub_linea = r10_sub_linea
		  and r72_cod_grupo = r10_cod_grupo
		  and r72_cod_clase = r10_cod_clase;

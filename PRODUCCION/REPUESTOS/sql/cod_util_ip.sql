unload to "cod_util_ip.txt"
	select r10_codigo, r10_nombre, r10_cod_util
		from rept010
		where r10_compania  = 1
		  and r10_linea     = '1'
		  and r10_sub_linea = '10'
		  and r10_cod_grupo = '101'
		  and r10_cod_clase = '101.P250'
		  and r10_marca     = 'NACION'
		order by 1;
unload to "cod_util_re.txt"
	select r10_codigo, r10_nombre, r10_cod_util
		from rept010
		where r10_compania  = 1
		  and r10_cod_util  = 'RE000'
		order by 1;

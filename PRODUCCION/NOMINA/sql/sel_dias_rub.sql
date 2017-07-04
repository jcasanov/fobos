select n06_cod_rubro cd_rub, n16_flag_ident fi, n16_descripcion desc,
	rolt008.*
	from rolt016, rolt006, outer rolt008
	where n16_flag_ident[1, 1] = 'D'
	  and n06_flag_ident       = n16_flag_ident
	  and n08_cod_rubro        = 1
	  and n08_rubro_base       = n06_cod_rubro
	order by n06_cod_rubro;

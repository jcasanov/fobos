select * from rolt006 where n06_cod_rubro in (61) order by n06_cod_rubro;
select * from rolt007 where n07_cod_rubro in (61) order by n07_cod_rubro;
select * from rolt008 where n08_cod_rubro in (61) order by n08_cod_rubro;
select * from rolt009
	where n09_compania  = 1
	  and n09_cod_rubro in (61)
	order by n09_cod_rubro;
select * from rolt010
	where n10_compania  = 1
	  and n10_cod_rubro in (61)
	order by n10_cod_rubro;
select * from rolt011
	where n11_compania  = 1
	  and n11_cod_rubro in (61)
	order by n11_cod_rubro;
select n06_cod_rubro, rolt016.*
	from rolt006, rolt016
	where n06_cod_rubro  in (61)
	  and n16_flag_ident = n06_flag_ident
	order by n06_cod_rubro;

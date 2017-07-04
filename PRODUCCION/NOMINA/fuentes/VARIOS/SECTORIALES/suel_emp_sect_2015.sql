select n30_cod_trab as codigo,
	n30_nombres as empleados,
	n30_sueldo_mes as sueldo_act,
	n30_sectorial as sect_act,
	a.n17_descripcion as nom_sect_act,
	(select c.n17_sectorial
		from rolt017 c
		where c.n17_compania  = a.n17_compania
		  and c.n17_ano_sect  = 2015
		  and c.n17_sectorial = a.n17_sectorial) as sect_nue,
	(select c.n17_descripcion
		from rolt017 c
		where c.n17_compania  = a.n17_compania
		  and c.n17_ano_sect  = 2015
		  and c.n17_sectorial = a.n17_sectorial) as nom_sect_nue,
	(select c.n17_valor
		from rolt017 c
		where c.n17_compania  = a.n17_compania
		  and c.n17_ano_sect  = 2015
		  and c.n17_sectorial = a.n17_sectorial) as val_sect_nue,
	round((select c.n17_valor
		from rolt017 c
		where c.n17_compania  = a.n17_compania
		  and c.n17_ano_sect  = 2015
		  and c.n17_sectorial = a.n17_sectorial) - n30_sueldo_mes, 2)
		as dif_ajustar,
	case when n30_estado = "A"
		then "ACTIVO"
		else "INACTIVO"
	end as estado
	from rolt030, rolt017 a
	where n30_compania    = 1
	  and n30_estado      = "A"
	  and a.n17_compania  = n30_compania
	  and a.n17_ano_sect  = n30_ano_sect
	  and a.n17_sectorial = n30_sectorial
	  and n30_sueldo_mes  <
		(select b.n17_valor
			from rolt017 b
			where b.n17_compania  = a.n17_compania
			  and b.n17_ano_sect  = 2015
			  and b.n17_sectorial = a.n17_sectorial)
	order by 2 asc;

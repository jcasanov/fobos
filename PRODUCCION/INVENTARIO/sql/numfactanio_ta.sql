select count(*) cuantas, month(t23_fecing) mes
 	from talt023
	where t23_compania     = 1
	  and t23_localidad    = 1
	  and t23_estado       in ('F', 'D')
	  and year(t23_fecing) = 2004
	group by 2
	order by 2

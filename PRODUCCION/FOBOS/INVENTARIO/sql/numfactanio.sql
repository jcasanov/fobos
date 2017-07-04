select count(*) cuantas, month(r19_fecing) mes
 	from rept019
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     = 'FA'
	  and year(r19_fecing) = 2003
	group by 2
	order by 2

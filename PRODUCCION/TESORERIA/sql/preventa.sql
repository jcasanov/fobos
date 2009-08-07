select r21_numprof, r21_tot_costo, sum(r22_costo * r22_cantidad)
	from rept021, rept022
	where r21_compania  = 1
	  and r21_localidad = 1
-- and r21_numprof   = 117
	  and r22_compania  = r21_compania
	  and r22_localidad = r21_localidad
	  and r22_numprof   = r21_numprof
	group by r21_numprof, r21_tot_costo

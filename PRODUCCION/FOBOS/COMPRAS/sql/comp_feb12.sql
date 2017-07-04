select c10_tipo_orden tipo, c01_nombre[1, 10] nom_tipo, --c01_aux_cont cta,
	sum((c10_tot_repto + c10_tot_mano) - c10_tot_dscto + 
	c10_dif_cuadre + c10_otros) tot_comp,
	from ordt010, ordt001
	where c10_compania  = 1
	  and c10_estado    = 'C'
	  and extend(c10_fecha_fact, year to month) = '2012-02'
	  and c01_tipo_orden = c10_tipo_orden
	group by 1, 2
	into temp t1;
	order by 1;

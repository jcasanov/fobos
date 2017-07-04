select t23_orden, round((select NVL(SUM((c11_precio - c11_val_descto) *
			(1 + c10_recargo / 100)), 0)
			from ordt010, ordt011
			where c10_compania    = t23_compania
			  and c10_localidad   = t23_localidad
			  and c10_ord_trabajo = t23_orden
			  and c11_compania    = c10_compania
			  and c11_localidad   = c10_localidad
			  and c11_numero_oc   = c10_numero_oc
			  and c11_tipo        = "S") +
		(select NVL(SUM(((c11_cant_ped * c11_precio) - c11_val_descto)
			* (1 + c10_recargo / 100)), 0)
			from ordt010, ordt011
			where c10_compania    = t23_compania
			  and c10_localidad   = t23_localidad
			  and c10_ord_trabajo = t23_orden
			  and c11_compania    = c10_compania
			  and c11_localidad   = c10_localidad
			  and c11_numero_oc   = c10_numero_oc
			  and c11_tipo        = "B"), 2) valor_oc
	from talt023
	where t23_compania  = 1
	  and t23_localidad = 1
	group by 1, 2
	order by 1 desc;
select * from talt023 where t23_orden = 453;
select c10_ord_trabajo, c10_numero_oc, c10_estado
	from ordt010
	where c10_ord_trabajo is not null
	  and c10_estado <> 'E'
	order by 1 desc;

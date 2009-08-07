select t23_orden, t23_tipo_ot, t23_estado, t23_val_otros1
	from talt023
	where t23_compania  = 1
	  and t23_localidad = 1
	  and t23_estado not in ('F', 'D')
	  and t23_val_otros1 > 0

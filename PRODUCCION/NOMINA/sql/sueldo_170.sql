select n30_num_doc_id codigo, n30_nombres empleado, n30_sueldo_mes sueldo
	from rolt030
	where n30_compania = 1
	  and n30_estado   = 'A'
	  and n30_sueldo_mes < 170
	order by 2

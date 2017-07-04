unload to "empl_nue.txt"
	select n30_num_doc_id, n30_nombres, n30_domicilio, n30_telef_domic
		from rolt030
		where n30_estado          = 'A'
		  and extend(n30_fecha_ing, year to month) =
			extend(today, year to month)
		order by n30_nombres;

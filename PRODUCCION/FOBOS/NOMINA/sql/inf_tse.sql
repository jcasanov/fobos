unload to "empleados_tse.unl"
	select n30_num_doc_id, n30_nombres, 20
		from rolt030
		where n30_compania = 1
		  and n30_estado   = 'A'
		order by n30_nombres;

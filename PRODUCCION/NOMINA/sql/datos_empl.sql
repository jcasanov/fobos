unload to "empleados.unl"
	select n30_num_doc_id, n30_nombres
		from rolt030
		where n30_compania = 1
		  and n30_estado   = 'A'
		order by 2;

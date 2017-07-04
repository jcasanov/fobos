unload to "empl_sect.txt"
	select n30_nombres, n17_descripcion, g35_nombre
		from rolt030, rolt017, gent035
		where n30_compania  = 1
		  and n30_estado    = 'A'
		  and n17_sectorial = n30_sectorial
		  and g35_compania  = n30_compania
		  and g35_cod_cargo = n30_cod_cargo
		order by 1;

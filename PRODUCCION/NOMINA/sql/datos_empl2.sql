unload to "empleados.txt"
	select n30_num_doc_id, n30_nombres, year(n30_fecha_ing) || "-" ||
		month(n30_fecha_ing) || "-" || day(n30_fecha_ing) fecha_ing,
		n30_sectorial, g35_nombre, n30_sueldo_mes, n30_domicilio
		from rolt030, gent035
		where n30_compania   = 1
		  and n30_estado     = 'A'
		  and n30_fecha_ing >= mdy (07, 01, 2004)
		  and g35_compania   = n30_compania
		  and g35_cod_cargo  = n30_cod_cargo
		order by n30_nombres;

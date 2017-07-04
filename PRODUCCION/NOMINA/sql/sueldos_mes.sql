unload to "sueldos_emp200605.txt"
	select n30_cod_trab, n30_nombres, n30_sueldo_mes
		from rolt030
		where n30_estado = 'A'
		order by n30_nombres;

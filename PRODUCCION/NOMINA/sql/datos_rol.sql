unload to "trabajadores.txt"
	select n30_cod_trab, n30_nombres
		from rolt030
		where n30_compania = 1
		  and n30_estado   = 'A'
		order by 2;

select unique lpad(n30_cod_trab, 3, 0) cod, n30_nombres[1, 29] empleados,
	n30_sueldo_mes sue_nue, a.n32_sueldo sue_ant,
	(n30_sueldo_mes - a.n32_sueldo) aumento
	from rolt030, rolt032 a
	where n30_compania     in (1, 2)
	  and n30_estado        = 'A'
	  and a.n32_compania    = n30_compania
	  and a.n32_cod_liqrol in ('Q1', 'Q2')
	  and a.n32_cod_trab    = n30_cod_trab
	  and a.n32_fecha_fin   =
		(select max(b.n32_fecha_fin)
			from rolt032 b
			where b.n32_compania   = a.n32_compania
			  and b.n32_cod_liqrol = a.n32_cod_liqrol
			  and b.n32_cod_trab   = a.n32_cod_trab)
	  and a.n32_sueldo     <> n30_sueldo_mes
	order by 5 desc, 2;

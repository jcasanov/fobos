select lpad(n39_cod_trab, 3, 0) cod, n30_nombres[1, 23] empleados,
	n39_periodo_ini per_ini, n39_periodo_fin per_fin,
	n39_perini_real p_r_i, n39_perfin_real p_f_r
	from rolt039, rolt030
	where n39_compania     = 1
	  and n39_periodo_ini <> n39_perini_real
	  and n30_compania     = n39_compania
	  and n30_cod_trab     = n39_cod_trab
	order by 2, 3 desc;

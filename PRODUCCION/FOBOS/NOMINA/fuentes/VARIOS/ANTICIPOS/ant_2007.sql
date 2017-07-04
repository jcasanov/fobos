select n33_cod_trab cod, n30_nombres[1, 35] empleado, n33_fecha_fin fecha,
	n33_valor val_ant
	from rolt033, rolt030
	where n33_compania    = 1
	  and n33_cod_liqrol in('Q1', 'Q2')
	  and n33_fecha_fin  >= mdy(01, 01, 2007)
	  and n33_cod_rubro   = 50
	  and n33_valor       > 0
	  and n30_compania    = n33_compania
	  and n30_cod_trab    = n33_cod_trab
	order by 2, 3;

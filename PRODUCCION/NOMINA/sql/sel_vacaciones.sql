select n30_nombres, n33_valor
	from rolt033, rolt030
	where n33_compania    = 1
	  and n33_cod_liqrol  in('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy(01,01,2005)
	  and n33_fecha_fin  <= mdy(01,31,2005)
	  and n33_cod_rubro   = 12
	  and n33_valor       > 0
	  and n30_compania    = n33_compania
	  and n30_cod_trab    = n33_cod_trab
	order by 1;

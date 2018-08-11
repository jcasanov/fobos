unload to "emplado_reser.txt"
select n33_cod_trab, n30_nombres, round(nvl(sum(n33_valor), 0), 2) tot_gan
	from rolt033, rolt030
	where n33_compania    = 1
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy (07, 01, 2004)
	  and n33_fecha_fin  <= mdy (06, 30, 2005)
	  and n33_cod_rubro  <> 14		-- menos el RUS
	  and n33_det_tot     = 'DI'
	  and n33_cant_valor  = 'V'
	  and n33_valor       > 0
	  and n30_compania    = n33_compania
	  and n30_cod_trab    = n33_cod_trab
	  and n30_estado      = 'A'
	group by 1, 2
	order by 2 asc;

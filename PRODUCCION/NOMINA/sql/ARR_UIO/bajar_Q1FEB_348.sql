unload to "n32_Q1FEB_348.unl"
	select * from rolt032
		where n32_compania   = 1
		  and n32_cod_liqrol = 'Q1'
		  and n32_fecha_ini  = mdy(02,01,2005)
		  and n32_fecha_fin  = mdy(02,15,2005)
		  and n32_cod_trab   = 348;

unload to "n33_Q1FEB_348.unl"
	select * from rolt033
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q1'
		  and n33_fecha_ini  = mdy(02,01,2005)
		  and n33_fecha_fin  = mdy(02,15,2005)
		  and n33_cod_trab   = 348;


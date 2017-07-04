unload to "rolt032.txt"
	select * from rolt032
		where n32_compania   = 1
		  and n32_cod_liqrol = 'Q2'
		  and n32_fecha_ini  = mdy(11, 16, 2004)
		  and n32_fecha_fin  = mdy(11, 30, 2004);
unload to "rolt033.txt"
	select * from rolt033
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q2'
		  and n33_fecha_ini  = mdy(11, 16, 2004)
		  and n33_fecha_fin  = mdy(11, 30, 2004);

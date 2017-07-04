--unload to "empl_antq2dic06.txt"
	select n30_nombres empleado, n33_valor valor_pago_prest
		from rolt033, rolt030
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q2'
		  and n33_fecha_ini  = mdy(12,16,2006)
		  and n33_fecha_fin  = mdy(12,31,2006)
		  and n33_cod_rubro  = 50
		  and n33_valor      > 0
		  and n30_compania   = n33_compania
		  and n30_cod_trab   = n33_cod_trab
		order by 1;

select unique n32_cod_liqrol, n32_fecha_ini, n32_fecha_fin
	from rolt032, rolt033
	where n32_compania   = 1
	  and n32_cod_trab   = 82
	  and n32_fecha_ini >= mdy(07,01,2005)
	  and n32_fecha_fin <= today
	  and n32_dias_trab  < 15
	  and n32_dias_falt  = 0
	  and n33_compania   = n32_compania
          and n33_cod_liqrol = n32_cod_liqrol
          and n33_fecha_ini  = n32_fecha_ini
          and n33_fecha_fin  = n32_fecha_fin
          and n33_cod_trab   = n32_cod_trab
          and n33_cod_rubro  = 11
	  and n33_valor      = 0
	order by 3;

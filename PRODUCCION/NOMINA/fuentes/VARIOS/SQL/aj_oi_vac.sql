begin work;

	update rolt032
		set n32_tot_gan  = n32_tot_gan  + 1.09,
		    n32_tot_ing  = n32_tot_ing  + 1.09
		where n32_compania   = 1
		  and n32_cod_liqrol = 'Q1'
		  and n32_fecha_ini  = mdy(11, 01, 2009)
		  and n32_fecha_fin  = mdy(11, 15, 2009)
		  and n32_cod_trab   = 117;

	update rolt033
		set n33_valor = n33_valor + 1.09
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q1'
		  and n33_fecha_ini  = mdy(11, 01, 2009)
		  and n33_fecha_fin  = mdy(11, 15, 2009)
		  and n33_cod_trab   = 117
		  and n33_cod_rubro  in (select n06_cod_rubro
					from rolt006
					where n06_flag_ident = 'OV');

	select SUM(n33_valor) valor
		from rolt033
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q1'
		  and n33_fecha_ini  = mdy(11, 01, 2009)
		  and n33_fecha_fin  = mdy(11, 15, 2009)
		  and n33_cod_trab   = 117
		  and n33_cod_rubro  in (select n08_rubro_base
					from rolt006, rolt008
					where n06_flag_ident = 'AP'
					  and n08_cod_rubro  = n06_cod_rubro)
		into temp t1;

	update rolt033
		set n33_valor = ((select valor from t1) * 9.35 / 100)
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q1'
		  and n33_fecha_ini  = mdy(11, 01, 2009)
		  and n33_fecha_fin  = mdy(11, 15, 2009)
		  and n33_cod_trab   = 117
		  and n33_cod_rubro  in (select n06_cod_rubro
					from rolt006
					where n06_flag_ident = 'AP');

	update rolt032
		set n32_tot_egr  = (select sum(n33_valor)
					from rolt033
					where n33_compania   = n32_compania
					  and n33_cod_liqrol = n32_cod_liqrol
					  and n33_fecha_ini  = n32_fecha_ini
					  and n33_fecha_fin  = n32_fecha_fin
					  and n33_cod_trab   = n32_cod_trab
					  and n33_det_tot    = 'DE')
		where n32_compania   = 1
		  and n32_cod_liqrol = 'Q1'
		  and n32_fecha_ini  = mdy(11, 01, 2009)
		  and n32_fecha_fin  = mdy(11, 15, 2009)
		  and n32_cod_trab   = 117;

	update rolt032
		set n32_tot_neto = n32_tot_ing - n32_tot_egr
		where n32_compania   = 1
		  and n32_cod_liqrol = 'Q1'
		  and n32_fecha_ini  = mdy(11, 01, 2009)
		  and n32_fecha_fin  = mdy(11, 15, 2009)
		  and n32_cod_trab   = 117;

commit work;

drop table t1;

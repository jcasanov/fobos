select n32_cod_trab cod_t, n33_cod_rubro rubro, n33_valor valor
	from rolt032, rolt033
	where n32_compania   = 1
	  and n32_cod_liqrol = 'Q2'
	  and n32_fecha_ini  = mdy(06, 16, 2010)
	  and n32_fecha_fin  = mdy(06, 30, 2010)
	  and n33_compania   = n32_compania
	  and n33_cod_liqrol = n32_cod_liqrol
	  and n33_fecha_ini  = n32_fecha_ini
	  and n33_fecha_fin  = n32_fecha_fin
	  and n33_cod_trab   = n32_cod_trab
	  and n33_cod_rubro in (10, 11, 12, 13, 14, 61, 75)
	  and n33_valor      > 0
	into temp t1;
begin work;
	update rolt033
		set n33_valor = nvl((select n63_valor
				from rolt063, rolt062
				where n63_compania    = n33_compania
				  and n63_cod_liqrol  = n33_cod_liqrol
				  and n63_fecha_ini   = n33_fecha_ini
				  and n63_fecha_fin   = n33_fecha_fin
				  and n63_cod_trab    = n33_cod_trab
				  and n63_valor       > 0 
				  and n62_compania    = n63_compania
				  and n62_cod_almacen = n63_cod_almacen
				  and n62_cod_rubro   = n33_cod_rubro), 0)
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q1'
		  and n33_fecha_ini  = mdy(06, 01, 2010)
		  and n33_fecha_fin  = mdy(06, 15, 2010)
		  and n33_cod_rubro in
				(select unique n62_cod_rubro
				from rolt063, rolt062
				where n63_compania    = n33_compania
				  and n63_cod_liqrol  = n33_cod_liqrol
				  and n63_fecha_ini   = n33_fecha_ini
				  and n63_fecha_fin   = n33_fecha_fin
				  and n63_cod_trab    = n33_cod_trab
				  and n63_valor       > 0 
				  and n62_compania    = n63_compania
				  and n62_cod_almacen = n63_cod_almacen);
	update rolt033
		set n33_valor = n33_valor +
				nvl((select valor
					from t1
					where cod_t = n33_cod_trab
					  and rubro = n33_cod_rubro), 0)
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q1'
		  and n33_fecha_ini  = mdy(06, 01, 2010)
		  and n33_fecha_fin  = mdy(06, 15, 2010)
		  and n33_cod_trab  in (select unique cod_t from t1)
		  and n33_cod_rubro in (select unique rubro from t1);
	update rolt005
		set n05_activo     = 'S',
		    n05_fecini_act = mdy(06,01,2010),
		    n05_fecfin_act = mdy(06,15,2010)
		where n05_compania = 1
		  and n05_proceso  = 'Q1';
	update rolt005
		set n05_activo     = 'N',
		    n05_fecini_act = null,
		    n05_fecfin_act = null
		where n05_compania = 1
		  and n05_proceso  = 'Q2';
	delete from rolt033
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q2'
		  and n33_fecha_ini  = mdy(06, 16, 2010)
		  and n33_fecha_fin  = mdy(06, 30, 2010);
	delete from rolt032
		where n32_compania   = 1
		  and n32_cod_liqrol = 'Q2'
		  and n32_fecha_ini  = mdy(06, 16, 2010)
		  and n32_fecha_fin  = mdy(06, 30, 2010);
	update rolt032
		set n32_estado = 'A'
		where n32_compania   = 1
		  and n32_cod_liqrol = 'Q1'
		  and n32_fecha_ini  = mdy(06, 01, 2010)
		  and n32_fecha_fin  = mdy(06, 15, 2010);
commit work;
drop table t1;

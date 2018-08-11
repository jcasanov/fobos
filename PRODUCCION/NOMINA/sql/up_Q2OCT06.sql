select n33_compania cia, n33_cod_liqrol cod, n33_fecha_ini fec_ini,
	n33_fecha_fin fec_fin, n33_cod_trab cod_trab, n33_cod_rubro cod_rub,
	n33_valor valor
	from rolt033
	where n33_compania   = 1
	  and n33_cod_liqrol = 'Q2'
	  and n33_fecha_ini  = mdy(10,16,2006)
	  and n33_fecha_fin  = mdy(10,31,2006)
	  and n33_cod_rubro  in (13, 59)
	  and n33_valor      > 0
	into temp t1;
select count(*) tot_emp from t1;
begin work;
update rolt033
	set n33_valor = nvl((select valor - (valor * 9.35 / 100)
				from t1
				where cia      = n33_compania
				  and cod      = n33_cod_liqrol
				  and fec_ini  = n33_fecha_ini
				  and fec_fin  = n33_fecha_fin
				  and cod_trab = n33_cod_trab
				  and cod_rub  = 13), 0)
			-
	                nvl((select valor from t1
				where cia      = n33_compania
				  and cod      = n33_cod_liqrol
				  and fec_ini  = n33_fecha_ini
				  and fec_fin  = n33_fecha_fin
				  and cod_trab = n33_cod_trab
				  and cod_rub  = 59), 0)
	where n33_compania   = 1
	  and n33_cod_liqrol = 'Q2'
	  and n33_fecha_ini  = mdy(10,16,2006)
	  and n33_fecha_fin  = mdy(10,31,2006)
	  and n33_cod_trab   in (select unique cod_trab from t1)
	  and n33_cod_rubro  = 61;
commit work;
drop table t1;

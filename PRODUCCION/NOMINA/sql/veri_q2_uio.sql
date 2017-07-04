select n32_cod_trab codc, sum(n32_tot_egr) val_eg
	from rolt032
	where n32_compania   = 1
	  and n32_cod_liqrol = 'Q2'
	  and n32_fecha_ini  = mdy(03,16,2014)
	  and n32_fecha_fin  = mdy(03,31,2014)
	group by 1
	into temp t1;
select n33_cod_trab codd, sum(n33_valor) val_de
	from rolt033
	where n33_compania   = 1
	  and n33_cod_liqrol = 'Q2'
	  and n33_fecha_ini  = mdy(03,16,2014)
	  and n33_fecha_fin  = mdy(03,31,2014)
	  and n33_det_tot    = 'DE'
	  and n33_cant_valor = 'V'
	  and n33_valor      > 0
	group by 1
	into temp t2;
select codc, val_eg, val_de
	from t1, t2
	where codd    = codc
	  and val_de <> val_eg;
drop table t1;
drop table t2;

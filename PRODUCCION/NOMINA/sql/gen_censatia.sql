select n06_cod_rubro cod_rubro
	from rolt006
	where n06_estado    = 'A'
	  and n06_cod_rubro in (select n08_rubro_base from rolt008
				where n08_cod_rubro =
					(select a.n06_cod_rubro from rolt006 a
						where a.n06_flag_ident = 'FC'))
	into temp t1;
select count(*) tot_rub from t1;
select n33_cod_trab cod_trab, nvl((sum(n33_valor) * 0.05), 0) valor_per,
	nvl((sum(n33_valor) * 0.02), 0) valor_pat
	from rolt033
	where n33_compania   = 1
	  and n33_cod_liqrol = 'Q1'
	  and n33_fecha_ini  = mdy(05, 01, 2006)
	  and n33_fecha_fin  = mdy(05, 15, 2006)
	  and n33_cod_rubro  in (select cod_rubro from t1)
	  and n33_valor      > 0
	group by 1
	into temp t2;
drop table t1;
update rolt080
	set n80_q1_trab  = (select valor_per from t2
				where cod_trab = n80_cod_trab),
	    n80_q1_patr  = (select valor_pat from t2
				where cod_trab = n80_cod_trab),
	    n80_sac_trab = n80_sac_trab + (select valor_per from t2
						where cod_trab = n80_cod_trab),
	    n80_sac_patr = n80_sac_patr + (select valor_pat from t2
						where cod_trab = n80_cod_trab)
	where n80_compania = 1
	  and n80_ano      = 2006
	  and n80_mes      = 5
	  and n80_cod_trab in (select unique cod_trab from t2);
drop table t2;

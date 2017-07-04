select n46_compania, n46_cod_liqrol, n46_fecha_ini, n46_fecha_fin,
	n45_cod_trab, n45_cod_rubro, n45_num_prest, n46_valor
	from rolt045, rolt046
	where n45_compania  = 2
	  and n46_compania  = n45_compania
	  and n46_num_prest = n45_num_prest
	into temp t1;
select count(*) total_t1 from t1;
select n33_compania cia, n33_cod_liqrol lq, n33_fecha_ini fec_ini,
	n33_fecha_fin fec_fin, n33_cod_trab cod_trab, n33_cod_rubro cod_rub,
	n33_valor valor
	from rolt033
	where n33_compania   = 2
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_cod_rubro  = 50
	  and n33_num_prest  is null
	  and n33_valor      > 0
	into temp t2;
select count(*) total_t2 from t2;
select * from t2, t1
	where cia      = n46_compania
	  and lq       = n46_cod_liqrol
	  and fec_ini  = n46_fecha_ini
	  and fec_fin  = n46_fecha_fin
	  and cod_trab = n45_cod_trab
	  and cod_rub  = n45_cod_rubro
	into temp t3;
drop table t1;
drop table t2;
select count(*) total_t3 from t3;
--select * from t3 order by cod_trab, fec_fin;
begin work;
update rolt033
	set n33_num_prest = (select n45_num_prest
				from t3
				where n46_compania   = n33_compania
				  and n46_cod_liqrol = n33_cod_liqrol
				  and n46_fecha_ini  = n33_fecha_ini
				  and n46_fecha_fin  = n33_fecha_fin
				  and n46_valor      = n33_valor
				  and n45_cod_trab   = n33_cod_trab
				  and n45_cod_rubro  = n33_cod_rubro)
	where exists (select * from t3
			where cia      = n33_compania
			  and lq       = n33_cod_liqrol
	  		  and fec_ini  = n33_fecha_ini
	  		  and fec_fin  = n33_fecha_fin
	  		  and cod_trab = n33_cod_trab
	  		  and cod_rub  = n33_cod_rubro);
commit work;
drop table t3;

select unique n56_compania cia_c, n56_aux_val_vac cta_ant,
	n56_cod_trab cod_trab_c, n56_proceso proc
	from rolt056
	where n56_compania in (1, 2)
	  and n56_proceso  in (select unique n18_flag_ident
				from rolt018)
	into temp tmp_n56;
select proc, cta_ant, cod_trab_c, nvl(sum(b13_valor_base), 0) saldo_cont
	from tmp_n56, ctbt012, ctbt013
	where b12_compania  = cia_c
	  and b12_estado    = 'M'
	  and b13_compania  = b12_compania
	  and b13_tipo_comp = b12_tipo_comp
	  and b13_num_comp  = b12_num_comp
	  and b13_cuenta    = cta_ant
	group by 1, 2, 3
	--having sum(b13_valor_base) <> 0
	into temp t1;
select unique cta_ant, cod_trab_c, saldo_cont
	from t1
	into temp tmp_sal;
drop table t1;
select * from rolt045, rolt046
	where n45_compania  in (1, 2)
	  and n45_estado    in ('A', 'R')
	  and n46_compania   = n45_compania
	  and n46_num_prest  = n45_num_prest
	into temp tmp_prest;
select n45_compania cia, n45_num_prest num_prest, n45_cod_rubro cod_rubro,
	n45_cod_trab cod_trab, n30_nombres empleado, n45_val_prest prestamo,
	n45_descontado descont, n45_valor_int val_int, n46_secuencia divi,
	n46_cod_liqrol lq, n46_fecha_ini fec_ini, n46_fecha_fin fec_fin,
	n46_valor valor, n46_saldo saldo, n33_num_prest num_ant, n33_valor
	val_rol, n45_sal_prest_ant saldo_ante,
	(select unique n18_flag_ident
		from rolt018
		where n18_cod_rubro = n45_cod_rubro) proceso
	from tmp_prest, rolt032, rolt033, rolt030
	where n32_compania   = n45_compania
	  and n32_cod_liqrol = n46_cod_liqrol
	  and n32_fecha_ini  = n46_fecha_ini
	  and n32_fecha_fin  = n46_fecha_fin
	  and n32_cod_trab   = n45_cod_trab
	  and n32_estado     = 'C'
	  and n33_compania   = n32_compania
	  and n33_cod_liqrol = n32_cod_liqrol
	  and n33_fecha_ini  = n32_fecha_ini
	  and n33_fecha_fin  = n32_fecha_fin
	  and n33_cod_trab   = n32_cod_trab
	  and n33_cod_rubro  = n45_cod_rubro
	  and n33_valor      > 0
	  and n30_compania   = n45_compania
	  and n30_cod_trab   = n45_cod_trab
	into temp t1;
insert into t1
	select n45_compania cia, n45_num_prest num_prest, n45_cod_rubro
		cod_rubro, n45_cod_trab cod_trab, n30_nombres empleado,
		n45_val_prest prestamo, n45_descontado descont, n45_valor_int
		val_int, n46_secuencia divi, n46_cod_liqrol lq, n46_fecha_ini
		fec_ini, n46_fecha_fin fec_fin, n46_valor valor, n46_saldo
		saldo, n45_num_prest num_ant, 0 val_rol, n45_sal_prest_ant
		saldo_ante, (select n18_flag_ident
				from rolt018
				where n18_cod_rubro = n45_cod_rubro) proceso
		from tmp_prest, rolt030
		where n46_saldo      > 0
		  and n30_compania   = n45_compania
		  and n30_cod_trab   = n45_cod_trab
		  and not exists
			(select 1 from t1
			where t1.cia       = tmp_prest.n45_compania
			  and t1.num_prest = tmp_prest.n45_num_prest)
		  and not exists
			(select 1 from rolt032, rolt033
			where n32_compania   = n45_compania
			  and n32_cod_liqrol = n46_cod_liqrol
			  and n32_fecha_ini  = n46_fecha_ini
			  and n32_fecha_fin  = n46_fecha_fin
			  and n32_cod_trab   = n45_cod_trab
			  and n32_estado     = 'C'
			  and n33_compania   = n32_compania
			  and n33_cod_liqrol = n32_cod_liqrol
			  and n33_fecha_ini  = n32_fecha_ini
			  and n33_fecha_fin  = n32_fecha_fin
			  and n33_cod_trab   = n32_cod_trab
			  and n33_cod_rubro  = n45_cod_rubro);
drop table tmp_prest;
select count(*) tot_empl_prest from t1;
select count(unique num_prest) tot_prest from t1;
select cia, num_prest, proceso, cod_rubro, cod_trab, empleado, prestamo,val_int,
	descont, saldo_ante, round(descont + nvl(sum(saldo), 0), 2) val_n,
	nvl(sum(val_rol), 0) val_r
	from t1
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	into temp t2;
--select * from t2 where val_n < val_r into temp t3;
--drop table t2;
select count(*) tot_empl_t2 from t2;
--select * from t3 order by num_prest;
--select * from t1 order by empleado;
--select num_prest, empleado, prestamo from t2 order by empleado, num_prest;
select t2.*, (prestamo + val_int - descont + saldo_ante) val_anti
	from t2
	into temp t4;
drop table t2;
{--
select t4.*, saldo_cont, cta_ant
	from t4, tmp_sal
	where cod_trab  = cod_trab_c
 	  and val_anti <> saldo_cont
	into temp t3;
--}
select cia, cta_ant cta, cod_trab, empleado,
	nvl(sum(prestamo), 0) prestamo, nvl(sum(val_int), 0) val_int,
	nvl(sum(descont), 0) descont, nvl(sum(saldo_ante), 0) saldo_ante,
	round(nvl(sum(val_n), 0), 2) val_n, round(nvl(sum(val_r), 0), 2) val_r,
	nvl(sum(val_anti), 0) val_anti
	from t4, tmp_n56
	where cia        = cia_c
	  and proc       = proceso
	  and cod_trab_c = cod_trab
	group by 1, 2, 3, 4
	into temp tmp_fin;
drop table t1;
drop table t4;
drop table tmp_n56;
select tmp_fin.*, saldo_cont, cta_ant,round(val_anti - saldo_cont, 2) diferencia
	from tmp_sal, tmp_fin
	where cod_trab  = cod_trab_c
	  and cta       = cta_ant
 	  and val_anti <> saldo_cont
	into temp t3;
drop table tmp_fin;
drop table tmp_sal;
select count(*) tot_empl_dif from t3;
select nvl(round(sum(saldo_cont), 2), 0) tot_sal_con,
	nvl(round(sum(val_anti), 2), 0) tot_val_ant,
	nvl(round(sum(diferencia), 2), 0) tot_dife
	from t3;
select * from t3 order by empleado;
drop table t3;

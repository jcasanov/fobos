select lpad(a.n32_ano_proceso, 4, 0) anio, lpad(a.n32_mes_proceso, 2, 0) mes,
	nvl(round(sum(a.n32_sueldo /
	(select count(*)
		from rolt032 b
		where b.n32_compania    = a.n32_compania
		  and b.n32_ano_proceso = a.n32_ano_proceso
		  and b.n32_mes_proceso = a.n32_mes_proceso
		  and b.n32_cod_trab    = a.n32_cod_trab)), 2), 0) sueldo,
	nvl(sum(a.n32_tot_gan), 0) tot_gan,
	nvl(sum(a.n32_tot_ing), 0) tot_ing,
	nvl(sum(a.n32_tot_egr), 0) tot_egr,
	nvl(sum(a.n32_tot_neto), 0) tot_net
	from rolt032 a
	where a.n32_compania    = 1
	  and a.n32_cod_liqrol in ('Q1', 'Q2')
	  and a.n32_fecha_ini  >= mdy(12, 01, 2003)
	  and a.n32_fecha_fin  <= mdy(03, 31, 2009)
	  and a.n32_cod_trab    = 117
	group by 1, 2
	into temp t1;
create temp table t2
	(
		sec	serial,
		fecha	datetime year to month,
		sueldo	decimal(12,2)
	);
select min(extend(mdy(mes, 01, anio), year to month)) fecha, sueldo
	from t1
	where sueldo in (select unique sueldo from t1)
	group by 2
	order by 1
	into temp caca;
insert into t2 select 0, fecha, sueldo from caca;
drop table caca;
select a.fecha, a.sueldo,
	nvl(round(a.sueldo -
		(select b.sueldo
		from t2 b
		where b.sec = a.sec - 1), 2), 0) aumento
	from t2 a
	order by 1;
select * from t1 order by 1, 2;
drop table t1;
drop table t2;

select lpad(n33_cod_trab, 3, 0) codtab, n30_nombres[1, 35] empleados,
	nvl(round(sum(n33_valor), 2), 0) valor
	from rolt033, rolt030
	where n33_compania   = 1
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_cod_rubro  = 58
	  and n33_valor      > 0
	  and n30_compania   = n33_compania
	  and n30_cod_trab   = n33_cod_trab
	group by 1, 2
	into temp t1;
select count(*) total_empleados from t1;
insert into t1
	select 000 cod, "z    TOTAL" emp, nvl(round(sum(a.valor), 2), 0) tot
		from t1 a
		group by 1, 2;
select * from t1 order by 2;
unload to "multas_no.txt" select * from t1 order by 2;
drop table t1;

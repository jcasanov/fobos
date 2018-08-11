--drop table t1;
select year(b12_fec_proceso) anio, b12_tipo_comp tc, b12_origen ori,
	round(nvl(sum(b13_valor_base), 0), 2) saldo
	from ctbt012, ctbt013
	where b12_compania  = 1
	  and b12_estado    = 'M'
	  and b13_compania  = b12_compania
	  and b13_tipo_comp = b12_tipo_comp
	  and b13_num_comp  = b12_num_comp
	  and b13_cuenta    = '11400102003'
	group by 1, 2, 3
	into temp t1;
select anio, nvl(round(sum(saldo), 2), 0) saldo_anio
	from t1
	group by 1
	order by 1;
select anio, nvl(round(sum(saldo), 2), 0) saldo_auto
	from t1
	where ori = 'A'
	group by 1
	order by 1;
select anio, nvl(round(sum(saldo), 2), 0) saldo_manual
	from t1
	where ori = 'M'
	group by 1
	order by 1;
select anio, tc, nvl(round(sum(saldo), 2), 0) saldo_gen
	from t1
	group by 1, 2
	order by 1, 2;
drop table t1;

select b13_tipo_comp tp, b13_num_comp num, b12_estado est, b12_fec_proceso fec,
	b13_cuenta cuenta,
	extend(b13_fec_proceso, year to month) fecha,
	nvl(b13_valor_base, 0) saldo
	from ctbt012, ctbt013
	where b12_compania     = 2
	  and b12_fec_proceso >= mdy(01, 01, 2005)
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_cuenta       = '21040201002'
	into temp t1;
select * from t1 where est = 'E' order by fecha, tp, num;
select est, count(*) tot_diarios from t1 group by 1;
select count(*) tot_diarios from t1;
select nvl(round(sum(saldo), 2), 0) saldo_al
	from t1
	where fecha < '2005-01'
	  and est   = 'M'
	into temp t2;
select * from t2;
select fecha, nvl(round(sum(saldo), 2), 0) saldo
	from t1
	where fecha >= '2005-01'
	  and est    = 'M'
	group by 1
	order by 1;
select nvl(round(sum(saldo), 2), 0) saldo_fin from t1 where est = 'M';
select tp, num, cuenta, fec, est, saldo
	from t1 where est = 'M' order by fec, tp, num;
drop table t1;
drop table t2;

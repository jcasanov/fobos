select b12_compania cia, b12_tipo_comp tp, b12_num_comp num, b12_estado est,
	b13_valor_base valor
	from ctbt012, ctbt013
	where b12_compania     = 1
	  and b12_estado      <> 'E'
	  and b12_fec_proceso between mdy(07, 01, 2008)
				  and mdy(07, 31, 2008)
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_cuenta       = '21040201001'
	into temp t1;
select b12_compania cia2, b12_tipo_comp tp2, b12_num_comp num2,
	b12_estado est2, sum(b13_valor_base) valor2
	from ctbt012, ctbt013
	where b12_compania     = 1
	  and b12_estado      <> 'E'
	  and b12_fec_proceso between mdy(07, 01, 2008)
				  and mdy(07, 31, 2008)
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  AND b13_cuenta                like "410101%"
	group by 1, 2, 3, 4
	into temp t2;

select sum(valor) from t1;
select sum(valor2) from t2;

--select tp, num, est, valor, round((valor2 * 0.12), 2) oper, valor2
select tp, num, est, valor, round((valor2 * 0.12),2) oper,
(round((valor2 * 0.12),2) - valor) dife,
valor2
from t1, t2
where
	cia = cia2
	and tp = tp2
	and num = num2

into temp t3;

select sum(valor) iva, sum(oper) t_op from t3;

select (abs(oper) - abs(valor)) dife from t3
into temp t4;

select sum(dife) from t4;
select * from t3 where dife <> 0;
drop table t4;
drop table t1;
drop table t2;
drop table t3;

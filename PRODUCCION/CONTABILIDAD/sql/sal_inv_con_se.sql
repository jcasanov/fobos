select 7 loc, b13_tipo_comp tp, b13_num_comp num,
	nvl(sum(b13_valor_base), 0) saldo
	from ctbt012, ctbt013
	where b12_compania    = 2
	  --and b12_estado      = 'M'
	  and b12_estado      <> 'E'
	  and b12_fec_proceso between mdy(01,01,2007) and today
	  and b13_compania    = b12_compania
	  and b13_tipo_comp   = b12_tipo_comp
	  and b13_num_comp    = b12_num_comp
	  and b13_cuenta      = '11400101006'
	group by 1, 2, 3
	into temp t1;
select 6 loc, b13_tipo_comp tp, b13_num_comp num,
	nvl(sum(b13_valor_base), 0) saldo
	from sermaco_gm@segye01:ctbt012, sermaco_gm@segye01:ctbt013
	where b12_compania    = 2
	  --and b12_estado      = 'M'
	  and b12_estado      <> 'E'
	  and b12_fec_proceso between mdy(01,01,2007) and today
	  and b13_compania    = b12_compania
	  and b13_tipo_comp   = b12_tipo_comp
	  and b13_num_comp    = b12_num_comp
	  and b13_cuenta      = '11400101006'
	group by 1, 2, 3
	into temp t2;
select loc, nvl(round(sum(saldo), 2), 0) saldo_loc from t1 group by 1;
select loc, nvl(round(sum(saldo), 2), 0) saldo_loc from t2 group by 1;
{
select a.loc, a.tp, a.num, nvl(round(sum(a.saldo), 2), 0) saldo_uio,
	b.loc loc1, b.tp tp1 , b.num num1,
	nvl(round(sum(b.saldo), 2), 0) saldo_gye
	from t1 a, outer t2 b
	where a.saldo <> b.saldo * (-1)
	group by 1, 2, 3, 5, 6, 7
	into temp t3;
}
drop table t1;
drop table t2;
--select * from t3 order by 8;
--drop table t3;

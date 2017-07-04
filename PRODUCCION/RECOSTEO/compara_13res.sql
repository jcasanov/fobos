select a.b13_tipo_comp, a.b13_num_comp, a.b13_cuenta, a.b13_valor_base vbr,
	b.b13_valor_base vb
from ctbt013_res a, ctbt013 b
where a.b13_compania  = b.b13_compania
  and a.b13_tipo_comp = b.b13_tipo_comp
  and a.b13_num_comp  = b.b13_num_comp
  and a.b13_cuenta    = b.b13_cuenta
  and a.b13_valor_base <> b.b13_valor_base
  and a.b13_compania = 99
into temp t1;
select * from t1 into temp t2;

load from "ctbt013_res180110.unl" insert into t1;
load from "26ENE10/ctbt013_res260110.unl" insert into t2;

select count(*) tot_t1 from t1;
select count(*) tot_t2 from t2;

select t1.b13_tipo_comp tc, t1.b13_num_comp nc, t2.*
from t2, outer t1
where
	t1.b13_tipo_comp = t2.b13_tipo_comp
	and t1.b13_num_comp = t2.b13_num_comp
	and t1.b13_cuenta = t2.b13_cuenta
	and t1.vb = t2.vb
INTO TEMP t3;

drop table t1;
drop table t2;

select count(*) tot_t3 from t3;

SELECT * FROM t3 WHERE tc is null into temp t4;

drop table t3;

select count(*) tot_t4 from t4;
select * from t4;

drop table t4;

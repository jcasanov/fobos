select * from rept019 where r19_compania = 999 into temp t1;
select * from rept020 where r20_compania = 999 into temp t2;
load from "rept019.unl" insert into t1;
load from "rept020.unl" insert into t2;
begin work;
insert into rept090
	(r90_compania, r90_localidad, r90_cod_tran, r90_num_tran, r90_fecing,
		r90_locali_fin)
	select r19_compania, r19_localidad, r19_cod_tran, r19_num_tran,
		r19_fecing, 1
		from t1;
insert into rept091 select * from t1;
insert into rept092 select * from t2;
select * from rept090 where r90_localidad = 2;
select * from rept091 where r91_localidad = 2;
select * from rept092 where r92_localidad = 2;
commit work;
drop table t1;
drop table t2;

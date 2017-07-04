select * from rolt032 where n32_compania = 23 into temp t1;
select * from rolt033 where n33_compania = 23 into temp t2;

load from "rolt032.unl" insert into t1;
load from "rolt033.unl" insert into t2;

select * from t1
	where n32_compania   = 1
	  and n32_cod_liqrol = 'Q1'
	  and n32_fecha_ini  = mdy(02,01,2005)
	  and n32_fecha_fin  = mdy(02,15,2005)
	into temp tmp_n32;

drop table t1;

select * from t2
	where n33_compania   = 1
	  and n33_cod_liqrol = 'Q1'
	  and n33_fecha_ini  = mdy(02,01,2005)
	  and n33_fecha_fin  = mdy(02,15,2005)
	into temp tmp_n33;

drop table t2;

unload to "n32_Q1FEB.unl" select * from tmp_n32;
unload to "n33_Q1FEB.unl" select * from tmp_n33;

drop table tmp_n32;
drop table tmp_n33;

select * from rolt032 where n32_compania = 23 into temp tmp_n32;
select * from rolt033 where n33_compania = 23 into temp tmp_n33;

load from "n32_Q1FEB.unl" insert into tmp_n32;
load from "n33_Q1FEB.unl" insert into tmp_n33;

load from "n32_Q1FEB_348.unl" insert into tmp_n32;
load from "n33_Q1FEB_348.unl" insert into tmp_n33;

begin work;

delete from rolt033
	where n33_compania   = 1
	  and n33_cod_liqrol = 'Q1'
	  and n33_fecha_ini  = mdy(02,01,2005)
	  and n33_fecha_fin  = mdy(02,15,2005);

delete from rolt032
	where n32_compania   = 1
	  and n32_cod_liqrol = 'Q1'
	  and n32_fecha_ini  = mdy(02,01,2005)
	  and n32_fecha_fin  = mdy(02,15,2005);

insert into rolt032 select * from tmp_n32;
insert into rolt033 select * from tmp_n33;

commit work;

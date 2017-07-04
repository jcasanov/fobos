select * from ordt003 where c03_compania = 99 into temp tmp_c03;

load from "ordt003_ori.unl" insert into tmp_c03;

select count(*) total_tmp_c03 from tmp_c03;

select tmp_c03.*, c02_compania
	from tmp_c03, outer ordt002
	where c02_compania   = c03_compania
	  and c02_tipo_ret   = c03_tipo_ret
	  and c02_porcentaje = c03_porcentaje
	into temp t1;

delete from t1 where c02_compania is null;

select count(*) total_t1 from t1;

select a.*
	from tmp_c03 a, t1 b
	where a.c03_compania   = b.c03_compania
	  and a.c03_tipo_ret   = b.c03_tipo_ret
	  and a.c03_porcentaje = b.c03_porcentaje
	  and a.c03_codigo_sri = b.c03_codigo_sri
	into temp t2;

select count(*) total_t2 from t2;

drop table tmp_c03;
drop table t1;

begin work;

	insert into ordt003 select * from t2;

commit work;

drop table t2;

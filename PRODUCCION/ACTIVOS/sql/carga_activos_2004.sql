begin work;

select * from actt010 where a10_compania = 15 into temp t1;

load from "activo_faltan.unl" insert into t1;

select a10_codigo_bien from t1 order by 1;

update t1 set a10_grupo_act = 1, a10_tipo_act = 601 where 1 = 1;

insert into actt010 select * from t1;

drop table t1;

commit work;

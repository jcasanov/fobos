select s10_compania, s10_codigo, s10_porcentaje_ice, s10_codigo_impto,
	s10_descripcion, s10_fecha_ini, s10_fecha_fin, s10_usuario
	from srit010
	where s10_compania = 999
	into temp t1;

load from "srit010.unl" insert into t1;

begin work;

insert into srit010
	(s10_compania, s10_codigo, s10_porcentaje_ice, s10_codigo_impto,
	 s10_descripcion, s10_fecha_ini, s10_fecha_fin, s10_usuario,
	 s10_fecing)
	select t1.*, current from t1;

commit work;

drop table t1;

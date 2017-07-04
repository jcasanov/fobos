select r104_compania cia, r104_localidad loc, r104_pre_ven_anio pl_anio,
	r104_pre_ven_mes pl_mes, r104_pre_ven_sem pl_sem, r104_vendedor vend,
	r104_cod_linea codlin, r104_pre_ven_val valor
	from rept104
	where r104_compania = 999
	into temp t1;

load from "rept104.csv" delimiter "," insert into t1;

insert into rept104
	(r104_compania, r104_localidad, r104_pre_ven_anio, r104_pre_ven_mes,
	 r104_pre_ven_sem, r104_vendedor, r104_cod_linea, r104_pre_ven_val,
	 r104_usuario, r104_fecing)
	select t1.*, "FOBOS", current
		from t1
		where loc = 4;

drop table t1;

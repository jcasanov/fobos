select n15_ano anio, n15_secuencia secu, n15_base_imp_ini bas_ini,
	n15_base_imp_fin bas_fin, n15_fracc_base fra_bas, n15_porc_ir porc
	from rolt015
	where n15_compania = 999
	into temp t1;

load from "tabla_ir.unl" insert into t1;

insert into rolt015
	select 1, anio, secu, bas_ini, bas_fin, fra_bas, (porc * 100),
		"FOBOS", current
		from t1;

drop table t1;

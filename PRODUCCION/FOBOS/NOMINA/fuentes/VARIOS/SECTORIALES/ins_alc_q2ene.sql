select n10_compania as cia,
	n10_cod_liqrol as liq,
	n10_cod_rubro as rub,
	n10_cod_trab as cod,
	n10_fecha_ini as fec_i,
	n10_fecha_fin as fec_f,
	n10_valor as valor,
	n10_usuario as usua
	from rolt010
	where n10_compania = 999
	into temp t1;

load from "alc_q2ene15.unl" delimiter "," insert into t1;

begin work;

	insert into rolt010
		select t1.*, current
			from t1;

--rollback work;
commit work;

drop table t1;

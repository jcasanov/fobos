select t24_orden numot, t24_mecanico tecni
	from talt024
	where t24_compania = 999
	into temp t1;

load from "camb_tec.unl" insert into t1;

begin work;

	update talt024
		set t24_mecanico = (select tecni
					from t1
					where numot = t24_orden)
		where t24_compania   = 1
		  and t24_localidad  = 1
		  and t24_orden     in (select numot from t1)
		  and t24_mecanico   = 1;

--rollback work;
commit work;

drop table t1;

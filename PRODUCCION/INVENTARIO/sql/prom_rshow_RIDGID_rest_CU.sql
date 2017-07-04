select r10_codigo as item,
	r10_cod_util as cod_uti,
	r10_precio_mb as pvp,
	r10_cantveh as cant_v
	from rept010
	where r10_compania = 999
	into temp t1;

load from "res_rshow_060814.unl" insert into t1;

begin work;

	update rept010
		set r10_cod_util    = (select cod_uti
					from t1
					where item = r10_codigo),
		    r10_usu_cosrepo = "HSALAZAR",
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in (select item from t1);

--rollback work;
commit work;

drop table t1;

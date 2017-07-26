select r10_codigo item
	from rept010
	where r10_compania = 999
	into temp t1;

load from "promo_myers.unl" insert into t1;

unload to "promo_myers_res.unl"
	select r10_codigo, r10_cod_util, r10_cantveh
		from rept010
		where r10_compania  = 1
		  and r10_codigo   in (select item from t1);

begin work;

	update rept010
		set r10_cod_util    = "PROM2",
		    r10_cantveh     = 1,
		    r10_usu_cosrepo = "HSALAZAR",
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in (select item from t1);

--rollback work;
commit work;

drop table t1;

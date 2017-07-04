select r10_compania cia, r10_codigo item, r10_costo_mb cos_act,
	r10_costo_mb cos_nue
	from rept010
	where r10_compania = 999
	into temp t1;

load from "cos_ite_uio_gye.unl" insert into t1;

begin work;

	update rept010
		set r10_costo_mb = (select cos_nue
					from t1
					where item = r10_codigo),
		    r10_usu_cosrepo = "E1EDWGUZ",
		    r10_fec_cosrepo = current
		where r10_compania = 1
		  and r10_codigo   in (select item from t1);

commit work;

drop table t1;

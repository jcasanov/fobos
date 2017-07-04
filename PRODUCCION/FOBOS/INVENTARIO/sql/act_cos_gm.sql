select r10_compania loc, r10_codigo item, r10_costo_mb cos_nue,
	r10_costo_mb cos_ant
	from rept010
	where r10_compania = 999
	into temp t1;
load from "item_cos.unl" insert into t1;
--begin work;
	update acero_gm:rept010
		set r10_costo_mb    = (select cos_nue
					from t1
					where item = r10_codigo
					  and loc  = 1),
		    r10_costult_mb  = (select cos_ant
					from t1
					where item = r10_codigo
					  and loc  = 1),
		    r10_usu_cosrepo = 'FOBOS',
		    r10_fec_cosrepo = current
		where r10_compania = 1
		  and r10_codigo   in (select item
					from t1
					where loc = 1);
--commit work;
drop table t1;

select r10_compania loc, r10_codigo item, r10_costo_mb costo 
	from rept010
	where r10_compania = 999
	into temp t1;

load from "aju_cos_12.unl" insert into t1;

unload to "ite_cos_12_qs.unl"
	select r10_codigo, r10_costo_mb, r10_costult_mb, r10_usu_cosrepo,
		r10_fec_cosrepo
		from rept010
		where r10_compania  = 1
		  and r10_codigo   in
			(select item
				from t1
				where loc = 4);

begin work;

	update rept010
		set r10_costult_mb = r10_costo_mb
		where r10_compania  = 1
		  and r10_codigo   in
			(select item
				from t1
				where loc = 4);

	update rept010
		set r10_costo_mb    = (select costo
					from t1
					where loc  = 4
					  and item = r10_codigo),
		    r10_usu_cosrepo = 'FOBOS',
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in
			(select item
				from t1
				where loc = 4);

--rollback work;
commit work;

drop table t1;

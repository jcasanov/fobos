select r10_compania loc, r10_codigo item
	from rept010
	where r10_compania = 999
	into temp t1;

load from "otras_marc.unl" insert into t1;

begin work;

	update acero_gm@acuiopr:rept010
		set r10_filtro = r10_marca
		where r10_compania  = 1
		  and r10_codigo   in
			(select item
				from t1
				where loc = 1);

	update acero_qm@acuiopr:rept010
		set r10_filtro = r10_marca
		where r10_compania  = 1
		  and r10_codigo   in
			(select item
				from t1
				where loc = 3);

commit work;

drop table t1;

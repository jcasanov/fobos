select r10_codigo item_s, r10_costo_mb cos_sur
	from acero_qs@acgyede:rept010
	where r10_compania = 1
	  and r10_estado   = 'A'
	into temp t1;
select r10_codigo item_q, r10_costo_mb cos_uio
	from acero_qm@acgyede:rept010
	where r10_compania = 1
	  and r10_estado   = 'A'
	into temp t2;
select t1.*, cos_uio
	from t1, t2
	where item_s  = item_q
	  and cos_sur = 0
	  and cos_uio > 0
	into temp t3;
drop table t1;
drop table t2;
select * from t3;
select count(*) tot_dif from t3;
drop table t3;

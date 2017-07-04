select r10_codigo item_s, r10_precio_mb pvp_sur
	from acero_qs@acgyede:rept010
	where r10_compania = 1
	  and r10_estado   = 'A'
	into temp t1;
select r10_codigo item_q, r10_precio_mb pvp_uio
	from acero_qm@acgyede:rept010
	where r10_compania = 1
	  and r10_estado   = 'A'
	into temp t2;
select t1.*, pvp_uio
	from t1, t2
	where item_s   = item_q
	  and pvp_sur <> pvp_uio
	into temp t3;
drop table t1;
drop table t2;
select * from t3;
select count(*) tot_dif from t3;
drop table t3;

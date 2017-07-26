set isolation to dirty read;
select r10_compania cia, r10_codigo item, r10_cantback cant_uio
	from rept010
	where r10_compania = 17
	into temp t1;
load from "r10_cantback_uio.unl" insert into t1;
select count(*) tot_t1 from t1;
select count(*) tot_r10 from rept010
	where exists (select cia, item from t1
			where cia  = r10_compania
			  and item = r10_codigo);
update rept010
	set r10_cantback = (select cant_uio from t1
				where cia  = r10_compania
				  and item = r10_codigo)
	where exists (select cia, item from t1
			where cia  = r10_compania
			  and item = r10_codigo);
drop table t1;

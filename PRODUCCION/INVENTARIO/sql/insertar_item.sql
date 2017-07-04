select a.r10_compania, a.r10_codigo
	from acero_gm@idsgye01:rept010 a
	--where a.r10_compania = 1
	--  and a.r10_estado   = "B"
	into temp t2;

select a.r10_compania, a.r10_codigo
	from acero_qm@idsuio01:rept010 a
	--where a.r10_compania = 1
	--  and a.r10_estado   = "B"
	into temp t1;

select a.* from t2 a
	where not exists
		(select 1 from t1 b
			where b.r10_compania = a.r10_compania
			  and b.r10_codigo   = a.r10_codigo)
	into temp t3;
drop table t1;
drop table t2;
select r10_codigo from t3;
drop table t3;

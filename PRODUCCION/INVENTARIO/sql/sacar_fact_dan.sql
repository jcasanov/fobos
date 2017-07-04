set isolation to dirty read;
select r19_localidad, r19_cod_tran, month(r19_fecing) mes,
	min(r19_num_tran) primera, max(r19_num_tran) ultima
	from rept019
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_cod_tran      = 'FA'
	  and r19_tipo_dev      is null
	  and year(r19_fecing)  = 2004
	  and month(r19_fecing) < month(today)
	group by 1, 2, 3
	into temp t1;
select r19_cod_tran, mes, primera, ultima, r38_num_sri
	from t1, rept038
	where r38_compania      = 1
	  and r38_localidad     = r19_localidad
	  and r38_cod_tran      = r19_cod_tran
	  and r38_num_tran      in (primera, ultima)
	into temp t2;
drop table t1;
select month(r19_fecing) mes_tot, count(*) hay
	from rept019
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_cod_tran      = 'FA'
	  and year(r19_fecing)  = 2004
	  and month(r19_fecing) < month(today)
	group by 1
	into temp t3;
select mes, r38_num_sri, hay
	from t2, t3
	where mes               = mes_tot
	order by 2, 3;
select r19_localidad mes, r19_codcli num_dan, r19_codcli total_fact
	from rept019
	where r19_compania      = 21
	into temp t1;
insert into t1
	select unique mes, r38_num_sri[9, 15], hay
	from t2, t3
	where mes               = mes_tot;
drop table t2;
drop table t3;
select mes, total_fact, num_dan
	from t1
	order by 1, 3;
drop table t1;

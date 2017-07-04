select r19_compania, r19_localidad, r19_cod_tran, r19_num_tran,
	r19_referencia, r19_ord_trabajo
	from rept019
        where r19_compania    = 1
	  and r19_localidad   = 1
	  and r19_cod_tran    = 'TR'
          and r19_ord_trabajo is not null
          and r19_referencia  like '%PRESUP%'
          and r19_fecing      < "2005-04-01 12:41:00"		-- para GYE
          --and r19_fecing      < "2005-04-01 13:40:00"		-- para UIO
	into temp t1;
select t1.*, t20_numpre, t20_user_aprob
	from t1, talt023, talt020
	where t23_compania  = r19_compania
	  and t23_localidad = r19_localidad
	  and t23_orden     = r19_ord_trabajo
	  and t20_compania  = t23_compania
	  and t20_localidad = t23_localidad
	  and t20_numpre    = t23_numpre
	into temp t2;
drop table t1;
select count(*) hay from t2;
select t2.*, r01_codigo
	from t2, rept001
	where r01_compania   = r19_compania
	  and r01_estado     = 'A'
	  and r01_user_owner = t20_user_aprob
	into temp t3;
drop table t2;
select count(*) total_reg from t3;
--select * from t3 order by r19_num_tran;
begin work;
update rept019
	set r19_vendedor = (select a.r01_codigo from t3 a
				where a.r19_compania  = rept019.r19_compania
				  and a.r19_localidad = rept019.r19_localidad
				  and a.r19_cod_tran  = rept019.r19_cod_tran
				  and a.r19_num_tran  = rept019.r19_num_tran)
	where exists (select b.r19_compania, b.r19_localidad, b.r19_cod_tran,
				b.r19_num_tran
			from t3 b
			where b.r19_compania    = rept019.r19_compania
			  and b.r19_localidad   = rept019.r19_localidad
			  and b.r19_cod_tran    = rept019.r19_cod_tran
			  and b.r19_num_tran    = rept019.r19_num_tran);
commit work;
drop table t3;

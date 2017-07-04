select r19_compania, r19_localidad, r19_cod_tran, r19_num_tran,
	r19_referencia, r19_ord_trabajo, r19_vendedor
	from rept019
        where r19_compania    = 1
	  and r19_localidad   = 1
	  and r19_cod_tran    = 'TR'
          and r19_ord_trabajo is not null
          and r19_referencia  like '%MATERIAL SOBRANTE%'
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
select count(*) total_reg_dist from t3 where r19_vendedor <> r01_codigo;
select * from t3 where r19_vendedor <> r01_codigo order by r19_num_tran;
drop table t3;

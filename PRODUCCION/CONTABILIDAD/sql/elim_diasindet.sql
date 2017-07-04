select r19_cod_tran, r19_num_tran, r19_tot_neto, r40_tipo_comp tipo_comp,
	r40_num_comp num_comp, extend(r19_fecing, year to month) fecha
	from rept019, rept040
	where r19_compania     = 1
	  and r19_localidad    in (1, 3)
	  and r19_cod_tran     = 'TR'
	  and date(r19_fecing) between mdy(01, 01, 2005)
				   and today
	  and r40_compania     = r19_compania
	  and r40_localidad    = r19_localidad
	  and r40_cod_tran     = r19_cod_tran
	  and r40_num_tran     = r19_num_tran
	into temp t1;
select t1.*, b13_valor_base
	from t1, outer ctbt013
	where b13_compania   = 1
	  and b13_tipo_comp  = tipo_comp
	  and b13_num_comp   = num_comp
	into temp t2;
drop table t1;
delete from t2 where b13_valor_base is not null and b13_valor_base <> 0;
select count(*) from t2;
begin work;
	delete from ctbt013
		where exists (select * from t2
				where tipo_comp = b13_tipo_comp
				  and num_comp  = b13_num_comp);
	delete from ctbt012
		where exists (select * from t2
				where tipo_comp = b12_tipo_comp
				  and num_comp  = b12_num_comp);
	delete from rept040
		where exists (select * from t2
				where tipo_comp = r40_tipo_comp
				  and num_comp  = r40_num_comp);
commit work;
drop table t2;

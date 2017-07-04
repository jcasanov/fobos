set isolation to dirty read;
select r19_cod_tran, r19_num_tran, r19_tot_neto, r40_tipo_comp, r40_num_comp,
	extend(r19_fecing, year to month) fecha
	from acero_gm:rept019, acero_gm:rept040
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     = 'TR'
	  and date(r19_fecing) between mdy(01, 01, 2005)
				   and today
	  and r40_compania     = r19_compania
	  and r40_localidad    = r19_localidad
	  and r40_cod_tran     = r19_cod_tran
	  and r40_num_tran     = r19_num_tran
	into temp t1;
select t1.*, (b13_valor_base * (-1)) b13_valor_base
	from t1, acero_gm:ctbt013
	where b13_compania   = 1
	  and b13_tipo_comp  = r40_tipo_comp
	  and b13_num_comp   = r40_num_comp
	  and b13_valor_base < 0
	into temp t2;
drop table t1;
select fecha, nvl(round(sum(r19_tot_neto), 2), 0) valor_inv,
	nvl(round(sum(b13_valor_base), 2), 0) valor_ctb
	from t2
	group by 1
	into temp t3;
drop table t2;
select * from t3 order by 1;
select round(sum(valor_inv), 2) tot_inv, round(sum(valor_ctb), 2) tot_ctb
	from t3;
select * from t3 where valor_inv <> valor_ctb order by 1;
drop table t3;

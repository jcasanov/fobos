set isolation to dirty read;

select b13_compania, b13_tipo_comp, b13_num_comp, b13_cuenta, b13_valor_base
	from ctbt012, ctbt013
	where b12_compania    = 1
	  and b12_estado      = 'M'
	  and b12_fec_proceso between mdy(10, 01, 2006) and mdy(10, 31, 2006)
	  and b13_compania    = b12_compania
	  and b13_tipo_comp   = b12_tipo_comp
	  and b13_num_comp    = b12_num_comp
	  and b13_cuenta      like '41%'
	into temp tmp_ctb;

select r40_compania, r19_localidad, r19_cod_tran, r19_num_tran, r19_tot_bruto,
	r19_tot_dscto, r40_tipo_comp, r40_num_comp
	from rept019, rept040
	where r19_compania                      = 1
	  and r19_localidad                     = 1
	  and r19_cod_tran                      in ('FA', 'DF', 'AF')
	  and extend(r19_fecing, year to month) = '2006-10'
	  and r40_compania                      = r19_compania
	  and r40_localidad                     = r19_localidad
	  and r40_cod_tran                      = r19_cod_tran
	  and r40_num_tran                      = r19_num_tran
union
select r40_compania, r19_localidad, r19_cod_tran, r19_num_tran, r19_tot_bruto,
	r19_tot_dscto, r40_tipo_comp, r40_num_comp
	from acero_gc:rept019, acero_gc:rept040
	where r19_compania                      = 1
	  and r19_localidad                     = 2
	  and r19_cod_tran                      in ('FA', 'DF', 'AF')
	  and extend(r19_fecing, year to month) = '2006-10'
	  and r40_compania                      = r19_compania
	  and r40_localidad                     = r19_localidad
	  and r40_cod_tran                      = r19_cod_tran
	  and r40_num_tran                      = r19_num_tran
	into temp tmp_inv;

select r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	case when r19_cod_tran = 'FA' then
		nvl(r19_tot_bruto - r19_tot_dscto, 0)
	else
		nvl(r19_tot_bruto - r19_tot_dscto, 0) * (-1)
	end valor_inv,
	case when r19_cod_tran = 'AF' then
		nvl(b13_valor_base, 0) * (-1)
	else
		nvl(b13_valor_base, 0)
	end valor_ctb, b13_tipo_comp tp, b13_num_comp num_c
	from tmp_ctb, outer tmp_inv
	where b13_compania   = r40_compania
	  and b13_tipo_comp  = r40_tipo_comp
	  and b13_num_comp   = r40_num_comp
	into temp t1;

drop table tmp_ctb;
drop table tmp_inv;

select loc, cod, num, round(valor_inv, 2) valor_inv,
	round(sum(valor_ctb), 2) valor_ctb, tp, num_c
	from t1
	group by 1, 2, 3, 4, 6, 7
	into temp t2;

drop table t1;

select count(*) total_t2 from t2;

select round(sum(valor_inv), 2) tot_inv, round(sum(valor_ctb), 2) tot_ctb
	from t2;

select * from t2 where abs(valor_inv) - abs(valor_ctb) <> 0 into temp t3;

drop table t2;

select count(*) tot_t3 from t3;
select * from t3 order by tp, num_c;

drop table t3;

set isolation to dirty read;
select r19_cod_tran, r19_num_tran, r19_tot_neto, r40_tipo_comp, r40_num_comp,
	extend(r19_fecing, year to month) fecha, r90_localidad, r90_cod_tran,
	r90_num_tran, r19_localidad
	from sermaco_gm@acgyede:rept019, sermaco_gm@acgyede:rept040,
		sermaco_gm@acgyede:rept090
	where r19_compania     = 2
	  and r19_localidad    = 6
	  and r19_cod_tran     = 'TR'
	  and year(r19_fecing) = 2006
	  and r40_compania     = r19_compania
	  and r40_localidad    = r19_localidad
	  and r40_cod_tran     = r19_cod_tran
	  and r40_num_tran     = r19_num_tran
	  and r90_compania     = r19_compania
	  and r90_locali_fin   = r19_localidad
	  and r90_codtra_fin   = r19_cod_tran
	  and r90_numtra_fin   = r19_num_tran
	union
	select r19_cod_tran, r19_num_tran, r19_tot_neto, r40_tipo_comp,
		r40_num_comp, extend(r19_fecing, year to month) fecha,
		r90_localidad, r90_cod_tran, r90_num_tran, r19_localidad
		from sermaco_qm@acgyede:rept019, sermaco_qm@acgyede:rept040,
			sermaco_qm@acgyede:rept090
		where r19_compania     = 2
		  and r19_localidad    = 7
		  and r19_cod_tran     = 'TR'
		  and year(r19_fecing) = 2006
		  and r40_compania     = r19_compania
		  and r40_localidad    = r19_localidad
		  and r40_cod_tran     = r19_cod_tran
		  and r40_num_tran     = r19_num_tran
		  and r90_compania     = r19_compania
		  and r90_locali_fin   = r19_localidad
		  and r90_codtra_fin   = r19_cod_tran
		  and r90_numtra_fin   = r19_num_tran
	into temp t1;
select t1.*, (b13_valor_base * (-1)) b13_valor_base
	from t1, sermaco_gm@acgyede:ctbt013
	where r19_localidad  = 6
	  and b13_compania   = 2
	  and b13_tipo_comp  = r40_tipo_comp
	  and b13_num_comp   = r40_num_comp
	  and b13_valor_base < 0
	union
	select t1.*, (b13_valor_base * (-1)) b13_valor_base
		from t1, sermaco_qm@acgyede:ctbt013
		where r19_localidad  = 7
		  and b13_compania   = 2
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
select r19_cod_tran tp1, r19_num_tran n1, r19_tot_neto val_inv,r40_tipo_comp dc,
	r40_num_comp nc, extend(r19_fecing, year to month) fecha,
	r90_localidad loc2, r90_cod_tran tp2, r90_num_tran n2,
	r19_localidad loc1
	from sermaco_gm@acgyede:rept019, sermaco_gm@acgyede:rept040,
		sermaco_gm@acgyede:rept090
	where r19_compania     = 2
	  and r19_localidad    = 6
	  and r19_cod_tran     = 'TR'
	  and year(r19_fecing) = 2006
	  and r40_compania     = r19_compania
	  and r40_localidad    = r19_localidad
	  and r40_cod_tran     = r19_cod_tran
	  and r40_num_tran     = r19_num_tran
	  and r90_compania     = r19_compania
	  and r90_locali_fin   = r19_localidad
	  and r90_codtra_fin   = r19_cod_tran
	  and r90_numtra_fin   = r19_num_tran
	into temp t1;
select t1.*, (b13_valor_base * (-1)) val_ctb
	from t1, sermaco_gm@acgyede:ctbt013
	where b13_compania   = 2
	  and b13_tipo_comp  = dc
	  and b13_num_comp   = nc
	  and b13_valor_base < 0
	into temp t2;
select r19_cod_tran tp1, r19_num_tran n1, r19_tot_neto val_inv,r40_tipo_comp dc,
	r40_num_comp nc, extend(r19_fecing, year to month) fecha,
	r90_localidad loc2, r90_cod_tran tp2, r90_num_tran n2,
	r19_localidad loc1
	from sermaco_qm@acgyede:rept019, sermaco_qm@acgyede:rept040,
		sermaco_qm@acgyede:rept090
	where r19_compania     = 2
	  and r19_localidad    = 7
	  and r19_cod_tran     = 'TR'
	  and year(r19_fecing) = 2006
	  and r40_compania     = r19_compania
	  and r40_localidad    = r19_localidad
	  and r40_cod_tran     = r19_cod_tran
	  and r40_num_tran     = r19_num_tran
	  and r90_compania     = r19_compania
	  and r90_locali_fin   = r19_localidad
	  and r90_codtra_fin   = r19_cod_tran
	  and r90_numtra_fin   = r19_num_tran
	into temp t3;
select t1.*, (b13_valor_base * (-1)) val_ctb
	from t1, sermaco_qm@acgyede:ctbt013
	where b13_compania   = 2
	  and b13_tipo_comp  = dc
	  and b13_num_comp   = nc
	  and b13_valor_base < 0
	into temp t4;
drop table t1;
drop table t3;
select t2.loc1 lg1, t2.n1 ng, t2.val_inv val_g, t2.loc2 lg2, t2.n2 ng2,
	t2.val_ctb val_cg1, t2.fecha fec_gye,
	t4.loc1 lq1, t4.n1 nq, t4.val_inv val_q, t4.loc2 lq2, t4.n2 nq2,
	t4.val_ctb val_cq1, t4.fecha fec_uio
 	from t2, t4
	where t2.loc2     = t4.loc1
	  and t2.tp2      = t4.tp1
	  and t2.n2       = t4.n1
	  and t2.val_ctb <> t4.val_ctb
	into temp t5;
drop table t2;
drop table t4;
select count(*) tot_tr from t5;
select * from t5 order by 2;
drop table t5;

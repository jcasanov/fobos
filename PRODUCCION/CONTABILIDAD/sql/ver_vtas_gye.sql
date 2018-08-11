select * from rept019
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     = 'FA'
	  and date(r19_fecing) between mdy(01, 01, 2006)
				       and mdy(11, 30, 2006)
	into temp t1;
select r90_localidad lc, r90_cod_tran tp, r90_num_tran num, r90_locali_fin lcf,
	r90_numtra_fin numf, date(r90_fecing_fin) fecfin, r40_tipo_comp tpc,
	r40_num_comp num_c
	from t1, rept040
	where r40_compania  = r90_compania
	  and r40_localidad = r90_locali_fin
	  and r40_cod_tran  = r90_codtra_fin
	  and r40_num_tran  = r90_numtra_fin
	into temp t2;
select t2.*, b13_valor_base valor_ctb
	from t2, ctbt013
	where b13_compania   = 1
	  and b13_tipo_comp  = tpc
	  and b13_num_comp   = num_c
	  --and b13_cuenta     = '11400101006'
	  and b13_valor_base > 0
	into temp tmp_tr_gye;
drop table t2;
select r90_localidad lc, r90_cod_tran tp, r90_num_tran num, r90_locali_fin lcf,
	r90_numtra_fin numf, date(r90_fecing_fin) fecfin, r40_tipo_comp tpc,
	r40_num_comp num_c
	from t1, outer acero_qm:rept040
	where r40_compania  = r90_compania
	  and r40_localidad = r90_localidad
	  and r40_cod_tran  = r90_cod_tran
	  and r40_num_tran  = r90_num_tran
	into temp t2;
drop table t1;
select t2.*, b13_valor_base valor_ctb
	from t2, acero_qm:ctbt013
	where b13_compania   = 1
	  and b13_tipo_comp  = tpc
	  and b13_num_comp   = num_c
	  --and b13_cuenta     = '11400101006'
	  and b13_valor_base < 0
	into temp tmp_tr_uio;
drop table t2;
select nvl(round(sum(valor_ctb), 2), 0) tot_gye from tmp_tr_gye;
select nvl(round(sum(b.valor_ctb), 2), 0) tot_uio
	from tmp_tr_uio b, outer tmp_tr_gye a
	where b.lc  = a.lc
	  and b.tp  = a.tp
	  and b.num = a.num;
drop table tmp_tr_gye;
drop table tmp_tr_uio;

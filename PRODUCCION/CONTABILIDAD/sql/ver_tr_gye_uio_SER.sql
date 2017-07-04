select * from sermaco_gm@segye01:rept090
	where r90_compania         = 2
	  and r90_localidad        = 7
	  and date(r90_fecing_fin) between mdy(01, 01, 2008)
				       and mdy(12, 31, 2008)
	into temp t1;
select count(*) tot_t1 from t1;
select r90_localidad lc, r90_cod_tran tp, r90_num_tran num, r90_locali_fin lcf,
	r90_numtra_fin numf, date(r90_fecing_fin) fecfin, r40_tipo_comp tpc,
	r40_num_comp num_c
	from t1, sermaco_gm@segye01:rept040
	where r40_compania  = r90_compania
	  and r40_localidad = r90_locali_fin
	  and r40_cod_tran  = r90_codtra_fin
	  and r40_num_tran  = r90_numtra_fin
	into temp t2;
select count(*) tot_t2 from t2;
select r90_locali_fin, r90_codtra_fin, r90_numtra_fin, lcf, tp, numf
	from t1, outer t2
	where lcf  = r90_locali_fin
	  and tp   = r90_codtra_fin
	  and numf = r90_numtra_fin
	into temp caca;
select count(*) tot_caca from caca;
delete from caca where numf is not null;
select count(*) tot_caca_del from caca;
select * from caca;
drop table caca;
select t2.*, b13_valor_base valor_ctb
	from t2, sermaco_gm@segye01:ctbt013
	where b13_compania   = 2
	  and b13_tipo_comp  = tpc
	  and b13_num_comp   = num_c
	  and b13_cuenta     = '11400101006'
	  and b13_valor_base > 0
	into temp tmp_tr_gye;
select count(*) tot_tr_gye from tmp_tr_gye;
drop table t2;
select r90_localidad lc, r90_cod_tran tp, r90_num_tran num, r90_locali_fin lcf,
	r90_numtra_fin numf, date(r90_fecing_fin) fecfin, r40_tipo_comp tpc,
	r40_num_comp num_c
	from t1, outer sermaco_qm@seuio01:rept040
	where r40_compania  = r90_compania
	  and r40_localidad = r90_localidad
	  and r40_cod_tran  = r90_cod_tran
	  and r40_num_tran  = r90_num_tran
	into temp t2;
drop table t1;
select t2.*, b13_valor_base valor_ctb
	from t2, sermaco_qm@seuio01:ctbt013
	where b13_compania   = 2
	  and b13_tipo_comp  = tpc
	  and b13_num_comp   = num_c
	  and b13_cuenta     = '11400101006'
	  and b13_valor_base < 0
	into temp tmp_tr_uio;
drop table t2;
select nvl(round(sum(valor_ctb), 2), 0) tot_gye from tmp_tr_gye;
select nvl(round(sum(b.valor_ctb), 2), 0) tot_uio
	--from tmp_tr_uio b, outer tmp_tr_gye a
	from tmp_tr_gye a, outer tmp_tr_uio b
	where b.lc  = a.lc
	  and b.tp  = a.tp
	  and b.num = a.num;
drop table tmp_tr_gye;
drop table tmp_tr_uio;

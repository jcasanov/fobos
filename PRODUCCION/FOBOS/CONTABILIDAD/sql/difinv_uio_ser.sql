select b13_compania cia, b13_tipo_comp tp, b13_num_comp num,
	(b13_valor_base * (-1)) val_ctb
	from sermaco_qm@acgyede:ctbt012,
		sermaco_qm@acgyede:ctbt013
	where b12_compania          = 2
	  and b12_tipo_comp         = 'DR'
	  and b12_estado            = 'M'
	  and b12_subtipo           = 25
	  and year(b12_fec_proceso) = 2007
	  and b13_compania          = b12_compania
	  and b13_tipo_comp         = b12_tipo_comp
	  and b13_num_comp          = b12_num_comp
	  and b13_cuenta            = '11400101006'
	into temp t1;
select r40_compania cia, r40_localidad loc, r40_cod_tran cod, r40_num_tran num,
	val_ctb
	from t1, sermaco_qm@acgyede:rept040
	where r40_compania  = cia
	  and r40_tipo_comp = tp
	  and r40_num_comp  = num
	into temp t2;
drop table t1;
select r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	round(r19_tot_neto, 2) val_r19, round(sum(r20_costo * r20_cant_ven),2)
	val_r20, round(val_ctb, 2) val_ctb,
	r90_localidad loc2, r90_cod_tran cod2, r90_num_tran num2,
	extend(r19_fecing, year to month) fecha
	from t2, sermaco_qm@acgyede:rept019,
		sermaco_qm@acgyede:rept020,
		sermaco_qm@acgyede:rept090
	where r19_compania   = cia
	  and r19_localidad  = loc
	  and r19_cod_tran   = cod
	  and r19_num_tran   = num
	  and r90_compania   = r19_compania
          and r90_locali_fin = r19_localidad
          and r90_codtra_fin = r19_cod_tran
          and r90_numtra_fin = r19_num_tran
	  and r20_compania   = r19_compania
	  and r20_localidad  = r19_localidad
	  and r20_cod_tran   = r19_cod_tran
	  and r20_num_tran   = r19_num_tran
	group by 1, 2, 3, 4, 6, 7, 8, 9, 10
	into temp tmp_uio;
drop table t2;
select count(*) tot_reg from tmp_uio;
select nvl(round(sum(val_r19), 2), 0) t3_val_r19,
	nvl(round(sum(val_r20), 2), 0) t3_val_r20,
	nvl(round(sum(val_ctb), 2), 0) t3_val_ctb
	from tmp_uio;
select * from tmp_uio where val_r19 <> val_ctb into temp t4;
select count(*) tot_reg_dif_uio from t4;
select nvl(round(sum(val_r19), 2), 0) tot_val_r19,
	nvl(round(sum(val_r20), 2), 0) tot_val_r20,
	nvl(round(sum(val_ctb), 2), 0) tot_val_ctb
	from t4;
select fecha, nvl(round(sum(val_r19), 2), 0) tot_val_r19,
	nvl(round(sum(val_r20), 2), 0) tot_val_r20,
	nvl(round(sum(val_ctb), 2), 0) tot_val_ctb
	from t4
	group by 1
	order by 1;
--select * from t4 order by 10, 3;
drop table t4;
---------------------------------
---------------------------------
select b13_compania cia, b13_tipo_comp tp, b13_num_comp num,
	b13_valor_base val_ctb
	from sermaco_gm@acgyede:ctbt012,
		sermaco_gm@acgyede:ctbt013
	where b12_compania          = 2
	  and b12_tipo_comp         = 'DR'
	  and b12_estado            = 'M'
	  and b12_subtipo           = 25
	  and year(b12_fec_proceso) = 2007
	  and b13_compania          = b12_compania
	  and b13_tipo_comp         = b12_tipo_comp
	  and b13_num_comp          = b12_num_comp
	  and b13_cuenta            = '11400101006'
	into temp t1;
select r40_compania cia, r40_localidad loc, r40_cod_tran cod, r40_num_tran num,
	val_ctb
	from t1, sermaco_gm@acgyede:rept040
	where r40_compania  = cia
	  and r40_tipo_comp = tp
	  and r40_num_comp  = num
	into temp t2;
drop table t1;
select r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	round(r19_tot_neto, 2) val_r19, round(sum(r20_costo * r20_cant_ven),2)
	val_r20, round(val_ctb, 2) val_ctb,
	extend(r19_fecing, year to month) fecha
	from t2, sermaco_gm@acgyede:rept019,
		sermaco_gm@acgyede:rept020
	where r19_compania   = cia
	  and r19_localidad  = loc
	  and r19_cod_tran   = cod
	  and r19_num_tran   = num
	  and r20_compania   = r19_compania
	  and r20_localidad  = r19_localidad
	  and r20_cod_tran   = r19_cod_tran
	  and r20_num_tran   = r19_num_tran
	group by 1, 2, 3, 4, 6, 7
	into temp tmp_gye;
drop table t2;
select a.*, b.val_ctb val_ctb_gye
	from tmp_uio a, tmp_gye b
	where a.loc2     = b.loc
	  and a.cod2     = b.cod
	  and a.num2     = b.num
	  and a.val_ctb <> b.val_ctb
	into temp t5;
drop table tmp_gye;
drop table tmp_uio;
select count(*) tot_dif_ctb from t5;
select * from t5 order by 10, 3;
drop table t5;

select r40_localidad loc, r40_cod_tran ct, r40_num_tran numt, r40_tipo_comp tp,
	r40_num_comp num, r40_num_tran sub_t
	from rept040
	where r40_compania = 99
	into temp t1;
load from "rept040_sur_v.unl" insert into t1;
select count(*) tot_t1 from t1;
select r40_localidad, r40_cod_tran, r40_num_tran, r40_tipo_comp, r40_num_comp
	from rept040, t1
	where r40_localidad = loc
	  and r40_cod_tran  = ct
	  and r40_num_tran  = numt
	into temp t2;
select count(*) tot_t2 from t2;
select t2.*, b12_subtipo st
	from t2, ctbt012
	where b12_compania  = 1
	  and b12_tipo_comp = r40_tipo_comp
	  and b12_num_comp  = r40_num_comp
	into temp t3;
select count(*) tot_t3 from t3;
drop table t2;
load from "rept040_sur_c.unl" insert into t1;
select t3.*, num
	from t3, t1
	where r40_cod_tran = ct
	  and r40_num_tran = numt
	  and st           = sub_t
	into temp t4;
drop table t3;
select count(*) tot_t4 from t4;
select b13_compania, b13_tipo_comp, num, b13_secuencia,	b13_cuenta,
	b13_tipo_doc, b13_glosa, b13_valor_base, b13_valor_aux,
	b13_num_concil, b13_filtro, b13_fec_proceso, b13_codcli, b13_codprov,
	b13_pedido
	from ctbt013, t4
	where b13_compania  = 1
	  and b13_tipo_comp = r40_tipo_comp
	  and b13_num_comp  = r40_num_comp
	into temp t5;
drop table t4;
unload to "ctbt013_fin.unl" select * from t5;
unload to "rept040_sur_f.unl" select * from t1;
drop table t1;
drop table t5;

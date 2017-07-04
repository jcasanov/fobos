set isolation to dirty read;
select rept040.*, r90_cod_tran tp2, 999999999.99 val_base
	from rept090, outer rept040
	where r90_compania  = 999
	  and r90_localidad = 999
	  and r40_compania  = r90_compania
	  and r40_localidad = r90_locali_fin
	  and r40_cod_tran  = r90_codtra_fin
	  and r40_num_tran  = r90_numtra_fin
	into temp t1;
--load from "r90_uio.unl" insert into t1;
load from "r90_gye.unl" insert into t1;
select nvl(sum(val_base), 0) tot_t1 from t1;
select count(*) tot_r90 from t1;
select rept040.*, r90_localidad loc, r90_cod_tran cod, r90_num_tran num_t
	from rept090, outer rept040
	where r90_compania     = 2
	  and r90_localidad    = 6
	  and year(r90_fecing) = 2007
	  and r90_locali_fin   = 7
	  and r40_compania     = r90_compania
	  and r40_localidad    = r90_locali_fin
	  and r40_cod_tran     = r90_codtra_fin
	  and r40_num_tran     = r90_numtra_fin
union all
select rept040.*, r90_localidad loc, r90_cod_tran cod, r90_num_tran num_t
	from rept090, outer rept040
	where r90_compania     = 2
	  and r90_localidad    = 7
	  and year(r90_fecing) = 2007
	  and r90_locali_fin   = 6
	  and r40_compania     = r90_compania
	  and r40_localidad    = r90_locali_fin
	  and r40_cod_tran     = r90_codtra_fin
	  and r40_num_tran     = r90_numtra_fin
	into temp t2;
select t1.*, t2.r40_tipo_comp tp_g, t2.r40_num_comp num_g
	from t1, t2
	where t2.loc   = t1.r40_localidad
	  and t2.cod   = t1.r40_cod_tran
	  and t2.num_t = t1.r40_num_tran
	into temp t3;
drop table t1;
drop table t2;
select ctbt012.*, b13_cuenta, b13_valor_base valor
	from ctbt012, ctbt013
	where b12_compania          = 2
	  and year(b12_fec_proceso) = 2007
	  and b13_compania          = b12_compania
	  and b13_tipo_comp         = b12_tipo_comp
	  and b13_num_comp          = b12_num_comp
	  and b13_valor_base        > 0
	into temp t2;
select b12_fec_proceso fecha, b12_tipo_comp tp, b12_num_comp num,
	b13_cuenta cta, valor, val_base
	from t3, outer t2
	where b12_compania   = r40_compania
	  and b12_tipo_comp  = tp_g
	  and b12_num_comp   = num_g
	  and valor         <> val_base
	into temp t4;
drop table t2;
drop table t3;
delete from t4 where tp is null;
select count(*) tot_t4 from t4;
select * from t4 order by 1, 3;
drop table t4;

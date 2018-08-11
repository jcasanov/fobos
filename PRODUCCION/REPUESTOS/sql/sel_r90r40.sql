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
	into temp t1;
select count(*) tot_r40 from t1;
select ctbt012.*, b13_cuenta, b13_valor_base
	from ctbt012, ctbt013
	where b12_compania          = 2
	  and year(b12_fec_proceso) = 2007
	  and b13_compania          = b12_compania
	  and b13_tipo_comp         = b12_tipo_comp
	  and b13_num_comp          = b12_num_comp
	into temp t2;
select b12_estado, b13_cuenta, count(*) tot_b12
	from t1, outer t2
	where b12_compania  = r40_compania
	  and b12_tipo_comp = r40_tipo_comp
	  and b12_num_comp  = r40_num_comp
	group by 1, 2;
select extend(b12_fec_proceso, year to month) fecha, b12_estado, b13_cuenta,
	count(*) tot_b12
	from t1, outer t2
	where b12_compania  = r40_compania
	  and b12_tipo_comp = r40_tipo_comp
	  and b12_num_comp  = r40_num_comp
	group by 1, 2, 3
	order by 1, 3;
drop table t1;

set isolation to dirty read;
select r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num
	from rept019
	where r19_compania    in (1, 2)
	  and r19_cod_tran    = 'TR'
	  and r19_bodega_dest in (select r02_codigo
					from rept002
					where r02_compania  = r19_compania
					  and r02_localidad not in(4, 5)) 
	  and year(r19_fecing) = 2007
	into temp t1;
select t1.*, r40_tipo_comp, r40_num_comp
	from t1, rept040
	where r40_compania  = cia
	  and r40_localidad = loc
	  and r40_cod_tran  = tp
	  and r40_num_tran  = num
	into temp t3;
drop table t1;
--unload to "r90_uio.unl"
unload to "r90_gye.unl"
select t3.*, b12_tipo_comp, abs(b13_valor_base)
	from t3, outer t2
	where b12_compania   = cia
	  and b12_tipo_comp  = r40_tipo_comp
	  and b12_num_comp   = r40_num_comp
	  and b13_valor_base < 0;
drop table t2;
drop table t3;

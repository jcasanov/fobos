select "GYE" loca, c10_tipo_orden, p20_compania, p20_localidad, p20_codprov,
	p20_tipo_doc, p20_num_doc, p20_dividendo, p01_num_doc, p01_nomprov,
	p20_valor_impto, p20_fecha_emi
	from acero_gm:cxpt020, acero_gm:cxpt001, acero_gm:ordt010,
		acero_gm:ordt001
	where p20_compania    = 1
	  and p20_localidad   = 1
	  and p20_tipo_doc    = 'FA'
	  and extend(p20_fecha_emi, year to month) = '2005-10'
	  and p01_codprov     = p20_codprov
	  and c10_compania    = p20_compania
	  and c10_localidad   = p20_localidad
	  and c10_numero_oc   = p20_numero_oc
	  and c10_estado      = 'C'
	  and c01_tipo_orden  = c10_tipo_orden
	  and c01_modulo     in('RE', 'AF', 'TA')
union
select "UIO" loca, c10_tipo_orden, p20_compania, p20_localidad, p20_codprov,
	p20_tipo_doc, p20_num_doc, p20_dividendo, p01_num_doc, p01_nomprov,
	p20_valor_impto, p20_fecha_emi
	from acero_qm:cxpt020, acero_qm:cxpt001, acero_qm:ordt010,
		acero_qm:ordt001
	where p20_compania    = 1
	  and p20_localidad   = 3
	  and p20_tipo_doc    = 'FA'
	  and extend(p20_fecha_emi, year to month) = '2005-10'
	  and p01_codprov     = p20_codprov
	  and c10_compania    = p20_compania
	  and c10_localidad   = p20_localidad
	  and c10_numero_oc   = p20_numero_oc
	  --and c10_tipo_orden in (1, 32, 40)
	  and c10_estado      = 'C'
	  and c01_tipo_orden  = c10_tipo_orden
	  and c01_modulo     in('RE', 'AF', 'TA')
	into temp t1;
select t1.loca, t1.c10_tipo_orden, p28_num_doc, p01_num_doc ruc, p01_nomprov
	nombre, to_char(p20_fecha_emi, "%d/%m/%Y") fecha_comp,
	to_char(p27_fecing, "%m/%Y") fecha_dec, p28_valor_base base_imp,
	p20_valor_impto	val_iva, p28_porcentaje porc, p28_valor_ret val_ret,
	to_char(p27_fecing, "%m/%Y") fecha_ret, p20_localidad loc
	from acero_gm:cxpt027, acero_gm:cxpt028, t1
	where p27_compania    = 1
	  and p27_localidad   = 1
	  and p27_estado      = 'A'
	  and extend(p27_fecing, year to month) = '2005-10'
	  and p28_compania    = p27_compania
	  and p28_localidad   = p27_localidad
	  and p28_num_ret     = p27_num_ret
	  and p28_tipo_ret    = 'F'
	  and p20_compania    = p28_compania
	  and p20_localidad   = p28_localidad
	  and p20_codprov     = p28_codprov
	  and p20_tipo_doc    = p28_tipo_doc
	  and p20_num_doc     = p28_num_doc
	  and p20_dividendo   = p28_dividendo
--	group by 1, 2, 3, 4, 5, 6,  9,  11, 12

union
select t1.loca, t1.c10_tipo_orden, p28_num_doc, p01_num_doc ruc, p01_nomprov
	nombre, to_char(p20_fecha_emi, "%d/%m/%Y") fecha_comp,
	to_char(p27_fecing, "%m/%Y") fecha_dec, p28_valor_base base_imp,
	p20_valor_impto	val_iva, p28_porcentaje porc, p28_valor_ret val_ret,
	to_char(p27_fecing, "%m/%Y") fecha_ret, p20_localidad loc
	from acero_qm:cxpt027, acero_qm:cxpt028, t1
	where p27_compania    = 1
	  and p27_localidad   = 3
	  and p27_estado      = 'A'
	  and extend(p27_fecing, year to month) = '2005-10'
	  and p28_compania    = p27_compania
	  and p28_localidad   = p27_localidad
	  and p28_num_ret     = p27_num_ret
	  and p28_tipo_ret    = 'F'
	  and p20_compania    = p28_compania
	  and p20_localidad   = p28_localidad
	  and p20_codprov     = p28_codprov
	  and p20_tipo_doc    = p28_tipo_doc
	  and p20_num_doc     = p28_num_doc
	  and p20_dividendo   = p28_dividendo
--	group by 1, 2, 3, 4, 5,6, 9, 11, 12
	into temp t2;
drop table t1;
unload to "oct.2005.unl" select * from t2;
select count(*) tot_reg from t2;
select loca, c10_tipo_orden, ruc, nombre, fecha_comp, fecha_dec,
	nvl(sum(base_imp), 0) base_imp,
	nvl(sum(val_iva), 0) val_iva, porc, nvl(sum(val_ret), 0) val_ret,
	fecha_ret
	from t2
	group by 1, 2, 3, 4, 5,6, 9,  11
	into temp t3;
drop table t2;
select count(*) tot_t3 from t3;
select * from t3 order by 1, 2;
--unload to "oct.2005.unl" select * from t3;
select count(*) tot_t3 from t3;
drop table t3;

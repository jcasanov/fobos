select z01_codcli, z01_num_doc_id, z21_saldo subtotal, z21_saldo tot_iva,
	z21_num_doc cuantos
	from cxct021, cxct001
	where z21_compania = 10
	  and z01_estado   = 'Z'
	into temp t1;
select z01_codcli, z01_num_doc_id, sum(z21_valor - z21_val_impto) subtotal,
	sum(z21_val_impto) tot_iva
	from cxct021, cxct001
	where z21_compania      = 1
	  and z21_localidad     = 1
	  and z21_tipo_doc      = 'NC'
	  and (z21_cod_tran     <> 'DF' or z21_origen = 'M')
	  and year(z21_fecing)  = 2003
	  and month(z21_fecing) = 1
	  and z01_codcli        = z21_codcli
	group by 1, 2
	into temp t2;
select z01_codcli, z01_num_doc_id, count(*) cuantos
	from cxct021, cxct001
	where z21_compania      = 1
	  and z21_localidad     = 1
	  and z21_tipo_doc      = 'NC'
	  and (z21_cod_tran     <> 'DF' or z21_origen = 'M')
	  and year(z21_fecing)  = 2003
	  and month(z21_fecing) = 1
	  and z01_codcli        = z21_codcli
	group by 1, 2
	into temp t3;
insert into t1
	select t2.z01_codcli, t2.z01_num_doc_id, subtotal, tot_iva, cuantos
		from t2, t3
		where t2.z01_codcli = t3.z01_codcli;
drop table t2;
drop table t3;
select z01_codcli, z01_num_doc_id, sum(z21_valor - z21_val_impto) subtotal,
	sum(z21_val_impto) tot_iva
	from acero_gc:cxct021, acero_gc:cxct001
	where z21_compania      = 1
	  and z21_localidad     = 2
	  and z21_tipo_doc      = 'NC'
	  and (z21_cod_tran     <> 'DF' or z21_origen = 'M')
	  and year(z21_fecing)  = 2003
	  and month(z21_fecing) = 1
	  and z01_codcli        = z21_codcli
	group by 1, 2
	into temp t2;
select z01_codcli, z01_num_doc_id, count(*) cuantos
	from acero_gc:cxct021, acero_gc:cxct001
	where z21_compania      = 1
	  and z21_localidad     = 2
	  and z21_tipo_doc      = 'NC'
	  and (z21_cod_tran     <> 'DF' or z21_origen = 'M')
	  and year(z21_fecing)  = 2003
	  and month(z21_fecing) = 1
	  and z01_codcli        = z21_codcli
	group by 1, 2
	into temp t3;
insert into t1
	select t2.z01_codcli, t2.z01_num_doc_id, subtotal, tot_iva, cuantos
		from t2, t3
		where t2.z01_codcli = t3.z01_codcli;
drop table t2;
drop table t3;
unload to "upnotcre.txt"
	select z01_codcli, z01_num_doc_id, sum(subtotal), sum(tot_iva),
		sum(cuantos)
		from t1
		group by 1, 2
		order by 1;
drop table t1;

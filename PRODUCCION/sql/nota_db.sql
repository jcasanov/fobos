select z01_codcli, z01_num_doc_id, z20_saldo_cap subtotal,
	z20_saldo_cap tot_iva, z20_cartera cuantos
	from cxct020, cxct001
	where z20_compania = 10
	  and z01_estado   = 'Z'
	into temp t1;
select z01_codcli, z01_num_doc_id, sum(z20_valor_cap + z20_valor_int) subtotal,
	sum(z20_val_impto) tot_iva
	from cxct020, cxct001
	where z20_compania      = 1
	  and z20_localidad     = 1
	  and z20_tipo_doc      = 'ND'
	  and year(z20_fecing)  = 2003
	  and month(z20_fecing) = 1
	  and z01_codcli        = z20_codcli
	group by 1, 2
	into temp t2;
select z01_codcli, z01_num_doc_id, count(*) cuantos
	from cxct020, cxct001
	where z20_compania      = 1
	  and z20_localidad     = 1
	  and z20_tipo_doc      = 'ND'
	  and year(z20_fecing)  = 2003
	  and month(z20_fecing) = 1
	  and z01_codcli        = z20_codcli
	group by 1, 2
	into temp t3;
insert into t1
	select t2.z01_codcli, t2.z01_num_doc_id, subtotal, tot_iva, cuantos
		from t2, t3
		where t2.z01_codcli = t3.z01_codcli;
drop table t2;
drop table t3;
unload to "upnotdeb.txt" select * from t1 order by 1;
drop table t1;

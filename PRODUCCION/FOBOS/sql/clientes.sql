select z01_codcli, z01_num_doc_id, z01_nomcli
	from rept019, cxct001
	where z01_estado = 'Z'
	into temp t1;
select z01_codcli, z01_num_doc_id, z01_nomcli
	from rept019, cxct001
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_cod_tran      = 'FA'
	  and year(r19_fecing)  = 2003
	  and month(r19_fecing) = 1
	  and z01_codcli        = r19_codcli
	into temp t2;
select z01_codcli, z01_num_doc_id, z01_nomcli
	from cxct021, cxct001
	where z21_compania      = 1
	  and z21_localidad     = 1
	  and z21_tipo_doc      = 'NC'
	  and year(z21_fecing)  = 2003
	  and month(z21_fecing) = 1
	  and z01_codcli        = z21_codcli
	into temp t3;
select z01_codcli, z01_num_doc_id, z01_nomcli
	from talt023, cxct001
	where t23_compania           = 1
	  and t23_localidad          = 1
	  and t23_num_factura is not null
	  and year(t23_fec_factura)  = 2003
	  and month(t23_fec_factura) = 1
	  and z01_codcli             = t23_cod_cliente
	into temp t4;
select z01_codcli, z01_num_doc_id, z01_nomcli
	from acero_gc:rept019, acero_gc:cxct001
	where r19_compania      = 1
	  and r19_localidad     = 2
	  and r19_cod_tran      = 'FA'
	  and year(r19_fecing)  = 2003
	  and month(r19_fecing) = 1
	  and z01_codcli        = r19_codcli
	into temp t5;
select z01_codcli, z01_num_doc_id, z01_nomcli
	from acero_gc:cxct021, acero_gc:cxct001
	where z21_compania      = 1
	  and z21_localidad     = 2
	  and z21_tipo_doc      = 'NC'
	  and year(z21_fecing)  = 2003
	  and month(z21_fecing) = 1
	  and z01_codcli        = z21_codcli
	into temp t6;
insert into t1
	select unique z01_codcli, z01_num_doc_id, z01_nomcli from t2;
insert into t1
	select unique z01_codcli, z01_num_doc_id, z01_nomcli from t3
		where z01_codcli not in (select unique z01_codcli from t2);
insert into t1
	select unique z01_codcli, z01_num_doc_id, z01_nomcli from t4
		where z01_codcli not in (select unique z01_codcli from t2);
insert into t1
	select unique z01_codcli, z01_num_doc_id, z01_nomcli from t5
		where z01_codcli not in (select unique z01_codcli from t2);
insert into t1
	select unique z01_codcli, z01_num_doc_id, z01_nomcli from t6
		where z01_codcli not in (select unique z01_codcli from t2);
drop table t2;
drop table t3;
drop table t4;
drop table t5;
drop table t6;
unload to "upcliente.txt" select * from t1 order by 3;
drop table t1;

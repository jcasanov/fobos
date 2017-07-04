select z01_codcli, z01_num_doc_id, r19_tot_neto subtotal,
	r19_tot_neto tot_iva, r19_oc_interna cuantos
	from rept019, cxct001
	where r19_compania = 10
	  and r19_codcli   = z01_codcli
	into temp t1;
select * from t1 into temp t5;
select unique z01_codcli, z01_num_doc_id, r19_cod_tran,
	sum(r19_tot_bruto) subtotal,
	sum(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto)) tot_iva
	from rept019, cxct001
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_cod_tran      in ('FA', 'DF', 'AF')
	  and year(r19_fecing)  = 2003
	  and month(r19_fecing) = 1
	  and z01_codcli        = r19_codcli
	group by 1, 2, 3
	into temp t2;
select unique z01_codcli, z01_num_doc_id, count(*) cuantos
	from rept019, cxct001
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_cod_tran      = 'FA'
	  and r19_tipo_dev     <> 'AF'
	  and year(r19_fecing)  = 2003
	  and month(r19_fecing) = 1
	  and z01_codcli        = r19_codcli
	group by 1, 2
	into temp t3;
update t2 set subtotal = subtotal * (-1),
	      tot_iva  = tot_iva  * (-1)
	where r19_cod_tran <> 'FA';
insert into t1
	select t2.z01_codcli, t2.z01_num_doc_id, sum(subtotal) subtot,
		sum(tot_iva) t_iva, cuantos
		from t2, outer t3
		where t2.z01_codcli = t3.z01_codcli
		group by 1, 2, 5;
drop table t2;
drop table t3;
select unique z01_codcli, z01_num_doc_id, sum(t23_tot_bruto) subtotal,
	sum(t23_val_impto) tot_iva
	from talt023, cxct001
	where t23_compania           = 1
	  and t23_localidad          = 1
	  and t23_estado             = 'F'
	  and t23_num_factura is not null
	  and year(t23_fec_factura)  = 2003
	  and month(t23_fec_factura) = 1
	  and z01_codcli             = t23_cod_cliente
	group by 1, 2
	into temp t2;
select unique z01_codcli, z01_num_doc_id, count(*) cuantos
	from talt023, cxct001
	where t23_compania           = 1
	  and t23_localidad          = 1
	  and t23_estado             = 'F'
	  and t23_num_factura is not null
	  and year(t23_fec_factura)  = 2003
	  and month(t23_fec_factura) = 1
	  and z01_codcli             = t23_cod_cliente
	group by 1, 2
	into temp t3;
insert into t5
	select t2.z01_codcli, t2.z01_num_doc_id, sum(subtotal) subtot,
		sum(tot_iva) t_iva, cuantos
		from t2, t3
		where t2.z01_codcli = t3.z01_codcli
		group by 1, 2, 5;
drop table t2;
drop table t3;
insert into t1
	select * from t5
		where t5.z01_codcli not in
			(select unique t1.z01_codcli from t1);
update t1 set t1.subtotal = t1.subtotal +
		(select t5.subtotal from t5
			where t5.z01_codcli = t1.z01_codcli)
	where t1.z01_codcli in (select unique t5.z01_codcli from t5);
update t1 set t1.tot_iva = t1.tot_iva +
		(select t5.tot_iva from t5
			where t5.z01_codcli = t1.z01_codcli)
	where t1.z01_codcli in (select unique t5.z01_codcli from t5);
update t1 set t1.cuantos = t1.cuantos +
		(select t5.cuantos from t5
			where t5.z01_codcli = t1.z01_codcli)
	where t1.z01_codcli in (select unique t5.z01_codcli from t5);
drop table t5;
select 0 z01_codcli, 'CLI. VARIOS' z01_num_doc_id, r19_cod_tran,
	sum(r19_tot_bruto) subtotal,
	sum(r19_tot_neto - (r19_tot_bruto - r19_tot_dscto)) tot_iva
	from rept019
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_cod_tran      in ('FA', 'DF', 'AF')
	  and year(r19_fecing)  = 2003
	  and month(r19_fecing) = 1
	  and r19_codcli is null
	group by 1, 2, 3
	into temp t2;
select 0 z01_codcli, 'CLI. VARIOS' z01_num_doc_id, count(*) cuantos
	from rept019
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_cod_tran      = 'FA'
	  --and r19_tipo_dev     <> 'AF'
	  and year(r19_fecing)  = 2003
	  and month(r19_fecing) = 1
	  and r19_codcli is null
	group by 1, 2
	into temp t3;
update t2 set subtotal = subtotal * (-1),
	      tot_iva  = tot_iva  * (-1)
	where r19_cod_tran <> 'FA';
insert into t1
	select t2.z01_codcli, t2.z01_num_doc_id, sum(subtotal) subtot,
		sum(tot_iva) t_iva, cuantos
		from t2, outer t3
		where t2.z01_codcli = t3.z01_codcli
		group by 1, 2, 5;
drop table t2;
drop table t3;
--unload to "upventas.txt" select * from t1 where subtotal <> 0 order by 1;
select * from t1 where subtotal <> 0 order by 1;
--select sum(subtotal) from t1 where subtotal <> 0 order by 1;
drop table t1;

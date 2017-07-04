select unique z22_codcli, z22_tipo_trn, z22_num_trn, z22_fecing,
	z23_tipo_favor, z23_doc_favor
	from cxct023, cxct022
	where z23_tipo_favor is not null
	  and z22_compania  = z23_compania
	  and z22_localidad = z23_localidad
	  and z22_codcli    = z23_codcli
	  and z22_tipo_trn  = z23_tipo_trn
	  and z22_num_trn   = z23_num_trn
	into temp t1;
select z22_codcli codcli, z22_tipo_trn tipo_trn, z22_num_trn num_trn,
	z22_fecing fecha, count(*) tot_doc
	from t1
	group by 1, 2, 3, 4
	having count(*) > 1
	into temp t2;
select t2.*, z23_tipo_favor, z23_doc_favor
	from t1, t2
	where z22_codcli    = codcli
	  and z22_tipo_trn  = tipo_trn
	  and z22_num_trn   = num_trn
	order by 5 desc;
drop table t1;
drop table t2;

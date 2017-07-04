select count(*) total_z23 from cxct023;
select z23_compania, z23_localidad, z23_codcli, z23_tipo_trn, z23_num_trn,
	date(z22_fecing) fecha
	from cxct022, cxct023
	where z22_compania     = 1
	  and date(z22_fecing) < today
	  and z23_compania     = z22_compania
	  and z23_localidad    = z22_localidad
	  and z23_codcli       = z22_codcli
	  and z23_tipo_trn     = z22_tipo_trn
	  and z23_num_trn      = z22_num_trn
	into temp t1;
select count(*) tot_doc_cob from t1 into temp t2;
select unique year(fecha) anio, month(fecha) mes, day(fecha) dia
	from t1
	into temp t3;
drop table t1;
select count(*) tot_dias from t3 into temp t4;
drop table t3;
select * from t2;
select round(tot_doc_cob / tot_dias, 0) prom_cob_dia from t2, t4;
drop table t2;
drop table t4;

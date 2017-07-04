begin work;
select * from acero_qs:cxct020
	where z20_cod_tran = 'FA'
	  and z20_num_tran in
		(select r19_num_tran
			from acero_qs:rept019
			where r19_compania  = z20_compania
			  and r19_localidad = z20_localidad
			  and r19_cod_tran  = "FA"
			  and r19_num_tran  = 87928)
	into temp t1;
update acero_qm:cxct020
	set z20_saldo_cap = 0
	where z20_compania  = 1
	  and z20_localidad = 4
	  and z20_codcli    = 229
	  and exists (select 1 from t1
			where t1.z20_compania  = z20_compania
			  and t1.z20_localidad = z20_localidad
			  and t1.z20_codcli    = z20_codcli
			  and t1.z20_tipo_doc  = z20_tipo_doc
			  and t1.z20_num_doc   = z20_num_doc
			  and t1.z20_dividendo = z20_dividendo);
select * from acero_qs:cxct023
	where exists
		(select 1 from t1
			where z23_compania  = z20_compania
			  and z23_localidad = z20_localidad
			  and z23_codcli    = z20_codcli
			  and z23_tipo_doc  = z20_tipo_doc
			  and z23_num_doc   = z20_num_doc
			  and z23_div_doc   = z20_dividendo)
	into temp t2;
drop table t1;
select * from acero_qs:cxct022
	where exists
		(select 1 from t2
			where z22_compania  = z23_compania
			  and z22_localidad = z23_localidad
			  and z22_codcli    = z23_codcli
			  and z22_tipo_trn  = z23_tipo_trn
			  and z22_num_trn   = z23_num_trn)
	into temp t1;
insert into acero_qm:cxct022 select * from t1;
insert into acero_qm:cxct023 select * from t2;
drop table t2;
commit work;

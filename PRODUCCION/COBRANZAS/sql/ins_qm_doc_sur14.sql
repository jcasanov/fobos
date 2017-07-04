begin work;
insert into acero_qm:cxct021
	select * from acero_qs@idsuio02:cxct021
		where z21_cod_tran = 'DF'
		  and z21_num_tran = 4118;
select * from acero_qs@idsuio02:cxct020
	where z20_cod_tran = 'FA'
	  and z20_num_tran in
		(select r19_num_tran
			from acero_qs@idsuio02:rept019
			where r19_compania  = z20_compania
			  and r19_localidad = z20_localidad
			  and r19_cod_tran  = "FA"
			  and r19_tipo_dev  = "DF"
			  and r19_num_dev   = 4118)
	into temp t1;
insert into acero_qm:cxct020 select * from t1;
select * from acero_qs@idsuio02:cxct023
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
select * from acero_qs@idsuio02:cxct022
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
--rollback work;
commit work;

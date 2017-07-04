select j12_compania, j12_localidad, j12_codcli, z20_tipo_doc, z20_num_doc,
	z20_dividendo, j12_banco, j12_num_cta, j12_num_cheque, j12_secuencia
	from cajt012, cxct020
	where z20_compania  = j12_compania
	  and z20_localidad = j12_localidad
	  and z20_codcli    = j12_codcli
	  and z20_tipo_doc  = 'ND'
	  and z20_num_doc   = j12_nd_interna
	  and z20_dividendo = 1
	into temp t1;
select count(*) tot_reg from t1;
select t1.*, z42_compania cia
	from t1, outer cxct042
	where z42_compania  = j12_compania
	  and z42_localidad = j12_localidad
	  and z42_codcli    = j12_codcli
	  and z42_tipo_doc  = z20_tipo_doc
	  and z42_num_doc   = z20_num_doc
	  and z42_dividendo = z20_dividendo
	into temp t2;
delete from t1 where 1 = 1;
select count(*) tot_reg_t2 from t2;
delete from t2 where cia is not null;
select count(*) tot_reg_ins from t2;
insert into t1
	select j12_compania, j12_localidad, j12_codcli, z20_tipo_doc,
		z20_num_doc, z20_dividendo, j12_banco, j12_num_cta,
		j12_num_cheque, j12_secuencia
		from t2;
drop table t2;
begin work;
	insert into cxct042 select * from t1;
commit work;
drop table t1;

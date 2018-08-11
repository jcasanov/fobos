select z20_compania, z20_localidad, z20_codcli, z20_tipo_doc, z20_num_doc,
	z20_dividendo, z20_saldo_cap, z20_saldo_int, z22_tipo_trn, z22_num_trn,
	z23_valor_cap, z23_valor_int, z23_saldo_cap, z23_saldo_int, z22_fecing
	from cxct020, cxct023, cxct022
	where z20_compania   = 1
	  and z20_localidad in (3, 4)
	  and z23_compania   = z20_compania
	  and z23_localidad  = z20_localidad
	  and z23_codcli     = z20_codcli
	  and z23_tipo_doc   = z20_tipo_doc
	  and z23_num_doc    = z20_num_doc
	  and z23_div_doc    = z20_dividendo
	  and z22_compania   = z23_compania
	  and z22_localidad  = z23_localidad
	  and z22_codcli     = z23_codcli
	  and z22_tipo_trn   = z23_tipo_trn
	  and z22_num_trn    = z23_num_trn
	  and z22_fecing    in (select max(a.z22_fecing)
				from cxct023 b, cxct022 a
				where b.z23_compania  = z20_compania
				  and b.z23_localidad = z20_localidad
				  and b.z23_codcli    = z20_codcli
				  and b.z23_tipo_doc  = z20_tipo_doc
				  and b.z23_num_doc   = z20_num_doc
				  and b.z23_div_doc   = z20_dividendo
				  and a.z22_compania  = b.z23_compania
				  and a.z22_localidad = b.z23_localidad
				  and a.z22_codcli    = b.z23_codcli
				  and a.z22_tipo_trn  = b.z23_tipo_trn
				  and a.z22_num_trn   = b.z23_num_trn)
	into temp t1;
select z20_codcli z23_codcli, nvl(sum(z23_saldo_cap + z23_saldo_int +
		z23_valor_cap +	z23_valor_int), 0) saldo_z23
	from t1
	group by 1
	into temp t2;
--
select z20_codcli, nvl(sum(z20_saldo_cap + z20_saldo_int), 0) saldo_z20
	from t1
	group by 1
	into temp t3;
--
{--
select z20_codcli, nvl(sum(z20_saldo_cap + z20_saldo_int), 0) saldo_z20
	from cxct020
	where z20_compania   = 1
	  and z20_localidad in (3, 4)
	group by 1
	into temp t3;
drop table t1;
--}
select count(z23_codcli) cli_z23 from t2;
select count(z20_codcli) cli_z20 from t3;
select z20_codcli, saldo_z20, saldo_z23
	from t2, t3
	where z20_codcli  = z23_codcli
	  and saldo_z20  <> saldo_z23
	into temp t4;
select z20_codcli, z23_codcli
	from t3, outer t2
	where z20_codcli = z23_codcli
	into temp t5;
delete from t5 where z23_codcli is not null;
drop table t2;
drop table t3;
select count(*) total_cli_descu from t4;
select * from t4 order by 1;
--
select z20_localidad, z20_codcli, z20_tipo_doc, z20_num_doc,
	z20_dividendo, z20_saldo_cap, z20_saldo_int, z22_tipo_trn, z22_num_trn,
	z23_valor_cap, z23_valor_int, z23_saldo_cap, z23_saldo_int, z22_fecing
	from t1
	where z20_codcli                    in (select t4.z20_codcli from t4)
	  and z20_saldo_cap + z20_saldo_int <>
		z23_saldo_cap + z23_saldo_int + z23_valor_cap +	z23_valor_int
	order by z22_fecing;
drop table t1;
--
drop table t4;
select unique z20_codcli
	from cxct020
	where z20_compania                   = 1
	  and z20_localidad                 in (3, 4)
	  and z20_codcli                    in (select t5.z20_codcli from t5)
	  and z20_saldo_cap + z20_saldo_int  > 0
	  and year(z20_fecing)               < 2003
	into temp t6;
drop table t5;
select count(*) cli_no_estan_z23 from t6;
select * from t6 order by 1;
drop table t6;

select z20_compania, z20_localidad, z20_codcli, z01_nomcli[1, 25] nomcli,
	z20_tipo_doc, z20_num_doc, z20_dividendo, z20_saldo_cap, z20_saldo_int,
	z20_fecha_emi, z20_fecha_vcto,
	nvl((select z23_valor_cap + z23_valor_int + z23_saldo_cap +
			z23_saldo_int
		from cxct023, cxct022
		where z23_compania  = z20_compania
		  and z23_localidad = z20_localidad
		  and z23_codcli    = z20_codcli
		  and z23_tipo_doc  = z20_tipo_doc
		  and z23_num_doc   = z20_num_doc
		  and z23_div_doc   = z20_dividendo
		  and z22_compania  = z23_compania
		  and z22_localidad = z23_localidad
		  and z22_codcli    = z23_codcli
		  and z22_tipo_trn  = z23_tipo_trn
		  and z22_num_trn   = z23_num_trn
		  and z22_fecing    = (select max(z22_fecing)
					from cxct023, cxct022
					where z23_compania  = z20_compania
					  and z23_localidad = z20_localidad
					  and z23_codcli    = z20_codcli
					  and z23_tipo_doc  = z20_tipo_doc
					  and z23_num_doc   = z20_num_doc
					  and z23_div_doc   = z20_dividendo
					  and z22_compania  = z23_compania
					  and z22_localidad = z23_localidad
					  and z22_codcli    = z23_codcli
					  and z22_tipo_trn  = z23_tipo_trn
					  and z22_num_trn   = z23_num_trn)),
		nvl(case when z20_fecha_emi <= mdy(12, 31, 2002)
						-- fecha migración COBRANZAS
			then z20_saldo_cap + z20_saldo_int
			else z20_valor_cap + z20_valor_int
		end, 0)) saldo_doc
	from cxct020, cxct001
	where z20_compania   = 1
	  and z20_moneda     = "DO"
	  and z20_fecha_emi <= today
	  and z01_codcli     = z20_codcli
	into temp temp_doc;
select b13_tipo_comp, b13_num_comp, b13_fec_proceso, b13_glosa, b13_codcli,
	b13_valor_base
	from ctbt012, ctbt013
	where b12_compania     = 1
	  and b12_estado      <> "E"
	  and b12_moneda       = "DO"
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_cuenta       = "11210101001"
	  and b13_fec_proceso <= TODAY
	  and b13_codcli      is not null
	into temp tmp_ctb;
select z21_codcli, nvl(sum(z21_saldo), 0) saldo_fav
	from cxct021
	where z21_codcli in (select unique z20_codcli from temp_doc)
	group by 1
	into temp t3;
select z20_codcli, nomcli, nvl(sum(saldo_doc), 0) valor_cxc
	from temp_doc
	group by 1, 2
	into temp t1;
update t1 set valor_cxc = valor_cxc + nvl((select nvl(saldo_fav, 0) from t3
					where z21_codcli = z20_codcli), 0)
	where 1 = 1;
drop table t3;
select b13_codcli, nvl(sum(b13_valor_base), 0) valor_ctb
	from tmp_ctb
	group by 1
	into temp t2;
select z20_codcli codcli, nomcli, valor_cxc, valor_ctb
	from t1, t2
	where z20_codcli  = b13_codcli
	  and valor_cxc  <> valor_ctb
	into temp t3;
select z20_codcli, nomcli, valor_cxc, b13_codcli
	from t1, outer t2
	where z20_codcli = b13_codcli
	into temp tmp_cli;
delete from tmp_cli where b13_codcli is not null or valor_cxc = 0;
select count(*) cli_cxc_no_ctb from tmp_cli;
select * from tmp_cli order by 3 desc;
drop table tmp_cli;
drop table t1;
drop table t2;
select unique z20_codcli cli_cxc from temp_doc group by 1 into temp t1;
select unique b13_codcli cli_ctb from tmp_ctb group by 1 into temp t2;
drop table temp_doc;
drop table tmp_ctb;
select count(*) tot_cli_cxc from t1;
select count(*) tot_cli_ctb from t2;
drop table t1;
drop table t2;
{--
select z23_tipo_trn, z23_num_trn, z40_tipo_doc, z40_num_doc, z23_codcli,
	nvl(sum(z23_valor_cap + z23_valor_int), 0) valor_trn
	from t3, cxct023, outer cxct040
	where z23_codcli    = codcli
	  and z40_compania  = z23_compania
	  and z40_localidad = z23_localidad
	  and z40_codcli    = z23_codcli
	  and z40_tipo_doc  = z23_tipo_trn
	  and z40_num_doc   = z23_num_trn
	group by 1, 2, 3, 4, 5
	into temp tmp_doc_ctb;
delete from tmp_doc_ctb where z40_tipo_doc is not null;
select z23_codcli, nvl(sum(valor_trn), 0) tot_trn_ctb
	from tmp_doc_ctb
	group by 1
	into temp t4;
drop table tmp_doc_ctb;
update t3 set valor_cxc = valor_cxc + (select tot_trn_ctb from t4
					where z23_codcli = codcli)
	where 1 = 1;
drop table t4;
--}
select count(*) tot_cli_des from t3;
select round(sum(valor_cxc), 2) tot_cxc from t3;
select round(sum(valor_ctb), 2) tot_ctb from t3;
select lpad(codcli, 4, 0) codcli, nomcli, valor_cxc, valor_ctb,
	round(case when valor_ctb >= 0
		then valor_cxc - valor_ctb
		else valor_cxc + valor_ctb
	end, 2) diferencia
	from t3
	order by 5 desc;
drop table t3;

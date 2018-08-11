select z20_localidad, z20_codcli, z20_tipo_doc, z20_num_doc, z20_dividendo,
	z20_saldo_cap, z20_saldo_int, z20_fecha_emi, z20_fecha_vcto,
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
					where z23_compania   = z20_compania
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
		  			  and z22_fecing    <= current)),
  			  --and z22_fecing    <= "2003-01-08 23:59:59")),
		case when z20_fecha_emi <=
				(select z60_fecha_carga
					from cxct060
					where z60_compania  = z20_compania
					  and z60_localidad = z20_localidad)
						-- fecha migración COBRANZAS
			then z20_saldo_cap + z20_saldo_int -
				nvl((select sum(z23_valor_cap + z23_valor_int)
					from cxct023
					where z23_compania  = z20_compania
					  and z23_localidad = z20_localidad
					  and z23_codcli    = z20_codcli
					  and z23_tipo_doc  = z20_tipo_doc
					  and z23_num_doc   = z20_num_doc
					  and z23_div_doc   = z20_dividendo), 0)
			else z20_valor_cap + z20_valor_int
		end) saldo_doc
	from cxct020
	where z20_compania  in (1, 2)
	  and z20_moneda     = "DO"
	  and z20_fecha_emi <= today
	into temp temp_doc;
select z20_codcli cli_trn, nvl(sum(saldo_doc), 0) valor_trn
	from temp_doc
	group by 1
	into temp t1;
select z20_localidad localidad, z20_codcli cli_doc, z20_tipo_doc tipo_doc,
	z20_num_doc num_doc, z20_dividendo dividendo, z20_fecha_emi fec_emi,
	z20_valor_cap + z20_valor_int valor_z20,
	nvl(sum(z20_saldo_cap + z20_saldo_int), 0) saldo_z20
	from cxct020
	where z20_compania  in (1, 2)
	  and z20_moneda     = "DO"
	  and z20_fecha_emi <= today
	group by 1, 2, 3, 4, 5, 6, 7
	into temp temp_z20;
select cli_doc, nvl(sum(saldo_z20), 0) valor_doc
	from temp_z20
	group by 1
	into temp t2;
{--
select lpad(z20_codcli, 5, 0) codcli, z20_tipo_doc tp,
	lpad(z20_num_doc, 5, 0) num, z20_fecha_emi fec_e,
	round(valor_z20, 2) valor_d, round(saldo_doc, 2) saldo_d
	from temp_doc, temp_z20
	where z20_codcli = 862
	  and localidad  = z20_localidad
	  and cli_doc    = z20_codcli
	  and tipo_doc   = z20_tipo_doc
	  and num_doc    = z20_num_doc
	  and dividendo  = z20_dividendo
	order by z20_fecha_emi desc, 6 desc;
--}
select count(cli_trn) tot_cli_trn from t1;
select count(cli_doc) tot_cli_doc from t2;
select cli_doc, round(valor_doc, 2) valor_z20, round(valor_trn, 2) valor_deu
	from t1, t2
	where cli_trn    = cli_doc
	  and valor_trn <> valor_doc
	into temp t3;
drop table t1;
drop table t2;
select count(*) tot_cli_des from t3;
select * from t3 order by 1 desc;
select nvl(round(sum(valor_deu), 2), 0) total_z23,
	nvl(round(sum(valor_z20), 2), 0) total_z20
	from t3;
drop table t3;
select unique lpad(cli_doc, 5, 0) codcli, tipo_doc, lpad(num_doc, 6, 0) num_doc,
	lpad(dividendo, 2, 0) div, round(saldo_doc, 2) sal_doc,
	round(saldo_z20, 2) sal_z20, fec_emi
	from temp_doc, temp_z20
	where localidad  = z20_localidad
	  and cli_doc    = z20_codcli
	  and tipo_doc   = z20_tipo_doc
	  and num_doc    = z20_num_doc
	  and dividendo  = z20_dividendo
	  and saldo_doc <> saldo_z20
	into temp t1;
select count(*) tot_doc_des from t1;
select tipo_doc, count(*) tot_tip_doc_des from t1 group by 1 order by 2 desc;
select * from t1 order by 7 desc, 1 desc, 2, 3;
drop table t1;
drop table temp_doc;
drop table temp_z20;

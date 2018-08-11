select z20_compania, z20_localidad, z20_codcli, z20_tipo_doc, z20_num_doc,
	z20_dividendo, z01_nomcli,
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
	from cxct020, cxct001
	where z20_compania  in (1, 2)
	  and z20_moneda     = "DO"
	  and z20_fecha_emi <= today
	  and z01_codcli     = z20_codcli
	into temp temp_doc;
select z20_codcli cli_deu, z01_nomcli nomcli, nvl(sum(saldo_doc), 0) saldo_deu
	from temp_doc
	group by 1, 2
	into temp tmp_deu;
drop table temp_doc;

select z21_localidad localidad, z21_codcli codcli, z21_tipo_doc tipo_doc,
	z21_num_doc num_doc,
	nvl(case when z21_fecha_emi > (select z60_fecha_carga
					from cxct060
					where z60_compania  = z21_compania
					  and z60_localidad = z21_localidad)
		then
		z21_valor +
		(select sum(z23_valor_cap + z23_valor_int)
		from cxct023, cxct022
		where z23_compania   = z21_compania
		  and z23_localidad  = z21_localidad
		  and z23_codcli     = z21_codcli
		  and z23_tipo_favor = z21_tipo_doc
		  and z23_doc_favor  = z21_num_doc
		  and z22_compania   = z23_compania
		  and z22_localidad  = z23_localidad
		  and z22_codcli     = z23_codcli
		  and z22_tipo_trn   = z23_tipo_trn
		  and z22_num_trn    = z23_num_trn
		  and z22_fecing     between extend(z21_fecha_emi,
								year to second)
					 and current)
		else
		nvl((select sum(z23_valor_cap + z23_valor_int)
			from cxct023
			where z23_compania   = z21_compania
			  and z23_localidad  = z21_localidad
			  and z23_codcli     = z21_codcli
			  and z23_tipo_favor = z21_tipo_doc
			  and z23_doc_favor  = z21_num_doc), 0) +
		z21_saldo -
		(select sum(z23_valor_cap + z23_valor_int)
		from cxct023, cxct022
		where z23_compania   = z21_compania
		  and z23_localidad  = z21_localidad
		  and z23_codcli     = z21_codcli
		  and z23_tipo_favor = z21_tipo_doc
		  and z23_doc_favor  = z21_num_doc
		  and z22_compania   = z23_compania
		  and z22_localidad  = z23_localidad
		  and z22_codcli     = z23_codcli
		  and z22_tipo_trn   = z23_tipo_trn
		  and z22_num_trn    = z23_num_trn
		  and z22_fecing     between extend(z21_fecha_emi,
								year to second)
					 and current)
		end,
		case when z21_fecha_emi <=
				(select z60_fecha_carga
					from cxct060
					where z60_compania  = z21_compania
					  and z60_localidad = z21_localidad)
						-- fecha migracion COBRANZAS
			then z21_saldo -
				nvl((select sum(z23_valor_cap + z23_valor_int)
					from cxct023
					where z23_compania   = z21_compania
					  and z23_localidad  = z21_localidad
					  and z23_codcli     = z21_codcli
					  and z23_tipo_favor = z21_tipo_doc
					  and z23_doc_favor  = z21_num_doc), 0)
			else z21_valor
		end) saldo_fav
	from cxct021
	where z21_compania  in (1, 2)
	  and z21_moneda     = "DO"
	  and z21_fecha_emi <= today
	into temp temp_doc;
select codcli cli_fav, nvl(sum(saldo_fav) * (-1), 0) saldo_fav
	from temp_doc
	group by 1
	into temp tmp_fav;
drop table temp_doc;

select cli_deu cli_cob, nomcli,
		nvl(nvl(saldo_deu, 0) + nvl(saldo_fav, 0), 0) saldo_cob
	from tmp_deu, outer tmp_fav
	where cli_deu = cli_fav
	into temp tmp_cob;
drop table tmp_deu;
drop table tmp_fav;
select count(*) tot_cli_cob from tmp_cob;

select unique z02_aux_clte_mb cuenta from cxct002 into temp tmp_cta;
insert into tmp_cta
	select unique b41_cxc_mb from ctbt041
		where b41_compania    in (1, 2)
		  and b41_modulo      in ('RE', 'TA')
		  and b41_grupo_linea = 'ACERO';
select b13_codcli cli_con, nvl(sum(b13_valor_base), 0) saldo_con
	from ctbt012, ctbt013
	where b12_compania  in (1, 2)
	  and b12_moneda    = 'DO'
	  and b12_estado    = 'M'
	  and b13_compania  = b12_compania
	  and b13_tipo_comp = b12_tipo_comp
	  and b13_num_comp  = b12_num_comp
	  and b13_cuenta    in (select unique cuenta from tmp_cta)
	group by 1
	into temp tmp_con;
drop table tmp_cta;
select count(*) tot_cli_con from tmp_con;

select lpad(cli_con, 5, 0) codcli, nvl(nomcli, "SIN CLIENTE") nomcli,
		round(nvl(saldo_con, 0), 2) saldo_con,
		round(nvl(saldo_cob, 0), 2) saldo_cob,
		case when nvl(saldo_cob, 0) >= 0 and
		          nvl(saldo_con, 0) >= 0 then
			round(nvl(saldo_con, 0) - nvl(saldo_cob, 0), 2)
		     else
			round(nvl(saldo_cob, 0) + nvl(saldo_con, 0), 2)
		end saldo
	from tmp_cob, tmp_con
	where cli_cob    = cli_con
	  and saldo_cob <> saldo_con
	into temp t1;
drop table tmp_cob;
drop table tmp_con;

select count(*) tot_cli_des from t1;
--unload to "cli_des_con_ctb.txt" select * from t1 order by 2;
select codcli, nomcli[1, 17], saldo_con, saldo_cob, saldo from t1 order by 2;
select nvl(round(sum(saldo_con), 2), 0) tot_sal_con,
	nvl(round(sum(saldo_cob), 2), 0) tot_sal_cob,
	round(nvl(sum(saldo_con), 0) + nvl(sum(saldo_cob), 0), 2) saldo_fin
	from t1;
drop table t1;

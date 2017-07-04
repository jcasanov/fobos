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
		case when z20_fecha_emi <= (select z60_fecha_carga
						from cxct060
						where z60_compania  =
								z20_compania
						  and z60_localidad =
								z20_localidad)
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
	into temp temp_deu;
select z20_codcli cli_deu, nvl(sum(saldo_doc), 0) valor_deu
	from temp_deu
	group by 1
	into temp t1;
select z21_localidad localidad, z21_codcli codcli, z21_tipo_doc tipo_doc,
	z21_num_doc num_doc, z21_fecha_emi fec_emi,
	nvl(case when z21_fecha_emi > (select z60_fecha_carga from cxct060
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
		case when z21_fecha_emi <= (select z60_fecha_carga
						from cxct060
						where z60_compania  =
								z21_compania
						  and z60_localidad =
								z21_localidad)
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
	into temp temp_fav;
select codcli cli_fav, nvl(sum(saldo_fav) * (-1), 0) valor_fav
	from temp_fav
	group by 1
	into temp t2;
drop table temp_deu;
drop table temp_fav;
select z20_codcli codcli, z01_nomcli cliente, z20_saldo_cap saldo_cart
	from cxct020, cxct001
	where z20_compania = 99
	  and z01_codcli   = z20_codcli
	into temp t3;
insert into t3
	select cli_deu, trim(z01_nomcli), valor_deu
	from t1, cxct001
	where z01_codcli = cli_deu;
insert into t3
	select cli_fav, trim(z01_nomcli), valor_fav
	from t2, cxct001
	where z01_codcli = cli_fav;
drop table t1;
drop table t2;
select codcli, cliente, nvl(sum(saldo_cart), 0) saldo_cart
	from t3
	group by 1, 2
	into temp t4;
drop table t3;
delete from t4 where saldo_cart = 0;
select count(*) total_cli from t4;
select nvl(round(sum(saldo_cart), 2), 0) total_cart from t4;
select codcli, cliente[1, 40] cliente, saldo_cart from t4 order by 2;
--unload to "cliente_cart.unl" select * from t4 order by 2;
drop table t4;

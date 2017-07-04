select z21_localidad localidad, z21_codcli codcli, z21_tipo_doc tipo_doc,
	z21_num_doc num_doc, z21_fecha_emi fec_emi,
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
					--and "2004-05-31 23:59:59")
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
					--and "2004-05-31 23:59:59")
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
	into temp temp_fav;
select codcli, nvl(sum(saldo_fav), 0) tot_sal_fav
	from temp_fav
	group by 1
	into temp t1;
select z21_localidad, z21_codcli, z21_tipo_doc, z21_num_doc, z21_fecha_emi,
	z21_valor valor_z21, nvl(sum(z21_saldo), 0) saldo_z21
	from cxct021
	where z21_compania  in (1, 2)
	  and z21_moneda     = "DO"
	  and z21_fecha_emi <= today
	group by 1, 2, 3, 4, 5, 6
	into temp temp_z21;
select z21_codcli, nvl(sum(saldo_z21), 0) tot_sal_z21
	from temp_z21
	group by 1
	into temp t2;
{--
select lpad(z21_codcli, 5, 0) codcli, z21_tipo_doc tp,
	lpad(z21_num_doc, 5, 0) num, z21_fecha_emi fec_e,
	round(valor_z21, 2) valor_f, round(saldo_fav, 2) saldo_f
	from temp_fav, temp_z21
	where z21_codcli = 3850
	  and localidad  = z21_localidad
	  and codcli     = z21_codcli
	  and tipo_doc   = z21_tipo_doc
	  and num_doc    = z21_num_doc
	order by z21_fecha_emi desc, 6 desc;
--}
select count(*) tot_fav from temp_fav;
select count(*) tot_z21 from temp_z21;
select codcli, round(tot_sal_fav, 2) tot_sal_fav,
	round(tot_sal_z21, 2) tot_sal_z21
	from t1, t2
	where codcli       = z21_codcli
	  and tot_sal_fav <> tot_sal_z21
	into temp t3;
drop table t1;
drop table t2;
select count(*) tot_cli_des from t3;
select * from t3 order by 1 desc;
select nvl(round(sum(tot_sal_fav), 2), 0) total_z23,
	nvl(round(sum(tot_sal_z21), 2), 0) total_z21
	from t3;
drop table t3;
select unique lpad(codcli, 5, 0) codcli, tipo_doc, lpad(num_doc, 5, 0) num_doc,
	round(saldo_fav, 2) sal_fav, round(saldo_z21, 2) sal_z21, fec_emi
	from temp_fav, temp_z21
	where localidad  = z21_localidad
	  and codcli     = z21_codcli
	  and tipo_doc   = z21_tipo_doc
	  and num_doc    = z21_num_doc
	  and saldo_fav <> saldo_z21
	into temp t1;
select count(*) tot_doc_des from t1;
select tipo_doc, count(*) tot_tip_doc_des from t1 group by 1 order by 2 desc;
select * from t1 order by 6 desc, 1 desc, 2, 3;
drop table t1;
drop table temp_fav;
drop table temp_z21;

select p20_localidad, p20_codprov, p20_tipo_doc, p20_num_doc, p20_dividendo,
	p20_saldo_cap, p20_saldo_int, p20_fecha_emi, p20_fecha_vcto,
	nvl((select p23_valor_cap + p23_valor_int + p23_saldo_cap +
			p23_saldo_int
		from cxpt023, cxpt022
		where p23_compania  = p20_compania
		  and p23_localidad = p20_localidad
		  and p23_codprov   = p20_codprov
		  and p23_tipo_doc  = p20_tipo_doc
		  and p23_num_doc   = p20_num_doc
		  and p23_div_doc   = p20_dividendo
		  and p23_orden     = (select max(p23_orden)
					from cxpt023, cxpt022
					where p23_compania   = p20_compania
					  and p23_localidad  = p20_localidad
					  and p23_codprov    = p20_codprov
					  and p23_tipo_doc   = p20_tipo_doc
					  and p23_num_doc    = p20_num_doc
					  and p23_div_doc    = p20_dividendo
					  and p22_compania   = p23_compania
					  and p22_localidad  = p23_localidad
					  and p22_codprov    = p23_codprov
					  and p22_tipo_trn   = p23_tipo_trn
					  and p22_num_trn    = p23_num_trn
					  and p22_fecing     =
					(select max(p22_fecing)
					from cxpt023, cxpt022
					where p23_compania   = p20_compania
					  and p23_localidad  = p20_localidad
					  and p23_codprov    = p20_codprov
					  and p23_tipo_doc   = p20_tipo_doc
					  and p23_num_doc    = p20_num_doc
					  and p23_div_doc    = p20_dividendo
					  and p22_compania   = p23_compania
					  and p22_localidad  = p23_localidad
					  and p22_codprov    = p23_codprov
					  and p22_tipo_trn   = p23_tipo_trn
					  and p22_num_trn    = p23_num_trn
					  and p22_fecing    <= current))
						--"2005-12-31 23:59:59"))
		  and p22_compania  = p23_compania
		  and p22_localidad = p23_localidad
		  and p22_codprov   = p23_codprov
		  and p22_tipo_trn  = p23_tipo_trn
		  and p22_num_trn   = p23_num_trn
		  and p22_fecing    = (select max(p22_fecing)
					from cxpt023, cxpt022
					where p23_compania   = p20_compania
					  and p23_localidad  = p20_localidad
					  and p23_codprov    = p20_codprov
					  and p23_tipo_doc   = p20_tipo_doc
					  and p23_num_doc    = p20_num_doc
					  and p23_div_doc    = p20_dividendo
					  and p22_compania   = p23_compania
					  and p22_localidad  = p23_localidad
					  and p22_codprov    = p23_codprov
					  and p22_tipo_trn   = p23_tipo_trn
					  and p22_num_trn    = p23_num_trn
					  and p22_fecing    <= current)),
						--"2005-12-31 23:59:59")),
		case when p20_fecha_emi <=
				(select z60_fecha_carga
					from cxct060
					where z60_compania  = p20_compania
					  and z60_localidad = p20_localidad)
						-- fecha migración TESORERIA
			then p20_saldo_cap + p20_saldo_int -
				nvl((select sum(p23_valor_cap + p23_valor_int)
					from cxpt023
					where p23_compania  = p20_compania
					  and p23_localidad = p20_localidad
					  and p23_codprov   = p20_codprov
					  and p23_tipo_doc  = p20_tipo_doc
					  and p23_num_doc   = p20_num_doc
					  and p23_div_doc   = p20_dividendo), 0)
			else p20_valor_cap + p20_valor_int
		end) saldo_doc
	from cxpt020
	where p20_compania  in (1, 2)
	  and p20_moneda     = "DO"
	  and p20_fecha_emi <= today
	into temp temp_deu;
select p20_codprov prov_deu, nvl(sum(saldo_doc), 0) valor_deu
	from temp_deu
	group by 1
	into temp t1;
drop table temp_deu;
select p20_codprov codprov, p01_nomprov proveedor, p20_saldo_cap saldo_deu
	from cxpt020, cxpt001
	where p20_compania = 99
	  and p01_codprov  = p20_codprov
	into temp t2;
insert into t2
	select prov_deu, trim(p01_nomprov), valor_deu
	from t1, cxpt001
	where p01_codprov = prov_deu;
drop table t1;
select codprov, proveedor, nvl(sum(saldo_deu), 0) saldo_deu
	from t2
	group by 1, 2
	into temp t3;
drop table t2;
delete from t3 where saldo_deu = 0;
select count(*) total_prov from t3;
select nvl(round(sum(saldo_deu), 2), 0) total_deu from t3;
select codprov, proveedor[1, 40] proveedor, saldo_deu from t3 order by 2;
drop table t3;

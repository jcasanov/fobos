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
select z20_codcli cli_trn, z01_nomcli cliente, year(z20_fecha_emi) anio,
	case when month(z20_fecha_emi) = 01 then "ENERO"
	     when month(z20_fecha_emi) = 02 then "FEBRERO"
	     when month(z20_fecha_emi) = 03 then "MARZO"
	     when month(z20_fecha_emi) = 04 then "ABRIL"
	     when month(z20_fecha_emi) = 05 then "MAYO"
	     when month(z20_fecha_emi) = 06 then "JUNIO"
	     when month(z20_fecha_emi) = 07 then "JULIO"
	     when month(z20_fecha_emi) = 08 then "AGOSTO"
	     when month(z20_fecha_emi) = 09 then "SEPTIEMBRE"
	     when month(z20_fecha_emi) = 10 then "OCTUBRE"
	     when month(z20_fecha_emi) = 11 then "NOVIEMBRE"
	     when month(z20_fecha_emi) = 12 then "DICIEMBRE"
	end meses, "01_VENCIDOS" tipo,
	nvl(sum(saldo_doc), 0) valor_trn
	from temp_doc, cxct001
	where z20_codcli       = z01_codcli
	  and z20_fecha_vcto   < mdy(02, 29, 2008)
	group by 1, 2, 3, 4, 5
	having sum(saldo_doc) <> 0
	into temp t1;
select z20_codcli cli_trn, z01_nomcli cliente, year(z20_fecha_emi) anio,
	case when month(z20_fecha_emi) = 01 then "ENERO"
	     when month(z20_fecha_emi) = 02 then "FEBRERO"
	     when month(z20_fecha_emi) = 03 then "MARZO"
	     when month(z20_fecha_emi) = 04 then "ABRIL"
	     when month(z20_fecha_emi) = 05 then "MAYO"
	     when month(z20_fecha_emi) = 06 then "JUNIO"
	     when month(z20_fecha_emi) = 07 then "JULIO"
	     when month(z20_fecha_emi) = 08 then "AGOSTO"
	     when month(z20_fecha_emi) = 09 then "SEPTIEMBRE"
	     when month(z20_fecha_emi) = 10 then "OCTUBRE"
	     when month(z20_fecha_emi) = 11 then "NOVIEMBRE"
	     when month(z20_fecha_emi) = 12 then "DICIEMBRE"
	end meses, "02_POR_VENCER" tipo,
	nvl(sum(saldo_doc), 0) valor_trn
	from temp_doc, cxct001
	where z20_codcli       = z01_codcli
	  and z20_fecha_vcto  >= mdy(02, 29, 2008)
	group by 1, 2, 3, 4, 5
	having sum(saldo_doc) <> 0
	into temp t2;
select z22_codcli cli_trn, z01_nomcli cliente, year(z22_fecing) anio,
	case when month(z22_fecing) = 01 then "ENERO"
	     when month(z22_fecing) = 02 then "FEBRERO"
	     when month(z22_fecing) = 03 then "MARZO"
	     when month(z22_fecing) = 04 then "ABRIL"
	     when month(z22_fecing) = 05 then "MAYO"
	     when month(z22_fecing) = 06 then "JUNIO"
	     when month(z22_fecing) = 07 then "JULIO"
	     when month(z22_fecing) = 08 then "AGOSTO"
	     when month(z22_fecing) = 09 then "SEPTIEMBRE"
	     when month(z22_fecing) = 10 then "OCTUBRE"
	     when month(z22_fecing) = 11 then "NOVIEMBRE"
	     when month(z22_fecing) = 12 then "DICIEMBRE"
	end meses, "03_COBRADO" tipo,
	nvl(sum(z23_valor_cap + z23_valor_int), 0) * (-1) valor_mov
	from cxct022, cxct023, cxct001
	where z22_compania     in (1, 2)
	  and date(z22_fecing) <= mdy(02, 29, 2008)
	  and z22_codcli        = z01_codcli
	  and z22_compania      = z23_compania
	  and z22_localidad     = z23_localidad
	  and z22_codcli        = z23_codcli
	  and z22_tipo_trn      = z23_tipo_trn
	  and z22_num_trn       = z23_num_trn
	group by 1, 2, 3, 4, 5
	having sum(z23_valor_cap + z23_valor_int) <> 0
	into temp t3;
drop table temp_doc;
select count(*) tot_t1 from t1;
select count(*) tot_t2 from t2;
select count(*) tot_t3 from t3;
select cli_trn, cliente, anio, meses, tipo, valor_trn from t1
	union
	select cli_trn, cliente, anio, meses, tipo, valor_trn from t2
	union
	select cli_trn, cliente, anio, meses, tipo, valor_mov from t3
	into temp t4;
drop table t1;
drop table t2;
drop table t3;
unload to "cartera_serfeb08.unl" select * from t4 order by cliente;
select count(*) tot_t4 from t4;
{--
select codcli, nomcli, count(*) tot_t4
	from t4
	group by 1, 2
	having count(*) > 1;
--}
drop table t4;

select case when z20_localidad = 1 then "GYE J T M"
	    when z20_localidad = 2 then "GYE CENTRO"
	    when z20_localidad = 3 then "UIO MATRIZ"
	    when z20_localidad = 4 then "UIO SUR"
	    when z20_localidad = 5 then "UIO KHOLER"
	end localidad,
	z20_codcli codcli, z01_nomcli cliente, z20_tipo_doc tipo_doc,
	z20_num_doc numero_doc, z20_dividendo dividendo,
	z20_saldo_cap saldo_cap, z20_saldo_int saldo_int,
	z20_fecha_emi fecha_emision, z20_fecha_vcto fecha_vencimiento,
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
	from cxct020, cxct001
	where z20_compania   = 1
	  and z20_moneda     = "DO"
	  and z20_fecha_emi <= today
	  and z01_codcli     = z20_codcli
union
select case when z20_localidad = 1 then "GYE J T M"
	    when z20_localidad = 2 then "GYE CENTRO"
	    when z20_localidad = 3 then "UIO MATRIZ"
	    when z20_localidad = 4 then "UIO SUR"
	    when z20_localidad = 5 then "UIO KHOLER"
	end localidad,
	z20_codcli codcli, z01_nomcli cliente, z20_tipo_doc tipo_doc,
	z20_num_doc numero_doc, z20_dividendo dividendo,
	z20_saldo_cap saldo_cap, z20_saldo_int saldo_int,
	z20_fecha_emi fecha_emision, z20_fecha_vcto fecha_vencimiento,
	nvl((select z23_valor_cap + z23_valor_int + z23_saldo_cap +
			z23_saldo_int
		from acero_gc:cxct023, acero_gc:cxct022
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
					from acero_gc:cxct023, acero_gc:cxct022
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
					from acero_gc:cxct060
					where z60_compania  = z20_compania
					  and z60_localidad = z20_localidad)
						-- fecha migración COBRANZAS
			then z20_saldo_cap + z20_saldo_int -
				nvl((select sum(z23_valor_cap + z23_valor_int)
					from acero_gc:cxct023
					where z23_compania  = z20_compania
					  and z23_localidad = z20_localidad
					  and z23_codcli    = z20_codcli
					  and z23_tipo_doc  = z20_tipo_doc
					  and z23_num_doc   = z20_num_doc
					  and z23_div_doc   = z20_dividendo), 0)
			else z20_valor_cap + z20_valor_int
		end) saldo_doc
	from acero_gc:cxct020, acero_gc:cxct001
	where z20_compania   = 1
	  and z20_moneda     = "DO"
	  and z20_fecha_emi <= today
	  and z01_codcli     = z20_codcli;

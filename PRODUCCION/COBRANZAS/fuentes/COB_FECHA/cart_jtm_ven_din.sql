select case when z20_localidad = 1 then "GYE J T M"
	    when z20_localidad = 2 then "GYE CENTRO"
	    when z20_localidad = 3 then "UIO MATRIZ"
	    when z20_localidad = 4 then "UIO SUR"
	    when z20_localidad = 5 then "UIO KHOLER"
	end localidad,
	z20_codcli codcli, z01_nomcli cliente,
	nvl(case when z20_areaneg = 1 then
		(select unique r01_nombres
			from rept019, rept001
			where r19_compania  = z20_compania
			  and r19_localidad = z20_localidad
			  and r19_cod_tran  = z20_cod_tran
			  and r19_num_tran  = z20_num_tran
			  and r01_compania  = r19_compania
			  and r01_codigo    = r19_vendedor)
		 when z20_areaneg = 2 then
		(select unique r01_nombres
			from talt023, talt061, rept001
			where t23_compania    = z20_compania
			  and t23_localidad   = z20_localidad
			  and t23_num_factura = z20_num_tran
			  and t61_compania    = t23_compania
                	  and t61_cod_asesor  = t23_cod_asesor
			  and r01_compania    = t61_compania
			  and r01_codigo      = t61_cod_vendedor)
		end, "SIN VENDEDOR") vendedor,
	z20_tipo_doc tipo_doc, z20_num_doc numero_doc, z20_dividendo dividendo,
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
	where z20_compania                   = 1
	  and z20_moneda                     = "DO"
	  and z20_fecha_emi                 <= today
	  and z20_saldo_cap + z20_saldo_int  > 0
	  and z01_codcli                     = z20_codcli;

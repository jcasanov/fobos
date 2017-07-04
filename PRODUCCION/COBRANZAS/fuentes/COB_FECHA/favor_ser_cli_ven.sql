select case when z21_localidad = 1 then "GYE J T M"
	    when z21_localidad = 2 then "GYE CENTRO"
	    when z21_localidad = 3 then "UIO MATRIZ"
	    when z21_localidad = 4 then "UIO SUR"
	    when z21_localidad = 5 then "UIO KHOLER"
	    when z21_localidad = 6 then "SERMACO GYE"
	    when z21_localidad = 7 then "SERMACO UIO"
	end localidad,
	case when z21_areaneg = 1 then "INVENTARIO"
	     when z21_areaneg = 2 then "TALLER"
	end area_neg,
	z21_codcli codcli, z01_nomcli cliente,
	nvl(case when z21_areaneg = 1 then
		(select unique r01_nombres
			from rept019, rept001
			where r19_compania  = z21_compania
			  and r19_localidad = z21_localidad
			  and r19_cod_tran  = z21_cod_tran
			  and r19_num_tran  = z21_num_tran
			  and r01_compania  = r19_compania
			  and r01_codigo    = r19_vendedor)
		 when z21_areaneg = 2 then
		(select unique r01_nombres
			from talt023, talt061, rept001
			where t23_compania    = z21_compania
			  and t23_localidad   = z21_localidad
			  and t23_num_factura = z21_num_tran
			  and t61_compania    = t23_compania
                	  and t61_cod_asesor  = t23_cod_asesor
			  and r01_compania    = t61_compania
			  and r01_codigo      = t61_cod_vendedor)
		end, "SIN VENDEDOR") vendedor,
	sum(nvl(case when z21_fecha_emi > (select z60_fecha_carga
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
			then z21_saldo -
				nvl((select sum(z23_valor_cap + z23_valor_int)
					from cxct023
					where z23_compania   = z21_compania
					  and z23_localidad  = z21_localidad
					  and z23_codcli     = z21_codcli
					  and z23_tipo_favor = z21_tipo_doc
					  and z23_doc_favor  = z21_num_doc), 0)
			else z21_valor
		end)) saldo_fav
	from cxct021, cxct001
	where z21_compania   = 2
	  and z21_moneda     = "DO"
	  and z21_fecha_emi <= today
	  and z21_saldo      > 0
	  and z01_codcli     = z21_codcli
	group by 1, 2, 3, 4, 5
	order by 4;

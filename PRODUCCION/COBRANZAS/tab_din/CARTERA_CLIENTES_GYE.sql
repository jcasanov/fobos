SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = z20_compania
		  AND g02_localidad = z20_localidad) AS local,
	CASE WHEN z20_areaneg = 1 THEN "INVENTARIO"
	     WHEN z20_areaneg = 2 THEN "TALLER"
	END AS area_neg,
	z20_codcli AS codcli, z01_nomcli AS cliente,
	z20_tipo_doc AS tp_doc, z20_num_doc AS num,
	z20_dividendo AS divid, z20_fecha_emi AS fecha,
	z20_fecha_vcto AS fec_vcto, YEAR(z20_fecha_emi) AS anio,
	NVL(z20_num_sri,
		CASE WHEN z20_areaneg = 1 THEN
			(SELECT r38_num_sri
			FROM rept038
			WHERE r38_compania    = z20_compania
			  AND r38_localidad   = z20_localidad
			  AND r38_tipo_fuente = "PR"
			  AND r38_cod_tran    = z20_cod_tran
			  AND r38_num_tran    = z20_num_tran)
		     WHEN z20_areaneg = 2 THEN
			(SELECT r38_num_sri
			FROM rept038
			WHERE r38_compania    = z20_compania
			  AND r38_localidad   = z20_localidad
			  AND r38_tipo_fuente = "OT"
			  AND r38_cod_tran    = z20_cod_tran
			  AND r38_num_tran    = z20_num_tran)
		     ELSE ""
		END) AS n_sri,
	(SELECT g31_nombre
		FROM gent031
		WHERE g31_ciudad = z01_ciudad
		  AND g31_pais   = z01_pais) AS ciud,
	NVL((SELECT LPAD(g32_zona_venta, 2, 0) || " " || g32_nombre
                FROM cxct002, gent032
                WHERE z02_compania   = z20_compania
                  AND z02_localidad  = z20_localidad
                  AND z02_codcli     = z20_codcli
                  AND g32_compania   = z02_compania
                  AND g32_zona_venta = z02_zona_venta),
		"SIN ZONA VENTA") AS zon_v,
	NVL((SELECT z06_nombre
		FROM cxct002, cxct006
		WHERE z02_compania   = z20_compania
		  AND z02_localidad  = z20_localidad
		  AND z02_codcli     = z20_codcli
		  AND z06_zona_cobro = z02_zona_cobro), "SIN COBRADOR") AS cobr,
	NVL(CASE WHEN z20_areaneg = 1 THEN
		CASE WHEN z20_localidad = 1 THEN
			(SELECT UNIQUE r01_nombres
				FROM rept019, rept001
				WHERE r19_compania  = z20_compania
				  AND r19_localidad = z20_localidad
				  AND r19_cod_tran  = z20_cod_tran
				  AND r19_num_tran  = z20_num_tran
				  AND r01_compania  = r19_compania
				  AND r01_codigo    = r19_vendedor)
		     WHEN z20_localidad = 2 THEN
			(SELECT UNIQUE r01_nombres
				FROM acero_gc:rept019, acero_gc:rept001
				WHERE r19_compania  = z20_compania
				  AND r19_localidad = z20_localidad
				  AND r19_cod_tran  = z20_cod_tran
				  AND r19_num_tran  = z20_num_tran
				  AND r01_compania  = r19_compania
				  AND r01_codigo    = r19_vendedor)
		END
		 WHEN z20_areaneg = 2 THEN
		(SELECT UNIQUE r01_nombres
			FROM talt023, talt061, rept001
			WHERE t23_compania    = z20_compania
			  AND t23_localidad   = z20_localidad
			  AND t23_num_factura = z20_num_tran
			  AND t61_compania    = t23_compania
                	  AND t61_cod_asesor  = t23_cod_asesor
			  AND r01_compania    = t61_compania
			  AND r01_codigo      = t61_cod_vendedor)
		END, "SIN VENDEDOR") AS vendedor,
	((TODAY - z20_fecha_vcto) * (-1)) AS antig,
	(z20_valor_cap + z20_valor_int) AS val_doc,
	(z20_saldo_cap + z20_saldo_int) AS sal_doc,
	NVL(SUM(CASE WHEN TODAY - z20_fecha_vcto <= 0 THEN
	NVL((SELECT z23_valor_cap + z23_valor_int + z23_saldo_cap +
			z23_saldo_int
		FROM cxct023, cxct022
		WHERE z23_compania  = z20_compania
		  AND z23_localidad = z20_localidad
		  AND z23_codcli    = z20_codcli
		  AND z23_tipo_doc  = z20_tipo_doc
		  AND z23_num_doc   = z20_num_doc
		  AND z23_div_doc   = z20_dividendo
		  AND z22_compania  = z23_compania
		  AND z22_localidad = z23_localidad
		  AND z22_codcli    = z23_codcli
		  AND z22_tipo_trn  = z23_tipo_trn
		  AND z22_num_trn   = z23_num_trn
		  AND z22_fecing    = (SELECT max(z22_fecing)
					FROM cxct023, cxct022
					WHERE z23_compania   = z20_compania
					  AND z23_localidad  = z20_localidad
					  AND z23_codcli     = z20_codcli
					  AND z23_tipo_doc   = z20_tipo_doc
					  AND z23_num_doc    = z20_num_doc
					  AND z23_div_doc    = z20_dividendo
					  AND z22_compania   = z23_compania
					  AND z22_localidad  = z23_localidad
					  AND z22_codcli     = z23_codcli
					  AND z22_tipo_trn   = z23_tipo_trn
					  AND z22_num_trn    = z23_num_trn
		  			  AND z22_fecing    <= CURRENT -
					(TODAY - z20_fecha_vcto) UNITS DAY)),
		CASE WHEN z20_fecha_emi <=
				(SELECT z60_fecha_carga
					FROM cxct060
					WHERE z60_compania  = z20_compania
					  AND z60_localidad = z20_localidad)
			THEN z20_saldo_cap + z20_saldo_int -
				NVL((SELECT SUM(z23_valor_cap + z23_valor_int)
					FROM cxct023
					WHERE z23_compania  = z20_compania
					  AND z23_localidad = z20_localidad
					  AND z23_codcli    = z20_codcli
					  AND z23_tipo_doc  = z20_tipo_doc
					  AND z23_num_doc   = z20_num_doc
					  AND z23_div_doc   = z20_dividendo), 0)
			ELSE z20_valor_cap + z20_valor_int
		END)
	END), 0) * (-1) AS por_v,
	NVL(SUM(CASE WHEN TODAY - z20_fecha_vcto  > 0 THEN
	NVL((SELECT z23_valor_cap + z23_valor_int + z23_saldo_cap +
			z23_saldo_int
		FROM cxct023, cxct022
		WHERE z23_compania  = z20_compania
		  AND z23_localidad = z20_localidad
		  AND z23_codcli    = z20_codcli
		  AND z23_tipo_doc  = z20_tipo_doc
		  AND z23_num_doc   = z20_num_doc
		  AND z23_div_doc   = z20_dividendo
		  AND z22_compania  = z23_compania
		  AND z22_localidad = z23_localidad
		  AND z22_codcli    = z23_codcli
		  AND z22_tipo_trn  = z23_tipo_trn
		  AND z22_num_trn   = z23_num_trn
		  AND z22_fecing    = (SELECT max(z22_fecing)
					FROM cxct023, cxct022
					WHERE z23_compania   = z20_compania
					  AND z23_localidad  = z20_localidad
					  AND z23_codcli     = z20_codcli
					  AND z23_tipo_doc   = z20_tipo_doc
					  AND z23_num_doc    = z20_num_doc
					  AND z23_div_doc    = z20_dividendo
					  AND z22_compania   = z23_compania
					  AND z22_localidad  = z23_localidad
					  AND z22_codcli     = z23_codcli
					  AND z22_tipo_trn   = z23_tipo_trn
					  AND z22_num_trn    = z23_num_trn
		  			  AND z22_fecing    <= CURRENT +
					(TODAY - z20_fecha_vcto) UNITS DAY)),
		CASE WHEN z20_fecha_emi <=
				(SELECT z60_fecha_carga
					FROM cxct060
					WHERE z60_compania  = z20_compania
					  AND z60_localidad = z20_localidad)
			THEN z20_saldo_cap + z20_saldo_int -
				NVL((SELECT SUM(z23_valor_cap + z23_valor_int)
					FROM cxct023
					WHERE z23_compania  = z20_compania
					  AND z23_localidad = z20_localidad
					  AND z23_codcli    = z20_codcli
					  AND z23_tipo_doc  = z20_tipo_doc
					  AND z23_num_doc   = z20_num_doc
					  AND z23_div_doc   = z20_dividendo), 0)
			ELSE z20_valor_cap + z20_valor_int
		END)
	END), 0) * (-1) AS venc
	FROM cxct020, cxct001
	WHERE z20_compania                   = 1
	  AND z20_moneda                     = "DO"
	  AND z20_fecha_emi                 <= TODAY
	  AND z20_saldo_cap + z20_saldo_int  > 0
	  AND z01_codcli                     = z20_codcli
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18;

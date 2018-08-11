SELECT "DEUDOR" AS tip_m,
	p20_codprov AS codprov,
	(SELECT p01_nomprov
		FROM acero_qm@acgyede:cxpt001
		WHERE p01_codprov = p20_codprov) AS nomprov,
	p20_tipo_doc AS tip_d,
	p20_num_doc AS num_d,
	p20_dividendo AS divi,
	p20_fecha_emi AS fec_emi,
	p20_fecha_vcto AS fec_vcto,
	CASE WHEN (p20_saldo_cap + p20_saldo_int) > 0
		THEN "CON SALDO DEUDOR"
		ELSE "SIN SALDO"
	END AS con_sl,
	(p20_valor_cap + p20_valor_int) AS val_doc,
	NVL((SELECT p23_valor_cap + p23_valor_int + p23_saldo_cap +
			p23_saldo_int
		FROM acero_qm@acgyede:cxpt023, acero_qm@acgyede:cxpt022
		WHERE p23_compania  = p20_compania
		  AND p23_localidad = p20_localidad
		  AND p23_codprov   = p20_codprov
		  AND p23_tipo_doc  = p20_tipo_doc
		  AND p23_num_doc   = p20_num_doc
		  AND p23_div_doc   = p20_dividendo
		  AND p23_orden     = (SELECT MAX(p23_orden)
					FROM acero_qm@acgyede:cxpt023,
						acero_qm@acgyede:cxpt022
					WHERE p23_compania   = p20_compania
					  AND p23_localidad  = p20_localidad
					  AND p23_codprov    = p20_codprov
					  AND p23_tipo_doc   = p20_tipo_doc
					  AND p23_num_doc    = p20_num_doc
					  AND p23_div_doc    = p20_dividendo
					  AND p22_compania   = p23_compania
					  AND p22_localidad  = p23_localidad
					  AND p22_codprov    = p23_codprov
					  AND p22_tipo_trn   = p23_tipo_trn
					  AND p22_num_trn    = p23_num_trn
					  AND p22_fecing     =
					(SELECT MAX(p22_fecing)
					FROM acero_qm@acgyede:cxpt023,
						acero_qm@acgyede:cxpt022
					WHERE p23_compania   = p20_compania
					  AND p23_localidad  = p20_localidad
					  AND p23_codprov    = p20_codprov
					  AND p23_tipo_doc   = p20_tipo_doc
					  AND p23_num_doc    = p20_num_doc
					  AND p23_div_doc    = p20_dividendo
					  AND p22_compania   = p23_compania
					  AND p22_localidad  = p23_localidad
					  AND p22_codprov    = p23_codprov
					  AND p22_tipo_trn   = p23_tipo_trn
					  AND p22_num_trn    = p23_num_trn
					  AND p22_fecing    <= CURRENT))
		  AND p22_compania  = p23_compania
		  AND p22_localidad = p23_localidad
		  AND p22_codprov   = p23_codprov
		  AND p22_tipo_trn  = p23_tipo_trn
		  AND p22_num_trn   = p23_num_trn
		  AND p22_fecing    = (SELECT MAX(p22_fecing)
					FROM acero_qm@acgyede:cxpt023,
						acero_qm@acgyede:cxpt022
					WHERE p23_compania   = p20_compania
					  AND p23_localidad  = p20_localidad
					  AND p23_codprov    = p20_codprov
					  AND p23_tipo_doc   = p20_tipo_doc
					  AND p23_num_doc    = p20_num_doc
					  AND p23_div_doc    = p20_dividendo
					  AND p22_compania   = p23_compania
					  AND p22_localidad  = p23_localidad
					  AND p22_codprov    = p23_codprov
					  AND p22_tipo_trn   = p23_tipo_trn
					  AND p22_num_trn    = p23_num_trn
					  AND p22_fecing    <= CURRENT)),
		CASE WHEN p20_fecha_emi <=
				(SELECT z60_fecha_carga
					FROM cxct060
					WHERE z60_compania  = p20_compania
					  AND z60_localidad = p20_localidad)
			THEN p20_saldo_cap + p20_saldo_int -
				NVL((SELECT sum(p23_valor_cap + p23_valor_int)
					FROM acero_qm@acgyede:cxpt023
					WHERE p23_compania  = p20_compania
					  AND p23_localidad = p20_localidad
					  AND p23_codprov   = p20_codprov
					  AND p23_tipo_doc  = p20_tipo_doc
					  AND p23_num_doc   = p20_num_doc
					  AND p23_div_doc   = p20_dividendo), 0)
			ELSE p20_valor_cap + p20_valor_int
		END) AS sal_doc
	FROM acero_qm@acgyede:cxpt020
	WHERE p20_compania   = 1
	  AND p20_fecha_emi <= TODAY
UNION ALL
SELECT "A FAVOR" AS tip_m,
	p21_codprov AS codprov,
	(SELECT p01_nomprov
		FROM acero_qm@acgyede:cxpt001
		WHERE p01_codprov = p21_codprov) AS nomprov,
	p21_tipo_doc AS tip_d,
	CAST(p21_num_doc AS CHAR(21)) AS num_d,
	1 AS divi,
	p21_fecha_emi AS fec_emi,
	p21_fecha_emi AS fec_vcto,
	CASE WHEN p21_saldo > 0
		THEN "CON SALDO A FAVOR"
		ELSE "SIN SALDO"
	END AS con_sl,
	(p21_valor * (-1)) AS val_doc,
	(NVL(CASE WHEN p21_fecha_emi > (SELECT z60_fecha_carga
					FROM cxct060
					WHERE z60_compania  = p21_compania
					  AND z60_localidad = p21_localidad)
		THEN
		p21_valor +
		(SELECT SUM(p23_valor_cap + p23_valor_int)
		FROM acero_qm@acgyede:cxpt023, acero_qm@acgyede:cxpt022
		WHERE p23_compania   = p21_compania
		  AND p23_localidad  = p21_localidad
		  AND p23_codprov    = p21_codprov
		  AND p23_tipo_favor = p21_tipo_doc
		  AND p23_doc_favor  = p21_num_doc
		  AND p22_compania   = p23_compania
		  AND p22_localidad  = p23_localidad
		  AND p22_codprov    = p23_codprov
		  AND p22_tipo_trn   = p23_tipo_trn
		  AND p22_num_trn    = p23_num_trn
		  AND p22_fecing     BETWEEN EXTEND(p21_fecha_emi,
								YEAR TO SECOND)
					 AND CURRENT)
		ELSE
		NVL((SELECT SUM(p23_valor_cap + p23_valor_int)
			FROM acero_qm@acgyede:cxpt023
			WHERE p23_compania   = p21_compania
			  AND p23_localidad  = p21_localidad
			  AND p23_codprov    = p21_codprov
			  AND p23_tipo_favor = p21_tipo_doc
			  AND p23_doc_favor  = p21_num_doc), 0) +
		p21_saldo -
		(SELECT SUM(p23_valor_cap + p23_valor_int)
		FROM acero_qm@acgyede:cxpt023, acero_qm@acgyede:cxpt022
		WHERE p23_compania   = p21_compania
		  AND p23_localidad  = p21_localidad
		  AND p23_codprov    = p21_codprov
		  AND p23_tipo_favor = p21_tipo_doc
		  AND p23_doc_favor  = p21_num_doc
		  AND p22_compania   = p23_compania
		  AND p22_localidad  = p23_localidad
		  AND p22_codprov    = p23_codprov
		  AND p22_tipo_trn   = p23_tipo_trn
		  AND p22_num_trn    = p23_num_trn
		  AND p22_fecing     BETWEEN EXTEND(p21_fecha_emi,
								YEAR TO SECOND)
					 AND CURRENT)
		END,
		CASE WHEN p21_fecha_emi <=
				(SELECT z60_fecha_carga
					FROM cxct060
					WHERE z60_compania  = p21_compania
					  AND z60_localidad = p21_localidad)
			THEN p21_saldo -
				NVL((SELECT SUM(p23_valor_cap + p23_valor_int)
					FROM acero_qm@acgyede:cxpt023
					WHERE p23_compania   = p21_compania
					  AND p23_localidad  = p21_localidad
					  AND p23_codprov    = p21_codprov
					  AND p23_tipo_favor = p21_tipo_doc
					  AND p23_doc_favor  = p21_num_doc), 0)
			ELSE p21_valor
		END) * (-1)) AS sal_doc
	FROM acero_qm@acgyede:cxpt021
	WHERE p21_compania   = 1
	  AND p21_fecha_emi <= TODAY;

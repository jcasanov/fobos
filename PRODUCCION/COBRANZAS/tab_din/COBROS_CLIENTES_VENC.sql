SELECT YEAR(z22_fecing) AS anio,
	CASE WHEN MONTH(z22_fecing) = 01 THEN "01_ENERO"
	     WHEN MONTH(z22_fecing) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(z22_fecing) = 03 THEN "03_MARZO"
	     WHEN MONTH(z22_fecing) = 04 THEN "04_ABRIL"
	     WHEN MONTH(z22_fecing) = 05 THEN "05_MAYO"
	     WHEN MONTH(z22_fecing) = 06 THEN "06_JUNIO"
	     WHEN MONTH(z22_fecing) = 07 THEN "07_JULIO"
	     WHEN MONTH(z22_fecing) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(z22_fecing) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(z22_fecing) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(z22_fecing) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(z22_fecing) = 12 THEN "12_DICIEMBRE"
	END AS meses,
	CASE WHEN z22_localidad = 1 THEN "01 J T M"
	     WHEN z22_localidad = 2 THEN "02 CENTRO"
	     WHEN z22_localidad = 3 THEN "03 MATRIZ"
	     WHEN z22_localidad = 4 THEN "04 SUR"
	     WHEN z22_localidad = 5 THEN "05 KOHLER"
	END AS localidad,
	z22_tipo_trn AS tip_trn,
	z22_num_trn AS num_trn,
	z22_codcli AS codcli,
	z01_nomcli AS clientes,
	CASE WHEN z22_areaneg = 1
		THEN "INVENTARIO"
		ELSE "TALLER"
	END AS areaneg,
	z22_usuario AS usuario,
	j01_nombre AS cod_pag,
	j11_cod_bco_tarj AS cta_bco,
	j11_num_ch_aut AS numero,
	j11_num_cta_tarj AS num_cta,
	NVL((SELECT z05_nombres
		FROM cxct005
		WHERE z05_compania = z22_compania
		  AND z05_codigo   = z22_cobrador), "SIN COBRADOR") AS agente,
	z23_tipo_doc AS tipo_doc,
	z23_num_doc AS num_doc,
	z23_div_doc AS dividendo,
	z23_tipo_favor AS tipo_fav,
	z23_doc_favor AS doc_fav,
	z20_fecha_vcto AS fecha_vcto,
	DATE(z22_fecing) AS fecha_pago,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >= 0) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 30)
		THEN (z23_valor_cap + z23_valor_int) * (-1)
		ELSE 0.00
	END AS venc_30,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >= 0) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 30)
		THEN (z23_saldo_cap + z23_saldo_int)
		ELSE 0.00
	END AS sald_30,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >  30) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 60)
		THEN (z23_valor_cap + z23_valor_int) * (-1)
		ELSE 0.00
	END AS venc_60,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >  30) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 60)
		THEN (z23_saldo_cap + z23_saldo_int)
		ELSE 0.00
	END AS sald_60,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >  60) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 90)
		THEN (z23_valor_cap + z23_valor_int) * (-1)
		ELSE 0.00
	END AS venc_90,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >  60) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 90)
		THEN (z23_saldo_cap + z23_saldo_int)
		ELSE 0.00
	END AS sald_90,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >  90) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 120)
		THEN (z23_valor_cap + z23_valor_int) * (-1)
		ELSE 0.00
	END AS venc_120,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >  90) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 120)
		THEN (z23_saldo_cap + z23_saldo_int)
		ELSE 0.00
	END AS sald_120,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >  120) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 180)
		THEN (z23_valor_cap + z23_valor_int) * (-1)
		ELSE 0.00
	END AS venc_180,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto >  120) AND
		  (DATE(z22_fecing) - z20_fecha_vcto <= 180)
		THEN (z23_saldo_cap + z23_saldo_int)
		ELSE 0.00
	END AS sald_180,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto > 180)
		THEN (z23_valor_cap + z23_valor_int) * (-1)
		ELSE 0.00
	END AS venc_may,
	CASE WHEN (DATE(z22_fecing) - z20_fecha_vcto > 180)
		THEN (z23_saldo_cap + z23_saldo_int)
		ELSE 0.00
	END AS sald_may
	FROM cxct022, cxct023, cxct020, cajt010, cajt011, cajt001, cxct001
	WHERE z22_compania     = 1
	  AND YEAR(z22_fecing) > 2008
	  AND z23_compania     = z22_compania
	  AND z23_localidad    = z22_localidad
	  AND z23_codcli       = z22_codcli
	  AND z23_tipo_trn     = z22_tipo_trn
	  AND z23_num_trn      = z22_num_trn
	  AND z20_compania     = z23_compania
	  AND z20_localidad    = z23_localidad
	  AND z20_codcli       = z23_codcli
	  AND z20_tipo_doc     = z23_tipo_doc
	  AND z20_num_doc      = z23_num_doc
	  AND z20_dividendo    = z23_div_doc
	  AND j10_compania     = z22_compania
	  AND j10_localidad    = z22_localidad
	  AND j10_tipo_destino = z22_tipo_trn
	  AND j10_num_destino  = z22_num_trn
	  AND j11_compania     = j10_compania
	  AND j11_localidad    = j10_localidad
	  AND j11_tipo_fuente  = j10_tipo_fuente
	  AND j11_num_fuente   = j10_num_fuente
	  AND j01_compania     = j11_compania
	  AND j01_codigo_pago  = j11_codigo_pago
	  AND j01_cont_cred    = "R"
	  AND z01_codcli       = z22_codcli

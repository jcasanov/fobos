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
	z23_tipo_doc AS tipo_doc,
	z23_num_doc AS num_doc,
	z23_div_doc AS dividendo,
	(z23_valor_cap + z23_valor_int) * (-1) AS valor,
	(z23_saldo_cap + z23_saldo_int) AS saldo
	FROM cxct022, cxct023, cajt010, cajt011, cajt001, cxct001
	WHERE z22_compania     = 1
	  AND YEAR(z22_fecing) > 2009
	  AND z23_compania     = z22_compania
	  AND z23_localidad    = z22_localidad
	  AND z23_codcli       = z22_codcli
	  AND z23_tipo_trn     = z22_tipo_trn
	  AND z23_num_trn      = z22_num_trn
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

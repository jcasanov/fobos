SELECT p20_fecha_emi AS fec_emi,
	"1790208087001" AS ruc,
	"F.V. - AREA ANDINA S.A." AS cliente,
	"FACTURA" AS tipo_fact,
	c13_num_aut AS num_aut,
	c10_factura[1, 7] AS num_ser,
	TRIM(CAST(TRIM(c10_factura[9, 21]) AS VARCHAR(13))) AS num_fact,
	(c10_tot_compra - c10_tot_impto) AS base_imp,
	0.00 AS base_cero,
	c10_tot_impto AS tot_iva,
	c10_tot_compra AS total
	FROM ordt010, ordt013, cxpt020
	WHERE c10_compania     = 1
	  AND c10_localidad    = 1
	  AND c10_estado       = "C"
	  AND c10_codprov      = 57
	  AND c13_compania     = c10_compania
	  AND c13_localidad    = c10_localidad
	  AND c13_numero_oc    = c10_numero_oc
	  AND c13_estado       = "A"
	  AND YEAR(c13_fecing) = 2008
	  AND p20_compania     = c13_compania
	  AND p20_localidad    = c13_localidad
	  AND p20_numero_oc    = c13_numero_oc
	ORDER BY 1 ASC, 7 ASC;

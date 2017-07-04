SELECT p21_fecha_emi AS fec_emi,
	"1790208087001" AS ruc,
	"F.V. - AREA ANDINA S.A." AS cliente,
	"" AS num_aut,
	"" AS num_ser,
	TRIM(CAST(p21_num_doc AS VARCHAR(13))) AS num_nc,
	(p21_valor - (p21_valor * 0.12)) AS base_imp,
	0.00 AS base_cero,
	(p21_valor * 0.12) AS tot_iva,
	p21_valor AS total,
	TRIM(CAST(TRIM(p23_num_doc[9, 21]) AS VARCHAR(13))) AS num_fact
	FROM cxpt021, OUTER cxpt023
	WHERE p21_compania        = 1
	  AND p21_localidad       = 1
	  AND p21_codprov         = 57
	  AND p21_tipo_doc        = "NC"
	  AND YEAR(p21_fecha_emi) = 2008
	  AND p23_compania        = p21_compania
	  AND p23_localidad       = p21_localidad
	  AND p23_codprov         = p21_codprov
	  AND p23_tipo_favor      = p21_tipo_doc
	  AND p23_doc_favor       = p21_num_doc
	ORDER BY 1 ASC, 6 ASC, 11 ASC;

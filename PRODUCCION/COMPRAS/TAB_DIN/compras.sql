SELECT EXTEND(c10_fecha_fact, YEAR TO MONTH) AS PERIODO,
	p01_num_doc AS RUC,
	p01_nomprov AS PROVEEDOR,
	COUNT(c10_factura) AS num_fact,
	NVL(SUM(c10_tot_compra - c10_flete - c10_tot_impto), 0) AS VALOR_COMPRA,
	NVL(SUM(c10_flete), 0) AS FLETE,
	NVL(SUM(c10_tot_impto), 0) AS VALOR_IVA,
	CASE WHEN c10_estado = 'C'
		THEN "CERRADO"
		ELSE "EN PROCESO"
	END AS ESTADO
	FROM ordt010, cxpt001
	WHERE c10_compania   = 1
	  AND c10_localidad  = 1
	  AND c10_tipo_orden = 1
	  AND c10_estado     = 'C'
	  AND p01_codprov    = c10_codprov
	  AND p01_personeria = 'J'
	GROUP BY 1, 2, 3, 8
	ORDER BY 1 DESC, 3 ASC;

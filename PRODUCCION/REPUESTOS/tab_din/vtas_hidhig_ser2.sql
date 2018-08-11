SELECT YEAR(a.r19_fecing) AS anio,
	COUNT(*) AS total_trans,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
			THEN (a.r19_tot_bruto - a.r19_tot_dscto)
			ELSE (a.r19_tot_bruto - a.r19_tot_dscto) * (-1)
		END) AS subtotal,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
			THEN (a.r19_tot_neto - a.r19_tot_bruto + a.r19_tot_dscto
				- a.r19_flete)
			ELSE (a.r19_tot_neto - a.r19_tot_bruto + a.r19_tot_dscto
				- a.r19_flete) * (-1)
		END) AS valor_iva,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
			THEN a.r19_tot_neto
			ELSE a.r19_tot_neto * (-1)
		END) AS total_neto
	FROM rept019 a
	WHERE a.r19_compania     = 2
	  AND a.r19_localidad    = 6
	  AND a.r19_cod_tran     IN ('FA', 'DF')
	  AND a.r19_codcli       = 1309
	  AND YEAR(a.r19_fecing) BETWEEN 2008 AND 2009
	GROUP BY 1
	ORDER BY 1 ASC;

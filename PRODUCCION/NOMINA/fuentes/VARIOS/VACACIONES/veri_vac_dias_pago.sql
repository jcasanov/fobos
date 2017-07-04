SELECT n39_cod_trab cod, n30_nombres empleados, n39_ano_proceso anio,
	(n39_valor_vaca + n39_valor_adic) val_vac, n39_descto_iess ap_iess,
	((n39_valor_vaca + n39_valor_adic) - n39_descto_iess) val_pag,
	SUM(n47_valor_pag) val_v_r,
	SUM(n47_valor_des) val_d_r,
	SUM(n47_valor_pag - n47_valor_des) ap_iess_r
	FROM rolt039, rolt047, rolt030
	WHERE n39_compania     = 1
	  AND n39_proceso     IN ("VA", "VP")
	  AND n39_ano_proceso  = 2012
	  AND n47_compania     = n39_compania
	  AND n47_proceso      = n39_proceso
	  AND n47_cod_trab     = n39_cod_trab
	  AND n47_periodo_ini  = n39_periodo_ini
	  AND n47_periodo_fin  = n39_periodo_fin
	  AND n30_compania     = n47_compania
	  AND n30_cod_trab     = n47_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6
	INTO TEMP tmp_v;
SELECT * FROM tmp_v
	--WHERE ap_iess <> ap_iess_r
	WHERE val_vac <> val_v_r
	ORDER BY 3, 2;
DROP TABLE tmp_v;

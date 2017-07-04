SELECT UNIQUE j14_compania, j14_localidad, j14_tipo_fuente, j14_num_fuente
	FROM cajt014
	WHERE j14_compania      = 1
	  AND j14_tipo_fuente   = 'SC'
	  AND DATE(j14_fecing) >= MDY(11, 18, 2011)
	INTO TEMP tmp_j14;
SELECT j14_compania AS compania, b12_tipo_comp AS tip_com,
	b12_num_comp AS num_comp, b12_fec_proceso AS fecha_comp,
	b12_fecing AS fecha_ing, NVL(SUM(j10_valor), 0) AS valor
	FROM tmp_j14, cajt010, cxct040, cxct001, ctbt012
	WHERE j10_compania      = j14_compania
	  AND j10_localidad     = j14_localidad
	  AND j10_tipo_fuente   = j14_tipo_fuente
	  AND j10_num_fuente    = j14_num_fuente
	  AND z40_compania      = j10_compania
	  AND z40_localidad     = j10_localidad
	  AND z40_codcli        = j10_codcli
	  AND z40_tipo_doc      = j10_tipo_destino
	  AND z40_num_doc       = j10_num_destino
	  AND z01_codcli        = j10_codcli
	  AND b12_compania      = z40_compania
	  AND b12_tipo_comp     = z40_tipo_comp
	  AND b12_num_comp      = z40_num_comp
	  AND b12_tipo_comp     = z40_tipo_comp
	  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) = "2011-09"
	GROUP BY 1, 2, 3, 4, 5
	INTO TEMP t1;
DROP TABLE tmp_j14;
SELECT ROUND(SUM(valor), 2) AS total
	FROM t1;
SELECT * FROM t1
	ORDER BY fecha_ing ASC;
UNLOAD TO "diario_ret.unl"
	SELECT compania, tip_com, num_comp, MDY(10, 01, 2011) fecha_comp,
		fecha_ing
		FROM t1
		ORDER BY fecha_ing ASC;
DROP TABLE t1;

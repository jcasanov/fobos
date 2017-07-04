SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_nombre)
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = a10_compania
		  AND g02_localidad = a10_localidad) AS local,
	YEAR(a.a12_fecing) AS anio,
	CASE WHEN MONTH(a.a12_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.a12_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.a12_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.a12_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.a12_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.a12_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.a12_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.a12_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.a12_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.a12_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.a12_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.a12_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	a.a12_codigo_bien AS acti,
	a10_descripcion AS desc_act,
	LPAD(a10_grupo_act, 2, 0) || " " || TRIM(a01_nombre) AS desc_gru,
	LPAD(a10_tipo_act, 3, 0) || " " || TRIM(a02_nombre) AS desc_tip,
	a10_numero_oc AS num_oc,
	DATE((SELECT DATE(MAX(b.a12_fecing))
		FROM acero_gm@idsgye01:actt012 b
		WHERE b.a12_compania     = a.a12_compania
		  AND b.a12_codigo_tran IN ("IN", "TR")
		  AND b.a12_codigo_bien  = a.a12_codigo_bien)) AS fec_comp,
	NVL(DATE((SELECT DATE(b.a12_fecing)
		FROM acero_gm@idsgye01:actt012 b
		WHERE b.a12_compania    = a.a12_compania
		  AND b.a12_codigo_tran = "RV"
		  AND b.a12_codigo_bien = a.a12_codigo_bien)), "") AS fec_reval,
	DATE(a.a12_fecing) AS fecha,
	a10_anos_util AS anio_u,
	(a.a12_porc_deprec / 100) AS porc,
	a10_val_dep_mb AS val_dep,
	a.a12_referencia AS refer,
	a.a12_depto_ori AS cod_dep,
	(SELECT g34_nombre
		FROM acero_gm@idsgye01:gent034
		WHERE g34_compania  = a.a12_compania
		  AND g34_cod_depto = a.a12_depto_ori) AS desc_dep,
	a.a12_tipcomp_gen AS tip_comp,
	a.a12_numcomp_gen AS num_comp,
	a.a12_codigo_tran AS cod_tran,
	CASE WHEN (a.a12_valor_mb > 0 AND a.a12_codigo_tran <> "DP")
		THEN a.a12_valor_mb
		ELSE 0.00
	END AS val_act,
	CASE WHEN a.a12_codigo_tran = "DP"
		THEN a.a12_valor_mb
		ELSE 0.00
	END AS dep_acum,
	CASE WHEN (a.a12_valor_mb <= 0 AND a.a12_codigo_tran <> "DP")
		THEN a.a12_valor_mb
		ELSE 0.00
	END AS val_mov,
	NVL(a.a12_valor_mb, 0.00) AS saldo,
	(SELECT a06_descripcion
		FROM acero_gm@idsgye01:actt006
		WHERE a06_compania = a10_compania
		  AND a06_estado   = a10_estado) AS est
	FROM acero_gm@idsgye01:actt012 a, acero_gm@idsgye01:actt010,
		acero_gm@idsgye01:actt001, acero_gm@idsgye01:actt002
	WHERE a.a12_compania  = 1
	  AND a10_compania    = a.a12_compania
	  AND a10_codigo_bien = a.a12_codigo_bien
	  AND a01_compania    = a10_compania
	  AND a01_grupo_act   = a10_grupo_act
	  AND a02_compania    = a01_compania
	  AND a02_grupo_act   = a01_grupo_act
	  AND a02_tipo_act    = a10_tipo_act
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_nombre)
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = a10_compania
		  AND g02_localidad = a10_localidad) AS local,
	YEAR(a.a12_fecing) AS anio,
	CASE WHEN MONTH(a.a12_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.a12_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.a12_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.a12_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.a12_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.a12_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.a12_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.a12_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.a12_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.a12_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.a12_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.a12_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	a.a12_codigo_bien AS acti,
	a10_descripcion AS desc_act,
	LPAD(a10_grupo_act, 2, 0) || " " || TRIM(a01_nombre) AS desc_gru,
	LPAD(a10_tipo_act, 3, 0) || " " || TRIM(a02_nombre) AS desc_tip,
	a10_numero_oc AS num_oc,
	DATE((SELECT DATE(MAX(b.a12_fecing))
		FROM acero_qm@idsuio01:actt012 b
		WHERE b.a12_compania     = a.a12_compania
		  AND b.a12_codigo_tran IN ("IN", "TR")
		  AND b.a12_codigo_bien  = a.a12_codigo_bien)) AS fec_comp,
	NVL(DATE((SELECT DATE(b.a12_fecing)
		FROM acero_qm@idsuio01:actt012 b
		WHERE b.a12_compania    = a.a12_compania
		  AND b.a12_codigo_tran = "RV"
		  AND b.a12_codigo_bien = a.a12_codigo_bien)), "") AS fec_reval,
	DATE(a.a12_fecing) AS fecha,
	a10_anos_util AS anio_u,
	(a.a12_porc_deprec / 100) AS porc,
	a10_val_dep_mb AS val_dep,
	a.a12_referencia AS refer,
	a.a12_depto_ori AS cod_dep,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = a.a12_compania
		  AND g34_cod_depto = a.a12_depto_ori) AS desc_dep,
	a.a12_tipcomp_gen AS tip_comp,
	a.a12_numcomp_gen AS num_comp,
	a.a12_codigo_tran AS cod_tran,
	CASE WHEN (a.a12_valor_mb > 0 AND a.a12_codigo_tran <> "DP")
		THEN a.a12_valor_mb
		ELSE 0.00
	END AS val_act,
	CASE WHEN a.a12_codigo_tran = "DP"
		THEN a.a12_valor_mb
		ELSE 0.00
	END AS dep_acum,
	CASE WHEN (a.a12_valor_mb <= 0 AND a.a12_codigo_tran <> "DP")
		THEN a.a12_valor_mb
		ELSE 0.00
	END AS val_mov,
	NVL(a.a12_valor_mb, 0.00) AS saldo,
	(SELECT a06_descripcion
		FROM acero_qm@idsuio01:actt006
		WHERE a06_compania = a10_compania
		  AND a06_estado   = a10_estado) AS est
	FROM acero_qm@idsuio01:actt012 a, acero_qm@idsuio01:actt010,
		acero_qm@idsuio01:actt001, acero_qm@idsuio01:actt002
	WHERE a.a12_compania  = 1
	  AND a10_compania    = a.a12_compania
	  AND a10_codigo_bien = a.a12_codigo_bien
	  AND a01_compania    = a10_compania
	  AND a01_grupo_act   = a10_grupo_act
	  AND a02_compania    = a01_compania
	  AND a02_grupo_act   = a01_grupo_act
	  AND a02_tipo_act    = a10_tipo_act;

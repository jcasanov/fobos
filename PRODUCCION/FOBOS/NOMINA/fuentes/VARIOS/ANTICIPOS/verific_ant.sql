SELECT n45_cod_trab AS cod,
	(SELECT n30_nombres
		FROM rolt030
		WHERE n30_compania = n45_compania
		  AND n30_cod_trab = n45_cod_trab) AS empleado,
	n45_num_prest AS antic, n45_cod_rubro AS cr,
	(SELECT n06_nombre_abr
		FROM rolt006
		WHERE n06_cod_rubro = n45_cod_rubro) AS rubro,
	CASE WHEN n45_estado = 'A' THEN "ACTIVO"
	     WHEN n45_estado = 'R' THEN "REDISTRIBUIDO"
	END AS estado,
	n46_cod_liqrol AS lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n46_cod_liqrol) AS proceso,
	n46_fecha_fin AS fec_pro, n46_valor AS valor, n46_saldo AS saldo
	FROM rolt045, rolt046
	WHERE n45_compania   IN (1, 2)
	  AND n45_estado     IN ('A', 'R')
	  AND n46_compania    = n45_compania
	  AND n46_num_prest   = n45_num_prest
	  AND n46_cod_liqrol  = 'Q1'
	  AND n46_saldo       > 0
	  AND n46_fecha_fin   < MDY(MONTH(TODAY), 15, YEAR(TODAY))
UNION
SELECT n45_cod_trab AS cod,
	(SELECT n30_nombres
		FROM rolt030
		WHERE n30_compania = n45_compania
		  AND n30_cod_trab = n45_cod_trab) AS empleado,
	n45_num_prest AS antic, n45_cod_rubro AS cr,
	(SELECT n06_nombre_abr
		FROM rolt006
		WHERE n06_cod_rubro = n45_cod_rubro) AS rubro,
	CASE WHEN n45_estado = 'A' THEN "ACTIVO"
	     WHEN n45_estado = 'R' THEN "REDISTRIBUIDO"
	END AS estado,
	n46_cod_liqrol AS lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n46_cod_liqrol) AS proceso,
	n46_fecha_fin AS fec_pro, n46_valor AS valor, n46_saldo AS saldo
	FROM rolt045, rolt046
	WHERE n45_compania   IN (1, 2)
	  AND n45_estado     IN ('A', 'R')
	  AND n46_compania    = n45_compania
	  AND n46_num_prest   = n45_num_prest
	  AND n46_cod_liqrol  = 'Q2'
	  AND n46_saldo       > 0
	  AND n46_fecha_fin   < MDY(MONTH(TODAY), 01, YEAR(TODAY))
					+ 1 UNITS MONTH - 1 UNITS DAY
UNION
SELECT n45_cod_trab AS cod,
	(SELECT n30_nombres
		FROM rolt030
		WHERE n30_compania = n45_compania
		  AND n30_cod_trab = n45_cod_trab) AS empleado,
	n45_num_prest AS antic, n45_cod_rubro AS cr,
	(SELECT n06_nombre_abr
		FROM rolt006
		WHERE n06_cod_rubro = n45_cod_rubro) AS rubro,
	CASE WHEN n45_estado = 'A' THEN "ACTIVO"
	     WHEN n45_estado = 'R' THEN "REDISTRIBUIDO"
	END AS estado,
	n46_cod_liqrol AS lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n46_cod_liqrol) AS proceso,
	n46_fecha_fin AS fec_pro, n46_valor AS valor, n46_saldo AS saldo
	FROM rolt045, rolt046
	WHERE n45_compania   IN (1, 2)
	  AND n45_estado     IN ('A', 'R')
	  AND n46_compania    = n45_compania
	  AND n46_num_prest   = n45_num_prest
	  AND n46_cod_liqrol IN ('VA', 'VP')
	  AND n46_saldo       > 0
	  AND EXTEND(n46_fecha_fin, YEAR TO MONTH) <=
		EXTEND(TODAY, YEAR TO MONTH)
UNION
SELECT n45_cod_trab AS cod,
	(SELECT n30_nombres
		FROM rolt030
		WHERE n30_compania = n45_compania
		  AND n30_cod_trab = n45_cod_trab) AS empleado,
	n45_num_prest AS antic, n45_cod_rubro AS cr,
	(SELECT n06_nombre_abr
		FROM rolt006
		WHERE n06_cod_rubro = n45_cod_rubro) AS rubro,
	CASE WHEN n45_estado = 'A' THEN "ACTIVO"
	     WHEN n45_estado = 'R' THEN "REDISTRIBUIDO"
	END AS estado,
	n46_cod_liqrol AS lq, n03_nombre_abr AS proceso,
	n46_fecha_fin AS fec_pro, n46_valor AS valor, n46_saldo AS saldo
	FROM rolt045, rolt046, rolt003
	WHERE n45_compania   IN (1, 2)
	  AND n45_estado     IN ('A', 'R')
	  AND n46_compania    = n45_compania
	  AND n46_num_prest   = n45_num_prest
	  AND n46_cod_liqrol IN ('DT', 'DC')
	  AND n46_saldo       > 0
	  AND n46_fecha_fin   < MDY(n03_mes_fin, n03_dia_fin, YEAR(TODAY))
	  AND n03_proceso     = n46_cod_liqrol
UNION
SELECT n45_cod_trab AS cod,
	(SELECT n30_nombres
		FROM rolt030
		WHERE n30_compania = n45_compania
		  AND n30_cod_trab = n45_cod_trab) AS empleado,
	n45_num_prest AS antic, n45_cod_rubro AS cr,
	(SELECT n06_nombre_abr
		FROM rolt006
		WHERE n06_cod_rubro = n45_cod_rubro) AS rubro,
	CASE WHEN n45_estado = 'A' THEN "ACTIVO"
	     WHEN n45_estado = 'R' THEN "REDISTRIBUIDO"
	END AS estado,
	n46_cod_liqrol AS lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n46_cod_liqrol) AS proceso,
	n46_fecha_fin AS fec_pro, n46_valor AS valor, n46_saldo AS saldo
	FROM rolt045, rolt046
	WHERE n45_compania        IN (1, 2)
	  AND n45_estado          IN ('A', 'R')
	  AND n46_compania         = n45_compania
	  AND n46_num_prest        = n45_num_prest
	  AND n46_cod_liqrol       = 'UT'
	  AND n46_saldo            > 0
	  AND YEAR(n46_fecha_fin)  < YEAR(TODAY) - 1
	ORDER BY 2 ASC, 9 DESC;

SELECT SUM(CASE WHEN a.n45_estado <> "T"
		THEN (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant)
		ELSE (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant)
			- NVL((SELECT b.n45_sal_prest_ant
				FROM rolt045 b
				WHERE b.n45_compania      = a.n45_compania
				  AND b.n45_num_prest     = a.n45_prest_tran
				  AND DATE(b.n45_fecing) <= TODAY), 0)
	END) val_d,
	0.00 val_p
	FROM rolt030, rolt045 a
	WHERE n30_compania        = 1
	  AND n30_cod_trab        = 114
	  AND a.n45_compania      = n30_compania
	  AND a.n45_cod_trab      = n30_cod_trab
	  AND a.n45_estado       IN ("A", "R", "P", "T")
	  AND DATE(a.n45_fecing) >= "01/01/2009"
	  AND DATE(a.n45_fecing)  < "01/01/2010"
	GROUP BY 2
UNION ALL
SELECT 0.00 val_d, SUM(n33_valor) val_p
	FROM rolt030, rolt033, rolt032
	WHERE n30_compania      = 1
	  AND n30_cod_trab      = 114
	  AND n33_compania      = n30_compania
	  AND n33_cod_liqrol   IN ("Q1", "Q2")
	  AND n33_cod_trab      = n30_cod_trab
	  AND n33_cod_rubro    IN
		(SELECT UNIQUE n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT UNIQUE n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n33_valor         > 0
	  AND n33_det_tot       = "DE"
	  AND n33_cant_valor    = "V"
	  AND n32_compania      = n33_compania
	  AND n32_cod_liqrol    = n33_cod_liqrol
	  AND n32_fecha_ini     = n33_fecha_ini
	  AND n32_fecha_fin     = n33_fecha_fin
	  AND n32_cod_trab      = n33_cod_trab
	  AND DATE(n32_fecing) >= "01/01/2009"
	  AND DATE(n32_fecing)  < "01/01/2010"
	GROUP BY 1
UNION ALL
SELECT 0.00 val_d, SUM(n37_valor) val_p
	FROM rolt030, rolt037, rolt036
	WHERE n30_compania      = 1
	  AND n30_cod_trab      = 114
	  AND n37_compania      = n30_compania
	  AND n37_proceso      IN ("DT", "DC")
	  AND n37_cod_trab      = n30_cod_trab
	  AND n37_cod_rubro    IN
		(SELECT UNIQUE n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT UNIQUE n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n37_valor         > 0
	  AND n36_compania      = n37_compania
	  AND n36_proceso       = n37_proceso
	  AND n36_fecha_ini     = n37_fecha_ini
	  AND n36_fecha_fin     = n37_fecha_fin
	  AND n36_cod_trab      = n37_cod_trab
	  AND DATE(n36_fecing) >= "01/01/2009"
	  AND DATE(n36_fecing)  < "01/01/2010"
	GROUP BY 1
UNION ALL
SELECT 0.00 val_d, SUM(n40_valor) val_p
	FROM rolt030, rolt040, rolt039
	WHERE n30_compania      = 1
	  AND n30_cod_trab      = 114
	  AND n40_compania      = n30_compania
	  AND n40_proceso      IN ("VA", "VP")
	  AND n40_cod_trab      = n30_cod_trab
	  AND n40_cod_rubro    IN
		(SELECT UNIQUE n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT UNIQUE n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n40_valor         > 0
	  AND n40_det_tot       = "DE"
	  AND n39_compania      = n40_compania
	  AND n39_proceso       = n40_proceso
	  AND n39_periodo_ini   = n40_periodo_ini
	  AND n39_periodo_fin   = n40_periodo_fin
	  AND n39_cod_trab      = n40_cod_trab
	  AND DATE(n39_fecing) >= "01/01/2009"
	  AND DATE(n39_fecing)  < "01/01/2010"
	GROUP BY 1
UNION ALL
SELECT 0.00 val_d, SUM(n49_valor) val_p
	FROM rolt030, rolt049, rolt042, rolt041
	WHERE n30_compania    = 1
	  AND n30_cod_trab    = 114
	  AND n49_compania      = n30_compania
	  AND n49_proceso       = "UT"
	  AND n49_cod_trab      = n30_cod_trab
	  AND n49_cod_rubro    IN
		(SELECT UNIQUE n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT UNIQUE n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n49_valor         > 0
	  AND n49_det_tot       = "DE"
	  AND n42_compania      = n49_compania
	  AND n42_proceso       = n49_proceso
	  AND n42_cod_trab      = n49_cod_trab
	  AND n42_fecha_ini     = n49_fecha_ini
	  AND n42_fecha_fin     = n49_fecha_fin
	  AND n41_compania      = n42_compania
	  AND n41_proceso       = n42_proceso
	  AND n41_fecha_ini     = n42_fecha_ini
	  AND n41_fecha_fin     = n42_fecha_fin
	  AND DATE(n41_fecing) >= "01/01/2009"
	  AND DATE(n41_fecing)  < "01/01/2010"
	GROUP BY 1
UNION ALL
SELECT 0.00 val_d, SUM(ABS(n92_valor_pago)) val_p
	FROM rolt030, rolt091, rolt092
	WHERE n30_compania      = 1
	  AND n30_cod_trab    = 114
	  AND n91_compania      = n30_compania
	  AND n91_proceso       = "CA"
	  AND n91_cod_trab      = n30_cod_trab
	  AND DATE(n91_fecing) >= "01/01/2009"
	  AND DATE(n91_fecing)  < "01/01/2010"
	  AND n92_compania      = n91_compania
	  AND n92_proceso       = n91_proceso
	  AND n92_cod_trab      = n91_cod_trab
	  AND n92_num_ant       = n91_num_ant
	  AND n92_valor_pago   <> 0
	GROUP BY 1
	INTO TEMP t1;

SELECT ROUND(NVL(SUM(NVL(val_d, 0) - NVL(val_p, 0)), 0), 2) saldo_ini
	FROM t1
	INTO TEMP t2;

DROP TABLE t1;

SELECT * FROM t2;

SELECT a.n45_num_prest num_prest, a.n45_estado cod_p,
	CASE WHEN a.n45_estado = "A" THEN "ACTIVO"
	     WHEN a.n45_estado = "P" THEN "PROCESADO"
	     WHEN a.n45_estado = "R" THEN "REDISTRIBUIDO"
	     WHEN a.n45_estado = "T" THEN "TRANSFERIDO"
	END nom_p,
	DATE(a.n45_fecing) fecha,
	CASE WHEN a.n45_estado <> "T"
		THEN (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant)
		ELSE (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant)
			- NVL((SELECT b.n45_sal_prest_ant
				FROM rolt045 b
				WHERE b.n45_compania      = a.n45_compania
				  AND b.n45_num_prest     = a.n45_prest_tran
				  AND DATE(b.n45_fecing) <= TODAY), 0)
	END val_d,
	0.00 val_a, LPAD(a.n45_cod_rubro, 2, 0) rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = a.n45_cod_rubro) nom_r
	FROM rolt030, rolt045 a
	WHERE n30_compania        = 1
	  AND n30_cod_trab        = 114
	  AND a.n45_compania      = n30_compania
	  AND a.n45_cod_trab      = n30_cod_trab
	  AND a.n45_estado       IN ("A", "R", "P", "T")
	  AND DATE(a.n45_fecing) BETWEEN "01/01/2010"
				     AND TODAY
UNION ALL
SELECT n33_num_prest num_prest, n33_cod_liqrol cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n33_cod_liqrol) nom_p,
	DATE(n32_fecing) fecha, 0.00 val_d, n33_valor val_p,
	LPAD(n33_cod_rubro, 2, 0) rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = n33_cod_rubro) nom_r
	FROM rolt030, rolt033, rolt032
	WHERE n30_compania      = 1
	  AND n30_cod_trab      = 114
	  AND n33_compania      = n30_compania
	  AND n33_cod_liqrol   IN ("Q1", "Q2")
	  AND n33_cod_trab      = n30_cod_trab
	  AND n33_cod_rubro    IN
		(SELECT UNIQUE n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT UNIQUE n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n33_valor         > 0
 	  AND n33_det_tot       = "DE"
	  AND n33_cant_valor    = "V"
	  AND n32_compania      = n33_compania
	  AND n32_cod_liqrol    = n33_cod_liqrol
	  AND n32_fecha_ini     = n33_fecha_ini
	  AND n32_fecha_fin     = n33_fecha_fin
	  AND n32_cod_trab      = n33_cod_trab
	  AND DATE(n32_fecing) BETWEEN "01/01/2010"
				   AND TODAY
UNION ALL
SELECT n37_num_prest num_prest, n37_proceso cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n37_proceso) nom_p,
	DATE(n36_fecing) fecha, 0.00 val_d, n37_valor val_p,
	LPAD(n37_cod_rubro, 2, 0) rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = n37_cod_rubro) nom_r
	FROM rolt030, rolt037, rolt036
	WHERE n30_compania     = 1
	  AND n30_cod_trab     = 114
	  AND n37_compania     = n30_compania
	  AND n37_proceso     IN ("DT", "DC")
	  AND n37_cod_trab     = n30_cod_trab
	  AND n37_cod_rubro   IN
		(SELECT UNIQUE n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT UNIQUE n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n37_valor         > 0
	  AND n36_compania      = n37_compania
	  AND n36_proceso       = n37_proceso
	  AND n36_fecha_ini     = n37_fecha_ini
	  AND n36_fecha_fin     = n37_fecha_fin
	  AND n36_cod_trab      = n37_cod_trab
	  AND DATE(n36_fecing) BETWEEN "01/01/2010"
				   AND TODAY
UNION ALL
SELECT n40_num_prest num_prest, n40_proceso cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n40_proceso) nom_p,
	DATE(n39_fecing) fecha, 0.00 val_d, n40_valor val_p,
	LPAD(n40_cod_rubro, 2, 0) rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = n40_cod_rubro) nom_r
	FROM rolt030, rolt040, rolt039
	WHERE n30_compania    = 1
	  AND n30_cod_trab    = 114
	  AND n40_compania      = n30_compania
	  AND n40_proceso      IN ("VA", "VP")
	  AND n40_cod_trab      = n30_cod_trab
	  AND n40_cod_rubro    IN
		(SELECT UNIQUE n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT UNIQUE n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n40_valor         > 0
	  AND n40_det_tot       = "DE"
	  AND n39_compania      = n40_compania
	  AND n39_proceso       = n40_proceso
	  AND n39_periodo_ini   = n40_periodo_ini
	  AND n39_periodo_fin   = n40_periodo_fin
	  AND n39_cod_trab      = n40_cod_trab
	  AND DATE(n39_fecing) BETWEEN "01/01/2010"
				   AND TODAY
UNION ALL
SELECT n49_num_prest num_prest, n49_proceso cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n49_proceso) nom_p,
	DATE(n41_fecing) fecha, 0.00 val_d, n49_valor val_p,
	LPAD(n49_cod_rubro, 2, 0) rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = n49_cod_rubro) nom_r
	FROM rolt030, rolt049, rolt042, rolt041
	WHERE n30_compania      = 1
	  AND n30_cod_trab      = 114
	  AND n49_compania      = n30_compania
	  AND n49_proceso       = "UT"
	  AND n49_cod_trab      = n30_cod_trab
	  AND n49_cod_rubro    IN
		(SELECT UNIQUE n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT UNIQUE n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n49_valor         > 0
	  AND n49_det_tot       = "DE"
	  AND n42_compania      = n49_compania
	  AND n42_proceso       = n49_proceso
	  AND n42_cod_trab      = n49_cod_trab
	  AND n42_fecha_ini     = n49_fecha_ini
	  AND n42_fecha_fin     = n49_fecha_fin
	  AND n41_compania      = n42_compania
	  AND n41_proceso       = n42_proceso
	  AND n41_fecha_ini     = n42_fecha_ini
	  AND n41_fecha_fin     = n42_fecha_fin
	  AND DATE(n41_fecing) BETWEEN "01/01/2010"
				   AND TODAY
UNION ALL
SELECT n92_num_prest num_prest, n91_proceso cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n91_proceso) nom_p,
	DATE(n91_fecing) fecha, 0.00 val_d, ABS(n92_valor_pago) val_p,
	n92_cod_liqrol rubro,
	(SELECT n03_nombre
		FROM rolt003
		WHERE n03_proceso = n92_cod_liqrol) nom_r
	FROM rolt030, rolt091, rolt092
	WHERE n30_compania      = 1
	  AND n30_cod_trab      = 114
	  AND n91_compania      = n30_compania
	  AND n91_proceso       = "CA"
	  AND n91_cod_trab      = n30_cod_trab
	  AND DATE(n91_fecing) BETWEEN "01/01/2010"
				   AND TODAY
	  AND n92_compania      = n91_compania
	  AND n92_proceso       = n91_proceso
	  AND n92_cod_trab      = n91_cod_trab
	  AND n92_num_ant       = n91_num_ant
	  AND n92_valor_pago   <> 0
	INTO TEMP t1;

SELECT LPAD(num_prest, 5, 0) ant, cod_p cp, nom_p[1, 10] nom_p, fecha, val_d,
	val_a
	FROM t1
	ORDER BY 4, 5 DESC;

SELECT ROUND(SUM(val_d), 2) tot_d, ROUND(SUM(val_a), 2) tot_a
	FROM t1
	INTO TEMP t3;

SELECT * FROM t3;

DROP TABLE t1;

SELECT ROUND(saldo_ini + tot_d - tot_a, 2) saldo_fin
	FROM t2, t3
	WHERE 1 = 1;

DROP TABLE t2;

DROP TABLE t3;

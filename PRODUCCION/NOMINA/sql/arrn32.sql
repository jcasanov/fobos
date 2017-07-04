SELECT rolt033.*, n32_cod_trab
        FROM rolt033, OUTER rolt032
        WHERE n32_compania   = n33_compania
          AND n32_cod_liqrol = n33_cod_liqrol
          AND n32_fecha_ini  = n33_fecha_ini
          AND n32_fecha_fin  = n33_fecha_fin
          AND n32_cod_trab   = n33_cod_trab
	  AND n33_fecha_fin <= MDY(08, 31, 2003)
        INTO TEMP t1;
DELETE FROM t1 WHERE n32_cod_trab IS NOT NULL;
SELECT t1.*, n30_nombres, n30_cod_depto
	FROM t1, rolt030
	WHERE n33_cod_trab = n30_cod_trab
	INTO TEMP temp_emp;
DROP TABLE t1;
SELECT COUNT(*) total_rubros FROM temp_emp;
SELECT UNIQUE n33_compania, n33_cod_liqrol, n33_fecha_ini, n33_fecha_fin,
	n33_cod_trab, n30_nombres, n30_cod_depto
	FROM temp_emp
	INTO TEMP t2;
SELECT COUNT(*) total_emp FROM t2;
BEGIN WORK;
INSERT INTO rolt032
	SELECT n33_compania, n33_cod_liqrol, n33_fecha_ini, n33_fecha_fin,
		n33_cod_trab, 'C', n30_cod_depto,
		NVL((SELECT UNIQUE a.n33_valor
			FROM temp_emp a
			WHERE a.n33_compania   = n33_compania
			  AND a.n33_cod_liqrol = n33_cod_liqrol
			  AND a.n33_fecha_ini  = n33_fecha_ini
			  AND a.n33_fecha_fin  = n33_fecha_fin
			  AND a.n33_cod_trab   = n33_cod_trab
			  AND a.n33_cod_rubro  IN
				(SELECT UNIQUE n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = 'VT')), 0) * 2,
		YEAR(n33_fecha_fin), MONTH(n33_fecha_fin), 0, 
		NVL((SELECT UNIQUE a.n33_valor
			FROM temp_emp a
			WHERE a.n33_compania   = n33_compania
			  AND a.n33_cod_liqrol = n33_cod_liqrol
			  AND a.n33_fecha_ini  = n33_fecha_ini
			  AND a.n33_fecha_fin  = n33_fecha_fin
			  AND a.n33_cod_trab   = n33_cod_trab
			  AND a.n33_cod_rubro  IN
				(SELECT UNIQUE n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = 'DT')), 0),
		NVL((SELECT UNIQUE a.n33_valor
			FROM temp_emp a
			WHERE a.n33_compania   = n33_compania
			  AND a.n33_cod_liqrol = n33_cod_liqrol
			  AND a.n33_fecha_ini  = n33_fecha_ini
			  AND a.n33_fecha_fin  = n33_fecha_fin
			  AND a.n33_cod_trab   = n33_cod_trab
			  AND a.n33_cod_rubro  IN
				(SELECT UNIQUE n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = 'DF')), 0),
		NVL((SELECT SUM(a.n33_valor)
			FROM temp_emp a
			WHERE a.n33_compania   = n33_compania
			  AND a.n33_cod_liqrol = n33_cod_liqrol
			  AND a.n33_fecha_ini  = n33_fecha_ini
			  AND a.n33_fecha_fin  = n33_fecha_fin
			  AND a.n33_cod_trab   = n33_cod_trab
			  AND a.n33_cod_rubro  IN
				(SELECT UNIQUE n08_rubro_base
					FROM rolt008, rolt006
					WHERE n06_cod_rubro  = n08_cod_rubro
					  AND n06_flag_ident = 'AP')), 0),
		NVL((SELECT SUM(a.n33_valor)
			FROM temp_emp a
			WHERE a.n33_compania   = n33_compania
			  AND a.n33_cod_liqrol = n33_cod_liqrol
			  AND a.n33_fecha_ini  = n33_fecha_ini
			  AND a.n33_fecha_fin  = n33_fecha_fin
			  AND a.n33_cod_trab   = n33_cod_trab
			  AND a.n33_det_tot    = 'DI'
			  AND a.n33_cant_valor = 'V'), 0),
		NVL((SELECT SUM(a.n33_valor)
			FROM temp_emp a
			WHERE a.n33_compania   = n33_compania
			  AND a.n33_cod_liqrol = n33_cod_liqrol
			  AND a.n33_fecha_ini  = n33_fecha_ini
			  AND a.n33_fecha_fin  = n33_fecha_fin
			  AND a.n33_cod_trab   = n33_cod_trab
			  AND a.n33_det_tot    = 'DE'
			  AND a.n33_cant_valor = 'V'), 0),
		NVL((SELECT SUM(a.n33_valor)
			FROM temp_emp a
			WHERE a.n33_compania   = n33_compania
			  AND a.n33_cod_liqrol = n33_cod_liqrol
			  AND a.n33_fecha_ini  = n33_fecha_ini
			  AND a.n33_fecha_fin  = n33_fecha_fin
			  AND a.n33_cod_trab   = n33_cod_trab
			  AND a.n33_det_tot    = 'DI'
			  AND a.n33_cant_valor = 'V'), 0) -
		NVL((SELECT SUM(a.n33_valor)
			FROM temp_emp a
			WHERE a.n33_compania   = n33_compania
			  AND a.n33_cod_liqrol = n33_cod_liqrol
			  AND a.n33_fecha_ini  = n33_fecha_ini
			  AND a.n33_fecha_fin  = n33_fecha_fin
			  AND a.n33_cod_trab   = n33_cod_trab
			  AND a.n33_det_tot    = 'DE'
			  AND a.n33_cant_valor = 'V'), 0),
		'DO', 1, 'E', '', '', '', 'FOBOS',
		EXTEND(n33_fecha_fin, YEAR TO MONTH)
	FROM t2;
COMMIT WORK;
DROP TABLE t2;
DROP TABLE temp_emp;

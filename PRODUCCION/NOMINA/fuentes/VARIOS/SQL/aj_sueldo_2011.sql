SELECT n30_compania AS cia, n30_cod_trab AS cod_trab, n30_nombres AS empleado,
	((NVL((SELECT n32_sueldo
		FROM rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol  = 'Q2'
		  AND n32_cod_trab    = n30_cod_trab
		  AND n32_ano_proceso = 2011
		  AND n32_mes_proceso = 01), 0) -
	NVL((SELECT n32_sueldo
		FROM rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol  = 'Q1'
		  AND n32_cod_trab    = n30_cod_trab
		  AND n32_ano_proceso = 2011
		  AND n32_mes_proceso = 01), 0)) / 2) AS incremento
	FROM rolt030
	WHERE n30_compania = 1
	  AND n30_estado   = 'A'
	INTO TEMP t1;
DELETE FROM t1 WHERE incremento = 0;
SELECT COUNT(*) tot_emp_inc FROM t1;
SELECT * FROM t1 ORDER BY empleado;
BEGIN WORK;
	UPDATE rolt033
		SET n33_valor = n33_valor +
				(SELECT incremento
					FROM t1
					WHERE cia      = n33_compania
					  AND cod_trab = n33_cod_trab)
		WHERE n33_compania    = 1
		  AND n33_cod_liqrol  = 'Q2'
		  AND n33_fecha_fin   = MDY(01, 31, 2011)
		  AND n33_cod_trab   IN (SELECT cod_trab FROM t1)
		  AND n33_cod_rubro   = 2
		  AND n33_valor       > 0;
	UPDATE rolt032
		SET n32_tot_gan = n32_tot_gan +
				(SELECT incremento
					FROM t1
					WHERE cia      = n32_compania
					  AND cod_trab = n32_cod_trab),
		    n32_tot_ing = n32_tot_ing +
				(SELECT incremento
					FROM t1
					WHERE cia      = n32_compania
					  AND cod_trab = n32_cod_trab)
		WHERE n32_compania    = 1
		  AND n32_cod_liqrol  = 'Q2'
		  AND n32_fecha_fin   = MDY(01, 31, 2011)
		  AND n32_cod_trab   IN (SELECT cod_trab FROM t1);
	UPDATE rolt033
		SET n33_valor = (SELECT n32_tot_gan * 9.35 / 100
					FROM rolt032
					WHERE n32_compania   = n33_compania
					  AND n32_cod_liqrol = n33_cod_liqrol
					  AND n32_fecha_ini  = n33_fecha_ini
					  AND n32_fecha_fin  = n33_fecha_fin
					  AND n32_cod_trab   = n33_cod_trab)
		WHERE n33_compania    = 1
		  AND n33_cod_liqrol  = 'Q2'
		  AND n33_fecha_fin   = MDY(01, 31, 2011)
		  AND n33_cod_trab   IN (SELECT cod_trab FROM t1)
		  AND n33_cod_rubro   = 55
		  AND n33_valor       > 0;
	UPDATE rolt032
		SET n32_tot_egr = (SELECT SUM(n33_valor)
					FROM rolt033
					WHERE n33_compania   = n32_compania
					  AND n33_cod_liqrol = n32_cod_liqrol
					  AND n33_fecha_ini  = n32_fecha_ini
					  AND n33_fecha_fin  = n32_fecha_fin
					  AND n33_cod_trab   = n32_cod_trab
					  AND n33_det_tot    = 'DE'
					  AND n33_valor      > 0)
		WHERE n32_compania    = 1
		  AND n32_cod_liqrol  = 'Q2'
		  AND n32_fecha_fin   = MDY(01, 31, 2011)
		  AND n32_cod_trab   IN (SELECT cod_trab FROM t1);
	UPDATE rolt032
		SET n32_tot_neto = n32_tot_ing - n32_tot_egr
		WHERE n32_compania    = 1
		  AND n32_cod_liqrol  = 'Q2'
		  AND n32_fecha_fin   = MDY(01, 31, 2011)
		  AND n32_cod_trab   IN (SELECT cod_trab FROM t1);
COMMIT WORK;
DROP TABLE t1;

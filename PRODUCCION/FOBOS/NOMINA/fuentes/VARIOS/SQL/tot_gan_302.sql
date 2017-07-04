SELECT * FROM rolt033
	WHERE n33_compania    = 1
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= MDY(01,01,2013)
	  AND n33_fecha_fin  <= MDY(05,31,2013)
	  AND n33_det_tot     = "DI"
	  AND n33_cant_valor  = "V"
	  AND n33_valor       > 0
	INTO TEMP tmp_n33;

SELECT a.n32_ano_proceso anio, a.n32_mes_proceso mes, a.n32_cod_trab,
	CASE WHEN NVL(SUM((SELECT SUM(n33_valor)
			FROM tmp_n33
			WHERE n33_compania   = a.n32_compania
			  AND n33_fecha_ini  = a.n32_fecha_ini
			  AND n33_fecha_fin  = a.n32_fecha_fin
			  AND n33_cod_trab   = a.n32_cod_trab
			  AND n33_cod_rubro  IN
				(SELECT n06_cod_rubro
				FROM rolt006
				WHERE n06_flag_ident IN ("VT", "VV", "OV",
					"VM", "VE", "SX", "SY")))), 0) >=
			NVL(SUM(a.n32_sueldo /
			(SELECT COUNT(*)
				FROM rolt032 b
				WHERE b.n32_compania    = a.n32_compania
				  AND b.n32_ano_proceso = a.n32_ano_proceso
				  AND b.n32_mes_proceso = a.n32_mes_proceso
				  AND b.n32_cod_trab    = a.n32_cod_trab)),0)
		 THEN
			NVL(SUM(a.n32_sueldo /
			(SELECT COUNT(*)
				FROM rolt032 b
				WHERE b.n32_compania    = a.n32_compania
				  AND b.n32_ano_proceso = a.n32_ano_proceso
				  AND b.n32_mes_proceso = a.n32_mes_proceso
				  AND b.n32_cod_trab    = a.n32_cod_trab)),
			0)
		 ELSE
			NVL(SUM((SELECT SUM(n33_valor)
				FROM tmp_n33
				WHERE n33_compania   = a.n32_compania
				  AND n33_fecha_ini  = a.n32_fecha_ini
				  AND n33_fecha_fin  = a.n32_fecha_fin
				  AND n33_cod_trab   = a.n32_cod_trab
				  AND n33_cod_rubro  IN
					(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ("VT", "VV",
					"VM", "OV", "VE", "SX", "SY")))), 0)
		 END AS sueldo,
		NVL(SUM(a.n32_tot_gan), 0) AS tot_gan,
		NVL(SUM(a.n32_tot_ing), 0) tot_ing,
		NVL(SUM(a.n32_tot_egr), 0) tot_egr,
		NVL(SUM(a.n32_tot_neto), 0) tot_net
		 FROM rolt032 a
		 WHERE a.n32_compania  = 1
		   AND a.n32_cod_trab  = 119
		   AND a.n32_estado   <> "E"
and a.n32_ano_proceso = 2013
		 GROUP BY 1, 2, 3
		 INTO TEMP t1;

DROP TABLE tmp_n33;

SELECT anio, mes, SUM(sueldo), SUM(tot_gan), SUM(tot_ing),
			SUM(tot_egr), SUM(tot_net)
		FROM t1
		GROUP BY 1, 2
		ORDER BY 1, 2;

DROP TABLE t1;

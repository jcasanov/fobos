SELECT * FROM rolt033
	WHERE n33_compania    = 1
          AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= "02/01/2010"
	  AND n33_fecha_fin  <= "02/28/2010"
	  AND n33_det_tot     = "DI"
	  AND n33_cant_valor  = "V"
          AND n33_valor       > 0
        INTO TEMP tmp_n33;
SELECT a.n32_ano_proceso AS anio, a.n32_mes_proceso AS mes,
	a.n32_cod_trab AS cod,
	CASE WHEN NVL(SUM((SELECT SUM(n33_valor)
			FROM tmp_n33
			WHERE n33_compania   = a.n32_compania
			  AND n33_fecha_ini  = a.n32_fecha_ini
			  AND n33_fecha_fin  = a.n32_fecha_fin
			  AND n33_cod_trab   = a.n32_cod_trab
		          AND n33_cod_rubro  IN
                		(SELECT n06_cod_rubro
		                        FROM rolt006
        		                WHERE n06_flag_ident IN ("VT", "VV",
						"OV", "VE", "SX")))), 0) >=
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
				  AND b.n32_cod_trab    = a.n32_cod_trab)), 0)
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
						"OV", "VE", "SX")))), 0)
		END AS sueldo,
	(SUM(NVL((SELECT SUM(n33_valor)
			FROM tmp_n33
			WHERE n33_compania    = a.n32_compania
			  AND n33_cod_liqrol  = a.n32_cod_liqrol
			  AND n33_fecha_ini   = a.n32_fecha_ini
			  AND n33_fecha_fin   = a.n32_fecha_fin
			  AND n33_cod_trab    = a.n32_cod_trab
			  AND n33_cod_rubro  IN
				(SELECT n08_rubro_base
				FROM rolt008
				WHERE n08_cod_rubro =
					(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = "AP"))), 0))
	-
	CASE WHEN NVL(SUM((SELECT SUM(n33_valor)
			FROM tmp_n33
			WHERE n33_compania   = a.n32_compania
			  AND n33_fecha_ini  = a.n32_fecha_ini
			  AND n33_fecha_fin  = a.n32_fecha_fin
			  AND n33_cod_trab   = a.n32_cod_trab
		          AND n33_cod_rubro  IN
                		(SELECT n06_cod_rubro
		                        FROM rolt006
        		                WHERE n06_flag_ident IN ("VT", "VV",
						"OV", "VE", "SX")))), 0) >=
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
				  AND b.n32_cod_trab    = a.n32_cod_trab)), 0)
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
						"OV", "VE", "SX")))), 0)
		END) AS val_ext,
	NVL(SUM(a.n32_tot_gan), 0) AS tot_gan,
	NVL(SUM(a.n32_tot_ing), 0) AS tot_ing,
	NVL(SUM(a.n32_tot_egr), 0) AS tot_egr,
	NVL(SUM(a.n32_tot_neto), 0) AS tot_net
	FROM rolt032 a
	WHERE a.n32_compania    = 1
	  AND a.n32_fecha_ini  >= "02/01/2010"
	  AND a.n32_fecha_fin  <= "02/28/2010"
	  AND a.n32_estado     <> "E"
	GROUP BY 1, 2, 3
	INTO TEMP t1;
DROP TABLE tmp_n33;
SELECT anio, mes, SUM(sueldo) tot_sue
	FROM t1
	GROUP BY 1, 2
	ORDER BY 1, 2;
SELECT anio, mes, cod, n30_nombres[1, 20] empleado, ROUND(sueldo, 2) sueldo,
	ROUND(sueldo + val_ext, 2) tot_g, ROUND(tot_gan, 2) tot_gan
	FROM t1, rolt030
	WHERE n30_cod_trab = cod
	INTO TEMP t2;
DROP TABLE t1;
SELECT mes mes2, SUM(sueldo) tot_sue2
	FROM t2
	GROUP BY 1
	ORDER BY 1;
SELECT cod, empleado, tot_g, tot_gan
	FROM t2
	WHERE tot_g <> tot_gan
	ORDER BY 2;
DROP TABLE t2;

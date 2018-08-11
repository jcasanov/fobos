SELECT a.n32_cod_trab AS cod_trab, n30_num_doc_id AS cedula,
	n30_nombres AS empleado, NVL(SUM(a.n32_dias_trab),0) AS dias,
	NVL(CASE WHEN n30_fecha_reing IS NOT NULL
		THEN CASE WHEN EXTEND(n30_fecha_reing, YEAR TO MONTH) =
			EXTEND(MDY(a.n32_mes_proceso, 01, a.n32_ano_proceso),
			YEAR TO MONTH) THEN n30_fecha_reing
			END
		END, NVL(CASE WHEN n30_fecha_ing IS NOT NULL
			THEN CASE WHEN EXTEND(n30_fecha_ing, YEAR TO MONTH) =
			EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso),
				YEAR TO MONTH) THEN n30_fecha_ing
	 END END, CASE WHEN n30_fecha_sal IS NOT NULL THEN
	 CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) =
	 EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso), YEAR TO MONTH)
	 THEN n30_fecha_sal END END )) AS fecha_nov,
	NVL(CASE WHEN n30_fecha_reing IS NOT NULL
		THEN CASE WHEN EXTEND(n30_fecha_reing, YEAR TO MONTH) =
		EXTEND(MDY(a.n32_mes_proceso, 01, a.n32_ano_proceso),
		YEAR TO MONTH)
		THEN (SELECT n22_tipo_arch FROM rolt022
		 WHERE n22_compania    = n30_compania
		   AND n22_codigo_arch = 4) END END,
		 NVL(CASE WHEN n30_fecha_ing IS NOT NULL
		 THEN CASE WHEN EXTEND(n30_fecha_ing, YEAR TO MONTH) =
		 EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso),
		 YEAR TO MONTH) THEN (SELECT n22_tipo_arch FROM rolt022
			WHERE n22_compania    = n30_compania
			   AND n22_codigo_arch = 4) END END,
		 NVL(CASE WHEN n30_fecha_sal IS NOT NULL
		 THEN CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) =
			EXTEND(MDY(a.n32_mes_proceso, 01,a.n32_ano_proceso),
			YEAR TO MONTH) THEN (SELECT n22_tipo_arch
		FROM rolt022 WHERE n22_compania    = n30_compania
		   AND n22_codigo_arch = 5) END END,
		(SELECT UNIQUE n26_tipo_arch FROM rolt026, rolt027
		WHERE n26_compania    = n30_compania   AND n26_codigo_arch = 2
		   AND n26_ano_carga   = a.n32_ano_proceso
		   AND n26_mes_carga   = a.n32_mes_proceso
		   AND n26_estado     <> "E"
		   AND n27_compania    = n26_compania
		   AND n27_ano_proceso = n26_ano_proceso
		   AND n27_mes_proceso = n26_mes_proceso
		   AND n27_codigo_arch = n26_codigo_arch
		   AND n27_tipo_arch   = n26_tipo_arch
		   AND n27_secuencia   = n26_secuencia
		   AND n27_estado     <> "E"
		   AND n27_cod_trab    = n30_cod_trab)))) AS cod_nov,
		 NVL(SUM(a.n32_sueldo / (SELECT COUNT(*) FROM rolt032 b
		 WHERE b.n32_compania    = a.n32_compania
		   AND b.n32_ano_proceso = a.n32_ano_proceso
		   AND b.n32_mes_proceso = a.n32_mes_proceso
		   AND b.n32_cod_trab    = a.n32_cod_trab)),0) AS sueldo,
		SUM(NVL((SELECT SUM(n33_valor) FROM rolt033
		WHERE n33_compania    = a.n32_compania
		   AND n33_cod_liqrol  = a.n32_cod_liqrol
			   AND n33_fecha_ini   = a.n32_fecha_ini
		   AND n33_fecha_fin   = a.n32_fecha_fin
		   AND n33_cod_trab    = a.n32_cod_trab
		   AND n33_cod_rubro  IN (SELECT n06_cod_rubro
			 FROM rolt006 WHERE n06_flag_ident
				 IN ("V5", "V1", "CO", "C1"))
				  AND n33_valor       > 0
			   AND n33_det_tot     = "DI"
			  AND n33_cant_valor  = "V"), 0)) AS valor_ext,
		 SUM(NVL((SELECT SUM(n33_valor) FROM rolt033
			 WHERE n33_compania    = a.n32_compania
			   AND n33_cod_liqrol  = a.n32_cod_liqrol
			   AND n33_fecha_ini   = a.n32_fecha_ini
		   AND n33_fecha_fin   = a.n32_fecha_fin
		   AND n33_cod_trab    = a.n32_cod_trab
		   AND n33_cod_rubro  IN (SELECT n08_rubro_base
		 FROM rolt008 WHERE n08_cod_rubro = 
			(SELECT n06_cod_rubro FROM rolt006
			WHERE n06_flag_ident = "AP"))
		  AND n33_valor       > 0
			   AND n33_det_tot     = "DI"
			  AND n33_cant_valor  = "V"), 0)) AS valor_rol,
		SUM(NVL((SELECT SUM(n33_valor) FROM rolt033
		WHERE n33_compania    = a.n32_compania
		   AND n33_cod_liqrol  = a.n32_cod_liqrol
		   AND n33_fecha_ini   = a.n32_fecha_ini
		   AND n33_fecha_fin   = a.n32_fecha_fin
		   AND n33_cod_trab    = a.n32_cod_trab
		   AND n33_cod_rubro  IN
			(SELECT n06_cod_rubro FROM rolt006
			WHERE n06_flag_ident = "AP")  AND n33_valor       > 0
		   AND n33_det_tot     = "DE"
		  AND n33_cant_valor  = "V"), 0)) AS ap_iess_per,
		 SUM(NVL((SELECT SUM(n33_valor) FROM rolt033
		 WHERE n33_compania    = a.n32_compania 
		  AND n33_cod_liqrol  = a.n32_cod_liqrol
		   AND n33_fecha_ini   = a.n32_fecha_ini
		   AND n33_fecha_fin   = a.n32_fecha_fin
		   AND n33_cod_trab    = a.n32_cod_trab
		   AND n33_cod_rubro  IN (SELECT n08_rubro_base
				 FROM rolt008 WHERE n08_cod_rubro =
			 (SELECT n06_cod_rubro FROM rolt006
			 WHERE n06_flag_ident = "AP"))
		  AND n33_valor       > 0
		   AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"), 0) *
		(SELECT n13_porc_cia / 100 FROM rolt013
		 WHERE n13_cod_seguro = n30_cod_seguro)) AS ap_iess_pat,
		 SUM(NVL((SELECT SUM(n33_valor) FROM rolt033
		 WHERE n33_compania    = a.n32_compania
		   AND n33_cod_liqrol  = a.n32_cod_liqrol
		   AND n33_fecha_ini   = a.n32_fecha_ini
		   AND n33_fecha_fin   = a.n32_fecha_fin
		   AND n33_cod_trab    = a.n32_cod_trab 
		  AND n33_cod_rubro  IN (SELECT n06_cod_rubro FROM rolt006
				 WHERE n06_flag_ident = "AP")
		  AND n33_valor       > 0
		   AND n33_det_tot     = "DE"
		  AND n33_cant_valor  = "V"), 0)) +
		 SUM(NVL((SELECT SUM(n33_valor) FROM rolt033
			 WHERE n33_compania    = a.n32_compania
			   AND n33_cod_liqrol  = a.n32_cod_liqrol
			   AND n33_fecha_ini   = a.n32_fecha_ini
			   AND n33_fecha_fin   = a.n32_fecha_fin
			   AND n33_cod_trab    = a.n32_cod_trab
			   AND n33_cod_rubro  IN
				 (SELECT n08_rubro_base FROM rolt008
				 WHERE n08_cod_rubro =
				 (SELECT n06_cod_rubro FROM rolt006
				 WHERE n06_flag_ident = "AP"))
		  AND n33_valor       > 0
		   AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"), 0) *
		 (SELECT n13_porc_cia / 100 FROM rolt013
		 WHERE n13_cod_seguro = n30_cod_seguro)) AS ap_iess
		  FROM rolt032 a, rolt030
		  WHERE a.n32_compania    =           1
		   AND a.n32_cod_liqrol IN ("Q1", "Q2")
		    AND a.n32_fecha_ini  >= "04/01/2009" 
		  AND a.n32_fecha_fin  <= "04/30/2009"
		   AND a.n32_estado     <> "E"
		    AND n30_compania    = a.n32_compania
		    AND n30_cod_trab    = a.n32_cod_trab
  GROUP BY 1, 2, 3, 5, 6
	order by 3;
  --INTO TEMP tmp_emp;

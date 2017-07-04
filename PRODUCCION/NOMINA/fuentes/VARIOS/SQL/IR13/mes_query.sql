SELECT n30_cod_trab AS CODIGO,
	TRIM(n30_nombres) AS EMPLEADOS,
	ROUND(SUM(NVL((SELECT SUM(n33_valor)
		FROM rolt033
		WHERE n33_compania    = n32_compania
		  AND n33_cod_liqrol  = n32_cod_liqrol
		  AND n33_fecha_ini  >= n32_fecha_ini
		  AND n33_fecha_fin  <= n32_fecha_fin
		  AND n33_cod_trab    = n32_cod_trab
		  AND n33_cod_rubro  IN
			(SELECT n08_rubro_base
				FROM rolt008, rolt006
				WHERE n06_cod_rubro  = n08_cod_rubro
				  AND n06_flag_ident = "AP")
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"), 0.00)), 2) AS TOTAL_GAN_NOM,
	ROUND(SUM(NVL((SELECT SUM(n33_valor)
		FROM rolt033
		WHERE n33_compania    = n32_compania
		  AND n33_cod_liqrol  = n32_cod_liqrol
		  AND n33_fecha_ini  >= n32_fecha_ini
		  AND n33_fecha_fin  <= n32_fecha_fin
		  AND n33_cod_trab    = n32_cod_trab
		  AND n33_cod_rubro  IN
			(SELECT n06_cod_rubro
				FROM rolt006
				WHERE n06_flag_ident = "AP")
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DE"
		  AND n33_cant_valor  = "V"), 0.00)), 2) AS APORTES_IESS,
	ROUND(SUM(NVL((SELECT SUM(n33_valor)
		FROM rolt033
		WHERE n33_compania    = n32_compania
		  AND n33_cod_liqrol  = n32_cod_liqrol
		  AND n33_fecha_ini  >= n32_fecha_ini
		  AND n33_fecha_fin  <= n32_fecha_fin
		  AND n33_cod_trab    = n32_cod_trab
		  AND n33_cod_rubro  IN
			(SELECT n08_rubro_base
				FROM rolt008, rolt006
				WHERE n06_cod_rubro  = n08_cod_rubro
				  AND n06_flag_ident = "AP")
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"), 0.00)) -
	SUM(NVL((SELECT SUM(n33_valor)
		FROM rolt033
		WHERE n33_compania    = n32_compania
		  AND n33_cod_liqrol  = n32_cod_liqrol
		  AND n33_fecha_ini  >= n32_fecha_ini
		  AND n33_fecha_fin  <= n32_fecha_fin
		  AND n33_cod_trab    = n32_cod_trab
		  AND n33_cod_rubro  IN
			(SELECT n06_cod_rubro
				FROM rolt006
				WHERE n06_flag_ident = "AP")
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DE"
		  AND n33_cant_valor  = "V"), 0.00)), 2) AS TOTAL_NOMINA,
	ROUND((NVL(CASE WHEN n30_estado = "A" THEN
			(SELECT SUM(b13_valor_base)
			FROM rolt056, ctbt012, ctbt013
			WHERE n56_compania    = n32_compania
			  AND n56_proceso     = 'AN'
			  AND n56_cod_trab    = n32_cod_trab
			  AND n56_cod_depto   = n32_cod_depto
			  AND b12_compania    = n56_compania
			  AND b12_estado     <> 'E'
			  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) =
				EXTEND(MDY(n32_mes_proceso, 01,
						n32_ano_proceso), YEAR TO MONTH)
			  AND b13_compania    = b12_compania
			  AND b13_tipo_comp   = b12_tipo_comp
			  AND b13_num_comp    = b12_num_comp
			  AND b13_valor_base  > 0
			  AND b13_cuenta      = '51030701'
						|| n56_aux_val_vac[9, 12])
			ELSE
			(SELECT SUM(b13_valor_base)
			FROM rolt056, ctbt012, ctbt013
			WHERE n56_compania    = n32_compania
			  AND n56_proceso     = 'AN'
			  AND n56_cod_trab    = n32_cod_trab
			  AND n56_cod_depto   = n32_cod_depto
			  AND b12_compania    = n56_compania
			  AND b12_estado     <> 'E'
			  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) =
				EXTEND(n30_fecha_sal, YEAR TO MONTH)
			  AND b13_compania    = b12_compania
			  AND b13_tipo_comp   = b12_tipo_comp
			  AND b13_num_comp    = b12_num_comp
			  AND b13_valor_base  > 0
			  AND b13_cuenta      = '51030701'
						|| n56_aux_val_vac[9, 12])
		END,
		NVL((SELECT SUM(n33_valor)
		FROM rolt033
		WHERE n33_compania    = n32_compania
		  AND n33_cod_liqrol  = n32_cod_liqrol
		  AND n33_fecha_ini  >= n32_fecha_ini
		  AND n33_fecha_fin  <= n32_fecha_fin
		  AND n33_cod_trab    = n32_cod_trab
		  AND n33_cod_rubro  IN
				(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = 'BO')
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"
		  AND NOT EXISTS
			(SELECT 1
				FROM rolt008, rolt006
				WHERE n08_rubro_base = n33_cod_rubro
				  AND n06_cod_rubro  = n08_cod_rubro
				  AND n06_flag_ident = "AP")),
			0.00))), 2) AS BONIFICACION,
	0.00 AS OTRAS_BONIFIC,
	ROUND((NVL(CASE WHEN n30_estado = "A" THEN
			(SELECT SUM(b13_valor_base)
			FROM rolt056, ctbt012, ctbt013
			WHERE n56_compania    = n32_compania
			  AND n56_proceso     = 'AN'
			  AND n56_cod_trab    = n32_cod_trab
			  AND n56_cod_depto   = n32_cod_depto
			  AND b12_compania    = n56_compania
			  AND b12_estado     <> 'E'
			  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) =
				EXTEND(MDY(n32_mes_proceso, 01,
						n32_ano_proceso), YEAR TO MONTH)
			  AND b13_compania    = b12_compania
			  AND b13_tipo_comp   = b12_tipo_comp
			  AND b13_num_comp    = b12_num_comp
			  AND b13_valor_base  > 0
			  AND b13_cuenta      = '51030702'
					|| n56_aux_val_vac[9, 12])
			ELSE
			(SELECT SUM(b13_valor_base)
			FROM rolt056, ctbt012, ctbt013
			WHERE n56_compania    = n32_compania
			  AND n56_proceso     = 'AN'
			  AND n56_cod_trab    = n32_cod_trab
			  AND n56_cod_depto   = n32_cod_depto
			  AND b12_compania    = n56_compania
			  AND b12_estado     <> 'E'
			  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) =
				EXTEND(n30_fecha_sal, YEAR TO MONTH)
			  AND b13_compania    = b12_compania
			  AND b13_tipo_comp   = b12_tipo_comp
			  AND b13_num_comp    = b12_num_comp
			  AND b13_valor_base  > 0
			  AND b13_cuenta      = '51030702'
					|| n56_aux_val_vac[9, 12])
		END,
		NVL((SELECT SUM(n33_valor)
		FROM rolt033
		WHERE n33_compania    = n32_compania
		  AND n33_cod_liqrol  = n32_cod_liqrol
		  AND n33_fecha_ini  >= n32_fecha_ini
		  AND n33_fecha_fin  <= n32_fecha_fin
		  AND n33_cod_trab    = n32_cod_trab
		  AND n33_cod_rubro  NOT IN
				(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ('SI', 'DI',
							'AG', 'IV', 'OI', 'BO',
							'FM', 'E1')
					   OR n06_cod_rubro  IN (35, 38, 39))
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"
		  AND NOT EXISTS
			(SELECT 1
				FROM rolt008, rolt006
				WHERE n08_rubro_base = n33_cod_rubro
				  AND n06_cod_rubro  = n08_cod_rubro
				  AND n06_flag_ident = "AP")),
			0.00))), 2) AS OTROS_VAL_NOM,
	CASE WHEN n30_estado = "A"
		THEN NVL((SELECT SUM(b13_valor_base)
			FROM rolt039, rolt057, ctbt012, ctbt013
			WHERE n39_compania      = n32_compania
			  AND n39_proceso      IN ("VA", "VP")
			  AND EXTEND(n39_fecing, YEAR TO MONTH) =
				EXTEND(MDY(n32_mes_proceso, 01,
						n32_ano_proceso), YEAR TO MONTH)
			  AND n39_cod_trab      = n32_cod_trab
			  AND n57_compania      = n39_compania
			  AND n57_proceso       = n39_proceso
			  AND n57_cod_trab      = n39_cod_trab
			  AND n57_periodo_ini   = n39_periodo_ini
			  AND n57_periodo_fin   = n39_periodo_fin
			  AND b12_compania      = n57_compania
			  AND b12_tipo_comp     = n57_tipo_comp
			  AND b12_num_comp      = n57_num_comp
			  AND b12_estado       <> "E"
			  AND b13_compania      = b12_compania
			  AND b13_tipo_comp     = b12_tipo_comp
			  AND b13_num_comp      = b12_num_comp
			  AND b13_cuenta       MATCHES "5101020*"
			  AND b13_valor_base    > 0), 0.00)
		ELSE NVL((SELECT SUM((n39_valor_vaca + n39_valor_adic)
					- n39_descto_iess)
			FROM rolt039
			WHERE n39_compania      = n30_compania
			  AND n39_proceso      IN ("VA", "VP")
			  AND n39_cod_trab      = n30_cod_trab
			  AND EXTEND(n39_fecing, YEAR TO MONTH) =
				EXTEND(MDY(n32_mes_proceso, 01,
					n32_ano_proceso), YEAR TO MONTH)), 0.00)
	END AS NETO_VACACIONES,
	CASE WHEN n32_mes_proceso = 04 THEN
			NVL((SELECT n42_val_trabaj + n42_val_cargas
				FROM rolt041, rolt042
				WHERE n41_compania = n30_compania
				  AND n41_ano      = (n32_ano_proceso - 1)
				  AND n41_estado   = "P"
				  AND n42_compania = n41_compania
				  AND n42_proceso  = "UT"
				  AND n42_ano      = n41_ano
				  AND n42_cod_trab = n30_cod_trab), 0.00)
		ELSE 0.00
	END AS UTILIDADES
	FROM rolt032, rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  = 2013
	  AND n32_mes_proceso  = 01
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	GROUP BY 1, 2, 6, 7, 8, 9, 10
UNION
SELECT n42_cod_trab AS CODIGO, TRIM(n30_nombres) AS EMPLEADOS,
	0.00 AS TOTAL_GAN_NOM, 0.00 AS APORTES_IESS, 0.00 AS TOTAL_NOMINA,
	0.00 AS BONIFICACION, 0.00 AS OTRAS_BONIFIC, 0.00 AS OTROS_VAL_NOM,
	0.00 AS NETO_VACACIONES,
	NVL(n42_val_trabaj + n42_val_cargas, 0.00) AS UTILIDADES
	FROM rolt041, rolt042, rolt030
	WHERE n41_compania        = 1
	  1ND n41_ano             = 2012
	  AND n41_estado          = "P"
	  AND n42_compania        = n41_compania
	  AND n42_proceso         = "UT"
	  AND n42_ano             = n41_ano
	  AND n30_compania        = n42_compania
	  AND n30_cod_trab        = n42_cod_trab
	  AND n30_estado          = 'I'
	  AND YEAR(n30_fecha_sal) BETWEEN n42_ano AND n42_ano + 1
	ORDER BY 2;
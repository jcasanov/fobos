
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

{--
SELECT EXTEND(b12_fec_proceso, YEAR TO MONTH) AS fecha,
	n30_cod_trab codigo, b13_cuenta[1, 8] cta1,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM rolt030, rolt056, ctbt012, ctbt013
	WHERE n30_compania           = 1
	  AND n30_estado             = 'A'
	  AND n56_compania           = n30_compania
	  AND n56_proceso            = 'AN'
	  AND n56_cod_trab           = n30_cod_trab
	  AND n56_cod_depto          = n30_cod_depto
	  AND b12_compania           = n56_compania
	  AND b12_estado            <> 'E'
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta             = '51030701' || n56_aux_val_vac[9, 12]
	GROUP BY 1, 2, 3
UNION
SELECT EXTEND(b12_fec_proceso, YEAR TO MONTH) AS fecha,
	n30_cod_trab codigo, b13_cuenta[1, 8] cta1,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM rolt030, rolt056, ctbt012, ctbt013
	WHERE n30_compania           = 1
	  AND n30_estado             = 'I'
	  AND YEAR(n30_fecha_sal)    = 2012
	  AND n56_compania           = n30_compania
	  AND n56_proceso            = 'AN'
	  AND n56_cod_trab           = n30_cod_trab
	  AND n56_cod_depto          = n30_cod_depto
	  AND b12_compania           = n56_compania
	  AND b12_estado            <> 'E'
	  AND YEAR(b12_fec_proceso)  = YEAR(n30_fecha_sal)
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta             = '51030701' || n56_aux_val_vac[9, 12]
	GROUP BY 1, 2, 3
UNION
SELECT EXTEND(b12_fec_proceso, YEAR TO MONTH) AS fecha,
	n30_cod_trab codigo, b13_cuenta[1, 8] cta1,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM rolt030, rolt056, ctbt012, ctbt013
	WHERE n30_compania           = 1
	  AND n30_estado             = 'A'
	  AND n56_compania           = n30_compania
	  AND n56_proceso            = 'AN'
	  AND n56_cod_trab           = n30_cod_trab
	  AND n56_cod_depto          = n30_cod_depto
	  AND b12_compania           = n56_compania
	  AND b12_estado            <> 'E'
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta             = '51030702' || n56_aux_val_vac[9, 12]
	GROUP BY 1, 2, 3
UNION
SELECT EXTEND(b12_fec_proceso, YEAR TO MONTH) AS fecha,
	n30_cod_trab codigo, b13_cuenta[1, 8] cta1,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM rolt030, rolt056, ctbt012, ctbt013
	WHERE n30_compania           = 1
	  AND n30_estado             = 'I'
	  AND YEAR(n30_fecha_sal)    = 2012
	  AND n56_compania           = n30_compania
	  AND n56_proceso            = 'AN'
	  AND n56_cod_trab           = n30_cod_trab
	  AND n56_cod_depto          = n30_cod_depto
	  AND b12_compania           = n56_compania
	  AND b12_estado            <> 'E'
	  AND YEAR(b12_fec_proceso)  = YEAR(n30_fecha_sal)
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta             = '51030702' || n56_aux_val_vac[9, 12]
	GROUP BY 1, 2, 3
	ORDER BY 1, 2, 3;
--}

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

{--
SELECT EXTEND(n39_fecing, YEAR TO MONTH) AS fecha,
	n30_cod_trab AS codigo,
	CASE WHEN n30_estado = 'A' THEN 'A' ELSE 'I' END AS est,
	NVL(SUM(b13_valor_base), 0) AS net_vac
	FROM rolt030, rolt039, rolt057, ctbt012, ctbt013
	WHERE n30_compania      = 1
	  AND n30_estado        = 'A'
	  AND n39_compania      = n30_compania
	  AND n39_proceso      IN ("VA", "VP")
	  AND YEAR(n39_fecing)  = 2012
	  AND n39_cod_trab      = n30_cod_trab
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
	  AND b13_valor_base    > 0
	GROUP BY 1, 2, 3
UNION
SELECT EXTEND(n39_fecing, YEAR TO MONTH) AS fecha,
	n30_cod_trab AS codigo,
	CASE WHEN n30_estado = 'A' THEN 'A' ELSE 'I' END AS est,
	NVL(SUM((n39_valor_vaca + n39_valor_adic)
		- n39_descto_iess), 0) AS net_vac
	FROM rolt030, rolt039
	WHERE n30_compania        = 1
	  AND n30_estado          = 'I'
	  AND YEAR(n30_fecha_sal) = 2012
	  AND n39_compania        = n30_compania
	  AND n39_proceso        IN ("VA", "VP")
	  AND n39_cod_trab        = n30_cod_trab
	  AND YEAR(n39_fecing)    = 2012
	GROUP BY 1, 2, 3
	ORDER BY 1, 2;
--}

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
------------------ UNICO SELECT DEL EXCEL: VALORES GANADO 2012 -----------------
--------------------------------------------------------------------------------

SELECT EXTEND(MDY(n32_mes_proceso,01,n32_ano_proceso),YEAR TO MONTH) AS fecha,
	n30_cod_trab AS codigo, n30_num_doc_id AS cedula,
	TRIM(n30_nombres) AS empleados,
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
				WHERE n06_flag_ident IN ("VT", "VE", "VM",
							"VV", "OV", "SX"))
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"), 0.00)), 2) AS sueldos,
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
				WHERE n06_flag_ident IN ("V5", "V1", "CO",
							"C1", "C2", "C3"))
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"), 0.00)), 2) AS sobresueldos,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = "DT"
		  AND n36_ano_proceso = n32_ano_proceso
		  AND n36_mes_proceso = n32_mes_proceso
		  AND n36_cod_trab    = n30_cod_trab
		  AND n36_estado      = "P"), 0.00) AS val_13ro,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = "DC"
		  AND n36_ano_proceso = n32_ano_proceso
		  AND n36_mes_proceso = n32_mes_proceso
		  AND n36_cod_trab    = n30_cod_trab
		  AND n36_estado      = "P"), 0.00) AS val_14to,
	NVL((SELECT SUM(n38_valor_fondo)
		FROM rolt038
		WHERE n38_compania        = n30_compania
		  AND EXTEND(n38_fecha_fin, YEAR TO MONTH) =
			EXTEND(MDY(n32_mes_proceso, 01, n32_ano_proceso),
				YEAR TO MONTH)
		  AND n38_cod_trab        = n30_cod_trab
		  AND n38_estado          = "P"), 0.00) AS fondo_reserva,
	CASE WHEN n32_mes_proceso = 4 THEN
			NVL((SELECT n42_val_trabaj + n42_val_cargas
				FROM rolt041, rolt042
				WHERE n41_compania = n30_compania
				  AND n41_ano      = 2011
				  AND n41_estado   = "P"
				  AND n42_compania = n41_compania
				  AND n42_proceso  = "UT"
				  AND n42_ano      = n41_ano
				  AND n42_cod_trab = n30_cod_trab), 0.00)
		ELSE 0.00
	END AS utilidades,
	CASE WHEN n30_estado = "A"
		THEN NVL((SELECT SUM(b13_valor_base)
			FROM rolt039, rolt057, ctbt012, ctbt013
			WHERE n39_compania      = n30_compania
			  AND n39_proceso      IN ("VA", "VP")
			  AND YEAR(n39_fecing)  = n32_ano_proceso
			  AND n39_cod_trab      = n30_cod_trab
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
		ELSE 0.00
	END AS net_vac,
	ROUND(SUM(NVL(CASE WHEN n30_estado = "A" THEN
			(SELECT SUM(b13_valor_base)
			FROM rolt056, ctbt012, ctbt013
			WHERE n56_compania           = n30_compania
			  AND n56_proceso            = 'AN'
			  AND n56_cod_trab           = n30_cod_trab
			  AND n56_cod_depto          = n30_cod_depto
			  AND b12_compania           = n56_compania
			  AND b12_estado            <> 'E'
			  AND YEAR(b12_fec_proceso)  = n32_ano_proceso
			  AND b13_compania           = b12_compania
			  AND b13_tipo_comp          = b12_tipo_comp
			  AND b13_num_comp           = b12_num_comp
			  AND b13_valor_base         > 0
			  AND b13_cuenta             = '51030701'
						|| n56_aux_val_vac[9, 12])
			ELSE
			(SELECT SUM(b13_valor_base)
			FROM rolt056, ctbt012, ctbt013
			WHERE n56_compania           = n30_compania
			  AND n56_proceso            = 'AN'
			  AND n56_cod_trab           = n30_cod_trab
			  AND n56_cod_depto          = n30_cod_depto
			  AND b12_compania           = n56_compania
			  AND b12_estado            <> 'E'
			  AND YEAR(b12_fec_proceso)  = YEAR(n30_fecha_sal)
			  AND b13_compania           = b12_compania
			  AND b13_tipo_comp          = b12_tipo_comp
			  AND b13_num_comp           = b12_num_comp
			  AND b13_valor_base         > 0
			  AND b13_cuenta             = '51030701'
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
			0.00))), 2) AS bonif,
	ROUND(SUM(NVL(CASE WHEN n30_estado = "A" THEN
			(SELECT SUM(b13_valor_base)
			FROM rolt056, ctbt012, ctbt013
			WHERE n56_compania           = n30_compania
			  AND n56_proceso            = 'AN'
			  AND n56_cod_trab           = n30_cod_trab
			  AND n56_cod_depto          = n30_cod_depto
			  AND b12_compania           = n56_compania
			  AND b12_estado            <> 'E'
			  AND YEAR(b12_fec_proceso)  = n32_ano_proceso
			  AND b13_compania           = b12_compania
			  AND b13_tipo_comp          = b12_tipo_comp
			  AND b13_num_comp           = b12_num_comp
			  AND b13_valor_base         > 0
			  AND b13_cuenta             = '51030702'
					|| n56_aux_val_vac[9, 12])
			ELSE
			(SELECT SUM(b13_valor_base)
			FROM rolt056, ctbt012, ctbt013
			WHERE n56_compania           = n30_compania
			  AND n56_proceso            = 'AN'
			  AND n56_cod_trab           = n30_cod_trab
			  AND n56_cod_depto          = n30_cod_depto
			  AND b12_compania           = n56_compania
			  AND b12_estado            <> 'E'
			  AND YEAR(b12_fec_proceso)  = YEAR(n30_fecha_sal)
			  AND b13_compania           = b12_compania
			  AND b13_tipo_comp          = b12_tipo_comp
			  AND b13_num_comp           = b12_num_comp
			  AND b13_valor_base         > 0
			  AND b13_cuenta             = '51030702'
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
			0.00))), 2) AS otros,
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
		  AND n33_cant_valor  = "V"), 0.00)), 2) AS val_ap
	FROM rolt032, rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  = 2012
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	GROUP BY 1, 2, 3, 4, 7, 8, 9, 10, 11
UNION
SELECT EXTEND(n41_fecing, YEAR TO MONTH) AS fecha, n42_cod_trab AS codigo,
	n30_num_doc_id AS cedula, TRIM(n30_nombres) AS empleados,
	0.00 AS sueldos, 0.00 AS sobresueldos, 0.00 AS val_13ro,
	0.00 AS val_14to, 0.00 AS fondo_reserva,
	NVL(n42_val_trabaj + n42_val_cargas, 0.00) AS utilidades,
	CASE WHEN n30_estado = "A"
		THEN 0.00
		ELSE NVL((SELECT SUM((n39_valor_vaca + n39_valor_adic)
					- n39_descto_iess)
			FROM rolt039
			WHERE n39_compania      = n30_compania
			  AND n39_proceso      IN ("VA", "VP")
			  AND n39_cod_trab      = n30_cod_trab
			  AND YEAR(n39_fecing)  = YEAR(n30_fecha_sal)), 0.00)
	END AS net_vac,
	0.00 AS bonif, 0.00 AS otros, 0.00 AS val_ap
	FROM rolt041, rolt042, rolt030
	WHERE n41_compania        = 1
	  AND n41_ano             = 2011
	  AND n41_estado          = "P"
	  AND n42_compania        = n41_compania
	  AND n42_proceso         = "UT"
	  AND n42_ano             = n41_ano
	  AND n30_compania        = n42_compania
	  AND n30_cod_trab        = n42_cod_trab
	  AND n30_estado          = 'I'
	  AND YEAR(n30_fecha_sal) = n42_ano
	ORDER BY 1, 4;

--------------------------------------------------------------------------------

SELECT MDY(mes_p, DAY(MDY(mes_p, 01, anio_p) + 1 UNITS MONTH - 1 UNITS DAY),
	anio_p) fecha
	FROM dual
	INTO TEMP fec_act;

{--
SELECT MDY(03, DAY(MDY(03, 01, 2013) + 1 UNITS MONTH - 1 UNITS DAY),
	2013) fecha
	FROM dual
	INTO TEMP fec_act;
--}

SELECT UNIQUE n30_compania, n30_cod_trab, n30_nombres, n30_estado,
	n30_cod_depto, n30_fecha_sal, n13_porc_trab, "N" mes_ut
	FROM rolt032, rolt030, rolt013
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ('Q1', 'Q2')
	  AND n32_ano_proceso  = YEAR((SELECT * FROM fec_act))
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	  AND n13_cod_seguro   = n30_cod_seguro
UNION
	SELECT UNIQUE n30_compania, n30_cod_trab, n30_nombres, n30_estado,
		n30_cod_depto, n30_fecha_sal, n13_porc_trab, "N" mes_ut
		FROM rolt042, rolt041, rolt030, rolt013
		WHERE n42_compania       = 1
		  AND n42_proceso        = 'UT'
		  AND n42_ano            = YEAR((SELECT * FROM fec_act)) - 1
		  AND n41_compania       = n42_compania
		  AND n41_proceso        = n42_proceso
		  AND n41_ano            = n42_ano
		  AND n30_compania       = n42_compania
		  AND n30_cod_trab       = n42_cod_trab
		  AND n13_cod_seguro     = n30_cod_seguro
	INTO TEMP tmp_n30;

UPDATE tmp_n30
	SET mes_ut = 'S'
	WHERE (MONTH((SELECT * FROM fec_act)) = 4
	   OR  MONTH((SELECT * FROM fec_act)) = 12);

SELECT COUNT(*) tot_emp_n30 FROM tmp_n30;

SELECT n30_cod_trab cod1, b13_cuenta[1, 8] cta1,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n30_estado           = 'A'
	  AND n56_compania         = n30_compania
	  AND n56_proceso          = 'AN'
	  AND n56_cod_trab         = n30_cod_trab
	  AND n56_cod_depto        = n30_cod_depto
	  AND b12_compania         = n56_compania
	  AND b12_estado          <> 'E'
	  AND b12_fec_proceso     >=
		(SELECT MDY(01, 01, YEAR(fecha)) FROM fec_act)
	  AND b12_fec_proceso     <= (SELECT * FROM fec_act)
	  AND b13_compania         = b12_compania
	  AND b13_tipo_comp        = b12_tipo_comp
	  AND b13_num_comp         = b12_num_comp
	  AND b13_valor_base       > 0
	  AND b13_cuenta           = '51030701' || n56_aux_val_vac[9, 12]
	GROUP BY 1, 2
UNION
SELECT n30_cod_trab cod1, b13_cuenta[1, 8] cta1,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal)  = YEAR((SELECT * FROM fec_act))
	  AND n56_compania         = n30_compania
	  AND n56_proceso          = 'AN'
	  AND n56_cod_trab         = n30_cod_trab
	  AND n56_cod_depto        = n30_cod_depto
	  AND b12_compania         = n56_compania
	  AND b12_estado          <> 'E'
	  AND b12_fec_proceso     >=
			(SELECT MDY(01, 01, YEAR(fecha)) FROM fec_act)
	  AND b12_fec_proceso     <= (SELECT * FROM fec_act)
	  AND b13_compania         = b12_compania
	  AND b13_tipo_comp        = b12_tipo_comp
	  AND b13_num_comp         = b12_num_comp
	  AND b13_valor_base       > 0
	  AND b13_cuenta           = '51030701' || n56_aux_val_vac[9, 12]
	GROUP BY 1, 2
UNION
SELECT n30_cod_trab cod1, b13_cuenta[1, 8] cta1,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n30_estado           = 'A'
	  AND n56_compania         = n30_compania
	  AND n56_proceso          = 'AN'
	  AND n56_cod_trab         = n30_cod_trab
	  AND n56_cod_depto        = n30_cod_depto
	  AND b12_compania         = n56_compania
	  AND b12_estado          <> 'E'
	  AND b12_fec_proceso     >=
			(SELECT MDY(01, 01, YEAR(fecha)) FROM fec_act)
	  AND b12_fec_proceso     <= (SELECT * FROM fec_act)
	  AND b13_compania         = b12_compania
	  AND b13_tipo_comp        = b12_tipo_comp
	  AND b13_num_comp         = b12_num_comp
	  AND b13_valor_base       > 0
	  AND b13_cuenta           = '51030702' || n56_aux_val_vac[9, 12]
	GROUP BY 1, 2
UNION
SELECT n30_cod_trab cod1, b13_cuenta[1, 8] cta1,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal)  = YEAR((SELECT * FROM fec_act))
	  AND n56_compania         = n30_compania
	  AND n56_proceso          = 'AN'
	  AND n56_cod_trab         = n30_cod_trab
	  AND n56_cod_depto        = n30_cod_depto
	  AND b12_compania         = n56_compania
	  AND b12_estado          <> 'E'
	  AND b12_fec_proceso     >=
			(SELECT MDY(01, 01, YEAR(fecha)) FROM fec_act)
	  AND b12_fec_proceso     <= (SELECT * FROM fec_act)
	  AND b13_compania         = b12_compania
	  AND b13_tipo_comp        = b12_tipo_comp
	  AND b13_num_comp         = b12_num_comp
	  AND b13_valor_base       > 0
	  AND b13_cuenta           = '51030702' || n56_aux_val_vac[9, 12]
	GROUP BY 1, 2
	INTO TEMP tmp_ctb;

SELECT n30_cod_trab codv, NVL(SUM(b13_valor_base), 0) net_vac
	FROM tmp_n30, rolt039, rolt057, ctbt012, ctbt013
	WHERE n30_estado        = 'A'
	  AND n39_compania      = n30_compania
	  AND n39_proceso      IN ("VA", "VP")
	  AND DATE(n39_fecing) >=
			(SELECT MDY(01, 01, YEAR(fecha)) FROM fec_act)
	  AND DATE(n39_fecing) <= (SELECT * FROM fec_act)
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
	GROUP BY 1
UNION
SELECT n30_cod_trab codv, NVL(SUM((n39_valor_vaca + n39_valor_adic)
		- n39_descto_iess), 0) net_vac
	FROM tmp_n30, rolt039
	WHERE n30_estado        = 'I'
	  AND n39_compania      = n30_compania
	  AND n39_proceso      IN ("VA", "VP")
	  AND n39_cod_trab      = n30_cod_trab
	  AND DATE(n39_fecing) >=
			(SELECT MDY(01, 01, YEAR(fecha)) FROM fec_act)
	  AND DATE(n39_fecing) <= (SELECT * FROM fec_act)
	GROUP BY 1
	INTO TEMP tmp_vac;

SELECT LPAD(n30_cod_trab, 3, 0) cod, TRIM(n30_nombres) empleado,
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
		  AND n33_cant_valor  = "V"), 0.00)), 2) tot_gan,
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
		  AND n33_cant_valor  = "V"), 0.00)), 2) val_ap,
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
		  AND n33_cant_valor  = "V"), 0.00)), 2) val_nom,
	ROUND(NVL(NVL((SELECT SUM(val_ctb)
			FROM tmp_ctb
			WHERE cod1 = n32_cod_trab
			  AND cta1 = '51030701'),
		(SELECT SUM(n33_valor)
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
				  AND n06_flag_ident = "AP"))), 0.00), 2) bonif,
	ROUND(NVL(NVL((SELECT SUM(val_ctb)
			FROM tmp_ctb
			WHERE cod1 = n32_cod_trab
			  AND cta1 = '51030702'),
		(SELECT SUM(n33_valor)
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
				  AND n06_flag_ident = "AP"))), 0.00), 2) otros,
	NVL((SELECT net_vac
		FROM tmp_vac
		WHERE codv = n30_cod_trab), 0.00) net_vac,
	NVL(CASE WHEN MONTH(n32_fecha_ini) = 4 THEN
		(SELECT n42_val_trabaj + n42_val_cargas
			FROM rolt041, rolt042
			WHERE n41_compania      = n30_compania
			  AND n41_ano           = YEAR((SELECT * FROM fec_act))
						- 1
			  AND n41_estado        = "P"
			  AND n42_compania      = n41_compania
			  AND n42_proceso       = 'UT'
			  AND n42_ano           = n41_ano
			  AND n42_cod_trab      = n30_cod_trab)
		 WHEN n32_fecha_ini IS NULL AND mes_ut = "S" THEN
		(SELECT n42_val_trabaj + n42_val_cargas
			FROM rolt041, rolt042
			WHERE n41_compania      = n30_compania
			  AND n41_ano           = YEAR((SELECT * FROM fec_act))
						- 1
			  AND n41_estado        = "P"
			  AND n42_compania      = n41_compania
			  AND n42_proceso       = 'UT'
			  AND n42_ano           = n41_ano
			  AND n42_cod_trab      = n30_cod_trab)
		END, 0.00) val_ut
	FROM tmp_n30, OUTER rolt032
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= (SELECT MDY(01, 01, YEAR(fecha)) FROM fec_act)
	  AND n32_fecha_fin  <= (SELECT * FROM fec_act)
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
	GROUP BY 1, 2, 6, 7, 8, 9
	INTO TEMP t1;

DROP TABLE tmp_n30;
DROP TABLE tmp_ctb;
DROP TABLE tmp_vac;

DELETE FROM t1
	WHERE tot_gan = 0
	  AND val_ap  = 0
	  AND val_nom = 0
	  AND bonif   = 0
	  AND otros   = 0
	  AND net_vac = 0
	  AND val_ut  = 0
	  AND MONTH((SELECT * FROM fec_act)) <> 12;

SELECT COUNT(*) tot_emp FROM t1;

SELECT cod, empleado, SUM(tot_gan) tot_gan, SUM(val_ap) val_ap,
	SUM(val_nom) val_nom, SUM(bonif) bonif, SUM(otros) otros,
	SUM(net_vac) net_vac, SUM(val_ut) val_ut
	FROM t1
	GROUP BY 1, 2
	INTO TEMP t2;

DROP TABLE t1;

UNLOAD TO "proy_ir_mes_lanio_p.unl"
	SELECT cod, empleado,
		ROUND(tot_gan * (SELECT (12 - MONTH(fecha)) + 1 FROM fec_act),
			2) tot_gan,
		ROUND(val_ap * (SELECT (12 - MONTH(fecha)) + 1 FROM fec_act),
			2) val_ap,
		ROUND(val_nom * (SELECT (12 - MONTH(fecha)) + 1 FROM fec_act),
			2) val_nom,
		bonif, 0.00 ot_bon,
		ROUND(otros * (SELECT (12 - MONTH(fecha)) + 1 FROM fec_act),
			2) otros,
		net_vac, val_ut
		FROM t2
		ORDER BY 2;

DROP TABLE fec_act;

DROP TABLE t2;

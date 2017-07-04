SELECT MDY(12, DAY(MDY(12, 01, 2011) + 1 UNITS MONTH - 1 UNITS DAY), 2011) fecha
	FROM dual
	INTO TEMP fec_act;

SELECT CASE WHEN n30_tipo_doc_id = "P"
		THEN "3"
		ELSE "2"
	END tipo_ane,
	n30_num_doc_id cedula,
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
		REPLACE(REPLACE(n30_domicilio[1, 20], "ñ", "N"),
			"Ñ", "N"), "/", ""), "-", " "), ",", ""),
			":", ""), "#", "No.") direccion,
	"10901" ciudad, "109" prov,
	CASE WHEN n30_telef_domic IS NOT NULL AND LENGTH(n30_telef_domic) = 9
		THEN LPAD(n30_telef_domic, 9, 0)
		ELSE "042683060"
	END telefono,
	1 sist_net,
	n30_compania, n30_cod_trab, n30_nombres, n30_estado,
	n30_cod_depto, NVL(n30_fecha_reing, n30_fecha_ing) n30_fecha_ing,
	n30_fecha_sal, n30_tipo_trab
	FROM rolt032, rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ('Q1', 'Q2')
	  AND n32_ano_proceso  = YEAR((SELECT * FROM fec_act))
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
UNION
	SELECT CASE WHEN n30_tipo_doc_id = "P"
			THEN "3"
			ELSE "2"
		END tipo_ane,
		n30_num_doc_id cedula,
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
			REPLACE(REPLACE(n30_domicilio[1, 20],"ñ", "N"),
				"Ñ", "N"), "/", ""), "-", " "), ",", ""),
				":", ""), "#", "No.") direccion,
		"10901" ciudad, "109" prov,
		CASE WHEN n30_telef_domic IS NOT NULL AND
				LENGTH(n30_telef_domic) = 9
			THEN LPAD(n30_telef_domic, 9, 0)
			ELSE "042683060"
		END telefono,
		1 sist_net,
		n30_compania, n30_cod_trab, n30_nombres, n30_estado,
		n30_cod_depto, NVL(n30_fecha_reing,n30_fecha_ing) n30_fecha_ing,
		 n30_fecha_sal, n30_tipo_trab
		FROM rolt042, rolt041, rolt030
		WHERE n42_compania       = 1
		  AND n42_proceso        = 'UT'
		  AND n42_ano            = YEAR((SELECT * FROM fec_act)) - 1
		  AND n41_compania       = n42_compania
		  AND n41_proceso        = n42_proceso
		  AND n41_ano            = n42_ano
		  AND n30_compania       = n42_compania
		  AND n30_cod_trab       = n42_cod_trab
	INTO TEMP tmp_n30;

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

SELECT n30_compania cia, LPAD(n30_cod_trab, 3, 0) cod,
	TRIM(n30_nombres) empleado,
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
				  AND n06_flag_ident = "AP"
				  AND EXISTS
				(SELECT 1 FROM rolt006 a
				WHERE a.n06_cod_rubro  = n08_rubro_base
				  AND a.n06_flag_ident IN ("VT", "VE", "VM",
							"VV", "OV", "SX")))
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"), 0.00)), 2) sueldos,
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
				  AND n06_flag_ident = "AP"
				  AND EXISTS
				(SELECT 1 FROM rolt006 a
				WHERE a.n06_cod_rubro  = n08_rubro_base
				  AND a.n06_flag_ident IN ("V5", "V1", "CO",
							"C1", "C2", "C3")))
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"), 0.00)), 2) sob_comi,
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
					   OR n06_cod_rubro  IN (35, 38))
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
	NVL((SELECT n42_val_trabaj + n42_val_cargas
		FROM rolt041, rolt042
		WHERE n41_compania = n30_compania
		  AND n41_ano      = YEAR((SELECT * FROM fec_act)) - 1
		  AND n41_estado   = "P"
		  AND n42_compania = n41_compania
		  AND n42_proceso  = 'UT'
		  AND n42_ano      = n41_ano
		  AND n42_cod_trab = n30_cod_trab), 0.00) val_ut,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = "DT"
		  AND n36_ano_proceso = YEAR((SELECT * FROM fec_act))
		  AND n36_cod_trab    = n30_cod_trab
		  AND n36_estado      = "P"), 0.00) val_dt,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = "DC"
		  AND n36_ano_proceso = YEAR((SELECT * FROM fec_act))
		  AND n36_cod_trab    = n30_cod_trab
		  AND n36_estado      = "P"), 0.00) val_dc,
	NVL((SELECT SUM(n38_valor_fondo)
		FROM rolt038
		WHERE n38_compania        = n30_compania
		  AND YEAR(n38_fecha_fin) = YEAR((SELECT * FROM fec_act))
		  AND n38_cod_trab        = n30_cod_trab
		  AND n38_estado          = "P"), 0.00) val_fr
	FROM tmp_n30, OUTER rolt032
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= (SELECT MDY(01, 01, YEAR(fecha)) FROM fec_act)
	  AND n32_fecha_fin  <= (SELECT * FROM fec_act)
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
	GROUP BY 1, 2, 3, 7, 8, 9, 10, 11, 12, 13
	INTO TEMP t1;

DROP TABLE tmp_ctb;
DROP TABLE tmp_vac;

DELETE FROM t1
	WHERE sueldos  = 0
	  AND sob_comi = 0
	  AND val_ap   = 0
	  AND bonif    = 0
	  AND otros    = 0
	  AND net_vac  = 0
	  AND val_ut   = 0
	  AND val_dt   = 0
	  AND val_dc   = 0
	  AND val_fr   = 0
	  AND MONTH((SELECT * FROM fec_act)) <> 12;

SELECT COUNT(*) tot_emp FROM t1;

SELECT cia, cod, empleado, SUM(sueldos) sueldos, SUM(sob_comi) sob_comi,
	SUM(val_ap) val_ap, SUM((sueldos + sob_comi) - val_ap) val_nom,
	SUM(bonif) bonif, SUM(otros) otros, SUM(net_vac) net_vac,
	SUM(val_ut) val_ut, val_dt, val_dc, val_fr
	FROM t1
	GROUP BY 1, 2, 3, 12, 13, 14
	INTO TEMP tmp_emp;

DROP TABLE t1;

SELECT COUNT(*) tot_emp FROM tmp_emp;

SELECT n30_cod_trab codigo, TRIM(n30_nombres[1, 35]) empleados,
	n56_aux_val_vac cta,
	ROUND(NVL(SUM(b13_valor_base) * (-1), 0), 2) val_ir_acum
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n56_compania     = n30_compania
	  AND n56_proceso      = 'IR'
	  AND n56_cod_depto    = n30_cod_depto
	  AND n56_cod_trab     = n30_cod_trab
	  AND b12_compania     = n56_compania
	  AND b12_tipo_comp    = 'DN'
	  AND b12_estado      <> 'E'
	  AND b12_fec_proceso BETWEEN MDY(10, 01, YEAR((SELECT * FROM fec_act)))
				  AND ((SELECT * FROM fec_act) + 1 UNITS MONTH)
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b13_cuenta       = n56_aux_val_vac
	  AND b13_valor_base   < 0
	GROUP BY 1, 2, 3
UNION
SELECT n30_cod_trab codigo, TRIM(n30_nombres[1, 35]) empleados,
	n56_aux_banco cta,
	ROUND(NVL(SUM(b13_valor_base) * (-1), 0), 2) val_ir_acum
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n56_compania     = n30_compania
	  AND n56_proceso      = 'AI'
	  AND n56_cod_depto    = n30_cod_depto
	  AND n56_cod_trab     = n30_cod_trab
	  AND b12_compania     = n56_compania
	  AND b12_tipo_comp    = 'DC'
	  AND b12_estado      <> 'E'
	  AND b12_origen       = 'A'
	  AND b12_fec_proceso BETWEEN MDY(10, 01, YEAR((SELECT * FROM fec_act)))
				  AND ((SELECT * FROM fec_act) + 1 UNITS MONTH)
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b13_cuenta       = n56_aux_banco
	  AND b13_valor_base   < 0
	GROUP BY 1, 2, 3
UNION
SELECT n30_cod_trab codigo, TRIM(n30_nombres[1, 35]) empleados,
	n56_aux_val_vac cta,
	ROUND(NVL(SUM(CASE WHEN n56_cod_trab <> 131
				THEN b13_valor_base * (-1)
				ELSE b13_valor_base
			END), 0), 2) val_ir_acum
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n56_compania     = n30_compania
	  AND n56_proceso      = 'IR'
	  AND n56_cod_depto    = n30_cod_depto
	  AND n56_cod_trab     = n30_cod_trab
	  AND b12_compania     = n56_compania
	  AND (b12_tipo_comp   = 'DN'
	   OR (b12_tipo_comp   = 'DC'
	  AND  n56_cod_trab    = 131))
	  AND b12_estado      <> 'E'
	  AND b12_fec_proceso BETWEEN MDY(11, 01, YEAR((SELECT * FROM fec_act)))
				  AND ((SELECT * FROM fec_act) + 1 UNITS MONTH)
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b13_cuenta       = n56_aux_val_vac
	  AND b13_valor_base   > 0
	GROUP BY 1, 2, 3
	INTO TEMP t1;

SELECT codigo, empleados, cta, ROUND(NVL(SUM(val_ir_acum), 0), 2) val_ir_acum
	FROM t1
	GROUP BY 1, 2, 3
	INTO TEMP tmp_ir_cob;

DROP TABLE t1;

SELECT * FROM tmp_ir_cob ORDER BY 2;

SELECT COUNT(*) tot_emp_ir FROM tmp_ir_cob;

SELECT ROUND(NVL(SUM(val_ir_acum), 0), 2) tot_ir FROM tmp_ir_cob;

UNLOAD TO "empleados_2011.unl"
	SELECT cod, empleado, tipo_ane, cedula, direccion, ciudad, prov,
		telefono,
		CASE WHEN val_ap > sist_net
			THEN sist_net
			ELSE 2
		END sist_net,
		sueldos, sob_comi, val_dt, val_dc, val_fr, val_ut,
		ROUND((net_vac + otros + bonif), 2) otr_boni, val_ap,
		0, 0, 0,
		ROUND(((sueldos + sob_comi + val_ut + net_vac + otros + bonif)
			- val_ap),
			2) subtotal,
		ROUND(CASE WHEN (n30_fecha_ing < (SELECT MDY(01, 01,YEAR(fecha))
						FROM fec_act))
			THEN 12
			ELSE TRUNC((((SELECT * FROM fec_act) - n30_fecha_ing)
					+ 1) / 30) +
				CASE WHEN (MOD((((SELECT * FROM fec_act) -
					n30_fecha_ing) + 1), 30) = 0) OR
					(((SELECT * FROM fec_act) -
						n30_fecha_ing) + 1)
					>= (SELECT n90_dias_anio
						FROM rolt090
						WHERE n90_compania =
							n30_compania)
					THEN 0.00
					ELSE MOD((((SELECT * FROM fec_act) -
						n30_fecha_ing) + 1), 30) / 30
				END
		END, 2) num_mes,
		0, 0, 0,
		ROUND(((sueldos + sob_comi + val_ut + net_vac + otros + bonif)
			- val_ap),
			2) base_impo,
		NVL((SELECT val_ir_acum
			FROM tmp_ir_cob
			WHERE codigo = cod), 0) val_ir_cau,
		NVL((SELECT val_ir_acum
			FROM tmp_ir_cob
			WHERE codigo = cod), 0) val_ir_ret,
		CASE WHEN NVL((SELECT val_ir_acum
				FROM tmp_ir_cob
				WHERE codigo = cod), 0) > 0
			THEN 1
			ELSE 0
		END num_ret,
		0, YEAR((SELECT * FROM fec_act)) anio
		FROM tmp_emp, tmp_n30
		WHERE n30_cod_trab = cod
		ORDER BY 2;

DROP TABLE tmp_n30;
DROP TABLE tmp_emp;

DROP TABLE tmp_ir_cob;
DROP TABLE fec_act;

CREATE TEMP TABLE temp_ir
	(
		anio		SMALLINT,
		indice		SMALLINT,
		base_ini	DECIMAL(14,2),
		base_max	DECIMAL(14,2),
		base_fra	DECIMAL(12,2),
		porc		DECIMAL(5,2)
	);

LOAD FROM "tabla_ir.unl" INSERT INTO temp_ir;

SELECT MDY(mes_p, DAY(MDY(mes_p, 01, anio_p) + 1 UNITS MONTH - 1 UNITS DAY),
	anio_p) fecha
	FROM dual
	INTO TEMP fec_act;

{--
SELECT MDY(04, DAY(MDY(04, 01, 2009) + 1 UNITS MONTH - 1 UNITS DAY),
	2009) fecha
	FROM dual
	INTO TEMP fec_act;
--}

SELECT UNIQUE n30_compania, n30_cod_trab, n30_nombres, n30_estado,
	n30_cod_depto, n30_fecha_sal, n13_porc_trab, "N" mes_ut
	FROM rolt032, rolt030, rolt013
	WHERE n32_compania    IN (1, 2)
	  AND n32_cod_liqrol  IN ('Q1', 'Q2')
	  AND n32_ano_proceso  = YEAR((SELECT * FROM fec_act))
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	  AND n13_cod_seguro   = n30_cod_seguro
UNION
	SELECT UNIQUE n30_compania, n30_cod_trab, n30_nombres, n30_estado,
		n30_cod_depto, n30_fecha_sal, n13_porc_trab, "N" mes_ut
		FROM rolt042, rolt041, rolt030, rolt013
		WHERE n42_compania      IN (1, 2)
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

SELECT n30_cod_trab cod1, ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n30_compania        IN (1, 2)
	  AND n30_estado           = 'A'
	  AND n56_compania         = n30_compania
	  AND n56_proceso          = 'AN'
	  AND n56_cod_trab         = n30_cod_trab
	  AND b12_compania         = n56_compania
	  AND b12_estado          <> 'E'
	  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) =
			EXTEND((SELECT * FROM fec_act), YEAR TO MONTH)
	  AND b13_compania         = b12_compania
	  AND b13_tipo_comp        = b12_tipo_comp
	  AND b13_num_comp         = b12_num_comp
	  AND b13_valor_base       > 0
	  AND b13_cuenta           = '51030701' || n56_aux_val_vac[9, 12]
	GROUP BY 1
UNION
SELECT n30_cod_trab cod1, ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n30_compania        IN (1, 2)
	  AND n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal)  = YEAR((SELECT * FROM fec_act))
	  AND n56_compania         = n30_compania
	  AND n56_proceso          = 'AN'
	  AND n56_cod_trab         = n30_cod_trab
	  AND b12_compania         = n56_compania
	  AND b12_estado          <> 'E'
	  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) =
			EXTEND((SELECT * FROM fec_act), YEAR TO MONTH)
	  AND b13_compania         = b12_compania
	  AND b13_tipo_comp        = b12_tipo_comp
	  AND b13_num_comp         = b12_num_comp
	  AND b13_valor_base       > 0
	  AND b13_cuenta           = '51030701' || n56_aux_val_vac[9, 12]
	GROUP BY 1
	INTO TEMP tmp_ctb;

SELECT LPAD(n30_cod_trab, 3, 0) cod, TRIM(n30_nombres) empleado,
	{--
	NVL(SUM(n32_tot_gan), 0) tot_gan,
	NVL(ROUND(SUM(n32_tot_gan * n13_porc_trab / 100), 2), 0) val_ap,
	NVL(ROUND(SUM(n32_tot_gan - (n32_tot_gan * n13_porc_trab / 100)), 2),
		0) val_nom,
	--}
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
	ROUND(SUM(NVL((SELECT n33_valor
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
						'AG', 'IV', 'OI', 'BO', 'FM'))
		  AND n33_valor       > 0
		  AND n33_det_tot     = "DI"
		  AND n33_cant_valor  = "V"
		  AND NOT EXISTS
			(SELECT 1
				FROM rolt008, rolt006
				WHERE n08_rubro_base = n33_cod_rubro
				  AND n06_cod_rubro  = n08_cod_rubro
				  AND n06_flag_ident = "AP")), 0.00)), 2) otros,
	NVL((SELECT SUM(b13_valor_base)
		FROM rolt039, rolt057, ctbt012, ctbt013
		WHERE n39_compania     = n30_compania
		  AND n39_proceso      IN ("VA", "VP")
		  AND n39_cod_trab     = n30_cod_trab
		  AND DATE(n39_fecing) BETWEEN n32_fecha_ini
					   AND n32_fecha_fin
		  AND n57_compania     = n39_compania
		  AND n57_proceso      = n39_proceso
		  AND n57_cod_trab     = n39_cod_trab
		  AND n57_periodo_ini  = n39_periodo_ini
		  AND n57_periodo_fin  = n39_periodo_fin
		  AND b12_compania     = n57_compania
		  AND b12_tipo_comp    = n57_tipo_comp
		  AND b12_num_comp     = n57_num_comp
		  AND b12_estado      <> "E"
		  AND b13_compania     = b12_compania
		  AND b13_tipo_comp    = b12_tipo_comp
		  AND b13_num_comp     = b12_num_comp
		  AND b13_cuenta[1, 1] = '5'
		  AND b13_valor_base   > 0), 0.00) val_vac,
	0.00 ap_vac,
	NVL((SELECT SUM(b13_valor_base)
		FROM rolt039, rolt057, ctbt012, ctbt013
		WHERE n39_compania     = n30_compania
		  AND n39_proceso      IN ("VA", "VP")
		  AND n39_cod_trab     = n30_cod_trab
		  AND DATE(n39_fecing) BETWEEN n32_fecha_ini
					   AND n32_fecha_fin
		  AND n57_compania     = n39_compania
		  AND n57_proceso      = n39_proceso
		  AND n57_cod_trab     = n39_cod_trab
		  AND n57_periodo_ini  = n39_periodo_ini
		  AND n57_periodo_fin  = n39_periodo_fin
		  AND b12_compania     = n57_compania
		  AND b12_tipo_comp    = n57_tipo_comp
		  AND b12_num_comp     = n57_num_comp
		  AND b12_estado      <> "E"
		  AND b13_compania     = b12_compania
		  AND b13_tipo_comp    = b12_tipo_comp
		  AND b13_num_comp     = b12_num_comp
		  AND b13_cuenta[1, 1] = '5'
		  AND b13_valor_base   > 0), 0.00) net_vac,
	{-- OJO ANTES
	NVL((SELECT n39_valor_vaca + n39_valor_adic
		FROM rolt039
		WHERE n39_compania     = n30_compania
		  AND n39_proceso      IN ("VA", "VP")
		  AND n39_cod_trab     = n30_cod_trab
		  AND n39_estado       = "P"
		  AND DATE(n39_fecing) BETWEEN n32_fecha_ini
					   AND n32_fecha_fin), 0.00) val_vac,
	NVL((SELECT n39_descto_iess
		FROM rolt039
		WHERE n39_compania     = n30_compania
		  AND n39_proceso      IN ("VA", "VP")
		  AND n39_cod_trab     = n30_cod_trab
		  AND n39_estado       = "P"
		  AND DATE(n39_fecing) BETWEEN n32_fecha_ini
					   AND n32_fecha_fin), 0.00) ap_vac,
	NVL((SELECT (n39_valor_vaca + n39_valor_adic) - n39_descto_iess
		FROM rolt039
		WHERE n39_compania     = n30_compania
		  AND n39_proceso      IN ("VA", "VP")
		  AND n39_cod_trab     = n30_cod_trab
		  AND n39_estado       = "P"
		  AND DATE(n39_fecing) BETWEEN n32_fecha_ini
					   AND n32_fecha_fin), 0.00) net_vac,
	--}
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = "DT"
		  AND n36_ano_proceso = n32_ano_proceso
		  AND n36_mes_proceso = n32_mes_proceso
		  AND n36_cod_trab  = n30_cod_trab
		  AND n36_estado    = "P"), 0) val_dt,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = "DC"
		  AND n36_ano_proceso = n32_ano_proceso
		  AND n36_mes_proceso = n32_mes_proceso
		  AND n36_cod_trab  = n30_cod_trab
		  AND n36_estado    = "P"), 0) val_dc,
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
		END, 0.00) val_ut,
	ROUND(NVL(NVL((SELECT SUM(val_ctb)
			FROM tmp_ctb
			WHERE cod1 = n32_cod_trab),
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
				  AND n06_flag_ident = "AP"))), 0.00), 2) bonif
	FROM tmp_n30, OUTER rolt032
	WHERE n32_compania   IN (1, 2)
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= MDY(MONTH((SELECT * FROM fec_act)), 01,
					YEAR((SELECT * FROM fec_act)))
	  AND n32_fecha_fin  <= (SELECT * FROM fec_act)
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
	GROUP BY 1, 2, 7, 8, 9, 10, 11, 12, 13
	INTO TEMP t1;
DROP TABLE tmp_ctb;

DELETE FROM t1
	WHERE tot_gan = 0
	  AND val_ap  = 0
	  AND val_nom = 0
	  AND otros   = 0
	  AND val_vac = 0
	  AND ap_vac  = 0
	  AND net_vac = 0
	  AND val_dt  = 0
	  AND val_dc  = 0
	  AND val_ut  = 0
	  AND bonif   = 0
	  AND MONTH((SELECT * FROM fec_act)) <> 12;

SELECT COUNT(*) tot_emp FROM t1;

SELECT cod, empleado, SUM(tot_gan) tot_gan, SUM(val_ap) val_ap,
	SUM(val_nom) val_nom, SUM(otros) otros, SUM(val_vac) val_vac,
	SUM(ap_vac) ap_vac, SUM(net_vac) net_vac, SUM(val_dt) val_dt,
	SUM(val_dc) val_dc, SUM(val_ut) val_ut, SUM(bonif) bonif
	FROM t1
	GROUP BY 1, 2
	INTO TEMP caca;

DROP TABLE t1;

SELECT * FROM caca
	INTO TEMP t1;

DROP TABLE caca;

UNLOAD TO "empleados_ir_mes_lanio_p.unl"
	SELECT cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac,
		net_vac, val_ut, bonif
		FROM t1
		ORDER BY 2;

SELECT cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac, net_vac,
	val_dt, val_dc, val_ut, bonif, ROUND(val_nom + otros + net_vac + val_ut
	+ bonif, 2) total
	FROM t1
	INTO TEMP caca;
DROP TABLE t1;

SELECT anio, indice, (base_ini / 12) base_ini, (base_max / 12) base_max,
	(base_fra / 12) base_fra, porc
	FROM temp_ir
	INTO TEMP tmp_ir;
DROP TABLE temp_ir;

SELECT * FROM caca
	WHERE total >= (SELECT MIN(base_max)
				FROM tmp_ir
				WHERE anio = YEAR((SELECT * FROM fec_act)))
	INTO TEMP t2;
DROP TABLE caca;

SELECT n30_cod_trab codigo, TRIM(n30_nombres[1, 35]) empleados,
	n56_aux_val_vac cta,
	ROUND(NVL(SUM(b13_valor_base) * (-1), 0), 2) val_ir_acum
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n30_compania           = 1
	  AND n56_compania           = n30_compania
	  AND n56_proceso            = 'IR'
	  AND n56_cod_depto          = n30_cod_depto
	  AND n56_cod_trab           = n30_cod_trab
	  AND b12_compania           = n56_compania
	  AND b12_estado            <> 'E'
	  AND YEAR(b12_fec_proceso)  = YEAR((SELECT * FROM fec_act))
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_cuenta             = n56_aux_val_vac
	  AND b13_valor_base         < 0
	GROUP BY 1, 2, 3
	INTO TEMP tmp_ir_cob;
DROP TABLE tmp_n30;

SELECT * FROM tmp_ir_cob ORDER BY 2;

SELECT COUNT(*) tot_emp_ir FROM t2;

SELECT cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac, net_vac,
	val_dt, val_dc, val_ut, bonif, total, NVL(val_ir_acum, 0) tot_ir_ret,
	ROUND((total - NVL((SELECT base_ini FROM tmp_ir
			WHERE anio     = YEAR((SELECT * FROM fec_act))
			  AND base_ini < total
			  AND base_max > total), 0)) *
			NVL((SELECT porc FROM tmp_ir
			WHERE anio     = YEAR((SELECT * FROM fec_act))
			  AND base_ini < total
			  AND base_max > total), 0) +
			NVL((SELECT base_fra FROM tmp_ir
			WHERE anio     = YEAR((SELECT * FROM fec_act))
			  AND base_ini < total
			  AND base_max > total), 0), 2) val_ir
	FROM t2, OUTER tmp_ir_cob
	WHERE cod = codigo
	INTO TEMP t3;
DROP TABLE t2;
DROP TABLE tmp_ir;
DROP TABLE tmp_ir_cob;

SELECT ROUND(SUM(val_ir), 2) total_ir FROM t3;

SELECT cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac, net_vac,
	val_dt, val_dc, val_ut, bonif, total, tot_ir_ret, val_ir,
	NVL(ROUND(val_ir - tot_ir_ret, 2), 0) val_ir_real
	FROM t3
	ORDER BY 2 ASC;
	--ORDER BY 17 desc;

DROP TABLE t3;
DROP TABLE fec_act;

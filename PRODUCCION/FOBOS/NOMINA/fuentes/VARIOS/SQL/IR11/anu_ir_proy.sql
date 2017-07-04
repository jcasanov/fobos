CREATE TEMP TABLE tmp_ir
	(
		anio		SMALLINT,
		indice		SMALLINT,
		base_ini	DECIMAL(14,2),
		base_max	DECIMAL(14,2),
		base_fra	DECIMAL(12,2),
		porc		DECIMAL(5,2)
	);

--LOAD FROM "tabla_ir.unl" INSERT INTO tmp_ir;

SELECT MDY(mes_p, DAY(MDY(mes_p, 01, anio_p) + 1 UNITS MONTH - 1 UNITS DAY),
	anio_p) fecha
	FROM dual
	INTO TEMP fec_act;

{--
SELECT MDY(03, DAY(MDY(03, 01, 2011) + 1 UNITS MONTH - 1 UNITS DAY),
	2011) fecha
	FROM dual
	INTO TEMP fec_act;
--}

SELECT UNIQUE n30_compania, n30_cod_trab, n30_nombres, n30_estado,
	n30_cod_depto, n30_fecha_ing, n30_fecha_sal, n30_cod_seguro,
	n30_tipo_trab
	FROM rolt032, rolt030
	WHERE n32_compania    IN (1, 2)
	  AND n32_cod_liqrol  IN ('Q1', 'Q2')
	  AND n32_ano_proceso  = YEAR((SELECT * FROM fec_act))
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
UNION
	SELECT UNIQUE n30_compania, n30_cod_trab, n30_nombres, n30_estado,
		n30_cod_depto, n30_fecha_ing, n30_fecha_sal, n30_cod_seguro,
		n30_tipo_trab
		FROM rolt042, rolt041, rolt030
		WHERE n42_compania      IN (1, 2)
		  AND n42_proceso        = 'UT'
		  AND n42_ano            = YEAR((SELECT * FROM fec_act)) - 1
		  AND n41_compania       = n42_compania
		  AND n41_proceso        = n42_proceso
		  AND n41_ano            = n42_ano
		  AND n30_compania       = n42_compania
		  AND n30_cod_trab       = n42_cod_trab
	INTO TEMP tmp_n30;

SELECT COUNT(*) tot_emp_n30 FROM tmp_n30;

CREATE PROCEDURE dia_mes (fecha DATE) RETURNING INT;
	DEFINE dia		INT;

	IF MONTH(fecha) = 2 AND DAY(fecha) > 28 THEN
		IF MOD(YEAR(TODAY), 4) = 0 THEN
			RETURN 28;
		ELSE
			RETURN 28;
		END IF;
	END IF;

	LET dia = DAY(fecha);

	RETURN dia;

END PROCEDURE;

SELECT n32_cod_trab codo, ROUND(SUM(n33_valor), 2) val_ot
	FROM rolt032, rolt033
	WHERE n32_compania   IN (1, 2)
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= MDY(01, 01, YEAR((SELECT * FROM fec_act)))
	  AND n32_fecha_fin  <= (SELECT * FROM fec_act)
	  AND n33_compania    = n32_compania
	  AND n33_cod_liqrol  = n32_cod_liqrol
	  AND n33_fecha_ini   = n32_fecha_ini
	  AND n33_fecha_fin   = n32_fecha_fin
	  AND n33_cod_trab    = n32_cod_trab
	  AND n33_cod_rubro  NOT IN (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ('SI', 'DI',
							'AG', 'IV', 'OI', 'BO',
							'FM', 'E1')
					   OR n06_cod_rubro  IN (35, 38))
	  AND n33_valor       > 0
	  AND n33_det_tot     = "DI"
	  AND n33_cant_valor  = "V"
	  AND NOT EXISTS (SELECT 1
				FROM rolt008, rolt006
				 WHERE n08_rubro_base = n33_cod_rubro
				   AND n06_cod_rubro  = n08_cod_rubro
				   AND n06_flag_ident = "AP")
	GROUP BY 1
	INTO TEMP tmp_ot;

SELECT n30_cod_trab cod1, ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM tmp_n30, rolt056, ctbt012, ctbt013
	WHERE n30_compania    IN (1, 2)
	  AND n30_estado       = 'A'
	  AND n56_compania     = n30_compania
	  AND n56_proceso      = 'AN'
	  AND n56_cod_trab     = n30_cod_trab
	  AND n56_cod_depto    = n30_cod_depto
	  AND b12_compania     = n56_compania
	  AND b12_estado       <> 'E'
	  AND b12_fec_proceso BETWEEN MDY(01, 01, YEAR((SELECT * FROM fec_act)))
				  AND (SELECT * FROM fec_act)
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b13_valor_base   > 0
	  AND b13_cuenta       = '51030701' || n56_aux_val_vac[9, 12]
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
	  AND n56_cod_depto        = n30_cod_depto
	  AND b12_compania         = n56_compania
	  AND b12_estado          <> 'E'
	  AND b12_fec_proceso     BETWEEN MDY(01, 01,
						YEAR((SELECT * FROM fec_act)))
				      AND (SELECT * FROM fec_act)
	  AND b13_compania         = b12_compania
	  AND b13_tipo_comp        = b12_tipo_comp
	  AND b13_num_comp         = b12_num_comp
	  AND b13_valor_base       > 0
	  AND b13_cuenta           = '51030701' || n56_aux_val_vac[9, 12]
	GROUP BY 1
	INTO TEMP tmp_ctb;

SELECT n32_cod_trab cod2, ROUND(SUM(n33_valor), 2) val_bon
	FROM rolt032, rolt033
	WHERE n32_compania   IN (1, 2)
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= MDY(01, 01, YEAR((SELECT * FROM fec_act)))
	  AND n32_fecha_fin  <= (SELECT * FROM fec_act)
	  AND n33_compania    = n32_compania
	  AND n33_cod_liqrol  = n32_cod_liqrol
	  AND n33_fecha_ini   = n32_fecha_ini
	  AND n33_fecha_fin   = n32_fecha_fin
	  AND n33_cod_trab    = n32_cod_trab
	  AND n33_cod_rubro  IN (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = 'BO')
	  AND n33_valor       > 0
	  AND n33_det_tot     = "DI"
	  AND n33_cant_valor  = "V"
	  AND NOT EXISTS (SELECT 1
				FROM rolt008, rolt006
				 WHERE n08_rubro_base = n33_cod_rubro
				   AND n06_cod_rubro  = n08_cod_rubro
				   AND n06_flag_ident = "AP")
	GROUP BY 1
	INTO TEMP tmp_bon;

SELECT n30_compania cia, LPAD(n30_cod_trab, 3, 0) cod,
	TRIM(n30_nombres) empleado, n30_estado est,
	NVL(ROUND(SUM(NVL((SELECT SUM(n33_valor)
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
		  AND n33_cant_valor  = "V"), 0.00)
 	/ MONTH((SELECT * FROM fec_act)) * 12), 2), 0) tot_gan,
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
	NVL(ROUND((SELECT val_ot * (12 - MONTH((SELECT * FROM fec_act)) + 1)
			FROM tmp_ot
			WHERE codo = n32_cod_trab), 2), 0) otros,
	ROUND(NVL(NVL((SELECT val_ctb
			FROM tmp_ctb
			WHERE cod1 = n32_cod_trab),
		(SELECT val_bon
			FROM tmp_bon
			WHERE cod2 = n32_cod_trab)), 0), 2) bonif,
	n30_cod_seguro cod_seguro, n30_tipo_trab tipo,
	n00_dias_vacac +
	(CASE WHEN (MDY(MONTH(n30_fecha_ing), dia_mes(n30_fecha_ing),
		YEAR((SELECT * FROM fec_act))))
		>= (n30_fecha_ing + (n00_ano_adi_vac - 1) UNITS YEAR
			- 1 UNITS DAY)
		THEN CASE WHEN (n00_dias_vacac +
			((YEAR(MDY(MONTH(n30_fecha_ing),dia_mes(n30_fecha_ing),
			YEAR((SELECT * FROM fec_act)))) - YEAR(n30_fecha_ing
			 + (n00_ano_adi_vac
			- 1) UNITS YEAR - 1 UNITS DAY)) * n00_dias_adi_va)) >
			n00_max_vacac
			THEN n00_max_vacac - n00_dias_vacac
			ELSE ((YEAR(MDY(MONTH(n30_fecha_ing),
				dia_mes(n30_fecha_ing),
				YEAR((SELECT * FROM fec_act)))) -
					YEAR(n30_fecha_ing +
				(n00_ano_adi_vac - 1) UNITS YEAR
				- 1 UNITS DAY)) * n00_dias_adi_va)
			END
		ELSE 0
		END) d_vac
	FROM rolt032, tmp_n30, rolt000
	WHERE n32_compania   IN (1, 2)
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= MDY(01, 01, YEAR((SELECT * FROM fec_act)))
	  AND n32_fecha_fin  <= (SELECT * FROM fec_act)
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
	  AND n00_serial      = n30_compania
	GROUP BY 1, 2, 3, 4, 7, 8, 9, 10, 11
	INTO TEMP t1;

DROP TABLE tmp_ot;
DROP TABLE tmp_ctb;
DROP TABLE tmp_bon;
DROP PROCEDURE dia_mes;

SELECT cia, cod, empleado, tot_gan, val_ap, NVL(ROUND(tot_gan - val_ap, 2),
	0) val_nom, otros, bonif, tipo, d_vac, est
	FROM t1
	INTO TEMP tmp_emp;

DROP TABLE t1;

SELECT cod codv, NVL(SUM(b13_valor_base), 0) val_vac, 0.00 ap_vac,
	NVL(SUM(b13_valor_base), 0) vac_net--, n39_tipo tip_v
	FROM tmp_emp, rolt039, rolt057, ctbt012, ctbt013
	--WHERE est               = 'A'
	WHERE n39_compania      = cia
	  AND n39_proceso      IN ("VA", "VP")
	  AND DATE(n39_fecing) BETWEEN MDY(01, 01,YEAR((SELECT * FROM fec_act)))
				   AND (SELECT * FROM fec_act)
	  AND n39_cod_trab      = cod
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
	GROUP BY 1, 3--, 5
UNION
SELECT cod codv, NVL(SUM(n39_valor_vaca + n39_valor_adic), 0) val_vac,
	NVL(SUM(n39_descto_iess), 0) ap_vac,
	NVL(SUM((n39_valor_vaca + n39_valor_adic) - n39_descto_iess),0) vac_net
	--n39_tipo tip_v
	FROM tmp_emp, rolt039
	WHERE est               = 'I'
	  AND n39_compania      = cia
	  --AND n39_proceso      IN ("VA", "VP")
	  AND n39_proceso       = "VP"
	  AND n39_cod_trab      = cod
	  AND DATE(n39_fecing) BETWEEN MDY(01, 01,YEAR((SELECT * FROM fec_act)))
				   AND (SELECT * FROM fec_act)
	GROUP BY 1--, 5
	INTO TEMP t1_v;

SELECT codv, NVL(SUM(val_vac), 0) val_vac, NVL(SUM(ap_vac), 0) ap_vac,
	NVL(SUM((val_vac) - ap_vac), 0) vac_net
	FROM t1_v
	GROUP BY 1
	INTO TEMP tmp_vac;

DROP TABLE t1_v;

SELECT cod codd, n36_proceso c_dec, NVL(n36_valor_bruto, 0) val_dec
	FROM rolt036, tmp_emp
	WHERE n36_compania     = cia
	  AND n36_proceso     IN ("DC", "DT")
	  AND n36_ano_proceso  = YEAR((SELECT * FROM fec_act))
	  AND n36_mes_proceso <= MONTH((SELECT * FROM fec_act))
	  AND n36_cod_trab     = cod
	  AND n36_estado       = "P"
	INTO TEMP tmp_dec;

SELECT n42_compania cia_u, n42_cod_trab codu, n30_nombres nom_emp,
	n30_tipo_trab tipo_u, n42_val_trabaj + n42_val_cargas val_ut,
	n30_estado est
	 FROM rolt041, rolt042, tmp_n30
	 WHERE n41_compania IN (1, 2)
	   AND n41_ano       = YEAR((SELECT * FROM fec_act)) - 1
	   AND n41_estado    = "P"
	   AND n42_compania  = n41_compania
	   AND n42_ano       = n41_ano
	   AND n30_compania  = n42_compania
	   AND n30_cod_trab  = n42_cod_trab
	INTO TEMP tmp_ut;

INSERT INTO tmp_emp
	SELECT cia_u, codu, nom_emp, 0.00, 0.00, 0.00, 0.00, 0.00, tipo_u, 0,
		est
		FROM tmp_ut
		WHERE MONTH((SELECT * FROM fec_act)) >= 4
		  AND NOT EXISTS
			(SELECT 1 FROM tmp_emp a
				WHERE a.cod = codu);

SELECT EXTEND((SELECT * FROM fec_act), YEAR TO MONTH) periodo, cod, empleado,
	tot_gan, val_ap, val_nom, otros,
	ROUND(CASE WHEN (NVL((SELECT val_vac FROM tmp_vac
				WHERE codv = cod), 0) = 0 AND
				MONTH((SELECT * FROM fec_act)) <> 12)
			THEN CASE WHEN tipo = "N" THEN (tot_gan / 360) * d_vac
				ELSE 0.00 END
			ELSE NVL((SELECT val_vac FROM tmp_vac
				WHERE codv = cod), 0)
		END, 2) val_vac,
	ROUND(NVL(CASE WHEN ((NVL((SELECT ap_vac FROM tmp_vac
				WHERE codv = cod), 0) = 0) AND
				MONTH((SELECT * FROM fec_act)) <> 12) --AND
			{
			(NVL((SELECT tip_v FROM tmp_vac
				WHERE codv = cod), "G") = "G"))
			}
			THEN CASE WHEN tipo = "N"
				THEN ((tot_gan / 360) * d_vac) * 9.35 / 100
				ELSE 0.00 END
			ELSE NVL((SELECT ap_vac
					FROM tmp_vac
					WHERE codv = cod), 0)
		END, 0), 2) ap_vac,
	ROUND(CASE WHEN (NVL((SELECT vac_net FROM tmp_vac
				WHERE codv = cod), 0) = 0 AND
				MONTH((SELECT * FROM fec_act)) <> 12)
			THEN CASE WHEN tipo = "N"
				THEN ((tot_gan / 360) * d_vac) -
					(((tot_gan / 360) * d_vac) *
					9.35 / 100)
				ELSE 0.00 END
			ELSE NVL((SELECT vac_net
					FROM tmp_vac
					WHERE codv = cod), 0)
		END, 2) vac_net,
	ROUND(CASE WHEN NVL((SELECT val_dec FROM tmp_dec
				WHERE codd = cod AND c_dec = "DT"), 0) = 0
			THEN CASE WHEN tipo = "N" THEN tot_gan / 12
				ELSE 0.00 END
			ELSE (SELECT val_dec FROM tmp_dec
				WHERE codd = cod AND c_dec = "DT")
		END, 2) val_dt,
	NVL(CASE WHEN MONTH((SELECT * FROM fec_act)) >= 3
			THEN ROUND((SELECT val_dec FROM tmp_dec
					WHERE codd  = cod
					  AND c_dec = "DC"), 2)
			ELSE CASE WHEN tipo = "N" THEN
				NVL(ROUND((SELECT (n00_salario_min / 12) *
					(9 + MONTH((SELECT * FROM fec_act)) - 1)
					FROM rolt000
					WHERE n00_serial = cia), 2), 0)
				ELSE 0.00
				END
		END, 0) val_dc,
	NVL(CASE WHEN MONTH((SELECT * FROM fec_act)) >= 4
			THEN ROUND((SELECT val_ut FROM tmp_ut
					WHERE codu = cod), 2)
			ELSE 0.00
		END, 0) val_ut,
	bonif
	FROM tmp_emp
	INTO TEMP t1;

DROP TABLE tmp_emp;
DROP TABLE tmp_vac;
DROP TABLE tmp_dec;
DROP TABLE tmp_ut;

DELETE FROM t1
	WHERE tot_gan = 0
	  AND val_ap  = 0
	  AND val_nom = 0
	  AND otros   = 0
	  AND val_vac = 0
	  AND ap_vac  = 0
	  AND vac_net = 0
	  AND val_dt  = 0
	  AND val_dc  = 0
	  AND val_ut  = 0
	  AND bonif   = 0;

SELECT COUNT(*) tot_emp FROM t1;

UNLOAD TO "proy_ir_mes_lanio_p.unl"
	SELECT cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac,
		vac_net, val_ut, bonif
		FROM t1
		ORDER BY 2;

SELECT periodo, cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac,ap_vac,
	vac_net, val_dt, val_dc, val_ut, bonif, NVL(ROUND(val_nom + otros +
	vac_net + val_ut + bonif, 2), 0) total
	FROM t1
	INTO TEMP caca;
DROP TABLE t1;

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

SELECT cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac, vac_net,
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
DROP TABLE tmp_ir_cob;
DROP TABLE tmp_ir;

SELECT ROUND(SUM(val_ir), 2) total_ir FROM t3;

SELECT cod, empleado, tot_gan, val_ap, val_nom, otros, val_vac, ap_vac, vac_net,
	val_dt, val_dc, val_ut, bonif, total, tot_ir_ret, val_ir,
	NVL(ROUND(val_ir - tot_ir_ret, 2), 0) val_ir_real
	FROM t3
	ORDER BY 2 ASC;

DROP TABLE t3;
DROP TABLE fec_act;

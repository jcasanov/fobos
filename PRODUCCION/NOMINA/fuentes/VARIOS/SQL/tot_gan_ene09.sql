SELECT UNIQUE n32_cod_trab AS codigo,
	n30_nombres AS empleados,
	NVL(SUM(n32_tot_gan), 0) -
	NVL(SUM((SELECT SUM(c.n33_valor)
		FROM rolt032 b, rolt033 c
		WHERE b.n32_compania    = a.n32_compania
		  AND b.n32_cod_liqrol  = a.n32_cod_liqrol
		  AND b.n32_fecha_ini   = a.n32_fecha_ini
		  AND b.n32_fecha_fin   = a.n32_fecha_fin
		  AND b.n32_cod_trab    = a.n32_cod_trab
		  AND c.n33_compania    = b.n32_compania
		  AND c.n33_cod_liqrol  = b.n32_cod_liqrol
		  AND c.n33_fecha_ini   = b.n32_fecha_ini
		  AND c.n33_fecha_fin   = b.n32_fecha_fin
		  AND c.n33_cod_trab    = b.n32_cod_trab
		  AND c.n33_cod_rubro  IN
				(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ('V5', 'V1',
								'CO', 'C1'))
		  AND c.n33_cant_valor  = 'V'
		  AND c.n33_det_tot     = 'DI'
		  AND c.n33_valor       > 0)), 0) AS sueldo,
	NVL(SUM((SELECT SUM(c.n33_valor)
		FROM rolt032 b, rolt033 c
		WHERE b.n32_compania    = a.n32_compania
		  AND b.n32_cod_liqrol  = a.n32_cod_liqrol
		  AND b.n32_fecha_ini   = a.n32_fecha_ini
		  AND b.n32_fecha_fin   = a.n32_fecha_fin
		  AND b.n32_cod_trab    = a.n32_cod_trab
		  AND c.n33_compania    = b.n32_compania
		  AND c.n33_cod_liqrol  = b.n32_cod_liqrol
		  AND c.n33_fecha_ini   = b.n32_fecha_ini
		  AND c.n33_fecha_fin   = b.n32_fecha_fin
		  AND c.n33_cod_trab    = b.n32_cod_trab
		  AND c.n33_cod_rubro  IN
				(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ('V5', 'V1',
						'CO', 'MO', 'C1', 'BO'))
		  AND c.n33_cant_valor  = 'V'
		  AND c.n33_det_tot     = 'DI'
		  AND c.n33_valor       > 0)), 0) AS sob_com_otr,
	NVL(SUM((SELECT SUM(c.n33_valor)
		FROM rolt032 b, rolt033 c
		WHERE b.n32_compania    = a.n32_compania
		  AND b.n32_cod_liqrol  = a.n32_cod_liqrol
		  AND b.n32_fecha_ini   = a.n32_fecha_ini
		  AND b.n32_fecha_fin   = a.n32_fecha_fin
		  AND b.n32_cod_trab    = a.n32_cod_trab
		  AND c.n33_compania    = b.n32_compania
		  AND c.n33_cod_liqrol  = b.n32_cod_liqrol
		  AND c.n33_fecha_ini   = b.n32_fecha_ini
		  AND c.n33_fecha_fin   = b.n32_fecha_fin
		  AND c.n33_cod_trab    = b.n32_cod_trab
		  AND c.n33_cod_rubro  IN
				(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ('AP'))
		  AND c.n33_cant_valor  = 'V'
		  AND c.n33_det_tot     = 'DE'
		  AND c.n33_valor       > 0)), 0) AS apo_iess,
	NVL((SELECT SUM(n39_valor_vaca + n39_valor_adic)
		FROM rolt039
		WHERE n39_compania       = n30_compania
		  AND n39_proceso       IN ('VA', 'VP')
		  AND year(n39_fecing)   = 2009
		  AND month(n39_fecing)  = 1
		  AND n39_cod_trab       = n30_cod_trab), 0) AS val_vac,
	NVL((SELECT SUM(n39_descto_iess)
		FROM rolt039
		WHERE n39_compania       = n30_compania
		  AND n39_proceso       IN ('VA', 'VP')
		  AND year(n39_fecing)   = 2009
		  AND month(n39_fecing)  = 1
		  AND n39_cod_trab       = n30_cod_trab), 0) AS iess_vac,
	NVL((SELECT SUM(b13_valor_base)
		FROM rolt056, ctbt012, ctbt013
		WHERE n56_compania    = n30_compania
		  AND n56_proceso     = 'AN'
		  AND n56_cod_trab    = n30_cod_trab
		  AND b12_compania    = n56_compania
		  AND b12_estado     <> 'E'
		  AND extend(b12_fec_proceso, year to month) = '2009-01'
		  AND b13_compania    = b12_compania
		  AND b13_tipo_comp   = b12_tipo_comp
		  AND b13_num_comp    = b12_num_comp
		  AND b13_valor_base <> 0
		  AND b13_cuenta      = '51030701' || n56_aux_val_vac[9, 12]),
					0) AS no_deduc
	FROM rolt032 a, rolt030
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ('Q1', 'Q2')
	  AND a.n32_fecha_ini  >= MDY (01, 01, 2009)
	  AND a.n32_fecha_fin  <= MDY (01, 31, 2009)
	  AND n30_compania      = a.n32_compania
	  AND n30_cod_trab      = a.n32_cod_trab
	GROUP BY 1, 2, 6, 7, 8
	INTO TEMP tmp_tot_gan;

SELECT codigo, empleados, sueldo, sob_com_otr, val_vac, no_deduc,
	(sueldo + sob_com_otr + val_vac + no_deduc) AS tot_gan
	FROM tmp_tot_gan
	INTO TEMP t2;

SELECT NVL(SUM(tot_gan), 0) total FROM t2;

SELECT * FROM t2 ORDER BY 2;

UNLOAD TO "empleados_ene09.unl"
	SELECT codigo, empleados, tot_gan
		FROM t2
		ORDER BY 2;

DROP TABLE t2;

DROP TABLE tmp_tot_gan;

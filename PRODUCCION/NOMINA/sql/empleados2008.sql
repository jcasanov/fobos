SELECT UNIQUE n32_cod_trab AS codigo, n30_num_doc_id AS cedula,
	n30_nombres AS empleados, n30_domicilio AS direccion,
	n30_telef_domic AS telefono,
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
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = 'DT'
		  AND n36_ano_proceso = 2008
		  AND n36_mes_proceso = 12
		  AND n36_cod_trab    = n30_cod_trab), 0) AS val_dt,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = 'DC'
		  AND n36_ano_proceso = 2008
		  AND n36_mes_proceso = 3
		  AND n36_cod_trab    = n30_cod_trab), 0) AS val_dc,
	NVL((SELECT n38_valor_fondo
		FROM rolt038
		WHERE n38_compania        = n30_compania
		  AND YEAR(n38_fecha_fin) = 2008
		  AND n38_cod_trab        = n30_cod_trab), 0) AS val_fr,
	NVL((SELECT n42_val_trabaj + n42_val_cargas
		FROM rolt042
		WHERE n42_compania = n30_compania
		  AND n42_proceso  = 'UT'
		  AND n42_ano      = 2007
		  AND n42_cod_trab = n30_cod_trab), 0) AS val_ut,
	0.00 desahucio,
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
		WHERE n39_compania     = n30_compania
		  AND n39_proceso     IN ('VA', 'VP')
		  AND n39_ano_proceso  = 2008
		  AND n39_cod_trab     = n30_cod_trab), 0) AS val_vac,
	NVL((SELECT SUM(n39_descto_iess)
		FROM rolt039
		WHERE n39_compania     = n30_compania
		  AND n39_proceso     IN ('VA', 'VP')
		  AND n39_ano_proceso  = 2008
		  AND n39_cod_trab     = n30_cod_trab), 0) AS iess_vac
	FROM rolt032 a, rolt030
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ('Q1', 'Q2')
	  AND a.n32_fecha_ini  >= MDY (01, 01, 2008)
	  AND a.n32_fecha_fin  <= MDY (12, 31, 2008)
	  AND n30_compania      = a.n32_compania
	  AND n30_cod_trab      = a.n32_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 14, 15
	INTO TEMP tmp_ir;

UNLOAD TO "empleados2008.unl"
	SELECT codigo, cedula, empleados, direccion, telefono, sueldo,
		(sob_com_otr + val_vac) AS sob_com_otr, val_dt, val_dc, val_fr,
		val_ut, desahucio, (apo_iess + iess_vac) AS val_iess
		FROM tmp_ir
		ORDER BY 3;

DROP TABLE tmp_ir

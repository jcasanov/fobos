SELECT n32_ano_proceso AS anio,
	CASE WHEN n32_mes_proceso = 01 THEN "ENERO"
	     WHEN n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n32_mes_proceso = 03 THEN "MARZO"
	     WHEN n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN n32_mes_proceso = 05 THEN "MAYO"
	     WHEN n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN n32_mes_proceso = 07 THEN "JULIO"
	     WHEN n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n32_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS codigo, n30_num_doc_id AS cedula,
	TRIM(n30_nombres) AS empleados,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n32_compania
		  AND g34_cod_depto = n32_cod_depto) AS dpto,
	ROUND(CASE WHEN n30_estado = "A" THEN
		CASE WHEN EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
				YEAR TO MONTH) <
		EXTEND(MDY(n32_mes_proceso, 01, n32_ano_proceso),YEAR TO MONTH)
		THEN 1.00
		ELSE (30 - CASE WHEN (DAY(NVL(n30_fecha_reing, n30_fecha_ing))
					> 30) OR
				(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)) = 2
					AND
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)) >= 28)
					THEN 30
					ELSE DAY(NVL(n30_fecha_reing,
							n30_fecha_ing))
				END + 1) / 30
		END
		ELSE
		CASE WHEN EXTEND(n30_fecha_sal, YEAR TO MONTH) <
		EXTEND(MDY(n32_mes_proceso, 01, n32_ano_proceso),YEAR TO MONTH)
		THEN 1.00
		ELSE CASE WHEN (DAY(n30_fecha_sal) > 30) OR
					(MONTH(n30_fecha_sal) = 2 AND
					DAY(n30_fecha_sal) >= 28)
				THEN 30
				ELSE DAY(n30_fecha_sal)
			END / 30
		END
		END, 2) AS num_mes,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS est,
	ROUND(SUM(CASE WHEN (n33_det_tot = "DI" AND n06_flag_ident IN ("VT",
						"VE", "VM", "VV", "OV", "SX"))
			THEN n33_valor
			ELSE 0.00
		END), 2) AS sueldos,
	ROUND(SUM(CASE WHEN (n33_det_tot = "DI" AND n06_flag_ident IN ("V5",
						"V1", "CO", "C1", "C2", "C3"))
			THEN n33_valor
			ELSE 0.00
		END), 2) AS sobresueldos,
	0.00 AS val_13ro, 0.00 AS val_14to, 0.00 AS fondo_reserva,
	0.00 AS utilidades,
	CASE WHEN n30_estado = "A"
		THEN NVL((SELECT SUM(b13_valor_base)
			FROM rolt039, rolt057, ctbt012, ctbt013
			WHERE n39_compania      = n32_compania
			  AND n39_proceso      IN ("VA", "VP")
			  AND EXTEND(n39_fecing, YEAR TO MONTH) =
				EXTEND(MDY(n32_mes_proceso, 01,
						n32_ano_proceso), YEAR TO MONTH)
			  AND n39_cod_trab      = n32_cod_trab
			  AND n39_cod_depto     = n32_cod_depto
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
			  AND n39_cod_depto     = n32_cod_depto
			  AND EXTEND(n39_fecing, YEAR TO MONTH) =
				EXTEND(MDY(n32_mes_proceso, 01,
					n32_ano_proceso), YEAR TO MONTH)), 0.00)
	END AS net_vac,
	0.00 AS bonif, 0.00 AS otros,
	ROUND(SUM(CASE WHEN (n33_det_tot = "DE" AND n06_flag_ident = "AP")
			THEN n33_valor
			ELSE 0.00
		END), 2) AS val_ap
	FROM rolt032, rolt033, rolt030, rolt006
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  > 2003
	  AND n33_compania     = n32_compania
	  AND n33_cod_liqrol   = n32_cod_liqrol
	  AND n33_fecha_ini   >= n32_fecha_ini
	  AND n33_fecha_fin   <= n32_fecha_fin
	  AND n33_cod_trab     = n32_cod_trab
	  AND n33_valor        > 0
	  AND n33_det_tot     IN ("DI", "DE")
	  AND n33_cant_valor   = "V"
	  AND n30_compania     = n33_compania
	  AND n30_cod_trab     = n33_cod_trab
	  AND n06_cod_rubro    = n33_cod_rubro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15, 16, 17
UNION
SELECT YEAR(n41_fecing) AS anio,
	CASE WHEN MONTH(n41_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n41_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n41_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n41_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n41_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n41_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n41_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n41_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n41_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n41_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n41_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n41_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	n42_cod_trab AS codigo, n30_num_doc_id AS cedula,
	TRIM(n30_nombres) AS empleados,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n42_compania
		  AND g34_cod_depto = n42_cod_depto) AS dpto,
	0.00 AS num_mes,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS est,
	0.00 AS sueldos, 0.00 AS sobresueldos, 0.00 AS val_13ro,
	0.00 AS val_14to, 0.00 AS fondo_reserva,
	NVL(n42_val_trabaj + n42_val_cargas, 0.00) AS utilidades,
	0.00 AS net_vac, 0.00 AS bonif, 0.00 AS otros, 0.00 AS val_ap
	FROM rolt041, rolt042, rolt030
	WHERE n41_compania        = 1
	  AND n41_ano             > 2005
	  AND n41_estado          = "P"
	  AND n42_compania        = n41_compania
	  AND n42_proceso         = "UT"
	  AND n42_ano             = n41_ano
	  AND n30_compania        = n42_compania
	  AND n30_cod_trab        = n42_cod_trab
	  AND n30_estado          = "I"
	  AND YEAR(n30_fecha_sal) BETWEEN n42_ano AND n42_ano + 1
UNION
SELECT n36_ano_proceso AS anio,
	CASE WHEN n36_mes_proceso = 01 THEN "ENERO"
	     WHEN n36_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n36_mes_proceso = 03 THEN "MARZO"
	     WHEN n36_mes_proceso = 04 THEN "ABRIL"
	     WHEN n36_mes_proceso = 05 THEN "MAYO"
	     WHEN n36_mes_proceso = 06 THEN "JUNIO"
	     WHEN n36_mes_proceso = 07 THEN "JULIO"
	     WHEN n36_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n36_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n36_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n36_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n36_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS codigo, n30_num_doc_id AS cedula,
	TRIM(n30_nombres) AS empleados, g34_nombre AS dpto, 0.00 AS num_mes,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS est,
	0.00 AS sueldos, 0.00 AS sobresueldos,
	CASE WHEN n36_proceso = "DT"
		THEN n36_valor_bruto
		ELSE 0.00
	END AS val_13ro,
	CASE WHEN n36_proceso = "DC"
		THEN n36_valor_bruto
		ELSE 0.00
	END AS val_14to,
	0.00 AS fondo_reserva, 0.00 AS utilidades, 0.00 AS net_vac,
	0.00 AS bonif, 0.00 AS otros, 0.00 AS val_ap
	FROM rolt036, rolt030, gent034
	WHERE n36_compania    = 1
	  AND n36_ano_proceso > 2003
	  AND n30_compania    = n36_compania
	  AND n30_cod_trab    = n36_cod_trab
	  AND g34_compania    = n36_compania
	  AND g34_cod_depto   = n36_cod_depto
UNION
SELECT YEAR(n38_fecha_fin) AS anio,
	CASE WHEN MONTH(n38_fecha_fin) = 01 THEN "ENERO"
	     WHEN MONTH(n38_fecha_fin) = 02 THEN "FEBRERO"
	     WHEN MONTH(n38_fecha_fin) = 03 THEN "MARZO"
	     WHEN MONTH(n38_fecha_fin) = 04 THEN "ABRIL"
	     WHEN MONTH(n38_fecha_fin) = 05 THEN "MAYO"
	     WHEN MONTH(n38_fecha_fin) = 06 THEN "JUNIO"
	     WHEN MONTH(n38_fecha_fin) = 07 THEN "JULIO"
	     WHEN MONTH(n38_fecha_fin) = 08 THEN "AGOSTO"
	     WHEN MONTH(n38_fecha_fin) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n38_fecha_fin) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n38_fecha_fin) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n38_fecha_fin) = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS codigo, n30_num_doc_id AS cedula,
	TRIM(n30_nombres) AS empleados, g34_nombre AS dpto, 0.00 AS num_mes,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS est,
	0.00 AS sueldos, 0.00 AS sobresueldos, 0.00 AS val_13ro,
	0.00 AS val_14to,
	NVL(SUM(n38_valor_fondo), 0.00) AS fondo_reserva,
	0.00 AS utilidades, 0.00 AS net_vac, 0.00 AS bonif, 0.00 AS otros,
	0.00 AS val_ap
	FROM rolt038, rolt032, rolt030, gent034
	WHERE n38_compania        = 1
	  AND YEAR(n38_fecha_fin) > 2003
	  AND n38_estado          = "P"
	  AND n32_compania        = n38_compania
	  AND n32_cod_liqrol      = "Q1"
	  AND n32_fecha_ini       = n38_fecha_ini
	  AND n32_cod_trab        = n38_cod_trab
	  AND n30_compania        = n32_compania
	  AND n30_cod_trab        = n32_cod_trab
	  AND g34_compania        = n32_compania
	  AND g34_cod_depto       = n32_cod_depto
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18
UNION
SELECT n32_ano_proceso AS anio,
	CASE WHEN n32_mes_proceso = 01 THEN "ENERO"
	     WHEN n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n32_mes_proceso = 03 THEN "MARZO"
	     WHEN n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN n32_mes_proceso = 05 THEN "MAYO"
	     WHEN n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN n32_mes_proceso = 07 THEN "JULIO"
	     WHEN n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n32_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS codigo, n30_num_doc_id AS cedula,
	TRIM(n30_nombres) AS empleados, g34_nombre AS dpto, 0.00 AS num_mes,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS est,
	0.00 AS sueldos, 0.00 AS sobresueldos, 0.00 AS val_13ro,
	0.00 AS val_14to, 0.00 AS fondo_reserva, 0.00 AS utilidades,
	0.00 AS net_vac,
	SUM(CASE WHEN b13_cuenta[1, 8] = "51030701"
			THEN b13_valor_base
			ELSE 0.00
		END) AS bonif,
	SUM(CASE WHEN b13_cuenta[1, 8] = "51030702"
			THEN b13_valor_base
			ELSE 0.00
		END) AS otros,
	0.00 AS val_ap
	FROM rolt032, rolt056, rolt030, gent034, ctbt012, ctbt013
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  > 2005
	  AND n56_compania     = n32_compania
	  AND n56_proceso      = "AN"
	  AND n56_cod_trab     = n32_cod_trab
	  AND n56_cod_depto    = n32_cod_depto
	  AND n30_compania     = n56_compania
	  AND n30_cod_trab     = n56_cod_trab
	  AND g34_compania     = n56_compania
	  AND g34_cod_depto    = n56_cod_depto
	  AND b12_compania     = n56_compania
	  AND b12_estado      <> "E"
	  AND ((n30_estado     = "A"
	  AND   EXTEND(b12_fec_proceso, YEAR TO MONTH) =
		EXTEND(MDY(n32_mes_proceso, 01, n32_ano_proceso),YEAR TO MONTH))
	   OR  (n30_estado     = "A"
	  AND   EXTEND(b12_fec_proceso, YEAR TO MONTH) =
		EXTEND(n30_fecha_sal, YEAR TO MONTH)))
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b13_valor_base   > 0
	  AND (b13_cuenta      = "51030701" || n56_aux_val_vac[9, 12]
	   OR  b13_cuenta      = "51030702" || n56_aux_val_vac[9, 12])
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 18
	ORDER BY 1;

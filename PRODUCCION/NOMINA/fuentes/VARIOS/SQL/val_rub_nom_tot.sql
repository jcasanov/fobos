SELECT n30_cod_trab AS CODIGO, n30_nombres AS EMPLEADOS,
	n32_ano_proceso AS ANIOS,
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
	END AS MESES,
	n30_nombres AS EMPLEADO, g34_nombre AS DEPARTAMENTO,
	n30_num_doc_id AS CEDULA, n32_sueldo AS SUELDO_ROL,
	NVL(SUM(n32_tot_ing), 0)  AS TOTAL_INGRESO,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = 'DT'
		  AND n36_ano_proceso = n32_ano_proceso
		  AND n36_mes_proceso = n32_mes_proceso
		  AND n36_cod_trab    = n30_cod_trab), 0) AS VALOR_DT,
	NVL((SELECT n36_valor_bruto
		FROM rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = 'DC'
		  AND n36_ano_proceso = n32_ano_proceso
		  AND n36_mes_proceso = n32_mes_proceso
		  AND n36_cod_trab    = n30_cod_trab), 0) AS VALOR_DC,
	NVL((SELECT n39_valor_vaca + n39_valor_adic
		FROM rolt039
		WHERE n39_compania    = n30_compania
		  AND n39_proceso     IN ('VA', 'VP')
		  AND n39_ano_proceso = n32_ano_proceso
		  AND n39_mes_proceso = n32_mes_proceso
		  AND n39_cod_trab    = n30_cod_trab), 0) AS VALOR_VA,
	NVL((SELECT n42_val_trabaj + n42_val_cargas
		FROM rolt041, rolt042
		WHERE n41_compania      = n30_compania
		  AND n41_proceso       = 'UT'
		  AND YEAR(n41_fecing)  = n32_ano_proceso
		  AND MONTH(n41_fecing) = n32_mes_proceso
		  AND n42_compania      = n41_compania
		  AND n42_proceso       = n41_proceso
		  AND n42_fecha_ini     = n41_fecha_ini
		  AND n42_fecha_fin     = n41_fecha_fin
		  AND n42_cod_trab      = n30_cod_trab), 0) AS VALOR_UT,
	NVL((SELECT n44_valor
		FROM rolt043, rolt044
		WHERE n43_compania      = n30_compania
		  AND n43_estado        = 'P'
		  AND YEAR(n43_fecing)  = n32_ano_proceso
		  AND MONTH(n43_fecing) = n32_mes_proceso
		  AND n44_compania      = n43_compania
		  AND n44_num_rol       = n43_num_rol
		  AND n44_cod_trab      = n30_cod_trab), 0) AS VALOR_UV
        FROM rolt030, gent034, rolt032, rolt033
        WHERE n30_compania    = 1
	  AND g34_compania    = n30_compania
	  AND g34_cod_depto   = n30_cod_depto
          AND n32_compania    = n30_compania
          AND n32_cod_liqrol IN ('Q1', 'Q2')
          AND n32_cod_trab    = n30_cod_trab
          AND n32_estado     <> 'E'
	  AND n33_compania    = n32_compania
          AND n33_cod_liqrol  = n32_cod_liqrol
          AND n33_fecha_ini   = n32_fecha_ini
          AND n33_fecha_fin   = n32_fecha_fin
          AND n33_cod_trab    = n32_cod_trab
          AND n33_valor       > 0
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14
	ORDER BY 2, 3, 4;

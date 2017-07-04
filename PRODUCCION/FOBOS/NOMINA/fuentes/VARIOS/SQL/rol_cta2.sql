SELECT n03_nombre AS cod_rol, n32_ano_proceso AS anio,
	CASE
		WHEN n32_mes_proceso = 01 THEN "ENERO"
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
	END AS MES,
	n32_cod_trab AS cod_emp, g09_numero_cta AS cuenta_empresa,
	CASE WHEN n32_cod_trab = 24
		THEN '0920503067'
		ELSE n30_num_doc_id
	END AS cedula,
	CASE WHEN n32_cod_trab = 24
		THEN 'CHILA RUA EMILIANO FRANCISCO'
		ELSE n30_nombres
	END AS empleados,
	n32_cta_trabaj AS cuenta_empl, n32_tot_neto AS neto_recibir
	FROM rolt032, rolt030, gent009, rolt003
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ('Q1', 'Q2')
	  AND n32_estado     <> 'E'
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
	  AND g09_compania    = n32_compania
	  AND g09_banco       = n32_bco_empresa
	  AND n03_proceso     = n32_cod_liqrol
	UNION
	SELECT n03_nombre AS cod_rol, n36_ano_proceso AS anio,
		CASE
			WHEN n36_mes_proceso = 01 THEN "ENERO"
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
		END AS MES,
		n36_cod_trab AS cod_emp, g09_numero_cta AS cuenta_empresa,
		CASE WHEN n36_cod_trab = 24
			THEN '0920503067'
			ELSE n30_num_doc_id
		END AS cedula,
		CASE WHEN n36_cod_trab = 24
			THEN 'CHILA RUA EMILIANO FRANCISCO'
			ELSE n30_nombres
		END AS empleados, n36_cta_trabaj AS cuenta_empl,
		n36_valor_neto AS neto_recibir
		FROM rolt036, rolt030, gent009, rolt003
		WHERE n36_compania    = 1
		  AND n36_proceso    IN ('DC', 'DT')
		  AND n36_estado     <> 'E'
		  AND n30_compania    = n36_compania
		  AND n30_cod_trab    = n36_cod_trab
		  AND g09_compania    = n36_compania
		  AND g09_banco       = n36_bco_empresa
		  AND n03_proceso     = n36_proceso
	UNION
	SELECT n03_nombre AS cod_rol, n41_ano AS anio,
		CASE
			WHEN MONTH(n41_fecing) = 01 THEN "ENERO"
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
		END AS MES,
		n42_cod_trab AS cod_emp, g09_numero_cta AS cuenta_empresa,
		CASE WHEN n42_cod_trab = 24
			THEN '0920503067'
			ELSE n30_num_doc_id
		END AS cedula,
		CASE WHEN n42_cod_trab = 24
			THEN 'CHILA RUA EMILIANO FRANCISCO'
			ELSE n30_nombres
		END AS empleados, n42_cta_trabaj AS cuenta_empl,
		(n42_val_trabaj + n42_val_cargas -
		(SELECT SUM(n49_valor)
			FROM rolt049
			WHERE n49_compania  = n42_compania
			  AND n49_proceso   = n42_proceso
			  AND n49_cod_trab  = n42_cod_trab
			  AND n49_fecha_ini = n42_fecha_ini
			  AND n49_fecha_fin = n42_fecha_fin))
		AS neto_recibir
		FROM rolt041, rolt042, rolt030, gent009, rolt003
		WHERE n41_compania    = 1
		  AND n41_proceso     = 'UT'
		  AND n41_estado     <> 'A'
		  AND n42_compania    = n41_compania
		  AND n42_proceso     = n41_proceso
		  AND n42_fecha_ini   = n41_fecha_ini
		  AND n42_fecha_fin   = n41_fecha_fin
		  AND n30_compania    = n42_compania
		  AND n30_cod_trab    = n42_cod_trab
		  AND g09_compania    = n42_compania
		  AND g09_banco       = n42_bco_empresa
		  AND n03_proceso     = n41_proceso
		ORDER BY 7;

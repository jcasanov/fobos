SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n32_ano_proceso AS anio,
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
	n32_cod_liqrol AS cod_lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n32_cod_liqrol) AS nom_lq,
	n32_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n32_compania
		  AND g34_cod_depto = n32_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n32_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n32_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n32_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n32_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM gent008
			WHERE g08_banco = n32_bco_empresa), "") AS bco,
	NVL(n32_cta_empresa, "") AS cta_emp,
	NVL(n32_cta_trabaj, "") AS cta_tra,
	n32_tot_gan AS val_g,
	n32_tot_egr * (-1) AS val_e,
	n32_tot_neto AS val_p,
	CASE WHEN n32_estado = "A" THEN "EN PROCESO"
	     WHEN n32_estado = "C" THEN "PROCESADO"
	     WHEN n32_estado = "E" THEN "ELIMINADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM rolt032, rolt030
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n36_ano_proceso AS anio,
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
	n36_proceso AS cod_lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n36_proceso) AS nom_lq,
	n36_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n36_compania
		  AND g34_cod_depto = n36_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n36_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n36_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n36_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n36_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM gent008
			WHERE g08_banco = n36_bco_empresa), "") AS bco,
	NVL(n36_cta_empresa, "") AS cta_emp,
	NVL(n36_cta_trabaj, "") AS cta_tra,
	n36_valor_bruto AS val_g,
	n36_descuentos * (-1) AS val_e,
	n36_valor_neto AS val_p,
	CASE WHEN n36_estado = "A" THEN "EN PROCESO"
	     WHEN n36_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM rolt036, rolt030
	WHERE n36_compania  = 1
	  AND n36_proceso  IN ("DC", "DT")
	  AND n30_compania  = n36_compania
	  AND n30_cod_trab  = n36_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n41_ano AS anio,
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
	n42_proceso AS cod_lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n42_proceso) AS nom_lq,
	n42_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n42_compania
		  AND g34_cod_depto = n42_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n42_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n42_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n42_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n42_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM gent008
			WHERE g08_banco = n42_bco_empresa), "") AS bco,
	NVL(n42_cta_empresa, "") AS cta_emp,
	NVL(n42_cta_trabaj, "") AS cta_tra,
	(n42_val_trabaj + n42_val_cargas) AS val_g,
	n42_descuentos * (-1) AS val_e,
	(n42_val_trabaj + n42_val_cargas - n42_descuentos) AS val_p,
	CASE WHEN n41_estado = "A" THEN "EN PROCESO"
	     WHEN n41_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM rolt041, rolt042, rolt030
	WHERE n41_compania  = 1
	  AND n41_proceso   = "UT"
	  AND n42_compania  = n41_compania
	  AND n42_proceso   = n41_proceso
	  AND n42_fecha_ini = n41_fecha_ini
	  AND n42_fecha_fin = n41_fecha_fin
	  AND n30_compania  = n42_compania
	  AND n30_cod_trab  = n42_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	YEAR(n43_fecing) AS anio,
	CASE WHEN MONTH(n43_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n43_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n43_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n43_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n43_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n43_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n43_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n43_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n43_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n43_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n43_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n43_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"UV" AS cod_lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = "UV") AS nom_lq,
	n44_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n44_compania
		  AND g34_cod_depto = n44_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n44_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n44_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n44_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n44_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM gent008
			WHERE g08_banco = n44_bco_empresa), "") AS bco,
	NVL(n44_cta_empresa, "") AS cta_emp,
	NVL(n44_cta_trabaj, "") AS cta_tra,
	n44_valor AS val_g,
	0.00 AS val_e,
	n44_valor AS val_p,
	CASE WHEN n43_estado = "A" THEN "EN PROCESO"
	     WHEN n43_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM rolt043, rolt044, rolt030
	WHERE n43_compania = 1
	  AND n44_compania = n43_compania
	  AND n44_num_rol  = n43_num_rol
	  AND n30_compania = n44_compania
	  AND n30_cod_trab = n44_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n39_ano_proceso AS anio,
	CASE WHEN n39_mes_proceso = 01 THEN "ENERO"
	     WHEN n39_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n39_mes_proceso = 03 THEN "MARZO"
	     WHEN n39_mes_proceso = 04 THEN "ABRIL"
	     WHEN n39_mes_proceso = 05 THEN "MAYO"
	     WHEN n39_mes_proceso = 06 THEN "JUNIO"
	     WHEN n39_mes_proceso = 07 THEN "JULIO"
	     WHEN n39_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n39_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n39_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n39_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n39_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n39_proceso AS cod_lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n39_proceso) AS nom_lq,
	n39_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n39_compania
		  AND g34_cod_depto = n39_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n39_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n39_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n39_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n39_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM gent008
			WHERE g08_banco = n39_bco_empresa), "") AS bco,
	NVL(n39_cta_empresa, "") AS cta_emp,
	NVL(n39_cta_trabaj, "") AS cta_tra,
	(n39_valor_vaca + n39_valor_adic) AS val_g,
	NVL((SELECT SUM(n40_valor * (-1))
		FROM rolt040
		WHERE n40_compania    = n39_compania
		  AND n40_proceso     = n39_proceso
		  AND n40_cod_trab    = n39_cod_trab
		  AND n40_periodo_ini = n39_periodo_ini
		  AND n40_periodo_fin = n39_periodo_fin), 0.00) AS val_e,
	n39_neto AS val_p,
	CASE WHEN n39_estado = "A" THEN "EN PROCESO"
	     WHEN n39_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM rolt039, rolt030
	WHERE n39_compania  = 1
	  AND n39_proceso  IN ("VA", "VP")
	  AND n30_compania  = n39_compania
	  AND n30_cod_trab  = n39_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n48_ano_proceso AS anio,
	CASE WHEN n48_mes_proceso = 01 THEN "ENERO"
	     WHEN n48_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n48_mes_proceso = 03 THEN "MARZO"
	     WHEN n48_mes_proceso = 04 THEN "ABRIL"
	     WHEN n48_mes_proceso = 05 THEN "MAYO"
	     WHEN n48_mes_proceso = 06 THEN "JUNIO"
	     WHEN n48_mes_proceso = 07 THEN "JULIO"
	     WHEN n48_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n48_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n48_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n48_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n48_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n48_cod_liqrol AS cod_lq,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n48_cod_liqrol) AS nom_lq,
	n48_cod_trab AS cod_t,
	n30_nombres AS empl,
	"JUBILADOS" AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n48_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n48_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n48_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n48_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM gent008
			WHERE g08_banco = n48_bco_empresa), "") AS bco,
	NVL(n48_cta_empresa, "") AS cta_emp,
	NVL(n48_cta_trabaj, "") AS cta_tra,
	n48_val_jub_pat AS val_g,
	0.00 AS val_e,
	n48_val_jub_pat AS val_p,
	CASE WHEN n48_estado = "A" THEN "EN PROCESO"
	     WHEN n48_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM rolt048, rolt030
	WHERE n48_compania = 1
	  AND n48_proceso  = "JU"
	  AND n30_compania = n48_compania
	  AND n30_cod_trab = n48_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n32_ano_proceso AS anio,
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
	n32_cod_liqrol AS cod_lq,
	(SELECT n03_nombre_abr
		FROM acero_qm@idsuio01:rolt003
		WHERE n03_proceso = n32_cod_liqrol) AS nom_lq,
	n32_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n32_compania
		  AND g34_cod_depto = n32_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n32_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n32_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n32_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n32_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM acero_qm@idsuio01:gent008
			WHERE g08_banco = n32_bco_empresa), "") AS bco,
	NVL(n32_cta_empresa, "") AS cta_emp,
	NVL(n32_cta_trabaj, "") AS cta_tra,
	n32_tot_gan AS val_g,
	n32_tot_egr * (-1) AS val_e,
	n32_tot_neto AS val_p,
	CASE WHEN n32_estado = "A" THEN "EN PROCESO"
	     WHEN n32_estado = "C" THEN "PROCESADO"
	     WHEN n32_estado = "E" THEN "ELIMINADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM acero_qm@idsuio01:rolt032, acero_qm@idsuio01:rolt030
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n36_ano_proceso AS anio,
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
	n36_proceso AS cod_lq,
	(SELECT n03_nombre_abr
		FROM acero_qm@idsuio01:rolt003
		WHERE n03_proceso = n36_proceso) AS nom_lq,
	n36_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n36_compania
		  AND g34_cod_depto = n36_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n36_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n36_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n36_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n36_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM acero_qm@idsuio01:gent008
			WHERE g08_banco = n36_bco_empresa), "") AS bco,
	NVL(n36_cta_empresa, "") AS cta_emp,
	NVL(n36_cta_trabaj, "") AS cta_tra,
	n36_valor_bruto AS val_g,
	n36_descuentos * (-1) AS val_e,
	n36_valor_neto AS val_p,
	CASE WHEN n36_estado = "A" THEN "EN PROCESO"
	     WHEN n36_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM acero_qm@idsuio01:rolt036, acero_qm@idsuio01:rolt030
	WHERE n36_compania  = 1
	  AND n36_proceso  IN ("DC", "DT")
	  AND n30_compania  = n36_compania
	  AND n30_cod_trab  = n36_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n41_ano AS anio,
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
	n42_proceso AS cod_lq,
	(SELECT n03_nombre_abr
		FROM acero_qm@idsuio01:rolt003
		WHERE n03_proceso = n42_proceso) AS nom_lq,
	n42_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n42_compania
		  AND g34_cod_depto = n42_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n42_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n42_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n42_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n42_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM acero_qm@idsuio01:gent008
			WHERE g08_banco = n42_bco_empresa), "") AS bco,
	NVL(n42_cta_empresa, "") AS cta_emp,
	NVL(n42_cta_trabaj, "") AS cta_tra,
	(n42_val_trabaj + n42_val_cargas) AS val_g,
	n42_descuentos * (-1) AS val_e,
	(n42_val_trabaj + n42_val_cargas - n42_descuentos) AS val_p,
	CASE WHEN n41_estado = "A" THEN "EN PROCESO"
	     WHEN n41_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM acero_qm@idsuio01:rolt041, acero_qm@idsuio01:rolt042, acero_qm@idsuio01:rolt030
	WHERE n41_compania  = 1
	  AND n41_proceso   = "UT"
	  AND n42_compania  = n41_compania
	  AND n42_proceso   = n41_proceso
	  AND n42_fecha_ini = n41_fecha_ini
	  AND n42_fecha_fin = n41_fecha_fin
	  AND n30_compania  = n42_compania
	  AND n30_cod_trab  = n42_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	YEAR(n43_fecing) AS anio,
	CASE WHEN MONTH(n43_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n43_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n43_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n43_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n43_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n43_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n43_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n43_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n43_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n43_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n43_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n43_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"UV" AS cod_lq,
	(SELECT n03_nombre_abr
		FROM acero_qm@idsuio01:rolt003
		WHERE n03_proceso = "UV") AS nom_lq,
	n44_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n44_compania
		  AND g34_cod_depto = n44_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n44_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n44_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n44_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n44_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM acero_qm@idsuio01:gent008
			WHERE g08_banco = n44_bco_empresa), "") AS bco,
	NVL(n44_cta_empresa, "") AS cta_emp,
	NVL(n44_cta_trabaj, "") AS cta_tra,
	n44_valor AS val_g,
	0.00 AS val_e,
	n44_valor AS val_p,
	CASE WHEN n43_estado = "A" THEN "EN PROCESO"
	     WHEN n43_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM acero_qm@idsuio01:rolt043, acero_qm@idsuio01:rolt044, acero_qm@idsuio01:rolt030
	WHERE n43_compania = 1
	  AND n44_compania = n43_compania
	  AND n44_num_rol  = n43_num_rol
	  AND n30_compania = n44_compania
	  AND n30_cod_trab = n44_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n39_ano_proceso AS anio,
	CASE WHEN n39_mes_proceso = 01 THEN "ENERO"
	     WHEN n39_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n39_mes_proceso = 03 THEN "MARZO"
	     WHEN n39_mes_proceso = 04 THEN "ABRIL"
	     WHEN n39_mes_proceso = 05 THEN "MAYO"
	     WHEN n39_mes_proceso = 06 THEN "JUNIO"
	     WHEN n39_mes_proceso = 07 THEN "JULIO"
	     WHEN n39_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n39_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n39_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n39_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n39_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n39_proceso AS cod_lq,
	(SELECT n03_nombre_abr
		FROM acero_qm@idsuio01:rolt003
		WHERE n03_proceso = n39_proceso) AS nom_lq,
	n39_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n39_compania
		  AND g34_cod_depto = n39_cod_depto) AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n39_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n39_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n39_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n39_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM acero_qm@idsuio01:gent008
			WHERE g08_banco = n39_bco_empresa), "") AS bco,
	NVL(n39_cta_empresa, "") AS cta_emp,
	NVL(n39_cta_trabaj, "") AS cta_tra,
	(n39_valor_vaca + n39_valor_adic) AS val_g,
	NVL((SELECT SUM(n40_valor * (-1))
		FROM acero_qm@idsuio01:rolt040
		WHERE n40_compania    = n39_compania
		  AND n40_proceso     = n39_proceso
		  AND n40_cod_trab    = n39_cod_trab
		  AND n40_periodo_ini = n39_periodo_ini
		  AND n40_periodo_fin = n39_periodo_fin), 0.00) AS val_e,
	n39_neto AS val_p,
	CASE WHEN n39_estado = "A" THEN "EN PROCESO"
	     WHEN n39_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM acero_qm@idsuio01:rolt039, acero_qm@idsuio01:rolt030
	WHERE n39_compania  = 1
	  AND n39_proceso  IN ("VA", "VP")
	  AND n30_compania  = n39_compania
	  AND n30_cod_trab  = n39_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS loc,
	n48_ano_proceso AS anio,
	CASE WHEN n48_mes_proceso = 01 THEN "ENERO"
	     WHEN n48_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n48_mes_proceso = 03 THEN "MARZO"
	     WHEN n48_mes_proceso = 04 THEN "ABRIL"
	     WHEN n48_mes_proceso = 05 THEN "MAYO"
	     WHEN n48_mes_proceso = 06 THEN "JUNIO"
	     WHEN n48_mes_proceso = 07 THEN "JULIO"
	     WHEN n48_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n48_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n48_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n48_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n48_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n48_cod_liqrol AS cod_lq,
	(SELECT n03_nombre_abr
		FROM acero_qm@idsuio01:rolt003
		WHERE n03_proceso = n48_cod_liqrol) AS nom_lq,
	n48_cod_trab AS cod_t,
	n30_nombres AS empl,
	"JUBILADOS" AS depto,
	CASE WHEN n30_tipo_doc_id = "C" THEN "CEDULA"
	     WHEN n30_tipo_doc_id = "R" THEN "RUC"
	     WHEN n30_tipo_doc_id = "P" THEN "PASAPORTE"
	END AS tip_d,
	n30_num_doc_id AS ced,
	CASE WHEN n48_tipo_pago = "E" THEN "EFECTIVO"
	     WHEN n48_tipo_pago = "C" THEN "CHEQUE"
	     WHEN n48_tipo_pago = "T" THEN "TRANSFERENCIA"
	END AS tip_pg,
	NVL(LPAD(n48_bco_empresa, 2, 0) || " " ||
		(SELECT TRIM(g08_nombre)
			FROM acero_qm@idsuio01:gent008
			WHERE g08_banco = n48_bco_empresa), "") AS bco,
	NVL(n48_cta_empresa, "") AS cta_emp,
	NVL(n48_cta_trabaj, "") AS cta_tra,
	n48_val_jub_pat AS val_g,
	0.00 AS val_e,
	n48_val_jub_pat AS val_p,
	CASE WHEN n48_estado = "A" THEN "EN PROCESO"
	     WHEN n48_estado = "P" THEN "PROCESADO"
	END AS est_p,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_t
	FROM acero_qm@idsuio01:rolt048, acero_qm@idsuio01:rolt030
	WHERE n48_compania = 1
	  AND n48_proceso  = "JU"
	  AND n30_compania = n48_compania
	  AND n30_cod_trab = n48_cod_trab;

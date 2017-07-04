SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS local,
	a.n36_ano_proceso AS anio,
	CASE WHEN a.n36_mes_proceso = 01 THEN "ENERO"
	     WHEN a.n36_mes_proceso = 02 THEN "FEBRERO"
	     WHEN a.n36_mes_proceso = 03 THEN "MARZO"
	     WHEN a.n36_mes_proceso = 04 THEN "ABRIL"
	     WHEN a.n36_mes_proceso = 05 THEN "MAYO"
	     WHEN a.n36_mes_proceso = 06 THEN "JUNIO"
	     WHEN a.n36_mes_proceso = 07 THEN "JULIO"
	     WHEN a.n36_mes_proceso = 08 THEN "AGOSTO"
	     WHEN a.n36_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN a.n36_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN a.n36_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN a.n36_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	"OT" AS cod_lq,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n36_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = a.n36_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n36_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = a.n36_compania
		  AND g34_cod_depto = a.n36_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n36_estado = "A" THEN "EN PROCESO"
	     WHEN a.n36_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"05 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n36_valor_bruto)
		FROM rolt036 b
		WHERE b.n36_compania    = a.n36_compania
		  AND b.n36_proceso     = a.n36_proceso
		  AND b.n36_ano_proceso = a.n36_ano_proceso - 1
		  AND b.n36_mes_proceso = a.n36_mes_proceso
		  AND b.n36_cod_trab    = a.n36_cod_trab)), 0) AS val_ant,
	SUM(a.n36_valor_bruto) AS val_p
	FROM rolt036 a, rolt030
	WHERE a.n36_compania  = 1
	  AND a.n36_proceso  IN ("DT", "DC")
	  AND n30_compania    = a.n36_compania
	  AND n30_cod_trab    = a.n36_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS local,
	a.n36_ano_proceso AS anio,
	CASE WHEN a.n36_mes_proceso = 01 THEN "ENERO"
	     WHEN a.n36_mes_proceso = 02 THEN "FEBRERO"
	     WHEN a.n36_mes_proceso = 03 THEN "MARZO"
	     WHEN a.n36_mes_proceso = 04 THEN "ABRIL"
	     WHEN a.n36_mes_proceso = 05 THEN "MAYO"
	     WHEN a.n36_mes_proceso = 06 THEN "JUNIO"
	     WHEN a.n36_mes_proceso = 07 THEN "JULIO"
	     WHEN a.n36_mes_proceso = 08 THEN "AGOSTO"
	     WHEN a.n36_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN a.n36_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN a.n36_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN a.n36_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	"OT" AS cod_lq,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n36_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = a.n36_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n36_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = a.n36_compania
		  AND g34_cod_depto = a.n36_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n36_estado = "A" THEN "EN PROCESO"
	     WHEN a.n36_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"06 OTROS EGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n36_descuentos * (-1))
		FROM rolt036 b
		WHERE b.n36_compania    = a.n36_compania
		  AND b.n36_proceso     = a.n36_proceso
		  AND b.n36_ano_proceso = a.n36_ano_proceso - 1
		  AND b.n36_mes_proceso = a.n36_mes_proceso
		  AND b.n36_cod_trab    = a.n36_cod_trab)), 0) AS val_ant,
	SUM(a.n36_descuentos * (-1)) AS val_p
	FROM rolt036 a, rolt030
	WHERE a.n36_compania    = 1
	  AND a.n36_proceso    IN ("DT", "DC")
	  AND a.n36_descuentos  > 0
	  AND n30_compania      = a.n36_compania
	  AND n30_cod_trab      = a.n36_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS local,
	a.n42_ano AS anio,
	"ABRIL" AS mes,
	"OT" AS cod_lq,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n42_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = a.n42_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n42_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = a.n42_compania
		  AND g34_cod_depto = a.n42_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN n41_estado = "A" THEN "EN PROCESO"
	     WHEN n41_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"05 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n42_val_trabaj + b.n42_val_cargas)
		FROM rolt042 b
		WHERE b.n42_compania = a.n42_compania
		  AND b.n42_proceso  = a.n42_proceso
		  AND b.n42_ano      = a.n42_ano - 1
		  AND b.n42_cod_trab = a.n42_cod_trab)), 0) AS val_ant,
	SUM(a.n42_val_trabaj + a.n42_val_cargas) AS val_p
	FROM rolt042 a, rolt041, rolt030
	WHERE a.n42_compania = 1
	  AND a.n42_proceso  = "UT"
	  AND n41_compania   = a.n42_compania
	  AND n41_proceso    = a.n42_proceso
	  AND n41_fecha_ini  = a.n42_fecha_ini
	  AND n41_fecha_fin  = a.n42_fecha_fin
	  AND n30_compania   = a.n42_compania
	  AND n30_cod_trab   = a.n42_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS local,
	a.n42_ano AS anio,
	"ABRIL" AS mes,
	"OT" AS cod_lq,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n42_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = a.n42_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n42_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = a.n42_compania
		  AND g34_cod_depto = a.n42_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN n41_estado = "A" THEN "EN PROCESO"
	     WHEN n41_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"06 OTROS EGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n42_descuentos * (-1))
		FROM rolt042 b
		WHERE b.n42_compania = a.n42_compania
		  AND b.n42_proceso  = a.n42_proceso
		  AND b.n42_ano      = a.n42_ano - 1
		  AND b.n42_cod_trab = a.n42_cod_trab)), 0) AS val_ant,
	SUM(a.n42_descuentos * (-1)) AS val_p
	FROM rolt042 a, rolt041, rolt030
	WHERE a.n42_compania   = 1
	  AND a.n42_proceso    = "UT"
	  AND a.n42_descuentos > 0
	  AND n41_compania     = a.n42_compania
	  AND n41_proceso      = a.n42_proceso
	  AND n41_fecha_ini    = a.n42_fecha_ini
	  AND n41_fecha_fin    = a.n42_fecha_fin
	  AND n30_compania     = a.n42_compania
	  AND n30_cod_trab     = a.n42_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS local,
	YEAR(a.n38_fecha_fin) AS anio,
	CASE WHEN MONTH(a.n38_fecha_fin) = 01 THEN "ENERO"
	     WHEN MONTH(a.n38_fecha_fin) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.n38_fecha_fin) = 03 THEN "MARZO"
	     WHEN MONTH(a.n38_fecha_fin) = 04 THEN "ABRIL"
	     WHEN MONTH(a.n38_fecha_fin) = 05 THEN "MAYO"
	     WHEN MONTH(a.n38_fecha_fin) = 06 THEN "JUNIO"
	     WHEN MONTH(a.n38_fecha_fin) = 07 THEN "JULIO"
	     WHEN MONTH(a.n38_fecha_fin) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.n38_fecha_fin) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.n38_fecha_fin) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.n38_fecha_fin) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.n38_fecha_fin) = 12 THEN "DICIEMBRE"
	END AS mes,
	"OT" AS cod_lq,
	"OTROS INGRESOS" AS nom_lq,
	LPAD("FR", 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = "FR") AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	n30_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n38_estado = "A" THEN "EN PROCESO"
	     WHEN a.n38_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"05 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n38_valor_fondo)
		FROM rolt038 b
		WHERE b.n38_compania  = a.n38_compania
		  AND b.n38_fecha_ini = CASE WHEN a.n38_fecha_ini <
							MDY(08, 01, 2009)
						THEN a.n38_fecha_ini
							- 1 UNITS YEAR
						ELSE a.n38_fecha_ini
							- 1 UNITS MONTH
					END
		  AND b.n38_fecha_fin = CASE WHEN a.n38_fecha_fin <
							MDY(08, 31, 2009)
						THEN a.n38_fecha_fin
							- 1 UNITS YEAR
						ELSE MDY(MONTH(a.n38_fecha_fin),
							01,
							YEAR(a.n38_fecha_fin))
							- 1 UNITS DAY
					END
		  AND b.n38_cod_trab  = a.n38_cod_trab)), 0) AS val_ant,
	SUM(a.n38_valor_fondo) AS val_p
	FROM rolt038 a, rolt030
	WHERE a.n38_compania  = 1
	  AND a.n38_pago_iess = "S"
	  AND n30_compania    = a.n38_compania
	  AND n30_cod_trab    = a.n38_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS local,
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
	"OT" AS cod_lq,
	"OTROS INGRESOS" AS nom_lq,
	LPAD("UV", 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = "UV") AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n44_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = a.n44_compania
		  AND g34_cod_depto = a.n44_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN n43_estado = "A" THEN "EN PROCESO"
	     WHEN n43_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"05 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n44_valor)
		FROM rolt044 b
		WHERE b.n44_compania = a.n44_compania
		  AND b.n44_num_rol  = a.n44_num_rol - 1
		  AND b.n44_cod_trab = a.n44_cod_trab)), 0) AS val_ant,
	SUM(a.n44_valor) AS val_p
	FROM rolt043, rolt044 a, rolt030
	WHERE n43_compania    = 1
	  AND a.n44_compania  = n43_compania
	  AND a.n44_num_rol   = n43_num_rol
	  AND n30_compania    = a.n44_compania
	  AND n30_cod_trab    = a.n44_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14;

SELECT a.n32_ano_proceso AS anio,
	CASE WHEN a.n32_mes_proceso = 01 THEN "ENERO"
	     WHEN a.n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN a.n32_mes_proceso = 03 THEN "MARZO"
	     WHEN a.n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN a.n32_mes_proceso = 05 THEN "MAYO"
	     WHEN a.n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN a.n32_mes_proceso = 07 THEN "JULIO"
	     WHEN a.n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN a.n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN a.n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN a.n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN a.n32_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	a.n32_cod_liqrol AS cod_lq,
	a.n32_fecha_fin AS fec_pro,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n32_cod_liqrol) AS nom_lq,
	LPAD(b.n33_cod_rubro, 3, 0) AS cod_r,
	(SELECT n06_nombre
		FROM acero_qm:rolt006
		WHERE n06_cod_rubro = b.n33_cod_rubro) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n32_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = a.n32_compania
		  AND g34_cod_depto = a.n32_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n32_estado = "A" THEN "EN PROCESO"
	     WHEN a.n32_estado = "C" THEN "PROCESADO"
	     WHEN a.n32_estado = "E" THEN "ELIMINADO"
	END AS est_p,
	CASE WHEN (b.n33_det_tot = "DI" AND
		(SELECT COUNT(*)
			FROM acero_qm:rolt008,
				acero_qm:rolt006
			WHERE n08_rubro_base  = b.n33_cod_rubro
			  AND n06_cod_rubro   = n08_cod_rubro
			  AND n06_flag_ident IN ("AP", "EC")) > 0)
		THEN "01 INGRESOS AL EMPLEADO GRAVABLE IESS"
	     WHEN b.n33_cod_rubro = 125 OR
			(b.n33_cod_rubro =
			(SELECT n06_cod_rubro
				FROM acero_qm:rolt006
				WHERE n06_flag_ident = "AP")) OR
			(b.n33_cod_rubro =
			(SELECT n06_cod_rubro
				FROM acero_qm:rolt006
				WHERE n06_flag_ident = "EC"))
		THEN "02 APORTES DEL EMPLEADO AL IESS"
	     WHEN b.n33_det_tot = "DE" OR b.n33_cod_rubro = 38 OR
			b.n33_cod_rubro = 39 OR
			(b.n33_cod_rubro =
			(SELECT n06_cod_rubro
				FROM acero_qm:rolt006
				WHERE n06_flag_ident = "SI")) OR
			(b.n33_cod_rubro =
			(SELECT n06_cod_rubro
				FROM acero_qm:rolt006
				WHERE n06_flag_ident = "OI")) OR
			(b.n33_cod_rubro =
			(SELECT n06_cod_rubro
				FROM acero_qm:rolt006
				WHERE n06_flag_ident = "E1")) OR
			(b.n33_cod_rubro =
			(SELECT n06_cod_rubro
				FROM acero_qm:rolt006
				WHERE n06_flag_ident = "AG"))
		THEN "03 EGRESOS DEL EMPLEADO"
	     WHEN (b.n33_det_tot = "DI" AND
		(SELECT COUNT(*)
			FROM acero_qm:rolt008,
				acero_qm:rolt006
			WHERE n08_rubro_base  = b.n33_cod_rubro
			  AND n06_cod_rubro   = n08_cod_rubro
			  AND n06_flag_ident IN ("AP", "EC")) = 0)
		THEN "04 OTROS INGRESOS AL EMPLEADO"
	END AS tip_rol,
	NVL(SUM((SELECT SUM(CASE WHEN b.n33_det_tot = "DI"
					THEN c.n33_valor
					ELSE c.n33_valor * (-1)
				END)
		FROM acero_qm:rolt033 c
		WHERE c.n33_compania    = b.n33_compania
		  AND c.n33_cod_liqrol  = b.n33_cod_liqrol
		  AND c.n33_fecha_ini   = (b.n33_fecha_ini - 1 UNITS MONTH)
		  AND c.n33_fecha_fin   = CASE WHEN DAY(b.n33_fecha_fin) = 15
						THEN b.n33_fecha_fin
							- 1 UNITS MONTH
						ELSE MDY(MONTH(b.n33_fecha_fin),
							01,
							YEAR(b.n33_fecha_fin))
							- 1 UNITS DAY
					  END
		  AND c.n33_cod_trab    = b.n33_cod_trab
		  AND c.n33_cod_rubro   = b.n33_cod_rubro
		  AND c.n33_det_tot     = b.n33_det_tot
		  AND c.n33_cant_valor  = b.n33_cant_valor
		  AND c.n33_valor       > 0)), 0) AS val_ant,
	SUM(CASE WHEN b.n33_det_tot = "DI"
			THEN b.n33_valor
			ELSE b.n33_valor * (-1)
		END) AS val_p
	FROM acero_qm:rolt032 a,
		acero_qm:rolt033 b,
		acero_qm:rolt030
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= MDY(01, 01, 2010)
	  AND b.n33_compania    = a.n32_compania
	  AND b.n33_cod_liqrol  = a.n32_cod_liqrol
	  AND b.n33_fecha_ini   = a.n32_fecha_ini
	  AND b.n33_fecha_fin   = a.n32_fecha_fin
	  AND b.n33_cod_trab    = a.n32_cod_trab
	  AND b.n33_det_tot    IN ("DI", "DE")
	  AND b.n33_cant_valor  = "V"
	  AND b.n33_valor       > 0
	  AND n30_compania      = b.n33_compania
	  AND n30_cod_trab      = b.n33_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT a.n48_ano_proceso AS anio,
	CASE WHEN a.n48_mes_proceso = 01 THEN "ENERO"
	     WHEN a.n48_mes_proceso = 02 THEN "FEBRERO"
	     WHEN a.n48_mes_proceso = 03 THEN "MARZO"
	     WHEN a.n48_mes_proceso = 04 THEN "ABRIL"
	     WHEN a.n48_mes_proceso = 05 THEN "MAYO"
	     WHEN a.n48_mes_proceso = 06 THEN "JUNIO"
	     WHEN a.n48_mes_proceso = 07 THEN "JULIO"
	     WHEN a.n48_mes_proceso = 08 THEN "AGOSTO"
	     WHEN a.n48_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN a.n48_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN a.n48_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN a.n48_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	a.n48_proceso AS cod_lq,
	a.n48_fecha_fin AS fec_pro,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n48_proceso) AS nom_lq,
	LPAD(a.n48_cod_liqrol, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n48_cod_liqrol) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	n30_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n48_estado = "A" THEN "EN PROCESO"
	     WHEN a.n48_estado = "P" THEN "PROCESADO"
	     WHEN a.n48_estado = "E" THEN "ELIMINADO"
	END AS est_p,
	"05 INGRESOS AL EMPLEADO JUBILADO" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n48_val_jub_pat)
		FROM acero_qm:rolt048 b
		WHERE b.n48_compania    = a.n48_compania
		  AND b.n48_proceso     = a.n48_proceso
		  AND b.n48_cod_liqrol  = a.n48_cod_liqrol
		  AND b.n48_fecha_ini   = (a.n48_fecha_ini - 1 UNITS MONTH)
		  AND b.n48_fecha_fin   = CASE WHEN DAY(a.n48_fecha_fin) = 15
						THEN a.n48_fecha_fin
							- 1 UNITS MONTH
						ELSE MDY(MONTH(a.n48_fecha_fin),
							01,
							YEAR(a.n48_fecha_fin))
							- 1 UNITS DAY
					  END
		  AND b.n48_cod_trab    = a.n48_cod_trab)), 0) AS val_ant,
	SUM(a.n48_val_jub_pat) AS val_p
	FROM acero_qm:rolt048 a, acero_qm:rolt030
	WHERE a.n48_compania     = 1
	  AND a.n48_proceso      = "JU"
	  AND a.n48_ano_proceso >= 2010
	  AND n30_compania       = a.n48_compania
	  AND n30_cod_trab       = a.n48_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT a.n36_ano_proceso AS anio,
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
	a.n36_fecha_fin AS fec_pro,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n36_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n36_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n36_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = a.n36_compania
		  AND g34_cod_depto = a.n36_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n36_estado = "A" THEN "EN PROCESO"
	     WHEN a.n36_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"06 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n36_valor_bruto)
		FROM acero_qm:rolt036 b
		WHERE b.n36_compania    = a.n36_compania
		  AND b.n36_proceso     = a.n36_proceso
		  AND b.n36_ano_proceso = a.n36_ano_proceso - 1
		  AND b.n36_mes_proceso = a.n36_mes_proceso
		  AND b.n36_cod_trab    = a.n36_cod_trab)), 0) AS val_ant,
	SUM(a.n36_valor_bruto) AS val_p
	FROM acero_qm:rolt036 a, acero_qm:rolt030
	WHERE a.n36_compania     = 1
	  AND a.n36_proceso     IN ("DT", "DC")
	  AND a.n36_ano_proceso >= 2010
	  AND n30_compania       = a.n36_compania
	  AND n30_cod_trab       = a.n36_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT a.n36_ano_proceso AS anio,
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
	a.n36_fecha_fin AS fec_pro,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n36_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n36_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n36_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = a.n36_compania
		  AND g34_cod_depto = a.n36_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n36_estado = "A" THEN "EN PROCESO"
	     WHEN a.n36_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"07 OTROS EGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n36_descuentos * (-1))
		FROM acero_qm:rolt036 b
		WHERE b.n36_compania    = a.n36_compania
		  AND b.n36_proceso     = a.n36_proceso
		  AND b.n36_ano_proceso = a.n36_ano_proceso - 1
		  AND b.n36_mes_proceso = a.n36_mes_proceso
		  AND b.n36_cod_trab    = a.n36_cod_trab)), 0) AS val_ant,
	SUM(a.n36_descuentos * (-1)) AS val_p
	FROM acero_qm:rolt036 a, acero_qm:rolt030
	WHERE a.n36_compania     = 1
	  AND a.n36_proceso     IN ("DT", "DC")
	  AND a.n36_ano_proceso >= 2010
	  AND a.n36_descuentos   > 0
	  AND n30_compania       = a.n36_compania
	  AND n30_cod_trab       = a.n36_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT YEAR(b.n41_fecing) AS anio,
	CASE WHEN MONTH(b.n41_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(b.n41_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(b.n41_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(b.n41_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(b.n41_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(b.n41_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(b.n41_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(b.n41_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(b.n41_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b.n41_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b.n41_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b.n41_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"OT" AS cod_lq,
	DATE(b.n41_fecing) AS fec_pro,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n42_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n42_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n42_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = a.n42_compania
		  AND g34_cod_depto = a.n42_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN b.n41_estado = "A" THEN "EN PROCESO"
	     WHEN b.n41_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"06 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(c.n42_val_trabaj + c.n42_val_cargas)
		FROM acero_qm:rolt042 c
		WHERE c.n42_compania  = a.n42_compania
		  AND c.n42_proceso   = a.n42_proceso
		  AND c.n42_cod_trab  = a.n42_cod_trab
		  AND c.n42_fecha_ini = a.n42_fecha_ini - 1 UNITS YEAR
		  AND c.n42_fecha_fin = a.n42_fecha_fin - 1 UNITS YEAR)),
		0) AS val_ant,
	SUM(a.n42_val_trabaj + a.n42_val_cargas) AS val_p
	FROM acero_qm:rolt042 a,
		acero_qm:rolt041 b,
		acero_qm:rolt030
	WHERE a.n42_compania   = 1
	  AND a.n42_proceso    = "UT"
	  AND a.n42_ano       >= 2009
	  AND b.n41_compania   = a.n42_compania
	  AND b.n41_proceso    = a.n42_proceso
	  AND b.n41_fecha_ini  = a.n42_fecha_ini
	  AND b.n41_fecha_fin  = a.n42_fecha_fin
	  AND n30_compania     = a.n42_compania
	  AND n30_cod_trab     = a.n42_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT YEAR(b.n41_fecing) AS anio,
	CASE WHEN MONTH(b.n41_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(b.n41_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(b.n41_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(b.n41_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(b.n41_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(b.n41_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(b.n41_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(b.n41_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(b.n41_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b.n41_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b.n41_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b.n41_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"OT" AS cod_lq,
	DATE(b.n41_fecing) AS fec_pro,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n42_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n42_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n42_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = a.n42_compania
		  AND g34_cod_depto = a.n42_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN b.n41_estado = "A" THEN "EN PROCESO"
	     WHEN b.n41_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"07 OTROS EGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(c.n42_descuentos * (-1))
		FROM acero_qm:rolt042 c
		WHERE c.n42_compania  = a.n42_compania
		  AND c.n42_proceso   = a.n42_proceso
		  AND c.n42_cod_trab  = a.n42_cod_trab
		  AND c.n42_fecha_ini = a.n42_fecha_ini - 1 UNITS YEAR
		  AND c.n42_fecha_fin = a.n42_fecha_fin - 1 UNITS YEAR)),
		0) AS val_ant,
	SUM(a.n42_descuentos * (-1)) AS val_p
	FROM acero_qm:rolt042 a,
		acero_qm:rolt041 b,
		acero_qm:rolt030
	WHERE a.n42_compania    = 1
	  AND a.n42_proceso     = "UT"
	  AND a.n42_ano        >= 2009
	  AND a.n42_descuentos  > 0
	  AND b.n41_compania    = a.n42_compania
	  AND b.n41_proceso     = a.n42_proceso
	  AND b.n41_fecha_ini   = a.n42_fecha_ini
	  AND b.n41_fecha_fin   = a.n42_fecha_fin
	  AND n30_compania      = a.n42_compania
	  AND n30_cod_trab      = a.n42_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT YEAR(a.n38_fecha_fin) AS anio,
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
	a.n38_fecha_fin AS fec_pro,
	"OTROS INGRESOS" AS nom_lq,
	LPAD("FR", 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = "FR") AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	n30_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n38_estado = "A" THEN "EN PROCESO"
	     WHEN a.n38_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"06 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n38_valor_fondo)
		FROM acero_qm:rolt038 b
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
	FROM acero_qm:rolt038 a, acero_qm:rolt030
	WHERE a.n38_compania         = 1
	  AND YEAR(a.n38_fecha_fin) >= 2010
	  AND a.n38_pago_iess        = "S"
	  AND n30_compania           = a.n38_compania
	  AND n30_cod_trab           = a.n38_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT YEAR(n43_fecing) AS anio,
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
	DATE(n43_fecing) AS fec_pro,
	"OTROS INGRESOS" AS nom_lq,
	LPAD("UV", 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = "UV") AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n44_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = a.n44_compania
		  AND g34_cod_depto = a.n44_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN n43_estado = "A" THEN "EN PROCESO"
	     WHEN n43_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"06 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n44_valor)
		FROM acero_qm:rolt044 b
		WHERE b.n44_compania = a.n44_compania
		  AND b.n44_num_rol  = a.n44_num_rol - 1
		  AND b.n44_cod_trab = a.n44_cod_trab)), 0) AS val_ant,
	SUM(a.n44_valor) AS val_p
	FROM acero_qm:rolt043,
		acero_qm:rolt044 a,
		acero_qm:rolt030
	WHERE n43_compania      = 1
	  AND n43_tributa       = "S"
	  AND YEAR(n43_fecing) >= 2010
	  AND a.n44_compania    = n43_compania
	  AND a.n44_num_rol     = n43_num_rol
	  AND n30_compania      = a.n44_compania
	  AND n30_cod_trab      = a.n44_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT YEAR(a.n39_fecing) AS anio,
	CASE WHEN MONTH(a.n39_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.n39_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.n39_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.n39_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.n39_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.n39_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.n39_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.n39_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.n39_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.n39_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.n39_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.n39_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"OT" AS cod_lq,
	DATE(a.n39_fecing) AS fec_pro,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n39_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n39_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n39_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = a.n39_compania
		  AND g34_cod_depto = a.n39_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n39_estado = "A" THEN "EN PROCESO"
	     WHEN a.n39_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"06 OTROS INGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n39_valor_vaca + b.n39_valor_adic
				+ b.n39_otros_ing)
		FROM acero_qm:rolt039 b
		WHERE b.n39_compania    = a.n39_compania
		  AND b.n39_proceso     = a.n39_proceso
		  AND EXTEND(b.n39_fecing, YEAR TO MONTH) =
			EXTEND(a.n39_fecing - 1 UNITS YEAR, YEAR TO MONTH)
		  AND b.n39_cod_trab    = a.n39_cod_trab)), 0) AS val_ant,
	SUM(a.n39_valor_vaca + a.n39_valor_adic + a.n39_otros_ing) AS val_p
	FROM acero_qm:rolt039 a, acero_qm:rolt030
	WHERE a.n39_compania      = 1
	  AND a.n39_proceso      IN ("VA", "VP")
	  AND YEAR(a.n39_fecing) >= 2010
	  AND n30_compania        = a.n39_compania
	  AND n30_cod_trab        = a.n39_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT YEAR(a.n39_fecing) AS anio,
	CASE WHEN MONTH(a.n39_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.n39_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.n39_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.n39_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.n39_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.n39_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.n39_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.n39_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.n39_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.n39_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.n39_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.n39_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"OT" AS cod_lq,
	DATE(a.n39_fecing) AS fec_pro,
	"OTROS INGRESOS" AS nom_lq,
	LPAD(a.n39_proceso, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM acero_qm:rolt003
		WHERE n03_proceso = a.n39_proceso) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n39_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM acero_qm:gent034
		WHERE g34_compania  = a.n39_compania
		  AND g34_cod_depto = a.n39_cod_depto) AS nom_dp,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est_e,
	CASE WHEN a.n39_estado = "A" THEN "EN PROCESO"
	     WHEN a.n39_estado = "P" THEN "PROCESADO"
	END AS est_p,
	"07 OTROS EGRESOS EMPLEADO ANUAL" AS tip_rol,
	NVL(SUM((SELECT SUM((b.n39_descto_iess + b.n39_otros_egr) * (-1))
		FROM acero_qm:rolt039 b
		WHERE b.n39_compania    = a.n39_compania
		  AND b.n39_proceso     = a.n39_proceso
		  AND EXTEND(b.n39_fecing, YEAR TO MONTH) =
			EXTEND(a.n39_fecing - 1 UNITS YEAR, YEAR TO MONTH)
		  AND b.n39_cod_trab    = a.n39_cod_trab)), 0) AS val_ant,
	SUM((a.n39_descto_iess + a.n39_otros_egr) * (-1)) AS val_p
	FROM acero_qm:rolt039 a, acero_qm:rolt030
	WHERE  a.n39_compania                        = 1
	  AND  a.n39_proceso                        IN ("VA", "VP")
	  AND  YEAR(a.n39_fecing)                   >= 2010
	  AND (a.n39_descto_iess + a.n39_otros_egr)  > 0
	  AND  n30_compania                          = a.n39_compania
	  AND  n30_cod_trab                          = a.n39_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14;

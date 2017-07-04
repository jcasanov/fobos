SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS local,
	a.n32_ano_proceso AS anio,
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
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = a.n32_cod_liqrol) AS nom_lq,
	LPAD(b.n33_cod_rubro, 3, 0) AS cod_r,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = b.n33_cod_rubro) AS nom_ru,
	n30_cod_trab AS cod_t,
	n30_nombres AS nom_t,
	a.n32_cod_depto AS cod_dp,
	(SELECT g34_nombre
		FROM gent034
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
			FROM rolt008, rolt006
			WHERE n08_rubro_base  = b.n33_cod_rubro
			  AND n06_cod_rubro   = n08_cod_rubro
			  AND n06_flag_ident IN ("AP", "EC")) > 0)
		THEN "01 INGRESOS AL EMPLEADO GRAVABLE IESS"
	     WHEN b.n33_det_tot = "DE"
		THEN "02 EGRESOS DEL EMPLEADO"
	     WHEN (b.n33_det_tot = "DI" AND
		(SELECT COUNT(*)
			FROM rolt008, rolt006
			WHERE n08_rubro_base  = b.n33_cod_rubro
			  AND n06_cod_rubro   = n08_cod_rubro
			  AND n06_flag_ident IN ("AP", "EC")) = 0)
		THEN "03 OTROS INGRESOS AL EMPLEADO"
	END AS tip_rol,
	NVL(SUM((SELECT SUM(CASE WHEN b.n33_det_tot = "DI"
					THEN c.n33_valor
					ELSE c.n33_valor * (-1)
				END)
		FROM rolt033 c
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
	FROM rolt032 a, rolt033 b, rolt030
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= MDY(08, 01, 2003)
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
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS local,
	a.n48_ano_proceso AS anio,
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
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = a.n48_proceso) AS nom_lq,
	LPAD(a.n48_cod_liqrol, 2, 0) AS cod_r,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = a.n48_cod_liqrol) AS nom_ru,
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
	CASE WHEN a.n48_estado = "A" THEN "EN PROCESO"
	     WHEN a.n48_estado = "P" THEN "PROCESADO"
	     WHEN a.n48_estado = "E" THEN "ELIMINADO"
	END AS est_p,
	"04 INGRESOS AL EMPLEADO JUBILADO" AS tip_rol,
	NVL(SUM((SELECT SUM(b.n48_val_jub_pat)
		FROM rolt048 b
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
	FROM rolt048 a, rolt030
	WHERE a.n48_compania = 1
	  AND a.n48_proceso  = "JU"
	  AND n30_compania   = a.n48_compania
	  AND n30_cod_trab   = a.n48_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14;

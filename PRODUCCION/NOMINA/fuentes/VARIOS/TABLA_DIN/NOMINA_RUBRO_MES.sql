SELECT (SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
		    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
		    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
		    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
			ELSE "OTROS"
		END
		FROM rolt030
		WHERE n30_compania = a.n32_compania
		  AND n30_cod_trab = a.n32_cod_trab) AS local,
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
	b.n33_cod_rubro AS cod_r,
	(SELECT d.n06_nombre
		FROM rolt006 d
		WHERE d.n06_cod_rubro = b.n33_cod_rubro) AS nom_ru,
	CASE WHEN a.n32_estado = "A" THEN "EN PROCESO"
	     WHEN a.n32_estado = "C" THEN "PROCESADO"
	     WHEN a.n32_estado = "E" THEN "ELIMINADO"
	END AS est_p,
	"01 INGRESOS AL EMPLEADO GRAVABLE IESS" AS tip_rol,
	NVL(SUM((SELECT SUM(c.n33_valor)
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
	SUM(b.n33_valor) AS val_p
	FROM rolt032 a, rolt033 b
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= MDY(08, 01, 2003)
	  AND b.n33_compania    = a.n32_compania
	  AND b.n33_cod_liqrol  = a.n32_cod_liqrol
	  AND b.n33_fecha_ini   = a.n32_fecha_ini
	  AND b.n33_fecha_fin   = a.n32_fecha_fin
	  AND b.n33_cod_trab    = a.n32_cod_trab
	  AND b.n33_det_tot     = "DI"
	  AND b.n33_cant_valor  = "V"
	  AND b.n33_valor       > 0
	  AND EXISTS
		(SELECT 1 FROM rolt008, rolt006
			WHERE n08_rubro_base  = b.n33_cod_rubro
			  AND n06_cod_rubro   = n08_cod_rubro
			  AND n06_flag_ident IN ("AP", "EC"))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT (SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
		    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
		    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
		    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
			ELSE "OTROS"
		END
		FROM rolt030
		WHERE n30_compania = a.n32_compania
		  AND n30_cod_trab = a.n32_cod_trab) AS local,
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
	b.n33_cod_rubro AS cod_r,
	(SELECT d.n06_nombre
		FROM rolt006 d
		WHERE d.n06_cod_rubro = b.n33_cod_rubro) AS nom_ru,
	CASE WHEN a.n32_estado = "A" THEN "EN PROCESO"
	     WHEN a.n32_estado = "C" THEN "PROCESADO"
	     WHEN a.n32_estado = "E" THEN "ELIMINADO"
	END AS est_p,
	"02 EGRESOS DEL EMPLEADO" AS tip_rol,
	NVL(SUM((SELECT SUM(c.n33_valor * (-1))
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
	SUM(b.n33_valor * (-1)) AS val_p
	FROM rolt032 a, rolt033 b, rolt006
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= MDY(08, 01, 2003)
	  AND b.n33_compania    = a.n32_compania
	  AND b.n33_cod_liqrol  = a.n32_cod_liqrol
	  AND b.n33_fecha_ini   = a.n32_fecha_ini
	  AND b.n33_fecha_fin   = a.n32_fecha_fin
	  AND b.n33_cod_trab    = a.n32_cod_trab
	  AND b.n33_det_tot     = "DE"
	  AND b.n33_cant_valor  = "V"
	  AND b.n33_valor       > 0
	  AND n06_cod_rubro     = b.n33_cod_rubro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT (SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
		    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
		    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
		    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
			ELSE "OTROS"
		END
		FROM rolt030
		WHERE n30_compania = a.n32_compania
		  AND n30_cod_trab = a.n32_cod_trab) AS local,
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
	b.n33_cod_rubro AS cod_r,
	(SELECT d.n06_nombre
		FROM rolt006 d
		WHERE d.n06_cod_rubro = b.n33_cod_rubro) AS nom_ru,
	CASE WHEN a.n32_estado = "A" THEN "EN PROCESO"
	     WHEN a.n32_estado = "C" THEN "PROCESADO"
	     WHEN a.n32_estado = "E" THEN "ELIMINADO"
	END AS est_p,
	"03 OTROS INGRESOS AL EMPLEADO" AS tip_rol,
	NVL(SUM((SELECT SUM(c.n33_valor)
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
	SUM(b.n33_valor) AS val_p
	FROM rolt032 a, rolt033 b
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= MDY(08, 01, 2003)
	  AND b.n33_compania    = a.n32_compania
	  AND b.n33_cod_liqrol  = a.n32_cod_liqrol
	  AND b.n33_fecha_ini   = a.n32_fecha_ini
	  AND b.n33_fecha_fin   = a.n32_fecha_fin
	  AND b.n33_cod_trab    = a.n32_cod_trab
	  AND b.n33_det_tot     = "DI"
	  AND b.n33_cant_valor  = "V"
	  AND b.n33_valor       > 0
	  AND NOT EXISTS
		(SELECT 1 FROM rolt008, rolt006
			WHERE n08_rubro_base  = b.n33_cod_rubro
			  AND n06_cod_rubro   = n08_cod_rubro
			  AND n06_flag_ident IN ("AP", "EC"))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9;

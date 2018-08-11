SELECT "01 ACERO GUAYAQUIL" AS loc,
	YEAR(b12_fec_proceso) AS anio,
	CASE WHEN MONTH(b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS n_mes,
	CASE WHEN  b13_cuenta[1, 8] = "21050101"    THEN "02 APORTES IESS"
	     WHEN  b13_cuenta[1, 8] = "51030701"    THEN "03 BONIFICACIONES"
	     WHEN  b13_cuenta[1, 8] = "51030702"    THEN "04 MOVILIZACION"
	     WHEN (b13_cuenta[1, 8] = "51010201" OR
		   b13_cuenta[1, 8] = "51010202" OR
		   b13_cuenta[1, 8] = "51010203")   THEN "05 VACACIONES PAGADAS"
	     WHEN  b13_cuenta       = "21020104001" THEN "06 UTILIDADES"
		ELSE "01 TOTAL GANADO"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"CUENTA DETALLE" AS tipo_cta,
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) AS val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE   b12_compania           = 1
	  AND   b12_estado            <> "E"
	  AND   YEAR(b12_fec_proceso)  = 2014
	  AND   b13_compania           = b12_compania
	  AND   b13_tipo_comp          = b12_tipo_comp
	  AND   b13_num_comp           = b12_num_comp
	  AND ((b13_cuenta            BETWEEN "51010101"
					  AND "51010103001"
	  AND   b13_valor_base         > 0)
	   OR  (b13_cuenta            BETWEEN "51010201"
					  AND "51010203001"
	  AND   b13_valor_base         > 0)
	   OR  (b13_cuenta[1, 8]       = "51010106"
	  AND   b13_cuenta            <> "51010106017"
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta            IN ("21050101001", "21050101008"))
	   OR  (b12_tipo_comp          = "DC"
	  AND   b12_num_comp          IN ("14070392", "14070888")
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta            IN ("21050101001", "21050101008"))
	   OR  (b13_cuenta[1, 8]      IN ("51030701", "51030702")
	  AND   b13_cuenta            NOT IN ("51030702060")
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta             = "21020104001"))
	  AND   b10_compania           = b13_compania
	  AND   b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT "01 ACERO GUAYAQUIL" AS loc,
	YEAR(b12_fec_proceso) AS anio,
	CASE WHEN MONTH(b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS n_mes,
	CASE WHEN  b13_cuenta[1, 8] = "21050101"  THEN "02 APORTES IESS"
	     WHEN  b13_cuenta[1, 8] = "51030701"  THEN "03 BONIFICACIONES"
	     WHEN  b13_cuenta[1, 8] = "51030702"  THEN "04 MOVILIZACION"
	     WHEN (b13_cuenta[1, 8] = "51010201" OR
		   b13_cuenta[1, 8] = "51010202" OR
		   b13_cuenta[1, 8] = "51010203") THEN "05 VACACIONES PAGADAS"
	     WHEN  b13_cuenta[1, 8] = "21020104"  THEN "06 UTILIDADES"
		ELSE "01 TOTAL GANADO"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"CUENTA MAYOR" AS tipo_cta,
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) AS val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE   b12_compania           = 1
	  AND   b12_estado            <> "E"
	  AND   YEAR(b12_fec_proceso)  = 2014
	  AND   b13_compania           = b12_compania
	  AND   b13_tipo_comp          = b12_tipo_comp
	  AND   b13_num_comp           = b12_num_comp
	  AND ((b13_cuenta            BETWEEN "51010101"
					  AND "51010103001"
	  AND   b13_valor_base         > 0)
	   OR  (b13_cuenta            BETWEEN "51010201"
					  AND "51010203001"
	  AND   b13_valor_base         > 0)
	   OR  (b13_cuenta[1, 8]       = "51010106"
	  AND   b13_cuenta            <> "51010106017"
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta            IN ("21050101001", "21050101008"))
	   OR  (b12_tipo_comp          = "DC"
	  AND   b12_num_comp          IN ("14070392", "14070888")
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta            IN ("21050101001", "21050101008"))
	   OR  (b13_cuenta[1, 8]      IN ("51030701", "51030702")
	  AND   b13_cuenta            NOT IN ("51030702060")
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta             = "21020104001"))
	  AND   b10_compania           = b13_compania
	  AND   b10_cuenta             = b13_cuenta[1, 8]
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT "03 ACERO MATRIZ QUITO" AS loc,
	YEAR(b12_fec_proceso) AS anio,
	CASE WHEN MONTH(b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS n_mes,
	CASE WHEN  b13_cuenta       = "21050101001" THEN "02 APORTES IESS"
	     WHEN  b13_cuenta[1, 8] = "51013701"    THEN "03 BONIFICACIONES"
	     WHEN  b13_cuenta       = "21020104001" THEN "06 UTILIDADES"
		ELSE "01 TOTAL GANADO"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"CUENTA DETALLE" AS tipo_cta,
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) AS val_ctb
	FROM acero_qm@idsuio01:ctbt012,
		acero_qm@idsuio01:ctbt013,
		acero_qm@idsuio01:ctbt010
	WHERE   b12_compania           = 1
	  AND   b12_estado            <> "E"
	  AND   YEAR(b12_fec_proceso)  = 2014
	  AND   b13_compania           = b12_compania
	  AND   b13_tipo_comp          = b12_tipo_comp
	  AND   b13_num_comp           = b12_num_comp
	  AND ((b13_cuenta[1, 8]       = "51010101"
	  AND   b13_valor_base         > 0)
	   OR  (b13_cuenta[1, 8]       = "51010106"
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta             = "21050101001")
	   OR  (b13_cuenta[1, 8]       = "51013701"
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta             = "21020104001"))
	  AND   b10_compania           = b13_compania
	  AND   b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT "03 ACERO MATRIZ QUITO" AS loc,
	YEAR(b12_fec_proceso) AS anio,
	CASE WHEN MONTH(b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS n_mes,
	CASE WHEN  b13_cuenta[1, 8] = "21050101"  THEN "02 APORTES IESS"
	     WHEN  b13_cuenta[1, 8] = "51013701"  THEN "03 BONIFICACIONES"
	     WHEN  b13_cuenta[1, 8] = "21020104"  THEN "06 UTILIDADES"
		ELSE "01 TOTAL GANADO"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"CUENTA MAYOR" AS tipo_cta,
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) AS val_ctb
	FROM acero_qm@idsuio01:ctbt012,
		acero_qm@idsuio01:ctbt013,
		acero_qm@idsuio01:ctbt010
	WHERE   b12_compania           = 1
	  AND   b12_estado            <> "E"
	  AND   YEAR(b12_fec_proceso)  = 2014
	  AND   b13_compania           = b12_compania
	  AND   b13_tipo_comp          = b12_tipo_comp
	  AND   b13_num_comp           = b12_num_comp
	  AND ((b13_cuenta[1, 8]       = "51010101"
	  AND   b13_valor_base         > 0)
	   OR  (b13_cuenta[1, 8]       = "51010106"
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta             = "21050101001")
	   OR  (b13_cuenta[1, 8]       = "51013701"
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta             = "21020104001"))
	  AND   b10_compania           = b13_compania
	  AND   b10_cuenta             = b13_cuenta[1, 8]
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;

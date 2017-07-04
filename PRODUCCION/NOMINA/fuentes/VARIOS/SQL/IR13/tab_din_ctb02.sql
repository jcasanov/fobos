SELECT MONTH(b12_fec_proceso) AS mes,
	CASE WHEN  b13_cuenta       = "21050101001" THEN "02 APORTES IESS"
	     WHEN  b13_cuenta[1, 8] = "51030701"    THEN "03 BONIFICACIONES"
	     WHEN  b13_cuenta[1, 8] = "51030702"    THEN "04 OTROS VALORES"
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
	"DEDUCIBLE" AS tipo,
	"NO" AS tipo_fr,
	"CUENTA DETALLE" AS tipo_cta,
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
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) AS val_ctb
	FROM ctbt012, ctbt013, ctbt010
	WHERE   b12_compania           = 1
	  AND   b12_estado            <> "E"
	  AND   YEAR(b12_fec_proceso)  = 2013
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
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta             = "21050101001")
	   OR  (b13_cuenta[1, 8]      IN ("51030701", "51030702")
	  AND   b13_cuenta            NOT IN ("51030702060")
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta             = "21020104001"))
	  AND   b10_compania           = b13_compania
	  AND   b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	CASE WHEN (b13_cuenta       = "51010301001" OR
		   b13_cuenta       = "51010302001" OR
		   b13_cuenta       = "51010303001") THEN "07 DECIMO TERCERO"
	     WHEN (b13_cuenta       = "51010301002" OR
		   b13_cuenta       = "51010302002" OR
		   b13_cuenta       = "51010303002") THEN "08 DECIMO CUARTO"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"NO" AS tipo_fr,
	"CUENTA DETALLE" AS tipo_cta,
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
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(b12_fec_proceso)  = 2013
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta            IN ("51010301001", "51010302001",
					"51010303001", "51010301002",
					"51010302002", "51010303002")
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	  AND EXISTS
		(SELECT 1 FROM rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	  AND NOT EXISTS
		(SELECT 1 FROM rolt048
			WHERE n48_compania  = b12_compania
			  AND n48_tipo_comp = b12_tipo_comp
			  AND n48_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY) AS mes,
	CASE WHEN b13_cuenta[1, 8] = "51010404" THEN "09 FONDO RESERVA IESS"
	     WHEN b13_cuenta[1, 8] = "51010405" THEN "10 FONDO RESERVA ROL"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"SI" AS tipo_fr,
	"CUENTA DETALLE" AS tipo_cta,
	CASE WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 01 THEN "ENERO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 02 THEN "FEBRERO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 03 THEN "MARZO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 04 THEN "ABRIL"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 05 THEN "MAYO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 06 THEN "JUNIO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 07 THEN "JULIO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 08 THEN "AGOSTO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 10 THEN "OCTUBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 12 THEN "DICIEMBRE"
	END AS n_mes,
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY)       = 2013
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta[1, 8]      IN ("51010404", "51010405")
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	  AND EXISTS
		(SELECT 1 FROM rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	CASE WHEN  b13_cuenta[1, 8] = "21050101"  THEN "02 APORTES IESS"
	     WHEN  b13_cuenta[1, 8] = "51030701"  THEN "03 BONIFICACIONES"
	     WHEN  b13_cuenta[1, 8] = "51030702"  THEN "04 OTROS VALORES"
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
	"DEDUCIBLE" AS tipo,
	"NO" AS tipo_fr,
	"CUENTA MAYOR" AS tipo_cta,
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
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) AS val_ctb
	FROM ctbt012, ctbt013, ctbt010
	WHERE   b12_compania           = 1
	  AND   b12_estado            <> "E"
	  AND   YEAR(b12_fec_proceso)  = 2013
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
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta             = "21050101001")
	   OR  (b13_cuenta[1, 8]      IN ("51030701", "51030702")
	  AND   b13_cuenta            NOT IN ("51030702060")
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta             = "21020104001"))
	  AND   b10_compania           = b13_compania
	  AND   b10_cuenta             = b13_cuenta[1, 8]
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	"0708 DECIMOS" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"NO" AS tipo_fr,
	"CUENTA MAYOR" AS tipo_cta,
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
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(b12_fec_proceso)  = 2013
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta[1, 8]      IN ("51010301", "51010302", "51010303")
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta[1, 8]
	  AND EXISTS
		(SELECT 1 FROM rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	  AND NOT EXISTS
		(SELECT 1 FROM rolt048
			WHERE n48_compania  = b12_compania
			  AND n48_tipo_comp = b12_tipo_comp
			  AND n48_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY) AS mes,
	CASE WHEN b13_cuenta[1, 8] = "51010404" THEN "09 FONDO RESERVA IESS"
	     WHEN b13_cuenta[1, 8] = "51010405" THEN "10 FONDO RESERVA ROL"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"SI" AS tipo_fr,
	"CUENTA MAYOR" AS tipo_cta,
	CASE WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 01 THEN "ENERO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 02 THEN "FEBRERO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 03 THEN "MARZO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 04 THEN "ABRIL"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 05 THEN "MAYO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 06 THEN "JUNIO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 07 THEN "JULIO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 08 THEN "AGOSTO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 10 THEN "OCTUBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
			- 1 UNITS DAY) = 12 THEN "DICIEMBRE"
	END AS n_mes,
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY)       = 2013
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta[1, 8]      IN ("51010404", "51010405")
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta[1, 8]
	  AND EXISTS
		(SELECT 1 FROM rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
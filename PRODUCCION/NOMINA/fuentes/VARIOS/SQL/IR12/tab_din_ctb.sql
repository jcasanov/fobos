SELECT MONTH(b12_fec_proceso) AS mes,
	"01 TOTAL GANADO" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"DEDUCIBLE" AS tipo,
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
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta            BETWEEN "51010101"
					AND "51010103001"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	"02 APORTES IESS" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"DEDUCIBLE" AS tipo,
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
	  AND b12_tipo_comp          = "DN"
	  AND b12_estado            <> "E"
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         < 0
	  AND b13_cuenta             = "21050101001"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	"03 BONIFICACIONES" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"DEDUCIBLE" AS tipo,
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
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta[1, 8]       = "51030701"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	"04 OTROS VALORES" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"DEDUCIBLE" AS tipo,
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
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta[1, 8]       = "51030702"
	  AND b13_cuenta            NOT IN ("51030702060")
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	"05 VACACIONES PAGADAS" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"DEDUCIBLE" AS tipo,
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
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta            BETWEEN "51010201"
					AND "51010203001"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	"06 UTILIDADES" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"DEDUCIBLE" AS tipo,
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
	  AND b12_tipo_comp          = "DN"
	  AND b12_estado            <> "E"
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta             = "21020104001"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	"07 DECIMO TERCERO" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
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
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta            IN ("51010301001", "51010302001",
					"51010303001")
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
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(b12_fec_proceso) AS mes,
	"08 DECIMO CUARTO" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
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
	  AND YEAR(b12_fec_proceso)  = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta            IN ("51010301002", "51010302002",
					"51010303002")
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
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY) AS mes,
	"09 FONDO RESERVA IESS" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
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
		- 1 UNITS DAY)       = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta            LIKE "51010405%"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	  AND EXISTS
		(SELECT 1 FROM rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY) AS mes,
	"10 FONDO RESERVA ROL" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
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
		- 1 UNITS DAY)       = 2012
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta            LIKE "51010404%"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	  AND EXISTS
		(SELECT 1 FROM rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9;

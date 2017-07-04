SELECT YEAR(b12_fec_proceso) AS anio,
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
	CASE WHEN (b13_cuenta[1, 8] = "51010101" OR
		   b13_cuenta[1, 8] = "51010102" OR
		   b13_cuenta[1, 8] = "51010103" OR
		   b13_cuenta[1, 8] = "51010106")    THEN "01 TOTAL GANADO"
	     WHEN (b13_cuenta       = "21050101001" OR
		   b13_cuenta       = "21050101008") THEN "02 APORTES IESS"
	     WHEN  b13_cuenta[1, 8] = "51030701"     THEN "04 BONIFICACIONES"
	     WHEN  b13_cuenta[1, 8] = "51030702"     THEN "05 MOVILIZACION"
	     WHEN (b13_cuenta[1, 8] = "51010201" OR
		   b13_cuenta[1, 8] = "51010202" OR
		   b13_cuenta[1, 8] = "51010203")   THEN "10 VACACIONES PAGADAS"
	     WHEN  b13_cuenta       = "21020104001"  THEN "11 UTILIDADES"
	     WHEN (b13_cuenta[1, 8] = "11020101" OR
		   b13_cuenta[1, 8] = "11010101")   THEN "15 PAGO NOMINA"
	     WHEN (b13_cuenta       = "21050101005" AND
		   b13_valor_base   > 0) OR
	          (b13_cuenta[1, 8] = "21040102" AND
		   b13_valor_base   > 0)             THEN "06 OTROS INGRESOS"
	     WHEN (b13_cuenta[1, 8] = "11240104" AND
		   b13_tipo_comp    <> "DN" AND
		   b13_valor_base   > 0)             THEN "09 VACACIONES"
	     WHEN  b13_cuenta       = "24010101001"  THEN "14 JUBILADOS"
		ELSE "03 EGRESOS NOMINA"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	CASE WHEN (b13_cuenta[1, 8] = "51010101" OR
		   b13_cuenta[1, 8] = "51010102" OR
		   b13_cuenta[1, 8] = "51010103" OR
		   b13_cuenta[1, 8] = "51010106") OR
	          (b13_cuenta       = "21050101001" OR
		   b13_cuenta       = "21050101008") OR
	           b13_cuenta[1, 8] = "51030701" OR
	           b13_cuenta[1, 8] = "51030702" OR
	          (b13_cuenta[1, 8] = "51010201" OR
		   b13_cuenta[1, 8] = "51010202" OR
		   b13_cuenta[1, 8] = "51010203") OR
	           b13_cuenta       = "21020104001"
		THEN "DEDUCIBLE"
	     WHEN (b13_cuenta       = "21050101005" AND b13_valor_base > 0) OR
	          (b13_cuenta[1, 8] = "21040102" AND b13_valor_base > 0) OR
	          (b13_cuenta[1, 8] = "11240104" AND b13_tipo_comp <> "DN" AND
		   b13_valor_base   > 0) OR
		   b13_cuenta       = "24010101001"
		THEN "NO DEDUCIBLE"
	     WHEN (b13_cuenta[1, 8] = "11020101" OR
		   b13_cuenta[1, 8] = "11010101")
		THEN "PAGO NOMINA"
		ELSE "NO DEDUCIBLE"
	END AS tipo,
	"NO" AS tipo_fr,
	"CUENTA DETALLE" AS tipo_cta,
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	b12_fec_proceso AS fec_pro,
	ROUND(SUM(b13_valor_base), 2) AS val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE   b12_compania           = 1
	  AND   b12_estado            <> "E"
	  AND   YEAR(b12_fec_proceso) >= 2010
	  AND   b12_compania || b12_tipo_comp || b12_num_comp NOT IN
		("1DC10010865", "1DC10010866", "1DC10120875", "1DC10120876",
		 "1DC10120878", "1DC10121236", "1DC11121027", "1DC11050890",
		 "1DC11120862", "1DC11020948", "1DC11020946", "1DC11120773",
		 "1DC11110842", "1DC11020949", "1DC12110910", "1DC12120993",
		 "1DC13120830", "1EG14120037")
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
	  AND   b13_cuenta[1, 8]      <> "51030701"
	  AND   b13_valor_base         < 0)
	   OR  (b12_tipo_comp         <> "DN"
	  AND   b13_cuenta[1, 8]       = "11240104"
	  AND   b13_valor_base         > 0)
	   OR ((b12_tipo_comp          = "DN"
	  AND   b13_cuenta            IN ("11240103001", "21050101005")
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DC"
	  AND   b12_num_comp           = "14070392"
	  AND   b13_cuenta             = "11240103001"
	  AND   b13_valor_base         < 0))
	   OR  (b12_tipo_comp          = "EG"
	  AND   b12_origen             = "A"
	  AND   b12_modulo             = "RO"
	  AND   b12_compania || b12_tipo_comp || b12_num_comp
		NOT IN
		(SELECT n59_compania || n59_tipo_comp || n59_num_comp
			FROM acero_gm@idsgye01:rolt059)
	  AND   b13_valor_base         < 0)
	   OR  (b12_tipo_comp          = "DC"
	  AND   b12_num_comp          IN ("12030847", "14070392", "14070888")
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta            IN ("21050101001", "21050101008"))
	   OR  (b12_tipo_comp         IN ("DN", "DC")
	  AND   b12_origen             = "A"
	  AND   b12_modulo             = "RO"
	  AND   b13_cuenta[1, 8]      IN ("51030701", "51030702")
	  AND   b13_cuenta            NOT IN ("51030702060")
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DC"
	  AND   b12_num_comp           = "14070888"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta[1, 8]      IN ("51030701", "51030702"))
	   OR  (b13_cuenta             = "24010101001"
	  AND   b13_fec_proceso       >= MDY(12, 01, 2010)
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta[1, 8]       = "21040102")
	   OR  (b12_tipo_comp          = "DN"
	  AND   b12_num_comp          IN ("10070002", "10110002", "11030005",
					"12010002", "13050004", "13090002")
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta            IN ("11210104002", "11240105025",
					"21050101007", "11240104024",
					"21050101008", "21090101001"))
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta             = "21020104001"))
	  AND  (b13_tipo_comp || b13_num_comp || b13_cuenta <>
			"DN1003000451010801018")
	  AND   b10_compania           = b13_compania
	  AND   b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT YEAR(b12_fec_proceso) AS anio,
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
	CASE WHEN (b13_cuenta       = "51010301001" OR
		   b13_cuenta       = "51010302001" OR
		   b13_cuenta       = "51010303001") THEN "12 DECIMO TERCERO"
	     WHEN (b13_cuenta       = "51010301002" OR
		   b13_cuenta       = "51010302002" OR
		   b13_cuenta       = "51010303002") THEN "13 DECIMO CUARTO"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"NO" AS tipo_fr,
	"CUENTA DETALLE" AS tipo_cta,
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	b12_fec_proceso AS fec_pro,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(b12_fec_proceso) >= 2010
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
		(SELECT 1 FROM acero_gm@idsgye01:rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt048
			WHERE n48_compania  = b12_compania
			  AND n48_tipo_comp = b12_tipo_comp
			  AND n48_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT YEAR(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))) AS anio,
	CASE WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 01 THEN "ENERO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 02 THEN "FEBRERO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 03 THEN "MARZO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 04 THEN "ABRIL"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 05 THEN "MAYO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 06 THEN "JUNIO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 07 THEN "JULIO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 08 THEN "AGOSTO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 10 THEN "OCTUBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 11 THEN "NOVIEMBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 12 THEN "DICIEMBRE"
	END AS n_mes,
	"07 FONDO RESERVA ROL" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"SI" AS tipo_fr,
	"CUENTA DETALLE" AS tipo_cta,
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	DATE(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))) AS fec_pro,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(MDY(MONTH(b12_fec_proceso), 01,
			YEAR(b12_fec_proceso))) >= 2010
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta[1, 8]       = "51010404"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	  AND EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT YEAR(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY) AS anio,
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
	"08 FONDO RESERVA IESS" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"SI" AS tipo_fr,
	"CUENTA DETALLE" AS tipo_cta,
	b12_tipo_comp AS td,
	b12_num_comp AS num,
	b13_cuenta AS cta,
	b10_descripcion AS n_cta,
	DATE(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY) AS fec_pro,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE  b12_compania           = 1
	  AND  b12_estado            <> "E"
	  AND  YEAR(MDY(MONTH(b12_fec_proceso), 01,
			YEAR(b12_fec_proceso)) - 1 UNITS DAY) >= 2010
	  AND  b13_compania           = b12_compania
	  AND  b13_tipo_comp          = b12_tipo_comp
	  AND  b13_num_comp           = b12_num_comp
	  AND  b13_valor_base         > 0
	  AND  b13_cuenta[1, 8]       = "51010405"
	  AND  b10_compania           = b13_compania
	  AND  b10_cuenta             = b13_cuenta
	  AND (EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	   OR  b13_compania || b13_tipo_comp || b13_num_comp || b13_cuenta[1, 8]
		IN ("1DC1112097851010405"))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT YEAR(b12_fec_proceso) AS anio,
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
	CASE WHEN (b13_cuenta[1, 8] = "51010101" OR
		   b13_cuenta[1, 8] = "51010102" OR
		   b13_cuenta[1, 8] = "51010103" OR
		   b13_cuenta[1, 8] = "51010106")    THEN "01 TOTAL GANADO"
	     WHEN (b13_cuenta       = "21050101001" OR
		   b13_cuenta       = "21050101008") THEN "02 APORTES IESS"
	     WHEN  b13_cuenta[1, 8] = "51030701"     THEN "04 BONIFICACIONES"
	     WHEN  b13_cuenta[1, 8] = "51030702"     THEN "05 MOVILIZACION"
	     WHEN (b13_cuenta[1, 8] = "51010201" OR
		   b13_cuenta[1, 8] = "51010202" OR
		   b13_cuenta[1, 8] = "51010203")   THEN "10 VACACIONES PAGADAS"
	     WHEN  b13_cuenta[1, 8] = "21020104"     THEN "11 UTILIDADES"
	     WHEN (b13_cuenta[1, 8] = "11020101" OR
		   b13_cuenta[1, 8] = "11010101")   THEN "15 PAGO NOMINA"
	     WHEN (b13_cuenta       = "21050101005" AND
		   b13_valor_base   > 0) OR
	          (b13_cuenta[1, 8] = "21040102" AND
		   b13_valor_base   > 0)             THEN "06 OTROS INGRESOS"
	     WHEN (b13_cuenta[1, 8] = "11240104" AND
		   b13_tipo_comp    <> "DN" AND
		   b13_valor_base   > 0)             THEN "09 VACACIONES"
	     WHEN  b13_cuenta       = "24010101001"  THEN "14 JUBILADOS"
		ELSE "03 EGRESOS NOMINA"
	END AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	CASE WHEN (b13_cuenta[1, 8] = "51010101" OR
		   b13_cuenta[1, 8] = "51010102" OR
		   b13_cuenta[1, 8] = "51010103" OR
		   b13_cuenta[1, 8] = "51010106") OR
	          (b13_cuenta       = "21050101001" OR
		   b13_cuenta       = "21050101008") OR
	           b13_cuenta[1, 8] = "51030701" OR
	           b13_cuenta[1, 8] = "51030702" OR
	          (b13_cuenta[1, 8] = "51010201" OR
		   b13_cuenta[1, 8] = "51010202" OR
		   b13_cuenta[1, 8] = "51010203") OR
	           b13_cuenta       = "21020104001"
		THEN "DEDUCIBLE"
	     WHEN (b13_cuenta       = "21050101005" AND b13_valor_base > 0) OR
	          (b13_cuenta[1, 8] = "21040102" AND b13_valor_base > 0) OR
	          (b13_cuenta[1, 8] = "11240104" AND b13_tipo_comp <> "DN" AND
		   b13_valor_base   > 0) OR
		   b13_cuenta       = "24010101001"
		THEN "NO DEDUCIBLE"
	     WHEN (b13_cuenta[1, 8] = "11020101" OR
		   b13_cuenta[1, 8] = "11010101")
		THEN "PAGO NOMINA"
		ELSE "NO DEDUCIBLE"
	END AS tipo,
	"NO" AS tipo_fr,
	"CUENTA MAYOR" AS tipo_cta,
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	b12_fec_proceso AS fec_pro,
	ROUND(SUM(b13_valor_base), 2) AS val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE   b12_compania           = 1
	  AND   b12_estado            <> "E"
	  AND   YEAR(b12_fec_proceso) >= 2010
	  AND   b12_compania || b12_tipo_comp || b12_num_comp NOT IN
		("1DC10010865", "1DC10010866", "1DC10120875", "1DC10120876",
		 "1DC10120878", "1DC10121236", "1DC11121027", "1DC11050890",
		 "1DC11120862", "1DC11020948", "1DC11020946", "1DC11120773",
		 "1DC11110842", "1DC11020949", "1DC12110910", "1DC12120993",
		 "1DC13120830", "1EG14120037")
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
	  AND   b13_cuenta[1, 8]      <> "51030701"
	  AND   b13_valor_base         < 0)
	   OR  (b12_tipo_comp         <> "DN"
	  AND   b13_cuenta[1, 8]       = "11240104"
	  AND   b13_valor_base         > 0)
	   OR ((b12_tipo_comp          = "DN"
	  AND   b13_cuenta            IN ("11240103001", "21050101005")
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DC"
	  AND   b12_num_comp           = "14070392"
	  AND   b13_cuenta             = "11240103001"
	  AND   b13_valor_base         < 0))
	   OR  (b12_tipo_comp          = "EG"
	  AND   b12_origen             = "A"
	  AND   b12_modulo             = "RO"
	  AND   b12_compania || b12_tipo_comp || b12_num_comp
		NOT IN
		(SELECT n59_compania || n59_tipo_comp || n59_num_comp
			FROM acero_gm@idsgye01:rolt059)
	  AND   b13_valor_base         < 0)
	   OR  (b12_tipo_comp          = "DC"
	  AND   b12_num_comp          IN ("12030847", "14070392", "14070888")
	  AND   b13_valor_base         < 0
	  AND   b13_cuenta            IN ("21050101001", "21050101008"))
	   OR  (b12_tipo_comp         IN ("DN", "DC")
	  AND   b12_origen             = "A"
	  AND   b12_modulo             = "RO"
	  AND   b13_cuenta[1, 8]      IN ("51030701", "51030702")
	  AND   b13_cuenta            NOT IN ("51030702060")
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DC"
	  AND   b12_num_comp           = "14070888"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta[1, 8]      IN ("51030701", "51030702"))
	   OR  (b13_cuenta             = "24010101001"
	  AND   b13_fec_proceso       >= MDY(12, 01, 2010)
	  AND   b13_valor_base         > 0)
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta[1, 8]       = "21040102")
	   OR  (b12_tipo_comp          = "DN"
	  AND   b12_num_comp          IN ("10070002", "10110002", "11030005",
					"12010002", "13050004", "13090002")
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta            IN ("11210104002", "11240105025",
					"21050101007", "11240104024",
					"21050101008", "21090101001"))
	   OR  (b12_tipo_comp          = "DN"
	  AND   b13_valor_base         > 0
	  AND   b13_cuenta             = "21020104001"))
	  AND  (b13_tipo_comp || b13_num_comp || b13_cuenta <>
			"DN1003000451010801018")
	  AND   b10_compania           = b13_compania
	  AND   b10_cuenta             = b13_cuenta[1, 8]
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT YEAR(b12_fec_proceso) AS anio,
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
	"1213 DECIMOS" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"NO" AS tipo_fr,
	"CUENTA MAYOR" AS tipo_cta,
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	b12_fec_proceso AS fec_pro,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(b12_fec_proceso) >= 2010
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta[1, 8]      IN ("51010301", "51010302", "51010303")
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta[1, 8]
	  AND EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt048
			WHERE n48_compania  = b12_compania
			  AND n48_tipo_comp = b12_tipo_comp
			  AND n48_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT YEAR(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))) AS anio,
	CASE WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 01 THEN "ENERO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 02 THEN "FEBRERO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 03 THEN "MARZO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 04 THEN "ABRIL"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 05 THEN "MAYO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 06 THEN "JUNIO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 07 THEN "JULIO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 08 THEN "AGOSTO"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 10 THEN "OCTUBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 11 THEN "NOVIEMBRE"
	     WHEN MONTH(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso)))
			= 12 THEN "DICIEMBRE"
	END AS n_mes,
	"07 FONDO RESERVA ROL" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"SI" AS tipo_fr,
	"CUENTA MAYOR" AS tipo_cta,
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	DATE(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))) AS fec_pro,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> "E"
	  AND YEAR(MDY(MONTH(b12_fec_proceso), 01,
			YEAR(b12_fec_proceso))) >= 2010
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND b13_valor_base         > 0
	  AND b13_cuenta[1, 8]       = "51010404"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta[1, 8]
	  AND EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT YEAR(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY) AS anio,
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
	"08 FONDO RESERVA IESS" AS rub,
	CASE WHEN DAY(b12_fec_proceso) <= 15
		THEN "PRIMERA QUINCENA"
		ELSE "SEGUNDA QUINCENA"
	END AS lq,
	"NO DEDUCIBLE" AS tipo,
	"SI" AS tipo_fr,
	"CUENTA MAYOR" AS tipo_cta,
	"TODOS" AS td,
	"DIARIOS" AS num,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS n_cta,
	DATE(MDY(MONTH(b12_fec_proceso), 01, YEAR(b12_fec_proceso))
		- 1 UNITS DAY) AS fec_pro,
	ROUND(SUM(b13_valor_base), 2) val_ctb
	FROM acero_gm@idsgye01:ctbt012,
		acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE  b12_compania           = 1
	  AND  b12_estado            <> "E"
	  AND  YEAR(MDY(MONTH(b12_fec_proceso), 01,
			YEAR(b12_fec_proceso)) - 1 UNITS DAY) >= 2010
	  AND  b13_compania           = b12_compania
	  AND  b13_tipo_comp          = b12_tipo_comp
	  AND  b13_num_comp           = b12_num_comp
	  AND  b13_valor_base         > 0
	  AND  b13_cuenta[1, 8]       = "51010405"
	  AND  b10_compania           = b13_compania
	  AND  b10_cuenta             = b13_cuenta[1, 8]
	  AND (EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt053
			WHERE n53_compania  = b12_compania
			  AND n53_tipo_comp = b12_tipo_comp
			  AND n53_num_comp  = b12_num_comp)
	   OR  b13_compania || b13_tipo_comp || b13_num_comp || b13_cuenta[1, 8]
		IN ("1DC1112097851010405"))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;

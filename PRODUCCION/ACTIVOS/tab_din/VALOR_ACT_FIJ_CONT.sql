SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 1) AS local,
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
	END AS mes,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_gm@idsgye01:ctbt001
			WHERE b01_nivel = b10_nivel) AS nive,
	NVL(LPAD(b12_subtipo, 2, 0) || " " ||
		(SELECT TRIM(b04_nombre)
			FROM acero_gm@idsgye01:ctbt004
			WHERE b04_compania = b12_compania
			  AND b04_subtipo  = b12_subtipo),
		"SIN SUBTIPO") AS subt,
	b12_tipo_comp || "-" || TRIM(b12_num_comp) AS num_comp,
	DATE(b12_fec_proceso) AS fec_pro,
	TRIM(b13_cuenta) || " " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM acero_gm@idsgye01:ctbt012, acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt010
	WHERE b12_compania  = 1
	  AND b12_estado    = "M"
	  AND b13_compania  = b12_compania
	  AND b13_tipo_comp = b12_tipo_comp
	  AND b13_num_comp  = b12_num_comp
	  AND b13_cuenta    MATCHES "120101*"
	  AND b10_compania  = b13_compania
	  AND b10_cuenta    = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = b10_compania
		  AND g02_localidad = 1) AS local,
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
	END AS mes,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_gm@idsgye01:ctbt001
			WHERE b01_nivel = b10_nivel) AS nive,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_gm@idsgye01:ctbt001
			WHERE b01_nivel = b10_nivel) AS subt,
	"TD-" || TO_CHAR(b12_fec_proceso, "%y") ||
		LPAD(MONTH(b12_fec_proceso), 2, 0) AS num_comp,
	DATE(b12_fec_proceso) AS fec_pro,
	TRIM(b13_cuenta[1, 8]) || " " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM acero_gm@idsgye01:ctbt010, acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt012
	WHERE b10_compania     = 1
	  AND b10_cuenta       MATCHES "120101*"
	  AND b10_nivel        = 5
	  AND b13_compania     = b10_compania
	  AND b13_cuenta[1, 8] = b10_cuenta[1, 8]
	  AND b12_compania     = b13_compania
	  AND b12_tipo_comp    = b13_tipo_comp
	  AND b12_num_comp     = b13_num_comp
	  AND b12_estado       = "M"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = b10_compania
		  AND g02_localidad = 1) AS local,
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
	END AS mes,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_gm@idsgye01:ctbt001
			WHERE b01_nivel = b10_nivel) AS nive,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_gm@idsgye01:ctbt001
			WHERE b01_nivel = b10_nivel) AS subt,
	"TD-" || TO_CHAR(b12_fec_proceso, "%y") ||
		LPAD(MONTH(b12_fec_proceso), 2, 0) AS num_comp,
	DATE(b12_fec_proceso) AS fec_pro,
	TRIM(b13_cuenta[1, 6]) || "00 " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM acero_gm@idsgye01:ctbt010, acero_gm@idsgye01:ctbt013,
		acero_gm@idsgye01:ctbt012
	WHERE b10_compania     = 1
	  AND b10_cuenta       MATCHES "120101*"
	  AND b10_nivel        = 4
	  AND b13_compania     = b10_compania
	  AND b13_cuenta[1, 6] = b10_cuenta[1, 6]
	  AND b12_compania     = b13_compania
	  AND b12_tipo_comp    = b13_tipo_comp
	  AND b12_num_comp     = b13_num_comp
	  AND b12_estado       = "M"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 3) AS local,
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
	END AS mes,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_qm@idsuio01:ctbt001
			WHERE b01_nivel = b10_nivel) AS nive,
	NVL(LPAD(b12_subtipo, 2, 0) || " " ||
		(SELECT TRIM(b04_nombre)
			FROM acero_qm@idsuio01:ctbt004
			WHERE b04_compania = b12_compania
			  AND b04_subtipo  = b12_subtipo),
		"SIN SUBTIPO") AS subt,
	b12_tipo_comp || "-" || TRIM(b12_num_comp) AS num_comp,
	DATE(b12_fec_proceso) AS fec_pro,
	TRIM(b13_cuenta) || " " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM acero_qm@idsuio01:ctbt012, acero_qm@idsuio01:ctbt013,
		acero_qm@idsuio01:ctbt010
	WHERE b12_compania  = 1
	  AND b12_estado    = "M"
	  AND b13_compania  = b12_compania
	  AND b13_tipo_comp = b12_tipo_comp
	  AND b13_num_comp  = b12_num_comp
	  AND b13_cuenta    MATCHES "120101*"
	  AND b10_compania  = b13_compania
	  AND b10_cuenta    = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = b10_compania
		  AND g02_localidad = 3) AS local,
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
	END AS mes,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_qm@idsuio01:ctbt001
			WHERE b01_nivel = b10_nivel) AS nive,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_qm@idsuio01:ctbt001
			WHERE b01_nivel = b10_nivel) AS subt,
	"TD-" || TO_CHAR(b12_fec_proceso, "%y") ||
		LPAD(MONTH(b12_fec_proceso), 2, 0) AS num_comp,
	DATE(b12_fec_proceso) AS fec_pro,
	TRIM(b13_cuenta[1, 8]) || " " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM acero_qm@idsuio01:ctbt010, acero_qm@idsuio01:ctbt013,
		acero_qm@idsuio01:ctbt012
	WHERE b10_compania     = 1
	  AND b10_cuenta       MATCHES "120101*"
	  AND b10_nivel        = 5
	  AND b13_compania     = b10_compania
	  AND b13_cuenta[1, 8] = b10_cuenta[1, 8]
	  AND b12_compania     = b13_compania
	  AND b12_tipo_comp    = b13_tipo_comp
	  AND b12_num_comp     = b13_num_comp
	  AND b12_estado       = "M"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = b10_compania
		  AND g02_localidad = 3) AS local,
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
	END AS mes,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_qm@idsuio01:ctbt001
			WHERE b01_nivel = b10_nivel) AS nive,
	LPAD(b10_nivel, 2, 0) || " " ||
		(SELECT TRIM(b01_nombre)
			FROM acero_qm@idsuio01:ctbt001
			WHERE b01_nivel = b10_nivel) AS subt,
	"TD-" || TO_CHAR(b12_fec_proceso, "%y") ||
		LPAD(MONTH(b12_fec_proceso), 2, 0) AS num_comp,
	DATE(b12_fec_proceso) AS fec_pro,
	TRIM(b13_cuenta[1, 6]) || "00 " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM acero_qm@idsuio01:ctbt010, acero_qm@idsuio01:ctbt013,
		acero_qm@idsuio01:ctbt012
	WHERE b10_compania     = 1
	  AND b10_cuenta       MATCHES "120101*"
	  AND b10_nivel        = 4
	  AND b13_compania     = b10_compania
	  AND b13_cuenta[1, 6] = b10_cuenta[1, 6]
	  AND b12_compania     = b13_compania
	  AND b12_tipo_comp    = b13_tipo_comp
	  AND b12_num_comp     = b13_num_comp
	  AND b12_estado       = "M"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;

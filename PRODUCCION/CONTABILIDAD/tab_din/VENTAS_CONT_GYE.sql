SELECT YEAR(a.b12_fec_proceso) AS anio,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	YEAR(a.b12_fec_proceso) || "-" ||
	CASE WHEN MONTH(a.b12_fec_proceso) IN (01, 02, 03) THEN "TRIM-01"
	     WHEN MONTH(a.b12_fec_proceso) IN (04, 05, 06) THEN "TRIM-02"
	     WHEN MONTH(a.b12_fec_proceso) IN (07, 08, 09) THEN "TRIM-03"
	     WHEN MONTH(a.b12_fec_proceso) IN (10, 11, 12) THEN "TRIM-04"
	END AS trimes,
	CASE WHEN b.b13_cuenta[1, 4] = "4102"
		THEN "VENTAS EXENTAS"
		ELSE "VENTAS CON IVA"
	END AS c_iva,
	"INGRESOS" AS tip_m,
	CASE WHEN b.b13_cuenta[1, 2] = "42"
		THEN "02 NO OPERACIONAL"
		ELSE "01 OPERACIONAL"
	END AS tip_tra,
	CASE WHEN a.b12_tipo_comp = "DC"
			AND a.b12_num_comp IN ("12100669", "12110144",
						"12120664", "12120669")
		THEN "VENTAS INVENTARIO"
		ELSE
	NVL(NVL((SELECT "VENTAS INVENTARIO"
		FROM rept040
		WHERE r40_compania  = a.b12_compania
		  AND r40_tipo_comp = a.b12_tipo_comp
		  AND r40_num_comp  = a.b12_num_comp),
	(SELECT "VENTAS TALLER"
		FROM talt050
		WHERE t50_compania  = a.b12_compania
		  AND t50_tipo_comp = a.b12_tipo_comp
		  AND t50_num_comp  = a.b12_num_comp)),
	"OTRAS VENTAS")
	END AS tip_vta,
	NVL(NVL((SELECT CASE WHEN r19_cont_cred = "C"
				THEN "CONTADO"
				ELSE "CREDITO"
			END
		FROM rept040, rept019
		WHERE r40_compania  = a.b12_compania
		  AND r40_tipo_comp = a.b12_tipo_comp
		  AND r40_num_comp  = a.b12_num_comp
		  AND r19_compania  = r40_compania
		  AND r19_localidad = r40_localidad
		  AND r19_cod_tran  = r40_cod_tran
		  AND r19_num_tran  = r40_num_tran),
	(SELECT CASE WHEN t23_cont_cred = "C"
				THEN "CONTADO"
				ELSE "CREDITO"
			END
		FROM talt050, talt023
		WHERE t50_compania  = a.b12_compania
		  AND t50_tipo_comp = a.b12_tipo_comp
		  AND t50_num_comp  = a.b12_num_comp
		  AND t23_compania  = t50_compania
		  AND t23_localidad = t50_localidad
		  AND t23_orden     = t50_orden)),
	"OTROS") AS tip_pag,
	LPAD(b10_nivel, 2, 0) || " " || TRIM(b01_nombre) AS nive,
	NVL(LPAD(a.b12_subtipo, 2, 0) || " " || TRIM(b04_nombre),
		"SIN SUBTIPO") AS subt,
	a.b12_tipo_comp || "-" || TRIM(a.b12_num_comp) AS num_comp,
	DATE(a.b12_fec_proceso) AS fec_pro,
	TRIM(b.b13_cuenta) || " " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b.b13_valor_base), 0.00) AS saldo
	FROM ctbt012 a, ctbt013 b, ctbt010, ctbt001, OUTER ctbt004
	WHERE a.b12_compania          = 1
	  AND a.b12_estado            = "M"
	  AND YEAR(a.b12_fec_proceso) > 2010
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = a.b12_compania
	  		  AND b50_tipo_comp = a.b12_tipo_comp
	 		  AND b50_num_comp  = a.b12_num_comp)
	  AND b.b13_compania          = a.b12_compania
	  AND b.b13_tipo_comp         = a.b12_tipo_comp
	  AND b.b13_num_comp          = a.b12_num_comp
	  AND b.b13_cuenta[1, 1]      = "4"
	  AND b10_compania            = b.b13_compania
	  AND b10_cuenta              = b.b13_cuenta
	  AND b01_nivel               = b10_nivel
	  AND b04_compania            = a.b12_compania
	  AND b04_subtipo             = a.b12_subtipo
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
UNION
SELECT YEAR(a.b12_fec_proceso) AS anio,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	YEAR(a.b12_fec_proceso) || "-" ||
	CASE WHEN MONTH(a.b12_fec_proceso) IN (01, 02, 03) THEN "TRIM-01"
	     WHEN MONTH(a.b12_fec_proceso) IN (04, 05, 06) THEN "TRIM-02"
	     WHEN MONTH(a.b12_fec_proceso) IN (07, 08, 09) THEN "TRIM-03"
	     WHEN MONTH(a.b12_fec_proceso) IN (10, 11, 12) THEN "TRIM-04"
	END AS trimes,
	CASE WHEN b.b13_cuenta[1, 4] = "4102"
		THEN "VENTAS EXENTAS"
		ELSE "VENTAS CON IVA"
	END AS c_iva,
	"INGRESOS" AS tip_m,
	CASE WHEN b.b13_cuenta[1, 2] = "42"
		THEN "02 NO OPERACIONAL"
		ELSE "01 OPERACIONAL"
	END AS tip_tra,
	CASE WHEN a.b12_tipo_comp = "DC"
			AND a.b12_num_comp IN ("12100669", "12110144",
						"12120664", "12120669")
		THEN "VENTAS INVENTARIO"
		ELSE
	NVL(NVL((SELECT "VENTAS INVENTARIO"
		FROM rept040
		WHERE r40_compania  = a.b12_compania
		  AND r40_tipo_comp = a.b12_tipo_comp
		  AND r40_num_comp  = a.b12_num_comp),
	(SELECT "VENTAS TALLER"
		FROM talt050
		WHERE t50_compania  = a.b12_compania
		  AND t50_tipo_comp = a.b12_tipo_comp
		  AND t50_num_comp  = a.b12_num_comp)),
	"OTRAS VENTAS")
	END AS tip_vta,
	NVL(NVL((SELECT CASE WHEN r19_cont_cred = "C"
				THEN "CONTADO"
				ELSE "CREDITO"
			END
		FROM rept040, rept019
		WHERE r40_compania  = a.b12_compania
		  AND r40_tipo_comp = a.b12_tipo_comp
		  AND r40_num_comp  = a.b12_num_comp
		  AND r19_compania  = r40_compania
		  AND r19_localidad = r40_localidad
		  AND r19_cod_tran  = r40_cod_tran
		  AND r19_num_tran  = r40_num_tran),
	(SELECT CASE WHEN t23_cont_cred = "C"
				THEN "CONTADO"
				ELSE "CREDITO"
			END
		FROM talt050, talt023
		WHERE t50_compania  = a.b12_compania
		  AND t50_tipo_comp = a.b12_tipo_comp
		  AND t50_num_comp  = a.b12_num_comp
		  AND t23_compania  = t50_compania
		  AND t23_localidad = t50_localidad
		  AND t23_orden     = t50_orden)),
	"OTROS") AS tip_pag,
	LPAD(b10_nivel, 2, 0) || " " || TRIM(b01_nombre) AS nive,
	LPAD(b10_nivel, 2, 0) || " " || TRIM(b01_nombre) AS subt,
	"TD-" || TO_CHAR(a.b12_fec_proceso, "%y") ||
		LPAD(MONTH(a.b12_fec_proceso), 2, 0) AS num_comp,
	DATE(a.b12_fec_proceso) AS fec_pro,
	TRIM(b.b13_cuenta[1, 8]) || " " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b.b13_valor_base), 0.00) AS saldo
	FROM ctbt010, ctbt013 b, ctbt012 a, ctbt001
	WHERE b10_compania            = 1
	  AND b10_cuenta[1, 1]        = "4"
	  AND b10_nivel               = 5
	  AND b.b13_compania          = b10_compania
	  AND b.b13_cuenta[1, 8]      = b10_cuenta[1, 8]
	  AND a.b12_compania          = b.b13_compania
	  AND a.b12_tipo_comp         = b.b13_tipo_comp
	  AND a.b12_num_comp          = b.b13_num_comp
	  AND a.b12_estado            = "M"
	  AND YEAR(a.b12_fec_proceso) > 2010
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = a.b12_compania
	  		  AND b50_tipo_comp = a.b12_tipo_comp
	 		  AND b50_num_comp  = a.b12_num_comp)
	  AND b01_nivel               = b10_nivel
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
UNION
SELECT YEAR(a.b12_fec_proceso) AS anio,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	YEAR(a.b12_fec_proceso) || "-" ||
	CASE WHEN MONTH(a.b12_fec_proceso) IN (01, 02, 03) THEN "TRIM-01"
	     WHEN MONTH(a.b12_fec_proceso) IN (04, 05, 06) THEN "TRIM-02"
	     WHEN MONTH(a.b12_fec_proceso) IN (07, 08, 09) THEN "TRIM-03"
	     WHEN MONTH(a.b12_fec_proceso) IN (10, 11, 12) THEN "TRIM-04"
	END AS trimes,
	CASE WHEN b.b13_cuenta[1, 4] = "4102"
		THEN "VENTAS EXENTAS"
		ELSE "VENTAS CON IVA"
	END AS c_iva,
	"INGRESOS" AS tip_m,
	CASE WHEN b.b13_cuenta[1, 2] = "42"
		THEN "02 NO OPERACIONAL"
		ELSE "01 OPERACIONAL"
	END AS tip_tra,
	CASE WHEN a.b12_tipo_comp = "DC"
			AND a.b12_num_comp IN ("12100669", "12110144",
						"12120664", "12120669")
		THEN "VENTAS INVENTARIO"
		ELSE
	NVL(NVL((SELECT "VENTAS INVENTARIO"
		FROM rept040
		WHERE r40_compania  = a.b12_compania
		  AND r40_tipo_comp = a.b12_tipo_comp
		  AND r40_num_comp  = a.b12_num_comp),
	(SELECT "VENTAS TALLER"
		FROM talt050
		WHERE t50_compania  = a.b12_compania
		  AND t50_tipo_comp = a.b12_tipo_comp
		  AND t50_num_comp  = a.b12_num_comp)),
	"OTRAS VENTAS")
	END AS tip_vta,
	NVL(NVL((SELECT CASE WHEN r19_cont_cred = "C"
				THEN "CONTADO"
				ELSE "CREDITO"
			END
		FROM rept040, rept019
		WHERE r40_compania  = a.b12_compania
		  AND r40_tipo_comp = a.b12_tipo_comp
		  AND r40_num_comp  = a.b12_num_comp
		  AND r19_compania  = r40_compania
		  AND r19_localidad = r40_localidad
		  AND r19_cod_tran  = r40_cod_tran
		  AND r19_num_tran  = r40_num_tran),
	(SELECT CASE WHEN t23_cont_cred = "C"
				THEN "CONTADO"
				ELSE "CREDITO"
			END
		FROM talt050, talt023
		WHERE t50_compania  = a.b12_compania
		  AND t50_tipo_comp = a.b12_tipo_comp
		  AND t50_num_comp  = a.b12_num_comp
		  AND t23_compania  = t50_compania
		  AND t23_localidad = t50_localidad
		  AND t23_orden     = t50_orden)),
	"OTROS") AS tip_pag,
	LPAD(b10_nivel, 2, 0) || " " || TRIM(b01_nombre) AS nive,
	LPAD(b10_nivel, 2, 0) || " " || TRIM(b01_nombre) AS subt,
	"TD-" || TO_CHAR(a.b12_fec_proceso, "%y") ||
		LPAD(MONTH(a.b12_fec_proceso), 2, 0) AS num_comp,
	DATE(a.b12_fec_proceso) AS fec_pro,
	TRIM(b.b13_cuenta[1, 6]) || "00 " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b.b13_valor_base), 0.00) AS saldo
	FROM ctbt010, ctbt013 b, ctbt012 a, ctbt001
	WHERE b10_compania            = 1
	  AND b10_cuenta[1, 1]        = "4"
	  AND b10_nivel               = 4
	  AND b.b13_compania          = b10_compania
	  AND b.b13_cuenta[1, 6]      = b10_cuenta[1, 6]
	  AND a.b12_compania          = b.b13_compania
	  AND a.b12_tipo_comp         = b.b13_tipo_comp
	  AND a.b12_num_comp          = b.b13_num_comp
	  AND a.b12_estado            = "M"
	  AND YEAR(a.b12_fec_proceso) > 2010
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = a.b12_compania
	  		  AND b50_tipo_comp = a.b12_tipo_comp
	 		  AND b50_num_comp  = a.b12_num_comp)
	  AND b01_nivel               = b10_nivel
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
UNION
SELECT YEAR(a.b12_fec_proceso) AS anio,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	YEAR(a.b12_fec_proceso) || "-" ||
	CASE WHEN MONTH(a.b12_fec_proceso) IN (01, 02, 03) THEN "TRIM-01"
	     WHEN MONTH(a.b12_fec_proceso) IN (04, 05, 06) THEN "TRIM-02"
	     WHEN MONTH(a.b12_fec_proceso) IN (07, 08, 09) THEN "TRIM-03"
	     WHEN MONTH(a.b12_fec_proceso) IN (10, 11, 12) THEN "TRIM-04"
	END AS trimes,
	"TARJETAS" AS c_iva,
	"TARJETAS" AS tip_m,
	"03 TJ-CREDITO" AS tip_tra,
	"TJ-CREDITO" AS tip_vta,
	"TJ-CREDITO" AS tip_pag,
	LPAD(b10_nivel, 2, 0) || " " || TRIM(b01_nombre) AS nive,
	NVL(LPAD(a.b12_subtipo, 2, 0) || " " || TRIM(b04_nombre),
		"SIN SUBTIPO") AS subt,
	a.b12_tipo_comp || "-" || TRIM(a.b12_num_comp) AS num_comp,
	DATE(a.b12_fec_proceso) AS fec_pro,
	TRIM(b.b13_cuenta) || " " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b.b13_valor_base), 0.00) AS saldo
	FROM ctbt012 a, ctbt013 b, ctbt010, ctbt001, OUTER ctbt004
	WHERE a.b12_compania           = 1
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso)  > 2010
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = a.b12_compania
	  		  AND b50_tipo_comp = a.b12_tipo_comp
	 		  AND b50_num_comp  = a.b12_num_comp)
	  AND b.b13_compania           = a.b12_compania
	  AND b.b13_tipo_comp          = a.b12_tipo_comp
	  AND b.b13_num_comp           = a.b12_num_comp
	  AND b.b13_cuenta            MATCHES "11210107*"
	  AND b.b13_tipo_comp         <> "DC"
	  AND b10_compania             = b.b13_compania
	  AND b10_cuenta               = b.b13_cuenta
	  AND b01_nivel                = b10_nivel
	  AND b04_compania             = a.b12_compania
	  AND b04_subtipo              = a.b12_subtipo
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
UNION
SELECT YEAR(a.b12_fec_proceso) AS anio,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	YEAR(a.b12_fec_proceso) || "-" ||
	CASE WHEN MONTH(a.b12_fec_proceso) IN (01, 02, 03) THEN "TRIM-01"
	     WHEN MONTH(a.b12_fec_proceso) IN (04, 05, 06) THEN "TRIM-02"
	     WHEN MONTH(a.b12_fec_proceso) IN (07, 08, 09) THEN "TRIM-03"
	     WHEN MONTH(a.b12_fec_proceso) IN (10, 11, 12) THEN "TRIM-04"
	END AS trimes,
	"TARJETAS" AS c_iva,
	"TARJETAS" AS tip_m,
	"03 TJ-CREDITO" AS tip_tra,
	"TJ-CREDITO" AS tip_vta,
	"TJ-CREDITO" AS tip_pag,
	LPAD(b10_nivel, 2, 0) || " " || TRIM(b01_nombre) AS nive,
	LPAD(b10_nivel, 2, 0) || " " || TRIM(b01_nombre) AS subt,
	"TD-" || TO_CHAR(a.b12_fec_proceso, "%y") ||
		LPAD(MONTH(a.b12_fec_proceso), 2, 0) AS num_comp,
	DATE(a.b12_fec_proceso) AS fec_pro,
	TRIM(b.b13_cuenta[1, 8]) || " " || TRIM(b10_descripcion) AS desc_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b.b13_valor_base), 0.00) AS saldo
	FROM ctbt010, ctbt013 b, ctbt012 a, ctbt001
	WHERE b10_compania             = 1
	  AND b10_cuenta              MATCHES "11210107*"
	  AND b10_nivel                = 5
	  AND b.b13_compania           = b10_compania
	  AND b.b13_cuenta[1, 8]       = b10_cuenta[1, 8]
	  AND b.b13_tipo_comp         <> "DC"
	  AND a.b12_compania           = b.b13_compania
	  AND a.b12_tipo_comp          = b.b13_tipo_comp
	  AND a.b12_num_comp           = b.b13_num_comp
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso)  > 2010
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = a.b12_compania
	  		  AND b50_tipo_comp = a.b12_tipo_comp
	 		  AND b50_num_comp  = a.b12_num_comp)
	  AND b01_nivel                = b10_nivel
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13;

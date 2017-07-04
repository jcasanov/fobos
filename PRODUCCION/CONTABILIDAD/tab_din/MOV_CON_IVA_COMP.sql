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
	END AS mes,
	b12_tipo_comp AS tip_com,
	b12_num_comp AS num_com,
	TRIM(b12_glosa) || " " || TRIM(b13_glosa) AS glos,
	b12_fec_proceso AS fec_pro,
	NVL((SELECT b04_nombre
		FROM ctbt004
		WHERE b04_compania = b12_compania
		  AND b04_subtipo  = b12_subtipo), "SIN SUBTIPO") AS subt,
	b13_cuenta AS cta,
	b10_descripcion AS nom_cta,
	NVL(b13_codprov, "") AS codp,
	NVL((SELECT p01_nomprov
		FROM cxpt001
		WHERE p01_codprov = b13_codprov), "SIN PROVEEDOR") AS nomp,
	NVL((SELECT p01_num_doc
		FROM cxpt001
		WHERE p01_codprov = b13_codprov), "") AS cedr,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	NVL((SELECT LPAD(c01_tipo_orden, 2, 0) || " " || TRIM(c01_nombre)
		FROM ordt040, ordt013, ordt010, ordt001
		WHERE c40_compania   = b12_compania
		  AND c40_tipo_comp  = b12_tipo_comp
		  AND c40_num_comp   = b12_num_comp
		  AND c13_compania   = c40_compania
		  AND c13_localidad  = c40_localidad
		  AND c13_numero_oc  = c40_numero_oc
		  AND c13_num_recep  = c40_num_recep
		  AND c13_estado     = "A"
		  AND c10_compania   = c13_compania
		  AND c10_localidad  = c13_localidad
		  AND c10_numero_oc  = c13_numero_oc
		  AND c01_tipo_orden = c10_tipo_orden),
		"00 SIN TIPO IVA") AS tip_iva,
	(SELECT b01_nombre
		FROM ctbt001
		WHERE b01_nivel = b10_nivel) AS nivel,
	CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_db,
	CASE WHEN b13_valor_base < 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_cr,
	b13_valor_base AS sald
	FROM ctbt013, ctbt012, ctbt010
	WHERE b13_compania           = 1
	  AND b13_cuenta[1, 8]       = "11300101"
	  AND YEAR(b13_fec_proceso) >= 2013
	  AND b12_compania           = b13_compania
	  AND b12_tipo_comp          = b13_tipo_comp
	  AND b12_num_comp           = b13_num_comp
	  AND b12_estado             = "M"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
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
	END AS mes,
	"TD" AS tip_com,
	"TODOS" AS num_com,
	"TODOS LOS DIARIOS" AS glos,
	b12_fec_proceso AS fec_pro,
	NVL((SELECT b04_nombre
		FROM ctbt004
		WHERE b04_compania = b12_compania
		  AND b04_subtipo  = b12_subtipo), "SIN SUBTIPO") AS subt,
	b13_cuenta[1, 8] AS cta,
	b10_descripcion AS nom_cta,
	"" AS codp,
	"SIN PROVEEDOR" AS nomp,
	"" AS cedr,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	"00 TODOS LOS TIPOS" AS tip_iva,
	(SELECT b01_nombre
		FROM ctbt001
		WHERE b01_nivel = b10_nivel) AS nivel,
	SUM(CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_db,
	SUM(CASE WHEN b13_valor_base < 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_cr,
	SUM(b13_valor_base) AS sald
	FROM ctbt013, ctbt012, ctbt010
	WHERE b13_compania           = 1
	  AND b13_cuenta[1, 8]       = "11300101"
	  AND YEAR(b13_fec_proceso) >= 2013
	  AND b12_compania           = b13_compania
	  AND b12_tipo_comp          = b13_tipo_comp
	  AND b12_num_comp           = b13_num_comp
	  AND b12_estado             = "M"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta[1, 8]
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15;

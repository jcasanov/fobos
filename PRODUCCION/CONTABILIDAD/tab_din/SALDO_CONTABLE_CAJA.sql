SELECT YEAR(a.b12_fec_proceso) AS anio, MONTH(a.b12_fec_proceso) AS mes,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "01_ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "03_MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "04_ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "05_MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "06_JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "07_JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "12_DICIEMBRE"
	END AS nom_mes,
	a.b12_subtipo AS subtipo,
	NVL((SELECT b04_nombre
		FROM ctbt004
		WHERE b04_compania = a.b12_compania
		  AND b04_subtipo  = a.b12_subtipo), "SIN SUBTIPO") AS nom_sub,
	TRIM(a.b12_usuario) AS usuario,
	CASE WHEN a.b12_origen = "A" THEN "AUTOMATICO"
	     WHEN a.b12_origen = "M" THEN "MANUAL"
	END AS origen,
	"CUENTA DETALLE" AS tipo_c,
	b.b13_tipo_comp AS tip_c,
	b.b13_num_comp AS num_c,
	--TO_CHAR(b.b13_fec_proceso, "%d-%m-%Y") AS fec_pro,
	b.b13_fec_proceso AS fec_pro,
	b.ROWID AS num_fil,
	--TRIM(a.b12_glosa) || " " || TRIM(b.b13_glosa) AS glosa,
	TRIM(b.b13_glosa) AS glosa,
	b.b13_cuenta AS cuenta,
	b10_descripcion AS nom_cta,
	CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END AS debito,
	CASE WHEN b.b13_valor_base < 0
		THEN b.b13_valor_base
		ELSE 0.00
	END AS credito
	FROM ctbt012 a, ctbt013 b, ctbt010
	WHERE a.b12_compania          = 1
	  AND a.b12_estado            = "M"
	  AND YEAR(a.b12_fec_proceso) > 2010
	  AND b.b13_compania          = a.b12_compania
	  AND b.b13_tipo_comp         = a.b12_tipo_comp
	  AND b.b13_num_comp          = a.b12_num_comp
	  AND b.b13_cuenta[1, 8]      = "11010101"
	  AND b10_compania            = b.b13_compania
	  AND b10_cuenta              = b.b13_cuenta
	ORDER BY 11, 12;

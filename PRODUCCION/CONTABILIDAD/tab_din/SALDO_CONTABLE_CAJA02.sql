SELECT YEAR(a.b12_fec_proceso) AS anio, 12 AS mes,
	"DICIEMBRE" AS nom_mes,
	"NA" AS subtipo,
	"SIN SUBTIPO" AS nom_sub,
	"GLOBAL" AS usuario,
	CASE WHEN 1 = 1 THEN "TODOS" END AS origen,
	"CUENTA DETALLE" AS tipo_c,
	"TT" AS tip_c,
	"TODOS" AS num_c,
	--TO_CHAR(b.b13_fec_proceso, "%d-%m-%Y") AS fec_pro,
	"" AS fec_pro,
	0 AS num_fil,
	--TRIM(a.b12_glosa) || " " || TRIM(b.b13_glosa) AS glosa,
	"" AS glosa,
	b.b13_cuenta AS cuenta,
	b10_descripcion AS nom_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS debito,
	SUM(CASE WHEN b.b13_valor_base < 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS credito
	FROM ctbt012 a, ctbt013 b, ctbt010
	WHERE a.b12_compania           = 1
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso) <= 2010
	  AND b.b13_compania           = a.b12_compania
	  AND b.b13_tipo_comp          = a.b12_tipo_comp
	  AND b.b13_num_comp           = a.b12_num_comp
	  AND b.b13_cuenta[1, 8]       = "11010101"
	  AND b10_compania             = b.b13_compania
	  AND b10_cuenta               = b.b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
	ORDER BY 1, 13;

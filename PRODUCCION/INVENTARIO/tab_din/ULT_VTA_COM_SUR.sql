SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs:gent002
		WHERE g02_compania  = a.r20_compania
		  AND g02_localidad = a.r20_localidad) AS local,
	"VENTA" AS tipo,
	a.r20_item AS item,
	"" AS ult_fec_com,
	NVL(MAX(a.r20_fecing), "") AS ult_fec_vta
	FROM acero_qs:rept020 a
	WHERE a.r20_compania   = 1
	  AND a.r20_localidad  = 4
	  AND a.r20_cod_tran   = "FA"
	  AND a.r20_cant_ven   >
		NVL((SELECT SUM(b.r20_cant_ven)
			FROM acero_qs:rept020 b, acero_qs:rept019 d
			WHERE b.r20_compania   = a.r20_compania
			  AND b.r20_localidad  = a.r20_localidad
			  AND b.r20_cod_tran   = a.r20_cod_tran
			  AND b.r20_num_tran   = a.r20_num_tran
			  AND b.r20_item       = a.r20_item
			  AND d.r19_compania   = b.r20_compania
			  AND d.r19_localidad  = b.r20_localidad
			  AND d.r19_cod_tran  IN ("DF", "AF")
			  AND d.r19_tipo_dev   = b.r20_cod_tran
			  AND d.r19_num_dev    = b.r20_num_tran), 0.00)
	GROUP BY 1, 2, 3, 4
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs:gent002
		WHERE g02_compania  = a.r20_compania
		  AND g02_localidad = a.r20_localidad) AS local,
	"COMPRA" AS tipo,
	a.r20_item AS item,
	NVL(MAX(a.r20_fecing), "") AS ult_fec_com,
	"" AS ult_fec_vta
	FROM acero_qs:rept020 a, acero_qs:rept019 d
	WHERE a.r20_compania   = 1
	  AND a.r20_localidad  = 4
	  AND a.r20_cod_tran  IN ("IM", "CL")
	  AND d.r19_compania   = a.r20_compania
	  AND d.r19_localidad  = a.r20_localidad
	  AND d.r19_cod_tran   = a.r20_cod_tran
	  AND d.r19_num_tran   = a.r20_num_tran
	  AND d.r19_tipo_dev  IS NULL
	GROUP BY 1, 2, 3, 5;

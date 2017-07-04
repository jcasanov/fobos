SELECT YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	DATE(r19_fecing) AS fec,
	fp_numero_semana(DATE(r19_fecing)) AS sem,
	LPAD(r19_vendedor, 2, 0) || " " || r01_nombres AS vend,
	r19_referencia AS refer,
	r20_bodega AS bd,
	CAST(r20_item AS INTEGER) AS item,
	r10_nombre AS descrip,
	r72_desc_clase AS clas,
	r10_marca AS marca,
	CASE WHEN r19_cod_tran = "A+"
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant
	FROM rept019, rept020, rept010, rept072, rept001
	WHERE r19_compania   = 1
	  AND r19_localidad  = 1
	  AND r19_cod_tran  IN ("A+", "A-")
	  AND r20_compania   = r19_compania
	  AND r20_localidad  = r19_localidad
	  AND r20_cod_tran   = r19_cod_tran
	  AND r20_num_tran   = r19_num_tran
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r01_compania   = r19_compania
	  AND r01_codigo     = r19_vendedor;

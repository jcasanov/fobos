SELECT CASE WHEN r22_localidad = 1 THEN "01 (J T M) TANCA"
	    WHEN r22_localidad = 2 THEN "02 GYE CENTRO"
	    WHEN r22_localidad = 3 THEN "03 MATRIZ UIO"
	    WHEN r22_localidad = 4 THEN "04 ACERO SUR"
	    WHEN r22_localidad = 5 THEN "05 ACERO KHOLER"
	END AS localidad,
	r22_anio AS anio,
	CASE WHEN r22_mes = 01 THEN "01 ENERO"
	     WHEN r22_mes = 02 THEN "02 FEBRERO"
	     WHEN r22_mes = 03 THEN "03 MARZO"
	     WHEN r22_mes = 04 THEN "04 ABRIL"
	     WHEN r22_mes = 05 THEN "05 MAYO"
	     WHEN r22_mes = 06 THEN "06 JUNIO"
	     WHEN r22_mes = 07 THEN "07 JULIO"
	     WHEN r22_mes = 08 THEN "08 AGOSTO"
	     WHEN r22_mes = 09 THEN "09 SEPTIEMBRE"
	     WHEN r22_mes = 10 THEN "10 OCTUBRE"
	     WHEN r22_mes = 11 THEN "11 NOVIEMBRE"
	     WHEN r22_mes = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r22_numprof AS proforma,
	r22_bodega AS bodega,
	{
	r03_nombre AS division,
	r70_desc_sub AS linea,
	r71_desc_grupo AS grupo,
	}
	r22_cod_clase AS clase,
	r72_desc_clase AS desc_clase,
	r22_item AS item,
	r22_descripcion AS descripcion,
	r22_marca AS marca,
	r22_cantidad AS cantidad,
	NVL(((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor,
	r01_nombres AS vendedor,
	r22_codcli AS codcli,
	r22_nomcli AS cliente,
	DATE(r22_fecing) AS fecha,
	CASE WHEN r22_cod_tran IS NULL
		THEN "NO FACTURADA"
		ELSE "FACTURADA"
	END AS tipo_prof,
	CASE WHEN r22_cod_tran IS NULL
		THEN "NN"
		ELSE r22_cod_tran
	END AS cod_tran,
	CASE WHEN r22_cod_tran IS NULL
		THEN 0
		ELSE r22_num_tran
	END AS cod_tran
	--FROM proforma, vendedor, division, linea, grupo, clase
	FROM proforma, vendedor, clase
	WHERE r22_localidad  = 1
	  AND r22_anio      >= 2009
	  AND r01_localidad  = r22_localidad
	  AND r01_codigo     = r22_vendedor
	  AND r72_linea      = r22_linea
	  AND r72_sub_linea  = r22_sub_linea
	  AND r72_cod_grupo  = r22_cod_grupo
	  AND r72_cod_clase  = r22_cod_clase
	ORDER BY 1, 2, 3, 17;

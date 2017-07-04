SELECT (SELECT r73_desc_marca
		FROM rept073
		WHERE r73_compania = r10_compania
		  AND r73_marca    = r10_marca) AS MARCA,
	r10_filtro AS FILTRO,
	(SELECT r01_iniciales
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS VENDEDOR,
	r19_cod_tran AS codtran,
	r19_num_tran AS numtran,
	NVL(r19_codcli, 99) AS codcli,
	r19_nomcli AS cliente,  
	DATE(r20_fecing) AS fecha_fact,
	CASE WHEN r19_cont_cred = "C" THEN "CONTADO"
	     WHEN r19_cont_cred = "R" THEN "CREDITO"
	     ELSE ""
	END AS formapago,
	r10_cod_clase AS clase,
	r20_item AS ITEMS,
	r10_nombre AS descripcion,
	CASE WHEN r19_cod_tran = 'FA'
		THEN NVL(r20_cant_ven, 0)
		ELSE NVL(r20_cant_ven, 0) * (-1)
        END AS can_vta,
	r20_precio AS PRECIO,
	r20_descuento AS por_dscto,
	CASE WHEN r19_cod_tran = 'FA'
		THEN NVL(r20_val_descto, 0)
		ELSE NVL(r20_val_descto, 0) * (-1)
        END AS val_dscto,
	CASE WHEN r19_cod_tran = 'FA' THEN
		NVL(((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	ELSE
		NVL(((r20_cant_ven * r20_precio) - r20_val_descto), 0) * (-1)
	END AS val_vta,
	r19_tipo_dev AS tipodev,
	r19_num_dev AS numdev,
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
	END AS mes_vta,
	CASE WHEN r19_vendedor IN (69, 10, 72, 14, 49, 17) THEN "BCV"
	     WHEN r19_vendedor IN (70, 18) THEN "GBM"
	END AS agt_ven,
	CAST(r10_linea AS INTEGER) AS linea,
	CASE WHEN r19_vendedor IN (69, 10, 72, 14, 49, 17) THEN 20
	     WHEN r19_vendedor IN (70, 18) THEN 68
	END AS codven
	FROM rept019, rept020, rept010
	WHERE  r19_compania      = 1
	  AND  r19_localidad     = 1
	  AND (r19_cod_tran     IN ("DF", "FA")
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     IN ("FA", "DF")))
	  AND  YEAR(r19_fecing)  = 2013
	  AND  r19_vendedor     IN (69, 10, 72, 14, 49, 17, 70, 18)
	  AND  r20_compania      = r19_compania
	  AND  r20_localidad     = r19_localidad
	  AND  r20_cod_tran      = r19_cod_tran
	  AND  r20_num_tran      = r19_num_tran
	  AND  r10_compania      = r20_compania
	  AND  r10_codigo        = r20_item
	ORDER BY 8 ASC, 3 ASC;

SELECT YEAR(r20_fecing) AS anio,
	(LPAD(MONTH(r20_fecing), 2, 0) || "_" || mes_nombre) AS mes,
	g02_nombre AS localidad,
	r20_cliente AS codcli,
	z01_nomcli AS nomcli,
	r20_bodega AS bodega,
	r20_item AS item,
	r20_cod_tran AS cod_tran,
	r20_num_tran AS num_tran,
	CASE WHEN r20_areaneg = 1
		THEN "INVENTARIO"
		ELSE "TALLER"
	END AS areaneg,
	r01_nombres AS vendedor,
	CASE WHEN r20_cont_cred = 'C'
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS formapago,
	r20_cant_ven AS cantidad,
	r20_val_descto AS descuento,
	NVL((r20_precio * r20_cant_ven) - r20_val_descto, 0) AS precio,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	DATE(r20_fecing) AS fecha
	FROM venta, cliente, item, clase, localidad, vendedor, meses
	WHERE YEAR(r20_fecing) > 2007
	  AND r10_codigo       = r20_item
	  AND z01_localidad    = r20_localidad
	  AND z01_codcli       = r20_cliente
	  AND r72_linea        = r10_linea
	  AND r72_sub_linea    = r10_sub_linea
	  AND r72_cod_grupo    = r10_cod_grupo
	  AND r72_cod_clase    = r10_cod_clase
	  AND g02_localidad    = r20_localidad
	  AND r01_localidad    = r20_localidad
	  AND r01_codigo       = r20_vendedor
	  AND numero_mes       = MONTH(r20_fecing);
	--ORDER BY 1, 2, 3, 14 DESC;

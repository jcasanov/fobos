SELECT r20_anio AS anio,
	CASE WHEN r20_mes = 01 THEN "01 ENERO"
	     WHEN r20_mes = 02 THEN "02 FEBRERO"
	     WHEN r20_mes = 03 THEN "03 MARZO"
	     WHEN r20_mes = 04 THEN "04 ABRIL"
	     WHEN r20_mes = 05 THEN "05 MAYO"
	     WHEN r20_mes = 06 THEN "06 JUNIO"
	     WHEN r20_mes = 07 THEN "07 JULIO"
	     WHEN r20_mes = 08 THEN "08 AGOSTO"
	     WHEN r20_mes = 09 THEN "09 SEPTIEMBRE"
	     WHEN r20_mes = 10 THEN "10 OCTUBRE"
	     WHEN r20_mes = 11 THEN "11 NOVIEMBRE"
	     WHEN r20_mes = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r20_cliente AS cod_cli,
	z01_nomcli AS nom_cli,
	r20_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r20_item AS item,
	r10_marca AS marca,
	CASE WHEN r20_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS forma_pago,
	CASE WHEN r20_cod_tran = "FA"
		THEN "FACTURAS"
		ELSE "DEVOLUCIONES"
	END AS tipo,
	CASE WHEN r20_cod_tran = "FA" THEN
		NVL((r20_val_descto), 0)
	ELSE
		NVL((r20_val_descto), 0)
	END AS descuento,
	CASE WHEN r20_cod_tran = "FA" THEN
		NVL(((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	ELSE
		NVL(((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	END AS valor_vta
	FROM venta, item, clase, vendedor, cliente
	WHERE r20_localidad IN (1, 2)
	  AND r10_codigo     = r20_item
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND z01_localidad  = r20_localidad
	  AND z01_codcli     = r20_cliente
	  AND r01_localidad  = r20_localidad
	  AND r01_codigo     = r20_vendedor;

SELECT r17_pedido AS pedido, r73_desc_marca AS marca, YEAR(r16_fecing) AS anio,
	CASE WHEN MONTH(r16_fecing) = 01 THEN "01_ENERO"
	     WHEN MONTH(r16_fecing) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(r16_fecing) = 03 THEN "03_MARZO"
	     WHEN MONTH(r16_fecing) = 04 THEN "04_ABRIL"
	     WHEN MONTH(r16_fecing) = 05 THEN "05_MAYO"
	     WHEN MONTH(r16_fecing) = 06 THEN "06_JUNIO"
	     WHEN MONTH(r16_fecing) = 07 THEN "07_JULLO"
	     WHEN MONTH(r16_fecing) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(r16_fecing) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(r16_fecing) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(r16_fecing) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(r16_fecing) = 12 THEN "12_DICIEMBRE"
	END AS meses,
	r16_fec_envio AS fecha_envio, r16_fec_llegada AS fecha_llegada,
	r17_item AS item, r10_cod_clase AS cod_clase, r72_desc_clase AS clase,
	r10_nombre AS descripcion, r17_cantped AS cantidad,
	CASE WHEN r17_estado = 'A' THEN 'ACTIVO'
	     WHEN r17_estado = 'C' THEN 'CONFIRMADO'
	     WHEN r17_estado = 'R' THEN 'RECIBIDO'
	     WHEN r17_estado = 'L' THEN 'LIQUIDACION'
	     WHEN r17_estado = 'P' THEN 'PROCESADO'
	     WHEN r17_estado = 'E' THEN 'ELIMINADO'
	END AS estado
	FROM rept016, rept017, rept010, rept072, rept073
	WHERE r17_compania  = r16_compania
	  AND r17_localidad = r16_localidad
	  AND r17_pedido    = r16_pedido
	  AND r10_compania  = r17_compania
	  AND r10_codigo    = r17_item
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND r73_compania  = r10_compania
	  AND r73_marca     = r10_marca
	ORDER BY 1, 3, 4

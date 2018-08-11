SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || g02_abreviacion
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS loc,
	YEAR(r19_fecing) AS anio,
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
	r19_cod_tran AS cod_tr,
	r19_num_tran AS num_tr,
	NVL(t23_cod_cliente, "") AS codcli,
	NVL(t23_nom_cliente, "") AS nomcli,
	NVL((SELECT r01_nombres
		FROM acero_qm@acgyede:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor), "") AS vend,
	DATE(r19_fecing) AS fecha,
	r19_tot_neto AS neto,
	NVL(r19_tipo_dev, "") AS cod_fact,
	NVL(r19_num_dev, "") AS num_fact,
	NVL(r19_ord_trabajo, "") AS orden,
	CASE WHEN t23_estado = "A" THEN "04_ACTIVA"
	     WHEN t23_estado = "C" THEN "03_CERRADA"
	     WHEN t23_estado = "F" THEN "01_FACTURADA"
	     WHEN t23_estado = "D" THEN "02_DEVUELTA"
	     WHEN t23_estado = "E" THEN "05_ELIMINADA"
	END AS estado_ot,
	r19_bodega_ori AS bod_ori,
	r19_bodega_dest AS bod_dest,
	NVL(r19_referencia, "") AS refer,
	CAST(r20_item AS INTEGER) AS item,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	r72_desc_clase AS clase,
	r19_usuario AS usua
	FROM acero_qm@acgyede:rept019,
		acero_qm@acgyede:talt023,
		acero_qm@acgyede:rept020,
		acero_qm@acgyede:rept010,
		acero_qm@acgyede:rept072
	WHERE r19_compania     = 1
	  AND r19_localidad    = 3
	  AND r19_cod_tran     = 'TR'
	  AND r19_ord_trabajo  IS NOT NULL
	  AND YEAR(r19_fecing) > 2012
	  AND t23_compania     = r19_compania
	  AND t23_localidad    = r19_localidad
	  AND t23_orden        = r19_ord_trabajo
	  AND r20_compania     = r19_compania
	  AND r20_localidad    = r19_localidad
	  AND r20_cod_tran     = r19_cod_tran
	  AND r20_num_tran     = r19_num_tran
	  AND r10_compania     = r20_compania
	  AND r10_codigo       = r20_item
	  AND r72_compania     = r10_compania
	  AND r72_linea        = r10_linea
	  AND r72_sub_linea    = r10_sub_linea
	  AND r72_cod_grupo    = r10_cod_grupo
	  AND r72_cod_clase    = r10_cod_clase;

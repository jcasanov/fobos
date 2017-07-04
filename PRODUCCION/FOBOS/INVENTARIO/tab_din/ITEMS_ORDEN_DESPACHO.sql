SELECT YEAR(a.r19_fecing) AS anio,
	CASE WHEN MONTH(a.r19_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(a.r19_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(a.r19_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(a.r19_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(a.r19_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(a.r19_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(a.r19_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(a.r19_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(a.r19_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(a.r19_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	a.r19_cod_tran AS cod_tran,
	a.r19_num_tran AS num_tran,
	a.r19_tipo_dev AS cod_dev,
	a.r19_num_dev AS num_dev,
	r34_num_ord_des AS orden_desp,
	r34_bodega AS bodega_desp,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS cliente,
	DATE(a.r19_fecing) AS fecha,
	CASE WHEN r34_estado = "A" THEN "ACTIVA"
	     WHEN r34_estado = "P" THEN "PARCIAL"
	     WHEN r34_estado = "E" THEN "ELIMINADA"
	     WHEN r34_estado = "D" THEN "DESPACHADA"
	END AS estado,
	r01_nombres AS vendedor,
	r34_usuario AS usuario,
	b.r20_item AS item,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	CASE WHEN a.r19_cod_tran = "FA"
		THEN b.r20_cant_ven
		ELSE b.r20_cant_ven * (-1)
	END AS cantidad,
	CASE WHEN a.r19_cod_tran = "FA"
		THEN r35_cant_des
		ELSE r35_cant_des * (-1)
	END AS cant_desp,
	CASE WHEN a.r19_cod_tran = "FA"
		THEN (r35_cant_des - r35_cant_ent)
		ELSE (r35_cant_des - r35_cant_ent) * (-1)
	END AS cant_pend,
	CASE WHEN a.r19_cod_tran = "FA"
		THEN r35_cant_ent
		ELSE r35_cant_ent * (-1)
	END AS cant_ent,
	NVL((SELECT SUM(CASE WHEN c.r19_bodega_ori = b.r20_bodega
				THEN d.r20_cant_ven
				ELSE d.r20_cant_ven * (-1)
			END)
		FROM rept019 c, rept020 d
		WHERE  c.r19_compania    = b.r20_compania
		  AND  c.r19_localidad   = b.r20_localidad
		  AND  c.r19_cod_tran    = "TR"
		  AND (c.r19_bodega_ori  = b.r20_bodega
		   OR  c.r19_bodega_dest = b.r20_bodega)
		  AND  c.r19_tipo_dev    = b.r20_cod_tran
		  AND  c.r19_num_dev     = b.r20_num_tran
		  AND  d.r20_compania    = c.r19_compania
		  AND  d.r20_localidad   = c.r19_localidad
		  AND  d.r20_cod_tran    = c.r19_cod_tran
		  AND  d.r20_num_tran    = c.r19_num_tran
		  AND  d.r20_item        = b.r20_item), 0.00) AS cruce,
	r10_marca AS marca
	FROM rept019 a, rept001, rept020 b, rept034, rept035, rept010, rept072
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 1
	  AND a.r19_cod_tran      = "FA"
	  AND YEAR(a.r19_fecing) >= 2010
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND b.r20_compania      = a.r19_compania
	  AND b.r20_localidad     = a.r19_localidad
	  AND b.r20_cod_tran      = a.r19_cod_tran
	  AND b.r20_num_tran      = a.r19_num_tran
	  AND r34_compania        = a.r19_compania
	  AND r34_localidad       = a.r19_localidad
	  AND r34_bodega          = b.r20_bodega
	  AND r34_cod_tran        = a.r19_cod_tran
	  AND r34_num_tran        = a.r19_num_tran
	  AND r35_compania        = r34_compania
	  AND r35_localidad       = r34_localidad
	  AND r35_bodega          = r34_bodega
	  AND r35_num_ord_des     = r34_num_ord_des
	  AND r35_item            = b.r20_item
	  AND r10_compania        = r35_compania
	  AND r10_codigo          = r35_item
	  AND r72_compania        = r10_compania
	  AND r72_linea           = r10_linea
	  AND r72_sub_linea       = r10_sub_linea
	  AND r72_cod_grupo       = r10_cod_grupo
	  AND r72_cod_clase       = r10_cod_clase
UNION
SELECT YEAR(a.r19_fecing) AS anio,
	CASE WHEN MONTH(a.r19_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(a.r19_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(a.r19_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(a.r19_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(a.r19_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(a.r19_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(a.r19_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(a.r19_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(a.r19_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(a.r19_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	a.r19_cod_tran AS cod_tran,
	a.r19_num_tran AS num_tran,
	a.r19_tipo_dev AS cod_dev,
	a.r19_num_dev AS num_dev,
	r34_num_ord_des AS orden_desp,
	0 AS num_entrega,
	r34_bodega AS bodega_desp,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS cliente,
	DATE(a.r19_fecing) AS fecha,
	CASE WHEN r34_estado = "A" THEN "ACTIVA"
	     WHEN r34_estado = "P" THEN "PARCIAL"
	     WHEN r34_estado = "E" THEN "ELIMINADA"
	     WHEN r34_estado = "D" THEN "DESPACHADA"
	END AS estado,
	r01_nombres AS vendedor,
	a.r19_usuario AS usuario,
	b.r20_item AS item,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	CASE WHEN a.r19_cod_tran = "FA"
		THEN b.r20_cant_ven
		ELSE b.r20_cant_ven * (-1)
	END AS cantidad,
	b.r20_cant_ven * (-1) AS cant_desp,
	0.00 AS cant_pend,
	b.r20_cant_ven * (-1) AS cant_ent,
	NVL((SELECT SUM(CASE WHEN e.r19_bodega_ori = b.r20_bodega
				THEN f.r20_cant_ven
				ELSE f.r20_cant_ven * (-1)
			END)
		FROM rept019 e, rept020 f
		WHERE  e.r19_compania    = b.r20_compania
		  AND  e.r19_localidad   = b.r20_localidad
		  AND  e.r19_cod_tran    = "TR"
		  AND (e.r19_bodega_ori  = b.r20_bodega
		   OR  e.r19_bodega_dest = b.r20_bodega)
		  AND  e.r19_tipo_dev    = b.r20_cod_tran
		  AND  e.r19_num_dev     = b.r20_num_tran
		  AND  f.r20_compania    = e.r19_compania
		  AND  f.r20_localidad   = e.r19_localidad
		  AND  f.r20_cod_tran    = e.r19_cod_tran
		  AND  f.r20_num_tran    = e.r19_num_tran
		  AND  f.r20_item        = b.r20_item), 0.00) AS cruce,
	r10_marca AS marca
	FROM rept019 a, rept001, rept020 b, rept034, rept035, rept010, rept072
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 1
	  AND a.r19_cod_tran     IN ("DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2010
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND b.r20_compania      = a.r19_compania
	  AND b.r20_localidad     = a.r19_localidad
	  AND b.r20_cod_tran      = a.r19_cod_tran
	  AND b.r20_num_tran      = a.r19_num_tran
	  AND r34_compania        = a.r19_compania
	  AND r34_localidad       = a.r19_localidad
	  AND r34_bodega          = b.r20_bodega
	  AND r34_cod_tran        = a.r19_tipo_dev
	  AND r34_num_tran        = a.r19_num_dev
	  AND r35_compania        = r34_compania
	  AND r35_localidad       = r34_localidad
	  AND r35_bodega          = r34_bodega
	  AND r35_num_ord_des     = r34_num_ord_des
	  AND r35_item            = b.r20_item
	  AND r10_compania        = r35_compania
	  AND r10_codigo          = r35_item
	  AND r72_compania        = r10_compania
	  AND r72_linea           = r10_linea
	  AND r72_sub_linea       = r10_sub_linea
	  AND r72_cod_grupo       = r10_cod_grupo
	  AND r72_cod_clase       = r10_cod_clase;

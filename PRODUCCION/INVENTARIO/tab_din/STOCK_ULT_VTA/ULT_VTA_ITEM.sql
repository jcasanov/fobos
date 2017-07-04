SELECT (SELECT LPAD(g02_localidad, 2, 0) || " J T M" --|| TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = b.r20_compania
		  AND g02_localidad = b.r20_localidad) AS loc,
	CAST(b.r20_item AS INTEGER) AS item_vta,
	DATE(b.r20_fecing) AS fec,
	b.r20_cod_tran AS tp,
	b.r20_num_tran AS num,
	b.r20_bodega AS bd,
	b.r20_cant_ven AS cant,
	((b.r20_cant_ven * b.r20_precio) - b.r20_val_descto) AS vta
	FROM rept020 b
	WHERE b.r20_compania   = 1
	  AND b.r20_localidad  = 1
	  AND b.r20_cod_tran   = "FA"
	  AND b.r20_fecing     =
		(SELECT MAX(c.r19_fecing)
			FROM rept020 d, rept019 c
			WHERE d.r20_compania   = b.r20_compania
			  AND d.r20_localidad  = b.r20_localidad
			  AND d.r20_cod_tran   = b.r20_cod_tran
			  AND d.r20_item       = b.r20_item
			  AND c.r19_compania   = d.r20_compania
			  AND c.r19_localidad  = d.r20_localidad
			  AND c.r19_cod_tran   = d.r20_cod_tran
			  AND c.r19_num_tran   = d.r20_num_tran
			  AND c.r19_tipo_dev  IS NULL)

SELECT UNIQUE t50_orden ot, t50_factura fact, t50_tipo_comp tc,
	t50_num_comp num, b13_cuenta cuenta
	FROM talt024, talt023, talt050, ctbt012, ctbt013
	WHERE t24_compania   = 1
	  AND t24_localidad  = 1
	  AND t24_codtarea   = '3'
	  AND t23_compania   = t24_compania
	  AND t23_localidad  = t24_localidad
	  AND t23_orden      = t24_orden
	  AND t23_estado    IN ('F', 'D')
	  AND t50_compania   = t23_compania
	  AND t50_localidad  = t23_localidad
	  AND t50_orden      = t23_orden
	  AND t50_factura    = t23_num_factura
	  AND b12_compania   = t50_compania
	  AND b12_tipo_comp  = t50_tipo_comp
	  AND b12_num_comp   = t50_num_comp
	  AND b12_estado    <> 'E'
	  AND b13_compania   = b12_compania
	  AND b13_tipo_comp  = b12_tipo_comp
	  AND b13_num_comp   = b12_num_comp
	  AND b13_cuenta    IN ('41010102003', '41010102103')

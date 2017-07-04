SELECT "CO" modulo, s23_sustento_tri sustento, "01" idtipo, p01_num_doc idprov,
	1 tc, c10_factura[1,3] establecimiento, c10_factura[5,7] pemision,
	c10_factura[9,15] secuencia, c13_num_aut aut, DAY(c13_fecha_recep) ||
	"/" || MONTH(c13_fecha_recep) || "/" || YEAR(c13_fecha_recep) fecha_reg,
	DAY(c13_fecha_recep) || "/" || MONTH(c13_fecha_recep) || "/" ||
	YEAR(c13_fecha_recep) fecha_emi, MONTH(TODAY) || "/" || YEAR(TODAY)
	fecha_cad, CASE WHEN c10_tot_impto = 0 THEN c10_tot_compra ELSE 0 END
	base_sin, CASE WHEN c10_tot_impto > 0 THEN
		(c10_tot_compra - c10_tot_impto) ELSE 0 END base_con,
	0 base_ice, 12 iva, 0 ice, c10_tot_impto monto_iva, 0 monto_ice,
	NVL((SELECT p28_valor_base || ", " || p28_porcentaje || ", " ||
		p28_valor_ret
		FROM cxpt028, cxpt027, ordt002
		WHERE p27_estado      = "A"
		  AND p28_tipo_ret    = "I"
		  AND c02_tipo_fuente = "B"
		  AND p27_compania    = p28_compania
		  AND p27_localidad   = p28_localidad
		  AND p27_num_ret     = p28_num_ret
		  AND p28_compania    = p20_compania
		  AND p28_localidad   = p20_localidad
		  AND p28_tipo_doc    = p20_tipo_doc
		  AND p28_num_doc     = p20_num_doc
		  AND p28_codprov     = p20_codprov
		  AND p28_dividendo   = p20_dividendo
		  AND c02_compania    = p28_compania
		  AND c02_tipo_ret    = p28_tipo_ret
		  AND c02_porcentaje  = p28_porcentaje), 0) bienes,
	NVL((SELECT p28_valor_base || ", " || p28_porcentaje || ", "
		|| p28_valor_ret
		FROM cxpt028, cxpt027, ordt002
		WHERE p27_estado      = "A"
		  AND p28_tipo_ret    = "I"
		  AND c02_tipo_fuente = "S"
		  AND p27_compania    = p28_compania
		  AND p27_localidad   = p28_localidad
		  AND p27_num_ret     = p28_num_ret
		  AND p28_compania    = p20_compania
		  AND p28_localidad   = p20_localidad
		  AND p28_tipo_doc    = p20_tipo_doc
		  AND p28_num_doc     = p20_num_doc
		  AND p28_codprov     = p20_codprov
		  AND p28_dividendo   = p20_dividendo
		  AND c02_compania    = p28_compania
		  AND c02_tipo_ret    = p28_tipo_ret
		  AND c02_porcentaje  = p28_porcentaje),0) servicios,
		CASE WHEN month(c10_fecing) = 01 THEN "ENE"
		     WHEN month(c10_fecing) = 02 THEN "FEB"
		     WHEN month(c10_fecing) = 03 THEN "MAR"
		     WHEN month(c10_fecing) = 04 THEN "ABR"
		     WHEN month(c10_fecing) = 05 THEN "MAY"
		     WHEN month(c10_fecing) = 06 THEN "JUN"
		     WHEN month(c10_fecing) = 07 THEN "JUL"
		     WHEN month(c10_fecing) = 08 THEN "AGO"
		     WHEN month(c10_fecing) = 09 THEN "SEP"
		     WHEN month(c10_fecing) = 10 THEN "OCT"
		     WHEN month(c10_fecing) = 11 THEN "NOV"
		     WHEN month(c10_fecing) = 12 THEN "DIC"
		END mes, YEAR(c10_fecing) anio, c10_usuario usuario,
	p20_codprov, p20_tipo_doc, p20_num_doc
	FROM ordt010, cxpt001, ordt001, ordt013, cxpt020, srit023
	WHERE c10_compania   = 1
	  AND c10_estado     = "C"
	  AND c13_estado     = "A"
	  AND c10_tipo_orden = c01_tipo_orden
	  AND c10_compania   = c13_compania
	  AND c10_localidad  = c13_localidad
	  AND c10_numero_oc  = c13_numero_oc
	  AND c10_compania   = p20_compania
	  AND c10_localidad  = p20_localidad
	  AND c10_numero_oc  = p20_numero_oc
	  AND s23_compania   = c10_compania
	  AND s23_tipo_orden = c10_tipo_orden
	  AND EXTEND(c10_fecing, YEAR TO MONTH) = "2007-04"
	  AND p01_codprov    = c10_codprov
UNION
SELECT "TE" modulo, "01" sustento, "01" idtipo, p01_num_doc idprov, 1 TC,
	p20_num_doc[1,3] establecimiento, p20_num_doc[5,7] pemision,
	p20_num_doc[9,15] secuencia, "1109999999" aut, DAY(p20_fecha_emi) ||
	"/" || MONTH(p20_fecha_emi) || "/" || YEAR(p20_fecha_emi) fecha_reg,
	DAY(p20_fecha_emi) || "/" || MONTH(p20_fecha_emi) || "/" ||
	YEAR(p20_fecha_emi) fecha_emi, MONTH(TODAY) || "/" || YEAR(TODAY)
	fecha_cad, CASE WHEN p20_valor_impto = 0 THEN p20_valor_fact ELSE 0 END
	base_sin, CASE WHEN p20_valor_impto > 0 THEN
		(p20_valor_fact - p20_valor_impto) ELSE 0 END base_con,
	0 base_ice, 12 iva, 0 ice, p20_valor_impto monto_iva, 0 monto_ice,
	NVL((SELECT p28_valor_base || ", " || p28_porcentaje || ", " ||
		p28_valor_ret
		FROM cxpt028, cxpt027, ordt002
		WHERE p27_estado      = "A"
		  AND p28_tipo_ret    = "I"
		  AND c02_tipo_fuente = "B"
		  AND p27_compania    = p28_compania
		  AND p27_localidad   = p28_localidad
		  AND p27_num_ret     = p28_num_ret
		  AND p28_compania    = p20_compania
		  AND p28_localidad   = p20_localidad
		  AND p28_tipo_doc    = p20_tipo_doc
		  AND p28_num_doc     = p20_num_doc
		  AND p28_codprov     = p20_codprov
		  AND p28_dividendo   = p20_dividendo    AND c02_compania    = p28_compania    AND c02_tipo_ret    = p28_tipo_ret    AND c02_porcentaje  = p28_porcentaje), 0) bienes, NVL((SELECT p28_valor_base || ", " || p28_porcentaje || ", " || p28_valor_ret  FROM cxpt028, cxpt027, ordt002  WHERE p27_estado      = "A"    AND p28_tipo_ret    = "I"    AND c02_tipo_fuente = "S"    AND p27_compania    = p28_compania    AND p27_localidad   = p28_localidad    AND p27_num_ret     = p28_num_ret    AND p28_compania    = p20_compania    AND p28_localidad   = p20_localidad    AND p28_tipo_doc    = p20_tipo_doc    AND p28_num_doc     = p20_num_doc    AND	p28_codprov     = p20_codprov    AND	p28_dividendo   = p20_dividendo    AND c02_compania    = p28_compania    AND c02_tipo_ret    = p28_tipo_ret   AND c02_porcentaje  = p28_porcentaje),0) servicios, CASE WHEN month(p20_fecha_emi) = 01 THEN "ENE"  WHEN month(p20_fecha_emi) = 02 THEN "FEB"  WHEN month(p20_fecha_emi) = 03 THEN "MAR"  WHEN month(p20_fecha_emi) = 04 THEN "ABR"  WHEN month(p20_fecha_emi) = 05 THEN "MAY"  WHEN month(p20_fecha_emi) = 06 THEN "JUN"  WHEN month(p20_fecha_emi) = 07 THEN "JUL"  WHEN month(p20_fecha_emi) = 08 THEN "AGO"  WHEN month(p20_fecha_emi) = 09 THEN "SEP"  WHEN month(p20_fecha_emi) = 10 THEN "OCT"  WHEN month(p20_fecha_emi) = 11 THEN "NOV"  WHEN month(p20_fecha_emi) = 12 THEN "DIC"  END mes, YEAR(p20_fecha_emi) anio, p20_usuario usuario,  p20_codprov, p20_tipo_doc, p20_num_doc  FROM cxpt020, cxpt041, cxpt001  WHERE p20_codprov     = p01_codprov    AND p20_compania    = p41_compania    AND p20_localidad   = p41_localidad    AND p20_codprov     = p41_codprov    AND p20_tipo_doc    = p41_tipo_doc    AND p20_num_doc     = p41_num_doc    AND p20_dividendo	= p41_dividendo    AND p20_tipo_doc    = "FA"    AND p20_compania    =           1   AND EXTEND(p20_fecha_emi, YEAR TO MONTH) = "2007-04-01 00:00:00" ORDER BY 7, 6  FROM cxpt020, cxpt001  WHERE p20_codprov  = p01_codprov    AND p20_tipo_doc = "FA"    AND p20_compania =           1   AND NOT EXISTS(SELECT 1 FROM ordt013, ordt010  WHERE c10_compania  = c13_compania    AND c10_localidad = c13_localidad    AND c10_numero_oc = c13_numero_oc    AND c13_factura   = p20_num_doc    AND c10_codprov   = p20_codprov)    AND EXTEND(p20_fecha_emi, YEAR TO MONTH) = "2007-04-01 00:00:00" ORDER BY 7, 6

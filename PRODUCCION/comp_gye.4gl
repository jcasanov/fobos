DATABASE acero_gm


DEFINE v_cod_loc	SMALLINT
DEFINE v_anio, v_mes	SMALLINT



MAIN

	IF num_args() <> 3 THEN
		DISPLAY 'Falta Localidad, Año y Mes.'
		EXIT PROGRAM
	END IF
	LET v_cod_loc = arg_val(1)
	LET v_anio    = arg_val(2)
	LET v_mes     = arg_val(3)
	CALL compras_jtm()

END MAIN



FUNCTION compras_jtm()

SET ISOLATION TO DIRTY READ
CALL proceso_obtener_compras(v_cod_loc)
CALL obtener_proveedores()
CALL salida_compras()

END FUNCTION



FUNCTION proceso_obtener_compras(cod_loc)
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE query		CHAR(4000)

LET query = 'SELECT p01_codprov, p01_nomprov, p01_num_doc, ',
		'LPAD(DAY(c10_fecing), 2, 0) || "/" || ',
		'LPAD(MONTH(c10_fecing), 2, 0) || "/" || ',
		'YEAR(c10_fecing) fecing, ',
		'LPAD(DAY(c10_fecha_fact), 2, 0) || "/" || ',
		'LPAD(MONTH(c10_fecha_fact), 2, 0) || "/" || ',
		'YEAR(c10_fecha_fact) c10_fecha_fact, ',
		' LPAD(c10_factura[1, 3], 3, 0) || ',
		'LPAD(c10_factura[5, 7], 3, 0) serie, ',
		'LPAD(c13_factura[9, 15], 7, 0) secuencia, ',
		'c13_num_aut, ',
		'NVL((c10_tot_repto + c10_tot_mano) - ',
		'c10_tot_dscto + c10_dif_cuadre + c10_otros, 0) subtotal, ',
		'c10_flete, c10_tot_impto, ',
		'NVL((SELECT NVL(p28_valor_base, 0) ',
			' FROM cxpt028, cxpt027 ',
			' WHERE p28_compania  = c13_compania ',
			'   AND p28_localidad = c13_localidad ',
			'   AND p28_codprov   = c10_codprov ',
			'   AND p28_num_doc   = c13_factura ',
			'   AND p28_tipo_ret  = "I" ',
			'   AND p27_compania  = p28_compania ',
			'   AND p27_localidad = p28_localidad ',
			'   AND p27_num_ret   = p28_num_ret ',
			'   AND p27_estado    = "A"), 0) valor_base, ',
		'NVL((SELECT NVL(p28_valor_ret, 0) ',
			' FROM cxpt028, cxpt027 ',
			' WHERE p28_compania  = c13_compania ',
			'   AND p28_localidad = c13_localidad ',
			'   AND p28_codprov   = c10_codprov ',
			'   AND p28_num_doc   = c13_factura ',
			'   AND p28_tipo_ret  = "I" ',
			'   AND p27_compania  = p28_compania ',
			'   AND p27_localidad = p28_localidad ',
			'   AND p27_num_ret   = p28_num_ret ',
			'   AND p27_estado    = "A"), 0) valor_iva, ',
		'NVL((SELECT NVL(p28_valor_ret, 0) ',
			' FROM cxpt028, cxpt027, ordt002 ',
			' WHERE p28_compania   = c13_compania ',
			'   AND p28_localidad  = c13_localidad ',
			'   AND p28_codprov    = c10_codprov ',
			'   AND p28_num_doc    = c13_factura ',
			'   AND p28_tipo_ret   = "F" ',
			'   AND p27_compania   = p28_compania ',
			'   AND p27_localidad  = p28_localidad ',
			'   AND p27_num_ret    = p28_num_ret ',
			'   AND p27_estado     = "A" ',
			'   AND c02_compania   = p28_compania ',
			'   AND c02_tipo_ret   = p28_tipo_ret ',
			'   AND c02_porcentaje = 1.00), 0) valor_ret ',
		' FROM ordt010, cxpt001, ordt013 ',
		' WHERE c10_compania   = 1 ',
		'   AND c10_localidad  = ', cod_loc,
		'   AND c10_tipo_orden = 1 ',
		'   AND c10_estado     = "C" ',
	        '   AND c10_moneda     = "DO" ',
	        '   AND EXTEND(c10_fecha_fact, YEAR TO MONTH) = ',
			'EXTEND(MDY(', v_mes, ', 01, ', v_anio,
				'), YEAR TO MONTH) ',
	        '   AND p01_codprov    = c10_codprov ',
		'   AND c13_compania   = c10_compania ',
		'   AND c13_localidad  = c10_localidad ',
		'   AND c13_numero_oc  = c10_numero_oc ',
		' INTO TEMP tmp_fac_pro '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp

END FUNCTION



FUNCTION obtener_proveedores()

UNLOAD TO "upproveedor.txt"
	SELECT UNIQUE p01_codprov, p01_num_doc, p01_nomprov
		FROM tmp_fac_pro
		WHERE subtotal <> 0
		ORDER BY 1

END FUNCTION



FUNCTION salida_compras()
DEFINE tot_neto		decimal(14,2)

UNLOAD TO "upcompras.txt"
	SELECT p01_num_doc, fecing, c10_fecha_fact, serie, secuencia,
		c13_num_aut, subtotal, c10_flete, c10_tot_impto, valor_base,
		valor_iva, valor_ret
		FROM tmp_fac_pro
		WHERE subtotal <> 0
		ORDER BY 1
SELECT SUM(subtotal) INTO tot_neto
	FROM tmp_fac_pro
	WHERE subtotal <> 0
	ORDER BY 1
DISPLAY "El Total Compras Año ", v_anio using '&&&&', " del Mes ", v_mes
	using '&&', " es   : ", tot_neto using "###,##&.##"
DROP TABLE tmp_fac_pro

END FUNCTION

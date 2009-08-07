SELECT b13_compania, b13_tipo_comp, b13_num_comp, b13_secuencia,
	b13_cuenta, b13_tipo_doc, b13_glosa, b13_valor_base,
	b13_valor_aux, b13_num_concil, b13_filtro, b13_fec_proceso, 0
	FROM ctbt013
	WHERE b13_compania   = 1
	  AND b13_cuenta     = ""
  	  AND b13_num_concil IN (0,1)
UNION ALL
SELECT b32_compania, b32_tipo_comp, b32_num_comp,
	b32_secuencia, b32_cuenta, b32_tipo_doc, b32_glosa,
	b32_valor_base, b32_valor_aux, b32_num_concil, 0,
	b32_fec_proceso, 1
	FROM ctbt032
	WHERE b32_compania   = 1
	  AND b32_cuenta     = ""
  	  AND b32_num_concil IN (0,1)
	ORDER BY 12, 2, 3

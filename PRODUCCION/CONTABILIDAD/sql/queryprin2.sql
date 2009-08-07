
SELECT b13_tipo_comp, b13_num_comp, b13_fec_proceso,',
 	0, 0, b13_glosa, b13_valor_base, b13_valor_aux',
	FROM ctbt013 ',
 	WHERE b13_compania   = 1
	  AND b13_cuenta     = "', rm_b30.b30_aux_cont, '"',
	  AND b13_num_concil = 0 ',
UNION ALL
SELECT b32_tipo_comp, b32_num_comp, b32_fec_proceso,',
	b32_num_cheque, b32_benef_che, b32_glosa, ',
	b32_valor_base, b32_valor_aux',
	FROM ctbt032 ',
	WHERE b32_compania   =1 
  	  AND b32_cuenta     = "',
		rm_b30.b30_aux_cont, '"',
          AND b32_num_concil = 0 ',
 	ORDER BY 3, 1, 2

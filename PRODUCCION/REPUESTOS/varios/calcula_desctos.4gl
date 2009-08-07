DATABASE diteca



MAIN
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE sum_descto	LIKE rept020.r20_val_descto
DEFINE subt			LIKE rept019.r19_tot_bruto
DEFINE porc			LIKE rept019.r19_descuento

DECLARE q_curs CURSOR FOR
	SELECT * FROM rept019
	 WHERE r19_compania  = 1
	   AND r19_cod_tran IN ('FA', 'DF', 'AF')
	   AND r19_descuento > 0
	 ORDER BY 1, 2, 3, 4

FOREACH q_curs INTO r_r19.*
	LET sum_descto = 0
	SELECT SUM(r20_val_descto) INTO sum_descto	
	  FROM rept020
	 WHERE r20_compania  = r_r19.r19_compania
	   AND r20_localidad = r_r19.r19_localidad
	   AND r20_cod_tran  = r_r19.r19_cod_tran
	   AND r20_num_tran  = r_r19.r19_num_tran

	IF r_r19.r19_tot_dscto >= sum_descto THEN
		LET subt = r_r19.r19_tot_bruto - sum_descto
		LET porc = 100 * (r_r19.r19_tot_dscto - sum_descto) / subt 
		IF porc < 0 THEN
			LET porc = 0
		END IF
		UPDATE rept019 SET r19_descuento = porc 
	 	 WHERE r19_compania  = r_r19.r19_compania
		   AND r19_localidad = r_r19.r19_localidad
		   AND r19_cod_tran  = r_r19.r19_cod_tran
		   AND r19_num_tran  = r_r19.r19_num_tran
	
		CONTINUE FOREACH	
	END IF
	
	IF r_r19.r19_tot_dscto < sum_descto THEN
		DISPLAY r_r19.r19_localidad, ' - ',r_r19.r19_cod_tran,
				r_r19.r19_num_tran, ' - ', r_r19.r19_descuento, '% - ',
				r_r19.r19_tot_dscto, ' - ', sum_descto	
		CONTINUE FOREACH	
	END IF

END FOREACH
FREE q_curs

END MAIN

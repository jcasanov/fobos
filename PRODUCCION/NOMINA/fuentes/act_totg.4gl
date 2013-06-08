DATABASE aceros

MAIN

CALL actualiza_total_ganado()

END MAIN



FUNCTION actualiza_total_ganado()
DEFINE r		RECORD LIKE rolt032.* 
DEFINE num_reg		INTEGER

DECLARE q1 CURSOR FOR SELECT *, ROWID FROM rolt032
FOREACH q1 INTO r.*, num_reg
	DISPLAY r.n32_cod_trab
	SELECT SUM(n33_valor) INTO r.n32_tot_gan 
		FROM rolt033
		WHERE n33_compania   = r.n32_compania   AND 
		      n33_cod_liqrol = r.n32_cod_liqrol AND 
		      n33_cod_trab   = r.n32_cod_trab   AND
		      n33_fecha_ini  = r.n32_fecha_ini  AND 
		      n33_fecha_fin  = r.n32_fecha_fin  AND 
		      n33_cant_valor = 'V' AND
		      n33_det_tot    = 'DI' AND
		      n33_cod_rubro IN (2,4,6,8,10,12,13)
	UPDATE rolt032 SET n32_tot_gan = r.n32_tot_gan
		WHERE ROWID = num_reg
END FOREACH

END FUNCTION

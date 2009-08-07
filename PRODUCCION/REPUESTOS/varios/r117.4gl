DATABASE diteca



MAIN
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r117		RECORD LIKE rept117.*

DECLARE q_curs CURSOR FOR
	SELECT * FROM rept019
	 WHERE r19_compania  = 1
	   AND r19_localidad = 1
	   AND r19_cod_tran  = 'IM'
	   AND r19_numliq IS NOT NULL
	   AND DATE(r19_fecing) <= MDY(09, 20, 2008) 
	 ORDER BY 1, 2, 3, 4

FOREACH q_curs INTO r_r19.*
	INITIALIZE r_r117.* TO NULL
	LET r_r117.r117_compania  = r_r19.r19_compania
	LET r_r117.r117_localidad = r_r19.r19_localidad
	LET r_r117.r117_cod_tran  = r_r19.r19_cod_tran
	LET r_r117.r117_num_tran  = r_r19.r19_num_tran
	LET r_r117.r117_numliq    = r_r19.r19_numliq

	DECLARE q_ped CURSOR FOR
		SELECT r29_pedido, r17_item, r20_cant_ven, r17_fob
		  FROM rept029, rept020, rept017
		 WHERE r29_compania  = r_r19.r19_compania
		   AND r29_localidad = r_r19.r19_localidad
		   AND r29_numliq    = r_r19.r19_numliq
		   AND r17_compania  = r29_compania 
		   AND r17_localidad = r29_localidad
		   AND r17_pedido    = r29_pedido
		   AND r20_compania  = r17_compania 
		   AND r20_localidad = r17_localidad
		   AND r20_cod_tran  = r_r19.r19_cod_tran
		   AND r20_num_tran  = r_r19.r19_num_tran
		   AND r20_item      = r17_item

	FOREACH q_ped INTO r_r117.r117_pedido, r_r117.r117_item,
					   r_r117.r117_cantidad, r_r117.r117_fob
		IF r_r117.r117_fob = 0 THEN
			LET r_r117.r117_fob = 0.01
		END IF
		IF r_r117.r117_cantidad = 0 THEN
			CONTINUE FOREACH
		END IF
		INSERT INTO rept117 VALUES (r_r117.*)
	END FOREACH
	FREE q_ped

END FOREACH
FREE q_curs

END MAIN

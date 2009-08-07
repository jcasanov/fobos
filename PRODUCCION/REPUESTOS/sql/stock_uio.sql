SELECT rept020.*, rept019.*, gent021.*   
  FROM rept020, rept019, gent021 
 WHERE r20_compania  = 1 
   AND r20_localidad = 2
   AND DATE(r20_fecing) BETWEEN mdy(01, 01, 2004) AND mdy(10, 28, 2004) 
   AND r19_compania  = r20_compania 
   AND r19_localidad = r20_localidad 
   AND r19_cod_tran  = r20_cod_tran 
   AND r19_num_tran  = r20_num_tran 
   AND g21_cod_tran  = r19_cod_tran 
 ORDER BY r20_item, r20_fecing 
		

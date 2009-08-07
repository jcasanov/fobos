SELECT rept020.*, rept019.*, gent021.* 
	FROM rept020, rept019, gent021 
        WHERE r20_compania  = 1 
          AND r20_localidad = 1 
          AND r20_item      = '6125-31-3131'
          AND r20_fecing BETWEEN mdy(1,1,2003) AND mdy(12,31,2003)
          AND r20_compania  = r19_compania 
          AND r20_localidad = r19_localidad
          AND r20_cod_tran  = r19_cod_tran 
          AND r20_num_tran  = r19_num_tran 
          AND r20_cod_tran  = g21_cod_tran 
        ORDER BY r20_fecing 

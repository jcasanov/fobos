DATABASE diteca


MAIN

DEFINE r_r20			RECORD LIKE rept020.*
DEFINE r_c11			RECORD LIKE ordt011.*
DEFINE r_117			RECORD LIKE rept117.*
DEFINE numero_oc		LIKE rept019.r19_oc_interna
DEFINE numliq			LIKE rept019.r19_numliq
DEFINE cantped			LIKE rept017.r17_cantped
DEFINE cantrec			LIKE rept017.r17_cantrec

DECLARE q_dcompras CURSOR FOR
	SELECT rept020.*, r19_oc_interna FROM rept020, rept019
	 WHERE r20_compania  = 1
	   AND r20_cod_tran  = 'CL'
	   AND r19_compania  = r20_compania
	   AND r19_localidad = r20_localidad
	   AND r19_cod_tran  = r20_cod_tran
	   AND r19_num_tran  = r20_num_tran
	   AND r19_tipo_tran = 'C'
	 ORDER BY r20_compania, r20_localidad, r20_cod_tran, r20_num_tran

FOREACH q_dcompras INTO r_r20.*, numero_oc
	INITIALIZE r_c11.* TO NULL
	SELECT * INTO r_c11.* FROM ordt011
	 WHERE c11_compania  = r_r20.r20_compania
	   AND c11_localidad = r_r20.r20_localidad
	   AND c11_numero_oc = numero_oc
	   AND c11_codigo    = r_r20.r20_item

	IF r_c11.c11_compania IS NOT NULL THEN
		UPDATE rept020 SET r20_cant_ped = r_c11.c11_cant_ped, 
						   r20_cant_ven = r_c11.c11_cant_rec,
						   r20_cant_ent = r_c11.c11_cant_rec
		 WHERE r20_compania  = r_r20.r20_compania
		   AND r20_localidad = r_r20.r20_localidad
		   AND r20_cod_tran  = r_r20.r20_cod_tran 
		   AND r20_num_tran  = r_r20.r20_num_tran 
		   AND r20_item      = r_r20.r20_item 
	END IF
END FOREACH

DECLARE q_dimp CURSOR FOR
	SELECT rept020.*, r19_numliq FROM rept020, rept019
	 WHERE r20_compania  = 1
	   AND r20_cod_tran  = 'IM'
	   AND r19_compania  = r20_compania
	   AND r19_localidad = r20_localidad
	   AND r19_cod_tran  = r20_cod_tran
	   AND r19_num_tran  = r20_num_tran
	   AND r19_tipo_tran = 'C'
	 ORDER BY r20_compania, r20_localidad, r20_cod_tran, r20_num_tran

FOREACH q_dimp INTO r_r20.*, numliq
	INITIALIZE cantrec, cantped TO NULL
	SELECT SUM(r117_cantidad), SUM(r17_cantped) INTO cantrec, cantped 
	  FROM rept117, rept017
	 WHERE r117_compania  = r_r20.r20_compania
	   AND r117_localidad = r_r20.r20_localidad
       AND r117_cod_tran  = 'IX'
	   AND r117_numliq    = numliq
	   AND r117_item      = r_r20.r20_item
	   AND r17_compania   = r117_compania
	   AND r17_localidad  = r117_localidad
	   AND r17_pedido     = r117_pedido   
	   AND r17_item       = r117_item     

display numliq, r_r20.r20_cod_tran, r_r20.r20_num_tran, cantped, cantrec
	IF cantrec IS NOT NULL THEN
		UPDATE rept020 SET r20_cant_ped = cantped, 
						   r20_cant_ven = cantrec,
						   r20_cant_ent = cantrec
		 WHERE r20_compania  = r_r20.r20_compania
		   AND r20_localidad = r_r20.r20_localidad
		   AND r20_cod_tran  = r_r20.r20_cod_tran 
		   AND r20_num_tran  = r_r20.r20_num_tran 
		   AND r20_item      = r_r20.r20_item 
	END IF
END FOREACH

UPDATE rept019  
   SET r19_tot_costo = (SELECT NVL(SUM(r20_cant_ven * r20_costo), 0)
						  FROM rept020
						 WHERE r20_compania  = r19_compania
						   AND r20_localidad = r19_localidad
						   AND r20_cod_tran  = r19_cod_tran
						   AND r20_num_tran  = r19_num_tran),
       r19_tot_neto  = (SELECT NVL(SUM(r20_cant_ven * r20_costo), 0)
						  FROM rept020
						 WHERE r20_compania  = r19_compania
						   AND r20_localidad = r19_localidad
						   AND r20_cod_tran  = r19_cod_tran
						   AND r20_num_tran  = r19_num_tran)
 WHERE r19_compania  = 1 
   AND r19_cod_tran  IN ('CL', 'IM') 
   AND r19_tipo_tran = 'C'

END MAIN

DATABASE diteca


MAIN

DEFINE r_r19			RECORD LIKE rept019.*
DEFINE cont_r100		INTEGER
DEFINE sum_r20			INTEGER

DISPLAY 'A+, DR, IC, IX y NI; son de ingreso y no mueven costo'
UPDATE rept019 SET r19_tipo_tran = 'I', r19_calc_costo = 'N'
 WHERE r19_compania = 1
   AND r19_cod_tran IN ('A+', 'DR', 'IC', 'IX', 'NI');

DISPLAY 'A-, DC, NE y RQ; son de egreso y no mueven costo'
UPDATE rept019 SET r19_tipo_tran = 'E', r19_calc_costo = 'N'
 WHERE r19_compania = 1
   AND r19_cod_tran IN ('A-', 'DC', 'NE', 'RQ');

DISPLAY 'AC no mueve stock pero si costo'
UPDATE rept019 SET r19_tipo_tran = 'C', r19_calc_costo = 'S'
 WHERE r19_compania = 1
   AND r19_cod_tran = 'AC';

DISPLAY 'TR mueve stock pero no costo'
UPDATE rept019 SET r19_tipo_tran = 'T', r19_calc_costo = 'N'
 WHERE r19_compania = 1
   AND r19_cod_tran = 'TR';

DISPLAY 'Procesando FA...'
DECLARE q_fact CURSOR FOR
	SELECT * FROM rept019
	 WHERE r19_compania = 1
	   AND r19_cod_tran = 'FA'
	 ORDER BY r19_compania, r19_localidad, r19_cod_tran, r19_num_tran

FOREACH q_fact INTO r_r19.*
	SELECT COUNT(*) INTO cont_r100 FROM rept100
	 WHERE r100_compania  = r_r19.r19_compania
	   AND r100_localidad = r_r19.r19_localidad
	   AND r100_cod_tran  = r_r19.r19_cod_tran 
	   AND r100_num_tran  = r_r19.r19_num_tran 

	IF cont_r100 > 0 THEN
		UPDATE rept019 SET r19_tipo_tran = 'E', r19_calc_costo = 'N'
		 WHERE r19_compania  = r_r19.r19_compania
		   AND r19_localidad = r_r19.r19_localidad
		   AND r19_cod_tran  = r_r19.r19_cod_tran 
		   AND r19_num_tran  = r_r19.r19_num_tran 
	ELSE
		UPDATE rept019 SET r19_tipo_tran = 'C', r19_calc_costo = 'N'
		 WHERE r19_compania  = r_r19.r19_compania
		   AND r19_localidad = r_r19.r19_localidad
		   AND r19_cod_tran  = r_r19.r19_cod_tran 
		   AND r19_num_tran  = r_r19.r19_num_tran 
	END IF
END FOREACH

DISPLAY 'Procesando DF y AF...'
DECLARE q_devfact CURSOR FOR
	SELECT * FROM rept019
	 WHERE r19_compania = 1
	   AND r19_cod_tran IN ('DF', 'AF')
	 ORDER BY r19_compania, r19_localidad, r19_cod_tran, r19_num_tran

FOREACH q_devfact INTO r_r19.*
	SELECT COUNT(*) INTO cont_r100 FROM rept100
	 WHERE r100_compania  = r_r19.r19_compania
	   AND r100_localidad = r_r19.r19_localidad
	   AND r100_cod_tran  = r_r19.r19_cod_tran 
	   AND r100_num_tran  = r_r19.r19_num_tran 

	IF cont_r100 > 0 THEN
		UPDATE rept019 SET r19_tipo_tran = 'I', r19_calc_costo = 'N'
		 WHERE r19_compania  = r_r19.r19_compania
		   AND r19_localidad = r_r19.r19_localidad
		   AND r19_cod_tran  = r_r19.r19_cod_tran 
		   AND r19_num_tran  = r_r19.r19_num_tran 
	ELSE
		UPDATE rept019 SET r19_tipo_tran = 'C', r19_calc_costo = 'N'
		 WHERE r19_compania  = r_r19.r19_compania
		   AND r19_localidad = r_r19.r19_localidad
		   AND r19_cod_tran  = r_r19.r19_cod_tran 
		   AND r19_num_tran  = r_r19.r19_num_tran 
	END IF
END FOREACH

DISPLAY 'Procesando CL e IM...'
DECLARE q_compras CURSOR FOR
	SELECT * FROM rept019
	 WHERE r19_compania = 1
	   AND r19_cod_tran IN ('CL', 'IM')
	 ORDER BY r19_compania, r19_localidad, r19_cod_tran, r19_num_tran

FOREACH q_compras INTO r_r19.*
	SELECT SUM(r20_cant_ven) INTO sum_r20 FROM rept020
	 WHERE r20_compania  = r_r19.r19_compania
	   AND r20_localidad = r_r19.r19_localidad
	   AND r20_cod_tran  = r_r19.r19_cod_tran 
	   AND r20_num_tran  = r_r19.r19_num_tran 

	IF sum_r20 > 0 THEN
		UPDATE rept019 SET r19_tipo_tran = 'I', r19_calc_costo = 'S'
		 WHERE r19_compania  = r_r19.r19_compania
		   AND r19_localidad = r_r19.r19_localidad
		   AND r19_cod_tran  = r_r19.r19_cod_tran 
		   AND r19_num_tran  = r_r19.r19_num_tran 
	ELSE
		UPDATE rept019 SET r19_tipo_tran = 'C', r19_calc_costo = 'S'
		 WHERE r19_compania  = r_r19.r19_compania
		   AND r19_localidad = r_r19.r19_localidad
		   AND r19_cod_tran  = r_r19.r19_cod_tran 
		   AND r19_num_tran  = r_r19.r19_num_tran 
	END IF
END FOREACH

END MAIN

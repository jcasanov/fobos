DATABASE aceros



DEFINE base		CHAR(20)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE orden		LIKE ordt010.c10_numero_oc
DEFINE fac_ant, fac_nue	LIKE cxpt020.p20_num_doc
DEFINE num_tran		LIKE rept019.r19_num_tran



MAIN
	
	IF num_args() <> 6 AND num_args() <> 7 THEN
		DISPLAY 'PARAMETROS INCORRECTOS.'
		DISPLAY 'SON: BASE@SERVIDOR COMPAÑÍA LOCALIDAD OC FACT_ANT FACT_NUE [CL]'
		EXIT PROGRAM
	END IF
	LET base     = arg_val(1)
	LET codcia   = arg_val(2)
	LET codloc   = arg_val(3)
	LET orden    = arg_val(4)
	LET fac_ant  = arg_val(5)
	LET fac_nue  = arg_val(6)
	LET num_tran = NULL
	IF num_args() = 7 THEN
		LET num_tran = arg_val(7)
	END IF
	CALL ejecutar_actualizacion()
	DISPLAY 'Actualización Terminada. OK'

END MAIN



FUNCTION ejecutar_actualizacion()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p23		RECORD LIKE cxpt023.*

CLOSE DATABASE

DATABASE base

SET ISOLATION TO DIRTY READ

BEGIN WORK

DISPLAY 'Iniciando Actualización ...'
IF num_tran IS NOT NULL THEN
	DISPLAY 'Actualizando registro en rept019 ...'
	UPDATE rept019
		SET r19_oc_externa = fac_nue
		WHERE r19_compania  = codcia
		  AND r19_localidad = codloc
		  AND r19_cod_tran  = 'CL'
		  AND r19_num_tran  = num_tran
END IF

IF orden > 0 THEN
	DISPLAY 'Actualizando registro en ordt010 ...'
	UPDATE ordt010
		SET c10_factura = fac_nue
		WHERE c10_compania  = codcia
		  AND c10_localidad = codloc
		  AND c10_numero_oc = orden

	INITIALIZE r_c10.* TO NULL
	SELECT * INTO r_c10.*
		FROM ordt010
		WHERE c10_compania  = codcia
		  AND c10_localidad = codloc
		  AND c10_numero_oc = orden

	DISPLAY 'Actualizando registro en ordt013 ...'
	UPDATE ordt013
		SET c13_factura  = fac_nue,
		    c13_num_guia = fac_nue
		WHERE c13_compania  = codcia
		  AND c13_localidad = codloc
		  AND c13_numero_oc = orden
		  AND c13_estado    = 'A'
		  --AND c13_num_recep = 1
ELSE
	INITIALIZE r_c10.* TO NULL
	DECLARE q_p20 CURSOR FOR
		SELECT p20_codprov
			FROM cxpt020
			WHERE p20_compania  = codcia
		          AND p20_localidad = codloc
		          AND p20_tipo_doc  = 'FA'
	        	  AND p20_num_doc   = fac_ant
	OPEN q_p20
	FETCH q_p20 INTO r_c10.c10_codprov
	CLOSE q_p20
	FREE q_p20
END IF

DISPLAY ' '
DISPLAY 'Chequeando si no existe algun pago ...'
DECLARE q_p23 CURSOR FOR
	SELECT * FROM cxpt023
		WHERE p23_compania  = codcia
	          AND p23_localidad = codloc
	          AND p23_codprov   = r_c10.c10_codprov
	          AND p23_tipo_doc  = 'FA'
	          AND p23_num_doc   = fac_ant
OPEN q_p23
FETCH q_p23 INTO r_p23.*
IF STATUS = NOTFOUND THEN
	DISPLAY 'Actualizando registro en cxpt020 ...'
	UPDATE cxpt020
		SET p20_num_doc = fac_nue
		WHERE p20_compania  = codcia
	          AND p20_localidad = codloc
	          AND p20_codprov   = r_c10.c10_codprov
	          AND p20_tipo_doc  = 'FA'
	          AND p20_num_doc   = fac_ant
	COMMIT WORK
	RETURN
END IF

DISPLAY ' '
DISPLAY 'Actualizando tablas del pago y contabilización ...'

SELECT * FROM cxpt020
	WHERE p20_compania  = codcia
          AND p20_localidad = codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = fac_ant
	INTO TEMP tmp_p20

UPDATE tmp_p20
	SET p20_num_doc = fac_nue
	WHERE p20_compania  = codcia
          AND p20_localidad = codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = fac_ant

DISPLAY 'Insertando registro en cxpt020 ...'

INSERT INTO cxpt020 SELECT * FROM tmp_p20

DISPLAY 'Actualizando registro en cxpt023 ...'

UPDATE cxpt023
	SET p23_num_doc = fac_nue
	WHERE p23_compania  = codcia
          AND p23_localidad = codloc
          AND p23_codprov   = r_c10.c10_codprov
          AND p23_tipo_doc  = 'FA'
          AND p23_num_doc   = fac_ant

DISPLAY 'Actualizando registro en cxpt025 ...'

UPDATE cxpt025
	SET p25_num_doc = fac_nue
	WHERE p25_compania  = codcia
          AND p25_localidad = codloc
          AND p25_codprov   = r_c10.c10_codprov
          AND p25_tipo_doc  = 'FA'
          AND p25_num_doc   = fac_ant

DISPLAY 'Actualizando registro en cxpt028 ...'

UPDATE cxpt028
	SET p28_num_doc = fac_nue
	WHERE p28_compania  = codcia
          AND p28_localidad = codloc
          AND p28_codprov   = r_c10.c10_codprov
          AND p28_tipo_doc  = 'FA'
          AND p28_num_doc   = fac_ant

DISPLAY 'Actualizando registro en cxpt041 ...'

UPDATE cxpt041
	SET p41_num_doc = fac_nue
	WHERE p41_compania  = codcia
          AND p41_localidad = codloc
          AND p41_codprov   = r_c10.c10_codprov
          AND p41_tipo_doc  = 'FA'
          AND p41_num_doc   = fac_ant

DISPLAY 'Borrando registro en cxpt020 de factura anterior ...'

DELETE FROM cxpt020
	WHERE p20_compania  = codcia
          AND p20_localidad = codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = fac_ant

COMMIT WORK

RETURN

END FUNCTION

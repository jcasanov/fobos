DATABASE aceros



DEFINE base		CHAR(20)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codcli		LIKE rept019.r19_codcli
DEFINE cedruc		LIKE rept019.r19_cedruc
DEFINE fec_ini, fec_fin	DATE
DEFINE vm_flag		CHAR(1)



MAIN
	
	IF num_args() <> 5 AND num_args() <> 6 AND num_args() <> 7 THEN
		DISPLAY 'PARAMETROS INCORRECTOS.'
		DISPLAY 'SON (1): BASE@SERVIDOR COMPANIA LOCALIDAD CLIENTE CEDRUC_NUE'
		DISPLAY 'SON (2): BASE@SERVIDOR COMPANIA LOCALIDAD CLIENTE CEDRUC_NUE FEC_INI FEC_FIN'
		DISPLAY 'SON (3): BASE@SERVIDOR COMPANIA LOCALIDAD CLIENTE CEDRUC_OLD FLAG = V'
		EXIT PROGRAM
	END IF
	LET base    = arg_val(1)
	LET codcia  = arg_val(2)
	LET codloc  = arg_val(3)
	LET codcli  = arg_val(4)
	LET cedruc  = arg_val(5)
	LET vm_flag = 'M'
	LET fec_ini = NULL
	LET fec_fin = NULL
	CASE num_args()
		WHEN 6	LET vm_flag = arg_val(6)
		WHEN 7	LET fec_ini = arg_val(6)
			LET fec_fin = arg_val(7)
	END CASE
	IF vm_flag = 'M' THEN
		CALL ejecutar_actualizacion()
		DISPLAY 'Actualización Terminada. OK'
	ELSE
		CALL ejecutar_verificacion()
		DISPLAY 'Verificacion Terminada. OK'
	END IF

END MAIN



FUNCTION ejecutar_actualizacion()
DEFINE query		CHAR(800)
DEFINE expr_fec		CHAR(150)

CLOSE DATABASE

DATABASE base

SET ISOLATION TO DIRTY READ

BEGIN WORK

DISPLAY 'Iniciando Actualización ...'
DISPLAY 'Actualizando registro en rept019 ...'
LET expr_fec = NULL
IF fec_ini IS NOT NULL THEN
	LET expr_fec = '   AND DATE(r19_fecing) BETWEEN "', fec_ini,
						 '" AND "', fec_fin, '"'
END IF
LET query = 'UPDATE rept019 ',
		' SET r19_cedruc = "', cedruc CLIPPED, '"',
		' WHERE r19_compania   = ', codcia,
		'   AND r19_localidad  = ', codloc,
		'   AND r19_cod_tran  IN ("FA", "DF", "AF") ',
		'   AND r19_codcli     = ', codcli,
		expr_fec CLIPPED
PREPARE exec_r19 FROM query
EXECUTE exec_r19

DISPLAY 'Actualizando registro en rept021 ...'
LET expr_fec = NULL
IF fec_ini IS NOT NULL THEN
	LET expr_fec = '   AND DATE(r21_fecing) BETWEEN "', fec_ini,
						 '" AND "', fec_fin, '"'
END IF
LET query = 'UPDATE rept021 ',
		' SET r21_cedruc = "', cedruc CLIPPED, '"',
		' WHERE r21_compania   = ', codcia,
		'   AND r21_localidad  = ', codloc,
		'   AND r21_codcli     = ', codcli,
		expr_fec CLIPPED
PREPARE exec_r21 FROM query
EXECUTE exec_r21

DISPLAY 'Actualizando registro en rept023 ...'
LET expr_fec = NULL
IF fec_ini IS NOT NULL THEN
	LET expr_fec = '   AND DATE(r23_fecing) BETWEEN "', fec_ini,
						 '" AND "', fec_fin, '"'
END IF
LET query = 'UPDATE rept023 ',
		' SET r23_cedruc = "', cedruc CLIPPED, '"',
		' WHERE r23_compania   = ', codcia,
		'   AND r23_localidad  = ', codloc,
		'   AND r23_codcli     = ', codcli,
		expr_fec CLIPPED
PREPARE exec_r23 FROM query
EXECUTE exec_r23

DISPLAY ' '

COMMIT WORK

RETURN

END FUNCTION



FUNCTION ejecutar_verificacion()
DEFINE fecha, fec_aux	DATETIME YEAR TO MONTH
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE cuantos		INTEGER

CLOSE DATABASE

DATABASE base

SET ISOLATION TO DIRTY READ

DISPLAY 'Iniciando Verificacion ...'
DISPLAY 'Verificando registro en rept019 ...'
DECLARE q_r19 CURSOR FOR
	SELECT EXTEND(r19_fecing, YEAR TO MONTH), r19_cod_tran, COUNT(*)
		FROM rept019
		WHERE r19_compania   = codcia
		  AND r19_localidad  = codloc
		  AND r19_cod_tran  IN ("FA", "DF", "AF")
		  AND r19_codcli     = codcli
		  AND r19_cedruc     = cedruc
		GROUP BY 1, 2
		ORDER BY 1, 2
DISPLAY ' '
DISPLAY '  FECHA    TP  TOTAL'
DISPLAY '  =====    ==  ====='
LET fec_aux = NULL
FOREACH q_r19 INTO fecha, cod_tran, cuantos
	DISPLAY '  ', fecha, '  ', cod_tran, '  ', cuantos USING "<<<<<&"
	IF fec_aux IS NULL THEN
		LET fec_aux = fecha
	END IF
	IF fec_aux <> fecha THEN
		DISPLAY ' '
		LET fec_aux = fecha
	END IF
END FOREACH
DISPLAY ' '
DISPLAY 'Verificando registro en rept021 ...'
DECLARE q_r21 CURSOR FOR
	SELECT EXTEND(r21_fecing, YEAR TO MONTH), COUNT(*)
		FROM rept021
		WHERE r21_compania   = codcia
		  AND r21_localidad  = codloc
		  AND r21_codcli     = codcli
		  AND r21_cedruc     = cedruc
		GROUP BY 1
		ORDER BY 1
DISPLAY ' '
DISPLAY '  FECHA    TOTAL PROF.'
DISPLAY '  =====    ==========='
FOREACH q_r21 INTO fecha, cuantos
	DISPLAY '  ', fecha, '  ', cuantos USING "<<<<<&"
	DISPLAY ' '
END FOREACH
DISPLAY 'Verificando registro en rept023 ...'
DECLARE q_r23 CURSOR FOR
	SELECT EXTEND(r23_fecing, YEAR TO MONTH), COUNT(*)
		FROM rept023
		WHERE r23_compania   = codcia
		  AND r23_localidad  = codloc
		  AND r23_codcli     = codcli
		  AND r23_cedruc     = cedruc
		GROUP BY 1
		ORDER BY 1
DISPLAY ' '
DISPLAY '  FECHA    TOTAL PREV.'
DISPLAY '  =====    ==========='
FOREACH q_r23 INTO fecha, cuantos
	DISPLAY '  ', fecha, '  ', cuantos USING "<<<<<&"
	DISPLAY ' '
END FOREACH

END FUNCTION

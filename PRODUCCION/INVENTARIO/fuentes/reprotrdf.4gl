DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE vm_bod_sstock	LIKE gent002.g02_localidad
DEFINE base		CHAR(20)
DEFINE tr_ini_df	INTEGER



MAIN

	IF num_args() <> 1 THEN
		DISPLAY 'Error de Parametros. Falta la Localidad.'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	LET codloc = arg_val(1)
	CASE codloc
		WHEN 1
			--LET base      = 'aceros'
			LET base      = 'acero_gm'
			LET tr_ini_df = 6054
		WHEN 2
			LET base = 'acero_gc'
			LET tr_ini_df = 1384
		WHEN 3
			LET base = 'acero_qm'
			LET tr_ini_df = 17260
		WHEN 4
			LET base = 'acero_qs'
			LET tr_ini_df = 5589
	END CASE
	CALL activar_base()
	CALL validar_parametros()
	CALL ejecuta_proceso()

END MAIN



FUNCTION activar_base()
DEFINE r_g51		RECORD LIKE gent051.*

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051
	WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g02.* TO NULL
SELECT * INTO r_g02.* FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la Localidad ', codloc USING '<<&', '.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()

INITIALIZE vm_bod_sstock TO NULL
DECLARE q_bod CURSOR FOR
	SELECT r02_codigo INTO vm_bod_sstock
		FROM rept002
		WHERE r02_compania  = codcia
		  AND r02_localidad = codloc
		  AND r02_estado    = 'A'
		  AND r02_tipo      = 'S'
OPEN q_bod
FETCH q_bod INTO vm_bod_sstock
IF vm_bod_sstock IS NULL THEN
	DISPLAY 'No existe configurada una bodega sin stock.'
	EXIT PROGRAM
END IF
CLOSE q_bod
FREE q_bod
BEGIN WORK
DISPLAY 'Iniciando Reproceso de TR para ligar con DF. Por favor espere ...'
CALL actualizacion_tr_df()
DISPLAY ' '
DISPLAY ' '
DISPLAY 'Iniciando Reproceso de TR para ligar con FA. Por favor espere ...'
CALL actualizacion_tr_fa()
DISPLAY ' '
COMMIT WORK
DISPLAY 'Reproceso Terminado OK.'

END FUNCTION



FUNCTION actualizacion_tr_df()
DEFINE r_transf		RECORD LIKE rept019.*
DEFINE r_dev		RECORD LIKE rept019.*
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE i, j, l		SMALLINT
DEFINE num_c		VARCHAR(15)

DECLARE q_trans1 CURSOR FOR
	SELECT * FROM rept019
		WHERE r19_compania   = codcia
		  AND r19_localidad  = codloc
		  AND r19_cod_tran   = 'TR'
		  AND r19_tipo_dev   IS NULL
		  AND r19_referencia LIKE '%GEN. DEV/ANU # %'
		ORDER BY r19_num_tran ASC
LET i = 0
LET l = 0
FOREACH q_trans1 INTO r_transf.*
	LET l = l + 1
	DISPLAY '  Reprocesando: ', r_transf.r19_cod_tran, '-',
		r_transf.r19_num_tran USING "<<<<<<<&", ' espere ... '
	LET num_c = NULL
	FOR j = 16 TO LENGTH(r_transf.r19_referencia)
		IF r_transf.r19_referencia[j, j] = ' ' THEN
			EXIT FOR
		END IF
		LET num_c = num_c CLIPPED, r_transf.r19_referencia[j, j]
	END FOR
	LET cod_tran = 'FA'
	IF r_transf.r19_num_tran >= tr_ini_df THEN
		LET cod_tran = 'DF'
	END IF
	LET num_tran = num_c
	IF cod_tran = 'FA' THEN
		INITIALIZE r_dev.* TO NULL
		DECLARE q_dev CURSOR FOR
			SELECT UNIQUE rept019.*
				FROM rept019, rept020
				WHERE r19_compania  = r_transf.r19_compania
				  AND r19_localidad = r_transf.r19_localidad
				  AND r19_cod_tran  = 'DF'
				  AND r19_tipo_dev  = cod_tran
				  AND r19_num_dev   = num_tran
				  AND r20_compania  = r19_compania
				  AND r20_localidad = r19_localidad
				  AND r20_cod_tran  = r19_cod_tran
				  AND r20_num_tran  = r19_num_tran
				  AND r20_bodega    = vm_bod_sstock
				ORDER BY r19_num_tran ASC
		OPEN q_dev
		FETCH q_dev INTO r_dev.*
		CLOSE q_dev
		FREE q_dev
		IF r_dev.r19_compania IS NULL THEN
			DISPLAY '  ', r_transf.r19_cod_tran, '-',
				r_transf.r19_num_tran USING "<<<<<<<&",
				' no tiene DF para ligar.'
			DISPLAY ' '
			CONTINUE FOREACH
		END IF
		LET cod_tran = r_dev.r19_cod_tran
		LET num_tran = r_dev.r19_num_tran
	END IF
	UPDATE rept019 SET r19_tipo_dev = cod_tran,
			   r19_num_dev  = num_tran
		WHERE r19_compania  = r_transf.r19_compania
		  AND r19_localidad = r_transf.r19_localidad
		  AND r19_cod_tran  = r_transf.r19_cod_tran
		  AND r19_num_tran  = r_transf.r19_num_tran
	DISPLAY '  Actualizada: ', r_transf.r19_cod_tran, '-',
		r_transf.r19_num_tran USING "<<<<<<<&", ' con ', cod_tran, '-',
		num_tran USING "<<<<<<<&", '  OK.'
	DISPLAY ' '
	LET i = i + 1
END FOREACH
DISPLAY 'Se ligaron ', i USING "<<<<&", ' TR con DF. Total reg. procesados ',
	l USING "<<<<&", ' OK.'

END FUNCTION



FUNCTION actualizacion_tr_fa()
DEFINE r_transf		RECORD LIKE rept019.*
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE num_entrega	LIKE rept036.r36_num_entrega
DEFINE i, j, l, ini	SMALLINT
DEFINE num_c		VARCHAR(15)

DECLARE q_trans2 CURSOR FOR
	SELECT * FROM rept019
		WHERE r19_compania   = codcia
		  AND r19_localidad  = codloc
		  AND r19_cod_tran   = 'TR'
		  AND r19_tipo_dev   IS NULL
		  AND r19_referencia LIKE '%AUTO. SIN STOCK GEN. POR NE # %'
		ORDER BY r19_num_tran ASC
LET i = 0
LET l = 0
FOREACH q_trans2 INTO r_transf.*
	LET l = l + 1
	DISPLAY '  Reprocesando: ', r_transf.r19_cod_tran, '-',
		r_transf.r19_num_tran USING "<<<<<<<&", ' espere ... '
	LET num_c = NULL
	LET ini   = 35
	IF r_transf.r19_referencia[1, 5] = 'TRANS' THEN
		LET ini = 38
	END IF
	FOR j = ini TO LENGTH(r_transf.r19_referencia)
		IF r_transf.r19_referencia[j, j] = ' ' THEN
			EXIT FOR
		END IF
		LET num_c = num_c CLIPPED, r_transf.r19_referencia[j, j]
	END FOR
	LET num_entrega = num_c
	INITIALIZE r_r34.* TO NULL
	SELECT rept034.* INTO r_r34.*
		FROM rept036, rept034
		WHERE r36_compania    = r_transf.r19_compania
		  AND r36_localidad   = r_transf.r19_localidad
		  AND r36_bodega      = vm_bod_sstock
		  AND r36_num_entrega = num_entrega
		  AND r34_compania    = r36_compania 
		  AND r34_localidad   = r36_localidad 
		  AND r34_bodega      = r36_bodega 
		  AND r34_num_ord_des = r36_num_ord_des 
	IF r_r34.r34_compania IS NULL THEN
		ROLLBACK WORK
		DISPLAY 'ERROR: No exsite Nota de Entrega ', vm_bod_sstock, ' ',
			num_entrega USING "<<<<<<<&"
		DISPLAY 'Reproceso no pudo Terminar  OK.'
		EXIT PROGRAM
	END IF
	UPDATE rept019 SET r19_tipo_dev = r_r34.r34_cod_tran,
			   r19_num_dev  = r_r34.r34_num_tran
		WHERE r19_compania  = r_transf.r19_compania
		  AND r19_localidad = r_transf.r19_localidad
		  AND r19_cod_tran  = r_transf.r19_cod_tran
		  AND r19_num_tran  = r_transf.r19_num_tran
	DISPLAY '  Actualizada: ', r_transf.r19_cod_tran, '-',
		r_transf.r19_num_tran USING "<<<<<<<&", ' con ',
		r_r34.r34_cod_tran, '-', r_r34.r34_num_tran USING "<<<<<<<&",
		'  OK.'
	DISPLAY ' '
	LET i = i + 1
END FOREACH
DISPLAY 'Se ligaron ', i USING "<<<<&", ' TR con FA. Total reg. procesados ',
	l USING "<<<<&", ' OK.'

END FUNCTION

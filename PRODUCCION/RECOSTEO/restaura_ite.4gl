DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad



MAIN
	
	IF num_args() <> 4 THEN
		DISPLAY 'ERROR DE PARAMETROS. FALTAN: base servidor_base ',
			'compañía localidad.'
		EXIT PROGRAM
	END IF
	CALL activar_base(arg_val(1), arg_val(2))
	LET codcia = arg_val(3)
	LET codloc = arg_val(4)
	CALL validar_parametros()
	IF NOT restaura_datos() THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		DISPLAY 'Restauracion no pudo realizarse.'
	ELSE
		WHENEVER ERROR STOP
		COMMIT WORK
		DISPLAY 'Restauracion Terminada OK.'
	END IF
	BEGIN WORK 
		DELETE FROM rept020_res
		DELETE FROM rept019_res
		DELETE FROM rept010_res
		DELETE FROM ctbt013_res
		DELETE FROM trans_ent
		DELETE FROM trans_salida
		DISPLAY ' '
		DISPLAY 'Registro borrados en tablas de respaldo (_res). OK'
	COMMIT WORK

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base, ' en la tabla gent051.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g01.*, r_g02.* TO NULL
SELECT * INTO r_g01.*
	FROM gent001
	WHERE g01_compania = codcia
IF r_g01.g01_compania IS NULL THEN
	DISPLAY 'No existe la compañía ', codcia USING "<<<&", ' en la base.'
	EXIT PROGRAM
END IF
SELECT * INTO r_g02.*
	FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la localidad ', codloc USING "<<<&", ' en la base.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION restaura_datos()
DEFINE cuantos, i	INTEGER
DEFINE r_r19		RECORD LIKE rept019_res.*
DEFINE r_r20		RECORD LIKE rept020_res.*
DEFINE r_r10		RECORD LIKE rept010_res.*
DEFINE r_b13		RECORD LIKE ctbt013_res.*

SET ISOLATION TO DIRTY READ
BEGIN WORK
WHENEVER ERROR CONTINUE
DISPLAY 'Inicia proceso de Restauracion. Por favor espere ...'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos
	FROM rept019_res
	WHERE r19_compania  = codcia
	  AND r19_localidad = codloc
IF cuantos = 0 THEN
	DISPLAY 'No se puede restaurar tabla rept019. ',
		'No tiene datos la tabla rept019_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY 'Restaurando tabla rept019. Por favor espere ...'
DECLARE q_r19 CURSOR FOR
	SELECT * FROM rept019_res
		WHERE r19_compania  = codcia
		  AND r19_localidad = codloc
		ORDER BY r19_cod_tran, r19_num_tran
LET i = 0
FOREACH q_r19 INTO r_r19.*
	DISPLAY '  Restaurando registro: ', r_r19.r19_cod_tran, '-',
		r_r19.r19_num_tran USING "<<<<<<<<&"
	UPDATE rept019
		SET r19_tot_costo = r_r19.r19_tot_costo,
		    r19_tot_neto  = r_r19.r19_tot_neto
		WHERE r19_compania  = r_r19.r19_compania
		  AND r19_localidad = r_r19.r19_localidad
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
	IF STATUS < 0 THEN
		DISPLAY '  Ha ocurrido un error al actualizar el registro',
			' en rept019.'
		DISPLAY ' '
		RETURN 0
	END IF
	IF STATUS = NOTFOUND THEN
		DISPLAY '  No se ha podido encontrar el registro en rept019.'
		DISPLAY ' '
		RETURN 0
	END IF
	LET i = i + 1
END FOREACH
DISPLAY 'Se restauraron un total de ', i USING "<<<<<<&", ' reg. en tabla',
	' rept019. OK'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos
	FROM rept020_res
	WHERE r20_compania  = codcia
	  AND r20_localidad = codloc
IF cuantos = 0 THEN
	DISPLAY 'No se puede restaurar tabla rept020. ',
		'No tiene datos la tabla rept020_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY 'Restaurando tabla rept020. Por favor espere ...'
DECLARE q_r20 CURSOR FOR
	SELECT * FROM rept020_res
		WHERE r20_compania  = codcia
		  AND r20_localidad = codloc
		ORDER BY r20_cod_tran, r20_num_tran, r20_bodega, r20_item,
			r20_orden
LET i = 0
FOREACH q_r20 INTO r_r20.*
	DISPLAY '  Restaurando registro: ', r_r20.r20_cod_tran, '-',
		r_r20.r20_num_tran USING "<<<<<<<<&", ' Item: ',
		r_r20.r20_item CLIPPED
	UPDATE rept020
		SET r20_costo      = r_r20.r20_costo,
		    r20_costant_mb = r_r20.r20_costant_mb,
		    r20_costant_ma = r_r20.r20_costant_ma,
		    r20_costnue_mb = r_r20.r20_costnue_mb,
		    r20_costnue_ma = r_r20.r20_costnue_ma
		WHERE r20_compania  = r_r20.r20_compania
		  AND r20_localidad = r_r20.r20_localidad
		  AND r20_cod_tran  = r_r20.r20_cod_tran
		  AND r20_num_tran  = r_r20.r20_num_tran
		  AND r20_bodega    = r_r20.r20_bodega
		  AND r20_item      = r_r20.r20_item
		  AND r20_orden     = r_r20.r20_orden
	IF STATUS < 0 THEN
		DISPLAY '  Ha ocurrido un error al actualizar el registro',
			' en rept020.'
		DISPLAY ' '
		RETURN 0
	END IF
	IF STATUS = NOTFOUND THEN
		DISPLAY '  No se ha podido encontrar el registro en rept020.'
		DISPLAY ' '
		RETURN 0
	END IF
	LET i = i + 1
END FOREACH
DISPLAY 'Se restauraron un total de ', i USING "<<<<<<&", ' reg. en tabla',
	' rept020. OK'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos
	FROM rept010_res
	WHERE r10_compania = codcia
IF cuantos = 0 THEN
	DISPLAY 'No se puede restaurar tabla rept010. ',
		'No tiene datos la tabla rept010_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY 'Restaurando tabla rept010. Por favor espere ...'
DECLARE q_r10 CURSOR FOR
	SELECT * FROM rept010_res
		WHERE r10_compania = codcia
		ORDER BY r10_codigo
LET i = 0
FOREACH q_r10 INTO r_r10.*
	DISPLAY '  Restaurando registro: ', r_r10.r10_codigo CLIPPED
	UPDATE rept010
		SET r10_costo_mb   = r_r10.r10_costo_mb,
		    r10_costo_ma   = r_r10.r10_costo_ma,
		    r10_costult_mb = r_r10.r10_costult_mb,
		    r10_costult_ma = r_r10.r10_costult_ma
		WHERE r10_compania = r_r10.r10_compania
		  AND r10_codigo   = r_r10.r10_codigo
	IF STATUS < 0 THEN
		DISPLAY '  Ha ocurrido un error al actualizar el registro',
			' en rept010.'
		DISPLAY ' '
		RETURN 0
	END IF
	IF STATUS = NOTFOUND THEN
		DISPLAY '  No se ha podido encontrar el registro en rept010.'
		DISPLAY ' '
		RETURN 0
	END IF
	LET i = i + 1
END FOREACH
DISPLAY 'Se restauraron un total de ', i USING "<<<<<<&", ' reg. en tabla',
	' rept010. OK'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos
	FROM ctbt013_res
	WHERE b13_compania = codcia
IF cuantos = 0 THEN
	DISPLAY 'No se puede restaurar tabla ctbt013. ',
		'No tiene datos la tabla ctbt013_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY 'Restaurando tabla ctbt013. Por favor espere ...'
DECLARE q_b13 CURSOR FOR
	SELECT * FROM ctbt013_res
		WHERE b13_compania = codcia
		ORDER BY b13_tipo_comp, b13_num_comp, b13_cuenta
LET i = 0
FOREACH q_b13 INTO r_b13.*
	DISPLAY '  Restaurando registro: ', r_b13.b13_tipo_comp, '-',
		r_b13.b13_num_comp CLIPPED, ' cuenta: ',r_b13.b13_cuenta CLIPPED
	UPDATE ctbt013
		SET b13_valor_base = r_b13.b13_valor_base
		WHERE b13_compania  = r_b13.b13_compania
		  AND b13_tipo_comp = r_b13.b13_tipo_comp
		  AND b13_num_comp  = r_b13.b13_num_comp
		  AND b13_secuencia = r_b13.b13_secuencia
		  AND b13_cuenta    = r_b13.b13_cuenta
	IF STATUS < 0 THEN
		DISPLAY '  Ha ocurrido un error al actualizar el registro',
			' en ctbt013.'
		DISPLAY ' '
		RETURN 0
	END IF
	IF STATUS = NOTFOUND THEN
		DISPLAY '  No se ha podido encontrar el registro en ctbt013.'
		DISPLAY ' '
		RETURN 0
	END IF
	LET i = i + 1
END FOREACH
DISPLAY 'Se restauraron un total de ', i USING "<<<<<<&", ' reg. en tabla',
	' ctbt013. OK'
DISPLAY ' '
RETURN 1

END FUNCTION

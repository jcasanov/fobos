DATABASE aceros



DEFINE r_vend		ARRAY[6] OF RECORD
				vend_viejo	LIKE rept001.r01_codigo,
				vend_nuevo	LIKE rept001.r01_codigo
			END RECORD
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base		CHAR(20)
DEFINE maximo		SMALLINT



MAIN

	IF num_args() <> 2 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE y LOCALIDAD. '
		EXIT PROGRAM
	END IF
	LET base   = arg_val(1)
	LET codcia = 1
	LET codloc = arg_val(2)
	LET maximo = 6
	CALL activar_base()
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



FUNCTION ejecuta_proceso()
DEFINE i, hecho		SMALLINT
DEFINE cuantos		INTEGER

LET r_vend[1].vend_viejo = 50
LET r_vend[1].vend_nuevo = 10
LET r_vend[2].vend_viejo = 53
LET r_vend[2].vend_nuevo = 33
LET r_vend[3].vend_viejo = 52
LET r_vend[3].vend_nuevo = 34
LET r_vend[4].vend_viejo = 54
LET r_vend[4].vend_nuevo = 17
LET r_vend[5].vend_viejo = 51
LET r_vend[5].vend_nuevo = 21
LET r_vend[6].vend_viejo = 57
LET r_vend[6].vend_nuevo = 58
BEGIN WORK
FOR i = 1 TO maximo
	SELECT COUNT(*) INTO cuantos FROM rept019
		WHERE r19_vendedor = r_vend[i].vend_viejo
	DISPLAY 'Actualizando Vendedor: ', r_vend[i].vend_viejo USING '&&',
		' ', cuantos USING "###&&", ' REG. con el Vendedor: ',
		r_vend[i].vend_nuevo USING '&&', ' en la rept019.'
	UPDATE rept019 SET r19_vendedor = r_vend[i].vend_nuevo
		WHERE r19_vendedor = r_vend[i].vend_viejo
	SELECT COUNT(*) INTO cuantos FROM rept019
		WHERE r19_vendedor = r_vend[i].vend_nuevo
	DISPLAY 'Se actualizaron ', cuantos, ' registros en la rept019.'
	DISPLAY ' '

	SELECT COUNT(*) INTO cuantos FROM rept021
		WHERE r21_vendedor = r_vend[i].vend_viejo
	DISPLAY 'Actualizando Vendedor: ', r_vend[i].vend_viejo USING '&&',
		' ', cuantos USING "###&&", ' REG. con el Vendedor: ',
		r_vend[i].vend_nuevo USING '&&', ' en la rept021.'
	UPDATE rept021 SET r21_vendedor = r_vend[i].vend_nuevo
		WHERE r21_vendedor = r_vend[i].vend_viejo
	SELECT COUNT(*) INTO cuantos FROM rept021
		WHERE r21_vendedor = r_vend[i].vend_nuevo
	DISPLAY 'Se actualizaron ', cuantos, ' registros en la rept021.'
	DISPLAY ' '

	SELECT COUNT(*) INTO cuantos FROM rept023
		WHERE r23_vendedor = r_vend[i].vend_viejo
	DISPLAY 'Actualizando Vendedor: ', r_vend[i].vend_viejo USING '&&',
		' ', cuantos USING "###&&", ' REG. con el Vendedor: ',
		r_vend[i].vend_nuevo USING '&&', ' en la rept023.'
	UPDATE rept023 SET r23_vendedor = r_vend[i].vend_nuevo
		WHERE r23_vendedor = r_vend[i].vend_viejo
	SELECT COUNT(*) INTO cuantos FROM rept023
		WHERE r23_vendedor = r_vend[i].vend_nuevo
	DISPLAY 'Se actualizaron ', cuantos, ' registros en la rept023.'
	DISPLAY ' '

	SELECT COUNT(*) INTO cuantos FROM rept091
		WHERE r91_vendedor = r_vend[i].vend_viejo
	DISPLAY 'Actualizando Vendedor: ', r_vend[i].vend_viejo USING '&&',
		' ', cuantos USING "###&&", ' REG. con el Vendedor: ',
		r_vend[i].vend_nuevo USING '&&', ' en la rept091.'
	UPDATE rept091 SET r91_vendedor = r_vend[i].vend_nuevo
		WHERE r91_vendedor = r_vend[i].vend_viejo
	SELECT COUNT(*) INTO cuantos FROM rept091
		WHERE r91_vendedor = r_vend[i].vend_nuevo
	DISPLAY 'Se actualizaron ', cuantos, ' registros en la rept091.'
	DISPLAY ' '

	DISPLAY 'Procesando la tabla rept060 ... por favor espere ...'
	CALL recalcular_rept060(i) RETURNING hecho
	IF NOT hecho THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
END FOR
COMMIT WORK

END FUNCTION



FUNCTION recalcular_rept060(i)
DEFINE i, j, l 		SMALLINT
DEFINE r_r60		RECORD LIKE rept060.*
DEFINE r_r60_n		RECORD LIKE rept060.*

SET LOCK MODE TO WAIT 10
DECLARE q_r60 CURSOR FOR
	SELECT * FROM rept060
		WHERE r60_compania = codcia
		  AND r60_vendedor = r_vend[i].vend_viejo
		ORDER BY r60_fecha ASC
LET j = 0
LET l = 0
FOREACH q_r60 INTO r_r60.*
	INITIALIZE r_r60_n.* TO NULL
	SELECT * INTO r_r60_n.* FROM rept060
		WHERE r60_compania = r_r60.r60_compania
		  AND r60_fecha    = r_r60.r60_fecha
		  AND r60_bodega   = r_r60.r60_bodega
		  AND r60_vendedor = r_vend[i].vend_nuevo
		  AND r60_moneda   = r_r60.r60_moneda
		  AND r60_linea    = r_r60.r60_linea
		  AND r60_rotacion = r_r60.r60_rotacion 
	IF r_r60_n.r60_compania IS NOT NULL THEN
		UPDATE rept060 SET r60_precio = r60_precio + r_r60.r60_precio,
				   r60_costo  = r60_costo  + r_r60.r60_costo
			WHERE r60_compania = r_r60_n.r60_compania
			  AND r60_fecha    = r_r60_n.r60_fecha
			  AND r60_bodega   = r_r60_n.r60_bodega
			  AND r60_vendedor = r_r60_n.r60_vendedor
			  AND r60_moneda   = r_r60_n.r60_moneda
			  AND r60_linea    = r_r60_n.r60_linea
			  AND r60_rotacion = r_r60_n.r60_rotacion 
		IF STATUS < 0 THEN
			DISPLAY 'Debido a un bloqueo no se pudo actualizar ',
				'estadísticas de ventas, para el vendedor ',
				r_r60_n.r60_vendedor USING "##&&",
				'. ejecute el proceso de nuevo.'
			RETURN 0
		END IF
		DELETE FROM rept060
			WHERE r60_compania = r_r60.r60_compania
			  AND r60_fecha    = r_r60.r60_fecha
			  AND r60_bodega   = r_r60.r60_bodega
			  AND r60_vendedor = r_r60.r60_vendedor
			  AND r60_moneda   = r_r60.r60_moneda
			  AND r60_linea    = r_r60.r60_linea
			  AND r60_rotacion = r_r60.r60_rotacion 
		LET j = j + 1
		CONTINUE FOREACH
	END IF
	UPDATE rept060 SET r60_vendedor = r_vend[i].vend_nuevo
		WHERE r60_compania = r_r60.r60_compania
		  AND r60_fecha    = r_r60.r60_fecha
		  AND r60_bodega   = r_r60.r60_bodega
		  AND r60_vendedor = r_r60.r60_vendedor
		  AND r60_moneda   = r_r60.r60_moneda
		  AND r60_linea    = r_r60.r60_linea
		  AND r60_rotacion = r_r60.r60_rotacion 
	IF STATUS < 0 THEN
		DISPLAY 'Debido a un bloqueo no se pudo actualizar ',
			'estadísticas de ventas, para el vendedor ',
			r_r60.r60_vendedor USING "##&&",
			'. ejecute el proceso de nuevo.'
		RETURN 0
	END IF
	LET l = l + 1
END FOREACH
DISPLAY 'Se acumularon ', j USING "###&&", ' reg. para vendedor ',
	r_vend[i].vend_nuevo USING "###&&", ' OK'
DISPLAY 'Se cambiaron ', l USING "###&&", ' reg. del vendedor ',
	r_vend[i].vend_viejo USING "###&&", ' para vendedor ',
	r_vend[i].vend_nuevo USING "###&&", ' OK'
DISPLAY ' '
RETURN 1

END FUNCTION

DATABASE aceros


DEFINE base1, base2	CHAR(20)
DEFINE usr1, usr2	LIKE gent005.g05_usuario
DEFINE codcia		LIKE gent001.g01_compania



MAIN

	IF num_args() <> 3 AND num_args() <> 4 THEN
		DISPLAY 'Número de parametros incorrectos.'
		DISPLAY 'Base_donde_crea_usr Base_origen Usuario1 o Usuario2.'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	LET base1  = arg_val(1)
	LET base2  = arg_val(2)
	LET usr1   = arg_val(3)
	IF num_args() = 4 THEN
		LET usr2  = arg_val(4)
	END IF
	CALL validar_paramentros()
	IF num_args() <> 4 THEN
		CALL crear_asigna_permisos_usr()
	ELSE
		CALL asigna_permisos_usr()
	END IF

END MAIN



FUNCTION activar_base(basedatos)
DEFINE basedatos	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE basedatos
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', basedatos
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051
	WHERE g51_basedatos = basedatos
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', basedatos
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_paramentros()

CALL activar_base(base2)
CALL validar_usr(usr1, base2)
IF num_args() = 4 THEN
	CALL validar_usr(usr2, base2)
END IF

END FUNCTION



FUNCTION validar_usr(usr, base)
DEFINE usr		LIKE gent005.g05_usuario
DEFINE base		CHAR(20)
DEFINE r_g05		RECORD LIKE gent005.*

INITIALIZE r_g05.* TO NULL
SELECT * INTO r_g05.* FROM gent005 WHERE g05_usuario = usr
IF r_g05.g05_usuario is NULL THEN
	DISPLAY 'El Usuario: ', usr, ' no existe en la base de datos ', base,'.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION crear_asigna_permisos_usr()
DEFINE query		CHAR(400)

CALL activar_base(base1)

BEGIN WORK

LET query = 'INSERT INTO gent005 ',
		' SELECT * FROM ', base2 CLIPPED, ':gent005 ',
			' WHERE g05_usuario = "', usr1 CLIPPED, '"'
PREPARE ej_t1 FROM query
EXECUTE ej_t1

LET query = 'INSERT INTO gent052 ',
		' SELECT * FROM ', base2 CLIPPED, ':gent052 ',
			' WHERE g52_usuario = "', usr1 CLIPPED, '"'
PREPARE ej_t2 FROM query
EXECUTE ej_t2

LET query = 'INSERT INTO gent053 ',
		' SELECT * FROM ', base2 CLIPPED, ':gent053 ',
			' WHERE g53_usuario = "', usr1 CLIPPED, '"'
PREPARE ej_t3 FROM query
EXECUTE ej_t3

LET query = 'INSERT INTO gent055 ',
		' SELECT g55_user, g55_compania, g55_modulo, g55_proceso, ',
				'"FOBOS", CURRENT ',
			' FROM ', base2 CLIPPED, ':gent055 ',
			' WHERE g55_user     = "', usr1 CLIPPED, '"',
		  	'   AND g55_compania = ', codcia,
			'   AND g55_proceso in ',
				'(SELECT g54_proceso FROM ', base1 CLIPPED,
						':gent054 ',
					' WHERE g54_estado <> "B")'
PREPARE ej_t4 FROM query
EXECUTE ej_t4

LET query = 'INSERT INTO gent007 ',
		' SELECT g07_user, g07_impresora, g07_default, "FOBOS", ',
				'CURRENT ',
			' FROM ', base2 CLIPPED, ':gent007 ',
			' WHERE g07_user      = "', usr1 CLIPPED, '"',
			'   AND g07_impresora in ',
				'(SELECT g06_impresora FROM ', base1 CLIPPED,
					':gent006)'
PREPARE ej_t5 FROM query
EXECUTE ej_t5

COMMIT WORK

DISPLAY 'Usuario: ', usr1, ' creado y actualizado en ', base1 CLIPPED,
	' con los mismos permisos de la base ', base2 CLIPPED, ' OK.'

END FUNCTION



FUNCTION asigna_permisos_usr()
DEFINE query		CHAR(400)

CALL activar_base(base1)

BEGIN WORK

DELETE FROM gent055 WHERE g55_user    = usr1
DELETE FROM gent053 WHERE g53_usuario = usr1
DELETE FROM gent052 WHERE g52_usuario = usr1
DELETE FROM gent007 WHERE g07_user    = usr1

LET query = 'SELECT * FROM ', base2 CLIPPED, ':gent052 ',
		' WHERE g52_usuario = "', usr2 CLIPPED, '"',
		' INTO TEMP t1'
PREPARE ej_t1_c FROM query
EXECUTE ej_t1_c

LET query = 'SELECT * FROM ', base2 CLIPPED, ':gent053 ',
		' WHERE g53_usuario = "', usr2 CLIPPED, '"',
		' INTO TEMP t2'
PREPARE ej_t2_c FROM query
EXECUTE ej_t2_c

LET query = 'SELECT * FROM ', base2 CLIPPED, ':gent055 ',
		' WHERE g55_user     = "', usr2 CLIPPED, '"',
		'   AND g55_compania = ', codcia,
		'   AND g55_proceso in ',
			'(SELECT g54_proceso FROM ', base1 CLIPPED, ':gent054 ',
				' WHERE g54_estado <> "B")',
		' INTO TEMP t3'
PREPARE ej_t3_c FROM query
EXECUTE ej_t3_c

LET query = 'SELECT * FROM ', base2 CLIPPED, ':gent007 ',
		' WHERE g07_user     = "', usr2 CLIPPED, '"',
		'   AND g07_impresora in ',
			'(SELECT g06_impresora FROM ', base1 CLIPPED,
				':gent006)',
		' INTO TEMP t4'
PREPARE ej_t4_c FROM query
EXECUTE ej_t4_c

UPDATE t1 SET g52_usuario = usr1 WHERE 1 = 1
UPDATE t2 SET g53_usuario = usr1 WHERE 1 = 1
UPDATE t3 SET g55_user    = usr1 WHERE 1 = 1
UPDATE t4 SET g07_user    = usr1 WHERE 1 = 1

INSERT INTO gent052 SELECT * FROM t1
INSERT INTO gent053 SELECT * FROM t2
INSERT INTO gent055 SELECT * FROM t3
INSERT INTO gent007 SELECT * FROM t4

COMMIT WORK

DISPLAY 'Usuario: ', usr1, ' actualizado con los mismos permisos del Usuario: ',
	usr2, ' OK.'

DROP TABLE t1
DROP TABLE t2
DROP TABLE t3
DROP TABLE t4

END FUNCTION

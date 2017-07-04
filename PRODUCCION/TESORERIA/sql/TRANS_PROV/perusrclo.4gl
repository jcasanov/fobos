DATABASE aceros


DEFINE base1, base2     CHAR(20)
DEFINE usr1, usr2       LIKE gent005.g05_usuario
DEFINE codcia1          LIKE gent001.g01_compania
DEFINE codcia2          LIKE gent001.g01_compania



MAIN

        IF num_args() <> 5 AND num_args() <> 6 THEN
                DISPLAY 'Número de parametros incorrectos.'
                DISPLAY 'Base_donde_crea_usr@SERV_BD cia_crea Base_origen@SERV_BD cia_ori Usuario1_a_asignar o Usuario2_origen.'
                EXIT PROGRAM
        END IF
        LET base1   = arg_val(1)
        LET codcia1 = arg_val(2)
        LET base2   = arg_val(3)
        LET codcia2 = arg_val(4)
        LET usr1    = arg_val(5)
        IF num_args() = 6 THEN
                LET usr2 = arg_val(6)
        END IF
        CALL validar_paramentros()
        IF num_args() <> 6 THEN
                CALL crear_asigna_permisos_usr()
        ELSE
                CALL asigna_permisos_usr()
        END IF

END MAIN



FUNCTION activar_base(basedatos)
DEFINE basedatos        CHAR(20)
DEFINE b                CHAR(20)
DEFINE i                SMALLINT
DEFINE r_g51            RECORD LIKE gent051.*

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE basedatos
IF STATUS < 0 THEN
        DISPLAY 'No se pudo abrir base de datos: ', basedatos
        EXIT PROGRAM
END IF
WHENEVER ERROR STOP
LET b = ' '
FOR i = 1 TO LENGTH(basedatos)
        IF basedatos[i, i] = '@' THEN
                EXIT FOR
        END IF
        LET b = b CLIPPED, basedatos[i, i]
END FOR
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051
        WHERE g51_basedatos = b
IF r_g51.g51_basedatos IS NULL THEN
        DISPLAY 'No existe base de datos: ', b
--      EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_paramentros()

CALL activar_base(base2)
CALL validar_usr(usr1, base2)
IF num_args() = 6 THEN
        CALL validar_usr(usr2, base2)
END IF

END FUNCTION



FUNCTION validar_usr(usr, base)
DEFINE usr              LIKE gent005.g05_usuario
DEFINE base             CHAR(20)
DEFINE r_g05            RECORD LIKE gent005.*

INITIALIZE r_g05.* TO NULL
SELECT * INTO r_g05.* FROM gent005 WHERE g05_usuario = usr
IF r_g05.g05_usuario is NULL THEN
        DISPLAY 'El Usuario: ', usr, ' no existe en la base de datos ', base,'.'
        EXIT PROGRAM
END IF

END FUNCTION



FUNCTION crear_asigna_permisos_usr()
DEFINE query            CHAR(400)

CALL activar_base(base1)

BEGIN WORK

LET query = 'INSERT INTO gent005 ',
                ' SELECT g05_usuario, g05_nombres, ',
                                'CASE WHEN g05_grupo = "CC" AND "',
                                        base2[1, 8] CLIPPED, '" = "acero_qm" ',
                                        'THEN "CB" ',
                                        'ELSE g05_grupo ',
                                'END, ',
                                'g05_estado, g05_tipo, g05_clave, g05_menu',
                        ' FROM ', base2 CLIPPED, ':gent005 ',
                        ' WHERE g05_usuario = "', usr1 CLIPPED, '"'
PREPARE ej_t1 FROM query
EXECUTE ej_t1

LET query = 'INSERT INTO gent052 ',
                ' SELECT * FROM ', base2 CLIPPED, ':gent052 ',
                        ' WHERE g52_usuario = "', usr1 CLIPPED, '"'
PREPARE ej_t2 FROM query
EXECUTE ej_t2

LET query = 'INSERT INTO gent053 ',
                ' SELECT g53_modulo, g53_usuario, ', codcia1,
                        ' FROM ', base2 CLIPPED, ':gent053 ',
                        ' WHERE g53_usuario = "', usr1 CLIPPED, '"'
PREPARE ej_t3 FROM query
EXECUTE ej_t3

LET query = 'INSERT INTO gent055 ',
                ' SELECT g55_user, ', codcia1, ', g55_modulo, g55_proceso, ',
                                '"FOBOS", CURRENT ',
                        ' FROM ', base2 CLIPPED, ':gent055 ',
                        ' WHERE g55_user     = "', usr1 CLIPPED, '"',
                        '   AND g55_compania = ', codcia2,
                        '   AND g55_proceso IN ',
                                '(SELECT g54_proceso FROM ', base1 CLIPPED,
                                                ':gent054 ',
                                        ' WHERE g54_estado <> "B")'
PREPARE ej_t4 FROM query
EXECUTE ej_t4

LET query = 'INSERT INTO gent057 ',
                ' SELECT g57_user, ', codcia1, ', g57_modulo, g57_proceso, ',
                                '"FOBOS", CURRENT ',
                        ' FROM ', base2 CLIPPED, ':gent057 ',
                        ' WHERE g57_user     = "', usr1 CLIPPED, '"',
                        '   AND g57_compania = ', codcia2,
                        '   AND g57_proceso IN ',
                                '(SELECT g54_proceso FROM ', base1 CLIPPED,
                                                ':gent054 ',
                                        ' WHERE g54_estado <> "B")'
PREPARE ej_t5 FROM query
EXECUTE ej_t5

LET query = 'INSERT INTO gent007 ',
                ' SELECT g07_user, g07_impresora, g07_default, "FOBOS", ',
                                'CURRENT ',
                        ' FROM ', base2 CLIPPED, ':gent007 ',
                        ' WHERE g07_user      = "', usr1 CLIPPED, '"',
                        '   AND g07_impresora IN ',
                                '(SELECT g06_impresora FROM ', base1 CLIPPED,
                                        ':gent006)'
PREPARE ej_t6 FROM query
EXECUTE ej_t6

COMMIT WORK

DISPLAY 'Usuario: ', usr1, ' creado y actualizado en ', base1 CLIPPED,
        ' con los mismos permisos de la base ', base2 CLIPPED, ' OK.'

END FUNCTION



FUNCTION asigna_permisos_usr()
DEFINE query            CHAR(400)

CALL activar_base(base1)

BEGIN WORK

DELETE FROM gent057 WHERE g57_user    = usr1
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
                '   AND g55_compania = ', codcia2,
                '   AND g55_proceso IN ',
                        '(SELECT g54_proceso FROM ', base1 CLIPPED, ':gent054 ',
                                ' WHERE g54_estado <> "B")',
                ' INTO TEMP t3'
PREPARE ej_t3_c FROM query
EXECUTE ej_t3_c

LET query = 'SELECT * FROM ', base2 CLIPPED, ':gent057 ',
                ' WHERE g57_user     = "', usr2 CLIPPED, '"',
                '   AND g57_compania = ', codcia2,
                '   AND g57_proceso IN ',
                        '(SELECT g54_proceso FROM ', base1 CLIPPED, ':gent054 ',
                                ' WHERE g54_estado <> "B")',
                ' INTO TEMP t4'
PREPARE ej_t4_c FROM query
EXECUTE ej_t4_c

LET query = 'SELECT * FROM ', base2 CLIPPED, ':gent007 ',
                ' WHERE g07_user     = "', usr2 CLIPPED, '"',
                '   AND g07_impresora IN ',
                        '(SELECT g06_impresora FROM ', base1 CLIPPED,
                                ':gent006)',
                ' INTO TEMP t5'
PREPARE ej_t5_c FROM query
EXECUTE ej_t5_c

UPDATE t1 SET g52_usuario = usr1 WHERE 1 = 1
UPDATE t2 SET g53_usuario = usr1 WHERE 1 = 1
UPDATE t3 SET g55_user    = usr1 WHERE 1 = 1
UPDATE t4 SET g57_user    = usr1 WHERE 1 = 1
UPDATE t5 SET g07_user    = usr1 WHERE 1 = 1

INSERT INTO gent052 SELECT * FROM t1
INSERT INTO gent053 SELECT * FROM t2
INSERT INTO gent055 SELECT * FROM t3
INSERT INTO gent057 SELECT * FROM t4
INSERT INTO gent007 SELECT * FROM t5

COMMIT WORK

DISPLAY 'Usuario: ', usr1, ' actualizado con los mismos permisos del Usuario: ',
        usr2, ' OK.'

DROP TABLE t1
DROP TABLE t2
DROP TABLE t3
DROP TABLE t4
DROP TABLE t5

END FUNCTION


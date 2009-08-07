                                                                                
-------------------------------------------------------------------------------
-- Titulo               : Genp120.4gl -- Mantenimiento de Paises
-- Elaboración          : 20-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  genp120 base GE 
-- Ultima Correción     : 29-ago-2001
-- Motivo Corrección    : standares
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_pais  RECORD LIKE gent030.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp120'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN

                                                                                
FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_pais AT 3,2 WITH 14 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_pais FROM '../forms/genf120_1'
DISPLAY FORM f_pais
INITIALIZE rm_pais.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
        COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                IF vm_num_rows > 0 THEN
                    	CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
                END IF
        COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
        COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
                IF vm_row_current < vm_num_rows THEN
                        LET vm_row_current = vm_row_current + 1
                END IF
                CALL lee_muestra_registro(vm_r_rows[vm_row_current])
                CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
                IF vm_row_current > 1 THEN
                        LET vm_row_current = vm_row_current - 1
                END IF
                CALL lee_muestra_registro(vm_r_rows[vm_row_current])
                CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('S') 'Salir' 'Salir del programa. '
                EXIT MENU
END MENU

END FUNCTION


FUNCTION control_consulta()
DEFINE codigo		LIKE gent030.g30_pais
DEFINE nombre		LIKE gent030.g30_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE codigo TO NULL
CONSTRUCT BY NAME expr_sql ON g30_pais, g30_nombre, g30_siglas, g30_usuario,                                  g30_fecing
	ON KEY(F2)
		IF INFIELD(g30_pais) THEN
			CALL fl_ayuda_pais()RETURNING codigo, nombre
			IF codigo IS NOT NULL THEN
			   LET rm_pais.g30_pais = codigo
			   LET rm_pais.g30_nombre = nombre
			   DISPLAY BY NAME rm_pais.g30_pais, rm_pais.g30_nombre
				
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM gent030 WHERE ', expr_sql CLIPPED, 
		' ORDER BY 2'
PREPARE cons FROM query
DECLARE q_pais CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_pais INTO rm_pais.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_pais.* TO NULL
LET rm_pais.g30_fecing = CURRENT
LET rm_pais.g30_usuario = vg_usuario
LET rm_pais.g30_pais = 0
DISPLAY BY NAME rm_pais.g30_fecing, rm_pais.g30_usuario
CALL lee_datos('I')
IF NOT int_flag THEN
	INSERT INTO gent030 VALUES (rm_pais.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



                                                                                
FUNCTION control_modificacion()
DEFINE    flag		   CHAR(1)

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM gent030 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_pais.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF

CALL lee_datos('M')
IF NOT int_flag THEN
    	UPDATE gent030 SET * = rm_pais.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE  resp    	CHAR(6)
DEFINE 	flag 	 	CHAR(1)
DEFINE 	serial 	 	LIKE gent030.g30_pais
DEFINE 	nom_pais 	LIKE gent030.g30_nombre
DEFINE 	siglas	 	LIKE gent030.g30_siglas

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_pais.g30_nombre, rm_pais.g30_siglas WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_pais.g30_nombre, rm_pais.g30_siglas)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                                LET int_flag = 1
                                IF flag = 'I' THEN
					 CLEAR FORM
				END IF
                                RETURN
                        END IF
                ELSE
                        IF flag = 'I' THEN
				CLEAR FORM
			END IF
		        RETURN
                END IF
	AFTER FIELD g30_nombre
		IF rm_pais.g30_nombre IS NOT NULL THEN
			SELECT g30_pais INTO serial
			FROM   gent030
			WHERE  g30_nombre = rm_pais.g30_nombre 
			IF status <> NOTFOUND THEN
			   IF rm_pais.g30_pais <> serial THEN
			      CALL fgl_winmessage(vg_producto,
                                              'Ya existe el país','exclamation')
				NEXT FIELD g30_nombre
			   END IF
			END IF
		END IF
        AFTER FIELD g30_siglas
                IF rm_pais.g30_siglas IS NOT NULL THEN
			SELECT g30_pais, g30_nombre INTO serial, nom_pais
                        FROM   gent030
                        WHERE  g30_siglas = rm_pais.g30_siglas
                        IF status <> NOTFOUND THEN
                           IF rm_pais.g30_pais <> serial THEN
                              CALL fgl_winmessage(vg_producto,'Las siglas ya han sido asignadas a '|| nom_pais,'exclamation')
		              NEXT FIELD g30_siglas
                           END IF
                        END IF
                END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_pais.* FROM gent030 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_pais.*

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
     EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION


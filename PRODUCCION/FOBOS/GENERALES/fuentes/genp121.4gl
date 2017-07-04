--------------------------------------------------------------------------------
-- Titulo           : Genp121.4gl -- Mantenimiento de Ciudades
-- Elaboración      : 20-ago-2001
-- Autor            : GVA/NPC
-- Formato Ejecucion: fglrun genp121 base modulo
-- Ultima Correción : 30-ago-2001
-- Motivo Corrección: Standares/Nuevo diseño
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_g31		RECORD LIKE gent031.*
DEFINE vm_rows		ARRAY[1000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp121.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_proceso = 'genp121'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 15
LET num_cols    = 80
IF vg_gui = 0 THEN        
	LET lin_menu = 1
	LET row_ini  = 2
	LET num_rows = 20
	LET num_cols = 78
END IF                  
OPEN WINDOW w_genp121_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_genf121_1 FROM '../forms/genf121_1'
ELSE
	OPEN FORM f_genf121_1 FROM '../forms/genf121_1c'
END IF
DISPLAY FORM f_genf121_1
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
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
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
		CALL control_modificacion()
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
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa.  '
		EXIT MENU
END MENU
CLOSE WINDOW w_genp121_1
EXIT PROGRAM

END FUNCTION



FUNCTION muestra_contadores(num_reg, max_reg)
DEFINE num_reg, max_reg	SMALLINT

DISPLAY BY NAME num_reg, max_reg

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER

CLEAR FORM
INITIALIZE rm_g31.* TO NULL
LET rm_g31.g31_ciudad  = 0
LET rm_g31.g31_fecing  = CURRENT
LET rm_g31.g31_usuario = vg_usuario
DISPLAY BY NAME rm_g31.g31_fecing, rm_g31.g31_usuario
CALL lee_datos('I')
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	INSERT INTO gent031 VALUES (rm_g31.*)
	IF STATUS = 0 THEN
		LET num_aux = SQLCA.SQLERRD[6]
		WHENEVER ERROR STOP
	ELSE
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se ha podido crear este código de ciudad. Por favor LLAME AL ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		RETURN
	END IF
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows  = 1
ELSE
	LET vm_num_rows  = vm_num_rows + 1
END IF
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = num_aux
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION


                                                                                
FUNCTION control_modificacion()

CALL lee_muestra_registro(vm_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM gent031
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE 
OPEN q_up
FETCH q_up INTO rm_g31.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de esta ciudad. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_salir()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE gent031
	SET * = rm_g31.*
	WHERE CURRENT OF q_up
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo MODIFICAR el registro de esta ciudad. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1000)
DEFINE query		CHAR(2000)
DEFINE r_g25		RECORD LIKE gent025.*
DEFINE r_g30		RECORD LIKE gent030.*
DEFINE r_g31		RECORD LIKE gent031.*

CLEAR FORM
INITIALIZE rm_g31.*, r_g25.*, r_g30.*, r_g31.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON g31_ciudad, g31_nombre, g31_pais, g31_divi_poli,
	g31_siglas, g31_usuario, g31_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(g31_ciudad) THEN
			CALL fl_ayuda_ciudad('00', 0)
				RETURNING r_g31.g31_ciudad, r_g31.g31_nombre
			IF r_g31.g31_ciudad IS NOT NULL THEN
				DISPLAY BY NAME r_g31.g31_ciudad,
						r_g31.g31_nombre
			END IF
		END IF
		IF INFIELD(g31_pais) THEN
			CALL fl_ayuda_pais()
				RETURNING r_g30.g30_pais, r_g30.g30_nombre
			IF r_g30.g30_pais IS NOT NULL THEN
				DISPLAY r_g30.g30_pais TO g31_pais
				DISPLAY BY NAME r_g30.g30_nombre
			END IF
		END IF
		IF INFIELD(g31_divi_poli) AND r_g30.g30_pais IS NOT NULL THEN
			CALL fl_ayuda_division_politica(r_g30.g30_pais)
				RETURNING r_g25.g25_divi_poli, r_g25.g25_nombre
			IF r_g25.g25_divi_poli IS NOT NULL THEN
				DISPLAY r_g25.g25_divi_poli TO g31_divi_poli
				DISPLAY BY NAME r_g25.g25_nombre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD g31_ciudad
		LET rm_g31.g31_ciudad = GET_FLDBUF(g31_ciudad)
		IF rm_g31.g31_ciudad IS NOT NULL THEN
			CALL fl_lee_ciudad(rm_g31.g31_ciudad)
				RETURNING r_g31.*
			IF r_g31.g31_ciudad IS NULL THEN
				CALL fl_mostrar_mensaje('Esta ciudad no existe en la compañía.', 'exclamation')
				NEXT FIELD g31_ciudad
			END IF
			LET rm_g31.g31_ciudad = r_g31.g31_ciudad
		ELSE
			INITIALIZE r_g31.*, rm_g31.g31_ciudad TO NULL
		END IF
		DISPLAY BY NAME rm_g31.g31_ciudad, r_g31.g31_nombre
	AFTER FIELD g31_pais
		LET rm_g31.g31_pais = GET_FLDBUF(g31_pais)
		IF rm_g31.g31_pais IS NOT NULL THEN
			CALL fl_lee_pais(rm_g31.g31_pais) RETURNING r_g30.*
			IF r_g30.g30_pais IS NULL THEN
				CALL fl_mostrar_mensaje('Este pais no existe en la compañía.', 'exclamation')
				NEXT FIELD g31_pais
			END IF
			LET rm_g31.g31_pais = r_g30.g30_pais
			CALL fl_lee_division_politica(rm_g31.g31_pais,
							rm_g31.g31_divi_poli)
				RETURNING r_g25.*
		ELSE
			INITIALIZE r_g30.*, r_g25.*, rm_g31.g31_divi_poli
				TO NULL
		END IF
		DISPLAY BY NAME r_g30.g30_nombre, rm_g31.g31_divi_poli,
				r_g25.g25_nombre
	AFTER FIELD g31_divi_poli
		LET rm_g31.g31_pais = GET_FLDBUF(g31_pais)
		IF rm_g31.g31_pais IS NULL THEN
			INITIALIZE r_g25.*, rm_g31.g31_divi_poli TO NULL
			DISPLAY BY NAME rm_g31.g31_divi_poli, r_g25.g25_nombre
			CONTINUE CONSTRUCT
		END IF
		LET rm_g31.g31_divi_poli = GET_FLDBUF(g31_divi_poli)
		IF rm_g31.g31_divi_poli IS NOT NULL THEN
			CALL fl_lee_division_politica(rm_g31.g31_pais,
							rm_g31.g31_divi_poli)
				RETURNING r_g25.*
			IF r_g25.g25_divi_poli IS NULL THEN
				CALL fl_mostrar_mensaje('Esta división política o provincia no existe en la compañía.', 'exclamation')
				NEXT FIELD g31_divi_poli
			END IF
			LET rm_g31.g31_divi_poli = r_g25.g25_divi_poli
		ELSE
			INITIALIZE r_g25.*, rm_g31.g31_divi_poli
				TO NULL
		END IF
		DISPLAY BY NAME rm_g31.g31_divi_poli, r_g25.g25_nombre
END CONSTRUCT
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
LET query = "SELECT *, ROWID ",
		" FROM gent031 ",
		" WHERE ", expr_sql CLIPPED, 
		" ORDER BY g31_pais ASC, g31_nombre ASC"
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_g31.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CLEAR FORM
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag		CHAR(1)
DEFINE r_g25		RECORD LIKE gent025.*
DEFINE r_g30		RECORD LIKE gent030.*
DEFINE nombre		LIKE gent031.g31_nombre
DEFINE siglas		LIKE gent031.g31_siglas
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)

INITIALIZE r_g25.*, r_g30.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_g31.g31_nombre, rm_g31.g31_pais, rm_g31.g31_divi_poli,
	rm_g31.g31_siglas
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_g31.g31_nombre, rm_g31.g31_pais,
				 rm_g31.g31_divi_poli, rm_g31.g31_siglas)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(g31_pais) THEN
			CALL fl_ayuda_pais()
				RETURNING r_g30.g30_pais, r_g30.g30_nombre
			IF r_g30.g30_pais IS NOT NULL THEN
				LET rm_g31.g31_pais = r_g30.g30_pais
				DISPLAY BY NAME rm_g31.g31_pais,
						r_g30.g30_nombre
			END IF
		END IF
		IF INFIELD(g31_divi_poli) AND r_g30.g30_pais IS NOT NULL THEN
			CALL fl_ayuda_division_politica(r_g30.g30_pais)
				RETURNING r_g25.g25_divi_poli, r_g25.g25_nombre
			IF r_g25.g25_divi_poli IS NOT NULL THEN
				LET rm_g31.g31_divi_poli = r_g25.g25_divi_poli
				DISPLAY BY NAME rm_g31.g31_divi_poli,
						r_g25.g25_nombre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD g31_pais
		IF rm_g31.g31_pais IS NOT NULL THEN
			CALL fl_lee_pais(rm_g31.g31_pais) RETURNING r_g30.*
			IF r_g30.g30_pais IS NULL THEN
				CALL fl_mostrar_mensaje('Este pais no existe en la compañía.', 'exclamation')
				NEXT FIELD g31_pais
			END IF
			LET rm_g31.g31_pais = r_g30.g30_pais
			CALL fl_lee_division_politica(rm_g31.g31_pais,
							rm_g31.g31_divi_poli)
				RETURNING r_g25.*
		ELSE
			INITIALIZE r_g30.*, r_g25.*, rm_g31.g31_divi_poli
				TO NULL
		END IF
		DISPLAY BY NAME r_g30.g30_nombre, rm_g31.g31_divi_poli,
				r_g25.g25_nombre
	AFTER FIELD g31_divi_poli
		IF rm_g31.g31_pais IS NULL THEN
			INITIALIZE r_g25.*, rm_g31.g31_divi_poli TO NULL
			DISPLAY BY NAME rm_g31.g31_divi_poli, r_g25.g25_nombre
			CONTINUE INPUT
		END IF
		IF rm_g31.g31_divi_poli IS NOT NULL THEN
			CALL fl_lee_division_politica(rm_g31.g31_pais,
							rm_g31.g31_divi_poli)
				RETURNING r_g25.*
			IF r_g25.g25_divi_poli IS NULL THEN
				CALL fl_mostrar_mensaje('Esta división política o provincia no existe en la compañía.', 'exclamation')
				NEXT FIELD g31_divi_poli
			END IF
			LET rm_g31.g31_divi_poli = r_g25.g25_divi_poli
		ELSE
			INITIALIZE r_g25.*, rm_g31.g31_divi_poli
				TO NULL
		END IF
		DISPLAY BY NAME rm_g31.g31_divi_poli, r_g25.g25_nombre
	AFTER INPUT
		IF rm_g31.g31_divi_poli IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la División Política o Provincia.', 'exclamation')
			NEXT FIELD g31_divi_poli
		END IF
		IF rm_g31.g31_nombre IS NOT NULL THEN
			LET nombre = NULL
			SELECT g31_nombre
				INTO nombre
				FROM gent031
				WHERE g31_ciudad    <> rm_g31.g31_ciudad
				  AND g31_pais       = rm_g31.g31_pais
				  AND g31_divi_poli  = rm_g31.g31_divi_poli
				  AND g31_nombre     = rm_g31.g31_nombre
			IF (nombre IS NOT NULL AND
			   (rm_g31.g31_nombre IS NULL OR
			    nombre = rm_g31.g31_nombre))
			THEN
				CALL fl_mostrar_mensaje('Ya existe este nombre de ciudad en la compañía.', 'exclamation')
				NEXT FIELD g31_nombre
			END IF
		END IF
		IF rm_g31.g31_siglas IS NOT NULL THEN
			LET siglas = NULL
			SELECT g31_siglas, g31_nombre
				INTO siglas, nombre
				FROM gent031
				WHERE g31_ciudad <> rm_g31.g31_ciudad
				  AND g31_siglas = rm_g31.g31_siglas
			IF (siglas IS NOT NULL AND
			   (rm_g31.g31_siglas IS NULL OR
			    siglas = rm_g31.g31_siglas))
			THEN
                   		LET mensaje = "Estas siglas ya han sido ",
						"asignada a la ciudad de ",
						nombre CLIPPED, "."
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				NEXT FIELD g31_siglas
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_salir()

IF vm_num_rows = 0 THEN
	CLEAR FORM
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_g25		RECORD LIKE gent025.*
DEFINE r_g30		RECORD LIKE gent030.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_g31.* FROM gent031 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_g31.g31_ciudad, rm_g31.g31_nombre, rm_g31.g31_pais,
		rm_g31.g31_divi_poli, rm_g31.g31_siglas, rm_g31.g31_usuario,
		rm_g31.g31_fecing
CALL fl_lee_pais(rm_g31.g31_pais) RETURNING r_g30.*
CALL fl_lee_division_politica(rm_g31.g31_pais, rm_g31.g31_divi_poli)
	RETURNING r_g25.*
DISPLAY BY NAME r_g30.g30_nombre, r_g25.g25_nombre
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION

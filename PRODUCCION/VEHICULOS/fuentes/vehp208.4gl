------------------------------------------------------------------------------
-- Titulo           : vehp208.4gl - Mantenimiento de Parámetros para 
--				    Reservaciones
-- Elaboracion      : 19-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp208 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT

--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v32			RECORD LIKE veht032.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp208'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
-- LET vg_codloc   = arg_val(4)
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_v32 AT 3,2 WITH 12 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_v32 FROM '../forms/vehf208_1'
DISPLAY FORM f_v32

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v32.* TO NULL
CALL muestra_contadores()
CALL muestra_etiquetas()

LET vm_max_rows = 1000

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
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
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
INITIALIZE rm_v32.* TO NULL

LET rm_v32.v32_fecing   = CURRENT
LET rm_v32.v32_usuario  = vg_usuario
LET rm_v32.v32_compania = vg_codcia

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

INSERT INTO veht032 VALUES (rm_v32.*)

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL muestra_contadores()
CALL muestra_etiquetas()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht032 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v32.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE veht032 SET * = rm_v32.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE linea		LIKE veht003.v03_linea,
       nom_linea	LIKE veht003.v03_nombre

DEFINE r_v03		RECORD LIKE veht003.*

INITIALIZE linea TO NULL
INITIALIZE nom_linea TO NULL
INITIALIZE r_v03.* TO NULL

LET INT_FLAG = 0
INPUT BY NAME rm_v32.v32_linea, rm_v32.v32_porc_min, 
              rm_v32.v32_usuario, rm_v32.v32_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(v32_linea, v32_porc_min) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(v32_linea) THEN
			CALL fl_ayuda_lineas_veh(vg_codcia)
				RETURNING linea, nom_linea
			IF linea IS NOT NULL THEN
				LET rm_v32.v32_linea = linea
				DISPLAY BY NAME rm_v32.v32_linea
				DISPLAY nom_linea TO n_linea
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD v32_linea
		IF flag = 'M' THEN
			NEXT FIELD v32_porc_min
		END IF
	AFTER  FIELD v32_linea
		IF rm_v32.v32_linea IS NULL THEN
			CLEAR n_linea
		ELSE
			SELECT * FROM veht032 
				WHERE v32_compania = vg_codcia
				  AND v32_linea    = rm_v32.v32_linea
			IF STATUS <> NOTFOUND THEN
				CALL fgl_winmessage(vg_producto,
					            'Ya existe parámetro' ||
						    ' para esta linea',
                                                    'exclamation')
				CLEAR n_linea
				NEXT FIELD v32_linea
			END IF
			CALL fl_lee_linea_veh(vg_codcia, rm_v32.v32_linea)
				RETURNING r_v03.*
			IF r_v03.v03_linea IS NOT NULL THEN 
				IF r_v03.v03_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
							    'Linea está ' ||
                  					    'bloqueada',
							    'exclamation')
					CLEAR n_linea
					NEXT FIELD v32_linea 
				ELSE
					DISPLAY r_v03.v03_nombre TO n_linea
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
						    'Linea no ' ||
                  				    'existe',
						    'exclamation')
				CLEAR n_linea
				NEXT FIELD v32_linea 
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE linea		LIKE veht003.v03_linea,
       nom_linea	LIKE veht003.v03_nombre

DEFINE r_v03		RECORD LIKE veht003.*

CLEAR FORM

INITIALIZE linea TO NULL
INITIALIZE nom_linea TO NULL
INITIALIZE r_v03.* TO NULL
INITIALIZE rm_v32.* TO NULL

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON v32_linea, v32_porc_min, v32_usuario
	ON KEY(F2)
		IF INFIELD(v32_linea) THEN
			CALL fl_ayuda_lineas_veh(vg_codcia)
				RETURNING linea, nom_linea
			IF linea IS NOT NULL THEN
				LET rm_v32.v32_linea = linea
				DISPLAY BY NAME rm_v32.v32_linea
				DISPLAY nom_linea TO n_linea
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER  FIELD v32_linea
		IF rm_v32.v32_linea IS NULL THEN
			CLEAR n_linea
		ELSE
			CALL fl_lee_linea_veh(vg_codcia, rm_v32.v32_linea)
				RETURNING r_v03.*
			IF r_v03.v03_linea IS NOT NULL THEN 
				IF r_v03.v03_estado = 'B' THEN
					CLEAR n_linea
				ELSE
					DISPLAY r_v03.v03_nombre TO n_linea
				END IF
			ELSE
				CLEAR n_linea
			END IF
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht032 WHERE ', expr_sql, 
            ' AND v32_compania = ', vg_codcia, ' ORDER BY 2' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v32.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v32.* FROM veht032 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v32.v32_linea,
                rm_v32.v32_porc_min,
		rm_v32.v32_usuario,
		rm_v32.v32_fecing
CALL muestra_contadores()
CALL muestra_etiquetas()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

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



FUNCTION muestra_etiquetas()

DEFINE r_v03			RECORD LIKE veht003.*

CALL fl_lee_linea_veh(vg_codcia, rm_v32.v32_linea) RETURNING r_v03.*
DISPLAY r_v03.v03_nombre TO n_linea

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION

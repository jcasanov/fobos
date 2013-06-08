------------------------------------------------------------------------------
-- Titulo           : genp110.4gl - Mantenimiento de Componentes de Entidades
--                                  del Sistema
-- Elaboracion      : 24-ago-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun genp110 base modulo
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
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS

DEFINE rm_sub		RECORD LIKE	gent012.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp110'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_sub AT 3,2 WITH 15 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_sub FROM '../forms/genf110_1'
DISPLAY FORM f_sub

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_sub.* TO NULL
CALL muestra_contadores()

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

DEFINE subtipo		LIKE gent012.g12_subtipo

CLEAR FORM
INITIALIZE rm_sub.* TO NULL

LET rm_sub.g12_fecing  = CURRENT
LET rm_sub.g12_usuario = vg_usuario

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

INITIALIZE subtipo TO NULL
SELECT MAX(g12_subtipo) INTO subtipo
	FROM gent012
	WHERE g12_tiporeg = rm_sub.g12_tiporeg

IF subtipo IS NULL THEN
	LET subtipo = 1
ELSE
	LET subtipo = subtipo + 1
END IF
LET rm_sub.g12_subtipo = subtipo
DISPLAY BY NAME rm_sub.g12_subtipo

INSERT INTO gent012 VALUES (rm_sub.*)

LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada

CALL muestra_contadores()
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
	SELECT * FROM gent012 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_sub.*
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
	FREE  q_upd
	RETURN
END IF 

UPDATE gent012 SET * = rm_sub.* WHERE CURRENT OF q_upd
COMMIT WORK
CLOSE q_upd
FREE  q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag		CHAR(6)
DEFINE resp 		CHAR(6)
DEFINE entidad 		LIKE gent012.g12_tiporeg
DEFINE n_entidad	LIKE gent011.g11_nombre
DEFINE componente	LIKE gent012.g12_subtipo

DEFINE r_ent		RECORD LIKE gent011.*

LET INT_FLAG = 0

INPUT BY NAME rm_sub.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_sub.g12_tiporeg, rm_sub.g12_subtipo, 
                                     rm_sub.g12_nombre) THEN
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
		IF INFIELD(g12_tiporeg) THEN
			CALL fl_ayuda_entidad() RETURNING entidad, n_entidad
			IF entidad IS NOT NULL THEN
				LET rm_sub.g12_tiporeg = entidad
				DISPLAY BY NAME rm_sub.g12_tiporeg
				DISPLAY n_entidad TO nom_ent
			END IF
		END IF
	BEFORE FIELD g12_tiporeg
		IF flag = 'M' THEN
			NEXT FIELD g12_nombre
		END IF 
	AFTER FIELD g12_tiporeg
		IF rm_sub.g12_tiporeg IS NULL THEN
			CLEAR nom_ent
		ELSE
			CALL fl_lee_entidad(rm_sub.g12_tiporeg) 
				RETURNING r_ent.*
			IF r_ent.g11_tiporeg IS NULL THEN	
				CALL fgl_winmessage(vg_producto,
                                                    'Entidad no existe',
						    'exclamation')
				CLEAR nom_ent
				NEXT FIELD g12_tiporeg
			ELSE
				DISPLAY r_ent.g11_nombre TO nom_ent
			END IF 
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)
DEFINE entidad			LIKE gent012.g12_tiporeg
DEFINE n_entidad		LIKE gent011.g11_nombre
DEFINE subtipo			LIKE gent012.g12_subtipo
DEFINE n_subtipo		LIKE gent012.g12_nombre

DEFINE r_ent			RECORD LIKE gent011.*
--DEFINE r_sub			RECORD LIKE gent012.*

CLEAR FORM

INITIALIZE entidad TO NULL
INITIALIZE subtipo TO NULL

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON g12_tiporeg, g12_subtipo, g12_nombre, g12_usuario
	ON KEY(F2)
		IF INFIELD(g12_tiporeg) THEN
			CALL fl_ayuda_entidad() RETURNING entidad, n_entidad
			IF entidad IS NOT NULL THEN
				LET rm_sub.g12_tiporeg = entidad
				DISPLAY BY NAME rm_sub.g12_tiporeg
				DISPLAY n_entidad TO nom_ent
			END IF
		END IF
		IF INFIELD(g12_subtipo) THEN
			CALL fl_ayuda_subtipo_entidad(rm_sub.g12_tiporeg) 
				RETURNING entidad, subtipo, n_subtipo, n_entidad
			IF entidad IS NOT NULL THEN
				LET rm_sub.g12_tiporeg = entidad
				LET rm_sub.g12_subtipo = subtipo
				DISPLAY BY NAME rm_sub.g12_tiporeg,
						rm_sub.g12_subtipo
				DISPLAY n_subtipo TO g12_nombre
				DISPLAY n_entidad TO nom_ent
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD g12_tiporeg
		LET rm_sub.g12_tiporeg = GET_FLDBUF(g12_tiporeg)
		IF rm_sub.g12_tiporeg IS NULL THEN
			CLEAR nom_ent
		ELSE
			CALL fl_lee_entidad(rm_sub.g12_tiporeg) 
				RETURNING r_ent.*
			IF r_ent.g11_tiporeg IS NULL THEN	
				CLEAR nom_ent
				NEXT FIELD g12_tiporeg
			ELSE
				DISPLAY r_ent.g11_nombre TO nom_ent
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

LET query = 'SELECT *, ROWID FROM gent012 WHERE ', expr_sql, 'ORDER BY 1, 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_sub.*, vm_rows[vm_num_rows]
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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE entidad		LIKE gent011.g11_nombre

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_sub.* FROM gent012 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

SELECT g11_nombre INTO entidad 
	FROM gent011 
	WHERE g11_tiporeg = rm_sub.g12_tiporeg

DISPLAY BY NAME rm_sub.*
DISPLAY entidad TO nom_ent

CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

END FUNCTION



FUNCTION no_validar_parametros()

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

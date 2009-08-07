------------------------------------------------------------------------------
-- Titulo           : maqp101.4gl - Mantenimiento de Cantones    
-- Elaboracion      : 18-nov-2004
-- Autor            : JCM
-- Formato Ejecucion: fglrun maqp101 base modulo compania 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_m02			RECORD LIKE maqt002.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/maqp101.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'maqp101'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_m02 AT 3,2 WITH 6 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_m02 FROM '../forms/maqf101_1'
DISPLAY FORM f_m02

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_m02.* TO NULL
CALL muestra_contadores()
CALL muestra_etiquetas()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
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
DEFINE rowid		INTEGER

CLEAR FORM
INITIALIZE rm_m02.* TO NULL

-- INITIALIZING NOT NULL FIELDS. IF IN AN INPUT I CAN'T PUT ANYTHING IN THEM -- 

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT MAX(m02_canton) INTO rm_m02.m02_canton FROM maqt002
IF rm_m02.m02_canton IS NULL THEN
	LET rm_m02.m02_canton = 1
ELSE
	LET rm_m02.m02_canton = rm_m02.m02_canton + 1
END IF

INSERT INTO maqt002 VALUES (rm_m02.*)
LET rowid = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila procesada 
DISPLAY BY NAME rm_m02.m02_canton

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid            	-- Rowid de la ultima fila 
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

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM maqt002 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_m02.*
WHENEVER ERROR STOP
IF SQLCA.SQLCODE < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF  
IF SQLCA.SQLCODE = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe rowid en la tabla.', 'stop')
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF 

UPDATE maqt002 SET * = rm_m02.* WHERE CURRENT OF q_upd

COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_m01		RECORD LIKE maqt001.*
DEFINE r_m02		RECORD LIKE maqt002.*

LET INT_FLAG = 0
INPUT BY NAME 
              rm_m02.m02_nombre, rm_m02.m02_provincia  
              WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_m02.m02_nombre, rm_m02.m02_provincia) 
		THEN
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
		IF INFIELD(m02_provincia) THEN
			CALL fl_ayuda_provincias()
				RETURNING r_m01.m01_provincia, 
                                          r_m01.m01_nombre
			IF r_m01.m01_provincia IS NOT NULL THEN
				LET rm_m02.m02_provincia = r_m01.m01_provincia
				DISPLAY BY NAME rm_m02.m02_provincia 
				DISPLAY r_m01.m01_nombre TO n_provincia
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD m02_provincia
		IF rm_m02.m02_provincia IS NULL THEN
			CLEAR n_provincia
		ELSE
			CALL fl_lee_provincia(rm_m02.m02_provincia)
				RETURNING r_m01.*
			IF r_m01.m01_provincia IS NULL THEN	
				CLEAR n_provincia
				CALL fgl_winmessage(vg_producto,
					            'Provincia no existe',
						    'exclamation')
				NEXT FIELD m01_provincia
			ELSE
				DISPLAY r_m01.m01_nombre TO n_provincia
			END IF 
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_m01		RECORD LIKE maqt001.*
DEFINE r_m02		RECORD LIKE maqt002.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON m02_canton, m02_nombre, m02_provincia
	ON KEY(F2)
		IF INFIELD(m02_provincia) THEN
			CALL fl_ayuda_provincias()
				RETURNING r_m01.m01_provincia, 
                                          r_m01.m01_nombre
			IF r_m01.m01_provincia IS NOT NULL THEN
				LET rm_m02.m02_provincia = r_m01.m01_provincia
				DISPLAY BY NAME rm_m02.m02_provincia 
				DISPLAY r_m01.m01_nombre TO n_provincia
			END IF
		END IF
		IF INFIELD(m02_canton) THEN
			CALL fl_ayuda_cantones(rm_m02.m02_provincia)
				RETURNING r_m02.m02_provincia,
                                          r_m01.m01_nombre,
  					  r_m02.m02_canton, 
                                          r_m02.m02_nombre
			IF r_m02.m02_provincia IS NOT NULL THEN
				LET rm_m02.m02_provincia = r_m01.m01_provincia
				LET rm_m02.m02_canton = r_m02.m02_canton
				LET rm_m02.m02_nombre = r_m02.m02_nombre
				DISPLAY BY NAME rm_m02.*
				DISPLAY r_m01.m01_nombre TO n_provincia
			END IF
		END IF
		LET INT_FLAG = 0
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM maqt002 ',
            '	WHERE ', expr_sql 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_m02.*, vm_rows[vm_num_rows]
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

SELECT * INTO rm_m02.* FROM maqt002 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_m02.m02_provincia,
                rm_m02.m02_canton,
                rm_m02.m02_nombre

CALL muestra_contadores()
CALL muestra_etiquetas()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 

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

DEFINE r_m01			RECORD LIKE maqt001.*

CALL fl_lee_provincia(rm_m02.m02_provincia) RETURNING r_m01.*
DISPLAY r_m01.m01_nombre TO n_provincia

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

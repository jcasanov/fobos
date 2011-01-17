{*
 * Titulo           : repp115.4gl - Mantenimiento de factores por tipo de 
 *                                  importacion
 * Elaboracion      : 26-ago-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp115 base modulo compania 
 *}
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
DEFINE rm_r114			RECORD LIKE rept114.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp115.error')
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
LET vg_proceso = 'repp115'

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
OPEN WINDOW w_r114 AT 3,2 WITH 11 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_r114 FROM '../forms/repf115_1'
DISPLAY FORM f_r114

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r114.* TO NULL
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
			
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
			IF fl_control_permiso_opcion('Modificar') THEN			
				SHOW OPTION 'Modificar'
		 	END IF 
			
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			IF fl_control_permiso_opcion('Modificar') THEN			
				SHOW OPTION 'Modificar'
			END IF 
			
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
INITIALIZE rm_r114.* TO NULL

-- INITIALIZING NOT NULL FIELDS. IF IN AN INPUT I CAN'T PUT ANYTHING IN THEM -- 

-- Campos de la tabla rept114
LET rm_r114.r114_compania = vg_codcia
LET rm_r114.r114_usuario  = vg_usuario
LET rm_r114.r114_fecing   = CURRENT

LET rm_r114.r114_factor     = 0
LET rm_r114.r114_distribuir = 'S'
LET rm_r114.r114_default    = 'N'
LET rm_r114.r114_flag_ident = 'IMP'

DISPLAY BY NAME rm_r114.r114_codigo,
                rm_r114.r114_descripcion,
                rm_r114.r114_factor,
                rm_r114.r114_default,
                rm_r114.r114_flag_ident,
				rm_r114.r114_usuario,
				rm_r114.r114_fecing
------------------------------------------------------------------------------- 

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

SELECT MAX(r114_codigo) INTO rm_r114.r114_codigo
  FROM rept114
 WHERE r114_compania = vg_codcia
IF rm_r114.r114_codigo IS NULL THEN
	LET rm_r114.r114_codigo = 0
END IF
LET rm_r114.r114_codigo = rm_r114.r114_codigo + 1 

INSERT INTO rept114 VALUES (rm_r114.*)
LET rowid = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila procesada 

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = rowid            	-- Rowid de la ultima fila 
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

BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM rept114 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
WHENEVER ERROR CONTINUE
OPEN q_upd
IF SQLCA.SQLCODE < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF  
WHENEVER ERROR STOP
FETCH q_upd INTO rm_r114.*
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

UPDATE rept114 SET * = rm_r114.* WHERE CURRENT OF q_upd

COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r			RECORD LIKE rept114.*

LET INT_FLAG = 0
INPUT BY NAME rm_r114.r114_codigo,  rm_r114.r114_descripcion,  
              rm_r114.r114_factor, 
			  rm_r114.r114_default, rm_r114.r114_flag_ident, 
			  rm_r114.r114_usuario, rm_r114.r114_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r114_codigo, r114_descripcion, r114_factor,  
							 r114_default, r114_flag_ident) 
		THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	AFTER INPUT
		IF rm_r114.r114_default = 'S' THEN
			CALL fl_lee_factor_importacion_stock_rep_predeterminado(
														vg_codcia, 
														rm_r114.r114_flag_ident
				 ) RETURNING r.*
			IF r.r114_compania IS NOT NULL THEN
				CASE flag
					WHEN 'I'
						CALL fgl_winmessage(vg_producto, 'Ya hay un factor predeterminado para este tipo de importación.', 'exclamation')
						CONTINUE INPUT
					WHEN 'M'
						IF r.r114_codigo <> rm_r114.r114_codigo THEN
							CALL fgl_winmessage(vg_producto, 'Ya hay un factor predeterminado para este tipo de importación.', 'exclamation')
							CONTINUE INPUT
						END IF
				END CASE
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE rm_r114		RECORD LIKE rept114.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON r114_codigo, r114_descripcion, r114_factor, r114_default, r114_usuario
	ON KEY(F2)
		IF INFIELD(r114_codigo) THEN
        	CALL fl_ayuda_factor_importacion_stock_rep(vg_codcia)
				RETURNING rm_r114.r114_codigo, rm_r114.r114_descripcion
			IF rm_r114.r114_codigo IS NOT NULL THEN
				DISPLAY BY NAME rm_r114.r114_codigo, rm_r114.r114_descripcion
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

LET query = 'SELECT *, ROWID FROM rept114 ',
            '	WHERE r114_compania  = ', vg_codcia, 
            '  	  AND ', expr_sql, 
            ' ORDER BY 1, 2' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r114.*, vm_rows[vm_num_rows]
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

SELECT * INTO rm_r114.* FROM rept114 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_r114.r114_codigo,
                rm_r114.r114_descripcion,
                rm_r114.r114_factor,
                rm_r114.r114_default,
                rm_r114.r114_flag_ident,
				rm_r114.r114_usuario,
				rm_r114.r114_fecing

CALL muestra_contadores()

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

------------------------------------------------------------------------------
-- Titulo           : genp105.4gl - Mantenimiento de Impresoras 
-- Elaboracion      : 23-ago-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun genp105 base modulo 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[1000] OF INTEGER 	-- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE rm_imp		RECORD LIKE gent006.*
DEFINE rm_impbod	ARRAY[1000] OF RECORD
				g24_bodega	LIKE gent024.g24_bodega,
				r02_nombre	LIKE rept002.r02_nombre,
				g24_imprime	LIKE gent024.g24_imprime,
				asignada	CHAR(1)
			END RECORD
DEFINE rm_user		ARRAY[1000] OF RECORD
				g24_usuario	LIKE gent024.g24_usuario,
				g24_fecing	LIKE gent024.g24_fecing
			END RECORD
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp105.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp105'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_genf105_1 AT 03, 02 WITH 14 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
OPEN FORM f_genf105_1 FROM '../forms/genf105_1'
DISPLAY FORM f_genf105_1
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
LET vm_max_det     = 1000
INITIALIZE rm_imp.* TO NULL
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Impresora/Bodega'
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Impresora/Bodega'
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
			SHOW OPTION 'Impresora/Bodega'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Impresora/Bodega'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Impresora/Bodega'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('B') 'Impresora/Bodega'	'Asignar impresora por bodega.'
		CALL control_asignar_impresora_bodegas()
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
INITIALIZE rm_imp.* TO NULL

LET rm_imp.g06_fecing = CURRENT
LET rm_imp.g06_usuario = vg_usuario

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
INSERT INTO gent006 VALUES (rm_imp.*)

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

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM gent006 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_imp.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  

CALL lee_datos('M')

IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	WHENEVER ERROR STOP
	RETURN
END IF 
WHENEVER ERROR STOP
UPDATE gent006 SET * = rm_imp.* WHERE CURRENT OF q_upd
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)
DEFINE impresora		LIKE gent006.g06_impresora
DEFINE n_imp			LIKE gent006.g06_nombre
DEFINE r_imp			RECORD LIKE gent006.*

CLEAR FORM

INITIALIZE impresora TO NULL
LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON g06_impresora, g06_nombre, g06_default, g06_usuario
	ON KEY(F2)
		IF INFIELD(g06_impresora) THEN
			CALL fl_ayuda_impresoras("TODAS")
				RETURNING impresora, n_imp
			IF impresora IS NOT NULL THEN
				LET rm_imp.g06_impresora = impresora
				DISPLAY BY NAME rm_imp.g06_impresora
				DISPLAY n_imp TO g06_nombre
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD g06_impresora
		LET rm_imp.g06_impresora = GET_FLDBUF(g06_impresora)
		IF rm_imp.g06_impresora IS NULL THEN
			CLEAR g06_nombre
		ELSE
			CALL fl_lee_impresora(rm_imp.g06_impresora) 
				RETURNING r_imp.*
			IF r_imp.g06_impresora IS NULL THEN	
				CLEAR  g06_nombre
			ELSE
				DISPLAY r_imp.g06_nombre TO g06_nombre
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

LET query = 'SELECT *, ROWID FROM gent006 WHERE ', expr_sql, 'ORDER BY 1' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_imp.*, vm_rows[vm_num_rows]
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



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE default		INTEGER

DEFINE r_imp 		RECORD LIKE gent006.*

IF flag = 'I' THEN
	LET rm_imp.g06_default = 'N'
END IF
LET INT_FLAG = 0
INPUT BY NAME rm_imp.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_imp.g06_impresora, rm_imp.g06_nombre,
                                     rm_imp.g06_default
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	BEFORE FIELD g06_impresora
		IF flag = 'M' THEN
			NEXT FIELD g06_nombre
		END IF
	AFTER FIELD g06_impresora
		CALL fl_lee_impresora(rm_imp.g06_impresora) RETURNING r_imp.*
		IF r_imp.g06_impresora IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto, 
                                            'Esta impresora ya existe',
                                            'exclamation')
			NEXT FIELD g06_impresora
		END IF
	AFTER INPUT
		IF FIELD_TOUCHED(g06_impresora) AND flag = 'M' THEN
			CALL fgl_winmessage(vg_producto,
                                            'No puede modificarse el código ' ||
                                            'de la impresora', 'exclamation')
			LET INT_FLAG = 1
			RETURN
		END IF
		IF rm_imp.g06_default = 'S' THEN
			SELECT ROWID INTO default 
				FROM gent006
				WHERE g06_default = 'S'
			IF STATUS <> NOTFOUND THEN
				CALL FGL_WINMESSAGE(vg_producto, 
           		             'Ya existe una impresora predeterminada',
                                     'info')
				LET rm_imp.g06_default = 'N'
				DISPLAY BY NAME rm_imp.g06_default
				CONTINUE INPUT
			END IF 
		END IF
END INPUT

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

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_imp.* FROM gent006 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_imp.*
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 70 

END FUNCTION



FUNCTION control_asignar_impresora_bodegas()
DEFINE r_g06		RECORD LIKE gent006.*

OPEN WINDOW w_genf105_2 AT 05, 13
        WITH FORM '../forms/genf105_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   BORDER)
DISPLAY "BD"		TO tit_col1
DISPLAY "Nombre Bodega"	TO tit_col2
DISPLAY "I"		TO tit_col3
DISPLAY "A"		TO tit_col4
DISPLAY rm_imp.g06_impresora TO g24_impresora
CALL fl_lee_impresora(rm_imp.g06_impresora) RETURNING r_g06.*
DISPLAY BY NAME r_g06.g06_nombre
CALL cargar_detalle()
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 0
	CLOSE WINDOW w_genf105_2
	RETURN
END IF
CALL asignar_impresora_bodegas()
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_genf105_2
	RETURN
END IF
BEGIN WORK
	IF NOT grabar_impresora_bodegas() THEN
		ROLLBACK WORK
		LET int_flag = 0
		CLOSE WINDOW w_genf105_2
		RETURN
	END IF
COMMIT WORK
CALL fl_mostrar_mensaje('Impresora asignada a Bodegas. OK', 'info')
LET int_flag = 0
CLOSE WINDOW w_genf105_2
RETURN

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		CHAR(1500)
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_impbod[i].*, rm_user[i].* TO NULL
END FOR
LET query = 'SELECT NVL(g24_bodega, r02_codigo) bodega, r02_nombre nombre, ',
		'NVL(g24_imprime, "N") imprime, ',
		'CASE WHEN g24_bodega IS NOT NULL ',
			'THEN "S" ',
			'ELSE "N" ',
		'END asignada, NVL(g24_usuario, "', vg_usuario CLIPPED, '"), ',
		'NVL(g24_fecing, CURRENT) ',
		' FROM rept002, OUTER gent024 ',
		' WHERE r02_compania  = ', vg_codcia,
		'   AND r02_localidad = ', vg_codloc,
		'   AND r02_tipo      = "F" ',
		'   AND r02_area      = "R" ',
		'   AND r02_estado    = "A" ',
		'   AND g24_compania  = r02_compania ',
		'   AND g24_bodega    = r02_codigo ',
		'   AND g24_impresora = "', rm_imp.g06_impresora, '"',
		' ORDER BY 4 DESC, 1 ASC, 2 ASC'
PREPARE cons_g24 FROM query
DECLARE q_g24 CURSOR FOR cons_g24
LET vm_num_det = 1
FOREACH q_g24 INTO rm_impbod[vm_num_det].*, rm_user[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION asignar_impresora_bodegas()
DEFINE resp		CHAR(6)
DEFINE i, j		SMALLINT

DISPLAY vm_num_det TO max_row
LET int_flag = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_impbod WITHOUT DEFAULTS FROM rm_impbod.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("INSERT","")
		--#CALL dialog.keysetlabel("DELETE","")
	BEFORE INSERT
		--#CANCEL INSERT
	BEFORE DELETE
		--#CANCEL DELETE
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		DISPLAY i TO num_row
		DISPLAY BY NAME rm_user[i].*
	AFTER INPUT
		LET j = 0
		FOR i = 1 TO vm_num_det
			IF rm_impbod[i].asignada = 'S' THEN
				LET j = j + 1
			END IF
		END FOR
		IF j = 0 THEN
			CALL fl_mostrar_mensaje('Al menos debe seleccionar una bodega.', 'info')
			--CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION grabar_impresora_bodegas()
DEFINE i, resul		SMALLINT

LET resul = 1
FOR i = 1 TO vm_num_det
	IF rm_impbod[i].asignada = 'N' THEN
		WHENEVER ERROR CONTINUE
		DELETE FROM gent024
			WHERE g24_compania  = vg_codcia
			  AND g24_bodega    = rm_impbod[i].g24_bodega
			  AND g24_impresora = rm_imp.g06_impresora
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se puede borrar el registro Bodega: ' || rm_impbod[i].g24_bodega || ' Impresora: ' || rm_imp.g06_impresora || '. LLAME AL ADMINISTRADOR.', 'exclamation')
			LET resul = 0
			EXIT FOR
		END IF
		CONTINUE FOR
	END IF
	SELECT * FROM gent024
		WHERE g24_compania  = vg_codcia
		  AND g24_bodega    = rm_impbod[i].g24_bodega
		  AND g24_impresora = rm_imp.g06_impresora
	IF STATUS = NOTFOUND THEN
		WHENEVER ERROR CONTINUE
		INSERT INTO gent024
			VALUES (vg_codcia, rm_impbod[i].g24_bodega,
				rm_imp.g06_impresora, rm_impbod[i].g24_imprime,
				vg_usuario, CURRENT)
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se puede insertar el registro Bodega: ' || rm_impbod[i].g24_bodega || ' Impresora: ' || rm_imp.g06_impresora || '. LLAME AL ADMINISTRADOR.', 'exclamation')
			LET resul = 0
			EXIT FOR
		END IF
	ELSE
		WHENEVER ERROR CONTINUE
		UPDATE gent024
			SET g24_imprime = rm_impbod[i].g24_imprime
			WHERE g24_compania  = vg_codcia
			  AND g24_bodega    = rm_impbod[i].g24_bodega
			  AND g24_impresora = rm_imp.g06_impresora
		IF STATUS <> 0 THEN
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se puede actualizar el registro Bodega: ' || rm_impbod[i].g24_bodega || ' Impresora: ' || rm_imp.g06_impresora || '. LLAME AL ADMINISTRADOR.', 'exclamation')
			LET resul = 0
			EXIT FOR
		END IF
	END IF
END FOR
RETURN resul

END FUNCTION

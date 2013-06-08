--------------------------------------------------------------------------------
-- Titulo           : genp140.4gl - Consulta Permisos de Usuarios x Modulo
-- Elaboracion      : 07-Abr-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun genp140 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g53		RECORD LIKE gent053.*
DEFINE rm_g55		RECORD LIKE gent055.*
DEFINE rm_permisos	ARRAY[6000] OF RECORD
				g05_usuario	LIKE gent005.g05_usuario,
				g50_nombre	LIKE gent050.g50_nombre,
				g54_proceso	LIKE gent054.g54_proceso,
				g54_nombre	LIKE gent054.g54_nombre,
				asignar_pro	CHAR(1),
				asignar_men	CHAR(1)
			END RECORD
DEFINE vm_row_cur	SMALLINT        	-- POSICION DE FILA ACTUAL
DEFINE vm_row_num	SMALLINT        	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_row_max	SMALLINT		-- MAXIMO DE FILAS LEIDAS
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_grabar_pro	SMALLINT
DEFINE vm_grabar_men	SMALLINT
DEFINE vm_incluir_pro	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp140.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'genp140'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_generales AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_genf140_1 FROM '../forms/genf140_1'
ELSE
	OPEN FORM f_genf140_1 FROM '../forms/genf140_1c'
END IF
DISPLAY FORM f_genf140_1
INITIALIZE rm_g53.*, rm_g55.* TO NULL
LET vm_row_cur = 0
LET vm_row_num = 0
LET vm_row_max = 6000
CALL control_proceso()

END FUNCTION



FUNCTION control_proceso()

LET vm_incluir_pro = 'N'
WHILE TRUE
	CALL borrar_detalle()
	CALL muestra_contadores()
	CALL mostrar_botones_detalle()
	CALL control_ingreso()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL muestra_detalle()
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g54		RECORD LIKE gent054.*

LET int_flag = 0
INPUT BY NAME rm_g53.g53_usuario, rm_g53.g53_modulo, rm_g55.g55_proceso,
	vm_incluir_pro
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		--#RETURN
		EXIT INPUT
        ON KEY(F2)
		IF INFIELD(g53_usuario) THEN
			CALL fl_ayuda_usuarios()
				RETURNING r_g05.g05_usuario, r_g05.g05_nombres
			IF r_g05.g05_usuario IS NOT NULL THEN
				LET rm_g53.g53_usuario = r_g05.g05_usuario
				DISPLAY BY NAME rm_g53.g53_usuario,
						r_g05.g05_nombres
			END IF
		END IF
		IF INFIELD(g53_modulo) THEN
			CALL fl_ayuda_modulos()
				RETURNING r_g50.g50_modulo, r_g50.g50_nombre
			IF r_g50.g50_modulo IS NOT NULL THEN
				LET rm_g53.g53_modulo = r_g50.g50_modulo
				DISPLAY BY NAME rm_g53.g53_modulo
				DISPLAY r_g50.g50_nombre TO tit_nombre_mod
			END IF
		END IF
		IF INFIELD(g55_proceso) THEN
			CALL fl_ayuda_procesos(rm_g53.g53_modulo)
				RETURNING r_g54.g54_modulo, r_g54.g54_proceso,
					  r_g54.g54_nombre
			IF r_g54.g54_proceso IS NOT NULL THEN
				LET rm_g55.g55_proceso = r_g54.g54_proceso
				DISPLAY BY NAME rm_g55.g55_proceso
				DISPLAY r_g54.g54_nombre TO tit_nombre
			END IF
		END IF
		LET int_flag = 0
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD g53_usuario
		IF rm_g53.g53_usuario IS NOT NULL THEN
			CALL fl_lee_usuario(rm_g53.g53_usuario)
				RETURNING r_g05.*
			IF r_g05.g05_usuario IS NULL THEN
				CALL fl_mostrar_mensaje('Este usuario no existe.','exclamation')
				NEXT FIELD g53_usuario
			END IF
			DISPLAY BY NAME r_g05.g05_nombres
			IF r_g05.g05_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g53_usuario
			END IF
		ELSE
			CLEAR g05_nombres
		END IF
	AFTER FIELD g53_modulo
		IF rm_g53.g53_modulo IS NOT NULL THEN
			CALL fl_lee_modulo(rm_g53.g53_modulo) RETURNING r_g50.*
			IF r_g50.g50_modulo IS NULL THEN
				CALL fl_mostrar_mensaje('Este módulo no existe.','exclamation')
				NEXT FIELD g53_modulo
			END IF
			DISPLAY r_g50.g50_nombre TO tit_nombre_mod
			IF r_g50.g50_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g53_modulo
			END IF
		ELSE
			CLEAR tit_nombre_mod, tit_nombre
		END IF
	AFTER FIELD g55_proceso
		IF rm_g53.g53_modulo IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_g55.g55_proceso IS NOT NULL THEN
			CALL fl_lee_proceso(rm_g53.g53_modulo,
						rm_g55.g55_proceso)
				RETURNING r_g54.*
			IF r_g54.g54_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('Este proceso no existe.','exclamation')
				NEXT FIELD g55_proceso
			END IF
			DISPLAY r_g54.g54_nombre TO tit_nombre
			IF r_g54.g54_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g55_proceso
			END IF
		ELSE
			CLEAR tit_nombre
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(800)

IF NOT proceso_carga() THEN
	DROP TABLE tmp_permisos
	RETURN
END IF
IF rm_g53.g53_usuario IS NULL THEN
	LET col            = 1
	LET vm_columna_1   = col
	LET vm_columna_2   = 2
ELSE
	LET col            = 2
	LET vm_columna_1   = col
	LET vm_columna_2   = 3
END IF
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM tmp_permisos ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det FROM query
	DECLARE q_det CURSOR FOR det
	LET vm_row_num = 1
        FOREACH q_det INTO rm_permisos[vm_row_num].*
                LET vm_row_num = vm_row_num + 1
                IF vm_row_num > vm_row_max THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_row_num = vm_row_num - 1
        IF vm_row_num = 0 THEN
		EXIT WHILE
	END IF
	LET int_flag = 0
	CALL set_count(vm_row_num)
	DISPLAY ARRAY rm_permisos TO rm_permisos.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F5)
			IF vg_usuario <> 'FOBOS' THEN
				CONTINUE DISPLAY
			END IF
			CALL asigna_permisos()
			LET int_flag = 0
			LET col      = 0
			EXIT DISPLAY
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_usuario(i)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#LET vm_row_cur = i
			--#CALL muestra_contadores()
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF vg_usuario <> 'FOBOS' THEN
				--#CALL dialog.keysetlabel("F5","")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","Permisos")
			--#END IF
			--#CALL dialog.keysetlabel("F6","Usuario")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col = 0 THEN
		CONTINUE WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE tmp_permisos

END FUNCTION



FUNCTION proceso_carga()
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE query		VARCHAR(250)
DEFINE expr_usr		VARCHAR(60)
DEFINE cuantos		INTEGER

SELECT g55_modulo, g55_proceso, g54_modulo, g54_proceso, g54_nombre
	FROM gent054, gent055
	WHERE g54_modulo   = 'XX'
	  AND g54_proceso  = 'xxxxx'
	  AND g55_compania = 10
	  AND g55_modulo   = g54_modulo
	  AND g55_proceso  = g54_proceso
	INTO TEMP t1
SELECT g53_usuario, g50_nombre, g54_proceso, g54_nombre, '' asignar_pro,
		'' asignar_men
	FROM gent053, gent050, t1
	WHERE g53_usuario = 'XXX'
	  AND g53_modulo  = g54_modulo
	  AND g50_modulo  = g53_modulo
	  AND g50_estado  = 'A'
	INTO TEMP tmp_permisos
LET expr_usr = NULL
IF rm_g53.g53_usuario IS NOT NULL THEN
	LET expr_usr = ' g05_usuario = "', rm_g53.g53_usuario, '"  AND '
END IF
LET query = 'SELECT * FROM gent005 ',
		' WHERE ', expr_usr CLIPPED,
		'       g05_estado <> "B" '
PREPARE usr_cons FROM query
DECLARE q_g05 CURSOR FOR usr_cons
FOREACH q_g05 INTO r_g05.*
	CALL cargar_temporal(r_g05.g05_usuario)
	DELETE FROM t1 WHERE 1 = 1
END FOREACH
DROP TABLE t1
SELECT COUNT(*) INTO cuantos FROM tmp_permisos
IF cuantos = 0 THEN
	LET vm_row_num = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION cargar_temporal(usuario)
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE query		CHAR(900)
DEFINE expr_mod		CHAR(100)
DEFINE expr_pro		CHAR(200)
DEFINE cuantos		INTEGER
DEFINE r_permiso	RECORD
				g_usuario	LIKE gent005.g05_usuario,
				g_nombre	LIKE gent050.g50_nombre,
				g_proceso	LIKE gent054.g54_proceso,
				g4_nombre	LIKE gent054.g54_nombre,
				asignar_pro1	CHAR(1),
				asignar_men1	CHAR(1)
			END RECORD
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g54		RECORD LIKE gent054.*

LET expr_mod  = NULL
IF rm_g53.g53_modulo IS NOT NULL THEN
	LET expr_mod  = ' g54_modulo   = "', rm_g53.g53_modulo, '"  AND '
END IF
LET expr_pro  = NULL
IF rm_g55.g55_proceso IS NOT NULL THEN
	LET expr_pro  = ' g54_proceso  = "', rm_g55.g55_proceso, '"  AND '
END IF
LET query = 'INSERT INTO t1 ',
		'SELECT g55_modulo, g55_proceso, g54_modulo, ',
				' g54_proceso, g54_nombre ',
			' FROM gent054, OUTER gent055 ',
			' WHERE ', expr_mod CLIPPED,
				expr_pro CLIPPED,
			'       g54_estado  <> "B" ',
			'   AND g55_user     = "', usuario, '"',
			'   AND g55_compania = ', vg_codcia,
		  	'   AND g55_modulo   = g54_modulo ',
	  		'   AND g55_proceso  = g54_proceso '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DELETE FROM t1
	WHERE g55_modulo  IS NOT NULL
	  AND g55_proceso IS NOT NULL
LET query = 'INSERT INTO tmp_permisos ',
		'SELECT g53_usuario, g50_nombre, g54_proceso, g54_nombre, ',
			' "S", "N" ',
			' FROM gent053, gent050, t1 ',
			' WHERE ', expr_mod CLIPPED,
				expr_pro CLIPPED,
			'       g53_usuario  = "', usuario, '"',
			'   AND g53_compania = ', vg_codcia,
			'   AND g53_modulo   = g54_modulo ',
			'   AND g50_modulo   = g53_modulo ',
			'   AND g50_estado   = "A"'
PREPARE exec_per FROM query
EXECUTE exec_per
UPDATE tmp_permisos SET asignar_men = 'S'
	WHERE g53_usuario = usuario
	  AND g54_proceso IN (SELECT g57_proceso FROM gent057
				WHERE g57_user     = usuario
				  AND g57_compania = vg_codcia)
IF vm_incluir_pro = 'N' THEN
	RETURN
END IF
LET query = ' SELECT * FROM gent050 a ',
		' WHERE g50_estado = "A" '
SELECT COUNT(*) INTO cuantos FROM tmp_permisos
IF cuantos > 0 THEN
	LET query = query CLIPPED,
			'   AND a.g50_nombre IN ',
			'   (SELECT UNIQUE g50_nombre FROM tmp_permisos '
	IF rm_g53.g53_usuario IS NOT NULL THEN
		LET query = query CLIPPED,
				' WHERE g53_usuario = "', usuario, '"'
	END IF
	LET query = query CLIPPED, ')'
END IF
PREPARE cons_g50_2 FROM query
DECLARE q_g50 CURSOR FOR cons_g50_2
FOREACH q_g50 INTO r_g50.*
	IF rm_g53.g53_modulo IS NOT NULL THEN
		IF rm_g53.g53_modulo <> r_g50.g50_modulo THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET expr_pro = NULL
	IF rm_g55.g55_proceso IS NOT NULL THEN
		CALL fl_lee_proceso(r_g50.g50_modulo, rm_g55.g55_proceso)
			RETURNING r_g54.*
		IF r_g54.g54_modulo IS NULL THEN
			CONTINUE FOREACH
		END IF
		LET expr_pro = '   AND g54_proceso = "', rm_g55.g55_proceso, '"'
	END IF
	LET query = ' SELECT "', usuario, '", "', r_g50.g50_nombre, '", ',
			' g54_proceso, g54_nombre, "N", "N" ',
			' FROM gent054 ',
			' WHERE g54_modulo  = "', r_g50.g50_modulo, '"',
			expr_pro CLIPPED,
			'   AND g54_estado <> "B"'
	PREPARE cons_g54 FROM query
	DECLARE q_cons_g54 CURSOR FOR cons_g54
	FOREACH q_cons_g54 INTO r_permiso.*
		SELECT * FROM tmp_permisos
			WHERE g53_usuario = r_permiso.g_usuario
			  AND g54_proceso = r_permiso.g_proceso
		IF STATUS <> NOTFOUND THEN
			CONTINUE FOREACH
		END IF
		INSERT INTO tmp_permisos VALUES(r_permiso.*)
	END FOREACH
	IF rm_g55.g55_proceso IS NOT NULL THEN
		EXIT FOREACH
	END IF
END FOREACH

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_cur, vm_row_num

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY "Usuario"		TO tit_col1
--#DISPLAY "Módulo"		TO tit_col2
--#DISPLAY "Proceso"		TO tit_col3
--#DISPLAY "Nombre del Proceso"	TO tit_col4
--#DISPLAY "P"                 	TO tit_col5
--#DISPLAY "M"                 	TO tit_col6

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_permisos')
	CLEAR rm_permisos[i].*
END FOR
LET vm_row_cur = 0
LET vm_row_num = 0

END FUNCTION



FUNCTION asigna_permisos()
DEFINE resul_men		SMALLINT
DEFINE resul_pro		SMALLINT

LET vm_grabar_pro = 0
LET vm_grabar_men = 0
CALL chequear_permisos()
IF int_flag THEN
	RETURN
END IF
BEGIN WORK
	IF vm_grabar_pro THEN
		CALL grabar_permisos_pro() RETURNING resul_pro
	END IF
	IF vm_grabar_men THEN
		CALL grabar_permisos_men() RETURNING resul_men
	END IF
COMMIT WORK
IF vm_grabar_pro THEN
	IF resul_pro THEN
		CALL fl_mostrar_mensaje('Permisos de Proceso asignados Ok.','info')
	ELSE
		CALL fl_mostrar_mensaje('Permisos de Proceso retirados Ok.','info')
	END IF
END IF
IF vm_grabar_men THEN
	IF resul_men THEN
		CALL fl_mostrar_mensaje('Permisos de Menú asignados Ok.','info')
	ELSE
		CALL fl_mostrar_mensaje('Permisos de Menú retirados Ok.','info')
	END IF
END IF
DELETE FROM tmp_permisos
	WHERE asignar_men = 'N'
	  AND asignar_pro = 'N'
SELECT COUNT(*) INTO vm_row_num FROM tmp_permisos

END FUNCTION



FUNCTION chequear_permisos()
DEFINE resp             CHAR(6)
DEFINE i, j, resul	SMALLINT
DEFINE salir, col	SMALLINT
DEFINE flag_tod		SMALLINT
DEFINE flag_nin		SMALLINT
DEFINE r_permisos_aux	ARRAY[6000] OF RECORD
				g05_usuario	LIKE gent005.g05_usuario,
				g50_nombre	LIKE gent050.g50_nombre,
				g54_proceso	LIKE gent054.g54_proceso,
				g54_nombre	LIKE gent054.g54_nombre,
				asignar_pro	CHAR(1),
				asignar_men	CHAR(1)
			END RECORD

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
FOR i = 1 TO vm_row_num
	LET r_permisos_aux[i].* = rm_permisos[i].*
END FOR
SELECT * FROM tmp_permisos INTO TEMP tmp_aux
LET i 	  = 1
LET salir = 0
WHILE NOT salir
	CALL cargar_query_temp(vm_columna_1, rm_orden[vm_columna_1],
				vm_columna_2, rm_orden[vm_columna_2])
	CALL set_count(vm_row_num)
	LET int_flag = 0
	INPUT ARRAY rm_permisos WITHOUT DEFAULTS FROM rm_permisos.*
		ON KEY(INTERRUPT)
       			LET int_flag = 0
	               	CALL fl_mensaje_abandonar_proceso() RETURNING resp
       			IF resp = 'Yes' THEN
 	      			LET int_flag = 1
				FOR i = 1 TO vm_row_num
					LET rm_permisos[i].*=r_permisos_aux[i].*
				END FOR
				DROP TABLE tmp_permisos
				SELECT * FROM tmp_aux INTO TEMP tmp_permisos
				CALL mostrar_per()
				EXIT INPUT
       	       		END IF	
		ON KEY(F6)
			IF flag_tod THEN
				CALL chequear_todo_ninguno(1) RETURNING resul
				IF NOT resul THEN
					CONTINUE INPUT
				END IF
				LET flag_tod = 0
				LET flag_nin = 1
				LET int_flag = 0
				LET vm_grabar_pro = 1
				LET vm_grabar_men = 1
				CALL dialog.keysetlabel('F6', '')
				CALL dialog.keysetlabel('F7', 'Ninguno')
			END IF
		ON KEY(F7)
			IF flag_nin THEN
				CALL chequear_todo_ninguno(2) RETURNING resul
				IF NOT resul THEN
					CONTINUE INPUT
				END IF
				LET flag_nin = 0
				LET flag_tod = 1
				LET int_flag = 0
				LET vm_grabar_pro = 1
				LET vm_grabar_men = 1
				CALL dialog.keysetlabel('F7', '')
				CALL dialog.keysetlabel('F6', 'Todos')
			END IF
		ON KEY(F15)
			LET col = 1
			EXIT INPUT
		ON KEY(F16)
			LET col = 2
			EXIT INPUT
		ON KEY(F17)
			LET col = 3
			EXIT INPUT
		ON KEY(F18)
			LET col = 4
			EXIT INPUT
		ON KEY(F19)
			LET col = 5
			EXIT INPUT
		ON KEY(F20)
			LET col = 6
			EXIT INPUT
		BEFORE INPUT
			CALL dialog.keysetlabel('DELETE', '')
			CALL dialog.keysetlabel('INSERT', '')
			CALL buscar_check('N', 'N') RETURNING flag_tod
			IF flag_tod THEN
				CALL dialog.keysetlabel('F6', 'Todos')
			ELSE
				CALL dialog.keysetlabel('F6', '')
			END IF
			CALL buscar_check('S', 'S') RETURNING flag_nin
			IF flag_nin THEN
				CALL dialog.keysetlabel('F7', 'Ninguno')
			ELSE
				CALL dialog.keysetlabel('F7', '')
			END IF
		BEFORE ROW
	       		LET i = arr_curr()
       			LET j = scr_line()
			LET vm_row_cur = i
			CALL muestra_contadores()
			CALL buscar_check('N', 'N') RETURNING flag_tod
			IF flag_tod THEN
				CALL dialog.keysetlabel('F6', 'Todos')
			ELSE
				CALL dialog.keysetlabel('F6', '')
			END IF
			CALL buscar_check('S', 'S') RETURNING flag_nin
			IF flag_nin THEN
				CALL dialog.keysetlabel('F7', 'Ninguno')
			ELSE
				CALL dialog.keysetlabel('F7', '')
			END IF
		BEFORE INSERT
			LET int_flag = 0
			EXIT INPUT
		AFTER FIELD asignar_pro
			IF rm_permisos[i].asignar_pro = 'N' THEN
				LET rm_permisos[i].asignar_men = 'N'
				DISPLAY rm_permisos[i].asignar_men TO
					rm_permisos[j].asignar_men
			END IF
			UPDATE tmp_permisos
				SET asignar_pro = rm_permisos[i].asignar_pro,
				    asignar_men = rm_permisos[i].asignar_men
				WHERE g53_usuario = rm_permisos[i].g05_usuario
				  AND g54_proceso = rm_permisos[i].g54_proceso
			LET vm_grabar_pro = 1
		AFTER FIELD asignar_men
			IF rm_permisos[i].asignar_pro = 'N' THEN
				LET rm_permisos[i].asignar_men = 'N'
				DISPLAY rm_permisos[i].asignar_men TO
					rm_permisos[j].asignar_men
			END IF
			UPDATE tmp_permisos
				SET asignar_men = rm_permisos[i].asignar_men
				WHERE g53_usuario = rm_permisos[i].g05_usuario
				  AND g54_proceso = rm_permisos[i].g54_proceso
			LET vm_grabar_men = 1
		AFTER INPUT
			LET salir = 1
	END INPUT
	IF int_flag = 0 THEN
		CONTINUE WHILE
	END IF
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col < 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
LET vm_row_num = arr_count()
DROP TABLE tmp_aux

END FUNCTION



FUNCTION grabar_permisos_pro()
DEFINE i, flag		SMALLINT
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE r_permiso	RECORD
				g05_usuario	LIKE gent005.g05_usuario,
				g50_nombre	LIKE gent050.g50_nombre,
				g54_proceso	LIKE gent054.g54_proceso,
				g54_nombre	LIKE gent054.g54_nombre,
				asignar_pro	CHAR(1),
				asignar_men	CHAR(1)
			END RECORD
DEFINE r_g52		RECORD LIKE gent052.*
DEFINE r_g53		RECORD LIKE gent053.*
DEFINE r_g55		RECORD LIKE gent055.*
DEFINE cuanto_g54	INTEGER
DEFINE cuanto_g55	INTEGER
DEFINE user_cont	LIKE gent055.g55_user

FOR i = 1 TO vm_row_num
	INITIALIZE r_g55.*, modulo TO NULL
	DECLARE q_modulo2 CURSOR FOR
		SELECT g54_modulo FROM gent054
			WHERE g54_proceso  = rm_permisos[i].g54_proceso
			  AND g54_estado  <> "B"
	OPEN q_modulo2
	FETCH q_modulo2 INTO modulo
	CLOSE q_modulo2
	FREE q_modulo2
	SELECT * INTO r_g55.* FROM gent055
		WHERE g55_user     = rm_permisos[i].g05_usuario
		  AND g55_compania = vg_codcia
		  AND g55_proceso  = rm_permisos[i].g54_proceso
	IF r_g55.g55_compania IS NOT NULL THEN
		CONTINUE FOR
	END IF
	INSERT INTO gent055
		VALUES(rm_permisos[i].g05_usuario, vg_codcia, modulo,
			rm_permisos[i].g54_proceso, vg_usuario, CURRENT)
END FOR
DECLARE q_mod_cont CURSOR FOR
	SELECT g54_modulo, COUNT(*) FROM gent054
		WHERE g54_estado <> 'B'
		GROUP BY g54_modulo
FOREACH q_mod_cont INTO modulo, cuanto_g54
	DECLARE q_mod_cont2 CURSOR FOR
		SELECT g55_user, COUNT(*) FROM gent055
			WHERE g55_compania = vg_codcia
			  AND g55_modulo   = modulo
		GROUP BY g55_user
	FOREACH q_mod_cont2 INTO user_cont, cuanto_g55
		IF cuanto_g55 = 0 THEN
			CONTINUE FOREACH
		END IF
		IF cuanto_g55 <> cuanto_g54 THEN
			CONTINUE FOREACH
		END IF
		DELETE FROM gent052
			WHERE g52_modulo  = modulo
			  AND g52_usuario = user_cont
		DELETE FROM gent053
			WHERE g53_modulo  = modulo
			  AND g53_usuario = user_cont
	END FOREACH
END FOREACH
LET flag = 0
DECLARE q_tmp_pro CURSOR FOR SELECT * FROM tmp_permisos WHERE asignar_pro = 'S'
FOREACH q_tmp_pro INTO r_permiso.*
	INITIALIZE modulo TO NULL
	DECLARE q_modulo3 CURSOR FOR
		SELECT g50_modulo FROM gent050
			WHERE g50_nombre = r_permiso.g50_nombre
			  AND g50_estado = 'A'
	OPEN q_modulo3
	FETCH q_modulo3 INTO modulo
	CLOSE q_modulo3
	FREE q_modulo3
	INITIALIZE r_g52.*, r_g53.* TO NULL
	SELECT * INTO r_g52.*
		FROM gent052
		WHERE g52_modulo  = modulo
		  AND g52_usuario = r_permiso.g05_usuario
	IF r_g52.g52_modulo IS NULL THEN
		INSERT INTO gent052 VALUES(modulo, r_permiso.g05_usuario, 'A')
	END IF
	SELECT * INTO r_g53.*
		FROM gent053
		WHERE g53_modulo   = modulo
		  AND g53_usuario  = r_permiso.g05_usuario
		  AND g53_compania = vg_codcia
	IF r_g53.g53_modulo IS NULL THEN
		INSERT INTO gent053
			VALUES(modulo, r_permiso.g05_usuario, vg_codcia)
	END IF
	DELETE FROM gent055
		WHERE g55_user     = r_permiso.g05_usuario
		  AND g55_compania = vg_codcia
		  AND g55_proceso  = r_permiso.g54_proceso
	LET flag = 1
END FOREACH
RETURN flag

END FUNCTION



FUNCTION grabar_permisos_men()
DEFINE i, flag		SMALLINT
DEFINE modulo		LIKE gent050.g50_modulo

DELETE FROM gent057
	WHERE g57_user    IN (SELECT UNIQUE g53_usuario FROM tmp_permisos)
	  AND g57_proceso IN (SELECT g54_proceso FROM tmp_permisos)
LET flag = 0
FOR i = 1 TO vm_row_num
	IF rm_permisos[i].asignar_men = 'N' THEN
		CONTINUE FOR
	END IF
	INITIALIZE modulo TO NULL
	DECLARE q_modulo CURSOR FOR
		SELECT g54_modulo FROM gent054
			WHERE g54_proceso  = rm_permisos[i].g54_proceso
			  AND g54_estado  <> "B"
	OPEN q_modulo
	FETCH q_modulo INTO modulo
	INSERT INTO gent057
		VALUES(rm_permisos[i].g05_usuario, vg_codcia, modulo,
			rm_permisos[i].g54_proceso, vg_usuario, CURRENT)
	CLOSE q_modulo
	FREE q_modulo
	LET flag = 1
END FOR
RETURN flag

END FUNCTION



FUNCTION cargar_query_temp(col1, crit1, col2, crit2)
DEFINE col1		SMALLINT
DEFINE crit1		CHAR(4)
DEFINE col2		SMALLINT
DEFINE crit2		CHAR(4)
DEFINE query		VARCHAR(255)
DEFINE i		SMALLINT

LET query = 'SELECT * FROM tmp_permisos ',
	    ' 	ORDER BY ', col1, ' ', crit1, ', ', col2, ' ', crit2
PREPARE t1 FROM query
DECLARE q_t1 CURSOR FOR t1
LET i = 1
FOREACH q_t1 INTO rm_permisos[i].*
	LET i = i + 1
END FOREACH

END FUNCTION



FUNCTION buscar_check(c1, c2)
DEFINE c1, c2		CHAR(1)
DEFINE i, encont	SMALLINT

LET encont = 0
FOR i = 1 TO vm_row_num
	IF rm_permisos[i].asignar_pro = c1 OR rm_permisos[i].asignar_men = c2
	THEN
		LET encont = 1
		EXIT FOR
	END IF
END FOR
RETURN encont

END FUNCTION



FUNCTION chequear_todo_ninguno(flag)
DEFINE flag, i		SMALLINT
DEFINE palabra1		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE mensaje		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE asi_per		CHAR(1)

CASE flag
	WHEN 1
		LET asi_per  = 'S'
		LET palabra1 = 'Asignar'
		LET palabra2 = 'Asignado'
	WHEN 2
		LET asi_per  = 'N'
		LET palabra1 = 'Quitar'
		LET palabra2 = 'Retirado'
END CASE
LET mensaje = 'TODOS los Permisos.'
CALL fl_hacer_pregunta('Esta seguro de ' || palabra1 CLIPPED || ' ' || mensaje CLIPPED || ' ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 0
END IF
LET mensaje = palabra2 CLIPPED, mensaje
FOR i = 1 TO vm_row_num
	LET rm_permisos[i].asignar_pro = asi_per
	LET rm_permisos[i].asignar_men = asi_per
END FOR
LET i = 1
UPDATE tmp_permisos
	SET asignar_pro = asi_per,
	    asignar_men = asi_per
	WHERE 1 = 1
CALL limpiar_per()
CALL mostrar_per()
CALL fl_mostrar_mensaje(mensaje || ' Confirme presionando ACEPTAR.', 'info')
RETURN 1

END FUNCTION



FUNCTION limpiar_per()
DEFINE i, arr		SMALLINT

LET arr = fgl_scr_size('rm_permisos')
FOR i = 1 TO arr
	CLEAR rm_permisos[i].*
END FOR

END FUNCTION



FUNCTION mostrar_per()
DEFINE i, arr		SMALLINT

LET arr = fgl_scr_size('rm_permisos')
IF vm_row_num <= arr THEN
	LET arr = vm_row_num
END IF
FOR i = 1 TO arr
	DISPLAY rm_permisos[i].* TO rm_permisos[i].*
END FOR

END FUNCTION



FUNCTION ver_usuario(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES',
		vg_separador, 'fuentes', vg_separador, '; fglrun genp104 ',
		vg_base, ' ', vg_modulo, ' "', rm_permisos[i].g05_usuario, '"'
RUN comando

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION

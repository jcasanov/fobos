--------------------------------------------------------------------------------
-- Titulo           : repp235.4gl - Cambio de precios masivo
-- Elaboracion      : 06-Abr-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp235 base modulo compania [codigo] [flag]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r85   	RECORD LIKE rept085.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE r_det_arch	ARRAY[20000] OF RECORD
				r86_item	LIKE rept086.r86_item,
				nom_item	LIKE rept010.r10_nombre,
				r86_precio_mb	LIKE rept086.r86_precio_mb,
				r86_precio_nue	LIKE rept086.r86_precio_nue
			END RECORD
DEFINE r_det_nov	ARRAY[20000] OF RECORD
				r86_item	LIKE rept086.r86_item,
				nom_item	LIKE rept010.r10_nombre,
				comentarios	VARCHAR(30)
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE vm_row_current   SMALLINT        	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT		-- MAXIMO DE FILAS LEIDAS
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE novedades	VARCHAR(80)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp235.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 AND num_args() <> 5 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'repp235'
CALL fl_activar_base_datos(vg_base)
IF num_args() <> 3 THEN
	UPDATE gent054 SET g54_estado = 'A'
		WHERE g54_modulo  = vg_modulo
		  AND g54_proceso = vg_proceso
		  AND g54_estado  = 'R'
END IF
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
IF num_args() <> 3 THEN
	UPDATE gent054 SET g54_estado = 'R'
		WHERE g54_modulo  = vg_modulo
		  AND g54_proceso = vg_proceso
		  AND g54_estado  = 'A'
END IF
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_det = 20000
IF num_args() = 5 THEN
	CALL muestra_detalle()
	EXIT PROGRAM
END IF
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
OPEN WINDOW w_inventario AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf235_1 FROM '../forms/repf235_1'
ELSE
	OPEN FORM f_repf235_1 FROM '../forms/repf235_1c'
END IF
DISPLAY FORM f_repf235_1
INITIALIZE rm_r85.*, rm_vend.* TO NULL
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN qu_vd
FETCH qu_vd INTO rm_vend.*
CLOSE qu_vd
FREE qu_vd
DECLARE q_r85 CURSOR FOR
	SELECT * FROM rept085
		WHERE r85_compania   = vg_codcia
		  AND r85_tipo_carga = 'C'
OPEN q_r85
FETCH q_r85 INTO rm_r85.*
CLOSE q_r85
FREE q_r85
LET vm_max_rows    = 1000
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Reversar'
		HIDE OPTION 'Detalle Items'
		IF rm_r85.r85_compania IS NOT NULL AND
		  (rm_g05.g05_tipo <> 'UF' AND (rm_vend.r01_tipo = 'J' OR
		   rm_vend.r01_tipo = 'G'))
		THEN
			IF rm_r85.r85_tipo_carga = 'C' THEN
				SHOW OPTION 'Aprobar Archivo'
			ELSE
				HIDE OPTION 'Aprobar Archivo'
			END IF
		ELSE
			HIDE OPTION 'Aprobar Archivo'
		END IF
		IF num_args() <> 3 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Cargar Archivo'
			HIDE OPTION 'Consultar'
			IF num_args() = 4 THEN
				CALL control_consulta()
				SHOW OPTION 'Detalle Items'
			END IF
		END IF
	COMMAND KEY('P') 'Cargar Archivo' 'Cambiar precios desde un archivo.'
		CALL control_cargar_archivo(2)
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Reversar'
			SHOW OPTION 'Detalle Items'
		END IF
		IF rm_r85.r85_compania IS NOT NULL AND
		  (rm_g05.g05_tipo <> 'UF' AND (rm_vend.r01_tipo = 'J' OR
		   rm_vend.r01_tipo = 'G'))
		THEN
			IF rm_r85.r85_tipo_carga = 'C' THEN
				SHOW OPTION 'Aprobar Archivo'
			ELSE
				HIDE OPTION 'Aprobar Archivo'
			END IF
		ELSE
			HIDE OPTION 'Aprobar Archivo'
		END IF
	COMMAND KEY('F') 'Aprobar Archivo' 'Aprueba/Procesa archivo.'
		CALL control_cargar_archivo(3)
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Reversar'
			SHOW OPTION 'Detalle Items'
		END IF
	COMMAND KEY('I') 'Ingresar' 'Cambiar precios por parametros.'
		CALL control_ingreso(1)
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Reversar'
			SHOW OPTION 'Detalle Items'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Reversar'
			SHOW OPTION 'Detalle Items'
			IF rm_r85.r85_compania IS NOT NULL AND
			  (rm_g05.g05_tipo <> 'UF' AND (rm_vend.r01_tipo = 'J' OR
			   rm_vend.r01_tipo = 'G'))
			THEN
				IF rm_r85.r85_tipo_carga = 'C' THEN
					SHOW OPTION 'Aprobar Archivo'
				ELSE
					HIDE OPTION 'Aprobar Archivo'
				END IF
			ELSE
				HIDE OPTION 'Aprobar Archivo'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Reversar'
				HIDE OPTION 'Detalle Items'
				IF rm_r85.r85_compania IS NOT NULL AND
				  (rm_g05.g05_tipo <> 'UF' AND (				   rm_vend.r01_tipo = 'J'  OR
				   rm_vend.r01_tipo = 'G'))
				THEN
					IF rm_r85.r85_tipo_carga = 'C' THEN
						SHOW OPTION 'Aprobar Archivo'
					ELSE
						HIDE OPTION 'Aprobar Archivo'
					END IF
				ELSE
					HIDE OPTION 'Aprobar Archivo'
				END IF
			END IF
		ELSE
			SHOW OPTION 'Reversar'
			SHOW OPTION 'Detalle Items'
			IF rm_r85.r85_compania IS NOT NULL AND
			  (rm_g05.g05_tipo <> 'UF' AND (rm_vend.r01_tipo = 'J' OR
			   rm_vend.r01_tipo = 'G'))
			THEN
				IF rm_r85.r85_tipo_carga = 'C' THEN
					SHOW OPTION 'Aprobar Archivo'
				ELSE
					HIDE OPTION 'Aprobar Archivo'
				END IF
			ELSE
				HIDE OPTION 'Aprobar Archivo'
			END IF
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('E') 'Reversar' 'Reversa el registro corriente. '
		CALL control_reversar()
	COMMAND KEY('D') 'Detalle Items' 'Muestra detalle de Items. '
		CALL muestra_detalle()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL control_muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL control_muestra_anterior_registro()
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



FUNCTION control_cargar_archivo(tipo_proc)
DEFINE tipo_proc	SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE flag, elimino 	SMALLINT
DEFINE cuantos		INTEGER
DEFINE archivo		VARCHAR(255)

IF tipo_proc = 2 THEN
	SELECT COUNT(*) INTO cuantos
		FROM rept085
		WHERE r85_compania   = vg_codcia
		  AND r85_tipo_carga = 'C'
	IF cuantos > 0 THEN
		CALL fl_mostrar_mensaje('No puede cargar otro archivo de precios mientras exista otro archivo cargado y no este APROBADO/PROCESADO.', 'info')
		RETURN
	END IF
	IF NOT cargar_datos_arch() THEN
		RETURN
	END IF
ELSE
	SELECT r86_item item, r10_nombre descripcion, r86_precio_mb precio_act,
		r86_precio_nue precio_nue
		FROM rept085, rept086, rept010
		WHERE r85_compania   = vg_codcia
		  AND r85_codigo     = rm_r85.r85_codigo
		  AND r85_tipo_carga = "C"
		  AND r86_compania   = r85_compania
		  AND r86_codigo     = r85_codigo
		  AND r10_compania   = r86_compania
		  AND r10_codigo     = r86_item
		INTO TEMP tmp_det_arch
	SELECT COUNT(*) INTO cuantos FROM tmp_det_arch
	IF cuantos = 0 THEN
		DROP TABLE tmp_det_arch
		CALL fl_mostrar_mensaje('No existe ningun archivo pendiente de carga.', 'exclamation')
		RETURN
	END IF
END IF
LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 20
LET num_cols = 74
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repf235_3 AT row_ini, 04 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_repf235_3 FROM '../forms/repf235_3'
ELSE
	OPEN FORM f_repf235_3 FROM '../forms/repf235_3c'
END IF
DISPLAY FORM f_repf235_3
LET vm_num_det = 0
CALL mostrar_botones_detalle2()
CALL borrar_detalle_arch()
CALL muestra_detalle_arch(tipo_proc) RETURNING elimino
IF elimino THEN
	DROP TABLE tmp_det_arch
	LET int_flag = 0
	RETURN
END IF
LET flag = int_flag
CALL borrar_detalle_arch()
CLOSE WINDOW w_repf235_3
IF flag THEN
	DROP TABLE tmp_det_arch
	LET int_flag = 0
	RETURN
END IF
CALL control_ingreso(tipo_proc)
IF tipo_proc = 2 THEN
	LET archivo = '$HOME/PRECIOS/precios_', vg_usuario CLIPPED, '_',
			TODAY USING "yyyy-mm-dd", '_', TIME, '.csv'
	LET archivo = 'mv -f precios.csv ', archivo CLIPPED
	RUN archivo
ELSE
	DROP TABLE tmp_det_arch
END IF
RUN 'rm -rf precios.csv '

END FUNCTION



FUNCTION cargar_datos_arch()
DEFINE query		CHAR(800)
DEFINE cuantos		INTEGER
DEFINE otras		SMALLINT
DEFINE mensaje		VARCHAR(200)

SELECT r10_codigo item, r10_precio_mb precio_nue
	FROM rept010
	WHERE r10_compania = 999
	INTO TEMP t1
RUN 'mv -f $HOME/tmp/precios.csv .'
RUN 'dos2unix precios.csv'
WHENEVER ERROR CONTINUE
LOAD FROM "precios.csv" DELIMITER "," INSERT INTO t1
IF STATUS = 846 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No se puede cargar el archivo porque falta el item o el precio en alguna linea del archivo.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF STATUS = 847 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No se puede cargar el archivo porque uno de los registros tiene una COMA en vez del PUNTO DECIMAL.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF STATUS = -805 THEN
	DROP TABLE t1
	LET mensaje = 'No se puede cargar el archivo porque no existe en la ',
			'ruta: ', FGL_GETENV("HOME") CLIPPED, '/tmp/.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF STATUS <> 0 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No se puede cargar el archivo porque ha ocurrido un error. LLAME AL ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
SELECT COUNT(*) INTO vm_num_det FROM t1
IF vm_num_det = 0 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No se puede cargar el archivo porque esta vacio.', 'exclamation')
	RETURN 0
END IF
SELECT item, r10_nombre descripcion, r10_precio_mb precio_act, precio_nue
	FROM t1, rept010
	WHERE r10_compania = vg_codcia
	  AND r10_codigo   = item
	INTO TEMP tmp_det_arch
SELECT * FROM t1
	WHERE NOT EXISTS
		(SELECT 1 FROM rept010
			WHERE r10_compania = vg_codcia
			  AND r10_codigo   = item)
	INTO TEMP tmp_fal
DROP TABLE t1
SELECT item, descripcion, "ITEM CON ESTADO BLOQUEADO" comentario
	FROM tmp_det_arch, rept010
	WHERE r10_compania = vg_codcia
	  AND r10_codigo   = item
	  AND r10_estado   = "B"
	INTO TEMP tmp_nov
SELECT COUNT(*) INTO cuantos FROM tmp_nov
LET novedades = NULL
IF cuantos > 0 THEN
	LET novedades = 'EXISTEN ITEMS CON ESTADO BLOQUEADO'
END IF
SELECT item, COUNT(*) ctos
	FROM tmp_det_arch
	GROUP BY 1
	HAVING COUNT(*) > 1
	INTO TEMP t1
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos > 0 THEN
	IF novedades IS NULL THEN
		LET novedades = 'EXISTEN ITEMS REPETIDOS'
	ELSE
		LET novedades = novedades CLIPPED, ' Y TAMBIEN REPETIDO'
	END IF
	LET query = 'INSERT INTO tmp_nov ',
		'SELECT UNIQUE item, descripcion, ',
			'(SELECT "ITEM ESTA REPETIDO: " || t1.ctos FROM t1 ',
			'WHERE t1.item = tmp_det_arch.item) comentario ',
		'FROM tmp_det_arch ',
		'WHERE item IN (SELECT item FROM t1) '
	PREPARE exec_nov1 FROM query
	EXECUTE exec_nov1
END IF
DROP TABLE t1
LET query = ' SELECT item, descripcion, ',
			'CASE WHEN precio_nue IS NULL ',
				'THEN "ITEM SIN PRECIO" ',
				'ELSE "ITEM CON PRECIO CERO" ',
			'END comentario ',
		'FROM tmp_det_arch ',
		'WHERE precio_nue IS NULL ',
		'   OR precio_nue <= 0 ',
		'INTO TEMP t1'
PREPARE exec_nov2 FROM query
EXECUTE exec_nov2
SELECT COUNT(*) INTO cuantos FROM t1
LET otras = 0
IF cuantos > 0 THEN
	IF novedades IS NULL THEN
		LET novedades = 'EXISTEN ITEMS SIN LA COLUMNA PRECIOS'
	ELSE
		LET novedades = novedades CLIPPED, '. OTRAS NOVEDADES'
		LET otras     = 1
	END IF
	INSERT INTO tmp_nov SELECT * FROM t1
END IF
DROP TABLE t1
SELECT COUNT(*) INTO cuantos FROM tmp_fal
IF cuantos > 0 THEN
	IF novedades IS NULL THEN
		LET novedades = 'ESTOS ITEMS NO EXISTEN EN LA BASE'
	END IF
	IF NOT otras THEN
		LET novedades = novedades CLIPPED, '. OTRAS NOVEDADES'
	END IF
	INSERT INTO tmp_nov
		SELECT item, "N/A" descripcion, "ITEM NO EXISTE" comentario
			FROM tmp_fal
END IF
SELECT COUNT(*) INTO cuantos FROM tmp_nov
DROP TABLE tmp_fal
IF cuantos > 0 THEN
	DROP TABLE tmp_det_arch
	CALL control_cargar_novedades()
	RETURN 0
END IF
DROP TABLE tmp_nov
RETURN 1

END FUNCTION



FUNCTION borrar_detalle_arch()
DEFINE i		SMALLINT

LET vm_num_det = 0
FOR i = 1 TO fgl_scr_size("r_det_arch")
	CLEAR r_det_arch[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE r_det_arch[i].* TO NULL
END FOR

END FUNCTION



FUNCTION muestra_detalle_arch(tipo_proc)
DEFINE tipo_proc	SMALLINT
DEFINE i, j, col, salir	SMALLINT
DEFINE elimino		SMALLINT
DEFINE resp		CHAR(6)
DEFINE query		CHAR(400)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE precio		LIKE rept010.r10_precio_mb

LET col           = 1
LET rm_orden[col] = 'ASC'
LET vm_columna_1  = col
LET vm_columna_2  = 4
LET elimino       = 0
WHILE TRUE
	LET query = 'SELECT * FROM tmp_det_arch ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det2 FROM query
	DECLARE q_det2 CURSOR FOR det2
	LET vm_num_det = 1
        FOREACH q_det2 INTO r_det_arch[vm_num_det].*
                LET vm_num_det = vm_num_det + 1
                IF vm_num_det > vm_max_det THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_num_det = vm_num_det - 1
	LET salir    = 0
	LET int_flag = 0
	CALL set_count(vm_num_det)
	INPUT ARRAY r_det_arch WITHOUT DEFAULTS FROM r_det_arch.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag   = 1
				EXIT INPUT
			END IF
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_item(r_det_arch[i].r86_item)
			LET int_flag = 0
		ON KEY(F6)
			IF tipo_proc = 3 THEN
				IF NOT eliminar_carga() THEN
					CONTINUE INPUT
				END IF
				LET elimino  = 1
				LET salir    = 1
				LET int_flag = 0
				EXIT INPUT
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
		--#BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
			--#IF tipo_proc = 3 THEN
				--#CALL dialog.keysetlabel("F6","Eliminar Carga")
			--#ELSE
				--#CALL dialog.keysetlabel("F6","")
			--#END IF
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#DISPLAY i TO cur_row
			--#DISPLAY vm_num_det TO max_row
			--#CALL fl_lee_item(vg_codcia, r_det_arch[i].r86_item)
				--#RETURNING r_r10.*
			--#DISPLAY BY NAME r_r10.r10_nombre
			--#CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
						--#r_r10.r10_sub_linea,
						--#r_r10.r10_cod_grupo,
						--#r_r10.r10_cod_clase)
				--#RETURNING r_r72.*
			--#DISPLAY BY NAME r_r10.r10_marca
			--#DISPLAY BY NAME r_r72.r72_desc_clase
		BEFORE DELETE
			--#CANCEL DELETE
		BEFORE INSERT
			--#CANCEL INSERT
		BEFORE FIELD r86_precio_nue
			LET precio = r_det_arch[i].r86_precio_nue
		AFTER FIELD r86_precio_nue
			LET r_det_arch[i].r86_precio_nue = precio
			DISPLAY r_det_arch[i].r86_precio_nue TO
				r_det_arch[j].r86_precio_nue
		AFTER INPUT
			LET salir = 1
	END INPUT
	IF int_flag = 1 OR salir THEN
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
RETURN elimino

END FUNCTION



FUNCTION mostrar_botones_detalle2()

--#DISPLAY "Item"			TO tit_col1
--#DISPLAY "Descripcion"		TO tit_col2
--#DISPLAY "Precio Actual"		TO tit_col3
--#DISPLAY "Precio Nuevo"		TO tit_col4

END FUNCTION



FUNCTION control_ingreso(flag)
DEFINE flag		SMALLINT
DEFINE cuantos		INTEGER
DEFINE num_aux		INTEGER
DEFINE mensaje		VARCHAR(100)

INITIALIZE rm_r85.* TO NULL
IF flag <> 3 THEN
	CLEAR FORM
	OPTIONS INPUT WRAP
	LET rm_r85.r85_compania    = vg_codcia
	LET rm_r85.r85_fec_camprec = TODAY
	LET rm_r85.r85_estado      = 'A'
	CASE flag
		WHEN 1 LET rm_r85.r85_tipo_carga = 'N'
		WHEN 2 LET rm_r85.r85_tipo_carga = 'C'
	END CASE
	LET rm_r85.r85_precio_nue  = 0
	LET rm_r85.r85_porc_aum    = 0
	LET rm_r85.r85_porc_dec    = 0
	LET rm_r85.r85_usuario     = vg_usuario
	LET rm_r85.r85_fecing      = CURRENT
	DISPLAY BY NAME rm_r85.r85_fec_camprec, rm_r85.r85_estado,
			rm_r85.r85_precio_nue, rm_r85.r85_porc_aum,
			rm_r85.r85_porc_dec, rm_r85.r85_fecing,
			rm_r85.r85_usuario
	CALL muestra_estado()
	CALL muestra_tipo_carga()
	CASE flag
		WHEN 1  CALL leer_parametros()
		WHEN 2  LET rm_r85.r85_referencia = 'POR CARGA DE ARCHIVO'
			DISPLAY BY NAME rm_r85.r85_referencia
			LET int_flag = 0
	END CASE
ELSE
	LET int_flag = 0
END IF
IF NOT int_flag THEN
	BEGIN WORK
		IF flag = 3 THEN
			WHENEVER ERROR CONTINUE
			DECLARE q_up CURSOR FOR
				SELECT * FROM rept085
					WHERE r85_compania   = vg_codcia
					  AND r85_tipo_carga = "C"
				FOR UPDATE
			OPEN q_up
			FETCH q_up INTO rm_r85.*
			IF STATUS < 0 THEN
				ROLLBACK WORK
				CALL fl_mensaje_bloqueo_otro_usuario()
				WHENEVER ERROR STOP
				RETURN
			END IF
			IF STATUS = NOTFOUND THEN
				ROLLBACK WORK
				CALL fl_mostrar_mensaje('Ha ocurrido un ERROR: No existe el registro de carga del arhivo de precios. Llame al ADMINISTRADOR', 'stop')
				WHENEVER ERROR STOP
				RETURN
			END IF
		END IF
		IF NOT cambia_precios_items_masivos(flag) THEN
			DROP TABLE tmp_prec1
			ROLLBACK WORK
			CLEAR FORM
			IF vm_num_rows > 0 THEN
				CALL lee_muestra_registro(
						vm_r_rows[vm_row_current])
			END IF
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			RETURN
		END IF
		IF flag <> 3 THEN
			SELECT NVL(MAX(r85_codigo), 0) + 1
				INTO rm_r85.r85_codigo
				FROM rept085
				WHERE r85_compania = rm_r85.r85_compania
			LET rm_r85.r85_fecing = CURRENT
        		INSERT INTO rept085 VALUES (rm_r85.*)
			LET num_aux = SQLCA.SQLERRD[6] 
			CALL genera_detalle()
        		IF vm_num_rows = vm_max_rows THEN
	        	        LET vm_num_rows = 1
		        ELSE
		                LET vm_num_rows = vm_num_rows + 1
	        	END IF
			LET vm_r_rows[vm_num_rows] = num_aux
			LET vm_row_current = vm_num_rows
		ELSE
			LET rm_r85.r85_tipo_carga = 'P'
			WHENEVER ERROR CONTINUE
			UPDATE rept085
				SET r85_tipo_carga = rm_r85.r85_tipo_carga
				WHERE CURRENT OF q_up
			IF STATUS < 0 THEN
				ROLLBACK WORK
				CALL fl_mostrar_mensaje('No se ha podido actualizar el tipo de carga del archivo.', 'exclamation')
				WHENEVER ERROR STOP
				RETURN
			END IF
		END IF
	WHENEVER ERROR STOP
	COMMIT WORK
	SELECT COUNT(*) INTO cuantos FROM tmp_prec1
	DROP TABLE tmp_prec1
	IF flag <> 2 THEN
		LET mensaje = 'Se actualizaron precios de ',
				cuantos USING "<<<<&", ' Items.'
	ELSE
		LET mensaje = 'Archivo de precios cargado OK.'
	END IF
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE capitulo		LIKE gent016.g16_capitulo
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r77		RECORD LIKE rept077.*

CLEAR FORM
IF num_args() <> 4 THEN
	INITIALIZE capitulo TO NULL
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r85_codigo, r85_fec_camprec, r85_estado,
		r85_tipo_carga, r85_referencia, r85_division, r85_linea,
		r85_cod_grupo, r85_cod_clase, r85_marca, r85_cod_util,
		r85_partida, r85_precio_nue, r85_porc_aum, r85_porc_dec,
		r85_usuario, r85_fecing, r85_usu_reversa, r85_fec_reversa
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r85_division) THEN
				CALL fl_ayuda_lineas_rep(vg_codcia)
					RETURNING r_r03.r03_codigo,
						  r_r03.r03_nombre
				IF r_r03.r03_codigo IS NOT NULL THEN
					LET rm_r85.r85_division=r_r03.r03_codigo
					DISPLAY BY NAME rm_r85.r85_division,
							r_r03.r03_nombre
				END IF
			END IF
			IF INFIELD(r85_linea) THEN
				CALL fl_ayuda_sublinea_rep(vg_codcia,
							rm_r85.r85_division)
					RETURNING r_r70.r70_sub_linea,
						  r_r70.r70_desc_sub
				IF r_r70.r70_sub_linea IS NOT NULL THEN
					LET rm_r85.r85_linea=r_r70.r70_sub_linea
					DISPLAY BY NAME rm_r85.r85_linea,
							r_r70.r70_desc_sub
				END IF
			END IF
			IF INFIELD(r85_cod_grupo) THEN
				CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
							rm_r85.r85_division,
							rm_r85.r85_linea)
		     		RETURNING r_r71.r71_cod_grupo,
		     			  r_r71.r71_desc_grupo
				IF r_r71.r71_cod_grupo IS NOT NULL THEN
					LET rm_r85.r85_cod_grupo =
							r_r71.r71_cod_grupo
					DISPLAY BY NAME rm_r85.r85_cod_grupo,
							r_r71.r71_desc_grupo
				END IF
			END IF
			IF INFIELD(r85_cod_clase) THEN
				CALL fl_ayuda_clase_ventas_rep(vg_codcia,
							rm_r85.r85_division,
							rm_r85.r85_linea,
							rm_r85.r85_cod_grupo)
					RETURNING r_r72.r72_cod_clase,
				     		  r_r72.r72_desc_clase
				IF r_r72.r72_cod_clase IS NOT NULL THEN
					LET rm_r85.r85_cod_clase =
							r_r72.r72_cod_clase
					DISPLAY BY NAME rm_r85.r85_cod_clase,
							r_r72.r72_desc_clase
				END IF
			END IF
			IF INFIELD(r85_marca) THEN
				CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, 
							rm_r85.r85_marca)
		  			RETURNING r_r73.r73_marca
				IF r_r73.r73_marca IS NOT NULL THEN
					LET rm_r85.r85_marca = r_r73.r73_marca
					CALL fl_lee_marca_rep(vg_codcia,
							rm_r85.r85_marca)
						RETURNING r_r73.*
					DISPLAY BY NAME rm_r85.r85_marca,
							r_r73.r73_desc_marca
		   		END IF
			END IF
			IF INFIELD(r85_cod_util) THEN
				CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
			     		RETURNING r_r77.r77_codigo_util
			     	IF r_r77.r77_codigo_util IS NOT NULL THEN
					LET rm_r85.r85_cod_util =
							r_r77.r77_codigo_util
					DISPLAY BY NAME rm_r85.r85_cod_util
			     	END IF
			END IF
			IF INFIELD(r85_partida) THEN
				CALL fl_ayuda_partidas(capitulo)
					RETURNING r_g16.g16_partida
				IF r_g16.g16_partida IS NOT NULL THEN
					LET rm_r85.r85_partida=r_g16.g16_partida
					DISPLAY BY NAME rm_r85.r85_partida
				END IF
			END IF
	                LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		END IF
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		RETURN
	END IF
ELSE
	LET expr_sql = ' r85_codigo   = ', arg_val(4)
END IF
LET query = 'SELECT *, ROWID FROM rept085 ',
		'WHERE r85_compania = ', vg_codcia,
		'  AND ', expr_sql CLIPPED,
		' ORDER BY r85_fec_camprec, r85_codigo'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_r85.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 4 THEN
		EXIT PROGRAM
	END IF
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION leer_parametros()
DEFINE resp		CHAR(6)
DEFINE flag		CHAR(1)
DEFINE capitulo		LIKE gent016.g16_capitulo
DEFINE precio_nue	LIKE rept085.r85_precio_nue
DEFINE porc_aum		LIKE rept085.r85_porc_aum
DEFINE porc_dec		LIKE rept085.r85_porc_dec
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_r77		RECORD LIKE rept077.*

INITIALIZE capitulo TO NULL
LET int_flag = 0
INPUT BY NAME rm_r85.r85_referencia, rm_r85.r85_division, rm_r85.r85_linea,
	rm_r85.r85_cod_grupo, rm_r85.r85_cod_clase, rm_r85.r85_marca,
	rm_r85.r85_cod_util, rm_r85.r85_partida, rm_r85.r85_precio_nue,
	rm_r85.r85_porc_aum, rm_r85.r85_porc_dec
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_r85.r85_referencia, rm_r85.r85_division,
				 rm_r85.r85_linea, rm_r85.r85_cod_grupo,
				 rm_r85.r85_cod_clase, rm_r85.r85_marca,
				 rm_r85.r85_cod_util, rm_r85.r85_partida,
				 rm_r85.r85_precio_nue, rm_r85.r85_porc_aum,
				 rm_r85.r85_porc_dec)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				CLEAR FORM
				LET int_flag = 1
				--#RETURN
				EXIT INPUT
			END IF
		ELSE
			CLEAR FORM
			--#RETURN
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r85_division) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING r_r03.r03_codigo, r_r03.r03_nombre
			IF r_r03.r03_codigo IS NOT NULL THEN
				LET rm_r85.r85_division = r_r03.r03_codigo
				DISPLAY BY NAME rm_r85.r85_division,
						r_r03.r03_nombre
			END IF
		END IF
		IF INFIELD(r85_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia,
							rm_r85.r85_division)
				RETURNING r_r70.r70_sub_linea,
					  r_r70.r70_desc_sub
			IF r_r70.r70_sub_linea IS NOT NULL THEN
				LET rm_r85.r85_linea = r_r70.r70_sub_linea
				DISPLAY BY NAME rm_r85.r85_linea,
						r_r70.r70_desc_sub
			END IF
		END IF
		IF INFIELD(r85_cod_grupo) THEN
			CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
							rm_r85.r85_division,
							rm_r85.r85_linea)
		     		RETURNING r_r71.r71_cod_grupo,
		     			  r_r71.r71_desc_grupo
			IF r_r71.r71_cod_grupo IS NOT NULL THEN
				LET rm_r85.r85_cod_grupo = r_r71.r71_cod_grupo
				DISPLAY BY NAME rm_r85.r85_cod_grupo,
						r_r71.r71_desc_grupo
			END IF
		END IF
		IF INFIELD(r85_cod_clase) THEN
			CALL fl_ayuda_clase_ventas_rep(vg_codcia,
							rm_r85.r85_division,
							rm_r85.r85_linea,
							rm_r85.r85_cod_grupo)
				RETURNING r_r72.r72_cod_clase,
			     		  r_r72.r72_desc_clase
			IF r_r72.r72_cod_clase IS NOT NULL THEN
				LET rm_r85.r85_cod_clase = r_r72.r72_cod_clase
				DISPLAY BY NAME rm_r85.r85_cod_clase,
						r_r72.r72_desc_clase
			END IF
		END IF
		IF INFIELD(r85_marca) THEN
			CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, 
							rm_r85.r85_marca)
	  			RETURNING r_r73.r73_marca
			IF r_r73.r73_marca IS NOT NULL THEN
				LET rm_r85.r85_marca = r_r73.r73_marca
				CALL fl_lee_marca_rep(vg_codcia,
							rm_r85.r85_marca)
					RETURNING r_r73.*
				DISPLAY BY NAME rm_r85.r85_marca,
						r_r73.r73_desc_marca
	   		END IF
		END IF
		IF INFIELD(r85_cod_util) THEN
			CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
		     		RETURNING r_r77.r77_codigo_util
		     	IF r_r77.r77_codigo_util IS NOT NULL THEN
				LET rm_r85.r85_cod_util = r_r77.r77_codigo_util
				DISPLAY BY NAME rm_r85.r85_cod_util
		     	END IF
		END IF
		IF INFIELD(r85_partida) THEN
			CALL fl_ayuda_partidas(capitulo)
				RETURNING r_g16.g16_partida
			IF r_g16.g16_partida IS NOT NULL THEN
				LET rm_r85.r85_partida = r_g16.g16_partida
				DISPLAY BY NAME rm_r85.r85_partida
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r85_precio_nue
		LET precio_nue = rm_r85.r85_precio_nue
	BEFORE FIELD r85_porc_aum
		LET porc_aum = rm_r85.r85_porc_aum
	BEFORE FIELD r85_porc_dec
		LET porc_dec = rm_r85.r85_porc_dec
	AFTER FIELD r85_division
		IF rm_r85.r85_division IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_r85.r85_division)
				RETURNING r_r03.*
			IF r_r03.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Division no existe.','exclamation')
				NEXT FIELD r85_division
			END IF
			DISPLAY BY NAME r_r03.r03_nombre
			IF r_r03.r03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r85_division
			END IF
		ELSE
			CLEAR r03_nombre
		END IF
	AFTER FIELD r85_linea
		IF rm_r85.r85_linea IS NOT NULL THEN
			CALL fl_retorna_sublinea_rep(vg_codcia,rm_r85.r85_linea)
				RETURNING r_r70.*, flag
			IF flag = 0 THEN
				IF r_r70.r70_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Linea no existe.','exclamation')
					NEXT FIELD r85_linea
				END IF
			END IF
			DISPLAY BY NAME r_r70.r70_desc_sub
		ELSE 
		     	CLEAR r70_desc_sub
                END IF
	AFTER FIELD r85_cod_grupo
                IF rm_r85.r85_cod_grupo IS NOT NULL THEN
			CALL fl_retorna_grupo_rep(vg_codcia,
							rm_r85.r85_cod_grupo)
				RETURNING r_r71.*, flag
			IF flag = 0 THEN
				IF r_r71.r71_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
					NEXT FIELD r85_cod_grupo
				END IF
			END IF
			DISPLAY BY NAME r_r71.r71_desc_grupo
		ELSE 
		     	CLEAR r71_desc_grupo
                END IF
	AFTER FIELD r85_cod_clase
                IF rm_r85.r85_cod_clase IS NOT NULL THEN
			CALL fl_retorna_clase_rep(vg_codcia,
							rm_r85.r85_cod_clase)
				RETURNING r_r72.*, flag
			IF flag = 0 THEN
				IF r_r72.r72_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Clase no existe.','exclamation')
					NEXT FIELD r85_cod_clase
				END IF
			END IF
			DISPLAY BY NAME r_r72.r72_desc_clase
		ELSE 
		     	CLEAR r72_desc_clase
                END IF
	AFTER FIELD r85_marca 
		IF rm_r85.r85_marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_r85.r85_marca)
				RETURNING r_r73.*
			IF r_r73.r73_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Marca no existe.','exclamation')
				NEXT FIELD r85_marca
			END IF
			DISPLAY BY NAME r_r73.r73_desc_marca
		ELSE
			CLEAR r73_desc_marca
		END IF
	AFTER FIELD r85_partida
		IF rm_r85.r85_partida IS NOT NULL THEN
			CALL fl_lee_partida(rm_r85.r85_partida)
				RETURNING r_g16.*
			IF r_g16.g16_partida IS NULL THEN
				CALL fl_mostrar_mensaje('Partida no existe.','exclamation')
				NEXT FIELD r85_partida
			END IF
		ELSE
			CLEAR r85_partida
		END IF
	AFTER FIELD r85_precio_nue
		IF rm_r85.r85_precio_nue IS NULL THEN
			LET rm_r85.r85_precio_nue = precio_nue
		END IF
		IF rm_r85.r85_porc_aum > 0 OR rm_r85.r85_porc_dec > 0 THEN
			LET rm_r85.r85_precio_nue = 0
		END IF
		DISPLAY BY NAME rm_r85.r85_precio_nue
	AFTER FIELD r85_porc_aum
		IF rm_r85.r85_porc_aum IS NULL THEN
			LET rm_r85.r85_porc_aum = porc_aum
		END IF
		IF rm_r85.r85_precio_nue > 0 OR rm_r85.r85_porc_dec > 0 THEN
			LET rm_r85.r85_porc_aum = 0
		END IF
		DISPLAY BY NAME rm_r85.r85_porc_aum
	AFTER FIELD r85_porc_dec
		IF rm_r85.r85_porc_dec IS NULL THEN
			LET rm_r85.r85_porc_dec = porc_dec
		END IF
		IF rm_r85.r85_precio_nue > 0 OR rm_r85.r85_porc_aum > 0 THEN
			LET rm_r85.r85_porc_dec = 0
		END IF
		DISPLAY BY NAME rm_r85.r85_porc_dec
	AFTER INPUT
		IF rm_r85.r85_precio_nue = 0 AND rm_r85.r85_porc_aum = 0 AND
		   rm_r85.r85_porc_dec = 0 THEN
			CALL fl_mostrar_mensaje('Al menos uno de los parametros de Precio Nuevo, Porc. Aumento o Porc. Decremento deben ser mayor a Cero.', 'exclamation')
			NEXT FIELD r85_precio_nue
		END IF
END INPUT
IF NOT int_flag THEN
	ERROR 'Generando Items para cambio precio . . . espere por favor'
		ATTRIBUTE(NORMAL)
END IF

END FUNCTION



FUNCTION control_muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r85.* FROM rept085 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con Indice: ' || num_row,
				'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_r85.r85_codigo, rm_r85.r85_fec_camprec,rm_r85.r85_referencia,
		rm_r85.r85_division, rm_r85.r85_linea, rm_r85.r85_cod_grupo,
		rm_r85.r85_cod_clase, rm_r85.r85_marca, rm_r85.r85_cod_util,
		rm_r85.r85_partida, rm_r85.r85_precio_nue, rm_r85.r85_porc_aum,
		rm_r85.r85_porc_dec, rm_r85.r85_usu_reversa,
		rm_r85.r85_fec_reversa, rm_r85.r85_usuario, rm_r85.r85_fecing
CALL fl_lee_linea_rep(vg_codcia, rm_r85.r85_division) RETURNING r_r03.*
DISPLAY BY NAME r_r03.r03_nombre
CALL fl_lee_sublinea_rep(vg_codcia, rm_r85.r85_division, rm_r85.r85_linea)
		RETURNING r_r70.*
DISPLAY BY NAME r_r70.r70_desc_sub
CALL fl_lee_grupo_rep(vg_codcia, rm_r85.r85_division, rm_r85.r85_linea,
				rm_r85.r85_cod_grupo)
		RETURNING r_r71.*
DISPLAY BY NAME r_r71.r71_desc_grupo
CALL fl_lee_clase_rep(vg_codcia, rm_r85.r85_division, rm_r85.r85_linea,
				rm_r85.r85_cod_grupo, rm_r85.r85_cod_clase)
		RETURNING r_r72.*
DISPLAY BY NAME r_r72.r72_desc_clase
CALL fl_lee_marca_rep(vg_codcia, rm_r85.r85_marca) RETURNING r_r73.*
DISPLAY BY NAME r_r73.r73_desc_marca
CALL muestra_estado()
CALL muestra_tipo_carga()

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 18
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION cambia_precios_items_masivos(flag)
DEFINE flag		SMALLINT
DEFINE cuantos		INTEGER
DEFINE mensaje		VARCHAR(100)
DEFINE expr_div		VARCHAR(100)
DEFINE expr_lin		VARCHAR(100)
DEFINE expr_grp		VARCHAR(100)
DEFINE expr_cla		VARCHAR(100)
DEFINE expr_mar		VARCHAR(100)
DEFINE expr_par		VARCHAR(100)
DEFINE expr_uti		VARCHAR(100)
DEFINE query		CHAR(1200)

LET expr_div = NULL
IF rm_r85.r85_division IS NOT NULL THEN
	LET expr_div = '   AND r10_linea     = "', rm_r85.r85_division CLIPPED,
						'"'
END IF
LET expr_lin = NULL
IF rm_r85.r85_linea IS NOT NULL THEN
	LET expr_lin = '   AND r10_sub_linea = "', rm_r85.r85_linea CLIPPED, '"'
END IF
LET expr_grp = NULL
IF rm_r85.r85_cod_grupo IS NOT NULL THEN
	LET expr_grp = '   AND r10_cod_grupo = "', rm_r85.r85_cod_grupo CLIPPED,
						 '"'
END IF
LET expr_cla = NULL
IF rm_r85.r85_cod_clase IS NOT NULL THEN
	LET expr_cla = '   AND r10_cod_clase = "', rm_r85.r85_cod_clase CLIPPED,
						 '"'
END IF
LET expr_mar = NULL
IF rm_r85.r85_marca IS NOT NULL THEN
	LET expr_mar = '   AND r10_marca     = "', rm_r85.r85_marca CLIPPED, '"'
END IF
LET expr_uti = NULL
IF rm_r85.r85_cod_util IS NOT NULL THEN
	LET expr_uti = '   AND r10_cod_util  = "', rm_r85.r85_cod_util CLIPPED,
						'"'
END IF
LET expr_par = NULL
IF rm_r85.r85_partida IS NOT NULL THEN
	LET expr_par = '   AND r10_partida   = "', rm_r85.r85_partida CLIPPED,
						'"'
END IF
CASE flag
	WHEN 1
		LET query = 'SELECT r10_codigo item, r10_precio_mb precio_n, ',
			'r10_precio_ant precio_a, r10_fec_camprec fecha_p, ',
			'r10_precio_mb precio_c, "N" revers ',
			' FROM rept010 ',
			' WHERE r10_compania  = ', vg_codcia,
			'   AND r10_estado    = "A" ',
				expr_par CLIPPED,
				expr_uti CLIPPED,
				expr_div CLIPPED,
				expr_lin CLIPPED,
				expr_grp CLIPPED,
				expr_cla CLIPPED,
				expr_mar CLIPPED
	WHEN 2
		LET query = 'SELECT item, r10_precio_mb precio_n, ',
			'r10_precio_ant precio_a, r10_fec_camprec fecha_p, ',
			'precio_nue precio_c, "N" revers ',
			' FROM rept010, tmp_det_arch ',
			' WHERE r10_compania = ', vg_codcia,
			'   AND r10_codigo   = item '
	WHEN 3
		LET query = 'SELECT r86_item item, r86_precio_mb precio_n, ',
			'r86_precio_ant precio_a, r86_fec_camprec fecha_p, ',
			'r86_precio_nue precio_c, r86_reversado revers ',
			' FROM rept085, rept086 ',
			' WHERE r85_compania   = ', vg_codcia,
			'   AND r85_tipo_carga = "C" ',
			'   AND r86_compania   = r85_compania ',
			'   AND r86_codigo     = r85_codigo '
END CASE
LET query = query CLIPPED, ' INTO TEMP tmp_prec1 '
PREPARE tabla_temp FROM query
EXECUTE tabla_temp
IF flag = 2 THEN
	DROP TABLE tmp_det_arch
END IF
SELECT COUNT(*) INTO cuantos FROM tmp_prec1
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
IF flag <> 3 THEN
	IF rm_r85.r85_precio_nue > 0 THEN
		UPDATE tmp_prec1
			SET precio_c = rm_r85.r85_precio_nue
			WHERE 1 = 1
	END IF
	IF rm_r85.r85_porc_aum > 0 THEN
		UPDATE tmp_prec1
			SET precio_c = precio_c +
					(precio_c * (rm_r85.r85_porc_aum / 100))
			WHERE 1 = 1
	END IF
	IF rm_r85.r85_porc_dec > 0 THEN
		UPDATE tmp_prec1
			SET precio_c = precio_c -
					((precio_c * rm_r85.r85_porc_dec) / 100)
			WHERE 1 = 1
	END IF
END IF
IF flag = 2 THEN
	RETURN 1
END IF
CALL usuario_camprec()
UPDATE rept010
	SET r10_precio_ant  = r10_precio_mb,
	    r10_precio_mb   = (SELECT precio_c
					FROM tmp_prec1
					WHERE item = r10_codigo),
	    r10_fec_camprec = CURRENT
	WHERE r10_compania  = vg_codcia
	  AND r10_codigo   IN (SELECT item FROM tmp_prec1)
IF STATUS < 0 THEN
	LET mensaje = 'Existe uno o varios Item(s) que esta(n) bloqueado(s) por otro proceso. No se actualizaran cambios en el Item. '
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION genera_detalle()
DEFINE r_r86		RECORD LIKE rept086.*

DECLARE q_t1 CURSOR FOR SELECT * FROM tmp_prec1 ORDER BY item
LET r_r86.r86_compania  = vg_codcia
LET r_r86.r86_codigo    = rm_r85.r85_codigo
LET r_r86.r86_secuencia = 1
FOREACH q_t1 INTO r_r86.r86_item, r_r86.r86_precio_mb, r_r86.r86_precio_ant,
			r_r86.r86_fec_camprec, r_r86.r86_precio_nue,
			r_r86.r86_reversado
	INSERT INTO rept086 VALUES(r_r86.*)
	LET r_r86.r86_secuencia = r_r86.r86_secuencia + 1
END FOREACH

END FUNCTION



FUNCTION eliminar_carga()

BEGIN WORK
	WHENEVER ERROR CONTINUE
	DELETE FROM rept086
		WHERE r86_compania = vg_codcia
		  AND r86_codigo   = rm_r85.r85_codigo
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo eliminar el detalle del archivo.', 'exclamation')
		WHENEVER ERROR STOP
		RETURN 0
	END IF
	DELETE FROM rept085
		WHERE r85_compania = vg_codcia
		  AND r85_codigo   = rm_r85.r85_codigo
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo eliminar la cabecera del archivo.', 'exclamation')
		WHENEVER ERROR STOP
		RETURN 0
	END IF
	WHENEVER ERROR STOP
COMMIT WORK
CALL fl_mostrar_mensaje('Carga del archivo ELIMINADA OK.', 'info')
RETURN 1

END FUNCTION



FUNCTION muestra_estado()

IF rm_r85.r85_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
END IF
IF rm_r85.r85_estado = 'R' THEN
	DISPLAY 'REVERSADO' TO tit_estado
END IF
DISPLAY BY NAME rm_r85.r85_estado

END FUNCTION



FUNCTION muestra_tipo_carga()

DISPLAY BY NAME rm_r85.r85_tipo_carga
CASE rm_r85.r85_tipo_carga
	WHEN 'N' DISPLAY "EN LINEA"  TO tit_tipo_carga
	WHEN 'C' DISPLAY "CARGADO"   TO tit_tipo_carga
	WHEN 'P' DISPLAY "PROCESADO" TO tit_tipo_carga
	WHEN 'E' DISPLAY "ELIMINADO" TO tit_tipo_carga
END CASE

END FUNCTION



FUNCTION muestra_detalle()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE v_num_det	INTEGER
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(800)
DEFINE r_detalle	ARRAY[20000] OF RECORD
				r86_item	LIKE rept086.r86_item,
				r86_precio_mb	LIKE rept086.r86_precio_mb,
				r86_precio_ant	LIKE rept086.r86_precio_ant,
				r86_fec_camprec	LIKE rept086.r86_fec_camprec,
				r86_precio_nue	LIKE rept086.r86_precio_nue,
				r86_reversado	LIKE rept086.r86_reversado
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 19
LET num_cols = 76
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_detalle AT row_ini, 03 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_repf235_2 FROM '../forms/repf235_2'
ELSE
	OPEN FORM f_repf235_2 FROM '../forms/repf235_2c'
END IF
DISPLAY FORM f_repf235_2
CALL mostrar_botones_detalle()
IF num_args() = 5 THEN
	LET rm_r85.r85_codigo = arg_val(4)
END IF
LET query = 'SELECT r86_item, r86_precio_mb, r86_precio_ant, ',
		'r86_fec_camprec, r86_precio_nue, r86_reversado ',
		' FROM rept086 ',
		'WHERE r86_compania = ', vg_codcia,
		'  AND r86_codigo   = ', rm_r85.r85_codigo,
		' INTO TEMP tmp_detalle '
PREPARE q_detalle FROM query
EXECUTE q_detalle
LET col           = 1
LET rm_orden[col] = 'ASC'
LET vm_columna_1  = col
LET vm_columna_2  = 4
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det FROM query
	DECLARE q_det CURSOR FOR det
	LET v_num_det = 1
        FOREACH q_det INTO r_detalle[v_num_det].*
                LET v_num_det = v_num_det + 1
                IF v_num_det > vm_max_det THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET v_num_det = v_num_det - 1
	LET int_flag = 0
	CALL set_count(v_num_det)
	DISPLAY ARRAY r_detalle TO r_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_item(r_detalle[i].r86_item)
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
			--#DISPLAY i TO cur_row
			--#DISPLAY v_num_det TO max_row
			--#CALL fl_lee_item(vg_codcia, r_detalle[i].r86_item)
				--#RETURNING r_r10.*
			--#DISPLAY BY NAME r_r10.r10_nombre
			--#CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
						--#r_r10.r10_sub_linea,
						--#r_r10.r10_cod_grupo,
						--#r_r10.r10_cod_clase)
				--#RETURNING r_r72.*
			--#DISPLAY BY NAME r_r72.r72_desc_clase
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
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
DROP TABLE tmp_detalle
CLOSE WINDOW w_detalle

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY "Item"			TO tit_col1
--#DISPLAY "Precio"			TO tit_col2
--#DISPLAY "Precio Anter."		TO tit_col3
--#DISPLAY "Fecha Cambio Precio"	TO tit_col4
--#DISPLAY "Precio Nuevo"		TO tit_col5
--#DISPLAY "R"				TO tit_col6

END FUNCTION



FUNCTION control_reversar()
DEFINE run_prog		CHAR(10)
DEFINE comando		CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp236 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', rm_r85.r85_codigo
RUN comando
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION ver_item(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE run_prog		CHAR(10)
DEFINE comando		CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp108 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' "', item, '"'
RUN comando

END FUNCTION



FUNCTION usuario_camprec()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r87		RECORD LIKE rept087.*
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE precio_nue	LIKE rept010.r10_precio_mb

DECLARE q_r87 CURSOR FOR SELECT item, precio_c FROM tmp_prec1
FOREACH q_r87 INTO codigo, precio_nue
	INITIALIZE r_r87.* TO NULL
	CALL fl_lee_item(vg_codcia, codigo) RETURNING r_r10.*
	LET r_r87.r87_compania    = vg_codcia
	LET r_r87.r87_localidad   = vg_codloc
	LET r_r87.r87_item        = codigo
	SELECT NVL(MAX(r87_secuencia), 0) + 1 INTO r_r87.r87_secuencia
		FROM rept087
		WHERE r87_compania = r_r87.r87_compania
		  AND r87_item     = r_r87.r87_item
	LET r_r87.r87_precio_act  = precio_nue
	LET r_r87.r87_precio_ant  = r_r10.r10_precio_mb
	LET r_r87.r87_usu_camprec = vg_usuario
	LET r_r87.r87_fec_camprec = CURRENT
	INSERT INTO rept087 VALUES (r_r87.*)
END FOREACH

END FUNCTION



FUNCTION control_cargar_novedades()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 20
LET num_cols = 74
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repf235_4 AT row_ini, 04 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_repf235_4 FROM '../forms/repf235_4'
ELSE
	OPEN FORM f_repf235_4 FROM '../forms/repf235_4c'
END IF
DISPLAY FORM f_repf235_4
LET vm_num_det = 0
CALL mostrar_botones_detalle3()
DISPLAY BY NAME novedades
CALL muestra_detalle_nov()
LET int_flag = 0
CLOSE WINDOW w_repf235_4
RETURN

END FUNCTION



FUNCTION muestra_detalle_nov()
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(400)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

LET col           = 3
LET rm_orden[col] = 'DESC'
LET vm_columna_1  = col
LET vm_columna_2  = 1
WHILE TRUE
	LET query = 'SELECT * FROM tmp_nov ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det3 FROM query
	DECLARE q_det3 CURSOR FOR det3
	LET vm_num_det = 1
        FOREACH q_det3 INTO r_det_nov[vm_num_det].*
                LET vm_num_det = vm_num_det + 1
                IF vm_num_det > vm_max_det THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_num_det = vm_num_det - 1
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY r_det_nov TO r_det_nov.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_item(r_det_nov[i].r86_item)
			LET int_flag = 0
		ON KEY(F6)
			CALL imprimir_novedades()
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("F6","Imprimir")
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#DISPLAY i TO cur_row
			--#DISPLAY vm_num_det TO max_row
			--#CALL fl_lee_item(vg_codcia, r_det_nov[i].r86_item)
				--#RETURNING r_r10.*
			--#DISPLAY BY NAME r_r10.r10_nombre
			--#CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
						--#r_r10.r10_sub_linea,
						--#r_r10.r10_cod_grupo,
						--#r_r10.r10_cod_clase)
				--#RETURNING r_r72.*
			--#DISPLAY BY NAME r_r10.r10_marca
			--#DISPLAY BY NAME r_r72.r72_desc_clase
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
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
DROP TABLE tmp_nov

END FUNCTION



FUNCTION mostrar_botones_detalle3()

--#DISPLAY "Item"		TO tit_col1
--#DISPLAY "Descripcion"	TO tit_col2
--#DISPLAY "Observaciones"	TO tit_col3

END FUNCTION



FUNCTION imprimir_novedades()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_novedades TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT report_novedades(i)
END FOR
FINISH REPORT report_novedades

END FUNCTION



REPORT report_novedades(i)
DEFINE i		SMALLINT
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo    = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET documento = "NOVEDADES EN ARCHIVO CARGA DE PRECIOS"
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', documento CLIPPED, 80) RETURNING titulo
	LET titulo = modulo, titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 027, fl_justifica_titulo('C', novedades CLIPPED, 80)
	PRINT COLUMN 001, "FECHA IMPRESION: ", DATE(TODAY) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 123, usuario CLIPPED
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "ITEM",
	      COLUMN 009, "DESCRIPCION CLASE",
	      COLUMN 051, "DESCRIPCION ITEM",
	      COLUMN 103, "OBSERVACIONES"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	CALL fl_lee_item(vg_codcia, r_det_nov[i].r86_item) RETURNING r_r10.*
	CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea, r_r10.r10_sub_linea,
				r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
		RETURNING r_r72.*
	PRINT COLUMN 001, r_det_nov[i].r86_item[1, 9]	CLIPPED,
	      COLUMN 009, r_r72.r72_desc_clase[1, 40]	CLIPPED,
	      COLUMN 051, r_det_nov[i].nom_item[1, 50]	CLIPPED,
	      COLUMN 103, r_det_nov[i].comentarios	CLIPPED
	
PAGE TRAILER
	PRINT COLUMN 027, "_______________________";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION

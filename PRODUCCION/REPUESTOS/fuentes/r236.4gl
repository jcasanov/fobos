------------------------------------------------------------------------------
-- Titulo           : repp236.4gl - Reversacion de cambio de precios masivo
-- Elaboracion      : 07-Abr-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp236 base modulo compania [codigo]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				estado		LIKE rept085.r85_estado,
				fecha_ini	DATE,
				fecha_fin	DATE
			END RECORD
DEFINE rm_detalle	ARRAY[1000] OF RECORD
				r85_codigo	LIKE rept085.r85_codigo,
				r85_referencia	LIKE rept085.r85_referencia,
				r85_usuario	LIKE rept085.r85_usuario,
				r85_fec_camprec	LIKE rept085.r85_fec_camprec,
				r85_estado	LIKE rept085.r85_estado
			END RECORD
DEFINE vm_num_det	SMALLINT        	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_det	SMALLINT		-- MAXIMO DE FILAS LEIDAS
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'repp236'
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
IF num_args() = 4 THEN
	LET rm_detalle[1].r85_codigo = arg_val(4)
	CALL control_reversar(rm_detalle[1].r85_codigo) RETURNING lin_menu
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
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf236_1 FROM '../forms/repf236_1'
ELSE
	OPEN FORM f_repf236_1 FROM '../forms/repf236_1c'
END IF
DISPLAY FORM f_repf236_1
LET vm_max_det = 1000
LET vm_num_det = 0
CALL control_proceso()

END FUNCTION



FUNCTION control_proceso()

LET rm_par.estado    = 'A'
LET rm_par.fecha_fin = TODAY
LET rm_par.fecha_ini = rm_par.fecha_fin - 30 UNITS DAY
WHILE TRUE
	CLEAR FORM
	CALL muestra_contadores(0)
	CALL mostrar_botones_detalle()
	CALL control_ingreso()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL muestra_detalle()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		--#RETURN
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha de Hoy.','exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor que la Fecha de Hoy.','exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(800)

IF NOT cargar_temporal() THEN
	DROP TABLE tmp_detalle
	LET int_flag = 0
	RETURN
END IF
LET col           = 4
LET vm_columna_1  = col
LET vm_columna_2  = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'DESC'
WHILE TRUE
	LET query = 'SELECT * FROM tmp_detalle ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det FROM query
	DECLARE q_det CURSOR FOR det
	LET vm_num_det = 1
        FOREACH q_det INTO rm_detalle[vm_num_det].*
                LET vm_num_det = vm_num_det + 1
                IF vm_num_det > vm_max_det THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_num_det = vm_num_det - 1
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F5)
			LET int_flag = 4
			EXIT DISPLAY
		ON KEY(F6)
			LET i = arr_curr()
			IF control_reversar(rm_detalle[i].r85_codigo) THEN
				DROP TABLE tmp_detalle
				IF NOT cargar_temporal() THEN
					LET int_flag = 4
				ELSE
					LET int_flag = 0
				END IF
				EXIT DISPLAY
			END IF
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_detalle(rm_detalle[i].r85_codigo, 1)
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_detalle(rm_detalle[i].r85_codigo, 2)
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
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--# CALL  muestra_contadores(i)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 OR int_flag = 4 THEN
		IF int_flag = 4 THEN
			LET int_flag = 0
		END IF
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

END FUNCTION



FUNCTION cargar_temporal()
DEFINE query		CHAR(800)
DEFINE expr_est		CHAR(100)
DEFINE cuantos		INTEGER

IF rm_par.estado <> 'T' THEN
	LET expr_est = '   AND r85_estado   = "', rm_par.estado, '"'
ELSE
	LET expr_est = '   AND r85_estado   IN ("A", "R")'
END IF
LET query = 'SELECT r85_codigo, r85_referencia, r85_usuario, r85_fec_camprec, ',
		'r85_estado ',
		' FROM rept085 ',
		'WHERE r85_compania = ', vg_codcia,
			expr_est CLIPPED,
		'  AND r85_fec_camprec BETWEEN "', rm_par.fecha_ini,
					'" AND "', rm_par.fecha_fin, '"',
		' INTO TEMP tmp_detalle '
PREPARE q_detalle FROM query
EXECUTE q_detalle
SELECT COUNT(*) INTO cuantos FROM tmp_detalle
IF cuantos = 0 THEN
	LET vm_num_det = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_reversar(codigo)
DEFINE codigo		LIKE rept085.r85_codigo
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r85		RECORD LIKE rept085.*
DEFINE r_r86		RECORD LIKE rept086.*
DEFINE mensaje		VARCHAR(100)
DEFINE resp		CHAR(6)

INITIALIZE r_r85.* TO NULL
SELECT * INTO r_r85.* FROM rept085
	WHERE r85_compania = vg_codcia
	  AND r85_codigo   = codigo
IF r_r85.r85_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe registrado el codigo ' || codigo USING "<<<<&" || '.', 'exclamation')
	RETURN 0
END IF
IF r_r85.r85_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Este Cambio de Precios ya fue Reversado.', 'exclamation')
	RETURN 0
END IF
CALL fl_hacer_pregunta('Esta seguro qwe desea Reversar este cambio ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 0
END IF
BEGIN WORK
DECLARE q_rev CURSOR FOR
	SELECT * FROM rept086
		WHERE r86_compania = r_r85.r85_compania
		  AND r86_codigo   = r_r85.r85_codigo
FOREACH q_rev INTO r_r86.*
	WHENEVER ERROR CONTINUE
	DECLARE q_r10 CURSOR FOR
		SELECT * FROM rept010
			WHERE r10_compania = r_r86.r86_compania
			  AND r10_codigo   = r_r86.r86_item
		FOR UPDATE
	OPEN q_r10
	FETCH q_r10 INTO r_r10.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		LET mensaje = 'El Item ', r_r10.r10_codigo USING "<<<<<<<",
				' esta bloqueado por otro proceso. No se puede',
				' reversar en este momento.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		WHENEVER ERROR STOP
		RETURN 0
	END IF
	WHENEVER ERROR STOP
	UPDATE rept010 SET r10_precio_mb   = r_r86.r86_precio_mb,
			   r10_precio_ant  = r_r86.r86_precio_ant,
			   r10_fec_camprec = r_r86.r86_fec_camprec
		WHERE CURRENT OF q_r10
	IF STATUS < 0 THEN
		ROLLBACK WORK
		LET mensaje = 'Ha ocurrido un error con el maestro de Items. ',
				' Por favor llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	CLOSE q_r10
	FREE q_r10
END FOREACH
UPDATE rept085 SET r85_estado      = 'R',
		   r85_fec_reversa = CURRENT
	WHERE r85_compania = r_r85.r85_compania
	  AND r85_codigo   = r_r85.r85_codigo
COMMIT WORK
CALL fl_mostrar_mensaje('Proceso Terminado Ok.', 'info')
RETURN 1

END FUNCTION



FUNCTION muestra_contadores(row_cur)
DEFINE row_cur		SMALLINT

DISPLAY row_cur    TO cur_row
DISPLAY vm_num_det TO max_row

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY "Codigo"		TO tit_col1
--#DISPLAY "Referencia"		TO tit_col2
--#DISPLAY "Usuario"		TO tit_col3
--#DISPLAY "Fecha C.P."		TO tit_col4
--#DISPLAY "E"			TO tit_col5

END FUNCTION



FUNCTION ver_detalle(codigo, flag)
DEFINE codigo		LIKE rept085.r85_codigo
DEFINE flag		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE param		CHAR(50)
DEFINE comando		CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET param = codigo
IF flag = 2 THEN
	LET param = codigo, ' "D"'
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp235 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', param CLIPPED
RUN comando CLIPPED

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

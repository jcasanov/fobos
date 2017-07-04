--------------------------------------------------------------------------------
-- Titulo           : repp236.4gl - Reversacion de cambio de precios masivo
-- Elaboracion      : 07-Abr-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp236 base modulo compania [codigo]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
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
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE vm_num_det	SMALLINT        	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_det	SMALLINT		-- MAXIMO DE FILAS LEIDAS
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_incluir	CHAR(6)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp236.err')
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
CALL fl_retorna_usuario()
LET vm_incluir = NULL
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
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
DEFINE r_r85, r_r85_ant	RECORD LIKE rept085.*
DEFINE r_r86		RECORD LIKE rept086.*
DEFINE mensaje		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE query		CHAR(600)

INITIALIZE r_r85.*, r_r85_ant.* TO NULL
SELECT * INTO r_r85.*
	FROM rept085
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
SELECT * INTO r_r85_ant.*
	FROM rept085
	WHERE r85_compania    = vg_codcia
	  AND r85_codigo      = codigo - 1
	  AND r85_estado      = 'A'
	  AND r85_division    = r_r85.r85_division
	  AND r85_linea       = r_r85.r85_linea
	  AND r85_cod_grupo   = r_r85.r85_cod_grupo
	  AND r85_cod_clase   = r_r85.r85_cod_clase
	  AND r85_marca       = r_r85.r85_marca
	  AND r85_cod_util    = r_r85.r85_cod_util
	  AND r85_partida     = r_r85.r85_partida
	  AND r85_precio_nue  = r_r85.r85_precio_nue
	  AND r85_porc_aum    = r_r85.r85_porc_aum
	  AND r85_porc_dec    = r_r85.r85_porc_dec
	  AND r85_fec_reversa IS NULL
IF r_r85_ant.r85_compania IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Debe Reversar primero el anterior registro de cambio de precios masivo.', 'exclamation')
	RETURN 0
END IF
CALL fl_hacer_pregunta('Esta seguro que desea Reversar este cambio ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 0
END IF
CALL generar_temp_item_modificado(codigo)
IF int_flag THEN
	IF vm_incluir IS NULL THEN
		RETURN 0
	END IF
END IF
LET int_flag = 0
BEGIN WORK
LET query = 'SELECT * FROM rept086 ',
		' WHERE r86_compania = ', r_r85.r85_compania,
		'   AND r86_codigo   = ', r_r85.r85_codigo
IF vm_incluir IS NOT NULL THEN
	IF vm_incluir = 'No' THEN
		LET query = query CLIPPED,
			'   AND r86_item NOT IN ',
				'(SELECT UNIQUE item_i FROM tmp_item) '
	END IF
END IF
PREPARE rev FROM query
DECLARE q_rev CURSOR FOR rev
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
	CALL usuario_camprec(r_r86.r86_item, r_r86.r86_precio_mb,
				r_r86.r86_precio_ant, r_r86.r86_fec_camprec)
	WHENEVER ERROR CONTINUE
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
	WHENEVER ERROR STOP
	CLOSE q_r10
	FREE q_r10
END FOREACH
WHENEVER ERROR CONTINUE
UPDATE rept085 SET r85_estado      = 'R',
		   r85_fec_reversa = CURRENT
	WHERE r85_compania = r_r85.r85_compania
	  AND r85_codigo   = r_r85.r85_codigo
IF STATUS < 0 THEN
	ROLLBACK WORK
	LET mensaje = 'Ha ocurrido un error actualizando el estado del cambio',
			'de precios. Por favor llame al ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
LET query = 'UPDATE rept086 ',
		' SET r86_reversado = "S" ',
		' WHERE r86_compania = ', r_r85.r85_compania,
		'   AND r86_codigo   = ', r_r85.r85_codigo
IF vm_incluir IS NOT NULL THEN
	IF vm_incluir = 'No' THEN
		LET query = query CLIPPED,
			'   AND r86_item NOT IN ',
				'(SELECT UNIQUE item_i FROM tmp_item) '
	END IF
END IF
PREPARE up_rev FROM query
EXECUTE up_rev
IF STATUS < 0 THEN
	ROLLBACK WORK
	LET mensaje = 'Ha ocurrido un error actualizando el estado del detalle',
			' de precios. Por favor llame al ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
COMMIT WORK
DROP TABLE tmp_item
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



FUNCTION usuario_camprec(codigo, precio_nue, precio_ant, fec_camp)
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE precio_nue	LIKE rept010.r10_precio_mb
DEFINE precio_ant	LIKE rept010.r10_precio_ant
DEFINE fec_camp		LIKE rept010.r10_fec_camprec
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r87		RECORD LIKE rept087.*

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
LET r_r87.r87_precio_ant  = precio_ant
LET r_r87.r87_usu_camprec = vg_usuario
LET r_r87.r87_fec_camprec = CURRENT
{--
IF fec_camp IS NOT NULL THEN
	LET r_r87.r87_fec_camprec = fec_camp
END IF
--}
INSERT INTO rept087 VALUES (r_r87.*)

END FUNCTION



FUNCTION generar_temp_item_modificado(codigo)
DEFINE codigo		LIKE rept085.r85_codigo
DEFINE item		LIKE rept010.r10_codigo
DEFINE cuantos		INTEGER
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

SELECT r86_item item_m, r86_precio_mb precio, r86_precio_ant precio_ant,
	r86_fec_camprec fec_cp, r86_precio_nue precio_nue, r87_localidad loc,
	r87_item item_i, r87_secuencia sec, r87_precio_act prec_act,
	r87_precio_ant prec_ant, r87_usu_camprec usu_p, r87_fec_camprec fec_c
	FROM rept085, rept086, rept087
	WHERE r85_compania    = vg_codcia
	  AND r85_codigo      = codigo
	  AND r86_compania    = r85_compania
	  AND r86_codigo      = r85_codigo
	  AND r87_compania    = r86_compania
	  AND r87_item        = r86_item
	  AND r87_fec_camprec > r85_fecing
	INTO TEMP tmp_item
SELECT COUNT(*) INTO cuantos FROM tmp_item
IF cuantos = 0 THEN
	RETURN
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
OPEN WINDOW w_repf236_2 AT row_ini, 04 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_repf236_2 FROM '../forms/repf236_2'
ELSE
	OPEN FORM f_repf236_2 FROM '../forms/repf236_2c'
END IF
DISPLAY FORM f_repf236_2
CALL mostrar_botones_detalle2()
MESSAGE "                                           Presione F12 para continuar..."
WHILE TRUE
	CALL muestra_detalle_items_no_cab() RETURNING item
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL muestra_detalle_items_no_det(item)
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_repf236_2
RETURN

END FUNCTION



FUNCTION muestra_detalle_items_no_cab()
DEFINE r_item_c		ARRAY[1000] OF RECORD
				r86_item	LIKE rept086.r86_item,
				r86_precio_mb	LIKE rept086.r86_precio_mb,
				r86_precio_ant	LIKE rept086.r86_precio_ant,
				r86_fec_camprec	LIKE rept086.r86_fec_camprec,
				r86_precio_nue	LIKE rept086.r86_precio_nue
			END RECORD
DEFINE i, j, col	SMALLINT
DEFINE num_row1, salir	SMALLINT
DEFINE query		CHAR(400)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

LET col           = 1
LET rm_orden[col] = 'ASC'
LET vm_columna_1  = col
LET vm_columna_2  = 4
WHILE TRUE
	LET query = 'SELECT UNIQUE item_m, precio, precio_ant, fec_cp,',
			' precio_nue ',
			' FROM tmp_item ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det2 FROM query
	DECLARE q_det2 CURSOR FOR det2
	LET num_row1 = 1
        FOREACH q_det2 INTO r_item_c[num_row1].*
                LET num_row1 = num_row1 + 1
                IF num_row1 > 1000 THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET num_row1 = num_row1 - 1
	LET salir    = 0
	LET int_flag = 0
	CALL set_count(num_row1)
	DISPLAY ARRAY r_item_c TO r_item_c.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i     = arr_curr()
			LET salir = 1
			EXIT DISPLAY
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_item(r_item_c[i].r86_item)
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Detalle")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#CALL muestra_contadores_det(i, num_row1, 0, 0)
			--#CALL fl_lee_item(vg_codcia, r_item_c[i].r86_item)
				--#RETURNING r_r10.*
			--#DISPLAY BY NAME r_r10.r10_nombre
			--#CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
						--#r_r10.r10_sub_linea,
						--#r_r10.r10_cod_grupo,
						--#r_r10.r10_cod_clase)
				--#RETURNING r_r72.*
			--#DISPLAY BY NAME r_r72.r72_desc_clase
			--#CALL lineas_detalle_items_no_det(r_item_c[i].r86_item)
		--#AFTER DISPLAY
			IF rm_g04.g04_grupo = 'SI' THEN
				LET int_flag = 0
				CALL fl_hacer_pregunta('Desea REVERSAR estos items con el precio antes de estos cambios ?', 'No')
					RETURNING vm_incluir
				LET int_flag = 1
			ELSE
				CALL fl_mostrar_mensaje('Usted no puede REVERSAR estos cambios masivos.', 'info')
				LET int_flag = 1
				EXIT DISPLAY
			END IF
	END DISPLAY
	IF int_flag = 1 OR salir = 1 THEN
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
RETURN r_item_c[i].r86_item

END FUNCTION



FUNCTION lineas_detalle_items_no_det(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_item_d		ARRAY[1000] OF RECORD
				r87_localidad	LIKE rept087.r87_localidad,
				r87_secuencia	LIKE rept087.r87_secuencia,
				r87_precio_act	LIKE rept087.r87_precio_act,
				r87_precio_ant	LIKE rept087.r87_precio_ant,
				r87_usu_camprec	LIKE rept087.r87_usu_camprec,
				r87_fec_camprec	LIKE rept087.r87_fec_camprec
			END RECORD
DEFINE i, lim, num_row2	SMALLINT
DEFINE query		CHAR(400)

LET lim = fgl_scr_size('r_item_d')
FOR i = 1 TO lim
	CLEAR r_item_d[i].*
END FOR
LET query = 'SELECT loc, sec, prec_act, prec_ant, usu_p, fec_c ',
		' FROM tmp_item ',
		' WHERE item_i = "', item CLIPPED, '"',
		' ORDER BY 6 DESC, 2 '
PREPARE det4 FROM query
DECLARE q_det4 CURSOR FOR det4
LET num_row2 = 1
FOREACH q_det4 INTO r_item_d[num_row2].*
	LET num_row2 = num_row2 + 1
	IF num_row2 > 1000 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row2 = num_row2 - 1
IF num_row2 < lim THEN
	LET lim = num_row2
END IF
FOR i = 1 TO lim
	DISPLAY r_item_d[i].* TO r_item_d[i].*
END FOR

END FUNCTION



FUNCTION muestra_detalle_items_no_det(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_item_d		ARRAY[1000] OF RECORD
				r87_localidad	LIKE rept087.r87_localidad,
				r87_secuencia	LIKE rept087.r87_secuencia,
				r87_precio_act	LIKE rept087.r87_precio_act,
				r87_precio_ant	LIKE rept087.r87_precio_ant,
				r87_usu_camprec	LIKE rept087.r87_usu_camprec,
				r87_fec_camprec	LIKE rept087.r87_fec_camprec
			END RECORD
DEFINE i, j, col	SMALLINT
DEFINE num_row2, salir	SMALLINT
DEFINE query		CHAR(400)

LET col           = 6
LET rm_orden[col] = 'DESC'
LET vm_columna_1  = col
LET vm_columna_2  = 2
WHILE TRUE
	LET query = 'SELECT loc, sec, prec_act, prec_ant, usu_p, fec_c ',
			' FROM tmp_item ',
			' WHERE item_i = "', item CLIPPED, '"',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det3 FROM query
	DECLARE q_det3 CURSOR FOR det3
	LET num_row2 = 1
        FOREACH q_det3 INTO r_item_d[num_row2].*
                LET num_row2 = num_row2 + 1
                IF num_row2 > 1000 THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET num_row2 = num_row2 - 1
	LET salir    = 0
	LET int_flag = 0
	CALL set_count(num_row2)
	DISPLAY ARRAY r_item_d TO r_item_d.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET salir = 1
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F23)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F24)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F25)
			LET col = 6
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F5","Cabecera")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#CALL muestra_contadores_det(0, 0, i, num_row2)
		--#AFTER DISPLAY
			IF rm_g04.g04_grupo = 'SI' THEN
				LET int_flag = 0
				CALL fl_hacer_pregunta('Desea REVERSAR estos items con el precio antes de estos cambios ?', 'No')
					RETURNING vm_incluir
				LET int_flag = 1
			ELSE
				CALL fl_mostrar_mensaje('Usted no puede REVERSAR estos cambios masivos.', 'info')
				LET int_flag = 1
				EXIT DISPLAY
			END IF
	END DISPLAY
	IF int_flag = 1 OR salir = 1 THEN
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

END FUNCTION



FUNCTION muestra_contadores_det(num_row1, max_row1, num_row2, max_row2)
DEFINE num_row1, max_row1 SMALLINT
DEFINE num_row2, max_row2 SMALLINT

DISPLAY BY NAME num_row1, max_row1, num_row2, max_row2

END FUNCTION



FUNCTION mostrar_botones_detalle2()

--#DISPLAY "Item"			TO tit_col1
--#DISPLAY "Precio"			TO tit_col2
--#DISPLAY "Precio Anter."		TO tit_col3
--#DISPLAY "Fecha Cambio Precio"	TO tit_col4
--#DISPLAY "Precio Nuevo"		TO tit_col5

--#DISPLAY 'LC'				TO tit_col6
--#DISPLAY 'Sec.'			TO tit_col7
--#DISPLAY 'Precio Actual'		TO tit_col8
--#DISPLAY 'Precio Anter.'		TO tit_col9
--#DISPLAY 'Usuario'			TO tit_col10
--#DISPLAY 'Fecha Cambio Precio'	TO tit_col11

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



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION

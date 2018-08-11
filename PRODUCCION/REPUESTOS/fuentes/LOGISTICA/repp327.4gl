--------------------------------------------------------------------------------
-- Titulo           : repp327.4gl - Consulta Control de Ruta
-- Elaboracion      : 26-jun-2013
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp327 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par		RECORD
				fecha_ini	LIKE rept113.r113_fecha,
				fecha_fin	LIKE rept113.r113_fecha,
				estado		LIKE rept113.r113_estado,
				r113_cod_trans	LIKE rept113.r113_cod_trans,
				r110_descripcion LIKE rept110.r110_descripcion,
				r113_cod_chofer	LIKE rept113.r113_cod_chofer,
				r111_nombre	LIKE rept111.r111_nombre
			END RECORD
DEFINE rm_detalle	ARRAY[20000] OF RECORD
				r113_num_hojrut	LIKE rept113.r113_num_hojrut,
				r113_fecha	LIKE rept113.r113_fecha,
				r113_km_ini	LIKE rept113.r113_km_ini,
				r113_km_fin	LIKE rept113.r113_km_fin,
				usuario		LIKE rept113.r113_usuario,
				fecing		LIKE rept113.r113_fecing,
				r113_estado	LIKE rept113.r113_estado
			END RECORD
DEFINE rm_det_adi	ARRAY[20000] OF RECORD
				r113_cod_trans	LIKE rept113.r113_cod_trans,
				r110_descripcion LIKE rept110.r110_descripcion,
				r113_cod_chofer	LIKE rept113.r113_cod_chofer,
				r111_nombre	LIKE rept111.r111_nombre,
				r113_observacion LIKE rept113.r113_observacion
			END RECORD
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_num_det	INTEGER
DEFINE vm_max_det	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp327.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp327'
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
LET vm_max_det = 20000
LET lin_menu   = 0          
LET row_ini    = 3          
LET num_rows   = 22         
LET num_cols   = 80         
IF vg_gui = 0 THEN        
	LET lin_menu = 1                                                        
	LET row_ini  = 2
	LET num_rows = 22 
	LET num_cols = 78 
END IF                  
OPEN WINDOW w_repp327_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_repf327_1 FROM '../forms/repf327_1'
ELSE
	OPEN FORM f_repf327_1 FROM '../forms/repf327_1c'
END IF
DISPLAY FORM f_repf327_1
CLEAR FORM
CALL control_mostrar_botones()
INITIALIZE rm_par.* TO NULL
LET rm_par.estado    = "T"
LET rm_par.fecha_fin = TODAY
LET rm_par.fecha_ini = MDY(MONTH(rm_par.fecha_fin), 01, YEAR(rm_par.fecha_fin))
WHILE TRUE
	CALL borrar_detalle()
	CALL control_consulta()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF vm_num_det = 0 THEN
		CONTINUE WHILE
	END IF
	CALL control_ver_detalle()
	DROP TABLE tmp_detalle
END WHILE
CLOSE WINDOW w_repp327_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_mostrar_botones()

--#DISPLAY "Número"		TO tit_col1
--#DISPLAY "Fecha"		TO tit_col2
--#DISPLAY "Km Ini"		TO tit_col3
--#DISPLAY "Km Fin"		TO tit_col4
--#DISPLAY "Usuario"		TO tit_col5
--#DISPLAY "Fecha/Usuario"	TO tit_col6
--#DISPLAY "E"			TO tit_col7

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].*, rm_det_adi[i].* TO NULL
END FOR
CLEAR r113_observacion
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION control_consulta()
DEFINE num_aux		INTEGER
DEFINE mensaje		VARCHAR(100)

LET vm_num_det = 0
CALL lee_cabecera()
IF int_flag THEN
	RETURN
END IF
CALL cargar_tabla_temp()
IF vm_num_det = 0 THEN
	DROP TABLE tmp_detalle
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE i, j, col	SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 2
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	CALL cargar_detalle()
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			CALL ver_control_ruta(i)
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
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_etiquetas_det(i, vm_num_det)
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag THEN
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
CALL muestra_etiquetas_det(0, vm_num_det)

END FUNCTION



FUNCTION lee_cabecera()
DEFINE r_r110		RECORD LIKE rept110.*
DEFINE r_r111		RECORD LIKE rept111.*
DEFINE fec_ini, fec_fin	LIKE rept113.r113_fecha
DEFINE resp		CHAR(6)

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(r113_cod_trans) THEN
			CALL fl_ayuda_transporte(vg_codcia, vg_codloc, "T")
				RETURNING r_r110.r110_cod_trans,
					  r_r110.r110_descripcion
		      	IF r_r110.r110_cod_trans IS NOT NULL THEN
				CALL fl_lee_transporte(vg_codcia, vg_codloc,
						r_r110.r110_cod_trans)
					RETURNING r_r110.*
				LET rm_par.r113_cod_trans   =
							r_r110.r110_cod_trans
				LET rm_par.r110_descripcion =
							r_r110.r110_descripcion
				DISPLAY BY NAME rm_par.r113_cod_trans,
						r_r110.r110_descripcion
		      	END IF
		END IF
		IF INFIELD(r113_cod_chofer) AND
		   rm_par.r113_cod_trans IS NOT NULL
		THEN
			CALL fl_ayuda_chofer(vg_codcia, vg_codloc,
						rm_par.r113_cod_trans, "T")
				RETURNING r_r111.r111_cod_chofer,
					  r_r111.r111_nombre
		      	IF r_r111.r111_cod_chofer IS NOT NULL THEN
				LET rm_par.r113_cod_chofer =
							r_r111.r111_cod_chofer
				LET rm_par.r111_nombre     =
							r_r111.r111_nombre
				DISPLAY BY NAME rm_par.r113_cod_chofer,
						r_r111.r111_nombre
		      	END IF
		END IF
		LET int_flag = 0
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
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor que la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha final no puede ser mayor que la fecha de hoy.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER FIELD r113_cod_trans
		IF rm_par.r113_cod_trans IS NOT NULL THEN
			CALL fl_lee_transporte(vg_codcia, vg_codloc,
						rm_par.r113_cod_trans)
				RETURNING r_r110.*
			IF r_r110.r110_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este transporte no existe en la compañía.', 'exclamation')
				NEXT FIELD r113_cod_trans
			END IF
			LET rm_par.r113_cod_trans   = r_r110.r110_cod_trans
			LET rm_par.r110_descripcion = r_r110.r110_descripcion
		ELSE
			INITIALIZE r_r110.*, r_r111.*, rm_par.r113_cod_trans,
					rm_par.r113_cod_chofer
				TO NULL
		END IF
		DISPLAY BY NAME rm_par.r113_cod_trans, r_r110.r110_descripcion,
				rm_par.r113_cod_chofer, r_r111.r111_nombre
	AFTER FIELD r113_cod_chofer
		IF rm_par.r113_cod_trans IS NULL THEN
			INITIALIZE r_r111.*, rm_par.r113_cod_chofer TO NULL
			DISPLAY BY NAME rm_par.r113_cod_chofer,
					r_r111.r111_nombre
			CONTINUE INPUT
		END IF
		IF rm_par.r113_cod_chofer IS NOT NULL THEN
			CALL fl_lee_chofer(vg_codcia, vg_codloc,
						rm_par.r113_cod_trans,
						rm_par.r113_cod_chofer)
				RETURNING r_r111.*
			IF r_r111.r111_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este chofer no existe en la compañía o no esta asociado a éste transporte.', 'exclamation')
				NEXT FIELD r113_cod_chofer
			END IF
			LET rm_par.r113_cod_chofer = r_r111.r111_cod_chofer
			LET rm_par.r111_nombre     = r_r111.r111_nombre
		ELSE
			INITIALIZE r_r111.*, rm_par.r113_cod_chofer TO NULL
		END IF
		DISPLAY BY NAME rm_par.r113_cod_chofer, r_r111.r111_nombre
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor que la fecha final.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_tabla_temp()
DEFINE query		CHAR(1500)
DEFINE expr_tra		VARCHAR(100)
DEFINE expr_cho		VARCHAR(100)
DEFINE expr_est		VARCHAR(100)

LET expr_est = NULL
IF rm_par.estado <> "T" THEN
	LET expr_est = "   AND r113_estado   = '", rm_par.estado, "'"
END IF
IF rm_par.estado = "P" THEN
	LET expr_est = "   AND r113_estado   IN ('A', 'P') "
END IF
LET expr_tra = NULL
IF rm_par.r113_cod_trans IS NOT NULL THEN
	LET expr_tra = "   AND r113_cod_trans = ", rm_par.r113_cod_trans
END IF
LET expr_cho = NULL
IF rm_par.r113_cod_chofer IS NOT NULL THEN
	LET expr_cho = "   AND r113_cod_chofer = ", rm_par.r113_cod_chofer
END IF
LET query = "SELECT r113_num_hojrut, r113_fecha, r113_km_ini,",
			" r113_km_fin, r113_usuario, r113_fecing, r113_estado,",
			" r113_cod_trans, r110_descripcion, r113_cod_chofer,",
			" r111_nombre, r113_observacion",
		" FROM rept113, rept110, rept111",
		" WHERE r113_compania  = ", vg_codcia,
		"   AND r113_localidad = ", vg_codloc,
		expr_tra CLIPPED,
		expr_cho CLIPPED,
		expr_est CLIPPED,
		"   AND r113_fecha     BETWEEN DATE('", rm_par.fecha_ini, "')",
					 " AND DATE('", rm_par.fecha_fin, "')",
		"   AND r110_compania   = r113_compania",
		"   AND r110_localidad  = r113_localidad",
		"   AND r110_cod_trans  = r113_cod_trans",
		"   AND r111_compania   = r113_compania",
		"   AND r111_localidad  = r113_localidad",
		"   AND r111_cod_trans  = r113_cod_trans",
		"   AND r111_cod_chofer = r113_cod_chofer",
		" INTO TEMP tmp_detalle "
PREPARE cons_ruta FROM query
EXECUTE cons_ruta
SELECT COUNT(*) INTO vm_num_det FROM tmp_detalle

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		CHAR(400)

LET query = "SELECT * FROM tmp_detalle ",
		" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1], ",",
			      vm_columna_2, " ", rm_orden[vm_columna_2] 
PREPARE cons_hoja FROM query
DECLARE q_hoja CURSOR FOR cons_hoja
LET vm_num_det = 1
FOREACH q_hoja INTO rm_detalle[vm_num_det].*, rm_det_adi[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_etiquetas_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT
DEFINE num_sri		LIKE rept095.r95_num_sri
DEFINE desc_zon		LIKE rept108.r108_descripcion
DEFINE desc_sub		LIKE rept109.r109_descripcion

CALL muestra_contadores_det(num_row, max_row)
IF num_row > 0 THEN
	DISPLAY BY NAME rm_det_adi[num_row].*
ELSE
	IF rm_par.r113_cod_trans IS NULL THEN
		CLEAR r113_cod_trans, r110_descripcion
	END IF
	IF rm_par.r113_cod_chofer IS NULL THEN
		CLEAR r113_cod_chofer, r111_nombre
	END IF
	CLEAR r113_observacion
END IF

END FUNCTION



FUNCTION ver_control_ruta(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE comando		VARCHAR(200)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando  = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog CLIPPED,
		' repp252 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', rm_detalle[i].r113_num_hojrut
RUN comando

END FUNCTION

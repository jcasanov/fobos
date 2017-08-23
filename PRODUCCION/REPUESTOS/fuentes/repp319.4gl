--------------------------------------------------------------------------------
-- Titulo           : repp319.4gl - Consulta de Transferencias
-- Elaboracion      : 03-may-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp319 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_bodega_ori	LIKE rept019.r19_bodega_ori
DEFINE vm_bodega_des	LIKE rept019.r19_bodega_dest
DEFINE vm_vend_bod	LIKE rept019.r19_vendedor
DEFINE tit_bodega_ori	LIKE rept002.r02_nombre
DEFINE tit_bodega_des	LIKE rept002.r02_nombre
DEFINE tit_vend_bod	LIKE rept001.r01_nombres
DEFINE referencia	LIKE rept019.r19_referencia
DEFINE tiene_cru	CHAR(1)
DEFINE rm_trans		ARRAY[10000] OF RECORD
				r19_cod_tran	LIKE rept019.r19_cod_tran,
				r19_num_tran	LIKE rept019.r19_num_tran,
				r19_fecing	DATE,
				r19_bodega_ori	LIKE rept019.r19_bodega_ori,
				r19_bodega_dest	LIKE rept019.r19_bodega_dest,
				r19_referencia	LIKE rept019.r19_referencia,
				r19_nomcli	LIKE rept019.r19_nomcli
			END RECORD
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_r01		RECORD LIKE rept001.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp319.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp319'
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

CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
INITIALIZE rm_r01.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_estado     = 'A'
		  AND r01_user_owner = vg_usuario
OPEN qu_vd 
FETCH qu_vd INTO rm_r01.*
CLOSE qu_vd 
FREE qu_vd 
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
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
OPEN WINDOW w_repf319_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf319_1 FROM '../forms/repf319_1'
ELSE
	OPEN FORM f_repf319_1 FROM '../forms/repf319_1c'
END IF
DISPLAY FORM f_repf319_1
LET vm_max_rows = 10000
--#DISPLAY 'TP'			TO tit_col1
--#DISPLAY 'Número'		TO tit_col2
--#DISPLAY 'Fecha TR.'		TO tit_col3
--#DISPLAY 'BO'			TO tit_col4
--#DISPLAY 'BD'			TO tit_col5
--#DISPLAY 'Referencia'		TO tit_col6
--#DISPLAY 'Observaciones'	TO tit_col7
--#LET vm_size_arr = fgl_scr_size('rm_trans')
IF vg_gui = 0 THEN
	LET vm_size_arr = 12
END IF
INITIALIZE vm_bodega_ori, vm_bodega_des, vm_vend_bod, tit_bodega_ori,
		tit_bodega_des, tit_vend_bod, referencia, tiene_cru TO NULL
LET vm_fecha_ini = MDY(MONTH(vg_fecha), 01, YEAR(vg_fecha))
LET vm_fecha_fin = vg_fecha
IF rm_r01.r01_tipo <> 'J' AND rm_r01.r01_tipo <> 'G' THEN
	LET vm_vend_bod  = rm_r01.r01_codigo
	LET tit_vend_bod = rm_r01.r01_nombres
	DISPLAY BY NAME vm_vend_bod, tit_vend_bod
END IF
LET tiene_cru = 'N'
WHILE TRUE
	CALL inicializar_detalle()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL muestra_consulta()
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf319_1
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_bod_ori	RECORD LIKE rept002.*
DEFINE r_bod_des	RECORD LIKE rept002.*
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin, vm_bodega_ori, vm_bodega_des,
	referencia, tiene_cru, vm_vend_bod
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(vm_bodega_ori) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'A',
							'T', '2')
				RETURNING r_bod_ori.r02_codigo,
					  r_bod_ori.r02_nombre
			IF r_bod_ori.r02_codigo IS NOT NULL THEN
				LET vm_bodega_ori  = r_bod_ori.r02_codigo
				LET tit_bodega_ori = r_bod_ori.r02_nombre
				DISPLAY BY NAME vm_bodega_ori, tit_bodega_ori
			END IF
		END IF
		IF INFIELD(vm_bodega_des) THEN
		     	CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'A',
							'T', '2')
				RETURNING r_bod_des.r02_codigo,
					  r_bod_des.r02_nombre
			IF r_bod_des.r02_codigo IS NOT NULL THEN
				LET vm_bodega_des  = r_bod_des.r02_codigo
				LET tit_bodega_des = r_bod_des.r02_nombre 
				DISPLAY BY NAME vm_bodega_des, tit_bodega_des
			END IF
		END IF
		IF INFIELD(vm_vend_bod) AND
		   (rm_g05.g05_tipo <> 'UF' OR rm_r01.r01_tipo = 'J' OR
		    rm_r01.r01_tipo = 'G')
		THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'M')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN                
				LET vm_vend_bod  = r_r01.r01_codigo
				LET tit_vend_bod = r_r01.r01_nombres
				DISPLAY BY NAME vm_vend_bod, tit_vend_bod
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fec_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fec_fin = vm_fecha_fin
	AFTER FIELD vm_fecha_ini
		IF vm_fecha_ini IS NULL THEN
			LET fec_ini = vm_fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
		IF vm_fecha_ini > vg_fecha THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin
		IF vm_fecha_fin IS NULL THEN
			LET fec_fin = vm_fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
		IF vm_fecha_fin > vg_fecha THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
	AFTER FIELD vm_bodega_ori
		IF vm_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega_ori)
				RETURNING r_bod_ori.*
			IF r_bod_ori.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.', 'exclamation')
				NEXT FIELD vm_bodega_ori
			END IF 
			LET vm_bodega_ori  = r_bod_ori.r02_codigo
			LET tit_bodega_ori = r_bod_ori.r02_nombre
			DISPLAY BY NAME vm_bodega_ori, tit_bodega_ori
		ELSE
			CLEAR vm_bodega_ori, tit_bodega_ori
			INITIALIZE vm_bodega_ori, tit_bodega_ori TO NULL
		END IF 
	AFTER FIELD vm_bodega_des
		IF vm_bodega_des IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega_des)
				RETURNING r_bod_des.*
			IF r_bod_des.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.', 'exclamation')
				NEXT FIELD vm_bodega_des
			END IF 
			LET vm_bodega_des  = r_bod_des.r02_codigo
			LET tit_bodega_des = r_bod_des.r02_nombre
			DISPLAY BY NAME vm_bodega_des, tit_bodega_des
		ELSE
			CLEAR vm_bodega_des, tit_bodega_des
			INITIALIZE vm_bodega_des, tit_bodega_des TO NULL
		END IF 
	AFTER FIELD vm_vend_bod
		IF rm_r01.r01_tipo <> 'J' AND rm_r01.r01_tipo <> 'G' THEN
			LET vm_vend_bod  = rm_r01.r01_codigo
			LET tit_vend_bod = rm_r01.r01_nombres
			DISPLAY BY NAME vm_vend_bod, tit_vend_bod
		END IF		
		IF vm_vend_bod IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, vm_vend_bod)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Usuario no existe.', 'exclamation')
				NEXT FIELD vm_vend_bod
			END IF
			LET vm_vend_bod  = r_r01.r01_codigo
			LET tit_vend_bod = r_r01.r01_nombres
			DISPLAY BY NAME vm_vend_bod, tit_vend_bod
		ELSE
			CLEAR vm_vend_bod, tit_vend_bod
			INITIALIZE vm_vend_bod, tit_vend_bod TO NULL
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la Fecha Final.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_bodega_ori IS NOT NULL THEN
			IF vm_bodega_des IS NOT NULL THEN
				IF vm_bodega_ori = vm_bodega_des THEN
					CALL fl_mostrar_mensaje('La Bodega Origen y la Bodega Destino no pueden ser iguales.', 'exclamation')
					NEXT FIELD vm_bodega_ori
				END IF
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_consulta()
DEFINE fec_i, fec_f	LIKE rept019.r19_fecing
DEFINE i, col		SMALLINT
DEFINE query		CHAR(2000)
DEFINE expr_bod_ori	VARCHAR(100)
DEFINE expr_bod_des	VARCHAR(100)
DEFINE expr_usua	VARCHAR(100)
DEFINE expr_refe	VARCHAR(150)
DEFINE expr_cruc	CHAR(600)
DEFINE cuantos		INTEGER

LET fec_i = EXTEND(vm_fecha_ini, YEAR TO SECOND)
LET fec_f = EXTEND(vm_fecha_fin, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND  
LET expr_bod_ori = NULL
IF vm_bodega_ori IS NOT NULL THEN
	LET expr_bod_ori = '   AND r19_bodega_ori  = "', vm_bodega_ori, '"'
END IF
LET expr_bod_des = NULL
IF vm_bodega_des IS NOT NULL THEN
	LET expr_bod_des = '   AND r19_bodega_dest = "', vm_bodega_des, '"'
END IF
LET expr_usua = NULL
IF vm_vend_bod IS NOT NULL THEN
	LET expr_usua = '   AND r19_vendedor    = ', vm_vend_bod
END IF
LET expr_refe = NULL
IF referencia IS NOT NULL THEN
	LET expr_refe = '   AND r19_referencia  = "', referencia CLIPPED, '"'
	LET i = 1
	WHILE TRUE
		IF referencia[i, i] = '*' OR referencia[i, i] = '?' THEN
			LET expr_refe = '   AND r19_referencia  MATCHES ("',
						referencia CLIPPED, '")'
			EXIT WHILE
		END IF
		LET i = i + 1
	END WHILE
END IF
LET expr_cruc = NULL
IF tiene_cru = 'S' THEN
	LET expr_cruc = '   AND EXISTS (SELECT 1 FROM rept041 ',
					'WHERE r41_compania  = r19_compania ',
					'  AND r41_localidad = r19_localidad ',
					'  AND r41_cod_tr    = r19_cod_tran ',
					'  AND r41_num_tr    = r19_num_tran)'
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 2
LET vm_columna_1           = col
LET vm_columna_2           = 3
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'DESC'
WHILE TRUE
	LET query = 'SELECT r19_cod_tran, r19_num_tran, DATE(r19_fecing), ',
			' r19_bodega_ori, r19_bodega_dest, r19_referencia, ',
			' r19_nomcli ',
			' FROM rept019 ',
			' WHERE r19_compania    = ', vg_codcia,
			'   AND r19_localidad   = ', vg_codloc,
			'   AND r19_cod_tran    = "TR" ',
			expr_bod_ori CLIPPED,
			expr_bod_des CLIPPED,
			expr_usua CLIPPED,
			expr_refe CLIPPED,
			'   AND r19_fecing      BETWEEN "', fec_i,
						 '" AND "', fec_f, '"',
			expr_cruc CLIPPED,
			' ORDER BY ',
				vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
				vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_trans[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_rows = i - 1
	IF vm_num_rows = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, vm_num_rows)
	END IF
	CALL set_count(vm_num_rows)
	LET int_flag = 0
	DISPLAY ARRAY rm_trans TO rm_trans.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			CALL muestra_contadores_det(i, vm_num_rows)
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1()
		ON KEY(F5)
			LET i = arr_curr()
			IF cuantos > 0 THEN
				CALL contabilizacion(rm_trans[i].r19_cod_tran,
				 		   rm_trans[i].r19_num_tran)
			END IF
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						rm_trans[i].r19_cod_tran,
						rm_trans[i].r19_num_tran)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL imprimir_transf(i)
			LET int_flag = 0
		ON KEY(F8)
			CALL control_imprimir()
			LET int_flag = 0
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
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_det(i, vm_num_rows)
			--#SELECT COUNT(*) INTO cuantos FROM rept040 
			--#	WHERE r40_compania  = vg_codcia	
			--#	  AND r40_localidad = vg_codloc
			--#	  AND r40_cod_tran  = rm_trans[i].r19_cod_tran
			--#	  AND r40_num_tran  = rm_trans[i].r19_num_tran
			--#IF cuantos > 0 THEN
				--#CALL dialog.keysetlabel('F5', 
				--#	'Contabilización')
			--#ELSE
				--#CALL dialog.keysetlabel('F5', '')
			--#END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("RETURN","")
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

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_transf TO PIPE comando
FOR i = 1 TO vm_num_rows
	OUTPUT TO REPORT reporte_transf(i)
END FOR
FINISH REPORT reporte_transf

END FUNCTION



REPORT reporte_transf(i)
DEFINE i		SMALLINT
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 030, "DETALLE DE TRANSFERENCIAS",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 015, "** RANGO FECHAS  : ",
	      COLUMN 035, vm_fecha_ini USING "dd-mm-yyyy", "  -  ",
	      COLUMN 050, vm_fecha_fin USING "dd-mm-yyyy"
	IF vm_bodega_ori IS NOT NULL THEN
		PRINT COLUMN 015, "** BODEGA ORIGEN : ",
		      COLUMN 035, vm_bodega_ori CLIPPED,
		      COLUMN 038, tit_bodega_ori CLIPPED
	ELSE
		PRINT 1 SPACES
	END IF
	IF vm_bodega_des IS NOT NULL THEN
		PRINT COLUMN 015, "** BODEGA DESTINO: ",
		      COLUMN 035, vm_bodega_des CLIPPED,
		      COLUMN 038, tit_bodega_des CLIPPED
	ELSE
		PRINT 1 SPACES
	END IF
	IF vm_vend_bod IS NOT NULL THEN
		PRINT COLUMN 015, "** USUARIO/TRANS.: ",
		      COLUMN 035, vm_vend_bod USING "&&",
		      COLUMN 038, tit_vend_bod CLIPPED
	ELSE
		PRINT 1 SPACES
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "TP",
	      COLUMN 004, "NUMERO",
	      COLUMN 012, "FECHA TR.",
	      COLUMN 023, "BO",
	      COLUMN 026, "BD",
	      COLUMN 035, "R E F E R E N C I A",
	      COLUMN 063, "OBSERVACIONES"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_trans[i].r19_cod_tran,
	      COLUMN 004, rm_trans[i].r19_num_tran	USING "<<<<<<&",
	      COLUMN 012, rm_trans[i].r19_fecing	USING "dd-mm-yyyy",
	      COLUMN 023, rm_trans[i].r19_bodega_ori,
	      COLUMN 026, rm_trans[i].r19_bodega_dest,
	      COLUMN 029, rm_trans[i].r19_referencia[1, 32] CLIPPED,
	      COLUMN 063, rm_trans[i].r19_nomcli[1, 18] CLIPPED
	
ON LAST ROW
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION inicializar_detalle()
DEFINE i		SMALLINT

LET vm_num_rows = 0
FOR i = 1 TO vm_size_arr 
	CLEAR rm_trans[i].*
END FOR
FOR i = 1 TO vm_max_rows
	INITIALIZE rm_trans[i].* TO NULL
END FOR

END FUNCTION



FUNCTION imprimir_transf(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', vg_codloc, ' "', rm_trans[i].r19_cod_tran, '" ',
		rm_trans[i].r19_num_tran
CALL ejecuta_comando('REPUESTOS', vg_modulo, 'repp415 ', param)

END FUNCTION



FUNCTION contabilizacion(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

INITIALIZE tipo_comp, num_comp TO NULL
DECLARE q_cursor1 CURSOR FOR
	SELECT r40_tipo_comp, r40_num_comp
		FROM rept040
		WHERE r40_compania  = vg_codcia
		  AND r40_localidad = vg_codloc
		  AND r40_cod_tran  = cod_tran
		  AND r40_num_tran  = num_tran
OPEN q_cursor1
FETCH q_cursor1 INTO tipo_comp, num_comp
CLOSE q_cursor1
FREE q_cursor1
IF tipo_comp IS NULL THEN
	RETURN
END IF
LET param = ' "', tipo_comp, '" ', num_comp CLIPPED
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
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



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Contabilizacion'          AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Transferencia'            AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Imprimir Transferencia'   AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprimir Listado'         AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

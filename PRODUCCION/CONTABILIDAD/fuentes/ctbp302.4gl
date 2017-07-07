--------------------------------------------------------------------------------
-- Titulo           : ctbp302.4gl - Consulta de Movimientos de cuentas
-- Elaboracion      : 11-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp302 base módulo compañía
--			[cuenta] [fecha_ini] [fecha_fin] [moneda]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b10		RECORD LIKE ctbt010.*
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE rm_b13		RECORD LIKE ctbt013.*
DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_subtipo	LIKE ctbt012.b12_subtipo
DEFINE vm_expr_sql	VARCHAR(200)
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det	INTEGER
DEFINE vm_num_det	INTEGER
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_nivel         SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_saldo_fec	DATE
DEFINE vm_saldo_al	DECIMAL(14,2)
DEFINE vm_total_deb	DECIMAL(14,2)
DEFINE vm_total_cre	DECIMAL(14,2)
DEFINE vm_r_rows	ARRAY[2000] OF LIKE ctbt010.b10_cuenta
DEFINE rm_det 		ARRAY[50000] OF RECORD
				b13_tipo_comp	LIKE ctbt013.b13_tipo_comp,
				b12_subtipo	LIKE ctbt012.b12_subtipo,
				b13_num_comp	LIKE ctbt013.b13_num_comp,
				b13_fec_proceso	LIKE ctbt013.b13_fec_proceso,
				tit_debito	DECIMAL(14,2),
				tit_credito	DECIMAL(14,2),
				tit_saldo	DECIMAL(14,2)
			END RECORD
DEFINE tit_glosa	ARRAY[50000] OF LIKE ctbt013.b13_glosa



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp302.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 7 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp302'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 2000
LET vm_max_det	= 50000
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf302_1"
DISPLAY FORM f_ctb
LET vm_scr_lin     = 0
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_nivel       = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_botones_detalle()
LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY
LET vm_expr_sql  = '1 = 1'
WHILE TRUE
	CALL control_consulta()
	CALL borrar_detalle()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE query		VARCHAR(1200)
DEFINE resul		SMALLINT
DEFINE cuantos		INTEGER

INITIALIZE cod_aux, r_mon.* TO NULL
LET vm_num_det = 0
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Nivel no está configurado.','stop')
	EXIT PROGRAM
END IF
CALL muestra_contadores_det(0, vm_num_det)
IF num_args() = 3 THEN
	LET rm_b12.b12_moneda = rg_gen.g00_moneda_base
	CALL fl_lee_moneda(rm_b12.b12_moneda) RETURNING r_mon.*
	IF r_mon.g13_moneda IS NULL THEN
       		CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
	        EXIT PROGRAM
	END IF
	DISPLAY r_mon.g13_nombre TO tit_moneda
	CALL leer_datos() RETURNING resul
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current])
			IF int_flag THEN
				LET int_flag = 0
				IF num_args() = 7 THEN
					EXIT PROGRAM
				END IF
				RETURN
			END IF
		ELSE
			CLEAR FORM
			CALL mostrar_botones_detalle()
		END IF
		RETURN
	END IF
ELSE
	INITIALIZE vm_tipo_comp, vm_subtipo TO NULL
	LET rm_b10.b10_cuenta = arg_val(4)
	CALL validar_nivel_cuenta() RETURNING resul
	IF resul = 1 THEN
		EXIT PROGRAM
	END IF
	LET vm_fecha_ini      = DATE(arg_val(5))
	LET vm_fecha_fin      = DATE(arg_val(6))
	LET rm_b12.b12_moneda = arg_val(7)
END IF
IF resul <> 2 THEN
	CALL matches_cuenta(rm_b10.b10_cuenta) RETURNING cod_aux
ELSE
	LET cod_aux = rm_b10.b10_cuenta
END IF
LET query = 'SELECT b10_cuenta, b10_estado FROM ctbt010 ',
		' WHERE b10_compania = ', vg_codcia,
		'   AND b10_cuenta   MATCHES "', cod_aux, '"',
		'   AND b10_nivel    = ', vm_nivel
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO r_b10.b10_cuenta, r_b10.b10_estado
	IF r_b10.b10_estado = 'B' THEN
		SELECT COUNT(*) INTO cuantos
			FROM ctbt013
			WHERE b13_compania = vg_codcia
			  AND b13_cuenta   = r_b10.b10_cuenta
		IF cuantos = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET vm_r_rows[vm_num_rows] = r_b10.b10_cuenta
	LET vm_num_rows            = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 7 THEN
		EXIT PROGRAM
	END IF
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0, vm_num_det)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0, vm_num_det)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	IF int_flag THEN
		LET int_flag = 0
		IF num_args() = 7 THEN
			EXIT PROGRAM
		END IF
		RETURN
	END IF
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE resul		SMALLINT

OPTIONS INPUT NO WRAP
INITIALIZE cod_aux, mone_aux, r_mon.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_b10.b10_cuenta, vm_fecha_ini, vm_fecha_fin, rm_b12.b12_moneda
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT PROGRAM
	ON KEY(F2)
		IF INFIELD(b10_cuenta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
               	              	LET rm_b10.b10_cuenta = cod_aux
				DISPLAY BY NAME rm_b10.b10_cuenta 
				DISPLAY nom_aux TO b10_descripcion
			END IF 
		END IF
		IF INFIELD(rm_b12.b12_moneda) THEN
       	       		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
		      	LET int_flag = 0
       		       	IF mone_aux IS NOT NULL THEN
                      	      	LET rm_b12.b12_moneda = mone_aux
                       		DISPLAY BY NAME rm_b12.b12_moneda
                       		DISPLAY nomm_aux TO tit_moneda
                       	END IF
       	        END IF
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD b10_cuenta
		IF rm_b10.b10_cuenta IS NOT NULL THEN
			CALL validar_nivel_cuenta() RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b10_cuenta
			END IF
		ELSE
			CLEAR b10_descripcion
		END IF 
	AFTER FIELD b12_moneda
       		IF rm_b12.b12_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_b12.b12_moneda)
				RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
                              	CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
       	                       	NEXT FIELD b12_moneda
               	       	END IF
               	ELSE
       	               	LET rm_b12.b12_moneda = rg_gen.g00_moneda_base
               	       	CALL fl_lee_moneda(rm_b12.b12_moneda)
				RETURNING r_mon.*
                       	DISPLAY BY NAME rm_b12.b12_moneda
       	       	END IF
        	DISPLAY r_mon.g13_nombre TO tit_moneda
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_fin < vm_fecha_ini THEN
			CALL fgl_winmessage(vg_producto,'La fecha de término debe ser mayor a la fecha de inicio.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		CALL lee_parametros()
		IF int_flag THEN
			OPTIONS INPUT NO WRAP
			NEXT FIELD b10_cuenta
		END IF
		CALL obtener_saldo()
END INPUT
RETURN resul

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b04		RECORD LIKE ctbt004.*

OPTIONS INPUT WRAP
INITIALIZE vm_expr_sql, vm_tipo_comp, vm_subtipo TO NULL
LET int_flag = 0
CONSTRUCT BY NAME vm_expr_sql ON b13_tipo_comp, b12_subtipo
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(b13_tipo_comp) THEN
			CALL fl_ayuda_tipos_comprobantes(vg_codcia)
				RETURNING r_b03.b03_tipo_comp,
					  r_b03.b03_nombre
			IF r_b03.b03_tipo_comp IS NOT NULL THEN
				DISPLAY r_b03.b03_tipo_comp TO b13_tipo_comp
			END IF
		END IF
		IF INFIELD(b12_subtipo) THEN
			CALL fl_ayuda_subtipos_comprobantes(vg_codcia)
				RETURNING r_b04.b04_subtipo,
					  r_b04.b04_nombre
			IF r_b04.b04_subtipo IS NOT NULL THEN
				DISPLAY r_b04.b04_subtipo TO b12_subtipo
			END IF
		END IF
	AFTER FIELD b13_tipo_comp
		LET vm_tipo_comp = get_fldbuf(b13_tipo_comp)
	AFTER FIELD b12_subtipo
		LET vm_subtipo   = get_fldbuf(b12_subtipo)
END CONSTRUCT

END FUNCTION



FUNCTION validar_nivel_cuenta()
DEFINE r_ctb		RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, rm_b10.b10_cuenta) RETURNING r_ctb.*
IF r_ctb.b10_cuenta IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Cuenta no existe.','exclamation')
	RETURN 1
END IF
DISPLAY BY NAME r_ctb.b10_descripcion
IF r_ctb.b10_permite_mov = 'N' THEN
	CLEAR b10_descripcion
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 1
END IF
IF r_ctb.b10_nivel = vm_nivel THEN
	LET rm_b10.b10_nivel = vm_nivel
	RETURN 2
ELSE
	LET rm_b10.b10_nivel = r_ctb.b10_nivel + 1
END IF
RETURN 0

END FUNCTION



FUNCTION sacar_total()
DEFINE i	SMALLINT

LET vm_total_deb = 0
LET vm_total_cre = 0
FOR i = 1 TO vm_num_det
	LET vm_total_deb = vm_total_deb	+ rm_det[i].tit_debito
	LET vm_total_cre = vm_total_cre	+ rm_det[i].tit_credito
END FOR
DISPLAY vm_total_deb TO tit_total_deb
DISPLAY vm_total_cre TO tit_total_cre

END FUNCTION



FUNCTION muestra_siguiente_registro(i)
DEFINE i		SMALLINT

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(i, vm_num_det)
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF int_flag THEN
	IF num_args() = 7 THEN
		EXIT PROGRAM
	END IF
	RETURN
END IF

END FUNCTION



FUNCTION muestra_anterior_registro(i)
DEFINE i		SMALLINT

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(i, vm_num_det)
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF int_flag THEN
	IF num_args() = 7 THEN
		EXIT PROGRAM
	END IF
	RETURN
END IF

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 66
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	LIKE ctbt010.b10_cuenta
DEFINE r_mon		RECORD LIKE gent013.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_dt CURSOR FOR
	SELECT * FROM ctbt010
		WHERE b10_compania  = vg_codcia
		  AND b10_cuenta    = num_registro
OPEN q_dt
FETCH q_dt INTO rm_b10.*
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No existe registro con índice: ' || vm_row_current, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_b10.b10_cuenta, rm_b10.b10_descripcion
IF num_args() = 7 THEN
	DISPLAY BY NAME rm_b12.b12_moneda, vm_fecha_ini, vm_fecha_fin
	CALL fl_lee_moneda(rm_b12.b12_moneda) RETURNING r_mon.*
	DISPLAY r_mon.g13_nombre TO tit_moneda
END IF
CALL obtener_saldo()
CALL muestra_detalle(num_registro)
IF int_flag THEN
	IF num_args() = 7 THEN
		EXIT PROGRAM
	END IF
	IF vm_num_rows = 0 THEN
		RETURN
	END IF
END IF

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg		LIKE ctbt010.b10_cuenta
DEFINE query		VARCHAR(1400)
DEFINE i		SMALLINT
DEFINE saldo		DECIMAL(14,2)
DEFINE r_b12		RECORD LIKE ctbt012.*

LET int_flag = 0
CALL borrar_detalle()
LET query = 'SELECT ctbt013.*, ctbt012.*, ctbt013.ROWID ',
		' FROM ctbt012, ctbt013 ',
		' WHERE b12_compania  = ', vg_codcia,
		--'  AND b12_estado    <> "E" ',
		'   AND b12_estado    = "M" ',
		'   AND b12_moneda    = "', rm_b12.b12_moneda, '"',
		'   AND b12_fec_proceso BETWEEN "', vm_fecha_ini,
					 '" AND "', vm_fecha_fin, '"',
		'   AND b13_compania  = b12_compania ',
	        '   AND b13_tipo_comp = b12_tipo_comp ',
		'   AND b13_num_comp  = b12_num_comp ',
		'   AND b13_cuenta    = "', num_reg, '"',
		'   AND ', vm_expr_sql CLIPPED,
		' ORDER BY b13_fec_proceso ASC, b12_fecing ASC, ',
				'b13_tipo_comp, b13_num_comp '
		{--
		' ORDER BY b13_fec_proceso, ctbt013.ROWID, b13_tipo_comp, ',
				'b13_num_comp '
		--}
PREPARE cons1 FROM query	
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_det = 1
LET saldo = vm_saldo_al
FOREACH q_cons1 INTO rm_b13.*, r_b12.*
	LET rm_det[vm_num_det].b13_tipo_comp   = rm_b13.b13_tipo_comp
	LET rm_det[vm_num_det].b12_subtipo     = r_b12.b12_subtipo
	LET rm_det[vm_num_det].b13_num_comp    = rm_b13.b13_num_comp
	LET rm_det[vm_num_det].b13_fec_proceso = rm_b13.b13_fec_proceso
	CALL obtener_valores_deb_cre(vm_num_det)
	LET rm_det[vm_num_det].tit_saldo = saldo +
					   rm_det[vm_num_det].tit_debito + 
					   rm_det[vm_num_det].tit_credito
	LET saldo = rm_det[vm_num_det].tit_saldo
	LET tit_glosa[vm_num_det] = rm_b13.b13_glosa CLIPPED
	IF r_b12.b12_num_cheque IS NOT NULL THEN
		LET tit_glosa[vm_num_det] = 'Ch. ',
					r_b12.b12_num_cheque USING '&&&&#'
		IF r_b12.b12_benef_che IS NOT NULL THEN
			LET tit_glosa[vm_num_det] =
					tit_glosa[vm_num_det] CLIPPED, ' ',
					r_b12.b12_benef_che CLIPPED
		ELSE
			LET tit_glosa[vm_num_det] =
					tit_glosa[vm_num_det] CLIPPED, ' ',
					rm_b13.b13_glosa CLIPPED
		END IF
	END IF
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 7 THEN
		IF vm_num_rows <= 1 THEN
			EXIT PROGRAM
		END IF
	END IF
	IF num_args() <> 7 THEN
		IF vm_num_rows < 1 THEN
			LET vm_row_current = 0
			LET vm_num_rows    = 0
		END IF
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		CALL muestra_contadores_det(0, vm_num_det)
		IF vm_num_rows = 0 THEN
			RETURN
		END IF
	END IF
END IF
IF vm_num_det > 0 THEN
	LET int_flag = 0
	FOR i = 1 TO fgl_scr_size('rm_det')
		DISPLAY rm_det[i].* TO rm_det[i].*
	END FOR
END IF
CALL sacar_total()
CALL muestra_detalle_arr()
IF int_flag THEN
	IF num_args() = 7 THEN
		EXIT PROGRAM
	END IF
	RETURN
END IF

END FUNCTION



FUNCTION obtener_valores_deb_cre(i)
DEFINE i		SMALLINT

IF rm_b12.b12_moneda = rg_gen.g00_moneda_base THEN
	IF rm_b13.b13_valor_base >= 0 THEN
		LET rm_det[i].tit_debito  = rm_b13.b13_valor_base
		LET rm_det[i].tit_credito = 0
	ELSE
		LET rm_det[i].tit_debito  = 0
		LET rm_det[i].tit_credito = rm_b13.b13_valor_base
	END IF
ELSE
	IF rm_b13.b13_valor_aux >= 0 THEN
		LET rm_det[i].tit_debito  = rm_b13.b13_valor_aux
		LET rm_det[i].tit_credito = 0
	ELSE
		LET rm_det[i].tit_debito  = 0
		LET rm_det[i].tit_credito = rm_b13.b13_valor_aux
	END IF
END IF

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i,j		SMALLINT

CALL set_count(vm_num_det)
DISPLAY ARRAY rm_det TO rm_det.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		CALL ver_comprobante(i)
		LET int_flag = 0
	ON KEY(F6)
		CALL imprimir()
		LET int_flag = 0
	ON KEY(F7)
		IF vm_num_rows > 1 THEN
			IF vm_row_current <> vm_num_rows THEN
				CALL muestra_siguiente_registro(i)
				IF int_flag THEN
					EXIT DISPLAY
				END IF
			END IF
		END IF
	ON KEY(F8)
		IF vm_num_rows > 1 THEN
			IF vm_row_current > 1 THEN
				CALL muestra_anterior_registro(i)
				IF int_flag THEN
					EXIT DISPLAY
				END IF
			END IF
		END IF
	ON KEY(F9)
		CALL control_archivo()
		LET int_flag = 0
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F9","Archivo")
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL muestra_contadores_det(i, vm_num_det)
		IF vm_num_det = 0 THEN
			CALL muestra_contadores_det(0, vm_num_det)
		END IF
		IF vm_num_rows <= 1 THEN
			--#CALL dialog.keysetlabel("F7","")
			--#CALL dialog.keysetlabel("F8","")
		ELSE
			--#CALL dialog.keysetlabel("F7","Siguiente Cuenta")
			--#CALL dialog.keysetlabel("F8","Anterior Cuenta")
		END IF
		IF vm_row_current <= 1 THEN
			--#CALL dialog.keysetlabel("F8","")
		END IF
		IF vm_row_current = vm_num_rows THEN
			--#CALL dialog.keysetlabel("F7","")
		END IF
		DISPLAY BY NAME tit_glosa[i]
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY
IF int_flag THEN
	IF num_args() = 7 THEN
		EXIT PROGRAM
	END IF
	RETURN
END IF

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR b10_cuenta, b10_descripcion, vm_fecha_ini, vm_fecha_fin, b12_moneda, 
	tit_moneda, vm_saldo_fec, vm_saldo_al
INITIALIZE rm_b10.*, rm_b12, rm_b13.*, vm_saldo_fec, vm_saldo_al,
	vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0, vm_num_det)
LET vm_scr_lin = fgl_scr_size('rm_det')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR tit_total_deb, tit_total_cre, tit_glosa

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION mostrar_botones_detalle()

DISPLAY 'TP'      TO tit_col1
DISPLAY 'ST'      TO tit_col2
DISPLAY 'Número'  TO tit_col3
DISPLAY 'Fecha'   TO tit_col4
DISPLAY 'Débito'  TO tit_col5
DISPLAY 'Crédito' TO tit_col6
DISPLAY 'Saldo'   TO tit_col7

END FUNCTION



FUNCTION obtener_saldo()
DEFINE anho		SMALLINT
DEFINE mes 		SMALLINT
DEFINE val1		DECIMAL(16,2)

LET vm_saldo_fec = vm_fecha_ini - 1
IF rm_b10.b10_cuenta[1, 1] <> '3' THEN
	CALL fl_obtiene_saldo_contable(vg_codcia, rm_b10.b10_cuenta,
					rm_b12.b12_moneda, vm_saldo_fec, 'A')
		RETURNING vm_saldo_al
ELSE
	CALL fl_obtener_saldo_cuentas_patrimonio(vg_codcia, rm_b10.b10_cuenta,
				rm_b12.b12_moneda, vm_saldo_fec, TODAY, 'A')
		RETURNING vm_saldo_al, val1
END IF
DISPLAY BY NAME vm_saldo_al, vm_saldo_fec

END FUNCTION



FUNCTION matches_cuenta(cod_aux)
DEFINE r_niv		RECORD LIKE ctbt001.*
DEFINE cod_aux		LIKE ctbt010.b10_cuenta

CALL fl_lee_nivel_cuenta(rm_b10.b10_nivel) RETURNING r_niv.*
LET cod_aux[r_niv.b01_posicion_i, r_niv.b01_posicion_f] = '**'
RETURN cod_aux

END FUNCTION



FUNCTION ver_comprobante(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

IF vm_num_det = 0 THEN
	CALL fgl_winmessage(vg_producto,'No hay comprobante para mostrar.','exclamation')
	RETURN
END IF
LET param = '"', rm_det[i].b13_tipo_comp, '" ', '"', rm_det[i].b13_num_comp, '"'
CALL ejecuta_comando('CONTABILIDAD', vg_modulo, 'ctbp201 ', param)

END FUNCTION



FUNCTION imprimir()
DEFINE param		VARCHAR(100)

LET param = vg_codloc, ' "', rm_b10.b10_cuenta, '" "', rm_b10.b10_cuenta, '" "',
		vm_fecha_ini, '" "', vm_fecha_fin, '" "', rm_b12.b12_moneda, '"'
IF vm_tipo_comp IS NOT NULL THEN
	LET param = param CLIPPED, ' "', vm_tipo_comp, '"'
END IF
IF vm_subtipo IS NOT NULL THEN
	IF vm_tipo_comp IS NULL THEN
		LET param = param CLIPPED, ' "XX"'
	END IF
	LET param = param CLIPPED, ' ', vm_subtipo
END IF
CALL ejecuta_comando('CONTABILIDAD', vg_modulo, 'ctbp405 ', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(100)
DEFINE comando          VARCHAR(300)
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



FUNCTION control_archivo()
DEFINE resp		CHAR(6)
DEFINE registro		CHAR(800)
DEFINE subtipo		VARCHAR(10)
DEFINE valor_c		VARCHAR(20)
DEFINE i		SMALLINT

CALL fl_hacer_pregunta('Desea generar un archivo de texto ?', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
FOR i = 1 TO vm_num_det
	LET subtipo  = rm_det[i].b12_subtipo USING "<<<<<<"
	LET valor_c  = rm_det[i].tit_debito USING "#,###,###,##&.##"
	LET registro = rm_det[i].b13_tipo_comp CLIPPED, '|', subtipo CLIPPED,
			'|', rm_det[i].b13_num_comp CLIPPED, '|',
			rm_det[i].b13_fec_proceso USING "dd-mm-yyyy", '|',
			tit_glosa[i] CLIPPED, '|',
			valor_c USING "<<<<<<<<<<<<&.##", '|'
	LET valor_c  = rm_det[i].tit_credito USING "#,###,###,##&.##"
	LET registro = registro CLIPPED, valor_c USING "<<<<<<<<<<<<&.##", '|'
	LET valor_c  = rm_det[i].tit_saldo USING "#,###,###,##&.##"
	LET registro = registro CLIPPED, valor_c USING "<<<<<<<<<<<<&.##"
	DISPLAY registro CLIPPED
END FOR
RUN 'mv ctbp302.txt $HOME/tmp'
CALL fl_mostrar_mensaje('Se generó el Archivo ctbp302.txt', 'info')

END FUNCTION

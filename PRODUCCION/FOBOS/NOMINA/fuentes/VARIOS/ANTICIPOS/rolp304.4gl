--------------------------------------------------------------------------------
-- Titulo           : rolp304.4gl - Consulta de Anticipos
-- Elaboracion      : 11-Ago-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp304 base modulo compañía [estado]
--			[fecha_ini] [fecha_fin] [[cod_trab]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_cur_det	SMALLINT
DEFINE rm_detalle	ARRAY[20000] OF RECORD
				n45_num_prest	LIKE rolt045.n45_num_prest,
				cod_rubro	LIKE rolt045.n45_cod_rubro,
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n45_fecha	DATE,
				n45_val_prest	LIKE rolt045.n45_val_prest,
				n45_descontado	LIKE rolt045.n45_descontado,
				estado		LIKE rolt045.n45_estado
			END RECORD
DEFINE rm_n45		RECORD LIKE rolt045.*
DEFINE rm_n46		RECORD LIKE rolt046.*
DEFINE vm_proceso	LIKE rolt003.n03_proceso
DEFINE vm_fec_tope	DATE
DEFINE total_valor	DECIMAL(14,2)
DEFINE total_descont	DECIMAL(14,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp304.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 6 AND num_args() <> 7 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp304'
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
DEFINE r_n03		RECORD LIKE rolt003.*

CALL fl_nivel_isolation()
LET vm_proceso = 'AN'
CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso ANTICIPOS en la tabla rolt003.', 'stop')
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
OPEN WINDOW w_rolf304_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf304_1 FROM '../forms/rolf304_1'
ELSE
	OPEN FORM f_rolf304_1 FROM '../forms/rolf304_1c'
END IF
DISPLAY FORM f_rolf304_1
LET vm_max_det = 20000
LET vm_num_det = 0
LET vm_cur_det = 0
CALL mostrar_botones()
CALL muestra_contadores()
INITIALIZE rm_n45.*, rm_n46.* TO NULL
IF num_args() <> 3 THEN
	CALL llamar_otro_prog()
	CLOSE WINDOW w_rolf304_1
	EXIT PROGRAM
END IF
LET rm_n45.n45_estado    = 'V'
CALL muestra_estado(rm_n45.n45_estado)
CALL retorna_fec_ini_est(rm_n45.n45_estado)
SELECT NVL(MAX(DATE(n45_fecha)), TODAY)
	INTO vm_fec_tope
	FROM rolt045
	WHERE n45_compania  = vg_codcia
	  AND n45_estado   <> 'E'
IF vm_fec_tope IS NULL THEN
	LET vm_fec_tope = TODAY
END IF
LET rm_n46.n46_fecha_fin = vm_fec_tope
WHILE TRUE
	CALL borrar_detalle()
	CALL leer_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_consulta()
END WHILE
CLOSE WINDOW w_rolf304_1
EXIT PROGRAM

END FUNCTION



FUNCTION llamar_otro_prog()
DEFINE r_n30		RECORD LIKE rolt030.*

LET rm_n45.n45_estado    = arg_val(4)
CALL muestra_estado(rm_n45.n45_estado)
LET rm_n46.n46_fecha_ini = arg_val(5)
LET rm_n46.n46_fecha_fin = arg_val(6)
IF num_args() = 7 THEN
	LET rm_n45.n45_cod_trab = arg_val(7)
	CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab)
		RETURNING r_n30.*
	DISPLAY BY NAME	rm_n45.n45_cod_trab
	DISPLAY r_n30.n30_nombres TO tit_nombres
END IF
DISPLAY BY NAME rm_n46.n46_fecha_ini, rm_n46.n46_fecha_fin
CALL control_consulta()

END FUNCTION



FUNCTION leer_parametros()
DEFINE resul	 	SMALLINT
DEFINE fec_ini		LIKE rolt046.n46_fecha_ini
DEFINE fec_fin		LIKE rolt046.n46_fecha_fin
DEFINE estado		LIKE rolt045.n45_estado
DEFINE r_n03_2		RECORD LIKE rolt003.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n16		RECORD LIKE rolt016.*
DEFINE r_n18		RECORD LIKE rolt018.*
DEFINE r_n30		RECORD LIKE rolt030.*

CALL muestra_estado(rm_n45.n45_estado)
LET int_flag = 0
INPUT BY NAME rm_n45.n45_estado, rm_n46.n46_fecha_ini, rm_n46.n46_fecha_fin,
	rm_n45.n45_cod_rubro, rm_n46.n46_cod_liqrol, rm_n45.n45_cod_trab
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n45_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n45.n45_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n45.n45_cod_trab
				DISPLAY r_n30.n30_nombres TO tit_nombres
                        END IF
                END IF
		IF INFIELD(n45_cod_rubro) THEN
			CALL fl_ayuda_rubros_generales_roles('DE', 'T',	'T',
								 'T', 'T', 'T')
				RETURNING r_n06.n06_cod_rubro, 
					  r_n06.n06_nombre 
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_n45.n45_cod_rubro = r_n06.n06_cod_rubro
				DISPLAY BY NAME rm_n45.n45_cod_rubro,
						r_n06.n06_nombre
			END IF
		END IF
		IF INFIELD(n46_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n46.n46_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n46.n46_cod_liqrol,
						r_n03.n03_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD n45_estado
		LET estado = rm_n45.n45_estado
	BEFORE FIELD n46_fecha_ini
		LET fec_ini = rm_n46.n46_fecha_ini
	BEFORE FIELD n46_fecha_fin
		LET fec_fin = rm_n46.n46_fecha_fin
	AFTER FIELD n45_estado
		IF rm_n45.n45_estado IS NULL THEN
			LET rm_n45.n45_estado = estado
		END IF
		CALL muestra_estado(rm_n45.n45_estado)
		CALL retorna_fec_ini_est(rm_n45.n45_estado)
	AFTER FIELD n46_fecha_ini
		IF rm_n46.n46_fecha_ini IS NULL THEN
			LET rm_n46.n46_fecha_ini = fec_ini
			DISPLAY BY NAME rm_n46.n46_fecha_ini
		END IF
		IF rm_n46.n46_fecha_ini > vm_fec_tope THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual a la fecha maxima de anticipos.', 'exclamation')
			LET rm_n46.n46_fecha_ini = vm_fec_tope
			DISPLAY BY NAME rm_n46.n46_fecha_ini
			NEXT FIELD n46_fecha_ini
		END IF
	AFTER FIELD n46_fecha_fin
		IF rm_n46.n46_fecha_fin IS NULL THEN
			LET rm_n46.n46_fecha_fin = fec_fin
			DISPLAY BY NAME rm_n46.n46_fecha_fin
		END IF
		IF rm_n46.n46_fecha_fin > vm_fec_tope THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor o igual a la fecha maxima de anticipos.', 'exclamation')
			LET rm_n46.n46_fecha_fin = vm_fec_tope
			DISPLAY BY NAME rm_n46.n46_fecha_fin
			NEXT FIELD n46_fecha_fin
		END IF
	AFTER FIELD n45_cod_rubro
		IF rm_n45.n45_cod_rubro IS NOT NULL THEN
			CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro)
				RETURNING r_n06.*
			IF r_n06.n06_cod_rubro IS NULL  THEN
				CALL fl_mostrar_mensaje('Rubro no existe.','exclamation')
				NEXT FIELD n45_cod_rubro
			END IF
			DISPLAY BY NAME r_n06.n06_nombre
			IF r_n06.n06_det_tot <> 'DE' THEN
				CALL fl_mostrar_mensaje('El rubro debe ser de descuento.', 'exclamation')
				NEXT FIELD n45_cod_rubro
			END IF
			IF r_n06.n06_flag_ident IS NULL THEN
				CALL fl_mostrar_mensaje('El rubro no tiene identificacion de ANTICIPOS.', 'exclamation')
				NEXT FIELD n45_cod_rubro
			END IF
			INITIALIZE r_n18.* TO NULL
			SELECT * INTO r_n18.*
				FROM rolt018
				WHERE n18_cod_rubro  = rm_n45.n45_cod_rubro
				  AND n18_flag_ident = r_n06.n06_flag_ident
			IF (r_n06.n06_flag_ident <> vm_proceso AND
			    r_n06.n06_flag_ident <> r_n18.n18_flag_ident) OR
			    r_n18.n18_flag_ident IS NULL
			THEN
				CALL fl_mostrar_mensaje('El rubro debe ser un rubro con identificacion de ANTICIPOS.', 'exclamation')
				NEXT FIELD n45_cod_rubro
			END IF
			IF r_n06.n06_ing_usuario = 'N' AND
			   r_n06.n06_flag_ident <> vm_proceso AND
			   r_n06.n06_flag_ident <> r_n18.n18_flag_ident
			THEN
				CALL fl_mostrar_mensaje('El rubro no puede ser ingresado por el usuario.', 'exclamation')
				NEXT FIELD n45_cod_rubro
			END IF
			IF r_n06.n06_flag_ident = r_n18.n18_flag_ident THEN
				CALL fl_lee_proceso_roles(r_n18.n18_flag_ident)
					RETURNING r_n03_2.*
				IF r_n03_2.n03_proceso IS NULL THEN
					SELECT * INTO r_n16.*
						FROM rolt016
						WHERE n16_flag_ident =
							r_n18.n18_flag_ident
					CALL fl_mostrar_mensaje('No existe configurado el proceso ' || r_n16.n16_descripcion CLIPPED || ' en la tabla rolt003.', 'exclamation')
					NEXT FIELD n45_cod_rubro
				END IF
			END IF
		ELSE
			CLEAR n06_nombre
		END IF
	AFTER FIELD n46_cod_liqrol
		IF rm_n46.n46_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n46.n46_cod_liqrol)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n46_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			IF r_n03.n03_acep_descto = 'N' THEN
				CALL fl_mostrar_mensaje('Este código de proceso no esta permitido que acepte descuentos.', 'exclamation')
				NEXT FIELD n46_cod_liqrol
			END IF
			IF r_n03.n03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n46_cod_liqrol
			END IF
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n45_cod_trab
		IF rm_n45.n45_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n45.n45_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n45_cod_trab
			END IF
			DISPLAY r_n30.n30_nombres TO tit_nombres
		ELSE
			CLEAR tit_nombres
		END IF
	AFTER INPUT
		IF rm_n46.n46_fecha_fin < rm_n46.n46_fecha_ini THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor que la fecha inicial.', 'exclamation')
			NEXT FIELD n46_fecha_fin
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()
DEFINE i, j, resul	SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 3
WHILE TRUE
	CALL cargar_datos_det() RETURNING resul
	IF resul THEN
		EXIT WHILE
	END IF
	CALL mostrar_detalle()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION cargar_datos_det()
DEFINE query		CHAR(2500)
DEFINE expr_rubr	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_esta	VARCHAR(100)
DEFINE tabla		VARCHAR(15)
DEFINE expr_sal		VARCHAR(150)
DEFINE expr_sal2	VARCHAR(100)
DEFINE expr_val		CHAR(300)
DEFINE expr_join	CHAR(300)
DEFINE expr_gru		VARCHAR(50)

LET expr_rubr = NULL
IF rm_n45.n45_cod_rubro IS NOT NULL THEN
	LET expr_rubr = '  AND n45_cod_rubro = ', rm_n45.n45_cod_rubro
END IF
LET expr_trab = NULL
IF rm_n45.n45_cod_trab IS NOT NULL THEN
	LET expr_trab = '  AND n45_cod_trab  = ', rm_n45.n45_cod_trab
END IF
LET expr_esta = NULL
IF rm_n45.n45_estado <> 'X' AND rm_n45.n45_estado <> 'V' THEN
	LET expr_esta = '  AND n45_estado    = "', rm_n45.n45_estado, '"'
ELSE
	IF rm_n45.n45_estado = 'V' THEN
		LET expr_esta = '  AND n45_estado IN ("A", "R") '
	END IF
END IF
LET tabla     = NULL
LET expr_val  = ' n45_val_prest + n45_valor_int + n45_sal_prest_ant, '
LET expr_sal  = ' n45_val_prest + n45_valor_int + n45_sal_prest_ant -',
		' n45_descontado, '
LET expr_join = NULL
LET expr_gru  = NULL
IF rm_n46.n46_cod_liqrol IS NOT NULL THEN
	LET tabla     = ' rolt046,'
	LET expr_val  = ' NVL((SELECT SUM(n58_valor_dist) ',
				'FROM rolt058 ',
				'WHERE n58_compania  = n46_compania ',
				'  AND n58_num_prest = n46_num_prest ',
				'  AND n58_proceso   = n46_cod_liqrol), ',
				'0) valor, '
	LET expr_sal  = ' NVL(SUM(n46_saldo), 0) saldo, '
	LET expr_sal2 = NULL
	IF rm_n45.n45_estado = 'A' OR rm_n45.n45_estado = 'R' OR
	   rm_n45.n45_estado = 'V'
	THEN
		LET expr_sal2 = '   AND n46_saldo      > 0 '
	ELSE
	END IF
	LET expr_join = '   AND n46_compania   = n45_compania ',
			'   AND n46_num_prest  = n45_num_prest ',
			'   AND n46_cod_liqrol = "', rm_n46.n46_cod_liqrol, '"',
			expr_sal2 CLIPPED
	LET expr_gru  = ' GROUP BY 1, 2, 3, 4, 5, 6, 8'
END IF
LET query = 'SELECT n45_num_prest, n45_cod_rubro, n30_cod_trab, n30_nombres, ',
		' DATE(n45_fecha) fecha, ', expr_val CLIPPED, expr_sal CLIPPED,
		' n45_estado ',
		' FROM rolt045,', tabla CLIPPED, ' rolt030 ',
		' WHERE n45_compania   = ', vg_codcia,
		expr_rubr CLIPPED,
		expr_trab CLIPPED,
		expr_esta CLIPPED,
		'   AND DATE(n45_fecha) BETWEEN "', rm_n46.n46_fecha_ini,
				  	 '" AND "', rm_n46.n46_fecha_fin, '"',
		'   AND n45_compania   = n30_compania ',
		'   AND n45_cod_trab   = n30_cod_trab ',
		expr_join CLIPPED,
		expr_gru CLIPPED,
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
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
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE j, col		SMALLINT

CALL mostrar_totales()
LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET vm_cur_det = arr_curr()
		CALL ver_anticipo()
		LET int_flag = 0
	ON KEY(F6)
		LET vm_cur_det = arr_curr()
		IF lee_cancelacion() IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL control_cancelacion()
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
	ON KEY(F22)
		LET col = 8
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#LET vm_cur_det = arr_curr()
	--#BEFORE ROW 
		--#LET vm_cur_det = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores()
		--#CALL muestra_estado(rm_detalle[vm_cur_det].estado)
		--#CALL muestra_tot_dividendo(
					rm_detalle[vm_cur_det].n45_num_prest)
		--#IF lee_cancelacion() IS NULL THEN
			--#CALL dialog.keysetlabel("F6","") 
		--#ELSE
			--#CALL dialog.keysetlabel("F6","Cancelacion") 
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
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

END FUNCTION



FUNCTION mostrar_totales()
DEFINE i		SMALLINT

LET total_valor   = 0
LET total_descont = 0
FOR i = 1 TO vm_num_det
	LET total_valor   = total_valor   + rm_detalle[i].n45_val_prest
	LET total_descont = total_descont + rm_detalle[i].n45_descontado
END FOR
DISPLAY BY NAME total_valor, total_descont

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Ant.'			TO tit_col1
DISPLAY 'Rub.'			TO tit_col2
DISPLAY 'Cod.'			TO tit_col3
DISPLAY 'E m p l e a d o s'	TO tit_col4
DISPLAY 'Fecha'			TO tit_col5
DISPLAY 'Valor'			TO tit_col6
DISPLAY 'Saldo'			TO tit_col7
DISPLAY 'E'			TO tit_col8

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_cur_det, vm_num_det

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR total_valor, total_descont, tot_div, sal_div, vm_cur_det, vm_num_det

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		LIKE rolt045.n45_estado

DISPLAY estado TO n45_estado
CASE estado
	WHEN 'A'
		DISPLAY 'ACTIVO'        TO tit_estado
	WHEN 'P'
		DISPLAY 'PROCESADO'     TO tit_estado
	WHEN 'T'
		DISPLAY 'TRANSFERIDO'   TO tit_estado
	WHEN 'R'
		DISPLAY 'REDISTRIBUIDO' TO tit_estado
	WHEN 'E'
		DISPLAY 'ELIMINADO'     TO tit_estado
	WHEN 'V'
		DISPLAY 'VIGENTES'      TO tit_estado
	WHEN 'X'
		DISPLAY 'T O D O S'     TO tit_estado
	OTHERWISE
		CLEAR n45_estado, tit_estado
END CASE

END FUNCTION



FUNCTION muestra_tot_dividendo(num_prest)
DEFINE num_prest	LIKE rolt045.n45_num_prest
DEFINE tot_div, sal_div	INTEGER

CALL retorna_num_dividendo(num_prest, 1) RETURNING tot_div
CALL retorna_num_dividendo(num_prest, 2) RETURNING sal_div
DISPLAY BY NAME tot_div, sal_div

END FUNCTION



FUNCTION retorna_num_dividendo(num_prest, flag)
DEFINE num_prest	LIKE rolt045.n45_num_prest
DEFINE flag		SMALLINT
DEFINE query		CHAR(400)
DEFINE expr_sql		VARCHAR(100)
DEFINE campo		VARCHAR(15)
DEFINE num_div		INTEGER

LET expr_sql = NULL
IF rm_n46.n46_cod_liqrol IS NOT NULL THEN
	LET expr_sql = '   AND n46_cod_liqrol = "', rm_n46.n46_cod_liqrol, '"'
END IF
CASE flag
	WHEN 1 LET campo = 'n46_valor'
	WHEN 2 LET campo = 'n46_saldo'
END CASE
LET query = 'SELECT COUNT(', campo CLIPPED, ') ',
		' FROM rolt046 ',
		' WHERE n46_compania   = ', vg_codcia,
		'   AND n46_num_prest  = ', num_prest,
		expr_sql CLIPPED
IF flag = 2 THEN
	LET query = query CLIPPED,
			'   AND n46_saldo      > 0 '
END IF
PREPARE cons_div1 FROM query
DECLARE q_div1 CURSOR FOR cons_div1
OPEN q_div1
FETCH q_div1 INTO num_div
CLOSE q_div1
FREE q_div1
RETURN num_div

END FUNCTION



FUNCTION ver_anticipo()
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[vm_cur_det].n45_num_prest
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp214 ', param)

END FUNCTION


 
FUNCTION control_cancelacion()
DEFINE r_canc		ARRAY[100] OF RECORD
				cod_c		LIKE rolt091.n91_num_ant,
				fecha		LIKE rolt091.n91_fecha_ant,
				motivo		LIKE rolt091.n91_motivo_ant,
				valor		LIKE rolt091.n91_valor_ant,
				tipo		LIKE rolt091.n91_tipo_pago
			END RECORD
DEFINE r_adi		ARRAY[100] OF RECORD
				n91_bco_empresa	LIKE rolt091.n91_bco_empresa,
				g08_nombre	LIKE gent008.g08_nombre,
				n91_cta_empresa	LIKE rolt091.n91_cta_empresa,
				n91_cta_trabaj	LIKE rolt091.n91_cta_trabaj
			END RECORD
DEFINE t_val_canc	LIKE rolt091.n91_valor_ant
DEFINE cuantos		INTEGER
DEFINE num_row, max_row	SMALLINT

SELECT COUNT(UNIQUE n91_num_ant)
	INTO cuantos
	FROM rolt091, rolt092
	WHERE n91_compania  = vg_codcia
	  AND n91_proceso   = 'CA'
	  AND n91_cod_trab  = rm_detalle[vm_cur_det].n30_cod_trab
	  AND n92_compania  = n91_compania
	  AND n92_proceso   = n91_proceso
	  AND n92_cod_trab  = n91_cod_trab
	  AND n92_num_ant   = n91_num_ant
	  AND n92_num_prest = rm_detalle[vm_cur_det].n45_num_prest
IF cuantos = 1 THEN
	CALL ver_cancelacion(0)
	RETURN
END IF
LET max_row = 100
OPEN WINDOW w_rolf304_2 AT 07, 12
	WITH FORM '../../NOMINA/forms/rolf304_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0, BORDER)
--#DISPLAY "Cod."	TO tit_col1
--#DISPLAY "Fecha"	TO tit_col2
--#DISPLAY "Motivo"	TO tit_col3
--#DISPLAY "Val. Canc."	TO tit_col4
--#DISPLAY "T"		TO tit_col5
DECLARE q_n91_2 CURSOR FOR
	SELECT n91_num_ant, n91_fecha_ant, n91_motivo_ant, n91_valor_ant,
		n91_tipo_pago, n91_bco_empresa, g08_nombre, n91_cta_empresa,
		n91_cta_trabaj
		FROM rolt091, OUTER gent008
		WHERE n91_compania  = vg_codcia
		  AND n91_proceso   = 'CA'
		  AND n91_cod_trab  = rm_detalle[vm_cur_det].n30_cod_trab
		  AND EXISTS
			(SELECT 1 FROM rolt092
			WHERE n92_compania  = n91_compania
			  AND n92_proceso   = n91_proceso
			  AND n92_cod_trab  = n91_cod_trab
			  AND n92_num_ant   = n91_num_ant
			  AND n92_num_prest =
					rm_detalle[vm_cur_det].n45_num_prest)
		  AND g08_banco     = n91_bco_empresa
		ORDER BY n91_num_ant, n91_fecha_ant
LET num_row    = 1
LET t_val_canc = 0
FOREACH q_n91_2 INTO r_canc[num_row].*, r_adi[num_row].*
	LET t_val_canc = t_val_canc + r_canc[num_row].valor
	LET num_row    = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_rolf304_2
	RETURN
END IF
DISPLAY BY NAME rm_detalle[vm_cur_det].n30_cod_trab,
		rm_detalle[vm_cur_det].n30_nombres, t_val_canc
LET max_row  = num_row
LET int_flag = 0
CALL set_count(max_row)
DISPLAY ARRAY r_canc TO r_canc.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET num_row = arr_curr()
		CALL ver_cancelacion(r_canc[num_row].cod_c)
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW
		--#LET num_row = arr_curr()
		--#DISPLAY BY NAME num_row, max_row, r_adi[num_row].*
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CLOSE WINDOW w_rolf304_2
RETURN

END FUNCTION



FUNCTION ver_cancelacion(cancelacion)
DEFINE cancelacion	LIKE rolt091.n91_num_ant
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[vm_cur_det].n30_cod_trab, ' '
IF cancelacion = 0 THEN
	LET param = param CLIPPED, ' ', lee_cancelacion()
ELSE
	LET param = param CLIPPED, ' ', cancelacion
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp255 ', param)

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



FUNCTION lee_cancelacion()
DEFINE num_can		LIKE rolt091.n91_num_ant

INITIALIZE num_can TO NULL
DECLARE q_canc CURSOR FOR
	SELECT n91_num_ant
		FROM rolt091, rolt092
		WHERE n91_compania  = vg_codcia
		  AND n91_proceso   = 'CA'
		  AND n91_cod_trab  = rm_detalle[vm_cur_det].n30_cod_trab
		  AND n92_compania  = n91_compania
		  AND n92_proceso   = n91_proceso
		  AND n92_cod_trab  = n91_cod_trab
		  AND n92_num_ant   = n91_num_ant
		  AND n92_num_prest = rm_detalle[vm_cur_det].n45_num_prest
OPEN q_canc
FETCH q_canc INTO num_can
CLOSE q_canc
FREE q_canc
RETURN num_can

END FUNCTION



FUNCTION retorna_fec_ini_est(estado)
DEFINE estado		LIKE rolt045.n45_estado
DEFINE query		CHAR(400)
DEFINE expr_est		VARCHAR(100)

LET expr_est = '   AND n45_estado   = "', estado, '"'
IF estado = 'V' THEN
	LET expr_est = '   AND n45_estado   IN ("A", "R")'
END IF
IF estado = 'X' THEN
	LET expr_est = NULL
END IF
LET query = 'SELECT NVL(MIN(DATE(n45_fecing)), TODAY) ',
		'FROM rolt045 ',
		'WHERE n45_compania = ', vg_codcia,
		expr_est CLIPPED
PREPARE cons_fec FROM query
DECLARE q_cons_fec CURSOR FOR cons_fec
OPEN q_cons_fec
FETCH q_cons_fec INTO rm_n46.n46_fecha_ini
CLOSE q_cons_fec
FREE q_cons_fec

END FUNCTION

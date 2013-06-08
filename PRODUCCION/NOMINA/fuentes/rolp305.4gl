--------------------------------------------------------------------------------
-- Titulo           : rolp305.4gl - Consulta de Valores por Rubro
-- Elaboracion      : 16-Feb-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp305 base modulo compañía
--			[cod_liqrol] [fecha_ini] [fecha_fin] [[cod_depto]]
--			[[cod_trab]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE i_cor, max_col	SMALLINT
DEFINE rm_detalle	ARRAY[500] OF RECORD
				cod_depto	LIKE rolt032.n32_cod_depto,
				n32_cod_trab	LIKE rolt032.n32_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				total_ing	DECIMAL(14,2),
				total_egr	DECIMAL(14,2),
				total_net	DECIMAL(14,2)
			END RECORD
DEFINE vm_tot_col	ARRAY[3] OF SMALLINT
DEFINE rubro_cons	ARRAY[3] OF RECORD
				cod	ARRAY[3] OF LIKE rolt006.n06_cod_rubro
			END RECORD
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE vm_trab_t	LIKE rolt032.n32_cod_trab
DEFINE vm_depto_t	LIKE rolt032.n32_cod_depto
DEFINE cod_aux		LIKE rolt030.n30_cod_trab
DEFINE tit_mes		VARCHAR(10)
DEFINE total_ing_gen	DECIMAL(14,2)
DEFINE total_egr_gen	DECIMAL(14,2)
DEFINE total_net_gen	DECIMAL(14,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_opcion	SMALLINT
DEFINE vm_pan, vm_arr	INTEGER
DEFINE pos_pan, pos_arr	INTEGER
DEFINE flag_p, flag_d	SMALLINT
DEFINE col1, col2	SMALLINT
DEFINE pos1, pos2	CHAR(4)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp305.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 6 AND num_args() <> 7
   AND num_args() <> 8
THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp305'
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
DEFINE resul	 	SMALLINT

CALL fl_nivel_isolation()
CREATE TEMP TABLE temp_detalle(
		cod_depto	INTEGER,
		n32_cod_trab	INTEGER,
		n30_nombres	VARCHAR(45,25),
		total_ing	DECIMAL(14,2),
		total_egr	DECIMAL(14,2),
		total_net	DECIMAL(14,2)
	)
CREATE TEMP TABLE temp_rubros(
		cod_trab	INTEGER,
		nombres		VARCHAR(45,25),
		cod_rubro	SMALLINT,
		orden_rub	SMALLINT,
		det_tot_r	CHAR(2),
		imprime_0	CHAR(1),
		valor_rub	DECIMAL(12,2)
	)
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 14
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf305_1 FROM '../forms/rolf305_1'
ELSE
	OPEN FORM f_rolf305_1 FROM '../forms/rolf305_1c'
END IF
DISPLAY FORM f_rolf305_1
LET vm_max_det = 500
LET max_col    = 3
IF num_args() <> 3 THEN
	CALL llamada_otro_prog()
	RETURN
END IF
CALL cargar_datos_liq() RETURNING resul
IF resul THEN
	RETURN
END IF
WHILE TRUE
	CLEAR FORM
	INITIALIZE rm_n32.n32_cod_depto, rm_n32.n32_cod_trab TO NULL
	LET vm_num_det = 0
	CALL encerar_tot(0)
	CALL encerar_rub()
	CALL mostrar_datos_liq()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_consulta_detalle()
END WHILE
DROP TABLE temp_detalle
DROP TABLE temp_rubros

END FUNCTION



FUNCTION llamada_otro_prog()

INITIALIZE rm_n32.*, vm_trab_t, vm_depto_t TO NULL
LET vm_num_det            = 0
LET rm_n32.n32_cod_liqrol = arg_val(4)
LET rm_n32.n32_fecha_ini  = arg_val(5)
LET rm_n32.n32_fecha_fin  = arg_val(6)
IF num_args() = 7 THEN
	LET rm_n32.n32_cod_depto = arg_val(7)
	LET vm_depto_t           = rm_n32.n32_cod_depto
END IF
IF num_args() = 8 THEN
	LET rm_n32.n32_cod_depto = arg_val(7)
	LET vm_depto_t           = rm_n32.n32_cod_depto
	LET rm_n32.n32_cod_trab  = arg_val(8)
	LET vm_trab_t            = rm_n32.n32_cod_trab
END IF
CALL control_consulta_detalle()
DROP TABLE temp_detalle
DROP TABLE temp_rubros

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)

INITIALIZE rm_n32.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN 1
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN 1
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	RETURN 1
END IF
LET rm_n32.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_n32.n32_mes_proceso = r_n01.n01_mes_proceso
CALL retorna_mes()
INITIALIZE r_n05.* TO NULL
DECLARE q_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania = vg_codcia
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
		ORDER BY n05_fecfin_act DESC
OPEN q_n05
FETCH q_n05 INTO r_n05.*
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania   = r_n05.n05_compania
		  --AND n32_cod_liqrol = r_n05.n05_proceso
		  AND n32_estado     <> 'E'
		ORDER BY n32_fecha_fin DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
LET rm_n32.n32_cod_liqrol  = r_n32.n32_cod_liqrol
LET rm_n32.n32_fecha_ini   = r_n32.n32_fecha_ini
LET rm_n32.n32_fecha_fin   = r_n32.n32_fecha_fin
LET rm_n32.n32_ano_proceso = r_n32.n32_ano_proceso
LET rm_n32.n32_mes_proceso = r_n32.n32_mes_proceso
CALL retorna_mes()
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq()
DEFINE r_n03		RECORD LIKE rolt003.*

CALL retorna_mes()
DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_fecha_ini,
		rm_n32.n32_fecha_fin, rm_n32.n32_ano_proceso,
		rm_n32.n32_mes_proceso, tit_mes
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE mes_aux		LIKE rolt032.n32_mes_proceso

LET int_flag = 0
INPUT BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_ano_proceso,
	rm_n32.n32_mes_proceso, rm_n32.n32_cod_depto, rm_n32.n32_cod_trab
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(n32_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n32.n32_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n32.n32_cod_liqrol,
						r_n03.n03_nombre  
			END IF
		END IF
		IF INFIELD(n32_mes_proceso) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET rm_n32.n32_mes_proceso = mes_aux
				DISPLAY BY NAME rm_n32.n32_mes_proceso, tit_mes
			END IF
                END IF
		IF INFIELD(n32_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_n32.n32_cod_depto = r_g34.g34_cod_depto
                                DISPLAY BY NAME rm_n32.n32_cod_depto,
						r_g34.g34_nombre
                        END IF
                END IF
		IF INFIELD(n32_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n32.n32_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n32.n32_cod_trab,
						r_n30.n30_nombres
                        END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD n32_ano_proceso
		LET anio = rm_n32.n32_ano_proceso
	BEFORE FIELD n32_mes_proceso
		LET mes = rm_n32.n32_mes_proceso
	AFTER FIELD n32_cod_liqrol
		IF rm_n32.n32_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n32_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			CALL mostrar_fechas()
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n32_ano_proceso
		IF rm_n32.n32_ano_proceso IS NOT NULL THEN
			IF rm_n32.n32_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n32_ano_proceso
			END IF
		ELSE
			LET rm_n32.n32_ano_proceso = anio
			DISPLAY BY NAME rm_n32.n32_ano_proceso
		END IF
		CALL mostrar_fechas()
	AFTER FIELD n32_mes_proceso
		IF rm_n32.n32_mes_proceso IS NULL THEN
			LET rm_n32.n32_mes_proceso = mes
			DISPLAY BY NAME rm_n32.n32_mes_proceso
		END IF
		CALL retorna_mes()
		DISPLAY BY NAME tit_mes
		CALL mostrar_fechas()
	AFTER FIELD n32_cod_depto
                IF rm_n32.n32_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_n32.n32_cod_depto)
                                RETURNING r_g34.*
                        IF r_g34.g34_compania IS NULL  THEN
                                CALL fgl_winmessage(vg_producto, 'Departamento no existe.','exclamation')
                                NEXT FIELD n32_cod_depto
                        END IF
                        DISPLAY BY NAME r_g34.g34_nombre
		ELSE
			CLEAR g34_nombre
                END IF
	AFTER FIELD n32_cod_trab
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n32.n32_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n32_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
		ELSE
			CLEAR n30_nombres
		END IF
END INPUT
LET vm_depto_t = rm_n32.n32_cod_depto
LET vm_trab_t  = rm_n32.n32_cod_trab

END FUNCTION



FUNCTION control_consulta_detalle()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul, col, i 	SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*

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
OPEN WINDOW w_rol2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf305_2 FROM '../forms/rolf305_2'
ELSE
	OPEN FORM f_rolf305_2 FROM '../forms/rolf305_2c'
END IF
DISPLAY FORM f_rolf305_2
CALL mostrar_botones_detalle1()
CALL preparar_query1() RETURNING resul
IF resul THEN
	CLOSE WINDOW w_rol2
	RETURN
END IF
DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_fecha_ini,
		rm_n32.n32_fecha_fin, rm_n32.n32_cod_depto
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre
CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto) RETURNING r_g34.*
DISPLAY BY NAME r_g34.g34_nombre
LET vm_pan = 1
LET vm_arr = 1
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 3
LET vm_columna_2  = 1
LET vm_columna_1  = col
LET rm_orden[col] = 'ASC'
LET pos_pan       = vm_pan
LET pos_arr       = vm_arr
LET col           = vm_columna_1
LET col1          = vm_columna_1
LET col2          = vm_columna_2
LET pos1          = rm_orden[col1]
LET pos2          = rm_orden[col2]
LET flag_p        = 0
LET flag_d        = 0
LET vm_opcion     = 3
WHILE TRUE
	CALL cargar_det_tmp()
	IF flag_d THEN
		FOR i = 1 TO vm_num_det
			IF cod_aux = rm_detalle[i].n32_cod_trab THEN
				LET pos_arr = i
				IF vm_num_det <= fgl_scr_size('rm_detalle') THEN
					LET pos_pan = i
				END IF
				EXIT FOR
			END IF
		END FOR
	END IF
	CALL mostrar_detalle()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
DELETE FROM temp_detalle
DELETE FROM temp_rubros
CLOSE WINDOW w_rol2
RETURN

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE i, j, col	SMALLINT
DEFINE opcion		SMALLINT

CALL mostrar_totales_gen()
LET opcion   = vm_opcion
LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET vm_pan   = scr_line()
		LET vm_arr   = arr_curr()
		LET int_flag = 1
               	EXIT DISPLAY  
	ON KEY(F5)
		LET i     = arr_curr()	
		LET i_cor = i
		CALL mostrar_empleado()
		LET int_flag = 0
	ON KEY(F6)
		LET i     = arr_curr()	
		LET i_cor = i
		CALL mostrar_liquidacion("L")
		LET int_flag = 0
	ON KEY(F7)
		LET i     = arr_curr()	
		LET i_cor = i
		CALL mostrar_liquidacion("I")
		LET int_flag = 0
	ON KEY(F8)
		LET i     = arr_curr()	
		LET i_cor = i
		CALL mostrar_liquidacion("T")
		LET int_flag = 0
	ON KEY(F9)
		CALL imprimir_listado()
		LET int_flag = 0
	{
	ON KEY(F10)
		IF cuantas_columnas(opcion) <= max_col THEN
			CONTINUE DISPLAY
		END IF
		LET pos_pan        = scr_line()
		LET pos_arr        = arr_curr()
		LET col            = col1
		LET vm_columna_1   = col1
		LET vm_columna_2   = col2
		LET rm_orden[col1] = pos1
		LET rm_orden[col2] = pos2
		LET flag_p         = 1
		CALL cambiar_columnas2(opcion, 1)
		CALL dialog.setcurrline(pos_pan, pos_arr)
		CALL muestra_contadores_detalle(pos_arr, vm_num_det)
		LET flag_d = 0
		IF cuantas_columnas(opcion) > max_col THEN
			--#CALL dialog.keysetlabel("F10","Anteriores Rubros") 
			--#CALL dialog.keysetlabel("F11","Siguientes Rubros") 
		ELSE
			--#CALL dialog.keysetlabel("F10","") 
			--#CALL dialog.keysetlabel("F11","") 
		END IF
		CONTINUE DISPLAY
	}
	ON KEY(F11)
		IF cuantas_columnas(opcion) <= max_col THEN
			CONTINUE DISPLAY
		END IF
		LET pos_pan        = scr_line()
		LET pos_arr        = arr_curr()
		LET col            = col1
		LET vm_columna_1   = col1
		LET vm_columna_2   = col2
		LET rm_orden[col1] = pos1
		LET rm_orden[col2] = pos2
		LET flag_p         = 1
		CALL cambiar_columnas(opcion, 1)
		CALL dialog.setcurrline(pos_pan, pos_arr)
		CALL muestra_contadores_detalle(pos_arr, vm_num_det)
		LET flag_d = 0
		IF cuantas_columnas(opcion) > max_col THEN
			--#CALL dialog.keysetlabel("F10","Anteriores Rubros") 
			--#CALL dialog.keysetlabel("F11","Siguientes Rubros") 
		ELSE
			--#CALL dialog.keysetlabel("F10","") 
			--#CALL dialog.keysetlabel("F11","") 
		END IF
		CONTINUE DISPLAY
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
		LET opcion = opcion + 1
		IF opcion > max_col THEN
			LET opcion = 1
		END IF
		LET pos_pan        = scr_line()
		LET pos_arr        = arr_curr()
		LET col            = col1
		LET vm_columna_1   = col1
		LET vm_columna_2   = col2
		LET rm_orden[col1] = pos1
		LET rm_orden[col2] = pos2
		LET flag_p         = 1
		IF vm_tot_col[opcion] = cuantas_columnas(opcion) THEN
			CALL encerar_tot(0)
		END IF
		CALL cambiar_columnas(opcion, 0)
		CALL dialog.setcurrline(pos_pan, pos_arr)
		CALL muestra_contadores_detalle(pos_arr, vm_num_det)
		LET flag_d = 0
		IF cuantas_columnas(opcion) > max_col THEN
			--#CALL dialog.keysetlabel("F10","Anteriores Rubros") 
			--#CALL dialog.keysetlabel("F11","Siguientes Rubros") 
		ELSE
			--#CALL dialog.keysetlabel("F10","") 
			--#CALL dialog.keysetlabel("F11","") 
		END IF
		IF vm_tot_col[opcion] = cuantas_columnas(opcion) THEN
			CALL encerar_tot(0)
		END IF
		LET vm_opcion = opcion
		CONTINUE DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		CALL dialog.setcurrline(pos_pan, pos_arr)
		CALL muestra_contadores_detalle(pos_arr, vm_num_det)
		CALL mostrar_contadores_rub(vm_tot_col[opcion],
						cuantas_columnas(opcion))
		IF cuantas_columnas(opcion) > max_col THEN
			--#CALL dialog.keysetlabel("F10","Anteriores Rubros") 
			--#CALL dialog.keysetlabel("F11","Siguientes Rubros") 
		ELSE
			--#CALL dialog.keysetlabel("F10","") 
			--#CALL dialog.keysetlabel("F11","") 
		END IF
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_detalle(i, vm_num_det)
		CALL mostrar_datos_det_cab(i)
		IF flag_d THEN
			CALL dialog.setcurrline(pos_pan, pos_arr)
			CALL muestra_contadores_detalle(pos_arr, vm_num_det)
			LET flag_d = 0
			CALL mostrar_datos_det_cab(pos_arr)
		END IF
		IF cuantas_columnas(opcion) > max_col THEN
			--#CALL dialog.keysetlabel("F10","Anteriores Rubros") 
			--#CALL dialog.keysetlabel("F11","Siguientes Rubros") 
		ELSE
			--#CALL dialog.keysetlabel("F10","") 
			--#CALL dialog.keysetlabel("F11","") 
		END IF
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
CASE flag_p
	WHEN 1
		LET col            = col1
		LET vm_columna_1   = col1
		LET vm_columna_2   = col2
		LET rm_orden[col1] = pos1
		LET rm_orden[col2] = pos2
		LET flag_p         = 0
	WHEN 0
		LET col1   = vm_columna_1
		LET col2   = vm_columna_2
		LET pos1   = rm_orden[col1]
		LET pos2   = rm_orden[col2]
		LET flag_d = 1
END CASE
IF flag_d THEN
	LET pos_pan = scr_line()
	LET pos_arr = arr_curr()
	LET cod_aux = rm_detalle[pos_arr].n32_cod_trab
END IF

END FUNCTION



FUNCTION cuantas_columnas(opc)
DEFINE opc		SMALLINT
DEFINE query		VARCHAR(250)
DEFINE expr_rub		VARCHAR(100)
DEFINE cuantos		INTEGER

CASE opc
	WHEN 1
		LET expr_rub = " WHERE det_tot_r = 'DI'"
	WHEN 2
		LET expr_rub = " WHERE det_tot_r = 'DE'"
	WHEN 3
		LET expr_rub = " WHERE det_tot_r IN ('TG', 'TI', 'TE', 'TN')"
	OTHERWISE
		LET expr_rub = " WHERE det_tot_r IN ('TG', 'TI', 'TE', 'TN')"
END CASE
LET query = "SELECT COUNT(UNIQUE cod_rubro) ctos FROM temp_rubros ",
		expr_rub CLIPPED,
		' INTO TEMP t1 '
PREPARE exec_cont FROM query
EXECUTE exec_cont
SELECT * INTO cuantos FROM t1
DROP TABLE t1
RETURN cuantos

END FUNCTION



FUNCTION cambiar_columnas(opc, act)
DEFINE opc, act		SMALLINT
DEFINE r_te		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				cod_rubro	LIKE rolt033.n33_cod_rubro,
				orden_rub	LIKE rolt033.n33_orden,
				det_tot_r	LIKE rolt033.n33_det_tot,
				imprime_0	LIKE rolt033.n33_imprime_0,
				valor_rub	LIKE rolt033.n33_valor
			END RECORD
DEFINE cod_r		LIKE rolt033.n33_cod_rubro
DEFINE query		VARCHAR(250)
DEFINE expr_rub		VARCHAR(100)
DEFINE i, j, l, aux_d	SMALLINT

CASE opc
	WHEN 1
		LET expr_rub = " WHERE det_tot_r = 'DI'"
	WHEN 2
		LET expr_rub = " WHERE det_tot_r = 'DE'"
	WHEN 3
		LET expr_rub = " WHERE det_tot_r IN ('TG', 'TI', 'TE', 'TN')"
END CASE
IF opc <> 3 AND vm_tot_col[opc] > 0 AND vm_tot_col[opc] <= max_col THEN
	FOR l = 1 TO vm_tot_col[opc]
		IF rubro_cons[opc].cod[l] IS NOT NULL THEN
			UPDATE temp_rubros
				SET imprime_0 = 'N'
				WHERE cod_rubro = rubro_cons[opc].cod[l]
		END IF
	END FOR
END IF
LET query = "SELECT * FROM temp_rubros ",
		expr_rub CLIPPED,
		" ORDER BY cod_rubro, nombres"
PREPARE tmp_rub FROM query
DECLARE q_rub CURSOR FOR tmp_rub
UPDATE temp_detalle
	SET total_ing = 0,
	    total_egr = 0,
	    total_net = 0
	WHERE 1 = 1
LET cod_r = NULL
LET j     = 0
LET aux_d = vm_num_det
IF vm_num_det = 1 THEN
	LET aux_d = aux_d + 1
END IF
FOREACH q_rub INTO r_te.*
	IF r_te.imprime_0 = 'N' THEN
		CONTINUE FOREACH
	END IF
	IF cod_r IS NULL OR cod_r <> r_te.cod_rubro THEN
		FOR i = j + 1 TO max_col
			IF r_te.cod_rubro = rubro_cons[opc].cod[i] THEN
				CONTINUE FOREACH
			END IF
		END FOR
		LET j = j + 1
	END IF
	LET cod_r = r_te.cod_rubro
	CASE j
		WHEN 1
			UPDATE temp_detalle SET total_ing = r_te.valor_rub
				WHERE n32_cod_trab = r_te.cod_trab
		WHEN 2
			UPDATE temp_detalle SET total_egr = r_te.valor_rub
				WHERE n32_cod_trab = r_te.cod_trab
		WHEN 3
			UPDATE temp_detalle SET total_net = r_te.valor_rub
				WHERE n32_cod_trab = r_te.cod_trab
	END CASE
	IF j > max_col THEN
		EXIT FOREACH
	END IF
	LET i = i + 1
	IF i > aux_d * max_col THEN
		EXIT FOREACH
	END IF
	LET rubro_cons[opc].cod[j] = r_te.cod_rubro
END FOREACH
CASE j
	WHEN 1
		UPDATE temp_detalle SET total_egr = NULL,
					total_net = NULL
			WHERE 1 = 1
		INITIALIZE rubro_cons[opc].cod[2] TO NULL
		INITIALIZE rubro_cons[opc].cod[3] TO NULL
	WHEN 2
		UPDATE temp_detalle SET total_net = NULL
			WHERE 1 = 1
		INITIALIZE rubro_cons[opc].cod[3] TO NULL
END CASE
IF j > max_col THEN
	LET j = max_col
END IF
IF j <= 0 THEN
	LET j = 1
END IF
LET vm_tot_col[opc] = vm_tot_col[opc] + j
IF opc = 3 THEN
	IF vm_tot_col[opc] = max_col * 2 THEN
		LET vm_tot_col[opc] = vm_tot_col[opc] - max_col
	END IF
END IF
CALL mostrar_contadores_rub(vm_tot_col[opc], cuantas_columnas(opc))
IF vm_tot_col[opc] >= cuantas_columnas(opc) THEN
	CALL actualiza_impr_rub(expr_rub)
	CALL encerar_tot(0)
ELSE
	IF NOT act THEN
		CALL actualiza_impr_rub(expr_rub)
		CALL encerar_rub()
		LET query = "SELECT UNIQUE cod_rubro ",
				" FROM temp_rubros ",
				expr_rub CLIPPED,
				" ORDER BY cod_rubro "
		PREPARE tmp_rub2 FROM query
		DECLARE q_rub2 CURSOR FOR tmp_rub2
		LET l = 1
		FOREACH q_rub2 INTO rubro_cons[opc].cod[l]
			LET l = l + 1
			IF l > max_col THEN
				EXIT FOREACH
			END IF
		END FOREACH
	ELSE
		FOR l = 1 TO max_col
			IF rubro_cons[opc].cod[l] IS NULL THEN
				CONTINUE FOR
			END IF
			UPDATE temp_rubros
				SET imprime_0 = 'N'
				WHERE cod_rubro = rubro_cons[opc].cod[l]
		END FOR
	END IF
END IF
CALL muestra_detalle_rub(opc)

END FUNCTION



{
FUNCTION cambiar_columnas2(opc, act)
DEFINE opc, act		SMALLINT
DEFINE r_te		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				cod_rubro	LIKE rolt033.n33_cod_rubro,
				orden_rub	LIKE rolt033.n33_orden,
				det_tot_r	LIKE rolt033.n33_det_tot,
				imprime_0	LIKE rolt033.n33_imprime_0,
				valor_rub	LIKE rolt033.n33_valor
			END RECORD
DEFINE cod_r		LIKE rolt033.n33_cod_rubro
DEFINE query		VARCHAR(250)
DEFINE expr_rub		VARCHAR(100)
DEFINE i, j, l		SMALLINT

CASE opc
	WHEN 1
		LET expr_rub = " WHERE det_tot_r = 'DI'"
	WHEN 2
		LET expr_rub = " WHERE det_tot_r = 'DE'"
	WHEN 3
		LET expr_rub = " WHERE det_tot_r IN ('TG', 'TI', 'TE', 'TN')"
END CASE
IF opc <> 3 AND vm_tot_col[opc] > 0 AND vm_tot_col[opc] <= max_col THEN
	FOR l = vm_tot_col[opc] TO 1 STEP 1
		IF rubro_cons[opc].cod[l] IS NOT NULL THEN
			UPDATE temp_rubros
				SET imprime_0 = 'N'
				WHERE cod_rubro = rubro_cons[opc].cod[l]
		END IF
	END FOR
END IF
LET query = "SELECT * FROM temp_rubros ",
		expr_rub CLIPPED,
		" ORDER BY cod_rubro DESC, nombres"
PREPARE tmp_rub3 FROM query
DECLARE q_rub3 CURSOR FOR tmp_rub3
UPDATE temp_detalle
	SET total_ing = 0,
	    total_egr = 0,
	    total_net = 0
	WHERE 1 = 1
LET cod_r = NULL
LET j     = max_col
FOREACH q_rub3 INTO r_te.*
	IF r_te.imprime_0 = 'N' THEN
		CONTINUE FOREACH
	END IF
	IF cod_r IS NULL OR cod_r <> r_te.cod_rubro THEN
		FOR i = j TO 1 STEP 1
			IF r_te.cod_rubro = rubro_cons[opc].cod[i] THEN
				CONTINUE FOREACH
			END IF
		END FOR
		LET j = j - 1
	END IF
	LET cod_r = r_te.cod_rubro
	CASE j
		WHEN 1
			UPDATE temp_detalle SET total_ing = r_te.valor_rub
				WHERE n32_cod_trab = r_te.cod_trab
		WHEN 2
			UPDATE temp_detalle SET total_egr = r_te.valor_rub
				WHERE n32_cod_trab = r_te.cod_trab
		WHEN 3
			UPDATE temp_detalle SET total_net = r_te.valor_rub
				WHERE n32_cod_trab = r_te.cod_trab
	END CASE
	IF j = 0 THEN
		EXIT FOREACH
	END IF
	LET i = i + 1
	IF i > vm_num_det * max_col THEN
		EXIT FOREACH
	END IF
	LET rubro_cons[opc].cod[j] = r_te.cod_rubro
END FOREACH
CASE j
	WHEN 1
		UPDATE temp_detalle SET total_egr = NULL,
					total_net = NULL
			WHERE 1 = 1
		INITIALIZE rubro_cons[opc].cod[2] TO NULL
		INITIALIZE rubro_cons[opc].cod[3] TO NULL
	WHEN 2
		UPDATE temp_detalle SET total_net = NULL
			WHERE 1 = 1
		INITIALIZE rubro_cons[opc].cod[3] TO NULL
END CASE
IF j >= max_col THEN
	LET j = 1
END IF
IF j <= 0 THEN
	LET j = max_col
END IF
LET vm_tot_col[opc] = vm_tot_col[opc] + j
IF opc = 3 THEN
	IF vm_tot_col[opc] = max_col * 2 THEN
		LET vm_tot_col[opc] = vm_tot_col[opc] - max_col
	END IF
END IF
CALL mostrar_contadores_rub(vm_tot_col[opc], cuantas_columnas(opc))
IF vm_tot_col[opc] < cuantas_columnas(opc) THEN
	CALL actualiza_impr_rub(expr_rub)
	CALL encerar_tot(0)
ELSE
	IF NOT act THEN
		CALL actualiza_impr_rub(expr_rub)
		CALL encerar_rub()
		LET query = "SELECT UNIQUE cod_rubro ",
				" FROM temp_rubros ",
				expr_rub CLIPPED,
				" ORDER BY cod_rubro DESC"
		PREPARE tmp_rub4 FROM query
		DECLARE q_rub4 CURSOR FOR tmp_rub4
		LET l = 1
		FOREACH q_rub4 INTO rubro_cons[opc].cod[l]
			LET l = l + 1
			IF l > max_col THEN
				EXIT FOREACH
			END IF
		END FOREACH
	ELSE
		FOR l = max_col TO 1 STEP 1
			IF rubro_cons[opc].cod[l] IS NULL THEN
				CONTINUE FOR
			END IF
			UPDATE temp_rubros
				SET imprime_0 = 'N'
				WHERE cod_rubro = rubro_cons[opc].cod[l]
		END FOR
	END IF
END IF
CALL muestra_detalle_rub(opc)

END FUNCTION
}



FUNCTION muestra_detalle_rub(opc)
DEFINE opc		SMALLINT
DEFINE i, j, lim, ini	SMALLINT

CALL cambiar_boton(opc)
CALL cargar_det_tmp()
CALL mostrar_totales_gen()
LET lim = vm_num_det
IF lim > fgl_scr_size('rm_detalle') THEN
	LET lim = fgl_scr_size('rm_detalle')
END IF
LET ini = pos_arr - (lim - pos_pan) + 1
LET lim = ini + lim - 1
IF pos_arr < fgl_scr_size('rm_detalle') THEN
	LET lim = fgl_scr_size('rm_detalle')
	LET ini = 1
END IF
IF lim > vm_num_det THEN
	LET lim = vm_num_det
END IF
IF ini < 1 THEN
	LET ini = 1
END IF
LET j = 1
FOR i = ini TO lim
	DISPLAY rm_detalle[i].* TO rm_detalle[j].*
	LET j = j + 1
END FOR

END FUNCTION



FUNCTION actualiza_impr_rub(expr_rub)
DEFINE expr_rub		VARCHAR(100)
DEFINE query		VARCHAR(250)

LET query = 'UPDATE temp_rubros ',
		' SET imprime_0 = "S" ',
		expr_rub CLIPPED
PREPARE up_rub FROM query
EXECUTE up_rub

END FUNCTION



FUNCTION mostrar_datos_det_cab(i)
DEFINE i		SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g35		RECORD LIKE gent035.*
DEFINE r_n30		RECORD LIKE rolt030.*

IF vm_depto_t IS NULL THEN
	CALL fl_lee_departamento(vg_codcia, rm_detalle[i].cod_depto)
		RETURNING r_g34.*
	DISPLAY rm_detalle[i].cod_depto TO n32_cod_depto
	DISPLAY BY NAME r_g34.g34_nombre
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_detalle[i].n32_cod_trab)
	RETURNING r_n30.*
CALL fl_lee_cargo(r_n30.n30_compania, r_n30.n30_cod_cargo)
	RETURNING r_g35.*
DISPLAY BY NAME r_n30.n30_cod_cargo, r_g35.g35_nombre

END FUNCTION



FUNCTION preparar_query1()
DEFINE query		CHAR(1800)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE nombre		LIKE rolt030.n30_nombres

LET expr_depto = NULL
IF rm_n32.n32_cod_depto IS NOT NULL THEN
	LET expr_depto = '   AND n32_cod_depto = ', rm_n32.n32_cod_depto
END IF
LET expr_trab = NULL
IF rm_n32.n32_cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n32_cod_trab = ', rm_n32.n32_cod_trab
END IF
LET query = 'SELECT rolt032.*, n30_nombres ',
		' FROM rolt032, rolt030 ',
		' WHERE n32_compania    = ',  vg_codcia,
		'   AND n32_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"',
		'   AND n32_fecha_ini   = "', rm_n32.n32_fecha_ini,  '"',
		'   AND n32_fecha_fin   = "', rm_n32.n32_fecha_fin,  '"',
		'   AND n32_estado     <> "E" ',
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n32_compania    = n30_compania ',
		'   AND n32_cod_trab    = n30_cod_trab ',
		' ORDER BY n32_cod_trab, n30_nombres '
PREPARE det FROM query	
DECLARE q_det CURSOR FOR det
SELECT n33_cod_rubro cod_rub, NVL(SUM(n33_valor), 0) val_rub
	FROM rolt033
	WHERE n33_compania   = vg_codcia
	  AND n33_cod_liqrol = rm_n32.n32_cod_liqrol
	  AND n33_fecha_ini  = rm_n32.n32_fecha_ini
	  AND n33_fecha_fin  = rm_n32.n32_fecha_fin
	GROUP BY 1
	HAVING SUM(n33_valor) > 0
	INTO TEMP t1
LET vm_num_det = 1
FOREACH q_det INTO r_n32.*, nombre
	LET rm_detalle[vm_num_det].cod_depto    = r_n32.n32_cod_depto
	LET rm_detalle[vm_num_det].n32_cod_trab = r_n32.n32_cod_trab
	LET rm_detalle[vm_num_det].n30_nombres  = nombre CLIPPED
	LET rm_detalle[vm_num_det].total_ing    = r_n32.n32_tot_ing
	LET rm_detalle[vm_num_det].total_egr    = r_n32.n32_tot_egr
	LET rm_detalle[vm_num_det].total_net    = r_n32.n32_tot_neto
	INSERT INTO temp_detalle VALUES(rm_detalle[vm_num_det].*)
	LET query = 'INSERT INTO temp_rubros ',
			' SELECT n33_cod_trab, "', nombre CLIPPED, '", ',
				'n33_cod_rubro, n33_orden, n33_det_tot, ',
				'"S", n33_valor ',
				' FROM rolt033 ',
				' WHERE n33_compania   = ', r_n32.n32_compania,
				'   AND n33_cod_liqrol = "',
						r_n32.n32_cod_liqrol, '"',
				'   AND n33_fecha_ini  = "',
						r_n32.n32_fecha_ini, '"',
				'   AND n33_fecha_fin  = "',
						r_n32.n32_fecha_fin, '"',
				'   AND n33_cod_trab   = ', r_n32.n32_cod_trab,
				'   AND n33_cod_rubro  IN ',
					'(SELECT cod_rub FROM t1 ',
					'WHERE cod_rub = n33_cod_rubro) '
	PREPARE exec_ins FROM query
	EXECUTE exec_ins
	INSERT INTO temp_rubros
		VALUES(r_n32.n32_cod_trab, nombre, 1000, 1000, 'TI', 'S',
			r_n32.n32_tot_ing)
	INSERT INTO temp_rubros
		VALUES(r_n32.n32_cod_trab, nombre, 1001, 1001, 'TE', 'S',
			r_n32.n32_tot_egr)
	INSERT INTO temp_rubros
		VALUES(r_n32.n32_cod_trab, nombre, 1002, 1002, 'TN', 'S',
			r_n32.n32_tot_neto)
	INSERT INTO temp_rubros
		VALUES(r_n32.n32_cod_trab, nombre, 1003, 1003, 'TG', 'S',
			r_n32.n32_tot_gan)
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
DROP TABLE t1
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
CALL encerar_rub()
RETURN 0

END FUNCTION



FUNCTION cargar_det_tmp()
DEFINE query		VARCHAR(200)

LET query = 'SELECT * FROM temp_detalle ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE tmp FROM query	
DECLARE q_tmp CURSOR FOR tmp
LET vm_num_det = 1
FOREACH q_tmp INTO rm_detalle[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION mostrar_totales_gen()
DEFINE i		SMALLINT

LET total_ing_gen = 0
LET total_egr_gen = 0
LET total_net_gen = 0
FOR i = 1 TO vm_num_det
	LET total_ing_gen = total_ing_gen + rm_detalle[i].total_ing
	LET total_egr_gen = total_egr_gen + rm_detalle[i].total_egr
	LET total_net_gen = total_net_gen + rm_detalle[i].total_net
END FOR
DISPLAY BY NAME total_ing_gen, total_egr_gen, total_net_gen

END FUNCTION



FUNCTION muestra_contadores_detalle(i, j)
DEFINE i, j		SMALLINT

DISPLAY i TO vm_num_det
DISPLAY j TO vm_max_det

END FUNCTION



FUNCTION mostrar_botones_detalle1()

--#DISPLAY "Dp"			TO tit_col1
--#DISPLAY "Cod."		TO tit_col2
--#DISPLAY "Empleado"		TO tit_col3
--#CALL cambiar_boton(3)

END FUNCTION



FUNCTION cambiar_boton(opc)
DEFINE opc		SMALLINT
DEFINE r_n06		RECORD LIKE rolt006.*

IF opc <> 3 THEN
	CALL fl_lee_rubro_roles(rubro_cons[opc].cod[1]) RETURNING r_n06.*
	--#DISPLAY r_n06.n06_nombre_abr	TO tit_col4
	CALL fl_lee_rubro_roles(rubro_cons[opc].cod[2]) RETURNING r_n06.*
	--#DISPLAY r_n06.n06_nombre_abr	TO tit_col5
	CALL fl_lee_rubro_roles(rubro_cons[opc].cod[3]) RETURNING r_n06.*
	--#DISPLAY r_n06.n06_nombre_abr	TO tit_col6
END IF
CASE opc
	WHEN 1
		--#DISPLAY "I  N  G  R  E  S  O  S"	TO tit_boton
	WHEN 2
		--#DISPLAY "E  G  R  E  S  O  S"	TO tit_boton
	WHEN 3
		--#DISPLAY "T  O  T  A  L  E  S"	TO tit_boton
		--#DISPLAY "Total Ingreso"		TO tit_col4
		--#DISPLAY "Total Egreso"		TO tit_col5
		--#DISPLAY "Total Neto"			TO tit_col6
		IF rubro_cons[opc].cod[1] = 1003 THEN
			--#DISPLAY "Total Ganado"	TO tit_col4
			--#DISPLAY ""			TO tit_col5
			--#DISPLAY ""			TO tit_col6
		END IF
END CASE

END FUNCTION



FUNCTION mostrar_contadores_rub(num_col, m_col)
DEFINE num_col, m_col	SMALLINT

DISPLAY BY NAME num_col, m_col

END FUNCTION



FUNCTION encerar_rub()
DEFINE i, j		SMALLINT

LET rubro_cons[max_col].cod[1] = 1000
LET rubro_cons[max_col].cod[2] = 1001
LET rubro_cons[max_col].cod[3] = 1002
FOR i = 1 TO max_col - 1
	FOR j = 1 TO max_col
		INITIALIZE rubro_cons[i].cod[j] TO NULL
	END FOR
END FOR

END FUNCTION



FUNCTION encerar_tot(flag)
DEFINE flag		SMALLINT

LET vm_tot_col[1] = 0
LET vm_tot_col[2] = 0
LET vm_tot_col[3] = 3
IF flag THEN
	LET vm_tot_col[3] = 0
END IF

END FUNCTION



FUNCTION retorna_mes()

CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(rm_n32.n32_mes_proceso), 10)
	RETURNING tit_mes

END FUNCTION 



FUNCTION mostrar_fechas()

CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n32.n32_cod_liqrol,
				rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso)
	RETURNING rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin
DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin

END FUNCTION 
 


FUNCTION mostrar_empleado()
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[i_cor].n32_cod_trab
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp108 ', param)

END FUNCTION


 
FUNCTION mostrar_liquidacion(flag)
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n30		RECORD LIKE rolt030.*

CALL fl_lee_liquidacion_roles(vg_codcia, rm_n32.n32_cod_liqrol,
				rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin,
				rm_detalle[i_cor].n32_cod_trab)
	RETURNING r_n32.*
CALL fl_lee_trabajador_roles(r_n32.n32_compania, r_n32.n32_cod_trab)
	RETURNING r_n30.*
LET prog = 'rolp303 '
CASE flag
	WHEN 'T'
		LET param = ' "', r_n32.n32_cod_liqrol, '" ',
				'"', r_n32.n32_fecha_ini, '" ',
				'"', r_n32.n32_fecha_fin, '" "N" '
	WHEN 'L'
		LET param = ' "', r_n32.n32_cod_liqrol, '" ',
				'"', r_n32.n32_fecha_ini, '" ',
				'"', r_n32.n32_fecha_fin, '" "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
	WHEN 'I'
		LET prog  = 'rolp405 '
		LET param = ' ', YEAR(r_n32.n32_fecha_ini), ' ',
				MONTH(r_n32.n32_fecha_ini), ' "',
				r_n32.n32_cod_liqrol, '"', ' "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
		IF r_n30.n30_estado = 'J' THEN
			LET prog  = 'rolp404 '
			LET param = ' ', YEAR(r_n32.n32_fecha_ini), ' ',
					MONTH(r_n32.n32_fecha_ini)
		END IF
END CASE
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION



FUNCTION imprimir_listado()
DEFINE param		VARCHAR(60)

LET param = ' "', rm_n32.n32_cod_liqrol, '" "', rm_n32.n32_fecha_ini, '" "',
		rm_n32.n32_fecha_fin, '"'
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp416 ', param)

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
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION

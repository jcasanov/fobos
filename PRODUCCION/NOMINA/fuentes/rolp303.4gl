--------------------------------------------------------------------------------
-- Titulo           : rolp303.4gl - Consulta de Liquidaciones
-- Elaboracion      : 04-Ago-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp303 base modulo compañía
--			[cod_liqrol] [fecha_ini] [fecha_fin] [agrupado]
--			[[cod_depto]] [[cod_trab]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE i_cor		SMALLINT
DEFINE vm_max_elmh      SMALLINT
DEFINE vm_num_elmh      SMALLINT
DEFINE vm_max_elmd      SMALLINT
DEFINE vm_num_elmd      SMALLINT
DEFINE vm_r_rows	ARRAY[500] OF INTEGER
DEFINE rm_detalle	ARRAY[500] OF RECORD
				cod_depto	LIKE rolt032.n32_cod_depto,
				n32_cod_trab	LIKE rolt032.n32_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				total_ing	DECIMAL(14,2),
				total_egr	DECIMAL(14,2),
				total_net	DECIMAL(14,2)
			END RECORD
DEFINE rm_det		ARRAY[500] OF RECORD
				cod_depto	LIKE rolt032.n32_cod_depto,
				cod_trab	LIKE rolt032.n32_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				total_gan	DECIMAL(14,2),
				total_ing	DECIMAL(14,2),
				total_egr	DECIMAL(14,2),
				total_net	DECIMAL(14,2)
			END RECORD
DEFINE rm_haberes	ARRAY[100] OF RECORD
				codrub_h	LIKE rolt033.n33_cod_rubro,
				nomrub_h	LIKE rolt006.n06_nombre_abr,
				valaux_h	LIKE rolt033.n33_horas_porc,
				valrub_h	LIKE rolt033.n33_valor
			END RECORD
DEFINE rm_descuentos	ARRAY[100] OF RECORD
				codrub_d	LIKE rolt033.n33_cod_rubro,
				nomrub_d	LIKE rolt006.n06_nombre_abr,
				valrub_d	LIKE rolt033.n33_valor
			END RECORD
DEFINE rm_toting	ARRAY[100] OF RECORD
				codrub_h	LIKE rolt033.n33_cod_rubro,
				nomrub_h	LIKE rolt006.n06_nombre_abr,
				valaux_h	LIKE rolt033.n33_horas_porc,
				valrub_h	DECIMAL(14,2)
			END RECORD
DEFINE rm_totdes	ARRAY[100] OF RECORD
				codrub_d	LIKE rolt033.n33_cod_rubro,
				nomrub_d	LIKE rolt006.n06_nombre_abr,
				valrub_d	DECIMAL(14,2)
			END RECORD
DEFINE rm_totrub	ARRAY[500] OF RECORD
				cod_depto	LIKE rolt032.n32_cod_depto,
				n32_cod_trab	LIKE rolt032.n32_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n33_horas_porc	LIKE rolt033.n33_horas_porc,
				n33_valor	LIKE rolt033.n33_valor
			END RECORD
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n01		RECORD LIKE rolt001.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE vm_trab_t	LIKE rolt032.n32_cod_trab
DEFINE vm_depto_t	LIKE rolt032.n32_cod_depto
DEFINE tit_mes		VARCHAR(10)
DEFINE vm_consulta	CHAR(1)
DEFINE vm_agrupado	CHAR(1)
DEFINE total_gan_gen	DECIMAL(14,2)
DEFINE total_ing_gen	DECIMAL(14,2)
DEFINE total_egr_gen	DECIMAL(14,2)
DEFINE total_net_gen	DECIMAL(14,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_flag_trab	SMALLINT
DEFINE vm_ver_tot	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp303.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 7 AND num_args() <> 8 AND num_args() <> 9
THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp303'
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
CREATE TEMP TABLE temp_detalle(
		cod_depto	SMALLINT,
		n32_cod_trab	INTEGER,
		n30_nombres	VARCHAR(45,25),
		total_ing	DECIMAL(14,2),
		total_egr	DECIMAL(14,2),
		total_net	DECIMAL(14,2),
		total_gan	DECIMAL(14,2)
	)
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 18
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
	OPEN FORM f_rolf303_1 FROM '../forms/rolf303_1'
ELSE
	OPEN FORM f_rolf303_1 FROM '../forms/rolf303_1c'
END IF
DISPLAY FORM f_rolf303_1
LET vm_max_rows = 500
LET vm_max_det  = 500
LET vm_max_elmh = 100
LET vm_max_elmd = 100
LET vm_agrupado = 'S'
IF num_args() <> 3 THEN
	CALL llamada_otro_prog()
	RETURN
END IF
IF cargar_datos_liq() THEN
	RETURN
END IF
WHILE TRUE
	CLEAR FORM
	INITIALIZE rm_n32.n32_cod_depto, rm_n32.n32_cod_trab TO NULL
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	LET vm_num_det     = 0
	LET vm_num_elmh    = 0
	LET vm_num_elmd    = 0
	CALL mostrar_datos_liq(1)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL llamar_consultas()
END WHILE
DROP TABLE temp_detalle

END FUNCTION



FUNCTION llamada_otro_prog()

INITIALIZE rm_n32.*, vm_trab_t, vm_depto_t TO NULL
LET vm_num_rows           = 0
LET vm_row_current        = 0
LET vm_num_det            = 0
LET vm_num_elmh           = 0
LET vm_num_elmd           = 0
LET rm_n32.n32_cod_liqrol = arg_val(4)
LET rm_n32.n32_fecha_ini  = arg_val(5)
LET rm_n32.n32_fecha_fin  = arg_val(6)
LET vm_agrupado           = arg_val(7)
IF num_args() = 7 OR num_args() = 8 THEN
	LET vm_flag_trab = 1
	LET vm_ver_tot   = 0
	LET vm_consulta  = 'D'
	IF num_args() = 8 THEN
		IF arg_val(8) <> 'D' AND arg_val(8) <> 'G' THEN
			LET rm_n32.n32_cod_depto = arg_val(8)
			LET vm_depto_t           = rm_n32.n32_cod_depto
		ELSE
			LET vm_consulta = arg_val(8)
		END IF
	END IF
	IF vm_consulta = 'D' THEN
		CALL control_consulta_detalle()
	ELSE
		CALL control_consulta_generica()
	END IF
END IF
IF num_args() = 9 THEN
	--LET rm_n32.n32_cod_depto = arg_val(8)
	LET vm_depto_t           = rm_n32.n32_cod_depto
	LET rm_n32.n32_cod_trab  = arg_val(9)
	LET vm_trab_t            = rm_n32.n32_cod_trab
	LET vm_flag_trab         = 0
	LET vm_ver_tot           = 0
	LET vm_consulta          = 'E'
	LET vm_num_rows          = 1
	CALL control_consulta_especifica()
END IF
DROP TABLE temp_detalle

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)

INITIALIZE rm_n32.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN 1
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING rm_n01.*
IF rm_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN 1
END IF
IF rm_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	RETURN 1
END IF
LET rm_n32.n32_ano_proceso = rm_n01.n01_ano_proceso
LET rm_n32.n32_mes_proceso = rm_n01.n01_mes_proceso
CALL retorna_mes()
INITIALIZE r_n05.* TO NULL
DECLARE q_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania = vg_codcia
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
		ORDER BY n05_fec_cierre DESC
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
LET rm_n32.n32_estado      = r_n32.n32_estado
LET rm_n32.n32_dias_trab   = r_n32.n32_dias_trab
LET rm_n32.n32_dias_falt   = r_n32.n32_dias_falt
LET rm_n32.n32_ano_proceso = r_n32.n32_ano_proceso
LET rm_n32.n32_mes_proceso = r_n32.n32_mes_proceso
CALL retorna_mes()
LET vm_consulta = 'D'
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq(flag)
DEFINE flag		SMALLINT
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_g34		RECORD LIKE gent034.*

CALL retorna_mes()
DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_fecha_ini,
		rm_n32.n32_fecha_fin, rm_n32.n32_ano_proceso,
		rm_n32.n32_mes_proceso, tit_mes
CASE flag
	WHEN 0
		DISPLAY BY NAME rm_n32.n32_cod_depto, rm_n32.n32_sueldo,
				rm_n32.n32_dias_falt, rm_n32.n32_tot_gan
		CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto)
			RETURNING r_g34.*
		DISPLAY BY NAME r_g34.g34_nombre
		CALL muestra_estado()
	WHEN 1
		DISPLAY BY NAME vm_consulta, vm_agrupado
END CASE
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre

END FUNCTION



FUNCTION muestra_estado()

DISPLAY BY NAME rm_n32.n32_estado
IF rm_n32.n32_estado = 'A' THEN
	DISPLAY 'EN PROCESO' TO tit_estado
END IF
IF rm_n32.n32_estado = 'C' THEN
	DISPLAY 'CERRADA'     TO tit_estado
END IF
IF rm_n32.n32_estado = 'E' THEN
	DISPLAY 'ELIMINADA'  TO tit_estado
END IF

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
	rm_n32.n32_mes_proceso, rm_n32.n32_cod_depto, rm_n32.n32_cod_trab,
	vm_consulta, vm_agrupado
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
			IF rm_n32.n32_ano_proceso > rm_n01.n01_ano_proceso THEN
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



FUNCTION llamar_consultas()

LET vm_flag_trab = 0
LET vm_ver_tot   = 0
CASE vm_consulta
	WHEN 'D'
		LET vm_flag_trab = 1
		CALL control_consulta_detalle()
	WHEN 'E'
		CALL control_consulta_especifica()
	WHEN 'G'
		LET vm_flag_trab = 1
		CALL control_consulta_generica()
END CASE

END FUNCTION



FUNCTION control_consulta_detalle()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

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
	OPEN FORM f_rolf303_2 FROM '../forms/rolf303_2'
ELSE
	OPEN FORM f_rolf303_2 FROM '../forms/rolf303_2c'
END IF
DISPLAY FORM f_rolf303_2
CALL mostrar_botones_detalle1()
IF preparar_query1() THEN
	CLOSE WINDOW w_rol2
	RETURN
END IF
CALL mostrar_consulta_detalle()
CLOSE WINDOW w_rol2
RETURN

END FUNCTION



FUNCTION mostrar_consulta_detalle()
DEFINE col, i 		SMALLINT

CALL muestra_tituto_det(1)
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 1
LET vm_columna_2 = 3
IF vm_agrupado = 'N' THEN
	LET col          = 3
	LET vm_columna_2 = 2
END IF
LET vm_columna_1  = col
LET rm_orden[col] = 'ASC'
WHILE TRUE
	CALL cargar_det_tmp()
	CALL mostrar_detalle()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
DELETE FROM temp_detalle

END FUNCTION



FUNCTION muestra_tituto_det(flag)
DEFINE flag		SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*

DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_fecha_ini,
		rm_n32.n32_fecha_fin, rm_n32.n32_cod_depto
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto) RETURNING r_g34.*
CASE vm_consulta
	WHEN 'D' DISPLAY BY NAME r_n03.n03_nombre
	WHEN 'G' IF flag THEN
			DISPLAY r_n03.n03_nombre_abr TO n03_nombre
		 ELSE
			DISPLAY BY NAME r_n03.n03_nombre
		 END IF
END CASE
DISPLAY BY NAME r_g34.g34_nombre

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE col		SMALLINT

CALL mostrar_totales_gen()
LET int_flag = 0
CALL set_count(vm_num_det)
CASE vm_consulta
	WHEN 'D' CALL display_detalle() RETURNING col
	WHEN 'G' CALL display_generica() RETURNING col
END CASE
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



FUNCTION display_detalle()
DEFINE i, j, col	SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*

DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i     = arr_curr()	
		LET i_cor = i
		CALL control_consulta_especifica()
		LET int_flag = 0
	ON KEY(F6)
		CALL muestra_totales()
		LET int_flag = 0
	ON KEY(F7)
		LET i     = arr_curr()	
		LET i_cor = i
		CALL imprimir_liquidacion('D')
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
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_detalle(i, vm_num_det)
		--#IF vm_depto_t IS NULL THEN
			--#CALL fl_lee_departamento(vg_codcia,
						--#rm_detalle[i].cod_depto)
				--#RETURNING r_g34.*
			--#DISPLAY rm_detalle[i].cod_depto TO n32_cod_depto
			--#DISPLAY BY NAME r_g34.g34_nombre
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
RETURN col

END FUNCTION



FUNCTION display_generica()
DEFINE i, j, col	SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*

DISPLAY ARRAY rm_det TO rm_det.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i     = arr_curr()	
		LET i_cor = i
		LET vm_ver_tot = 1
		CALL control_consulta_especifica()
		LET vm_ver_tot = 0
		LET int_flag = 0
	ON KEY(F6)
		CALL muestra_totales()
		LET int_flag = 0
	ON KEY(F7)
		LET i     = arr_curr()	
		LET i_cor = i
		CALL imprimir_liquidacion('D')
		LET int_flag = 0
	ON KEY(F8)
		LET i     = arr_curr()	
		LET i_cor = i
		CALL ubicarse_detalle()
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
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F5","Liquidación")
		--#CALL dialog.keysetlabel("F6","Totales")
		--#CALL dialog.keysetlabel("F7","Imprimir")
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_detalle(i, vm_num_det)
		--#IF vm_depto_t IS NULL THEN
			--#CALL fl_lee_departamento(vg_codcia,
						--#rm_det[i].cod_depto)
				--#RETURNING r_g34.*
			--#DISPLAY rm_det[i].cod_depto TO n32_cod_depto
			--#DISPLAY BY NAME r_g34.g34_nombre
		--#END IF
		--#DISPLAY rm_det[i].cod_trab TO n32_cod_trab
		--#DISPLAY rm_det[i].nom_trab TO n30_nombres
		--#LET i_cor = i
		--#CALL mostrar_datos_det()
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
RETURN col

END FUNCTION



FUNCTION control_consulta_especifica()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

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
OPEN WINDOW w_rol3 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf303_3 FROM '../forms/rolf303_3'
ELSE
	OPEN FORM f_rolf303_3 FROM '../forms/rolf303_3c'
END IF
DISPLAY FORM f_rolf303_3
CALL mostrar_botones_detalle2()
IF preparar_query2() THEN
	CLOSE WINDOW w_rol3
	RETURN
END IF
MENU 'OPCIONES'                                                                 
	BEFORE MENU                                                             
                IF vm_num_rows <= 1 THEN 
                        HIDE OPTION 'Avanzar'   
                        HIDE OPTION 'Retroceder'
                ELSE          
                        SHOW OPTION 'Avanzar'     
                END IF                           
                IF vm_row_current <= 1 THEN     
                        HIDE OPTION 'Retroceder'
		END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Detalle'  
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF 
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Detalle'  
			HIDE OPTION 'Retroceder' 
			SHOW OPTION 'Avanzar'   
			NEXT OPTION 'Avanzar'  
		ELSE 
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Avanzar'  
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('D') 'Detalle'   'Se ubica en los detalles.'
		IF vm_num_rows > 0 THEN
			CALL ubicarse_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
        COMMAND KEY('T') 'Totales' 
		CALL muestra_totales()
        COMMAND KEY('I') 'Imprimir' 
		CALL imprimir_liquidacion('E')
	COMMAND KEY('S') 'Salir'    		'Salir a la pantalla anterior.'
		EXIT MENU
END MENU
IF vm_consulta = 'E' THEN
	DELETE FROM temp_detalle
END IF
CLOSE WINDOW w_rol3

END FUNCTION



FUNCTION preparar_query1()
DEFINE query		CHAR(1200)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE insertar		SMALLINT
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
		' WHERE n32_compania   = ', vg_codcia,
		'   AND n32_cod_liqrol = "', rm_n32.n32_cod_liqrol, '"',
		'   AND n32_fecha_ini  = "', rm_n32.n32_fecha_ini, '"',
		'   AND n32_fecha_fin  = "', rm_n32.n32_fecha_fin, '"',
		'   AND n32_estado <> "E" ',
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n32_compania   = n30_compania ',
		'   AND n32_cod_trab   = n30_cod_trab ',
		' ORDER BY n32_cod_trab, n30_nombres '
PREPARE det FROM query	
DECLARE q_det CURSOR FOR det
LET vm_num_det = 1
FOREACH q_det INTO r_n32.*, nombre
	LET insertar = 0
	SELECT * FROM temp_detalle
		WHERE cod_depto    = r_n32.n32_cod_depto
		  AND n32_cod_trab = r_n32.n32_cod_trab
	IF STATUS = NOTFOUND THEN
		LET insertar = 1
	END IF
	CASE vm_consulta
		WHEN 'D'
			LET rm_detalle[vm_num_det].cod_depto    =
							r_n32.n32_cod_depto
			LET rm_detalle[vm_num_det].n32_cod_trab =
							r_n32.n32_cod_trab
			LET rm_detalle[vm_num_det].n30_nombres  = nombre
			LET rm_detalle[vm_num_det].total_ing    =
							r_n32.n32_tot_ing
			LET rm_detalle[vm_num_det].total_egr    =
							r_n32.n32_tot_egr
			LET rm_detalle[vm_num_det].total_net    =
							r_n32.n32_tot_neto
			IF insertar THEN
				INSERT INTO temp_detalle
					VALUES(rm_detalle[vm_num_det].*,
						r_n32.n32_tot_gan)
			END IF
		WHEN 'G'
			LET rm_det[vm_num_det].cod_depto = r_n32.n32_cod_depto
			LET rm_det[vm_num_det].cod_trab  = r_n32.n32_cod_trab
			LET rm_det[vm_num_det].nom_trab  = nombre
			LET rm_det[vm_num_det].total_gan = r_n32.n32_tot_gan
			LET rm_det[vm_num_det].total_ing = r_n32.n32_tot_ing
			LET rm_det[vm_num_det].total_egr = r_n32.n32_tot_egr
			LET rm_det[vm_num_det].total_net = r_n32.n32_tot_neto
			IF insertar THEN
				INSERT INTO temp_detalle
					VALUES(rm_det[vm_num_det].cod_depto,
						rm_det[vm_num_det].cod_trab,
						rm_det[vm_num_det].nom_trab,
						rm_det[vm_num_det].total_ing,
						rm_det[vm_num_det].total_egr,
						rm_det[vm_num_det].total_net,
						rm_det[vm_num_det].total_gan)
			END IF
	END CASE
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION cargar_det_tmp()
DEFINE r_det		RECORD
				cod_depto	LIKE rolt032.n32_cod_depto,
				cod_trab	LIKE rolt032.n32_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				total_ing	DECIMAL(14,2),
				total_egr	DECIMAL(14,2),
				total_net	DECIMAL(14,2),
				total_gan	DECIMAL(14,2)
			END RECORD
DEFINE query		VARCHAR(200)

LET query = 'SELECT * FROM temp_detalle ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE tmp FROM query	
DECLARE q_tmp CURSOR FOR tmp
LET vm_num_det = 1
FOREACH q_tmp INTO r_det.*
	CASE vm_consulta
		WHEN 'D'
			LET rm_detalle[vm_num_det].cod_depto   = r_det.cod_depto
			LET rm_detalle[vm_num_det].n32_cod_trab= r_det.cod_trab
			LET rm_detalle[vm_num_det].n30_nombres = r_det.nom_trab
			LET rm_detalle[vm_num_det].total_ing   = r_det.total_ing
			LET rm_detalle[vm_num_det].total_egr   = r_det.total_egr
			LET rm_detalle[vm_num_det].total_net   = r_det.total_net
		WHEN 'G'
			LET rm_det[vm_num_det].cod_depto = r_det.cod_depto
			LET rm_det[vm_num_det].cod_trab  = r_det.cod_trab
			LET rm_det[vm_num_det].nom_trab  = r_det.nom_trab
			LET rm_det[vm_num_det].total_gan = r_det.total_gan
			LET rm_det[vm_num_det].total_ing = r_det.total_ing
			LET rm_det[vm_num_det].total_egr = r_det.total_egr
			LET rm_det[vm_num_det].total_net = r_det.total_net
	END CASE
	LET vm_num_det = vm_num_det + 1
        IF vm_num_det > vm_max_det THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION preparar_query2()
DEFINE query		CHAR(1200)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_orden	VARCHAR(100)
DEFINE nombre		LIKE rolt030.n30_nombres

LET expr_depto = NULL
LET expr_trab  = NULL
CASE vm_flag_trab
	WHEN 0
		IF rm_n32.n32_cod_depto IS NOT NULL THEN
			LET expr_depto = '   AND n32_cod_depto = ',
							rm_n32.n32_cod_depto
		END IF
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			LET expr_trab  = '   AND n32_cod_trab = ',
							rm_n32.n32_cod_trab
		END IF
	WHEN 1
		LET expr_trab = '   AND n32_cod_trab = ',
						rm_detalle[i_cor].n32_cod_trab
		IF vm_consulta = 'G' THEN
			LET expr_trab = '   AND n32_cod_trab = ',
						rm_det[i_cor].cod_trab
		END IF
END CASE
LET expr_orden = ' ORDER BY n32_cod_depto, n30_nombres'
IF vm_agrupado = 'N' THEN
	LET expr_orden = ' ORDER BY n30_nombres'
END IF
LET query = 'SELECT rolt032.*, rolt032.ROWID, n30_nombres ',
		' FROM rolt032, rolt030 ',
		' WHERE n32_compania   = ', vg_codcia,
		'   AND n32_cod_liqrol = "', rm_n32.n32_cod_liqrol, '"',
		'   AND n32_fecha_ini  = "', rm_n32.n32_fecha_ini,  '"',
		'   AND n32_fecha_fin  = "', rm_n32.n32_fecha_fin,  '"',
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n32_compania   = n30_compania ',
		'   AND n32_cod_trab   = n30_cod_trab ',
		expr_orden CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_n32.*, vm_r_rows[vm_num_rows], nombre
	SELECT * FROM temp_detalle
		WHERE cod_depto    = rm_n32.n32_cod_depto
		  AND n32_cod_trab = rm_n32.n32_cod_trab
	IF STATUS = NOTFOUND THEN
		INSERT INTO temp_detalle
			VALUES(rm_n32.n32_cod_depto, rm_n32.n32_cod_trab,nombre,
				rm_n32.n32_tot_ing, rm_n32.n32_tot_egr,
				rm_n32.n32_tot_neto, rm_n32.n32_tot_gan)
	END IF
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CALL muestra_contadores()
	CALL muestra_contadores_det(0, 0)
	LET vm_row_current = 0
	RETURN 1
END IF
LET vm_row_current = 1
CALL mostrar_datos()
RETURN 0

END FUNCTION



FUNCTION mostrar_totales_gen()
DEFINE i		SMALLINT

LET total_gan_gen = 0
LET total_ing_gen = 0
LET total_egr_gen = 0
LET total_net_gen = 0
FOR i = 1 TO vm_num_det
	CASE vm_consulta
		WHEN 'D'
			LET total_ing_gen = total_ing_gen +
						rm_detalle[i].total_ing
			LET total_egr_gen = total_egr_gen +
						rm_detalle[i].total_egr
			LET total_net_gen = total_net_gen +
						rm_detalle[i].total_net
		WHEN 'G'
			LET total_gan_gen = total_gan_gen + rm_det[i].total_gan
			LET total_ing_gen = total_ing_gen + rm_det[i].total_ing
			LET total_egr_gen = total_egr_gen + rm_det[i].total_egr
			LET total_net_gen = total_net_gen + rm_det[i].total_net
	END CASE
END FOR
IF vm_consulta = 'G' THEN
	DISPLAY BY NAME total_gan_gen
END IF
DISPLAY BY NAME total_ing_gen, total_egr_gen, total_net_gen

END FUNCTION



FUNCTION muestra_contadores_detalle(i, j)
DEFINE i, j		SMALLINT

DISPLAY i TO vm_num_det
DISPLAY j TO vm_max_det

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_current, vm_num_rows

END FUNCTION



FUNCTION mostrar_botones_detalle1()

--#DISPLAY "DP"			TO tit_col1
--#DISPLAY "Cod."		TO tit_col2
--#DISPLAY "Empleado"		TO tit_col3
--#DISPLAY "Total Ingreso"	TO tit_col4
--#DISPLAY "Total Egreso"	TO tit_col5
--#DISPLAY "Total Neto"		TO tit_col6

END FUNCTION



FUNCTION mostrar_botones_detalle2()

--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY "Descripción"	TO tit_col2
--#DISPLAY "D/H"		TO tit_col3
--#DISPLAY "Valor"		TO tit_col4
--#DISPLAY "Cod."		TO tit_col5
--#DISPLAY "Descripción"	TO tit_col6
--#DISPLAY "Valor"		TO tit_col7

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_datos()

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_datos()

END FUNCTION



FUNCTION mostrar_datos()

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores()
CALL muestra_contadores_det(0, 0)

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_g35		RECORD LIKE gent035.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_cons1 CURSOR FOR SELECT * FROM rolt032 WHERE ROWID = num_registro
OPEN q_cons1
FETCH q_cons1 INTO rm_n32.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
CALL mostrar_datos_liq(0)
DISPLAY BY NAME	rm_n32.n32_cod_trab
CALL fl_lee_trabajador_roles(vg_codcia, rm_n32.n32_cod_trab) RETURNING r_n30.*
CALL fl_lee_cargo(vg_codcia, r_n30.n30_cod_cargo) RETURNING r_g35.*
DISPLAY BY NAME r_n30.n30_nombres, r_n30.n30_cod_cargo, r_g35.g35_nombre
CALL mostrar_datos_det()
CLOSE q_cons1
FREE q_cons1

END FUNCTION



FUNCTION mostrar_datos_det()

CALL cargar_detalle()
CALL muestra_detalle()
CASE vm_flag_trab
	WHEN 0
		DISPLAY rm_n32.n32_tot_ing  TO total_ing
		DISPLAY rm_n32.n32_tot_egr  TO total_egr
		DISPLAY rm_n32.n32_tot_neto TO total_net
	WHEN 1
		IF vm_consulta <> 'G' THEN
			DISPLAY BY NAME rm_detalle[i_cor].total_ing,
					rm_detalle[i_cor].total_egr,
					rm_detalle[i_cor].total_net
		ELSE
			IF NOT vm_ver_tot THEN
				DISPLAY rm_det[i_cor].total_ing TO total_ing2
				DISPLAY	rm_det[i_cor].total_egr TO total_egr2
				DISPLAY	rm_det[i_cor].total_net TO total_net2
			ELSE
				DISPLAY BY NAME rm_det[i_cor].total_ing,
						rm_det[i_cor].total_egr,
						rm_det[i_cor].total_net
			END IF
		END IF
END CASE
CALL muestra_contadores_det(0, 0)

END FUNCTION



FUNCTION cargar_detalle()
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n33		RECORD LIKE rolt033.*

IF vm_consulta = 'G' THEN
	LET rm_n32.n32_cod_trab = rm_det[i_cor].cod_trab
END IF
DECLARE q_n33 CURSOR FOR
	SELECT * FROM rolt033
		WHERE n33_compania   = vg_codcia
		  AND n33_cod_liqrol = rm_n32.n32_cod_liqrol
		  AND n33_fecha_ini  = rm_n32.n32_fecha_ini
		  AND n33_fecha_fin  = rm_n32.n32_fecha_fin
		  AND n33_cod_trab   = rm_n32.n32_cod_trab
		  AND n33_cant_valor = 'V'
	ORDER BY n33_orden
LET vm_num_elmh = 1
LET vm_num_elmd = 1
FOREACH q_n33 INTO r_n33.*
	IF r_n33.n33_det_tot <> 'DI' AND r_n33.n33_det_tot <> 'DE' THEN
		CONTINUE FOREACH
	END IF
	IF r_n33.n33_valor = 0 AND r_n33.n33_imprime_0 = 'N' AND
	  (r_n33.n33_horas_porc IS NULL OR r_n33.n33_horas_porc = 0)
	THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_rubro_roles(r_n33.n33_cod_rubro) RETURNING r_n06.*
	IF r_n33.n33_det_tot = 'DI' THEN
		LET rm_haberes[vm_num_elmh].codrub_h = r_n33.n33_cod_rubro
		LET rm_haberes[vm_num_elmh].nomrub_h = r_n06.n06_nombre_abr
		LET rm_haberes[vm_num_elmh].valaux_h = r_n33.n33_horas_porc
		LET rm_haberes[vm_num_elmh].valrub_h = r_n33.n33_valor
		LET vm_num_elmh = vm_num_elmh + 1
		IF vm_num_elmh > vm_max_elmh THEN
			CALL fl_mensaje_arreglo_incompleto()
			EXIT PROGRAM
		END IF
	END IF
	IF r_n33.n33_det_tot = 'DE' THEN
		LET rm_descuentos[vm_num_elmd].codrub_d = r_n33.n33_cod_rubro
		LET rm_descuentos[vm_num_elmd].nomrub_d = r_n06.n06_nombre_abr
		LET rm_descuentos[vm_num_elmd].valrub_d = r_n33.n33_valor
		LET vm_num_elmd = vm_num_elmd + 1
		IF vm_num_elmd > vm_max_elmd THEN
			CALL fl_mensaje_arreglo_incompleto()
			EXIT PROGRAM
		END IF
	END IF
END FOREACH
LET vm_num_elmh = vm_num_elmh - 1
LET vm_num_elmd = vm_num_elmd - 1

END FUNCTION



FUNCTION muestra_detalle()

CALL borrar_detalle()
CALL muestra_detalle_h()
CALL muestra_detalle_d()

END FUNCTION



FUNCTION muestra_detalle_h()
DEFINE i, lim		SMALLINT

LET lim = vm_num_elmh
IF lim > fgl_scr_size('rm_haberes') THEN
	LET lim = fgl_scr_size('rm_haberes')
END IF
IF lim > 0 THEN
	FOR i = 1 TO lim
		DISPLAY rm_haberes[i].* TO rm_haberes[i].*
	END FOR
END IF

END FUNCTION



FUNCTION muestra_detalle_d()
DEFINE i, lim		SMALLINT

LET lim = vm_num_elmd
IF lim > fgl_scr_size('rm_descuentos') THEN
	LET lim = fgl_scr_size('rm_descuentos')
END IF
IF lim > 0 THEN
	FOR i = 1 TO lim
		DISPLAY rm_descuentos[i].* TO rm_descuentos[i].*
	END FOR
END IF

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_haberes')
	CLEAR rm_haberes[i].*
END FOR
FOR i = 1 TO fgl_scr_size('rm_descuentos')
	CLEAR rm_descuentos[i].*
END FOR

END FUNCTION



FUNCTION ubicarse_detalle()
DEFINE salir		SMALLINT

LET salir = 0
IF vm_num_elmh > 0 THEN
	CALL detalle_haberes() RETURNING salir
END IF
IF vm_num_elmd > 0 AND salir = 0 THEN
	CALL detalle_descuentos() RETURNING salir
END IF
CALL muestra_contadores_det(0, 0)

END FUNCTION



FUNCTION detalle_haberes()
DEFINE i, j, salir	SMALLINT
DEFINE r_n06		RECORD LIKE rolt006.*

LET salir = 0
CALL set_count(vm_num_elmh)
DISPLAY ARRAY rm_haberes TO rm_haberes.*
       	ON KEY(INTERRUPT)   
		LET salir = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		IF vm_num_elmd > 0 THEN
			CALL detalle_descuentos() RETURNING salir
			IF salir = 1 THEN
				EXIT DISPLAY
			END IF
		END IF
	ON KEY(F6)
		CALL imprimir_liquidacion('E')
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()
		CALL fl_lee_rubro_roles(rm_haberes[i].codrub_h)
			RETURNING r_n06.*
		IF r_n06.n06_flag_ident IS NULL OR (r_n06.n06_flag_ident <> 'DV'
		   AND r_n06.n06_flag_ident <> 'VV'
		   AND r_n06.n06_flag_ident <> 'XV')
		THEN
			CONTINUE DISPLAY
		END IF
		CALL comprobante_vacaciones(i, 'C')
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#IF vm_num_elmd > 0 THEN
			--#CALL dialog.keysetlabel("F5", "Descuentos") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#CALL dialog.keysetlabel("F6","Imprimir") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, 0)
		--#CALL fl_lee_rubro_roles(rm_haberes[i].codrub_h)
			--#RETURNING r_n06.*
		--#IF r_n06.n06_flag_ident IS NULL OR
		   --#(r_n06.n06_flag_ident <> 'DV' AND
		   --#r_n06.n06_flag_ident <> 'XV' AND
		   --#r_n06.n06_flag_ident <> 'VV')
		--#THEN
			--#CALL dialog.keysetlabel("F7","")
		--#ELSE
			--#CALL dialog.keysetlabel("F7","Comp. Vacaciones")
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
RETURN salir

END FUNCTION 



FUNCTION detalle_descuentos()
DEFINE i, j, salir	SMALLINT
DEFINE r_n06		RECORD LIKE rolt006.*

LET salir = 0
CALL set_count(vm_num_elmd)
DISPLAY ARRAY rm_descuentos TO rm_descuentos.*
       	ON KEY(INTERRUPT)   
		LET salir = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		IF vm_num_elmh > 0 THEN
			CALL detalle_haberes() RETURNING salir
			IF salir = 1 THEN
				EXIT DISPLAY
			END IF
		END IF
	ON KEY(F6)
		CALL imprimir_liquidacion('E')
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()
		IF NOT rubro_anticipo(rm_descuentos[i].codrub_d) THEN
			CONTINUE DISPLAY
		END IF
		CALL ver_anticipo(i)
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		CALL fl_lee_rubro_roles(rm_descuentos[i].codrub_d)
			RETURNING r_n06.*
		IF r_n06.n06_flag_ident IS NULL OR (r_n06.n06_flag_ident <> 'DV'
		   AND r_n06.n06_flag_ident <> 'VV'
		   AND r_n06.n06_flag_ident <> 'XV')
		THEN
			CONTINUE DISPLAY
		END IF
		CALL comprobante_vacaciones(i, 'C')
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#IF vm_num_elmd > 0 THEN
			--#CALL dialog.keysetlabel("F5", "Haberes") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#CALL dialog.keysetlabel("F6","Imprimir") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(0, i)
		--#IF NOT rubro_anticipo(rm_descuentos[i].codrub_d) THEN
			--#CALL dialog.keysetlabel("F7","")
		--#ELSE
			--#CALL dialog.keysetlabel("F7","Anticipo")
		--#END IF
		--#IF r_n06.n06_flag_ident IS NULL OR
		   --#(r_n06.n06_flag_ident <> 'DV' AND
		   --#r_n06.n06_flag_ident <> 'XV' AND
		   --#r_n06.n06_flag_ident <> 'VV')
		--#THEN
			--#CALL dialog.keysetlabel("F8","")
		--#ELSE
			--#CALL dialog.keysetlabel("F8","Comp. Vacaciones")
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
RETURN salir

END FUNCTION 



FUNCTION rubro_anticipo(rubro)
DEFINE rubro		LIKE rolt006.n06_cod_rubro
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n18		RECORD LIKE rolt018.*

CALL fl_lee_rubro_roles(rubro) RETURNING r_n06.*
INITIALIZE r_n18.* TO NULL
SELECT * INTO r_n18.*
	FROM rolt018
	WHERE n18_cod_rubro  = rubro
	  AND n18_flag_ident = r_n06.n06_flag_ident
IF (r_n06.n06_flag_ident <> 'AN' AND
    r_n06.n06_flag_ident <> r_n18.n18_flag_ident) OR
    r_n18.n18_flag_ident IS NULL
THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION muestra_contadores_det(ini_h, ini_d)
DEFINE ini_h		SMALLINT
DEFINE ini_d		SMALLINT

DISPLAY BY NAME ini_h, ini_d, vm_num_elmh, vm_num_elmd

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



FUNCTION muestra_totales()
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE i, j		SMALLINT
DEFINE tot_rub_ing	SMALLINT
DEFINE tot_rub_des	SMALLINT
DEFINE tot_hp 		DECIMAL(14,2) 
DEFINE tot_val 		DECIMAL(14,2) 
DEFINE total_ing	DECIMAL(14,2) 
DEFINE total_egr	DECIMAL(14,2) 
DEFINE total_net	DECIMAL(14,2) 
DEFINE query		CHAR(1400)
DEFINE expr_where	CHAR(500)
DEFINE expr_where2	CHAR(500)
DEFINE expr_tablas	VARCHAR(50)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)

LET expr_depto = NULL
IF vm_depto_t IS NOT NULL THEN
	LET expr_depto = '   AND n32_cod_depto = ', vm_depto_t
END IF
LET expr_trab = NULL
IF vm_trab_t IS NOT NULL THEN
	LET expr_trab = '   AND n32_cod_trab = ', vm_trab_t
END IF
LET expr_where = ' WHERE n32_compania   = ', vg_codcia,
		 '   AND n32_cod_liqrol = "', rm_n32.n32_cod_liqrol, '"',
		 '   AND n32_fecha_ini  = "', rm_n32.n32_fecha_ini,  '"',
		 '   AND n32_fecha_fin  = "', rm_n32.n32_fecha_fin,  '"',
		 '   AND n32_estado     <> "E" ',
		expr_depto CLIPPED,
		expr_trab CLIPPED
LET query = 'SELECT SUM(n32_tot_ing), SUM(n32_tot_egr), SUM(n32_tot_neto) ',
		' FROM rolt032 ',
		expr_where CLIPPED
PREPARE sfin FROM query	
DECLARE q_sfin CURSOR FOR sfin
OPEN q_sfin
FETCH q_sfin INTO total_ing, total_egr, total_net
LET expr_tablas = ' FROM rolt033 '
LET expr_where2 = ' WHERE n33_compania   = ', vg_codcia,
		  '   AND n33_cod_liqrol = "', rm_n32.n32_cod_liqrol, '"',
		  '   AND n33_fecha_ini  = "', rm_n32.n32_fecha_ini,  '"',
		  '   AND n33_fecha_fin  = "', rm_n32.n32_fecha_fin,  '"'
IF vm_trab_t IS NOT NULL OR vm_depto_t IS NOT NULL THEN
	LET expr_tablas = ' FROM rolt032, rolt033 '
	LET expr_where2 = expr_where CLIPPED,
			  '   AND n32_compania   = n33_compania ',
			  '   AND n32_cod_liqrol = n33_cod_liqrol ',
			  '   AND n32_fecha_ini  = n33_fecha_ini ',
			  '   AND n32_fecha_fin  = n33_fecha_fin ',
			  '   AND n32_cod_trab   = n33_cod_trab '
END IF
LET query = 'SELECT n33_imprime_0, n33_orden, n33_det_tot, n33_cod_rubro, ',
		' SUM(n33_horas_porc), SUM(n33_valor) ',
		expr_tablas CLIPPED,
		expr_where2 CLIPPED,
		'   AND n33_cant_valor = "V" ',
		'   AND n33_det_tot IN ("DI","DE") ',
		' GROUP BY 1,2,3,4 ',
		' ORDER BY n33_orden'
PREPARE tot FROM query	
DECLARE q_tot CURSOR FOR tot
LET tot_rub_ing = 0
LET tot_rub_des = 0
FOREACH q_tot INTO r_n33.n33_imprime_0, r_n33.n33_orden, r_n33.n33_det_tot,
		   r_n33.n33_cod_rubro, tot_hp, tot_val
	IF tot_val = 0 AND r_n33.n33_imprime_0 = 'N' THEN
		IF tot_hp IS NULL OR tot_hp = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	CALL fl_lee_rubro_roles(r_n33.n33_cod_rubro) RETURNING r_n06.*
	IF r_n33.n33_det_tot = 'DI' THEN
		LET tot_rub_ing = tot_rub_ing + 1
		LET rm_toting[tot_rub_ing].codrub_h = r_n33.n33_cod_rubro
		LET rm_toting[tot_rub_ing].nomrub_h = r_n06.n06_nombre_abr
		LET rm_toting[tot_rub_ing].valaux_h = tot_hp
		LET rm_toting[tot_rub_ing].valrub_h = tot_val
	END IF
	IF r_n33.n33_det_tot = 'DE' THEN
		LET tot_rub_des = tot_rub_des + 1
		LET rm_totdes[tot_rub_des].codrub_d = r_n33.n33_cod_rubro
		LET rm_totdes[tot_rub_des].nomrub_d = r_n06.n06_nombre_abr
		LET rm_totdes[tot_rub_des].valrub_d = tot_val
	END IF
END FOREACH
IF tot_rub_ing + tot_rub_des = 0 THEN
	RETURN
END IF
OPEN WINDOW w_tot AT 05, 02 WITH FORM '../forms/rolf303_4'
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
CALL mostrar_botones_detalle2()
LET i = tot_rub_des
IF i > fgl_scr_size('rm_totdes') THEN
	LET i = fgl_scr_size('rm_totdes')
END IF
IF i > 0 THEN
	FOR j = 1 TO i
		DISPLAY rm_totdes[j].* TO rm_totdes[j].*
	END FOR
END IF
CASE vm_consulta
	WHEN 'D'
		DISPLAY vm_num_det  TO tot_trab
	WHEN 'E'
		DISPLAY vm_num_rows TO tot_trab
	WHEN 'G'
		DISPLAY vm_num_det  TO tot_trab
END CASE
DISPLAY BY NAME total_ing, total_egr, total_net
CALL muestra_contadores_tot(1, tot_rub_ing, 0, tot_rub_des)
WHILE TRUE
	LET int_flag = 0
	CALL set_count(tot_rub_ing)
	DISPLAY ARRAY rm_toting TO rm_toting.*
       		ON KEY(INTERRUPT)   
			LET int_flag = 1
       	        	EXIT DISPLAY  
		ON KEY(F5)
			IF tot_rub_des > 0 THEN
				LET int_flag = 0
				EXIT DISPLAY
			END IF
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_detalle_rubro_tot(rm_toting[i].codrub_h)
			LET int_flag = 0
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_tot(i, tot_rub_ing, 0,
							--#tot_rub_des)
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT", "") 
			--#CALL dialog.keysetlabel("F5", "Descuentos") 
			--#CALL dialog.keysetlabel("F6", "Detalle") 
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL set_count(tot_rub_des)
	DISPLAY ARRAY rm_totdes TO rm_totdes.*
       		ON KEY(INTERRUPT)   
			LET int_flag = 1
       	        	EXIT DISPLAY  
		ON KEY(F5)
			IF tot_rub_des > 0 THEN
				LET int_flag = 0
				EXIT DISPLAY
			END IF
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_detalle_rubro_tot(rm_totdes[i].codrub_d)
			LET int_flag = 0
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_contadores_tot(0, tot_rub_ing, i,
							--#tot_rub_des)
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT", "") 
			--#CALL dialog.keysetlabel("F5", "Ingresos") 
			--#CALL dialog.keysetlabel("F6", "Detalle") 
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_tot

END FUNCTION



FUNCTION muestra_contadores_tot(ini_h, fin_h, ini_d, fin_d)
DEFINE ini_h, fin_h	SMALLINT
DEFINE ini_d, fin_d	SMALLINT

DISPLAY BY NAME ini_h, fin_h, ini_d, fin_d

END FUNCTION



FUNCTION ver_detalle_rubro_tot(codrub)
DEFINE codrub		LIKE rolt033.n33_cod_rubro
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE query		CHAR(1200)
DEFINE expr_val		VARCHAR(100)
DEFINE tot_hor, total	DECIMAL(14,2)
DEFINE num_row, max_row	SMALLINT

LET max_row = 500
OPEN WINDOW w_rolf303_6 AT 04,08
	WITH FORM '../../NOMINA/forms/rolf303_6'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0, BORDER)
--#DISPLAY "DP"		TO tit_col1
--#DISPLAY "Cod."	TO tit_col2
--#DISPLAY "Empleado"	TO tit_col3
--#DISPLAY "D/H"	TO tit_col4
--#DISPLAY "Valor"	TO tit_col5
CALL muestra_tituto_det(0)
CALL fl_lee_rubro_roles(codrub) RETURNING r_n06.*
DISPLAY BY NAME r_n06.n06_cod_rubro, r_n06.n06_nombre
LET expr_val = NULL
IF r_n06.n06_det_tot <> 'DI' THEN
	LET expr_val = '   AND n33_valor       > 0 '
END IF
LET query = 'SELECT cod_depto, n32_cod_trab, n30_nombres, n33_horas_porc,',
			' n33_valor ',
		' FROM temp_detalle, rolt033 ',
		' WHERE n33_compania    = ', vg_codcia,
		'   AND n33_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"',
		'   AND n33_fecha_ini   = "', rm_n32.n32_fecha_ini, '"',
		'   AND n33_fecha_fin   = "', rm_n32.n32_fecha_fin, '"',
		'   AND n33_cod_trab    = n32_cod_trab ',
		'   AND n33_cod_rubro   = ', codrub,
		expr_val CLIPPED,
		' ORDER BY n30_nombres '
PREPARE det_tr FROM query	
DECLARE q_det_tr CURSOR FOR det_tr
LET num_row = 1
LET tot_hor = 0
LET total   = 0
FOREACH q_det_tr INTO rm_totrub[num_row].*
	IF rm_totrub[num_row].n33_horas_porc = 0 THEN
		LET rm_totrub[num_row].n33_horas_porc = NULL
	END IF
	IF rm_totrub[num_row].n33_horas_porc IS NULL AND
	   rm_totrub[num_row].n33_valor = 0
	THEN
		CONTINUE FOREACH
	END IF
	LET total   = total + rm_totrub[num_row].n33_valor
	IF rm_totrub[num_row].n33_horas_porc IS NOT NULL THEN
		LET tot_hor = tot_hor + rm_totrub[num_row].n33_horas_porc
	END IF
	LET num_row = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_rolf303_6
	RETURN
END IF
IF tot_hor = 0 THEN
	LET tot_hor = NULL
END IF
DISPLAY BY NAME tot_hor, total
LET max_row  = num_row
LET int_flag = 0
CALL set_count(max_row)
DISPLAY ARRAY rm_totrub TO rm_totrub.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW
		--#LET num_row = arr_curr()
		--#DISPLAY BY NAME num_row, max_row
		--#IF vm_depto_t IS NULL THEN
			--#CALL fl_lee_departamento(vg_codcia,
						--#rm_totrub[num_row].cod_depto)
				--#RETURNING r_g34.*
			--#DISPLAY rm_totrub[num_row].cod_depto TO n32_cod_depto
			--#DISPLAY BY NAME r_g34.g34_nombre
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CLOSE WINDOW w_rolf303_6
RETURN

END FUNCTION



FUNCTION imprimir_liquidacion(flag)
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)
DEFINE r_n30		RECORD LIKE rolt030.*

CALL fl_lee_trabajador_roles(vg_codcia, rm_n32.n32_cod_trab) RETURNING r_n30.*
LET param = ' ', YEAR(rm_n32.n32_fecha_ini), ' ', MONTH(rm_n32.n32_fecha_ini)
IF r_n30.n30_estado = 'J' THEN
	CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp404 ', param)
	RETURN
END IF
LET param = param CLIPPED, ' "', rm_n32.n32_cod_liqrol, '" "', vm_agrupado, '"'
CASE flag
	WHEN 'E'
		LET param = param CLIPPED, ' ', rm_n32.n32_cod_depto, ' ',
				rm_n32.n32_cod_trab
	WHEN 'D'
		LET param = param CLIPPED, ' ', rm_n32.n32_cod_depto
		IF vm_num_det = 1 THEN
			LET param = param CLIPPED, ' ', rm_n32.n32_cod_trab
		END IF
END CASE
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp405 ', param)

END FUNCTION


 
FUNCTION ver_anticipo(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)
DEFINE r_n33		RECORD LIKE rolt033.*

CALL fl_lee_rubro_liq_trabajador(vg_codcia, rm_n32.n32_cod_liqrol,
				rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin,
				rm_n32.n32_cod_trab, rm_descuentos[i].codrub_d)
	RETURNING r_n33.*
IF r_n33.n33_num_prest IS NULL THEN
	RETURN
END IF
LET param = ' ', r_n33.n33_num_prest
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp214 ', param)

END FUNCTION


 
FUNCTION comprobante_vacaciones(i, flag)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_vac		ARRAY[10] OF RECORD
				cod_v		LIKE rolt047.n47_proceso,
				per_ini		LIKE rolt047.n47_periodo_ini,
				per_fin		LIKE rolt047.n47_periodo_fin,
				dias_g		LIKE rolt047.n47_dias_goza,
				val_pag		LIKE rolt047.n47_valor_pag,
				val_des		LIKE rolt047.n47_valor_des
			END RECORD
DEFINE t_dias_g		LIKE rolt047.n47_dias_goza
DEFINE t_val_pag	LIKE rolt047.n47_valor_pag
DEFINE t_val_des	LIKE rolt047.n47_valor_des
DEFINE param		VARCHAR(60)
DEFINE cuantos		INTEGER
DEFINE num_row, max_row	SMALLINT

SELECT COUNT(*) INTO cuantos
	FROM rolt047
	WHERE n47_compania   = vg_codcia
	  AND n47_cod_liqrol = rm_n32.n32_cod_liqrol
	  AND n47_fecha_ini  = rm_n32.n32_fecha_ini
	  AND n47_fecha_fin  = rm_n32.n32_fecha_fin
	  AND n47_cod_trab   = rm_n32.n32_cod_trab
IF cuantos = 1 THEN
	CALL ver_comprobante_vacaciones(i, flag)
	RETURN
END IF
LET max_row = 10
OPEN WINDOW w_rolf303_7 AT 09, 15
	WITH FORM '../../NOMINA/forms/rolf303_7'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE 0, BORDER)
--#DISPLAY "CP"		TO tit_col1
--#DISPLAY "Per. Inic."	TO tit_col2
--#DISPLAY "Per. Final"	TO tit_col3
--#DISPLAY "D.G."	TO tit_col4
--#DISPLAY "Val. Pag."	TO tit_col5
--#DISPLAY "Val. Des."	TO tit_col6
DECLARE q_n47_2 CURSOR FOR
	SELECT n47_proceso, n47_periodo_ini, n47_periodo_fin, n47_dias_goza,
		n47_valor_pag, n47_valor_des
		FROM rolt047
		WHERE n47_compania   = vg_codcia
		  AND n47_cod_liqrol = rm_n32.n32_cod_liqrol
		  AND n47_fecha_ini  = rm_n32.n32_fecha_ini
		  AND n47_fecha_fin  = rm_n32.n32_fecha_fin
		  AND n47_cod_trab   = rm_n32.n32_cod_trab
		ORDER BY n47_periodo_fin
LET num_row   = 1
LET t_dias_g  = 0
LET t_val_pag = 0
LET t_val_des = 0
FOREACH q_n47_2 INTO r_vac[num_row].*
	LET t_dias_g  = t_dias_g  + r_vac[num_row].dias_g
	LET t_val_pag = t_val_pag + r_vac[num_row].val_pag
	LET t_val_des = t_val_des + r_vac[num_row].val_des
	LET num_row   = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_rolf303_7
	RETURN
END IF
DISPLAY BY NAME t_dias_g, t_val_pag, t_val_des
LET max_row = num_row
LET int_flag = 0
CALL set_count(max_row)
DISPLAY ARRAY r_vac TO r_vac.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET num_row = arr_curr()
		LET param = ' "P" "', r_vac[num_row].cod_v, '" ',
				rm_n32.n32_cod_trab
		IF flag <> 'L' THEN
			LET param = param CLIPPED, ' "', r_vac[num_row].per_ini,
					'" "', r_vac[num_row].per_fin, '"'
			IF flag = 'G' THEN
				LET param = param CLIPPED, ' "G"'
			END IF
		END IF
		CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp252 ', param)
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel('RETURN', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW
		--#LET num_row = arr_curr()
		--#DISPLAY BY NAME num_row, max_row
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CLOSE WINDOW w_rolf303_7
RETURN

END FUNCTION


 
FUNCTION ver_comprobante_vacaciones(i, flag)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)
DEFINE r_n47		RECORD LIKE rolt047.*

LET param = ' "P" ', rm_n32.n32_cod_trab
IF flag <> 'L' THEN
	INITIALIZE r_n47.* TO NULL
	DECLARE q_n47 CURSOR FOR
		SELECT * FROM rolt047
			WHERE n47_compania   = vg_codcia
			  AND n47_cod_liqrol = rm_n32.n32_cod_liqrol
			  AND n47_fecha_ini  = rm_n32.n32_fecha_ini
			  AND n47_fecha_fin  = rm_n32.n32_fecha_fin
			  AND n47_cod_trab   = rm_n32.n32_cod_trab
	OPEN q_n47
	FETCH q_n47 INTO r_n47.*
	CLOSE q_n47
	FREE q_n47
	IF r_n47.n47_compania IS NULL THEN
		RETURN
	END IF
	LET param = ' "P" "', r_n47.n47_proceso, '" ', rm_n32.n32_cod_trab,
			' "', r_n47.n47_periodo_ini, '"',
			' "', r_n47.n47_periodo_fin, '"'
	IF flag = 'G' THEN
		LET param = param CLIPPED, ' "G"'
	END IF
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp252 ', param)

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



FUNCTION control_consulta_generica()
DEFINE i, j		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n30		RECORD LIKE rolt030.*

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
OPEN WINDOW w_rol5 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MENU LINE lin_menu,
		  MESSAGE LINE 0, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf303_5 FROM '../forms/rolf303_5'
ELSE
	OPEN FORM f_rolf303_5 FROM '../forms/rolf303_5c'
END IF
DISPLAY FORM f_rolf303_5
CALL setear_botones_generica()
IF preparar_query1() THEN
	CLOSE WINDOW w_rol5
	RETURN
END IF
CALL mostrar_consulta_detalle()
CLOSE WINDOW w_rol5
RETURN

END FUNCTION



FUNCTION setear_botones_generica()

--#DISPLAY "DP"			TO tit_col1
--#DISPLAY "Cod."		TO tit_col2
--#DISPLAY "Empleado"		TO tit_col3
--#DISPLAY "Total Gan."		TO tit_col4
--#DISPLAY "Total Ing."		TO tit_col5
--#DISPLAY "Total Egr."		TO tit_col6
--#DISPLAY "Total Neto"		TO tit_col7

--#DISPLAY "Cod."		TO tit_col8
--#DISPLAY "Descripción"	TO tit_col9
--#DISPLAY "D/H"		TO tit_col10
--#DISPLAY "Valor"		TO tit_col11
--#DISPLAY "Cod."		TO tit_col12
--#DISPLAY "Descripción"	TO tit_col13
--#DISPLAY "Valor"		TO tit_col14

END FUNCTION

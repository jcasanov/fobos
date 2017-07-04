--------------------------------------------------------------------------------
-- Titulo           : rolp202.4gl - Mantenimiento de Novedades de Roles x Trab.
-- Elaboracion      : 31-Jul-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp202 base modulo compañía [cod_trab] [flag]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_elmh      SMALLINT
DEFINE vm_num_elmh      SMALLINT
DEFINE vm_max_elmd      SMALLINT
DEFINE vm_num_elmd      SMALLINT
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE rm_haberes	ARRAY[100] OF RECORD
				codrub_h	LIKE rolt033.n33_cod_rubro,
				nomrub_h	LIKE rolt006.n06_nombre_abr,
				valrub_h	LIKE rolt033.n33_valor
			END RECORD
DEFINE rm_descuentos	ARRAY[100] OF RECORD
				codrub_d	LIKE rolt033.n33_cod_rubro,
				nomrub_d	LIKE rolt006.n06_nombre_abr,
				valrub_d	LIKE rolt033.n33_valor
			END RECORD
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE tit_mes		VARCHAR(10)
DEFINE vm_orden		CHAR(1)
DEFINE vm_grabar_h	SMALLINT
DEFINE vm_grabar_d	SMALLINT
DEFINE vm_grabar_c	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp202.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp202'
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
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 15
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
	OPEN FORM f_rolf202_1 FROM '../forms/rolf202_1'
ELSE
	OPEN FORM f_rolf202_1 FROM '../forms/rolf202_1c'
END IF
DISPLAY FORM f_rolf202_1
LET vm_max_rows	   = 1000
LET vm_max_elmh    = 100
LET vm_max_elmd    = 100
WHILE TRUE
	CLEAR FORM
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	LET vm_num_elmh    = 0
	LET vm_num_elmd    = 0
	CALL cargar_datos_liq() RETURNING resul
	IF resul THEN
		EXIT WHILE
	END IF
	CALL mostrar_datos_liq(1)
	IF rm_n32.n32_cod_trab IS NULL THEN
		CALL lee_parametros()
	END IF
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_novedades_trab()
	IF num_args() = 5 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)

DEFINE estado		LIKE rolt032.n32_estado
DEFINE query		VARCHAR(1500)

INITIALIZE rm_n32.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
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
CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(rm_n32.n32_mes_proceso), 10)
	RETURNING tit_mes
INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
IF r_n05.n05_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe una liquidación activa.', 'stop')
	RETURN 1
END IF

LET estado = 'A'
IF num_args() = 5 AND arg_val(5) = 'F' THEN
	LET estado = 'F'
	LET rm_n32.n32_cod_trab = arg_val(4)
END IF

INITIALIZE r_n32.* TO NULL

LET query = 'SELECT * FROM rolt032 WHERE n32_compania   = ', vg_codcia  
IF estado = 'F' THEN
	LET query = query, ' AND n32_cod_trab = ', rm_n32.n32_cod_trab
ELSE
	LET query = query, ' AND n32_cod_liqrol = "', r_n05.n05_proceso, '"'
END IF
LET query = query, ' AND n32_estado = "', estado, '" ',
		   ' ORDER BY n32_fecha_ini DESC '

PREPARE cons_fini FROM query
DECLARE q_ultliq CURSOR FOR cons_fini

OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
IF r_n32.n32_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No se ha registrado la liquidación activa.', 'stop')
	RETURN 1
END IF
IF r_n05.n05_fecini_act <> r_n32.n32_fecha_ini THEN
	CALL fl_lee_proceso_roles(r_n32.n32_cod_liqrol) RETURNING r_n03.*
	LET mensaje = 'La fecha de inicio de la liquidación de rol: ',
			r_n32.n32_cod_liqrol, ' ', r_n03.n03_nombre CLIPPED,
			' no es correcta.' 
	IF estado <> 'F' THEN
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		RETURN 1
	END IF
END IF
LET rm_n32.n32_cod_liqrol = r_n32.n32_cod_liqrol
LET rm_n32.n32_fecha_ini  = r_n32.n32_fecha_ini
LET rm_n32.n32_fecha_fin  = r_n32.n32_fecha_fin
LET rm_n32.n32_estado     = r_n32.n32_estado
LET rm_n32.n32_dias_trab  = r_n32.n32_dias_trab
LET rm_n32.n32_dias_falt  = r_n32.n32_dias_falt
LET vm_orden              = 'C'
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq(flag)
DEFINE flag		SMALLINT
DEFINE r_n03		RECORD LIKE rolt003.*

DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_fecha_ini,
		rm_n32.n32_fecha_fin, rm_n32.n32_ano_proceso,
		rm_n32.n32_mes_proceso, tit_mes
IF flag THEN
	DISPLAY BY NAME vm_orden
--ELSE
	--DISPLAY BY NAME rm_n32.n32_dias_falt
END IF
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre
CALL muestra_estado()

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
IF rm_n32.n32_estado = 'F' THEN
	DISPLAY 'FINIQUITO'  TO tit_estado
END IF

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_n30		RECORD LIKE rolt030.*

LET int_flag = 0
INPUT BY NAME rm_n32.n32_cod_trab, vm_orden
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
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
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mensaje_estado_bloqueado()
				--NEXT FIELD n32_cod_trab
			END IF
		ELSE
			CLEAR n30_nombres
		END IF
END INPUT

END FUNCTION



FUNCTION control_novedades_trab()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul	 	SMALLINT

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
	OPEN FORM f_rolf202_2 FROM '../forms/rolf202_2'
ELSE
	OPEN FORM f_rolf202_2 FROM '../forms/rolf202_2c'
END IF
DISPLAY FORM f_rolf202_2
CALL mostrar_botones_detalle()
CALL preparar_query() RETURNING resul
IF resul THEN
	CLOSE WINDOW w_rol2
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
			SHOW OPTION 'Mantenimiento'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Detalle'  
			SHOW OPTION 'Mantenimiento'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF 
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Detalle'  
			SHOW OPTION 'Mantenimiento'   
			HIDE OPTION 'Retroceder' 
			SHOW OPTION 'Avanzar'   
			NEXT OPTION 'Avanzar'  
		ELSE 
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Mantenimiento'
			SHOW OPTION 'Avanzar'  
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('M') 'Mantenimiento'	'Mantenimiento de un registro.'
		IF vm_num_rows > 0 THEN                                        
			CALL control_mantenimiento()
		ELSE                                                            
			CALL fl_mensaje_consultar_primero()                     
		END IF	                                                        
        COMMAND KEY('D') 'Detalle'   'Se ubica en los detalles.'
		IF vm_num_rows > 0 THEN
			CALL ubicarse_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('S') 'Salir'    		'Salir a la pantalla anterior.'
		EXIT MENU
END MENU
CLOSE WINDOW w_rol2

END FUNCTION



FUNCTION control_mantenimiento()
DEFINE resul		SMALLINT

IF vm_num_elmh = 0 AND vm_num_elmd = 0 THEN
	CALL fl_mostrar_mensaje('Este empleado no tiene rubros para ingresar.', 'exclamation')
	RETURN
END IF
CALL control_bloqueo() RETURNING resul
IF resul THEN
	RETURN
END IF
LET vm_grabar_h = 0
LET vm_grabar_d = 0
LET vm_grabar_c = 0
MENU 'OPCIONES'
	{
	COMMAND KEY('F') 'Dias'
		CALL control_dias()
	}
	COMMAND KEY('H') 'Haberes'
		CALL control_haberes()
	COMMAND KEY('D') 'Descuentos'
		CALL control_descuentos()
	COMMAND KEY('G') 'Grabar'
		IF vm_grabar_h = 1 OR vm_grabar_d = 1 OR vm_grabar_c = 1 THEN
			CALL control_grabar()
			EXIT MENU
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir al menú anterior.'
		ROLLBACK WORK
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_bloqueo()

CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt032 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n32.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 1
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
WHENEVER ERROR STOP
RETURN 0

END FUNCTION



FUNCTION control_dias()
DEFINE dias		LIKE rolt032.n32_dias_falt
DEFINE dias_aux1	LIKE rolt032.n32_dias_falt
DEFINE dias_aux2	LIKE rolt032.n32_dias_falt
DEFINE num		SMALLINT

IF rm_n32.n32_cod_liqrol[1] = 'S' THEN
	LET num = rm_n00.n00_dias_semana
END IF
IF rm_n32.n32_cod_liqrol[1] = 'Q' THEN
	LET num = rm_n00.n00_dias_mes / 2
END IF
IF rm_n32.n32_cod_liqrol[1] = 'M' THEN
	LET num = rm_n00.n00_dias_mes
END IF
OPTIONS INPUT NO WRAP
LET dias_aux1 = rm_n32.n32_dias_falt
LET dias_aux2 = rm_n32.n32_dias_trab
LET int_flag = 0
INPUT BY NAME rm_n32.n32_dias_falt
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		LET rm_n32.n32_dias_falt = dias_aux1
		DISPLAY BY NAME rm_n32.n32_dias_falt
		RETURN
	BEFORE FIELD n32_dias_falt
		LET dias = rm_n32.n32_dias_falt
	AFTER FIELD n32_dias_falt
		IF rm_n32.n32_dias_falt IS NULL THEN
			LET rm_n32.n32_dias_falt = dias
		END IF
		IF rm_n32.n32_dias_falt > num THEN
			CALL fl_mostrar_mensaje('No puede poner mas días faltados que los permitidos en esta liquidación.', 'exclamation')
			NEXT FIELD n32_dias_falt
		END IF
		{
		IF rm_n32.n32_dias_falt > rm_n32.n32_dias_trab + dias_aux1 THEN
			CALL fl_mostrar_mensaje('Los días faltados deben ser menor o igual a los días trabajados.', 'exclamation')
			NEXT FIELD n32_dias_falt
		END IF
		}
		DISPLAY BY NAME rm_n32.n32_dias_falt
	AFTER INPUT
		LET rm_n32.n32_dias_trab = rm_n32.n32_dias_trab -
					   rm_n32.n32_dias_falt
		LET vm_grabar_c = 1
END INPUT
OPTIONS INPUT WRAP

END FUNCTION



FUNCTION control_haberes()
DEFINE i, j, salir	SMALLINT
DEFINE resp		CHAR(6)
DEFINE valor		LIKE rolt033.n33_valor
DEFINE val_aux		ARRAY[100] OF LIKE rolt033.n33_valor
DEFINE tot_dias		SMALLINT
DEFINE max_dias		SMALLINT
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE mensaje		VARCHAR(200)

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
FOR i = 1 TO vm_num_elmh
	LET val_aux[i] = rm_haberes[i].valrub_h
END FOR
WHILE TRUE
	LET salir = 0
	CALL set_count(vm_num_elmh)
	LET int_flag = 0
	INPUT ARRAY rm_haberes WITHOUT DEFAULTS FROM rm_haberes.*
		ON KEY(INTERRUPT)
       	       		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
		       	IF resp = 'Yes' THEN
             			LET int_flag = 1
				LET salir = 1
				FOR i = 1 TO vm_num_elmh
					LET rm_haberes[i].valrub_h = val_aux[i]
				END FOR
				CALL muestra_detalle_h()
				EXIT INPUT
        	       	END IF
	       	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
       			--#CALL dialog.keysetlabel("DELETE","")
               		--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE INSERT
			CLEAR rm_haberes[j].*
			EXIT INPUT
		BEFORE ROW
       			LET i = arr_curr()
	        	LET j = scr_line()
			CALL muestra_contadores_det(i, 0)
		BEFORE FIELD valrub_h
			LET valor = rm_haberes[i].valrub_h
		AFTER FIELD valrub_h
			IF rm_haberes[i].valrub_h IS NULL THEN
				LET rm_haberes[i].valrub_h = valor
				DISPLAY rm_haberes[i].valrub_h TO
					rm_haberes[j].valrub_h
			END IF
		AFTER INPUT
			IF int_flag THEN
				EXIT INPUT
			END IF
			LET tot_dias = 0
			FOR i = 1 TO vm_num_elmh
				CALL fl_lee_rubro_roles(rm_haberes[i].codrub_h)
					RETURNING r_n06.*
				IF r_n06.n06_cant_valor = 'D' THEN
					LET tot_dias = tot_dias + 
						       rm_haberes[i].valrub_h
				END IF
			END FOR
			IF rm_n32.n32_cod_liqrol = 'ME' THEN
				LET max_dias = rm_n00.n00_dias_mes
			ELSE 
				IF rm_n32.n32_cod_liqrol[1,1] = 'S' THEN
					LET max_dias = rm_n00.n00_dias_semana
				ELSE
					LET max_dias = rm_n00.n00_dias_mes / 2
				END IF
			END IF
			IF tot_dias <> max_dias THEN
				LET mensaje ='Los rubros de dias deben sumar: ',
					      max_dias USING '<<#'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				--CONTINUE INPUT
			END IF
			LET vm_grabar_h = 1
			LET salir       = 1
	END INPUT
	IF salir THEN
		CALL muestra_contadores_det(0, 0)
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION control_descuentos()
DEFINE i, j, salir	SMALLINT
DEFINE resp		CHAR(6)
DEFINE valor		LIKE rolt033.n33_valor
DEFINE val_aux		ARRAY[100] OF LIKE rolt033.n33_valor

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
FOR i = 1 TO vm_num_elmd
	LET val_aux[i] = rm_descuentos[i].valrub_d
END FOR
WHILE TRUE
	LET salir = 0
	CALL set_count(vm_num_elmd)
	LET int_flag = 0
	INPUT ARRAY rm_descuentos WITHOUT DEFAULTS FROM rm_descuentos.*
		ON KEY(INTERRUPT)
       	       		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
		       	IF resp = 'Yes' THEN
             			LET int_flag = 1
				LET salir = 1
				FOR i = 1 TO vm_num_elmd
					LET rm_descuentos[i].valrub_d =
								val_aux[i]
				END FOR
				CALL muestra_detalle_d()
				EXIT INPUT
        	       	END IF
	       	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
       			--#CALL dialog.keysetlabel("DELETE","")
               		--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE INSERT
			CLEAR rm_descuentos[j].*
			EXIT INPUT
		BEFORE ROW
       			LET i = arr_curr()
	        	LET j = scr_line()
			CALL muestra_contadores_det(0, i)
		BEFORE FIELD valrub_d
			LET valor = rm_descuentos[i].valrub_d
		AFTER FIELD valrub_d
			IF rm_descuentos[i].valrub_d IS NULL THEN
				LET rm_descuentos[i].valrub_d = valor
				DISPLAY rm_descuentos[i].valrub_d TO
					rm_descuentos[j].valrub_d
			END IF
		AFTER INPUT
			LET vm_grabar_d = 1
			LET salir       = 1
	END INPUT
	IF salir THEN
		CALL muestra_contadores_det(0, 0)
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION control_grabar()
DEFINE r_n47		RECORD LIKE rolt047.*
DEFINE comando		CHAR(100)

IF vm_grabar_h = 1 THEN
	CALL grabar_haberes()
END IF
IF vm_grabar_d = 1 THEN
	CALL grabar_descuentos()
END IF
IF vm_grabar_c = 1 THEN
	UPDATE rolt032 SET n32_dias_trab = rm_n32.n32_dias_trab,
	                   n32_dias_falt = rm_n32.n32_dias_falt
		WHERE CURRENT OF q_up
END IF
COMMIT WORK
IF num_args() = 5 THEN
	LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ',
		       vg_codcia, ' F ', rm_n32.n32_cod_trab
ELSE
	LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ',
		       vg_codcia, ' X ', rm_n32.n32_cod_trab
	DECLARE q_n47 CURSOR FOR
		SELECT * FROM rolt047
			WHERE n47_compania   = vg_codcia
			  AND n47_proceso    = 'VA'
			  AND n47_estado     = 'A'
			  AND n47_cod_liqrol = rm_n32.n32_cod_liqrol
			  AND n47_fecha_ini  = rm_n32.n32_fecha_ini
			  AND n47_fecha_fin  = rm_n32.n32_fecha_fin
			  AND n47_cod_trab   = rm_n32.n32_cod_trab
	FOREACH q_n47 INTO r_n47.*
		LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ',
	        	       vg_codcia, ' X ', r_n47.n47_cod_trab
		RUN comando
	END FOREACH
END IF
RUN comando
CALL fl_mostrar_mensaje('Empleado actualizado con los valores en sus rubros. Ok.', 'info')

END FUNCTION



FUNCTION bloqueo_n33(cod_rub, flag)
DEFINE cod_rub		LIKE rolt033.n33_cod_rubro
DEFINE flag		SMALLINT
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE palabra		VARCHAR(10)

CASE flag
	WHEN 1
		LET palabra = 'haberes'
	WHEN 2
		LET palabra = 'descuentos'
END CASE
WHENEVER ERROR CONTINUE
DECLARE q_habdes CURSOR FOR
	SELECT * FROM rolt033
		WHERE n33_compania   = vg_codcia
		  AND n33_cod_liqrol = rm_n32.n32_cod_liqrol
		  AND n33_fecha_ini  = rm_n32.n32_fecha_ini
		  AND n33_fecha_fin  = rm_n32.n32_fecha_fin
		  AND n33_cod_trab   = rm_n32.n32_cod_trab
		  AND n33_cod_rubro  = cod_rub
	FOR UPDATE
OPEN q_habdes
FETCH q_habdes INTO r_n33.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al querer actualizar uno de los rubros de ' || palabra || '. El programa abortara desahaciendo todo.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Uno de los rubros de ' || palabra || ' esta bloqueado por otro proceso.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

END FUNCTION



FUNCTION grabar_haberes()
DEFINE i		SMALLINT

FOR i = 1 TO vm_num_elmh
	CALL bloqueo_n33(rm_haberes[i].codrub_h, 1)
	UPDATE rolt033 SET n33_valor = rm_haberes[i].valrub_h
		WHERE CURRENT OF q_habdes
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El rubro de haberes ' || rm_haberes[i].codrub_h USING "&&&" || ' no se puede actualizar.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	CLOSE q_habdes
	FREE q_habdes
END FOR

END FUNCTION



FUNCTION grabar_descuentos()
DEFINE i		SMALLINT

FOR i = 1 TO vm_num_elmd
	CALL bloqueo_n33(rm_descuentos[i].codrub_d, 2)
	UPDATE rolt033 SET n33_valor = rm_descuentos[i].valrub_d
		WHERE CURRENT OF q_habdes
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El rubro de descuentos ' || rm_descuentos[i].codrub_d USING "&&&" || ' no se puede actualizar.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	CLOSE q_habdes
	FREE q_habdes
END FOR

END FUNCTION



FUNCTION preparar_query()
DEFINE query		CHAR(1200)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_orden	VARCHAR(100)
DEFINE nombre		LIKE rolt030.n30_nombres

LET expr_trab = NULL
IF rm_n32.n32_cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n32_cod_trab = ', rm_n32.n32_cod_trab
END IF
CASE vm_orden
	WHEN 'C'
		LET expr_orden = ' ORDER BY n32_cod_trab'
	WHEN 'N'
		LET expr_orden = ' ORDER BY n30_nombres'
END CASE
LET query = 'SELECT rolt032.*, rolt032.ROWID, n30_nombres ',
		' FROM rolt032, rolt030 ',
		' WHERE n32_compania   = ', vg_codcia,
		'   AND n32_cod_liqrol = "', rm_n32.n32_cod_liqrol, '"',
		'   AND n32_fecha_ini  = "', rm_n32.n32_fecha_ini, '"',
		'   AND n32_fecha_fin  = "', rm_n32.n32_fecha_fin, '"',
		expr_trab CLIPPED,
		'   AND n32_estado     = "', rm_n32.n32_estado, '"',
		'   AND n32_compania   = n30_compania ',
		'   AND n32_cod_trab   = n30_cod_trab ',
		expr_orden CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_n32.*, vm_r_rows[vm_num_rows], nombre
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores()
	CALL muestra_contadores_det(0, 0)
	RETURN 1
END IF
LET vm_row_current = 1
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores()
CALL muestra_contadores_det(0, 0)
RETURN 0

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_current, vm_num_rows

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY "Cod."		TO tit_col1
--#DISPLAY "Descripción"	TO tit_col2
--#DISPLAY "Valor"		TO tit_col3
--#DISPLAY "Cod."		TO tit_col4
--#DISPLAY "Descripción"	TO tit_col5
--#DISPLAY "Valor"		TO tit_col6

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores()
CALL muestra_contadores_det(0, 0)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores()
CALL muestra_contadores_det(0, 0)

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_n30		RECORD LIKE rolt030.*

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
DISPLAY BY NAME r_n30.n30_nombres
CASE vm_orden
	WHEN 'C'
		DISPLAY 'CODIGO' TO orden_des
	WHEN 'N'
		DISPLAY 'NOMBRE' TO orden_des
END CASE
CALL cargar_detalle()
CALL muestra_detalle()
CLOSE q_cons1
FREE q_cons1

END FUNCTION



FUNCTION cargar_detalle()
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n33		RECORD LIKE rolt033.*

DECLARE q_n33 CURSOR FOR
	SELECT * FROM rolt033
		WHERE n33_compania   = vg_codcia
		  AND n33_cod_liqrol = rm_n32.n32_cod_liqrol
		  AND n33_fecha_ini  = rm_n32.n32_fecha_ini
		  AND n33_fecha_fin  = rm_n32.n32_fecha_fin
		  AND n33_cod_trab   = rm_n32.n32_cod_trab
	ORDER BY n33_orden
LET vm_num_elmh = 1
LET vm_num_elmd = 1
FOREACH q_n33 INTO r_n33.*
	IF r_n33.n33_det_tot <> 'DI' AND r_n33.n33_det_tot <> 'DE' THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_rubro_roles(r_n33.n33_cod_rubro) RETURNING r_n06.*
	IF r_n06.n06_calculo = 'S' THEN
		CONTINUE FOREACH
	END IF
	IF r_n06.n06_ing_usuario = 'N' THEN
		CONTINUE FOREACH
	END IF
	IF r_n33.n33_det_tot = 'DI' THEN
		LET rm_haberes[vm_num_elmh].codrub_h = r_n33.n33_cod_rubro
		LET rm_haberes[vm_num_elmh].nomrub_h = r_n06.n06_nombre_abr
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

LET salir = 0
CALL set_count(vm_num_elmh)
DISPLAY ARRAY rm_haberes TO rm_haberes.*
       	ON KEY(INTERRUPT)   
		LET salir = 1
       	        EXIT DISPLAY  
	ON KEY(F1,CONTROL-W) 
		CALL llamar_visor_teclas()
	ON KEY(F5)
		IF vm_num_elmd > 0 THEN
			CALL detalle_descuentos() RETURNING salir
			IF salir = 1 THEN
				EXIT DISPLAY
			END IF
		END IF
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#IF vm_num_elmd > 0 THEN
			--#CALL dialog.keysetlabel("F5", "Descuentos") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, 0)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
RETURN salir

END FUNCTION 



FUNCTION detalle_descuentos()
DEFINE i, j, salir	SMALLINT

LET salir = 0
CALL set_count(vm_num_elmd)
DISPLAY ARRAY rm_descuentos TO rm_descuentos.*
       	ON KEY(INTERRUPT)   
		LET salir = 1
       	        EXIT DISPLAY  
	ON KEY(F1,CONTROL-W) 
		CALL llamar_visor_teclas()
	ON KEY(F5)
		IF vm_num_elmh > 0 THEN
			CALL detalle_haberes() RETURNING salir
			IF salir = 1 THEN
				EXIT DISPLAY
			END IF
		END IF
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#IF vm_num_elmd > 0 THEN
			--#CALL dialog.keysetlabel("F5", "Haberes") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(0, i)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
RETURN salir

END FUNCTION 



FUNCTION muestra_contadores_det(ini_h, ini_d)
DEFINE ini_h		SMALLINT
DEFINE ini_d		SMALLINT

DISPLAY BY NAME ini_h, ini_d, vm_num_elmh, vm_num_elmd

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

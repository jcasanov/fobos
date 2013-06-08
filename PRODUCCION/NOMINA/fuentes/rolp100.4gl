------------------------------------------------------------------------------
-- Titulo           : rolp100.4gl - Configuración Parámetros Generales 
-- Elaboracion      : 28-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp100 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_r_rows	ARRAY [50] OF INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf100_1"
DISPLAY FORM f_rol
INITIALIZE rm_n00.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
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



FUNCTION control_ingreso()
DEFINE r_mon		RECORD LIKE gent013.*

CALL fl_retorna_usuario()
INITIALIZE rm_n00.*, r_mon.* TO NULL
LET rm_n00.n00_moneda_pago  = rg_gen.g00_moneda_base
LET rm_n00.n00_dias_mes     = 30
LET rm_n00.n00_dias_semana  = 7
LET rm_n00.n00_horas_dia    = 8 
LET rm_n00.n00_seguro_event = 'S' 
LET rm_n00.n00_salario_min  = 0 
LET rm_n00.n00_uti_trabaj   = 0 
LET rm_n00.n00_uti_cargas   = 0
LET rm_n00.n00_dias_vacac   = 0
LET rm_n00.n00_ano_adi_vac  = 0
LET rm_n00.n00_dias_adi_va  = 0
LET rm_n00.n00_max_vacac    = 0
LET rm_n00.n00_max_vac_acum = 0
LET rm_n00.n00_usuario      = vg_usuario
LET rm_n00.n00_fecing       = CURRENT
CLEAR tit_moneda
CALL fl_lee_moneda(rm_n00.n00_moneda_pago) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fgl_winmessage(vg_producto,'No existe ninguna moneda base','stop')
	EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_moneda
CALL leer_datos()
IF NOT int_flag THEN
	LET rm_n00.n00_serial = 0
	LET rm_n00.n00_fecing = CURRENT
	INSERT INTO rolt000 VALUES (rm_n00.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	DISPLAY BY NAME rm_n00.n00_fecing
	LET vm_row_current = vm_num_rows
	LET rm_n00.n00_serial =	SQLCA.SQLERRD[2]
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE ultimo_rol		LIKE rolt000.n00_serial

INITIALIZE ultimo_rol TO NULL 	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rolt000
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n00.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
SELECT MAX(n00_serial) INTO ultimo_rol FROM rolt000
IF ultimo_rol IS NULL THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'Error: No hay registros que modificar','exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
IF ultimo_rol <> rm_n00.n00_serial THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'El rol es histórico, no puede ser modificado','exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos()
IF NOT int_flag THEN
	UPDATE rolt000 SET n00_moneda_pago  = rm_n00.n00_moneda_pago,
			   n00_dias_mes     = rm_n00.n00_dias_mes,
			   n00_dias_semana  = rm_n00.n00_dias_semana,
			   n00_horas_dia    = rm_n00.n00_horas_dia,
			   n00_salario_min  = rm_n00.n00_salario_min,
			   n00_seguro_event = rm_n00.n00_seguro_event,
			   n00_uti_trabaj   = rm_n00.n00_uti_trabaj,
			   n00_uti_cargas   = rm_n00.n00_uti_cargas,
			   n00_dias_vacac   = rm_n00.n00_dias_vacac,
			   n00_ano_adi_vac  = rm_n00.n00_ano_adi_vac,
			   n00_dias_adi_va  = rm_n00.n00_dias_adi_va,
			   n00_max_vacac    = rm_n00.n00_max_vacac,
			   n00_max_vac_acum = rm_n00.n00_max_vac_acum
			WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
 
END FUNCTION



FUNCTION control_consulta()
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON n00_moneda_pago, n00_dias_mes, n00_dias_semana,
	n00_horas_dia, n00_salario_min, n00_seguro_event, n00_uti_trabaj,
	n00_uti_cargas, n00_dias_vacac, n00_max_vacac, n00_max_vac_acum,
	n00_ano_adi_vac, n00_dias_adi_va
	ON KEY(F2)
		IF infield(n00_moneda_pago) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				DISPLAY mone_aux TO n00_moneda_pago 
				DISPLAY nomm_aux TO tit_moneda
			END IF 
		END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rolt000
		WHERE ' || expr_sql || ' ORDER BY 1 DESC'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_n00.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos ()
DEFINE resp		CHAR(6)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE mone_aux		LIKE gent013.g13_moneda
DEFINE nomm_aux		LIKE gent013.g13_nombre
DEFINE deci_aux		LIKE gent013.g13_decimales

LET int_flag = 0
INITIALIZE r_mon.* TO NULL
DISPLAY BY NAME rm_n00.n00_usuario, rm_n00.n00_fecing,
		rm_n00.n00_salario_min, rm_n00.n00_uti_trabaj, 
		rm_n00.n00_uti_cargas, rm_n00.n00_dias_vacac,
		rm_n00.n00_ano_adi_vac, rm_n00.n00_dias_adi_va
INPUT BY NAME rm_n00.n00_moneda_pago, rm_n00.n00_dias_mes,
	rm_n00.n00_dias_semana, rm_n00.n00_horas_dia, rm_n00.n00_salario_min,
	rm_n00.n00_seguro_event, rm_n00.n00_uti_trabaj, rm_n00.n00_uti_cargas,
	rm_n00.n00_dias_vacac, rm_n00.n00_max_vacac, rm_n00.n00_max_vac_acum,
	rm_n00.n00_ano_adi_vac, rm_n00.n00_dias_adi_va
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_n00.n00_moneda_pago, rm_n00.n00_dias_mes,
			rm_n00.n00_dias_semana, rm_n00.n00_horas_dia,
			rm_n00.n00_salario_min, rm_n00.n00_seguro_event,
			rm_n00.n00_uti_trabaj, rm_n00.n00_uti_cargas,
			rm_n00.n00_dias_vacac, rm_n00.n00_max_vacac,
			rm_n00.n00_max_vac_acum, rm_n00.n00_ano_adi_vac,
			rm_n00.n00_dias_adi_va)
        	THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
	                       	CLEAR FORM
        	               	RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF infield(n00_moneda_pago) THEN
			CALL fl_ayuda_monedas()
				RETURNING mone_aux, nomm_aux, deci_aux
			LET int_flag = 0
			IF mone_aux IS NOT NULL THEN
				LET rm_n00.n00_moneda_pago = mone_aux
				DISPLAY BY NAME rm_n00.n00_moneda_pago 
				DISPLAY nomm_aux TO tit_moneda
			END IF 
		END IF
	BEFORE FIELD n00_uti_cargas
		IF rm_n00.n00_uti_trabaj = 'S' THEN
			LET rm_n00.n00_uti_trabaj = NULL
			CLEAR n00_uti_trabaj
		END IF
	BEFORE FIELD n00_ano_adi_vac
		IF rm_n00.n00_ano_adi_vac = 0 THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD n00_dias_adi_va
		IF rm_n00.n00_dias_adi_va = 0 THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD n00_moneda_pago 
		IF rm_n00.n00_moneda_pago IS NOT NULL THEN
			CALL fl_lee_moneda(rm_n00.n00_moneda_pago)
				RETURNING r_mon.* 
			IF r_mon.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Moneda no existe','exclamation')
				NEXT FIELD n00_moneda_pago
			ELSE
				DISPLAY r_mon.g13_nombre TO tit_moneda
			END IF
			IF r_mon.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n00_moneda_pago
			END IF
		ELSE
			LET rm_n00.n00_moneda_pago = rg_gen.g00_moneda_base
			DISPLAY BY NAME rm_n00.n00_moneda_pago
			CALL fl_lee_moneda(rm_n00.n00_moneda_pago)
				RETURNING r_mon.* 
			DISPLAY r_mon.g13_nombre TO tit_mon_bas
		END IF
	AFTER FIELD n00_salario_min
                IF rm_n00.n00_salario_min IS NOT NULL THEN
                        CALL fl_retorna_precision_valor(rm_n00.n00_moneda_pago,
                                                        rm_n00.n00_salario_min)
                                RETURNING rm_n00.n00_salario_min
                        DISPLAY BY NAME rm_n00.n00_salario_min
                END IF
	AFTER FIELD n00_ano_adi_vac
		IF rm_n00.n00_ano_adi_vac IS NOT NULL THEN
			IF rm_n00.n00_ano_adi_vac = 0 THEN
				LET rm_n00.n00_dias_adi_va = 0
				DISPLAY BY NAME rm_n00.n00_dias_adi_va
			END IF
		END IF
	AFTER FIELD n00_dias_adi_va
		IF rm_n00.n00_dias_adi_va IS NOT NULL THEN
			IF rm_n00.n00_dias_adi_va = 0 THEN
				LET rm_n00.n00_ano_adi_vac = 0
				DISPLAY BY NAME rm_n00.n00_ano_adi_vac
			END IF
		END IF
	AFTER INPUT
		IF rm_n00.n00_dias_vacac > rm_n00.n00_max_vacac THEN
			CALL fl_mostrar_mensaje('El máximo de vacaciones debe ser mayor o igual los días de vacaciones.', 'exclamation')
			NEXT FIELD n00_max_vacac
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_n00.* FROM rolt000 WHERE ROWID=num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME	rm_n00.n00_moneda_pago,
		rm_n00.n00_dias_mes,
		rm_n00.n00_dias_semana,
		rm_n00.n00_horas_dia,
		rm_n00.n00_salario_min,
		rm_n00.n00_seguro_event,
		rm_n00.n00_uti_trabaj,
		rm_n00.n00_uti_cargas,
		rm_n00.n00_dias_vacac,
		rm_n00.n00_ano_adi_vac,
		rm_n00.n00_dias_adi_va,
		rm_n00.n00_max_vacac,
		rm_n00.n00_max_vac_acum,
		rm_n00.n00_usuario,
		rm_n00.n00_fecing
	CALL fl_lee_moneda(rm_n00.n00_moneda_pago) RETURNING r_mon.* 
	DISPLAY r_mon.g13_nombre TO tit_moneda
ELSE
	RETURN
END IF

END FUNCTION

------------------------------------------------------------------------------
-- Titulo           : rolp231.4gl - Mantenimiento de Prestamos - Modulo Club
-- Elaboracion      : 22-sep-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp231 base modulo compañía [num_prest] [[nulo]]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE rm_detalle	ARRAY[200] OF RECORD
				n65_secuencia	LIKE rolt065.n65_secuencia,
				n65_cod_liqrol	LIKE rolt065.n65_cod_liqrol,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr,
				n65_fecha_ini	LIKE rolt065.n65_fecha_ini,
				n65_fecha_fin	LIKE rolt065.n65_fecha_fin,
				n65_valor	LIKE rolt065.n65_valor,
				n65_saldo	LIKE rolt065.n65_saldo
			END RECORD
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n60		RECORD LIKE rolt060.*
DEFINE rm_n64		RECORD LIKE rolt064.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_n36		RECORD LIKE rolt036.*
DEFINE rm_par		RECORD
				cod_liqrol	LIKE rolt065.n65_cod_liqrol,
				n03_nombre	LIKE rolt003.n03_nombre,
				n65_fecha_ini	LIKE rolt065.n65_fecha_ini,
				n65_fecha_fin	LIKE rolt065.n65_fecha_fin,
				num_pagos	SMALLINT,
				frecuencia	CHAR(1)
			END RECORD
DEFINE total_valor	DECIMAL(14,2)
DEFINE total_saldo	DECIMAL(14,2)
DEFINE vm_flag_mant	CHAR(1)
DEFINE rm_detint	ARRAY[200] OF RECORD
	val_prest		LIKE rolt064.n64_val_prest,
	val_interes		LIKE rolt064.n64_val_interes 
END RECORD
DEFINE vm_max_prest	SMALLINT
DEFINE vm_num_prest	SMALLINT
DEFINE vm_cur_prest	SMALLINT
DEFINE vm_max_detliq	SMALLINT
DEFINE vm_num_detliq	SMALLINT
DEFINE vm_cur_detliq	SMALLINT
DEFINE vm_cambio_valor	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp231.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 AND num_args() <> 5 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp231'
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

CALL fl_lee_parametros_club_roles(vg_codcia) RETURNING rm_n60.*
IF rm_n60.n60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existen parametros del club para esta compania.', 'stop')
	EXIT PROGRAM
END IF

OPEN WINDOW w_rol1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
OPEN FORM f_rolf231_1 FROM '../forms/rolf231_1'
DISPLAY FORM f_rolf231_1
CALL mostrar_botones()
LET vm_max_rows	   = 1000
LET vm_max_det     = 199
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
CALL muestra_contadores()
CALL muestra_contadores_det(0)
MENU 'OPCIONES'                                                                 
	BEFORE MENU                                                             
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Detalle'
		IF num_args() <> 3 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			IF vm_num_rows > 0 THEN
				CALL ubicarse_detalle()
			END IF
			EXIT PROGRAM
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Detalle'
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
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
       	COMMAND KEY('E') 'Eliminar' 'Eliminar registro corriente. '
		CALL control_eliminacion()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF 
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder' 
			SHOW OPTION 'Avanzar'   
			NEXT OPTION 'Avanzar'  
		ELSE 
			SHOW OPTION 'Avanzar'  
			SHOW OPTION 'Retroceder'
		END IF
        COMMAND KEY('D') 'Detalle'   'Se ubica en el detalle.'
		IF vm_num_rows > 0 THEN
			CALL ubicarse_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE resul		SMALLINT

CALL fl_retorna_usuario()
LET vm_flag_mant = 'I'
CALL borrar_pantalla()
CALL datos_defaults_cab()
LET rm_par.frecuencia = 'Q'
CALL generacion_datos() RETURNING resul
IF resul THEN
	RETURN
END IF
BEGIN WORK
	SELECT MAX(n64_num_prest) INTO rm_n64.n64_num_prest
		FROM rolt064
		WHERE n64_compania = vg_codcia
	IF rm_n64.n64_num_prest IS NULL THEN
		LET rm_n64.n64_num_prest = 1
	ELSE
		LET rm_n64.n64_num_prest = rm_n64.n64_num_prest + 1
	END IF
	LET rm_n64.n64_fecha  = CURRENT
	LET rm_n64.n64_fecing = CURRENT
	INSERT INTO rolt064 VALUES (rm_n64.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	CALL grabar_detalle()
COMMIT WORK
CALL control_generacion_nov_roles()
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current            = vm_num_rows
LET vm_r_rows[vm_row_current] = num_aux
CALL muestrar_reg()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
DEFINE resul		SMALLINT

IF rm_n64.n64_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Solo puede modificar un préstamo cuando está activo.', 'exclamation')
	RETURN
END IF
IF rm_n64.n64_val_prest + rm_n64.n64_val_interes - rm_n64.n64_descontado = 0 THEN
	CALL fl_mostrar_mensaje('No puede modificar un préstamo que ya esté cancelado.', 'exclamation')
	RETURN
END IF
LET vm_flag_mant = 'M'
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt064
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n64.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL generacion_datos() RETURNING resul
IF resul THEN
	ROLLBACK WORK
	RETURN
END IF
UPDATE rolt064 SET * = rm_n64.* WHERE CURRENT OF q_up
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
	RETURN
END IF
CALL grabar_detalle()
COMMIT WORK
CALL control_generacion_nov_roles()
LET vm_flag_mant = 'C'
CALL muestrar_reg()
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION generacion_datos()

LET vm_cambio_valor = 1
CALL leer_cabecera()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 1
END IF
IF vm_flag_mant = 'I' OR vm_cambio_valor THEN
	CALL leer_parametros()
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN 1
	END IF
	CALL generar_detalle(1, 1, 1)
END IF
CALL leer_detalle()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION control_consulta()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n64		RECORD LIKE rolt064.*
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(1100)
DEFINE num_reg		INTEGER

CLEAR FORM
CALL mostrar_botones()
IF num_args() <> 3 THEN
	LET expr_sql = ' n64_num_prest = ', arg_val(4)
ELSE
	LET int_flag = 0 
	CONSTRUCT BY NAME expr_sql ON n64_estado, n64_num_prest, n64_cod_rubro,
		n64_cod_trab, n64_moneda, n64_val_prest, 
		n64_descontado, n64_referencia
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(n64_num_prest) THEN
				CALL fl_ayuda_anticipos_club(vg_codcia, 'T')
					RETURNING r_n64.n64_num_prest
				IF r_n64.n64_num_prest IS NOT NULL THEN
					LET rm_n64.n64_num_prest =
							r_n64.n64_num_prest
					DISPLAY BY NAME rm_n64.n64_num_prest
				END IF
			END IF
			IF INFIELD(n64_cod_rubro) THEN
				CALL fl_ayuda_rubros_generales_roles('DE', 'T',
							'T', 'S', 'T', 'T')
					RETURNING r_n06.n06_cod_rubro, 
						  r_n06.n06_nombre 
				IF r_n06.n06_cod_rubro IS NOT NULL THEN
					LET rm_n64.n64_cod_rubro =
							r_n06.n06_cod_rubro
					DISPLAY BY NAME rm_n64.n64_cod_rubro,
							r_n06.n06_nombre
				END IF
			END IF
			IF INFIELD(n64_cod_trab) THEN
	                        CALL fl_ayuda_afiliados_club(vg_codcia)
	                                RETURNING r_n30.n30_cod_trab,
						  r_n30.n30_nombres
				IF r_n30.n30_cod_trab IS NOT NULL THEN
	                                LET rm_n64.n64_cod_trab =
							r_n30.n30_cod_trab
        	                        DISPLAY BY NAME rm_n64.n64_cod_trab,
							r_n30.n30_nombres
                        	END IF
	                END IF
			IF INFIELD(n64_moneda) THEN
				CALL fl_ayuda_monedas()
					RETURNING r_g13.g13_moneda,
						  r_g13.g13_nombre,
						  r_g13.g13_decimales
				IF r_g13.g13_moneda IS NOT NULL THEN
					LET rm_n64.n64_moneda = r_g13.g13_moneda
					DISPLAY BY NAME rm_n64.n64_moneda,
							r_g13.g13_nombre
				END IF
			END IF
			LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD n64_estado
			LET rm_n64.n64_estado = get_fldbuf(n64_estado)
			IF rm_n64.n64_estado IS NOT NULL THEN
				CALL muestra_estado()
			ELSE
				CLEAR n64_estado, tit_estado
			END IF
	END CONSTRUCT
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN
	END IF
END IF
LET query = 'SELECT *, ROWID FROM rolt064 ',
		' WHERE n64_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2 ' CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_n64.*, num_reg
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
	IF num_args() <> 3 THEN
		EXIT PROGRAM
	END IF
	CLEAR FORM
	LET vm_row_current = 0
	LET vm_num_det     = 0
	CALL mostrar_botones()
	CALL muestra_contadores()
	CALL muestra_contadores_det(0)
	RETURN
END IF
LET vm_row_current = 1
CALL muestrar_reg()

END FUNCTION



FUNCTION control_eliminacion()
DEFINE confir		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_n64.n64_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('No puede eliminar un préstamo que no esté ACTIVO.', 'exclamation')
	RETURN
END IF
IF rm_n64.n64_descontado > 0 THEN
	CALL fl_mostrar_mensaje('No puede eliminar un préstamo que se ha descontado uno o más dividendos.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_elimin CURSOR FOR
	SELECT * FROM rolt064
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_elimin
FETCH q_elimin INTO rm_n64.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro que desea eliminar. Por favor pida ayuda al Administrador.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF	
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
LET int_flag = 1
CALL elimina_registro()
COMMIT WORK
CALL control_generacion_nov_roles()
CALL fl_mostrar_mensaje('Se ha eliminado este préstamo Ok.', 'info')

END FUNCTION



FUNCTION elimina_registro()
DEFINE estado		LIKE rolt064.n64_estado

IF rm_n64.n64_estado = 'A' THEN
	LET estado = 'E'
END IF
IF rm_n64.n64_estado = 'E' THEN
	LET estado = 'A'
END IF
UPDATE rolt064 SET n64_estado    = estado,
		   n64_fec_elimi = CURRENT
	WHERE CURRENT OF q_elimin
LET rm_n64.n64_fec_elimi = CURRENT
LET rm_n64.n64_estado    = estado
CALL muestra_estado()

END FUNCTION




FUNCTION mostrar_botones_cap()

DISPLAY 'Prest.'	TO tit_col1
DISPLAY 'Div.'		TO tit_col2
DISPLAY 'LQ'		TO tit_col3
DISPLAY 'Fecha Ini.'	TO tit_col4
DISPLAY 'Fecha Fin.'	TO tit_col5
DISPLAY 'Valor'		TO tit_col6
DISPLAY 'Saldo'		TO tit_col7

DISPLAY 'LQ'		TO tit_col8
DISPLAY 'Fecha Ini.'	TO tit_col9
DISPLAY 'Fecha Fin.'	TO tit_col10
DISPLAY 'Total Ing.'	TO tit_col11
DISPLAY 'Total Egr.'	TO tit_col12
DISPLAY 'Total Neto'	TO tit_col13

END FUNCTION



FUNCTION muestra_contadores_detprest()

DISPLAY BY NAME vm_cur_prest, vm_num_prest

END FUNCTION 



FUNCTION muestra_contadores_detliq()

DISPLAY BY NAME vm_cur_detliq, vm_num_detliq

END FUNCTION 



FUNCTION leer_cabecera()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n64		RECORD LIKE rolt064.*
DEFINE val_prest	LIKE rolt064.n64_val_prest
DEFINE porc_interes	LIKE rolt064.n64_porc_interes
DEFINE val_p		LIKE rolt064.n64_val_prest
DEFINE porc_int		LIKE rolt064.n64_porc_interes
DEFINE fecha		LIKE rolt064.n64_fecha
DEFINE deuda		DECIMAL(14,2)
DEFINE deuda_c		VARCHAR(13)
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_n64.n64_cod_rubro,  rm_n64.n64_cod_trab,     rm_n64.n64_moneda,
	      rm_n64.n64_val_prest,  rm_n64.n64_porc_interes, 
              rm_n64.n64_referencia, rm_n64.n64_fecha
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n64.n64_cod_rubro, rm_n64.n64_cod_trab,
				 rm_n64.n64_moneda, rm_n64.n64_val_prest,
				 rm_n64.n64_referencia, rm_n64.n64_porc_interes)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n64_cod_rubro) THEN
			CALL fl_ayuda_rubros_generales_roles('DE', 'T', 'T',
								'S', 'T', 'T')
				RETURNING r_n06.n06_cod_rubro, 
					  r_n06.n06_nombre 
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_n64.n64_cod_rubro = r_n06.n06_cod_rubro
				DISPLAY BY NAME rm_n64.n64_cod_rubro,
						r_n06.n06_nombre
			END IF
		END IF
		IF INFIELD(n64_cod_trab) THEN
			IF vm_flag_mant = 'M' THEN
				CONTINUE INPUT
                	END IF
                        CALL fl_ayuda_afiliados_club(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n64.n64_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n64.n64_cod_trab,
						r_n30.n30_nombres
                        END IF
                END IF
		IF INFIELD(n64_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre,
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_n64.n64_moneda = r_g13.g13_moneda
				DISPLAY BY NAME rm_n64.n64_moneda,
						r_g13.g13_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		IF vm_flag_mant = 'M' THEN
			LET val_p           = rm_n64.n64_val_prest
			LET porc_int        = rm_n64.n64_porc_interes
			LET vm_cambio_valor = 0
		END IF
	BEFORE FIELD n64_cod_trab
		IF vm_flag_mant = 'M' THEN
			LET r_n64.n64_cod_trab = rm_n64.n64_cod_trab
		END IF
	BEFORE FIELD n64_val_prest
		LET val_prest = rm_n64.n64_val_prest
	BEFORE FIELD n64_porc_interes
		LET porc_interes = rm_n64.n64_porc_interes
	BEFORE FIELD n64_fecha
		LET fecha = rm_n64.n64_fecha
	AFTER FIELD n64_cod_rubro
		IF rm_n64.n64_cod_rubro IS NOT NULL THEN
			CALL fl_lee_rubro_roles(rm_n64.n64_cod_rubro)
				RETURNING r_n06.*
			IF r_n06.n06_cod_rubro IS NULL  THEN
				CALL fl_mostrar_mensaje('Rubro no existe.','exclamation')
				NEXT FIELD n64_cod_rubro
			END IF
			DISPLAY BY NAME r_n06.n06_nombre
			IF r_n06.n06_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n64_cod_rubro
			END IF
			IF r_n06.n06_ing_usuario = 'N' THEN
				CALL fl_mostrar_mensaje('El rubro no puede ser ingresado por el usuario.', 'exclamation')
				NEXT FIELD n64_cod_rubro
			END IF
			IF r_n06.n06_det_tot <> 'DE' THEN
				CALL fl_mostrar_mensaje('El rubro debe ser de descuento.', 'exclamation')
				NEXT FIELD n64_cod_rubro
			END IF
		ELSE
			CLEAR n06_nombre
		END IF
	AFTER FIELD n64_cod_trab
		IF vm_flag_mant = 'M' THEN
			LET rm_n64.n64_cod_trab = r_n64.n64_cod_trab
			DISPLAY BY NAME rm_n64.n64_cod_trab
			CONTINUE INPUT
		END IF
		IF rm_n64.n64_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n64.n64_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n64_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n64_cod_trab
			END IF
			DECLARE q_n64 CURSOR FOR
				SELECT * FROM rolt064
					WHERE n64_compania = vg_codcia
					  AND n64_cod_trab = rm_n64.n64_cod_trab
					  AND n64_estado   = 'A'
					  AND n64_descontado < n64_val_prest +
					      n64_val_interes
			OPEN q_n64
			FETCH q_n64 INTO r_n64.*
			IF STATUS <> NOTFOUND THEN
				SELECT SUM(n64_val_prest + n64_val_interes - 
					   n64_descontado)
					INTO deuda FROM rolt064
					WHERE n64_compania = vg_codcia
					  AND n64_cod_trab = rm_n64.n64_cod_trab
					  AND n64_estado   IN ('A', 'P')
 				LET deuda_c = deuda USING "--,---,--&.##"
				CALL fl_mostrar_mensaje('Este empleado ya tiene una deuda de ' || fl_justifica_titulo('I', deuda_c, 13) CLIPPED || '.', 'exclamation')
				{--
				CLOSE q_n64
				FREE q_n64
				NEXT FIELD n64_cod_trab
				--}
			END IF
			CLOSE q_n64
			FREE q_n64
		ELSE
			CLEAR n30_nombres
		END IF
	AFTER FIELD n64_moneda
		IF rm_n64.n64_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_n64.n64_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL  THEN
				CALL fgl_winmessage(vg_producto, 'Moneda no existe.', 'exclamation')
				NEXT FIELD n64_moneda
			END IF
			DISPLAY BY NAME r_g13.g13_nombre
			IF r_g13.g13_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n64_moneda
			END IF
			CALL retorna_paridad()
				RETURNING rm_n64.n64_paridad, resul
			IF resul THEN
				NEXT FIELD n64_moneda
			END IF
                ELSE
                        CALL fl_lee_moneda(rg_gen.g00_moneda_base)
				RETURNING r_g13.*
			LET rm_n64.n64_moneda  = rg_gen.g00_moneda_base
			CALL retorna_paridad()
				RETURNING rm_n64.n64_paridad, resul
			DISPLAY BY NAME rm_n64.n64_moneda,
					r_g13.g13_nombre
		END IF
	AFTER FIELD n64_val_prest
		IF rm_n64.n64_descontado > 0 OR rm_n64.n64_val_prest IS NULL
		THEN
			LET rm_n64.n64_val_prest = val_prest
			DISPLAY BY NAME rm_n64.n64_val_prest
			CONTINUE INPUT
		END IF
	AFTER FIELD n64_porc_interes
		IF rm_n64.n64_descontado > 0 OR rm_n64.n64_porc_interes IS NULL 
		THEN
			LET rm_n64.n64_porc_interes = porc_interes
			DISPLAY BY NAME rm_n64.n64_porc_interes
			CONTINUE INPUT
		END IF
	AFTER FIELD n64_fecha
		IF rm_n64.n64_descontado > 0 OR rm_n64.n64_fecha IS NULL 
		THEN
			LET rm_n64.n64_fecha = fecha
			DISPLAY BY NAME rm_n64.n64_fecha
			CONTINUE INPUT
		END IF
		IF rm_n64.n64_fecha > TODAY THEN
			CALL fl_mostrar_mensaje('Fecha no puede ser mayor a hoy.', 'exclamation')
			NEXT FIELD n64_fecha
		END IF
		IF TODAY - rm_n64.n64_fecha > 30 THEN
			CALL fl_mostrar_mensaje('Antiguedad de fecha no puede ser mayor a 30 días.', 'exclamation')
			NEXT FIELD n64_fecha
		END IF
	AFTER INPUT
		IF rm_n64.n64_val_prest = 0 THEN
			CALL fl_mostrar_mensaje('Debe ingresar el valor del préstamo que sea mayor a cero.', 'exclamation')
			NEXT FIELD n64_val_prest
		END IF
		IF vm_flag_mant = 'M' THEN
			IF val_p <> rm_n64.n64_val_prest OR
			   porc_int <> rm_n64.n64_porc_interes THEN
				LET vm_cambio_valor = 1
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION leer_parametros()
DEFINE lin_men		SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE dia	 	SMALLINT
DEFINE resul	 	SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE fec_ini		LIKE rolt065.n65_fecha_ini
DEFINE fec_fin		LIKE rolt065.n65_fecha_fin
DEFINE cod_liq		LIKE rolt003.n03_proceso
DEFINE nombre		LIKE rolt003.n03_nombre
DEFINE num_p		SMALLINT

LET lin_men  = 0
LET num_rows = 12
LET num_cols = 60
IF vg_gui = 0 THEN
	LET lin_men  = 1
	LET num_rows = 12
	LET num_cols = 58
END IF
OPEN WINDOW w_rol2 AT 09, 13 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_men, BORDER,
		  MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf231_2 FROM '../forms/rolf231_2'
ELSE
	OPEN FORM f_rolf231_2 FROM '../forms/rolf231_2c'
END IF
DISPLAY FORM f_rolf231_2
IF rm_par.cod_liqrol IS NOT NULL THEN
	CALL fl_lee_proceso_roles(rm_par.cod_liqrol) RETURNING r_n03.*
	LET rm_par.n03_nombre = r_n03.n03_nombre
	DISPLAY BY NAME rm_par.n03_nombre
END IF
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_par.*) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_par.cod_liqrol = r_n03.n03_proceso
				LET rm_par.n03_nombre = r_n03.n03_nombre
				CALL cargar_datos_liq(1, 0) RETURNING resul
				IF resul THEN
					LET int_flag = 1
					EXIT INPUT
				END IF
				DISPLAY BY NAME rm_par.cod_liqrol,
						rm_par.n03_nombre
				IF rm_par.n65_fecha_ini IS NOT NULL THEN
					IF rm_par.cod_liqrol[1] = 'M' OR
					   rm_par.cod_liqrol[1] = 'Q' OR
					   rm_par.cod_liqrol[1] = 'S' THEN
						LET rm_n32.n32_ano_proceso =
						YEAR(rm_par.n65_fecha_ini)
						LET rm_n32.n32_mes_proceso =
						MONTH(rm_par.n65_fecha_ini)
					END IF
					IF rm_par.cod_liqrol = 'DC' OR
					   rm_par.cod_liqrol = 'DT' THEN
						LET rm_n36.n36_ano_proceso =
						YEAR(rm_par.n65_fecha_fin)
						LET rm_n36.n36_mes_proceso =
						MONTH(rm_par.n65_fecha_fin)
					END IF
				END IF
				CALL mostrar_fechas(1, 0, 0)
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD cod_liqrol
		LET cod_liq = rm_par.cod_liqrol
		LET nombre  = rm_par.n03_nombre
	BEFORE FIELD n65_fecha_ini
		LET fec_ini = rm_par.n65_fecha_ini
	BEFORE FIELD n65_fecha_fin
		LET fec_fin = rm_par.n65_fecha_fin
	BEFORE FIELD num_pagos
		LET num_p   = rm_par.num_pagos
	AFTER FIELD cod_liqrol
		IF rm_par.cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_par.cod_liqrol)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de liquidación en la Compañía.', 'exclamation')
				NEXT FIELD cod_liqrol
			END IF
			LET rm_par.n03_nombre = r_n03.n03_nombre
			CALL cargar_datos_liq(1, 0) RETURNING resul
			IF resul THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
			DISPLAY BY NAME rm_par.n03_nombre
			IF rm_par.n65_fecha_ini IS NOT NULL THEN
				IF rm_par.cod_liqrol[1] = 'M' OR
				   rm_par.cod_liqrol[1] = 'Q' OR
				   rm_par.cod_liqrol[1] = 'S' THEN
					LET rm_n32.n32_ano_proceso =
						YEAR(rm_par.n65_fecha_ini)
					LET rm_n32.n32_mes_proceso =
						MONTH(rm_par.n65_fecha_ini)
				END IF
				IF rm_par.cod_liqrol = 'DC' OR
				   rm_par.cod_liqrol = 'DT' OR 
				   rm_par.cod_liqrol = 'UT' THEN
					LET rm_n36.n36_ano_proceso =
						YEAR(rm_par.n65_fecha_fin)
					LET rm_n36.n36_mes_proceso =
						MONTH(rm_par.n65_fecha_fin)
				END IF
			END IF
			CALL mostrar_fechas(1, 0, 0)
			IF r_n03.n03_acep_descto = 'N' THEN
				CALL fl_mostrar_mensaje('Este código de proceso no esta permitido que acepte descuentos.', 'exclamation')
				NEXT FIELD cod_liqrol
			END IF
			IF r_n03.n03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD cod_liqrol
			END IF
			IF rm_par.cod_liqrol[1] <> 'M' AND
			   rm_par.cod_liqrol[1] <> 'Q' AND
			   rm_par.cod_liqrol[1] <> 'S' THEN
				LET rm_par.num_pagos = 1
				DISPLAY BY NAME rm_par.num_pagos
			END IF
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n64.n64_cod_trab)
                        	RETURNING r_n30.*
			IF rm_par.cod_liqrol[1] = 'M' OR
			   rm_par.cod_liqrol[1] = 'Q' OR
			   rm_par.cod_liqrol[1] = 'S' THEN
				IF r_n30.n30_tipo_rol <> rm_par.cod_liqrol[1]
				THEN
					CALL fl_mostrar_mensaje('Este código de proceso no esta configurado para este empleado.', 'exclamation')
					NEXT FIELD cod_liqrol
				END IF
			END IF
		ELSE
			LET rm_par.cod_liqrol = cod_liq
			LET rm_par.n03_nombre = nombre
			DISPLAY BY NAME rm_par.cod_liqrol, rm_par.n03_nombre
		END IF
	AFTER FIELD n65_fecha_ini
		IF fec_ini = rm_par.n65_fecha_ini THEN
			CONTINUE INPUT
		END IF
		IF rm_par.n65_fecha_ini IS NULL THEN
			LET rm_par.n65_fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.n65_fecha_ini
		END IF
		IF rm_par.cod_liqrol IS NOT NULL THEN
			CALL retorna_dia(rm_par.cod_liqrol, 1, 0) RETURNING dia
			LET rm_par.n65_fecha_ini =
					MDY(MONTH(rm_par.n65_fecha_ini), dia,
						YEAR(rm_par.n65_fecha_ini))
			IF rm_par.cod_liqrol[1] = 'M' OR
			   rm_par.cod_liqrol[1] = 'Q' OR
			   rm_par.cod_liqrol[1] = 'S' THEN
				LET rm_n32.n32_ano_proceso =
						YEAR(rm_par.n65_fecha_ini)
				LET rm_n32.n32_mes_proceso =
						MONTH(rm_par.n65_fecha_ini)
			END IF
			IF rm_par.cod_liqrol = 'DC' OR rm_par.cod_liqrol = 'DT'
			THEN
				LET rm_n36.n36_ano_proceso =
						YEAR(rm_par.n65_fecha_ini + 1)
				LET rm_n36.n36_mes_proceso =
						MONTH(rm_par.n65_fecha_fin)
			END IF
			CALL mostrar_fechas(1, 0, 0)
		END IF
		IF rm_par.n65_fecha_ini <= rm_n32.n32_fecha_ini OR
		   rm_par.n65_fecha_ini <= rm_n36.n36_fecha_ini THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser mayor que la fecha de cierre de la última liquidación procesada.', 'exclamation')
			CALL retorna_n05(rm_par.cod_liqrol)
				RETURNING r_n05.*, resul
			IF resul THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
			IF rm_par.cod_liqrol <> 'UV' THEN
				CALL retorna_dia(rm_par.cod_liqrol, 1, 0)
					RETURNING dia
				LET rm_par.n65_fecha_ini =
					MDY(MONTH(r_n05.n05_fec_cierre),
						dia, YEAR(r_n05.n05_fec_cierre))
				CALL retorna_fecha(rm_par.n65_fecha_ini)
					RETURNING rm_par.n65_fecha_ini
			END IF
			DISPLAY BY NAME rm_par.n65_fecha_ini
			NEXT FIELD n65_fecha_ini
		END IF
	AFTER FIELD n65_fecha_fin
		LET rm_par.n65_fecha_fin = fec_fin
		DISPLAY BY NAME rm_par.n65_fecha_fin
	AFTER FIELD num_pagos
		IF rm_par.num_pagos IS NULL THEN
			LET rm_par.num_pagos = num_p
			DISPLAY BY NAME rm_par.num_pagos
		END IF
	AFTER INPUT
		IF rm_par.frecuencia IS NULL THEN
			CALL fl_mostrar_mensaje('Elija frecuencia.', 'exclamation')
			NEXT FIELD frecuencia
		END IF
			
		IF rm_par.n65_fecha_fin < rm_par.n65_fecha_ini THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor que la fecha inicial.', 'exclamation')
			NEXT FIELD n65_fecha_fin
		END IF
		IF rm_par.cod_liqrol[1] <> 'M' AND
		   rm_par.cod_liqrol[1] <> 'Q' AND
		   rm_par.cod_liqrol[1] <> 'S' THEN
			LET rm_par.num_pagos = 1
			DISPLAY BY NAME rm_par.num_pagos
		END IF
		LET vm_num_det = rm_par.num_pagos
END INPUT
CLOSE WINDOW w_rol2

END FUNCTION



FUNCTION leer_detalle()
DEFINE i, j, salir	SMALLINT
DEFINE resul, dia	SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE mes_aux		LIKE rolt065.n65_fecha_fin
DEFINE r_det		RECORD
				n65_secuencia	LIKE rolt065.n65_secuencia,
				n65_cod_liqrol	LIKE rolt065.n65_cod_liqrol,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr,
				n65_fecha_ini	LIKE rolt065.n65_fecha_ini,
				n65_fecha_fin	LIKE rolt065.n65_fecha_fin,
				n65_valor	LIKE rolt065.n65_valor,
				n65_saldo	LIKE rolt065.n65_saldo
			END RECORD

OPTIONS INSERT KEY F15,
	DELETE KEY F16
WHILE TRUE
	LET salir = 0
	CALL set_count(vm_num_det)
	LET int_flag = 0
	INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
		ON KEY(INTERRUPT)
       	       		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
		       	IF resp = 'Yes' THEN
             			LET int_flag = 1
				LET salir    = 1
				EXIT INPUT
        	       	END IF
	       	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
	       	ON KEY(F2)
			IF INFIELD(n65_cod_liqrol) THEN
				CALL fl_ayuda_procesos_roles()
					RETURNING r_n03.n03_proceso,
						  r_n03.n03_nombre
				IF r_n03.n03_proceso IS NOT NULL THEN
					LET rm_detalle[i].n65_cod_liqrol =
							r_n03.n03_proceso
					LET rm_detalle[i].n03_nombre_abr =
							r_n03.n03_nombre_abr
					CALL cargar_datos_liq(2, i)
						RETURNING resul
					IF resul THEN
						NEXT FIELD n65_cod_liqrol
					END IF
					DISPLAY rm_detalle[i].n65_cod_liqrol TO
						rm_detalle[j].n65_cod_liqrol
					DISPLAY rm_detalle[i].n03_nombre_abr TO
						rm_detalle[j].n03_nombre_abr
					CALL mostrar_fechas(2, i, j)
				END IF
			END IF
			LET int_flag = 0
		ON KEY(F5)
       			LET i = arr_curr()
			CALL leer_parametros()
			IF NOT int_flag THEN
				CALL generar_detalle(1, 1,
						rm_detalle[1].n65_secuencia)
				EXIT INPUT
			END IF
			LET int_flag = 0
		BEFORE INPUT
               		--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
 
		BEFORE INSERT
       			LET i = arr_curr()
	        	LET j = scr_line()
			CLEAR rm_detalle[j].*
			EXIT INPUT
 
		BEFORE ROW
       			LET i = arr_curr()
	        	LET j = scr_line()
			CALL muestra_contadores_det(i)
			LET r_det.* = rm_detalle[i].*
		BEFORE FIELD n65_cod_liqrol
			LET r_det.n65_cod_liqrol = rm_detalle[i].n65_cod_liqrol
			LET r_det.n03_nombre_abr = rm_detalle[i].n03_nombre_abr
		BEFORE FIELD n65_fecha_ini
			LET r_det.n65_fecha_ini = rm_detalle[i].n65_fecha_ini
		BEFORE FIELD n65_fecha_fin
			LET r_det.n65_fecha_fin = rm_detalle[i].n65_fecha_fin
		BEFORE FIELD n65_valor
			LET r_det.n65_valor = rm_detalle[i].n65_valor
		AFTER DELETE
			{
			CALL generar_detalle(2, i,
						rm_detalle[i].n65_secuencia - 1)
			INITIALIZE rm_detalle[vm_num_det].* TO NULL
			IF vm_num_det <= fgl_scr_size('rm_detalle') THEN
				CLEAR rm_detalle[vm_num_det].*
			END IF
			}
			LET vm_num_det = vm_num_det - 1
			IF vm_num_det = 0 THEN
       				LET i = arr_curr()
				LET int_flag = 1
				WHILE int_flag 
					CALL leer_parametros()
				END WHILE
				CALL generar_detalle(1, 1, 1)
			END IF
			CALL mostrar_total()
			EXIT INPUT
		AFTER FIELD n65_cod_liqrol
			IF rm_detalle[i].n65_cod_liqrol IS NOT NULL THEN
   				CALL fl_lee_proceso_roles(rm_detalle[i].n65_cod_liqrol)
					RETURNING r_n03.*
				IF r_n03.n03_proceso IS NULL THEN
					CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
					NEXT FIELD n65_cod_liqrol
				END IF
				LET rm_detalle[i].n03_nombre_abr =
							r_n03.n03_nombre_abr
				DISPLAY rm_detalle[i].n03_nombre_abr TO
					rm_detalle[j].n03_nombre_abr
				CALL cargar_datos_liq(2, i) RETURNING resul
				IF resul THEN
					NEXT FIELD n65_cod_liqrol
				END IF
				CALL mostrar_fechas(2, i, j)
				IF r_n03.n03_acep_descto = 'N' THEN
					CALL fl_mostrar_mensaje('Este código de proceso no esta permitido que acepte descuentos.', 'exclamation')
					NEXT FIELD n65_cod_liqrol
				END IF
				IF r_n03.n03_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD n65_cod_liqrol
				END IF
			{
				IF FIELD_TOUCHED(rm_detalle[i].n65_cod_liqrol)
				THEN
					CALL generar_detalle(2, i,
						rm_detalle[i].n65_secuencia)
				END IF
			}
			ELSE
				LET rm_detalle[i].n65_cod_liqrol =
							r_det.n65_cod_liqrol
				LET rm_detalle[i].n03_nombre_abr =
							r_det.n03_nombre_abr
				DISPLAY rm_detalle[i].n65_cod_liqrol TO
					rm_detalle[j].n65_cod_liqrol
				DISPLAY rm_detalle[i].n03_nombre_abr TO
					rm_detalle[j].n03_nombre_abr
			END IF
		AFTER FIELD n65_fecha_ini
			IF r_det.n65_fecha_ini = rm_detalle[i].n65_fecha_ini
			THEN
				CONTINUE INPUT
			END IF
			IF rm_detalle[i].n65_fecha_ini IS NULL THEN
				LET rm_detalle[i].n65_fecha_ini =
							r_det.n65_fecha_ini
				DISPLAY rm_detalle[i].n65_fecha_ini TO
					rm_detalle[j].n65_fecha_ini
			END IF
			IF rm_detalle[i].n65_cod_liqrol IS NOT NULL THEN
				CALL retorna_dia(rm_detalle[i].n65_cod_liqrol,
						2, i)
					RETURNING dia
				LET rm_detalle[i].n65_fecha_ini =
					MDY(MONTH(rm_detalle[i].n65_fecha_ini),
					 dia, YEAR(rm_detalle[i].n65_fecha_ini))
				CALL mostrar_fechas(2, i, j)
			{
				CALL generar_detalle(2, i,
						rm_detalle[i].n65_secuencia)
			}
			END IF
		AFTER FIELD n65_fecha_fin
			LET rm_detalle[i].n65_fecha_fin = r_det.n65_fecha_fin
			DISPLAY rm_detalle[i].n65_fecha_fin TO
				rm_detalle[j].n65_fecha_fin
		AFTER FIELD n65_valor
			IF rm_detalle[i].n65_valor IS NULL THEN
				LET rm_detalle[i].n65_valor = r_det.n65_valor
				DISPLAY rm_detalle[i].n65_valor TO
					rm_detalle[j].n65_valor
			END IF
			LET rm_detalle[i].n65_saldo = rm_detalle[i].n65_valor
			DISPLAY rm_detalle[i].n65_saldo TO
				rm_detalle[j].n65_saldo
			CALL mostrar_total()
		AFTER INPUT
			CALL mostrar_total()
			CALL validar_detalle() RETURNING resul
			IF resul THEN
				NEXT FIELD n65_cod_liqrol
			END IF
			IF total_valor > (rm_n64.n64_val_prest + rm_n64.n64_val_interes - rm_n64.n64_descontado)
			THEN
				CALL fl_mostrar_mensaje('El valor total de los dividendos es mayor que el valor del préstamo menos el descontado.', 'exclamation')
				NEXT FIELD n65_valor
			END IF
			IF total_valor <> (rm_n64.n64_val_prest + rm_n64.n64_val_interes - rm_n64.n64_descontado)
			THEN
				CALL fl_mostrar_mensaje('No cuadra total del detalle contra valor del préstamo más intereses.', 'exclamation')
				NEXT FIELD n65_valor
			END IF
			LET salir = 1
	END INPUT
	IF salir THEN
		CALL muestra_contadores_det(0)
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION validar_detalle()
DEFINE i, j, resul	SMALLINT
DEFINE mensaje		VARCHAR(300)
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE fec_ini		LIKE rolt032.n32_fecha_ini
DEFINE fec_fin		LIKE rolt032.n32_fecha_fin
DEFINE r_n64		RECORD LIKE rolt064.*

LET resul = 0
FOR i = 1 TO vm_num_det - 1
	FOR j = i + 1 TO vm_num_det
		IF rm_detalle[i].n65_cod_liqrol = rm_detalle[j].n65_cod_liqrol
		   AND
		   rm_detalle[i].n65_fecha_ini >= rm_detalle[j].n65_fecha_ini
		THEN
			LET mensaje = 'La fecha inicial del dividendo No. ',
					i USING "&&&", ' es incorrecta. ',
					'Modifique el código del proceso.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			LET resul = 1
			EXIT FOR
		END IF
		IF rm_detalle[i].n65_fecha_fin >= rm_detalle[j].n65_fecha_fin
		THEN
			LET mensaje = 'La fecha final del dividendo No. ',
					i USING "&&&", ' es incorrecta. ',
					'Modifique el código del proceso.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			LET resul = 1
			EXIT FOR
		END IF
	END FOR
	IF resul THEN
		--EXIT FOR
		RETURN resul
	END IF
END FOR
FOR i = 1 TO vm_num_det 
	LET cod_liqrol = rm_detalle[i].n65_cod_liqrol
	LET fec_ini    = rm_detalle[i].n65_fecha_ini
	LET fec_fin    = rm_detalle[i].n65_fecha_fin
	DECLARE q_ptt CURSOR FOR
		SELECT rolt064.*
			FROM rolt064, rolt065
			WHERE n64_compania = vg_codcia AND
			      n64_cod_trab = rm_n64.n64_cod_trab AND
			      n64_estado <> 'E' AND
			      n64_cod_rubro  = rm_n64.n64_cod_rubro AND
			      n64_descontado < n64_val_prest+n64_val_interes AND
			      n64_compania   = n65_compania AND 
			      n64_num_prest  = n65_num_prest AND 	
			      n65_cod_liqrol = cod_liqrol AND 
			      n65_fecha_ini  = fec_ini AND 
			      n65_fecha_fin  = fec_fin AND 
			      n65_saldo > 0	
	FOREACH q_ptt INTO r_n64.*
		IF vm_flag_mant = 'I' THEN
			LET resul = 1
			EXIT FOREACH
		ELSE
			IF r_n64.n64_num_prest <> rm_n64.n64_num_prest THEN	
				LET resul = 1
				EXIT FOREACH
			END IF
		END IF
	END FOREACH	
END FOR
IF resul THEN
	LET mensaje = 'Existe otro préstamo: ', 
		       r_n64.n64_num_prest USING '&&&&&', 
		      ', que ya tiene un dividendo a ser descontado en la ',
		      'liquidación: ', cod_liqrol, ' ', 
		       fec_ini USING 'dd-mm-yyyy', '-',
		       fec_fin USING 'dd-mm-yyyy', '. ',
		      'Corrija los dividendos o en la cabecera utilice otro ',
		      'rubro de roles asociado.' 
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
END IF
RETURN resul

END FUNCTION



FUNCTION datos_defaults_cab()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE resul	 	SMALLINT

LET rm_n64.n64_compania     = vg_codcia
LET rm_n64.n64_estado       = 'A'
LET rm_n64.n64_fecha        = CURRENT
LET rm_n64.n64_val_prest    = 0
LET rm_n64.n64_val_interes  = 0
LET rm_n64.n64_porc_interes = rm_n60.n60_int_mensual 
LET rm_n64.n64_descontado   = 0
LET rm_n64.n64_moneda       = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_n64.n64_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada una moneda base en el sistema.', 'stop')
	EXIT PROGRAM
END IF
CALL retorna_paridad() RETURNING rm_n64.n64_paridad, resul
LET rm_n64.n64_usuario    = vg_usuario
LET rm_n64.n64_fecha      = TODAY
LET rm_n64.n64_fecing     = CURRENT
LET rm_par.num_pagos      = 1
DISPLAY BY NAME rm_n64.n64_fecha, rm_n64.n64_val_prest, rm_n64.n64_descontado,
		rm_n64.n64_moneda, r_g13.g13_nombre, rm_n64.n64_porc_interes,
                rm_n64.n64_val_interes
CALL muestra_estado()
CALL limpiar_detalle()

END FUNCTION



FUNCTION cargar_datos_liq(flag, i)
DEFINE flag, i, resul	SMALLINT
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE cod_liqrol	LIKE rolt003.n03_proceso

CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	EXIT PROGRAM
END IF
CASE flag
	WHEN 1
		LET cod_liqrol = rm_par.cod_liqrol
	WHEN 2
		LET cod_liqrol = rm_detalle[i].n65_cod_liqrol
END CASE
INITIALIZE rm_n32.*, rm_n36.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania   =  vg_codcia  
		  AND n32_cod_liqrol =  cod_liqrol
		  AND n32_cod_trab   =  rm_n64.n64_cod_trab
		  --AND n32_estado     <> 'E'
		  AND n32_estado     = 'C'
		ORDER BY n32_fecha_fin DESC
OPEN q_ultliq
FETCH q_ultliq INTO rm_n32.*
IF rm_n32.n32_compania IS NOT NULL THEN
	CLOSE q_ultliq
	FREE q_ultliq
	CALL retorna_ano_mes(rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso)
		RETURNING rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso
	RETURN 0
END IF
CLOSE q_ultliq
FREE q_ultliq
DECLARE q_decimos CURSOR FOR
	SELECT * FROM rolt036
		WHERE n36_compania = vg_codcia  
		  AND n36_proceso  = cod_liqrol
		  AND n36_cod_trab = rm_n64.n64_cod_trab
		  AND n36_estado   = 'A'
		ORDER BY n36_fecha_fin DESC
OPEN q_decimos
FETCH q_decimos INTO rm_n36.*
IF rm_n36.n36_compania IS NOT NULL THEN
	CLOSE q_decimos
	FREE q_decimos
	CALL retorna_ano_mes(rm_n36.n36_ano_proceso, rm_n36.n36_mes_proceso)
		RETURNING rm_n36.n36_ano_proceso, rm_n36.n36_mes_proceso
	RETURN 0
END IF
CLOSE q_decimos
FREE q_decimos
CALL retorna_n05(cod_liqrol) RETURNING r_n05.*, resul
IF resul THEN
	RETURN 1
END IF
IF cod_liqrol[1] = 'M' OR cod_liqrol[1] = 'Q' OR cod_liqrol[1] = 'S' THEN
	LET rm_n32.n32_ano_proceso = r_n01.n01_ano_proceso
	LET rm_n32.n32_mes_proceso = r_n01.n01_mes_proceso
	LET rm_n32.n32_fecha_fin   = r_n05.n05_fec_cierre
END IF
IF cod_liqrol = 'DC' OR cod_liqrol = 'DT' OR cod_liqrol = 'UT' THEN
	LET rm_n36.n36_ano_proceso = r_n01.n01_ano_proceso
	LET rm_n36.n36_mes_proceso = r_n01.n01_mes_proceso
	LET rm_n36.n36_fecha_fin   = r_n05.n05_fec_cierre
END IF
RETURN 0

END FUNCTION



FUNCTION retorna_n05(cod_liq)
DEFINE cod_liq		LIKE rolt003.n03_proceso
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE mensaje		VARCHAR(100)

INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = cod_liq
	  AND n05_activo   = 'N'
	ORDER BY n05_fec_cierre DESC
IF r_n05.n05_compania IS NULL THEN
	CALL fl_lee_proceso_roles(cod_liq) RETURNING r_n03.*
        LET mensaje = 'El proceso ', r_n03.n03_proceso, ' ',
			r_n03.n03_nombre CLIPPED, ' no está cerrado, y no se ',
			'le puede conceder préstamos.'
        CALL fl_mostrar_mensaje(mensaje, 'stop')
	RETURN r_n05.*, 1
END IF
RETURN r_n05.*, 0

END FUNCTION



FUNCTION generar_detalle(flag, l, ini)
DEFINE flag, l		SMALLINT
DEFINE ini, divi	LIKE rolt065.n65_secuencia
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE valor		LIKE rolt064.n64_val_prest
DEFINE cod_liqrol	LIKE rolt003.n03_proceso
DEFINE ano		LIKE rolt001.n01_ano_proceso
DEFINE mes		LIKE rolt001.n01_mes_proceso
DEFINE fecha_ini	LIKE rolt065.n65_fecha_ini
DEFINE fecha_fin	LIKE rolt065.n65_fecha_fin
DEFINE i		SMALLINT
DEFINE fraccion_tiempo	DECIMAL(3, 1)
DEFINE valor_deuda	LIKE rolt064.n64_val_prest
DEFINE tot_interes	LIKE rolt064.n64_val_prest
DEFINE tot_prestamo	LIKE rolt064.n64_val_prest
DEFINE meses		DECIMAL(4,2)

CASE flag
	WHEN 1
		LET cod_liqrol = rm_par.cod_liqrol
		LET fecha_ini  = rm_par.n65_fecha_ini
		LET fecha_fin  = rm_par.n65_fecha_fin
	WHEN 2
		LET cod_liqrol = rm_detalle[l].n65_cod_liqrol
		LET fecha_ini  = rm_detalle[l].n65_fecha_ini
		LET fecha_fin  = rm_detalle[l].n65_fecha_fin
END CASE
LET divi = ini
LET tot_prestamo = 0
IF rm_n64.n64_descontado = 0 THEN
	IF rm_par.frecuencia = 'M' THEN
		LET meses = rm_par.num_pagos 
	ELSE
		LET meses = rm_par.num_pagos / 2
	END IF 
	LET rm_n64.n64_val_interes = rm_n64.n64_val_prest * 
                             	(rm_n64.n64_porc_interes / 100) * meses
END IF
{
LET tot_prestamo = rm_n64.n64_val_prest + rm_n64.n64_val_interes - 
		   rm_n64.n64_descontado
--FOR i = 1 TO (l - 1)
	--LET tot_prestamo = tot_prestamo + rm_detalle[i].n65_valor
--END FOR
}
FOR i = l TO vm_num_det
	CALL fl_lee_proceso_roles(cod_liqrol) RETURNING r_n03.*
	LET rm_detalle[i].n65_secuencia  = divi
	LET rm_detalle[i].n65_cod_liqrol = cod_liqrol
	LET rm_detalle[i].n03_nombre_abr = r_n03.n03_nombre_abr
	LET rm_detalle[i].n65_fecha_ini  = fecha_ini
	LET rm_detalle[i].n65_fecha_fin  = fecha_fin
	IF flag = 1 THEN
		IF rm_par.frecuencia = 'Q' THEN
			LET mes = MONTH(fecha_ini)
			LET ano = YEAR(fecha_ini)
			IF cod_liqrol = 'Q1' THEN
				LET cod_liqrol = 'Q2'
				CALL fl_retorna_rango_fechas_proceso(vg_codcia,
					 cod_liqrol, ano, mes)
					RETURNING fecha_ini, fecha_fin
			ELSE
				LET cod_liqrol = 'Q1'
				LET ano = YEAR(fecha_ini  + 1 UNITS MONTH)
				LET mes = MONTH(fecha_ini + 1 UNITS MONTH)
				CALL fl_retorna_rango_fechas_proceso(vg_codcia,
					 cod_liqrol, ano, mes)
					RETURNING fecha_ini, fecha_fin
			END IF
		END IF			
		LET rm_detalle[i].n65_valor = (rm_n64.n64_val_prest -
						rm_n64.n64_descontado) 
		IF vm_flag_mant = 'M' THEN
			LET rm_detalle[i].n65_valor = (rm_detalle[i].n65_valor +
					       	       rm_n64.n64_val_interes) 
		END IF
		LET rm_detalle[i].n65_valor = rm_detalle[i].n65_valor /
					      rm_par.num_pagos
		LET rm_detalle[i].n65_saldo = rm_detalle[i].n65_valor
		LET tot_prestamo = tot_prestamo + rm_detalle[i].n65_valor
		IF i = vm_num_det THEN
			LET rm_detalle[i].n65_valor = 
				rm_detalle[i].n65_valor +
				(rm_n64.n64_val_prest -
			         rm_n64.n64_descontado - tot_prestamo)
				--(rm_n64.n64_val_prest - tot_prestamo)
			LET tot_prestamo = tot_prestamo + 
				(rm_n64.n64_val_prest -
			         rm_n64.n64_descontado - tot_prestamo)
				--(rm_n64.n64_val_prest - tot_prestamo)
			IF vm_flag_mant = 'M' THEN
				LET rm_detalle[i].n65_valor = 
				    rm_detalle[i].n65_valor +
				    rm_n64.n64_val_interes 
				LET tot_prestamo = tot_prestamo + 
				    rm_n64.n64_val_interes
			END IF
		END IF
		LET rm_detalle[i].n65_saldo = rm_detalle[i].n65_valor
		LET rm_detint[i].val_prest = rm_detalle[i].n65_valor
	END IF
	IF rm_par.frecuencia = 'M' THEN
		CALL retorna_fecha(fecha_ini) RETURNING fecha_ini
		CALL retorna_fecha(fecha_fin) RETURNING fecha_fin
	END IF
	LET divi = divi + 1
END FOR
{
IF flag = 1 THEN
	LET valor = rm_detalle[1].n65_valor * rm_par.num_pagos
	--IF valor <> rm_n64.n64_val_prest THEN
	IF valor < rm_n64.n64_val_prest - rm_n64.n64_descontado THEN
		LET rm_detalle[vm_num_det].n65_valor =
					rm_detalle[vm_num_det].n65_valor +
					(rm_n64.n64_val_prest - valor)
		LET rm_detalle[vm_num_det].n65_saldo =
					rm_detalle[vm_num_det].n65_valor
		LET rm_detint[vm_num_det].val_prest = 
					rm_detalle[vm_num_det].n65_valor
	END IF
END IF
}
IF rm_n64.n64_descontado = 0 AND vm_flag_mant = 'I' THEN
	IF rm_par.frecuencia = 'M' THEN
		LET meses = rm_par.num_pagos 
	ELSE
		LET meses = rm_par.num_pagos / 2
	END IF 
	LET fraccion_tiempo = rm_detalle[vm_num_det].n65_fecha_fin - 
                      	rm_detalle[1].n65_fecha_ini
	LET fraccion_tiempo = fraccion_tiempo / 30
	LET rm_n64.n64_val_interes = rm_n64.n64_val_prest * 
                             	(rm_n64.n64_porc_interes / 100) *
                             	meses
                             	--fraccion_tiempo  
	LET tot_interes = 0
	FOR i = 1 TO vm_num_det
		IF rm_detint[i].val_interes IS NULL THEN
			LET rm_detint[i].val_interes = 0
		END IF
		LET rm_detint[i].val_interes = rm_n64.n64_val_interes / rm_par.num_pagos
		LET tot_interes = tot_interes + rm_detint[i].val_interes
		IF i = vm_num_det THEN
			LET rm_detint[i].val_interes = rm_detint[i].val_interes +
				(rm_n64.n64_val_interes - tot_interes)
			LET tot_interes = tot_interes + 
					(rm_n64.n64_val_interes - tot_interes)
		END IF
		LET rm_detalle[i].n65_valor = rm_detint[i].val_prest +
				      	rm_detint[i].val_interes
		LET rm_detalle[i].n65_saldo = rm_detalle[i].n65_valor
	END FOR
END IF
CALL mostrar_detalle()

LET valor_deuda = rm_n64.n64_val_prest + rm_n64.n64_val_interes -
		  rm_n64.n64_descontado
DISPLAY BY NAME rm_n64.n64_val_interes, valor_deuda
--DISPLAY 0 TO n64_descontado

END FUNCTION



FUNCTION retorna_paridad()
DEFINE r_g14		RECORD LIKE gent014.*

IF rm_n64.n64_moneda = rg_gen.g00_moneda_base THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(rm_n64.n64_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('La paridad para está moneda no existe.','exclamation')
		RETURN r_g14.g14_tasa, 1
	END IF
END IF
RETURN r_g14.g14_tasa, 0

END FUNCTION



FUNCTION muestra_estado()
DEFINE estado		LIKE rolt064.n64_estado

LET estado = rm_n64.n64_estado
DISPLAY BY NAME rm_n64.n64_estado
CASE estado
	WHEN 'A'
		DISPLAY 'ACTIVO'    TO tit_estado
	WHEN 'P'
		DISPLAY 'PROCESADO' TO tit_estado
	WHEN 'E'
		DISPLAY 'ELIMINADO' TO tit_estado
	OTHERWISE
		CLEAR n64_estado, tit_estado
END CASE

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Div'		TO tit_col1
DISPLAY 'Liq.'		TO tit_col2
DISPLAY 'Descripción'	TO tit_col3
DISPLAY 'Fec. Ini.'	TO tit_col4
DISPLAY 'Fec. Fin.'	TO tit_col5
DISPLAY 'Valor'		TO tit_col6
DISPLAY 'Saldo'		TO tit_col7

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_current, vm_num_rows

END FUNCTION



FUNCTION muestra_contadores_det(current_det)
DEFINE current_det	SMALLINT

DISPLAY BY NAME current_det, vm_num_det

END FUNCTION 



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestrar_reg()

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestrar_reg()

END FUNCTION



FUNCTION mostrar_salir()

LET vm_flag_mant = 'C'
CLEAR FORM
CALL mostrar_botones()
IF vm_row_current > 0 THEN
	CALL muestrar_reg()
END IF

END FUNCTION



FUNCTION muestrar_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores()
CALL muestra_contadores_det(0)

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE valor_deuda	DECIMAL(14,2)

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_cons1 CURSOR FOR SELECT * FROM rolt064 WHERE ROWID = num_registro
OPEN q_cons1
FETCH q_cons1 INTO rm_n64.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME	rm_n64.n64_num_prest, rm_n64.n64_cod_rubro, rm_n64.n64_cod_trab,
		rm_n64.n64_moneda, rm_n64.n64_val_prest, rm_n64.n64_val_interes,
		rm_n64.n64_porc_interes, 
		rm_n64.n64_descontado, rm_n64.n64_referencia, rm_n64.n64_fecha
CALL fl_lee_rubro_roles(rm_n64.n64_cod_rubro) RETURNING r_n06.*
DISPLAY BY NAME r_n06.n06_nombre
CALL fl_lee_trabajador_roles(vg_codcia, rm_n64.n64_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME r_n30.n30_nombres
CALL fl_lee_moneda(rm_n64.n64_moneda) RETURNING r_g13.*
DISPLAY BY NAME r_g13.g13_nombre
LET valor_deuda = rm_n64.n64_val_prest + rm_n64.n64_val_interes - 
                  rm_n64.n64_descontado
DISPLAY BY NAME valor_deuda
CALL muestra_estado()
CALL cargar_detalle()
CALL mostrar_detalle()
LET rm_par.cod_liqrol    = rm_detalle[1].n65_cod_liqrol
LET rm_par.n65_fecha_ini = rm_detalle[1].n65_fecha_ini
LET rm_par.n65_fecha_fin = rm_detalle[1].n65_fecha_fin
LET rm_par.num_pagos     = vm_num_det
CLOSE q_cons1
FREE q_cons1

END FUNCTION



FUNCTION cargar_detalle()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n65		RECORD LIKE rolt065.*

DECLARE q_n65 CURSOR FOR
	SELECT * FROM rolt065
		WHERE n65_compania  = rm_n64.n64_compania
		  AND n65_num_prest = rm_n64.n64_num_prest
		  --AND n65_saldo > 0
		ORDER BY n65_secuencia
LET vm_num_det = 1
FOREACH q_n65 INTO r_n65.*
	IF vm_flag_mant = 'M' THEN
		IF r_n65.n65_saldo >= 0 
		AND r_n65.n65_saldo < (r_n65.n65_valor + r_n65.n65_val_interes)
		THEN
			CONTINUE FOREACH
		END IF
	END IF
	CALL fl_lee_proceso_roles(r_n65.n65_cod_liqrol) RETURNING r_n03.*
	LET rm_detalle[vm_num_det].n65_secuencia  = r_n65.n65_secuencia
	LET rm_detalle[vm_num_det].n65_cod_liqrol = r_n65.n65_cod_liqrol
	LET rm_detalle[vm_num_det].n03_nombre_abr = r_n03.n03_nombre_abr
	LET rm_detalle[vm_num_det].n65_fecha_ini  = r_n65.n65_fecha_ini
	LET rm_detalle[vm_num_det].n65_fecha_fin  = r_n65.n65_fecha_fin
	LET rm_detalle[vm_num_det].n65_valor      = r_n65.n65_valor +
						    r_n65.n65_val_interes
	LET rm_detalle[vm_num_det].n65_saldo      = r_n65.n65_saldo
	LET rm_detint[vm_num_det].val_prest       = r_n65.n65_valor
	LET rm_detint[vm_num_det].val_interes     = r_n65.n65_val_interes
	LET vm_num_det                            = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION grabar_detalle()
DEFINE r_n65		RECORD LIKE rolt065.*
DEFINE i, sec		SMALLINT

DELETE FROM rolt065
	WHERE n65_compania  = rm_n64.n64_compania
	  AND n65_num_prest = rm_n64.n64_num_prest
	  AND n65_saldo     = n65_valor + n65_val_interes
SELECT MAX(n65_secuencia) INTO sec FROM rolt065
	WHERE n65_compania  = rm_n64.n64_compania
	  AND n65_num_prest = rm_n64.n64_num_prest
IF sec IS NULL THEN
	LET sec = 0
END IF
FOR i = 1 TO vm_num_det
	LET sec = sec + 1
	LET r_n65.n65_compania    = rm_n64.n64_compania
	LET r_n65.n65_num_prest   = rm_n64.n64_num_prest
	--LET r_n65.n65_secuencia   = rm_detalle[i].n65_secuencia
	LET r_n65.n65_secuencia   = sec
	LET r_n65.n65_cod_liqrol  = rm_detalle[i].n65_cod_liqrol
	LET r_n65.n65_fecha_ini   = rm_detalle[i].n65_fecha_ini
	LET r_n65.n65_fecha_fin   = rm_detalle[i].n65_fecha_fin
	--LET r_n65.n65_valor       = rm_detint[i].val_prest
	--LET r_n65.n65_val_interes = rm_detint[i].val_interes
	LET r_n65.n65_valor       = rm_detalle[i].n65_saldo
	LET r_n65.n65_val_interes = 0
	LET r_n65.n65_saldo       = rm_detalle[i].n65_saldo
	INSERT INTO rolt065 VALUES(r_n65.*)
END FOR

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE i, lim		SMALLINT

CALL borrar_detalle()
LET lim = vm_num_det
IF lim > fgl_scr_size('rm_detalle') THEN
	LET lim = fgl_scr_size('rm_detalle')
END IF
FOR i = 1 TO lim
	DISPLAY rm_detalle[i].* TO rm_detalle[i].*
END FOR
CALL mostrar_total()

END FUNCTION



FUNCTION mostrar_total()
DEFINE i		SMALLINT

LET total_valor = 0
LET total_saldo = 0
FOR i = 1 TO vm_num_det
	LET total_valor = total_valor + rm_detalle[i].n65_valor
	LET total_saldo = total_saldo + rm_detalle[i].n65_saldo
END FOR
DISPLAY BY NAME total_valor, total_saldo

END FUNCTION



FUNCTION ubicarse_detalle()
DEFINE i, j		SMALLINT
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE r_n32		RECORD LIKE rolt032.*

CALL set_count(vm_num_det)
LET int_flag = 0
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F1,CONTROL-W) 
		CALL llamar_visor_teclas()
	ON KEY(F6)
		LET i = arr_curr()
		LET prog  = 'rolp303 '
		LET param = ' "', rm_detalle[i].n65_cod_liqrol, '" ',
		            ' "', rm_detalle[i].n65_fecha_ini,  '" ',
		            ' "', rm_detalle[i].n65_fecha_fin, '" "N" ',
		            ' 0 ', rm_n64.n64_cod_trab
		IF rm_detalle[i].n65_cod_liqrol[1,1] MATCHES "[SQM]" THEN
			CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)
		END IF
	--#BEFORE DISPLAY 
		LET i = arr_curr()
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i)
		--#CALL dialog.keysetlabel("F6","") 
		--#IF rm_detalle[i].n65_cod_liqrol[1,1] MATCHES "[SQM]" THEN
			--#CALL dialog.keysetlabel("F6","Liquid. Rol") 
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
CALL muestra_contadores_det(0)

END FUNCTION 



FUNCTION retorna_fecha(fecha_fin)
DEFINE fecha_fin	DATE
DEFINE fecha		RECORD
				ano		SMALLINT,
				mes		SMALLINT,
				dia		SMALLINT
			END RECORD

LET fecha.ano = YEAR(fecha_fin)
LET fecha.mes = MONTH(fecha_fin)
LET fecha.dia = DAY(fecha_fin)
CALL retorna_ano_mes(fecha.ano, fecha.mes) RETURNING fecha.ano, fecha.mes
IF fecha.dia >= 28 THEN
	IF fecha.mes = 2 THEN
		LET fecha.dia = 28
		IF (fecha.ano MOD 4) = 0 THEN
			LET fecha.dia = 29
		END IF
	ELSE
		IF fecha.mes = 4 OR fecha.mes = 6 OR fecha.mes = 9 OR
		   fecha.mes = 11 THEN
			LET fecha.dia = 30
		ELSE
			LET fecha.dia = 31
		END IF
	END IF
END IF
LET fecha_fin = MDY(fecha.mes, fecha.dia, fecha.ano)
RETURN fecha_fin

END FUNCTION 



FUNCTION retorna_ano_mes(ano, mes)
DEFINE ano		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso

LET mes = mes + 1
IF mes > 12 THEN
	LET mes = 1
	LET ano = ano + 1
END IF
RETURN ano, mes

END FUNCTION 



FUNCTION retorna_dia(cod_liq, flag, i)
DEFINE cod_liq		LIKE rolt003.n03_proceso
DEFINE flag, i		SMALLINT
DEFINE r_n02   		RECORD LIKE rolt002.*
DEFINE r_n03   		RECORD LIKE rolt003.*
DEFINE ano		LIKE rolt001.n01_ano_proceso
DEFINE mes		LIKE rolt001.n01_mes_proceso

IF cod_liq = 'Q1' OR cod_liq = 'Q2' OR cod_liq = 'ME' OR cod_liq = 'DC' OR
   cod_liq = 'DT' OR cod_liq = 'UT' THEN
  	CALL fl_lee_proceso_roles(rm_par.cod_liqrol) RETURNING r_n03.*
	RETURN r_n03.n03_dia_ini
END IF
IF cod_liq[1,1] = 'S' THEN
	CASE flag
		WHEN 1
			LET ano = YEAR(rm_par.n65_fecha_ini)
			LET mes = MONTH(rm_par.n65_fecha_ini)
		WHEN 2
			LET ano = YEAR(rm_detalle[i].n65_fecha_ini)
			LET mes = MONTH(rm_detalle[i].n65_fecha_ini)
	END CASE
	CALL fl_lee_periodos_semana(vg_codcia, ano, mes) RETURNING r_n02.*
	CASE cod_liq[2,2]
		WHEN '1'
			RETURN DAY(r_n02.n02_fecha_ini_1)
		WHEN '2'
			RETURN DAY(r_n02.n02_fecha_ini_2)
		WHEN '3'
			RETURN DAY(r_n02.n02_fecha_ini_3)
		WHEN '4'
			RETURN DAY(r_n02.n02_fecha_ini_4)
		WHEN '5'
			RETURN DAY(r_n02.n02_fecha_ini_5)
	END CASE
END IF

END FUNCTION 



FUNCTION mostrar_fechas(flag, i, j)
DEFINE flag, i, j	SMALLINT
DEFINE cod_liqrol	LIKE rolt003.n03_proceso
DEFINE fecha_ini	LIKE rolt065.n65_fecha_ini
DEFINE fecha_fin	LIKE rolt065.n65_fecha_fin
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso

CASE flag
	WHEN 1
		LET cod_liqrol = rm_par.cod_liqrol
		IF cod_liqrol[1] = 'M' OR cod_liqrol[1] = 'Q' OR
		   cod_liqrol[1] = 'S' THEN
			LET anio = rm_n32.n32_ano_proceso
			LET mes  = rm_n32.n32_mes_proceso
		END IF
		IF cod_liqrol = 'DT' OR cod_liqrol = 'DC' OR cod_liqrol = 'UT' THEN
			LET anio = rm_n36.n36_ano_proceso
			LET mes  = rm_n36.n36_mes_proceso
		END IF
	WHEN 2
		LET cod_liqrol = rm_detalle[i].n65_cod_liqrol
		LET mes        = MONTH(rm_detalle[i].n65_fecha_ini)
		LET anio       = YEAR(rm_detalle[i].n65_fecha_ini)
END CASE
CALL fl_retorna_rango_fechas_proceso(vg_codcia, cod_liqrol, anio, mes)
	RETURNING fecha_ini, fecha_fin
CASE flag
	WHEN 1
		LET rm_par.n65_fecha_ini = fecha_ini
		LET rm_par.n65_fecha_fin = fecha_fin
		DISPLAY BY NAME rm_par.n65_fecha_ini, rm_par.n65_fecha_fin
	WHEN 2
		LET rm_detalle[i].n65_fecha_ini = fecha_ini
		LET rm_detalle[i].n65_fecha_fin = fecha_fin
		DISPLAY rm_detalle[i].n65_fecha_ini TO
			rm_detalle[j].n65_fecha_ini
		DISPLAY rm_detalle[i].n65_fecha_fin TO
			rm_detalle[j].n65_fecha_fin
END CASE

END FUNCTION 



FUNCTION borrar_pantalla()

CALL borrar_cabecera()
CALL limpiar_detalle()
CALL borrar_detalle()

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR n64_estado, tit_estado, n64_num_prest, n64_cod_rubro, n06_nombre,
	n64_cod_trab, n30_nombres, n64_moneda, g13_nombre, n64_val_prest,
	n64_porc_interes, n64_val_interes, n64_descontado, valor_deuda, 
        n64_fecha, n64_referencia
INITIALIZE rm_n64.*, rm_par.* TO NULL

END FUNCTION



FUNCTION limpiar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].* TO NULL
END FOR

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR total_valor, total_saldo

END FUNCTION


 
FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
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



FUNCTION control_generacion_nov_roles()
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE mensaje		VARCHAR(200)
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n30		RECORD LIKE rolt030.*

INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
IF r_n05.n05_compania IS NULL THEN
	RETURN
END IF
IF r_n05.n05_proceso[1,1] <> 'M' AND r_n05.n05_proceso[1,1] <> 'Q' AND
	   r_n05.n05_proceso[1,1] <> 'S' THEN
	RETURN
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n64.n64_cod_trab) RETURNING r_n30.*
LET mensaje = 'Se va a regenerar novedad de ',r_n05.n05_proceso,
				' ', r_n05.n05_fecini_act USING "dd-mm-yyyy",
				' - ', r_n05.n05_fecfin_act USING "dd-mm-yyyy",
				' para el trabajador ', rm_n64.n64_cod_trab
				USING "&&&&", ' ', r_n30.n30_nombres CLIPPED
CALL fl_mostrar_mensaje(mensaje, 'info')
LET prog  = 'rolp200 '
LET param = ' ', r_n05.n05_proceso[1,1], ' ', rm_n64.n64_cod_trab,
	    ' ', r_n05.n05_proceso, ' ', r_n05.n05_fecini_act,
	    ' ', r_n05.n05_fecfin_act 
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION

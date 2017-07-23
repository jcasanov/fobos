--------------------------------------------------------------------------------
-- Titulo           : rolp214.4gl - Mantenimiento de Anticipos
-- Elaboracion      : 06-Ago-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp214 base modulo compañía [num_prest] [[nulo]]
--			[[cod_trab]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_r_rows	ARRAY[6000] OF INTEGER
DEFINE rm_detalle	ARRAY[300] OF RECORD
				n46_secuencia	LIKE rolt046.n46_secuencia,
				n46_cod_liqrol	LIKE rolt046.n46_cod_liqrol,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr,
				n46_fecha_ini	LIKE rolt046.n46_fecha_ini,
				n46_fecha_fin	LIKE rolt046.n46_fecha_fin,
				n46_valor	LIKE rolt046.n46_valor,
				n46_saldo	LIKE rolt046.n46_saldo
			END RECORD
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n45		RECORD LIKE rolt045.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_n36		RECORD LIKE rolt036.*
DEFINE rm_n39		RECORD LIKE rolt039.*
DEFINE rm_n41		RECORD LIKE rolt041.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_par		RECORD
				cod_liqrol	LIKE rolt046.n46_cod_liqrol,
				n03_nombre	LIKE rolt003.n03_nombre,
				n46_fecha_ini	LIKE rolt046.n46_fecha_ini,
				n46_fecha_fin	LIKE rolt046.n46_fecha_fin,
				num_pagos	SMALLINT
			END RECORD
DEFINE total_valor	DECIMAL(14,2)
DEFINE total_saldo	DECIMAL(14,2)
DEFINE vm_flag_mant	CHAR(1)
DEFINE rm_detprest	ARRAY[20] OF RECORD
				n46_num_prest	LIKE rolt046.n46_num_prest,
				n46_secuencia	LIKE rolt046.n46_secuencia,
				n46_cod_liqrol	LIKE rolt046.n46_cod_liqrol,
				n46_fecha_ini	LIKE rolt046.n46_fecha_ini,
				n46_fecha_fin	LIKE rolt046.n46_fecha_fin,
				n46_valor	LIKE rolt046.n46_valor,
				n46_saldo	LIKE rolt046.n46_saldo
			END RECORD
DEFINE rm_detliq	ARRAY[50] OF RECORD
				n32_cod_liqrol	LIKE rolt032.n32_cod_liqrol,
				n32_fecha_ini	LIKE rolt032.n32_fecha_ini,
				n32_fecha_fin	LIKE rolt032.n32_fecha_fin,
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE rm_dettotpre	ARRAY[20] OF RECORD
				n58_proceso	LIKE rolt058.n58_proceso,
				n03_nombre	LIKE rolt003.n03_nombre,
				n58_div_act	LIKE rolt058.n58_div_act,
				n58_num_div	LIKE rolt058.n58_num_div,
				n58_valor_div	LIKE rolt058.n58_valor_div,
				n58_valor_dist	LIKE rolt058.n58_valor_dist,
				n58_saldo_dist	LIKE rolt058.n58_saldo_dist
			END RECORD
DEFINE vm_proceso	LIKE rolt003.n03_proceso
DEFINE vm_aux_con_red	LIKE ctbt010.b10_cuenta
DEFINE vm_max_prest	SMALLINT
DEFINE vm_num_prest	SMALLINT
DEFINE vm_cur_prest	SMALLINT
DEFINE vm_max_detliq	SMALLINT
DEFINE vm_num_detliq	SMALLINT
DEFINE vm_cur_detliq	SMALLINT
DEFINE vm_max_dettot	SMALLINT
DEFINE vm_num_dettot	SMALLINT
DEFINE vm_cur_dettot	SMALLINT
DEFINE vm_cambio_valor	SMALLINT
DEFINE vm_lin_pag	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp214.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6
THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp214'
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
IF num_args() = 6 THEN
	INITIALIZE rm_n45.* TO NULL
	LET rm_n45.n45_num_prest = arg_val(4)
	LET rm_n45.n45_cod_trab  = arg_val(6)
	CALL control_capacidad_pago()
	EXIT PROGRAM
END IF
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en CONTABILIDAD.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
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
OPEN WINDOW w_rolf214_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf214_1 FROM '../forms/rolf214_1'
ELSE
	OPEN FORM f_rolf214_1 FROM '../forms/rolf214_1c'
END IF
DISPLAY FORM f_rolf214_1
CALL mostrar_botones()
LET vm_max_rows	   = 6000
LET vm_max_det     = 300
LET vm_max_dettot  = 20
LET vm_num_dettot  = 0
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
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Contabilización'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Capacidad Pago'
		HIDE OPTION 'Resumen'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Archivo Banco'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Anticipo Anterior'
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
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Capacidad Pago'
			SHOW OPTION 'Resumen'
			SHOW OPTION 'Imprimir'
			IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
				IF  rm_n45.n45_tipo_pago = 'T' AND
				   (rm_n45.n45_estado = 'A' OR
				    rm_n45.n45_estado = 'R')
				THEN
					SHOW OPTION 'Archivo Banco'
				ELSE
					HIDE OPTION 'Archivo Banco'
				END IF
			END IF
			SHOW OPTION 'Detalle'
			IF rm_n45.n45_prest_tran IS NOT NULL THEN
				SHOW OPTION 'Anticipo Anterior'
			ELSE
				HIDE OPTION 'Anticipo Anterior'
			END IF
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
       	COMMAND KEY('F') 'Forma de Pago' 'Forma de Pago del anticipo. '
		CALL control_forma_pago()
       	COMMAND KEY('Z') 'Contabilización' 'Contabilización del anticipo. '
		CALL control_contabilizacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Eliminar'
			IF rm_n45.n45_estado <> 'E' AND rm_n45.n45_estado <> 'T'
			THEN
				SHOW OPTION 'Capacidad Pago'
			ELSE
				HIDE OPTION 'Capacidad Pago'
			END IF
			SHOW OPTION 'Resumen'
			SHOW OPTION 'Imprimir'
			IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
				IF  rm_n45.n45_tipo_pago = 'T' AND
				   (rm_n45.n45_estado = 'A' OR
				    rm_n45.n45_estado = 'R')
				THEN
					SHOW OPTION 'Archivo Banco'
				ELSE
					HIDE OPTION 'Archivo Banco'
				END IF
			END IF
			SHOW OPTION 'Detalle'
			IF rm_n45.n45_prest_tran IS NOT NULL THEN
				SHOW OPTION 'Anticipo Anterior'
			ELSE
				HIDE OPTION 'Anticipo Anterior'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Forma de Pago'
				HIDE OPTION 'Contabilización'
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Capacidad Pago'
				HIDE OPTION 'Resumen'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Archivo Banco'
				HIDE OPTION 'Detalle'
				HIDE OPTION 'Anticipo Anterior'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Eliminar'
			IF rm_n45.n45_estado <> 'E' AND rm_n45.n45_estado <> 'T'
			THEN
				SHOW OPTION 'Capacidad Pago'
			ELSE
				HIDE OPTION 'Capacidad Pago'
			END IF
			SHOW OPTION 'Resumen'
			SHOW OPTION 'Imprimir'
			IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
				IF  rm_n45.n45_tipo_pago = 'T' AND
				   (rm_n45.n45_estado = 'A' OR
				    rm_n45.n45_estado = 'R')
				THEN
					SHOW OPTION 'Archivo Banco'
				ELSE
					HIDE OPTION 'Archivo Banco'
				END IF
			END IF
			SHOW OPTION 'Detalle'
			IF rm_n45.n45_prest_tran IS NOT NULL THEN
				SHOW OPTION 'Anticipo Anterior'
			ELSE
				HIDE OPTION 'Anticipo Anterior'
			END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
       	COMMAND KEY('E') 'Eliminar' 'Eliminar registro corriente. '
		CALL control_eliminacion()
		IF rm_n45.n45_estado = 'E' OR rm_n45.n45_estado = 'T' THEN
			HIDE OPTION 'Capacidad Pago'
		END IF
       	COMMAND KEY('P') 'Capacidad Pago' 'Capacidad de Pago del Empleado. '
		CALL control_capacidad_pago()
        COMMAND KEY('T') 'Resumen'   'Muestra totales por proceso.'
		CALL control_resumen(2)
        COMMAND KEY('K') 'Imprimir'   'Imprime el anticipo actual.'
		CALL control_imprimir()
        COMMAND KEY('L') 'Archivo Banco'   'Genera el archivo para las transf.'
		CALL generar_archivo()
        COMMAND KEY('D') 'Detalle'   'Se ubica en el detalle.'
		IF vm_num_rows > 0 THEN
			CALL ubicarse_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
        COMMAND KEY('X') 'Anticipo Anterior'   'Muestra anticipo anterior.'
		CALL ver_anticipo(2)
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
		IF rm_n45.n45_estado <> 'E' AND rm_n45.n45_estado <> 'T' THEN
			SHOW OPTION 'Capacidad Pago'
		ELSE
			HIDE OPTION 'Capacidad Pago'
		END IF
		IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
			IF  rm_n45.n45_tipo_pago = 'T' AND
			   (rm_n45.n45_estado = 'A' OR
			    rm_n45.n45_estado = 'R')
			THEN
				SHOW OPTION 'Archivo Banco'
			ELSE
				HIDE OPTION 'Archivo Banco'
			END IF
		END IF
		IF rm_n45.n45_prest_tran IS NOT NULL THEN
			SHOW OPTION 'Anticipo Anterior'
		ELSE
			HIDE OPTION 'Anticipo Anterior'
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
		IF rm_n45.n45_estado <> 'E' AND rm_n45.n45_estado <> 'T' THEN
			SHOW OPTION 'Capacidad Pago'
		ELSE
			HIDE OPTION 'Capacidad Pago'
		END IF
		IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
			IF  rm_n45.n45_tipo_pago = 'T' AND
			   (rm_n45.n45_estado = 'A' OR
			    rm_n45.n45_estado = 'R')
			THEN
				SHOW OPTION 'Archivo Banco'
			ELSE
				HIDE OPTION 'Archivo Banco'
			END IF
		END IF
		IF rm_n45.n45_prest_tran IS NOT NULL THEN
			SHOW OPTION 'Anticipo Anterior'
		ELSE
			HIDE OPTION 'Anticipo Anterior'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE resul, i		SMALLINT
DEFINE r_n45		RECORD LIKE rolt045.*

CALL fl_retorna_usuario()
LET vm_flag_mant = 'I'
CALL borrar_pantalla()
FOR i = 1 TO vm_max_dettot
	INITIALIZE rm_dettotpre[i].* TO NULL
END FOR
CALL datos_defaults_cab()
CALL generacion_datos(1) RETURNING resul
IF resul THEN
	RETURN
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	WHILE TRUE
		LET rm_n45.n45_num_prest = NULL
		SELECT NVL(MAX(n45_num_prest), 0) + 1
			INTO rm_n45.n45_num_prest
			FROM rolt045
			WHERE n45_compania = vg_codcia
		IF rm_n45.n45_num_prest IS NULL THEN
			LET rm_n45.n45_num_prest = 1
		END IF
		CALL fl_lee_cab_prestamo_roles(vg_codcia, rm_n45.n45_num_prest)
			RETURNING r_n45.*
		IF r_n45.n45_num_prest IS NULL THEN
			EXIT WHILE
		END IF
	END WHILE
	WHENEVER ERROR STOP
	LET rm_n45.n45_fecha  = CURRENT
	LET rm_n45.n45_fecing = CURRENT
	IF rm_n45.n45_tipo_pago = 'R' THEN
		LET rm_n45.n45_tipo_pago = 'T'
	END IF
	INSERT INTO rolt045 VALUES(rm_n45.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	CALL grabar_detalle()
	CALL grabar_resumen()
	CALL control_transferir_prestamo()
COMMIT WORK
IF rm_n45.n45_val_prest > 0 THEN
	CALL regenerar_novedades(rm_n45.n45_num_prest, 0)
	CALL regenerar_novedades(rm_n45.n45_prest_tran, 1)
ELSE
	CALL regenerar_novedades(rm_n45.n45_prest_tran, 1)
	CALL regenerar_novedades(rm_n45.n45_num_prest, 0)
END IF
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current            = vm_num_rows
LET vm_r_rows[vm_row_current] = num_aux
CALL muestrar_reg()
IF rm_n45.n45_sal_prest_ant > 0 OR rm_n45.n45_tipo_pago <> 'C' THEN
--IF rm_n45.n45_sal_prest_ant > 0 THEN
	CALL control_contabilizacion()
END IF
CALL control_imprimir()
CALL fl_mensaje_registro_ingresado()
LET vm_num_dettot = 0

END FUNCTION



FUNCTION control_modificacion()
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE resul, flag	SMALLINT
DEFINE resp		CHAR(6)

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_n45.n45_estado <> 'A' AND rm_n45.n45_estado <> 'R' THEN
	CALL fl_mostrar_mensaje('Solo puede modificar un anticipo cuando esta Activo o Redistribuido.', 'exclamation')
	RETURN
END IF
{--
IF rm_n45.n45_descontado > 0 THEN
	CALL fl_mostrar_mensaje('No puede modificar un anticipo que ya se comenzo a descontar.', 'exclamation')
	RETURN
END IF
--}
IF rm_n45.n45_val_prest + rm_n45.n45_sal_prest_ant + rm_n45.n45_valor_int -
   rm_n45.n45_descontado = 0
THEN
	CALL fl_mostrar_mensaje('No puede modificar un anticipo que ya esté cancelado.', 'exclamation')
	RETURN
END IF
LET flag = 1
CALL lee_prest_cont(vg_codcia, rm_n45.n45_num_prest) RETURNING r_n59.*
IF r_n59.n59_compania IS NOT NULL THEN
	CALL fl_mostrar_mensaje('No puede modificar un anticipo que ya esté contabilizado.', 'exclamation')
	IF vm_num_det <= 1 THEN
		LET flag     = 0
		LET int_flag = 0
		CALL fl_hacer_pregunta('Este anticipo tiene un solo dividendo. Desea dividirlo en varios dividendos ? ', 'Yes')
			RETURNING resp
		IF resp <> 'Yes' THEN
			RETURN
		END IF
	END IF
END IF
LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt045
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n45.*
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
IF rm_n45.n45_descontado > 0 THEN
	CALL modificar_dividendos_con_saldo() RETURNING resul
	IF int_flag THEN
		CALL mostrar_salir()
	END IF
ELSE
	CALL generacion_datos(flag) RETURNING resul
END IF
IF resul THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
LET rm_n45.n45_fecha  = CURRENT
IF rm_n45.n45_tipo_pago = 'R' THEN
	LET rm_n45.n45_tipo_pago = 'T'
END IF
UPDATE rolt045 SET * = rm_n45.* WHERE CURRENT OF q_up
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
CALL grabar_detalle()
CALL grabar_resumen()
WHENEVER ERROR STOP
COMMIT WORK
CALL regenerar_novedades(rm_n45.n45_num_prest, 0)
LET vm_flag_mant = 'C'
CALL muestrar_reg()
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION generacion_datos(flag)
DEFINE flag		SMALLINT

LET vm_cambio_valor = 1
CALL leer_cabecera()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 1
END IF
IF vm_flag_mant = 'I' OR vm_cambio_valor OR NOT flag THEN
	CALL parametros_generar_detalle(flag)
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN 1
	END IF
	IF flag THEN
		CALL control_forma_pago()
		IF int_flag THEN
			CALL mostrar_salir()
			RETURN 1
		END IF
	END IF
	CALL generar_detalle(1, 1, vm_num_det, 1)
END IF
CALL leer_detalle()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 1
END IF
IF vm_flag_mant <> 'I' THEN
	CALL control_forma_pago()
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN 1
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION control_consulta()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE query		CHAR(1800)
DEFINE expr_sql		CHAR(1200)
DEFINE num_reg		INTEGER

CLEAR FORM
CALL mostrar_botones()
IF num_args() <> 3 THEN
	LET expr_sql = ' n45_num_prest = ', arg_val(4)
ELSE
	LET int_flag = 0 
	CONSTRUCT BY NAME expr_sql ON n45_estado, n45_num_prest, n45_cod_rubro,
		n45_prest_tran, n45_cod_trab, n45_usuario, n45_moneda,
		n45_val_prest, n45_mes_gracia, n45_porc_int, n45_valor_int,
		n45_sal_prest_ant, n45_descontado, n45_paridad, n45_referencia,
		n45_fecha
		ON KEY(F2)
			IF INFIELD(n45_num_prest) THEN
				CALL fl_ayuda_anticipos(vg_codcia, 'X')
					RETURNING r_n45.n45_num_prest
				IF r_n45.n45_num_prest IS NOT NULL THEN
					LET rm_n45.n45_num_prest =
							r_n45.n45_num_prest
					DISPLAY BY NAME rm_n45.n45_num_prest
				END IF
			END IF
			IF INFIELD(n45_cod_rubro) THEN
				CALL fl_ayuda_rubros_generales_roles('DE', 'T',
							'T', 'S', 'T', 'T')
					RETURNING r_n06.n06_cod_rubro, 
						  r_n06.n06_nombre 
				IF r_n06.n06_cod_rubro IS NOT NULL THEN
					LET rm_n45.n45_cod_rubro =
							r_n06.n06_cod_rubro
					DISPLAY BY NAME rm_n45.n45_cod_rubro,
							r_n06.n06_nombre
				END IF
			END IF
			IF INFIELD(n45_prest_tran) THEN
				CALL fl_ayuda_anticipos(vg_codcia, 'T')
					RETURNING r_n45.n45_prest_tran
				IF r_n45.n45_prest_tran IS NOT NULL THEN
					LET rm_n45.n45_prest_tran =
							r_n45.n45_prest_tran
					DISPLAY BY NAME rm_n45.n45_prest_tran
				END IF
			END IF
			IF INFIELD(n45_cod_trab) THEN
	                        CALL fl_ayuda_codigo_empleado(vg_codcia)
	                                RETURNING r_n30.n30_cod_trab,
						  r_n30.n30_nombres
				IF r_n30.n30_cod_trab IS NOT NULL THEN
	                                LET rm_n45.n45_cod_trab =
							r_n30.n30_cod_trab
        	                        DISPLAY BY NAME rm_n45.n45_cod_trab,
							r_n30.n30_nombres
                        	END IF
	                END IF
			IF INFIELD(n45_moneda) THEN
				CALL fl_ayuda_monedas()
					RETURNING r_g13.g13_moneda,
						  r_g13.g13_nombre,
						  r_g13.g13_decimales
				IF r_g13.g13_moneda IS NOT NULL THEN
					LET rm_n45.n45_moneda = r_g13.g13_moneda
					DISPLAY BY NAME rm_n45.n45_moneda,
							r_g13.g13_nombre
				END IF
			END IF
			LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD n45_estado
			LET rm_n45.n45_estado = GET_FLDBUF(n45_estado)
			IF rm_n45.n45_estado IS NOT NULL THEN
				CALL muestra_estado()
			ELSE
				CLEAR n45_estado, tit_estado
			END IF
	END CONSTRUCT
	IF int_flag THEN
		CALL mostrar_salir()
		RETURN
	END IF
END IF
LET query = 'SELECT *, ROWID FROM rolt045 ',
		' WHERE n45_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2 ' CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_n45.*, num_reg
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
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE confir		CHAR(6)
DEFINE resp		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
--IF rm_n45.n45_val_prest = 0 AND rm_n45.n45_estado = 'R' THEN
IF rm_n45.n45_estado = 'R' THEN
	CALL fl_mostrar_mensaje('No puede eliminar un anticipo que ya esta REDEFINIDO.', 'exclamation')
	RETURN
END IF
IF rm_n45.n45_estado <> 'A' AND rm_n45.n45_estado <> 'R' THEN
	CALL fl_mostrar_mensaje('No puede eliminar un anticipo que no esté ACTIVO o REDISTRIBUIDO.', 'exclamation')
	RETURN
END IF
IF rm_n45.n45_descontado > 0 THEN
	CALL fl_mostrar_mensaje('No puede eliminar un anticipo que se ha descontado uno o mas dividendos.', 'exclamation')
	RETURN
END IF
IF rm_n45.n45_val_prest + rm_n45.n45_sal_prest_ant + rm_n45.n45_valor_int -
   rm_n45.n45_descontado = 0
THEN
	CALL fl_mostrar_mensaje('No puede eliminar un anticipo que ya esté cancelado.', 'exclamation')
	RETURN
END IF
CALL fl_hacer_pregunta('Esta seguro que desea ELIMINAR este anticipo ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
CALL lee_prest_cont(vg_codcia, rm_n45.n45_num_prest) RETURNING r_n59.*
IF r_n59.n59_compania IS NOT NULL THEN
	CALL fl_hacer_pregunta('Este anticipo tiene contabilización. Desea continuar con la eliminación ?', 'No')
		RETURNING resp
	IF resp <> 'Yes' THEN
		RETURN
	END IF
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_elimin CURSOR FOR
	SELECT * FROM rolt045
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_elimin
FETCH q_elimin INTO rm_n45.*
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
CALL eliminar_diario_contable(r_n59.*)
CALL regenerar_novedades(rm_n45.n45_num_prest, 0)
CALL fl_mostrar_mensaje('Se ha eliminado esté anticipo Ok.', 'info')

END FUNCTION



FUNCTION elimina_registro()
DEFINE estado		LIKE rolt045.n45_estado

IF rm_n45.n45_estado = 'A' THEN
	LET estado = 'E'
END IF
IF rm_n45.n45_estado = 'E' THEN
	LET estado = 'A'
END IF
UPDATE rolt045 SET n45_estado    = estado,
		   n45_fec_elimi = CURRENT
	WHERE CURRENT OF q_elimin
LET rm_n45.n45_fec_elimi = CURRENT
LET rm_n45.n45_estado    = estado
CALL muestra_estado()
DISPLAY BY NAME rm_n45.n45_fec_elimi

END FUNCTION



FUNCTION eliminar_diario_contable(r_n59)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE resp		CHAR(6)

CALL fl_lee_comprobante_contable(r_n59.n59_compania, r_n59.n59_tipo_comp,
					r_n59.n59_num_comp)
	RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	RETURN
END IF
IF r_b12.b12_estado = 'E' THEN
	RETURN
END IF
CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
				r_b12.b12_num_comp, 'D')
BEGIN WORK
SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
UPDATE ctbt012 SET b12_estado     = 'E',
		   b12_fec_modifi = CURRENT 
	WHERE b12_compania  = r_b12.b12_compania
	  AND b12_tipo_comp = r_b12.b12_tipo_comp
	  AND b12_num_comp  = r_b12.b12_num_comp
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se puede eliminar el diario contable del Anticipo. LLAME AL ADMINISTRADOR.', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
COMMIT WORK

END FUNCTION



FUNCTION control_capacidad_pago()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul	 	SMALLINT
DEFINE r_n30		RECORD LIKE rolt030.*

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 21
LET num_cols = 70
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf214_3 AT row_ini, 06 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf214_3 FROM '../forms/rolf214_3'
ELSE
	OPEN FORM f_rolf214_3 FROM '../forms/rolf214_3c'
END IF
DISPLAY FORM f_rolf214_3
CALL mostrar_botones_cap()
CALL preparar_query_cap() RETURNING resul
IF resul THEN
	RETURN
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab) RETURNING r_n30.*
DISPLAY rm_n45.n45_cod_trab TO n32_cod_trab
DISPLAY BY NAME r_n30.n30_nombres
WHILE TRUE
	IF vm_num_prest > 0 THEN
		CALL detalle_detant()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	IF vm_num_detliq > 0 THEN
		CALL detalle_detliq()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
END WHILE
CLOSE WINDOW w_rolf214_3

END FUNCTION



FUNCTION mostrar_botones_cap()

DISPLAY 'Antic.'	TO tit_col1
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



FUNCTION preparar_query_cap()
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n46		RECORD LIKE rolt046.*
DEFINE fec_ini		LIKE rolt032.n32_fecha_ini
DEFINE fec_fin		LIKE rolt032.n32_fecha_fin
DEFINE total_valor	DECIMAL(14,2)
DEFINE total_saldo	DECIMAL(14,2)
DEFINE total_ing	DECIMAL(14,2)
DEFINE total_egr	DECIMAL(14,2)
DEFINE total_net	DECIMAL(14,2)
DEFINE lim		SMALLINT

LET vm_max_prest  = 20
LET vm_max_detliq = 50
INITIALIZE r_n32.*, r_n46.* TO NULL
DECLARE q_detant CURSOR FOR
	SELECT rolt046.* FROM rolt045, rolt046
		WHERE n45_compania  = vg_codcia
		  AND n45_cod_trab  = rm_n45.n45_cod_trab
		  AND n45_estado    IN ("A", "R")
		  AND n45_val_prest + n45_sal_prest_ant + n45_valor_int >
								n45_descontado
		  AND n46_compania  = n45_compania
		  AND n46_num_prest = n45_num_prest
		  AND n46_saldo     > 0
		ORDER BY n46_num_prest, n46_secuencia
OPEN q_detant
FETCH q_detant INTO r_n46.*
LET fec_fin = TODAY
LET fec_ini = fec_fin - 1 UNITS YEAR
DECLARE q_detliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania   = vg_codcia
		  AND n32_fecha_ini >= fec_ini
		  AND n32_fecha_fin <= fec_fin
		  AND n32_cod_trab   = rm_n45.n45_cod_trab
		  AND n32_estado    <> 'E'
		ORDER BY n32_fecha_fin DESC
OPEN q_detliq
FETCH q_detliq INTO r_n32.*
IF r_n32.n32_compania IS NULL AND r_n46.n46_compania IS NULL THEN
	CLOSE q_detant
	FREE q_detant
	CLOSE q_detliq
	FREE q_detliq
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
LET total_valor  = 0
LET total_saldo  = 0
LET vm_num_prest = 1
FOREACH q_detant INTO r_n46.*
	IF r_n46.n46_num_prest = rm_n45.n45_num_prest THEN
		CONTINUE FOREACH
	END IF
	LET rm_detprest[vm_num_prest].n46_num_prest  = r_n46.n46_num_prest
	LET rm_detprest[vm_num_prest].n46_secuencia  = r_n46.n46_secuencia
	LET rm_detprest[vm_num_prest].n46_cod_liqrol = r_n46.n46_cod_liqrol
	LET rm_detprest[vm_num_prest].n46_fecha_ini  = r_n46.n46_fecha_ini
	LET rm_detprest[vm_num_prest].n46_fecha_fin  = r_n46.n46_fecha_fin
	LET rm_detprest[vm_num_prest].n46_valor      = r_n46.n46_valor
	LET rm_detprest[vm_num_prest].n46_saldo      = r_n46.n46_saldo
	LET total_valor = total_valor + rm_detprest[vm_num_prest].n46_valor
	LET total_saldo = total_saldo + rm_detprest[vm_num_prest].n46_saldo
	LET vm_num_prest = vm_num_prest + 1
	IF vm_num_prest > vm_max_prest THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_prest  = vm_num_prest - 1
IF vm_num_prest > 0 THEN
	LET lim = vm_num_prest
	IF lim > fgl_scr_size('rm_detprest') THEN
		LET lim = fgl_scr_size('rm_detprest')
	END IF
	LET vm_cur_prest = 0
	CALL muestra_contadores_detprest()
	FOR vm_cur_prest = 1 TO lim
		DISPLAY rm_detprest[vm_cur_prest].* TO
			rm_detprest[vm_cur_prest].*
	END FOR
	DISPLAY BY NAME total_valor, total_saldo
END IF
LET total_ing     = 0
LET total_egr     = 0
LET total_net     = 0
LET vm_num_detliq = 1
FOREACH q_detliq INTO r_n32.*
	LET rm_detliq[vm_num_detliq].n32_cod_liqrol = r_n32.n32_cod_liqrol
	LET rm_detliq[vm_num_detliq].n32_fecha_ini  = r_n32.n32_fecha_ini
	LET rm_detliq[vm_num_detliq].n32_fecha_fin  = r_n32.n32_fecha_fin
	LET rm_detliq[vm_num_detliq].n32_tot_ing    = r_n32.n32_tot_ing
	LET rm_detliq[vm_num_detliq].n32_tot_egr    = r_n32.n32_tot_egr
	LET rm_detliq[vm_num_detliq].n32_tot_neto   = r_n32.n32_tot_neto
	LET total_ing = total_ing + rm_detliq[vm_num_detliq].n32_tot_ing
	LET total_egr = total_egr + rm_detliq[vm_num_detliq].n32_tot_egr
	LET total_net = total_net + rm_detliq[vm_num_detliq].n32_tot_neto
	LET vm_num_detliq = vm_num_detliq + 1
	IF vm_num_detliq > vm_max_detliq THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_detliq = vm_num_detliq - 1
IF vm_num_detliq > 0 THEN
	LET lim = vm_num_detliq
	IF lim > fgl_scr_size('rm_detliq') THEN
		LET lim = fgl_scr_size('rm_detliq')
	END IF
	LET vm_cur_detliq = 0
	CALL muestra_contadores_detliq()
	FOR vm_cur_detliq = 1 TO lim
		DISPLAY rm_detliq[vm_cur_detliq].* TO rm_detliq[vm_cur_detliq].*
	END FOR
	DISPLAY BY NAME total_ing, total_egr, total_net
END IF
RETURN 0

END FUNCTION



FUNCTION detalle_detant()
DEFINE j		SMALLINT

CALL set_count(vm_num_prest)
DISPLAY ARRAY rm_detprest TO rm_detprest.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		IF vm_num_detliq > 0 THEN
			LET int_flag = 0
			EXIT DISPLAY
		END IF
	ON KEY(F6)
		IF num_args() <> 5 THEN
			LET vm_cur_prest = arr_curr()
			CALL ver_anticipo(1)
		END IF
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F1","") 
		--#IF vm_num_detliq > 0 THEN
			--#CALL dialog.keysetlabel("F5", "Ultimas 12 Liq.") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#CALL dialog.keysetlabel("F6", "Anticipo") 
		--#IF num_args() = 5 THEN
			--#CALL dialog.keysetlabel("F6", "") 
		--#END IF
		--#CALL dialog.keysetlabel("F7", "") 
	--#BEFORE ROW 
		--#LET vm_cur_prest = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_detprest()
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY
END DISPLAY
LET vm_cur_prest = 0
--#CALL muestra_contadores_detprest()

END FUNCTION 



FUNCTION detalle_detliq()
DEFINE j		SMALLINT

CALL set_count(vm_num_detliq)
DISPLAY ARRAY rm_detliq TO rm_detliq.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		IF vm_num_prest > 0 THEN
			LET int_flag = 0
			EXIT DISPLAY
		END IF
	ON KEY(F7)
		LET vm_cur_detliq = arr_curr()
		CALL ver_liquidacion()
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F1","") 
		--#IF vm_num_prest > 0 THEN
			--#CALL dialog.keysetlabel("F5", "Ant. Pendientes") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#CALL dialog.keysetlabel("F6", "") 
		--#CALL dialog.keysetlabel("F7", "Liquidación") 
	--#BEFORE ROW 
		--#LET vm_cur_detliq = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_detliq()
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
LET vm_cur_detliq = 0
--#CALL muestra_contadores_detliq()

END FUNCTION 



FUNCTION muestra_contadores_detprest()

DISPLAY BY NAME vm_cur_prest, vm_num_prest

END FUNCTION 



FUNCTION muestra_contadores_detliq()

DISPLAY BY NAME vm_cur_detliq, vm_num_detliq

END FUNCTION 



FUNCTION leer_cabecera()
DEFINE r_n03, r_n03_2	RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n16		RECORD LIKE rolt016.*
DEFINE r_n18		RECORD LIKE rolt018.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE dia		LIKE rolt003.n03_dia_fin
DEFINE val_prest	LIKE rolt045.n45_val_prest
DEFINE val_p		LIKE rolt045.n45_val_prest
DEFINE fecha_p		LIKE rolt045.n45_fecha
DEFINE mes_g		LIKE rolt045.n45_mes_gracia
DEFINE porc_i		LIKE rolt045.n45_porc_int
DEFINE deuda		DECIMAL(14,2)
DEFINE deuda_c		VARCHAR(13)
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_n45.n45_cod_rubro, rm_n45.n45_cod_trab, rm_n45.n45_val_prest,
	rm_n45.n45_mes_gracia, rm_n45.n45_porc_int, rm_n45.n45_referencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n45.n45_cod_rubro, rm_n45.n45_cod_trab,
				 rm_n45.n45_val_prest, rm_n45.n45_mes_gracia,
				 rm_n45.n45_porc_int, rm_n45.n45_referencia)
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
	ON KEY(F2)
		IF INFIELD(n45_cod_rubro) THEN
			CALL fl_ayuda_rubros_generales_roles('DE', 'T', 'T',
								'T', 'T', 'T')
				RETURNING r_n06.n06_cod_rubro, 
					  r_n06.n06_nombre 
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_n45.n45_cod_rubro = r_n06.n06_cod_rubro
				DISPLAY BY NAME rm_n45.n45_cod_rubro,
						r_n06.n06_nombre
			END IF
		END IF
		IF INFIELD(n45_cod_trab) THEN
			IF vm_flag_mant = 'M' THEN
				CONTINUE INPUT
                	END IF
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n45.n45_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n45.n45_cod_trab,
						r_n30.n30_nombres
                        END IF
                END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		IF vm_flag_mant = 'M' THEN
			LET val_p           = rm_n45.n45_val_prest
			LET vm_cambio_valor = 0
		END IF
	BEFORE FIELD n45_cod_rubro
		LET r_n06.n06_cod_rubro = rm_n45.n45_cod_rubro
	BEFORE FIELD n45_cod_trab
		IF vm_flag_mant = 'M' THEN
			LET r_n45.n45_cod_trab = rm_n45.n45_cod_trab
		END IF
	BEFORE FIELD n45_val_prest
		LET val_prest = rm_n45.n45_val_prest
	BEFORE FIELD n45_mes_gracia
		LET mes_g = rm_n45.n45_mes_gracia
	BEFORE FIELD n45_porc_int
		LET porc_i = rm_n45.n45_porc_int
	AFTER FIELD n45_cod_rubro
		IF rm_n45.n45_cod_rubro IS NULL THEN
			LET rm_n45.n45_cod_rubro = r_n06.n06_cod_rubro
			CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro)
				RETURNING r_n06.*
			DISPLAY BY NAME rm_n45.n45_cod_rubro, r_n06.n06_nombre
		END IF
		IF rm_n45.n45_cod_rubro IS NOT NULL THEN
			CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro)
				RETURNING r_n06.*
			IF r_n06.n06_cod_rubro IS NULL  THEN
				CALL fl_mostrar_mensaje('Rubro no existe.','exclamation')
				NEXT FIELD n45_cod_rubro
			END IF
			DISPLAY BY NAME r_n06.n06_nombre
			IF r_n06.n06_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n45_cod_rubro
			END IF
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
				LET rm_n45.n45_tipo_pago = 'E'
			END IF
		ELSE
			CLEAR n06_nombre
		END IF
	AFTER FIELD n45_cod_trab
		IF vm_flag_mant = 'M' THEN
			LET rm_n45.n45_cod_trab = r_n45.n45_cod_trab
			DISPLAY BY NAME rm_n45.n45_cod_trab
			CONTINUE INPUT
		END IF
		IF rm_n45.n45_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n45.n45_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n45_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mensaje_estado_bloqueado()
				--NEXT FIELD n45_cod_trab
			END IF
			LET rm_n45.n45_prest_tran    = NULL
			LET rm_n45.n45_sal_prest_ant = 0
			DECLARE q_n45 CURSOR FOR
				SELECT * FROM rolt045
					WHERE n45_compania = vg_codcia
					  AND n45_cod_trab = rm_n45.n45_cod_trab
					  AND n45_cod_rubro=rm_n45.n45_cod_rubro
					  AND n45_estado   IN ('A', 'R')
			OPEN q_n45
			FETCH q_n45 INTO r_n45.*
			IF STATUS <> NOTFOUND THEN
				SELECT NVL(SUM(n45_val_prest + n45_sal_prest_ant
				 	+ n45_valor_int - n45_descontado), 0)
					INTO deuda FROM rolt045
					WHERE n45_compania = vg_codcia
					  AND n45_cod_trab = rm_n45.n45_cod_trab
					  AND n45_cod_rubro=rm_n45.n45_cod_rubro
					  AND n45_estado   IN ('A', 'R')
 				LET deuda_c = deuda USING "--,---,--&.##"
				CALL fl_mostrar_mensaje('Este empleado ya tiene una deuda de ' || fl_justifica_titulo('I', deuda_c, 13) CLIPPED || '.', 'exclamation')
				LET rm_n45.n45_sal_prest_ant = deuda
				DECLARE q_ant CURSOR FOR
					SELECT n45_num_prest, n45_fecha
						FROM rolt045
						WHERE n45_compania  = vg_codcia
						  AND n45_cod_trab  =
							rm_n45.n45_cod_trab
						  AND n45_cod_rubro =
							rm_n45.n45_cod_rubro
						  AND n45_estado   IN ('A', 'R')
					ORDER BY n45_fecha DESC
				OPEN q_ant
				FETCH q_ant INTO rm_n45.n45_prest_tran, fecha_p
				CLOSE q_ant
				FREE q_ant
			END IF
			CLOSE q_n45
			FREE q_n45
			DISPLAY BY NAME rm_n45.n45_sal_prest_ant,
					rm_n45.n45_prest_tran
			CALL proceso_activo_nomina(rm_n45.n45_prest_tran, 1, 0)
				RETURNING r_n05.*, resul
			IF NOT resul THEN
				CALL fl_lee_proceso_roles(r_n05.n05_proceso)
					RETURNING r_n03.*
				LET dia = r_n03.n03_dia_fin
				IF r_n03.n03_dia_fin IS NULL THEN
					LET dia = DAY(MDY(MONTH(TODAY +
						1 UNITS MONTH), 01,
						YEAR(TODAY + 1 UNITS MONTH)) -
						1 UNITS DAY)
				END IF
				IF EXTEND(TODAY, MONTH TO DAY) >
				   EXTEND(MDY(MONTH(TODAY), dia, YEAR(TODAY)),
					MONTH TO DAY)
				THEN
					CALL fl_mostrar_mensaje('No puede Redistribuír el saldo anterior, ya que el proceso ' || r_n05.n05_proceso || ' ' || r_n03.n03_nombre CLIPPED || ' esta abierto y no esta contabilizado, ademas la fecha de hoy es posterior a la fecha de cierre.', 'exclamation')
					--LET int_flag = 1
					--RETURN
				END IF
			END IF
		ELSE
			CLEAR n30_nombres
		END IF
		CALL calcular_interes()
	AFTER FIELD n45_mes_gracia
		IF vm_flag_mant = 'M' THEN
			LET rm_n45.n45_mes_gracia = mes_g
			DISPLAY BY NAME rm_n45.n45_mes_gracia
			CONTINUE INPUT
		END IF
		IF rm_n45.n45_mes_gracia IS NULL THEN
			LET rm_n45.n45_mes_gracia = mes_g
			DISPLAY BY NAME rm_n45.n45_mes_gracia
		END IF
		IF rm_n45.n45_mes_gracia > 0 THEN
			IF rm_n45.n45_mes_gracia > rm_n90.n90_mes_gra_ant THEN
				CALL fl_mostrar_mensaje('Los meses de gracia no pueden ser mayor que los meses de gracia configurado.', 'exclamation')
				LET rm_n45.n45_mes_gracia =
							rm_n90.n90_mes_gra_ant
				DISPLAY BY NAME rm_n45.n45_mes_gracia
				NEXT FIELD n45_mes_gracia
			END IF
		END IF
	AFTER FIELD n45_porc_int
		IF vm_flag_mant = 'M' THEN
			LET rm_n45.n45_porc_int = porc_i
			DISPLAY BY NAME rm_n45.n45_porc_int
			CONTINUE INPUT
		END IF
		IF rm_n45.n45_porc_int IS NULL THEN
			LET rm_n45.n45_porc_int = porc_i
			DISPLAY BY NAME rm_n45.n45_porc_int
		END IF
		IF rm_n45.n45_porc_int > 0 THEN
			IF rm_n45.n45_porc_int > rm_n90.n90_porc_int_ant THEN
				CALL fl_mostrar_mensaje('El porcentaje interes no puede ser mayor que el porcentaje configurado.', 'exclamation')
				LET rm_n45.n45_porc_int =rm_n90.n90_porc_int_ant
				DISPLAY BY NAME rm_n45.n45_porc_int
				NEXT FIELD n45_porc_int
			END IF
		END IF
		CALL calcular_interes()
	AFTER FIELD n45_val_prest
		IF rm_n45.n45_descontado > 0 OR rm_n45.n45_val_prest IS NULL
		THEN
			LET rm_n45.n45_val_prest = val_prest
			DISPLAY BY NAME rm_n45.n45_val_prest
			CONTINUE INPUT
		END IF
		CALL calcular_interes()
	AFTER INPUT
		IF rm_n45.n45_val_prest = 0 AND rm_n45.n45_sal_prest_ant = 0
		THEN
			CALL fl_mostrar_mensaje('Debe ingresar el valor del anticipo que sea mayor a cero.', 'exclamation')
			NEXT FIELD n45_val_prest
		END IF
		IF vm_flag_mant = 'M' THEN
			IF val_p <> rm_n45.n45_val_prest THEN
				LET vm_cambio_valor = 1
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION parametros_generar_detalle(flag)
DEFINE flag		SMALLINT
DEFINE resp		CHAR(6)

IF flag THEN
	CALL fl_hacer_pregunta('Desea generar los dividendos, para descontarlos en un solo proceso de nomina ?', 'No')
		RETURNING resp
END IF
IF resp = 'Yes' OR NOT flag THEN
	CALL leer_parametros()
	RETURN
END IF
CALL control_resumen(1)

END FUNCTION



FUNCTION leer_parametros()
DEFINE lin_men		SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE dia	 	SMALLINT
DEFINE resul	 	SMALLINT
DEFINE num_p		SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE fec_ini		LIKE rolt046.n46_fecha_ini
DEFINE fec_fin		LIKE rolt046.n46_fecha_fin
DEFINE cod_liq		LIKE rolt003.n03_proceso
DEFINE nombre		LIKE rolt003.n03_nombre

LET lin_men  = 0
LET num_rows = 11
LET num_cols = 57
IF vg_gui = 0 THEN
	LET lin_men  = 1
	LET num_rows = 12
	LET num_cols = 58
END IF
OPEN WINDOW w_rolf214_2 AT 09, 13 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_men, BORDER,
		  MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf214_2 FROM '../forms/rolf214_2'
ELSE
	OPEN FORM f_rolf214_2 FROM '../forms/rolf214_2c'
END IF
DISPLAY FORM f_rolf214_2
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
				IF rm_par.n46_fecha_ini IS NOT NULL THEN
					IF rm_par.cod_liqrol[1] = 'M' OR
					   rm_par.cod_liqrol[1] = 'Q' OR
					   rm_par.cod_liqrol[1] = 'S' THEN
						LET rm_n32.n32_ano_proceso =
						YEAR(rm_par.n46_fecha_ini)
						LET rm_n32.n32_mes_proceso =
						MONTH(rm_par.n46_fecha_ini)
					END IF
					IF rm_par.cod_liqrol = 'DC' OR
					   rm_par.cod_liqrol = 'DT' THEN
						LET rm_n36.n36_ano_proceso =
						YEAR(rm_par.n46_fecha_fin)
						LET rm_n36.n36_mes_proceso =
						MONTH(rm_par.n46_fecha_fin)
					END IF
					IF rm_par.cod_liqrol = 'VA' OR
					   rm_par.cod_liqrol = 'VP' THEN
						LET rm_n39.n39_ano_proceso =
						YEAR(rm_par.n46_fecha_fin)
						LET rm_n39.n39_mes_proceso =
						MONTH(rm_par.n46_fecha_fin)
					END IF
					IF rm_par.cod_liqrol = 'UT' THEN
						LET rm_n41.n41_ano =
						YEAR(rm_par.n46_fecha_fin)
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
	BEFORE FIELD n46_fecha_ini
		LET fec_ini = rm_par.n46_fecha_ini
	BEFORE FIELD n46_fecha_fin
		LET fec_fin = rm_par.n46_fecha_fin
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
			IF rm_par.n46_fecha_ini IS NOT NULL THEN
				IF rm_par.cod_liqrol[1] = 'M' OR
				   rm_par.cod_liqrol[1] = 'Q' OR
				   rm_par.cod_liqrol[1] = 'S' THEN
					LET rm_n32.n32_ano_proceso =
						YEAR(rm_par.n46_fecha_ini)
					LET rm_n32.n32_mes_proceso =
						MONTH(rm_par.n46_fecha_ini)
				END IF
				IF rm_par.cod_liqrol = 'DC' OR
				   rm_par.cod_liqrol = 'DT' THEN
					LET rm_n36.n36_ano_proceso =
						YEAR(rm_par.n46_fecha_fin)
					LET rm_n36.n36_mes_proceso =
						MONTH(rm_par.n46_fecha_fin)
				END IF
				IF rm_par.cod_liqrol = 'VA' OR
				   rm_par.cod_liqrol = 'VP' THEN
					LET rm_n39.n39_ano_proceso =
						YEAR(rm_par.n46_fecha_fin)
					LET rm_n39.n39_mes_proceso =
						MONTH(rm_par.n46_fecha_fin)
				END IF
				IF rm_par.cod_liqrol = 'UT' THEN
					LET rm_n41.n41_ano =
						YEAR(rm_par.n46_fecha_fin)
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
							rm_n45.n45_cod_trab)
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
	AFTER FIELD n46_fecha_ini
		IF fec_ini = rm_par.n46_fecha_ini THEN
			CONTINUE INPUT
		END IF
		IF rm_par.n46_fecha_ini IS NULL THEN
			LET rm_par.n46_fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.n46_fecha_ini
		END IF
		IF rm_par.cod_liqrol IS NOT NULL THEN
			CALL retorna_dia(rm_par.cod_liqrol, 1, 0) RETURNING dia
			LET rm_par.n46_fecha_ini =
					MDY(MONTH(rm_par.n46_fecha_ini), dia,
						YEAR(rm_par.n46_fecha_ini))
			IF rm_par.cod_liqrol[1] = 'M' OR
			   rm_par.cod_liqrol[1] = 'Q' OR
			   rm_par.cod_liqrol[1] = 'S' THEN
				LET rm_n32.n32_ano_proceso =
						YEAR(rm_par.n46_fecha_ini)
				LET rm_n32.n32_mes_proceso =
						MONTH(rm_par.n46_fecha_ini)
			END IF
			IF rm_par.cod_liqrol = 'DC' OR rm_par.cod_liqrol = 'DT'
			THEN
				LET rm_n36.n36_ano_proceso =
						YEAR(rm_par.n46_fecha_ini + 1)
				LET rm_n36.n36_mes_proceso =
						MONTH(rm_par.n46_fecha_fin)
			END IF
			IF rm_par.cod_liqrol = 'VA' OR
			   rm_par.cod_liqrol = 'VP' THEN
				LET rm_n39.n39_ano_proceso =
						YEAR(rm_par.n46_fecha_fin)
				LET rm_n39.n39_mes_proceso =
						MONTH(rm_par.n46_fecha_fin)
			END IF
			IF rm_par.cod_liqrol = 'UT' THEN
				LET rm_n41.n41_ano = YEAR(rm_par.n46_fecha_fin)
			END IF
			CALL mostrar_fechas(1, 0, 0)
		END IF
		IF rm_par.n46_fecha_ini <= rm_n32.n32_fecha_ini OR
		   rm_par.n46_fecha_ini <= rm_n36.n36_fecha_ini OR
		   rm_par.n46_fecha_ini <= rm_n39.n39_perini_real THEN
			IF rm_par.cod_liqrol[1] = 'M' OR
			   rm_par.cod_liqrol[1] = 'Q' OR
			   rm_par.cod_liqrol[1] = 'S' THEN
				IF rm_n32.n32_estado = 'A' THEN
					CONTINUE INPUT
				END IF
			END IF
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
				LET rm_par.n46_fecha_ini =
					MDY(MONTH(r_n05.n05_fec_cierre),
						dia, YEAR(r_n05.n05_fec_cierre))
				CALL retorna_fecha(rm_par.cod_liqrol,
							rm_par.n46_fecha_ini)
					RETURNING rm_par.n46_fecha_ini
			END IF
			DISPLAY BY NAME rm_par.n46_fecha_ini
			NEXT FIELD n46_fecha_ini
		END IF
	AFTER FIELD n46_fecha_fin
		LET rm_par.n46_fecha_fin = fec_fin
		DISPLAY BY NAME rm_par.n46_fecha_fin
	AFTER FIELD num_pagos
		IF rm_par.num_pagos IS NULL THEN
			LET rm_par.num_pagos = num_p
			DISPLAY BY NAME rm_par.num_pagos
		END IF
	AFTER INPUT
		IF rm_par.n46_fecha_fin < rm_par.n46_fecha_ini THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser menor que la fecha inicial.', 'exclamation')
			NEXT FIELD n46_fecha_fin
		END IF
		LET vm_num_det = rm_par.num_pagos
END INPUT
CLOSE WINDOW w_rolf214_2

END FUNCTION



FUNCTION control_resumen(flag)
DEFINE flag		SMALLINT
DEFINE lin_men		SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE val_prest, total	LIKE rolt045.n45_val_prest

LET lin_men  = 0
LET num_rows = 19
LET num_cols = 79
IF vg_gui = 0 THEN
	LET lin_men  = 1
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf214_4 AT 05, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_men, BORDER,
		  MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf214_4 FROM '../forms/rolf214_4'
ELSE
	OPEN FORM f_rolf214_4 FROM '../forms/rolf214_4c'
END IF
DISPLAY FORM f_rolf214_4
--#DISPLAY "CP"          TO tit_col1
--#DISPLAY "Proceso"     TO tit_col2
--#DISPLAY "D.Ac."       TO tit_col3
--#DISPLAY "T.D."        TO tit_col4
--#DISPLAY "Valor Div."  TO tit_col5
--#DISPLAY "Total Dist." TO tit_col6
--#DISPLAY "Saldo Dist." TO tit_col7
LET val_prest = rm_n45.n45_val_prest + rm_n45.n45_sal_prest_ant +
		rm_n45.n45_valor_int
DISPLAY rm_n45.n45_num_prest TO n58_num_prest
CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro) RETURNING r_n06.*
CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME rm_n45.n45_cod_rubro, r_n06.n06_nombre, rm_n45.n45_cod_trab,
		r_n30.n30_nombres, val_prest
IF flag = 2 THEN
	LET vm_num_dettot = 0
END IF
IF vm_num_dettot = 0 THEN
	CALL cargar_dettotpre(flag)
	IF vm_num_dettot = 0 THEN
		CALL fl_mostrar_mensaje('No existe configurado totales por proceso de NOMINA.', 'exclamation')
		LET int_flag = 1
		CLOSE WINDOW w_rolf214_4
		RETURN
	END IF
END IF
CALL obtener_total_dettot() RETURNING total
CASE flag
	WHEN 1 CALL leer_par_dist_var_procesos(val_prest)
	WHEN 2 CALL ver_par_dist_var_procesos()
END CASE
CLOSE WINDOW w_rolf214_4
RETURN

END FUNCTION



FUNCTION leer_par_dist_var_procesos(val_prest)
DEFINE val_prest, total	LIKE rolt045.n45_val_prest
DEFINE j	 	SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE val_div		LIKE rolt058.n58_num_div
DEFINE valor		LIKE rolt058.n58_valor_div

LET int_flag = 0
CALL set_count(vm_num_dettot)
INPUT ARRAY rm_dettotpre WITHOUT DEFAULTS FROM rm_dettotpre.*
	ON KEY(INTERRUPT)
       		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
        	--#CALL dialog.keysetlabel('INSERT','')
       		--#CALL dialog.keysetlabel('DELETE','')
	BEFORE ROW
		LET vm_cur_dettot = arr_curr()
		LET j = scr_line()
		DISPLAY BY NAME vm_cur_dettot, vm_num_dettot
	BEFORE INSERT
		--#CANCEL INSERT
	BEFORE DELETE
		--#CANCEL DELETE
	BEFORE FIELD n58_num_div
		LET val_div = rm_dettotpre[vm_cur_dettot].n58_num_div
	BEFORE FIELD n58_valor_div
		LET valor = rm_dettotpre[vm_cur_dettot].n58_valor_div
	AFTER FIELD n58_num_div
		IF rm_dettotpre[vm_cur_dettot].n58_num_div IS NULL THEN
			LET rm_dettotpre[vm_cur_dettot].n58_num_div = val_div
		END IF
		DISPLAY rm_dettotpre[vm_cur_dettot].n58_num_div TO
			rm_dettotpre[j].n58_num_div
		CALL calcular_valor_dist(vm_cur_dettot, j)
		CALL obtener_total_dettot() RETURNING total
	AFTER FIELD n58_valor_div
		IF rm_dettotpre[vm_cur_dettot].n58_valor_div IS NULL THEN
			LET rm_dettotpre[vm_cur_dettot].n58_valor_div = valor
		END IF
		CALL calcular_valor_dist(vm_cur_dettot, j)
		DISPLAY rm_dettotpre[vm_cur_dettot].n58_valor_div
			TO rm_dettotpre[j].n58_valor_div
		CALL fl_lee_proceso_roles(
					rm_dettotpre[vm_cur_dettot].n58_proceso)
			RETURNING r_n03.*
		IF r_n03.n03_valor > 0 THEN
			IF rm_dettotpre[vm_cur_dettot].n58_valor_div >
			   r_n03.n03_valor AND
			   rm_dettotpre[vm_cur_dettot].n58_proceso
			   <> 'DT'
			THEN
				LET mensaje = 'El valor a distribuir ',
						'para este proceso, no',
						' puede ser mayor al ',
						'valor fijo del mismo,',
						' osea ',r_n03.n03_valor
						USING "###,##&.##", '.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				NEXT FIELD n58_valor_div
			END IF
		END IF
		IF valor_tope_proc(vm_cur_dettot) THEN
			IF (rm_dettotpre[vm_cur_dettot].n58_proceso <> 'Q1') AND
			   (rm_dettotpre[vm_cur_dettot].n58_proceso <> 'Q2')
			THEN
				NEXT FIELD n58_valor_div
			END IF
		END IF
		IF rm_dettotpre[vm_cur_dettot].n58_valor_div > 0 AND
		   rm_dettotpre[vm_cur_dettot].n58_num_div = 0
		THEN
			CALL fl_mostrar_mensaje('Dígite el número de dividendos.', 'exclamation')
			NEXT FIELD n58_num_div
		END IF
		LET rm_dettotpre[vm_cur_dettot].n58_saldo_dist =
			rm_dettotpre[vm_cur_dettot].n58_valor_dist
		DISPLAY rm_dettotpre[vm_cur_dettot].n58_saldo_dist
			TO rm_dettotpre[j].n58_saldo_dist
		CALL obtener_total_dettot() RETURNING total
	AFTER INPUT 
		CALL obtener_total_dettot() RETURNING total
		IF total <> val_prest THEN
			CALL fl_mostrar_mensaje('El total a distribuir, no puede ser diferente que el valor del anticipo.', 'exclamation')
			CONTINUE INPUT
		END IF
		FOR j = 1 TO vm_num_dettot
			IF rm_dettotpre[j].n58_num_div > 0 AND
			   rm_dettotpre[j].n58_valor_dist = 0
			THEN
				LET rm_dettotpre[j].n58_num_div = 0
			END IF
		END FOR
END INPUT

END FUNCTION



FUNCTION calcular_valor_dist(i, j)
DEFINE i, j		SMALLINT

LET rm_dettotpre[i].n58_valor_dist = rm_dettotpre[i].n58_valor_div *
					rm_dettotpre[i].n58_num_div
LET rm_dettotpre[i].n58_saldo_dist = rm_dettotpre[i].n58_valor_dist
DISPLAY rm_dettotpre[i].n58_valor_dist TO rm_dettotpre[j].n58_valor_dist
DISPLAY rm_dettotpre[i].n58_saldo_dist TO rm_dettotpre[j].n58_saldo_dist

END FUNCTION



FUNCTION valor_tope_proc(i)
DEFINE i		SMALLINT
DEFINE valor		DECIMAL(14,2)
DEFINE valor_c		VARCHAR(13)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE per_ini, per_fin	DATE
DEFINE anio_i, anio_f	SMALLINT

IF rm_dettotpre[i].n58_proceso = 'Q1' OR rm_dettotpre[i].n58_proceso = 'Q2' THEN
	SELECT NVL(MAX(a.n32_tot_ing), 0) INTO valor
		FROM rolt032 a
		WHERE a.n32_compania   = vg_codcia
		  AND a.n32_cod_liqrol = rm_dettotpre[i].n58_proceso
		  AND a.n32_fecha_fin  =
			(SELECT MAX(b.n32_fecha_fin)
				FROM rolt032 b
				WHERE b.n32_compania   = a.n32_compania
				  AND b.n32_cod_liqrol = a.n32_cod_liqrol
				  AND b.n32_fecha_ini  = a.n32_fecha_ini
				  AND b.n32_fecha_fin  = a.n32_fecha_fin
			  	  AND b.n32_cod_trab   = a.n32_cod_trab)
		  AND a.n32_cod_trab   = rm_n45.n45_cod_trab
		  AND a.n32_estado    <> 'E'
	LET valor = valor * rm_dettotpre[i].n58_num_div
END IF
IF rm_dettotpre[i].n58_proceso = 'DT' THEN
	SELECT NVL(MAX(YEAR(n36_fecha_fin)), (YEAR(TODAY) - 1))
		INTO anio_i
		FROM rolt036
		WHERE n36_compania     = vg_codcia
		  AND n36_proceso      = rm_dettotpre[i].n58_proceso
		  AND n36_cod_trab     = rm_n45.n45_cod_trab
	CALL fl_lee_proceso_roles(rm_dettotpre[i].n58_proceso) RETURNING r_n03.*
	LET anio_f  = YEAR(TODAY)
	LET per_ini = MDY(r_n03.n03_mes_ini, r_n03.n03_dia_ini, anio_i)
	LET per_fin = MDY(r_n03.n03_mes_fin, r_n03.n03_dia_fin, anio_f)
	SELECT NVL(SUM(n32_tot_gan) / 12, 0) INTO valor
		FROM rolt032
		WHERE n32_compania    = vg_codcia
		  AND n32_cod_liqrol IN ('Q1', 'Q2')
		  AND n32_fecha_ini  >= per_ini
		  AND n32_fecha_fin  <= per_fin
		  AND n32_cod_trab    = rm_n45.n45_cod_trab
		  AND n32_estado     <> 'E'
	SELECT NVL(MAX(n36_valor_bruto), 0) INTO r_n03.n03_valor
		FROM rolt036
		WHERE n36_compania     = vg_codcia
		  AND n36_proceso      = rm_dettotpre[i].n58_proceso
		  AND n36_cod_trab     = rm_n45.n45_cod_trab
	IF valor < r_n03.n03_valor THEN
		LET valor = r_n03.n03_valor
	END IF
END IF
IF rm_dettotpre[i].n58_proceso = 'DC' THEN
	SELECT NVL(MAX(n36_valor_bruto), 0) INTO valor
		FROM rolt036
		WHERE n36_compania     = vg_codcia
		  AND n36_proceso      = rm_dettotpre[i].n58_proceso
		  AND n36_cod_trab     = rm_n45.n45_cod_trab
	CALL fl_lee_proceso_roles(rm_dettotpre[i].n58_proceso) RETURNING r_n03.*
	IF valor < r_n03.n03_valor THEN
		LET valor = r_n03.n03_valor
	END IF
END IF
IF rm_dettotpre[i].n58_proceso = 'VA' OR rm_dettotpre[i].n58_proceso = 'VP' THEN
	CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab)
		RETURNING r_n30.*
	LET per_ini = NULL
	SELECT MAX(n39_periodo_fin) + 1 UNITS DAY
		INTO per_ini
		FROM rolt039
		WHERE n39_compania     = vg_codcia
		  AND n39_proceso      = rm_dettotpre[i].n58_proceso
		  AND n39_cod_trab     = rm_n45.n45_cod_trab
	IF per_ini IS NULL THEN
		LET per_ini = MDY(MONTH(r_n30.n30_fecha_ing),
					DAY(r_n30.n30_fecha_ing), YEAR(TODAY))
	END IF
	LET per_fin = per_ini + 1 UNITS YEAR - 1 UNITS DAY
	CALL retorna_valor_vacacion(r_n30.n30_cod_trab, r_n30.n30_fecha_ing,
					per_ini, per_fin)
		RETURNING valor
	SELECT NVL(MAX(n39_valor_vaca + n39_valor_adic), 0)
		INTO r_n03.n03_valor
		FROM rolt039
		WHERE n39_compania     = vg_codcia
		  AND n39_proceso      = rm_dettotpre[i].n58_proceso
		  AND n39_cod_trab     = rm_n45.n45_cod_trab
	IF valor < r_n03.n03_valor THEN
		LET valor = r_n03.n03_valor
	END IF
END IF
IF rm_dettotpre[i].n58_proceso = 'UT' THEN
	SELECT NVL(MAX(n42_val_trabaj + n42_val_cargas), 0)
		INTO valor
		FROM rolt042
		WHERE n42_compania  = vg_codcia
		  AND n42_cod_trab  = rm_n45.n45_cod_trab
END IF
IF rm_dettotpre[i].n58_valor_div > valor AND valor <> 0 THEN
	LET valor_c = valor USING "--,---,--&.##"
	CALL fl_mostrar_mensaje('El empleado en este proceso tiene ' || fl_justifica_titulo('I', valor_c, 13) CLIPPED || ' a favor de él, por lo tanto el valor a distribuir debe ser menor.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION retorna_valor_vacacion(cod_trab, fec_ing, per_ini, per_fin)
DEFINE cod_trab		LIKE rolt039.n39_cod_trab
DEFINE fec_ing		LIKE rolt039.n39_fecha_ing
DEFINE per_ini		LIKE rolt039.n39_periodo_ini
DEFINE per_fin		LIKE rolt039.n39_periodo_fin
DEFINE tot_ganado	LIKE rolt039.n39_tot_ganado
DEFINE valor_vac	LIKE rolt039.n39_valor_vaca
DEFINE dias_vac		DECIMAL(4,0)
DEFINE dias_adi		DECIMAL(4,0)
DEFINE fec_tope		DATE
DEFINE anios_ant	SMALLINT
DEFINE dias_trab	SMALLINT
DEFINE factor_dia_vac	DECIMAL(20,12)
DEFINE factor_dia_adi	DECIMAL(20,12)

IF DAY(per_ini) > 1 AND DAY(per_ini) < 16 THEN
	LET per_ini = MDY(MONTH(per_ini), 01, YEAR(per_ini))
END IF
IF DAY(per_ini) > 16 THEN
	LET per_ini = MDY(MONTH(per_ini), 16, YEAR(per_ini))
END IF
LET per_fin = per_ini + rm_n90.n90_dias_anio UNITS DAY
IF NOT anio_bisiesto(YEAR(per_fin)) AND MONTH(per_fin) > 2 THEN
	LET per_fin = per_fin - 1 UNITS DAY
END IF
SELECT NVL(SUM(n32_tot_gan), 0) INTO tot_ganado
	FROM rolt032
	WHERE n32_compania     = vg_codcia
	  AND n32_cod_liqrol  IN("Q1", "Q2")
	  AND n32_fecha_ini   >= per_ini
	  AND n32_fecha_fin   <= per_fin
	  AND n32_cod_trab     = cod_trab
	  AND n32_ano_proceso >= rm_n90.n90_anio_ini_vac
	  AND n32_estado      <> 'E'
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
LET valor_vac = tot_ganado / (rm_n90.n90_dias_ano_vac / rm_n00.n00_dias_vacac)
LET dias_vac  = rm_n00.n00_dias_vacac
LET dias_adi  = 0
LET fec_tope  = fec_ing + (rm_n00.n00_ano_adi_vac - 1) UNITS YEAR - 1 UNITS DAY
IF per_fin >= fec_tope THEN
	LET anios_ant = YEAR(per_fin) - YEAR(fec_tope)
	LET dias_adi  = anios_ant * rm_n00.n00_dias_adi_va
	IF (dias_vac + dias_adi) > rm_n00.n00_max_vacac THEN
		LET dias_adi = rm_n00.n00_max_vacac - rm_n00.n00_dias_vacac
	END IF
END IF
IF per_fin > fecha_ultima_quincena() THEN
	LET factor_dia_vac = dias_vac / rm_n90.n90_dias_ano_vac		--360
	LET factor_dia_adi = dias_adi / rm_n90.n90_dias_ano_vac
	LET dias_trab      = fecha_ultima_quincena() - per_ini + 1
	LET dias_vac       = factor_dia_vac * dias_trab
	LET dias_adi       = factor_dia_adi * dias_trab
END IF
LET valor_vac = valor_vac + ((valor_vac / dias_vac) * dias_adi)
RETURN valor_vac

END FUNCTION



FUNCTION anio_bisiesto(anio)
DEFINE anio		SMALLINT
DEFINE query		VARCHAR(200)
DEFINE valor		DECIMAL(12,2)

LET query = 'SELECT MOD(', anio, ', 4) val_mod FROM dual INTO TEMP tmp_mod '
PREPARE exec_mod FROM query
EXECUTE exec_mod
SELECT * INTO valor FROM tmp_mod
DROP TABLE tmp_mod
IF valor = 0 THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION fecha_ultima_quincena()
DEFINE fecha_ult	LIKE rolt032.n32_fecha_fin

SELECT NVL(MAX(n32_fecha_fin), TODAY) INTO fecha_ult
	FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN("Q1", "Q2")
	  AND n32_estado     <> 'E'
RETURN fecha_ult

END FUNCTION



FUNCTION ver_par_dist_var_procesos()
DEFINE j		SMALLINT

CALL set_count(vm_num_dettot)
LET int_flag = 0
DISPLAY ARRAY rm_dettotpre TO rm_dettotpre.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET vm_cur_dettot = arr_curr()
		--#LET j = scr_line()
		--#DISPLAY BY NAME vm_cur_dettot, vm_num_dettot
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY

END FUNCTION



FUNCTION cargar_dettotpre(flag)
DEFINE flag		SMALLINT
DEFINE query		CHAR(2000)
DEFINE expr_tab		VARCHAR(6)
DEFINE expr_sql		VARCHAR(400)
DEFINE i		SMALLINT
DEFINE num_prest	LIKE rolt045.n45_num_prest

FOR i = 1 TO vm_max_dettot
	INITIALIZE rm_dettotpre[i].* TO NULL
END FOR
LET expr_tab = NULL
LET expr_sql = ' WHERE'
IF flag = 1 THEN
	LET expr_tab = ' OUTER'
	LET expr_sql = ' WHERE n03_estado       = "A" ',
			'   AND n03_tipo_calc   <> "P" ',
			'   AND n03_acep_descto  = "S" ',
			'   AND'
END IF
LET query = 'SELECT NVL(n58_proceso, n03_proceso), n03_nombre, ',
			'NVL(n58_div_act, 0), NVL(n58_num_div, 0), ',
			'NVL(n58_valor_div, 0), NVL(n58_valor_dist, 0), ',
			'NVL(n58_saldo_dist, 0) ',
		' FROM rolt003,', expr_tab CLIPPED, ' rolt058 ',
		expr_sql CLIPPED, ' n58_compania     = ', vg_codcia,
		'   AND n58_num_prest    = ', rm_n45.n45_num_prest,
		'   AND n58_proceso      = n03_proceso ',
		' ORDER BY 2 '
IF rm_n45.n45_num_prest IS NULL THEN
	LET num_prest = rm_n45.n45_prest_tran
	IF num_prest IS NULL THEN
		LET num_prest = 0
	END IF
	LET expr_sql = '   AND EXISTS (SELECT * FROM rolt045 ',
				' WHERE n45_compania   = n58_compania ',
				'   AND n45_num_prest <> n58_num_prest ',
				'   AND n45_cod_rubro  = ',rm_n45.n45_cod_rubro,
				'   AND n45_estado    IN ("A", "R"))), '
	LET query = 'SELECT n03_proceso, n03_nombre, 0, ',
			' NVL((SELECT n58_num_div - n58_div_act ',
				' FROM rolt058 ',
				' WHERE n58_compania     = ', vg_codcia,
				'   AND n58_num_prest    = ', num_prest,
				'   AND n58_num_div      > 0 ',
				'   AND n58_proceso      = n03_proceso ',
				expr_sql CLIPPED,
			'CASE WHEN n03_frecuencia <> "A" THEN 1 ELSE 0 END),',
			' NVL((SELECT CASE WHEN NVL((n58_num_div - ',
					'n58_div_act), 0) = 0',
					' THEN 0 ELSE n58_valor_div END ',
				' FROM rolt058 ',
				' WHERE n58_compania     = ', vg_codcia,
				'   AND n58_num_prest    = ', num_prest,
				'   AND n58_valor_div    > 0 ',
				'   AND n58_proceso      = n03_proceso ',
				expr_sql CLIPPED, ' 0.00), ',
			' NVL((SELECT (n58_num_div - n58_div_act) * ',
					'n58_valor_div ',
				' FROM rolt058 ',
				' WHERE n58_compania     = ', vg_codcia,
				'   AND n58_num_prest    = ', num_prest,
				'   AND n58_valor_dist   > 0 ',
				'   AND n58_proceso      = n03_proceso ',
				expr_sql CLIPPED, ' 0.00), ',
			' NVL((SELECT (n58_num_div - n58_div_act) * ',
					'n58_valor_div ',
				' FROM rolt058 ',
				' WHERE n58_compania     = ', vg_codcia,
				'   AND n58_num_prest    = ', num_prest,
				'   AND n58_valor_dist   > 0 ',
				'   AND n58_proceso      = n03_proceso ',
				expr_sql CLIPPED, ' 0.00) ',
			' FROM rolt003 ',
			' WHERE n03_estado       = "A" ',
			'   AND n03_tipo_calc   <> "P" ',
			'   AND n03_acep_descto  = "S" ',
			' ORDER BY 2 '
END IF
PREPARE cons_n58 FROM query
DECLARE q_n58 CURSOR FOR cons_n58
LET vm_num_dettot = 1
FOREACH q_n58 INTO rm_dettotpre[vm_num_dettot].*
	LET vm_num_dettot = vm_num_dettot + 1
	IF vm_num_dettot > vm_max_dettot THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_dettot = vm_num_dettot - 1

END FUNCTION



FUNCTION obtener_total_dettot()
DEFINE tot_val_div	DECIMAL(12,2)
DEFINE tot_val_dis	DECIMAL(12,2)
DEFINE tot_sal_dis	DECIMAL(12,2)
DEFINE val_dif		DECIMAL(12,2)
DEFINE tot_div_act	SMALLINT
DEFINE tot_num_div, i	SMALLINT

LET tot_div_act = 0
LET tot_num_div = 0
LET tot_val_div = 0
LET tot_val_dis = 0
LET tot_sal_dis = 0
FOR i = 1 TO vm_num_dettot
	LET tot_div_act = tot_div_act + rm_dettotpre[i].n58_div_act
	LET tot_num_div = tot_num_div + rm_dettotpre[i].n58_num_div
	LET tot_val_div = tot_val_div + rm_dettotpre[i].n58_valor_div
	LET tot_val_dis = tot_val_dis + rm_dettotpre[i].n58_valor_dist
	LET tot_sal_dis = tot_sal_dis + rm_dettotpre[i].n58_saldo_dist
END FOR
LET val_dif = (rm_n45.n45_val_prest + rm_n45.n45_sal_prest_ant +
		rm_n45.n45_valor_int) - tot_val_dis
DISPLAY BY NAME tot_div_act, tot_num_div, tot_val_dis, tot_sal_dis, val_dif
LET vm_num_det = tot_num_div
RETURN tot_val_dis

END FUNCTION



FUNCTION leer_detalle()
DEFINE r_det		RECORD
				n46_secuencia	LIKE rolt046.n46_secuencia,
				n46_cod_liqrol	LIKE rolt046.n46_cod_liqrol,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr,
				n46_fecha_ini	LIKE rolt046.n46_fecha_ini,
				n46_fecha_fin	LIKE rolt046.n46_fecha_fin,
				n46_valor	LIKE rolt046.n46_valor,
				n46_saldo	LIKE rolt046.n46_saldo
			END RECORD
DEFINE i, j, salir	SMALLINT
DEFINE resul, dia	SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_n03		RECORD LIKE rolt003.*

CALL calcular_interes()
WHILE TRUE
	LET salir    = 0
	LET int_flag = 0
	CALL set_count(vm_num_det)
	INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				LET salir    = 1
				EXIT INPUT
			END IF
		ON KEY(F2)
			IF INFIELD(n46_cod_liqrol) THEN
				CALL fl_ayuda_procesos_roles()
					RETURNING r_n03.n03_proceso,
						  r_n03.n03_nombre
				IF r_n03.n03_proceso IS NOT NULL THEN
					LET rm_detalle[i].n46_cod_liqrol =
							r_n03.n03_proceso
					LET rm_detalle[i].n03_nombre_abr =
							r_n03.n03_nombre_abr
					CALL cargar_datos_liq(2, i)
						RETURNING resul
					IF resul THEN
						NEXT FIELD n46_cod_liqrol
					END IF
					DISPLAY rm_detalle[i].n46_cod_liqrol TO
						rm_detalle[j].n46_cod_liqrol
					DISPLAY rm_detalle[i].n03_nombre_abr TO
						rm_detalle[j].n03_nombre_abr
					CALL mostrar_fechas(2, i, j)
				END IF
			END IF
			LET int_flag = 0
		ON KEY(F5)
       			LET i = arr_curr()
			LET vm_num_dettot = 0
			CALL parametros_generar_detalle(0)
			IF NOT int_flag THEN
				CALL generar_detalle(1, 1, vm_num_det,
						rm_detalle[1].n46_secuencia)
				EXIT INPUT
			END IF
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("DELETE","")
		BEFORE INSERT
			--#CANCEL INSERT
		BEFORE DELETE
			--#CANCEL DELETE
		BEFORE ROW
       			LET i = arr_curr()
	        	LET j = scr_line()
			CALL muestra_contadores_det(i)
			LET r_det.* = rm_detalle[i].*
		BEFORE FIELD n46_cod_liqrol
			LET r_det.n46_cod_liqrol = rm_detalle[i].n46_cod_liqrol
			LET r_det.n03_nombre_abr = rm_detalle[i].n03_nombre_abr
		BEFORE FIELD n46_fecha_ini
			LET r_det.n46_fecha_ini = rm_detalle[i].n46_fecha_ini
		BEFORE FIELD n46_fecha_fin
			LET r_det.n46_fecha_fin = rm_detalle[i].n46_fecha_fin
		BEFORE FIELD n46_valor
			LET r_det.n46_valor = rm_detalle[i].n46_valor
		{--
		AFTER DELETE
			CALL generar_detalle(2, i, vm_num_det,
						rm_detalle[i].n46_secuencia - 1)
			INITIALIZE rm_detalle[vm_num_det].* TO NULL
			IF vm_num_det <= fgl_scr_size('rm_detalle') THEN
				CLEAR rm_detalle[vm_num_det].*
			END IF
			LET vm_num_det = vm_num_det - 1
			CALL mostrar_total()
			EXIT INPUT
		--}
		AFTER FIELD n46_cod_liqrol
			IF rm_detalle[i].n46_cod_liqrol IS NOT NULL THEN
   				CALL fl_lee_proceso_roles(rm_detalle[i].n46_cod_liqrol)
					RETURNING r_n03.*
				IF r_n03.n03_proceso IS NULL THEN
					CALL fl_mostrar_mensaje('No existe el código de liquidación en la Compañía.','exclamation')
					NEXT FIELD n46_cod_liqrol
				END IF
				LET rm_detalle[i].n03_nombre_abr =
							r_n03.n03_nombre_abr
				DISPLAY rm_detalle[i].n03_nombre_abr TO
					rm_detalle[j].n03_nombre_abr
				CALL cargar_datos_liq(2, i) RETURNING resul
				IF resul THEN
					NEXT FIELD n46_cod_liqrol
				END IF
				CALL mostrar_fechas(2, i, j)
				IF r_n03.n03_acep_descto = 'N' THEN
					CALL fl_mostrar_mensaje('Este código de proceso no esta permitido que acepte descuentos.', 'exclamation')
					NEXT FIELD n46_cod_liqrol
				END IF
				IF r_n03.n03_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD n46_cod_liqrol
				END IF
				IF FIELD_TOUCHED(rm_detalle[i].n46_cod_liqrol)
				THEN
					CALL generar_detalle(2, i, vm_num_det,
						rm_detalle[i].n46_secuencia)
				END IF
			ELSE
				LET rm_detalle[i].n46_cod_liqrol =
							r_det.n46_cod_liqrol
				LET rm_detalle[i].n03_nombre_abr =
							r_det.n03_nombre_abr
				DISPLAY rm_detalle[i].n46_cod_liqrol TO
					rm_detalle[j].n46_cod_liqrol
				DISPLAY rm_detalle[i].n03_nombre_abr TO
					rm_detalle[j].n03_nombre_abr
			END IF
		AFTER FIELD n46_fecha_ini
			IF r_det.n46_fecha_ini = rm_detalle[i].n46_fecha_ini
			THEN
				CONTINUE INPUT
			END IF
			IF rm_detalle[i].n46_fecha_ini IS NULL THEN
				LET rm_detalle[i].n46_fecha_ini =
							r_det.n46_fecha_ini
				DISPLAY rm_detalle[i].n46_fecha_ini TO
					rm_detalle[j].n46_fecha_ini
			END IF
			IF rm_detalle[i].n46_cod_liqrol IS NOT NULL THEN
				CALL retorna_dia(rm_detalle[i].n46_cod_liqrol,
						2, i)
					RETURNING dia
				LET rm_detalle[i].n46_fecha_ini =
					MDY(MONTH(rm_detalle[i].n46_fecha_ini),
					 dia, YEAR(rm_detalle[i].n46_fecha_ini))
				CALL mostrar_fechas(2, i, j)
				CALL generar_detalle(2, i, vm_num_det,
						rm_detalle[i].n46_secuencia)
			END IF
		AFTER FIELD n46_fecha_fin
			LET rm_detalle[i].n46_fecha_fin = r_det.n46_fecha_fin
			DISPLAY rm_detalle[i].n46_fecha_fin TO
				rm_detalle[j].n46_fecha_fin
		AFTER FIELD n46_valor
			IF rm_detalle[i].n46_valor IS NULL THEN
				LET rm_detalle[i].n46_valor = r_det.n46_valor
				DISPLAY rm_detalle[i].n46_valor TO
					rm_detalle[j].n46_valor
			END IF
			LET rm_detalle[i].n46_saldo = rm_detalle[i].n46_valor
			DISPLAY rm_detalle[i].n46_saldo TO
				rm_detalle[j].n46_saldo
			CALL mostrar_total()
		AFTER INPUT
			CALL calcular_interes()
			CALL mostrar_total()
			CALL validar_detalle() RETURNING resul
			IF resul THEN
				NEXT FIELD n46_cod_liqrol
			END IF
			IF total_valor <> (rm_n45.n45_val_prest +
					rm_n45.n45_valor_int +
					rm_n45.n45_sal_prest_ant -
					rm_n45.n45_descontado)
			THEN
				CALL fl_mostrar_mensaje('El valor total de los dividendos es mayor que el valor del anticipo menos el descontado.', 'exclamation')
				NEXT FIELD n46_valor
			END IF
			LET salir = 1
	END INPUT
	IF salir THEN
		CALL muestra_contadores_det(0)
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION modificar_dividendos_con_saldo()
DEFINE r_det		RECORD
				n46_secuencia	LIKE rolt046.n46_secuencia,
				n46_cod_liqrol	LIKE rolt046.n46_cod_liqrol,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr,
				n46_fecha_ini	LIKE rolt046.n46_fecha_ini,
				n46_fecha_fin	LIKE rolt046.n46_fecha_fin,
				n46_valor	LIKE rolt046.n46_valor,
				n46_saldo	LIKE rolt046.n46_saldo
			END RECORD
DEFINE i, j		SMALLINT
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

CALL calcular_interes()
CALL cargar_detalle()
CALL mostrar_total()
CALL set_count(vm_num_det)
LET int_flag = 0
INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("INSERT","")
		--#CALL dialog.keysetlabel("DELETE","")
	BEFORE INSERT
		--#CANCEL INSERT
	BEFORE DELETE
		--#CANCEL DELETE
	BEFORE ROW
       		LET i = arr_curr()
        	LET j = scr_line()
		CALL muestra_contadores_det(i)
		LET r_det.* = rm_detalle[i].*
	BEFORE FIELD n46_cod_liqrol
		LET r_det.n46_cod_liqrol = rm_detalle[i].n46_cod_liqrol
		LET r_det.n03_nombre_abr = rm_detalle[i].n03_nombre_abr
	BEFORE FIELD n46_fecha_ini
		LET r_det.n46_fecha_ini = rm_detalle[i].n46_fecha_ini
	BEFORE FIELD n46_fecha_fin
		LET r_det.n46_fecha_fin = rm_detalle[i].n46_fecha_fin
	BEFORE FIELD n46_valor
		LET r_det.n46_valor = rm_detalle[i].n46_valor
	{--
	AFTER DELETE
		CALL generar_detalle(2, i, vm_num_det,
					rm_detalle[i].n46_secuencia - 1)
		INITIALIZE rm_detalle[vm_num_det].* TO NULL
		IF vm_num_det <= fgl_scr_size('rm_detalle') THEN
			CLEAR rm_detalle[vm_num_det].*
		END IF
		LET vm_num_det = vm_num_det - 1
		CALL mostrar_total()
		EXIT INPUT
	--}
	AFTER FIELD n46_cod_liqrol
		LET rm_detalle[i].n46_cod_liqrol = r_det.n46_cod_liqrol
		LET rm_detalle[i].n03_nombre_abr = r_det.n03_nombre_abr
		DISPLAY rm_detalle[i].n46_cod_liqrol TO
			rm_detalle[j].n46_cod_liqrol
		DISPLAY rm_detalle[i].n03_nombre_abr TO
			rm_detalle[j].n03_nombre_abr
	AFTER FIELD n46_fecha_ini
		LET rm_detalle[i].n46_fecha_ini = r_det.n46_fecha_ini
		DISPLAY rm_detalle[i].n46_fecha_ini TO
			rm_detalle[j].n46_fecha_ini
	AFTER FIELD n46_fecha_fin
		LET rm_detalle[i].n46_fecha_fin = r_det.n46_fecha_fin
		DISPLAY rm_detalle[i].n46_fecha_fin TO
			rm_detalle[j].n46_fecha_fin
	AFTER FIELD n46_valor
		IF rm_detalle[i].n46_valor IS NULL THEN
			LET rm_detalle[i].n46_valor = r_det.n46_valor
			DISPLAY rm_detalle[i].n46_valor TO
				rm_detalle[j].n46_valor
		END IF
		LET rm_detalle[i].n46_saldo = rm_detalle[i].n46_valor
		DISPLAY rm_detalle[i].n46_saldo TO
			rm_detalle[j].n46_saldo
		CALL mostrar_total()
	AFTER INPUT
		CALL mostrar_total()
		IF total_saldo <> (rm_n45.n45_val_prest +
				rm_n45.n45_valor_int +
				rm_n45.n45_sal_prest_ant -
				rm_n45.n45_descontado)
		THEN
			CALL fl_mostrar_mensaje('El saldo total de los dividendos es diferente que el valor actual del anticipo.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT
CALL muestra_contadores_det(0)
RETURN int_flag

END FUNCTION



FUNCTION validar_detalle()
DEFINE i, j, resul	SMALLINT
DEFINE mensaje		VARCHAR(100)

LET resul = 0
FOR i = 1 TO vm_num_det - 1
	FOR j = i + 1 TO vm_num_det
		IF (rm_detalle[i].n46_cod_liqrol <> 'UT') AND
		   (rm_detalle[i].n46_cod_liqrol =
		    rm_detalle[j].n46_cod_liqrol) AND
		   (rm_detalle[i].n46_fecha_ini >=
		    rm_detalle[j].n46_fecha_ini)
		THEN
			LET mensaje = 'La fecha inicial del dividendo No. ',
					i USING "<&&", ' es incorrecta. ',
					'Modifique el código del proceso.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			LET resul = 1
			EXIT FOR
		END IF
		IF (rm_detalle[i].n46_cod_liqrol <> 'UT') AND
		   (rm_detalle[i].n46_cod_liqrol =
		    rm_detalle[j].n46_cod_liqrol) AND
		   (rm_detalle[i].n46_fecha_fin >=
		    rm_detalle[j].n46_fecha_fin)
		THEN
			LET mensaje = 'La fecha final del dividendo No. ',
					i USING "<&&", ' es incorrecta. ',
					'Modifique el código del proceso.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			LET resul = 1
			EXIT FOR
		END IF
	END FOR
	IF resul THEN
		EXIT FOR
	END IF
END FOR
RETURN resul

END FUNCTION



FUNCTION datos_defaults_cab()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE resul	 	SMALLINT

INITIALIZE r_n06.* TO NULL
LET rm_n45.n45_compania      = vg_codcia
IF vg_codloc <> 3 THEN
	DECLARE q_rubant CURSOR FOR
		SELECT * FROM rolt006
			WHERE n06_flag_ident = vm_proceso
			ORDER BY n06_cod_rubro ASC
	OPEN q_rubant
	FETCH q_rubant INTO r_n06.*
	CLOSE q_rubant
	FREE q_rubant
	IF r_n06.n06_cod_rubro IS NULL THEN
		CALL fl_mostrar_mensaje('No existe configurado el rubro para el proceso ANTICIPOS en la tabla rolt006.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_n45.n45_cod_rubro     = r_n06.n06_cod_rubro
END IF
LET rm_n45.n45_estado        = 'A'
LET rm_n45.n45_fecha         = CURRENT
LET rm_n45.n45_val_prest     = 0
LET rm_n45.n45_valor_int     = 0
LET rm_n45.n45_sal_prest_ant = 0
LET rm_n45.n45_descontado    = 0
LET rm_n45.n45_mes_gracia    = rm_n90.n90_mes_gra_ant
LET rm_n45.n45_porc_int      = rm_n90.n90_porc_int_ant
LET rm_n45.n45_moneda        = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_n45.n45_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada una moneda base en el sistema.', 'stop')
	EXIT PROGRAM
END IF
CALL retorna_paridad() RETURNING rm_n45.n45_paridad, resul
LET rm_n45.n45_tipo_pago     = 'C'
LET rm_n45.n45_usuario       = vg_usuario
LET rm_n45.n45_fecing        = CURRENT
LET rm_par.num_pagos         = 1
DISPLAY BY NAME rm_n45.n45_cod_rubro, r_n06.n06_nombre, rm_n45.n45_fecha,
		rm_n45.n45_val_prest, rm_n45.n45_sal_prest_ant,
		rm_n45.n45_descontado, rm_n45.n45_moneda, r_g13.g13_nombre,
		rm_n45.n45_paridad, rm_n45.n45_usuario, rm_n45.n45_prest_tran,
		rm_n45.n45_mes_gracia, rm_n45.n45_porc_int, rm_n45.n45_valor_int
CALL muestra_estado()
CALL limpiar_detalle()
LET vm_num_dettot  = 0
LET vm_num_det     = 0
LET vm_aux_con_red = NULL
CALL calcular_interes()

END FUNCTION



FUNCTION cargar_datos_liq(flag, i)
DEFINE flag, i, resul	SMALLINT
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE cod_liqrol	LIKE rolt003.n03_proceso
DEFINE mes		SMALLINT

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
        CALL fl_mostrar_mensaje('Compañía no esta activa.', 'stop')
	EXIT PROGRAM
END IF
CASE flag
	WHEN 1
		LET cod_liqrol = rm_par.cod_liqrol
	WHEN 2
		LET cod_liqrol = rm_detalle[i].n46_cod_liqrol
END CASE
INITIALIZE rm_n32.*, rm_n36.*, rm_n39.*, rm_n41.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania   =  vg_codcia  
		  AND n32_cod_liqrol =  cod_liqrol
		  AND n32_cod_trab   =  rm_n45.n45_cod_trab
		  AND n32_estado     <> 'E'
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
		  AND n36_cod_trab = rm_n45.n45_cod_trab
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
DECLARE q_vacaciones CURSOR FOR
	SELECT * FROM rolt039
		WHERE n39_compania = vg_codcia  
		  AND n39_proceso  = cod_liqrol
		  AND n39_cod_trab = rm_n45.n45_cod_trab
		  AND n39_estado   = 'A'
		ORDER BY n39_perfin_real DESC
OPEN q_vacaciones
FETCH q_vacaciones INTO rm_n39.*
IF rm_n39.n39_compania IS NOT NULL THEN
	CLOSE q_vacaciones
	FREE q_vacaciones
	CALL retorna_ano_mes(rm_n39.n39_ano_proceso, rm_n39.n39_mes_proceso)
		RETURNING rm_n39.n39_ano_proceso, rm_n39.n39_mes_proceso
	RETURN 0
END IF
CLOSE q_vacaciones
FREE q_vacaciones
DECLARE q_utilidades CURSOR FOR
	SELECT rolt041.*
		FROM rolt042, rolt041
		WHERE n42_compania = vg_codcia  
		  AND n42_cod_trab = rm_n45.n45_cod_trab
		  AND n41_compania = n42_compania
		  AND n41_ano      = n42_ano
		  AND n41_estado   = 'A'
		ORDER BY n41_ano DESC
OPEN q_utilidades
FETCH q_utilidades INTO rm_n41.*
IF rm_n41.n41_compania IS NOT NULL THEN
	CLOSE q_utilidades
	FREE q_utilidades
	CALL retorna_ano_mes(cod_liqrol, 11) RETURNING rm_n41.n41_ano, mes
	RETURN 0
END IF
CLOSE q_utilidades
FREE q_utilidades
CALL retorna_n05(cod_liqrol) RETURNING r_n05.*, resul
IF resul THEN
	RETURN 1
END IF
IF cod_liqrol[1] = 'M' OR cod_liqrol[1] = 'Q' OR cod_liqrol[1] = 'S' THEN
	LET rm_n32.n32_ano_proceso = r_n01.n01_ano_proceso
	LET rm_n32.n32_mes_proceso = r_n01.n01_mes_proceso
	LET rm_n32.n32_fecha_fin   = r_n05.n05_fec_cierre
END IF
IF cod_liqrol = 'DC' OR cod_liqrol = 'DT' THEN
	LET rm_n36.n36_ano_proceso = r_n01.n01_ano_proceso
	LET rm_n36.n36_mes_proceso = r_n01.n01_mes_proceso
	LET rm_n36.n36_fecha_fin   = r_n05.n05_fec_cierre
END IF
IF cod_liqrol = 'VA' OR cod_liqrol = 'VP' THEN
	LET rm_n39.n39_ano_proceso = YEAR(TODAY)
	LET rm_n39.n39_mes_proceso = MONTH(TODAY)
	LET rm_n39.n39_perfin_real = TODAY
END IF
IF cod_liqrol = 'UT' THEN
	LET rm_n41.n41_ano = YEAR(TODAY)
END IF
RETURN 0

END FUNCTION



FUNCTION retorna_n05(cod_liq)
DEFINE cod_liq		LIKE rolt003.n03_proceso
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE mensaje		VARCHAR(100)

INITIALIZE r_n05.* TO NULL
IF cod_liq = 'VA' OR cod_liq = 'VP' THEN
	RETURN r_n05.*, 0
END IF
SELECT * INTO r_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = cod_liq
	  AND n05_activo   = 'N'
	ORDER BY n05_fec_cierre DESC
IF r_n05.n05_compania IS NULL THEN
	CALL fl_lee_proceso_roles(cod_liq) RETURNING r_n03.*
        LET mensaje = 'El proceso ', r_n03.n03_proceso, ' ',
			r_n03.n03_nombre CLIPPED, ' no esta cerrado, y no se ',
			'le puede conceder anticipos.'
        CALL fl_mostrar_mensaje(mensaje, 'stop')
	RETURN r_n05.*, 1
END IF
RETURN r_n05.*, 0

END FUNCTION



FUNCTION generar_detalle(flag, l, max_det, ini)
DEFINE flag, l, max_det	SMALLINT
DEFINE ini		LIKE rolt046.n46_secuencia
DEFINE r_reg		RECORD
				n46_secuencia	LIKE rolt046.n46_secuencia,
				n46_cod_liqrol	LIKE rolt046.n46_cod_liqrol,
				n03_nombre_abr	LIKE rolt003.n03_nombre_abr,
				n46_fecha_ini	LIKE rolt046.n46_fecha_ini,
				n46_fecha_fin	LIKE rolt046.n46_fecha_fin,
				n46_valor	LIKE rolt046.n46_valor,
				n46_saldo	LIKE rolt046.n46_saldo
			END RECORD
DEFINE i		SMALLINT

IF vm_num_dettot = 0 THEN
	CALL generar_detalle_uno(flag, l, max_det, ini, 0)
	RETURN
END IF
SELECT n46_secuencia sec, n46_cod_liqrol lq, n03_nombre_abr nom_abr,
	n46_fecha_ini fec_ini, n46_fecha_fin fec_fin, n46_valor val_det,
	n46_saldo sal_det
	FROM rolt046, rolt003
	WHERE n46_compania = 999
	  AND n03_proceso  = n46_cod_liqrol
	INTO TEMP tmp_det
LET l = 1
FOR i = 1 TO vm_num_dettot
	IF i = 1 THEN
		LET max_det = rm_dettotpre[i].n58_num_div
	ELSE
		LET max_det = max_det + rm_dettotpre[i].n58_num_div
	END IF
	CALL generar_detalle_uno(3, l, max_det, l, i)
	LET l = l + rm_dettotpre[i].n58_num_div
END FOR
DECLARE q_det CURSOR FOR SELECT * FROM tmp_det ORDER BY fec_fin ASC, lq DESC
LET vm_num_det = 1
FOREACH q_det INTO r_reg.*
	LET rm_detalle[vm_num_det].n46_secuencia  = vm_num_det
	LET rm_detalle[vm_num_det].n46_cod_liqrol = r_reg.n46_cod_liqrol
	LET rm_detalle[vm_num_det].n03_nombre_abr = r_reg.n03_nombre_abr
	LET rm_detalle[vm_num_det].n46_fecha_ini  = r_reg.n46_fecha_ini
	LET rm_detalle[vm_num_det].n46_fecha_fin  = r_reg.n46_fecha_fin
	LET rm_detalle[vm_num_det].n46_valor      = r_reg.n46_valor
	LET rm_detalle[vm_num_det].n46_saldo      = r_reg.n46_saldo
	LET vm_num_det = vm_num_det + 1
END FOREACH
LET vm_num_det = vm_num_det - 1
CALL calcular_interes()
CALL mostrar_detalle(ini)
DROP TABLE tmp_det

END FUNCTION



FUNCTION generar_detalle_uno(flag, l, max_det, ini, posi)
DEFINE flag, l, max_det	SMALLINT
DEFINE ini		LIKE rolt046.n46_secuencia
DEFINE posi		SMALLINT
DEFINE divi, num_div	LIKE rolt046.n46_secuencia
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE valor		LIKE rolt045.n45_val_prest
DEFINE cod_liqrol	LIKE rolt003.n03_proceso
DEFINE fecha_ini	LIKE rolt046.n46_fecha_ini
DEFINE fecha_fin	LIKE rolt046.n46_fecha_fin
DEFINE val_prest	LIKE rolt045.n45_val_prest
DEFINE val_aux		LIKE rolt045.n45_val_prest
DEFINE tot_prestamo	LIKE rolt045.n45_val_prest
DEFINE anio, mes, dia	SMALLINT
DEFINE restar, i, j	SMALLINT
DEFINE retorna_mes	SMALLINT
DEFINE encont		SMALLINT

LET val_prest = rm_n45.n45_val_prest + rm_n45.n45_sal_prest_ant
		+ rm_n45.n45_valor_int - rm_n45.n45_descontado
LET val_aux   = rm_n45.n45_val_prest
IF rm_n45.n45_val_prest = 0 OR rm_n45.n45_sal_prest_ant > 0 THEN
	LET val_aux = val_prest
END IF
LET num_div   = rm_par.num_pagos
CASE flag
	WHEN 1
		LET cod_liqrol = rm_par.cod_liqrol
		LET fecha_ini  = rm_par.n46_fecha_ini
		LET fecha_fin  = rm_par.n46_fecha_fin
	WHEN 2
		LET cod_liqrol = rm_detalle[l].n46_cod_liqrol
		LET fecha_ini  = rm_detalle[l].n46_fecha_ini
		LET fecha_fin  = rm_detalle[l].n46_fecha_fin
	WHEN 3
		LET cod_liqrol = rm_dettotpre[posi].n58_proceso
		IF cod_liqrol[1] = 'M' OR cod_liqrol[1] = 'Q' OR
		   cod_liqrol[1] = 'S' THEN
			SELECT YEAR(MAX(a.n32_fecha_fin)),
				MONTH(MAX(a.n32_fecha_fin)),
				DAY(MAX(a.n32_fecha_fin))
				INTO anio, mes, dia
				FROM rolt032 a
				WHERE a.n32_compania   = vg_codcia
				  AND a.n32_fecha_fin <=
					(SELECT MAX(b.n32_fecha_fin)
					FROM rolt032 b
					WHERE b.n32_compania   = a.n32_compania
					  AND b.n32_cod_liqrol =a.n32_cod_liqrol
					  AND b.n32_fecha_ini  = a.n32_fecha_ini
					  AND b.n32_fecha_fin  = a.n32_fecha_fin
				  	  AND b.n32_cod_trab   = a.n32_cod_trab)
				  AND a.n32_cod_trab   = rm_n45.n45_cod_trab
				  AND a.n32_estado    <> 'E'
			LET retorna_mes = 1
			IF cod_liqrol = 'Q2' THEN
				IF dia = 15 THEN
					LET mes = mes - 1
					IF mes = 0 THEN
						LET mes  = 1
						LET anio = anio - 1
						IF anio < YEAR(TODAY) THEN
							LET anio = YEAR(TODAY)
							LET retorna_mes = 0
						END IF
					END IF
				END IF
			END IF
			IF retorna_mes THEN
				CALL retorna_ano_mes(anio, mes)
					RETURNING anio, mes
			END IF
			CALL retorna_ano_mes_gracia(anio, mes)
				RETURNING anio, mes
		END IF
		IF cod_liqrol = 'DT' OR cod_liqrol = 'DC' OR
		   cod_liqrol = 'VA' OR cod_liqrol = 'UT' OR cod_liqrol = 'VP'
		THEN
			LET anio = YEAR(TODAY)
			LET mes  = MONTH(TODAY)
			IF cod_liqrol = 'UT' THEN
				IF mes <= 4 THEN
					LET restar = 1
					IF mes = 4 AND DAY(TODAY) > 15 THEN
						LET restar = 0
					END IF
					IF restar THEN
						LET anio = anio - 1
					END IF
				END IF
			END IF
		END IF
		IF cod_liqrol = 'VP' THEN
			LET encont = 0
			FOR j = 1 TO vm_num_dettot
				IF rm_dettotpre[j].n58_proceso = 'VA' AND
				   rm_dettotpre[j].n58_num_div > 0
				THEN
					LET encont = 1
					EXIT FOR
				END IF
			END FOR
			IF encont THEN
				FOR j = max_det TO 1 STEP -1
					IF rm_detalle[j].n46_cod_liqrol = 'VA'
					THEN
						LET anio =
					YEAR(rm_detalle[j].n46_fecha_fin) + 1
						EXIT FOR
					END IF
				END FOR
			END IF
		END IF
		CALL retorna_fecha_proc(cod_liqrol, anio, mes)
			RETURNING fecha_ini, fecha_fin
		CALL retorna_fecha_proc_anual_gracia(fecha_ini, fecha_fin)
			RETURNING fecha_ini, fecha_fin
		LET val_prest  = rm_dettotpre[posi].n58_valor_dist
		LET num_div    = rm_dettotpre[posi].n58_num_div
END CASE
CALL fl_lee_proceso_roles(cod_liqrol) RETURNING r_n03.*
LET divi         = ini
LET tot_prestamo = 0
IF flag <> 3 THEN
	FOR i = 1 TO (l - 1)
		LET tot_prestamo = tot_prestamo + rm_detalle[i].n46_valor
	END FOR
END IF
FOR i = l TO max_det
	LET rm_detalle[i].n46_secuencia  = divi
	LET rm_detalle[i].n46_cod_liqrol = r_n03.n03_proceso
	LET rm_detalle[i].n03_nombre_abr = r_n03.n03_nombre_abr
	LET rm_detalle[i].n46_fecha_ini  = fecha_ini
	LET rm_detalle[i].n46_fecha_fin  = fecha_fin
	IF flag = 1 OR flag = 3 THEN
		LET rm_detalle[i].n46_valor = val_prest / num_div
		LET tot_prestamo = tot_prestamo + rm_detalle[i].n46_valor
		IF i = max_det AND flag = 1 THEN
			LET rm_detalle[i].n46_valor = 
				rm_detalle[i].n46_valor +
				(val_aux - tot_prestamo)
			LET tot_prestamo = tot_prestamo + 
				(val_aux - tot_prestamo)
		END IF
		IF i = max_det AND flag = 3 THEN
			LET rm_detalle[i].n46_valor = 
						rm_detalle[i].n46_valor +
						(val_prest - tot_prestamo)
			LET tot_prestamo = tot_prestamo +
						(val_prest - tot_prestamo)
		END IF
		LET rm_detalle[i].n46_saldo = rm_detalle[i].n46_valor
	END IF
	CALL retorna_fecha(cod_liqrol, fecha_ini) RETURNING fecha_ini
	CALL retorna_fecha(cod_liqrol, fecha_fin) RETURNING fecha_fin
	IF flag = 3 THEN
		INSERT INTO tmp_det VALUES (rm_detalle[i].*)
	END IF
	LET divi = divi + 1
END FOR
IF flag = 1 OR flag = 3 THEN
	LET valor = rm_detalle[1].n46_valor * num_div
	IF valor < val_prest AND flag = 1 THEN
		IF tot_prestamo <> rm_n45.n45_val_prest THEN
			LET rm_detalle[max_det].n46_valor =
					rm_detalle[max_det].n46_valor +
					(val_aux - valor)
		END IF
		LET rm_detalle[max_det].n46_saldo =rm_detalle[max_det].n46_valor
	END IF
	IF valor < val_prest AND flag = 3 THEN
		IF tot_prestamo <> val_prest THEN
			LET rm_detalle[max_det].n46_valor =
					rm_detalle[max_det].n46_valor +
					(val_prest - valor)
		END IF
		LET rm_detalle[max_det].n46_saldo =rm_detalle[max_det].n46_valor
		UPDATE tmp_det
			SET val_det = rm_detalle[max_det].n46_valor,
			    sal_det = rm_detalle[max_det].n46_saldo
			WHERE sec = rm_detalle[max_det].n46_secuencia
			  AND lq  = rm_detalle[max_det].n46_cod_liqrol
	END IF
END IF
IF flag <> 3 THEN
	CALL mostrar_detalle(ini)
END IF

END FUNCTION



FUNCTION retorna_paridad()
DEFINE r_g14		RECORD LIKE gent014.*

IF rm_n45.n45_moneda = rg_gen.g00_moneda_base THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(rm_n45.n45_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('La paridad para esta moneda no existe.','exclamation')
		RETURN r_g14.g14_tasa, 1
	END IF
END IF
RETURN r_g14.g14_tasa, 0

END FUNCTION



FUNCTION calcular_interes()
DEFINE valor_prest	LIKE rolt045.n45_val_prest
DEFINE valor_int	LIKE rolt045.n45_valor_int
DEFINE i, num_dias	INTEGER
DEFINE factor		DECIMAL(9,16)

--LET rm_n45.n45_valor_int = (rm_n45.n45_val_prest * rm_n45.n45_porc_int) / 100
IF rm_n45.n45_porc_int = 0 AND rm_n45.n45_valor_int = 0 THEN
	RETURN
END IF
IF vm_num_det = 0 OR rm_n45.n45_descontado <> 0 THEN
	RETURN
END IF
IF rm_n45.n45_valor_int > 0 THEN
	RETURN
END IF
LET rm_n45.n45_valor_int = 0
LET valor_prest          = rm_n45.n45_val_prest
FOR i = 1 TO vm_num_det
	IF i > 1 THEN
		LET valor_prest = valor_prest - rm_detalle[i].n46_valor
		LET num_dias    = rm_detalle[i].n46_fecha_fin -
					rm_detalle[i - 1].n46_fecha_fin
	ELSE
		LET num_dias = rm_detalle[i].n46_fecha_fin - TODAY
	END IF
	IF valor_prest <= 0 THEN
		CONTINUE FOR
	END IF
	IF num_dias < 1 THEN
		LET num_dias = 1
	END IF
	LET factor = num_dias
	IF rm_detalle[i].n46_cod_liqrol[1, 1] <> 'Q' THEN
		LET factor = 12 / num_dias
	END IF
	LET valor_int               = valor_prest * rm_n45.n45_porc_int *
					factor / (rm_n90.n90_dias_ano_ant * 100)
	LET rm_detalle[i].n46_valor = rm_detalle[i].n46_valor + valor_int
	LET rm_detalle[i].n46_saldo = rm_detalle[i].n46_saldo + valor_int
	LET rm_n45.n45_valor_int    = rm_n45.n45_valor_int    + valor_int
END FOR
DISPLAY BY NAME rm_n45.n45_valor_int
CALL mostrar_total()

END FUNCTION



FUNCTION muestra_estado()
DEFINE estado		LIKE rolt045.n45_estado

LET estado = rm_n45.n45_estado
DISPLAY BY NAME rm_n45.n45_estado
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
	OTHERWISE
		CLEAR n45_estado, tit_estado
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
DECLARE q_cons1 CURSOR FOR SELECT * FROM rolt045 WHERE ROWID = num_registro
OPEN q_cons1
FETCH q_cons1 INTO rm_n45.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME	rm_n45.n45_num_prest, rm_n45.n45_cod_rubro, rm_n45.n45_cod_trab,
		rm_n45.n45_moneda, rm_n45.n45_val_prest, rm_n45.n45_paridad,
		rm_n45.n45_sal_prest_ant, rm_n45.n45_descontado,
		rm_n45.n45_referencia, rm_n45.n45_fecha, rm_n45.n45_fec_elimi,
		rm_n45.n45_usuario, rm_n45.n45_prest_tran,rm_n45.n45_mes_gracia,
		rm_n45.n45_porc_int, rm_n45.n45_valor_int
CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro) RETURNING r_n06.*
DISPLAY BY NAME r_n06.n06_nombre
CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME r_n30.n30_nombres
CALL fl_lee_moneda(rm_n45.n45_moneda) RETURNING r_g13.*
DISPLAY BY NAME r_g13.g13_nombre
LET valor_deuda = rm_n45.n45_val_prest + rm_n45.n45_sal_prest_ant
			+ rm_n45.n45_valor_int - rm_n45.n45_descontado
DISPLAY BY NAME valor_deuda
CALL muestra_estado()
CALL cargar_detalle()
CALL calcular_interes()
CALL mostrar_detalle(1)
LET rm_par.cod_liqrol    = rm_detalle[1].n46_cod_liqrol
LET rm_par.n46_fecha_ini = rm_detalle[1].n46_fecha_ini
LET rm_par.n46_fecha_fin = rm_detalle[1].n46_fecha_fin
LET rm_par.num_pagos     = vm_num_det
CLOSE q_cons1
FREE q_cons1

END FUNCTION



FUNCTION cargar_detalle()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n46		RECORD LIKE rolt046.*

DECLARE q_n46 CURSOR FOR
	SELECT * FROM rolt046
		WHERE n46_compania  = rm_n45.n45_compania
		  AND n46_num_prest = rm_n45.n45_num_prest
		ORDER BY n46_secuencia
LET vm_num_det = 1
FOREACH q_n46 INTO r_n46.*
	IF vm_flag_mant = 'M' THEN
		IF r_n46.n46_saldo >= 0 AND r_n46.n46_saldo < r_n46.n46_valor
		THEN
			CONTINUE FOREACH
		END IF
	END IF
	CALL fl_lee_proceso_roles(r_n46.n46_cod_liqrol) RETURNING r_n03.*
	LET rm_detalle[vm_num_det].n46_secuencia  = r_n46.n46_secuencia
	LET rm_detalle[vm_num_det].n46_cod_liqrol = r_n46.n46_cod_liqrol
	LET rm_detalle[vm_num_det].n03_nombre_abr = r_n03.n03_nombre_abr
	LET rm_detalle[vm_num_det].n46_fecha_ini  = r_n46.n46_fecha_ini
	LET rm_detalle[vm_num_det].n46_fecha_fin  = r_n46.n46_fecha_fin
	LET rm_detalle[vm_num_det].n46_valor      = r_n46.n46_valor
	LET rm_detalle[vm_num_det].n46_saldo      = r_n46.n46_saldo
	LET vm_num_det                            = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION grabar_detalle()
DEFINE r_n46		RECORD LIKE rolt046.*
DEFINE i		SMALLINT

DELETE FROM rolt058
	WHERE n58_compania  = rm_n45.n45_compania
	  AND n58_num_prest = rm_n45.n45_num_prest
DELETE FROM rolt046
	WHERE n46_compania  = rm_n45.n45_compania
	  AND n46_num_prest = rm_n45.n45_num_prest
	  AND n46_saldo     = n46_valor
FOR i = 1 TO vm_num_det
	LET r_n46.n46_compania   = rm_n45.n45_compania
	LET r_n46.n46_num_prest  = rm_n45.n45_num_prest
	LET r_n46.n46_secuencia  = rm_detalle[i].n46_secuencia
	LET r_n46.n46_cod_liqrol = rm_detalle[i].n46_cod_liqrol
	LET r_n46.n46_fecha_ini  = rm_detalle[i].n46_fecha_ini
	LET r_n46.n46_fecha_fin  = rm_detalle[i].n46_fecha_fin
	LET r_n46.n46_valor      = rm_detalle[i].n46_valor
	LET r_n46.n46_saldo      = rm_detalle[i].n46_saldo
	INSERT INTO rolt046 VALUES(r_n46.*)
END FOR

END FUNCTION



FUNCTION grabar_resumen()
DEFINE r_n58		RECORD LIKE rolt058.*
DEFINE query		CHAR(800)
DEFINE i		SMALLINT

IF vm_num_dettot = 0 THEN
	LET query = 'INSERT INTO rolt058 ',
			' (n58_compania, n58_num_prest, n58_proceso, ',
			'n58_div_act, n58_num_div, n58_valor_div, ',
			'n58_valor_dist, n58_saldo_dist, n58_usuario, ',
			'n58_fecing) ',
			' SELECT n46_compania, n46_num_prest, n46_cod_liqrol,',
				' 0, COUNT(n46_secuencia), MAX(n46_valor),',
				' NVL(SUM(n46_valor), 0), NVL(SUM(n46_saldo),',
				' 0), "', vg_usuario CLIPPED, '", CURRENT ',
				' FROM rolt046 ',
				' WHERE n46_compania  = ', rm_n45.n45_compania,
				'   AND n46_num_prest = ', rm_n45.n45_num_prest,
				' GROUP BY 1, 2, 3, 4, 9, 10 '
	PREPARE exec_n58 FROM query
	EXECUTE exec_n58
	RETURN
END IF
FOR i = 1 TO vm_num_dettot
	IF rm_dettotpre[i].n58_valor_div  = 0 AND
	   rm_dettotpre[i].n58_valor_dist = 0 AND
	   rm_dettotpre[i].n58_saldo_dist = 0
	THEN
		CONTINUE FOR
	END IF
	LET r_n58.n58_compania   = rm_n45.n45_compania
	LET r_n58.n58_num_prest  = rm_n45.n45_num_prest
	LET r_n58.n58_proceso    = rm_dettotpre[i].n58_proceso
	LET r_n58.n58_div_act    = rm_dettotpre[i].n58_div_act
	LET r_n58.n58_num_div    = rm_dettotpre[i].n58_num_div
	LET r_n58.n58_valor_div  = rm_dettotpre[i].n58_valor_div
	LET r_n58.n58_valor_dist = rm_dettotpre[i].n58_valor_dist
	LET r_n58.n58_saldo_dist = rm_dettotpre[i].n58_saldo_dist
	LET r_n58.n58_usuario    = vg_usuario
	LET r_n58.n58_fecing     = CURRENT
	INSERT INTO rolt058 VALUES(r_n58.*)
END FOR

END FUNCTION



FUNCTION control_transferir_prestamo()
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE deuda		DECIMAL(14,2)

DECLARE q_n45_tran CURSOR FOR
	SELECT * FROM rolt045
		WHERE n45_compania   = vg_codcia
		  AND n45_num_prest <> rm_n45.n45_num_prest
		  AND n45_cod_rubro  = rm_n45.n45_cod_rubro
		  AND n45_cod_trab   = rm_n45.n45_cod_trab
		  AND n45_estado    IN ("A", "R")
OPEN q_n45_tran
FETCH q_n45_tran INTO r_n45.*
IF STATUS = NOTFOUND THEN
	CLOSE q_n45_tran
	FREE q_n45_tran
	RETURN
END IF
CLOSE q_n45_tran
FREE q_n45_tran
SELECT NVL(SUM(n45_val_prest + n45_sal_prest_ant + n45_valor_int -
		n45_descontado), 0)
	INTO deuda
	FROM rolt045
	WHERE n45_compania   = vg_codcia
	  AND n45_num_prest <> rm_n45.n45_num_prest
	  AND n45_cod_rubro  = rm_n45.n45_cod_rubro
	  AND n45_cod_trab   = rm_n45.n45_cod_trab
	  AND n45_estado    IN ("A", "R")
WHENEVER ERROR CONTINUE
DECLARE q_up_tran CURSOR FOR
	SELECT * FROM rolt045
		WHERE n45_compania  = r_n45.n45_compania
		  AND n45_num_prest = r_n45.n45_num_prest
	FOR UPDATE
OPEN q_up_tran
FETCH q_up_tran INTO r_n45.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('El registro del anticipo anterior no existe. Ha ocurrido un error interno de la base de datos.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
UPDATE rolt045
	SET n45_estado     = 'T',
	    n45_prest_tran = rm_n45.n45_num_prest,
	    n45_descontado = (n45_val_prest + n45_sal_prest_ant + n45_valor_int)
	WHERE CURRENT OF q_up_tran
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro del anticipo anterior. Consulte con el Administrador.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
UPDATE rolt045
	SET n45_estado        = 'R',
	    n45_prest_tran    = r_n45.n45_num_prest,
	    n45_sal_prest_ant = deuda
	WHERE n45_compania  = vg_codcia
	  AND n45_num_prest = rm_n45.n45_num_prest
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro del anticipo anterior. Consulte con el Administrador.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
--IF rm_n45.n45_val_prest = 0 THEN
	UPDATE rolt046
		SET n46_saldo = 0
		WHERE n46_compania  = r_n45.n45_compania
		  AND n46_num_prest = r_n45.n45_num_prest
	UPDATE rolt058
		SET n58_saldo_dist = 0,
		    n58_div_act    = n58_num_div
		WHERE n58_compania  = r_n45.n45_compania
		  AND n58_num_prest = r_n45.n45_num_prest
--END IF
WHENEVER ERROR STOP

END FUNCTION



FUNCTION mostrar_detalle(ini)
DEFINE ini		SMALLINT
DEFINE i, lim		SMALLINT

IF ini <= vm_num_det THEN
	CALL borrar_detalle(ini)
END IF
LET lim = vm_num_det
IF lim > fgl_scr_size('rm_detalle') THEN
	LET lim = fgl_scr_size('rm_detalle')
END IF
FOR i = ini TO lim
	DISPLAY rm_detalle[i].* TO rm_detalle[i].*
END FOR
CALL mostrar_total()

END FUNCTION



FUNCTION mostrar_total()
DEFINE i		SMALLINT

LET total_valor = 0
LET total_saldo = 0
FOR i = 1 TO vm_num_det
	LET total_valor = total_valor + rm_detalle[i].n46_valor
	LET total_saldo = total_saldo + rm_detalle[i].n46_saldo
END FOR
DISPLAY BY NAME total_valor, total_saldo

END FUNCTION



FUNCTION ubicarse_detalle()
DEFINE i, j		SMALLINT

CALL set_count(vm_num_det)
LET int_flag = 0
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F6)
		IF rm_n45.n45_estado <> 'E' AND rm_n45.n45_estado <> 'T' THEN
			CALL control_capacidad_pago()
		END IF
	ON KEY(F7)
		CALL control_forma_pago()
		LET int_flag = 0
	ON KEY(F8)
		IF rm_n45.n45_num_prest IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL control_contabilizacion()
		LET int_flag = 0
	ON KEY(F9)
		IF rm_n45.n45_num_prest IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL control_resumen(2)
		LET int_flag = 0
	ON KEY(F10)
		IF rm_n45.n45_num_prest IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL control_imprimir()
		LET int_flag = 0
	ON KEY(F11)
		IF rm_n45.n45_prest_tran IS NULL OR num_args() = 5 THEN
			CONTINUE DISPLAY
		END IF
		CALL ver_anticipo(2)
		LET int_flag = 0
	ON KEY(CONTROL-V)
		IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
			IF  rm_n45.n45_tipo_pago = 'T' AND
			   (rm_n45.n45_estado = 'A' OR rm_n45.n45_estado = 'R')
			THEN
				CALL generar_archivo()
			END IF
		END IF
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-V","") 
		--#IF rm_n45.n45_estado = 'E' OR rm_n45.n45_estado = 'T' THEN
			--#CALL dialog.keysetlabel("F6","") 
		--#ELSE
			--#CALL dialog.keysetlabel("F6","Capacidad Pago") 
		--#END IF
		--#IF rm_n45.n45_num_prest IS NULL THEN
			--#CALL dialog.keysetlabel("F8","") 
			--#CALL dialog.keysetlabel("F9","") 
			--#CALL dialog.keysetlabel("F10","") 
		--#ELSE
			--#CALL dialog.keysetlabel("F8","Contabilización") 
			--#CALL dialog.keysetlabel("F9","Resumen") 
			--#CALL dialog.keysetlabel("F10","Imprimir") 
		--#END IF
		--#IF rm_n45.n45_prest_tran IS NULL OR num_args() = 5 THEN
			--#CALL dialog.keysetlabel("F11","") 
		--#ELSE
			--#CALL dialog.keysetlabel("F11","Anticipo Anterior") 
		--#END IF
		--#IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
			--#IF  rm_n45.n45_tipo_pago = 'T' AND
			--# (rm_n45.n45_estado = 'A' OR rm_n45.n45_estado = 'R')
			--#THEN
				--#CALL dialog.keysetlabel("CONTROL-V","Archivo Banco") 
			--#END IF
		--#END IF
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
CALL muestra_contadores_det(0)
IF int_flag THEN
	IF vm_num_det > fgl_scr_size('rm_detalle') THEN
		CALL mostrar_detalle(1)
	END IF
END IF

END FUNCTION 



FUNCTION retorna_fecha(cod_liqrol, fecha_fin)
DEFINE cod_liqrol	LIKE rolt003.n03_proceso
DEFINE fecha_fin	DATE
DEFINE fecha		RECORD
				ano		SMALLINT,
				mes		SMALLINT,
				dia		SMALLINT
			END RECORD

LET fecha.ano = YEAR(fecha_fin)
LET fecha.mes = MONTH(fecha_fin)
LET fecha.dia = DAY(fecha_fin)
IF cod_liqrol[1] = 'M' OR cod_liqrol[1] = 'Q' OR cod_liqrol[1] = 'S' THEN
	CALL retorna_ano_mes(fecha.ano, fecha.mes) RETURNING fecha.ano,fecha.mes
ELSE
	LET fecha.ano = fecha.ano + 1
END IF
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

{--
IF EXTEND(MDY(mes, 01, ano), YEAR TO MONTH) = EXTEND(TODAY, YEAR TO MONTH) THEN
	RETURN ano, mes
END IF
--}
LET mes = mes + 1
IF mes > 12 THEN
	LET mes = 1
	LET ano = ano + 1
END IF
RETURN ano, mes

END FUNCTION 



FUNCTION retorna_ano_mes_gracia(ano, mes)
DEFINE ano		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso

IF rm_n45.n45_mes_gracia = 0 THEN
	RETURN ano, mes
END IF
LET mes = mes + rm_n45.n45_mes_gracia
IF mes > 12 THEN
	LET mes = mes - 12
	LET ano = ano + 1
END IF
RETURN ano, mes

END FUNCTION 



FUNCTION retorna_fecha_proc_anual_gracia(fecha_ini, fecha_fin)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha		DATE
DEFINE anio, mes	SMALLINT

IF rm_n45.n45_mes_gracia = 0 THEN
	RETURN fecha_ini, fecha_fin
END IF
CALL retorna_ano_mes_gracia(YEAR(TODAY), MONTH(TODAY)) RETURNING anio, mes
LET fecha = MDY(mes, 01, anio)
IF EXTEND(fecha, YEAR TO MONTH) > EXTEND(fecha_fin, YEAR TO MONTH) THEN
	LET fecha_ini = fecha_fin + 1 UNITS DAY
	LET fecha_fin = fecha_fin + 1 UNITS YEAR
END IF
RETURN fecha_ini, fecha_fin

END FUNCTION 



FUNCTION retorna_dia(cod_liq, flag, i)
DEFINE cod_liq		LIKE rolt003.n03_proceso
DEFINE flag, i		SMALLINT
DEFINE r_n02   		RECORD LIKE rolt002.*
DEFINE r_n03   		RECORD LIKE rolt003.*
DEFINE ano		LIKE rolt001.n01_ano_proceso
DEFINE mes		LIKE rolt001.n01_mes_proceso

IF cod_liq = 'Q1' OR cod_liq = 'Q2' OR cod_liq = 'ME' OR cod_liq = 'DC' OR
   cod_liq = 'DT' OR cod_liq = 'UT'
THEN
  	CALL fl_lee_proceso_roles(rm_par.cod_liqrol) RETURNING r_n03.*
		RETURN r_n03.n03_dia_ini
END IF
IF cod_liq[1,1] = 'S' THEN
	CASE flag
		WHEN 1
			LET ano = YEAR(rm_par.n46_fecha_ini)
			LET mes = MONTH(rm_par.n46_fecha_ini)
		WHEN 2
			LET ano = YEAR(rm_detalle[i].n46_fecha_ini)
			LET mes = MONTH(rm_detalle[i].n46_fecha_ini)
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
DEFINE fecha_ini	LIKE rolt046.n46_fecha_ini
DEFINE fecha_fin	LIKE rolt046.n46_fecha_fin
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
--DEFINE k, l		SMALLINT

CASE flag
	WHEN 1
		LET cod_liqrol = rm_par.cod_liqrol
		IF cod_liqrol[1] = 'M' OR cod_liqrol[1] = 'Q' OR
		   cod_liqrol[1] = 'S' THEN
			LET anio = rm_n32.n32_ano_proceso
			LET mes  = rm_n32.n32_mes_proceso
		END IF
		IF cod_liqrol = 'DT' OR cod_liqrol = 'DC' THEN
			LET anio = rm_n36.n36_ano_proceso
			LET mes  = rm_n36.n36_mes_proceso
		END IF
		IF cod_liqrol = 'VA' OR cod_liqrol = 'VP' THEN
			LET anio = rm_n39.n39_ano_proceso
			LET mes  = rm_n39.n39_mes_proceso
		END IF
		IF cod_liqrol = 'UT' THEN
			LET anio = rm_n41.n41_ano
			LET mes  = 1
		END IF
	WHEN 2
		LET cod_liqrol = rm_detalle[i].n46_cod_liqrol
		{--
		LET l = 0
		IF i > 1 THEN
			FOR k = 1 TO i - 1
				IF cod_liqrol = rm_detalle[k].n46_cod_liqrol
				THEN
					LET l = k
					EXIT FOR
				END IF
			END FOR
		END IF
		IF l = 0 THEN
			LET l = i
		END IF
		--}
		IF cod_liqrol[1] = 'M' OR cod_liqrol[1] = 'Q' OR
		   cod_liqrol[1] = 'S' THEN
			LET mes  = MONTH(rm_detalle[i].n46_fecha_ini)
			LET anio = YEAR(rm_detalle[i].n46_fecha_ini)
		END IF
		IF cod_liqrol = 'DT' OR cod_liqrol = 'DC' OR
		   cod_liqrol = 'VA' OR cod_liqrol = 'UT' OR cod_liqrol = 'VP'
		THEN
			LET mes  = MONTH(rm_detalle[i].n46_fecha_fin)
			LET anio = YEAR(rm_detalle[i].n46_fecha_fin)
		END IF
END CASE
CALL retorna_fecha_proc(cod_liqrol, anio, mes) RETURNING fecha_ini, fecha_fin
CASE flag
	WHEN 1
		LET rm_par.n46_fecha_ini = fecha_ini
		LET rm_par.n46_fecha_fin = fecha_fin
		DISPLAY BY NAME rm_par.n46_fecha_ini, rm_par.n46_fecha_fin
	WHEN 2
		LET rm_detalle[i].n46_fecha_ini = fecha_ini
		LET rm_detalle[i].n46_fecha_fin = fecha_fin
		DISPLAY rm_detalle[i].n46_fecha_ini TO
			rm_detalle[j].n46_fecha_ini
		DISPLAY rm_detalle[i].n46_fecha_fin TO
			rm_detalle[j].n46_fecha_fin
END CASE

END FUNCTION 



FUNCTION retorna_fecha_proc(cod_liqrol, anio, mes)
DEFINE cod_liqrol	LIKE rolt003.n03_proceso
DEFINE fecha_ini	LIKE rolt046.n46_fecha_ini
DEFINE fecha_fin	LIKE rolt046.n46_fecha_fin
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE anio_g		LIKE rolt032.n32_ano_proceso
DEFINE mes_g		LIKE rolt032.n32_mes_proceso
DEFINE dia	 	SMALLINT
DEFINE fecha		DATE

IF cod_liqrol <> 'VA' AND cod_liqrol <> 'VP' THEN
	IF cod_liqrol = 'UT' THEN
		IF anio - 1 < YEAR(TODAY) - 1 THEN
			LET anio = YEAR(TODAY) - 1
		END IF
	END IF
	CALL fl_retorna_rango_fechas_proceso(vg_codcia, cod_liqrol, anio, mes)
		RETURNING fecha_ini, fecha_fin
	IF (EXTEND(MDY(mes, 01, anio), YEAR TO MONTH) <=
	    EXTEND(TODAY, YEAR TO MONTH)) AND
	   (cod_liqrol[1] = 'M' OR cod_liqrol[1] = 'Q' OR cod_liqrol[1] = 'S')
	THEN
		INITIALIZE fecha TO NULL
		SELECT a.n32_fecha_fin INTO fecha
			FROM rolt032 a
			WHERE a.n32_compania   = vg_codcia
			  AND a.n32_cod_liqrol = cod_liqrol
			  AND a.n32_fecha_fin <=
				(SELECT MAX(b.n32_fecha_fin)
				FROM rolt032 b
					WHERE b.n32_compania   = a.n32_compania
					  AND b.n32_cod_liqrol =a.n32_cod_liqrol
					  AND b.n32_fecha_ini  = a.n32_fecha_ini
					  AND b.n32_fecha_fin  = a.n32_fecha_fin
				  	  AND b.n32_cod_trab   = a.n32_cod_trab)
			  AND a.n32_cod_trab   = rm_n45.n45_cod_trab
			  AND a.n32_estado     = 'A'
		IF fecha IS NOT NULL THEN
			CALL retorna_ano_mes_gracia(YEAR(fecha), MONTH(fecha))
				RETURNING anio_g, mes_g
			LET fecha_fin = MDY(mes_g, DAY(fecha), anio_g)
			IF cod_liqrol = 'Q1' THEN
				LET fecha_ini = MDY(MONTH(fecha_fin), 01,
							YEAR(fecha_fin))
			END IF
			IF cod_liqrol = 'Q2' THEN
				LET fecha_ini = MDY(MONTH(fecha_fin), 16,
							YEAR(fecha_fin))
			END IF
		END IF
	END IF
	IF anio <= YEAR(TODAY) AND (cod_liqrol = 'DT' OR cod_liqrol = 'DC') THEN
		LET fecha = NULL
		SELECT MAX(n36_fecha_fin) + 1 UNITS DAY
			INTO fecha
			FROM rolt036
			WHERE n36_compania   = vg_codcia
			  AND n36_proceso    = cod_liqrol
			  AND n36_fecha_fin <= fecha_fin
			  AND n36_estado     = 'P'
		IF fecha IS NOT NULL THEN
			CALL fl_lee_proceso_roles(cod_liqrol) RETURNING r_n03.*
			LET fecha_ini = MDY(r_n03.n03_mes_ini,
						r_n03.n03_dia_ini, YEAR(fecha))
			LET fecha_fin = fecha_ini + 1 UNITS YEAR - 1 UNITS DAY
		END IF
		CALL retorna_fecha_proc_anual_gracia(fecha_ini, fecha_fin)
			RETURNING fecha_ini, fecha_fin
	END IF
	IF anio <= YEAR(TODAY) AND cod_liqrol = 'UT' THEN
		LET anio = NULL
		SELECT MAX(n41_ano) + 1
			INTO anio
			FROM rolt041
			WHERE n41_compania = vg_codcia
			  AND n41_estado   = 'P'
		IF anio IS NOT NULL THEN
			CALL fl_lee_proceso_roles(cod_liqrol) RETURNING r_n03.*
			LET fecha_ini = MDY(r_n03.n03_mes_ini,
						r_n03.n03_dia_ini, anio)
			LET fecha_fin = MDY(r_n03.n03_mes_fin,
						r_n03.n03_dia_fin, anio)
		END IF
	END IF
	IF cod_liqrol = 'UT' THEN
		IF YEAR(fecha_fin) + 1 < YEAR(TODAY) THEN
			LET fecha_ini = fecha_ini + 1 UNITS YEAR
			LET fecha_fin = fecha_fin + 1 UNITS YEAR
		END IF
	END IF
ELSE
	CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab)
		RETURNING r_n30.*
	LET dia = DAY(r_n30.n30_fecha_ing)
	IF dia > 1 AND dia < 16 THEN
		LET dia = 1
	END IF
	IF dia > 16 THEN
		LET dia = 16
	END IF
	LET fecha_ini = MDY(MONTH(r_n30.n30_fecha_ing), dia, anio - 1)
	LET fecha_fin = fecha_ini + 1 UNITS YEAR - 1 UNITS DAY
END IF
RETURN fecha_ini, fecha_fin

END FUNCTION 



FUNCTION borrar_pantalla()

CALL borrar_cabecera()
CALL limpiar_detalle()
CALL borrar_detalle(1)

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR n45_estado, tit_estado, n45_num_prest, n45_cod_rubro, n06_nombre,
	n45_cod_trab, n30_nombres, n45_moneda, g13_nombre, n45_val_prest,
	n45_paridad, n45_sal_prest_ant, n45_descontado, valor_deuda, n45_fecha,
	n45_fec_elimi, n45_referencia, n45_usuario, n45_prest_tran,
	n45_mes_gracia, n45_porc_int, n45_valor_int
INITIALIZE rm_n45.*, rm_par.* TO NULL

END FUNCTION



FUNCTION limpiar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].* TO NULL
END FOR

END FUNCTION



FUNCTION borrar_detalle(ini)
DEFINE ini, i		SMALLINT

FOR i = ini TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
CLEAR total_valor, total_saldo

END FUNCTION


 
FUNCTION ver_anticipo(flag)
DEFINE flag		SMALLINT
DEFINE param		VARCHAR(60)
DEFINE num_prest	LIKE rolt045.n45_num_prest

CASE flag
	WHEN 1 LET num_prest = rm_detprest[vm_cur_prest].n46_num_prest
	WHEN 2 LET num_prest = rm_n45.n45_prest_tran
END CASE
LET param = ' ', num_prest, ' "X"'
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp214 ', param)

END FUNCTION



FUNCTION ver_liquidacion()
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE r_n32		RECORD LIKE rolt032.*

CALL fl_lee_liquidacion_roles(vg_codcia,rm_detliq[vm_cur_detliq].n32_cod_liqrol,
					rm_detliq[vm_cur_detliq].n32_fecha_ini,
					rm_detliq[vm_cur_detliq].n32_fecha_fin,
					rm_n45.n45_cod_trab)
	RETURNING r_n32.*
LET prog  = 'rolp303 '
LET param = ' "', rm_detliq[vm_cur_detliq].n32_cod_liqrol, '" ',
		'"', rm_detliq[vm_cur_detliq].n32_fecha_ini, '" ',
		'"', rm_detliq[vm_cur_detliq].n32_fecha_fin, '" "N" ',
		r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION



FUNCTION regenerar_novedades(num_prest, sin_saldo)
DEFINE num_prest	LIKE rolt045.n45_num_prest
DEFINE sin_saldo	SMALLINT
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE mensaje		VARCHAR(200)
DEFINE resul		SMALLINT

CALL proceso_activo_nomina(num_prest, 0, sin_saldo) RETURNING r_n05.*, resul
IF resul THEN
	RETURN
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab) RETURNING r_n30.*
LET mensaje = 'Se va a regenerar novedad de ', r_n05.n05_proceso, ' ',
		r_n05.n05_fecini_act USING "dd-mm-yyyy", ' - ',
		r_n05.n05_fecfin_act USING "dd-mm-yyyy", ' para el trabajador ',
		rm_n45.n45_cod_trab USING "&&&&", ' ', r_n30.n30_nombres CLIPPED
CALL fl_mostrar_mensaje(mensaje, 'info')
CASE r_n05.n05_proceso
	WHEN 'Q1' LET prog  = 'rolp200 '
	WHEN 'Q2' LET prog  = 'rolp200 '
	WHEN 'DT' LET prog  = 'rolp207 '
	WHEN 'DC' LET prog  = 'rolp221 '
	WHEN 'UT' LET prog  = 'rolp222 '
END CASE
LET param = ' ', r_n05.n05_proceso[1,1], ' ', rm_n45.n45_cod_trab, ' ',
		r_n05.n05_proceso, ' ', r_n05.n05_fecini_act, ' ',
		r_n05.n05_fecfin_act
IF r_n05.n05_proceso = 'DT' OR r_n05.n05_proceso = 'DC' THEN
	LET param = ' ', r_n05.n05_fecini_act, ' ', r_n05.n05_fecfin_act, ' ',
			rm_n45.n45_cod_trab, ' G'
END IF
IF r_n05.n05_proceso = 'UT' THEN
	LET param = ' ', YEAR(r_n05.n05_fecfin_act), ' ', rm_n45.n45_cod_trab,
			' G'
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION



FUNCTION proceso_activo_nomina(num_prest, flag, sin_saldo)
DEFINE num_prest	LIKE rolt045.n45_num_prest
DEFINE flag, sin_saldo	SMALLINT
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n46		RECORD LIKE rolt046.*
DEFINE r_n53		RECORD LIKE rolt053.*

INITIALIZE r_n05.*, r_n46.*, r_n53.* TO NULL
SELECT * INTO r_n05.*
	FROM rolt005 
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
IF r_n05.n05_compania IS NULL THEN
	RETURN r_n05.*, 1
END IF
IF r_n05.n05_proceso[1,1] <> 'M' AND r_n05.n05_proceso[1,1] <> 'Q' AND
   r_n05.n05_proceso[1,1] <> 'S' AND r_n05.n05_proceso[1,1] <> 'D' AND
   r_n05.n05_proceso[1,1] <> 'U'
THEN
	RETURN r_n05.*, 1
END IF
IF NOT sin_saldo THEN
	SELECT * INTO r_n46.*
		FROM rolt046 
		WHERE n46_compania   = r_n05.n05_compania
		  AND n46_num_prest  = num_prest
		  AND n46_cod_liqrol = r_n05.n05_proceso
		  AND n46_fecha_ini  = r_n05.n05_fecini_act
		  AND n46_fecha_fin  = r_n05.n05_fecfin_act
		  AND n46_saldo      > 0
ELSE
	SELECT * INTO r_n46.*
		FROM rolt046 
		WHERE n46_compania   = r_n05.n05_compania
		  AND n46_num_prest  = num_prest
		  AND n46_cod_liqrol = r_n05.n05_proceso
		  AND n46_fecha_ini  = r_n05.n05_fecini_act
		  AND n46_fecha_fin  = r_n05.n05_fecfin_act
	IF STATUS = NOTFOUND THEN
		IF r_n05.n05_proceso[1,1] = 'Q' THEN
			SELECT * INTO r_n46.*
				FROM rolt046 
				WHERE n46_compania   = vg_codcia
				  AND n46_num_prest  = num_prest
				  AND n46_cod_liqrol = rm_n32.n32_cod_liqrol
				  AND n46_fecha_ini  = rm_n32.n32_fecha_ini
				  AND n46_fecha_fin  = rm_n32.n32_fecha_fin
		END IF
	END IF
END IF
IF r_n46.n46_compania IS NULL THEN
	RETURN r_n05.*, 1
END IF
IF flag THEN
	IF r_n05.n05_proceso[1,1] <> 'M' AND r_n05.n05_proceso[1,1] <> 'Q' AND
	   r_n05.n05_proceso[1,1] <> 'S' AND r_n05.n05_proceso[1,1] <> 'D'
	THEN
		SELECT * INTO r_n53.*
			FROM rolt053 
			WHERE n53_compania   = r_n05.n05_compania
			  AND n53_cod_liqrol = r_n05.n05_proceso
			  AND n53_fecha_ini  = r_n05.n05_fecini_act
			  AND n53_fecha_fin  = r_n05.n05_fecfin_act
		IF r_n53.n53_compania IS NULL THEN
			RETURN r_n05.*, 1
		END IF
	END IF
END IF
RETURN r_n05.*, 0

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



FUNCTION control_forma_pago()
DEFINE lin_men		SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul	 	SMALLINT
DEFINE escape	 	INTEGER
DEFINE resp		CHAR(6)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE tipo_pago	LIKE rolt045.n45_tipo_pago
DEFINE cta_trabaj	LIKE rolt045.n45_cta_trabaj

LET lin_men  = 0
LET num_rows = 10
LET num_cols = 71
IF vg_gui = 0 THEN
	LET lin_men  = 1
	LET num_rows = 11
	LET num_cols = 72
END IF
OPEN WINDOW w_rolf214_5 AT 10, 05 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_men, BORDER,
		  MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf214_5 FROM '../forms/rolf214_5'
ELSE
	OPEN FORM f_rolf214_5 FROM '../forms/rolf214_5c'
END IF
DISPLAY FORM f_rolf214_5
CALL fl_lee_banco_general(rm_n45.n45_bco_empresa) RETURNING r_g08.*
DISPLAY BY NAME r_g08.g08_nombre
CALL lee_prest_cont(vg_codcia, rm_n45.n45_num_prest) RETURNING r_n59.*
IF r_n59.n59_compania IS NOT NULL AND vm_flag_mant = 'C' THEN
	WHILE TRUE
		LET tipo_pago = rm_n45.n45_tipo_pago
		IF rm_n45.n45_val_prest = 0 THEN
			LET rm_n45.n45_tipo_pago = 'R'
		END IF
		DISPLAY BY NAME rm_n45.n45_tipo_pago, rm_n45.n45_bco_empresa,
				rm_n45.n45_cta_empresa, rm_n45.n45_cta_trabaj
		MESSAGE 'Presione ESC para SALIR ...'
		LET escape = fgl_getkey()
		IF escape <> 0 AND escape <> 27 THEN
			CONTINUE WHILE
		END IF
		IF rm_n45.n45_val_prest = 0 THEN
			LET rm_n45.n45_tipo_pago = tipo_pago
		END IF
		EXIT WHILE
	END WHILE
	CLOSE WINDOW w_rolf214_5
	RETURN
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab) RETURNING r_n30.*
IF (r_n30.n30_tipo_pago  <> 'E' AND r_n30.n30_bco_empresa  IS NOT NULL) AND
   (rm_n45.n45_tipo_pago <> 'E' AND rm_n45.n45_bco_empresa IS NULL) AND
    rm_n45.n45_val_prest  > 0
THEN
	LET rm_n45.n45_tipo_pago   = r_n30.n30_tipo_pago
	LET rm_n45.n45_bco_empresa = r_n30.n30_bco_empresa
	LET rm_n45.n45_cta_empresa = r_n30.n30_cta_empresa
	IF rm_n45.n45_tipo_pago = 'T' THEN
		LET rm_n45.n45_cta_trabaj  = r_n30.n30_cta_trabaj
	END IF
	CALL fl_lee_banco_general(rm_n45.n45_bco_empresa) RETURNING r_g08.*
	DISPLAY BY NAME r_g08.g08_nombre
ELSE
	IF rm_n45.n45_val_prest = 0 THEN
		CALL fl_lee_cab_prestamo_roles(rm_n45.n45_compania,
						rm_n45.n45_prest_tran)
			RETURNING r_n45.*
		LET rm_n45.n45_tipo_pago   = 'R'
		LET rm_n45.n45_bco_empresa = r_n45.n45_bco_empresa
		LET rm_n45.n45_cta_empresa = r_n45.n45_cta_empresa
		--IF rm_n45.n45_cta_trabaj IS NULL THEN
			CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro)
				RETURNING r_n06.*
			INITIALIZE r_n56.* TO NULL
			SELECT * INTO r_n56.*
				FROM rolt056
				WHERE n56_compania  = vg_codcia
				  AND n56_proceso   = r_n06.n06_flag_ident
				  AND n56_cod_depto = r_n30.n30_cod_depto
				  AND n56_cod_trab  = rm_n45.n45_cod_trab
				  AND n56_estado    = "A"
			IF r_n56.n56_compania IS NOT NULL THEN
				LET vm_aux_con_red = r_n56.n56_aux_val_vac
			END IF
		--END IF
		CALL fl_lee_banco_general(rm_n45.n45_bco_empresa)
			RETURNING r_g08.*
		DISPLAY BY NAME r_g08.g08_nombre
	END IF
END IF
LET r_n45.* = rm_n45.*
LET int_flag = 0
IF rm_n45.n45_tipo_pago = 'R' THEN
	CLOSE WINDOW w_rolf214_5
	RETURN
END IF
INPUT BY NAME rm_n45.n45_tipo_pago, rm_n45.n45_bco_empresa,
	rm_n45.n45_cta_empresa, rm_n45.n45_cta_trabaj
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n45.n45_tipo_pago, rm_n45.n45_bco_empresa,
				 rm_n45.n45_cta_empresa, rm_n45.n45_cta_trabaj)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET rm_n45.n45_tipo_pago  = r_n45.n45_tipo_pago
				LET rm_n45.n45_bco_empresa=r_n45.n45_bco_empresa
				LET rm_n45.n45_cta_empresa=r_n45.n45_cta_empresa
				LET rm_n45.n45_cta_trabaj =r_n45.n45_cta_trabaj
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n45_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
                                RETURNING r_g08.g08_banco, r_g08.g08_nombre,
					r_g09.g09_tipo_cta, r_g09.g09_numero_cta
                        IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_n45.n45_bco_empresa = r_g08.g08_banco
				LET rm_n45.n45_cta_empresa =r_g09.g09_numero_cta
				CALL fl_lee_trabajador_roles(
							rm_n45.n45_compania,
							rm_n45.n45_cod_trab)
					RETURNING r_n30.*
				IF rm_n45.n45_tipo_pago = 'T' THEN
					LET rm_n45.n45_cta_trabaj =
							r_n30.n30_cta_trabaj
				END IF
                                DISPLAY BY NAME rm_n45.n45_bco_empresa,
						r_g08.g08_nombre,
						rm_n45.n45_cta_empresa,
						rm_n45.n45_cta_trabaj
                        END IF
                END IF
		{--
		IF INFIELD(n45_cta_trabaj) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n45.n45_cta_trabaj = r_b10.b10_cuenta
				DISPLAY BY NAME rm_n45.n45_cta_trabaj
			END IF
		END IF
		--}
		LET int_flag = 0
	BEFORE FIELD n45_cta_trabaj
		LET cta_trabaj = rm_n45.n45_cta_trabaj
	AFTER FIELD n45_tipo_pago
		CALL fl_lee_trabajador_roles(rm_n45.n45_compania,
						rm_n45.n45_cod_trab)
			RETURNING r_n30.*
		CASE rm_n45.n45_tipo_pago
			WHEN 'E'
				LET rm_n45.n45_bco_empresa = NULL
				LET rm_n45.n45_cta_empresa = NULL
				LET rm_n45.n45_cta_trabaj  = NULL
			WHEN 'C'
				LET rm_n45.n45_bco_empresa=r_n30.n30_bco_empresa
				LET rm_n45.n45_cta_empresa=r_n30.n30_cta_empresa
				LET rm_n45.n45_cta_trabaj = NULL
			WHEN 'T'
				LET rm_n45.n45_bco_empresa=r_n30.n30_bco_empresa
				LET rm_n45.n45_cta_empresa=r_n30.n30_cta_empresa
				LET rm_n45.n45_cta_trabaj = r_n30.n30_cta_trabaj
		END CASE
		CALL fl_lee_banco_general(rm_n45.n45_bco_empresa)
			RETURNING r_g08.*
		DISPLAY BY NAME rm_n45.n45_tipo_pago, rm_n45.n45_bco_empresa,
				r_g08.g08_nombre, rm_n45.n45_cta_empresa,
				rm_n45.n45_cta_trabaj
	AFTER FIELD n45_bco_empresa
                IF rm_n45.n45_bco_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_general(rm_n45.n45_bco_empresa)
                                RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD n45_bco_empresa
			END IF
			DISPLAY BY NAME r_g08.g08_nombre
		ELSE
			CLEAR n45_bco_empresa, g08_nombre, n45_cta_empresa
                END IF
	AFTER FIELD n45_cta_empresa
                IF rm_n45.n45_cta_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_compania(vg_codcia,
							rm_n45.n45_bco_empresa,
							rm_n45.n45_cta_empresa)
                                RETURNING r_g09.*
			IF r_g09.g09_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco o Cuenta Corriente no existe en la compañía.','exclamation')
				NEXT FIELD n45_bco_empresa
			END IF
			LET rm_n45.n45_cta_empresa = r_g09.g09_numero_cta
			DISPLAY BY NAME rm_n45.n45_cta_empresa
                        CALL fl_lee_banco_general(rm_n45.n45_bco_empresa)
                                RETURNING r_g08.*
			DISPLAY BY NAME r_g08.g08_nombre
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n45_bco_empresa
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n45_bco_empresa
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n45_bco_empresa
			END IF
		ELSE
			CLEAR n45_cta_empresa
		END IF
	AFTER FIELD n45_cta_trabaj
		IF rm_n45.n45_cta_trabaj IS NULL THEN
			LET rm_n45.n45_cta_trabaj = cta_trabaj
		END IF
		IF rm_n45.n45_cta_trabaj <> cta_trabaj THEN
			LET rm_n45.n45_cta_trabaj = cta_trabaj
		END IF
		DISPLAY BY NAME rm_n45.n45_cta_trabaj
		IF rm_n45.n45_tipo_pago <> 'T' THEN
			LET rm_n45.n45_cta_trabaj = NULL
			DISPLAY BY NAME rm_n45.n45_cta_trabaj
			CONTINUE INPUT
		END IF
		IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
			{--
			IF NOT validar_cuenta(rm_n45.n45_cta_trabaj) THEN
				NEXT FIELD n45_cta_trabaj
			END IF
			--}
		ELSE
			CLEAR n45_cta_trabaj
		END IF
	AFTER INPUT
		IF rm_n45.n45_tipo_pago = 'R' THEN
			CALL fl_mostrar_mensaje('Cambie la forma de pago.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_n45.n45_tipo_pago <> 'E' THEN
			IF rm_n45.n45_bco_empresa IS NULL OR
			   rm_n45.n45_cta_empresa IS NULL
			THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de pago Cheque o Transferencia, debe ingresar el Banco y la Cuenta Corriente.', 'exclamation')
				NEXT FIELD n45_bco_empresa
			END IF
		ELSE
			IF rm_n45.n45_bco_empresa IS NULL OR
			   rm_n45.n45_cta_empresa IS NULL
			THEN
				INITIALIZE rm_n45.n45_bco_empresa,
					rm_n45.n45_cta_empresa TO NULL
				CLEAR n45_bco_empresa, n45_cta_empresa,
					g08_nombre
			END IF
		END IF
		IF rm_n45.n45_cta_trabaj IS NULL THEN
			IF rm_n45.n45_tipo_pago = 'T' THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de Pago Transferencia, debe ingresar el No. de Cuenta de su Banco.', 'exclamation')
				NEXT FIELD n45_cta_trabaj
			END IF
		END IF
		IF rm_n45.n45_tipo_pago = 'T' THEN
			IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
				{--
				IF NOT validar_cuenta(rm_n45.n45_cta_trabaj)
				THEN
					NEXT FIELD n45_cta_trabaj
				END IF
				--}
			END IF
		END IF
END INPUT
CLOSE WINDOW w_rolf214_5

END FUNCTION



FUNCTION validar_cuenta(aux_cont)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 0
END IF
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 0
END IF
IF r_cta.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION




FUNCTION control_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE tipo_pago	LIKE rolt045.n45_tipo_pago
DEFINE resp		CHAR(6)

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL lee_prest_cont(vg_codcia, rm_n45.n45_num_prest) RETURNING r_n59.*
IF r_n59.n59_compania IS NOT NULL THEN
	CALL ver_contabilizacion(r_n59.n59_tipo_comp, r_n59.n59_num_comp)
	RETURN
END IF
IF rm_n90.n90_gen_cont_ant = 'N' THEN
	CALL fl_mostrar_mensaje('No se puede contabilizar el anticipo, porque no esta configurado generacion contable para anticipos, en la configuracion adicional de nomina.', 'exclamation')
	RETURN
END IF
IF rm_n45.n45_estado <> 'A' AND rm_n45.n45_estado <> 'R' THEN
	CALL fl_mostrar_mensaje('Solo puede contabilizar un anticipo cuando esta Activo o Redistribuido.', 'exclamation')
	RETURN
END IF
IF rm_n45.n45_descontado > 0 THEN
	CALL fl_mostrar_mensaje('No puede contabilizar un anticipo que ya se comenzo a descontar.', 'exclamation')
	RETURN
END IF
IF rm_n45.n45_val_prest > 0 AND rm_n45.n45_tipo_pago <> 'E' THEN
--IF rm_n45.n45_val_prest > 0 THEN
	CALL fl_hacer_pregunta('Esta seguro de generar contabilización para este Anticipo ?', 'Yes')
		RETURNING resp
	IF resp <> 'Yes' THEN
		RETURN
	END IF
END IF
IF vm_flag_mant <> 'I' AND rm_n45.n45_tipo_pago <> 'E' THEN
--IF vm_flag_mant <> 'I' THEN
	CALL control_forma_pago()
	IF int_flag THEN
		RETURN
	END IF
END IF
BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_cont CURSOR FOR
		SELECT * FROM rolt045
			WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_cont
	FETCH q_cont INTO rm_n45.*
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
	LET tipo_pago = rm_n45.n45_tipo_pago
	IF rm_n45.n45_tipo_pago = 'R' THEN
		LET tipo_pago = 'T'
	END IF
	UPDATE rolt045
		SET n45_tipo_pago   = tipo_pago,
		    n45_bco_empresa = rm_n45.n45_bco_empresa,
		    n45_cta_empresa = rm_n45.n45_cta_empresa,
		    n45_cta_trabaj  = rm_n45.n45_cta_trabaj
		WHERE CURRENT OF q_cont
	IF STATUS < 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
		RETURN
	END IF
	WHENEVER ERROR STOP
	CALL generar_contabilizacion() RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF
COMMIT WORK
IF r_b12.b12_compania IS NOT NULL AND rm_b00.b00_mayo_online = 'S' THEN
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
					r_b12.b12_num_comp, 'M')
END IF
CALL fl_hacer_pregunta('Desea ver contabilización generada ?', 'Yes')
	RETURNING resp
IF resp = 'Yes' THEN
	CALL ver_contabilizacion(r_b12.b12_tipo_comp, r_b12.b12_num_comp)
END IF
CALL fl_lee_cab_prestamo_roles(vg_codcia, rm_n45.n45_num_prest)
	RETURNING rm_n45.*
CALL fl_mostrar_mensaje('Contabilización del Anticipo Generada Ok.', 'info')
IF rm_n45.n45_cta_trabaj IS NOT NULL THEN
	IF  rm_n45.n45_tipo_pago = 'T' AND
	   (rm_n45.n45_estado = 'A' OR rm_n45.n45_estado = 'R')
	THEN
		CALL generar_archivo()
	END IF
END IF

END FUNCTION



FUNCTION generar_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE r_n59		RECORD LIKE rolt059.*
DEFINE glosa		LIKE ctbt012.b12_glosa
DEFINE num_che		LIKE ctbt012.b12_num_cheque
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE val_prest	LIKE rolt045.n45_val_prest
DEFINE valor_cuad	DECIMAL(14,2)

INITIALIZE r_b12.*, r_n56.*, r_n59.* TO NULL
CALL fl_lee_trabajador_roles(vg_codcia, rm_n45.n45_cod_trab) RETURNING r_n30.*
CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro) RETURNING r_n06.*
SELECT * INTO r_n56.*
	FROM rolt056
	WHERE n56_compania  = vg_codcia
	  AND n56_proceso   = r_n06.n06_flag_ident
	  AND n56_cod_depto = r_n30.n30_cod_depto
	  AND n56_cod_trab  = rm_n45.n45_cod_trab
	  AND n56_estado    = "A"
IF r_n56.n56_compania IS NULL THEN
	CALL fl_lee_proceso_roles(r_n06.n06_flag_ident) RETURNING r_n03.*
	CALL fl_mostrar_mensaje('No existen auxiliares contable para este trabajador en el proceso de ' || r_n03.n03_nombre CLIPPED || '.', 'stop')
	RETURN r_b12.*
END IF
IF rm_n45.n45_valor_int > 0 AND r_n56.n56_aux_otr_egr IS NULL THEN
	CALL fl_mostrar_mensaje('No existe auxiliar contable para el valor interes.', 'stop')
	RETURN r_b12.*
END IF
IF NOT validacion_contable(TODAY) THEN
	RETURN r_b12.*
END IF
LET r_b12.b12_compania 	  = vg_codcia
LET r_b12.b12_tipo_comp   = "DC"
IF rm_n45.n45_tipo_pago = 'C' THEN
	LET r_b12.b12_tipo_comp = "EG"
END IF
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
				r_b12.b12_tipo_comp, YEAR(TODAY), MONTH(TODAY)) 
IF r_b12.b12_num_comp <= 0 THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
LET r_b12.b12_estado 	  = 'A'
LET r_b12.b12_glosa       = rm_n45.n45_referencia CLIPPED, ' ',
				r_n30.n30_nombres[1, 25] CLIPPED,
				', ANTICIPOS DE EMPLEADOS ',
				DATE(rm_n45.n45_fecha) USING "dd-mm-yyyy"
IF rm_n45.n45_tipo_pago = 'C' THEN
	LET r_b12.b12_benef_che = r_n30.n30_nombres CLIPPED
	CALL lee_cheque(r_b12.*) RETURNING num_che, glosa
	IF int_flag THEN
		CALL fl_mostrar_mensaje('Debe generar el cheque, de lo contrario no se podra liquidar este anticipo.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
	LET r_b12.b12_num_cheque = num_che
	LET r_b12.b12_glosa      = glosa CLIPPED
END IF
IF rm_n45.n45_sal_prest_ant > 0 THEN
	LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' (REDISTRIBUIDO).'
END IF
LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' ANT. ',
			rm_n45.n45_num_prest USING "<<&&", ' '
IF rm_n45.n45_sal_prest_ant > 0 THEN
	LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' PA-',
				rm_n45.n45_prest_tran USING "<<&&"
END IF
LET r_b12.b12_origen      = 'A'
CALL fl_lee_moneda(r_n30.n30_mon_sueldo) RETURNING r_g13.*
IF r_g13.g13_moneda = rg_gen.g00_moneda_base THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(r_g13.g13_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('La paridad para esta moneda no existe.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
END IF
LET r_b12.b12_moneda      = r_g13.g13_moneda
LET r_b12.b12_paridad     = r_g14.g14_tasa
LET r_b12.b12_fec_proceso = TODAY
LET r_b12.b12_modulo      = vg_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = CURRENT
INSERT INTO ctbt012 VALUES (r_b12.*) 
LET val_prest = rm_n45.n45_val_prest + rm_n45.n45_valor_int
IF rm_n45.n45_val_prest = 0 THEN
	LET val_prest = rm_n45.n45_sal_prest_ant
END IF
CALL fl_lee_cab_prestamo_roles(vg_codcia, rm_n45.n45_prest_tran)
	RETURNING r_n45.*
IF r_n45.n45_estado = 'A' OR r_n45.n45_estado = 'R' OR r_n45.n45_estado = 'T'
THEN
	-- OJO QUITAR CUANDO ESTEN DADOS DE BAJA LOS ANTICIPOS VIEJOS
	IF vg_codloc <> 3 OR DATE(r_n45.n45_fecing) >= MDY(06, 15, 2007) THEN
	--

	CALL lee_prest_cont(vg_codcia, r_n45.n45_num_prest) RETURNING r_n59.*
	IF r_n59.n59_compania IS NULL THEN
		LET val_prest = val_prest + r_n45.n45_val_prest
				+ r_n45.n45_valor_int
	END IF

	--
	END IF
	--
END IF
LET sec = 1
--IF rm_n45.n45_tipo_pago = 'T' OR rm_n45.n45_tipo_pago = 'R' THEN
IF rm_n45.n45_val_prest = 0 THEN
	LET r_n56.n56_aux_banco = vm_aux_con_red
END IF
IF rm_n45.n45_tipo_pago = 'R' THEN
	CALL generar_detalle_contable(r_b12.*, vm_aux_con_red, val_prest,
					'D', sec, 0, 'S')
ELSE
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac, val_prest,
					'D', sec, 0, 'S')
END IF
IF rm_n45.n45_sal_prest_ant > 0 AND rm_n45.n45_val_prest > 0 THEN
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				rm_n45.n45_sal_prest_ant, 'D', sec, 0, 'S')
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				rm_n45.n45_sal_prest_ant, 'H', sec, 1, 'N')
END IF
IF rm_n45.n45_valor_int > 0 THEN
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_otr_egr,
					rm_n45.n45_valor_int, 'H', sec, 0, 'S')
END IF
LET sec = sec + 1
CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_banco, (val_prest -
				rm_n45.n45_valor_int), 'H', sec, 1, 'S')
SELECT NVL(SUM(b13_valor_base), 0) INTO valor_cuad
	FROM ctbt013
	WHERE b13_compania  = vg_codcia
	  AND b13_tipo_comp = r_b12.b12_tipo_comp
	  AND b13_num_comp  = r_b12.b12_num_comp
IF valor_cuad <> 0 THEN
	CALL fl_mostrar_mensaje('Se ha generado un error en la contabilizacion. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
INITIALIZE r_n59.* TO NULL
LET r_n59.n59_compania  = rm_n45.n45_compania
LET r_n59.n59_num_prest = rm_n45.n45_num_prest
LET r_n59.n59_tipo_comp = r_b12.b12_tipo_comp
LET r_n59.n59_num_comp  = r_b12.b12_num_comp
INSERT INTO rolt059 VALUES(r_n59.*)
RETURN r_b12.*

END FUNCTION



FUNCTION validacion_contable(fecha)
DEFINE fecha		DATE
DEFINE resp 		VARCHAR(6)

IF YEAR(fecha) < YEAR(rm_b00.b00_fecha_cm) OR
  (YEAR(fecha) = YEAR(rm_b00.b00_fecha_cm) AND
   MONTH(fecha) <= MONTH(rm_b00.b00_fecha_cm))
THEN
	CALL fl_mostrar_mensaje('El Mes en Contabilidad esta cerrado. Reapertúrelo para que se pueda generar la contabilización del Anticipo.', 'stop')
	RETURN 0
END IF
IF fecha_bloqueada(vg_codcia, MONTH(fecha), YEAR(fecha)) THEN
	CALL fl_mostrar_mensaje('No puede generar contabilización del Anticipo de un mes bloqueado en CONTABILIDAD.', 'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION fecha_bloqueada(codcia, mes, ano)
DEFINE codcia 		LIKE ctbt006.b06_compania
DEFINE mes, ano		SMALLINT
DEFINE r_b06		RECORD LIKE ctbt006.*

INITIALIZE r_b06.* TO NULL 
SELECT * INTO r_b06.*
	FROM ctbt006
	WHERE b06_compania = codcia
	  AND b06_ano      = ano
	  AND b06_mes      = mes
IF r_b06.b06_mes IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Mes contable esta bloqueado.','stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION lee_cheque(r_b12)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE glosa		LIKE ctbt012.b12_glosa

OPEN WINDOW w_rolf214_6 AT 09, 12 WITH FORM "../forms/rolf214_6" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME r_b12.b12_num_cheque, r_b12.b12_glosa
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD b12_glosa
		LET glosa = r_b12.b12_glosa
	AFTER FIELD b12_glosa
		IF r_b12.b12_glosa IS NULL THEN
			LET r_b12.b12_glosa = glosa
			DISPLAY BY NAME r_b12.b12_glosa
		END IF
	AFTER FIELD b12_num_cheque
		IF r_b12.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
	AFTER INPUT
		IF r_b12.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
END INPUT
CLOSE WINDOW w_rolf214_6
RETURN r_b12.b12_num_cheque, r_b12.b12_glosa

END FUNCTION



FUNCTION generar_detalle_contable(r_b12, cuenta, valor, tipo, sec, flag_bco,
					flag)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		LIKE ctbt013.b13_valor_base
DEFINE tipo		CHAR(1)
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE flag_bco		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_b13		RECORD LIKE ctbt013.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = sec
IF flag_bco THEN
	IF rm_n45.n45_tipo_pago <> 'E' THEN
		CALL fl_lee_banco_compania(vg_codcia, rm_n45.n45_bco_empresa,
						rm_n45.n45_cta_empresa)
			RETURNING r_g09.*
		IF rm_n45.n45_val_prest > 0 AND flag = 'S' THEN
			LET cuenta = r_g09.g09_aux_cont
		END IF
	END IF
	IF rm_n45.n45_val_prest > 0 THEN
		CASE rm_n45.n45_tipo_pago
			WHEN 'C' IF flag = 'S' THEN
					LET r_b13.b13_tipo_doc = 'CHE'
				 END IF
			WHEN 'T' --LET r_b13.b13_tipo_doc = 'DEP'
		END CASE
	END IF
END IF
LET r_b13.b13_cuenta      = cuenta
LET r_b13.b13_glosa       = 'LIQ.ANT.EMP. ',
				rm_n45.n45_cod_trab USING "<<<&&", ' AN-',
				rm_n45.n45_num_prest USING "<<<&&",
				' RUBRO: ', rm_n45.n45_cod_rubro USING "<<<&&",
				' ', DATE(rm_n45.n45_fecha) USING "dd-mm-yyyy"
LET r_b13.b13_valor_base  = 0
LET r_b13.b13_valor_aux   = 0
CASE tipo
	WHEN 'D'
		LET r_b13.b13_valor_base = valor
	WHEN 'H'
		LET r_b13.b13_valor_base = valor * (-1)
END CASE
LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
INSERT INTO ctbt013 VALUES (r_b13.*)

END FUNCTION



FUNCTION lee_prest_cont(codcia, num_prest)
DEFINE codcia		LIKE rolt059.n59_compania
DEFINE num_prest	LIKE rolt059.n59_num_prest
DEFINE r_n59		RECORD LIKE rolt059.*

INITIALIZE r_n59.* TO NULL
SELECT * INTO r_n59.*
	FROM rolt059
	WHERE n59_compania  = codcia
	  AND n59_num_prest = num_prest
RETURN r_n59.*

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

LET param = ' "', tipo_comp, '" "', num_comp, '"'
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201 ', param)

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET vm_lin_pag = 66
IF vg_codloc = 3 THEN
	LET vm_lin_pag = 44
END IF
START REPORT reporte_anticipos TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT reporte_anticipos(i)
END FOR
FINISH REPORT reporte_anticipos

END FUNCTION



REPORT reporte_anticipos(i)
DEFINE i, j		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(10)
DEFINE label_letras	VARCHAR(130)
DEFINE valor_deuda	DECIMAL(14,2)
DEFINE valor_car	VARCHAR(20)
DEFINE tot_da		SMALLINT
DEFINE tot_nd		SMALLINT
DEFINE tot_val_d	DECIMAL(14,2)
DEFINE tot_sal_d	DECIMAL(14,2)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	4
	PAGE LENGTH	vm_lin_pag

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	CALL fl_justifica_titulo('C', "ANTICIPOS A TRABAJADORES", 40)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 012, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 016, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_12cpi
	SKIP 1 LINES
	CALL fl_lee_trabajador_roles(rm_n45.n45_compania, rm_n45.n45_cod_trab)
		RETURNING r_n30.*
	CALL fl_lee_rubro_roles(rm_n45.n45_cod_rubro) RETURNING r_n06.*
	CALL fl_lee_moneda(r_n30.n30_mon_sueldo) RETURNING r_g13.*
	CALL fl_justifica_titulo('I', rm_n45.n45_usuario, 10) RETURNING usuario
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO    : ', r_g50.g50_nombre[1, 19] CLIPPED
	LET valor_deuda = rm_n45.n45_val_prest + rm_n45.n45_sal_prest_ant
				+ rm_n45.n45_valor_int - rm_n45.n45_descontado
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 089, 'PAG. ', PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, 'ANTICIPO  : ', rm_n45.n45_num_prest USING "<<<<&&",
	      COLUMN 025, 'RUBRO: ', rm_n45.n45_cod_rubro USING "&&", ' ',
		r_n06.n06_nombre_abr CLIPPED;
	IF rm_n45.n45_prest_tran IS NOT NULL THEN
		PRINT COLUMN 052, 'ESTADO: ', rm_n45.n45_estado, ' ',
			retorna_estado(rm_n45.n45_estado) CLIPPED,
		      COLUMN 078, 'ANT. TRANS.: ',
			rm_n45.n45_prest_tran USING "<<<<&&"
	ELSE
		PRINT COLUMN 059, 'ESTADO           : ', rm_n45.n45_estado, ' ',
			retorna_estado(rm_n45.n45_estado) CLIPPED
	END IF
	PRINT COLUMN 001, 'EMPLEADO  : ', rm_n45.n45_cod_trab USING "<<<&&&",
		' ', r_n30.n30_nombres[1, 35] CLIPPED,
	      COLUMN 059, 'USUARIO          : ', usuario
	LET valor_car = rm_n45.n45_val_prest USING "---,---,--&.##"
	CALL fl_justifica_titulo('I', valor_car, 14) RETURNING valor_car
	PRINT COLUMN 001, 'MONEDA    : ', rm_n45.n45_moneda CLIPPED, ' ',
		r_g13.g13_nombre CLIPPED,
	      COLUMN 059, 'VALOR ANTICIPO   : ', valor_car
	LET valor_car = rm_n45.n45_paridad USING "--,---,--&.#########"
	CALL fl_justifica_titulo('I', valor_car, 19) RETURNING valor_car
	PRINT COLUMN 001, 'PARIDAD   : ', valor_car;
	IF rm_n45.n45_sal_prest_ant > 0 THEN
		LET valor_car = rm_n45.n45_sal_prest_ant USING "---,---,--&.##"
		CALL fl_justifica_titulo('I', valor_car, 14) RETURNING valor_car
		PRINT COLUMN 059, 'SALDO ANT. PREST.: ', valor_car
	ELSE
		PRINT COLUMN 059, ' '
	END IF
	LET valor_car = rm_n45.n45_descontado USING "---,---,--&.##"
	CALL fl_justifica_titulo('I', valor_car, 14) RETURNING valor_car
	PRINT COLUMN 001, 'REFERENCIA: ', rm_n45.n45_referencia CLIPPED,
	      COLUMN 059, 'DESCONTADO       : ', valor_car
	LET valor_car = valor_deuda USING "---,---,--&.##"
	CALL fl_justifica_titulo('I', valor_car, 14) RETURNING valor_car
	PRINT COLUMN 001, 'FECHA     : ', DATE(rm_n45.n45_fecha)
		USING "dd-mm-yyyy", 1 SPACES,
		EXTEND(rm_n45.n45_fecha, HOUR TO SECOND),
	      COLUMN 059, 'VALOR ACTUAL     : ', valor_car
	IF rm_n45.n45_fec_elimi IS NOT NULL THEN
		PRINT COLUMN 001, 'FECHA ELI.: ', DATE(rm_n45.n45_fec_elimi)
			USING "dd-mm-yyyy", 1 SPACES,
			EXTEND(rm_n45.n45_fec_elimi, HOUR TO SECOND);
	ELSE
		PRINT COLUMN 001, ' ';
	END IF
	PRINT COLUMN 059, 'FECHA IMPRESION  : ', DATE(TODAY) USING "dd-mm-yyyy",
		1 SPACES, TIME
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'DIV.',
	      COLUMN 007, 'LQ',
	      COLUMN 011, '        NOMBRE PROCESO',
	      COLUMN 045, 'FECHA INI.',
	      COLUMN 057, 'FECHA FIN.',
	      COLUMN 069, ' VALOR DIVID.',
	      COLUMN 084, ' SALDO ACTUAL'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	CALL fl_lee_proceso_roles(rm_detalle[i].n46_cod_liqrol)
		RETURNING r_n03.*
	PRINT COLUMN 001, rm_detalle[i].n46_secuencia	USING "<<&&",
	      COLUMN 007, rm_detalle[i].n46_cod_liqrol	CLIPPED,
	      COLUMN 011, r_n03.n03_nombre		CLIPPED,
	      COLUMN 045, rm_detalle[i].n46_fecha_ini	USING "dd-mm-yyyy",
	      COLUMN 057, rm_detalle[i].n46_fecha_fin	USING "dd-mm-yyyy",
	      COLUMN 069, rm_detalle[i].n46_valor	USING "--,---,--&.##",
	      COLUMN 084, rm_detalle[i].n46_saldo	USING "--,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 069, '-------------',
	      COLUMN 084, '-------------'
	PRINT COLUMN 056, 'TOTALES ==>  ',
	      COLUMN 069, SUM(rm_detalle[i].n46_valor)	USING "--,---,--&.##",
	      COLUMN 084, SUM(rm_detalle[i].n46_saldo)	USING "--,---,--&.##"
	NEED 20 LINES
	SKIP 2 LINES
	PRINT COLUMN 005, 'RESUMEN POR PROCESO:'
	PRINT COLUMN 005, '===================='
	SKIP 1 LINES
	PRINT COLUMN 007, 'LQ',
	      COLUMN 011, '   NOMBRE PROCESO',
	      COLUMN 033, 'DA',
	      COLUMN 037, 'TD',
	      COLUMN 041, ' VALOR DIVID.',
	      COLUMN 056, 'TOTAL X PROC.',
	      COLUMN 070, 'SALDO X PROC.'
	PRINT COLUMN 007, '----------------------------------------------------------------------------'
	LET tot_da    = 0
	LET tot_nd    = 0
	LET tot_val_d = 0
	LET tot_sal_d = 0
	LET vm_num_dettot = 0
	CALL cargar_dettotpre(2)
	FOR j = 1 TO vm_num_dettot
		PRINT COLUMN 007, rm_dettotpre[j].n58_proceso	CLIPPED,
		      COLUMN 011, rm_dettotpre[j].n03_nombre[1, 20] CLIPPED,
		      COLUMN 033, rm_dettotpre[j].n58_div_act	USING "&&",
		      COLUMN 037, rm_dettotpre[j].n58_num_div	USING "&&",
		      COLUMN 041, rm_dettotpre[j].n58_valor_div
							USING "--,---,--&.##",
		      COLUMN 056, rm_dettotpre[j].n58_valor_dist
							USING "--,---,--&.##",
		      COLUMN 070, rm_dettotpre[j].n58_saldo_dist
							USING "--,---,--&.##"
		LET tot_da    = tot_da    + rm_dettotpre[j].n58_div_act
		LET tot_nd    = tot_nd    + rm_dettotpre[j].n58_num_div
		LET tot_val_d = tot_val_d + rm_dettotpre[j].n58_valor_dist
		LET tot_sal_d = tot_sal_d + rm_dettotpre[j].n58_saldo_dist
	END FOR
	PRINT COLUMN 033, '--',
	      COLUMN 037, '--',
	      COLUMN 056, '-------------',
	      COLUMN 070, '-------------'
	PRINT COLUMN 020, 'TOTALES ==>  ',
	      COLUMN 033, tot_da			USING "&&",
	      COLUMN 037, tot_nd			USING "&&",
	      COLUMN 056, tot_val_d			USING "--,---,--&.##",
	      COLUMN 070, tot_sal_d			USING "--,---,--&.##"

PAGE TRAILER
	SKIP 3 LINES
	PRINT COLUMN 003, '..............................',
	      COLUMN 060, '..............................'
	PRINT COLUMN 003, '     Firma del Trabajador     ',
	      COLUMN 060, '     Firma de Autorizacion    ';
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE rolt045.n45_estado
DEFINE nom_estado	VARCHAR(15)

CASE estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
	WHEN 'T' LET nom_estado = 'TRANSFERIDO'
	WHEN 'R' LET nom_estado = 'REDISTRIBUIDO'
	WHEN 'E' LET nom_estado = 'ELIMINADO'
END CASE
RETURN nom_estado

END FUNCTION



FUNCTION generar_archivo()
DEFINE query 		CHAR(6000)
DEFINE archivo		VARCHAR(100)
DEFINE comando		VARCHAR(100)
DEFINE mensaje		VARCHAR(200)
DEFINE nom_mes		VARCHAR(10)
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE r_n59		RECORD LIKE rolt059.*

INITIALIZE r_n59.* TO NULL
SELECT * INTO r_n59.*
	FROM rolt059
	WHERE n59_compania  = rm_n45.n45_compania
	  AND n59_num_prest = rm_n45.n45_num_prest
IF r_n59.n59_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No puede generar archivo de pago al banco de un anticipo no contabilizado.', 'exclamation')
	RETURN
END IF
LET nom_mes = UPSHIFT(fl_justifica_titulo('I',
			fl_retorna_nombre_mes(MONTH(rm_n45.n45_fecha)), 11))
LET archivo = "ANT_", rm_n45.n45_num_prest USING "<<<<<&", "_",
		DAY(rm_n45.n45_fecha) USING "&&", "-", nom_mes[1, 3] CLIPPED,
		YEAR(rm_n45.n45_fecha) USING "####", "_"
CALL fl_lee_ciudad(rm_g02.g02_ciudad) RETURNING r_g31.*
LET archivo = archivo CLIPPED, r_g31.g31_siglas CLIPPED, ".txt"
LET comando = "ls -1 $HOME/tmp/", archivo CLIPPED, " > ../../../tmp/arch_anti"
RUN comando
CREATE TEMP TABLE t1 (nom_arch VARCHAR(100))
LOAD FROM "../../../tmp/arch_anti" INSERT INTO t1
DECLARE q_t1 CURSOR FOR SELECT * FROM t1
OPEN q_t1
FETCH q_t1 INTO comando
CLOSE q_t1
FREE q_t1
DROP TABLE t1
LET comando = comando[18, 100] CLIPPED
IF archivo = comando THEN
	LET comando = "rm -rf ../../../tmp/arch_anti"
	RUN comando
	CALL fl_mostrar_mensaje('A este anticipo, ya se le generó el archivo de pago al banco.', 'exclamation')
	RETURN
END IF
LET comando = "rm -rf ../../../tmp/arch_anti"
RUN comando
CREATE TEMP TABLE tmp_rol_ban
	(
		tipo_pago		CHAR(2),
		cuenta_empresa		CHAR(11),
		secuencia		SERIAL,
		comp_pago		CHAR(5),
		cod_trab		CHAR(6),
		moneda			CHAR(3),
		valor			VARCHAR(13),
		forma_pago		CHAR(3),
		codi_banco		CHAR(4),
		tipo_cuenta		CHAR(3),
		cuenta_empleado		CHAR(11),
		tipo_doc_id		CHAR(1),
		num_doc_id		VARCHAR(13),
		empleado		VARCHAR(40),
		direccion		VARCHAR(40),
		ciudad			VARCHAR(20),
		telefono		VARCHAR(10),
		local_cobro		VARCHAR(10),
		referencia		VARCHAR(30),
		referencia_adic		VARCHAR(30)
	)

LET query = 'SELECT "PA" AS tip_pag, g09_numero_cta AS cuenta_empr,',
			' 0 AS secu, "" AS comp_p, n45_cod_trab AS cod_emp,',
			' g13_simbolo AS mone, TRUNC(n45_val_prest * 100,0) AS',
			' neto_rec, "CTA" AS for_pag, "0036" AS cod_ban,',
			' CASE WHEN n30_tipo_cta_tra = "A"',
				' THEN "AHO"',
				' ELSE "CTE"',
			' END AS tipo_c, n45_cta_trabaj AS cuenta_empl,',
			' n30_tipo_doc_id AS tipo_id,',
			' CASE WHEN n45_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "0920503067"',
				' ELSE n30_num_doc_id',
			' END AS cedula,',
			' CASE WHEN n45_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "CHILA RUA EMILIANO FRANCISCO"',
				' ELSE n30_nombres',
			' END AS empleados, n30_domicilio AS direc,',
			' g31_nombre AS ciudad_emp, n30_telef_domic AS fono,',
			' "" AS loc_cob, n03_nombre AS refer1,',
			' CASE',
				' WHEN MONTH(n45_fecha) = 01 THEN "ENERO"',
				' WHEN MONTH(n45_fecha) = 02 THEN "FEBRERO"',
				' WHEN MONTH(n45_fecha) = 03 THEN "MARZO"',
				' WHEN MONTH(n45_fecha) = 04 THEN "ABRIL"',
				' WHEN MONTH(n45_fecha) = 05 THEN "MAYO"',
				' WHEN MONTH(n45_fecha) = 06 THEN "JUNIO"',
				' WHEN MONTH(n45_fecha) = 07 THEN "JULIO"',
				' WHEN MONTH(n45_fecha) = 08 THEN "AGOSTO"',
				' WHEN MONTH(n45_fecha) = 09 THEN "SEPTIEMBRE"',
				' WHEN MONTH(n45_fecha) = 10 THEN "OCTUBRE"',
				' WHEN MONTH(n45_fecha) = 11 THEN "NOVIEMBRE"',
				' WHEN MONTH(n45_fecha) = 12 THEN "DICIEMBRE"',
			' END || "-" || LPAD(YEAR(n45_fecha), 4, 0) AS refer2',
		' FROM rolt045, rolt030, gent009, gent013, gent031,',
			' rolt003 ',
		' WHERE n45_compania   = ', vg_codcia,
		'   AND n45_num_prest  = ', rm_n45.n45_num_prest,
		'   AND n45_estado    IN ("A", "R")',
		'   AND n45_val_prest  > 0 ',
  		'   AND n30_compania   = n45_compania ',
		'   AND n30_cod_trab   = n45_cod_trab ',
		'   AND g09_compania   = n45_compania ',
		'   AND g09_banco      = n45_bco_empresa ',
		'   AND g09_numero_cta = n45_cta_empresa ',
		'   AND n03_proceso    = "', vm_proceso, '"',
		'   AND g13_moneda     = n45_moneda ',
		'   AND g31_ciudad     = n30_ciudad_nac ',
		' ORDER BY 14 ',
		' INTO TEMP t1 '
PREPARE exec_dat FROM query
EXECUTE exec_dat
LET query = 'INSERT INTO tmp_rol_ban ',
		'(tipo_pago, cuenta_empresa, secuencia, comp_pago, cod_trab,',
		' moneda, valor, forma_pago, codi_banco, tipo_cuenta,',
		' cuenta_empleado, tipo_doc_id, num_doc_id, empleado,',
		' direccion, ciudad, telefono, local_cobro, referencia,',
		' referencia_adic) ',
		' SELECT * FROM t1 '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DROP TABLE t1
LET query = 'SELECT tipo_pago, cuenta_empresa, secuencia, comp_pago, cod_trab,',
		' "USD" moneda, LPAD(valor, 13, 0) valor, forma_pago,',
		' codi_banco, tipo_cuenta,',
		' LPAD(cuenta_empleado, 11, 0) cta_emp, tipo_doc_id,',
		' LPAD(num_doc_id, 13, 0) num_doc_id,',
		' REPLACE(empleado, "ñ", "N") empleado,',
		' "" direccion, "" ciudad, "" telefono, "" local_cobro,',
		' "ROL DE PAGO" referencia, referencia_adic',
		' FROM tmp_rol_ban ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_rol_ban
UNLOAD TO "../../../tmp/ant_emp.txt" DELIMITER "	"
	SELECT * FROM t1
		ORDER BY secuencia
LET mensaje = 'Archivo ', archivo CLIPPED, ' Generado ', FGL_GETENV("HOME"),
		'/tmp/  OK'
LET archivo = "mv ../../../tmp/ant_emp.txt $HOME/tmp/", archivo CLIPPED
RUN archivo
DROP TABLE t1
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION 

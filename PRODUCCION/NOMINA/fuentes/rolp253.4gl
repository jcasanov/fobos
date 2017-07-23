-------------------------------------------------------------------------------
-- Titulo               : rolp253.4gl -- Anticipos de Vacaciones
-- Elaboración          : 27-Mar-2007
-- Autor                : NPC
-- Formato de Ejecución : fglrun rolp253 Base Modulo Compañía
--			[cod_trab] [proc_vac] [periodo_ini] [periodo_fin]
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n03		RECORD LIKE rolt003.*
DEFINE rm_n05		RECORD LIKE rolt005.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_n91   	RECORD LIKE rolt091.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_proceso	LIKE rolt039.n39_proceso
DEFINE vm_vac_goz	LIKE rolt039.n39_proceso
DEFINE vm_vac_pag	LIKE rolt039.n39_proceso



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp253.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 7 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp253'
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
LET vm_proceso = 'AV'
CALL fl_lee_proceso_roles(vm_proceso) RETURNING rm_n03.*
IF rm_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso ANTICIPO VACACIONES en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF
LET vm_vac_goz = 'VA'
CALL fl_lee_proceso_roles(vm_vac_goz) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso VACACIONES en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF
LET vm_vac_pag = 'VP'
CALL fl_lee_proceso_roles(vm_vac_pag) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso VACACIONES PAGADAS en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*
IF num_args() = 3 THEN
	IF rm_n05.n05_proceso <> vm_vac_goz THEN
		CALL fl_mostrar_mensaje('No puede ejecutar este proceso mientras exista otro proceso de Nomina Activo.', 'stop')
		EXIT PROGRAM
	END IF
	IF rm_n05.n05_proceso <> vm_vac_pag THEN
		CALL fl_mostrar_mensaje('No puede ejecutar este proceso mientras exista otro proceso de Nomina Activo.', 'stop')
		--EXIT PROGRAM
	END IF
END IF
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en CONTABILIDAD.', 'stop')
	EXIT PROGRAM
END IF
LET vm_max_rows = 1000
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 22
LET num_cols    = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf253_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf253_1 FROM '../forms/rolf253_1'
ELSE
	OPEN FORM f_rolf253_1 FROM '../forms/rolf253_1c'
END IF
DISPLAY FORM f_rolf253_1
INITIALIZE rm_n91.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Contabilización'
		HIDE OPTION 'Detalle Tot. Gan.'
		HIDE OPTION 'Imprimir'
		IF num_args() <> 3 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Detalle Tot. Gan.'
			SHOW OPTION 'Imprimir'
			CALL control_consulta()
			IF vm_num_rows > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
			IF vm_num_rows = 0 THEN
				EXIT PROGRAM
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Detalle Tot. Gan.'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Detalle Tot. Gan.'
			SHOW OPTION 'Imprimir'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Contabilización'
				HIDE OPTION 'Detalle Tot. Gan.'
				HIDE OPTION 'Imprimir'
			END IF
		ELSE
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Detalle Tot. Gan.'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('B') 'Contabilización' 'Ver diario contable.'
		CALL ver_contabilizacion()
	COMMAND KEY('T') 'Detalle Tot. Gan.' 'Ver total ganado por liq.'
		CALL ver_tot_gan_liq()
	COMMAND KEY('P') 'Imprimir' 'Imprime el comprobante.'
		CALL control_imprimir()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL lee_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL lee_anterior_registro()
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
LET int_flag = 0
CLOSE WINDOW w_rolf253_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE num_aux		INTEGER
DEFINE resp		CHAR(6)

CLEAR FORM
INITIALIZE rm_n91.* TO NULL
LET rm_n91.n91_compania   = vg_codcia
LET rm_n91.n91_proceso    = vm_proceso
LET rm_n91.n91_fecha_ant  = TODAY
LET rm_n91.n91_prov_aport = 'S'
LET rm_n91.n91_tipo_pago  = 'C'
LET rm_n91.n91_fecing     = CURRENT
LET rm_n91.n91_usuario    = vg_usuario
DISPLAY BY NAME rm_n91.n91_proceso, rm_n03.n03_nombre, rm_n91.n91_fecha_ant,
		rm_n91.n91_fecing, rm_n91.n91_usuario
BEGIN WORK
	CALL lee_datos()
	IF int_flag THEN
		ROLLBACK WORK
		CLEAR FORM
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		END IF
		RETURN
	END IF
	SELECT NVL(MAX(n91_num_ant) + 1, 1) INTO rm_n91.n91_num_ant
		FROM rolt091
		WHERE n91_compania = rm_n91.n91_compania
		  AND n91_proceso  = rm_n91.n91_proceso
		  AND n91_cod_trab = rm_n91.n91_cod_trab
	IF rm_n91.n91_num_ant IS NULL THEN
		LET rm_n91.n91_num_ant = 1
	END IF
	LET rm_n91.n91_fecing = CURRENT
	INSERT INTO rolt091 VALUES (rm_n91.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	IF rm_n90.n90_gen_cont_vac = 'S' THEN
		WHENEVER ERROR CONTINUE
		CALL generar_contabilizacion() RETURNING r_b12.*
		IF r_b12.b12_compania IS NULL THEN
			WHENEVER ERROR STOP
			ROLLBACK WORK
			CLEAR FORM
			IF vm_num_rows > 0 THEN
				CALL lee_muestra_registro(
						vm_r_rows[vm_row_current])
			END IF
			RETURN
		END IF
		WHENEVER ERROR STOP
	END IF
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = num_aux
LET vm_row_current         = vm_num_rows
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
IF rm_n90.n90_gen_cont_vac = 'S' THEN
	IF r_b12.b12_compania IS NOT NULL AND rm_b00.b00_mayo_online = 'S' THEN
		CALL fl_mayoriza_comprobante(r_b12.b12_compania,
				r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'M')
	END IF
	CALL fl_hacer_pregunta('Desea ver contabilización generada ?', 'Yes')
		RETURNING resp
	IF resp = 'Yes' THEN
		CALL ver_contabilizacion()
	END IF
END IF
CALL control_imprimir()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1200)
DEFINE query		CHAR(2000)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n91		RECORD LIKE rolt091.*

CLEAR FORM
LET int_flag = 0
IF num_args() = 3 THEN
	CONSTRUCT BY NAME expr_sql ON n91_cod_trab, n91_num_ant, n91_fecha_ant,
	n91_motivo_ant, n91_prov_aport, n91_tipo_pago, n91_valor_gan,
	n91_val_vac_par, n91_bco_empresa, n91_val_pro_apor, n91_cta_empresa,
	n91_cta_trabaj, n91_saldo_pend, n91_valor_tope, n91_proc_vac,
	n91_periodo_ini, n91_periodo_fin, n91_tipo_comp, n91_num_comp,
	n91_valor_ant, n91_usuario, n91_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT PROGRAM
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n91_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n91.n91_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n91.n91_cod_trab,
						r_n30.n30_nombres
                        END IF
                END IF
		IF INFIELD(n91_num_ant) THEN
                        CALL fl_ayuda_proceso_adic_rol(vg_codcia, vm_proceso)
                                RETURNING r_n91.n91_num_ant
                        IF r_n91.n91_num_ant IS NOT NULL THEN
                                LET rm_n91.n91_num_ant = r_n91.n91_num_ant
                                DISPLAY BY NAME rm_n91.n91_num_ant
                        END IF
                END IF
		IF INFIELD(n91_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'T')
                                RETURNING r_g08.g08_banco, r_g08.g08_nombre,
					r_g09.g09_tipo_cta, r_g09.g09_numero_cta
                        IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_n91.n91_bco_empresa = r_g08.g08_banco
				LET rm_n91.n91_cta_empresa =r_g09.g09_numero_cta
                                DISPLAY BY NAME rm_n91.n91_bco_empresa,
						r_g08.g08_nombre,
						rm_n91.n91_cta_empresa
                        END IF
                END IF
		IF INFIELD(n91_cta_trabaj) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n91.n91_cta_trabaj = r_b10.b10_cuenta
				DISPLAY BY NAME rm_n91.n91_cta_trabaj
			END IF
		END IF
                LET int_flag = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		IF vm_num_rows >0 THEN
			CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'n91_cod_trab    = ', arg_val(4),
			'   AND n91_proc_vac    = "', arg_val(5), '"',
			'   AND n91_periodo_ini = "', arg_val(6), '"',
			'   AND n91_periodo_fin = "', arg_val(7), '"'
END IF
LET query = 'SELECT *, ROWID FROM rolt091 ',
		' WHERE n91_compania    = ', vg_codcia,
		'   AND n91_proceso     = "', vm_proceso, '"',
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3, 4 '
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_n91.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() <> 3 THEN
		EXIT PROGRAM
	END IF
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE resp      	CHAR(6)
DEFINE resul		SMALLINT
DEFINE fecha		DATE

LET int_flag = 0 
INPUT BY NAME rm_n91.n91_cod_trab, rm_n91.n91_motivo_ant, rm_n91.n91_prov_aport,
	rm_n91.n91_tipo_pago, rm_n91.n91_bco_empresa, rm_n91.n91_cta_empresa,
	rm_n91.n91_cta_trabaj, rm_n91.n91_valor_ant
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n91.n91_cod_trab, rm_n91.n91_motivo_ant,
				 rm_n91.n91_prov_aport, rm_n91.n91_tipo_pago,
				 rm_n91.n91_bco_empresa, rm_n91.n91_cta_empresa,
				 rm_n91.n91_cta_trabaj, rm_n91.n91_valor_ant)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				EXIT INPUT
			END IF
		ELSE
			CLEAR FORM
			EXIT INPUT
		END IF       	
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n91_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n91.n91_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n91.n91_cod_trab,
						r_n30.n30_nombres
                        END IF
                END IF
		IF INFIELD(n91_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
                                RETURNING r_g08.g08_banco, r_g08.g08_nombre,
					r_g09.g09_tipo_cta, r_g09.g09_numero_cta
                        IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_n91.n91_bco_empresa = r_g08.g08_banco
				LET rm_n91.n91_cta_empresa =r_g09.g09_numero_cta
                                DISPLAY BY NAME rm_n91.n91_bco_empresa,
						r_g08.g08_nombre,
						rm_n91.n91_cta_empresa
                        END IF
                END IF
		IF INFIELD(n91_cta_trabaj) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n91.n91_cta_trabaj = r_b10.b10_cuenta
				DISPLAY BY NAME rm_n91.n91_cta_trabaj
			END IF
		END IF
                LET int_flag = 0
	ON KEY(F5)
		CALL ver_tot_gan_liq()
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("F5","Detalle Tot. Gan.")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD n91_cod_trab
		IF rm_n91.n91_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n91.n91_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de este empleado en la Compañía.', 'exclamation')
				NEXT FIELD n91_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n91_cod_trab
			END IF
			IF NOT cargar_datos_anticipo() THEN
				NEXT FIELD n91_cod_trab
			END IF
			CALL datos_tipo_pago(1)
			{--
			IF EXTEND(rm_n91.n91_fecha_ant, YEAR TO MONTH) >=
			   EXTEND(rm_n91.n91_periodo_fin, YEAR TO MONTH)
			THEN
			--}
			IF DAY(rm_n91.n91_periodo_fin) >= 15 THEN
				LET fecha = MDY(MONTH(rm_n91.n91_periodo_fin),
					15, YEAR(rm_n91.n91_periodo_fin))
			ELSE
				LET fecha = MDY(MONTH(rm_n91.n91_periodo_fin),
					01, YEAR(rm_n91.n91_periodo_fin))
					- 1 UNITS DAY
			END IF
			IF fecha_ultima_quincena() >= fecha THEN
				CALL fl_mostrar_mensaje('El periodo de estas vacaciones ya esta completo. Por favor liquide estas vacaciones por el proceso de liquidación del menú.', 'exclamation')
				NEXT FIELD n91_cod_trab
			END IF
		ELSE
			CLEAR n30_nombres
		END IF
	AFTER FIELD n91_prov_aport
		CALL calular_valores()
	AFTER FIELD n91_tipo_pago
		CALL datos_tipo_pago(0)
	AFTER FIELD n91_bco_empresa
                IF rm_n91.n91_bco_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_general(rm_n91.n91_bco_empresa)
                                RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD n91_bco_empresa
			END IF
			DISPLAY BY NAME r_g08.g08_nombre
		ELSE
			CLEAR n91_bco_empresa, g08_nombre, n91_cta_empresa
                END IF
	AFTER FIELD n91_cta_empresa
                IF rm_n91.n91_cta_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_compania(vg_codcia,
					rm_n91.n91_bco_empresa,
					rm_n91.n91_cta_empresa)
                                RETURNING r_g09.*
			IF r_g09.g09_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco o Cuenta Corriente no existe en la compañía.','exclamation')
				NEXT FIELD n91_bco_empresa
			END IF
			LET rm_n91.n91_cta_empresa = r_g09.g09_numero_cta
			DISPLAY BY NAME rm_n91.n91_cta_empresa
                        CALL fl_lee_banco_general(rm_n91.n91_bco_empresa)
                                RETURNING r_g08.*
			DISPLAY BY NAME r_g08.g08_nombre
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n91_bco_empresa
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n91_bco_empresa
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n91_bco_empresa
			END IF
		ELSE
			CLEAR n91_cta_empresa
		END IF
	AFTER FIELD n91_cta_trabaj
		IF rm_n91.n91_tipo_pago <> 'T' THEN
			LET rm_n91.n91_cta_trabaj = NULL
			DISPLAY BY NAME rm_n91.n91_cta_trabaj
			CONTINUE INPUT
		END IF
		IF rm_n91.n91_cta_trabaj IS NOT NULL THEN
			{--
			IF validar_cuenta(rm_n91.n91_cta_trabaj) THEN
				NEXT FIELD n91_cta_trabaj
			END IF
			--}
		ELSE
			CLEAR n91_cta_trabaj
		END IF
	AFTER FIELD n91_valor_ant
		IF rm_n91.n91_valor_ant > rm_n91.n91_valor_tope THEN
			CALL fl_mostrar_mensaje('El valor del anticipo no puede ser mayor que el valor tope.', 'exclamation')
			NEXT FIELD n91_valor_ant
		END IF
	AFTER INPUT
		IF rm_n91.n91_tipo_pago <> 'E' THEN
			IF rm_n91.n91_bco_empresa IS NULL
			OR rm_n91.n91_cta_empresa IS NULL THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de pago Cheque o Transferencia, debe ingresar el Banco y la Cuenta Corriente.', 'exclamation')
				NEXT FIELD n91_bco_empresa
			END IF
		ELSE
			IF rm_n91.n91_bco_empresa IS NULL
			OR rm_n91.n91_cta_empresa IS NULL THEN
				INITIALIZE rm_n91.n91_bco_empresa,
					rm_n91.n91_cta_empresa TO NULL
				CLEAR n91_bco_empresa, n91_cta_empresa,
					g08_nombre
			END IF
		END IF
		IF rm_n91.n91_cta_trabaj IS NULL THEN
			IF rm_n91.n91_tipo_pago = 'T' THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de Pago Transferencia, debe ingresar el Número de Cuenta Contable.', 'exclamation')
				NEXT FIELD n91_cta_trabaj
			END IF
		END IF
		IF rm_n91.n91_tipo_pago = 'T' THEN
			IF rm_n91.n91_cta_trabaj IS NOT NULL THEN
				{--
				IF validar_cuenta(rm_n91.n91_cta_trabaj) THEN
					NEXT FIELD n91_cta_trabaj
				END IF
				--}
			END IF
		END IF
		IF rm_n91.n91_valor_ant > rm_n91.n91_valor_tope THEN
			CALL fl_mostrar_mensaje('El valor del anticipo no puede ser mayor que el valor tope.', 'exclamation')
			NEXT FIELD n91_valor_ant
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_datos_anticipo()

LET rm_n91.n91_valor_gan    = NULL
LET rm_n91.n91_val_vac_par  = NULL
LET rm_n91.n91_val_pro_apor = NULL
LET rm_n91.n91_saldo_pend   = NULL
LET rm_n91.n91_valor_tope   = NULL
LET rm_n91.n91_proc_vac     = NULL
LET rm_n91.n91_periodo_ini  = NULL
LET rm_n91.n91_periodo_fin  = NULL
IF NOT preparar_empleados_pendientes() THEN
	CALL mostrar_datos_anticipo()
	CALL fl_mostrar_mensaje('No se puede calcular el anticipo para este empleado, debido a que ya tiene en proceso las vacaciones actuales ó tiene mas de una vacación pendiente de pago.', 'exclamation')
	RETURN 0
END IF
SELECT p_ini, p_fin, valor_gan, v_vac
	INTO rm_n91.n91_periodo_ini, rm_n91.n91_periodo_fin,
		rm_n91.n91_valor_gan, rm_n91.n91_val_vac_par
	FROM tmp_vacaciones
	WHERE cod_t = rm_n91.n91_cod_trab
LET rm_n91.n91_saldo_pend = 0
DROP TABLE tmp_vacaciones
SELECT NVL(SUM(n91_valor_ant), 0) val_ant
	FROM rolt091
	WHERE n91_compania    = rm_n91.n91_compania
	  AND n91_proceso     = rm_n91.n91_proceso
	  AND n91_cod_trab    = rm_n91.n91_cod_trab
	  AND n91_periodo_ini = rm_n91.n91_periodo_ini
	  AND n91_periodo_fin = rm_n91.n91_periodo_fin
UNION
SELECT NVL(SUM(n46_saldo), 0) val_ant
	FROM rolt045, rolt046
	WHERE n45_compania   = vg_codcia
	  AND n45_cod_trab   = rm_n91.n91_cod_trab
	  AND n45_estado     IN ('A', 'R')
	  AND n45_val_prest + n45_valor_int - n45_descontado > 0
	  AND n45_compania   = n46_compania
	  AND n45_num_prest  = n46_num_prest
	  AND n46_cod_liqrol IN (vm_vac_goz, vm_vac_pag)
	  AND n46_fecha_ini  = rm_n91.n91_periodo_ini
	  AND n46_fecha_fin  = rm_n91.n91_periodo_fin
	  AND n46_saldo      > 0
	INTO TEMP t1
SELECT NVL(SUM(val_ant), 0) INTO rm_n91.n91_saldo_pend FROM t1
DROP TABLE t1
LET rm_n91.n91_proc_vac   = vm_vac_goz
{--
LET rm_n91.n91_valor_tope = rm_n91.n91_valor_tope -
			(rm_n91.n91_saldo_pend / (rm_n90.n90_dias_ano_vac /
			rm_n00.n00_dias_vacac))
--}
CALL calular_valores()
IF rm_n91.n91_valor_tope <= 0 THEN
	CALL mostrar_datos_anticipo()
	CALL fl_mostrar_mensaje('Ya no se puede hacer anticipo de este empleado, para este período.', 'exclamation')
	RETURN 0
END IF
CALL mostrar_datos_anticipo()
RETURN 1

END FUNCTION



FUNCTION preparar_empleados_pendientes()
DEFINE fecha_ult	LIKE rolt032.n32_fecha_fin
DEFINE query		CHAR(4000)
DEFINE cuantos		INTEGER

LET query = 'SELECT UNIQUE n32_compania cia, n32_cod_trab cod_trab, ',
			' CASE WHEN YEAR(TODAY) > n32_ano_proceso ',
				' THEN YEAR(TODAY) ',
				' ELSE n32_ano_proceso ',
			' END anio ',
		' FROM rolt032 ',
		' WHERE n32_compania     = ', vg_codcia,
		'   AND n32_cod_liqrol  IN ("Q1", "Q2") ',
		'   AND n32_cod_trab     = ', rm_n91.n91_cod_trab,
		'   AND n32_ano_proceso  > ', rm_n90.n90_anio_ini_vac,
		' INTO TEMP tmp_n32 '
PREPARE exec_n32 FROM query
EXECUTE exec_n32
SELECT COUNT(*) INTO cuantos FROM tmp_n32
IF cuantos = 0 THEN
	DROP TABLE tmp_n32
	RETURN 0
END IF
CALL fecha_ultima_quincena() RETURNING fecha_ult
LET query = 'SELECT n30_compania, n30_cod_trab, n30_nombres,',
		' CASE WHEN EXTEND(n30_fecha_ing, MONTH TO DAY) = "02-29"',
		' THEN MDY(MONTH(n30_fecha_ing), 28, YEAR(n30_fecha_ing))',
		' ELSE n30_fecha_ing',
		' END n30_fecha_ing ',
		' FROM rolt030 ',
		' WHERE n30_compania  = ', vg_codcia,
		'   AND n30_estado    = "A" ',
		'   AND n30_tipo_trab = "N" ',
		' INTO TEMP tmp_n30 '
PREPARE exec_n30 FROM query
EXECUTE exec_n30
LET query = 'SELECT n30_cod_trab cod_t, n30_nombres nom, ',
		'MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),anio - 1) p_ini,',
		'MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), anio)',
				' - 1 UNITS DAY p_fin, ',
		rm_n00.n00_dias_vacac, ' + ',
		'(CASE WHEN (MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),',
				' anio)) ',
			'>= (n30_fecha_ing + (', rm_n00.n00_ano_adi_vac,
			' - 1) UNITS YEAR - 1 UNITS DAY) ',
			'THEN CASE WHEN (', rm_n00.n00_dias_vacac, ' + ',
			'((YEAR(MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), ',
			'anio)) - YEAR(n30_fecha_ing + (',
			rm_n00.n00_ano_adi_vac, ' - 1) UNITS YEAR - ',
			'1 UNITS DAY)) * ', rm_n00.n00_dias_adi_va, ')) > ',
			rm_n00.n00_max_vacac,
			' THEN ', rm_n00.n00_max_vacac, ' - ',
					rm_n00.n00_dias_vacac,
			' ELSE ((YEAR(MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), anio)) - ',
				'YEAR(n30_fecha_ing + (',rm_n00.n00_ano_adi_vac,
				' - 1) UNITS YEAR - 1 UNITS DAY)) * ',
				rm_n00.n00_dias_adi_va, ')',
			' END ',
			'ELSE 0 ',
		'END) d_vac, ',
	'NVL((SELECT SUM(n32_tot_gan) ',
		' FROM rolt032 ',
		' WHERE n32_compania     = n30_compania ',
		'   AND n32_cod_liqrol  IN("Q1", "Q2") ',
		'   AND n32_fecha_ini   >= MDY(MONTH(n30_fecha_ing), ',
			'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
				'AND DAY(n30_fecha_ing) <= 15 ',
				'THEN 1 ELSE 16 END), anio - 1) ',
		'   AND n32_fecha_fin   <= MDY(MONTH(n30_fecha_ing), ',
			'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
				'AND DAY(n30_fecha_ing) <= 15 ',
				'THEN 1 ELSE 16 END), anio) - 1 UNITS DAY ',
		'   AND n32_cod_trab     = n30_cod_trab ',
		'   AND n32_ano_proceso >= ', rm_n90.n90_anio_ini_vac,
		'   AND n32_estado      <> "E"), 0) valor_gan, ',
	'(NVL((SELECT SUM(n32_tot_gan) ',
		' FROM rolt032 ',
		' WHERE n32_compania     = n30_compania ',
		'   AND n32_cod_liqrol  IN("Q1", "Q2") ',
		'   AND n32_fecha_ini   >= MDY(MONTH(n30_fecha_ing), ',
			'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
				'AND DAY(n30_fecha_ing) <= 15 ',
				'THEN 1 ELSE 16 END), anio - 1) ',
		'   AND n32_fecha_fin   <= MDY(MONTH(n30_fecha_ing), ',
			'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
				'AND DAY(n30_fecha_ing) <= 15 ',
				'THEN 1 ELSE 16 END), anio) - 1 UNITS DAY ',
		'   AND n32_cod_trab     = n30_cod_trab ',
		'   AND n32_ano_proceso >= ', rm_n90.n90_anio_ini_vac,
		'   AND n32_estado      <> "E"), 0) / (',
			rm_n90.n90_dias_ano_vac, ' / ', rm_n00.n00_dias_vacac,
			') ',
		'+ ((NVL((SELECT SUM(n32_tot_gan) ',
			' FROM rolt032 ',
			' WHERE n32_compania     = n30_compania ',
			'   AND n32_cod_liqrol  IN("Q1", "Q2") ',
			'   AND n32_fecha_ini   >= MDY(MONTH(n30_fecha_ing), ',
				'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
					'AND DAY(n30_fecha_ing) <= 15 ',
					'THEN 1 ELSE 16 END), anio - 1) ',
			'   AND n32_fecha_fin   <= MDY(MONTH(n30_fecha_ing), ',
				'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
					'AND DAY(n30_fecha_ing) <= 15 ',
					'THEN 1 ELSE 16 END), anio) - 1 ',
					'UNITS DAY ',
			'   AND n32_cod_trab     = n30_cod_trab ',
			'   AND n32_ano_proceso >= ', rm_n90.n90_anio_ini_vac,
			'   AND n32_estado      <> "E"), 0) / (',
		rm_n90.n90_dias_ano_vac, ' / ', rm_n00.n00_dias_vacac,
			')) / ', rm_n00.n00_dias_vacac, ') * ',
	'(CASE WHEN (MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), anio)) ',
		'>= (n30_fecha_ing + (', rm_n00.n00_ano_adi_vac,
			' - 1) UNITS YEAR - 1 UNITS DAY) ',
		'THEN CASE WHEN (', rm_n00.n00_dias_vacac, ' + ',
			'((YEAR(MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), ',
			'anio)) - YEAR(n30_fecha_ing + (',
			rm_n00.n00_ano_adi_vac,	'- 1) UNITS YEAR - ',
			'1 UNITS DAY)) * ', rm_n00.n00_dias_adi_va, ')) > ',
			rm_n00.n00_max_vacac,
			' THEN ', rm_n00.n00_max_vacac, ' - ',
					rm_n00.n00_dias_vacac,
			' ELSE ((YEAR(MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), anio)) - ',
				'YEAR(n30_fecha_ing + (',rm_n00.n00_ano_adi_vac,
				' - 1) UNITS YEAR - 1 UNITS DAY)) * ',
				rm_n00.n00_dias_adi_va, ')',
			' END ',
		' ELSE 0 ',
		' END)) v_vac ',
	' FROM tmp_n32, tmp_n30 ',
	' WHERE n30_compania  = cia ',
	'   AND n30_cod_trab  = cod_trab ',
	'   AND NOT EXISTS ',
		'(SELECT * FROM rolt039 ',
		'WHERE n39_compania     = n30_compania ',
		'  AND n39_proceso     IN ("', vm_vac_goz, '", "',
						vm_vac_pag, '")',
		'  AND n39_cod_trab     = n30_cod_trab ',
		'  AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing), ',
						'DAY(n30_fecha_ing), anio - 1)',
		'  AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), anio) - 1 UNITS DAY) ',
	' INTO TEMP tmp_pend '
PREPARE exec_pend FROM query
EXECUTE exec_pend
DELETE FROM tmp_pend WHERE v_vac <= 0
SELECT COUNT(*) INTO cuantos FROM tmp_pend
IF cuantos = 0 THEN
	DROP TABLE tmp_n32
	DROP TABLE tmp_n30
	DROP TABLE tmp_pend
	RETURN 0
END IF
DELETE FROM tmp_pend WHERE v_vac <= 0
LET query = 'INSERT INTO tmp_pend ',
		' SELECT n30_cod_trab cod_t, n30_nombres nom, n39_periodo_ini',
			' p_ini, n39_periodo_fin p_fin, ',
			'(n39_dias_vac + n39_dias_adi) d_vac, ',
			'n39_tot_ganado valor_gan, ',
			'(n39_valor_vaca + n39_valor_adic) v_vac ',
		' FROM tmp_n32, tmp_n30, rolt039 ',
		' WHERE n30_compania     = cia ',
		'   AND n30_cod_trab     = cod_trab ',
		'   AND n39_compania     = n30_compania ',
		'   AND n39_proceso     IN ("', vm_vac_goz, '", "',
						vm_vac_pag, '")',
		'   AND n39_cod_trab     = n30_cod_trab ',
		'   AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing), ',
		 				'DAY(n30_fecha_ing), anio - 1)',
		'   AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), anio) - 1 UNITS DAY ',
		'   AND n39_estado       = "A" '
PREPARE exec_pend2 FROM query
EXECUTE exec_pend2
DROP TABLE tmp_n30
DROP TABLE tmp_n32
SELECT * FROM tmp_pend INTO TEMP tmp_vacaciones
DROP TABLE tmp_pend
SELECT COUNT(*) INTO cuantos FROM tmp_vacaciones
IF cuantos > 1 THEN
	DROP TABLE tmp_vacaciones
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION datos_tipo_pago(flag)
DEFINE flag		SMALLINT
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_n30		RECORD LIKE rolt030.*

CALL fl_lee_trabajador_roles(rm_n91.n91_compania, rm_n91.n91_cod_trab)
	RETURNING r_n30.*
IF flag THEN
	LET rm_n91.n91_tipo_pago = r_n30.n30_tipo_pago
END IF
CASE rm_n91.n91_tipo_pago
	WHEN 'E'
		LET rm_n91.n91_bco_empresa = NULL
		LET rm_n91.n91_cta_empresa = NULL
		LET rm_n91.n91_cta_trabaj  = NULL
	WHEN 'C'
		LET rm_n91.n91_bco_empresa = r_n30.n30_bco_empresa
		LET rm_n91.n91_cta_empresa = r_n30.n30_cta_empresa
		LET rm_n91.n91_cta_trabaj  = NULL
	WHEN 'T'
		LET rm_n91.n91_bco_empresa = r_n30.n30_bco_empresa
		LET rm_n91.n91_cta_empresa = r_n30.n30_cta_empresa
		LET rm_n91.n91_cta_trabaj  = r_n30.n30_cta_trabaj
END CASE
CALL fl_lee_banco_general(rm_n91.n91_bco_empresa) RETURNING r_g08.*
DISPLAY BY NAME rm_n91.n91_tipo_pago, rm_n91.n91_bco_empresa, r_g08.g08_nombre,
		rm_n91.n91_cta_empresa, rm_n91.n91_cta_trabaj

END FUNCTION



FUNCTION calular_valores()

CALL calcular_iess() RETURNING rm_n91.n91_val_pro_apor
LET rm_n91.n91_valor_tope = rm_n91.n91_val_vac_par - rm_n91.n91_val_pro_apor -
				rm_n91.n91_saldo_pend
DISPLAY BY NAME rm_n91.n91_val_pro_apor, rm_n91.n91_valor_tope

END FUNCTION



FUNCTION calcular_iess()
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE val_apor		LIKE rolt091.n91_val_pro_apor

LET val_apor = 0
IF rm_n91.n91_prov_aport = 'N' THEN
	RETURN val_apor
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n91.n91_cod_trab) RETURNING r_n30.*
CALL fl_lee_seguros(r_n30.n30_cod_seguro) RETURNING r_n13.*
LET val_apor = (rm_n91.n91_val_vac_par * r_n13.n13_porc_trab) / 100
RETURN val_apor

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



FUNCTION mostrar_datos_anticipo()

DISPLAY BY NAME rm_n91.n91_valor_gan, rm_n91.n91_val_vac_par,
		rm_n91.n91_val_pro_apor, rm_n91.n91_saldo_pend,
		rm_n91.n91_valor_tope, rm_n91.n91_proc_vac,
		rm_n91.n91_periodo_ini, rm_n91.n91_periodo_fin

END FUNCTION



FUNCTION validar_cuenta(aux_cont)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL  THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_cta.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION lee_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_n30		RECORD LIKE rolt030.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_n91.* FROM rolt091 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con indice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_n91.n91_proceso, rm_n91.n91_cod_trab, rm_n91.n91_num_ant,
	rm_n91.n91_fecha_ant, rm_n91.n91_motivo_ant, rm_n91.n91_prov_aport,
	rm_n91.n91_tipo_pago, rm_n91.n91_valor_gan, rm_n91.n91_val_vac_par,
	rm_n91.n91_bco_empresa, rm_n91.n91_val_pro_apor, rm_n91.n91_cta_empresa,
	rm_n91.n91_cta_trabaj, rm_n91.n91_saldo_pend, rm_n91.n91_valor_tope,
	rm_n91.n91_proc_vac, rm_n91.n91_periodo_ini, rm_n91.n91_periodo_fin,
	rm_n91.n91_tipo_comp, rm_n91.n91_num_comp, rm_n91.n91_valor_ant,
	rm_n91.n91_usuario, rm_n91.n91_fecing
CALL fl_lee_trabajador_roles(vg_codcia, rm_n91.n91_cod_trab) RETURNING r_n30.*
CALL fl_lee_banco_general(rm_n91.n91_bco_empresa) RETURNING r_g08.*
DISPLAY BY NAME rm_n03.n03_nombre, r_n30.n30_nombres, r_g08.g08_nombre
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION generar_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE glosa		LIKE ctbt012.b12_glosa
DEFINE num_che		LIKE ctbt012.b12_num_cheque
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE valor_cuad	DECIMAL(14,2)

INITIALIZE r_b12.*, r_n56.* TO NULL
CALL fl_lee_trabajador_roles(vg_codcia, rm_n91.n91_cod_trab)
	RETURNING r_n30.*
SELECT * INTO r_n56.*
	FROM rolt056
	WHERE n56_compania  = vg_codcia
	  AND n56_proceso   = vm_proceso
	  AND n56_cod_depto = r_n30.n30_cod_depto
	  AND n56_cod_trab  = rm_n91.n91_cod_trab
	  AND n56_estado    = "A"
IF NOT validacion_contable(TODAY) THEN
	RETURN r_b12.*
END IF
IF r_n56.n56_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existen auxiliares contable para este trabajador en el proceso de anticipo de vacaciones.', 'stop')
	RETURN r_b12.*
END IF
LET r_b12.b12_compania 	  = vg_codcia
LET r_b12.b12_tipo_comp   = "DC"
IF rm_n91.n91_tipo_pago = 'C' THEN
	LET r_b12.b12_tipo_comp = "EG"
END IF
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
				r_b12.b12_tipo_comp, YEAR(TODAY), MONTH(TODAY)) 
IF r_b12.b12_num_comp <= 0 THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
LET r_b12.b12_estado 	  = 'A'
LET r_b12.b12_glosa       = 'ANTICIPO DE VACACIONES ',
				rm_n91.n91_motivo_ant CLIPPED, ' PERIODO: ',
				rm_n91.n91_periodo_ini USING "dd-mm-yyyy",
				' - ',
				rm_n91.n91_periodo_fin USING "dd-mm-yyyy"
IF rm_n91.n91_tipo_pago = 'C' THEN
	LET r_b12.b12_benef_che = r_n30.n30_nombres CLIPPED
	CALL lee_cheque(r_b12.*) RETURNING num_che, glosa
	IF int_flag THEN
		CALL fl_mostrar_mensaje('Debe generar el cheque, de lo contrario no se podra generar este anticipo de vacaciones del trabajador.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
	LET r_b12.b12_num_cheque = num_che
	LET r_b12.b12_glosa      = glosa CLIPPED
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
LET sec = 1
IF rm_n91.n91_tipo_pago = 'T' THEN
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
					rm_n91.n91_valor_ant, 'D', sec, 1)
ELSE
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
					rm_n91.n91_valor_ant, 'D', sec, 0)
END IF
LET sec = sec + 1
CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_banco,
				rm_n91.n91_valor_ant, 'H', sec, 1)
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
UPDATE rolt091
	SET n91_tipo_comp = r_b12.b12_tipo_comp,
	    n91_num_comp  = r_b12.b12_num_comp
	WHERE n91_compania = rm_n91.n91_compania
	  AND n91_proceso  = rm_n91.n91_proceso
	  AND n91_cod_trab = rm_n91.n91_cod_trab
	  AND n91_num_ant  = rm_n91.n91_num_ant
RETURN r_b12.*

END FUNCTION



FUNCTION validacion_contable(fecha)
DEFINE fecha		DATE
DEFINE resp 		VARCHAR(6)

IF YEAR(fecha) < YEAR(rm_b00.b00_fecha_cm) OR
  (YEAR(fecha) = YEAR(rm_b00.b00_fecha_cm) AND
   MONTH(fecha) <= MONTH(rm_b00.b00_fecha_cm))
THEN
	CALL fl_mostrar_mensaje('El Mes en Contabilidad esta cerrado. Reapertúrelo para que se pueda generar la contabilización del Anticipo de Vacaciones.', 'stop')
	RETURN 0
END IF
IF fecha_bloqueada(vg_codcia, MONTH(fecha), YEAR(fecha)) THEN
	CALL fl_mostrar_mensaje('No puede generar contabilización del Anticipo de Vacaciones de un mes bloqueado en CONTABILIDAD.', 'stop')
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

OPEN WINDOW w_rolf253_2 AT 07, 12 WITH FORM "../forms/rolf252_4" 
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
CLOSE WINDOW w_rolf253_2
RETURN r_b12.b12_num_cheque, r_b12.b12_glosa

END FUNCTION



FUNCTION generar_detalle_contable(r_b12, cuenta, valor, tipo, sec, flag_bco)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		LIKE ctbt013.b13_valor_base
DEFINE tipo		CHAR(1)
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE flag_bco		SMALLINT
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_b13		RECORD LIKE ctbt013.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = sec
IF flag_bco THEN
	IF rm_n91.n91_tipo_pago <> 'E' AND tipo = 'H' THEN
		CALL fl_lee_banco_compania(vg_codcia,rm_n91.n91_bco_empresa,
						rm_n91.n91_cta_empresa)
			RETURNING r_g09.*
		LET cuenta = r_g09.g09_aux_cont
	END IF
	CASE rm_n91.n91_tipo_pago
		WHEN 'C' LET r_b13.b13_tipo_doc = 'CHE'
		--WHEN 'T' LET r_b13.b13_tipo_doc = 'DEP'
	END CASE
END IF
LET r_b13.b13_cuenta      = cuenta
IF rm_n91.n91_tipo_pago = 'T' AND tipo = 'H' AND flag_bco THEN
	LET r_b13.b13_glosa = 'TRANSFERENCIA A CUENTA DEL EMPLEADO '
ELSE
	LET r_b13.b13_glosa = 'ANT.VAC.EMP. '
END IF
LET r_b13.b13_glosa       = r_b13.b13_glosa CLIPPED, ' ',
				rm_n91.n91_cod_trab USING "<<&&", ' ',
				rm_n91.n91_periodo_ini USING "dd-mm-yy",' ',
				rm_n91.n91_periodo_fin USING "dd-mm-yy"
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



FUNCTION ver_contabilizacion()
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(20)

IF rm_n91.n91_tipo_comp IS NULL THEN
	CALL fl_mostrar_mensaje('Este anticipo no esta contabilizado.', 'exclamation')
	RETURN
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, run_prog, 'ctbp201 ', vg_base,
	' CB ', vg_codcia, ' "', rm_n91.n91_tipo_comp, '" "',
	rm_n91.n91_num_comp, '"'
RUN comando

END FUNCTION



FUNCTION ver_tot_gan_liq()
DEFINE dia, valida	SMALLINT
DEFINE fec_ini		LIKE rolt032.n32_fecha_ini
DEFINE fec_fin		LIKE rolt032.n32_fecha_fin

LET dia = 1
IF DAY(rm_n91.n91_periodo_ini) > 15 THEN
	LET dia = 16
END IF
LET fec_ini = MDY(MONTH(rm_n91.n91_periodo_ini), dia,
			YEAR(rm_n91.n91_periodo_ini))
LET dia     = DAY(MDY(MONTH(rm_n91.n91_fecha_ant), 01,
		YEAR(rm_n91.n91_fecha_ant)) + 1 UNITS MONTH - 1 UNITS DAY)
LET fec_fin = MDY(MONTH(rm_n91.n91_fecha_ant), dia, YEAR(rm_n91.n91_fecha_ant))
IF TODAY < fecha_ultima_quincena() THEN
	LET fec_fin = fecha_ultima_quincena()
END IF
{--
LET valida = 1
IF MONTH(TODAY) = MONTH(fecha_ultima_quincena()) THEN
	IF EXTEND(rm_n91.n91_fecha_ant, YEAR TO MONTH) =
	   EXTEND(TODAY, YEAR TO MONTH)
	THEN
		LET valida = 0
	END IF
END IF
IF DAY(rm_n91.n91_fecha_ant) < 15 AND valida THEN
	LET fec_fin = MDY(MONTH(fec_fin), 01, YEAR(fec_fin)) - 1 UNITS DAY
END IF
--}
IF DAY(rm_n91.n91_fecha_ant) >= 15 AND DAY(rm_n91.n91_fecha_ant) < DAY(fec_fin)
THEN
	LET fec_fin = MDY(MONTH(fec_fin), 15, YEAR(fec_fin))
END IF
CALL fl_valor_ganado_liquidacion(vg_codcia, vm_proceso,
				rm_n91.n91_cod_trab, fec_ini, fec_fin)

END FUNCTION

                                                                                
                                                                                
FUNCTION control_imprimir()
DEFINE r_n91		RECORD LIKE rolt091.*
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
DECLARE q_imp CURSOR FOR
	SELECT * FROM rolt091 WHERE ROWID = vm_r_rows[vm_row_current]
START REPORT comprobante_anticipo TO PIPE comando
FOREACH q_imp INTO r_n91.*
	OUTPUT TO REPORT comprobante_anticipo(r_n91.*)
END FOREACH
FINISH REPORT comprobante_anticipo

END FUNCTION



REPORT comprobante_anticipo(r_n91)
DEFINE r_n91		RECORD LIKE rolt091.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE titulo		VARCHAR(80)
DEFINE label_letras	VARCHAR(130)
DEFINE linea		VARCHAR(80)
DEFINE mes, tit_mes	VARCHAR(10)
DEFINE m_i, m_f		VARCHAR(10)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	CALL fl_justifica_titulo('C', "ANTICIPO VACACIONES", 20)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 016, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 020, titulo,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi
	SKIP 2 LINES
	CALL fl_lee_localidad(r_n91.n91_compania, vg_codloc) RETURNING r_g02.*
	CALL fl_lee_trabajador_roles(r_n91.n91_compania, r_n91.n91_cod_trab)
		RETURNING r_n30.*
	CALL fl_lee_moneda(r_n30.n30_mon_sueldo) RETURNING r_g13.*
	PRINT COLUMN 003, 'NOMBRE DEL TRABAJADOR: ', r_n30.n30_nombres CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 003, 'ANTICIPO No.         : ',
		r_n91.n91_num_ant USING "<<<<&",
	      COLUMN 064, 'FECHA: ', r_n91.n91_fecha_ant USING "dd-mm-yyyy"
	SKIP 2 LINES
	PRINT COLUMN 003, 'MOTIVO DEL ANTICIPO  : ',r_n91.n91_motivo_ant CLIPPED
	SKIP 1 LINES
	IF r_n91.n91_prov_aport = 'S' THEN
		PRINT COLUMN 049, 'CON PROVISION DE APORTE PERSONAL'
	ELSE
		PRINT COLUMN 003, ' '
	END IF
	SKIP 2 LINES

ON EVERY ROW
	PRINT COLUMN 003, 'FORMA DE PAGO        : ', r_n91.n91_tipo_pago, ' ',
		tipo_pago(r_n91.n91_tipo_pago) CLIPPED,
	      COLUMN 054, 'VALOR GANADO: ',
		r_n91.n91_valor_gan USING "##,###,##&.##"
	SKIP 1 LINES
	CALL fl_lee_banco_general(r_n91.n91_bco_empresa) RETURNING r_g08.*
	PRINT COLUMN 003, 'BANCO DE LA EMPRESA  : ',
		r_n91.n91_bco_empresa USING "#&&", ' ',r_g08.g08_nombre CLIPPED,
	      COLUMN 054, 'VALOR P. VA.: ',
		r_n91.n91_val_vac_par USING "##,###,##&.##"
	PRINT COLUMN 003, 'CUENTA DE LA EMPRESA : ',
		r_n91.n91_cta_empresa CLIPPED,
	      COLUMN 050, '(-) APOR. P. PE.: ',
		r_n91.n91_val_pro_apor USING "##,###,##&.##"
	IF r_n91.n91_cta_trabaj IS NOT NULL THEN
		PRINT COLUMN 003, 'CUENTA DEL TRABAJADOR: ',
			r_n91.n91_cta_trabaj CLIPPED;
	ELSE
		PRINT COLUMN 003, ' ';
	END IF
	PRINT COLUMN 068, '-------------'
	PRINT COLUMN 054, 'VALOR TOPE  : ',
		r_n91.n91_valor_tope USING "##,###,##&.##"
	SKIP 1 LINES
	PRINT COLUMN 003, 'APLICARSE EN VACACION: ', r_n91.n91_proc_vac CLIPPED,
		' ', r_n91.n91_periodo_ini USING "dd-mm-yyyy",
		' ', r_n91.n91_periodo_fin USING "dd-mm-yyyy"
	PRINT COLUMN 003, 'COMPROBANTE          : ', r_n91.n91_tipo_comp, ' ',
		r_n91.n91_num_comp CLIPPED,
	      COLUMN 054, 'VALOR ANTIC.: ',
		r_n91.n91_valor_ant USING "##,###,##&.##"
	SKIP 2 LINES

ON LAST ROW
	PRINT COLUMN 003, 'SUMA LIQUIDA RECIBIDA: ',
	      COLUMN 064, r_g13.g13_simbolo CLIPPED, ' ',
		r_n91.n91_valor_ant USING "$$,###,##&.##"
	SKIP 1 LINES
	LET label_letras = fl_retorna_letras(r_g13.g13_moneda,
						r_n91.n91_valor_ant)
	PRINT COLUMN 003, 'SON: ', label_letras[1, 77] CLIPPED
	SKIP 4 LINES
	PRINT COLUMN 003, '..............................',
	      COLUMN 040, '..............................'
	PRINT COLUMN 003, '     Firma del Trabajador     ',
	      COLUMN 040, '       Firma del Gerente      '

END REPORT



FUNCTION tipo_pago(tipo)
DEFINE tipo		LIKE rolt091.n91_tipo_pago
DEFINE nombre		VARCHAR(15)

CASE tipo
	WHEN 'E' LET nombre = 'EFECTIVO'
	WHEN 'C' LET nombre = 'CHEQUE'
	WHEN 'T' LET nombre = 'TRANSFERENCIA'
END CASE
RETURN nombre

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

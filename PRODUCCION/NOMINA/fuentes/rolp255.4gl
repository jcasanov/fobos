--------------------------------------------------------------------------------
-- Titulo               : rolp255.4gl -- Cancelacion Dividendos de Anticipos
-- Elaboración          : 14-May-2007
-- Autor                : NPC
-- Formato de Ejecución : fglrun rolp255 Base Modulo Compañía
--			  [cod_trab] [num_prest]
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n03		RECORD LIKE rolt003.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_n91   	RECORD LIKE rolt091.*
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE vm_proceso	LIKE rolt003.n03_proceso
DEFINE rm_detalle	ARRAY[200] OF RECORD
				n92_num_prest	LIKE rolt092.n92_num_prest,
				n92_secuencia	LIKE rolt092.n92_secuencia,
				n92_cod_liqrol	LIKE rolt092.n92_cod_liqrol,
                                n92_fecha_ini	LIKE rolt092.n92_fecha_ini,
				n92_fecha_fin	LIKE rolt092.n92_fecha_ini,
				valor_div	DECIMAL(12,2),
                                n92_valor_pago	LIKE rolt092.n92_valor_pago,
				cancelar	CHAR(1)
			END RECORD
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current	SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE tot_val_div	DECIMAL(14,2)
DEFINE tot_val_pag	DECIMAL(14,2)
DEFINE vm_lin_pag	SMALLINT



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp255.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp255'
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
LET vm_proceso = 'CA'
CALL fl_lee_proceso_roles(vm_proceso) RETURNING rm_n03.*
IF rm_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso CANCELACION DE DIVIDENDOS en la tabla rolt003.', 'stop')
	EXIT PROGRAM
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
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compañía.','stop')
	EXIT PROGRAM
END IF
LET vm_max_rows = 1000
LET vm_max_det  = 200
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
OPEN WINDOW w_rolf255_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf255_1 FROM '../forms/rolf255_1'
ELSE
	OPEN FORM f_rolf255_1 FROM '../forms/rolf255_1c'
END IF
DISPLAY FORM f_rolf255_1
CALL mostrar_botones()
INITIALIZE rm_n91.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(vm_num_det, 0)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Contabilización'
		HIDE OPTION 'Empleado'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Detalle'
		IF num_args() <> 3 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Empleado'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
			CALL control_consulta()
			IF vm_num_rows > 0 THEN
				CALL ubicarse_detalle()
			END IF
			EXIT PROGRAM
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Empleado'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
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
			SHOW OPTION 'Empleado'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Contabilización'
				HIDE OPTION 'Empleado'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Contabilización'
			SHOW OPTION 'Empleado'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('B') 'Contabilización' 'Ver diario contable.'
		CALL ver_contabilizacion()
	COMMAND KEY('E') 'Empleado' 'Muestra los datos del empleado.'
		CALL ver_empleado()
	COMMAND KEY('P') 'Imprimir' 'Imprime el comprobante.'
		CALL control_imprimir()
        COMMAND KEY('D') 'Detalle'   'Se ubica en el detalle.'
		IF vm_num_rows > 0 THEN
			CALL ubicarse_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
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

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE num_aux		INTEGER
DEFINE resp		CHAR(6)

CALL borrar_pantalla()
LET rm_n91.n91_compania   = vg_codcia
LET rm_n91.n91_proceso    = vm_proceso
LET rm_n91.n91_fecha_ant  = TODAY
LET rm_n91.n91_prov_aport = 'N'
LET rm_n91.n91_tipo_pago  = 'E'
LET rm_n91.n91_valor_gan  = NULL
LET rm_n91.n91_fecing     = CURRENT
LET rm_n91.n91_usuario    = vg_usuario
DISPLAY BY NAME rm_n91.n91_fecha_ant, rm_n91.n91_usuario
CALL leer_cabecera()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN
END IF
CALL cargar_anticipos()
IF vm_num_det = 0 THEN
	CALL fl_mostrar_mensaje('Este empleado no tiene anticipos pendientes.', 'exclamation')
	CALL mostrar_salir()
	RETURN
END IF
CALL leer_detalle()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN
END IF
BEGIN WORK
	SELECT NVL(MAX(n91_num_ant) + 1, 1)
		INTO rm_n91.n91_num_ant
		FROM rolt091
		WHERE n91_compania = rm_n91.n91_compania
		  AND n91_proceso  = rm_n91.n91_proceso
		  AND n91_cod_trab = rm_n91.n91_cod_trab
	IF rm_n91.n91_num_ant IS NULL THEN
		LET rm_n91.n91_num_ant = 1
	END IF
	--LET rm_n91.n91_valor_gan    = tot_val_pag * (-1)
	LET rm_n91.n91_val_vac_par  = 0
	LET rm_n91.n91_val_pro_apor = 0
	LET rm_n91.n91_saldo_pend   = 0
	LET rm_n91.n91_valor_tope   = 0
	LET rm_n91.n91_valor_ant    = tot_val_pag
	LET rm_n91.n91_fecing       = CURRENT
	INSERT INTO rolt091 VALUES (rm_n91.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	CALL grabar_detalle()
	IF NOT dar_baja_dividendos() THEN
		ROLLBACK WORK
		CALL mostrar_salir()
		RETURN
	END IF
	IF rm_n90.n90_gen_cont_ant = 'S' THEN
		CALL fl_hacer_pregunta('Desea generar contabilización para esta Cancelación de Dividendos ?', 'Yes')
			RETURNING resp
		IF resp = 'Yes' THEN
			WHENEVER ERROR CONTINUE
			CALL generar_contabilizacion() RETURNING r_b12.*
			IF r_b12.b12_compania IS NULL THEN
				WHENEVER ERROR STOP
				ROLLBACK WORK
				CALL mostrar_salir()
				RETURN
			END IF
			WHENEVER ERROR STOP
		ELSE
			INITIALIZE r_b12.* TO NULL
		END IF
	END IF
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = num_aux
LET vm_row_current         = vm_num_rows
CALL muestrar_reg()
IF rm_n90.n90_gen_cont_ant = 'S' AND resp = 'Yes' THEN
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
CALL regenerar_novedades()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(900)
DEFINE query		CHAR(1400)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n91		RECORD LIKE rolt091.*

CLEAR FORM
CALL mostrar_botones()
LET int_flag = 0
IF num_args() = 3 THEN
	CONSTRUCT BY NAME expr_sql ON n91_num_ant, n91_fecha_ant, n91_cod_trab,
		n91_motivo_ant, n91_tipo_pago, n91_bco_empresa, n91_cta_empresa,
		n91_cta_trabaj, n91_valor_gan, n91_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n91_num_ant) THEN
                        CALL fl_ayuda_proceso_adic_rol(vg_codcia, vm_proceso)
                                RETURNING r_n91.n91_num_ant
                        IF r_n91.n91_num_ant IS NOT NULL THEN
                                LET rm_n91.n91_num_ant = r_n91.n91_num_ant
                                DISPLAY BY NAME rm_n91.n91_num_ant
                        END IF
                END IF
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
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
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
		CALL mostrar_salir()
		RETURN
	END IF
ELSE
	LET expr_sql = 'n91_cod_trab = ', arg_val(4),
			'   AND n91_num_ant  = ', arg_val(5)
END IF
LET query = 'SELECT rolt091.*, rolt091.ROWID, rolt030.n30_nombres ',
		' FROM rolt091, rolt030 ',
		' WHERE n91_compania    = ', vg_codcia,
		'   AND n91_proceso     = "', vm_proceso, '"',
		'   AND ', expr_sql CLIPPED,
		'   AND n30_compania    = n91_compania ',
		'   AND n30_cod_trab    = n91_cod_trab ',
		' ORDER BY 4, n30_nombres '
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
	LET vm_row_current = 0
	LET vm_num_det     = 0
	CALL mostrar_botones()
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(vm_num_det, 0)
        RETURN
END IF
LET vm_row_current = 1
CALL muestrar_reg()

END FUNCTION



FUNCTION leer_cabecera()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE resp      	CHAR(6)
DEFINE resul		SMALLINT

LET int_flag = 0 
INPUT BY NAME rm_n91.n91_cod_trab, rm_n91.n91_motivo_ant, rm_n91.n91_tipo_pago,
	rm_n91.n91_bco_empresa, rm_n91.n91_cta_empresa, rm_n91.n91_cta_trabaj,
	rm_n91.n91_valor_gan
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n91.n91_cod_trab, rm_n91.n91_motivo_ant,
				 rm_n91.n91_tipo_pago, rm_n91.n91_bco_empresa,
				 rm_n91.n91_cta_empresa, rm_n91.n91_cta_trabaj,
				 rm_n91.n91_valor_gan)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				RETURN
			END IF
		ELSE
			CLEAR FORM
			RETURN
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
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n91.n91_cta_trabaj = r_b10.b10_cuenta
				DISPLAY BY NAME rm_n91.n91_cta_trabaj
			END IF
		END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
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
				--NEXT FIELD n91_cod_trab
			END IF
			IF (r_n30.n30_tipo_pago    <> 'E' AND
			    r_n30.n30_bco_empresa  IS NOT NULL) AND
			   (rm_n91.n91_tipo_pago   <> 'E' AND
			    rm_n91.n91_bco_empresa IS NULL)
			THEN
				LET rm_n91.n91_tipo_pago  = r_n30.n30_tipo_pago
				LET rm_n91.n91_bco_empresa=r_n30.n30_bco_empresa
				LET rm_n91.n91_cta_empresa=r_n30.n30_cta_empresa
				IF rm_n91.n91_tipo_pago = 'T' THEN
					LET rm_n91.n91_cta_trabaj =
							r_n30.n30_cta_trabaj
				END IF
				DISPLAY BY NAME rm_n91.n91_tipo_pago,
						rm_n91.n91_bco_empresa,
						rm_n91.n91_cta_empresa,
						rm_n91.n91_cta_trabaj
				CALL fl_lee_banco_general(rm_n91.n91_bco_empresa)
					RETURNING r_g08.*
				DISPLAY BY NAME r_g08.g08_nombre
			END IF
		ELSE
			CLEAR n30_nombres
		END IF
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
			IF validar_cuenta(rm_n91.n91_cta_trabaj) THEN
				NEXT FIELD n91_cta_trabaj
			END IF
		ELSE
			CLEAR n91_cta_trabaj
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
				IF validar_cuenta(rm_n91.n91_cta_trabaj) THEN
					NEXT FIELD n91_cta_trabaj
				END IF
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION leer_detalle()
DEFINE i, j, salir	SMALLINT
DEFINE resp		CHAR(6)
DEFINE valor		LIKE rolt046.n46_valor

OPTIONS	INSERT KEY F30
OPTIONS	DELETE KEY F31
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
	       	ON KEY(F5)
       			LET i = arr_curr()
			CALL pagar_div(i)
			IF rm_detalle[i].cancelar = 'S' THEN
				--#CALL dialog.keysetlabel("F5","Quitar")
			ELSE
				--#CALL dialog.keysetlabel("F5","Pagar")
			END IF
			IF tot_val_div = (tot_val_pag * (-1)) THEN
				--#CALL dialog.keysetlabel("F6","Quitar Todos")
			ELSE
				--#CALL dialog.keysetlabel("F6","Pagar Todos")
			END IF
	       	ON KEY(F6)
       			LET i = arr_curr()
			CALL pagar_div(0)
			IF rm_detalle[i].cancelar = 'S' THEN
				--#CALL dialog.keysetlabel("F5","Quitar")
			ELSE
				--#CALL dialog.keysetlabel("F5","Pagar")
			END IF
			IF tot_val_div = (tot_val_pag * (-1)) THEN
				--#CALL dialog.keysetlabel("F6","Quitar Todos")
			ELSE
				--#CALL dialog.keysetlabel("F6","Pagar Todos")
			END IF
		BEFORE INPUT
               		--#CALL dialog.keysetlabel("INSERT","")
               		--#CALL dialog.keysetlabel("DELETE","")
               		--#CALL dialog.keysetlabel("RETURN","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE INSERT
			CLEAR rm_detalle[j].*
			EXIT INPUT
		BEFORE ROW
       			LET i = arr_curr()
	        	LET j = scr_line()
			IF rm_detalle[i].cancelar = 'S' THEN
				--#CALL dialog.keysetlabel("F5","Quitar")
			ELSE
				--#CALL dialog.keysetlabel("F5","Pagar")
			END IF
			IF tot_val_div = (tot_val_pag * (-1)) THEN
				--#CALL dialog.keysetlabel("F6","Quitar Todos")
			ELSE
				--#CALL dialog.keysetlabel("F6","Pagar Todos")
			END IF
			CALL muestra_contadores_det(i, vm_num_det)
			CALL mostrar_total()
		BEFORE DELETE
			EXIT INPUT
		BEFORE FIELD n92_valor_pago
			LET valor = rm_detalle[i].n92_valor_pago
		AFTER FIELD n92_valor_pago
			IF rm_detalle[i].n92_valor_pago IS NULL THEN
				LET rm_detalle[i].n92_valor_pago = valor
				DISPLAY rm_detalle[i].n92_valor_pago TO
					rm_detalle[j].n92_valor_pago
			END IF
			IF rm_detalle[i].n92_valor_pago > 
			   rm_detalle[i].valor_div
			THEN
				CALL fl_mostrar_mensaje('El valor del pago no puede ser mayor que el valor del dividendo.', 'exclamation')
				LET rm_detalle[i].n92_valor_pago = 0
				LET rm_detalle[i].cancelar       = 'N'
				DISPLAY rm_detalle[i].n92_valor_pago TO
					rm_detalle[j].n92_valor_pago
				DISPLAY rm_detalle[i].cancelar TO
					rm_detalle[j].cancelar
				NEXT FIELD n92_valor_pago
			END IF
			IF rm_detalle[i].n92_valor_pago > 0 THEN
				LET rm_detalle[i].n92_valor_pago =
					rm_detalle[i].n92_valor_pago * (-1)
			END IF
			IF rm_detalle[i].n92_valor_pago < 0 THEN
				LET rm_detalle[i].cancelar = 'S'
				DISPLAY rm_detalle[i].cancelar TO
					rm_detalle[j].cancelar
			END IF
			DISPLAY rm_detalle[i].n92_valor_pago TO
				rm_detalle[j].n92_valor_pago
			CALL mostrar_total()
		AFTER FIELD cancelar
			IF rm_detalle[i].n92_valor_pago <> 0 THEN
				CONTINUE INPUT
			END IF
			IF rm_detalle[i].cancelar = 'S' THEN
				LET rm_detalle[i].n92_valor_pago =
						rm_detalle[i].valor_div * (-1)
			ELSE
				LET rm_detalle[i].n92_valor_pago = 0
			END IF
			DISPLAY rm_detalle[i].n92_valor_pago TO
				rm_detalle[j].n92_valor_pago
			CALL mostrar_total()
		AFTER INPUT
			CALL mostrar_total()
			IF rm_n91.n91_valor_gan <> (tot_val_pag * (-1)) THEN
				CALL fl_mostrar_mensaje('El total de pago es diferente al valor a cancelar.', 'exclamation')
				CONTINUE INPUT
			END IF
			LET salir = 1
	END INPUT
	IF salir THEN
		CALL muestra_contadores_det(0, vm_num_det)
		EXIT WHILE
	END IF
END WHILE

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
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del último.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION pagar_div(i)
DEFINE i		SMALLINT
DEFINE ini, lim, l	SMALLINT
DEFINE primera		SMALLINT
DEFINE val_tot		LIKE rolt091.n91_valor_gan

LET ini = i
LET lim = i
IF i = 0 THEN
	LET ini = 1
	LET lim = vm_num_det
END IF
LET val_tot = rm_n91.n91_valor_gan
LET primera = 1
FOR l = ini TO lim 
	IF rm_detalle[l].cancelar = 'N' THEN
		LET rm_detalle[l].cancelar       = 'S'
		LET rm_detalle[l].n92_valor_pago =rm_detalle[l].valor_div * (-1)
		IF NOT primera THEN
			IF val_tot <= rm_detalle[l].valor_div THEN
				LET rm_detalle[l].n92_valor_pago =val_tot * (-1)
				EXIT FOR
			END IF
		END IF
		LET primera = 0
		LET val_tot = val_tot + rm_detalle[l].n92_valor_pago
		IF val_tot = 0 THEN
			EXIT FOR
		END IF
	ELSE
		LET rm_detalle[l].cancelar       = 'N'
		LET rm_detalle[l].n92_valor_pago = 0
	END IF
END FOR
CALL mostrar_detalle()

END FUNCTION



FUNCTION lee_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL muestrar_reg()

END FUNCTION



FUNCTION lee_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL muestrar_reg()

END FUNCTION



FUNCTION mostrar_salir()

CLEAR FORM
CALL mostrar_botones()
IF vm_row_current > 0 THEN
	CALL muestrar_reg()
END IF

END FUNCTION



FUNCTION muestrar_reg()

CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0, vm_num_det)

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
DISPLAY BY NAME rm_n91.n91_num_ant, rm_n91.n91_fecha_ant, rm_n91.n91_cod_trab,
	rm_n91.n91_motivo_ant, rm_n91.n91_tipo_pago, rm_n91.n91_bco_empresa,
	rm_n91.n91_cta_empresa, rm_n91.n91_cta_trabaj, rm_n91.n91_valor_gan,
	rm_n91.n91_usuario
CALL fl_lee_trabajador_roles(vg_codcia, rm_n91.n91_cod_trab) RETURNING r_n30.*
CALL fl_lee_banco_general(rm_n91.n91_bco_empresa) RETURNING r_g08.*
DISPLAY BY NAME r_n30.n30_nombres, r_g08.g08_nombre
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL cargar_detalle()
CALL mostrar_detalle()

END FUNCTION



FUNCTION cargar_anticipos()
DEFINE r_n46		RECORD LIKE rolt046.*

DECLARE q_n46 CURSOR FOR
	SELECT rolt046.*
		FROM rolt045, rolt046
		WHERE n45_compania  = rm_n91.n91_compania
		  AND n45_cod_trab  = rm_n91.n91_cod_trab
		  AND n45_estado    IN ("A", "R")
		  AND n46_compania  = n45_compania
		  AND n46_num_prest = n45_num_prest
		  AND n46_saldo     > 0
		ORDER BY n46_num_prest, n46_secuencia
LET vm_num_det = 1
FOREACH q_n46 INTO r_n46.*
	LET rm_detalle[vm_num_det].n92_num_prest  = r_n46.n46_num_prest
	LET rm_detalle[vm_num_det].n92_secuencia  = r_n46.n46_secuencia
	LET rm_detalle[vm_num_det].n92_cod_liqrol = r_n46.n46_cod_liqrol
	LET rm_detalle[vm_num_det].n92_fecha_ini  = r_n46.n46_fecha_ini
	LET rm_detalle[vm_num_det].n92_fecha_fin  = r_n46.n46_fecha_fin
	LET rm_detalle[vm_num_det].valor_div      = r_n46.n46_saldo
	LET rm_detalle[vm_num_det].n92_valor_pago = 0
	LET rm_detalle[vm_num_det].cancelar       = 'N'
	LET vm_num_det                            = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION cargar_detalle()
DEFINE r_n92		RECORD LIKE rolt092.*

DECLARE q_n92 CURSOR FOR
	SELECT * FROM rolt092
		WHERE n92_compania = rm_n91.n91_compania
		  AND n92_proceso  = rm_n91.n91_proceso
		  AND n92_cod_trab = rm_n91.n91_cod_trab
		  AND n92_num_ant  = rm_n91.n91_num_ant
		ORDER BY n92_num_prest, n92_secuencia
LET vm_num_det = 1
FOREACH q_n92 INTO r_n92.*
	LET rm_detalle[vm_num_det].n92_num_prest  = r_n92.n92_num_prest
	LET rm_detalle[vm_num_det].n92_secuencia  = r_n92.n92_secuencia
	LET rm_detalle[vm_num_det].n92_cod_liqrol = r_n92.n92_cod_liqrol
	LET rm_detalle[vm_num_det].n92_fecha_ini  = r_n92.n92_fecha_ini
	LET rm_detalle[vm_num_det].n92_fecha_fin  = r_n92.n92_fecha_fin
	LET rm_detalle[vm_num_det].valor_div      = r_n92.n92_valor
	LET rm_detalle[vm_num_det].n92_valor_pago = r_n92.n92_valor_pago
	LET rm_detalle[vm_num_det].cancelar       = 'S'
	LET vm_num_det                            = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

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

LET tot_val_div = 0
LET tot_val_pag = 0
FOR i = 1 TO vm_num_det
	LET tot_val_div = tot_val_div + rm_detalle[i].valor_div
	LET tot_val_pag = tot_val_pag + rm_detalle[i].n92_valor_pago
END FOR
DISPLAY BY NAME tot_val_div, tot_val_pag

END FUNCTION



FUNCTION ubicarse_detalle()
DEFINE i, j		SMALLINT

CALL set_count(vm_num_det)
LET int_flag = 0
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F7)
		LET i = arr_curr()
		CALL ver_anticipo(i)
		LET int_flag = 0
	ON KEY(F8)
		CALL ver_empleado()
		LET int_flag = 0
	ON KEY(F9)
		CALL ver_contabilizacion()
		LET int_flag = 0
	ON KEY(F10)
		CALL control_imprimir()
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_num_det)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
CALL muestra_contadores_det(0, vm_num_det)

END FUNCTION 



FUNCTION grabar_detalle()
DEFINE r_n92		RECORD LIKE rolt092.*
DEFINE i		SMALLINT

DELETE FROM rolt092
	WHERE n92_compania = rm_n91.n91_compania
	  AND n92_proceso  = rm_n91.n91_proceso
	  AND n92_cod_trab = rm_n91.n91_cod_trab
	  AND n92_num_ant  = rm_n91.n91_num_ant
FOR i = 1 TO vm_num_det
	IF rm_detalle[i].n92_valor_pago = 0 THEN
		CONTINUE FOR
	END IF
	INITIALIZE r_n92.* TO NULL
	LET r_n92.n92_compania   = rm_n91.n91_compania
	LET r_n92.n92_proceso    = rm_n91.n91_proceso
	LET r_n92.n92_cod_trab   = rm_n91.n91_cod_trab
	LET r_n92.n92_num_ant    = rm_n91.n91_num_ant
	LET r_n92.n92_num_prest  = rm_detalle[i].n92_num_prest
	LET r_n92.n92_secuencia  = rm_detalle[i].n92_secuencia
	LET r_n92.n92_cod_liqrol = rm_detalle[i].n92_cod_liqrol
	LET r_n92.n92_fecha_ini  = rm_detalle[i].n92_fecha_ini
	LET r_n92.n92_fecha_fin  = rm_detalle[i].n92_fecha_fin
	LET r_n92.n92_valor      = rm_detalle[i].valor_div
	LET r_n92.n92_saldo      = 0
	LET r_n92.n92_valor_pago = rm_detalle[i].n92_valor_pago
	INSERT INTO rolt092 VALUES(r_n92.*)
END FOR

END FUNCTION


 
FUNCTION dar_baja_dividendos()
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE r_n46		RECORD LIKE rolt046.*
DEFINE num_prest	LIKE rolt045.n45_num_prest
DEFINE resul, i		SMALLINT

LET resul     = 1
LET num_prest = 0
FOR i = 1 TO vm_num_det
	IF rm_detalle[i].n92_valor_pago = 0 THEN
		CONTINUE FOR
	END IF
	INITIALIZE r_n46.* TO NULL
	WHENEVER ERROR CONTINUE
	DECLARE q_baja_n46 CURSOR WITH HOLD FOR
		SELECT * FROM rolt046
			WHERE n46_compania   = rm_n91.n91_compania
			  AND n46_num_prest  = rm_detalle[i].n92_num_prest
			  AND n46_secuencia  = rm_detalle[i].n92_secuencia
			FOR UPDATE
	OPEN q_baja_n46
	FETCH q_baja_n46 INTO r_n46.*
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('Esta bloqueado uno de los dividendos de este empleado.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOR
	END IF
	IF STATUS = NOTFOUND THEN
		CALL fl_mostrar_mensaje('No existe uno de los dividendos de este empleado. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOR
	END IF
	UPDATE rolt046
		SET n46_saldo = rm_detalle[i].valor_div +
				rm_detalle[i].n92_valor_pago
		WHERE CURRENT OF q_baja_n46
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('No se pudo dar baja a uno de los dividendos de este empleado.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOR
	END IF
	CLOSE q_baja_n46
	FREE q_baja_n46
	UPDATE rolt058
		SET n58_saldo_dist = n58_saldo_dist +
					rm_detalle[i].n92_valor_pago
		WHERE n58_compania  = rm_n91.n91_compania
		  AND n58_num_prest = rm_detalle[i].n92_num_prest
		  AND n58_proceso   = rm_detalle[i].n92_cod_liqrol
	IF (rm_detalle[i].n92_valor_pago * (-1)) = rm_detalle[i].valor_div THEN
		UPDATE rolt058
			SET n58_div_act    = n58_div_act + 1
			WHERE n58_compania  = rm_n91.n91_compania
			  AND n58_num_prest = rm_detalle[i].n92_num_prest
			  AND n58_proceso   = rm_detalle[i].n92_cod_liqrol
	END IF
	--IF num_prest <> 0 AND num_prest = rm_detalle[i].n92_num_prest THEN
	--	CONTINUE FOR
	--END IF
	LET num_prest = rm_detalle[i].n92_num_prest
	INITIALIZE r_n45.* TO NULL
	WHENEVER ERROR CONTINUE
	DECLARE q_baja_n45 CURSOR WITH HOLD FOR
		SELECT * FROM rolt045
			WHERE n45_compania  = rm_n91.n91_compania
			  AND n45_num_prest = rm_detalle[i].n92_num_prest
			FOR UPDATE
	OPEN q_baja_n45
	FETCH q_baja_n45 INTO r_n45.*
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('Esta bloqueado uno de los anticipos de este empleado.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOR
	END IF
	IF STATUS = NOTFOUND THEN
		CALL fl_mostrar_mensaje('No existe uno de los anticipos de este empleado. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOR
	END IF
	IF (r_n45.n45_descontado - rm_detalle[i].n92_valor_pago) >=
	   (r_n45.n45_val_prest + r_n45.n45_valor_int + r_n45.n45_sal_prest_ant)
	THEN
		LET r_n45.n45_estado = 'P' 
	END IF
	UPDATE rolt045
		SET n45_descontado = (r_n45.n45_descontado -
					rm_detalle[i].n92_valor_pago),
		    n45_estado     = r_n45.n45_estado
		WHERE CURRENT OF q_baja_n45
	IF STATUS < 0 THEN
		CALL fl_mostrar_mensaje('No se pudo dar baja a uno de los anticipos de este empleado.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		EXIT FOR
	END IF
	CLOSE q_baja_n45
	FREE q_baja_n45
	WHENEVER ERROR STOP
END FOR
RETURN resul

END FUNCTION


 
FUNCTION ver_anticipo(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(60)

LET param = ' ', rm_detalle[i].n92_num_prest, ' "X"'
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp214 ', param)

END FUNCTION


 
FUNCTION ver_empleado()
DEFINE param		VARCHAR(60)

LET param = ' ', rm_n91.n91_cod_trab
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp108 ', param)

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



FUNCTION mostrar_botones()

DISPLAY 'Ant.'		TO tit_col1
DISPLAY 'Div.'		TO tit_col2
DISPLAY 'LQ'		TO tit_col3
DISPLAY 'Fec. Ini.'	TO tit_col4
DISPLAY 'Fec. Fin.'	TO tit_col5
DISPLAY 'Saldo Div.'	TO tit_col6
DISPLAY 'Valor Pago'	TO tit_col7
DISPLAY 'C'		TO tit_col8

END FUNCTION



FUNCTION muestra_contadores(num_cur, max_cur)
DEFINE num_cur, max_cur	SMALLINT

DISPLAY BY NAME num_cur, max_cur

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
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
	CALL fl_mostrar_mensaje('No existen auxiliares contable para este trabajador en el proceso de cancelacion de dividendos.', 'stop')
	RETURN r_b12.*
END IF
LET r_b12.b12_compania 	  = vg_codcia
LET r_b12.b12_tipo_comp   = "DC"
IF rm_n91.n91_tipo_pago <> 'E' AND vg_codloc <> 3 THEN
	LET r_b12.b12_tipo_comp = "DP"
END IF
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
				r_b12.b12_tipo_comp, YEAR(TODAY), MONTH(TODAY)) 
IF r_b12.b12_num_comp <= 0 THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
LET r_b12.b12_estado 	  = 'A'
LET r_b12.b12_glosa       = rm_n03.n03_nombre CLIPPED, ' ',
				rm_n91.n91_motivo_ant CLIPPED
IF r_b12.b12_tipo_comp = "EG" THEN
	LET r_b12.b12_benef_che = r_n30.n30_nombres CLIPPED
	CALL lee_cheque(r_b12.*) RETURNING num_che, glosa
	IF int_flag THEN
		CALL fl_mostrar_mensaje('Debe generar el cheque, de lo contrario no se podra generar esta cancelacion dividendos de anticipo.', 'stop')
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
CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				rm_n91.n91_valor_ant, 'D', sec, 0)
IF rm_n91.n91_tipo_pago = 'T' THEN
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_banco,
					rm_n91.n91_valor_ant, 'H', sec, 0)
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, rm_n91.n91_cta_trabaj,
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
	CALL fl_mostrar_mensaje('El Mes en Contabilidad esta cerrado. Reapertúrelo para que se pueda generar la contabilización de la Cancelacion de Dividendos.', 'stop')
	RETURN 0
END IF
IF fecha_bloqueada(vg_codcia, MONTH(fecha), YEAR(fecha)) THEN
	CALL fl_mostrar_mensaje('No puede generar contabilización de la Cancelacion de Dividendos de un mes bloqueado en CONTABILIDAD.', 'stop')
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

OPEN WINDOW w_rolf255_2 AT 07, 12 WITH FORM "../forms/rolf252_4" 
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
CLOSE WINDOW w_rolf255_2
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
DEFINE r_n30		RECORD LIKE rolt030.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = sec
IF flag_bco THEN
	IF rm_n91.n91_tipo_pago <> 'E' THEN
		CALL fl_lee_banco_compania(vg_codcia,rm_n91.n91_bco_empresa,
						rm_n91.n91_cta_empresa)
			RETURNING r_g09.*
		LET cuenta = r_g09.g09_aux_cont
	END IF
	{
	CASE rm_n91.n91_tipo_pago
		WHEN 'C' LET r_b13.b13_tipo_doc = 'CHE'
		WHEN 'T' LET r_b13.b13_tipo_doc = 'DEP'
	END CASE
	}
	IF rm_n91.n91_tipo_pago <> 'E' AND vg_codloc <> 3 THEN
		LET r_b13.b13_tipo_doc = 'DEP'
	END IF
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n91.n91_cod_trab) RETURNING r_n30.*
LET r_b13.b13_cuenta      = cuenta
LET r_b13.b13_glosa       = 'CAN.ANT.EMP. ',
				rm_n91.n91_fecha_ant USING "dd-mm-yy", ' ',
				rm_n91.n91_cod_trab USING "<<&&", ' ',
				r_n30.n30_nombres CLIPPED
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



FUNCTION regenerar_novedades()
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE mensaje		VARCHAR(200)
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n46		RECORD LIKE rolt046.*
DEFINE num_prest	LIKE rolt045.n45_num_prest

INITIALIZE r_n05.*, r_n46.* TO NULL
SELECT * INTO r_n05.*
	FROM rolt005 
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
IF r_n05.n05_compania IS NULL THEN
	RETURN
END IF
IF r_n05.n05_proceso[1,1] <> 'M' AND r_n05.n05_proceso[1,1] <> 'Q' AND
   r_n05.n05_proceso[1,1] <> 'S' AND r_n05.n05_proceso[1,1] <> 'D'
THEN
	RETURN
END IF
LET num_prest = NULL
DECLARE q_num_p CURSOR FOR
	SELECT n92_num_prest FROM rolt092
		WHERE n92_compania   = rm_n91.n91_compania
		  AND n92_proceso    = rm_n91.n91_proceso
		  AND n92_cod_trab   = rm_n91.n91_cod_trab
		  AND n92_num_ant    = rm_n91.n91_num_ant
		  AND n92_cod_liqrol = r_n05.n05_proceso
		  AND n92_fecha_ini  = r_n05.n05_fecini_act
		  AND n92_fecha_fin  = r_n05.n05_fecfin_act
OPEN q_num_p
FETCH q_num_p INTO num_prest
CLOSE q_num_p
FREE q_num_p
IF num_prest IS NULL THEN
	RETURN
END IF
SELECT * INTO r_n46.*
	FROM rolt046 
	WHERE n46_compania   = r_n05.n05_compania
	  AND n46_num_prest  = num_prest
	  AND n46_cod_liqrol = r_n05.n05_proceso
	  AND n46_fecha_ini  = r_n05.n05_fecini_act
	  AND n46_fecha_fin  = r_n05.n05_fecfin_act
IF r_n46.n46_compania IS NULL THEN
	RETURN
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n91.n91_cod_trab) RETURNING r_n30.*
LET mensaje = 'Se va a regenerar novedad de ', r_n05.n05_proceso, ' ',
		r_n05.n05_fecini_act USING "dd-mm-yyyy", ' - ',
		r_n05.n05_fecfin_act USING "dd-mm-yyyy", ' para el trabajador ',
		rm_n91.n91_cod_trab USING "&&&&", ' ', r_n30.n30_nombres CLIPPED
CALL fl_mostrar_mensaje(mensaje, 'info')
CASE r_n05.n05_proceso
	WHEN 'Q1' LET prog  = 'rolp200 '
	WHEN 'Q2' LET prog  = 'rolp200 '
	WHEN 'DT' LET prog  = 'rolp207 '
	WHEN 'DC' LET prog  = 'rolp221 '
	WHEN 'UT' LET prog  = 'rolp222 '
END CASE
LET param = ' ', r_n05.n05_proceso[1,1], ' ', rm_n91.n91_cod_trab, ' ',
		r_n05.n05_proceso, ' ', r_n05.n05_fecini_act, ' ',
		r_n05.n05_fecfin_act
IF r_n05.n05_proceso = 'DT' OR r_n05.n05_proceso = 'DC' THEN
	LET param = ' ', r_n05.n05_fecini_act, ' ', r_n05.n05_fecfin_act, ' ',
			rm_n91.n91_cod_trab, ' G'
END IF
IF r_n05.n05_proceso = 'UT' THEN
	LET param = ' ', YEAR(r_n05.n05_fecfin_act), ' ', rm_n91.n91_cod_trab,
			' G'
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION



FUNCTION ver_contabilizacion()
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)

IF rm_n91.n91_tipo_comp IS NULL THEN
	CALL fl_mostrar_mensaje('Esta cancelación no esta contabilizada.', 'exclamation')
	RETURN
END IF
LET prog  = 'ctbp201 '
LET param = ' "', rm_n91.n91_tipo_comp, '" "', rm_n91.n91_num_comp, '"'
CALL ejecuta_comando('CONTABILIDAD', 'CB', prog, param)

END FUNCTION

                                                                                
                                                                                
FUNCTION control_imprimir()
DEFINE r_n91		RECORD LIKE rolt091.*
DEFINE i		SMALLINT
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET vm_lin_pag = 66
IF vg_codloc = 3 THEN
	LET vm_lin_pag = 44
END IF
DECLARE q_imp CURSOR FOR
	SELECT * FROM rolt091 WHERE ROWID = vm_r_rows[vm_row_current]
START REPORT comprobante_anticipo TO PIPE comando
FOREACH q_imp INTO r_n91.*
	FOR i = 1 TO vm_num_det
		OUTPUT TO REPORT comprobante_anticipo(r_n91.*, i)
	END FOR
END FOREACH
FINISH REPORT comprobante_anticipo

END FUNCTION



REPORT comprobante_anticipo(r_n91, i)
DEFINE r_n91		RECORD LIKE rolt091.*
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(42)
DEFINE usuario		VARCHAR(19)
DEFINE label_letras	VARCHAR(130)
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
	CALL fl_justifica_titulo('C', "CANCELACION DE DIVIDENDOS", 30)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 012, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 016, titulo,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_12cpi
	SKIP 2 LINES
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO               : ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = "USUARIO: ", rm_n91.n91_usuario CLIPPED
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_trabajador_roles(r_n91.n91_compania, r_n91.n91_cod_trab)
		RETURNING r_n30.*
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 089, 'PAG. ', PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, 'CANCELACION No.      : ',
		r_n91.n91_num_ant USING "<<<<&",
	      COLUMN 080, 'FECHA: ', r_n91.n91_fecha_ant USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, 'NOMBRE DEL EMPLEADO  : ',
		rm_n91.n91_cod_trab USING "<<<&&&", ' ',
		r_n30.n30_nombres CLIPPED
	PRINT COLUMN 001, 'MOTIVO DE CANCELACION: ',r_n91.n91_motivo_ant CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA IMPRESION      : ',
		DATE(TODAY) USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 078, usuario
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'ANT.',
	      COLUMN 007, 'DIV.',
	      COLUMN 013, 'LQ',
	      COLUMN 017, '      NOMBRE PROCESO',
	      COLUMN 045, 'FECHA INI.',
	      COLUMN 057, 'FECHA FIN.',
	      COLUMN 069, ' SALDO DIVID.',
	      COLUMN 084, 'VALOR DE PAGO'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	CALL fl_lee_proceso_roles(rm_detalle[i].n92_cod_liqrol)
		RETURNING r_n03.*
	PRINT COLUMN 001, rm_detalle[i].n92_num_prest	USING "##&&",
	      COLUMN 007, rm_detalle[i].n92_secuencia	USING "##&&",
	      COLUMN 013, rm_detalle[i].n92_cod_liqrol	CLIPPED,
	      COLUMN 017, r_n03.n03_nombre[1, 26]	CLIPPED,
	      COLUMN 045, rm_detalle[i].n92_fecha_ini	USING "dd-mm-yyyy",
	      COLUMN 057, rm_detalle[i].n92_fecha_fin	USING "dd-mm-yyyy",
	      COLUMN 069, rm_detalle[i].valor_div	USING "##,###,##&.##",
	      COLUMN 084, rm_detalle[i].n92_valor_pago	USING "##,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 069, '-------------',
	      COLUMN 084, '-------------'
	PRINT COLUMN 056, 'TOTALES ==>  ',
	      COLUMN 069, tot_val_div			USING "##,###,##&.##",
	      COLUMN 084, tot_val_pag			USING "##,###,##&.##"

PAGE TRAILER
	CALL fl_lee_moneda(r_n30.n30_mon_sueldo) RETURNING r_g13.*
	PRINT COLUMN 001, 'SUMA LIQUIDA RECIBIDA: ',
	      COLUMN 080, r_g13.g13_simbolo CLIPPED, ' ',
		r_n91.n91_valor_gan USING "$$,###,##&.##"
	SKIP 1 LINES
	LET label_letras = fl_retorna_letras(r_g13.g13_moneda,
						r_n91.n91_valor_gan * (-1))
	PRINT COLUMN 001, 'SON: ', label_letras[1, 77] CLIPPED
	SKIP 4 LINES
	PRINT COLUMN 013, '..............................',
	      COLUMN 056, '..............................'
	PRINT COLUMN 013, '     Firma del Trabajador     ',
	      COLUMN 056, '     Firma de Autorizacion    '

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



FUNCTION borrar_pantalla()

CALL borrar_cabecera()
CALL limpiar_detalle()
CALL borrar_detalle()

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR n91_num_ant, n91_fecha_ant, n91_cod_trab, n30_nombres, n91_motivo_ant,
	n91_tipo_pago, n91_bco_empresa, g08_nombre, n91_cta_empresa,
	n91_cta_trabaj, n91_usuario
INITIALIZE rm_n91.* TO NULL

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
CLEAR tot_val_div, tot_val_pag

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

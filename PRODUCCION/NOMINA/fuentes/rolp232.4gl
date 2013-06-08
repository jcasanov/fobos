-------------------------------------------------------------------------------
-- Titulo               : rolp232.4gl -- Mantenimiento Transacciones del Club
-- Elaboración          : 24-Oct-2003
-- Autor                : NPC
-- Formato de Ejecución : fglrun rolp232 Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_n60   	RECORD LIKE rolt060.*
DEFINE rm_n68   	RECORD LIKE rolt068.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp232'
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
LET vm_max_rows = 1000
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
OPEN WINDOW w_rol AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf232 FROM '../forms/rolf232_1'
ELSE
	OPEN FORM f_rolf232 FROM '../forms/rolf232_1c'
END IF
DISPLAY FORM f_rolf232
INITIALIZE rm_n68.*, rm_n60.* TO NULL
CALL fl_lee_parametros_club_roles(vg_codcia) RETURNING rm_n60.*
IF rm_n60.n60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado parametros del Club.', 'stop')
	EXIT PROGRAM
END IF
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL mostrar_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL mostrar_anterior_registro()
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



FUNCTION procesar_valor_prestamo()
DEFINE r_n64		RECORD LIKE rolt064.*
DEFINE r_n65		RECORD LIKE rolt065.*
DEFINE saldo		LIKE rolt065.n65_saldo

WHENEVER ERROR CONTINUE
DECLARE q_n64 CURSOR FOR
	SELECT * FROM rolt064
		WHERE n64_compania  = vg_codcia
		  AND n64_num_prest = rm_n68.n68_num_prest
	FOR UPDATE
OPEN q_n64
FETCH q_n64 INTO r_n64.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN 1
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error al actualizar el saldo del préstamo del club. Por favor llame al Administrador.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
DECLARE q_n65 CURSOR FOR
	SELECT * FROM rolt065
		WHERE n65_compania  = r_n64.n64_compania
		  AND n65_num_prest = r_n64.n64_num_prest
LET saldo = rm_n68.n68_valor
FOREACH q_n65 INTO r_n65.*
	IF saldo >= r_n65.n65_saldo THEN
		LET saldo           = saldo - r_n65.n65_saldo
		LET r_n65.n65_saldo = 0
	ELSE
		LET r_n65.n65_saldo = r_n65.n65_saldo - saldo
		LET saldo           = 0
	END IF
	UPDATE rolt065 SET n65_saldo = r_n65.n65_saldo
		WHERE n65_compania  = r_n65.n65_compania
		  AND n65_num_prest = r_n65.n65_num_prest
		  AND n65_secuencia = r_n65.n65_secuencia
	IF saldo = 0 THEN
		EXIT FOREACH
	END IF
END FOREACH
UPDATE rolt064 SET n64_descontado = n64_descontado + rm_n68.n68_valor
	WHERE CURRENT OF q_n64
RETURN 0

END FUNCTION



FUNCTION procesar_saldos_club()
DEFINE r_n60		RECORD LIKE rolt060.*
DEFINE r_n69		RECORD LIKE rolt069.*
DEFINE anio, anio_aux	LIKE rolt069.n69_anio
DEFINE mes, mes_aux	LIKE rolt069.n69_mes
DEFINE saldo_ini	LIKE rolt069.n69_saldo_ini

INITIALIZE r_n60.*, r_n69.* TO NULL
LET anio = YEAR(rm_n68.n68_fecha)
LET mes  = MONTH(rm_n68.n68_fecha)
WHENEVER ERROR CONTINUE
DECLARE q_n60 CURSOR FOR SELECT * FROM rolt060 WHERE n60_compania = vg_codcia
	FOR UPDATE
OPEN q_n60
FETCH q_n60 INTO r_n60.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN r_n69.*, 1
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error al cargar el saldo del parametro del club. Por favor llame al Administrador.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
DECLARE q_n69 CURSOR FOR
	SELECT * FROM rolt069
		WHERE n69_compania   = vg_codcia
		  AND n69_banco      = rm_n68.n68_banco
		  AND n69_numero_cta = rm_n68.n68_numero_cta
		  AND n69_anio       = anio
		  AND n69_mes        = mes
	FOR UPDATE
OPEN q_n69
FETCH q_n69 INTO r_n69.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN r_n69.*, 1
END IF
IF STATUS = NOTFOUND THEN
	INITIALIZE anio_aux, mes_aux TO NULL
	LET saldo_ini = 0
	SELECT MAX(n69_anio) INTO anio_aux FROM rolt069
		WHERE n69_compania   = vg_codcia
		  AND n69_banco      = rm_n68.n68_banco
		  AND n69_numero_cta = rm_n68.n68_numero_cta
	IF anio_aux IS NOT NULL THEN
		SELECT MAX(n69_mes) INTO mes_aux FROM rolt069
			WHERE n69_compania   = vg_codcia
			  AND n69_banco      = rm_n68.n68_banco
			  AND n69_numero_cta = rm_n68.n68_numero_cta
			  AND n69_anio       = anio_aux
		SELECT (n69_saldo_ini + n69_valor_ing -	n69_valor_egr)
			INTO saldo_ini
			FROM rolt069
			WHERE n69_compania   = vg_codcia
			  AND n69_banco      = rm_n68.n68_banco
			  AND n69_numero_cta = rm_n68.n68_numero_cta
			  AND n69_anio       = anio_aux
			  AND n69_mes        = mes_aux
	END IF
	LET r_n69.n69_compania   = vg_codcia
	LET r_n69.n69_banco      = rm_n68.n68_banco
	LET r_n69.n69_numero_cta = rm_n68.n68_numero_cta
	LET r_n69.n69_anio       = anio
	LET r_n69.n69_mes        = mes
	LET r_n69.n69_saldo_ini  = saldo_ini
	LET r_n69.n69_valor_ing  = 0
	LET r_n69.n69_valor_egr  = 0
	INSERT INTO rolt069 VALUES (r_n69.*)
	OPEN q_n69
	FETCH q_n69 INTO r_n69.*
	IF (STATUS < 0) OR (STATUS = NOTFOUND) THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Ha ocurrido un error al cargar los saldos del club. Por favor llame al Administrador.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
END IF
WHENEVER ERROR STOP
RETURN r_n69.*, 0

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_n69		RECORD LIKE rolt069.*
DEFINE num_tran		LIKE rolt068.n68_num_tran
DEFINE resul		SMALLINT

CLEAR FORM
INITIALIZE rm_n68.* TO NULL
LET rm_n68.n68_compania = vg_codcia
LET rm_n68.n68_fecha    = TODAY
LET rm_n68.n68_valor    = 0
LET rm_n68.n68_usuario  = vg_usuario
LET rm_n68.n68_fecing   = CURRENT
DISPLAY BY NAME rm_n68.n68_fecha, rm_n68.n68_usuario, rm_n68.n68_fecing
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
	IF rm_n68.n68_num_prest IS NOT NULL THEN
		CALL procesar_valor_prestamo() RETURNING resul
		IF resul THEN
			RETURN
		END IF
	END IF
	IF rm_n68.n68_banco IS NOT NULL THEN
		CALL procesar_saldos_club() RETURNING r_n69.*, resul
		IF resul THEN
			RETURN
		END IF
	END IF
	INITIALIZE num_tran TO NULL
	SELECT MAX(n68_num_tran) INTO num_tran FROM rolt068
		WHERE n68_compania = vg_codcia
		  AND n68_cod_tran = rm_n68.n68_cod_tran
	IF num_tran IS NULL THEN
		LET num_tran = 1
	ELSE
		LET num_tran = num_tran + 1
	END IF
	LET rm_n68.n68_num_tran  = num_tran
	LET rm_n68.n68_saldo_ant = r_n69.n69_saldo_ini + r_n69.n69_valor_ing -
				   r_n69.n69_valor_egr 
	LET rm_n68.n68_fecing    = CURRENT
        INSERT INTO rolt068 VALUES(rm_n68.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	IF rm_n68.n68_banco IS NOT NULL AND rm_n68.n68_cod_tran = 'IN' THEN
		UPDATE rolt069 SET n69_valor_ing = n69_valor_ing +
							rm_n68.n68_valor
			WHERE CURRENT OF q_n69
		UPDATE rolt060 SET n60_saldo_cta = n60_saldo_cta +
							rm_n68.n68_valor
			WHERE CURRENT OF q_n60
	END IF
	IF rm_n68.n68_banco IS NOT NULL AND rm_n68.n68_cod_tran = 'EG' THEN
		UPDATE rolt069 SET n69_valor_egr = n69_valor_egr +
							rm_n68.n68_valor
			WHERE CURRENT OF q_n69
		UPDATE rolt060 SET n60_saldo_cta = n60_saldo_cta -
							rm_n68.n68_valor
			WHERE CURRENT OF q_n60
	END IF
	COMMIT WORK
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n64		RECORD LIKE rolt064.*
DEFINE r_n67		RECORD LIKE rolt067.*
DEFINE r_n68		RECORD LIKE rolt068.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON n68_cod_tran, n68_num_tran, n68_cod_rubro,
	n68_fecha, n68_valor, n68_referencia, n68_cod_trab, n68_cod_liqrol,
	n68_num_prest, n68_fecha_ini, n68_fecha_fin, n68_banco, n68_numero_cta,
	n68_num_cheque, n68_beneficiario, n68_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n68_num_tran) THEN
			LET r_n68.n68_cod_tran = get_fldbuf(n68_cod_tran)
			CALL fl_ayuda_transacciones_club(vg_codcia,
							r_n68.n68_cod_tran)
				RETURNING r_n68.n68_cod_tran, r_n68.n68_num_tran
			IF r_n68.n68_num_tran IS NOT NULL THEN
				CALL fl_lee_transacciones_club(vg_codcia,
							r_n68.n68_cod_tran,
							r_n68.n68_num_tran)
					RETURNING r_n68.*
				CALL fl_lee_trabajador_roles(vg_codcia,
							r_n68.n68_cod_trab)
					RETURNING r_n30.*
				DISPLAY BY NAME r_n68.n68_cod_tran,
						r_n68.n68_num_tran,
						r_n68.n68_cod_trab,
						r_n30.n30_nombres,
						r_n68.n68_valor
			END IF
		END IF
		IF INFIELD(n68_cod_rubro) THEN
			CALL fl_ayuda_rubros_club('A')
				RETURNING r_n67.n67_cod_rubro, r_n67.n67_nombre
			IF r_n67.n67_cod_rubro IS NOT NULL THEN
				DISPLAY r_n67.n67_cod_rubro TO n68_cod_rubro
				DISPLAY BY NAME r_n67.n67_nombre
			END IF
		END IF
		IF INFIELD(n68_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                DISPLAY r_n30.n30_cod_trab TO n68_cod_trab
                                DISPLAY BY NAME r_n30.n30_nombres
                        END IF
                END IF
		IF INFIELD(n68_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				DISPLAY r_n03.n03_proceso TO n68_cod_liqrol
				DISPLAY BY NAME r_n03.n03_nombre
			END IF
		END IF
		IF INFIELD(n68_num_prest) THEN
			CALL fl_ayuda_anticipos_club(vg_codcia, 'A')
				RETURNING r_n64.n64_num_prest
			IF r_n64.n64_num_prest IS NOT NULL THEN
				DISPLAY r_n64.n64_num_prest TO n68_num_prest
			END IF
		END IF
		IF INFIELD(n68_banco) THEN
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				DISPLAY r_g08.g08_banco TO n68_banco
				DISPLAY BY NAME r_g08.g08_nombre
			END IF
		END IF
		IF INFIELD(n68_numero_cta) THEN
			CALL fl_ayuda_cuenta_banco(vg_codcia, 'T') 
				RETURNING r_g09.g09_banco, r_g08.g08_nombre,
				          r_g09.g09_tipo_cta,
					  r_g09.g09_numero_cta 
			IF r_g09.g09_numero_cta IS NOT NULL THEN
				DISPLAY r_g09.g09_banco      TO n68_banco
				DISPLAY r_g09.g09_numero_cta TO n68_numero_cta
				DISPLAY BY NAME r_g08.g08_nombre
			END IF	
		END IF
		LET int_flag = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rolt068 ',
		' WHERE n68_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2, 3'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_n68.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n64		RECORD LIKE rolt064.*
DEFINE r_n67		RECORD LIKE rolt067.*
DEFINE r_n68		RECORD LIKE rolt068.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE cod_rubro	LIKE rolt067.n67_cod_rubro
DEFINE cod_trab		LIKE rolt030.n30_cod_trab

LET int_flag = 0 
INPUT BY NAME rm_n68.n68_cod_tran, rm_n68.n68_cod_rubro, rm_n68.n68_fecha, 
	rm_n68.n68_valor,
	rm_n68.n68_referencia, rm_n68.n68_cod_trab, rm_n68.n68_num_prest,
	rm_n68.n68_banco, rm_n68.n68_numero_cta, rm_n68.n68_num_cheque,
	rm_n68.n68_beneficiario
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n68.n68_cod_tran, rm_n68.n68_cod_rubro,
				 rm_n68.n68_valor, rm_n68.n68_referencia,
				 rm_n68.n68_cod_trab, rm_n68.n68_num_prest,
				 rm_n68.n68_banco, rm_n68.n68_numero_cta,
				 rm_n68.n68_num_cheque, rm_n68.n68_beneficiario)
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
		IF INFIELD(n68_cod_rubro) THEN
			CALL fl_ayuda_rubros_club('A')
				RETURNING r_n67.n67_cod_rubro, r_n67.n67_nombre
			IF r_n67.n67_cod_rubro IS NOT NULL THEN
				LET rm_n68.n68_cod_rubro = r_n67.n67_cod_rubro
				DISPLAY BY NAME rm_n68.n68_cod_rubro,
						r_n67.n67_nombre
			END IF
		END IF
		IF INFIELD(n68_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n68.n68_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n68.n68_cod_trab,
                                		r_n30.n30_nombres
                        END IF
                END IF
		IF INFIELD(n68_num_prest) THEN
			CALL fl_ayuda_anticipos_club(vg_codcia, 'A')
				RETURNING r_n64.n64_num_prest
			IF r_n64.n64_num_prest IS NOT NULL THEN
				LET rm_n68.n68_num_prest = r_n64.n64_num_prest
				DISPLAY BY NAME rm_n68.n68_num_prest
			END IF
		END IF
		IF INFIELD(n68_banco) THEN
			IF rm_n68.n68_cod_tran = 'EG' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_bancos()
				RETURNING r_g08.g08_banco, r_g08.g08_nombre
			IF r_g08.g08_banco IS NOT NULL THEN
				LET rm_n68.n68_banco = r_g08.g08_banco
				DISPLAY BY NAME rm_n68.n68_banco,
						r_g08.g08_nombre
			END IF
		END IF
		IF INFIELD(n68_numero_cta) THEN
			IF rm_n68.n68_cod_tran = 'EG' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_cuenta_banco(vg_codcia, 'A') 
				RETURNING r_g09.g09_banco, r_g08.g08_nombre,
				          r_g09.g09_tipo_cta, 
				          r_g09.g09_numero_cta 
			IF r_g09.g09_numero_cta IS NOT NULL THEN
				LET rm_n68.n68_banco      = r_g09.g09_banco
				LET rm_n68.n68_numero_cta = r_g09.g09_numero_cta
				DISPLAY BY NAME rm_n68.n68_banco,
						r_g08.g08_nombre,
						rm_n68.n68_numero_cta
			END IF	
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		LET rm_n68.n68_banco      = rm_n60.n60_banco
		LET rm_n68.n68_numero_cta = rm_n60.n60_numero_cta
		CALL fl_lee_banco_general(rm_n68.n68_banco) RETURNING r_g08.*
		DISPLAY BY NAME rm_n68.n68_numero_cta,
				rm_n68.n68_banco,
				r_g08.g08_nombre
	BEFORE FIELD n68_cod_rubro
		LET cod_rubro = rm_n68.n68_cod_rubro
	BEFORE FIELD n68_cod_trab
		LET cod_trab = rm_n68.n68_cod_trab
	BEFORE FIELD n68_banco
		IF rm_n68.n68_cod_tran = 'EG' THEN
			LET r_n68.n68_banco = rm_n60.n60_banco
		END IF
	BEFORE FIELD n68_numero_cta
		IF rm_n68.n68_cod_tran = 'EG' THEN
			LET r_n68.n68_numero_cta = rm_n60.n60_numero_cta
		END IF
	AFTER FIELD n68_cod_tran
		IF rm_n68.n68_cod_tran IS NOT NULL THEN
			IF rm_n68.n68_cod_tran = 'EG' THEN
				LET rm_n68.n68_banco      = rm_n60.n60_banco
				LET rm_n68.n68_numero_cta =
							rm_n60.n60_numero_cta
				CALL fl_lee_banco_general(rm_n68.n68_banco)
					RETURNING r_g08.*
				DISPLAY BY NAME rm_n68.n68_numero_cta,
						rm_n68.n68_banco,
						r_g08.g08_nombre
			END IF
		END IF
	AFTER FIELD n68_cod_rubro
		IF rm_n68.n68_cod_rubro IS NOT NULL THEN
			CALL fl_lee_rubros_club(rm_n68.n68_cod_rubro)
				RETURNING r_n67.*
			IF r_n67.n67_cod_rubro IS NULL THEN
				CALL fl_mostrar_mensaje('No existe ese rubro en el Club.', 'exclamation')
				NEXT FIELD n68_cod_rubro
			END IF
			DISPLAY BY NAME r_n67.n67_nombre
			IF r_n67.n67_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n68_cod_rubro
			END IF
			IF r_n67.n67_cod_rubro <> cod_rubro OR
			   rm_n68.n68_referencia IS NULL THEN
				LET rm_n68.n68_referencia = r_n67.n67_nombre
				DISPLAY BY NAME rm_n68.n68_referencia
			END IF
		ELSE
			CLEAR n67_nombre
		END IF
	AFTER FIELD n68_cod_trab
		IF rm_n68.n68_num_prest IS NOT NULL THEN
			CALL datos_del_prest(cod_trab)
			CONTINUE INPUT
		END IF
		IF rm_n68.n68_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n68.n68_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n68_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n68_cod_trab
			END IF
			IF r_n30.n30_cod_trab <> cod_trab OR
			   rm_n68.n68_beneficiario IS NULL THEN
				LET rm_n68.n68_beneficiario = r_n30.n30_nombres
				DISPLAY BY NAME rm_n68.n68_beneficiario
			END IF
		ELSE
			CLEAR n30_nombres
		END IF
	AFTER FIELD n68_num_prest
		IF rm_n68.n68_num_prest IS NOT NULL THEN
			IF rm_n68.n68_cod_tran <> 'EG' THEN
				CALL fl_mostrar_mensaje('No puede poner un préstamo con una transacción que no sea de Egreso.', 'exclamation')
				LET rm_n68.n68_num_prest = NULL
				CLEAR n68_num_prest 
				CONTINUE INPUT
			END IF
			CALL fl_lee_prestamo_club(vg_codcia,
							rm_n68.n68_num_prest)
				RETURNING r_n64.*
			IF r_n64.n64_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe número de préstamo del club.', 'exclamation')
				NEXT FIELD n68_num_prest
			END IF
			IF r_n64.n64_estado = 'E' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n68_num_prest
			END IF
			IF r_n64.n64_estado = 'P' THEN
				CALL fl_mostrar_mensaje('Préstamo ya ha sido cancelado.', 'exclamation')
				NEXT FIELD n68_num_prest
			END IF
			IF rm_n68.n68_valor >
			   (r_n64.n64_val_prest + r_n64.n64_val_interes)
			THEN
				CALL fl_mostrar_mensaje('El valor de esta transacción es mayor que el del préstamo.', 'exclamation')
				NEXT FIELD n68_valor
			END IF
			LET cod_trab = rm_n68.n68_cod_trab
			CALL datos_del_prest(cod_trab)
		END IF
	AFTER FIELD n68_banco
		IF rm_n68.n68_cod_tran = 'EG' THEN
			LET rm_n68.n68_banco = r_n68.n68_banco
			CALL fl_lee_banco_general(rm_n68.n68_banco)
				RETURNING r_g08.*
			DISPLAY BY NAME rm_n68.n68_banco, r_g08.g08_nombre
			CONTINUE INPUT
		END IF
		IF rm_n68.n68_banco IS NOT NULL THEN
			IF rm_n68.n68_banco <> rm_n60.n60_banco THEN
				CALL fl_mostrar_mensaje('El banco debe ser el del club.', 'exclamation')
				LET rm_n68.n68_banco = rm_n60.n60_banco
				CALL fl_lee_banco_general(rm_n68.n68_banco)
					RETURNING r_g08.*
				DISPLAY BY NAME rm_n68.n68_banco,
						r_g08.g08_nombre
			END IF
		ELSE
			CLEAR g08_nombre
		END IF
	AFTER FIELD n68_numero_cta
		IF rm_n68.n68_cod_tran = 'EG' THEN
			LET rm_n68.n68_numero_cta = r_n68.n68_numero_cta
			DISPLAY BY NAME rm_n68.n68_numero_cta
			CONTINUE INPUT
		END IF
		IF rm_n68.n68_numero_cta IS NOT NULL THEN
			IF rm_n68.n68_numero_cta <> rm_n60.n60_numero_cta THEN
				CALL fl_mostrar_mensaje('La cuenta debe ser la del club.', 'exclamation')
				LET rm_n68.n68_banco      = rm_n60.n60_banco
				LET rm_n68.n68_numero_cta =rm_n60.n60_numero_cta
				CALL fl_lee_banco_general(rm_n68.n68_banco)
					RETURNING r_g08.*
				DISPLAY BY NAME rm_n68.n68_banco,
						r_g08.g08_nombre,
						rm_n68.n68_numero_cta
			END IF
			CALL fl_lee_banco_compania(vg_codcia, rm_n68.n68_banco,
							rm_n68.n68_numero_cta)
				RETURNING r_g09.*
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mostrar_mensaje('La cuenta esta bloqueada.','exclamation')
				NEXT FIELD n68_numero_cta
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n68_numero_cta
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n68_numero_cta
			END IF
		END IF
	AFTER INPUT
		IF rm_n68.n68_cod_tran = 'IN' AND r_n67.n67_flag_ident <> 'I' THEN
			CALL fl_mostrar_mensaje('El tipo de rubro debe ser de ingreso.', 'exclamation')
			NEXT FIELD n68_cod_rubro
		END IF
		IF rm_n68.n68_cod_tran = 'EG' AND r_n67.n67_flag_ident <> 'E' THEN
			CALL fl_mostrar_mensaje('El tipo de rubro debe ser de egreso.', 'exclamation')
			NEXT FIELD n68_cod_rubro
		END IF
		IF rm_n68.n68_valor = 0 THEN
			CALL fl_mostrar_mensaje('No puede dejar el valor de la transacción en cero.', 'exclamation')
			NEXT FIELD n68_valor
		END IF
		IF rm_n68.n68_num_cheque IS NULL THEN
			IF rm_n68.n68_cod_tran = 'EG' THEN
				CALL fl_mostrar_mensaje('Digite el número del cheque.', 'exclamation')
				NEXT FIELD n68_num_cheque
			END IF
		END IF
		IF rm_n68.n68_numero_cta IS NULL THEN
			IF rm_n68.n68_banco IS NOT NULL OR
			   rm_n68.n68_num_cheque IS NOT NULL
			THEN
				CALL fl_mostrar_mensaje('Digite el número de la cuenta del club.', 'exclamation')
				NEXT FIELD n68_numero_cta
			END IF
		END IF
		IF rm_n68.n68_banco IS NULL THEN
			IF rm_n68.n68_numero_cta IS NOT NULL OR
			   rm_n68.n68_num_cheque IS NOT NULL
			THEN
				CALL fl_mostrar_mensaje('Digite el banco del club.', 'exclamation')
				NEXT FIELD n68_banco
			END IF
		END IF
		IF rm_n68.n68_num_prest IS NOT NULL THEN
			CALL fl_lee_prestamo_club(vg_codcia,
							rm_n68.n68_num_prest)
				RETURNING r_n64.*
			IF rm_n68.n68_valor >
			   (r_n64.n64_val_prest + r_n64.n64_val_interes)
			THEN
				CALL fl_mostrar_mensaje('El valor de esta transacción es mayor que el del préstamo.', 'exclamation')
				NEXT FIELD n68_valor
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION datos_del_prest(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n64		RECORD LIKE rolt064.*

CALL fl_lee_prestamo_club(vg_codcia, rm_n68.n68_num_prest) RETURNING r_n64.*
LET rm_n68.n68_cod_trab = r_n64.n64_cod_trab
CALL fl_lee_trabajador_roles(vg_codcia,	rm_n68.n68_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME rm_n68.n68_cod_trab, r_n30.n30_nombres
IF r_n30.n30_cod_trab <> cod_trab OR rm_n68.n68_beneficiario IS NULL THEN
	LET rm_n68.n68_beneficiario = r_n30.n30_nombres
	DISPLAY BY NAME rm_n68.n68_beneficiario
END IF

END FUNCTION



FUNCTION mostrar_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION mostrar_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n67		RECORD LIKE rolt067.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_n68.* FROM rolt068 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_n68.n68_cod_tran, rm_n68.n68_num_tran, rm_n68.n68_cod_rubro,
		rm_n68.n68_fecha, rm_n68.n68_valor, rm_n68.n68_referencia,
		rm_n68.n68_cod_trab,rm_n68.n68_cod_liqrol, rm_n68.n68_num_prest,
		rm_n68.n68_fecha_ini, rm_n68.n68_fecha_fin, rm_n68.n68_banco,
		rm_n68.n68_numero_cta, rm_n68.n68_num_cheque,
		rm_n68.n68_beneficiario, rm_n68.n68_usuario, rm_n68.n68_fecing
CALL fl_lee_rubros_club(rm_n68.n68_cod_rubro) RETURNING r_n67.*
DISPLAY BY NAME r_n67.n67_nombre
CALL fl_lee_trabajador_roles(vg_codcia, rm_n68.n68_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME r_n30.n30_nombres
CALL fl_lee_proceso_roles(rm_n68.n68_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre
CALL fl_lee_banco_general(rm_n68.n68_banco) RETURNING r_g08.*
DISPLAY BY NAME r_g08.g08_nombre

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 17
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

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

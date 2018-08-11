------------------------------------------------------------------------------
-- Titulo           : cajp101.4gl - Mantenimiento de tipos de formas de pago
-- Elaboracion      : 01-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cajp101 base módulo compañía
-- Ultima Correccion: 20-feb-2002 
-- Motivo Correccion: Se aumentaron los campos j01_compania y j01_aux_cont
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_j01		RECORD LIKE cajt001.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp101.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'cajp101'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE confir		CHAR(6)
DEFINE lin_menu         SMALLINT
DEFINE row_ini          SMALLINT
DEFINE num_rows         SMALLINT
DEFINE num_cols         SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET lin_menu = 0
LET row_ini  = 3  ## (estandar)
LET num_rows = 12 ## (WITH 12 rows)
LET num_cols = 80
IF vg_gui = 0 THEN
        LET lin_menu = 1  ## (standar)
        LET row_ini  = 4  ## (standar)
        LET num_rows = 20 ## (standar)
        LET num_cols = 78 ## (standar maximo columnas)
END IF
OPEN WINDOW w_cajf101_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
		MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_cajf101_1 FROM '../forms/cajf101_1'
ELSE
        OPEN FORM f_cajf101_1 FROM '../forms/cajf101_1c'
END IF
DISPLAY FORM f_cajf101_1
INITIALIZE rm_j01.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
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
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
 	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL bloquear_activar()
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

CALL fl_retorna_usuario()
INITIALIZE rm_j01.* TO NULL
LET rm_j01.j01_compania  = vg_codcia
LET rm_j01.j01_cont_cred = 'C'
LET rm_j01.j01_retencion = 'N'
LET rm_j01.j01_estado    = 'A'
LET rm_j01.j01_usuario   = vg_usuario
LET rm_j01.j01_fecing    = fl_current()
CLEAR tit_estado_caj, n_aux_cont
CALL muestra_estado()
IF vg_gui = 0 THEN
	CALL muestra_contcred(rm_j01.j01_cont_cred)
END IF
CALL leer_datos('I')
IF int_flag THEN
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
LET rm_j01.j01_fecing = fl_current()
INSERT INTO cajt001 VALUES (rm_j01.*)
LET vm_num_rows = vm_num_rows + 1
LET vm_row_current = vm_num_rows
DISPLAY BY NAME rm_j01.j01_fecing
LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
CALL mostrar_registro(vm_r_rows[vm_num_rows])	
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_j01.j01_estado = 'B' THEN
        CALL fl_mensaje_estado_bloqueado()
        RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM cajt001
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_j01.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
UPDATE cajt001
	SET * = rm_j01.*
	WHERE CURRENT OF q_up
COMMIT WORK
CALL fl_mensaje_registro_modificado()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE cod_aux		LIKE cajt001.j01_codigo_pago
DEFINE nom_aux		LIKE cajt001.j01_nombre
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(500)
DEFINE num_reg		INTEGER

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON j01_codigo_pago, j01_nombre, j01_estado,
	j01_cont_cred, j01_retencion, j01_aux_cont
        ON KEY(F1,CONTROL-W)
                IF vg_gui = 0 THEN
                        CALL control_visor_teclas_caracter_1()
                END IF
	ON KEY(F2)
		IF INFIELD(j01_codigo_pago) THEN
			CALL fl_ayuda_forma_pago(vg_codcia, 'T', 'T', 'T')
				RETURNING cod_aux, nom_aux, cont_cred
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO j01_codigo_pago 
				DISPLAY nom_aux TO j01_nombre
			END IF 
		END IF
		IF INFIELD(j01_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_j01.j01_aux_cont = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta, r_b10.b10_descripcion 
					TO j01_aux_cont, n_aux_cont
			END IF
		END IF
		LET int_flag = 0
	BEFORE CONSTRUCT
                IF vg_gui = 1 THEN
			--#CALL dialog.keysetlabel('F1', '')	
			--#CALL dialog.keysetlabel('CONTROL-W', '')	
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
LET query = 'SELECT *, ROWID ',
		' FROM cajt001 ',
		' WHERE j01_compania   = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_j01.*, num_reg
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



FUNCTION leer_datos(flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE r_j01	RECORD LIKE cajt001.*

DEFINE r_b10		RECORD LIKE ctbt010.*

INITIALIZE r_j01.* TO NULL
DISPLAY BY NAME rm_j01.j01_usuario, rm_j01.j01_fecing, rm_j01.j01_estado
LET int_flag = 0
INPUT BY NAME rm_j01.j01_codigo_pago, rm_j01.j01_nombre, rm_j01.j01_aux_cont,
	rm_j01.j01_retencion, rm_j01.j01_cont_cred
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(j01_codigo_pago, j01_nombre, j01_aux_cont,
				 j01_retencion, j01_cont_cred)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				CLEAR FORM
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	BEFORE INPUT
                IF vg_gui = 1 THEN
			--#CALL dialog.keysetlabel('F1', '')
			--#CALL dialog.keysetlabel('CONTROL-W', '')	
		END IF
        ON KEY(F1,CONTROL-W)
                IF vg_gui = 0 THEN
                        CALL control_visor_teclas_caracter_1()
                END IF
	ON KEY(F2)
		IF INFIELD(j01_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_j01.j01_aux_cont = r_b10.b10_cuenta
				DISPLAY BY NAME rm_j01.j01_aux_cont
				DISPLAY r_b10.b10_descripcion 
					TO n_aux_cont
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD j01_codigo_pago
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD j01_codigo_pago
		IF rm_j01.j01_codigo_pago IS NOT NULL THEN
			CALL fl_lee_tipo_pago_caja(vg_codcia,
						rm_j01.j01_codigo_pago,
						rm_j01.j01_cont_cred)
                        	RETURNING r_j01.*
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Código de tipo de pago ya existe.','exclamation')
				NEXT FIELD j01_codigo_pago
			END IF
		ELSE
			CLEAR j01_codigo_pago, j01_nombre
		END IF
	AFTER FIELD j01_aux_cont
		IF rm_j01.j01_aux_cont IS NULL THEN
			CLEAR n_aux_cont
			CONTINUE INPUT
		END IF
		CALL fl_lee_cuenta(vg_codcia, rm_j01.j01_aux_cont)
			RETURNING r_b10.*
		IF r_b10.b10_cuenta IS NULL THEN
			CALL fl_mostrar_mensaje('Cuenta no existe.','exclamation')
			CLEAR n_aux_cont
			NEXT FIELD j01_aux_cont
		END IF
		IF r_b10.b10_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD j01_aux_cont
		END IF
		DISPLAY r_b10.b10_descripcion TO n_aux_cont
	AFTER FIELD j01_cont_cred
		IF vg_gui = 0 THEN
			IF rm_j01.j01_cont_cred IS NOT NULL THEN
				CALL muestra_contcred(rm_j01.j01_cont_cred)
			ELSE
				CLEAR tit_cont_cred
			END IF
		END IF
		IF flag_mant = 'M' THEN
			IF rm_j01.j01_codigo_pago IS NOT NULL THEN
				CALL fl_lee_tipo_pago_caja(vg_codcia,
							rm_j01.j01_codigo_pago,
							rm_j01.j01_cont_cred)
	                        	RETURNING r_j01.*
				IF r_j01.j01_codigo_pago IS NOT NULL THEN
					CALL fl_mostrar_mensaje('Ya existe este codigo de pago con este tipo de pago.','exclamation')
					NEXT FIELD j01_cont_cred
				END IF
			END IF
		END IF
	AFTER INPUT
		IF flag_mant = 'I' THEN
			IF rm_j01.j01_codigo_pago IS NOT NULL THEN
				CALL fl_lee_tipo_pago_caja(vg_codcia,
							rm_j01.j01_codigo_pago,
							rm_j01.j01_cont_cred)
	                        	RETURNING r_j01.*
				IF r_j01.j01_codigo_pago IS NOT NULL THEN
					CALL fl_mostrar_mensaje('Código de tipo de pago ya existe.','exclamation')
					CONTINUE INPUT
				END IF
			ELSE
				CLEAR j01_codigo_pago, j01_nombre
			END IF
		END IF
END INPUT
IF rm_j01.j01_retencion IS NULL THEN
	LET rm_j01.j01_retencion = 'N'
END IF

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
DISPLAY row_current, " de ", num_rows AT 1, 67
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_b10		RECORD LIKE ctbt010.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_j01.* FROM cajt001 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_j01.j01_codigo_pago, rm_j01.j01_nombre, rm_j01.j01_cont_cred,
		rm_j01.j01_retencion, rm_j01.j01_aux_cont, rm_j01.j01_usuario,
		rm_j01.j01_fecing
CALL fl_lee_cuenta(vg_codcia, rm_j01.j01_aux_cont) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO n_aux_cont
CALL muestra_estado()
IF vg_gui = 0 THEN
	CALL muestra_contcred(rm_j01.j01_cont_cred)
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM cajt001
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_j01.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CAll fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
LET int_flag = 1
CALL bloquea_activa_registro()
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		LIKE cajt001.j01_estado
                                                                                
IF rm_j01.j01_estado = 'A' THEN
        DISPLAY 'BLOQUEADO' TO tit_estado_caj
        LET estado = 'B'
END IF
IF rm_j01.j01_estado = 'B' THEN
        DISPLAY 'ACTIVO' TO tit_estado_caj
        LET estado = 'A'
END IF
LET rm_j01.j01_estado = estado
DISPLAY BY NAME rm_j01.j01_estado
UPDATE cajt001 SET j01_estado = estado WHERE CURRENT OF q_ba
                                                                                
END FUNCTION



FUNCTION muestra_estado()

IF rm_j01.j01_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado_caj
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado_caj
END IF
DISPLAY BY NAME rm_j01.j01_estado

END FUNCTION



FUNCTION muestra_contcred(contcred)
DEFINE contcred		CHAR(1)

CASE contcred
	WHEN 'C'
		DISPLAY 'CONTADO' TO tit_cont_cred
	WHEN 'R'
		DISPLAY 'CREDITO' TO tit_cont_cred
	WHEN 'T'
		DISPLAY 'TODOS'   TO tit_cont_cred
	OTHERWISE
		CLEAR j01_cont_cred, tit_cont_cred
END CASE

END FUNCTION


FUNCTION control_visor_teclas_caracter_1()
DEFINE a, fila          INTEGER
                                                                                
CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
LET a = fgl_getkey()
CLOSE WINDOW w_tf
                                                                                
END FUNCTION

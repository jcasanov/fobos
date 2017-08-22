--------------------------------------------------------------------------------
-- Titulo               : genp143.4gl -- Mantenimiento de Conf. Impuestos
-- Elaboracion          : 06-Ago-2007
-- Autor                : NPC
-- Formato de Ejecucion : fglrun genp143 Base Modulo Compania
-- Ultima Correcion     : 
-- Motivo Correccion    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_g58   	RECORD LIKE gent058.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp143.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'genp143'
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
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_genf143_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_genf143_1 FROM '../forms/genf143_1'
ELSE
	OPEN FORM f_genf143_1 FROM '../forms/genf143_1c'
END IF
DISPLAY FORM f_genf143_1

INITIALIZE rm_g58.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
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
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
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
        COMMAND KEY('B') 'Bloquear/Activar' 'Activa o Bloquea registro actual. '
		CALL control_bloquear_activar()
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
DEFINE r_g02		RECORD LIKE gent002.*

CLEAR FORM
INITIALIZE rm_g58.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_g58.g58_compania   = vg_codcia
LET rm_g58.g58_localidad  = vg_codloc
LET rm_g58.g58_estado     = 'A'
LET rm_g58.g58_tipo_impto = 'I'
LET rm_g58.g58_tipo       = 'V'
LET rm_g58.g58_impto_sist = 'N'
LET rm_g58.g58_fecing     = fl_current()
LET rm_g58.g58_usuario    = vg_usuario
CALL fl_lee_localidad(rm_g58.g58_compania, rm_g58.g58_localidad)
	RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO tit_localidad
DISPLAY BY NAME rm_g58.g58_fecing, rm_g58.g58_usuario
CALL muestra_estado()
CALL lee_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
INSERT INTO gent058 VALUES (rm_g58.*)
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
LET vm_row_current         = vm_num_rows
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF rm_g58.g58_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM gent058 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_g58.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
UPDATE gent058 SET * = rm_g58.* WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(600)
DEFINE query		CHAR(1200)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g02		RECORD LIKE gent002.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON g58_estado, g58_localidad, g58_porc_impto,
	g58_tipo, g58_tipo_impto, g58_desc_impto, g58_desc_abr, g58_impto_sist,
	g58_aux_cont, g58_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(g58_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				DISPLAY r_g02.g02_localidad TO g58_localidad
				DISPLAY r_g02.g02_nombre    TO tit_localidad
			END IF
		END IF
		IF INFIELD(g58_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO g58_aux_cont
				DISPLAY r_b10.b10_descripcion TO tit_aux_cont
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
	RETURN
END IF
LET query = 'SELECT gent058.*, gent058.ROWID ',
		' FROM gent058 ',
		' WHERE g58_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2, 3, 4 '
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_g58.*, vm_r_rows[vm_num_rows]
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
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g58		RECORD LIKE gent058.*
DEFINE resp      	CHAR(6)
DEFINE resul		SMALLINT
DEFINE cuantos		INTEGER

LET int_flag = 0 
INPUT BY NAME rm_g58.g58_localidad, rm_g58.g58_porc_impto, rm_g58.g58_tipo,
	rm_g58.g58_tipo_impto, rm_g58.g58_desc_impto, rm_g58.g58_desc_abr,
	rm_g58.g58_impto_sist, rm_g58.g58_aux_cont
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_g58.g58_localidad, rm_g58.g58_porc_impto,
				 rm_g58.g58_tipo, rm_g58.g58_tipo_impto,
				 rm_g58.g58_desc_impto, rm_g58.g58_desc_abr,
				 rm_g58.g58_impto_sist, rm_g58.g58_aux_cont)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				IF vm_flag_mant = 'I' THEN
					CLEAR FORM
				END IF
				RETURN
			END IF
		ELSE
			IF vm_flag_mant = 'I' THEN
				CLEAR FORM
			END IF
			RETURN
		END IF       	
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF vm_flag_mant = 'I' THEN
			IF INFIELD(g58_localidad) THEN
				CALL fl_ayuda_localidad(vg_codcia)
					RETURNING r_g02.g02_localidad,
						  r_g02.g02_nombre
				IF r_g02.g02_localidad IS NOT NULL THEN
					LET rm_g58.g58_localidad =
							r_g02.g02_localidad
					DISPLAY r_g02.g02_localidad
						TO g58_localidad
					DISPLAY r_g02.g02_nombre
						TO tit_localidad
				END IF
			END IF
		END IF
		IF INFIELD(g58_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_g58.g58_aux_cont = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO g58_aux_cont
				DISPLAY r_b10.b10_descripcion TO tit_aux_cont
			END IF
		END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD g58_localidad
		IF vm_flag_mant = 'M' THEN
			LET r_g02.g02_localidad = rm_g58.g58_localidad
		END IF
	BEFORE FIELD g58_porc_impto
		IF vm_flag_mant = 'M' THEN
			LET r_g58.g58_porc_impto = rm_g58.g58_porc_impto
		END IF
	BEFORE FIELD g58_tipo_impto
		IF vm_flag_mant = 'M' THEN
			LET r_g58.g58_tipo_impto = rm_g58.g58_tipo_impto
		END IF
	BEFORE FIELD g58_tipo
		IF vm_flag_mant = 'M' THEN
			LET r_g58.g58_tipo = rm_g58.g58_tipo
		END IF
	AFTER FIELD g58_localidad
		IF vm_flag_mant = 'M' THEN
			LET rm_g58.g58_localidad = r_g02.g02_localidad
			CALL fl_lee_localidad(rm_g58.g58_compania,
						rm_g58.g58_localidad)
				RETURNING r_g02.*
			DISPLAY r_g02.g02_localidad TO g58_localidad
			DISPLAY r_g02.g02_nombre    TO tit_localidad
			CONTINUE INPUT
		END IF
		IF rm_g58.g58_localidad IS NULL THEN
			LET rm_g58.g58_localidad = vg_codloc
		END IF
		CALL fl_lee_localidad(rm_g58.g58_compania, rm_g58.g58_localidad)
			RETURNING r_g02.*
		IF r_g02.g02_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
			NEXT FIELD g58_localidad
		END IF
		DISPLAY r_g02.g02_nombre TO tit_localidad
		IF r_g02.g02_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD g58_localidad
		END IF
	 AFTER FIELD g58_porc_impto
		IF vm_flag_mant = 'M' THEN
			LET rm_g58.g58_porc_impto = r_g58.g58_porc_impto 
			DISPLAY BY NAME rm_g58.g58_porc_impto
			CONTINUE INPUT
		END IF
	 AFTER FIELD g58_tipo_impto
		IF vm_flag_mant = 'M' THEN
			LET rm_g58.g58_tipo_impto = r_g58.g58_tipo_impto 
			DISPLAY BY NAME rm_g58.g58_tipo_impto
			CONTINUE INPUT
		END IF
	 AFTER FIELD g58_tipo
		IF vm_flag_mant = 'M' THEN
			LET rm_g58.g58_tipo = r_g58.g58_tipo 
			DISPLAY BY NAME rm_g58.g58_tipo
			CONTINUE INPUT
		END IF
	AFTER FIELD g58_aux_cont
		IF rm_g58.g58_aux_cont IS NOT NULL THEN
			CALL validar_cuenta(rm_g58.g58_aux_cont, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD g58_aux_cont
			END IF
		ELSE
			CLEAR tit_aux_cont
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			CALL fl_lee_porc_impto(vg_codcia, rm_g58.g58_localidad,
						rm_g58.g58_tipo_impto,
						rm_g58.g58_porc_impto,
						rm_g58.g58_tipo)
				RETURNING r_g58.*
			IF r_g58.g58_compania IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe configurado impuesto.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF rm_g58.g58_impto_sist = 'S' THEN
			SELECT COUNT(*) INTO cuantos
				FROM gent058
				WHERE g58_compania    = vg_codcia
				  AND g58_localidad   = rm_g58.g58_localidad
				  AND g58_tipo_impto  = rm_g58.g58_tipo_impto
				  AND g58_porc_impto <> rm_g58.g58_porc_impto
				  AND g58_tipo        = rm_g58.g58_tipo
				  AND g58_impto_sist  = 'S'
			IF cuantos > 0 THEN
				CALL fl_mostrar_mensaje('El impuesto predeterminado ya esta asignado en el sistema.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cuenta(aux_cont, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE flag		SMALLINT
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL  THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1 DISPLAY r_cta.b10_descripcion TO tit_aux_cont
END CASE
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



FUNCTION control_bloquear_activar()
DEFINE confir		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM gent058 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_g58.*
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
CALL bloquea_activa_registro()
COMMIT WORK
CALL fl_mostrar_mensaje('Se cambió el estado de esta configuracion Ok.', 'info')

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		LIKE gent058.g58_estado

IF rm_g58.g58_estado = 'A' THEN
	LET estado = 'B'
END IF
IF rm_g58.g58_estado = 'B' THEN
	LET estado = 'A'
END IF
LET rm_g58.g58_estado = estado
UPDATE gent058 SET g58_estado = estado WHERE CURRENT OF q_ba
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_estado()

IF rm_g58.g58_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
END IF
IF rm_g58.g58_estado = 'B' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
DISPLAY BY NAME rm_g58.g58_estado

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
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_b10		RECORD LIKE ctbt010.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_g58.* FROM gent058 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_g58.g58_estado, rm_g58.g58_localidad, rm_g58.g58_porc_impto,
		rm_g58.g58_tipo, rm_g58.g58_tipo_impto, rm_g58.g58_desc_impto,
		rm_g58.g58_desc_abr, rm_g58.g58_impto_sist, rm_g58.g58_aux_cont,
		rm_g58.g58_usuario, rm_g58.g58_fecing
CALL muestra_estado()
CALL fl_lee_localidad(rm_g58.g58_compania, rm_g58.g58_localidad)
	RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO tit_localidad
CALL fl_lee_cuenta(vg_codcia, rm_g58.g58_aux_cont) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_aux_cont
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION


                                                                                
FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

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

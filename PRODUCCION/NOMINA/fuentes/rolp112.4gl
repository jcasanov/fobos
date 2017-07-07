--------------------------------------------------------------------------------
-- Titulo               : rolp112.4gl -- Mantenimiento de Conf. Adic. Contable
-- Elaboración          : 09-Feb-2007
-- Autor                : NPC
-- Formato de Ejecución : fglrun rolp112 Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_n56   	RECORD LIKE rolt056.*
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp112.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp112'
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
OPEN WINDOW w_rolf112_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf112_1 FROM '../forms/rolf112_1'
ELSE
	OPEN FORM f_rolf112_1 FROM '../forms/rolf112_1c'
END IF
DISPLAY FORM f_rolf112_1
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compañía.','stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_n56.* TO NULL
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

CLEAR FORM
INITIALIZE rm_n56.* TO NULL
LET vm_flag_mant        = 'I'
LET rm_n56.n56_compania = vg_codcia
LET rm_n56.n56_estado   = 'A'
LET rm_n56.n56_fecing   = CURRENT
LET rm_n56.n56_usuario  = vg_usuario
DISPLAY BY NAME rm_n56.n56_fecing, rm_n56.n56_usuario
CALL muestra_estado()
CALL lee_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
INSERT INTO rolt056 VALUES (rm_n56.*)
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

IF rm_n56.n56_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt056 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n56.*
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
UPDATE rolt056 SET * = rm_n56.* WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1500)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE nombre		LIKE rolt030.n30_nombres

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON n56_estado, n56_proceso, n56_cod_trab,
	n56_cod_depto, n56_aux_val_vac, n56_aux_val_adi, n56_aux_otr_ing,
	n56_aux_iess, n56_aux_otr_egr, n56_aux_banco, n56_usuario, n56_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n56_proceso) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				DISPLAY r_n03.n03_proceso TO n56_proceso
				DISPLAY BY NAME r_n03.n03_nombre
			END IF
		END IF
		IF INFIELD(n56_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				DISPLAY r_n30.n30_cod_trab TO n56_cod_trab
				DISPLAY BY NAME r_n30.n30_nombres
			END IF
		END IF
		IF INFIELD(n56_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
				RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
			IF r_g34.g34_cod_depto IS NOT NULL THEN
				DISPLAY r_g34.g34_cod_depto TO n56_cod_depto
				DISPLAY BY NAME r_g34.g34_nombre
			END IF
		END IF
		IF INFIELD(n56_aux_val_vac) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta TO n56_aux_val_vac
				DISPLAY r_b10.b10_descripcion TO tit_aux_val_vac
			END IF
		END IF
		IF INFIELD(n56_aux_val_adi) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta TO n56_aux_val_adi
				DISPLAY r_b10.b10_descripcion TO tit_aux_val_adi
			END IF
		END IF
		IF INFIELD(n56_aux_otr_ing) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta TO n56_aux_otr_ing
				DISPLAY r_b10.b10_descripcion TO tit_aux_otr_ing
			END IF
		END IF
		IF INFIELD(n56_aux_iess) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta TO n56_aux_iess
				DISPLAY r_b10.b10_descripcion TO tit_aux_iess
			END IF
		END IF
		IF INFIELD(n56_aux_otr_egr) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta TO n56_aux_otr_egr
				DISPLAY r_b10.b10_descripcion TO tit_aux_otr_egr
			END IF
		END IF
		IF INFIELD(n56_aux_banco) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta TO n56_aux_banco
				DISPLAY r_b10.b10_descripcion TO tit_aux_banco
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
LET query = 'SELECT rolt056.*, rolt056.ROWID, rolt030.n30_nombres ',
		' FROM rolt056, rolt030 ',
		' WHERE n56_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		'   AND n30_compania = n56_compania ',
		'   AND n30_cod_trab = n56_cod_trab ',
		' ORDER BY 2, n30_nombres '
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_n56.*, vm_r_rows[vm_num_rows], nombre
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
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n56		RECORD LIKE rolt056.*
DEFINE resp      	CHAR(6)
DEFINE resul		SMALLINT
DEFINE cuantos		INTEGER

LET int_flag = 0 
INPUT BY NAME rm_n56.n56_proceso, rm_n56.n56_cod_trab, rm_n56.n56_cod_depto,
	rm_n56.n56_aux_val_vac, rm_n56.n56_aux_val_adi, rm_n56.n56_aux_otr_ing,
	rm_n56.n56_aux_iess, rm_n56.n56_aux_otr_egr, rm_n56.n56_aux_banco
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n56.n56_proceso, rm_n56.n56_cod_trab,
				 rm_n56.n56_cod_depto, rm_n56.n56_aux_val_vac,
				 rm_n56.n56_aux_val_adi, rm_n56.n56_aux_otr_ing,
				 rm_n56.n56_aux_iess, rm_n56.n56_aux_otr_egr,
				 rm_n56.n56_aux_banco)
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
		IF INFIELD(n56_proceso) THEN
			IF vm_flag_mant = 'M' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n56.n56_proceso = r_n03.n03_proceso
				DISPLAY r_n03.n03_proceso TO n56_proceso
				DISPLAY BY NAME r_n03.n03_nombre
			END IF
		END IF
		IF INFIELD(n56_cod_trab) THEN
			IF vm_flag_mant = 'M' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_n56.n56_cod_trab = r_n30.n30_cod_trab
				DISPLAY r_n30.n30_cod_trab TO n56_cod_trab
				DISPLAY BY NAME r_n30.n30_nombres
			END IF
		END IF
		IF INFIELD(n56_aux_val_vac) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n56.n56_aux_val_vac = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO n56_aux_val_vac
				DISPLAY r_b10.b10_descripcion TO tit_aux_val_vac
			END IF
		END IF
		IF INFIELD(n56_aux_val_adi) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n56.n56_aux_val_adi = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO n56_aux_val_adi
				DISPLAY r_b10.b10_descripcion TO tit_aux_val_adi
			END IF
		END IF
		IF INFIELD(n56_aux_otr_ing) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n56.n56_aux_otr_ing = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO n56_aux_otr_ing
				DISPLAY r_b10.b10_descripcion TO tit_aux_otr_ing
			END IF
		END IF
		IF INFIELD(n56_aux_iess) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n56.n56_aux_iess = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO n56_aux_iess
				DISPLAY r_b10.b10_descripcion TO tit_aux_iess
			END IF
		END IF
		IF INFIELD(n56_aux_otr_egr) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n56.n56_aux_otr_egr = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO n56_aux_otr_egr
				DISPLAY r_b10.b10_descripcion TO tit_aux_otr_egr
			END IF
		END IF
		IF INFIELD(n56_aux_banco) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_n56.n56_aux_banco = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO n56_aux_banco
				DISPLAY r_b10.b10_descripcion TO tit_aux_banco
			END IF
		END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD n56_proceso
		IF vm_flag_mant = 'M' THEN
			LET r_n03.n03_proceso = rm_n56.n56_proceso
		END IF
	BEFORE FIELD n56_cod_trab
		IF vm_flag_mant = 'M' THEN
			LET r_n30.n30_cod_trab = rm_n56.n56_cod_trab
		END IF
	 AFTER FIELD n56_proceso
		IF vm_flag_mant = 'M' THEN
			LET rm_n56.n56_proceso = r_n03.n03_proceso 
			CALL fl_lee_proceso_roles(rm_n56.n56_proceso)
				RETURNING r_n03.*
			DISPLAY BY NAME rm_n56.n56_proceso, r_n03.n03_nombre
			CONTINUE INPUT
		END IF
		IF rm_n56.n56_proceso IS NOT NULL THEN
			CALL fl_lee_proceso_roles(rm_n56.n56_proceso)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('El Proceso no existe en la Companía.', 'exclamation')
                        	NEXT FIELD n56_proceso
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			IF r_n03.n03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                        	NEXT FIELD n56_proceso
			END IF
		ELSE
			CLEAR n03_nombre
		END IF
	 AFTER FIELD n56_cod_trab
		IF vm_flag_mant = 'M' THEN
			LET rm_n56.n56_cod_trab = r_n30.n30_cod_trab 
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n56.n56_cod_trab)
				RETURNING r_n30.*
			DISPLAY BY NAME rm_n56.n56_cod_trab, r_n30.n30_nombres
			CONTINUE INPUT
		END IF
		IF rm_n56.n56_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n56.n56_cod_trab)
				RETURNING r_n30.*
			IF r_n30.n30_cod_trab IS NULL THEN
				CALL fl_mostrar_mensaje('El Código de Empleado no existe en la Companía.', 'exclamation')
                        	NEXT FIELD n56_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
			IF r_n30.n30_estado <> 'A' AND
			   rm_n56.n56_proceso <> 'UT'
			THEN
				CALL fl_mensaje_estado_bloqueado()
                        	NEXT FIELD n56_cod_trab
			END IF
			LET rm_n56.n56_cod_depto = r_n30.n30_cod_depto
			CALL fl_lee_departamento(vg_codcia,rm_n56.n56_cod_depto)
				RETURNING r_g34.*
			DISPLAY BY NAME rm_n56.n56_cod_depto, r_g34.g34_nombre
		ELSE
			CLEAR n30_nombres, n56_cod_depto, g34_nombre
		END IF
	AFTER FIELD n56_aux_val_vac
		IF rm_n56.n56_aux_val_vac IS NOT NULL THEN
			CALL validar_cuenta(rm_n56.n56_aux_val_vac, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD n56_aux_val_vac
			END IF
		ELSE
			CLEAR tit_aux_val_vac
		END IF
	AFTER FIELD n56_aux_val_adi
		IF rm_n56.n56_aux_val_adi IS NOT NULL THEN
			CALL validar_cuenta(rm_n56.n56_aux_val_adi, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD n56_aux_val_adi
			END IF
		ELSE
			CLEAR tit_aux_val_adi
		END IF
	AFTER FIELD n56_aux_otr_ing
		IF rm_n56.n56_aux_otr_ing IS NOT NULL THEN
			CALL validar_cuenta(rm_n56.n56_aux_otr_ing, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD n56_aux_otr_ing
			END IF
		ELSE
			CLEAR tit_aux_otr_ing
		END IF
	AFTER FIELD n56_aux_iess
		IF rm_n56.n56_aux_iess IS NOT NULL THEN
			CALL validar_cuenta(rm_n56.n56_aux_iess, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD n56_aux_iess
			END IF
		ELSE
			CLEAR tit_aux_iess
		END IF
	AFTER FIELD n56_aux_otr_egr
		IF rm_n56.n56_aux_otr_egr IS NOT NULL THEN
			CALL validar_cuenta(rm_n56.n56_aux_otr_egr, 5)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD n56_aux_otr_egr
			END IF
		ELSE
			CLEAR tit_aux_otr_egr
		END IF
	AFTER FIELD n56_aux_banco
		IF rm_n56.n56_aux_banco IS NOT NULL THEN
			CALL validar_cuenta(rm_n56.n56_aux_banco, 6)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD n56_aux_banco
			END IF
		ELSE
			CLEAR tit_aux_banco
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			INITIALIZE r_n56.* TO NULL
			SELECT * INTO r_n56.*
				FROM rolt056
				WHERE n56_compania  = vg_codcia
				  AND n56_proceso   = rm_n56.n56_proceso
				  AND n56_cod_depto = rm_n56.n56_cod_depto
				  AND n56_cod_trab  = rm_n56.n56_cod_trab
			IF r_n56.n56_compania IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe configurado un registro para este empleado en este proceso.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		{--
		SELECT COUNT(*) INTO cuantos
			FROM gent009
			WHERE g09_compania = vg_codcia
			  AND g09_estado   = 'A'
			  AND g09_aux_cont = rm_n56.n56_aux_banco
		IF cuantos = 0 THEN
			CALL fl_mostrar_mensaje('La cuenta del banco debe ser una cuenta contable bancaria.', 'exclamation')
			NEXT FIELD n56_aux_banco
		END IF
		--}
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
	WHEN 1
		DISPLAY r_cta.b10_descripcion TO tit_aux_val_vac
	WHEN 2
		DISPLAY r_cta.b10_descripcion TO tit_aux_val_adi
	WHEN 3
		DISPLAY r_cta.b10_descripcion TO tit_aux_otr_ing
	WHEN 4
		DISPLAY r_cta.b10_descripcion TO tit_aux_iess
	WHEN 5
		DISPLAY r_cta.b10_descripcion TO tit_aux_otr_egr
	WHEN 6
		DISPLAY r_cta.b10_descripcion TO tit_aux_banco
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
	SELECT * FROM rolt056 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_n56.*
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
DEFINE estado		LIKE rolt056.n56_estado

IF rm_n56.n56_estado = 'A' THEN
	LET estado = 'B'
END IF
IF rm_n56.n56_estado = 'B' THEN
	LET estado = 'A'
END IF
LET rm_n56.n56_estado = estado
UPDATE rolt056 SET n56_estado = estado WHERE CURRENT OF q_ba
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_estado()

IF rm_n56.n56_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
END IF
IF rm_n56.n56_estado = 'B' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
DISPLAY BY NAME rm_n56.n56_estado

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
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_n56.* FROM rolt056 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_n56.n56_estado, rm_n56.n56_proceso, rm_n56.n56_cod_trab,
	rm_n56.n56_cod_depto, rm_n56.n56_aux_val_vac, rm_n56.n56_aux_val_adi,
	rm_n56.n56_aux_otr_ing, rm_n56.n56_aux_iess, rm_n56.n56_aux_otr_egr,
	rm_n56.n56_aux_banco, rm_n56.n56_usuario, rm_n56.n56_fecing
CALL muestra_estado()
CALL fl_lee_proceso_roles(rm_n56.n56_proceso) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre
CALL fl_lee_trabajador_roles(vg_codcia, rm_n56.n56_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME r_n30.n30_nombres
CALL fl_lee_departamento(vg_codcia, rm_n56.n56_cod_depto)
	RETURNING r_g34.*
DISPLAY BY NAME r_g34.g34_nombre
CALL fl_lee_cuenta(vg_codcia, rm_n56.n56_aux_val_vac) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_aux_val_vac
CALL fl_lee_cuenta(vg_codcia, rm_n56.n56_aux_val_adi) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_aux_val_adi
CALL fl_lee_cuenta(vg_codcia, rm_n56.n56_aux_otr_ing) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_aux_otr_ing
CALL fl_lee_cuenta(vg_codcia, rm_n56.n56_aux_iess) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_aux_iess
CALL fl_lee_cuenta(vg_codcia, rm_n56.n56_aux_otr_egr) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_aux_otr_egr
CALL fl_lee_cuenta(vg_codcia, rm_n56.n56_aux_banco) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_aux_banco
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

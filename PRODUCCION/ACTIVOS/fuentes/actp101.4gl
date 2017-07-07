-------------------------------------------------------------------------------
-- Titulo               : actp101.4gl -- Mantenimiento Grupos de Activos Fijos
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  actp101.4gl base GE (compañía) 
-- Ultima Correción     : 02-jun-2003
-- Motivo Corrección    : (RCA) Revision y Cooreccion Aceros
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_last_lvl		LIKE ctbt001.b01_nivel
DEFINE rm_a01			RECORD LIKE actt001.*
DEFINE activo 			ARRAY[1000] OF INTEGER 
DEFINE vm_indice		INTEGER
DEFINE vm_num_rows		INTEGER      
DEFINE vm_max_rows		INTEGER
DEFINE vm_programa		VARCHAR(12)
DEFINE vm_flag_mant		CHAR(1)
DEFINE vm_calculo		CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp101.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
        CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
        EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp101'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000

OPEN WINDOW w_actf101_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST - 1)

OPEN FORM f_actf101_1 FROM '../forms/actf101_1'
DISPLAY FORM f_actf101_1
INITIALIZE rm_a01.* TO NULL

INITIALIZE vm_last_lvl TO NULL
SELECT MAX(b01_nivel) INTO vm_last_lvl FROM ctbt001 
IF vm_last_lvl IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado los niveles de cuenta.', 'exclamation')
	EXIT PROGRAM
END IF

LET vm_num_rows = 0
LET vm_indice   = 0
CALL muestra_contadores()
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
		IF vm_indice > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_indice = vm_num_rows THEN
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
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_indice <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_indice > 0 THEN
			CALL lee_muestra_registro(activo[vm_indice])
		END IF

	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_indice < vm_num_rows THEN
			LET vm_indice = vm_indice + 1 
		END IF	

		CALL lee_muestra_registro(activo[vm_indice])
		IF vm_indice = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF

	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_indice > 1 THEN
			LET vm_indice = vm_indice - 1 
		END IF
		CALL lee_muestra_registro(activo[vm_indice])
		IF vm_indice = 1 THEN
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
CLOSE WINDOW w_actf101_1

END FUNCTION



FUNCTION control_consulta()
DEFINE codigo		LIKE actt001.a01_grupo_act
DEFINE nombre		LIKE actt001.a01_nombre
DEFINE cuenta    	LIKE ctbt010.b10_cuenta
DEFINE descripcion  	LIKE ctbt010.b10_descripcion
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE rm_a01.* TO NULL
CONSTRUCT BY NAME expr_sql ON a01_grupo_act, a01_nombre, a01_depreciable,
	a01_anos_util, a01_porc_deprec, a01_aux_activo, a01_aux_reexpr,
	a01_aux_dep_act, a01_aux_dep_reex, a01_aux_pago, a01_paga_iva,
	a01_aux_iva, a01_aux_venta, a01_aux_gasto, a01_aux_transf, a01_usuario,
	a01_fecing

	ON KEY(INTERRUPT)
		CLEAR FORM
		LET int_flag = 1
		EXIT CONSTRUCT

	ON KEY(F2)
		IF INFIELD(a01_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
			     RETURNING codigo, nombre
			IF codigo IS NOT NULL THEN
				LET rm_a01.a01_grupo_act = codigo
				LET rm_a01.a01_nombre = nombre
				DISPLAY BY NAME rm_a01.a01_grupo_act,	
				rm_a01.a01_nombre, rm_a01.a01_depreciable,
                                rm_a01.a01_anos_util, 
				rm_a01.a01_porc_deprec,
				rm_a01.a01_aux_activo, 
				rm_a01.a01_aux_reexpr,
	                        rm_a01.a01_aux_dep_act,
				rm_a01.a01_aux_dep_reex,
				rm_a01.a01_aux_pago,
				rm_a01.a01_paga_iva,
				rm_a01.a01_aux_iva,
				rm_a01.a01_aux_venta,
				rm_a01.a01_aux_gasto,
				rm_a01.a01_aux_transf,
				rm_a01.a01_usuario,
				rm_a01.a01_fecing
			END IF 
			LET int_flag = 0
		END IF
	

		IF INFIELD(a01_aux_activo) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_activo = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_activo
				DISPLAY descripcion TO descripcion1
			END IF 
			LET int_flag = 0
		END IF
	

		IF INFIELD(a01_aux_reexpr) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_reexpr = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_reexpr
				DISPLAY descripcion TO descripcion2
			END IF
			LET int_flag = 0 
		END IF 


		IF INFIELD(a01_aux_dep_act) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_dep_act = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_dep_act
				DISPLAY descripcion TO descripcion3
			END IF 
			LET int_flag = 0
		END IF 


		IF INFIELD(a01_aux_dep_reex) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_dep_reex = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_dep_reex
				DISPLAY descripcion TO descripcion4
			END IF 
			LET int_flag = 0
		END IF


		IF INFIELD(a01_aux_pago) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_pago = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_pago
				DISPLAY descripcion TO descripcion5
			END IF 
			LET int_flag = 0
		END IF


		IF INFIELD(a01_aux_iva) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_iva = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_iva
				DISPLAY descripcion TO descripcion6
			END IF 
			LET int_flag = 0
		END IF


		IF INFIELD(a01_aux_venta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_venta = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_venta
				DISPLAY descripcion TO descripcion7
			END IF 
			LET int_flag = 0
		END IF


		IF INFIELD(a01_aux_gasto) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_gasto = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_gasto
				DISPLAY descripcion TO descripcion8
			END IF 
			LET int_flag = 0
		END IF

		IF INFIELD(a01_aux_transf) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_transf = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_transf
				DISPLAY descripcion TO descripcion9
			END IF 
			LET int_flag = 0
		END IF


END CONSTRUCT

IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(activo[vm_indice])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		' FROM actt001 ',
		' WHERE a01_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2 '
PREPARE cons FROM query
DECLARE q_act CURSOR FOR cons
LET vm_num_rows = 1

FOREACH q_act INTO rm_a01.*, activo[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_indice = 0
	CALL muestra_contadores()
        CLEAR FORM
        RETURN
END IF
LET vm_indice = 1
CALL lee_muestra_registro(activo[vm_indice])

END FUNCTION



FUNCTION control_ingreso()
DEFINE maximo SMALLINT

CLEAR FORM
INITIALIZE rm_a01.* TO NULL
LET rm_a01.a01_compania    = vg_codcia
LET rm_a01.a01_depreciable = 'N'
LET rm_a01.a01_paga_iva    = 'S'
LET rm_a01.a01_usuario     = vg_usuario
LET rm_a01.a01_fecing      = CURRENT
LET vm_flag_mant           = 'I'
LET vm_calculo             = 'N'
DISPLAY BY NAME rm_a01.a01_depreciable, rm_a01.a01_paga_iva, rm_a01.a01_usuario,
		rm_a01.a01_fecing
CALL lee_datos()
IF NOT int_flag THEN
	SELECT MAX(a01_grupo_act) INTO maximo FROM actt001 
		WHERE a01_compania = vg_codcia
	IF maximo IS NULL THEN
		LET maximo  = 0
	END IF
	LET rm_a01.a01_grupo_act = maximo + 1 
	LET rm_a01.a01_fecing  = CURRENT
	INSERT INTO actt001 VALUES (rm_a01.*) 
	DISPLAY BY NAME rm_a01.a01_grupo_act,	
			rm_a01.a01_nombre, 
			rm_a01.a01_depreciable,
                	rm_a01.a01_anos_util, 
			rm_a01.a01_porc_deprec,
			rm_a01.a01_aux_activo, 
			rm_a01.a01_aux_reexpr,
	        	rm_a01.a01_aux_dep_act,
			rm_a01.a01_aux_dep_reex,
			rm_a01.a01_aux_pago,
			rm_a01.a01_paga_iva,
			rm_a01.a01_aux_iva,
			rm_a01.a01_aux_venta,
			rm_a01.a01_aux_gasto,
			rm_a01.a01_aux_transf,
			rm_a01.a01_usuario,
			rm_a01.a01_fecing

	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET activo[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_indice = vm_num_rows
	CALL muestra_contadores()
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(activo[vm_indice])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

LET vm_flag_mant = 'M'

WHENEVER ERROR CONTINUE
BEGIN WORK

DECLARE q_up CURSOR FOR 
	SELECT * FROM actt001 WHERE ROWID = activo[vm_indice]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_a01.*

WHENEVER ERROR STOP
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
RETURN
END IF

LET vm_calculo         = 'N'
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE actt001 SET * = rm_a01.* WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(activo[vm_indice])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE cuenta    	LIKE ctbt010.b10_cuenta
DEFINE descripcion	LIKE ctbt010.b10_descripcion
DEFINE porc_deprec	LIKE actt001.a01_porc_deprec
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_a01.a01_grupo_act, rm_a01.a01_nombre,
	rm_a01.a01_depreciable, rm_a01.a01_anos_util, vm_calculo,
	rm_a01.a01_porc_deprec, rm_a01.a01_aux_activo,
	rm_a01.a01_aux_reexpr, rm_a01.a01_aux_dep_act,
	rm_a01.a01_aux_dep_reex, rm_a01.a01_aux_pago, rm_a01.a01_paga_iva,
	rm_a01.a01_aux_iva, rm_a01.a01_aux_venta, rm_a01.a01_aux_gasto,
	rm_a01.a01_aux_transf, rm_a01.a01_usuario, rm_a01.a01_fecing 

	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(a01_grupo_act, a01_nombre, a01_depreciable,
				 a01_anos_util, a01_porc_deprec, vm_calculo,
				 a01_aux_activo, a01_aux_reexpr,a01_aux_dep_act,
				 a01_aux_dep_reex, a01_aux_pago, a01_paga_iva,
				 a01_aux_iva, a01_aux_venta, a01_aux_gasto,
				 a01_aux_transf, a01_usuario, a01_fecing)
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

	ON KEY(F2)
		IF INFIELD(a01_aux_activo) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_activo = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_activo
				DISPLAY descripcion TO descripcion1
			END IF 
		END IF

		IF INFIELD(a01_aux_reexpr) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_reexpr = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_reexpr
				DISPLAY descripcion TO descripcion2
			END IF
		END IF 

		IF INFIELD(a01_aux_dep_act) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_dep_act = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_dep_act
				DISPLAY descripcion TO descripcion3
			END IF 
		END IF 

		IF INFIELD(a01_aux_dep_reex) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_dep_reex = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_dep_reex
				DISPLAY descripcion TO descripcion4
			END IF 
		END IF

		IF INFIELD(a01_aux_pago) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_pago = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_pago
				DISPLAY descripcion TO descripcion5
			END IF 
		END IF

		IF INFIELD(a01_aux_iva) THEN
			IF rm_a01.a01_paga_iva = 'N' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_iva = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_iva
				DISPLAY descripcion TO descripcion6
			END IF 
		END IF

		IF INFIELD(a01_aux_venta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_venta = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_venta
				DISPLAY descripcion TO descripcion7
			END IF 
		END IF

		IF INFIELD(a01_aux_gasto) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_gasto = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_gasto
				DISPLAY descripcion TO descripcion8
			END IF 
		END IF

		IF INFIELD(a01_aux_transf) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_last_lvl) 
				RETURNING cuenta, descripcion
			IF cuenta IS NOT NULL THEN
				LET rm_a01.a01_aux_transf = cuenta
				DISPLAY BY NAME rm_a01.a01_aux_transf
				DISPLAY descripcion TO descripcion9
			END IF 
			LET int_flag = 0
		END IF

		LET int_flag = 0


	AFTER FIELD a01_nombre
		IF vm_flag_mant = 'M' THEN
			SELECT a01_nombre
				FROM actt001
				WHERE a01_compania  = vg_codcia
				  AND a01_nombre    = rm_a01.a01_nombre
				  AND ROWID        <> activo[vm_indice]
		ELSE
			SELECT a01_nombre
				FROM actt001
				WHERE a01_compania  = vg_codcia
				  AND a01_nombre    = rm_a01.a01_nombre
		END IF
		IF STATUS <> NOTFOUND THEN
			CALL fl_mostrar_mensaje('El nombre esta repetido', 'info')
			NEXT FIELD a01_nombre
		END IF


        AFTER FIELD a01_anos_util
		IF rm_a01.a01_depreciable = 'S'  THEN
			LET rm_a01.a01_porc_deprec = 
				(100/rm_a01.a01_anos_util)
				DISPLAY BY NAME rm_a01.a01_porc_deprec
			
		ELSE
			LET rm_a01.a01_anos_util = 9999
			LET rm_a01.a01_porc_deprec = 0.0
			DISPLAY BY NAME rm_a01.a01_anos_util, 
					rm_a01.a01_porc_deprec
			
		END IF


	AFTER FIELD a01_aux_activo
		IF rm_a01.a01_aux_activo IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_a01.a01_aux_activo,
				1)
			THEN
				NEXT FIELD a01_aux_activo
			END IF
		ELSE
			CLEAR descripcion1
		END IF

	AFTER FIELD a01_aux_reexpr
		IF rm_a01.a01_aux_reexpr IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_a01.a01_aux_reexpr,
				2)
			THEN
				NEXT FIELD a01_aux_reexpr
			END IF
		ELSE
			CLEAR descripcion2
		END IF


	AFTER FIELD a01_aux_dep_act
		IF rm_a01.a01_aux_dep_act IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_a01.a01_aux_dep_act,
				3)
			THEN
				NEXT FIELD a01_aux_dep_act
			END IF
		ELSE
			CLEAR descripcion3
		END IF


	AFTER FIELD a01_aux_dep_reex
		IF rm_a01.a01_aux_dep_reex IS NOT NULL THEN
			IF NOT valida_cuenta_contable(
					rm_a01.a01_aux_dep_reex, 4)
			THEN
				NEXT FIELD a01_aux_dep_reex
			END IF
		ELSE
			CLEAR descripcion4
		END IF


	AFTER FIELD a01_aux_pago
		IF rm_a01.a01_aux_pago IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_a01.a01_aux_pago,
				5)
			THEN
				NEXT FIELD a01_aux_pago
			END IF
		ELSE
			CLEAR descripcion5
		END IF

	AFTER FIELD a01_paga_iva
		IF rm_a01.a01_paga_iva = 'N' THEN
			LET rm_a01.a01_aux_iva = NULL
			DISPLAY BY NAME rm_a01.a01_aux_iva
			CLEAR descripcion6
		END IF

	AFTER FIELD a01_aux_iva
		IF rm_a01.a01_paga_iva = 'N' THEN
			LET rm_a01.a01_aux_iva = NULL
			DISPLAY BY NAME rm_a01.a01_aux_iva
			CLEAR descripcion6
			CONTINUE INPUT
		END IF
		IF rm_a01.a01_aux_iva IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_a01.a01_aux_iva, 6)
			THEN
				NEXT FIELD a01_aux_iva
			END IF
		ELSE
			CLEAR descripcion6
		END IF


	AFTER FIELD a01_aux_venta
		IF rm_a01.a01_aux_venta IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_a01.a01_aux_venta,7)
			THEN
				NEXT FIELD a01_aux_venta
			END IF
		ELSE
			CLEAR descripcion7
		END IF

	AFTER FIELD a01_aux_gasto
		IF rm_a01.a01_aux_gasto IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_a01.a01_aux_gasto,8)
			THEN
				NEXT FIELD a01_aux_gasto
			END IF
		ELSE
			CLEAR descripcion8
		END IF

	AFTER FIELD a01_aux_transf
		IF rm_a01.a01_aux_transf IS NOT NULL THEN
			IF NOT valida_cuenta_contable(rm_a01.a01_aux_transf,9)
			THEN
				NEXT FIELD a01_aux_transf
			END IF
		ELSE
			CLEAR descripcion9
		END IF

	BEFORE FIELD a01_porc_deprec
		LET porc_deprec = rm_a01.a01_porc_deprec
	AFTER FIELD a01_porc_deprec
		IF vm_calculo = 'N' THEN
			LET rm_a01.a01_porc_deprec = 
				(100/rm_a01.a01_anos_util)
			DISPLAY BY NAME rm_a01.a01_porc_deprec
			CONTINUE INPUT
		END IF
		IF rm_a01.a01_porc_deprec IS NULL THEN
			LET rm_a01.a01_porc_deprec = porc_deprec
			DISPLAY BY NAME rm_a01.a01_porc_deprec
		END IF
	AFTER INPUT
		IF rm_a01.a01_paga_iva = 'S' THEN
			IF rm_a01.a01_aux_iva IS NULL THEN
				CALL fl_mostrar_mensaje('Debe digitar la cuenta de IVA.', 'exclamation')
				NEXT FIELD a01_aux_iva
			END IF
		ELSE
			LET rm_a01.a01_aux_iva = NULL
			DISPLAY BY NAME rm_a01.a01_aux_iva
			CLEAR descripcion6
		END IF
END INPUT

END FUNCTION



FUNCTION valida_cuenta_contable(cuenta, flag_descr)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE flag_descr	SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, cuenta) RETURNING r_b10.*
IF r_b10.b10_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe esta cuenta.', 'exclamation')
	RETURN 0
END IF
CASE flag_descr
	WHEN 1 DISPLAY r_b10.b10_descripcion TO descripcion1
	WHEN 2 DISPLAY r_b10.b10_descripcion TO descripcion2
	WHEN 3 DISPLAY r_b10.b10_descripcion TO descripcion3
	WHEN 4 DISPLAY r_b10.b10_descripcion TO descripcion4
	WHEN 5 DISPLAY r_b10.b10_descripcion TO descripcion5
	WHEN 6 DISPLAY r_b10.b10_descripcion TO descripcion6
	WHEN 7 DISPLAY r_b10.b10_descripcion TO descripcion7
	WHEN 8 DISPLAY r_b10.b10_descripcion TO descripcion8
	WHEN 9 DISPLAY r_b10.b10_descripcion TO descripcion9
END CASE
IF r_b10.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 0
END IF
IF r_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r		RECORD LIKE ctbt010.*


IF vm_num_rows < 1 THEN
	CLEAR FORM
	RETURN
END IF

SELECT * INTO rm_a01.* FROM actt001 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_a01.a01_grupo_act, rm_a01.a01_nombre,
		rm_a01.a01_depreciable, rm_a01.a01_anos_util,
		rm_a01.a01_porc_deprec, rm_a01.a01_aux_activo,
		rm_a01.a01_aux_reexpr, rm_a01.a01_aux_dep_act,
		rm_a01.a01_aux_dep_reex, rm_a01.a01_aux_pago,
		rm_a01.a01_paga_iva, rm_a01.a01_aux_iva, rm_a01.a01_aux_venta,
		rm_a01.a01_aux_gasto, rm_a01.a01_aux_transf, rm_a01.a01_usuario,
		rm_a01.a01_fecing

CLEAR descripcion1, descripcion2, descripcion3, descripcion4,
	descripcion5, descripcion6, descripcion7, descripcion8, descripcion9

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_activo) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion1

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_reexpr) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion2

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_dep_act) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion3

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_dep_reex) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion4

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_pago) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion5

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_iva) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion6

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_venta) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion7

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_gasto) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion8

CALL fl_lee_cuenta(vg_codcia, rm_a01.a01_aux_transf) RETURNING r.*
DISPLAY r.b10_descripcion TO descripcion9

CALL muestra_contadores()

END FUNCTION


                                                                                
FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_indice, " de ", vm_num_rows AT 1, 69
                                                                                
END FUNCTION

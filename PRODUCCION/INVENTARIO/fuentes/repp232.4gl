-------------------------------------------------------------------------------
-- Titulo               : repp232.4gl -- Mantenimiento de Códigos de Utilidad
-- Elaboración          : 21-Nov-2002
-- Autor                : NPC
-- Formato de Ejecución : fglrun repp232 Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_r10   	RECORD LIKE rept010.*
DEFINE rm_r77   	RECORD LIKE rept077.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'repp232'
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
LET num_rows = 16
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_item AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
OPEN FORM f_rep FROM '../forms/repf232_1'
DISPLAY FORM f_rep
CALL control_ingreso()

END FUNCTION



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
WHILE TRUE
	CLEAR FORM
	INITIALIZE rm_r10.*, rm_r77.* TO NULL
	LET rm_r77.r77_compania   = vg_codcia
	LET rm_r77.r77_fecing     = CURRENT
	LET rm_r77.r77_usuario    = vg_usuario
	DISPLAY BY NAME rm_r77.r77_fecing, rm_r77.r77_usuario
	CALL lee_datos()
	IF NOT int_flag THEN
		CALL control_modificacion()
	ELSE
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION control_modificacion()
DEFINE num_items	INTEGER
DEFINE num_items_c	CHAR(10)
DEFINE resp		CHAR(6)

SELECT COUNT(*) INTO num_items FROM rept010
	WHERE r10_compania = vg_codcia
	  AND r10_tipo     = rm_r10.r10_tipo
	  AND r10_marca    = rm_r10.r10_marca
IF num_items = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
BEGIN WORK
{--
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rept010
		WHERE r10_compania = vg_codcia
		  AND r10_tipo     = rm_r10.r10_tipo
		  AND r10_marca    = rm_r10.r10_marca
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_r10.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
--}
CALL fl_hacer_pregunta('Realmente desea ejecutar este proceso?','No')
	RETURNING resp
IF resp = 'No' THEN
	ROLLBACK WORK
	RETURN
END IF
WHENEVER ERROR CONTINUE
SET LOCK MODE TO NOT WAIT
UPDATE rept010 SET r10_cod_util = rm_r77.r77_codigo_util
	WHERE r10_compania = vg_codcia
	  AND r10_tipo     = rm_r10.r10_tipo
	  AND r10_marca    = rm_r10.r10_marca
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Existen uno o varios items bloqueados por uno u otros usuarios. Intente mas tarde.','stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
COMMIT WORK
LET num_items_c = num_items
CALL fl_mostrar_mensaje('Se actualizaron ' || num_items_c CLIPPED || ' Items con el codigo de utilidad ' || rm_r77.r77_codigo_util CLIPPED || '. Proceso terminado Ok.','info')

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE r_r06		RECORD LIKE rept006.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE r_utl		RECORD LIKE rept077.*

INITIALIZE r_r06.*, r_r73.*, r_utl.* TO NULL
LET int_flag = 0 
INPUT BY NAME rm_r10.r10_marca, rm_r10.r10_tipo, rm_r77.r77_codigo_util
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	IF field_touched(rm_r10.r10_marca, rm_r10.r10_tipo,
				 rm_r77.r77_codigo_util)
		THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                            LET int_flag = 1
                            RETURN
                        END IF
                ELSE
                        RETURN
                END IF       	
	ON KEY(F2)
		IF INFIELD(r10_marca) THEN
			CALL fl_ayuda_marcas_rep(vg_codcia)
				RETURNING r_r73.r73_marca
			IF r_r73.r73_marca IS NOT NULL THEN
				LET rm_r10.r10_marca = r_r73.r73_marca
				CALL fl_lee_marca_rep(vg_codcia,
							rm_r10.r10_marca)
					RETURNING r_r73.*
				DISPLAY BY NAME rm_r10.r10_marca,
						r_r73.r73_desc_marca
			END IF
		END IF
		IF INFIELD(r10_tipo) THEN
			CALL fl_ayuda_tipo_item()
				RETURNING r_r06.r06_codigo, r_r06.r06_nombre
			IF r_r06.r06_codigo IS NOT NULL THEN
				LET rm_r10.r10_tipo = r_r06.r06_codigo
				DISPLAY BY NAME rm_r10.r10_tipo,
						r_r06.r06_nombre
			END IF
		END IF
		IF INFIELD(r77_codigo_util) THEN
			CALL fl_ayuda_factor_utilidad_rep(vg_codcia)
		     		RETURNING r_utl.r77_codigo_util
		     	IF r_utl.r77_codigo_util IS NOT NULL THEN
				LET rm_r77.r77_codigo_util =
							r_utl.r77_codigo_util
				DISPLAY BY NAME rm_r77.r77_codigo_util
				CALL fl_lee_factor_utilidad_rep(vg_codcia,
							rm_r77.r77_codigo_util)
					RETURNING r_utl.*
				LET rm_r77.* = r_utl.*
				DISPLAY BY NAME rm_r77.r77_codigo_util,
						rm_r77.r77_multiplic,
						rm_r77.r77_util_min,
						rm_r77.r77_dscmax_ger,
						rm_r77.r77_dscmax_jef,
						rm_r77.r77_dscmax_ven
		     	END IF
		END IF
                LET int_flag = 0
	AFTER FIELD r10_marca
		IF rm_r10.r10_marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_r10.r10_marca)
				RETURNING r_r73.*
			IF r_r73.r73_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta marca en la compa¤ia.','exclamation')
				NEXT FIELD r10_marca
			END IF
			DISPLAY BY NAME r_r73.r73_desc_marca
		ELSE
			CLEAR r73_desc_marca
		END IF
	AFTER FIELD r10_tipo
		IF rm_r10.r10_tipo IS NOT NULL THEN
			CALL fl_lee_tipo_item(rm_r10.r10_tipo)
				RETURNING r_r06.*
			IF r_r06.r06_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este tipo de item en la compa¤ia.','exclamation')
				NEXT FIELD r10_tipo
			END IF
			DISPLAY BY NAME r_r06.r06_nombre
		ELSE
			CLEAR r06_nombre
		END IF
	AFTER FIELD r77_codigo_util
		IF rm_r77.r77_codigo_util IS NOT NULL THEN
			CALL fl_lee_factor_utilidad_rep(vg_codcia,
							rm_r77.r77_codigo_util)
				RETURNING r_utl.*
			IF r_utl.r77_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este codigo de utilidad en la compa¤ia.','exclamation')
				NEXT FIELD r77_codigo_util
               		END IF
			LET rm_r77.* = r_utl.*
			DISPLAY BY NAME rm_r77.r77_codigo_util,
					rm_r77.r77_multiplic,
					rm_r77.r77_util_min,
					rm_r77.r77_dscmax_ger,
					rm_r77.r77_dscmax_jef,
					rm_r77.r77_dscmax_ven
		ELSE
			CLEAR r77_multiplic, r77_util_min, r77_dscmax_ger,
			      r77_dscmax_jef, r77_dscmax_ven
              	END IF
END INPUT

END FUNCTION

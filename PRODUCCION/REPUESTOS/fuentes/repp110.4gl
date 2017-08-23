-------------------------------------------------------------------------------
-- Titulo               : repp110.4gl -- Mantenimiento de Sublíneas de Ventas
-- Elaboración          : 23-Ago-2002
-- Autor                : NPC
-- Formato de Ejecución : fglrun repp110.4gl Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_r70   	RECORD LIKE rept070.*
DEFINE vm_r_rows 	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp110.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'repp110'
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
LET num_rows = 11
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
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM '../forms/repf110_1'
ELSE
	OPEN FORM f_rep FROM '../forms/repf110_1c'
END IF
DISPLAY FORM f_rep
INITIALIZE rm_r70.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
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
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
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



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(600)
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_sublin		RECORD LIKE rept070.*

CLEAR FORM
INITIALIZE rm_r70.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r70_linea, r70_sub_linea, r70_desc_sub,
	r70_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r70_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
		     		RETURNING r_lin.r03_codigo, r_lin.r03_nombre
			IF r_lin.r03_codigo IS NOT NULL THEN
				LET rm_r70.r70_linea = r_lin.r03_codigo
				DISPLAY BY NAME rm_r70.r70_linea
				DISPLAY r_lin.r03_nombre TO tit_linea
		     	END IF
		END IF
		IF INFIELD(r70_sub_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia, rm_r70.r70_linea)
		     		RETURNING r_sublin.r70_sub_linea,
				     	  r_sublin.r70_desc_sub
		     	IF r_sublin.r70_sub_linea IS NOT NULL THEN
				LET rm_r70.r70_sub_linea =
							r_sublin.r70_sub_linea
				DISPLAY BY NAME rm_r70.r70_sub_linea,
				 		r_sublin.r70_desc_sub
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
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept070 ',
		'WHERE r70_compania = ', vg_codcia,
		' AND ', expr_sql CLIPPED,
		' ORDER BY 2'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_r70.*, vm_r_rows[vm_num_rows]
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



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_r70.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_r70.r70_compania   = vg_codcia
LET rm_r70.r70_usuario    = vg_usuario
LET rm_r70.r70_fecing     = fl_current()
DISPLAY BY NAME rm_r70.r70_fecing, rm_r70.r70_usuario
CALL lee_datos()
IF NOT int_flag THEN
	LET rm_r70.r70_fecing     = fl_current()
        INSERT INTO rept070 VALUES (rm_r70.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant      = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rept070
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_r70.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE rept070 SET * = rm_r70.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_sub		RECORD LIKE rept070.*
                                                                                
LET int_flag = 0 
INPUT BY NAME rm_r70.r70_linea, rm_r70.r70_sub_linea, rm_r70.r70_desc_sub
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_r70.r70_linea, rm_r70.r70_sub_linea,
				  rm_r70.r70_desc_sub)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
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
		IF INFIELD(r70_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
		     		RETURNING r_lin.r03_codigo, r_lin.r03_nombre
			IF r_lin.r03_codigo IS NOT NULL THEN
				LET rm_r70.r70_linea = r_lin.r03_codigo
				DISPLAY BY NAME rm_r70.r70_linea
				DISPLAY r_lin.r03_nombre TO tit_linea
		     	END IF
		END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r70_linea, r70_sub_linea
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD r70_linea
		IF rm_r70.r70_linea IS NOT NULL THEN
        	       	CALL fl_lee_linea_rep(vg_codcia, rm_r70.r70_linea)
          	        	RETURNING r_lin.*
                       	IF r_lin.r03_codigo IS NULL THEN
							CALL fl_mostrar_mensaje('La Línea de Venta no existe en la compañía.','exclamation')
                            NEXT FIELD r70_linea
               	        END IF
                       	IF r_lin.r03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r70_linea
               	        END IF
			DISPLAY r_lin.r03_nombre TO tit_linea
		ELSE 
			CLEAR tit_linea
               	END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			CALL fl_lee_sublinea_rep(vg_codcia,rm_r70.r70_linea,
							rm_r70.r70_sub_linea)
				RETURNING r_sub.*
			IF r_sub.r70_sub_linea IS NOT NULL THEN
				CALL fl_mostrar_mensaje('La Sublínea ya existe para está compañía.','exclamation')
				NEXT FIELD r70_sub_linea
               		END IF
              	END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_lin		RECORD LIKE rept003.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r70.* FROM rept070 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_r70.r70_linea, rm_r70.r70_sub_linea, rm_r70.r70_desc_sub,
		rm_r70.r70_usuario, rm_r70.r70_fecing
CALL fl_lee_linea_rep(vg_codcia, rm_r70.r70_linea) RETURNING r_lin.*
DISPLAY r_lin.r03_nombre TO tit_linea

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
DEFINE nrow  		        SMALLINT
                                                                                
LET nrow = 17
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

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

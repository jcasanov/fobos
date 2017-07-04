-------------------------------------------------------------------------------
-- Titulo               : repp112.4gl -- Mantenimiento de Clases de Ventas
-- Elaboración          : 24-Ago-2002
-- Autor                : NPC
-- Formato de Ejecución : fglrun repp112.4gl Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_r72   	RECORD LIKE rept072.*
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
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp112'
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
LET num_rows = 13
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
	OPEN FORM f_rep FROM '../forms/repf112_1'
ELSE
	OPEN FORM f_rep FROM '../forms/repf112_1c'
END IF
DISPLAY FORM f_rep
INITIALIZE rm_r72.* TO NULL
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
DEFINE r_sub		RECORD LIKE rept070.*
DEFINE r_grp		RECORD LIKE rept071.*
DEFINE r_cla		RECORD LIKE rept072.*

CLEAR FORM
INITIALIZE rm_r72.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r72_linea, r72_sub_linea, r72_cod_grupo,
	r72_cod_clase, r72_desc_clase, r72_usuario, r72_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r72_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
		     		RETURNING r_lin.r03_codigo, r_lin.r03_nombre
			IF r_lin.r03_codigo IS NOT NULL THEN
				LET rm_r72.r72_linea = r_lin.r03_codigo
				DISPLAY BY NAME rm_r72.r72_linea
				DISPLAY r_lin.r03_nombre TO tit_linea
		     	END IF
		END IF
		IF INFIELD(r72_sub_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia, rm_r72.r72_linea)
		  		RETURNING r_sub.r70_sub_linea,
					  r_sub.r70_desc_sub
			IF r_sub.r70_sub_linea IS NOT NULL THEN
				LET rm_r72.r72_sub_linea = r_sub.r70_sub_linea
				DISPLAY BY NAME rm_r72.r72_sub_linea
				DISPLAY r_sub.r70_desc_sub TO tit_sub_linea
		   	END IF
		END IF
		IF INFIELD(r72_cod_grupo) THEN
			CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
							rm_r72.r72_linea,
							rm_r72.r72_sub_linea)
		     		RETURNING r_grp.r71_cod_grupo,
					  r_grp.r71_desc_grupo
			IF r_grp.r71_cod_grupo IS NOT NULL THEN
				LET rm_r72.r72_cod_grupo = r_grp.r71_cod_grupo
				DISPLAY BY NAME rm_r72.r72_cod_grupo
				DISPLAY r_grp.r71_desc_grupo TO tit_grupo
		     	END IF
		END IF
		IF INFIELD(r72_cod_clase) THEN
			CALL fl_ayuda_clase_ventas_rep(vg_codcia,
							rm_r72.r72_linea,
							rm_r72.r72_sub_linea,
							rm_r72.r72_cod_grupo)
		     		RETURNING r_cla.r72_cod_clase,
				   	  r_cla.r72_desc_clase
		     	IF r_cla.r72_cod_clase IS NOT NULL THEN
				LET rm_r72.r72_cod_clase = r_cla.r72_cod_clase
				DISPLAY BY NAME rm_r72.r72_cod_clase,
				 		r_cla.r72_desc_clase
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
LET query = 'SELECT *, ROWID FROM rept072 ',
		'WHERE r72_compania = ', vg_codcia,
		' AND ', expr_sql CLIPPED,
		' ORDER BY 2'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_r72.*, vm_r_rows[vm_num_rows]
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
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_r72.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_r72.r72_compania   = vg_codcia
LET rm_r72.r72_fecing     = CURRENT
LET rm_r72.r72_usuario    = vg_usuario
DISPLAY BY NAME rm_r72.r72_fecing, rm_r72.r72_usuario
CALL lee_datos()
IF NOT int_flag THEN
	LET rm_r72.r72_fecing     = CURRENT
        INSERT INTO rept072 VALUES (rm_r72.*)
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

LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rept072
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_r72.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE rept072 SET * = rm_r72.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	COMMIT WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_sub		RECORD LIKE rept070.*
DEFINE r_grp		RECORD LIKE rept071.*
DEFINE r_cla		RECORD LIKE rept072.*
                                                                                
LET int_flag = 0 
INPUT BY NAME rm_r72.r72_linea, rm_r72.r72_sub_linea, rm_r72.r72_cod_grupo,
	rm_r72.r72_cod_clase, rm_r72.r72_desc_clase
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_r72.r72_linea, rm_r72.r72_sub_linea,
				  rm_r72.r72_cod_grupo, rm_r72.r72_cod_clase,
				  rm_r72.r72_desc_clase)
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
		IF INFIELD(r72_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
		     		RETURNING r_lin.r03_codigo, r_lin.r03_nombre
			IF r_lin.r03_codigo IS NOT NULL THEN
				LET rm_r72.r72_linea = r_lin.r03_codigo
				DISPLAY BY NAME rm_r72.r72_linea
				DISPLAY r_lin.r03_nombre TO tit_linea
		     	END IF
		END IF
		IF INFIELD(r72_sub_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia, rm_r72.r72_linea)
		  		RETURNING r_sub.r70_sub_linea,
					  r_sub.r70_desc_sub
			IF r_sub.r70_sub_linea IS NOT NULL THEN
				LET rm_r72.r72_sub_linea = r_sub.r70_sub_linea
				DISPLAY BY NAME rm_r72.r72_sub_linea
				DISPLAY r_sub.r70_desc_sub TO tit_sub_linea
		   	END IF
		END IF
		IF INFIELD(r72_cod_grupo) THEN
			CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
							rm_r72.r72_linea,
							rm_r72.r72_sub_linea)
		     		RETURNING r_grp.r71_cod_grupo,
					  r_grp.r71_desc_grupo
			IF r_grp.r71_cod_grupo IS NOT NULL THEN
				LET rm_r72.r72_cod_grupo = r_grp.r71_cod_grupo
				DISPLAY BY NAME rm_r72.r72_cod_grupo
				DISPLAY r_grp.r71_desc_grupo TO tit_grupo
		     	END IF
		END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r72_linea, r72_sub_linea, r72_cod_grupo, r72_cod_clase
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD r72_linea
		IF rm_r72.r72_linea IS NOT NULL THEN
        	       	CALL fl_lee_linea_rep(vg_codcia, rm_r72.r72_linea)
          	        	RETURNING r_lin.*
                       	IF r_lin.r03_codigo IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'La Línea de Venta no existe en la compañía.','exclamation')
				CALL fl_mostrar_mensaje('La Línea de Venta no existe en la compañía.','exclamation')
                                NEXT FIELD r72_linea
               	        END IF
                       	IF r_lin.r03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r72_linea
               	        END IF
			DISPLAY r_lin.r03_nombre TO tit_linea
		ELSE 
			CLEAR tit_linea
               	END IF
	AFTER FIELD r72_sub_linea
		IF rm_r72.r72_sub_linea IS NOT NULL THEN
        	       	CALL fl_lee_sublinea_rep(vg_codcia,rm_r72.r72_linea,
							rm_r72.r72_sub_linea)
          	        	RETURNING r_sub.*
                       	IF r_sub.r70_sub_linea IS NULL THEN
                               	--CALL fgl_winmessage (vg_producto,'La Sublínea de Venta no existe en la compañía.','exclamation')
				CALL fl_mostrar_mensaje('La Sublínea de Venta no existe en la compañía.','exclamation')
                                NEXT FIELD r72_sub_linea
               	        END IF
			DISPLAY r_sub.r70_desc_sub TO tit_sub_linea
		ELSE 
			CLEAR tit_sub_linea
               	END IF
	AFTER FIELD r72_cod_grupo
		IF rm_r72.r72_cod_grupo IS NOT NULL THEN
        	       	CALL fl_lee_grupo_rep(vg_codcia,rm_r72.r72_linea,
						rm_r72.r72_sub_linea,
						rm_r72.r72_cod_grupo)
          	        	RETURNING r_grp.*
                       	IF r_grp.r71_cod_grupo IS NULL THEN
                               	--CALL fgl_winmessage(vg_producto,'El Grupo de Venta no existe en la compañía.','exclamation')
				CALL fl_mostrar_mensaje('El Grupo de Venta no existe en la compañía.','exclamation')
                                NEXT FIELD r72_cod_grupo
               	        END IF
			DISPLAY r_grp.r71_desc_grupo TO tit_grupo
		ELSE 
			CLEAR tit_grupo
               	END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			CALL fl_lee_clase_rep(vg_codcia,rm_r72.r72_linea,
						rm_r72.r72_sub_linea,
						rm_r72.r72_cod_grupo,
						rm_r72.r72_cod_clase)
				RETURNING r_cla.*
			IF r_cla.r72_cod_clase IS NOT NULL THEN
				--CALL fgl_winmessage(vg_producto,'La Clase ya existe para este Grupo de Venta.','exclamation')
				CALL fl_mostrar_mensaje('La Clase ya existe para este Grupo de Venta.','exclamation')
				NEXT FIELD r72_cod_clase
			END IF
              	END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_sub		RECORD LIKE rept070.*
DEFINE r_grp		RECORD LIKE rept071.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r72.* FROM rept072 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_r72.r72_linea, rm_r72.r72_sub_linea, rm_r72.r72_cod_grupo,
		rm_r72.r72_cod_clase, rm_r72.r72_desc_clase, rm_r72.r72_usuario,
		rm_r72.r72_fecing
CALL fl_lee_linea_rep(vg_codcia, rm_r72.r72_linea) RETURNING r_lin.*
DISPLAY r_lin.r03_nombre TO tit_linea
CALL fl_lee_sublinea_rep(vg_codcia, rm_r72.r72_linea, rm_r72.r72_sub_linea)
	RETURNING r_sub.*
DISPLAY r_sub.r70_desc_sub TO tit_sub_linea
CALL fl_lee_grupo_rep(vg_codcia, rm_r72.r72_linea, rm_r72.r72_sub_linea,
			rm_r72.r72_cod_grupo)
	RETURNING r_grp.*
DISPLAY r_grp.r71_desc_grupo TO tit_grupo

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
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION

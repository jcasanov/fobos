-------------------------------------------------------------------------------
-- Titulo               : repp109.4gl -- Mantenimiento de Equivalencias
-- Elaboración          : 5-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  repp109.4gl base RE 1  
-- Ultima Correción     : 15-sep-2001
-- Motivo Corrección    : 2
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_equi		RECORD LIKE rept015.*
DEFINE rm_equi2		RECORD LIKE rept015.*
DEFINE rm_item		RECORD LIKE rept010.*
DEFINE vm_r_rows	ARRAY[1000] OF LIKE rept015.r15_item
				-- ARREGLO DE ITEMS LEIDOS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)
DEFINE vm_resp		CHAR(6)
DEFINE vm_num_eq     	SMALLINT
DEFINE vm_max_rows     	SMALLINT
DEFINE vm_elementos    	SMALLINT
DEFINE vm_filas_pant   	SMALLINT
DEFINE rm_equi_item	ARRAY[200] OF RECORD
				r15_equivalente		LIKE rept015.r15_item,
				r10_nombre	        LIKE rept010.r10_nombre
			END RECORD    
DEFINE vm_ind_arr	SMALLINT



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'repp109'
LET vm_max_rows = 1000
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE i SMALLINT

CALL fl_nivel_isolation()
LET vm_elementos = 200

OPEN WINDOW w_equi AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_equi FROM '../forms/repf109_1'
DISPLAY FORM f_equi
CALL control_DISPLAY_botones()

INITIALIZE rm_equi.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Mantenimiento'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows <= 1 THEN
			--HIDE OPTION 'Mantenimiento'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Retroceder'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Mantenimiento'
		END IF
	COMMAND KEY('M') 'Mantenimiento' 'Mantenimiento a las equivalencias.'
		IF vm_num_rows > 0  AND rm_equi.r15_item IS NOT NULL THEN
			CALL control_mantenimiento()
		END IF
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Retroceder'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		LET vm_flag_mant = ''
		CALL control_consulta()
		IF vm_num_rows < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Retroceder'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Mantenimiento'
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
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar' 
			SHOW OPTION 'Retroceder' 
			NEXT OPTION 'Retroceder' 
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_DISPLAY_botones()

DISPLAY 'Item'		TO tit_col1
DISPLAY 'Descripción'	TO tit_col2

END FUNCTION



FUNCTION control_mantenimiento()
DEFINE expr_sql		VARCHAR(50)
DEFINE i		SMALLINT
DEFINE r_equi_item 	RECORD LIKE rept015.*

DEFINE fecha_actual DATETIME YEAR TO SECOND

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR SELECT * FROM rept015 
	WHERE r15_compania = vg_codcia 
	AND   r15_item     = rm_equi.r15_item
	FOR   UPDATE
OPEN q_upd
FETCH q_upd INTO r_equi_item.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()	
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL cargar_equivalentes()
CALL lee_equivalentes()
LET vm_flag_mant = 'M'
IF NOT int_flag THEN
	DELETE FROM rept015 
		WHERE r15_compania = vg_codcia 
		AND   r15_item     = rm_equi.r15_item
	LET fecha_actual = fl_current()
	FOR i = 1 TO arr_count()
		INSERT INTO rept015
	 	VALUES (vg_codcia, rm_equi.r15_item, 		       				rm_equi_item[i].r15_equivalente,
		rm_equi.r15_usuario,fecha_actual)
	END FOR
	COMMIT WORK
	IF arr_count() > 0 THEN
		CALL fl_mensaje_registro_modificado()
	ELSE 
		--CALL fgl_winmessage(vg_producto,'Se eliminaron todas las equivalencias del Item ','exclamation')
		CALL fl_mostrar_mensaje('Se eliminaron todas las equivalencias del Item.','exclamation')
		CLEAR FORM
		CALL control_DISPLAY_botones()
		LET vm_num_rows    = 0
		LET vm_row_current = 0
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		RETURN
	END IF
	--LET expr_sql = "r15_item = '",rm_equi.r15_item CLIPPED, "'"
	--CALL valida_mantenimiento(expr_sql)
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
ELSE 
	ROLLBACK WORK
	IF NOT int_flag THEN
		CALL fl_mensaje_consultar_primero()
	END IF
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
CALL control_DISPLAY_botones()

LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r15_item
	ON KEY(F2)
		IF INFIELD(r15_item) THEN
		     CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
		     RETURNING rm_equi.r15_item, rm_item.r10_nombre
		     IF rm_equi.r15_item IS NOT NULL THEN
			DISPLAY BY NAME rm_equi.r15_item
			DISPLAY  rm_item.r10_nombre TO nom_item
		     END IF
		END IF
                LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	CALL control_DISPLAY_botones()
	IF vm_num_rows >0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
CALL valida_mantenimiento(expr_sql)

END FUNCTION



FUNCTION valida_mantenimiento(expr_sql)
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

LET query = 'SELECT UNIQUE r15_item FROM rept015 WHERE r15_compania = ',
		vg_codcia,' AND ', expr_sql CLIPPED, ' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_equi CURSOR FOR cons
LET vm_num_rows = 1

FOREACH q_equi INTO vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
	LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 AND  vm_flag_mant <> 'M' AND vm_flag_mant <> 'I' THEN
	--CALL fgl_winmessage(vg_producto,'No se encontraron registros con el criterio indicado', 'exclamation')
	CALL fl_mostrar_mensaje('No se encontraron registros con el criterio indicado.','exclamation')
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
	CALL control_DISPLAY_botones()
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION control_ingreso()
DEFINE i		SMALLINT
DEFINE expr_sql		VARCHAR(50)
DEFINE r_equi_item 	RECORD LIKE rept015.*

OPTIONS INPUT WRAP
CLEAR FORM
CALL control_DISPLAY_botones()

INITIALIZE rm_equi.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_equi.r15_fecing    = fl_current()
LET rm_equi.r15_usuario   = vg_usuario
LET rm_equi.r15_compania  = vg_codcia
DISPLAY BY NAME rm_equi.r15_fecing, rm_equi.r15_usuario

CALL lee_item()
IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF 
	RETURN
END IF
CALL cargar_equivalentes()

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd2 CURSOR FOR SELECT * FROM rept015 
	WHERE r15_compania = vg_codcia 
	AND   r15_item     = rm_equi.r15_item
	FOR   UPDATE
OPEN q_upd2
FETCH q_upd2 INTO r_equi_item.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()	
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
IF NOT int_flag THEN
	CALL lee_equivalentes()
END IF
IF NOT int_flag THEN
	SELECT UNIQUE r15_item FROM rept015 
	WHERE r15_item = rm_equi.r15_item
	IF status <> NOTFOUND AND vm_num_rows >= 1 THEN
		LET vm_num_rows = vm_num_rows - 1 
	END IF
	DELETE FROM rept015 
	 WHERE r15_compania = vg_codcia 
	   AND r15_item = rm_equi.r15_item
	FOR i = 1 TO arr_count()
		INSERT INTO rept015 VALUES (vg_codcia, rm_equi.r15_item, 		       	
			rm_equi_item[i].r15_equivalente, rm_equi.r15_usuario, 
	       	rm_equi.r15_fecing)
	END FOR
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_num_rows] = rm_equi.r15_item
	COMMIT WORK
	IF arr_count() > 0 THEN
		CALL fl_mensaje_registro_ingresado()
	ELSE 
		LET vm_row_current = 0
		--CALL fgl_winmessage(vg_producto,'No existen equivalencias para el item ','exclamation')
		CALL fl_mostrar_mensaje('No existen equivalencias para el item.','exclamation')
		CLEAR FORM
		CALL control_DISPLAY_botones()
	END IF
	LET expr_sql = "r15_item = '",rm_equi.r15_item CLIPPED, "'"
	CALL valida_mantenimiento(expr_sql)
ELSE
	ROLLBACK WORK
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_item()
DEFINE resp		CHAR(6)
                                                                               
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_equi.r15_item  WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_equi.r15_item)
                 THEN
                        LET int_flag = 0
                        CALL fl_mensaje_abandonar_proceso()   
				RETURNING resp
                        IF resp = 'Yes' THEN
                             LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                CLEAR FORM
				CALL control_DISPLAY_botones()
			    END IF
                            RETURN
                        END IF
                ELSE
			IF vm_flag_mant = 'I' THEN
                	        CLEAR FORM
				CALL control_DISPLAY_botones()
			END IF
                        RETURN
                END IF       	
       ON KEY(F2)
                IF INFIELD(r15_item) THEN
                     CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
                     RETURNING rm_equi.r15_item, rm_item.r10_nombre
                     IF rm_equi.r15_item IS NOT NULL THEN
                        DISPLAY BY NAME rm_equi.r15_item
                        DISPLAY  rm_item.r10_nombre TO nom_item
                     END IF
                END IF
                LET int_flag = 0
	AFTER FIELD r15_item
               IF vm_flag_mant = 'I' THEN
     		    CALL fl_lee_item(vg_codcia, rm_equi.r15_item)
			RETURNING rm_item.*
                    IF rm_item.r10_codigo IS NULL THEN
                        --CALL fgl_winmessage(vg_producto,'El item no existe.','exclamation')
			CALL fl_mostrar_mensaje('El item no existe.','exclamation')
                        NEXT FIELD r15_item
                    END IF
	            LET rm_equi.r15_item = rm_item.r10_codigo
     		    DISPLAY BY NAME rm_equi.r15_item
                    DISPLAY  rm_item.r10_nombre TO nom_item
              END IF
END INPUT

END FUNCTION



FUNCTION lee_equivalentes()
DEFINE resp      			CHAR(6)
DEFINE i,j,k,filas_max,filas_pant     	SMALLINT

OPTIONS INPUT WRAP
LET int_flag   = 0 
LET filas_max  = 100 
LET filas_pant = 7 
CALL set_count(vm_num_eq)
INPUT ARRAY rm_equi_item  WITHOUT DEFAULTS FROM rm_equi_item.*
	BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
        ON KEY(INTERRUPT)
                        LET int_flag = 0
                        CALL fl_mensaje_abandonar_proceso()   
				RETURNING resp
                        IF resp = 'Yes' THEN
                             LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                               	 CLEAR FORM
				CALL control_DISPLAY_botones()
			    END IF
                            RETURN
                        END IF
       	ON KEY(F2)
                IF INFIELD(r15_equivalente) THEN
                     CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
                     RETURNING rm_item.r10_codigo, rm_item.r10_nombre
                     IF rm_item.r10_codigo IS NOT NULL THEN
			LET rm_equi_item[i].r15_equivalente =rm_item.r10_codigo
                        DISPLAY rm_item.r10_codigo TO
				 rm_equi_item[j].r15_equivalente
                        DISPLAY rm_item.r10_nombre TO rm_equi_item[j].r10_nombre
                     END IF
                END IF
                LET int_flag = 0
	AFTER FIELD r15_equivalente
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
	    	IF rm_equi_item[i].r15_equivalente IS NOT NULL THEN
			IF rm_equi.r15_item = rm_equi_item[i].r15_equivalente
			THEN
				--CALL fgl_winmessage(vg_producto,'Item no puede ser equivalente a si mismo','exclamation')
				CALL fl_mostrar_mensaje('Item no puede ser equivalente a si mismo.','exclamation')
				NEXT FIELD r15_equivalente
			END IF
     			CALL fl_lee_item(vg_codcia, rm_equi_item[i].r15_equivalente)
				RETURNING rm_item.*
                	IF rm_item.r10_codigo IS NULL THEN
                       		--CALL fgl_winmessage(vg_producto,'El item no existe.','exclamation')
				CALL fl_mostrar_mensaje('El item no existe.','exclamation')
                       		NEXT FIELD r15_equivalente
                	END IF
			LET rm_equi_item[i].r10_nombre = rm_item.r10_nombre
			DISPLAY rm_equi_item[i].r10_nombre TO
					rm_equi_item[j].r10_nombre
			FOR k = 1 TO arr_count()
				IF rm_equi_item[i].r15_equivalente = rm_equi_item[k].r15_equivalente AND i <> k THEN
					--CALL fgl_winmessage(vg_producto,'No puede ingresar items repetidos','exclamation')
					CALL fl_mostrar_mensaje('No puede ingresar items repetidos.','exclamation')
					NEXT FIELD r15_equivalente
               			END IF
			END FOR
		ELSE
			IF rm_equi_item[i].r10_nombre IS NOT NULL
				AND rm_equi_item[i].r15_equivalente IS NULL
			THEN
				NEXT FIELD r15_equivalente
			END IF 
		END IF
END INPUT

END FUNCTION



FUNCTION cargar_equivalentes()

DECLARE q_eq CURSOR FOR
	SELECT r15_equivalente, r10_nombre
	  FROM rept015, rept010
	 WHERE r15_compania = vg_codcia AND r15_item = rm_equi.r15_item 
	   AND r15_compania = r10_compania AND r15_equivalente  = r10_codigo
LET vm_num_eq = 1
FOREACH q_eq INTO rm_equi_item[vm_num_eq].*
	LET vm_num_eq = vm_num_eq + 1
END FOREACH
LET vm_num_eq = vm_num_eq - 1

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE i	SMALLINT
DEFINE j	SMALLINT
DEFINE num_row		LIKE rept015.r15_item
DEFINE rm_equi_item ARRAY[100] OF RECORD
	r15_equivalente		LIKE rept015.r15_item,
	r10_nombre	        LIKE rept010.r10_nombre
	END RECORD

LET vm_filas_pant = fgl_scr_size('rm_equi_item')
FOR j = 1 TO vm_filas_pant 
	INITIALIZE rm_equi_item[j].* TO NULL
	CLEAR rm_equi_item[j].*
END FOR
IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_eq2 CURSOR FOR SELECT * FROM rept015
 WHERE r15_compania = vg_codcia AND r15_item = num_row
OPEN q_eq2
FETCH q_eq2 INTO rm_equi.*
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
LET i = 0
DISPLAY BY NAME rm_equi.r15_item, rm_equi.r15_usuario, rm_equi.r15_fecing
CALL fl_lee_item(vg_codcia, rm_equi.r15_item)
	RETURNING rm_item.*
        DISPLAY  rm_item.r10_nombre TO nom_item
FOREACH q_eq2 INTO rm_equi.*

	LET i = i + 1
	IF i > vm_elementos THEN
		CALL fl_mensaje_arreglo_lleno()
		RETURN
		EXIT FOREACH
	END IF

	LET rm_equi_item[i].r15_equivalente = rm_equi.r15_equivalente 
	CALL fl_lee_item(vg_codcia, rm_equi_item[i].r15_equivalente)
		RETURNING rm_item.*
	LET rm_equi_item[i].r10_nombre      = rm_item.r10_nombre

END FOREACH
LET vm_ind_arr = i
LET i = i - 1
IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF
FOR j = 1 TO vm_filas_pant
	DISPLAY rm_equi_item[j].* TO rm_equi_item[j].*
END FOR

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION

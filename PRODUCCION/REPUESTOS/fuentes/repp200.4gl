{*
 * Titulo           : repp200.4gl - Ingreso de Sustituciones 
 * Elaboracion      : 29-oct-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp200 base RE 1 
 *}
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_r14  	 	RECORD LIKE rept014.*
DEFINE rm_r14_2 	RECORD LIKE rept014.*
DEFINE rm_r10  	RECORD LIKE rept010.*

DEFINE vm_r_rows ARRAY[1000] OF LIKE rept014.r14_item_ant -- ARREGLO DE ITEMS LEIDOS

DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS

DEFINE vm_demonios      VARCHAR(12)

DEFINE vm_flag_mant     CHAR(1)
DEFINE vm_resp			CHAR(6)
DEFINE vm_num_sus     	SMALLINT -- Numero de sustitutos del item
DEFINE vm_max_rows     	SMALLINT
DEFINE vm_elementos    	SMALLINT
DEFINE vm_filas_pant   	SMALLINT

DEFINE r_detalle	 ARRAY[250] OF RECORD
	r14_cantidad		LIKE rept014.r14_cantidad,
	r14_item_nue		LIKE rept014.r14_item_nue,
	r10_nombre	        LIKE rept010.r10_nombre
END RECORD    

DEFINE vm_ind_arr	SMALLINT



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp200.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp200'
LET vm_max_rows  = 1000
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE i SMALLINT

CALL fl_nivel_isolation()
LET vm_elementos = 250

OPEN WINDOW w_repp200 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_repp200 FROM '../forms/repf200_1'
DISPLAY FORM f_repp200
CALL control_display_botones()

INITIALIZE rm_r14.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
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
		IF vm_num_rows > 0  AND rm_r14.r14_item_ant IS NOT NULL THEN
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
		CALL muestra_contadores()
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
		CALL muestra_contadores()
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



FUNCTION control_display_botones()

DISPLAY 'Item'			TO tit_col1
DISPLAY 'Descripción'	TO tit_col2
DISPLAY 'Cant'			TO tit_col3
DISPLAY '** Sustitutos'	TO tit_sus

END FUNCTION



FUNCTION control_mantenimiento()
DEFINE expr_sql		VARCHAR(50)
DEFINE i		SMALLINT

BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR SELECT * FROM rept014 
	WHERE r14_compania = vg_codcia 
	AND   r14_item_ant     = rm_r14.r14_item_ant
	FOR   UPDATE
OPEN q_upd
FETCH q_upd 
IF status < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()	
	RETURN
END IF
WHENEVER ERROR STOP

CALL control_lee_sustitutos()

LET vm_flag_mant = 'M'

IF NOT int_flag THEN
	DELETE FROM rept014 
		WHERE r14_compania = vg_codcia 
		AND   r14_item_ant     = rm_r14.r14_item_ant
	FOR i = 1 TO arr_count()
		INSERT INTO rept014 VALUES (vg_codcia,
					    rm_r14.r14_item_ant,
					    r_detalle[i].r14_item_nue,
						r_detalle[i].r14_cantidad,
					    rm_r14.r14_usuario, CURRENT)
	END FOR

	IF arr_count() > 0 THEN
		IF rm_r10.r10_estado <> 'S' THEN
			UPDATE rept010 SET r10_estado = 'S'
				WHERE r10_compania = vg_codcia
			  	  AND r10_codigo   = rm_r14.r14_item_ant
		END IF

		COMMIT WORK

		CALL fl_mensaje_registro_modificado()
	ELSE 
		UPDATE rept010 SET r10_estado = 'A'
			WHERE r10_compania = vg_codcia
			  AND r10_codigo   = rm_r14.r14_item_ant

		COMMIT WORK

		CALL fgl_winmessage(vg_producto,'Se eliminaron todos los sustitutos del Item ' || rm_r14.r14_item_ant,'exclamation')
		CLEAR FORM
		CALL control_display_botones()
		LET vm_num_rows    = 0
		LET vm_row_current = 0
		CALL muestra_contadores()
		RETURN
	END IF
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
ELSE 
	ROLLBACK WORK

	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
CALL control_display_botones()

LET int_flag = 0
LET vm_flag_mant = 'C'
CONSTRUCT BY NAME expr_sql ON r14_item_ant
	ON KEY(F2)
		IF INFIELD(r14_item_ant) THEN
		     	CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
		     		RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre
		     	IF rm_r10.r10_codigo IS NOT NULL THEN
				LET rm_r14.r14_item_ant = rm_r10.r10_codigo
				DISPLAY BY NAME rm_r14.r14_item_ant
				DISPLAY  rm_r10.r10_nombre TO nom_item
		     END IF
		END IF
                LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	CALL control_display_botones()
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores()
	RETURN
END IF
CALL valida_mantenimiento(expr_sql)

END FUNCTION



FUNCTION valida_mantenimiento(expr_sql)
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

LET query = 'SELECT UNIQUE r14_item_ant FROM rept014 WHERE r14_compania = ',
		vg_codcia,' AND ', expr_sql CLIPPED
PREPARE cons FROM query
DECLARE q_sust CURSOR FOR cons
LET vm_num_rows = 1

FOREACH q_sust INTO vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
	LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 AND  vm_flag_mant <> 'M' AND vm_flag_mant <> 'I' THEN
	CALL fgl_winmessage(vg_producto, 'No se encontraron registros con el criterio indicado', 'exclamation')
	LET vm_row_current = 0
	CALL muestra_contadores()
        CLEAR FORM
	CALL control_display_botones()
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION control_ingreso()
DEFINE i		SMALLINT
DEFINE expr_sql		VARCHAR(50)
DEFINE r_r14	 	RECORD LIKE rept014.*

OPTIONS INPUT WRAP
CLEAR FORM
CALL control_display_botones()

INITIALIZE rm_r14.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_r14.r14_fecing    = CURRENT
LET rm_r14.r14_usuario   = vg_usuario
LET rm_r14.r14_compania  = vg_codcia
DISPLAY BY NAME rm_r14.r14_fecing, rm_r14.r14_usuario

CALL lee_item()
IF int_flag THEN
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF 
	RETURN
END IF
CALL control_cargar_sustitutos()

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd2 CURSOR FOR 
	SELECT * FROM rept014 
		WHERE r14_compania = vg_codcia 
		  AND r14_item_ant = rm_r14.r14_item_ant
	FOR   UPDATE
OPEN q_upd2
FETCH q_upd2 
WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()	
	RETURN
END IF

CALL control_lee_sustitutos()

IF NOT int_flag THEN
	SELECT UNIQUE r14_item_ant FROM rept014 
	WHERE r14_item_ant = rm_r14.r14_item_ant
	IF status <> NOTFOUND AND vm_num_rows >= 1 THEN
		LET vm_num_rows = vm_num_rows - 1 
	END IF
	DELETE FROM rept014 
	 WHERE r14_compania = vg_codcia 
	   AND r14_item_ant = rm_r14.r14_item_ant
	FOR i = 1 TO arr_count()
		INSERT INTO rept014 VALUES (vg_codcia, rm_r14.r14_item_ant, 		       				    r_detalle[i].r14_item_nue, r_detalle[i].r14_cantidad, 
					    rm_r14.r14_usuario,	CURRENT)
	END FOR
	
	
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_num_rows] = rm_r14.r14_item_ant


	IF arr_count() > 0 THEN
		IF rm_r10.r10_estado <> 'S' THEN
			UPDATE rept010 SET r10_estado = 'S'
				WHERE r10_compania = vg_codcia
				  AND r10_codigo   = rm_r14.r14_item_ant
		END IF

		COMMIT WORK

		CALL fgl_winmessage (vg_producto,'Registro grabado Ok.','info')
	ELSE 

		UPDATE rept010 SET r10_estado = 'A'
			WHERE r10_compania = vg_codcia
			  AND r10_codigo   = rm_r14.r14_item_ant
		
		COMMIT WORK

		LET vm_row_current = 0
		CALL fgl_winmessage(vg_producto,'Se eliminaron todas las sustituciones para el item ' || rm_r14.r14_item_ant,'exclamation')
		CLEAR FORM
		CALL control_display_botones()
	END IF
	LET expr_sql = "r14_item_ant = '",rm_r14.r14_item_ant CLIPPED, "'"

	CALL valida_mantenimiento(expr_sql)

ELSE
	ROLLBACK WORK
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION lee_item()
DEFINE           resp      CHAR(6)
                                                                               
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_r14.r14_item_ant  WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_r14.r14_item_ant)
                 THEN
                        LET int_flag = 0
                        CALL fl_mensaje_abandonar_proceso()   
				RETURNING resp
                        IF resp = 'Yes' THEN
                             LET int_flag = 1
			    IF vm_flag_mant = 'I' THEN
                                CLEAR FORM
				CALL control_display_botones()
			    END IF
                            RETURN
                        END IF
                ELSE
			IF vm_flag_mant = 'I' THEN
                	        CLEAR FORM
				CALL control_display_botones()
			END IF
                        RETURN
                END IF       	
       ON KEY(F2)
                IF INFIELD(r14_item_ant) THEN
                     CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
                     RETURNING rm_r14.r14_item_ant, rm_r10.r10_nombre
                     IF rm_r14.r14_item_ant IS NOT NULL THEN
                        DISPLAY BY NAME rm_r14.r14_item_ant
                        DISPLAY  rm_r10.r10_nombre TO nom_item
                     END IF
                END IF
                LET int_flag = 0
	AFTER FIELD r14_item_ant
               IF vm_flag_mant = 'I' THEN
     		    CALL fl_lee_item(vg_codcia, rm_r14.r14_item_ant)
			RETURNING rm_r10.*
                    IF rm_r10.r10_codigo IS NULL THEN
                          CALL fgl_winmessage(vg_producto,
			                      'El item no existe','exclamation')
                          NEXT FIELD r14_item_ant
                    END IF
			IF rm_r10.r10_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,'','')
			END IF
	            LET rm_r14.r14_item_ant = rm_r10.r10_codigo
     		    DISPLAY BY NAME rm_r14.r14_item_ant
                    DISPLAY  rm_r10.r10_nombre TO nom_item
              END IF
END INPUT

END FUNCTION



FUNCTION control_lee_sustitutos()
DEFINE resp      			CHAR(6)
DEFINE i,j,k  			     	SMALLINT

OPTIONS INPUT WRAP
LET int_flag   = 0 
CALL set_count(vm_num_sus)
INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		DISPLAY "" AT 6,1
		DISPLAY i, ' de ', vm_num_sus AT 6, 28
        ON KEY(INTERRUPT)
                LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso()   
			RETURNING resp
                IF resp = 'Yes' THEN
                	LET int_flag = 1
			IF vm_flag_mant = 'I' THEN
                       		CLEAR FORM
				CALL control_display_botones()
		    	END IF
			DISPLAY "" AT 6,1
                     	RETURN
                END IF
       	ON KEY(F2)
		IF INFIELD(r14_item_nue) THEN
                	CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
                     		RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre
                     	IF rm_r10.r10_codigo IS NOT NULL THEN
				LET r_detalle[i].r14_item_nue = 
				    rm_r10.r10_codigo
                        	DISPLAY rm_r10.r10_codigo TO 
					r_detalle[j].r14_item_nue
                     		DISPLAY rm_r10.r10_nombre TO 
					r_detalle[j].r10_nombre
                        END IF
                END IF
                LET int_flag = 0
	AFTER FIELD r14_item_nue
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
	    	IF r_detalle[i].r14_item_nue IS NOT NULL THEN
			IF rm_r14.r14_item_ant = r_detalle[i].r14_item_nue THEN
				CALL fgl_winmessage(vg_producto,'Item no puede ser sustituto de si mismo.','exclamation')
				NEXT FIELD r14_item_nue
			END IF
     			CALL fl_lee_item(vg_codcia, r_detalle[i].r14_item_nue)
				RETURNING rm_r10.*
                	IF rm_r10.r10_codigo IS NULL THEN
                       		CALL fgl_winmessage(vg_producto, 'El item no existe en la Compañía.','exclamation')
                       		NEXT FIELD r14_item_nue
                	END IF
			LET r_detalle[i].r10_nombre = rm_r10.r10_nombre
			DISPLAY r_detalle[i].r10_nombre TO 
				r_detalle[j].r10_nombre
			FOR k = 1 TO arr_count()
				IF r_detalle[i].r14_item_nue = 
				   r_detalle[k].r14_item_nue AND 
				   i <> k THEN
					CALL fgl_winmessage(vg_producto,'No puede ingresar items repetidos.','exclamation')
					NEXT FIELD r14_item_nue
               			END IF
			END FOR
		ELSE
			IF r_detalle[i].r10_nombre IS NOT NULL
				AND r_detalle[i].r14_item_nue IS NULL
			THEN
				NEXT FIELD r14_item_nue
			END IF 
		END IF
END INPUT

END FUNCTION



FUNCTION control_cargar_sustitutos()

DECLARE q_sust2 CURSOR FOR
	SELECT r14_cantidad, r14_item_nue, r10_nombre
	  FROM rept014, rept010
	 WHERE r14_compania = vg_codcia 
	   AND r14_item_ant = rm_r14.r14_item_ant 
	   AND r14_compania = r10_compania 
	   AND r14_item_nue = r10_codigo
LET vm_num_sus = 1
FOREACH q_sust2 INTO r_detalle[vm_num_sus].*
	LET vm_num_sus = vm_num_sus + 1
END FOREACH
LET vm_num_sus = vm_num_sus - 1

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE i	SMALLINT
DEFINE j	SMALLINT
DEFINE num_row		LIKE rept014.r14_item_ant

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR j = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[j].* TO NULL
	CLEAR r_detalle[j].*
END FOR
IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_rept014 CURSOR FOR 
	SELECT * FROM rept014
 		WHERE r14_compania = vg_codcia 
		  AND r14_item_ant = num_row
OPEN q_rept014
FETCH q_rept014 INTO rm_r14.*
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_r14.r14_item_ant, rm_r14.r14_usuario, rm_r14.r14_fecing
CALL fl_lee_item(vg_codcia, rm_r14.r14_item_ant)
	RETURNING rm_r10.*
        DISPLAY  rm_r10.r10_nombre TO nom_item

LET i = 1
FOREACH q_rept014 INTO rm_r14.*

	LET r_detalle[i].r14_cantidad = rm_r14.r14_cantidad 
	LET r_detalle[i].r14_item_nue = rm_r14.r14_item_nue 
	CALL fl_lee_item(vg_codcia, r_detalle[i].r14_item_nue)
		RETURNING rm_r10.*
	LET r_detalle[i].r10_nombre   = rm_r10.r10_nombre
	LET i = i + 1
	IF i > vm_elementos THEN
		--CALL fl_mensaje_arreglo_lleno()
		EXIT FOREACH
	END IF

END FOREACH
LET vm_ind_arr = i - 1
LET vm_num_sus = vm_ind_arr
IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF
FOR j = 1 TO vm_filas_pant
	DISPLAY r_detalle[j].* TO r_detalle[j].*
END FOR

END FUNCTION


                                                                                
FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68
                                                                                
END FUNCTION

                                                                                
                                                                                
FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
     CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
     EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
    CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
    EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
     EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
   CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc,'stop')
   EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION


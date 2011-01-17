{*
 * -- Titulo               : repp114.4gl -- Mantenimiento de Promociones 
 *											por item
 * -- Elaboración          : 3-sep-2001
 * -- Autor                : JCM
 * -- Formato de Ejecución : fglrun repp114 base RE 1 1
 *}  
                                                                              
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r110 	RECORD LIKE rept110.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant         CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp114.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base		= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_codloc	= arg_val(4)
LET vg_proceso	= 'repp114'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW repw114_1 AT 3,2 WITH 16 ROWS, 80 COLUMNS 
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM repf114_1 FROM '../forms/repf114_1'
DISPLAY FORM repf114_1
INITIALIZE rm_r110.* TO NULL
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
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 

		  IF fl_control_permiso_opcion('Bloquear') THEN
		       SHOW OPTION 'Bloquear/Activar'
		  END IF
		
		END IF

		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
        COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			IF fl_control_permiso_opcion('Modificar') THEN			
			   SHOW OPTION 'Modificar'
			END IF 

		 	IF fl_control_permiso_opcion('Bloquear') THEN
		           SHOW OPTION 'Bloquear/Activar'
		 	END IF	

			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'

			IF fl_control_permiso_opcion('Modificar') THEN			
			   SHOW OPTION 'Modificar'
			END IF 

		        IF fl_control_permiso_opcion('Bloquear') THEN
		           SHOW OPTION 'Bloquear/Activar'
		        END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
        COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
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
	COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE r_r10		RECORD LIKE rept010.*

DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql 
	   ON r110_estado, r110_item, r110_fecha_inicio, 
		  r110_fecha_limite, r110_descripcion, r110_descuento, r110_recargo,
		  r110_stock_limite, r110_hasta_ingreso, r110_usuario
	ON KEY(F2)
		IF INFIELD(r110_item) THEN
			CALL fl_ayuda_maestro_items(vg_codcia, 'TODOS') 
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre
			IF r_r10.r10_codigo IS NOT NULL THEN
			    LET rm_r110.r110_item = r_r10.r10_codigo
			    DISPLAY BY NAME rm_r110.r110_item
				DISPLAY r_r10.r10_nombre TO tit_item
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows >0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept110 ',
			' WHERE r110_compania = ', vg_codcia, 
			'   AND r110_localidad = ', vg_codloc, 
			'   AND ', expr_sql CLIPPED, ' ORDER BY 1, 2, 3'

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r110.*, vm_r_rows[vm_num_rows]
	IF vm_num_rows >= vm_max_rows THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF 
	LET vm_num_rows = vm_num_rows + 1
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

LET vm_flag_mant = 'I'
CLEAR FORM
INITIALIZE rm_r110.* TO NULL
LET rm_r110.r110_fecing     	= CURRENT
LET rm_r110.r110_usuario    	= vg_usuario
LET rm_r110.r110_compania   	= vg_codcia
LET rm_r110.r110_localidad  	= vg_codloc
LET rm_r110.r110_fecha_inicio	= TODAY
LET rm_r110.r110_estado     	= 'A'
LET rm_r110.r110_hasta_ingreso 	= 'N'
DISPLAY BY NAME rm_r110.r110_hasta_ingreso, rm_r110.r110_estado, 
				rm_r110.r110_fecing, rm_r110.r110_usuario, 
				rm_r110.r110_fecha_inicio
DISPLAY 'ACTIVO' TO tit_estado
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
	INSERT INTO rept110 VALUES (rm_r110.*)
	COMMIT WORK
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
IF rm_r110.r110_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM rept110 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_r110.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
	UPDATE rept110 SET r110_fecha_inicio  = rm_r110.r110_fecha_inicio,
					   r110_fecha_limite  = rm_r110.r110_fecha_limite,
					   r110_descripcion   = rm_r110.r110_descripcion, 
					   r110_descuento     = rm_r110.r110_descuento, 
					   r110_recargo       = rm_r110.r110_recargo, 
					   r110_stock_limite  = rm_r110.r110_stock_limite,
					   r110_hasta_ingreso = rm_r110.r110_hasta_ingreso
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION


FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF rm_r110.r110_compania IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET mensaje = 'Seguro de bloquear'
IF rm_r110.r110_estado <> 'A' THEN
	LET mensaje = 'Seguro de activar'
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	DECLARE q_del CURSOR FOR SELECT * FROM rept110 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_r110.*
	IF status < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	WHENEVER ERROR STOP
	LET estado = 'B'
	IF rm_r110.r110_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	UPDATE rept110 SET r110_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	LET int_flag = 0
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM	
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_datos()
DEFINE resp    		CHAR(6)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r110		RECORD LIKE rept110.*

OPTIONS INPUT WRAP, ACCEPT KEY	F12
LET int_flag = 0
INPUT BY NAME rm_r110.r110_estado, rm_r110.r110_item, 
			  rm_r110.r110_fecha_inicio, rm_r110.r110_fecha_limite, 
			  rm_r110.r110_descripcion, 
			  rm_r110.r110_descuento, rm_r110.r110_recargo, 
			  rm_r110.r110_stock_limite, 
			  rm_r110.r110_hasta_ingreso, rm_r110.r110_usuario, rm_r110.r110_fecing
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched(rm_r110.r110_estado, rm_r110.r110_item, 
							  rm_r110.r110_fecha_inicio, rm_r110.r110_fecha_limite, 
							  rm_r110.r110_descripcion, rm_r110.r110_descuento, 
							  rm_r110.r110_recargo,
							  rm_r110.r110_stock_limite, rm_r110.r110_hasta_ingreso, 
							  rm_r110.r110_usuario, rm_r110.r110_fecing)
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
	ON KEY(F2)
		IF INFIELD(r110_item) THEN
			CALL fl_ayuda_maestro_items(vg_codcia, 'TODOS') 
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre
			IF r_r10.r10_codigo IS NOT NULL THEN
			    LET rm_r110.r110_item = r_r10.r10_codigo
			    DISPLAY BY NAME rm_r110.r110_item
				DISPLAY r_r10.r10_nombre TO tit_item
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r110_item
		IF rm_r110.r110_item IS NULL THEN
			CALL fl_lee_item(vg_codcia, rm_r110.r110_item) RETURNING r_r10.*
			IF r_r10.r10_codigo IS NULL THEN
        		CALL fgl_winmessage(vg_producto, 'No existe item: ' || rm_r110.r110_item, 
									'exclamation')
				NEXT FIELD r110_item
			END IF
			IF r_r10.r10_estado = 'B' THEN
        		CALL fgl_winmessage(vg_producto, 'El item esta bloqueado.', 'exclamation')
				NEXT FIELD r110_item
			END IF
		END IF
	BEFORE FIELD r110_item
		NEXT FIELD r110_fecha_limite
	BEFORE FIELD r110_fecha_inicio
		NEXT FIELD r110_fecha_limite
	AFTER FIELD r110_descuento
		IF r_r110.r110_descuento IS NOT NULL THEN
			IF r_r110.r110_descuento < 0 THEN
				CALL fgl_winmessage(vg_producto, "No puede ingresar valores negativos.", "exclamation")
				NEXT FIELD r110_descuento
			END IF
			INITIALIZE r_r110.r110_recargo TO NULL
			DISPLAY BY NAME r_r110.r110_recargo
		END IF
	AFTER FIELD r110_recargo
		IF r_r110.r110_recargo IS NOT NULL THEN
			IF r_r110.r110_recargo < 0 THEN
				CALL fgl_winmessage(vg_producto, "No puede ingresar valores negativos.", "exclamation")
				NEXT FIELD r110_recargo
			END IF
			INITIALIZE r_r110.r110_descuento TO NULL
			DISPLAY BY NAME r_r110.r110_descuento
		END IF
	AFTER INPUT
		IF rm_r110.r110_fecha_limite IS NULL AND rm_r110.r110_stock_limite IS NULL AND
		   rm_r110.r110_hasta_ingreso = 'N'
		THEN
        	CALL fgl_winmessage(vg_producto, 'Debe escoger una condicion para terminar la promocion.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_r110.r110_fecha_limite IS NOT NULL THEN
			IF rm_r110.r110_fecha_inicio > rm_r110.r110_fecha_limite THEN
        		CALL fgl_winmessage(vg_producto, 'La fecha de inicio debe ser menor o igual a la fecha limite.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF rm_r110.r110_descuento IS NOT NULL AND 
		   rm_r110.r110_recargo IS NOT NULL
		THEN
			CALL fgl_winmessage(vg_producto, "Solo puede ingresar un descuento o un recargo pero no ambos.", "exclamation")
			CONTINUE INPUT
		END IF
		IF rm_r110.r110_recargo IS NOT NULL AND rm_r110.r110_stock_limite IS NOT NULL
		THEN
			CALL fgl_winmessage(vg_producto, "En recargo no puede haber stock limite.", "exclamation")
			CONTINUE INPUT
		END IF
		
		IF vm_flag_mant = 'I' THEN
			CALL fl_obtener_promocion_activa_item(vg_codcia, vg_codloc, rm_r110.r110_item)
				RETURNING r_r110.* 
			IF r_r110.r110_compania IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto,'Ya existe una promocion activa con esta fecha de inicio.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_r10		RECORD LIKE rept010.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r110.* FROM rept110 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_r110.r110_estado, rm_r110.r110_item, rm_r110.r110_fecha_inicio, 
			  rm_r110.r110_fecha_limite, rm_r110.r110_descripcion, 
			  rm_r110.r110_descuento, rm_r110.r110_recargo, 
			  rm_r110.r110_stock_limite, 
			  rm_r110.r110_hasta_ingreso, rm_r110.r110_usuario, rm_r110.r110_fecing
IF rm_r110.r110_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
CALL fl_lee_item(vg_codcia, rm_r110.r110_item) RETURNING r_r10.*
DISPLAY r_r10.r10_nombre TO tit_item

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
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
        CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION


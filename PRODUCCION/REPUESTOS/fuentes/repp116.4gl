-------------------------------------------------------------------------------
-- Titulo               : repp116.4gl -- Mantenimiento de Series
-- Elaboración          : 08-Oct-2002
-- Autor                : NPC
-- Formato de Ejecución : fglrun repp116 Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_r76   	RECORD LIKE rept076.*
DEFINE rm_ser		ARRAY[1000] OF RECORD
				r76_item	LIKE rept076.r76_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r76_serie	LIKE rept076.r76_serie,
				estado		VARCHAR(10)
			END RECORD
DEFINE vm_r_rows	ARRAY[1000] OF RECORD
				r76_compania	LIKE rept076.r76_compania,
				r76_localidad	LIKE rept076.r76_localidad,
				r76_bodega	LIKE rept076.r76_bodega,
				r76_item	LIKE rept076.r76_item
			END RECORD
DEFINE cont_ser_item	INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_det 	SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_max_det       SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
     	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp116'
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
LET vm_max_det  = 1000
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
OPEN WINDOW w_item AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM '../forms/repf116_1'
ELSE
	OPEN FORM f_rep FROM '../forms/repf116_1c'
END IF
DISPLAY FORM f_rep
INITIALIZE rm_r76.* TO NULL
CALL borrar_cabecera()
CALL iniciar_arr()
CALL borrar_arr()
CALL mostrar_botones_detalle()
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_num_det     = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		HIDE OPTION 'Detalle'
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		SHOW OPTION 'Detalle'
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
		SHOW OPTION 'Detalle'
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
		CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE est		VARCHAR(10)
DEFINE i		SMALLINT

CALL borrar_cabecera()
CALL iniciar_arr()
CALL borrar_arr()
CALL mostrar_botones_detalle()
INITIALIZE rm_r76.* TO NULL
LET rm_r76.r76_compania   = vg_codcia
LET rm_r76.r76_localidad  = vg_codloc
LET rm_r76.r76_estado 	  = 'A'
LET rm_r76.r76_fecing     = fl_current()
LET rm_r76.r76_usuario    = vg_usuario
DISPLAY BY NAME rm_r76.r76_estado
IF vg_gui = 0 THEN
	CALL muestra_estado(rm_r76.r76_estado, 'C') RETURNING est
END IF
DISPLAY BY NAME rm_r76.r76_fecing, rm_r76.r76_usuario
CALL lee_cabecera()
IF NOT int_flag THEN
	CALL lee_detalle()
	IF NOT int_flag THEN
		BEGIN WORK
			FOR i = 1 TO vm_num_det
				LET rm_r76.r76_fecing = fl_current()
	 			INSERT INTO rept076
					VALUES (rm_r76.r76_compania,
						rm_r76.r76_localidad,
						rm_r76.r76_bodega,
						rm_r76.r76_item,
						rm_ser[i].r76_serie,
						rm_r76.r76_estado,
						rm_r76.r76_usuario,
						rm_r76.r76_fecing)
			END FOR
		COMMIT WORK
        	IF vm_num_rows = vm_max_rows THEN
                	LET vm_num_rows = 1
  		ELSE
        	        LET vm_num_rows = vm_num_rows + 1
        	END IF
		LET vm_r_rows[vm_num_rows].r76_compania  = rm_r76.r76_compania
		LET vm_r_rows[vm_num_rows].r76_localidad = rm_r76.r76_localidad
		LET vm_r_rows[vm_num_rows].r76_bodega    = rm_r76.r76_bodega
		LET vm_r_rows[vm_num_rows].r76_item      = rm_r76.r76_item
		LET vm_row_current = vm_num_rows
		CALL fl_mensaje_registro_ingresado()
	END IF
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current].*)
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql1	CHAR(400)
DEFINE expr_sql2	CHAR(400)
DEFINE expr_estado	CHAR(100)
DEFINE query		CHAR(1000)
DEFINE est		VARCHAR(10)
DEFINE r_selo		RECORD LIKE rept076.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r02		RECORD LIKE rept002.*

CLEAR FORM
CALL mostrar_botones_detalle()
INITIALIZE rm_r76.* TO NULL
WHILE TRUE
	OPTIONS INPUT NO WRAP
	LET int_flag = 0 
	CONSTRUCT BY NAME expr_sql1 ON r76_bodega, r76_item
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r76_bodega) THEN
				CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'T', 'T', 'V')
			     		RETURNING r_r02.r02_codigo,
						r_r02.r02_nombre
			     	IF r_r02.r02_codigo IS NOT NULL THEN
					LET rm_r76.r76_bodega = r_r02.r02_codigo
					DISPLAY BY NAME rm_r76.r76_bodega,
							r_r02.r02_nombre
			     	END IF
			END IF
			IF INFIELD(r76_item) THEN
				CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
			     		RETURNING r_r10.r10_codigo,
						r_r10.r10_nombre
			     	IF r_r10.r10_codigo IS NOT NULL THEN
					LET rm_r76.r76_item = r_r10.r10_codigo
					DISPLAY BY NAME rm_r76.r76_item,
							r_r10.r10_nombre
			     	END IF
			END IF
	                LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD r76_bodega
			LET rm_r76.r76_bodega = get_fldbuf(r76_bodega)
			IF rm_r76.r76_bodega IS NOT NULL THEN
				CALL fl_lee_bodega_rep(vg_codcia,
							rm_r76.r76_bodega)
					RETURNING r_r02.*
				IF r_r02.r02_compania IS NULL THEN
					CALL fl_mostrar_mensaje('No existe esa Bodega.','exclamation')
					NEXT FIELD r76_bodega
				END IF
				IF r_r02.r02_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD r76_bodega
				END IF
				DISPLAY BY NAME r_r02.r02_nombre
			ELSE
				CLEAR r02_nombre
			END IF
		AFTER FIELD r76_item
			LET rm_r76.r76_item = get_fldbuf(r76_item)
			IF rm_r76.r76_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, rm_r76.r76_item)
					RETURNING r_r10.*
				IF r_r10.r10_compania IS NULL THEN
					CALL fl_mostrar_mensaje('No existe ese ítem.','exclamation')
					NEXT FIELD r76_item
				END IF
				IF r_r10.r10_estado = 'B' THEN
					CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD r76_item
				END IF
				DISPLAY BY NAME r_r10.r10_nombre
			ELSE
				CLEAR r10_nombre
			END IF
	END CONSTRUCT
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	LET rm_r76.r76_estado = 'T'
	IF vg_gui = 0 THEN
		CALL muestra_estado(rm_r76.r76_estado, 'C') RETURNING est
	END IF
	LET int_flag = 0 
	INPUT BY NAME rm_r76.r76_estado
		WITHOUT DEFAULTS
	        ON KEY(INTERRUPT)
        	       	LET int_flag = 1
        		CLEAR FORM
			CALL muestra_contadores_det(0)
			CALL mostrar_botones_detalle()
                	RETURN
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD r76_estado
			IF vg_gui = 0 THEN
				IF rm_r76.r76_estado IS NOT NULL THEN
					CALL muestra_estado(rm_r76.r76_estado,
								'C')
						RETURNING est
				ELSE
					CLEAR tit_estado
				END IF
			END IF
	END INPUT
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	OPTIONS INPUT WRAP
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql2 ON r76_serie, r76_usuario, r76_fecing
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag = 0 THEN
		EXIT WHILE
	END IF
END WHILE
IF int_flag THEN
	CLEAR FORM
	CALL mostrar_botones_detalle()
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current].*)
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	RETURN
END IF
LET expr_estado = '  AND r76_estado    = "', rm_r76.r76_estado, '"'
IF rm_r76.r76_estado = 'T' THEN
	LET expr_estado = '  AND r76_estado IN ("A", "F", "D", "E")'
END IF
LET query = 'SELECT UNIQUE r76_compania, r76_localidad, r76_bodega, r76_item',
		' FROM rept076 ',
		'WHERE r76_compania  = ', vg_codcia,
		'  AND r76_localidad = ', vg_codloc,
		'  AND ', expr_sql1 CLIPPED,
		expr_estado CLIPPED,
		'  AND ', expr_sql2 CLIPPED
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO vm_r_rows[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	LET vm_num_det     = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
        CLEAR FORM
	CALL mostrar_botones_detalle()
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current].*)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)

END FUNCTION



FUNCTION lee_cabecera()
DEFINE resp      	CHAR(6)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r02		RECORD LIKE rept002.*

LET int_flag = 0 
INPUT BY NAME rm_r76.r76_bodega, rm_r76.r76_item
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	IF field_touched(rm_r76.r76_bodega, rm_r76.r76_item) THEN
                	LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                        	LET int_flag = 1
        			CLEAR FORM
				CALL muestra_contadores_det(0)
				CALL mostrar_botones_detalle()
                        	RETURN
                        END IF
                ELSE
        		CLEAR FORM
			CALL muestra_contadores_det(0)
			CALL mostrar_botones_detalle()
                        RETURN
                END IF       	
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r76_bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'T', 'T', 'V')
		     		RETURNING r_r02.r02_codigo, r_r02.r02_nombre
		     	IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r76.r76_bodega = r_r02.r02_codigo
				DISPLAY BY NAME rm_r76.r76_bodega,
						r_r02.r02_nombre
		     	END IF
		END IF
		IF INFIELD(r76_item) THEN
			CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
		     		RETURNING r_r10.r10_codigo, r_r10.r10_nombre
		     	IF r_r10.r10_codigo IS NOT NULL THEN
				LET rm_r76.r76_item = r_r10.r10_codigo
				DISPLAY BY NAME rm_r76.r76_item,
						r_r10.r10_nombre
		     	END IF
		END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r76_bodega
		IF rm_r76.r76_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r76.r76_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esa Bodega.','exclamation')
				NEXT FIELD r76_bodega
			END IF
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r76_bodega
			END IF
			DISPLAY BY NAME r_r02.r02_nombre
		ELSE
			CLEAR r02_nombre
		END IF
	AFTER FIELD r76_item
		IF rm_r76.r76_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_r76.r76_item)
				RETURNING r_r10.*
			IF r_r10.r10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe ese ítem.','exclamation')
				NEXT FIELD r76_item
			END IF
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r76_item
			END IF
			DISPLAY BY NAME r_r10.r10_nombre
		ELSE
			CLEAR r10_nombre
		END IF
END INPUT

END FUNCTION



FUNCTION lee_detalle()
DEFINE resp      	CHAR(6)
DEFINE i, j, k, l	SMALLINT
DEFINE faltan_ing	INTEGER
DEFINE r_selo		RECORD LIKE rept076.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r10		RECORD LIKE rept010.*

CALL set_count(vm_num_det)
LET int_flag = 0
INPUT ARRAY rm_ser WITHOUT DEFAULTS FROM rm_ser.*
	ON KEY(INTERRUPT)
       	       	LET int_flag = 0
       		CALL fl_mensaje_abandonar_proceso() RETURNING resp
              	IF resp = 'Yes' THEN
       			LET int_flag = 1
        		CLEAR FORM
			CALL muestra_contadores_det(0)
			CALL mostrar_botones_detalle()
          		RETURN
        	END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas() 
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		LET i = arr_curr()
		CALL fl_lee_item(vg_codcia, rm_r76.r76_item)
			RETURNING r_r10.*
		IF r_r10.r10_serie_lote <> 'S' OR
		   r_r10.r10_serie_lote IS NULL THEN
			CALL mensaje_salir('Este ítem no es seriado.','exclamation')
       			LET int_flag = 1
			EXIT INPUT
		END IF
		CALL fl_lee_stock_rep(vg_codcia, rm_r76.r76_bodega,
					rm_r76.r76_item)
			RETURNING r_r11.*
		IF r_r11.r11_stock_act = 0 OR r_r11.r11_stock_act IS NULL THEN
			CALL mensaje_salir('No existe stock en esta bodega para este ítem.','exclamation')
       			LET int_flag = 1
			EXIT INPUT
		END IF
		CALL obtener_num_serie_ing() RETURNING faltan_ing
		IF faltan_ing = 0 THEN
			CALL mensaje_salir('Este ítem ya tiene series asignadas para el stock actual.','exclamation')
       			LET int_flag = 1
			EXIT INPUT
		END IF
		CALL fl_mostrar_mensaje('Usted debe ingresar ' || faltan_ing || ' números de serie para este ítem.','info')
	BEFORE DELETE
		INITIALIZE rm_ser[i].* TO NULL
		LET vm_num_det = arr_count()
		CALL muestra_contadores_det(i)
		--DISPLAY vm_num_det TO cont_ser_item
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET vm_num_det = arr_count()
		CALL muestra_contadores_det(i)
		--DISPLAY vm_num_det TO cont_ser_item
	AFTER FIELD r76_serie
		IF rm_ser[i].r76_serie IS NOT NULL THEN
			CALL fl_lee_serie_rep(vg_codcia, vg_codloc,
					rm_r76.r76_bodega, rm_r76.r76_item,
					rm_ser[i].r76_serie)
				RETURNING r_selo.*
			IF r_selo.r76_serie IS NOT NULL THEN
				CALL fl_mostrar_mensaje('El Código de la Serie ya existe en esta Compañía.','exclamation')
				NEXT FIELD r76_serie
       			END IF
			CALL fl_lee_item(vg_codcia, rm_r76.r76_item)
				RETURNING r_r10.*
			LET rm_ser[i].r76_item   = r_r10.r10_codigo
			LET rm_ser[i].r10_nombre = r_r10.r10_nombre
			LET rm_ser[i].estado     = muestra_estado ('A', 'D') 
			DISPLAY rm_ser[i].r76_item   TO rm_ser[j].r76_item
			DISPLAY rm_ser[i].r10_nombre TO rm_ser[j].r10_nombre
			DISPLAY rm_ser[i].estado     TO rm_ser[j].estado
       		END IF
	AFTER INPUT
		LET cont_ser_item = arr_count()
		IF faltan_ing <> cont_ser_item THEN
			CALL fl_mostrar_mensaje('Los números de serie ingresados no coinciden con el stock actual del ítem.','exclamation')
			NEXT FIELD r76_serie
		END IF
		--DISPLAY BY NAME cont_ser_item
		FOR k = 1 TO vm_num_det - 1
			FOR l = k + 1 TO vm_num_det
				IF rm_ser[k].r76_serie = rm_ser[l].r76_serie
				THEN
					CALL fl_mostrar_mensaje('Existe en el detalle un número de serie repetido.','exclamation')
					NEXT FIELD r76_serie
				END IF
			END FOR
		END FOR
END INPUT
LET vm_num_det = arr_count()

END FUNCTION



FUNCTION mensaje_salir(mensaje, icono)
DEFINE mensaje		VARCHAR(150)
DEFINE icono		VARCHAR(20)

CALL fl_mostrar_mensaje(mensaje, icono)
CALL borrar_cabecera()
CALL iniciar_arr()
CALL borrar_arr()
CALL mostrar_botones_detalle()
CALL muestra_contadores_det(0)
IF vg_gui = 0 THEN
	CLEAR tit_estado
END IF

END FUNCTION



FUNCTION obtener_num_serie_ing()
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE falta		INTEGER

SELECT COUNT(*) INTO cont_ser_item
	FROM rept076
	WHERE r76_compania  = vg_codcia
	  AND r76_localidad = vg_codloc
	  AND r76_bodega    = rm_r76.r76_bodega
	  AND r76_item      = rm_r76.r76_item
	  AND r76_estado    = 'A'
CALL fl_lee_stock_rep(vg_codcia, rm_r76.r76_bodega, rm_r76.r76_item)
	RETURNING r_r11.*
DISPLAY BY NAME r_r11.r11_stock_act --, cont_ser_item
LET falta = r_r11.r11_stock_act - cont_ser_item
RETURN falta

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		RECORD
				r76_compania	LIKE rept076.r76_compania,
				r76_localidad	LIKE rept076.r76_localidad,
				r76_bodega	LIKE rept076.r76_bodega,
				r76_item	LIKE rept076.r76_item
			END RECORD
DEFINE query		CHAR(1000)
DEFINE expr_bodega	CHAR(100)
DEFINE expr_item	CHAR(100)
DEFINE expr_estado	CHAR(100)
DEFINE est		VARCHAR(10)
DEFINE r_r76		RECORD LIKE rept076.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE falta		INTEGER
DEFINE i, max_row	SMALLINT
DEFINE estado_ser	CHAR(1)

IF vm_num_rows <= 0 THEN
	RETURN
END IF
DECLARE q_ser CURSOR FOR
	SELECT UNIQUE * FROM rept076
	WHERE r76_compania  = num_row.r76_compania
	  AND r76_localidad = num_row.r76_localidad
	  AND r76_bodega    = num_row.r76_bodega
	  AND r76_item      = num_row.r76_item
	ORDER BY 5
OPEN q_ser
FETCH q_ser INTO r_r76.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current || '.','exclamation')
	RETURN
END IF
LET rm_r76.r76_compania  = r_r76.r76_compania
LET rm_r76.r76_localidad = r_r76.r76_localidad
LET rm_r76.r76_bodega    = r_r76.r76_bodega
LET rm_r76.r76_item      = r_r76.r76_item
LET rm_r76.r76_serie     = r_r76.r76_serie
LET rm_r76.r76_usuario   = r_r76.r76_usuario
LET rm_r76.r76_fecing    = r_r76.r76_fecing
DISPLAY BY NAME rm_r76.r76_bodega, rm_r76.r76_item, rm_r76.r76_estado,
		rm_r76.r76_usuario, rm_r76.r76_fecing
CALL fl_lee_bodega_rep(vg_codcia, rm_r76.r76_bodega) RETURNING r_r02.*
DISPLAY BY NAME r_r02.r02_nombre
CALL fl_lee_item(vg_codcia, rm_r76.r76_item) RETURNING r_r10.*
DISPLAY BY NAME r_r10.r10_nombre
IF vg_gui = 0 THEN
	CALL muestra_estado(rm_r76.r76_estado, 'C') RETURNING est
END IF
CALL obtener_num_serie_ing() RETURNING falta
LET expr_bodega = NULL
IF num_row.r76_bodega IS NOT NULL THEN
	LET expr_bodega = '  AND r76_bodega    = "', num_row.r76_bodega, '"'
END IF
LET expr_item = NULL
IF num_row.r76_item IS NOT NULL THEN
	LET expr_item   = '  AND r76_item      = "', num_row.r76_item, '"' 
END IF
LET expr_estado = '  AND r76_estado    = "', rm_r76.r76_estado, '"'
IF rm_r76.r76_estado = 'T' THEN
	LET expr_estado = '  AND r76_estado IN ("A", "F", "D", "E")'
END IF
LET query = 'SELECT r76_serie, r76_estado ',
		'FROM rept076 ',
		'WHERE r76_compania  = ', num_row.r76_compania,
		'  AND r76_localidad = ', num_row.r76_localidad,
		expr_bodega CLIPPED,
		expr_item CLIPPED,
		expr_estado CLIPPED
PREPARE serie_item FROM query
DECLARE q_serie CURSOR FOR serie_item
LET vm_num_det = 1
FOREACH q_serie INTO rm_ser[vm_num_det].r76_serie, estado_ser
	LET rm_ser[vm_num_det].r76_item   = rm_r76.r76_item
	LET rm_ser[vm_num_det].r10_nombre = r_r10.r10_nombre
	LET rm_ser[vm_num_det].estado     = muestra_estado (estado_ser,'D') 
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
CALL borrar_arr()
LET max_row = fgl_scr_size('rm_ser')
IF vm_num_det < fgl_scr_size('rm_ser') THEN
	LET max_row = vm_num_det
END IF
FOR i = 1 TO max_row
	DISPLAY rm_ser[i].* TO rm_ser[i].*
END FOR
CLOSE q_ser

END FUNCTION

                                                                                
                                                                                
FUNCTION muestra_estado(estado, cabdet)
DEFINE estado		CHAR(1)
DEFINE cabdet		CHAR(1)
DEFINE desest		VARCHAR(10)

LET desest = NULL
CASE estado
	WHEN 'A'
		CASE cabdet
			WHEN 'C'
				DISPLAY 'ACTIVO' TO tit_estado
			WHEN 'D'
				RETURN 'ACTIVO'
		END CASE
	WHEN 'F'
		CASE cabdet
			WHEN 'C'
				DISPLAY 'FACTURADO' TO tit_estado
			WHEN 'D'
				RETURN 'FACTURADO'
		END CASE
	WHEN 'D'
		CASE cabdet
			WHEN 'C'
				DISPLAY 'DESPACHADO' TO tit_estado
			WHEN 'D'
				RETURN 'DESPACHADO'
		END CASE
	WHEN 'E'
		CASE cabdet
			WHEN 'C'
				DISPLAY 'ELIMINADO' TO tit_estado
			WHEN 'D'
				RETURN 'ELIMINADO'
		END CASE
	WHEN 'T'
		CASE cabdet
			WHEN 'C'
				DISPLAY 'T O D O S' TO tit_estado
			WHEN 'D'
				RETURN desest
		END CASE
	OTHERWISE
		CASE cabdet
			WHEN 'C'
				CLEAR r76_estado, tit_estado
			WHEN 'D'
				RETURN desest
		END CASE
END CASE
RETURN desest

END FUNCTION

                                                                                
                                                                                
FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current].*)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)

END FUNCTION

                                                                                
                                                                                
FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_r_rows[vm_row_current].*)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 1, 1
	DISPLAY row_current, " de ", num_rows AT 1, 67
END IF

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor                 SMALLINT

IF vg_gui = 1 THEN
	DISPLAY "" AT 10, 67
	DISPLAY cor, " de ", vm_num_det AT 10, 67
END IF

END FUNCTION

                                                                                
                                                                                
FUNCTION borrar_cabecera()

CLEAR r76_bodega, r02_nombre, r76_item, r10_nombre, r76_estado, r11_stock_act,
	r76_usuario, r76_fecing

END FUNCTION

                                                                                
                                                                                
FUNCTION iniciar_arr()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_ser[i].* TO NULL
END FOR
LET vm_num_det = 0

END FUNCTION

                                                                                
                                                                                
FUNCTION borrar_arr()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_ser')
	CLEAR rm_ser[i].*
END FOR

END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY 'Item'		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY 'Serie'		TO tit_col3
--#DISPLAY 'Estado'		TO tit_col4

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i		SMALLINT

LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_ser TO rm_ser.*
	ON KEY(INTERRUPT)
		LET int_flag   = 1
		CALL muestra_contadores_det(0)
		EXIT DISPLAY
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#CALL muestra_contadores_det(i)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY

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

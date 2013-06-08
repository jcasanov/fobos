------------------------------------------------------------------------------
-- Titulo           : talp203.4gl - Ingreso de materiales a presupuestos 
-- Elaboracion      : 13-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp203 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_tal		RECORD LIKE talt020.*
DEFINE rm_tal2		RECORD LIKE talt022.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE vm_total         LIKE talt020.t20_total_rp
DEFINE vm_r_rows	ARRAY [100] OF LIKE talt020.t20_numpre 
DEFINE rm_r10		RECORD LIKE rept010.*
DEFINE rm_ta 		ARRAY [100] OF RECORD
				t22_cantidad	LIKE talt022.t22_cantidad,
				t22_item	LIKE talt022.t22_item,
				t22_descripcion	LIKE talt022.t22_descripcion,
				t22_precio	LIKE talt022.t22_precio,
				t22_stock	LIKE talt022.t22_stock
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp203'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE indice           SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows	= 100
LET vm_max_elm  = 100
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
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_tal FROM "../forms/talf203_1"
ELSE
	OPEN FORM f_tal FROM "../forms/talf203_1c"
END IF
DISPLAY FORM f_tal
CALL mostrar_botones_detalle()
INITIALIZE rm_tal.*, rm_tal2.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
LET vm_num_elm = 0
LET vm_total   = 0
FOR indice = 1 TO vm_max_elm
        INITIALIZE rm_ta[indice].* TO NULL
END FOR
LET rm_tal2.t22_compania  = vg_codcia
LET rm_tal2.t22_localidad = vg_codloc
LET rm_tal2.t22_usuario   = vg_usuario
LET rm_tal2.t22_fecing    = CURRENT
LET vm_size_arr = fgl_scr_size('rm_ta')
{
IF vg_gui = 0 THEN
	LET vm_size_arr = 10
END IF
}
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
       	COMMAND KEY('M') 'Modificar' 'Ingresar/Modificar materiales a presupuesto. '
		CALL control_modificacion()
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
		IF vm_num_elm > vm_size_arr THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_elm > vm_size_arr THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
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
		IF vm_num_elm > vm_size_arr THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_modificacion()
DEFINE num_elm          SMALLINT
DEFINE indice           SMALLINT

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_lee_presupuesto_taller(vg_codcia,vg_codloc,vm_r_rows[vm_row_current])
        RETURNING rm_tal.*
IF rm_tal.t20_estado = 'P' THEN
        --CALL fgl_winmessage(vg_producto,'Este presupuesto ya ha sido aprobado','exclamation')
	CALL fl_mostrar_mensaje('Este presupuesto ya ha sido aprobado.','exclamation')
        RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_uppre2 CURSOR FOR SELECT * FROM talt020
	WHERE t20_compania  = vg_codcia AND
              t20_localidad = vg_codloc AND
              t20_numpre    = vm_r_rows[vm_row_current]
        FOR UPDATE
OPEN q_uppre2
FETCH q_uppre2 INTO rm_tal.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up CURSOR FOR SELECT * FROM talt022
	WHERE t22_compania = vg_codcia
	AND t22_localidad  = vg_codloc
	AND t22_numpre     = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tal2.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
LET vm_total   = 0
WHENEVER ERROR STOP
CALL leer_detalle() RETURNING num_elm
IF NOT int_flag THEN
	DELETE FROM talt022 WHERE t22_compania = vg_codcia
			AND t22_localidad  = vg_codloc
			AND t22_numpre     = rm_tal2.t22_numpre
	FOR indice = 1 TO arr_count()
		LET rm_tal2.t22_secuencia  = indice
		INSERT INTO talt022 VALUES (rm_tal2.t22_compania,
					rm_tal2.t22_localidad,
					rm_tal.t20_numpre,
					rm_tal2.t22_secuencia,
					rm_ta[indice].t22_item,
					rm_ta[indice].t22_descripcion,
					rm_ta[indice].t22_cantidad,
					rm_ta[indice].t22_precio,
					rm_ta[indice].t22_stock,
					rm_tal2.t22_usuario,
					rm_tal2.t22_fecing)
	END FOR
	LET int_flag = 0
        UPDATE talt020 SET t20_total_rp = rm_tal.t20_total_rp
                WHERE CURRENT OF q_uppre2
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CLEAR FORM
	CALL mostrar_botones_detalle()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
	COMMIT WORK
END IF
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
DEFINE numpre		LIKE talt020.t20_numpre
DEFINE codcli		LIKE talt023.t23_cod_cliente
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE query		CHAR(400)
DEFINE expr_sql		CHAR(400)

LET int_flag = 0
CLEAR FORM
CALL mostrar_botones_detalle()
INITIALIZE numpre TO NULL
CONSTRUCT BY NAME expr_sql ON t20_numpre
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t20_numpre) THEN
                	CALL fl_ayuda_presupuestos_taller(vg_codcia,vg_codloc,'A')
                                RETURNING numpre, codcli, nomcli
                        LET int_flag = 0
                        IF numpre IS NOT NULL THEN
				CALL fl_lee_presupuesto_taller(vg_codcia,
							vg_codloc, numpre)
					RETURNING rm_tal.*
                                DISPLAY numpre TO t20_numpre
				CALL muestra_cabecera()
                        END IF
                END IF
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
		CALL mostrar_botones_detalle()
	END IF
	RETURN
END IF
LET query = 'SELECT t20_numpre FROM talt020 ' ||
		'WHERE t20_compania = ' || vg_codcia ||
		' AND t20_localidad = ' || vg_codloc ||
		' AND ' || expr_sql CLIPPED ||
		' AND t20_estado = ' || '"' || 'A' || '"' || ' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	CALL mostrar_botones_detalle()
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_cabecera()

DISPLAY rm_tal.t20_nom_cliente TO tit_cliente

END FUNCTION



FUNCTION leer_detalle()
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j    		SMALLINT
DEFINE codi_aux		LIKE rept010.r10_codigo
DEFINE nomi_aux		LIKE rept010.r10_nombre
DEFINE descri_ori       LIKE talt022.t22_descripcion
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE grupo_linea	LIKE rept003.r03_grupo_linea
DEFINE bodega		LIKE rept002.r02_codigo

LET i = 1
LET resul = 0
INITIALIZE codi_aux, descri_ori, bodega, grupo_linea TO NULL
CALL set_count(vm_num_elm)
LET int_flag = 0
INPUT ARRAY rm_ta WITHOUT DEFAULTS FROM rm_ta.*
	ON KEY(INTERRUPT)
               	LET int_flag = 0
               	CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
              	IF resp = 'Yes' THEN
			LET vm_total = 0
               		LET int_flag = 1
               		CLEAR FORM
			CALL mostrar_botones_detalle()
          		RETURN i
               	END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t22_item) THEN
                	CALL fl_ayuda_maestro_items_stock(vg_codcia,grupo_linea,
							bodega)
				RETURNING codi_aux, nomi_aux,
					  r_r10.r10_linea,r_r10.r10_precio_mb,
					  r_r11.r11_bodega, stock
			LET int_flag = 0
			IF codi_aux IS NOT NULL THEN
				LET rm_tal2.t22_numpre = rm_tal.t20_numpre
				LET rm_ta[i].t22_item  = codi_aux
				DISPLAY codi_aux TO rm_ta[j].t22_item
				CALL muestra_descripcion(nomi_aux,i,j)
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
        	LET i = arr_curr()
        	LET j = scr_line()
		IF rm_ta[i].t22_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_ta[i].t22_item)
				RETURNING rm_r10.*
			CALL muestra_descripciones(rm_ta[i].t22_item,
				rm_r10.r10_linea, rm_r10.r10_sub_linea,
				rm_r10.r10_cod_grupo, 
				rm_r10.r10_cod_clase)
			DISPLAY rm_r10.r10_nombre TO tit_descri
		ELSE
			CLEAR tit_descri, descrip_1, descrip_2, descrip_3
		END IF
		CALL sacar_total()
	BEFORE FIELD t22_descripcion
                LET descri_ori = rm_ta[i].t22_descripcion
                DISPLAY rm_ta[i].t22_descripcion TO tit_descri
	AFTER FIELD t22_cantidad
		IF rm_ta[i].t22_descripcion IS NOT NULL
		AND rm_ta[i].t22_cantidad IS NULL THEN
			NEXT FIELD t22_cantidad
		END IF
	AFTER FIELD t22_item
		IF rm_ta[i].t22_item IS NOT NULL THEN
			LET rm_tal2.t22_numpre = rm_tal.t20_numpre
			CALL validar_item(i,j) RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t22_item
			END IF
			CALL muestra_descripciones(rm_ta[i].t22_item,
					rm_r10.r10_linea, rm_r10.r10_sub_linea,
					rm_r10.r10_cod_grupo, 
					rm_r10.r10_cod_clase)
			CALL sacar_total()
		ELSE
			CLEAR tit_descri, descrip_1, descrip_2, descrip_3
			IF rm_ta[i].t22_cantidad IS NULL THEN
				NEXT FIELD t22_cantidad
			END IF
			IF rm_ta[i].t22_descripcion IS NULL THEN
				CALL muestra_descripcion('ESCRIBA LA DESCRIPCION',i,j)
				LET rm_ta[i].t22_stock = 0
				DISPLAY rm_ta[i].t22_stock TO rm_ta[j].t22_stock
				CALL sacar_total()
			END IF
		END IF
	AFTER FIELD t22_descripcion
		IF rm_ta[i].t22_item IS NOT NULL THEN
			LET rm_ta[i].t22_descripcion = descri_ori
			CALL muestra_descripcion(rm_ta[i].t22_descripcion,i,j)
		ELSE
			IF rm_ta[i].t22_precio IS NULL AND resul = 2 THEN
                                NEXT FIELD t22_precio
                        END IF
		END IF
	AFTER FIELD t22_precio
		IF rm_ta[i].t22_item IS NOT NULL THEN
			LET rm_ta[i].t22_descripcion = descri_ori
			CALL muestra_descripcion(rm_ta[i].t22_descripcion,i,j)
		END IF
		IF rm_ta[i].t22_precio IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rm_tal.t20_moneda,
                                                        rm_ta[i].t22_precio)
                                RETURNING rm_ta[i].t22_precio
			DISPLAY rm_ta[i].t22_precio TO rm_ta[j].t22_precio
			CALL sacar_total()
			CONTINUE INPUT
		ELSE
			IF rm_ta[i].t22_descripcion IS NOT NULL THEN
                                NEXT FIELD t22_precio
                        END IF
		END IF
	AFTER DELETE
                CALL sacar_total()
	AFTER INPUT
                CALL sacar_total()
END INPUT
LET i = arr_count()
RETURN i
                                                                                
END FUNCTION



FUNCTION sacar_total()
DEFINE i        SMALLINT
                                                                                
LET vm_total = 0
FOR i = 1 TO arr_count()
        LET vm_total = vm_total + rm_ta[i].t22_precio
END FOR
LET rm_tal.t20_total_rp = vm_total + (vm_total * rm_tal.t20_recargo_rp / 100)
CALL mostrar_total()
                                                                                
END FUNCTION



FUNCTION validar_item(i,j)
DEFINE i,j		SMALLINT
DEFINE resul		SMALLINT
DEFINE rm_r10		RECORD LIKE rept010.*
DEFINE r_cia		RECORD LIKE rept000.*
DEFINE r_rep		RECORD LIKE rept011.*

INITIALIZE rm_r10.* TO NULL
INITIALIZE r_cia.* TO NULL
INITIALIZE r_rep.* TO NULL
CALL fl_lee_item(vg_codcia,rm_ta[i].t22_item) RETURNING rm_r10.*
IF rm_r10.r10_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Item no existe','exclamation')
	CALL fl_mostrar_mensaje('Item no existe.','exclamation')
	RETURN 1
END IF
CALL muestra_descripcion(rm_r10.r10_nombre,i,j)

IF rm_r10.r10_precio_mb > 0 THEN
	LET rm_ta[i].t22_precio = rm_r10.r10_precio_mb
	DISPLAY rm_ta[i].t22_precio TO rm_ta[j].t22_precio
END IF
IF rm_r10.r10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_cia.*
IF r_cia.r00_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Bodega no existe','exclamation')
	CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
	RETURN 1
END IF
IF r_cia.r00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
CALL fl_lee_stock_rep(vg_codcia,r_cia.r00_bodega_fact,rm_ta[i].t22_item)
	RETURNING r_rep.*
IF r_rep.r11_compania IS NULL THEN
	LET rm_ta[i].t22_stock = 0
ELSE
	LET rm_ta[i].t22_stock = r_rep.r11_stock_act
END IF
DISPLAY rm_ta[i].t22_stock TO rm_ta[j].t22_stock
RETURN 0

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY row_current, " de ", num_rows AT 1, 67
END IF
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	LIKE talt020.t20_numpre

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM talt020
                WHERE t20_compania  = vg_codcia AND
		      t20_localidad = vg_codloc AND
		      t20_numpre    = num_registro
        OPEN q_dt
        FETCH q_dt INTO rm_tal.*
	IF STATUS = NOTFOUND THEN
		--CALL fgl_winmessage(vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
        DECLARE q_dt2 CURSOR FOR SELECT * FROM talt022
                WHERE t22_compania  = vg_codcia AND
                      t22_localidad = vg_codloc AND
                      t22_numpre    = rm_tal.t20_numpre
        OPEN q_dt2
        FETCH q_dt2 INTO rm_tal2.*
	DISPLAY BY NAME	rm_tal.t20_numpre
	CALL muestra_cabecera()
	CALL muestra_detalle(num_registro)
ELSE
	RETURN
END IF
CLOSE q_dt
CLOSE q_dt2

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg          LIKE talt022.t22_numpre
DEFINE query            CHAR(400)
DEFINE i                SMALLINT
                                                                                
LET int_flag = 0
FOR i = 1 TO vm_size_arr
        INITIALIZE rm_ta[i].* TO NULL
        CLEAR rm_ta[i].*
END FOR
LET i = 1
LET query = 'SELECT t22_cantidad,t22_item,t22_descripcion,t22_precio,t22_stock FROM talt022 ' ||
                'WHERE t22_compania = ' || vg_codcia ||
		' AND t22_localidad = ' || vg_codloc ||
		' AND t22_numpre    = ' || num_reg CLIPPED || ' ORDER BY 2'
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_elm = 0
LET vm_total = 0
FOREACH q_cons1 INTO rm_ta[i].*
        LET vm_num_elm = vm_num_elm + 1
	LET vm_total = vm_total + rm_ta[i].t22_precio
        LET i = i + 1
        IF vm_num_elm > vm_max_elm THEN
        	LET vm_num_elm = vm_num_elm - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
IF vm_num_elm > 0 THEN
        LET int_flag = 0
        FOR i = 1 TO vm_size_arr
                DISPLAY rm_ta[i].* TO rm_ta[i].*
		DISPLAY rm_ta[i].t22_descripcion TO tit_descri
        END FOR
END IF
IF int_flag THEN
        INITIALIZE rm_ta[1].* TO NULL
        RETURN
END IF
CALL mostrar_total()

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i		SMALLINT

CALL set_count(vm_num_elm)
DISPLAY ARRAY rm_ta TO rm_ta.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#DISPLAY rm_ta[i].t22_descripcion TO tit_descri
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
                                                                                
END FUNCTION



FUNCTION mostrar_total()

DISPLAY vm_total TO tit_total

END FUNCTION



FUNCTION muestra_descripcion(descr,i,j)
DEFINE i,j		SMALLINT
DEFINE descr		LIKE talt022.t22_descripcion

LET rm_ta[i].t22_descripcion = descr 
DISPLAY rm_ta[i].t22_descripcion TO rm_ta[j].t22_descripcion
DISPLAY rm_ta[i].t22_descripcion TO tit_descri

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION mostrar_botones_detalle()

--#DISPLAY 'Cant'        TO tit_col1
--#DISPLAY 'Item'        TO tit_col2
--#DISPLAY 'Descripción' TO tit_col3
--#DISPLAY 'Precio'      TO tit_col4
--#DISPLAY 'Stock'       TO tit_col5

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r70.r70_desc_sub   TO descrip_1
DISPLAY r_r71.r71_desc_grupo TO descrip_2
DISPLAY r_r72.r72_desc_clase TO descrip_3

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

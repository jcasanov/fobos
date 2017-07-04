------------------------------------------------------------------------------
-- Titulo           : repp317.4gl - Consulta Inventario Físico 2004
-- Elaboracion      : 04-Nov-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp317 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE rm_r89		RECORD LIKE rept089.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE vm_bodega	LIKE rept089.r89_bodega
DEFINE vm_item		LIKE rept089.r89_item
DEFINE vm_desc_item	LIKE rept010.r10_nombre
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_ordenar	CHAR(1)
DEFINE rm_inventario	ARRAY [20000] OF RECORD
				r89_bodega	LIKE rept089.r89_bodega,
				r89_item	LIKE rept089.r89_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r89_bueno	LIKE rept089.r89_bueno,
				r89_incompleto	LIKE rept089.r89_incompleto,
				r89_mal_est	LIKE rept089.r89_mal_est,
				r89_suma	LIKE rept089.r89_suma,
				r89_stock_act	LIKE rept089.r89_stock_act
			END RECORD
DEFINE rm_periodo	ARRAY [20000] OF RECORD
				r89_anio	LIKE rept089.r89_anio,
				r89_mes		LIKE rept089.r89_mes
			END RECORD
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp317.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp317'
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
LET vm_max_det = 20000
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 22
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp317 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf317 FROM "../forms/repf317_1"
ELSE
	OPEN FORM f_repf317 FROM "../forms/repf317_1c"
END IF
DISPLAY FORM f_repf317
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia
	  AND r01_user_owner = vg_usuario
OPEN qu_vd
INITIALIZE rm_vend.* TO NULL
FETCH qu_vd INTO rm_vend.*
IF STATUS = NOTFOUND THEN
	IF rm_g05.g05_tipo = 'UF' THEN
		CALL fl_mostrar_mensaje('Usted no está configurado en la tabla de vendedores/bodegueros.','stop')
		RETURN
	END IF
END IF
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()

CALL borrar_cabecera()
CALL mostrar_botones_det()
LET rm_r89.r89_usuario = vg_usuario
CALL obtener_fecha_ini()
LET vm_fecha_fin       = TODAY
LET vm_ordenar         = 'N'
WHILE TRUE
	CALL borrar_detalle()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL ejecuta_consulta()
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repp317
EXIT PROGRAM

END FUNCTION



FUNCTION ejecuta_consulta()
DEFINE r_r89		RECORD LIKE rept089.*
DEFINE secuen		LIKE rept089.r89_secuencia
DEFINE query		CHAR(1000)
DEFINE expr_bod         VARCHAR(100)
DEFINE expr_ite         VARCHAR(100)
DEFINE i, j, col	SMALLINT

LET expr_bod = NULL
IF vm_bodega IS NOT NULL THEN
	LET expr_bod = '   AND r89_bodega    = "', vm_bodega, '"'
END IF
LET expr_ite = NULL
IF vm_item IS NOT NULL THEN
	LET expr_ite = '   AND r89_item      = "', vm_item CLIPPED, '"'
END IF
LET query = 'SELECT r89_bodega, r89_item, r10_nombre, r89_bueno, ',
			'r89_incompleto, r89_mal_est, r89_suma, r89_stock_act,',
			' r89_anio, r89_mes, r89_secuencia ',
		' FROM rept089, rept010 ',
		' WHERE r89_compania  =  ', vg_codcia,
		'   AND r89_localidad =  ', vg_codloc,
		expr_bod CLIPPED, 
		expr_ite CLIPPED, 
		'   AND r89_usuario   = "', rm_r89.r89_usuario, '"',
		'   AND r89_fecha BETWEEN "', vm_fecha_ini,
				   '" AND "', vm_fecha_fin, '"',
		'   AND r10_compania  = r89_compania ',
		'   AND r10_codigo    = r89_item ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 9
LET vm_columna_1           = col
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT r89_bodega, r89_item, r10_nombre, r89_bueno, ',
			'r89_incompleto, r89_mal_est, r89_suma, r89_stock_act,',
			' r89_anio, r89_mes, r89_secuencia ',
			' FROM t1 ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET i = 1
	FOREACH q_deto INTO rm_inventario[i].*, rm_periodo[i].*, secuen
		LET i = i + 1
		IF i > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	LET vm_num_det = i
	IF vg_gui = 0 THEN
		CALL muestra_etiquetas(rm_inventario[1].r89_item, 1, vm_num_det)
	END IF
	CALL obtener_totales()
	CALL set_count(vm_num_det)
	LET int_flag = 0
	DISPLAY ARRAY rm_inventario TO rm_inventario.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
       		ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			CALL control_modificar(i, j)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_otros_datos(i)
			LET int_flag = 0
		ON KEY(F7)
			CALL control_imprimir()
			LET int_flag = 0
		ON KEY(RETURN)
			LET i = arr_curr()
			CALL muestra_etiquetas(rm_inventario[i].r89_item, i,
						vm_num_det)
		ON KEY(F15)
			IF vm_ordenar = 'S' THEN
				LET col = 1
				EXIT DISPLAY
			END IF
		ON KEY(F16)
			IF vm_ordenar = 'S' THEN
				LET col = 2
				EXIT DISPLAY
			END IF
		ON KEY(F17)
			IF vm_ordenar = 'S' THEN
				LET col = 3
				EXIT DISPLAY
			END IF
		ON KEY(F18)
			IF vm_ordenar = 'S' THEN
				LET col = 4
				EXIT DISPLAY
			END IF
		ON KEY(F19)
			IF vm_ordenar = 'S' THEN
				LET col = 5
				EXIT DISPLAY
			END IF
		ON KEY(F20)
			IF vm_ordenar = 'S' THEN
				LET col = 6
				EXIT DISPLAY
			END IF
		ON KEY(F21)
			IF vm_ordenar = 'S' THEN
				LET col = 7
				EXIT DISPLAY
			END IF
		ON KEY(F22)
			IF vm_ordenar = 'S' THEN
				LET col = 8
				EXIT DISPLAY
			END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("F7","Imprimir Listado")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_etiquetas(rm_inventario[i].r89_item, i,
						--#vm_num_det)
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE t1

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE bodega_p		LIKE rept002.r02_codigo
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE grupo_linea, bodega_p TO NULL
LET int_flag = 0
INPUT BY NAME rm_r89.r89_usuario, vm_fecha_ini, vm_fecha_fin, vm_bodega,
	--#vm_ordenar,
	vm_item
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r89_usuario) THEN
			IF rm_g05.g05_tipo = 'UF' OR
			   (rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G')
			THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_usuarios("A")
				RETURNING r_g05.g05_usuario, r_g05.g05_nombres
			IF r_g05.g05_usuario IS NOT NULL THEN
				LET rm_r89.r89_usuario = r_g05.g05_usuario
				DISPLAY BY NAME rm_r89.r89_usuario
			END IF
		END IF
		IF INFIELD(vm_bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T', 'T', 'A', 'T', '2')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET vm_bodega = r_r02.r02_codigo
				DISPLAY BY NAME vm_bodega, r_r02.r02_nombre
			END IF
		END IF
		IF INFIELD(r10_codigo) THEN
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
							grupo_linea, bodega_p)
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  bodega, stock
			IF r_r10.r10_codigo IS NOT NULL THEN
				LET vm_item      = r_r10.r10_codigo
				LET vm_desc_item = r_r10.r10_nombre
				DISPLAY BY NAME vm_item, vm_desc_item
			END IF 
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD r89_usuario
		IF rm_g05.g05_tipo = 'UF' OR
		   (rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G') THEN
			LET rm_r89.r89_usuario = vg_usuario
			DISPLAY BY NAME rm_r89.r89_usuario
			CONTINUE INPUT
		END IF
		IF rm_r89.r89_usuario IS NOT NULL THEN
			CALL fl_lee_usuario(rm_r89.r89_usuario)
				RETURNING r_g05.*
			IF r_g05.g05_usuario IS NULL THEN
				CALL fl_mostrar_mensaje('Este usuario no existe.','exclamation')
				NEXT FIELD r89_usuario
			END IF
			IF r_g05.g05_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r89_usuario
			END IF
			CALL obtener_fecha_ini()
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NULL THEN
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
		IF vm_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la de hoy.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NULL THEN
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
		IF vm_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la de hoy.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
	AFTER FIELD vm_bodega
		IF vm_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esa Bodega.','exclamation')
				NEXT FIELD vm_bodega
			END IF
			DISPLAY BY NAME r_r02.r02_nombre
       	                IF r_r02.r02_estado = 'B' THEN
               	                CALL fl_mensaje_estado_bloqueado()
                       	        NEXT FIELD vm_bodega
                        END IF
		ELSE
			CLEAR r02_nombre
		END IF
	AFTER FIELD vm_item
		IF vm_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, vm_item) RETURNING r_r10.*
			IF r_r10.r10_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('El item no existe.','exclamation')
				NEXT FIELD vm_item
			END IF
			LET vm_desc_item = r_r10.r10_nombre
			DISPLAY BY NAME vm_desc_item
		ELSE
			LET vm_desc_item = NULL
			DISPLAY BY NAME vm_desc_item
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor a la Fecha Final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR r89_usuario, vm_fecha_ini, vm_fecha_fin, vm_bodega, r02_nombre, vm_item,
	vm_desc_item
INITIALIZE rm_r89.*, vm_bodega, vm_item, vm_desc_item, vm_fecha_ini,
	vm_fecha_fin, vm_ordenar TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CLEAR num_row, max_row, descrip_2, descrip_3, descrip_4, nom_item, nom_marca,
	total_bueno, total_incompleto, total_mal_est, total_suma,
	total_stock_act, tit_diferencia
--#LET vm_size_arr = fgl_scr_size('rm_inventario')
IF vg_gui = 0 THEN
	LET vm_size_arr = 7
END IF
FOR i = 1 TO vm_size_arr
        INITIALIZE rm_inventario[i].*, rm_periodo[i].* TO NULL
        CLEAR rm_inventario[i].*
END FOR

END FUNCTION



FUNCTION mostrar_botones_det()

--#DISPLAY 'BD'			TO tit_col1
--#DISPLAY 'Item'		TO tit_col2
--#DISPLAY 'Descripción'	TO tit_col3
--#DISPLAY 'Bueno'		TO tit_col4
--#DISPLAY 'Incomp.'		TO tit_col5
--#DISPLAY 'Mal Estado'		TO tit_col6
--#DISPLAY 'Total'		TO tit_col7
--#DISPLAY 'Stock Act.'		TO tit_col8

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row		SMALLINT
                                                                                
DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION muestra_etiquetas(item, i, numlin)
DEFINE item		LIKE rept010.r10_codigo
DEFINE i, numlin	SMALLINT
DEFINE r_item		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, numlin)
CALL fl_lee_item(vg_codcia, item) RETURNING r_item.*
CALL muestra_descripciones(item, r_item.r10_linea, r_item.r10_sub_linea,
				r_item.r10_cod_grupo, r_item.r10_cod_clase)
DISPLAY r_item.r10_nombre TO nom_item 
CALL calcular_diferencia(i)

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo) RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r70.r70_desc_sub   TO descrip_2
DISPLAY r_r71.r71_desc_grupo TO descrip_3
DISPLAY r_r72.r72_desc_clase TO descrip_4
DISPLAY r_r10.r10_marca      TO nom_marca

END FUNCTION



FUNCTION control_modificar(i, j)
DEFINE i, j		SMALLINT
DEFINE r_r89		RECORD LIKE rept089.*
DEFINE r_inv_aux	RECORD
				r89_bodega	LIKE rept089.r89_bodega,
				r89_item	LIKE rept089.r89_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r89_bueno	LIKE rept089.r89_bueno,
				r89_incompleto	LIKE rept089.r89_incompleto,
				r89_mal_est	LIKE rept089.r89_mal_est,
				r89_suma	LIKE rept089.r89_suma,
				r89_stock_act	LIKE rept089.r89_stock_act
			END RECORD

BEGIN WORK
	WHENEVER ERROR STOP
	DECLARE q_modinv CURSOR FOR
		SELECT * FROM rept089
			WHERE r89_compania  = vg_codcia
			  AND r89_localidad = vg_codloc
			  AND r89_bodega    = rm_inventario[i].r89_bodega
			  AND r89_item      = rm_inventario[i].r89_item
			  AND r89_usuario   = rm_r89.r89_usuario
			  AND r89_anio      = rm_periodo[i].r89_anio
			  AND r89_mes       = rm_periodo[i].r89_mes
		FOR UPDATE
	WHENEVER ERROR CONTINUE
	OPEN q_modinv
	FETCH q_modinv INTO r_r89.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este Item, lo tiene bloqueado otro usuario.','exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	OPTIONS INPUT WRAP
	IF vg_gui = 0 THEN
		CALL muestra_etiquetas(rm_inventario[i].r89_item, i, vm_num_det)
	END IF
	LET int_flag = 0
	INPUT rm_inventario[i].* WITHOUT DEFAULTS FROM rm_inventario[j].*
		ON KEY(INTERRUPT)
			LET rm_inventario[i].* = r_inv_aux.*
			DISPLAY rm_inventario[i].* TO rm_inventario[j].*
			CALL calcular_valores(i, j)
			CALL obtener_totales()
			LET int_flag = 1
			--#ROLLBACK WORK
			--#RETURN
			EXIT INPUT
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			LET r_inv_aux.* = rm_inventario[i].*
	AFTER FIELD r89_bueno, r89_incompleto, r89_mal_est
		CALL calcular_valores(i, j)
		CALL obtener_totales()
	AFTER INPUT
		CALL calcular_valores(i, j)
		CALL obtener_totales()
	END INPUT
	IF int_flag THEN
		ROLLBACK WORK
		RETURN
	END IF
	UPDATE rept089 SET r89_stock_act  = rm_inventario[i].r89_stock_act,
			   r89_bueno      = rm_inventario[i].r89_bueno,
			   r89_incompleto = rm_inventario[i].r89_incompleto,
			   r89_mal_est    = rm_inventario[i].r89_mal_est,
			   r89_suma       = rm_inventario[i].r89_suma,
			   r89_usu_modifi = vg_usuario,
			   r89_fec_modifi = CURRENT
		WHERE CURRENT OF q_modinv
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION


 
FUNCTION obtener_totales()
DEFINE total_bueno	SMALLINT
DEFINE total_incompleto	SMALLINT
DEFINE total_mal_est	SMALLINT
DEFINE total_suma	SMALLINT
DEFINE total_stock_act	SMALLINT
DEFINE i		SMALLINT

LET total_bueno      = 0
LET total_incompleto = 0
LET total_mal_est    = 0
LET total_suma       = 0
LET total_stock_act  = 0
FOR i = 1 TO vm_num_det
	LET total_bueno      = total_bueno      + rm_inventario[i].r89_bueno
	LET total_incompleto = total_incompleto +rm_inventario[i].r89_incompleto
	LET total_mal_est    = total_mal_est    + rm_inventario[i].r89_mal_est
	LET total_suma       = total_suma       + rm_inventario[i].r89_suma
	LET total_stock_act  = total_stock_act  + rm_inventario[i].r89_stock_act
END FOR
DISPLAY BY NAME total_bueno, total_incompleto, total_mal_est, total_suma,
		total_stock_act

END FUNCTION



FUNCTION calcular_valores(i, j)
DEFINE i, j		SMALLINT

LET rm_inventario[i].r89_suma = rm_inventario[i].r89_bueno +
				rm_inventario[i].r89_incompleto +
				rm_inventario[i].r89_mal_est
DISPLAY rm_inventario[i].r89_suma TO rm_inventario[j].r89_suma
CALL calcular_diferencia(i)

END FUNCTION



FUNCTION cursor_dif(i)
DEFINE i		SMALLINT
DEFINE query		CHAR(800)

LET query = 'SELECT * FROM rept089 ',
		' WHERE r89_compania  =  ', vg_codcia,
		'   AND r89_localidad =  ', vg_codloc,
		'   AND r89_bodega    = "', rm_inventario[i].r89_bodega, '"',
		'   AND r89_item      = "',
					rm_inventario[i].r89_item CLIPPED, '"',
		'   AND r89_usuario  <> "', rm_r89.r89_usuario CLIPPED, '"',
		'   AND r89_anio      = ', rm_periodo[i].r89_anio,
		'   AND r89_mes       = ', rm_periodo[i].r89_mes
PREPARE cons_dif FROM query
DECLARE q_dif CURSOR FOR cons_dif

END FUNCTION



FUNCTION calcular_diferencia(i)
DEFINE i		SMALLINT
DEFINE r_r89		RECORD LIKE rept089.*
DEFINE tit_diferencia	DECIMAL(8,2)
DEFINE total		DECIMAL(8,2)

LET total = 0
CALL cursor_dif(i)
FOREACH q_dif INTO r_r89.*
	LET total = total + r_r89.r89_suma
END FOREACH
LET tit_diferencia = rm_inventario[i].r89_suma + total -
			rm_inventario[i].r89_stock_act
DISPLAY BY NAME tit_diferencia

END FUNCTION


 
FUNCTION obtener_fecha_ini()

SELECT NVL(MIN(r89_fecing), TODAY) INTO vm_fecha_ini
	FROM rept089
	WHERE r89_compania      = vg_codcia
	  AND r89_localidad     = vg_codloc
	  AND r89_usuario       = rm_r89.r89_usuario
	  AND YEAR(r89_fecing) >= 2006

END FUNCTION


 
FUNCTION ver_otros_datos(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp239 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' "',
	rm_inventario[i].r89_bodega, '" "', rm_inventario[i].r89_item, '" "',
	rm_r89.r89_usuario, '" ', rm_periodo[i].r89_anio, ' ',
	rm_periodo[i].r89_mes
RUN comando

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT listado_inventario_fisico TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT listado_inventario_fisico(i)
END FOR
FINISH REPORT listado_inventario_fisico

END FUNCTION



REPORT listado_inventario_fisico(i)
DEFINE i		SMALLINT
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE factura		VARCHAR(15)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 029, "LISTADO INVENTARIO FISICO",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 022, "** USUARIO       : ", rm_r89.r89_usuario CLIPPED
	--#IF vm_bodega IS NOT NULL THEN
		--#CALL fl_lee_bodega_rep(vg_codcia, vm_bodega)
			--#RETURNING r_r02.*
		--#PRINT COLUMN 022, "** BODEGA        : ",
			--#vm_bodega CLIPPED, " ", r_r02.r02_nombre CLIPPED
	--#ELSE
		--#PRINT " "
	--#END IF
	--#IF vm_item IS NOT NULL THEN
		--#PRINT COLUMN 022, "** ITEM          : ",
			--#vm_item CLIPPED, " ", vm_desc_item CLIPPED
	--#ELSE
		--#PRINT " "
	--#END IF
	PRINT COLUMN 022, "** FECHA INICIAL : ", vm_fecha_ini
							USING "dd-mm-yyyy"
	PRINT COLUMN 022, "** FECHA FINAL   : ", vm_fecha_fin
							USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "DB",
	      COLUMN 004, "ITEM",
	      COLUMN 012, "DESCRIPCION",
	      COLUMN 032, "    BUENO",
	      COLUMN 042, "INCOMPLET",
	      COLUMN 052, "MAL ESTAD",
	      COLUMN 062, "    TOTAL",
	      COLUMN 072, "STOCK ACT"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_inventario[i].r89_bodega,
	      COLUMN 004, rm_inventario[i].r89_item[1, 7]	CLIPPED,
	      COLUMN 012, rm_inventario[i].r10_nombre[1, 19]	CLIPPED,
	      COLUMN 032, rm_inventario[i].r89_bueno	  USING "--,--&.##",
	      COLUMN 042, rm_inventario[i].r89_incompleto USING "--,--&.##",
	      COLUMN 052, rm_inventario[i].r89_mal_est	  USING "--,--&.##",
	      COLUMN 062, rm_inventario[i].r89_suma	  USING "--,--&.##",
	      COLUMN 072, rm_inventario[i].r89_stock_act  USING "--,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 032, "---------",
	      COLUMN 042, "---------",
	      COLUMN 052, "---------",
	      COLUMN 062, "---------",
	      COLUMN 072, "---------"
	PRINT COLUMN 021, "TOTAL ==>  ",
	      COLUMN 032, SUM(rm_inventario[i].r89_bueno)     USING "--,--&.##",
	      COLUMN 042, SUM(rm_inventario[i].r89_incompleto)
							USING "--,--&.##",
	      COLUMN 052, SUM(rm_inventario[i].r89_mal_est)   USING "--,--&.##",
	      COLUMN 062, SUM(rm_inventario[i].r89_suma)      USING "--,--&.##",
	      COLUMN 072, SUM(rm_inventario[i].r89_stock_act) USING "--,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Modificar'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Detalle'                  AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Imprimir Listado'         AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

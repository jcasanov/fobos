--------------------------------------------------------------------------------
-- Titulo           : repp325.4gl - Consulta Inventario Físico por Bodega
-- Elaboracion      : 21-Dic-2010
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp325 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE rm_r89		RECORD LIKE rept089.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE vm_bodega	LIKE rept089.r89_bodega
DEFINE vm_diferencia	CHAR(1)
DEFINE vm_item		LIKE rept089.r89_item
DEFINE vm_desc_item	LIKE rept010.r10_nombre
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_inventario	ARRAY [20000] OF RECORD
				r89_bodega	LIKE rept089.r89_bodega,
				r89_item	LIKE rept089.r89_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r89_bueno	LIKE rept089.r89_bueno,
				r89_incompleto	LIKE rept089.r89_incompleto,
				r89_suma	LIKE rept089.r89_suma,
				diferencia	DECIMAL(8,2),
				mens_dif	VARCHAR(10)
			END RECORD
DEFINE rm_periodo	ARRAY [20000] OF RECORD
				r89_anio	LIKE rept089.r89_anio,
				r89_mes		LIKE rept089.r89_mes,
				stock_act	LIKE rept011.r11_stock_act,
				cant_pend	LIKE rept011.r11_stock_act,
				r89_usuario	LIKE rept089.r89_usuario,
				r89_usu_modifi	LIKE rept089.r89_usu_modifi
			END RECORD
DEFINE r_loc 	   	ARRAY[50] OF RECORD
				bod_loc		LIKE rept002.r02_codigo,
				nom_bod_loc	LIKE rept002.r02_nombre,
				stock_loc	LIKE rept011.r11_stock_act
			END RECORD
DEFINE r_rem		ARRAY[50] OF RECORD
				bod_rem		LIKE rept002.r02_codigo,
				nom_bod_rem	LIKE rept002.r02_nombre,
				stock_rem	LIKE rept011.r11_stock_act
			END RECORD
DEFINE i_loc, i_rem	SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE total_bueno	SMALLINT
DEFINE total_incompleto	SMALLINT
DEFINE total_suma	SMALLINT
DEFINE total_dif	DECIMAL(12,2)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp325.err')
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
LET vg_proceso = 'repp325'
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
OPEN WINDOW w_repp325 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf325 FROM "../forms/repf325_1"
ELSE
	OPEN FORM f_repf325 FROM "../forms/repf325_1c"
END IF
DISPLAY FORM f_repf325
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
DEFINE codloc		LIKE rept002.r02_localidad
DEFINE aux_usu		LIKE rept089.r89_usuario

CALL borrar_cabecera()
CALL mostrar_botones_det()
LET rm_r89.r89_usuario = vg_usuario
CALL obtener_fecha_ini()
LET vm_fecha_fin       = TODAY
LET codloc = vg_codloc
IF vg_codloc = 3 THEN
	LET codloc = 5
END IF
SELECT r02_codigo bod_loc
	FROM rept002
	WHERE r02_compania   = vg_codcia
	  AND r02_localidad IN (vg_codloc, codloc)
	  AND r02_tipo       = 'F'
	INTO TEMP tmp_bod
LET vm_diferencia = 'T'
WHILE TRUE
	CALL borrar_detalle()
	LET aux_usu = rm_r89.r89_usuario
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_proceso()
	LET rm_r89.r89_usuario = aux_usu
END WHILE
DROP TABLE tmp_bod
LET int_flag = 0
CLOSE WINDOW w_repp325
EXIT PROGRAM

END FUNCTION



FUNCTION control_proceso()
DEFINE desc_mar		LIKE rept073.r73_desc_marca
DEFINE desc_cla		LIKE rept072.r72_desc_clase

IF NOT generar_tabla_trabajo() THEN
	RETURN
END IF
DECLARE q_deto CURSOR FOR
	SELECT bodega, item, descrip, vendible, no_vend, --total, mens_dife,
		sto_act - cant_pend, cant_pend,
		mens_dife, anio, mes, sto_act, cant_pend, usuario, usu_mod,
		marca, clase
		FROM tmp_inv
		ORDER BY bodega, marca, clase, descrip, item
LET vm_num_det = 1
FOREACH q_deto INTO rm_inventario[vm_num_det].*, rm_periodo[vm_num_det].*,
			desc_mar, desc_cla
	--IF rm_inventario[vm_num_det].r89_suma = 0 THEN
	IF rm_inventario[vm_num_det].r89_bueno = 0 AND
	   rm_inventario[vm_num_det].r89_incompleto = 0
	THEN
		LET rm_inventario[vm_num_det].r89_bueno      = NULL
		LET rm_inventario[vm_num_det].r89_incompleto = NULL
		--LET rm_inventario[vm_num_det].r89_suma       = NULL
	END IF
	IF rm_inventario[vm_num_det].diferencia = 0 THEN
		LET rm_inventario[vm_num_det].diferencia     = NULL
	END IF
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
CALL control_consulta_detalle()

END FUNCTION



FUNCTION control_consulta_detalle()
DEFINE query		CHAR(1000)
DEFINE i, j, col	SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 1
LET vm_columna_1           = col
LET vm_columna_2           = 12
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT bodega, item, descrip, vendible, no_vend, ',
				--'total, mens_dife, ',
				'sto_act - cant_pend, cant_pend, ',
				'mens_dife, anio, mes, sto_act, cant_pend, ',
				'usuario, usu_mod, marca, clase ',
			' FROM tmp_inv ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE deto FROM query
	DECLARE q_deto2 CURSOR FOR deto
	LET i = 1
	FOREACH q_deto2 INTO rm_inventario[i].*, rm_periodo[i].*
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
		CALL muestra_etiquetas(rm_inventario[1].r89_item, 1, 1,
					vm_num_det)
	END IF
	CALL muestra_tot_reg()
	CALL set_count(vm_num_det)
	LET int_flag = 0
	DISPLAY ARRAY rm_inventario TO rm_inventario.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_otros_datos(i)
			LET int_flag = 0
		ON KEY(F6)
			CALL control_imprimir()
			LET int_flag = 0
		ON KEY(F7)
			CALL control_archivo()
			LET int_flag = 0
		ON KEY(F8)
			IF (rm_g05.g05_tipo <> 'UF' OR rm_vend.r01_tipo = 'J' OR
			    rm_vend.r01_tipo = 'G')
			THEN
				LET i = arr_curr()
				CALL control_stock_items(rm_inventario[i].r89_item, i)
				LET int_flag = 0
			END IF
		ON KEY(F9)
			IF (rm_g05.g05_tipo <> 'UF' OR rm_vend.r01_tipo = 'J' OR
			    rm_vend.r01_tipo = 'G')
			THEN
				LET i = arr_curr()
				CALL control_items_pendientes(rm_inventario[i].r89_item)
				LET int_flag = 0
			END IF
		ON KEY(CONTROL-W)
			CALL control_estadisticas()
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
		ON KEY(F22)
			LET col = 8
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')   
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF (rm_g05.g05_tipo <> 'UF' OR rm_vend.r01_tipo = 'J'
			--# OR
		    	--#rm_vend.r01_tipo = 'G')
			--#THEN
				--#CALL dialog.keysetlabel('F8', 'Stock')
				--#CALL dialog.keysetlabel('F9', 'Items Pend.')
			--#ELSE
				--#CALL dialog.keysetlabel('F8', '')
				--#CALL dialog.keysetlabel('F9', '')
			--#END IF
			--#CALL dialog.keysetlabel('CONTROL-W','Estadísticas')
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_etiquetas(rm_inventario[i].r89_item, i,
						--#j, vm_num_det)
			--#CALL obtener_totales(i, j)
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
DROP TABLE tmp_inv

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
	vm_item, vm_diferencia
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
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
			SELECT * FROM tmp_bod
				WHERE bod_loc = r_r02.r02_codigo
			IF STATUS = NOTFOUND THEN
				CALL fl_mostrar_mensaje('Digite una bodega de esta localidad.', 'exclamation')
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



FUNCTION generar_tabla_trabajo()
DEFINE query		CHAR(3000)
DEFINE subquery		CHAR(250)
DEFINE expr_bod2        VARCHAR(100)
DEFINE expr_ite2        VARCHAR(100)
DEFINE expr_usu		VARCHAR(200)
DEFINE expr_dif		VARCHAR(100)
DEFINE cuantos		INTEGER
DEFINE resul, resul2	SMALLINT

LET expr_bod2 = NULL
IF vm_bodega IS NOT NULL THEN
	LET expr_bod2 = '   AND r89_bodega    = "', vm_bodega, '"'
END IF
LET expr_ite2 = NULL
IF vm_item IS NOT NULL THEN
	LET expr_ite2 = '   AND r89_item      = "', vm_item CLIPPED, '"'
END IF
LET expr_usu = NULL
IF rm_r89.r89_usuario IS NOT NULL THEN
	LET expr_usu = '   AND (r89_usuario    = "', rm_r89.r89_usuario CLIPPED,
			'"  OR  r89_usu_modifi = "', rm_r89.r89_usuario CLIPPED,
			'")'
END IF
LET query = 'SELECT r89_bodega bodega, r89_item item, r10_nombre descrip, ',
			'NVL(SUM(r89_bueno), 0) vendible, ',
			'NVL(SUM(r89_incompleto), 0) no_vend, ',
			'NVL(SUM(r89_suma), 0) total, ',
			'"" mens_dife, ',
			'r89_anio anio, r89_mes mes, r10_marca marca, ',
			'r72_desc_clase clase, r89_stock_act sto_act, ',
			'r89_usuario usuario, r89_usu_modifi usu_mod ',
		' FROM rept089, rept010, rept072 ',
		' WHERE r89_compania   =  ', vg_codcia,
		'   AND r89_localidad  =  ', vg_codloc,
		expr_bod2 CLIPPED, 
		expr_ite2 CLIPPED, 
		expr_usu CLIPPED, 
		'   AND r89_fecha      BETWEEN "', vm_fecha_ini,
					'" AND "', vm_fecha_fin, '"',
		'   AND r10_compania   = r89_compania ',
		'   AND r10_codigo     = r89_item ',
		'   AND r72_compania   = r10_compania ',
		'   AND r72_linea      = r10_linea ',
		'   AND r72_sub_linea  = r10_sub_linea ',
		'   AND r72_cod_grupo  = r10_cod_grupo ',
		'   AND r72_cod_clase  = r10_cod_clase ',
		' GROUP BY 1, 2, 3, 7, 8, 9, 10, 11, 12, 13, 14 ',
		' INTO TEMP t1 '
PREPARE exec_r89 FROM query
EXECUTE exec_r89
SELECT COUNT(*) INTO cuantos FROM t1
LET resul = 1
IF cuantos = 0 THEN
	LET resul = 0
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE t1
	RETURN resul
END IF
SELECT bodega, item, descrip, NVL(SUM(vendible), 0) vendible,
	NVL(SUM(no_vend), 0) no_vend, NVL(SUM(total), 0) total, mens_dife,
	anio, mes, marca, clase, NVL(SUM(sto_act), 0) sto_act, usuario, usu_mod
	FROM t1
	GROUP BY 1, 2, 3, 7, 8, 9, 10, 11, 13, 14
	INTO TEMP tmp_ite
DROP TABLE t1
--CALL tiene_stock_pendiente() RETURNING resul2
	LET resul2 = 0
IF resul2 THEN
	--IF vm_tipo = 'T' THEN
		SELECT bodega, item, descrip, vendible, no_vend, total,
			mens_dife, anio, mes, marca, clase, sto_act,
			0.00 cant_pend
			FROM tmp_ite
		UNION
		SELECT r20_bodega bodega, r20_item item, r10_nombre descrip,
			0.00 vendible, 0.00 no_vend, 0.00 total, "" mens_dife,
			NVL((SELECT anio
				FROM tmp_ite
				WHERE bodega = r20_bodega
				  AND item   = r20_item), YEAR(TODAY)) anio,
			NVL((SELECT mes
				FROM tmp_ite
				WHERE bodega = r20_bodega
				  AND item   = r20_item), MONTH(TODAY)) mes,
			r10_marca marca, r72_desc_clase clase,
			0.00 sto_act, cant_pend
			FROM temp_pend, rept010, rept072
			WHERE r10_compania   = vg_codcia
			  AND r10_codigo     = r20_item
			  AND r72_compania   = r10_compania
			  AND r72_linea      = r10_linea
			  AND r72_sub_linea  = r10_sub_linea
			  AND r72_cod_grupo  = r10_cod_grupo
			  AND r72_cod_clase  = r10_cod_clase
		INTO TEMP t2
	{--
	ELSE
		SELECT r20_bodega bodega, r20_item item, r10_nombre descrip,
			0.00 vendible, 0.00 no_vend, 0.00 total, "" mens_dife,
			NVL((SELECT anio
				FROM tmp_ite
				WHERE bodega = r20_bodega
				  AND item   = r20_item), YEAR(TODAY)) anio,
			NVL((SELECT mes
				FROM tmp_ite
				WHERE bodega = r20_bodega
				  AND item   = r20_item), MONTH(TODAY)) mes,
			r10_marca marca, r72_desc_clase clase,
			0.00 sto_act, cant_pend
			FROM temp_pend, rept010, rept072
			WHERE r10_compania   = vg_codcia
			  AND r10_codigo     = r20_item
			  AND r72_compania   = r10_compania
			  AND r72_linea      = r10_linea
			  AND r72_sub_linea  = r10_sub_linea
			  AND r72_cod_grupo  = r10_cod_grupo
			  AND r72_cod_clase  = r10_cod_clase
			INTO TEMP t2
	END IF
	--}
	SELECT bodega, item, descrip, NVL(SUM(vendible), 0) vendible,
		NVL(SUM(no_vend), 0) no_vend, NVL(SUM(total), 0) total,
		mens_dife, anio, mes, marca, clase,
		NVL(SUM(sto_act + cant_pend), 0) sto_act,
		(SELECT b.usuario
			FROM tmp_ite b
			WHERE b.bodega = t2.bodega
			  AND b.item   = t2.item
			  AND b.anio   = t2.anio
			  AND b.mes    = t2.mes) usuario,
		(SELECT b.usu_mod
			FROM tmp_ite b
			WHERE b.bodega = t2.bodega
			  AND b.item   = t2.item
			  AND b.anio   = t2.anio
			  AND b.mes    = t2.mes) usu_mod
			FROM t2
			GROUP BY 1, 2, 3, 7, 8, 9, 10, 11, 13, 14
		INTO TEMP t3
	DROP TABLE t2
ELSE
	IF resul2 THEN
		SELECT * FROM tmp_ite
			WHERE NOT EXISTS
				(SELECT 1 FROM temp_pend
					WHERE r20_bodega = bodega
					  AND r20_item   = item)
			INTO TEMP t3
	ELSE
		SELECT * FROM tmp_ite INTO TEMP t3
	END IF
END IF
DROP TABLE tmp_ite
SELECT bodega, item, descrip, NVL(SUM(vendible), 0) vendible,
	NVL(SUM(no_vend), 0) no_vend, NVL(SUM(total), 0) total, mens_dife,
	anio, mes, marca, clase, NVL(SUM(sto_act), 0) sto_act, usuario, usu_mod
	FROM t3
	GROUP BY 1, 2, 3, 7, 8, 9, 10, 11, 13, 14
	INTO TEMP t4
DROP TABLE t3
LET subquery = ' 0 '
IF resul2 THEN
	LET subquery = 'NVL((SELECT cant_pend ',
			'FROM temp_pend ',
			'WHERE r20_bodega = bodega ',
			'  AND r20_item   = item), 0) '
END IF
LET query = 'SELECT bodega, item, descrip, vendible, no_vend, total, ',
			'(sto_act - total) diferencia, ',
			'CASE WHEN sto_act < total THEN "SOBRANTE" ',
			'     WHEN sto_act > total THEN "FALTANTE" ',
				'ELSE "" ',
			'END mens_dife, ',
			'anio, mes, marca, clase, ',
			subquery CLIPPED, ' cant_pend, ',
			'sto_act, usuario, usu_mod ',
		' FROM t4 ',
		' INTO TEMP t5 '
PREPARE exec_t5 FROM query
EXECUTE exec_t5
DROP TABLE t4
{--
IF NOT resul2 THEN
	SELECT * FROM t5 INTO TEMP tmp_inv
	DROP TABLE t5
	RETURN resul
END IF
--}
LET expr_dif = NULL
IF vm_diferencia = 'D' THEN
	LET expr_dif = ' WHERE mens_dife <> "" '
END IF
IF vm_diferencia = 'S' THEN
	LET expr_dif = ' WHERE mens_dife = "" '
END IF
{--
LET query = 'SELECT *, NVL((SELECT cant_pend ',
			'FROM temp_pend ',
			'WHERE r20_bodega = bodega ',
			'  AND r20_item   = item), 0) cant_pend2 ',
--}
LET query = 'SELECT * FROM t5 ',
		expr_dif CLIPPED,
		' INTO TEMP tmp_inv '
PREPARE exec_inv FROM query
EXECUTE exec_inv
DROP TABLE t5
--DROP TABLE temp_pend
RETURN resul

END FUNCTION



FUNCTION tiene_stock_pendiente()
DEFINE cuantos		INTEGER
DEFINE query		CHAR(1000)
DEFINE expr_ite         VARCHAR(100)

LET expr_ite = NULL
IF vm_item IS NOT NULL THEN
	LET expr_ite = '   AND r35_item      = "', vm_item CLIPPED, '"'
END IF
LET query = 'SELECT UNIQUE r35_item item ',
		' FROM rept034, rept035 ',
		' WHERE r34_compania     = ', vg_codcia,
	  	'   AND r34_localidad    = ', vg_codloc,
	  	'   AND r34_bodega      IN (SELECT bodega FROM tmp_ite) ',
	  	'   AND r34_estado      IN ("A", "P") ',
	  	'   AND r35_compania     = r34_compania ',
	  	'   AND r35_localidad    = r34_localidad ',
		'   AND r35_bodega       = r34_bodega ',
		'   AND r35_num_ord_des  = r34_num_ord_des ',
		expr_ite CLIPPED,
		' INTO TEMP tmp_ite_p '
PREPARE exec_ite_p FROM query
EXECUTE exec_ite_p
SELECT r20_cod_tran, r20_num_tran, DATE(r20_fecing) fecha, r20_bodega, r20_item,
		r20_cant_ven
	FROM rept020
	WHERE r20_compania   = vg_codcia
	  AND r20_localidad  = vg_codloc
	  AND r20_cod_tran  IN ("FA", "DF")
	  AND r20_bodega    IN (SELECT bodega FROM tmp_ite)
	  AND r20_item      IN (SELECT item FROM tmp_ite_p)
	INTO TEMP t_r20
DROP TABLE tmp_ite_p
SELECT r19_cod_tran, r19_num_tran, r19_nomcli, r19_tipo_dev, r19_num_dev
	FROM rept019
	WHERE r19_compania   = vg_codcia
	  AND r19_localidad  = vg_codloc
	  AND r19_cod_tran   = "FA"
	  AND (r19_tipo_dev  = "DF" OR r19_tipo_dev IS NULL)
UNION ALL
SELECT r19_cod_tran, r19_num_tran, r19_nomcli, r19_tipo_dev, r19_num_dev
	FROM rept019
	WHERE r19_compania   = vg_codcia
	  AND r19_localidad  = vg_codloc
	  AND r19_cod_tran   = "DF"
	INTO TEMP t_r19
SELECT c.*, d.r19_nomcli
	FROM t_r20 c, t_r19 d
	WHERE c.r20_cod_tran = "FA"
	  AND d.r19_cod_tran = c.r20_cod_tran
	  AND d.r19_num_tran = c.r20_num_tran
	INTO TEMP t_f
SELECT a.r19_tipo_dev c_t, a.r19_num_dev n_t, b.r20_bodega bd, b.r20_item ite,
	b.r20_cant_ven cant
	FROM t_r19 a, t_r20 b
	WHERE a.r19_cod_tran = b.r20_cod_tran
	  AND a.r19_num_tran = b.r20_num_tran
	  AND b.r20_cod_tran = "DF"
	INTO TEMP t_d
SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item, r20_cant_ven -
	NVL((SELECT SUM(cant)
		FROM t_d
		WHERE c_t = r20_cod_tran
		  AND n_t = r20_num_tran
		  AND bd  = r20_bodega
		  AND ite = r20_item), 0) r20_cant_ven, r19_nomcli
	FROM t_f
	INTO TEMP t_t
DROP TABLE t_f
DROP TABLE t_d
SELECT * FROM t_t WHERE r20_cant_ven > 0 INTO TEMP t1
DROP TABLE t_t
DROP TABLE t_r19
DROP TABLE t_r20
SELECT r34_compania, r34_localidad, r34_bodega, r34_num_ord_des, r34_cod_tran,
		r34_num_tran
	FROM rept034
	WHERE r34_compania   = vg_codcia
	  AND r34_localidad  = vg_codloc
	  AND r34_estado    IN ("A", "P")
	INTO TEMP t_r34
SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item, r20_cant_ven,
		r34_num_ord_des, r19_nomcli
	FROM t1, t_r34
	WHERE r34_compania  = vg_codcia
	  AND r34_localidad = vg_codloc
	  AND r34_bodega    = r20_bodega
	  AND r34_cod_tran  = r20_cod_tran
	  AND r34_num_tran  = r20_num_tran
	INTO TEMP t2
DROP TABLE t1
DROP TABLE t_r34
SELECT COUNT(*) INTO cuantos FROM t2
IF cuantos = 0 THEN
	DROP TABLE t2
	RETURN 0
END IF
SELECT UNIQUE r35_num_ord_des, r20_bodega bodega, r20_item item,
	SUM(r35_cant_des - r35_cant_ent) cantidad
	FROM rept035, t2
	WHERE r35_compania    = vg_codcia
	  AND r35_localidad   = vg_codloc
	  AND r35_bodega      = r20_bodega
	  AND r35_num_ord_des = r34_num_ord_des
	  AND r35_item        = r20_item
	GROUP BY 1, 2, 3
	HAVING SUM(r35_cant_des - r35_cant_ent) > 0
	INTO TEMP t3
LET query = 'SELECT r20_bodega, r20_item, NVL(SUM(cantidad), 0) cant_pend, ',
			'"', vg_usuario, '" usuario ',
		'FROM t2, t3 ',
		'WHERE r20_bodega      = bodega ',
		'  AND r20_item        = item ', 
		'  AND r35_num_ord_des = r34_num_ord_des ',
		'GROUP BY 1, 2, 4 ',
		'INTO TEMP temp_pend '
PREPARE exec_pend FROM query
EXECUTE exec_pend
DROP TABLE t2
DROP TABLE t3
{
SELECT COUNT(*) INTO cuantos FROM temp_pend
IF cuantos = 0 THEN
	RETURN 0
END IF
}
RETURN 1

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR r89_usuario, vm_fecha_ini, vm_fecha_fin, vm_bodega, r02_nombre, vm_item,
	vm_desc_item, r89_usu_modifi, tot_item_dig
INITIALIZE rm_r89.*, vm_bodega, vm_item, vm_desc_item, vm_fecha_ini,
	vm_fecha_fin TO NULL

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CLEAR num_row, max_row, descrip_2, descrip_3, descrip_4, nom_item, nom_marca,
	total_bueno, total_incompleto, total_suma, r89_usu_modifi, tot_item_dig,
	total_dif
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
--#DISPLAY 'Vendible'		TO tit_col4
--#DISPLAY 'No Vend.'		TO tit_col5
--DISPLAY 'Total'		TO tit_col6
--DISPLAY 'Diferencia'		TO tit_col7
--#DISPLAY 'Stock'		TO tit_col6
--#DISPLAY 'Pend.'		TO tit_col7
--#DISPLAY 'Mens. Dif.'		TO tit_col8

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row		SMALLINT
                                                                                
DISPLAY BY NAME num_row, max_row

END FUNCTION


 
FUNCTION muestra_etiquetas(item, i, j, numlin)
DEFINE item		LIKE rept010.r10_codigo
DEFINE i, j, numlin	SMALLINT
DEFINE r_item		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, numlin)
CALL fl_lee_item(vg_codcia, item) RETURNING r_item.*
CALL muestra_descripciones(item, r_item.r10_linea, r_item.r10_sub_linea,
				r_item.r10_cod_grupo, r_item.r10_cod_clase)
DISPLAY r_item.r10_nombre TO nom_item 
CALL calcular_diferencia(i, j)
IF (rm_g05.g05_tipo <> 'UF' OR rm_vend.r01_tipo = 'J' OR rm_vend.r01_tipo = 'G')
THEN
	DISPLAY BY NAME rm_periodo[i].r89_usuario, rm_periodo[i].r89_usu_modifi
ELSE
	DISPLAY BY NAME rm_periodo[i].r89_usu_modifi
END IF

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



FUNCTION obtener_totales(i, j)
DEFINE i, j		SMALLINT
DEFINE l		SMALLINT

CALL calcular_valores(i, j)
LET total_bueno      = 0
LET total_incompleto = 0
LET total_suma       = 0
LET total_dif        = 0
FOR l = 1 TO vm_num_det
	IF rm_inventario[l].r89_bueno IS NOT NULL THEN
		LET total_bueno = total_bueno + rm_inventario[l].r89_bueno
	END IF
	IF rm_inventario[l].r89_incompleto IS NOT NULL THEN
		LET total_incompleto = total_incompleto +
					rm_inventario[l].r89_incompleto
	END IF
	IF rm_inventario[l].r89_suma IS NOT NULL THEN
		LET total_suma = total_suma + rm_inventario[l].r89_suma
	END IF
	IF rm_inventario[l].diferencia IS NOT NULL THEN
		LET total_dif = total_dif + rm_inventario[l].diferencia
	END IF
END FOR
DISPLAY BY NAME total_bueno, total_incompleto, total_suma, total_dif

END FUNCTION



FUNCTION calcular_valores(i, j)
DEFINE i, j		SMALLINT

--LET rm_inventario[i].r89_suma = rm_inventario[i].r89_bueno + rm_inventario[i].r89_incompleto
LET rm_inventario[i].r89_suma = rm_periodo[i].stock_act
				- rm_periodo[i].cant_pend
DISPLAY rm_inventario[i].r89_suma TO rm_inventario[j].r89_suma
CALL calcular_diferencia(i, j)

END FUNCTION



FUNCTION calcular_diferencia(i, j)
DEFINE i, j		SMALLINT
DEFINE tit_diferencia	DECIMAL(8,2)

--LET tit_diferencia = rm_inventario[i].r89_suma - rm_periodo[i].stock_act
LET tit_diferencia = (rm_inventario[i].r89_bueno
			+ rm_inventario[i].r89_incompleto)
			- rm_periodo[i].stock_act
IF tit_diferencia > 0 THEN
	LET rm_inventario[i].mens_dif = 'SOBRANTE'
END IF
IF tit_diferencia = 0 THEN
	LET rm_inventario[i].mens_dif = NULL
END IF
IF tit_diferencia < 0 THEN
	LET rm_inventario[i].mens_dif = 'FALTANTE'
END IF
LET rm_inventario[i].diferencia = rm_periodo[i].cant_pend
DISPLAY rm_inventario[i].diferencia TO rm_inventario[j].diferencia
DISPLAY rm_inventario[i].mens_dif   TO rm_inventario[j].mens_dif

END FUNCTION


 
FUNCTION obtener_fecha_ini()

SELECT NVL(DATE(MIN(r11_fec_corte)), TODAY)
	INTO vm_fecha_ini
	FROM resp_exis
	WHERE r11_compania = vg_codcia

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
	      COLUMN 016, "D E S C R I P C I O N",
	      COLUMN 043, " VENDIBLE",
	      COLUMN 053, "NO VENDI.",
	      COLUMN 063, "    TOTAL",
	      COLUMN 073, "DIFEREN."
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_inventario[i].r89_bodega,
	      COLUMN 004, rm_inventario[i].r89_item[1, 7]	CLIPPED,
	      COLUMN 012, rm_inventario[i].r10_nombre[1, 30]	CLIPPED,
	      COLUMN 043, rm_inventario[i].r89_bueno	  USING "--,--&.##",
	      COLUMN 053, rm_inventario[i].r89_incompleto USING "--,--&.##",
	      COLUMN 063, rm_inventario[i].r89_suma	  USING "--,--&.##",
	      COLUMN 073, rm_inventario[i].mens_dif		CLIPPED
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 045, "---------",
	      COLUMN 055, "---------",
	      COLUMN 065, "---------"
	PRINT COLUMN 032, "TOTAL ==>  ",
	      COLUMN 043, SUM(rm_inventario[i].r89_bueno)     USING "--,--&.##",
	      COLUMN 053, SUM(rm_inventario[i].r89_incompleto)
							USING "--,--&.##",
	      COLUMN 063, SUM(rm_inventario[i].r89_suma)      USING "--,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION control_archivo()
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)
DEFINE query		CHAR(2000)

LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar en archivo los datos grabados ?', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
LET query = 'SELECT (SELECT g02_abreviacion ',
			'FROM gent002 ',
			'WHERE g02_compania  = r02_compania ',
			'  AND g02_localidad = ', vg_codloc, ') loc, ',
			'bodega, r02_nombre, marca, clase, descrip, item, ',
			{-- OJO CAMBIADO EL 24/02/2011
			mens_dife, r89_bueno, r89_incompleto,
			sto_act - cant_pend, cant_pend, r10_precio_mb, usuario
			--}
			'mens_dife, r89_bueno, r89_incompleto, ',
			'sto_act - cant_pend sto_cong, r11_stock_act, ',
			'cant_pend, r10_precio_mb, usuario, ',
			'CASE WHEN r89_suma < r11_stock_act THEN "FALTANTE" ',
			'     WHEN r89_suma > r11_stock_act THEN "SOBRANTE" ',
			'     WHEN r89_suma = r11_stock_act THEN "" ',
			'END mens2 ',
		'FROM tmp_inv, rept002, rept089, rept010, resp_exis ',
		'WHERE r02_compania  = ', vg_codcia,
		'  AND r02_codigo    = bodega ',
		'  AND r89_compania  = r02_compania ',
		'  AND r89_localidad = ', vg_codloc,
		'  AND r89_bodega    = r02_codigo ',
		'  AND r89_item      = item ',
		'  AND r89_anio      = anio ',
		'  AND r89_mes       = mes ',
		'  AND r10_compania  = r02_compania ',
		'  AND r10_codigo    = item ',
		'  AND r11_compania  = r10_compania ',
		'  AND r11_bodega    = bodega ',
		'  AND r11_item      = r10_codigo ',
		'INTO TEMP tmp_nuevo '
PREPARE exec_nuevo FROM query
EXECUTE exec_nuevo
UNLOAD TO "../../../tmp/repp325.unl"
	SELECT * FROM tmp_nuevo
		ORDER BY bodega, marca, clase, descrip, item 
RUN "mv ../../../tmp/repp325.unl $HOME/tmp/"
LET mensaje = 'Archivo Generado en ', FGL_GETENV("HOME"), '/tmp/repp325.unl',
		' OK.'
DROP TABLE tmp_nuevo
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_stock_items(codigo, pos)
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE pos		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE tot_stock_loc	DECIMAL (8,2)
DEFINE tot_stock_rem	DECIMAL (8,2)
DEFINE tot_stock_gen 	DECIMAL (8,2)
DEFINE i, salir, lim	SMALLINT
DEFINE row_ini		SMALLINT
DEFINE query		CHAR(400)

CALL fl_lee_item(vg_codcia, codigo) RETURNING r_r10.*
IF r_r10.r10_compania IS NULL THEN
	RETURN
END IF
LET row_ini = 3
IF vg_gui = 0 THEN
	LET row_ini = 2
END IF
OPEN WINDOW w_repf247_3 AT row_ini, 31 WITH 21 ROWS, 48 COLUMNS
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf247_3 FROM '../forms/repf247_3'
ELSE
	OPEN FORM f_repf247_3 FROM '../forms/repf247_3c'
END IF
DISPLAY FORM f_repf247_3
CREATE TEMP TABLE temp_loc(
		bod_loc		CHAR(2), 
		nom_bod_loc	CHAR(30),
		stock_loc	DECIMAL(8,2),
		cant_loc	DECIMAL(8,2)
	)
CREATE TEMP TABLE temp_rem(
		bod_rem		CHAR(2), 
		nom_bod_rem	CHAR(30),
		stock_rem	DECIMAL(8,2)
	)
CALL mostrar_cabecera_bodegas_ln()
DISPLAY BY NAME codigo, r_r10.r10_nombre
DECLARE q_eme CURSOR FOR
	SELECT * FROM rept011
		WHERE r11_compania  = vg_codcia
		  AND r11_item      = codigo
		  AND r11_stock_act > 0
		ORDER BY r11_stock_act DESC, r11_bodega
LET i_loc = 0
LET i_rem = 0
LET tot_stock_loc = 0
LET tot_stock_rem = 0
FOREACH q_eme INTO r_r11.*
	CALL fl_lee_bodega_rep(vg_codcia, r_r11.r11_bodega) RETURNING r_r02.*
        IF r_r02.r02_tipo = 'S' THEN
		CONTINUE FOREACH
	END IF
        IF r_r02.r02_localidad = vg_codloc THEN
		LET i_loc                    = i_loc + 1
		LET r_loc[i_loc].bod_loc     = r_r11.r11_bodega
		LET r_loc[i_loc].nom_bod_loc = r_r02.r02_nombre
		LET r_loc[i_loc].stock_loc   = r_r11.r11_stock_act
		LET tot_stock_loc            = tot_stock_loc
						+ r_r11.r11_stock_act
		INSERT INTO temp_loc
			VALUES (r_r11.r11_bodega, r_r02.r02_nombre,
				r_r11.r11_stock_act, NULL)
	ELSE
		LET i_rem = i_rem + 1
		LET r_rem[i_rem].bod_rem     = r_r11.r11_bodega
		LET r_rem[i_rem].nom_bod_rem = r_r02.r02_nombre
		LET r_rem[i_rem].stock_rem   = r_r11.r11_stock_act
		LET tot_stock_rem            = tot_stock_rem
						+ r_r11.r11_stock_act
		INSERT INTO temp_rem VALUES (r_rem[i_rem].*)
	END IF
END FOREACH
IF i_loc = 0 AND i_rem = 0 THEN
	DROP TABLE temp_loc
	DROP TABLE temp_rem
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 0
	CLOSE WINDOW w_repf247_3
	RETURN
END IF
LET tot_stock_gen = tot_stock_loc + tot_stock_rem
LET lim           = fgl_scr_size('r_loc')
FOR i = 1 TO lim
	IF i > i_loc THEN
		EXIT FOR
	END IF
	DISPLAY r_loc[i].*  TO r_loc[i].*
END FOR
FOR i = 1 TO fgl_scr_size('r_rem')      
	IF i > i_rem THEN               
		EXIT FOR                
	END IF                          
	DISPLAY r_rem[i].* TO r_rem[i].*
END FOR                            
DISPLAY BY NAME tot_stock_loc, tot_stock_rem, tot_stock_gen
LET salir = 0
IF i_loc > 0 AND salir = 0 THEN
	CALL control_detalle_bodega_loc(pos) RETURNING salir
ELSE
	IF i_rem > 0 AND salir = 0 THEN
		CALL control_detalle_bodega_rem(pos) RETURNING salir
	END IF
END IF
DROP TABLE temp_loc
DROP TABLE temp_rem
LET int_flag = 0
CLOSE WINDOW w_repf247_3
RETURN

END FUNCTION



FUNCTION control_detalle_bodega_loc(pos)
DEFINE pos		SMALLINT
DEFINE i, j, salir	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT bod_loc, nom_bod_loc, stock_loc FROM temp_loc ',
			'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				',', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE loc FROM query
	DECLARE q_loc CURSOR FOR loc 
	LET i = 1
	FOREACH q_loc INTO r_loc[i].*
		LET i = i + 1
		IF i > i_loc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(1, i_loc, 0, i_rem)
	CALL set_count(i)
	DISPLAY ARRAY r_loc TO r_loc.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
        	        EXIT DISPLAY  
        	ON KEY(RETURN)   
			LET i = arr_curr()
			CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
		ON KEY(F5)
			IF i_rem > 0 THEN
				CALL muestra_contadores_det_tot(0, i_loc, 1,
								i_rem)
				CALL control_detalle_bodega_rem(pos)
					RETURNING salir
				IF salir = 1 THEN
					EXIT DISPLAY
				END IF
			END IF
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel('ACCEPT', '')   
			--#IF i_rem > 0 THEN
				--#CALL dialog.keysetlabel("F5","Remotas") 
			--#ELSE
				--#CALL dialog.keysetlabel("F5","") 
			--#END IF
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
	        --#AFTER DISPLAY  
	                --#CONTINUE DISPLAY  
	END DISPLAY
	IF salir = 1 THEN
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
RETURN salir

END FUNCTION 



FUNCTION control_detalle_bodega_rem(pos)
DEFINE pos		SMALLINT
DEFINE i, j, salir 	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_rem ',
			'ORDER BY ',
				vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
				vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE rem FROM query
	DECLARE q_rem CURSOR FOR rem 
	LET i = 1
	FOREACH q_rem INTO r_rem[i].*
		LET i = i + 1
		IF i > i_rem THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(0, i_loc, 1, i_rem)
	CALL set_count(i)
	DISPLAY ARRAY r_rem TO r_rem.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
	                EXIT DISPLAY  
		ON KEY(RETURN)
			LET i = arr_curr()	
			LET j = scr_line()
			CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
		ON KEY(F5)
			IF i_loc > 0 THEN
				CALL muestra_contadores_det_tot(1, i_loc, 0,
								i_rem)
				CALL control_detalle_bodega_loc(pos)
					RETURNING salir
				IF salir = 1 THEN
					EXIT DISPLAY
				END IF
			END IF
		ON KEY(F18)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 3
			EXIT DISPLAY
	        --#BEFORE DISPLAY 
	                --#CALL dialog.keysetlabel('ACCEPT', '')   
			--#CALL dialog.keysetlabel("F1","") 
			--#IF i_loc > 0 THEN
				--#CALL dialog.keysetlabel("F5","Locales") 
			--#ELSE
				--#CALL dialog.keysetlabel("F5","") 
			--#END IF
				--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
	        --#AFTER DISPLAY  
	                --#CONTINUE DISPLAY  
	END DISPLAY 
	IF salir = 1 THEN
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
RETURN salir

END FUNCTION 



FUNCTION control_items_pendientes(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE param		VARCHAR(100)

LET param = ' X X X X X N S "', item CLIPPED, '"'
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp318', param, 1)

END FUNCTION 



FUNCTION muestra_contadores_det_tot(num_row_l, max_row_l, num_row_r, max_row_r)
DEFINE num_row_l, max_row_l	SMALLINT
DEFINE num_row_r, max_row_r	SMALLINT

DISPLAY BY NAME num_row_l, max_row_l, num_row_r, max_row_r

END FUNCTION 



FUNCTION mostrar_cabecera_bodegas_ln()

DISPLAY 'BD'			TO tit_col1
DISPLAY 'Bodegas Locales'	TO tit_col2
DISPLAY 'Stock'			TO tit_col3
DISPLAY 'BD'			TO tit_col4
DISPLAY 'Bodegas Remotas'	TO tit_col5
DISPLAY 'Stock'			TO tit_col6

END FUNCTION 



FUNCTION muestra_tot_reg()
DEFINE query		CHAR(500)
DEFINE expr		VARCHAR(100)
DEFINE tot_item_dig	INTEGER

LET expr = NULL
IF vm_bodega IS NOT NULL THEN
	LET expr = '  AND r89_bodega = "', vm_bodega, '"'
END IF
LET query = 'SELECT COUNT(*) tot_dig ',
		'FROM rept089 ',
		'WHERE r89_compania     = ', vg_codcia,
			expr CLIPPED,
		'  AND DATE(r89_fecing) BETWEEN "', vm_fecha_ini,
					 '" AND "', vm_fecha_fin, '"',
		'INTO TEMP t_a '
PREPARE exec_t_a FROM query
EXECUTE exec_t_a
SELECT * INTO tot_item_dig FROM t_a
DISPLAY BY NAME tot_item_dig
DROP TABLE t_a

END FUNCTION 



FUNCTION control_estadisticas()
DEFINE r_det_est	ARRAY[100] OF RECORD
				bodega		LIKE rept002.r02_codigo,
				nombre		LIKE rept002.r02_nombre,
				max_reg		INTEGER,
				num_reg		INTEGER,
				porcentaje	DECIMAL(5,2)
			END RECORD
DEFINE query		CHAR(1800)
DEFINE expr		VARCHAR(100)
DEFINE i, col		SMALLINT
DEFINE num_row, max_row	SMALLINT
DEFINE tot_num_reg	INTEGER
DEFINE tot_max_reg	INTEGER
DEFINE tot_porc		DECIMAL(5,2)

LET max_row = 100
OPEN WINDOW w_repf250_2 AT 05, 10 WITH 17 ROWS, 61 COLUMNS
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_repf250_2 FROM '../forms/repf250_2'
ELSE
	OPEN FORM f_repf250_2 FROM '../forms/repf250_2c'
END IF
DISPLAY FORM f_repf250_2
DISPLAY 'BD'			TO tit_col1
DISPLAY 'Bodegas Locales'	TO tit_col2
DISPLAY 'Tot. Item'		TO tit_col3
DISPLAY 'Digitados'		TO tit_col4
DISPLAY '%'			TO tit_col5
CASE vg_codloc
	WHEN 1 LET expr = '  AND r02_localidad IN (1, 2) '
	WHEN 3 LET expr = '  AND r02_localidad IN (3, 5) '
	WHEN 4 LET expr = '  AND r02_localidad = 4 '
END CASE
LET query = 'SELECT r11_bodega bod, r02_nombre nom, COUNT(*) tot_reg, ',
		'(SELECT COUNT(*) ',
			'FROM rept089 ',
			'WHERE r89_compania     = r11_compania ',
			'  AND r89_bodega       = r11_bodega ',
			'  AND DATE(r89_fecing) BETWEEN "', vm_fecha_ini,
						 '" AND "', vm_fecha_fin,
			'") tot_dig ',
		{
		'(((SELECT COUNT(*) ',
			'FROM rept089 ',
			'WHERE r89_compania     = r11_compania ',
			'  AND r89_bodega       = r11_bodega ',
			'  AND DATE(r89_fecing) BETWEEN "', vm_fecha_ini,
						 '" AND "', vm_fecha_fin,
			'") / COUNT(*)) * 100) porcentaje ',
		}
		'FROM resp_exis, rept002 ',
		'WHERE r11_compania        = ', vg_codcia,
		'  AND DATE(r11_fec_corte) BETWEEN "', vm_fecha_ini,
					    '" AND "', vm_fecha_fin, '" ',
		'  AND r11_stock_act       > 0 ',
		'  AND r02_compania        = r11_compania ',
		'  AND r02_codigo          = r11_bodega ',
		'  AND r02_tipo            = "F" ',
			expr CLIPPED,
		'GROUP BY 1, 2, 4 ',
		'INTO TEMP tmp_est '
PREPARE exec_est FROM query
EXECUTE exec_est
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 1
LET vm_columna_1           = col
LET vm_columna_2           = 5
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT bod, nom, tot_dig, tot_reg, ',
				'((tot_dig / tot_reg) * 100) porc',
			' FROM tmp_est ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE deto3 FROM query
	DECLARE q_deto3 CURSOR FOR deto3
	LET tot_num_reg = 0
	LET tot_max_reg = 0
	LET tot_porc    = 0
	LET num_row     = 1
	FOREACH q_deto3 INTO r_det_est[num_row].*
		LET tot_max_reg = tot_max_reg + r_det_est[num_row].num_reg
		LET tot_num_reg = tot_num_reg + r_det_est[num_row].max_reg
		LET num_row     = num_row + 1
		IF num_row > max_row THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row  = num_row - 1
	LET tot_porc = (tot_num_reg / tot_max_reg) * 100
	DISPLAY BY NAME tot_num_reg, tot_max_reg, tot_porc
	LET int_flag = 0
	CALL set_count(num_row)
	DISPLAY ARRAY r_det_est TO r_det_est.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')   
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#DISPLAY i       TO num_row
			--#DISPLAY num_row TO max_row
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
DROP TABLE tmp_est
CLOSE WINDOW w_repf250_2
RETURN

END FUNCTION 

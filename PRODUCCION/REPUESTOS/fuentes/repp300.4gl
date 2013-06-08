------------------------------------------------------------------------------
-- Titulo           : repp300.4gl - Consulta Detallada de Items
-- Elaboracion      : 07-nov-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp300.4gl base_datos modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_item		ARRAY[3000] OF RECORD
				r11_bodega	LIKE rept011.r11_bodega,
				r10_sec_item	LIKE rept010.r10_sec_item,
				r10_codigo	LIKE rept010.r10_codigo,
				r10_nombre	LIKE rept010.r10_nombre,
				precio		DECIMAL(12,2),
				r11_stock_act	LIKE rept011.r11_stock_act
			END RECORD
DEFINE rm_par 		RECORD
				moneda		LIKE gent013.g13_moneda,
				tit_moneda	CHAR(20),
				bodega		LIKE rept002.r02_codigo,
				tit_bodega	VARCHAR(20),
				linea		LIKE rept003.r03_codigo,
				sub_linea	LIKE rept070.r70_sub_linea,
				tit_sub_linea	VARCHAR(35),
				cod_grupo	LIKE rept071.r71_cod_grupo,
				tit_grupo	VARCHAR(35),
				cod_clase	LIKE rept072.r72_cod_clase,
				tit_clase	VARCHAR(35),
				marca		LIKE rept010.r10_marca,       
				tit_marca	VARCHAR(35)
			END RECORD
DEFINE vm_max_rows	SMALLINT
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r01		RECORD LIKE rept001.*	-- SUBLINEA DE VENTA
DEFINE rm_sublin	RECORD LIKE rept070.*	-- SUBLINEA DE VENTA
DEFINE rm_grupo		RECORD LIKE rept071.*	-- GRUPO DE VENTA
DEFINE rm_clase		RECORD LIKE rept072.*	-- CLASE DE VENTA



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp300.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp300'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
INITIALIZE rm_par.*, rm_r01.* TO NULL
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.* 
LET rm_par.tit_moneda = r_mon.g13_nombre
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_rep.* 
LET rm_par.bodega = r_rep.r00_bodega_fact
CALL fl_lee_bodega_rep(vg_codcia, r_rep.r00_bodega_fact) RETURNING r_bod.*
LET rm_par.tit_bodega = r_bod.r02_nombre
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_estado     = 'A'
		  AND r01_user_owner = vg_usuario
OPEN qu_vd 
FETCH qu_vd INTO rm_r01.*
CLOSE qu_vd 
FREE qu_vd 
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
OPEN WINDOW w_repf300_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf300_1 FROM '../forms/repf300_1'
ELSE
	OPEN FORM f_repf300_1 FROM '../forms/repf300_1c'
END IF
DISPLAY FORM f_repf300_1
LET vm_max_rows = 3000
--#DISPLAY 'Bd'             TO tit_col1
--#DISPLAY 'Sec'            TO tit_col2
--#DISPLAY 'Item'           TO tit_col3
--#DISPLAY 'Descripción'    TO tit_col4
--#IF rm_g04.g04_ver_costo = 'N' THEN
	--DISPLAY ' '     	 TO tit_col5
--#ELSE
	---#DISPLAY 'Marg.'          TO tit_col5
--#END IF
--#DISPLAY 'Precio Unit.'   TO tit_col5
--#DISPLAY 'Stock'          TO tit_col6
DISPLAY BY NAME rm_par.tit_moneda, rm_par.tit_bodega
--#LET vm_size_arr = fgl_scr_size('rm_item')
IF vg_gui = 0 THEN
	LET vm_size_arr = 8
END IF
WHILE TRUE
	FOR i = 1 TO vm_size_arr 
		CLEAR rm_item[i].*
	END FOR
	CALL lee_parametros1()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL lee_parametros2()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL muestra_consulta()
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf300_1
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros1()
DEFINE resp		CHAR(3)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE bod_aux		LIKE rept002.r02_codigo
DEFINE lin_aux		LIKE rept003.r03_codigo
DEFINE tit_aux		VARCHAR(30)
DEFINE num_dec		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE flag		CHAR(1)
DEFINE marca		LIKE rept010.r10_marca

IF rm_par.sub_linea IS NOT NULL THEN
	CALL fl_lee_sublinea_rep(vg_codcia, rm_par.linea, rm_par.sub_linea)
		RETURNING rm_sublin.*
	DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
END IF
IF rm_par.cod_grupo IS NOT NULL THEN
	CALL fl_lee_grupo_rep(vg_codcia, rm_par.linea, rm_par.sub_linea,
				rm_par.cod_grupo)
		RETURNING rm_grupo.*
	DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
END IF
IF rm_par.cod_clase IS NOT NULL THEN
	CALL fl_lee_clase_rep(vg_codcia, rm_par.linea, rm_par.sub_linea,
				rm_par.cod_grupo, rm_par.cod_clase)
		RETURNING rm_clase.*
	DISPLAY rm_clase.r72_desc_clase TO tit_clase
END IF
LET int_flag = 0
INPUT BY NAME rm_par.moneda, rm_par.bodega, rm_par.linea, rm_par.sub_linea,
	rm_par.cod_grupo, rm_par.cod_clase, rm_par.marca
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda     = mon_aux
				LET rm_par.tit_moneda = tit_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, 'T', 'T', 'T', 'A', 'T', '0')
				RETURNING bod_aux, tit_aux
			IF bod_aux IS NOT NULL THEN
				LET rm_par.bodega     = bod_aux
				LET rm_par.tit_bodega = tit_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING lin_aux, tit_aux
       		     	LET int_flag = 0
			IF lin_aux IS NOT NULL THEN
				LET rm_par.linea = lin_aux
				DISPLAY tit_aux TO tit_division
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
	{-- Añadido por NPC --}
		IF INFIELD(sub_linea) THEN
		     CALL fl_ayuda_sublinea_rep(vg_codcia, rm_par.linea)
		     	RETURNING rm_sublin.r70_sub_linea,
				  rm_sublin.r70_desc_sub
       		     LET int_flag = 0
		     IF rm_sublin.r70_sub_linea IS NOT NULL THEN
			LET rm_par.sub_linea = rm_sublin.r70_sub_linea
			DISPLAY BY NAME rm_par.sub_linea
			DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
		     END IF
		END IF
		IF INFIELD(cod_grupo) THEN
		     CALL fl_ayuda_grupo_ventas_rep(vg_codcia, rm_par.linea,
							rm_par.sub_linea)
		     	RETURNING rm_grupo.r71_cod_grupo,
		     		  rm_grupo.r71_desc_grupo
       		     LET int_flag = 0
		     IF rm_grupo.r71_cod_grupo IS NOT NULL THEN
			LET rm_par.cod_grupo = rm_grupo.r71_cod_grupo
			DISPLAY BY NAME rm_par.cod_grupo
			DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
		     END IF
		END IF
		IF INFIELD(cod_clase) THEN
		     CALL fl_ayuda_clase_ventas_rep(vg_codcia, rm_par.linea,
							rm_par.sub_linea,
							rm_par.cod_grupo)
		     	RETURNING rm_clase.r72_cod_clase,
		     		  rm_clase.r72_desc_clase
       		     LET int_flag = 0
		     IF rm_clase.r72_cod_clase IS NOT NULL THEN
			LET rm_par.cod_clase = rm_clase.r72_cod_clase
			DISPLAY BY NAME rm_par.cod_clase
			DISPLAY rm_clase.r72_desc_clase TO tit_clase
		     END IF
		END IF
		IF INFIELD(marca) THEN
			CALL fl_ayuda_marcas_rep_asignadas(vg_codcia, 
								rm_par.marca)
	  			RETURNING marca
       		     	LET int_flag = 0
			IF marca IS NOT NULL THEN
				LET rm_par.marca = marca
				CALL fl_lee_marca_rep(vg_codcia, rm_par.marca)
					RETURNING r_r73.*
				DISPLAY BY NAME rm_par.marca
				DISPLAY r_r73.r73_desc_marca TO tit_marca
	   		END IF
		END IF
	{-- --}
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_moneda = r_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_moneda
		ELSE
			LET rm_par.tit_moneda = NULL
			CLEAR tit_moneda
		END IF
	AFTER FIELD bodega
		IF rm_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega) RETURNING r_bod.*
			IF r_bod.r02_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				NEXT FIELD bodega
			END IF
			LET rm_par.tit_bodega = r_bod.r02_nombre
			DISPLAY BY NAME rm_par.tit_bodega
		ELSE
			LET rm_par.tit_bodega = NULL
			CLEAR tit_bodega
		END IF
	AFTER FIELD linea
		IF rm_par.linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_par.linea) RETURNING r_lin.*
			IF r_lin.r03_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'División no existe.','exclamation')
				CALL fl_mostrar_mensaje('División no existe.','exclamation')
				NEXT FIELD linea
			END IF
			DISPLAY r_lin.r03_nombre TO tit_division
		ELSE
			CLEAR tit_division
		END IF
	{-- Añadido por NPC --}
	AFTER FIELD sub_linea
                IF rm_par.sub_linea IS NOT NULL THEN
			CALL fl_retorna_sublinea_rep(vg_codcia,
						rm_par.sub_linea)
				RETURNING rm_sublin.*, flag
			IF flag = 0 THEN
				IF rm_sublin.r70_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Línea no existe.','exclamation')
					NEXT FIELD sub_linea
				END IF
			END IF
			DISPLAY rm_sublin.r70_desc_sub TO tit_sub_linea
		ELSE 
		     	CLEAR tit_sub_linea
                END IF
	AFTER FIELD cod_grupo
                IF rm_par.cod_grupo IS NOT NULL THEN
			CALL fl_retorna_grupo_rep(vg_codcia,
						rm_par.cod_grupo)
				RETURNING rm_grupo.*, flag
			IF flag = 0 THEN
				IF rm_grupo.r71_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
					NEXT FIELD cod_grupo
				END IF
			END IF
			DISPLAY rm_grupo.r71_desc_grupo TO tit_grupo
		ELSE 
		     	CLEAR tit_grupo
                END IF
	AFTER FIELD cod_clase
                IF rm_par.cod_clase IS NOT NULL THEN
			CALL fl_retorna_clase_rep(vg_codcia, rm_par.cod_clase)
				RETURNING rm_clase.*, flag
			IF flag = 0 THEN
				IF rm_clase.r72_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Clase no existe.','exclamation')
					NEXT FIELD cod_clase
				END IF
			END IF
			DISPLAY rm_clase.r72_desc_clase TO tit_clase
		ELSE 
		     	CLEAR tit_clase
                END IF
	AFTER FIELD marca 
		IF rm_par.marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_par.marca)
				RETURNING r_r73.*
			IF r_r73.r73_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Marca no existe.','exclamation')
				NEXT FIELD marca
			END IF
			DISPLAY r_r73.r73_desc_marca TO tit_marca
		ELSE
			CLEAR tit_marca
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE i		INTEGER
DEFINE query		CHAR(700)
DEFINE campos		VARCHAR(50)
DEFINE expr_sql		CHAR(400)
DEFINE expr_bod		VARCHAR(100)
DEFINE expr_lin		VARCHAR(100)
DEFINE expr_sub		VARCHAR(100)
DEFINE expr_grp		VARCHAR(100)
DEFINE expr_cla		VARCHAR(100)
DEFINE expr_marca	VARCHAR(100)
DEFINE te_codigo	CHAR(15)
DEFINE te_nombre 	CHAR(40)
DEFINE te_costo		DECIMAL(14,2)
DEFINE te_precio	DECIMAL(14,2)
DEFINE te_margen	DECIMAL(14,2)
DEFINE te_stock		DECIMAL (8,2)
DEFINE rs		RECORD LIKE rept011.*
DEFINE marca		LIKE rept010.r10_marca

LET int_flag = 0
IF rm_par.moneda = rg_gen.g00_moneda_base THEN
	LET campos = 'r10_costo_mb costo, r10_precio_mb precio,'
	LET int_flag = 0
	CONSTRUCT expr_sql ON r10_sec_item, r10_codigo, r10_nombre,
			      r10_precio_mb, r11_stock_act FROM 
			      r10_sec_item, r10_codigo, r10_nombre, precio, 
			      r11_stock_act
        	ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE CONSTRUCT
			--DISPLAY '> 0' TO r11_stock_act
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
ELSE
	LET campos = 'r10_costo_ma costo, r10_precio_ma precio,'
	LET int_flag = 0
	CONSTRUCT expr_sql ON r10_sec_item, r10_codigo, r10_nombre, 
			      r10_precio_ma, r11_stock_act FROM 
			      r10_sec_item, r10_codigo, r10_nombre, precio,
			      r11_stock_act
        	ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE CONSTRUCT
			--DISPLAY '> 0' TO r11_stock_act
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
END IF
IF int_flag THEN
	RETURN
END IF
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_bod = ' '
IF rm_par.bodega IS NOT NULL THEN
	LET expr_bod = " AND r11_bodega = '", rm_par.bodega CLIPPED, "'"
END IF
LET expr_lin = ' '
IF rm_par.linea IS NOT NULL THEN
	LET expr_lin = " AND r10_linea = '", rm_par.linea CLIPPED, "'"
END IF
LET expr_sub = ' '
IF rm_par.sub_linea IS NOT NULL THEN
	LET expr_sub = " AND r10_sub_linea = '", rm_par.sub_linea CLIPPED, "'"
END IF
LET expr_grp = ' '
IF rm_par.cod_grupo IS NOT NULL THEN
	LET expr_grp = " AND r10_cod_grupo = '", rm_par.cod_grupo CLIPPED, "'"
END IF
LET expr_cla = ' '
IF rm_par.cod_clase IS NOT NULL THEN
	LET expr_cla = " AND r10_cod_clase = '", rm_par.cod_clase CLIPPED, "'"
END IF
LET expr_marca = ' '
IF rm_par.marca IS NOT NULL THEN
	LET expr_marca = " AND r10_marca = '", rm_par.marca CLIPPED, "'"
END IF
LET query = 'SELECT r11_bodega, r10_sec_item, r10_codigo, r10_nombre, ',
			campos, ' 0 margen, ',
			' r11_stock_act',
		  	' FROM rept010, rept011 ',
		  	' WHERE r10_compania  = ', vg_codcia,
		          expr_lin CLIPPED, 
		          expr_sub CLIPPED,  
		          expr_grp CLIPPED,  
		          expr_marca CLIPPED,  
		          expr_cla CLIPPED, ' AND ', 
			  expr_sql CLIPPED, ' AND ',
			' r11_bodega   NOT IN ("QC", "GC") AND ',
			' r10_compania  = r11_compania ',
			  expr_bod CLIPPED, ' AND ',
			' r10_codigo    = r11_item ',
			' INTO TEMP temp_item'
PREPARE cit FROM query
EXECUTE cit
SELECT COUNT(*) INTO i FROM temp_item
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	DROP TABLE temp_item
	RETURN
END IF
UPDATE temp_item SET margen = (precio - costo) / costo * 100
	WHERE costo > 0
IF rm_g04.g04_ver_costo = 'N' THEN
	UPDATE temp_item SET costo  = NULL,
			     margen = NULL
END IF
DECLARE q_lito CURSOR FOR SELECT * FROM temp_item
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION
 


FUNCTION muestra_consulta()
DEFINE i		SMALLINT
DEFINE query		CHAR(300)
DEFINE num_rows		INTEGER
DEFINE sustituye_con	SMALLINT
DEFINE ver_item		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r76		RECORD LIKE rept076.*

LET ver_item = 0
IF rm_r01.r01_compania IS NOT NULL THEN
	IF rm_r01.r01_tipo = 'J' OR rm_r01.r01_tipo = 'G' THEN
		LET ver_item = 1
	END IF
ELSE
	IF rm_g04.g04_ver_costo = 'S' THEN
		LET ver_item = 1
	END IF
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT r11_bodega, r10_sec_item, r10_codigo, r10_nombre, ',
			' precio, r11_stock_act',
			' FROM temp_item ',
			'ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_item[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET num_rows = i - 1
	IF vg_gui = 0 THEN
		CALL muestra_etiquetas_det(1, num_rows,	rm_item[1].r10_codigo)
	END IF
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_item TO rm_item.*
		ON KEY(INTERRUPT)
			CLEAR descri_item, descri_clase
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			CALL muestra_etiquetas_det(i, num_rows,
							rm_item[i].r10_codigo)
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			IF ver_item THEN
				LET i = arr_curr()
				CALL mostrar_item(i)
			END IF
		ON KEY(F6)
			CALL sustituido(r_r10.*)
		ON KEY(F7)
			CALL sustituye(r_r10.*)
		ON KEY(F8)
			CALL control_ver_ubicacion(r_r10.r10_codigo, 
						   r_r10.r10_nombre)
		ON KEY(F9)
			LET i = arr_curr()
			CALL control_pedidos(rm_item[i].r10_codigo,
					     r_r10.r10_nombre)
		ON KEY(F10)
			CALL muestra_stock_max_min(ver_item)
			LET int_flag = 0
			{--
			IF vg_gui = 0 THEN
				LET i = arr_curr()
				INITIALIZE r_r76.* TO NULL
				DECLARE q_ser2 CURSOR FOR
					SELECT UNIQUE * FROM rept076
					WHERE r76_compania  = vg_codcia
					  AND r76_localidad = vg_codloc 
					  AND r76_bodega    = rm_par.bodega
					  AND r76_item   = rm_item[i].r10_codigo
				OPEN q_ser2
				FETCH q_ser2 INTO r_r76.*
			END IF
			IF r_r76.r76_serie IS NOT NULL THEN
				LET i = arr_curr()
				CALL fl_ayuda_serie_rep(vg_codcia, vg_codloc,
						rm_par.bodega,
						rm_item[i].r10_codigo, 'T')
					RETURNING r_r76.r76_serie,
						  r_r76.r76_fecing
				LET int_flag = 0
			END IF
			IF vg_gui = 0 THEN
				CLOSE q_ser2
				FREE q_ser2
			END IF
			--}
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_etiquetas_det(i, num_rows, rm_item[i].r10_codigo)
			--#CALL fl_lee_item(vg_codcia, rm_item[i].r10_codigo)
				--#RETURNING r_r10.*
			--#IF r_r10.r10_estado = 'S' THEN
				--#CALL dialog.keysetlabel('F6', 'Sustituido Por')
			--#ELSE
				--#CALL dialog.keysetlabel('F6', '')
			--#END IF			
			
			--#SELECT COUNT(r14_item_ant) INTO sustituye_con FROM rept014
				--#WHERE r14_compania = vg_codcia
				  --#AND r14_item_nue = r_r10.r10_codigo
			--#IF sustituye_con > 0 THEN
				--#CALL dialog.keysetlabel('F7', 'Sustituye a')
			--#ELSE
				--#CALL dialog.keysetlabel('F7', '')
			--#END IF			
			--#CALL dialog.keysetlabel('F9', 'Pedidos')

			--#INITIALIZE r_r76.* TO NULL
			--#DECLARE q_ser CURSOR FOR
				--#SELECT UNIQUE * FROM rept076
					--#WHERE r76_compania  = vg_codcia
					  --#AND r76_localidad = vg_codloc 
					  --#AND r76_bodega    = rm_par.bodega
					  --#AND r76_item= rm_item[i].r10_codigo
			--#OPEN q_ser
			--#FETCH q_ser INTO r_r76.*
			--#IF r_r76.r76_serie IS NOT NULL THEN
				--#CALL dialog.keysetlabel('F10', 'Series')
			--#ELSE
				--CALL dialog.keysetlabel('F10', '')
			--#END IF
			--#CLOSE q_ser
			--#FREE q_ser
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('RETURN', '')
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--IF rm_g04.g04_ver_costo = 'N' THEN
			--#IF NOT ver_item THEN
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 0 THEN
		CONTINUE WHILE
	END IF
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1 = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE temp_item
CLEAR descri_item, descri_clase, num_row, max_row

END FUNCTION



FUNCTION control_pedidos(item, nombre)
DEFINE item		LIKE rept010.r10_codigo
DEFINE nombre		LIKE rept010.r10_nombre

DEFINE i		SMALLINT

DEFINE r_pedido ARRAY[100] OF RECORD
	pedido		LIKE rept016.r16_pedido, 
	proveedor	LIKE rept016.r16_proveedor, 
	fecha_lleg	LIKE rept016.r16_fec_llegada, 
	cantidad	LIKE rept017.r17_cantped
END RECORD

OPEN WINDOW w_300_4 AT 8, 33 WITH 14 ROWS, 46 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_300_4 FROM '../forms/repf300_4'
ELSE
	OPEN FORM f_300_4 FROM '../forms/repf300_4c'
END IF
DISPLAY FORM f_300_4

--#DISPLAY 'Pedido'	TO bt_pedido
--#DISPLAY 'Proveedor'	TO bt_proveedor
--#DISPLAY 'Fec. Lleg.'	TO bt_fecha
--#DISPLAY 'Cant.'	TO bt_cantidad

DISPLAY item TO item
DISPLAY nombre TO n_item

DECLARE q_pedido CURSOR FOR
	SELECT r17_pedido, r16_proveedor, r16_fec_llegada, r17_cantped
		FROM rept016, rept017
		WHERE r17_compania  = vg_codcia
	          AND r17_item      = item
		  AND r17_estado    NOT IN ('A', 'P')
		  AND r16_compania  = r17_compania
                  AND r16_localidad = r17_localidad
                  AND r16_pedido    = r17_pedido
	UNION ALL
	SELECT r17_pedido, r16_proveedor, r16_fec_llegada, 
	       (r17_cantped - r17_cantrec)
		FROM rept016, rept017
		WHERE r17_compania  = vg_codcia
	          AND r17_item      = item
		  AND r17_cantped   > r17_cantrec 
		  AND r17_estado    = 'P'
		  AND r16_compania  = r17_compania
                  AND r16_localidad = r17_localidad
                  AND r16_pedido    = r17_pedido
                  
LET i = 1
FOREACH q_pedido INTO r_pedido[i].*
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 0
	CLOSE WINDOW w_300_4
        RETURN
END IF

CALL set_count(i)
DISPLAY ARRAY r_pedido TO ra_pedido.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('RETURN', '')
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY

LET int_flag = 0
CLOSE WINDOW w_300_4
RETURN

END FUNCTION



FUNCTION sustituye(r_item)
DEFINE i		SMALLINT
DEFINE max_items	SMALLINT
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_items ARRAY[100] OF RECORD 
	item		LIKE rept010.r10_codigo, 
	nombre		LIKE rept010.r10_nombre, 	
	fecha		DATE
END RECORD
DEFINE mensaje		VARCHAR(132)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET max_items = 100

LET lin_menu = 0
LET row_ini  = 9
LET num_rows = 12
LET num_cols = 68
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 8
	LET num_rows = 15
	LET num_cols = 69
END IF
OPEN WINDOW w_300_2 AT row_ini, 8 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_300_2 FROM '../forms/repf300_2'
ELSE
	OPEN FORM f_300_2 FROM '../forms/repf300_2c'
END IF
DISPLAY FORM f_300_2

LET mensaje = fl_justifica_titulo('D', 'Sustituto', 10)
DISPLAY mensaje TO lbl_item
--#DISPLAY 'Sustituidos' TO bt_item
--#DISPLAY 'Fecha'       TO bt_fecha

DISPLAY r_item.r10_codigo TO item1
DISPLAY r_item.r10_nombre TO n_item1

-- Cursor que obtiene los items sustituidos por este item,
-- es decir, a quienes sustituye
DECLARE q_sustituidos2 CURSOR FOR 
	SELECT r14_item_ant, r10_nombre, DATE(r14_fecing) 
		FROM rept014, rept010
		WHERE r14_compania = vg_codcia
		  AND r14_item_nue = r_item.r10_codigo
		  AND r10_compania = r14_compania 
		  AND r10_codigo   = r14_item_ant

LET i = 1
FOREACH q_sustituidos2 INTO r_items[i].*
	LET i = i + 1
	IF i > max_items THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
CALL set_count(i)
DISPLAY ARRAY r_items TO ra_items.*

LET int_flag = 0
CLOSE WINDOW w_300_2
RETURN

END FUNCTION



FUNCTION sustituido(r_item)
DEFINE i		SMALLINT
DEFINE max_items	SMALLINT
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_items ARRAY[100] OF RECORD
	item		LIKE rept010.r10_codigo, 
	nombre		LIKE rept010.r10_nombre, 	
	fecha		DATE
END RECORD
DEFINE mensaje		VARCHAR(132)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET max_items = 100

LET lin_menu = 0
LET row_ini  = 9
LET num_rows = 12
LET num_cols = 68
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 8
	LET num_rows = 15
	LET num_cols = 69
END IF
OPEN WINDOW w_300_2 AT row_ini, 8 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_300_2 FROM '../forms/repf300_2'
ELSE
	OPEN FORM f_300_2 FROM '../forms/repf300_2c'
END IF
DISPLAY FORM f_300_2

LET mensaje = fl_justifica_titulo('D', 'Sustituto', 10)
DISPLAY mensaje TO lbl_item
--#DISPLAY 'Sustituto' TO bt_item
--#DISPLAY 'Fecha'     TO bt_fecha

DISPLAY r_item.r10_codigo TO item1
DISPLAY r_item.r10_nombre TO n_item1

-- Cursor que obtiene los items sustitutos para este item,
-- es decir, por quienes fue sustituido
DECLARE q_sustitutos2 CURSOR FOR 
	SELECT r14_item_nue, r10_nombre, DATE(r14_fecing) FROM rept014, rept010
		WHERE r14_compania = vg_codcia
		  AND r14_item_ant = r_item.r10_codigo
		  AND r10_compania = r14_compania 
		  AND r10_codigo   = r14_item_nue
		  
LET i = 1
FOREACH q_sustitutos2 INTO r_items[i].*
	LET i = i + 1
	IF i > max_items THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1

CALL set_count(i)
--DISPLAY ARRAY r_items TO ra_items[i].*
DISPLAY ARRAY r_items TO ra_items.*

LET int_flag = 0
CLOSE WINDOW w_300_2
RETURN

END FUNCTION



FUNCTION control_ver_ubicacion(item, nombre)
DEFINE item 		LIKE rept010.r10_codigo
DEFINE nombre 		LIKE rept010.r10_nombre
DEFINE i 		SMALLINT
DEFINE r_detalle	ARRAY[100] OF RECORD
	bodega		LIKE rept011.r11_bodega,
	n_bodega	LIKE rept002.r02_nombre,
	stock		LIKE rept011.r11_stock_act,
	ubicacion	LIKE rept011.r11_ubicacion	
	END RECORD

OPEN WINDOW w_300_3 AT 8, 34 WITH 12 ROWS, 45 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST , BORDER, MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_300_3 FROM '../forms/repf300_3'
ELSE
	OPEN FORM f_300_3 FROM '../forms/repf300_3c'
END IF
DISPLAY FORM f_300_3

--#DISPLAY 'Bodega'    TO bt_bodega
--#DISPLAY 'Stock'     TO bt_stock
--#DISPLAY 'Ubicación' TO bt_ubicacion

DISPLAY item TO item
DISPLAY nombre TO n_item

DECLARE q_ubicacion CURSOR FOR
	SELECT r11_bodega, r02_nombre, r11_stock_act, r11_ubicacion
		 FROM rept011, rept002
		WHERE r11_compania = vg_codcia
		  AND r11_item     = item
		  AND r11_compania = r02_compania
		  AND r11_bodega   = r02_codigo		
		  AND r02_codigo   NOT IN ('QC', 'GC')
LET i = 1
FOREACH q_ubicacion INTO r_detalle[i].*
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1

CALL set_count(i)
--DISPLAY ARRAY r_detalle TO r_detalle[i].*
DISPLAY ARRAY r_detalle TO r_detalle.*

LET int_flag = 0
CLOSE WINDOW w_300_3
RETURN

END FUNCTION



FUNCTION mostrar_item(i)
DEFINE i		SMALLINT
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET comando = run_prog, 'repp108 ', vg_base, ' RE ', vg_codcia, ' ', vg_codloc, ' "', rm_item[i].r10_codigo CLIPPED, '"'
RUN comando

END FUNCTION



FUNCTION muestra_etiquetas_det(num_row, max_row, item)
DEFINE num_row, max_row	SMALLINT
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

DISPLAY BY NAME num_row, max_row
CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
	RETURNING r_r72.*
DISPLAY r_r72.r72_desc_clase TO descri_clase
DISPLAY r_r10.r10_nombre     TO descri_item

END FUNCTION



FUNCTION muestra_stock_max_min(ver_item)
DEFINE ver_item		SMALLINT
DEFINE r_item_max	ARRAY [3000] OF RECORD
				r10_codigo	LIKE rept010.r10_codigo,
				r10_nombre	LIKE rept010.r10_nombre,
				r10_stock_max	LIKE rept010.r10_stock_max,
				r10_stock_min	LIKE rept010.r10_stock_min
			END RECORD
DEFINE i, num_row	SMALLINT
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE r_r10		RECORD LIKE rept010.*

OPEN WINDOW w_300_5 AT 05, 07 WITH 18 ROWS, 68 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST, BORDER, MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_300_5 FROM '../forms/repf300_5'
ELSE
	OPEN FORM f_300_5 FROM '../forms/repf300_5c'
END IF
DISPLAY FORM f_300_5
--#DISPLAY 'Item'		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY 'Maximo'		TO tit_col3
--#DISPLAY 'Mínimo'		TO tit_col4
FOR i = 1 TO vm_max_rows
	INITIALIZE r_item_max[i].* TO NULL
END FOR
DECLARE q_maxmin CURSOR FOR
	SELECT UNIQUE r10_codigo FROM temp_item ORDER BY r10_codigo ASC
LET num_row = 1
FOREACH q_maxmin INTO codigo
	CALL fl_lee_item(vg_codcia, codigo) RETURNING r_r10.*
	LET r_item_max[num_row].r10_codigo    = codigo
	LET r_item_max[num_row].r10_nombre    = r_r10.r10_nombre
	LET r_item_max[num_row].r10_stock_max = r_r10.r10_stock_max
	LET r_item_max[num_row].r10_stock_min = r_r10.r10_stock_min
	LET num_row                           = num_row + 1
	IF num_row > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	LET int_flag = 0
	CLOSE WINDOW w_300_5
	RETURN
END IF
IF vg_gui = 0 THEN
	CALL muestra_etiquetas_det(1, num_row, r_item_max[1].r10_codigo)
END IF
CALL set_count(num_row)
DISPLAY ARRAY r_item_max TO r_item_max.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(RETURN)
		LET i = arr_curr()
		CALL muestra_etiquetas_det(i, num_row, r_item_max[i].r10_codigo)
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_2() 
	ON KEY(F5)
		IF ver_item THEN
			LET i = arr_curr()
			CALL mostrar_item(i)
		END IF
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#CALL muestra_etiquetas_det(i, num_row,
						--#r_item_max[i].r10_codigo)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('RETURN', '')
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#IF NOT ver_item THEN
			--#CALL dialog.keysetlabel("F5","")
		--#END IF
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
LET int_flag = 0
CLOSE WINDOW w_300_5
RETURN

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



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Item'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Sustituído'               AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Sustituye'               AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Ver Ubicación'           AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F9>      Ver Pedido'              AT a,2
DISPLAY  'F9' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F10>     Stock Maximo Minimo'     AT a,2
DISPLAY  'F10' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Item'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

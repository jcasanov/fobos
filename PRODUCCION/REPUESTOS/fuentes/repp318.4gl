--------------------------------------------------------------------------------
-- Titulo           : repp318.4gl - Consulta de Items Pendientes
-- Elaboracion      : 03-mar-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp318 base modulo compañía localidad
--			[rm_par.*]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_par 		RECORD
				r10_linea	LIKE rept010.r10_linea,
				r03_nombre	LIKE rept003.r03_nombre,
				r10_sub_linea	LIKE rept010.r10_sub_linea,
				r70_desc_sub	LIKE rept070.r70_desc_sub,
				r10_cod_grupo	LIKE rept010.r10_cod_grupo,
				r71_desc_grupo	LIKE rept071.r71_desc_grupo,
				r10_cod_clase	LIKE rept010.r10_cod_clase,
				r72_desc_clase	LIKE rept072.r72_desc_clase,
				r10_marca	LIKE rept010.r10_marca,       
				r73_desc_marca	LIKE rept073.r73_desc_marca,
				pend_falta	CHAR(1),
				pendientes	CHAR(1)
			END RECORD
DEFINE rm_item		ARRAY[3000] OF RECORD
				r10_codigo	LIKE rept010.r10_codigo,
				r10_nombre	LIKE rept010.r10_nombre,
				stock_pend	DECIMAL(8,2),
				stock_total	DECIMAL(8,2),
				stock_local	DECIMAL(8,2),
				r10_stock_max	LIKE rept010.r10_stock_max,
				r10_stock_min	LIKE rept010.r10_stock_min
			END RECORD
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_stock_pend	SMALLINT
DEFINE vm_expr_loc	VARCHAR(50)
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_sublin	RECORD LIKE rept070.*
DEFINE rm_grupo		RECORD LIKE rept071.*
DEFINE rm_clase		RECORD LIKE rept072.*
DEFINE rm_g01		RECORD LIKE gent001.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp318.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 11 AND num_args() <> 12 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp318'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE codloc		LIKE gent002.g02_localidad

CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
INITIALIZE rm_par.*, rm_r01.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_estado     = 'A'
		  AND r01_user_owner = vg_usuario
OPEN qu_vd 
FETCH qu_vd INTO rm_r01.*
CLOSE qu_vd 
FREE qu_vd 
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
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
OPEN WINDOW w_repf318_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp318_1 FROM '../forms/repf318_1'
ELSE
	OPEN FORM f_repp318_1 FROM '../forms/repf318_1c'
END IF
DISPLAY FORM f_repp318_1
LET vm_max_rows = 3000
--#DISPLAY 'Item'		TO tit_col1
--#DISPLAY 'Descripción'	TO tit_col2
--#DISPLAY 'Stock Pend.'	TO tit_col3
--#DISPLAY 'Stock Total'	TO tit_col4
--#DISPLAY 'Stock Local'	TO tit_col5
--#DISPLAY 'Maximo'		TO tit_col6
--#DISPLAY 'Minimo'		TO tit_col7
--#LET vm_size_arr = fgl_scr_size('rm_item')
IF vg_gui = 0 THEN
	LET vm_size_arr = 8
END IF
LET rm_par.pend_falta = 'S'
LET rm_par.pendientes = 'S'
LET vm_expr_loc	      = NULL
CASE vg_codloc
	WHEN 1
		LET codloc = 2
	WHEN 2
		LET codloc = 1
	WHEN 3
		LET codloc = 4
	WHEN 4
		LET codloc = 3
END CASE
LET vm_expr_loc = ' r02_localidad IN (', vg_codloc, ', ', codloc, ')'
WHILE TRUE
	LET vm_num_rows = 0
	FOR i = 1 TO vm_size_arr 
		CLEAR rm_item[i].*
	END FOR
	IF num_args() = 4 THEN
		CALL lee_parametros1()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_par.r10_linea     = arg_val(5)
		IF rm_par.r10_linea = 'X' THEN
			LET rm_par.r10_linea = NULL
		END IF
		LET rm_par.r10_sub_linea = arg_val(6)
		IF rm_par.r10_sub_linea = 'X' THEN
			LET rm_par.r10_sub_linea = NULL
		END IF
		LET rm_par.r10_cod_grupo = arg_val(7)
		IF rm_par.r10_cod_grupo = 'X' THEN
			LET rm_par.r10_cod_grupo = NULL
		END IF
		LET rm_par.r10_cod_clase = arg_val(8)
		IF rm_par.r10_cod_clase = 'X' THEN
			LET rm_par.r10_cod_clase = NULL
		END IF
		LET rm_par.r10_marca     = arg_val(9)
		IF rm_par.r10_marca = 'X' THEN
			LET rm_par.r10_marca = NULL
		END IF
		LET rm_par.pend_falta    = arg_val(10)
		LET rm_par.pendientes    = arg_val(11)
		DISPLAY BY NAME rm_par.*
	END IF
	CALL lee_parametros2()
	IF int_flag THEN
		IF num_args() <> 4 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CALL control_consulta()
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE temp_item
	IF vm_stock_pend THEN
		DROP TABLE temp_pend
	END IF
	IF num_args() <> 4 THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf318_1
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros1()
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE flag		CHAR(1)
DEFINE p_fal, pend	CHAR(1)

IF rm_par.r10_sub_linea IS NOT NULL THEN
	CALL fl_lee_sublinea_rep(vg_codcia, rm_par.r10_linea,
					rm_par.r10_sub_linea)
		RETURNING rm_sublin.*
	DISPLAY BY NAME rm_sublin.r70_desc_sub
END IF
IF rm_par.r10_cod_grupo IS NOT NULL THEN
	CALL fl_lee_grupo_rep(vg_codcia, rm_par.r10_linea, rm_par.r10_sub_linea,
				rm_par.r10_cod_grupo)
		RETURNING rm_grupo.*
	DISPLAY BY NAME rm_grupo.r71_desc_grupo
END IF
IF rm_par.r10_cod_clase IS NOT NULL THEN
	CALL fl_lee_clase_rep(vg_codcia, rm_par.r10_linea, rm_par.r10_sub_linea,
				rm_par.r10_cod_grupo, rm_par.r10_cod_clase)
		RETURNING rm_clase.*
	DISPLAY BY NAME rm_clase.r72_desc_clase
END IF
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r10_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING r_r03.r03_codigo, r_r03.r03_nombre
			LET int_flag = 0
			IF r_r03.r03_codigo IS NOT NULL THEN
				LET rm_par.r10_linea  = r_r03.r03_codigo
				LET rm_par.r03_nombre = r_r03.r03_nombre
				DISPLAY BY NAME rm_par.r10_linea,
						rm_par.r03_nombre
			END IF
		END IF
		IF INFIELD(r10_sub_linea) THEN
			CALL fl_ayuda_sublinea_rep(vg_codcia, rm_par.r10_linea)
				RETURNING rm_sublin.r70_sub_linea,
					  rm_sublin.r70_desc_sub
			LET int_flag = 0
			IF rm_sublin.r70_sub_linea IS NOT NULL THEN
				LET rm_par.r10_sub_linea =
						rm_sublin.r70_sub_linea
				LET rm_par.r70_desc_sub  =
						rm_sublin.r70_desc_sub
				DISPLAY BY NAME rm_par.r10_sub_linea,
						rm_sublin.r70_desc_sub
			END IF
		END IF
		IF INFIELD(r10_cod_grupo) THEN
			CALL fl_ayuda_grupo_ventas_rep(vg_codcia,
							rm_par.r10_linea,
							rm_par.r10_sub_linea)
				RETURNING rm_grupo.r71_cod_grupo,
					  rm_grupo.r71_desc_grupo
			LET int_flag = 0
			IF rm_grupo.r71_cod_grupo IS NOT NULL THEN
				LET rm_par.r10_cod_grupo =
							rm_grupo.r71_cod_grupo
				LET rm_par.r71_desc_grupo =
							rm_grupo.r71_desc_grupo
				DISPLAY BY NAME rm_par.r10_cod_grupo,
						rm_grupo.r71_desc_grupo
			END IF
		END IF
		IF INFIELD(r10_cod_clase) THEN
			CALL fl_ayuda_clase_ventas_rep(vg_codcia,
							rm_par.r10_linea,
							rm_par.r10_sub_linea,
							rm_par.r10_cod_grupo)
				RETURNING rm_clase.r72_cod_clase,
					  rm_clase.r72_desc_clase
			LET int_flag = 0
			IF rm_clase.r72_cod_clase IS NOT NULL THEN
				LET rm_par.r10_cod_clase =
							rm_clase.r72_cod_clase
				LET rm_par.r72_desc_clase =
							rm_clase.r72_desc_clase
				DISPLAY BY NAME rm_par.r10_cod_clase,
						rm_clase.r72_desc_clase
			END IF
		END IF
		IF INFIELD(r10_marca) THEN
			CALL fl_ayuda_marcas_rep_asignadas(vg_codcia,
							rm_par.r10_marca)
				RETURNING r_r73.r73_marca
			LET int_flag = 0
			IF r_r73.r73_marca IS NOT NULL THEN
				LET rm_par.r10_marca      = r_r73.r73_marca
				LET rm_par.r73_desc_marca = r_r73.r73_desc_marca
				CALL fl_lee_marca_rep(vg_codcia,
							rm_par.r10_marca)
					RETURNING r_r73.*
				DISPLAY BY NAME rm_par.r10_marca,
						r_r73.r73_desc_marca
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD pend_falta
		LET p_fal = rm_par.pend_falta
	BEFORE FIELD pendientes
		LET pend = rm_par.pendientes
	AFTER FIELD r10_linea
		IF rm_par.r10_linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_par.r10_linea)
				RETURNING r_r03.*
			IF r_r03.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('División no existe.', 'exclamation')
				NEXT FIELD r10_linea
			END IF
			LET rm_par.r03_nombre = r_r03.r03_nombre
			DISPLAY BY NAME r_r03.r03_nombre
		ELSE
			LET rm_par.r03_nombre = NULL
			CLEAR r03_nombre
		END IF
	AFTER FIELD r10_sub_linea
		IF rm_par.r10_sub_linea IS NOT NULL THEN
			CALL fl_retorna_sublinea_rep(vg_codcia,
							rm_par.r10_sub_linea)
				RETURNING rm_sublin.*, flag
			IF flag = 0 THEN
				IF rm_sublin.r70_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Línea no existe.', 'exclamation')
					NEXT FIELD r10_sub_linea
				END IF
			END IF
			LET rm_par.r70_desc_sub = rm_sublin.r70_desc_sub
			DISPLAY BY NAME rm_sublin.r70_desc_sub
		ELSE
			LET rm_par.r70_desc_sub = NULL
			CLEAR r70_desc_sub
		END IF
	AFTER FIELD r10_cod_grupo
		IF rm_par.r10_cod_grupo IS NOT NULL THEN
			CALL fl_retorna_grupo_rep(vg_codcia,
							rm_par.r10_cod_grupo)
				RETURNING rm_grupo.*, flag
			IF flag = 0 THEN
				IF rm_grupo.r71_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
					NEXT FIELD r10_cod_grupo
				END IF
			END IF
			LET rm_par.r71_desc_grupo = rm_grupo.r71_desc_grupo
			DISPLAY BY NAME rm_grupo.r71_desc_grupo
		ELSE
			LET rm_par.r71_desc_grupo = NULL
			CLEAR r71_desc_grupo
		END IF
	AFTER FIELD r10_cod_clase
		IF rm_par.r10_cod_clase IS NOT NULL THEN
			CALL fl_retorna_clase_rep(vg_codcia,
							rm_par.r10_cod_clase)
				RETURNING rm_clase.*, flag
			IF flag = 0 THEN
				IF rm_clase.r72_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Clase no existe.', 'exclamation')
					NEXT FIELD r10_cod_clase
				END IF
			END IF
			LET rm_par.r72_desc_clase = rm_clase.r72_desc_clase
			DISPLAY BY NAME rm_clase.r72_desc_clase
		ELSE
			LET rm_par.r72_desc_clase = NULL
			CLEAR r72_desc_clase
		END IF
	AFTER FIELD r10_marca 
		IF rm_par.r10_marca IS NOT NULL THEN
			CALL fl_lee_marca_rep(vg_codcia, rm_par.r10_marca)
				RETURNING r_r73.*
			IF r_r73.r73_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Marca no existe.', 'exclamation')
				NEXT FIELD r10_marca
			END IF
			LET rm_par.r73_desc_marca = r_r73.r73_desc_marca
			DISPLAY BY NAME r_r73.r73_desc_marca
		ELSE
			LET rm_par.r73_desc_marca = NULL
			CLEAR r73_desc_marca
		END IF
	AFTER FIELD pend_falta
		IF vg_gui = 0 THEN
			IF rm_par.pend_falta IS NULL THEN
				LET rm_par.pend_falta = p_fal
				DISPLAY BY NAME rm_par.pend_falta
			END IF
		END IF
	AFTER FIELD pendientes
		IF vg_gui = 0 THEN
			IF rm_par.pendientes IS NULL THEN
				LET rm_par.pendientes = pend
				DISPLAY BY NAME rm_par.pendientes
			END IF
		END IF
	AFTER INPUT
		IF rm_par.r10_linea IS NULL THEN
			LET rm_par.r03_nombre = NULL
			DISPLAY BY NAME rm_par.r03_nombre
		END IF
		IF rm_par.r10_sub_linea IS NULL THEN
			LET rm_par.r70_desc_sub = NULL
			DISPLAY BY NAME rm_par.r70_desc_sub
		END IF
		IF rm_par.r10_cod_grupo IS NULL THEN
			LET rm_par.r71_desc_grupo = NULL
			DISPLAY BY NAME rm_par.r71_desc_grupo
		END IF
		IF rm_par.r10_cod_clase IS NULL THEN
			LET rm_par.r72_desc_clase = NULL
			DISPLAY BY NAME rm_par.r72_desc_clase
		END IF
		IF rm_par.r10_marca IS NULL THEN
			LET rm_par.r73_desc_marca = NULL
			DISPLAY BY NAME rm_par.r73_desc_marca
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE expr_sql		CHAR(400)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE bodega_p		LIKE rept002.r02_codigo
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE stock		LIKE rept011.r11_stock_act

INITIALIZE expr_sql, grupo_linea, bodega_p TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT expr_sql ON r10_codigo, r10_nombre, r10_stock_max,
				r10_stock_min
		FROM r10_codigo, r10_nombre, r10_stock_max, r10_stock_min
	       	ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
	       	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r10_codigo) THEN
				CALL fl_ayuda_maestro_items_stock(vg_codcia,
							grupo_linea, bodega_p)
					RETURNING r_r10.r10_codigo,
						r_r10.r10_nombre,
						r_r10.r10_linea,
						r_r10.r10_precio_mb,
						bodega, stock
				IF r_r10.r10_codigo IS NOT NULL THEN
					DISPLAY BY NAME r_r10.r10_codigo,
							r_r10.r10_nombre
				END IF 
			END IF
			LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
ELSE
	IF num_args() = 12 THEN
		LET expr_sql = ' r10_codigo = "', arg_val(12), '"'
	ELSE
		LET expr_sql = ' 1 = 1 '
	END IF
END IF
IF NOT int_flag THEN
	CALL ejecutar_carga_datos_temp(expr_sql)
END IF

END FUNCTION



FUNCTION ejecutar_carga_datos_temp(expr_sql)
DEFINE expr_sql		CHAR(400)
DEFINE cuantos		INTEGER
DEFINE query		CHAR(1200)
DEFINE expr_lin		VARCHAR(100)
DEFINE expr_sub		VARCHAR(100)
DEFINE expr_grp		VARCHAR(100)
DEFINE expr_cla		VARCHAR(100)
DEFINE expr_marca	VARCHAR(100)
DEFINE ex_outer		VARCHAR(10)
DEFINE stock_p		LIKE rept011.r11_stock_act

ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_lin = NULL
IF rm_par.r10_linea IS NOT NULL THEN
	LET expr_lin = "   AND r10_linea     = '", rm_par.r10_linea CLIPPED, "'"
END IF
LET expr_sub = NULL
IF rm_par.r10_sub_linea IS NOT NULL THEN
	LET expr_sub = "   AND r10_sub_linea = '", rm_par.r10_sub_linea CLIPPED,
						"'"
END IF
LET expr_grp = NULL
IF rm_par.r10_cod_grupo IS NOT NULL THEN
	LET expr_grp = "   AND r10_cod_grupo = '", rm_par.r10_cod_grupo CLIPPED,
						"'"
END IF
LET expr_cla = NULL
IF rm_par.r10_cod_clase IS NOT NULL THEN
	LET expr_cla = "   AND r10_cod_clase = '", rm_par.r10_cod_clase CLIPPED,
						"'"
END IF
LET expr_marca = NULL
IF rm_par.r10_marca IS NOT NULL THEN
	LET expr_marca = "   AND r10_marca     = '", rm_par.r10_marca CLIPPED,
						"'"
END IF
SELECT r10_sec_item r10_codigo, r10_nombre, r11_stock_act stock_pend,
	r11_stock_act stock_tot, r11_stock_act stock_loc, r10_stock_max,
	r10_stock_min
	FROM rept010, rept011
	WHERE r10_compania  = 17
	  AND r11_compania  = r10_compania
	  AND r11_item      = r10_codigo
	INTO TEMP t_item
SELECT r10_codigo item, stock_loc stock_l
	FROM t_item
	INTO TEMP t_item_loc
SELECT r02_compania, r02_codigo, r02_nombre, r02_localidad
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_tipo     <> "S"
	INTO TEMP t_bod
LET query = ' SELECT r10_codigo, r10_nombre, 0 stock_p1, 0 stock_t1, ',
			' 0 stock_l1, r10_stock_max, r10_stock_min ',
		' FROM rept010 ',
		' WHERE r10_compania   = ', vg_codcia,
	          expr_lin CLIPPED, 
	          expr_sub CLIPPED,  
	          expr_grp CLIPPED,  
	          expr_cla CLIPPED,
	          expr_marca CLIPPED,  
		'   AND ', expr_sql CLIPPED,
		' INTO TEMP t_r10 '
PREPARE pre_r10 FROM query
EXECUTE pre_r10
LET query = ' SELECT r11_compania, r11_bodega, r11_item, r11_stock_act ',
		' FROM rept011 ',
		' WHERE r11_compania  = ', vg_codcia,
		'   AND r11_bodega   IN (SELECT r02_codigo FROM t_bod) ',
		'   AND r11_item     IN (SELECT r10_codigo FROM t_r10) ',
		' INTO TEMP t_r11 '
PREPARE pre_r11 FROM query
EXECUTE pre_r11
SELECT r11_item r10_codigo, NVL(SUM(r11_stock_act), 0) stock_t
	FROM t_r11
	GROUP BY 1
	INTO TEMP t_item_tot
LET query = 'INSERT INTO t_item_loc ',
		' SELECT r11_item, NVL(SUM(r11_stock_act), 0) stock_l ',
			' FROM t_r11 ',
			' WHERE r11_bodega IN (SELECT r02_codigo FROM t_bod ',
						' WHERE ', vm_expr_loc CLIPPED,
							') ',
			' GROUP BY 1'
PREPARE cit_loc FROM query
EXECUTE cit_loc
SELECT r10_codigo item_tl, stock_t, NVL(stock_l, 0) stock_l
	FROM t_item_tot, OUTER t_item_loc
	WHERE r10_codigo = item
	INTO TEMP t_totloc
DROP TABLE t_item_tot
DROP TABLE t_item_loc
INSERT INTO t_item
	SELECT r10_codigo, r10_nombre, stock_p1, stock_t, stock_l,
			r10_stock_max, r10_stock_min
		FROM t_r10, t_totloc
		WHERE r10_codigo = item_tl
DROP TABLE t_r10
DROP TABLE t_totloc
SELECT COUNT(*) INTO cuantos FROM t_item
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	RETURN
END IF
LET vm_stock_pend = obtener_stock_pendiente()
LET ex_outer      = ' OUTER '
IF rm_par.pendientes = 'S' THEN
	IF NOT vm_stock_pend THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		DROP TABLE t_r11
		DROP TABLE t_bod
		DROP TABLE t_item
		LET vm_stock_pend = 0
		RETURN
	END IF
	LET ex_outer = NULL
END IF
IF vm_stock_pend THEN
	LET query = ' SELECT r10_codigo, r10_nombre, ',
				' NVL(SUM(cant_pend), 0) stock_pend, ',
				'stock_tot, stock_loc, r10_stock_max, ',
				'r10_stock_min ',
			' FROM t_item,', ex_outer CLIPPED, ' temp_pend',
			' WHERE r10_codigo = r20_item ',
			' GROUP BY 1, 2, 4, 5, 6, 7 ',
			' INTO TEMP temp_item'
	PREPARE pre_item FROM query
	EXECUTE pre_item
ELSE
	SELECT * FROM t_item INTO TEMP temp_item
END IF
DROP TABLE t_item
IF rm_par.pendientes = 'N' THEN
	SELECT NVL(SUM(stock_pend), 0) INTO stock_p FROM temp_item
	IF vm_stock_pend AND stock_p = 0 THEN
		DROP TABLE temp_pend
		LET vm_stock_pend = 0
	END IF
END IF
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION
 


FUNCTION control_consulta()
DEFINE i, col		SMALLINT
DEFINE query		CHAR(400)
DEFINE ver_item		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

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
LET col                    = 3
LET vm_columna_1           = col
LET vm_columna_2           = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_item ',
			' ORDER BY ',
				vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
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
	LET vm_num_rows = i - 1
	CALL mostrar_total_item()
	IF vg_gui = 0 THEN
		CALL muestra_etiquetas_det(1, vm_num_rows,rm_item[1].r10_codigo)
	END IF
	CALL set_count(vm_num_rows)
	LET int_flag = 0
	DISPLAY ARRAY rm_item TO rm_item.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			CALL muestra_etiquetas_det(i, vm_num_rows,
							rm_item[i].r10_codigo)
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1()
		ON KEY(F5)
			IF ver_item THEN
				LET i = arr_curr()
				CALL mostrar_item(i)
			END IF
		ON KEY(F6)
			IF vm_stock_pend THEN
				LET i = arr_curr()
				CALL ver_detalle_bodega(i, 'P')
				LET int_flag = 0
			END IF
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_detalle_bodega(i, 'T')
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_detalle_bodega(i, 'L')
			LET int_flag = 0
		ON KEY(F9)
			CALL control_imprimir()
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
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL muestra_etiquetas_det(i, vm_num_rows,
						--#rm_item[i].r10_codigo)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('RETURN', '')
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF NOT vm_stock_pend THEN
				--#CALL dialog.keysetlabel("F6","")
			--#ELSE
				--#CALL dialog.keysetlabel("F6","Stock Pendiente")
			--#END IF
			--#IF NOT ver_item THEN
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
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
CLEAR descri_item, descri_clase, num_row, max_row, tot_stock_pend,
	tot_stock_total, tot_stock_local

END FUNCTION



FUNCTION mostrar_item(i)
DEFINE i		SMALLINT
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

{- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE -}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
LET comando = run_prog, 'repp108 ', vg_base, ' RE ', vg_codcia, ' ', vg_codloc, ' "', rm_item[i].r10_codigo CLIPPED, '"'
RUN comando

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_etiquetas_det(num_row, max_row, item)
DEFINE num_row, max_row	SMALLINT
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL muestra_contadores_det(num_row, max_row)
CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
	RETURNING r_r72.*
DISPLAY r_r72.r72_desc_clase TO descri_clase
DISPLAY r_r10.r10_nombre     TO descri_item

END FUNCTION



FUNCTION mostrar_total_item()
DEFINE tot_stock_pend	DECIMAL(10,2)
DEFINE tot_stock_total	DECIMAL(10,2)
DEFINE tot_stock_local	DECIMAL(10,2)
DEFINE i		SMALLINT

LET tot_stock_pend  = 0
LET tot_stock_total = 0
LET tot_stock_local = 0
FOR i = 1 TO vm_num_rows
	LET tot_stock_pend  = tot_stock_pend  + rm_item[i].stock_pend
	LET tot_stock_total = tot_stock_total + rm_item[i].stock_total
	LET tot_stock_local = tot_stock_local + rm_item[i].stock_local
END FOR
DISPLAY BY NAME tot_stock_pend, tot_stock_total, tot_stock_local

END FUNCTION



FUNCTION obtener_stock_pendiente()
DEFINE cuantos		INTEGER
DEFINE query		CHAR(800)
DEFINE expr_ssto	CHAR(100)
define ccc		like rept020.r20_cant_ven

LET expr_ssto = NULL
IF rm_par.pend_falta = 'S' THEN
	LET expr_ssto = '   AND r02_tipo      = "S" '
END IF
LET query = 'SELECT r02_codigo FROM rept002 ',
		' WHERE r02_compania  = ', vg_codcia,
		'   AND r02_localidad = ', vg_codloc,
		'   AND r02_factura   = "S" ',
		expr_ssto CLIPPED,
		' INTO TEMP t_bd1 '
PREPARE cons_bod FROM query
EXECUTE cons_bod
SELECT r20_cod_tran, r20_num_tran, DATE(r20_fecing) fecha, r20_bodega, r20_item,
		r20_cant_ven
	FROM rept020
	WHERE r20_compania   = vg_codcia
	  AND r20_localidad  = vg_codloc
	  AND r20_cod_tran  IN ("FA", "DF")
	  AND r20_bodega    IN (SELECT r02_codigo FROM t_bd1)
	  AND r20_item      IN (SELECT r10_codigo FROM t_item)
	INTO TEMP t_r20
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
	WHERE d.r19_cod_tran = c.r20_cod_tran
	  AND d.r19_num_tran = c.r20_num_tran
	  AND c.r20_cod_tran = "FA"
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
DROP TABLE t_bd1
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
SELECT UNIQUE r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cantidad cant_pend, r19_nomcli
	FROM t2, t3
	WHERE r20_bodega      = bodega
	  AND r20_item        = item
	  AND r35_num_ord_des = r34_num_ord_des
	INTO TEMP temp_pend
DROP TABLE t2
DROP TABLE t3
SELECT COUNT(*) INTO cuantos FROM temp_pend
IF cuantos = 0 THEN
	DROP TABLE temp_pend
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION ver_detalle_bodega(posicion, flag)
DEFINE posicion		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_item_pend	ARRAY[100] OF RECORD
				r02_codigo	LIKE rept002.r02_codigo, 
				r02_nombre	LIKE rept002.r02_nombre, 
				stock_var	LIKE rept011.r11_stock_act
			END RECORD
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE tot_stock_var	LIKE rept011.r11_stock_act
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(800)
DEFINE expr_whe		CHAR(300)
DEFINE max_bod		SMALLINT
DEFINE col_ini		SMALLINT
DEFINE col_fin		SMALLINT
DEFINE nomostrar	SMALLINT
DEFINE r_orden	 	ARRAY[6] OF CHAR(4)
DEFINE v_columna_1	SMALLINT
DEFINE v_columna_2	SMALLINT

LET col_ini = 18
LET col_fin = 48
IF vg_gui = 0 THEN
	LET col_ini = 17
	LET col_fin = 49
END IF
OPEN WINDOW w_repf318_2 AT 07, col_ini WITH 15 ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf318_2 FROM '../forms/repf318_2'
ELSE
	OPEN FORM f_repf318_2 FROM '../forms/repf318_2c'
END IF
DISPLAY FORM f_repf318_2
LET max_bod = 100
DISPLAY BY NAME rm_item[posicion].r10_codigo, rm_item[posicion].r10_nombre
--#DISPLAY 'BD' 	TO tit_col1
--#DISPLAY 'Nombre'  	TO tit_col2
LET i = 1
CASE flag
	WHEN 'P'
		DISPLAY 'STOCK PENDIENTE POR BODEGA' TO tit_principal
		--#DISPLAY 'Stock Pend.'	TO tit_col3
		IF rm_item[posicion].stock_pend = 0 THEN
			LET i = 0
		END IF
	WHEN 'T'
		DISPLAY '* STOCK TOTAL POR BODEGA *' TO tit_principal
		--#DISPLAY 'Stock Total'	TO tit_col3
		IF rm_item[posicion].stock_total = 0 THEN
			LET i = 0
		END IF
	WHEN 'L'
		DISPLAY '* STOCK LOCAL POR BODEGA *' TO tit_principal
		--#DISPLAY 'Stock Local'	TO tit_col3
		IF rm_item[posicion].stock_local = 0 THEN
			LET i = 0
		END IF
END CASE
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 0
	CLOSE WINDOW w_repf318_2
	RETURN
END IF
FOR i = 1 TO 6
	LET r_orden[i] = '' 
END FOR
LET col                  = 3
LET v_columna_1          = col
LET v_columna_2          = 1
LET r_orden[v_columna_1] = 'DESC'
LET r_orden[v_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT r02_codigo, r02_nombre, NVL(r11_stock_act, 0) ',
			' FROM t_bod, t_r11 ',
			' WHERE r02_compania  = ', vg_codcia
	LET expr_whe =  '   AND r11_compania  = r02_compania ',
        	        '   AND r11_bodega    = r02_codigo ',
			'   AND r11_item      = ', rm_item[posicion].r10_codigo,
	                ' ORDER BY ', v_columna_1, ' ', r_orden[v_columna_1],
				', ', v_columna_2, ' ', r_orden[v_columna_2] 
	CASE flag
		WHEN 'P'
			LET query = 'SELECT r20_bodega, r02_nombre, ',
						'NVL(SUM(cant_pend), 0) ',
					' FROM temp_pend, rept002 ',
					' WHERE r20_item     = ',
						rm_item[posicion].r10_codigo,
					'   AND r02_compania = ', vg_codcia,
					'   AND r02_codigo   = r20_bodega ',
					' GROUP BY 1, 2 ',
			                ' ORDER BY ', v_columna_1, ' ',
							r_orden[v_columna_1],
						', ', v_columna_2, ' ',
							r_orden[v_columna_2] 
		WHEN 'T'
			LET query = query CLIPPED, expr_whe CLIPPED
		WHEN 'L'
			LET query = query CLIPPED,
					'   AND ', vm_expr_loc CLIPPED,
					expr_whe CLIPPED
	END CASE
	PREPARE cons_bod_exis FROM query
	DECLARE q_exist CURSOR FOR cons_bod_exis
	LET i             = 1
	LET tot_stock_var = 0
	FOREACH q_exist INTO r_item_pend[i].*
		LET tot_stock_var = tot_stock_var + r_item_pend[i].stock_var
		LET i = i + 1
		IF i > max_bod THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	DISPLAY BY NAME tot_stock_var
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, i)
	END IF
	LET int_flag = 0
	CALL set_count(i)
	DISPLAY ARRAY r_item_pend TO r_item_pend.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET j = arr_curr()
			CALL muestra_contadores_det(j, i)
       		ON KEY(F1,CONTROL-W)
			IF flag = 'P' THEN
				CALL control_visor_teclas_caracter_2()
			ELSE
				CALL control_visor_teclas_caracter_4()
			END IF
		ON KEY(F5)
			IF flag = 'P' THEN
				LET j = arr_curr()
				CALL control_facturas(r_item_pend[j].r02_codigo,
						rm_item[posicion].r10_codigo)
				LET int_flag = 0
			END IF
		ON KEY(F6)
			LET j = arr_curr()
			CALL fl_lee_bodega_rep(vg_codcia,
						r_item_pend[j].r02_codigo)
				RETURNING r_r02.*
			LET nomostrar = 1
			IF flag = 'P' AND r_r02.r02_tipo <> 'S' THEN
				LET nomostrar = 0
			END IF
			IF r_r02.r02_localidad = vg_codloc AND nomostrar THEN
				CALL control_movimientos(
						r_item_pend[j].r02_codigo,
						rm_item[posicion].r10_codigo,
						r_item_pend[j].stock_var)
				LET int_flag = 0
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
			--#CALL dialog.keysetlabel('RETURN', '')
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#IF flag = 'P' THEN
				--#CALL dialog.keysetlabel("F5","Facturas")
			--#ELSE
				--#CALL dialog.keysetlabel("F5","")
			--#END IF
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#CALL muestra_contadores_det(j, i)
			--#CALL fl_lee_bodega_rep(vg_codcia,
						--#r_item_pend[j].r02_codigo)
				--#RETURNING r_r02.*
			--#LET nomostrar = 1
			--#IF flag = 'P' AND r_r02.r02_tipo <> 'S' THEN
				--#LET nomostrar = 0
			--#END IF
			--#IF r_r02.r02_localidad = vg_codloc AND nomostrar THEN
				--#CALL dialog.keysetlabel("F6","Movimientos")
			--#ELSE
				--#CALL dialog.keysetlabel("F6","")
			--#END IF
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> v_columna_1 THEN
		LET v_columna_2          = v_columna_1 
		LET r_orden[v_columna_2] = r_orden[v_columna_1]
		LET v_columna_1          = col 
	END IF
	IF r_orden[v_columna_1] = 'ASC' THEN
		LET r_orden[v_columna_1] = 'DESC'
	ELSE
		LET r_orden[v_columna_1] = 'ASC'
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf318_2
RETURN

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_items TO PIPE comando
FOR i = 1 TO vm_num_rows
	OUTPUT TO REPORT reporte_items(i)
END FOR
FINISH REPORT reporte_items

END FUNCTION



REPORT reporte_items(i)
DEFINE i		SMALLINT
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_factura	ARRAY[800] OF RECORD
				bodega		LIKE rept002.r02_codigo,
				r19_cod_tran	LIKE rept019.r19_cod_tran, 
				r19_num_tran	LIKE rept019.r19_num_tran, 
				r19_nomcli	LIKE rept019.r19_nomcli, 
				r19_fecing	DATE,
				r34_num_ord_des	LIKE rept034.r34_num_ord_des,
				stock_pend	LIKE rept011.r11_stock_act
			END RECORD
DEFINE j, max_fac	SMALLINT
DEFINE query		CHAR(800)
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
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
	LET max_fac     = 800
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
	      COLUMN 029, "DETALLE DE ITEMS PENDIENTES",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.r10_linea IS NOT NULL THEN
		PRINT COLUMN 005, "** DIVISION: ",
		      COLUMN 025, rm_par.r10_linea CLIPPED,
		      COLUMN 027, rm_par.r03_nombre CLIPPED;
	ELSE
		PRINT 1 SPACES;
	END IF
	IF rm_par.pend_falta = 'S' THEN
		IF rm_par.r10_linea IS NOT NULL THEN
			PRINT COLUMN 059, "PENDIENTES FALTA STOCK"
		ELSE
			PRINT COLUMN 028, "PENDIENTES FALTA STOCK"
		END IF
	ELSE
		PRINT COLUMN 059, 1 SPACES
	END IF
	IF rm_par.r10_sub_linea IS NOT NULL THEN
		PRINT COLUMN 005, "** LINEA   : ",
		      COLUMN 024, rm_par.r10_sub_linea CLIPPED,
		      COLUMN 027, rm_par.r70_desc_sub CLIPPED;
	ELSE
		PRINT 1 SPACES;
	END IF
	IF rm_par.pendientes = 'S' THEN
		IF rm_par.r10_linea IS NOT NULL OR
		   rm_par.r10_sub_linea IS NOT NULL
		THEN
			PRINT COLUMN 066, "SOLO PENDIENTES"
		ELSE
			IF rm_par.pend_falta = 'S' THEN
				PRINT COLUMN 031, "SOLO  PENDIENTES"
			ELSE
				PRINT COLUMN 033, "SOLO PENDIENTES"
			END IF
		END IF
	ELSE
		PRINT COLUMN 066, 1 SPACES
	END IF
	IF rm_par.r10_cod_grupo IS NOT NULL THEN
		PRINT COLUMN 005, "** GRUPO   : ",
		      COLUMN 022, fl_justifica_titulo('D',
						rm_par.r10_cod_grupo, 4),
		      COLUMN 027, rm_par.r71_desc_grupo
	ELSE
		PRINT 1 SPACES
	END IF
	IF rm_par.r10_cod_clase IS NOT NULL THEN
		PRINT COLUMN 005, "** CLASE   : ",
		      COLUMN 018, fl_justifica_titulo('D',
						rm_par.r10_cod_clase, 8),
		      COLUMN 027, rm_par.r72_desc_clase
	ELSE
		PRINT 1 SPACES
	END IF
	IF rm_par.r10_marca IS NOT NULL THEN
		PRINT COLUMN 005, "** MARCA   : ",
		      COLUMN 020, fl_justifica_titulo('D', rm_par.r10_marca, 6),
		      COLUMN 027, rm_par.r73_desc_marca
	ELSE
		PRINT 1 SPACES
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "ITEM",
	      COLUMN 009, "D E S C R I P C I O N",
	      COLUMN 033, "STOCK PEN.",
	      COLUMN 044, "STOCK TOTAL",
	      COLUMN 056, "STOCK LOCAL",
	      COLUMN 068, "MAXIMO",
	      COLUMN 075, "MINIMO"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 5 LINES
	PRINT COLUMN 001, rm_item[i].r10_codigo		USING "######",
	      COLUMN 008, rm_item[i].r10_nombre[1, 24],
	      COLUMN 033, rm_item[i].stock_pend		USING "###,##&.##",
	      COLUMN 044, rm_item[i].stock_total	USING "####,##&.##",
	      COLUMN 056, rm_item[i].stock_local	USING "####,##&.##",
	      COLUMN 068, rm_item[i].r10_stock_max	USING "#####&",
	      COLUMN 075, rm_item[i].r10_stock_min	USING "#####&"
	LET query = 'SELECT UNIQUE r20_bodega, r20_cod_tran, r20_num_tran, ',
				'r19_nomcli, fecha, r35_num_ord_des, cant_pend',
			' FROM temp_pend ',
			' WHERE r20_item = "', rm_item[i].r10_codigo, '"',
	                ' ORDER BY 1 ASC, 5 ASC, 1, 2, 3, 6 '
	PREPARE cons_fac_r FROM query
	DECLARE q_fact_r CURSOR FOR cons_fac_r
	LET j = 1
	FOREACH q_fact_r INTO r_factura[j].*
		PRINT COLUMN 004, r_factura[j].bodega,
		      COLUMN 007, r_factura[j].r19_cod_tran,
		      COLUMN 010, r_factura[j].r19_num_tran	USING "<<<<<<&",
		      COLUMN 018, r_factura[j].r19_nomcli[1, 30],
		      COLUMN 049, r_factura[j].r19_fecing	USING "dd-mm-yyyy",
		      COLUMN 060, r_factura[j].r34_num_ord_des	USING "<<<<<<&",
		      COLUMN 069, r_factura[j].stock_pend	USING "###,##&.##"
		LET j = j + 1
		IF j > max_fac THEN
			EXIT FOREACH
		END IF
	END FOREACH
	SKIP 1 LINES
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 035, "----------",
	      COLUMN 046, "-----------",
	      COLUMN 058, "-----------"
	PRINT COLUMN 020, "TOTALES ==>  ",
	      COLUMN 033, SUM(rm_item[i].stock_pend)	USING "###,##&.##",
	      COLUMN 044, SUM(rm_item[i].stock_total)	USING "####,##&.##",
	      COLUMN 056, SUM(rm_item[i].stock_local)	USING "####,##&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION control_facturas(bodega, item)
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_factura	ARRAY[800] OF RECORD
				r19_cod_tran	LIKE rept019.r19_cod_tran, 
				r19_num_tran	LIKE rept019.r19_num_tran, 
				r19_nomcli	LIKE rept019.r19_nomcli, 
				r19_fecing	DATE,
				r34_num_ord_des	LIKE rept034.r34_num_ord_des,
				stock_pend	LIKE rept011.r11_stock_act
			END RECORD
DEFINE tot_stock_pend	LIKE rept011.r11_stock_act
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j, col	SMALLINT
DEFINE max_fac		SMALLINT
DEFINE col_ini		SMALLINT
DEFINE col_fin		SMALLINT
DEFINE query		CHAR(800)
DEFINE r_orden	 	ARRAY[6] OF CHAR(4)
DEFINE v_columna_1	SMALLINT
DEFINE v_columna_2	SMALLINT

LET col_ini = 04
LET col_fin = 74
IF vg_gui = 0 THEN
	LET col_ini = 03
	LET col_fin = 75
END IF
OPEN WINDOW w_repf318_3 AT 05, col_ini WITH 18 ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf318_3 FROM '../forms/repf318_3'
ELSE
	OPEN FORM f_repf318_3 FROM '../forms/repf318_3c'
END IF
DISPLAY FORM f_repf318_3
CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_r02.*
CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
DISPLAY BY NAME r_r02.r02_codigo, r_r02.r02_nombre, r_r10.r10_codigo,
		r_r10.r10_nombre
LET max_fac = 800
--#DISPLAY 'TP' 	TO tit_col1
--#DISPLAY 'Numero'  	TO tit_col2
--#DISPLAY 'Cliente'	TO tit_col3
--#DISPLAY 'Fecha Fact'	TO tit_col4
--#DISPLAY 'Ord. Desp.'	TO tit_col5
--#DISPLAY 'Cant. Pend'	TO tit_col6
FOR i = 1 TO 6
	LET r_orden[i] = '' 
END FOR
LET col                  = 3
LET v_columna_1          = col
LET v_columna_2          = 4
LET r_orden[v_columna_1] = 'DESC'
LET r_orden[v_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT UNIQUE r20_cod_tran, r20_num_tran, r19_nomcli,',
				' fecha, r35_num_ord_des, cant_pend ',
			' FROM temp_pend ',
			' WHERE r20_bodega = "', bodega, '"',
			'   AND r20_item   = "', item, '"',
	                ' ORDER BY ', v_columna_1, ' ', r_orden[v_columna_1],
				', ', v_columna_2, ' ', r_orden[v_columna_2] 
	PREPARE cons_fac FROM query
	DECLARE q_fact CURSOR FOR cons_fac
	LET i              = 1
	LET tot_stock_pend = 0
	FOREACH q_fact INTO r_factura[i].*
		LET tot_stock_pend = tot_stock_pend + r_factura[i].stock_pend
		LET i = i + 1
		IF i > max_fac THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	DISPLAY BY NAME tot_stock_pend
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, i)
		DISPLAY r_factura[1].r19_nomcli TO nombre_cli
	END IF
	LET int_flag = 0
	CALL set_count(i)
	DISPLAY ARRAY r_factura TO r_factura.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET j = arr_curr()
			CALL muestra_contadores_det(j, i)
			DISPLAY r_factura[j].r19_nomcli TO nombre_cli
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_3()
		ON KEY(F5)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						r_factura[j].r19_cod_tran,
						r_factura[j].r19_num_tran)
			LET int_flag = 0
		ON KEY(F6)
			LET j = arr_curr()
			CALL llamar_orden_despacho(r_factura[j].r19_cod_tran,
						r_factura[j].r19_num_tran,
						bodega,
						r_factura[j].r34_num_ord_des)
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('RETURN', '')
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#CALL muestra_contadores_det(j, i)
			--#DISPLAY r_factura[j].r19_nomcli TO nombre_cli
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> v_columna_1 THEN
		LET v_columna_2          = v_columna_1 
		LET r_orden[v_columna_2] = r_orden[v_columna_1]
		LET v_columna_1          = col 
	END IF
	IF r_orden[v_columna_1] = 'ASC' THEN
		LET r_orden[v_columna_1] = 'DESC'
	ELSE
		LET r_orden[v_columna_1] = 'ASC'
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf318_3
RETURN

END FUNCTION


 
FUNCTION control_movimientos(bodega, item, stock_var)
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE item		LIKE rept010.r10_codigo
DEFINE stock_var	LIKE rept011.r11_stock_act
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE col_ini		SMALLINT
DEFINE col_fin		SMALLINT
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fec_ini, fec_fin	DATE
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET col_ini = 15
LET col_fin = 54
IF vg_gui = 0 THEN
	LET col_ini = 14
	LET col_fin = 54
END IF
OPEN WINDOW w_repf318_4 AT 06, col_ini WITH 13 ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf318_4 FROM '../forms/repf318_4'
ELSE
	OPEN FORM f_repf318_4 FROM '../forms/repf318_4c'
END IF
DISPLAY FORM f_repf318_4
CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_r02.*
CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
DISPLAY BY NAME r_r02.r02_codigo, r_r02.r02_nombre, r_r10.r10_codigo,
		r_r10.r10_nombre, stock_var
LET fecha_fin = TODAY
LET fecha_ini = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
WHILE TRUE
	LET int_flag = 0
	INPUT BY NAME fecha_ini, fecha_fin
		WITHOUT DEFAULTS
	        ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT INPUT
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE FIELD fecha_ini
			LET fec_ini = fecha_ini
		BEFORE FIELD fecha_fin
			LET fec_fin = fecha_fin
		AFTER FIELD fecha_ini
			IF fecha_ini IS NOT NULL THEN
				IF fecha_ini > TODAY THEN
					CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la fecha de hoy.', 'exclamation')
					NEXT FIELD fecha_ini
				END IF
			ELSE
				LET fecha_ini = fec_ini
				DISPLAY BY NAME fecha_ini
			END IF
		AFTER FIELD fecha_fin
			IF fecha_fin IS NOT NULL THEN
				IF fecha_fin > TODAY THEN
					CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor que la fecha de hoy.', 'exclamation')
					NEXT FIELD fecha_fin
				END IF
			ELSE
				LET fecha_fin = fec_fin
				DISPLAY BY NAME fecha_fin
			END IF
		AFTER INPUT
			IF fecha_ini > fecha_fin THEN
				CALL fl_mostrar_mensaje('La Fecha Final no puede ser menor que la Fecha Inicial.', 'exclamation')
				NEXT FIELD fecha_fin
			END IF
	END INPUT
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET run_prog = '; fglrun '
	IF vg_gui = 0 THEN
		LET run_prog = '; fglgo '
	END IF
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
			vg_separador, 'fuentes', vg_separador, run_prog,
			'repp307 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
			' ', vg_codloc, ' "', bodega, '" "', item CLIPPED,
			'" "', fecha_ini, '" "', fecha_fin, '"'
	RUN comando
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf318_4
RETURN

END FUNCTION


 
FUNCTION llamar_orden_despacho(cod_tran, num_tran, bodega, num_orden)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE num_orden	LIKE rept034.r34_num_ord_des
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp231 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' "', cod_tran, '" ',
	num_tran, ' "C" "P" "', bodega, '" ', num_orden
RUN comando

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
DISPLAY '<F6>      Stock Pendiente'          AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Stock Total'              AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Stock Local'              AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F9>      Imprimir'                 AT a,2
DISPLAY  'F9' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Facturas'             AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Ver Movimientos'          AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_3() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Factura'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Orden Despacho Pend.'     AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_4() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F6>      Ver Movimientos'          AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

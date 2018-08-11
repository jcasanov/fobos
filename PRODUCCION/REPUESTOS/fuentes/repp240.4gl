------------------------------------------------------------------------------
-- Titulo           : repp240.4gl - Control Pedido a Proveedores Locales
-- Elaboracion      : 12-Nov-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp240 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_pedido 	ARRAY[1000] OF RECORD
				r93_item	LIKE rept093.r93_item,
				r93_cod_pedido	LIKE rept093.r93_cod_pedido,
				r10_nombre	LIKE rept010.r10_nombre,
				r93_stock_max	LIKE rept093.r93_stock_max,
				r93_stock_min	LIKE rept093.r93_stock_min,
				r93_stock_act	LIKE rept093.r93_stock_act,
				r93_cantpend	LIKE rept093.r93_cantpend,
				r93_cantpedir	LIKE rept093.r93_cantpedir
			END RECORD
DEFINE vm_num_det	INTEGER
DEFINE vm_max_det	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp240.err')
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
LET vg_proceso = 'repp240'
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
OPEN WINDOW w_imp AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cons FROM '../forms/repf240_1'
ELSE
	OPEN FORM f_cons FROM '../forms/repf240_1c'
END IF
DISPLAY FORM f_cons
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No está creada una compañía para el módulo de inventarios.','stop')
	RETURN
END IF
LET vm_max_det = 1000
CALL mostrar_botones_det()
--#LET vm_size_arr = fgl_scr_size('rm_pedido')
IF vg_gui = 0 THEN
	LET vm_size_arr = 10
END IF
CALL control_proceso()

END FUNCTION



FUNCTION control_proceso()

WHILE TRUE
	CALL muestra_contadores_det(0, 0)
	LET vm_num_det = 1
	CALL borrar_detalle()
	CALL lee_detalle()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL grabar_detalle()
END WHILE

END FUNCTION



FUNCTION lee_detalle()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE cantpedir	LIKE rept093.r93_cantpedir
DEFINE i, j		SMALLINT  
DEFINE resp		CHAR(6) 
DEFINE max_row		SMALLINT

OPTIONS INSERT KEY F30
WHILE TRUE
	INITIALIZE r_r21.* TO NULL
	CALL set_count(vm_num_det)
	LET int_flag = 0
	INPUT ARRAY rm_pedido WITHOUT DEFAULTS FROM rm_pedido.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT       
			END IF                  
		ON KEY(F1,CONTROL-W)           
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F2)          
			IF INFIELD(r93_item) THEN
				CALL fl_ayuda_maestro_items_stock(vg_codcia,
							r_r21.r21_grupo_linea,
							rm_r00.r00_bodega_fact)
					RETURNING r_r10.r10_codigo,
						  r_r10.r10_nombre,
						  r_r10.r10_linea,
						  r_r10.r10_precio_mb,
						  r_r11.r11_bodega,
						  r_r11.r11_stock_act
				IF r_r10.r10_codigo IS NOT NULL THEN     
					LET rm_pedido[i].r93_item =
								r_r10.r10_codigo
					DISPLAY rm_pedido[i].r93_item TO
						rm_pedido[j].r93_item 
				END IF
			END IF
			LET int_flag = 0
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_item(rm_pedido[i].r93_item)
			LET int_flag = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel('INSERT','')
		BEFORE INSERT
			IF max_row > vm_max_det THEN
				CALL fl_mostrar_mensaje('La lista esta llena, por favor GUARDE los datos ahora y continue ingresando los demas Items.', 'info')
				LET int_flag = 2
				LET max_row  = max_row - 1
				EXIT INPUT
			END IF
		BEFORE ROW
			LET i       = arr_curr()
			LET j       = scr_line()
			LET max_row = arr_count()
			IF i > max_row THEN
				LET max_row = max_row + 1
			END IF
			IF rm_pedido[i].r93_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia,
							rm_pedido[i].r93_item)
					RETURNING r_r10.*
				CALL cargar_datos_item(i, j)
				CALL muestra_etiquetas_det(i, max_row, i)
			ELSE
				CLEAR nom_item, descrip_1, descrip_2, descrip_3,
					descrip_4, nom_marca
			END IF
		BEFORE FIELD r93_cantpedir
			LET cantpedir = rm_pedido[i].r93_cantpedir
		AFTER FIELD r93_item
			IF rm_pedido[i].r93_item IS NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_item(vg_codcia, rm_pedido[i].r93_item)
				RETURNING r_r10.*            
			IF r_r10.r10_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('El item no existe.', 'exclamation')
				NEXT FIELD r93_item
			END IF
			CALL cargar_datos_item(i, j)
			CALL muestra_etiquetas_det(i, max_row, i)
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r93_item
			END IF
			IF r_r10.r10_cod_pedido IS NULL THEN
				CALL fl_mostrar_mensaje('El item no tiene Código de Pedido.', 'exclamation')
				NEXT FIELD r93_item
			END IF
			IF r_r10.r10_stock_max IS NULL THEN
				CALL fl_mostrar_mensaje('El item no tiene Stock Maximo.', 'exclamation')
				NEXT FIELD r93_item
			END IF
			IF r_r10.r10_stock_min IS NULL THEN
				CALL fl_mostrar_mensaje('El item no tiene Stock Mínimo.', 'exclamation')
				NEXT FIELD r93_item
			END IF
			{--
			IF r_r10.r10_stock_max = 0 AND r_r10.r10_stock_min = 0
			THEN
				CALL fl_mostrar_mensaje('El item tiene Stock Maximo y Mínimo de Cero, no tiene Rango de Stock para hacer el Pedido.', 'exclamation')
				NEXT FIELD r93_item
			END IF
			--}
			IF item_repetido(i, max_row) THEN
				CALL fl_mostrar_mensaje('Este Item ya esta ingresado en la lista.', 'exclamation')
				NEXT FIELD r93_item
			END IF
			CALL calcula_totales(max_row)
		AFTER FIELD r93_cantpedir
			IF rm_pedido[i].r93_item IS NULL THEN
				CALL fl_mostrar_mensaje('Digite item primero.', 'exclamation')
				LET rm_pedido[i].r93_cantpedir = NULL
				DISPLAY rm_pedido[i].r93_cantpedir TO
					rm_pedido[j].r93_cantpedir
				NEXT FIELD r93_item
			END IF
			IF rm_pedido[i].r93_cantpedir IS NULL THEN
				LET rm_pedido[i].r93_cantpedir = cantpedir
				DISPLAY rm_pedido[i].r93_cantpedir TO
					rm_pedido[j].r93_cantpedir
			END IF
			{--
			IF rm_pedido[i].r93_cantpedir >
			   rm_pedido[i].r93_stock_max
			THEN
				CALL fl_mostrar_mensaje('La Cantidad a Pedir no puede ser mayor que el Stock Maximo.', 'exclamation')
				NEXT FIELD r93_cantpedir
			END IF
			IF rm_pedido[i].r93_cantpedir <
			   rm_pedido[i].r93_stock_min
			THEN
				CALL fl_mostrar_mensaje('La Cantidad a Pedir no puede ser menor que el Stock Mínimo.', 'exclamation')
				NEXT FIELD r93_cantpedir
			END IF
			--}
			CALL calcula_totales(max_row)
		AFTER DELETE
			LET max_row = arr_count()
			CALL calcula_totales(max_row)
			IF i - 1 = max_row THEN
				LET int_flag = 2
				EXIT INPUT
			END IF
		AFTER INPUT
			LET max_row = arr_count()
			CALL calcula_totales(max_row)
	END INPUT 
	LET vm_num_det = max_row
	IF int_flag <> 2 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION  



FUNCTION grabar_detalle()
DEFINE i		SMALLINT
DEFINE r_r93		RECORD LIKE rept093.*

DEFINE fecha_actual DATETIME YEAR TO SECOND

BEGIN WORK
FOR i = 1 TO vm_num_det
	INITIALIZE r_r93.* TO NULL
	DECLARE q_r93 CURSOR FOR
		SELECT * FROM rept093
			WHERE r93_compania  = vg_codcia
			  AND r93_item      = rm_pedido[i].r93_item
			  AND r93_cantpedir = rm_pedido[i].r93_cantpedir
	OPEN q_r93
	FETCH q_r93 INTO r_r93.*
	IF r_r93.r93_compania IS NOT NULL THEN
		CLOSE q_r93
		FREE q_r93
		CONTINUE FOR
	END IF
	CLOSE q_r93
	FREE q_r93
	IF NOT actualizar_cantback_maestro_item(i) THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	DELETE FROM rept093
		WHERE r93_compania = vg_codcia
		  AND r93_item     = rm_pedido[i].r93_item
	LET rm_pedido[i].r93_cantpend = rm_pedido[i].r93_cantpend +
					rm_pedido[i].r93_cantpedir
    LET fecha_actual = fl_current()
	INSERT INTO rept093
		VALUES(vg_codcia, rm_pedido[i].r93_item,
			rm_pedido[i].r93_cod_pedido, rm_pedido[i].r93_stock_max,
			rm_pedido[i].r93_stock_min, rm_pedido[i].r93_stock_act,
			rm_pedido[i].r93_cantpend, rm_pedido[i].r93_cantpedir,
			vg_usuario, fecha_actual)
END FOR
COMMIT WORK
CALL fl_mostrar_mensaje('Proceso Terminado OK.', 'info')

END FUNCTION  



FUNCTION actualizar_cantback_maestro_item(i)
DEFINE i, intentar	SMALLINT
DEFINE salir 		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

LET intentar = 1
LET salir    = 0
WHENEVER ERROR CONTINUE
WHILE (intentar)
	INITIALIZE r_r10.* TO NULL
	DECLARE q_r10 CURSOR FOR
		SELECT * FROM rept010
			WHERE r10_compania = vg_codcia
			  AND r10_codigo   = rm_pedido[i].r93_item
		FOR UPDATE
	OPEN q_r10
	FETCH q_r10 INTO r_r10.*
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar(i)
	ELSE
		LET intentar = 0
		LET salir    = 1
	END IF
	IF r_r10.r10_compania IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Ocurrió un ERROR de Integridad con el Item ' || rm_pedido[i].r93_item CLIPPED || '. Por favor llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
END WHILE
WHENEVER ERROR STOP
IF NOT intentar AND NOT salir THEN
	RETURN salir
END IF
UPDATE rept010 SET r10_cantback = r10_cantback + rm_pedido[i].r93_cantpedir
	WHERE CURRENT OF q_r10 
CLOSE q_r10
FREE q_r10
RETURN salir

END FUNCTION



FUNCTION mostrar_botones_det()

--#DISPLAY 'Item'		TO tit_col1
--#DISPLAY 'Código Pedido'	TO tit_col2
--#DISPLAY 'Descrip.'		TO tit_col3
--#DISPLAY 'MAX'		TO tit_col4
--#DISPLAY 'MIN'		TO tit_col5
--#DISPLAY 'Act Loc'		TO tit_col6
--#DISPLAY 'Pend.'		TO tit_col7
--#DISPLAY 'Pedir'		TO tit_col8

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_size_arr 
	CLEAR rm_pedido[i].*
END FOR
FOR i = 1 TO vm_max_det 
	INITIALIZE rm_pedido[i].* TO NULL
END FOR
CLEAR total_pedir

END FUNCTION



FUNCTION item_repetido(i, lim)
DEFINE i, lim		SMALLINT
DEFINE j, encontro	SMALLINT

LET encontro = 0
FOR j = 1 TO lim
	IF j = i THEN
		CONTINUE FOR
	END IF
	IF rm_pedido[i].r93_item = rm_pedido[j].r93_item THEN
		LET encontro = 1
		EXIT FOR
	END IF
END FOR
RETURN encontro

END FUNCTION



FUNCTION calcula_totales(lim)
DEFINE lim, i		SMALLINT
DEFINE total_pedir	DECIMAL(10,2)

LET total_pedir = 0
FOR i = 1 TO lim
	LET total_pedir = total_pedir + rm_pedido[i].r93_cantpedir
END FOR
DISPLAY BY NAME total_pedir

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_r03.*
CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo) RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r03.r03_nombre     TO descrip_1
DISPLAY r_r70.r70_desc_sub   TO descrip_2
DISPLAY r_r71.r71_desc_grupo TO descrip_3
DISPLAY r_r72.r72_desc_clase TO descrip_4
DISPLAY r_r10.r10_marca      TO nom_marca

END FUNCTION



FUNCTION muestra_etiquetas_det(i, ind1, ind2)
DEFINE i, ind1, ind2	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, ind1)
CALL fl_lee_item(vg_codcia, rm_pedido[ind2].r93_item) RETURNING r_r10.*  
CALL muestra_descripciones(rm_pedido[ind2].r93_item, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
DISPLAY r_r10.r10_nombre TO nom_item 

END FUNCTION



FUNCTION cargar_datos_item(i, j)
DEFINE i, j		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r93		RECORD LIKE rept093.*

CALL fl_lee_item(vg_codcia, rm_pedido[i].r93_item) RETURNING r_r10.*  
LET rm_pedido[i].r93_cod_pedido = r_r10.r10_cod_pedido
LET rm_pedido[i].r10_nombre     = r_r10.r10_nombre
LET rm_pedido[i].r93_stock_max  = r_r10.r10_stock_max
LET rm_pedido[i].r93_stock_min  = r_r10.r10_stock_min
CALL retorna_stock_local(i) RETURNING rm_pedido[i].r93_stock_act
IF rm_pedido[i].r93_cantpend IS NULL THEN
	LET rm_pedido[i].r93_cantpend  = r_r10.r10_cantback
	LET rm_pedido[i].r93_cantpedir = rm_pedido[i].r93_cantpend +
					 rm_pedido[i].r93_stock_act
	IF rm_pedido[i].r93_cantpedir <= rm_pedido[i].r93_stock_min THEN
		LET rm_pedido[i].r93_cantpedir = rm_pedido[i].r93_stock_max -
						 rm_pedido[i].r93_stock_act -
						 rm_pedido[i].r93_cantpend
	ELSE
		LET rm_pedido[i].r93_cantpedir = 0
	END IF
	INITIALIZE r_r93.* TO NULL
	SELECT * INTO r_r93.* FROM rept093
		WHERE r93_compania = r_r10.r10_compania
		  AND r93_item     = r_r10.r10_codigo
	IF r_r93.r93_compania IS NOT NULL THEN
		--LET rm_pedido[i].r93_cantpend  = r_r93.r93_cantpend
		--LET rm_pedido[i].r93_cantpedir = r_r93.r93_cantpedir
	END IF
END IF
DISPLAY rm_pedido[i].* TO rm_pedido[j].*

END FUNCTION



FUNCTION retorna_stock_local(i)
DEFINE i		SMALLINT
DEFINE stock_total	DECIMAL(8,2)
DEFINE loc		LIKE gent002.g02_localidad

CASE vg_codloc
	WHEN 1
		LET loc = 2
	WHEN 3
		LET loc = 4
	OTHERWISE
		LET loc = 0
END CASE
SELECT NVL(SUM(r11_stock_act), 0) INTO stock_total
	FROM rept011
	WHERE r11_compania  = vg_codcia
	  AND r11_bodega    IN (SELECT r02_codigo FROM rept002
					WHERE r02_compania  = r11_compania
					  AND r02_estado    = 'A'
					  AND r02_tipo      = 'F'
					  AND r02_area      = 'R'
					  AND r02_localidad IN (vg_codloc, loc))
	  AND r11_item      = rm_pedido[i].r93_item
	  AND r11_stock_act > 0
RETURN stock_total

END FUNCTION



FUNCTION mensaje_intentar(i)
DEFINE i, intentar	SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fl_hacer_pregunta('Item ' || rm_pedido[i].r93_item CLIPPED || ' bloqueado por otro usuario. Desea intentarlo nuevamente ?', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	CALL fl_mensaje_abandonar_proceso() RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF
RETURN intentar

END FUNCTION



FUNCTION ver_item(item)
DEFINE item 		LIKE rept010.r10_codigo
DEFINE command_run	VARCHAR(100)
DEFINE run_prog		CHAR(10)

IF item IS NULL THEN
	RETURN
END IF
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'repp108 ',
		vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',vg_codloc, ' ',item
RUN command_run

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
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

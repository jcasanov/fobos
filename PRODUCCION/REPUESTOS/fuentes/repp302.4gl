------------------------------------------------------------------------------
-- Titulo           : repp302.4gl - Consulta de Item Pedidos
-- Elaboracion      : 06-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp302 base módulo compañía localidad [pedido]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     CHAR(400)
DEFINE rm_rep		RECORD LIKE rept016.*
DEFINE rm_rep2		RECORD LIKE rept017.*
DEFINE rm_rep3		RECORD LIKE rept010.*
DEFINE vm_pedido	LIKE rept016.r16_pedido
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_elm       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_repd		ARRAY [1000] OF RECORD
				r17_item	LIKE rept017.r17_item,
				tit_descripcion	LIKE rept010.r10_nombre,
				tit_cantidad	DECIMAL (8,2),
				r17_pedido	LIKE rept017.r17_pedido,
				r16_fec_llegada	LIKE rept016.r16_fec_llegada
			END RECORD
DEFINE vm_programa	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp302.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp302'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i,j,l,col	SMALLINT
DEFINE query		CHAR(500)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_elm = 1000
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
OPEN WINDOW w_rep AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/repf302_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf302_1c"
END IF
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_repd[i].* TO NULL
END FOR
INITIALIZE rm_rep.*, rm_rep2.*, rm_rep3.* TO NULL
IF num_args() = 5 THEN
	LET vm_pedido = arg_val(5)
	--SELECT r17_item, r10_nombre, r17_cantped - r17_cantrec cantidad,
	SELECT r17_item, r10_nombre, r17_cantped cantidad,
		r17_pedido, r16_fec_llegada
		FROM rept016, rept017, rept010
			WHERE r16_compania  = vg_codcia AND 
			      r16_localidad = vg_codloc AND
			      r16_pedido    = vm_pedido AND
			      r17_compania  = r16_compania AND
			      r17_localidad = r16_localidad AND
			      r17_pedido    = r16_pedido AND 
			      --r17_cantrec   < r17_cantped AND
			      r17_compania  = r10_compania AND 
			      r17_item      = r10_codigo
		INTO TEMP tmp_detalle_rep
ELSE
	SELECT r17_item, r10_nombre, r17_cantped - r17_cantrec cantidad,
		r17_pedido, r16_fec_llegada
		FROM rept016, rept017, rept010
			WHERE r16_compania  = vg_codcia AND 
			      r16_localidad = vg_codloc AND
			      r17_compania  = r16_compania AND
			      r17_localidad = r16_localidad AND
			      r17_pedido    = r16_pedido AND 
			      r17_cantrec   < r17_cantped AND
			      r17_compania  = r10_compania AND 
			      r17_item      = r10_codigo
		INTO TEMP tmp_detalle_rep
END IF
SELECT COUNT(*) INTO vm_num_elm FROM tmp_detalle_rep
IF vm_num_elm = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1] = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	DISPLAY FORM f_rep
	--#DISPLAY 'Item'        TO tit_col1
	--#DISPLAY 'Descripción' TO tit_col2
	--#DISPLAY 'Cant.'       TO tit_col3
	--#DISPLAY 'Pedidos'     TO tit_col4
	--#DISPLAY 'Fec. Lle.'   TO tit_col5
	LET query = 'SELECT * FROM tmp_detalle_rep ',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET i = 1
	FOREACH q_deto INTO rm_repd[i].*
		LET i = i + 1
		IF i > vm_max_elm THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT PROGRAM
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_repd TO rm_repd.*
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#LET l = scr_line()
			--#CALL muestra_contadores(j,i)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET j = arr_curr()
			LET l = scr_line()
			CALL ver_pedido(j)
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

END FUNCTION



FUNCTION muestra_contadores(cor,num)
DEFINE cor,num	         SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 21,1
	DISPLAY cor, " de ", num AT 21, 4
END IF

END FUNCTION



FUNCTION leer_nota_ped()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 6
LET num_rows = 6
LET num_cols = 22
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp AT row_ini, 30 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf302_2 FROM '../forms/repf302_2'
ELSE
	OPEN FORM f_repf302_2 FROM '../forms/repf302_2c'
END IF
DISPLAY FORM f_repf302_2
LET vm_programa = 'N'
LET int_flag    = 0
INPUT BY NAME vm_programa
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
END INPUT
CLOSE WINDOW w_repp
RETURN

END FUNCTION



FUNCTION ver_pedido(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE prog		CHAR(10)
DEFINE r_r81		RECORD LIKE rept081.*
DEFINE pedido		LIKE rept016.r16_pedido

LET prog        = ' repp204 '
LET pedido      = rm_repd[i].r17_pedido
LET vm_programa = 'S'
CALL fl_lee_nota_pedido_rep(vg_codcia, vg_codloc, rm_repd[i].r17_pedido)
	RETURNING r_r81.*
IF r_r81.r81_pedido IS NOT NULL THEN
	IF vg_gui = 1 THEN
		CALL leer_nota_ped()
		IF int_flag THEN
			RETURN
		END IF
		IF vm_programa = 'N' THEN
			LET prog   = ' repp233 '
			LET pedido = r_r81.r81_pedido
		END IF
	END IF
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, prog, vg_base,
	' ', vg_modulo, ' ', vg_codcia,' ', vg_codloc, ' ',
	'"', pedido, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Pedido'               AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

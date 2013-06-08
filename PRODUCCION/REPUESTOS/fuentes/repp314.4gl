--------------------------------------------------------------------------------
-- Titulo           : repp314.4gl - Consulta de Nota Entrega de Bodega
-- Elaboracion      : 11-Dic-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp314 base módulo compañía localidad
--				bodega orden de despacho flag
--				flag E = Nota Entrega  flag D = Orden Despacho
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	CHAR(400)
DEFINE rm_r36		RECORD LIKE rept036.*
DEFINE rm_r34		RECORD LIKE rept034.*
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_repd      SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_total_ent     DECIMAL (8,2)
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE r_entr 		ARRAY [1000] OF RECORD
				r37_item	LIKE rept037.r37_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r37_cant_ent	LIKE rept037.r37_cant_ent
			END RECORD
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE rm_g05		RECORD LIKE gent005.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp314.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 7 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp314'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i, resul		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_r95		RECORD LIKE rept095.*
DEFINE r_r96		RECORD LIKE rept096.*
DEFINE cod_tran		LIKE rept034.r34_cod_tran
DEFINE num_tran		LIKE rept034.r34_num_tran

CALL fl_nivel_isolation()
CALL fl_retorna_usuario()
LET vm_max_rows = 1000
LET vm_max_elm  = 1000
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
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_mas FROM "../forms/repf314_1"
ELSE
	OPEN FORM f_mas FROM "../forms/repf314_1c"
END IF
DISPLAY FORM f_mas
CALL mostrar_botones_detalle()
FOR i = 1 TO vm_max_elm
	INITIALIZE r_entr[i].* TO NULL
END FOR
INITIALIZE rm_r34.*, rm_r36.* TO NULL
LET vm_num_rows     = 0
LET vm_row_current  = 0
LET vm_num_repd     = 0
LET vm_scr_lin      = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
LET rm_r36.r36_bodega = arg_val(5)
CASE arg_val(7)
	WHEN 'E' LET rm_r36.r36_num_entrega = arg_val(6)
	WHEN 'D' LET rm_r36.r36_num_ord_des = arg_val(6)
END CASE
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
INITIALIZE rm_vend.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN qu_vd 
FETCH qu_vd INTO rm_vend.*
CLOSE qu_vd 
FREE qu_vd 
CALL control_consulta()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF rm_g05.g05_grupo <> 'GE' AND rm_g05.g05_grupo <> 'SI' AND
		   rm_g05.g05_grupo <> 'JB' AND rm_g05.g05_grupo <> 'OD'
		THEN
			HIDE OPTION 'Imprimir Nota'
		ELSE
			SHOW OPTION 'Imprimir Nota'
		END IF
		IF (NOT tiene_codigo_caja() OR rm_g05.g05_tipo <> 'UF') AND
		   (rm_g05.g05_grupo = 'GE' OR rm_g05.g05_grupo = 'SI' OR
		    rm_g05.g05_grupo = 'OD')
		THEN
			SHOW OPTION 'Imprimir Orden'
		ELSE
			HIDE OPTION 'Imprimir Orden'
		END IF
		{--
		IF (rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G') THEN
			HIDE OPTION 'Imprimir Nota'
		ELSE
			SHOW OPTION 'Imprimir Nota'
		END IF
		--}
		IF num_args() = 7 THEN
			SHOW OPTION 'Detalle'
                	IF vm_num_rows > 1 THEN
                        	SHOW OPTION 'Avanzar'
			END IF
                	IF vm_row_current > 1 THEN
                        	SHOW OPTION 'Retroceder'
			END IF
		END IF
		CALL retorna_guia_ne() RETURNING r_r96.*
		IF r_r96.r96_compania IS NOT NULL THEN
			HIDE OPTION 'Generar Guía Rem.'
			HIDE OPTION 'Agre. a Guía Rem.'
		ELSE
			CALL retorna_guia_valida() RETURNING r_r95.*
			IF r_r95.r95_compania IS NOT NULL THEN
				HIDE OPTION 'Generar Guía Rem.'
				SHOW OPTION 'Agre. a Guía Rem.'
			ELSE
				SHOW OPTION 'Generar Guía Rem.'
				HIDE OPTION 'Agre. a Guía Rem.'
			END IF
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
		CALL retorna_guia_ne() RETURNING r_r96.*
		IF r_r96.r96_compania IS NOT NULL THEN
			HIDE OPTION 'Generar Guía Rem.'
			HIDE OPTION 'Agre. a Guía Rem.'
		ELSE
			CALL retorna_guia_valida() RETURNING r_r95.*
			IF r_r95.r95_compania IS NOT NULL THEN
				HIDE OPTION 'Generar Guía Rem.'
				SHOW OPTION 'Agre. a Guía Rem.'
			ELSE
				SHOW OPTION 'Generar Guía Rem.'
				HIDE OPTION 'Agre. a Guía Rem.'
			END IF
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
		CALL retorna_guia_ne() RETURNING r_r96.*
		IF r_r96.r96_compania IS NOT NULL THEN
			HIDE OPTION 'Generar Guía Rem.'
			HIDE OPTION 'Agre. a Guía Rem.'
		ELSE
			CALL retorna_guia_valida() RETURNING r_r95.*
			IF r_r95.r95_compania IS NOT NULL THEN
				HIDE OPTION 'Generar Guía Rem.'
				SHOW OPTION 'Agre. a Guía Rem.'
			ELSE
				SHOW OPTION 'Generar Guía Rem.'
				HIDE OPTION 'Agre. a Guía Rem.'
			END IF
		END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('P') 'Imprimir Orden' 'Muestra Orden Despacho a imprimir. '
		CALL imprimir_orden()
	COMMAND KEY('T') 'Imprimir Nota' 'Muestra Nota Entrega a imprimir. '
		CALL imprimir_nota()
	COMMAND KEY('X') 'Generar Guía Rem.' 'Genera la Guía de Remisión. '
		CALL fl_control_guia_remision(vg_codcia, vg_codloc,
						rm_r34.r34_bodega,
						rm_r36.r36_num_entrega,
						rm_r34.r34_cod_tran,
						rm_r34.r34_num_tran)
			RETURNING resul
		CALL retorna_guia_ne() RETURNING r_r96.*
		IF r_r96.r96_compania IS NOT NULL THEN
			HIDE OPTION 'Generar Guía Rem.'
			HIDE OPTION 'Agre. a Guía Rem.'
			CALL imprimir_guia(r_r96.r96_guia_remision)
		ELSE
			CALL retorna_guia_valida() RETURNING r_r95.*
			IF r_r95.r95_compania IS NOT NULL THEN
				HIDE OPTION 'Generar Guía Rem.'
				SHOW OPTION 'Agre. a Guía Rem.'
			ELSE
				SHOW OPTION 'Generar Guía Rem.'
				HIDE OPTION 'Agre. a Guía Rem.'
			END IF
		END IF
	COMMAND KEY('Y') 'Agre. a Guía Rem.' 'Agrega NE a Guía de Remisión. '
		IF fl_agregar_guia_remision(vg_codcia, vg_codloc,
						rm_r34.r34_bodega,
						rm_r36.r36_num_entrega,
						rm_r34.r34_cod_tran,
						rm_r34.r34_num_tran)
		THEN
			HIDE OPTION 'Agre. a Guía Rem.'
			CALL retorna_guia_ne() RETURNING r_r96.*
			CALL imprimir_guia(r_r96.r96_guia_remision)
		END IF
	COMMAND KEY('G') 'Guía Remisión' 'Muestra la Guía de Remisión. '
		LET cod_tran = NULL
		LET num_tran = NULL
		CALL fl_ver_guia_remision(vg_codcia, vg_codloc,
						rm_r34.r34_bodega,
						rm_r36.r36_num_entrega,
						cod_tran, num_tran)
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(1000)
DEFINE expr_sql		VARCHAR(100)
DEFINE num_reg		INTEGER

CLEAR FORM
CALL mostrar_botones_detalle()
LET int_flag = 0
LET expr_sql = '  AND r36_num_ord_des = ', rm_r36.r36_num_ord_des
IF arg_val(7) = 'E' THEN
	LET expr_sql = '  AND r36_num_entrega = ', rm_r36.r36_num_entrega
END IF
LET query = 'SELECT ROWID ',
		'FROM rept036 ',
		'WHERE r36_compania    = ', vg_codcia,
		'  AND r36_localidad   = ', vg_codloc,             
		'  AND r36_bodega      = "', rm_r36.r36_bodega CLIPPED, '"',
		expr_sql CLIPPED
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
	EXIT PROGRAM
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT
DEFINE tot_cant		DECIMAL (8,2)

LET vm_total_ent = 0
FOR i = 1 TO vm_num_repd
	LET vm_total_ent = vm_total_ent + r_entr[i].r37_cant_ent
END FOR
DISPLAY BY NAME vm_total_ent 

END FUNCTION



FUNCTION muestra_siguiente_registro()
                                                                                
IF vm_row_current < vm_num_rows THEN
        LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
                                                                                
END FUNCTION



FUNCTION muestra_anterior_registro()
                                                                                
IF vm_row_current > 1 THEN
        LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 1, 1
	DISPLAY row_current, " de ", num_rows AT 1, 65
END IF
                                                                                
END FUNCTION



FUNCTION muestra_contadores_det(num_row)
DEFINE num_row		SMALLINT
                                                                                
DISPLAY BY NAME num_row, vm_num_repd
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_reg)
DEFINE num_reg		INTEGER
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE mensaje		VARCHAR(100)

IF vm_num_rows > 0 THEN
        DECLARE q_dt CURSOR FOR
		SELECT * FROM rept036
                	WHERE ROWID = num_reg	     	         
        OPEN q_dt
        FETCH q_dt INTO rm_r36.*
        IF STATUS = NOTFOUND THEN
		LET mensaje ='No existe registro con índice: ' || vm_row_current
        	--CALL fgl_winmessage (vg_producto, mensaje, 'exclamation')
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
                RETURN
        END IF	
        SELECT * INTO rm_r34.* FROM rept034
             	WHERE r34_compania    = vg_codcia
        	  AND r34_localidad   = vg_codloc             
        	  AND r34_bodega      = rm_r36.r36_bodega      	         
                  AND r34_num_ord_des = rm_r36.r36_num_ord_des
	DISPLAY BY NAME rm_r36.r36_num_entrega, rm_r36.r36_num_ord_des,
			rm_r34.r34_cod_tran, rm_r34.r34_num_tran,
			rm_r34.r34_bodega, rm_r36.r36_bodega_real,
			rm_r36.r36_fec_entrega, rm_r36.r36_entregar_a,
			rm_r36.r36_entregar_en
	CALL fl_lee_bodega_rep(vg_codcia, rm_r34.r34_bodega) RETURNING r_r02.*
        DISPLAY r_r02.r02_nombre TO tit_bodega
	CALL fl_lee_bodega_rep(vg_codcia, rm_r36.r36_bodega_real)
		RETURNING r_r02.*
        DISPLAY r_r02.r02_nombre TO tit_bodega_real
	CALL muestra_estado(rm_r36.r36_estado)
	CALL muestra_detalle(rm_r36.r36_bodega, rm_r36.r36_num_entrega)
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION muestra_detalle(bodega, num_ne)
DEFINE bodega		LIKE rept036.r36_bodega
DEFINE num_ne		LIKE rept036.r36_num_entrega
DEFINE orden		LIKE rept037.r37_orden
DEFINE query            CHAR(1000)
DEFINE i		SMALLINT
DEFINE r_entr_aux 	RECORD
				r37_item	LIKE rept037.r37_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r37_cant_ent	LIKE rept037.r37_cant_ent
			END RECORD

CALL retorna_tam_arr()
LET vm_scr_lin = vm_size_arr
LET int_flag = 0
FOR i = 1 TO vm_scr_lin
        INITIALIZE r_entr[i].* TO NULL
        CLEAR r_entr[i].*
END FOR
LET query = 'SELECT r37_item, r10_nombre, r37_cant_ent, r37_orden ',
		'FROM rept037, rept010 ',
                'WHERE r37_compania    = ', vg_codcia,
		'  AND r37_localidad   = ', vg_codloc,
		'  AND r37_bodega      = "', bodega, '"',
		'  AND r37_num_entrega = ', num_ne,
		'  AND r37_compania    = r10_compania ',
		'  AND r37_item        = r10_codigo ',
		'ORDER BY r37_orden'
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET i = 1
LET vm_num_repd = 0
FOREACH q_cons1 INTO r_entr_aux.*, orden
	LET r_entr[i].* = r_entr_aux.*
        LET i = i + 1
        LET vm_num_repd = vm_num_repd + 1
        IF vm_num_repd > vm_max_elm THEN
        	LET vm_num_repd = vm_num_repd - 1
		EXIT FOREACH
        END IF
END FOREACH
IF vm_num_repd > 0 THEN
        LET int_flag = 0
	CALL muestra_contadores_det(0)
	CALL muestra_lineas_detalle()
END IF
CALL sacar_total()
IF int_flag THEN
	INITIALIZE r_entr[1].* TO NULL
        RETURN
END IF
CALL muestra_etiquetas(0, 1)

END FUNCTION



FUNCTION muestra_lineas_detalle()
DEFINE i		SMALLINT
DEFINE lineas		SMALLINT

CALL retorna_tam_arr()
LET lineas = vm_size_arr
IF vm_num_repd < vm_size_arr THEN
	LET lineas = vm_num_repd
END IF
FOR i = 1 TO lineas
	DISPLAY r_entr[i].* TO r_entr[i].*
END FOR

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i, j		SMALLINT
DEFINE query		CHAR(1000)
DEFINE r_entr_aux 	RECORD
				r37_item	LIKE rept037.r37_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r37_cant_ent	LIKE rept037.r37_cant_ent
			END RECORD
DEFINE orden		LIKE rept037.r37_orden
DEFINE cod_tran		LIKE rept034.r34_cod_tran
DEFINE num_tran		LIKE rept034.r34_num_tran

CALL mostrar_botones_detalle()
LET query = 'SELECT r37_item, r10_nombre, r37_cant_ent, r37_orden ',
		'FROM rept037, rept010 ',
                'WHERE r37_compania    = ', vg_codcia,
		'  AND r37_localidad   = ', vg_codloc,
		'  AND r37_bodega      = "', rm_r36.r36_bodega, '"',
		'  AND r37_num_entrega = ', rm_r36.r36_num_entrega,
		'  AND r37_compania    = r10_compania ',
		'  AND r37_item        = r10_codigo ',
		'ORDER BY r37_orden'
PREPARE det FROM query
DECLARE q_det CURSOR FOR det
LET vm_num_repd = 1
FOREACH q_det INTO r_entr_aux.*, orden
	LET r_entr[vm_num_repd].* = r_entr_aux.*
        LET vm_num_repd = vm_num_repd + 1
        IF vm_num_repd > vm_max_elm THEN
		EXIT FOREACH
        END IF
END FOREACH
LET vm_num_repd = vm_num_repd - 1
LET int_flag = 0
CALL set_count(vm_num_repd)
CALL retorna_tam_arr()
IF vg_gui = 0 THEN
	CALL muestra_etiquetas(1, 1)
END IF
LET vm_scr_lin = vm_size_arr
DISPLAY ARRAY r_entr TO r_entr.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		IF (NOT tiene_codigo_caja() OR rm_g05.g05_tipo <> 'UF') AND
		   (rm_g05.g05_grupo = 'GE' OR rm_g05.g05_grupo = 'SI' OR
		    rm_g05.g05_grupo = 'OD')
		THEN
			CALL imprimir_orden()
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF NOT (rm_g05.g05_grupo <> 'GE' AND rm_g05.g05_grupo <> 'SI'
		   AND  rm_g05.g05_grupo <> 'JB' AND rm_g05.g05_grupo <> 'OD')
		THEN
			CALL imprimir_nota()
			LET int_flag = 0
		END IF
	ON KEY(F7)
		LET cod_tran = NULL
		LET num_tran = NULL
		CALL fl_ver_guia_remision(vg_codcia, vg_codloc,
						rm_r34.r34_bodega,
						rm_r36.r36_num_entrega,
						cod_tran, num_tran)
		LET int_flag = 0
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL muestra_etiquetas(i, i)
	--#BEFORE ROW
		--#LET i = arr_curr()
        	--#LET j = scr_line()
		--#CALL muestra_etiquetas(i, i)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#IF (NOT tiene_codigo_caja() OR rm_g05.g05_tipo <> 'UF') AND
		   --#(rm_g05.g05_grupo = 'GE' OR rm_g05.g05_grupo = 'SI' OR
		    --#rm_g05.g05_grupo = 'OD')
		--#THEN
			--#CALL dialog.keysetlabel("F5","Imprimir Orden")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","")
		--#END IF
		--#IF rm_g05.g05_grupo <> 'GE' AND rm_g05.g05_grupo <> 'SI' AND
		   --#rm_g05.g05_grupo <> 'JB' AND rm_g05.g05_grupo <> 'OD'
		--#THEN
			--#CALL dialog.keysetlabel("F6","")
		--#ELSE
			--#CALL dialog.keysetlabel("F6","Imprimir Nota")
		--#END IF
		--#CALL dialog.keysetlabel("F7","Guía Remisión")
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
IF int_flag = 1 THEN
	CALL muestra_etiquetas(0, 1)
	RETURN
END IF

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



FUNCTION muestra_etiquetas(fila, indice)
DEFINE fila, indice	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(fila)
CALL fl_lee_item(vg_codcia, r_entr[indice].r37_item) RETURNING r_r10.*
CALL muestra_descripciones(r_entr[indice].r37_item, r_r10.r10_linea,
		r_r10.r10_sub_linea, r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
DISPLAY r_r10.r10_nombre TO nom_item

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		LIKE rept036.r36_estado
                                                                                
IF estado = 'A' THEN
        DISPLAY 'ACTIVA' TO tit_estado_rep
END IF
IF estado = 'E' THEN
        DISPLAY 'ELIMINADA' TO tit_estado_rep
END IF
DISPLAY estado TO r36_estado
                                                                                
END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY 'Item'        TO tit_col1
--#DISPLAY 'Descripción' TO tit_col2
--#DISPLAY 'Cant. Ent.'  TO tit_col3

END FUNCTION



FUNCTION imprimir_orden()
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp431 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_r36.r36_bodega, ' ', rm_r36.r36_num_ord_des
RUN vm_nuevoprog

END FUNCTION



FUNCTION imprimir_nota()
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp432 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_r36.r36_bodega, ' ', rm_r36.r36_num_entrega
RUN vm_nuevoprog

END FUNCTION



FUNCTION imprimir_guia(guia)
DEFINE guia		LIKE rept095.r95_guia_remision
DEFINE r_r97		RECORD LIKE rept097.*
DEFINE comando		VARCHAR(200)
DEFINE run_prog		CHAR(10)

INITIALIZE r_r97.* TO NULL
SELECT * INTO r_r97.*
	FROM rept097
	WHERE r97_compania      = vg_codcia
	  AND r97_localidad     = vg_codloc
	  AND r97_guia_remision = guia
	  AND r97_cod_tran      = rm_r34.r34_cod_tran
	  AND r97_num_tran      = rm_r34.r34_num_tran
IF r_r97.r97_compania IS NOT NULL THEN
	LET run_prog = '; fglrun '
	IF vg_gui = 0 THEN
		LET run_prog = '; fglgo '
	END IF
	LET comando  = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
			vg_separador, 'fuentes', vg_separador, run_prog CLIPPED,
			' repp434 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
			' ', vg_codloc, ' ', r_r97.r97_guia_remision, ' "',
			rm_r34.r34_cod_tran, '"'
	RUN comando
END IF

END FUNCTION



FUNCTION retorna_guia_ne()
DEFINE r_r96		RECORD LIKE rept096.*

INITIALIZE r_r96.* TO NULL
SELECT rept096.* INTO r_r96.*
	FROM rept096
	WHERE r96_compania    = vg_codcia
	  AND r96_localidad   = vg_codloc
	  AND r96_bodega      = rm_r36.r36_bodega
	  AND r96_num_entrega = rm_r36.r36_num_entrega
RETURN r_r96.*

END FUNCTION



FUNCTION retorna_guia_valida()
DEFINE r_r95		RECORD LIKE rept095.*

INITIALIZE r_r95.* TO NULL
DECLARE q_r95 CURSOR FOR
	SELECT rept095.*
	FROM rept097, rept095
	WHERE r97_compania      = vg_codcia
	  AND r97_localidad     = vg_codloc
	  AND r97_cod_tran      = rm_r34.r34_cod_tran
	  AND r97_num_tran      = rm_r34.r34_num_tran
	  AND r95_compania      = r97_compania
	  AND r95_localidad     = r97_localidad
	  AND r95_guia_remision = r97_guia_remision
	  AND r95_estado        = 'A'
OPEN q_r95
FETCH q_r95 INTO r_r95.*
CLOSE q_r95
FREE q_r95
RETURN r_r95.*

END FUNCTION



FUNCTION retorna_tam_arr()

LET vm_size_arr = fgl_scr_size('r_entr')

END FUNCTION



FUNCTION tiene_codigo_caja()
DEFINE r_j02		RECORD LIKE cajt002.*

INITIALIZE r_j02.* TO NULL
DECLARE q_j02 CURSOR FOR
	SELECT * FROM cajt002
		WHERE j02_compania  = vg_codcia
		  AND j02_localidad = vg_codloc
		  AND j02_usua_caja = rm_g05.g05_usuario
OPEN q_j02
FETCH q_j02 INTO r_j02.*
CLOSE q_j02
FREE q_j02
IF r_j02.j02_compania IS NULL THEN
	RETURN 0
ELSE
	RETURN 1
END IF

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
DISPLAY '<F5>      Imprimir Orden'           AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Imprimir Nota'            AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

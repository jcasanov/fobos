--------------------------------------------------------------------------------
-- Titulo           : repp667.4gl - Carga a produccion la mudanza de Quito
--                                  Matriz a La Prensa.
-- Elaboracion      : 13-Dic-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp667 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_estado	CHAR(1)
DEFINE rm_tran		ARRAY[1000] OF RECORD
				r19_localidad	LIKE rept019.r19_localidad,
				r19_cod_tran	LIKE rept019.r19_cod_tran,
				r19_num_tran	LIKE rept019.r19_num_tran,
				r19_bodega_ori	LIKE rept019.r19_bodega_ori,
				r19_bodega_dest	LIKE rept019.r19_bodega_dest,
				r19_referencia	LIKE rept019.r19_referencia,
				r19_fecing	DATE,
				r94_codtra_fin	LIKE rept094.r94_codtra_fin,
				r94_numtra_fin	LIKE rept094.r94_numtra_fin,
				r94_traspasada	LIKE rept094.r94_traspasada
			END RECORD
DEFINE r_detalle	ARRAY[200] OF RECORD
				r20_cant_ped	LIKE rept020.r20_cant_ped,
				r20_stock_ant	LIKE rept020.r20_stock_ant,
				r20_item	LIKE rept020.r20_item,
				r20_costo	LIKE rept020.r20_costo,
				subtotal_item	LIKE rept019.r19_tot_costo
			END RECORD
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_vertrans	CHAR(1)
DEFINE rm_vend		RECORD LIKE rept001.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp667.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 8 THEN
	-- Validar # parÃ¡metros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp667'
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

IF num_args() = 6 THEN
	CALL llamada_con_parametros1()
	RETURN
END IF
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
OPEN WINDOW w_imp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_cons FROM '../forms/repf667_1'
ELSE
	OPEN FORM f_cons FROM '../forms/repf667_1c'
END IF
DISPLAY FORM f_cons
INITIALIZE rm_vend.* TO NULL
DECLARE qu_bodeg CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_bodeg 
FETCH qu_bodeg INTO rm_vend.*
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Usted no está configurado como vendedores/bodegueros.','stop')
	CLOSE qu_bodeg 
	FREE qu_bodeg 
	RETURN
END IF
CLOSE qu_bodeg 
FREE qu_bodeg 
LET vm_max_rows = 1000
--#DISPLAY 'L'          TO tit_col1
--#DISPLAY '#'          TO tit_col2
--#DISPLAY 'Origen'     TO tit_col3
--#DISPLAY 'BO'         TO tit_col4
--#DISPLAY 'BD'         TO tit_col5
--#DISPLAY 'Referencia' TO tit_col6
--#DISPLAY 'Fecha     ' TO tit_col7
--#DISPLAY '#'          TO tit_col8
--#DISPLAY 'Destino'    TO tit_col9
--#DISPLAY 'T'  	TO tit_col10
LET vm_estado    = 'P'
LET vm_vertrans  = 'N'
LET vm_fecha_fin = TODAY
LET vm_fecha_ini = vm_fecha_fin - 30 UNITS DAY
IF num_args() = 8 THEN
	CALL llamada_con_parametros2()
	RETURN
END IF
CALL control_consulta()

END FUNCTION



FUNCTION llamada_con_parametros1()
DEFINE r_r94		RECORD LIKE rept094.*
DEFINE mensaje		VARCHAR(100)

LET rm_tran[1].r19_cod_tran = arg_val(5)
LET rm_tran[1].r19_num_tran = arg_val(6)
INITIALIZE r_r94.* TO NULL
SELECT * INTO r_r94.* FROM rept094
	WHERE r94_compania   = vg_codcia
	  AND r94_locali_fin = vg_codloc
	  AND r94_codtra_fin = rm_tran[1].r19_cod_tran
	  AND r94_numtra_fin = rm_tran[1].r19_num_tran
IF r_r94.r94_compania IS NULL THEN
	LET mensaje = 'Transferencia ', rm_tran[1].r19_cod_tran, '-',
			rm_tran[1].r19_num_tran USING "<<<<<<<<<<&",
			' no tiene transferencia de ORIGEN.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN
END IF
CALL muestra_transferencia_origen(vg_codcia, r_r94.r94_localidad,
					r_r94.r94_cod_tran, r_r94.r94_num_tran)

END FUNCTION



FUNCTION llamada_con_parametros2()

LET vm_estado            = arg_val(5)
LET vm_fecha_ini         = arg_val(6)
LET vm_fecha_fin         = arg_val(7)
LET vm_num_rows          = 0
CALL muestra_contadores(0)
IF vg_gui = 0 THEN
	CALL muestra_estado()
END IF
DISPLAY BY NAME vm_estado, vm_fecha_ini, vm_fecha_fin
CALL carga_arreglo_trabajo()
IF vm_num_rows = 0 THEN
	RETURN
END IF
CALL despliega_arreglo()

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

WHILE TRUE
	LET vm_num_rows = 0
	CALL muestra_contadores(0)
	CALL lee_parametros()
	IF int_flag THEN
		RETURN
	END IF
	CALL carga_arreglo_trabajo()
	IF vm_num_rows = 0 THEN
		CONTINUE WHILE
	END IF
	CALL despliega_arreglo()
	FOR i = 1 TO fgl_scr_size('rm_tran')
		CLEAR rm_tran[i].*
	END FOR
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp		CHAR(3)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

LET int_flag = 0
IF vg_gui = 0 THEN
	CALL muestra_estado()
END IF
OPTIONS INPUT NO WRAP
INPUT BY NAME vm_estado, vm_fecha_ini, vm_fecha_fin, vm_vertrans
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		--#RETURN
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD vm_estado
		IF vm_estado IS NOT NULL AND vg_gui = 0 THEN
			CALL muestra_estado()
		ELSE	
			IF vg_gui = 0 THEN
				CLEAR tit_estado
			END IF
		END IF
	AFTER FIELD vm_fecha_ini
		IF vm_fecha_ini IS NULL THEN
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
		IF vm_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha de Hoy.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin
		IF vm_fecha_fin IS NULL THEN
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
		IF vm_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor que la Fecha de Hoy.', 'exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION carga_arreglo_trabajo()
DEFINE query		CHAR(1200)
DEFINE expr_bod		VARCHAR(150)
DEFINE expr_usr		VARCHAR(100)

LET expr_bod = NULL
IF rm_vend.r01_tipo = 'B' THEN
	--LET expr_bod = '   AND r19_bodega_ori[1, 1] = "0" '
	LET expr_bod = '   AND r19_bodega_ori[1, 1] = "1" '
END IF
IF rm_vend.r01_tipo = 'J' THEN
	--LET expr_bod = '   AND (r19_bodega_dest[1, 1] = "0" ',
	LET expr_bod = '   AND r19_bodega_dest[1, 1] = "1" '
			--'   OR r19_bodega_dest = "17") '
END IF
LET int_flag = 0
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_usr = NULL
IF vm_vertrans = 'S' THEN
	LET expr_usr = '   AND r19_usuario    = "',
				rm_vend.r01_user_owner CLIPPED, '"'
	LET expr_bod = NULL
END IF
LET query = 'SELECT r19_localidad, r19_cod_tran, r19_num_tran, ',
		' r19_bodega_ori, r19_bodega_dest, r19_referencia, ',
		' DATE(r19_fecing), r94_codtra_fin, r94_numtra_fin, ',
		' r94_traspasada ',
		' FROM rept094, rept019 ',
		' WHERE r94_compania  = ', vg_codcia,
		'   AND r94_localidad = ', vg_codloc,
		'   AND r94_cod_tran  = "TR" ',
		expr_bod CLIPPED,
		'   AND r19_compania  = r94_compania ',
		'   AND r19_localidad = r94_localidad ',
		'   AND r19_cod_tran  = r94_cod_tran ',
		'   AND r19_num_tran  = r94_num_tran ',
		'   AND DATE(r19_fecing) BETWEEN "', vm_fecha_ini,
					  '" AND "', vm_fecha_fin, '"',
		expr_usr CLIPPED
IF vm_estado = 'P' THEN
	LET query = query CLIPPED, '   AND r94_codtra_fin IS NULL ',
			'   AND r94_traspasada  = "N" '
ELSE
	IF vm_estado = 'T' THEN
		--LET query = query CLIPPED, ' AND r94_codtra_fin IS NOT NULL '
		LET query = query CLIPPED, '   AND r94_traspasada    = "S" '
	END IF
END IF
LET query = query CLIPPED, ' ORDER BY 7 '
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_tran[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	RETURN
END IF
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION
 


FUNCTION despliega_arreglo()
DEFINE i, j		SMALLINT
DEFINE query		CHAR(300)
DEFINE num_rows		INTEGER
DEFINE comando		VARCHAR(100)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE ejecutable	CHAR(10)
DEFINE resp		CHAR(6)

IF vg_gui = 0 THEN
	DISPLAY '<F5> Origen     <F6> Destino      <F7> Traspasar      ',
		'<F8> Anular Traspaso'
		AT 20,03 
	DISPLAY 'F5' AT 20,04 ATTRIBUTE(REVERSE)
	DISPLAY 'F6' AT 20,20 ATTRIBUTE(REVERSE)
	DISPLAY 'F7' AT 20,38 ATTRIBUTE(REVERSE)
	DISPLAY 'F8' AT 20,58 ATTRIBUTE(REVERSE)
END IF
CALL set_count(vm_num_rows)
LET int_flag = 0
DISPLAY ARRAY rm_tran TO rm_tran.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F5)
		LET i = arr_curr()
		CALL muestra_transferencia_origen(vg_codcia, 
			rm_tran[i].r19_localidad, 
			rm_tran[i].r19_cod_tran, rm_tran[i].r19_num_tran)
	ON KEY(F6)
		LET i = arr_curr()
		IF rm_tran[i].r94_codtra_fin IS NOT NULL THEN
			LET ejecutable = 'fglrun '
			IF vg_gui = 0 THEN
				LET ejecutable = 'fglgo '
			END IF
			LET comando = ejecutable, ' repp216 ', vg_base, ' ', 
				vg_modulo, ' ', vg_codcia, ' ',
				vg_codloc, ' ', 
				rm_tran[i].r94_codtra_fin, ' ',
				rm_tran[i].r94_numtra_fin
			RUN comando
		END IF
	ON KEY(F7)
		LET i = arr_curr()
		LET j = scr_line()
		IF rm_tran[i].r94_traspasada = 'N' THEN
			LET comando = 'Seguro de traspasar la transferencia: ',
				       rm_tran[i].r19_cod_tran, '-',
				       rm_tran[i].r19_num_tran USING '<<<<<&'
			CALL fl_hacer_pregunta(comando, 'No') RETURNING resp
			IF resp = 'Yes' THEN
				CALL control_traspasar_transferencia(
						rm_tran[i].r19_localidad, 
						rm_tran[i].r19_cod_tran, 
						rm_tran[i].r19_num_tran)
					RETURNING rm_tran[i].r94_traspasada
				DISPLAY rm_tran[i].r94_traspasada TO 
			        	rm_tran[j].r94_traspasada 
			END IF
			--#IF rm_tran[i].r94_traspasada = 'S' THEN
				--#CALL dialog.keysetlabel("F7","")
				--#CALL dialog.keysetlabel("F8","")
			--# END IF
		END IF
	ON KEY(F8)
		LET i = arr_curr()
		LET j = scr_line()
		IF rm_tran[i].r94_codtra_fin IS NULL AND vm_vertrans = 'S' THEN
			LET comando = 'Seguro de Anular el traspaso ',
					'(transferencia): ',
				       rm_tran[i].r19_cod_tran, '-',
				       rm_tran[i].r19_num_tran USING '<<<<<&'
			CALL fl_hacer_pregunta(comando, 'No') RETURNING resp
			IF resp = 'Yes' THEN
				CALL control_cargar_transferencia(
						rm_tran[i].r19_localidad, 
						rm_tran[i].r19_cod_tran, 
						rm_tran[i].r19_num_tran)
					RETURNING rm_tran[i].r94_codtra_fin,
				                  rm_tran[i].r94_numtra_fin
				DISPLAY rm_tran[i].r94_codtra_fin TO 
			        	rm_tran[j].r94_codtra_fin 
				DISPLAY rm_tran[i].r94_numtra_fin TO 
			        	rm_tran[j].r94_numtra_fin 
			END IF
			--#IF rm_tran[i].r94_codtra_fin IS NOT NULL THEN	
				--#CALL dialog.keysetlabel("F6","Destino")
				--#CALL dialog.keysetlabel("F7","")
				--#CALL dialog.keysetlabel("F8","")
			--# END IF
		END IF
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#IF rm_tran[i].r94_codtra_fin IS NULL THEN	
			--#CALL dialog.keysetlabel("F6","")
		--#ELSE
			--#CALL dialog.keysetlabel("F6","Destino")
		--#END IF
		--#CALL dialog.keysetlabel("F7","")
		--#CALL dialog.keysetlabel("F8","")
		--#IF rm_tran[i].r94_traspasada = 'N' THEN
			--#IF rm_tran[i].r94_codtra_fin IS NULL THEN	
				--#CALL dialog.keysetlabel("F7","Traspasar")
				--#CALL dialog.keysetlabel("F8","Anular Traspaso")
			--#END IF
		--#END IF
		--#IF vm_vertrans = 'N' THEN
			--#CALL dialog.keysetlabel("F8","")
		--#END IF
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#CALL muestra_contadores(i)
		--#IF rm_tran[i].r94_codtra_fin IS NULL THEN	
			--#CALL dialog.keysetlabel("F6","")
		--#ELSE
			--#CALL dialog.keysetlabel("F6","Destino")
		--#END IF
		--#IF rm_tran[i].r94_traspasada = 'S' THEN
			--#CALL dialog.keysetlabel("F7","")
			--#CALL dialog.keysetlabel("F8","")
		--#ELSE
			--#IF rm_tran[i].r94_codtra_fin IS NULL THEN	
				--#CALL dialog.keysetlabel("F7","Traspasar")
				--#CALL dialog.keysetlabel("F8","Anular Traspaso")
			--#END IF
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
                                                                                
END FUNCTION



FUNCTION muestra_transferencia_origen(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j 		SMALLINT
DEFINE query 		CHAR(250)
DEFINE num_max_rows	SMALLINT
DEFINE num		SMALLINT

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
LET num_max_rows = 200
OPEN WINDOW w_tra AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_tra FROM '../forms/repf667_2'
ELSE
	OPEN FORM f_tra FROM '../forms/repf667_2c'
END IF
DISPLAY FORM f_tra
--#DISPLAY 'Cant'		TO tit_col1
--#DISPLAY 'Stock'		TO tit_col2
--#DISPLAY 'Item'		TO tit_col3
--#DISPLAY 'Costo Unit.'	TO tit_col4
--#DISPLAY 'Subtotal'		TO tit_col5
SELECT * INTO r_r19.* FROM rept019 
	WHERE r19_compania  = codcia AND 
	      r19_localidad = codloc AND
	      r19_cod_tran  = cod_tran AND
	      r19_num_tran  = num_tran
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe transferencia en rept019.',
				'exclamation')
	CLOSE WINDOW w_tra
	RETURN
END IF
CALL fl_lee_localidad(codcia, codloc) RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO tit_local
DISPLAY BY NAME r_r19.r19_num_tran,    r_r19.r19_cod_tran, 
		r_r19.r19_bodega_ori,  r_r19.r19_bodega_dest,
		r_r19.r19_tot_costo,   r_r19.r19_referencia, 
		r_r19.r19_usuario,     r_r19.r19_fecing,
		r_r19.r19_localidad
CALL fl_lee_bodega_rep(codcia, r_r19.r19_bodega_ori)
	RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO nom_bod_ori
CALL fl_lee_bodega_rep(codcia, r_r19.r19_bodega_dest)
	RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO nom_bod_des
LET query = 'SELECT r20_cant_ped, r20_stock_ant, r20_item, r20_costo, ',
		    'r20_costo * r20_cant_ped FROM rept020 ',
            	'WHERE r20_compania  =  ', codcia, 
	    	'  AND r20_localidad =  ', codloc,
	    	'  AND r20_cod_tran  = "', r_r19.r19_cod_tran,'"',
            	'  AND r20_num_tran  =  ', r_r19.r19_num_tran,
	    	' ORDER BY 3'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO r_detalle[i].*
	LET i = i + 1
        IF i > num_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET i = 0
	CLOSE WINDOW w_tra
	RETURN
END IF 
LET num = i
LET j = 0
IF vg_gui = 0 THEN
	LET j = 1
END IF
CALL muestra_contadores_det(j, num)
CALL set_count(num)
DISPLAY ARRAY r_detalle TO r_detalle.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
        	CALL control_imprimir(codloc, r_r19.r19_cod_tran,
					r_r19.r19_num_tran)
		LET int_flag = 0
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL muestra_etiquetas_det(i, num, i)
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
                --#CALL dialog.keysetlabel('RETURN', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel("F5","Imprimir")
	--#BEFORE ROW 
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_etiquetas_det(i, num, i)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

LET int_flag = 0
CLOSE WINDOW w_tra

END FUNCTION



FUNCTION control_traspasar_transferencia(codloc, cod_tran, num_tran)
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r94		RECORD LIKE rept094.*
DEFINE r_r94_aux	RECORD LIKE rept094.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE mensaje		VARCHAR(130)

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
DECLARE qu_vd2 CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_vd2
INITIALIZE r_r01.* TO NULL
FETCH qu_vd2 INTO r_r01.*
IF status = NOTFOUND THEN
	DECLARE q_vend2 CURSOR FOR SELECT * FROM rept001
		WHERE r01_compania = vg_codcia AND r01_estado = 'A' AND 
	      	      r01_tipo IN ('B','J','G')
		ORDER BY r01_tipo
	OPEN q_vend2
	FETCH q_vend2 INTO r_r01.*
END IF		
SELECT * INTO r_r94.* FROM rept094
	WHERE r94_compania  = vg_codcia AND 
	      r94_localidad = codloc    AND 
	      r94_cod_tran  = cod_tran  AND 
	      r94_num_tran  = num_tran  
IF status = NOTFOUND THEN
	LET mensaje = 'No existe en rept094: ', cod_tran, '-',
		       num_tran USING '<<<<<<&'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN 'N'
END IF
IF r_r94.r94_codtra_fin IS NOT NULL THEN
	LET mensaje = 'La transferencia: ', cod_tran, '-',
		       num_tran USING '<<<<<<&', 
		      ' ya ha estado traspasada.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 'N'
END IF
SELECT * INTO r_r19.* FROM rept019
	WHERE r19_compania  = vg_codcia AND 
	      r19_localidad = codloc    AND 
	      r19_cod_tran  = cod_tran  AND 
	      r19_num_tran  = num_tran  
IF status = NOTFOUND THEN
	LET mensaje = 'No existe en rept019: ', cod_tran, '-',
		       num_tran USING '<<<<<<&'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN 'N'
END IF
BEGIN WORK
	CALL control_actualizacion_existencia(r_r19.*)
	INITIALIZE r_r94_aux.* TO NULL
	SELECT * INTO r_r94_aux.* FROM rept094
		WHERE r94_compania  = r_r94.r94_compania
		  AND r94_localidad = r_r94.r94_localidad
		  AND r94_cod_tran  = r_r94.r94_cod_tran
		  AND r94_num_tran  = r_r94.r94_num_tran
	IF r_r94_aux.r94_traspasada = 'S' THEN
		ROLLBACK WORK
		LET mensaje = 'La transferencia: ', r_r94.r94_cod_tran, '-',
				r_r94.r94_num_tran USING '<<<<<<&',
				' ya ha sido realizado su traspaso.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		RETURN 'S'
	END IF
	UPDATE rept094 SET r94_traspasada = 'S'
		WHERE r94_compania  = r_r94.r94_compania
		  AND r94_localidad = r_r94.r94_localidad
		  AND r94_cod_tran  = r_r94.r94_cod_tran
		  AND r94_num_tran  = r_r94.r94_num_tran
COMMIT WORK
LET mensaje = 'Proceso terminó Ok., verifique el stock.'
CALL fl_mostrar_mensaje(mensaje, 'info')
RETURN 'S'

END FUNCTION



FUNCTION control_cargar_transferencia(codloc, cod_tran, num_tran)
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE bodega_aux	LIKE rept002.r02_codigo
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r94		RECORD LIKE rept094.*
DEFINE r_r94_aux	RECORD LIKE rept094.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_stock_ori	RECORD LIKE rept011.*
DEFINE r_stock_des	RECORD LIKE rept011.*
DEFINE num_tran_ori	INTEGER
DEFINE costo_nue	DECIMAL(12,2)
DEFINE fecing_ori	DATETIME YEAR TO SECOND
DEFINE mensaje		VARCHAR(130)

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_vd 
INITIALIZE r_r01.* TO NULL
FETCH qu_vd INTO r_r01.*
IF status = NOTFOUND THEN
	DECLARE q_vend CURSOR FOR SELECT * FROM rept001
		WHERE r01_compania = vg_codcia AND r01_estado = 'A' AND 
	      	      r01_tipo IN ('B','J','G')
		ORDER BY r01_tipo
	OPEN q_vend
	FETCH q_vend INTO r_r01.*
END IF		
SELECT * INTO r_r94.* FROM rept094
	WHERE r94_compania  = vg_codcia AND 
	      r94_localidad = codloc    AND 
	      r94_cod_tran  = cod_tran  AND 
	      r94_num_tran  = num_tran  
IF status = NOTFOUND THEN
	LET mensaje = 'No existe en rept094: ', cod_tran, '-',
		       num_tran USING '<<<<<<&'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN cod_tran, num_tran
END IF
IF r_r94.r94_codtra_fin IS NOT NULL THEN
	LET mensaje = 'La transferencia: ', cod_tran, '-',
		       num_tran USING '<<<<<<&', 
		      ' ya ha estado traspasada.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN r_r94.r94_codtra_fin, r_r94.r94_numtra_fin
END IF
SELECT * INTO r_r19.* FROM rept019
	WHERE r19_compania  = vg_codcia AND 
	      r19_localidad = codloc    AND 
	      r19_cod_tran  = cod_tran  AND 
	      r19_num_tran  = num_tran  
IF status = NOTFOUND THEN
	LET mensaje = 'No existe en rept019: ', cod_tran, '-',
		       num_tran USING '<<<<<<&'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN cod_tran, num_tran
END IF
INITIALIZE cod_tran, num_tran TO NULL
LET r_r19.r19_vendedor = r_r01.r01_codigo
LET r_r19.r19_usuario  = vg_usuario
LET num_tran_ori       = r_r19.r19_num_tran
LET fecing_ori         = r_r19.r19_fecing
LET r_r19.r19_fecing   = CURRENT
LET r_r19.r19_localidad= vg_codloc
BEGIN WORK
CALL control_actualizacion_existencia(r_r19.*)
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA', 'TR')
	RETURNING r_r19.r19_num_tran 
IF r_r19.r19_num_tran <= 0 THEN
	ROLLBACK WORK	
	EXIT PROGRAM
END IF
LET bodega_aux            = r_r19.r19_bodega_ori
LET r_r19.r19_bodega_ori  = r_r19.r19_bodega_dest
LET r_r19.r19_bodega_dest = bodega_aux
INSERT INTO rept019 VALUES (r_r19.*)
DECLARE qu_dtr CURSOR FOR 
	SELECT * FROM rept020
		WHERE r20_compania  = r_r19.r19_compania
		  AND r20_localidad = r_r94.r94_localidad
		  AND r20_cod_tran  = r_r19.r19_cod_tran
		  AND r20_num_tran  = num_tran_ori
		ORDER BY r20_orden
FOREACH qu_dtr INTO r_r20.*
	LET r_r20.r20_num_tran = r_r19.r19_num_tran
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, r_r20.r20_item)
		RETURNING r_stock_ori.*
	IF r_stock_ori.r11_compania IS NULL THEN
		LET r_stock_ori.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_ant = r_stock_ori.r11_stock_act
	LET r_stock_ori.r11_stock_act = r_stock_ori.r11_stock_act -
					r_r20.r20_cant_ven
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	LET r_r20.r20_costant_mb = r_r10.r10_costult_mb
	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costant_ma = r_r10.r10_costult_ma
	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	IF r_stock_ori.r11_stock_act >= 0 THEN
		IF localidad_bodega(r_r19.r19_bodega_ori) = vg_codloc THEN
			UPDATE rept011
				SET r11_stock_act = r_stock_ori.r11_stock_act
				WHERE r11_compania = vg_codcia AND 
				      r11_bodega   = r_r19.r19_bodega_ori AND
				      r11_item     = r_r20.r20_item
		END IF
	END IF
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, r_r20.r20_item)
		RETURNING r_stock_des.*
	IF r_stock_des.r11_compania IS NULL THEN
		INSERT INTO rept011
      			(r11_compania, r11_bodega, r11_item, 
	 		 r11_ubicacion, r11_stock_ant, 
	 	         r11_stock_act, r11_ing_dia,
	 	         r11_egr_dia)
		VALUES(vg_codcia, r_r19.r19_bodega_dest,
	               r_r20.r20_item, 'SN', 0, 0, 0, 0)
		LET r_stock_des.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_bd  = r_stock_des.r11_stock_act
	LET r_stock_des.r11_stock_act = r_stock_des.r11_stock_act +
					r_r20.r20_cant_ven
	UPDATE rept011
		SET r11_stock_act = r_stock_des.r11_stock_act
		WHERE r11_compania = vg_codcia AND 
		      r11_bodega   = r_r19.r19_bodega_dest AND
		      r11_item     = r_r20.r20_item
	LET r_r20.r20_fecing    = r_r19.r19_fecing
	LET r_r20.r20_localidad = r_r19.r19_localidad
	INSERT INTO rept020 VALUES (r_r20.*)
END FOREACH
INITIALIZE r_r94_aux.* TO NULL
SELECT * INTO r_r94_aux.* FROM rept094
	WHERE r94_compania  = r_r94.r94_compania
	  AND r94_localidad = r_r94.r94_localidad
	  AND r94_cod_tran  = r_r94.r94_cod_tran
	  AND r94_num_tran  = r_r94.r94_num_tran
IF r_r94_aux.r94_codtra_fin IS NOT NULL THEN
	ROLLBACK WORK
	LET mensaje = 'La transferencia: ', r_r94.r94_cod_tran, '-',
			r_r94.r94_num_tran USING '<<<<<<&',
			' ya ha sido cancelado su traspaso.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	RETURN r_r94_aux.r94_codtra_fin, r_r94_aux.r94_numtra_fin
END IF
UPDATE rept094 SET r94_codtra_fin = r_r20.r20_cod_tran,
    		   r94_numtra_fin = r_r20.r20_num_tran,
    		   r94_fecing_fin = r_r19.r19_fecing,
		   r94_traspasada = 'N'
	WHERE r94_compania  = r_r94.r94_compania
	  AND r94_localidad = r_r94.r94_localidad
	  AND r94_cod_tran  = r_r94.r94_cod_tran
	  AND r94_num_tran  = r_r94.r94_num_tran
COMMIT WORK
CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc, 
	 	r_r19.r19_cod_tran, r_r19.r19_num_tran)
LET mensaje = 'Proceso terminó Ok., verifique e imprima la transferencia ',
	      'generada.'
CALL fl_mostrar_mensaje(mensaje, 'info')
RETURN r_r19.r19_cod_tran, r_r19.r19_num_tran

END FUNCTION



FUNCTION control_actualizacion_existencia(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE stock_act	LIKE rept011.r11_stock_act
DEFINE ing_dia		LIKE rept011.r11_ing_dia
DEFINE act_sto_bd	SMALLINT

SET LOCK MODE TO WAIT
DECLARE q_r20 CURSOR FOR
	SELECT * FROM rept020
		WHERE r20_compania  = r_r19.r19_compania
		  AND r20_localidad = r_r19.r19_localidad
		  AND r20_cod_tran  = r_r19.r19_cod_tran
		  AND r20_num_tran  = r_r19.r19_num_tran
		ORDER BY r20_orden
FOREACH q_r20 INTO r_r20.*
	CALL actualizar_stock_bodega_prensa(r_r19.r19_bodega_ori,
						r_r19.r19_bodega_dest)
		RETURNING act_sto_bd
	IF localidad_bodega(r_r19.r19_bodega_ori) = vg_codloc AND
		act_sto_bd
	THEN
		UPDATE rept011 
			SET r11_stock_ant = r11_stock_act,
			    r11_stock_act = r11_stock_act - r_r20.r20_cant_ped,
			    r11_egr_dia   = r_r20.r20_cant_ped
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_ori
			  AND r11_item     = r_r20.r20_item 
	END IF
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, r_r20.r20_item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		LET stock_act = 0
		LET ing_dia   = 0
		IF localidad_bodega(r_r19.r19_bodega_dest) = vg_codloc THEN
			LET stock_act = r_r20.r20_cant_ped
			LET ing_dia   = r_r20.r20_cant_ped
			INSERT INTO rept011
      				(r11_compania, r11_bodega, r11_item, 
			 	r11_ubicacion, r11_stock_ant, 
			 	r11_stock_act, r11_ing_dia,
			 	r11_egr_dia)
			VALUES(vg_codcia, r_r19.r19_bodega_dest, r_r20.r20_item,
				'SN', 0, stock_act, ing_dia, 0)
		END IF
	ELSE
		IF localidad_bodega(r_r19.r19_bodega_dest) = vg_codloc THEN
			UPDATE rept011 
				SET r11_stock_ant = r11_stock_act,
		      		    r11_stock_act = r11_stock_act +
						      r_r20.r20_cant_ped,
		      		    r11_ing_dia   = r_r20.r20_cant_ped
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = r_r19.r19_bodega_dest
				  AND r11_item     = r_r20.r20_item 
		END IF
	END IF
END FOREACH
SET LOCK MODE TO NOT WAIT

END FUNCTION



FUNCTION actualizar_stock_bodega_prensa(bod_ori, bod_dest)
DEFINE bod_ori, bod_dest	LIKE rept002.r02_codigo

--IF (bod_ori[1, 1] = '0' OR bod_dest[1, 1] = '0' OR bod_dest = '17') AND
IF (bod_ori[1, 1] = '1' OR bod_dest[1, 1] = '1') AND
    (localidad_bodega(bod_ori) = 3 OR localidad_bodega(bod_dest) = 3)
THEN
	RETURN 0
ELSE
	RETURN 1
END IF

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
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r03.r03_nombre     TO descrip_1
DISPLAY r_r70.r70_desc_sub   TO descrip_2
DISPLAY r_r71.r71_desc_grupo TO descrip_3
DISPLAY r_r72.r72_desc_clase TO descrip_4
DISPLAY r_r10.r10_marca      TO nom_marca

END FUNCTION



FUNCTION localidad_bodega(bodega)
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE r_r02		RECORD LIKE rept002.*

CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_r02.*
RETURN r_r02.r02_localidad

END FUNCTION



FUNCTION muestra_contadores(num_cur)
DEFINE num_cur		SMALLINT

--#DISPLAY BY NAME num_cur, vm_num_rows

END FUNCTION



FUNCTION muestra_estado()

DISPLAY BY NAME vm_estado
CASE vm_estado
	WHEN 'P'
		DISPLAY 'PENDIENTES'   TO tit_estado
	WHEN 'T'
		DISPLAY 'TRASPASADAS' TO tit_estado
	WHEN 'D'
		DISPLAY 'T O D A S'    TO tit_estado
END CASE

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_etiquetas_det(i, ind1, ind2)
DEFINE i, ind1, ind2	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, ind1)
CALL fl_lee_item(vg_codcia, r_detalle[ind2].r20_item) RETURNING r_r10.*  
CALL muestra_descripciones(r_detalle[ind2].r20_item, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
DISPLAY r_r10.r10_nombre TO nom_item 

END FUNCTION



FUNCTION control_imprimir(codloc, cod_tran, num_tran)
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE comando		CHAR(255)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÃƒÂšN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp415 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', codloc, ' "', cod_tran, '" ', num_tran,' "O"'
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
DISPLAY '<F5>    Imprimir'                   AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

------------------------------------------------------------------------------
-- Titulo           : repp666.4gl - Carga a produccion transferencias de otras
--                                  localidades, previamente transmitidas.
-- Elaboracion      : 01-Feb-2004
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp666 base_datos modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_estado	CHAR(1)
DEFINE rm_tran		ARRAY[1000] OF RECORD
				r91_localidad	LIKE rept091.r91_localidad,
				r91_cod_tran	LIKE rept091.r91_cod_tran,
				r91_num_tran	LIKE rept091.r91_num_tran,
				r91_bodega_ori	LIKE rept091.r91_bodega_ori,
				r91_bodega_dest	LIKE rept091.r91_bodega_dest,
				r91_referencia	LIKE rept091.r91_referencia,
				r91_fecing	DATE,
				r90_codtra_fin	LIKE rept090.r90_codtra_fin,
				r90_numtra_fin	LIKE rept090.r90_numtra_fin
			END RECORD
DEFINE r_detalle	ARRAY[200] OF RECORD
				r92_cant_ped	LIKE rept092.r92_cant_ped,
				r92_stock_ant	LIKE rept092.r92_stock_ant,
				r92_item	LIKE rept092.r92_item,
				r92_costo	LIKE rept092.r92_costo,
				subtotal_item	LIKE rept019.r19_tot_costo
			END RECORD
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE vm_stock_pend	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_cruce		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp666.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 8 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp666'
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
	EXIT PROGRAM
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
OPEN WINDOW w_repf666_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf666_1 FROM '../forms/repf666_1'
ELSE
	OPEN FORM f_repf666_1 FROM '../forms/repf666_1c'
END IF
DISPLAY FORM f_repf666_1
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
LET vm_estado    = 'P'
LET vm_fecha_fin = TODAY
LET vm_fecha_ini = NULL
SQL
	SELECT MIN(DATE(r90_fecing))
		INTO $vm_fecha_ini
		FROM rept090
		WHERE r90_compania   = $vg_codcia
		  AND r90_cod_tran   = 'TR'
		  AND r90_codtra_fin IS NULL
END SQL
IF vm_fecha_ini IS NULL THEN
	LET vm_fecha_ini = vm_fecha_fin - 30 UNITS DAY
END IF
INITIALIZE rm_g02.* TO NULL
CALL obtener_localidad()
IF num_args() = 8 THEN
	CALL llamada_con_parametros2()
ELSE
	CALL control_consulta()
END IF
CLOSE WINDOW w_repf666_1
EXIT PROGRAM

END FUNCTION



FUNCTION llamada_con_parametros1()
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE mensaje		VARCHAR(100)

LET rm_tran[1].r91_cod_tran = arg_val(5)
LET rm_tran[1].r91_num_tran = arg_val(6)
INITIALIZE r_r90.* TO NULL
SELECT * INTO r_r90.* FROM rept090
	WHERE r90_compania   = vg_codcia
	  AND r90_locali_fin = vg_codloc
	  AND r90_codtra_fin = rm_tran[1].r91_cod_tran
	  AND r90_numtra_fin = rm_tran[1].r91_num_tran
IF r_r90.r90_compania IS NULL THEN
	LET mensaje = 'Transferencia ', rm_tran[1].r91_cod_tran, '-',
			rm_tran[1].r91_num_tran USING "<<<<<<<<<<&",
			' no tiene transferencia de ORIGEN.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
ELSE
	CALL muestra_transferencia_origen(vg_codcia, r_r90.r90_localidad,
					r_r90.r90_cod_tran, r_r90.r90_num_tran)
END IF

END FUNCTION



FUNCTION llamada_con_parametros2()

LET vm_estado            = arg_val(5)
LET vm_fecha_ini         = arg_val(6)
LET vm_fecha_fin         = arg_val(7)
LET rm_g02.g02_localidad = arg_val(8)
CALL obtener_localidad()
LET vm_num_rows          = 0
CALL muestra_contadores(0)
IF vg_gui = 0 THEN
	CALL muestra_estado()
END IF
DISPLAY BY NAME vm_estado, vm_fecha_ini, vm_fecha_fin
CALL carga_arreglo_trabajo()
IF vm_num_rows > 0 THEN
	CALL despliega_arreglo()
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE i		SMALLINT

LET vm_cruce = 0
WHILE TRUE
	LET vm_num_rows = 0
	CALL muestra_contadores(0)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
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
DEFINE r_g02		RECORD LIKE gent002.*

OPTIONS INPUT NO WRAP
IF vg_gui = 0 THEN
	CALL muestra_estado()
END IF
LET int_flag = 0
INPUT BY NAME vm_estado, vm_fecha_ini, vm_fecha_fin, rm_g02.g02_localidad
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
        ON KEY(F2)
		IF INFIELD(g02_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
                        LET int_flag = 0
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_g02.g02_localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_g02.g02_localidad,
						r_g02.g02_nombre
			END IF
                END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	BEFORE FIELD g02_localidad
		LET r_g02.g02_localidad = rm_g02.g02_localidad
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
	AFTER FIELD g02_localidad
		IF vg_codloc = 2 OR vg_codloc = 4 OR vg_codloc = 5 THEN
			IF vg_codloc = 2 THEN
				LET rm_g02.g02_localidad = 1
			END IF
			IF vg_codloc = 4 THEN
				IF rm_g02.g02_localidad <> 3 AND
				   rm_g02.g02_localidad <> 5
				THEN
					LET rm_g02.g02_localidad = 3
				END IF
			END IF
			IF vg_codloc = 5 THEN
				IF rm_g02.g02_localidad = 1 OR
				   rm_g02.g02_localidad = 2
				THEN
					CALL fl_mostrar_mensaje('La localidad solo puede ser 3 o 4.', 'exclamation')
					LET rm_g02.g02_localidad = 3
				END IF
			END IF
			CALL obtener_localidad()
			CONTINUE INPUT
		END IF
		IF rm_g02.g02_localidad IS NULL THEN
			LET rm_g02.g02_localidad = r_g02.g02_localidad
		END IF
		CALL obtener_localidad()
		IF rm_g02.g02_localidad IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esta Localidad.', 'exclamation')
			NEXT FIELD g02_localidad
		END IF
		IF rm_g02.g02_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD g02_localidad
		END IF
		IF rm_g02.g02_localidad = vg_codloc THEN
			CALL fl_mostrar_mensaje('La Localidad debe ser distinta que la Localidad: ' || rm_g02.g02_nombre CLIPPED || '.', 'exclamation')
			NEXT FIELD g02_localidad
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION carga_arreglo_trabajo()
DEFINE query		CHAR(1000)

LET int_flag = 0
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET query = 'SELECT r91_localidad, r91_cod_tran, r91_num_tran, ',
		' r91_bodega_ori, r91_bodega_dest, r91_referencia, ',
		' DATE(r91_fecing), r90_codtra_fin, r90_numtra_fin ',
		' FROM rept090, rept091 ',
		' WHERE r90_compania  = ', vg_codcia,
		'   AND r90_localidad = ', rm_g02.g02_localidad,
		'   AND r90_cod_tran  = "TR" ',
		'   AND r91_compania  = r90_compania ',
		'   AND r91_localidad = r90_localidad ',
		'   AND r91_cod_tran  = r90_cod_tran ',
		'   AND r91_num_tran  = r90_num_tran ',
		'   AND DATE(r91_fecing) BETWEEN "', vm_fecha_ini,
					  '" AND "', vm_fecha_fin, '"'
IF vm_estado = 'P' THEN
	LET query = query CLIPPED, '   AND r90_codtra_fin IS NULL '
ELSE
	IF vm_estado = 'T' THEN
		LET query = query CLIPPED, '   AND r90_codtra_fin IS NOT NULL '
	END IF
END IF
IF vg_codloc = 3 OR vg_codloc = 5 THEN
	LET query = query CLIPPED, '   AND r90_locali_fin = ', vg_codloc
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
DEFINE i, j, reversa	SMALLINT
DEFINE query		CHAR(300)
DEFINE num_rows		INTEGER
DEFINE comando		VARCHAR(100)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r42		RECORD LIKE rept042.*
DEFINE ejecutable	CHAR(10)
DEFINE resp		CHAR(6)

IF vg_gui = 0 THEN
	DISPLAY '<F5> Origen     <F6> Destino      <F7> Transmitir     ',
		'<F8> Reversar Trans.'
		AT 20,03 
	DISPLAY 'F5' AT 20,04 ATTRIBUTE(REVERSE)
	DISPLAY 'F6' AT 20,20 ATTRIBUTE(REVERSE)
	DISPLAY 'F7' AT 20,38 ATTRIBUTE(REVERSE)
	DISPLAY 'F8' AT 20,58 ATTRIBUTE(REVERSE)
END IF
CALL set_count(vm_num_rows)
DISPLAY ARRAY rm_tran TO rm_tran.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F5)
		LET i = arr_curr()
		CALL muestra_transferencia_origen(vg_codcia, 
			rm_tran[i].r91_localidad, 
			rm_tran[i].r91_cod_tran, rm_tran[i].r91_num_tran)
	ON KEY(F6)
		LET i = arr_curr()
		IF rm_tran[i].r90_codtra_fin IS NOT NULL THEN
			LET ejecutable = 'fglrun '
			IF vg_gui = 0 THEN
				LET ejecutable = 'fglgo '
			END IF
			LET comando = ejecutable, ' repp216 ', vg_base, ' ', 
				vg_modulo, ' ', vg_codcia, ' ',
				vg_codloc, ' ', 
				rm_tran[i].r90_codtra_fin, ' ',
				rm_tran[i].r90_numtra_fin
			RUN comando
		END IF
	ON KEY(F7)
		LET i = arr_curr()
		LET j = scr_line()
		IF rm_tran[i].r90_codtra_fin IS NULL THEN
			LET comando = 'Seguro de transmitir la transferencia: ',
				       rm_tran[i].r91_cod_tran, '-',
				       rm_tran[i].r91_num_tran USING '<<<<<&'
			CALL fl_hacer_pregunta(comando,'No') RETURNING resp
			IF resp = 'Yes' THEN
				CALL control_cargar_transferencia(
						rm_tran[i].r91_localidad, 
						rm_tran[i].r91_cod_tran, 
						rm_tran[i].r91_num_tran, 1)
					RETURNING rm_tran[i].r90_codtra_fin,
				                  rm_tran[i].r90_numtra_fin
				DISPLAY rm_tran[i].r90_codtra_fin TO 
			        	rm_tran[j].r90_codtra_fin 
				DISPLAY rm_tran[i].r90_numtra_fin TO 
			        	rm_tran[j].r90_numtra_fin 
				LET reversa = 1
			END IF
			--#IF rm_tran[i].r90_codtra_fin IS NOT NULL THEN	
				--#CALL dialog.keysetlabel("F6","Destino")
				--#CALL dialog.keysetlabel("F7","")
				--#CALL dialog.keysetlabel("F8","Reversar Transm.")
			--#ELSE
				--#CALL dialog.keysetlabel("F8","")
			--#END IF
		END IF
	ON KEY(F8)
		LET i = arr_curr()
		LET j = scr_line()
		IF vg_gui = 0 THEN
			INITIALIZE r_r42.* TO NULL
			SELECT * INTO r_r42.*
				FROM rept042
				WHERE r42_compania  = vg_codcia
				  AND r42_localidad = vg_codloc
				  AND r42_cod_tran  = rm_tran[i].r90_codtra_fin
				  AND r42_num_tran  = rm_tran[i].r90_numtra_fin
			IF r_r42.r42_num_tr_re IS NOT NULL THEN
				LET reversa = 0
			ELSE
				IF rm_tran[i].r90_codtra_fin IS NOT NULL THEN
					LET reversa = 1
				ELSE
					LET reversa = 0
				END IF
			END IF
		END IF
		IF rm_tran[i].r90_codtra_fin IS NOT NULL AND reversa THEN
			LET comando = 'Seguro de Reversar la transmision ',
					'(transferencia): ',
				       rm_tran[i].r91_cod_tran, '-',
				       rm_tran[i].r91_num_tran USING '<<<<<&'
			CALL fl_hacer_pregunta(comando, 'No') RETURNING resp
			IF resp = 'Yes' THEN
				CALL control_cargar_transferencia(vg_codloc,
						rm_tran[i].r90_codtra_fin, 
						rm_tran[i].r90_numtra_fin, 0)
					RETURNING rm_tran[i].r90_codtra_fin,
				                  rm_tran[i].r90_numtra_fin
			END IF
			--#IF rm_tran[i].r90_codtra_fin IS NOT NULL THEN	
				--#CALL dialog.keysetlabel("F6","Destino")
				--#CALL dialog.keysetlabel("F7","")
				--#CALL dialog.keysetlabel("F8","")
			--# END IF
		END IF
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#CALL muestra_contadores(i)
		--#IF rm_tran[i].r90_codtra_fin IS NULL THEN	
			--#CALL dialog.keysetlabel("F6","")
			--#CALL dialog.keysetlabel("F7","Transmitir")
			--#CALL dialog.keysetlabel("F8","")
		--#ELSE
			--#CALL dialog.keysetlabel("F6","Destino")
			--#CALL dialog.keysetlabel("F7","")
			--#CALL dialog.keysetlabel("F8","Reversar Transm.")
		--#END IF
		--#INITIALIZE r_r42.* TO NULL
		--#SELECT * INTO r_r42.*
			--#FROM rept042
			--#WHERE r42_compania  = vg_codcia
			--#  AND r42_localidad = vg_codloc
			--#  AND r42_cod_tran  = rm_tran[i].r90_codtra_fin
			--#  AND r42_num_tran  = rm_tran[i].r90_numtra_fin 
		--#IF r_r42.r42_num_tr_re IS NOT NULL THEN
			--#CALL dialog.keysetlabel("F8","")
			--#LET reversa = 0
		--#ELSE
			--#IF rm_tran[i].r90_codtra_fin IS NOT NULL THEN
				--#CALL dialog.keysetlabel("F8","Reversar Transm.")
				--#LET reversa = 1
			--#ELSE
				--#CALL dialog.keysetlabel("F8","")
				--#LET reversa = 0
			--#END IF
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
                                                                                
END FUNCTION



FUNCTION muestra_transferencia_origen(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept091.r91_compania
DEFINE codloc		LIKE rept091.r91_localidad
DEFINE cod_tran		LIKE rept091.r91_cod_tran
DEFINE num_tran		LIKE rept091.r91_num_tran
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r91		RECORD LIKE rept091.*
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
	OPEN FORM f_tra FROM '../forms/repf666_2'
ELSE
	OPEN FORM f_tra FROM '../forms/repf666_2c'
END IF
DISPLAY FORM f_tra
--#DISPLAY 'Cant'		TO tit_col1
--#DISPLAY 'Stock'		TO tit_col2
--#DISPLAY 'Item'		TO tit_col3
--#DISPLAY 'Costo Unit.'	TO tit_col4
--#DISPLAY 'Subtotal'		TO tit_col5
SELECT * INTO r_r91.* FROM rept091 
	WHERE r91_compania  = codcia AND 
	      r91_localidad = codloc AND
	      r91_cod_tran  = cod_tran AND
	      r91_num_tran  = num_tran
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe transferencia en rept091.',
				'exclamation')
	CLOSE WINDOW w_tra
	RETURN
END IF
CALL fl_lee_localidad(codcia, codloc) RETURNING r_g02.*
DISPLAY r_g02.g02_nombre TO tit_local
DISPLAY BY NAME r_r91.r91_num_tran,    r_r91.r91_cod_tran, 
		r_r91.r91_bodega_ori,  r_r91.r91_bodega_dest,
		r_r91.r91_tot_costo,   r_r91.r91_referencia, 
		r_r91.r91_usuario,     r_r91.r91_fecing,
		r_r91.r91_localidad
CALL fl_lee_bodega_rep(codcia, r_r91.r91_bodega_ori) RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO nom_bod_ori
CALL fl_lee_bodega_rep(codcia, r_r91.r91_bodega_dest) RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO nom_bod_des
LET query = 'SELECT r92_cant_ped, r92_stock_ant, r92_item, r92_costo, ',
		    'r92_costo * r92_cant_ped FROM rept092 ',
            	'WHERE r92_compania  =  ', codcia, 
	    	'  AND r92_localidad =  ', codloc,
	    	'  AND r92_cod_tran  = "', r_r91.r91_cod_tran,'"',
            	'  AND r92_num_tran  =  ', r_r91.r91_num_tran,
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
	LET i = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_tra
	RETURN
END IF 
LET num = i
LET j = 0
IF vg_gui = 0 THEN
	LET j = 1
END IF
SELECT rept019.* INTO r_r19.*
	FROM rept090, rept019
	WHERE r90_compania  = r_r91.r91_compania
	  AND r90_localidad = r_r91.r91_localidad
	  AND r90_cod_tran  = r_r91.r91_cod_tran
	  AND r90_num_tran  = r_r91.r91_num_tran  
	  AND r19_compania  = r90_compania
	  AND r19_localidad = r90_locali_fin
	  AND r19_cod_tran  = r90_codtra_fin
	  AND r19_num_tran  = r90_numtra_fin
CALL muestra_contadores_det(j, num)
CALL set_count(num)
DISPLAY ARRAY r_detalle TO r_detalle.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		LET i = arr_curr()	
		IF tiene_item_cruce(r_detalle[i].r92_item, r_r19.*) THEN
			CALL muestra_facturas_cruce(i, r_r19.*)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF tiene_facturas_cruce(r_r19.*) THEN
			CALL muestra_fact_items_cruce(r_r19.*)
			LET int_flag = 0
		END IF
	ON KEY(F7)
        	CALL control_imprimir(codloc, r_r91.r91_cod_tran,
					r_r91.r91_num_tran)
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
		--#CALL dialog.keysetlabel("F5","Facturas Cruce")
		--#CALL dialog.keysetlabel("F6","Fact. Item Cruce")
		--#CALL dialog.keysetlabel("F7","Imprimir")
	--#BEFORE ROW 
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_etiquetas_det(i, num, i)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CLOSE WINDOW w_tra
RETURN

END FUNCTION



FUNCTION control_cargar_transferencia(codloc, cod_tran, num_tran, flag)
DEFINE codloc		LIKE rept091.r91_localidad
DEFINE cod_tran		LIKE rept091.r91_cod_tran
DEFINE num_tran		LIKE rept091.r91_num_tran
DEFINE flag		SMALLINT
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE r_r90_aux	RECORD LIKE rept090.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_stock_ori	RECORD LIKE rept011.*
DEFINE r_stock_des	RECORD LIKE rept011.*
DEFINE bod_aux		LIKE rept019.r19_bodega_ori
DEFINE bod_aux2		LIKE rept019.r19_bodega_dest
DEFINE num_tran_ori	INTEGER
DEFINE costo_nue	DECIMAL(12,2)
DEFINE fecing_ori	DATETIME YEAR TO SECOND
DEFINE query		CHAR(400)
DEFINE mensaje		VARCHAR(130)
DEFINE resp		CHAR(6)

{--
IF codloc <> 1 AND codloc <> 3 THEN
	LET mensaje = 'Solo se puede transmitir ',
		      'transferencias de localidades ',
		      'origen 1 ó 3.'
	CALL fl_mostrar_mensaje(mensaje,'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN cod_tran, num_tran
END IF
--}
IF NOT flag THEN
	CALL fl_hacer_pregunta('Desea Reversar esta transmision (transferencia) ?',
				'No')
		RETURNING resp
	IF resp <> 'Yes' THEN
		RETURN
	END IF
END IF
CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
INITIALIZE r_r01.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia
	  AND r01_user_owner = vg_usuario
OPEN qu_vd 
FETCH qu_vd INTO r_r01.*
IF STATUS = NOTFOUND THEN
	DECLARE q_vend CURSOR FOR
		SELECT * FROM rept001
		WHERE r01_compania  = vg_codcia
		  AND r01_estado    = 'A'
		  AND r01_tipo     IN ('B','I')
		ORDER BY r01_tipo
	OPEN q_vend
	FETCH q_vend INTO r_r01.*
	CLOSE q_vend
	FREE q_vend
END IF
CLOSE qu_vd 
FREE qu_vd 
IF flag THEN
	SELECT * INTO r_r90.*
		FROM rept090
		WHERE r90_compania  = vg_codcia
		  AND r90_localidad = codloc
		  AND r90_cod_tran  = cod_tran
		  AND r90_num_tran  = num_tran  
ELSE
	SELECT * INTO r_r90.*
		FROM rept090
		WHERE r90_compania   = vg_codcia
		  AND r90_locali_fin = codloc
		  AND r90_codtra_fin = cod_tran
		  AND r90_numtra_fin = num_tran  
END IF
IF STATUS = NOTFOUND THEN
	LET mensaje = 'No existe en rept090: ', cod_tran, '-',
		       num_tran USING '<<<<<<&'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN cod_tran, num_tran
END IF
IF flag THEN
	IF r_r90.r90_codtra_fin IS NOT NULL THEN
		LET mensaje = 'La transferencia: ', cod_tran, '-',
			       num_tran USING '<<<<<<&', 
			      ' ya ha estado trasmitida.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		RETURN r_r90.r90_codtra_fin, r_r90.r90_numtra_fin
	END IF
	SELECT * INTO r_r19.*
		FROM rept091
		WHERE r91_compania  = vg_codcia
		  AND r91_localidad = codloc
		  AND r91_cod_tran  = cod_tran
		  AND r91_num_tran  = num_tran  
ELSE
	SELECT * INTO r_r19.*
		FROM rept019
		WHERE r19_compania  = r_r90.r90_compania
		  AND r19_localidad = r_r90.r90_locali_fin
		  AND r19_cod_tran  = r_r90.r90_codtra_fin
		  AND r19_num_tran  = r_r90.r90_numtra_fin
END IF
IF STATUS = NOTFOUND THEN
	LET mensaje = 'No existe en rept091: ', cod_tran, '-',
		       num_tran USING '<<<<<<&'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN cod_tran, num_tran
END IF
IF flag THEN
	INITIALIZE cod_tran, num_tran TO NULL
END IF
IF NOT flag THEN
	IF items_alterados(r_r19.*, r_r90.*) THEN
		CALL fl_mostrar_mensaje('Algunos items de esta transferencia tienen stock insuficiente o su costo promedio ha variado por otra transaccion y no se podra realizar la REVERSA.', 'exclamation')
		RETURN cod_tran, num_tran
	END IF
	IF tiene_nota_de_entrega(r_r19.*) THEN
		CALL fl_mostrar_mensaje('Uno o Alguno de los items de esta transferencia tiene(n) nota de entrega y no se podra realizar la REVERSA.', 'exclamation')
		RETURN cod_tran, num_tran
	END IF
END IF
SELECT * INTO r_r02.* FROM rept002
	WHERE r02_compania = r_r19.r19_compania AND
	      r02_codigo   = r_r19.r19_bodega_ori
IF r_r02.r02_localidad = vg_codloc THEN
	CALL fl_mostrar_mensaje('La bodega origen es de esta misma localidad.', 
				'exclamation')
	RETURN cod_tran, num_tran
END IF 
SELECT * INTO r_r02.* FROM rept002
	WHERE r02_compania = r_r19.r19_compania AND
	      r02_codigo   = r_r19.r19_bodega_dest
IF r_r02.r02_localidad != vg_codloc THEN
	CALL fl_mostrar_mensaje('La bodega destino no es de esta localidad.', 
				'exclamation')
	RETURN cod_tran, num_tran
END IF 
LET r_r19.r19_vendedor = r_r01.r01_codigo
LET r_r19.r19_usuario  = vg_usuario
LET num_tran_ori       = r_r19.r19_num_tran
LET fecing_ori         = r_r19.r19_fecing
LET r_r19.r19_fecing   = CURRENT
LET r_r19.r19_localidad= vg_codloc
BEGIN WORK
IF NOT flag THEN
	IF vg_codloc = 1 THEN
		IF NOT verificar_si_existe_cruce(codloc, cod_tran, num_tran)
		THEN
			ROLLBACK WORK	
			RETURN cod_tran, num_tran
		END IF
		IF vm_cruce THEN
			CALL proceso_cruce_de_bodegas(r_r19.*, flag)
		END IF
	END IF
	LET bod_aux               = r_r19.r19_bodega_ori
	LET r_r19.r19_bodega_ori  = r_r19.r19_bodega_dest
	LET r_r19.r19_bodega_dest = bod_aux
END IF
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA', 'TR')
	RETURNING r_r19.r19_num_tran 
IF r_r19.r19_num_tran <= 0 THEN
	ROLLBACK WORK	
	EXIT PROGRAM
END IF
IF NOT flag THEN
	LET r_r19.r19_referencia = 'TRANS. TRANSFER. REVERSADA (',
					cod_tran, '-', num_tran USING "<<<<<<&",
					')'
	LET r_r19.r19_fecing     = CURRENT
END IF
INSERT INTO rept019 VALUES (r_r19.*)
IF flag THEN
	LET bod_aux  = r_r19.r19_bodega_ori
	LET bod_aux2 = r_r19.r19_bodega_dest
	LET query    = 'SELECT * FROM rept092 ',
			' WHERE r92_compania  = ', r_r19.r19_compania,
			'   AND r92_localidad = ', r_r90.r90_localidad,
			'   AND r92_cod_tran  = "', r_r19.r19_cod_tran, '"',
			'   AND r92_num_tran  = ', num_tran_ori,
			' ORDER BY r92_orden '
ELSE
	LET bod_aux  = r_r19.r19_bodega_dest
	LET bod_aux2 = r_r19.r19_bodega_ori
	LET query    = 'SELECT * FROM rept020 ',
			' WHERE r20_compania  = ', r_r90.r90_compania,
		  	'   AND r20_localidad = ', r_r90.r90_locali_fin,
			'   AND r20_cod_tran  = "', r_r90.r90_codtra_fin, '"',
			'   AND r20_num_tran  = ', r_r90.r90_numtra_fin,
			' ORDER BY r20_orden '
END IF
PREPARE cons_dtr FROM query
DECLARE qu_dtr CURSOR FOR cons_dtr
FOREACH qu_dtr INTO r_r20.*
	IF NOT flag THEN
		LET r_r20.r20_bodega = r_r19.r19_bodega_ori
		LET r_r20.r20_fecing = CURRENT
	END IF
	LET r_r20.r20_num_tran = r_r19.r19_num_tran
	CALL fl_lee_stock_rep(vg_codcia, bod_aux, r_r20.r20_item)
		RETURNING r_stock_ori.*
	IF r_stock_ori.r11_compania IS NULL THEN
		LET r_stock_ori.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_ant       = r_stock_ori.r11_stock_act
	IF flag THEN
		LET r_stock_ori.r11_stock_act = r_stock_ori.r11_stock_act -
						r_r20.r20_cant_ven
	ELSE
		LET r_stock_ori.r11_stock_act = r_stock_ori.r11_stock_act +
						r_r20.r20_cant_ven
	END IF
	SELECT * INTO r_r10.* FROM rept010
		WHERE r10_compania = vg_codcia AND 
	      	      r10_codigo   = r_r20.r20_item
	IF r_r90.r90_localidad = 1 OR r_r90.r90_localidad = 3 OR
	   r_r90.r90_localidad = 6 OR r_r90.r90_localidad = 7 THEN
		CALL fl_obtiene_costo_item(vg_codcia, r_r19.r19_moneda,
			r_r20.r20_item, r_r20.r20_cant_ven, r_r20.r20_costo)
			RETURNING costo_nue
		LET r_r20.r20_costant_mb  = r_r10.r10_costo_mb
		LET r_r10.r10_costo_mb    = costo_nue
		LET r_r20.r20_costnue_mb  = costo_nue
		LET r_r10.r10_costult_mb  = r_r20.r20_costo
		UPDATE rept010 SET r10_costo_mb		= r_r10.r10_costo_mb,
                                   r10_costult_mb	= r_r10.r10_costult_mb
			WHERE r10_compania = vg_codcia
			  AND r10_codigo   = r_r20.r20_item
	END IF
	IF r_stock_ori.r11_stock_act >= 0 THEN
		IF localidad_bodega(bod_aux) = vg_codloc THEN
			UPDATE rept011
				SET r11_stock_act = r_stock_ori.r11_stock_act
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = bod_aux
				  AND r11_item     = r_r20.r20_item
		END IF
	END IF
	CALL fl_lee_stock_rep(vg_codcia, bod_aux2, r_r20.r20_item)
		RETURNING r_stock_des.*
	IF r_stock_des.r11_compania IS NULL THEN
		INSERT INTO rept011
      			(r11_compania, r11_bodega, r11_item, 
	 		 r11_ubicacion, r11_stock_ant, 
	 	         r11_stock_act, r11_ing_dia,
	 	         r11_egr_dia)
		VALUES(vg_codcia, bod_aux2, r_r20.r20_item, 'SN', 0, 0, 0, 0)
		LET r_stock_des.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_bd        = r_stock_des.r11_stock_act
	IF flag THEN
		LET r_stock_des.r11_stock_act = r_stock_des.r11_stock_act +
						r_r20.r20_cant_ven
	ELSE
		LET r_stock_des.r11_stock_act = r_stock_des.r11_stock_act -
						r_r20.r20_cant_ven
	END IF
	UPDATE rept011
		SET r11_stock_act = r_stock_des.r11_stock_act
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = bod_aux2
		  AND r11_item     = r_r20.r20_item
	LET r_r20.r20_fecing    = r_r19.r19_fecing
	LET r_r20.r20_localidad = r_r19.r19_localidad
	INSERT INTO rept020 VALUES (r_r20.*)
END FOREACH
IF flag THEN
	INITIALIZE r_r90_aux.* TO NULL
	SELECT * INTO r_r90_aux.* FROM rept090
		WHERE r90_compania  = r_r90.r90_compania
		  AND r90_localidad = r_r90.r90_localidad
		  AND r90_cod_tran  = r_r90.r90_cod_tran
		  AND r90_num_tran  = r_r90.r90_num_tran
	IF r_r90_aux.r90_codtra_fin IS NOT NULL THEN
		ROLLBACK WORK
		LET mensaje = 'La transferencia: ', r_r90.r90_cod_tran, '-',
				r_r90.r90_num_tran USING '<<<<<<&',
				' ya ha sido trasmitida.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		RETURN r_r90_aux.r90_codtra_fin, r_r90_aux.r90_numtra_fin
	END IF
END IF
IF flag THEN
	UPDATE rept090
		SET r90_codtra_fin = r_r20.r20_cod_tran,
    		    r90_numtra_fin = r_r20.r20_num_tran,
    		    r90_fecing_fin = r_r19.r19_fecing
		WHERE r90_compania  = r_r90.r90_compania
		  AND r90_localidad = r_r90.r90_localidad
		  AND r90_cod_tran  = r_r90.r90_cod_tran
		  AND r90_num_tran  = r_r90.r90_num_tran
	IF vg_codloc = 1 THEN
		CALL proceso_cruce_de_bodegas(r_r19.*, flag)
	END IF
ELSE
	INSERT INTO rept042
		VALUES(vg_codcia, vg_codloc, cod_tran, num_tran,
			r_r19.r19_cod_tran, r_r19.r19_num_tran)
	IF vg_codloc = 1 THEN
		IF vm_cruce THEN
			UPDATE tmp_r41
				SET r41_cod_tran = r_r19.r19_cod_tran,
				    r41_num_tran = r_r19.r19_num_tran
				WHERE 1 = 1
			INSERT INTO rept041 SELECT * FROM tmp_r41
			DROP TABLE tmp_r41
		END IF
	END IF
END IF
COMMIT WORK
CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc,r_r19.r19_cod_tran,
					r_r19.r19_num_tran)
IF NOT flag THEN
	CALL enviar_transferencia_otra_loc(r_r19.*)
END IF
LET mensaje = 'Proceso terminado Ok., verifique e imprima la transferencia ',
	      'generada.'
CALL fl_mostrar_mensaje(mensaje, 'info')
IF tiene_facturas_cruce(r_r19.*) THEN
	CALL muestra_fact_items_cruce(r_r19.*)
END IF
LET vm_cruce = 0
RETURN r_r19.r19_cod_tran, r_r19.r19_num_tran

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo,cod_clase,flag)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE flag		SMALLINT
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
IF flag THEN
	DISPLAY r_r03.r03_nombre     TO descrip_1
	DISPLAY r_r70.r70_desc_sub   TO descrip_2
	DISPLAY r_r71.r71_desc_grupo TO descrip_3
	DISPLAY r_r10.r10_marca      TO nom_marca
ELSE
	DISPLAY r_r10.r10_nombre TO nom_item
END IF
DISPLAY r_r72.r72_desc_clase TO descrip_4

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
		DISPLAY 'TRANSMITIDAS' TO tit_estado
	WHEN 'D'
		DISPLAY 'T O D A S'    TO tit_estado
END CASE

END FUNCTION



FUNCTION obtener_localidad()

IF rm_g02.g02_localidad IS NULL THEN
	CASE vg_codloc
		WHEN 1
			LET rm_g02.g02_localidad = 3
		WHEN 2
			LET rm_g02.g02_localidad = 1
		WHEN 3
			LET rm_g02.g02_localidad = 1
		WHEN 4
			LET rm_g02.g02_localidad = 3
		WHEN 5
			LET rm_g02.g02_localidad = 3
	END CASE
END IF
CALL fl_lee_localidad(vg_codcia, rm_g02.g02_localidad) RETURNING rm_g02.*
DISPLAY BY NAME rm_g02.g02_localidad, rm_g02.g02_nombre

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_etiquetas_det(i, ind1, ind2)
DEFINE i, ind1, ind2	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, ind1)
CALL fl_lee_item(vg_codcia, r_detalle[ind2].r92_item) RETURNING r_r10.*  
CALL muestra_descripciones(r_detalle[ind2].r92_item, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase, 1)
DISPLAY r_r10.r10_nombre TO nom_item 

END FUNCTION



FUNCTION control_imprimir(codloc, cod_tran, num_tran)
DEFINE codloc		LIKE rept091.r91_localidad
DEFINE cod_tran		LIKE rept091.r91_cod_tran
DEFINE num_tran		LIKE rept091.r91_num_tran
DEFINE comando		CHAR(255)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp415 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', codloc, ' "', cod_tran, '" ', num_tran,' "O"'
RUN comando	

END FUNCTION



FUNCTION items_alterados(r_r19, r_r90)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE contador		SMALLINT
DEFINE num_det		SMALLINT

SELECT COUNT(*) INTO contador
	FROM rept020, rept011, rept010
	WHERE r20_compania   = vg_codcia
	  AND r20_localidad  = vg_codloc
	  AND r20_cod_tran   = r_r19.r19_cod_tran
	  AND r20_num_tran   = r_r19.r19_num_tran
	  AND NOT EXISTS(SELECT 1 FROM rept019
				WHERE r19_compania  = r20_compania
				  AND r19_localidad = r_r90.r90_locali_fin
				  AND r19_cod_tran  = r_r90.r90_codtra_fin
				  AND r19_num_tran  = r_r90.r90_numtra_fin)
	  AND r11_compania   = r20_compania
	  AND r11_bodega     = r_r19.r19_bodega_ori
	  AND r11_item       = r20_item
	  --AND r11_stock_act  = r20_stock_ant + r20_cant_ven
	  AND r11_stock_act >= r20_cant_ven
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
	  AND r10_costo_mb   = r20_costnue_mb
SELECT COUNT(*) INTO num_det
	FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = r_r19.r19_cod_tran
	  AND r20_num_tran  = r_r19.r19_num_tran
	  AND NOT EXISTS(SELECT 1 FROM rept019
				WHERE r19_compania  = r20_compania
				  AND r19_localidad = r_r90.r90_locali_fin
				  AND r19_cod_tran  = r_r90.r90_codtra_fin
				  AND r19_num_tran  = r_r90.r90_numtra_fin)
IF num_det = contador THEN
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION tiene_nota_de_entrega(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE contador		SMALLINT

SELECT COUNT(r37_item)
	INTO contador
	FROM rept020, rept036, rept037
	WHERE r20_compania      = r_r19.r19_compania
	  AND r20_localidad     = r_r19.r19_localidad
	  AND r20_cod_tran      = r_r19.r19_cod_tran
	  AND r20_num_tran      = r_r19.r19_num_tran
	  AND r36_compania      = r20_compania
	  AND r36_localidad     = r20_localidad
	  AND r36_estado        = "A"
	  AND r36_fecing       >= r20_fecing
	  AND r37_compania      = r36_compania
	  AND r37_localidad     = r36_localidad
	  AND r37_bodega        = r36_bodega
	  AND r37_num_entrega   = r36_num_entrega
	  AND r37_item          = r20_item
IF contador > 0 THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION verificar_si_existe_cruce(codloc, cod_tran, num_tran)
DEFINE codloc		LIKE rept091.r91_localidad
DEFINE cod_tran		LIKE rept091.r91_cod_tran
DEFINE num_tran		LIKE rept091.r91_num_tran
DEFINE r_r41		RECORD LIKE rept041.*
DEFINE resp		CHAR(6)

IF vm_cruce THEN
	LET vm_cruce = 0
	RETURN 1
END IF
INITIALIZE r_r41.* TO NULL
DECLARE q_trans CURSOR FOR
	SELECT b.* FROM rept041 b
		WHERE b.r41_compania  = vg_codcia
		  AND b.r41_localidad = codloc
		  AND b.r41_cod_tran  = cod_tran
		  AND b.r41_num_tran  = num_tran
		  AND NOT EXISTS
			(SELECT 1 FROM rept041 a
				WHERE a.r41_compania  = b.r41_compania
				  AND a.r41_localidad = b.r41_localidad
				  AND a.r41_cod_tran  IN ('DF', 'AF', 'DC')
				  AND a.r41_cod_tr    = b.r41_cod_tr
				  AND a.r41_num_tr    = b.r41_num_tr)
OPEN q_trans
FETCH q_trans INTO r_r41.*
IF r_r41.r41_compania IS NULL THEN
	CLOSE q_trans
	FREE q_trans
	RETURN 1
END IF
CALL fl_hacer_pregunta('Desea DESHACER transferencias de CRUCE AUTOMATICO ?',
			'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	CLOSE q_trans
	FREE q_trans
	RETURN 0
END IF
LET vm_cruce = 1
SELECT * FROM rept041 WHERE r41_compania = 999 INTO TEMP tmp_r41
RETURN 1

END FUNCTION



FUNCTION proceso_cruce_de_bodegas(r_r19, flag)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE flag		SMALLINT
DEFINE r_rep		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha		LIKE rept020.r20_fecing,
				bodega		LIKE rept020.r20_bodega,
				item		LIKE rept020.r20_item,
				cant_pend	LIKE rept020.r20_cant_ven,
				cant_desp	LIKE rept020.r20_cant_ven,
				stock_act	LIKE rept011.r11_stock_act
			END RECORD
DEFINE r_fact		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha		LIKE rept020.r20_fecing,
				bodega		LIKE rept020.r20_bodega,
				r19_nomcli	LIKE rept019.r19_nomcli,
				r19_vendedor	LIKE rept019.r19_vendedor
			END RECORD
DEFINE aux_i		LIKE rept011.r11_item
DEFINE cant		LIKE rept011.r11_stock_act
DEFINE tot_cant_des	LIKE rept011.r11_stock_act
DEFINE num_f		LIKE rept020.r20_num_tran

IF NOT verificar_item_bodega_sin_stock(r_r19.*) THEN
	RETURN
END IF
DECLARE q_sto CURSOR WITH HOLD FOR
	SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item,
		cant_pend, cant_desp, NVL(r11_stock_act, 0)
		FROM temp_pend, t_r11
		WHERE r11_compania  = vg_codcia
		  AND r11_bodega    = r_r19.r19_bodega_ori
		  AND r11_item      = r20_item
		  AND r11_stock_act > 0
		ORDER BY fecha ASC, r20_num_tran ASC
LET cant  = 0
LET aux_i = NULL
FOREACH q_sto INTO r_rep.*
--display 'cant antes ', r_rep.cod_tran, '-', r_rep.num_tran, '  ', r_rep.cant_desp
	LET r_rep.cant_desp = retorna_cant_tr(r_rep.bodega, r_rep.item,
						r_rep.cod_tran, r_rep.num_tran)
--display 'cant despues ', r_rep.cod_tran, '-', r_rep.num_tran, '  ', r_rep.cant_desp
	IF aux_i IS NULL OR aux_i <> r_rep.item THEN
		SELECT NVL(SUM(cant_desp), 0)
			INTO tot_cant_des
			FROM temp_pend, t_r11
			WHERE r11_compania  = vg_codcia
			  AND r11_bodega    = r_r19.r19_bodega_ori
			  AND r11_item      = r_rep.item
			  AND r11_stock_act > 0
			  AND r20_cod_tran  = r_rep.cod_tran
			  AND r20_num_tran  < r_rep.num_tran
			  AND r20_item      = r11_item
			  AND fecha         < r_rep.fecha
		LET cant = r_rep.stock_act - tot_cant_des
	END IF
	IF r_rep.cant_desp <= cant THEN
		LET cant = cant - r_rep.cant_desp
	ELSE
		LET r_rep.cant_desp = cant
		LET cant            = 0
	END IF
	UPDATE temp_pend
		SET cant_desp = r_rep.cant_desp
		WHERE r20_cod_tran = r_rep.cod_tran
		  AND r20_num_tran = r_rep.num_tran
		  AND r20_bodega   = r_rep.bodega
		  AND r20_item     = r_rep.item
	LET aux_i = r_rep.item
END FOREACH
DECLARE q_fact CURSOR WITH HOLD FOR
	SELECT UNIQUE r20_cod_tran, r20_num_tran, fecha, r20_bodega,
		r19_nomcli, r19_vendedor
		FROM temp_pend
		ORDER BY fecha ASC, r20_num_tran ASC
LET num_f = NULL
FOREACH q_fact INTO r_fact.*
	IF NOT flag THEN
		SELECT * FROM rept041, rept019
			WHERE r41_compania  = r_r19.r19_compania
			  AND r41_localidad = r_r19.r19_localidad
			  AND r41_cod_tran  = r_r19.r19_cod_tran
			  AND r41_num_tran  = r_r19.r19_num_tran
			  AND r19_compania  = r41_compania
			  AND r19_localidad = r41_localidad
			  AND r19_cod_tran  = r41_cod_tr
			  AND r19_num_tran  = r41_num_tr
			  AND r19_tipo_dev  = r_fact.cod_tran
			  AND r19_num_dev   = r_fact.num_tran
		IF STATUS = NOTFOUND THEN
			CONTINUE FOREACH
		END IF
	END IF
--display r_fact.*
	IF num_f IS NULL OR r_fact.num_tran <> num_f THEN
		CALL transferir_item_bod_ss_bod_res(r_fact.*, r_r19.*, flag)
	END IF
	LET num_f = r_fact.num_tran
END FOREACH
--rollback work
--exit program
CALL dropear_tablas_tmp()
IF flag THEN
	CALL fl_mostrar_mensaje('Transferencias por CRUCE de BODEGA "SIN STOCK" con la bodega ' || r_r19.r19_bodega_dest CLIPPED || ' generadas OK.', 'info')
ELSE
	CALL fl_mostrar_mensaje('Transferencias para DESHACER CRUCE de BODEGA "SIN STOCK" con la bodega ' || r_r19.r19_bodega_ori CLIPPED || ' generadas OK.', 'info')
END IF

END FUNCTION



FUNCTION verificar_item_bodega_sin_stock(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE query		CHAR(1200)
DEFINE cuantos		INTEGER

MESSAGE 'Generando consulta . . . espere por favor'
SELECT r10_sec_item r10_codigo, r10_nombre, r11_stock_act stock_pend,
	r11_stock_act stock_tot, r11_stock_act stock_loc, r10_stock_max,
	r10_stock_min
	FROM rept010, rept011
	WHERE r10_compania  = 17
	  AND r11_compania  = r10_compania
	  AND r11_item      = r10_codigo
	INTO TEMP t_item
SELECT r10_codigo item, stock_loc stock_l FROM t_item INTO TEMP t_item_loc
SELECT r02_compania, r02_codigo, r02_nombre, r02_localidad
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_tipo     <> "S"
	  AND r02_estado    = "A"
	  --AND r02_tipo      = "S"
	INTO TEMP t_bod
SELECT r20_item item_p
	FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = r_r19.r19_cod_tran
	  AND r20_num_tran  = r_r19.r19_num_tran
	INTO TEMP tmp_ite_cl
LET query = ' SELECT r10_codigo, r10_nombre, 0 stock_p1, 0 stock_t1, ',
			' 0 stock_l1, r10_stock_max, r10_stock_min ',
		' FROM rept010 ',
		' WHERE r10_compania  = ', vg_codcia,
		'   AND r10_codigo   IN (SELECT item_p FROM tmp_ite_cl) ',
		' INTO TEMP t_r10 '
PREPARE pre_r10 FROM query
EXECUTE pre_r10
LET query = ' SELECT r20_compania r11_compania, r20_bodega r11_bodega, ',
			'r20_item r11_item, r20_cant_ven r11_stock_act ',
		' FROM rept019, rept020 ',
		' WHERE r19_compania   = ', vg_codcia,
		'   AND r19_localidad  = ', vg_codloc,
		'   AND r19_cod_tran   = "', r_r19.r19_cod_tran, '"',
		'   AND r19_num_tran   = ', r_r19.r19_num_tran,
		'   AND r20_compania   = r19_compania ',
		'   AND r20_localidad  = r19_localidad ',
		'   AND r20_cod_tran   = r19_cod_tran ',
		'   AND r20_num_tran   = r19_num_tran ',
		'   AND r20_item      IN (SELECT r10_codigo FROM t_r10) ',
		' INTO TEMP t_r11 '
PREPARE pre_r11 FROM query
EXECUTE pre_r11
SELECT r11_item r10_codigo, NVL(SUM(r11_stock_act), 0) stock_t
	FROM t_r11
	GROUP BY 1
	INTO TEMP t_item_tot
CASE vg_codloc
	WHEN 1
		LET codloc  = 2
	WHEN 2
		LET codloc  = 1
	WHEN 3
		LET codloc  = 4
	WHEN 4
		LET codloc  = 3
END CASE
LET query = 'INSERT INTO t_item_loc ',
		' SELECT r11_item, NVL(SUM(r11_stock_act), 0) stock_l ',
			' FROM t_r11 ',
			' WHERE r11_bodega IN ',
				'(SELECT r02_codigo FROM t_bod ',
				' WHERE r02_localidad IN (', vg_codloc, ', ',
								codloc, ')) ',
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
	MESSAGE 'No se encontraron registros.'
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	DROP TABLE tmp_ite_cl
	MESSAGE '                                         '
	RETURN 0
END IF
LET vm_stock_pend = obtener_stock_pendiente()
IF NOT vm_stock_pend THEN
	MESSAGE 'No se encontraron registros pendientes.'
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	DROP TABLE tmp_ite_cl
	LET vm_stock_pend = 0
	MESSAGE '                                         '
	RETURN 0
END IF
IF vm_stock_pend THEN
	LET query = ' SELECT r10_codigo, r10_nombre, ',
				' NVL(SUM(cant_pend), 0) stock_pend, ',
				'stock_tot, stock_loc, r10_stock_max, ',
				'r10_stock_min ',
			' FROM t_item, temp_pend',
			' WHERE r10_codigo = r20_item ',
			' GROUP BY 1, 2, 4, 5, 6, 7 ',
			' INTO TEMP temp_item_pen'
	PREPARE pre_item FROM query
	EXECUTE pre_item
ELSE
	SELECT * FROM t_item INTO TEMP temp_item_pen
END IF
DROP TABLE t_item
--CALL mostrar_detalle_item()
--DROP TABLE temp_item_pen
MESSAGE '                                         '
RETURN 1

END FUNCTION



FUNCTION obtener_bod_sin_stock()
DEFINE query		CHAR(800)

LET query = 'SELECT r02_codigo FROM rept002 ',
		' WHERE r02_compania  = ', vg_codcia,
		'   AND r02_localidad = ', vg_codloc,
		'   AND r02_factura   = "S" ',
		'   AND r02_tipo      = "S" ',
		'   AND r02_area      = "R" ',
		' INTO TEMP t_bd1 '
PREPARE cons_bod FROM query
EXECUTE cons_bod

END FUNCTION



FUNCTION obtener_stock_pendiente()
DEFINE cuantos		INTEGER
DEFINE query		CHAR(800)

CALL obtener_bod_sin_stock()
SELECT r20_cod_tran, r20_num_tran, r20_fecing fecha, r20_bodega, r20_item,
	r20_cant_ven
	FROM rept020
	WHERE r20_compania   = vg_codcia
	  AND r20_localidad  = vg_codloc
	  AND r20_cod_tran  IN ("FA", "DF")
	  AND r20_bodega    IN (SELECT r02_codigo FROM t_bd1)
	  AND r20_item      IN (SELECT r10_codigo FROM t_item)
	INTO TEMP t_r20
SELECT r19_cod_tran, r19_num_tran, r19_nomcli, r19_vendedor, r19_tipo_dev,
	r19_num_dev
	FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = "FA"
	  AND (r19_tipo_dev = "DF" OR r19_tipo_dev IS NULL)
UNION ALL
SELECT r19_cod_tran, r19_num_tran, r19_nomcli, r19_vendedor, r19_tipo_dev,
	r19_num_dev
	FROM rept019
	WHERE r19_compania   = vg_codcia
	  AND r19_localidad  = vg_codloc
	  AND r19_cod_tran   = "DF"
	INTO TEMP t_r19
SELECT c.*, d.r19_nomcli, d.r19_vendedor
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
		  AND ite = r20_item), 0) r20_cant_ven, r19_nomcli, r19_vendedor
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
		r34_num_ord_des, r19_nomcli, r19_vendedor
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
	r20_item, cantidad cant_pend, r19_nomcli, r19_vendedor,
	cantidad cant_desp
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
SELECT a.r20_cod_tran, a.r20_num_tran, a.fecha, a.r35_num_ord_des, a.r20_bodega,
	a.r20_item, a.cant_pend, a.r19_nomcli, a.r19_vendedor, a.cant_desp,
	NVL(SUM(c.r20_cant_ven), 0) * (-1) cant_tr
	FROM temp_pend a, OUTER rept019 b, rept020 c
	WHERE b.r19_compania   = vg_codcia
	  AND b.r19_localidad  = vg_codloc
	  AND b.r19_cod_tran   = 'TR'
	  AND b.r19_bodega_ori = a.r20_bodega
	  AND b.r19_tipo_dev   = a.r20_cod_tran
	  AND b.r19_num_dev    = a.r20_num_tran
	  AND c.r20_compania   = b.r19_compania
	  AND c.r20_localidad  = b.r19_localidad
	  AND c.r20_cod_tran   = b.r19_cod_tran
	  AND c.r20_num_tran   = b.r19_num_tran
	  AND c.r20_item       = a.r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT a.r20_cod_tran, a.r20_num_tran, a.fecha, a.r35_num_ord_des, a.r20_bodega,
	a.r20_item, a.cant_pend, a.r19_nomcli, a.r19_vendedor, a.cant_desp,
	NVL(SUM(c.r20_cant_ven), 0) cant_tr
	FROM temp_pend a, OUTER rept019 b, rept020 c
	WHERE b.r19_compania    = vg_codcia
	  AND b.r19_localidad   = vg_codloc
	  AND b.r19_cod_tran    = 'TR'
	  AND b.r19_bodega_dest = a.r20_bodega
	  AND b.r19_tipo_dev    = a.r20_cod_tran
	  AND b.r19_num_dev     = a.r20_num_tran
	  AND c.r20_compania    = b.r19_compania
	  AND c.r20_localidad   = b.r19_localidad
	  AND c.r20_cod_tran    = b.r19_cod_tran
	  AND c.r20_num_tran    = b.r19_num_tran
	  AND c.r20_item        = a.r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	INTO TEMP t4
DROP TABLE temp_pend
SELECT r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cant_pend, r19_nomcli, r19_vendedor, cant_desp,
	NVL(SUM(cant_tr), 0) cant_tr
	FROM t4
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	INTO TEMP t5
DROP TABLE t4
SELECT r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cant_pend - cant_tr cant_pend, r19_nomcli, r19_vendedor,
	cant_desp - cant_tr cant_desp
	FROM t5
	INTO TEMP temp_pend
DROP TABLE t5
RETURN 1

END FUNCTION



FUNCTION mostrar_detalle_item()
DEFINE r_ite		RECORD
				codigo		LIKE rept010.r10_codigo,
				nombre		LIKE rept010.r10_nombre,
				stock_pend	DECIMAL(10,2),
				stock_tot	DECIMAL(10,2),
				stock_loc	DECIMAL(10,2),
				sto_max		LIKE rept010.r10_stock_max,
				sto_min		LIKE rept010.r10_stock_min
			END RECORD
DEFINE i		SMALLINT

DECLARE q_item CURSOR FOR SELECT * FROM temp_item_pen
DISPLAY ' '
LET i = 1
FOREACH q_item INTO r_ite.*
	DISPLAY 'ITEM: ', r_ite.codigo CLIPPED, ' ', r_ite.nombre CLIPPED
	DISPLAY '  Sto. Pend. ', r_ite.stock_pend USING "---,--&.##"
	--DISPLAY '  Sto. Tot.  ', r_ite.stock_tot  USING "---,--&.##"
	--DISPLAY '  Sto. Loc.  ', r_ite.stock_loc  USING "---,--&.##"
	DISPLAY ' '
	LET i = i + 1
END FOREACH
LET i = i - 1
IF i > 0 THEN
	DISPLAY 'Se encontraron un total de ', i USING "<<<<&", ' ITEMS. OK'
END IF

END FUNCTION



FUNCTION transferir_item_bod_ss_bod_res(r_fact, r_trans, flag)
DEFINE r_fact		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha		LIKE rept020.r20_fecing,
				bodega		LIKE rept020.r20_bodega,
				r19_nomcli	LIKE rept019.r19_nomcli,
				r19_vendedor	LIKE rept019.r19_vendedor
			END RECORD
DEFINE r_trans		RECORD LIKE rept019.*
DEFINE flag		SMALLINT
DEFINE r_fact_i		RECORD
				item		LIKE rept020.r20_item,
				cant_desp	LIKE rept020.r20_cant_ven
			END RECORD
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE cod_tr		LIKE rept041.r41_cod_tr
DEFINE num_tr		LIKE rept041.r41_num_tr
DEFINE fec		LIKE rept020.r20_fecing
DEFINE cant_d		LIKE rept020.r20_cant_ven
DEFINE stock_act	LIKE rept011.r11_stock_act
DEFINE mensaje		VARCHAR(200)
DEFINE num_tran		VARCHAR(15)
DEFINE conta, cont, j	INTEGER
DEFINE query		CHAR(1000)
DEFINE expr_can		VARCHAR(100)

LET expr_can = NULL
IF flag THEN
	LET expr_can = '   AND cant_desp    > 0 '
END IF
LET query = 'SELECT r20_item, cant_desp ',
		' FROM temp_pend ',
		' WHERE r20_cod_tran = "', r_fact.cod_tran, '"',
		'   AND r20_num_tran = ', r_fact.num_tran,
		'   AND r20_bodega   = "', r_fact.bodega, '"',
		expr_can CLIPPED,
		' ORDER BY r20_item ASC '
PREPARE cons_fact_i FROM query
DECLARE q_fact_i CURSOR FOR cons_fact_i
OPEN q_fact_i
FETCH q_fact_i INTO r_fact_i.*
IF STATUS = NOTFOUND THEN
	CLOSE q_fact_i
	FREE q_fact_i
	RETURN
END IF
INITIALIZE r_r19.*, r_fact_i.* TO NULL
LET r_r19.r19_compania		= vg_codcia
LET r_r19.r19_localidad   	= vg_codloc
LET r_r19.r19_cod_tran    	= 'TR'
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA',
					r_r19.r19_cod_tran)
	RETURNING r_r19.r19_num_tran
IF r_r19.r19_num_tran = 0 THEN
	ROLLBACK WORK	
	CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
	EXIT PROGRAM
END IF
IF r_r19.r19_num_tran = -1 THEN
	SET LOCK MODE TO WAIT
	WHILE r_r19.r19_num_tran = -1
		CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 
							vg_modulo, 'AA',
							r_r19.r19_cod_tran)
			RETURNING r_r19.r19_num_tran
	END WHILE
	SET LOCK MODE TO NOT WAIT
END IF
LET r_r19.r19_cont_cred		= 'C'
LET r_r19.r19_referencia	= 'TR. AUTO. TR-',
					r_trans.r19_num_tran USING "<<<<<&",' ',
					r_fact.cod_tran CLIPPED, '-',
					r_fact.num_tran USING "<<<<<<&"
IF flag THEN
	LET r_r19.r19_referencia = r_r19.r19_referencia CLIPPED, ' SIN STOCK'
ELSE
	LET r_r19.r19_referencia = r_r19.r19_referencia CLIPPED, ' (REVERSA)'
END IF
LET r_r19.r19_nomcli		= ' '
LET r_r19.r19_dircli     	= ' '
LET r_r19.r19_cedruc     	= ' '
LET r_r19.r19_vendedor   	= r_fact.r19_vendedor
LET r_r19.r19_descuento  	= 0.0
LET r_r19.r19_porc_impto 	= 0.0
LET r_r19.r19_tipo_dev          = r_fact.cod_tran
LET r_r19.r19_num_dev           = r_fact.num_tran
LET r_r19.r19_bodega_ori 	= r_trans.r19_bodega_dest
LET r_r19.r19_bodega_dest	= r_fact.bodega
IF NOT flag THEN
	LET r_r19.r19_bodega_dest = r_trans.r19_bodega_dest
	LET r_r19.r19_bodega_ori  = r_fact.bodega
END IF
LET r_r19.r19_moneda     	= rg_gen.g00_moneda_base
LET r_r19.r19_precision  	= rg_gen.g00_decimal_mb
LET r_r19.r19_paridad    	= 1
LET r_r19.r19_tot_costo  	= 0
LET r_r19.r19_tot_bruto  	= 0.0
LET r_r19.r19_tot_dscto  	= 0.0
LET r_r19.r19_tot_neto		= r_r19.r19_tot_costo
LET r_r19.r19_flete      	= 0.0
LET r_r19.r19_usuario      	= vg_usuario
LET r_r19.r19_fecing      	= CURRENT
INSERT INTO rept019 VALUES (r_r19.*)
INITIALIZE r_r20.* TO NULL
LET r_r20.r20_compania		= vg_codcia
LET r_r20.r20_localidad  	= vg_codloc
LET r_r20.r20_cod_tran   	= r_r19.r19_cod_tran
LET r_r20.r20_num_tran   	= r_r19.r19_num_tran
LET r_r20.r20_cant_ent   	= 0 
LET r_r20.r20_cant_dev   	= 0
LET r_r20.r20_descuento  	= 0.0
LET r_r20.r20_val_descto 	= 0.0
LET r_r20.r20_val_impto  	= 0.0
LET r_r20.r20_ubicacion  	= 'SN'
LET j = 1
LET conta = 0
FOREACH q_fact_i INTO r_fact_i.*
	CALL fl_lee_item(vg_codcia, r_fact_i.item) RETURNING r_r10.*
	IF flag THEN
		LET cant_d = r_fact_i.cant_desp
	ELSE
		DECLARE q_cant_d CURSOR FOR
			SELECT r41_cod_tr, r41_num_tr, r20_fecing,
				NVL(r20_cant_ven, 0)
				FROM rept041, rept020
				WHERE r41_compania  = r_trans.r19_compania
				  AND r41_localidad = r_trans.r19_localidad
				  AND r41_cod_tran  = r_trans.r19_cod_tran
				  AND r41_num_tran  = r_trans.r19_num_tran
				  AND r20_compania  = r41_compania
				  AND r20_localidad = r41_localidad
				  AND r20_cod_tran  = r41_cod_tr
				  AND r20_num_tran  = r41_num_tr
				  AND r20_bodega    = r_trans.r19_bodega_dest
				  AND r20_item      = r_fact_i.item
				ORDER BY 3 ASC, 1 ASC, 2 ASC
		OPEN q_cant_d
		WHILE TRUE
			FETCH q_cant_d INTO cod_tr, num_tr, fec, cant_d
			SELECT COUNT(r20_item) INTO cont
				FROM tmp_r41, rept020
				WHERE r41_cod_tran  = r_trans.r19_cod_tran
				  AND r41_num_tran  = r_trans.r19_num_tran
				  AND r20_compania  = r41_compania
				  AND r20_localidad = r41_localidad
				  AND r20_cod_tran  = r41_cod_tr
				  AND r20_num_tran  = r41_num_tr
				  AND r20_item      = r_fact_i.item
--display 'while ', cod_tr, '-', num_tr, ' ', cant_d, '  ', conta, ' ', cont
			IF conta = cont THEN
				EXIT WHILE
			ELSE
				LET conta = conta + 1
			END IF
		END WHILE
		CLOSE q_cant_d
		FREE q_cant_d
	END IF
	LET r_r19.r19_tot_costo  = r_r19.r19_tot_costo + 
				  (cant_d * r_r10.r10_costo_mb)
	LET r_r20.r20_cant_ped   = cant_d
	LET r_r20.r20_cant_ven   = cant_d
	LET r_r20.r20_bodega     = r_r19.r19_bodega_ori
	LET r_r20.r20_item       = r_fact_i.item 
	LET r_r20.r20_costo      = r_r10.r10_costo_mb 
	LET r_r20.r20_orden      = j
	LET r_r20.r20_fob        = r_r10.r10_fob 
	LET r_r20.r20_linea      = r_r10.r10_linea 
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion 
	LET r_r20.r20_precio     = r_r10.r10_precio_mb
	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, r_fact_i.item)
		RETURNING r_r11.*
	IF r_r11.r11_compania IS NOT NULL THEN
		CALL fl_lee_bodega_rep(r_r11.r11_compania, r_r11.r11_bodega)
			RETURNING r_r02.*
		IF r_r02.r02_tipo <> 'S' THEN
--display 'item: ', r_fact_i.item, ' bod: ', r_r11.r11_bodega, ' stock: ', r_r11.r11_stock_act, ' cant: ', cant_d
			LET stock_act = r_r11.r11_stock_act - cant_d
			IF stock_act < 0 THEN
				ROLLBACK WORK
				LET mensaje = 'ERROR: El item ',
						r_r11.r11_item CLIPPED,
						' tiene stock insuficiente, ',
						'para'
				IF flag THEN
					LET mensaje = mensaje CLIPPED,
							' GENERAR'
				ELSE
					LET mensaje = mensaje CLIPPED,
							' REVERSAR'
				END IF
				LET mensaje = mensaje CLIPPED, ' el CRUCE',
						' AUTOMATICO. Llame al',
						'ADMINISTRADOR.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				EXIT PROGRAM
			END IF
		END IF
	END IF
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_ant  = r_r11.r11_stock_act 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, r_fact_i.item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act 
	LET r_r20.r20_fecing	 = CURRENT
	INSERT INTO rept020 VALUES(r_r20.*)
	UPDATE rept011
		SET r11_stock_act = r11_stock_act - cant_d,
		    r11_egr_dia   = r11_egr_dia   + cant_d
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = r_r19.r19_bodega_ori
		  AND r11_item     = r_fact_i.item 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, r_fact_i.item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		INSERT INTO rept011
      			(r11_compania, r11_bodega, r11_item, r11_ubicacion,
			 r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
		VALUES(vg_codcia, r_r19.r19_bodega_dest, r_fact_i.item, 'SN',
			0, cant_d, cant_d, 0) 
	ELSE
		UPDATE rept011 
			SET r11_stock_act = r11_stock_act + cant_d,
	      		    r11_ing_dia   = r11_ing_dia   + cant_d
			WHERE r11_compania  = vg_codcia
			  AND r11_bodega    = r_r19.r19_bodega_dest
			  AND r11_item      = r_fact_i.item 
	END IF
	UPDATE temp_item_pen
		SET stock_pend = stock_pend - cant_d
		WHERE r10_codigo = r_fact_i.item
	LET j = j + 1
	--display '   transf ', r_r20.r20_num_tran, ' ', r_r20.r20_cant_ven, ' item ', r_r20.r20_item
	LET conta = 0
END FOREACH
--display '   transf ', r_r19.r19_num_tran
UPDATE rept019
	SET r19_tot_costo = r_r19.r19_tot_costo,
	    r19_tot_bruto = r_r19.r19_tot_bruto,
	    r19_tot_neto  = r_r19.r19_tot_bruto
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = r_r19.r19_cod_tran
	  AND r19_num_tran  = r_r19.r19_num_tran
IF flag THEN
	INSERT INTO rept041
		VALUES(vg_codcia, vg_codloc, r_trans.r19_cod_tran,
			r_trans.r19_num_tran, r_r19.r19_cod_tran,
			r_r19.r19_num_tran)
ELSE
	INSERT INTO tmp_r41
		VALUES(vg_codcia, vg_codloc, r_trans.r19_cod_tran,
			r_trans.r19_num_tran, r_r19.r19_cod_tran,
			r_r19.r19_num_tran)
END IF
{
LET num_tran = r_r19.r19_num_tran
CALL fl_mostrar_mensaje('Se genero transferencia automatica No. ' ||
			num_tran || '. De la bodega ' || r_r19.r19_bodega_ori ||
			' a la bodega ' || r_r19.r19_bodega_dest || '.','info')
}

END FUNCTION



FUNCTION retorna_cant_tr(bodega, item, cod_tran, num_tran)
DEFINE bodega		LIKE rept020.r20_bodega
DEFINE item		LIKE rept020.r20_item
DEFINE cod_tran		LIKE rept020.r20_cod_tran
DEFINE num_tran		LIKE rept020.r20_num_tran
DEFINE cant		DECIMAL(8,2)
DEFINE cant_fac		DECIMAL(8,2)
DEFINE cant_tra		DECIMAL(8,2)

SELECT NVL(SUM(r20_cant_ven), 0) INTO cant_fac
	FROM rept019, rept020
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = cod_tran
	  AND r19_num_tran  = num_tran
	  AND r20_compania  = r19_compania
	  AND r20_localidad = r19_localidad
	  AND r20_cod_tran  = r19_cod_tran
	  AND r20_num_tran  = r19_num_tran
	  AND r20_bodega    = bodega
	  AND r20_item      = item
SELECT NVL(SUM(r20_cant_ven), 0) * (-1) cant_tr
	FROM rept019, rept020
	WHERE r19_compania   = vg_codcia
	  AND r19_localidad  = vg_codloc
	  AND r19_cod_tran   = 'TR'
	  AND r19_bodega_ori = bodega
	  AND r19_tipo_dev   = cod_tran
	  AND r19_num_dev    = num_tran
	  AND r20_compania   = r19_compania
	  AND r20_localidad  = r19_localidad
	  AND r20_cod_tran   = r19_cod_tran
	  AND r20_num_tran   = r19_num_tran
	  AND r20_item       = item
UNION
SELECT NVL(SUM(r20_cant_ven), 0) cant_tr
	FROM rept019, rept020
	WHERE r19_compania    = vg_codcia
	  AND r19_localidad   = vg_codloc
	  AND r19_cod_tran    = 'TR'
	  AND r19_bodega_dest = bodega
	  AND r19_tipo_dev    = cod_tran
	  AND r19_num_dev     = num_tran
	  AND r20_compania    = r19_compania
	  AND r20_localidad   = r19_localidad
	  AND r20_cod_tran    = r19_cod_tran
	  AND r20_num_tran    = r19_num_tran
	  AND r20_item        = item
	INTO TEMP t1
SELECT NVL(SUM(cant_tr), 0) INTO cant_tra FROM t1
DROP TABLE t1
LET cant = cant_fac - cant_tra
RETURN cant

END FUNCTION



FUNCTION tiene_facturas_cruce(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r41		RECORD LIKE rept041.*

INITIALIZE r_r41.* TO NULL
DECLARE q_tiene CURSOR FOR
	SELECT * FROM rept041
		WHERE r41_compania  = vg_codcia
		  AND r41_localidad = vg_codloc
		  AND r41_cod_tran  = r_r19.r19_cod_tran
		  AND r41_num_tran  = r_r19.r19_num_tran
OPEN q_tiene
FETCH q_tiene INTO r_r41.*
CLOSE q_tiene
FREE q_tiene
IF r_r41.r41_compania IS NULL THEN
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION tiene_item_cruce(item, r_r19)
DEFINE item		LIKE rept020.r20_item
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r41		RECORD LIKE rept041.*

INITIALIZE r_r41.* TO NULL
DECLARE q_tiene2 CURSOR FOR
	SELECT rept041.*
		FROM rept041, rept019, rept020
		WHERE r41_compania  = vg_codcia
		  AND r41_localidad = vg_codloc
		  AND r41_cod_tran  = r_r19.r19_cod_tran
		  AND r41_num_tran  = r_r19.r19_num_tran
		  AND r19_compania  = r41_compania
		  AND r19_localidad = r41_localidad
		  AND r19_cod_tran  = r41_cod_tr
		  AND r19_num_tran  = r41_num_tr
		  AND r20_compania  = r19_compania
		  AND r20_localidad = r19_localidad
		  AND r20_cod_tran  = r19_cod_tran
		  AND r20_num_tran  = r19_num_tran
		  AND r20_item      = item
OPEN q_tiene2
FETCH q_tiene2 INTO r_r41.*
CLOSE q_tiene2
FREE q_tiene2
IF r_r41.r41_compania IS NULL THEN
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION muestra_fact_items_cruce(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_factcru	ARRAY[800] OF RECORD
				item		LIKE rept020.r20_item,
				cant_cruc	LIKE rept020.r20_cant_ven,
				cant_pend	LIKE rept020.r20_cant_ven,
				num_fact	LIKE rept019.r19_num_tran, 
				fec_fact	DATE,
				cliente		LIKE rept019.r19_nomcli, 
				num_tran	LIKE rept019.r19_num_tran 
			END RECORD
DEFINE r_adi		ARRAY[800] OF RECORD
				codcli		LIKE rept019.r19_codcli
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j, col	SMALLINT
DEFINE resul		SMALLINT
DEFINE num_row		SMALLINT
DEFINE max_row		SMALLINT
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE query		CHAR(4000)
DEFINE r_orden	 	ARRAY[10] OF CHAR(4)
DEFINE v_columna_1	SMALLINT
DEFINE v_columna_2	SMALLINT

LET row_ini = 07
LET row_fin = 17
LET col_ini = 02
LET col_fin = 80
IF vg_gui = 0 THEN
	LET row_ini = 09
	LET row_fin = 13
	LET col_ini = 03
	LET col_fin = 76
END IF
OPEN WINDOW w_repf214_4 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf214_4 FROM '../forms/repf214_4'
ELSE
	OPEN FORM f_repf214_4 FROM '../forms/repf214_4c'
END IF
DISPLAY FORM f_repf214_4
LET max_row = 800
--#DISPLAY 'Item' 	TO tit_col1
--#DISPLAY 'Cant.Cruce'	TO tit_col2
--#DISPLAY 'Cant.Pend.'	TO tit_col3
--#DISPLAY 'Factura'	TO tit_col4
--#DISPLAY 'Fecha Fact'	TO tit_col5
--#DISPLAY 'Cliente'	TO tit_col6
--#DISPLAY 'Transf.'	TO tit_col7
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET col                  = 5
LET v_columna_1          = col
LET v_columna_2          = 4
LET r_orden[v_columna_1] = 'ASC'
LET r_orden[v_columna_2] = 'ASC'
CALL obtener_bod_sin_stock()
LET query = 'SELECT d.r20_item item_c, d.r20_cant_ven, ',
		' NVL(CASE WHEN b.r19_bodega_ori = ',
			'(SELECT r02_codigo FROM t_bd1) ',
		' THEN ',
			'(SELECT NVL(SUM(f.r20_cant_ven), 0) * (-1) ',
				'FROM rept019 e, rept020 f ',
				'WHERE e.r19_compania   = b.r19_compania ',
				'  AND e.r19_localidad  = b.r19_localidad ',
				'  AND e.r19_cod_tran   = "TR" ',
				'  AND e.r19_bodega_ori = b.r19_bodega_ori ',
				'  AND e.r19_tipo_dev   = b.r19_tipo_dev ',
				'  AND e.r19_num_dev    = b.r19_num_dev ',
				'  AND f.r20_compania   = e.r19_compania ',
				'  AND f.r20_localidad  = e.r19_localidad ',
				'  AND f.r20_cod_tran   = e.r19_cod_tran ',
				'  AND f.r20_num_tran   = e.r19_num_tran ',
				'  AND f.r20_item       = d.r20_item) ',
		' ELSE ',
			'(SELECT NVL(SUM(f.r20_cant_ven), 0) ',
				'FROM rept019 e, rept020 f ',
				'WHERE e.r19_compania   = b.r19_compania ',
				'  AND e.r19_localidad  = b.r19_localidad ',
				'  AND e.r19_cod_tran   = "TR" ',
				'  AND e.r19_bodega_dest= b.r19_bodega_dest ',
				'  AND e.r19_tipo_dev   = b.r19_tipo_dev ',
				'  AND e.r19_num_dev    = b.r19_num_dev ',
				'  AND f.r20_compania   = e.r19_compania ',
				'  AND f.r20_localidad  = e.r19_localidad ',
				'  AND f.r20_cod_tran   = e.r19_cod_tran ',
				'  AND f.r20_num_tran   = e.r19_num_tran ',
				'  AND f.r20_item       = d.r20_item) ',
		' END, 0.00) cant_pend, ',
		' b.r19_num_dev, ',
		'DATE((SELECT a.r19_fecing ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev)) fec_f,',
		'(SELECT a.r19_nomcli ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev) nom_c,',
		' d.r20_num_tran, ',
		'(SELECT a.r19_codcli ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev) cod_c ',
		' FROM rept041, rept019 b, rept020 d, outer rept042 ',
		' WHERE r41_compania    = ', vg_codcia,
		'   AND r41_localidad   = ', vg_codloc,
		'   AND r41_cod_tran    = "', r_r19.r19_cod_tran, '"',
		'   AND r41_num_tran    = ', r_r19.r19_num_tran,
		'   AND b.r19_compania  = r41_compania ',
		'   AND b.r19_localidad = r41_localidad ',
		'   AND b.r19_cod_tran  = r41_cod_tr ',
		'   AND b.r19_num_tran  = r41_num_tr ',
		'   AND d.r20_compania  = b.r19_compania ',
		'   AND d.r20_localidad = b.r19_localidad ',
		'   AND d.r20_cod_tran  = b.r19_cod_tran ',
		'   AND d.r20_num_tran  = b.r19_num_tran ',
		'   AND r42_compania    = b.r19_compania ',
		'   AND r42_localidad   = b.r19_localidad ',
		'   AND r42_cod_tran    = r41_cod_tran ',
		'   AND r42_num_tran    = r41_num_tran ',
		'   AND r42_cod_tr_re   = b.r19_cod_tran ',
		'   AND r42_num_tr_re   = b.r19_num_tran ',
		' INTO TEMP t1 '
PREPARE exec_cru FROM query
EXECUTE exec_cru
SELECT item_c, r20_cant_ven, NVL(SUM(cant_pend), 0) cant_pend, r19_num_dev,
	fec_f, nom_c, r20_num_tran, cod_c
	FROM t1
	GROUP BY 1, 2, 4, 5, 6, 7, 8
	INTO TEMP tmp_cru
DROP TABLE t1
WHILE TRUE
	LET query = 'SELECT item_c, r20_cant_ven, ',
			' NVL((SELECT r20_cant_ven ',
				' FROM rept020 ',
				' WHERE r20_compania  = ', vg_codcia,
				'   AND r20_localidad = ', vg_codloc,
				'   AND r20_cod_tran  = "FA" ',
				'   AND r20_num_tran  = r19_num_dev ',
				'   AND r20_bodega    = ',
					'(SELECT r02_codigo FROM t_bd1) ',
				'   AND r20_item      = item_c), 0) - ',
			'cant_pend, r19_num_dev, fec_f, nom_c, r20_num_tran, ',
			'cod_c ',
			' FROM tmp_cru ',
	                ' ORDER BY ', v_columna_1, ' ', r_orden[v_columna_1],
				', ', v_columna_2, ' ', r_orden[v_columna_2] 
	PREPARE cons_fac FROM query
	DECLARE q_fact_c CURSOR FOR cons_fac
	LET num_row = 1
	FOREACH q_fact_c INTO r_factcru[num_row].*, r_adi[num_row].*
		LET num_row = num_row + 1
		IF num_row > max_row THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row = num_row - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, num_row)
		DISPLAY r_adi[1].codcli      TO codcli
		DISPLAY r_factcru[1].cliente TO nomcli
		CALL fl_lee_item(vg_codcia,r_factcru[1].item) RETURNING r_r10.*
		CALL muestra_descripciones(r_r10.r10_codigo, r_r10.r10_linea,
					r_r10.r10_sub_linea,r_r10.r10_cod_grupo,
					r_r10.r10_cod_clase, 0)
	END IF
	CALL set_count(num_row)
	DISPLAY ARRAY r_factcru TO r_factcru.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(RETURN)
			LET j = arr_curr()
			CALL muestra_contadores_det(j, num_row)
			DISPLAY r_adi[j].codcli      TO codcli
			DISPLAY r_factcru[j].cliente TO nomcli
			CALL fl_lee_item(vg_codcia, r_factcru[j].item)
				RETURNING r_r10.*
			CALL muestra_descripciones(r_r10.r10_codigo,
					r_r10.r10_linea, r_r10.r10_sub_linea,
					r_r10.r10_cod_grupo,r_r10.r10_cod_clase,
					0)
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2()
		ON KEY(F5)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'FA', r_factcru[j].num_fact)
			LET int_flag = 0
		ON KEY(F6)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'TR', r_factcru[j].num_tran)
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
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#CALL muestra_contadores_det(j, num_row)
			--#DISPLAY r_adi[j].codcli      TO codcli
			--#DISPLAY r_factcru[j].cliente TO nomcli
			--#CALL fl_lee_item(vg_codcia, r_factcru[j].item)
				--#RETURNING r_r10.*
			--#CALL muestra_descripciones(r_r10.r10_codigo,
					--#r_r10.r10_linea, r_r10.r10_sub_linea,
					--#r_r10.r10_cod_grupo,
					--#r_r10.r10_cod_clase, 0)
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
DROP TABLE t_bd1
DROP TABLE tmp_cru
LET int_flag = 0
CLOSE WINDOW w_repf214_4
RETURN

END FUNCTION



FUNCTION muestra_facturas_cruce(posi, r_r19)
DEFINE posi		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_detcru		ARRAY[800] OF RECORD
				num_fact	LIKE rept019.r19_num_tran, 
				fec_fact	DATE,
				cant_cruc	LIKE rept020.r20_cant_ven,
				cant_pend	LIKE rept020.r20_cant_ven,
				cliente		LIKE rept019.r19_nomcli, 
				num_tran	LIKE rept019.r19_num_tran 
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j, col	SMALLINT
DEFINE resul		SMALLINT
DEFINE num_row		SMALLINT
DEFINE max_row		SMALLINT
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE query		CHAR(3000)
DEFINE r_orden	 	ARRAY[10] OF CHAR(4)
DEFINE v_columna_1	SMALLINT
DEFINE v_columna_2	SMALLINT

LET row_ini = 07
LET row_fin = 17
LET col_ini = 02
LET col_fin = 80
IF vg_gui = 0 THEN
	LET row_ini = 09
	LET row_fin = 13
	LET col_ini = 03
	LET col_fin = 76
END IF
OPEN WINDOW w_repf214_5 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf214_5 FROM '../forms/repf214_5'
ELSE
	OPEN FORM f_repf214_5 FROM '../forms/repf214_5c'
END IF
DISPLAY FORM f_repf214_5
LET max_row = 800
--#DISPLAY 'Factura'	TO tit_col1
--#DISPLAY 'Fecha Fact'	TO tit_col2
--#DISPLAY 'Cant.Cruce'	TO tit_col3
--#DISPLAY 'Cant.Pend.'	TO tit_col4
--#DISPLAY 'Cliente'	TO tit_col5
--#DISPLAY 'Transf.'	TO tit_col6
CALL fl_lee_item(vg_codcia, r_detalle[posi].r92_item) RETURNING r_r10.*
DISPLAY r_detalle[posi].r92_item TO item
CALL muestra_descripciones(r_r10.r10_codigo, r_r10.r10_linea,
				r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
				r_r10.r10_cod_clase, 0)
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET col                  = 2
LET v_columna_1          = col
LET v_columna_2          = 1
LET r_orden[v_columna_1] = 'ASC'
LET r_orden[v_columna_2] = 'ASC'
CALL obtener_bod_sin_stock()
LET query = 'SELECT d.r20_item item_c, b.r19_num_dev, ',
		'DATE((SELECT a.r19_fecing ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev)) fec_f,',
		' d.r20_cant_ven, ',
		' NVL(CASE WHEN b.r19_bodega_ori = ',
			'(SELECT r02_codigo FROM t_bd1) ',
		' THEN ',
			'(SELECT NVL(SUM(f.r20_cant_ven), 0) * (-1) ',
				'FROM rept019 e, rept020 f ',
				'WHERE e.r19_compania   = b.r19_compania ',
				'  AND e.r19_localidad  = b.r19_localidad ',
				'  AND e.r19_cod_tran   = "TR" ',
				'  AND e.r19_bodega_ori = b.r19_bodega_ori ',
				'  AND e.r19_tipo_dev   = b.r19_tipo_dev ',
				'  AND e.r19_num_dev    = b.r19_num_dev ',
				'  AND f.r20_compania   = e.r19_compania ',
				'  AND f.r20_localidad  = e.r19_localidad ',
				'  AND f.r20_cod_tran   = e.r19_cod_tran ',
				'  AND f.r20_num_tran   = e.r19_num_tran ',
				'  AND f.r20_item       = d.r20_item) ',
		' ELSE ',
			'(SELECT NVL(SUM(f.r20_cant_ven), 0) ',
				'FROM rept019 e, rept020 f ',
				'WHERE e.r19_compania   = b.r19_compania ',
				'  AND e.r19_localidad  = b.r19_localidad ',
				'  AND e.r19_cod_tran   = "TR" ',
				'  AND e.r19_bodega_dest= b.r19_bodega_dest ',
				'  AND e.r19_tipo_dev   = b.r19_tipo_dev ',
				'  AND e.r19_num_dev    = b.r19_num_dev ',
				'  AND f.r20_compania   = e.r19_compania ',
				'  AND f.r20_localidad  = e.r19_localidad ',
				'  AND f.r20_cod_tran   = e.r19_cod_tran ',
				'  AND f.r20_num_tran   = e.r19_num_tran ',
				'  AND f.r20_item       = d.r20_item) ',
		' END, 0.00) cant_pend, ',
		'(SELECT a.r19_nomcli ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev) nom_c,',
		' d.r20_num_tran ',
		' FROM rept041, rept019 b, rept020 d, outer rept042 ',
		' WHERE r41_compania    = ', vg_codcia,
		'   AND r41_localidad   = ', vg_codloc,
		'   AND r41_cod_tran    = "', r_r19.r19_cod_tran, '"',
		'   AND r41_num_tran    = ', r_r19.r19_num_tran,
		'   AND b.r19_compania  = r41_compania ',
		'   AND b.r19_localidad = r41_localidad ',
		'   AND b.r19_cod_tran  = r41_cod_tr ',
		'   AND b.r19_num_tran  = r41_num_tr ',
		'   AND d.r20_compania  = b.r19_compania ',
		'   AND d.r20_localidad = b.r19_localidad ',
		'   AND d.r20_cod_tran  = b.r19_cod_tran ',
		'   AND d.r20_num_tran  = b.r19_num_tran ',
		'   AND d.r20_item      = "', r_detalle[posi].r92_item CLIPPED,
					 '"',
		'   AND r42_compania    = b.r19_compania ',
		'   AND r42_localidad   = b.r19_localidad ',
		'   AND r42_cod_tran    = r41_cod_tran ',
		'   AND r42_num_tran    = r41_num_tran ',
		'   AND r42_cod_tr_re   = b.r19_cod_tran ',
		'   AND r42_num_tr_re   = b.r19_num_tran ',
		' INTO TEMP t1 '
PREPARE exec_cru2 FROM query
EXECUTE exec_cru2
SELECT r19_num_dev, fec_f, r20_cant_ven, NVL(SUM(cant_pend), 0) cant_pend,
	nom_c, r20_num_tran
	FROM t1
	GROUP BY 1, 2, 3, 5, 6
	INTO TEMP tmp_cru
DROP TABLE t1
WHILE TRUE
	LET query = 'SELECT r19_num_dev, fec_f, r20_cant_ven, ',
			' NVL((SELECT r20_cant_ven ',
				' FROM rept020 ',
				' WHERE r20_compania  = ', vg_codcia,
				'   AND r20_localidad = ', vg_codloc,
				'   AND r20_cod_tran  = "FA" ',
				'   AND r20_num_tran  = r19_num_dev ',
				'   AND r20_bodega    = ',
					'(SELECT r02_codigo FROM t_bd1) ',
				'   AND r20_item      = "',
				r_detalle[posi].r92_item CLIPPED, '"), 0) - ',
			'cant_pend, nom_c, r20_num_tran ',
			' FROM tmp_cru ',
	                ' ORDER BY ', v_columna_1, ' ', r_orden[v_columna_1],
				', ', v_columna_2, ' ', r_orden[v_columna_2] 
	PREPARE cons_fac2 FROM query
	DECLARE q_fact_c2 CURSOR FOR cons_fac2
	LET num_row = 1
	FOREACH q_fact_c2 INTO r_detcru[num_row].*
		LET num_row = num_row + 1
		IF num_row > max_row THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row = num_row - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, num_row)
	END IF
	CALL set_count(num_row)
	DISPLAY ARRAY r_detcru TO r_detcru.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(RETURN)
			LET j = arr_curr()
			CALL muestra_contadores_det(j, num_row)
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2()
		ON KEY(F5)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'FA', r_detcru[j].num_fact)
			LET int_flag = 0
		ON KEY(F6)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'TR', r_detcru[j].num_tran)
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
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#CALL muestra_contadores_det(j, num_row)
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
DROP TABLE t_bd1
DROP TABLE tmp_cru
LET int_flag = 0
CLOSE WINDOW w_repf214_5
RETURN

END FUNCTION



FUNCTION dropear_tablas_tmp()

DROP TABLE t_r11
DROP TABLE t_bod
DROP TABLE temp_item_pen
DROP TABLE tmp_ite_cl
IF vm_stock_pend THEN
	DROP TABLE temp_pend
END IF

END FUNCTION



FUNCTION enviar_transferencia_otra_loc(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE localidad_des	LIKE gent002.g02_localidad
DEFINE opc		CHAR(2)
DEFINE comando		VARCHAR(250)

CALL localidad_bodega(r_r19.r19_bodega_dest) RETURNING localidad_des
IF localidad_des = vg_codloc THEN
	RETURN
END IF
CASE localidad_des
	WHEN 2
		LET opc = '3'
	WHEN 5
		IF vg_codloc <> 4 THEN
			LET opc = '7'
		ELSE
			LET opc = '9'
		END IF
	--WHEN 3
		--LET opc = '2'
	OTHERWISE
		LET opc = NULL
		IF vg_codloc = 5 THEN
			IF localidad_bodega(r_r19.r19_bodega_dest) = 3 THEN
				LET opc = '8'
			END IF
			IF localidad_bodega(r_r19.r19_bodega_dest) = 4 THEN
				LET opc = '10'
			END IF
		END IF
END CASE
IF opc IS NULL THEN
	RETURN
END IF
ERROR 'Se esta enviando la Transferencia. Por favor espere ... '
LET comando = 'cd /acero/fobos/PRODUCCION/TRANSMISION/; fglgo transfer "',
		opc, '" X &> /acero/fobos/PRODUCCION/TRANSMISION/transfer.log '
RUN comando CLIPPED
ERROR '                                                        '
CALL fl_lee_localidad(vg_codcia, localidad_des) RETURNING r_g02.*
CALL fl_mostrar_mensaje('Transferencia enviada a Localidad: ' || r_g02.g02_nombre CLIPPED || '.', 'info')

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



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Factura'                  AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Transferencia'            AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

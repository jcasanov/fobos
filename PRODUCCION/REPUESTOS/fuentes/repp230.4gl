------------------------------------------------------------------------------
-- Titulo           : repp230.4gl - Carga a produccion transferencias de otras
--                                  localidades, previamente transmitidas.
-- Elaboracion      : 01-Feb-2004
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp230.4gl base_datos modulo compañía localidad
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_estado	CHAR(1)
DEFINE rm_tran ARRAY[1000] OF RECORD
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
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp230.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp230'
LET vg_proceso  = vg_proceso
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
OPEN WINDOW w_imp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
	OPEN FORM f_cons FROM '../forms/repf230_1'
DISPLAY FORM f_cons
LET vm_max_rows = 1000
--#DISPLAY '#'          TO tit_col1
--#DISPLAY 'Origen'     TO tit_col2
--#DISPLAY 'BO'         TO tit_col3
--#DISPLAY 'BD'         TO tit_col4
--#DISPLAY 'Referencia' TO tit_col5
--#DISPLAY 'Fecha     ' TO tit_col6
--#DISPLAY '#'          TO tit_col7
--#DISPLAY 'Real'       TO tit_col8
WHILE TRUE
	CALL lee_estado()
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



FUNCTION lee_estado()
DEFINE resp		CHAR(3)

LET int_flag = 0
LET vm_estado = 'P'
OPTIONS INPUT NO WRAP
INPUT BY NAME vm_estado WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		--#RETURN
		EXIT INPUT
	AFTER FIELD vm_estado
		IF vm_estado IS NOT NULL THEN
			IF vm_estado <> 'P' AND vm_estado <> 'T' AND
                           vm_estado <> 'D' 
			THEN
				CALL fgl_winmessage(vg_producto,'Estado incorrecto.','exclamation')
				NEXT FIELD vm_estado
			END IF
		ELSE
			LET vm_estado = 'P'
		END IF
END INPUT

END FUNCTION



FUNCTION carga_arreglo_trabajo()
DEFINE query		CHAR(500)

LET int_flag = 0
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET query = 'SELECT r91_localidad, r91_cod_tran, r91_num_tran, ',
		  ' r91_bodega_ori, r91_bodega_dest, r91_referencia, ',
		  ' DATE(r91_fecing), r90_codtra_fin, r90_numtra_fin ',
		  ' FROM rept090, rept091 ',
		  ' WHERE r90_compania  = r91_compania  AND ',
			' r90_localidad = r91_localidad AND ',
			' r90_cod_tran  = r91_cod_tran  AND ',
			' r90_num_tran  = r91_num_tran '
IF vm_estado = 'P' THEN
	LET query = query CLIPPED, ' AND r90_codtra_fin IS NULL '
ELSE
	IF vm_estado = 'T' THEN
		LET query = query CLIPPED, ' AND r90_codtra_fin IS NOT NULL '
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

CALL set_count(vm_num_rows)
LET int_flag = 0
DISPLAY ARRAY rm_tran TO rm_tran.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#IF rm_tran[i].r90_codtra_fin IS NULL THEN	
			--#CALL dialog.keysetlabel("F6","")
			--#CALL dialog.keysetlabel("F7","Transmitir")
		--#ELSE
			--#CALL dialog.keysetlabel("F6","Destino")
			--#CALL dialog.keysetlabel("F7","")
		--#END IF
	ON KEY(F5)
		LET i = arr_curr()
		CALL muestra_transferencia_origen(vg_codcia, 
			rm_tran[i].r91_localidad, 
			rm_tran[i].r91_cod_tran, rm_tran[i].r91_num_tran)
	ON KEY(F6)
		LET i = arr_curr()
		IF rm_tran[i].r90_codtra_fin IS NOT NULL THEN
			LET ejecutable = 'fglrun '
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
			CALL fgl_winquestion(vg_producto, comando,'No', 'Yes|No', 'question', 1) RETURNING resp
			IF resp = 'Yes' THEN
				CALL control_cargar_transferencia(
						rm_tran[i].r91_localidad, 
						rm_tran[i].r91_cod_tran, 
						rm_tran[i].r91_num_tran)
					RETURNING rm_tran[i].r90_codtra_fin,
				                  rm_tran[i].r90_numtra_fin
				DISPLAY rm_tran[i].r90_codtra_fin TO 
			        	rm_tran[j].r90_codtra_fin 
				DISPLAY rm_tran[i].r90_numtra_fin TO 
			        	rm_tran[j].r90_numtra_fin 
			END IF
			--#IF rm_tran[i].r90_codtra_fin IS NOT NULL THEN	
				--#CALL dialog.keysetlabel("F6","Destino")
				--#CALL dialog.keysetlabel("F7","")
			--# END IF
		END IF
END DISPLAY
                                                                                
END FUNCTION



FUNCTION muestra_transferencia_origen(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept091.r91_compania
DEFINE codloc		LIKE rept091.r91_localidad
DEFINE cod_tran		LIKE rept091.r91_cod_tran
DEFINE num_tran		LIKE rept091.r91_num_tran
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
DEFINE r_detalle ARRAY[200] OF RECORD
	r92_cant_ped		LIKE rept092.r92_cant_ped,
	r92_stock_ant		LIKE rept092.r92_stock_ant,
	r92_item		LIKE rept092.r92_item,
	r92_costo		LIKE rept092.r92_costo,
	subtotal_item		LIKE rept019.r19_tot_costo
	END RECORD

LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
LET num_max_rows = 200
OPEN WINDOW w_tra AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
	OPEN FORM f_tra FROM '../forms/repf230_2'
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
	CALL fgl_winmessage(vg_producto, 'No existe transferencia en rept091.',
				'exclamation')
	CLOSE WINDOW w_tra
	RETURN
END IF
CALL fl_lee_localidad(codcia, codloc) RETURNING r_g02.*
--DISPLAY r_g02.g02_nombre TO tit_local
DISPLAY BY NAME r_r91.r91_num_tran,    r_r91.r91_cod_tran, 
		r_r91.r91_bodega_ori,  r_r91.r91_bodega_dest,
		r_r91.r91_tot_costo,   r_r91.r91_referencia, 
		r_r91.r91_usuario,     r_r91.r91_fecing,
		r_r91.r91_localidad
CALL fl_lee_bodega_rep(codcia, r_r91.r91_bodega_ori)
	RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO nom_bod_ori
CALL fl_lee_bodega_rep(codcia, r_r91.r91_bodega_dest)
	RETURNING r_r02.*
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
	CALL fl_mensaje_consulta_sin_registros()
	LET i = 0
	CLOSE WINDOW w_tra
	RETURN
END IF 
CALL set_count(i)
DISPLAY ARRAY r_detalle TO r_detalle.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
                --#CALL dialog.keysetlabel('RETURN', '')
	--#BEFORE ROW 
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL fl_lee_item(codcia, r_detalle[i].r92_item)
			--#RETURNING r_r10.*
		--#DISPLAY r_r10.r10_nombre TO nom_item
		--CALL muestra_descripciones(r_detalle[i].r92_item,
				--r_r10.r10_linea, r_r10.r10_sub_linea,
				--r_r10.r10_cod_grupo, 
				--r_r10.r10_cod_clase)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL fl_lee_item(codcia, r_detalle[i].r92_item)
			RETURNING r_r10.*
		--CALL muestra_descripciones(r_detalle[i].r92_item,
				--r_r10.r10_linea, r_r10.r10_sub_linea,
				--r_r10.r10_cod_grupo, 
				--r_r10.r10_cod_clase)
		DISPLAY r_r10.r10_nombre TO nom_item
END DISPLAY

LET int_flag = 0
CLOSE WINDOW w_tra

END FUNCTION



FUNCTION control_cargar_transferencia(codloc, cod_tran, num_tran)
DEFINE codloc		LIKE rept091.r91_localidad
DEFINE cod_tran		LIKE rept091.r91_cod_tran
DEFINE num_tran		LIKE rept091.r91_num_tran
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_stock_ori	RECORD LIKE rept011.*
DEFINE r_stock_des	RECORD LIKE rept011.*
DEFINE num_tran_ori	INTEGER
DEFINE costo_nue	DECIMAL(12,2)
DEFINE fecing_ori	DATETIME YEAR TO SECOND
DEFINE mensaje		VARCHAR(130)

{
IF codloc <> 1 AND codloc <> 3 THEN
	LET mensaje = 'Solo se puede transmitir ',
		      'transferencias de localidades ',
		      'origen 1 ó 3.'
	CALL fgl_winmessage(vg_producto, mensaje,'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN cod_tran, num_tran
END IF
}
CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
--DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
--	WHERE r01_compania   = vg_codcia AND
--	      r01_user_owner = vg_usuario
--OPEN qu_vd 
INITIALIZE r_r01.* TO NULL
--FETCH qu_vd INTO r_r01.*
--IF status = NOTFOUND THEN
	DECLARE q_vend CURSOR FOR SELECT * FROM rept001
		WHERE r01_compania = vg_codcia AND r01_estado = 'A' AND 
	      	      r01_tipo IN ('E','I')
		ORDER BY r01_tipo
	OPEN q_vend
	FETCH q_vend INTO r_r01.*
--END IF		
SELECT * INTO r_r90.* FROM rept090
	WHERE r90_compania  = vg_codcia AND 
	      r90_localidad = codloc    AND 
	      r90_cod_tran  = cod_tran  AND 
	      r90_num_tran  = num_tran  
IF status = NOTFOUND THEN
	LET mensaje = 'No existe en rept090: ', cod_tran, '-',
		       num_tran USING '<<<<<<&'
	CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN cod_tran, num_tran
END IF
IF r_r90.r90_codtra_fin IS NOT NULL THEN
	LET mensaje = 'La transferencia: ', cod_tran, '-',
		       num_tran USING '<<<<<<&', 
		      ' ya ha estado trasmitida.'
	CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
	RETURN r_r90.r90_codtra_fin, r_r90.r90_numtra_fin
END IF
SELECT * INTO r_r19.* FROM rept091
	WHERE r91_compania  = vg_codcia AND 
	      r91_localidad = codloc    AND 
	      r91_cod_tran  = cod_tran  AND 
	      r91_num_tran  = num_tran  
IF status = NOTFOUND THEN
	LET mensaje = 'No existe en rept091: ', cod_tran, '-',
		       num_tran USING '<<<<<<&'
	CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
	INITIALIZE cod_tran, num_tran TO NULL
	RETURN cod_tran, num_tran
END IF
INITIALIZE cod_tran, num_tran TO NULL
SELECT * INTO r_r02.* FROM rept002
	WHERE r02_compania = r_r19.r19_compania AND
	      r02_codigo   = r_r19.r19_bodega_ori
IF r_r02.r02_localidad = vg_codloc THEN
	CALL fgl_winmessage(vg_producto, 'La bodega origen es de esta misma localidad.', 
				'exclamation')
	RETURN cod_tran, num_tran
END IF 
SELECT * INTO r_r02.* FROM rept002
	WHERE r02_compania = r_r19.r19_compania AND
	      r02_codigo   = r_r19.r19_bodega_dest
IF r_r02.r02_localidad != vg_codloc THEN
	CALL fgl_winmessage(vg_producto, 'La bodega destino no es de esta localidad.', 
				'exclamation')
	RETURN cod_tran, num_tran
END IF 
LET r_r19.r19_vendedor = r_r01.r01_codigo
LET r_r19.r19_usuario  = vg_usuario
LET num_tran_ori       = r_r19.r19_num_tran
LET fecing_ori         = r_r19.r19_fecing
LET r_r19.r19_fecing   = CURRENT
LET r_r19.r19_localidad= vg_codloc

CALL fl_lee_cod_transaccion(r_r19.r19_cod_tran) RETURNING r_g21.*
LET r_r19.r19_tipo_tran  = r_g21.g21_tipo
LET r_r19.r19_calc_costo = r_g21.g21_calc_costo

BEGIN WORK
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE', 'AA', 'TR')
	RETURNING r_r19.r19_num_tran 
IF r_r19.r19_num_tran <= 0 THEN
	ROLLBACK WORK	
	EXIT PROGRAM
END IF
INSERT INTO rept019 VALUES (r_r19.*)
DECLARE qu_dtr CURSOR FOR 
	SELECT * FROM rept092
		WHERE r92_compania  = r_r19.r19_compania  AND 
		      r92_localidad = r_r90.r90_localidad AND 
		      r92_cod_tran  = r_r19.r19_cod_tran  AND
		      r92_num_tran  = num_tran_ori
		ORDER BY r92_orden
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
	SELECT * INTO r_r10.* FROM rept010
		WHERE r10_compania = vg_codcia AND 
	      	      r10_codigo   = r_r20.r20_item
	IF r_r90.r90_localidad = 1 OR r_r90.r90_localidad = 3 THEN
		CALL fl_obtiene_costo_item(vg_codcia, r_r19.r19_moneda,
			r_r20.r20_item, r_r20.r20_cant_ven, r_r20.r20_costo)
			RETURNING costo_nue
		LET r_r20.r20_costant_mb  = r_r10.r10_costo_mb
		LET r_r10.r10_costo_mb    = costo_nue
		LET r_r20.r20_costnue_mb  = costo_nue
		LET r_r10.r10_costult_mb  = r_r20.r20_costo
		UPDATE rept010 SET r10_costo_mb		= r_r10.r10_costo_mb,
                                   r10_costult_mb	= r_r10.r10_costult_mb
			WHERE r10_compania = vg_codcia AND 
	              	      r10_codigo   = r_r20.r20_item
	END IF
	IF r_stock_ori.r11_stock_act >= 0 THEN
		UPDATE rept011
			SET r11_stock_act = r_stock_ori.r11_stock_act
			WHERE r11_compania = vg_codcia AND 
			      r11_bodega   = r_r19.r19_bodega_ori AND
			      r11_item     = r_r20.r20_item
	END IF
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
			       r_r20.r20_item)
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

	CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc, 
							r_r20.r20_cod_tran, r_r20.r20_num_tran, r_r20.r20_item)
END FOREACH
UPDATE rept090 SET r90_codtra_fin = r_r20.r20_cod_tran,
    		   r90_numtra_fin = r_r20.r20_num_tran,
    		   r90_fecing_fin = r_r19.r19_fecing
	WHERE r90_compania 	= r_r90.r90_compania  AND
    	      r90_localidad 	= r_r90.r90_localidad AND
    	      r90_cod_tran 	= r_r90.r90_cod_tran  AND
    	      r90_num_tran 	= r_r90.r90_num_tran
COMMIT WORK
CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc, 
	 	r_r19.r19_cod_tran, r_r19.r19_num_tran)
LET mensaje = 'Proceso terminó Ok., verifique e imprima la transferencia ',
	      'generada.'
CALL fgl_winmessage(vg_producto, mensaje, 'info')
RETURN r_r19.r19_cod_tran, r_r19.r19_num_tran

END FUNCTION



{
FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
--DEFINE sub_linea	LIKE rept010.r10_sub_linea
--DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
--DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
--DEFINE r_r70		RECORD LIKE rept070.*
--DEFINE r_r71		RECORD LIKE rept071.*
--DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_r03.*
--CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
--CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
--	RETURNING r_r71.*
--CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
--	RETURNING r_r72.*
DISPLAY r_r03.r03_nombre     TO descrip_1
--DISPLAY r_r70.r70_desc_sub   TO descrip_2
--DISPLAY r_r71.r71_desc_grupo TO descrip_3
--DISPLAY r_r72.r72_desc_clase TO descrip_4

END FUNCTION
}



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION

--------------------------------------------------------------------------------
-- Titulo           : repp223.4gl - Aprobacion de Pre-Venta
-- Elaboracion      : 15-oct-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp223 base modulo compania localidad [numprev]
-- Ultima Correccion: 15-oct-2001
-- Motivo Correccion: 1
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows		ARRAY[1000] OF INTEGER	-- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT		-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT		-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT		-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r23			RECORD LIKE rept023.*	-- CABECERA
DEFINE rm_r24		 	RECORD LIKE rept024.*	-- DETALLE
DEFINE rm_g13		 	RECORD LIKE gent013.*	-- MONEDA
DEFINE rm_g20		 	RECORD LIKE gent020.*	-- GRUPO LINEA

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[200] OF RECORD
	tit_estado		VARCHAR(11),
	num_preventa		LIKE rept023.r23_numprev,
	total_sin_iva		LIKE rept023.r23_tot_bruto,
	total_costo		LIKE rept023.r23_tot_costo,
{
	diferencia		LIKE rept023.r23_tot_neto,
	utilidad		LIKE rept023.r23_descuento,
}
	diferencia		DECIMAL(11,2),
	utilidad		DECIMAL(11,2),
	aprobar			LIKE rept023.r23_estado
	END RECORD
	---------------------------------------------

	---- ARREGLO PARALELO PARA EL ESTADO y NOMBRE DE CLIENTE----
DEFINE r_detalle_2 ARRAY[200] OF RECORD
	r23_cont_cred 	LIKE rept023.r23_estado,
	r23_estado 	LIKE rept023.r23_estado,
	r23_nomcli	LIKE rept023.r23_nomcli
	END RECORD	
	------------------------------------------------------------
		---- ARREGLO QUE MUESTRA LA PREVENTA ----
DEFINE r_preventa ARRAY[200] OF RECORD
	r24_cant_ven		LIKE rept024.r24_cant_ven,
	r24_item		LIKE rept024.r24_item,
	r24_descuento		LIKE rept024.r24_precio,
	precio_descuento	DECIMAL(11,2),
	costo_item		DECIMAL(11,2),
	diferencia		DECIMAL(11,2),
	utilidad		DECIMAL(11,2)
	END RECORD 

DEFINE tot_precio_descuento 	DECIMAL(11,2)
DEFINE tot_costo	 	DECIMAL(11,2)
DEFINE tot_diferencia	 	DECIMAL(11,2)
DEFINE tot_utilidad 		DECIMAL(11,2)
	------------------------------------------------------------
	---- ARREGLO PARALELO PARA NOMBRE DEL ITEM----
DEFINE r_preventa_2 ARRAY[200] OF RECORD
	nom_item	LIKE rept010.r10_nombre
	END  RECORD
	----------------------------------------------

DEFINE vm_estado		LIKE rept023.r23_estado
DEFINE vm_estado_2		LIKE rept023.r23_estado
DEFINE vm_num_detalle		SMALLINT   -- INDICE DE LA PREVENTA (ARRAY)
DEFINE vm_ind_arr		SMALLINT   -- INDICE DE MI ARREGLO  (ARRAY)
DEFINE vm_filas_pant		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_size_arr		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_size_arr2		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_subtotal   	 	DECIMAL(12,2)	-- TOTAL BRUTO 
DEFINE vm_descuento    		DECIMAL(12,2)	-- TOTAL DEL DESCUENTO
DEFINE vm_impuesto    		DECIMAL(12,2)	-- TOTAL DEL IMPUESTO
DEFINE vm_total    		DECIMAL(12,2)	-- TOTAL NETO



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp223.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp223'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
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

CALL fl_nivel_isolation()
CREATE TEMP TABLE temp_prev(
	tit_estado		VARCHAR(11),
	num_preventa		INTEGER,
	total_sin_iva		DECIMAL(12,2),
	total_costo		DECIMAL(12,2),
	diferencia		DECIMAL(12,2),
	utilidad		DECIMAL(12,2),
	aprobar			CHAR(1),
	nom_cli			VARCHAR(100))

CREATE UNIQUE INDEX ind_num_prev ON temp_prev(num_preventa)

LET vm_max_rows = 250
IF num_args() = 5 THEN
	CALL ejecutar_aprobacion_preventa_automatica()
	EXIT PROGRAM
END IF
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12,
	INSERT KEY F30,
	DELETE KEY F31
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
OPEN WINDOW w_repp223 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp223 FROM '../forms/repf223_1'
ELSE
	OPEN FORM f_repp223 FROM '../forms/repf223_1c'
END IF
DISPLAY FORM f_repp223

CALL control_DISPLAY_botones()

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r23.* TO NULL
INITIALIZE rm_r24.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[2] = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 1
CALL control_cargar_detalle()
CALL control_ingreso_detalle()

END FUNCTION



FUNCTION ejecutar_aprobacion_preventa_automatica()
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE i, done		SMALLINT
DEFINE mensaje		VARCHAR(100)

CALL retorna_tam_arr()
LET vm_filas_pant  = vm_size_arr
LET vm_num_rows    = 0
LET vm_row_current = 0
INITIALIZE rm_r23.*, rm_r24.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[2]        = 'ASC'
LET vm_columna_1       = 2
LET vm_columna_2       = 1
LET rm_r23.r23_numprev = arg_val(5)
CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, rm_r23.r23_numprev)
	RETURNING r_r23.*
IF r_r23.r23_estado <> 'A' THEN
	RETURN
END IF
CALL control_cargar_detalle()
BEGIN WORK
CALL control_actualizacion() RETURNING done
IF done = 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se realizó proceso de Aprobación Pre-Venta.', 'stop')
	EXIT PROGRAM
END IF 
CALL control_credito() RETURNING done
IF done = 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se realizó proceso de Aprobación Pre-Venta verificando Crédito.', 'stop')
	EXIT PROGRAM
END IF
COMMIT WORK
LET mensaje = 'Aprobación de Pre-Venta ', rm_r23.r23_numprev USING "<<<<<<&",
		' Generada Ok.'
--CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_mostrar_detalle_preventa(i)
DEFINE i		SMALLINT
DEFINE num_cols 	SMALLINT

LET num_cols = 71
IF vg_gui = 0 THEN
	LET num_cols = 72
END IF
OPEN WINDOW w_repp223_2 AT 4, 5 WITH 19 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, 
		  MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp223_2 FROM '../forms/repf223_2'
ELSE
	OPEN FORM f_repp223_2 FROM '../forms/repf223_2c'
END IF
DISPLAY FORM f_repp223_2

CALL control_DISPLAY_botones_2()

LET tot_utilidad = r_detalle[i].utilidad
CALL control_cargar_detalle_preventa(r_detalle[i].num_preventa)
CALL fl_lee_moneda(rm_r23.r23_moneda) 	-- PARA OBTENER EL NOMBRE DE LA MONEDA 
	RETURNING rm_g13.*		   	    

DISPLAY rm_g13.g13_nombre TO nom_moneda
DISPLAY BY NAME rm_r23.r23_moneda, tot_precio_descuento, tot_costo, 
		tot_diferencia,	tot_utilidad, rm_r23.r23_nomcli
CALL control_DISPLAY_detalle_preventa()
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_repp223_2 
	RETURN
END IF

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE i,j,k,m,salir,done	SMALLINT
DEFINE resp			CHAR(6)
DEFINE command_line		VARCHAR(100)
DEFINE query			VARCHAR(200)
DEFINE run_prog		CHAR(10)

LET salir = 0
CALL retorna_tam_arr()
LET vm_filas_pant  = vm_size_arr
LET k = 1
WHILE NOT salir

	LET query = 'SELECT * FROM temp_prev ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
		      	      vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE dprev FROM query
	DECLARE q_dprev CURSOR FOR dprev

	LET i = 1
	FOREACH q_dprev INTO r_detalle[i].*, r_detalle_2[i].r23_nomcli
		LET i = i + 1
	END FOREACH
	LET i = 1
	LET j = 1
	LET int_flag = 0
	CALL set_count(vm_ind_arr)
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			IF INFIELD(aprobar) THEN
				CALL control_mostrar_detalle_preventa(i)
			END IF 
		ON KEY(F6)
			{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
			LET run_prog = 'fglrun '
			IF vg_gui = 0 THEN
				LET run_prog = 'fglgo '
			END IF
			{--- ---}
			LET command_line = run_prog || 'repp209 ' || vg_base
					    || ' ' || vg_modulo || ' '
					    || vg_codcia || ' ' || vg_codloc
					    || ' ' || r_detalle[i].num_preventa
			RUN command_line
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()    # POSICION CORRIENTE EN PANTALLA
			CLEAR r23_nomcli
			CALL muestra_contadores(i)
		BEFORE INSERT  
			IF i = arr_count() THEN
				LET vm_ind_arr = arr_count() - 1
			ELSE
				LET vm_ind_arr = arr_count()
			END IF
			EXIT INPUT

		AFTER INPUT 
		FOR m = 1 TO arr_count()
			IF r_detalle[m].aprobar = 'P' THEN
				LET m = 0
				EXIT FOR
			END IF
		END FOR
		IF m = 0 THEN
			BEGIN WORK
				CALL control_actualizacion()
					RETURNING done
				IF done = 0 THEN
					ROLLBACK WORK
					--CALL fgl_winmessage(vg_producto,'No se realizó proceso.','exclamation')
					CALL fl_mostrar_mensaje('No se realizó proceso.','exclamation')
					CONTINUE INPUT
				END IF 
				CALL control_credito()
					RETURNING done
				IF done = 0 THEN
					ROLLBACK WORK
					--CALL fgl_winmessage(vg_producto,'No se realizó proceso.','exclamation')
					CALL fl_mostrar_mensaje('No se realizó proceso.','exclamation')
				ELSE
					COMMIT WORK
					--CALL fgl_winmessage(vg_producto,'Registros actualizados Ok.','info')
					CALL fl_mostrar_mensaje('Registros actualizados Ok.','info')
					CALL control_cargar_detalle()
				END IF
		END IF
		ON KEY(F15)
			--LET r_detalle[i].aprobar =  r_detalle[j].aprobar
			LET k = 1
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F16)
			--LET r_detalle[i].aprobar = GET_FLDBUF(r_detalle[j].aprobar)
			LET k = 2
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F17)
			--LET r_detalle[i].aprobar = GET_FLDBUF(r_detalle[j].aprobar)
			LET k = 3
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F18)
			--LET r_detalle[i].aprobar = GET_FLDBUF(r_detalle[j].aprobar)
			LET k = 4
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F19)
			--LET r_detalle[i].aprobar = GET_FLDBUF(r_detalle[j].aprobar)
			LET k = 5
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F20)
			--LET r_detalle[i].aprobar = GET_FLDBUF(r_detalle[j].aprobar)
			LET k = 6
			LET int_flag = 2
			EXIT INPUT
	END INPUT
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF

	FOR m = 1 TO arr_count()
		UPDATE temp_prev SET aprobar = r_detalle[m].aprobar
			WHERE num_preventa  = r_detalle[m].num_preventa
	END FOR
			 
	IF int_flag = 2 THEN
		IF k <> vm_columna_1 THEN
			LET vm_columna_2           = vm_columna_1 
			LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
			LET vm_columna_1 = k 
		END IF
		IF rm_orden[vm_columna_1] = 'ASC' THEN
			LET rm_orden[vm_columna_1] = 'DESC'
		ELSE
			LET rm_orden[vm_columna_1] = 'ASC'
		END IF
	END IF
END WHILE

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'Estado'        TO tit_col1
--#DISPLAY 'No.'           TO tit_col2
--#DISPLAY 'Total sin IVA' TO tit_col3
--#DISPLAY 'Total Costo'   TO tit_col4
--#DISPLAY 'Diferencia'    TO tit_col5
--#DISPLAY '% Util.'       TO tit_col6

END FUNCTION



FUNCTION control_DISPLAY_botones_2()

--#DISPLAY 'Cant'      		TO tit_col1
--#DISPLAY 'Item'          	TO tit_col2
--#DISPLAY 'Dscto'          	TO tit_col3
--#DISPLAY 'Precio - Dscto' 	TO tit_col4
--#DISPLAY 'Total Costo'   	TO tit_col5
--#DISPLAY 'Diferencia'    	TO tit_col6
--#DISPLAY '% Util.'       	TO tit_col7

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE query		CHAR(800)
DEFINE expr_numprev	VARCHAR(100)
DEFINE i 		SMALLINT

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	IF num_args() <> 5 THEN
		CLEAR r_detalle[i].*
	END IF
END FOR
LET vm_estado    = 'A'
LET vm_estado_2  = 'N'
LET expr_numprev = NULL
IF num_args() = 5 THEN
	LET expr_numprev = '   AND r23_numprev   = ', rm_r23.r23_numprev
END IF
LET query = 'SELECT r23_nomcli, r23_estado, r23_cont_cred, r23_numprev, ',
		    ' r23_tot_bruto - r23_tot_dscto, r23_tot_costo ',
		' FROM rept023 ',
		' WHERE r23_compania  = ', vg_codcia,
		'   AND r23_localidad = ', vg_codloc,
		expr_numprev CLIPPED,
		'   AND r23_estado   IN ("', vm_estado,'",', 
					'"', vm_estado_2,'")'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET i = 1

DELETE FROM temp_prev

FOREACH q_cons INTO r_detalle_2[i].r23_nomcli,    r_detalle_2[i].r23_estado,
		    r_detalle_2[i].r23_cont_cred, r_detalle[i].num_preventa, 
		    r_detalle[i].total_sin_iva,   r_detalle[i].total_costo
        IF i  > vm_max_rows THEN
		EXIT FOREACH
	END IF	
	CASE r_detalle_2[i].r23_estado 
		WHEN 'A'
			LET r_detalle[i].tit_estado = 'SIN APROBAR'
		WHEN 'N'
			LET r_detalle[i].tit_estado = 'NO APROBADA'
	END CASE
	LET r_detalle[i].aprobar    = 'A'
	IF num_args() = 5 THEN
		LET r_detalle[i].aprobar = 'P'
	END IF
	LET r_detalle[i].diferencia = r_detalle[i].total_sin_iva - 
				      r_detalle[i].total_costo
	LET r_detalle[i].utilidad   = r_detalle[i].diferencia  / 
		     		      r_detalle[i].total_costo * 100	
	INSERT INTO temp_prev VALUES (r_detalle[i].*, r_detalle_2[i].r23_nomcli)

	LET i = i + 1
        IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	--CALL fgl_winmessage(vg_producto,'No existen Preventas para aprobación.','info')
	CALL fl_mostrar_mensaje('No existen Preventas para aprobación.','info')
	LET i = 0
	EXIT PROGRAM
END IF
LET vm_ind_arr = i
IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF
IF num_args() = 5 THEN
	RETURN
END IF
FOR i = 1 TO vm_filas_pant   
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

END FUNCTION



FUNCTION control_cargar_detalle_preventa(num_preventa)
DEFINE num_preventa	LIKE rept023.r23_numprev
DEFINE i 		SMALLINT
DEFINE query 		CHAR(300)
DEFINE r_r10		RECORD LIKE rept010.*	-- MAESTRO DE ITEMS

CALL retorna_tam_arr2()
LET vm_filas_pant = vm_size_arr2
FOR i = 1 TO vm_filas_pant 
	CLEAR r_preventa[i].*
END FOR
LET query = 'SELECT r24_cant_ven, r24_item, r24_descuento, ',
		    ' (r24_precio * r24_cant_ven) - r24_val_descto ',
		  ' FROM rept024 ',
            	'WHERE r24_compania  = ', vg_codcia, 
	    	'  AND r24_localidad = ', vg_codloc,
            	'  AND r24_numprev   = ', num_preventa
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2

CALL fl_lee_preventa_rep(vg_codcia,vg_codloc,num_preventa)
	RETURNING rm_r23.*
LET tot_precio_descuento = 0
LET tot_costo	         = 0
LET tot_diferencia       = 0
LET i = 1
FOREACH q_cons2 INTO r_preventa[i].r24_cant_ven,  r_preventa[i].r24_item,
		     r_preventa[i].r24_descuento, r_preventa[i].precio_descuento
	CALL fl_lee_item(vg_codcia, r_preventa[i].r24_item)
		RETURNING r_r10.*
	IF rm_r23.r23_moneda = rg_gen.g00_moneda_base THEN
		LET r_preventa[i].costo_item = r_preventa[i].r24_cant_ven *
					       r_r10.r10_costo_mb
	ELSE
		LET r_preventa[i].costo_item = r_preventa[i].r24_cant_ven *
					       r_r10.r10_costo_ma
	END IF	 
	LET r_preventa_2[i].nom_item = r_r10.r10_nombre
	LET r_preventa[i].diferencia = r_preventa[i].precio_descuento - 
				       r_preventa[i].costo_item
	LET r_preventa[i].utilidad   = r_preventa[i].diferencia  / 
		     		       r_preventa[i].costo_item * 100	
	LET tot_precio_descuento     = tot_precio_descuento +
				       r_preventa[i].precio_descuento
	LET tot_costo		     = tot_costo +
				       r_preventa[i].costo_item
	LET tot_diferencia           = tot_diferencia +
				       r_preventa[i].diferencia
	LET i = i + 1
        IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET i = 0
	CLEAR FORM
	RETURN
END IF
LET vm_num_detalle = i

END FUNCTION



FUNCTION control_DISPLAY_detalle_preventa()
DEFINE j,i		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL set_count(vm_num_detalle)
DISPLAY ARRAY r_preventa TO r_preventa.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
		LET int_flag = 0
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL fl_lee_item(vg_codcia,r_preventa[i].r24_item) 
			RETURNING r_r10.*  
		DISPLAY r_r10.r10_nombre TO nom_item 
		CALL muestra_descripciones(r_preventa[i].r24_item,
			r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, 
			r_r10.r10_cod_clase)
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#DISPLAY '' AT 5,1
		--#DISPLAY i,' de ',vm_num_detalle AT 5,58
		--#DISPLAY r_preventa_2[i].nom_item TO nom_item 
		--#CALL fl_lee_item(vg_codcia,r_preventa[i].r24_item) 
			--#RETURNING r_r10.*  
		--#DISPLAY r_r10.r10_nombre TO nom_item 
		--#CALL muestra_descripciones(r_preventa[i].r24_item,
			--#r_r10.r10_linea, r_r10.r10_sub_linea,
			--#r_r10.r10_cod_grupo, 
			--#r_r10.r10_cod_clase)
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_actualizacion()
DEFINE done,j           SMALLINT
DEFINE mensaje		VARCHAR(100)

LET j	     = 1
LET done     = 0
WHILE TRUE
        WHENEVER ERROR CONTINUE
	IF r_detalle[j].aprobar = 'P' THEN
		UPDATE rept023 SET r23_estado = 'P'
                      WHERE r23_compania  = vg_codcia
                        AND r23_localidad = vg_codloc
                        AND r23_numprev   = r_detalle[j].num_preventa

		LET done = control_actualizacion_caja(r_detalle[j].num_preventa)
		IF done = 0 THEN
			EXIT WHILE
		END IF

	END IF
        WHENEVER ERROR STOP
        IF STATUS < 0 THEN
		LET mensaje = 'La preventa número ', r_detalle[j].num_preventa,
				' del cliente ', r_detalle_2[j].r23_nomcli,
				' está siendo modificada, no se realizará ',
				'la aprobacion.'
                --CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		EXIT WHILE
        END IF
	LET j = j + 1
	IF j > vm_ind_arr THEN
		LET done     = 1
		EXIT WHILE
	END IF
END WHILE
RETURN done

END FUNCTION



FUNCTION control_credito()
DEFINE done,j 		SMALLINT 
DEFINE r_r25		RECORD LIKE rept025.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE fecha_aux	DATE 

WHENEVER ERROR CONTINUE

LET done = 0 
LET j    = 1
WHILE TRUE

	IF r_detalle[j].aprobar = 'P' AND r_detalle_2[j].r23_cont_cred = 'R'
	   THEN

		CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, 
					 r_detalle[j].num_preventa)
			RETURNING r_r23.*

		CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, 
					      r_r23.r23_codcli)
			RETURNING r_z02.*
		IF r_z02.z02_credit_dias = 0 THEN
			LET r_z02.z02_credit_dias = 30
		END IF
		CALL fl_lee_cabecera_credito_rep(vg_codcia, vg_codloc,
			                         r_detalle[j].num_preventa)
			RETURNING r_r25.*
		IF r_r25.r25_compania IS NULL THEN
			DELETE FROM rept025
				WHERE r25_compania  = vg_codcia
			        AND   r25_localidad = vg_codloc
			        AND   r25_numprev   = r_detalle[j].num_preventa

			DELETE FROM rept026
				WHERE r26_compania  = vg_codcia
			        AND   r26_localidad = vg_codloc
			        AND   r26_numprev   = r_detalle[j].num_preventa

			DELETE FROM rept027
				WHERE r27_compania  = vg_codcia
				AND   r27_localidad = vg_codloc
				AND   r27_numprev   = r_detalle[j].num_preventa

			INSERT INTO rept025 VALUES(vg_codcia, vg_codloc, 
					r_detalle[j].num_preventa, 0, 
					r_r23.r23_tot_neto, 0, 1, 
					r_z02.z02_credit_dias, null, null)

			LET fecha_aux = TODAY + r_z02.z02_credit_dias 

			INSERT INTO rept026 VALUES(vg_codcia, vg_codloc,  
					r_r23.r23_numprev, 1, 
					r_r23.r23_tot_neto, 0, 
			       		fecha_aux)
		END IF
	END IF
	LET j = j + 1
	IF j > vm_ind_arr THEN
		LET done     = 1
		EXIT WHILE
	END IF
END WHILE

WHENEVER ERROR STOP
IF status < 0 THEN
	LET done = 0
END IF

RETURN done 

END FUNCTION



FUNCTION control_actualizacion_caja(num_preventa)
DEFINE num_preventa 	LIKE rept023.r23_numprev
DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE anticipos	DECIMAL(12,2)

CALL fl_lee_preventa_rep(vg_codcia,vg_codloc,num_preventa)
	RETURNING rm_r23.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_j10.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_j10 CURSOR FOR
			SELECT * FROM cajt010
				WHERE j10_compania    = vg_codcia      
				  AND j10_localidad   = vg_codloc       
				  AND j10_tipo_fuente = 'PR'
				  AND j10_num_fuente  =	rm_r23.r23_numprev
			FOR UPDATE
	OPEN  q_j10
	FETCH q_j10 INTO r_j10.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF

-- GVA * 
	DELETE FROM cajt010 
		WHERE j10_compania    = vg_codcia      
		  AND j10_localidad   = vg_codloc       
		  AND j10_tipo_fuente = 'PR'
		  AND j10_num_fuente  =	rm_r23.r23_numprev
{
DELETE FROM cajt010 WHERE CURRENT OF q_j10 
CLOSE q_j10
FREE  q_j10
}
CALL fl_lee_grupo_linea(vg_codcia, rm_r23.r23_grupo_linea)
	RETURNING rm_g20.*

LET r_j10.j10_areaneg   = rm_g20.g20_areaneg
LET r_j10.j10_codcli    = rm_r23.r23_codcli
LET r_j10.j10_nomcli    = rm_r23.r23_nomcli
LET r_j10.j10_moneda    = rm_r23.r23_moneda

LET r_j10.j10_fecha_pro   = CURRENT
LET r_j10.j10_usuario     = vg_usuario 
LET r_j10.j10_fecing      = CURRENT
LET r_j10.j10_compania    = vg_codcia
LET r_j10.j10_localidad   = vg_codloc
LET r_j10.j10_tipo_fuente = 'PR'
LET r_j10.j10_num_fuente  = rm_r23.r23_numprev
LET r_j10.j10_estado      = 'A'

INITIALIZE r_j10.j10_codigo_caja,  r_j10.j10_tipo_destino, 
 	   r_j10.j10_num_destino,  r_j10.j10_referencia,     
 	   r_j10.j10_banco,        r_j10.j10_numero_cta,   
	   r_j10.j10_tip_contable, r_j10.j10_num_contable,
	   anticipos
           TO NULL    

-- Para verificar si existen pagos anticipados o NC aplicados a la preventa 
SELECT SUM(r27_valor) INTO anticipos FROM rept027
	WHERE r27_compania  = vg_codcia
	  AND r27_localidad = vg_codloc
	  AND r27_numprev   = rm_r23.r23_numprev

IF anticipos IS NULL THEN 
	LET anticipos = 0
END IF
                                                                
IF rm_r23.r23_cont_cred = 'R' THEN
	LET r_j10.j10_valor = 0
ELSE
	LET r_j10.j10_valor = rm_r23.r23_tot_neto - anticipos 
END IF

INSERT INTO cajt010 VALUES(r_j10.*)

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()
DEFINE intentar         SMALLINT
DEFINE resp             CHAR(6)
                                                                                
LET intentar = 1
--CALL fgl_winquestion(vg_producto,'Registro bloqueado por otro usuario, desea intentarlo nuevamente','No','Yes|No','question',1)
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente','No')
	RETURNING resp
IF resp = 'No' THEN
	LET intentar = 0
END IF
RETURN intentar

END FUNCTION






FUNCTION muestra_contadores(i)
DEFINE i 	SMALLINT

IF vg_gui = 1 THEN
	DISPLAY '' AT 19,1
	DISPLAY i, ' de ', vm_ind_arr AT 19, 5 
END IF
DISPLAY r_detalle_2[i].r23_nomcli TO r23_nomcli

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

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

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 14
END IF

END FUNCTION



FUNCTION retorna_tam_arr2()

--#LET vm_size_arr2 = fgl_scr_size('r_preventa')
IF vg_gui = 0 THEN
	LET vm_size_arr2 = 5
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
DISPLAY '<F5>      Mostrar Detalle Pre-Venta' AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Ver Pre-Venta'             AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

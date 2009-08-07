------------------------------------------------------------------------------
-- Titulo           : repp210.4gl - Forma de Pago Pre-Venta
-- Elaboracion      : 25-oct-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp210 base modulo compania localidad [numprev]
-- Ultima Correccion: 18-may-2005
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r23			RECORD LIKE rept023.*	-- CABECERA PREVENTA
DEFINE rm_r24		 	RECORD LIKE rept024.*	-- DETALLE PREVENTA
DEFINE rm_r25		 	RECORD LIKE rept025.*	-- CABECERA CREDITO
DEFINE rm_r25_2		 	RECORD LIKE rept025.*	-- CAB. CRED. AUXILIAR
DEFINE rm_r26		 	RECORD LIKE rept026.*	-- DETALLE CREDITO
DEFINE rm_r27		 	RECORD LIKE rept027.*	-- ANTICIPOS
DEFINE rm_z21		 	RECORD LIKE cxct021.*	-- ANTICIPOS
DEFINE rm_g13			RECORD LIKE gent013.*	-- MONEDA
DEFINE rm_g20			RECORD LIKE gent020.*	-- GRUPO LINEA
DEFINE rm_z02			RECORD LIKE cxct002.*	-- CLIENTE LOCALIDAD
DEFINE rm_z03			RECORD LIKE cxct003.*	-- CLIENTE AREA NEGOCIO
DEFINE dias_entre_pagos		SMALLINT
DEFINE fecha_primer_pago	DATE

	---- DETALLE PRIMERA PRESENTACION  ----
DEFINE r_detalle ARRAY[1000] OF RECORD
	num_preventa		LIKE rept023.r23_numprev,
	tit_estado		VARCHAR(11),
	valor_neto		LIKE rept023.r23_tot_neto,
	valor_anticipos		LIKE rept025.r25_valor_ant,
	monto_credito		LIKE rept025.r25_valor_cred
	END RECORD
	---------------------------------------------
	---- ARREGLO PARALELO PARA EL ESTADO y NOMBRE DE CLIENTE----
DEFINE r_detalle_1 ARRAY[1000] OF RECORD
	r23_estado 	LIKE rept023.r23_estado,
	r23_nomcli	LIKE rept023.r23_nomcli
	END RECORD	
	------------------------------------------------------------
	---- DETALLE CREDITO CON DIVIDENDOS ----
DEFINE r_detalle_3 ARRAY[200] OF RECORD
	r26_dividendo	LIKE rept026.r26_dividendo,
	r26_fec_vcto	LIKE rept026.r26_fec_vcto,
	r26_valor_cap	LIKE rept026.r26_valor_cap,
	r26_valor_int	LIKE rept026.r26_valor_int,
	total 		LIKE rept026.r26_valor_cap
	END RECORD
DEFINE vm_tot_cap 	LIKE rept026.r26_valor_cap
DEFINE vm_tot_interes 	LIKE rept026.r26_valor_int
DEFINE vm_total 	LIKE rept026.r26_valor_cap
	---------------------------------------------
	-------------- DETALLE ANTICIPOS -------------
DEFINE r_detalle_2 ARRAY[100] OF RECORD
	z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
	z21_num_doc	LIKE cxct021.z21_num_doc,
	z21_moneda	LIKE cxct021.z21_moneda,
	z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
	z21_saldo	LIKE cxct021.z21_saldo,
	r27_valor	LIKE rept027.r27_valor
	END RECORD
DEFINE total_anticipos		LIKE rept027.r27_valor
DEFINE total_anticipos_aux	LIKE rept027.r27_valor
	----------------------------------------------

DEFINE vm_areaneg		LIKE cxct021.z21_areaneg
DEFINE vm_credito		LIKE rept023.r23_cont_cred
DEFINE vm_estado		LIKE rept023.r23_estado
DEFINE vm_estado_2		LIKE rept023.r23_estado
DEFINE vm_num_detalle		SMALLINT   -- INDICE DE LA PREVENTA (ARRAY)
DEFINE vm_ind_arr		SMALLINT   -- INDICE DE MI ARREGLO  (ARRAY)
DEFINE vm_filas_pant		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_ind_docs 		SMALLINT   -- INDICE DE DOCUMENTOS
DEFINE vm_ind_div 		SMALLINT   -- INDICE DE DIVIDENDOS
DEFINE vm_cont_cred 		LIKE rept023.r23_cont_cred -- TIPO DE PAGO
DEFINE vm_flag_anticipos	CHAR(1) -- PARA SABER SI TIENE O NO ANTICIPOS
					-- 'S' o 'N'
DEFINE vm_flag_grabar		CHAR(1) -- PARA SABER SI TIENE O NO QUE GRABAR
					-- 'S' o 'N'
DEFINE vg_numprev		LIKE rept023.r23_numprev
DEFINE vm_flag_dividendos	CHAR(1)	-- PARA SABER SI TIENE O NO DIVIDENDOS
					-- 'S' o 'N'


MAIN
	
LET vm_max_rows     = 1000
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp210.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4  AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base            = arg_val(1)
LET vg_modulo          = arg_val(2)
LET vg_codcia          = arg_val(3)
LET vg_codloc          = arg_val(4)
LET vg_numprev         = arg_val(5)
LET vg_proceso = 'repp210'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CREATE TEMP TABLE temp_prev_2(
	num_preventa		INTEGER,
	tit_estado		VARCHAR(11),
	valor_neto		DECIMAL(12,2),
	valor_anticipos		DECIMAL(12,2),
	monto_credito		DECIMAL(12,2),
	nombre_cliente		VARCHAR(45,20))

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 5 THEN
	CALL control_menu_credito(vg_numprev)
	EXIT PROGRAM
END IF

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12,
	INSERT KEY F30,
	DELETE KEY F31

OPEN WINDOW w_repp210 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_repp210 FROM '../forms/repf210_1'
DISPLAY FORM f_repp210

LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r23.* TO NULL
INITIALIZE rm_r24.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'DESC'
LET rm_orden[2]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_credito   = 'R'
LET vm_estado    = 'A'
LET vm_estado_2  = 'P'
DISPLAY 'No.'  		        TO tit_col1
DISPLAY 'Estado'  		TO tit_col2
DISPLAY 'Valor Neto'		TO tit_col3
DISPLAY 'Valor Anticipo'   	TO tit_col4
DISPLAY 'Monto Crédito'    	TO tit_col5
CALL control_cargar_detalle()
CALL control_display_detalle()

END FUNCTION



FUNCTION control_display_botones_anticipos()

DISPLAY 'Tip'		TO tit_col1
DISPLAY 'No. Doc.'	TO tit_col2
DISPLAY 'Mon'		TO tit_col3
DISPLAY 'Fec. Emisión'	TO tit_col4
DISPLAY 'Saldo Doc.'	TO tit_col5
DISPLAY 'Valor a usar'	TO tit_col6

END FUNCTION



FUNCTION control_display_botones_credito()

DISPLAY 'Pago'		TO tit_col1
DISPLAY 'Fec. Vcto.'	TO tit_col2
DISPLAY 'Valor Capital'	TO tit_col3
DISPLAY 'Valor Interes'	TO tit_col4
DISPLAY 'Valor Total'	TO tit_col5

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE query	VARCHAR(600)
DEFINE i 	SMALLINT

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET query = 'SELECT r23_nomcli, r23_estado, r23_numprev, 
		    r23_tot_neto
		 FROM rept023 
		WHERE r23_compania  =  ', vg_codcia,
		' AND r23_localidad =  ', vg_codloc,
		' AND r23_cont_cred = "', vm_credito,'"', 
		' AND r23_estado    = "', vm_estado_2,'"'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET i = 1

DELETE FROM temp_prev_2

FOREACH q_cons INTO r_detalle_1[i].r23_nomcli, r_detalle_1[i].r23_estado, 
		    r_detalle[i].num_preventa, r_detalle[i].valor_neto
	CASE r_detalle_1[i].r23_estado 
		WHEN 'A'
			LET r_detalle[i].tit_estado = 'SIN APROBAR'
		WHEN 'P'
			LET r_detalle[i].tit_estado = 'APROBADA'
	END CASE
	CALL fl_lee_cabecera_credito_rep(vg_codcia, vg_codloc,
				     	 r_detalle[i].num_preventa)
		RETURNING rm_r25.*
	IF rm_r25.r25_numprev IS NOT NULL THEN
		LET r_detalle[i].valor_anticipos = rm_r25.r25_valor_ant
		LET r_detalle[i].monto_credito   = rm_r25.r25_valor_cred
	ELSE
		LET r_detalle[i].valor_anticipos = 0
		LET r_detalle[i].monto_credito   = 0
	END IF
		
	INSERT INTO temp_prev_2 VALUES (r_detalle[i].*, r_detalle_1[i].r23_nomcli)

	LET i = i + 1
        IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1

IF i = 0 THEN
	CALL fgl_winmessage(vg_producto,'No existen preventas a crédito. ',
			    'info')
	EXIT PROGRAM
END IF

LET vm_num_detalle = i

END FUNCTION



FUNCTION control_display_detalle()
DEFINE j,i,k 		SMALLINT
DEFINE command_line	VARCHAR(100)
DEFINE query		VARCHAR(600)
DEFINE resp		CHAR(6)

LET k = 1
WHILE TRUE
	LET query = 'SELECT * FROM temp_prev_2 ',
		' ORDER BY ', vm_columna_1, ' ',
		      rm_orden[vm_columna_1], ', ',
		      vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE	 dprev FROM query
	DECLARE q_dprev CURSOR FOR dprev
	LET i = 1
	FOREACH q_dprev INTO r_detalle[i].*, r_detalle_1[i].r23_nomcli
		LET i = i + 1
	END FOREACH
	LET i = 1
	LET j = 1
	LET int_flag = 0
	CALL set_count(vm_num_detalle)
	DISPLAY ARRAY r_detalle TO r_detalle.*
       		ON KEY(INTERRUPT)
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
               			EXIT PROGRAM
			END IF
			LET int_flag = 0
		ON KEY(F7)
			CALL control_menu_credito(r_detalle[i].num_preventa)
{
		ON KEY(F8)
			CALL control_ver_preventa(r_detalle[i].num_preventa)
       		BEFORE DISPLAY
       	        	CALL dialog.keysetlabel('ACCEPT', '')
}
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores(i)
			DISPLAY r_detalle_1[i].r23_nomcli TO nom_cliente
        	AFTER DISPLAY
               		 CONTINUE DISPLAY
		ON KEY(F15)
			LET k = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET k = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET k = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET k = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET k = 5
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
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



FUNCTION control_forma_pago(numprev)
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE fecha_1er_pago	DATE

LET vm_flag_grabar      = 'N'
LET vm_flag_anticipos   = 'N'
LET vm_flag_dividendos  = 'N'
LET total_anticipos     = 0
LET total_anticipos_aux = 0

CALL fl_lee_preventa_rep(vg_codcia,vg_codloc,numprev)
	RETURNING rm_r23.*

CALL fl_lee_grupo_linea(vg_codcia, rm_r23.r23_grupo_linea)
	RETURNING rm_g20.*

LET vm_areaneg = rm_g20.g20_areaneg

INITIALIZE rm_r25.*,fecha_primer_pago  TO NULL
LET fecha_primer_pago = TODAY


CALL fl_lee_cabecera_credito_rep(vg_codcia, vg_codloc, rm_r23.r23_numprev ) 
	RETURNING rm_r25.*
IF rm_r25.r25_numprev IS NULL THEN

	LET fecha_primer_pago     = TODAY
	LET rm_r25.r25_interes    = 0
	LET dias_entre_pagos      = 30
	LET rm_r25.r25_plazo      = calcula_plazo()
	LET rm_r25.r25_numprev    = rm_r23.r23_numprev
	LET rm_r25.r25_valor_cred = rm_r23.r23_tot_neto
	LET rm_r25.r25_valor_ant  = 0
	LET rm_r25.r25_dividendos = 1
	LET vm_flag_dividendos = 'S'
ELSE
	LET fecha_1er_pago = TODAY 
	IF rm_r25.r25_valor_cred + rm_r25.r25_valor_ant <> rm_r23.r23_tot_neto
   	   THEN
		LET fecha_primer_pago     = fecha_1er_pago
		LET rm_r25.r25_interes    = 0
		LET rm_r25.r25_interes    = 0
		LET rm_r25.r25_numprev    = rm_r23.r23_numprev
		LET rm_r25.r25_valor_cred = rm_r23.r23_tot_neto
		LET rm_r25.r25_valor_ant  = 0
	END IF
	LET dias_entre_pagos = rm_r25.r25_plazo

	CALL control_cargar_dividendos()

END IF
	
IF rm_r25.r25_valor_ant IS NULL THEN
	LET rm_r25.r25_valor_ant = 0
END IF

CALL fl_lee_moneda(rm_r23.r23_moneda) 	-- PARA OBTENER EL NOMBRE DE LA MONEDA 
	RETURNING rm_g13.*		   	    

DISPLAY BY NAME rm_r23.r23_moneda, fecha_primer_pago, rm_r25.r25_plazo,
		dias_entre_pagos,  rm_r25.r25_interes, rm_r25.r25_valor_ant,
		rm_r25.r25_valor_cred, rm_r25.r25_numprev, rm_r23.r23_codcli,
		rm_r23.r23_nomcli, rm_r25.r25_dividendos
DISPLAY rm_g13.g13_nombre TO nom_moneda

END FUNCTION



FUNCTION control_menu_credito(numprev)
DEFINE done 		SMALLINT
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE bloqueada	CHAR(1)
DEFINE resp		CHAR(6)

LET bloqueada = control_bloquear_preventa(numprev)

IF bloqueada = 'S' THEN
	CALL fgl_winmessage(vg_producto,'La preventa está siendo modificada.',
			    'exclamation')
		RETURN
END IF 

OPEN WINDOW w_210_3 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2,MENU LINE FIRST, COMMENT LINE LAST, 
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_210_3 FROM '../forms/repf210_3'
DISPLAY FORM f_210_3
CLEAR FORM
CALL control_display_botones_credito()

CALL control_forma_pago(numprev)


MENU 'OPCIONES'
	COMMAND KEY('V') 'Ver Preventa' 	'Ver toda la Preventa.'	
		CALL control_ver_preventa(rm_r23.r23_numprev)
	COMMAND KEY('A') 'Doc. a Favor'	       'Documentos a favor del Cliente.'
		CALL control_anticipos_cliente()
	COMMAND KEY('R') 'Crédito'		'Condiciones de Crédito.'
		CALL control_credito()
	COMMAND KEY('G') 'Grabar'		'Grabar el Crédito. '
		CALL control_grabar()
			RETURNING done
		IF done = 1 THEN
			EXIT MENU
		END IF
	COMMAND KEY('S') 'Salir' 		'Salir Menu.'
		LET resp = control_salir()
		IF resp = 'Yes' THEN
			EXIT MENU
		END IF
END MENU

CLOSE WINDOW w_210_3
IF num_args() = 5 THEN
	EXIT PROGRAM
END IF

CALL funcion_master()

END FUNCTION



FUNCTION control_salir()
DEFINE resp CHAR(6)

CALL fl_mensaje_abandonar_proceso()
	RETURNING resp
RETURN resp

END FUNCTION


FUNCTION control_bloquear_preventa(numprev)
DEFINE numprev 		LIKE rept023.r23_numprev
DEFINE bloqueada	CHAR(1) 	-- S BLOQUEADA
					-- N NO BLOQUEADA
LET bloqueada = 'N'
WHENEVER ERROR CONTINUE
BEGIN WORK
	
	DECLARE q_read_r23 CURSOR FOR 
		SELECT * FROM rept023 
			WHERE r23_compania  = vg_codcia
			AND   r23_localidad = vg_codloc 
			AND   r23_numprev   = numprev
		FOR UPDATE

	OPEN q_read_r23
	FETCH q_read_r23
	
	IF status < 0 THEN
		LET bloqueada = 'S'
	END IF
	
COMMIT WORK
WHENEVER ERROR STOP

RETURN bloqueada

END FUNCTION 



FUNCTION control_grabar()
DEFINE i,done 	SMALLINT
DEFINE resp	CHAR(6)

LET done = 0
IF vm_flag_grabar = 'N' THEN
	CALL fgl_winmessage(vg_producto,'Aun no ha actualizado el crédito. ','exclamation')
	RETURN done
END IF

BEGIN WORK
	
	DELETE FROM rept025
		WHERE r25_compania  = vg_codcia
		AND   r25_localidad = vg_codloc
		AND   r25_numprev   = rm_r23.r23_numprev

	LET rm_r25.r25_compania  = vg_codcia
	LET rm_r25.r25_localidad = vg_codloc
	LET rm_r25.r25_numprev   = rm_r23.r23_numprev
	IF total_anticipos IS NOT NULL  THEN
		LET rm_r25.r25_valor_ant = total_anticipos
	ELSE
		LET rm_r25.r25_valor_ant = 0 
	END IF

	INSERT INTO rept025 VALUES(rm_r25.*)

	DELETE FROM rept026
		WHERE r26_compania  = vg_codcia
		AND   r26_localidad = vg_codloc
		AND   r26_numprev   = rm_r23.r23_numprev

	LET rm_r26.r26_compania  = vg_codcia
	LET rm_r26.r26_localidad = vg_codloc
	LET rm_r26.r26_numprev   = rm_r23.r23_numprev

	FOR i = 1 TO rm_r25.r25_dividendos
		LET rm_r26.r26_dividendo = r_detalle_3[i].r26_dividendo
		LET rm_r26.r26_valor_cap = r_detalle_3[i].r26_valor_cap
		LET rm_r26.r26_valor_int = r_detalle_3[i].r26_valor_int
		LET rm_r26.r26_fec_vcto  = r_detalle_3[i].r26_fec_vcto

		INSERT INTO rept026 VALUES(rm_r26.*)

	END FOR

	IF vm_flag_anticipos = 'S' THEN
		CALL control_ingreso_anticipos()
			RETURNING done
		IF done = 0 THEN
			ROLLBACK WORK
			CALL fgl_winmessage(vg_producto,'No realizo la transacción. ','exclamation')
			RETURN
		END IF
	END IF

	CALL control_actualizacion_caja()
		RETURNING done
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en la actualización de la caja','exclamation')
		RETURN
	END IF 

IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'No se pudo realizar la transacción a ocurrido un error. ','exclamation')
	RETURN
END IF
	COMMIT WORK
   	LET done = 1
	CALL fgl_winmessage(vg_producto,'Proceso realizado Ok. ','info')

RETURN done

END FUNCTION



FUNCTION control_actualizacion_caja()
DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_upd		RECORD LIKE cajt010.*

IF rm_r23.r23_estado <> 'P' THEN
	RETURN 1
END IF

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
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET intentar = mensaje_intentar()
		CLOSE q_j10
		FREE  q_j10
	ELSE
		WHENEVER ERROR STOP
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF

IF r_j10.j10_compania IS NOT NULL THEN
	DELETE FROM cajt010 WHERE CURRENT OF q_j10
END IF
CLOSE q_j10
FREE  q_j10

LET r_j10.j10_areaneg   = rm_g20.g20_areaneg
LET r_j10.j10_codcli    = rm_r23.r23_codcli
LET r_j10.j10_nomcli    = rm_r23.r23_nomcli
LET r_j10.j10_moneda    = rm_r23.r23_moneda

IF rm_r23.r23_cont_cred = 'R' THEN
	LET r_j10.j10_valor = 0
ELSE
	IF vm_flag_anticipos = 'S' THEN
		LET r_j10.j10_valor = rm_r23.r23_tot_neto -
				      total_anticipos
	ELSE
		LET r_j10.j10_valor = rm_r23.r23_tot_neto 
	END IF
	
END IF

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
	   r_j10.j10_tip_contable, r_j10.j10_num_contable
           TO NULL    
                                                                
INSERT INTO cajt010 VALUES(r_j10.*)

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()
DEFINE intentar         SMALLINT
DEFINE resp             CHAR(6)
                                                                                
LET intentar = 1
CALL fgl_winquestion(vg_producto,
                     'Registro bloqueado por otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
                                RETURNING resp
IF resp = 'No' THEN
	LET intentar = 0
END IF
                                                                                
RETURN intentar
                                                                                
END FUNCTION



FUNCTION control_credito()
DEFINE r_r25 		RECORD LIKE rept025.*
DEFINE fecha_aux 	LIKE rept026.r26_fec_vcto
DEFINE dias	 	SMALLINT

LET r_r25.*   = rm_r25.*
LET fecha_aux = fecha_primer_pago
LET dias      = dias_entre_pagos
CALL control_ingreso_credito()

IF NOT int_flag THEN
	IF rm_r25.r25_interes <= 0 THEN
		IF r_r25.r25_dividendos <> rm_r25.r25_dividendos OR
		   r_r25.r25_interes    <> rm_r25.r25_interes    OR
		   fecha_aux            <> fecha_primer_pago     OR
		   dias	                <> dias_entre_pagos      OR
		   vm_flag_dividendos    = 'S' -- CUANDO NO HAYA DIVIDENDOS
		   THEN
			CALL control_cargar_detalle_credito()
		END IF
		CALL control_ingreso_detalle_credito()
		LET vm_flag_grabar = 'S'
	ELSE
		IF r_r25.r25_dividendos <> rm_r25.r25_dividendos OR
		   r_r25.r25_interes    <> rm_r25.r25_interes    OR
		   fecha_aux            <> fecha_primer_pago     OR
		   dias	                <> dias_entre_pagos
		   THEN
			CALL control_cargar_detalle_credito()
		END IF
		CALL control_display_detalle_credito()
		LET vm_flag_grabar = 'S'
	END IF
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION control_cargar_dividendos()
DEFINE i 	SMALLINT

DECLARE q_read_r26 CURSOR FOR
	SELECT * FROM rept026
		WHERE r26_compania  = vg_codcia
		  AND r26_localidad = vg_codloc
		  AND r26_numprev   = rm_r23.r23_numprev

OPEN q_read_r26
FETCH q_read_r26 INTO rm_r26.*
IF status = NOTFOUND THEN
	CLOSE q_read_r26
	RETURN
ELSE
	LET i = 1
	FOREACH q_read_r26 INTO rm_r26.*	
		
		IF i = 1 THEN
			LET fecha_primer_pago = rm_r26.r26_fec_vcto
		END IF

		LET r_detalle_3[i].r26_dividendo = rm_r26.r26_dividendo	
		LET r_detalle_3[i].r26_fec_vcto  = rm_r26.r26_fec_vcto	
		LET r_detalle_3[i].r26_valor_cap = rm_r26.r26_valor_cap	
		LET r_detalle_3[i].r26_valor_int = rm_r26.r26_valor_int	
		LET r_detalle_3[i].total         = rm_r26.r26_valor_cap +
						   rm_r26.r26_valor_int	
		LET i = i + 1
		IF i > 250 THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i > 1 THEN
		LET dias_entre_pagos = r_detalle_3[2].r26_fec_vcto -
				       r_detalle_3[1].r26_fec_vcto	 
	END IF

	LET vm_ind_div = i
	LET vm_filas_pant = fgl_scr_size('r_detalle_3')
	IF vm_ind_div < vm_filas_pant THEN
		LET vm_filas_pant = vm_ind_div
	END IF 
	FOR i = 1 TO vm_filas_pant
		DISPLAY r_detalle_3[i].* TO r_detalle_3[i].*
	END FOR
	CALL calcula_interes()
END IF

END FUNCTION



FUNCTION control_cargar_detalle_credito()
DEFINE i 	SMALLINT
DEFINE saldo    LIKE rept025.r25_valor_cred
DEFINE val_div  LIKE rept026.r26_valor_cap

LET saldo   = rm_r25.r25_valor_cred
LET val_div = rm_r25.r25_valor_cred / rm_r25.r25_dividendos

FOR i = 1 TO rm_r25.r25_dividendos
	LET r_detalle_3[i].r26_dividendo = i
	IF i = 1 THEN
		LET r_detalle_3[i].r26_fec_vcto = fecha_primer_pago
	ELSE
		LET r_detalle_3[i].r26_fec_vcto = 
		    r_detalle_3[i-1].r26_fec_vcto + dias_entre_pagos
	END IF
	IF i <> rm_r25.r25_dividendos THEN
		LET r_detalle_3[i].r26_valor_cap = val_div
		LET saldo = saldo - val_div
	ELSE
		LET r_detalle_3[i].r26_valor_cap = saldo
	END IF
END FOR 
CALL calcula_interes()
	LET vm_filas_pant = fgl_scr_size('r_detalle_3')
	IF rm_r25.r25_dividendos < vm_filas_pant THEN
		LET vm_filas_pant = rm_r25.r25_dividendos
	END IF 
	FOR i = 1 TO vm_filas_pant
		DISPLAY r_detalle_3[i].* TO r_detalle_3[i].*
	END FOR

END FUNCTION



FUNCTION control_display_detalle_credito()

CALL set_count(rm_r25.r25_dividendos)
DISPLAY ARRAY r_detalle_3 TO r_detalle_3.* 
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT','')
        AFTER DISPLAY
                CONTINUE DISPLAY
        ON KEY(INTERRUPT)
                EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_ingreso_detalle_credito()
DEFINE resp 		CHAR(6)
DEFINE i,j,k		SMALLINT
DEFINE fecha_aux 	LIKE rept026.r26_fec_vcto
DEFINE r_det_aux	ARRAY[200] OF RECORD
	r26_dividendo	LIKE rept026.r26_dividendo,
	r26_fec_vcto	LIKE rept026.r26_fec_vcto,
	r26_valor_cap	LIKE rept026.r26_valor_cap,
	r26_valor_int	LIKE rept026.r26_valor_int,
	total 		LIKE rept026.r26_valor_cap
	END RECORD

FOR k = 1 TO rm_r25.r25_dividendos
	LET r_det_aux[k].*	= r_detalle_3[k].*
END FOR

OPTIONS
	INSERT KEY F30,
	DELETE KEY F40
LET int_flag = 0
WHILE TRUE
	CALL set_count(rm_r25.r25_dividendos) 
	INPUT ARRAY r_detalle_3 WITHOUT DEFAULTS FROM r_detalle_3.*
		BEFORE INPUT 
			CALL dialog.keysetlabel ('INSERT','')
			CALL dialog.keysetlabel ('DELETE','')
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
			IF resp = 'Yes' THEN
				FOR k = 1 TO rm_r25.r25_dividendos
					LET r_detalle_3[k].* = r_det_aux[k].*
				END FOR
				LET vm_filas_pant = fgl_scr_size('r_detalle_3')
				IF rm_r25.r25_dividendos < vm_filas_pant THEN
					LET vm_filas_pant= rm_r25.r25_dividendos
				END IF 
				FOR k = 1 TO vm_filas_pant
					DISPLAY r_detalle_3[k].* TO 
						r_detalle_3[k].*
				END FOR
				LET int_flag = 1
				EXIT INPUT
			END IF
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE INSERT
			EXIT INPUT
		BEFORE FIELD r26_fec_vcto
			LET fecha_aux = r_detalle_3[i].r26_fec_vcto
		AFTER FIELD r26_fec_vcto
			IF r_detalle_3[i].r26_fec_vcto IS NULL THEN
				LET r_detalle_3[i].r26_fec_vcto = fecha_aux
				DISPLAY r_detalle_3[i].r26_fec_vcto TO
					r_detalle_3[j].r26_fec_vcto
			END IF
		AFTER FIELD r26_valor_cap
			IF r_detalle_3[i].r26_valor_cap IS NOT NULL THEN
				CALL calcula_interes()
			ELSE 
				NEXT FIELD r26_valor_cap
			END IF
		AFTER INPUT
			FOR k = 1 TO arr_count() - 1
				IF r_detalle_3[k].r26_fec_vcto >=
				   r_detalle_3[k + 1].r26_fec_vcto
				   THEN
					CALL fgl_winmessage(vg_producto,'Existen fechas que resultan menores a las ingresadas anteriormente en los pagos. ','exclamation')
					EXIT INPUT
				END IF
			END FOR	
			IF vm_total > rm_r25.r25_valor_cred THEN
				CALL fgl_winmessage(vg_producto,'El total del valor capital es mayor al total de la deuda. ','exclamation')
				EXIT INPUT
			END IF
			IF vm_total < rm_r25.r25_valor_cred THEN
				CALL fgl_winmessage(vg_producto,'El total del valor capital es menor al total de la deuda. ','exclamation')
				EXIT INPUT
			END IF

-- Para evitar que se grabe una fecha de vencimiento < a today (1822)
			FOR i = 1 TO rm_r25.r25_dividendos
				IF r_detalle_3[i].r26_fec_vcto < TODAY THEN
					CALL fgl_winmessage(vg_producto,
						'La fecha de vencimiento ' ||
                                                ' no puede ser menor a la ' ||
						' fecha de hoy.',
						'exclamation')
					CONTINUE INPUT
				END IF
			END FOR

			LET rm_r25.r25_plazo = 
			    r_detalle_3[rm_r25.r25_dividendos].r26_fec_vcto -
			    TODAY 	
			DISPLAY BY NAME rm_r25.r25_plazo

			EXIT WHILE
	END INPUT
IF int_flag THEN
	RETURN
END IF
END WHILE	

END FUNCTION



FUNCTION calcula_interes()
DEFINE valor_cred	LIKE rept025.r25_valor_cred
DEFINE i 		SMALLINT

LET vm_tot_cap     = 0
LET vm_tot_interes = 0
LET vm_total       = 0
LET valor_cred = rm_r25.r25_valor_cred
FOR i = 1 TO rm_r25.r25_dividendos
	LET r_detalle_3[i].r26_valor_int = valor_cred * 
			                   (rm_r25.r25_interes / 100) *
		      			   (dias_entre_pagos /360)
	LET valor_cred = valor_cred - r_detalle_3[i].r26_valor_cap
	LET r_detalle_3[i].total = r_detalle_3[i].r26_valor_cap +
				   r_detalle_3[i].r26_valor_int
	LET vm_tot_cap     = vm_tot_cap     + r_detalle_3[i].r26_valor_cap
	LET vm_tot_interes = vm_tot_interes + r_detalle_3[i].r26_valor_int
	LET vm_total       = vm_total       + r_detalle_3[i].total
END FOR
DISPLAY BY NAME vm_tot_cap, vm_tot_interes, vm_total

END FUNCTION



FUNCTION control_anticipos_cliente()
DEFINE i		SMALLINT 
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_r27		RECORD LIKE rept027.*

OPEN WINDOW w_repp210_3 AT 8,11 WITH 14 ROWS, 68 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, 
		  MESSAGE LINE LAST - 1) 
OPEN FORM f_repp210_3 FROM '../forms/repf210_2'
DISPLAY FORM f_repp210_3
CLEAR FORM
CALL control_display_botones_anticipos()

IF total_anticipos_aux = total_anticipos THEN

	DECLARE q_read_z21 CURSOR FOR
		SELECT * FROM cxct021
			WHERE z21_compania  = vg_codcia
			  AND z21_localidad = vg_codloc
			  AND z21_codcli    = rm_r23.r23_codcli
			  AND z21_areaneg   = vm_areaneg
			  AND z21_moneda    = rm_r23.r23_moneda
			  AND z21_saldo     > 0		
			ORDER BY z21_fecha_emi 

	DECLARE q_read_r27 CURSOR FOR
		SELECT * FROM rept027
			WHERE r27_compania  = vg_codcia
			  AND r27_localidad = vg_codloc
			  AND r27_numprev   = rm_r23.r23_numprev
	
	LET i = 1
	FOREACH	 q_read_z21 INTO r_z21.*
		LET r_detalle_2[i].z21_tipo_doc  = r_z21.z21_tipo_doc
		LET r_detalle_2[i].z21_num_doc   = r_z21.z21_num_doc
		LET r_detalle_2[i].z21_moneda    = r_z21.z21_moneda
		LET r_detalle_2[i].z21_fecha_emi = r_z21.z21_fecha_emi
		LET r_detalle_2[i].z21_saldo     = r_z21.z21_saldo
		LET r_detalle_2[i].r27_valor     = 0 
		LET i = i + 1
		IF i > 100 THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	LET vm_ind_docs = i

	IF i = 0 THEN
		CALL fgl_winmessage(vg_producto,
			    'No hay documentos a favor para este cliente',
			    'exclamation')
		LET rm_r25.r25_valor_ant = 0
		CLOSE WINDOW w_repp210_3
		RETURN
	END IF

	FOREACH q_read_r27 INTO r_r27.* 
		FOR i = 1 TO vm_ind_docs 
			IF r_detalle_2[i].z21_tipo_doc = r_r27.r27_tipo 
			AND r_detalle_2[i].z21_num_doc = r_r27.r27_numero 
			THEN
				LET r_detalle_2[i].r27_valor = r_r27.r27_valor 
				EXIT FOR
			END IF
		END FOR
	END FOREACH
END IF

	CALL control_anticipos()
	IF NOT int_flag THEN
		CLOSE WINDOW w_repp210_3
		LET rm_r25.r25_valor_cred = rm_r23.r23_tot_neto
		LET rm_r25.r25_valor_ant = total_anticipos
		LET rm_r25.r25_valor_cred = rm_r25.r25_valor_cred - 
				            total_anticipos
		DISPLAY BY NAME rm_r25.r25_valor_ant
		DISPLAY BY NAME rm_r25.r25_valor_cred
		IF rm_r25.r25_dividendos IS NOT NULL THEN
			CALL control_cargar_detalle_credito()	
		END IF
		LET vm_flag_anticipos = 'S'
		LET vm_flag_grabar = 'S'
	END IF


END FUNCTION



FUNCTION control_ver_preventa(numprev)
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE command_line	VARCHAR(100)

LET command_line = 'fglrun repp209 ' || vg_base || ' '
	    || vg_modulo || ' ' || vg_codcia 
	    || ' ' || vg_codloc || ' PREV ' ||
	    numprev
RUN command_line

END FUNCTION



FUNCTION control_ingreso_credito()
DEFINE resp 	   	CHAR(6)

LET int_flag = 0
IF fecha_primer_pago IS NULL THEN
	LET fecha_primer_pago = TODAY + 30
END IF
INPUT BY NAME rm_r25.r25_numprev, rm_r23.r23_codcli, rm_r23.r23_nomcli,
	      rm_r25.r25_dividendos, rm_r25.r25_interes, rm_r25.r25_plazo, 
	      fecha_primer_pago, dias_entre_pagos, rm_r25.r25_valor_cred,
	      rm_r25.r25_valor_ant WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r23_codcli,  r23_nomcli, r25_dividendos,
				     r25_interes, dias_entre_pagos)
		THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
	AFTER FIELD r25_dividendos
		IF rm_r25.r25_dividendos IS NOT NULL THEN
			IF dias_entre_pagos IS NOT NULL THEN
				LET rm_r25.r25_plazo = rm_r25.r25_dividendos *
						       dias_entre_pagos
				DISPLAY BY NAME rm_r25.r25_plazo
			END IF
		END IF
	AFTER FIELD dias_entre_pagos
		IF dias_entre_pagos IS NOT NULL THEN
			IF rm_r25.r25_dividendos IS NOT NULL THEN
				LET rm_r25.r25_plazo = rm_r25.r25_dividendos *
						       dias_entre_pagos
				DISPLAY BY NAME rm_r25.r25_plazo
			END IF
		END IF
	AFTER FIELD fecha_primer_pago
		IF fecha_primer_pago IS NOT NULL THEN
			IF fecha_primer_pago < TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha ingresada debe ser mayor o igual a la de hoy. ','exclamation')	
				NEXT FIELD fecha_primer_pago
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION calcula_plazo()
DEFINE plazo 	LIKE cxct002.z02_credit_dias

CALL fl_lee_cliente_areaneg(vg_codcia, vg_codloc, vm_areaneg, rm_r23.r23_codcli)
	RETURNING rm_z03.*
IF rm_z03.z03_credit_dias IS NOT NULL THEN
	LET plazo = rm_z03.z03_credit_dias 
ELSE
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r23.r23_codcli)
		RETURNING rm_z02.*
	LET plazo = rm_z02.z02_credit_dias
END IF
RETURN plazo

END FUNCTION



FUNCTION control_anticipos()
DEFINE i,j,done		SMALLINT 
DEFINE resp		CHAR(6)
DEFINE r_z21		RECORD LIKE cxct021.*

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F40

CALL calcula_total_anticipos(vm_ind_docs)

WHILE TRUE
LET INT_FLAG = 0
CALL set_count(vm_ind_docs)
INPUT ARRAY r_detalle_2 WITHOUT DEFAULTS FROM r_detalle_2.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL dialog.keysetlabel('DELETE', '')
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line() 
	AFTER ROW
		CALL calcula_total_anticipos(vm_ind_docs)
	AFTER FIELD r27_valor
		IF r_detalle_2[i].r27_valor IS NOT NULL THEN
			IF r_detalle_2[i].r27_valor > r_detalle_2[i].z21_saldo
			   THEN
				CALL fgl_winmessage(vg_producto,
						    'El saldo del documento '|| 
						    'es insuficiente',
						    'exclamation')
				NEXT FIELD r27_valor
			END IF
		ELSE
			LET r_detalle_2[i].r27_valor = 0
			DISPLAY r_detalle_2[i].r27_valor TO 
				r_detalle_2[j].r27_valor
		END IF
		CALL calcula_total_anticipos(vm_ind_docs)
	BEFORE INSERT
		EXIT INPUT
	BEFORE DELETE
		EXIT INPUT
	AFTER INPUT 
		CALL calcula_total_anticipos(vm_ind_docs)
		IF total_anticipos > rm_r23.r23_tot_neto THEN
			CALL fgl_winmessage(vg_producto,
				'El total de los pagos anticipados ' ||
				'aplicados es mayor al total de la ' ||
				'factura',
				'exclamation') 
			CONTINUE INPUT
		END IF
		IF total_anticipos = rm_r23.r23_tot_neto THEN
			CALL fgl_winquestion(vg_producto,'El total de los pagos anticipados aplicados es igual al total de la factura, desea realizar la factura al contado', 'No', 'Yes|No','question', 1)
				 RETURNING resp 
			IF resp = 'Yes' THEN
				CALL control_actualizacion_preventa()
					RETURNING done
				IF done = 1 THEN
					EXIT PROGRAM
				END IF
			ELSE
				CONTINUE INPUT
			END IF	
		END IF

		EXIT WHILE
END INPUT
IF int_flag THEN
	LET total_anticipos = 0
	CLOSE WINDOW w_repp210_3
	RETURN
END IF
END WHILE

--CLOSE WINDOW w_repp210_3

END FUNCTION



FUNCTION control_actualizacion_preventa()
DEFINE command_line	VARCHAR(100)
DEFINE i,done 		SMALLINT

WHENEVER ERROR CONTINUE
LET done = 0
BEGIN WORK
	UPDATE rept023 SET r23_cont_cred = 'C'
		WHERE r23_compania  = vg_codcia
		AND   r23_localidad = vg_codloc  
		AND   r23_numprev   = rm_r23.r23_numprev  
WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'La preventa está siendo modificada,
			    no se realizará la actualización.','exclamation')	
	RETURN done
END IF
DELETE FROM rept026 
	WHERE r26_compania  = vg_codcia 
	AND   r26_localidad = vg_codloc
	AND   r26_numprev   = rm_r23.r23_numprev

DELETE FROM rept025 
	WHERE r25_compania  = vg_codcia 
	AND   r25_localidad = vg_codloc
	AND   r25_numprev   = rm_r23.r23_numprev

DELETE FROM rept027 
	WHERE r27_compania  = vg_codcia 
	AND   r27_localidad = vg_codloc
	AND   r27_numprev   = rm_r23.r23_numprev

LET rm_r27.r27_compania  = vg_codcia
LET rm_r27.r27_localidad = vg_codloc
LET rm_r27.r27_numprev   = rm_r23.r23_numprev

FOR i = 1 TO vm_ind_docs
	IF r_detalle_2[i].r27_valor IS NOT NULL AND
	   r_detalle_2[i].r27_valor > 0 
	   THEN
		LET rm_r27.r27_tipo   = r_detalle_2[i].z21_tipo_doc
		LET rm_r27.r27_numero = r_detalle_2[i].z21_num_doc
		LET rm_r27.r27_valor  = r_detalle_2[i].r27_valor
		INSERT INTO rept027 VALUES (rm_r27.*)
	END IF
END FOR 
COMMIT WORK
LET done = 1
CALL fgl_winmessage(vg_producto,'Proceso realizado Ok.','info')
LET command_line = 'fglrun repp210 ' || vg_base || ' '
	    || vg_modulo || ' ' || vg_codcia 
	    || ' ' || vg_codloc 
RUN command_line

RETURN done

END FUNCTION



FUNCTION calcula_total_anticipos(num_elm)
DEFINE num_elm		SMALLINT
DEFINE i 		SMALLINT

LET total_anticipos = 0
FOR i = 1 TO num_elm
	IF r_detalle_2[i].r27_valor IS NOT NULL THEN
		LET total_anticipos = total_anticipos + r_detalle_2[i].r27_valor
	END IF
END FOR

DISPLAY BY NAME total_anticipos

END FUNCTION



FUNCTION control_ingreso_anticipos()
DEFINE intentar		SMALLINT
DEFINE done,i 		SMALLINT
DEFINE resp 		CHAR(3)

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_r27_3 CURSOR FOR
			SELECT * FROM rept027
				WHERE r27_compania  = vg_codcia         
				  AND r27_localidad = vg_codloc          
				  AND r27_numprev   = rm_r23.r23_numprev
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		CALL fgl_winquestion(vg_producto,'Registro está siendo modificado por otro usuario, desea intentarlo nuevamente','No','Yes|No','question',1)
			RETURNING resp
		IF resp = 'No' THEN
			LET intentar =  0
			LET done     =  0
		END IF
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

DELETE FROM rept027 
	WHERE r27_compania  = vg_codcia 
	AND   r27_localidad = vg_codloc
	AND   r27_numprev   = rm_r23.r23_numprev

LET rm_r27.r27_compania  = vg_codcia
LET rm_r27.r27_localidad = vg_codloc
LET rm_r27.r27_numprev   = rm_r23.r23_numprev

FOR i = 1 TO vm_ind_docs
	IF r_detalle_2[i].r27_valor IS NOT NULL AND
	   r_detalle_2[i].r27_valor > 0 
	   THEN
		LET rm_r27.r27_tipo   = r_detalle_2[i].z21_tipo_doc
		LET rm_r27.r27_numero = r_detalle_2[i].z21_num_doc
		LET rm_r27.r27_valor  = r_detalle_2[i].r27_valor
		INSERT INTO rept027 VALUES (rm_r27.*)
	END IF
END FOR 

RETURN done

END FUNCTION



FUNCTION muestra_contadores(i)
DEFINE i 	SMALLINT

DISPLAY '' AT 19,1
DISPLAY i, ' de ', vm_num_detalle AT 19, 12
DISPLAY r_detalle_1[i].r23_nomcli TO nom_cliente

END FUNCTION



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

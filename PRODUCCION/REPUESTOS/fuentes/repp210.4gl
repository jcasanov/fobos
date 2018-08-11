--------------------------------------------------------------------------------
-- Titulo           : repp210.4gl - Forma de Pago Pre-Venta
-- Elaboracion      : 25-oct-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp210 base modulo compania localidad
--			[numprev] [A/R]
-- Ultima Correccion: 03-ago-2017	NPC
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
DEFINE rm_r00			RECORD LIKE rept000.*	
DEFINE rm_r88			RECORD LIKE rept088.*
DEFINE rm_z61			RECORD LIKE cxct061.*
DEFINE dias_entre_pagos		SMALLINT
DEFINE fecha_primer_pago	DATE
DEFINE entro_cre		SMALLINT

	---- DETALLE PRIMERA PRESENTACION  ----
DEFINE r_detalle ARRAY[200] OF RECORD
	num_preventa		LIKE rept023.r23_numprev,
	tit_estado		VARCHAR(11),
	valor_neto		LIKE rept023.r23_tot_neto,
	valor_anticipos		LIKE rept025.r25_valor_ant,
	monto_credito		LIKE rept025.r25_valor_cred
	END RECORD
	---------------------------------------------
	---- ARREGLO PARALELO PARA EL ESTADO y NOMBRE DE CLIENTE----
DEFINE r_detalle_1 ARRAY[200] OF RECORD
	r23_estado 	LIKE rept023.r23_estado,
	r23_codcli	LIKE rept023.r23_codcli,
	r23_nomcli	LIKE rept023.r23_nomcli,
	r23_moneda	LIKE rept023.r23_moneda
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
DEFINE vm_size_arr		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_size_arr3		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_ind_docs 		SMALLINT   -- INDICE DE DOCUMENTOS
DEFINE vm_ind_div 		SMALLINT   -- INDICE DE DIVIDENDOS
DEFINE vm_flag_anticipos	CHAR(1) -- PARA SABER SI TIENE O NO ANTICIPOS
					-- 'S' o 'N'
DEFINE vm_flag_grabar		CHAR(1) -- PARA SABER SI TIENE O NO QUE GRABAR
					-- 'S' o 'N'
DEFINE vg_numprev		LIKE rept023.r23_numprev
DEFINE vm_flag_dividendos	CHAR(1)	-- PARA SABER SI TIENE O NO DIVIDENDOS
					-- 'S' o 'N'


MAIN
	
LET vm_max_rows = 1000
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp210.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

{*
 * 4 argumentos es la llamada normal: base modulo codcia codloc
 * 5 argumentos 
 * 6 argumentos es aprobación de crédito automático desde la proforma
 *}
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_numprev = arg_val(5)
LET vg_proceso = 'repp210'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CREATE TEMP TABLE temp_prev_2(
	num_preventa		INTEGER,
	tit_estado		VARCHAR(11),
	valor_neto		DECIMAL(12,2),
	valor_anticipos		DECIMAL(12,2),
	monto_credito		DECIMAL(12,2),
	r23_estado 		CHAR(1),
	r23_codcli		INTEGER,
	r23_nomcli		CHAR(35),
	r23_moneda		CHAR(2))
CREATE TEMP TABLE tempo_doc 
	(locali		SMALLINT,
	 codcli		INTEGER,
	 nomcli		CHAR(100),
	 localidad	VARCHAR(20,10),
	 por_vencer	DECIMAL(12,2),
	 vencido	DECIMAL(12,2))

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 5 THEN
	CALL control_menu_credito(vg_numprev, 0)
	EXIT PROGRAM
END IF
IF num_args() = 6 THEN
	CALL ejecutar_aprobacion_credito_preventa_automatica()
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
OPEN WINDOW w_repp210 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp210 FROM '../forms/repf210_1'
ELSE
	OPEN FORM f_repp210 FROM '../forms/repf210_1c'
END IF
DISPLAY FORM f_repp210
IF vg_gui = 0 THEN
	LET vm_filas_pant = 15
END IF
CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r23.* TO NULL
INITIALIZE rm_r24.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[2]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 1
LET vm_credito   = 'R'
LET vm_estado    = 'A'
LET vm_estado_2  = 'P'
IF vg_gui = 1 THEN
	--#DISPLAY 'No.'  	        TO tit_col1
	--#DISPLAY 'Estado'  		TO tit_col2
	--#DISPLAY 'Valor Neto'		TO tit_col3
	--#DISPLAY 'Valor Anticipo'   	TO tit_col4
	--#DISPLAY 'Monto Crédito'    	TO tit_col5
END IF
CALL control_display_detalle()

END FUNCTION



FUNCTION ejecutar_aprobacion_credito_preventa_automatica()
DEFINE r_r25		RECORD LIKE rept025.*

CALL retorna_tam_arr()
LET vm_filas_pant  = vm_size_arr
LET vm_num_rows    = 0
LET vm_row_current = 0
INITIALIZE rm_r23.*, rm_r24.*, rm_r88.* TO NULL
DECLARE q_r88 CURSOR FOR
	SELECT * FROM rept088
		WHERE r88_compania    = vg_codcia
		  AND r88_localidad   = vg_codloc
		  AND r88_numprev_nue = vg_numprev
OPEN q_r88
FETCH q_r88 INTO rm_r88.*
CLOSE q_r88
FREE q_r88
CALL fl_lee_cabecera_credito_rep(vg_codcia, vg_codloc, vg_numprev)
	RETURNING r_r25.*
IF r_r25.r25_compania IS NOT NULL THEN
	RETURN
END IF
CALL control_menu_credito(vg_numprev, 0)

END FUNCTION



FUNCTION control_display_botones_anticipos()

--#DISPLAY 'Tip'		TO tit_col1
--#DISPLAY 'No. Doc.'		TO tit_col2
--#DISPLAY 'Mon'		TO tit_col3
--#DISPLAY 'Fec. Emisión'	TO tit_col4
--#DISPLAY 'Saldo Doc.'		TO tit_col5
--#DISPLAY 'Valor a usar'	TO tit_col6

END FUNCTION



FUNCTION control_display_botones_credito()

--#DISPLAY 'Pago'		TO tit_col1
--#DISPLAY 'Fec. Vcto.'		TO tit_col2
--#DISPLAY 'Valor Capital'	TO tit_col3
--#DISPLAY 'Valor Interes'	TO tit_col4
--#DISPLAY 'Valor Total'	TO tit_col5

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE query	CHAR(800)
DEFINE i 	SMALLINT

IF vg_gui = 0 THEN
	LET vm_filas_pant = 15
END IF
CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET query = 'SELECT r23_nomcli, r23_estado, r23_codcli, r23_moneda, ',
		' r23_numprev, r23_tot_neto ',
	        ' FROM rept023 WHERE r23_compania  =  ', vg_codcia,
		' AND r23_localidad =  ', vg_codloc,
		' AND r23_cont_cred = "', vm_credito,'"', 
		' AND r23_estado    = "', vm_estado_2,'"'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET i = 1

DELETE FROM temp_prev_2

FOREACH q_cons INTO r_detalle_1[i].r23_nomcli, r_detalle_1[i].r23_estado, 
		    r_detalle_1[i].r23_codcli, r_detalle_1[i].r23_moneda, 
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
		
	INSERT INTO temp_prev_2 VALUES (r_detalle[i].*, r_detalle_1[i].*)

	LET i = i + 1
        IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1

IF i = 0 THEN
	CALL fl_mostrar_mensaje('No existen preventas a crédito.','info')
	EXIT PROGRAM
END IF

LET vm_num_detalle = i

END FUNCTION



FUNCTION control_display_detalle()
DEFINE j,i,k 		SMALLINT
DEFINE command_line	VARCHAR(100)
DEFINE query		CHAR(600)
DEFINE resp		CHAR(6)

LET k = 1
WHILE TRUE
	CALL control_cargar_detalle()
	LET query = 'SELECT * FROM temp_prev_2 ',
		' ORDER BY ', vm_columna_1, ' ',
		      rm_orden[vm_columna_1], ', ',
		      vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE	 dprev FROM query
	DECLARE q_dprev CURSOR FOR dprev
	LET i = 1
	FOREACH q_dprev INTO r_detalle[i].*, r_detalle_1[i].*
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
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F6)
			LET i = arr_curr()
			LET j = scr_line()
			CALL estado_cuenta(i)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			LET j = scr_line()
			CALL control_menu_credito(r_detalle[i].num_preventa, i)
			LET int_flag = 0
			IF entro_cre = 1 THEN
				--#CONTINUE DISPLAY
			ELSE
				EXIT DISPLAY
			END IF
		ON KEY(F8)
			LET i = arr_curr()
			LET j = scr_line()
			CALL control_ver_preventa(r_detalle[i].num_preventa)
			LET int_flag = 0
       	--#BEFORE DISPLAY
       	    --#CALL dialog.keysetlabel('ACCEPT', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL muestra_contadores(i)
        --#AFTER DISPLAY
            --#CONTINUE DISPLAY
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



FUNCTION control_forma_pago(numprev, flag)
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE flag			SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE fecha_1er_pago	DATE
DEFINE num_dias		INTEGER
DEFINE d_pagos		INTEGER

LET vm_flag_grabar      = 'N'
LET vm_flag_anticipos   = 'N'
LET vm_flag_dividendos  = 'N'
LET total_anticipos     = 0
LET total_anticipos_aux = 0

CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, numprev) RETURNING rm_r23.*
CALL fl_lee_grupo_linea(vg_codcia, rm_r23.r23_grupo_linea) RETURNING rm_g20.*

LET vm_areaneg = rm_g20.g20_areaneg

INITIALIZE rm_r25.*, fecha_primer_pago TO NULL
LET d_pagos           = rm_z61.z61_dia_entre_pago
LET fecha_primer_pago = vg_fecha + d_pagos

IF num_args() = 6 AND arg_val(6) = 'R' THEN
	CALL fl_lee_cabecera_transaccion_rep(rm_r88.r88_compania,
				rm_r88.r88_localidad, rm_r88.r88_cod_fact,
				rm_r88.r88_num_fact)
		RETURNING r_r19.*
	LET num_dias          = 7
	IF r_r19.r19_cont_cred = 'C' THEN
		LET d_pagos   = 1
		LET num_dias  = 1
	END IF
	LET fecha_primer_pago = vg_fecha + num_dias UNITS DAY
END IF

CALL fl_lee_cabecera_credito_rep(vg_codcia, vg_codloc, rm_r23.r23_numprev) 
	RETURNING rm_r25.*
IF rm_r25.r25_numprev IS NULL THEN
	LET fecha_primer_pago     = vg_fecha + d_pagos
	IF num_args() = 6 AND arg_val(6) = 'R' THEN
		LET fecha_primer_pago = vg_fecha + num_dias UNITS DAY
	END IF
	IF arg_val(6) = 'A' THEN
		CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r23.r23_codcli)
			RETURNING r_z02.*
		LET fecha_primer_pago = vg_fecha + r_z02.z02_dia_entre_pago UNITS DAY
	END IF
	LET rm_r25.r25_interes    = rm_z61.z61_intereses
	LET dias_entre_pagos      = d_pagos
	IF num_args() = 6 AND arg_val(6) = 'R' THEN
		LET dias_entre_pagos = num_dias
	END IF
	IF r_z02.z02_dia_entre_pago IS NOT NULL THEN
		LET dias_entre_pagos = r_z02.z02_dia_entre_pago
	END IF
	LET rm_r25.r25_plazo      = calcula_plazo()
	LET rm_r25.r25_numprev    = rm_r23.r23_numprev
	LET rm_r25.r25_valor_cred = rm_r23.r23_tot_neto
	LET rm_r25.r25_valor_ant  = 0
	LET rm_r25.r25_dividendos = rm_z61.z61_num_pagos
	IF r_z02.z02_num_pagos IS NOT NULL THEN
		LET rm_r25.r25_dividendos = r_z02.z02_num_pagos
	END IF
	IF r_r19.r19_cont_cred = 'R' AND num_args() = 6 AND arg_val(6) = 'R' THEN
		SELECT NVL(MAX(z20_dividendo), 1) INTO rm_r25.r25_dividendos
			FROM cxct020
			WHERE z20_compania  = r_r19.r19_compania
			  AND z20_localidad = r_r19.r19_localidad
			  AND z20_codcli    = r_r19.r19_codcli
			  AND z20_tipo_doc  = r_r19.r19_cod_tran
			  AND z20_cod_tran  = r_r19.r19_cod_tran
			  AND z20_num_tran  = r_r19.r19_num_tran
	END IF
	LET vm_flag_dividendos    = 'S'
	IF num_args() = 6 AND arg_val(6) = 'R' THEN
		LET rm_r25.r25_plazo = rm_r25.r25_dividendos * dias_entre_pagos
	END IF
ELSE
	LET fecha_1er_pago = vg_fecha + d_pagos
	IF num_args() = 6 THEN
		LET fecha_1er_pago = vg_fecha + num_dias UNITS DAY
	END IF
	IF rm_r25.r25_valor_cred + rm_r25.r25_valor_ant <> rm_r23.r23_tot_neto
	THEN
		LET fecha_primer_pago     = fecha_1er_pago
		IF arg_val(6) = 'A' THEN
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
											rm_r23.r23_codcli)
				RETURNING r_z02.*
			LET fecha_primer_pago = vg_fecha +
									r_z02.z02_dia_entre_pago UNITS DAY
		END IF
		LET rm_r25.r25_interes    = 0
		LET rm_r25.r25_interes    = 0
		LET rm_r25.r25_numprev    = rm_r23.r23_numprev
		LET rm_r25.r25_valor_cred = rm_r23.r23_tot_neto
		LET rm_r25.r25_valor_ant  = 0
	END IF
	LET dias_entre_pagos = rm_r25.r25_plazo

	CALL control_cargar_dividendos(rm_r23.r23_numprev)

END IF
	
IF rm_r25.r25_valor_ant IS NULL THEN
	LET rm_r25.r25_valor_ant = 0
END IF

CALL fl_lee_moneda(rm_r23.r23_moneda) 	-- PARA OBTENER EL NOMBRE DE LA MONEDA 
	RETURNING rm_g13.*		   	    

IF num_args() = 6 AND flag THEN
	RETURN
END IF

DISPLAY BY NAME rm_r23.r23_moneda, fecha_primer_pago, rm_r25.r25_plazo,
		dias_entre_pagos,  rm_r25.r25_interes, rm_r25.r25_valor_ant,
		rm_r25.r25_valor_cred, rm_r25.r25_numprev, rm_r23.r23_codcli,
		rm_r23.r23_nomcli, rm_r25.r25_dividendos
DISPLAY rm_g13.g13_nombre TO nom_moneda
IF num_args() = 6 AND arg_val(6) = 'A' THEN
	CALL control_cargar_detalle_credito()
	DISPLAY BY NAME vm_tot_cap, vm_tot_interes, vm_total
END IF

END FUNCTION



FUNCTION control_menu_credito(numprev, i)
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE i, done 		SMALLINT
DEFINE bloqueada	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE mensaje		VARCHAR(100)
DEFINE nprev		VARCHAR(10)
DEFINE flag_error	SMALLINT
DEFINE r_z02		RECORD LIKE cxct002.*

LET entro_cre = 0
CALL fl_lee_configuracion_credito_cxc(vg_codcia, vg_codloc) RETURNING rm_z61.*
CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r23.r23_codcli)
	RETURNING r_z02.*
IF r_z02.z02_credit_auto = 'N' THEN
	CALL fl_mostrar_mensaje('El cliente no esta configurado para autorizar crédito en la preventa.', 'exclamation')
	RETURN
END IF
IF r_z02.z02_num_pagos IS NOT NULL THEN
	LET rm_z61.z61_num_pagos = r_z02.z02_num_pagos
END IF
IF r_z02.z02_dia_entre_pago IS NOT NULL THEN
	LET rm_z61.z61_dia_entre_pago = r_z02.z02_dia_entre_pago
END IF
IF r_z02.z02_max_entre_pago IS NOT NULL THEN
	LET rm_z61.z61_max_entre_pago = r_z02.z02_max_entre_pago
END IF
CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, numprev) RETURNING rm_r23.*
IF num_args() = 4 AND rm_r23.r23_estado <> 'P' THEN
	CALL fl_mostrar_mensaje('La preventa no tiene estado de aprobada.','exclamation')
	RETURN
END IF 
LET bloqueada = control_bloquear_preventa(numprev)
IF bloqueada = 'S' THEN
	LET nprev   = numprev
	LET mensaje = 'La preventa ', nprev CLIPPED,
			' está bloqueada por otro proceso.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN
END IF 
IF rm_r23.r23_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('La preventa no tiene código de cliente. Por favor corrija la proforma y vuelva a convertir en preventa.','exclamation')
	RETURN
END IF	
IF NOT valida_cliente_consumidor_final(rm_r23.r23_codcli) THEN
	RETURN
END IF	
CALL control_saldos_vencidos(vg_codcia, rm_r23.r23_codcli, 0)
	RETURNING flag_error
IF flag_error AND num_args() = 5 THEN
	RETURN
END IF
IF i > 0 THEN
	IF NOT tiene_cupo_credito(numprev, i) THEN
		LET entro_cre = 1
		RETURN
	END IF
END IF
IF num_args() = 6 THEN
	CALL generacion_credito(numprev)
	IF arg_val(6) = 'R' THEN
		RETURN
	END IF
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
OPEN WINDOW w_210_3 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_210_3 FROM '../forms/repf210_3'
ELSE
	OPEN FORM f_210_3 FROM '../forms/repf210_3c'
END IF
DISPLAY FORM f_210_3
CLEAR FORM
CALL control_display_botones_credito()

CALL control_forma_pago(numprev, 0)
MENU 'OPCIONES'
	BEFORE MENU
		IF num_args() <> 4 THEN
			HIDE OPTION 'Crédito'
			HIDE OPTION 'Grabar'
		END IF
	COMMAND KEY('V') 'Ver Preventa' 	'Ver toda la Preventa.'	
		CALL control_ver_preventa(rm_r23.r23_numprev)
	COMMAND KEY('A') 'Doc. a Favor'	       'Documentos a favor del Cliente.'
		CALL control_anticipos_cliente()
	COMMAND KEY('R') 'Crédito'		'Condiciones de Crédito.'
		CALL control_credito()
	COMMAND KEY('G') 'Grabar'		'Grabar el Crédito. '
		CALL control_grabar() RETURNING done
		IF done = 1 THEN
			EXIT MENU
		END IF
	COMMAND KEY('D') 'Detalle'		'Se ubica en el detalle.'
		CALL control_display_detalle_credito()
	COMMAND KEY('S') 'Salir' 		'Salir Menu.'
		IF arg_val(6) = 'A' THEN
			EXIT MENU
		END IF
		IF rm_r23.r23_estado = 'P' THEN
			LET resp = control_salir()
			IF resp = 'Yes' THEN
				EXIT MENU
			END IF
		ELSE
			EXIT MENU
		END IF
END MENU

CLOSE WINDOW w_210_3
IF num_args() = 5 THEN
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION generacion_credito(numprev)
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE done		SMALLINT

CALL control_forma_pago(numprev, 1)
CALL control_credito()
CALL control_grabar() RETURNING done
IF NOT done THEN
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION control_salir()
DEFINE resp		CHAR(6)

CALL fl_mensaje_abandonar_proceso() RETURNING resp
RETURN resp

END FUNCTION


FUNCTION control_bloquear_preventa(numprev)
DEFINE numprev 		LIKE rept023.r23_numprev
DEFINE bloqueada	CHAR(1) 	-- S BLOQUEADA
					-- N NO BLOQUEADA
LET bloqueada = 'N'
BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_read_r23 CURSOR FOR 
		SELECT * FROM rept023 
			WHERE r23_compania  = vg_codcia
			AND   r23_localidad = vg_codloc 
			AND   r23_numprev   = numprev
		FOR UPDATE
	OPEN q_read_r23
	FETCH q_read_r23
	IF STATUS < 0 THEN
		LET bloqueada = 'S'
	END IF
COMMIT WORK
WHENEVER ERROR STOP
RETURN bloqueada

END FUNCTION 



FUNCTION control_grabar()
DEFINE i,done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE mensaje		VARCHAR(100)

LET done = 0
IF vm_flag_grabar = 'N' THEN
	CALL fl_mostrar_mensaje('Aun no ha actualizado el crédito. ','exclamation')
	RETURN done
END IF
CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, rm_r23.r23_numprev)
	RETURNING r_r23.*
CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, r_r23.r23_codcli)
	RETURNING r_z02.*
IF r_z02.z02_credit_auto = 'N' THEN
	CALL fl_mostrar_mensaje('El cliente no esta configurado para autorizar crédito en la preventa.', 'exclamation')
	RETURN done
END IF
IF r_r23.r23_compania IS NULL OR r_r23.r23_estado = 'F' OR 
   r_r23.r23_cod_tran IS NOT NULL THEN
	LET mensaje = 'Lo siento, La Preventa ', rm_r23.r23_numprev USING "#######&", ' ya ha sido facturada.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
BEGIN WORK
	LET rm_r23.r23_cont_cred = 'R'
	WHENEVER ERROR CONTINUE
	UPDATE rept023 SET r23_cont_cred = 'R'
		WHERE r23_compania  = vg_codcia
		AND   r23_localidad = vg_codloc  
		AND   r23_numprev   = rm_r23.r23_numprev  
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	
	DELETE FROM rept025
		WHERE r25_compania  = vg_codcia
		AND   r25_localidad = vg_codloc
		AND   r25_numprev   = rm_r23.r23_numprev

	LET rm_r25.r25_compania  = vg_codcia
	LET rm_r25.r25_localidad = vg_codloc
	LET rm_r25.r25_numprev   = rm_r23.r23_numprev

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

	WHENEVER ERROR STOP
	IF vm_flag_anticipos = 'S' AND num_args() <> 6 THEN
		CALL control_ingreso_anticipos()
			RETURNING done
		IF done = 0 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No realizo la transacción. ','exclamation')
			RETURN
		END IF
	END IF

	CALL control_actualizacion_caja()
		RETURNING done
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Ha ocurrido un error en la actualización de la caja.','exclamation')
		RETURN
	END IF 

IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo realizar la transacción a ocurrido un error. ','exclamation')
	RETURN
END IF
COMMIT WORK
LET done = 1
IF num_args() <> 6 THEN
	CALL fl_mostrar_mensaje('Proceso realizado Ok. ','info')
ELSE
	LET mensaje = 'Aprobación de Crédito en Pre-Venta ',
			rm_r23.r23_numprev USING "<<<<<<&", ' Generada Ok.'
	CALL fl_mostrar_mensaje(mensaje, 'info')
END IF
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
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_j10
		FREE  q_j10
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF

IF STATUS <> NOTFOUND THEN
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

LET r_j10.j10_fecha_pro   = fl_current()
LET r_j10.j10_usuario     = vg_usuario 
LET r_j10.j10_fecing      = fl_current()
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
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente','No')
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
IF num_args() <> 6 THEN
	CALL control_ingreso_credito()
ELSE
	LET int_flag = 0
END IF
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
		IF num_args() <> 6 THEN
			CALL control_ingreso_detalle_credito()
		END IF
		LET vm_flag_grabar = 'S'
	ELSE
		IF r_r25.r25_dividendos <> rm_r25.r25_dividendos OR
		   r_r25.r25_interes    <> rm_r25.r25_interes    OR
		   fecha_aux            <> fecha_primer_pago     OR
		   dias	                <> dias_entre_pagos
		   THEN
			CALL control_cargar_detalle_credito()
		END IF
		IF num_args() <> 6 THEN
			CALL control_display_detalle_credito()
		END IF
		LET vm_flag_grabar = 'S'
	END IF
--#ELSE
	--#RETURN
END IF

END FUNCTION



FUNCTION control_cargar_dividendos(numprev)
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE i 		SMALLINT

DECLARE q_read_r26 CURSOR FOR
	SELECT * FROM rept026
		WHERE r26_compania  = vg_codcia
		  AND r26_localidad = vg_codloc
		  AND r26_numprev   = numprev

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
		IF i > 200 THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i > 1 THEN
		LET dias_entre_pagos = r_detalle_3[2].r26_fec_vcto -
				       r_detalle_3[1].r26_fec_vcto	 
	END IF

	LET vm_ind_div = i
	IF vg_gui = 0 THEN
		LET vm_filas_pant = 8
	END IF
	CALL retorna_tam_arr3()
	LET vm_filas_pant = vm_size_arr3
	IF vm_ind_div < vm_filas_pant THEN
		LET vm_filas_pant = vm_ind_div
	END IF 
	IF num_args() <> 6 THEN
		FOR i = 1 TO vm_filas_pant
			DISPLAY r_detalle_3[i].* TO r_detalle_3[i].*
		END FOR
	END IF
	CALL calcula_interes()
END IF

END FUNCTION



FUNCTION control_cargar_detalle_credito()
DEFINE i 		SMALLINT
DEFINE fecha		DATE
DEFINE query		CHAR(300)
DEFINE saldo    	LIKE rept025.r25_valor_cred
DEFINE val_div  	LIKE rept026.r26_valor_cap

LET saldo   = rm_r25.r25_valor_cred
LET val_div = rm_r25.r25_valor_cred / rm_r25.r25_dividendos

FOR i = 1 TO rm_r25.r25_dividendos
	LET r_detalle_3[i].r26_dividendo = i
	IF num_args() <> 6 THEN
		IF i = 1 THEN
			LET r_detalle_3[i].r26_fec_vcto = fecha_primer_pago
		ELSE
			LET r_detalle_3[i].r26_fec_vcto = 
			    r_detalle_3[i-1].r26_fec_vcto + dias_entre_pagos
		END IF
	ELSE
		IF arg_val(6) = 'R' THEN
			LET query = 'SELECT r26_fec_vcto ',
					' FROM rept026 ',
					' WHERE r26_compania  = ', rm_r88.r88_compania,
					'   AND r26_localidad = ', rm_r88.r88_localidad,
					'   AND r26_numprev   = ', rm_r88.r88_numprev,
					'   AND r26_dividendo = ', i
		END IF
		IF arg_val(6) = 'A' THEN
			LET query = 'SELECT r26_fec_vcto ',
					' FROM rept026 ',
					' WHERE r26_compania  = ', vg_codcia,
					'   AND r26_localidad = ', vg_codloc,
					'   AND r26_numprev   = ', vg_numprev,
					'   AND r26_dividendo = ', i
		END IF
		PREPARE cons_r26_ant FROM query
		DECLARE q_r26_ant CURSOR FOR cons_r26_ant
		OPEN q_r26_ant
		FETCH q_r26_ant INTO fecha
		IF STATUS = NOTFOUND THEN
			IF i = 1 THEN
				LET r_detalle_3[i].r26_fec_vcto = fecha_primer_pago
			ELSE
				LET r_detalle_3[i].r26_fec_vcto =
						r_detalle_3[i - 1].r26_fec_vcto + dias_entre_pagos
			END IF
		ELSE
			IF fecha > vg_fecha THEN
				LET r_detalle_3[i].r26_fec_vcto = fecha
			ELSE
				LET r_detalle_3[i].r26_fec_vcto = vg_fecha +
								1 UNITS DAY
			END IF
		END IF
		CLOSE q_r26_ant
		FREE q_r26_ant
	END IF
	IF i <> rm_r25.r25_dividendos THEN
		LET r_detalle_3[i].r26_valor_cap = val_div
		LET saldo = saldo - val_div
	ELSE
		LET r_detalle_3[i].r26_valor_cap = saldo
	END IF
END FOR 
CALL calcula_interes()
IF vg_gui = 0 THEN
	LET vm_filas_pant = 8
END IF
CALL retorna_tam_arr3()
LET vm_filas_pant = vm_size_arr3
IF rm_r25.r25_dividendos < vm_filas_pant THEN
	LET vm_filas_pant = rm_r25.r25_dividendos
END IF 
IF num_args() = 6 AND arg_val(6) = 'R' THEN
	RETURN
END IF
FOR i = 1 TO vm_filas_pant
	DISPLAY r_detalle_3[i].* TO r_detalle_3[i].*
END FOR

END FUNCTION



FUNCTION control_display_detalle_credito()

CALL set_count(rm_r25.r25_dividendos)
DISPLAY ARRAY r_detalle_3 TO r_detalle_3.* 
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT','')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_ingreso_detalle_credito()
DEFINE resp 		CHAR(6)
DEFINE i,j,k, tt	SMALLINT
DEFINE fecha_aux 	LIKE rept026.r26_fec_vcto
DEFINE r_det_aux	ARRAY[200] OF RECORD
	r26_dividendo	LIKE rept026.r26_dividendo,
	r26_fec_vcto	LIKE rept026.r26_fec_vcto,
	r26_valor_cap	LIKE rept026.r26_valor_cap,
	r26_valor_int	LIKE rept026.r26_valor_int,
	total 		LIKE rept026.r26_valor_cap
	END RECORD
DEFINE desinput		SMALLINT
DEFINE mensaje		VARCHAR(150)
DEFINE fecha		DATE

FOR k = 1 TO rm_r25.r25_dividendos
	LET r_det_aux[k].*	= r_detalle_3[k].*
END FOR

OPTIONS
	INSERT KEY F30,
	DELETE KEY F40
LET desinput = 0
WHILE TRUE
	CALL set_count(rm_r25.r25_dividendos) 
	LET int_flag = 0
	INPUT ARRAY r_detalle_3 WITHOUT DEFAULTS FROM r_detalle_3.*
		BEFORE INPUT 
			--#CALL dialog.keysetlabel ('INSERT','')
			--#CALL dialog.keysetlabel ('DELETE','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
			IF resp = 'Yes' THEN
				FOR k = 1 TO rm_r25.r25_dividendos
					LET r_detalle_3[k].* = r_det_aux[k].*
				END FOR
				IF vg_gui = 0 THEN
					LET vm_filas_pant = 8
				END IF
				CALL retorna_tam_arr3()
				LET vm_filas_pant = vm_size_arr3
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
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
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
			LET fecha = fecha_primer_pago + rm_r25.r25_plazo
			IF r_detalle_3[i].r26_fec_vcto > fecha AND i = 1 THEN
				LET mensaje = 'La fecha ingresada debe ser ',
						'menor o igual a la fecha ',
						'dentro de ',
						dias_entre_pagos USING "<<<&",
						' días.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
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
					CALL fl_mostrar_mensaje('Existen fechas que resultan menores a las ingresadas anteriormente en los pagos. ','exclamation')
					EXIT INPUT
				END IF
			END FOR	
			IF vm_total > rm_r25.r25_valor_cred THEN
				CALL fl_mostrar_mensaje('El total del valor capital es mayor al total de la deuda. ','exclamation')
				EXIT INPUT
			END IF
			IF vm_total < rm_r25.r25_valor_cred THEN
				CALL fl_mostrar_mensaje('El total del valor capital es menor al total de la deuda. ','exclamation')
				EXIT INPUT
			END IF

-- Para evitar que se grabe una fecha de vencimiento < a today (1822)
			FOR i = 1 TO rm_r25.r25_dividendos
				IF r_detalle_3[i].r26_fec_vcto < vg_fecha THEN
					CALL fl_mostrar_mensaje('La fecha de vencimiento no puede ser menor a la fecha de hoy.','exclamation')
					CONTINUE INPUT
				END IF
			END FOR
			LET tt = rm_r25.r25_dividendos
			LET rm_r25.r25_plazo = 
			    r_detalle_3[tt].r26_fec_vcto - vg_fecha 	
			DISPLAY BY NAME rm_r25.r25_plazo

			--#EXIT WHILE
			LET desinput = 1
	END INPUT
	IF vg_gui = 0 THEN
		IF desinput = 1 THEN
			EXIT WHILE
		END IF
	END IF
IF int_flag THEN
	--#RETURN
	EXIT WHILE
END IF
END WHILE	

END FUNCTION



FUNCTION calcula_interes()
DEFINE valor_cred	LIKE rept025.r25_valor_cred
DEFINE i 			SMALLINT

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
IF num_args() <> 6 THEN
	DISPLAY BY NAME vm_tot_cap, vm_tot_interes, vm_total
END IF

END FUNCTION



FUNCTION control_anticipos_cliente()
DEFINE i		SMALLINT 
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_r27		RECORD LIKE rept027.*

OPEN WINDOW w_repp210_3 AT 8, 11 WITH 14 ROWS, 68 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, 
		  MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp210_3 FROM '../forms/repf210_2'
ELSE
	OPEN FORM f_repp210_3 FROM '../forms/repf210_2c'
END IF
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
		CALL fl_mostrar_mensaje('No hay documentos a favor para este cliente.','exclamation')
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
DEFINE run_prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET command_line = run_prog || 'repp209 ' || vg_base || ' '
	    || vg_modulo || ' ' || vg_codcia 
	    || ' ' || vg_codloc || ' ' ||
	    numprev
RUN command_line

END FUNCTION



FUNCTION control_ingreso_credito()
DEFINE resp 	   	CHAR(6)
DEFINE fecha		DATE
DEFINE mensaje		VARCHAR(150)
DEFINE r_z00		RECORD LIKE cxct000.*
DEFINE r_z02		RECORD LIKE cxct002.*

IF fecha_primer_pago IS NULL THEN
	LET fecha_primer_pago = vg_fecha + dias_entre_pagos
END IF
LET int_flag = 0
INPUT BY NAME rm_r25.r25_numprev, rm_r23.r23_codcli, rm_r23.r23_nomcli,
	      rm_r25.r25_dividendos, rm_r25.r25_plazo, fecha_primer_pago,
		dias_entre_pagos, rm_r25.r25_valor_cred, rm_r25.r25_valor_ant
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(r23_codcli,  r23_nomcli, r25_dividendos,
				     dias_entre_pagos)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
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
			IF fecha_primer_pago < vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha ingresada debe ser mayor o igual a la de hoy. ','exclamation')
				NEXT FIELD fecha_primer_pago
			END IF
			LET fecha = vg_fecha + rm_r25.r25_plazo
			IF fecha_primer_pago > fecha THEN
				LET mensaje = 'La fecha ingresada debe ser ',
						'menor o igual a la fecha ',
						'dentro de ',
						dias_entre_pagos USING "<<<&",
						' días.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			END IF
		END IF
	AFTER INPUT
		CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_z00.* 
		IF r_z00.z00_bloq_vencido = 'S' THEN
				CALL fl_lee_cliente_localidad(vg_codcia,
							vg_codloc,
							rm_r23.r23_codcli)
					RETURNING r_z02.*
				IF rm_r25.r25_plazo > r_z02.z02_dia_entre_pago THEN
					CALL fl_mostrar_mensaje('El plazo de crédito no puede ser mayor al límite de días crédito del cliente.', 'exclamation')
					NEXT FIELD r25_plazo
				END IF
		END IF
		IF rm_r25.r25_dividendos > rm_z61.z61_max_pagos THEN
			CALL fl_mostrar_mensaje('El número de pagos no puede ser mayor al maximo de pagos.', 'exclamation')
			NEXT FIELD r25_dividendos
		END IF
		IF dias_entre_pagos > rm_z61.z61_max_entre_pago THEN
			CALL fl_mostrar_mensaje('Los días entre pagos no puede ser mayor al maximo de días para los pagos.', 'exclamation')
			NEXT FIELD dias_entre_pagos
		END IF
		IF rm_r25.r25_interes > rm_z61.z61_intereses THEN
			CALL fl_mostrar_mensaje('El porcentaje de interés no puede ser mayor al maximo porcentaje de interés.', 'exclamation')
			NEXT FIELD r25_interes
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
	LET plazo = rm_z02.z02_dia_entre_pago
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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT', '')
		--#CALL dialog.keysetlabel('DELETE', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line() 
	AFTER ROW
		CALL calcula_total_anticipos(vm_ind_docs)
	AFTER FIELD r27_valor
		IF r_detalle_2[i].r27_valor IS NOT NULL THEN
			IF r_detalle_2[i].r27_valor > r_detalle_2[i].z21_saldo
			   THEN
				CALL fl_mostrar_mensaje('El saldo del documento es insuficiente.','exclamation')
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
			CALL fl_mostrar_mensaje('El total de los pagos anticipados aplicados es mayor al total de la factura.','exclamation') 
			CONTINUE INPUT
		END IF
		IF total_anticipos = rm_r23.r23_tot_neto THEN
			CALL fl_hacer_pregunta('El total de los pagos anticipados aplicados es igual al total de la factura, desea realizar la factura al contado','No')
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

END FUNCTION



FUNCTION control_actualizacion_preventa()
DEFINE command_line	VARCHAR(100)
DEFINE i,done 		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE mensaje		VARCHAR(100)

LET done = 0
CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, rm_r23.r23_numprev)
	RETURNING r_r23.*
IF r_r23.r23_compania IS NULL OR r_r23.r23_estado = 'F' OR 
   r_r23.r23_cod_tran IS NOT NULL THEN
	LET mensaje = 'Lo siento, La Preventa ', rm_r23.r23_numprev USING "#######&", ' ya ha sido facturada.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
	UPDATE rept023 SET r23_cont_cred = 'C'
		WHERE r23_compania  = vg_codcia
		AND   r23_localidad = vg_codloc  
		AND   r23_numprev   = rm_r23.r23_numprev  
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('La preventa está siendo modificada, no se realizará la actualización.','exclamation')
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
CALL fl_mostrar_mensaje('Proceso realizado Ok.','info')
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET command_line = run_prog || 'repp210 ' || vg_base || ' '
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
		CALL fl_hacer_pregunta('Registro está siendo modificado por otro usuario, desea intentarlo nuevamente','No')
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

IF vg_gui = 1 THEN
	DISPLAY '' AT 19,1
	DISPLAY i, ' de ', vm_num_detalle AT 19, 12
END IF
DISPLAY r_detalle_1[i].r23_nomcli TO nom_cliente

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 14
END IF

END FUNCTION



FUNCTION retorna_tam_arr3()

--#LET vm_size_arr3 = fgl_scr_size('r_detalle_3')
IF vg_gui = 0 THEN
	LET vm_size_arr3 = 8
END IF

END FUNCTION

                                                                                
                                                                                
FUNCTION estado_cuenta(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)
DEFINE fecha		DATE

IF r_detalle_1[i].r23_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('Esta Pre-Venta no tiene codigo del cliente.','excalamtion')
	RETURN
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
IF vg_gui = 0 THEN
	CALL fl_mostrar_mensaje('Este programa no esta para este tipo de terminales.', 'exclamation')
	RETURN
END IF
LET fecha   = vg_fecha
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, '; fglrun cxcp314 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		r_detalle_1[i].r23_moneda, ' ', fecha, ' "T" 0.01 "N" 0 ',
		r_detalle_1[i].r23_codcli
RUN comando

END FUNCTION



FUNCTION valida_cliente_consumidor_final(codcli)
DEFINE codcli		LIKE cxct021.z21_codcli
DEFINE mensaje		VARCHAR(200)

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*		   
LET mensaje = 'El código de cliente: ', rm_r00.r00_codcli_tal USING '#####&',
	' solo puede ser usado para ventas contado menores o ',
	'iguales a: ',                                        
        rm_r00.r00_valmin_ccli USING '##,##&.##'              
IF codcli = rm_r00.r00_codcli_tal THEN 
	CALL fl_mostrar_mensaje(mensaje,'exclamation')          
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_saldos_vencidos(codcia, codcli, flag_mens)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		DECIMAL(14,2)
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z00		RECORD LIKE cxct000.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE mensaje		VARCHAR(180)
DEFINE flag_error 	SMALLINT
DEFINE flag_mens 	SMALLINT
DEFINE icono		CHAR(20)
DEFINE mens		CHAR(20)

LET icono = 'exclamation'
LET mens  = 'Lo siento, esta'
IF flag_mens THEN
	LET icono = 'info'
	LET mens  = 'Esta'
END IF
CALL fl_retorna_saldo_vencido(codcia, codcli) RETURNING moneda, valor
LET flag_error = 0
IF valor > 0 THEN
	CALL fl_lee_moneda(moneda) RETURNING r_g13.*
	LET mensaje = 'El cliente tiene un saldo vencido ' ||
		      'de  ' || valor || 
		      '  en la moneda ' ||
                      r_g13.g13_nombre ||
		      '.'
	CALL fl_mostrar_mensaje(mensaje, icono)
	CALL fl_lee_compania_cobranzas(codcia) RETURNING r_z00.* 
	IF r_z00.z00_bloq_vencido = 'S' THEN
		CALL fl_mostrar_mensaje(mens CLIPPED || ' activo el bloqueo de proformar y facturar a clientes con saldos vencidos. El cliente debera cancelar sus deudas.',icono)
		LET flag_error = 1
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							codcli)
				RETURNING r_z02.*
			IF r_z02.z02_credit_dias > 0 THEN
				LET flag_error = 0
			END IF
	END IF
END IF
RETURN flag_error

END FUNCTION



FUNCTION tiene_cupo_credito(numprev, i)
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE i		SMALLINT
DEFINE r_cli		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				locali		LIKE gent002.g02_localidad,
				tot_pven 	DECIMAL(12,2),
				tot_venc 	DECIMAL(12,2),
				tot_saldo 	DECIMAL(12,2)
			END RECORD
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE mensaje		CHAR(500)
DEFINE resul		SMALLINT
DEFINE cred_aprob	DECIMAL(12,2)
DEFINE valor_cred	DECIMAL(12,2)
DEFINE query		CHAR(800)

CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r23.r23_codcli)
	RETURNING r_z02.*
IF r_z02.z02_credit_dias < 1 THEN
	CALL fl_mostrar_mensaje('No se puede procesar este crédito porque el cliente no tiene días de crédito.', 'exclamation')
	RETURN 0
END IF
IF NOT genera_tabla_trabajo_detalle() THEN
	DELETE FROM tempo_doc
	DROP TABLE tmp_mov
	RETURN 1
END IF
IF NOT genera_tabla_trabajo_resumen() THEN
	DELETE FROM tempo_doc
	DROP TABLE tmp_mov
	RETURN 1
END IF
CALL muestra_resumen_clientes() RETURNING resul, r_cli.*
DELETE FROM tempo_doc
DROP TABLE tmp_mov
IF resul THEN
	RETURN 1
END IF
CALL fl_lee_cliente_localidad(vg_codcia, r_cli.locali, r_cli.codcli)
	RETURNING r_z02.*
LET query = 'SELECT NVL(SUM(r25_valor_cred), 0) val_c ',
		'FROM rept023, rept025 ',
		'WHERE r23_compania   = ', vg_codcia,
		'  AND r23_localidad  = ', vg_codloc,
		'  AND r23_numprev   <> ', numprev,
		'  AND r23_codcli     = ', r_cli.codcli,
		'  AND r23_estado     = "P" ',
		'  AND r23_cod_tran  IS NULL ',
		'  AND r25_compania   = r23_compania ',
		'  AND r25_localidad  = r23_localidad ',
		'  AND r25_numprev    = r23_numprev ',
		'  AND r25_cod_tran  IS NULL ',
		'UNION ',
		'SELECT NVL(SUM(t25_valor_cred), 0) val_c ',
		'FROM talt023, talt025 ',
		'WHERE t23_compania     = ', vg_codcia,
		'  AND t23_localidad    = ', vg_codloc,
		'  AND t23_cod_cliente  = ', r_cli.codcli,
		'  AND t23_estado      IN ("A", "C") ',
		'  AND t25_compania     = t23_compania ',
		'  AND t25_localidad    = t23_localidad ',
		'  AND t25_orden        = t23_orden ',
		'INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
LET cred_aprob = 0
SELECT NVL(SUM(val_c), 0) INTO cred_aprob FROM t1
DROP TABLE t1
LET valor_cred = (r_z02.z02_cupcred_aprob - r_cli.tot_saldo) -
			(cred_aprob + r_detalle[i].valor_neto)
IF (cred_aprob + r_detalle[i].valor_neto) >
   (r_z02.z02_cupcred_aprob - r_cli.tot_saldo)
THEN
	LET mensaje = 'El cliente tiene SALDO DEUDOR de:           ',
		r_cli.tot_saldo USING "#,###,##&.&&",
		'\n\nEl CREDITO que se solicita es de:               ',
		r_detalle[i].valor_neto USING "#,###,##&.&&"
	IF cred_aprob > 0 THEN
		LET mensaje = mensaje CLIPPED,
			'\n\nTiene créditos ya aprobados de:                ',
			cred_aprob USING "#,###,##&.&&"
	END IF
	LET mensaje = mensaje CLIPPED,
		'\n\nEl monto total de su DEUDA sería de:        ',
		(r_cli.tot_saldo + r_detalle[i].valor_neto + cred_aprob)
		USING "#,###,##&.&&",
		'\n\nEl cliente tiene un CUPO DE CREDITO de: ',
		r_z02.z02_cupcred_aprob USING "#,###,##&.&&",
		'\n\ny el crédito solicitado excede el CUPO en:  ',
		valor_cred USING "#,###,##&.&&"
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	CALL fl_mostrar_mensaje('NO SE PUEDE PROCESAR ESTE CREDITO.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION genera_tabla_trabajo_detalle()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(4500)
DEFINE subquery1	CHAR(1500)
DEFINE subquery2	CHAR(500)
DEFINE bas_loc		VARCHAR(20)
DEFINE num_doc		INTEGER

ERROR "Procesando documentos con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
LET bas_loc = NULL
IF vg_codloc = 4 OR vg_codloc = 2 THEN
	IF vg_codloc = 2 THEN
		LET bas_loc = 'acero_gm@idsgye01:'
	END IF
	IF vg_codloc = 4 THEN
		LET bas_loc = 'acero_qm@idsuio01:'
	END IF
END IF
LET query = 'SELECT a.* ',
		' FROM ', bas_loc CLIPPED, 'cxct020 a',
		' WHERE z20_compania   = ', vg_codcia,
		'   AND z20_codcli     = ', rm_r23.r23_codcli,
		'   AND z20_fecha_emi <=  "', vg_fecha, '"',
		' INTO TEMP tmp_z20 '
PREPARE cons_z20 FROM query
EXECUTE cons_z20
LET fecha = EXTEND(vg_fecha, YEAR TO SECOND) + 23 UNITS HOUR +
		59 UNITS MINUTE + 59 UNITS SECOND
LET subquery1 = '(SELECT z23_valor_cap + z23_valor_int + z23_saldo_cap + ',
			'z23_saldo_int ',
		' FROM ', bas_loc CLIPPED, 'cxct023, ', bas_loc CLIPPED,
			'cxct022 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo ',
		'   AND z22_compania  = z23_compania ',
		'   AND z22_localidad = z23_localidad ',
		'   AND z22_codcli    = z23_codcli ',
		'   AND z22_tipo_trn  = z23_tipo_trn ',
		'   AND z22_num_trn   = z23_num_trn ',
		'   AND z22_fecing    = (SELECT MAX(z22_fecing) ',
					' FROM ', bas_loc CLIPPED, 'cxct023, ',
						bas_loc CLIPPED, 'cxct022 ',
					' WHERE z23_compania  = z20_compania ',
					'   AND z23_localidad = z20_localidad ',
					'   AND z23_codcli    = z20_codcli ',
					'   AND z23_tipo_doc  = z20_tipo_doc ',
					'   AND z23_num_doc   = z20_num_doc ',
					'   AND z23_div_doc   = z20_dividendo ',
					'   AND z22_compania  = z23_compania ',
					'   AND z22_localidad = z23_localidad ',
					'   AND z22_codcli    = z23_codcli ',
					'   AND z22_tipo_trn  = z23_tipo_trn ',
					'   AND z22_num_trn   = z23_num_trn ',
					'   AND z22_fecing   <= "', fecha, '"))'
LET subquery2 = ' (SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM ', bas_loc CLIPPED, 'cxct023 ',
		' WHERE z23_compania  = z20_compania ',
		'   AND z23_localidad = z20_localidad ',
		'   AND z23_codcli    = z20_codcli ',
		'   AND z23_tipo_doc  = z20_tipo_doc ',
		'   AND z23_num_doc   = z20_num_doc ',
		'   AND z23_div_doc   = z20_dividendo) '
LET query = ' SELECT g02_nombre, z20_localidad, z20_codcli, z20_tipo_doc, ',
			'z20_num_doc, z20_dividendo, z01_nomcli, ',
			'z20_fecha_emi, z20_fecha_vcto, ',
			'(z20_valor_cap + z20_valor_int) valor_doc, ',
			' NVL(', subquery1 CLIPPED, ', ',
			' CASE WHEN z20_fecha_emi <= "', vg_fecha, '"',
				' THEN z20_saldo_cap + z20_saldo_int - ',
					subquery2 CLIPPED,
				' ELSE z20_valor_cap + z20_valor_int',
			' END) valor_mov, z20_areaneg area_n, ',
			'z20_cod_tran cod_tran, z20_num_tran num_tran ',
		' FROM tmp_z20, gent002, cxct001 ',
		' WHERE g02_compania   = z20_compania ',
		'   AND g02_localidad  = z20_localidad ',
		'   AND z01_codcli     = z20_codcli ',
		' INTO TEMP tmp_mov '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_z20
DELETE FROM tmp_mov WHERE valor_mov = 0
SELECT COUNT(*) INTO num_doc FROM tmp_mov 
ERROR ' '
IF num_doc = 0 THEN
	RETURN 0
END IF
CALL obtener_documentos_a_favor()
RETURN 1

END FUNCTION



FUNCTION obtener_documentos_a_favor()
DEFINE fecha		LIKE cxct022.z22_fecing
DEFINE query		CHAR(6000)
DEFINE subquery1	CHAR(1000)
DEFINE subquery2	CHAR(400)
DEFINE bas_loc		VARCHAR(20)
DEFINE num_fav		INTEGER

ERROR "Procesando documentos a favor con saldos . . . espere por favor." ATTRIBUTE(NORMAL)
LET bas_loc = NULL
IF vg_codloc = 4 OR vg_codloc = 2 THEN
	IF vg_codloc = 2 THEN
		LET bas_loc = 'acero_gm@idsgye01:'
	END IF
	IF vg_codloc = 4 THEN
		LET bas_loc = 'acero_qm@idsuio01:'
	END IF
END IF
LET query = 'SELECT a.* ',
		' FROM ', bas_loc CLIPPED, 'cxct021 a',
		' WHERE z21_compania   = ', vg_codcia,
		'   AND z21_codcli     = ', rm_r23.r23_codcli,
		'   AND z21_fecha_emi <= "', vg_fecha, '"',
		' INTO TEMP tmp_z21 '
PREPARE cons_z21 FROM query
EXECUTE cons_z21
LET fecha = EXTEND(vg_fecha, YEAR TO SECOND) + 23 UNITS HOUR + 59 UNITS MINUTE
		+ 59 UNITS SECOND
LET subquery1 = '(SELECT SUM(z23_valor_cap + z23_valor_int) ',
		' FROM ', bas_loc CLIPPED, 'cxct023, ', bas_loc CLIPPED,
			'cxct022 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc ',
		'   AND z22_compania   = z23_compania ',
		'   AND z22_localidad  = z23_localidad ',
		'   AND z22_codcli     = z23_codcli ',
		'   AND z22_tipo_trn   = z23_tipo_trn ',
		'   AND z22_num_trn    = z23_num_trn ',
		'   AND z22_fecing     BETWEEN EXTEND(z21_fecha_emi, ',
						'YEAR TO SECOND)',
					 ' AND "', fecha, '")'
LET subquery2 = '(SELECT NVL(SUM(z23_valor_cap + z23_valor_int), 0) ',
		' FROM ', bas_loc CLIPPED, 'cxct023 ',
		' WHERE z23_compania   = z21_compania ',
		'   AND z23_localidad  = z21_localidad ',
		'   AND z23_codcli     = z21_codcli ',
		'   AND z23_tipo_favor = z21_tipo_doc ',
		'   AND z23_doc_favor  = z21_num_doc) '
LET query = 'SELECT z21_localidad, z21_tipo_doc, z21_num_doc, z21_codcli, ',
		' z01_nomcli, z21_fecha_emi, ',
		' NVL(CASE WHEN z21_fecha_emi > "', vg_fecha, '"',
			' THEN z21_valor + ', subquery1 CLIPPED,
			' ELSE ', subquery2 CLIPPED, ' + z21_saldo - ',
				  subquery1 CLIPPED,
		' END, ',
		' CASE WHEN z21_fecha_emi <= "', vg_fecha, '"',
			' THEN z21_saldo - ', subquery2 CLIPPED,
			' ELSE z21_valor',
		' END) * (-1) saldo_mov ',
		' FROM tmp_z21, cxct001 ',
		' WHERE z01_codcli     = z21_codcli ',
		' INTO TEMP tmp_fav '
PREPARE stmnt2 FROM query
EXECUTE stmnt2
DROP TABLE tmp_z21
DELETE FROM tmp_fav WHERE saldo_mov = 0
SELECT COUNT(*) INTO num_fav FROM tmp_fav
ERROR ' '
SELECT z21_localidad, z21_codcli, z01_nomcli, NVL(SUM(saldo_mov), 0) saldo_fav
	FROM tmp_fav
	GROUP BY 1, 2, 3
	INTO TEMP tmp_sal_fav
DROP TABLE tmp_fav

END FUNCTION



FUNCTION genera_tabla_trabajo_resumen()
DEFINE query		CHAR(1200)
DEFINE subquery		CHAR(800)
DEFINE num_cli		INTEGER
DEFINE flag		SMALLINT

LET flag = 1
ERROR "Generando resumen . . . espere por favor." ATTRIBUTE(NORMAL)
LET query = 'SELECT z20_localidad loc1, z20_codcli cli1, valor_mov sald1 ',
		' FROM tmp_mov ',
		' WHERE z20_fecha_vcto >= "', vg_fecha, '"', 
		'   AND valor_mov       > 0 ',
		' INTO TEMP t1 '
PREPARE cons_t1_a FROM query
EXECUTE	cons_t1_a
LET query = 'SELECT z20_localidad loc2, z20_codcli cli2, valor_mov sald2 ',
		' FROM tmp_mov ',
		' WHERE z20_fecha_vcto < "', vg_fecha, '"',
		'   AND valor_mov      > 0 ',
		' INTO TEMP t2 '
PREPARE cons_t2_a FROM query
EXECUTE	cons_t2_a
LET subquery = '(SELECT NVL(SUM(sald1), 0) ',
			' FROM t1 ',
			' WHERE cli1 = z20_codcli ',
			'   AND loc1 = z20_localidad), ',
			'(SELECT NVL(SUM(sald2), 0) ',
			' FROM t2 ',
			' WHERE cli2 = z20_codcli ',
			'   AND loc2 = z20_localidad) '
LET query = 'INSERT INTO tempo_doc ',
		' SELECT z20_localidad, z20_codcli, z01_nomcli, g02_nombre, ',
			subquery CLIPPED,
			' FROM tmp_mov ',
			' GROUP BY 1, 2, 3, 4'
PREPARE cons_mov FROM query
EXECUTE cons_mov
DELETE FROM tempo_doc WHERE por_vencer = 0 AND vencido = 0
SELECT COUNT(*) INTO num_cli FROM tempo_doc
ERROR " "
IF num_cli = 0 THEN
	LET flag = 0
END IF
DROP TABLE t1
DROP TABLE t2
RETURN flag

END FUNCTION



FUNCTION muestra_resumen_clientes()
DEFINE r_cli		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				locali		LIKE gent002.g02_localidad,
				tot_pven 	DECIMAL(12,2),
				tot_venc 	DECIMAL(12,2),
				tot_saldo 	DECIMAL(12,2)
			END RECORD
DEFINE query		CHAR(200)

SELECT codcli, nomcli, locali,
	NVL(SUM(por_vencer + vencido), 0) saldo_deu,
	NVL(SUM(por_vencer + vencido), 0) saldo_fav
	FROM tempo_doc
	GROUP BY 1, 2, 3
	INTO TEMP tmp_sal_deu
UPDATE tmp_sal_deu SET saldo_fav = 0
INSERT INTO tmp_sal_deu
	SELECT z21_codcli, z01_nomcli, z21_localidad, 0.00,
		NVL(SUM(saldo_fav), 0) saldo_fav
		FROM tmp_sal_fav
		GROUP BY 1, 2, 3, 4
SELECT codcli, nomcli, locali, NVL(SUM(saldo_deu), 0) saldo_deu,
	NVL(SUM(saldo_fav), 0) saldo_fav
	FROM tmp_sal_deu
	GROUP BY 1, 2, 3
	INTO TEMP tmp_cli_car
DROP TABLE tmp_sal_deu
DROP TABLE tmp_sal_fav
LET query = "SELECT codcli, nomcli, locali, saldo_deu, ",
			"NVL(saldo_fav, 0), saldo_deu + ",
			"NVL(saldo_fav, 0) ",
		" FROM tmp_cli_car "
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
OPEN q_cons2
FETCH q_cons2 INTO r_cli.*
CLOSE q_cons2
FREE q_cons2
DROP TABLE tmp_cli_car
IF r_cli.tot_saldo <= 0 THEN
	RETURN 1, r_cli.*
END IF
RETURN 0, r_cli.*

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

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
DISPLAY '<F6>      Estado de Cuenta'         AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Control de Crédito'       AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Ver Pre-Venta'            AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

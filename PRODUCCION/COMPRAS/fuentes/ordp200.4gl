{*
 * Titulo           : ordp200.4gl - Mantenimineto de Ordenes de Compra
 * Elaboracion      : 01-sep-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun ordp200 base modulo compania localidad
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE
DEFINE vm_max_detalle	SMALLINT	-- NUMERO MAXIMO ELEMENTOS DEL DETALLE
DEFINE vm_num_recep	SMALLINT	-- NUMERO DE RECEPCIONES DE LA OC

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r10		 	RECORD LIKE rept010.*	-- MAESTRO DE ITEMS
DEFINE rm_c01		 	RECORD LIKE ordt001.*	-- TIPO DE O.C.
DEFINE rm_c10		 	RECORD LIKE ordt010.*	-- CABECERA
DEFINE rm_c11		 	RECORD LIKE ordt011.*	-- DETALLE
DEFINE rm_c12		 	RECORD LIKE ordt012.*	-- FORMA DE PAGO
DEFINE rm_g34		 	RECORD LIKE gent034.*	-- DEPARTAMENTOS
DEFINE rm_p01		 	RECORD LIKE cxpt001.*	-- PROVEEDORES
DEFINE rm_t23		 	RECORD LIKE talt023.*	-- ORDENES DE TRABAJO
DEFINE rm_g13		 	RECORD LIKE gent013.*	-- MONEDAS
DEFINE rm_g14		 	RECORD LIKE gent014.*	-- CONVERSION MONEDAS

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[250] OF RECORD
	c11_tipo		LIKE ordt011.c11_tipo,
	c11_cant_ped		LIKE ordt011.c11_cant_ped,
	c11_codigo		LIKE ordt011.c11_codigo,
	c11_descrip		LIKE ordt011.c11_descrip,
	c11_descuento		LIKE ordt011.c11_descuento,
	c11_precio		LIKE ordt011.c11_precio,
	paga_iva		LIKE ordt011.c11_paga_iva
	END RECORD
----------------------------------------------------------

	---- ARREGLO PARA LA FORMA DE PAGO ----
DEFINE r_detalle_2 ARRAY[250] OF RECORD
	c12_dividendo		LIKE ordt012.c12_dividendo,
	c12_fecha_vcto		LIKE ordt012.c12_fecha_vcto,
	c12_valor_cap		LIKE ordt012.c12_valor_cap,
	c12_valor_int		LIKE ordt012.c12_valor_int,
	subtotal		LIKE ordt012.c12_valor_cap
	END RECORD
-------------------------------------------------------

DEFINE vm_subtotal		LIKE ordt010.c10_tot_repto
DEFINE vm_subtotal_2		LIKE ordt010.c10_tot_repto

	----------------------------------------------------------

	---- ARREGLO PARALELO ----
DEFINE r_detalle_1 ARRAY[250] OF RECORD
	c11_tipo		LIKE ordt011.c11_tipo,
	c11_val_descto		LIKE ordt011.c11_val_descto
	END RECORD
	--------------------------

DEFINE vm_tipo			LIKE ordt011.c11_tipo
DEFINE vm_flag_item		CHAR(1)	   -- S o N
DEFINE vm_flag_mant		CHAR(1)	   -- FLAG DE MANTENIMIENTO
					   -- 'I' --> INGRESO		
					   -- 'M' --> MODIFICACION		
					   -- 'C' --> CONSULTA		
DEFINE vm_ind_arr	SMALLINT   -- INDICE DE MI ARREGLO (INPUT ARRAY)
DEFINE vm_ini_arr       SMALLINT        -- Indica la posicion inicial desde
                                        -- que se empezo a mostrar la ultima vez
DEFINE vm_curr_arr      SMALLINT        -- Indica la posición actual en el
                                        -- detalle (ultimo elemento mostrado)
DEFINE vm_filas_pant	SMALLINT   -- FILAS EN PANTALLA

DEFINE vg_num_ord		LIKE ordt010.c10_numero_oc
DEFINE vm_calc_iva		CHAR(1) 	-- S: Subtotal
						-- D: Detalle

---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE FORMA DE PAGO ----

DEFINE pagos			SMALLINT
DEFINE tot_dias			SMALLINT	
DEFINE fecha_pago		DATE
DEFINE dias_pagos		SMALLINT
DEFINE tot_compra		LIKE ordt010.c10_tot_compra
DEFINE tot_cap			LIKE ordt010.c10_tot_compra
DEFINE tot_int			LIKE ordt010.c10_tot_compra
DEFINE tot_sub			LIKE ordt010.c10_tot_compra
---------------------------------------------------------------


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp200.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_num_ord  = arg_val(5)
LET vg_proceso = 'ordp200'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_rows     = 1000
LET vm_max_detalle  = 250

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW w_200 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_200 FROM '../forms/ordf200_1'
DISPLAY FORM f_200
CALL control_display_botones()

LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_num_rows = 0
LET vm_row_current = 0

INITIALIZE rm_c10.*, rm_c11.* TO NULL

CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
                HIDE OPTION 'Ver Recepción'
                HIDE OPTION 'Imprimir'
		IF num_args() = 5 THEN
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			SHOW OPTION 'Imprimir'
			IF rm_c10.c10_estado <> 'A' THEN
				CALL control_cargar_recepciones()
				IF vm_num_recep <> 0 THEN
					SHOW OPTION 'Ver Recepción'
				END IF
			END IF
                	IF vm_num_rows = 1 AND (vm_ind_arr - vm_curr_arr) > 0
			   THEN
                       	 	SHOW OPTION 'Avanzar Detalle'
                	END IF
		END IF 

	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
                CALL control_ingreso()
                HIDE OPTION 'Ver Recepción'
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Imprimir'
		END IF
                IF vm_num_rows = 1 AND (vm_ind_arr - vm_curr_arr) > 0 THEN
                        SHOW OPTION 'Avanzar Detalle'
                END IF
                IF vm_row_current > 1 THEN
                        SHOW OPTION 'Retroceder'
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                END IF
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                END IF

	COMMAND KEY('M') 'Modificar' 		'Modificar un registro.'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	

	COMMAND KEY('P') 'Ver Recepción' 'Ver recepción de la orden de compra.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_recepcion()
		END IF	
		
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
                CALL control_consulta()
		IF num_args() = 5 THEN
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_num_rows > 0 THEN
			IF rm_c10.c10_estado <> 'A' THEN
				CALL control_cargar_recepciones()
				IF vm_num_recep <> 0 THEN
					SHOW OPTION 'Ver Recepción'
				ELSE
					HIDE OPTION 'Ver Recepción'
				END IF
			ELSE
                        	HIDE OPTION 'Ver Recepción'
			END IF
		END IF
                IF vm_num_rows <= 1 THEN
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                        SHOW OPTION 'Modificar'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                        	HIDE OPTION 'Modificar'
                        	HIDE OPTION 'Ver Recepción'
                        END IF
                ELSE
                        SHOW OPTION 'Modificar'
                        SHOW OPTION 'Avanzar'
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF

        COMMAND KEY('I') 'Imprimir'      'Imprime la Orden de Compra.'
		IF vm_num_rows > 0 THEN
			CALL control_imprimir_oc()
		END IF

        COMMAND KEY('V') 'Avanzar Detalle'      'Muestra siguientes detalles.'
                CALL control_mostrar_sig_det()
                IF (vm_ind_arr - vm_curr_arr) <= 0 THEN
                        HIDE OPTION 'Avanzar Detalle'
                END IF
                SHOW OPTION 'Retroceder Detalle'

        COMMAND KEY('T') 'Retroceder Detalle'   'Muestra anteriores detalles.'
                CALL control_mostrar_ant_det()
                SHOW OPTION 'Avanzar Detalle'
                IF vm_ini_arr <= 1 THEN
                        HIDE OPTION 'Retroceder Detalle'
		END IF	

	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Modificar'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                        SHOW OPTION 'Avanzar Detalle'
                END IF
		IF rm_c10.c10_estado <> 'A' THEN
			CALL control_cargar_recepciones()
			IF vm_num_recep <> 0 THEN
				SHOW OPTION 'Ver Recepción'
			ELSE
				HIDE OPTION 'Ver Recepción'
			END IF
		ELSE
                       	HIDE OPTION 'Ver Recepción'
		END IF

	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                        SHOW OPTION 'Avanzar Detalle'
                END IF
		IF rm_c10.c10_estado <> 'A' THEN
			CALL control_cargar_recepciones()
			IF vm_num_recep <> 0 THEN
				SHOW OPTION 'Ver Recepción'
			ELSE
				HIDE OPTION 'Ver Recepción'
			END IF
		ELSE
                       	HIDE OPTION 'Ver Recepción'
		END IF

	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU

END MENU

END FUNCTION


                                                                                
FUNCTION control_cargar_recepciones()
DEFINE r_c13            RECORD LIKE ordt013.*
DEFINE i                SMALLINT
                                                                                
DECLARE q_ordt013 CURSOR FOR
        SELECT * FROM ordt013
               WHERE c13_compania  = vg_codcia
                 AND c13_localidad = vg_codloc
                 AND c13_numero_oc = rm_c10.c10_numero_oc
                                                                                
LET i = 1
FOREACH q_ordt013 INTO r_c13.* 
        LET i = i + 1
        IF i > 100 THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_recep = i - 1
                                                                                
END FUNCTION



FUNCTION control_ver_recepcion()
DEFINE command_run	VARCHAR(150)

LET command_run = 'fglrun ordp202 ', vg_base, ' ', vg_modulo, ' ', 
	           vg_codcia, ' ', vg_codloc, ' ', rm_c10.c10_numero_oc 	

RUN command_run

END FUNCTION



FUNCTION control_imprimir_oc()
DEFINE command_run	VARCHAR(150)

LET command_run = 'fglrun ordp400 ', vg_base, ' ', vg_modulo, ' ', 
	           vg_codcia, ' ', vg_codloc, ' ', rm_c10.c10_numero_oc 	

RUN command_run

END FUNCTION



FUNCTION control_mostrar_sig_det()
DEFINE i                SMALLINT
DEFINE filas_pant       SMALLINT
DEFINE filas_mostrar    SMALLINT
                                                                                
IF (vm_ind_arr - vm_curr_arr) <= 0 THEN
        RETURN
END IF
                                                                                
LET filas_pant = fgl_scr_size('r_detalle')
LET filas_mostrar = vm_ind_arr - vm_curr_arr
                                                                                
FOR i = 1 TO filas_pant
        CLEAR r_detalle[i].*
END FOR
                                                                                
IF filas_mostrar < filas_pant THEN
        LET filas_pant = filas_mostrar
END IF
                                                                                
LET vm_ini_arr = vm_curr_arr + 1
                                                                                
FOR i = 1 TO filas_pant
        LET vm_curr_arr = vm_curr_arr + 1
        DISPLAY r_detalle[vm_curr_arr].* TO r_detalle[i].*
END FOR

END FUNCTION



FUNCTION control_mostrar_ant_det()
DEFINE i                SMALLINT
DEFINE filas_pant       SMALLINT
                                                                                
IF vm_ini_arr <= 1 THEN
        RETURN
END IF
                                                                                
LET filas_pant = fgl_scr_size('r_detalle')
LET vm_ini_arr = vm_ini_arr - filas_pant
FOR i = 1 TO filas_pant
        CLEAR r_detalle[i].*
END FOR
                                                                                
LET vm_curr_arr = vm_ini_arr - 1
FOR i = 1 TO filas_pant
        LET vm_curr_arr = vm_curr_arr + 1
        DISPLAY r_detalle[vm_curr_arr].* TO r_detalle[i].*
END FOR
                                                                                
END FUNCTION



FUNCTION control_forma_pago()
DEFINE i 	SMALLINT

IF rm_c10.c10_tipo_pago = 'C' THEN

	CALL fgl_winmessage(vg_producto,'La forma de pago solo para ordenes de compra a crédito.','exclamation')
	RETURN

END IF

OPEN WINDOW w_200_2 AT 6,8 WITH 16 ROWS, 71 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_200_2 FROM '../forms/ordf200_2'
DISPLAY FORM f_200_2

CALL control_display_botones_2()

IF num_args() = 5 THEN
	LET i = control_cargar_forma_pago_oc()
	CALL control_display_ordt012(i)
	CLOSE WINDOW w_200_2
	RETURN
END IF

BEGIN WORK
display 'begin... forma pago'

IF vm_flag_mant <> 'M' THEN

	WHENEVER ERROR CONTINUE
	DECLARE q_ordt010_2 CURSOR FOR 
		SELECT * FROM ordt010 
			WHERE c10_compania  = vg_codcia
			AND   c10_localidad = vg_codloc
			AND   c10_numero_oc = rm_c10.c10_numero_oc
		FOR UPDATE

	OPEN q_ordt010_2
	FETCH q_ordt010_2 

	IF status < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto,'La orden de compra esta siendo modificada por otro usuario.','exclamation')
		CLOSE WINDOW w_200_2
		RETURN
	END IF
	WHENEVER ERROR STOP

END IF

LET tot_compra         = rm_c10.c10_tot_compra

DISPLAY BY NAME tot_compra, rm_c10.c10_interes

IF rm_c10.c10_estado <> 'A' THEN
	ROLLBACK WORK
	LET i = control_cargar_forma_pago_oc()
	CALL control_display_ordt012(i)
	CLOSE WINDOW w_200_2
	RETURN
END IF

LET i = control_cargar_forma_pago_oc()

IF i = 0 THEN
	ROLLBACK WORK
	CLOSE WINDOW w_200_2
	RETURN
END IF

IF i = 1 THEN
	LET pagos      = 1 
	LET fecha_pago = TODAY + 30
	LET dias_pagos = 30
	LET tot_cap    = 0
	LET tot_int    = 0
	LET tot_sub    = 0
	DISPLAY BY NAME fecha_pago, dias_pagos, tot_cap, tot_int, tot_sub
END IF

CALL control_ingreso_forma_pago_oc()

IF int_flag THEN
	ROLLBACK WORK
	CLOSE WINDOW w_200_2
	RETURN
END IF

CALL control_cargar_detalle_forma_pago()

IF rm_c10.c10_interes > 0 THEN
	CALL control_display_ordt012(pagos)
	LET int_flag = 0
ELSE
	CALL control_lee_detalle_forma_pago()
	LET int_flag = 0
END IF

CALL control_insert_ordt012()

UPDATE ordt010 
	SET c10_interes = rm_c10.c10_interes
		WHERE c10_compania  = vg_codcia
		  AND c10_localidad = vg_codloc
		  AND c10_numero_oc = rm_c10.c10_numero_oc

COMMIT WORK
display 'commit... form pago'
CLOSE WINDOW w_200_2

END FUNCTION



FUNCTION control_insert_ordt012()
DEFINE  i 	SMALLINT

DELETE FROM ordt012
	WHERE c12_compania  = vg_codcia
	  AND c12_localidad = vg_codloc
	  AND c12_numero_oc = rm_c10.c10_numero_oc

IF rm_c10.c10_tipo_pago = 'C' THEN
	RETURN
END IF

LET rm_c12.c12_compania  = vg_codcia
LET rm_c12.c12_localidad = vg_codloc
LET rm_c12.c12_numero_oc = rm_c10.c10_numero_oc

FOR i = 1 TO pagos
	
	LET rm_c12.c12_dividendo  = i
	LET rm_c12.c12_fecha_vcto = r_detalle_2[i].c12_fecha_vcto
	LET rm_c12.c12_valor_cap  = r_detalle_2[i].c12_valor_cap
	LET rm_c12.c12_valor_int  = r_detalle_2[i].c12_valor_int

	INSERT INTO ordt012 VALUES(rm_c12.*)

END FOR

END FUNCTION



FUNCTION control_display_ordt012(i)
DEFINE i,filas 	SMALLINT

LET filas = fgl_scr_size('detalle_2')

CALL set_count(i)

DISPLAY ARRAY r_detalle_2 TO r_detalle_2.* 
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT','')
		CALL dialog.keysetlabel('F3','')
		CALL dialog.keysetlabel('F4','')
		IF i <= filas THEN
			CALL fgl_keysetlabel('Avanzar','')
			CALL fgl_keysetlabel('Retroceder','')
		END IF

        AFTER DISPLAY
                CONTINUE DISPLAY

        ON KEY(INTERRUPT)
                EXIT DISPLAY

END DISPLAY

END FUNCTION



FUNCTION control_cargar_forma_pago_oc()
DEFINE r_c12		RECORD LIKE ordt012.*
DEFINE i,k,filas		SMALLINT

FOR k = 1 TO fgl_scr_size('r_detalle_2')
	INITIALIZE r_detalle_2[k].* TO NULL
	CLEAR      r_detalle_2[k].*
END FOR

DECLARE q_ordt012 CURSOR FOR 
	SELECT * FROM ordt012 
		WHERE c12_compania  = vg_codcia
		  AND c12_localidad = vg_codloc
		  AND c12_numero_oc = rm_c10.c10_numero_oc

LET tot_compra = 0
LET tot_cap    = 0
LET tot_int    = 0
LET tot_sub    = 0
LET i = 1
FOREACH q_ordt012 INTO r_c12.*
	LET r_detalle_2[i].c12_dividendo  = r_c12.c12_dividendo
	LET r_detalle_2[i].c12_fecha_vcto = r_c12.c12_fecha_vcto
	LET r_detalle_2[i].c12_valor_cap  = r_c12.c12_valor_cap
	LET r_detalle_2[i].c12_valor_int  = r_c12.c12_valor_int
	LET r_detalle_2[i].subtotal       = r_c12.c12_valor_cap +
					    r_c12.c12_valor_int

	LET tot_cap = tot_cap + r_c12.c12_valor_cap	
	LET tot_int = tot_int + r_c12.c12_valor_int	
	LET tot_sub = tot_sub + r_detalle_2[i].subtotal	

	LET i = i + 1
	IF i > vm_max_detalle THEN
		CALL fgl_winmessage(vg_producto,'Ha superado el maximo número de elementos del detalle no puede continuar cargando el detalle de la forma de pago.','exclamation')
		RETURN 0
	END IF

END FOREACH

LET i = i - 1

LET pagos = i

IF i > 0 THEN
	LET tot_dias = r_detalle_2[i].c12_fecha_vcto - DATE(rm_c10.c10_fecing)
END IF

LET tot_compra = rm_c10.c10_tot_compra
DISPLAY BY NAME pagos, tot_cap, tot_int, tot_sub, tot_dias, tot_compra,
		       rm_c10.c10_interes	

IF i = 0 THEN
	RETURN 1
END IF

LET filas = fgl_scr_size('r_detalle_2')

IF i < filas THEN
	LET filas = i
END IF 

FOR k = 1 TO filas 
	IF k = 1 THEN
		LET fecha_pago = r_detalle_2[k].c12_fecha_vcto
		LET dias_pagos = r_detalle_2[k].c12_fecha_vcto -
				 DATE(rm_c10.c10_fecing)
		IF filas > 1 THEN
			LET dias_pagos = r_detalle_2[k + 1].c12_fecha_vcto -
					 r_detalle_2[k].c12_fecha_vcto 
		END IF
		DISPLAY BY NAME fecha_pago, dias_pagos
	END IF
	DISPLAY r_detalle_2[k].* TO r_detalle_2[k].*
END FOR

RETURN i

END FUNCTION



FUNCTION calcula_interes()
DEFINE valor		LIKE ordt012.c12_valor_cap
DEFINE i 		SMALLINT

LET tot_cap = 0
LET tot_int = 0
LET tot_sub = 0
LET valor   = rm_c10.c10_tot_compra

FOR i = 1 TO pagos

	LET r_detalle_2[i].c12_valor_int = valor * 
			                   (rm_c10.c10_interes / 100) *
		      			   (dias_pagos /360)

	LET valor = valor - r_detalle_2[i].c12_valor_cap

	LET r_detalle_2[i].subtotal = r_detalle_2[i].c12_valor_cap +
				      r_detalle_2[i].c12_valor_int

	LET tot_cap     = tot_cap   + r_detalle_2[i].c12_valor_cap
	LET tot_int     = tot_int   + r_detalle_2[i].c12_valor_int
	LET tot_sub     = tot_sub   + r_detalle_2[i].subtotal

END FOR
DISPLAY BY NAME tot_cap, tot_int, tot_sub

END FUNCTION



FUNCTION control_cargar_detalle_forma_pago()
DEFINE i 		SMALLINT
DEFINE saldo    	LIKE ordt010.c10_tot_compra
DEFINE val_div  	LIKE ordt010.c10_tot_compra

LET saldo   = rm_c10.c10_tot_compra
LET val_div = rm_c10.c10_tot_compra / pagos

FOR i = 1 TO pagos

	LET r_detalle_2[i].c12_dividendo = i

	IF i = 1 THEN
		LET r_detalle_2[i].c12_fecha_vcto = fecha_pago
	ELSE
		LET r_detalle_2[i].c12_fecha_vcto = 
		    r_detalle_2[i-1].c12_fecha_vcto + dias_pagos
	END IF

	IF i <> pagos THEN
		LET r_detalle_2[i].c12_valor_cap = val_div
		LET saldo = saldo - val_div
	ELSE
		LET r_detalle_2[i].c12_valor_cap = saldo
	END IF

END FOR 

	CALL calcula_interes()

	LET vm_filas_pant = fgl_scr_size('r_detalle_2')

	IF pagos < vm_filas_pant THEN
		LET vm_filas_pant = pagos
	END IF 

	FOR i = 1 TO vm_filas_pant
		DISPLAY r_detalle_2[i].* TO r_detalle_2[i].*
	END FOR

END FUNCTION



FUNCTION control_ingreso_forma_pago_oc()

LET int_flag = 0
INPUT BY NAME pagos, rm_c10.c10_interes, fecha_pago, dias_pagos 
	      WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 0
		IF r_detalle_2[1].c12_dividendo IS NOT NULL THEN
			LET int_flag = 1
			RETURN
		END IF

		CALL fgl_winmessage(vg_producto,'Debe especificar la forma de pago de esta orden de compra ','exclamation')
		CONTINUE INPUT
		
	AFTER FIELD fecha_pago
		IF fecha_pago < TODAY THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar una fecha mayor o igual a la de hoy.','exclamation')
			NEXT FIELD fecha_pago
		END IF

	AFTER FIELD pagos
		IF pagos IS NOT NULL AND dias_pagos IS NOT NULL THEN
			LET tot_dias = pagos * dias_pagos
			DISPLAY BY NAME tot_dias
		END IF

	AFTER FIELD dias_pagos
		IF pagos IS NOT NULL AND dias_pagos IS NOT NULL THEN
			LET tot_dias = pagos * dias_pagos
			DISPLAY BY NAME tot_dias
		END IF

	AFTER INPUT 
		IF pagos IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar el número de pagos para generar el detalle.','exclamation')
			NEXT FIELD pagos
		END IF
			
		IF fecha_pago IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar la fecha del primer pago de la orden de compra.','exclamation')
			NEXT FIELD fecha_pago
		END IF

		IF dias_pagos IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar el número de días entre pagos para generar el detalle.','exclamation')
			NEXT FIELD dias_pagos
		END IF
			
END INPUT

END FUNCTION



FUNCTION control_lee_detalle_forma_pago()
DEFINE resp 		CHAR(6)
DEFINE i,j,k		SMALLINT
DEFINE fecha_aux 	LIKE rept026.r26_fec_vcto


OPTIONS
	INSERT KEY F30,
	DELETE KEY F40

WHILE TRUE

	LET int_flag = 0
	CALL set_count(pagos) 

	INPUT ARRAY r_detalle_2 WITHOUT DEFAULTS FROM r_detalle_2.*

		BEFORE INPUT 
			CALL dialog.keysetlabel ('INSERT','')
			CALL dialog.keysetlabel ('DELETE','')

		ON KEY(INTERRUPT)
			LET int_flag = 0
			CONTINUE INPUT

		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()

		BEFORE INSERT
			EXIT INPUT

		BEFORE FIELD c12_fecha_vcto
			LET fecha_aux = r_detalle_2[i].c12_fecha_vcto

		AFTER FIELD c12_fecha_vcto
			IF r_detalle_2[i].c12_fecha_vcto IS NULL THEN
				LET r_detalle_2[i].c12_fecha_vcto = fecha_aux
				DISPLAY r_detalle_2[i].c12_fecha_vcto TO
					r_detalle_2[j].c12_fecha_vcto
			END IF

		AFTER FIELD c12_valor_cap
			IF r_detalle_2[i].c12_valor_cap IS NOT NULL THEN
				CALL calcula_interes()
			ELSE 
				NEXT FIELD c12_valor_cap
			END IF

		AFTER INPUT
			FOR k = 1 TO arr_count() - 1
				IF r_detalle_2[k].c12_fecha_vcto >=
				   r_detalle_2[k + 1].c12_fecha_vcto
				   THEN
					CALL fgl_winmessage(vg_producto,'Existen fechas que resultan menores a las ingresadas anteriormente en los pagos. ','exclamation')
					EXIT INPUT
				END IF
			END FOR	

			IF tot_cap > tot_compra THEN
				CALL fgl_winmessage(vg_producto,'El total del valor capital es mayor al total de la deuda. ','exclamation')
				EXIT INPUT
			END IF

			IF tot_cap < tot_compra THEN
				CALL fgl_winmessage(vg_producto,'El total del valor capital es menor al total de la deuda. ','exclamation')
				EXIT INPUT
			END IF

			LET tot_dias = r_detalle_2[pagos].c12_fecha_vcto - TODAY 	
			DISPLAY BY NAME tot_dias

			EXIT WHILE
	END INPUT

END WHILE	

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'T' 		TO tit_col0
DISPLAY 'Can' 		TO tit_col1
DISPLAY 'Codigo' 	TO tit_col2
DISPLAY 'Descripción'	TO tit_col3
DISPLAY 'Des %'		TO tit_col4
DISPLAY 'Precio Unit.'	TO tit_col5

END FUNCTION



FUNCTION control_display_botones_2()

DISPLAY '#' 	 	TO tit_col1
DISPLAY 'Fecha Vcto'	TO tit_col2
DISPLAY 'Valor Capital'	TO tit_col3
DISPLAY 'Valor Interes'	TO tit_col4
DISPLAY 'Subtotal'	TO tit_col5

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE  i,j 	SMALLINT

CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.*
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT', '')
	BEFORE ROW
		LET i = arr_curr()	
		LET j = scr_line()	

		IF r_detalle[i].c11_descuento IS NOT NULL AND
		   r_detalle[i].c11_precio    IS NOT NULL AND
		   r_detalle[i].c11_cant_ped  IS NOT NULL 
		   THEN
			LET vm_subtotal_2 = r_detalle[i].c11_precio * 
					  r_detalle[i].c11_cant_ped
			DISPLAY BY NAME vm_subtotal_2
		END IF

        AFTER DISPLAY
                CONTINUE DISPLAY
        ON KEY(INTERRUPT)
		CLEAR vm_subtotal_2
                EXIT DISPLAY
		
END DISPLAY

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)

CLEAR FORM
CALL control_display_botones()

LET vm_flag_mant = 'I'
INITIALIZE rm_c10.*, rm_c11.* TO NULL

-- INITIAL VALUES FOR rm_c10 FIELDS
LET rm_c10.c10_tipo_pago   = 'C'
LET rm_c10.c10_recargo     = 0
LET rm_c10.c10_estado      = 'A'
LET rm_c10.c10_fecing      = CURRENT
LET rm_c10.c10_usuario     = vg_usuario
LET rm_c10.c10_compania    = vg_codcia
LET rm_c10.c10_localidad   = vg_codloc
LET rm_c10.c10_moneda      = rg_gen.g00_moneda_base
LET rm_c10.c10_paridad     = 1
LET rm_c10.c10_porc_descto = 0
LET rm_c10.c10_interes     = 0
LET rm_c10.c10_porc_impto = rg_gen.g00_porc_impto

CALL fl_lee_moneda(rg_gen.g00_moneda_base) 	     -- PARA OBTENER EL NOMBRE 
	RETURNING rm_g13.*		   	     -- DE LA MONEDA BASE
LET rm_c10.c10_precision = rm_g13.g13_decimales

DISPLAY BY NAME rm_c10.c10_moneda,      rm_c10.c10_porc_impto, 
		rm_c10.c10_porc_descto, rm_c10.c10_usuario,
		rm_c10.c10_recargo,	rm_c10.c10_tipo_pago,
		rm_c10.c10_fecing,	rm_c10.c10_estado	

DISPLAY rm_g13.g13_nombre TO nom_moneda
DISPLAY 'ACTIVO' TO tit_estado
LET vm_calc_iva = 'S'

CALL control_lee_cabecera()

IF int_flag THEN
	LET int_flag = 0
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET vm_num_detalles = control_lee_detalle() 

IF int_flag THEN
	LET int_flag = 0
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
	-- ACTUALIZO LOS VALORES DEFAULTS QUE INGRESE AL INICIO DE LEE DATOS --

BEGIN WORK
display 'begin... ingreso   '

	LET done = control_insert_ordt010()
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso de la cabecera de la orden de compra no se realizará el proceso.','exclamation')
		IF vm_num_rows <= 1 THEN
			LET vm_num_rows = 0
			LET vm_row_current = 0
			CLEAR FORM
			CALL control_display_botones()
		ELSE
			LET vm_num_rows = vm_num_rows - 1
			LET vm_row_current = vm_num_rows
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF 

	LET done = control_insert_ordt011()
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso del detalle de la orden de compra no se realizará el proceso.','exclamation')
		IF vm_num_rows <= 1 THEN
			LET vm_num_rows = 0
			LET vm_row_current = 0
			CLEAR FORM
			CALL control_display_botones()
		ELSE
			LET vm_num_rows = vm_num_rows - 1
			LET vm_row_current = vm_num_rows
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
COMMIT WORK
display 'commit... ingreso  '

IF rm_c10.c10_tipo_pago = 'R' THEN
	CALL fgl_winmessage(vg_producto,'Debe especificar la forma de pago para esta orden de compra','info')
	CALL control_forma_pago()
END IF


{* 
 * Esto fue un hack, se lo elimina

CALL fgl_winquestion(vg_producto, 'Desea aprobar esta orden de compra?', 'No',
		     'Yes|No', 'question', 1)	
	RETURNING resp
IF resp = 'Yes' THEN
	LET rm_c10.c10_estado = 'P'
	LET rm_c10.c10_usua_aprob = vg_usuario
	LET rm_c10.c10_fecha_aprob = CURRENT
	UPDATE ordt010 SET * = rm_c10.* 
		WHERE c10_compania  = rm_c10.c10_compania
		  AND c10_localidad = rm_c10.c10_localidad
		  AND c10_numero_oc = rm_c10.c10_numero_oc			
END IF
*}

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
DEFINE done			SMALLINT
DEFINE resp			VARCHAR(6)
DEFINE aprobada		SMALLINT

IF rm_c10.c10_estado = 'C' THEN
	CALL fgl_winmessage(vg_producto,
			    'No puede modificar una orden de compra cerrada.','exclamation')
	RETURN
END IF

SELECT * FROM ordt013
 WHERE c13_compania  = vg_codcia
   AND c13_localidad = vg_codloc
   AND c13_numero_oc = rm_c10.c10_numero_oc
   AND c13_estado <> 'E'
IF status <> NOTFOUND THEN
	CALL fgl_winmessage(vg_producto,
			    'No puede modificar orden de compra por que ya se han realizado recepciones.','exclamation')
	RETURN
END IF

LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ordt010 CURSOR FOR 
	SELECT * FROM ordt010 
		WHERE c10_compania  = vg_codcia
		AND   c10_localidad = vg_codloc
		AND   c10_numero_oc = rm_c10.c10_numero_oc
	FOR UPDATE
OPEN q_ordt010
FETCH q_ordt010 
IF status < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP

LET aprobada = 0
IF rm_c10.c10_estado = 'P' THEN
	CALL fgl_winquestion(vg_producto,
		'La orden ya fue aprobada, si continua deberá ' ||  
		'aprobar la orden nuevamente. Desea continuar?',
		'No', 'Yes|No', 'question', 1) RETURNING resp
	IF resp = 'No' THEN
		ROLLBACK WORK
		RETURN
	END IF
	LET aprobada = 1
	LET rm_c10.c10_estado = 'A'
	DISPLAY BY NAME rm_c10.c10_estado
	DISPLAY 'ACTIVO' TO tit_estado 
END IF

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden)
	RETURNING rm_c01.*
LET vm_tipo = rm_c01.c01_bien_serv

LET vm_flag_item = 'N'

IF rm_c01.c01_modulo = 'RE' AND rm_c01.c01_ing_bodega = 'S' 
   THEN
	LET vm_flag_item = 'S'
END IF

CALL control_lee_cabecera()

IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

LET vm_num_detalles = control_lee_detalle() 

IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
ELSE
	IF rm_c10.c10_tipo_pago = 'C' THEN
			LET rm_c10.c10_interes = 0
	END IF

	UPDATE ordt010 	
		SET * = rm_c10.*
		WHERE CURRENT OF q_ordt010

	DELETE FROM ordt011
		WHERE c11_compania  = vg_codcia
		AND   c11_localidad = vg_codloc
		AND   c11_numero_oc   = rm_c10.c10_numero_oc

	LET done = control_insert_ordt011()
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error al intentar actualizar el detalle de la preventa. No se realizará el proceso.','exclamation')
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN
	END IF

	COMMIT WORK

	IF rm_c10.c10_tipo_pago = 'R' THEN
		CALL fgl_winmessage(vg_producto,'Debe especificar la forma de pago para esta orden de compra','info')
		CALL control_forma_pago()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE 
		CALL control_insert_ordt012()
	END IF
	IF aprobada AND rm_c10.c10_ord_trabajo IS NOT NULL THEN
		CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc, 
			rm_c10.c10_ord_trabajo)
	END IF

	CALL lee_muestra_registro(vm_rows[vm_row_current])

	CALL fl_mensaje_registro_modificado()
END IF

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



FUNCTION control_insert_ordt010()
DEFINE i,done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE numprev          INTEGER


LET done = 1
LET rm_c10.c10_fecing = CURRENT

SELECT MAX(c10_numero_oc) + 1 INTO rm_c10.c10_numero_oc
	FROM  ordt010
	WHERE c10_compania  = vg_codcia
	AND   c10_localidad = vg_codloc

IF rm_c10.c10_numero_oc IS NULL THEN
	LET rm_c10.c10_numero_oc = 1
END IF


INSERT INTO ordt010 VALUES (rm_c10.*)
DISPLAY BY NAME rm_c10.c10_numero_oc

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
        LET vm_num_rows = vm_num_rows + 1
END IF

LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 

RETURN done

END FUNCTION



FUNCTION control_insert_ordt011()
DEFINE i,done 	SMALLINT

LET rm_c11.c11_compania   = vg_codcia
LET rm_c11.c11_localidad  = vg_codloc
LET rm_c11.c11_numero_oc  = rm_c10.c10_numero_oc
LET rm_c11.c11_cant_rec   = 0

FOR i = 1 TO vm_num_detalles
	
	display r_detalle[i].c11_tipo, vm_tipo
	IF vm_tipo <> 'T' THEN
		LET rm_c11.c11_tipo = vm_tipo
	ELSE
		LET rm_c11.c11_tipo = r_detalle[i].c11_tipo
	END IF

	LET rm_c11.c11_cant_ped     = r_detalle[i].c11_cant_ped
	LET rm_c11.c11_codigo       = r_detalle[i].c11_codigo
	LET rm_c11.c11_descrip      = r_detalle[i].c11_descrip
	LET rm_c11.c11_descuento    = r_detalle[i].c11_descuento
	LET rm_c11.c11_precio       = r_detalle[i].c11_precio
	LET rm_c11.c11_secuencia    = i
	LET rm_c11.c11_paga_iva     = r_detalle[i].paga_iva
	IF vm_calc_iva = 'S' THEN
		LET rm_c11.c11_paga_iva = 'S'
	END IF
	LET rm_c11.c11_val_descto   = r_detalle_1[i].c11_val_descto
	IF vm_calc_iva = 'D' AND r_detalle[i].paga_iva = 'S' THEN
		LET rm_c11.c11_val_impto   = ((r_detalle[i].c11_cant_ped *
					       r_detalle[i].c11_precio) -
					      r_detalle_1[i].c11_val_descto) *
					     rm_c10.c10_porc_impto / 100  
		LET rm_c11.c11_val_impto = fl_retorna_precision_valor(
					 	rm_c10.c10_moneda,
						rm_c11.c11_val_impto)
	ELSE
		LET rm_c11.c11_val_impto   = 0
	END IF
	INSERT INTO ordt011 VALUES(rm_c11.*)
END FOR 

IF status < 0 THEN
	LET done = 0
ELSE
	LET done = 1
END IF

RETURN done

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE resp 		CHAR(6)
DEFINE done		SMALLINT

LET int_flag = 0
INPUT BY NAME rm_c10.c10_moneda,       rm_c10.c10_tipo_orden,
	      rm_c10.c10_cod_depto,    rm_c10.c10_codprov,
	      rm_c10.c10_atencion,     rm_c10.c10_porc_impto, 
              vm_calc_iva,             rm_c10.c10_porc_descto,  
              rm_c10.c10_recargo,      rm_c10.c10_solicitado,
	      rm_c10.c10_ord_trabajo,  rm_c10.c10_tipo_pago,   
	      rm_c10.c10_referencia 
	      WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(c10_cod_depto,  c10_tipo_orden,
				     c10_codprov,    c10_atencion, 
				     c10_solicitado, c10_ord_trabajo,
				     c10_referencia)
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
	ON KEY(F2)
		IF INFIELD(c10_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_c10.c10_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_c10.c10_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
		      	END IF
		END IF

		IF INFIELD(c10_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
			     	RETURNING rm_g34.g34_cod_depto, 
					  rm_g34.g34_nombre
			IF rm_g34.g34_cod_depto IS NOT NULL THEN
			    	LET rm_c10.c10_cod_depto = rm_g34.g34_cod_depto
			    	DISPLAY BY NAME rm_c10.c10_cod_depto
			        DISPLAY  rm_g34.g34_nombre TO nom_departamento
			END IF
		END IF

		IF INFIELD(c10_codprov) THEN
			CALL fl_ayuda_proveedores()
				RETURNING rm_p01.p01_codprov, 
					  rm_p01.p01_nomprov
			IF rm_p01.p01_codprov IS NOT NULL THEN
				LET rm_c10.c10_codprov = rm_p01.p01_codprov
				DISPLAY BY NAME rm_c10.c10_codprov
				DISPLAY rm_p01.p01_nomprov TO nom_proveedor
			END IF
		END IF

		IF INFIELD(c10_tipo_orden) THEN
			CALL fl_ayuda_tipos_ordenes_compras()
				RETURNING rm_c01.c01_tipo_orden,
					  rm_c01.c01_nombre
			IF rm_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_c10.c10_tipo_orden =rm_c01.c01_tipo_orden
				DISPLAY BY NAME rm_c10.c10_tipo_orden
				DISPLAY rm_c01.c01_nombre TO nom_tipo_orden
			END IF 
		END IF

		IF INFIELD(c10_ord_trabajo) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc,'A')
				RETURNING rm_t23.t23_orden, 
					  rm_t23.t23_nom_cliente
			IF rm_t23.t23_orden IS NOT NULL THEN
				LET rm_c10.c10_ord_trabajo = rm_t23.t23_orden
				DISPLAY BY NAME rm_c10.c10_ord_trabajo
				DISPLAY rm_t23.t23_nom_cliente TO 
					nom_ord_trabajo
			END IF
		END IF

		LET int_flag = 0

	AFTER FIELD c10_porc_impto
		IF rm_c10.c10_porc_impto IS NULL THEN
			LET rm_c10.c10_porc_impto = rg_gen.g00_porc_impto 
			DISPLAY BY NAME rm_c10.c10_porc_impto
		END IF
		IF rm_c10.c10_porc_impto <> 0 
		AND rm_c10.c10_porc_impto <> rg_gen.g00_porc_impto 
		THEN
			CALL fgl_winmessage(vg_producto,
				'Este no es un porcentaje de impuesto valido.',
				'exclamation')
			NEXT FIELD c10_porc_impto
		END IF

	AFTER FIELD c10_moneda
		IF rm_c10.c10_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_c10.c10_moneda)
				RETURNING rm_g13.*
                	IF rm_g13.g13_moneda IS  NULL THEN
		    		CALL fgl_winmessage (vg_producto, 'La moneda no existe en la Compañía. ','exclamation')
				CLEAR nom_moneda
                        	NEXT FIELD c10_moneda
			END IF
			IF  rm_c10.c10_moneda <> rg_gen.g00_moneda_base AND
			    rm_c10.c10_moneda <> rg_gen.g00_moneda_alt
			    THEN
				CALL fgl_winmessage(vg_producto,'La Moneda ingresada no es la moneda base ni la moneda alterna','exclamation')
				CLEAR nom_moneda
				NEXT FIELD c10_moneda
			END IF
			IF rm_c10.c10_moneda = rg_gen.g00_moneda_alt THEN
				CALL fl_lee_factor_moneda(rm_c10.c10_moneda,
							rg_gen.g00_moneda_base)
					RETURNING rm_g14.*
				IF rm_g14.g14_tasa IS NULL THEN
					CALL fgl_winmessage(vg_producto,'No existe conversión entre la moneda base y la moneda alterna. Debe revisar la configuración. ','exclamation')
					EXIT PROGRAM
				END IF 
				LET rm_c10.c10_precision = rm_g13.g13_decimales
				LET rm_c10.c10_paridad   = rm_g14.g14_tasa
			END IF 
			DISPLAY rm_g13.g13_nombre TO nom_moneda
		ELSE
			CLEAR nom_moneda
                END IF

	BEFORE FIELD c10_tipo_orden
		IF vm_flag_mant = 'M' THEN
			IF rm_c10.c10_tipo_orden <> 'A' THEN
				NEXT FIELD NEXT
			END IF	
		END IF

	AFTER FIELD c10_tipo_orden
		IF rm_c10.c10_tipo_orden IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden)
				RETURNING rm_c01.*
			IF rm_c01.c01_tipo_orden IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el tipo de orden en la Compañía.','exclamation')
				NEXT FIELD c10_tipo_orden
			END IF

			LET vm_tipo = rm_c01.c01_bien_serv

			CASE rm_c01.c01_bien_serv
				WHEN 'B'
					DISPLAY 'BIENES'    TO tit_orden
				WHEN 'S'
					DISPLAY 'SERVICIOS' TO tit_orden
				WHEN 'T'
					DISPLAY 'TODOS'     TO tit_orden
			END CASE

			LET vm_flag_item = 'N'

			IF rm_c01.c01_modulo = 'RE' AND 
			   rm_c01.c01_ing_bodega = 'S' 
			   THEN
				LET vm_flag_item = 'S'
			END IF

			DISPLAY rm_c01.c01_nombre TO nom_tipo_orden
		ELSE	
			CLEAR tit_orden
			CLEAR nom_tipo_orden
			NEXT FIELD c10_tipo_orden
		END IF

	AFTER FIELD c10_cod_depto
		IF rm_c10.c10_cod_depto IS NOT NULL THEN
			CALL fl_lee_departamento(vg_codcia, 
						 rm_c10.c10_cod_depto)
				RETURNING rm_g34.*
			IF rm_g34.g34_cod_depto IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el departamento en la Compañía.','exclamation')
				NEXT FIELD c10_cod_depto
			END IF
			DISPLAY rm_g34.g34_nombre TO nom_departamento
		ELSE	
			CLEAR nom_departamento
		END IF

	AFTER FIELD c10_codprov
		IF rm_c10.c10_codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_c10.c10_codprov)
				RETURNING rm_p01.*
			IF rm_p01.p01_codprov IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el proveedor en la Compañía.','exclamation')
				NEXT FIELD c10_codprov
			END IF
			DISPLAY rm_p01.p01_nomprov TO nom_proveedor
		ELSE	
			CLEAR nom_proveedor
		END IF

	AFTER FIELD c10_ord_trabajo
		IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
			CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
						  rm_c10.c10_ord_trabajo)
				RETURNING rm_t23.*
			IF rm_t23.t23_orden IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la orden de trabajo en la Compañía.','exclamation')
				NEXT FIELD c10_ord_trabajo
			END IF
			IF rm_c01.c01_modulo IS NULL OR rm_c01.c01_modulo <> 'TA' THEN
				CALL fgl_winmessage(vg_producto,'La orden de trabajo solo es obligatorio cuando la orden sea por bienes y servicios.','exclamation')
				INITIALIZE rm_c10.c10_ord_trabajo TO NULL
				CLEAR c10_ord_trabajo
				CLEAR nom_ord_trabajo
				NEXT FIELD NEXT 
			END IF
			DISPLAY rm_t23.t23_nom_cliente TO nom_ord_trabajo
		ELSE	
			CLEAR nom_ord_trabajo
		END IF

	AFTER INPUT
		IF rm_c01.c01_modulo = 'TA' AND rm_c10.c10_ord_trabajo IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar una Orden de Trabajo para esta Orden de Compra','exclamation')
			NEXT FIELD c10_ord_trabajo
		END IF
			
END INPUT

END FUNCTION



FUNCTION control_lee_detalle()
DEFINE i,j,k,ind	SMALLINT
DEFINE resp		CHAR(6)

DEFINE paga_iva		LIKE ordt011.c11_paga_iva

LET vm_filas_pant  = fgl_scr_size('r_detalle')
LET rm_c10.c10_tot_compra = 0
LET i = 1
LET j = 1

IF vm_flag_mant <> 'M' THEN
	FOR k = 1 TO vm_filas_pant 
		INITIALIZE r_detalle[k].* TO NULL
		CLEAR r_detalle[k].*
	END FOR
	CALL set_count(i)
ELSE 
	CALL set_count(vm_ind_arr)
END IF

LET int_flag = 0
INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*

	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN 0
		END IF
	ON KEY(F2)
		IF INFIELD(c11_codigo) THEN
			IF vm_flag_item = 'S' THEN
			
				CALL fl_ayuda_maestro_items(vg_codcia, 'TODOS')
                     			RETURNING rm_r10.r10_codigo, 
						  rm_r10.r10_nombre

                     		IF rm_r10.r10_codigo IS NOT NULL THEN
					LET r_detalle[i].c11_codigo  = 
				    	    rm_r10.r10_codigo
					LET r_detalle[i].c11_descrip = 
				    	    rm_r10.r10_nombre
					DISPLAY r_detalle[i].c11_codigo TO
						r_detalle[j].c11_codigo
                        		DISPLAY r_detalle[i].c11_descrip TO
						r_detalle[j].c11_descrip
				END IF

			END IF
                END IF
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA

		IF i > vm_max_detalle THEN
			CALL fgl_winmessage(vg_producto,'Ha llegado al límite del detalle de la orden de compra no puede ingresar más elementos al detalle','exclamation')
			NEXT FIELD c11_cant_ped
		END IF

		IF r_detalle[i].c11_cant_ped IS NOT NULL AND
		   r_detalle[i].c11_precio   IS NOT NULL 
		   THEN
			LET vm_subtotal_2 = r_detalle[i].c11_cant_ped *
					    r_detalle[i].c11_precio
			DISPLAY BY NAME vm_subtotal_2
		END IF
		IF vm_tipo <> 'T' THEN
			IF i <> 1 THEN
				LET r_detalle[i].c11_tipo = vm_tipo
			END IF
		ELSE
			IF r_detalle[i].c11_tipo IS NULL THEN
				LET r_detalle[i].c11_tipo = 'S'
			END IF
		END IF
		IF r_detalle[i].paga_iva IS NULL THEN
			LET r_detalle[i].paga_iva = 'S'
			DISPLAY r_detalle[i].paga_iva TO r_detalle[j].c11_paga_iva
		END IF

	BEFORE DELETE	
		INITIALIZE r_detalle[i].* TO NULL

	AFTER DELETE	
		--INITIALIZE r_detalle[i].* TO NULL
		LET k = i - j + 1
		CALL calcula_totales(arr_count(),k)

	BEFORE FIELD c11_tipo	
		IF vm_tipo <> 'T' THEN
			--IF i <> 1 THEN
				LET r_detalle[i].c11_tipo = vm_tipo
			--END IF
			NEXT FIELD NEXT
		ELSE
			IF r_detalle[i].c11_tipo IS NULL THEN
				LET r_detalle[i].c11_tipo = 'S'
			END IF
		END IF
	
	BEFORE FIELD c11_paga_iva
		IF vm_calc_iva = 'S' THEN
			NEXT FIELD c11_cant_ped
		END IF
		LET paga_iva = r_detalle[i].paga_iva

	AFTER FIELD c11_paga_iva
		IF r_detalle[i].paga_iva <> paga_iva THEN
			LET k = i - j + 1
			CALL calcula_totales(arr_count(), k)
		END IF
		NEXT FIELD c11_cant_ped

{
	AFTER ROW 
		IF r_detalle[i].c11_codigo IS NULL THEN
			NEXT FIELD c11_codigo		
		END IF
		IF r_detalle[i].c11_descrip IS NULL THEN
			NEXT FIELD c11_descrip		
		END IF
}

	AFTER FIELD c11_cant_ped
		IF r_detalle[i].c11_cant_ped IS NOT NULL THEN
			IF r_detalle[i].c11_descuento IS NOT NULL AND
			   r_detalle[i].c11_precio    IS NOT NULL 
		   	   THEN
				LET k = i - j + 1
				CALL calcula_totales(arr_count(),k)
			END IF
		END IF	
		IF r_detalle[i].c11_cant_ped IS NULL AND
		   r_detalle[i].c11_precio   IS NOT NULL 
		   THEN
			NEXT FIELD c11_cant_ped
		END IF
			
	BEFORE FIELD c11_codigo
		IF vm_tipo = 'S' THEN
			LET r_detalle[i].c11_cant_ped = 1
			LET r_detalle[i].c11_codigo = 'SERVICIO'||i
			DISPLAY r_detalle[i].c11_codigo TO 
				r_detalle[j].c11_codigo
			DISPLAY r_detalle[i].c11_cant_ped TO 
				r_detalle[j].c11_cant_ped
		END IF

	AFTER FIELD c11_codigo
		IF vm_tipo = 'S' THEN
			LET r_detalle[i].c11_codigo = 'SERVICIO'||i
			DISPLAY r_detalle[i].c11_codigo TO 
				r_detalle[j].c11_codigo
		END IF

		IF vm_flag_item = 'S' AND r_detalle[i].c11_codigo IS NOT NULL
		   THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].c11_codigo)
				RETURNING rm_r10.*
			IF rm_r10.r10_codigo IS NULL THEN
				CALL fgl_winquestion(vg_producto,'El código no existe. ¿ Desea crearlo ?','No','Yes|No','question',1)	
					RETURNING resp
				IF resp = 'Yes' THEN
					CALL control_crear_item()
					NEXT FIELD c11_codigo
				ELSE
					NEXT FIELD c11_codigo
				END IF
			END IF
			LET r_detalle[i].c11_descrip = rm_r10.r10_nombre
			DISPLAY r_detalle[i].c11_descrip TO 
				r_detalle[j].c11_descrip
		END IF 
		IF r_detalle[i].c11_descrip IS NOT NULL AND 
		   r_detalle[i].c11_codigo  IS NULL
		   THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar el código de la descripción ingresada.','exclamation')
			NEXT FIELD c11_codigo
		END IF  
		------ PARA LA VALIDACION DE CODIGOS REPETIDOS ------
			FOR k = 1 TO arr_count()
				IF  r_detalle[i].c11_codigo =
				    r_detalle[k].c11_codigo AND 
				    i <> k
				    THEN
					CALL fgl_winmessage(vg_producto,'No puede ingresar códigos repetidos','exclamation')
					NEXT FIELD c11_codigo
               			END IF
			END FOR
		-------------------------------------------------------
		IF r_detalle[i].c11_codigo IS NULL AND
		   r_detalle[i].c11_descrip IS NOT NULL 
		   THEN
			NEXT FIELD c11_codigo
		END IF
		IF r_detalle[i].c11_descrip IS NULL AND 
		   r_detalle[i].c11_codigo  IS NOT NULL
		   THEN
			NEXT FIELD c11_descrip
		END IF

	BEFORE FIELD c11_descrip
		IF vm_flag_item = 'S' THEN
			NEXT FIELD NEXT
		END IF

	AFTER FIELD c11_descrip
		IF r_detalle[i].c11_descrip IS NULL AND 
		   r_detalle[i].c11_codigo  IS NOT NULL
		   THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar la descripción del código ingresado.','exclamation')
			NEXT FIELD c11_descrip
		END IF  

	BEFORE FIELD c11_descuento
		LET r_detalle[i].c11_descuento = rm_c10.c10_porc_descto
		DISPLAY r_detalle[i].c11_descuento TO 
			r_detalle[j].c11_descuento

	AFTER FIELD c11_descuento
		IF r_detalle[i].c11_cant_ped IS NOT NULL AND
		   r_detalle[i].c11_precio   IS NOT NULL 
		   THEN
			LET k = i - j + 1
			CALL calcula_totales(arr_count(),k)
		END IF	

	AFTER FIELD c11_precio
		IF r_detalle[i].c11_descuento IS NOT NULL AND
		   r_detalle[i].c11_cant_ped  IS NOT NULL 
		   THEN
			LET k = i - j + 1
			CALL calcula_totales(arr_count(),k)
		END IF	
		IF  r_detalle[k].c11_precio   IS NULL AND 
		    r_detalle[i].c11_cant_ped IS NOT NULL 
		    THEN
			NEXT FIELD c11_precio
		END IF

	AFTER INPUT
		IF rm_c10.c10_tot_compra = 0 THEN
			NEXT FIELD c11_cant_ped
		END IF
		LET ind        = arr_count() 
		LET vm_ind_arr = ind 

END INPUT

RETURN ind

END FUNCTION



FUNCTION control_crear_item()
DEFINE command 		VARCHAR(100) 

LET command = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	           vg_separador, 'fuentes', vg_separador, '; 
		   fglrun repp108 ', vg_base, ' ','RE', ' ',vg_codcia
	      	
RUN command

END FUNCTION



FUNCTION calcula_totales(indice, indice_2)
DEFINE indice,k		SMALLINT
DEFINE indice_2,y	SMALLINT
DEFINE v_impto		LIKE ordt010.c10_tot_impto

LET vm_filas_pant  = fgl_scr_size('r_detalle')
LET rm_c10.c10_tot_repto   = 0	
LET rm_c10.c10_tot_mano    = 0	
LET rm_c10.c10_tot_dscto   = 0	
LET rm_c10.c10_tot_impto   = 0	
LET rm_c10.c10_tot_compra  = 0	
LET vm_subtotal		   = 0	
LET vm_subtotal_2	   = 0	
LET v_impto		   = 0	

FOR k = 1 TO indice
	IF r_detalle[k].c11_cant_ped  IS NULL OR 
	   r_detalle[k].c11_descuento IS NULL OR 
	   r_detalle[k].c11_precio    IS NULL 
	   THEN
		CONTINUE FOR
	END IF
	---- SUBTOTAL ----
	LET vm_subtotal_2 = r_detalle[k].c11_precio * r_detalle[k].c11_cant_ped

	LET vm_subtotal   = vm_subtotal + vm_subtotal_2
	----------------------------

	IF r_detalle[k].c11_tipo = 'B' THEN
		LET rm_c10.c10_tot_repto = rm_c10.c10_tot_repto + vm_subtotal_2
	END IF
	IF r_detalle[k].c11_tipo = 'S' THEN
		LET rm_c10.c10_tot_mano  = rm_c10.c10_tot_mano  + vm_subtotal_2 
	END IF

	---- DESCUENTO - TOT_DSCTO ----
	LET r_detalle_1[k].c11_val_descto = vm_subtotal_2 * 
					    r_detalle[k].c11_descuento / 100  

	LET r_detalle_1[k].c11_val_descto = 
		fl_retorna_precision_valor(rm_c10.c10_moneda,
		                           r_detalle_1[k].c11_val_descto)

	LET rm_c10.c10_tot_dscto = rm_c10.c10_tot_dscto + 
				   r_detalle_1[k].c11_val_descto
	--------------------------------

	---- IMPUESTO - TOT_IMPTO ------
	IF vm_calc_iva = 'D' AND r_detalle[k].paga_iva = 'S' THEN
		LET v_impto =(vm_subtotal_2 - r_detalle_1[k].c11_val_descto) * 
			      rm_c10.c10_porc_impto / 100
	
		LET v_impto = fl_retorna_precision_valor(rm_c10.c10_moneda, 
  				v_impto)

		LET rm_c10.c10_tot_impto = rm_c10.c10_tot_impto + v_impto
	END IF
	--------------------------------

END FOR

IF vm_calc_iva = 'S' THEN
	LET rm_c10.c10_tot_impto = (rm_c10.c10_tot_repto + rm_c10.c10_tot_mano -
				    rm_c10.c10_tot_dscto) * 
				    rm_c10.c10_porc_impto / 100
END IF
LET rm_c10.c10_tot_impto = fl_retorna_precision_valor(rm_c10.c10_moneda,
			   rm_c10.c10_tot_impto)

LET y = indice_2

IF indice <= vm_filas_pant THEN
	LET vm_filas_pant = indice
END IF

FOR k = 1 TO vm_filas_pant
	DISPLAY r_detalle[y].c11_tipo TO r_detalle[k].c11_tipo
	IF y = indice THEN
		EXIT FOR
	END IF 
	LET y = y + 1
END FOR
	
LET rm_c10.c10_tot_compra = vm_subtotal - rm_c10.c10_tot_dscto +
			    rm_c10.c10_tot_impto	

DISPLAY BY NAME vm_subtotal,          rm_c10.c10_tot_dscto, 
		rm_c10.c10_tot_impto, rm_c10.c10_tot_compra

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(600)
DEFINE expr_sql_2	VARCHAR(600)
DEFINE query		VARCHAR(600)
DEFINE r_c10		RECORD LIKE ordt010.* 	-- CABECERA PROFORMA

INITIALIZE expr_sql_2 TO NULL
CLEAR FORM
CALL control_display_botones()

LET vm_flag_mant = 'C'

LET INT_FLAG = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON c10_numero_oc,   c10_estado,    c10_moneda,  c10_fecing,	
	             c10_tipo_orden,  c10_cod_depto, c10_codprov, c10_atencion, 
		     c10_porc_descto, c10_recargo,   c10_solicitado,
	             c10_ord_trabajo, c10_tipo_pago, c10_referencia 
	ON KEY(F2)
		
		IF INFIELD(c10_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc,
						     0, 0, 'A','00','T')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				LET rm_c10.c10_numero_oc = r_c10.c10_numero_oc
				DISPLAY BY NAME rm_c10.c10_numero_oc
			END IF
		END IF

		IF INFIELD(c10_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_c10.c10_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_c10.c10_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
		      	END IF
		END IF

		IF INFIELD(c10_cod_depto) THEN
			CALL fl_ayuda_departamentos(vg_codcia)
			     	RETURNING rm_g34.g34_cod_depto, 
					  rm_g34.g34_nombre
			IF rm_g34.g34_cod_depto IS NOT NULL THEN
			    	LET rm_c10.c10_cod_depto = rm_g34.g34_cod_depto
			    	DISPLAY BY NAME rm_c10.c10_cod_depto
			        DISPLAY  rm_g34.g34_nombre TO nom_departamento
			END IF
		END IF

		IF INFIELD(c10_codprov) THEN
			CALL fl_ayuda_proveedores()
				RETURNING rm_p01.p01_codprov, 
					  rm_p01.p01_nomprov
			IF rm_p01.p01_codprov IS NOT NULL THEN
				LET rm_c10.c10_codprov = rm_p01.p01_codprov
				DISPLAY BY NAME rm_c10.c10_codprov
				DISPLAY rm_p01.p01_nomprov
			END IF
		END IF

		IF INFIELD(c10_tipo_orden) THEN
			CALL fl_ayuda_tipos_ordenes_compras()
				RETURNING rm_c01.c01_tipo_orden,
					  rm_c01.c01_nombre
			IF rm_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_c10.c10_tipo_orden =rm_c01.c01_tipo_orden
				DISPLAY BY NAME rm_c10.c10_tipo_orden
				DISPLAY rm_c01.c01_nombre TO nom_tipo_orden
			END IF 
		END IF

		IF INFIELD(c10_ord_trabajo) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc,'A')
				RETURNING rm_t23.t23_orden, 
					  rm_t23.t23_nom_cliente
			IF rm_t23.t23_orden IS NOT NULL THEN
				LET rm_c10.c10_ord_trabajo = rm_t23.t23_orden
				DISPLAY BY NAME rm_c10.c10_ord_trabajo
				DISPLAY rm_t23.t23_nom_cliente TO 
					nom_ord_trabajo
			END IF
		END IF

		LET int_flag = 0

	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		CALL control_display_botones()
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'c10_numero_oc = ',vg_num_ord 
END IF

IF expr_sql_2 IS NOT NULL THEN
	LET expr_sql = expr_sql || ' AND ' || expr_sql_2
END IF

LET query = 'SELECT *, ROWID FROM ordt010 
		WHERE c10_compania  = ', vg_codcia,
		' AND c10_localidad = ', vg_codloc,
		' AND ', expr_sql CLIPPED,
		' ORDER BY 3, 4' 

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_c10.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 

LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	CALL control_display_botones()
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_c10.* FROM ordt010 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET vm_subtotal = rm_c10.c10_tot_repto + rm_c10.c10_tot_mano

	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_c10.c10_numero_oc, rm_c10.c10_estado,  rm_c10.c10_moneda,
		rm_c10.c10_porc_impto,rm_c10.c10_fecing,  rm_c10.c10_tipo_orden,
 		rm_c10.c10_cod_depto, rm_c10.c10_porc_descto,rm_c10.c10_codprov,
		rm_c10.c10_recargo,    rm_c10.c10_atencion,  rm_c10.c10_usuario,
		rm_c10.c10_ord_trabajo,rm_c10.c10_tot_dscto, vm_subtotal, 
		rm_c10.c10_tipo_pago,  rm_c10.c10_referencia, 
		rm_c10.c10_solicitado, rm_c10.c10_tot_compra, 
		rm_c10.c10_tot_impto    

CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(400)

DEFINE cont 		SMALLINT
DEFINE v_impto		LIKE ordt011.c11_val_impto
DEFINE val_impto	LIKE ordt011.c11_val_impto

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle.* TO NULL
	INITIALIZE r_detalle_1.* TO NULL
	--CLEAR r_detalle[i].*
END FOR

LET query = 'SELECT c11_tipo, c11_cant_ped,  c11_codigo, c11_descrip,',
		' c11_descuento, c11_precio, c11_paga_iva, c11_val_impto', 
		' FROM ordt011 ',
            	'WHERE c11_compania  = ', vg_codcia, 
	    	'  AND c11_localidad = ', vg_codloc,
            	'  AND c11_numero_oc = ', rm_c10.c10_numero_oc

PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2

LET val_impto = 0
LET i = 1
FOREACH q_cons2 INTO r_detalle[i].*, v_impto
	LET val_impto = val_impto + v_impto
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
	CALL control_display_botones()
	RETURN
END IF

SELECT COUNT(c11_paga_iva) INTO cont FROM ordt011
	WHERE c11_compania  = vg_codcia 
	  AND c11_localidad = vg_codloc
          AND c11_numero_oc = rm_c10.c10_numero_oc
	  AND c11_paga_iva  = 'N'

IF cont = 0 AND val_impto = 0 THEN
	LET vm_calc_iva = 'S' 
ELSE
	LET vm_calc_iva = 'D'
END IF
DISPLAY BY NAME vm_calc_iva

LET vm_ind_arr  = i
LET vm_curr_arr = 0
LET vm_ini_arr  = 0

CALL control_mostrar_sig_det()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()

CASE rm_c10.c10_estado
	WHEN 'A'
		DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'P'
		DISPLAY 'APROBADO' TO tit_estado
	WHEN 'C'
		DISPLAY 'CERRADO' TO tit_estado
END CASE

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden)
	RETURNING rm_c01.*
LET vm_tipo = rm_c01.c01_bien_serv

CASE rm_c01.c01_bien_serv
	WHEN 'B'
		DISPLAY 'BIENES'    TO tit_orden
	WHEN 'S'
		DISPLAY 'SERVICIOS' TO tit_orden
	WHEN 'T'
		DISPLAY 'TODOS'     TO tit_orden
END CASE

CALL fl_lee_moneda(rm_c10.c10_moneda)
	RETURNING rm_g13.*
	DISPLAY rm_g13.g13_nombre TO nom_moneda
CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden)
	RETURNING rm_c01.*
	DISPLAY rm_c01.c01_nombre TO nom_tipo_orden
CALL fl_lee_departamento(vg_codcia, rm_c10.c10_cod_depto)
	RETURNING rm_g34.*
	DISPLAY rm_g34.g34_nombre TO nom_departamento
CALL fl_lee_proveedor(rm_c10.c10_codprov)
	RETURNING rm_p01.*
	DISPLAY rm_p01.p01_nomprov TO nom_proveedor
CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_c10.c10_ord_trabajo)
	RETURNING rm_t23.*
	DISPLAY rm_t23.t23_nom_cliente TO nom_ord_trabajo

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

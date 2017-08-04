------------------------------------------------------------------------------
-- Titulo           : ordp200.4gl - Mantenimineto de Ordenes de Compra
-- Elaboracion      : 14-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ordp200 base modulo compania localidad [num_oc]
--	 En modo ingreso: fglrun ordp200 base mod cia loc I tipo numprof vend
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT   	-- CANTIDAD DE FILAS LEIDAS

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
	subtotal		DECIMAL(12,2),
	paga_iva		LIKE ordt011.c11_paga_iva
	END RECORD
DEFINE vm_size_arr		INTEGER
----------------------------------------------------------

	---- ARREGLO PARA LA FORMA DE PAGO ----
DEFINE r_detalle_2 ARRAY[250] OF RECORD
	c12_dividendo		LIKE ordt012.c12_dividendo,
	c12_fecha_vcto		LIKE ordt012.c12_fecha_vcto,
	c12_valor_cap		LIKE ordt012.c12_valor_cap,
	c12_valor_int		LIKE ordt012.c12_valor_int,
	subtotal		LIKE ordt012.c12_valor_cap
	END RECORD
DEFINE vm_size_arr2		INTEGER
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
DEFINE valor_fact		DECIMAL(12,2)

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
DEFINE vm_activo_mod		LIKE ordt001.c01_modulo
DEFINE vm_flag_llam		CHAR(1)
DEFINE vm_tipo_oc		LIKE ordt010.c10_tipo_orden
DEFINE vm_numprof		LIKE rept021.r21_numprof
DEFINE vm_vendedor		LIKE rept001.r01_codigo



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp200.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 8
THEN     -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
IF num_args() = 5 THEN
	LET vg_num_ord = arg_val(5)
END IF
LET vm_flag_llam = NULL
IF num_args() = 8 THEN
	LET vm_flag_llam = arg_val(5)
	LET vm_tipo_oc   = arg_val(6)
	LET vm_numprof   = arg_val(7)
	LET vm_vendedor  = arg_val(8)
END IF
LET vg_proceso = 'ordp200'

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
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_c10		RECORD LIKE ordt010.*

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
LET vm_max_rows     = 1000
LET vm_max_detalle  = 250
LET vm_activo_mod   = 'AF'

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
OPEN WINDOW w_200 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_200 FROM '../forms/ordf200_1'
ELSE
	OPEN FORM f_200 FROM '../forms/ordf200_1c'
END IF
DISPLAY FORM f_200
CALL control_DISPLAY_botones()

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
LET vm_num_rows = 0
LET vm_row_current = 0

INITIALIZE rm_c10.*, rm_c11.* TO NULL

CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Ubicarse Detalle'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
                HIDE OPTION 'Ver Recepción'
                HIDE OPTION 'Ver Anulación'
                HIDE OPTION 'Imprimir'
                HIDE OPTION 'Eliminar'
		IF num_args() = 5 THEN
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
                	HIDE OPTION 'Eliminar'
			CALL control_consulta()
			SHOW OPTION 'Ubicarse Detalle'
			SHOW OPTION 'Imprimir'
			IF rm_c10.c10_estado <> 'A' THEN
				CALL control_cargar_recepciones(1)
				IF vm_num_recep <> 0 THEN
					SHOW OPTION 'Ver Recepción'
				ELSE
                			SHOW OPTION 'Ver Anulación'
				END IF
			ELSE
				CALL control_cargar_recepciones(2)
				IF vm_num_recep <> 0 THEN
        	       			SHOW OPTION 'Ver Anulación'
				END IF
			END IF
			IF rm_c10.c10_tipo_pago = 'R' THEN
				SHOW OPTION 'Forma de Pago'
			END IF
                	IF vm_num_rows = 1 AND (vm_ind_arr - vm_curr_arr) > 0
			   THEN
                       	 	SHOW OPTION 'Avanzar Detalle'
                	END IF
		END IF 
		IF vm_flag_llam = 'I' THEN
			CALL lee_oc_proforma() RETURNING r_c10.*
			IF r_c10.c10_compania IS NOT NULL THEN
				LET vg_num_ord = r_c10.c10_numero_oc
               	CALL control_consulta()
				IF r_c10.c10_estado = 'C' THEN
					CALL control_ver_detalle()
					EXIT MENU
				END IF
				CALL control_modificacion()
				EXIT MENU
			END IF
			CALL control_ingreso()
			EXIT MENU
		END IF

	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
				CALL control_ingreso()
                HIDE OPTION 'Ver Recepción'
               	HIDE OPTION 'Ver Anulación'
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ubicarse Detalle'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Eliminar'
			IF rm_c10.c10_tipo_pago = 'R' THEN
				SHOW OPTION 'Forma de Pago'
			ELSE 
				HIDE OPTION 'Forma de Pago'
			END IF
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
			IF rm_c10.c10_tipo_pago = 'R' THEN
				SHOW OPTION 'Forma de Pago'
			ELSE 
				HIDE OPTION 'Forma de Pago'
			END IF
			IF rm_c10.c10_estado = 'A' THEN
                		SHOW OPTION 'Eliminar'
			END IF
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	

        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
                CALL control_consulta()
		IF num_args() = 5 THEN
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_num_rows > 0 THEN
                	HIDE OPTION 'Eliminar'
			IF rm_c10.c10_tipo_pago = 'R' THEN
				SHOW OPTION 'Forma de Pago'
			ELSE
				HIDE OPTION 'Forma de Pago'
			END IF
			IF rm_c10.c10_estado <> 'A' THEN
				CALL control_cargar_recepciones(1)
				IF vm_num_recep <> 0 THEN
					SHOW OPTION 'Ver Recepción'
               				HIDE OPTION 'Ver Anulación'
				ELSE
					HIDE OPTION 'Ver Recepción'
               				SHOW OPTION 'Ver Anulación'
				END IF
			ELSE
                		SHOW OPTION 'Eliminar'
                        	HIDE OPTION 'Ver Recepción'
               			HIDE OPTION 'Ver Anulación'
				CALL control_cargar_recepciones(2)
				IF vm_num_recep <> 0 THEN
        	       			SHOW OPTION 'Ver Anulación'
				END IF
			END IF
		END IF
                IF vm_num_rows <= 1 THEN
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                        SHOW OPTION 'Modificar'
			SHOW OPTION 'Ubicarse Detalle'
			SHOW OPTION 'Imprimir'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Forma de Pago'
                        	HIDE OPTION 'Modificar'
				HIDE OPTION 'Ubicarse Detalle'
				HIDE OPTION 'Imprimir'
                        	HIDE OPTION 'Ver Recepción'
                        END IF
                ELSE
                        SHOW OPTION 'Modificar'
			SHOW OPTION 'Ubicarse Detalle'
			SHOW OPTION 'Imprimir'
                        SHOW OPTION 'Avanzar'
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('F') 'Forma de Pago' 'Para ordenes de compra a crédito.'
		IF vm_num_rows > 0 THEN
			CALL control_forma_pago()
			IF num_args() = 4 THEN
				CALL lee_muestra_registro(vm_rows[vm_row_current])
			END IF
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
		
	COMMAND KEY('P') 'Ver Recepción' 'Ver recepción de la orden de compra.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_recepcion_anulacion(1)
		END IF	
		
	COMMAND KEY('Z') 'Ver Anulación' 'Ver anulación de la orden de compra.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_recepcion_anulacion(2)
		END IF	
		
        COMMAND KEY('E') 'Eliminar'      'Elimina la Orden de Compra.'
		IF vm_num_rows > 0 AND rm_c10.c10_estado = 'A' THEN
			CALL control_elimina_oc()
			IF rm_c10.c10_estado = 'E' THEN
                        	HIDE OPTION 'Eliminar'
			END IF
		END IF

        COMMAND KEY('K') 'Imprimir'      'Imprime la Orden de Compra.'
		IF vm_num_rows > 0 THEN
			CALL imprimir_orden()
		END IF

        COMMAND KEY('X') 'Ubicarse Detalle' 'Se ubica Detalle Orden de Compra.'
		CALL control_ver_detalle()
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
			SHOW OPTION 'Ubicarse Detalle'
			SHOW OPTION 'Imprimir'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ubicarse Detalle'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                        SHOW OPTION 'Avanzar Detalle'
                END IF
		IF rm_c10.c10_tipo_pago = 'R' THEN
			SHOW OPTION 'Forma de Pago'
		ELSE 
			HIDE OPTION 'Forma de Pago'
		END IF
		IF rm_c10.c10_estado <> 'A' THEN
                        HIDE OPTION 'Eliminar'
			CALL control_cargar_recepciones(1)
			IF vm_num_recep <> 0 THEN
				SHOW OPTION 'Ver Recepción'
               			HIDE OPTION 'Ver Anulación'
			ELSE
				HIDE OPTION 'Ver Recepción'
               			SHOW OPTION 'Ver Anulación'
			END IF
		ELSE
                        SHOW OPTION 'Eliminar'
                       	HIDE OPTION 'Ver Recepción'
               		HIDE OPTION 'Ver Anulación'
			CALL control_cargar_recepciones(2)
			IF vm_num_recep <> 0 THEN
               			SHOW OPTION 'Ver Anulación'
			END IF
		END IF

	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ubicarse Detalle'
			SHOW OPTION 'Imprimir'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Ubicarse Detalle'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                        SHOW OPTION 'Avanzar Detalle'
                END IF
		HIDE OPTION 'Forma de Pago'
		IF rm_c10.c10_tipo_pago = 'R' THEN
			SHOW OPTION 'Forma de Pago'
		ELSE
			HIDE OPTION 'Forma de Pago'
		END IF
		IF rm_c10.c10_estado <> 'A' THEN
                        HIDE OPTION 'Eliminar'
			CALL control_cargar_recepciones(1)
			IF vm_num_recep <> 0 THEN
				SHOW OPTION 'Ver Recepción'
               			HIDE OPTION 'Ver Anulación'
			ELSE
				HIDE OPTION 'Ver Recepción'
               			SHOW OPTION 'Ver Anulación'
			END IF
		ELSE
                        SHOW OPTION 'Eliminar'
                       	HIDE OPTION 'Ver Recepción'
               		HIDE OPTION 'Ver Anulación'
			CALL control_cargar_recepciones(2)
			IF vm_num_recep <> 0 THEN
               			SHOW OPTION 'Ver Anulación'
			END IF
		END IF

	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU

END MENU

END FUNCTION


                                                                                
FUNCTION control_cargar_recepciones(flag)
DEFINE flag		SMALLINT
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE estado		LIKE ordt013.c13_estado
DEFINE i		SMALLINT

CASE flag
	WHEN 1
		LET estado = 'A'
	WHEN 2
		LET estado = 'E'
END CASE
DECLARE q_ordt013 CURSOR FOR
        SELECT * FROM ordt013
               WHERE c13_compania  = vg_codcia
                 AND c13_localidad = vg_codloc
                 AND c13_numero_oc = rm_c10.c10_numero_oc
		 AND c13_estado    = estado
                                                                                
LET i = 1
FOREACH q_ordt013 INTO r_c13.* 
        LET i = i + 1
        IF i > 100 THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_recep = i - 1
                                                                                
END FUNCTION



FUNCTION control_ver_recepcion_anulacion(flag)
DEFINE flag		SMALLINT
DEFINE param		VARCHAR(100)
DEFINE prog		VARCHAR(10)

CASE flag
	WHEN 1
		LET prog = 'ordp202'
	WHEN 2
		LET prog = 'ordp204'
END CASE
LET param = vg_codloc, ' ', rm_c10.c10_numero_oc
CALL ejecuta_comando('COMPRAS', vg_modulo, prog, param)

END FUNCTION



FUNCTION control_mostrar_sig_det()
DEFINE i                SMALLINT
DEFINE filas_pant       SMALLINT
DEFINE filas_mostrar    SMALLINT
                                                                                
IF (vm_ind_arr - vm_curr_arr) <= 0 THEN
        RETURN
END IF
                                                                                
CALL retorna_tam_arr()
LET filas_pant = vm_size_arr
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
LET i = vm_ini_arr
IF vm_curr_arr <= filas_pant THEN
	LET i = 0
END IF
CALL muestra_contadores_det(i, vm_num_detalles)

END FUNCTION



FUNCTION control_mostrar_ant_det()
DEFINE i                SMALLINT
DEFINE filas_pant       SMALLINT
                                                                                
IF vm_ini_arr <= 1 THEN
        RETURN
END IF
                                                                                
CALL retorna_tam_arr()
LET filas_pant = vm_size_arr
LET vm_ini_arr = vm_ini_arr - filas_pant
FOR i = 1 TO filas_pant
        CLEAR r_detalle[i].*
END FOR
                                                                                
LET vm_curr_arr = vm_ini_arr - 1
FOR i = 1 TO filas_pant
        LET vm_curr_arr = vm_curr_arr + 1
        DISPLAY r_detalle[vm_curr_arr].* TO r_detalle[i].*
END FOR
LET i = vm_ini_arr
IF vm_curr_arr <= filas_pant THEN
	LET i = 0
END IF
CALL muestra_contadores_det(i, vm_num_detalles)
                                                                                
END FUNCTION



FUNCTION control_forma_pago()
DEFINE i 	SMALLINT

IF rm_c10.c10_tipo_pago = 'C' THEN

	--CALL fgl_winmessage(vg_producto,'La forma de pago solo para ordenes de compra a crédito.','exclamation')
	CALL fl_mostrar_mensaje('La forma de pago solo para ordenes de compra a crédito.','exclamation')
	RETURN

END IF

OPEN WINDOW w_200_2 AT 6, 8 WITH 16 ROWS, 71 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
IF vg_gui = 1 THEN
	OPEN FORM f_200_2 FROM '../forms/ordf200_2'
ELSE
	OPEN FORM f_200_2 FROM '../forms/ordf200_2c'
END IF
DISPLAY FORM f_200_2

CALL control_DISPLAY_botones_2()

IF num_args() = 5 THEN
	LET i = control_cargar_forma_pago_oc()
	CALL control_DISPLAY_ordt012(i)
	CLOSE WINDOW w_200_2
	RETURN
END IF

BEGIN WORK

WHENEVER ERROR CONTINUE
IF vm_flag_mant <> 'M' THEN

	DECLARE q_ordt010_2 CURSOR FOR 
		SELECT * FROM ordt010 
			WHERE c10_compania  = vg_codcia
			AND   c10_localidad = vg_codloc
			AND   c10_numero_oc = rm_c10.c10_numero_oc
		FOR UPDATE

	OPEN q_ordt010_2
	FETCH q_ordt010_2 

	IF status < 0 THEN
		ROLLBACK WORK
		--CALL fgl_winmessage(vg_producto,'La orden de compra esta siendo modificada por otro usuario.','exclamation')
		CALL fl_mostrar_mensaje('La orden de compra esta siendo modificada por otro usuario.','exclamation')
		WHENEVER ERROR STOP
		CLOSE WINDOW w_200_2
		RETURN
	END IF

END IF

LET tot_compra         = rm_c10.c10_tot_compra

DISPLAY BY NAME tot_compra, rm_c10.c10_interes

IF rm_c10.c10_estado <> 'A' AND vm_flag_llam IS NULL THEN
	ROLLBACK WORK
	LET i = control_cargar_forma_pago_oc()
	CALL control_DISPLAY_ordt012(i)
	WHENEVER ERROR STOP
	CLOSE WINDOW w_200_2
	RETURN
END IF

LET i = control_cargar_forma_pago_oc()

IF i = 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
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
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP

CALL control_cargar_detalle_forma_pago()

IF rm_c10.c10_interes > 0 THEN
	CALL control_DISPLAY_ordt012(pagos)
ELSE
	CALL control_lee_detalle_forma_pago()
END IF

CALL control_insert_ordt012()

UPDATE ordt010 
	SET c10_interes = rm_c10.c10_interes
		WHERE c10_compania  = vg_codcia
		  AND c10_localidad = vg_codloc
		  AND c10_numero_oc = rm_c10.c10_numero_oc

COMMIT WORK
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



FUNCTION control_DISPLAY_ordt012(i)
DEFINE i,filas 	SMALLINT

CALL retorna_tam_arr2()
LET filas = vm_size_arr2

CALL set_count(i)

DISPLAY ARRAY r_detalle_2 TO r_detalle_2.* 
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT','')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel('F3','')
		--#CALL dialog.keysetlabel('F4','')
		--#IF i <= filas THEN
			--#CALL fgl_keysetlabel('Avanzar','')
			--#CALL fgl_keysetlabel('Retroceder','')
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY


END DISPLAY

END FUNCTION



FUNCTION control_cargar_forma_pago_oc()
DEFINE r_c12		RECORD LIKE ordt012.*
DEFINE i,k,filas		SMALLINT

CALL retorna_tam_arr2()
FOR k = 1 TO vm_size_arr2
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
		--CALL fgl_winmessage(vg_producto,'Ha superado el maximo número de elementos del detalle no puede continuar cargando el detalle de la forma de pago.','exclamation')
		CALL fl_mostrar_mensaje('Ha superado el maximo número de elementos del detalle no puede continuar cargando el detalle de la forma de pago.','exclamation')
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

CALL retorna_tam_arr2()
LET filas = vm_size_arr2

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

	CALL retorna_tam_arr2()
	LET vm_filas_pant = vm_size_arr2

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
	{--
		IF r_detalle_2[1].c12_dividendo IS NOT NULL THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	--}

		--CALL fgl_winmessage(vg_producto,'Debe especificar la forma de pago de esta orden de compra ','exclamation')
		CALL fl_mostrar_mensaje('Debe especificar la forma de pago de esta orden de compra.','exclamation')
		CONTINUE INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
		
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD fecha_pago
		IF fecha_pago < TODAY THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar una fecha mayor o igual a la de hoy.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar una fecha mayor o igual a la de hoy.','exclamation')
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
		IF int_flag THEN
			EXIT INPUT
		END IF
		IF pagos IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar el número de pagos para generar el detalle.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar el número de pagos para generar el detalle.','exclamation')
			NEXT FIELD pagos
		END IF
			
		IF fecha_pago IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar la fecha del primer pago de la orden de compra.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar la fecha del primer pago de la orden de compra.','exclamation')
			NEXT FIELD fecha_pago
		END IF

		IF dias_pagos IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar el número de días entre pagos para generar el detalle.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar el número de días entre pagos para generar el detalle.','exclamation')
			NEXT FIELD dias_pagos
		END IF
			
END INPUT

END FUNCTION



FUNCTION control_lee_detalle_forma_pago()
DEFINE resp 		CHAR(6)
DEFINE i,j,k		SMALLINT
DEFINE fecha_aux 	LIKE rept026.r26_fec_vcto
DEFINE salirinp		SMALLINT


OPTIONS
	INSERT KEY F30,
	DELETE KEY F40

LET salirinp = 0
WHILE TRUE

	LET int_flag = 0
	CALL set_count(pagos) 

	INPUT ARRAY r_detalle_2 WITHOUT DEFAULTS FROM r_detalle_2.*

		BEFORE INPUT 
			--#CALL dialog.keysetlabel ('INSERT','')
			--#CALL dialog.keysetlabel ('DELETE','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")

		ON KEY(INTERRUPT)
			LET int_flag = 0
			CONTINUE INPUT

        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()

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
					--CALL fgl_winmessage(vg_producto,'Existen fechas que resultan menores a las ingresadas anteriormente en los pagos. ','exclamation')
					CALL fl_mostrar_mensaje('Existen fechas que resultan menores a las ingresadas anteriormente en los pagos.','exclamation')
					EXIT INPUT
				END IF
			END FOR	

			IF tot_cap > tot_compra THEN
				--CALL fgl_winmessage(vg_producto,'El total del valor capital es mayor al total de la deuda. ','exclamation')
				CALL fl_mostrar_mensaje('El total del valor capital es mayor al total de la deuda.','exclamation')
				EXIT INPUT
			END IF

			IF tot_cap < tot_compra THEN
				--CALL fgl_winmessage(vg_producto,'El total del valor capital es menor al total de la deuda. ','exclamation')
				CALL fl_mostrar_mensaje('El total del valor capital es menor al total de la deuda.','exclamation')
				EXIT INPUT
			END IF

			LET tot_dias = r_detalle_2[pagos].c12_fecha_vcto - TODAY 	
			DISPLAY BY NAME tot_dias

			IF vg_gui = 1 THEN
				EXIT WHILE
			ELSE
		 		LET salirinp = 1
				EXIT INPUT
			END IF
	END INPUT
	IF salirinp = 1 THEN
		EXIT WHILE
	END IF	

END WHILE	

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'T' 			TO tit_col0
--#DISPLAY 'Cantidad' 		TO tit_col1
--#DISPLAY 'Codigo' 		TO tit_col2
--#DISPLAY 'Descripción'	TO tit_col3
--#DISPLAY 'Des %'		TO tit_col4
--#DISPLAY 'Precio U.'		TO tit_col5
--#DISPLAY ' Subtotal'		TO tit_col6

END FUNCTION



FUNCTION control_DISPLAY_botones_2()

--#DISPLAY '#' 	 		TO tit_col1
--#DISPLAY 'Fecha Vcto'		TO tit_col2
--#DISPLAY 'Valor Capital'	TO tit_col3
--#DISPLAY 'Valor Interes'	TO tit_col4
--#DISPLAY 'Subtotal'		TO tit_col5

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE  i,j 		SMALLINT
DEFINE r_c01		RECORD LIKE ordt001.*

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
CALL muestra_contadores_det(1, vm_ind_arr)
CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()	
		CALL muestra_contadores_det(i, vm_ind_arr)
	ON KEY(F5)
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		CALL mostrar_bien(i)
		LET int_flag = 0
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET i = arr_curr()	
		--#LET j = scr_line()	
		--#CALL muestra_contadores_det(i, vm_ind_arr)
		--#IF r_detalle[i].c11_descuento IS NOT NULL AND
		   --#r_detalle[i].c11_precio    IS NOT NULL AND
		   --#r_detalle[i].c11_cant_ped  IS NOT NULL 
		   --#THEN
			--#LET vm_subtotal_2 = r_detalle[i].c11_precio * 
					  --#r_detalle[i].c11_cant_ped
		--#END IF
		--#IF vm_activo_mod = r_c01.c01_modulo THEN
			--#CALL dialog.keysetlabel("F5","Ver Bien")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","")
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
		
END DISPLAY
CALL muestra_contadores_det(0, vm_ind_arr)

END FUNCTION



FUNCTION control_ingreso()
DEFINE i, intentar 	SMALLINT
DEFINE done 		SMALLINT

CLEAR FORM
CALL control_DISPLAY_botones()

LET vm_flag_mant = 'I'
INITIALIZE rm_c10.*, rm_c11.* TO NULL

-- INITIAL VALUES FOR rm_c10 FIELDS
--LET rm_c10.c10_tipo_pago   = 'C'
LET rm_c10.c10_tipo_pago   = 'R'
IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF
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
LET rm_c10.c10_flete       = 0
LET rm_c10.c10_otros       = 0
LET rm_c10.c10_dif_cuadre  = 0
LET rm_c10.c10_porc_impto = rg_gen.g00_porc_impto
LET valor_fact   = 0
LET vm_num_detalles = 0

CALL fl_lee_moneda(rg_gen.g00_moneda_base) 	     -- PARA OBTENER EL NOMBRE 
	RETURNING rm_g13.*		   	     -- DE LA MONEDA BASE
LET rm_c10.c10_precision = rm_g13.g13_decimales

DISPLAY BY NAME rm_c10.c10_moneda,      rm_c10.c10_porc_impto, 
		rm_c10.c10_porc_descto,
		rm_c10.c10_recargo,	rm_c10.c10_tipo_pago,
		rm_c10.c10_fecing,	rm_c10.c10_estado	

DISPLAY rm_g13.g13_nombre TO nom_moneda
DISPLAY 'ACTIVO' TO tit_estado
LET vm_calc_iva = 'S'
IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF

CALL control_lee_cabecera()

IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET vm_num_detalles = control_lee_detalle() 

IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
	-- ACTUALIZO LOS VALORES DEFAULTS QUE INGRESE AL INICIO DE LEE DATOS --

BEGIN WORK

	LET done = control_insert_ordt010()
	IF done = 0 THEN
		ROLLBACK WORK
		--CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso de la cabecera de la preventa no se realizara el proceso.','exclamation')
		CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso de la cabecera de la orden de compras no se realizara el proceso.','exclamation')
		IF vm_num_rows <= 1 THEN
			LET vm_num_rows = 0
			LET vm_row_current = 0
			CLEAR FORM
			CALL control_DISPLAY_botones()
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
		--CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso del detalle de la preventa no se realizara el proceso.','exclamation')
		CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso del detalle de la preventa no se realizara el proceso.','exclamation')
		IF vm_num_rows <= 1 THEN
			LET vm_num_rows = 0
			LET vm_row_current = 0
			CLEAR FORM
			CALL control_DISPLAY_botones()
		ELSE
			LET vm_num_rows = vm_num_rows - 1
			LET vm_row_current = vm_num_rows
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
COMMIT WORK

	IF rm_c10.c10_tipo_pago = 'R' THEN
		--CALL fgl_winmessage(vg_producto,'Debe especificar la forma de pago para esta orden de compra','info')
		CALL fl_mostrar_mensaje('Debe especificar la forma de pago para esta orden de compra','info')
		CALL control_forma_pago()
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_tipopago(rm_c10.c10_tipo_pago)
	END IF

CALL muestra_contadores()
CALL imprimir_orden()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
DEFINE done		SMALLINT
DEFINE resp		VARCHAR(6)
DEFINE aprobada		SMALLINT

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c10.c10_numero_oc)
	RETURNING rm_c10.*
IF rm_c10.c10_estado = 'C' THEN
	CALL fl_mostrar_mensaje('No puede modificar una Orden de Compra que este cerrada.','exclamation')
	RETURN
END IF
IF rm_c10.c10_estado = 'E' THEN
	CALL fl_mostrar_mensaje('No puede modificar una Orden de Compra que esta eliminada.','exclamation')
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
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP

LET aprobada = 0
IF rm_c10.c10_estado = 'P' THEN
	--CALL fgl_winquestion(vg_producto,'La orden ya fue aprobada, si continua debera aprobar la orden nuevamente. Desea continuar?','No','Yes|No','question',1)
	CALL fl_hacer_pregunta('La orden ya fue aprobada, si continua debera aprobar la orden nuevamente. Desea continuar?','No')
		RETURNING resp
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
		--CALL fgl_winmessage(vg_producto,'Ha ocurrido un error al intentar actualizar el detalle de la preventa. No se realizara el proceso.','exclamation')
		CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar actualizar el detalle de la preventa. No se realizara el proceso.','exclamation')
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN
	END IF

	COMMIT WORK
	IF rm_c10.c10_tipo_pago = 'R' THEN
		--CALL fgl_winmessage(vg_producto,'Debe especificar la forma de pago para esta orden de compra','info')
		CALL fl_mostrar_mensaje('Debe especificar la forma de pago para esta orden de compra.','info')
		CALL control_forma_pago()
		IF vg_gui = 0 THEN
			CALL muestra_tipopago(rm_c10.c10_tipo_pago)
		END IF
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
--CALL fgl_winquestion(vg_producto,'Registro bloqueado por otro usuario, desea intentarlo nuevamente','No','Yes|No','question',1)
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente','No')
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
DEFINE r_s23		RECORD LIKE srit023.*

LET done = 1
LET rm_c10.c10_fecing = CURRENT

SELECT MAX(c10_numero_oc) + 1 INTO rm_c10.c10_numero_oc
	FROM  ordt010
	WHERE c10_compania  = vg_codcia
	AND   c10_localidad = vg_codloc

IF rm_c10.c10_numero_oc IS NULL THEN
	LET rm_c10.c10_numero_oc = 1
END IF

--WHENEVER ERROR CONTINUE
WHENEVER ERROR STOP

LET rm_c10.c10_sustento_sri = 'S'
CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
				rm_c10.c10_sustento_sri)
	RETURNING r_s23.*
IF r_s23.s23_compania IS NULL THEN
	RETURN 0
END IF
LET rm_c10.c10_cod_sust_sri = r_s23.s23_sustento_sri
LET rm_c10.c10_base_ice     = 0
LET rm_c10.c10_valor_ice    = 0
IF vm_flag_llam = 'I' THEN
	LET rm_c10.c10_estado      = 'P'
	LET rm_c10.c10_usua_aprob  = vg_usuario
	LET rm_c10.c10_fecha_aprob = CURRENT
END IF
INSERT INTO ordt010 VALUES (rm_c10.*)
DISPLAY BY NAME rm_c10.c10_numero_oc

IF status < 0 THEN
	WHENEVER ERROR STOP
	SELECT MAX(c10_numero_oc) + 1 INTO rm_c10.c10_numero_oc
		FROM  ordt010
		WHERE c10_compania  = vg_codcia
		AND   c10_localidad = vg_codloc
	LET rm_c10.c10_sustento_sri = 'S'
	CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
					rm_c10.c10_sustento_sri)
		RETURNING r_s23.*
	IF r_s23.s23_compania IS NULL THEN
		RETURN 0
	END IF
	LET rm_c10.c10_cod_sust_sri = r_s23.s23_sustento_sri
	LET rm_c10.c10_base_ice     = 0
	LET rm_c10.c10_valor_ice    = 0
	INSERT INTO ordt010 VALUES (rm_c10.*)
	DISPLAY BY NAME rm_c10.c10_numero_oc
END IF
WHENEVER ERROR STOP

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

--WHENEVER ERROR CONTINUE

LET rm_c11.c11_compania   = vg_codcia
LET rm_c11.c11_localidad  = vg_codloc
LET rm_c11.c11_numero_oc  = rm_c10.c10_numero_oc
LET rm_c11.c11_cant_rec   = 0

FOR i = 1 TO vm_num_detalles

	
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

WHENEVER ERROR STOP
IF status < 0 THEN
	LET done = 0
ELSE
	LET done = 1
END IF

RETURN done

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE resp 		CHAR(6)
DEFINE done			SMALLINT
DEFINE r_b43		RECORD LIKE ctbt043.*
DEFINE r_s23_s		RECORD LIKE srit023.*
DEFINE r_s23_n		RECORD LIKE srit023.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_c10		RECORD LIKE ordt010.*

LET int_flag = 0
CALL calcula_totales(vm_num_detalles,1)
IF vm_flag_llam = 'I' THEN
	LET rm_c10.c10_tipo_orden = vm_tipo_oc
	LET rm_c10.c10_cod_depto  = 1
	LET rm_c10.c10_numprof    = vm_numprof
	CALL lee_oc_proforma() RETURNING r_c10.*
	IF r_c10.c10_compania IS NOT NULL THEN
		LET rm_c10.*    = r_c10.*
		LET vm_subtotal = rm_c10.c10_tot_repto + rm_c10.c10_tot_mano
		LET valor_fact  = vm_subtotal - rm_c10.c10_tot_dscto + rm_c10.c10_otros
							+ rm_c10.c10_dif_cuadre
	ELSE
		CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, vm_numprof)
			RETURNING r_r21.*
		LET rm_c10.c10_referencia = r_r21.r21_nomcli
		CALL fl_lee_vendedor_rep(vg_codcia, vm_vendedor) RETURNING r_r01.*
		LET rm_c10.c10_solicitado = r_r01.r01_nombres
	END IF
	CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING rm_c01.*
	CALL fl_lee_departamento(vg_codcia, rm_c10.c10_cod_depto) RETURNING rm_g34.*
	DISPLAY BY NAME rm_c10.c10_cod_depto, rm_c10.c10_tipo_orden,
					rm_c10.c10_numprof, valor_fact, rm_c10.c10_referencia
	DISPLAY rm_g34.g34_nombre TO nom_departamento
	DISPLAY rm_c01.c01_nombre TO nom_tipo_orden
END IF
DISPLAY BY NAME rm_c10.c10_dif_cuadre, rm_c10.c10_usuario
INPUT BY NAME rm_c10.c10_codprov,
              rm_c10.c10_moneda,       rm_c10.c10_tipo_orden,
	      rm_c10.c10_cod_depto,    
	      rm_c10.c10_atencion,      rm_c10.c10_referencia ,  
           rm_c10.c10_porc_impto, 
              vm_calc_iva,             rm_c10.c10_porc_descto,  
              rm_c10.c10_recargo,      rm_c10.c10_solicitado,
	      rm_c10.c10_ord_trabajo,  rm_c10.c10_tipo_pago,   
	     
          rm_c10.c10_otros,
	      rm_c10.c10_flete, rm_c10.c10_numprof, valor_fact 
	      WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(c10_cod_depto,  c10_tipo_orden,
				     c10_codprov,    c10_atencion, 
				     c10_solicitado, c10_ord_trabajo,
				     c10_referencia, rm_c10.c10_numprof)
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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
			CALL fl_ayuda_tipos_ordenes_compras('A')
				RETURNING rm_c01.c01_tipo_orden,
					  rm_c01.c01_nombre
			IF rm_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_c10.c10_tipo_orden =rm_c01.c01_tipo_orden
				DISPLAY BY NAME rm_c10.c10_tipo_orden
				DISPLAY rm_c01.c01_nombre TO nom_tipo_orden
			END IF 
		END IF

		IF INFIELD(c10_ord_trabajo) THEN
			IF vm_flag_llam = 'I' THEN
				LET rm_c10.c10_ord_trabajo = NULL
				DISPLAY BY NAME rm_c10.c10_ord_trabajo
				CONTINUE INPUT
			END IF
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

	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD c10_porc_impto
		CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
						'S')
			RETURNING r_s23_s.*
		CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
						'N')
			RETURNING r_s23_n.*
		IF r_s23_s.s23_compania IS NULL AND r_s23_n.s23_compania IS NULL
		THEN
			CALL fl_mostrar_mensaje('Este tipo de orden de compra no tiene ningun codigo de sustento tributario. POR FAVOR LLAME AL ADMINISTRADOR.', 'exclamation')
			NEXT FIELD c10_porc_impto
		END IF
		{--
		IF rm_c01.c01_aux_cont IS NULL THEN
			IF rm_c10.c10_porc_impto <> 0 THEN
				LET rm_c10.c10_porc_impto = 0
				DISPLAY BY NAME rm_c10.c10_porc_impto
				CONTINUE INPUT
			END IF
		ELSE
			LET rm_c10.c10_porc_impto = rg_gen.g00_porc_impto
			DISPLAY BY NAME rm_c10.c10_porc_impto
		END IF
		--}
		IF rm_c10.c10_porc_impto = 0 THEN
			IF r_s23_n.s23_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este tipo de orden de compra no tiene ningun codigo de sustento tributario exento de IVA.', 'info')
				LET rm_c10.c10_porc_impto = rg_gen.g00_porc_impto
				DISPLAY BY NAME rm_c10.c10_porc_impto
			END IF
		END IF
		IF rm_c10.c10_porc_impto IS NULL THEN
			LET rm_c10.c10_porc_impto = rg_gen.g00_porc_impto 
			DISPLAY BY NAME rm_c10.c10_porc_impto
		END IF
		IF rm_c10.c10_porc_impto <> 0 
		AND rm_c10.c10_porc_impto <> rg_gen.g00_porc_impto 
		THEN
			--CALL fgl_winmessage(vg_producto,'Este no es un porcentaje de impuesto valido.','exclamation')
			CALL fl_mostrar_mensaje('Este no es un porcentaje de impuesto valido.','exclamation')
			NEXT FIELD c10_porc_impto
		END IF

	AFTER FIELD c10_moneda
		IF rm_c10.c10_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_c10.c10_moneda)
				RETURNING rm_g13.*
                	IF rm_g13.g13_moneda IS  NULL THEN
		    		--CALL fgl_winmessage(vg_producto,'La moneda no existe en la Compañía. ','exclamation')
				CALL fl_mostrar_mensaje('La moneda no existe en la Compañía.','exclamation')
				CLEAR nom_moneda
                        	NEXT FIELD c10_moneda
			END IF
			IF  rm_c10.c10_moneda <> rg_gen.g00_moneda_base AND
			    rm_c10.c10_moneda <> rg_gen.g00_moneda_alt
			    THEN
				--CALL fgl_winmessage(vg_producto,'La Moneda ingresada no es la moneda base ni la moneda alterna','exclamation')
				CALL fl_mostrar_mensaje('La Moneda ingresada no es la moneda base ni la moneda alterna.','exclamation')
				CLEAR nom_moneda
				NEXT FIELD c10_moneda
			END IF
			IF rm_c10.c10_moneda <> rg_gen.g00_moneda_base THEN
				CALL fl_mostrar_mensaje('La Moneda ingresada no puede ser diferente a la moneda base del sistema.','exclamation')
				LET rm_c10.c10_moneda = rg_gen.g00_moneda_base
				DISPLAY BY NAME rm_c10.c10_moneda
				NEXT FIELD c10_moneda
			END IF
			IF rm_c10.c10_moneda = rg_gen.g00_moneda_alt THEN
				CALL fl_lee_factor_moneda(rm_c10.c10_moneda,
							rg_gen.g00_moneda_base)
					RETURNING rm_g14.*
				IF rm_g14.g14_tasa IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'No existe conversión entre la moneda base y la moneda alterna. Debe revisar la configuración. ','exclamation')
					CALL fl_mostrar_mensaje('No existe conversión entre la moneda base y la moneda alterna. Debe revisar la configuración.','exclamation')
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
			NEXT FIELD NEXT
		END IF

	AFTER FIELD c10_tipo_orden
		IF rm_c10.c10_tipo_orden IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden)
				RETURNING rm_c01.*
			IF rm_c01.c01_tipo_orden IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe el tipo de orden en la Compañía.','exclamation')
				CALL fl_mostrar_mensaje('No existe el tipo de orden en la Compañía.','exclamation')
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
			IF rm_c01.c01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD c10_tipo_orden
			END IF
			IF rm_c01.c01_aux_cont IS NULL THEN
				IF rm_c10.c10_porc_impto <> 0 THEN
					LET rm_c10.c10_porc_impto = 0
					DISPLAY BY NAME rm_c10.c10_porc_impto
				END IF
			ELSE
				IF rm_c10.c10_porc_impto <>rg_gen.g00_porc_impto
				THEN
					LET rm_c10.c10_porc_impto =
							rg_gen.g00_porc_impto 
					DISPLAY BY NAME rm_c10.c10_porc_impto
				END IF
			END IF
			CALL fl_obtener_aux_cont_sust(vg_codcia,
						rm_c10.c10_tipo_orden, 'S')
				RETURNING r_s23_s.*
			IF r_s23_s.s23_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este tipo de orden de compra no tiene configurado ningun codigo de sustento tributario (SI sustento).', 'exclamation')
				NEXT FIELD c10_tipo_orden
			END IF
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
				--CALL fgl_winmessage(vg_producto,'No existe el departamento en la Compañía.','exclamation')
				CALL fl_mostrar_mensaje('No existe el departamento en la Compañía.','exclamation')
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
				--CALL fgl_winmessage(vg_producto,'No existe el proveedor en la Compañía.','exclamation')
				CALL fl_mostrar_mensaje('No existe el proveedor en la Compañía.','exclamation')
				NEXT FIELD c10_codprov
			END IF
			DISPLAY rm_p01.p01_nomprov TO nom_proveedor
			IF rm_p01.p01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD c10_codprov
			END IF
		ELSE	
			CLEAR nom_proveedor
		END IF

	AFTER FIELD c10_ord_trabajo
		IF vm_flag_llam = 'I' THEN
			LET rm_c10.c10_ord_trabajo = NULL
			DISPLAY BY NAME rm_c10.c10_ord_trabajo
			CONTINUE INPUT
		END IF
		IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
			CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
						  rm_c10.c10_ord_trabajo)
				RETURNING rm_t23.*
			IF rm_t23.t23_orden IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe la orden de trabajo en la Compañía.','exclamation')
				CALL fl_mostrar_mensaje('No existe la orden de trabajo en la Compañía.','exclamation')
				NEXT FIELD c10_ord_trabajo
			END IF
			IF rm_c01.c01_modulo IS NULL OR rm_c01.c01_modulo <> 'TA' THEN
				--CALL fgl_winmessage(vg_producto,'La orden de trabajo solo es obligatorio cuando la orden sea por bienes y servicios.','exclamation')
				CALL fl_mostrar_mensaje('La orden de trabajo solo es obligatorio cuando la orden sea por bienes y servicios.','exclamation')
				INITIALIZE rm_c10.c10_ord_trabajo TO NULL
				CLEAR c10_ord_trabajo
				CLEAR nom_ord_trabajo
				NEXT FIELD NEXT 
			END IF
			DISPLAY rm_t23.t23_nom_cliente TO nom_ord_trabajo
			IF rm_t23.t23_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('La orden de trabajo debe estar activa.','exclamation')
				NEXT FIELD c10_ord_trabajo
			END IF
		ELSE	
			CLEAR nom_ord_trabajo
		END IF
	AFTER FIELD c10_tipo_pago
		IF vg_gui = 0 THEN
			IF rm_c10.c10_tipo_pago IS NOT NULL THEN
				CALL muestra_tipopago(rm_c10.c10_tipo_pago)
			ELSE
				CLEAR tit_tipo_pago
			END IF
		END IF
	AFTER FIELD valor_fact
		IF valor_fact IS NULL OR valor_fact <= 0 THEN
			LET valor_fact = vm_subtotal - rm_c10.c10_tot_dscto + rm_c10.c10_otros
			DISPLAY BY NAME valor_fact 
		END IF
		CALL calcula_totales(vm_num_detalles,1)
	AFTER FIELD c10_otros, c10_flete
		CALL calcula_totales(vm_num_detalles,1)
	AFTER INPUT
		IF vm_flag_llam <> 'I' THEN
			IF valor_fact IS NULL OR valor_fact <= 0 THEN
				CALL fl_mostrar_mensaje('Digite subtotal antes del iva de la factura del proveedor.','exclamation')
				NEXT FIELD valor_fact
			END IF
		END IF
		IF rm_c01.c01_modulo = 'TA' AND rm_c10.c10_ord_trabajo IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar una Orden de Trabajo para esta Orden de Compra.','exclamation')
			NEXT FIELD c10_ord_trabajo
		END IF
		IF rm_c01.c01_aux_cont IS NULL THEN
			IF rm_c10.c10_porc_impto <> 0 THEN
				LET rm_c10.c10_porc_impto = 0
				DISPLAY BY NAME rm_c10.c10_porc_impto
			END IF
		END IF
		CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
						'S')
			RETURNING r_s23_s.*
		CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
						'N')
			RETURNING r_s23_n.*
		IF r_s23_s.s23_compania IS NULL AND r_s23_n.s23_compania IS NULL
		THEN
			CALL fl_mostrar_mensaje('Este tipo de orden de compra no tiene ningun codigo de sustento tributario. POR FAVOR LLAME AL ADMINISTRADOR.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_c01.c01_aux_cont IS NULL AND r_s23_s.s23_aux_cont IS NULL
		THEN
			IF rm_c10.c10_porc_impto <> 0 THEN
				CALL fl_mostrar_mensaje('Este tipo de orden de compra no tiene ningun auxiliar contable para IVA. POR FAVOR LLAME AL ADMINISTRADOR.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
			INITIALIZE r_b43.* TO NULL
			DECLARE q_b43 CURSOR FOR
				SELECT * FROM ctbt043
					WHERE b43_compania   = vg_codcia
					  AND b43_localidad  = vg_codloc
					  AND b43_porc_impto =
							rm_c10.c10_porc_impto
			OPEN q_b43
			FETCH q_b43 INTO r_b43.*
			CLOSE q_b43
			FREE q_b43
			IF r_b43.b43_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables del taller (ctbt043) para este tipo de orden de compras exentas de IVA.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_lee_detalle()
DEFINE i,j,k,ind	SMALLINT
DEFINE max_row		SMALLINT
DEFINE resp		CHAR(6)
DEFINE paga_iva		LIKE ordt011.c11_paga_iva
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE grupo_linea	LIKE rept003.r03_grupo_linea
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE valor_bien	LIKE actt010.a10_valor
DEFINE grupo		LIKE actt010.a10_grupo_act
DEFINE tipo		LIKE actt010.a10_tipo_act
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r22		RECORD LIKE rept022.*

-- Para los valores de la lista de precios
DEFINE pvp_prov_sug	 LIKE ordt004.c04_pvp_prov_sug
DEFINE desc_prov	 LIKE ordt004.c04_desc_prov
DEFINE costo_prov	 LIKE ordt004.c04_costo_prov

CALL retorna_tam_arr()
LET vm_filas_pant  = vm_size_arr
LET rm_c10.c10_tot_compra = 0
LET i = 1
LET j = 1

INITIALIZE grupo_linea, bodega, grupo, tipo TO NULL
IF vm_flag_mant <> 'M' THEN
	FOR k = 1 TO vm_filas_pant 
		INITIALIZE r_detalle[k].* TO NULL
		CLEAR r_detalle[k].*
	END FOR
	CALL set_count(i)
	LET max_row = i
ELSE 
	CALL set_count(vm_ind_arr)
	LET max_row = vm_ind_arr
END IF

IF vm_flag_llam = 'I' THEN

	-- En el pedido se deben acumular los items
	DECLARE q_r22 CURSOR FOR
		SELECT r22_item, r10_nombre, c04_pvp_prov_sug, c04_desc_prov,
               c04_costo_prov, r22_precio, sum(r22_cantidad)
			FROM rept022, rept010, OUTER ordt004
			WHERE r22_compania  = vg_codcia
			  AND r22_localidad = vg_codloc
			  AND r22_numprof   = vm_numprof
			  AND r10_compania  = r22_compania
			  AND r10_codigo    = r22_item
  			  AND c04_compania  = r22_compania
  			  AND c04_localidad = r22_localidad
			  AND c04_codprov   = rm_c10.c10_codprov
			  AND c04_cod_item  = r10_cod_pedido
			  AND c04_fecha_vigen <= TODAY
			  AND (c04_fecha_fin IS NULL OR c04_fecha_fin > TODAY)
			GROUP BY r22_item, r10_nombre, c04_pvp_prov_sug, c04_desc_prov,
               		 c04_costo_prov, r22_precio

	LET valor_fact = 0
	LET k = 1
	FOREACH q_r22 INTO r_detalle[k].c11_codigo, r_detalle[k].c11_descrip,
						pvp_prov_sug, desc_prov, costo_prov, r_detalle[k].c11_precio,
						r_detalle[k].c11_cant_ped	

		LET r_detalle[k].c11_tipo = 'B'

		-- Si tenemos la lista de precios del proveedor, usemos esa en lugar
		-- de los precios de la proforma
		IF pvp_prov_sug IS NOT NULL THEN
			LET r_detalle[k].c11_precio = pvp_prov_sug 
			LET r_detalle[k].c11_descuento = desc_prov 
		ELSE
			IF costo_prov IS NOT NULL THEN
				LET r_detalle[k].c11_precio = costo_prov
				LET r_detalle[k].c11_descuento = 0 
			END IF
		END IF

		LET r_detalle[k].c11_descuento = 0 
		LET r_detalle[k].subtotal = (r_detalle[k].c11_precio * 
										(1 - (r_detalle[k].c11_descuento / 100))) * 
										r_detalle[k].c11_cant_ped
		LET r_detalle[k].paga_iva = 'S'

		LET valor_fact            = valor_fact + r_detalle[k].subtotal

		LET k = k + 1
	END FOREACH
	LET k = k - 1
	IF k < 1 THEN
		LET k = 1
	END IF
	CALL set_count(k)
	LET max_row = k
END IF

INITIALIZE r_r10.*, r_r22.* TO NULL

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
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
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(c11_codigo) THEN
			IF vm_flag_item = 'S' THEN
                	CALL fl_ayuda_maestro_items_stock(vg_codcia,grupo_linea,
							bodega)
         			RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre,
					  rm_r10.r10_linea,rm_r10.r10_precio_mb,
					  r_r11.r11_bodega, stock
                     		IF rm_r10.r10_codigo IS NOT NULL THEN
					LET r_detalle[i].c11_codigo  = 
				    	    rm_r10.r10_codigo
					LET r_detalle[i].c11_descrip = 
				    	    rm_r10.r10_nombre
					DISPLAY r_detalle[i].c11_codigo TO
						r_detalle[j].c11_codigo
                        		DISPLAY r_detalle[i].c11_descrip TO
						r_detalle[j].c11_descrip
					ERROR rm_r10.r10_nombre
				END IF

			END IF
			IF r_c01.c01_modulo = vm_activo_mod THEN
				CALL fl_ayuda_codigo_bien(vg_codcia, grupo,
								tipo, 'A', 0)
					RETURNING r_a10.a10_codigo_bien,
						  r_a10.a10_descripcion
				IF r_a10.a10_codigo_bien IS NOT NULL THEN
					LET r_detalle[i].c11_codigo  = 
				    	    r_a10.a10_codigo_bien
					LET r_detalle[i].c11_descrip = 
				    	    r_a10.a10_descripcion
					DISPLAY r_detalle[i].c11_codigo TO
						r_detalle[j].c11_codigo
                        		DISPLAY r_detalle[i].c11_descrip TO
						r_detalle[j].c11_descrip
				END IF
			END IF	
                END IF
	ON KEY(F5)
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		CALL mostrar_bien(i)
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#IF vm_activo_mod = r_c01.c01_modulo THEN
			--#CALL dialog.keysetlabel("F5","Ver Bien")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","")
		--#END IF
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)

		IF i > vm_max_detalle THEN
			--CALL fgl_winmessage(vg_producto,'Ha llegado al límite del detalle de la orden de compra no puede ingresar mas elementos al detalle','exclamation')
			CALL fl_mostrar_mensaje('Ha llegado al límite del detalle de la orden de compra no puede ingresar mas elementos al detalle.','exclamation')
			NEXT FIELD c11_cant_ped
		END IF

		IF r_detalle[i].c11_cant_ped IS NOT NULL AND
		   r_detalle[i].c11_precio   IS NOT NULL 
		   THEN
			LET vm_subtotal_2 = r_detalle[i].c11_cant_ped *
					    r_detalle[i].c11_precio
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
		IF vm_activo_mod = r_c01.c01_modulo THEN
			LET r_detalle[i].c11_tipo = 'B'
			DISPLAY r_detalle[i].c11_tipo TO r_detalle[j].c11_tipo
			LET r_detalle[i].c11_cant_ped = 1
			DISPLAY r_detalle[i].c11_cant_ped TO
		       		r_detalle[j].c11_cant_ped
		END IF
		IF r_detalle[i].paga_iva IS NULL THEN
			LET r_detalle[i].paga_iva = 'S'
			DISPLAY r_detalle[i].paga_iva TO r_detalle[j].c11_paga_iva
		END IF
		IF vm_flag_item = 'S' AND r_detalle[i].c11_codigo IS NOT NULL
		   THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].c11_codigo)
				RETURNING rm_r10.*
			ERROR rm_r10.r10_nombre
		END IF

	AFTER ROW
		IF vm_activo_mod = r_c01.c01_modulo THEN
			LET r_detalle[i].c11_tipo = 'B'
			DISPLAY r_detalle[i].c11_tipo TO r_detalle[j].c11_tipo
			LET r_detalle[i].c11_cant_ped = 1
			DISPLAY r_detalle[i].c11_cant_ped TO
		       		r_detalle[j].c11_cant_ped
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
		IF r_detalle[i].c11_cant_ped IS NOT NULL OR
		   r_detalle[i].c11_tipo = 'S' OR
		   vm_activo_mod = r_c01.c01_modulo THEN
			LET r_detalle[i].c11_cant_ped = 1
			--DISPLAY r_detalle[i].c11_cant_ped TO
			  --      r_detalle[j].c11_cant_ped
			IF r_detalle[i].c11_descuento IS NOT NULL AND
			   r_detalle[i].c11_precio    IS NOT NULL 
		   	   THEN
				LET r_detalle[i].subtotal = 
				    r_detalle[i].c11_precio * 
				    r_detalle[i].c11_cant_ped
				DISPLAY r_detalle[i].subtotal TO 
				        r_detalle[j].subtotal
				LET k = i - j + 1
				CALL calcula_totales(arr_count(),k)
			END IF
		END IF
		IF vm_activo_mod = r_c01.c01_modulo THEN
			LET r_detalle[i].c11_tipo = 'B'
			DISPLAY r_detalle[i].c11_tipo TO r_detalle[j].c11_tipo
			LET r_detalle[i].c11_cant_ped = 1
			DISPLAY r_detalle[i].c11_cant_ped TO
		       		r_detalle[j].c11_cant_ped
		END IF
	
	BEFORE FIELD c11_paga_iva
		IF vm_calc_iva = 'S' THEN
			--NEXT FIELD c11_cant_ped
			--NEXT FIELD NEXT
		END IF
		LET paga_iva = r_detalle[i].paga_iva

	AFTER FIELD c11_paga_iva
		IF vm_calc_iva = 'S' THEN
			LET r_detalle[i].paga_iva = 'S'
			DISPLAY r_detalle[i].paga_iva TO 
				r_detalle[j].c11_paga_iva
		END IF
		IF r_detalle[i].paga_iva <> paga_iva THEN
			LET k = i - j + 1
			CALL calcula_totales(arr_count(), k)
		END IF
		--NEXT FIELD c11_cant_ped

	AFTER ROW 
{--
		IF r_detalle[i].c11_codigo IS NULL THEN
			NEXT FIELD c11_codigo		
		END IF
		IF r_detalle[i].c11_descrip IS NULL THEN
			NEXT FIELD c11_descrip		
		END IF
--}
		
	AFTER FIELD c11_cant_ped
		IF r_detalle[i].c11_cant_ped IS NOT NULL THEN
			IF r_detalle[i].c11_tipo = 'S'
			OR vm_activo_mod = r_c01.c01_modulo THEN
				LET r_detalle[i].c11_cant_ped = 1
				DISPLAY r_detalle[i].c11_cant_ped TO
			       		r_detalle[j].c11_cant_ped
			END IF	
			IF r_detalle[i].c11_descuento IS NOT NULL AND
			   r_detalle[i].c11_precio    IS NOT NULL 
		   	   THEN
				LET r_detalle[i].subtotal = 
				    r_detalle[i].c11_precio * 
				    r_detalle[i].c11_cant_ped
				DISPLAY r_detalle[i].subtotal TO 
				        r_detalle[j].subtotal
				LET k = i - j + 1
				CALL calcula_totales(arr_count(),k)
			END IF
		END IF	
		IF r_detalle[i].c11_cant_ped IS NULL AND
		   r_detalle[i].c11_precio   IS NOT NULL 
		   THEN
			NEXT FIELD c11_cant_ped
		END IF
		IF vm_activo_mod = r_c01.c01_modulo THEN
			LET r_detalle[i].c11_tipo = 'B'
			DISPLAY r_detalle[i].c11_tipo TO r_detalle[j].c11_tipo
			LET r_detalle[i].c11_cant_ped = 1
			DISPLAY r_detalle[i].c11_cant_ped TO
		       		r_detalle[j].c11_cant_ped
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
		IF r_detalle[i].c11_codigo IS NULL AND 
			r_detalle[i].c11_cant_ped IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Digite código.','exclamation')
			NEXT FIELD c11_codigo
		END IF  
		IF vm_flag_item = 'S' AND r_detalle[i].c11_codigo IS NOT NULL
		   THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].c11_codigo)
				RETURNING rm_r10.*
			IF rm_r10.r10_codigo IS NULL THEN
				--CALL fgl_winquestion(vg_producto,'El código no existe. ¿ Desea crearlo ?','No','Yes|No','question',1)	
				CALL fl_hacer_pregunta('El código no existe. ¿ Desea crearlo ?','No')
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
			ERROR rm_r10.r10_nombre
			IF rm_r10.r10_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Item esta bloqueado.','exclamation')
				NEXT FIELD c11_codigo
			END IF
			IF rm_r10.r10_costo_mb <= 0.01 AND
			   --fl_item_tiene_movimientos(vg_codcia,
			--				rm_r10.r10_codigo)
			   tiene_stock_local(rm_r10.r10_codigo) > 0
			THEN
				CALL fl_mostrar_mensaje('Debe estar configurado correctamente el costo del item origen y NO con costo menor igual a 0.01.', 'exclamation')
				NEXT FIELD c11_codigo
			END IF
		END IF 
		IF vm_activo_mod = r_c01.c01_modulo THEN
			CALL fl_lee_codigo_bien(vg_codcia,
						r_detalle[i].c11_codigo)
				RETURNING r_a10.*
			IF r_a10.a10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este código de bien en la compania.','exclamation')
				NEXT FIELD c11_codigo
			END IF
			LET r_detalle[i].c11_descrip = r_a10.a10_descripcion
			LET r_detalle[i].c11_precio  = r_a10.a10_valor
			DISPLAY r_detalle[i].c11_descrip TO 
				r_detalle[j].c11_descrip
			DISPLAY r_detalle[i].c11_precio TO 
				r_detalle[j].c11_precio
			IF r_a10.a10_estado = 'S' THEN
				CALL fl_mostrar_mensaje('Este código de bien ya tiene stock.','exclamation')
				NEXT FIELD c11_codigo
			END IF
			IF r_a10.a10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('Este código de bien no tiene estado de recien creado: A.','exclamation')
				NEXT FIELD c11_codigo
			END IF
		END IF 
		IF r_detalle[i].c11_descrip IS NOT NULL AND 
		   r_detalle[i].c11_codigo  IS NULL
		   THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar el código de la descripción ingresada.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar el código de la descripción ingresada.','exclamation')
			NEXT FIELD c11_codigo
		END IF  
		------ PARA LA VALIDACION DE CODIGOS REPETIDOS ------
			FOR k = 1 TO arr_count()
				IF  r_detalle[i].c11_codigo =
				    r_detalle[k].c11_codigo AND 
				    i <> k
				    THEN
					--CALL fgl_winmessage(vg_producto,'No puede ingresar códigos repetidos','exclamation')
					CALL fl_mostrar_mensaje('No puede ingresar códigos repetidos.','exclamation')
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
			--CALL fgl_winmessage(vg_producto,'Debe ingresar la descripción del código ingresado.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar la descripción del código ingresado.','exclamation')
			NEXT FIELD c11_descrip
		END IF  
		IF r_detalle[i].c11_descrip IS NOT NULL AND 
			r_detalle[i].c11_descuento IS NULL THEN
			LET r_detalle[i].c11_descuento = rm_c10.c10_porc_descto
			DISPLAY r_detalle[i].c11_descuento TO 
				r_detalle[j].c11_descuento
			LET k = i - j + 1
			CALL calcula_totales(arr_count(),k)
		END IF
{
	BEFORE FIELD c11_descuento
		LET r_detalle[i].c11_descuento = rm_c10.c10_porc_descto
		DISPLAY r_detalle[i].c11_descuento TO 
			r_detalle[j].c11_descuento
}
	AFTER FIELD c11_descuento
		IF r_detalle[i].c11_descuento IS NULL AND 
		   r_detalle[i].c11_codigo IS NOT NULL THEN
			LET r_detalle[i].c11_descuento = rm_c10.c10_porc_descto
			DISPLAY r_detalle[i].c11_descuento TO 
				r_detalle[j].c11_descuento
		END IF	
		LET k = i - j + 1
		CALL calcula_totales(arr_count(),k)
	BEFORE FIELD c11_precio
		LET valor_bien = NULL
		IF vm_activo_mod = r_c01.c01_modulo THEN
			LET valor_bien = r_detalle[i].c11_precio
		END IF
	AFTER FIELD c11_precio
		IF valor_bien IS NOT NULL THEN
			LET r_detalle[i].c11_precio = valor_bien
			DISPLAY r_detalle[i].c11_precio TO
				r_detalle[j].c11_precio
		END IF
		IF r_detalle[i].c11_descuento IS NOT NULL AND
		   r_detalle[i].c11_cant_ped  IS NOT NULL 
		   THEN
			LET r_detalle[i].subtotal = r_detalle[i].c11_precio * 
			                            r_detalle[i].c11_cant_ped
			DISPLAY r_detalle[i].subtotal TO r_detalle[j].subtotal
			LET k = i - j + 1
			CALL calcula_totales(arr_count(),k)
		END IF	
		IF  r_detalle[i].c11_precio   IS NULL AND 
		    r_detalle[i].c11_cant_ped IS NOT NULL 
		    THEN
			NEXT FIELD c11_precio
		END IF

	AFTER INPUT
		LET ind        = arr_count() 
		IF ind = 0 OR r_detalle[1].c11_cant_ped IS NULL THEN 
			CALL fl_mostrar_mensaje('Digite detalle.','exclamation')
			NEXT FIELD c11_cant_ped
		END IF  
		IF rm_c10.c10_dif_cuadre > 1 OR rm_c10.c10_dif_cuadre < -1 THEN
			CALL fl_mostrar_mensaje('La diferencia de cuadre no debe ser mayor que 1.','exclamation')
			NEXT FIELD c11_cant_ped
		END IF  
		IF rm_c10.c10_tot_compra = 0 THEN
			NEXT FIELD c11_cant_ped
		END IF
		LET vm_ind_arr = ind 

END INPUT

RETURN ind

END FUNCTION



FUNCTION mostrar_bien(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(100)

LET param = r_detalle[i].c11_codigo
CALL ejecuta_comando('ACTIVOS', 'AF', 'actp104', param)

END FUNCTION



FUNCTION control_crear_item()
DEFINE param		VARCHAR(100)

LET param = NULL
CALL ejecuta_comando('REPUESTOS', 'RE', 'repp108', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(20)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(100)
DEFINE command 		VARCHAR(255) 
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET command = 'cd ..', vg_separador, '..', vg_separador, modulo, 
	           vg_separador, 'fuentes', vg_separador, run_prog, 
		   prog, ' ', vg_base, ' ', mod, ' ', vg_codcia, ' ',
		param CLIPPED
RUN command

END FUNCTION



FUNCTION calcula_totales(indice, indice_2)
DEFINE indice,k		SMALLINT
DEFINE indice_2,y	SMALLINT
DEFINE v_impto		LIKE ordt010.c10_tot_impto

CALL retorna_tam_arr()
LET vm_filas_pant  = vm_size_arr
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
	LET r_detalle[k].subtotal = vm_subtotal_2

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
IF valor_fact = 0 THEN
	LET valor_fact = vm_subtotal - rm_c10.c10_tot_dscto + rm_c10.c10_otros
END IF
DISPLAY BY NAME valor_fact

LET rm_c10.c10_dif_cuadre = valor_fact - (vm_subtotal - rm_c10.c10_tot_dscto +
					rm_c10.c10_otros)

IF vm_calc_iva = 'S' THEN
	LET rm_c10.c10_tot_impto = (rm_c10.c10_tot_repto + rm_c10.c10_tot_mano -
				rm_c10.c10_tot_dscto + rm_c10.c10_dif_cuadre +
				rm_c10.c10_otros) * rm_c10.c10_porc_impto / 100
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
			    rm_c10.c10_otros + 
			    rm_c10.c10_tot_impto + rm_c10.c10_flete +
			    rm_c10.c10_dif_cuadre
DISPLAY BY NAME vm_subtotal,          rm_c10.c10_tot_dscto, 
		rm_c10.c10_tot_impto, rm_c10.c10_tot_compra,
		rm_c10.c10_dif_cuadre

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(600)
DEFINE expr_sql_2	CHAR(600)
DEFINE query		CHAR(600)
DEFINE r_c10		RECORD LIKE ordt010.* 	-- CABECERA PROFORMA

INITIALIZE expr_sql_2 TO NULL
CLEAR FORM
CALL control_DISPLAY_botones()

LET vm_flag_mant = 'C'

LET INT_FLAG = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON c10_numero_oc,   c10_estado,    c10_moneda,  c10_fecing,	
	             c10_tipo_orden,  c10_cod_depto, c10_codprov, c10_atencion, 
		     c10_porc_descto, c10_recargo,   c10_solicitado,
	             c10_ord_trabajo, c10_tipo_pago, c10_referencia, c10_usuario,
			c10_numprof
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		
		IF INFIELD(c10_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc,
						     0, 0, 'T','00','T')
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
			CALL fl_ayuda_tipos_ordenes_compras('T')
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

		AFTER FIELD c10_tipo_pago
			LET rm_c10.c10_tipo_pago = get_fldbuf(c10_tipo_pago)
			IF vg_gui = 0 THEN
				IF rm_c10.c10_tipo_pago IS NOT NULL THEN
	             		     CALL muestra_tipopago(rm_c10.c10_tipo_pago)
				ELSE
					CLEAR tit_tipo_pago
				END IF
			END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'c10_numero_oc = ',vg_num_ord 
END IF

IF expr_sql_2 IS NOT NULL THEN
	LET expr_sql = expr_sql CLIPPED || ' AND ' || expr_sql_2
END IF

LET query = 'SELECT *, ROWID FROM ordt010 ',
		' WHERE c10_compania  = ', vg_codcia,
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
	CALL control_DISPLAY_botones()
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
LET valor_fact  = vm_subtotal - rm_c10.c10_tot_dscto + rm_c10.c10_otros +
		  rm_c10.c10_dif_cuadre

	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_c10.c10_numero_oc, rm_c10.c10_estado,  rm_c10.c10_moneda,
		rm_c10.c10_porc_impto,rm_c10.c10_fecing,  rm_c10.c10_tipo_orden,
 		rm_c10.c10_cod_depto, rm_c10.c10_porc_descto,rm_c10.c10_codprov,
		rm_c10.c10_recargo,    rm_c10.c10_atencion, 
		rm_c10.c10_ord_trabajo,rm_c10.c10_tot_dscto, vm_subtotal, 
		rm_c10.c10_tipo_pago,  rm_c10.c10_referencia, 
		rm_c10.c10_solicitado, rm_c10.c10_tot_compra, 
		rm_c10.c10_tot_impto,  rm_c10.c10_flete, rm_c10.c10_otros,
		valor_fact, rm_c10.c10_dif_cuadre, rm_c10.c10_usuario,
		rm_c10.c10_numprof

IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(500)

DEFINE cont 		SMALLINT
DEFINE v_impto		LIKE ordt011.c11_val_impto
DEFINE val_impto	LIKE ordt011.c11_val_impto

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	INITIALIZE r_detalle_1[i].* TO NULL
	--CLEAR r_detalle[i].*
END FOR

LET query = 'SELECT c11_tipo, c11_cant_ped, c11_codigo, c11_descrip,',
		' c11_descuento, c11_precio, ',
		' c11_precio * c11_cant_ped, c11_paga_iva, ',
		' c11_val_impto', 
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
	CALL control_DISPLAY_botones()
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
LET vm_num_detalles = i
LET vm_curr_arr = 0
LET vm_ini_arr  = 0

CALL control_mostrar_sig_det()

END FUNCTION



FUNCTION muestra_contadores()

IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 
END IF

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
	WHEN 'E'
		DISPLAY 'ELIMINADO' TO tit_estado
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



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 4
END IF

END FUNCTION



FUNCTION retorna_tam_arr2()

--#LET vm_size_arr = fgl_scr_size('r_detalle_2')
IF vg_gui = 0 THEN
	LET vm_size_arr = 7
END IF

END FUNCTION



FUNCTION muestra_tipopago(tipopago)
DEFINE tipopago		CHAR(1)

CASE tipopago
	WHEN 'C'
		DISPLAY 'CONTADO' TO tit_tipo_pago
	WHEN 'R'
		DISPLAY 'CREDITO' TO tit_tipo_pago
	OTHERWISE
		CLEAR c10_tipo_pago, tit_tipo_pago
END CASE

END FUNCTION



FUNCTION control_elimina_oc()
DEFINE resp		VARCHAR(6)

CALL fl_hacer_pregunta('Seguro de eliminar la orden','No')
	RETURNING resp
IF resp = 'No' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE qu_by CURSOR FOR
	SELECT * FROM ordt010
		WHERE c10_compania  = rm_c10.c10_compania 
	  	  AND c10_localidad = rm_c10.c10_localidad
	          AND c10_numero_oc = rm_c10.c10_numero_oc
		FOR UPDATE
OPEN qu_by
FETCH qu_by INTO rm_c10.*
IF status = NOTFOUND THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('La orden de compra esta siendo modificada por otro usuario.','exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
IF rm_c10.c10_estado <> 'A' THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET rm_c10.c10_estado = 'E'
DISPLAY BY NAME rm_c10.c10_estado
UPDATE ordt010 SET c10_estado = 'E'
	WHERE CURRENT OF qu_by
--CALL muestra_etiquetas()
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('Registro Eliminado OK.', 'info')
COMMIT WORK

END FUNCTION	



FUNCTION imprimir_orden()
DEFINE param		VARCHAR(100)

LET param = vg_codloc, ' ', rm_c10.c10_numero_oc
CALL ejecuta_comando('COMPRAS', vg_modulo, 'ordp400', param)

END FUNCTION	



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION tiene_stock_local(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE stock		LIKE rept011.r11_stock_act

LET stock = 0
SELECT NVL(SUM(r11_stock_act), 0)
	INTO stock
	FROM rept011, rept002
	WHERE r11_compania   = vg_codcia
	  AND r11_item       = item
	  AND r11_stock_act  > 0
	  AND r02_compania   = r11_compania
	  AND r02_codigo     = r11_bodega
	  AND r02_tipo      <> 'S'
	  AND r02_localidad IN
		(SELECT UNIQUE a.g02_localidad
			FROM gent002 a
			WHERE a.g02_compania  = r02_compania
			  AND a.g02_localidad = r02_localidad
			  AND a.g02_ciudad    =
				(SELECT b.g02_ciudad
					FROM gent002 b
					WHERE b.g02_compania  = a.g02_compania
					  AND b.g02_localidad = vg_codloc))
RETURN stock

END FUNCTION



FUNCTION lee_oc_proforma()
DEFINE r_c10		RECORD LIKE ordt010.*

INITIALIZE r_c10.* TO NULL
DECLARE q_oc_prof CURSOR FOR
	SELECT * FROM ordt010
		WHERE c10_compania  = vg_codcia
		  AND c10_localidad = vg_codloc
		  AND c10_numprof   = vm_numprof
OPEN q_oc_prof
FETCH q_oc_prof INTO r_c10.*
CLOSE q_oc_prof
FREE q_oc_prof
RETURN r_c10.*

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
DISPLAY '<F5>      Ver Bien'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

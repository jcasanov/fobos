--------------------------------------------------------------------------------
-- Titulo           : cxpp210.4gl - Ingreso de Facturas
-- Elaboracion      : 25-Jun-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp210 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows			ARRAY[1000] OF INTEGER
DEFINE vm_row_current		SMALLINT
DEFINE vm_num_rows		SMALLINT
DEFINE vm_max_rows		SMALLINT
DEFINE vm_num_detalles		SMALLINT
DEFINE vm_max_detalle		SMALLINT
DEFINE vm_num_recep		SMALLINT
DEFINE rm_r10		 	RECORD LIKE rept010.*	-- MAESTRO DE ITEMS
DEFINE rm_c01		 	RECORD LIKE ordt001.*	-- TIPO DE O.C.
DEFINE rm_c10		 	RECORD LIKE ordt010.*	-- CABECERA
DEFINE rm_c11		 	RECORD LIKE ordt011.*	-- DETALLE
DEFINE rm_c12		 	RECORD LIKE ordt012.*	-- FORMA DE PAGO
DEFINE rm_c13		 	RECORD LIKE ordt013.*
DEFINE rm_g34		 	RECORD LIKE gent034.*	-- DEPARTAMENTOS
DEFINE rm_p01		 	RECORD LIKE cxpt001.*	-- PROVEEDORES
DEFINE rm_t23		 	RECORD LIKE talt023.*	-- ORDENES DE TRABAJO
DEFINE rm_g13		 	RECORD LIKE gent013.*	-- MONEDAS
DEFINE rm_g14		 	RECORD LIKE gent014.*	-- CONVERSION MONEDAS
DEFINE rm_b00		 	RECORD LIKE ctbt000.*
DEFINE r_detalle	ARRAY[250] OF RECORD
				c11_tipo	LIKE ordt011.c11_tipo,
				c11_cant_ped	LIKE ordt011.c11_cant_ped,
				c11_codigo	LIKE ordt011.c11_codigo,
				c11_descrip	LIKE ordt011.c11_descrip,
				c11_descuento	LIKE ordt011.c11_descuento,
				c11_precio	LIKE ordt011.c11_precio,
				subtotal	DECIMAL(12,2),
				paga_iva	LIKE ordt011.c11_paga_iva
			END RECORD
DEFINE vm_size_arr	INTEGER
DEFINE r_detalle_2	ARRAY[250] OF RECORD
				c12_dividendo	LIKE ordt012.c12_dividendo,
				c12_fecha_vcto	LIKE ordt012.c12_fecha_vcto,
				c12_valor_cap	LIKE ordt012.c12_valor_cap,
				c12_valor_int	LIKE ordt012.c12_valor_int,
				subtotal	LIKE ordt012.c12_valor_cap
			END RECORD
DEFINE r_detalle_6	ARRAY[250] OF RECORD
				c14_cantidad	LIKE ordt014.c14_cantidad,
				c14_codigo	LIKE ordt014.c14_codigo,
				c14_descrip	LIKE ordt014.c14_descrip,
				c14_descuento	LIKE ordt014.c14_descuento,
				c14_precio	LIKE ordt014.c14_precio
			END RECORD
DEFINE vm_size_arr2	INTEGER
DEFINE vm_subtotal	LIKE ordt010.c10_tot_repto
DEFINE vm_subtotal_2	LIKE ordt010.c10_tot_repto
DEFINE r_detalle_1	ARRAY[250] OF RECORD
				c11_tipo	LIKE ordt011.c11_tipo,
				c11_val_descto	LIKE ordt011.c11_val_descto
			END RECORD
	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle_3 ARRAY[250] OF RECORD
	c11_cant_ped		LIKE ordt011.c11_cant_ped,
	c14_cantidad		LIKE ordt014.c14_cantidad,
	c14_codigo		LIKE ordt014.c14_codigo,
	c14_descrip		LIKE ordt014.c14_descrip,
	c14_descuento		LIKE ordt014.c14_descuento,
	c14_precio		LIKE ordt014.c14_precio,
	paga_iva		LIKE ordt011.c11_paga_iva
	END RECORD

	---- ARREGLO PARA LA FORMA DE PAGO ----
DEFINE r_detalle_4 ARRAY[250] OF RECORD
	c15_dividendo		LIKE ordt015.c15_dividendo,
	c15_fecha_vcto		LIKE ordt015.c15_fecha_vcto,
	c15_valor_cap		LIKE ordt015.c15_valor_cap,
	c15_valor_int		LIKE ordt015.c15_valor_int,
	subtotal		LIKE ordt015.c15_valor_cap
	END RECORD
-------------------------------------------------------

DEFINE r_detalle_5 ARRAY[250] OF RECORD
	c11_tipo		LIKE ordt011.c11_tipo,
	c14_val_descto		LIKE ordt014.c14_val_descto
	END RECORD
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
DEFINE rm_c00		RECORD LIKE ordt000.*	-- CONFIGURACION DE OC
DEFINE rm_c14	 	RECORD LIKE ordt014.*	-- DETALLE RECEPCION
DEFINE rm_c15	 	RECORD LIKE ordt015.*	-- PAGOS
DEFINE rm_b12	 	RECORD LIKE ctbt012.*

DEFINE vm_impuesto		LIKE ordt010.c10_porc_impto
DEFINE vm_moneda		LIKE ordt010.c10_moneda

DEFINE vm_flag_forma_pago	CHAR(1)		-- S o N o Y.. ok

---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE FORMA DE PAGO ----

DEFINE tot_recep		LIKE ordt010.c10_tot_compra
---------------------------------------------------------------

DEFINE iva_bien 	DECIMAL(11,2)	
DEFINE iva_servi	DECIMAL(11,2)	
DEFINE val_bienes	LIKE rept019.r19_tot_bruto
DEFINE val_servi	LIKE rept019.r19_tot_bruto
DEFINE val_impto	LIKE rept019.r19_tot_dscto
DEFINE val_pagar	LIKE rept019.r19_tot_neto
DEFINE tot_ret		LIKE rept019.r19_tot_neto
DEFINE vm_nota_credito  LIKE cxct021.z21_tipo_doc
DEFINE vm_fact_nue	LIKE ordt013.c13_factura
DEFINE fecha_tope		LIKE ctbt000.b00_fecha_cm
---------------------------------------------------------------



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_num_ord = arg_val(5)

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
OPEN WINDOW w_cxpp210 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf210_1 FROM '../forms/cxpf210_1'
ELSE
	OPEN FORM f_cxpf210_1 FROM '../forms/cxpf210_1c'
END IF
DISPLAY FORM f_cxpf210_1

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
LET vm_num_rows = 0
LET vm_row_current = 0

INITIALIZE rm_c10.*, rm_c11.* TO NULL

CALL muestra_contadores()

CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
LET fecha_tope = rm_b00.b00_fecha_cm + 1 UNITS MONTH
IF fecha_tope < rm_b00.b00_periodo_ini THEN
	LET fecha_tope = rm_b00.b00_periodo_ini
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Forma de Pago'
                HIDE OPTION 'Ver Recepción'
                HIDE OPTION 'Ver Anulación'
		IF NOT tiene_ice() THEN
                	HIDE OPTION 'Base ICE'
		ELSE
                	SHOW OPTION 'Base ICE'
		END IF
                HIDE OPTION 'Imprimir'
                HIDE OPTION 'Eliminacion'
		IF num_args() = 5 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			SHOW OPTION 'Imprimir'
			IF NOT tiene_ice() THEN
        	        	HIDE OPTION 'Base ICE'
			ELSE
                		SHOW OPTION 'Base ICE'
			END IF
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
		END IF 

	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
                CALL control_ingreso()
                HIDE OPTION 'Ver Recepción'
               	HIDE OPTION 'Ver Anulación'
                HIDE OPTION 'Eliminacion'
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Imprimir'
			IF NOT tiene_ice() THEN
        	        	HIDE OPTION 'Base ICE'
			ELSE
                		SHOW OPTION 'Base ICE'
			END IF
			IF rm_c10.c10_tipo_pago = 'R' THEN
				SHOW OPTION 'Forma de Pago'
			ELSE 
				HIDE OPTION 'Forma de Pago'
			END IF
		END IF
                IF vm_row_current > 1 THEN
                        SHOW OPTION 'Retroceder'
                END IF
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                END IF
                IF vm_row_current >= 1 THEN
			IF rm_c10.c10_estado = 'C' THEN
				SHOW OPTION 'Ver Recepción'
				SHOW OPTION 'Eliminacion'
        	       		HIDE OPTION 'Ver Anulación'
			ELSE
				HIDE OPTION 'Eliminacion'
				HIDE OPTION 'Ver Recepción'
	               		SHOW OPTION 'Ver Anulación'
			END IF
		END IF

        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
                CALL control_consulta()
		IF num_args() = 5 THEN
			SHOW OPTION 'Imprimir'
			IF NOT tiene_ice() THEN
        	        	HIDE OPTION 'Base ICE'
			ELSE
                		SHOW OPTION 'Base ICE'
			END IF
		END IF
		IF vm_num_rows > 0 THEN
			IF rm_c10.c10_tipo_pago = 'R' THEN
				SHOW OPTION 'Forma de Pago'
			ELSE
				HIDE OPTION 'Forma de Pago'
			END IF
			IF rm_c10.c10_estado <> 'A' THEN
				CALL control_cargar_recepciones(1)
				IF vm_num_recep <> 0 THEN
					SHOW OPTION 'Eliminacion'
					SHOW OPTION 'Ver Recepción'
               				HIDE OPTION 'Ver Anulación'
				ELSE
					HIDE OPTION 'Eliminacion'
					HIDE OPTION 'Ver Recepción'
               				SHOW OPTION 'Ver Anulación'
				END IF
			ELSE
				HIDE OPTION 'Eliminacion'
                        	HIDE OPTION 'Ver Recepción'
               			HIDE OPTION 'Ver Anulación'
				CALL control_cargar_recepciones(2)
				IF vm_num_recep <> 0 THEN
        	       			SHOW OPTION 'Ver Anulación'
				END IF
			END IF
		END IF
                IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Imprimir'
			IF NOT tiene_ice() THEN
        	        	HIDE OPTION 'Base ICE'
			ELSE
                		SHOW OPTION 'Base ICE'
			END IF
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Forma de Pago'
				HIDE OPTION 'Imprimir'
				IF NOT tiene_ice() THEN
        		        	HIDE OPTION 'Base ICE'
				ELSE
                			SHOW OPTION 'Base ICE'
				END IF
                        	HIDE OPTION 'Ver Recepción'
                        END IF
                ELSE
			SHOW OPTION 'Imprimir'
			IF NOT tiene_ice() THEN
        	        	HIDE OPTION 'Base ICE'
			ELSE
                		SHOW OPTION 'Base ICE'
			END IF
                        SHOW OPTION 'Avanzar'
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF

	COMMAND KEY('E') 'Eliminacion' 'Elimina la factura actual.'
		CALL control_eliminacion()
                IF vm_row_current >= 1 THEN
			IF rm_c10.c10_estado <> 'E' THEN
				SHOW OPTION 'Ver Recepción'
				SHOW OPTION 'Eliminacion'
        	       		HIDE OPTION 'Ver Anulación'
			ELSE
				HIDE OPTION 'Eliminacion'
				HIDE OPTION 'Ver Recepción'
	               		SHOW OPTION 'Ver Anulación'
			END IF
		END IF

	COMMAND KEY('F') 'Forma de Pago' 'Para ordenes de compra a crédito.'
		IF vm_num_rows > 0 THEN
			CALL control_forma_pago()
			IF num_args() = 4 THEN
				CALL lee_muestra_registro(vm_rows[vm_row_current])
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

        COMMAND KEY('Y') 'Base ICE'      'Muestra los datos para calculo ICE.'
		CALL control_ice(1)

        COMMAND KEY('K') 'Imprimir'      'Imprime la Orden de Compra.'
		IF vm_num_rows > 0 THEN
			CALL imprimir_orden()
		END IF

	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Imprimir'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
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
                       	HIDE OPTION 'Ver Recepción'
               		HIDE OPTION 'Ver Anulación'
			CALL control_cargar_recepciones(2)
			IF vm_num_recep <> 0 THEN
               			SHOW OPTION 'Ver Anulación'
			END IF
		END IF
		IF NOT tiene_ice() THEN
                	HIDE OPTION 'Base ICE'
		ELSE
                	SHOW OPTION 'Base ICE'
		END IF

	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Imprimir'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		HIDE OPTION 'Forma de Pago'
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
                       	HIDE OPTION 'Ver Recepción'
               		HIDE OPTION 'Ver Anulación'
			CALL control_cargar_recepciones(2)
			IF vm_num_recep <> 0 THEN
               			SHOW OPTION 'Ver Anulación'
			END IF
		END IF
		IF NOT tiene_ice() THEN
                	HIDE OPTION 'Base ICE'
		ELSE
                	SHOW OPTION 'Base ICE'
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
CALL ejecuta_comando('COMPRAS', 'OC', prog, param)

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
LET i = vm_ini_arr
IF vm_curr_arr <= filas_pant THEN
	LET i = 0
END IF

END FUNCTION



FUNCTION control_forma_pago()
DEFINE i 	SMALLINT

IF rm_c10.c10_tipo_pago = 'C' THEN
	CALL fl_mostrar_mensaje('La forma de pago solo para ordenes de compra a crédito.','exclamation')
	RETURN
END IF

OPEN WINDOW w_200_2 AT 6, 8 WITH 16 ROWS, 71 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
IF vg_gui = 1 THEN
	OPEN FORM f_200_2 FROM '../../COMPRAS/forms/ordf200_2'
ELSE
	OPEN FORM f_200_2 FROM '../../COMPRAS/forms/ordf200_2c'
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
		CALL fl_mostrar_mensaje('La orden de compra esta siendo modificada por otro usuario.','exclamation')
		WHENEVER ERROR STOP
		CLOSE WINDOW w_200_2
		RETURN
	END IF

END IF

LET tot_compra         = rm_c10.c10_tot_compra

DISPLAY BY NAME tot_compra, rm_c10.c10_interes

LET i = control_cargar_forma_pago_oc()

LET i = 1

IF vm_flag_mant <> 'I' THEN
	ROLLBACK WORK
	LET i = control_cargar_forma_pago_oc()
	CALL control_DISPLAY_ordt012(i)
	WHENEVER ERROR STOP
	CLOSE WINDOW w_200_2
	RETURN
END IF

IF i = 1 THEN
	LET pagos      = 1 
	LET fecha_pago = vg_fecha + 30
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


END FUNCTION



FUNCTION control_ingreso_forma_pago_oc()

LET int_flag = 0
INPUT BY NAME pagos, rm_c10.c10_interes, fecha_pago, dias_pagos 
	      WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mostrar_mensaje('Debe especificar la forma de pago de esta orden de compra.','exclamation')
		CONTINUE INPUT
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
		
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD fecha_pago
		IF fecha_pago < vg_fecha THEN
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
			CALL fl_mostrar_mensaje('Debe ingresar el número de pagos para generar el detalle.','exclamation')
			NEXT FIELD pagos
		END IF
			
		IF fecha_pago IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar la fecha del primer pago de la orden de compra.','exclamation')
			NEXT FIELD fecha_pago
		END IF

		IF dias_pagos IS NULL THEN
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
					CALL fl_mostrar_mensaje('Existen fechas que resultan menores a las ingresadas anteriormente en los pagos.','exclamation')
					EXIT INPUT
				END IF
			END FOR	

			IF tot_cap > tot_compra THEN
				CALL fl_mostrar_mensaje('El total del valor capital es mayor al total de la deuda.','exclamation')
				EXIT INPUT
			END IF

			IF tot_cap < tot_compra THEN
				CALL fl_mostrar_mensaje('El total del valor capital es menor al total de la deuda.','exclamation')
				EXIT INPUT
			END IF

			LET tot_dias = r_detalle_2[pagos].c12_fecha_vcto - vg_fecha 	
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
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT

CLEAR FORM

LET vm_flag_mant = 'I'
INITIALIZE rm_c10.*, rm_c11.*, rm_c13.* TO NULL

-- INITIAL VALUES FOR rm_c10 FIELDS
--LET rm_c10.c10_tipo_pago   = 'C'
LET rm_c10.c10_tipo_pago   = 'R'
IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF
LET rm_c10.c10_recargo     = 0
LET rm_c10.c10_estado      = 'A'
LET rm_c10.c10_fecing      = fl_current()
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
LET rm_c10.c10_base_ice    = 0
LET rm_c10.c10_valor_ice   = 0
LET rm_c10.c10_sustento_sri = 'S'
LET rm_c10.c10_porc_impto  = rg_gen.g00_porc_impto
LET vm_impuesto            = rm_c10.c10_porc_impto
LET vm_moneda              = rm_c10.c10_moneda
LET rm_c10.c10_atencion    = '.'
LET rm_c10.c10_solicitado  = '.'
LET valor_fact             = 0
LET vm_num_detalles        = 0

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING rm_g13.*
LET rm_c10.c10_precision = rm_g13.g13_decimales

DISPLAY BY NAME rm_c10.c10_moneda, rm_c10.c10_porc_impto, rm_c10.c10_fecing,
		rm_c10.c10_estado	

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
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET vm_num_detalles                          = 1
LET r_detalle[vm_num_detalles].c11_tipo      = 'B'
LET r_detalle[vm_num_detalles].c11_cant_ped  = 1
LET r_detalle[vm_num_detalles].c11_codigo    = 'GASTOS'
LET r_detalle[vm_num_detalles].c11_descrip   = rm_c10.c10_referencia CLIPPED
LET r_detalle[vm_num_detalles].c11_descuento = 0
LET r_detalle[vm_num_detalles].c11_precio    = valor_fact
LET r_detalle[vm_num_detalles].subtotal      = valor_fact
LET r_detalle[vm_num_detalles].paga_iva      = 'S'
LET r_detalle_1[vm_num_detalles].c11_tipo    = 'B'
LET r_detalle_1[vm_num_detalles].c11_val_descto = 0

	-- ACTUALIZO LOS VALORES DEFAULTS QUE INGRESE AL INICIO DE LEE DATOS --

BEGIN WORK

	LET done = control_insert_ordt010()
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso de la cabecera de la orden de compra (Faltan los sustentos tributarios) no se realizara el proceso.','exclamation')
		IF vm_num_rows <= 1 THEN
			LET vm_num_rows = 0
			LET vm_row_current = 0
			CLEAR FORM
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
		CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso del detalle de la orden de compra no se realizara el proceso.','exclamation')
		IF vm_num_rows <= 1 THEN
			LET vm_num_rows = 0
			LET vm_row_current = 0
			CLEAR FORM
		ELSE
			LET vm_num_rows = vm_num_rows - 1
			LET vm_row_current = vm_num_rows
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
COMMIT WORK

IF rm_c10.c10_tipo_pago = 'R' THEN
	CALL control_forma_pago()
END IF

CALL muestra_contadores()
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL control_recepcion() RETURNING done
CALL control_grabar() RETURNING done
CALL imprimir_orden()
CALL lee_muestra_registro(vm_rows[vm_row_current])
LET vm_flag_mant = 'C'
CALL fl_mensaje_registro_ingresado()

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



FUNCTION control_insert_ordt010()
DEFINE i,done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE numprev          INTEGER
DEFINE r_s23		RECORD LIKE srit023.*

LET done = 1
LET rm_c10.c10_fecing = fl_current()

LET rm_c10.c10_numero_oc = genera_secuencia_oc()

--WHENEVER ERROR CONTINUE
WHENEVER ERROR STOP

LET rm_c10.c10_estado      = 'P'
LET rm_c10.c10_usua_aprob  = vg_usuario
LET rm_c10.c10_fecha_aprob = fl_current()
LET rm_c10.c10_dif_cuadre  = 0
CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
				rm_c10.c10_sustento_sri)
	RETURNING r_s23.*
IF r_s23.s23_compania IS NULL THEN
	RETURN 0
END IF
LET rm_c10.c10_cod_sust_sri = r_s23.s23_sustento_sri
INSERT INTO ordt010 VALUES (rm_c10.*)
DISPLAY BY NAME rm_c10.c10_numero_oc

IF status < 0 THEN
	WHENEVER ERROR STOP
	LET rm_c10.c10_numero_oc   = genera_secuencia_oc()
	LET rm_c10.c10_estado      = 'P'
	LET rm_c10.c10_usua_aprob  = vg_usuario
	LET rm_c10.c10_fecha_aprob = fl_current()
	LET rm_c10.c10_dif_cuadre  = 0
	CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
					rm_c10.c10_sustento_sri)
		RETURNING r_s23.*
	IF r_s23.s23_compania IS NULL THEN
		RETURN 0
	END IF
LET rm_c10.c10_cod_sust_sri = r_s23.s23_sustento_sri
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
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_s23_s		RECORD LIKE srit023.*
DEFINE r_s23_n		RECORD LIKE srit023.*
DEFINE otros		LIKE ordt010.c10_otros
DEFINE flete		LIKE ordt010.c10_flete
DEFINE resp 		CHAR(6)
DEFINE done, lim	SMALLINT
DEFINE mensaje		VARCHAR(200)

LET int_flag = 0
CALL calcula_totales(vm_num_detalles,1)
DISPLAY BY NAME rm_c10.c10_usuario
INPUT BY NAME rm_c10.c10_codprov, rm_c13.c13_num_guia, rm_c13.c13_fec_emi_fac,
	rm_c13.c13_num_aut, rm_c13.c13_fecha_cadu,
	rm_c10.c10_tipo_orden, rm_c10.c10_porc_impto, rm_c10.c10_sustento_sri,
	rm_c10.c10_referencia, rm_c10.c10_cod_depto, valor_fact,
	rm_c10.c10_otros, rm_c10.c10_flete
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_c10.c10_codprov, rm_c13.c13_num_guia,
				rm_c13.c13_fec_emi_fac, rm_c13.c13_num_aut,
				rm_c13.c13_fecha_cadu, rm_c10.c10_tipo_orden,
				rm_c10.c10_porc_impto, rm_c10.c10_codprov,
				rm_c10.c10_sustento_sri,
				rm_c10.c10_referencia, rm_c10.c10_cod_depto,
				valor_fact, rm_c10.c10_otros, rm_c10.c10_flete)
		THEN
			RETURN
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
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
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING rm_p01.p01_codprov, 
					  rm_p01.p01_nomprov
			IF rm_p01.p01_codprov IS NOT NULL THEN
				LET rm_c10.c10_codprov = rm_p01.p01_codprov
				DISPLAY BY NAME rm_c10.c10_codprov
				DISPLAY rm_p01.p01_nomprov TO nom_proveedor
			END IF
		END IF
		IF INFIELD(c10_tipo_orden) THEN
			CALL fl_ayuda_tipo_factura_cxp()
				RETURNING rm_c01.c01_tipo_orden,
					  rm_c01.c01_nombre
			IF rm_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_c10.c10_tipo_orden =rm_c01.c01_tipo_orden
				DISPLAY BY NAME rm_c10.c10_tipo_orden
				DISPLAY rm_c01.c01_nombre TO nom_tipo_orden
			END IF 
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF NOT tiene_ice() THEN
			--#CALL dialog.keysetlabel("F5","")
		ELSE
			--#CALL dialog.keysetlabel("F5","Calcular ICE")
			CALL control_ice(0)
			CALL calcula_totales(vm_num_detalles,1)
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel("F5","")
	AFTER FIELD c13_num_guia
		IF LENGTH(rm_c13.c13_num_guia) < 14 THEN
			CALL fl_mostrar_mensaje('El número del documento ingresado es incorrecto.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF rm_c13.c13_num_guia[4, 4] <> '-' OR
		   rm_c13.c13_num_guia[8, 8] <> '-' THEN
			CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF LENGTH(rm_c13.c13_num_guia[1, 7]) <> 7 THEN
			CALL fl_mostrar_mensaje('Digite correctamente el punto de venta o el punto de emision.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		LET rm_c13.c13_serie_comp = rm_c13.c13_num_guia[1, 3],
						rm_c13.c13_num_guia[5, 7]
		IF rm_c13.c13_num_guia[1, 3] <> rm_c13.c13_serie_comp[1, 3] THEN
			CALL fl_mostrar_mensaje('El prefijo del local es diferente que el de la serie del comprobante.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF rm_c13.c13_num_guia[5, 7] <> rm_c13.c13_serie_comp[4, 6] THEN
			CALL fl_mostrar_mensaje('El prefijo de venta es diferente que el de la serie del comprobante.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF NOT fl_valida_numeros(rm_c13.c13_num_guia[1, 3]) THEN
			NEXT FIELD c13_num_guia
		END IF
		IF NOT fl_valida_numeros(rm_c13.c13_num_guia[5, 7]) THEN
			NEXT FIELD c13_num_guia
		END IF
		LET lim = LENGTH(rm_c13.c13_num_guia)
		IF NOT fl_valida_numeros(rm_c13.c13_num_guia[9, lim]) THEN
			NEXT FIELD c13_num_guia
		END IF
		CALL retorna_num_aut()

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
			CALL fl_mostrar_mensaje('Este no es un porcentaje de impuesto valido.','exclamation')
			NEXT FIELD c10_porc_impto
		END IF
		CALL calcula_totales(vm_num_detalles,1)

	BEFORE FIELD c10_tipo_orden
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF

	AFTER FIELD c10_tipo_orden
		IF rm_c10.c10_tipo_orden IS NOT NULL THEN
			CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden)
				RETURNING rm_c01.*
			IF rm_c01.c01_tipo_orden IS NULL THEN
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
			IF rm_c01.c01_modulo <> 'OC' AND
			   rm_c01.c01_modulo IS NOT NULL
			THEN
				CALL fl_mostrar_mensaje('Debe escojer un tipo de factura de Compras o de Tesoreria.', 'exclamation')
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
			IF NOT tiene_ice() THEN
				--#CALL dialog.keysetlabel("F5","")
			ELSE
				--#CALL dialog.keysetlabel("F5","Calcular ICE")
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
				CALL fl_mostrar_mensaje('No existe el proveedor en la Compañía.','exclamation')
				NEXT FIELD c10_codprov
			END IF
			DISPLAY rm_p01.p01_nomprov TO nom_proveedor
			IF rm_c13.c13_num_aut IS NULL THEN
				LET rm_c13.c13_serie_comp = rm_p01.p01_serie_comp
				CALL retorna_num_aut()
				DISPLAY BY NAME rm_c13.c13_num_aut
			END IF
			IF rm_p01.p01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD c10_codprov
			END IF
		ELSE	
			CLEAR nom_proveedor
		END IF

	AFTER FIELD valor_fact
		IF valor_fact IS NULL OR valor_fact <= 0 THEN
			LET valor_fact = vm_subtotal - rm_c10.c10_tot_dscto + rm_c10.c10_otros
			DISPLAY BY NAME valor_fact 
		END IF
		CALL calcula_totales(vm_num_detalles,1)
	BEFORE FIELD c10_otros
		LET otros = rm_c10.c10_otros
	BEFORE FIELD c10_flete
		LET flete = rm_c10.c10_flete
	AFTER FIELD c10_otros, c10_flete
		IF rm_c10.c10_otros IS NULL THEN
			LET rm_c10.c10_otros = otros
			DISPLAY BY NAME rm_c10.c10_otros
		END IF
		IF rm_c10.c10_flete IS NULL THEN
			LET rm_c10.c10_flete = flete
			DISPLAY BY NAME rm_c10.c10_flete
		END IF
		CALL calcula_totales(vm_num_detalles,1)
	AFTER FIELD c13_fecha_cadu
		IF rm_c13.c13_fecha_cadu IS NULL THEN
			NEXT FIELD c13_fecha_cadu
		END IF
		IF rm_c13.c13_fecha_cadu IS NOT NULL THEN
			DISPLAY BY NAME rm_c13.c13_fecha_cadu
		END IF
	AFTER FIELD c13_fec_emi_fac
		IF rm_c13.c13_fec_emi_fac < fecha_tope THEN
			LET mensaje = 'La fecha de emisión de factura no puede ser menor',
							' que la fecha: ', fecha_tope USING "dd-mm-yyyy",
							' del modulo de Contabilidad.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD c13_fec_emi_fac
		END IF
	AFTER FIELD c13_num_aut
		IF rm_c13.c13_num_aut IS NULL THEN
			CALL retorna_num_aut()
		END IF
		IF (LENGTH(rm_c13.c13_num_aut) <> 10 AND
			LENGTH(rm_c13.c13_num_aut) <> 37 AND
			LENGTH(rm_c13.c13_num_aut) <> 47 AND
			LENGTH(rm_c13.c13_num_aut) <> 49)
		THEN
			CALL fl_mostrar_mensaje('El número de autorización debe ser el número electrónico o bien el número específico de 10 digitos.', 'exclamation')
			NEXT FIELD c13_num_aut
		END IF
		IF NOT fl_valida_numeros(rm_c13.c13_num_aut) THEN
			NEXT FIELD c13_num_aut
		END IF
	AFTER INPUT
		IF valor_fact IS NULL OR valor_fact <= 0 THEN
			CALL fl_mostrar_mensaje('Digite subtotal antes del iva de la factura del proveedor.','exclamation')
			NEXT FIELD valor_fact
		END IF
		{
		IF rm_c01.c01_aux_cont IS NULL THEN
			IF rm_c10.c10_porc_impto <> 0 THEN
				LET rm_c10.c10_porc_impto = 0
				DISPLAY BY NAME rm_c10.c10_porc_impto
			END IF
		END IF
		}
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, 
						 rm_c10.c10_codprov, 'FA',
						 rm_c13.c13_num_guia, 1)
			RETURNING r_p20.*
		IF r_p20.p20_num_doc IS NOT NULL THEN
			CALL fl_mostrar_mensaje('La factura ya ha sido recibida.','exclamation')
			NEXT FIELD c13_num_guia
		END IF
		CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
						'S')
			RETURNING r_s23_s.*
		CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden,
						'N')
			RETURNING r_s23_n.*
		IF rm_c10.c10_sustento_sri = 'N' AND
		   r_s23_s.s23_compania IS NULL AND r_s23_n.s23_compania IS NULL
		THEN
			CALL fl_mostrar_mensaje('Este tipo de orden de compra no tiene ningun codigo de sustento tributario. POR FAVOR LLAME AL ADMINISTRADOR.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_c10.c10_sustento_sri = 'S' AND rm_c01.c01_aux_cont IS NULL
			AND r_s23_s.s23_aux_cont IS NULL
		THEN
			IF rm_c10.c10_porc_impto <> 0 THEN
				CALL fl_mostrar_mensaje('Este tipo de orden de compra no tiene ningun auxiliar contable para IVA. POR FAVOR LLAME AL ADMINISTRADOR.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF tiene_ice() THEN
			IF rm_c10.c10_base_ice = 0 THEN
				CALL control_ice(0)
				CALL calcula_totales(vm_num_detalles,1)
				IF rm_c10.c10_base_ice = 0 THEN
					CONTINUE INPUT
				END IF
			END IF
		END IF
		CALL calcula_totales(vm_num_detalles,1)
		IF rm_c13.c13_fecha_cadu IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la fecha de caducidad.', 'exclamation')
			NEXT FIELD c13_fecha_cadu
		END IF
		IF rm_c13.c13_fecha_cadu < vg_fecha THEN
			CALL fl_mostrar_mensaje('La fecha de caducidad no puede ser menor a la fecha de hoy.', 'exclamation')
			NEXT FIELD c13_fecha_cadu
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

CALL retorna_tam_arr()
LET vm_filas_pant  = vm_size_arr
LET rm_c10.c10_tot_compra = 0
LET i = 1
LET j = 1

INITIALIZE grupo_linea, bodega TO NULL
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

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*

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
LET rm_c10.c10_dif_cuadre  = valor_fact
LET rm_c10.c10_tot_repto   = valor_fact
LET rm_c10.c10_tot_mano    = 0	
LET rm_c10.c10_tot_dscto   = 0	
LET rm_c10.c10_tot_impto   = 0	
LET rm_c10.c10_tot_compra  = 0	
LET vm_subtotal		   = rm_c10.c10_dif_cuadre
LET vm_subtotal_2	   = rm_c10.c10_dif_cuadre
LET v_impto		   = 0	

LET indice = vm_num_detalles

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
	DISPLAY BY NAME valor_fact
END IF

LET rm_c10.c10_dif_cuadre = valor_fact - (vm_subtotal - rm_c10.c10_tot_dscto +
					rm_c10.c10_otros)

IF vm_calc_iva = 'S' THEN
	LET rm_c10.c10_tot_impto = (rm_c10.c10_tot_repto  + rm_c10.c10_tot_mano -
				    rm_c10.c10_tot_dscto  + rm_c10.c10_otros) * 
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
			    rm_c10.c10_otros + 
			    rm_c10.c10_tot_impto + rm_c10.c10_flete +
			    rm_c10.c10_valor_ice
DISPLAY BY NAME vm_subtotal,          rm_c10.c10_tot_dscto, 
		rm_c10.c10_tot_impto, rm_c10.c10_tot_compra

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(600)
DEFINE expr_sql_2	CHAR(600)
DEFINE query		CHAR(600)
DEFINE r_c10		RECORD LIKE ordt010.* 	-- CABECERA PROFORMA

INITIALIZE expr_sql_2 TO NULL
CLEAR FORM

LET vm_flag_mant = 'C'

LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON c10_numero_oc,   c10_estado,    c10_moneda,  c10_fecing,
		c10_codprov, c13_num_guia, c13_num_aut, c13_fecha_cadu,
		c10_tipo_orden,
		c10_porc_impto, c10_referencia, c10_cod_depto, c10_usuario,
		c10_otros, c10_flete
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
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING rm_p01.p01_codprov, 
					  rm_p01.p01_nomprov
			IF rm_p01.p01_codprov IS NOT NULL THEN
				LET rm_c10.c10_codprov = rm_p01.p01_codprov
				DISPLAY BY NAME rm_c10.c10_codprov
				DISPLAY rm_p01.p01_nomprov
			END IF
		END IF

		IF INFIELD(c10_tipo_orden) THEN
			CALL fl_ayuda_tipo_factura_cxp()
				RETURNING rm_c01.c01_tipo_orden,
					  rm_c01.c01_nombre
			IF rm_c01.c01_tipo_orden IS NOT NULL THEN
				LET rm_c10.c10_tipo_orden =rm_c01.c01_tipo_orden
				DISPLAY BY NAME rm_c10.c10_tipo_orden
				DISPLAY rm_c01.c01_nombre TO nom_tipo_orden
			END IF 
		END IF

		LET int_flag = 0

		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
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

LET query = 'SELECT ordt010.*, ordt010.ROWID ',
		' FROM ordt010, ordt013 ',
		' WHERE c10_compania  = ', vg_codcia,
		'   AND c10_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		'   AND c13_compania  = c10_compania ',
		'   AND c13_localidad = c10_localidad ',
		'   AND c13_numero_oc = c10_numero_oc ',
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
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE estado		CHAR(1)

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_c10.* FROM ordt010 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET vm_subtotal = rm_c10.c10_tot_repto + rm_c10.c10_tot_mano
LET valor_fact  = vm_subtotal - rm_c10.c10_tot_dscto + rm_c10.c10_otros 
LET estado = 'A'
IF rm_c10.c10_estado = 'E' THEN
	LET estado = rm_c10.c10_estado
END IF
DECLARE q_c13 CURSOR FOR
	SELECT * FROM ordt013
		WHERE c13_compania  = vg_codcia
		  AND c13_localidad = vg_codloc
		  AND c13_numero_oc = rm_c10.c10_numero_oc
		  AND c13_estado    = estado
		ORDER BY c13_num_recep DESC
OPEN q_c13
FETCH q_c13 INTO rm_c13.*
CLOSE q_c13
FREE q_c13

	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_c10.c10_numero_oc, rm_c10.c10_estado,  rm_c10.c10_moneda,
		rm_c10.c10_porc_impto,rm_c10.c10_fecing,  rm_c10.c10_tipo_orden,
 		rm_c10.c10_cod_depto, rm_c10.c10_codprov,
		rm_c10.c10_tot_dscto, rm_c10.c10_sustento_sri,
		rm_c10.c10_referencia, 
		rm_c10.c10_tot_compra, vm_subtotal,
		rm_c10.c10_tot_impto,  rm_c10.c10_flete, rm_c10.c10_otros,
		valor_fact, rm_c10.c10_usuario,
		rm_c13.c13_num_guia, rm_c13.c13_fec_emi_fac, rm_c13.c13_num_aut,
		rm_c13.c13_fecha_cadu

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

LET vm_ind_arr  = i
LET vm_num_detalles = i
LET vm_curr_arr = 0
LET vm_ini_arr  = 0

--CALL control_mostrar_sig_det()

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_current, vm_num_rows

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
		DISPLAY 'ACTIVA' TO tit_estado
	WHEN 'P'
		DISPLAY 'APROBADA' TO tit_estado
	WHEN 'C'
		DISPLAY 'CERRADA' TO tit_estado
	WHEN 'E'
		DISPLAY 'ELIMINADA' TO tit_estado
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



FUNCTION imprimir_orden()
DEFINE param		VARCHAR(100)

LET param = vg_codloc, ' ', rm_c10.c10_numero_oc
CALL ejecuta_comando('COMPRAS', 'OC', 'ordp400', param)

END FUNCTION	



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

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



FUNCTION control_recepcion()
DEFINE i 	SMALLINT

INITIALIZE rm_c00.*, rm_c14.*, vm_flag_forma_pago TO NULL
LET tot_ret = 0

LET rm_c13.c13_fecing  = fl_current()
LET rm_c13.c13_usuario = vg_usuario
LET rm_c13.c13_estado  = 'A'

BEGIN WORK
WHENEVER ERROR CONTINUE 
	DECLARE q_ordt010 CURSOR FOR 
		SELECT * FROM ordt010
			WHERE c10_compania  = vg_codcia	
			  AND c10_localidad = vg_codloc
			  AND c10_numero_oc = rm_c10.c10_numero_oc
		FOR UPDATE

OPEN q_ordt010 
FETCH q_ordt010 INTO rm_c10.*

IF STATUS < 0 THEN
	ROLLBACK WORK 
	INITIALIZE rm_c00.*, rm_c14.*, vm_flag_forma_pago TO NULL
	CALL fl_mostrar_mensaje('La orden de compra está siendo recibida por otro usuario.','exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP

CALL control_cargar_detalle()

IF vm_ind_arr = 0 THEN
	ROLLBACK WORK 
	INITIALIZE rm_c00.*, rm_c14.*, vm_flag_forma_pago TO NULL
	RETURN 0
END IF

IF rm_c01.c01_bien_serv = 'S' OR rm_c01.c01_bien_serv = 'T' THEN 

	FOR i = 1 TO  vm_ind_arr
		LET r_detalle_3[i].c14_cantidad = r_detalle_3[i].c11_cant_ped
	END FOR
	CALL calcula_totales_recep()
	LET vm_flag_forma_pago = 'N'
	LET int_flag = 0
	RETURN 1

END IF

RETURN 1

END FUNCTION



FUNCTION control_grabar()
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE estado  	 	LIKE ordt010.c10_estado
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

DEFINE fecha_actual DATETIME YEAR TO SECOND

LET fecha_actual = fl_current()

UPDATE ordt010 SET c10_estado      = 'C',
		   c10_factura     = rm_c13.c13_num_guia,
		   c10_fecha_fact  = vg_fecha,
		   c10_fecha_entre = fecha_actual	
	WHERE CURRENT OF q_ordt010 

CALL control_insert_ordt013()
CALL control_insert_ordt014()
CALL control_update_ordt011()
CALL control_cargar_detalle_ordt015()

IF rm_c10.c10_tipo_pago = 'R' THEN
	IF vm_flag_forma_pago = 'N' THEN
		CALL control_insert_ordt015_1()
	ELSE
		CALL control_insert_ordt015_2()
	END IF
END IF

-- SI la compra es al contado solo grabara un registro
CALL control_insert_cxpt020()

-- SI la compra local es al contado debe grabarse un ajuste
-- para darse de baja el documento
IF rm_c10.c10_tipo_pago = 'C' THEN
	CALL graba_ajuste_documento_contado()
END IF

CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_c10.c10_codprov)

INITIALIZE r_b12.* TO NULL

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*
IF r_c01.c01_modulo <> 'AF' OR r_c01.c01_modulo IS NULL THEN
	CALL contabilizacion_online() RETURNING r_b12.*
END IF
IF int_flag THEN
	RETURN 0
END IF
COMMIT WORK
IF r_b12.b12_compania IS NOT NULL AND r_b00.b00_mayo_online = 'S' THEN
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
				     r_b12.b12_num_comp, 'M')
END IF
IF r_b12.b12_compania IS NOT NULL THEN
	LET run_prog = '; fglrun '
	IF vg_gui = 0 THEN
		LET run_prog = '; fglgo '
	END IF
	CALL fl_hacer_pregunta('Desea ver contabilizacion generada?','No')
		RETURNING resp
	IF resp = 'Yes' THEN
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      			'CONTABILIDAD', vg_separador, 'fuentes',
	      			vg_separador, run_prog, 'ctbp201 ',
				vg_base, ' ', 'CB', vg_codcia, ' ',
				r_b12.b12_tipo_comp, ' ', 
				r_b12.b12_num_comp
		RUN comando
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION graba_ajuste_documento_contado()
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*

INITIALIZE r_p22.*, r_p23.* TO NULL

-- Graba Cabecera Ajuste Documento
LET r_p22.p22_compania   = vg_codcia
LET r_p22.p22_localidad  = vg_codloc
LET r_p22.p22_codprov    = rm_c10.c10_codprov
LET r_p22.p22_tipo_trn   = 'AJ'

LET r_p22.p22_referencia = 'RECEPCION ORDEN DE COMPRA # '|| rm_c13.c13_num_recep || ' PAGO CONTADO'
LET r_p22.p22_fecha_emi  = vg_fecha
LET r_p22.p22_moneda     = rm_c10.c10_moneda
LET r_p22.p22_paridad    = rm_c10.c10_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = (rm_c13.c13_tot_recep - tot_ret) * -1    --val_pagar
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'A'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = fl_current() + 1 UNITS SECOND

LET r_p22.p22_num_trn    = nextValInSequence('TE', r_p22.p22_tipo_trn)


INSERT INTO cxpt022 VALUES(r_p22.*)
--------------------------------------------------------------------------

LET r_p23.p23_compania  = r_p22.p22_compania
LET r_p23.p23_localidad = r_p22.p22_localidad
LET r_p23.p23_codprov   = r_p22.p22_codprov
LET r_p23.p23_tipo_trn  = r_p22.p22_tipo_trn
LET r_p23.p23_num_trn   = r_p22.p22_num_trn

LET r_p23.p23_tipo_doc   = 'FA'
LET r_p23.p23_num_doc    = rm_c13.c13_factura
LET r_p23.p23_div_doc    = 1		-- Un solo divividendo 
LET r_p23.p23_valor_int  = 0
LET r_p23.p23_valor_mora = 0
LET r_p23.p23_saldo_int  = 0
LET r_p23.p23_orden      = 1		-- Un solo detalle
LET r_p23.p23_valor_cap  = r_p22.p22_total_cap

SELECT p20_saldo_cap INTO r_p23.p23_saldo_cap
	FROM cxpt020
	WHERE p20_compania  = vg_codcia
	  AND p20_localidad = vg_codloc
	  AND p20_codprov   = r_p23.p23_codprov
	  AND p20_tipo_doc  = r_p23.p23_tipo_doc
	  AND p20_num_doc   = r_p23.p23_num_doc
	  AND p20_dividendo = r_p23.p23_div_doc
		  
LET val_pagar = rm_c13.c13_tot_recep
UPDATE cxpt020 SET p20_saldo_cap = 0
	--rm_c13.c13_tot_recep
	WHERE p20_compania  = vg_codcia
	  AND p20_localidad = vg_codloc
	  AND p20_codprov   = r_p23.p23_codprov
	  AND p20_tipo_doc  = r_p23.p23_tipo_doc
	  AND p20_num_doc   = r_p23.p23_num_doc
	  AND p20_dividendo = r_p23.p23_div_doc
	  
INSERT INTO cxpt023 VALUES(r_p23.*)

END FUNCTION



FUNCTION control_insert_ordt015_1()
DEFINE sql_expr		CHAR(300)

LET sql_expr = 'INSERT INTO ordt015 ',
	       '	SELECT c12_compania, c12_localidad, c12_numero_oc, ',
	         	       rm_c13.c13_num_recep, ', c12_dividendo, ', 
	       '   	       c12_fecha_vcto, c12_valor_cap, c12_valor_int ',
	       '	FROM ordt012 ',
	       '	WHERE c12_compania  = ', vg_codcia,
	       '	AND   c12_localidad = ', vg_codloc,
	       '	AND   c12_numero_oc = ', rm_c13.c13_numero_oc

PREPARE statement1 FROM sql_expr
EXECUTE statement1

END FUNCTION



FUNCTION control_insert_ordt013()

INITIALIZE rm_c13.c13_fecha_eli TO NULL

LET rm_c13.c13_compania    = vg_codcia
LET rm_c13.c13_localidad   = vg_codloc
LET rm_c13.c13_numero_oc   = rm_c10.c10_numero_oc
LET rm_c13.c13_fecing      = fl_current()
LET rm_c13.c13_fecha_recep = fl_current()
LET rm_c13.c13_factura     = rm_c13.c13_num_guia
LET rm_c13.c13_estado      = 'A'
LET rm_c13.c13_flete       = rm_c10.c10_flete
LET rm_c13.c13_otros       = rm_c10.c10_otros
LET rm_c13.c13_interes     = rm_c10.c10_interes
LET rm_c13.c13_tot_bruto   = rm_c10.c10_dif_cuadre
LET rm_c13.c13_tot_dscto   = rm_c10.c10_tot_dscto
LET rm_c13.c13_dif_cuadre  = rm_c10.c10_dif_cuadre
LET rm_c13.c13_tot_impto   = rm_c10.c10_tot_impto 
LET rm_c13.c13_tot_recep   = rm_c10.c10_tot_compra

SELECT MAX(c13_num_recep) + 1 INTO rm_c13.c13_num_recep
	 FROM ordt013
	WHERE c13_compania  = vg_codcia
	  AND c13_localidad = vg_codloc
	  AND c13_numero_oc = rm_c13.c13_numero_oc

IF rm_c13.c13_num_recep IS NULL THEN
	LET rm_c13.c13_num_recep = 1
END IF
INSERT INTO ordt013 VALUES(rm_c13.*)

END FUNCTION



FUNCTION control_cargar_ordt015_1()
DEFINE r_c15			RECORD LIKE ordt015.*
DEFINE i,k,filas		SMALLINT

CALL retorna_tam_arr2()
FOR k = 1 TO vm_size_arr2
	INITIALIZE r_detalle_4[k].* TO NULL
END FOR

DECLARE q_ordt015 CURSOR FOR 
	SELECT * FROM ordt015 
		WHERE c15_compania  = vg_codcia
		  AND c15_localidad = vg_codloc
		  AND c15_numero_oc = rm_c13.c13_numero_oc
		  AND c15_num_recep = rm_c13.c13_num_recep

LET tot_cap = 0
LET tot_int = 0
LET tot_sub = 0
LET i = 1
FOREACH q_ordt015 INTO r_c15.*

	LET r_detalle_4[i].c15_dividendo  = r_c15.c15_dividendo
	LET r_detalle_4[i].c15_fecha_vcto = r_c15.c15_fecha_vcto
	LET r_detalle_4[i].c15_valor_cap  = r_c15.c15_valor_cap
	LET r_detalle_4[i].c15_valor_int  = r_c15.c15_valor_int
	LET r_detalle_4[i].subtotal       = r_c15.c15_valor_cap +
					    r_c15.c15_valor_int

	LET tot_cap = tot_cap + r_c15.c15_valor_cap	
	LET tot_int = tot_int + r_c15.c15_valor_int	
	LET tot_sub = tot_sub + r_detalle_4[i].subtotal	

	LET i = i + 1

END FOREACH

LET i = i - 1

LET fecha_pago = r_detalle_4[1].c15_fecha_vcto
LET tot_recep = tot_cap

IF i > 1 THEN
	LET dias_pagos = r_detalle_4[2].c15_fecha_vcto -
		 	 r_detalle_4[1].c15_fecha_vcto 
ELSE
	LET dias_pagos = r_detalle_4[1].c15_fecha_vcto - DATE(rm_c13.c13_fecing)
END IF
LET tot_dias = dias_pagos * i

LET pagos = i
DISPLAY BY NAME tot_recep, dias_pagos, pagos, tot_cap, tot_int, 
		tot_sub,   fecha_pago, tot_dias, rm_c13.c13_interes

END FUNCTION



FUNCTION control_cargar_ordt015_2()
DEFINE r_c12			RECORD LIKE ordt012.*
DEFINE i,k,filas		SMALLINT

CALL retorna_tam_arr2()
FOR k = 1 TO vm_size_arr2
	INITIALIZE r_detalle_4[k].* TO NULL
END FOR

DECLARE q_ordt012_2 CURSOR FOR 
	SELECT * FROM ordt012 
		WHERE c12_compania  = vg_codcia
		  AND c12_localidad = vg_codloc
		  AND c12_numero_oc = rm_c13.c13_numero_oc

LET tot_cap = 0
LET tot_int = 0
LET tot_sub = 0
LET i = 1
FOREACH q_ordt012_2 INTO r_c12.*

	LET r_detalle_4[i].c15_dividendo  = r_c12.c12_dividendo
	LET r_detalle_4[i].c15_fecha_vcto = r_c12.c12_fecha_vcto
	LET r_detalle_4[i].c15_valor_cap  = r_c12.c12_valor_cap
	LET r_detalle_4[i].c15_valor_int  = r_c12.c12_valor_int
	LET r_detalle_4[i].subtotal       = r_c12.c12_valor_cap +
					    r_c12.c12_valor_int

	LET tot_cap = tot_cap + r_c12.c12_valor_cap	
	LET tot_int = tot_int + r_c12.c12_valor_int	
	LET tot_sub = tot_sub + r_detalle_4[i].subtotal	

	LET i = i + 1

END FOREACH

LET i = i - 1

LET fecha_pago = r_detalle_4[1].c15_fecha_vcto
LET tot_recep = tot_cap

IF i > 1 THEN
	LET dias_pagos = r_detalle_4[2].c15_fecha_vcto -
		 	 r_detalle_4[1].c15_fecha_vcto 
ELSE
	LET dias_pagos = r_detalle_4[1].c15_fecha_vcto - DATE(rm_c13.c13_fecing)
END IF
LET tot_dias = dias_pagos * i

LET pagos = i
LET rm_c13.c13_interes = rm_c10.c10_interes
DISPLAY BY NAME tot_recep, dias_pagos, pagos, tot_cap, tot_int, 
		tot_sub,   fecha_pago, tot_dias, rm_c13.c13_interes

END FUNCTION



FUNCTION control_insert_ordt014()
DEFINE i,k 	SMALLINT

LET rm_c14.c14_compania   = vg_codcia
LET rm_c14.c14_localidad  = vg_codloc
LET rm_c14.c14_numero_oc  = rm_c13.c13_numero_oc
LET rm_c14.c14_num_recep  = rm_c13.c13_num_recep

LET k = 1
FOR i = 1 TO vm_ind_arr

	IF r_detalle_3[i].c14_cantidad > 0 THEN
		LET rm_c14.c14_cantidad  = r_detalle_3[i].c14_cantidad
		LET rm_c14.c14_codigo       = r_detalle_3[i].c14_codigo
		LET rm_c14.c14_descrip      = r_detalle_3[i].c14_descrip
		LET rm_c14.c14_descuento    = r_detalle_3[i].c14_descuento
		LET rm_c14.c14_precio       = r_detalle_3[i].c14_precio
		LET rm_c14.c14_secuencia    = k
		LET rm_c14.c14_paga_iva     = r_detalle_3[i].paga_iva
		LET rm_c14.c14_val_descto   = r_detalle_5[i].c14_val_descto
		IF vm_calc_iva = 'D' AND rm_c14.c14_paga_iva = 'S' THEN
			LET rm_c14.c14_val_impto = ((rm_c14.c14_cantidad * 
					             rm_c14.c14_precio)  -
						    rm_c14.c14_val_descto) *
						    vm_impuesto / 100 	
		ELSE
			LET rm_c14.c14_val_impto = 0
		END IF
		LET rm_c14.c14_val_descto = 0

		INSERT INTO ordt014 VALUES(rm_c14.*)

		LET k = k + 1
		
	END IF
END FOR 

END FUNCTION



FUNCTION control_update_ordt011()
DEFINE i 	SMALLINT

FOR i = 1 TO vm_ind_arr

	IF r_detalle_3[i].c14_cantidad > 0 THEN

		UPDATE ordt011 
			SET c11_cant_rec = c11_cant_rec + 
					   r_detalle_3[i].c14_cantidad
			WHERE c11_compania  = vg_codcia
			  AND c11_localidad = vg_codloc
			  AND c11_numero_oc = rm_c13.c13_numero_oc
			  AND c11_codigo    = r_detalle_3[i].c14_codigo

	END IF

END FOR 

END FUNCTION




FUNCTION control_cargar_cant_oc()
DEFINE r_c11		RECORD LIKE ordt011.*

SELECT c11_numero_oc, SUM(c11_cant_ped)
	INTO r_c11.c11_numero_oc, r_c11.c11_cant_ped
	FROM ordt010, ordt011
	WHERE c10_compania  = vg_codcia
	  AND c10_localidad = vg_codloc
	  AND c10_numero_oc = rm_c13.c13_numero_oc
	  AND c11_compania  = c10_compania
	  AND c11_localidad = c10_localidad
	  AND c11_numero_oc = c10_numero_oc
GROUP BY c11_numero_oc
                             
RETURN r_c11.c11_cant_ped

END FUNCTION



FUNCTION control_cargar_cant_recep()
DEFINE num_oc		LIKE ordt011.c11_numero_oc
DEFINE r_c14		RECORD LIKE ordt014.*

SELECT c14_numero_oc, SUM(c14_cantidad)
	INTO r_c14.c14_numero_oc, r_c14.c14_cantidad
	FROM ordt013, ordt014
	WHERE c13_estado    <> 'E' 
          AND c13_compania  = vg_codcia
	  AND c13_localidad = vg_codloc
	  AND c13_numero_oc = rm_c13.c13_numero_oc
	  AND c14_compania  = vg_codcia
	  AND c14_localidad = vg_codloc
	  AND c14_numero_oc = rm_c13.c13_numero_oc
	  AND c14_num_recep = c13_num_recep
GROUP BY c14_numero_oc

IF r_c14.c14_cantidad IS NULL THEN
	RETURN 0
END IF
                             
RETURN r_c14.c14_cantidad

END FUNCTION



FUNCTION calcula_totales_recep()
DEFINE k 		SMALLINT
DEFINE v_impto		LIKE ordt013.c13_tot_impto

LET rm_c13.c13_tot_bruto   = 0	
LET rm_c13.c13_tot_dscto   = 0	
LET rm_c13.c13_tot_impto   = 0	
LET rm_c13.c13_tot_recep   = 0	
LET rm_c13.c13_dif_cuadre  = rm_c10.c10_dif_cuadre
LET rm_c13.c13_flete       = rm_c10.c10_flete
LET rm_c13.c13_otros       = rm_c10.c10_otros
LET vm_subtotal_2	   = 0	
LET v_impto		   = 0	
LET iva_bien               = 0
LET iva_servi              = 0
LET val_servi              = 0
LET val_bienes             = 0

FOR k = 1 TO vm_ind_arr
	---- SUBTOTAL CODIGO----
	LET vm_subtotal_2 = r_detalle_3[k].c14_precio * r_detalle_3[k].c14_cantidad
	----------------------------

	LET rm_c13.c13_tot_bruto  = rm_c13.c13_tot_bruto + vm_subtotal_2 

	---- DESCUENTO - TOT_DSCTO ----
	LET r_detalle_5[k].c14_val_descto = vm_subtotal_2 * 
					    r_detalle_3[k].c14_descuento / 100  

	LET r_detalle_5[k].c14_val_descto = 
		fl_retorna_precision_valor(vm_moneda,
		                           r_detalle_5[k].c14_val_descto)

	LET rm_c13.c13_tot_dscto = rm_c13.c13_tot_dscto + 
				   r_detalle_5[k].c14_val_descto
	--------------------------------
	IF r_detalle_5[k].c11_tipo = 'B' THEN
		LET val_bienes = val_bienes + vm_subtotal_2 - 
				 r_detalle_5[k].c14_val_descto
	ELSE
		LET val_servi  = val_servi + vm_subtotal_2 - 
				 r_detalle_5[k].c14_val_descto
	END IF
	IF vm_calc_iva = 'D' AND r_detalle_3[k].paga_iva = 'S' THEN
		---- IMPUESTO - TOT_IMPTO ------
		LET v_impto =(vm_subtotal_2 - r_detalle_5[k].c14_val_descto) * 
			      vm_impuesto / 100
	
		LET v_impto = fl_retorna_precision_valor(vm_moneda, v_impto)
	
		LET rm_c13.c13_tot_impto = rm_c13.c13_tot_impto + v_impto
		--------------------------------
		IF r_detalle_5[k].c11_tipo = 'B' THEN
			LET iva_bien  = iva_bien  + v_impto
		ELSE
			LET iva_servi = iva_servi + v_impto
		END IF
	END IF

END FOR
IF val_bienes > 0 THEN
	LET val_bienes = val_bienes + rm_c13.c13_otros
ELSE
	IF val_servi > 0 THEN
		LET val_servi = val_servi + rm_c13.c13_otros
	END IF
END IF
IF vm_calc_iva = 'S' THEN
	LET rm_c13.c13_tot_impto = (rm_c13.c13_tot_bruto - rm_c13.c13_tot_dscto + 
	            		    rm_c13.c13_otros ) * (vm_impuesto / 100)
	LET rm_c13.c13_tot_impto = fl_retorna_precision_valor(vm_moneda, rm_c13.c13_tot_impto)
	LET iva_bien  = val_bienes * vm_impuesto / 100
	LET iva_bien  = fl_retorna_precision_valor(vm_moneda, iva_bien)
	LET iva_servi = val_servi * vm_impuesto / 100
	LET iva_servi = fl_retorna_precision_valor(vm_moneda, iva_servi)
END IF
LET rm_c13.c13_tot_recep = rm_c13.c13_tot_bruto - rm_c13.c13_tot_dscto +
			   rm_c13.c13_tot_impto	+ rm_c13.c13_flete +
			   rm_c13.c13_otros     

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(400)
DEFINE r_c11		RECORD LIKE ordt011.*

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle_3[i].* TO NULL
	INITIALIZE r_detalle_5[i].* TO NULL
END FOR

LET query = 'SELECT * FROM ordt011 ',
            	'WHERE c11_compania  = ', vg_codcia, 
	    	'  AND c11_localidad = ', vg_codloc,
            	'  AND c11_numero_oc = ', rm_c10.c10_numero_oc,
		' ORDER BY 4 '

PREPARE cons2_2 FROM query
DECLARE q_cons2_2 CURSOR FOR cons2_2
LET i = 1
FOREACH q_cons2_2 INTO r_c11.*
	
	IF r_c11.c11_cant_ped - r_c11.c11_cant_rec > 0 
	   THEN
		LET r_detalle_3[i].c11_cant_ped  = r_c11.c11_cant_ped - 
	 					 r_c11.c11_cant_rec
		LET r_detalle_3[i].c14_cantidad  = r_detalle_3[i].c11_cant_ped
		LET r_detalle_3[i].c14_codigo    = r_c11.c11_codigo
		LET r_detalle_3[i].c14_descrip   = r_c11.c11_descrip
		LET r_detalle_3[i].c14_descuento = r_c11.c11_descuento
		LET r_detalle_3[i].c14_precio    = r_c11.c11_precio
		LET r_detalle_3[i].paga_iva      = r_c11.c11_paga_iva 
		LET r_detalle_5[i].c11_tipo    = r_c11.c11_tipo 
		IF r_c11.c11_paga_iva = 'N' THEN
			LET vm_calc_iva = 'D'
		END IF
		LET i = i + 1
        	IF i > vm_max_detalle THEN
			CALL fl_mostrar_mensaje('La cantidad de elementos del detalle supero la cantidad de elementos del arreglo','stop')
			EXIT PROGRAM
		END IF	
	END IF	

END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mostrar_mensaje('No hay elementos del detalle que recibir.','exclamation')
END IF

LET vm_ind_arr = i

END FUNCTION



FUNCTION control_insert_ordt015_2()
DEFINE  i 	SMALLINT

LET rm_c15.c15_compania  = vg_codcia
LET rm_c15.c15_localidad = vg_codloc
LET rm_c15.c15_numero_oc = rm_c13.c13_numero_oc
LET rm_c15.c15_num_recep = rm_c13.c13_num_recep

FOR i = 1 TO pagos
	
	LET rm_c15.c15_dividendo  = i
	LET rm_c15.c15_fecha_vcto = r_detalle_4[i].c15_fecha_vcto
	LET rm_c15.c15_valor_cap  = r_detalle_4[i].c15_valor_cap
	LET rm_c15.c15_valor_int  = r_detalle_4[i].c15_valor_int

	INSERT INTO ordt015 VALUES(rm_c15.*)

END FOR

END FUNCTION



FUNCTION control_cargar_detalle_ordt015()
DEFINE i 		SMALLINT
DEFINE saldo    	LIKE ordt013.c13_tot_recep
DEFINE val_div  	LIKE ordt013.c13_tot_recep

LET saldo   = rm_c13.c13_tot_recep
LET val_div = rm_c13.c13_tot_recep / pagos
LET pagos   = 1

FOR i = 1 TO pagos

	LET r_detalle_4[i].c15_dividendo = i

	IF i = 1 THEN
		LET r_detalle_4[i].c15_fecha_vcto = fecha_pago
	ELSE
		LET r_detalle_4[i].c15_fecha_vcto = 
		    r_detalle_4[i-1].c15_fecha_vcto + dias_pagos
	END IF

	IF i <> pagos THEN
		LET r_detalle_4[i].c15_valor_cap = val_div
		LET saldo 			 = saldo - val_div
	ELSE
		LET r_detalle_4[i].c15_valor_cap = saldo
	END IF
	LET r_detalle_4[i].c15_valor_int = 0

END FOR 

	CALL retorna_tam_arr()
	LET vm_filas_pant = vm_size_arr2

	IF pagos < vm_filas_pant THEN
		LET vm_filas_pant = pagos
	END IF 

END FUNCTION



FUNCTION control_insert_cxpt020()
DEFINE i		SMALLINT
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_c15		RECORD LIKE ordt015.*

INITIALIZE r_p20.* TO NULL
LET r_p20.p20_compania    = vg_codcia
LET r_p20.p20_localidad   = vg_codloc
LET r_p20.p20_codprov     = rm_c10.c10_codprov
LET r_p20.p20_usuario     = vg_usuario
LET r_p20.p20_fecing      = fl_current()
LET r_p20.p20_fecha_emi	  = vg_fecha
LET r_p20.p20_tipo_doc    = 'FA'
LET r_p20.p20_num_doc     = rm_c13.c13_factura
LET r_p20.p20_referencia  = 'RECEPCION # ' || rm_c13.c13_num_recep
LET r_p20.p20_porc_impto  = rm_c10.c10_porc_impto
LET r_p20.p20_tasa_int    = rm_c13.c13_interes
LET r_p20.p20_tasa_mora   = 0
LET r_p20.p20_moneda	  = rm_c10.c10_moneda
LET r_p20.p20_paridad     = rm_c10.c10_paridad
LET r_p20.p20_valor_fact  = rm_c13.c13_tot_recep
LET r_p20.p20_valor_impto = rm_c13.c13_tot_impto

LET r_p20.p20_cod_depto  = rm_c10.c10_cod_depto 
LET r_p20.p20_cartera    = 6
LET r_p20.p20_numero_oc  = rm_c13.c13_numero_oc
LET r_p20.p20_origen     = 'A'		-- automatico

IF rm_c10.c10_tipo_pago = 'R' THEN
	DECLARE q_c15 CURSOR FOR 
		SELECT * FROM ordt015
			WHERE c15_compania  = vg_codcia
	  	  	  AND c15_localidad = vg_codloc
	  	  	  AND c15_numero_oc = rm_c13.c13_numero_oc
	  	     	  AND c15_num_recep = rm_c13.c13_num_recep

	FOREACH q_c15 INTO r_c15.*
		LET r_p20.p20_dividendo  = r_c15.c15_dividendo
		LET r_p20.p20_fecha_vcto = r_c15.c15_fecha_vcto
		LET r_p20.p20_valor_cap  = r_c15.c15_valor_cap
		LET r_p20.p20_saldo_cap  = r_c15.c15_valor_cap
		LET r_p20.p20_valor_int  = r_c15.c15_valor_int
		LET r_p20.p20_saldo_int  = r_c15.c15_valor_int
	
		INSERT INTO cxpt020 VALUES(r_p20.*)
	END FOREACH
ELSE
	LET r_p20.p20_referencia  = 'RECEPCION # ' || rm_c13.c13_num_recep 
				    || '  DE CONTADO'
	LET r_p20.p20_dividendo  = 1
	LET r_p20.p20_fecha_vcto = vg_fecha
	LET r_p20.p20_valor_cap  = rm_c13.c13_tot_recep
	LET r_p20.p20_valor_int  = 0
	LET r_p20.p20_saldo_cap  = rm_c13.c13_tot_recep
	LET r_p20.p20_saldo_int  = 0
	
	INSERT INTO cxpt020 VALUES(r_p20.*)
END IF

END FUNCTION



FUNCTION contabilizacion_online()
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p00		RECORD LIKE cxpt000.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_ctas	ARRAY[25] OF RECORD 
	cuenta		LIKE ctbt013.b13_cuenta,
	n_cuenta	LIKE ctbt010.b10_descripcion,
	valor_db	LIKE ctbt013.b13_valor_base,
	valor_cr	LIKE ctbt013.b13_valor_base
END RECORD

DEFINE i, j, l, col	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE salir		SMALLINT
DEFINE impto		LIKE ordt013.c13_tot_impto
DEFINE retenciones	LIKE cxpt027.p27_total_ret 
DEFINE cuenta_cxp	LIKE ctbt010.b10_cuenta
DEFINE cuenta      	LIKE ctbt010.b10_cuenta
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base

DEFINE tot_debito	LIKE ctbt013.b13_valor_base
DEFINE tot_credito	LIKE ctbt013.b13_valor_base
DEFINE r_s23		RECORD LIKE srit023.*
DEFINE tributa		LIKE srit023.s23_tributa

DEFINE resp 		VARCHAR(6)
DEFINE query		VARCHAR(250)
DEFINE orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT

FOR i = 1 TO 10
	LET orden[i] = '' 
END FOR
LET columna_1 = 1
LET columna_2 = 2
LET col       = 2

CREATE TEMP TABLE tmp_cuenta(
	te_cuenta	CHAR(12),
	te_descripcion  CHAR(30),
	te_valor_db	DECIMAL(14,2),
	te_valor_cr	DECIMAL(14,2),
	te_serial	SERIAL,
	te_flag		CHAR(1) 
	-- 'F' -> Fijo, no puede ser elminado
	-- 'V' -> Variable, se puede eliminar
);

LET max_rows = 25

INITIALIZE r_b12.* TO NULL

OPEN WINDOW w_202_4 AT 8, 2 WITH 14 ROWS, 78 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_202_4 FROM "../../COMPRAS/forms/ordf202_4"
ELSE
	OPEN FORM f_202_4 FROM "../../COMPRAS/forms/ordf202_4c"
END IF
DISPLAY FORM f_202_4

--#DISPLAY 'Cuenta' 		TO bt_cuenta
--#DISPLAY 'Descripción'	TO bt_descripcion
--#DISPLAY 'Débito'		TO bt_valor_db
--#DISPLAY 'Crédito'		TO bt_valor_cr

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc) 
	RETURNING r_c10.*

CALL fl_lee_auxiliares_generales(vg_codcia, vg_codloc) RETURNING r_b42.*
IF r_b42.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado auxiliares contables para IVA.','exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_c10.c10_codprov)
	RETURNING r_p02.*
IF r_p02.p02_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado auxiliares contables para este proveedor.','exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

LET impto = rm_c13.c13_tot_impto

IF impto IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha realizado ninguna recepción.','exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF 

DECLARE q_p28 CURSOR FOR
	SELECT * FROM cxpt028
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_codprov   = rm_c10.c10_codprov
		  AND p28_tipo_doc  = 'FA'
		  AND p28_num_doc   = rm_c13.c13_factura

IF rm_c10.c10_moneda = rg_gen.g00_moneda_base THEN
	LET cuenta_cxp = r_p02.p02_aux_prov_mb
ELSE
	LET cuenta_cxp = r_p02.p02_aux_prov_ma
END IF

IF cuenta_cxp IS NULL THEN
	CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_p00.*
	IF r_p00.p00_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe una compañía configurada en Tesorería.','exclamation')
		LET int_flag = 1
		CLOSE WINDOW w_202_4
		RETURN r_b12.*
	END IF
	IF rm_c10.c10_moneda = rg_gen.g00_moneda_base THEN
		LET cuenta_cxp = r_p00.p00_aux_prov_mb
	ELSE
		LET cuenta_cxp = r_p00.p00_aux_prov_ma
	END IF
END IF
CALL inserta_tabla_temporal(cuenta_cxp, 0, rm_c13.c13_tot_recep, 'F') 
	RETURNING tot_debito, tot_credito

LET retenciones = 0
FOREACH q_p28 INTO r_p28.*
	CALL fl_lee_tipo_retencion(vg_codcia, r_p28.p28_tipo_ret, 
		r_p28.p28_porcentaje) RETURNING r_c02.*
	CALL inserta_tabla_temporal(r_c02.c02_aux_cont, 0, r_p28.p28_valor_ret,
		'F') RETURNING tot_debito, tot_credito
	LET retenciones = retenciones + r_p28.p28_valor_ret
END FOREACH

IF retenciones > 0 THEN
	UPDATE tmp_cuenta SET te_valor_cr = te_valor_cr - retenciones
		WHERE te_cuenta = cuenta_cxp
END IF
LET tributa = 'S'
IF rm_c13.c13_tot_impto = 0 THEN
	LET tributa = 'N'
END IF
CALL fl_obtener_aux_cont_sust(vg_codcia, rm_c10.c10_tipo_orden, tributa)
	RETURNING r_s23.*
IF r_s23.s23_aux_cont IS NOT NULL THEN
	LET rm_c01.c01_aux_cont = r_s23.s23_aux_cont
END IF
IF rm_c01.c01_aux_cont IS NOT NULL THEN 
	LET r_b42.b42_iva_compra = rm_c01.c01_aux_cont
END IF
IF rm_c10.c10_sustento_sri = 'S' THEN
	CALL inserta_tabla_temporal(r_b42.b42_iva_compra, impto, 0, 'F')
		RETURNING tot_debito, tot_credito
END IF

INITIALIZE rm_b12.* TO NULL
LET rm_b12.b12_glosa = 'COMPROBANTE: ', rm_p01.p01_nomprov[1,25], ' ',
			rm_c13.c13_factura
LET salir = 0
WHILE NOT salir
	LET int_flag = 0
	INPUT BY NAME rm_b12.b12_glosa
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CONTINUE INPUT
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
	END INPUT
	IF int_flag THEN
		CLOSE WINDOW w_202_4
		RETURN r_b12.*
	END IF
	LET query = 'SELECT te_cuenta, te_descripcion, te_valor_db, ',
		     	'   te_valor_cr ',
		    '	FROM tmp_cuenta ',
		    '	ORDER BY ', columna_1, ' ', orden[columna_1],
			      ', ', columna_2, ' ', orden[columna_2]
	PREPARE ctas FROM query
	DECLARE q_ctas CURSOR FOR ctas 
	LET i = 1
	FOREACH q_ctas INTO r_ctas[i].*    
		LET i = i + 1
		IF i > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET int_flag = 0
	CALL set_count(i)
	INPUT ARRAY r_ctas WITHOUT DEFAULTS FROM r_ctas.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CONTINUE INPUT
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F2)
			IF INFIELD(b13_cuenta) AND modificable(r_ctas[i].cuenta)
			THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia, -1) 
					RETURNING r_b10.b10_cuenta, 
        					  r_b10.b10_descripcion 
				IF r_b10.b10_cuenta IS NOT NULL THEN
					LET r_ctas[i].cuenta = r_b10.b10_cuenta
					LET r_ctas[i].n_cuenta = 
						r_b10.b10_descripcion
					DISPLAY r_ctas[i].cuenta
						TO r_ctas[j].b13_cuenta
					DISPLAY r_ctas[i].n_cuenta
						TO r_ctas[j].n_cuenta
				END IF	
			END IF
			LET int_flag = 0	
		ON KEY(F5)
			LET int_flag = 0
			EXIT INPUT
		ON KEY(F15)
			LET col = 1	
			EXIT INPUT
		ON KEY(F16)
			LET col = 2	
			EXIT INPUT
		ON KEY(F17)
			LET col = 3	
			EXIT INPUT
		ON KEY(F18)
			LET col = 4	
			EXIT INPUT
		BEFORE INPUT
			DISPLAY BY NAME tot_debito, tot_credito
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE DELETE
			IF NOT modificable(r_ctas[i].cuenta) THEN
				EXIT INPUT    
			END IF
			DELETE FROM tmp_cuenta 
				WHERE te_cuenta = r_ctas[i].cuenta
			LET tot_debito  = tot_debito  - r_ctas[i].valor_db
			LET tot_credito = tot_credito - r_ctas[i].valor_cr
			DISPLAY BY NAME tot_debito, tot_credito
		BEFORE FIELD b13_cuenta
			LET i = arr_curr()
			LET cuenta = r_ctas[i].cuenta
		AFTER FIELD b13_cuenta
			IF r_ctas[i].cuenta IS NULL AND modificable(cuenta)
			THEN
-- :)
				IF cuenta IS NOT NULL THEN
					DELETE FROM tmp_cuenta
						WHERE te_cuenta = cuenta
				END IF
-- :)
				CONTINUE INPUT
			END IF
			IF (r_ctas[i].cuenta IS NULL 
			 OR cuenta <> r_ctas[i].cuenta) 
			AND NOT modificable(cuenta) 
			THEN
				CALL fl_mostrar_mensaje('No puede modificar esta cuenta.','exclamation')
				LET r_ctas[i].cuenta = cuenta
				DISPLAY r_ctas[i].cuenta TO r_ctas[j].b13_cuenta
				CONTINUE INPUT
			END IF
			IF (cuenta IS NULL OR cuenta <> r_ctas[i].cuenta) 
			AND NOT modificable(r_ctas[i].cuenta) 
			THEN
				CALL fl_mostrar_mensaje('No puede volver a ingresar esta cuenta.','exclamation')
				LET r_ctas[i].cuenta = ' '
				NEXT FIELD b13_cuenta
			END IF
			CALL fl_lee_cuenta(vg_codcia, r_ctas[i].cuenta) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fl_mostrar_mensaje('No existe cuenta contable.','exclamation')
				NEXT FIELD b13_cuenta
			END IF
			IF r_b10.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD b13_cuenta
			END IF
-- :)
			IF cuenta IS NOT NULL THEN
				DELETE FROM tmp_cuenta
					WHERE te_cuenta = cuenta
			END IF
-- :)
			CALL inserta_tabla_temporal(r_ctas[i].cuenta,
				r_ctas[i].valor_db, r_ctas[i].valor_cr, 'V')
				RETURNING tot_debito, tot_credito
			DISPLAY BY NAME tot_debito, tot_credito
			LET r_ctas[i].n_cuenta = r_b10.b10_descripcion
			DISPLAY r_ctas[i].n_cuenta TO r_ctas[j].n_cuenta
		BEFORE FIELD valor_db 
			IF NOT modificable(r_ctas[i].cuenta) THEN
				NEXT FIELD b13_cuenta  
			END IF
			LET debito = r_ctas[i].valor_db
		AFTER FIELD valor_db
			IF r_ctas[i].valor_db IS NULL THEN
				LET r_ctas[i].valor_db = 0
				DISPLAY r_ctas[i].valor_db
					TO r_ctas[j].valor_db
			END IF
			IF r_ctas[i].valor_db > 0 THEN
				LET r_ctas[i].valor_cr = 0
				DISPLAY r_ctas[i].valor_cr
					TO r_ctas[j].valor_cr
			END IF
			IF debito <> r_ctas[i].valor_db OR debito IS NULL 
			THEN
				CALL inserta_tabla_temporal(r_ctas[i].cuenta,
					r_ctas[i].valor_db, r_ctas[i].valor_cr,
					'V') RETURNING tot_debito, tot_credito
				DISPLAY BY NAME tot_debito, tot_credito
			{
				IF cuenta_distribucion(vg_codcia, 
						       r_ctas[i].cuenta) 
				AND rm_cuenta[i].valor_debito > 0
				THEN
					CALL muestra_distribucion(vg_codcia,
						rm_cuenta[i].cuenta,
						rm_cuenta[i].valor_debito)
					LET int_flag = 0
				END IF
			}
			END IF
		BEFORE FIELD valor_cr 
			IF NOT modificable(r_ctas[i].cuenta) THEN
				NEXT FIELD b13_cuenta
			END IF
			LET credito = r_ctas[i].valor_cr
		AFTER FIELD valor_cr
			IF r_ctas[i].valor_cr IS NULL THEN
				LET r_ctas[i].valor_cr = 0
				DISPLAY r_ctas[i].valor_cr TO r_ctas[j].valor_cr
			END IF
			IF r_ctas[i].valor_cr > 0 THEN
				LET r_ctas[i].valor_db = 0
				DISPLAY r_ctas[i].valor_db TO r_ctas[j].valor_db
			END IF
			IF credito <> r_ctas[i].valor_cr OR credito IS NULL 
			THEN
				CALL inserta_tabla_temporal(r_ctas[i].cuenta,
					r_ctas[i].valor_db, r_ctas[i].valor_cr,
					'V') RETURNING tot_debito, tot_credito
				DISPLAY BY NAME tot_debito, tot_credito
			{
				IF cuenta_distribucion(vg_codcia, 
						       rm_cuenta[i].cuenta) 
				AND rm_cuenta[i].valor_credito > 0
				THEN
					CALL muestra_distribucion(vg_codcia,
						rm_cuenta[i].cuenta,
						rm_cuenta[i].valor_credito)
					LET int_flag = 0
				END IF
			}
			END IF
		AFTER INPUT
			IF tot_debito IS NULL THEN
				CALL fl_mostrar_mensaje('No hay lineas de detalle para el débito.','exclamation')
				CONTINUE INPUT
			END IF
			IF tot_credito IS NULL THEN
				CALL fl_mostrar_mensaje('No hay lineas de detalle para el crédito.','exclamation')
				CONTINUE INPUT
			END IF
			LET tot_debito  = 0
			LET tot_credito = 0
			FOR l = 1 TO arr_count()
				IF r_ctas[l].valor_db IS NOT NULL THEN
					LET tot_debito  = tot_debito  +
							r_ctas[l].valor_db
				END IF
				IF r_ctas[l].valor_cr IS NOT NULL THEN
					LET tot_credito = tot_credito +
							r_ctas[l].valor_cr
				END IF
			END FOR
			DISPLAY BY NAME tot_debito, tot_credito
			IF tot_debito <> tot_credito THEN
				CALL fl_mostrar_mensaje('Los valores en el débito y el crédito deben ser iguales.','exclamation')
				CONTINUE INPUT
			END IF
			--IF tot_debito > rm_c13.c13_tot_recep THEN
			IF tot_debito > rm_c10.c10_tot_compra THEN
				CALL fl_mostrar_mensaje('Los valores en el débito y el crédito deben ser iguales al total de la recepción.','exclamation')
				CONTINUE INPUT
			END IF
			IF tot_debito = 0 THEN
				CALL fl_mostrar_mensaje('No puede generar un Diario Contable con totales de CERO para el Débito y el Crédito.','exclamation')
				CONTINUE INPUT
			END IF
			SELECT NVL(SUM(te_valor_db), 0),NVL(SUM(te_valor_cr), 0)
				INTO tot_debito, tot_credito
				FROM tmp_cuenta
			IF tot_debito <> tot_credito THEN
				CALL fl_mostrar_mensaje('Los valores en el débito y el crédito deben ser iguales. en la tabla temporal','exclamation')
				CONTINUE INPUT
			END IF
			LET salir = 1
	END INPUT
	IF int_flag THEN
		CLOSE WINDOW w_202_4
		RETURN r_b12.*
	END IF

	IF col IS NOT NULL AND NOT salir THEN
        	IF col <> columna_1 THEN
        	        LET columna_2        = columna_1
        	        LET orden[columna_2] = orden[columna_1]
        	        LET columna_1        = col
        	END IF
        	IF orden[columna_1] = 'ASC' THEN
        	        LET orden[columna_1] = 'DESC'
        	ELSE
        	        LET orden[columna_1] = 'ASC'
        	END IF
		INITIALIZE col TO NULL
	END IF
END WHILE	

CALL genera_comprobante_contable() RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

DROP TABLE tmp_cuenta
CLOSE WINDOW w_202_4

RETURN r_b12.*

END FUNCTION



FUNCTION grabar_detalle_cont(r_b12, cuenta, valor, i)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		DECIMAL(14,2)
DEFINE i		SMALLINT
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p02		RECORD LIKE cxpt002.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = i
LET r_b13.b13_tipo_doc    = NULL
LET r_b13.b13_cuenta      = cuenta
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING r_c10.*
LET r_b13.b13_glosa  = 'PROV. # ', r_c10.c10_codprov
			USING "<<<<&", ' OC. # ',
			r_c10.c10_numero_oc USING "<<<<<<<<<&"
CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, r_c10.c10_codprov)
	RETURNING r_p02.*
IF cuenta = r_p02.p02_aux_prov_mb THEN
	LET r_b13.b13_glosa  = 'COMPRA FACT # ',
				rm_c13.c13_num_guia CLIPPED,
				' OC # ', r_c10.c10_numero_oc USING "<<<<<<<<<&"
END IF
IF r_c10.c10_moneda = rg_gen.g00_moneda_base THEN
	LET r_b13.b13_valor_base  = valor
	LET r_b13.b13_valor_aux   = 0
ELSE
	LET r_b13.b13_valor_base  = valor * r_c10.c10_paridad
	LET r_b13.b13_valor_aux   = valor
END IF
LET r_b13.b13_num_concil  = NULL
LET r_b13.b13_filtro      = NULL
LET r_b13.b13_fec_proceso = rm_c13.c13_fec_emi_fac
LET r_b13.b13_codcli      = NULL
LET r_b13.b13_codprov     = r_c10.c10_codprov
LET r_b13.b13_pedido      = NULL
INSERT INTO ctbt013 VALUES(r_b13.*)

END FUNCTION



FUNCTION modificable(cuenta)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE return_value	SMALLINT
DEFINE flag		CHAR(1)
DEFINE ctos		INTEGER

INITIALIZE flag TO NULL
SELECT COUNT(*) INTO ctos FROM tmp_cuenta WHERE te_cuenta = cuenta
IF ctos = 1 THEN
	SELECT te_flag INTO flag FROM tmp_cuenta WHERE te_cuenta = cuenta
	LET return_value = 1
	IF flag = 'F' THEN
		LET return_value = 0
	END IF
ELSE
	LET return_value = 1
END IF
RETURN return_value

END FUNCTION



FUNCTION inserta_tabla_temporal(cuenta, valor_db, valor_cr, flag)
DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE valor_db		LIKE ctbt013.b13_valor_base
DEFINE valor_cr		LIKE ctbt013.b13_valor_base
DEFINE flag		CHAR(1)
DEFINE tot_debito	LIKE ctbt013.b13_valor_base
DEFINE tot_credito	LIKE ctbt013.b13_valor_base
DEFINE ctos		INTEGER

SELECT COUNT(*) INTO ctos FROM tmp_cuenta WHERE te_cuenta = cuenta
CASE flag
	WHEN 'F'
		IF ctos = 0 THEN
			CALL insertar_registro(cuenta, valor_db, valor_cr, flag)
		END IF
	WHEN 'V'
		IF ctos = 0 THEN
			CALL insertar_registro(cuenta, valor_db, valor_cr, flag)
		ELSE
			UPDATE tmp_cuenta
				SET te_valor_db = valor_db,
				    te_valor_cr = valor_cr
				WHERE te_cuenta = cuenta
		END IF
END CASE

SELECT SUM(te_valor_db), SUM(te_valor_cr) 
	INTO tot_debito, tot_credito 
	FROM tmp_cuenta

RETURN tot_debito, tot_credito

END FUNCTION



FUNCTION insertar_registro(cuenta, valor_db, valor_cr, flag)
DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE valor_db		LIKE ctbt013.b13_valor_base
DEFINE valor_cr		LIKE ctbt013.b13_valor_base
DEFINE flag		CHAR(1)
DEFINE query		VARCHAR(255)

IF valor_db IS NULL THEN
	LET valor_db = 0
END IF
IF valor_cr IS NULL THEN
	LET valor_cr = 0
END IF
LET query = 'INSERT INTO tmp_cuenta ',
		'SELECT "', cuenta CLIPPED, '", b10_descripcion, ', valor_db,
			', ', valor_cr, ', 0, "', flag, '"',
		' FROM ctbt010 ',
		' WHERE b10_compania = ', vg_codcia,
		'   AND b10_cuenta   = "', cuenta CLIPPED, '"'
PREPARE stmnt1 FROM query
EXECUTE stmnt1

END FUNCTION



FUNCTION genera_comprobante_contable()

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_p02		RECORD LIKE cxpt002.*

DEFINE cuenta 		LIKE ctbt010.b10_cuenta
DEFINE glosa, glosa1	LIKE ctbt013.b13_glosa
DEFINE query		CHAR(500)
DEFINE expr_valor	VARCHAR(100)

INITIALIZE r_b12.* TO NULL
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING r_c10.*

CALL fl_lee_tipo_comprobante_contable(vg_codcia, 'DO') RETURNING r_b03.*
IF r_b03.b03_compania IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe tipo de comprobante para Diario de Compras: DO.','exclamation')
	EXIT PROGRAM
END IF
LET glosa = 'OC # ', rm_c13.c13_numero_oc USING "<<<<<<<&", ' RECEPCION # ',
		rm_c13.c13_num_recep USING "<<<<<<<&"
INITIALIZE r_b12.* TO NULL
LET r_b12.b12_compania    = vg_codcia  
-- OjO confirmar
LET r_b12.b12_tipo_comp   = r_b03.b03_tipo_comp
LET r_b12.b12_fec_proceso = rm_c13.c13_fec_emi_fac
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
								r_b12.b12_tipo_comp,
								YEAR(r_b12.b12_fec_proceso),
								MONTH(r_b12.b12_fec_proceso))
LET r_b12.b12_estado      = 'A' 
LET r_b12.b12_glosa       = rm_b12.b12_glosa CLIPPED
LET r_b12.b12_origen      = 'A' 
LET r_b12.b12_moneda      = r_c10.c10_moneda 
LET r_b12.b12_paridad     = r_c10.c10_paridad 
LET r_b12.b12_modulo      = r_b03.b03_modulo
LET r_b12.b12_usuario     = vg_usuario 
LET r_b12.b12_fecing      = fl_current()

INSERT INTO ctbt012 VALUES(r_b12.*)

--
IF r_b12.b12_moneda = r_b00.b00_moneda_base THEN
	LET expr_valor = ' (te_valor_cr * (-1)), 0 '
ELSE
	LET expr_valor = ' (te_valor_cr * (-1) * ', r_b12.b12_paridad, 
			 '), (te_valor_cr * (-1))'
END IF
--

CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, r_c10.c10_codprov)
	RETURNING r_p02.*
LET cuenta = NULL
DECLARE q_cta CURSOR FOR
	SELECT UNIQUE te_cuenta
		FROM tmp_cuenta
		WHERE te_cuenta = r_p02.p02_aux_prov_mb
OPEN q_cta
FETCH q_cta INTO cuenta
CLOSE q_cta
FREE q_cta
LET glosa1 = NULL
IF cuenta IS NOT NULL THEN
	LET glosa1  = 'COMPRA FACT # ', rm_c13.c13_num_guia CLIPPED,
			' OC # ', r_c10.c10_numero_oc USING "<<<<<<<<<&"
END IF
LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_num_concil, b13_fec_proceso, b13_codprov) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
			' CASE WHEN te_cuenta = "', cuenta CLIPPED, '"',
				' THEN "', glosa1 CLIPPED, '"',
				' ELSE "', glosa CLIPPED, '"',
			' END, ',
	    		expr_valor CLIPPED, ', 0,', 
	    ' 		DATE("', r_b12.b12_fec_proceso, '"),',
		        rm_c10.c10_codprov,
	    '		FROM tmp_cuenta ', 
	    '		WHERE te_valor_cr > 0 '
PREPARE stmnt3 FROM query
EXECUTE stmnt3

--
IF r_b12.b12_moneda = r_b00.b00_moneda_base THEN
	LET expr_valor = ' te_valor_db, 0 '
ELSE
	LET expr_valor = ' (te_valor_db * ', r_b12.b12_paridad, 
			 '), te_valor_db'
END IF
--
LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_num_concil, b13_fec_proceso,b13_codprov) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
			' CASE WHEN te_cuenta = "', cuenta CLIPPED, '"',
				' THEN "', glosa1 CLIPPED, '"',
				' ELSE "', glosa CLIPPED, '"',
			' END, ',
	    		expr_valor CLIPPED, ', 0, ', 
	    ' 		DATE("', r_b12.b12_fec_proceso, '"),',
		        rm_c10.c10_codprov,
	    '		FROM tmp_cuenta ', 
	    '		WHERE te_valor_db > 0 '
PREPARE stmnt4 FROM query
EXECUTE stmnt4
UPDATE ctbt013 SET b13_codprov = rm_c10.c10_codprov
	WHERE b13_compania  = vg_codcia AND 
	      b13_tipo_comp = r_b12.b12_tipo_comp AND 
	      b13_num_comp  = r_b12.b12_num_comp

CALL grabar_conf_cont_compras(r_b12.b12_tipo_comp, r_b12.b12_num_comp)

RETURN r_b12.*

END FUNCTION



FUNCTION grabar_conf_cont_compras(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

INSERT INTO ordt040 VALUES(vg_codcia, vg_codloc, rm_c13.c13_numero_oc,
		           rm_c13.c13_num_recep, tipo_comp, num_comp)

END FUNCTION



FUNCTION retorna_fin_mes(fecha)
DEFINE fecha		DATE
DEFINE mes, anio	SMALLINT

LET mes  = MONTH(fecha) + 1
LET anio = YEAR(fecha)
IF mes > 12 THEN
	LET mes  = 1
	LET anio = anio + 1
END IF
LET fecha = MDY(mes, 01, anio) - 1 UNITS DAY
RETURN fecha

END FUNCTION



FUNCTION tiene_ice()
DEFINE r_s24		RECORD LIKE srit024.*

INITIALIZE r_s24.* TO NULL
DECLARE q_s24 CURSOR FOR
	SELECT * FROM srit024
		WHERE s24_compania   = vg_codcia
		  AND s24_tipo_orden = rm_c10.c10_tipo_orden
OPEN q_s24
FETCH q_s24 INTO r_s24.*
CLOSE q_s24
FREE q_s24
IF r_s24.s24_compania IS NULL THEN
	RETURN 0
END IF
LET rm_c10.c10_cod_ice     = r_s24.s24_codigo
LET rm_c10.c10_porc_ice    = r_s24.s24_porcentaje_ice
LET rm_c10.c10_cod_ice_imp = r_s24.s24_codigo_impto
RETURN 1

END FUNCTION



FUNCTION control_ice(flag)
DEFINE flag		SMALLINT
DEFINE r_s10		RECORD LIKE srit010.*
DEFINE base_ice		LIKE ordt010.c10_base_ice
DEFINE tecla		SMALLINT
DEFINE resp 		CHAR(6)

OPEN WINDOW w_cxpf210_2 AT 05, 32 WITH FORM '../forms/cxpf210_2'
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST)
CLEAR FORM
DISPLAY rm_c10.c10_tipo_orden TO tipo_orden
DISPLAY rm_c01.c01_nombre     TO descripcion
DISPLAY BY NAME rm_c10.c10_cod_ice, rm_c10.c10_porc_ice, rm_c10.c10_cod_ice_imp,
		rm_c10.c10_base_ice, rm_c10.c10_valor_ice
CALL fl_lee_conf_ice(vg_codcia, rm_c10.c10_cod_ice, rm_c10.c10_porc_ice,
			rm_c10.c10_cod_ice_imp)
	RETURNING r_s10.*
DISPLAY BY NAME r_s10.s10_descripcion
IF flag = 1 THEN
	MESSAGE 'Presione cualquier tecla para salir ...'
	LET tecla = fgl_getkey()
	CLOSE WINDOW w_cxpf210_2
	LET int_flag = 0
	RETURN
END IF
LET int_flag = 0
INPUT BY NAME rm_c10.c10_base_ice
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_c10.c10_base_ice) THEN
			RETURN
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
	BEFORE FIELD c10_base_ice
		LET base_ice = rm_c10.c10_base_ice
	AFTER FIELD c10_base_ice
		IF rm_c10.c10_base_ice IS NULL THEN
			LET rm_c10.c10_base_ice = base_ice
			DISPLAY BY NAME rm_c10.c10_base_ice
		END IF
		LET rm_c10.c10_valor_ice = rm_c10.c10_base_ice *
						rm_c10.c10_porc_ice / 100
		DISPLAY BY NAME rm_c10.c10_valor_ice
END INPUT
CLOSE WINDOW w_cxpf210_2
LET int_flag = 0
RETURN

END FUNCTION



FUNCTION control_eliminacion()
DEFINE num_ret		LIKE cxpt028.p28_num_ret
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE anulo_rp, i	SMALLINT
DEFINE mensaje		VARCHAR(250)
DEFINE resp		CHAR(6)

DEFINE fecha_actual DATETIME YEAR TO SECOND

CALL fl_hacer_pregunta('Seguro de ELIMINAR esta Factura ?', 'No') RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
LET vm_max_detalle  = 250
LET vm_nota_credito = 'NC'
LET fecha_actual = fl_current()

INITIALIZE rm_c13.* TO NULL
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ordt013_2 CURSOR FOR
        SELECT * FROM ordt013
               WHERE c13_compania  = vg_codcia
                 AND c13_localidad = vg_codloc
                 AND c13_numero_oc = rm_c10.c10_numero_oc
                 AND c13_estado    = 'A'
	FOR UPDATE
OPEN q_ordt013_2
FETCH q_ordt013_2 INTO rm_c13.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	LET mensaje = 'La recepción # ', rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
			' esta bloqueada por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
IF rm_c13.c13_compania IS NULL THEN
	CLOSE q_ordt013_2
	FREE q_ordt013_2
	ROLLBACK WORK
	LET mensaje = 'La orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
		       ' no tiene ninguna recepción para que pueda ser anulada.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET anulo_rp = 0
FOREACH q_ordt013_2 INTO rm_c13.*
	DECLARE q_ordt014 CURSOR FOR
		SELECT c14_cantidad, c14_codigo, c14_descrip, c14_descuento,
			c14_precio
			FROM ordt014
			WHERE c14_compania  = rm_c13.c13_compania
			  AND c14_localidad = rm_c13.c13_localidad
			  AND c14_numero_oc = rm_c13.c13_numero_oc
			  AND c14_num_recep = rm_c13.c13_num_recep
	LET i = 1
	FOREACH q_ordt014 INTO r_detalle_6[i].*
		LET i = i + 1
		IF i > vm_max_detalle THEN
			CALL fl_mensaje_arreglo_incompleto()
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
	END FOREACH
	LET vm_ind_arr = i - 1
	IF vm_ind_arr = 0 THEN
		LET mensaje = 'La recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				' no tiene detalle.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
		EXIT FOREACH
	END IF
	IF NOT validar_recep_oc() THEN
		EXIT FOREACH
	END IF
	WHENEVER ERROR CONTINUE 
	DECLARE q_ordt010_3 CURSOR FOR 
		SELECT * FROM ordt010
			WHERE c10_compania  = rm_c13.c13_compania
			  AND c10_localidad = rm_c13.c13_localidad
			  AND c10_numero_oc = rm_c13.c13_numero_oc
		FOR UPDATE
	OPEN q_ordt010_3 
	FETCH q_ordt010_3 INTO r_c10.*
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		LET mensaje = 'La orden de compra # ',
				r_c10.c10_numero_oc USING "<<<<<<<&",
				' esta bloqueada por otro usuario.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	FOR i = 1 TO vm_ind_arr
		UPDATE ordt011
			SET c11_cant_rec = c11_cant_rec -
						r_detalle_6[i].c14_cantidad
			WHERE c11_compania  = r_c10.c10_compania
			  AND c11_localidad = r_c10.c10_localidad
			  AND c11_numero_oc = r_c10.c10_numero_oc
			  AND c11_codigo    = r_detalle_6[i].c14_codigo
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			LET mensaje = 'No se pudo actualizar el detalle de la',
					' orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END FOR 
	LET rm_c13.c13_fecha_eli = fl_current()
	LET i = 0
	UPDATE ordt013
		SET c13_estado    = 'E',
		    c13_fecha_eli = fecha_actual
		WHERE c13_compania  = rm_c13.c13_compania
		  AND c13_localidad = rm_c13.c13_localidad
		  AND c13_numero_oc = rm_c13.c13_numero_oc
		  AND c13_num_recep = rm_c13.c13_num_recep
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		LET mensaje = 'No se pudo eliminar la recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				'. Ha ocurrido un error de Base de ',
				'Datos, llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	IF rm_c10.c10_tipo_pago = 'R' THEN
		LET valor_aplicado = control_rebaja_deuda()  
		IF valor_aplicado < 0 THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
	END IF
	IF rm_c13.c13_tot_recep = rm_c10.c10_tot_compra THEN
		UPDATE ordt010 SET c10_estado = 'E' WHERE CURRENT OF q_ordt010_3
		IF STATUS < 0 THEN
			ROLLBACK WORK 
			LET mensaje = 'No se pudo actualizar el estado de la ',
					'orden de compra # ',
					r_c10.c10_numero_oc USING "<<<<<<<&",
					'. Ha ocurrido un error de Base de ',
					'Datos, llame al ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END IF		
	DECLARE q_cxpt028 CURSOR FOR 
		SELECT UNIQUE p28_num_ret
			FROM cxpt028
			WHERE p28_compania  = rm_c10.c10_compania
			  AND p28_localidad = rm_c10.c10_localidad
			  AND p28_codprov   = rm_c10.c10_codprov
			  AND p28_tipo_doc  = 'FA'
			  AND p28_num_doc   = rm_c13.c13_factura
	OPEN  q_cxpt028
	FETCH q_cxpt028 INTO num_ret
	CLOSE q_cxpt028
	FREE  q_cxpt028
	UPDATE cxpt027 SET p27_estado    = 'E',
			   p27_fecha_eli = fecha_actual
		WHERE p27_compania  = rm_c10.c10_compania
		  AND p27_localidad = rm_c10.c10_localidad
		  AND p27_num_ret   = num_ret
	IF STATUS < 0 THEN
		ROLLBACK WORK 
		LET mensaje = 'No se pudo eliminar la retención de la ',
				'recepción # ',
				rm_c13.c13_num_recep USING "<<<<&&",
				' por orden de compra # ',
				rm_c13.c13_numero_oc USING "<<<<<<<&",
				'. Ha ocurrido un error de Base de ',
				'Datos, llame al ADMINISTRADOR.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	LET anulo_rp = 1
END FOREACH
WHENEVER ERROR STOP
COMMIT WORK
IF anulo_rp THEN
	CALL eliminar_diarios_contables_recep_reten_oc_anuladas()
	CALL cambiar_numero_fact_oc(rm_c10.c10_numero_oc)
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('Factura ha sido Eliminada.', 'info')

END FUNCTION



FUNCTION validar_recep_oc()
DEFINE r_p01	 	RECORD LIKE cxpt001.*
DEFINE r_c00	 	RECORD LIKE ordt000.*
DEFINE r_c01	 	RECORD LIKE ordt001.*
DEFINE r_t23	 	RECORD LIKE talt023.*
DEFINE num_recep	LIKE ordt013.c13_num_recep
DEFINE dias		SMALLINT
DEFINE mensaje		VARCHAR(250)
DEFINE pago		DECIMAL(14,2)

CALL fl_lee_compania_orden_compra(vg_codcia) RETURNING r_c00.*
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING rm_c10.*
IF rm_c10.c10_numero_oc IS NULL THEN
	LET mensaje = 'No existe la orden de compra # ',
			rm_c13.c13_numero_oc USING "<<<<<<<&",
			' en la Compañía.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
IF rm_c10.c10_estado <> 'C' THEN
	LET mensaje = 'No se puede anular la recepción # ',
			rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			'. Tiene la OC estado = ', rm_c10.c10_estado, '.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	ROLLBACK WORK
	LET mensaje = 'No existe Proveedor ',
			rm_c10.c10_codprov USING "<<<<<<<&",
			' en la Compañía.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
IF r_c01.c01_ing_bodega = 'S' AND r_c01.c01_modulo = 'RE' THEN
	LET mensaje = 'La orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			' pertenece a Inventario y debe ser anulada por ',
			'Devolución de Compra Local.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF 
LET rm_c13.c13_interes = rm_c10.c10_interes
IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_c10.c10_ord_trabajo)
		RETURNING r_t23.*
	IF r_t23.t23_estado <> 'A' THEN
		LET mensaje = 'La orden de trabajo # ',
				rm_c10.c10_ord_trabajo USING "<<<<<<<&",
				' asociada a la orden de compra # ',
				rm_c10.c10_numero_oc USING "<<<<<<<&",
				' tiene estado = ', r_t23.t23_estado, '.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
		RETURN 0
	END IF
END IF
LET dias = vg_fecha - rm_c10.c10_fecha_fact
IF (r_c00.c00_react_mes = 'S' AND (YEAR(vg_fecha) <> YEAR(rm_c10.c10_fecha_fact) OR
    MONTH(vg_fecha) <> MONTH(rm_c10.c10_fecha_fact))) OR
   (r_c00.c00_react_mes = 'N' AND dias > r_c00.c00_dias_react)
THEN
	LET mensaje = 'No se puede anular la recepción # ',
			rm_c13.c13_num_recep USING "<<<<&&",
			' por orden de compra # ',
			rm_c10.c10_numero_oc USING "<<<<<<<&",
			'. Revise la configuración de Compañías en el módulo',
			' de COMPRAS.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
DECLARE q_num_f CURSOR FOR
	SELECT c13_factura, c13_num_recep
		FROM ordt013
		WHERE c13_compania  = vg_codcia
		  AND c13_localidad = vg_codloc
		  AND c13_numero_oc = rm_c10.c10_numero_oc
		  AND c13_estado    = 'A'
		ORDER BY c13_num_recep DESC
OPEN q_num_f
FETCH q_num_f INTO rm_c13.c13_factura, num_recep
CLOSE q_num_f
FREE q_num_f
SELECT NVL(SUM((p20_valor_cap + p20_valor_int) -
		(p20_saldo_cap + p20_saldo_int)), 0)
	INTO pago
	FROM cxpt020
	WHERE p20_compania  = rm_c10.c10_compania
	  AND p20_localidad = rm_c10.c10_localidad
	  AND p20_codprov   = rm_c10.c10_codprov
	  AND p20_num_doc   = rm_c13.c13_factura
	  AND p20_numero_oc = rm_c10.c10_numero_oc
IF pago <> 0 THEN
	CALL fl_mostrar_mensaje('Esta recepción de orden compra no puede ser anulada, porque ha sido parcial o totalmente pagada.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_rebaja_deuda()
DEFINE num_row		INTEGER
DEFINE i		SMALLINT
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE aplicado_cap	DECIMAL(14,2)
DEFINE aplicado_int	DECIMAL(14,2)
DEFINE valor_aplicar	DECIMAL(14,2)
DEFINE valor_favor	LIKE cxpt021.p21_valor
DEFINE tot_ret		DECIMAL(14,2)
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p21		RECORD LIKE cxpt021.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*

LET tot_ret = 0
SELECT p27_total_ret INTO tot_ret
	FROM cxpt027
	WHERE p27_compania  = rm_c13.c13_compania
	  AND p27_localidad = rm_c13.c13_localidad
	  AND p27_num_ret   = rm_c13.c13_num_ret 
INITIALIZE r_p21.* TO NULL
LET r_p21.p21_compania   = vg_codcia
LET r_p21.p21_localidad  = vg_codloc
LET r_p21.p21_codprov    = rm_c10.c10_codprov
LET r_p21.p21_tipo_doc   = vm_nota_credito
LET r_p21.p21_num_doc    = nextValInSequence('TE', vm_nota_credito)
LET r_p21.p21_referencia = 'ANULACION RECEPCION # ',
				rm_c13.c13_num_recep USING "<&", ' OC # ',
				rm_c13.c13_numero_oc USING "<<<<&"
LET r_p21.p21_fecha_emi  = vg_fecha
LET r_p21.p21_moneda     = rm_c10.c10_moneda
LET r_p21.p21_paridad    = rm_c10.c10_paridad
LET r_p21.p21_valor      = rm_c13.c13_tot_recep - tot_ret
LET r_p21.p21_saldo      = rm_c13.c13_tot_recep - tot_ret
LET r_p21.p21_subtipo    = 1
LET r_p21.p21_origen     = 'A'
LET r_p21.p21_usuario    = vg_usuario
LET r_p21.p21_fecing     = fl_current()
INSERT INTO cxpt021 VALUES(r_p21.*)
-- Para aplicar la nota de credito
DECLARE q_ddev CURSOR FOR 
	SELECT * FROM cxpt020
		WHERE p20_compania                  = vg_codcia
	          AND p20_localidad                 = vg_codloc
	          AND p20_codprov                   = rm_c10.c10_codprov
	          AND p20_tipo_doc                  = 'FA'
	          AND p20_num_doc                   = rm_c13.c13_factura
		  AND p20_saldo_cap + p20_saldo_int > 0
		FOR UPDATE
INITIALIZE r_p22.* TO NULL
LET r_p22.p22_compania  = vg_codcia
LET r_p22.p22_localidad = vg_codloc
LET r_p22.p22_codprov	= rm_c10.c10_codprov
LET r_p22.p22_tipo_trn  = 'AJ'
LET r_p22.p22_num_trn 	= fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
				'TE', 'AA', r_p22.p22_tipo_trn)
IF r_p22.p22_num_trn <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_p22.p22_referencia  = r_p21.p21_referencia CLIPPED
LET r_p22.p22_fecha_emi   = vg_fecha
LET r_p22.p22_moneda 	  = rm_c10.c10_moneda
LET r_p22.p22_paridad 	  = rm_c10.c10_paridad
LET r_p22.p22_tasa_mora   = 0
LET r_p22.p22_total_cap   = 0
LET r_p22.p22_total_int   = 0
LET r_p22.p22_total_mora  = 0
LET r_p22.p22_subtipo 	  = 1
LET r_p22.p22_origen 	  = 'A'
LET r_p22.p22_fecha_elim  = NULL
LET r_p22.p22_tiptrn_elim = NULL
LET r_p22.p22_numtrn_elim = NULL
LET r_p22.p22_usuario 	  = vg_usuario
LET r_p22.p22_fecing 	  = fl_current()
INSERT INTO cxpt022 VALUES (r_p22.*)
LET num_row        = SQLCA.SQLERRD[6]
LET valor_favor    = r_p21.p21_valor 
LET i              = 0
LET valor_aplicado = 0
FOREACH q_ddev INTO r_p20.*
	LET valor_aplicar = valor_favor - valor_aplicado
	IF valor_aplicar = 0 THEN
		EXIT FOREACH
	END IF
	LET i            = i + 1
	LET aplicado_cap = 0
	LET aplicado_int = 0
	IF r_p20.p20_saldo_int <= valor_aplicar THEN
		LET aplicado_int = r_p20.p20_saldo_int 
	ELSE
		LET aplicado_int = valor_aplicar
	END IF
	LET valor_aplicar = valor_aplicar - aplicado_int
	IF r_p20.p20_saldo_cap <= valor_aplicar THEN
		LET aplicado_cap = r_p20.p20_saldo_cap 
	ELSE
		LET aplicado_cap = valor_aplicar
	END IF
	LET valor_aplicado       = valor_aplicado + aplicado_cap + aplicado_int
	LET r_p22.p22_total_cap  = r_p22.p22_total_cap + (aplicado_cap * -1)
	LET r_p22.p22_total_int  = r_p22.p22_total_int + (aplicado_int * -1)
    	LET r_p23.p23_compania   = vg_codcia
    	LET r_p23.p23_localidad  = vg_codloc
    	LET r_p23.p23_codprov	 = r_p22.p22_codprov
    	LET r_p23.p23_tipo_trn   = r_p22.p22_tipo_trn
    	LET r_p23.p23_num_trn    = r_p22.p22_num_trn
    	LET r_p23.p23_orden 	 = i
    	LET r_p23.p23_tipo_doc   = r_p20.p20_tipo_doc
    	LET r_p23.p23_num_doc 	 = r_p20.p20_num_doc
    	LET r_p23.p23_div_doc 	 = r_p20.p20_dividendo
    	LET r_p23.p23_tipo_favor = r_p21.p21_tipo_doc
    	LET r_p23.p23_doc_favor  = r_p21.p21_num_doc
    	LET r_p23.p23_valor_cap  = aplicado_cap * -1
    	LET r_p23.p23_valor_int  = aplicado_int * -1
    	LET r_p23.p23_valor_mora = 0
    	LET r_p23.p23_saldo_cap  = r_p20.p20_saldo_cap
    	LET r_p23.p23_saldo_int  = r_p20.p20_saldo_int
	INSERT INTO cxpt023 VALUES (r_p23.*)
	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap - aplicado_cap,
	                   p20_saldo_int = p20_saldo_int - aplicado_int
		WHERE CURRENT OF q_ddev
END FOREACH
UPDATE cxpt021 SET p21_saldo = p21_saldo - valor_aplicado
	WHERE p21_compania  = r_p21.p21_compania
	  AND p21_localidad = r_p21.p21_localidad
	  AND p21_codprov   = r_p21.p21_codprov
	  AND p21_tipo_doc  = r_p21.p21_tipo_doc
	  AND p21_num_doc   = r_p21.p21_num_doc
IF i = 0 THEN
	DELETE FROM cxpt022 WHERE ROWID = num_row
ELSE
	UPDATE cxpt022 SET p22_total_cap = r_p22.p22_total_cap,
	                   p22_total_int = r_p22.p22_total_int
		WHERE ROWID = num_row
END IF
RETURN valor_aplicado

END FUNCTION



FUNCTION genera_secuencia_oc()
DEFINE num_oc		LIKE ordt010.c10_numero_oc

{*
 * Primero leemos la tabla de secuencias, si obtenemos un valor no nulo y 
 * mayor a cero usamos ese valor para insertar; caso contrario recurrimos 
 * al viejo y efectivo método de buscar el último registro y sumarle uno
 *}

LET num_oc = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'OC',
											 'AA', 'OC')
IF num_oc IS NOT NULL AND num_oc > 0 THEN
	RETURN num_oc
END IF

SELECT MAX(c10_numero_oc) + 1
  INTO num_oc
  FROM ordt010
 WHERE c10_compania  = vg_codcia
   AND c10_localidad = vg_codloc

-- Si el resultado es nulo, es el primer registro
IF num_oc IS NULL THEN   
	LET num_oc = 1
END IF

RETURN num_oc

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran
DEFINE retVal 		SMALLINT

SET LOCK MODE TO WAIT 
LET retVal   = -1
WHILE retVal = -1
	LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
							modulo, 'AA', tipo_tran)
	IF retVal = 0 THEN
		SET LOCK MODE TO NOT WAIT
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe configuracion de secuencias para este tipo de transacción.','stop')
		EXIT PROGRAM
	END IF
	IF retVal <> -1 THEN
		EXIT WHILE
	END IF
END WHILE
SET LOCK MODE TO NOT WAIT
RETURN retVal

END FUNCTION



FUNCTION eliminar_diarios_contables_recep_reten_oc_anuladas()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c40		RECORD LIKE ordt040.*
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE num_ret		LIKE cxpt027.p27_num_ret

DECLARE q_eli_cont CURSOR WITH HOLD FOR
	SELECT ordt010.*, ordt013.*
		FROM ordt010, ordt013
		WHERE c10_compania  = vg_codcia
		  AND c10_localidad = vg_codloc
		  AND c10_numero_oc = rm_c10.c10_numero_oc
		  AND c10_estado    = 'E'
		  AND c13_compania  = c10_compania
		  AND c13_localidad = c10_localidad
		  AND c13_numero_oc = c10_numero_oc
		  AND c13_estado    = c10_estado
		ORDER BY c10_numero_oc
FOREACH q_eli_cont INTO r_c10.*, r_c13.*
	INITIALIZE r_c40.*, num_ret TO NULL
	SELECT * INTO r_c40.* FROM ordt040
		WHERE c40_compania  = r_c13.c13_compania
		  AND c40_localidad = r_c13.c13_localidad
		  AND c40_numero_oc = r_c13.c13_numero_oc
		  AND c40_num_recep = r_c13.c13_num_recep
	IF r_c40.c40_compania IS NOT NULL THEN
		CALL eliminar_diario_contable(r_c40.c40_compania,
						r_c40.c40_tipo_comp,
						r_c40.c40_num_comp,
						r_c13.*, 1)
	END IF
	DECLARE q_obtret CURSOR FOR 
		SELECT UNIQUE p28_num_ret
			FROM cxpt028
			WHERE p28_compania  = r_c10.c10_compania
			  AND p28_localidad = r_c10.c10_localidad
			  AND p28_codprov   = r_c10.c10_codprov
			  AND p28_tipo_doc  = 'FA'
			  AND p28_num_doc   = r_c13.c13_factura
	OPEN  q_obtret
	FETCH q_obtret INTO num_ret
	CLOSE q_obtret
	FREE  q_obtret
	IF num_ret IS NOT NULL THEN
		CALL fl_lee_retencion_cxp(r_c13.c13_compania,
						r_c13.c13_localidad, num_ret)
			RETURNING r_p27.*
		IF r_p27.p27_tip_contable IS NOT NULL THEN
			IF r_p27.p27_estado = 'E' THEN
			       CALL eliminar_diario_contable(r_p27.p27_compania,
							r_p27.p27_tip_contable,
							r_p27.p27_num_contable,
							r_c13.*, 2)
			END IF
		END IF
	END IF
	CALL fl_genera_saldos_proveedor(r_c13.c13_compania, r_c13.c13_localidad,
					r_c10.c10_codprov)
END FOREACH

END FUNCTION



FUNCTION eliminar_diario_contable(codcia, tipo_comp, num_comp, r_c13, flag)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE flag		SMALLINT
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE mensaje		VARCHAR(250)
DEFINE mens_com		VARCHAR(100)

DEFINE fecha_actual DATETIME YEAR TO SECOND

CALL fl_lee_comprobante_contable(codcia, tipo_comp, num_comp) RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	CASE flag
		WHEN 1
			LET mens_com = 'contable para la recepción # ',
					r_c13.c13_num_recep USING "<<<<&&"
		WHEN 2
			LET mens_com = 'contable para la retención # ',
					r_c13.c13_num_ret USING "<<<<&&",
					'de la recepción # ',
					r_c13.c13_num_recep USING "<<<<&&"
	END CASE
	LET mensaje = 'No existe en la ctbt012 comprobante',
			mens_com CLIPPED,
			' por orden de compra # ',
			r_c13.c13_numero_oc USING "<<<<<<<&",
			' para el comprobante contable ',
			tipo_comp, '-', num_comp, '.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'stop')
	RETURN
END IF
IF r_b12.b12_estado = 'E' THEN
	RETURN
END IF
CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
				r_b12.b12_num_comp, 'D')
SET LOCK MODE TO WAIT 5
LET fecha_actual = fl_current()
UPDATE ctbt012 SET b12_estado     = 'E',
		   b12_fec_modifi = fecha_actual 
	WHERE b12_compania  = r_b12.b12_compania
	  AND b12_tipo_comp = r_b12.b12_tipo_comp
	  AND b12_num_comp  = r_b12.b12_num_comp

END FUNCTION



FUNCTION cambiar_numero_fact_oc(orden_oc)
DEFINE orden_oc		LIKE ordt010.c10_numero_oc
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE i, lim		INTEGER
DEFINE query		CHAR(800)

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, orden_oc) RETURNING r_c10.*
INITIALIZE r_c13.* TO NULL
DECLARE q_recep CURSOR FOR
	SELECT * FROM ordt013
		WHERE c13_compania  = r_c10.c10_compania
		  AND c13_localidad = r_c10.c10_localidad
		  AND c13_numero_oc = orden_oc
		  AND c13_estado    = 'E'
OPEN q_recep
FETCH q_recep INTO r_c13.*
CLOSE q_recep
FREE q_recep
LET i   = 1
LET lim = LENGTH(r_c13.c13_factura)
CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, r_c10.c10_codprov, 'FA',
				r_c13.c13_factura, 1)
	RETURNING r_p20.*
WHILE TRUE
	LET vm_fact_nue = r_p20.p20_num_doc[1, 3],
				r_p20.p20_num_doc[5, lim] CLIPPED,
				i USING "<<<<<<<<&"
	CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
					r_c10.c10_codprov, 'FA',
					vm_fact_nue, 1)
		RETURNING r_p20.*
	IF r_p20.p20_compania IS NULL THEN
		EXIT WHILE
	END IF
	LET lim = LENGTH(vm_fact_nue)
	LET i   = i + 1
END WHILE
BEGIN WORK
WHENEVER ERROR STOP 
LET query = 'UPDATE ordt010 ',
		' SET c10_factura = "', vm_fact_nue CLIPPED, '"',
		' WHERE c10_compania  = ', vg_codcia,
		'   AND c10_localidad = ', vg_codloc,
		'   AND c10_numero_oc = ', r_c10.c10_numero_oc
PREPARE exec_up01 FROM query
EXECUTE exec_up01
LET query = 'UPDATE ordt013 ',
		' SET c13_factura  = "', vm_fact_nue CLIPPED, '", ',
		'     c13_num_guia = "', vm_fact_nue CLIPPED, '"',
		' WHERE c13_compania  = ', vg_codcia,
		'   AND c13_localidad = ', vg_codloc,
		'   AND c13_numero_oc = ', r_c10.c10_numero_oc,
		'   AND c13_estado    = "E" ',
		'   AND c13_num_recep = ', r_c13.c13_num_recep
PREPARE exec_up02 FROM query
EXECUTE exec_up02
DECLARE q_p23 CURSOR FOR
	SELECT * FROM cxpt023
		WHERE p23_compania  = vg_codcia
	          AND p23_localidad = vg_codloc
	          AND p23_codprov   = r_c10.c10_codprov
	          AND p23_tipo_doc  = 'FA'
	          AND p23_num_doc   = r_c13.c13_factura
OPEN q_p23
FETCH q_p23 INTO r_p23.*
IF STATUS = NOTFOUND THEN
	LET query = 'UPDATE cxpt020 ',
			' SET p20_num_doc = "', vm_fact_nue CLIPPED, '"',
			' WHERE p20_compania  = ', vg_codcia,
			'   AND p20_localidad = ', vg_codloc,
			'   AND p20_codprov   = ', r_c10.c10_codprov,
			'   AND p20_tipo_doc  = "FA" ',
			'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
	PREPARE exec_up03 FROM query
	EXECUTE exec_up03
	COMMIT WORK
	RETURN
END IF
SELECT * FROM cxpt020
	WHERE p20_compania  = vg_codcia
          AND p20_localidad = vg_codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = r_c13.c13_factura
	INTO TEMP tmp_p20
LET query = 'UPDATE tmp_p20 ',
		' SET p20_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p20_compania  = ', vg_codcia,
		'   AND p20_localidad = ', vg_codloc,
		'   AND p20_codprov   = ', r_c10.c10_codprov,
		'   AND p20_tipo_doc  = "FA" ',
		'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up04 FROM query
EXECUTE exec_up04
INSERT INTO cxpt020 SELECT * FROM tmp_p20
LET query = 'UPDATE cxpt023 ',
		' SET p23_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p23_compania  = ', vg_codcia,
		'   AND p23_localidad = ', vg_codloc,
		'   AND p23_codprov   = ', r_c10.c10_codprov,
		'   AND p23_tipo_doc  = "FA" ',
		'   AND p23_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up05 FROM query
EXECUTE exec_up05
LET query = 'UPDATE cxpt025 ',
		' SET p25_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p25_compania  = ', vg_codcia,
		'   AND p25_localidad = ', vg_codloc,
		'   AND p25_codprov   = ', r_c10.c10_codprov,
		'   AND p25_tipo_doc  = "FA" ',
		'   AND p25_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up06 FROM query
EXECUTE exec_up06
LET query = 'UPDATE cxpt028 ',
		' SET p28_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p28_compania  = ', vg_codcia,
		'   AND p28_localidad = ', vg_codloc,
		'   AND p28_codprov   = ', r_c10.c10_codprov,
		'   AND p28_tipo_doc  = "FA" ',
		'   AND p28_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up07 FROM query
EXECUTE exec_up07
LET query = 'UPDATE cxpt041 ',
		' SET p41_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p41_compania  = ', vg_codcia,
		'   AND p41_localidad = ', vg_codloc,
		'   AND p41_codprov   = ', r_c10.c10_codprov,
		'   AND p41_tipo_doc  = "FA" ',
		'   AND p41_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_up08 FROM query
EXECUTE exec_up08
LET query = 'DELETE FROM cxpt020 ',
		' WHERE p20_compania  = ', vg_codcia,
		'   AND p20_localidad = ', vg_codloc,
		'   AND p20_codprov   = ', r_c10.c10_codprov,
		'   AND p20_tipo_doc  = "FA" ',
		'   AND p20_num_doc   = "', r_c13.c13_factura, '"'
PREPARE exec_del01 FROM query
EXECUTE exec_del01
WHENEVER ERROR STOP 
COMMIT WORK
DROP TABLE tmp_p20

END FUNCTION



FUNCTION retorna_num_aut()
DEFINE r_s18		RECORD LIKE srit018.*

LET rm_c13.c13_num_aut = vg_fecha USING "ddmmyyyy"
INITIALIZE r_s18.* TO NULL
DECLARE q_s18 CURSOR FOR
	SELECT * FROM srit018
		WHERE s18_compania  = vg_codcia
		  AND s18_cod_ident = rm_p01.p01_tipo_doc
		  AND s18_tipo_tran = 1
OPEN q_s18
FETCH q_s18 INTO r_s18.*
CLOSE q_s18
FREE q_s18
LET rm_c13.c13_num_aut = rm_c13.c13_num_aut, r_s18.s18_sec_tran
LET rm_c13.c13_num_aut = rm_c13.c13_num_aut, rm_p01.p01_num_doc CLIPPED, '2',
					rm_c13.c13_num_guia[1, 3] CLIPPED,
					rm_c13.c13_num_guia[5, 7] CLIPPED,
					rm_c13.c13_num_guia[9, 17] CLIPPED,
					rm_p01.p01_num_aut
DISPLAY BY NAME rm_c13.c13_num_aut

END FUNCTION

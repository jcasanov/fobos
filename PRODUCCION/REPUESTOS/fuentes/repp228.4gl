{*
 * Titulo           : repp228.4gl - Ingreso a Bodega x Devolucion de Facturas
 * Elaboracion      : 23-sep-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp228 base modulo compania localidad
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE
DEFINE vm_elementos	SMALLINT	-- NUMERO MAXIMO DE ELEMENTOS DEL 
				        -- ARREGLO

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r00		 	RECORD LIKE rept000.*	-- CONFIGURACION DE LA
							-- COMPAÑIA DE RPTO.
DEFINE rm_r01		 	RECORD LIKE rept001.*	-- VENDEDORES
DEFINE rm_r02		 	RECORD LIKE rept002.*	-- BODEGA
DEFINE rm_r10		 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r11		 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r19, rm_fact		RECORD LIKE rept019.*	-- CAB. TRANSACCIONES
DEFINE rm_r20			RECORD LIKE rept020.*	-- DET. TRANSACCIONES
DEFINE rm_g13		 	RECORD LIKE gent013.*	-- MONEDAS.
DEFINE rm_c01			RECORD LIKE cxct001.*   -- CLIENTES GENERAL.
DEFINE rm_c02			RECORD LIKE cxct002.*   -- CLIENTES LOCALIDAD.
DEFINE rm_j10			RECORD LIKE cajt010.*   -- REGISTRO DE CAJA

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[200] OF RECORD
	r20_cant_ven		LIKE rept020.r20_cant_ven,
	r20_cant_dev		LIKE rept020.r20_cant_dev,
	r20_item			LIKE rept020.r20_item,
	r10_nombre			LIKE rept010.r10_nombre
	END RECORD
	----------------------------------------------------------
	---- ARREGLO PARALELO PARA LOS OTROS CAMPOS ----
DEFINE r_detalle_1 ARRAY[200] OF RECORD
	vm_cant_dev		LIKE rept020.r20_cant_dev,  -- PARA ALMACENAR
							    -- LA CANT.DEVUELTA
							    -- ANTERIORMENTE
	r20_fob			LIKE rept020.r20_fob,
	r20_costo		LIKE rept020.r20_costo,
	r20_costant_mb		LIKE rept020.r20_costant_mb,
	r20_costant_ma		LIKE rept020.r20_costant_ma,
	r20_costnue_mb		LIKE rept020.r20_costant_mb,
	r20_costnue_ma		LIKE rept020.r20_costant_ma,
	r20_linea		LIKE rept020.r20_linea,
	r20_rotacion		LIKE rept020.r20_rotacion,
	r20_val_descto		LIKE rept020.r20_val_descto,
	r20_val_impto		LIKE rept020.r20_val_impto,
	r20_descuento		LIKE rept020.r20_descuento,
	r20_precio		LIKE rept020.r20_precio,
	subtotal_item		LIKE rept019.r19_tot_neto,
	val_costo		LIKE rept019.r19_tot_costo
	END RECORD
	----------------------------------------------------------

DEFINE vm_cod_dev	LIKE rept019.r19_cod_tran
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_cod_tran_2	LIKE rept019.r19_cod_tran

DEFINE vm_flag_devolucion	CHAR(1)	   -- FLAG DE DEVOLUCION
					   -- 'S' Si se puede devolver
					   -- 'N' No se puede devolver
DEFINE vm_flag_mant		CHAR(1)	   -- FLAG DE MANTENIMIENTO
					   -- 'I' --> INGRESO		
					   -- 'M' --> MODIFICACION		
					   -- 'C' --> CONSULTA		
DEFINE vm_ind_arr		SMALLINT   -- INDICE DE MI ARREGLO (INPUT ARRAY)
DEFINE vm_filas_pant		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_impuesto    		DECIMAL(12,2)	-- TOTAL DEL IMPUESTO
DEFINE vg_cod_tran	 	LIKE gent021.g21_cod_tran
DEFINE vg_num_tran		LIKE rept019.r19_num_tran



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp228.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_cod_tran = arg_val(5)
LET vg_num_tran = arg_val(6)
LET vg_proceso = 'repp228'

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
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_cod_dev      = 'NI'
LET vm_cod_tran     = 'FA'
LET vm_cod_tran_2   = vm_cod_dev
LET vm_max_rows     = 1000
LET vm_elementos    = 250
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_228 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_228 FROM '../forms/repf228_1'
DISPLAY FORM f_228
CALL control_display_botones()

LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Ver Factura'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
                HIDE OPTION 'Imprimir'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
			SHOW OPTION 'Ver Factura'
                	SHOW OPTION 'Imprimir'
			CALL control_consulta()
			IF vm_ind_arr > vm_filas_pant THEN
				SHOW OPTION 'Ver Detalle'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
                CALL control_ingreso()
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Ver Factura'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Imprimir'
		END IF
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
		HIDE OPTION 'Imprimir'
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				SHOW OPTION 'Ver Factura'
				SHOW OPTION 'Ver Detalle'
			END IF 
                ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
                        SHOW OPTION 'Avanzar'
                END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('F') 'Ver Factura' 		'Ver Factura de la Transacción.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_factura(rm_r19.r19_num_dev)
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('V') 'Ver Detalle' 		'Ver Detalle de la Transacción.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF 
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
        COMMAND KEY('P') 'Imprimir'		'Imprime la devolución.'
        	CALL imprimir()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ver_factura(num_tran)
DEFINE num_tran 	LIKE rept019.r19_num_tran
DEFINE command_line	VARCHAR(100)
DEFINE r_r19		RECORD LIKE rept019.*

CALL fl_lee_cabecera_transaccion_rep(vg_codcia,vg_codloc, vm_cod_tran, num_tran)
	RETURNING r_r19.*

IF r_r19.r19_num_tran IS NULL THEN
	CALL fgl_winmessage(vg_producto,'La factura no existe en la Compañía',
			    'exclamation')
	RETURN
END IF

LET command_line = 'fglrun repp308 ' || vg_base || ' '
	    || vg_modulo || ' ' || vg_codcia 
	    || ' ' || vg_codloc || ' ' ||
	    vm_cod_tran || ' ' || num_tran
RUN command_line

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'C Ven.'		TO tit_col1
DISPLAY 'C Dev.'		TO tit_col2
DISPLAY 'Item'			TO tit_col3
DISPLAY 'Descripcion'	TO tit_col4

IF vm_flag_mant = 'C' THEN
	DISPLAY 'C Dev.'	TO tit_col1
	DISPLAY ' '			TO tit_col2
END IF

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE i,j 	SMALLINT
DEFINE r_r10 	RECORD LIKE rept010.*

CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.*
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT', '')
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()

		IF r_detalle[i].r20_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
				RETURNING r_r10.*
				DISPLAY BY NAME r_r10.r10_nombre
		END IF
        AFTER DISPLAY
                CONTINUE DISPLAY
        ON KEY(INTERRUPT)
                EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT
DEFINE pago_fact_nc_pa 	CHAR(1)
DEFINE val_ant 		DECIMAL(12,2)

CLEAR FORM
LET vm_flag_mant = 'I'
CALL control_display_botones()

INITIALIZE rm_r19.*, rm_r20.* TO NULL
LET rm_r19.r19_fecing   = CURRENT
LET rm_r19.r19_usuario  = vg_usuario
LET rm_r19.r19_cod_tran = vm_cod_tran_2
LET rm_r19.r19_tipo_dev = vm_cod_tran
DISPLAY BY NAME rm_r19.r19_fecing,   rm_r19.r19_usuario, 
		rm_r19.r19_tipo_dev

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		LET vm_flag_mant = 'C'
		CLEAR FORM
		CALL control_display_botones()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
	DECLARE q_read_r19 CURSOR FOR SELECT * FROM rept019
		WHERE  r19_compania  = vg_codcia
		AND    r19_localidad = vg_codloc
		AND    r19_cod_tran  = rm_r19.r19_cod_tran
		AND    r19_num_tran  = rm_r19.r19_num_tran
		FOR UPDATE

	OPEN q_read_r19
	FETCH q_read_r19
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF

WHENEVER ERROR STOP
LET i = control_cargar_detalle_factura()
IF i > vm_elementos THEN
	CLEAR FORM 
	CALL control_display_botones()
	RETURN
END IF


IF vm_flag_devolucion = 'N' THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,
			    'La factura ya ha sido devuelta totalmente.',
			    'exclamation')
	CLEAR FORM 
	CALL control_display_botones()
	RETURN
END IF

LET int_flag = 0
LET vm_num_detalles = ingresa_detalles() 
IF int_flag THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		LET vm_flag_mant = 'C'
		CLEAR FORM
		CALL control_display_botones()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET vm_cod_tran_2   = vm_cod_dev
IF rm_r19.r19_tot_neto = rm_fact.r19_tot_neto THEN
	IF TODAY = DATE(rm_fact.r19_fecing) THEN
		LET vm_cod_tran_2   = vm_cod_dev
		IF rm_fact.r19_cont_cred = 'R' THEN 
			IF NOT verifica_saldo_fact_devuelta() THEN
				LET vm_cod_tran_2   = vm_cod_dev
			END IF
		END IF
	ELSE
		LET vm_cod_tran_2   = vm_cod_dev
	END IF
END IF
LET done = control_cabecera()
DISPLAY BY NAME rm_r19.r19_cod_tran
IF done = 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'No se realizo el proceso.',
			    'exclamation')
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
LET done = control_ingreso_detalle()
IF done = 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso del detalle de la devolución. No se realizará el proceso.','exclamation')
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
LET done = control_actualiza_existencia()
IF done = 0 THEN
	ROLLBACK WORK 
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
CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc, 
	rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
CALL muestra_contadores()

CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_cargar_detalle_factura()
DEFINE r_r20 	RECORD LIKE rept020.*
DEFINE r_r10 	RECORD LIKE rept010.*
DEFINE i 	SMALLINT

LET vm_flag_devolucion = 'N'

DECLARE q_read_r20 CURSOR FOR SELECT * FROM rept020
	WHERE r20_compania  = vg_codcia
	AND   r20_localidad = vg_codloc
	AND   r20_cod_tran  = rm_r19.r19_cod_tran
	AND   r20_num_tran  = rm_r19.r19_num_tran 

LET i = 1 
FOREACH q_read_r20 INTO r_r20.*
	IF r_r20.r20_cant_ent > 0 THEN
		CALL fl_lee_item(vg_codcia, r_r20.r20_item)
			RETURNING r_r10.*
		LET r_detalle[i].r10_nombre       = r_r10.r10_nombre
		LET r_detalle_1[i].r20_linea      = r_r10.r10_linea
		LET r_detalle_1[i].r20_rotacion   = r_r10.r10_rotacion
		LET r_detalle_1[i].r20_fob        = r_r10.r10_fob
		LET r_detalle_1[i].r20_costant_mb = r_r20.r20_costant_mb
		LET r_detalle_1[i].r20_costant_ma = r_r20.r20_costant_ma
		LET r_detalle_1[i].r20_costnue_mb = r_r20.r20_costnue_mb
		LET r_detalle_1[i].r20_costnue_ma = r_r20.r20_costnue_ma
		LET r_detalle_1[i].r20_costo      = r_r20.r20_costo  
		LET r_detalle_1[i].vm_cant_dev    = r_r20.r20_cant_dev  
		LET r_detalle[i].r20_item         = r_r20.r20_item 
		LET r_detalle_1[i].r20_precio       = r_r20.r20_precio 
		LET r_detalle_1[i].r20_descuento    = r_r20.r20_descuento 
		LET r_detalle[i].r20_cant_ven     = r_r20.r20_cant_ent  
		LET r_detalle[i].r20_cant_dev     = 0 	  
		LET r_detalle_1[i].subtotal_item    = r_r20.r20_cant_dev * 
						    r_r20.r20_precio
		LET i = i + 1
	END IF
	IF i > vm_elementos THEN
		CALL fl_mensaje_arreglo_lleno()
		RETURN i
		EXIT FOREACH
	END IF
END FOREACH

LET vm_ind_arr = i - 1

FOR i = 1 TO vm_ind_arr
	IF r_detalle[i].r20_cant_ven > 0 THEN
		LET vm_flag_devolucion = 'S'
		EXIT FOR	
	END IF
END FOR

RETURN 0

END FUNCTION



FUNCTION control_cabecera()
DEFINE i,done 	SMALLINT
DEFINE resp		CHAR(6)
DEFINE num_tran  	LIKE rept019.r19_num_tran
DEFINE r_g14		RECORD 	LIKE gent014.*
DEFINE r_g21		RECORD 	LIKE gent021.*

	--- ACTUALIZO LOS VALORES PARA SU INGRESO ---
LET rm_r19.r19_tipo_dev = vm_cod_tran	  	-- TIPO DEV = 'FA' 
LET rm_r19.r19_cod_tran = vm_cod_tran_2		
LET rm_r19.r19_usuario  = vg_usuario			
LET rm_r19.r19_fecing   = CURRENT
LET rm_r19.r19_paridad  = 1

CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
LET rm_r19.r19_tipo_tran  = r_g21.g21_tipo
LET rm_r19.r19_calc_costo = r_g21.g21_calc_costo

IF rm_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(rm_r19.r19_moneda,rg_gen.g00_moneda_alt)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto,'No existe factor de conversión entre la moneda base y la moneda alterna.','stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET rm_r19.r19_paridad = r_g14.g14_tasa
END IF
	---------------------------------------------
LET done = 1
CALL control_num_transaccion()
	RETURNING num_tran
IF num_tran = -1 THEN
	RETURN 0
END IF 
LET rm_r19.r19_num_tran = num_tran		-- EL NUEVO NUMERO DE LA TRAN.	

INSERT INTO rept019 VALUES (rm_r19.*)
DISPLAY BY NAME rm_r19.r19_num_tran

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
        LET vm_num_rows = vm_num_rows + 1
END IF

LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 

IF status < 0 THEN
	LET done = 0
END IF
                                             	-- procesada
RETURN done

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE i,done,k		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*

LET done = 1
SET LOCK MODE TO WAIT 10
-- INITIAL VALUES FOR rm_r20 FIELDS
LET rm_r20.r20_compania  = vg_codcia
LET rm_r20.r20_localidad = vg_codloc
LET rm_r20.r20_num_tran  = rm_r19.r19_num_tran
LET rm_r20.r20_cod_tran  = vm_cod_tran_2
LET rm_r20.r20_fecing    = rm_r19.r19_fecing

LET k = 1
FOR i = 1 TO vm_ind_arr
	IF r_detalle[i].r20_cant_dev > 0 THEN
		
		CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,
     				      r_detalle[i].r20_item)
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			LET rm_r20.r20_stock_ant = 0
			LET rm_r20.r20_ubicacion = 'SN'
		ELSE
			LET rm_r20.r20_stock_ant = r_r11.r11_stock_act
			LET rm_r20.r20_ubicacion = r_r11.r11_ubicacion
		END IF
		
		----ACTUALIZO LA CANTIDAD DEV EN LA FACTURA INGRESADA ----
		UPDATE rept020 
			SET   r20_cant_dev  = r_detalle[i].r20_cant_dev + 
					      r_detalle_1[i].vm_cant_dev
			WHERE r20_compania  = vg_codcia
			AND   r20_localidad = vg_codloc
			AND   r20_cod_tran  = vm_cod_tran 	 -- 'FA'
			AND   r20_num_tran  = rm_r19.r19_num_dev -- FACTURA DEV.
			AND   r20_item      = r_detalle[i].r20_item 
		---------------------------------------------------------
		LET rm_r20.r20_item       = r_detalle[i].r20_item
    	CALL fl_lee_item(vg_codcia, rm_r20.r20_item) RETURNING r_r10.*
		LET r_r10.r10_costult_mb  = r_detalle_1[i].r20_costo
		LET rm_r20.r20_cant_ped   = r_detalle[i].r20_cant_dev
		LET rm_r20.r20_cant_ven   = r_detalle[i].r20_cant_dev
		LET rm_r20.r20_cant_dev   = 0
		LET rm_r20.r20_cant_ent   = r_detalle[i].r20_cant_dev
		LET rm_r20.r20_stock_bd   = 0
		LET rm_r20.r20_precio     = r_r10.r10_costo_mb
		LET rm_r20.r20_descuento  = 0 
		LET rm_r20.r20_orden      = k
		LET rm_r20.r20_fob        = r_r10.r10_fob
		LET rm_r20.r20_costant_mb = r_r10.r10_costo_mb
		LET rm_r20.r20_costant_ma = 0
		LET rm_r20.r20_costnue_mb = r_r10.r10_costo_mb
		LET rm_r20.r20_costnue_ma = 0
		LET rm_r20.r20_linea      = r_detalle_1[i].r20_linea
		LET rm_r20.r20_rotacion   = r_detalle_1[i].r20_rotacion
		LET rm_r20.r20_costo      = r_r10.r10_costo_mb
		LET rm_r20.r20_val_descto = 0 
		LET rm_r20.r20_val_impto  = 0
		INSERT INTO rept020 VALUES(rm_r20.*)

		CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc, 
							rm_r20.r20_cod_tran, rm_r20.r20_num_tran, rm_r20.r20_item)
		LET k = k + 1
	END IF
END FOR 
IF status < 0 THEN
	LET done = 0
END IF

RETURN done

END FUNCTION



FUNCTION control_actualiza_existencia()
DEFINE i,done 		SMALLINT
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE cant_dev		LIKE rept020.r20_cant_dev

SET LOCK MODE TO WAIT
LET done = 1

FOR i = 1 TO vm_ind_arr
	LET cant_dev = r_detalle[i].r20_cant_dev 

	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,
				      r_detalle[i].r20_item)	
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			{*
             * De hecho esto es absurdo, como podria ser
             * nulo si ya hubo en existencia el item?
             * Debe ser al menos 0.
             *}
			INSERT INTO rept011
	      			(r11_compania, r11_bodega, r11_item, 
				 r11_ubicacion, r11_stock_ant, 
				 r11_stock_act, r11_ing_dia,
				 r11_egr_dia)
			VALUES(vg_codcia, rm_r19.r19_bodega_ori,
			       r_detalle[i].r20_item, 'SN', 
			       0, cant_dev, cant_dev, 0) 
		ELSE	 
			UPDATE rept011 
				SET   r11_stock_ant = r11_stock_act,
		     	     	      r11_stock_act = r11_stock_act + 
		      		         	      cant_dev,
		      	     	      r11_ing_dia   = cant_dev
			 WHERE r11_compania = vg_codcia
		  	   AND   r11_bodega = rm_r19.r19_bodega_ori
			   AND   r11_item   = r_detalle[i].r20_item 
		END IF

END FOR 

SET LOCK MODE TO NOT WAIT

RETURN done

END FUNCTION



FUNCTION control_num_transaccion()
DEFINE num_tran 	LIKE rept019.r19_num_tran
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE resp 		CHAR(6)

CALL fl_lee_compania_repuestos(vg_codcia)  
        RETURNING r_r00.*                
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc,  vg_modulo,
	                             'AA', vm_cod_tran_2)
	RETURNING num_tran
CASE num_tran 
	WHEN 0
			CALL fgl_winmessage(vg_producto,'No existe control de'||
				    ' secuencia para esta transacción, no se'||
				    ' puede asignar un número de transacción'||
				    ' a la operación. ','stop')
			EXIT PROGRAM
	WHEN -1
		WHILE num_tran = -1
			CALL fgl_winquestion(vg_producto, 
      					     'Registro está siendo modificado'||
				      	     ' por otro usuario, desea' ||
                                             ' intentarlo nuevamente', 'No',
         				     'Yes|No', 'question', 1)
				RETURNING resp
			IF resp = 'No' THEN
				EXIT WHILE
			ELSE
				IF num_tran <> -1 THEN
					EXIT WHILE
				END IF
			END IF
			CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA', vm_cod_tran_2)
				RETURNING num_tran
		END WHILE
END CASE

RETURN num_tran

END FUNCTION



FUNCTION lee_datos()

DEFINE resp 		CHAR(6)
DEFINE comando 		CHAR(600)
DEFINE done		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r19_referencia	LIKE rept019.r19_referencia
DEFINE r19_bodega_ori	LIKE rept019.r19_bodega_ori

LET int_flag = 0
LET r19_referencia = NULL
INPUT BY NAME rm_r19.r19_num_dev, rm_r19.r19_codcli, r19_referencia, 
			  r19_bodega_ori
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
	ON KEY(F5)
		IF INFIELD(r19_num_dev) THEN
			IF rm_r19.r19_num_dev IS NOT NULL THEN
				CALL control_ver_factura(rm_r19.r19_num_dev)
			END IF
		END IF
	ON KEY(F2)
		IF INFIELD(r19_num_dev) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      vm_cod_tran)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli 
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							    vg_codloc,
							    vm_cod_tran,
							    r_r19.r19_num_tran)
					RETURNING rm_r19.*
				LET rm_r19.r19_num_dev = rm_r19.r19_num_tran
				CALL control_display_cabecera()
		      	END IF
		END IF
                IF INFIELD(r19_codcli) THEN
                        CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
                                RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
                        IF r_z01.z01_codcli IS NOT NULL THEN
                                LET rm_r19.r19_codcli = r_z01.z01_codcli
                                LET rm_r19.r19_nomcli = r_z01.z01_nomcli
                                DISPLAY BY NAME rm_r19.r19_codcli,
                                                rm_r19.r19_nomcli
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD r19_num_dev
		IF rm_r19.r19_num_dev IS NOT NULL THEN
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							    vg_codloc,
							    vm_cod_tran,
							    rm_r19.r19_num_dev)
				RETURNING r_r19.*
                	IF r_r19.r19_num_tran IS  NULL THEN
		    		CALL fgl_winmessage (vg_producto, 
					'La factura no existe en la Compañía. ',
					'exclamation')
                        	NEXT FIELD r19_num_dev
			END IF

			LET rm_r19.* = r_r19.*
			LET rm_r19.r19_num_dev = rm_r19.r19_num_tran
			LET rm_r19.r19_referencia = r19_referencia
			LET rm_r19.r19_bodega_ori = r19_bodega_ori

			CALL control_display_cabecera()

			CALL fl_lee_compania_repuestos(vg_codcia)  
        			RETURNING rm_r00.*                

			IF DATE(rm_r19.r19_fecing) + rm_r00.r00_dias_dev < 
			   TODAY 
			   THEN
				CALL fgl_winmessage(vg_producto,'La factura no puede ser devuelta porque supero el plazo para su devolución.','exclamation')
				NEXT FIELD r19_num_dev
			END IF

			IF rm_r19.r19_codcli IS NULL THEN
				CALL fgl_winquestion(vg_producto,
					'No hay código de cliente, desea ' ||
					'ingresar los datos del cliente. ',
					'No', 'Yes|No', 'question', 1)
					RETURNING resp
				IF resp = 'No' THEN
					NEXT FIELD r19_num_dev
				END IF	
				LET comando = 'cd ..',     vg_separador, 
					         '..',     vg_separador,
                                              'COBRANZAS', vg_separador, 
					      'fuentes',   vg_separador, 
                                              '; fglrun cxcp101 ', vg_base, ' ',
                                              'CO ', vg_codcia, ' ',
                                              vg_codloc
				RUN comando CLIPPED

				NEXT FIELD r19_codcli
			END IF
		ELSE 
			NEXT FIELD r19_num_dev
		END IF
        AFTER FIELD r19_codcli
		IF r_r19.r19_codcli IS NOT NULL THEN
                	LET rm_r19.r19_codcli = r_r19.r19_codcli
			DISPLAY BY NAME rm_r19.r19_codcli
		END IF
		IF r_r19.r19_codcli IS NULL AND
                	rm_r19.r19_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_r19.r19_codcli)
        			RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Cliente no existe.',
					'exclamation')
				NEXT FIELD r19_codcli
			END IF
			IF r_z01.z01_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
					'Cliente está bloqueado.',
					'exclamation')
				NEXT FIELD r19_codcli
			END IF
			LET rm_r19.r19_nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_r19.r19_nomcli

			UPDATE rept019 SET r19_codcli = r_z01.z01_codcli,
				 	   r19_nomcli = r_z01.z01_nomcli
				WHERE r19_compania  = vg_codcia
				  AND r19_localidad = vg_codloc
				  AND r19_cod_tran  = vm_cod_tran
				  AND r19_num_tran  = rm_r19.r19_num_dev
                END IF
               	IF rm_r19.r19_codcli IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Debe ingresar código del cliente.',
				'exclamation')
			NEXT FIELD r19_codcli
		END IF
	AFTER FIELD r19_bodega_ori
		IF rm_r19.r19_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Bodega no existe.',
						    		'exclamation')
				CLEAR nom_bodega
				NEXT FIELD r19_bodega_ori
			END IF 
			IF r_r02.r02_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto, 'Bodega está bloqueada.',
									'exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			IF r_r02.r02_localidad <> vg_codloc THEN
				CALL fgl_winmessage(vg_producto, 'Bodega no es de esta ' ||
												 'localidad.',
									'exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			IF r_r02.r02_factura <> 'S' THEN
				CALL fgl_winmessage(vg_producto, 'Bodega no factura.',
									'exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			DISPLAY r_r02.r02_nombre TO nom_bodega
		ELSE
			CLEAR nom_bodega
		END IF
	AFTER INPUT
		IF r19_referencia IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Debe ingresar motivo de la devolución.',
				'exclamation')
			NEXT FIELD r19_referencia
		END IF
		LET rm_r19.r19_referencia = r19_referencia
		IF r19_bodega_ori IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Debe ingresar bodega.',
				'exclamation')
			NEXT FIELD r19_bodega_ori
		END IF
		LET rm_r19.r19_bodega_ori = r19_bodega_ori
END INPUT
LET rm_fact.* = rm_r19.*

END FUNCTION



FUNCTION control_display_cabecera()

DISPLAY BY NAME rm_r19.r19_moneda,     rm_r19.r19_num_dev, 
		rm_r19.r19_bodega_ori, rm_r19.r19_porc_impto, 
		rm_r19.r19_codcli,     rm_r19.r19_nomcli,
		rm_r19.r19_cont_cred,  rm_r19.r19_vendedor ,
		rm_r19.r19_referencia

CALL fl_lee_moneda(rm_r19.r19_moneda)
	RETURNING rm_g13.*
	DISPLAY rm_g13.g13_nombre TO nom_moneda

CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
	RETURNING rm_r02.*
	DISPLAY rm_r02.r02_nombre TO nom_bodega

CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
	RETURNING rm_r01.*
	DISPLAY rm_r01.r01_nombres TO nom_vendedor

END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j,k,ind	SMALLINT
DEFINE resp		CHAR(6)

LET rm_r19.r19_tot_neto = 0
OPTIONS 
	--INPUT NO WRAP,
	INSERT KEY F30,
	DELETE KEY F31

LET vm_filas_pant  = fgl_scr_size('r_detalle')
WHILE TRUE
	LET i = 1
	LET j = 1
	LET int_flag = 0
	CALL set_count(vm_ind_arr)
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		BEFORE INPUT 
			CALL dialog.keysetlabel('DELETE','')
			CALL dialog.keysetlabel('INSERT','')
		BEFORE ROW
			LET i = arr_curr()   # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()   # POSICION CORRIENTE EN LA PANTALLA

			IF r_detalle[i].r20_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
					RETURNING rm_r10.*
			END IF

		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN 0
			END IF
		AFTER FIELD r20_cant_dev
			IF r_detalle[i].r20_cant_dev IS NOT NULL THEN
				IF r_detalle[i].r20_cant_dev > 
				   r_detalle[i].r20_cant_ven
				   THEN
					CALL fgl_winmessage(vg_producto,'La cantidad devuelta es superior a la vendida. Debe ingresar cantidades iguales o menores a la vendida.','exclamation')
					NEXT FIELD r20_cant_dev
				END IF
				LET k = i - j + 1
				CALL calcula_totales(arr_count(),k)
			END IF
		BEFORE INSERT
			EXIT INPUT
		AFTER INPUT
			IF rm_r19.r19_tot_neto = 0 THEN
				CALL fgl_winmessage(vg_producto,'Digite cantidad a devolver. ','exclamation')
				NEXT FIELD r20_cant_dev
			END IF  
			EXIT WHILE

	END INPUT
	IF int_flag THEN
		EXIT WHILE
		
	END IF

END WHILE

RETURN ind

END FUNCTION



FUNCTION calcula_totales(ind, ind_2)
DEFINE ind,k		SMALLINT
DEFINE ind_2,y	SMALLINT

LET rm_r19.r19_tot_costo     = 0	-- TOTAL COSTO 
LET rm_r19.r19_tot_bruto     = 0	-- TOTAL BRUTO 
LET rm_r19.r19_tot_dscto      = 0	-- TOTAL DEL DESCUENTO
LET rm_r19.r19_tot_neto      = 0 	-- TOTAL NETO
LET vm_impuesto  = 0 	-- TOTAL DEL IMPUESTO

FOR k = 1 TO ind
		
	LET r_detalle_1[k].val_costo = r_detalle[k].r20_cant_dev * 
				       r_detalle_1[k].r20_costo
	LET rm_r19.r19_tot_costo = rm_r19.r19_tot_costo +
				   r_detalle_1[k].val_costo 

	LET r_detalle_1[k].subtotal_item = r_detalle_1[k].r20_precio *  
				         r_detalle[k].r20_cant_dev
	LET rm_r19.r19_tot_bruto = rm_r19.r19_tot_bruto + 
				   r_detalle_1[k].subtotal_item 

	LET r_detalle_1[k].r20_val_descto = r_detalle[k].r20_cant_dev  *
					    r_detalle_1[k].r20_precio    * 
					    r_detalle_1[k].r20_descuento / 100  

	LET rm_r19.r19_tot_dscto = rm_r19.r19_tot_dscto + 
				   r_detalle_1[k].r20_val_descto

	LET r_detalle_1[k].r20_val_impto =
	    (r_detalle_1[k].subtotal_item - r_detalle_1[k].r20_val_descto)
	    * rm_r19.r19_porc_impto     / 100

	LET vm_impuesto = vm_impuesto + r_detalle_1[k].r20_val_impto

END FOR

LET vm_impuesto = fl_retorna_precision_valor(rm_r19.r19_moneda, vm_impuesto)

LET rm_r19.r19_tot_dscto = fl_retorna_precision_valor(rm_r19.r19_moneda, 
						      rm_r19.r19_tot_dscto)

LET y = ind_2
FOR k = 1 TO vm_filas_pant
	IF y = ind THEN
		EXIT FOR
	END IF 
	LET y = y + 1
END FOR

{*
 * El descuento total esta formado por el dscto en cada linea + el dscto
 * en cabecera.
 *}
LET rm_r19.r19_tot_dscto = rm_r19.r19_tot_dscto + 
						   ((rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto) * 
						   rm_r19.r19_descuento / 100)

LET vm_impuesto = (rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto) *
		  rm_r19.r19_porc_impto / 100 	
LET vm_impuesto = fl_retorna_precision_valor(rm_r19.r19_moneda, vm_impuesto)

LET rm_r19.r19_tot_neto = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto +
			  vm_impuesto 
LET rm_r19.r19_flete = 0
IF rm_r19.r19_tot_neto + rm_fact.r19_flete = rm_fact.r19_tot_neto THEN
	LET rm_r19.r19_flete = rm_fact.r19_flete
	LET rm_r19.r19_tot_neto = rm_r19.r19_tot_neto + rm_fact.r19_flete
END IF	

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE r_r19		RECORD LIKE rept019.*

LET vm_flag_mant = 'C'

CLEAR FORM

LET rm_r19.r19_cod_tran = vm_cod_tran_2
LET rm_r19.r19_tipo_dev = vm_cod_tran
DISPLAY BY NAME rm_r19.r19_cod_tran, rm_r19.r19_tipo_dev

CALL control_display_botones()

IF num_args() = 4 THEN
	LET INT_FLAG = 0
	CONSTRUCT BY NAME expr_sql 
		  ON r19_cod_tran,   r19_num_tran,   r19_num_dev,  r19_moneda,
		     r19_bodega_ori, r19_codcli,   r19_nomcli,   
		     r19_vendedor, 
		     r19_porc_impto, r19_cont_cred  
	BEFORE CONSTRUCT
		DISPLAY vm_cod_dev TO r19_cod_tran
	ON KEY(F2)
		IF INFIELD(r19_num_dev) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      vm_cod_tran)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli 

		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				LET rm_r19.r19_num_dev = rm_r19.r19_num_tran
				DISPLAY BY NAME rm_r19.r19_num_dev
		      	END IF
		END IF
		IF INFIELD(r19_num_tran) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      vm_cod_tran_2)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli 
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							    vg_codloc,
							    vm_cod_tran_2,
							    r_r19.r19_num_tran)
					RETURNING rm_r19.*
				DISPLAY BY NAME rm_r19.r19_num_tran
				CALL control_display_cabecera()
			END IF
		END IF
		IF INFIELD(r19_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_r19.r19_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_r19.r19_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
		      	END IF
		END IF
		IF INFIELD(r19_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
				LET rm_r19.r19_vendedor = rm_r01.r01_codigo	
				DISPLAY BY NAME rm_r19.r19_vendedor
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r19_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r19.r19_codcli = rm_c02.z02_codcli
				LET rm_r19.r19_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r19.r19_codcli,
						rm_r19.r19_nomcli
			END IF 
		END IF
		IF INFIELD(r19_bodega) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T')
		     RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     IF rm_r02.r02_codigo IS NOT NULL THEN
			    LET rm_r19.r19_bodega_ori = rm_r02.r02_codigo
			    DISPLAY BY NAME rm_r19.r19_bodega_ori
			    DISPLAY rm_r02.r02_nombre TO r02_nombre
		     END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r19_cod_tran
		LET rm_r19.r19_cod_tran = get_fldbuf(r19_cod_tran)
		IF rm_r19.r19_cod_tran <> vm_cod_dev THEN 
			CALL fgl_winmessage(vg_producto, 'Solo puede poner ' ||
					'tipo: ' || vm_cod_dev, 'exclamation')
			DISPLAY vm_cod_dev TO r19_cod_tran
			NEXT FIELD r19_cod_tran
		END IF
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
	LET expr_sql = ' r19_cod_tran = "', vg_cod_tran, '" AND ',
		       ' r19_num_tran = ',vg_num_tran
END IF

LET query = 'SELECT *, ROWID FROM rept019 
		WHERE r19_compania  = ', vg_codcia,
		' AND r19_localidad = ', vg_codloc,
		' AND ', expr_sql CLIPPED,
		' ORDER BY 3, 4' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r19.*, vm_rows[vm_num_rows]
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
SELECT * INTO rm_r19.* FROM rept019 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET vm_impuesto = rm_r19.r19_tot_neto - rm_r19.r19_flete -  
		  (rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto)

	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r19.r19_cod_tran,   rm_r19.r19_num_tran, rm_r19.r19_usuario,
		rm_r19.r19_vendedor,   rm_r19.r19_bodega_ori, 
--		rm_r19.r19_moneda, 
		rm_r19.r19_porc_impto, rm_r19.r19_cont_cred, rm_r19.r19_codcli,
		rm_r19.r19_nomcli,     
		rm_r19.r19_tipo_dev,   rm_r19.r19_num_dev, rm_r19.r19_fecing ,
		rm_r19.r19_referencia

CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(400)

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET query = 'SELECT r20_cant_ent, r20_cant_dev, r20_item, r10_nombre ',
		    '  FROM rept020, rept010 ',
            	'WHERE r20_compania  =  ', vg_codcia, 
	    	'  AND r20_localidad =  ', vg_codloc,
            	'  AND r20_cod_tran  = "', rm_r19.r19_cod_tran,'"',
            	'  AND r20_num_tran  = ', rm_r19.r19_num_tran,
				'  AND r10_compania  = r20_compania ',
				'  AND r10_codigo    = r20_item '
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO r_detalle[i].*
	INITIALIZE r_detalle[i].r20_cant_dev TO NULL  -- PARA NO MOSTRAR NADA
						      -- EN LA EN EL DETALLE
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
LET vm_ind_arr = i

IF vm_ind_arr <= vm_filas_pant THEN 
	LET vm_filas_pant = vm_ind_arr
END IF 

FOR i = 1 TO vm_filas_pant 
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR 

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF

IF vm_flag_mant <> 'C' THEN
	LET vm_flag_mant = 'C'
	CALL control_display_botones()
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

IF vm_flag_mant <> 'C' THEN
	LET vm_flag_mant = 'C'
	CALL control_display_botones()
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()

CALL fl_lee_moneda(rm_r19.r19_moneda)
	RETURNING rm_g13.*
	DISPLAY rm_g13.g13_nombre TO nom_moneda
CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
	RETURNING rm_r02.*
	DISPLAY rm_r02.r02_nombre TO nom_bodega
CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
	RETURNING rm_r01.*
	DISPLAY rm_r01.r01_nombres TO nom_vendedor

END FUNCTION



FUNCTION imprimir()

DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp401 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran,
	rm_r19.r19_num_tran
	
RUN comando	

END FUNCTION



FUNCTION verifica_saldo_fact_devuelta()
DEFINE r_r25		RECORD LIKE rept025.*
DEFINE saldo_fact	DECIMAL(14,2)

SELECT * INTO r_r25.* FROM rept025
	WHERE r25_compania  = rm_fact.r19_compania  AND 
	      r25_localidad = rm_fact.r19_localidad AND 
	      r25_cod_tran  = rm_fact.r19_cod_tran  AND 
	      r25_num_tran  = rm_fact.r19_num_tran
IF status = NOTFOUND THEN
	LET r_r25.r25_valor_ant  = 0
	LET r_r25.r25_valor_cred = 0
END IF
SELECT SUM(z20_saldo_cap) INTO saldo_fact FROM cxct020
	WHERE z20_compania  = rm_fact.r19_compania  AND 
	      z20_localidad = rm_fact.r19_localidad AND 
	      z20_cod_tran  = rm_fact.r19_cod_tran  AND 
	      z20_num_tran  = rm_fact.r19_num_tran  AND 
	      z20_codcli    = rm_fact.r19_codcli
IF saldo_fact IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Factura crédito no existe en  ' || 
					 'módulo de Cobranzas. Devolución ' ||
					 'no se ejecutó', 'stop')
	ROLLBACK WORK
	EXIT PROGRAM
END IF	
IF r_r25.r25_valor_cred = saldo_fact THEN
	RETURN 1
END IF
RETURN 0

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

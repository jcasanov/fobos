{*
 * Titulo           : repp220.4gl - Mantenimiento de Proforma
 * Elaboracion      : 25-jul-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp220 base modulo compania localidad
 *
 * XXX En el programa se esta usando vm_ind_arr y vm_num_detalles con el
 *     mismo proposito, y peor aun a veces se graba en uno y a veces en otro
 *     al ser las dos variables globales esto esta causando confusion.
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE

-- ESTAS VARIABLES SON PARA CONTROLAR EL TIPO DE INVENTARIO
DEFINE rm_tipinv	RECORD 	
	-- codigo y factor para stock
	sto_codigo		LIKE rept114.r114_codigo,
	sto_factor		LIKE rept114.r114_factor,
	sto_flag_ident	LIKE rept114.r114_flag_ident,
	-- codigo y factor para importacion
	imp_codigo		LIKE rept114.r114_codigo,
	imp_factor		LIKE rept114.r114_factor,
	imp_flag_ident	LIKE rept114.r114_flag_ident
END RECORD

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r00		 	RECORD LIKE rept000.*	-- CONFIGURACION DE LA
							-- COMPAÑIA DE RPTO.
DEFINE rm_r01		 	RECORD LIKE rept001.*	-- VENDEDOR
DEFINE rm_r02		 	RECORD LIKE rept002.*	-- BODEGA
DEFINE rm_r03		 	RECORD LIKE rept003.*	-- LINEA VTA.
DEFINE rm_r10		 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r21			RECORD LIKE rept021.*	-- CABECERA PROFORMA
DEFINE rm_r22		 	RECORD LIKE rept022.*	-- DETALLE PROFORMA
DEFINE rm_r23		 	RECORD LIKE rept023.*	-- CABECERA PREVENTA
DEFINE rm_r24		 	RECORD LIKE rept024.*	-- DETALLE PREVENTA
DEFINE rm_g13		 	RECORD LIKE gent013.*	-- MONEDAS.
DEFINE rm_g20		 	RECORD LIKE gent020.*	-- GRUPO DE LINEAS VTA.
DEFINE rm_g14		 	RECORD LIKE gent014.*	-- CONV. ENTRE MONEDAS.
DEFINE rm_c01		 	RECORD LIKE cxct001.*	-- CLIENTES GENERALES.
DEFINE rm_c02		 	RECORD LIKE cxct002.*	-- CLIENTES CIA. LOCAL.
DEFINE rm_r16			RECORD LIKE rept016.*	-- PEDIDO

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[500] OF RECORD
	r22_cantidad		LIKE rept022.r22_cantidad,
	r22_item			LIKE rept022.r22_item,
	r10_nombre			LIKE rept010.r10_nombre,
	r22_dias_ent		LIKE rept022.r22_dias_ent,
	r22_precio			LIKE rept022.r22_precio,
	subtotal_item		LIKE rept021.r21_tot_neto
END RECORD
	----------------------------------------------------------
	---- ARREGLO PARA LOS CAMPOS FUERA DE MI SCREEN RECORD ----
DEFINE r_detalle_1 ARRAY[500] OF RECORD
	r22_item_ant		LIKE rept022.r22_item_ant,
	r22_descripcion		LIKE rept022.r22_descripcion,
	r22_linea			LIKE rept022.r22_linea,
	r22_rotacion		LIKE rept022.r22_rotacion,
	r22_costo			LIKE rept022.r22_costo,  -- COSTO ITEM
	r22_porc_descto		LIKE rept022.r22_porc_descto,
	r22_val_descto		LIKE rept022.r22_val_descto,
	r22_val_impto		LIKE rept022.r22_val_impto,
	val_costo			LIKE rept021.r21_tot_costo,    -- COSTO DE ITEMS
	peso				LIKE rept010.r10_peso
END RECORD
	------------------------------------------------------------
	----- ESTE ARREGLO ADICIONAL LO AGREGO PARA DETERMINAR -----
	----- LOS VALORES DE LISTA ORIGINALES Y LOS DESCTOS Y  -----
	----- Y RECARGOS QUE AFECTARON  					   -----
DEFINE r_detalle_2 ARRAY[500] OF RECORD
    r113_precio_lista 	LIKE rept113.r113_precio_lista,
    r113_dscto_clte 	LIKE rept113.r113_dscto_clte,
    r113_recargo_clte 	LIKE rept113.r113_recargo_clte,
    r113_dscto_item 	LIKE rept113.r113_dscto_item,
    r113_recargo_item 	LIKE rept113.r113_recargo_item
END RECORD
	----------------------------------------------------------

DEFINE vm_fecha			DATE			-- FECHA DE INGRESO
DEFINE vm_flag_mant		CHAR(1)	   -- FLAG DE MANTENIMIENTO
					   -- 'I' --> INGRESO		
					   -- 'M' --> MODIFICACION		
					   -- 'C' --> CONSULTA		
DEFINE vm_ind_arr		SMALLINT   -- INDICE DE MI ARREGLO (INPUT ARRAY)
DEFINE vm_filas_pant	SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_costo   	 	DECIMAL(12,2)	-- TOTAL COSTO 
DEFINE vm_subtotal    	DECIMAL(12,2)	-- TOTAL BRUTO 
DEFINE vm_descuento   	DECIMAL(12,2)	-- TOTAL DEL DESCUENTO
DEFINE vm_val_dscto2	LIKE rept021.r21_tot_dscto
DEFINE vm_impuesto    	DECIMAL(12,2)	-- TOTAL DEL IMPUESTO
DEFINE vm_total    		DECIMAL(12,2)	-- TOTAL NETO
DEFINE vg_numprev		LIKE rept021.r21_numprof

DEFINE vm_tot_peso		DECIMAL(11,3)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp220.error')
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
IF num_args() THEN
	LET vg_numprev  = arg_val(5)
END IF	
LET vg_proceso = 'repp220'
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

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW w_220 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_220 FROM '../forms/repf220_1'
DISPLAY FORM f_220
CALL control_display_botones()

-- PARA OBTENER LA CONFIGURACION DEL AREA DE REPUESTOS
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*

LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_max_rows     = 1000
LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r21.* TO NULL
INITIALIZE rm_r22.* TO NULL
CALL muestra_contadores()

CALL inicializar_factores_importacion_stock()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Copiar'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Hacer Preventa'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Hacer Pedido'
		IF num_args() = 5 THEN
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Copiar'
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Imprimir'
			CALL control_consulta()
		END IF 
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
        CALL control_ingreso()
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Copiar'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Hacer Pedido'
			SHOW OPTION 'Imprimir'
		END IF
                IF vm_row_current > 1 THEN
                        SHOW OPTION 'Retroceder'
                END IF
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                END IF
	COMMAND KEY('M') 'Modificar' 'Modificar un registro.'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('O') 'Copiar' 'Genera una proforma en base a una ya existente.'
		IF vm_num_rows > 0 THEN
			CALL control_copiar()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Copiar'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Hacer Pedido'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_row_current > 1 THEN
        	SHOW OPTION 'Retroceder'
        END IF
        IF vm_row_current = vm_num_rows THEN
        	HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('H') 'Hacer Preventa'   'Convertir la proforma en preventa.'
		IF vm_num_rows > 0 THEN
			CALL control_hacer_preventa()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('P') 'Hacer Pedido'      'Convertir la Proforma en Pedido.'
		IF vm_num_rows > 0 THEN
			CALL control_hacer_pedido()
			IF NOT int_flag THEN
				CALL control_grabar_proforma_pedido()
			END IF
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Copiar'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Hacer Pedido'
			SHOW OPTION 'Imprimir'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
				IF vm_num_rows = 0 THEN
					HIDE OPTION 'Imprimir'
					HIDE OPTION 'Modificar'
					HIDE OPTION 'Copiar'
					HIDE OPTION 'Ver Detalle'
					HIDE OPTION 'Hacer Preventa'
					HIDE OPTION 'Hacer Pedido'
                        END IF
                ELSE
					SHOW OPTION 'Modificar'
					SHOW OPTION 'Copiar'	
					SHOW OPTION 'Hacer Pedido'
					SHOW OPTION 'Imprimir'
					SHOW OPTION 'Hacer Preventa'
					SHOW OPTION 'Ver Detalle'
					SHOW OPTION 'Avanzar'
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF

	COMMAND KEY('I') 'Imprimir'
		IF rm_r21.r21_numprof IS NOT NULL THEN
			CALL control_imprimir_proforma()
		END IF
      COMMAND KEY('V') 'Ver Detalle'   'Muestra anteriores detalles.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Copiar'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Copiar'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Copiar'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Copiar'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_copiar()
DEFINE numprof_orig 	LIKE rept021.r21_numprof
DEFINE done		SMALLINT
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE stock			LIKE rept022.r22_cantidad

LET numprof_orig = rm_r21.r21_numprof

CALL control_display_botones()

LET vm_flag_mant = 'I'

IF rm_r00.r00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,'No existe configuración para la Compañía en el área de Repuestos. ','exclamation')
	RETURN
END IF
IF rm_r00.r00_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,'La Compañía está con status BLOQUEADO en el área de Repuestos. ','exclamation')
	RETURN
END IF

-- INITIAL VALUES FOR rm_r21 FIELDS
LET vm_fecha              = DATE(CURRENT)
LET rm_r21.r21_usuario    = vg_usuario
LET rm_r21.r21_compania   = vg_codcia
LET rm_r21.r21_localidad  = vg_codloc
LET rm_r21.r21_factor_fob = 1

INITIALIZE rm_r21.r21_numprof TO NULL
DISPLAY BY NAME vm_val_dscto2

CALL fl_lee_bodega_rep(vg_codcia, rm_r21.r21_bodega) -- PARA OBTENER EL NOMBRE
	RETURNING rm_r02.*			     -- DE LA BODEGA
	DISPLAY rm_r02.r02_nombre TO nom_bodega

CALL fl_lee_moneda(rg_gen.g00_moneda_base) 	     -- PARA OBTENER EL NOMBRE 
	RETURNING rm_g13.*		   	     -- DE LA MONEDA BASE

DISPLAY BY NAME vm_fecha, rm_r21.r21_moneda, rm_r21.r21_porc_impto, 
				rm_r21.r21_dias_prof, rm_r21.r21_usuario, rm_r21.r21_numprof
DISPLAY rm_g13.g13_nombre TO nom_moneda

CALL lee_datos()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

CALL recalcular()

LET vm_flag_mant = 'M'
LET vm_num_detalles = ingresa_detalles() 
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET vm_flag_mant = 'I'
CALL ingresa_descuento2()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

	-- ACTUALIZO LOS VALORES DEFAULTS QUE INGRESE AL INICIO DE LEE DATOS --
LET rm_r21.r21_fecing = CURRENT
LET rm_r21.r21_tot_neto = vm_total
BEGIN WORK

	LET done = control_cabecera()
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso de la cabecera de la preventa no se realizará el proceso.','exclamation')
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
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso del detalle de la preventa no se realizará el proceso.','exclamation')
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
CALL muestra_contadores()
--CALL lee_muestra_registro(vm_rows[vm_row_current])

CALL control_imprimir_proforma()

CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_imprimir_proforma()
DEFINE command_run 	VARCHAR(100)

	LET command_run = 'fglrun repp419 ',vg_base, ' ', vg_modulo, ' ', 
										vg_codcia, ' ', vg_codloc, ' ',
										rm_r21.r21_numprof
	RUN command_run

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'Cant' 		TO tit_col1
DISPLAY 'Item' 		TO tit_col2
DISPLAY 'Descripcion'	TO tit_col4
DISPLAY 'Ent'		TO tit_col3
DISPLAY 'Precio Unit.'	TO tit_col5
DISPLAY 'Subtotal'	TO tit_col6

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE  i,j 	SMALLINT
DEFINE r_r10	RECORD LIKE rept010.*

CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.*
	BEFORE DISPLAY
    	CALL dialog.keysetlabel('ACCEPT', '')
	BEFORE ROW
		LET i = arr_curr()	
		LET j = scr_line()	

		CALL fl_lee_item(vg_codcia,r_detalle[i].r22_item) RETURNING r_r10.*
		DISPLAY r_r10.r10_nombre TO r_detalle[j].r10_nombre
        AFTER DISPLAY
			CONTINUE DISPLAY
        ON KEY(INTERRUPT)
			EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_hacer_preventa()
DEFINE i,j,done 	SMALLINT
DEFINE resp 		CHAR(6)
DEFINE preventas 	INTEGER 
DEFINE r_r24		RECORD LIKE rept024.*
DEFINE salir		SMALLINT
DEFINE query		VARCHAR(500)
DEFINE expr_costo	VARCHAR(100)
DEFINE cupo_credito     LIKE cxct020.z20_saldo_cap   -- C. CREDITO FORMA
DEFINE saldo_credito    LIKE cxct020.z20_saldo_cap   -- Saldo.CRED FORM

DEFINE stock		LIKE rept011.r11_stock_act
DEFINE mensaje		VARCHAR(500)
DEFINE command_line	VARCHAR(100)

DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r102		RECORD LIKE rept102.*
DEFINE r_z02			RECORD LIKE cxct002.*
DEFINE r_z30			RECORD LIKE cxct030.*
DEFINE r_g20			RECORD LIKE gent020.*


DEFINE orden		SMALLINT
DEFINE r_detprev	RECORD
	item			LIKE rept022.r22_item,
	precio			LIKE rept022.r22_precio,
	descto			LIKE rept022.r22_porc_descto,
	linea			LIKE rept010.r10_linea,
	cantidad		LIKE rept022.r22_cantidad
END RECORD

IF fl_proforma_facturada(vg_codcia, vg_codloc, rm_r21.r21_numprof) THEN
	CALL fgl_winmessage(vg_producto, 'No se puede modificar proforma porque ya se han generado facturas.', 'exclamation')
	RETURN
END IF

IF proforma_expiro() THEN
	CALL fgl_winmessage(vg_producto,'La proforma ya expiró.','exclamation')
	RETURN
END IF

IF fl_proforma_aprobada(vg_codcia, vg_codloc, rm_r21.r21_numprof) THEN
	CALL fgl_winquestion(vg_producto,
						'¿Desea reemplazar las preventas generadas ' ||
						'anteriormente para esta proforma?', 'No', 'Yes|No', 
						'question', 1)
				RETURNING resp
	IF resp = 'No' THEN
		RETURN
	END IF
END IF

-- Empieza el proceso
BEGIN WORK

	{*
	 * Elimina las preventas existentes para esta proforma, asi como sus 
	 * registros de caja... damn it, esto deberia ser un trigger
	 *} 
	DECLARE q_r102 CURSOR FOR
		SELECT rept102.* FROM rept102, rept023
		 WHERE r102_compania  = vg_codcia
		   AND r102_localidad = vg_codloc
		   AND r102_numprof   = rm_r21.r21_numprof
		   AND r23_compania   = r102_compania
		   AND r23_localidad  = r102_localidad
		   AND r23_numprev    = r102_numprev
		   AND r23_estado     = 'P'

	FOREACH q_r102 INTO r_r102.*
		DELETE FROM cajt010  
		 WHERE j10_compania    = r_r102.r102_compania
		   AND j10_localidad   = r_r102.r102_localidad
		   AND j10_tipo_fuente = 'PR'
		   AND j10_num_fuente  = r_r102.r102_numprev 
		   AND j10_estado      = 'A'

		UPDATE rept023 SET r23_estado = 'N'
		 WHERE r23_compania  = r_r102.r102_compania
		   AND r23_localidad = r_r102.r102_localidad
		   AND r23_numprev   = r_r102.r102_numprev
		   AND r23_estado    = 'P'
	END FOREACH

INITIALIZE rm_r23.* TO NULL

LET rm_r23.r23_compania    = vg_codcia                                 
LET rm_r23.r23_localidad   = vg_codloc                                 
LET rm_r23.r23_estado      = 'P' 
LET rm_r23.r23_cont_cred   = 'C' 
LET rm_r23.r23_grupo_linea = rm_r21.r21_grupo_linea                       
LET rm_r23.r23_codcli      = rm_r21.r21_codcli                                 
LET rm_r23.r23_nomcli      = rm_r21.r21_nomcli                                 
LET rm_r23.r23_dircli      = rm_r21.r21_dircli                                 
LET rm_r23.r23_telcli      = rm_r21.r21_telcli                                 
LET rm_r23.r23_cedruc      = rm_r21.r21_cedruc                                 
LET rm_r23.r23_vendedor    = rm_r21.r21_vendedor                           
LET rm_r23.r23_descuento   = rm_r21.r21_descuento                               
LET rm_r23.r23_bodega      = rm_r21.r21_bodega                         
LET rm_r23.r23_porc_impto  = rm_r21.r21_porc_impto                         
LET rm_r23.r23_moneda      = rm_r21.r21_moneda                         
LET rm_r23.r23_tot_costo   = 0 -- rm_r21.r21_tot_costo                   
LET rm_r23.r23_tot_bruto   = 0 -- rm_r21.r21_tot_bruto                   
LET rm_r23.r23_tot_dscto   = 0 -- rm_r21.r21_tot_dscto                   
LET rm_r23.r23_tot_neto    = 0 -- rm_r21.r21_tot_neto 
LET rm_r23.r23_flete  	   = 0
LET rm_r23.r23_usuario     = vg_usuario    
LET rm_r23.r23_fecing      = CURRENT    
LET rm_r23.r23_referencia  = rm_r21.r21_modelo   

CALL fl_lee_moneda(rm_r23.r23_moneda) RETURNING rm_g13.*	   	 
LET rm_r23.r23_precision = rm_g13.g13_decimales

IF rm_r23.r23_moneda = rg_gen.g00_moneda_base THEN
	LET rm_r23.r23_paridad = 1
ELSE
	CALL fl_lee_factor_moneda(rg_gen.g00_moneda_alt, rg_gen.g00_moneda_base)
		RETURNING rm_g14.*
	LET rm_r23.r23_paridad =  rm_g14.g14_tasa
END IF

CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r21.r21_codcli)
	RETURNING r_z02.*
CALL fl_lee_grupo_linea(vg_codcia, rm_r21.r21_grupo_linea) RETURNING r_g20.*
CALL fl_lee_resumen_saldo_cliente(vg_codcia, vg_codloc, r_g20.g20_areaneg,
								  rm_r21.r21_codcli, rm_r21.r21_moneda)
	RETURNING r_z30.* 

LET cupo_credito = r_z02.z02_cupocred_mb
LET saldo_credito = cupo_credito 
IF r_z30.z30_compania IS NOT NULL THEN
	LET saldo_credito = cupo_credito - (r_z30.z30_saldo_venc + r_z30.z30_saldo_xvenc)
END IF
IF saldo_credito < 0 THEN
	LET saldo_credito = 0
END IF

OPEN WINDOW w_220_4 AT 11,17 WITH 12 ROWS, 72 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, 
		  MESSAGE LINE LAST - 2) 
OPEN FORM f_220_4 FROM '../forms/repf220_4'
DISPLAY FORM f_220_4

DISPLAY BY NAME saldo_credito, cupo_credito
CALL control_otros_datos_preventa()

IF rm_r23.r23_cont_cred = 'C' THEN
	IF r_z30.z30_saldo_venc > 0 THEN
		CALL fgl_winmessage(vg_producto, 'El cliente tiene un saldo vencido de ' || r_z30.z30_saldo_venc || ' no se puede facturar al contado.', 'info')
		CLOSE WINDOW w_220_4
		RETURN
	END IF 
END IF

-- Para hacer el numero de preventas segun el numero de lineas 
-- soportadas por la factura

LET preventas = 1
IF rm_r00.r00_numlin_fact <> 9999 THEN
	LET preventas = vm_ind_arr / rm_r00.r00_numlin_fact 
	IF vm_ind_arr MOD rm_r00.r00_numlin_fact > 0 THEN
		LET preventas = preventas + 1 	---NUMERO DE PREVENTAS A GENERAR
	END IF
END IF

-- Saca los items que se van a grabar en el detalle de la(s) preventa(s)
DECLARE q_prof CURSOR FOR
	SELECT MIN(r22_orden), r22_item, r22_precio, r22_porc_descto, 
               r10_linea, SUM(r22_cantidad) 
		FROM rept022, rept010
		WHERE r22_compania  = vg_codcia
		  AND r22_localidad = vg_codloc
		  AND r22_numprof   = rm_r21.r21_numprof
		  AND r10_compania  = r22_compania
		  AND r10_codigo    = r22_item
		GROUP BY r22_item, r22_precio, r22_porc_descto, r10_linea
		ORDER BY 1          

INITIALIZE r_detprev.* TO NULL
LET salir = 0
OPEN  q_prof 
FETCH q_prof INTO orden, r_detprev.*
IF STATUS = NOTFOUND THEN
	LET salir = 1
END IF

FOR i = 1 TO preventas 

	IF salir THEN
		EXIT FOR
	END IF

	SELECT MAX(r23_numprev) + 1 INTO rm_r23.r23_numprev
       		FROM  rept023
        	WHERE r23_compania  = vg_codcia
        	AND   r23_localidad = vg_codloc
                                                                                
	IF rm_r23.r23_numprev IS NULL THEN
       	 	LET rm_r23.r23_numprev = 1
	END IF

	INSERT INTO rept023 VALUES (rm_r23.*)


	{*
	 * Crea la relacion entre preventa y proforma
	 *}
	INSERT INTO rept102 VALUES (vg_codcia, vg_codloc, rm_r21.r21_numprof,
								rm_r23.r23_numprev, rm_r23.r23_usuario, 
								rm_r23.r23_fecing)

	LET j = 1
	WHILE NOT salir
	
		IF j > rm_r00.r00_numlin_fact THEN
			EXIT WHILE	
		END IF 
	
		INITIALIZE r_r24.* TO NULL
		SELECT * INTO r_r24.* FROM rept024 
			WHERE r24_compania  = vg_codcia
			  AND r24_localidad = vg_codloc
			  AND r24_numprev   = rm_r23.r23_numprev
		  	  AND r24_item      = r_detprev.item
								
		IF STATUS <> NOTFOUND THEN
			IF r_detprev.precio <> r_r24.r24_precio THEN
				CALL fgl_winmessage(vg_producto,
					'El item ' || r_detprev.item CLIPPED || 
					' se ha digitado dos ' ||
					'veces en la proforma, con '||
					'precios diferentes. Se detendrá ' ||
					'la generación de la preventa.',
					'stop')
				ROLLBACK WORK
				RETURN
			END IF
			IF r_detprev.descto <> r_r24.r24_descuento THEN
				CALL fgl_winmessage(vg_producto,
					'El item ' || r_detprev.item CLIPPED || 
					' se ha digitado dos ' ||
					'veces en la proforma, con '||
					'descuentos diferentes. Se detendrá ' ||
					'la generación de la preventa.',
					'stop')
				ROLLBACK WORK
				RETURN
			END IF
		END IF

		INITIALIZE rm_r24.* TO NULL
		LET rm_r24.r24_compania     = vg_codcia        
		LET rm_r24.r24_localidad    = vg_codloc    
        LET rm_r24.r24_numprev      = rm_r23.r23_numprev             
        LET rm_r24.r24_proformado   = 'S'
	    LET rm_r24.r24_cant_ped     = r_detprev.cantidad
   		LET rm_r24.r24_cant_ven     = rm_r24.r24_cant_ped
        LET rm_r24.r24_item         = r_detprev.item
        LET rm_r24.r24_descuento    = r_detprev.descto
        LET rm_r24.r24_precio       = r_detprev.precio
       	LET rm_r24.r24_orden        = j
        LET rm_r24.r24_linea        = r_detprev.linea

		CALL fl_lee_stock_disponible_rep(vg_codcia, vg_codloc, 
										 r_detprev.item, 'R') 
			RETURNING stock 
		IF stock < rm_r24.r24_cant_ped THEN
--			LET rm_r24.r24_cant_ven = stock
			LET mensaje = 'El Item ', rm_r24.r24_item CLIPPED, '  ',
				r_r10.r10_nombre CLIPPED, '  ', '  tiene en stock disponible ',
				stock, '  y la cantidad pedida es ',
				rm_r24.r24_cant_ped, '. ', 'Modifique la proforma y vuelva a ',
				'generar la preventa.' 
			CALL fgl_winmessage(vg_producto, mensaje,'exclamation') 
--			ROLLBACK WORK
--			RETURN 
		END IF 
	
        LET rm_r24.r24_val_descto   = 
	        	(r_detprev.cantidad * r_detprev.precio) * 
	        	(r_detprev.descto / 100)
        LET rm_r24.r24_val_impto    = 
			((r_detprev.cantidad * r_detprev.precio) - 
	        rm_r24.r24_val_descto) * 
			(rm_r23.r23_porc_impto / 100)
		LET rm_r24.r24_val_impto = fl_retorna_precision_valor(
					rm_r23.r23_moneda, rm_r24.r24_val_impto)
			
		INSERT INTO rept024 VALUES(rm_r24.*)

       	LET j = j + 1			
		INITIALIZE r_detprev.* TO NULL
		FETCH q_prof INTO orden, r_detprev.*
		IF STATUS = NOTFOUND THEN
			LET salir = 1
		END IF
	END WHILE

	IF rm_r23.r23_moneda = rg_gen.g00_moneda_base THEN
		LET expr_costo = ' SUM(r24_cant_ven * r10_costo_mb) ' 
	ELSE   
		IF rm_r23.r23_moneda = rg_gen.g00_moneda_alt THEN
			LET expr_costo = ' SUM(r24_cant_ven * r10_costo_ma) ' 
		ELSE
			CALL fgl_winmessage(vg_producto,
				'La preventa debe hacerse en la ' ||
				'moneda base o en la moneda alterna del ' ||
				'sistema.',
				'stop')
			ROLLBACK WORK
			CLOSE WINDOW w_220_4
			RETURN 
		END IF 
	END IF
			
	LET query = 'SELECT SUM(r24_cant_ven * r24_precio), ' ||
		              ' SUM((r24_descuento / 100) * ' ||
						'	(r24_cant_ven * r24_precio)), ' ||
					  ' SUM(r24_val_impto), ' ||
			  expr_costo CLIPPED ||
		    '	FROM rept024, rept010 ' ||
		    '	WHERE r24_compania  = ' || vg_codcia ||
		        ' AND r24_localidad = ' || vg_codloc ||
		        ' AND r24_numprev   = ' || rm_r23.r23_numprev ||
		        ' AND r10_compania  = r24_compania ' ||
		        ' AND r10_codigo    = r24_item '

	PREPARE stmnt1 FROM query
	EXECUTE stmnt1 INTO vm_subtotal, vm_descuento, vm_impuesto, vm_costo

	LET vm_subtotal = fl_retorna_precision_valor(rm_r23.r23_moneda,
					              vm_subtotal)	
	LET vm_descuento = fl_retorna_precision_valor(rm_r23.r23_moneda,
					              vm_descuento)	
	LET vm_impuesto  = fl_retorna_precision_valor(rm_r23.r23_moneda,
					              vm_impuesto)	
	LET rm_r23.r23_tot_costo = vm_costo
	LET rm_r23.r23_tot_bruto = vm_subtotal
	LET rm_r23.r23_tot_dscto = vm_descuento
	LET rm_r23.r23_tot_dscto = rm_r23.r23_tot_dscto +
		   ((rm_r23.r23_tot_bruto - vm_descuento) * rm_r23.r23_descuento / 100) 
	LET rm_r23.r23_tot_dscto  = fl_retorna_precision_valor(rm_r23.r23_moneda,
					              rm_r23.r23_tot_dscto)	
	-- Para sacar el impuesto del total bruto
	LET vm_impuesto = (vm_subtotal - rm_r23.r23_tot_dscto) * rm_r23.r23_porc_impto / 100
	LET rm_r23.r23_tot_neto = vm_subtotal - rm_r23.r23_tot_dscto + vm_impuesto
	LET rm_r23.r23_tot_neto = fl_retorna_precision_valor(rm_r23.r23_moneda,
					              rm_r23.r23_tot_neto)	

	UPDATE rept023 SET r23_tot_costo = rm_r23.r23_tot_costo,
					   r23_tot_bruto = rm_r23.r23_tot_bruto,
					   r23_tot_dscto = rm_r23.r23_tot_dscto,
					   r23_tot_neto  = rm_r23.r23_tot_neto
	 WHERE r23_compania  = vg_codcia
	   AND r23_localidad = vg_codloc
	   AND r23_numprev   = rm_r23.r23_numprev 

	CALL control_actualizacion_caja() RETURNING done
	IF done = 0 THEN
		CALL fgl_winmessage(vg_producto,
			'No se pudo grabar en la cajt010. No se realizará proceso.',
			'exclamation')
		ROLLBACK WORK
		CLOSE WINDOW w_220_4
		RETURN
	END IF

END FOR

COMMIT WORK

CALL fgl_winmessage(vg_producto,
	'Se genero ' || preventas || ' preventas '||
	' y la última preventa se genero con el número  ' || 
	rm_r23.r23_numprev||'.',
	'info')

IF rm_r23.r23_cont_cred = 'R' AND saldo_credito > rm_r21.r21_tot_neto THEN
	IF r_z30.z30_saldo_venc > 0 THEN
		CALL fgl_winmessage(vg_producto, 'El cliente tiene un saldo vencido de ' || r_z30.z30_saldo_venc || ' y necesitara autorizacion de Cobranzas.', 'info')
	ELSE
		LET command_line = 'fglrun repp231 ' || vg_base || ' '
				            || vg_modulo || ' ' || vg_codcia
			    	        || ' ' || vg_codloc || ' ' ||
			    	        rm_r21.r21_numprof
		RUN command_line
	END IF
END IF

CLOSE WINDOW w_220_4

END FUNCTION




FUNCTION control_otros_datos_preventa()
DEFINE tipo_pago		LIKE rept023.r23_cont_cred
DEFINE ped_cliente		LIKE rept023.r23_ped_cliente
DEFINE telcli			LIKE rept023.r23_telcli
DEFINE ord_compra 		LIKE rept023.r23_ord_compra
DEFINE referencia		LIKE rept023.r23_referencia

LET tipo_pago   = rm_r23.r23_cont_cred
LET ped_cliente = rm_r23.r23_ped_cliente
LET telcli	    = rm_r23.r23_telcli
LET ord_compra 	= rm_r23.r23_ord_compra
LET referencia	= rm_r23.r23_referencia

INPUT BY NAME rm_r23.r23_cont_cred,
			  rm_r23.r23_ped_cliente, rm_r23.r23_telcli,
	          rm_r23.r23_ord_compra,  rm_r23.r23_referencia, rm_r23.r23_paridad,
	          rm_r23.r23_usuario
	      WITHOUT DEFAULTS
	AFTER FIELD r23_cont_cred
		IF rm_r23.r23_codcli IS NULL THEN
			IF rm_r23.r23_cont_cred = 'R' THEN
				CALL fgl_winmessage(vg_producto, 'No se puede vender a credito en proformas sin codigo de cliente.', 'exclamation')
				LET rm_r23.r23_cont_cred = 'C'
				DISPLAY BY NAME rm_r23.r23_cont_cred
				NEXT FIELD r23_cont_cred
			END IF
		END IF
END INPUT
IF int_flag THEN
	LET rm_r23.r23_cont_cred 	= tipo_pago
	LET rm_r23.r23_ped_cliente 	= ped_cliente
	LET rm_r23.r23_telcli		= telcli
	LET rm_r23.r23_ord_compra 	= ord_compra
	LET rm_r23.r23_referencia	= referencia
	LET int_flag = 0
END IF

IF rm_r23.r23_ord_compra IS NOT NULL AND rm_r23.r23_cont_cred = 'C' THEN
	CALL fgl_winmessage(vg_producto,
		'Para pagar con orden de compra la pre-venta debe ser a credito.',
		'info')
	LET rm_r23.r23_cont_cred = 'R' 
END IF

RETURN	

END FUNCTION





FUNCTION control_hacer_pedido()
DEFINE r_r16		RECORD LIKE  rept016.*
DEFINE r_r17		RECORD LIKE  rept017.*
DEFINE r_r03		RECORD LIKE  rept003.*
DEFINE r_p01		RECORD LIKE  cxpt001.*
DEFINE r_p02		RECORD LIKE  cxpt002.*
DEFINE r_b10		RECORD LIKE  ctbt010.*
DEFINE r_g13		RECORD LIKE  gent013.*
DEFINE resp		CHAR(6)

IF proforma_expiro() THEN
	CALL fgl_winmessage(vg_producto,'La proforma ya expiró.','exclamation')
	LET int_flag = 1
	RETURN
END IF

OPEN WINDOW w_220_3 AT 8,2 WITH 12 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, 
		  MESSAGE LINE LAST - 2) 
OPEN FORM f_220_3 FROM '../forms/repf220_3'
DISPLAY FORM f_220_3

INITIALIZE rm_r16.*, r_r16.*, r_r17.*, r_r03.*, r_p01.*, r_p02.*, r_b10.*, 
		   r_g13.*
		TO NULL

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
LET rm_r16.r16_moneda     = rg_gen.g00_moneda_base
LET rm_r16.r16_fec_envio  = TODAY
LET rm_r16.r16_tipo       = 'E'
LET rm_r16.r16_referencia = 'PROFORMA # '|| rm_r21.r21_numprof || '.' 
LET rm_r16.r16_estado     = 'A'
DISPLAY 'ACTIVO' TO tit_estado_rep
DISPLAY r_g13.g13_nombre TO tit_mon_bas

LET int_flag = 0
INPUT BY NAME rm_r16.r16_pedido,    rm_r16.r16_tipo,      rm_r16.r16_linea,
			  rm_r16.r16_proveedor, rm_r16.r16_fec_envio, rm_r16.r16_referencia,
              rm_r16.r16_moneda,    rm_r16.r16_aux_cont,  rm_r16.r16_estado
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF field_touched(r16_pedido,    r16_tipo,       r16_proveedor, 
						 r16_fec_envio, r16_referencia, r16_moneda,
						 r16_aux_cont)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLOSE WINDOW w_220_3
				RETURN
			END IF
		ELSE
			CLOSE WINDOW w_220_3
			RETURN
		END IF
	ON KEY(F2)
		IF infield(r16_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING r_r03.r03_codigo, r_r03.r03_nombre
			IF r_r03.r03_codigo IS NOT NULL THEN
				LET rm_r16.r16_linea = r_r03.r03_codigo
				DISPLAY BY NAME rm_r16.r16_linea
			END IF
		END IF
		IF infield(r16_proveedor) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				CALL fl_lee_proveedor_localidad(vg_codcia,
							vg_codloc, 
							r_p01.p01_codprov)
					RETURNING r_p02.*
				LET rm_r16.r16_proveedor = r_p01.p01_codprov
				LET rm_r16.r16_demora    = 
						r_p02.p02_dias_demora
				LET rm_r16.r16_seguridad = r_p02.p02_dias_seguri
				DISPLAY BY NAME rm_r16.r16_proveedor,
						rm_r16.r16_demora, 
						rm_r16.r16_seguridad
				DISPLAY r_p01.p01_nomprov TO tit_proveedor
			END IF
		END IF
		IF infield(r16_moneda) THEN
                        CALL fl_ayuda_monedas()
                                RETURNING r_g13.g13_moneda, r_g13.g13_nombre, 
					  r_g13.g13_decimales
                        IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_r16.r16_moneda = r_g13.g13_nombre
                                DISPLAY BY NAME rm_r16.r16_moneda
                                DISPLAY r_g13.g13_nombre TO tit_mon_bas
                        END IF
                END IF
		IF infield(r16_aux_cont) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,6)
                                RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
                        IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_r16.r16_aux_cont = r_b10.b10_cuenta
                                DISPLAY BY NAME rm_r16.r16_aux_cont
                                DISPLAY r_b10.b10_descripcion TO tit_aux_con
                        END IF
                END IF
		LET int_flag = 0

	AFTER FIELD r16_pedido
		IF rm_r16.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia,vg_codloc, rm_r16.r16_pedido)
				RETURNING r_r16.*
			IF r_r16.r16_compania IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto,'Este pedido ya fue realizado en la Compañía.','exclamation')
				NEXT FIELD r16_pedido
			END IF
		END IF
	AFTER FIELD r16_linea
		IF rm_r16.r16_linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_r16.r16_linea)
				RETURNING r_r03.*
			IF r_r03.r03_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe esa línea en la Compañía.','exclamation')
				NEXT FIELD r16_linea
			END IF
                        IF r_r03.r03_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r16_linea
                        END IF
			IF rm_r21.r21_grupo_linea <> r_r03.r03_grupo_linea THEN
				CALL fgl_winmessage(vg_producto, 'La Línea es diferente al Grupo de Línea que esta en la Proforma, debe ingresar una Línea que se encuentre dentro de ese Grupo de Línea.', 'exclamation')
				NEXT FIELD r16_linea
			END IF
		ELSE
			IF rm_r16.r16_tipo = 'S' THEN
				CALL fgl_winmessage(vg_producto,'Pedido es sugerido, escoja una línea.','exclamation')
				NEXT FIELD r16_linea
			END IF
		END IF
	AFTER FIELD r16_proveedor
		IF rm_r16.r16_proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor_localidad(vg_codcia,
						vg_codloc,rm_r16.r16_proveedor)
				RETURNING r_p02.*
			IF r_p02.p02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe ese proveedor en la Localidad de la Compañía.','exclamation')
				NEXT FIELD r16_proveedor
			END IF
			CALL fl_lee_proveedor(rm_r16.r16_proveedor)
				RETURNING r_p01.*
			DISPLAY r_p01.p01_nomprov TO tit_proveedor
			IF r_p01.p01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r16_proveedor
			END IF
			LET rm_r16.r16_demora    = r_p02.p02_dias_demora
			LET rm_r16.r16_seguridad = r_p02.p02_dias_seguri
			DISPLAY BY NAME rm_r16.r16_demora, rm_r16.r16_seguridad
		ELSE
			CLEAR r16_demora, r16_seguridad, tit_proveedor
		END IF
	AFTER FIELD r16_fec_envio
		IF rm_r16.r16_fec_envio IS NOT NULL THEN
			IF rm_r16.r16_fec_envio > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de envío no puede ser mayor a hoy.','exclamation')
				NEXT FIELD r16_fec_envio
			END IF
		END IF
	AFTER FIELD r16_moneda
		IF rm_r16.r16_moneda IS NOT NULL THEN
                        CALL fl_lee_moneda(rm_r16.r16_moneda)
                                RETURNING r_g13.*
                        IF r_g13.g13_moneda IS NULL  THEN
                        	CALL fgl_winmessage(vg_producto,'Moneda no existe en la Companía.','exclamation')
                                NEXT FIELD r16_moneda
                        END IF
                        DISPLAY r_g13.g13_nombre TO tit_mon_bas
                        IF r_g13.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r16_moneda
                        END IF
                ELSE
                        LET rm_r16.r16_moneda = rg_gen.g00_moneda_base
                        DISPLAY BY NAME rm_r16.r16_moneda
                        CALL fl_lee_moneda(rm_r16.r16_moneda) 
				RETURNING r_g13.*
                        DISPLAY r_g13.g13_nombre TO tit_mon_bas
                END IF
	AFTER FIELD r16_aux_cont
		IF rm_r16.r16_aux_cont IS NOT NULL THEN
                        CALL fl_lee_cuenta(vg_codcia, rm_r16.r16_aux_cont)
                                RETURNING r_b10.*
                        IF r_b10.b10_cuenta IS NULL THEN
                        	CALL fgl_winmessage(vg_producto,'Cuenta no existe en la Compañía.','exclamation')
                                NEXT FIELD r16_aux_cont
                        END IF
                        DISPLAY r_b10.b10_descripcion TO tit_aux_con
                        IF r_b10.b10_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD r16_aux_cont
                        END IF
			IF r_b10.b10_nivel <> 6 THEN
                        	CALL fgl_winmessage(vg_producto,'Nivel de cuenta debe ser solo 6.','info')
                                NEXT FIELD r16_aux_cont
                        END IF
                ELSE
                        CLEAR tit_aux_con
                END IF
	AFTER INPUT
		IF rm_r16.r16_tipo = 'S' THEN
			IF rm_r16.r16_linea IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Pedido es sugerido, escoja una línea.','exclamation')
				DISPLAY BY NAME rm_r16.r16_linea
				NEXT FIELD r16_linea
			END IF
		END IF
END INPUT	

CLOSE WINDOW w_220_3

END FUNCTION



FUNCTION control_grabar_proforma_pedido()
DEFINE expr_sql 	VARCHAR(200)
DEFINE r_r22		RECORD LIKE rept022.*
DEFINE r_r17		RECORD LIKE rept017.*
DEFINE r_r10		RECORD LIKE rept010.*

LET rm_r16.r16_compania    = vg_codcia
LET rm_r16.r16_localidad   = vg_codloc
LET rm_r16.r16_fec_envio   = CURRENT
LET rm_r16.r16_maximo      = 0
LET rm_r16.r16_minimo      = 0
LET rm_r16.r16_periodo_vta = 0
LET rm_r16.r16_pto_reorden = 0
LET rm_r16.r16_flag_estad  = 'M'
LET rm_r16.r16_usuario     = vg_usuario
LET rm_r16.r16_fecing      = CURRENT

BEGIN WORK
	INSERT INTO rept016 VALUES (rm_r16.*)
	LET expr_sql = 'SELECT * FROM rept022',
				' WHERE r22_compania  =', vg_codcia,
				'   AND r22_localidad =', vg_codloc,
				'   AND r22_numprof   =',rm_r21.r21_numprof,
				' ORDER BY r22_orden' 

	PREPARE ejecucion FROM expr_sql
	DECLARE q_det_ped CURSOR FOR ejecucion
		
	FOREACH q_det_ped INTO r_r22.*
		CALL fl_lee_item(rm_r16.r16_compania, r_r22.r22_item)
			RETURNING r_r10.*
		LET r_r17.r17_compania  = rm_r16.r16_compania	
		LET r_r17.r17_localidad = rm_r16.r16_localidad	
		LET r_r17.r17_pedido    = rm_r16.r16_pedido	
		LET r_r17.r17_item      = r_r22.r22_item	
		LET r_r17.r17_orden     = r_r22.r22_orden	
		LET r_r17.r17_estado    = 'A'	
		LET r_r17.r17_fob       = r_r10.r10_fob	
		LET r_r17.r17_cantped   = r_r22.r22_cantidad	
		LET r_r17.r17_cantrec   = 0	
		LET r_r17.r17_ind_bko   = 'S'
		LET r_r17.r17_cantpaq   = r_r10.r10_cantpaq
		LET r_r17.r17_peso      = r_r10.r10_peso
		LET r_r17.r17_partida   = r_r10.r10_partida
		LET r_r17.r17_linea     = r_r10.r10_linea
		LET r_r17.r17_rotacion  = r_r10.r10_rotacion

		-- Para consolidar cuando existen items repetidos en la
		-- proforma (suma lo que existe en pedido + la cantidad del 
		-- item repetido)
		WHENEVER ERROR CONTINUE
		INSERT INTO rept017 VALUES (r_r17.*)
		IF status < 0 THEN
			UPDATE rept017 set r17_cantped = r17_cantped +
							 r_r17.r17_cantped
				WHERE r17_compania  = vg_codcia
				  AND r17_localidad = vg_codloc
				  AND r17_pedido    = rm_r16.r16_pedido
				  AND r17_item      = r_r17.r17_item
		END IF
		WHENEVER ERROR STOP
	END FOREACH
COMMIT WORK

CALL fgl_winmessage(vg_producto, 'Proceso Realizado Ok.', 'info')

END FUNCTION



FUNCTION control_actualizacion_caja()
DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_upd		RECORD LIKE cajt010.*

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

IF STATUS <> NOTFOUND THEN
	DELETE FROM cajt010 WHERE CURRENT OF q_j10
END IF
CLOSE q_j10
FREE  q_j10

INITIALIZE r_j10.* TO NULL

CALL fl_lee_grupo_linea(vg_codcia, rm_r23.r23_grupo_linea)
	RETURNING rm_g20.*

LET r_j10.j10_areaneg     = rm_g20.g20_areaneg
LET r_j10.j10_codcli      = rm_r23.r23_codcli
LET r_j10.j10_nomcli      = rm_r23.r23_nomcli
LET r_j10.j10_moneda      = rm_r23.r23_moneda
LET r_j10.j10_valor       = rm_r23.r23_tot_neto 
LET r_j10.j10_fecha_pro   = CURRENT
LET r_j10.j10_usuario     = vg_usuario 
LET r_j10.j10_fecing      = CURRENT
LET r_j10.j10_compania    = vg_codcia
LET r_j10.j10_localidad   = vg_codloc
LET r_j10.j10_tipo_fuente = 'PR'
LET r_j10.j10_num_fuente  = rm_r23.r23_numprev
LET r_j10.j10_estado      = 'A'

INSERT INTO cajt010 VALUES(r_j10.*)

RETURN done

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT

CLEAR FORM
CALL control_display_botones()

LET vm_flag_mant = 'I'
INITIALIZE rm_r01.*, rm_r03.*, rm_r10.*, rm_g13.* TO NULL
INITIALIZE rm_g14.*, rm_g20.*, rm_c01.*, rm_c02.* TO NULL
INITIALIZE rm_r21.*, rm_r22.* TO NULL

FOR i = 1 TO 500 
	INITIALIZE r_detalle_1[i].* TO NULL
	INITIALIZE r_detalle_2[i].* TO NULL
END FOR

IF rm_r00.r00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,'No existe configuración para la Compañía en el área de Repuestos. ','exclamation')
	RETURN
END IF
IF rm_r00.r00_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,'La Compañía está con status BLOQUEADO en el área de Repuestos. ','exclamation')
	RETURN
END IF

-- INITIAL VALUES FOR rm_r21 FIELDS
LET vm_fecha              = DATE(CURRENT)
LET rm_r21.r21_usuario    = vg_usuario
LET rm_r21.r21_compania   = vg_codcia
LET rm_r21.r21_localidad  = vg_codloc
-- XXX esto es un hack horrible
IF vg_codloc = 1 THEN
	-- LET rm_r21.r21_bodega     = rm_r00.r00_bodega_fact
	LET rm_r21.r21_bodega     = 'MA'
END IF 
IF vg_codloc = 2 THEN
	-- LET rm_r21.r21_bodega     = rm_r00.r00_bodega_fact
	LET rm_r21.r21_bodega     = 'QT'
END IF
-- XXX fin del hack 
LET rm_r21.r21_dias_prof  = rm_r00.r00_dias_prof
LET rm_r21.r21_moneda     = rg_gen.g00_moneda_base
LET rm_r21.r21_porc_impto = rg_gen.g00_porc_impto
LET rm_r21.r21_descuento  =  0.0
LET vm_val_dscto2 = 0
LET rm_r21.r21_factor_fob = 1

CALL fl_lee_bodega_rep(vg_codcia, rm_r21.r21_bodega) -- PARA OBTENER EL NOMBRE
	RETURNING rm_r02.*			     -- DE LA BODEGA
	DISPLAY rm_r02.r02_nombre TO nom_bodega

CALL fl_lee_moneda(rg_gen.g00_moneda_base) 	     -- PARA OBTENER EL NOMBRE 
	RETURNING rm_g13.*		   	     -- DE LA MONEDA BASE
LET rm_r21.r21_precision = rm_g13.g13_decimales

DISPLAY BY NAME vm_fecha, rm_r21.r21_moneda, rm_r21.r21_porc_impto, 
		rm_r21.r21_dias_prof, rm_r21.r21_usuario, vm_val_dscto2
DISPLAY rm_g13.g13_nombre TO nom_moneda

CALL lee_datos()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET vm_total = 0
LET rm_r21.r21_tot_neto  = vm_total 

LET vm_num_detalles = ingresa_detalles() 
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

CALL ingresa_descuento2()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

	-- ACTUALIZO LOS VALORES DEFAULTS QUE INGRESE AL INICIO DE LEE DATOS --
LET rm_r21.r21_fecing = CURRENT
LET rm_r21.r21_tot_neto = vm_total
BEGIN WORK

	LET done = control_cabecera()
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso de la cabecera de la preventa no se realizará el proceso.','exclamation')
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
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso del detalle de la preventa no se realizará el proceso.','exclamation')
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
CALL muestra_contadores()
--CALL lee_muestra_registro(vm_rows[vm_row_current])

CALL control_imprimir_proforma()

CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
DEFINE cliente 			LIKE rept021.r21_codcli
DEFINE done				SMALLINT
DEFINE i				SMALLINT
DEFINE r_r10			RECORD LIKE rept010.*
DEFINE stock			LIKE rept011.r11_stock_act

IF fl_proforma_facturada(vg_codcia, vg_codloc, rm_r21.r21_numprof) THEN
	CALL fgl_winmessage(vg_producto, 'No se puede modificar proforma porque ya se han generado facturas.', 'exclamation')
	RETURN
END IF

LET vm_flag_mant = 'M'
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up2 CURSOR FOR 
	SELECT * FROM rept021 
		WHERE r21_compania  = vg_codcia
		AND   r21_localidad = vg_codloc
		AND   r21_numprof   = rm_r21.r21_numprof
	FOR UPDATE

OPEN q_up2
FETCH q_up2 
IF status < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP

LET cliente = rm_r21.r21_codcli
LET rm_r21.r21_dias_prof = rm_r00.r00_dias_prof

CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

IF cliente <> rm_r21.r21_codcli THEN
	CALL recalcular()
END IF 

LET vm_num_detalles = ingresa_detalles() 
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
ELSE

	CALL ingresa_descuento2()
	IF int_flag THEN
		IF vm_num_rows = 0 THEN
			CLEAR FORM
			CALL control_display_botones()
		ELSE	
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF

	LET rm_r21.r21_tot_dscto = vm_descuento + vm_val_dscto2
	UPDATE rept021 	
		SET * = rm_r21.*
		WHERE CURRENT OF q_up2

	DELETE FROM rept022
		WHERE r22_compania  = vg_codcia
		AND   r22_localidad = vg_codloc
		AND   r22_numprof   = rm_r21.r21_numprof

	LET done = control_ingreso_detalle()
	IF done = 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto,'Ha ocurrido un error al intentar actualizar el detalle de la preventa. No se realizará el proceso.','exclamation')
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN
	END IF

	COMMIT WORK
	--CALL lee_muestra_registro(vm_rows[vm_row_current])
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



FUNCTION control_cabecera()

SELECT MAX(r21_numprof) + 1 INTO rm_r21.r21_numprof
	FROM  rept021
	WHERE r21_compania  = vg_codcia
	AND   r21_localidad = vg_codloc

IF rm_r21.r21_numprof IS NULL THEN
	LET rm_r21.r21_numprof = 1
END IF

LET rm_r21.r21_tot_dscto = rm_r21.r21_tot_dscto + vm_val_dscto2

INSERT INTO rept021 VALUES (rm_r21.*)
DISPLAY BY NAME rm_r21.r21_numprof

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
        LET vm_num_rows = vm_num_rows + 1
END IF

LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 

RETURN 1

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE i,done 	SMALLINT
DEFINE r_r10	RECORD LIKE rept010.*
DEFINE r_r113	RECORD LIKE rept113.*
DEFINE orden	SMALLINT

LET done  = 1
LET orden = 1
-- INITIAL VALUES FOR rm_r22 FIELDS

DELETE FROM rept113
 WHERE r113_compania  = vg_codcia 
   AND r113_localidad = vg_codloc
   AND r113_numprof   = rm_r21.r21_numprof  

FOR i = 1 TO vm_num_detalles
	INITIALIZE rm_r22.* TO NULL
	LET rm_r22.r22_compania     = vg_codcia
	LET rm_r22.r22_localidad    = vg_codloc
	LET rm_r22.r22_numprof      = rm_r21.r21_numprof
	LET rm_r22.r22_cantidad     = r_detalle[i].r22_cantidad
	LET rm_r22.r22_item         = r_detalle[i].r22_item
	LET rm_r22.r22_item_ant     = r_detalle_1[i].r22_item_ant
	LET rm_r22.r22_porc_descto  = r_detalle_1[i].r22_porc_descto
	LET rm_r22.r22_precio       = r_detalle[i].r22_precio
	LET rm_r22.r22_dias_ent     = r_detalle[i].r22_dias_ent

	LET rm_r22.r22_orden        = orden
	LET orden = orden + 1
-- Para evitar que se caiga por que el campo r22_decripcion IS NULL
	IF r_detalle_1[i].r22_descripcion IS NULL THEN
		IF r_detalle[i].r22_item IS NULL THEN
			CONTINUE FOR
		ELSE
			CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item)
				RETURNING r_r10.*
			LET rm_r22.r22_descripcion = r_r10.r10_nombre
		END IF
	ELSE
		LET rm_r22.r22_descripcion  = r_detalle_1[i].r22_descripcion
	END IF
	LET rm_r22.r22_linea        = r_detalle_1[i].r22_linea
	LET rm_r22.r22_rotacion     = r_detalle_1[i].r22_rotacion
	LET rm_r22.r22_costo        = r_detalle_1[i].r22_costo
	
	LET rm_r22.r22_val_descto   = r_detalle_1[i].r22_val_descto
	LET rm_r22.r22_val_impto    = r_detalle_1[i].r22_val_impto 
	INSERT INTO rept022 VALUES(rm_r22.*)

	INITIALIZE r_r113.* TO NULL
	LET r_r113.r113_compania  = rm_r22.r22_compania  
	LET r_r113.r113_localidad = rm_r22.r22_localidad 
	LET r_r113.r113_numprof   = rm_r22.r22_numprof  
	LET r_r113.r113_orden     = rm_r22.r22_orden   
	LET r_r113.r113_item      = rm_r22.r22_item    
	LET r_r113.r113_precio_lista = r_detalle_2[i].r113_precio_lista
	LET r_r113.r113_dscto_clte   = r_detalle_2[i].r113_dscto_clte  
	LET r_r113.r113_recargo_clte = r_detalle_2[i].r113_recargo_clte  
	LET r_r113.r113_dscto_item   = r_detalle_2[i].r113_dscto_item  
	LET r_r113.r113_recargo_item = r_detalle_2[i].r113_recargo_item  
	INSERT INTO rept113 VALUES(r_r113.*)
END FOR 

RETURN done

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE cliente		LIKE rept021.r21_codcli
DEFINE done		SMALLINT

LET int_flag = 0
INPUT BY NAME   rm_r21.r21_moneda,     rm_r21.r21_bodega,     
		rm_r21.r21_dias_prof,  rm_r21.r21_grupo_linea, 
		rm_r21.r21_codcli,     rm_r21.r21_nomcli, 
		rm_r21.r21_cedruc,     rm_r21.r21_dircli,
		rm_r21.r21_telcli,     rm_r21.r21_vendedor, 
		rm_r21.r21_modelo,
		rm_r21.r21_forma_pago, rm_r21.r21_referencia,
		rm_r21.r21_atencion
		WITHOUT DEFAULTS

	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r21_grupo_linea, r21_codcli, r21_nomcli, 
				     r21_cedruc,  r21_vendedor,   r21_dircli)
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
		IF INFIELD(r21_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_r21.r21_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_r21.r21_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
		      	END IF
		END IF
		IF INFIELD(r21_bodega) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T')
		     	RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     IF rm_r02.r02_codigo IS NOT NULL THEN
			    LET rm_r21.r21_bodega = rm_r02.r02_codigo
			    DISPLAY BY NAME rm_r21.r21_bodega
			    DISPLAY rm_r02.r02_nombre TO nom_bodega
		     END IF
		END IF
		IF INFIELD(r21_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
				LET rm_r21.r21_vendedor = rm_r01.r01_codigo	
				DISPLAY BY NAME rm_r21.r21_vendedor
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r21_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r21.r21_codcli = rm_c02.z02_codcli
				LET rm_r21.r21_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r21.r21_codcli,
						rm_r21.r21_nomcli
			END IF 
		END IF
		IF INFIELD(r21_grupo_linea) THEN
		      CALL fl_ayuda_grupo_lineas(vg_codcia)
			   RETURNING rm_g20.g20_grupo_linea, rm_g20.g20_nombre
			IF rm_g20.g20_grupo_linea IS NOT NULL THEN
				LET rm_r21.r21_grupo_linea = 
				    rm_g20.g20_grupo_linea
				DISPLAY BY NAME rm_r21.r21_grupo_linea
			    	DISPLAY  rm_g20.g20_nombre TO nom_grupo
			END IF
		END IF
		LET int_flag = 0

	ON KEY(F5)	
		CALL control_crear_cliente()
		LET INT_FLAG = 0

	AFTER FIELD r21_moneda
		IF rm_r21.r21_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_r21.r21_moneda)
				RETURNING rm_g13.*
                	IF rm_g13.g13_moneda IS  NULL THEN
		    		CALL fgl_winmessage (vg_producto, 'La moneda no existe en la Comapañía. ','exclamation')
				CLEAR nom_moneda
                        	NEXT FIELD r21_moneda
			END IF
			IF  rm_r21.r21_moneda <> rg_gen.g00_moneda_base AND
			    rm_r21.r21_moneda <> rg_gen.g00_moneda_alt
			    THEN
				CALL fgl_winmessage(vg_producto,'La Moneda ingresada no es la moneda base ni la moneda alterna','exclamation')
				CLEAR nom_moneda
				NEXT FIELD r21_moneda
			END IF
			IF rm_r21.r21_moneda = rg_gen.g00_moneda_alt THEN
				CALL fl_lee_factor_moneda(rm_r21.r21_moneda,
							rg_gen.g00_moneda_base)
					RETURNING rm_g14.*
				IF rm_g14.g14_tasa IS NULL THEN
					CALL fgl_winmessage(vg_producto,'No existe conversión entre la moneda base i moneda alterna. Debe revisar la configuración. ','exclamation')
					NEXT FIELD r21_moneda
				END IF 
			END IF 
			LET rm_r21.r21_precision = rm_g13.g13_decimales
			DISPLAY rm_g13.g13_nombre TO nom_moneda
		ELSE
			CLEAR nom_moneda
                END IF
	AFTER FIELD r21_bodega
		IF rm_r21.r21_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r21.r21_bodega)
				RETURNING rm_r02.*
			IF rm_r02.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe',
						    'exclamation')
				CLEAR nom_bodega
				NEXT FIELD r21_bodega
			END IF 
			IF rm_r02.r02_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
						            'Bodega está ' ||
                                                            'bloqueada',
							    'exclamation')
					NEXT FIELD r21_bodega
			END IF
			IF rm_r02.r02_factura <> 'S' THEN
					CALL fgl_winmessage(vg_producto,
						            'Bodega no ' ||
                                                            'factura',
							    'exclamation')
					NEXT FIELD r21_bodega
			END IF
			DISPLAY rm_r02.r02_nombre TO nom_bodega
		ELSE
			CLEAR nom_bodega
		END IF
	AFTER FIELD r21_vendedor
		IF rm_r21.r21_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor)
				RETURNING rm_r01.*
			IF rm_r01.r01_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'Vendedor no existe',
						    'exclamation')
				CLEAR nom_vendedor
				NEXT FIELD r21_vendedor
			END IF 
			IF rm_r01.r01_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
						            'Vendedor está ' ||
                                                            'bloqueado',
							    'exclamation')
					NEXT FIELD r21_vendedor
			END IF
			DISPLAY rm_r01.r01_nombres TO nom_vendedor
		ELSE
			CLEAR nom_vendedor
		END IF		 
	AFTER FIELD r21_grupo_linea
		IF rm_r21.r21_grupo_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(vg_codcia, 
					        rm_r21.r21_grupo_linea)
				RETURNING rm_g20.*
			IF rm_g20.g20_grupo_linea IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Grupo de '||
					            'Línea de Venta no existe',
						    'exclamation')
				CLEAR nom_grupo
				NEXT FIELD r21_grupo_linea
			END IF
			DISPLAY rm_g20.g20_nombre TO nom_grupo
		ELSE
			CLEAR nom_grupo
			NEXT FIELD r21_grupo_linea
		END IF
	AFTER FIELD r21_codcli
		IF rm_r21.r21_codcli IS NOT NULL OR
		   rm_r21.r21_codcli <> ''
		   THEN
			CALL control_cliente() RETURNING cliente
			IF cliente IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el Cliente en la Compañía. ','exclamation') 
				CLEAR r21_nomcli, r21_cedruc, r21_dircli
				INITIALIZE rm_r21.r21_telcli TO NULL 
				NEXT FIELD r21_codcli
			END IF
			IF rm_c01.z01_estado <>'A' THEN
				CALL fgl_winmessage(vg_producto,
						    'Cliente está bloqueado',
						    'exclamation')
				NEXT FIELD r21_codcli
			END IF
		END IF
	BEFORE FIELD r21_nomcli
		IF rm_r21.r21_codcli IS NOT NULL THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD r21_cedruc
		IF rm_r21.r21_codcli IS NOT NULL THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD r21_dircli
		IF rm_r21.r21_codcli IS NOT NULL THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD r21_telcli
		IF rm_r21.r21_codcli IS NOT NULL THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD r21_dias_prof
		IF rm_r21.r21_dias_prof IS NULL THEN
			NEXT FIELD r21_dias_prof
		END IF
		IF rm_r21.r21_dias_prof = 0 THEN
			NEXT FIELD r21_dias_prof
		END IF
			
END INPUT

END FUNCTION



FUNCTION control_cliente()
DEFINE cliente	LIKE rept021.r21_codcli
 
	INITIALIZE cliente TO NULL
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r21.r21_codcli)
		RETURNING rm_c02.*
	IF rm_c02.z02_codcli IS NULL THEN
		RETURN cliente
	END IF
	CALL fl_lee_cliente_general(rm_r21.r21_codcli) RETURNING rm_c01.*

	LET cliente				 = rm_c01.z01_codcli
	LET rm_r21.r21_nomcli    = rm_c01.z01_nomcli
	LET rm_r21.r21_dircli    = rm_c01.z01_direccion1
	LET rm_r21.r21_cedruc    = rm_c01.z01_num_doc_id
	LET rm_r21.r21_telcli    = rm_c01.z01_telefono1

	LET rm_r21.r21_porc_impto = rg_gen.g00_porc_impto
	IF rm_c01.z01_paga_impto = 'N' THEN
		LET rm_r21.r21_porc_impto = 0 
	END IF
	DISPLAY BY NAME rm_r21.r21_nomcli, rm_r21.r21_dircli, rm_r21.r21_cedruc, 
					rm_r21.r21_telcli, rm_r21.r21_porc_impto

	RETURN cliente
END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j,k,ind		SMALLINT
DEFINE resp				CHAR(6)
DEFINE stock			LIKE rept022.r22_cantidad
DEFINE stock_disp		LIKE rept022.r22_cantidad
DEFINE item_anterior	LIKE rept010.r10_codigo
DEFINE num_elm			SMALLINT
DEFINE salir  			SMALLINT
DEFINE in_array			SMALLINT
DEFINE valor_min		LIKE rept022.r22_precio
DEFINE bodega			LIKE rept011.r11_bodega

DEFINE r_r114			RECORD LIKE rept114.*

INITIALIZE item_anterior TO NULL

LET vm_filas_pant  = fgl_scr_size('r_detalle')
LET i = 1
LET j = 1
LET salir    = 0
LET in_array = 0

WHILE NOT salir
LET int_flag = 0
IF vm_flag_mant <> 'M' THEN
	IF NOT in_array THEN
		INITIALIZE r_detalle[1].* TO NULL
	END IF
	IF in_array THEN
		LET i = vm_ind_arr
	END IF
	CALL set_count(i)
ELSE 
	CALL set_count(vm_ind_arr)
END IF
INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
		DISPLAY '' AT 10,1
		DISPLAY i, ' de ', arr_count() AT 17, 1 
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT WHILE      
		END IF
	ON KEY(F2)
		IF INFIELD(r22_item) THEN
        	CALL fl_ayuda_maestro_items_stock(vg_codcia, rm_r21.r21_grupo_linea,
											  rm_r21.r21_bodega)
                    		RETURNING rm_r10.r10_codigo,  rm_r10.r10_nombre,
									  bodega,  rm_r10.r10_linea,
									  rm_r10.r10_precio_mb,stock,stock_disp 
            IF rm_r10.r10_codigo IS NOT NULL THEN
				LET r_detalle[i].r22_item   = rm_r10.r10_codigo
				CALL fl_lee_item(vg_codcia, rm_r10.r10_codigo) 
						RETURNING rm_r10.*

                DISPLAY r_detalle[i].r22_item   	 TO r_detalle[j].r22_item
				DISPLAY rm_r10.r10_nombre TO r_detalle[j].r10_nombre
			END IF
        END IF
		IF INFIELD(r22_dias_ent) THEN
        	CALL fl_ayuda_factor_importacion_stock_rep(vg_codcia)
				RETURNING r_r114.r114_codigo, r_r114.r114_descripcion
            IF r_r114.r114_codigo IS NOT NULL THEN
				LET r_detalle[i].r22_dias_ent   = r_r114.r114_codigo
			END IF
		END IF
		LET INT_FLAG = 0
	ON KEY(F6)
		CALL control_crear_item()
		LET INT_FLAG = 0
	ON KEY(F7)
		CALL control_ver_item(r_detalle[i].r22_item)
		LET INT_FLAG = 0
	BEFORE INPUT
		IF in_array THEN
			CALL dialog.setcurrline(j, k)
			LET i = k           # POSICION CORRIENTE EN EL ARRAY
			LET in_array = 0
			NEXT FIELD r22_item
		END IF
	AFTER ROW
		-------------------------------------------------------------
		-- PARA SABER SI ESTE ITEM ESTA SUSTITUIDO POR OTRO
		CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item) RETURNING rm_r10.*
		IF rm_r10.r10_estado = 'S' AND r_detalle[i].r22_dias_ent <> rm_tipinv.sto_codigo THEN
			LET num_elm = arr_count()
			CALL fl_sustituido_por(vg_codcia, rm_r10.r10_codigo)
			CALL proceso_sustitucion(rm_r10.r10_codigo, j, i, num_elm) 
				RETURNING num_elm
			CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item) RETURNING rm_r10.*
			CALL calcula_totales(num_elm)
			LET k = i
			LET vm_ind_arr = num_elm
			LET in_array = 1
			EXIT INPUT
		END IF
		CALL calcular_rentabilidad_minima_detalle_factura(i) RETURNING valor_min
		IF valor_min > r_detalle[i].r22_precio THEN
			CALL fgl_winmessage(vg_producto, 'El precio del item esta por debajo de la rentabilidad minima.', 'exclamation')
		END IF 
	BEFORE INSERT
		-- Se debe insertar una fila en el arreglo paralelo
{* 
 * Yo se que habia anadido esta validacion por algo pero no
 * me acuerdo porque fue y ahora hay problemas por eso.
 *}
--		IF r_detalle[i].r22_item IS NOT NULL THEN
			CALL addRows(i, arr_count(), 1)
			INITIALIZE r_detalle_1[i].* TO NULL
			INITIALIZE r_detalle_2[i].* TO NULL
--		END IF
	AFTER INSERT
		CALL llena_arreglo_detalle(i, i)
	AFTER DELETE	
		CALL deleteRow(i, arr_count() + 1)
		CALL calcula_totales(arr_count())
		CALL mostrar_lineas_actuales(arr_curr(), arr_count(),
									 scr_line(), vm_filas_pant)
--		DISPLAY r_detalle[i].r22_cantidad  TO r_detalle[j].r22_cantidad
--		DISPLAY r_detalle[i].subtotal_item TO r_detalle[j].subtotal_item
--		DISPLAY r_detalle[i].r22_cantidad  TO r_detalle[j].r22_cantidad
--		DISPLAY r_detalle[i].subtotal_item TO r_detalle[j].subtotal_item
		DISPLAY r_detalle[i].* TO r_detalle[j].*
	AFTER FIELD r22_cantidad
		IF r_detalle[i].r22_cantidad IS NULL THEN
			LET r_detalle[i].r22_cantidad = 0
			DISPLAY r_detalle[i].r22_cantidad TO r_detalle[j].r22_cantidad
		END IF
		IF r_detalle[i].r22_item IS NOT NULL THEN
			CALL obtener_codigo_factor_stock(r_detalle[i].r22_item, 
											 r_detalle[i].r22_cantidad,
											 r_detalle[i].r22_dias_ent) 
				RETURNING r_detalle[i].r22_dias_ent
		END IF
		LET k = i - j + 1
		CALL calcula_totales(arr_count())
		CALL mostrar_lineas_actuales(arr_curr(), arr_count(),
									 scr_line(), vm_filas_pant)
		DISPLAY r_detalle[i].subtotal_item TO r_detalle[j].subtotal_item
	BEFORE FIELD r22_item
		LET item_anterior = r_detalle[i].r22_item
	AFTER FIELD r22_item
		IF r_detalle[i].r22_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item) RETURNING rm_r10.*
			IF rm_r10.r10_codigo IS NULL THEN
				CALL FGL_WINQUESTION(vg_producto, 'Item no existe desea crearlo.','Yes',
									 'Yes|No|Cancel','question',1) 
					RETURNING resp
				IF resp = 'Yes' THEN
					CALL control_crear_item()
				END IF
				NEXT FIELD r22_item
			END IF
			IF rm_r10.r10_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto, 'El Item está con status Bloqueado.',
									'exclamation')
				NEXT FIELD r22_item
			END IF
		------ PARA LA VALIDACION DE ITEMS REPETIDOS ------
		FOR k = 1 TO arr_count()
			IF  r_detalle_1[i].r22_item_ant IS NOT NULL THEN
				EXIT FOR
			END IF
			IF  r_detalle[i].r22_item = r_detalle[k].r22_item AND 
			    i <> k THEN
				IF  r_detalle_1[k].r22_item_ant IS NOT NULL THEN
					CONTINUE FOR
				END IF
				CALL fgl_winquestion(vg_producto,
					'El item ya ' ||
					' fue ingresado ' ||
					' en la posición ' || k ||
					', desea ir a esa posición?',
					'Yes', 'Yes|No', 'question', 1)
					RETURNING resp	
				IF resp = 'Yes' THEN
					IF i < arr_count() AND item_anterior
						IS NOT NULL THEN
						LET r_detalle[i].r22_item =
							item_anterior
						DISPLAY r_detalle[i].* TO
						        r_detalle[j].*
						LET i = arr_count() 
					ELSE
						INITIALIZE r_detalle[i].*
							TO NULL
						LET i = arr_count() - 1	
					END IF
					LET vm_ind_arr = i 
					LET in_array = 1
					EXIT INPUT
				END IF
				CALL fgl_winmessage(vg_producto,
					'No puede ingresar items ' ||
					' repetidos.', 
					'exclamation')
				NEXT FIELD r22_item
               		END IF
		END FOR
		----------------------------------------------------------
		--- PARA SABER SI LA LINEA DE VTA. CORRESPONDE AL GRP. VTA. ---
			CALL fl_lee_linea_rep(vg_codcia, rm_r10.r10_linea) RETURNING rm_r03.*	
			IF rm_r03.r03_grupo_linea <> rm_g20.g20_grupo_linea THEN
				CALL fgl_winmessage(vg_producto,'El Item no pertenece al Grupo de Línea de Venta. ','exclamation')
				NEXT FIELD r22_item
			END IF
		-------------------------------------------------------------
		CALL obtener_codigo_factor_stock(r_detalle[i].r22_item, 
										 r_detalle[i].r22_cantidad,
										 r_detalle[i].r22_dias_ent) 
			RETURNING r_detalle[i].r22_dias_ent
		----------------------------------------------------------
		IF item_anterior <> r_detalle[i].r22_item AND rm_r10.r10_estado = 'A' THEN
			LET r_detalle_1[i].r22_item_ant = NULL
		END IF
		----------------------------------------------------------
		-- PARA SABER SI ESTE ITEM ESTA SUSTITUIDO POR OTRO
		IF rm_r10.r10_estado = 'S' AND r_detalle[i].r22_dias_ent <> rm_tipinv.sto_codigo 
		THEN
			LET i = arr_curr()
			LET j = scr_line()
			LET num_elm = arr_count()
			CALL fl_sustituido_por(vg_codcia, rm_r10.r10_codigo)
			CALL proceso_sustitucion(rm_r10.r10_codigo, j, i, num_elm) RETURNING num_elm
			CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item) RETURNING rm_r10.*
			CALL calcula_totales(num_elm)
			LET k = i
			LET vm_ind_arr = num_elm
			LET in_array = 1
			EXIT INPUT
		END IF
		-------------------------------------------------------------
		---- ASIGNO VALORES SI TODO OK. ----
		CALL datos_proforma(rm_r10.*, i)
		IF r_detalle[i].r22_precio <= 0 THEN
			CALL fgl_winmessage(vg_producto, 'Item tiene precio cero.', 
								'exclamation')
			NEXT FIELD r22_item
		END IF
		CALL obtener_descuento_item(rm_r10.r10_codigo, i) 
			RETURNING r_detalle_1[i].r22_porc_descto, 
					  r_detalle_1[i].r22_val_descto 
		DISPLAY rm_r10.r10_nombre TO r_detalle[j].r10_nombre
		------------------------------------------------------------
		CALL fl_lee_stock_disponible_rep(vg_codcia, vg_codloc, 
										 r_detalle[i].r22_item, 'R') 
			RETURNING stock 
		IF stock < 0 THEN
			LET stock = 0
		END IF
		----------------------------------------------------------
		LET k = i - j + 1
		CALL calcula_totales(arr_count())
		CALL mostrar_lineas_actuales(arr_curr(), arr_count(),
									 scr_line(), vm_filas_pant)
		DISPLAY r_detalle[i].* TO r_detalle[j].*

		------------------------------------------------------------
		ELSE
			IF r_detalle[i].r22_cantidad IS NOT NULL THEN
				NEXT FIELD r22_item
			END IF 
		END IF
	AFTER FIELD r22_dias_ent
		IF r_detalle[i].r22_dias_ent IS NOT NULL THEN
			IF stock < r_detalle[i].r22_cantidad THEN
				IF r_detalle[i].r22_dias_ent = rm_tipinv.sto_codigo THEN
					CALL fgl_winmessage(vg_producto, 'No existe stock en el inventario no se puede realizar entrega inmediata.','exclamation')
					LET r_detalle[i].r22_dias_ent = rm_tipinv.imp_codigo
					DISPLAY r_detalle[i].r22_dias_ent 
						 TO r_detalle[j].r22_dias_ent
					NEXT FIELD r22_dias_ent
				END IF
			END IF
			CALL fl_lee_factor_importacion_stock_rep(vg_codcia, 
												  r_detalle[i].r22_dias_ent) 
				RETURNING r_r114.*
			IF r_r114.r114_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Factor no existe.', 'exclamation')
				NEXT FIELD r22_dias_ent
			END IF
			CASE r_r114.r114_flag_ident 
				WHEN 'STO' 
					LET rm_tipinv.sto_codigo     = r_r114.r114_codigo
					LET rm_tipinv.sto_factor     = r_r114.r114_factor
					LET rm_tipinv.sto_flag_ident = r_r114.r114_flag_ident
				WHEN 'IMP' 
					LET rm_tipinv.imp_codigo     = r_r114.r114_codigo
					LET rm_tipinv.imp_factor     = r_r114.r114_factor
					LET rm_tipinv.imp_flag_ident = r_r114.r114_flag_ident
			END CASE
		END IF
	AFTER INPUT
		IF rm_r21.r21_tot_neto = 0 THEN
			NEXT FIELD r22_cantidad
		END IF
		LET ind = arr_count()
		LET vm_ind_arr = ind
		LET j = 1
		FOR i = 1 TO ind 
			CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item)
				RETURNING rm_r10.*
			IF rm_r10.r10_estado = 'S' 
			AND r_detalle[i].r22_dias_ent <> rm_tipinv.sto_codigo 
			THEN
				LET num_elm = ind
				CALL fl_sustituido_por(vg_codcia, rm_r10.r10_codigo)
				CALL proceso_sustitucion(rm_r10.r10_codigo, j, i, num_elm) 
					RETURNING num_elm
				CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item) RETURNING rm_r10.*
				LET k = i - j + 1
				CALL calcula_totales(num_elm)
				LET k = i	-- Conservo la posicion actual 
						    -- del input
				LET i = num_elm
				LET vm_ind_arr = num_elm
				LET in_array = 1
				EXIT INPUT
			END IF
		END FOR
		LET i = arr_count()
		LET k = i - j + 1
		CALL calcula_totales(i)
		CALL calcula_muestra_totales_factura()
		CALL mostrar_lineas_actuales(arr_curr(), i,
									 scr_line(), vm_filas_pant)

		IF rentabilidad_factura_no_permitida(i) THEN
			CALL fgl_winmessage(vg_producto, 'El valor de la factura esta por debajo de la rentabilidad mínima.', 'stop')
--			CONTINUE INPUT
		END IF

		LET salir = 1
END INPUT
END WHILE
DISPLAY '' AT 10,1
IF int_flag THEN
	RETURN 0
ELSE
	RETURN ind
END IF

END FUNCTION


{*
 * Se calcula un valor de recargo para el item segun el factor
 * indicado en el record rm_tipinv, dependiendo de si el item 
 * esta en stock o se va a importar 
 *}
FUNCTION obtener_codigo_factor_stock(item, cantidad, dias_ent) 
DEFINE item		LIKE rept022.r22_item
DEFINE cantidad	LIKE rept022.r22_cantidad
DEFINE dias_ent	LIKE rept022.r22_dias_ent
DEFINE stock	LIKE rept022.r22_cantidad

	IF dias_ent <> rm_tipinv.sto_codigo THEN
		RETURN dias_ent
	END IF

	CALL fl_lee_stock_disponible_rep(vg_codcia, vg_codloc, item, 'R') 
		RETURNING stock 
	IF stock < 0 THEN
		LET stock = 0
	END IF
	IF stock >= cantidad THEN
		-- Se puede despachar de stock
		LET dias_ent = rm_tipinv.sto_codigo
	ELSE
		LET dias_ent = rm_tipinv.imp_codigo
	END IF

	RETURN dias_ent 
END FUNCTION



FUNCTION datos_proforma(r_r10, i)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i			INTEGER

	LET r_detalle[i].r22_item			= r_r10.r10_codigo
	LET r_detalle_1[i].r22_descripcion 	= r_r10.r10_nombre
	LET r_detalle[i].r10_nombre 		= r_r10.r10_nombre
	LET r_detalle_1[i].r22_linea		= r_r10.r10_linea
	LET r_detalle_1[i].r22_rotacion		= r_r10.r10_rotacion
	LET r_detalle_1[i].peso				= r_r10.r10_peso

	IF rg_gen.g00_moneda_base = rm_r21.r21_moneda THEN
		LET r_detalle[i].r22_precio =
			fl_obtener_precio_tipo_cliente(rm_c01.z01_tipo_clte,
										   r_r10.r10_precio_mb,
										   r_r10.r10_costo_mb,
										   r_r10.r10_fob) 
		LET r_detalle_1[i].r22_costo = r_r10.r10_costo_mb
	ELSE	
		LET r_detalle[i].r22_precio =
			fl_obtener_precio_tipo_cliente(rm_c01.z01_tipo_clte,
										   r_r10.r10_precio_ma,
										   r_r10.r10_costo_ma,
										   r_r10.r10_fob) 
		LET r_detalle_1[i].r22_costo = r_r10.r10_costo_ma
	END IF	
	LET r_detalle_2[i].r113_precio_lista = r_detalle[i].r22_precio

	IF r_detalle[i].r22_cantidad IS NOT NULL THEN
		LET r_detalle[i].subtotal_item = 
			r_detalle[i].r22_precio * r_detalle[i].r22_cantidad
		LET r_detalle_1[i].val_costo = 
			r_detalle_1[i].r22_costo * r_detalle[i].r22_cantidad
	END IF

END FUNCTION



FUNCTION obtener_descuento_item(item, i)
DEFINE item				LIKE rept010.r10_codigo
DEFINE i				INTEGER

DEFINE stock			LIKE rept022.r22_cantidad
DEFINE cantidad			LIKE rept022.r22_cantidad
DEFINE dif				LIKE rept022.r22_cantidad
DEFINE val_dscto_dif	LIKE rept022.r22_val_descto

DEFINE r_z02			RECORD LIKE cxct002.*
DEFINE r_r110			RECORD LIKE rept110.*
DEFINE porc_dscto     	LIKE rept022.r22_porc_descto
DEFINE porc_dscto_item	LIKE rept022.r22_porc_descto
DEFINE val_dscto		LIKE rept022.r22_val_descto
DEFINE valor_min		LIKE rept010.r10_costo_mb

	LET r_detalle_2[i].r113_dscto_clte = 0
	LET r_detalle_2[i].r113_recargo_clte = 0
	LET r_detalle_2[i].r113_dscto_item = 0
	LET r_detalle_2[i].r113_recargo_item = 0

	IF fl_tipo_cliente_venta_costo_fob(rm_c01.z01_tipo_clte) THEN
		RETURN 0, 0
	END IF

	IF rm_r21.r21_codcli IS NOT NULL THEN
		CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r21.r21_codcli)
			RETURNING r_z02.*
		LET r_detalle_2[i].r113_dscto_clte = r_z02.z02_dcto_item_c
		LET r_detalle_2[i].r113_recargo_clte = r_z02.z02_dcto_item_r
	END IF
	
	CALL fl_obtener_promocion_activa_item(vg_codcia, vg_codloc, item)
		RETURNING r_r110.*
	LET porc_dscto_item = r_r110.r110_descuento 
	IF porc_dscto_item IS NULL THEN
		LET porc_dscto_item = 0
	END IF
	LET cantidad = r_detalle[i].r22_cantidad
	IF cantidad IS NULL THEN
		LET cantidad = 0
	END IF
	IF r_r110.r110_stock_limite IS NOT NULL THEN
		CALL fl_lee_stock_disponible_rep(vg_codcia, vg_codloc, item, 'R') 
			RETURNING stock
		IF stock < 0 THEN
			LET stock = 0
		END IF
		IF (stock - r_r110.r110_stock_limite) < cantidad THEN
			LET dif = stock - r_r110.r110_stock_limite
			LET val_dscto_dif = r_detalle[i].r22_precio * dif * 
								porc_dscto_item / 100  
			LET porc_dscto_item = (val_dscto_dif * 100) / 
								  (r_detalle[i].r22_precio * cantidad)
		END IF
	END IF

	LET r_detalle_2[i].r113_dscto_item = porc_dscto_item
	LET r_detalle_2[i].r113_recargo_item = r_r110.r110_recargo
	IF r_detalle_2[i].r113_recargo_item IS NULL THEN
		LET r_detalle_2[i].r113_recargo_item = 0
	END IF 

	LET porc_dscto = 0
	IF r_detalle_2[i].r113_dscto_clte > 0 THEN
		LET porc_dscto = porc_dscto + r_detalle_2[i].r113_dscto_clte
	END IF
	IF porc_dscto_item > 0 THEN
		LET porc_dscto = porc_dscto + porc_dscto_item
	END IF

	CALL calcular_precio_item_cliente(i) RETURNING r_detalle[i].r22_precio

	LET val_dscto = r_detalle[i].r22_precio * porc_dscto / 100  

	CALL calcular_rentabilidad_minima_detalle_factura(i)
		RETURNING valor_min

	IF (r_detalle[i].r22_precio - val_dscto) < valor_min THEN
		IF porc_dscto <= 0 THEN
			-- No se puede rebajar el dscto si no se ha dado nada
			RETURN 0, 0 
		END IF
--		LET val_dscto = r_detalle[i].r22_precio - valor_min
--		LET porc_dscto = (val_dscto * 100) / r_detalle[i].r22_precio
	END IF 
	LET val_dscto = fl_retorna_precision_valor(rm_r21.r21_moneda, val_dscto)

	RETURN porc_dscto, val_dscto

END FUNCTION



FUNCTION control_crear_cliente()
DEFINE command_run		VARCHAR(100)

LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', 
	           vg_separador, 'fuentes', vg_separador, '; 
		   fglrun cxcp101 ', vg_base, ' ','CO', ' ',vg_codcia, ' ',
		   vg_codloc
RUN command_run

END FUNCTION



FUNCTION control_crear_item()
DEFINE command_run		VARCHAR(100)

LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	           vg_separador, 'fuentes', vg_separador, '; 
		   fglrun repp108 ', vg_base, ' ','RE', ' ',vg_codcia
RUN command_run

END FUNCTION



FUNCTION control_ver_item(item)
DEFINE item 		LIKE rept010.r10_codigo
DEFINE command_run		VARCHAR(100)

IF item IS NULL THEN
	RETURN
END IF

LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	           vg_separador, 'fuentes', vg_separador, '; 
		   fglrun repp306 ', vg_base, ' ','RE', ' ',vg_codcia, ' ', vg_codloc,
			' ', item
RUN command_run

END FUNCTION



FUNCTION calcula_totales(indice)
DEFINE indice,k		SMALLINT
DEFINE y			SMALLINT

LET vm_costo     = 0	-- TOTAL COSTO 
LET vm_subtotal  = 0	-- TOTAL BRUTO 
LET vm_descuento = 0	-- TOTAL DEL DESCUENTO
LET vm_impuesto  = 0 	-- TOTAL DEL IMPUESTO
LET vm_total     = 0	-- TOTAL NETO
LET vm_tot_peso  = 0	-- TOTAL PESO

CALL recalcular_precios_items(indice)

FOR k = 1 TO indice
	IF assert_valor_nulo(k) THEN
		CONTINUE FOR
	END IF
	IF r_detalle_1[k].r22_costo IS NULL THEN
		LET r_detalle_1[k].r22_costo = 0 
	END IF
	LET r_detalle_1[k].val_costo = r_detalle[k].r22_cantidad * 
								   r_detalle_1[k].r22_costo
	LET vm_costo = vm_costo + r_detalle_1[k].val_costo 

	LET r_detalle[k].subtotal_item = r_detalle[k].r22_precio *  
									 r_detalle[k].r22_cantidad
	LET vm_subtotal = vm_subtotal + r_detalle[k].subtotal_item
	LET vm_subtotal = fl_retorna_precision_valor(rm_r21.r21_moneda,
												 vm_subtotal)

	LET r_detalle_1[k].r22_val_descto = 
			r_detalle[k].subtotal_item * r_detalle_1[k].r22_porc_descto / 100
	LET r_detalle_1[k].r22_val_descto = 
			fl_retorna_precision_valor(rm_r21.r21_moneda,
								       r_detalle_1[k].r22_val_descto)

	IF r_detalle_1[k].r22_val_descto IS NOT NULL THEN
		LET vm_descuento = vm_descuento + r_detalle_1[k].r22_val_descto
	END IF

	LET r_detalle_1[k].r22_val_impto = 0

	LET vm_tot_peso =  vm_tot_peso + 
			   (r_detalle_1[k].peso * r_detalle[k].r22_cantidad)
END FOR

CALL calcula_muestra_totales_factura()

END FUNCTION



{*
 * Los precios de los items que se importan tienen un recargo. Ese recargo se
 * distribuira proporcionalmente entre todos los items que se importan.
 *}
FUNCTION recalcular_precios_items(num_elm)
DEFINE curr_pos				SMALLINT
DEFINE num_elm, i			SMALLINT
DEFINE total_si_en_stock	LIKE rept010.r10_precio_mb
DEFINE total_diff			LIKE rept010.r10_precio_mb
DEFINE dist_incr			LIKE rept010.r10_precio_mb

	CALL recalcular_valores(num_elm) RETURNING total_si_en_stock, total_diff

	FOR i = 1 TO num_elm
		IF r_detalle[i].r22_dias_ent <> rm_tipinv.sto_codigo THEN
			LET dist_incr = 
				((r_detalle[i].r22_precio * r_detalle[i].r22_cantidad)
				/ total_si_en_stock) * total_diff 
			LET dist_incr = dist_incr / r_detalle[i].r22_cantidad
			LET r_detalle[i].r22_precio = r_detalle[i].r22_precio + dist_incr
		ELSE
			LET r_detalle[i].r22_precio = r_detalle[i].r22_precio * 
										  (1 + (rm_tipinv.sto_factor / 100))
		END IF
	END FOR
END FUNCTION



FUNCTION recalcular_valores(num_elm)
DEFINE num_elm			SMALLINT
DEFINE i				SMALLINT
DEFINE total, diff		LIKE rept010.r10_precio_mb
DEFINE precio, recargo	LIKE rept010.r10_precio_mb

	LET total = 0
	LET diff  = 0
	FOR i = 1 TO num_elm
		IF assert_valor_nulo(i) THEN
			CONTINUE FOR
		END IF
		LET precio = calcular_precio_item_cliente(i) 
		LET r_detalle[i].r22_precio = precio
		LET precio = precio * r_detalle[i].r22_cantidad
						
		IF r_detalle[i].r22_dias_ent <> rm_tipinv.sto_codigo THEN
			LET r_detalle[i].r22_dias_ent = rm_tipinv.imp_codigo
		END IF
		CASE r_detalle[i].r22_dias_ent
			WHEN rm_tipinv.sto_codigo 
				LET recargo = precio * rm_tipinv.sto_factor / 100
			WHEN rm_tipinv.imp_codigo 
				LET recargo = precio * rm_tipinv.imp_factor / 100
				LET total = total + precio 
				LET diff  = diff + recargo
		END CASE
	END FOR

	-- El valor a retornar solo considera los items que se importaran
	RETURN total, diff
END FUNCTION



FUNCTION assert_valor_nulo(curr_pos) 
DEFINE curr_pos 		SMALLINT

	IF r_detalle[curr_pos].r22_precio IS NULL OR 
	   r_detalle[curr_pos].r22_cantidad IS NULL
	THEN
		RETURN 1
	END IF
	RETURN 0
	
END FUNCTION



FUNCTION calcular_totales_detalle_proforma(curr_pos)
DEFINE curr_pos		SMALLINT

	LET r_detalle[curr_pos].subtotal_item = r_detalle[curr_pos].r22_precio *  
											r_detalle[curr_pos].r22_cantidad

	LET vm_subtotal = vm_subtotal + r_detalle[curr_pos].subtotal_item 
END FUNCTION



FUNCTION calcular_precio_item_cliente(curr_pos)
DEFINE curr_pos			SMALLINT
DEFINE recargo			DECIMAL(5,2)

	LET recargo = r_detalle_2[curr_pos].r113_recargo_clte +
				  r_detalle_2[curr_pos].r113_recargo_item

	RETURN (r_detalle_2[curr_pos].r113_precio_lista * (1 + (recargo / 100)))
END FUNCTION



FUNCTION calcula_muestra_totales_factura()

LET vm_impuesto = (vm_subtotal - vm_descuento - vm_val_dscto2) * 
			       rm_r21.r21_porc_impto / 100 
LET vm_impuesto = fl_retorna_precision_valor(rm_r21.r21_moneda, vm_impuesto)   

LET vm_total = vm_subtotal - vm_descuento - vm_val_dscto2 + vm_impuesto 
LET rm_r21.r21_tot_costo = vm_costo
LET rm_r21.r21_tot_bruto = vm_subtotal
LET rm_r21.r21_tot_dscto = vm_descuento
LET rm_r21.r21_tot_neto  = vm_total
DISPLAY BY NAME rm_r21.r21_tot_bruto, rm_r21.r21_tot_dscto, 
				rm_r21.r21_descuento, vm_val_dscto2, vm_impuesto, 
				rm_r21.r21_tot_neto, vm_tot_peso

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(600)
DEFINE expr_sql_2	VARCHAR(600)
DEFINE query		VARCHAR(600)
DEFINE r_r21		RECORD LIKE rept021.* 	-- CABECERA PROFORMA

INITIALIZE expr_sql_2 TO NULL
CLEAR FORM
CALL control_display_botones()

LET INT_FLAG = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON r21_numprof,  r21_moneda,   r21_bodega, r21_grupo_linea, 
		     r21_codcli,   r21_nomcli,   r21_cedruc, r21_dircli, 
		     r21_telcli,   r21_vendedor, r21_usuario  
	ON KEY(F2)
		IF INFIELD(r21_numprof) THEN
			CALL fl_ayuda_proformas_rep(vg_codcia, vg_codloc)
				RETURNING r_r21.r21_numprof, r_r21.r21_nomcli
			IF r_r21.r21_numprof IS NOT NULL THEN
				CALL fl_lee_proforma_rep(vg_codcia, vg_codloc,
							 r_r21.r21_numprof)
					RETURNING rm_r21.*
				LET vm_fecha  = DATE(rm_r21.r21_fecing)
				DISPLAY BY NAME rm_r21.r21_numprof,
						rm_r21.r21_moneda,
						rm_r21.r21_moneda,
						rm_r21.r21_bodega,
						rm_r21.r21_grupo_linea,
						rm_r21.r21_codcli,
						rm_r21.r21_nomcli,
						rm_r21.r21_dircli,
						rm_r21.r21_cedruc,
						rm_r21.r21_vendedor,
						rm_r21.r21_porc_impto,
						vm_fecha
			END IF
		END IF
		IF INFIELD(r21_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_r21.r21_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_r21.r21_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
		      	END IF
		END IF
		IF INFIELD(r21_bodega) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T')
		     	RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     IF rm_r02.r02_codigo IS NOT NULL THEN
			    LET rm_r21.r21_bodega = rm_r02.r02_codigo
			    DISPLAY BY NAME rm_r21.r21_bodega
			    DISPLAY rm_r02.r02_nombre TO nom_bodega
		     END IF
		END IF
	
		IF INFIELD(r21_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
				LET rm_r21.r21_vendedor = rm_r01.r01_codigo	
				DISPLAY BY NAME rm_r21.r21_vendedor
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r21_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
					IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r21.r21_codcli = rm_c02.z02_codcli
				LET rm_r21.r21_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r21.r21_codcli,
						rm_r21.r21_nomcli
			END IF 
		END IF
		LET int_flag = 0
		AFTER CONSTRUCT
			IF rm_r21.r21_codcli IS NOT NULL THEN
				INITIALIZE rm_r21.r21_nomcli TO NULL
				DISPLAY BY NAME rm_r21.r21_nomcli
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
	LET expr_sql = 'r21_numprof = ',vg_numprev 
END IF

IF expr_sql_2 IS NOT NULL THEN
	LET expr_sql = expr_sql || ' AND ' || expr_sql_2
END IF

LET query = 'SELECT *, ROWID FROM rept021 
		WHERE r21_compania  = ', vg_codcia,
		' AND r21_localidad = ', vg_codloc,
		' AND ', expr_sql CLIPPED,
		' ORDER BY 3 DESC, 4' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r21.*, vm_rows[vm_num_rows]
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
SELECT * INTO rm_r21.* FROM rept021 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
LET vm_impuesto = rm_r21.r21_tot_neto -
		  (rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto)
LET vm_fecha  = DATE(rm_r21.r21_fecing)

{* xxx
 * Durante la ejecucion del programa r21_descuento debe tener el
 * valor de la suma de los dsctos de las lineas.
 * De hecho, lo correcto es crear otro campo en la 21 para eso o eliminar
 * de una vez la dependencia de campos calculados.
 *}
SELECT SUM(r22_val_descto) INTO rm_r21.r21_tot_dscto FROM rept022
 WHERE r22_compania  = vg_codcia
   AND r22_localidad = vg_codloc
   AND r22_numprof = rm_r21.r21_numprof

LET vm_val_dscto2 = (rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto) * 
					 rm_r21.r21_descuento / 100
	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r21.r21_numprof, rm_r21.r21_vendedor, rm_r21.r21_tot_neto,  
		vm_fecha,           rm_r21.r21_moneda,   rm_r21.r21_porc_impto,
		rm_r21.r21_codcli,  rm_r21.r21_nomcli,   rm_r21.r21_dircli,
		rm_r21.r21_cedruc,  rm_r21.r21_descuento, vm_val_dscto2, 
		rm_r21.r21_dias_prof,  rm_r21.r21_grupo_linea, 
		rm_r21.r21_tot_bruto,  rm_r21.r21_telcli,
		rm_r21.r21_tot_dscto,  vm_impuesto,       
		rm_r21.r21_bodega,     rm_r21.r21_usuario, 
		rm_r21.r21_referencia, rm_r21.r21_modelo,
		rm_r21.r21_forma_pago, rm_r21.r21_atencion    
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

DISPLAY BY NAME vm_tot_peso

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i 		SMALLINT
DEFINE r_r22		RECORD LIKE rept022.*
DEFINE peso 		LIKE rept010.r10_peso

FOR i = 1 TO 500
	INITIALIZE r_detalle_1[i].* TO NULL
	INITIALIZE r_detalle_2[i].* TO NULL
END FOR

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle.* TO NULL
	INITIALIZE r_detalle_1.* TO NULL
	CLEAR r_detalle[i].*
END FOR

DECLARE  q_rept022 CURSOR FOR 
	SELECT rept022.*, rept010.r10_peso, NVL(r113_precio_lista, 0),
		   NVL(r113_dscto_clte, 0), NVL(r113_recargo_clte, 0),
           NVL(r113_dscto_item, 0), NVL(r113_recargo_item, 0)
		 FROM rept022, rept010, OUTER rept113 
            	WHERE r22_compania   = vg_codcia 
				  AND r22_localidad  = vg_codloc
            	  AND r22_numprof    = rm_r21.r21_numprof
            	  AND r10_compania   = r22_compania
            	  AND r10_codigo     = r22_item
				  AND r113_compania  = r22_compania
				  AND r113_localidad = r22_localidad
				  AND r113_numprof   = r22_numprof
				  AND r113_orden     = r22_orden  
				  AND r113_item      = r22_item
		ORDER BY r22_orden

LET vm_tot_peso = 0

LET i = 1
FOREACH q_rept022 INTO r_r22.*, peso, r_detalle_2[i].*
	LET r_detalle[i].r22_cantidad    = r_r22.r22_cantidad
	LET r_detalle[i].r22_item        = r_r22.r22_item
	LET r_detalle[i].r22_dias_ent    = r_r22.r22_dias_ent
	LET r_detalle_1[i].r22_porc_descto = r_r22.r22_porc_descto
	LET r_detalle[i].r22_precio      = r_r22.r22_precio
	LET r_detalle[i].subtotal_item   = r_r22.r22_precio * r_r22.r22_cantidad

	LET r_detalle_1[i].r22_item_ant    = r_r22.r22_item_ant
	LET r_detalle_1[i].r22_descripcion = r_r22.r22_descripcion
	LET r_detalle[i].r10_nombre 	   = r_r22.r22_descripcion
	LET r_detalle_1[i].r22_linea       = r_r22.r22_linea
	LET r_detalle_1[i].r22_rotacion    = r_r22.r22_rotacion
	LET r_detalle_1[i].r22_costo       = r_r22.r22_costo
	LET r_detalle_1[i].r22_val_descto  = r_r22.r22_val_descto
	LET r_detalle_1[i].r22_val_impto   = r_r22.r22_val_impto
	LET r_detalle_1[i].val_costo       = r_r22.r22_costo * r_r22.r22_cantidad
	LET r_detalle_1[i].peso			   = peso

	LET vm_tot_peso = vm_tot_peso + r_r22.r22_cantidad * peso 

	LET i = i + 1
        IF i >= 500 THEN
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

IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF

FOR i = 1 TO vm_filas_pant 
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "                                      " AT 1,1
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

CALL fl_lee_grupo_linea(vg_codcia,  rm_r21.r21_grupo_linea) RETURNING rm_g20.*
DISPLAY rm_g20.g20_nombre TO nom_grupo

CALL fl_lee_moneda(rm_r21.r21_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_moneda

CALL fl_lee_bodega_rep(vg_codcia, rm_r21.r21_bodega) RETURNING rm_r02.*
DISPLAY rm_r02.r02_nombre TO nom_bodega

CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor) RETURNING rm_r01.*
DISPLAY rm_r01.r01_nombres TO nom_vendedor

END FUNCTION



FUNCTION proceso_sustitucion(item, arr_scr_curr, arr_prog_curr, arr_prog_max)

DEFINE r22_cantidad	LIKE rept022.r22_cantidad
DEFINE item		LIKE rept010.r10_codigo
DEFINE item_ant		LIKE rept010.r10_codigo
DEFINE stock 		LIKE rept011.r11_stock_act
DEFINE cant  		SMALLINT
DEFINE porc_descto	LIKE rept022.r22_porc_descto
DEFINE arr_scr_curr	SMALLINT
DEFINE arr_prog_curr	SMALLINT
DEFINE arr_prog_max	SMALLINT
DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r14		RECORD LIKE rept014.*

SELECT COUNT(*) INTO cant FROM rept014 
	WHERE r14_compania = vg_codcia
	  AND r14_item_ant = item             

CALL addRows((arr_prog_curr + 1), arr_prog_max, (cant - 1))
FOR i = arr_prog_max TO (arr_prog_curr + 1) STEP -1
	LET r_detalle[i+(cant-1)].*   = r_detalle[i].*    
END FOR

DECLARE q_sust CURSOR FOR 
	SELECT * FROM rept014 
		WHERE r14_compania = vg_codcia 
		  AND r14_item_ant = item

LET r22_cantidad = r_detalle[arr_prog_curr].r22_cantidad
LET porc_descto  = r_detalle_1[arr_prog_curr].r22_porc_descto
IF r_detalle_1[arr_prog_curr].r22_item_ant IS NULL THEN
	LET item_ant = item
ELSE
	LET item_ant = r_detalle_1[arr_prog_curr].r22_item_ant
END IF

OPEN q_sust
FOR i = 0 TO (cant - 1)
	LET j = arr_prog_curr + i
	INITIALIZE r_r14.* TO NULL
	FETCH q_sust INTO r_r14.*
	INITIALIZE r_detalle[j].*, r_detalle_1[j].* TO NULL
	LET r_detalle[j].r22_cantidad = r22_cantidad * r_r14.r14_cantidad 
	LET r_detalle_1[j].r22_item_ant = item_ant

	CALL fl_lee_item(vg_codcia, r_r14.r14_item_nue) RETURNING r_r10.*
	CALL datos_proforma(r_r10.*, j)
	CALL obtener_descuento_item(r_r10.r10_codigo, j) 
		RETURNING r_detalle_1[j].r22_porc_descto, r_detalle_1[j].r22_val_descto 

	--- PARA CONOCER LOS DIAS DE ENTREGA DEL ITEM ---
	{*
	 * Se calcula un valor de recargo para el item segun el factor
	 * indicado en el record rm_tipinv, dependiendo de si el item 
	 * esta en stock o se va a importar 
	 *}
	CALL fl_lee_stock_disponible_rep(vg_codcia, vg_codloc, r_detalle[j].r22_item, 'R') 
			RETURNING stock 
	IF stock < 0 THEN
		LET stock = 0
	END IF
	IF stock >= r_detalle[j].r22_cantidad THEN
		LET r_detalle[j].r22_dias_ent = rm_tipinv.sto_codigo
	ELSE
		LET r_detalle[j].r22_dias_ent = rm_tipinv.imp_codigo
	END IF
	----------------------------------------------------------
	CALL llena_arreglo_detalle(j, j)
	
	IF (arr_scr_curr + i) <= vm_filas_pant THEN 
		DISPLAY r_detalle[arr_prog_curr + i].* TO r_detalle[arr_scr_curr + i].*
	END IF
END FOR
CLOSE q_sust
FREE  q_sust

LET i = i - 1

RETURN (arr_prog_max + i)

END FUNCTION



FUNCTION deleteRow(i, num_rows)
                                                                                
DEFINE i                SMALLINT
DEFINE num_rows         SMALLINT
                                                                                
WHILE (i < num_rows)
        LET r_detalle_1[i].* = r_detalle_1[i + 1].*
        LET r_detalle_2[i].* = r_detalle_2[i + 1].*
        LET i = i + 1
END WHILE
INITIALIZE r_detalle_1[i].* TO NULL
INITIALIZE r_detalle_2[i].* TO NULL
                                                                                
END FUNCTION
                                                                                

-- Funcion que añade N filas en un arreglo 
-- curr_row posicion aactual en el arreglo
-- num_rows numero actual de filas en el arreglo
-- added_rows numero de filas que se van a aumentar
FUNCTION addRows(curr_row, num_rows, added_rows)
DEFINE i                SMALLINT
DEFINE curr_row         SMALLINT
DEFINE num_rows         SMALLINT
DEFINE added_rows       SMALLINT

FOR i = num_rows TO curr_row STEP -1
display i, added_rows, r_detalle_1[i+added_rows].*, r_detalle_2[i+added_rows].*
	LET r_detalle_1[i + added_rows].* = r_detalle_1[i].* 	
	LET r_detalle_2[i + added_rows].* = r_detalle_2[i].* 	
END FOR

END FUNCTION



-- Funcion que llena los datos que pueden variar del arreglo r_detalle_1
-- ant_pos indice que hace referencia a la posicion anterior de la fila
-- se usa para hacer referencia al item en el arreglo r_detalle
-- new_pos nueva posicion de la fila
FUNCTION llena_arreglo_detalle(ant_pos, new_pos)

DEFINE ant_pos      	SMALLINT
DEFINE new_pos      	SMALLINT
DEFINE bruto		DECIMAL(12,2)

DEFINE r_r10		RECORD LIKE rept010.*

CALL fl_lee_item(vg_codcia, r_detalle[ant_pos].r22_item) RETURNING r_r10.* 

CALL datos_proforma(r_r10.*, new_pos)
CALL obtener_descuento_item(r_r10.r10_codigo, new_pos) 
	RETURNING r_detalle_1[new_pos].r22_porc_descto, 
			  r_detalle_1[new_pos].r22_val_descto 

LET bruto = (r_detalle[ant_pos].r22_cantidad * r_detalle[ant_pos].r22_precio) -
		     r_detalle_1[new_pos].r22_val_descto
LET r_detalle_1[new_pos].r22_val_impto = 
				((bruto - r_detalle_1[new_pos].r22_val_descto) * 
				rm_r21.r21_porc_impto) / 100

END FUNCTION



FUNCTION ingresa_descuento2()

INPUT BY NAME rm_r21.r21_descuento, vm_val_dscto2 WITHOUT DEFAULTS
	AFTER FIELD r21_descuento
		LET vm_val_dscto2 = (rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto) *
							rm_r21.r21_descuento / 100
		CALL calcula_muestra_totales_factura()
	AFTER FIELD vm_val_dscto2
		LET rm_r21.r21_descuento = vm_val_dscto2 * 100 / 
								(rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto)
		CALL calcula_muestra_totales_factura()
	AFTER INPUT
		CALL calcula_muestra_totales_factura()
		IF rentabilidad_factura_no_permitida(vm_num_detalles) THEN
			CALL fgl_winmessage(vg_producto, 'El valor de la factura esta por debajo de la rentabilidad mínima.', 'stop')
--			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION calcular_rentabilidad_minima_detalle_factura(curr_pos)
DEFINE curr_pos			INTEGER
DEFINE r_r03			RECORD LIKE rept003.*

	IF fl_tipo_cliente_venta_costo_fob(rm_c01.z01_tipo_clte) THEN
		-- El precio debe tener el pvp, el costo o el fob segun sea el 
		-- tipo de cliente
		RETURN r_detalle[curr_pos].r22_precio
	END IF

	CALL fl_lee_linea_rep(vg_codcia, r_detalle_1[curr_pos].r22_linea) 
		RETURNING r_r03.*
	RETURN (r_detalle_1[curr_pos].r22_costo * (1 + r_r03.r03_rentab_min / 100))
END FUNCTION



FUNCTION calcular_rentabilidad_minima_factura(num_elm)
DEFINE num_elm			SMALLINT
DEFINE i				SMALLINT
DEFINE valor_min		LIKE rept010.r10_costo_mb

	LET valor_min = 0
	FOR i = 1 TO num_elm
		LET valor_min = valor_min + 
			(calcular_rentabilidad_minima_detalle_factura(i) *
			 r_detalle[i].r22_cantidad)
	END FOR

	RETURN valor_min
END FUNCTION



FUNCTION rentabilidad_factura_no_permitida(num_elm) 
DEFINE num_elm			SMALLINT
DEFINE valor_min 		LIKE rept010.r10_costo_mb

	CALL calcular_rentabilidad_minima_factura(num_elm) RETURNING valor_min
	IF (rm_r21.r21_tot_bruto - vm_descuento - vm_val_dscto2) < valor_min THEN
		RETURN TRUE
	END IF
	RETURN FALSE
END FUNCTION



FUNCTION mostrar_lineas_actuales(curr_pos, num_elm, ind_pant, num_elm_pant)
DEFINE curr_pos		SMALLINT
DEFINE num_elm		SMALLINT
DEFINE ind_pant		SMALLINT
DEFINE num_elm_pant	SMALLINT

DEFINE i			SMALLINT -- indice en el arreglo del programa
DEFINE j			SMALLINT -- indice en el arreglo de la pantalla

	LET i = curr_pos - ind_pant 

	FOR j = 1 TO num_elm_pant 
		IF i + j > num_elm THEN
			EXIT FOR
		END IF
		DISPLAY r_detalle[i+j].* TO r_detalle[j].*
	END FOR
END FUNCTION



FUNCTION inicializar_factores_importacion_stock()
DEFINE r_r114		RECORD LIKE rept114.*

	CALL fl_lee_factor_importacion_stock_rep_predeterminado(vg_codcia, 'STO') 
		RETURNING r_r114.* 
	LET rm_tipinv.sto_codigo     = r_r114.r114_codigo
	LET rm_tipinv.sto_factor     = r_r114.r114_factor
	LET rm_tipinv.sto_flag_ident = r_r114.r114_flag_ident

	CALL fl_lee_factor_importacion_stock_rep_predeterminado(vg_codcia, 'IMP') 
		RETURNING r_r114.* 
	LET rm_tipinv.imp_codigo     = r_r114.r114_codigo
	LET rm_tipinv.imp_factor     = r_r114.r114_factor
	LET rm_tipinv.imp_flag_ident = r_r114.r114_flag_ident
END FUNCTION



FUNCTION proforma_expiro()
	IF DATE(rm_r21.r21_fecing) + rm_r00.r00_dias_prof < TODAY AND 
	   DATE(rm_r21.r21_fecing) + rm_r21.r21_dias_prof < TODAY 
	THEN
		RETURN 1
	END IF
	RETURN 0
END FUNCTION



FUNCTION recalcular()
DEFINE i		SMALLINT
DEFINE stock	LIKE rept011.r11_stock_act
DEFINE r_r10	RECORD LIKE rept010.*

	FOR i = 1 TO vm_ind_arr 
		CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item) RETURNING r_r10.*
		CALL datos_proforma(r_r10.*, i)
		CALL obtener_descuento_item(r_r10.r10_codigo, i) 
			RETURNING r_detalle_1[i].r22_porc_descto, 
					  r_detalle_1[i].r22_val_descto 

		--- PARA CONOCER LOS DIAS DE ENTREGA DEL ITEM ---
		{*
		 * Se calcula un valor de recargo para el item segun el factor
		 * indicado en el record rm_tipinv, dependiendo de si el item 
		 * esta en stock o se va a importar 
		 *}
		CALL fl_lee_stock_disponible_rep(vg_codcia, vg_codloc, 
										 r_detalle[i].r22_item, 'R') 
				RETURNING stock 
		IF stock < 0 THEN
			LET stock = 0
		END IF
		IF stock >= r_detalle[i].r22_cantidad THEN
			LET r_detalle[i].r22_dias_ent = rm_tipinv.sto_codigo
		ELSE
			LET r_detalle[i].r22_dias_ent = rm_tipinv.imp_codigo
		END IF
	END	FOR
	CALL calcula_totales(vm_ind_arr)

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

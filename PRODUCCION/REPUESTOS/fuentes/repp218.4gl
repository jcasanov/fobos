{*
 * Titulo           : repp218.4gl - Devolución de compras locales  
 * Elaboracion      : 14-nov-2001
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp218 base modulo compania localidad
 *			Si se reciben 4 parametros se está ejecutando en 
 *			modo independiente
 *			Si se reciben 6 parametros, se asume que el quinto es
 * 			el codigo de la compra local (transaccion origen)
 *			y el sexto parametro es el numero de la compra local
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_transaccion   LIKE rept019.r19_cod_tran
DEFINE vm_dev_tran      LIKE rept019.r19_cod_tran
DEFINE vm_nota_credito  LIKE rept019.r19_cod_tran
DEFINE vm_factura	LIKE rept019.r19_cod_tran

DEFINE vm_num_tran	LIKE rept019.r19_num_tran

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_r19		RECORD LIKE rept019.* 

DEFINE vm_indice	SMALLINT
DEFINE vm_max_ventas	SMALLINT
DEFINE rm_compra ARRAY[100] OF RECORD
	cant_dev		LIKE rept020.r20_cant_ped, 
	cant_ven		LIKE rept020.r20_cant_ven, 
	item			LIKE rept020.r20_item, 
	descuento		LIKE rept020.r20_descuento,
	precio			LIKE rept020.r20_precio, 
	total			LIKE rept019.r19_tot_bruto
END RECORD

DEFINE rm_datos ARRAY[100] OF RECORD
	item  	 		LIKE rept010.r10_nombre,
	costo			LIKE rept020.r20_costo,		-- COSTO ITEM
	val_dscto		LIKE rept020.r20_val_descto,
	stock_ant		LIKE rept020.r20_stock_ant
END RECORD

-- Registro de la tabla de configuración del módulo de repuestos
DEFINE rm_r00			RECORD LIKE rept000.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp218.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp218'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
			        -- que luego puede ser reemplazado si se 
                            	-- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

INITIALIZE vm_dev_tran TO NULL
LET vm_num_tran = 0
IF num_args() = 6 THEN
	LET vm_dev_tran = arg_val(5)
	LET vm_num_tran = arg_val(6)
END IF

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
OPEN WINDOW w_218 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_218 FROM '../forms/repf218_1'
DISPLAY FORM f_218

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r19.* TO NULL

CALL muestra_contadores()
CALL setea_nombre_botones()

LET vm_max_rows   = 1000
LET vm_max_ventas = 100


CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe registro de configuración para esta compañía.',
		'exclamation')
	EXIT PROGRAM
END IF

-- OjO
LET vm_dev_tran     = 'CL'       
LET vm_nota_credito = 'NC'
LET vm_factura      = 'FA'

INITIALIZE vm_transaccion TO NULL
SELECT g21_codigo_dev INTO vm_transaccion FROM gent021 
	WHERE g21_cod_tran = vm_dev_tran   
IF vm_transaccion IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha configurado un código de devolución para ' ||
		'este tipo de transacciones.',
		'stop')
	EXIT PROGRAM
END IF
--

IF num_args() = 6 THEN
	CALL consultar_devoluciones()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'		
		IF vm_num_tran <> 0 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			IF vm_num_rows > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
			SHOW OPTION 'Detalle'
                	SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
                IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('D') 'Detalle'		'Ver detalle de devolución.'
		CALL control_mostrar_det()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Imprimir'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Imprimir'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF vm_num_rows > 0 THEN
                	SHOW OPTION 'Imprimir'
                END IF
        COMMAND KEY('P') 'Imprimir'		'Imprime la compra local.'
        	CALL imprimir()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g21		RECORD LIKE gent021.*

DEFINE i 		SMALLINT
DEFINE rowid   		SMALLINT
DEFINE done		SMALLINT

DEFINE valor_aplicado	DECIMAL(14,2)

CLEAR FORM
INITIALIZE rm_r19.* TO NULL

-- THESE VALUES WON'T CHANGE 
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
LET rm_r19.r19_cod_tran   = vm_transaccion
LET rm_r19.r19_tipo_dev   = vm_dev_tran      
LET rm_r19.r19_flete      = 0
LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_fecing     = CURRENT

CALL fl_lee_cod_transaccion(vm_transaccion) RETURNING r_g21.*
LET rm_r19.r19_tipo_tran  = r_g21.g21_tipo
LET rm_r19.r19_calc_costo = r_g21.g21_calc_costo

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL setea_nombre_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

CALL ingresa_detalle()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL setea_nombre_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET done = 0
FOR i = 1 TO vm_indice
	IF rm_compra[i].cant_dev > 0 THEN
		LET done = 1
		EXIT FOR
	END IF
END FOR

IF NOT done THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL setea_nombre_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK
	
LET rm_r19.r19_bodega_dest = rm_r19.r19_bodega_ori

LET rm_r19.r19_num_tran = nextValInSequence(vg_modulo, rm_r19.r19_cod_tran)
IF rm_r19.r19_num_tran  = -1 THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL setea_nombre_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

INSERT INTO rept019 VALUES (rm_r19.*)
DISPLAY BY NAME rm_r19.r19_num_tran

LET rowid = SQLCA.SQLERRD[6] 		 -- Rowid de la ultima fila 
                                         -- procesada
LET done = graba_detalle()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET done = actualiza_transaccion()
IF NOT done THEN
	ROLLBACK WORK
   	IF vm_num_rows = 0 THEN
	    	CLEAR FORM
    		CALL muestra_contadores()
    	ELSE	
	    	CALL lee_muestra_registro(vm_rows[vm_row_current])
    	END IF
	RETURN
END IF

LET done = actualiza_orden()
IF NOT done THEN
	ROLLBACK WORK
   	IF vm_num_rows = 0 THEN
	    	CLEAR FORM
    		CALL muestra_contadores()
    	ELSE	
	    	CALL lee_muestra_registro(vm_rows[vm_row_current])
    	END IF
	RETURN
END IF

IF rm_r19.r19_cont_cred = 'R' THEN
	LET valor_aplicado = rebaja_deuda()
	IF valor_aplicado < 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
END IF

LET done = elimina_retenciones()
IF NOT done THEN
	ROLLBACK WORK
   	IF vm_num_rows = 0 THEN
	    	CLEAR FORM
    		CALL muestra_contadores()
    	ELSE	
	    	CALL lee_muestra_registro(vm_rows[vm_row_current])
    	END IF
	RETURN
END IF
	
COMMIT WORK
CALL fl_control_master_contab_repuestos(rm_r19.r19_compania, 
	rm_r19.r19_localidad, rm_r19.r19_cod_tran, rm_r19.r19_num_tran)

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_rows[vm_num_rows] = rowid
LET vm_row_current = vm_num_rows

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos()

DEFINE resp 		CHAR(6)

DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_c10		RECORD LIKE ordt010.*

LET INT_FLAG = 0
INPUT BY NAME rm_r19.r19_cod_tran, rm_r19.r19_tipo_dev, rm_r19.r19_num_dev, 
	      rm_r19.r19_usuario, rm_r19.r19_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_r19.r19_tipo_dev, rm_r19.r19_num_dev) 
		THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(r19_num_dev) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,    
				vm_dev_tran) RETURNING r_r19.r19_tipo_dev,
				          	       r_r19.r19_num_dev,
				   	  	       r_r19.r19_nomcli
		     	IF r_r19.r19_tipo_dev IS NOT NULL THEN
				LET rm_r19.r19_tipo_dev = r_r19.r19_tipo_dev
				LET rm_r19.r19_num_dev  = r_r19.r19_num_dev
				LET rm_r19.r19_nomcli   = r_r19.r19_nomcli  
				DISPLAY BY NAME rm_r19.r19_tipo_dev, 
						rm_r19.r19_num_dev
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_nombre_botones()
	AFTER FIELD r19_num_dev
		IF rm_r19.r19_num_dev IS NULL THEN
			INITIALIZE r_r19.* TO NULL
			CALL muestra_etiquetas(r_r19.*)
			CONTINUE INPUT
		END IF
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
			rm_r19.r19_tipo_dev, rm_r19.r19_num_dev)
			RETURNING r_r19.*
		IF r_r19.r19_oc_interna IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'La transacción no está asociada a una ' ||
				'orden de compra.',
				'exclamation')
			INITIALIZE r_r19.* TO NULL 
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		IF TODAY > (date(r_r19.r19_fecing) + rm_r00.r00_dias_dev) THEN
			CALL fgl_winmessage(vg_producto,
				'Ha excedido el limite de tiempo permitido ' ||
				'para realizar devoluciones.',
				'exclamation')
			INITIALIZE r_r19.* TO NULL 
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		IF rm_r00.r00_dev_mes = 'S' THEN
			IF month(r_r19.r19_fecing) <> month(TODAY) THEN
				CALL fgl_winmessage(vg_producto,
					'La devolución debe realizarse ' ||
					'en el mismo mes en que se realizó ' ||
					'la venta.',
					'exclamation')
				INITIALIZE r_r19.* TO NULL 
				CALL muestra_etiquetas(r_r19.*)
				NEXT FIELD r19_num_dev
			END IF
		END IF
		-- Valida si los items recibidos han sido afectados por 
		-- alguna transacción
		IF items_alterados(r_r19.*) THEN
			CALL fgl_winquestion(vg_producto,
				'Algunos items de esta compra local ' ||
				'han sido afectados por otra transacción. ' ||
				'¿Esta seguro que quiere realizar la devolución?.',
				'No', 'Yes|No|Cancel', 'question', 1) RETURNING resp 
			IF resp <> 'Yes' THEN
				INITIALIZE r_r19.* TO NULL
				CALL muestra_etiquetas(r_r19.*)
				NEXT FIELD r19_num_dev
			END IF
		END IF
		CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
			r_r19.r19_oc_interna) RETURNING r_c10.*
		IF r_c10.c10_numero_oc IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Orden de compra no existe.',
				'exclamation')
			INITIALIZE r_r19.* TO NULL
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		LET rm_r19.r19_tipo_dev    = vm_dev_tran
		LET rm_r19.r19_cont_cred   = r_r19.r19_cont_cred
		LET rm_r19.r19_descuento   = r_r19.r19_descuento
		LET rm_r19.r19_porc_impto  = r_r19.r19_porc_impto
		LET rm_r19.r19_oc_interna  = r_r19.r19_oc_interna 
		LET rm_r19.r19_oc_externa  = r_r19.r19_oc_externa
		LET rm_r19.r19_fact_venta  = r_r19.r19_fact_venta
		LET rm_r19.r19_moneda      = r_r19.r19_moneda
		LET rm_r19.r19_paridad     = r_r19.r19_paridad
		LET rm_r19.r19_precision   = r_r19.r19_precision
		LET rm_r19.r19_codcli      = r_r19.r19_codcli
		LET rm_r19.r19_nomcli      = r_r19.r19_nomcli
		LET rm_r19.r19_dircli      = r_r19.r19_dircli    
		LET rm_r19.r19_cedruc      = r_r19.r19_cedruc     
		LET rm_r19.r19_telcli      = r_r19.r19_telcli     
		LET rm_r19.r19_vendedor    = r_r19.r19_vendedor
		LET rm_r19.r19_bodega_ori  = r_r19.r19_bodega_ori
		CALL muestra_etiquetas(rm_r19.*)
END INPUT

END FUNCTION



FUNCTION ingresa_detalle()

DEFINE resp 		CHAR(6)
DEFINE i    		SMALLINT
DEFINE j    		SMALLINT
DEFINE salir		SMALLINT

DEFINE flag		SMALLINT

LET INT_FLAG = 0
LET vm_indice = lee_detalle_tran_ori()
IF INT_FLAG THEN
	RETURN
END IF

LET flag = 0
FOR i = 1 TO vm_indice
	IF rm_compra[i].cant_ven > 0 THEN
		LET flag = 1
	END IF 	
END FOR

IF NOT flag THEN
	CALL fgl_winmessage(vg_producto, 
		'Esta compra local ya ha sido devuelta por completo.',
		'exclamation')
	LET INT_FLAG = 1
	RETURN
END IF

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31

LET salir = 0
WHILE NOT salir
	LET i = 1
	LET j = 1
	LET INT_FLAG = 0
	CALL set_count(vm_indice)
	INPUT ARRAY rm_compra WITHOUT DEFAULTS FROM ra_compra.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
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
			DISPLAY rm_datos[i].item TO descripcion
		AFTER FIELD r20_cant_dev
			IF rm_compra[i].cant_dev IS NULL THEN
				CALL calcula_totales(vm_indice) 
				NEXT FIELD r20_cant_dev
			END IF
			IF rm_compra[i].cant_dev > rm_compra[i].cant_ven THEN
				CALL fgl_winmessage(vg_producto,
					'La cantidad a devolver debe ser ' ||
					'menor o igual a la cantidad ' ||
					'despachada.',
					'exclamation')
				NEXT FIELD r20_cant_dev
			END IF
		-------------------------------------------------------------
			LET rm_compra[i].total = 
				rm_compra[i].cant_dev * rm_compra[i].precio
			LET rm_datos[i].val_dscto =
			       rm_compra[i].total * (rm_compra[i].descuento/100)
			CALL calcula_totales(vm_indice) 
			DISPLAY rm_compra[i].* TO ra_compra[j].*
			DISPLAY rm_datos[i].item TO descripcion
		BEFORE DELETE
			EXIT INPUT
		BEFORE INSERT
			EXIT INPUT
		AFTER INPUT
-- OjO
-- validacion para evitar problemas en presentaciones
-- sera eliminada en cuanto se manejen las
-- devoluciones parciales
		for i = 1 to arr_count()
			if rm_compra[i].cant_dev <> rm_compra[i].cant_ven then
				call fgl_winmessage(vg_producto,
					'Deben devolverse todos los ' ||
					'items.',
					'exclamation') 
				continue input	
			end if
		end for
--
			LET salir = 1
	END INPUT

	IF INT_FLAG THEN
		RETURN
	END IF
END WHILE

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_c10		RECORD LIKE ordt010.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON r19_num_tran, r19_num_dev, r19_oc_interna, r19_oc_externa, 
	   r19_fact_venta, r19_bodega_ori, r19_usuario
	ON KEY(F2)
		IF INFIELD(r19_num_dev) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,    
				vm_dev_tran) RETURNING r_r19.r19_tipo_dev,
				          	       r_r19.r19_num_dev,
				   	  	       r_r19.r19_nomcli
		     	IF r_r19.r19_tipo_dev IS NOT NULL THEN
				LET rm_r19.r19_tipo_dev = r_r19.r19_tipo_dev
				LET rm_r19.r19_num_dev  = r_r19.r19_num_dev
				LET rm_r19.r19_nomcli   = r_r19.r19_nomcli  
				DISPLAY BY NAME rm_r19.r19_tipo_dev, 
						rm_r19.r19_num_dev
			END IF
		END IF
		IF INFIELD(r19_oc_interna) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc, 
				0, 0, 'T', vg_modulo, 'S')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				LET rm_r19.r19_oc_interna = r_c10.c10_numero_oc
				DISPLAY BY NAME rm_r19.r19_oc_interna
			END IF
		END IF
		IF INFIELD(r19_bodega_ori) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T')
		     		RETURNING r_r02.r02_codigo, 
					  r_r02.r02_nombre
		     	IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r19.r19_bodega_ori = r_r02.r02_codigo
				DISPLAY BY NAME rm_r19.r19_bodega_ori
				DISPLAY r_r02.r02_nombre TO n_bodega
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE CONSTRUCT
		CALL setea_nombre_botones()
	AFTER FIELD r19_bodega_ori
		IF rm_r19.r19_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CLEAR n_bodega
			END IF 
			IF r_r02.r02_estado = 'B' THEN
				CLEAR n_bodega
			END IF
			DISPLAY r_r02.r02_nombre TO n_bodega
		ELSE
			CLEAR n_bodega
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM rept019 ',
	    'WHERE r19_compania  = ', vg_codcia, 
	    '  AND r19_localidad = ', vg_codloc,
	    '  AND r19_cod_tran = "', vm_transaccion, '" ',
	    '  AND r19_tipo_dev = "', vm_dev_tran, '" ',
	    '  AND ', expr_sql CLIPPED,
	    'ORDER BY 1, 2, 3, 4' 

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
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

DEFINE iva		LIKE rept019.r19_tot_dscto

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_r19.* FROM rept019 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET iva = (rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto) * 
	  (rm_r19.r19_porc_impto / 100)

DISPLAY BY NAME rm_r19.r19_cod_tran,   
                rm_r19.r19_num_tran,   
		rm_r19.r19_tipo_dev,
		rm_r19.r19_num_dev,
		rm_r19.r19_oc_interna,
		rm_r19.r19_oc_externa,
		rm_r19.r19_vendedor,
		rm_r19.r19_bodega_ori,
		rm_r19.r19_moneda,    
		rm_r19.r19_tot_bruto,
		rm_r19.r19_tot_dscto,
		iva,
		rm_r19.r19_tot_neto, 
		rm_r19.r19_usuario,
		rm_r19.r19_fecing

CALL muestra_etiquetas(rm_r19.*)
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

LET filas_pant = fgl_scr_size('ra_compra')

FOR i = 1 TO filas_pant 
	INITIALIZE rm_compra[i].* TO NULL
	CLEAR ra_compra[i].*
END FOR

LET i = lee_detalle_dev()
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

LET vm_indice = i

IF vm_indice < filas_pant THEN
	LET filas_pant = vm_indice
END IF

FOR i = 1 TO filas_pant   
	DISPLAY rm_compra[i].* TO ra_compra[i].*
END FOR
DISPLAY rm_datos[1].item TO descripcion

END FUNCTION



FUNCTION lee_detalle_tran_ori()

DEFINE i		SMALLINT
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*

DECLARE q_det CURSOR FOR
	SELECT rept020.*, r10_nombre FROM rept020, rept010
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc  
		  AND r20_cod_tran  = rm_r19.r19_tipo_dev
		  AND r20_num_tran  = rm_r19.r19_num_dev 
		  AND (r20_cant_ven - r20_cant_dev) > 0
		  AND r10_compania  = r20_compania
		  AND r10_codigo    = r20_item
	ORDER BY r20_orden

LET i = 1
FOREACH q_det INTO r_r20.*, rm_datos[i].item 
	LET rm_compra[i].cant_dev   = 0                   
	LET rm_compra[i].cant_ven   = r_r20.r20_cant_ven - r_r20.r20_cant_dev
	LET rm_compra[i].item       = r_r20.r20_item
	LET rm_compra[i].descuento  = r_r20.r20_descuento
	LET rm_compra[i].precio     = r_r20.r20_precio
	LET rm_compra[i].total      = 0                                        

	LET rm_datos[i].val_dscto   = 0

	LET rm_datos[i].stock_ant  = r_r20.r20_stock_ant 
	LET rm_datos[i].costo	   = r_r20.r20_costo

	LET i = i + 1
	IF i > vm_max_ventas THEN
		CALL fl_mensaje_arreglo_incompleto()
		LET INT_FLAG = 1
		RETURN 0
	END IF
END FOREACH

LET i = i - 1

RETURN i

END FUNCTION



FUNCTION lee_detalle_dev()

DEFINE i		SMALLINT
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*

DECLARE q_dev CURSOR FOR
	SELECT rept020.*, r10_codigo FROM rept020, rept010
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc  
		  AND r20_cod_tran  = rm_r19.r19_cod_tran
		  AND r20_num_tran  = rm_r19.r19_num_tran
		  AND r10_compania  = r20_compania
                  AND r10_codigo    = r20_item
	ORDER BY r20_orden

LET i = 1
FOREACH q_dev INTO r_r20.*, rm_datos[i].item 
	LET rm_compra[i].cant_dev   = r_r20.r20_cant_ven  
	LET rm_compra[i].cant_ven   = r_r20.r20_cant_ven                      
	LET rm_compra[i].item       = r_r20.r20_item
	LET rm_compra[i].descuento  = r_r20.r20_descuento
	LET rm_compra[i].precio     = r_r20.r20_precio
	LET rm_compra[i].total      = r_r20.r20_precio * rm_compra[i].cant_dev 

	LET rm_datos[i].val_dscto  = 
		rm_compra[i].total * (r_r20.r20_descuento / 100)

	LET rm_datos[i].stock_ant  = r_r20.r20_stock_ant 
	LET rm_datos[i].costo	   = r_r20.r20_costo

	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1

RETURN i

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

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



FUNCTION muestra_etiquetas(r_r19)

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_c10		RECORD LIKE ordt010.*

DISPLAY BY NAME r_r19.r19_oc_interna,
		r_r19.r19_moneda,
		r_r19.r19_bodega_ori

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, r_r19.r19_oc_interna)
	RETURNING r_c10.*
CALL etiquetas_orden_compra(r_c10.*)
CALL setea_nombre_botones()

CALL fl_lee_bodega_rep(vg_codcia, r_r19.r19_bodega_ori) RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO n_bodega

CALL fl_lee_vendedor_rep(vg_codcia, r_r19.r19_vendedor) RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO n_vendedor

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran

DEFINE resp		CHAR(6)
DEFINE retVal 		SMALLINT

SET LOCK MODE TO WAIT 3

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, modulo,
		'AA', tipo_tran)
		
SET LOCK MODE TO NOT WAIT
		
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

CALL fgl_winquestion(vg_producto, 
	'La tabla de secuencias de transacciones ' ||
        'está siendo accesada por otro usuario, espere unos  ' ||
        'segundos y vuelva a intentar', 
	'No', 'Yes|No|Cancel', 'question', 1) RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION



FUNCTION setea_nombre_botones()

DISPLAY 'Dev'    TO bt_cant_dev 
DISPLAY 'Cant'   TO bt_cant_vend
DISPLAY 'Item'   TO bt_item    
DISPLAY 'Desc'  TO bt_dscto
DISPLAY 'Precio Unit.' TO bt_precio
DISPLAY 'Total'  TO bt_total

END FUNCTION



FUNCTION etiquetas_orden_compra(r_c10)

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*

IF r_c10.c10_numero_oc IS NULL THEN
	INITIALIZE rm_r19.r19_descuento,
		   rm_r19.r19_porc_impto,
		   rm_r19.r19_moneda,
		   rm_r19.r19_oc_externa,
		   rm_r19.r19_fact_venta
		TO NULL
	CLEAR cod_proveedor, n_proveedor, n_moneda
ELSE
	CALL fl_lee_moneda(r_c10.c10_moneda) RETURNING r_g13.*
	DISPLAY r_g13.g13_nombre TO n_moneda    

	CALL fl_lee_proveedor(r_c10.c10_codprov) RETURNING r_p01.*
	DISPLAY r_c10.c10_codprov TO cod_proveedor
	DISPLAY r_p01.p01_nomprov TO n_proveedor

END IF

DISPLAY BY NAME rm_r19.r19_descuento,
		rm_r19.r19_porc_impto,
		rm_r19.r19_moneda,
		rm_r19.r19_oc_externa,
		rm_r19.r19_fact_venta

END FUNCTION



FUNCTION calcula_totales(num_elm)

DEFINE num_elm		SMALLINT
DEFINE i      	 	SMALLINT

DEFINE costo 		LIKE rept019.r19_tot_costo
DEFINE bruto		LIKE rept019.r19_tot_bruto
DEFINE precio		LIKE rept019.r19_tot_neto  
DEFINE descto       	LIKE rept019.r19_tot_dscto
	
DEFINE iva          	LIKE rept019.r19_tot_dscto

LET costo     = 0	-- TOTAL COSTO 
LET precio    = 0	-- TOTAL NETO  
LET descto    = 0 	-- TOTAL DESCUENTO
LET bruto     = 0 	-- TOTAL BRUTO     

FOR i = 1 TO num_elm
	IF rm_compra[i].cant_dev IS NOT NULL AND rm_datos[i].costo IS NOT NULL 
	THEN
		LET costo = costo + (rm_datos[i].costo  * rm_compra[i].cant_dev)
	END IF
	IF rm_compra[i].total IS NOT NULL THEN
		LET rm_datos[i].val_dscto = 
			rm_compra[i].total * (rm_compra[i].descuento / 100)
		LET bruto = bruto + rm_compra[i].total
	END IF
	IF rm_datos[i].val_dscto IS NOT NULL THEN
		LET descto = descto + rm_datos[i].val_dscto
	END IF
END FOR

LET iva    = (bruto - descto) * (rm_r19.r19_porc_impto / 100)

LET precio = (bruto - descto) + iva

LET rm_r19.r19_tot_dscto  = descto
LET rm_r19.r19_tot_bruto  = bruto
LET rm_r19.r19_tot_neto   = precio
LET rm_r19.r19_tot_costo  = costo

DISPLAY BY NAME rm_r19.r19_tot_bruto,
                rm_r19.r19_tot_dscto,
                iva,
                rm_r19.r19_tot_neto
                
END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
				RETURNING resp
IF resp = 'No' THEN
	CALL fl_mensaje_abandonar_proceso()
		 RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF

RETURN intentar

END FUNCTION



FUNCTION graba_detalle()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE i		SMALLINT
DEFINE orden   		SMALLINT

DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r20		RECORD LIKE rept020.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r20.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r20 CURSOR FOR
			SELECT * FROM rept020
				WHERE r20_compania  = vg_codcia         
				  AND r20_localidad = vg_codloc          
				  AND r20_cod_tran  = rm_r19.r19_cod_tran
				  AND r20_num_tran  = rm_r19.r19_num_tran
			FOR UPDATE
	OPEN  q_r20
	FETCH q_r20 INTO r_r20.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_r20
		FREE  q_r20
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

WHILE (status <> NOTFOUND)
	DELETE FROM rept020 WHERE CURRENT OF q_r20         

	INITIALIZE r_r20.* TO NULL
	FETCH q_r20 INTO r_r20.*
END WHILE  
CLOSE q_r20
FREE  q_r20

LET r_r20.r20_compania  = vg_codcia
LET r_r20.r20_localidad = vg_codloc
LET r_r20.r20_cod_tran  = rm_r19.r19_cod_tran
LET r_r20.r20_num_tran  = rm_r19.r19_num_tran

-- En r20_cant_ped y r20_cant_ven se graba la cantidad a devolver
-- En r20_cant_dev y r20_cant_ent se graba cero (0)
LET r_r20.r20_cant_dev   = 0
LET r_r20.r20_cant_ent   = 0
LET r_r20.r20_costant_mb = 0
LET r_r20.r20_costant_ma = 0
LET r_r20.r20_costnue_mb = 0
LET r_r20.r20_costnue_ma = 0

LET r_r20.r20_fecing     = CURRENT

LET orden = 1
FOR i = 1 TO vm_indice
	IF rm_compra[i].cant_dev = 0 THEN
		CONTINUE FOR
	END IF

	LET r_r20.r20_orden      = orden                      
	LET orden = orden + 1

	LET r_r20.r20_cant_ped   = rm_compra[i].cant_dev   
	LET r_r20.r20_cant_ven   = rm_compra[i].cant_dev
   
	LET done = obtiene_existencias(i)
	IF NOT done THEN
		RETURN done
	END IF

	LET r_r20.r20_stock_ant  = rm_datos[i].stock_ant
	LET r_r20.r20_stock_bd   = rm_datos[i].stock_ant
	LET r_r20.r20_descuento  = rm_compra[i].descuento
	LET r_r20.r20_val_descto = rm_datos[i].val_dscto
	LET r_r20.r20_val_impto  = 
				rm_compra[i].total * (rm_r19.r19_porc_impto / 100)

	CALL fl_lee_item(vg_codcia, rm_compra[i].item) RETURNING r_r10.*
	LET r_r20.r20_linea      = r_r10.r10_linea				
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion
	LET r_r20.r20_fob        = r_r10.r10_fob             

	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori, rm_compra[i].item) 
		RETURNING r_r11.*
	LET r_r20.r20_ubicacion  = r_r11.r11_ubicacion

	LET r_r20.r20_item       = rm_compra[i].item       
	LET r_r20.r20_precio     = rm_compra[i].precio

	LET r_r20.r20_costo      = rm_datos[i].costo 

	INSERT INTO rept020 VALUES (r_r20.*)

	CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc, 
							r_r20.r20_cod_tran, r_r20.r20_num_tran, r_r20.r20_item)
END FOR 

RETURN done

END FUNCTION



FUNCTION obtiene_existencias(i)

DEFINE i        	SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)

DEFINE r_r11		RECORD LIKE rept011.*

LET intentar = 1
LET done = 0

WHILE (intentar)
	INITIALIZE r_r11.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r11 CURSOR FOR
			SELECT * FROM rept011
				WHERE r11_compania  = vg_codcia
				AND   r11_bodega    = rm_r19.r19_bodega_ori
				AND   r11_item      = rm_compra[i].item
	OPEN  q_r11
	WHENEVER ERROR STOP
	FETCH q_r11 INTO r_r11.*
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

LET rm_datos[i].stock_ant = r_r11.r11_stock_act

CLOSE q_r11
FREE  q_r11

RETURN done

END FUNCTION



FUNCTION actualiza_transaccion()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE i		SMALLINT

DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r19.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r19 CURSOR FOR
			SELECT * FROM rept019
				WHERE r19_compania  = vg_codcia         
				  AND r19_localidad = vg_codloc          
				  AND r19_cod_tran  = rm_r19.r19_tipo_dev
				  AND r19_num_tran  = rm_r19.r19_num_dev 
			FOR UPDATE
	OPEN  q_r19
	FETCH q_r19 INTO r_r19.* 
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

UPDATE rept019 SET r19_tipo_dev = rm_r19.r19_cod_tran,
		   r19_num_dev  = rm_r19.r19_num_tran
	WHERE CURRENT OF q_r19

CLOSE q_r19
FREE q_r19

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r20.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_upd CURSOR FOR
			SELECT * FROM rept020
				WHERE r20_compania  = vg_codcia         
				  AND r20_localidad = vg_codloc          
				  AND r20_cod_tran  = rm_r19.r19_tipo_dev
				  AND r20_num_tran  = rm_r19.r19_num_dev 
			FOR UPDATE
	OPEN  q_upd
	FETCH q_upd INTO r_r20.*
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

WHILE (STATUS <> NOTFOUND)
	FOR i = 1 TO vm_indice
		IF r_r20.r20_item = rm_compra[i].item THEN
			LET r_r20.r20_cant_dev = 
				r_r20.r20_cant_dev + rm_compra[i].cant_dev
			UPDATE rept020 SET * = r_r20.* WHERE CURRENT OF q_upd 
			EXIT FOR
		END IF
	END FOR

	INITIALIZE r_r20.* TO NULL
	FETCH q_upd INTO r_r20.*
END WHILE   
CLOSE q_upd
FREE  q_upd

RETURN done

END FUNCTION



FUNCTION control_mostrar_det()

CALL set_count(vm_indice)
DISPLAY ARRAY rm_compra TO ra_compra.*
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION actualiza_orden()

DEFINE i        	SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)

DEFINE r_c11		RECORD LIKE ordt011.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_c11.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_c11 CURSOR FOR
			SELECT * FROM ordt011
				WHERE c11_compania  = vg_codcia
				  AND c11_localidad = vg_codloc            
				  AND c11_numero_oc = rm_r19.r19_oc_interna
			FOR UPDATE
	OPEN  q_c11
	FETCH q_c11 INTO r_c11.*
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

WHILE (STATUS <> NOTFOUND)
	FOR i = 1 TO vm_indice
		IF r_c11.c11_codigo = rm_compra[i].item THEN
			UPDATE ordt011 SET 
				c11_cant_rec = 
					c11_cant_rec - rm_compra[i].cant_ven
				WHERE CURRENT OF q_c11
			EXIT FOR
		END IF
	END FOR
	
	INITIALIZE r_c11.* TO NULL
	FETCH q_c11 INTO r_c11.*
END WHILE   

RETURN done

END FUNCTION



FUNCTION items_alterados(r_r19)

DEFINE r_r19		RECORD LIKE rept019.*
DEFINE contador		SMALLINT
DEFINE num_det		SMALLINT

SELECT COUNT(*) INTO contador
	FROM rept020, rept011, rept010
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = r_r19.r19_cod_tran
	  AND r20_num_tran  = r_r19.r19_num_tran
	  AND r11_compania  = r20_compania
	  AND r11_bodega    = r_r19.r19_bodega_ori
	  AND r11_item      = r20_item
	  AND r11_stock_act = r20_stock_ant + r20_cant_ven
	  AND r10_compania  = r20_compania
	  AND r10_codigo    = r20_item
	  AND r10_costo_mb  = r20_costnue_mb
	  
SELECT COUNT(*) INTO num_det
	FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = r_r19.r19_cod_tran
	  AND r20_num_tran  = r_r19.r19_num_tran
	  
IF num_det = contador THEN
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION rebaja_deuda()

DEFINE i		SMALLINT

DEFINE num_row		INTEGER
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE aplicado_cap	DECIMAL(14,2)
DEFINE aplicado_int	DECIMAL(14,2)
DEFINE valor_aplicar	DECIMAL(14,2)
DEFINE valor_favor	LIKE cxpt021.p21_valor

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p21		RECORD LIKE cxpt021.*

DEFINE r_doc		RECORD LIKE cxpt020.*

DEFINE r_caju		RECORD LIKE cxpt022.*
DEFINE r_daju		RECORD LIKE cxpt023.*

INITIALIZE r_p21.*  TO NULL
INITIALIZE r_caju.* TO NULL
INITIALIZE r_daju.* TO NULL

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING r_c10.*

LET r_p21.p21_compania     = vg_codcia
LET r_p21.p21_localidad    = vg_codloc
LET r_p21.p21_codprov      = r_c10.c10_codprov
LET r_p21.p21_tipo_doc     = vm_nota_credito
LET r_p21.p21_num_doc      = nextValInSequence('TE', vm_nota_credito)
IF r_p21.p21_num_doc = -1 THEN
	LET INT_FLAG = 1
	RETURN
END IF

LET r_p21.p21_referencia   = 'DEVOLUCION (COMPRA LOCAL) # ' || 
			     rm_r19.r19_num_tran
LET r_p21.p21_fecha_emi    = TODAY
LET r_p21.p21_moneda       = rm_r19.r19_moneda
LET r_p21.p21_paridad      = rm_r19.r19_paridad
        
--	Solo se carga a la nota de credito lo que ya se haya pagado,   
--	las retenciones nunca salieron, asi que no cuentan
SELECT NVL(SUM(p23_valor_cap), 0) INTO r_p21.p21_valor FROM cxpt023
	WHERE p23_compania  = vg_codcia
	  AND p23_localidad = vg_codloc 
	  AND p23_codprov   = r_c10.c10_codprov
	  AND p23_tipo_trn  = 'PG'
	  AND p23_tipo_doc  = 'FA'
	  AND p23_num_doc   = r_c10.c10_factura

LET r_p21.p21_valor        = r_p21.p21_valor * (-1)
LET r_p21.p21_saldo        = r_p21.p21_valor    
LET r_p21.p21_subtipo      = 1
LET r_p21.p21_origen       = 'A'
LET r_p21.p21_usuario      = vg_usuario
LET r_p21.p21_fecing       = CURRENT

INSERT INTO cxpt021 VALUES(r_p21.*)

-- Para dar de baja el resto de la deuda impaga

DECLARE q_ddev CURSOR FOR 
	SELECT * FROM cxpt020 WHERE p20_compania  = vg_codcia
	                        AND p20_localidad = vg_codloc
	                        AND p20_codprov   = r_c10.c10_codprov
	                        AND p20_tipo_doc  = vm_factura
	                        AND p20_num_doc   = rm_r19.r19_oc_externa
				AND p20_saldo_cap + p20_saldo_int > 0
		FOR UPDATE
		
INITIALIZE r_caju.* TO NULL
LET r_caju.p22_compania 	= vg_codcia
LET r_caju.p22_localidad 	= vg_codloc
LET r_caju.p22_codprov		= r_c10.c10_codprov
LET r_caju.p22_tipo_trn 	= 'AJ'
LET r_caju.p22_num_trn 		= fl_actualiza_control_secuencias(vg_codcia, 
				  vg_codloc, 'TE', 'AA', 'AJ')
IF r_caju.p22_num_trn <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_caju.p22_referencia 	= 'DEV. COMPRA LOCAL # ', rm_r19.r19_num_tran
LET r_caju.p22_fecha_emi 	= TODAY
LET r_caju.p22_moneda 		= rm_r19.r19_moneda
LET r_caju.p22_paridad 		= rm_r19.r19_paridad
LET r_caju.p22_tasa_mora 	= 0
LET r_caju.p22_total_cap 	= 0
LET r_caju.p22_total_int 	= 0
LET r_caju.p22_total_mora	= 0
LET r_caju.p22_subtipo 		= 1
LET r_caju.p22_origen 		= 'A'
LET r_caju.p22_fecha_elim 	= NULL
LET r_caju.p22_tiptrn_elim 	= NULL
LET r_caju.p22_numtrn_elim 	= NULL
LET r_caju.p22_usuario 		= vg_usuario
LET r_caju.p22_fecing 		= CURRENT

INSERT INTO cxpt022 VALUES (r_caju.*)
LET num_row = SQLCA.SQLERRD[6]

LET valor_favor = rm_r19.r19_tot_neto
LET i = 0
LET valor_aplicado = 0
FOREACH q_ddev INTO r_doc.*
	LET valor_aplicar = valor_favor - valor_aplicado
	IF valor_aplicar = 0 THEN
		EXIT FOREACH
	END IF
	LET i = i + 1
	LET aplicado_cap  = 0
	LET aplicado_int  = 0
	IF r_doc.p20_saldo_int <= valor_aplicar THEN
		LET aplicado_int = r_doc.p20_saldo_int 
	ELSE
		LET aplicado_int = valor_aplicar
	END IF
	LET valor_aplicar = valor_aplicar - aplicado_int
	IF r_doc.p20_saldo_cap <= valor_aplicar THEN
		LET aplicado_cap = r_doc.p20_saldo_cap 
	ELSE
		LET aplicado_cap = valor_aplicar
	END IF
	LET valor_aplicado = valor_aplicado + aplicado_cap + aplicado_int
	LET r_caju.p22_total_cap        = r_caju.p22_total_cap + 
					  (aplicado_cap * -1)
	LET r_caju.p22_total_int        = r_caju.p22_total_int + 
					  (aplicado_int * -1)
    	LET r_daju.p23_compania 	= vg_codcia
    	LET r_daju.p23_localidad 	= vg_codloc
    	LET r_daju.p23_codprov		= r_caju.p22_codprov
    	LET r_daju.p23_tipo_trn 	= r_caju.p22_tipo_trn
    	LET r_daju.p23_num_trn  	= r_caju.p22_num_trn
    	LET r_daju.p23_orden 		= i
    	LET r_daju.p23_tipo_doc 	= r_doc.p20_tipo_doc
    	LET r_daju.p23_num_doc 	        = r_doc.p20_num_doc
    	LET r_daju.p23_div_doc 		= r_doc.p20_dividendo
    	LET r_daju.p23_tipo_favor 	= r_p21.p21_tipo_doc
    	LET r_daju.p23_doc_favor 	= r_p21.p21_num_doc
    	LET r_daju.p23_valor_cap 	= aplicado_cap * -1
    	LET r_daju.p23_valor_int 	= aplicado_int * -1
    	LET r_daju.p23_valor_mora 	= 0
    	LET r_daju.p23_saldo_cap 	= r_doc.p20_saldo_cap
    	LET r_daju.p23_saldo_int	= r_doc.p20_saldo_int
	INSERT INTO cxpt023 VALUES (r_daju.*)
	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap - aplicado_cap,
	                   p20_saldo_int = p20_saldo_int - aplicado_int
		WHERE CURRENT OF q_ddev
END FOREACH
IF i = 0 THEN
	DELETE FROM cxpt022 WHERE ROWID = num_row
ELSE
	UPDATE cxpt022 SET p22_total_cap = r_caju.p22_total_cap,
	                   p22_total_int = r_caju.p22_total_int
		WHERE ROWID = num_row
END IF
FREE q_ddev
CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, r_p21.p21_codprov)
RETURN valor_aplicado

END FUNCTION



FUNCTION consultar_devoluciones()

LET vm_num_rows    = 1
LET vm_row_current = 1

DECLARE q_dev2 CURSOR FOR
	SELECT *, ROWID FROM rept019
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = vm_transaccion
		  AND r19_tipo_dev  = vm_dev_tran
		  AND r19_num_dev   = vm_num_tran
		ORDER BY 1, 2, 3, 4
		  
FOREACH q_dev2 INTO rm_r19.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
FREE q_dev2

LET vm_num_rows = vm_num_rows - 1

IF vm_num_rows = 0 THEN
	CALL fgl_winmessage(vg_producto,
		'No existen devoluciones para esta compra local.',
		'info')
	EXIT PROGRAM
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION elimina_retenciones()

DEFINE done 		SMALLINT
DEFINE r_c10		RECORD LIKE ordt010.*

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING r_c10.*

LET done = 1

SET LOCK MODE TO WAIT 3
WHENEVER ERROR CONTINUE
DECLARE q_ret CURSOR FOR
	SELECT p27_estado FROM cxpt027
		WHERE p27_compania  = vg_codcia
		  AND p27_localidad = vg_codloc
		  AND p27_num_ret   IN (SELECT DISTINCT p28_num_ret 
		  			FROM cxpt028
		  			WHERE p28_compania  = p27_compania
		  			  AND p28_localidad = p27_localidad
		  			  AND p28_codprov   = r_c10.c10_codprov
		  			  AND p28_tipo_doc  = vm_factura
		  			  AND p28_num_doc   = rm_r19.r19_oc_externa)
	FOR UPDATE OF p27_estado
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
OPEN  q_ret
FETCH q_ret
IF STATUS < 0 THEN
	CALL fgl_winmessage(vg_producto, 
		'No se pudo completar el proceso, por favor espere unos ' ||
		'segundos y vuelva a intentarlo.',
		'exclamation')
	LET done = 0
	RETURN
END IF
IF status <> NOTFOUND THEN
	UPDATE cxpt027 SET p27_estado = 'E' WHERE CURRENT OF q_ret
	CLOSE q_ret
	FREE  q_ret
END IF
RETURN done

END FUNCTION



FUNCTION imprimir()

DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp416 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran,
	rm_r19.r19_num_tran
	
RUN comando	

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

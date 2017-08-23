------------------------------------------------------------------------------
-- Titulo           : repp219.4gl - Devolución de ventas al taller 
-- Elaboracion      : 06-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp219 base modulo compania localidad
--			Si se reciben 4 parametros se está ejecutando en 
--			modo independiente
--			Si se reciben 6 parametros, se asume que el quinto es
-- 			el codigo de la requisicion (transaccion origen)
--			y el sexto parametro es el numero de la requisicion
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_transaccion   LIKE rept019.r19_cod_tran
DEFINE vm_dev_tran      LIKE rept019.r19_cod_tran

DEFINE vm_requisicion 	LIKE rept019.r19_cod_tran
DEFINE vm_factura 	LIKE rept019.r19_cod_tran

DEFINE vm_dev_req 	LIKE rept019.r19_cod_tran
DEFINE vm_dev_fact 	LIKE rept019.r19_cod_tran

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
DEFINE rm_venta ARRAY[100] OF RECORD
	cant_dev		LIKE rept020.r20_cant_ped, 
	cant_ven		LIKE rept020.r20_cant_ven, 
	item			LIKE rept020.r20_item, 
	descuento		LIKE rept020.r20_descuento,
	precio			LIKE rept020.r20_precio, 
	total			LIKE rept019.r19_tot_bruto
END RECORD

DEFINE rm_datos ARRAY[100] OF RECORD
	bodega 	 		LIKE rept020.r20_bodega,
	item  	 		LIKE rept010.r10_nombre,
	orden  	 		LIKE rept020.r20_orden,
	costo			LIKE rept020.r20_costo,		-- COSTO ITEM
	val_dscto		LIKE rept020.r20_val_descto,
	stock_ant		LIKE rept020.r20_stock_ant
END RECORD

-- Flag que indica si los repuestos de la orden de trabajo salen al
-- precio de venta al público(P) o al costo (C)
DEFINE vm_tipo_orden		LIKE talt005.t05_prec_rpto

-- Registro de la tabla de configuración del módulo de repuestos
DEFINE rm_r00			RECORD LIKE rept000.*
DEFINE rm_t00			RECORD LIKE talt000.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN  -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp219'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
			        -- que luego puede ser reemplazado si se 
                            	-- mantiene sin comentario la siguiente linea

INITIALIZE vm_dev_tran TO NULL
LET vm_num_tran = 0
IF num_args() = 6 THEN
	LET vm_dev_tran = arg_val(5)
	LET vm_num_tran = arg_val(6)
END IF

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
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
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
OPEN WINDOW w_219 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_219 FROM '../forms/repf219_1'
ELSE
	OPEN FORM f_219 FROM '../forms/repf219_1c'
END IF
DISPLAY FORM f_219

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r19.* TO NULL

LET vm_tipo_orden = 'P'

CALL muestra_contadores()
CALL setea_nombre_botones()

LET vm_max_rows   = 1000
LET vm_max_ventas = 100


CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
IF rm_r00.r00_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe registro de configuración para esta compañía.','exclamation')
	CALL fl_mostrar_mensaje('No existe registro de configuración para esta compañía.','exclamation')
	EXIT PROGRAM
END IF

-- OjO
LET vm_requisicion = 'RQ'
LET vm_factura     = 'FA'

SELECT g21_codigo_dev INTO vm_dev_req FROM gent021 
	WHERE g21_cod_tran = vm_requisicion
SELECT g21_codigo_dev INTO vm_dev_fact FROM gent021 
	WHERE g21_cod_tran = vm_factura
-- LET vm_dev_req     = 'DR'
-- LET vm_dev_fact    = 'DF'

IF num_args() <> 6 THEN
	IF vg_codcia = rm_r00.r00_cia_taller THEN
		LET vm_transaccion = vm_dev_req
   		LET vm_dev_tran    = vm_requisicion
	ELSE
    		LET vm_transaccion = vm_dev_fact
   		LET vm_dev_tran    = vm_factura
	END IF
ELSE
	IF vm_dev_tran = vm_factura THEN
    		LET vm_transaccion = vm_dev_fact
    	ELSE
    		LET vm_transaccion = vm_dev_req
    	END IF
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
		--HIDE OPTION 'Ver Factura'
		IF vm_num_tran <> 0 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			--SHOW OPTION 'Ver Factura'
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
			SHOW OPTION 'Imprimir'
			--SHOW OPTION 'Ver Factura'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir'
			--SHOW OPTION 'Ver Factura'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir'
			--SHOW OPTION 'Ver Factura'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Imprimir'
			--SHOW OPTION 'Ver Factura'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('D') 'Detalle'		'Ver detalle de devolución.'
		CALL control_mostrar_det()
	COMMAND KEY('P') 'Imprimir'		'Imprimir comprobante.'
		CALL control_imprimir()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_g13		RECORD LIKE gent013.*

DEFINE i		SMALLINT
DEFINE rowid    	INTEGER
DEFINE intentar		SMALLINT
DEFINE done		SMALLINT

CLEAR FORM
INITIALIZE rm_r19.* TO NULL

-- THESE VALUES WON'T CHANGE 
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
LET rm_r19.r19_cod_tran   = vm_transaccion
LET rm_r19.r19_tipo_dev   = vm_dev_tran      
LET rm_r19.r19_flete      = 0
LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_fecing     = fl_current()

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

-- Atrapo la orden de trabajo para que nadie la pueda modificar hasta que
-- yo termine este proceso

BEGIN WORK

LET intentar = 1
LET done = 0
WHILE (intentar)
    INITIALIZE r_t23.* TO NULL
    WHENEVER ERROR CONTINUE
        DECLARE q_t23 CURSOR FOR
	        SELECT * FROM talt023
		        WHERE t23_compania  = vg_codcia
		          AND t23_localidad = vg_codloc
		          AND t23_orden     = rm_r19.r19_ord_trabajo
	        FOR UPDATE
	OPEN  q_t23
	FETCH q_t23 INTO r_t23.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL setea_nombre_botones()
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF    
	RETURN
END IF	

CALL ingresa_detalle(r_t23.*)
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL setea_nombre_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	ROLLBACK WORK
	RETURN
END IF

LET done = 0
FOR i = 1 TO vm_indice
	IF rm_venta[i].cant_dev > 0 THEN
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
	ROLLBACK WORK
	RETURN
END IF

LET rm_r19.r19_bodega_dest = rm_r19.r19_bodega_ori

LET rm_r19.r19_num_tran = nextValInSequence()
IF rm_r19.r19_num_tran = -1 THEN
	ROLLBACK WORK
	CLEAR FORM
	RETURN
END IF

INSERT INTO rept019 VALUES (rm_r19.*)
DISPLAY BY NAME rm_r19.r19_num_tran

LET rowid = SQLCA.SQLERRD[6]		-- Rowid de la ultima fila
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

LET r_t23.t23_val_rp_alm  = r_t23.t23_val_rp_alm - rm_r19.r19_tot_bruto
CALL fl_totaliza_orden_taller(r_t23.*) RETURNING r_t23.*

UPDATE talt023 SET t23_val_rp_alm = r_t23.t23_val_rp_alm,
    		   t23_vde_rp_alm = r_t23.t23_vde_rp_alm,
    		   t23_tot_bruto  = r_t23.t23_tot_bruto,
    		   t23_tot_dscto  = r_t23.t23_tot_dscto,
    		   t23_val_impto  = r_t23.t23_val_impto,
    		   t23_tot_neto   = r_t23.t23_tot_neto
	WHERE CURRENT OF q_t23
CLOSE q_t23
FREE  q_t23

IF vm_transaccion = vm_dev_fact THEN
	IF vg_codcia = rm_r00.r00_cia_taller THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('La transacción devuelta es una factura, y la compañía del Taller no debe ser la misma que Inventario.','stop')
		EXIT PROGRAM
	END IF
	IF rm_r00.r00_codcli_tal IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No está configurado el código de cliente para la compañía del Taller', 'stop')
		EXIT PROGRAM
	END IF
	IF rm_r19.r19_codcli IS NULL OR rm_r19.r19_codcli <> 
		rm_r00.r00_codcli_tal IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Código cliente en la factura no es del Taller', 'stop')
		EXIT PROGRAM
	END IF
	CALL crea_nota_credito()
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

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos()

DEFINE resp 		CHAR(6)

DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t05		RECORD LIKE talt005.*
DEFINE r_t23		RECORD LIKE talt023.*

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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_num_dev) THEN
			CALL fl_ayuda_venta_taller_rep(vg_codcia, vg_codloc,    
				vm_dev_tran) RETURNING r_r19.r19_tipo_dev,
				          	       r_r19.r19_num_dev,
				   	  	       r_r19.r19_nomcli
		     	IF r_r19.r19_tipo_dev IS NOT NULL THEN
				LET rm_r19.r19_tipo_dev = r_r19.r19_tipo_dev
				LET rm_r19.r19_num_dev  = r_r19.r19_num_dev
				LET rm_r19.r19_nomcli   = r_r19.r19_nomcli  
				DISPLAY BY NAME rm_r19.r19_tipo_dev, 
						rm_r19.r19_num_dev,
						rm_r19.r19_nomcli
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_nombre_botones()
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r19_num_dev
		IF rm_r19.r19_num_dev IS NULL THEN
			INITIALIZE r_r19.* TO NULL
			CALL muestra_etiquetas(r_r19.*)
			CONTINUE INPUT
		END IF
		CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
			rm_r19.r19_tipo_dev, rm_r19.r19_num_dev)
			RETURNING r_r19.*
		IF r_r19.r19_ord_trabajo IS NULL THEN
			CALL fl_mostrar_mensaje('La transacción no está asociada a una orden de trabajo.','exclamation')
			INITIALIZE r_r19.* TO NULL 
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		IF vg_fecha > date(r_r19.r19_fecing) + rm_t00.t00_dias_dev THEN
			CALL fl_mostrar_mensaje('Ha excedido el limite de tiempo permitido para realizar devoluciones.','exclamation')
			INITIALIZE r_r19.* TO NULL 
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		IF rm_t00.t00_dev_mes = 'S' THEN
			IF month(r_r19.r19_fecing) <> month(vg_fecha) THEN
				CALL fl_mostrar_mensaje('La devolución debe realizarse en el mismo mes en que se realizó la venta.','exclamation')
				INITIALIZE r_r19.* TO NULL 
				CALL muestra_etiquetas(r_r19.*)
				NEXT FIELD r19_num_dev
			END IF
		END IF
		CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, 
			r_r19.r19_ord_trabajo) RETURNING r_t23.*
		IF r_t23.t23_orden IS NULL THEN
			CALL fl_mostrar_mensaje('Orden de trabajo no existe.','exclamation')
			INITIALIZE r_r19.* TO NULL
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		IF r_t23.t23_estado <> 'A' THEN
			CALL fl_mostrar_mensaje('Orden de trabajo no está activa.','exclamation')
			INITIALIZE r_r19.* TO NULL
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		LET rm_r19.r19_tipo_dev    = vm_dev_tran
		LET rm_r19.r19_ord_trabajo = r_r19.r19_ord_trabajo
		LET rm_r19.r19_cont_cred   = r_r19.r19_cont_cred
		LET rm_r19.r19_descuento   = r_r19.r19_descuento
		LET rm_r19.r19_porc_impto  = r_r19.r19_porc_impto
		LET rm_r19.r19_bodega_ori  = r_r19.r19_bodega_ori
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
		CALL fl_lee_tipo_orden_taller(vg_codcia, r_t23.t23_tipo_ot)
			RETURNING r_t05.*
		LET vm_tipo_orden = r_t05.t05_prec_rpto
		CALL setea_nombre_botones()
END INPUT

END FUNCTION



FUNCTION ingresa_detalle(r_tal)

DEFINE resp 		CHAR(6)
DEFINE i    		SMALLINT
DEFINE j    		SMALLINT
DEFINE salir		SMALLINT

DEFINE flag		SMALLINT

DEFINE r_tal		RECORD LIKE talt023.*

LET INT_FLAG = 0
LET vm_indice = lee_detalle_tran_ori()
IF INT_FLAG THEN
	RETURN
END IF

LET flag = 0
FOR i = 1 TO vm_indice
	IF rm_venta[i].cant_ven > 0 THEN
		LET flag = 1
	END IF 	
END FOR

IF NOT flag THEN
	CALL fl_mostrar_mensaje('Esta factura ya ha sido devuelta por completo.','exclamation')
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
	INPUT ARRAY rm_venta WITHOUT DEFAULTS FROM ra_venta.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
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
			DISPLAY rm_datos[i].item TO descripcion
		AFTER FIELD r20_cant_dev
			IF rm_venta[i].cant_dev IS NULL THEN
				CALL calcula_totales(vm_indice) 
				NEXT FIELD r20_cant_dev
			END IF
			IF rm_venta[i].cant_dev > rm_venta[i].cant_ven THEN
				CALL fl_mostrar_mensaje('La cantidad a devolver debe ser menor o igual a la cantidad despachada.','exclamation')
				NEXT FIELD r20_cant_dev
			END IF
		-------------------------------------------------------------
			LET rm_venta[i].total = 
				rm_venta[i].cant_dev * rm_venta[i].precio
			LET rm_datos[i].val_dscto =
				rm_venta[i].total * (rm_venta[i].descuento/100)
			CALL calcula_totales(vm_indice) 
			DISPLAY rm_venta[i].* TO ra_venta[j].*
			DISPLAY rm_datos[i].item TO descripcion
		BEFORE DELETE
			EXIT INPUT
		BEFORE INSERT
			EXIT INPUT
		AFTER INPUT
			LET salir = 1
	END INPUT

	IF INT_FLAG THEN
		RETURN
	END IF
END WHILE

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(600)

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE mensaje		VARCHAR(100)

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON r19_cod_tran, r19_num_tran, r19_tipo_dev, r19_num_dev, 
	   r19_ord_trabajo, r19_vendedor, r19_bodega_ori, r19_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_num_dev) THEN
			CALL fl_ayuda_venta_taller_rep(vg_codcia, vg_codloc,    
				vm_dev_tran) RETURNING r_r19.r19_tipo_dev,
				          	       r_r19.r19_num_dev,
				   	  	       r_r19.r19_nomcli
		     	IF r_r19.r19_tipo_dev IS NOT NULL THEN
				LET rm_r19.r19_tipo_dev = r_r19.r19_tipo_dev
				LET rm_r19.r19_num_dev  = r_r19.r19_num_dev
				LET rm_r19.r19_nomcli   = r_r19.r19_nomcli  
				DISPLAY BY NAME rm_r19.r19_tipo_dev, 
						rm_r19.r19_num_dev,
						rm_r19.r19_nomcli
			END IF
		END IF
		IF INFIELD(r19_ord_trabajo) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'A') 
				RETURNING r_t23.t23_orden,
					  r_t23.t23_nom_cliente
			IF r_t23.t23_orden IS NOT NULL THEN
				LET rm_r19.r19_ord_trabajo = r_t23.t23_orden
				LET rm_r19.r19_nomcli = r_t23.t23_nom_cliente
				DISPLAY BY NAME rm_r19.r19_ord_trabajo,
						rm_r19.r19_nomcli
			END IF
		END IF
		IF INFIELD(r19_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'M')
				RETURNING r_r01.r01_codigo, 
					  r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
			    LET rm_r19.r19_vendedor = r_r01.r01_codigo
			    DISPLAY BY NAME rm_r19.r19_vendedor
			    DISPLAY r_r01.r01_nombres TO n_vendedor
			END IF
		END IF
		IF INFIELD(r19_bodega_ori) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'T', 'T', 'S', 'V')
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
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r19_cod_tran
		LET rm_r19.r19_cod_tran = GET_FLDBUF(r19_cod_tran)
		IF rm_r19.r19_cod_tran IS NOT NULL THEN
			IF rm_r19.r19_cod_tran <> vm_dev_req     
			AND rm_r19.r19_cod_tran <> vm_dev_fact
			THEN
				LET mensaje = 'El código de la transacción '||
                                            'debe ser ' || vm_dev_req ||
					    ' o ' || vm_dev_fact || '.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
                        	NEXT FIELD r19_cod_tran
			END IF 
		END IF
	AFTER FIELD r19_tipo_dev
		LET rm_r19.r19_tipo_dev = GET_FLDBUF(r19_tipo_dev)
		IF rm_r19.r19_tipo_dev IS NOT NULL THEN
			IF rm_r19.r19_tipo_dev <> vm_requisicion 
			AND rm_r19.r19_tipo_dev <> vm_factura
			THEN
				LET mensaje = 'El código de la venta '||
                                            'debe ser ' || vm_requisicion ||
					    ' o ' || vm_factura || '.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
                NEXT FIELD r19_tipo_dev
			END IF 
		END IF
	AFTER FIELD r19_vendedor
		LET rm_r19.r19_vendedor = GET_FLDBUF(r19_vendedor) 
		IF rm_r19.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CLEAR n_vendedor
			END IF 
			IF r_r01.r01_estado = 'B' THEN
				CLEAR n_vendedor
			END IF
			DISPLAY r_r01.r01_nombres TO n_vendedor
		ELSE
			CLEAR n_vendedor
		END IF		 
	AFTER FIELD r19_bodega_ori
		LET rm_r19.r19_bodega_ori = GET_FLDBUF(r19_bodega_ori) 
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
	    '	WHERE r19_compania  = ', vg_codcia, 
	    '	  AND r19_localidad = ', vg_codloc,
	    '	  AND  r19_cod_tran = "', vm_dev_fact, '"',
	    '	  AND r19_ord_trabajo IS NOT NULL ',
	    '	  AND r19_tipo_dev = "', vm_factura, '"',
	    '	  AND ', expr_sql CLIPPED,
	    'UNION ALL	',
	    'SELECT *, ROWID FROM rept019 ',
	    '	WHERE r19_compania  = ', vg_codcia, 
	    '	  AND r19_localidad = ', vg_codloc,
	    '	  AND r19_cod_tran = "', vm_dev_req, '" ',
	    '	  AND r19_ord_trabajo IS NOT NULL ',
	    '	  AND r19_tipo_dev = "', vm_requisicion, '"',
	    '	  AND ', expr_sql CLIPPED

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

LET iva = rm_r19.r19_tot_bruto * (rm_r19.r19_porc_impto / 100)

DISPLAY BY NAME rm_r19.r19_cod_tran,   
                rm_r19.r19_num_tran,   
		rm_r19.r19_tipo_dev,
		rm_r19.r19_num_dev,
		rm_r19.r19_codcli,
		rm_r19.r19_nomcli,     
		rm_r19.r19_vendedor,   
		rm_r19.r19_ord_trabajo,
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

--#LET filas_pant = fgl_scr_size('ra_venta')
IF vg_gui = 0 THEN
	LET filas_pant = 5
END IF

FOR i = 1 TO filas_pant 
	INITIALIZE rm_venta[i].* TO NULL
	CLEAR ra_venta[i].*
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
	DISPLAY rm_venta[i].* TO ra_venta[i].*
END FOR
DISPLAY rm_datos[1].item TO descripcion

END FUNCTION



FUNCTION lee_detalle_tran_ori()

DEFINE i		SMALLINT
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*

DECLARE q_det CURSOR FOR
	SELECT * FROM rept020
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc  
		  AND r20_cod_tran  = rm_r19.r19_tipo_dev
		  AND r20_num_tran  = rm_r19.r19_num_dev 
		  AND (r20_cant_ven - r20_cant_dev) > 0
	ORDER BY r20_orden

LET i = 1
FOREACH q_det INTO r_r20.* 
	LET rm_venta[i].cant_dev   = 0                   
	LET rm_venta[i].cant_ven   = r_r20.r20_cant_ven - r_r20.r20_cant_dev
	LET rm_venta[i].item       = r_r20.r20_item
	LET rm_venta[i].descuento  = r_r20.r20_descuento
	LET rm_venta[i].precio     = r_r20.r20_precio
	LET rm_venta[i].total      = r_r20.r20_precio * rm_venta[i].cant_dev 

	LET rm_datos[i].bodega     = r_r20.r20_bodega 
	LET rm_datos[i].orden      = r_r20.r20_orden  
	LET rm_datos[i].val_dscto  = 
		rm_venta[i].total * (r_r20.r20_descuento / 100)

	LET rm_datos[i].stock_ant  = r_r20.r20_stock_ant 
	LET rm_datos[i].costo	   = r_r20.r20_costo
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	LET rm_datos[i].item       = r_r10.r10_nombre 

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
	SELECT * FROM rept020
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc  
		  AND r20_cod_tran  = rm_r19.r19_cod_tran
		  AND r20_num_tran  = rm_r19.r19_num_tran
	ORDER BY r20_orden

LET i = 1
FOREACH q_dev INTO r_r20.* 
	LET rm_venta[i].cant_dev   = r_r20.r20_cant_ven  
	LET rm_venta[i].cant_ven   = r_r20.r20_cant_ven                      
	LET rm_venta[i].item       = r_r20.r20_item
	LET rm_venta[i].descuento  = r_r20.r20_descuento
	LET rm_venta[i].precio     = r_r20.r20_precio
	LET rm_venta[i].total      = r_r20.r20_precio * rm_venta[i].cant_dev 

	LET rm_datos[i].val_dscto  = 
		rm_venta[i].total * (r_r20.r20_descuento / 100)

	LET rm_datos[i].stock_ant  = r_r20.r20_stock_ant 
	LET rm_datos[i].costo	   = r_r20.r20_costo
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	LET rm_datos[i].item       = r_r10.r10_nombre 

	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1

RETURN i

END FUNCTION



FUNCTION muestra_contadores()

IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 
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



FUNCTION muestra_etiquetas(r_r19)

DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*

DISPLAY BY NAME r_r19.r19_ord_trabajo,
		r_r19.r19_moneda,
		r_r19.r19_codcli,
		r_r19.r19_nomcli,
		r_r19.r19_vendedor,
		r_r19.r19_bodega_ori

CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, r_r19.r19_ord_trabajo)
	RETURNING r_t23.*
CALL etiquetas_orden_trabajo(r_t23.*)
CALL setea_nombre_botones()

CALL fl_lee_bodega_rep(vg_codcia, r_r19.r19_bodega_ori) RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO n_bodega

CALL fl_lee_vendedor_rep(vg_codcia, r_r19.r19_vendedor) RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO n_vendedor

END FUNCTION



FUNCTION nextValInSequence()

DEFINE resp		CHAR(6)
DEFINE retVal 		SMALLINT

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
		'AA', vm_transaccion)
IF retVal = 0 THEN
	EXIT PROGRAM
END IF
IF retVal <> -1 THEN
	 EXIT WHILE
END IF

CALL fl_hacer_pregunta('La tabla de secuencias de transacciones está siendo accesada por otro usuario, espere unos segundos y vuelva a intentar','No')
	RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION



FUNCTION setea_nombre_botones()

--#DISPLAY 'Dev'    TO bt_cant_dev 
--#DISPLAY 'Desp'   TO bt_cant_vend
--#DISPLAY 'Item'   TO bt_item    
--#DISPLAY 'Desc'   TO bt_dscto
--#IF vm_tipo_orden = 'P' THEN
	--#DISPLAY 'Precio Unit.' TO bt_precio
--#ELSE
	--#DISPLAY 'Costo Unit.'  TO bt_precio
--#END IF
--#DISPLAY 'Total'  TO bt_total

END FUNCTION



FUNCTION etiquetas_orden_trabajo(r_t23)

DEFINE r_g13		RECORD LIKE gent013.*

DEFINE r_t03		RECORD LIKE talt003.*
DEFINE r_t05		RECORD LIKE talt005.*
DEFINE r_t23		RECORD LIKE talt023.*

DEFINE r_z01		RECORD LIKE cxct001.*

IF r_t23.t23_orden IS NULL THEN
	INITIALIZE rm_r19.r19_codcli,
		   rm_r19.r19_nomcli, 
		   rm_r19.r19_dircli,       
		   rm_r19.r19_telcli,      
		   rm_r19.r19_cedruc,     
		   rm_r19.r19_moneda
		TO NULL
	CLEAR n_chasis, n_placa, n_moneda
ELSE
	CALL fl_lee_moneda(r_t23.t23_moneda) RETURNING r_g13.*
	DISPLAY r_g13.g13_nombre TO n_moneda    

	DISPLAY r_t23.t23_chasis     TO n_chasis
	DISPLAY r_t23.t23_placa      TO n_placa

	CALL fl_lee_tipo_orden_taller(vg_codcia, r_t23.t23_tipo_ot)
		RETURNING r_t05.*
	LET vm_tipo_orden = r_t05.t05_prec_rpto

END IF

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
	IF rm_venta[i].cant_dev IS NOT NULL AND rm_datos[i].costo IS NOT NULL 
	THEN
		LET costo = costo + (rm_datos[i].costo  * rm_venta[i].cant_dev)
	END IF
	IF rm_venta[i].total IS NOT NULL THEN
		LET rm_datos[i].val_dscto = 
			rm_venta[i].total * (rm_venta[i].descuento / 100)
		LET bruto = bruto + rm_venta[i].total
	END IF
	IF rm_datos[i].val_dscto IS NOT NULL THEN
		LET descto = descto + rm_datos[i].val_dscto
	END IF
END FOR

IF rm_r19.r19_tipo_dev = vm_factura THEN
    LET iva    = bruto * (rm_r19.r19_porc_impto / 100)
ELSE
    LET iva = 0
END IF

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
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente','No')
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
DEFINE costo_nue	LIKE rept010.r10_costo_mb

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
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

WHILE (STATUS <> NOTFOUND)
	DELETE FROM rept020 WHERE CURRENT OF q_r20         
	
	INITIALIZE r_r20.* TO NULL
	FETCH q_r20 INTO r_r20.*
END WHILE  
CLOSE q_r20
FREE  q_r20

LET orden = 1
FOR i = 1 TO vm_indice

	IF rm_venta[i].cant_dev = 0 THEN
		CONTINUE FOR
	END IF

	INITIALIZE r_r20.* TO NULL
	LET r_r20.r20_compania  = vg_codcia
	LET r_r20.r20_localidad = vg_codloc
	LET r_r20.r20_cod_tran  = rm_r19.r19_cod_tran
	LET r_r20.r20_num_tran  = rm_r19.r19_num_tran
	LET r_r20.r20_bodega    = rm_datos[i].bodega       
	LET r_r20.r20_item      = rm_venta[i].item       

	-- En r20_cant_ped y r20_cant_ven se graba la cantidad a devolver
	-- En r20_cant_dev y r20_cant_ent se graba cero (0)
	LET r_r20.r20_cant_dev   = 0
	LET r_r20.r20_cant_ent   = 0

	LET r_r20.r20_fecing     = fl_current()

	LET r_r20.r20_orden      = rm_datos[i].orden                  
	LET orden = orden + 1

	LET r_r20.r20_cant_ped   = rm_venta[i].cant_dev   
	LET r_r20.r20_cant_ven   = rm_venta[i].cant_dev

	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	CALL fl_obtiene_costo_item(vg_codcia, rm_r19.r19_moneda,
		r_r20.r20_item, rm_venta[i].cant_dev,
		rm_datos[i].costo)
		RETURNING costo_nue
	LET r_r10.r10_costult_mb  = rm_datos[i].costo
	UPDATE rept010 SET r10_costo_mb		= costo_nue,
                   	   r10_costult_mb	= r_r10.r10_costult_mb
		WHERE r10_compania = vg_codcia AND 
	              r10_codigo   = r_r20.r20_item
	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costant_ma = 0
	LET r_r20.r20_costnue_mb = costo_nue
	LET r_r20.r20_costnue_ma = 0
   
	LET done = actualiza_existencias(i)
	IF NOT done THEN
		RETURN done
	END IF

    	LET r_r20.r20_stock_ant  = rm_datos[i].stock_ant
	LET r_r20.r20_stock_bd   = rm_datos[i].stock_ant 
    	LET r_r20.r20_descuento  = rm_venta[i].descuento
    	LET r_r20.r20_val_descto = rm_datos[i].val_dscto
    	LET r_r20.r20_val_impto  = 
		rm_venta[i].total * (rm_r19.r19_porc_impto / 100)

    	LET r_r20.r20_linea      = r_r10.r10_linea				
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion
	LET r_r20.r20_fob        = r_r10.r10_fob             

	CALL fl_lee_stock_rep(vg_codcia, r_r20.r20_bodega,
		rm_venta[i].item) RETURNING r_r11.*
	LET r_r20.r20_ubicacion  = r_r11.r11_ubicacion

	LET r_r20.r20_precio     = rm_venta[i].precio

	LET r_r20.r20_cant_ent   = 0
	LET r_r20.r20_costo      = rm_datos[i].costo 

	INSERT INTO rept020 VALUES (r_r20.*)
END FOR 

RETURN done

END FUNCTION



FUNCTION actualiza_existencias(i)

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
				AND   r11_bodega    = rm_datos[i].bodega
				AND   r11_item      = rm_venta[i].item
			FOR UPDATE
	OPEN  q_r11
	FETCH q_r11 INTO r_r11.*
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

LET rm_datos[i].stock_ant = r_r11.r11_stock_act

IF r_r11.r11_compania IS NOT NULL THEN
	UPDATE rept011 SET r11_stock_act = r11_stock_act + rm_venta[i].cant_dev,
	     		   r11_ing_dia   = r11_ing_dia   + rm_venta[i].cant_dev
		WHERE CURRENT OF q_r11
ELSE
	LET r_r11.r11_compania  = vg_codcia 
	LET r_r11.r11_bodega    = rm_datos[i].bodega
	LET r_r11.r11_item      = rm_venta[i].item
	LET r_r11.r11_ubicacion = 'SN'
	LET r_r11.r11_stock_ant = 0
	LET r_r11.r11_stock_act = rm_venta[i].cant_dev
	LET r_r11.r11_ing_dia   = rm_venta[i].cant_dev
	LET r_r11.r11_egr_dia   = 0
	INSERT INTO rept011 VALUES(r_r11.*)
END IF
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
FREE  q_r19

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
		IF r_r20.r20_item = rm_venta[i].item THEN
			LET r_r20.r20_cant_dev = 
				r_r20.r20_cant_dev + rm_venta[i].cant_dev
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
DISPLAY ARRAY rm_venta TO ra_venta.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION crea_nota_credito()
DEFINE linea		LIKE rept020.r20_linea
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_glin		RECORD LIKE gent020.*
DEFINE r_nc		RECORD LIKE cxct021.*
DEFINE r		RECORD LIKE gent014.*
DEFINE r_ccred		RECORD LIKE rept025.*
DEFINE num_nc		INTEGER
DEFINE num_row		INTEGER
DEFINE valor_credito	DECIMAL(14,2)	
DEFINE valor_aplicado	DECIMAL(14,2)	

DECLARE q_dfg CURSOR FOR SELECT r20_linea FROM rept020
	WHERE r20_compania  = vg_codcia AND
	      r20_localidad = vg_codloc AND
	      r20_cod_tran  = rm_r19.r19_tipo_dev AND
	      r20_num_tran  = rm_r19.r19_num_dev
OPEN q_dfg
FETCH q_dfg INTO linea
CLOSE q_dfg
FREE q_dfg
CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_lin.*
CALL fl_lee_grupo_linea(vg_codcia, r_lin.r03_grupo_linea)
	RETURNING r_glin.*
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', 'NC')
	RETURNING num_nc
IF num_nc <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
INITIALIZE r_nc.* TO NULL
LET r_nc.z21_compania 	= vg_codcia
LET r_nc.z21_localidad 	= vg_codloc
LET r_nc.z21_codcli 	= rm_r19.r19_codcli 
LET r_nc.z21_tipo_doc 	= 'NC'
LET r_nc.z21_num_doc 	= num_nc 
LET r_nc.z21_areaneg 	= r_glin.g20_areaneg
LET r_nc.z21_referencia = 'DEV. FACTURA: ', rm_r19.r19_tipo_dev, ' ',
			   rm_r19.r19_num_dev USING '<<<<<<<<<<<<<&'
LET r_nc.z21_fecha_emi 	= vg_fecha
LET r_nc.z21_moneda 	= rm_r19.r19_moneda
LET r_nc.z21_paridad 	= 1
IF r_nc.z21_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_nc.z21_moneda, rg_gen.g00_moneda_base)
		RETURNING r.*
	IF r.g14_serial IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No hay factor de conversión.','stop')
		EXIT PROGRAM
	END IF
	LET r_nc.z21_paridad 	= r.g14_tasa
END IF	
LET valor_credito       = rm_r19.r19_tot_neto
LET r_nc.z21_valor 	= valor_credito
LET r_nc.z21_saldo 	= valor_credito
LET r_nc.z21_subtipo 	= 1
LET r_nc.z21_origen 	= 'A'
LET r_nc.z21_usuario 	= vg_usuario
LET r_nc.z21_fecing 	= fl_current()
INSERT INTO cxct021 VALUES (r_nc.*)
LET num_row = SQLCA.SQLERRD[6]
CALL fl_aplica_documento_favor(vg_codcia, vg_codloc, r_nc.z21_codcli, 
			    r_nc.z21_tipo_doc, r_nc.z21_num_doc, valor_credito,
			    r_nc.z21_moneda, r_glin.g20_areaneg,
			    rm_r19.r19_tipo_dev, rm_r19.r19_num_dev)  
	RETURNING valor_aplicado
IF valor_aplicado < 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
UPDATE cxct021 SET z21_saldo = z21_saldo - valor_aplicado
	WHERE ROWID = num_row
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_nc.z21_codcli)

END FUNCTION



FUNCTION consultar_devoluciones()

LET vm_num_rows    = 1
LET vm_row_current = 1

IF vm_dev_tran = 'RQ' OR vm_dev_tran = 'FA' THEN
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
ELSE
	LET vm_num_rows = 1
	SELECT ROWID INTO vm_rows[vm_num_rows] FROM rept019 
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = vm_dev_tran   
		  AND r19_num_tran  = vm_num_tran
	IF STATUS = NOTFOUND THEN
		LET vm_num_rows = vm_num_rows - 1
	END IF
END IF

IF vm_num_rows = 0 THEN
	CALL fl_mostrar_mensaje('No existen devoluciones para esta requisición.','info')
	EXIT PROGRAM
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(255)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
	LET comando = run_prog, 'repp417 ',vg_base, ' ',
			   vg_modulo, ' ', vg_codcia, ' ',
			   vg_codloc, ' ',rm_r19.r19_cod_tran, 
			   rm_r19.r19_num_tran
	RUN comando

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

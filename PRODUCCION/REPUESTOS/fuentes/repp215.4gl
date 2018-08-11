------------------------------------------------------------------------------
-- Titulo           : repp215.4gl - Ingreso de ventas al taller 
-- Elaboracion      : 02-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp215 base modulo compania localidad 
--			[tipo_tran num_tran]
--			Si se reciben 4 parametros se está ejecutando en 
--			modo independiente
--			Si se reciben 6 parametros, se asume que el quinto es
-- 			el codigo de la venta (transaccion origen)
--			y el sexto parametro es el numero de la venta
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_tran	LIKE rept019.r19_num_tran

DEFINE vm_transaccion   LIKE rept019.r19_cod_tran
DEFINE vm_requisicion 	LIKE rept019.r19_cod_tran
DEFINE vm_factura 	LIKE rept019.r19_cod_tran

------------------------------------------------------------------------------
-- Variables que se usaran para identificar a la compañia y a la localidad
-- del taller para las llamadas a funciones que tengan que ver con la orden
-- de trabajo
DEFINE vm_codcia	SMALLINT
DEFINE vm_codloc	SMALLINT
------------------------------------------------------------------------------

DEFINE vm_filas_pant	SMALLINT

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
DEFINE rm_venta ARRAY[50] OF RECORD
	cant_ped		LIKE rept020.r20_cant_ped, 
	cant_ven		LIKE rept020.r20_cant_ven, 
	item			LIKE rept020.r20_item, 
	descuento		LIKE rept020.r20_descuento,
	precio			LIKE rept020.r20_precio, 
	total			LIKE rept019.r19_tot_bruto
END RECORD

DEFINE rm_datos ARRAY[50] OF RECORD
	item  	 		LIKE rept010.r10_nombre,
	costo			LIKE rept020.r20_costo,		-- COSTO ITEM
	val_dscto		LIKE rept020.r20_val_descto,
	stock_ant		LIKE rept020.r20_stock_ant
END RECORD

-- Flag que indica si los repuestos de la orden de trabajo salen al
-- precio de venta al público(P) o al costo (C)
DEFINE vm_tipo_orden		LIKE talt005.t05_prec_rpto

-- Bandera que me permitirá saber si debo actualizar el registo
-- de la cabecera
DEFINE vm_update_flag       SMALLINT

-- Registro de la tabla de configuración del módulo de repuestos
DEFINE rm_r00			RECORD LIKE rept000.*

-- Registro de la tabla de configuración del módulo de talleres
DEFINE rm_t00		RECORD LIKE talt000.* 

-- Registro de la tabla de configuración de tipos de O.T.
DEFINE rm_t05		RECORD LIKE talt005.* 



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp215.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp215'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
			        -- que luego puede ser reemplazado si se 
                            	-- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

INITIALIZE vm_transaccion TO NULL
LET vm_num_tran = 0
IF num_args() = 6 THEN
	LET vm_transaccion = arg_val(5)
	LET vm_num_tran    = arg_val(6)
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
OPEN WINDOW w_215 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_215 FROM '../forms/repf215_1'
ELSE
	OPEN FORM f_215 FROM '../forms/repf215_1c'
END IF
DISPLAY FORM f_215

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r19.* TO NULL

LET vm_tipo_orden = 'P'

CALL muestra_contadores()
CALL setea_nombre_botones()

LET vm_max_rows = 1000


CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe registro de configuración para esta compañía.','exclamation')
	EXIT PROGRAM
END IF

-- LEE CONFIGURACION TALLER PARA FLAG REQUISICIONES
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
IF rm_t00.t00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe registro de configuración para esta compañía.','exclamation')
	EXIT PROGRAM
END IF

-- OjO
LET vm_requisicion = 'RQ'
LET vm_factura     = 'FA'

IF num_args() <> 6 THEN
	IF vg_codcia = rm_r00.r00_cia_taller THEN
    		LET vm_transaccion = vm_requisicion
		LET vm_codcia = vg_codcia
		LET vm_codloc = vg_codloc
	ELSE
    		LET vm_transaccion = vm_factura
		LET vm_codcia = rm_r00.r00_cia_taller
		SELECT g02_localidad INTO vm_codloc 
			FROM gent002
			WHERE g02_compania = vm_codcia
			  AND g02_matriz   = 'S' 
	END IF
END IF
--

IF num_args() = 6 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Devoluciones'
		HIDE OPTION 'Imprimir'
		IF vm_num_tran <> 0 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			IF vm_indice > vm_filas_pant THEN
				SHOW OPTION 'Detalle'
			END IF
                	IF rm_r19.r19_tipo_dev IS NOT NULL THEN
                		SHOW OPTION 'Devoluciones'
                	END IF
                	SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			IF vm_indice > vm_filas_pant THEN
				SHOW OPTION 'Detalle'
			END IF
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
			IF vm_indice > vm_filas_pant THEN
				SHOW OPTION 'Detalle'
			END IF
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Imprimir'	
		HIDE OPTION 'Detalle'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
                IF rm_r19.r19_tipo_dev IS NOT NULL THEN
                	SHOW OPTION 'Devoluciones'
                END IF
		IF vm_indice > vm_filas_pant THEN
			SHOW OPTION 'Detalle'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('D') 'Detalle'		'Ver detalle de venta'
		CALL control_mostrar_det()
	COMMAND KEY('E') 'Devoluciones'         'Ver devoluciones.'
		CALL ver_devolucion()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Devoluciones'
		HIDE OPTION 'Detalle'
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
                IF rm_r19.r19_tipo_dev IS NOT NULL THEN
                	SHOW OPTION 'Devoluciones'
                END IF
		IF vm_indice > vm_filas_pant THEN
			SHOW OPTION 'Detalle'
		END IF
                IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Devoluciones'
		HIDE OPTION 'Detalle'
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
                IF rm_r19.r19_tipo_dev IS NOT NULL THEN
                	SHOW OPTION 'Devoluciones'
                END IF
		IF vm_indice > vm_filas_pant THEN
			SHOW OPTION 'Detalle'
		END IF
                IF vm_num_rows > 0 THEN
                	SHOW OPTION 'Imprimir'
                END IF
        COMMAND KEY('P') 'Imprimir'		'Imprime comprobante.'
        	CALL imprimir()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_g13		RECORD LIKE gent013.*

DEFINE rowid   		INTEGER
DEFINE intentar		SMALLINT
DEFINE done		SMALLINT

CLEAR FORM
INITIALIZE rm_r19.* TO NULL

LET vm_update_flag = 0

-- THESE VALUES WON'T CHANGE 
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
LET rm_r19.r19_cod_tran   = vm_transaccion
LET rm_r19.r19_flete      = 0
LET rm_r19.r19_descuento  = 0
LET rm_r19.r19_porc_impto = 0
LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_fecing     = fl_current()
LET rm_r19.r19_bodega_ori = rm_r00.r00_bodega_fact

CALL muestra_etiquetas()

IF vm_transaccion = vm_factura THEN
	LET rm_r19.r19_cont_cred  = 'R'
ELSE
	LET rm_r19.r19_cont_cred  = 'C'
END IF

 

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
		        WHERE t23_compania  = vm_codcia
		          AND t23_localidad = vm_codloc
		          AND t23_orden     = rm_r19.r19_ord_trabajo
	        FOR UPDATE
	OPEN q_t23
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
	FREE q_t23
	IF vm_num_rows = 0 THEN
		CLEAR FORM
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
	FREE  q_t23
	RETURN
END IF

LET rm_r19.r19_bodega_dest = rm_r19.r19_bodega_ori

LET rm_r19.r19_num_tran = nextValInSequence()
IF rm_r19.r19_num_tran = -1 THEN
	ROLLBACK WORK
	CLEAR FORM
	RETURN
END IF

IF rm_r19.r19_cod_tran = vm_factura THEN
	LET rm_r19.r19_porc_impto = rg_gen.g00_porc_impto
END IF

INSERT INTO rept019 VALUES (rm_r19.*)
DISPLAY BY NAME rm_r19.r19_num_tran

LET rowid = SQLCA.SQLERRD[6]		-- Rowid de la ultima fila
					-- procesada
LET done = graba_detalle(r_t23.*)
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

IF vm_update_flag THEN
    LET done = actualiza_cabecera()
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
END IF

LET r_t23.t23_val_rp_alm  = r_t23.t23_val_rp_alm + rm_r19.r19_tot_bruto
CALL fl_totaliza_orden_taller(r_t23.*) RETURNING r_t23.*

UPDATE talt023 SET 
    t23_val_rp_alm = r_t23.t23_val_rp_alm,
    t23_vde_rp_alm = r_t23.t23_vde_rp_alm,
    t23_tot_bruto  = r_t23.t23_tot_bruto,
    t23_tot_dscto  = r_t23.t23_tot_dscto,
    t23_val_impto  = r_t23.t23_val_impto,
    t23_tot_neto   = r_t23.t23_tot_neto
WHERE CURRENT OF q_t23
CLOSE q_t23
FREE  q_t23
IF vm_transaccion = vm_factura THEN
	IF vg_codcia = rm_r00.r00_cia_taller THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('La transacción es una factura, y la compañía del Taller no debe ser la misma que Inventario.','stop')
		EXIT PROGRAM
	END IF
	IF rm_r00.r00_codcli_tal IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No está configurado el código de cliente para la compañía del Taller.','stop')
		EXIT PROGRAM
	END IF
	CALL genera_cuenta_por_cobrar()
	CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, rm_r00.r00_codcli_tal)
END IF	
CALL fl_actualiza_estadisticas_item_rep(vg_codcia, vg_codloc, 
			rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
	RETURNING done
IF NOT done THEN
	ROLLBACK WORK
	EXIT PROGRAM
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

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_t05		RECORD LIKE talt005.*
DEFINE r_t23		RECORD LIKE talt023.*

LET INT_FLAG = 0
INPUT BY NAME rm_r19.r19_cod_tran, rm_r19.r19_ord_trabajo, rm_r19.r19_vendedor,
	      rm_r19.r19_bodega_ori, rm_r19.r19_usuario, rm_r19.r19_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r19_ord_trabajo, 
				     r19_vendedor,
				     r19_bodega_ori
                                    ) THEN
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
		IF INFIELD(r19_ord_trabajo) THEN
			CALL fl_ayuda_orden_trabajo(vm_codcia, vm_codloc, 'A') 
				RETURNING r_t23.t23_orden,
					  r_t23.t23_nom_cliente
			IF r_t23.t23_orden IS NOT NULL THEN
				LET rm_r19.r19_ord_trabajo = r_t23.t23_orden
				DISPLAY BY NAME rm_r19.r19_ord_trabajo
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
	BEFORE INPUT
		CALL setea_nombre_botones()
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r19_ord_trabajo
		IF rm_r19.r19_ord_trabajo IS NULL THEN
			INITIALIZE r_t23.* TO NULL
			CALL etiquetas_orden_trabajo(r_t23.*)
			CONTINUE INPUT
		END IF

		CALL fl_lee_orden_trabajo(vm_codcia, vm_codloc, 
			rm_r19.r19_ord_trabajo) RETURNING r_t23.*
		IF r_t23.t23_orden IS NULL THEN
			CALL fl_mostrar_mensaje('Orden de trabajo no existe.','exclamation')
			INITIALIZE r_t23.* TO NULL
			CALL etiquetas_orden_trabajo(r_t23.*)
			NEXT FIELD r19_ord_trabajo
		END IF

  		CALL fl_lee_tipo_orden_taller(vm_codcia, r_t23.t23_tipo_ot)
  			RETURNING r_t05.*
  		LET vm_tipo_orden = r_t05.t05_prec_rpto

		IF r_t23.t23_estado <> 'A' THEN
			CALL fl_mostrar_mensaje('Orden de trabajo no está activa.','exclamation')
			INITIALIZE r_t23.* TO NULL
			CALL etiquetas_orden_trabajo(r_t23.*)
			NEXT FIELD r19_ord_trabajo
		END IF
		IF rm_r00.r00_compania = rm_r00.r00_cia_taller  AND
		   rm_t00.t00_req_tal  = 'N' AND 
		   r_t05.t05_factura   = 'S' THEN
			CALL fl_mostrar_mensaje('Debido a Configuración General no se pueden hacer requisiciones contra órdenes que se facturan.','exclamation')
			NEXT FIELD r19_ord_trabajo
		END IF
		CALL etiquetas_orden_trabajo(r_t23.*)
		CALL setea_nombre_botones()
	AFTER FIELD r19_vendedor
		IF rm_r19.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation')
				CLEAR n_vendedor
				NEXT FIELD r19_vendedor
			END IF 
			IF r_r01.r01_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Vendedor está bloqueado.','exclamation')
				CLEAR n_vendedor
				NEXT FIELD r19_vendedor
			END IF
			DISPLAY r_r01.r01_nombres TO n_vendedor
		ELSE
			CLEAR n_vendedor
		END IF		 
	AFTER FIELD r19_bodega_ori
		IF rm_r19.r19_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF 
			IF r_r02.r02_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Bodega está bloqueada.','exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF
			DISPLAY r_r02.r02_nombre TO n_bodega
		ELSE
			CLEAR n_bodega
		END IF
END INPUT

END FUNCTION


FUNCTION ingresa_detalle(r_tal)

DEFINE resp 		CHAR(6)
DEFINE i    		SMALLINT
DEFINE j    		SMALLINT
DEFINE k    		SMALLINT
DEFINE salir		SMALLINT

DEFINE linea		LIKE rept020.r20_linea
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE valor_tope	LIKE talt023.t23_valor_tope

DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_tal		RECORD LIKE talt023.*

LET vm_indice = lee_detalle()

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
		ON KEY(F2)
			IF INFIELD(r20_item) THEN
                		CALL fl_ayuda_maestro_items_stock_sinlinea(
					vg_codcia,
					rm_r19.r19_bodega_ori)
                     			RETURNING r_r10.r10_codigo,  
						  r_r10.r10_nombre,
					  	  r_r11.r11_bodega,  
						  r_r10.r10_linea,
					  	  r_r10.r10_precio_mb,
						  stock 
                     		IF r_r10.r10_codigo IS NOT NULL THEN
					LET rm_venta[i].item = r_r10.r10_codigo
					DISPLAY rm_venta[i].item 
						TO ra_venta[j].r20_item
				END IF
        	        END IF
			LET INT_FLAG = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			DISPLAY rm_datos[i].item TO descripcion
		AFTER FIELD r20_item
	    		IF rm_venta[i].item IS NULL THEN
				CLEAR descripcion
				INITIALIZE rm_venta[i].precio,
					   rm_venta[i].descuento,
					   rm_venta[i].total
					TO NULL
				CLEAR ra_venta[j].r20_precio,
				      ra_venta[j].r20_descuento,
				      ra_venta[j].total
				CONTINUE INPUT
			END IF
     			CALL fl_lee_item(vg_codcia, rm_venta[i].item)
				RETURNING r_r10.*
                	IF r_r10.r10_codigo IS NULL THEN
						CALL fl_mostrar_mensaje('El item no existe.','exclamation')
                       	NEXT FIELD r20_item
                	END IF
               		IF r_r10.r10_estado = 'B' THEN
						CALL fl_mostrar_mensaje('El item está bloqueado.','exclamation')
                       	NEXT FIELD r20_item
                	END IF
		--------------------------------------------------------------
		----------- PARA LA VALIDACION DE ITEMS REPETIDOS ------------
			FOR k = 1 TO arr_count()
				IF rm_venta[i].item = rm_venta[k].item 
				AND i <> k
				THEN
					CALL fl_mostrar_mensaje('No puede ingresar items repetidos.','exclamation')
					NEXT FIELD r20_item
               			END IF
			END FOR
		-------------------------------------------------------------
		--- PARA CONOCER EL STOCK DEL ITEM EN LA BODEGA INGRESADA ---
			LET stock = control_stock(rm_venta[i].item)
			IF stock > rm_venta[i].cant_ped THEN
				LET rm_venta[i].cant_ven = 
					rm_venta[i].cant_ped
			ELSE
				LET rm_venta[i].cant_ven = stock
			END IF
		-------------------------------------------------------------
			---- ASIGNO VALORES SI TODO OK. ----
			LET rm_datos[i].item      = r_r10.r10_nombre
			IF rg_gen.g00_moneda_base = rm_r19.r19_moneda THEN
				LET rm_datos[i].costo = r_r10.r10_costo_mb
			ELSE	
				IF rg_gen.g00_moneda_alt = rm_r19.r19_moneda 
				THEN
					LET rm_datos[i].costo = 
						r_r10.r10_costo_ma
				ELSE
					LET rm_datos[i].costo =
						r_r10.r10_costo_mb *
						calcula_paridad(
							rg_gen.g00_moneda_base,
							rm_r19.r19_moneda) 
				END IF
			END IF	
			
			IF vm_tipo_orden = 'C' THEN
				LET rm_venta[i].precio = rm_datos[i].costo
				LET rm_venta[i].descuento = 0
			ELSE
				IF rg_gen.g00_moneda_base = rm_r19.r19_moneda 
				THEN
					LET rm_venta[i].precio = 
						r_r10.r10_precio_mb
				ELSE	
					IF rg_gen.g00_moneda_alt = 
						rm_r19.r19_moneda 
					THEN
						LET rm_venta[i].precio = 
							r_r10.r10_precio_ma
					ELSE
						LET rm_venta[i].precio =
							r_r10.r10_precio_mb *
							calcula_paridad(
							rg_gen.g00_moneda_base,
							rm_r19.r19_moneda) 
					END IF
				END IF	
				CALL fl_lee_linea_rep(vg_codcia, 
					r_r10.r10_linea)
					RETURNING r_r03.*
				LET rm_venta[i].descuento = r_r03.r03_dcto_tal
			END IF
			IF vg_codcia = rm_r00.r00_cia_taller THEN
			    LET rm_venta[i].descuento = 0
			END IF
		------------------------------------------------------------
		---- PARA CONTROLAR QUE EL PRECIO SEA MAYOR A CERO ----
			IF rm_venta[i].precio <= 0 THEN
				CALL fl_mostrar_mensaje('El item no puede ser facturado porque su precio es igual a cero.','exclamation') 
				NEXT FIELD r20_item
			END IF
		---------------------------------------------------------
			LET rm_venta[i].total = 
				rm_venta[i].cant_ven * rm_venta[i].precio
			LET rm_datos[i].val_dscto = 
			    rm_venta[i].total * (rm_venta[i].descuento / 100)
			CALL calcula_totales(arr_count(), r_tal.*) 
				RETURNING valor_tope
			DISPLAY rm_venta[i].* TO ra_venta[j].*
			DISPLAY rm_datos[i].item TO descripcion
		AFTER FIELD r20_cant_ped
			IF rm_venta[i].item IS NOT NULL	
			AND rm_venta[i].cant_ped IS NULL  
			THEN
				NEXT FIELD r20_cant_ped
			END IF
			IF rm_venta[i].cant_ped IS NULL THEN
				INITIALIZE rm_venta[i].total TO NULL
				CLEAR ra_venta[j].total
				CALL calcula_totales(arr_count(), r_tal.*) 
					RETURNING valor_tope
				CONTINUE INPUT
			END IF
		--- PARA CONOCER EL STOCK DEL ITEM EN LA BODEGA INGRESADA ---
			IF rm_venta[i].item IS NOT NULL THEN
				LET stock = control_stock(rm_venta[i].item)
				IF stock > rm_venta[i].cant_ped THEN
					LET rm_venta[i].cant_ven = 
						rm_venta[i].cant_ped
				ELSE
					LET rm_venta[i].cant_ven = stock
				END IF
			ELSE
				INITIALIZE rm_venta[i].cant_ven TO NULL
				CLEAR ra_venta[j].r20_cant_ven
			END IF
		-------------------------------------------------------------
			LET rm_venta[i].total = 
				rm_venta[i].cant_ven * rm_venta[i].precio
			CALL calcula_totales(arr_count(), r_tal.*) 
				RETURNING valor_tope
			DISPLAY rm_venta[i].* TO ra_venta[j].*
			DISPLAY rm_datos[i].item TO descripcion
		BEFORE DELETE
			CALL deleteRow(i, arr_count())
		AFTER DELETE	
			CALL calcula_totales(arr_count(), r_tal.*) 
				RETURNING valor_tope
		BEFORE INSERT
			INITIALIZE rm_datos[i].* TO NULL
		AFTER INPUT
			LET vm_indice = arr_count()
			IF calcula_totales(vm_indice, r_tal.*) > 
				r_tal.t23_valor_tope 
			THEN
				CALL fl_mostrar_mensaje('El total neto excede el valor tope de la orden de trabajo.','exclamation')
                        		CONTINUE INPUT
			END IF
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
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE mensaje		VARCHAR(100)

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON r19_cod_tran, r19_num_tran, r19_ord_trabajo, r19_vendedor, 
	   r19_bodega_ori, r19_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_ord_trabajo) THEN
			CALL fl_ayuda_orden_trabajo(vm_codcia, vm_codloc, 'A') 
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
			IF rm_r19.r19_cod_tran <> vm_requisicion 
			AND rm_r19.r19_cod_tran <> vm_factura
			THEN
				LET mensaje ='El código de la transacción debe ser ' || vm_requisicion || ' o ' || vm_factura || '.'
				CALL fl_mostrar_mensaje(mensaje,'exclamation')
                NEXT FIELD r19_cod_tran
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
	    '	  AND r19_cod_tran = "', vm_factura,     '"',
	    '	  AND r19_ord_trabajo IS NOT NULL ', 
	    '	  AND ', expr_sql CLIPPED,
	    'UNION ALL ',
	    'SELECT *, ROWID FROM rept019 ',
	    '	WHERE r19_compania  = ', vg_codcia, 
	    '	  AND r19_localidad = ', vg_codloc,
	    '	  AND r19_cod_tran = "', vm_requisicion, '" ',
	    '	  AND r19_ord_trabajo IS NOT NULL ', 
	    '	  AND ', expr_sql CLIPPED

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r19.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
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

IF rm_r19.r19_cod_tran = vm_factura THEN
	LET vm_codcia = rm_r00.r00_cia_taller
	SELECT g02_localidad INTO vm_codloc FROM gent002
		WHERE g02_compania = vm_codcia AND g02_matriz = 'S'
ELSE
	LET vm_codcia = vg_codcia
	LET vm_codloc = vg_codloc
END IF

CALL muestra_etiquetas()
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
LET vm_filas_pant = filas_pant

FOR i = 1 TO filas_pant 
	INITIALIZE rm_venta[i].* TO NULL
	CLEAR ra_venta[i].*
END FOR

LET i = lee_detalle()
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



FUNCTION lee_detalle()

DEFINE i		SMALLINT
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*

DECLARE q_det CURSOR FOR
	SELECT * FROM rept020
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc  
		  AND r20_cod_tran  = rm_r19.r19_cod_tran
		  AND r20_num_tran  = rm_r19.r19_num_tran
	ORDER BY r20_orden

LET i = 1
FOREACH q_det INTO r_r20.* 
	LET rm_venta[i].cant_ped   = r_r20.r20_cant_ped
	LET rm_venta[i].cant_ven   = r_r20.r20_cant_ven
	LET rm_venta[i].item       = r_r20.r20_item
	LET rm_venta[i].descuento  = r_r20.r20_descuento
	LET rm_venta[i].precio     = r_r20.r20_precio
	LET rm_venta[i].total      = r_r20.r20_precio * r_r20.r20_cant_ven 

	LET rm_datos[i].val_dscto  = r_r20.r20_val_descto
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



FUNCTION muestra_etiquetas()

DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*

CALL fl_lee_orden_trabajo(vm_codcia, vm_codloc, rm_r19.r19_ord_trabajo)
	RETURNING r_t23.*
CALL etiquetas_orden_trabajo(r_t23.*)
CALL setea_nombre_botones()

CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori) RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO n_bodega

CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor) RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO n_vendedor

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE veht036.v36_moneda
DEFINE moneda_dest	LIKE veht036.v36_moneda
DEFINE paridad		LIKE veht036.v36_paridad_mb

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION nextValInSequence()

DEFINE resp		CHAR(6)
DEFINE retVal 		INTEGER

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

--#DISPLAY 'Cant'   TO bt_cant_ped
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
	CLEAR cod_mecanico, n_mecanico, n_moneda
ELSE
	IF vm_transaccion = vm_factura THEN
		IF rm_r00.r00_codcli_tal IS NULL THEN
			CALL fl_mostrar_mensaje('No se ha configurado un cliente para ventas entre compañías.','stop')
			EXIT PROGRAM
		END IF
		LET rm_r19.r19_codcli      = rm_r00.r00_codcli_tal
	ELSE
		LET rm_r19.r19_codcli      = r_t23.t23_cod_cliente
	END IF
	CALL fl_lee_cliente_general(rm_r19.r19_codcli) RETURNING r_z01.*
	LET rm_r19.r19_dircli      = r_z01.z01_direccion1	
	LET rm_r19.r19_cedruc      = r_z01.z01_num_doc_id
	LET rm_r19.r19_nomcli      = r_z01.z01_nomcli
	LET rm_r19.r19_telcli      = r_z01.z01_telefono1  

	CALL fl_lee_mecanico(vm_codcia, r_t23.t23_cod_mecani) RETURNING r_t03.*
	DISPLAY r_t23.t23_cod_mecani TO cod_mecanico
	DISPLAY r_t03.t03_nombres    TO n_mecanico

	CALL fl_lee_moneda(r_t23.t23_moneda) RETURNING r_g13.*
	LET rm_r19.r19_moneda      = r_g13.g13_moneda
	LET rm_r19.r19_precision   = r_g13.g13_decimales
	LET rm_r19.r19_paridad     = calcula_paridad(rm_r19.r19_moneda,
						     rg_gen.g00_moneda_base)
	DISPLAY r_g13.g13_nombre TO n_moneda    

	CALL fl_lee_tipo_orden_taller(vm_codcia, r_t23.t23_tipo_ot)
		RETURNING r_t05.*
	LET vm_tipo_orden = r_t05.t05_prec_rpto

END IF

DISPLAY BY NAME rm_r19.r19_codcli,
		rm_r19.r19_nomcli, 
		rm_r19.r19_moneda

END FUNCTION



FUNCTION control_stock(item)

DEFINE item 		LIKE rept020.r20_item

DEFINE r_r11		RECORD LIKE rept011.*

CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori, item) RETURNING r_r11.*
IF r_r11.r11_stock_act IS NULL THEN
	LET r_r11.r11_stock_act = 0
END IF
RETURN r_r11.r11_stock_act

END FUNCTION



FUNCTION calcula_totales(num_elm, r_t23)

DEFINE num_elm		SMALLINT
DEFINE i      	 	SMALLINT

DEFINE costo 		LIKE rept019.r19_tot_costo
DEFINE bruto		LIKE rept019.r19_tot_bruto
DEFINE precio		LIKE rept019.r19_tot_neto  
DEFINE descto       	LIKE rept019.r19_tot_dscto
	
DEFINE iva          	LIKE rept019.r19_tot_dscto

DEFINE r_t23		RECORD LIKE talt023.*

LET costo     = 0	-- TOTAL COSTO 
LET precio    = 0	-- TOTAL NETO  
LET descto    = 0 	-- TOTAL DESCUENTO
LET bruto     = 0 	-- TOTAL BRUTO     

FOR i = 1 TO num_elm
	IF rm_venta[i].cant_ven IS NOT NULL AND rm_datos[i].costo IS NOT NULL 
	THEN
		LET costo = costo + (rm_datos[i].costo  * rm_venta[i].cant_ven)
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

IF rm_r19.r19_cod_tran = vm_factura THEN
    LET iva    = bruto * (rm_r19.r19_porc_impto / 100)
ELSE
    LET iva = 0
END IF

LET precio = (bruto - descto) + iva

LET rm_r19.r19_tot_dscto  = descto
LET rm_r19.r19_tot_bruto  = bruto
LET rm_r19.r19_tot_neto   = precio
LET rm_r19.r19_tot_costo  = costo

LET r_t23.t23_val_rp_alm  = r_t23.t23_val_rp_alm + rm_r19.r19_tot_bruto
CALL fl_totaliza_orden_taller(r_t23.*) RETURNING r_t23.*

DISPLAY BY NAME rm_r19.r19_tot_bruto,
                rm_r19.r19_tot_dscto,
                iva,
                rm_r19.r19_tot_neto
                
RETURN r_t23.t23_tot_neto  

END FUNCTION



FUNCTION deleteRow(i, num_rows)

DEFINE i		SMALLINT
DEFINE num_rows		SMALLINT

WHILE (i < num_rows)
	LET rm_datos[i].* = rm_datos[i + 1].*
	LET i = i + 1
END WHILE
INITIALIZE rm_datos[i].* TO NULL

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



FUNCTION graba_detalle(r_t23)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE i		SMALLINT

DEFINE dummy        	LIKE talt023.t23_valor_tope

DEFINE r_t23        	RECORD LIKE talt023.*
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
	OPEN q_r20
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

WHILE (STATUS <> NOTFOUND)
	DELETE FROM rept020 WHERE CURRENT OF q_r20         

	INITIALIZE r_r20.* TO NULL
	FETCH q_r20 INTO r_r20.*
END WHILE  

LET r_r20.r20_compania  = vg_codcia
LET r_r20.r20_localidad = vg_codloc
LET r_r20.r20_cod_tran  = rm_r19.r19_cod_tran
LET r_r20.r20_num_tran  = rm_r19.r19_num_tran

LET r_r20.r20_cant_dev   = 0
LET r_r20.r20_costant_mb = 0
LET r_r20.r20_costant_ma = 0
LET r_r20.r20_costnue_mb = 0
LET r_r20.r20_costnue_ma = 0

LET r_r20.r20_fecing     = fl_current()

FOR i = 1 TO vm_indice
	LET r_r20.r20_orden      = i                      

	LET done = actualiza_existencias(i)
	IF NOT done THEN
		LET rm_venta[i].cant_ven  = 0
        	LET rm_venta[i].total     = 0
        	LET rm_datos[i].val_dscto = 0
        	LET vm_update_flag = 1
		CALL calcula_totales(vm_indice, r_t23.*) RETURNING dummy
	END IF

	LET r_r20.r20_cant_ven   = rm_venta[i].cant_ven
    	LET r_r20.r20_stock_ant  = rm_datos[i].stock_ant
    	LET r_r20.r20_stock_bd   = rm_datos[i].stock_ant
    	LET r_r20.r20_descuento  = rm_venta[i].descuento
    	LET r_r20.r20_val_descto = rm_datos[i].val_dscto
    	LET r_r20.r20_val_impto  = 
		rm_venta[i].total * (rm_r19.r19_porc_impto / 100)

	LET r_r20.r20_cant_ped   = rm_venta[i].cant_ped   

    	CALL fl_lee_item(vg_codcia, rm_venta[i].item) RETURNING r_r10.*
    	LET r_r20.r20_linea      = r_r10.r10_linea				
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion
	LET r_r20.r20_fob        = r_r10.r10_fob             

	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori, 
		rm_venta[i].item) RETURNING r_r11.*
	LET r_r20.r20_ubicacion  = r_r11.r11_ubicacion

	LET r_r20.r20_bodega     = rm_r19.r19_bodega_ori
	LET r_r20.r20_item       = rm_venta[i].item       
	LET r_r20.r20_precio     = rm_venta[i].precio

	LET r_r20.r20_cant_ent   = 0
	LET r_r20.r20_costo      = rm_datos[i].costo 

	INSERT INTO rept020 VALUES (r_r20.*)
END FOR 
LET done = 1

RETURN done

END FUNCTION



FUNCTION actualiza_existencias(i)

DEFINE i        	SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(100)

DEFINE r_r11		RECORD LIKE rept011.*

LET intentar = 1
LET done = 0

WHILE (intentar)
	INITIALIZE r_r11.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r11 CURSOR FOR
			SELECT * FROM rept011
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = rm_r19.r19_bodega_ori
				  AND r11_item     = rm_venta[i].item
			FOR UPDATE
	OPEN q_r11
	FETCH q_r11 INTO r_r11.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_r11
		FREE  q_r11
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

	LET rm_datos[i].stock_ant = r_r11.r11_stock_act

	IF r_r11.r11_stock_act < rm_venta[i].cant_ven THEN
		LET mensaje =
			'Ha ocurrido una disminución en el stock del item '|| 
			rm_venta[i].item || '. No se puede realizar la ' ||
			'transacción. '
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		LET done = 0
		CLOSE q_r11
		RETURN done
	END IF

	UPDATE rept011 SET 
		r11_stock_ant = r11_stock_act,
		r11_stock_act = r11_stock_act - rm_venta[i].cant_ven,
     		r11_egr_dia   = rm_venta[i].cant_ven
	WHERE CURRENT OF q_r11
CLOSE q_r11
FREE q_r11

RETURN done

END FUNCTION



FUNCTION actualiza_cabecera()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_r19		RECORD LIKE rept019.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r19.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r19 CURSOR FOR
			SELECT * FROM rept019
				WHERE r19_compania  = vg_codcia         
				  AND r19_localidad = vg_codloc          
				  AND r19_cod_tran  = rm_r19.r19_cod_tran
				  AND r19_num_tran  = rm_v19.v19_num_tran
			FOR UPDATE
	OPEN q_r19
	FETCH q_r19 INTO r_r19.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_r19
		FREE  q_r19
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

UPDATE rept019 SET * = rm_r19.* WHERE CURRENT OF q_r19

CLOSE q_r19
FREE  q_r19

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



FUNCTION genera_cuenta_por_cobrar()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r		RECORD LIKE gent014.*
DEFINE linea		LIKE rept020.r20_linea
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_glin		RECORD LIKE gent020.*
DEFINE r_cli		RECORD LIKE cxct002.*

WHENEVER ERROR STOP
CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r00.r00_codcli_tal)
	RETURNING r_cli.*
IF r_cli.z02_compania IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Cliente no existe en cxct002.','stop')
	EXIT PROGRAM
END IF
IF r_cli.z02_credit_dias = 0 THEN
	LET r_cli.z02_credit_dias = 30
END IF
	
DECLARE q_dfg CURSOR FOR SELECT r20_linea FROM rept020
	WHERE r20_compania  = vg_codcia AND
	      r20_localidad = vg_codloc AND
	      r20_cod_tran  = rm_r19.r19_cod_tran AND
	      r20_num_tran  = rm_r19.r19_num_tran
OPEN q_dfg
FETCH q_dfg INTO linea
CLOSE q_dfg
FREE q_dfg
CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_lin.*
CALL fl_lee_grupo_linea(vg_codcia, r_lin.r03_grupo_linea)
	RETURNING r_glin.*
INITIALIZE r_doc.* TO NULL
LET r_doc.z20_compania	= vg_codcia
LET r_doc.z20_localidad = vg_codloc
LET r_doc.z20_codcli 	= rm_r00.r00_codcli_tal
LET r_doc.z20_tipo_doc 	= vm_transaccion
LET r_doc.z20_num_doc 	= rm_r19.r19_num_tran
LET r_doc.z20_dividendo = 1
LET r_doc.z20_areaneg 	= r_glin.g20_areaneg
LET r_doc.z20_referencia= NULL
LET r_doc.z20_fecha_emi = vg_fecha
LET r_doc.z20_fecha_vcto= vg_fecha + r_cli.z02_credit_dias
LET r_doc.z20_tasa_int  = 0
LET r_doc.z20_tasa_mora = 0
LET r_doc.z20_moneda 	= rm_r19.r19_moneda
LET r_doc.z20_paridad 	= 1
IF r_doc.z20_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_doc.z20_moneda, rg_gen.g00_moneda_base)
		RETURNING r.*
	IF r.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('No hay factor de conversión.','stop')
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_doc.z20_paridad 	= r.g14_tasa
END IF	
LET r_doc.z20_valor_cap = rm_r19.r19_tot_neto
LET r_doc.z20_valor_int = 0
LET r_doc.z20_saldo_cap = rm_r19.r19_tot_neto
LET r_doc.z20_saldo_int = 0
LET r_doc.z20_cartera 	= 1
LET r_doc.z20_linea 	= r_lin.r03_grupo_linea
LET r_doc.z20_origen 	= 'A'
LET r_doc.z20_cod_tran  = rm_r19.r19_cod_tran
LET r_doc.z20_num_tran  = rm_r19.r19_num_tran
LET r_doc.z20_usuario 	= vg_usuario
LET r_doc.z20_fecing 	= fl_current()
INSERT INTO cxct020 VALUES (r_doc.*)

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = vm_transaccion
	  AND r19_num_tran  = vm_num_tran
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe requisición.','exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION ver_devolucion()
DEFINE comando		CHAR(255)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp219 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran, ' ',
	rm_r19.r19_num_tran
	
RUN comando	

END FUNCTION



FUNCTION imprimir()
DEFINE comando		CHAR(255)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp414 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran,
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

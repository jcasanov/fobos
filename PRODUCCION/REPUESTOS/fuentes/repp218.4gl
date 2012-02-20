-----------------------------------------------------------------------------
-- Titulo           : repp218.4gl - Devolución de compras locales  
-- Elaboracion      : 14-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp218 base modulo compania localidad
--			Si se reciben 4 parametros se está ejecutando en 
--			modo independiente
--			Si se reciben 6 parametros, se asume que el quinto es
-- 			el codigo de la compra local (transaccion origen)
--			y el sexto parametro es el numero de la compra local
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
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
DEFINE rm_r19, rm_cl	RECORD LIKE rept019.* 

DEFINE vm_indice	SMALLINT
DEFINE vm_max_ventas	SMALLINT
DEFINE rm_compra ARRAY[1000] OF RECORD
	cant_dev		LIKE rept020.r20_cant_ped, 
	cant_ven		LIKE rept020.r20_cant_ven, 
	item			LIKE rept020.r20_item, 
	descuento		LIKE rept020.r20_descuento,
	precio			LIKE rept020.r20_precio, 
	total			LIKE rept019.r19_tot_bruto
END RECORD

DEFINE rm_datos ARRAY[1000] OF RECORD
	bodega 	 		LIKE rept020.r20_bodega,
	item  	 		LIKE rept010.r10_nombre,
	orden  	 		LIKE rept020.r20_orden,
	costo			LIKE rept020.r20_costo,		-- COSTO ITEM
	val_dscto		LIKE rept020.r20_val_descto,
	stock_ant		LIKE rept020.r20_stock_ant,
	costo_ant		LIKE rept020.r20_costant_mb
END RECORD

-- Registro de la tabla de configuración del módulo de repuestos
DEFINE rm_r00			RECORD LIKE rept000.*
DEFINE rm_c10			RECORD LIKE ordt010.*
DEFINE vm_fact_nue		LIKE rept019.r19_oc_externa
DEFINE vm_cruce			SMALLINT
DEFINE vm_cod_tran_ne	LIKE rept019.r19_cod_tran



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp218.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 7 AND num_args() <> 8
THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp218'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
			        -- que luego puede ser reemplazado si se 
                            	-- mantiene sin comentario la siguiente linea

INITIALIZE vm_dev_tran TO NULL
LET vm_num_tran = 0
IF num_args() >= 6 THEN
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
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
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
OPEN WINDOW w_218 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_218 FROM '../forms/repf218_1'
ELSE
	OPEN FORM f_218 FROM '../forms/repf218_1c'
END IF
DISPLAY FORM f_218

LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_cod_tran_ne = 'NE'
INITIALIZE rm_r19.* TO NULL

CALL muestra_contadores()
CALL setea_nombre_botones()

LET vm_max_rows   = 1000
LET vm_max_ventas = 1000


CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe registro de configuración para esta compañía.','exclamation')
	CALL fl_mostrar_mensaje('No existe registro de configuración para esta compañía.','exclamation')
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
	--CALL fgl_winmessage(vg_producto,'No se ha configurado un código de devolución para este tipo de transacciones.','stop')
	CALL fl_mostrar_mensaje('No se ha configurado un código de devolución para este tipo de transacciones.','stop')
	EXIT PROGRAM
END IF
--

IF num_args() >= 6 THEN
	LET vm_dev_tran = arg_val(5)
	CALL consultar_devoluciones()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Compra Local'		
		HIDE OPTION 'Imprimir'		
		IF vm_num_tran <> 0 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			IF vm_num_rows > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
			HIDE OPTION 'Detalle'
			HIDE OPTION 'Compra Local'		
                	HIDE OPTION 'Imprimir'
			CALL control_mostrar_det()
			EXIT PROGRAM
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Compra Local'		
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
			SHOW OPTION 'Compra Local'		
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Compra Local'		
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
			SHOW OPTION 'Compra Local'		
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('D') 'Detalle' 'Ver detalle de devolución.'
		CALL control_mostrar_det()
        COMMAND KEY('L') 'Compra Local' 'Muestra la Compra Local.'
		CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
					rm_r19.r19_tipo_dev, rm_r19.r19_num_dev)
        COMMAND KEY('P') 'Imprimir' 'Imprime la Devolución Compra Local.'
        	CALL imprimir()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro.'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Compra Local'		
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
			SHOW OPTION 'Compra Local'		
			SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('R') 'Retroceder' 'Ver anterior registro.'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Compra Local'		
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
			SHOW OPTION 'Compra Local'		
                	SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_r41		RECORD LIKE rept041.*

DEFINE r_g13		RECORD LIKE gent013.*

DEFINE i 		SMALLINT
DEFINE rowid   		INTEGER
DEFINE done		SMALLINT

DEFINE valor_aplicado	DECIMAL(14,2)

DEFINE fecha_actual DATETIME YEAR TO SECOND

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

LET vm_cruce = 0

BEGIN WORK

CALL lee_datos()
IF INT_FLAG THEN
	ROLLBACK WORK
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
	ROLLBACK WORK
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

LET fecha_actual = fl_current()

UPDATE ordt010 SET c10_estado = 'E' 
	WHERE c10_compania  = rm_c10.c10_compania  AND 
	      c10_localidad = rm_c10.c10_localidad AND 
	      c10_numero_oc = rm_c10.c10_numero_oc
UPDATE ordt013 SET c13_estado = 'E',
		   c13_fecha_eli = fecha_actual
	WHERE c13_compania  = rm_c10.c10_compania  AND 
	      c13_localidad = rm_c10.c10_localidad AND 
	      c13_numero_oc = rm_c10.c10_numero_oc
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

IF vm_cruce THEN
	UPDATE tmp_r41
		SET r41_cod_tran = rm_r19.r19_cod_tran,
		    r41_num_tran = rm_r19.r19_num_tran
		WHERE 1 = 1

	INSERT INTO rept041 SELECT * FROM tmp_r41

	DROP TABLE tmp_r41
END IF
	
COMMIT WORK
CALL fl_control_master_contab_repuestos(rm_r19.r19_compania, 
	rm_r19.r19_localidad, rm_r19.r19_cod_tran, rm_r19.r19_num_tran)

DECLARE q_cont_ne CURSOR FOR
	SELECT * FROM rept041
		WHERE r41_compania  = rm_r19.r19_compania
		  AND r41_localidad = rm_r19.r19_localidad
		  AND r41_cod_tran  = rm_r19.r19_cod_tran
		  AND r41_num_tran  = rm_r19.r19_num_tran
		ORDER BY r41_num_tr ASC
FOREACH q_cont_ne INTO r_r41.*
	CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc,
											r_r41.r41_cod_tr, r_r41.r41_num_tr)
END FOREACH

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_rows[vm_num_rows] = rowid
LET vm_row_current = vm_num_rows

CALL cambiar_numero_fact()

CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE pago		DECIMAL(14,2)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE aux_fact		LIKE rept019.r19_oc_externa

LET vm_fact_nue = NULL
LET INT_FLAG = 0
INPUT BY NAME rm_r19.r19_cod_tran, rm_r19.r19_tipo_dev, rm_r19.r19_num_dev, 
	rm_r19.r19_oc_externa, rm_r19.r19_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_r19.r19_tipo_dev, rm_r19.r19_num_dev,
					rm_r19.r19_oc_externa) 
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
		LET rm_cl.* = r_r19.*
		IF r_r19.r19_oc_interna IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'La transacción no está asociada a una orden de compra.','exclamation')
			CALL fl_mostrar_mensaje('La transacción no está asociada a una orden de compra.','exclamation')
			INITIALIZE r_r19.* TO NULL 
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		IF vg_fecha > (date(r_r19.r19_fecing) + rm_r00.r00_dias_dev) THEN
			--CALL fgl_winmessage(vg_producto,'Ha excedido el limite de tiempo permitido para realizar devoluciones.','exclamation')
			CALL fl_mostrar_mensaje('Ha excedido el limite de tiempo permitido para realizar devoluciones.','exclamation')
			INITIALIZE r_r19.* TO NULL 
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		IF rm_r00.r00_dev_mes = 'S' THEN
			IF month(r_r19.r19_fecing) <> month(vg_fecha) THEN
				--CALL fgl_winmessage(vg_producto,'La devolución debe realizarse en el mismo mes en que se realizó la venta.','exclamation')
				CALL fl_mostrar_mensaje('La devolución debe realizarse en el mismo mes en que se realizó la venta.','exclamation')
				INITIALIZE r_r19.* TO NULL 
				CALL muestra_etiquetas(r_r19.*)
				NEXT FIELD r19_num_dev
			END IF
		END IF
		-- Valida si los items recibidos han sido afectados por 
		-- alguna transacción
		IF items_alterados(r_r19.*) THEN
			CALL fl_mostrar_mensaje('Algunos items de esta compra local tienen stock insuficiente o su costo promedio ha variado por otra transacción y no se podra realizar la devolución.','exclamation')
			INITIALIZE r_r19.* TO NULL
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		IF tiene_nota_de_entrega(r_r19.*) THEN
			CALL fl_mostrar_mensaje('Uno o Alguno de los items de esta compra local tiene(n) nota de entrega y no se podra realizar la REVERSA del CRUCE AUTOMATICO.', 'exclamation')
			INITIALIZE r_r19.* TO NULL
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
			r_r19.r19_oc_interna) RETURNING rm_c10.*
		IF rm_c10.c10_numero_oc IS NULL THEN
			CALL fl_mostrar_mensaje('Orden de compra no existe.','exclamation')
			INITIALIZE r_r19.* TO NULL
			CALL muestra_etiquetas(r_r19.*)
			NEXT FIELD r19_num_dev
		END IF
		DISPLAY BY NAME rm_c10.c10_flete, rm_c10.c10_otros,
			        rm_c10.c10_dif_cuadre
		IF r_r19.r19_cont_cred = 'R' THEN
			SELECT NVL(SUM((p20_valor_cap + p20_valor_int) -
				(p20_saldo_cap + p20_saldo_int)), 0)
				INTO pago
				FROM cxpt020
				WHERE p20_compania  = r_r19.r19_compania
				  AND p20_localidad = r_r19.r19_localidad
				  AND p20_codprov   = rm_c10.c10_codprov
				  AND p20_num_doc   = r_r19.r19_oc_externa
				  AND p20_numero_oc = r_r19.r19_oc_interna
			IF pago <> 0 THEN
				CALL fl_mostrar_mensaje('Esta compra local no puede ser devuelta, porque ha sido parcial o totalmente pagada.', 'exclamation')
				NEXT FIELD r19_num_dev
			END IF
		END IF
		LET rm_r19.r19_tipo_dev    = vm_dev_tran
		LET rm_r19.r19_cont_cred   = r_r19.r19_cont_cred
		LET rm_r19.r19_descuento   = r_r19.r19_descuento
		LET rm_r19.r19_porc_impto  = r_r19.r19_porc_impto
		LET rm_r19.r19_oc_interna  = r_r19.r19_oc_interna 
		LET aux_fact               = r_r19.r19_oc_externa
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
	{--
	AFTER INPUT
		LET rm_r19.r19_oc_externa = rm_r19.r19_oc_externa CLIPPED
		IF rm_r19.r19_oc_externa IS NULL THEN
			NEXT FIELD r19_oc_externa
		END IF
		IF rm_r19.r19_oc_externa = aux_fact THEN
			CALL fl_mostrar_mensaje('Cambie el numero de factura para generar esta devolucion.','exclamation')
			NEXT FIELD r19_oc_externa
		END IF
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
					rm_c10.c10_codprov, 'FA',
					rm_r19.r19_oc_externa, 1)
			RETURNING r_p20.*
		IF r_p20.p20_num_doc IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Esta factura ya existe para este provedor.','exclamation')
			NEXT FIELD r19_oc_externa
		END IF
		LET vm_fact_nue           = rm_r19.r19_oc_externa
		LET rm_r19.r19_oc_externa = aux_fact
	--}
END INPUT

END FUNCTION



FUNCTION ingresa_detalle()

DEFINE resp 		CHAR(6)
DEFINE i    		SMALLINT
DEFINE j    		SMALLINT
DEFINE salir		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
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
	--CALL fgl_winmessage(vg_producto,'Esta compra local ya ha sido devuelta por completo.','exclamation')
	CALL fl_mostrar_mensaje('Esta compra local ya ha sido devuelta por completo.','exclamation')
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
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel('DELETE', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			CALL calcula_totales(vm_indice) 
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_etiquetas_det(i, vm_indice, i)
		AFTER FIELD r20_cant_dev
			IF rm_compra[i].cant_dev <> rm_compra[i].cant_ven THEN
				LET rm_compra[i].cant_dev =
						rm_compra[i].cant_ven
				DISPLAY rm_compra[i].cant_dev TO
					ra_compra[j].r20_cant_dev
			END IF
			IF rm_compra[i].cant_dev IS NULL THEN
				CALL calcula_totales(vm_indice) 
				NEXT FIELD r20_cant_dev
			END IF
			IF rm_compra[i].cant_dev > rm_compra[i].cant_ven THEN
				--CALL fgl_winmessage(vg_producto,'La cantidad a devolver debe ser menor o igual a la cantidad despachada.','exclamation')
				CALL fl_mostrar_mensaje('La cantidad a devolver debe ser menor o igual a la cantidad despachada.','exclamation')
				NEXT FIELD r20_cant_dev
			END IF
		-------------------------------------------------------------
			LET rm_compra[i].total = 
				rm_compra[i].cant_dev * rm_compra[i].precio
			LET rm_datos[i].val_dscto =
			       rm_compra[i].total * (rm_compra[i].descuento/100)
			CALL calcula_totales(vm_indice) 
			DISPLAY rm_compra[i].* TO ra_compra[j].*
			DISPLAY rm_datos[i].item TO nom_item
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
				--CALL fgl_winmessage(vg_producto,'Deben devolverse todos los items.','exclamation') 
				CALL fl_mostrar_mensaje('Deben devolverse todos los items.','exclamation') 
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
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(600)

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_c10		RECORD LIKE ordt010.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON r19_num_tran, r19_num_dev, r19_oc_interna, r19_oc_externa, 
	   r19_fact_venta, r19_bodega_ori
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
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
				0, 0, 'C', vg_modulo, 'S')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				LET rm_r19.r19_oc_interna = r_c10.c10_numero_oc
				DISPLAY BY NAME rm_r19.r19_oc_interna
			END IF
		END IF
		IF INFIELD(r19_bodega_ori) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', '1', 'R', 'S', 'V')
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
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
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
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna) 
	RETURNING rm_c10.*
LET iva = (rm_r19.r19_tot_neto - rm_r19.r19_tot_bruto) + rm_r19.r19_tot_dscto - 
	 	      rm_c10.c10_dif_cuadre - rm_c10.c10_flete - 
		      rm_c10.c10_otros

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
		rm_r19.r19_fecing
DISPLAY BY NAME rm_c10.c10_flete, rm_c10.c10_otros, rm_c10.c10_dif_cuadre
CALL muestra_etiquetas(rm_r19.*)
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

LET filas_pant = fgl_scr_size('ra_compra')
{
IF vg_gui = 0 THEN
	LET filas_pant = 4
END IF
}
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
CALL muestra_etiquetas_det(0, vm_indice, 1)

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
	--LET rm_compra[i].cant_dev   = 0                   
	LET rm_compra[i].cant_ven   = r_r20.r20_cant_ven - r_r20.r20_cant_dev
	LET rm_compra[i].cant_dev   = rm_compra[i].cant_ven
	LET rm_compra[i].item       = r_r20.r20_item
	LET rm_compra[i].descuento  = r_r20.r20_descuento
	LET rm_compra[i].precio     = r_r20.r20_precio
	LET rm_compra[i].total      = 0                                        

	LET rm_datos[i].bodega      = r_r20.r20_bodega
	LET rm_datos[i].orden       = r_r20.r20_orden
	LET rm_datos[i].val_dscto   = 0

	LET rm_datos[i].stock_ant  = r_r20.r20_stock_ant 
	LET rm_datos[i].costo_ant  = r_r20.r20_costant_mb
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
	IF i > vm_max_ventas THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1

RETURN i

END FUNCTION



FUNCTION muestra_contadores()

IF vg_gui = 1 THEN
	DISPLAY "" AT 1, 1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 63
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

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_c10		RECORD LIKE ordt010.*

DISPLAY BY NAME r_r19.r19_oc_interna,
		r_r19.r19_moneda,
		r_r19.r19_bodega_ori,
		r_r19.r19_vendedor

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
DEFINE retVal 		INTEGER

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

--CALL fgl_winquestion(vg_producto,'La tabla de secuencias de transacciones está siendo accesada por otro usuario, espere unos segundos y vuelva a intentar','No','Yes|No|Cancel','question',1)
CALL fl_hacer_pregunta('La tabla de secuencias de transacciones está siendo accesada por otro usuario, espere unos segundos y vuelva a intentar','No')
	RETURNING resp 
IF resp <> 'Yes' THEN
	EXIT WHILE	
END IF

END WHILE

RETURN retVal

END FUNCTION



FUNCTION setea_nombre_botones()

--#DISPLAY 'Dev'    		TO bt_cant_dev 
--#DISPLAY 'Cant'   		TO bt_cant_vend
--#DISPLAY 'Item'   		TO bt_item    
--#DISPLAY 'Desc'  		TO bt_dscto
--#DISPLAY 'Precio Unit.'	TO bt_precio
--#DISPLAY 'Total'		TO bt_total

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
DEFINE cant_dev 	LIKE rept020.r20_cant_ven
DEFINE cant_ven  	LIKE rept020.r20_cant_ven

LET costo     = 0	-- TOTAL COSTO 
LET precio    = 0	-- TOTAL NETO  
LET descto    = 0 	-- TOTAL DESCUENTO
LET bruto     = 0 	-- TOTAL BRUTO     

LET cant_dev = 0
LET cant_ven = 0
FOR i = 1 TO num_elm
	LET cant_dev = cant_dev + rm_compra[i].cant_dev
	LET cant_ven = cant_ven + rm_compra[i].cant_ven
	{
	IF rm_compra[i].cant_dev IS NOT NULL AND rm_datos[i].costo IS NOT NULL 
	THEN
		LET costo = costo + (rm_datos[i].costo  * rm_compra[i].cant_dev)
	END IF
	}
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
IF cant_ven = cant_dev THEN
	LET descto = rm_cl.r19_tot_dscto
	LET bruto  = rm_cl.r19_tot_bruto
	LET precio = rm_cl.r19_tot_neto
        LET iva    = (rm_cl.r19_tot_neto - bruto) + descto - 
	 	      rm_c10.c10_dif_cuadre - rm_c10.c10_flete - 
		      rm_c10.c10_otros
END IF
LET rm_r19.r19_tot_dscto  = descto
LET rm_r19.r19_tot_bruto  = bruto
LET rm_r19.r19_tot_neto   = precio
LET rm_r19.r19_tot_costo  = rm_c10.c10_dif_cuadre

DISPLAY BY NAME rm_r19.r19_tot_bruto,
                rm_r19.r19_tot_dscto,
                iva,
                rm_r19.r19_tot_neto
                
END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
--CALL fgl_winquestion(vg_producto,'Registro bloqueado por otro usuario, desea intentarlo nuevamente','No','Yes|No','question',1)
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

DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r20		RECORD LIKE rept020.*

INITIALIZE r_r20.* TO NULL

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

LET r_r20.r20_fecing     = fl_current()

LET orden = 1
FOR i = 1 TO vm_indice
	IF rm_compra[i].cant_dev = 0 THEN
		CONTINUE FOR
	END IF
	LET r_r20.r20_item       = rm_compra[i].item       
	LET r_r20.r20_bodega     = rm_datos[i].bodega                      
	LET r_r20.r20_orden      = rm_datos[i].orden                      
	LET orden = orden + 1

	LET r_r20.r20_cant_ped   = rm_compra[i].cant_dev   
	LET r_r20.r20_cant_ven   = rm_compra[i].cant_dev
    	CALL fl_lee_item(vg_codcia, rm_compra[i].item) RETURNING r_r10.*
	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
	LET r_r20.r20_costnue_mb = rm_datos[i].costo_ant
	LET r_r20.r20_costnue_ma = 0
	--UPDATE rept010 SET r10_costo_mb   = rm_datos[i].costo_ant,
	UPDATE rept010 SET r10_costo_mb   = r_r20.r20_costnue_mb,
		           r10_costult_mb = r_r10.r10_costo_mb
		WHERE r10_compania = vg_codcia AND 
		      --r10_codigo   = rm_datos[i].item
		      r10_codigo   = r_r20.r20_item
	CALL fl_lee_stock_rep(vg_codcia, r_r20.r20_bodega, 
		rm_compra[i].item) RETURNING r_r11.*
    	LET r_r20.r20_stock_ant  = r_r11.r11_stock_act
    	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act
   
	LET done = actualiza_existencias(i)
	IF NOT done THEN
		RETURN done
	END IF

    	LET r_r20.r20_descuento  = rm_compra[i].descuento
    	LET r_r20.r20_val_descto = rm_datos[i].val_dscto
    	LET r_r20.r20_val_impto  = 
		rm_compra[i].total * (rm_r19.r19_porc_impto / 100)

	LET r_r20.r20_bodega     = rm_datos[i].bodega       
    	LET r_r20.r20_linea      = r_r10.r10_linea				
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion
	LET r_r20.r20_fob        = r_r10.r10_fob             

	LET r_r20.r20_ubicacion  = r_r11.r11_ubicacion

	LET r_r20.r20_precio     = rm_compra[i].precio

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
DEFINE mensaje		CHAR(70)
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
				AND   r11_item      = rm_compra[i].item
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
LET r_r11.r11_stock_act = r_r11.r11_stock_act - rm_compra[i].cant_dev
IF r_r11.r11_stock_act < 0 THEN
	ROLLBACK WORK
	LET mensaje = 'ERROR: El item ', rm_compra[i].item CLIPPED,
			' tiene stock insuficiente.' 
	CALL fl_mostrar_mensaje(mensaje,'stop')
	EXIT PROGRAM
END IF

UPDATE rept011 SET r11_stock_act = r11_stock_act - rm_compra[i].cant_dev,
	           r11_egr_dia   = r11_egr_dia   + rm_compra[i].cant_dev
	WHERE CURRENT OF q_r11

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
DEFINE i, j		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

LET i = 0
IF vg_gui = 0 THEN
	LET i = 1
END IF
CALL muestra_contadores_det(i, vm_indice)
CALL set_count(vm_indice)
DISPLAY ARRAY rm_compra TO ra_compra.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		IF num_args() <> 8 THEN
			--CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
			--		rm_r19.r19_tipo_dev, rm_r19.r19_num_dev)
			CALL ver_compra_local(rm_r19.r19_tipo_dev,
						rm_r19.r19_num_dev)
		END IF
		LET int_flag = 0
	ON KEY(F6)
		CALL imprimir()
		LET int_flag = 0
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL muestra_etiquetas_det(i, vm_indice, i)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel("RETURN","")
		--#IF num_args() = 8 THEN
			--#CALL dialog.keysetlabel("F5","")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","Compra Local")
		--#END IF
		--#CALL dialog.keysetlabel("F6","Imprimir")
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_etiquetas_det(i, vm_indice, i)
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_indice)

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

IF NOT proceso_cruce_de_bodegas(r_r19.*) THEN
	--RETURN 1
END IF

SELECT COUNT(*) INTO contador
	FROM rept020, rept011, rept010
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = r_r19.r19_cod_tran
	  AND r20_num_tran  = r_r19.r19_num_tran
	  AND r11_compania  = r20_compania
	  AND r11_bodega    = r_r19.r19_bodega_ori
	  AND r11_item      = r20_item
	  --AND r11_stock_act = r20_stock_ant + r20_cant_ven
	  AND r11_stock_act >= r20_cant_ven
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



FUNCTION tiene_nota_de_entrega(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE contador		SMALLINT

SELECT * FROM rept041, rept019, rept020
	WHERE r41_compania      = r_r19.r19_compania
	  AND r41_localidad     = r_r19.r19_localidad
	  AND r41_cod_tran      = r_r19.r19_cod_tran
	  AND r41_num_tran      = r_r19.r19_num_tran
	  AND r19_compania      = r41_compania
	  AND r19_localidad     = r41_localidad
	  AND r19_cod_tran      = r41_cod_tr
	  AND r19_num_tran      = r41_num_tr
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_tipo_dev
	  AND r20_num_tran      = r19_num_dev
	INTO TEMP tmp_t1
SELECT COUNT(r37_item)
	INTO contador
	FROM tmp_t1, rept034, rept036, rept037
	WHERE r34_compania      = r20_compania
          AND r34_localidad     = r20_localidad
          AND r34_cod_tran      = r20_cod_tran
          AND r34_num_tran      = r20_num_tran
          AND r36_compania      = r34_compania
          AND r36_localidad     = r34_localidad
          AND r36_bodega        = r34_bodega
          AND r36_num_ord_des   = r34_num_ord_des
	  AND r36_estado        = "A"
	  AND r36_fecing       >= r20_fecing
	  AND r37_compania      = r36_compania
	  AND r37_localidad     = r36_localidad
	  AND r37_bodega        = r36_bodega
	  AND r37_num_entrega   = r36_num_entrega
	  AND r37_item          = r20_item
	  AND EXISTS (SELECT 1 FROM rept020
			WHERE r20_compania  = r_r19.r19_compania
			  AND r20_localidad = r_r19.r19_localidad
			  AND r20_cod_tran  = r_r19.r19_cod_tran
			  AND r20_num_tran  = r_r19.r19_num_tran
			  AND r20_item      = r37_item)
DROP TABLE tmp_t1
IF contador > 0 THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION rebaja_deuda()

DEFINE i		SMALLINT

DEFINE num_row		INTEGER
DEFINE num_row_nc	INTEGER
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

LET r_p21.p21_referencia   = 'DEVOLUCION (COMPRA LOCAL) # ',
			     rm_r19.r19_num_tran USING '<<<<<<<<&'
LET r_p21.p21_fecha_emi    = vg_fecha
LET r_p21.p21_moneda       = rm_r19.r19_moneda
LET r_p21.p21_paridad      = rm_r19.r19_paridad
LET r_p21.p21_valor        = rm_r19.r19_tot_neto
LET r_p21.p21_saldo        = rm_r19.r19_tot_neto
LET r_p21.p21_subtipo      = 1
LET r_p21.p21_origen       = 'A'
LET r_p21.p21_usuario      = vg_usuario
LET r_p21.p21_fecing       = fl_current()

INSERT INTO cxpt021 VALUES(r_p21.*)
LET num_row_nc = SQLCA.SQLERRD[6]

-- Para aplicar la nota de credito

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
LET r_caju.p22_referencia 	= 'DEV. COMPRA LOCAL # ',
					rm_r19.r19_num_tran USING '<<<<<<<<&'
LET r_caju.p22_fecha_emi 	= vg_fecha
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
LET r_caju.p22_fecing 		= fl_current()

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
UPDATE cxpt021 SET p21_saldo = p21_saldo - valor_aplicado
	WHERE ROWID = num_row_nc
CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, r_p21.p21_codprov)
FREE q_ddev
RETURN valor_aplicado

END FUNCTION



FUNCTION consultar_devoluciones()
DEFINE query		CHAR(400)

LET vm_num_rows    = 1
LET vm_row_current = 1

LET query = 'SELECT *, ROWID FROM rept019 ',
		' WHERE r19_compania  = ', vg_codcia,
		'   AND r19_localidad = ', vg_codloc
IF num_args() >= 7 THEN
	LET query = query CLIPPED, 
		    ' AND r19_tipo_dev  = "', vm_dev_tran, '"',
		    ' AND r19_num_dev   = ', vm_num_tran,
		    ' ORDER BY 1, 2, 3, 4'
ELSE
	LET query = query CLIPPED, 
		    ' AND r19_cod_tran  = "', vm_dev_tran, '"',
		    ' AND r19_num_tran  = ', vm_num_tran,
		    ' ORDER BY 1, 2, 3, 4'
END IF		  
PREPARE dev2 FROM query
DECLARE q_dev2 CURSOR FOR dev2
FOREACH q_dev2 INTO rm_r19.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
FREE q_dev2

LET vm_num_rows = vm_num_rows - 1

IF vm_num_rows = 0 THEN
	--CALL fgl_winmessage(vg_producto,'No existen devoluciones para esta compra local.','info')
	CALL fl_mostrar_mensaje('No existen devoluciones para esta compra local.','info')
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
	CALL fl_mostrar_mensaje('No se pudo completar el proceso, por favor espere unos segundos y vuelva a intentarlo.','exclamation')
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
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp416 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran,
	rm_r19.r19_num_tran
	
RUN comando	

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_r03.*
CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r72.r72_desc_clase TO descrip_4

END FUNCTION



FUNCTION muestra_etiquetas_det(i, ind1, ind2)
DEFINE i, ind1, ind2	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, ind1)
CALL fl_lee_item(vg_codcia, rm_compra[ind2].item) RETURNING r_r10.*  
CALL muestra_descripciones(rm_compra[ind2].item, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
DISPLAY r_r10.r10_nombre TO nom_item 

END FUNCTION



FUNCTION ver_compra_local(tipo_dev, num_dev)
DEFINE tipo_dev		LIKE rept019.r19_tipo_dev
DEFINE num_dev		LIKE rept019.r19_num_dev
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'repp214 ',
		vg_base, ' "', vg_modulo, '" ', vg_codcia, ' ', vg_codloc,
		' "', tipo_dev, '" ', num_dev, ' "C"'
RUN comando

END FUNCTION



FUNCTION cambiar_numero_fact()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE i, lim		INTEGER

LET i   = 1
LET lim = LENGTH(rm_r19.r19_oc_externa)
CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, rm_c10.c10_codprov, 'FA',
				rm_r19.r19_oc_externa, 1)
	RETURNING r_p20.*
WHILE TRUE
	LET vm_fact_nue = r_p20.p20_num_doc[1, 3],
				r_p20.p20_num_doc[5, lim] CLIPPED,
				i USING "<<<<<<&"
	CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
					rm_c10.c10_codprov, 'FA',
					vm_fact_nue, 1)
		RETURNING r_p20.*
	IF r_p20.p20_compania IS NULL THEN
		EXIT WHILE
	END IF
	LET lim = LENGTH(vm_fact_nue)
	LET i   = i + 1
END WHILE
BEGIN WORK
IF rm_r19.r19_num_dev IS NOT NULL THEN
	UPDATE rept019
		SET r19_oc_externa = vm_fact_nue
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = rm_r19.r19_cod_tran
		  AND r19_num_tran  = rm_r19.r19_num_tran
	UPDATE rept019
		SET r19_oc_externa = vm_fact_nue
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = rm_r19.r19_tipo_dev
		  AND r19_num_tran  = rm_r19.r19_num_dev
END IF
UPDATE ordt010
	SET c10_factura = vm_fact_nue
	WHERE c10_compania  = vg_codcia
	  AND c10_localidad = vg_codloc
	  AND c10_numero_oc = rm_r19.r19_oc_interna
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING r_c10.*
UPDATE ordt013
	SET c13_factura  = vm_fact_nue,
	    c13_num_guia = vm_fact_nue
	WHERE c13_compania  = vg_codcia
	  AND c13_localidad = vg_codloc
	  AND c13_numero_oc = rm_r19.r19_oc_interna
	  AND c13_estado    = 'E'
	  --AND c13_num_recep = 1
DECLARE q_p23 CURSOR FOR
	SELECT * FROM cxpt023
		WHERE p23_compania  = vg_codcia
	          AND p23_localidad = vg_codloc
	          AND p23_codprov   = r_c10.c10_codprov
	          AND p23_tipo_doc  = 'FA'
	          AND p23_num_doc   = rm_r19.r19_oc_externa
OPEN q_p23
FETCH q_p23 INTO r_p23.*
IF STATUS = NOTFOUND THEN
	UPDATE cxpt020
		SET p20_num_doc = vm_fact_nue
		WHERE p20_compania  = vg_codcia
	          AND p20_localidad = vg_codloc
	          AND p20_codprov   = r_c10.c10_codprov
	          AND p20_tipo_doc  = 'FA'
	          AND p20_num_doc   = rm_r19.r19_oc_externa
	COMMIT WORK
	RETURN
END IF
SELECT * FROM cxpt020
	WHERE p20_compania  = vg_codcia
          AND p20_localidad = vg_codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = rm_r19.r19_oc_externa
	INTO TEMP tmp_p20
UPDATE tmp_p20
	SET p20_num_doc = vm_fact_nue
	WHERE p20_compania  = vg_codcia
          AND p20_localidad = vg_codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = rm_r19.r19_oc_externa
INSERT INTO cxpt020 SELECT * FROM tmp_p20
DROP TABLE tmp_p20
UPDATE cxpt023
	SET p23_num_doc = vm_fact_nue
	WHERE p23_compania  = vg_codcia
          AND p23_localidad = vg_codloc
          AND p23_codprov   = r_c10.c10_codprov
          AND p23_tipo_doc  = 'FA'
          AND p23_num_doc   = rm_r19.r19_oc_externa
UPDATE cxpt025
	SET p25_num_doc = vm_fact_nue
	WHERE p25_compania  = vg_codcia
          AND p25_localidad = vg_codloc
          AND p25_codprov   = r_c10.c10_codprov
          AND p25_tipo_doc  = 'FA'
          AND p25_num_doc   = rm_r19.r19_oc_externa
UPDATE cxpt028
	SET p28_num_doc = vm_fact_nue
	WHERE p28_compania  = vg_codcia
          AND p28_localidad = vg_codloc
          AND p28_codprov   = r_c10.c10_codprov
          AND p28_tipo_doc  = 'FA'
          AND p28_num_doc   = rm_r19.r19_oc_externa
UPDATE cxpt041
	SET p41_num_doc = vm_fact_nue
	WHERE p41_compania  = vg_codcia
          AND p41_localidad = vg_codloc
          AND p41_codprov   = r_c10.c10_codprov
          AND p41_tipo_doc  = 'FA'
          AND p41_num_doc   = rm_r19.r19_oc_externa
DELETE FROM cxpt020
	WHERE p20_compania  = vg_codcia
          AND p20_localidad = vg_codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = rm_r19.r19_oc_externa
COMMIT WORK

END FUNCTION



FUNCTION proceso_cruce_de_bodegas(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r41		RECORD LIKE rept041.*
DEFINE r_trans		RECORD LIKE rept019.*
DEFINE resp		CHAR(6)

IF vm_cruce THEN
	RETURN 1
END IF
INITIALIZE r_r41.* TO NULL
DECLARE q_trans CURSOR FOR
	SELECT b.*
		FROM rept041 b, rept019 c
		WHERE b.r41_compania  = r_r19.r19_compania
		  AND b.r41_localidad = r_r19.r19_localidad
		  AND b.r41_cod_tran  = r_r19.r19_cod_tran
		  AND b.r41_num_tran  = r_r19.r19_num_tran
		  AND c.r19_compania  = b.r41_compania
		  AND c.r19_localidad = b.r41_localidad
		  AND c.r19_cod_tran  = b.r41_cod_tr
		  AND c.r19_num_tran  = b.r41_num_tr
		  AND NOT EXISTS
			(SELECT 1 FROM rept019 a
				WHERE a.r19_compania    = c.r19_compania
				  AND a.r19_localidad   = c.r19_localidad
				  AND a.r19_cod_tran    = vm_cod_tran_ne
				  AND a.r19_tipo_dev    = c.r19_tipo_dev
				  AND a.r19_num_dev     = c.r19_num_dev
				  AND a.r19_bodega_ori  = c.r19_bodega_dest
				  AND a.r19_bodega_dest = c.r19_bodega_ori)
OPEN q_trans
FETCH q_trans INTO r_r41.*
IF r_r41.r41_compania IS NULL THEN
	CLOSE q_trans
	FREE q_trans
	CALL fl_mostrar_mensaje('Ya se han hecho anulado las transferencias de cruce en otro proceso de INVENTARIO.', 'info') 
	RETURN 0
END IF
CALL fl_hacer_pregunta('Desea DESHACER transferencias de CRUCE AUTOMATICO ?',
			'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	CLOSE q_trans
	FREE q_trans
	RETURN 0
END IF
LET vm_cruce = 1
SELECT * FROM rept041 WHERE r41_compania = 999 INTO TEMP tmp_r41
FOREACH q_trans INTO r_r41.*
	CALL fl_lee_cabecera_transaccion_rep(r_r41.r41_compania,
					r_r41.r41_localidad, r_r41.r41_cod_tr,
					r_r41.r41_num_tr)
		RETURNING r_trans.*
	CALL transferir_item_bod_ss_bod_res(r_trans.*)
END FOREACH
CALL fl_lee_cabecera_transaccion_rep(r_r41.r41_compania, r_r41.r41_localidad,
					r_r41.r41_cod_tran, r_r41.r41_num_tran)
		RETURNING r_trans.*
CALL fl_mostrar_mensaje('Transferencias para DESHACER CRUCE de BODEGA "SIN STOCK" con la bodega ' || r_trans.r19_bodega_ori CLIPPED || ' generadas OK.', 'info')
RETURN 1

END FUNCTION



FUNCTION transferir_item_bod_ss_bod_res(r_trans)
DEFINE r_trans		RECORD LIKE rept019.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_trans_d	RECORD LIKE rept020.*
DEFINE stock_act	LIKE rept011.r11_stock_act
DEFINE mensaje		VARCHAR(200)

INITIALIZE r_r19.* TO NULL
LET r_r19.r19_compania		= vg_codcia
LET r_r19.r19_localidad   	= vg_codloc
LET r_r19.r19_cod_tran    	= vm_cod_tran_ne
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA',
					r_r19.r19_cod_tran)
	RETURNING r_r19.r19_num_tran
IF r_r19.r19_num_tran = 0 THEN
	ROLLBACK WORK	
	CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
	EXIT PROGRAM
END IF
IF r_r19.r19_num_tran = -1 THEN
	SET LOCK MODE TO WAIT
	WHILE r_r19.r19_num_tran = -1
		CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 
							vg_modulo, 'AA',
							r_r19.r19_cod_tran)
			RETURNING r_r19.r19_num_tran
	END WHILE
	SET LOCK MODE TO NOT WAIT
END IF
LET r_r19.r19_cont_cred		= 'C'
LET r_r19.r19_referencia	= 'TR. AUTO. POR CL # ',
				  rm_cl.r19_num_tran USING "<<<<<<&",
				  ' DEV.COMP. LOC.'
LET r_r19.r19_nomcli		= ' '
LET r_r19.r19_dircli     	= ' '
LET r_r19.r19_cedruc     	= ' '
LET r_r19.r19_vendedor   	= r_trans.r19_vendedor
LET r_r19.r19_descuento  	= 0.0
LET r_r19.r19_porc_impto 	= 0.0
LET r_r19.r19_tipo_dev          = r_trans.r19_tipo_dev
LET r_r19.r19_num_dev           = r_trans.r19_num_dev
LET r_r19.r19_bodega_ori 	= r_trans.r19_bodega_dest
LET r_r19.r19_bodega_dest	= r_trans.r19_bodega_ori
LET r_r19.r19_moneda     	= rg_gen.g00_moneda_base
LET r_r19.r19_precision  	= rg_gen.g00_decimal_mb
LET r_r19.r19_paridad    	= 1
LET r_r19.r19_tot_costo  	= 0
LET r_r19.r19_tot_bruto  	= 0.0
LET r_r19.r19_tot_dscto  	= 0.0
LET r_r19.r19_tot_neto		= r_r19.r19_tot_costo
LET r_r19.r19_flete      	= 0.0
LET r_r19.r19_usuario      	= vg_usuario
LET r_r19.r19_fecing      	= fl_current()
INSERT INTO rept019 VALUES (r_r19.*)
INITIALIZE r_r20.* TO NULL
LET r_r20.r20_compania		= vg_codcia
LET r_r20.r20_localidad  	= vg_codloc
LET r_r20.r20_cod_tran   	= r_r19.r19_cod_tran
LET r_r20.r20_num_tran   	= r_r19.r19_num_tran
LET r_r20.r20_cant_ent   	= 0 
LET r_r20.r20_cant_dev   	= 0
LET r_r20.r20_descuento  	= 0.0
LET r_r20.r20_val_descto 	= 0.0
LET r_r20.r20_val_impto  	= 0.0
LET r_r20.r20_ubicacion  	= 'SN'
DECLARE q_trans_d CURSOR FOR
	SELECT * FROM rept020
		WHERE r20_compania  = r_trans.r19_compania
		  AND r20_localidad = r_trans.r19_localidad
		  AND r20_cod_tran  = r_trans.r19_cod_tran
		  AND r20_num_tran  = r_trans.r19_num_tran
		ORDER BY r20_orden ASC
FOREACH q_trans_d INTO r_trans_d.*
	CALL fl_lee_item(vg_codcia, r_trans_d.r20_item) RETURNING r_r10.*
	LET r_r19.r19_tot_costo  = r_r19.r19_tot_costo + 
				  (r_trans_d.r20_cant_ven * r_r10.r10_costo_mb)
	LET r_r20.r20_cant_ped   = r_trans_d.r20_cant_ven
	LET r_r20.r20_cant_ven   = r_trans_d.r20_cant_ven
	LET r_r20.r20_bodega     = r_r19.r19_bodega_ori
	LET r_r20.r20_item       = r_trans_d.r20_item 
	LET r_r20.r20_costo      = r_r10.r10_costo_mb 
	LET r_r20.r20_orden      = r_trans_d.r20_orden
	LET r_r20.r20_fob        = r_r10.r10_fob 
	LET r_r20.r20_linea      = r_r10.r10_linea 
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion 
	LET r_r20.r20_precio     = r_r10.r10_precio_mb
	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori,
				r_trans_d.r20_item)
		RETURNING r_r11.*
	IF r_r11.r11_compania IS NOT NULL THEN
		CALL fl_lee_bodega_rep(r_r11.r11_compania, r_r11.r11_bodega)
			RETURNING r_r02.*
		IF r_r02.r02_tipo <> 'S' THEN
			LET stock_act = r_r11.r11_stock_act -
					r_trans_d.r20_cant_ven
			IF stock_act < 0 THEN
				ROLLBACK WORK
				LET mensaje = 'ERROR: El item ',
						r_r11.r11_item CLIPPED,
						' tiene stock insuficiente, ',
						'para DESHACER el CRUCE',
						' AUTOMATICO. Llame al',
						'ADMINISTRADOR.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				EXIT PROGRAM
			END IF
		END IF
	END IF
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_ant  = r_r11.r11_stock_act 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
				r_trans_d.r20_item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act 
	LET r_r20.r20_fecing	 = fl_current()
	INSERT INTO rept020 VALUES(r_r20.*)
	UPDATE rept011
		SET r11_stock_act = r11_stock_act - r_trans_d.r20_cant_ven,
		    r11_egr_dia   = r11_egr_dia   + r_trans_d.r20_cant_ven
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = r_r19.r19_bodega_ori
		  AND r11_item     = r_trans_d.r20_item 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
				r_trans_d.r20_item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		INSERT INTO rept011
      			(r11_compania, r11_bodega, r11_item, r11_ubicacion,
			 r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
		VALUES(vg_codcia, r_r19.r19_bodega_dest,r_trans_d.r20_item,'SN',
			0, r_trans_d.r20_cant_ven, r_trans_d.r20_cant_ven, 0) 
	ELSE
		UPDATE rept011 
			SET r11_stock_act = r11_stock_act +
						r_trans_d.r20_cant_ven,
	      		    r11_ing_dia   = r11_ing_dia + r_trans_d.r20_cant_ven
			WHERE r11_compania  = vg_codcia
			  AND r11_bodega    = r_r19.r19_bodega_dest
			  AND r11_item      = r_trans_d.r20_item 
	END IF
END FOREACH
UPDATE rept019
	SET r19_tot_costo = r_r19.r19_tot_costo,
	    r19_tot_bruto = r_r19.r19_tot_bruto,
	    r19_tot_neto  = r_r19.r19_tot_bruto
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = r_r19.r19_cod_tran
	  AND r19_num_tran  = r_r19.r19_num_tran
INSERT INTO tmp_r41
	VALUES(vg_codcia, vg_codloc, rm_cl.r19_cod_tran, rm_cl.r19_num_tran,
		r_r19.r19_cod_tran, r_r19.r19_num_tran)

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
DISPLAY '<F5>      Ver Compra Local'         AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Imprimir Devolución'      AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

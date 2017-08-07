--------------------------------------------------------------------------------
-- Titulo           : repp214.4gl - Generación de compra local  
-- Elaboracion      : 13-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp214 base modulo compania localidad 
--			[codtran numtran]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_factura	LIKE rept019.r19_cod_tran
DEFINE vm_retencion	LIKE rept019.r19_cod_tran
DEFINE vm_ajuste	LIKE cxpt022.p22_tipo_trn
DEFINE vm_transaccion   LIKE rept019.r19_cod_tran

DEFINE vm_num_tran	LIKE rept019.r19_num_tran

-- Para guardar el numero del documento de retenciones
DEFINE vm_num_ret 	LIKE cxpt027.p27_num_ret

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT

DEFINE vm_max_detalle	SMALLINT	-- NUMERO MAXIMO ELEMENTOS DEL DETALLE

DEFINE vm_num_aut	LIKE ordt013.c13_num_aut
DEFINE vm_serie_comp	LIKE ordt013.c13_serie_comp
DEFINE vm_fecha_cadu	LIKE ordt013.c13_fecha_cadu
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_r19		RECORD LIKE rept019.* 
DEFINE rm_c10		RECORD LIKE ordt010.* 
DEFINE rm_p01		RECORD LIKE cxpt001.* 
DEFINE rm_p29		RECORD LIKE cxpt029.* 

DEFINE vm_indice	SMALLINT
DEFINE vm_max_compra	SMALLINT
DEFINE rm_compra ARRAY[1000] OF RECORD
	cant_ped		LIKE rept020.r20_cant_ped, 
	cant_ven		LIKE rept020.r20_cant_ven, 
	item			LIKE rept020.r20_item, 
	descuento		LIKE rept020.r20_descuento,
	precio			LIKE ordt011.c11_precio, 
	total			LIKE rept019.r19_tot_bruto
END RECORD

DEFINE rm_datos ARRAY[1000] OF RECORD
	item  	 		LIKE rept010.r10_nombre,
	val_descto		LIKE rept020.r20_val_descto,
	stock_ant		LIKE rept020.r20_stock_ant,
	costo_base		DECIMAL(12,2),
	costo_adi		DECIMAL(12,2)
END RECORD

	---- ARREGLO PARA LA FORMA DE PAGO ----
DEFINE r_detalle_2 ARRAY[250] OF RECORD
	c12_dividendo		LIKE ordt012.c12_dividendo,
	c12_fecha_vcto		LIKE ordt012.c12_fecha_vcto,
	c12_valor_cap		LIKE ordt012.c12_valor_cap,
	c12_valor_int		LIKE ordt012.c12_valor_int,
	subtotal		LIKE ordt011.c11_descuento
END RECORD

DEFINE ind_max_ret	SMALLINT
DEFINE ind_ret		SMALLINT
DEFINE r_ret ARRAY[50] OF RECORD
	check		CHAR(1),
	n_retencion	LIKE ordt002.c02_nombre,
	tipo_ret	LIKE cxpt005.p05_tipo_ret, 
	val_base	LIKE rept019.r19_tot_bruto, 
	porc		LIKE cxpt005.p05_porcentaje, 
	subtotal 	LIKE rept019.r19_tot_neto
END RECORD

DEFINE val_bienes	LIKE rept019.r19_tot_bruto
DEFINE val_servi	LIKE rept019.r19_tot_bruto
DEFINE val_impto	LIKE rept019.r19_tot_dscto
DEFINE val_neto		LIKE rept019.r19_tot_neto
DEFINE val_pagar	LIKE rept019.r19_tot_neto
DEFINE tot_ret		LIKE rept019.r19_tot_neto
------------------------------------------------------
---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE FORMA DE PAGO ----

DEFINE vm_filas_pant		SMALLINT

DEFINE tot_dias			SMALLINT	
DEFINE pagos			SMALLINT
DEFINE fecha_pago		DATE
DEFINE dias_pagos		SMALLINT
DEFINE c10_interes		LIKE ordt010.c10_interes
DEFINE tot_compra		LIKE ordt010.c10_tot_compra
DEFINE tot_cap			LIKE ordt010.c10_tot_compra
DEFINE tot_int			LIKE ordt010.c10_tot_compra
DEFINE tot_sub			LIKE ordt010.c10_tot_compra
---------------------------------------------------------------

-- Registro de la tabla de configuración del módulo de repuestos
DEFINE rm_r00			RECORD LIKE rept000.*
DEFINE rm_c00			RECORD LIKE ordt000.*
DEFINE vm_stock_pend		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp214.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 7 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp214'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
			        -- que luego puede ser reemplazado si se 
                            	-- mantiene sin comentario la siguiente linea

LET vm_num_tran = 0
IF num_args() <> 4 THEN
	LET vm_num_tran  = arg_val(6)
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
OPEN WINDOW w_214 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_214 FROM '../forms/repf214_1'
ELSE
	OPEN FORM f_214 FROM '../forms/repf214_1c'
END IF
DISPLAY FORM f_214

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r19.* TO NULL

CALL muestra_contadores()
CALL setea_nombre_botones()

LET vm_max_rows = 1000
LET vm_max_compra = 1000
LET vm_max_detalle  = 250
LET ind_max_ret = 50

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe registro de configuración en el módulo de repuestos para esta compañía.','exclamation')
	CALL fl_mostrar_mensaje('No existe registro de configuración en el módulo de repuestos para esta compañía.','exclamation')
	EXIT PROGRAM
END IF

CALL fl_lee_compania_orden_compra(vg_codcia) RETURNING rm_c00.*
IF rm_c00.c00_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe registro de configuración en el módulo de ordenes de compra para esta compañía.','exclamation')
	CALL fl_mostrar_mensaje('No existe registro de configuración en el módulo de ordenes de compra para esta compañía.','exclamation')
	EXIT PROGRAM
END IF

-- OjO
LET vm_transaccion = 'CL'       
LET vm_factura     = 'FA'
LET vm_retencion   = 'RT'
LET vm_ajuste      = 'AJ'
--

LET val_bienes = 0
LET val_impto  = 0
LET val_neto   = 0
LET val_pagar  = 0

IF vm_num_tran <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Orden de Compra'
		HIDE OPTION 'Forma Pago'
		HIDE OPTION 'Devoluciones'
		HIDE OPTION 'Ver Retenciones'
		HIDE OPTION 'Fact. Item Cruce'
		HIDE OPTION 'Imprimir'
		IF vm_num_tran <> 0 THEN        -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Orden de Compra'	
			IF rm_r19.r19_cont_cred = 'R' THEN
				SHOW OPTION 'Forma Pago'
			END IF
			--IF vm_indice > vm_filas_pant THEN
				SHOW OPTION 'Detalle'
			--END IF		
                	IF rm_r19.r19_tipo_dev IS NOT NULL AND num_args() <> 7
			THEN
                		SHOW OPTION 'Devoluciones'
                	END IF
                	IF ind_ret > 0 THEN
                		SHOW OPTION 'Ver Retenciones'
                	END IF
			IF NOT tiene_facturas_cruce() THEN
				HIDE OPTION 'Fact. Item Cruce'
			ELSE
				SHOW OPTION 'Fact. Item Cruce'
			END IF
                	SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Ver Retenciones'
		HIDE OPTION 'Orden de Compra'
		HIDE OPTION 'Forma Pago'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			IF vm_indice > vm_filas_pant THEN
				SHOW OPTION 'Detalle'
			END IF
			SHOW OPTION 'Orden de Compra'	
			SHOW OPTION 'Forma Pago'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
			IF vm_indice > vm_filas_pant THEN
				SHOW OPTION 'Detalle'
			END IF
			SHOW OPTION 'Orden de Compra'
			IF rm_r19.r19_cont_cred = 'R' THEN
				SHOW OPTION 'Forma Pago'
			END IF
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 AND ind_ret > 0 THEN
			SHOW OPTION 'Ver Retenciones'
		END IF
		IF NOT tiene_facturas_cruce() THEN
			HIDE OPTION 'Fact. Item Cruce'
		ELSE
			SHOW OPTION 'Fact. Item Cruce'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
		CALL setea_nombre_botones()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Devoluciones'
		HIDE OPTION 'Forma Pago'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Ver Retenciones'
		IF NOT tiene_facturas_cruce() THEN
			HIDE OPTION 'Fact. Item Cruce'
		ELSE
			SHOW OPTION 'Fact. Item Cruce'
		END IF
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Orden de Compra'
			IF NOT tiene_facturas_cruce() THEN
				HIDE OPTION 'Fact. Item Cruce'
			ELSE
				SHOW OPTION 'Fact. Item Cruce'
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
				HIDE OPTION 'Orden de Compra'
			END IF
		ELSE
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Orden de Compra'
			IF NOT tiene_facturas_cruce() THEN
				HIDE OPTION 'Fact. Item Cruce'
			ELSE
				SHOW OPTION 'Fact. Item Cruce'
			END IF
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
			IF rm_r19.r19_cont_cred = 'R' THEN
				SHOW OPTION 'Forma Pago'
			END IF
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
                IF rm_r19.r19_tipo_dev IS NOT NULL THEN
                	SHOW OPTION 'Devoluciones'
                END IF
                IF ind_ret > 0 THEN
                	SHOW OPTION 'Ver Retenciones'
                END IF
		IF NOT tiene_facturas_cruce() THEN
			HIDE OPTION 'Fact. Item Cruce'
		ELSE
			SHOW OPTION 'Fact. Item Cruce'
		END IF
		CALL setea_nombre_botones()
	COMMAND KEY('D') 'Detalle'		'Ver detalle de compra local.'
		CALL control_mostrar_det()
	COMMAND KEY('F') 'Forma Pago'		'Ver forma de pago.'
		CALL muestra_forma_pago()
	COMMAND KEY('T') 'Ver Retenciones'	'Ver retenciones.'
		CALL ver_retenciones()
	COMMAND KEY('E') 'Devoluciones'         'Ver devoluciones.'
		CALL ver_devolucion()
	COMMAND KEY('O') 'Orden de Compra'	'Ver orden de compra.'
		CALL orden_compra()
        COMMAND KEY('X') 'Fact. Item Cruce'	'Muestra facturas cruzadas.'
		CALL muestra_fact_items_cruce()
        COMMAND KEY('P') 'Imprimir'		'Imprime la compra local.'
		CALL control_imprimir(0)
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		HIDE OPTION 'Devoluciones'
		HIDE OPTION 'Forma Pago'
		HIDE OPTION 'Ver Retenciones'
		IF NOT tiene_facturas_cruce() THEN
			HIDE OPTION 'Fact. Item Cruce'
		ELSE
			SHOW OPTION 'Fact. Item Cruce'
		END IF
		HIDE OPTION 'Imprimir'
		CALL siguiente_registro()
		IF rm_r19.r19_cont_cred = 'R' THEN
			SHOW OPTION 'Forma Pago'
		END IF		
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
                IF ind_ret > 0 THEN
                	SHOW OPTION 'Ver Retenciones'
                END IF		
		IF NOT tiene_facturas_cruce() THEN
			HIDE OPTION 'Fact. Item Cruce'
		ELSE
			SHOW OPTION 'Fact. Item Cruce'
		END IF
                IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		HIDE OPTION 'Devoluciones'
		HIDE OPTION 'Forma Pago'
		HIDE OPTION 'Ver Retenciones'
		IF NOT tiene_facturas_cruce() THEN
			HIDE OPTION 'Fact. Item Cruce'
		ELSE
			SHOW OPTION 'Fact. Item Cruce'
		END IF
		HIDE OPTION 'Imprimir'
		CALL anterior_registro()
		IF rm_r19.r19_cont_cred = 'R' THEN
			SHOW OPTION 'Forma Pago'
		END IF		
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
                IF ind_ret > 0 THEN
                	SHOW OPTION 'Ver Retenciones'
                END IF
		IF NOT tiene_facturas_cruce() THEN
			HIDE OPTION 'Fact. Item Cruce'
		ELSE
			SHOW OPTION 'Fact. Item Cruce'
		END IF
                IF vm_num_rows > 0 THEN
                	SHOW OPTION 'Imprimir'
                END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE i		SMALLINT

DEFINE cantidad_ped	DECIMAL (8,2)
DEFINE cantidad_rec	DECIMAL (8,2)
DEFINE rowid		INTEGER
DEFINE intentar		SMALLINT
DEFINE done		SMALLINT

DEFINE resp 		CHAR(6)
DEFINE estado 		LIKE ordt010.c10_estado

LET vm_num_ret = NULL
CLEAR FORM
INITIALIZE rm_r19.* TO NULL

-- THESE VALUES WON'T CHANGE 
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
LET rm_r19.r19_cod_tran   = vm_transaccion
LET rm_r19.r19_flete      = 0
LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_fecing     = CURRENT
LET rm_r19.r19_bodega_ori = rm_r00.r00_bodega_fact

LET rm_r19.r19_dircli     = '.'   
LET rm_r19.r19_cedruc     = '.'   

CALL muestra_etiquetas()

CALL lee_datos()
LET rm_r19.r19_nomcli     = rm_p01.p01_nomprov
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_c10.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_c10 CURSOR FOR
			SELECT * FROM ordt010
				WHERE c10_compania  = vg_codcia
				  AND c10_localidad = vg_codloc            
				  AND c10_numero_oc = rm_r19.r19_oc_interna
			FOR UPDATE
	OPEN  q_c10
	FETCH q_c10 INTO r_c10.*
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
	FREE q_c10
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN 
END IF

CALL ingresa_detalle()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	IF vm_indice = 0 THEN
		UPDATE ordt010 SET c10_estado = 'A' WHERE CURRENT OF q_c10
		COMMIT WORK
		RETURN
	END IF	
	ROLLBACK WORK
	RETURN
END IF
IF r_c10.c10_tot_compra <> rm_r19.r19_tot_neto THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Se ha detectado que el total neto de la orden de compra No. ' || r_c10.c10_numero_oc USING "<<<<<<<&" || ' es diferente al total neto de la compra local.', 'stop')
	EXIT PROGRAM
END IF
LET val_bienes = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto +
		 rm_c10.c10_dif_cuadre + rm_c10.c10_otros     
LET val_neto   = rm_r19.r19_tot_neto

LET rm_r19.r19_bodega_dest = rm_r19.r19_bodega_ori

LET rm_r19.r19_num_tran = nextValInSequence(vg_modulo, rm_r19.r19_cod_tran)
IF rm_r19.r19_num_tran = -1 THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET rm_r19.r19_fecing = CURRENT
LET rm_r19.r19_flete  = rm_c10.c10_flete
INSERT INTO rept019 VALUES (rm_r19.*)
DISPLAY BY NAME rm_r19.r19_num_tran

LET rowid = SQLCA.SQLERRD[6] 			-- Rowid de la ultima fila 
                                             	-- procesada
CALL graba_cabecera_recepcion(r_c10.*) RETURNING r_c13.*
                                             	
LET done = graba_detalle(r_c13.*)
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
SELECT SUM(c11_cant_ped) INTO cantidad_ped
	FROM ordt011
	WHERE c11_compania  = vg_codcia
	  AND c11_localidad = vg_codloc
	  AND c11_numero_oc = rm_r19.r19_oc_interna

SELECT SUM(c14_cantidad) INTO cantidad_rec
	FROM ordt014
	WHERE c14_compania  = vg_codcia
	  AND c14_localidad = vg_codloc
	  AND c14_numero_oc = rm_r19.r19_oc_interna
	  AND c14_num_recep = r_c13.c13_num_recep

LET estado = 'C'
IF cantidad_ped <> cantidad_rec THEN
	LET done = 1
	FOR i = 1 TO vm_indice
		IF rm_compra[i].cant_ped <> rm_compra[i].cant_ven THEN
			LET done = 0
			EXIT FOR
		END IF
	END FOR
	IF NOT done THEN
		CALL fl_hacer_pregunta('No se han recibido todos los articulos de la orden de compra, desea poder recibirlos despues?','No')
			RETURNING resp
		IF resp = 'Yes' THEN
			LET estado = 'P'
		END IF
	END IF
	IF rm_r19.r19_cont_cred = 'R' THEN
		LET INT_FLAG = 0
		CALL control_forma_pago(r_c10.*, r_c13.*)
		IF INT_FLAG THEN
			ROLLBACK WORK
			IF vm_num_rows = 0 THEN
				CLEAR FORM
				CALL muestra_contadores()
			ELSE	
				CALL lee_muestra_registro(
					vm_rows[vm_row_current]
				)
			END IF
			LET INT_FLAG = 0
			RETURN
		END IF
		CALL graba_vencimientos_recepcion_parcial(r_c13.*)
	END IF
ELSE
	IF rm_r19.r19_cont_cred = 'R' THEN
		CALL forma_pago_oc(r_c13.*)
	END IF
END IF

IF rm_r19.r19_cont_cred = 'C' THEN
	LET c10_interes = 0
END IF

UPDATE ordt013 SET c13_interes = c10_interes 
	WHERE c13_compania  = vg_codcia
  	  AND c13_localidad = vg_codloc
  	  AND c13_numero_oc = rm_r19.r19_oc_interna
  	  AND c13_num_recep = r_c13.c13_num_recep

LET INT_FLAG = 0
CALL control_menu2(r_c13.*, r_c10.*)
IF INT_FLAG THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

UPDATE ordt010 SET c10_estado      = estado,
		   c10_factura     = rm_r19.r19_oc_externa,
		   c10_fecha_fact  = TODAY,
		   c10_fecha_entre = CURRENT	
	WHERE CURRENT OF q_c10
CLOSE q_c10
FREE  q_c10

INITIALIZE r_p01.* TO NULL
WHENEVER ERROR CONTINUE
DECLARE q_p01 CURSOR FOR
	SELECT * FROM cxpt001
		WHERE p01_codprov = rm_c10.c10_codprov
	FOR UPDATE
OPEN q_p01
FETCH q_p01 INTO r_p01.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('El código del proveedor esta bloqueado por otro proceso.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, r_p01.p01_codprov)
	RETURNING r_p02.*
IF r_p02.p02_aux_prov_mb IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe configurado auxiliar contable para este proveedor.', 'stop')
	RETURN
END IF
IF (r_p01.p01_num_aut IS NULL AND r_p01.p01_serie_comp IS NULL) OR
   (r_p01.p01_num_aut <> vm_num_aut OR r_p01.p01_serie_comp <> vm_serie_comp)
THEN
	UPDATE cxpt001
		SET p01_serie_comp = vm_serie_comp,
		    p01_num_aut    = vm_num_aut
		WHERE CURRENT OF q_p01
END IF
CLOSE q_p01
FREE q_p01
CALL proceso_cruce_de_bodegas()

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
CALL control_imprimir(1)
CALL fl_mensaje_registro_ingresado()
IF tiene_facturas_cruce() THEN
	CALL muestra_fact_items_cruce()
END IF

END FUNCTION



FUNCTION lee_datos()

DEFINE resp 		CHAR(6)

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE contador		SMALLINT

DEFINE oc_ant		LIKE ordt010.c10_numero_oc

INITIALIZE vm_num_aut, vm_serie_comp, vm_fecha_cadu TO NULL

LET INT_FLAG = 0
INPUT BY NAME rm_r19.r19_cod_tran, rm_r19.r19_oc_interna, vm_num_aut,
	vm_serie_comp, vm_fecha_cadu, rm_r19.r19_oc_externa,
	rm_r19.r19_fact_venta, rm_r19.r19_vendedor, rm_r19.r19_bodega_ori
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_r19.r19_cod_tran, rm_r19.r19_oc_interna,
				vm_num_aut, vm_serie_comp, vm_fecha_cadu,
				rm_r19.r19_oc_externa, rm_r19.r19_fact_venta,
				rm_r19.r19_vendedor, rm_r19.r19_bodega_ori)
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
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(r19_oc_interna) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc, 
				0, 0, 'P', vg_modulo, 'S')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				LET rm_r19.r19_oc_interna = r_c10.c10_numero_oc
				DISPLAY BY NAME rm_r19.r19_oc_interna
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
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', '1', 'R', 'S', 'V')
		     		RETURNING r_r02.r02_codigo, r_r02.r02_nombre
		     	IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r19.r19_bodega_ori = r_r02.r02_codigo
				DISPLAY BY NAME rm_r19.r19_bodega_ori
				DISPLAY r_r02.r02_nombre TO n_bodega
			END IF
		END IF
		LET INT_FLAG = 0
	ON KEY(F5)
		IF rm_r19.r19_oc_interna IS NOT NULL THEN
			CALL orden_compra()
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel('F5', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		CALL setea_nombre_botones()
	BEFORE FIELD r19_oc_interna
		LET oc_ant = rm_r19.r19_oc_interna
	AFTER FIELD r19_oc_interna
		-- La orden de compra debe tener estado 'P' (Aprobada)
		-- y debe hacer referencia en el campo c10_tipo_orden
 		-- a un registro de la tabla ordt001 que tenga  los 
		-- siguientes valores:
		-- - c01_modulo = 'RE'
		-- - c01_ing_bodega = 'S' 
		IF rm_r19.r19_oc_interna IS NULL THEN
			INITIALIZE r_c10.* TO NULL
			CALL etiquetas_orden_compra(r_c10.*)
			--#CALL dialog.keysetlabel('F5', '')
			CONTINUE INPUT
		END IF

		CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
			rm_r19.r19_oc_interna) RETURNING r_c10.*
		IF r_c10.c10_numero_oc IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Orden de compra no existe.','exclamation')
			CALL fl_mostrar_mensaje('Orden de compra no existe.','exclamation')
			INITIALIZE r_c10.* TO NULL
			CALL etiquetas_orden_compra(r_c10.*)
			--#CALL dialog.keysetlabel('F5', '')
			NEXT FIELD r19_oc_interna 
		END IF
		IF r_c10.c10_estado <> 'P' THEN
			--CALL fgl_winmessage(vg_producto,'No puede realizar una compra local de esta orden de compra.','exclamation')
			CALL fl_mostrar_mensaje('Orden de compra no esta aprobada.','exclamation')
			INITIALIZE r_c10.* TO NULL
			CALL etiquetas_orden_compra(r_c10.*)
			--#CALL dialog.keysetlabel('F5', '')
			NEXT FIELD r19_oc_interna
		END IF
		
		CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
			RETURNING r_c01.*
		IF r_c01.c01_modulo <> vg_modulo AND r_c01.c01_ing_bodega <> 'S'
		THEN
			--CALL fgl_winmessage(vg_producto,'Esta orden de compra no puede asociarse a una compra local.','exclamation')
			CALL fl_mostrar_mensaje('Orden de compra no pertenece al módulo.','exclamation')
			INITIALIZE r_c10.* TO NULL
			CALL etiquetas_orden_compra(r_c10.*)
			--#CALL dialog.keysetlabel('F5', '')
			NEXT FIELD r19_oc_interna
		END IF
		CALL etiquetas_orden_compra(r_c10.*)
		IF oc_ant IS NULL OR oc_ant <> r_c10.c10_numero_oc THEN
			LET vm_num_aut    = rm_p01.p01_num_aut
			LET vm_serie_comp = rm_p01.p01_serie_comp
			DISPLAY BY NAME vm_num_aut, vm_serie_comp
		END IF
		--#CALL dialog.keysetlabel('F5', 'Orden de Compra')
		CALL setea_nombre_botones()
	AFTER FIELD r19_vendedor
		IF rm_r19.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Vendedor no existe.','exclamation')
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation')
				CLEAR n_vendedor
				NEXT FIELD r19_vendedor
			END IF 
			IF r_r01.r01_estado = 'B' THEN
				--CALL fgl_winmessage(vg_producto,'Vendedor está bloqueado.','exclamation')
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
				--CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF 
			IF r_r02.r02_estado = 'B' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega está bloqueada.','exclamation')
				CALL fl_mostrar_mensaje('Bodega está bloqueada.','exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF
			IF r_r02.r02_tipo <> 'F' THEN
				--CALL fgl_winmessage(vg_producto,'Debe escoger una bodega física.','exclamation')
				CALL fl_mostrar_mensaje('Debe escoger una bodega física.','exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF
			DISPLAY r_r02.r02_nombre TO n_bodega
		ELSE
			CLEAR n_bodega
		END IF
	AFTER FIELD r19_oc_externa
		IF LENGTH(rm_r19.r19_oc_externa) < 14 THEN
			CALL fl_mostrar_mensaje('El número del documento ingresado es incorrecto.', 'exclamation')
			NEXT FIELD r19_oc_externa
		END IF
		IF rm_r19.r19_oc_externa[4, 4] <> '-' OR
		   rm_r19.r19_oc_externa[8, 8] <> '-' THEN
			CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
			NEXT FIELD r19_oc_externa
		END IF
		IF LENGTH(rm_r19.r19_oc_externa[1, 7]) <> 7 THEN
			CALL fl_mostrar_mensaje('Digite correctamente el punto de venta o el punto de emision.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		LET vm_serie_comp = rm_r19.r19_oc_externa[1, 3],
					rm_r19.r19_oc_externa[5, 7]
		DISPLAY BY NAME vm_serie_comp
		IF rm_r19.r19_oc_externa[1, 3] <> vm_serie_comp[1, 3] THEN
			CALL fl_mostrar_mensaje('El prefijo del local es diferente que el de la serie del comprobante.', 'exclamation')
			NEXT FIELD r19_oc_externa
		END IF
		IF rm_r19.r19_oc_externa[5, 7] <> vm_serie_comp[4, 6] THEN
			CALL fl_mostrar_mensaje('El prefijo de venta es diferente que el de la serie del comprobante.', 'exclamation')
			NEXT FIELD r19_oc_externa
		END IF
	AFTER FIELD vm_fecha_cadu
		IF vm_fecha_cadu IS NOT NULL THEN
			CALL retorna_fin_mes(vm_fecha_cadu)
				RETURNING vm_fecha_cadu
			DISPLAY BY NAME vm_fecha_cadu
		END IF
	AFTER INPUT
		IF rm_r19.r19_oc_externa IS NULL THEN
			NEXT FIELD r19_oc_externa
		END IF
		IF rm_r19.r19_fact_venta IS NULL THEN
			NEXT FIELD r19_fact_venta
		END IF
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
			r_c10.c10_codprov, vm_factura, rm_r19.r19_oc_externa,
			1) RETURNING r_p20.*
		IF r_p20.p20_num_doc IS NOT NULL THEN
			--CALL fgl_winmessage(vg_producto,'Esta factura ya existe para este provedor.','exclamation')
			CALL fl_mostrar_mensaje('Esta factura ya existe para este provedor.','exclamation')
			NEXT FIELD r19_oc_externa
		END IF
		IF vm_fecha_cadu IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la fecha de caducidad.', 'exclamation')
			NEXT FIELD vm_fecha_cadu
		END IF
		IF vm_fecha_cadu < TODAY THEN
			CALL fl_mostrar_mensaje('La fecha de caducidad no puede ser menor a la fecha de hoy.', 'exclamation')
			NEXT FIELD vm_fecha_cadu
		END IF
END INPUT
LET rm_c10.* = r_c10.*

END FUNCTION



FUNCTION ingresa_detalle()

DEFINE resp 		CHAR(6)
DEFINE i    		SMALLINT
DEFINE j    		SMALLINT
DEFINE k    		SMALLINT
DEFINE salir		SMALLINT
DEFINE rm_r10		RECORD LIKE rept010.*

LET vm_indice = lee_detalle_orden_compra() 
IF INT_FLAG THEN
	RETURN
END IF

IF vm_indice = 0 THEN
	--CALL fgl_winmessage(vg_producto,'La orden de compra ya fue recibida por completo.','exclamation')
	CALL fl_mostrar_mensaje('La orden de compra ya fue recibida por completo.','exclamation')
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
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i, vm_indice)
			CALL fl_lee_item(vg_codcia, rm_compra[i].item)
				RETURNING rm_r10.*
			CALL muestra_descripciones(rm_compra[i].item,
				rm_r10.r10_linea, rm_r10.r10_sub_linea,
				rm_r10.r10_cod_grupo, 
				rm_r10.r10_cod_clase)
			CALL calcula_totales()
		AFTER FIELD r20_cant_ven
			LET rm_compra[i].cant_ven = rm_compra[i].cant_ped
			DISPLAY rm_compra[i].cant_ven TO ra_compra[j].r20_cant_ven
			IF rm_compra[i].cant_ven > rm_compra[i].cant_ped THEN
				--CALL fgl_winmessage(vg_producto,'Debe poner una cantidad menor o igual a la cantidad disponible.','exclamation')
				CALL fl_mostrar_mensaje('Debe poner una cantidad menor o igual a la cantidad disponible.','exclamation')
				NEXT FIELD r20_cant_ven
			END IF
			LET rm_compra[i].total = 
				rm_compra[i].precio * rm_compra[i].cant_ven
			CALL calcula_totales()
			DISPLAY rm_compra[i].* TO ra_compra[j].*
		BEFORE DELETE	
			EXIT INPUT
		BEFORE INSERT
			EXIT INPUT	
		AFTER INPUT
			CALL calcula_totales() 
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
DEFINE r_c10		RECORD LIKE ordt010.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON r19_num_tran, r19_oc_interna, r19_oc_externa, r19_fact_venta, 
	   r19_vendedor, r19_bodega_ori 
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_num_tran) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      vm_transaccion)
				RETURNING rm_r19.r19_cod_tran, 
					  rm_r19.r19_num_tran,
					  rm_r19.r19_nomcli 
		      	IF rm_r19.r19_num_tran IS NOT NULL THEN
				CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							    vg_codloc,
							    vm_transaccion,
							    rm_r19.r19_num_tran)
					RETURNING rm_r19.*
				DISPLAY BY NAME rm_r19.r19_num_tran
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
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', '1', 'R', 'S', 'V')
		     		RETURNING r_r02.r02_codigo, r_r02.r02_nombre
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
	    'WHERE r19_compania  = ', vg_codcia, 
	    '  AND r19_localidad = ', vg_codloc,
	    '  AND r19_cod_tran = "', vm_transaccion, '" ',
	    '  AND r19_oc_interna IS NOT NULL ', 
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
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
			rm_r19.r19_oc_interna) RETURNING rm_c10.*

LET iva = (rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto + rm_c10.c10_dif_cuadre +
	   rm_c10.c10_otros) * (rm_r19.r19_porc_impto / 100)

DISPLAY BY NAME rm_r19.r19_cod_tran,   
                rm_r19.r19_num_tran,   
		rm_r19.r19_oc_interna,
		rm_r19.r19_oc_externa,
		rm_r19.r19_fact_venta,
		rm_r19.r19_vendedor,
		rm_r19.r19_bodega_ori,
		rm_r19.r19_moneda,    
		rm_r19.r19_tot_bruto,
		rm_r19.r19_tot_dscto,
		rm_r19.r19_fecing,
		iva,
		rm_c10.c10_dif_cuadre,
		rm_r19.r19_tot_neto

SELECT c13_num_aut, c13_serie_comp, c13_fecha_cadu
	INTO vm_num_aut, vm_serie_comp, vm_fecha_cadu
	FROM ordt013
	WHERE c13_compania  = vg_codcia AND c13_localidad = vg_codloc
	  AND c13_numero_oc = rm_r19.r19_oc_interna
	  AND c13_factura   = rm_r19.r19_oc_externa

DISPLAY BY NAME vm_num_aut, vm_serie_comp, vm_fecha_cadu
		
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

CALL lee_retenciones()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

LET filas_pant = fgl_scr_size('ra_compra')
{
IF vg_gui = 0 THEN
	LET filas_pant = 3
END IF
}
LET vm_filas_pant = filas_pant

FOR i = 1 TO filas_pant 
	INITIALIZE rm_compra[i].* TO NULL
	CLEAR ra_compra[i].*
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
	DISPLAY rm_compra[i].* TO ra_compra[i].*
END FOR
CALL muestra_contadores_det(0, vm_indice)
CALL fl_lee_item(vg_codcia, rm_compra[1].item) RETURNING r_r10.*  
CALL muestra_descripciones(rm_compra[1].item, r_r10.r10_linea,
				r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
				r_r10.r10_cod_clase)

END FUNCTION



FUNCTION lee_detalle()

DEFINE i		SMALLINT
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*

DECLARE q_det CURSOR FOR
	SELECT * FROM rept020, rept010
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc  
		  AND r20_cod_tran  = rm_r19.r19_cod_tran
		  AND r20_num_tran  = rm_r19.r19_num_tran
		  AND r10_compania  = r20_compania
		  AND r10_codigo    = r20_item
	ORDER BY r20_orden

LET i = 1
FOREACH q_det INTO r_r20.*, r_r10.*          
	LET rm_compra[i].cant_ped   = r_r20.r20_cant_ped
	LET rm_compra[i].cant_ven   = r_r20.r20_cant_ven
	LET rm_compra[i].item       = r_r20.r20_item
	LET rm_compra[i].descuento  = r_r20.r20_descuento
	LET rm_compra[i].precio     = r_r20.r20_precio
	LET rm_compra[i].total      = r_r20.r20_precio * r_r20.r20_cant_ven 

	LET rm_datos[i].item        = r_r10.r10_nombre
	LET rm_datos[i].val_descto  = r_r20.r20_val_descto
	LET rm_datos[i].stock_ant   = r_r20.r20_stock_ant
	LET rm_datos[i].costo_base  = rm_compra[i].total-rm_datos[i].val_descto
	LET rm_datos[i].costo_adi   = 0

	LET i = i + 1
	IF i > vm_max_compra THEN
		EXIT FOREACH
	END IF
END FOREACH
FREE q_det

LET i = i - 1

RETURN i

END FUNCTION



FUNCTION lee_detalle_orden_compra()

DEFINE i		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_c11		RECORD LIKE ordt011.*

DECLARE q_ord CURSOR FOR
	SELECT * FROM ordt011, rept010
		WHERE c11_compania  = vg_codcia
		  AND c11_localidad = vg_codloc  
		  AND c11_numero_oc = rm_r19.r19_oc_interna
		  AND c11_cant_ped - c11_cant_rec > 0
                  AND r10_compania  = c11_compania
		  AND r10_codigo    = c11_codigo
	ORDER BY c11_secuencia

LET i = 1
FOREACH q_ord INTO r_c11.*, r_r10.*
	LET rm_compra[i].cant_ped   = r_c11.c11_cant_ped - r_c11.c11_cant_rec
	LET rm_compra[i].cant_ven   = r_c11.c11_cant_ped - r_c11.c11_cant_rec
	LET rm_compra[i].item       = r_c11.c11_codigo
	LET rm_compra[i].descuento  = r_c11.c11_descuento
	LET rm_compra[i].precio     = r_c11.c11_precio
	LET rm_compra[i].total      = r_c11.c11_precio * rm_compra[i].cant_ven

	LET rm_datos[i].item        = r_r10.r10_nombre
	LET rm_datos[i].val_descto  = r_c11.c11_val_descto
	LET rm_datos[i].costo_base  = rm_compra[i].total-rm_datos[i].val_descto
	LET rm_datos[i].costo_adi   = 0
	LET i = i + 1
	IF i > vm_max_compra THEN
		CALL fl_mensaje_arreglo_incompleto()
		LET INT_FLAG = 1
		RETURN 0  
	END IF
END FOREACH
FREE q_ord

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



FUNCTION muestra_etiquetas()

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r01		RECORD LIKE rept001.*

DISPLAY BY NAME	rm_r19.r19_fecing
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING r_c10.*
CALL etiquetas_orden_compra(r_c10.*)
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
		--CALL fgl_winmessage(vg_producto,'No existe factor de conversión para esta moneda.','exclamation')
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)

DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran

DEFINE resp		CHAR(6)
DEFINE retVal 		SMALLINT

LET retVal = -1
WHILE retVal = -1

LET retVal = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, modulo,
		'AA', tipo_tran)
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

--#DISPLAY 'Disp'   		TO bt_cant_ped
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
	INITIALIZE rm_r19.r19_moneda,
		   rm_r19.r19_descuento,
		   rm_r19.r19_porc_impto,
		   vm_num_aut, vm_serie_comp, vm_fecha_cadu
	 	TO NULL
	CLEAR cod_proveedor, n_proveedor, n_moneda, vm_num_aut, vm_serie_comp,
		c10_flete, c10_otros, vm_fecha_cadu
ELSE
	LET rm_r19.r19_descuento  = r_c10.c10_porc_descto
	LET rm_r19.r19_porc_impto = r_c10.c10_porc_impto
	LET rm_r19.r19_cont_cred  = r_c10.c10_tipo_pago

	DISPLAY BY NAME r_c10.c10_flete, r_c10.c10_otros
	DISPLAY r_c10.c10_codprov TO cod_proveedor
	CALL fl_lee_proveedor(r_c10.c10_codprov) RETURNING r_p01.*
	LET rm_p01.* = r_p01.*
	DISPLAY r_p01.p01_nomprov TO n_proveedor

	CALL fl_lee_moneda(r_c10.c10_moneda) RETURNING r_g13.*
	LET rm_r19.r19_moneda      = r_g13.g13_moneda
	LET rm_r19.r19_precision   = r_g13.g13_decimales
	LET rm_r19.r19_paridad     = calcula_paridad(rm_r19.r19_moneda,
						     rg_gen.g00_moneda_base)
	DISPLAY r_g13.g13_nombre TO n_moneda    
END IF

DISPLAY BY NAME rm_r19.r19_moneda,
		rm_r19.r19_descuento,
		rm_r19.r19_porc_impto

END FUNCTION



FUNCTION calcula_totales()

DEFINE i      	 	SMALLINT

DEFINE costo 		LIKE rept019.r19_tot_costo
DEFINE bruto		LIKE rept019.r19_tot_bruto
DEFINE precio		LIKE rept019.r19_tot_neto  
DEFINE descto       	LIKE rept019.r19_tot_dscto
	
DEFINE iva          	LIKE rept019.r19_tot_dscto

DEFINE r_c10		RECORD LIKE ordt010.*

LET precio    = 0	-- TOTAL NETO  
LET descto    = 0 	-- TOTAL DESCUENTO
LET bruto     = 0 	-- TOTAL BRUTO     

FOR i = 1 TO vm_indice
	IF rm_compra[i].total IS NOT NULL THEN
		LET rm_datos[i].val_descto = 
			rm_compra[i].total * (rm_compra[i].descuento / 100)
		LET bruto = bruto + rm_compra[i].total
	END IF
	IF rm_datos[i].val_descto IS NOT NULL THEN
		LET descto = descto + rm_datos[i].val_descto
	END IF
END FOR

LET iva    = (bruto - descto + rm_c10.c10_otros + rm_c10.c10_dif_cuadre) *
             (rm_r19.r19_porc_impto / 100)                                
             
LET precio = (bruto - descto) + rm_c10.c10_dif_cuadre + iva

LET rm_r19.r19_tot_dscto  = descto
LET rm_r19.r19_tot_bruto  = bruto
LET rm_r19.r19_tot_neto   = precio
LET rm_r19.r19_tot_costo  = rm_c10.c10_dif_cuadre
LET rm_r19.r19_tot_neto   = rm_r19.r19_tot_neto + rm_c10.c10_flete +
			    rm_c10.c10_otros
DISPLAY BY NAME rm_r19.r19_tot_bruto,
                rm_r19.r19_tot_dscto,
                iva,
                rm_r19.r19_tot_neto,
                rm_c10.c10_dif_cuadre
                
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



FUNCTION graba_detalle(r_c13)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE i		SMALLINT
DEFINE orden    	SMALLINT
DEFINE costo_ing	DECIMAL(12,2)
DEFINE costo_nue	DECIMAL(12,2)
DEFINE descto_unit	DECIMAL(12,2)
DEFINE costo_adi_unit	DECIMAL(12,2)
DEFINE r_r10, r_aux	RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c14		RECORD LIKE ordt014.*

INITIALIZE r_r20.* TO NULL
LET r_r20.r20_compania  = vg_codcia
LET r_r20.r20_localidad = vg_codloc
LET r_r20.r20_cod_tran  = rm_r19.r19_cod_tran
LET r_r20.r20_num_tran  = rm_r19.r19_num_tran

LET r_r20.r20_cant_dev   = 0
LET r_r20.r20_cant_ent   = 0
LET r_r20.r20_costnue_mb = 0
LET r_r20.r20_costnue_ma = 0

LET r_r20.r20_fecing     = CURRENT

LET orden = 1
CALL prorratea_costos_adicionales()
FOR i = 1 TO vm_indice
	IF rm_compra[i].cant_ven = 0 THEN
		CONTINUE FOR
	END IF
	LET r_r20.r20_orden      = orden
	LET orden = orden + 1                      
	LET descto_unit    = rm_datos[i].val_descto / rm_compra[i].cant_ven 
	LET costo_adi_unit = rm_datos[i].costo_adi / rm_compra[i].cant_ven 
	LET descto_unit    = fl_retorna_precision_valor(rm_r19.r19_moneda, descto_unit)
	LET costo_adi_unit = fl_retorna_precision_valor(rm_r19.r19_moneda, costo_adi_unit)
	LET costo_ing      = rm_compra[i].precio - descto_unit + costo_adi_unit
			 
	CALL fl_obtiene_costo_item(vg_codcia, rm_r19.r19_moneda,rm_compra[i].item,
			rm_compra[i].cant_ven, costo_ing)
		RETURNING costo_nue
    	CALL fl_lee_item(vg_codcia, rm_compra[i].item) RETURNING r_r10.*
	LET r_aux.* = r_r10.*
	LET r_r10.r10_precio_ant  = r_r10.r10_precio_mb
	LET r_r10.r10_fec_camprec = CURRENT
	LET r_r10.r10_precio_mb   = costo_nue + 
				   (costo_nue * rm_r19.r19_fact_venta / 100)
	LET r_r10.r10_precio_mb   = fl_retorna_precision_valor(rm_r19.r19_moneda, r_r10.r10_precio_mb)
	LET r_r10.r10_costo_mb    = costo_nue
	LET r_r20.r20_costnue_mb  = costo_nue
	LET r_r10.r10_costult_mb  = costo_ing
	--LET r_r10.r10_fob         = costo_ing
	LET r_r10.r10_fob         = rm_compra[i].precio - descto_unit
								-- 20-05-2008
	UPDATE rept010 SET r10_costo_mb		= r_r10.r10_costo_mb,
	                   r10_costult_mb	= r_r10.r10_costult_mb,
			   r10_fob              = r_r10.r10_fob
	                   --r10_precio_mb	= r_r10.r10_precio_mb,
	                   --r10_precio_ant	= r_r10.r10_precio_ant,
	                   --r10_fec_camprec	= r_r10.r10_fec_camprec
		WHERE r10_compania = vg_codcia AND 
		      r10_codigo   = rm_compra[i].item
	SELECT SUM(r11_stock_act) INTO r_r20.r20_stock_bd FROM rept011
		WHERE r11_compania  = vg_codcia AND
		      r11_item      = rm_compra[i].item   -- Stock anterior en 
							-- todas las bodegas
	IF r_r20.r20_stock_bd IS NULL THEN
		LET r_r20.r20_stock_bd = 0
	END IF
	LET done = actualiza_existencias(i)
	IF NOT done THEN
		RETURN done
	END IF

	LET r_r20.r20_cant_ven   = rm_compra[i].cant_ven
    	LET r_r20.r20_descuento  = rm_compra[i].descuento
    	LET r_r20.r20_val_descto = rm_datos[i].val_descto
    	LET r_r20.r20_val_impto  = 
		rm_compra[i].total * (rm_r19.r19_porc_impto / 100)
	LET r_r20.r20_val_impto  = fl_retorna_precision_valor(rm_r19.r19_moneda, r_r20.r20_val_impto)

	LET r_r20.r20_cant_ped   = rm_compra[i].cant_ped   

    	LET r_r20.r20_linea      = r_r10.r10_linea				
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion
	LET r_r20.r20_fob        = r_r10.r10_fob             
	LET r_r20.r20_costant_mb = r_aux.r10_costo_mb
	LET r_r20.r20_costant_ma = r_aux.r10_costo_ma

	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,	
		rm_compra[i].item) RETURNING r_r11.*
	IF r_r11.r11_compania IS NULL THEN
		LET r_r20.r20_ubicacion = 'SN'
    		LET r_r20.r20_stock_ant = 0 
	ELSE
		LET r_r20.r20_ubicacion = r_r11.r11_ubicacion
    		LET r_r20.r20_stock_ant = 
			r_r11.r11_stock_act - r_r20.r20_cant_ped
	END IF
	LET r_r20.r20_bodega     = rm_r19.r19_bodega_ori
	LET r_r20.r20_item       = rm_compra[i].item       
	LET r_r20.r20_precio     = rm_compra[i].precio

	LET r_r20.r20_cant_ent   = rm_compra[i].cant_ven   
	--LET r_r20.r20_costo      = rm_compra[i].precio
	LET r_r20.r20_costo      = costo_ing	-- PUESTO EL 09-02-2009

	INSERT INTO rept020 VALUES (r_r20.*)
	
	-- Graba detalle de recepcion
	LET r_c14.c14_compania   = vg_codcia
	LET r_c14.c14_localidad  = vg_codloc
	LET r_c14.c14_numero_oc  = rm_r19.r19_oc_interna
	LET r_c14.c14_num_recep  = r_c13.c13_num_recep
	LET r_c14.c14_secuencia  = orden - 1	-- Arriba incremente orden
	LET r_c14.c14_codigo     = rm_compra[i].item  
	LET r_c14.c14_cantidad   = rm_compra[i].cant_ven
	LET r_c14.c14_descrip    = r_r10.r10_nombre  
	LET r_c14.c14_descuento  = rm_compra[i].descuento  
	LET r_c14.c14_val_descto = rm_datos[i].val_descto
	LET r_c14.c14_precio     = rm_compra[i].precio
	LET r_c14.c14_val_impto  = ((r_c14.c14_cantidad * r_c14.c14_precio) -
 				    r_c14.c14_val_descto) * 
				   rm_r19.r19_porc_impto / 100	
	LET r_c14.c14_paga_iva   = 'S'
	INSERT INTO ordt014 VALUES(r_c14.*)
END FOR 
LET done = 1

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
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = rm_r19.r19_bodega_ori
				  AND r11_item     = rm_compra[i].item
			FOR UPDATE
	OPEN q_r11
	FETCH q_r11 INTO r_r11.*
	WHENEVER ERROR STOP
	IF status = NOTFOUND THEN
		INSERT INTO rept011 VALUES (vg_codcia, rm_r19.r19_bodega_ori,
			rm_compra[i].item, 'SN', NULL, 0, 0, 0, 0, 
			NULL, NULL, NULL, NULL, NULL, NULL)
		CONTINUE WHILE
	END IF
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

IF r_r11.r11_compania IS NOT NULL THEN
	UPDATE rept011 SET r11_stock_ant = r11_stock_act,
			   r11_stock_act = r11_stock_act + 
					   rm_compra[i].cant_ven,
  		   	   r11_ing_dia   = rm_compra[i].cant_ven
		WHERE CURRENT OF q_r11
END IF
CLOSE q_r11
FREE q_r11

RETURN done

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
		CLOSE q_c11
		FREE  q_c11
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
			UPDATE ordt011 SET c11_cant_rec = c11_cant_rec + 
					   rm_compra[i].cant_ven
				WHERE CURRENT OF q_c11
			EXIT FOR
		END IF
	END FOR
	
	INITIALIZE r_c11.* TO NULL
	FETCH q_c11 INTO r_c11.*
END WHILE
CLOSE q_c11
FREE  q_c11

RETURN done

END FUNCTION



FUNCTION control_mostrar_det()
DEFINE i, j		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(1, vm_indice)
CALL set_count(vm_indice)
DISPLAY ARRAY rm_compra TO ra_compra.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_3() 
	ON KEY(F5)
		LET i = arr_curr()	
		IF tiene_item_cruce(rm_compra[i].item) THEN
			CALL muestra_facturas_cruce(i)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF tiene_facturas_cruce() THEN
			CALL muestra_fact_items_cruce()
			LET int_flag = 0
		END IF
	ON KEY(F7)
		CALL control_imprimir(0)
		LET int_flag = 0
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL muestra_contadores_det(i, vm_indice)
		CALL fl_lee_item(vg_codcia,rm_compra[i].item) RETURNING r_r10.*
		CALL muestra_descripciones(rm_compra[i].item,
			r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, 
			r_r10.r10_cod_clase)
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("F5","Facturas Cruce")
		--#CALL dialog.keysetlabel("F6","Fact. Item Cruce")
		--#CALL dialog.keysetlabel("F7","Imprimir")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_contadores_det(i, vm_indice)
		--#CALL fl_lee_item(vg_codcia,rm_compra[i].item) 
			--#RETURNING r_r10.*  
		--#CALL muestra_descripciones(rm_compra[i].item,
			--#r_r10.r10_linea, r_r10.r10_sub_linea,
			--#r_r10.r10_cod_grupo, 
			--#r_r10.r10_cod_clase)
		--#IF tiene_item_cruce(rm_compra[i].item) THEN
			--#CALL dialog.keysetlabel("F5","Facturas Cruce")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","")
		--#END IF
		--#IF tiene_facturas_cruce() THEN
			--#CALL dialog.keysetlabel("F6","Fact. Item Cruce")
		--#ELSE
			--#CALL dialog.keysetlabel("F6","")
		--#END IF
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_indice)

END FUNCTION



FUNCTION graba_cabecera_recepcion(r_c10)

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*

INITIALIZE r_c13.* TO NULL

LET r_c13.c13_compania     = vg_codcia
LET r_c13.c13_localidad    = vg_codloc
LET r_c13.c13_numero_oc    = rm_r19.r19_oc_interna
LET r_c13.c13_estado       = 'A'

LET r_c13.c13_fecha_recep = rm_r19.r19_fecing
LET r_c13.c13_num_guia    = rm_r19.r19_oc_externa
LET r_c13.c13_factura     = rm_r19.r19_oc_externa
LET r_c13.c13_bodega      = rm_r19.r19_bodega_ori
LET r_c13.c13_interes     = r_c10.c10_interes
LET r_c13.c13_tot_bruto   = rm_r19.r19_tot_bruto
LET r_c13.c13_tot_dscto   = rm_r19.r19_tot_dscto
LET r_c13.c13_tot_impto   = 
	(rm_r19.r19_tot_neto - rm_r19.r19_tot_bruto) + rm_r19.r19_tot_dscto - 
	 rm_c10.c10_dif_cuadre - rm_c10.c10_flete - rm_c10.c10_otros
LET r_c13.c13_tot_recep   = rm_r19.r19_tot_neto
LET r_c13.c13_usuario     = vg_usuario
LET r_c13.c13_fecing      = rm_r19.r19_fecing

LET r_c13.c13_num_aut     = vm_num_aut
LET r_c13.c13_serie_comp  = vm_serie_comp
LET r_c13.c13_fecha_cadu  = vm_fecha_cadu
LET r_c13.c13_flete       = rm_c10.c10_flete
LET r_c13.c13_otros       = rm_c10.c10_otros
LET r_c13.c13_dif_cuadre  = rm_c10.c10_dif_cuadre

SELECT MAX(c13_num_recep) INTO r_c13.c13_num_recep
	FROM ordt013
	WHERE c13_compania  = vg_codcia
	  AND c13_localidad = vg_codloc
	  AND c13_numero_oc = rm_r19.r19_oc_interna
IF r_c13.c13_num_recep IS NULL THEN
	LET r_c13.c13_num_recep = 1
ELSE
	LET r_c13.c13_num_recep = r_c13.c13_num_recep + 1
END IF
INSERT INTO ordt013 VALUES(r_c13.*)

RETURN r_c13.*

END FUNCTION



FUNCTION orden_compra()
DEFINE param		VARCHAR(60)

LET param = ' ', vg_codloc, ' ', rm_r19.r19_oc_interna
CALL ejecuta_comando('COMPRAS', 'OC', 'ordp200 ', param)

END FUNCTION



FUNCTION control_forma_pago(r_c10, r_c13)
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE tot_compra	LIKE ordt010.c10_tot_compra
DEFINE i 		SMALLINT

OPEN WINDOW w_214_2 AT 6,5 WITH 17 ROWS, 74 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)		  
IF vg_gui = 1 THEN
	OPEN FORM f_214_2 FROM '../forms/repf214_2'
ELSE
	OPEN FORM f_214_2 FROM '../forms/repf214_2c'
END IF
DISPLAY FORM f_214_2

LET tot_compra = rm_r19.r19_tot_neto
DISPLAY BY NAME tot_compra

CALL control_DISPLAY_botones_2()

IF i = 1 THEN
	LET pagos      = 1 
-- OjO
-- fecha_pago debe ser TODAY + credit_dias (definido en la cxpt002)
	CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, r_c10.c10_codprov)
		RETURNING r_p02.*
	LET fecha_pago = TODAY + r_p02.p02_credit_dias
	LET dias_pagos = r_p02.p02_credit_dias
	LET tot_cap    = 0
	LET tot_int    = 0
	LET tot_sub    = 0
	DISPLAY BY NAME fecha_pago, dias_pagos, tot_cap, tot_int, tot_sub
END IF

CALL control_ingreso_forma_pago_oc(r_c10.*)
IF NOT INT_FLAG THEN
	CALL control_cargar_detalle_forma_pago(r_c10.*)
END IF

CLOSE WINDOW w_214_2

END FUNCTION



FUNCTION control_DISPLAY_botones_2()

--#DISPLAY '#'        		TO tit_col1
--#DISPLAY 'Fecha Vcto'		TO tit_col2
--#DISPLAY 'Valor Capital'	TO tit_col3
--#DISPLAY 'Valor Interes'	TO tit_col4
--#DISPLAY 'Subtotal'		TO tit_col5

END FUNCTION



FUNCTION control_ingreso_forma_pago_oc(r_c10)

DEFINE resp 		CHAR(6)

DEFINE r_c10		RECORD LIKE ordt010.*

LET pagos       = 1
LET c10_interes = r_c10.c10_interes
LET fecha_pago  = TODAY + 30
LET dias_pagos  = 30

INPUT BY NAME pagos, c10_interes, fecha_pago, dias_pagos WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD fecha_pago
		IF fecha_pago < TODAY OR fecha_pago IS NULL THEN
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
END INPUT

END FUNCTION



FUNCTION control_cargar_detalle_forma_pago(r_c10)

DEFINE r_c10		RECORD LIKE ordt010.*

DEFINE resp		CHAR(6)
DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE saldo    	LIKE ordt010.c10_tot_compra
DEFINE val_div  	LIKE ordt010.c10_tot_compra

DEFINE salir		SMALLINT

LET saldo   = rm_r19.r19_tot_neto
LET val_div = saldo / pagos

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

CALL calcula_interes(r_c10.*)

IF c10_interes > 0 THEN
	CALL set_count(pagos)
	CALL mostrar_el_array_fp()
	RETURN
END IF

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31

LET salir = 0
WHILE NOT salir
	CALL set_count(pagos)
	INPUT ARRAY r_detalle_2 WITHOUT DEFAULTS FROM r_detalle_2.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT INPUT
			END IF	
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel('DELETE', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE INSERT
			EXIT INPUT
		BEFORE DELETE
			EXIT INPUT
		AFTER FIELD c12_valor_cap
			CALL calcula_total_forma_pago(pagos)
		AFTER FIELD c12_valor_int
			CALL calcula_total_forma_pago(pagos)
		AFTER INPUT 
			IF tot_cap <> rm_r19.r19_tot_neto THEN
				--CALL fgl_winmessage(vg_producto,'El valor capital no coincide con el valor neto de la deuda.','exclamation')
				CALL fl_mostrar_mensaje('El valor capital no coincide con el valor neto de la deuda.','exclamation')
				CONTINUE INPUT
			END IF
			LET salir = 1
	END INPUT
	IF INT_FLAG THEN
		LET salir = 1
	END IF
END WHILE

END FUNCTION



FUNCTION calcula_interes(r_c10)

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE valor		LIKE ordt012.c12_valor_cap
DEFINE i 		SMALLINT

LET tot_cap = 0
LET tot_int = 0
LET tot_sub = 0
LET valor   = rm_r19.r19_tot_neto

FOR i = 1 TO pagos

	LET r_detalle_2[i].c12_valor_int = valor * 
			                   (c10_interes / 100) *
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



FUNCTION graba_vencimientos_recepcion_parcial(r_c13)

DEFINE i		SMALLINT
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c15		RECORD LIKE ordt015.*

LET r_c15.c15_compania  = vg_codcia
LET r_c15.c15_localidad = vg_codloc
LET r_c15.c15_numero_oc = rm_r19.r19_oc_interna
LET r_c15.c15_num_recep = r_c13.c13_num_recep

FOR i = 1 TO pagos
	LET r_c15.c15_dividendo   = r_detalle_2[i].c12_dividendo
	LET r_c15.c15_fecha_vcto  = r_detalle_2[i].c12_fecha_vcto
	LET r_c15.c15_valor_cap   = r_detalle_2[i].c12_valor_cap
	LET r_c15.c15_valor_int   = r_detalle_2[i].c12_valor_int
	
	INSERT INTO ordt015 VALUES(r_c15.*)
END FOR

END FUNCTION



FUNCTION genera_documentos_deudores(r_c13, r_c10)

DEFINE i		SMALLINT

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c15		RECORD LIKE ordt015.*
DEFINE r_p20		RECORD LIKE cxpt020.*

LET r_p20.p20_compania    = vg_codcia
LET r_p20.p20_localidad   = vg_codloc
LET r_p20.p20_codprov     = r_c10.c10_codprov
LET r_p20.p20_usuario     = vg_usuario
LET r_p20.p20_fecing      = CURRENT
LET r_p20.p20_fecha_emi	  = TODAY
LET r_p20.p20_tipo_doc    = 'FA'
LET r_p20.p20_num_doc     = rm_r19.r19_oc_externa
LET r_p20.p20_referencia  = 'COMPRA LOCAL # ' || rm_r19.r19_num_tran
LET r_p20.p20_porc_impto  = rm_r19.r19_porc_impto
IF c10_interes IS NULL THEN
	LET r_p20.p20_tasa_int    = 0
ELSE
	LET r_p20.p20_tasa_int    = c10_interes
END IF	
LET r_p20.p20_tasa_mora   = 0
LET r_p20.p20_moneda	  = rm_r19.r19_moneda
LET r_p20.p20_paridad     = rm_r19.r19_paridad
LET r_p20.p20_valor_fact  = rm_r19.r19_tot_neto
LET r_p20.p20_valor_impto = rm_r19.r19_tot_neto + rm_r19.r19_tot_dscto -
			    rm_r19.r19_tot_bruto - r_c10.c10_flete -
			    r_c10.c10_otros      - r_c10.c10_dif_cuadre
-- OjO
LET r_p20.p20_cod_depto  = r_c10.c10_cod_depto
LET r_p20.p20_cartera    = 6
LET r_p20.p20_numero_oc  = rm_r19.r19_oc_interna
LET r_p20.p20_origen     = 'A'			-- automatico

IF rm_r19.r19_cont_cred = 'R' THEN
	DECLARE q_c15 CURSOR FOR 
		SELECT * FROM ordt015
			WHERE c15_compania  = vg_codcia
	  	  	  AND c15_localidad = vg_codloc
	  	  	  AND c15_numero_oc = r_c13.c13_numero_oc
	  	     	  AND c15_num_recep = r_c13.c13_num_recep

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
	LET r_p20.p20_referencia  = 'COMPRA LOCAL # ' || rm_r19.r19_num_tran 
				    || ' CONTADO'
	LET r_p20.p20_dividendo  = 1
	LET r_p20.p20_fecha_vcto = TODAY
	LET r_p20.p20_valor_cap  = rm_r19.r19_tot_neto
	LET r_p20.p20_valor_int  = 0
	LET r_p20.p20_saldo_cap  = rm_r19.r19_tot_neto
	LET r_p20.p20_saldo_int  = 0
	
	INSERT INTO cxpt020 VALUES(r_p20.*)
END IF

END FUNCTION



FUNCTION forma_pago_oc(r_c13)

DEFINE sql_expr		CHAR(300)
DEFINE r_c13		RECORD LIKE ordt013.*

LET sql_expr = 'INSERT INTO ordt015 ',
	       '	SELECT c12_compania, c12_localidad, c12_numero_oc, ',
	         	       r_c13.c13_num_recep, ', c12_dividendo, ', 
	       '  	       c12_fecha_vcto, c12_valor_cap, c12_valor_int ',
	       '	FROM ordt012 ',
	       '	WHERE c12_compania  = ', vg_codcia,
	       '	AND c12_localidad = ',   vg_codloc,
	       '	AND c12_numero_oc = ', rm_r19.r19_oc_interna
	       
PREPARE statement1 FROM sql_expr
EXECUTE statement1

LET c10_interes = r_c13.c13_interes

END FUNCTION



FUNCTION calcula_total_forma_pago(num_elm)

DEFINE i			SMALLINT
DEFINE num_elm			SMALLINT

LET tot_cap = 0
LET tot_sub = 0
LET tot_int = 0
FOR i = 1 TO num_elm
	IF r_detalle_2[i].c12_valor_cap IS NOT NULL THEN
		LET tot_cap = tot_cap + r_detalle_2[i].c12_valor_cap
		LET tot_sub = tot_sub + r_detalle_2[i].c12_valor_cap
		LET r_detalle_2[i].subtotal = r_detalle_2[i].c12_valor_cap +
			r_detalle_2[i].c12_valor_int
	END IF
	IF r_detalle_2[i].c12_valor_int IS NOT NULL THEN
		LET tot_int = tot_int + r_detalle_2[i].c12_valor_int
		LET tot_sub = tot_sub + r_detalle_2[i].c12_valor_int
		LET r_detalle_2[i].subtotal = r_detalle_2[i].c12_valor_cap +
			r_detalle_2[i].c12_valor_int
	END IF
	DISPLAY r_detalle_2[i].subtotal TO r_detalle_2[i].subtotal
END FOR

DISPLAY BY NAME tot_int, tot_sub, tot_cap

END FUNCTION



FUNCTION muestra_forma_pago()

IF rm_r19.r19_cont_cred = 'C' THEN
	--CALL fgl_winmessage(vg_producto,'Esta compra se realizó al contado.','exclamation')
	CALL fl_mostrar_mensaje('Esta compra se realizó al contado.','exclamation')
	RETURN
END IF
		
OPEN WINDOW w_202_3 AT 6,8 WITH 16 ROWS, 71 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
	BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_202_3 FROM '../forms/repf214_2'
ELSE
	OPEN FORM f_202_3 FROM '../forms/repf214_2c'
END IF
DISPLAY FORM f_202_3

CALL control_DISPLAY_botones_2()
LET INT_FLAG = 0
CALL control_cargar_ordt015_1()
IF INT_FLAG THEN
	CLOSE WINDOW w_202_3
	RETURN
END IF
CALL control_DISPLAY_detalle_forma_pago()

CLOSE WINDOW w_202_3
		
END FUNCTION		



FUNCTION control_cargar_ordt015_1()

DEFINE i,k,filas	SMALLINT

DEFINE tot_recep 	LIKE rept019.r19_tot_neto

DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c15		RECORD LIKE ordt015.*

DECLARE q_ordt015 CURSOR FOR 
	SELECT * FROM ordt015, ordt013
		WHERE c13_compania  = vg_codcia
		  AND c13_localidad = vg_codloc
		  AND c13_numero_oc = rm_r19.r19_oc_interna
		  AND c13_factura   = rm_r19.r19_oc_externa
		  AND c15_compania  = c13_compania
		  AND c15_localidad = c13_localidad
		  AND c15_numero_oc = c13_numero_oc
		  AND c15_num_recep = c13_num_recep

LET tot_cap = 0
LET tot_int = 0
LET tot_sub = 0
LET i = 1
FOREACH q_ordt015 INTO r_c15.*, r_c13.*

	LET r_detalle_2[i].c12_dividendo  = r_c15.c15_dividendo
	LET r_detalle_2[i].c12_fecha_vcto = r_c15.c15_fecha_vcto
	LET r_detalle_2[i].c12_valor_cap  = r_c15.c15_valor_cap
	LET r_detalle_2[i].c12_valor_int  = r_c15.c15_valor_int
	LET r_detalle_2[i].subtotal       = r_c15.c15_valor_cap +
					    r_c15.c15_valor_int

	LET tot_cap = tot_cap + r_c15.c15_valor_cap	
	LET tot_int = tot_int + r_c15.c15_valor_int	
	LET tot_sub = tot_sub + r_detalle_2[i].subtotal	

	LET i = i + 1

END FOREACH

LET i = i - 1

IF i = 0 THEN
	--CALL fgl_winmessage(vg_producto,'No existe forma de pago.','exclamation')
	CALL fl_mostrar_mensaje('No existe forma de pago.','exclamation')
	LET INT_FLAG = 1
	RETURN
END IF

LET fecha_pago = r_detalle_2[1].c12_fecha_vcto
LET tot_recep = tot_cap

IF i > 1 THEN
	LET dias_pagos = r_detalle_2[2].c12_fecha_vcto -
		 	 r_detalle_2[1].c12_fecha_vcto 
ELSE
	LET dias_pagos = 
		r_detalle_2[1].c12_fecha_vcto - date(r_c13.c13_fecing)
END IF
LET tot_dias = r_detalle_2[i].c12_fecha_vcto - TODAY

LET pagos = i
DISPLAY tot_recep TO tot_compra
DISPLAY r_c13.c13_interes TO c10_interes
DISPLAY BY NAME dias_pagos, pagos, tot_cap, tot_int, 
		tot_sub,   fecha_pago, tot_dias

END FUNCTION



FUNCTION mostrar_el_array_fp()

LET int_flag = 0
DISPLAY ARRAY r_detalle_2 TO r_detalle_2.* 
        ON KEY(F12)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_2() 
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('INTERRUPT','')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_DISPLAY_detalle_forma_pago()

IF pagos > 0 THEN
	CALL set_count(pagos)
END IF
CALL mostrar_el_array_fp()

END FUNCTION



FUNCTION control_menu2(r_c13, r_c10)

DEFINE i		SMALLINT
DEFINE done 		SMALLINT

DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_c00		RECORD LIKE ordt000.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_p05		RECORD LIKE cxpt005.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE resp 		CHAR(6)

CALL fl_lee_proveedor(r_c10.c10_codprov)	RETURNING r_p01.*
CALL fl_lee_compania_orden_compra(vg_codcia)	RETURNING r_c00.*

LET val_servi  = 0
LET val_bienes = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto +
		 rm_c10.c10_dif_cuadre + rm_c10.c10_otros     
LET val_impto  = val_bienes * (rm_r19.r19_porc_impto / 100)
LET val_neto   = rm_r19.r19_tot_neto
LET val_pagar  = val_neto
LET val_bienes = val_bienes + rm_c10.c10_flete
LET tot_ret    = 0

LET ind_ret = 0
IF r_c00.c00_cuando_ret = 'C' THEN
	DECLARE q_ret CURSOR FOR
		SELECT * FROM ordt002, OUTER cxpt005
			WHERE c02_compania   = vg_codcia
		  	  AND p05_compania   = c02_compania
		  	  AND p05_codprov    = r_c10.c10_codprov
		  	  AND p05_tipo_ret   = c02_tipo_ret
		  	  AND p05_porcentaje = c02_porcentaje 

	LET i = 1
	FOREACH q_ret INTO r_c02.*, r_p05.*
		IF r_c02.c02_tipo_ret = 'F' AND r_p01.p01_ret_fuente = 'N' 
		THEN
			CONTINUE FOREACH
		END IF
		IF r_c02.c02_tipo_ret = 'I' AND r_p01.p01_ret_impto = 'N' 
		THEN
			CONTINUE FOREACH
		END IF
		LET r_ret[i].n_retencion = r_c02.c02_nombre
		LET r_ret[i].tipo_ret    = r_c02.c02_tipo_ret
		LET r_ret[i].porc        = r_c02.c02_porcentaje
		LET r_ret[i].val_base    = 0
		LET r_ret[i].subtotal    = 0
		LET r_ret[i].check       = 'N'
		IF r_p05.p05_tipo_ret IS NOT NULL THEN
			LET r_ret[i].check = 'S'
			IF r_p05.p05_tipo_ret = 'I' THEN
				LET r_ret[i].val_base = val_impto
			ELSE
				LET r_ret[i].val_base = val_bienes
			END IF
			LET r_ret[i].subtotal = 
				(r_ret[i].val_base * 
				(r_p05.p05_porcentaje / 100))
			LET tot_ret = tot_ret + r_ret[i].subtotal 
			LET val_pagar = val_pagar - r_ret[i].subtotal
		END IF
		LET i = i + 1
		IF i > ind_max_ret THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1

	LET ind_ret = i
END IF

MENU 'OPCIONES'
	BEFORE MENU
		IF r_c00.c00_cuando_ret = 'P' THEN
			HIDE OPTION 'Retenciones'
		END IF
		IF rm_r19.r19_cont_cred = 'C' THEN
			HIDE OPTION 'Forma Pago'
		END IF
	COMMAND KEY('F') 'Forma Pago'		'Ver forma de pago.'
		IF rm_r19.r19_cont_cred = 'R' THEN
			CALL muestra_forma_pago()
		ELSE
			--CALL fgl_winmessage(vg_producto,'La compra se está realizando al contado.','exclamation')
			CALL fl_mostrar_mensaje('La compra se está realizando al contado.','exclamation')
		END IF
	COMMAND KEY('R') 'Retenciones'		'Ver retenciones.'
		IF r_c00.c00_cuando_ret = 'C' THEN
			CALL muestra_retenciones(r_c10.*)
		ELSE
			--CALL fgl_winmessage(vg_producto,'La compañía realiza las retenciones al pagar la factura.','exclamation')
			CALL fl_mostrar_mensaje('La compañía realiza las retenciones al pagar la factura.','exclamation')
		END IF
	COMMAND KEY('G') 'Grabar'		'Graba compra local.'
		LET INT_FLAG = 0
		IF r_c00.c00_cuando_ret = 'C' AND tot_ret = 0 THEN
			--CALL fgl_winquestion(vg_producto,'No se han indicado retenciones. Seguro de generar la Compra Local sin retenciones?','No','Yes|No','question',1)
			CALL fl_hacer_pregunta('No se han indicado retenciones. Seguro de generar la Compra Local sin retenciones?','No')
				RETURNING resp
			IF resp <> 'Yes' THEN
				CONTINUE MENU
			END IF
		END IF
		-- SI la compra es al contado solo grabara un registro
		CALL genera_documentos_deudores(r_c13.*, r_c10.*)
		IF r_c00.c00_cuando_ret = 'C' THEN
			LET done = graba_retenciones(r_c10.*)
			-- SI done = 1 hubieron retenciones
			-- SI done = 0 no hubieron retenciones y no se 
			-- hara ajuste
			INITIALIZE rm_p29.* TO NULL
			IF validar_num_sri(1) <> 1 THEN
				ROLLBACK WORK
				EXIT PROGRAM
			END IF
			CALL genera_num_ret_sri()
			IF done THEN
				UPDATE rept019
					SET r19_num_ret = vm_num_ret
					WHERE r19_compania = rm_r19.r19_compania
					AND  r19_localidad= rm_r19.r19_localidad
					AND  r19_cod_tran = rm_r19.r19_cod_tran
					AND  r19_num_tran = rm_r19.r19_num_tran
				CALL graba_ajuste_retencion(r_c10.*)
				-- REGRESA INT_FLAG = 1 CUANDO HUBO UN ERROR EN
				-- LA FUNCION DE SECUENCIAS DE TRANSACCIONES Y 
				-- DEBE DESHACER TODO
				IF INT_FLAG THEN
					LET INT_FLAG = 1
					EXIT MENU
				END IF
			END IF
		END IF
		-- SI la compra local es al contado debe grabarse un ajuste
		-- para darse de baja el documento
		IF rm_r19.r19_cont_cred = 'C' THEN
			CALL graba_ajuste_documento_contado(r_c10.*)
			IF INT_FLAG THEN
				LET INT_FLAG = 1
				EXIT MENU
			END IF
		END IF
		CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, 
					        r_c10.c10_codprov)
		LET INT_FLAG = 0
		EXIT MENU
	COMMAND KEY('C') 'Cancelar'		'Cancela compra local.'
		LET INT_FLAG = 1
		EXIT MENU	
END MENU	

END FUNCTION



FUNCTION muestra_retenciones(r_c10)

DEFINE resp		CHAR(6)
DEFINE c		CHAR(1)
DEFINE salir		SMALLINT
DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE iva 		SMALLINT

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*

OPEN WINDOW w_214_4 AT 4,9 WITH 20 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)		  
IF vg_gui = 1 THEN
	OPEN FORM f_214_4 FROM '../forms/repf214_3'
ELSE
	OPEN FORM f_214_4 FROM '../forms/repf214_3c'
END IF
DISPLAY FORM f_214_4

CALL fl_lee_proveedor(r_c10.c10_codprov)	RETURNING r_p01.*
DISPLAY r_p01.p01_nomprov TO n_proveedor

DISPLAY BY NAME val_servi, val_bienes, val_impto, val_neto, val_pagar, tot_ret

OPTIONS 
	INSERT KEY F40,
	DELETE KEY F41

LET salir = 0
WHILE NOT salir
IF ind_ret > 0 THEN
	CALL set_count(ind_ret)
ELSE
	--CALL fgl_winmessage(vg_producto,'No hay datos a mostrar.','exclamation')
	CALL fl_mostrar_mensaje('No hay datos a mostrar.','exclamation')
	RETURN
END IF
INPUT ARRAY r_ret WITHOUT DEFAULTS FROM ra_ret.*
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
		CALL setea_nombre_botones_f3()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE INSERT
		EXIT INPUT
	BEFORE DELETE
		EXIT INPUT
	BEFORE FIELD check
		LET c = r_ret[i].check
	AFTER  FIELD check
		IF c <> r_ret[i].check THEN
			IF r_ret[i].check = 'S' THEN
				IF r_ret[i].tipo_ret = 'I' THEN
					LET r_ret[i].val_base = val_impto
				ELSE
					LET r_ret[i].val_base = val_bienes
				END IF
				LET r_ret[i].subtotal = 
					(r_ret[i].val_base * 
					(r_ret[i].porc / 100))	
				LET val_pagar = val_pagar - r_ret[i].subtotal
				LET tot_ret = tot_ret + r_ret[i].subtotal
			END IF
			IF r_ret[i].check = 'N' THEN
				LET val_pagar = val_pagar + r_ret[i].subtotal
				LET tot_ret = tot_ret - r_ret[i].subtotal
				LET r_ret[i].val_base = 0
				LET r_ret[i].subtotal = 0
			END IF
			DISPLAY r_ret[i].* TO ra_ret[j].*
			DISPLAY BY NAME val_pagar, tot_ret
			--NEXT FIELD ra_ret[j].check
			NEXT FIELD check
		END IF
	AFTER INPUT 
		IF tot_ret > val_neto THEN
			--CALL fgl_winmessage(vg_producto,'El valor de las retenciones no debe ser mayor al valor neto.','exclamation')
			CALL fl_mostrar_mensaje('El valor de las retenciones no debe ser mayor al valor neto.','exclamation')
			CONTINUE INPUT
		END IF
		LET iva = 0
		FOR i = 1 TO ind_ret 
			IF r_ret[i].check = 'S' AND r_ret[i].tipo_ret = 'I'
			THEN
				LET iva = iva + r_ret[i].porc
			END IF
		END FOR
		IF iva > 100 THEN
			--CALL fgl_winmessage(vg_producto,'Las retenciones sobre el iva no pueden exceder al 100% del iva.','exclamation')
			CALL fl_mostrar_mensaje('Las retenciones sobre el iva no pueden exceder al 100% del iva.','exclamation')
			CONTINUE INPUT
		END IF
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_214_4
	RETURN
END IF

END WHILE

CLOSE WINDOW w_214_4

END FUNCTION



FUNCTION graba_ajuste_retencion(r_c10)

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE r_p28		RECORD LIKE cxpt028.*

DEFINE i		SMALLINT
DEFINE orden		SMALLINT

INITIALIZE r_p22.* TO NULL
INITIALIZE r_p23.* TO NULL

-- Graba Cabecera Ajuste Documento
LET r_p22.p22_compania   = vg_codcia
LET r_p22.p22_localidad  = vg_codloc
LET r_p22.p22_codprov    = r_c10.c10_codprov
LET r_p22.p22_tipo_trn   = vm_ajuste

LET r_p22.p22_num_trn    = nextValInSequence('TE', r_p22.p22_tipo_trn)
IF r_p22.p22_num_trn     = -1 THEN
	LET INT_FLAG = 1
	RETURN
END IF

LET r_p22.p22_referencia = 'RETENCIONES EN COMPRA LOCAL # '|| 
			   rm_r19.r19_num_tran
LET r_p22.p22_fecha_emi  = TODAY
LET r_p22.p22_moneda     = rm_r19.r19_moneda
LET r_p22.p22_paridad    = rm_r19.r19_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = (val_neto - val_pagar) * (-1)
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'A'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = CURRENT 

INSERT INTO cxpt022 VALUES(r_p22.*)
--------------------------------------------------------------------------

LET r_p23.p23_compania  = r_p22.p22_compania
LET r_p23.p23_localidad = r_p22.p22_localidad
LET r_p23.p23_codprov   = r_p22.p22_codprov
LET r_p23.p23_tipo_trn  = r_p22.p22_tipo_trn
LET r_p23.p23_num_trn   = r_p22.p22_num_trn

	LET r_p23.p23_tipo_doc   = 'FA'
	LET r_p23.p23_num_doc    = rm_r19.r19_oc_externa
	LET r_p23.p23_valor_int  = 0
	LET r_p23.p23_valor_mora = 0
	LET r_p23.p23_saldo_int  = 0

LET orden = 1

DECLARE q_ret2 CURSOR FOR 
	SELECT * FROM cxpt028
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_num_ret   = vm_num_ret
		ORDER BY p28_secuencia
		
FOREACH q_ret2 INTO r_p28.*
	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT 3
	DECLARE q_saldo2 CURSOR FOR
		SELECT p20_saldo_cap FROM cxpt020
			WHERE p20_compania  = vg_codcia
			  AND p20_localidad = vg_codloc
			  AND p20_codprov   = r_p23.p23_codprov
			  AND p20_tipo_doc  = r_p23.p23_tipo_doc
			  AND p20_num_doc   = r_p23.p23_num_doc
			  AND p20_dividendo = r_p28.p28_dividendo
		FOR UPDATE OF p20_saldo_cap
	SET LOCK MODE TO NOT WAIT
	WHENEVER ERROR STOP
	
	OPEN  q_saldo2
	FETCH q_saldo2 INTO r_p23.p23_saldo_cap
	IF STATUS < 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
		
	LET r_p23.p23_orden     = orden
	LET orden = orden + 1
	LET r_p23.p23_div_doc   = r_p28.p28_dividendo
	LET r_p23.p23_valor_cap = r_p28.p28_valor_ret * (-1)
		
	INSERT INTO cxpt023 VALUES(r_p23.*)
		
	UPDATE cxpt020 
		SET p20_saldo_cap = p20_saldo_cap - r_p28.p28_valor_ret
		WHERE CURRENT OF q_saldo2
			
	CLOSE q_saldo2
	FREE  q_saldo2
END FOREACH
FREE q_ret2
		  
END FUNCTION



FUNCTION graba_ajuste_documento_contado(r_c10)

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*

INITIALIZE r_p22.* TO NULL
INITIALIZE r_p23.* TO NULL

-- Graba Cabecera Ajuste Documento
LET r_p22.p22_compania   = vg_codcia
LET r_p22.p22_localidad  = vg_codloc
LET r_p22.p22_codprov    = r_c10.c10_codprov
LET r_p22.p22_tipo_trn   = vm_ajuste

LET r_p22.p22_referencia = 'COMPRA LOCAL # '|| rm_r19.r19_num_tran ||
			   ' PAGO CONTADO'
LET r_p22.p22_fecha_emi  = TODAY
LET r_p22.p22_moneda     = rm_r19.r19_moneda
LET r_p22.p22_paridad    = rm_r19.r19_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = val_pagar
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'A'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = CURRENT + 1 UNITS SECOND

LET r_p22.p22_num_trn    = nextValInSequence('TE', r_p22.p22_tipo_trn)
IF r_p22.p22_num_trn     = -1 THEN
	LET INT_FLAG = 1
	RETURN
END IF

INSERT INTO cxpt022 VALUES(r_p22.*)
--------------------------------------------------------------------------

LET r_p23.p23_compania  = r_p22.p22_compania
LET r_p23.p23_localidad = r_p22.p22_localidad
LET r_p23.p23_codprov   = r_p22.p22_codprov
LET r_p23.p23_tipo_trn  = r_p22.p22_tipo_trn
LET r_p23.p23_num_trn   = r_p22.p22_num_trn

LET r_p23.p23_tipo_doc   = 'FA'
LET r_p23.p23_num_doc    = rm_r19.r19_oc_externa
LET r_p23.p23_div_doc    = 1		-- Un solo divividendo 
LET r_p23.p23_valor_int  = 0
LET r_p23.p23_valor_mora = 0
LET r_p23.p23_saldo_int  = 0
LET r_p23.p23_orden      = 1		-- Un solo detalle
LET r_p23.p23_valor_cap  = val_pagar * (-1)
LET r_p23.p23_saldo_cap  = r_p23.p23_valor_cap  

SET LOCK MODE TO WAIT 3

DECLARE q_cont CURSOR FOR
	SELECT p20_saldo_cap
		FROM cxpt020
		WHERE p20_compania  = vg_codcia
		  AND p20_localidad = vg_codloc
		  AND p20_codprov   = r_p23.p23_codprov
		  AND p20_tipo_doc  = r_p23.p23_tipo_doc
		  AND p20_num_doc   = r_p23.p23_num_doc
		  AND p20_dividendo = r_p23.p23_div_doc
	FOR UPDATE OF p20_saldo_cap
	
SET LOCK MODE TO NOT WAIT
IF STATUS < 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
	
OPEN  q_cont
FETCH q_cont 

	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap - val_pagar
		WHERE CURRENT OF q_cont
		
CLOSE q_cont
FREE  q_cont
	  
INSERT INTO cxpt023 VALUES(r_p23.*)

END FUNCTION



FUNCTION graba_retenciones(r_c10)

DEFINE r_c10		RECORD LIKE ordt010.*

DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE r_p28		RECORD LIKE cxpt028.*

DEFINE i		SMALLINT
DEFINE done		SMALLINT
DEFINE orden		SMALLINT

DEFINE dividendo 	SMALLINT
DEFINE saldo		DECIMAL(12,2)
DEFINE mensaje		CHAR(100)

LET done = 1
IF (val_neto - val_pagar) = 0 THEN
	-- No se ha retenido nada, no se generara ajuste
	LET done = 0
	RETURN done
END IF

INITIALIZE r_p27.* TO NULL
INITIALIZE r_p28.* TO NULL

LET r_p27.p27_compania      = vg_codcia
LET r_p27.p27_localidad     = vg_codloc
LET r_p27.p27_estado        = 'A'
LET r_p27.p27_codprov       = r_c10.c10_codprov
LET r_p27.p27_moneda        = rm_r19.r19_moneda
LET r_p27.p27_paridad       = rm_r19.r19_paridad
LET r_p27.p27_total_ret     = tot_ret
LET r_p27.p27_origen        = 'A'
LET r_p27.p27_usuario       = vg_usuario
LET r_p27.p27_fecing        = CURRENT

LET r_p27.p27_num_ret = nextValInSequence('TE', vm_retencion)
IF r_p27.p27_num_ret = -1 THEN
	LET INT_FLAG = 1
	-- OJO
	RETURN 0
END IF

INSERT INTO cxpt027 VALUES(r_p27.*) 

LET vm_num_ret = r_p27.p27_num_ret
-- Graba Detalle Retencion

LET r_p28.p28_compania   = vg_codcia        
LET r_p28.p28_localidad  = vg_codloc
LET r_p28.p28_num_ret    = r_p27.p27_num_ret
LET r_p28.p28_codprov    = r_p27.p27_codprov
LET r_p28.p28_tipo_doc   = 'FA'
LET r_p28.p28_num_doc    = rm_r19.r19_oc_externa
LET r_p28.p28_valor_fact = rm_r19.r19_tot_neto

DECLARE q_saldo CURSOR FOR
	SELECT p20_dividendo, p20_saldo_cap
		FROM cxpt020
		WHERE p20_compania  = vg_codcia
		  AND p20_localidad = vg_codloc
		  AND p20_codprov   = r_p28.p28_codprov
		  AND p20_tipo_doc  = r_p28.p28_tipo_doc
		  AND p20_num_doc   = r_p28.p28_num_doc
		  AND p20_saldo_cap > 0
		ORDER BY p20_dividendo ASC

FOR i = 1 TO ind_ret
	IF r_ret[i].check = 'S' THEN
		EXIT FOR
	END IF
END FOR

-- Si no hay retenciones que hacer se borra la cabecera
IF i > ind_ret THEN
	DELETE FROM cxpt027 
		WHERE p27_compania  = r_p27.p27_compania
		  AND p27_localidad = r_p27.p27_localidad
		  AND p27_num_ret   = r_p27.p27_num_ret
	RETURN 0
END IF

LET orden = 1
FOREACH q_saldo INTO dividendo, saldo
	LET done  = 0	
	IF saldo < r_ret[i].subtotal THEN
		CONTINUE FOREACH
	END IF
		
	WHILE saldo >= r_ret[i].subtotal
		IF r_ret[i].check = 'N' THEN
			LET i = i + 1
			IF i > ind_ret THEN
				EXIT FOREACH
			END IF
			CONTINUE WHILE
		END IF
 		
		LET r_p28.p28_secuencia  = orden
		LET orden = orden + 1
		LET r_p28.p28_dividendo  = dividendo
		LET r_p28.p28_tipo_ret   = r_ret[i].tipo_ret
		LET r_p28.p28_porcentaje = r_ret[i].porc
		LET r_p28.p28_valor_base = r_ret[i].val_base
		LET r_p28.p28_valor_ret  = r_ret[i].subtotal
	
		INSERT INTO cxpt028 VALUES(r_p28.*)

		LET done = 1
		LET saldo = saldo - r_ret[i].subtotal
		LET i = i + 1
		IF i > ind_ret THEN
			EXIT FOREACH
		END IF		
	END WHILE
END FOREACH
IF NOT done THEN
	LET mensaje = 'No pudo hacerse la retención'
	CASE r_ret[i].tipo_ret
		WHEN 'I'
			LET mensaje = mensaje, ' sobre el IVA (',
				      r_ret[i].porc || '%).'
		WHEN 'F'
			LET mensaje = mensaje, ' en la fuente (',
				      r_ret[i].porc, '%).'
		OTHERWISE
			LET mensaje = mensaje, ' ', 
				      r_ret[i].tipo_ret, ' (',
				      r_ret[i].porc, '%).'
	END CASE
	--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	ROLLBACK WORK
	EXIT PROGRAM
END IF

RETURN done

END FUNCTION



FUNCTION validar_num_sri(validar)
DEFINE validar		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

CALL fl_validacion_num_sri(vg_codcia, vg_codloc, 'RT', 'N', rm_p29.p29_num_sri)
	RETURNING r_g37.*, rm_p29.p29_num_sri, flag
CASE flag
	WHEN -1
		RETURN -1
	WHEN 0
		RETURN  0
END CASE
IF validar = 1 THEN
	SELECT COUNT(*) INTO cont FROM cxpt029
		WHERE p29_compania  = vg_codcia
		  AND p29_localidad = vg_codloc
  		  AND p29_num_sri   = rm_p29.p29_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_p29.p29_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION genera_num_ret_sri()
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE cuantos		SMALLINT

WHENEVER ERROR CONTINUE
DECLARE q_sri CURSOR FOR
	SELECT * FROM gent037
		WHERE g37_compania   = vg_codcia
		  AND g37_localidad  = vg_codloc
		  AND g37_tipo_doc   = 'RT'
	  	  AND g37_fecha_emi <= DATE(TODAY)
	  	  AND g37_fecha_exp >= DATE(TODAY)
		FOR UPDATE
OPEN q_sri
FETCH q_sri INTO r_g37.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
LET cuantos = 8 + r_g37.g37_num_dig_sri
LET sec_sri = rm_p29.p29_num_sri[9, cuantos] USING "########"
UPDATE gent037
	SET g37_sec_num_sri = sec_sri
	WHERE g37_compania     = r_g37.g37_compania
	  AND g37_localidad    = r_g37.g37_localidad
	  AND g37_tipo_doc     = r_g37.g37_tipo_doc
	  AND g37_secuencia    = r_g37.g37_secuencia
	  AND g37_sec_num_sri <= sec_sri
INSERT INTO cxpt029
	VALUES (vg_codcia, vg_codloc, vm_num_ret, rm_p29.p29_num_sri)
INSERT INTO cxpt032
	VALUES (vg_codcia, vg_codloc, vm_num_ret, r_g37.g37_tipo_doc,
		r_g37.g37_secuencia)

END FUNCTION



FUNCTION setea_nombre_botones_f3()

--#DISPLAY 'Descripción' TO bt_nom_ret
--#DISPLAY 'Tipo R.'     TO bt_tipo_ret
--#DISPLAY 'Valor Base'  TO bt_base 
--#DISPLAY '%'           TO bt_porc
--#DISPLAY 'Subtotal'    TO bt_valor

END FUNCTION



FUNCTION ver_devolucion()
DEFINE param		VARCHAR(60)

LET param = ' ', vg_codloc, ' ', rm_r19.r19_cod_tran, ' ', rm_r19.r19_num_tran,
		' X D'
CALL ejecuta_comando('REPUESTOS', vg_modulo, 'repp218 ', param)

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
	--CALL fgl_winmessage(vg_producto,'No existe compra local.','exclamation')
	CALL fl_mostrar_mensaje('No existe compra local.','exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION ver_retenciones()

DEFINE resp		CHAR(6)
DEFINE salir		SMALLINT

DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p20		RECORD LIKE cxpt020.*

IF vm_num_rows <= 0 THEN
	CALL fL_mensaje_consultar_primero()
	RETURN
END IF

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING r_c10.*
IF r_c10.c10_numero_oc IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Orden de compra no existe.','exclamation')
	CALL fl_mostrar_mensaje('Orden de compra no existe.','exclamation')
	RETURN
END IF

CALL fl_lee_proveedor(r_c10.c10_codprov)	RETURNING r_p01.*
IF r_p01.p01_codprov IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
	CALL fl_mostrar_mensaje('Proveedor no existe.','exclamation')
	RETURN
END IF

CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, r_c10.c10_codprov,
				 'FA', rm_r19.r19_oc_externa, 1)
	RETURNING r_p20.*
IF r_p20.p20_num_doc IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No se generaron documentos para esta compra local.','exclamation')
	CALL fl_mostrar_mensaje('No se generaron documentos para esta compra local.','exclamation')
	RETURN
END IF

OPEN WINDOW w_214_4 AT 4,9 WITH 20 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)		  
IF vg_gui = 1 THEN
	OPEN FORM f_214_4 FROM '../forms/repf214_3'
ELSE
	OPEN FORM f_214_4 FROM '../forms/repf214_3c'
END IF
DISPLAY FORM f_214_4

DISPLAY r_p01.p01_nomprov TO n_proveedor

LET val_bienes = r_p20.p20_valor_fact - r_p20.p20_valor_impto
LET val_servi  = 0
LET val_impto  = r_p20.p20_valor_impto
LET val_neto   = r_p20.p20_valor_fact
LET val_pagar  = val_neto - tot_ret

DISPLAY BY NAME val_bienes, val_servi, val_impto, val_neto, val_pagar, tot_ret

OPTIONS 
	INSERT KEY F40,
	DELETE KEY F41

LET salir = 0
WHILE NOT salir
IF ind_ret > 0 THEN
	CALL set_count(ind_ret)
ELSE
	--CALL fgl_winmessage(vg_producto,'No hay datos a mostrar.','exclamation')
	CALL fl_mostrar_mensaje('No hay datos a mostrar.','exclamation')
	RETURN
END IF
INPUT ARRAY r_ret WITHOUT DEFAULTS FROM ra_ret.*
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
		CALL setea_nombre_botones_f3()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE INSERT
		EXIT INPUT
	BEFORE DELETE
		EXIT INPUT
	AFTER  FIELD check
		IF r_ret[i].check = 'N' THEN
			LET r_ret[i].check = 'S'
			DISPLAY r_ret[i].* TO ra_ret[j].*
			--NEXT FIELD ra_ret[j-1].check
			NEXT FIELD check
		END IF
	AFTER INPUT 
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_214_4
	RETURN
END IF

END WHILE

CLOSE WINDOW w_214_4

END FUNCTION



FUNCTION lee_retenciones()

DEFINE r_c10		RECORD LIKE ordt010.*

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING r_c10.*
IF r_c10.c10_numero_oc IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Orden de compra no existe.','exclamation')
	CALL fl_mostrar_mensaje('Orden de compra no existe.','exclamation')
	RETURN
END IF

DECLARE q_p28 CURSOR FOR
	SELECT 'S', c02_nombre, p28_tipo_ret, p28_valor_base, p28_porcentaje,
	       p28_valor_ret
		FROM cxpt028, ordt002
		WHERE p28_compania   = vg_codcia
		  AND p28_localidad  = vg_codloc
		  AND p28_codprov    = r_c10.c10_codprov
		  AND p28_tipo_doc   = 'FA'
		  AND p28_num_doc    = rm_r19.r19_oc_externa
		  AND c02_compania   = p28_compania
		  AND c02_tipo_ret   = p28_tipo_ret
		  AND c02_porcentaje = p28_porcentaje

LET tot_ret = 0
LET ind_ret = 1
FOREACH q_p28 INTO r_ret[ind_ret].*
	LET tot_ret = tot_ret + r_ret[ind_ret].subtotal
	LET ind_ret = ind_ret + 1
	IF ind_ret > ind_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH

LET ind_ret = ind_ret - 1

END FUNCTION



FUNCTION control_imprimir(flag)
DEFINE flag		SMALLINT
DEFINE impresion	CHAR(1)

IF flag THEN
	CALL imprimir_comprobante(rm_r19.r19_cod_tran, rm_r19.r19_num_tran, 1)
	CALL imprimir_transferencias()
	RETURN
END IF
IF NOT tiene_facturas_cruce() THEN
	CALL imprimir_comprobante(rm_r19.r19_cod_tran, rm_r19.r19_num_tran, 1)
	RETURN
END IF
CALL control_sel_impresion(rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
	RETURNING impresion
IF int_flag THEN
	RETURN
END IF
CASE impresion
	WHEN 'C'
		CALL imprimir_comprobante(rm_r19.r19_cod_tran,
						rm_r19.r19_num_tran, 1)
	WHEN 'T'
		CALL imprimir_transferencias()
	WHEN 'X'
		CALL imprimir_comprobante(rm_r19.r19_cod_tran,
						rm_r19.r19_num_tran, 1)
		CALL imprimir_transferencias()
END CASE

END FUNCTION



FUNCTION imprimir_transferencias()
DEFINE r_r41		RECORD LIKE rept041.*

DECLARE q_imp_tr CURSOR FOR
	SELECT * FROM rept041
		WHERE r41_compania  = rm_r19.r19_compania
		  AND r41_localidad = rm_r19.r19_localidad
		  AND r41_cod_tran  = rm_r19.r19_cod_tran
		  AND r41_num_tran  = rm_r19.r19_num_tran
		ORDER BY r41_num_tr ASC
FOREACH q_imp_tr INTO r_r41.*
	CALL imprimir_comprobante(r_r41.r41_cod_tr, r_r41.r41_num_tr, 2)
END FOREACH

END FUNCTION



FUNCTION control_sel_impresion(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE impresion	CHAR(1)
DEFINE row_max		SMALLINT
DEFINE col_max		SMALLINT

LET row_max = 11
LET col_max = 40
IF vg_gui = 0 THEN
	LET row_max = 10
	LET col_max = 41
END IF
OPEN WINDOW w_repf214_6 AT 08, 21 WITH row_max ROWS, col_max COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
IF vg_gui = 1 THEN
	OPEN FORM f_repf214_6 FROM '../forms/repf214_6'
ELSE
	OPEN FORM f_repf214_6 FROM '../forms/repf214_6c'
END IF
DISPLAY FORM f_repf214_6
LET impresion = 'C'
DISPLAY BY NAME cod_tran, num_tran, impresion
IF vg_gui = 0 THEN
	CALL muestra_impresion(impresion)
END IF
LET int_flag = 0
INPUT BY NAME impresion WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD impresion
		IF vg_gui = 0 THEN
			IF impresion IS NOT NULL THEN
				CALL muestra_impresion(impresion)
			ELSE
				CLEAR tit_impresion
			END IF
		END IF
END INPUT
CLOSE WINDOW w_repf214_6
RETURN impresion

END FUNCTION



FUNCTION muestra_impresion(impresion)
DEFINE impresion	CHAR(1)

CASE impresion
	WHEN 'C'
		DISPLAY 'COMPRA LOCAL'   TO tit_impresion
	WHEN 'T'
		DISPLAY 'TRANSFERENCIAS' TO tit_impresion
	WHEN 'X'
		DISPLAY 'T O D A S'      TO tit_impresion
	OTHERWISE
		CLEAR impresion, tit_impresion
END CASE

END FUNCTION



FUNCTION imprimir_comprobante(cod_tran, num_tran, reporte)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE reporte		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		VARCHAR(250)
DEFINE expr_tran	VARCHAR(70)
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)

LET param = vg_codloc, ' "', cod_tran, '" ', num_tran CLIPPED
CASE reporte
	WHEN 1
		LET prog = 'repp413 '
	WHEN 2
		LET prog = 'repp415 '
END CASE
CALL ejecuta_comando('REPUESTOS', vg_modulo, prog, param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

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
DISPLAY '<F5>      Ver Orden Compra'         AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F12>     Salir'                    AT a,2
DISPLAY  'F12' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_3() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Facturas Cruce'           AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Fact. Item Cruce'         AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Imprimir Compra Local'    AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_4() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Factura'                  AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Transferencia'            AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
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
CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
DISPLAY r_r10.r10_nombre TO nom_item

END FUNCTION



FUNCTION prorratea_costos_adicionales()
DEFINE val_prorrateo	DECIMAL(12,2)
DEFINE dif		DECIMAL(10,2)
DEFINE factor		DECIMAL(14,7) 
DEFINE tot_pro		DECIMAL(12,2) 
DEFINE i		SMALLINT

IF rm_c10.c10_flete + rm_c10.c10_otros = 0 THEN
	RETURN
END IF
LET val_prorrateo = rm_c10.c10_flete + rm_c10.c10_otros
LET factor = val_prorrateo / (rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto)
LET tot_pro = 0
FOR i = 1 TO vm_indice
	IF rm_compra[i].cant_ven = 0 THEN
		CONTINUE FOR
	END IF
	LET rm_datos[i].costo_adi = rm_datos[i].costo_base * factor
	LET tot_pro  = tot_pro + rm_datos[i].costo_adi
END FOR
LET dif = val_prorrateo - tot_pro
FOR i = 1 TO vm_indice
	IF rm_compra[i].cant_ven = 0 THEN
        	CONTINUE FOR
        END IF
        IF rm_datos[i].costo_adi + dif <= 0 THEN
        	CONTINUE FOR
       	END IF
	LET rm_datos[i].costo_adi = rm_datos[i].costo_adi + dif
	EXIT FOR
END FOR

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



FUNCTION proceso_cruce_de_bodegas()
DEFINE r_rep		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha		LIKE rept020.r20_fecing,
				bodega		LIKE rept020.r20_bodega,
				item		LIKE rept020.r20_item,
				cant_pend	LIKE rept020.r20_cant_ven,
				cant_desp	LIKE rept020.r20_cant_ven,
				stock_act	LIKE rept011.r11_stock_act
			END RECORD
DEFINE r_fact		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha		LIKE rept020.r20_fecing,
				bodega		LIKE rept020.r20_bodega,
				r19_nomcli	LIKE rept019.r19_nomcli,
				r19_vendedor	LIKE rept019.r19_vendedor
			END RECORD
DEFINE aux_i		LIKE rept011.r11_item
DEFINE cant		LIKE rept011.r11_stock_act
DEFINE tot_cant_des	LIKE rept011.r11_stock_act
DEFINE num_f		LIKE rept020.r20_num_tran

IF NOT verificar_item_bodega_sin_stock() THEN
	RETURN
END IF
DECLARE q_sto CURSOR FOR
	SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item,
		cant_pend, cant_desp, NVL(r11_stock_act, 0)
		FROM temp_pend, t_r11
		WHERE r11_compania  = vg_codcia
		  AND r11_bodega    = rm_r19.r19_bodega_ori
		  AND r11_item      = r20_item
		  AND r11_stock_act > 0
		ORDER BY fecha ASC, r20_num_tran ASC
LET cant  = 0
LET aux_i = NULL
FOREACH q_sto INTO r_rep.*
--display 'cant antes ', r_rep.cod_tran, '-', r_rep.num_tran, '  item: ', r_rep.item, '  cant_d ', r_rep.cant_desp
	LET r_rep.cant_desp = retorna_cant_tr(r_rep.bodega, r_rep.item,
						r_rep.cod_tran, r_rep.num_tran)
	IF aux_i IS NULL OR aux_i <> r_rep.item THEN
		SELECT NVL(SUM(cant_desp), 0)
			INTO tot_cant_des
			FROM temp_pend, t_r11
			WHERE r11_compania  = vg_codcia
			  AND r11_bodega    = rm_r19.r19_bodega_ori
			  AND r11_item      = r_rep.item
			  AND r11_stock_act > 0
			  AND r20_cod_tran  = r_rep.cod_tran
			  AND r20_num_tran  < r_rep.num_tran
			  AND r20_item      = r11_item
			  AND fecha         < r_rep.fecha
		LET cant = r_rep.stock_act - tot_cant_des
	END IF
	IF r_rep.cant_desp <= cant THEN
		LET cant = cant - r_rep.cant_desp
	ELSE
		LET r_rep.cant_desp = cant
		LET cant            = 0
	END IF
--display 'cant despues ', r_rep.cod_tran, '-', r_rep.num_tran, '  item: ', r_rep.item, '  cant_d ', r_rep.cant_desp, '  ', cant
	UPDATE temp_pend
		SET cant_desp = r_rep.cant_desp
		WHERE r20_cod_tran = r_rep.cod_tran
		  AND r20_num_tran = r_rep.num_tran
		  AND r20_bodega   = r_rep.bodega
		  AND r20_item     = r_rep.item
	LET aux_i = r_rep.item
END FOREACH
DECLARE q_fact CURSOR WITH HOLD FOR
	SELECT UNIQUE r20_cod_tran, r20_num_tran, fecha, r20_bodega,
		r19_nomcli, r19_vendedor
		FROM temp_pend
		ORDER BY fecha ASC, r20_num_tran ASC
LET num_f = NULL
FOREACH q_fact INTO r_fact.*
--display r_fact.*
	IF num_f IS NULL OR r_fact.num_tran <> num_f THEN
		CALL transferir_item_bod_ss_bod_res(r_fact.*)
	END IF
	LET num_f = r_fact.num_tran
END FOREACH
--rollback work
--exit program
CALL dropear_tablas_tmp()
CALL fl_mostrar_mensaje('Transferencias por CRUCE de BODEGA "SIN STOCK" con la bodega ' || rm_r19.r19_bodega_ori CLIPPED || ' generadas OK.', 'info')

END FUNCTION



FUNCTION verificar_item_bodega_sin_stock()
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE query		CHAR(1200)
DEFINE cuantos		INTEGER

MESSAGE 'Generando consulta . . . espere por favor'
SELECT r10_sec_item r10_codigo, r10_nombre, r11_stock_act stock_pend,
	r11_stock_act stock_tot, r11_stock_act stock_loc, r10_stock_max,
	r10_stock_min
	FROM rept010, rept011
	WHERE r10_compania  = 99
	  AND r11_compania  = r10_compania
	  AND r11_item      = r10_codigo
	INTO TEMP t_item
SELECT r10_codigo item, stock_loc stock_l FROM t_item INTO TEMP t_item_loc
SELECT r02_compania, r02_codigo, r02_nombre, r02_localidad
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_tipo     <> "S"
	  --AND r02_tipo      = "S"
	INTO TEMP t_bod
SELECT r20_item item_p
	FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = rm_r19.r19_cod_tran
	  AND r20_num_tran  = rm_r19.r19_num_tran
	INTO TEMP tmp_ite_cl
LET query = ' SELECT r10_codigo, r10_nombre, 0 stock_p1, 0 stock_t1, ',
			' 0 stock_l1, r10_stock_max, r10_stock_min ',
		' FROM rept010 ',
		' WHERE r10_compania  = ', vg_codcia,
		'   AND r10_codigo   IN (SELECT item_p FROM tmp_ite_cl) ',
		' INTO TEMP t_r10 '
PREPARE pre_r10 FROM query
EXECUTE pre_r10
{--
LET query = ' SELECT r11_compania, r11_bodega, r11_item, r11_stock_act ',
		' FROM rept011 ',
		' WHERE r11_compania  = ', vg_codcia,
		'   AND r11_bodega   IN (SELECT r02_codigo FROM t_bod) ',
		'   AND r11_item     IN (SELECT r10_codigo FROM t_r10) ',
--}
LET query = ' SELECT r20_compania r11_compania, r20_bodega r11_bodega, ',
			'r20_item r11_item, r20_cant_ven r11_stock_act ',
		' FROM rept019, rept020 ',
		' WHERE r19_compania   = ', vg_codcia,
		'   AND r19_localidad  = ', vg_codloc,
		'   AND r19_cod_tran   = "', rm_r19.r19_cod_tran, '"',
		'   AND r19_num_tran   = ', rm_r19.r19_num_tran,
		'   AND r20_compania   = r19_compania ',
		'   AND r20_localidad  = r19_localidad ',
		'   AND r20_cod_tran   = r19_cod_tran ',
		'   AND r20_num_tran   = r19_num_tran ',
		'   AND r20_item      IN (SELECT r10_codigo FROM t_r10) ',
		' INTO TEMP t_r11 '
PREPARE pre_r11 FROM query
EXECUTE pre_r11
SELECT r11_item r10_codigo, NVL(SUM(r11_stock_act), 0) stock_t
	FROM t_r11
	GROUP BY 1
	INTO TEMP t_item_tot
CASE vg_codloc
	WHEN 1 LET codloc = 2
	WHEN 2 LET codloc = 1
	WHEN 3 LET codloc = 4
	WHEN 4 LET codloc = 3
END CASE
LET query = 'INSERT INTO t_item_loc ',
		' SELECT r11_item, NVL(SUM(r11_stock_act), 0) stock_l ',
			' FROM t_r11 ',
			' WHERE r11_bodega IN ',
				'(SELECT r02_codigo FROM t_bod ',
				' WHERE r02_localidad IN (', vg_codloc, ', ',
								codloc, ')) ',
			' GROUP BY 1'
PREPARE cit_loc FROM query
EXECUTE cit_loc
SELECT r10_codigo item_tl, stock_t, NVL(stock_l, 0) stock_l
	FROM t_item_tot, OUTER t_item_loc
	WHERE r10_codigo = item
	INTO TEMP t_totloc
DROP TABLE t_item_tot
DROP TABLE t_item_loc
INSERT INTO t_item
	SELECT r10_codigo, r10_nombre, stock_p1, stock_t, stock_l,
			r10_stock_max, r10_stock_min
		FROM t_r10, t_totloc
		WHERE r10_codigo = item_tl
DROP TABLE t_r10
DROP TABLE t_totloc
SELECT COUNT(*) INTO cuantos FROM t_item
IF cuantos = 0 THEN
	MESSAGE 'No se encontraron registros.'
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	DROP TABLE tmp_ite_cl
	MESSAGE '                                         '
	RETURN 0
END IF
LET vm_stock_pend = obtener_stock_pendiente()
IF NOT vm_stock_pend THEN
	MESSAGE 'No se encontraron registros pendientes.'
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	DROP TABLE tmp_ite_cl
	LET vm_stock_pend = 0
	MESSAGE '                                         '
	RETURN 0
END IF
IF vm_stock_pend THEN
	LET query = ' SELECT r10_codigo, r10_nombre, ',
				' NVL(SUM(cant_pend), 0) stock_pend, ',
				'stock_tot, stock_loc, r10_stock_max, ',
				'r10_stock_min ',
			' FROM t_item, temp_pend',
			' WHERE r10_codigo = r20_item ',
			' GROUP BY 1, 2, 4, 5, 6, 7 ',
			' INTO TEMP temp_item_pen'
	PREPARE pre_item FROM query
	EXECUTE pre_item
ELSE
	SELECT * FROM t_item INTO TEMP temp_item_pen
END IF
DROP TABLE t_item
--CALL mostrar_detalle_item()
--DROP TABLE temp_item_pen
MESSAGE '                                         '
RETURN 1

END FUNCTION



FUNCTION obtener_bod_sin_stock()
DEFINE query		CHAR(800)

LET query = 'SELECT r02_codigo FROM rept002 ',
		' WHERE r02_compania  = ', vg_codcia,
		'   AND r02_localidad = ', vg_codloc,
		'   AND r02_factura   = "S" ',
		'   AND r02_tipo      = "S" ',
		'   AND r02_area      = "R" ',
		' INTO TEMP t_bd1 '
PREPARE cons_bod FROM query
EXECUTE cons_bod

END FUNCTION



FUNCTION obtener_stock_pendiente()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE cuantos		INTEGER
DEFINE query		CHAR(1500)
DEFINE expr_query	VARCHAR(200)

CALL obtener_bod_sin_stock()
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING r_c10.*
CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, r_c10.c10_numprof)
	RETURNING r_r21.*
LET expr_query = NULL
IF r_r21.r21_num_tran IS NOT NULL THEN
	LET expr_query = '   AND r20_cod_tran = "', r_r21.r21_cod_tran, '" ',
					 '   AND r20_num_tran = ', r_r21.r21_num_tran
END IF
LET query = 'SELECT r20_cod_tran, r20_num_tran, r20_fecing fecha, r20_bodega, ',
					'r20_item, r20_cant_ven ',
				' FROM rept020 ',
				' WHERE r20_compania   = ', vg_codcia,
				'   AND r20_localidad  = ', vg_codloc,
				'   AND r20_cod_tran  IN ("FA", "DF") ',
				expr_query CLIPPED,
				'   AND r20_bodega    IN (SELECT r02_codigo FROM t_bd1) ',
				'   AND r20_item      IN (SELECT r10_codigo FROM t_item) ',
				' INTO TEMP t_r20 '
PREPARE exec_t_r20 FROM query
EXECUTE exec_t_r20
LET expr_query = NULL
IF r_r21.r21_num_tran IS NOT NULL THEN
	LET expr_query = '   AND r19_cod_tran = "', r_r21.r21_cod_tran, '" ',
					 '   AND r19_num_tran = ', r_r21.r21_num_tran
ELSE
	LET expr_query = '   AND r19_cod_tran = "FA" '
END IF
LET query = 'SELECT r19_cod_tran, r19_num_tran, r19_nomcli, r19_vendedor, ',
					'r19_tipo_dev, r19_num_dev ',
				' FROM rept019 ',
				' WHERE r19_compania  = ', vg_codcia,
				'   AND r19_localidad = ', vg_codloc,
				expr_query CLIPPED,
				'   AND (r19_tipo_dev = "DF" OR r19_tipo_dev IS NULL) ',
			' UNION ALL ',
			' SELECT r19_cod_tran, r19_num_tran, r19_nomcli, r19_vendedor, ',
						'r19_tipo_dev, r19_num_dev ',
				' FROM rept019 ',
				' WHERE r19_compania   = ', vg_codcia,
				'   AND r19_localidad  = ', vg_codloc,
	 			'   AND r19_cod_tran   = "DF" ',
				' INTO TEMP t_r19 '
PREPARE exec_t_r19 FROM query
EXECUTE exec_t_r19
SELECT c.*, d.r19_nomcli, d.r19_vendedor
	FROM t_r20 c, t_r19 d
	WHERE d.r19_cod_tran = c.r20_cod_tran
	  AND d.r19_num_tran = c.r20_num_tran
	  AND c.r20_cod_tran = "FA"
	INTO TEMP t_f
SELECT a.r19_tipo_dev c_t, a.r19_num_dev n_t, b.r20_bodega bd, b.r20_item ite,
	b.r20_cant_ven cant
	FROM t_r19 a, t_r20 b
	WHERE a.r19_cod_tran = b.r20_cod_tran
	  AND a.r19_num_tran = b.r20_num_tran
	  AND b.r20_cod_tran = "DF"
	INTO TEMP t_d
SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item, r20_cant_ven -
	NVL((SELECT SUM(cant)
		FROM t_d
		WHERE c_t = r20_cod_tran
		  AND n_t = r20_num_tran
		  AND bd  = r20_bodega
		  AND ite = r20_item), 0) r20_cant_ven, r19_nomcli, r19_vendedor
	FROM t_f
	INTO TEMP t_t
DROP TABLE t_f
DROP TABLE t_d
SELECT * FROM t_t WHERE r20_cant_ven > 0 INTO TEMP t1
DROP TABLE t_t
DROP TABLE t_bd1
DROP TABLE t_r19
DROP TABLE t_r20
SELECT r34_compania, r34_localidad, r34_bodega, r34_num_ord_des, r34_cod_tran,
		r34_num_tran
	FROM rept034
	WHERE r34_compania   = vg_codcia
	  AND r34_localidad  = vg_codloc
	  AND r34_estado    IN ("A", "P")
	INTO TEMP t_r34
SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item, r20_cant_ven,
		r34_num_ord_des, r19_nomcli, r19_vendedor
	FROM t1, t_r34
	WHERE r34_compania  = vg_codcia
	  AND r34_localidad = vg_codloc
	  AND r34_bodega    = r20_bodega
	  AND r34_cod_tran  = r20_cod_tran
	  AND r34_num_tran  = r20_num_tran
	INTO TEMP t2
DROP TABLE t1
DROP TABLE t_r34
SELECT COUNT(*) INTO cuantos FROM t2
IF cuantos = 0 THEN
	DROP TABLE t2
	RETURN 0
END IF
SELECT UNIQUE r35_num_ord_des, r20_bodega bodega, r20_item item,
	SUM(r35_cant_des - r35_cant_ent) cantidad
	FROM rept035, t2
	WHERE r35_compania    = vg_codcia
	  AND r35_localidad   = vg_codloc
	  AND r35_bodega      = r20_bodega
	  AND r35_num_ord_des = r34_num_ord_des
	  AND r35_item        = r20_item
	GROUP BY 1, 2, 3
	HAVING SUM(r35_cant_des - r35_cant_ent) > 0
	INTO TEMP t3
SELECT UNIQUE r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cantidad cant_pend, r19_nomcli, r19_vendedor,
	cantidad cant_desp
	FROM t2, t3
	WHERE r20_bodega      = bodega
	  AND r20_item        = item
	  AND r35_num_ord_des = r34_num_ord_des
	INTO TEMP temp_pend
DROP TABLE t2
DROP TABLE t3
SELECT COUNT(*) INTO cuantos FROM temp_pend
IF cuantos = 0 THEN
	DROP TABLE temp_pend
	RETURN 0
END IF
SELECT a.r20_cod_tran, a.r20_num_tran, a.fecha, a.r35_num_ord_des, a.r20_bodega,
	a.r20_item, a.cant_pend, a.r19_nomcli, a.r19_vendedor, a.cant_desp,
	NVL(SUM(c.r20_cant_ven), 0) * (-1) cant_tr
	FROM temp_pend a, OUTER rept019 b, rept020 c
	WHERE b.r19_compania   = vg_codcia
	  AND b.r19_localidad  = vg_codloc
	  AND b.r19_cod_tran   = 'TR'
	  AND b.r19_bodega_ori = a.r20_bodega
	  AND b.r19_tipo_dev   = a.r20_cod_tran
	  AND b.r19_num_dev    = a.r20_num_tran
	  AND c.r20_compania   = b.r19_compania
	  AND c.r20_localidad  = b.r19_localidad
	  AND c.r20_cod_tran   = b.r19_cod_tran
	  AND c.r20_num_tran   = b.r19_num_tran
	  AND c.r20_item       = a.r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT a.r20_cod_tran, a.r20_num_tran, a.fecha, a.r35_num_ord_des, a.r20_bodega,
	a.r20_item, a.cant_pend, a.r19_nomcli, a.r19_vendedor, a.cant_desp,
	NVL(SUM(c.r20_cant_ven), 0) cant_tr
	FROM temp_pend a, OUTER rept019 b, rept020 c
	WHERE b.r19_compania    = vg_codcia
	  AND b.r19_localidad   = vg_codloc
	  AND b.r19_cod_tran    = 'TR'
	  AND b.r19_bodega_dest = a.r20_bodega
	  AND b.r19_tipo_dev    = a.r20_cod_tran
	  AND b.r19_num_dev     = a.r20_num_tran
	  AND c.r20_compania    = b.r19_compania
	  AND c.r20_localidad   = b.r19_localidad
	  AND c.r20_cod_tran    = b.r19_cod_tran
	  AND c.r20_num_tran    = b.r19_num_tran
	  AND c.r20_item        = a.r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	INTO TEMP t4
DROP TABLE temp_pend
SELECT r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cant_pend, r19_nomcli, r19_vendedor, cant_desp,
	NVL(SUM(cant_tr), 0) cant_tr
	FROM t4
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	INTO TEMP t5
DROP TABLE t4
SELECT r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cant_pend - cant_tr cant_pend, r19_nomcli, r19_vendedor,
	cant_desp - cant_tr cant_desp
	FROM t5
	INTO TEMP temp_pend
DROP TABLE t5
RETURN 1

END FUNCTION



FUNCTION mostrar_detalle_item()
DEFINE r_ite		RECORD
				codigo		LIKE rept010.r10_codigo,
				nombre		LIKE rept010.r10_nombre,
				stock_pend	DECIMAL(10,2),
				stock_tot	DECIMAL(10,2),
				stock_loc	DECIMAL(10,2),
				sto_max		LIKE rept010.r10_stock_max,
				sto_min		LIKE rept010.r10_stock_min
			END RECORD
DEFINE i		SMALLINT

DECLARE q_item CURSOR FOR SELECT * FROM temp_item_pen
DISPLAY ' '
LET i = 1
FOREACH q_item INTO r_ite.*
	DISPLAY 'ITEM: ', r_ite.codigo CLIPPED, ' ', r_ite.nombre CLIPPED
	DISPLAY '  Sto. Pend. ', r_ite.stock_pend USING "---,--&.##"
	--DISPLAY '  Sto. Tot.  ', r_ite.stock_tot  USING "---,--&.##"
	--DISPLAY '  Sto. Loc.  ', r_ite.stock_loc  USING "---,--&.##"
	DISPLAY ' '
	LET i = i + 1
END FOREACH
LET i = i - 1
IF i > 0 THEN
	DISPLAY 'Se encontraron un total de ', i USING "<<<<&", ' ITEMS. OK'
END IF

END FUNCTION



FUNCTION transferir_item_bod_ss_bod_res(r_fact)
DEFINE r_fact		RECORD
				cod_tran	LIKE rept020.r20_cod_tran,
				num_tran	LIKE rept020.r20_num_tran,
				fecha		LIKE rept020.r20_fecing,
				bodega		LIKE rept020.r20_bodega,
				r19_nomcli	LIKE rept019.r19_nomcli,
				r19_vendedor	LIKE rept019.r19_vendedor
			END RECORD
DEFINE r_fact_i		RECORD
				item		LIKE rept020.r20_item,
				cant_desp	LIKE rept020.r20_cant_ven
			END RECORD
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE j		SMALLINT
DEFINE stock_act	LIKE rept011.r11_stock_act
DEFINE mensaje		VARCHAR(200)
DEFINE num_tran		VARCHAR(15)

DECLARE q_fact_i CURSOR FOR
	SELECT r20_item, cant_desp
		FROM temp_pend
		WHERE r20_cod_tran = r_fact.cod_tran
		  AND r20_num_tran = r_fact.num_tran
		  AND r20_bodega   = r_fact.bodega
		  AND cant_desp    > 0
		ORDER BY r20_item ASC
OPEN q_fact_i
FETCH q_fact_i INTO r_fact_i.*
IF STATUS = NOTFOUND THEN
	CLOSE q_fact_i
	FREE q_fact_i
	RETURN
END IF
INITIALIZE r_r19.*, r_fact_i.* TO NULL
LET r_r19.r19_compania		= vg_codcia
LET r_r19.r19_localidad   	= vg_codloc
LET r_r19.r19_cod_tran    	= 'TR'
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
LET r_r19.r19_referencia	= 'TR. AUTO. CL-',
					rm_r19.r19_num_tran USING "<<<<<&",' ',
					r_fact.cod_tran CLIPPED, '-',
					r_fact.num_tran USING "<<<<<<&",
					' SIN STOCK'
LET r_r19.r19_nomcli		= ' '
LET r_r19.r19_dircli     	= ' '
LET r_r19.r19_cedruc     	= ' '
LET r_r19.r19_vendedor   	= r_fact.r19_vendedor
LET r_r19.r19_descuento  	= 0.0
LET r_r19.r19_porc_impto 	= 0.0
LET r_r19.r19_tipo_dev          = r_fact.cod_tran
LET r_r19.r19_num_dev           = r_fact.num_tran
LET r_r19.r19_bodega_ori 	= rm_r19.r19_bodega_ori
LET r_r19.r19_bodega_dest	= r_fact.bodega
LET r_r19.r19_moneda     	= rg_gen.g00_moneda_base
LET r_r19.r19_precision  	= rg_gen.g00_decimal_mb
LET r_r19.r19_paridad    	= 1
LET r_r19.r19_tot_costo  	= 0
LET r_r19.r19_tot_bruto  	= 0.0
LET r_r19.r19_tot_dscto  	= 0.0
LET r_r19.r19_tot_neto		= r_r19.r19_tot_costo
LET r_r19.r19_flete      	= 0.0
LET r_r19.r19_usuario      	= vg_usuario
LET r_r19.r19_fecing      	= CURRENT
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
LET j = 1
FOREACH q_fact_i INTO r_fact_i.*
	CALL fl_lee_item(vg_codcia, r_fact_i.item) RETURNING r_r10.*
	LET r_r19.r19_tot_costo  = r_r19.r19_tot_costo + 
				  (r_fact_i.cant_desp * r_r10.r10_costo_mb)
	LET r_r20.r20_cant_ped   = r_fact_i.cant_desp
	LET r_r20.r20_cant_ven   = r_fact_i.cant_desp
	LET r_r20.r20_bodega     = r_r19.r19_bodega_ori
	LET r_r20.r20_item       = r_fact_i.item 
	LET r_r20.r20_costo      = r_r10.r10_costo_mb 
	LET r_r20.r20_orden      = j
	LET r_r20.r20_fob        = r_r10.r10_fob 
	LET r_r20.r20_linea      = r_r10.r10_linea 
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion 
	LET r_r20.r20_precio     = r_r10.r10_precio_mb
	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, r_fact_i.item)
		RETURNING r_r11.*
	IF r_r11.r11_compania IS NOT NULL THEN
		CALL fl_lee_bodega_rep(r_r11.r11_compania, r_r11.r11_bodega)
			RETURNING r_r02.*
		IF r_r02.r02_tipo <> 'S' THEN
			LET stock_act = r_r11.r11_stock_act -
					r_fact_i.cant_desp
			IF stock_act < 0 THEN
				ROLLBACK WORK
				LET mensaje = 'ERROR: El item ',
						r_r11.r11_item CLIPPED,
						' tiene stock insuficiente, ',
						'para GENERAR el CRUCE',
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
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, r_fact_i.item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act 
	LET r_r20.r20_fecing	 = CURRENT
	INSERT INTO rept020 VALUES(r_r20.*)
	UPDATE rept011
		SET r11_stock_act = r11_stock_act - r_fact_i.cant_desp,
		    r11_egr_dia   = r11_egr_dia   + r_fact_i.cant_desp
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = r_r19.r19_bodega_ori
		  AND r11_item     = r_fact_i.item 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, r_fact_i.item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		INSERT INTO rept011
      			(r11_compania, r11_bodega, r11_item, r11_ubicacion,
			 r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
		VALUES(vg_codcia, r_r19.r19_bodega_dest, r_fact_i.item, 'SN',
			0, r_fact_i.cant_desp, r_fact_i.cant_desp, 0) 
	ELSE
		UPDATE rept011 
			SET r11_stock_act = r11_stock_act + r_fact_i.cant_desp,
	      		    r11_ing_dia   = r11_ing_dia   + r_fact_i.cant_desp
			WHERE r11_compania  = vg_codcia
			  AND r11_bodega    = r_r19.r19_bodega_dest
			  AND r11_item      = r_fact_i.item 
	END IF
	UPDATE temp_item_pen
		SET stock_pend = stock_pend - r_fact_i.cant_desp
		WHERE r10_codigo = r_fact_i.item
	LET j = j + 1
	--display '   transf ', r_r20.r20_num_tran, ' ', r_r20.r20_cant_ven, ' item ', r_r20.r20_item
END FOREACH
--display '   transf ', r_r19.r19_num_tran
UPDATE rept019
	SET r19_tot_costo = r_r19.r19_tot_costo,
	    r19_tot_bruto = r_r19.r19_tot_bruto,
	    r19_tot_neto  = r_r19.r19_tot_bruto
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = r_r19.r19_cod_tran
	  AND r19_num_tran  = r_r19.r19_num_tran
INSERT INTO rept041
	VALUES(vg_codcia, vg_codloc, rm_r19.r19_cod_tran, rm_r19.r19_num_tran,
		r_r19.r19_cod_tran, r_r19.r19_num_tran)
{
LET num_tran = r_r19.r19_num_tran
CALL fl_mostrar_mensaje('Se genero transferencia automatica No. ' ||
			num_tran || '. De la bodega ' || r_r19.r19_bodega_ori ||
			' a la bodega ' || r_r19.r19_bodega_dest || '.','info')
}

END FUNCTION



FUNCTION retorna_cant_tr(bodega, item, cod_tran, num_tran)
DEFINE bodega		LIKE rept020.r20_bodega
DEFINE item		LIKE rept020.r20_item
DEFINE cod_tran		LIKE rept020.r20_cod_tran
DEFINE num_tran		LIKE rept020.r20_num_tran
DEFINE cant		DECIMAL(8,2)
DEFINE cant_fac		DECIMAL(8,2)
DEFINE cant_tra		DECIMAL(8,2)

SELECT NVL(SUM(r20_cant_ven), 0) INTO cant_fac
	FROM rept019, rept020
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = cod_tran
	  AND r19_num_tran  = num_tran
	  AND r20_compania  = r19_compania
	  AND r20_localidad = r19_localidad
	  AND r20_cod_tran  = r19_cod_tran
	  AND r20_num_tran  = r19_num_tran
	  AND r20_bodega    = bodega
	  AND r20_item      = item
SELECT NVL(SUM(r20_cant_ven), 0) * (-1) cant_tr
	FROM rept019, rept020
	WHERE r19_compania   = vg_codcia
	  AND r19_localidad  = vg_codloc
	  AND r19_cod_tran   = 'TR'
	  AND r19_bodega_ori = bodega
	  AND r19_tipo_dev   = cod_tran
	  AND r19_num_dev    = num_tran
	  AND r20_compania   = r19_compania
	  AND r20_localidad  = r19_localidad
	  AND r20_cod_tran   = r19_cod_tran
	  AND r20_num_tran   = r19_num_tran
	  AND r20_item       = item
UNION
SELECT NVL(SUM(r20_cant_ven), 0) cant_tr
	FROM rept019, rept020
	WHERE r19_compania    = vg_codcia
	  AND r19_localidad   = vg_codloc
	  AND r19_cod_tran    = 'TR'
	  AND r19_bodega_dest = bodega
	  AND r19_tipo_dev    = cod_tran
	  AND r19_num_dev     = num_tran
	  AND r20_compania    = r19_compania
	  AND r20_localidad   = r19_localidad
	  AND r20_cod_tran    = r19_cod_tran
	  AND r20_num_tran    = r19_num_tran
	  AND r20_item        = item
	INTO TEMP t1
SELECT NVL(SUM(cant_tr), 0) INTO cant_tra FROM t1
DROP TABLE t1
LET cant = cant_fac - cant_tra
RETURN cant

END FUNCTION



FUNCTION tiene_facturas_cruce()
DEFINE r_r41		RECORD LIKE rept041.*

INITIALIZE r_r41.* TO NULL
DECLARE q_tiene CURSOR FOR
	SELECT * FROM rept041
		WHERE r41_compania  = vg_codcia
		  AND r41_localidad = vg_codloc
		  AND r41_cod_tran  = rm_r19.r19_cod_tran
		  AND r41_num_tran  = rm_r19.r19_num_tran
OPEN q_tiene
FETCH q_tiene INTO r_r41.*
CLOSE q_tiene
FREE q_tiene
IF r_r41.r41_compania IS NULL THEN
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION tiene_item_cruce(item)
DEFINE item		LIKE rept020.r20_item
DEFINE r_r41		RECORD LIKE rept041.*

INITIALIZE r_r41.* TO NULL
DECLARE q_tiene2 CURSOR FOR
	SELECT rept041.*
		FROM rept041, rept019, rept020
		WHERE r41_compania  = vg_codcia
		  AND r41_localidad = vg_codloc
		  AND r41_cod_tran  = rm_r19.r19_cod_tran
		  AND r41_num_tran  = rm_r19.r19_num_tran
		  AND r19_compania  = r41_compania
		  AND r19_localidad = r41_localidad
		  AND r19_cod_tran  = r41_cod_tr
		  AND r19_num_tran  = r41_num_tr
		  AND r20_compania  = r19_compania
		  AND r20_localidad = r19_localidad
		  AND r20_cod_tran  = r19_cod_tran
		  AND r20_num_tran  = r19_num_tran
		  AND r20_item      = item
OPEN q_tiene2
FETCH q_tiene2 INTO r_r41.*
CLOSE q_tiene2
FREE q_tiene2
IF r_r41.r41_compania IS NULL THEN
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION muestra_fact_items_cruce()
DEFINE r_factcru	ARRAY[800] OF RECORD
				item		LIKE rept020.r20_item,
				cant_cruc	LIKE rept020.r20_cant_ven,
				cant_pend	LIKE rept020.r20_cant_ven,
				num_fact	LIKE rept019.r19_num_tran, 
				fec_fact	DATE,
				cliente		LIKE rept019.r19_nomcli, 
				num_tran	LIKE rept019.r19_num_tran 
			END RECORD
DEFINE r_adi		ARRAY[800] OF RECORD
				codcli		LIKE rept019.r19_codcli
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j, col	SMALLINT
DEFINE resul		SMALLINT
DEFINE num_row		SMALLINT
DEFINE max_row		SMALLINT
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE query		CHAR(3500)
DEFINE r_orden	 	ARRAY[10] OF CHAR(4)
DEFINE v_columna_1	SMALLINT
DEFINE v_columna_2	SMALLINT

LET row_ini = 07
LET row_fin = 17
LET col_ini = 02
LET col_fin = 80
IF vg_gui = 0 THEN
	LET row_ini = 09
	LET row_fin = 13
	LET col_ini = 03
	LET col_fin = 76
END IF
OPEN WINDOW w_repf214_4 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf214_4 FROM '../forms/repf214_4'
ELSE
	OPEN FORM f_repf214_4 FROM '../forms/repf214_4c'
END IF
DISPLAY FORM f_repf214_4
LET max_row = 800
--#DISPLAY 'Item' 	TO tit_col1
--#DISPLAY 'Cant.Cruce'	TO tit_col2
--#DISPLAY 'Cant.Pend.'	TO tit_col3
--#DISPLAY 'Factura'	TO tit_col4
--#DISPLAY 'Fecha Fact'	TO tit_col5
--#DISPLAY 'Cliente'	TO tit_col6
--#DISPLAY 'Transf.'	TO tit_col7
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET col                  = 5
LET v_columna_1          = col
LET v_columna_2          = 4
LET r_orden[v_columna_1] = 'ASC'
LET r_orden[v_columna_2] = 'ASC'
CALL obtener_bod_sin_stock()
LET query = 'SELECT d.r20_item item_c, d.r20_cant_ven, ',
		' NVL(CASE WHEN b.r19_bodega_ori = ',
			'(SELECT r02_codigo FROM t_bd1) ',
		' THEN ',
			'(SELECT NVL(SUM(f.r20_cant_ven), 0) * (-1) ',
				'FROM rept019 e, rept020 f ',
				'WHERE e.r19_compania   = b.r19_compania ',
				'  AND e.r19_localidad  = b.r19_localidad ',
				'  AND e.r19_cod_tran   = "TR" ',
				'  AND e.r19_bodega_ori = b.r19_bodega_ori ',
				'  AND e.r19_tipo_dev   = b.r19_tipo_dev ',
				'  AND e.r19_num_dev    = b.r19_num_dev ',
				'  AND f.r20_compania   = e.r19_compania ',
				'  AND f.r20_localidad  = e.r19_localidad ',
				'  AND f.r20_cod_tran   = e.r19_cod_tran ',
				'  AND f.r20_num_tran   = e.r19_num_tran ',
				'  AND f.r20_item       = d.r20_item) ',
		' ELSE ',
			'(SELECT NVL(SUM(f.r20_cant_ven), 0) ',
				'FROM rept019 e, rept020 f ',
				'WHERE e.r19_compania   = b.r19_compania ',
				'  AND e.r19_localidad  = b.r19_localidad ',
				'  AND e.r19_cod_tran   = "TR" ',
				'  AND e.r19_bodega_dest= b.r19_bodega_dest ',
				'  AND e.r19_tipo_dev   = b.r19_tipo_dev ',
				'  AND e.r19_num_dev    = b.r19_num_dev ',
				'  AND f.r20_compania   = e.r19_compania ',
				'  AND f.r20_localidad  = e.r19_localidad ',
				'  AND f.r20_cod_tran   = e.r19_cod_tran ',
				'  AND f.r20_num_tran   = e.r19_num_tran ',
				'  AND f.r20_item       = d.r20_item) ',
		' END, 0.00) cant_pend, ',
		' b.r19_num_dev, ',
		'DATE((SELECT a.r19_fecing ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev)) fec_f,',
		'(SELECT a.r19_nomcli ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev) nom_c,',
		' d.r20_num_tran, ',
		'(SELECT a.r19_codcli ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev) cod_c ',
		' FROM rept041, rept019 b, rept020 d ',
		' WHERE r41_compania    = ', vg_codcia,
		'   AND r41_localidad   = ', vg_codloc,
		'   AND r41_cod_tran    = "', rm_r19.r19_cod_tran, '"',
		'   AND r41_num_tran    = ', rm_r19.r19_num_tran,
		'   AND b.r19_compania  = r41_compania ',
		'   AND b.r19_localidad = r41_localidad ',
		'   AND b.r19_cod_tran  = r41_cod_tr ',
		'   AND b.r19_num_tran  = r41_num_tr ',
		'   AND d.r20_compania  = b.r19_compania ',
		'   AND d.r20_localidad = b.r19_localidad ',
		'   AND d.r20_cod_tran  = b.r19_cod_tran ',
		'   AND d.r20_num_tran  = b.r19_num_tran ',
		' INTO TEMP t1 '
PREPARE exec_cru FROM query
EXECUTE exec_cru
SELECT item_c, r20_cant_ven, NVL(SUM(cant_pend), 0) cant_pend, r19_num_dev,
	fec_f, nom_c, r20_num_tran, cod_c
	FROM t1
	GROUP BY 1, 2, 4, 5, 6, 7, 8
	INTO TEMP tmp_cru
DROP TABLE t1
WHILE TRUE
	LET query = 'SELECT item_c, r20_cant_ven, ',
			' NVL((SELECT r20_cant_ven ',
				' FROM rept020 ',
				' WHERE r20_compania  = ', vg_codcia,
				'   AND r20_localidad = ', vg_codloc,
				'   AND r20_cod_tran  = "FA" ',
				'   AND r20_num_tran  = r19_num_dev ',
				'   AND r20_bodega    = ',
					'(SELECT r02_codigo FROM t_bd1) ',
				'   AND r20_item      = item_c), 0) - ',
			'cant_pend, r19_num_dev, fec_f, nom_c, r20_num_tran, ',
			'cod_c ',
			' FROM tmp_cru ',
	                ' ORDER BY ', v_columna_1, ' ', r_orden[v_columna_1],
				', ', v_columna_2, ' ', r_orden[v_columna_2] 
	PREPARE cons_fac FROM query
	DECLARE q_fact_c CURSOR FOR cons_fac
	LET num_row = 1
	FOREACH q_fact_c INTO r_factcru[num_row].*, r_adi[num_row].*
		LET num_row = num_row + 1
		IF num_row > max_row THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row = num_row - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, num_row)
		DISPLAY r_adi[1].codcli      TO codcli
		DISPLAY r_factcru[1].cliente TO nomcli
		CALL fl_lee_item(vg_codcia,r_factcru[1].item) RETURNING r_r10.*
		CALL muestra_descripciones(r_r10.r10_codigo, r_r10.r10_linea,
					r_r10.r10_sub_linea,r_r10.r10_cod_grupo,
					r_r10.r10_cod_clase)
	END IF
	LET int_flag = 0
	CALL set_count(num_row)
	DISPLAY ARRAY r_factcru TO r_factcru.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET j = arr_curr()
			CALL muestra_contadores_det(j, num_row)
			DISPLAY r_adi[j].codcli      TO codcli
			DISPLAY r_factcru[j].cliente TO nomcli
			CALL fl_lee_item(vg_codcia, r_factcru[j].item)
				RETURNING r_r10.*
			CALL muestra_descripciones(r_r10.r10_codigo,
					r_r10.r10_linea, r_r10.r10_sub_linea,
					r_r10.r10_cod_grupo,r_r10.r10_cod_clase)
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_4()
		ON KEY(F5)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'FA', r_factcru[j].num_fact)
			LET int_flag = 0
		ON KEY(F6)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'TR', r_factcru[j].num_tran)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		ON KEY(F21)
			LET col = 7
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#CALL muestra_contadores_det(j, num_row)
			--#DISPLAY r_adi[j].codcli      TO codcli
			--#DISPLAY r_factcru[j].cliente TO nomcli
			--#CALL fl_lee_item(vg_codcia, r_factcru[j].item)
				--#RETURNING r_r10.*
			--#CALL muestra_descripciones(r_r10.r10_codigo,
					--#r_r10.r10_linea, r_r10.r10_sub_linea,
					--#r_r10.r10_cod_grupo,
					--#r_r10.r10_cod_clase)
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> v_columna_1 THEN
		LET v_columna_2          = v_columna_1 
		LET r_orden[v_columna_2] = r_orden[v_columna_1]
		LET v_columna_1          = col 
	END IF
	IF r_orden[v_columna_1] = 'ASC' THEN
		LET r_orden[v_columna_1] = 'DESC'
	ELSE
		LET r_orden[v_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE t_bd1
DROP TABLE tmp_cru
LET int_flag = 0
CLOSE WINDOW w_repf214_4
RETURN

END FUNCTION



FUNCTION muestra_facturas_cruce(posi)
DEFINE posi		SMALLINT
DEFINE r_detcru		ARRAY[800] OF RECORD
				num_fact	LIKE rept019.r19_num_tran, 
				fec_fact	DATE,
				cant_cruc	LIKE rept020.r20_cant_ven,
				cant_pend	LIKE rept020.r20_cant_ven,
				cliente		LIKE rept019.r19_nomcli, 
				num_tran	LIKE rept019.r19_num_tran 
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j, col	SMALLINT
DEFINE resul		SMALLINT
DEFINE num_row		SMALLINT
DEFINE max_row		SMALLINT
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE query		CHAR(2500)
DEFINE r_orden	 	ARRAY[10] OF CHAR(4)
DEFINE v_columna_1	SMALLINT
DEFINE v_columna_2	SMALLINT

LET row_ini = 07
LET row_fin = 17
LET col_ini = 02
LET col_fin = 80
IF vg_gui = 0 THEN
	LET row_ini = 09
	LET row_fin = 13
	LET col_ini = 03
	LET col_fin = 76
END IF
OPEN WINDOW w_repf214_5 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf214_5 FROM '../forms/repf214_5'
ELSE
	OPEN FORM f_repf214_5 FROM '../forms/repf214_5c'
END IF
DISPLAY FORM f_repf214_5
LET max_row = 800
--#DISPLAY 'Factura'	TO tit_col1
--#DISPLAY 'Fecha Fact'	TO tit_col2
--#DISPLAY 'Cant.Cruce'	TO tit_col3
--#DISPLAY 'Cant.Pend.'	TO tit_col4
--#DISPLAY 'Cliente'	TO tit_col5
--#DISPLAY 'Transf.'	TO tit_col6
CALL fl_lee_item(vg_codcia, rm_compra[posi].item) RETURNING r_r10.*
DISPLAY rm_compra[posi].item TO item
CALL muestra_descripciones(r_r10.r10_codigo, r_r10.r10_linea,
				r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
				r_r10.r10_cod_clase)
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET col                  = 2
LET v_columna_1          = col
LET v_columna_2          = 1
LET r_orden[v_columna_1] = 'ASC'
LET r_orden[v_columna_2] = 'ASC'
CALL obtener_bod_sin_stock()
LET query = 'SELECT d.r20_item item_c, b.r19_num_dev, ',
		'DATE((SELECT a.r19_fecing ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev)) fec_f,',
		' d.r20_cant_ven, ',
		' NVL(CASE WHEN b.r19_bodega_ori = ',
			'(SELECT r02_codigo FROM t_bd1) ',
		' THEN ',
			'(SELECT NVL(SUM(f.r20_cant_ven), 0) * (-1) ',
				'FROM rept019 e, rept020 f ',
				'WHERE e.r19_compania   = b.r19_compania ',
				'  AND e.r19_localidad  = b.r19_localidad ',
				'  AND e.r19_cod_tran   = "TR" ',
				'  AND e.r19_bodega_ori = b.r19_bodega_ori ',
				'  AND e.r19_tipo_dev   = b.r19_tipo_dev ',
				'  AND e.r19_num_dev    = b.r19_num_dev ',
				'  AND f.r20_compania   = e.r19_compania ',
				'  AND f.r20_localidad  = e.r19_localidad ',
				'  AND f.r20_cod_tran   = e.r19_cod_tran ',
				'  AND f.r20_num_tran   = e.r19_num_tran ',
				'  AND f.r20_item       = d.r20_item) ',
		' ELSE ',
			'(SELECT NVL(SUM(f.r20_cant_ven), 0) ',
				'FROM rept019 e, rept020 f ',
				'WHERE e.r19_compania   = b.r19_compania ',
				'  AND e.r19_localidad  = b.r19_localidad ',
				'  AND e.r19_cod_tran   = "TR" ',
				'  AND e.r19_bodega_dest= b.r19_bodega_dest ',
				'  AND e.r19_tipo_dev   = b.r19_tipo_dev ',
				'  AND e.r19_num_dev    = b.r19_num_dev ',
				'  AND f.r20_compania   = e.r19_compania ',
				'  AND f.r20_localidad  = e.r19_localidad ',
				'  AND f.r20_cod_tran   = e.r19_cod_tran ',
				'  AND f.r20_num_tran   = e.r19_num_tran ',
				'  AND f.r20_item       = d.r20_item) ',
		' END, 0.00) cant_pend, ',
		'(SELECT a.r19_nomcli ',
			'FROM rept019 a ',
			'WHERE a.r19_compania  = b.r19_compania ',
			'  AND a.r19_localidad = b.r19_localidad',
			'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
			'  AND a.r19_num_tran  = b.r19_num_dev) nom_c,',
		' d.r20_num_tran ',
		' FROM rept041, rept019 b, rept020 d ',
		' WHERE r41_compania    = ', vg_codcia,
		'   AND r41_localidad   = ', vg_codloc,
		'   AND r41_cod_tran    = "', rm_r19.r19_cod_tran, '"',
		'   AND r41_num_tran    = ', rm_r19.r19_num_tran,
		'   AND b.r19_compania  = r41_compania ',
		'   AND b.r19_localidad = r41_localidad ',
		'   AND b.r19_cod_tran  = r41_cod_tr ',
		'   AND b.r19_num_tran  = r41_num_tr ',
		'   AND d.r20_compania  = b.r19_compania ',
		'   AND d.r20_localidad = b.r19_localidad ',
		'   AND d.r20_cod_tran  = b.r19_cod_tran ',
		'   AND d.r20_num_tran  = b.r19_num_tran ',
		'   AND d.r20_item      = "', rm_compra[posi].item CLIPPED, '"',
		' INTO TEMP t1 '
PREPARE exec_cru2 FROM query
EXECUTE exec_cru2
SELECT r19_num_dev, fec_f, r20_cant_ven, NVL(SUM(cant_pend), 0) cant_pend,
	nom_c, r20_num_tran
	FROM t1
	GROUP BY 1, 2, 3, 5, 6
	INTO TEMP tmp_cru
DROP TABLE t1
WHILE TRUE
	LET query = 'SELECT r19_num_dev, fec_f, r20_cant_ven, ',
			' NVL((SELECT r20_cant_ven ',
				' FROM rept020 ',
				' WHERE r20_compania  = ', vg_codcia,
				'   AND r20_localidad = ', vg_codloc,
				'   AND r20_cod_tran  = "FA" ',
				'   AND r20_num_tran  = r19_num_dev ',
				'   AND r20_bodega    = ',
					'(SELECT r02_codigo FROM t_bd1) ',
				'   AND r20_item      = "',
				rm_compra[posi].item CLIPPED, '"), 0) - ',
			'cant_pend, nom_c, r20_num_tran ',
			' FROM tmp_cru ',
	                ' ORDER BY ', v_columna_1, ' ', r_orden[v_columna_1],
				', ', v_columna_2, ' ', r_orden[v_columna_2] 
	PREPARE cons_fac2 FROM query
	DECLARE q_fact_c2 CURSOR FOR cons_fac2
	LET num_row = 1
	FOREACH q_fact_c2 INTO r_detcru[num_row].*
		LET num_row = num_row + 1
		IF num_row > max_row THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET num_row = num_row - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, num_row)
	END IF
	LET int_flag = 0
	CALL set_count(num_row)
	DISPLAY ARRAY r_detcru TO r_detcru.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(RETURN)
			LET j = arr_curr()
			CALL muestra_contadores_det(j, num_row)
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_4()
		ON KEY(F5)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'FA', r_detcru[j].num_fact)
			LET int_flag = 0
		ON KEY(F6)
			LET j = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'TR', r_detcru[j].num_tran)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 6
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#CALL muestra_contadores_det(j, num_row)
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> v_columna_1 THEN
		LET v_columna_2          = v_columna_1 
		LET r_orden[v_columna_2] = r_orden[v_columna_1]
		LET v_columna_1          = col 
	END IF
	IF r_orden[v_columna_1] = 'ASC' THEN
		LET r_orden[v_columna_1] = 'DESC'
	ELSE
		LET r_orden[v_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE t_bd1
DROP TABLE tmp_cru
LET int_flag = 0
CLOSE WINDOW w_repf214_5
RETURN

END FUNCTION



FUNCTION dropear_tablas_tmp()

DROP TABLE t_r11
DROP TABLE t_bod
DROP TABLE temp_item_pen
DROP TABLE tmp_ite_cl
IF vm_stock_pend THEN
	DROP TABLE temp_pend
END IF

END FUNCTION

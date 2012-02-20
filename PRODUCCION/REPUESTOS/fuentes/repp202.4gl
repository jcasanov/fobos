{*
 * Titulo           : repp202.4gl - Recepcion para compra local  
 * Elaboracion      : 29-jul-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp202 base modulo compania localidad 
 * 					  [vm_cod_tran] [vm_num_tran]
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_transaccion   LIKE rept019.r19_cod_tran

DEFINE vm_cod_tran		LIKE rept019.r19_cod_tran
DEFINE vm_num_tran		LIKE rept019.r19_num_tran

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT

DEFINE vm_max_detalle	SMALLINT	-- NUMERO MAXIMO ELEMENTOS DEL DETALLE

--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_r19		RECORD LIKE rept019.* 
DEFINE rm_c10		RECORD LIKE ordt010.* 
DEFINE rm_p01		RECORD LIKE cxpt001.* 

DEFINE vm_indice	SMALLINT
DEFINE vm_max_compra	SMALLINT
DEFINE rm_compra ARRAY[100] OF RECORD
	item			LIKE rept020.r20_item, 
	descripcion		LIKE rept010.r10_nombre,
	cant_ped		LIKE rept020.r20_cant_ped, 
	cant_ven		LIKE rept020.r20_cant_ven 
END RECORD

DEFINE rm_datos ARRAY[100] OF RECORD
	descuento		LIKE rept020.r20_descuento,
	val_descto		LIKE rept020.r20_val_descto,
	precio			LIKE rept020.r20_precio, 
	total			LIKE rept019.r19_tot_bruto
END RECORD

DEFINE vm_filas_pant		SMALLINT

-- Registro de la tabla de configuración del módulo de repuestos
DEFINE rm_r00			RECORD LIKE rept000.*
DEFINE rm_c00			RECORD LIKE ordt000.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp202.error')
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
LET vg_proceso = 'repp202'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
			        -- que luego puede ser reemplazado si se 
                            	-- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

INITIALIZE vm_cod_tran, vm_num_tran TO NULL
IF num_args() = 6 THEN
	LET vm_cod_tran = arg_val(5)
	LET vm_num_tran = arg_val(6)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_202 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_202 FROM '../forms/repf202_1'
DISPLAY FORM f_202

LET vm_num_rows = 0
LET vm_row_current = 0
LET vm_transaccion = 'IC'
INITIALIZE rm_r19.* TO NULL

CALL muestra_contadores()
CALL setea_nombre_botones()

LET vm_max_rows = 1000
LET vm_max_compra = 100
LET vm_max_detalle  = 250

CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe registro de configuración en el módulo de ' ||
		'repuestos para esta compañía.',
		'exclamation')
	EXIT PROGRAM
END IF

CALL fl_lee_compania_orden_compra(vg_codcia) RETURNING rm_c00.*
IF rm_c00.c00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe registro de configuración en el módulo de ' ||
		'ordenes de compra para esta compañía.',
		'exclamation')
	EXIT PROGRAM
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
		IF vm_num_tran IS NOT NULL THEN
			CALL execute_query()
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF fl_control_permiso_opcion('Imprimir') THEN			
				SHOW OPTION 'Imprimir'
			END IF 
		
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Detalle'
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
			IF fl_control_permiso_opcion('Imprimir') THEN
			      SHOW OPTION 'Imprimir'
		        END IF
		
		END IF
		CALL setea_nombre_botones()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Detalle'
		CALL control_consulta()
	
		IF vm_num_rows <= 1 THEN
			IF vm_indice > vm_filas_pant THEN
				
			    	  SHOW OPTION 'Detalle'
		        
			END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			IF vm_indice > vm_filas_pant THEN
				
			    		  SHOW OPTION 'Detalle'
		        
			END IF
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_num_rows > 0 THEN
			IF vm_indice > vm_filas_pant THEN
				
			    		  SHOW OPTION 'Detalle'
		        
			END IF	
				IF fl_control_permiso_opcion('Imprimir') THEN
			    		  SHOW OPTION 'Imprimir'
		           	END IF	
		
		END IF
		IF vm_row_current <= 1 THEN
            HIDE OPTION 'Retroceder'
        END IF
		CALL setea_nombre_botones()
	COMMAND KEY('D') 'Detalle'		'Ver detalle de recepcion.'
		CALL control_mostrar_det()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
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
        IF vm_indice > vm_filas_pant THEN
			
			   SHOW OPTION 'Detalle'
		    
	END IF
        IF vm_num_rows > 0 THEN
			IF fl_control_permiso_opcion('Imprimir') THEN
	    		  SHOW OPTION 'Imprimir'
	           	END IF	
        END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
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
                IF vm_indice > vm_filas_pant THEN
			
			   SHOW OPTION 'Detalle'
		    
		END IF
                IF vm_num_rows > 0 THEN
                	IF fl_control_permiso_opcion('Imprimir') THEN
	    		  SHOW OPTION 'Imprimir'
	           	END IF	
                END IF
        COMMAND KEY('P') 'Imprimir'		'Imprime la recepción.'
        	CALL imprimir()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE i			SMALLINT

DEFINE rowid		SMALLINT
DEFINE intentar		SMALLINT
DEFINE done			SMALLINT

DEFINE resp 		CHAR(6)
DEFINE estado 		LIKE ordt010.c10_estado
DEFINE costo		LIKE rept019.r19_tot_costo

DEFINE r_g21		RECORD LIKE gent021.*

CLEAR FORM
INITIALIZE rm_r19.* TO NULL

-- THESE VALUES WON'T CHANGE 
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
LET rm_r19.r19_cod_tran   = vm_transaccion
LET rm_r19.r19_flete      = 0
LET rm_r19.r19_fact_venta = 0
LET rm_r19.r19_descuento  = 0.0
LET rm_r19.r19_porc_impto = 0.0
LET rm_r19.r19_paridad    = 0.0
LET rm_r19.r19_precision  = 0
LET rm_r19.r19_tot_bruto  = 0.0
LET rm_r19.r19_tot_dscto  = 0.0
LET rm_r19.r19_cont_cred  = 'C'
SELECT MIN(r01_codigo) INTO rm_r19.r19_vendedor
  FROM rept001 WHERE r01_compania = vg_codcia
LET rm_r19.r19_moneda     = rg_gen.g00_moneda_base
LET rm_r19.r19_paridad    = calcula_paridad(rg_gen.g00_moneda_base,	
											rm_r19.r19_moneda)
CALL fl_lee_moneda(rm_r19.r19_moneda) RETURNING r_g13.*
LET rm_r19.r19_precision   = r_g13.g13_decimales

LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_fecing     = CURRENT
LET rm_r19.r19_bodega_ori = rm_r00.r00_bodega_fact

LET rm_r19.r19_dircli     = '.'   
LET rm_r19.r19_cedruc     = '.'   

CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
LET rm_r19.r19_tipo_tran  = r_g21.g21_tipo
LET rm_r19.r19_calc_costo = r_g21.g21_calc_costo

CALL muestra_etiquetas()

CALL lee_datos()
LET rm_r19.r19_nomcli     = rm_p01.p01_nomprov
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
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
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
WHENEVER ERROR STOP
IF NOT intentar AND NOT done THEN
	ROLLBACK WORK
	FREE q_c10
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
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
	ROLLBACK WORK
	RETURN
END IF

LET rm_r19.r19_referencia  = 'Recepcion compra local: ', rm_r19.r19_oc_interna
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
DISPLAY BY NAME rm_r19.r19_num_tran

INSERT INTO rept019 VALUES (rm_r19.*)
LET rowid = SQLCA.SQLERRD[6]            -- Rowid de la ultima fila
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
LET INT_FLAG = 0

CLOSE q_c10
FREE  q_c10


SELECT SUM(r20_costo * r20_cant_ven) INTO costo
  FROM rept020
 WHERE r20_compania  = rm_r19.r19_compania	
   AND r20_localidad = rm_r19.r19_localidad
   AND r20_cod_tran  = rm_r19.r19_cod_tran 
   AND r20_num_tran  = rm_r19.r19_num_tran 

IF costo IS NULL THEN
	LET costo = 0
END IF

UPDATE rept019 SET r19_tot_costo = costo,
				   r19_tot_bruto = 0, 
				   r19_tot_dscto = 0, 
				   r19_tot_neto  = costo 
 WHERE r19_compania  = rm_r19.r19_compania	
   AND r19_localidad = rm_r19.r19_localidad
   AND r19_cod_tran  = rm_r19.r19_cod_tran 
   AND r19_num_tran  = rm_r19.r19_num_tran 

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
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE contador		SMALLINT

DEFINE oc_ant		LIKE ordt010.c10_numero_oc

LET INT_FLAG = 0
INPUT BY NAME rm_r19.r19_cod_tran,
			  rm_r19.r19_oc_interna, rm_r19.r19_bodega_ori,
              rm_r19.r19_usuario, rm_r19.r19_fecing 
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(r19_oc_interna, r19_bodega_ori) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
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
		IF INFIELD(r19_bodega_ori) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T')
		     		RETURNING r_r02.r02_codigo, r_r02.r02_nombre
		     	IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r19.r19_bodega_ori = r_r02.r02_codigo
				DISPLAY BY NAME rm_r19.r19_bodega_ori
				DISPLAY r_r02.r02_nombre TO n_bodega
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
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
			CONTINUE INPUT
		END IF

		CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
			rm_r19.r19_oc_interna) RETURNING r_c10.*
		IF r_c10.c10_numero_oc IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				'Orden de compra no existe.',
				'exclamation')
			INITIALIZE r_c10.* TO NULL
			CALL etiquetas_orden_compra(r_c10.*)
			NEXT FIELD r19_oc_interna 
		END IF
		IF r_c10.c10_estado <> 'P' THEN
			CASE r_c10.c10_estado
				WHEN 'A'
					CALL fgl_winmessage(vg_producto,
						'No puede recepcionar esta orden de compra ' ||
						'por que no ha sido aprobada.',
						'exclamation')
				WHEN 'C'
					CALL fgl_winmessage(vg_producto,
						'No puede recepcionar esta orden de compra ' ||
						'por que ya esta cerrada.',
						'exclamation')
			END CASE
			INITIALIZE r_c10.* TO NULL
			CALL etiquetas_orden_compra(r_c10.*)
			NEXT FIELD r19_oc_interna
		END IF
		
		CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
			RETURNING r_c01.*
		IF r_c01.c01_modulo <> vg_modulo AND r_c01.c01_ing_bodega <> 'S'
		THEN
			CALL fgl_winmessage(vg_producto,
				'Esta orden de compra no puede asociarse a ' ||
				'una compra local.',
				'exclamation')
			INITIALIZE r_c10.* TO NULL
			CALL etiquetas_orden_compra(r_c10.*)
			NEXT FIELD r19_oc_interna
		END IF

		CALL etiquetas_orden_compra(r_c10.*)
		CALL setea_nombre_botones()
	AFTER FIELD r19_bodega_ori
		IF rm_r19.r19_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe.',
						    'exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF 
			IF r_r02.r02_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
					            'Bodega está ' ||
                                                    'bloqueada.',
						    'exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF
			IF r_r02.r02_tipo <> 'F' THEN
				CALL fgl_winmessage(vg_producto,
					'Debe escoger una bodega física.',
					'exclamation')
				CLEAR n_bodega
				NEXT FIELD r19_bodega_ori
			END IF
			DISPLAY r_r02.r02_nombre TO n_bodega
		ELSE
			CLEAR n_bodega
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

LET vm_indice = lee_detalle_orden_compra() 
IF INT_FLAG THEN
	RETURN
END IF

IF vm_indice = 0 THEN
	CALL fgl_winmessage(vg_producto,
		'La orden de compra ya fue recibida por completo.',
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
			CALL calcula_totales()
		AFTER FIELD r20_cant_ven
			IF rm_compra[i].cant_ven IS NULL THEN
				LET rm_compra[i].cant_ven = 0
				DISPLAY rm_compra[i].cant_ven
					TO ra_compra[j].r20_cant_ven
				CONTINUE INPUT
			END IF
			IF rm_compra[i].cant_ven > rm_compra[i].cant_ped THEN
				CALL fgl_winmessage(vg_producto, 'No puede recepcionar mas de lo que pidio.', 'exclamation')
				NEXT FIELD r20_cant_ven
			END IF
			LET rm_datos[i].total = 
				rm_datos[i].precio * rm_compra[i].cant_ven
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



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_r19.* FROM rept019 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_r19.r19_cod_tran,
				rm_r19.r19_num_tran,
				rm_r19.r19_oc_interna,
				rm_r19.r19_bodega_ori,
				rm_r19.r19_usuario,
				rm_r19.r19_fecing

CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_c10		RECORD LIKE ordt010.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON r19_num_tran, r19_oc_interna, r19_bodega_ori, r19_usuario
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
		IF INFIELD(r19_bodega_ori) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T')
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
		'  AND r19_cod_tran = "', vm_transaccion, '"', 
	    '  AND ', expr_sql CLIPPED,
	    'ORDER BY 1, 2, 3 DESC' 

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




FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

LET filas_pant = fgl_scr_size('ra_compra')
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

END FUNCTION



FUNCTION lee_detalle()
DEFINE i		SMALLINT

DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*

DECLARE q_det CURSOR FOR
	   SELECT r20_item, r20_cant_ped, r10_nombre, r20_orden,       
			  r20_cant_ven 
         FROM rept020, rept010
		WHERE r20_compania  = vg_codcia
		  AND r20_localidad = vg_codloc  
		  AND r20_cod_tran  = vm_cod_tran
		  AND r20_num_tran  = vm_num_tran
		  AND r10_compania  = r20_compania
		  AND r10_codigo    = r20_item
	ORDER BY r20_orden

LET i = 1
FOREACH q_det INTO r_r20.r20_item, r_r20.r20_cant_ped, r_r10.r10_nombre, 
				   r_r20.r20_orden, r_r20.r20_cant_ven
	LET rm_compra[i].cant_ped    = r_r20.r20_cant_ped
	LET rm_compra[i].cant_ven    = r_r20.r20_cant_ven
	LET rm_compra[i].item        = r_r20.r20_item
	LET rm_compra[i].descripcion = r_r10.r10_nombre

	LET i = i + 1
	IF i > 100 THEN
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

	SELECT SUM(c14_cantidad) INTO r_c11.c11_cant_rec 
      FROM ordt014
	 WHERE c14_compania  = vg_codcia
	   AND c14_localidad = vg_codloc
	   AND c14_numero_oc = r_c11.c11_numero_oc
	   AND c14_codigo    = r_c11.c11_codigo

	IF r_c11.c11_cant_rec IS NULL THEN
		LET r_c11.c11_cant_rec = 0
	END IF

	LET rm_compra[i].cant_ped    = r_c11.c11_cant_ped - r_c11.c11_cant_rec
	LET rm_compra[i].cant_ven    = r_c11.c11_cant_ped - r_c11.c11_cant_rec

	IF rm_compra[i].cant_ped = 0 THEN
		CONTINUE FOREACH
	END IF

	LET rm_compra[i].item        = r_c11.c11_codigo
	LET rm_compra[i].descripcion = r_r10.r10_nombre

	LET rm_datos[i].descuento    = r_c11.c11_descuento
	LET rm_datos[i].precio       = r_c11.c11_precio
	LET rm_datos[i].total        = r_c11.c11_precio * rm_compra[i].cant_ven
	LET rm_datos[i].val_descto   = r_c11.c11_val_descto

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



FUNCTION muestra_etiquetas()

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r01		RECORD LIKE rept001.*

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_r19.r19_oc_interna)
	RETURNING r_c10.*
CALL etiquetas_orden_compra(r_c10.*)
CALL setea_nombre_botones()

CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori) RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO n_bodega

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
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
				    'para esta moneda.',
				    'exclamation')
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
DEFINE retVal 		INTEGER

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

DISPLAY 'Item'   TO bt_item    
DISPLAY 'Descripcion'   TO bt_descripcion    
DISPLAY 'O/C'   TO bt_cant_ped
DISPLAY 'Cant'   TO bt_cant_vend

END FUNCTION



FUNCTION etiquetas_orden_compra(r_c10)

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*

IF r_c10.c10_numero_oc IS NULL THEN
	CLEAR cod_proveedor, n_proveedor
ELSE
	DISPLAY r_c10.c10_codprov TO cod_proveedor
	CALL fl_lee_proveedor(r_c10.c10_codprov) RETURNING r_p01.*
	LET rm_p01.* = r_p01.*
	DISPLAY r_p01.p01_nomprov TO n_proveedor
END IF

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
	IF rm_datos[i].total IS NOT NULL THEN
		LET rm_datos[i].val_descto = 
			rm_datos[i].total * (rm_datos[i].descuento / 100)
		LET bruto = bruto + rm_datos[i].total
	END IF
	IF rm_datos[i].val_descto IS NOT NULL THEN
		LET descto = descto + rm_datos[i].val_descto
	END IF
END FOR

LET iva    = (bruto - descto) * (rm_c10.c10_porc_impto / 100)

LET precio = (bruto - descto) + iva

LET rm_r19.r19_tot_dscto  = descto
LET rm_r19.r19_tot_bruto  = bruto
LET rm_r19.r19_tot_neto   = precio
LET rm_r19.r19_tot_costo  = bruto

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



FUNCTION graba_detalle(r_c13)

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE i		SMALLINT
DEFINE orden    	SMALLINT
DEFINE costo_ing	DECIMAL(12,2)
DEFINE costo_nue	DECIMAL(12,2)
DEFINE descto_unit	DECIMAL(12,2)
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
LET r_r20.r20_stock_bd   = 0
LET r_r20.r20_descuento  = 0.0
LET r_r20.r20_val_descto = 0.0
LET r_r20.r20_val_impto  = 0.0
LET r_r20.r20_fob        = 0.0
LET r_r20.r20_ubicacion  = 'SN'

LET r_r20.r20_fecing     = CURRENT

LET orden = 1
FOR i = 1 TO vm_indice
	IF rm_compra[i].cant_ven <= 0 THEN
		CONTINUE FOR
	END IF
	LET r_r20.r20_orden      = orden
	LET orden = orden + 1                      
	LET descto_unit = rm_datos[i].val_descto / rm_compra[i].cant_ven 
	LET costo_ing = rm_datos[i].precio - descto_unit
			 
   	CALL fl_lee_item(vg_codcia, rm_compra[i].item) RETURNING r_r10.*

	LET done = actualiza_existencias(i)
	IF NOT done THEN
		RETURN done
	END IF

	LET r_r20.r20_cant_ped   = rm_compra[i].cant_ped   
	LET r_r20.r20_cant_ven   = rm_compra[i].cant_ven
	LET r_r20.r20_cant_ent   = rm_compra[i].cant_ven   
   	LET r_r20.r20_linea      = r_r10.r10_linea				
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion
	LET r_r20.r20_fob        = r_r10.r10_fob             
    LET r_r20.r20_precio     = r_r10.r10_precio_mb
    LET r_r20.r20_costo      = r_r10.r10_costo_mb
    LET r_r20.r20_costant_mb = r_r10.r10_costult_mb
    LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    LET r_r20.r20_costant_ma = r_r10.r10_costult_ma
    LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma

    CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori, rm_compra[i].item) 
		RETURNING r_r11.*
    IF r_r11.r11_compania IS NULL THEN
        LET r_r20.r20_ubicacion = 'SN'
        LET r_r20.r20_stock_ant = 0
    ELSE
        LET r_r20.r20_ubicacion = r_r11.r11_ubicacion
        LET r_r20.r20_stock_ant = r_r11.r11_stock_act - r_r20.r20_cant_ped
    END IF

	LET r_r20.r20_item       = rm_compra[i].item       
    INSERT INTO rept020 VALUES (r_r20.*)
    CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc,
                          		r_r20.r20_cod_tran, r_r20.r20_num_tran, 
								r_r20.r20_item)

	-- Graba detalle de recepcion
	LET r_c14.c14_compania   = rm_r19.r19_compania
	LET r_c14.c14_localidad  = rm_r19.r19_localidad
	LET r_c14.c14_numero_oc  = rm_r19.r19_oc_interna
	LET r_c14.c14_num_recep  = r_c13.c13_num_recep
	LET r_c14.c14_secuencia  = orden - 1	-- Arriba incremente orden
	LET r_c14.c14_codigo     = rm_compra[i].item  
	LET r_c14.c14_cantidad   = rm_compra[i].cant_ven
	LET r_c14.c14_descrip    = r_r10.r10_nombre  
	LET r_c14.c14_descuento  = rm_datos[i].descuento  
	LET r_c14.c14_val_descto = rm_datos[i].val_descto
	LET r_c14.c14_precio     = rm_datos[i].precio
	LET r_c14.c14_val_impto  = ((r_c14.c14_cantidad * r_c14.c14_precio) -
 				    r_c14.c14_val_descto) * 
				   rm_c10.c10_porc_impto / 100	
	LET r_c14.c14_paga_iva   = 'S'
	INSERT INTO ordt014 VALUES(r_c14.*)
END FOR 
LET done = 1

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



FUNCTION graba_cabecera_recepcion(r_c10)

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*

INITIALIZE r_c13.* TO NULL

LET r_c13.c13_compania     = vg_codcia
LET r_c13.c13_localidad    = vg_codloc
LET r_c13.c13_numero_oc    = rm_r19.r19_oc_interna
LET r_c13.c13_estado       = 'P'

LET r_c13.c13_fecha_recep = CURRENT
LET r_c13.c13_bodega      = rm_r19.r19_bodega_ori
LET r_c13.c13_interes     = r_c10.c10_interes
LET r_c13.c13_tot_bruto   = rm_r19.r19_tot_bruto
LET r_c13.c13_tot_dscto   = rm_r19.r19_tot_dscto
LET r_c13.c13_tot_impto   = 
	(rm_r19.r19_tot_neto - rm_r19.r19_tot_bruto) + rm_r19.r19_tot_dscto
LET r_c13.c13_tot_recep   = rm_r19.r19_tot_neto
LET r_c13.c13_usuario     = vg_usuario
LET r_c13.c13_fecing      = CURRENT

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



FUNCTION imprimir()

DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp421 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran, ' ',
	rm_r19.r19_num_tran
	
RUN comando	

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
				  AND   r11_bodega  = rm_r19.r19_bodega_ori
				  AND   r11_item    = rm_compra[i].item
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

IF r_r11.r11_compania IS NOT NULL THEN
	UPDATE rept011 SET r11_stock_ant = r11_stock_act,
			   		   r11_stock_act = r11_stock_act + rm_compra[i].cant_ven,
		  		   	   r11_ing_dia   = rm_compra[i].cant_ven
		WHERE CURRENT OF q_r11
END IF
CLOSE q_r11
FREE q_r11

RETURN done

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = vm_cod_tran
	  AND r19_num_tran  = vm_num_tran
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe ninguna recepcion para esta orden de compra.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

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

{*
 * Titulo           : repp216.4gl - Ingreso Tranferencias
 * Elaboracion      : 08-feb-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp216 base modulo compania localidad
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_row_current_2	SMALLINT	-- CONTROLAR EL ROLLBACK
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE

--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_r00		 	RECORD LIKE rept000.*	-- CONFIGURACION DE LA
							-- COMPAÑIA DE RPTO.
DEFINE rm_r01		 	RECORD LIKE rept001.*	-- VENDEDOR
DEFINE rm_r02		 	RECORD LIKE rept002.*	-- BODEGA
DEFINE rm_r03		 	RECORD LIKE rept003.*	-- LINEA VTA.
DEFINE rm_r10		 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r11		 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r19			RECORD LIKE rept019.*	-- CABECERA
DEFINE rm_r20		 	RECORD LIKE rept020.*	-- DETALLE
DEFINE rm_g22		 	RECORD LIKE gent022.*	-- SUBTIPO TRANSACCIONES

DEFINE r_detalle ARRAY[200] OF RECORD
	r20_cant_ped		LIKE rept020.r20_cant_ped,
	r20_stock_ant		LIKE rept020.r20_stock_ant,
	r20_item		LIKE rept020.r20_item,
	r20_costo		LIKE rept020.r20_costo,
	subtotal_item		LIKE rept019.r19_tot_costo
	END RECORD
	-----------------------------------------------------
DEFINE vm_ind_arr	SMALLINT
DEFINE vm_filas_pant	SMALLINT
DEFINE vm_total    	DECIMAL(12,2)
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vg_cod_tran	LIKE gent021.g21_cod_tran
DEFINE vg_num_tran	LIKE rept019.r19_num_tran



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp216.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4  AND num_args() <> 6 THEN -- Validar # parámetros correcto
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
LET vg_proceso = 'repp216'

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
LET vm_max_rows     = 1000
LET vm_cod_tran     = 'TR'
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_216 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_216 FROM '../forms/repf216_1'
DISPLAY FORM f_216
CALL control_display_botones()

LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Imprimir'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
			CALL control_consulta()
			IF vm_ind_arr > vm_filas_pant THEN
				SHOW OPTION 'Ver Detalle'
			END IF
                	SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_row_current > 0 THEN
			SHOW OPTION 'Ver Detalle'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		HIDE OPTION 'Imprimir'
		CALL control_consulta()
		IF vm_num_rows < 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Ver Detalle'
			END IF
		ELSE
			IF vm_num_rows = 1 THEN
				SHOW OPTION 'Ver Detalle'
				HIDE OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			ELSE
				SHOW OPTION 'Avanzar'
				SHOW OPTION 'Ver Detalle'
			END IF
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('D') 'Ver Detalle'		'Ver detalle del Registro.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
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
        COMMAND KEY('P') 'Imprimir'		'Imprime comprobante.'
        	CALL imprimir()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'Cant'		TO tit_col1
DISPLAY 'Stock'		TO tit_col2
DISPLAY 'Item'		TO tit_col3
DISPLAY 'Costo Unit.'	TO tit_col4
DISPLAY 'Subtotal'	TO tit_col5

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE i,j 	SMALLINT

CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.*
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT', '')
	BEFORE ROW 
		LET i = arr_curr()
		LET j = scr_line()

		CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
			RETURNING rm_r10.*
		DISPLAY rm_r10.r10_nombre TO nom_item

        AFTER DISPLAY
                CONTINUE DISPLAY
        ON KEY(INTERRUPT)
                EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE done 		SMALLINT

CLEAR FORM
CALL control_display_botones()

INITIALIZE rm_r19.* TO NULL
INITIALIZE rm_r20.* TO NULL

-- INITIAL VALUES FOR rm_r19 FIELDS
LET rm_r19.r19_fecing     = CURRENT
LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
LET rm_r19.r19_cod_tran   = vm_cod_tran

DISPLAY BY NAME rm_r19.r19_usuario, rm_r19.r19_fecing, rm_r19.r19_cod_tran

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET rm_r19.r19_tot_costo = 0 
LET rm_r19.r19_tot_neto  = 0 

LET INT_FLAG = 0
LET vm_num_detalles = ingresa_detalles() 
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

	-- ACTUALIZO LA FECHA DE INGRESO --
LET rm_r19.r19_fecing    = CURRENT
LET rm_r20.r20_fecing    = CURRENT
DISPLAY BY NAME rm_r19.r19_fecing
	-----------------------------------

BEGIN WORK
	CALL control_ingreso_cabecera()
		RETURNING done 
	IF  done = 0 THEN  	-- PARA SABER SI HUBO O NO UN ERROR
		ROLLBACK WORK   -- EN EL NUMERO DE TRANSACCION
		IF vm_num_rows > 0 THEN 
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		ELSE
			CLEAR FORM
			CALL control_display_botones()
		END IF
		RETURN
	END IF

	CALL control_actualizacion_existencia()
	CALL control_ingreso_detalle()

	CALL preparar_transferencias_para_recepcion()

COMMIT WORK
CALL fl_control_master_contab_repuestos(rm_r19.r19_compania, 
	rm_r19.r19_localidad, rm_r19.r19_cod_tran, rm_r19.r19_num_tran)

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_ingreso_cabecera()
DEFINE num_tran         LIKE rept019.r19_num_tran
DEFINE done 			SMALLINT
DEFINE r_g21			RECORD LIKE gent021.*

LET done = 0
  -- ATRAPO EL NUMERO DE LA TRANSACCION QUE LE CORRESPONDA AL REGISTRO --

CALL fl_lee_compania_repuestos(vg_codcia)  -- PARA OBTENER LA BODEGA PRINCIPAL
					   -- DE LA COMPAÑIA
	RETURNING rm_r00.*

LET rm_r19.r19_cont_cred  = 'C'
LET rm_r19.r19_nomcli     = ' '
LET rm_r19.r19_dircli     = ' '
LET rm_r19.r19_cedruc     = ' '
LET rm_r19.r19_descuento  = 0.0
LET rm_r19.r19_porc_impto = 0.0
LET rm_r19.r19_moneda     = rg_gen.g00_moneda_base
LET rm_r19.r19_paridad    = rg_gen.g00_decimal_mb
LET rm_r19.r19_precision  = 1
LET rm_r19.r19_tot_bruto  = 0.0
LET rm_r19.r19_tot_dscto  = 0.0
LET rm_r19.r19_flete      = 0.0
LET rm_r19.r19_tot_neto   = rm_r19.r19_tot_costo

CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
LET rm_r19.r19_tipo_tran  = r_g21.g21_tipo
LET rm_r19.r19_calc_costo = r_g21.g21_calc_costo

CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
	                             'AA',vm_cod_tran)
	RETURNING num_tran

CASE num_tran 
	WHEN 0
			CALL fgl_winmessage(vg_producto,'No existe control de'||
				    ' secuencia para esta transacción, no se'||
				    ' puede asignar un número de transacción'||
				    ' a la operación. ','stop')
			ROLLBACK WORK	
			EXIT PROGRAM
	WHEN -1
		SET LOCK MODE TO WAIT
		WHILE num_tran = -1
			CALL fl_actualiza_control_secuencias(vg_codcia, 
							     vg_codloc, 
							     vg_modulo, 
							 'AA', vm_cod_tran)
				RETURNING num_tran
		END WHILE
		SET LOCK MODE TO NOT WAIT
END CASE
LET rm_r19.r19_num_tran   = num_tran

INSERT INTO rept019 VALUES (rm_r19.*)
DISPLAY BY NAME rm_r19.r19_num_tran
LET done = 1

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
        LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current_2     = vm_row_current
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
RETURN done

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE j 			SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*	

---- INITIAL VALUES FOR rm_r20 FIELDS ----
LET rm_r20.r20_compania   = vg_codcia
LET rm_r20.r20_localidad  = vg_codloc
LET rm_r20.r20_cod_tran   = vm_cod_tran
LET rm_r20.r20_num_tran   = rm_r19.r19_num_tran
LET rm_r20.r20_cant_ent   = 0 
LET rm_r20.r20_cant_dev   = 0
LET rm_r20.r20_descuento  = 0.0
LET rm_r20.r20_val_descto = 0.0
LET rm_r20.r20_val_impto  = 0.0
------------------------------------------
LET rm_r20.r20_num_tran = rm_r19.r19_num_tran
FOR j = 1 TO vm_num_detalles
	LET rm_r20.r20_cant_ped   = r_detalle[j].r20_cant_ped
	LET rm_r20.r20_cant_ven   = r_detalle[j].r20_cant_ped
	LET rm_r20.r20_stock_ant  = r_detalle[j].r20_stock_ant 

	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_dest, r_detalle[j].r20_item)
		RETURNING rm_r11.*
	IF rm_r11.r11_stock_act IS NULL THEN
		LET rm_r11.r11_stock_act = 0
		LET rm_r11.r11_ubicacion  = 'SN'
	END IF

	CALL fl_lee_item(vg_codcia, r_detalle[j].r20_item) RETURNING r_r10.*

	LET rm_r20.r20_ubicacion  = rm_r11.r11_ubicacion
	LET rm_r20.r20_stock_bd   = rm_r11.r11_stock_act 
	LET rm_r20.r20_item       = r_detalle[j].r20_item 
	LET rm_r20.r20_costo      = r_detalle[j].r20_costo 
	LET rm_r20.r20_orden      = j
	LET rm_r20.r20_fob        = r_r10.r10_fob 
	LET rm_r20.r20_linea      = r_r10.r10_linea 
	LET rm_r20.r20_rotacion   = r_r10.r10_rotacion 
	LET rm_r20.r20_precio     = r_r10.r10_precio_mb 
	LET rm_r20.r20_costant_mb = r_r10.r10_costult_mb
	LET rm_r20.r20_costnue_mb = r_r10.r10_costo_mb
	LET rm_r20.r20_costant_ma = r_r10.r10_costult_ma
	LET rm_r20.r20_costnue_ma = r_r10.r10_costo_ma
	INSERT INTO rept020 VALUES(rm_r20.*)

	CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc, 
							rm_r20.r20_cod_tran, rm_r20.r20_num_tran, rm_r20.r20_item)
END FOR 

END FUNCTION



FUNCTION control_actualizacion_existencia()
DEFINE j 	SMALLINT

SET LOCK MODE TO WAIT

LET j = 1
FOR j = 1 TO vm_num_detalles
	
	UPDATE rept011 
		SET   r11_stock_ant = r11_stock_act,
		      r11_stock_act = r11_stock_act - r_detalle[j].r20_cant_ped,
		      r11_egr_dia   = r_detalle[j].r20_cant_ped
		WHERE r11_compania  = vg_codcia
		AND   r11_bodega    = rm_r19.r19_bodega_ori
		AND   r11_item      = r_detalle[j].r20_item 
			
	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_dest, 
			      r_detalle[j].r20_item)
		RETURNING rm_r11.*
        display rm_r11.r11_stock_act , '   ' , rm_r11.r11_ubicacion
	IF rm_r11.r11_stock_act IS NULL THEN
		INSERT INTO rept011
      			(r11_compania, r11_bodega, r11_item, 
		 	r11_ubicacion, r11_stock_ant, 
		 	r11_stock_act, r11_ing_dia,
		 	r11_egr_dia)
		VALUES(vg_codcia, rm_r19.r19_bodega_dest,
		       r_detalle[j].r20_item, 'SN', 
		       0, r_detalle[j].r20_cant_ped, 
		       r_detalle[j].r20_cant_ped,0) 
	ELSE
		UPDATE rept011 
			SET   r11_stock_ant = r11_stock_act,
	      		      r11_stock_act = r11_stock_act + 
					      r_detalle[j].r20_cant_ped,
	      		      r11_ing_dia   = r_detalle[j].r20_cant_ped
			WHERE r11_compania  = vg_codcia
			AND   r11_bodega    = rm_r19.r19_bodega_dest
			AND   r11_item      = r_detalle[j].r20_item 
	END IF

END FOR

SET LOCK MODE TO NOT WAIT

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

LET INT_FLAG = 0
INPUT BY NAME rm_r19.r19_vendedor,    rm_r19.r19_bodega_ori,
	      rm_r19.r19_bodega_dest, rm_r19.r19_referencia,
	      rm_r19.r19_cod_subtipo
	      WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r19_vendedor, r19_bodega_ori,
				     r19_referencia, r19_bodega_dest)
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
		IF INFIELD(r19_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
			    LET rm_r19.r19_vendedor = rm_r01.r01_codigo
			    DISPLAY BY NAME rm_r19.r19_vendedor
			    DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r19_bodega_ori) THEN
		     	CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T')
		     		RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     	IF rm_r02.r02_codigo IS NOT NULL THEN
				LET rm_r19.r19_bodega_ori = rm_r02.r02_codigo
				DISPLAY BY NAME rm_r19.r19_bodega_ori
			    	DISPLAY rm_r02.r02_nombre TO nom_bod_ori
		     END IF
		END IF
		IF INFIELD(r19_bodega_dest) THEN
		     	CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T')
		     		RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     	IF rm_r02.r02_codigo IS NOT NULL THEN
				LET rm_r19.r19_bodega_dest = rm_r02.r02_codigo
				DISPLAY BY NAME rm_r19.r19_bodega_dest
			    	DISPLAY rm_r02.r02_nombre TO nom_bod_des
		     END IF
		END IF
                IF INFIELD(r19_cod_subtipo) THEN
                       	CALL fl_ayuda_subtipo_tran(vm_cod_tran)
		       		RETURNING rm_g22.g22_cod_tran,
					  rm_g22.g22_cod_subtipo, 
					  rm_g22.g22_nombre
                        IF rm_g22.g22_cod_subtipo IS NOT NULL THEN
				LET rm_r19.r19_cod_subtipo = 
			            rm_g22.g22_cod_subtipo
                              	DISPLAY BY NAME rm_r19.r19_cod_subtipo
				DISPLAY rm_g22.g22_nombre TO nom_subtipo
                        END IF
                END IF
		LET INT_FLAG = 0
	AFTER FIELD r19_vendedor
		IF rm_r19.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING rm_r01.*
			IF rm_r01.r01_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'Vendedor no existe',
						    'exclamation')
				NEXT FIELD r19_vendedor
			END IF 
			IF rm_r01.r01_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
						            'Vendedor está ' ||
                                                            'bloqueado',
							    'exclamation')
					NEXT FIELD r19_vendedor
			END IF
			DISPLAY rm_r01.r01_nombres TO nom_vendedor
		ELSE
			CLEAR nom_vendedor
		END IF		 
	AFTER FIELD r19_bodega_ori
		IF rm_r19.r19_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
				RETURNING rm_r02.*
			IF rm_r02.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe',
						    'exclamation')
				NEXT FIELD r19_bodega_ori
			END IF 
			IF rm_r02.r02_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
						            'Bodega está ' ||
                                                            'bloqueada',
							    'exclamation')
					NEXT FIELD r19_bodega_ori
			END IF
{
			IF rm_r02.r02_tipo <> 'F' THEN
					CALL fgl_winmessage(vg_producto,
						            'Bodega no es ' ||
                                                            'física',
							    'exclamation')
					NEXT FIELD r19_bodega_ori
			END IF
			IF rm_r02.r02_factura <> 'S' THEN
					CALL fgl_winmessage(vg_producto,
						            'Bodega no ' ||
                                                            'factura',
							    'exclamation')
					NEXT FIELD r19_bodega_ori
			END IF
}
			IF rm_r02.r02_localidad <> vg_codloc THEN
				CALL fgl_winmessage(vg_producto, 'La bodega origen debe ser de esta localidad.', 'exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			IF rm_r19.r19_bodega_ori = rm_r19.r19_bodega_dest THEN
				CALL fgl_winmessage(vg_producto,'La bodega origen no puede ser la misma que la bodega destino.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			DISPLAY rm_r02.r02_nombre TO nom_bod_ori
		ELSE
			CLEAR nom_bod_ori
		END IF
	AFTER FIELD r19_bodega_dest
		IF rm_r19.r19_bodega_dest IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, 
						rm_r19.r19_bodega_dest)
				RETURNING rm_r02.*
			IF rm_r02.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe',
						    'exclamation')
				NEXT FIELD r19_bodega_dest
			END IF 
			IF rm_r02.r02_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
						            'Bodega está ' ||
                                                            'bloqueada',
							    'exclamation')
					NEXT FIELD r19_bodega_dest
			END IF
{
			IF rm_r02.r02_tipo <> 'F' THEN
					CALL fgl_winmessage(vg_producto,
						            'Bodega no es ' ||
                                                            'física',
							    'exclamation')
					NEXT FIELD r19_bodega_dest
			END IF
			IF rm_r02.r02_factura <> 'S' THEN
					CALL fgl_winmessage(vg_producto,
						            'Bodega no ' ||
                                                            'factura',
							    'exclamation')
					NEXT FIELD r19_bodega_dest
			END IF
}
			IF rm_r19.r19_bodega_ori = rm_r19.r19_bodega_dest THEN
				CALL fgl_winmessage(vg_producto,'La bodega origen no puede ser la misma que la bodega destino.','exclamation')
				NEXT FIELD r19_bodega_dest
			END IF
			DISPLAY rm_r02.r02_nombre TO nom_bod_des
		ELSE
			CLEAR nom_bod_des
		END IF
	AFTER FIELD r19_cod_subtipo
		IF rm_r19.r19_cod_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_transaccion(rm_r19.r19_cod_subtipo)
				RETURNING rm_g22.*
			IF rm_g22.g22_cod_subtipo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'Subtipo de Transacción '||
						    'no existe',
						    'exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF 
			IF rm_g22.g22_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
						            'Subtipo de ' ||
                                                            'Transacción '||
							    'está bloqueada',
							    'exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			IF rm_g22.g22_cod_tran <> rm_r19.r19_cod_tran THEN
				CALL fgl_winmessage(vg_producto,'El Subtipo de Transacción no pertenece a la Transacción ','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			DISPLAY rm_g22.g22_nombre TO nom_subtipo
		ELSE
			CLEAR nom_subtipo
		END IF
END INPUT

END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j,k,ind	SMALLINT
DEFINE resp		CHAR(6)

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET i = 1
LET j = 1
DISPLAY BY NAME rm_r19.r19_tot_costo
CALL set_count(i)
INPUT ARRAY r_detalle FROM r_detalle.*
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
		
		IF r_detalle[i].r20_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
				RETURNING rm_r10.*
			DISPLAY rm_r10.r10_nombre TO nom_item
		END IF

	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN 0
		END IF
	ON KEY(F2)
		IF INFIELD(r20_item) THEN
                	CALL fl_ayuda_maestro_items_stock_sinlinea(vg_codcia, 
							rm_r19.r19_bodega_ori)
                     		RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre,
					  rm_r10.r10_linea,
					  rm_r10.r10_precio_mb,	
					  rm_r11.r11_bodega, 
					  rm_r11.r11_stock_act

                     	IF rm_r10.r10_codigo IS NOT NULL THEN
				LET r_detalle[i].r20_item      = 
				    rm_r10.r10_codigo
				LET r_detalle[i].r20_stock_ant =
				    rm_r11.r11_stock_act
                        	DISPLAY rm_r10.r10_codigo TO
					r_detalle[j].r20_item
                        	DISPLAY r_detalle[i].r20_stock_ant TO
					r_detalle[j].r20_stock_ant
                        	DISPLAY rm_r10.r10_nombre TO nom_item
                     	END IF
                END IF
                LET int_flag = 0
	AFTER FIELD r20_cant_ped
	    	IF  r_detalle[i].r20_cant_ped IS NOT NULL
		AND r_detalle[i].r20_item IS NOT NULL 
		    THEN
			IF r_detalle[i].r20_stock_ant < 
		   	   r_detalle[i].r20_cant_ped
		   	   THEN				
				CALL fgl_winmessage(vg_producto,'La cantidad ingresada para la transferencia es mayor al stock existente en la bodega origen.','exclamation')
				NEXT FIELD r20_cant_ped
			END IF
			CALL calcular_total()
			DISPLAY r_detalle[i].subtotal_item TO
				r_detalle[j].subtotal_item
		END IF 
		IF r_detalle[i].r20_cant_ped IS NULL AND 
		   r_detalle[i].r20_item IS NOT NULL 
		   THEN
			NEXT FIELD r20_cant_ped
		END IF
	AFTER FIELD r20_item
	    	IF r_detalle[i].r20_item IS NOT NULL THEN
     			CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
				RETURNING rm_r10.*

                	IF rm_r10.r10_codigo IS NULL THEN
                       		CALL fgl_winmessage(vg_producto,
		                            'El item no existe','exclamation')
                       		NEXT FIELD r20_item
                	END IF

                	IF rm_r10.r10_estado = 'B' THEN
                       		CALL fgl_winmessage(vg_producto, 'El item está en estado bloqueado','exclamation')
                       		NEXT FIELD r20_item
                	END IF

			FOR k = 1 TO arr_count()
				IF  r_detalle[i].r20_item = 
				    r_detalle[k].r20_item
				AND i <> k
				THEN
					CALL fgl_winmessage(vg_producto,'No puede ingresar items repetidos','exclamation')
					NEXT FIELD r20_item
               			END IF
			END FOR

			---- PARA SACAR EL STOCK DE LA BODEGA ----
			CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,
     					      r_detalle[i].r20_item)
				RETURNING rm_r11.*

			IF rm_r11.r11_stock_act IS NULL OR 
			   rm_r11.r11_stock_act = 0 
			   THEN
				CALL fgl_winmessage(vg_producto, 'El item no posee existencia en la bodega. No se puede transferir. ','exclamation')
				NEXT FIELD r20_item
			END IF
			LET r_detalle[i].r20_stock_ant = rm_r11.r11_stock_act

			IF r_detalle[i].r20_cant_ped IS NOT NULL THEN
				IF r_detalle[i].r20_stock_ant < 
			   	   r_detalle[i].r20_cant_ped
			   	   THEN				
					DISPLAY rm_r10.r10_nombre TO nom_item
					CALL fgl_winmessage(vg_producto,'La cantidad ingresada para la transferencia es mayor al stock existente en la bodega origen.','exclamation')
					NEXT FIELD r20_cant_ped
				END IF
			END IF
			---------------------------------------------

			LET r_detalle[i].r20_stock_ant = rm_r11.r11_stock_act
			LET r_detalle[i].r20_costo     = rm_r10.r10_costo_mb

			--- DISPLAYO LOS DEMAS CAMPOS DE LA FILA SI TODO OK.---
			CALL calcular_total()
			DISPLAY rm_r11.r11_stock_act TO
				r_detalle[j].r20_stock_ant
			DISPLAY rm_r10.r10_nombre TO nom_item
			DISPLAY r_detalle[i].r20_costo TO
				r_detalle[j].r20_costo
			DISPLAY r_detalle[i].subtotal_item TO
				r_detalle[j].subtotal_item
			------------------------------------------------------

		ELSE
			IF r_detalle[i].r20_cant_ped IS NOT NULL
				AND r_detalle[i].r20_item IS NULL
			THEN
				NEXT FIELD r20_item
			END IF 
		END IF
	AFTER DELETE
		CALL calcular_total()
	AFTER INPUT
		IF rm_r19.r19_tot_costo  = 0 THEN
			NEXT FIELD r20_cant_ped
		END IF
		LET ind = arr_count()
		LET vm_ind_arr = arr_count()
END INPUT
RETURN ind

END FUNCTION



FUNCTION calcular_total()
DEFINE k 	SMALLINT

LET rm_r19.r19_tot_costo = 0
FOR k = 1 TO arr_count()
	LET r_detalle[k].subtotal_item = r_detalle[k].r20_cant_ped * 
					 r_detalle[k].r20_costo
	LET rm_r19.r19_tot_costo = rm_r19.r19_tot_costo + 
				   r_detalle[k].subtotal_item 
END FOR
DISPLAY BY NAME rm_r19.r19_tot_costo

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(500)
DEFINE r_r19		RECORD LIKE rept019.*

CLEAR FORM
CALL control_display_botones()

LET rm_r19.r19_cod_tran = vm_cod_tran
DISPLAY BY NAME rm_r19.r19_cod_tran
IF num_args() = 4 THEN
	LET INT_FLAG = 0
	CONSTRUCT BY NAME expr_sql 
			  ON r19_num_tran,    r19_vendedor, r19_bodega_ori, 
			     r19_bodega_dest, r19_referencia, r19_cod_subtipo,
			     r19_fecing,      r19_usuario
	ON KEY(F2)
		IF INFIELD(r19_num_tran) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      vm_cod_tran)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli 

		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				LET rm_r19.r19_num_tran = r_r19.r19_num_tran
				DISPLAY BY NAME rm_r19.r19_num_tran	
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
		IF INFIELD(r19_bodega_ori) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T')
		     		RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     IF rm_r02.r02_codigo IS NOT NULL THEN
			    LET rm_r19.r19_bodega_ori = rm_r02.r02_codigo
			    DISPLAY BY NAME rm_r19.r19_bodega_ori
			    DISPLAY rm_r02.r02_nombre TO nom_bod_ori
		     END IF
		END IF
		IF INFIELD(r19_bodega_dest) THEN
		     	CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T')
		     		RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     	IF rm_r02.r02_codigo IS NOT NULL THEN
				LET rm_r19.r19_bodega_dest = rm_r02.r02_codigo
			    	DISPLAY BY NAME rm_r19.r19_bodega_dest
			   	DISPLAY rm_r02.r02_nombre TO nom_bod_des
		    	END IF
		END IF
		LET int_flag = 0
	END CONSTRUCT
ELSE

	LET expr_sql = ' r19_num_tran = ', vg_num_tran

END IF

IF INT_FLAG THEN
	CLEAR FORM
	CALL control_display_botones()
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM rept019 ', 
		' WHERE r19_compania  = ',vg_codcia,
		' AND   r19_localidad = ',vg_codloc,
		' AND   r19_cod_tran  = "', vm_cod_tran,'"', 
		' AND ',expr_sql CLIPPED ||
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

CLEAR FORM
CALL control_display_botones()

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r19.* FROM rept019 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r19.r19_num_tran,    rm_r19.r19_cod_tran, 
		rm_r19.r19_cod_subtipo,	rm_r19.r19_vendedor, 
		rm_r19.r19_bodega_ori,  rm_r19.r19_bodega_dest,
		rm_r19.r19_tot_costo, 	rm_r19.r19_referencia, 
		rm_r19.r19_usuario,     rm_r19.r19_fecing

IF rm_r19.r19_cod_subtipo IS NOT NULL THEN
	CALL fl_lee_subtipo_transaccion(rm_r19.r19_cod_subtipo)
		RETURNING rm_g22.*
		DISPLAY rm_g22.g22_nombre TO nom_subtipo
END IF
CALL muestra_detalle()
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i 		SMALLINT
DEFINE query 		CHAR(250)

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET query = 'SELECT r20_cant_ped, r20_stock_ant, r20_item, r20_costo,
		    r20_costo * r20_cant_ped FROM rept020 ',
            	'WHERE r20_compania  =  ', vg_codcia, 
	    	'  AND r20_localidad =  ', vg_codloc,
	    	'  AND r20_cod_tran  = "', vm_cod_tran,'"',
            	'  AND r20_num_tran  =  ', rm_r19.r19_num_tran,
	    	' ORDER BY 3'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO r_detalle[i].*
	LET i = i + 1
        IF i > 200 THEN
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

DISPLAY "" AT 1,1
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

CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
	RETURNING rm_r02.*
	DISPLAY rm_r02.r02_nombre TO nom_bod_ori
CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_dest)
	RETURNING rm_r02.*
	DISPLAY rm_r02.r02_nombre TO nom_bod_des
CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
	RETURNING rm_r01.*
	DISPLAY rm_r01.r01_nombres TO nom_vendedor

END FUNCTION



FUNCTION imprimir()

DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp415 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran,
	rm_r19.r19_num_tran
	
RUN comando	

END FUNCTION



FUNCTION preparar_transferencias_para_recepcion()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE r_r02		RECORD LIKE rept002.*

	LET r_r19.* = rm_r19.*
	
	SELECT * INTO r_r02.* FROM rept002
		WHERE r02_compania = r_r19.r19_compania AND
		      r02_codigo   = r_r19.r19_bodega_dest
	IF r_r02.r02_localidad = vg_codloc THEN
		RETURN
	END IF 
	LET r_r19.r19_nomcli   = 'ORIGEN: TR-', r_r19.r19_num_tran 
					       USING '<<<<<<<'
	LET r_r19.r19_dircli   = r_r19.r19_nomcli
	INSERT INTO rept091 VALUES (r_r19.*)
	DECLARE qu_dtr CURSOR FOR 
		SELECT * FROM rept020
			WHERE r20_compania  = r_r19.r19_compania  AND 
			      r20_localidad = r_r19.r19_localidad AND 
			      r20_cod_tran  = r_r19.r19_cod_tran  AND
			      r20_num_tran  = r_r19.r19_num_tran
			ORDER BY r20_orden
	FOREACH qu_dtr INTO r_r20.*
		INSERT INTO rept092 VALUES (r_r20.*)
	END FOREACH
	FREE qu_dtr
	INITIALIZE r_r90.* TO NULL
    	LET r_r90.r90_compania 		= r_r19.r19_compania
    	LET r_r90.r90_localidad 	= r_r19.r19_localidad
    	LET r_r90.r90_cod_tran 		= r_r19.r19_cod_tran
    	LET r_r90.r90_num_tran 		= r_r19.r19_num_tran
    	LET r_r90.r90_fecing 		= r_r19.r19_fecing
    	LET r_r90.r90_locali_fin 	= r_r02.r02_localidad
    	LET r_r90.r90_fecing_fin 	= CURRENT
	INSERT INTO rept090 VALUES (r_r90.*)

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

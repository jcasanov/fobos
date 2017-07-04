--------------------------------------------------------------------------------
-- Titulo           : repp212.4gl - Ingreso Ajustes de Existencias
-- Elaboracion      : 25-sep-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp212 base modulo compania localidad
--			[cod_tran] [num_tran]
-- Ultima Correccion: 28-sep-2001
-- Motivo Correccion: 4
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows		ARRAY[1000] OF INTEGER -- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_row_current_2	SMALLINT	-- CONTROLAR EL ROLLBACK
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE
DEFINE vm_elementos	SMALLINT	-- NUMERO MAXIMO DEL DETALLE
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_r00	 	RECORD LIKE rept000.*	-- CONFIGURACION DE LA CIA
DEFINE rm_r01	 	RECORD LIKE rept001.*	-- VENDEDOR
DEFINE rm_r02	 	RECORD LIKE rept002.*	-- BODEGA
DEFINE rm_r03	 	RECORD LIKE rept003.*	-- LINEA VTA.
DEFINE rm_r10	 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r11	 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r19		RECORD LIKE rept019.*	-- CABECERA
DEFINE rm_r20	 	RECORD LIKE rept020.*	-- DETALLE
DEFINE rm_g22	 	RECORD LIKE gent022.*	-- SUBTIPO TRANSACCIONES
DEFINE rm_aj_exist	ARRAY[4000] OF RECORD
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r20_stock_ant	LIKE rept020.r20_stock_ant,
				r20_item	LIKE rept020.r20_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r10_costo_mb	LIKE rept010.r10_costo_mb,
				total		LIKE rept019.r19_tot_costo
			END RECORD
DEFINE vm_ind_arr	SMALLINT
DEFINE vm_size_arr	SMALLINT
DEFINE vm_total    	DECIMAL(12,2)
DEFINE linea		VARCHAR(5)
DEFINE tipo_ajuste	CHAR(2)
----- VARIABLES MODULARES DEL PROGRAMA PARA DEFINIR -----------
----- LOS DOS UNICOS TIPO DE TRANSACCIONES DEL PROCESO -------
DEFINE vm_ajuste_mas	LIKE gent021.g21_cod_tran
DEFINE vm_ajuste_menos	LIKE gent021.g21_cod_tran
DEFINE vg_cod_tran	LIKE gent021.g21_cod_tran
DEFINE vg_num_tran	LIKE rept019.r19_num_tran
DEFINE vm_bod_sstock	LIKE rept002.r02_codigo
DEFINE vm_bod_tal	LIKE rept002.r02_codigo



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp212.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN    -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_cod_tran = arg_val(5)
LET vg_num_tran = arg_val(6)
LET vg_proceso  = 'repp212'
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
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
LET vm_max_rows     = 1000
LET vm_elementos    = 4000
LET vm_ajuste_mas   = 'A+'
LET vm_ajuste_menos = 'A-'
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
INITIALIZE vm_bod_tal TO NULL
SELECT r02_codigo INTO vm_bod_tal
	FROM rept002
	WHERE r02_compania  = vg_codcia	 
	  AND r02_localidad = vg_codloc
          AND r02_estado    = "A"                                      
	  AND r02_area      = "T"                                       
	  AND r02_factura   = "S"                                       
	  AND r02_tipo      = "L"                                       
INITIALIZE vm_bod_sstock TO NULL                                      
SELECT r02_codigo INTO vm_bod_sstock FROM rept002                               
		WHERE r02_compania  = vg_codcia                                 
		  AND r02_localidad = vg_codloc
		  AND r02_estado    = "A"                                      
		  AND r02_tipo      = "S"                                       
OPEN WINDOW w_aj_exist AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_aj_exist FROM '../forms/repf212_1'
ELSE
	OPEN FORM f_aj_exist FROM '../forms/repf212_1c'
END IF
DISPLAY FORM f_aj_exist
CALL control_DISPLAY_botones()

CALL retorna_tam_arr()
LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r19.* TO NULL
INITIALIZE rm_r20.* TO NULL
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Imprimir'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
			CALL control_consulta()
			IF vm_ind_arr > vm_size_arr THEN
				SHOW OPTION 'Detalle'
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
			SHOW OPTION 'Detalle'
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
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			IF vm_num_rows = 1 THEN
				SHOW OPTION 'Detalle'
				HIDE OPTION 'Avanzar'
				HIDE OPTION 'Retroceder'
			ELSE
				SHOW OPTION 'Avanzar'
				SHOW OPTION 'Detalle'
			END IF
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('D') 'Detalle'		'Ver detalle de Ajuste'
		CALL control_detalle()
        COMMAND KEY('P') 'Imprimir'		'Imprime comprobante.'
        	CALL imprimir()
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
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'Cantidad'		TO tit_col1
--#DISPLAY 'Stock Act.'		TO tit_col2
--#DISPLAY 'Item'		TO tit_col3
--#DISPLAY 'Descripción'	TO tit_col4
--#DISPLAY 'Costo'		TO tit_col5
--#DISPLAY 'Subtotal'		TO tit_col6

END FUNCTION



FUNCTION control_detalle()
DEFINE i, j		SMALLINT

LET i = 0
IF vg_gui = 0 THEN
	LET i = 1
END IF
CALL muestra_contadores_det(i, vm_ind_arr)
CALL set_count(vm_ind_arr)
DISPLAY ARRAY rm_aj_exist TO rm_aj_exist.*
        ON KEY(INTERRUPT)
		CALL muestra_etiquetas_det(0, vm_ind_arr, 1)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL muestra_etiquetas_det(i, vm_ind_arr, i)
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_etiquetas_det(i, vm_ind_arr, i)
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
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
CALL control_DISPLAY_botones()

INITIALIZE rm_r19.* TO NULL
INITIALIZE linea TO NULL
INITIALIZE rm_r20.* TO NULL

-- INITIAL VALUES FOR rm_r19 FIELDS
LET rm_r19.r19_fecing     = CURRENT
LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
LET rm_r19.r19_cod_tran   = vm_ajuste_mas
DISPLAY BY NAME rm_r19.r19_fecing

-- THESE FIELDS ARE NOT NULL BUT THERE ARE NOTHING TO PUT IN THEM --
LET rm_r19.r19_cont_cred  = 'C'
LET rm_r19.r19_nomcli     = ' '
LET rm_r19.r19_dircli     = ' '
LET rm_r19.r19_cedruc     = ' '
LET rm_r19.r19_descuento  = 0.0
LET rm_r19.r19_porc_impto = 0.0
LET rm_r19.r19_precision  = rg_gen.g00_decimal_mb
LET rm_r19.r19_paridad    = 1
LET rm_r19.r19_tot_bruto  = 0.0
LET rm_r19.r19_tot_dscto  = 0.0
LET rm_r19.r19_flete      = 0.0
LET tipo_ajuste = 'I'
DISPLAY BY NAME tipo_ajuste

DISPLAY BY NAME rm_r19.r19_cod_tran
IF vg_gui = 0 THEN
	CALL muestra_codtran(rm_r19.r19_cod_tran)
END IF
CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET vm_total = 0
LET rm_r19.r19_tot_costo = vm_total 
LET rm_r19.r19_tot_neto  = vm_total 
LET INT_FLAG = 0
LET rm_r20.r20_cod_tran = rm_r19.r19_cod_tran
DISPLAY BY NAME rm_r19.r19_cod_tran
IF vg_gui = 0 THEN
	CALL muestra_codtran(rm_r19.r19_cod_tran)
END IF
LET vm_num_detalles = ingresa_detalles() 
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
	-- ACTUALIZO LOS VALORES DEFAULTS QUE INGRESE AL INICIO DE LEE DATOS --
LET rm_r19.r19_fecing = CURRENT
LET rm_r20.r20_fecing = CURRENT
LET rm_r19.r19_tot_costo = vm_total
LET rm_r19.r19_tot_neto = vm_total
DISPLAY BY NAME rm_r19.r19_fecing
BEGIN WORK

	CALL control_ingreso_cabecera()
		RETURNING intentar, done 
	IF intentar = 0 AND done = 0 THEN  -- PARA SABER SI HUBO O NO UN ERROR
					   -- EN EL NUMERO DE TRANSACCION
		CLEAR FORM
		CALL control_DISPLAY_botones()
		RETURN
	END IF

	CALL control_ingreso_detalle()
	CALL control_actualizacion_existencia()
		RETURNING intentar, done -- PARA SABER SI HIZO O NO EL ROLLBACK
	IF intentar = 0 AND done = 0 THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
		RETURN
	END IF
COMMIT WORK
{--
CALL fl_control_master_contab_repuestos(rm_r19.r19_compania, 
	rm_r19.r19_localidad, rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
--}
CALL fl_mostrar_mensaje('No se generó contabilización de este ajuste, consultar con el administrador.', 'exclamation')
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_ingreso_cabecera()
DEFINE i 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE num_tran         LIKE rept019.r19_num_tran
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT

LET intentar = 1
LET done = 0
  -- ATRAPO EL NUMERO DE LA TRANSACCION QUE LE CORRESPONDA AL REGISTRO --

CALL fl_lee_compania_repuestos(vg_codcia)  -- PARA OBTENER LA BODEGA PRINCIPAL
					   -- DE LA COMPAÑIA
	RETURNING rm_r00.*
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
	                             'AA',rm_r19.r19_cod_tran)
	RETURNING num_tran
CASE num_tran 
	WHEN 0
			--CALL fgl_winmessage(vg_producto,'No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
			CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
			ROLLBACK WORK	
			EXIT PROGRAM
	WHEN -1
		SET LOCK MODE TO WAIT
		WHILE num_tran = -1
			IF num_tran <> -1 THEN
				EXIT WHILE
			END IF
			CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, rm_r00.r00_bodega_fact, rm_r19.r19_cod_tran)
				RETURNING num_tran
		END WHILE
		SET LOCK MODE TO NOT WAIT
END CASE

LET rm_r19.r19_num_tran    = num_tran
LET rm_r19.r19_moneda      = rg_gen.g00_moneda_base   -- ASIGNA LA MONEDA BASE
LET rm_r19.r19_bodega_dest = rm_r19.r19_bodega_ori

INSERT INTO rept019 VALUES (rm_r19.*)
DISPLAY BY NAME rm_r19.r19_num_tran

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
        LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current_2     = vm_row_current
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
RETURN intentar, done

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE j 	SMALLINT
DEFINE rart	RECORD LIKE rept010.*

---- INITIAL VALUES FOR rm_r20 FIELDS ----
LET rm_r20.r20_compania   = vg_codcia
LET rm_r20.r20_localidad  = vg_codloc
LET rm_r20.r20_linea      = linea
LET rm_r20.r20_stock_bd   = 0
LET rm_r20.r20_cant_ent   = 0 
LET rm_r20.r20_cant_dev   = 0
LET rm_r20.r20_descuento  = 0.0
LET rm_r20.r20_val_descto = 0.0
LET rm_r20.r20_val_impto  = 0.0
LET rm_r20.r20_fob        = 0.0
LET rm_r20.r20_ubicacion  = ' '
------------------------------------------
LET rm_r20.r20_num_tran = rm_r19.r19_num_tran
FOR j = 1 TO vm_num_detalles
	CALL fl_lee_item(vg_codcia, rm_aj_exist[j].r20_item)
		RETURNING rart.*
	LET rm_r20.r20_cant_ped   = rm_aj_exist[j].r20_cant_ven
	LET rm_r20.r20_cant_ven   = rm_aj_exist[j].r20_cant_ven
	LET rm_r20.r20_stock_ant  = rm_aj_exist[j].r20_stock_ant 
	LET rm_r20.r20_bodega     = rm_r19.r19_bodega_ori
	LET rm_r20.r20_item       = rm_aj_exist[j].r20_item 
	LET rm_r20.r20_orden      = j
	LET rm_r20.r20_linea      = rart.r10_linea
	LET rm_r20.r20_rotacion   = rart.r10_rotacion 
	LET rm_r20.r20_precio     = rart.r10_precio_mb
	LET rm_r20.r20_costo      = rart.r10_costo_mb
	LET rm_r20.r20_costant_mb = rart.r10_costult_mb
	LET rm_r20.r20_costnue_mb = rart.r10_costo_mb
	LET rm_r20.r20_costant_ma = rart.r10_costult_ma
	LET rm_r20.r20_costnue_ma = rart.r10_costo_ma
	INSERT INTO rept020 VALUES(rm_r20.*)
END FOR 

END FUNCTION




FUNCTION control_actualizacion_existencia()
DEFINE j, k 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT
DEFINE ins_item		SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(100)
DEFINE r_r11		RECORD LIKE rept011.*

-------------------------------------------------------
-- REPITE HASTA QUE PUEDA ACTUALIZAR LA TABLA rept011
-- O HASTA QUE EL USUARIO DECIDA NO VOLVERLO A INTENTAR
-------------------------------------------------------
LET intentar = 1
LET done     = 0
LET j        = 1
WHILE (intentar)
	LET ins_item = 0
	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,
				rm_aj_exist[j].r20_item)
		RETURNING r_r11.*
	IF r_r11.r11_compania IS NULL THEN
		INSERT INTO rept011
     			(r11_compania, r11_bodega, r11_item, 
			 r11_ubicacion, r11_stock_ant, 
			 r11_stock_act, r11_ing_dia,
			 r11_egr_dia)
			VALUES(vg_codcia, rm_r19.r19_bodega_ori,
			       rm_aj_exist[j].r20_item, 'SN', 
			       0, rm_aj_exist[j].r20_cant_ven, 
			       rm_aj_exist[j].r20_cant_ven,0) 
		IF rm_r19.r19_cod_tran = 'A+' THEN
			LET ins_item = 1
		END IF
	END IF
	CASE rm_r19.r19_cod_tran
		WHEN 'A+'
			IF NOT ins_item THEN
				UPDATE rept011 
					SET   r11_stock_ant = r11_stock_act,
					      r11_stock_act = r11_stock_act + 
					      rm_aj_exist[j].r20_cant_ven,
					      r11_ing_dia   = 
						     rm_aj_exist[j].r20_cant_ven
					WHERE r11_compania = vg_codcia
					AND   r11_bodega   =
					      rm_r19.r19_bodega_ori
					AND   r11_item     =
					      rm_aj_exist[j].r20_item 
			END IF
		WHEN 'A-'
			CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,
     					      rm_aj_exist[j].r20_item)
				RETURNING rm_r11.*
			IF rm_r11.r11_stock_act < rm_aj_exist[j].r20_cant_ven
			   AND rm_r19.r19_bodega_ori <> vm_bod_sstock THEN
				LET mensaje = 'Ha ocurrido una disminución en el stoctk del item '|| rm_r20.r20_item CLIPPED ||'. No se puede realizar la transacción.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				ROLLBACK WORK
				LET vm_num_rows    = vm_num_rows - 1
				LET vm_row_current = vm_row_current_2
				LET intentar       = 0
				LET done           = 0
				EXIT WHILE
			END IF
			UPDATE rept011 
				SET   r11_stock_act = r11_stock_act - 
					            rm_aj_exist[j].r20_cant_ven,
				      r11_egr_dia   =
						    rm_aj_exist[j].r20_cant_ven
				WHERE r11_compania  = vg_codcia
				AND   r11_bodega    = rm_r19.r19_bodega_ori
				AND   r11_item      = rm_aj_exist[j].r20_item
	END CASE
	WHENEVER ERROR STOP
	IF status < 0 THEN
		CALL fl_hacer_pregunta('Registro está siendo modificado por otro usuario, desea intentarlo nuevamente','No')
			RETURNING resp
		IF resp = 'No' THEN
			ROLLBACK WORK
			LET vm_num_rows    = vm_num_rows - 1
			LET vm_row_current = vm_row_current_2
			LET intentar       = 0
			LET done           = 0
			EXIT WHILE
		ELSE
			LET j = j - 1
		END IF
	END IF
	LET j = j + 1
	IF j > vm_num_detalles  THEN
		LET intentar = 0
		LET done     = 1
		EXIT WHILE
	END IF
END WHILE
RETURN intentar, done

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE puedehaceraj	SMALLINT
DEFINE r_g05		RECORD LIKE gent005.*

LET int_flag = 0
INPUT BY NAME rm_r19.r19_referencia, rm_r19.r19_vendedor, rm_r19.r19_bodega_ori,
	      linea, tipo_ajuste, rm_r19.r19_cod_subtipo, 
	      rm_r19.r19_tot_costo
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r19_vendedor,    r19_bodega_ori, 
				     r19_referencia,  
				     r19_cod_subtipo)
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
		IF INFIELD(r19_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'A')
			RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
			    LET rm_r19.r19_vendedor = rm_r01.r01_codigo
			    DISPLAY BY NAME rm_r19.r19_vendedor
			    DISPLAY rm_r01.r01_nombres TO nom_vend
			END IF
		END IF
		IF INFIELD(r19_bodega_ori) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'T', 'A', 'T', 'V')
		     RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     IF rm_r02.r02_codigo IS NOT NULL THEN
			    LET rm_r19.r19_bodega_ori = rm_r02.r02_codigo
			    DISPLAY BY NAME rm_r19.r19_bodega_ori
			    DISPLAY rm_r02.r02_nombre TO nom_bod
		     END IF
		END IF
		IF INFIELD(linea) THEN
		     CALL fl_ayuda_lineas_rep(vg_codcia)
		     RETURNING rm_r03.r03_codigo, rm_r03.r03_nombre
		     IF rm_r03.r03_codigo IS NOT NULL THEN
			    LET linea = rm_r03.r03_codigo
			    DISPLAY BY NAME linea
			    DISPLAY rm_r03.r03_nombre TO nom_lin
		     END IF
		END IF
                IF INFIELD(r19_cod_subtipo) THEN
                       	CALL fl_ayuda_subtipo_tran(rm_r19.r19_cod_tran)
		       		RETURNING rm_g22.g22_cod_tran,
				rm_g22.g22_cod_subtipo, rm_g22.g22_nombre
                        IF rm_g22.g22_cod_subtipo IS NOT NULL THEN
				LET rm_r19.r19_cod_subtipo = 
			            rm_g22.g22_cod_subtipo
                              	DISPLAY BY NAME rm_r19.r19_cod_subtipo
				DISPLAY rm_g22.g22_nombre TO nom_subtipo
				IF vg_gui = 0 THEN
				       CALL muestra_codtran(rm_r19.r19_cod_tran)
				END IF
                        END IF
                END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD tipo_ajuste
		CASE tipo_ajuste
			WHEN 'I'
				LET rm_r19.r19_cod_tran = vm_ajuste_mas
			WHEN 'D'
				LET rm_r19.r19_cod_tran = vm_ajuste_menos
		END CASE
		DISPLAY BY NAME rm_r19.r19_cod_tran
		IF vg_gui = 0 THEN
			IF rm_r19.r19_cod_tran IS NOT NULL THEN
		        	CALL muestra_codtran(rm_r19.r19_cod_tran)
			ELSE
				CLEAR tit_cod_tran
			END IF
		END IF
	AFTER FIELD r19_vendedor
		IF rm_r19.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING rm_r01.*
			IF rm_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation')
				NEXT FIELD r19_vendedor
			END IF 
			IF rm_r01.r01_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Vendedor está bloqueado.','exclamation')
				NEXT FIELD r19_vendedor
			END IF
			DISPLAY rm_r01.r01_nombres TO nom_vend
		ELSE
			CLEAR nom_vend
		END IF		 
	AFTER FIELD r19_bodega_ori
		IF rm_r19.r19_bodega_ori IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
				RETURNING rm_r02.*
			IF rm_r02.r02_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF 
			IF rm_r02.r02_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Bodega está bloqueada.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			{
			IF rm_r02.r02_tipo <> 'F' THEN
				CALL fl_mostrar_mensaje('Bodega no es física.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			IF rm_r02.r02_factura <> 'S' THEN
				CALL fl_mostrar_mensaje('Bodega no factura.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			}
			IF rm_r02.r02_localidad <> vg_codloc THEN
				CALL fl_mostrar_mensaje('Bodega no es local.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			DISPLAY rm_r02.r02_nombre TO nom_bod
		ELSE
			CLEAR nom_bod
		END IF
	AFTER FIELD linea
		IF linea IS NOT NULL THEN
                    	CALL fl_lee_linea_rep(vg_codcia, linea)
                        	RETURNING rm_r03.*
			IF rm_r03.r03_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('División no existe.','exclamation')
				NEXT FIELD linea
			END IF
			IF rm_r03.r03_estado = 'B' THEN
				CALL fl_mostrar_mensaje('División está bloqueada.','exclamation')
				NEXT FIELD linea
			END IF		
			DISPLAY rm_r03.r03_nombre TO nom_lin
		ELSE
			CLEAR nom_lin
		END IF
	AFTER FIELD r19_cod_subtipo
		IF rm_r19.r19_cod_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_transaccion(rm_r19.r19_cod_subtipo)
				RETURNING rm_g22.*
			IF rm_g22.g22_cod_subtipo IS NULL THEN
				CALL fl_mostrar_mensaje('Subtipo de Transacción no existe.','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF 
			IF rm_g22.g22_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Subtipo de Transacción está bloqueada.','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			IF rm_g22.g22_cod_tran <> rm_r19.r19_cod_tran THEN
				CALL fl_mostrar_mensaje('El Subtipo de Transacción no pertenece a la Transacción. ','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			DISPLAY rm_g22.g22_nombre TO nom_subtipo
		ELSE
			CLEAR nom_subtipo
		END IF
	AFTER INPUT 
		IF linea IS NULL OR linea = ' ' THEN
			CALL fl_mostrar_mensaje('Debe ingresar la División de los items para realizar el ajuste.','exclamation') 
			NEXT FIELD linea
		END IF
		IF rm_r19.r19_cod_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_transaccion(rm_r19.r19_cod_subtipo)
				RETURNING rm_g22.*
			IF rm_g22.g22_cod_subtipo IS NULL THEN
				CALL fl_mostrar_mensaje('Subtipo de Transacción no existe.','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF 
			IF rm_g22.g22_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Subtipo de Transacción está bloqueada.','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			IF rm_g22.g22_cod_tran <> rm_r19.r19_cod_tran THEN
				CALL fl_mostrar_mensaje('El Subtipo de Transacción no pertenece a la Transacción.','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			DISPLAY rm_g22.g22_nombre TO nom_subtipo
		END IF
		IF rm_r19.r19_bodega_ori = vm_bod_tal AND vg_usuario <> "FOBOS"
		THEN
			CALL fl_mostrar_mensaje('No puede poner la bodega logica del taller.','exclamation')
			NEXT FIELD r19_bodega_ori
		END IF
		IF rm_r19.r19_bodega_ori = vm_bod_sstock THEN
			CALL fl_mostrar_mensaje('La bodega asignada para ventas sin stock no puede ser utilizada.','exclamation')
			CALL fl_lee_usuario(rm_r01.r01_user_owner)
				RETURNING r_g05.*
			LET puedehaceraj = 0
			IF r_g05.g05_usuario IS NOT NULL THEN
				IF r_g05.g05_grupo = 'SI' THEN
					LET puedehaceraj = 1
				END IF
			END IF
			IF NOT puedehaceraj THEN
				NEXT FIELD r19_bodega_ori
			END IF
			CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
			IF r_g05.g05_usuario IS NOT NULL THEN
				IF r_g05.g05_grupo <> 'SI' THEN
					CALL fl_mostrar_mensaje('Usted no es un usuario de sistemas, no puede usar este código de vendedor.', 'exclamation')
					NEXT FIELD r19_vendedor
				END IF
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j,k,ind	SMALLINT
DEFINE resp		CHAR(6)
DEFINE max_row		SMALLINT
DEFINE stock		LIKE rept011.r11_stock_act

CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr 
	INITIALIZE rm_aj_exist[i].* TO NULL
	CLEAR rm_aj_exist[i].*
END FOR
LET i = 1
LET j = 1
DISPLAY BY NAME rm_r19.r19_tot_costo

CALL set_count(i)
INPUT ARRAY rm_aj_exist WITHOUT DEFAULTS FROM rm_aj_exist.* 
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN 0
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r20_item) THEN
               		CALL fl_ayuda_maestro_items_stock(vg_codcia, linea, 
				rm_r19.r19_bodega_ori)
                     		RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre,
					  rm_r10.r10_linea,rm_r10.r10_precio_mb,
					  rm_r11.r11_bodega, stock         
                     	IF rm_r10.r10_codigo IS NOT NULL THEN
				LET rm_aj_exist[i].r20_item = rm_r10.r10_codigo
                        	DISPLAY rm_r10.r10_codigo TO
					rm_aj_exist[j].r20_item
                        	DISPLAY rm_r10.r10_nombre TO 
					rm_aj_exist[j].r10_nombre
                     	END IF
                END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		IF rm_aj_exist[i].r20_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_aj_exist[i].r20_item)
				RETURNING rm_r10.*
			CALL muestra_etiquetas_det(i, max_row, i)
		ELSE
			CLEAR nom_item, descrip_1, descrip_2, descrip_3,
				descrip_4, nom_marca
		END IF
	AFTER FIELD r20_cant_ven
	    	IF rm_aj_exist[i].r20_cant_ven IS NOT NULL 
		AND rm_aj_exist[i].r20_item IS NOT NULL 
		THEN
		----VALIDO CUANDO SEA DISMINUCION DE EXISTENCIA----
			IF rm_aj_exist[i].r20_cant_ven > rm_r11.r11_stock_act 
			AND rm_r19.r19_cod_tran = 'A-'
			THEN
				CALL fl_mostrar_mensaje('La existencia actual es menor a la ingresada para su disminución.','exclamation')
				IF rm_r19.r19_bodega_ori <> vm_bod_sstock THEN
					NEXT FIELD r20_cant_ven
				END IF 
			END IF 
			CALL calcular_total()
			DISPLAY rm_aj_exist[i].total TO
				rm_aj_exist[j].total
		END IF 
		IF rm_aj_exist[i].r20_cant_ven IS NULL AND 
		   rm_aj_exist[i].r20_item IS NOT NULL 
		   THEN
			NEXT FIELD r20_cant_ven
		END IF
	AFTER FIELD r20_item
	    	IF rm_aj_exist[i].r20_item IS NOT NULL THEN
     			CALL fl_lee_item(vg_codcia, rm_aj_exist[i].r20_item)
				RETURNING rm_r10.*
                	IF rm_r10.r10_codigo IS NULL THEN
                       		--CALL fgl_winmessage(vg_producto,'El item no existe.','exclamation')
				CALL fl_mostrar_mensaje('El item no existe.','exclamation')
                       		NEXT FIELD r20_item
                	END IF
                	IF rm_r10.r10_estado = 'B' THEN
                       		--CALL fgl_winmessage(vg_producto,'El item está en estado bloqueado.','exclamation')
				CALL fl_mostrar_mensaje('El item está en estado bloqueado.','exclamation')
                       		NEXT FIELD r20_item
                	END IF
                	IF rm_r10.r10_linea <> linea THEN
				CALL fl_mostrar_mensaje('El item no pertenece a la División ingresada.','exclamation')
                       		NEXT FIELD r20_item
                	END IF
			IF rm_r10.r10_costo_mb <= 0.01 AND
			   NOT fl_item_tiene_movimientos(rm_r10.r10_compania,
							rm_r10.r10_codigo)
			THEN
				CALL fl_mostrar_mensaje('Debe estar configurado correctamente el costo del item y NO con costo menor igual a 0.01.', 'exclamation')
                       		NEXT FIELD r20_item
                	END IF
			CALL muestra_etiquetas_det(i, max_row, i)
			FOR k = 1 TO arr_count()
				IF  rm_aj_exist[i].r20_item = 
				    rm_aj_exist[k].r20_item
				AND i <> k
				THEN
					--CALL fgl_winmessage(vg_producto,'No puede ingresar items repetidos.','exclamation')
					CALL fl_mostrar_mensaje('No puede ingresar items repetidos.','exclamation')
					NEXT FIELD r20_item
               			END IF
			END FOR
			---- PARA SACAR EL STOCK DE LA BODEGA ----
			CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,
     					      rm_aj_exist[i].r20_item)
				RETURNING rm_r11.*
			IF rm_r11.r11_stock_act IS NULL THEN
				LET rm_r11.r11_stock_act = 0
			END IF
			---------------------------------------------
		----DISPLAYO LOS PRIMEROS CAMPOS DE LA FILA SI TODO OK.----
			LET rm_aj_exist[i].r20_stock_ant = rm_r11.r11_stock_act
			LET rm_aj_exist[i].r10_nombre    = rm_r10.r10_nombre
			LET rm_aj_exist[i].r10_costo_mb  = rm_r10.r10_costo_mb
			DISPLAY rm_r11.r11_stock_act TO
				rm_aj_exist[j].r20_stock_ant
			DISPLAY rm_aj_exist[i].r10_nombre TO
				rm_aj_exist[j].r10_nombre
			DISPLAY rm_aj_exist[i].r10_costo_mb TO
				rm_aj_exist[j].r10_costo_mb
			---------------------------------------------------
		 	----VALIDO CUANDO SEA DISMINUCION DE EXISTENCIA----
			IF rm_aj_exist[i].r20_cant_ven > rm_r11.r11_stock_act 
			AND rm_r19.r19_cod_tran = 'A-'
			THEN
				CALL fl_mostrar_mensaje('La existencia actual es menor a la ingresada para su disminución.','exclamation')
				IF rm_r19.r19_bodega_ori <> vm_bod_sstock THEN
					NEXT FIELD r20_cant_ven
				END IF 
			END IF 
			----------------------------------------------------
		----DISPLAYO LOS DEMAS CAMPOS DE LA FILA SI TODO OK.----
			LET rm_aj_exist[i].total = rm_r10.r10_costo_mb *
						rm_aj_exist[i].r20_cant_ven
			LET rm_r19.r19_tot_costo = vm_total 
			DISPLAY rm_aj_exist[i].total TO
				rm_aj_exist[j].total
			CALL calcular_total()
			------------------------------------------------------
		ELSE
			IF rm_aj_exist[i].r10_nombre IS NOT NULL
				AND rm_aj_exist[i].r20_item IS NULL
			THEN
				NEXT FIELD r20_item
			END IF 
		END IF

	AFTER INPUT
		IF arr_count() = 0 THEN
			NEXT FIELD r20_cant_ven
		END IF
		LET ind = arr_count()
		LET vm_ind_arr = arr_count()
END INPUT

RETURN ind

END FUNCTION



FUNCTION calcular_total()
DEFINE k 	SMALLINT

LET vm_total = 0
FOR k = 1 TO arr_count()
	LET rm_aj_exist[k].total = rm_aj_exist[k].r10_costo_mb *						   rm_aj_exist[k].r20_cant_ven
	LET vm_total = vm_total + rm_aj_exist[k].total
	LET rm_r19.r19_tot_costo = vm_total 
END FOR
DISPLAY BY NAME rm_r19.r19_tot_costo

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(800)
DEFINE r_r19		RECORD LIKE rept019.*

CLEAR FORM
CALL control_DISPLAY_botones()
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON r19_cod_tran, r19_num_tran, r19_fecing, r19_referencia,
		     r19_vendedor, r19_bodega_ori
		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r19_num_tran) THEN
				LET r_r19.r19_cod_tran= get_fldbuf(r19_cod_tran)
				IF r_r19.r19_cod_tran = 'A-' OR
				   r_r19.r19_cod_tran = 'A+' THEN
				CALL fl_ayuda_transaccion_rep(vg_codcia,
						vg_codloc, r_r19.r19_cod_tran)
					RETURNING r_r19.r19_cod_tran,
						  r_r19.r19_num_tran,
						  r_r19.r19_nomcli
				LET int_flag = 0
				IF r_r19.r19_cod_tran IS NOT NULL THEN
					LET rm_r19.r19_cod_tran =
							r_r19.r19_cod_tran
					LET rm_r19.r19_num_tran =
							r_r19.r19_num_tran
					DISPLAY BY NAME rm_r19.r19_cod_tran,
							rm_r19.r19_num_tran
				END IF
				END IF
			END IF
			IF INFIELD(r19_vendedor) THEN
				CALL fl_ayuda_vendedores(vg_codcia, 'A', 'A')
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
				IF rm_r01.r01_codigo IS NOT NULL THEN
				    LET rm_r19.r19_vendedor = rm_r01.r01_codigo
				    DISPLAY BY NAME rm_r19.r19_vendedor
				    DISPLAY rm_r01.r01_nombres TO nom_vend
				END IF
			END IF
			IF INFIELD(r19_bodega_ori) THEN
			     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'T', 'A', 'T', 'V')
			     RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
			     IF rm_r02.r02_codigo IS NOT NULL THEN
				    LET rm_r19.r19_bodega_ori= rm_r02.r02_codigo
				    DISPLAY BY NAME rm_r19.r19_bodega_ori
				    DISPLAY rm_r02.r02_nombre TO nom_bod
			     END IF
			END IF
			IF INFIELD(linea) THEN
			     CALL fl_ayuda_lineas_rep(vg_codcia)
			     RETURNING rm_r03.r03_codigo, rm_r03.r03_nombre
			     IF linea IS NOT NULL THEN
				    LET linea = rm_r03.r03_codigo
				    DISPLAY BY NAME linea
				    DISPLAY rm_r03.r03_nombre TO nom_lin
			     END IF
			END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD r19_cod_tran
			LET rm_r19.r19_cod_tran = get_fldbuf(r19_cod_tran)
			IF rm_r19.r19_cod_tran IS NOT NULL THEN
				IF rm_r19.r19_cod_tran <> vm_ajuste_mas
				   AND rm_r19.r19_cod_tran <> 
					vm_ajuste_menos
					THEN
					--CALL fgl_winmessage(vg_producto,'Debe ingresar el código (A+) Ajuste Incremento, (A-) Ajuste Decremento.','exclamation')
					CALL fl_mostrar_mensaje('Debe ingresar el código (A+) Ajuste Incremento, (A-) Ajuste Decremento.','exclamation')
					NEXT FIELD r19_cod_tran
				END IF
			END IF
			IF vg_gui = 0 THEN
				IF rm_r19.r19_cod_tran IS NOT NULL THEN
		        	       CALL muestra_codtran(rm_r19.r19_cod_tran)
				ELSE
					CLEAR tit_cod_tran
				END IF
			END IF
		LET int_flag = 0
	END CONSTRUCT
ELSE
	LET expr_sql = 'r19_cod_tran = "', vg_cod_tran, '"', 
		       ' AND ', 'r19_num_tran = ', vg_num_tran	
END IF

IF INT_FLAG THEN
	CLEAR FORM
	CALL control_DISPLAY_botones()
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM rept019 ', 
		' WHERE r19_compania   = ', vg_codcia,
		'   AND r19_localidad  = ', vg_codloc,
		'   AND r19_cod_tran  IN ("', vm_ajuste_mas, '",', 
					'"', vm_ajuste_menos, '")',
		'   AND ', expr_sql CLIPPED,
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
	CALL control_DISPLAY_botones()
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

CLEAR FORM
CALL control_DISPLAY_botones()
IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r19.* FROM rept019 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
CASE rm_r19.r19_cod_tran 
	WHEN 'A+'
		DISPLAY 'I' TO tipo_ajuste 
	WHEN 'A-'
		DISPLAY 'D' TO tipo_ajuste 
END CASE
IF vg_gui = 0 THEN
	CALL muestra_codtran(rm_r19.r19_cod_tran)
END IF
	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r19.r19_num_tran,  rm_r19.r19_cod_tran, 
		rm_r19.r19_cod_subtipo,
		rm_r19.r19_vendedor,  rm_r19.r19_bodega_ori,
		rm_r19.r19_tot_costo, rm_r19.r19_referencia, 
		rm_r19.r19_fecing
		
CALL muestra_detalle()
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(400)

CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr 
	INITIALIZE rm_aj_exist[i].* TO NULL
	CLEAR rm_aj_exist[i].*
END FOR

LET query = 'SELECT r20_cant_ven, r20_stock_ant, r20_item, r10_nombre, ',
		' r20_costo, r20_costo * r20_cant_ven, r20_linea ',
		'  FROM rept020, rept010 ',
            	'WHERE r20_compania  =  ', vg_codcia, 
	    	'  AND r20_localidad =  ', vg_codloc,
	    	'  AND r20_cod_tran  = "', rm_r19.r19_cod_tran,'"',
            	'  AND r20_num_tran  =  ', rm_r19.r19_num_tran,
            	'  AND r20_compania  =  r10_compania',
            	'  AND r20_item      =  r10_codigo'

PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO rm_aj_exist[i].*, linea 

	LET i = i + 1
        IF i > vm_elementos THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET i = 0
	CLEAR FORM
	CALL control_DISPLAY_botones()
	RETURN
END IF 
LET vm_ind_arr = i
DISPLAY BY NAME linea
IF vm_ind_arr < vm_size_arr THEN
	LET vm_size_arr = vm_ind_arr
END IF
FOR i = 1 TO vm_size_arr   
	DISPLAY rm_aj_exist[i].* TO rm_aj_exist[i].*
END FOR
CALL muestra_etiquetas_det(0, vm_ind_arr, 1)

END FUNCTION



FUNCTION muestra_contadores()

IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 
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

IF rm_r19.r19_cod_subtipo IS NOT NULL THEN
	CALL fl_lee_subtipo_transaccion(rm_r19.r19_cod_subtipo)
		RETURNING rm_g22.*
	DISPLAY rm_g22.g22_nombre TO nom_subtipo
END IF
CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
	RETURNING rm_r02.*
DISPLAY rm_r02.r02_nombre TO nom_bod
CALL fl_lee_linea_rep(vg_codcia, linea)
      	RETURNING rm_r03.*
DISPLAY rm_r03.r03_nombre TO nom_lin
CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
	RETURNING rm_r01.*
DISPLAY rm_r01.r01_nombres TO nom_vend

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
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp411 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran,
	rm_r19.r19_num_tran
RUN comando	

END FUNCTION



FUNCTION retorna_tam_arr()

LET vm_size_arr = fgl_scr_size('rm_aj_exist')
{
IF vg_gui = 0 THEN
	LET vm_size_arr = 5
END IF
}

END FUNCTION



FUNCTION muestra_codtran(codtran)
DEFINE codtran		CHAR(2)

CASE codtran
	WHEN 'A+'
		DISPLAY 'INCREMENTO' TO tit_cod_tran
	WHEN 'A-'
		DISPLAY 'DECREMENTO' TO tit_cod_tran
	OTHERWISE
		CLEAR r19_cod_tran, tit_cod_tran
END CASE

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

CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_r03.*
CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r03.r03_nombre     TO descrip_1
DISPLAY r_r70.r70_desc_sub   TO descrip_2
DISPLAY r_r71.r71_desc_grupo TO descrip_3
DISPLAY r_r72.r72_desc_clase TO descrip_4
DISPLAY r_r10.r10_marca      TO nom_marca

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION muestra_etiquetas_det(i, ind1, ind2)
DEFINE i, ind1, ind2	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, ind1)
CALL fl_lee_item(vg_codcia, rm_aj_exist[ind2].r20_item) RETURNING r_r10.*  
CALL muestra_descripciones(rm_aj_exist[ind2].r20_item, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
DISPLAY r_r10.r10_nombre TO nom_item 

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

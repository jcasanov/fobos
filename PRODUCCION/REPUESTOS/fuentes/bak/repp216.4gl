------------------------------------------------------------------------------
-- Titulo           : repp216.4gl - Ingreso Tranferencias
-- Elaboracion      : 07-nov-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp216 base modulo compania localidad
-- Ultima Correccion: 07-nov-2001
-- Motivo Correccion: 1
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows		ARRAY[1000] OF INTEGER 	-- ARREGLO ROWID DE FILAS LEIDAS
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
DEFINE rm_g05		 	RECORD LIKE gent005.*
DEFINE rm_vend		 	RECORD LIKE rept001.*

DEFINE r_detalle ARRAY[200] OF RECORD
	r20_cant_ped		LIKE rept020.r20_cant_ped,
	r20_stock_ant		LIKE rept020.r20_stock_ant,
	r20_item		LIKE rept020.r20_item,
	r20_costo		LIKE rept020.r20_costo,
	subtotal_item		LIKE rept019.r19_tot_costo
	END RECORD
	--- PARA ALMACENAR LOS OTROS VALORES DEL DETALLE ----
DEFINE r_detalle_2 ARRAY[200] OF RECORD
	r20_fob			LIKE rept020.r20_fob,
	r20_precio		LIKE rept020.r20_precio,
	r20_costo		LIKE rept020.r20_costo,
	r20_costant_mb		LIKE rept020.r20_costant_mb,
	r20_costnue_mb		LIKE rept020.r20_costnue_mb,
	r20_costant_ma		LIKE rept020.r20_costant_ma,
	r20_costnue_ma		LIKE rept020.r20_costnue_ma,
	r20_stock_bd		LIKE rept020.r20_stock_bd,
	r20_linea		LIKE rept020.r20_linea,
	r20_rotacion		LIKE rept020.r20_rotacion
	END RECORD
	-----------------------------------------------------
DEFINE r_serie		ARRAY[200,1000] OF RECORD
				r76_serie	LIKE rept076.r76_serie,
				r76_fecing	LIKE rept076.r76_fecing,
				check		CHAR(1)
			END RECORD
DEFINE r_serie_aux	ARRAY[1000] OF RECORD
				r76_serie	LIKE rept076.r76_serie,
				r76_fecing	LIKE rept076.r76_fecing,
				check		CHAR(1)
			END RECORD
	-----------------------------------------------------
DEFINE vm_ind_arr	SMALLINT
DEFINE vm_size_arr	SMALLINT
DEFINE vm_total    	DECIMAL(12,2)
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vg_cod_tran	LIKE gent021.g21_cod_tran
DEFINE vg_num_tran	LIKE rept019.r19_num_tran
DEFINE vm_num_ser	ARRAY[1000] OF SMALLINT
DEFINE vm_bod_tal	LIKE rept002.r02_codigo



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp216.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_cod_tran = arg_val(5)
LET vg_num_tran = arg_val(6)
LET vg_proceso  = 'repp216'
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
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
INITIALIZE vm_bod_tal TO NULL
SELECT r02_codigo INTO vm_bod_tal FROM rept002
	WHERE r02_compania  = vg_codcia	 
	  AND r02_localidad = vg_codloc
          AND r02_estado    = "A"                                      
	  AND r02_area      = "T"                                       
	  AND r02_factura   = "S"                                       
	  AND r02_tipo      = "L"                                       

CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_vd 
INITIALIZE rm_vend.* TO NULL
FETCH qu_vd INTO rm_vend.*
IF status = NOTFOUND THEN
	IF rm_g05.g05_tipo = 'UF' THEN
		CALL fl_mostrar_mensaje('Usted no está configurado como bodeguero.','stop')
		RETURN                                                                  
	END IF  
END IF		
CREATE TEMP TABLE tmp_serie(
		te_item		CHAR(2),
		te_serie	CHAR(20),
		te_fecha	DATETIME YEAR TO SECOND,
		te_check	CHAR(1)
	)
LET vm_max_rows     = 1000
LET vm_cod_tran     = 'TR'
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
OPEN WINDOW w_216 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_216 FROM '../forms/repf216_1'
ELSE
	OPEN FORM f_216 FROM '../forms/repf216_1c'
END IF
DISPLAY FORM f_216
CALL control_DISPLAY_botones()

CALL retorna_tam_arr()
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Imprimir'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Ver Detalle'
                	HIDE OPTION 'Imprimir'
			CALL control_consulta()
			CALL control_ver_detalle()
			EXIT PROGRAM
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



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'Cant'		TO tit_col1
--#DISPLAY 'Stock'		TO tit_col2
--#DISPLAY 'Item'		TO tit_col3
--#DISPLAY 'Costo Unit.'	TO tit_col4
--#DISPLAY 'Subtotal'		TO tit_col5

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE i,j 	SMALLINT
DEFINE r_r76	RECORD LIKE rept076.*

CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
			RETURNING rm_r10.*
		CALL muestra_descripciones(r_detalle[i].r20_item,
				rm_r10.r10_linea, rm_r10.r10_sub_linea,
				rm_r10.r10_cod_grupo, 
				rm_r10.r10_cod_clase)
		DISPLAY rm_r10.r10_nombre TO nom_item
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		IF vg_gui = 0 THEN
			LET i = arr_curr()
			INITIALIZE r_r76.* TO NULL
			DECLARE q_ser2 CURSOR FOR
				SELECT UNIQUE * FROM rept076
				WHERE r76_compania  = vg_codcia
				  AND r76_localidad = vg_codloc 
				  AND r76_bodega    = rm_r19.r19_bodega_ori
				  AND r76_item      = r_detalle[i].r20_item
			OPEN q_ser2
			FETCH q_ser2 INTO r_r76.*
		END IF
		IF r_r76.r76_serie IS NOT NULL THEN
			LET i = arr_curr()
				CALL fl_ayuda_serie_rep(vg_codcia, vg_codloc,
					rm_r19.r19_bodega_ori,
					r_detalle[i].r20_item, 'T')
				RETURNING r_r76.r76_serie,
					  r_r76.r76_fecing
				LET int_flag = 0
		END IF
		IF vg_gui = 0 THEN
			CLOSE q_ser2
			FREE q_ser2
		END IF
	ON KEY(F6)
        	CALL imprimir()
		LET int_flag = 0
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel("ACCEPT", "")
		--#CALL dialog.keysetlabel("F1", "")
		--#CALL dialog.keysetlabel("F6", "Imprimir")
		--#CALL dialog.keysetlabel("CONTROL-W", "")
	--#BEFORE ROW 
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
			--#RETURNING rm_r10.*
		--#DISPLAY rm_r10.r10_nombre TO nom_item
		--#CALL muestra_descripciones(r_detalle[i].r20_item,
				--#rm_r10.r10_linea, rm_r10.r10_sub_linea,
				--#rm_r10.r10_cod_grupo, 
				--#rm_r10.r10_cod_clase)
		--#INITIALIZE r_r76.* TO NULL
		--#DECLARE q_ser CURSOR FOR
			--#SELECT UNIQUE * FROM rept076
				--#WHERE r76_compania  = vg_codcia
				  --#AND r76_localidad = vg_codloc 
				  --#AND r76_bodega    = rm_r19.r19_bodega_ori
				  --#AND r76_item      = r_detalle[i].r20_item
		--#OPEN q_ser
		--#FETCH q_ser INTO r_r76.*
		--#IF r_r76.r76_serie IS NOT NULL THEN
			--#CALL dialog.keysetlabel('F5', 'Series')
		--#ELSE
			--#CALL dialog.keysetlabel('F5', '')
		--#END IF
		--#CLOSE q_ser
		--#FREE q_ser
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_ingreso()
DEFINE i, j, k 		SMALLINT
DEFINE done 		SMALLINT
DEFINE r_r76		ARRAY[1000] OF RECORD LIKE rept076.*

CLEAR FORM
CALL control_DISPLAY_botones()
INITIALIZE rm_r19.*, rm_r20.* TO NULL

-- INITIAL VALUES FOR rm_r19 FIELDS
LET rm_r19.r19_fecing     = CURRENT
LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
LET rm_r19.r19_cod_tran   = vm_cod_tran
LET rm_r19.r19_vendedor   = rm_vend.r01_codigo

DISPLAY BY NAME rm_r19.r19_usuario, rm_r19.r19_fecing, 
		rm_r19.r19_cod_tran, rm_r19.r19_fecing
DISPLAY rm_vend.r01_nombres TO nom_vendedor
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
LET rm_r19.r19_tot_costo = 0 
LET rm_r19.r19_tot_neto  = 0 
LET INT_FLAG = 0
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
			CALL control_DISPLAY_botones()
		END IF
		RETURN
	END IF

	CALL control_ingreso_detalle()

	CALL control_actualizacion_existencia()

{--
--
-- PROCESO PARA ACTAULIZAR LAS TRANSFERENCIA DE ITEM SERIADOS
	IF vm_num_ser[i] > 0 THEN
		FOR i = 1 TO vm_num_detalles
			WHENEVER ERROR CONTINUE
			DECLARE q_serup CURSOR FOR
				SELECT * FROM rept076
					WHERE r76_compania  = vg_codcia
					  AND r76_localidad = vg_codloc
					  AND r76_bodega    =
							rm_r19.r19_bodega_ori
					  AND r76_iten      =
							r_detalle[i].r20_item
				FOR UPDATE
			OPEN q_serup
			FETCH q_serup INTO r_r76[1].*
			IF STATUS < 0 THEN
				ROLLBACK WORK
				CALL fl_mensaje_bloqueo_otro_usuario()
				WHENEVER ERROR STOP
				RETURN
			END IF
			LET k = 1
			FOREACH q_serup INTO r_r76[k].*
				LET k = k + 1
				IF k > vm_num_ser[i] THEN
					ROLLBACK WORK
					CALL fl_mensaje_arreglo_incompleto()
					WHENEVER ERROR STOP
					EXIT PROGRAM
				END IF
			END FOREACH
			LET k = k - 1
			WHENEVER ERROR STOP
			OPEN q_serup
			DELETE FROM rept076 WHERE CURRENT OF q_serup
			FOR j = 1 TO k 
				INSERT INTO rept076
					VALUES (r_r76[j].r76_compania,
						r_r76[j].r76_localidad,
						rm_r19.r19_bodega_dest,
						r_detalle[i].r20_item,
						r_serie[i,j].r76_serie,
						r_r76[j].r76_estado,
						r_r76[j].r76_usuario,
						r_r76[j].r76_fecing)
				INSERT INTO rept079
					VALUES (r_r76[j].r76_compania,
						r_r76[j].r76_localidad,
						vm_cod_tran,
						rm_r19.r19_num_tran,
						r_detalle[i].r20_item,
						r_serie[i,j].r76_serie)
			END FOR
			CLOSE q_serup
			FREE q_serup
		END FOR
	END IF
--
--
--}

COMMIT WORK
CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc, 
	 	rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
CALL muestra_contadores()
CALL enviar_transferencia_otra_loc()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_ingreso_cabecera()
DEFINE num_tran         LIKE rept019.r19_num_tran
DEFINE done 		SMALLINT

LET done = 0
  -- ATRAPO EL NUMERO DE LA TRANSACCION QUE LE CORRESPONDA AL REGISTRO --


CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
	                             'AA',vm_cod_tran)
	RETURNING num_tran

CASE num_tran 
	WHEN 0
			ROLLBACK WORK	
			--CALL fgl_winmessage(vg_producto,'No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
			CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
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

LET rm_r19.r19_cont_cred  = 'C'
LET rm_r19.r19_nomcli     = ' '
LET rm_r19.r19_dircli     = ' '
LET rm_r19.r19_cedruc     = ' '
LET rm_r19.r19_descuento  = 0.0
LET rm_r19.r19_porc_impto = 0.0
LET rm_r19.r19_moneda     = rg_gen.g00_moneda_base
LET rm_r19.r19_precision  = rg_gen.g00_decimal_mb
LET rm_r19.r19_paridad    = 1
LET rm_r19.r19_tot_bruto  = 0.0
LET rm_r19.r19_tot_dscto  = 0.0
LET rm_r19.r19_flete      = 0.0
LET rm_r19.r19_num_tran   = num_tran
LET rm_r19.r19_tot_neto   = rm_r19.r19_tot_costo

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
DEFINE j 	SMALLINT

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
LET rm_r20.r20_ubicacion  = 'SN'
------------------------------------------
LET rm_r20.r20_num_tran = rm_r19.r19_num_tran
FOR j = 1 TO vm_num_detalles
	LET rm_r20.r20_cant_ped   = r_detalle[j].r20_cant_ped
	LET rm_r20.r20_cant_ven   = r_detalle[j].r20_cant_ped
	LET rm_r20.r20_stock_ant  = r_detalle[j].r20_stock_ant 

	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_dest,
 			      r_detalle[j].r20_item)
		RETURNING rm_r11.*
	IF rm_r11.r11_stock_act IS NULL THEN
		LET rm_r11.r11_stock_act = 0
	END IF

	LET rm_r20.r20_stock_bd   = rm_r11.r11_stock_act 
	LET rm_r20.r20_bodega     = rm_r19.r19_bodega_ori
	LET rm_r20.r20_item       = r_detalle[j].r20_item 
	LET rm_r20.r20_costo      = r_detalle[j].r20_costo 
	LET rm_r20.r20_orden      = j
	LET rm_r20.r20_fob        = r_detalle_2[j].r20_fob 
	LET rm_r20.r20_linea      = r_detalle_2[j].r20_linea 
	LET rm_r20.r20_rotacion   = r_detalle_2[j].r20_rotacion 
	LET rm_r20.r20_precio     = r_detalle_2[j].r20_precio 
	LET rm_r20.r20_costant_mb = r_detalle_2[j].r20_costant_mb
	LET rm_r20.r20_costnue_mb = r_detalle_2[j].r20_costnue_mb
	LET rm_r20.r20_costant_ma = r_detalle_2[j].r20_costant_ma
	LET rm_r20.r20_costnue_ma = r_detalle_2[j].r20_costnue_ma
	INSERT INTO rept020 VALUES(rm_r20.*)
END FOR 

END FUNCTION



FUNCTION control_actualizacion_existencia()
DEFINE j 		SMALLINT
DEFINE stock_act	LIKE rept011.r11_stock_act
DEFINE ing_dia		LIKE rept011.r11_ing_dia

SET LOCK MODE TO WAIT

LET j = 1
FOR j = 1 TO vm_num_detalles
	
	IF localidad_bodega(rm_r19.r19_bodega_ori) = vg_codloc THEN
		UPDATE rept011 
			SET   r11_stock_ant = r11_stock_act,
			      r11_stock_act = r11_stock_act -
						r_detalle[j].r20_cant_ped,
			      r11_egr_dia   = r_detalle[j].r20_cant_ped
			WHERE r11_compania  = vg_codcia
			AND   r11_bodega    = rm_r19.r19_bodega_ori
			AND   r11_item      = r_detalle[j].r20_item 
	END IF
			
	CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_dest, 
			      r_detalle[j].r20_item)
		RETURNING rm_r11.*
	IF rm_r11.r11_stock_act IS NULL THEN
		LET stock_act = 0
		LET ing_dia   = 0
		IF localidad_bodega(rm_r19.r19_bodega_dest) = vg_codloc THEN
			LET stock_act = r_detalle[j].r20_cant_ped
			LET ing_dia   = r_detalle[j].r20_cant_ped
		END IF
		INSERT INTO rept011
      			(r11_compania, r11_bodega, r11_item, 
		 	r11_ubicacion, r11_stock_ant, 
		 	r11_stock_act, r11_ing_dia,
		 	r11_egr_dia)
		VALUES(vg_codcia, rm_r19.r19_bodega_dest,
		       r_detalle[j].r20_item, 'SN', 
		       0, stock_act, ing_dia, 0) 
	ELSE
		IF localidad_bodega(rm_r19.r19_bodega_dest) = vg_codloc THEN
			UPDATE rept011 
				SET   r11_stock_ant = r11_stock_act,
		      		      r11_stock_act = r11_stock_act + 
						      r_detalle[j].r20_cant_ped,
		      		      r11_ing_dia   = r_detalle[j].r20_cant_ped
				WHERE r11_compania  = vg_codcia
				AND   r11_bodega    = rm_r19.r19_bodega_dest
				AND   r11_item      = r_detalle[j].r20_item 
		END IF
	END IF

END FOR

SET LOCK MODE TO NOT WAIT

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE local_ori	LIKE rept002.r02_localidad
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE r_ori, r_des	RECORD LIKE rept002.*
DEFINE r1_g02, r2_g02	RECORD LIKE gent002.*
DEFINE sin_stock	LIKE rept002.r02_tipo

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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_vendedor) AND (rm_g05.g05_tipo <> 'UF' OR 
			rm_vend.r01_tipo = 'J') THEN
			CALL fl_ayuda_vendedores(vg_codcia)
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
			    LET rm_r19.r19_vendedor = rm_r01.r01_codigo
			    DISPLAY BY NAME rm_r19.r19_vendedor
			    DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r19_bodega_ori) THEN
		     	CALL fl_ayuda_bodegas_rep(vg_codcia,'T')
		     		RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     	IF rm_r02.r02_codigo IS NOT NULL THEN
				LET rm_r19.r19_bodega_ori = rm_r02.r02_codigo
				DISPLAY BY NAME rm_r19.r19_bodega_ori
			    	DISPLAY rm_r02.r02_nombre TO nom_bod_ori
		     END IF
		END IF
		IF INFIELD(r19_bodega_dest) THEN
		     	CALL fl_ayuda_bodegas_rep(vg_codcia,'T')
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
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r19_vendedor                      
		IF rm_vend.r01_tipo <> 'J' THEN
			LET rm_r19.r19_vendedor = rm_vend.r01_codigo 
			DISPLAY BY NAME rm_r19.r19_vendedor	
		END IF		
		IF rm_r19.r19_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
				RETURNING rm_r01.*       
			IF rm_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Bodeguero no existe.','exclamation') 
				CLEAR nom_vendedor
				NEXT FIELD r19_vendedor
			END IF                        
			IF rm_r01.r01_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Bodeguero está bloqueado.','exclamation')      
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
			LET r_ori.* = rm_r02.*
			IF rm_r02.r02_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF 
			IF rm_r02.r02_estado = 'B' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega está bloqueada.','exclamation')
				CALL fl_mostrar_mensaje('Bodega está bloqueada.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			{
			IF rm_r02.r02_tipo <> 'F' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no es física.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no es física.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			IF rm_r02.r02_factura <> 'S' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no factura.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no factura.','exclamation')
				NEXT FIELD r19_bodega_ori
			END IF
			}
			IF rm_r19.r19_bodega_ori = rm_r19.r19_bodega_dest THEN
				--CALL fgl_winmessage(vg_producto,'La bodega origen no puede ser la misma que la bodega destino.','exclamation')
				CALL fl_mostrar_mensaje('La bodega origen no puede ser la misma que la bodega destino.','exclamation')
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
			LET r_des.* = rm_r02.*
			IF rm_r02.r02_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				NEXT FIELD r19_bodega_dest
			END IF 
			IF rm_r02.r02_estado = 'B' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega está bloqueada.','exclamation')
				CALL fl_mostrar_mensaje('Bodega está bloqueada.','exclamation')
				NEXT FIELD r19_bodega_dest
			END IF
			{
			IF rm_r02.r02_tipo <> 'F' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no es física.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no es física.','exclamation')
				NEXT FIELD r19_bodega_dest
			END IF
			IF rm_r02.r02_factura <> 'S' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no factura.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no factura.','exclamation')
				NEXT FIELD r19_bodega_dest
			END IF
			}
			IF rm_r19.r19_bodega_ori = rm_r19.r19_bodega_dest THEN
				--CALL fgl_winmessage(vg_producto,'La bodega origen no puede ser la misma que la bodega destino.','exclamation')
				CALL fl_mostrar_mensaje('La bodega origen no puede ser la misma que la bodega destino.','exclamation')
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
				--CALL fgl_winmessage(vg_producto,'Subtipo de Transacción no existe.','exclamation')
				CALL fl_mostrar_mensaje('Subtipo de Transacción no existe.','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF 
			IF rm_g22.g22_estado = 'B' THEN
				--CALL fgl_winmessage(vg_producto,'Subtipo de Transacción está bloqueada.','exclamation')
				CALL fl_mostrar_mensaje('Subtipo de Transacción está bloqueada.','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			IF rm_g22.g22_cod_tran <> rm_r19.r19_cod_tran THEN
				--CALL fgl_winmessage(vg_producto,'El Subtipo de Transacción no pertenece a la Transacción.','exclamation')
				CALL fl_mostrar_mensaje('El Subtipo de Transacción no pertenece a la Transacción.','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			DISPLAY rm_g22.g22_nombre TO nom_subtipo
		ELSE
			CLEAR nom_subtipo
		END IF
	AFTER INPUT
		IF rm_r19.r19_bodega_ori = vm_bod_tal THEN
			CALL fl_mostrar_mensaje('No puede poner como origen la bodega logica del taller.','exclamation')
			--NEXT FIELD r19_bodega_ori
		END IF
		CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
			RETURNING rm_r02.*
		LET local_ori = rm_r02.r02_localidad 
		LET sin_stock = rm_r02.r02_tipo
		CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_dest)
			RETURNING rm_r02.*
		IF local_ori <> vg_codloc AND 
		   rm_r02.r02_localidad <> vg_codloc THEN
			CALL fl_mostrar_mensaje('Por lo menos una bodega debe pertenecer a esta localidad.','exclamation')
			NEXT FIELD r19_bodega_ori
		END IF
		IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
			IF local_ori <> vg_codloc THEN
				IF sin_stock <> 'S' THEN
					CALL fl_mostrar_mensaje('La Bodega Origen debe pertenecer a esta localidad.','exclamation')
					NEXT FIELD r19_bodega_ori
				END IF
			END IF
		END IF
		CALL fl_lee_localidad(vg_codcia, r_ori.r02_localidad)
			RETURNING r1_g02.*
		CALL fl_lee_localidad(vg_codcia, r_des.r02_localidad)
			RETURNING r2_g02.*
		IF (r1_g02.g02_ciudad <> r2_g02.g02_ciudad AND 
		    r_ori.r02_localidad <> vg_codloc) 
		   OR 
		   (r_ori.r02_localidad = 1 AND r_des.r02_localidad = 2 AND 
			vg_codloc = 2) THEN
			CALL fl_mostrar_mensaje('Las transferencias entre '||
				'ciudades o de la localidad principal ' ||
				'de Guayaquil al otro local, solo se ' ||
 				'podrán realizar por medio de la ' ||
				'transmisión automática que se ejecuta '||
				'en Sistemas.', 'exclamation')
			NEXT FIELD r19_bodega_ori
		END IF
			
END INPUT

END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j,k,ind	SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r76		RECORD LIKE rept076.*
DEFINE grupo_linea	LIKE rept021.r21_grupo_linea

CALL retorna_tam_arr()
LET grupo_linea = NULL
FOR i = 1 TO vm_size_arr 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET i = 1
LET j = 1
DISPLAY BY NAME rm_r19.r19_tot_costo
CALL set_count(i)
INPUT ARRAY r_detalle FROM r_detalle.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN 0
		END IF
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(r20_item) THEN
{--
                	CALL fl_ayuda_maestro_items_stock_sinlinea(vg_codcia, 
							rm_r19.r19_bodega_ori)
                     		RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre,
					  rm_r10.r10_linea,
					  rm_r10.r10_precio_mb,	
					  rm_r11.r11_bodega, 
					  rm_r11.r11_stock_act
--}
                	CALL fl_ayuda_maestro_items_stock(vg_codcia,
					grupo_linea, rm_r19.r19_bodega_ori)
                     		RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre,
					  rm_r10.r10_linea,rm_r10.r10_precio_mb,
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
{--
	ON KEY(F5)
		IF rm_r10.r10_serie_lote = 'S' THEN
			LET i = arr_curr()
			IF r_detalle[i].r20_item IS NOT NULL THEN
				CALL leer_series(rm_r19.r19_bodega_ori,
						r_detalle[i].r20_item, 'A', i)
				LET int_flag = 0
			END IF
		END IF
--}
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
		IF r_detalle[i].r20_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
				RETURNING rm_r10.*
			DISPLAY rm_r10.r10_nombre TO nom_item
		END IF
		IF r_detalle[i].r20_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
				RETURNING rm_r10.*
			CALL muestra_descripciones(r_detalle[i].r20_item,
				rm_r10.r10_linea, rm_r10.r10_sub_linea,
				rm_r10.r10_cod_grupo, 
				rm_r10.r10_cod_clase)
			DISPLAY rm_r10.r10_nombre TO nom_item
		ELSE
			CLEAR nom_item, descrip_1, descrip_2, descrip_3, descrip_4	
		END IF
	BEFORE DELETE
		INITIALIZE r_detalle[i].* TO NULL
	AFTER FIELD r20_cant_ped
	    	IF  r_detalle[i].r20_cant_ped IS NOT NULL
		AND r_detalle[i].r20_item IS NOT NULL 
		    THEN
			IF r_detalle[i].r20_stock_ant < 
		   	   r_detalle[i].r20_cant_ped
		   	   THEN				
				--CALL fgl_winmessage(vg_producto,'La cantidad ingresada para la transferencia es mayor al stock existente en la bodega origen.','exclamation')
				CALL fl_mostrar_mensaje('La cantidad ingresada para la transferencia es mayor al stock existente en la bodega origen.','exclamation')
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
                       		--CALL fgl_winmessage(vg_producto,'El item no existe.','exclamation')
				CALL fl_mostrar_mensaje('El item no existe.','exclamation')
                       		NEXT FIELD r20_item
                	END IF
			DISPLAY rm_r10.r10_nombre TO nom_item
			CALL muestra_descripciones(r_detalle[i].r20_item,
				rm_r10.r10_linea, rm_r10.r10_sub_linea,
				rm_r10.r10_cod_grupo, 
				rm_r10.r10_cod_clase)

                	IF rm_r10.r10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                       		NEXT FIELD r20_item
                	END IF

			FOR k = 1 TO arr_count()
				IF  r_detalle[i].r20_item = 
				    r_detalle[k].r20_item
				AND i <> k
				THEN
					--CALL fgl_winmessage(vg_producto,'No puede ingresar items repetidos.','exclamation')
					CALL fl_mostrar_mensaje('No puede ingresar items repetidos.','exclamation')
					NEXT FIELD r20_item
               			END IF
			END FOR

			---- PARA SACAR EL STOCK DE LA BODEGA ----
			CALL fl_lee_stock_rep(vg_codcia, rm_r19.r19_bodega_ori,
     					      r_detalle[i].r20_item)
				RETURNING rm_r11.*

			CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori)
				RETURNING r_r02.*
			IF rm_r11.r11_stock_act IS NULL OR
			   rm_r11.r11_stock_act = 0 
			THEN
				IF r_r02.r02_localidad = vg_codloc THEN
					--CALL fgl_winmessage(vg_producto,'El item no posee existencia en la bodega. No se puede transferir.','exclamation')
					CALL fl_mostrar_mensaje('El item no posee existencia en la bodega. No se puede transferir.','exclamation')
					NEXT FIELD r20_item
				END IF
			END IF
			IF rm_r11.r11_stock_act IS NULL THEN
				LET rm_r11.r11_stock_act = 0
			END IF
			LET r_detalle[i].r20_stock_ant = rm_r11.r11_stock_act

			IF r_detalle[i].r20_cant_ped IS NOT NULL THEN
				IF r_detalle[i].r20_stock_ant < 
			   	   r_detalle[i].r20_cant_ped
			   	   THEN				
					IF r_r02.r02_localidad = vg_codloc THEN
						--CALL fgl_winmessage(vg_producto,'La cantidad ingresada para la transferencia es mayor al stock existente en la bodega origen.','exclamation')
						CALL fl_mostrar_mensaje('La cantidad ingresada para la transferencia es mayor al stock existente en la bodega origen.','exclamation')
						NEXT FIELD r20_cant_ped
					END IF
				END IF
			END IF
			---------------------------------------------

			LET r_detalle[i].r20_stock_ant = rm_r11.r11_stock_act
			LET r_detalle[i].r20_costo     = rm_r10.r10_costo_mb

			--- LLENO LOS DEMAS CAMPOS EN EL ARREGLO PARALELO -----
			LET r_detalle_2[i].r20_linea      = 
			    rm_r10.r10_linea
			LET r_detalle_2[i].r20_rotacion   = 
			    rm_r10.r10_rotacion
			LET r_detalle_2[i].r20_precio     = 
			    rm_r10.r10_precio_mb
			LET r_detalle_2[i].r20_costant_mb =
			    rm_r10.r10_costult_mb
			LET r_detalle_2[i].r20_costnue_mb =
			    rm_r10.r10_costo_mb
			LET r_detalle_2[i].r20_costant_ma =
			    rm_r10.r10_costult_ma
			LET r_detalle_2[i].r20_costnue_ma =
			    rm_r10.r10_costo_ma
			LET r_detalle_2[i].r20_fob        =
			    rm_r10.r10_fob
			-------------------------------------------------------

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

			------------------------------------------------------
			IF rm_r10.r10_serie_lote = 'S' THEN
				--#CALL dialog.keysetlabel('F5', 'Series')
			ELSE
				--#CALL dialog.keysetlabel('F5', '')
			END IF
			------------------------------------------------------
		ELSE
			CLEAR nom_item, descrip_1, descrip_2, descrip_3, 
			      descrip_4
			IF r_detalle[i].r20_cant_ped IS NOT NULL
				AND r_detalle[i].r20_item IS NULL THEN
				NEXT FIELD r20_item
			END IF 
		END IF
	AFTER DELETE
		CALL calcular_total()
	AFTER INPUT
		IF r_detalle[i].subtotal_item IS NULL THEN
			NEXT FIELD r20_item
		END IF
		CALL calcular_total()
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
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(500)
DEFINE r_r19		RECORD LIKE rept019.*

CLEAR FORM
CALL control_DISPLAY_botones()

LET rm_r19.r19_cod_tran = vm_cod_tran
DISPLAY BY NAME rm_r19.r19_cod_tran
IF num_args() = 4 THEN
	LET INT_FLAG = 0
	CONSTRUCT BY NAME expr_sql 
			  ON r19_num_tran,    r19_vendedor, r19_bodega_ori, 
			     r19_bodega_dest, r19_referencia, r19_cod_subtipo,
			     r19_fecing,      r19_usuario
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(r19_num_tran) THEN
				CALL fl_ayuda_transaccion_rep(vg_codcia,
							vg_codloc, vm_cod_tran)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli 

			      	IF r_r19.r19_num_tran IS NOT NULL THEN
					LET rm_r19.r19_num_tran =
							r_r19.r19_num_tran
					DISPLAY BY NAME rm_r19.r19_num_tran	
				END IF
			END IF
			IF INFIELD(r19_vendedor) AND (rm_g05.g05_tipo <> 'UF' OR
			   rm_vend.r01_tipo = 'J' OR rm_vend.r01_tipo = 'G')
			THEN
				CALL fl_ayuda_vendedores(vg_codcia)
					RETURNING rm_r01.r01_codigo, 
						  rm_r01.r01_nombres
				IF rm_r01.r01_codigo IS NOT NULL THEN
					LET rm_r19.r19_vendedor = rm_r01.r01_codigo	
					DISPLAY BY NAME rm_r19.r19_vendedor
					DISPLAY rm_r01.r01_nombres TO nom_vendedor
				END IF
			END IF
			IF INFIELD(r19_bodega_ori) THEN
			     CALL fl_ayuda_bodegas_rep(vg_codcia,'T')
		     		RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
			     IF rm_r02.r02_codigo IS NOT NULL THEN
				    LET rm_r19.r19_bodega_ori= rm_r02.r02_codigo
				    DISPLAY BY NAME rm_r19.r19_bodega_ori
				    DISPLAY rm_r02.r02_nombre TO nom_bod
			     END IF
			END IF
			IF INFIELD(r19_bodega_dest) THEN
			     	CALL fl_ayuda_bodegas_rep(vg_codcia,'T')
		     		RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
			     	IF rm_r02.r02_codigo IS NOT NULL THEN
					LET rm_r19.r19_bodega_dest =
							rm_r02.r02_codigo
				    	DISPLAY BY NAME rm_r19.r19_bodega_dest
				   	DISPLAY rm_r02.r02_nombre TO nom_bod_des
		    		END IF
			END IF
			LET int_flag = 0
		BEFORE CONSTRUCT
			IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G'
			THEN
				DISPLAY rm_vend.r01_codigo TO r19_vendedor
				DISPLAY rm_vend.r01_nombres TO nom_vendedor
			END IF
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD r19_vendedor
			IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G'
			THEN
				DISPLAY rm_vend.r01_codigo TO r19_vendedor
				DISPLAY rm_vend.r01_nombres TO nom_vendedor
			END IF		
			LET rm_r01.r01_codigo = GET_FLDBUF(r19_vendedor)
			IF rm_r01.r01_codigo IS NOT NULL THEN
				CALL fl_lee_vendedor_rep(vg_codcia, rm_r01.r01_codigo)
					RETURNING rm_r01.*       
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			ELSE
				CLEAR nom_vendedor
			END IF                        
	END CONSTRUCT
ELSE

	LET expr_sql = ' r19_num_tran = ', vg_num_tran

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
		' WHERE r19_compania  = ',vg_codcia,
		' AND   r19_localidad = ',vg_codloc,
		' AND   r19_cod_tran  = "', vm_cod_tran,'"', 
		' AND ', expr_sql CLIPPED ||
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
	IF num_args() <> 4 THEN
		EXIT PROGRAM
	END IF
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

CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET query = 'SELECT r20_cant_ped, r20_stock_ant, r20_item, r20_costo, ',
		    'r20_costo * r20_cant_ped FROM rept020 ',
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
        IF i > vm_max_rows THEN
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
IF vm_ind_arr < vm_size_arr THEN
	LET vm_size_arr = vm_ind_arr
END IF
FOR i = 1 TO vm_size_arr   
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

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
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp415 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran,
	rm_r19.r19_num_tran
	
RUN comando	

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 5
END IF

END FUNCTION



FUNCTION cargar_series()

END FUNCTION



FUNCTION leer_series(bodega, item, estado, inditem)
DEFINE i, j, k, inditem SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE cols_max         SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE bodega		LIKE rept076.r76_bodega
DEFINE item		LIKE rept076.r76_item
DEFINE estado		LIKE rept076.r76_estado
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE expr_estado	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE vm_columna_4     SMALLINT
DEFINE vm_columna_5     SMALLINT
DEFINE vm_columna_6     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT
DEFINE salirwhi		SMALLINT

LET filas_max  = 200
LET cols_max   = 1000
OPEN WINDOW w_serie AT 06, 33 WITH 17 ROWS, 46 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST - 1,
		BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_repf216_2 FROM '../forms/repf216_2'
ELSE
	OPEN FORM f_repf216_2 FROM '../forms/repf216_2c'
END IF
DISPLAY FORM f_repf216_2
LET filas_pant = fgl_scr_size('r_serie')
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Series' 	   	TO bt_serie
--#DISPLAY 'Fecha Ingreso'	TO bt_fecha
--#DISPLAY 'C'			TO bt_check
		   
WHILE TRUE
	LET expr_estado = " 1 = 1 "
	IF estado <> 'T' THEN
		LET expr_estado = " AND r76_estado = '", estado, "'"
	END IF
	LET vm_columna_1 = 1
	LET vm_columna_2 = 2
	LET vm_columna_3 = 3
	LET rm_orden[vm_columna_1]  = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = 'SELECT r76_serie, r76_fecing ',
				'FROM rept076 ',
				'WHERE r76_compania  = ', vg_codcia,
				'  AND r76_localidad = ', vg_codloc,
				'  AND r76_bodega    = "', bodega, '"',
				'  AND r76_item      = "', item CLIPPED, '"',
				 expr_estado CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	        PREPARE series FROM query
        	DECLARE q_series CURSOR FOR series
	        LET i = 1
        	FOREACH q_series INTO r_serie[inditem, i].r76_serie,
					r_serie[inditem, i].r76_fecing
                	LET i = i + 1
			IF i > filas_max THEN
				CALL fl_mensaje_arreglo_incompleto()
				CLOSE WINDOW w_serie
				RETURN
				--EXIT PROGRAM
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
        	        CALL fl_mensaje_consulta_sin_registros()
	                LET i = 0
        	        LET salir = 0
	                EXIT WHILE
		END IF
		CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
		DISPLAY item TO r76_item
		DISPLAY BY NAME r_r10.r10_nombre
                FOR j = 1 TO filas_pant
                	DISPLAY r_serie[inditem, j].* TO r_serie[j].*
	        END FOR
		FOR j = 1 TO filas_max
			IF r_serie[inditem, j].r76_serie IS NULL THEN
				EXIT FOR
			END IF
			LET r_serie_aux[j].* = r_serie[inditem, j].*
	        END FOR
	        LET j = 1
		LET salirwhi = 1
		WHILE salirwhi = 1
	        	LET INT_FLAG = 0
			CALL set_count(i)
			INPUT ARRAY r_serie_aux	WITHOUT DEFAULTS FROM r_serie.*
				ON KEY(INTERRUPT)
        		                LET salir = 1
					LET salirwhi = 0
                	        	EXIT INPUT
				ON KEY(F2)
        		                LET int_flag = 4
                		        FOR i = 1 TO filas_pant
                        		        CLEAR r_serie[i].*
		                        END FOR
					LET salirwhi = 0
        		                EXIT INPUT
				ON KEY(F15)	
					LET col = 1  
					LET salirwhi = 0
					EXIT INPUT
				ON KEY(F16)	
					LET col = 2  
					LET salirwhi = 0
					EXIT INPUT
				BEFORE ROW
					LET j = arr_curr()
					LET k = scr_line()
	                		DISPLAY r_serie[inditem, j].r76_serie
						TO r_serie[k].r76_serie
                			DISPLAY r_serie[inditem, j].r76_fecing
						TO r_serie[k].r76_fecing
					MESSAGE j, ' de ', i
					IF j > i THEN
						CONTINUE WHILE
					END IF
	                	AFTER INPUT
					LET salirwhi = 0
        	        	        LET salir = 1
			END INPUT
			IF vg_gui = 0 THEN
				IF salirwhi = 0 THEN
					EXIT WHILE
				END IF
			END IF
		END WHILE
		IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
			EXIT WHILE
		END IF
		IF col IS NOT NULL AND NOT salir THEN
        		IF col <> vm_columna_1 THEN
        	        	LET vm_columna_2           = vm_columna_1
	        	        LET rm_orden[vm_columna_2] = 
							rm_orden[vm_columna_1]
	        	        LET vm_columna_1           = col
        		END IF
        		IF rm_orden[vm_columna_1] = 'ASC' THEN
	        	        LET rm_orden[vm_columna_1] = 'DESC'
        		ELSE
        		        LET rm_orden[vm_columna_1] = 'ASC'
	        	END IF
			INITIALIZE col TO NULL
		END IF
	END WHILE
	IF i = 0 THEN
	        CONTINUE WHILE
	END IF
	IF NOT salir AND int_flag = 4 THEN
        	CONTINUE WHILE
	END IF
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_serie
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR r_serie[i].*
	END FOR
END WHILE

END FUNCTION



FUNCTION iniciar_serie()
DEFINE filas_max	SMALLINT
DEFINE cols_max, i, j	SMALLINT

LET filas_max  = 200
LET cols_max   = 1000
FOR i = 1 TO filas_max
	FOR j = 1 TO cols_max
		INITIALIZE r_serie[i,j].*, r_serie_aux[j].* TO NULL
	END FOR
END FOR

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
DISPLAY r_r03.r03_nombre     TO descrip_1
DISPLAY r_r70.r70_desc_sub   TO descrip_2
DISPLAY r_r71.r71_desc_grupo TO descrip_3
DISPLAY r_r72.r72_desc_clase TO descrip_4

END FUNCTION



FUNCTION localidad_bodega(bodega)
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE r_r02		RECORD LIKE rept002.*

CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_r02.*
RETURN r_r02.r02_localidad

END FUNCTION



FUNCTION enviar_transferencia_otra_loc()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE localidad_des	LIKE gent002.g02_localidad
DEFINE opc		SMALLINT
DEFINE comando		VARCHAR(100)

CALL localidad_bodega(rm_r19.r19_bodega_dest) RETURNING localidad_des
IF localidad_des = vg_codloc THEN
	RETURN
END IF
CASE localidad_des
	WHEN 2
		LET opc = 3
	WHEN 3
		LET opc = 2
	OTHERWISE
		LET opc = NULL
END CASE
IF opc IS NULL THEN
	RETURN
END IF
ERROR 'Se esta enviando la Transferencia. Por favor espere ... '
LET comando = 'cd /acero/fobos/PRODUCCION/TRANSMISION/; fglgo transfer ',
		opc, ' X &> /dev/null '
RUN comando CLIPPED
ERROR '                                                        '
CALL fl_lee_localidad(vg_codcia, localidad_des) RETURNING r_g02.*
CALL fl_mostrar_mensaje('Transferencia enviada a Localidad: ' || r_g02.g02_nombre CLIPPED || '.', 'info')

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
DISPLAY '<F5>      Series'                   AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

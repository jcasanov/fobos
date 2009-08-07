------------------------------------------------------------------------------
-- Titulo           : repp213.4gl - Ingreso Ajustes de Costos
-- Elaboracion      : 01-oct-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp212 base RE 1 1
-- Ultima Correccion: 01-oct-2001
-- Motivo Correccion: 1
------------------------------------------------------------------------------
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
							-- COMPA�IA DE RPTO.
DEFINE rm_r01		 	RECORD LIKE rept001.*	-- VENDEDOR
DEFINE rm_r02		 	RECORD LIKE rept002.*	-- BODEGA
DEFINE rm_r03		 	RECORD LIKE rept003.*	-- LINEA VTA.
DEFINE rm_r10		 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r11		 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r19			RECORD LIKE rept019.*	-- CABECERA
DEFINE rm_r20		 	RECORD LIKE rept020.*	-- DETALLE
DEFINE rm_g22		 	RECORD LIKE gent022.*	-- SUBTIPO TRANSACCIONES
DEFINE rm_g14	 		RECORD LIKE gent014.*	-- CONVERSION MONEDAS

DEFINE rm_aj_costo ARRAY[200] OF RECORD
	r20_item		LIKE rept020.r20_item,
	r10_nombre		LIKE rept010.r10_nombre,
	r20_stock_ant		LIKE rept020.r20_stock_ant,
	r20_costant_mb		LIKE rept020.r20_costant_mb,
	r20_costnue_mb		LIKE rept020.r20_costnue_mb
	END RECORD
	--- PARA ALMACENAR LOS OTROS VALORES DEL DETALLE ----
DEFINE rm_aj_costo_2 ARRAY[200] OF RECORD
	r20_precio		LIKE rept020.r20_precio,
	r20_costo		LIKE rept020.r20_costo,
	r20_costant_ma		LIKE rept020.r20_costant_ma,
	r20_costnue_ma		LIKE rept020.r20_costnue_ma,
	r20_linea		LIKE rept020.r20_linea,
	r20_rotacion		LIKE rept020.r20_rotacion
	END RECORD
	-----------------------------------------------------

DEFINE vm_ind_arr		SMALLINT
DEFINE vm_filas_pant		SMALLINT
DEFINE vm_total  	 	DECIMAL(12,2)
DEFINE vm_total2		DECIMAL(12,2)
DEFINE linea			VARCHAR(5)

----- VARIABLE MODULAR DEL PROGRAMA PARA DEFINIR -----------
----- EL UNICO  TIPO DE TRANSACCION DEL PROCESO -------
DEFINE vm_ajuste_costo	LIKE gent021.g21_cod_tran
DEFINE vg_cod_tran	LIKE gent021.g21_cod_tran
DEFINE vg_num_tran	LIKE rept019.r19_num_tran
DEFINE vm_elementos	SMALLINT	-- NUMERO MAXIMO DEL DETALLE



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp213.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN    -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_cod_tran = arg_val(5)
LET vg_num_tran = arg_val(6)
LET vg_proceso = 'repp213'
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
LET vm_elementos    = 250
LET vm_max_rows     = 1000
LET vm_ajuste_costo = 'AC'	
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_aj_costo AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_aj_costo FROM '../forms/repf213_1'
DISPLAY FORM f_aj_costo
CALL control_display_botones()

LET vm_filas_pant = fgl_scr_size('rm_aj_costo')
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
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
			CALL control_consulta()
			IF vm_ind_arr > vm_filas_pant THEN
				SHOW OPTION 'Detalle'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
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
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
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
		END IF
	COMMAND KEY('D') 'Detalle'		'Ver detalle de Ajuste'
		CALL control_detalle()
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



FUNCTION control_display_botones()

DISPLAY 'Item'			TO tit_col1
DISPLAY 'Descripci�n'		TO tit_col2
DISPLAY 'Stock'			TO tit_col3
DISPLAY 'Costo Anterior' 	TO tit_col4
DISPLAY 'Costo Actual'		TO tit_col5

END FUNCTION



FUNCTION control_detalle()

CALL set_count(vm_ind_arr)
DISPLAY ARRAY rm_aj_costo TO rm_aj_costo.*
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT', '')
        AFTER DISPLAY
                CONTINUE DISPLAY
        ON KEY(INTERRUPT)
                EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT

CLEAR FORM
CALL control_display_botones()

INITIALIZE rm_r19.* TO NULL
INITIALIZE linea TO NULL
INITIALIZE rm_r20.* TO NULL

-- INITIAL VALUES FOR rm_r19 FIELDS
LET rm_r19.r19_fecing     = CURRENT
LET rm_r19.r19_usuario    = vg_usuario
LET rm_r19.r19_compania   = vg_codcia
LET rm_r19.r19_localidad  = vg_codloc
DISPLAY BY NAME rm_r19.r19_usuario
DISPLAY BY NAME rm_r19.r19_fecing

-- INITIAL VALUES FOR rm_r20 FIELDS
LET rm_r20.r20_compania   = vg_codcia
LET rm_r20.r20_localidad  = vg_codloc

-- THESE FIELDS ARE NOT NULL BUT THERE ARE NOTHING TO PUT IN THEM --
CALL fl_lee_compania_repuestos(vg_codcia)  -- PARA OBTENER LA BODEGA PRINCIPAL
					   -- DE LA COMPA�IA
	RETURNING rm_r00.*
LET rm_r19.r19_moneda      = rg_gen.g00_moneda_base   -- ASIGNA LA MONEDA BASE
LET rm_r19.r19_bodega_dest = rm_r00.r00_bodega_fact
LET rm_r19.r19_bodega_ori  = rm_r00.r00_bodega_fact
LET rm_r19.r19_cont_cred  = 'C'
LET rm_r19.r19_nomcli     = ' '
LET rm_r19.r19_dircli     = ' '
LET rm_r19.r19_cedruc     = ' '
LET rm_r19.r19_descuento  = 0.0
LET rm_r19.r19_porc_impto = 0.0
LET rm_r19.r19_paridad    = 0.0
LET rm_r19.r19_precision  = 0
LET rm_r19.r19_tot_bruto  = 0.0
LET rm_r19.r19_tot_dscto  = 0.0
LET rm_r19.r19_flete      = 0.0

LET rm_r20.r20_ubicacion  = ' '
LET rm_r20.r20_stock_bd   = 0
LET rm_r20.r20_cant_ent   = 0 
LET rm_r20.r20_cant_dev   = 0
LET rm_r20.r20_descuento  = 0.0
LET rm_r20.r20_val_descto = 0.0
LET rm_r20.r20_val_impto  = 0.0
LET rm_r20.r20_fob        = 0.0
--------------------------------------------------------------------
LET rm_r19.r19_cod_tran = vm_ajuste_costo
DISPLAY BY NAME rm_r19.r19_cod_tran
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

LET vm_total  = 0
LET vm_total2 = 0
LET rm_r19.r19_tot_costo = vm_total 
LET rm_r19.r19_tot_neto  = vm_total2 
LET INT_FLAG = 0
LET rm_r20.r20_cod_tran = vm_ajuste_costo
DISPLAY BY NAME rm_r19.r19_cod_tran
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
	-- ACTUALIZO LOS VALORES DEFAULTS QUE INGRESE AL INICIO DE LEE DATOS --
LET rm_r19.r19_fecing = CURRENT
LET rm_r20.r20_fecing = CURRENT
LET rm_r19.r19_tot_costo = vm_total
LET rm_r19.r19_tot_neto = vm_total2
DISPLAY BY NAME rm_r19.r19_fecing
BEGIN WORK
	IF rm_r19.r19_tot_neto <> 0 THEN
		CALL control_ingreso_cabecera() RETURNING intentar, done 
		IF intentar = 0 AND done = 0 THEN -- PARA SABER SI HUBO ERROR
									   	  -- EN EL NUMERO DE TRANSACCION
			CLEAR FORM
			CALL control_display_botones()
			RETURN
		END IF
		CALL control_ingreso_detalle()
	END IF
	IF intentar = 0 AND done = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
		RETURN
	END IF
COMMIT WORK
CALL fl_control_master_contab_repuestos(rm_r19.r19_compania, 
	rm_r19.r19_localidad, rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_ingreso_cabecera()
DEFINE resp		CHAR(6)
DEFINE num_tran         LIKE rept019.r19_num_tran
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT
DEFINE row_current	SMALLINT

DEFINE r_g21		RECORD LIKE gent021.*

CALL fl_lee_cod_transaccion(rm_r19.r19_cod_tran) RETURNING r_g21.*
LET rm_r19.r19_tipo_tran  = r_g21.g21_tipo
LET rm_r19.r19_calc_costo = r_g21.g21_calc_costo

LET intentar = 1
LET done = 0
  -- ATRAPO EL NUMERO DE LA TRANSACCION QUE LE CORRESPONDA AL REGISTRO --

CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
	                             'AA', rm_r19.r19_cod_tran)
	RETURNING num_tran
CASE num_tran 
	WHEN 0
			CALL fgl_winmessage(vg_producto,'No existe control de'||
				    ' secuencia para esta transacci�n, no se'||
				    ' puede asignar un n�mero de transacci�n'||
				    ' a la operaci�n. ','stop')
			ROLLBACK WORK	
			EXIT PROGRAM
	WHEN -1
		SET LOCK MODE TO WAIT
		WHILE num_tran = -1
			CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA', rm_r19.r19_cod_tran)
				RETURNING num_tran
		END WHILE
		SET LOCK MODE TO NOT WAIT
END CASE
LET rm_r19.r19_num_tran = num_tran
DISPLAY BY NAME rm_r19.r19_num_tran
INSERT INTO rept019 VALUES (rm_r19.*)
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
DEFINE j 		SMALLINT

LET rm_r20.r20_num_tran = rm_r19.r19_num_tran
FOR j = 1 TO vm_num_detalles 
	IF rm_aj_costo[j].r20_stock_ant = 0 THEN
		CONTINUE FOR
	END IF
	LET rm_r20.r20_costant_mb = rm_aj_costo[j].r20_costant_mb
	LET rm_r20.r20_costnue_mb = rm_aj_costo[j].r20_costnue_mb
	LET rm_r20.r20_cant_ped   = rm_aj_costo[j].r20_stock_ant
	LET rm_r20.r20_cant_ven   = rm_aj_costo[j].r20_stock_ant
	LET rm_r20.r20_stock_ant  = rm_aj_costo[j].r20_stock_ant 
	LET rm_r20.r20_item       = rm_aj_costo[j].r20_item 
	LET rm_r20.r20_orden      = j
	LET rm_r20.r20_linea      = rm_aj_costo_2[j].r20_linea 
	LET rm_r20.r20_rotacion   = rm_aj_costo_2[j].r20_rotacion 
	LET rm_r20.r20_precio     = rm_aj_costo_2[j].r20_precio 
	LET rm_r20.r20_costo      = rm_aj_costo_2[j].r20_costo 
	LET rm_r20.r20_costant_ma = rm_aj_costo_2[j].r20_costant_ma
	LET rm_r20.r20_costnue_ma = rm_aj_costo_2[j].r20_costnue_ma
	INSERT INTO rept020 VALUES(rm_r20.*)

	CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc, 
							rm_r20.r20_cod_tran, rm_r20.r20_num_tran, rm_r20.r20_item)
END FOR 

END FUNCTION



FUNCTION control_actualizacion_items()
DEFINE j 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT

LET intentar = 1
LET done = 0
LET j = 1
-------------------------------------------------------
-- REPITE HASTA QUE PUEDE ACTUALIZAR LA TABLA DE rept010(MAESTRO DE ITEMS)
-- O HASTA QUE EL USUARIO DECIDA NO VOLVERLO A INTENTAR
-------------------------------------------------------
WHILE (intentar)
	UPDATE rept010 
		SET   r10_costult_mb = rm_aj_costo[j].r20_costant_mb, 
		      r10_costult_ma = rm_aj_costo_2[j].r20_costant_ma, 
		      r10_costo_mb   = rm_aj_costo[j].r20_costnue_mb, 
		      r10_costo_ma   = rm_aj_costo_2[j].r20_costnue_ma 
		WHERE r10_compania   = vg_codcia
		AND   r10_codigo     = rm_aj_costo[j].r20_item
	IF status < 0 THEN
		CALL fgl_winquestion(vg_producto, 
      				     'Registro est� siendo modificado'||
			      	     ' por otro usuario, desea' ||
                                     ' intentarlo nuevamente', 'No',
         			     'Yes|No', 'question', 1)
			RETURNING resp
		IF resp = 'No' THEN
			ROLLBACK WORK
			LET vm_num_rows = vm_num_rows - 1
			LET vm_row_current = vm_row_current_2
			LET intentar = 0
			LET done = 0
			RETURN intentar, done
		ELSE
			LET j = j - 1
		END IF
	END IF
	LET j = j + 1
	IF j > vm_num_detalles THEN
		LET intentar = 0
		LET done = 1
		EXIT WHILE
	END IF
END WHILE
RETURN intentar, done

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

LET INT_FLAG = 0
INPUT BY NAME rm_r19.r19_referencia, rm_r19.r19_vendedor, linea, 
	      rm_r19.r19_cod_subtipo, rm_r19.r19_tot_costo
	      WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r19_vendedor, r19_referencia, linea)
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
			    DISPLAY rm_r01.r01_nombres TO nom_vend
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
                       	CALL fl_ayuda_subtipo_tran(vm_ajuste_costo)
		       		RETURNING rm_g22.g22_cod_tran,
				rm_g22.g22_cod_subtipo, rm_g22.g22_nombre
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
						            'Vendedor est� ' ||
                                                            'bloqueado',
							    'exclamation')
					NEXT FIELD r19_vendedor
			END IF
			DISPLAY rm_r01.r01_nombres TO nom_vend
		ELSE
			CLEAR nom_vend
		END IF		 
	AFTER FIELD linea
		IF linea IS NOT NULL THEN
                    	CALL fl_lee_linea_rep(vg_codcia, linea)
                        	RETURNING rm_r03.*
			IF rm_r03.r03_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'L�nea de Venta no existe',
						    'exclamation')
				NEXT FIELD linea
			END IF
			IF rm_r03.r03_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
					            'L�nea de Venta est� ' ||
                                                    'bloqueada',
						    'exclamation')
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
				CALL fgl_winmessage(vg_producto,
					            'Subtipo de Transacci�n '||
						    'no existe',
						    'exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF 
			IF rm_g22.g22_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
						            'Subtipo de ' ||
                                                            'Transacci�n '||
							    'est� bloqueada',
							    'exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			IF rm_g22.g22_cod_tran <> rm_r19.r19_cod_tran THEN
				CALL fgl_winmessage(vg_producto,'El Subtipo de Transacci�n no pertenece a la Transacci�n ','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			DISPLAY rm_g22.g22_nombre TO nom_subtipo
		ELSE
			CLEAR nom_subtipo
		END IF
	AFTER INPUT 
		IF linea IS NULL OR linea = ' ' THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar la L�nea de Venta de los Items para realizar el ajuste ','exclamation') 
			NEXT FIELD linea
		END IF
		IF rm_r19.r19_cod_subtipo IS NOT NULL THEN
			CALL fl_lee_subtipo_transaccion(rm_r19.r19_cod_subtipo)
				RETURNING rm_g22.*
			IF rm_g22.g22_cod_subtipo IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					            'Subtipo de Transacci�n '||
						    'no existe',
						    'exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF 
			IF rm_g22.g22_estado = 'B' THEN
				CALL fgl_winmessage(vg_producto,
						            'Subtipo de ' ||
                                                            'Transacci�n '||
							    'est� bloqueada',
							    'exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			IF rm_g22.g22_cod_tran <> rm_r19.r19_cod_tran THEN
				CALL fgl_winmessage(vg_producto,'El Subtipo de Transacci�n no pertenece a la Transacci�n ','exclamation')
				NEXT FIELD r19_cod_subtipo
			END IF
			DISPLAY rm_g22.g22_nombre TO nom_subtipo
		END IF
END INPUT

END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j,k,ind	SMALLINT
DEFINE stock, stock_aux	SMALLINT
DEFINE resp		CHAR(6)


LET vm_filas_pant = fgl_scr_size('rm_aj_costo')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE rm_aj_costo[i].* TO NULL
	CLEAR rm_aj_costo[i].*
END FOR
LET i = 1
LET j = 1
DISPLAY BY NAME rm_r19.r19_tot_costo
CALL set_count(i)
INPUT ARRAY rm_aj_costo FROM rm_aj_costo.*
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
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
                	CALL fl_ayuda_maestro_items(vg_codcia, linea)
                     		RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre
                     	IF rm_r10.r10_codigo IS NOT NULL THEN
				LET rm_aj_costo[i].r20_item =rm_r10.r10_codigo
                        	DISPLAY rm_aj_costo[i].r20_item TO
					rm_aj_costo[j].r20_item
                        	DISPLAY rm_r10.r10_nombre TO 
					rm_aj_costo[j].r10_nombre
                     	END IF
                END IF
                LET int_flag = 0
	AFTER FIELD r20_item
	    	IF rm_aj_costo[i].r20_item IS NOT NULL THEN
     			CALL fl_lee_item(vg_codcia, rm_aj_costo[i].r20_item)
				RETURNING rm_r10.*
                	IF rm_r10.r10_codigo IS NULL THEN
                       		CALL fgl_winmessage(vg_producto,
		                            'El item no existe','exclamation')
                       		NEXT FIELD r20_item
                	END IF
                	IF rm_r10.r10_estado = 'B' THEN
                       		CALL fgl_winmessage(vg_producto, 'El item est� en estado bloqueado','exclamation')
                       		NEXT FIELD r20_item
                	END IF
                	IF rm_r10.r10_linea <> linea THEN
                       		CALL fgl_winmessage(vg_producto,'El item no '||
						    'corresponde a la L�nea '||
						    'de Venta ingresada',
						    'exclamation')
                       		NEXT FIELD r20_item
                	END IF
			FOR k = 1 TO arr_count()
				IF  rm_aj_costo[i].r20_item = 
				    rm_aj_costo[k].r20_item
				AND i <> k
				THEN
					CALL fgl_winmessage(vg_producto,'No puede ingresar items repetidos','exclamation')
					NEXT FIELD r20_item
               			END IF
			END FOR
 ---------  CURSOR PARA SACAR EL STOCK DEL ITEM POR TODAS LaS BODEGAS --------
			LET stock     = 0
			LET stock_aux = 0
			DECLARE q_stock CURSOR FOR 
				SELECT r11_stock_act FROM rept011
				WHERE r11_compania = vg_codcia
				AND   r11_item = rm_aj_costo[i].r20_item
			FOREACH q_stock INTO stock_aux
				LET stock = stock + stock_aux
			END FOREACH
		--------------------------------------------------
		---- LLENO LOS CAMPOS DE LA FILA SI TODO OK. ----
			LET rm_aj_costo[i].r20_stock_ant  = stock
			LET rm_aj_costo[i].r10_nombre     = rm_r10.r10_nombre
			LET rm_aj_costo[i].r20_costant_mb = rm_r10.r10_costo_mb
		--------------------------------------------------------
		---- LLENO LOS DEMAS CAMPOS EN EL ARREGLO PARALELO -----
			LET rm_aj_costo_2[i].r20_linea    = rm_r10.r10_linea
			LET rm_aj_costo_2[i].r20_rotacion = rm_r10.r10_rotacion
			LET rm_aj_costo_2[i].r20_precio   = rm_r10.r10_precio_mb
			LET rm_aj_costo_2[i].r20_costo    = rm_r10.r10_costo_mb
			LET rm_aj_costo_2[i].r20_costant_ma=rm_r10.r10_costo_ma
			DISPLAY rm_aj_costo[i].r20_stock_ant
				TO rm_aj_costo[j].r20_stock_ant
			DISPLAY rm_aj_costo[i].r10_nombre 
				TO rm_aj_costo[j].r10_nombre
			DISPLAY rm_aj_costo[i].r20_costant_mb
				TO rm_aj_costo[j].r20_costant_mb
		ELSE
			IF rm_aj_costo[i].r10_nombre IS NOT NULL
				AND rm_aj_costo[i].r20_item IS NULL
			THEN
				NEXT FIELD r20_item
			END IF 
		END IF
	BEFORE FIELD r20_costnue_mb
		IF rm_aj_costo[i].r20_item IS NULL THEN
			NEXT FIELD r20_item
		END IF
	AFTER FIELD r20_costnue_mb
		LET rm_aj_costo[i].r20_costnue_mb = 
		    fl_retorna_precision_valor(rg_gen.g00_moneda_base,
					       rm_aj_costo[i].r20_costnue_mb)
		---- PARA SACAR LA CONVERSION DE LA MONEDA ALTERNA ----
		IF rg_gen.g00_moneda_alt IS NOT NULL THEN
		       CALL fl_lee_factor_moneda(rg_gen.g00_moneda_base,
		                                 rg_gen.g00_moneda_alt)
				RETURNING rm_g14.*
			IF rm_g14.g14_serial IS NOT NULL THEN
				LET rm_aj_costo_2[i].r20_costnue_ma = 
			    	    rm_aj_costo[i].r20_costnue_mb *
			            rm_g14.g14_tasa
			ELSE
				LET rm_aj_costo_2[i].r20_costnue_ma = 0
			END IF
		ELSE
			LET rm_aj_costo_2[i].r20_costnue_ma = 0
		END IF
		------------------------------------------------------
		CALL calcula_totales()
	AFTER DELETE
		CALL calcula_totales()
	AFTER INPUT
		IF arr_count() = 0 THEN
			NEXT FIELD r20_item
		END IF
		LET ind = arr_count()
		LET vm_ind_arr = arr_count()
END INPUT
RETURN ind

END FUNCTION



FUNCTION calcula_totales()
DEFINE k 	SMALLINT
DEFINE total, total2   	DECIMAL(12,2)

LET vm_total  = 0
LET vm_total2 = 0
LET total     = 0
LET total2    = 0
FOR k = 1 TO arr_count()
		---- COSTO TOTAL ----
	LET total  = rm_aj_costo[k].r20_stock_ant *
                     rm_aj_costo[k].r20_costnue_mb
		--------------------
		---- COSTO NETO ----
	LET total2 = (rm_aj_costo[k].r20_costnue_mb -
                      rm_aj_costo[k].r20_costant_mb) *
		      rm_aj_costo[k].r20_stock_ant
		--------------------
	LET vm_total  = vm_total  + total
	LET vm_total2 = vm_total2 + total2
	LET vm_total  = vm_total2
	LET rm_r19.r19_tot_costo = vm_total 
END FOR
DISPLAY BY NAME rm_r19.r19_tot_costo

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql			VARCHAR(600)
DEFINE query			VARCHAR(600)

CLEAR FORM
CALL control_display_botones()

IF num_args() = 4 THEN
	LET INT_FLAG = 0
	CONSTRUCT BY NAME expr_sql 
			  ON r19_num_tran, r19_referencia, 
			     r19_vendedor, r19_usuario, r19_fecing
	ON KEY(F2)
		IF INFIELD(r19_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia)
			RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
			    LET rm_r19.r19_vendedor = rm_r01.r01_codigo
			    DISPLAY BY NAME rm_r19.r19_vendedor
			    DISPLAY rm_r01.r01_nombres TO nom_vend
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

LET query = 'SELECT *, ROWID FROM rept019 
		WHERE r19_compania  = ', vg_codcia,
		' AND r19_localidad = ', vg_codloc,
		' AND r19_cod_tran  ="', vm_ajuste_costo,'"',
		' AND ', expr_sql CLIPPED
PREPARE cons FROM query
DECLARE q_cons SCROLL CURSOR FOR cons
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

IF vm_num_rows <= 0 THEN
	RETURN
END IF
CLEAR FORM
CALL control_display_botones()

SELECT * INTO rm_r19.* FROM rept019 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r19.r19_num_tran, rm_r19.r19_cod_subtipo,
		rm_r19.r19_vendedor, rm_r19.r19_tot_costo,
		rm_r19.r19_referencia, rm_r19.r19_usuario, rm_r19.r19_fecing,
		rm_r19.r19_cod_tran
IF rm_r19.r19_cod_subtipo IS NOT NULL THEN
	CALL fl_lee_subtipo_transaccion(rm_r19.r19_cod_subtipo)
		RETURNING rm_g22.*
		DISPLAY rm_g22.g22_nombre TO nom_subtipo
END IF
CALL muestra_contadores()
CALL muestra_detalle()
CALL muestra_etiquetas()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i 		SMALLINT
DEFINE query 		VARCHAR(400)

LET vm_filas_pant = fgl_scr_size('rm_aj_costo')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE rm_aj_costo[i].* TO NULL
	CLEAR rm_aj_costo[i].*
END FOR
LET query = 'SELECT r20_item, r10_nombre, r20_stock_ant,', 
		'   r20_costant_mb, r20_costnue_mb, r20_linea ',
		'FROM rept020, rept010 ',
            	'WHERE r20_compania  =  ', vg_codcia, 
	    	'  AND r20_localidad =  ', vg_codloc,
	    	'  AND r20_cod_tran  = "', rm_r19.r19_cod_tran,'"',
            	'  AND r20_num_tran  =  ', rm_r19.r19_num_tran,
            	'  AND r20_compania  =  r10_compania',
            	'  AND r20_item      =  r10_codigo',
	    	' ORDER BY 1'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO rm_aj_costo[i].*, linea
	IF i = 1 THEN
		DISPLAY BY NAME linea
	END IF
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
	CALL control_display_botones()
	RETURN
END IF
LET vm_ind_arr = i
IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF
FOR i = 1 TO vm_filas_pant   
	DISPLAY rm_aj_costo[i].* TO rm_aj_costo[i].*
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

CALL fl_lee_linea_rep(vg_codcia, linea)
      	RETURNING rm_r03.*
	DISPLAY rm_r03.r03_nombre TO nom_lin
CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
	RETURNING rm_r01.*
	DISPLAY rm_r01.r01_nombres TO nom_vend

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || 
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
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION

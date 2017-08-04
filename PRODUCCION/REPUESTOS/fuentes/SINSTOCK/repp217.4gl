------------------------------------------------------------------------------
-- Titulo           : repp217.4gl - Devolucion de Facturas
-- Elaboracion      : 05-nov-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp217 base modulo compania localidad
--			[cod_tran] [num_tran]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows		ARRAY[1000] OF INTEGER 	-- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT		-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT		-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT		-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE vm_num_detalles	SMALLINT		-- NUMERO ELEMENTOS DEL DETALLE
DEFINE vm_elementos	SMALLINT		-- NUMERO MAXIMO DE ELEMENTOS
						-- DEL ARREGLO
DEFINE vm_total_fact	LIKE rept019.r19_tot_neto

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r00	 	RECORD LIKE rept000.*	-- CONFIGURACION DE LA
							-- COMPA�IA DE RPTO.
DEFINE rm_r01	 	RECORD LIKE rept001.*	-- VENDEDORES
DEFINE rm_r02	 	RECORD LIKE rept002.*	-- BODEGA
DEFINE rm_r10	 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r11	 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r19, rm_fact	RECORD LIKE rept019.*	-- CAB. TRANSACCIONES
DEFINE rm_r20		RECORD LIKE rept020.*	-- DET. TRANSACCIONES
DEFINE rm_g13	 	RECORD LIKE gent013.*	-- MONEDAS.
DEFINE rm_c01		RECORD LIKE cxct001.*   -- CLIENTES GENERAL.
DEFINE rm_c02		RECORD LIKE cxct002.*   -- CLIENTES LOCALIDAD.
DEFINE rm_j10		RECORD LIKE cajt010.*   -- REGISTRO DE CAJA

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle	ARRAY[200] OF RECORD
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r20_cant_dev	LIKE rept020.r20_cant_dev,
				r20_bodega	LIKE rept020.r20_bodega,
				r20_item	LIKE rept020.r20_item,
				r20_descuento	LIKE rept020.r20_descuento,
				r20_precio	LIKE rept020.r20_precio,
				subtotal_item	LIKE rept019.r19_tot_neto
			END RECORD
	----------------------------------------------------------
	---- ARREGLO PARALELO PARA LOS OTROS CAMPOS ----
DEFINE r_detalle_1	ARRAY[200] OF RECORD
			 -- PARA ALMACENAR LA CANT.DEVUELTA ANTERIORMENTE
				vm_cant_dev	LIKE rept020.r20_cant_dev,
				r20_fob		LIKE rept020.r20_fob,
				r20_costo	LIKE rept020.r20_costo,
				r20_costant_mb	LIKE rept020.r20_costant_mb,
				r20_costant_ma	LIKE rept020.r20_costant_ma,
				r20_costnue_mb	LIKE rept020.r20_costant_mb,
				r20_costnue_ma	LIKE rept020.r20_costant_ma,
				r20_bodega	LIKE rept020.r20_bodega,
				r20_orden	LIKE rept020.r20_orden,
				r20_linea	LIKE rept020.r20_linea,
				r20_rotacion	LIKE rept020.r20_rotacion,
				r20_val_descto	LIKE rept020.r20_val_descto,
				r20_val_impto	LIKE rept020.r20_val_impto,
				val_costo	LIKE rept019.r19_tot_costo
			END RECORD
	----------------------------------------------------------

DEFINE vm_cod_dev	LIKE rept019.r19_cod_tran
DEFINE vm_cod_anu	LIKE rept019.r19_cod_tran
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_cod_tran_2	LIKE rept019.r19_cod_tran

DEFINE vm_flag_devolucion	CHAR(1)	   -- FLAG DE DEVOLUCION
					   -- 'S' Si se puede devolver
					   -- 'N' No se puede devolver
DEFINE vm_flag_mant	CHAR(1)	   -- FLAG DE MANTENIMIENTO
					   -- 'I' --> INGRESO		
					   -- 'M' --> MODIFICACION		
					   -- 'C' --> CONSULTA		
DEFINE vm_ind_arr	SMALLINT   -- INDICE DE MI ARREGLO (INPUT ARRAY)
DEFINE vm_size_arr	SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_impuesto    	DECIMAL(12,2)	-- TOTAL DEL IMPUESTO
DEFINE vg_cod_tran 	LIKE gent021.g21_cod_tran
DEFINE vg_num_tran	LIKE rept019.r19_num_tran



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp217.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN     -- Validar # par�metros correcto
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_cod_tran = arg_val(5)
LET vg_num_tran = arg_val(6)
LET vg_proceso  = 'repp217'
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

CREATE TEMP TABLE tmp_item_ret(
		nota_ent	INTEGER,
		bodega_real	CHAR(2),
		bodega_fact	CHAR(2),
		item		CHAR(15),
		cant_dev	DECIMAL(8,2),
		cant_ent	DECIMAL(8,2)
	)
CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_lee_compania_repuestos(vg_codcia)  RETURNING rm_r00.*                
LET vm_cod_dev    = 'DF'
LET vm_cod_anu    = 'AF'
LET vm_cod_tran   = 'FA'
LET vm_cod_tran_2 = vm_cod_dev
LET vm_max_rows   = 1000
LET vm_elementos  = 200
LET lin_menu      = 0          
LET row_ini       = 3          
LET num_rows      = 22         
LET num_cols      = 80         
IF vg_gui = 0 THEN        
	LET lin_menu = 1                                                        
	LET row_ini  = 2
	LET num_rows = 22 
	LET num_cols = 78 
END IF                  
OPEN WINDOW w_217 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS            
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_217 FROM '../forms/repf217_1'
ELSE
	OPEN FORM f_217 FROM '../forms/repf217_1c'
END IF
DISPLAY FORM f_217
CALL control_DISPLAY_botones()
CALL retorna_tam_arr()
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Ver Factura'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
                HIDE OPTION 'Imprimir'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Ver Factura'
                	HIDE OPTION 'Imprimir'
			HIDE OPTION 'Ver Detalle'
			CALL control_consulta()
			CALL control_ver_detalle()
			EXIT PROGRAM
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
                CALL control_ingreso()
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Ver Factura'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Imprimir'
		END IF
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
		HIDE OPTION 'Imprimir'
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				SHOW OPTION 'Ver Factura'
				SHOW OPTION 'Ver Detalle'
			END IF 
                ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
                        SHOW OPTION 'Avanzar'
                END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('F') 'Ver Factura' 		'Ver Factura de la Transacci�n.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_factura(rm_r19.r19_num_dev)
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
        COMMAND KEY('P') 'Imprimir'		'Imprime Devoluci�n/Anulaci�n.'
        	CALL imprimir()
	COMMAND KEY('V') 'Ver Detalle' 		'Ver Detalle de la Transacci�n.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF 
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Ver Factura'
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



FUNCTION control_ver_factura(num_tran)
DEFINE num_tran 	LIKE rept019.r19_num_tran
DEFINE command_line	VARCHAR(100)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE run_prog		CHAR(10)

CALL fl_lee_cabecera_transaccion_rep(vg_codcia,vg_codloc, vm_cod_tran, num_tran)
	RETURNING r_r19.*

IF r_r19.r19_num_tran IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'La factura no existe en la Compa��a.','exclamation')
	CALL fl_mostrar_mensaje('La factura no existe en la Compa��a.','exclamation')
	RETURN
END IF

{-- ESTO PARA LLAMAR AL PROGRAMA SEG�N SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
LET command_line = run_prog || 'repp308 ' || vg_base || ' '
	    || vg_modulo || ' ' || vg_codcia 
	    || ' ' || vg_codloc || ' ' ||
	    vm_cod_tran || ' ' || num_tran
RUN command_line

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'C Ven.'		TO tit_col1
--#DISPLAY 'C Dev.'		TO tit_col2
--#DISPLAY 'Bd'			TO tit_col3
--#DISPLAY 'Item'		TO tit_col4
--#DISPLAY 'Des %'		TO tit_col5
--#DISPLAY 'Precio Unit.'	TO tit_col6
--#DISPLAY 'Subtotal'		TO tit_col7

--#IF vm_flag_mant = 'C' THEN
	--#DISPLAY 'C Dev.'	TO tit_col1
	--#DISPLAY ' '		TO tit_col2
--#END IF

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE i,j 	SMALLINT
DEFINE r_r10 	RECORD LIKE rept010.*

CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F5)
		CALL control_ver_factura(rm_r19.r19_num_dev)
		LET int_flag = 0
	ON KEY(F6)
        	CALL imprimir()
		LET int_flag = 0
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
			RETURNING r_r10.*
		CALL muestra_descripciones(r_detalle[i].r20_item,
				r_r10.r10_linea, r_r10.r10_sub_linea,
				r_r10.r10_cod_grupo, 
				r_r10.r10_cod_clase)
		DISPLAY r_r10.r10_nombre TO nom_item
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("F6","Imprimir")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()

		--#IF r_detalle[i].r20_item IS NOT NULL THEN
			--#CALL fl_lee_item(vg_codcia, r_detalle[i].r20_item)
				--#RETURNING r_r10.*
			--#CALL muestra_descripciones(r_detalle[i].r20_item,
				--#r_r10.r10_linea, r_r10.r10_sub_linea,
				--#r_r10.r10_cod_grupo, 
				--#r_r10.r10_cod_clase)
			--#DISPLAY r_r10.r10_nombre TO nom_item
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT
DEFINE flag_transf	SMALLINT
DEFINE pago_fact_nc_pa 	CHAR(1)
DEFINE val_ant 		DECIMAL(12,2)
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_r02		RECORD LIKE rept002.*

CLEAR FORM
LET vm_flag_mant = 'I'
CALL control_DISPLAY_botones()

INITIALIZE rm_r19.*, rm_r20.* TO NULL
LET rm_r19.r19_fecing   = CURRENT
LET rm_r19.r19_usuario  = vg_usuario
LET rm_r19.r19_cod_tran = vm_cod_tran_2
LET rm_r19.r19_tipo_dev = vm_cod_tran
DISPLAY BY NAME rm_r19.r19_tipo_dev, rm_r19.r19_fecing

CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE	
		LET vm_flag_mant = 'C'
		CLEAR FORM
		CALL control_DISPLAY_botones()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_read_r19 CURSOR FOR SELECT * FROM rept019
		WHERE  r19_compania  = vg_codcia
		AND    r19_localidad = vg_codloc
		AND    r19_cod_tran  = rm_r19.r19_cod_tran
		AND    r19_num_tran  = rm_r19.r19_num_tran
		FOR UPDATE

	OPEN q_read_r19
	FETCH q_read_r19
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		CLEAR FORM 
		CALL control_DISPLAY_botones()
		WHENEVER ERROR STOP
		RETURN
	END IF
WHENEVER ERROR STOP
UPDATE rept019 SET r19_codcli = rm_r19.r19_codcli,
	 	   r19_nomcli = rm_r19.r19_nomcli
	WHERE CURRENT OF q_read_r19
LET i = control_cargar_detalle_factura()
IF i > vm_elementos THEN
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	RETURN
END IF

IF vm_flag_devolucion = 'N' THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'La factura ya ha sido devuelta totalmente.','exclamation')
	CALL fl_mostrar_mensaje('La factura ya ha sido devuelta totalmente.','exclamation')
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	RETURN
END IF

LET int_flag = 0
LET vm_num_detalles = ingresa_detalles() 
IF int_flag THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE	
		LET vm_flag_mant = 'C'
		CLEAR FORM
		CALL control_DISPLAY_botones()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET vm_cod_tran_2 = vm_cod_dev
IF rm_r19.r19_tot_neto = rm_fact.r19_tot_neto THEN
	IF TODAY = DATE(rm_fact.r19_fecing) AND
	   NOT tiene_nota_entrega(rm_fact.r19_cod_tran, rm_fact.r19_num_tran)
	THEN
		LET vm_cod_tran_2 = vm_cod_anu
		IF rm_fact.r19_cont_cred = 'R' THEN 
			IF NOT verifica_saldo_fact_devuelta() THEN
				LET vm_cod_tran_2 = vm_cod_dev
			END IF
		END IF
	ELSE
		LET vm_cod_tran_2 = vm_cod_dev
	END IF
END IF
LET done = control_cabecera()
DISPLAY BY NAME rm_r19.r19_cod_tran, rm_r19.r19_fecing
IF done = 0 THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No se realizo el proceso.','exclamation')
	CALL fl_mostrar_mensaje('No se realizo el proceso.','exclamation')
	IF vm_num_rows <= 1 THEN
		LET vm_num_rows = 0
		LET vm_row_current = 0
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE
		LET vm_num_rows = vm_num_rows - 1
		LET vm_row_current = vm_num_rows
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF 

LET done = control_ingreso_detalle()
IF done = 0 THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'Ha ocurrido un error en el ingreso del detalle de la devoluci�n. No se realizar� el proceso.','exclamation')
	CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso del detalle de la devoluci�n. No se realizar� el proceso.','exclamation')
	IF vm_num_rows <= 1 THEN
		LET vm_num_rows = 0
		LET vm_row_current = 0
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE
		LET vm_num_rows = vm_num_rows - 1
		LET vm_row_current = vm_num_rows
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET done = control_actualiza_existencia()
IF done = 0 THEN
	ROLLBACK WORK 
	IF vm_num_rows <= 1 THEN
		LET vm_num_rows = 0
		LET vm_row_current = 0
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE
		LET vm_num_rows = vm_num_rows - 1
		LET vm_row_current = vm_num_rows
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET pago_fact_nc_pa = 'N'
IF rm_r19.r19_cod_tran = vm_cod_anu AND rm_fact.r19_cont_cred = 'C' THEN
	LET val_ant = 0
	SELECT r25_valor_ant INTO val_ant FROM rept025
		WHERE r25_compania  = rm_r19.r19_compania  AND 
		      r25_localidad = rm_r19.r19_localidad AND 
		      r25_cod_tran  = rm_r19.r19_tipo_dev  AND 
		      r25_num_tran  = rm_r19.r19_num_dev
	IF val_ant > 0 THEN
		LET pago_fact_nc_pa = 'S'
	END IF
END IF
IF rm_r19.r19_cod_tran = vm_cod_dev OR 
	(rm_r19.r19_cod_tran = vm_cod_anu AND rm_fact.r19_cont_cred = 'R') OR 
	pago_fact_nc_pa = 'S' THEN
		CALL crea_nota_credito()
END IF
CALL fl_actualiza_acumulados_ventas_rep(vg_codcia, vg_codloc, 
			rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
	RETURNING done
IF NOT done THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
CALL fl_actualiza_estadisticas_item_rep(vg_codcia, vg_codloc, 
			rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
	RETURNING done
IF NOT done THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
CALL actualiza_estado_caja()
CALL actualiza_ordenes_despacho()
LET flag_transf = 0
FOR i = 1 TO vm_ind_arr
	CALL fl_lee_bodega_rep(vg_codcia, r_detalle[i].r20_bodega)
		RETURNING r_r02.*
	IF r_r02.r02_tipo <> 'S' THEN
		CONTINUE FOR
	END IF
	-- OJO REVISAR
	{-- PARA QUE HAGA LA TRANF. DE LA BODEGA 79
	IF r_r02.r02_localidad <> vg_codloc THEN
		CONTINUE FOR
	END IF
	--}
	IF r_detalle[i].r20_cant_dev > 0 THEN
		CALL cargar_temp(i)
		LET flag_transf = 1
	END IF
END FOR
IF flag_transf THEN
	CALL transferencia_retorno()
	DELETE FROM tmp_item_ret
END IF
IF rm_r19.r19_cod_tran <> vm_cod_dev THEN
	CALL verifica_pago_tarjeta_credito()
END IF
COMMIT WORK

CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc, 
	rm_r19.r19_cod_tran, rm_r19.r19_num_tran)
CALL muestra_contadores()
SELECT * INTO r_z21.* FROM cxct021
	WHERE z21_compania  = vg_codcia
	  AND z21_localidad = vg_codloc
	  AND z21_cod_tran  = rm_r19.r19_cod_tran
	  AND z21_num_tran  = rm_r19.r19_num_tran
CALL imprimir()
IF r_z21.z21_tipo_doc = 'NC' THEN
	CALL imprimir_nota_credito(r_z21.*)
END IF
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION actualiza_estado_caja()
DEFINE cod_pago		LIKE cajt011.j11_codigo_pago
DEFINE valor		DECIMAL(12,2)

SELECT * INTO rm_j10.* FROM cajt010 
	WHERE j10_compania    =  vg_codcia 
	  AND j10_localidad   =  vg_codloc 	
	  AND j10_tipo_fuente = 'PR'
	  AND j10_tipo_destino=  vm_cod_tran 
	  AND j10_num_destino =  rm_r19.r19_num_dev

IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe registro en cajt010','stop')
	EXIT PROGRAM
END IF
-- FALTA ANALIZAR CUANDO EL OPERATIVO ANULA UNA PARTE Y LUEGO 
-- ANULA EL RESTO, COMO DEBER�A QUEDAR EL ESTADO DEN CAJT010 ?

--IF rm_r19.r19_tot_neto = rm_j10.j10_valor THEN
IF rm_r19.r19_tot_neto = vm_total_fact THEN
	IF DATE(rm_j10.j10_fecha_pro) = TODAY AND
	   rm_r19.r19_cod_tran = vm_cod_anu THEN
 		UPDATE cajt010 set j10_estado = 'E'
			WHERE j10_compania    =  vg_codcia 
		          AND j10_localidad   =  vg_codloc 	
		          AND j10_tipo_fuente =  rm_j10.j10_tipo_fuente
		          AND j10_num_fuente  =  rm_j10.j10_num_fuente
		DECLARE q_lazo CURSOR FOR
			SELECT j11_codigo_pago, SUM(j11_valor) FROM cajt011
				WHERE j11_compania    =  vg_codcia 
	  			  AND j11_localidad   =  vg_codloc 	
	  			  AND j11_tipo_fuente =  rm_j10.j10_tipo_fuente
	  			  AND j11_num_fuente  =  rm_j10.j10_num_fuente
				  AND j11_codigo_pago IN ('EF','CH')
				GROUP BY 1
		FOREACH q_lazo INTO cod_pago, valor
			IF cod_pago = 'EF' THEN
				UPDATE cajt005
				SET j05_ef_ing_dia = 
				    j05_ef_ing_dia - valor
				WHERE j05_compania    = vg_codcia 
				  AND j05_localidad   = vg_codloc 
				  AND j05_codigo_caja = rm_j10.j10_codigo_caja 
				  AND j05_fecha_aper  = DATE(rm_j10.j10_fecha_pro)
			ELSE
				UPDATE cajt005
				SET j05_ch_ing_dia = 
				    j05_ch_ing_dia - valor
				WHERE j05_compania    = vg_codcia 
				  AND j05_localidad   = vg_codloc 
				  AND j05_codigo_caja = rm_j10.j10_codigo_caja 
				  AND j05_fecha_aper  = DATE(rm_j10.j10_fecha_pro)
			END IF
		END FOREACH
	END IF
END IF
 
END FUNCTION



FUNCTION control_cargar_detalle_factura()
DEFINE r_r20 	RECORD LIKE rept020.*
DEFINE r_r10 	RECORD LIKE rept010.*
DEFINE i 	SMALLINT

LET vm_flag_devolucion = 'N'

DECLARE q_read_r20 CURSOR FOR SELECT * FROM rept020
	WHERE r20_compania  = vg_codcia
	AND   r20_localidad = vg_codloc
	AND   r20_cod_tran  = rm_r19.r19_cod_tran
	AND   r20_num_tran  = rm_r19.r19_num_tran 

LET i = 1 
FOREACH q_read_r20 INTO r_r20.*
	IF r_r20.r20_cant_ven - r_r20.r20_cant_dev > 0 THEN
		CALL fl_lee_item(vg_codcia, r_r20.r20_item)
			RETURNING r_r10.*
		LET r_detalle_1[i].r20_bodega     = r_r20.r20_bodega
		LET r_detalle_1[i].r20_orden      = r_r20.r20_orden
		LET r_detalle_1[i].r20_linea      = r_r10.r10_linea
		LET r_detalle_1[i].r20_rotacion   = r_r10.r10_rotacion
		LET r_detalle_1[i].r20_fob        = r_r10.r10_fob
		LET r_detalle_1[i].r20_costant_mb = r_r20.r20_costant_mb
		LET r_detalle_1[i].r20_costant_ma = r_r20.r20_costant_ma
		LET r_detalle_1[i].r20_costnue_mb = r_r20.r20_costnue_mb
		LET r_detalle_1[i].r20_costnue_ma = r_r20.r20_costnue_ma
		LET r_detalle_1[i].r20_costo      = r_r20.r20_costo  
		LET r_detalle_1[i].vm_cant_dev    = r_r20.r20_cant_dev  
		LET r_detalle[i].r20_item         = r_r20.r20_item 
		LET r_detalle[i].r20_precio       = r_r20.r20_precio 
		LET r_detalle[i].r20_descuento    = r_r20.r20_descuento 
		LET r_detalle[i].r20_cant_ven     = r_r20.r20_cant_ven - 
						    r_r20.r20_cant_dev
		LET r_detalle[i].r20_cant_dev     = 0 	  
		LET r_detalle[i].r20_bodega       = r_r20.r20_bodega
		LET r_detalle[i].subtotal_item    = r_r20.r20_cant_dev * 
						    r_r20.r20_precio
		LET i = i + 1
	END IF
	IF i > vm_elementos THEN
		CALL fl_mensaje_arreglo_lleno()
		RETURN i
		EXIT FOREACH
	END IF
END FOREACH

LET vm_ind_arr = i - 1

FOR i = 1 TO vm_ind_arr
	IF r_detalle[i].r20_cant_ven > 0 THEN
		LET vm_flag_devolucion = 'S'
		EXIT FOR	
	END IF
END FOR

RETURN 0

END FUNCTION



FUNCTION control_cabecera()
DEFINE i,done 	SMALLINT
DEFINE resp		CHAR(6)
DEFINE num_tran  	LIKE rept019.r19_num_tran
DEFINE r_g14		RECORD 	LIKE gent014.*


LET done = 1
CALL control_num_transaccion()
	RETURNING num_tran
IF num_tran = -1 THEN
	RETURN 0
END IF 

	--- ACTUALIZO LOS VALORES PARA SU INGRESO ---
LET rm_r19.r19_tipo_dev = vm_cod_tran	  	-- TIPO DEV = 'FA' 
LET rm_r19.r19_cod_tran = vm_cod_tran_2		
LET rm_r19.r19_num_tran = num_tran		-- EL NUEVO NUMERO DE LA TRAN.	
LET rm_r19.r19_usuario  = vg_usuario			
LET rm_r19.r19_fecing   = CURRENT
LET rm_r19.r19_paridad  = 1

IF rm_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(rm_r19.r19_moneda,rg_gen.g00_moneda_alt)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		ROLLBACK WORK
		--CALL fgl_winmessage(vg_producto,'No existe factor de conversi�n entre la moneda base y la moneda alterna.','stop')
		CALL fl_mostrar_mensaje('No existe factor de conversi�n entre la moneda base y la moneda alterna.','stop')
		EXIT PROGRAM
	END IF
	LET rm_r19.r19_paridad = r_g14.g14_tasa
END IF
	---------------------------------------------

INSERT INTO rept019 VALUES (rm_r19.*)
DISPLAY BY NAME rm_r19.r19_num_tran

----- ACTUALIZO LA FACTURA SELECCIONADA EN LA DEVOLUCION ---
UPDATE rept019 
	SET   r19_tipo_dev  = vm_cod_tran_2,
	      r19_num_dev   = num_tran
	WHERE r19_compania  = vg_codcia
	AND   r19_localidad = vg_codloc 
	AND   r19_cod_tran  = vm_cod_tran
	AND   r19_num_tran  = rm_r19.r19_num_dev
	------------------------------------------

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
        LET vm_num_rows = vm_num_rows + 1
END IF

LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 

IF status < 0 THEN
	LET done = 0
END IF
                                             	-- procesada
RETURN done

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE i,done,k		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE costo_nue	DECIMAL(14,2)

LET done = 1
SET LOCK MODE TO WAIT 10
-- INITIAL VALUES FOR rm_r20 FIELDS
LET rm_r20.r20_compania  = vg_codcia
LET rm_r20.r20_localidad = vg_codloc
LET rm_r20.r20_num_tran  = rm_r19.r19_num_tran
LET rm_r20.r20_cod_tran  = vm_cod_tran_2
LET rm_r20.r20_fecing    = rm_r19.r19_fecing
LET rm_r20.r20_ubicacion = 'SN'

LET k = 1
FOR i = 1 TO vm_ind_arr
	IF r_detalle[i].r20_cant_dev > 0 THEN
		
		CALL fl_lee_stock_rep(vg_codcia, r_detalle_1[i].r20_bodega,
     				      r_detalle[i].r20_item)
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			LET rm_r20.r20_stock_ant  = 0
		ELSE
			LET rm_r20.r20_stock_ant  = r_r11.r11_stock_act
		END IF
		
		----ACTUALIZO LA CANTIDAD DEV EN LA FACTURA INGRESADA ----
		UPDATE rept020 
			SET   r20_cant_dev  = r_detalle[i].r20_cant_dev + 
					      r_detalle_1[i].vm_cant_dev
			WHERE r20_compania  = vg_codcia
			AND   r20_localidad = vg_codloc
			AND   r20_cod_tran  = vm_cod_tran 	 -- 'FA'
			AND   r20_num_tran  = rm_r19.r19_num_dev -- FACTURA DEV.
			AND   r20_bodega    = r_detalle_1[i].r20_bodega 
			AND   r20_item      = r_detalle[i].r20_item 
			AND   r20_orden     = r_detalle_1[i].r20_orden
		---------------------------------------------------------
		LET rm_r20.r20_bodega     = r_detalle_1[i].r20_bodega
		LET rm_r20.r20_item       = r_detalle[i].r20_item
    		CALL fl_lee_item(vg_codcia, rm_r20.r20_item) RETURNING r_r10.*
		CALL fl_obtiene_costo_item(vg_codcia, rm_r19.r19_moneda,
			rm_r20.r20_item, r_detalle[i].r20_cant_dev, 
			r_detalle_1[i].r20_costo)
			RETURNING costo_nue
		LET r_r10.r10_costult_mb  = r_detalle_1[i].r20_costo
		UPDATE rept010 SET r10_costo_mb		= costo_nue,
	                   	   r10_costult_mb	= r_r10.r10_costult_mb
			WHERE r10_compania = vg_codcia AND 
		              r10_codigo   = rm_r20.r20_item
		LET rm_r20.r20_cant_ped   = r_detalle[i].r20_cant_dev
		LET rm_r20.r20_cant_ven   = r_detalle[i].r20_cant_dev
		LET rm_r20.r20_cant_dev   = 0
		LET rm_r20.r20_cant_ent   = 0
		LET rm_r20.r20_stock_bd   = 0
		LET rm_r20.r20_precio     = r_detalle[i].r20_precio
		LET rm_r20.r20_descuento  = r_detalle[i].r20_descuento
		LET rm_r20.r20_orden      = r_detalle_1[i].r20_orden
		LET rm_r20.r20_fob        = r_detalle_1[i].r20_fob
		LET rm_r20.r20_costant_mb = r_r10.r10_costo_mb
		LET rm_r20.r20_costant_ma = 0
		LET rm_r20.r20_costnue_mb = costo_nue
		LET rm_r20.r20_costnue_ma = 0
		LET rm_r20.r20_linea      = r_detalle_1[i].r20_linea
		LET rm_r20.r20_rotacion   = r_detalle_1[i].r20_rotacion
		LET rm_r20.r20_costo      = r_detalle_1[i].r20_costo
		LET rm_r20.r20_val_descto = r_detalle_1[i].r20_val_descto
		LET rm_r20.r20_val_impto  = r_detalle_1[i].r20_val_impto 
		INSERT INTO rept020 VALUES(rm_r20.*)
		LET k = k + 1
	END IF
END FOR 
IF status < 0 THEN
	LET done = 0
END IF

RETURN done

END FUNCTION



FUNCTION control_actualiza_existencia()
DEFINE i,done 	SMALLINT
DEFINE r_r11	RECORD LIKE rept011.*

SET LOCK MODE TO WAIT
LET done = 1

FOR i = 1 TO vm_ind_arr
	IF r_detalle[i].r20_cant_dev > 0 THEN

		CALL fl_lee_stock_rep(vg_codcia, r_detalle_1[i].r20_bodega,
				      r_detalle[i].r20_item)	
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			INSERT INTO rept011
	      			(r11_compania, r11_bodega, r11_item, 
				 r11_ubicacion, r11_stock_ant, 
				 r11_stock_act, r11_ing_dia,
				 r11_egr_dia)
				VALUES(vg_codcia, r_detalle_1[i].r20_bodega,
				       r_detalle[i].r20_item, 'SN', 
				       0, r_detalle[i].r20_cant_dev, 
				       r_detalle[i].r20_cant_dev,0) 
		ELSE	 
			UPDATE rept011 
				SET   r11_stock_ant = r11_stock_act,
		     	     	      r11_stock_act = r11_stock_act + 
		      		         	      r_detalle[i].r20_cant_dev,
		      	     	      r11_ing_dia   = r_detalle[i].r20_cant_dev
				WHERE r11_compania = vg_codcia
				AND   r11_bodega   = r_detalle_1[i].r20_bodega
				AND   r11_item     = r_detalle[i].r20_item 
		END IF
	END IF
END FOR 

SET LOCK MODE TO NOT WAIT

RETURN done

END FUNCTION



FUNCTION control_num_transaccion()
DEFINE num_tran 	LIKE rept019.r19_num_tran
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE resp 		CHAR(6)

CALL fl_lee_compania_repuestos(vg_codcia)  
        RETURNING r_r00.*                
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc,  vg_modulo,
	                             'AA', vm_cod_tran_2)
	RETURNING num_tran
CASE num_tran 
	WHEN 0
			--CALL fgl_winmessage(vg_producto,'No existe control de secuencia para esta transacci�n, no se puede asignar un n�mero de transacci�n a la operaci�n.','stop')
			CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacci�n, no se puede asignar un n�mero de transacci�n a la operaci�n.','stop')
			EXIT PROGRAM
	WHEN -1
		WHILE num_tran = -1
			--CALL fgl_winquestion(vg_producto,'Registro est� siendo modificado por otro usuario, desea intentarlo nuevamente','No','Yes|No','question',1)
			CALL fl_hacer_pregunta('Registro est� siendo modificado por otro usuario, desea intentarlo nuevamente','No')
				RETURNING resp
			IF resp = 'No' THEN
				EXIT WHILE
			ELSE
				IF num_tran <> -1 THEN
					EXIT WHILE
				END IF
			END IF
			CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA', vm_cod_tran_2)
				RETURNING num_tran
		END WHILE
END CASE

RETURN num_tran

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE comando 		CHAR(600)
DEFINE done		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r19_referencia	LIKE rept019.r19_referencia
DEFINE run_prog		CHAR(10)
DEFINE flag_consumidor	CHAR(1)

LET r19_referencia = NULL
LET int_flag = 0
INPUT BY NAME rm_r19.r19_num_dev, rm_r19.r19_codcli, r19_referencia 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(r19_num_dev) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      vm_cod_tran)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli 
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							    vg_codloc,
							    vm_cod_tran,
							    r_r19.r19_num_tran)
					RETURNING rm_r19.*
				LET rm_r19.r19_num_dev = rm_r19.r19_num_tran
				CALL control_DISPLAY_cabecera()
		      	END IF
		END IF
                IF INFIELD(r19_codcli) THEN
                        CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
                                RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
                        IF r_z01.z01_codcli IS NOT NULL THEN
                                LET rm_r19.r19_codcli = r_z01.z01_codcli
                                LET rm_r19.r19_nomcli = r_z01.z01_nomcli
                                DISPLAY BY NAME rm_r19.r19_codcli,
                                                rm_r19.r19_nomcli
                        END IF
                END IF
		LET int_flag = 0
	ON KEY(F5)
		IF INFIELD(r19_num_dev) THEN
			IF rm_r19.r19_num_dev IS NOT NULL THEN
				CALL control_ver_factura(rm_r19.r19_num_dev)
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r19_num_dev
		IF rm_r19.r19_num_dev IS NOT NULL THEN
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							    vg_codloc,
							    vm_cod_tran,
							    rm_r19.r19_num_dev)
				RETURNING r_r19.*
                	IF r_r19.r19_num_tran IS  NULL THEN
		    		--CALL fgl_winmessage (vg_producto,'La factura no existe en la Compa��a.','exclamation')
				CALL fl_mostrar_mensaje('La factura no existe en la Compa��a.','exclamation')
                        	NEXT FIELD r19_num_dev
			END IF

			LET rm_r19.* = r_r19.*
			LET vm_total_fact = r_r19.r19_tot_neto
			LET rm_r19.r19_num_dev = rm_r19.r19_num_tran
			LET rm_r19.r19_referencia = r19_referencia

			CALL control_DISPLAY_cabecera()


			IF DATE(rm_r19.r19_fecing) + rm_r00.r00_dias_dev < 
			   TODAY 
			   THEN
				--CALL fgl_winmessage(vg_producto,'La factura no puede ser devuelta porque supero el plazo para su devoluci�n.','exclamation')
				CALL fl_mostrar_mensaje('La factura no puede ser devuelta porque supero el plazo para su devoluci�n.','exclamation')
				NEXT FIELD r19_num_dev
			END IF

			IF rm_r19.r19_codcli IS NULL THEN
				--CALL fgl_winquestion(vg_producto,'No hay c�digo de cliente, desea ingresar los datos del cliente.','No','Yes|No','question',1)
				CALL fl_hacer_pregunta('No hay c�digo de cliente, desea ingresar los datos del cliente.','No')
					RETURNING resp
				LET flag_consumidor = 'N'
				IF resp = 'No' THEN
					LET flag_consumidor = 'S'
					--NEXT FIELD r19_num_dev
					NEXT FIELD r19_codcli
				END IF	
				{-- ESTO PARA LLAMAR AL PROGRAMA SEG�N SEA EL AMBIENTE --}
				LET run_prog = '; fglrun '
				IF vg_gui = 0 THEN
					LET run_prog = '; fglgo '
				END IF
				{--- ---}
				LET comando = 'cd ..',     vg_separador, 
					         '..',     vg_separador,
                                              'COBRANZAS', vg_separador, 
					      'fuentes',   vg_separador, 
                                              run_prog,'cxcp101 ', vg_base, ' ',
                                              'CO ', vg_codcia, ' ',
                                              vg_codloc
				RUN comando CLIPPED
				NEXT FIELD r19_codcli
			END IF
			IF TODAY > DATE(rm_r19.r19_fecing) AND 
				rm_r19.r19_codcli = rm_r00.r00_codcli_tal THEN
				CALL fl_mostrar_mensaje('Se va a generar NC, y el cliente es CONSUMIDOR FINAL, debe indicar un c�digo de cliente v�lido.','exclamation')
				NEXT FIELD r19_codcli
			END IF
		ELSE 
			NEXT FIELD r19_num_dev
		END IF
        AFTER FIELD r19_codcli
		IF r_r19.r19_codcli IS NOT NULL AND 
			rm_r19.r19_codcli IS NULL THEN
                	LET rm_r19.r19_codcli = r_r19.r19_codcli
			DISPLAY BY NAME rm_r19.r19_codcli
		END IF
		IF (r_r19.r19_codcli IS NULL AND
                	rm_r19.r19_codcli IS NOT NULL) OR 
			(TODAY > DATE(r_r19.r19_fecing) AND 
				r_r19.r19_codcli = rm_r00.r00_codcli_tal) OR
		    tiene_nota_entrega(vm_cod_tran, rm_r19.r19_num_dev)
		THEN
			CALL fl_lee_cliente_general(rm_r19.r19_codcli)
        			RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD r19_codcli
			END IF
			IF r_z01.z01_estado = 'B' THEN
				--CALL fgl_winmessage(vg_producto,'Cliente est� bloqueado.','exclamation')
				CALL fl_mostrar_mensaje('Cliente est� bloqueado.','exclamation')
				NEXT FIELD r19_codcli
			END IF
			CALL fl_lee_compania_repuestos(vg_codcia)  
        			RETURNING rm_r00.*                
			IF rm_r19.r19_codcli = rm_r00.r00_codcli_tal THEN
				CALL fl_mostrar_mensaje('El codigo del cliente no puede ser el del consumidor final.','exclamation')
				NEXT FIELD r19_codcli
			END IF
			LET rm_r19.r19_nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_r19.r19_nomcli
		ELSE
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							    vg_codloc,
							    vm_cod_tran,
							    rm_r19.r19_num_dev)
				RETURNING r_r19.*
                	LET rm_r19.r19_codcli = r_r19.r19_codcli
			DISPLAY BY NAME rm_r19.r19_codcli
			LET rm_r19.r19_nomcli = r_r19.r19_nomcli
			DISPLAY BY NAME rm_r19.r19_nomcli
                END IF
	AFTER INPUT
               	IF rm_r19.r19_codcli IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar c�digo del cliente.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar c�digo del cliente.','exclamation')
			NEXT FIELD r19_codcli
		END IF
		IF (TODAY > DATE(r_r19.r19_fecing) AND 
		   rm_r19.r19_codcli = rm_r00.r00_codcli_tal) THEN
			CALL fl_mostrar_mensaje('El codigo del cliente no puede ser el del consumidor final.','exclamation')
			NEXT FIELD r19_codcli
		END IF
		IF r19_referencia IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'Debe ingresar motivo de la devoluci�n.','exclamation')
			CALL fl_mostrar_mensaje('Debe ingresar motivo de la devoluci�n.','exclamation')
			NEXT FIELD r19_referencia
		END IF
		LET rm_r19.r19_referencia = r19_referencia
END INPUT
LET rm_fact.* = rm_r19.*

END FUNCTION



FUNCTION control_DISPLAY_cabecera()

DISPLAY BY NAME rm_r19.r19_moneda,     rm_r19.r19_num_dev, 
		rm_r19.r19_porc_impto, 
		rm_r19.r19_codcli,     rm_r19.r19_nomcli,
		rm_r19.r19_vendedor ,
		rm_r19.r19_referencia

CALL fl_lee_moneda(rm_r19.r19_moneda)
	RETURNING rm_g13.*
	DISPLAY rm_g13.g13_nombre TO nom_moneda

CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
	RETURNING rm_r01.*
	DISPLAY rm_r01.r01_nombres TO nom_vendedor

END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j,k,ind	SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_r02		RECORD LIKE rept002.*

LET rm_r19.r19_tot_neto = 0
OPTIONS 
	--INPUT NO WRAP,
	INSERT KEY F30,
	DELETE KEY F31

CALL retorna_tam_arr()
WHILE TRUE
	LET i = 1
	LET j = 1
	LET int_flag = 0
	CALL set_count(vm_ind_arr)
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN 0
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT 
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()   # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()   # POSICION CORRIENTE EN LA PANTALLA

			IF r_detalle[i].r20_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, 
						 r_detalle[i].r20_item)
					RETURNING rm_r10.*
				CALL muestra_descripciones(r_detalle[i].r20_item,
					rm_r10.r10_linea, rm_r10.r10_sub_linea,
					rm_r10.r10_cod_grupo, 
					rm_r10.r10_cod_clase)
				DISPLAY rm_r10.r10_nombre TO nom_item
			END IF
		BEFORE INSERT
			EXIT INPUT
		AFTER FIELD r20_cant_dev
			IF r_detalle[i].r20_cant_dev IS NOT NULL THEN
				IF r_detalle[i].r20_cant_dev > 
				   r_detalle[i].r20_cant_ven
				THEN
					CALL fl_mostrar_mensaje('La cantidad devuelta es superior a la vendida. Debe ingresar cantidades iguales o menores a la vendida.','exclamation')
					NEXT FIELD r20_cant_dev
				END IF
				CALL fl_lee_bodega_rep(vg_codcia,
						r_detalle[i].r20_bodega)
					RETURNING r_r02.*
				IF r_r02.r02_tipo = 'S' AND
				   r_detalle[i].r20_cant_dev <> 0
				THEN
					LET r_detalle[i].r20_cant_dev =
						r_detalle[i].r20_cant_ven
					DISPLAY r_detalle[i].r20_cant_dev TO
						r_detalle[j].r20_cant_dev
				END IF
				LET k = i - j + 1
				CALL calcula_totales(arr_count(),k)
				DISPLAY r_detalle[i].subtotal_item TO
					r_detalle[j].subtotal_item
			END IF
		AFTER INPUT
			IF rm_r19.r19_tot_neto = 0 THEN
				--CALL fgl_winmessage(vg_producto,'Digite cantidad a devolver. ','exclamation')
				CALL fl_mostrar_mensaje('Digite cantidad a devolver. ','exclamation')
				NEXT FIELD r20_cant_dev
			END IF  
			EXIT WHILE

	END INPUT
	IF int_flag THEN
		EXIT WHILE
		
	END IF

END WHILE

RETURN vm_ind_arr

END FUNCTION



FUNCTION calcula_totales(ind, ind_2)
DEFINE ind,k		SMALLINT
DEFINE ind_2,y	SMALLINT

LET rm_r19.r19_tot_costo     = 0	-- TOTAL COSTO 
LET rm_r19.r19_tot_bruto     = 0	-- TOTAL BRUTO 
LET rm_r19.r19_tot_dscto      = 0	-- TOTAL DEL DESCUENTO
LET rm_r19.r19_tot_neto      = 0 	-- TOTAL NETO
LET vm_impuesto  = 0 	-- TOTAL DEL IMPUESTO

FOR k = 1 TO ind
		
	LET r_detalle_1[k].val_costo = r_detalle[k].r20_cant_dev * 
				       r_detalle_1[k].r20_costo
	LET rm_r19.r19_tot_costo = rm_r19.r19_tot_costo +
				   r_detalle_1[k].val_costo 

	LET r_detalle[k].subtotal_item = r_detalle[k].r20_precio *  
				         r_detalle[k].r20_cant_dev
	LET rm_r19.r19_tot_bruto = rm_r19.r19_tot_bruto + 
				   r_detalle[k].subtotal_item 

	LET r_detalle_1[k].r20_val_descto = r_detalle[k].r20_cant_dev  *
					    r_detalle[k].r20_precio    * 
					    r_detalle[k].r20_descuento / 100  

	LET rm_r19.r19_tot_dscto = rm_r19.r19_tot_dscto + 
				   r_detalle_1[k].r20_val_descto

	LET r_detalle_1[k].r20_val_impto =
	    (r_detalle[k].subtotal_item - r_detalle_1[k].r20_val_descto)
	    * rm_r19.r19_porc_impto     / 100

	LET vm_impuesto = vm_impuesto + r_detalle_1[k].r20_val_impto

END FOR

LET vm_impuesto = fl_retorna_precision_valor(rm_r19.r19_moneda, vm_impuesto)

LET rm_r19.r19_tot_dscto = fl_retorna_precision_valor(rm_r19.r19_moneda, 
						      rm_r19.r19_tot_dscto)

LET y = ind_2
FOR k = 1 TO vm_size_arr
	DISPLAY r_detalle[y].r20_descuento TO r_detalle[k].r20_descuento
	IF y = ind THEN
		EXIT FOR
	END IF 
	LET y = y + 1
END FOR

LET vm_impuesto = (rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto) *
		  rm_r19.r19_porc_impto / 100 	
LET vm_impuesto = fl_retorna_precision_valor(rm_r19.r19_moneda, vm_impuesto)

LET rm_r19.r19_tot_neto = rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto +
			  vm_impuesto 
DISPLAY BY NAME rm_r19.r19_tot_bruto, rm_r19.r19_tot_dscto, 
		vm_impuesto, rm_r19.r19_tot_neto
LET rm_r19.r19_flete = 0
IF rm_r19.r19_tot_neto + rm_fact.r19_flete = rm_fact.r19_tot_neto THEN
	LET rm_r19.r19_flete = rm_fact.r19_flete
	LET rm_r19.r19_tot_neto = rm_r19.r19_tot_neto + rm_fact.r19_flete
END IF	

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1500)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE mensaje		VARCHAR(100)

LET vm_flag_mant = 'C'

CLEAR FORM

LET rm_r19.r19_cod_tran = vm_cod_tran_2
LET rm_r19.r19_tipo_dev = vm_cod_tran
DISPLAY BY NAME rm_r19.r19_cod_tran, rm_r19.r19_tipo_dev

CALL control_DISPLAY_botones()

IF num_args() = 4 THEN
	LET INT_FLAG = 0
	CONSTRUCT BY NAME expr_sql 
		  ON r19_cod_tran, r19_num_tran,   r19_num_dev,  r19_moneda,   
		     r19_codcli,   r19_nomcli,   
		     r19_vendedor, 
		     r19_porc_impto
	BEFORE CONSTRUCT
		DISPLAY vm_cod_dev TO r19_cod_tran
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r19_num_dev) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      vm_cod_tran)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli 

		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				LET rm_r19.r19_num_dev = rm_r19.r19_num_tran
				DISPLAY BY NAME rm_r19.r19_num_dev
		      	END IF
		END IF
		IF INFIELD(r19_num_tran) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      vm_cod_tran_2)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli 
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							    vg_codloc,
							    vm_cod_tran_2,
							    r_r19.r19_num_tran)
					RETURNING rm_r19.*
				DISPLAY BY NAME rm_r19.r19_num_tran
				CALL control_DISPLAY_cabecera()
			END IF
		END IF
		IF INFIELD(r19_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_r19.r19_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_r19.r19_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
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
		IF INFIELD(r19_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r19.r19_codcli = rm_c02.z02_codcli
				LET rm_r19.r19_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r19.r19_codcli,
						rm_r19.r19_nomcli
			END IF 
		END IF
		LET int_flag = 0
	AFTER FIELD r19_cod_tran
		LET rm_r19.r19_cod_tran = get_fldbuf(r19_cod_tran)
		IF rm_r19.r19_cod_tran <> vm_cod_dev AND 
			rm_r19.r19_cod_tran <> vm_cod_anu THEN
			LET mensaje = 'Solo puede poner ' ||
					'tipos: ' || vm_cod_dev ||
					' y ' || vm_cod_anu
			--CALL fgl_winmessage(vg_producto,mensaje,'exclamation')
			CALL fl_mostrar_mensaje(mensaje,'exclamation')
			DISPLAY vm_cod_dev TO r19_cod_tran
			NEXT FIELD r19_cod_tran
		END IF
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = ' r19_cod_tran = "', vg_cod_tran, '" AND ',
		       ' r19_num_tran = ',vg_num_tran
END IF

LET query = 'SELECT *, ROWID FROM rept019 ',
		' WHERE r19_compania  = ', vg_codcia,
		'   AND r19_localidad = ', vg_codloc,
		'   AND r19_cod_tran IN ("', vm_cod_dev, '", "', vm_cod_anu,
					'", "', vm_cod_tran, '")',
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
	IF num_args() = 6 THEN
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

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r19.* FROM rept019 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

LET vm_impuesto = rm_r19.r19_tot_neto - rm_r19.r19_flete -  
		  (rm_r19.r19_tot_bruto - rm_r19.r19_tot_dscto)

	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r19.r19_cod_tran,   rm_r19.r19_num_tran,
		rm_r19.r19_vendedor,  
		rm_r19.r19_tot_neto,   rm_r19.r19_moneda, 
		rm_r19.r19_porc_impto, rm_r19.r19_codcli,
		rm_r19.r19_nomcli,     
		rm_r19.r19_tot_bruto,  rm_r19.r19_tot_dscto, vm_impuesto,
		rm_r19.r19_tipo_dev,   rm_r19.r19_num_dev, rm_r19.r19_fecing ,
		rm_r19.r19_referencia

CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(400)

CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET query = 'SELECT r20_cant_ven, r20_cant_dev, r20_bodega, r20_item, ',
		    'r20_descuento, ',
		    'r20_precio, r20_precio * r20_cant_ven ',
		    'r20_val_impto FROM rept020 ',
            	'WHERE r20_compania  =  ', vg_codcia, 
	    	'  AND r20_localidad =  ', vg_codloc,
            	'  AND r20_cod_tran  = "', rm_r19.r19_cod_tran,'"',
            	'  AND r20_num_tran  = ', rm_r19.r19_num_tran
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO r_detalle[i].*
	INITIALIZE r_detalle[i].r20_cant_dev TO NULL  -- PARA NO MOSTRAR NADA
						      -- EN LA EN EL DETALLE
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

IF vm_ind_arr <= vm_size_arr THEN 
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

IF vm_flag_mant <> 'C' THEN
	LET vm_flag_mant = 'C'
	CALL control_DISPLAY_botones()
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

IF vm_flag_mant <> 'C' THEN
	LET vm_flag_mant = 'C'
	CALL control_DISPLAY_botones()
END IF

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()

CALL fl_lee_moneda(rm_r19.r19_moneda)
	RETURNING rm_g13.*
	DISPLAY rm_g13.g13_nombre TO nom_moneda
CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
	RETURNING rm_r01.*
	DISPLAY rm_r01.r01_nombres TO nom_vendedor

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r70.r70_desc_sub   TO descrip_1
DISPLAY r_r71.r71_desc_grupo TO descrip_2
DISPLAY r_r72.r72_desc_clase TO descrip_3

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
DEFINE num_dev		VARCHAR(15)
DEFINE valor_credito	DECIMAL(14,2)	
DEFINE valor_aplicado	DECIMAL(14,2)	
DEFINE inserta_nc	SMALLINT
DEFINE tot_saldo_doc	DECIMAL(14,2)

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
INITIALIZE r_nc.* TO NULL
CALL fl_mostrar_mensaje('Ingrese el No. Pre-Impreso de la Nota Cr�dito.','info')
LET int_flag = 0
INPUT BY NAME r_nc.z21_num_sri
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		CONTINUE INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END INPUT
LET num_dev		= rm_r19.r19_num_dev
LET r_nc.z21_compania 	= vg_codcia
LET r_nc.z21_localidad 	= vg_codloc
LET r_nc.z21_codcli 	= rm_r19.r19_codcli 
LET r_nc.z21_tipo_doc 	= 'NC'
LET r_nc.z21_areaneg 	= r_glin.g20_areaneg
LET r_nc.z21_linea  	= r_glin.g20_grupo_linea
LET r_nc.z21_referencia = 'DEV. FACTURA: ', rm_r19.r19_tipo_dev, '-',
			   num_dev CLIPPED
LET r_nc.z21_fecha_emi 	= TODAY
LET r_nc.z21_moneda 	= rm_r19.r19_moneda
LET r_nc.z21_paridad 	= 1
IF r_nc.z21_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_nc.z21_moneda, rg_gen.g00_moneda_base)
		RETURNING r.*
	IF r.g14_serial IS NULL THEN
		ROLLBACK WORK
		--CALL fgl_winmessage(vg_producto,'No hay factor de conversi�n.','stop')
		CALL fl_mostrar_mensaje('No hay factor de conversi�n.','stop')
		EXIT PROGRAM
	END IF
	LET r_nc.z21_paridad 	= r.g14_tasa
END IF	
LET valor_credito       = rm_r19.r19_tot_neto
LET r_nc.z21_val_impto 	= vm_impuesto
LET r_nc.z21_valor 	= valor_credito
LET r_nc.z21_saldo 	= valor_credito
LET r_nc.z21_subtipo 	= 1
LET r_nc.z21_origen 	= 'A'
LET r_nc.z21_cod_tran   = rm_r19.r19_cod_tran
LET r_nc.z21_num_tran   = rm_r19.r19_num_tran
LET r_nc.z21_usuario 	= vg_usuario
LET r_nc.z21_fecing 	= CURRENT
LET inserta_nc = 1
IF rm_r19.r19_cod_tran = vm_cod_anu THEN
	SELECT SUM(z20_saldo_cap + z20_saldo_int) INTO tot_saldo_doc 
		FROM cxct020 
		WHERE z20_compania  = vg_codcia AND 
	              z20_localidad = vg_codloc AND 
	              z20_areaneg   = r_glin.g20_areaneg  AND
	              z20_cod_tran  = rm_r19.r19_tipo_dev AND 
	              z20_num_tran  = rm_r19.r19_num_dev
	IF valor_credito <= tot_saldo_doc THEN 
		LET inserta_nc 		= 0
		LET r_nc.z21_tipo_doc 	= NULL
		LET r_nc.z21_num_doc 	= NULL
	END IF
END IF
LET num_row = 0
IF inserta_nc THEN
	--IF TODAY = DATE(rm_fact.r19_fecing) AND
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', 'NC')
		RETURNING num_nc
	IF num_nc <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_nc.z21_num_doc 	= num_nc 
	IF rm_r19.r19_codcli = rm_r00.r00_codcli_tal THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Se va a generar NC, y el cliente es CONSUMIDOR FINAL, debe indicar un c�digo de cliente v�lido.','stop')
		EXIT PROGRAM
	END IF
	INSERT INTO cxct021 VALUES (r_nc.*)
	LET num_row = SQLCA.SQLERRD[6]
END IF
CALL fl_aplica_documento_favor(vg_codcia, vg_codloc, r_nc.z21_codcli, 
			    r_nc.z21_tipo_doc, r_nc.z21_num_doc, valor_credito,
			    r_nc.z21_moneda, r_glin.g20_areaneg,
			    rm_r19.r19_tipo_dev, rm_r19.r19_num_dev)  
	RETURNING valor_aplicado
IF valor_aplicado < 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF inserta_nc THEN
	UPDATE cxct021 SET z21_saldo = z21_saldo - valor_aplicado
		WHERE ROWID = num_row
END IF
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_nc.z21_codcli)

END FUNCTION



FUNCTION actualiza_ordenes_despacho()
DEFINE cant_ent, cant_ven	DECIMAL (8,2)
DEFINE cant_dev, saldo		DECIMAL (8,2)
DEFINE r_r20          		RECORD LIKE rept020.*
DEFINE r_r34          		RECORD LIKE rept034.*
DEFINE mensaje			VARCHAR(100)

DECLARE q_chiripa CURSOR FOR
	SELECT * FROM rept020
		WHERE r20_compania  = rm_r19.r19_compania  AND
		      r20_localidad = rm_r19.r19_localidad AND
		      r20_cod_tran  = rm_r19.r19_tipo_dev  AND
		      r20_num_tran  = rm_r19.r19_num_dev
LET cant_ent = 0
LET cant_ven = 0
FOREACH q_chiripa INTO r_r20.*
	LET cant_ent = cant_ent + r_r20.r20_cant_ent
	LET cant_ven = cant_ven + r_r20.r20_cant_ven
END FOREACH 
IF cant_ven = cant_ent THEN
	RETURN
END IF
DECLARE q_chicho CURSOR FOR
	SELECT * FROM rept020
		WHERE r20_compania  = rm_r19.r19_compania  AND
		      r20_localidad = rm_r19.r19_localidad AND
		      r20_cod_tran  = rm_r19.r19_cod_tran  AND
		      r20_num_tran  = rm_r19.r19_num_tran
LET cant_dev = 0
FOREACH q_chicho INTO r_r20.*
	LET cant_dev = cant_dev + r_r20.r20_cant_ven
END FOREACH 
IF cant_dev = cant_ven AND cant_ent = 0 THEN
	UPDATE rept034 SET r34_estado = 'E'
		WHERE r34_compania  = rm_r19.r19_compania  AND 
		      r34_localidad = rm_r19.r19_localidad AND 
		      r34_cod_tran  = rm_r19.r19_tipo_dev  AND 
		      r34_num_tran  = rm_r19.r19_num_dev
	RETURN
END IF
FOREACH q_chicho INTO r_r20.*
	SELECT * INTO r_r34.* FROM rept034
		WHERE r34_compania    = rm_r19.r19_compania  AND
		      r34_localidad   = rm_r19.r19_localidad AND
		      r34_cod_tran    = rm_r19.r19_tipo_dev  AND 
		      r34_num_tran    = rm_r19.r19_num_dev   AND
		      r34_bodega      = r_r20.r20_bodega     AND 
		      r34_estado <> 'E'
	IF status = NOTFOUND THEN
		RETURN
	END IF
	DECLARE up_dod CURSOR FOR
		SELECT r35_cant_des - r35_cant_ent
			FROM rept035
			WHERE r35_compania    = rm_r19.r19_compania   AND
		              r35_localidad   = rm_r19.r19_localidad  AND
		              r35_bodega      = r_r34.r34_bodega      AND 
		              r35_num_ord_des = r_r34.r34_num_ord_des AND 
		              r35_item        = r_r20.r20_item        AND
		              r35_orden       = r_r20.r20_orden
			FOR UPDATE
	OPEN up_dod
	FETCH up_dod INTO saldo
	IF status = NOTFOUND THEN
		ROLLBACK WORK
		LET mensaje = 'No se encontr� item '
				|| 'devuelto: ' || r_r20.r20_item 
				|| ' en O.D. '  || r_r34.r34_num_ord_des
				|| '. No se grab� devoluci�n.'
		--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	IF saldo = 0 THEN
		CONTINUE FOREACH
	END IF 
	IF r_r20.r20_cant_ven > saldo THEN
		CONTINUE FOREACH
	END IF
	UPDATE rept035 SET r35_cant_des = r35_cant_des - r_r20.r20_cant_ven
		WHERE CURRENT OF up_dod
END FOREACH	

END FUNCTION



FUNCTION cargar_temp(i)
DEFINE i		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r36		RECORD LIKE rept036.*
DEFINE r_r37		RECORD LIKE rept037.*
DEFINE cant		LIKE rept037.r37_cant_ent
DEFINE cant_dev		LIKE rept020.r20_cant_dev

DECLARE q_retorno CURSOR FOR
	SELECT rept036.*, rept037.*
		FROM rept034, rept036, rept037
		WHERE r34_compania    = vg_codcia
		  AND r34_localidad   = vg_codloc
		  AND r34_cod_tran    = rm_r19.r19_tipo_dev
		  AND r34_num_tran    = rm_r19.r19_num_dev
		  AND r36_compania    = r34_compania
		  AND r36_localidad   = r34_localidad
		  AND r36_bodega      = r34_bodega
		  AND r36_num_ord_des = r34_num_ord_des
		  AND r37_compania    = r36_compania
		  AND r37_localidad   = r36_localidad
		  AND r37_bodega      = r36_bodega
		  AND r37_num_entrega = r36_num_entrega
		  AND r37_item        = r_detalle[i].r20_item
		ORDER BY r37_cant_ent DESC
OPEN q_retorno
LET cant = 0
FOREACH q_retorno INTO r_r36.*, r_r37.*
	CALL fl_lee_bodega_rep(vg_codcia, r_r36.r36_bodega) RETURNING r_r02.*
	IF r_r02.r02_tipo <> 'S' THEN
		CONTINUE FOREACH
	END IF
	LET cant_dev = r_r37.r37_cant_ent
	IF r_r37.r37_cant_ent > r_detalle[i].r20_cant_dev THEN
		LET cant_dev = r_detalle[i].r20_cant_dev
	END IF
	LET cant = cant + cant_dev
	INSERT INTO tmp_item_ret
		VALUES(r_r37.r37_num_entrega, r_r36.r36_bodega_real,
			r_detalle[i].r20_bodega, r_detalle[i].r20_item,
			cant_dev, r_r37.r37_cant_ent)
	IF cant >= r_detalle[i].r20_cant_dev THEN
		EXIT FOREACH
	END IF
END FOREACH

END FUNCTION



FUNCTION transferencia_retorno()
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE cantidad		LIKE rept037.r37_cant_ent
DEFINE r_item		RECORD
				nota_ent	LIKE rept036.r36_num_entrega,
				bodega_real	LIKE rept002.r02_codigo,
				bodega_fact	LIKE rept002.r02_codigo,
				item		LIKE rept010.r10_codigo,
				cant_dev	LIKE rept020.r20_cant_dev,
				cant_ent	LIKE rept037.r37_cant_ent
			END RECORD
DEFINE r_fact		RECORD LIKE rept019.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r02_real	RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE j		SMALLINT
DEFINE mensaje		VARCHAR(100)

DECLARE q_vend CURSOR FOR
	SELECT * FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_tipo_dev  = rm_r19.r19_tipo_dev
	  AND r19_num_dev   = rm_r19.r19_num_dev
OPEN q_vend
FETCH q_vend INTO r_fact.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe factura.', 'stop')
	EXIT PROGRAM
END IF
DECLARE q_tmp CURSOR FOR SELECT UNIQUE bodega_real FROM tmp_item_ret
OPEN q_tmp
FOREACH q_tmp INTO bodega
	{-- PARA QUE REALIZE TRANSF. DE LA BOD. REAL OTRA LOC. A LA DEFAULT
	CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_r02.*
	IF r_r02.r02_localidad <> vg_codloc THEN
		CONTINUE FOREACH
	END IF
	--}
	DECLARE q_tmp1 CURSOR FOR
		SELECT * FROM tmp_item_ret WHERE bodega_real = bodega
	OPEN q_tmp1
	FETCH q_tmp1 INTO r_item.*
	CLOSE q_tmp1
	FREE q_tmp1
	CALL fl_lee_bodega_rep(vg_codcia, r_item.bodega_real)
		RETURNING r_r02_real.*
	IF r_r02_real.r02_localidad <> vg_codloc THEN
		LET r_item.bodega_real = rm_r00.r00_bodega_fact
	END IF
	INITIALIZE r_r19.* TO NULL
	LET r_r19.r19_compania	= vg_codcia
	LET r_r19.r19_localidad	= vg_codloc
	LET r_r19.r19_cod_tran 	= 'TR'
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', r_r19.r19_cod_tran)
		RETURNING r_r19.r19_num_tran
	IF r_r19.r19_num_tran = 0 THEN
		ROLLBACK WORK	
		CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacci�n, no se puede asignar un n�mero de transacci�n a la operaci�n.','stop')
		EXIT PROGRAM
	END IF
	IF r_r19.r19_num_tran = -1 THEN
		SET LOCK MODE TO WAIT
		WHILE r_r19.r19_num_tran = -1
			CALL fl_actualiza_control_secuencias(vg_codcia,
						vg_codloc, vg_modulo, 'AA',
						r_r19.r19_cod_tran)
				RETURNING r_r19.r19_num_tran
		END WHILE
		SET LOCK MODE TO NOT WAIT
	END IF
	LET r_r19.r19_cont_cred	 = 'C'
	LET r_r19.r19_referencia = 'GEN. DEV/ANU # ', rm_r19.r19_num_tran
					USING "<<<<<<<&", ' NE # ',
					r_item.nota_ent USING "<<<<<<<&"
	LET r_r19.r19_nomcli     = ' '
	LET r_r19.r19_dircli     = ' '
	LET r_r19.r19_cedruc     = ' '
	LET r_r19.r19_vendedor   = r_fact.r19_vendedor
	LET r_r19.r19_descuento  = 0.0
	LET r_r19.r19_porc_impto = 0.0
	LET r_r19.r19_bodega_ori = r_item.bodega_fact
	LET r_r19.r19_bodega_dest= r_item.bodega_real 
	LET r_r19.r19_moneda     = rg_gen.g00_moneda_base
	LET r_r19.r19_precision  = rg_gen.g00_decimal_mb
	LET r_r19.r19_paridad    = 1
	LET r_r19.r19_tot_costo  = 0
	LET r_r19.r19_tot_bruto  = 0.0
	LET r_r19.r19_tot_dscto  = 0.0
	LET r_r19.r19_tot_neto	 = r_r19.r19_tot_costo
	LET r_r19.r19_flete      = 0.0
	LET r_r19.r19_usuario    = vg_usuario
	LET r_r19.r19_fecing     = CURRENT
	INSERT INTO rept019 VALUES (r_r19.*)
	INITIALIZE r_r20.* TO NULL
	LET r_r20.r20_compania	 = vg_codcia
	LET r_r20.r20_localidad  = vg_codloc
	LET r_r20.r20_cod_tran   = r_r19.r19_cod_tran
	LET r_r20.r20_num_tran   = r_r19.r19_num_tran
	LET r_r20.r20_cant_ent   = 0 
	LET r_r20.r20_cant_dev   = 0
	LET r_r20.r20_descuento  = 0.0
	LET r_r20.r20_val_descto = 0.0
	LET r_r20.r20_val_impto  = 0.0
	LET r_r20.r20_ubicacion  = 'SN'
	DECLARE q_tmp2 CURSOR FOR
		SELECT item, SUM(cant_dev) FROM tmp_item_ret
			WHERE bodega_real = bodega
			GROUP BY 1
	LET j        = 1
	LET cantidad = 0
	FOREACH q_tmp2 INTO r_item.item, cantidad
		CALL fl_lee_item(vg_codcia, r_item.item) RETURNING r_r10.*
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo + 
				  (cantidad * r_r10.r10_costo_mb)
		LET r_r20.r20_cant_ped   = cantidad
		LET r_r20.r20_cant_ven   = cantidad
		LET r_r20.r20_bodega     = r_r19.r19_bodega_ori
		LET r_r20.r20_item       = r_item.item 
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
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori,
					r_item.item)
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET r_r20.r20_stock_ant  = r_r11.r11_stock_act 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
					r_item.item)
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET r_r20.r20_stock_bd   = r_r11.r11_stock_act 
		LET r_r20.r20_fecing	 = CURRENT
		INSERT INTO rept020 VALUES(r_r20.*)
		LET r_r19.r19_tot_costo  = r_r19.r19_tot_costo +
					  (r_r20.r20_cant_ven * r_r20.r20_costo)
		LET r_r19.r19_tot_neto   = r_r19.r19_tot_neto +
					 (r_r20.r20_cant_ven * r_r20.r20_precio)
		UPDATE rept011 SET r11_stock_act = r11_stock_act - cantidad,
			           r11_egr_dia   = r11_egr_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_ori
			  AND r11_item     = r_item.item 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
					r_item.item)
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			INSERT INTO rept011
      				(r11_compania, r11_bodega, r11_item, 
			 	 r11_ubicacion, r11_stock_ant, 
			 	 r11_stock_act, r11_ing_dia,
		 		 r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
				       r_item.item, 'SN', 0, cantidad, 
				       cantidad, 0) 
		ELSE
			UPDATE rept011 SET r11_stock_act = r11_stock_act + 
				       				cantidad,
			      		   r11_ing_dia   = r11_ing_dia +
				       				cantidad
				WHERE r11_compania = vg_codcia
				  AND r11_bodega   = r_r19.r19_bodega_dest
				  AND r11_item     = r_item.item 
		END IF
	END FOREACH
	UPDATE rept019 SET r19_tot_bruto = r_r19.r19_tot_bruto,
			   r19_tot_costo = r_r19.r19_tot_costo,
			   r19_tot_neto  = r_r19.r19_tot_neto
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
	LET mensaje = 'Se genero transferencia automatica No. ',
			r_r19.r19_num_tran USING "<<<<<<<&", '. De la bodega ',
			r_r19.r19_bodega_ori, ' a la bodega ',
			r_r19.r19_bodega_dest, '.'
	CALL fl_mostrar_mensaje(mensaje, 'info')
END FOREACH

END FUNCTION



FUNCTION imprimir()
DEFINE comando		CHAR(255)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEG�N SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp401 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', rm_r19.r19_cod_tran,
	rm_r19.r19_num_tran
	
RUN comando	

END FUNCTION



FUNCTION verifica_saldo_fact_devuelta()
DEFINE r_r25		RECORD LIKE rept025.*
DEFINE saldo_fact	DECIMAL(14,2)

SELECT * INTO r_r25.* FROM rept025
	WHERE r25_compania  = rm_fact.r19_compania  AND 
	      r25_localidad = rm_fact.r19_localidad AND 
	      r25_cod_tran  = rm_fact.r19_cod_tran  AND 
	      r25_num_tran  = rm_fact.r19_num_tran
IF status = NOTFOUND THEN
	LET r_r25.r25_valor_ant  = 0
	LET r_r25.r25_valor_cred = 0
END IF
SELECT SUM(z20_saldo_cap) INTO saldo_fact FROM cxct020
	WHERE z20_compania  = rm_fact.r19_compania  AND 
	      z20_localidad = rm_fact.r19_localidad AND 
	      z20_cod_tran  = rm_fact.r19_cod_tran  AND 
	      z20_num_tran  = rm_fact.r19_num_tran  AND 
	      z20_codcli    = rm_fact.r19_codcli
IF saldo_fact IS NULL THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'Factura cr�dito no existe en m�dulo de Cobranzas. Devoluci�n no se ejecut�','stop')
	CALL fl_mostrar_mensaje('Factura cr�dito no existe en m�dulo de Cobranzas. Devoluci�n no se ejecut�','stop')
	EXIT PROGRAM
END IF	
IF r_r25.r25_valor_cred = saldo_fact THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 5
END IF

END FUNCTION



FUNCTION imprimir_nota_credito(r)
DEFINE r		RECORD LIKE cxct021.*
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', 
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp414 ', vg_base, 
	' ', 'CO', vg_codcia, ' ', vg_codloc, ' ', r.z21_codcli,
	' "', r.z21_tipo_doc, '" ', r.z21_num_doc
RUN comando	

END FUNCTION



FUNCTION verifica_pago_tarjeta_credito()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_tj		RECORD LIKE gent010.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE tipo		LIKE cxct021.z21_tipo_doc
DEFINE num  		LIKE cxct021.z21_num_doc
DEFINE valor		DECIMAL(12,2)

SELECT * INTO r_j10.* FROM cajt010
	WHERE j10_compania     = rm_fact.r19_compania     AND 
	      j10_localidad    = rm_fact.r19_localidad    AND 
	      j10_tipo_destino = rm_fact.r19_cod_tran AND 
	      j10_num_destino  = rm_fact.r19_num_tran  AND 
	      j10_tipo_fuente  = 'PR'
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe en cajt010 la factura devuelta.',
				'stop')
	EXIT PROGRAM
END IF	
SELECT * INTO r_j11.* FROM cajt011
	WHERE j11_compania    = r_j10.j10_compania    AND 
	      j11_localidad   = r_j10.j10_localidad   AND 
	      j11_tipo_fuente = r_j10.j10_tipo_fuente AND 
	      j11_num_fuente  = r_j10.j10_num_fuente  AND 
	      j11_codigo_pago = 'TJ'
IF status = NOTFOUND THEN
	RETURN
END IF
CALL fl_lee_tarjeta_credito(r_j11.j11_cod_bco_tarj) RETURNING r_tj.*
IF r_tj.g10_codcobr IS NULL THEN
	RETURN
END IF
SELECT * INTO r_z20.* FROM cxct020
	WHERE z20_compania  = vg_codcia            AND 
	      z20_localidad = vg_codloc            AND
	      z20_codcli    = r_tj.g10_codcobr     AND
	      z20_tipo_doc  = rm_fact.r19_cod_tran AND
	      z20_num_doc   = rm_fact.r19_num_tran AND
	      z20_dividendo = 1
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe en cxct020 el pago con tarjeta '
				|| 'del cliente: ' || r_tj.g10_codcobr, 'stop')
	EXIT PROGRAM
END IF
LET valor = rm_r19.r19_tot_neto
IF valor > r_z20.z20_saldo_cap THEN
	LET valor = r_z20.z20_saldo_cap
END IF
LET tipo = NULL
LET num  = NULL
CALL fl_aplica_documento_favor(vg_codcia, vg_codloc, r_tj.g10_codcobr,
			    tipo, num, valor,
			    r_j10.j10_moneda, r_j10.j10_areaneg,
			    rm_r19.r19_tipo_dev, rm_r19.r19_num_dev)  
	RETURNING num
IF num < 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_tj.g10_codcobr)

END FUNCTION



FUNCTION tiene_nota_entrega(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE r_r36		RECORD LIKE rept036.*
DEFINE tiene		SMALLINT

DECLARE q_r34 CURSOR FOR
	SELECT * FROM rept034
		WHERE r34_compania  =  vg_codcia
		  AND r34_localidad =  vg_codloc
		  AND r34_cod_tran  =  cod_tran
		  AND r34_num_tran  =  num_tran
		  AND r34_estado    <> 'E'
LET tiene = 0
FOREACH q_r34 INTO r_r34.*
	DECLARE q_r36 CURSOR FOR
		SELECT * FROM rept036
			WHERE r36_compania    =  r_r34.r34_compania
			  AND r36_localidad   =  r_r34.r34_localidad
			  AND r36_bodega      =  r_r34.r34_bodega
			  AND r36_num_ord_des =  r_r34.r34_num_ord_des
			  AND r36_estado      <> 'E'
	OPEN q_r36
	FETCH q_r36 INTO r_r36.*
	IF STATUS <> NOTFOUND THEN
		LET tiene = 1
	END IF
	CLOSE q_r36
	FREE q_r36
	IF tiene THEN
		EXIT FOREACH
	END IF
END FOREACH
RETURN tiene

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

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
DISPLAY '<F5>      Ver Factura del Cliente'  AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
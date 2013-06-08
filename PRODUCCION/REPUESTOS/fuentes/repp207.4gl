------------------------------------------------------------------------------
-- Titulo           : repp207.4gl - Liquidación de pedidos      
-- Elaboracion      : 07-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp212 base modulo compania localidad [numliq]
--		Si (numliq <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (numliq = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_numliq	LIKE rept028.r28_numliq
-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_r28		RECORD LIKE rept028.*
DEFINE vm_ind_ped	SMALLINT
DEFINE rm_pedido 	ARRAY[50] OF RECORD
				pedido		LIKE rept016.r16_pedido, 
				moneda		LIKE rept016.r16_moneda, 
				n_moneda	LIKE gent013.g13_nombre, 
				proveedor	LIKE rept016.r16_proveedor, 
				tipo		LIKE rept016.r16_tipo, 
				n_tipo		CHAR(10)
			END RECORD
DEFINE vm_ind_rub	SMALLINT
DEFINE rm_rubros 	ARRAY[100] OF RECORD
				rubro		LIKE rept030.r30_codrubro, 
				fecha		LIKE rept030.r30_fecha,	 
				moneda		LIKE rept030.r30_moneda,
				paridad		LIKE rept030.r30_paridad,
				valor		LIKE rept030.r30_valor,
				valor_ml	LIKE rept030.r30_valor,
				check		CHAR(1)
			END RECORD
DEFINE rm_r30		ARRAY[100] OF RECORD 
				serial		LIKE rept030.r30_serial,
				observacion	LIKE rept030.r30_observacion,
				orden		LIKE rept030.r30_orden
			END RECORD
DEFINE rm_pp		ARRAY[500] OF RECORD
				r17_item	LIKE rept017.r17_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r17_partida	LIKE rept017.r17_partida,
				r17_porc_part	LIKE rept017.r17_porc_part
			END RECORD
DEFINE vm_num_pp	SMALLINT
DEFINE vm_moneda_ped	LIKE rept016.r16_moneda



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp207.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)		
LET vg_proceso = 'repp207'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vm_numliq = 0 			-- igual a cero si se ejecuta en forma 
IF num_args() = 5 THEN   		-- independiente
	LET vm_numliq   = arg_val(5) 	-- <> de cero si se ejecuta en modo de 
END IF					-- solo consulta
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
SELECT * FROM rept017 WHERE r17_compania = 0 INTO TEMP te_detalle
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
OPEN WINDOW w_207 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_207 FROM '../forms/repf207_1'
ELSE
	OPEN FORM f_207 FROM '../forms/repf207_1c'
END IF
DISPLAY FORM f_207
LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r28.* TO NULL
CALL muestra_contadores()
LET vm_max_rows = 1000
IF vm_numliq <> 0 THEN
	CALL execute_query()
END IF
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		HIDE OPTION 'Cargos Locales'
		HIDE OPTION 'Ver pedidos'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Detalle Costeo'
		HIDE OPTION 'Aranceles'
		IF vm_numliq <> 0 THEN          -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			IF vm_num_rows = 1 THEN
				SHOW OPTION 'Cargos Locales'
				SHOW OPTION 'Ver pedidos'
				SHOW OPTION 'Detalle Costeo'
				SHOW OPTION 'Aranceles'
				SHOW OPTION 'Imprimir'
			END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cargos Locales'
			SHOW OPTION 'Ver pedidos'
			SHOW OPTION 'Imprimir'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cargos Locales'
			SHOW OPTION 'Ver pedidos'
			SHOW OPTION 'Detalle Costeo'
			SHOW OPTION 'Aranceles'
			SHOW OPTION 'Imprimir'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
				HIDE OPTION 'Cargos Locales'
				HIDE OPTION 'Ver pedidos'
				HIDE OPTION 'Detalle Costeo'
				HIDE OPTION 'Aranceles'
			END IF
		ELSE
			SHOW OPTION 'Detalle Costeo'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Eliminar'
			SHOW OPTION 'Cargos Locales'
			SHOW OPTION 'Ver pedidos'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Aranceles'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('E') 'Eliminar' 		'Eliminar registro corriente.'
		CALL control_eliminacion()
	COMMAND KEY('P') 'Ver pedidos'		'Ver pedidos.'
		CALL ingresa_pedidos('C')
	COMMAND KEY('U') 'Cargos Locales'	'Ingresar cargos locales.'
		CALL ingresa_rubros()
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	COMMAND KEY('X') 'Aranceles'
		CALL lee_partidas_aranceles('C')
	COMMAND KEY('J') 'Detalle Costeo'
		CALL muestra_costeo_detallado()
	COMMAND KEY('K') 'Imprimir' 'Imprimir la Liquidación.'
		CALL control_imprimir_liquidacion()
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




FUNCTION control_imprimir_liquidacion()
DEFINE command_run 	VARCHAR(200)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
LET command_run = run_prog || 'repp408 ' || vg_base || ' ' || vg_modulo ||
			' ' || vg_codcia || ' ' || vg_codloc || ' ' || 
			rm_r28.r28_numliq
RUN command_run

END FUNCTION



FUNCTION control_ingreso()
DEFINE done, i 		SMALLINT
DEFINE rowid   		INTEGER
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_g14		RECORD LIKE gent014.*

CLEAR FORM
INITIALIZE rm_r28.* TO NULL
FOR i = 1 TO 50
	INITIALIZE rm_pedido[i].* TO NULL
END FOR
FOR i = 1 TO 100
	INITIALIZE rm_rubros[i].* TO NULL
END FOR
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*
IF r_r00.r00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada una compañía en el modulo de INVENTARIO.','stop')
	EXIT PROGRAM
END IF
LET vm_ind_ped = 0 
LET rm_r28.r28_compania     = vg_codcia
LET rm_r28.r28_localidad    = vg_codloc
LET rm_r28.r28_estado       = 'A'
LET rm_r28.r28_flag_flete   = 'F'
LET rm_r28.r28_moneda       = rg_gen.g00_moneda_base
LET rm_r28.r28_paridad      = 1
LET rm_r28.r28_bodega       = r_r00.r00_bodega_fact
LET rm_r28.r28_margen_uti   = 0.0 
LET rm_r28.r28_fact_costo   = 0.0 
LET rm_r28.r28_tot_exfab_mi = 0.0 
LET rm_r28.r28_tot_exfab_mb = 0.0 
LET rm_r28.r28_tot_iva      = 0.0 
LET rm_r28.r28_tot_desp_mi  = 0.0 
LET rm_r28.r28_tot_desp_mb  = 0.0 
LET rm_r28.r28_tot_fob_mi   = 0.0 
LET rm_r28.r28_tot_fob_mb   = 0.0 
LET rm_r28.r28_tot_flete    = 0.0 
LET rm_r28.r28_tot_flet_cae = 0.0 
LET rm_r28.r28_tot_seguro   = 0.0 
LET rm_r28.r28_tot_seg_neto = 0.0 
LET rm_r28.r28_tot_cif      = 0.0 
LET rm_r28.r28_tot_arancel  = 0.0 
LET rm_r28.r28_tot_salvagu  = 0.0 
LET rm_r28.r28_tot_cargos   = 0.0 
LET rm_r28.r28_tot_costimp  = 0.0 
LET rm_r28.r28_fecha_lleg   = TODAY
LET rm_r28.r28_fecha_ing    = TODAY
LET rm_r28.r28_fecing       = CURRENT
LET rm_r28.r28_usuario      = vg_usuario
IF vg_gui = 0 THEN
	CALL muestra_flag_flete(rm_r28.r28_flag_flete)
END IF
CALL muestra_etiquetas()
BEGIN WORK
CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	ROLLBACK WORK
	RETURN
END IF
SELECT MAX(r28_numliq) INTO rm_r28.r28_numliq
	FROM rept028
	WHERE r28_compania  = vg_codcia
	  AND r28_localidad = vg_codloc
IF rm_r28.r28_numliq IS NULL THEN
	LET rm_r28.r28_numliq = 1
ELSE
	LET rm_r28.r28_numliq = rm_r28.r28_numliq + 1
END IF  
LET rm_r28.r28_codprov   = rm_pedido[1].proveedor
LET rm_r28.r28_fecha_ing = CURRENT
INSERT INTO rept028 VALUES (rm_r28.*)
DISPLAY BY NAME rm_r28.r28_numliq
LET rowid  = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila procesada
CALL actualiza_detalle_pedidos()
LET done = graba_pedidos()
IF NOT done THEN
	ROLLBACK WORK
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	ELSE
		CLEAR FORM
		CALL muestra_contadores()
	END IF
	RETURN
END IF
COMMIT WORK
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



FUNCTION control_modificacion()
DEFINE done 		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_r28.r28_estado = 'P' THEN
	--CALL fgl_winmessage(vg_producto,'Esta liquidación ya fue cerrada y no puede ser modificada.','exclamation')
	CALL fl_mostrar_mensaje('Esta liquidación ya fue cerrada y no puede ser modificada.','exclamation')
	RETURN
END IF
IF rm_r28.r28_estado <> 'A' THEN
	--CALL fgl_winmessage(vg_producto,'Esta liquidación no está activa', 'exclamation')
	CALL fl_mostrar_mensaje('Esta liquidación no está activa.', 'exclamation')
	RETURN
END IF
LET vm_ind_ped = lee_pedidos()
CALL lee_muestra_registro(vm_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR 
	SELECT * FROM rept028 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_r28.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  
WHENEVER ERROR STOP
LET vm_ind_rub = lee_detalle()
CALL lee_datos('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 
UPDATE rept028 SET * = rm_r28.* WHERE CURRENT OF q_upd
CALL actualiza_detalle_pedidos()
LET done = graba_pedidos()
IF NOT done THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
COMMIT WORK
CLOSE q_upd
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r28.r28_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('No puede eliminar una liquidación que no esté ACTIVA.', 'exclamation')
	RETURN
END IF
CALL fl_hacer_pregunta('Esta seguro de eliminar esta liquidación ?.', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 0
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_eli CURSOR FOR 
	SELECT * FROM rept028
		WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_eli
FETCH q_eli INTO rm_r28.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe esta Liquidación. Pedir ayuda al administrador', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF  
WHENEVER ERROR STOP
CALL cambiar_estado_elim_pedido() RETURNING resul
IF resul THEN
	ROLLBACK WORK
	RETURN
END IF
UPDATE rept028 SET r28_estado = 'B' WHERE CURRENT OF q_eli
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error al momento de eliminar la Liquidación.', 'exclamation')
	RETURN
END IF  
CALL lee_muestra_registro(vm_rows[vm_row_current])
COMMIT WORK
CALL fl_mostrar_mensaje('Liquidación ha sido eliminada  Ok.', 'info')

END FUNCTION



FUNCTION cambiar_estado_elim_pedido()
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE r_r29		RECORD LIKE rept029.*

DECLARE q_r29_e CURSOR FOR
	SELECT * FROM rept029
		WHERE r29_compania  = vg_codcia
		  AND r29_localidad = vg_codloc
		  AND r29_numliq    = rm_r28.r28_numliq
FOREACH q_r29_e INTO r_r29.*
	CALL fl_lee_pedido_rep(r_r29.r29_compania, r_r29.r29_localidad,
				r_r29.r29_pedido)
		RETURNING r_r16.*
	IF r_r16.r16_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe un pedido.', 'exclamation')
		RETURN 1
	END IF
	IF r_r16.r16_estado <> 'L' THEN
		CONTINUE FOREACH
	END IF
	UPDATE rept016 SET r16_estado = 'R'
		WHERE r16_compania  = r_r16.r16_compania
		  AND r16_localidad = r_r16.r16_localidad
		  AND r16_pedido    = r_r16.r16_pedido
	UPDATE rept017 SET r17_estado = 'R'
		WHERE r17_compania  = r_r16.r16_compania
		  AND r17_localidad = r_r16.r16_localidad
		  AND r17_pedido    = r_r16.r16_pedido
		  AND r17_estado    = 'L'
END FOREACH
RETURN 0

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)
DEFINE moneda_ori	LIKE rept030.r30_moneda
DEFINE moneda_dest	LIKE rept028.r28_moneda
DEFINE paridad		LIKE rept030.r30_paridad   
DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
	RETURN paridad
END IF
CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) RETURNING r_g14.*
IF r_g14.g14_serial IS NULL THEN
	CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
	INITIALIZE paridad TO NULL
ELSE
	LET paridad = r_g14.g14_tasa 
END IF
RETURN paridad

END FUNCTION



FUNCTION lee_detalle()
DEFINE i		SMALLINT
DEFINE r_r30		RECORD LIKE rept030.*

DECLARE q_ing2 CURSOR FOR 
	SELECT * FROM rept030 
		WHERE r30_compania  = vg_codcia
	          AND r30_localidad = vg_codloc
	          AND r30_numliq    = rm_r28.r28_numliq
		ORDER BY r30_fecha, r30_orden
LET i = 1
FOREACH q_ing2 INTO r_r30.*
	LET rm_rubros[i].rubro    = r_r30.r30_codrubro
	LET rm_rubros[i].fecha    = r_r30.r30_fecha   
	LET rm_rubros[i].moneda   = r_r30.r30_moneda
	LET rm_rubros[i].paridad  = r_r30.r30_paridad
	LET rm_rubros[i].valor    = r_r30.r30_valor
	LET rm_rubros[i].valor_ml = 
		fl_retorna_precision_valor(rm_r28.r28_moneda,
     		r_r30.r30_valor * r_r30.r30_paridad)
	LET rm_rubros[i].check    = 'N'
	LET rm_r30[i].serial      = r_r30.r30_serial
	LET rm_r30[i].orden       = r_r30.r30_orden
	LET rm_r30[i].observacion = r_r30.r30_observacion
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1 
RETURN i

END FUNCTION



FUNCTION ingresa_rubros()
DEFINE i, j, k, salir	SMALLINT
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE mensaje		CHAR(40)
DEFINE flag		CHAR(1)
DEFINE total		LIKE rept030.r30_valor
DEFINE rubro		LIKE rept030.r30_codrubro
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g17		RECORD LIKE gent017.*
DEFINE r_r30		RECORD LIKE rept030.*
DEFINE num_cols		SMALLINT
DEFINE max_row		SMALLINT

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET num_cols = 80
IF vg_gui = 0 THEN
	LET num_cols = 78
END IF
OPEN WINDOW w_207_4 AT 06, 02 WITH 16 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_207_4 FROM '../forms/repf207_4'
ELSE
	OPEN FORM f_207_4 FROM '../forms/repf207_4c'
END IF
DISPLAY FORM f_207_4
LET total = 0
LET vm_ind_rub = lee_detalle()
LET total = total_cargos(vm_ind_rub)
-- Si el estado de la liquidacion es igual a 'P' o 
-- se esta ejecutando el programa en modo de solo consulta
-- no deben de modificarse los rubros
IF rm_r28.r28_estado = 'P' OR vm_numliq <> 0 THEN
	IF vm_ind_rub = 0 THEN
		CALL fl_mostrar_mensaje('No hay rubros ingresados en esta liquidación.','exclamation')
		CLOSE WINDOW w_207_4
		RETURN
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_rub(1, vm_ind_rub)
	END IF
	CALL set_count(vm_ind_rub)
	DISPLAY ARRAY rm_rubros TO ra_rubros.*
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
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#DISPLAY rm_r30[i].observacion TO n_rubro
			--#DISPLAY total TO total_cargos
			--#CALL muestra_contadores_rub(i, vm_ind_rub)
	END DISPLAY
	CLOSE WINDOW w_207_4
	RETURN 
END IF
OPTIONS INSERT KEY F30
LET salir = 0
WHILE NOT salir
	LET i = 1
	LET j = 1
	LET INT_FLAG = 0	
	IF vm_ind_rub <= 0 THEN
		INITIALIZE rm_rubros[1].* TO NULL
		LET vm_ind_rub = 1
	END IF
	IF vm_ind_rub IS NULL THEN
		LET vm_ind_rub = 1
	END IF
	CALL set_count(vm_ind_rub)
	INPUT ARRAY rm_rubros WITHOUT DEFAULTS FROM ra_rubros.*
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
			IF INFIELD(r30_codrubro) THEN
				CALL fl_ayuda_rubros() 
					RETURNING r_g17.g17_codrubro, 
						  r_g17.g17_nombre 
				IF r_g17.g17_codrubro IS NOT NULL THEN
					LET rm_rubros[i].rubro =
							r_g17.g17_codrubro
					DISPLAY rm_rubros[i].rubro TO
						ra_rubros[j].r30_codrubro
					LET rm_r30[i].observacion =
							r_g17.g17_nombre
					DISPLAY rm_r30[j].observacion TO n_rubro
				END IF
			END IF
			IF INFIELD(r30_moneda) THEN
				CALL fl_ayuda_monedas() 
					RETURNING r_mon.g13_moneda,
						r_mon.g13_nombre,
						r_mon.g13_decimales 
				IF r_mon.g13_moneda IS NOT NULL THEN
					LET rm_rubros[i].moneda =
								r_mon.g13_moneda
					DISPLAY r_mon.g13_moneda TO
						ra_rubros[j].r30_moneda
				END IF	
			END IF
			LET INT_FLAG = 0
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')  
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			IF vm_ind_rub = 0 THEN
				INITIALIZE rm_rubros[1].* TO NULL
				LET rm_rubros[1].fecha = CURRENT
				DISPLAY rm_rubros[1].* TO ra_rubros[1].*
				CONTINUE INPUT
			END IF
			DISPLAY rm_r30[i].observacion TO n_rubro
			DISPLAY total TO total_cargos
			CALL muestra_contadores_rub(1, vm_ind_rub)
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			LET max_row = arr_count()
			IF i > max_row THEN
				LET max_row = max_row + 1
			END IF
			DISPLAY rm_r30[i].observacion TO n_rubro
			LET total = total_cargos(arr_count())
			DISPLAY total TO total_cargos
			CALL muestra_contadores_rub(i, max_row)
		{
		BEFORE INSERT
			INITIALIZE rm_rubros[i].* TO NULL
			LET rm_rubros[i].fecha     = CURRENT
			DISPLAY rm_rubros[i].* TO ra_rubros[j].*
		}
		BEFORE DELETE
			CALL deleteRow(i, arr_count())
		AFTER DELETE
			LET vm_ind_rub = arr_count()
			EXIT INPUT
		BEFORE FIELD r30_codrubro
			LET rubro = rm_rubros[i].rubro
		AFTER FIELD r30_codrubro
			IF rm_rubros[i].rubro IS NULL THEN
				INITIALIZE rm_rubros[i].rubro TO NULL
				CLEAR ra_rubros[j].r30_codrubro 
				CONTINUE INPUT          
			ELSE
			       CALL fl_lee_rubro_liquidacion(rm_rubros[i].rubro)
					RETURNING r_g17.*
				IF r_g17.g17_codrubro IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'Rubro no existe.','exclamation')
					CALL fl_mostrar_mensaje('Rubro no existe.','exclamation')
					NEXT FIELD r30_codrubro
				END IF
				LET rm_rubros[i].rubro     = r_g17.g17_codrubro
				LET rm_r30[i].orden        = r_g17.g17_orden
				IF rm_r30[i].observacion IS NULL 
				OR rubro <> rm_rubros[i].rubro THEN
					LET rm_r30[i].observacion =
								r_g17.g17_nombre
				END IF
				DISPLAY rm_rubros[i].* TO ra_rubros[j].*
				DISPLAY rm_r30[i].observacion TO n_rubro
			END IF
		AFTER FIELD r30_moneda
			IF rm_rubros[i].moneda IS NULL THEN
				NEXT FIELD r30_moneda
			END IF
			CALL fl_lee_moneda(rm_rubros[i].moneda)
				RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				--CALL FGL_WINMESSAGE(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD r30_moneda
			END IF
			IF r_mon.g13_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r30_moneda
			END IF
			LET rm_rubros[i].paridad =
				calcula_paridad(rm_rubros[i].moneda,
						rm_r28.r28_moneda)
			IF rm_rubros[i].paridad IS NULL THEN
				LET rm_rubros[i].moneda = rm_r28.r28_moneda     
			END IF	
			DISPLAY rm_rubros[i].* TO ra_rubros[j].*
		AFTER FIELD r30_valor
			IF rm_rubros[i].valor IS NULL THEN
				CONTINUE INPUT
			END IF
			LET rm_rubros[i].valor = fl_retorna_precision_valor(
							rm_rubros[i].moneda,
							rm_rubros[i].valor)
			IF rm_r28.r28_moneda IS NOT NULL THEN
				LET rm_rubros[i].valor_ml = 
				fl_retorna_precision_valor(rm_r28.r28_moneda,
				rm_rubros[i].valor * rm_rubros[i].paridad)
			ELSE
				LET rm_rubros[i].valor_ml =
				rm_rubros[i].valor * rm_rubros[i].paridad
			END IF
			DISPLAY rm_rubros[i].* TO ra_rubros[j].*
			LET total = total_cargos(arr_count()) 
			DISPLAY total TO total_cargos
		BEFORE FIELD check
			CALL mas_datos(i)	
			LET rm_rubros[i].check = 'N'
			DISPLAY rm_rubros[i].check TO ra_rubros[j].check	
			NEXT FIELD NEXT
		AFTER INPUT
			LET vm_ind_rub = arr_count()
			FOR i = 1 TO vm_ind_rub 
				IF rm_rubros[i].rubro IS NULL OR
				   rm_rubros[i].fecha IS NULL OR
				   rm_rubros[i].moneda IS NULL OR
			  	   rm_rubros[i].paridad IS NULL OR
				   rm_rubros[i].valor IS NULL 
				THEN
					CONTINUE INPUT
				END IF
			END FOR 
			LET salir = 1
	END INPUT
	IF INT_FLAG THEN
		CLOSE WINDOW w_207_4
		RETURN 
	END IF
END WHILE
CLOSE WINDOW w_207_4
BEGIN WORK
LET done = graba_rubros()
IF NOT done THEN
	ROLLBACK WORK
ELSE
	CALL control_prorrateo()
	CALL actualiza_detalle_pedidos()
	COMMIT WORK
END IF
CALL calcular_liquidacion()
RETURN 

END FUNCTION



FUNCTION mas_datos(i)
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

OPTIONS INPUT NO WRAP
OPEN WINDOW w_207_5 AT 10,20 WITH 05 ROWS, 50 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_207_5 FROM '../forms/repf207_5'
ELSE
	OPEN FORM f_207_5 FROM '../forms/repf207_5c'
END IF
DISPLAY FORM f_207_5
CALL fl_lee_moneda(rm_rubros[i].moneda) RETURNING r_g13.*
DISPLAY rm_rubros[i].moneda TO r30_moneda
DISPLAY r_g13.g13_nombre TO n_moneda
LET INT_FLAG = 0
INPUT rm_r30[i].observacion WITHOUT DEFAULTS FROM r30_observacion
IF INT_FLAG THEN
	CLOSE WINDOW w_207_5
	RETURN
END IF
CLOSE WINDOW w_207_5

END FUNCTION



FUNCTION graba_rubros()
DEFINE done		SMALLINT
DEFINE intentar		SMALLINT
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_r30		RECORD LIKE rept030.*

DECLARE q_rubro CURSOR FOR
	SELECT * FROM rept030
		WHERE r30_compania  = vg_codcia
		  AND r30_localidad = vg_codloc
		  AND r30_numliq    = rm_r28.r28_numliq
		ORDER BY r30_fecha, r30_orden
LET i = 1
FOREACH q_rubro INTO r_r30.*
	INITIALIZE flag TO NULL
	LET j = i
	IF r_r30.r30_serial = rm_r30[i].serial THEN
		LET flag = 'U'
		LET i = i + 1
	ELSE
		LET flag = 'D'
	END IF
	IF flag IS NOT NULL THEN
		LET done = actualiza_detalle_liq(j, flag, r_r30.r30_serial)
		IF NOT done THEN
			RETURN done 
		END IF
		CONTINUE FOREACH
	END IF
END FOREACH 
WHILE (i <= vm_ind_rub)
	INITIALIZE r_r30.* TO NULL
	LET r_r30.r30_compania    = vg_codcia
	LET r_r30.r30_localidad   = vg_codloc
	LET r_r30.r30_numliq      = rm_r28.r28_numliq
	LET r_r30.r30_serial      = 0
	LET r_r30.r30_codrubro    = rm_rubros[i].rubro
	LET r_r30.r30_fecha       = rm_rubros[i].fecha
	LET r_r30.r30_observacion = rm_r30[i].observacion 
	LET r_r30.r30_moneda      = rm_rubros[i].moneda
	LET r_r30.r30_valor       = rm_rubros[i].valor
	LET r_r30.r30_paridad     = rm_rubros[i].paridad
	LET r_r30.r30_orden	  = rm_r30[i].orden
	INSERT INTO rept030 VALUES (r_r30.*)
	LET i = i + 1
END WHILE
LET done = actualiza_cabecera_liq()
IF NOT done THEN
	RETURN done 
END IF
RETURN 1

END FUNCTION



FUNCTION actualiza_detalle_pedidos()
DEFINE r_r17		RECORD LIKE rept017.*

DECLARE qu_deped CURSOR FOR SELECT * FROM te_detalle
FOREACH qu_deped INTO r_r17.*
	UPDATE rept017 SET * = r_r17.*
		WHERE r17_compania  = r_r17.r17_compania  AND 
		      r17_localidad = r_r17.r17_localidad AND 
		      r17_pedido    = r_r17.r17_pedido    AND 
		      r17_item      = r_r17.r17_item      AND 
		      r17_orden     = r_r17.r17_orden
END FOREACH

END FUNCTION



FUNCTION deleteRow(i, num_rows)
DEFINE i		SMALLINT
DEFINE num_rows		SMALLINT

WHILE (i < num_rows)
	LET rm_r30[i].* = rm_r30[i + 1].*
	LET i = i + 1
END WHILE
INITIALIZE rm_r30[i].* TO NULL

END FUNCTION



FUNCTION mensaje_intentar()
DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
--CALL fgl_winquestion(vg_producto,'Registro bloqueado por otro usuario, desea intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
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



FUNCTION actualiza_detalle_liq(i, flag, serial)
DEFINE flag		CHAR(1)
DEFINE i 		SMALLINT
DEFINE serial		LIKE rept030.r30_serial
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE r_r30		RECORD LIKE rept030.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r30.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_updet CURSOR FOR
			SELECT * FROM rept030
				WHERE r30_compania  = vg_codcia
				  AND r30_localidad = vg_codloc
				  AND r30_numliq    = rm_r28.r28_numliq
				  AND r30_serial    = serial
			FOR UPDATE
	OPEN q_updet
	FETCH q_updet INTO r_r30.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_updet
		FREE  q_updet
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF
CASE flag
	WHEN 'U' 
		LET r_r30.r30_codrubro    = rm_rubros[i].rubro
		LET r_r30.r30_moneda      = rm_rubros[i].moneda
		LET r_r30.r30_paridad     = rm_rubros[i].paridad
		LET r_r30.r30_valor       = rm_rubros[i].valor
		LET r_r30.r30_orden	  = rm_r30[i].orden
		LET r_r30.r30_observacion = rm_r30[i].observacion 
		UPDATE rept030 SET * = r_r30.* WHERE CURRENT OF q_updet 
	WHEN 'D'
		DELETE FROM rept030 WHERE CURRENT OF q_updet
END CASE
CLOSE q_updet
FREE  q_updet
RETURN done

END FUNCTION



FUNCTION actualiza_cabecera_liq()
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_r28 CURSOR FOR
			SELECT * FROM rept028
				WHERE r28_compania  = vg_codcia
				  AND r28_localidad = vg_codloc
				  AND r28_numliq    = rm_r28.r28_numliq
			FOR UPDATE
	OPEN q_r28  
	FETCH q_r28 INTO rm_r28.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_r28
		FREE  q_r28
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF
SELECT SUM(r30_valor * r30_paridad) INTO rm_r28.r28_tot_cargos
	FROM rept030
	WHERE r30_compania  = vg_codcia
	  AND r30_localidad = vg_codloc
	  AND r30_numliq    = rm_r28.r28_numliq 
IF rm_r28.r28_tot_cargos IS NULL THEN
	LET rm_r28.r28_tot_cargos = 0.0
END IF
LET rm_r28.r28_tot_cargos = fl_retorna_precision_valor(rm_r28.r28_moneda,
						      rm_r28.r28_tot_cargos)
CALL calcular_liquidacion()
UPDATE rept028 SET * = rm_r28.* WHERE CURRENT OF q_r28   
CLOSE q_r28
FREE  q_r28  
RETURN done

END FUNCTION



FUNCTION actualiza_estado_pedido(estado_ori, estado_dest, pedido)
DEFINE estado_ori	LIKE rept017.r17_estado
DEFINE estado_dest	LIKE rept017.r17_estado
DEFINE pedido		LIKE rept016.r16_pedido
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE r_r16		RECORD LIKE rept016.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r16.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_cab CURSOR FOR
			SELECT * FROM rept016
				WHERE r16_compania  = vg_codcia
				  AND r16_localidad = vg_codloc
				  AND r16_pedido    = pedido
			FOR UPDATE
	OPEN  q_cab  
	FETCH q_cab INTO r_r16.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_cab
		FREE  q_cab
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF
LET r_r16.r16_estado = estado_dest                   
UPDATE rept016 SET * = r_r16.* WHERE CURRENT OF q_cab   
LET done = actualiza_detalles_pedido(estado_ori, estado_dest, pedido)
IF NOT done THEN
	RETURN done
END IF
CLOSE q_cab  
FREE  q_cab
RETURN done

END FUNCTION



FUNCTION actualiza_detalles_pedido(estado_ori, estado_dest, pedido)
DEFINE estado_ori	LIKE rept017.r17_estado
DEFINE estado_dest	LIKE rept017.r17_estado
DEFINE pedido		LIKE rept016.r16_pedido
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE r_r17		RECORD LIKE rept017.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r17.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r17 CURSOR FOR
			SELECT * FROM rept017
				WHERE r17_compania  = vg_codcia
				  AND r17_localidad = vg_codloc
				  AND r17_pedido    = pedido
				  AND r17_estado    = estado_ori
			FOR UPDATE
	OPEN  q_r17
	FETCH q_r17 INTO r_r17.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_r17
		FREE  q_r17
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF
WHILE (STATUS <> NOTFOUND)
	LET r_r17.r17_estado = estado_dest           
	UPDATE rept017 SET * = r_r17.* WHERE CURRENT OF q_r17   
	INITIALIZE r_r17.* TO NULL
	FETCH q_r17 INTO r_r17.*
END WHILE    
CLOSE q_r17
FREE  q_r17
RETURN done

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE contador 	SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE paridad		LIKE rept028.r28_paridad

DISPLAY BY NAME rm_r28.r28_estado, rm_r28.r28_moneda, rm_r28.r28_paridad,
		rm_r28.r28_tot_exfab_mi, rm_r28.r28_tot_desp_mi,
		rm_r28.r28_tot_exfab_mb, rm_r28.r28_tot_desp_mb,
		rm_r28.r28_tot_fob_mi, rm_r28.r28_tot_fob_mb,
		rm_r28.r28_tot_flete, rm_r28.r28_tot_flet_cae,
	        rm_r28.r28_tot_seg_neto,
		rm_r28.r28_tot_seguro, rm_r28.r28_tot_cif,
		rm_r28.r28_tot_salvagu, rm_r28.r28_tot_arancel,
		rm_r28.r28_tot_cargos, rm_r28.r28_tot_iva,
		rm_r28.r28_tot_costimp, rm_r28.r28_usuario, rm_r28.r28_fecing 
LET INT_FLAG = 0
INPUT BY NAME rm_r28.r28_origen, rm_r28.r28_flag_flete, rm_r28.r28_forma_pago,
	rm_r28.r28_descripcion, rm_r28.r28_bodega, rm_r28.r28_paridad,
	rm_r28.r28_tot_iva, rm_r28.r28_tot_desp_mi, rm_r28.r28_tot_flete,
	rm_r28.r28_tot_flet_cae,
	rm_r28.r28_tot_seg_neto, rm_r28.r28_tot_seguro, rm_r28.r28_elaborado
 	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_r28.r28_origen, rm_r28.r28_flag_flete,
				rm_r28.r28_forma_pago, rm_r28.r28_descripcion,
				rm_r28.r28_bodega, rm_r28.r28_paridad,
				rm_r28.r28_tot_iva, rm_r28.r28_tot_desp_mi,
				rm_r28.r28_tot_flete, rm_r28.r28_tot_seguro,
				rm_r28.r28_tot_seg_neto, rm_r28.r28_elaborado)
		THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(r28_bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'F', 'R', 'N', 'I')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre 
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r28.r28_bodega = r_r02.r02_codigo
				DISPLAY BY NAME rm_r28.r28_bodega
				DISPLAY r_r02.r02_nombre TO n_bodega
			END IF
		END IF
		{--
		IF INFIELD(r28_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_r28.r28_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO r28_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		--}
		LET INT_FLAG = 0
	ON KEY(F5)
		CALL ingresa_pedidos('I')
		IF int_flag THEN
			IF vm_ind_ped = 0 THEN
				LET int_flag = 0
			END IF
		END IF
		CALL calcular_liquidacion()
		DISPLAY BY NAME rm_r28.r28_tot_fob_mi,
 				rm_r28.r28_tot_exfab_mi,
				rm_r28.r28_tot_flete,
				rm_r28.r28_tot_desp_mi
	ON KEY(F6)
		CALL lee_partidas_aranceles('I')
		CALL control_prorrateo()
		CALL calcular_liquidacion()
	ON KEY(F7)
		CALL muestra_costeo_detallado()
		
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		IF vm_ind_ped = 0 THEN
			CALL fl_mostrar_mensaje('Digite el pedido primero.','exclamation')
			CALL ingresa_pedidos('I')
			LET int_flag = 0
			--NEXT FIELD r28_origen
		END IF
		IF flag = 'I' THEN
			{--
			LET rm_r28.r28_paridad =
					calcula_paridad(rm_r28.r28_moneda,
							 rg_gen.g00_moneda_base)
			IF rm_r28.r28_paridad IS NULL THEN
				NEXT FIELD r28_paridad
			END IF
			DISPLAY BY NAME rm_r28.r28_paridad
			--}
		END IF
	AFTER FIELD r28_flag_flete
		IF vg_gui = 0 THEN
			IF rm_r28.r28_flag_flete IS NOT NULL THEN
				CALL muestra_flag_flete(rm_r28.r28_flag_flete)
			ELSE
				CLEAR tit_flag_flete
			END IF
		END IF
	AFTER FIELD r28_bodega
		IF rm_r28.r28_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r28.r28_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NOT NULL THEN
				IF r_r02.r02_estado <> 'B' THEN
					DISPLAY r_r02.r02_nombre TO n_bodega
				ELSE
					--CALL fgl_winmessage(vg_producto,'Bodega está bloqueada.','exclamation')
					CALL fl_mostrar_mensaje('Bodega está bloqueada.','exclamation')
					CLEAR n_bodega 
					NEXT FIELD r28_bodega
				END IF
				IF r_r02.r02_tipo_ident <> 'I' THEN
					CALL fl_mostrar_mensaje('Digite la bodega de importacion.', 'exclamation')
					NEXT FIELD r28_bodega
				END IF
			ELSE
				--CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				CLEAR n_bodega
				NEXT FIELD r28_bodega
			END IF
		ELSE
			CLEAR n_bodega
		END IF		 
	BEFORE FIELD r28_paridad       
		LET paridad = rm_r28.r28_paridad
	AFTER FIELD r28_paridad       
		IF rm_r28.r28_paridad IS NULL THEN
			LET rm_r28.r28_paridad = paridad
			DISPLAY BY NAME rm_r28.r28_paridad
		END IF
		CALL control_prorrateo()
		CALL calcular_liquidacion()
	AFTER FIELD r28_tot_desp_mi       
		LET rm_r28.r28_tot_desp_mi =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_tot_desp_mi)
		DISPLAY BY NAME rm_r28.r28_tot_desp_mi 
		LET rm_r28.r28_tot_desp_mb = rm_r28.r28_tot_desp_mi *
					     rm_r28.r28_paridad
		LET rm_r28.r28_tot_desp_mb = 
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_tot_desp_mb)
		DISPLAY BY NAME rm_r28.r28_tot_desp_mb 
		CALL control_prorrateo()
		CALL calcular_liquidacion()
	AFTER FIELD r28_tot_flete       
		LET rm_r28.r28_tot_flete =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_tot_flete)
		DISPLAY BY NAME rm_r28.r28_tot_flete 
		CALL control_prorrateo()
		CALL calcular_liquidacion()
	AFTER FIELD r28_tot_flet_cae
		LET rm_r28.r28_tot_flet_cae =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_tot_flet_cae)
		DISPLAY BY NAME rm_r28.r28_tot_flet_cae
		CALL control_prorrateo()
		CALL calcular_liquidacion()
	AFTER FIELD r28_tot_seguro      
		LET rm_r28.r28_tot_seguro =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_tot_seguro)
		DISPLAY BY NAME rm_r28.r28_tot_seguro 
		CALL control_prorrateo()
		CALL calcular_liquidacion()
	AFTER FIELD r28_tot_seg_neto      
		LET rm_r28.r28_tot_seg_neto =
			fl_retorna_precision_valor(rm_r28.r28_moneda,
						   rm_r28.r28_tot_seg_neto)
		DISPLAY BY NAME rm_r28.r28_tot_seg_neto 
		CALL control_prorrateo()
		CALL calcular_liquidacion()
	AFTER INPUT 
		IF rm_r28.r28_tot_seguro > rm_r28.r28_tot_seg_neto THEN
			CALL fl_mostrar_mensaje('El seguro total debe ser mayor que el valor prima neta.','exclamation')
			NEXT FIELD r28_tot_seguro
		END IF 
		LET rm_r28.r28_tot_cargos = total_cargos(vm_ind_rub)
		DISPLAY BY NAME rm_r28.r28_tot_cargos
		IF vm_moneda_ped = rm_r28.r28_moneda THEN
			LET rm_r28.r28_paridad = 1
			DISPLAY BY NAME rm_r28.r28_paridad
		END IF
		IF vm_ind_ped = 0 THEN
			--CALL fgl_winquestion(vg_producto,'No ha ingresado ningun pedido, y no podrá grabar. ¿Desea especificar algún pedido? ','No','Yes|No','question',1)
			CALL fl_mostrar_mensaje('No ha ingresado ningun pedido, hágalo para poder grabar.','exclamation')
			CONTINUE INPUT
		END IF
		CALL control_prorrateo()
		CALL calcular_liquidacion()
END INPUT

END FUNCTION



FUNCTION total_cargos(num_elm)
DEFINE i		SMALLINT
DEFINE num_elm		SMALLINT 
DEFINE total		LIKE rept028.r28_tot_cargos

IF num_elm IS NULL OR num_elm = 0 THEN
	SELECT SUM(r30_valor * r30_paridad) INTO total
		FROM rept030
		WHERE r30_compania  = vg_codcia
		  AND r30_localidad = vg_codloc
		  AND r30_numliq    = rm_r28.r28_numliq 
	IF total IS NULL THEN
		LET total = 0
	END IF
ELSE
	LET total = 0
	FOR i = 1 TO num_elm
		LET total = total + rm_rubros[i].valor_ml
	END FOR
END IF 
IF rm_r28.r28_moneda IS NOT NULL THEN
	LET total = fl_retorna_precision_valor(rm_r28.r28_moneda, total)
END IF
RETURN total

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r28		RECORD LIKE rept028.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*

CLEAR FORM
LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON r28_numliq, r28_estado, r28_origen,r28_flag_flete,
	r28_forma_pago, r28_descripcion, r28_bodega, r28_moneda, r28_paridad,
	r28_tot_exfab_mi, r28_tot_exfab_mb, r28_tot_iva, r28_tot_desp_mi,
	r28_tot_desp_mb, r28_tot_fob_mi, r28_tot_fob_mb, r28_tot_flete,
	r28_tot_flet_cae,
	r28_tot_seguro, r28_tot_seg_neto, r28_tot_cif, r28_tot_arancel,
	r28_tot_salvagu, r28_tot_cargos, r28_tot_costimp, r28_elaborado,
	r28_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r28_numliq) THEN
			CALL fl_ayuda_liquidacion_rep(vg_codcia, vg_codloc, 'T')
				RETURNING r_r28.r28_numliq 
			IF r_r28.r28_numliq IS NOT NULL THEN
				LET rm_r28.r28_numliq = r_r28.r28_numliq
				DISPLAY BY NAME rm_r28.r28_numliq
			END IF
		END IF
		IF INFIELD(r28_bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'F', 'R', 'N', 'I')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre 
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET rm_r28.r28_bodega = r_r02.r02_codigo
				DISPLAY BY NAME rm_r28.r28_bodega
				DISPLAY r_r02.r02_nombre TO n_bodega
			END IF
		END IF
		IF INFIELD(r28_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_r28.r28_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO r28_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r28_moneda
		LET rm_r28.r28_moneda = GET_FLDBUF(r28_moneda)
		IF rm_r28.r28_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
	AFTER FIELD r28_bodega
		LET rm_r28.r28_bodega = GET_FLDBUF(r28_bodega)
		IF rm_r28.r28_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r28.r28_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NOT NULL THEN
				IF r_r02.r02_estado <> 'B' THEN
					DISPLAY r_r02.r02_nombre TO n_bodega
				ELSE
					CLEAR n_bodega 
				END IF
			ELSE
				CLEAR n_bodega
			END IF
		ELSE
			CLEAR n_bodega
		END IF		 
	AFTER FIELD r28_flag_flete
		LET rm_r28.r28_flag_flete = get_fldbuf(r28_flag_flete)
		IF vg_gui = 0 THEN
			IF rm_r28.r28_flag_flete IS NOT NULL THEN
				CALL muestra_flag_flete(rm_r28.r28_flag_flete)
			ELSE
				CLEAR tit_flag_flete
			END IF
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
LET query = 'SELECT *, ROWID FROM rept028 ', 
            '	WHERE r28_compania  = ', vg_codcia, 
	    ' 	  AND r28_localidad = ', vg_codloc,
	    ' 	  AND ', expr_sql CLIPPED, 
            ' ORDER BY 1, 2, 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r28.*, vm_rows[vm_num_rows]
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

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r28.* FROM rept028 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
DISPLAY BY NAME rm_r28.r28_numliq,
		rm_r28.r28_estado,
		rm_r28.r28_descripcion,
		rm_r28.r28_bodega,
		rm_r28.r28_origen,     
		rm_r28.r28_flag_flete,     
		rm_r28.r28_forma_pago,
		rm_r28.r28_moneda,
		rm_r28.r28_paridad,
		rm_r28.r28_tot_exfab_mi,
		rm_r28.r28_tot_exfab_mb,
		rm_r28.r28_tot_fob_mi,
		rm_r28.r28_tot_fob_mb,
		rm_r28.r28_tot_desp_mi,
		rm_r28.r28_tot_desp_mb,
		rm_r28.r28_tot_flete,
		rm_r28.r28_tot_flet_cae,
		rm_r28.r28_tot_seguro,     
		rm_r28.r28_tot_seg_neto,     
		rm_r28.r28_tot_cif,     
		rm_r28.r28_tot_arancel,     
		rm_r28.r28_tot_cargos,
		rm_r28.r28_tot_iva,
		rm_r28.r28_tot_salvagu,
		rm_r28.r28_tot_costimp,
		rm_r28.r28_elaborado,
		rm_r28.r28_usuario,
		rm_r28.r28_fecing
IF vg_gui = 0 THEN
	CALL muestra_flag_flete(rm_r28.r28_flag_flete)
END IF
CALL muestra_etiquetas()
CALL muestra_contadores()
LET vm_ind_ped = lee_pedidos()
--CALL calcular_liquidacion()
CALL carga_tabla_aranceles()
CALL carga_tabla_temporal_prorrateo()

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
	INITIALIZE vm_ind_ped TO NULL
	INITIALIZE vm_ind_rub TO NULL
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
	INITIALIZE vm_ind_ped TO NULL
	INITIALIZE vm_ind_rub TO NULL
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_etiquetas()
DEFINE nom_estado	CHAR(9)
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_r02		RECORD LIKE rept002.*

CASE rm_r28.r28_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'B' LET nom_estado = 'BLOQUEADA'
	WHEN 'P' LET nom_estado = 'PROCESADA'
END CASE
DISPLAY nom_estado TO n_estado
CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda
CALL fl_lee_bodega_rep(vg_codcia, rm_r28.r28_bodega) RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO n_bodega

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1
SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM rept028
	WHERE r28_compania  = vg_codcia
	  AND r28_localidad = vg_codloc
	  AND r28_numliq    = vm_numliq
IF STATUS = NOTFOUND THEN
	--CALL fgl_winmessage(vg_producto,'Liquidación no existe.','exclamation')
	CALL fl_mostrar_mensaje('Liquidación no existe.','exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION muestra_detalle_pedido(pedido)
DEFINE pedido		LIKE rept029.r29_pedido
DEFINE comando 		CHAR(255)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
LET comando = run_prog, 'repp302 ', vg_base, ' ', vg_modulo, ' ',
                                 vg_codcia, ' ', vg_codloc, ' "', pedido, '"'
RUN comando

END FUNCTION



FUNCTION lee_pedidos()
DEFINE i		SMALLINT
DEFINE r_r29		RECORD LIKE rept029.*

DECLARE q_ped CURSOR FOR 
	SELECT r29_pedido, r16_moneda, g13_nombre, r16_proveedor, r16_tipo 
		FROM rept029, rept016, gent013 
		WHERE r29_compania  = vg_codcia
	          AND r29_localidad = vg_codloc
	          AND r29_numliq    = rm_r28.r28_numliq
		  AND r16_compania  = r29_compania
		  AND r16_localidad = r29_localidad
                  AND r16_pedido    = r29_pedido
		  AND g13_moneda    = r16_moneda
		ORDER BY 1                   
LET i = 1
FOREACH q_ped INTO rm_pedido[i].pedido,	  rm_pedido[i].moneda, 
		   rm_pedido[i].n_moneda, rm_pedido[i].proveedor, 
		   rm_pedido[i].tipo  
	CASE rm_pedido[i].tipo
		WHEN 'S'
			LET rm_pedido[i].n_tipo = 'SUGERIDO'
		WHEN 'E'
			LET rm_pedido[i].n_tipo = 'EMERGENCIA'	
	END CASE
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1 
RETURN i

END FUNCTION



FUNCTION ingresa_pedidos(flag)
DEFINE resp		CHAR(6)
DEFINE i, j, l, k	SMALLINT
DEFINE salir		SMALLINT
DEFINE contador		SMALLINT
DEFINE flag 		CHAR(1)
DEFINE done		SMALLINT
DEFINE resul		SMALLINT
DEFINE fob		LIKE rept028.r28_tot_exfab_mi
DEFINE ped_ant		LIKE rept016.r16_pedido 
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE regenera		CHAR(1)
DEFINE ind_ped_ori	SMALLINT
DEFINE r_pedido_aux 	ARRAY[50] OF RECORD
				pedido		LIKE rept016.r16_pedido, 
				moneda		LIKE rept016.r16_moneda, 
				n_moneda	LIKE gent013.g13_nombre, 
				proveedor	LIKE rept016.r16_proveedor, 
				tipo		LIKE rept016.r16_tipo, 
				n_tipo		CHAR(10)
			END RECORD

IF vm_num_rows = 0 AND flag = 'C' THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
OPEN WINDOW w_207_2 AT 9,12 WITH 12 ROWS, 66 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_207_2 FROM '../forms/repf207_2'
ELSE
	OPEN FORM f_207_2 FROM '../forms/repf207_2c'
END IF
DISPLAY FORM f_207_2
IF vm_ind_ped IS NULL OR vm_ind_ped <= 0 THEN 
	LET vm_ind_ped = lee_pedidos()
END IF
-- Si el estado de la liquidacion es igual a 'P' o 
-- se esta ejecutando el programa en modo de solo consulta
-- no deben de modificarse los pedidos
IF rm_r28.r28_estado = 'P' OR vm_numliq <> 0 OR flag = 'C' THEN
	IF vm_ind_ped = 0 THEN
		--CALL fgl_winmessage(vg_producto,'No hay pedidos asignados a esta liquidación.','exclamation')
		CALL fl_mostrar_mensaje('No hay pedidos asignados a esta liquidación.','exclamation')
		RETURN
	END IF
	CALL set_count(vm_ind_ped)
	DISPLAY ARRAY rm_pedido TO ra_pedido.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			LET i = arr_curr()
			IF rm_pedido[i].pedido IS NOT NULL THEN
				CALL muestra_detalle_pedido(rm_pedido[i].pedido)
			ELSE
				--CALL fgl_winmessage(vg_producto,'Ingrese un pedido primero.','exclamation')
				CALL fl_mostrar_mensaje('Ingrese un pedido primero.','exclamation')
			END IF
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
	END DISPLAY
	CLOSE WINDOW w_207_2

	LET vm_ind_ped = 0 --GVA ... PARA QUE VUELVA A MOSTRAR LOS PEDIDOS 
			   --CORRESPONDIENTES A LA LIQUIDACION CONSULTADA

	RETURN 
END IF
OPTIONS INSERT KEY F30
LET salir = 0
LET ind_ped_ori = vm_ind_ped
IF vm_ind_ped > 0 THEN
	FOR l = 1 TO vm_ind_ped
		LET r_pedido_aux[l].* = rm_pedido[l].*
	END FOR
	CALL set_count(vm_ind_ped)
END IF
WHILE NOT salir
	LET i = 1
	LET j = 1
	LET INT_FLAG = 0
	INPUT ARRAY rm_pedido WITHOUT DEFAULTS FROM ra_pedido.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				FOR l = 1 TO vm_ind_ped
					LET rm_pedido[l].* = r_pedido_aux[l].*
				END FOR
				EXIT INPUT 
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F2)
			IF INFIELD(r16_pedido) THEN
				CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc,
							'R', 'T')
					RETURNING r_r16.r16_pedido 
--				 	       r_p01.p01_nomprov,
--					       r_r16.r16_estado, 
--					       r_r16.r16_tipo        
				IF r_r16.r16_pedido IS NOT NULL THEN
					LET rm_pedido[i].pedido =
								r_r16.r16_pedido
					DISPLAY rm_pedido[i].pedido TO
						ra_pedido[j].r16_pedido
				END IF		
			END IF
			LET INT_FLAG = 0
		ON KEY(F5)
			IF rm_pedido[i].pedido IS NOT NULL THEN
				CALL muestra_detalle_pedido(rm_pedido[i].pedido)
			ELSE
				--CALL fgl_winmessage(vg_producto,'Ingrese un pedido primero.','exclamation')
				CALL fl_mostrar_mensaje('Ingrese un pedido primero.','exclamation')
			END IF
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			IF vm_ind_ped = 0 THEN
				INITIALIZE rm_pedido[1].* TO NULL
				DISPLAY rm_pedido[1].* TO ra_pedido[1].*
			END IF
		BEFORE FIELD r16_pedido
			LET ped_ant = rm_pedido[i].pedido
		AFTER FIELD r16_pedido
			IF rm_pedido[i].pedido IS NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, 
						rm_pedido[i].pedido)
				RETURNING r_r16.*
			IF r_r16.r16_pedido IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'El pedido no existe.','exclamation') 
				CALL fl_mostrar_mensaje('El pedido no existe.','exclamation') 
				NEXT FIELD r16_pedido
			END IF
			IF r_r16.r16_estado <> 'R' AND r_r16.r16_estado <> 'L'
			THEN
				--CALL fgl_winmessage(vg_producto,'No puede liquidar este pedido.','exclamation')
				CALL fl_mostrar_mensaje('No puede liquidar este pedido.','exclamation')
				NEXT FIELD r16_pedido
			END IF
			CALL buscar_pedido_liq_act(rm_pedido[i].pedido)
				RETURNING resul
			IF resul THEN
				NEXT FIELD r16_pedido
			END IF
			SELECT COUNT(*) INTO contador FROM rept017
				WHERE r17_compania  = vg_codcia
			  	  AND r17_localidad = vg_codloc
			  	  AND r17_pedido    = rm_pedido[i].pedido
				  AND r17_estado IN ('R', 'L')
			IF contador = 0 THEN
				--CALL fgl_winmessage(vg_producto,'No existen items recibidos ni liquidados en el pedido.','exclamation')
				CALL fl_mostrar_mensaje('No existen items recibidos ni liquidados en el pedido.','exclamation')
				NEXT FIELD r16_pedido
			END IF
			LET rm_pedido[i].pedido    = r_r16.r16_pedido
			LET rm_pedido[i].moneda    = r_r16.r16_moneda
			LET rm_pedido[i].tipo      = r_r16.r16_tipo
			LET rm_pedido[i].proveedor = r_r16.r16_proveedor
			CALL etiquetas_pedido(i)
			DISPLAY rm_pedido[i].* TO ra_pedido[j].*
			IF NOT valido_item_sin_partida(rm_pedido[i].pedido) THEN
				NEXT FIELD r16_pedido
			END IF
		AFTER INPUT
			LET vm_ind_ped = arr_count()
			FOR l = 1 TO vm_ind_ped - 1
				FOR k = l + 1 TO vm_ind_ped
					IF rm_pedido[l].pedido =
					   rm_pedido[k].pedido
					THEN
						CALL fl_mostrar_mensaje('No puede poner pedidos repetidos.', 'exclamation')
						NEXT FIELD r16_pedido
					END IF
				END FOR
			END FOR
			LET rm_r28.r28_tot_exfab_mi = 0
			LET rm_r28.r28_tot_exfab_mb = 0
			FOR i = 1 TO vm_ind_ped
				SELECT SUM(r17_fob * r17_cantrec) INTO fob
					FROM rept017
					WHERE r17_compania  = vg_codcia
					  AND r17_localidad = vg_codloc
					  AND r17_pedido   = rm_pedido[i].pedido
					  AND r17_estado IN ('R', 'L')
				          AND r17_cantrec > 0
				IF fob IS NULL THEN
					LET fob = 0
				END IF
				LET rm_r28.r28_tot_exfab_mi = 
					rm_r28.r28_tot_exfab_mi + fob
				CALL fl_lee_pedido_rep(vg_codcia, vg_codloc,
							rm_pedido[i].pedido)
					RETURNING r_r16.*
				LET rm_r28.r28_tot_exfab_mb = 
					rm_r28.r28_tot_exfab_mb +
					(fob * rm_r28.r28_paridad)
				LET vm_moneda_ped = r_r16.r16_moneda
			END FOR
			LET salir = 1
	END INPUT
	IF INT_FLAG THEN
		LET salir = 1
	END IF
END WHILE
CLOSE WINDOW w_207_2
LET regenera = 'N'
IF ind_ped_ori = vm_ind_ped THEN
	FOR i = 1 TO ind_ped_ori
		IF rm_pedido[i].pedido <> r_pedido_aux[i].pedido THEN
			LET regenera = 'S'
			EXIT FOR
		END IF
	END FOR
END IF
IF ind_ped_ori <> vm_ind_ped OR regenera = 'S' THEN
	CALL carga_tabla_temporal_prorrateo()
	CALL carga_tabla_aranceles()
END IF
CALL calcular_liquidacion()

END FUNCTION



FUNCTION valido_item_sin_partida(pedido)
DEFINE pedido		LIKE rept016.r16_pedido
DEFINE r_r17		RECORD LIKE rept017.*
DEFINE contar		INTEGER
DEFINE mens_ite		VARCHAR(200)
DEFINE mensaje		CHAR(300)
DEFINE palabra		CHAR(6)

DECLARE q_parti CURSOR FOR
	SELECT * FROM rept017
		WHERE r17_compania  = vg_codcia
		  AND r17_localidad = vg_codloc
		  AND r17_pedido    = pedido
		ORDER BY r17_item
LET mens_ite = NULL
LET contar   = 0
FOREACH q_parti INTO r_r17.*
	IF r_r17.r17_partida = '0000.00.00.00' OR r_r17.r17_partida = '0' THEN
		LET mens_ite = mens_ite, ' ', r_r17.r17_item CLIPPED
		LET contar   = contar + 1
	END IF
END FOREACH
IF contar = 0 THEN
	RETURN 1
END IF
LET mensaje = 'Los Items: '
LET palabra = 'tienen'
IF contar = 1 THEN
	LET mensaje = 'El Item: '
	LET palabra = 'tiene'
END IF
LET mensaje = mensaje CLIPPED, mens_ite CLIPPED, ', no ', palabra CLIPPED,
		' ninguna partida asignada.'
CALL fl_mostrar_mensaje(mensaje, 'exclamation')
RETURN 0

END FUNCTION



FUNCTION buscar_pedido_liq_act(pedido)
DEFINE pedido		LIKE rept016.r16_pedido
DEFINE r_r28		RECORD LIKE rept028.*
DEFINE r_r29		RECORD LIKE rept029.*
DEFINE mensaje		VARCHAR(100)

DECLARE q_r29 CURSOR FOR
	SELECT * FROM rept029
		WHERE r29_compania  = vg_codcia
		  AND r29_localidad = vg_codloc
		  AND r29_pedido    = pedido
FOREACH q_r29 INTO r_r29.*
	CALL fl_lee_liquidacion_rep(r_r29.r29_compania, r_r29.r29_localidad,
					r_r29.r29_numliq)
		RETURNING r_r28.*
	IF r_r28.r28_compania IS NULL THEN
		CONTINUE FOREACH
	END IF
	IF r_r28.r28_estado = 'A' THEN
		IF r_r28.r28_numliq = rm_r28.r28_numliq THEN
			CONTINUE FOREACH
		END IF
		LET mensaje = 'Este pedido esta asignado en la liquidación No.',
				' ', r_r29.r29_numliq USING "<<<<<<<<",
				' que esta Activa.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		RETURN 1
	END IF
END FOREACH
RETURN 0

END FUNCTION



FUNCTION graba_pedidos()
DEFINE i 		SMALLINT
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE r_r29		RECORD LIKE rept029.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r29.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_pedxliq CURSOR FOR
			SELECT * FROM rept029
				WHERE r29_compania  = vg_codcia
				  AND r29_localidad = vg_codloc
				  AND r29_numliq    = rm_r28.r28_numliq
			FOR UPDATE
	OPEN  q_pedxliq 
	FETCH q_pedxliq INTO r_r29.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_pedxliq
		FREE  q_pedxliq
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done 
END IF
WHILE (STATUS <> NOTFOUND)
	LET done = actualiza_estado_pedido('L', 'R', r_r29.r29_pedido)
	IF NOT done THEN
		RETURN done
	END IF
	DELETE FROM rept029 WHERE CURRENT OF q_pedxliq

	INITIALIZE r_r29.* TO NULL
	FETCH q_pedxliq INTO r_r29.*
END WHILE
CLOSE q_pedxliq
FREE  q_pedxliq
INITIALIZE r_r29.* TO NULL
LET r_r29.r29_compania  = vg_codcia
LET r_r29.r29_localidad = vg_codloc
LET r_r29.r29_numliq    = rm_r28.r28_numliq
FOR i = 1 TO vm_ind_ped
	LET r_r29.r29_pedido = rm_pedido[i].pedido	
	IF r_r29.r29_pedido IS NULL THEN
		CONTINUE FOR
	END IF	
	INSERT INTO rept029 VALUES(r_r29.*)
	LET done = actualiza_estado_pedido('R', 'L', r_r29.r29_pedido)
	IF NOT done THEN
		RETURN done
	END IF
END FOR
RETURN done

END FUNCTION



FUNCTION etiquetas_pedido(i)
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE tipo		CHAR(10)

CALL fl_lee_moneda(rm_pedido[i].moneda) RETURNING r_g13.*
LET rm_pedido[i].n_moneda = r_g13.g13_nombre
CASE rm_pedido[i].tipo
	WHEN 'S'
		LET rm_pedido[i].n_tipo = 'SUGERIDO'
	WHEN 'E'
		LET rm_pedido[i].n_tipo = 'EMERGENCIA'
	OTHERWISE
		INITIALIZE rm_pedido[i].n_tipo TO NULL
END CASE		 

END FUNCTION



FUNCTION muestra_flag_flete(flag_flete)
DEFINE flag_flete	LIKE rept028.r28_flag_flete

CASE flag_flete
	WHEN 'F'
		DISPLAY 'TOTAL FOB' TO tit_flag_flete
	WHEN 'P'
		DISPLAY 'PIE CUBICO' TO tit_flag_flete
	OTHERWISE
		CLEAR r28_flag_flete, tit_flag_flete
END CASE

END FUNCTION



FUNCTION calcular_total_fob()

LET rm_r28.r28_tot_fob_mi = 0
LET rm_r28.r28_tot_fob_mi = rm_r28.r28_tot_exfab_mi + rm_r28.r28_tot_desp_mi
LET rm_r28.r28_tot_fob_mi = fl_retorna_precision_valor(rm_r28.r28_moneda,
							rm_r28.r28_tot_fob_mi)
DISPLAY BY NAME rm_r28.r28_tot_fob_mi, rm_r28.r28_tot_exfab_mi

END FUNCTION



FUNCTION calcular_total_fob_mb()
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE fob		DECIMAL(14,4)
DEFINE i		SMALLINT

LET rm_r28.r28_tot_exfab_mb = 0
FOR i = 1 TO vm_ind_ped
	SELECT SUM(r17_fob * r17_cantrec) INTO fob
		FROM rept017
		WHERE r17_compania  = vg_codcia
		  AND r17_localidad = vg_codloc
		  AND r17_pedido    = rm_pedido[i].pedido
		  AND r17_estado IN ('R', 'L')
	          AND r17_cantrec > 0
	IF fob IS NULL THEN
		LET fob = 0
	END IF
	CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, rm_pedido[i].pedido)
		RETURNING r_r16.*
	LET rm_r28.r28_tot_exfab_mb = rm_r28.r28_tot_exfab_mb +
				      (fob * rm_r28.r28_paridad)
	LET vm_moneda_ped = r_r16.r16_moneda
END FOR
LET rm_r28.r28_tot_fob_mb = 0
LET rm_r28.r28_tot_fob_mb = (rm_r28.r28_tot_exfab_mb + rm_r28.r28_tot_desp_mb) 
LET rm_r28.r28_tot_fob_mb = fl_retorna_precision_valor(rm_r28.r28_moneda,
							rm_r28.r28_tot_fob_mb)
DISPLAY BY NAME rm_r28.r28_tot_fob_mb, rm_r28.r28_tot_exfab_mb

END FUNCTION



FUNCTION calcular_total_cif()

LET rm_r28.r28_tot_cif = 0
LET rm_r28.r28_tot_cif = rm_r28.r28_tot_fob_mb + rm_r28.r28_tot_flete +
			 rm_r28.r28_tot_seg_neto
LET rm_r28.r28_tot_cif = fl_retorna_precision_valor(rm_r28.r28_moneda,
							rm_r28.r28_tot_cif)
DISPLAY BY NAME rm_r28.r28_tot_cif

END FUNCTION



FUNCTION calcular_total_cost_imp()

LET rm_r28.r28_tot_costimp = 0
LET rm_r28.r28_tot_costimp = rm_r28.r28_tot_cif + rm_r28.r28_tot_arancel +
			     rm_r28.r28_tot_cargos + rm_r28.r28_tot_salvagu
LET rm_r28.r28_tot_costimp = fl_retorna_precision_valor(rm_r28.r28_moneda,
							rm_r28.r28_tot_costimp)
DISPLAY BY NAME rm_r28.r28_tot_costimp, rm_r28.r28_tot_arancel

END FUNCTION



FUNCTION calcular_liquidacion()

CALL calcular_total_fob()
CALL calcular_total_fob_mb()
CALL calcular_total_cif()
CALL calcular_total_cost_imp()

END FUNCTION



FUNCTION carga_tabla_temporal_prorrateo()
DEFINE i		SMALLINT

DELETE FROM te_detalle WHERE 1 = 1
FOR i = 1 TO vm_ind_ped                           
	IF rm_pedido[i].pedido IS NULL THEN
		CONTINUE FOR                      
	END IF
	INSERT INTO te_detalle 
		SELECT * FROM rept017
		WHERE r17_compania  = vg_codcia AND 
	              r17_localidad = vg_codloc AND
	              r17_pedido    = rm_pedido[i].pedido AND 
	              r17_cantrec   > 0
END FOR			                     

END FUNCTION



FUNCTION control_prorrateo()
DEFINE factor		DECIMAL(26,15)
DEFINE i		SMALLINT
DEFINE tot_piecubico	DECIMAL(13,4)
DEFINE r_g17		RECORD LIKE gent017.*

LET factor = rm_r28.r28_tot_desp_mi / rm_r28.r28_tot_exfab_mi
UPDATE te_detalle SET r17_desp_mi    = r17_fob * factor,
		      --r17_exfab_mb   = r17_fob / rm_r28.r28_paridad
		      r17_exfab_mb   = r17_fob * rm_r28.r28_paridad
--UPDATE te_detalle SET r17_desp_mb    = r17_desp_mi / rm_r28.r28_paridad
UPDATE te_detalle SET r17_desp_mb    = r17_desp_mi * rm_r28.r28_paridad
UPDATE te_detalle SET r17_tot_fob_mi = r17_fob      + r17_desp_mi,
                      r17_tot_fob_mb = r17_exfab_mb + r17_desp_mb 
LET factor = rm_r28.r28_tot_flet_cae / rm_r28.r28_tot_fob_mb  
UPDATE te_detalle SET r17_flete = r17_tot_fob_mb * factor
IF rm_r28.r28_flag_flete = 'P' THEN             
	SELECT SUM(r17_cantrec * r17_vol_cuft) INTO tot_piecubico 
		FROM te_detalle
	IF tot_piecubico IS NOT NULL THEN     
		LET factor = rm_r28.r28_tot_flete / tot_piecubico
		UPDATE te_detalle SET r17_flete = r17_vol_cuft * factor
	END IF
END IF

LET factor = rm_r28.r28_tot_seguro / rm_r28.r28_tot_fob_mb
UPDATE te_detalle SET r17_seguro  = r17_tot_fob_mb * factor
UPDATE te_detalle SET r17_cif     = r17_tot_fob_mb + r17_flete + r17_seguro
UPDATE te_detalle SET r17_arancel = r17_cif * r17_porc_part / 100,
		      r17_cargos  = 0
UPDATE te_detalle SET r17_salvagu = r17_cif * r17_porc_salva / 100

LET factor = rm_r28.r28_tot_flete / rm_r28.r28_tot_fob_mb  
UPDATE te_detalle SET r17_flete = r17_tot_fob_mb * factor
IF rm_r28.r28_flag_flete = 'P' THEN             
	SELECT SUM(r17_cantrec * r17_vol_cuft) INTO tot_piecubico 
		FROM te_detalle
	IF tot_piecubico IS NOT NULL THEN     
		LET factor = rm_r28.r28_tot_flete / tot_piecubico
		UPDATE te_detalle SET r17_flete = r17_vol_cuft * factor
	END IF
END IF

LET factor = rm_r28.r28_tot_seg_neto / rm_r28.r28_tot_fob_mb
UPDATE te_detalle SET r17_seguro  = r17_tot_fob_mb * factor
UPDATE te_detalle SET r17_cif     = r17_tot_fob_mb + r17_flete + r17_seguro

SELECT SUM(r17_arancel * r17_cantrec) INTO rm_r28.r28_tot_arancel 
	FROM te_detalle
SELECT SUM(r17_salvagu * r17_cantrec) INTO rm_r28.r28_tot_salvagu 
	FROM te_detalle
LET vm_ind_rub = lee_detalle()
FOR i = 1 TO vm_ind_rub
	IF rm_rubros[i].valor_ml > 0 THEN
		CALL fl_lee_rubro_liquidacion(rm_rubros[i].rubro)
                	RETURNING r_g17.*           
                IF r_g17.g17_base = 'FOB' THEN
                	LET factor = rm_rubros[i].valor_ml / rm_r28.r28_tot_fob_mb              
			UPDATE te_detalle 
				SET r17_cargos = r17_cargos + (r17_tot_fob_mb * factor)
		ELSE                                                           
			LET factor = rm_rubros[i].valor_ml / rm_r28.r28_tot_cif
                        UPDATE te_detalle 
				SET r17_cargos = r17_cargos + (r17_cif * factor)   
		END IF
	END IF
END FOR
LET int_flag = 0
UPDATE te_detalle SET r17_costuni_ing = r17_cif + r17_arancel + 
		      r17_salvagu + r17_cargos

END FUNCTION



FUNCTION muestra_costeo_detallado()
DEFINE flag_valor 	CHAR(1)
DEFINE cant		LIKE rept017.r17_cantrec
DEFINE max_rows, i, j 	SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE pedido		LIKE rept017.r17_pedido
DEFINE r_costeo ARRAY[2000] OF RECORD
		r17_item		LIKE rept017.r17_item, 
		descrip			LIKE rept010.r10_nombre, 
		r17_cantrec		LIKE rept017.r17_cantrec, 
	        r17_porc_part		LIKE rept017.r17_porc_part, 
		r17_porc_salva		LIKE rept017.r17_porc_salva, 
		r17_tot_fob_mb		LIKE rept017.r17_tot_fob_mb,
		r17_flete		LIKE rept017.r17_flete, 
		r17_seguro		LIKE rept017.r17_seguro, 
		r17_cif			LIKE rept017.r17_cif, 
		r17_arancel		LIKE rept017.r17_arancel, 
		r17_cargos		LIKE rept017.r17_cargos, 
		r17_costuni_ing		LIKE rept017.r17_costuni_ing
	END RECORD
DEFINE tot_fob_mb		DECIMAL(14,2)
DEFINE tot_flete		DECIMAL(14,2)
DEFINE tot_seguro		DECIMAL(14,2)
DEFINE tot_cif			DECIMAL(14,2)
DEFINE tot_arancel		DECIMAL(14,2)
DEFINE tot_cargos		DECIMAL(14,2)
DEFINE tot_costuni_ing		DECIMAL(14,2)

IF vg_gui = 0 THEN
	CALL fl_mostrar_mensaje('Esta opcion no esta habilitada para terminales.','exclamation')
	RETURN
END IF
CALL control_prorrateo()
LET max_rows = 2000
OPEN WINDOW w_cd AT 2,1 WITH FORM "../forms/repf207_6"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
DISPLAY 'Item'        TO tit_col1   
DISPLAY 'Descripción' TO tit_col2                                     
DISPLAY 'Cant.'       TO tit_col3
DISPLAY '% Ar.'       TO tit_col4 
DISPLAY '% Sa'        TO tit_col5
DISPLAY 'Fob. Unit.'  TO tit_col6    
DISPLAY 'Flete'       TO tit_col7   
DISPLAY 'Seguro'      TO tit_col8       
DISPLAY 'CIF'         TO tit_col9  
DISPLAY 'Arancel'     TO tit_col10   
DISPLAY 'Cargos'      TO tit_col11
DISPLAY 'Costo Ing.'  TO tit_col12
SELECT r17_pedido, r17_orden, r17_item, r10_nombre, r17_cantrec, r17_porc_part, 
	r17_porc_salva, r17_tot_fob_mb, r17_flete, r17_seguro, r17_cif,
	r17_arancel + r17_salvagu tot_arasal, r17_cargos, r17_costuni_ing
	FROM te_detalle, rept010
	WHERE r10_compania = 999
	  AND r17_item     = r10_codigo
	INTO TEMP t1
LET flag_valor = 'T'
LET int_flag = 0
WHILE NOT int_flag
	IF flag_valor = 'T' THEN
		DISPLAY 'TOTALES'   TO tipo_valor
	ELSE
		DISPLAY 'UNITARIOS' TO tipo_valor
	END IF
	DECLARE qu_lucas CURSOR FOR 
		SELECT r17_pedido, r17_orden, 
		       r17_item, r10_nombre, r17_cantrec, r17_porc_part, 
		       r17_porc_salva, r17_tot_fob_mb, r17_flete, r17_seguro, 
		       r17_cif, r17_arancel + r17_salvagu, r17_cargos,
		       r17_costuni_ing
			FROM te_detalle, rept010
			WHERE r10_compania = vg_codcia AND
			      r17_item     = r10_codigo
			ORDER BY 1,2
	LET i = 1
	LET tot_fob_mb	    = 0
	LET tot_flete	    = 0
	LET tot_seguro	    = 0
	LET tot_cif	    = 0
	LET tot_arancel	    = 0
	LET tot_cargos	    = 0
	LET tot_costuni_ing = 0
	FOREACH qu_lucas INTO pedido, j, r_costeo[i].*
		LET cant = r_costeo[i].r17_cantrec
		IF flag_valor <> 'T' THEN
			LET cant = 1
		END IF
		LET r_costeo[i].r17_tot_fob_mb = r_costeo[i].r17_tot_fob_mb * 
						 cant
		SELECT ROUND(r_costeo[i].r17_tot_fob_mb, 2) 
			INTO r_costeo[i].r17_tot_fob_mb FROM dual  
		LET r_costeo[i].r17_flete      = r_costeo[i].r17_flete      * 
						 cant
		LET r_costeo[i].r17_seguro     = r_costeo[i].r17_seguro     * 
						 cant
		LET r_costeo[i].r17_cif        = r_costeo[i].r17_tot_fob_mb +
						 r_costeo[i].r17_flete      +
						 r_costeo[i].r17_seguro
		LET r_costeo[i].r17_arancel    = r_costeo[i].r17_arancel    * 
						 cant
		LET r_costeo[i].r17_cargos     = r_costeo[i].r17_cargos     * 
						 cant
		LET r_costeo[i].r17_costuni_ing= r_costeo[i].r17_costuni_ing* 
						 cant
		LET tot_fob_mb	    = tot_fob_mb      + r_costeo[i].r17_tot_fob_mb
		LET tot_flete	    = tot_flete       + r_costeo[i].r17_flete
		LET tot_seguro	    = tot_seguro      + r_costeo[i].r17_seguro
		LET tot_cif	    = tot_cif         + r_costeo[i].r17_cif
		LET tot_arancel	    = tot_arancel     + r_costeo[i].r17_arancel
		LET tot_cargos	    = tot_cargos      + r_costeo[i].r17_cargos
		LET tot_costuni_ing = tot_costuni_ing + r_costeo[i].r17_costuni_ing
		INSERT INTO t1 VALUES(pedido, j, r_costeo[i].*)
		LET i = i + 1
		IF i > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	DISPLAY BY NAME tot_fob_mb, tot_flete, tot_seguro, tot_cif, tot_arancel,
		        tot_cargos, tot_costuni_ing
	LET i = i - 1
	CALL set_count(i)	
	LET int_flag = 0
	DISPLAY ARRAY r_costeo TO r_costeo.*
		ON KEY(F5)
			IF flag_valor = 'T' THEN
				LET flag_valor = 'U'
			ELSE
				LET flag_valor = 'T'
			END IF
			EXIT DISPLAY
		ON KEY(F6)
			UNLOAD TO "../../../tmp/repp207.unl"
				SELECT * FROM t1
					ORDER BY 1, 2
			RUN "mv ../../../tmp/repp207.unl $HOME/tmp/"
			LET mensaje = 'Archivo Generado en ',
					FGL_GETENV("HOME"), '/tmp/repp207.unl',
					' OK.'
			CALL fl_mostrar_mensaje(mensaje, 'info')
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F6","Archivo")
	END DISPLAY
END WHILE
DROP TABLE t1
CLOSE WINDOW w_cd

END FUNCTION


FUNCTION carga_tabla_aranceles()
DEFINE expr_ped		CHAR(200)
DEFINE query		CHAR(500)
DEFINE i		SMALLINT
		
LET vm_num_pp = 0
IF vm_ind_ped = 0 THEN
	RETURN
END IF
LET expr_ped = 'r17_pedido IN (' 
FOR i = 1 TO vm_ind_ped
	LET expr_ped = expr_ped CLIPPED, '"', rm_pedido[i].pedido CLIPPED, '",'
END FOR
LET expr_ped = expr_ped CLIPPED, '"GVA-GARROCHA")'
LET query = 'SELECT r17_item, r10_nombre, r17_partida, r17_porc_part ',
		' FROM rept017, rept010 ',
		' WHERE r17_compania  = ', vg_codcia, 
		'   AND r17_localidad = ', vg_codloc, 
		'   AND ', expr_ped CLIPPED,
		'   AND r17_cantrec > 0 ',
		'   AND r17_compania = r10_compania ',
		'   AND r17_item     = r10_codigo ',
		'   ORDER BY 3,1'
PREPARE garrocha FROM query
DECLARE q_garrocha CURSOR FOR garrocha
LET vm_num_pp = 1
FOREACH q_garrocha INTO rm_pp[vm_num_pp].*
	LET vm_num_pp = vm_num_pp + 1
	IF vm_num_pp > 500 THEN
		CALL fl_mostrar_mensaje('Se ha excedido tamano del arreglo '||
					'rm_pp. Avise a Sistemas.', 'stop')
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_num_pp = vm_num_pp - 1

END FUNCTION



FUNCTION lee_partidas_aranceles(flag)
DEFINE flag		CHAR(1)
DEFINE r_pp_ori 	ARRAY[500] OF RECORD
		r17_item	LIKE rept017.r17_item,
		r10_nombre	LIKE rept010.r10_nombre,
		r17_partida	LIKE rept017.r17_partida,
		r17_porc_part	LIKE rept017.r17_porc_part
	END RECORD
DEFINE i, j		SMALLINT
DEFINE resp		CHAR(7)
DEFINE r_g16		RECORD LIKE gent016.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE nulo, partida	LIKE gent016.g16_partida
DEFINE row_ini		SMALLINT
DEFINE col_ini		SMALLINT
DEFINE row_max		SMALLINT
DEFINE col_max		SMALLINT

IF vm_num_pp = 0 THEN
	RETURN 
END IF
LET row_ini = 4
LET col_ini = 4
LET row_max = 19
LET col_max = 75
IF vg_gui = 0 THEN
	LET row_ini = 5
	LET col_ini = 4
	LET row_max = 18
	LET col_max = 74
END IF
OPEN WINDOW w_pp AT row_ini, col_ini WITH row_max ROWS, col_max COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_207_7 FROM '../forms/repf207_7'
ELSE
	OPEN FORM f_207_7 FROM '../forms/repf207_7c'
END IF
DISPLAY FORM f_207_7
IF vg_gui = 1 THEN
	DISPLAY 'Item'        TO tit_col1
	DISPLAY 'Descripción' TO tit_col2
	DISPLAY 'Partida'     TO tit_col3
	DISPLAY '%'           TO tit_col4
ELSE
	CALL fl_lee_item(vg_codcia, rm_pp[1].r17_item) RETURNING r_r10.*
	CALL muestra_descripciones(rm_pp[1].r17_item, r_r10.r10_linea,
				r_r10.r10_sub_linea, r_r10.r10_cod_grupo, 
				r_r10.r10_cod_clase)
	DISPLAY r_r10.r10_nombre TO nom_item
END IF
IF flag = 'C' THEN
	CALL set_count(vm_num_pp)
	DISPLAY ARRAY rm_pp TO rm_pp.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(RETURN)
			LET i = arr_curr()
			LET j = scr_line()
			CALL fl_lee_item(vg_codcia, rm_pp[i].r17_item)
				RETURNING r_r10.*
			CALL muestra_descripciones(rm_pp[i].r17_item,
				r_r10.r10_linea, r_r10.r10_sub_linea,
				r_r10.r10_cod_grupo, 
				r_r10.r10_cod_clase)
			DISPLAY r_r10.r10_nombre TO nom_item
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#LET j = scr_line()
			--#CALL fl_lee_item(vg_codcia, rm_pp[i].r17_item)
				--#RETURNING r_r10.*
			--#CALL muestra_descripciones(rm_pp[i].r17_item,
				--#r_r10.r10_linea, r_r10.r10_sub_linea,
				--#r_r10.r10_cod_grupo, 
				--#r_r10.r10_cod_clase)
			--#DISPLAY r_r10.r10_nombre TO nom_item
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	CLOSE WINDOW w_pp
	RETURN 
END IF
FOR i = 1 TO vm_num_pp
	LET r_pp_ori[i].* = rm_pp[i].*
END FOR
OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_num_pp)
	INPUT ARRAY rm_pp WITHOUT DEFAULTS FROM rm_pp.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				FOR i = 1 TO vm_num_pp
					LET rm_pp[i].* = r_pp_ori[i].*
				END FOR
				EXIT INPUT 
			END IF
		ON KEY(F2)
			IF infield(r17_partida) THEN
				LET nulo = NULL
				CALL fl_ayuda_partidas(nulo) RETURNING partida
				IF partida IS NOT NULL THEN
					LET rm_pp[i].r17_partida = partida
					DISPLAY rm_pp[i].* TO rm_pp[j].*
				END IF
				LET int_flag = 0
			END IF
		ON KEY(F5)
			CALL ver_partida(rm_pp[i].r17_partida)
			LET int_flag = 0
		BEFORE INPUT 
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW 
			LET i = arr_curr()
			LET j = scr_line()
			IF i > vm_num_pp THEN
				LET int_flag = 2
				EXIT INPUT
			END IF
			CALL fl_lee_item(vg_codcia, rm_pp[i].r17_item)
				RETURNING r_r10.*
			CALL muestra_descripciones(rm_pp[i].r17_item,
				r_r10.r10_linea, r_r10.r10_sub_linea,
				r_r10.r10_cod_grupo, 
				r_r10.r10_cod_clase)
			DISPLAY r_r10.r10_nombre TO nom_item
		AFTER FIELD r17_partida
			IF rm_pp[i].r17_partida IS NULL THEN
				NEXT FIELD r17_partida
			END IF 
			IF FIELD_TOUCHED(r17_partida) THEN
				CALL fl_lee_partida(rm_pp[i].r17_partida)
					RETURNING r_g16.*
				IF r_g16.g16_partida IS NULL THEN
					CALL fl_mostrar_mensaje('Partida no existe.', 'exclamation')
					NEXT FIELD r17_partida
				END IF
				LET rm_pp[i].r17_porc_part=r_g16.g16_porcentaje
				DISPLAY rm_pp[i].* TO rm_pp[j].*
			END IF
		AFTER FIELD r17_porc_part
			IF rm_pp[i].r17_porc_part IS NULL THEN
				NEXT FIELD r17_porc_part
			END IF 
	END INPUT
	IF int_flag <= 1 THEN
		EXIT WHILE
	END IF
END WHILE
FOR i = 1 TO vm_num_pp
	UPDATE te_detalle SET r17_partida   = rm_pp[i].r17_partida,
			      r17_porc_part = rm_pp[i].r17_porc_part
		WHERE r17_item = rm_pp[i].r17_item
END FOR
CLOSE WINDOW w_pp
OPTIONS 
	INSERT KEY F10,
	DELETE KEY F11

END FUNCTION



FUNCTION muestra_contadores_rub(num_row, max_row)
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
DISPLAY r_r71.r71_desc_grupo TO descrip_3
DISPLAY r_r72.r72_desc_clase TO descrip_4

END FUNCTION



FUNCTION ver_partida(partida)
DEFINE partida		LIKE gent016.g16_partida
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE comando		CHAR(300)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES',
	vg_separador, 'fuentes', vg_separador, run_prog, ' genp114 ', vg_base,
	' "GE" "', partida, '"'
RUN comando

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
DISPLAY '<F5>      Ingresar Pedidos'         AT a,2
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
DISPLAY '<F5>      Ver Detalle del Pedido'   AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

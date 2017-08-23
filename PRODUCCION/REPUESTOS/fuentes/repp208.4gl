--------------------------------------------------------------------------------
-- Titulo           : repp208.4gl - Cierre de Pedidos           
-- Elaboracion      : 10-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp208 base modulo compania localidad
-- Ultima Correccion: 5 de julio de 2002
-- Motivo Correccion: Si hay stock conserve el PVP, si no hay stock
--		      actualize por Factor Venta (RCA)
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

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
DEFINE rm_ctrn		RECORD LIKE rept019.*
DEFINE vm_tipo_tran	CHAR(2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp208.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp208'
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
LET vm_tipo_tran = 'IM'		-- IMPORTACION
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_208 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_208 FROM '../forms/repf208_1'
ELSE
	OPEN FORM f_208 FROM '../forms/repf208_1c'
END IF
DISPLAY FORM f_208
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
LET vm_max_rows = 1000
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Ver Liquidación'
		HIDE OPTION 'Cerrar' 
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Ver Liquidación'
			SHOW OPTION 'Cerrar' 
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('L') 'Ver Liquidación'      'Ver la liquidación.'
		CALL control_liquidacion()
	COMMAND KEY('E') 'Cerrar'		'Cierra la liquidación'
		CALL control_cerrar()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Ver Liquidación'
			SHOW OPTION 'Cerrar' 
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Ver Liquidación'
				HIDE OPTION 'Cerrar' 
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Ver Liquidación'
			SHOW OPTION 'Cerrar' 
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
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



FUNCTION control_ingreso()
DEFINE r_r28		RECORD LIKE rept028.*

CLEAR FORM
INITIALIZE rm_r28.* TO NULL
OPTIONS	INPUT NO WRAP
LET INT_FLAG = 0
INPUT BY NAME rm_r28.r28_numliq WITHOUT DEFAULTS
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r28_numliq) THEN
			CALL fl_ayuda_liquidacion_rep(vg_codcia, vg_codloc, 'A')
				RETURNING r_r28.r28_numliq
			IF r_r28.r28_numliq IS NOT NULL THEN
				LET rm_r28.r28_numliq = r_r28.r28_numliq
				DISPLAY BY NAME rm_r28.r28_numliq
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END INPUT
OPTIONS INPUT WRAP
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET vm_num_rows = vm_num_rows + 1
SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM rept028
	WHERE r28_compania  = vg_codcia
	  AND r28_localidad = vg_codloc
	  AND r28_numliq    = rm_r28.r28_numliq
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Número de liquidación no existe.','exclamation')
	LET vm_num_rows = vm_num_rows - 1
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
ELSE
	LET vm_row_current = vm_num_rows
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE r_r28		RECORD LIKE rept028.*
DEFINE r_mon		RECORD LIKE gent013.*

CLEAR FORM
LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql ON r28_numliq, r28_estado
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r28_numliq) THEN
			CALL fl_ayuda_liquidacion_rep(vg_codcia, vg_codloc, 'P')
				RETURNING r_r28.r28_numliq
			IF r_r28.r28_numliq IS NOT NULL THEN
				LET rm_r28.r28_numliq = r_r28.r28_numliq
				DISPLAY BY NAME rm_r28.r28_numliq
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
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
	    '	ORDER BY 4 DESC'
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
		rm_r28.r28_fecing,
		rm_r28.r28_moneda,
		rm_r28.r28_paridad,
		rm_r28.r28_fecha_lleg,
		rm_r28.r28_fecha_ing,
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
		rm_r28.r28_tot_cargos,
		rm_r28.r28_tot_iva,
		rm_r28.r28_tot_arancel,
		rm_r28.r28_tot_salvagu,
		rm_r28.r28_tot_costimp
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()
DEFINE nrow		SMALLINT

LET nrow = 1
IF vg_gui = 0 THEN
	LET nrow = 3
END IF
DISPLAY "" AT nrow,1
DISPLAY vm_row_current, " de ", vm_num_rows AT nrow, 67

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
DEFINE nom_estado		CHAR(9)
DEFINE r_g13			RECORD LIKE gent013.*

CASE rm_r28.r28_estado
	WHEN 'A' LET nom_estado = 'ACTIVA'
	WHEN 'P' LET nom_estado = 'PROCESADA'
	WHEN 'B' LET nom_estado = 'ELIMINADA'
END CASE
CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda
DISPLAY nom_estado   TO n_estado
	
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



FUNCTION control_liquidacion()
DEFINE command_line	CHAR(100)
DEFINE run_prog		CHAR(10)

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
LET command_line = run_prog, 'repp207 ', vg_base,   ' ', vg_modulo,
		                 ' ', vg_codcia, ' ', vg_codloc,
				 ' ', rm_r28.r28_numliq
RUN command_line

END FUNCTION



FUNCTION control_cerrar()
DEFINE tot_fob_rec	DECIMAL(22,10)
DEFINE resul, done	SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r28.r28_estado = 'P' THEN
	CALL fl_mostrar_mensaje('La liquidación ya fue cerrada.','exclamation')
	RETURN
END IF
IF rm_r28.r28_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Esta liquidación no está activa.', 'exclamation')
	RETURN
END IF
IF rm_r28.r28_tot_fob_mb <= 0 THEN
	CALL fl_mostrar_mensaje('La liquidación no tiene total fob.','exclamation')
	RETURN
END IF
SELECT SUM(r17_cantrec * r17_fob) INTO tot_fob_rec
	FROM rept029, rept017
	WHERE r29_compania  = rm_r28.r28_compania  AND 
	      r29_localidad = rm_r28.r28_localidad AND 
	      r29_numliq    = rm_r28.r28_numliq    AND
	      r29_compania  = r17_compania         AND 
	      r29_localidad = r17_localidad        AND 
	      r29_pedido    = r17_pedido           AND
	      r17_estado    = 'L'
IF rm_r28.r28_tot_exfab_mi <> tot_fob_rec THEN
	CALL fl_mostrar_mensaje('Fob recibido en liquidación es distinto del fob recibido en pedidos. Verifique y de mantenimiento a la liquidación.','exclamation')
	RETURN
END IF
BEGIN WORK
LET done = actualiza_cabecera_liq()
IF NOT done THEN
	ROLLBACK WORK
	RETURN
END IF
LET done = actualiza_cabecera_pedido()
IF NOT done THEN
	ROLLBACK WORK
	RETURN
END IF
LET done = actualiza_detalle_pedido()
IF NOT done THEN
	ROLLBACK WORK
	RETURN
END IF
CALL genera_transferencia() RETURNING resul, r_r19.*
IF NOT resul THEN
	ROLLBACK WORK
	RETURN
END IF
COMMIT WORK
CALL fl_control_master_contab_repuestos(rm_ctrn.r19_compania, 
	rm_ctrn.r19_localidad, rm_ctrn.r19_cod_tran, rm_ctrn.r19_num_tran)
IF r_r19.r19_compania IS NOT NULL THEN
	CALL fl_control_master_contab_repuestos(r_r19.r19_compania,
						r_r19.r19_localidad,
						r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION actualiza_cabecera_liq()
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE r_r28		RECORD LIKE rept028.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_r28.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_r28 CURSOR FOR
			SELECT * FROM rept028
				WHERE r28_compania  = vg_codcia
				  AND r28_localidad = vg_codloc
				  AND r28_numliq    = rm_r28.r28_numliq
			FOR UPDATE
	OPEN q_r28  
	FETCH q_r28 INTO r_r28.*
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
LET r_r28.r28_estado = 'P'
UPDATE rept028 SET * = r_r28.* WHERE CURRENT OF q_r28   
CLOSE q_r28  
FREE  q_r28
RETURN done

END FUNCTION



FUNCTION actualiza_cabecera_pedido()
DEFINE r_upd		RECORD LIKE rept016.*

UPDATE rept016 SET r16_estado = 'P' 
	WHERE r16_compania  = vg_codcia AND 
	      r16_localidad = vg_codloc AND
	      r16_pedido    IN 
		(SELECT r29_pedido FROM rept029
			WHERE r29_compania  = vg_codcia AND 
			      r29_localidad = vg_codloc AND 
			      r29_numliq    = rm_r28.r28_numliq)
RETURN 1

END FUNCTION



FUNCTION actualiza_detalle_pedido()
DEFINE intentar		SMALLINT
DEFINE done, i 		SMALLINT
DEFINE r_r17		RECORD LIKE rept017.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE rst		RECORD LIKE rept011.*
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_det		RECORD LIKE rept020.*
DEFINE r_art, r_aant	RECORD LIKE rept010.*
DEFINE costo_ing	DECIMAL(22,10)
DEFINE costo_nue	DECIMAL(22,10)
DEFINE fob		LIKE rept017.r17_fob
DEFINE mensaje		VARCHAR(100)

CREATE TEMP TABLE temp_detped
	(te_item	CHAR(15),
	 te_cantped	DECIMAL(8,2),
	 te_cantrec	DECIMAL(8,2),
	 te_fob		DECIMAL(13,4))
DECLARE q_dped CURSOR FOR SELECT rept017.* FROM rept029, rept017
	WHERE r29_compania  = vg_codcia     AND 
	      r29_localidad = vg_codloc     AND 
	      r29_numliq    = rm_r28.r28_numliq AND
	      r17_compania  = r29_compania  AND 
	      r17_localidad = r29_localidad AND 
   	      r17_pedido    = r29_pedido    AND
	      r17_estado    = 'L'
FOREACH q_dped INTO r_r17.*
	IF r_r17.r17_cantrec = 0 THEN
		CONTINUE FOREACH
	END IF	
	SELECT * FROM temp_detped WHERE te_item = r_r17.r17_item
	IF status = NOTFOUND THEN
		INSERT INTO temp_detped 
			VALUES (r_r17.r17_item,    r_r17.r17_cantped, 
			        r_r17.r17_cantrec, r_r17.r17_fob)
	ELSE
		UPDATE temp_detped 
			SET te_cantrec = te_cantrec + r_r17.r17_cantrec,
			    te_cantped = te_cantped + r_r17.r17_cantped,
		            te_fob     = ((te_fob * te_cantrec) + 
				         (r_r17.r17_fob * r_r17.r17_cantrec)) /
				         (te_cantrec + r_r17.r17_cantrec)
			WHERE te_item = r_r17.r17_item
	END IF
	SELECT * FROM rept011 WHERE r11_compania  = vg_codcia AND
				    r11_bodega    = rm_r28.r28_bodega AND 
				    r11_item      = r_r17.r17_item
	IF status = NOTFOUND THEN
		INSERT INTO rept011 VALUES(vg_codcia, rm_r28.r28_bodega,
			r_r17.r17_item, 'SN', NULL, 0, 0, 0, 0, NULL, NULL, 
			NULL, NULL, NULL, NULL)
	END IF
END FOREACH
CLOSE q_dped
CALL fl_lee_proveedor(rm_r28.r28_codprov) RETURNING r_prov.*
DECLARE q_tt CURSOR FOR SELECT * FROM temp_detped
	ORDER BY te_item
INITIALIZE rm_ctrn.* TO NULL
LET rm_ctrn.r19_num_tran = fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA', vm_tipo_tran)
IF rm_ctrn.r19_num_tran <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_ctrn.r19_compania 	= vg_codcia
LET rm_ctrn.r19_localidad 	= vg_codloc
LET rm_ctrn.r19_cod_tran 	= vm_tipo_tran
LET rm_ctrn.r19_cont_cred 	= 'C'
LET rm_ctrn.r19_referencia 	= 'LIQUIDACION: ',
					rm_r28.r28_numliq USING "<<<<<<<&", ' ',
					'PEDIDO: ', r_r17.r17_pedido CLIPPED
LET rm_ctrn.r19_nomcli 		= r_prov.p01_nomprov
LET rm_ctrn.r19_dircli 		= r_prov.p01_direccion1
LET rm_ctrn.r19_cedruc 		= r_prov.p01_num_doc
SELECT MIN(r01_codigo) INTO rm_ctrn.r19_vendedor
	FROM rept001 WHERE r01_compania = vg_codcia
LET rm_ctrn.r19_descuento 	= 0
LET rm_ctrn.r19_porc_impto 	= 0
LET rm_ctrn.r19_bodega_ori 	= rm_r28.r28_bodega
LET rm_ctrn.r19_bodega_dest 	= rm_r28.r28_bodega
LET rm_ctrn.r19_fact_costo 	= rm_r28.r28_fact_costo
LET rm_ctrn.r19_fact_venta 	= rm_r28.r28_margen_uti
LET rm_ctrn.r19_moneda 		= rm_r28.r28_moneda
IF rg_gen.g00_moneda_base = rm_r28.r28_moneda THEN
	LET rm_ctrn.r19_paridad = 1
ELSE
	CALL fl_lee_factor_moneda(rm_r28.r28_moneda, rg_gen.g00_moneda_base) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		ROLLBACK WORK
		LET mensaje = 'No hay paridad de conversión de: ', rm_r28.r28_moneda, ' a ', rg_gen.g00_moneda_base
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	LET rm_ctrn.r19_paridad = r_g14.g14_tasa
END IF	
CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_g13.*
LET rm_ctrn.r19_precision 	= r_g13.g13_decimales
LET rm_ctrn.r19_tot_costo 	= 0
LET rm_ctrn.r19_tot_bruto	= 0
LET rm_ctrn.r19_tot_dscto 	= 0
LET rm_ctrn.r19_tot_neto 	= 0
LET rm_ctrn.r19_flete 		= 0
LET rm_ctrn.r19_numliq 		= rm_r28.r28_numliq
LET rm_ctrn.r19_usuario 	= vg_usuario
LET rm_ctrn.r19_fecing 		= fl_current()
INSERT INTO rept019 VALUES (rm_ctrn.*)
SET LOCK MODE TO WAIT 5
LET i = 0
OPEN q_dped
WHILE TRUE
	FETCH q_dped INTO r_r17.*
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	UPDATE rept017 SET r17_estado = 'P' 
	      WHERE r17_compania  = vg_codcia  AND 
	      	    r17_localidad = vg_codloc  AND 
   	            r17_pedido    = r_r17.r17_pedido AND
	      	    r17_item      = r_r17.r17_item
	IF r_r17.r17_cantrec <= 0 THEN
		CONTINUE WHILE
	END IF
	LET costo_ing = r_r17.r17_costuni_ing
	CALL fl_obtiene_costo_item_imp(vg_codcia, rm_r28.r28_moneda,
					r_r17.r17_item,
		r_r17.r17_cantrec, costo_ing)
		RETURNING costo_nue
	DECLARE q_ust CURSOR FOR SELECT * FROM rept011
		WHERE r11_compania  = vg_codcia AND
		      r11_bodega    = rm_r28.r28_bodega AND 
		      r11_item      = r_r17.r17_item
		FOR UPDATE
	OPEN q_ust
	FETCH q_ust INTO rst.*
	SELECT SUM(r11_stock_act) INTO rst.r11_stock_ant FROM rept011
		WHERE r11_compania  = vg_codcia AND
		      r11_item      = r_r17.r17_item   -- Stock anterior todas las bodegas
	UPDATE rept011 SET r11_stock_act  = r11_stock_act + r_r17.r17_cantrec,
			   r11_ing_dia    = r11_ing_dia   + r_r17.r17_cantrec,
			   r11_fec_ulting = vg_fecha,
			   r11_tip_ulting = rm_ctrn.r19_cod_tran,
			   r11_num_ulting = rm_ctrn.r19_num_tran
		WHERE CURRENT OF q_ust
	CALL fl_lee_item(vg_codcia, r_r17.r17_item) RETURNING r_art.*
	LET r_aant.* = r_art.*
	LET r_art.r10_precio_ant  = r_art.r10_precio_mb
	LET r_art.r10_fec_camprec = fl_current()
	LET r_art.r10_costo_mb    = costo_nue
	LET r_art.r10_costult_mb  = costo_ing
	LET r_art.r10_cantped     = r_art.r10_cantped - r_r17.r17_cantrec
	IF r_art.r10_cantped < 0 THEN
		LET r_art.r10_cantped = 0
	END IF
	UPDATE rept010 SET r10_costo_mb		= r_art.r10_costo_mb,
	                   r10_costult_mb	= r_art.r10_costult_mb
		WHERE r10_compania = vg_codcia AND 
		      r10_codigo   = r_art.r10_codigo
	INITIALIZE r_det.* TO NULL
	LET i = i + 1
    	LET r_det.r20_compania 		= vg_codcia
    	LET r_det.r20_localidad 	= vg_codloc
    	LET r_det.r20_cod_tran 		= rm_ctrn.r19_cod_tran
    	LET r_det.r20_num_tran 		= rm_ctrn.r19_num_tran
	LET r_det.r20_bodega		= rm_ctrn.r19_bodega_dest
    	LET r_det.r20_item 		= r_r17.r17_item
    	LET r_det.r20_orden 		= 1
    	LET r_det.r20_cant_ped 		= r_r17.r17_cantped
    	LET r_det.r20_cant_ven 		= r_r17.r17_cantrec
    	LET r_det.r20_cant_dev 		= 0
    	LET r_det.r20_cant_ent 		= 0
    	LET r_det.r20_descuento 	= 0
    	LET r_det.r20_val_descto 	= 0
    	LET r_det.r20_precio		= r_art.r10_precio_mb 
    	LET r_det.r20_val_impto 	= 0
    	LET r_det.r20_costo 		= costo_ing
    	LET r_det.r20_fob 		= r_r17.r17_fob
    	LET r_det.r20_linea 		= r_art.r10_linea
    	LET r_det.r20_rotacion 		= r_art.r10_rotacion
    	LET r_det.r20_ubicacion 	= rst.r11_ubicacion
    	LET r_det.r20_costant_mb 	= r_aant.r10_costo_mb
    	LET r_det.r20_costant_ma 	= r_aant.r10_costo_ma
    	LET r_det.r20_costnue_mb 	= r_art.r10_costo_mb
    	LET r_det.r20_costnue_ma 	= r_art.r10_costo_ma
    	LET r_det.r20_stock_ant 	= rst.r11_stock_act
    	LET r_det.r20_stock_bd 		= rst.r11_stock_ant
    	LET r_det.r20_fecing 		= rm_ctrn.r19_fecing
	INSERT INTO rept020 VALUES (r_det.*)
	LET rm_ctrn.r19_tot_costo       = rm_ctrn.r19_tot_costo + 
				         (costo_ing * r_r17.r17_cantrec)
END WHILE
IF i = 0 THEN 
	CALL fl_mostrar_mensaje('No se procesó ningún item, verifique pedidos asignados en la liquidación.','stop')
	EXIT PROGRAM
END IF
UPDATE rept019 SET r19_tot_costo = rm_ctrn.r19_tot_costo,
		   r19_tot_bruto = rm_ctrn.r19_tot_costo,
		   r19_tot_neto  = rm_ctrn.r19_tot_costo
	WHERE r19_compania  = rm_ctrn.r19_compania  AND 
	      r19_localidad = rm_ctrn.r19_localidad AND 
	      r19_cod_tran  = rm_ctrn.r19_cod_tran  AND
	      r19_num_tran  = rm_ctrn.r19_num_tran
DROP TABLE temp_detped
RETURN 1

END FUNCTION



FUNCTION genera_transferencia()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_dtrn		RECORD LIKE rept020.*
DEFINE stock_act	LIKE rept011.r11_stock_act
DEFINE mensaje		VARCHAR(200)
DEFINE i, resul		SMALLINT
DEFINE cuantos		INTEGER

INITIALIZE r_r19.* TO NULL
SELECT COUNT(*)
	INTO cuantos
	FROM rept020, rept010
	WHERE r20_compania  = rm_ctrn.r19_compania
	  AND r20_localidad = rm_ctrn.r19_localidad
	  AND r20_cod_tran  = rm_ctrn.r19_cod_tran
	  AND r20_num_tran  = rm_ctrn.r19_num_tran
	  AND r10_compania  = r20_compania
	  AND r10_codigo    = r20_item
	  AND r10_tipo      = 7
IF cuantos = 0 THEN
	RETURN 1, r_r19.*
END IF
LET r_r19.r19_compania		= vg_codcia
LET r_r19.r19_localidad   	= vg_codloc
LET r_r19.r19_cod_tran    	= 'TR'
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA',
					r_r19.r19_cod_tran)
	RETURNING r_r19.r19_num_tran
IF r_r19.r19_num_tran = 0 THEN
	CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
	RETURN 0, r_r19.*
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
LET r_r19.r19_referencia        = 'TR. GEN. IMP.# '
LET r_r19.r19_referencia	= r_r19.r19_referencia CLIPPED, ' ',
					rm_ctrn.r19_num_tran USING "<<<<<&",
					' BD ', rm_ctrn.r19_bodega_ori CLIPPED
LET r_r19.r19_nomcli		= ' '
LET r_r19.r19_dircli     	= ' '
LET r_r19.r19_cedruc     	= ' '
LET r_r19.r19_vendedor   	= rm_ctrn.r19_vendedor
LET r_r19.r19_descuento  	= 0.0
LET r_r19.r19_porc_impto 	= 0.0
LET r_r19.r19_tipo_dev          = rm_ctrn.r19_cod_tran
LET r_r19.r19_num_dev           = rm_ctrn.r19_num_tran
LET r_r19.r19_bodega_ori        = rm_ctrn.r19_bodega_ori
SQL
	SELECT r02_codigo
		INTO $r_r19.r19_bodega_dest
		FROM rept002
		WHERE r02_compania   = $vg_codcia
		  AND r02_localidad  = $vg_codloc
		  AND r02_estado     = "A"
		  AND r02_area       = "T"
		  AND r02_tipo_ident = "E"
END SQL
IF r_r19.r19_bodega_dest IS NULL THEN
	CALL fl_mostrar_mensaje('No existe bodega de Ensamblaje.','exclamation')
	RETURN 0, r_r19.*
END IF
IF r_r19.r19_bodega_ori = r_r19.r19_bodega_dest THEN
	CALL fl_mostrar_mensaje('La bodega de importación debe ser diferente a la bodega de Ensamblaje.', 'exclamation')
	RETURN 0, r_r19.*
END IF
LET r_r19.r19_moneda     	= rm_ctrn.r19_moneda
LET r_r19.r19_precision  	= rm_ctrn.r19_precision
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
	SELECT rept020.*
		FROM rept020, rept010
		WHERE r20_compania  = rm_ctrn.r19_compania
		  AND r20_localidad = rm_ctrn.r19_localidad
		  AND r20_cod_tran  = rm_ctrn.r19_cod_tran
		  AND r20_num_tran  = rm_ctrn.r19_num_tran
		  AND r10_compania  = r20_compania
		  AND r10_codigo    = r20_item
		  AND r10_tipo      = 7
		ORDER BY r20_item ASC
LET resul = 1
LET i     = 1
FOREACH q_trans_d INTO r_dtrn.*
	CALL fl_lee_item(vg_codcia, r_dtrn.r20_item) RETURNING r_r10.*
	LET r_r19.r19_tot_costo  = r_r19.r19_tot_costo + 
				  (r_dtrn.r20_cant_ven * r_r10.r10_costo_mb)
	LET r_r20.r20_cant_ped   = r_dtrn.r20_cant_ven
	LET r_r20.r20_cant_ven   = r_dtrn.r20_cant_ven
	LET r_r20.r20_bodega     = r_r19.r19_bodega_ori
	LET r_r20.r20_item       = r_dtrn.r20_item 
	LET r_r20.r20_costo      = r_r10.r10_costo_mb 
	LET r_r20.r20_orden      = i
	LET r_r20.r20_fob        = r_r10.r10_fob 
	LET r_r20.r20_linea      = r_r10.r10_linea 
	LET r_r20.r20_rotacion   = r_r10.r10_rotacion 
	LET r_r20.r20_precio     = r_r10.r10_precio_mb
	LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
	LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
	LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, r_dtrn.r20_item)
		RETURNING r_r11.*
	IF r_r11.r11_compania IS NOT NULL THEN
		CALL fl_lee_bodega_rep(r_r11.r11_compania, r_r11.r11_bodega)
			RETURNING r_r02.*
		IF r_r02.r02_tipo <> 'S' THEN
			LET stock_act =r_r11.r11_stock_act - r_dtrn.r20_cant_ven
			IF stock_act < 0 THEN
				LET mensaje = 'ERROR: El item ',
						r_r11.r11_item CLIPPED,
						' tiene stock insuficiente, ',
						'para generar esta ',
						'transferencia. Llame al',
						'ADMINISTRADOR.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				LET resul = 0
				EXIT FOREACH
			END IF
		END IF
	END IF
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_ant  = r_r11.r11_stock_act 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, r_dtrn.r20_item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act 
	LET r_r20.r20_fecing	 = fl_current()
	INSERT INTO rept020 VALUES(r_r20.*)
	UPDATE rept011
		SET r11_stock_act = r11_stock_act - r_dtrn.r20_cant_ven,
		    r11_egr_dia   = r11_egr_dia   + r_dtrn.r20_cant_ven
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = r_r19.r19_bodega_ori
		  AND r11_item     = r_dtrn.r20_item 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
				r_dtrn.r20_item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		INSERT INTO rept011
			(r11_compania, r11_bodega, r11_item, r11_ubicacion,
			 r11_stock_ant, r11_stock_act, r11_ing_dia, r11_egr_dia)
			VALUES(vg_codcia, r_r19.r19_bodega_dest,
				r_dtrn.r20_item, 'SN', 0,
				r_dtrn.r20_cant_ven, r_dtrn.r20_cant_ven, 0)
	ELSE
		UPDATE rept011
			SET r11_stock_act = r11_stock_act + r_dtrn.r20_cant_ven,
	      		    r11_ing_dia   = r11_ing_dia   + r_dtrn.r20_cant_ven
			WHERE r11_compania  = vg_codcia
			  AND r11_bodega    = r_r19.r19_bodega_dest
			  AND r11_item      = r_dtrn.r20_item 
	END IF
END FOREACH
IF resul THEN
	UPDATE rept019
		SET r19_tot_costo = r_r19.r19_tot_costo,
		    r19_tot_bruto = r_r19.r19_tot_bruto,
		    r19_tot_neto  = r_r19.r19_tot_bruto
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
ELSE
	DELETE FROM rept019
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = r_r19.r19_cod_tran
		  AND r19_num_tran  = r_r19.r19_num_tran
	UPDATE gent015
		SET g15_numero = r_r19.r19_num_tran - 1
		WHERE g15_compania  = vg_codcia
		  AND g15_localidad = vg_codloc
		  AND g15_modulo    = vg_modulo
		  AND g15_bodega    = "AA"
		  AND g15_tipo      = r_r19.r19_cod_tran
END IF
CALL imprimir_transferencia(r_r19.r19_cod_tran, r_r19.r19_num_tran)
LET mensaje = 'Se genero transferencia # ', r_r19.r19_num_tran USING "<<<<<<<&",
		'. De la bodega ', r_r19.r19_bodega_ori, ' a la bodega ',
		r_r19.r19_bodega_dest, '.'
CALL fl_mostrar_mensaje(mensaje, 'info')
RETURN resul, r_r19.*

END FUNCTION



FUNCTION imprimir_transferencia(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE param		VARCHAR(60)

LET param = ' "', cod_tran, '" ', num_tran
CALL fl_ejecuta_comando('REPUESTOS', vg_modulo, 'repp415 ', param, 1)

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

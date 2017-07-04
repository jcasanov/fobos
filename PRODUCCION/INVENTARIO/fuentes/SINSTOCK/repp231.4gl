------------------------------------------------------------------------------
-- Titulo           : repp231.4gl - Orden de Despacho de Bodega
-- Elaboracion      : 22-Ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp231 base módulo compañía localidad
--				[factura] [num_factura]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	CHAR(400)
DEFINE rm_r34		RECORD LIKE rept034.*
DEFINE rm_r35		RECORD LIKE rept035.*
DEFINE vm_bodega_real	LIKE rept036.r36_bodega_real
DEFINE vm_vendedor	LIKE rept001.r01_codigo
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE vm_max_elm       SMALLINT
DEFINE vm_num_repd      SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_grabado	SMALLINT 
DEFINE vm_flag_grabar	SMALLINT 
DEFINE vm_flag_mant     CHAR(1)
DEFINE vm_flag_bod	CHAR(1)
DEFINE vm_total_des     DECIMAL (8,2)
DEFINE vm_total_ent     DECIMAL (8,2)
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE r_desp 		ARRAY [1000] OF RECORD
				r35_item	LIKE rept035.r35_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r35_cant_des	LIKE rept035.r35_cant_des,
				r35_cant_ent	LIKE rept035.r35_cant_ent
			END RECORD
DEFINE vm_orden		ARRAY [1000] OF LIKE rept035.r35_orden



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN  -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp231'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i, resp		SMALLINT
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_retorna_usuario()
LET vm_max_rows = 1000
LET vm_max_elm  = 1000
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
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_mas FROM "../forms/repf231_1"
ELSE
	OPEN FORM f_mas FROM "../forms/repf231_1c"
END IF
DISPLAY FORM f_mas
CALL mostrar_botones_detalle()
FOR i = 1 TO vm_max_elm
	INITIALIZE r_desp[i].* TO NULL
END FOR
INITIALIZE rm_r34.*, rm_r35.* TO NULL
LET vm_num_rows     = 0
LET vm_row_current  = 0
LET vm_num_repd     = 0
LET vm_scr_lin      = 0 
LET vm_flag_grabar  = 0
LET vm_flag_mant    = 'N'
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Crear Nota Entrega'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Ver Nota Entrega'
		HIDE OPTION 'Imprimir Orden'
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Detalle'
			SHOW OPTION 'Ver Nota Entrega'
			SHOW OPTION 'Imprimir Orden'
			LET rm_r34.r34_cod_tran = arg_val(5)
			LET rm_r34.r34_num_tran = arg_val(6)
                        CALL control_consulta()
                        IF vm_num_rows = 0 THEN
                                EXIT PROGRAM
                        END IF
                	IF vm_num_rows > 1 THEN
                        	SHOW OPTION 'Avanzar'
			END IF
                	IF vm_row_current > 1 THEN
                        	SHOW OPTION 'Retroceder'
			END IF
		END IF
	COMMAND KEY('N') 'Crear Nota Entrega' 'Crear Nota Entrega registro corriente. '
		CALL mensaje_sin_cantidad_ent() RETURNING resp
		IF resp = 1 THEN
			CONTINUE MENU
		END IF
                CALL control_nota_entrega()
		IF vm_num_repd > vm_scr_lin THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        SHOW OPTION 'Crear Nota Entrega'
			SHOW OPTION 'Ver Nota Entrega'
			SHOW OPTION 'Imprimir Orden'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                                HIDE OPTION 'Crear Nota Entrega'
				HIDE OPTION 'Ver Nota Entrega'
				HIDE OPTION 'Imprimir Orden'
                        END IF
                ELSE
                        SHOW OPTION 'Crear Nota Entrega'
			SHOW OPTION 'Ver Nota Entrega'
                        SHOW OPTION 'Avanzar'
			SHOW OPTION 'Imprimir Orden'
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_repd > vm_scr_lin THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	 COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
                CALL muestra_siguiente_registro()
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                        SHOW OPTION 'Retroceder'
                        NEXT OPTION 'Retroceder'
                ELSE
                        SHOW OPTION 'Avanzar'
                        SHOW OPTION 'Retroceder'
                END IF
		IF num_args() = 4 THEN
			IF vm_num_repd > vm_scr_lin THEN
        	                SHOW OPTION 'Detalle'
                	ELSE
                        	HIDE OPTION 'Detalle'
     			END IF
               	ELSE
			SHOW OPTION 'Detalle'
     		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
                CALL muestra_anterior_registro()
                IF vm_row_current = 1 THEN
                        HIDE OPTION 'Retroceder'
                        SHOW OPTION 'Avanzar'
                        NEXT OPTION 'Avanzar'
                ELSE
                        SHOW OPTION 'Avanzar'
                        SHOW OPTION 'Retroceder'
                END IF
		IF num_args() = 4 THEN
			IF vm_num_repd > vm_scr_lin THEN
                	        SHOW OPTION 'Detalle'
         		ELSE
                        	HIDE OPTION 'Detalle'
                	END IF
               	ELSE
			SHOW OPTION 'Detalle'
     		END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalle del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('V') 'Ver Nota Entrega' 'Muestra Nota Entrega Generada. '
		CALL llamar_nota_entrega()
	COMMAND KEY('P') 'Imprimir Orden' 'Muestra Orden Despacho a imprimir.'
		CALL imprimir_orden()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION sub_menu()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*

LET vm_bodega_real = rm_r34.r34_bodega
CALL fl_lee_bodega_rep(vg_codcia, vm_bodega_real) RETURNING r_r02.*
DISPLAY BY NAME vm_bodega_real
DISPLAY r_r02.r02_nombre TO tit_bodega_real
LET vm_flag_bod = 'S'
MENU 'OPCIONES'
	BEFORE MENU
	        CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
		CALL fl_lee_bodega_rep(vg_codcia, vm_bodega_real)
			RETURNING r_r02.*
		IF r_r02.r02_tipo = 'S' THEN
			CALL leer_cabecera()
			IF int_flag THEN
				ROLLBACK WORK
				CLEAR FORM
				CALL mostrar_botones_detalle()
				IF vm_row_current > 0 THEN
	               			CALL mostrar_registro(
						vm_r_rows[vm_row_current], 0)
   	    			END IF
				EXIT MENU
			END IF
		END IF
		IF rm_r34.r34_bodega <> vm_bodega_real THEN
			CALL validar_bodeguero() RETURNING resul
			IF resul = 1 THEN
				EXIT MENU
			END IF
		END IF
		CALL leer_detalle()
		IF int_flag THEN
			ROLLBACK WORK
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
	               		CALL mostrar_registro(
						vm_r_rows[vm_row_current], 0)
       			END IF
			EXIT MENU
		END IF
	COMMAND KEY('C') 'Cabecera' 'Lee Cabecera del registro corriente. '
		CALL leer_cabecera()
		IF int_flag THEN
			IF vm_flag_mant = 'M' THEN
				ROLLBACK WORK
			END IF
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
	               		CALL mostrar_registro(
						vm_r_rows[vm_row_current], 0)
       			END IF
			EXIT MENU
		END IF
	COMMAND KEY('D') 'Detalle' 'Lee Detalle del registro corriente. '
		IF rm_r34.r34_bodega <> vm_bodega_real THEN
			CALL validar_bodeguero() RETURNING resul
			IF resul = 1 THEN
				EXIT MENU
			END IF
		END IF
		CALL leer_detalle()
		IF int_flag THEN
			IF vm_flag_mant = 'M' THEN
				ROLLBACK WORK
			END IF
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
	               		CALL mostrar_registro(
						vm_r_rows[vm_row_current], 0)
       			END IF
			EXIT MENU
		END IF
	COMMAND KEY('G') 'Generar' 'Genera Nota Entrega con registro corriente.'
		CALL control_generar()
		IF vm_grabado THEN
			EXIT MENU
		END IF
	COMMAND KEY('S') 'Salir' 'Sale del menú. '
		IF vm_flag_grabar = 1 THEN
			LET int_flag = 0
			--CALL fgl_winquestion(vg_producto,'Salir al menú principal y perder los cambios realizados ?','No','Yes|No|Cancel','question',1)
			CALL fl_hacer_pregunta('Salir al menú principal y perder los cambios realizados ?','No')
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				IF vm_flag_mant = 'M' THEN
					ROLLBACK WORK
        			END IF
				CLEAR FORM
				CALL mostrar_botones_detalle()
				IF vm_row_current > 0 THEN
		                	CALL mostrar_registro(
						vm_r_rows[vm_row_current], 0)
        			END IF
				EXIT MENU
			END IF
		ELSE
			CLEAR FORM
			CALL mostrar_botones_detalle()
			IF vm_row_current > 0 THEN
		               	CALL mostrar_registro(
						vm_r_rows[vm_row_current], 0)
       			END IF
			EXIT MENU
		END IF
END MENU
LET vm_bodega_real = NULL
CLEAR vm_bodega_real, tit_bodega_real

END FUNCTION



FUNCTION validar_bodeguero()
DEFINE r_r01		RECORD LIKE rept001.*

LET vm_vendedor = NULL
DECLARE q_vend CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_user_owner = vg_usuario
OPEN q_vend
FETCH q_vend INTO r_r01.*
IF STATUS = NOTFOUND THEN
	CLOSE q_vend
	FREE q_vend
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('El usuario ' || vg_usuario CLIPPED || ' no esta configurado como bodeguero y no puede continuar con este proceso.','exclamation')
	RETURN 1
END IF
CLOSE q_vend
FREE q_vend
LET vm_vendedor    = r_r01.r01_codigo
RETURN 0

END FUNCTION



FUNCTION control_generar()
DEFINE i		SMALLINT

LET vm_grabado = 0
IF vm_total_ent = 0 THEN
	CALL fl_mostrar_mensaje('No se puede generar Nota Entrega sin cantidad a entregar.','exclamation')
	RETURN
END IF
IF vm_flag_grabar THEN
	LET vm_grabado = 1
	UPDATE rept034 SET r34_estado	= rm_r34.r34_estado
		WHERE CURRENT OF q_up
	FOR i = 1 TO vm_num_repd
		IF r_desp[i].r35_cant_ent > 0 THEN
			UPDATE rept035 SET r35_cant_ent = r35_cant_ent +
							r_desp[i].r35_cant_ent
				WHERE r35_compania    = rm_r34.r34_compania
				  AND r35_localidad   = rm_r34.r34_localidad
				  AND r35_bodega      = rm_r34.r34_bodega
				  AND r35_num_ord_des = rm_r34.r34_num_ord_des
				  AND r35_item        = r_desp[i].r35_item
				  AND r35_orden       = vm_orden[i]
		END IF
	END FOR
	CALL generar_nota_entrega()
	COMMIT WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current], 1)
	CALL fl_mensaje_registro_modificado()
END IF
LET vm_flag_grabar = 0
WHENEVER ERROR STOP

END FUNCTION



FUNCTION generar_nota_entrega()
DEFINE i		SMALLINT
DEFINE num_entrega	INTEGER
DEFINE r_r02		RECORD LIKE rept002.*

SELECT MAX(r36_num_entrega) INTO num_entrega
	FROM rept036
	WHERE r36_compania    = rm_r34.r34_compania
	  AND r36_localidad   = rm_r34.r34_localidad
	  AND r36_bodega      = rm_r34.r34_bodega
IF num_entrega IS NULL THEN
	LET num_entrega = 1
ELSE
	LET num_entrega = num_entrega + 1
END IF
INSERT INTO rept036 VALUES (rm_r34.r34_compania, rm_r34.r34_localidad,
	rm_r34.r34_bodega, num_entrega, rm_r34.r34_num_ord_des, 'A',
	rm_r34.r34_fec_entrega, rm_r34.r34_entregar_a, rm_r34.r34_entregar_en,
	vm_bodega_real, vg_usuario, CURRENT)
FOR i = 1 TO vm_num_repd
	IF r_desp[i].r35_cant_ent > 0 THEN
		INSERT INTO rept037 VALUES (rm_r34.r34_compania,
			rm_r34.r34_localidad, rm_r34.r34_bodega, 
			num_entrega, r_desp[i].r35_item, vm_orden[i],
			r_desp[i].r35_cant_ent)
		UPDATE rept020 SET r20_cant_ent = r20_cant_ent +
						  r_desp[i].r35_cant_ent
			WHERE r20_compania  = rm_r34.r34_compania
			  AND r20_localidad = rm_r34.r34_localidad
			  AND r20_cod_tran  = rm_r34.r34_cod_tran
			  AND r20_num_tran  = rm_r34.r34_num_tran
			  AND r20_bodega    = rm_r34.r34_bodega
			  AND r20_item      = r_desp[i].r35_item
			  AND r20_orden     = vm_orden[i]
	END IF
END FOR
IF rm_r34.r34_bodega <> vm_bodega_real THEN
	-- OJO REVISAR
	CALL fl_lee_bodega_rep(vg_codcia, vm_bodega_real) RETURNING r_r02.*
	IF r_r02.r02_localidad = vg_codloc THEN
		CALL generar_transferencia(num_entrega)
	END IF
	--
	-- CALL generar_transferencia(num_entrega)
END IF

END FUNCTION



FUNCTION generar_transferencia(num_entrega)
DEFINE num_entrega	VARCHAR(10)
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE num_tran		VARCHAR(15)
DEFINE j		SMALLINT

INITIALIZE r_r19.* TO NULL
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
LET r_r19.r19_referencia	= 'TR. AUTO. SIN STOCK GEN. POR NE # ',
					num_entrega
LET r_r19.r19_nomcli		= ' '
LET r_r19.r19_dircli     	= ' '
LET r_r19.r19_cedruc     	= ' '
LET r_r19.r19_vendedor   	= vm_vendedor
LET r_r19.r19_descuento  	= 0.0
LET r_r19.r19_porc_impto 	= 0.0
LET r_r19.r19_bodega_ori 	= vm_bodega_real
LET r_r19.r19_bodega_dest	= rm_r34.r34_bodega
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
FOR j = 1 TO vm_num_repd
	IF r_desp[j].r35_cant_ent = 0 THEN
		CONTINUE FOR
	END IF
	CALL fl_lee_item(vg_codcia, r_desp[j].r35_item) RETURNING r_r10.*
	LET r_r19.r19_tot_costo = r_r19.r19_tot_costo + 
				  (r_desp[j].r35_cant_ent * r_r10.r10_costo_mb)
	LET r_r20.r20_cant_ped   = r_desp[j].r35_cant_ent
	LET r_r20.r20_cant_ven   = r_desp[j].r35_cant_ent
	LET r_r20.r20_bodega     = r_r19.r19_bodega_ori
	LET r_r20.r20_item       = r_desp[j].r35_item 
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
				r_desp[j].r35_item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_ant  = r_r11.r11_stock_act 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
				r_desp[j].r35_item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		LET r_r11.r11_stock_act = 0
	END IF
	LET r_r20.r20_stock_bd   = r_r11.r11_stock_act 
	LET r_r20.r20_fecing	 = CURRENT
	INSERT INTO rept020 VALUES(r_r20.*)
	UPDATE rept011 SET r11_stock_act = r11_stock_act -
					   r_desp[j].r35_cant_ent,
		           r11_egr_dia   = r11_egr_dia + r_desp[j].r35_cant_ent
		WHERE r11_compania = vg_codcia
		  AND r11_bodega   = r_r19.r19_bodega_ori
		  AND r11_item     = r_desp[j].r35_item 
	CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
				r_desp[j].r35_item)
		RETURNING r_r11.*
	IF r_r11.r11_stock_act IS NULL THEN
		INSERT INTO rept011
      			(r11_compania, r11_bodega, r11_item, 
		 	r11_ubicacion, r11_stock_ant, 
		 	r11_stock_act, r11_ing_dia,
		 	r11_egr_dia)
		VALUES(vg_codcia, r_r19.r19_bodega_dest,
		       r_desp[j].r35_item, 'SN', 0, r_desp[j].r35_cant_ent, 
		       r_desp[j].r35_cant_ent, 0) 
	ELSE
		UPDATE rept011 
			SET   r11_stock_act = r11_stock_act + 
					      r_desp[j].r35_cant_ent,
	      		      r11_ing_dia   = r11_ing_dia +
					      r_desp[j].r35_cant_ent
			WHERE r11_compania  = vg_codcia
			AND   r11_bodega    = r_r19.r19_bodega_dest
			AND   r11_item      = r_desp[j].r35_item 
	END IF
END FOR 
LET j = vm_num_repd
UPDATE rept019 SET r19_tot_bruto = r_r19.r19_tot_bruto,
		   r19_tot_neto  = r_r19.r19_tot_bruto
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = r_r19.r19_cod_tran
	  AND r19_num_tran  = r_r19.r19_num_tran
LET num_tran = r_r19.r19_num_tran
CALL fl_mostrar_mensaje('Se genero transferencia automatica No. ' ||
			num_tran || '. De la bodega ' || r_r19.r19_bodega_ori ||
			' a la bodega ' || r_r19.r19_bodega_dest || '.','info')

END FUNCTION



FUNCTION control_nota_entrega()
	
CALL mostrar_botones_detalle()
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current], 0)
IF rm_r34.r34_estado <> 'A' AND rm_r34.r34_estado <> 'P' THEN
	--CALL fgl_winmessage(vg_producto,'Orden de despacho ya ha sido despachada.','exclamation')
	CALL fl_mostrar_mensaje('Orden de despacho ya ha sido despachada.','exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rept034
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_r34.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current], 0)
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
IF rm_r34.r34_fec_entrega < TODAY THEN
	LET rm_r34.r34_fec_entrega = TODAY
END IF
LET vm_flag_mant = 'M'
CALL sub_menu()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(600)
DEFINE num_reg		INTEGER
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE estado		CHAR(1)

CLEAR FORM
CALL mostrar_botones_detalle()
LET estado = NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON r34_bodega, r34_num_ord_des, r34_estado,
		r34_cod_tran, r34_num_tran, r34_fec_entrega, r34_entregar_a,
		r34_entregar_en
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			LET rm_r34.r34_bodega = GET_FLDBUF(r34_bodega)	
			IF INFIELD(r34_num_ord_des) THEN
				CALL fl_ayuda_orden_despacho(vg_codcia,
						vg_codloc, rm_r34.r34_bodega,
						estado)
					RETURNING r_r34.r34_bodega,
						  r_r34.r34_num_ord_des
				LET int_flag = 0
				IF r_r34.r34_num_ord_des IS NOT NULL THEN
					CALL fl_lee_orden_despacho(vg_codcia,
							vg_codloc,
							r_r34.r34_bodega, 
							r_r34.r34_num_ord_des)
						RETURNING r_r34.*
					DISPLAY BY NAME r_r34.r34_num_ord_des,
							r_r34.r34_bodega, 
							r_r34.r34_cod_tran,
							r_r34.r34_num_tran,
							r_r34.r34_fec_entrega,
							r_r34.r34_entregar_a
					CALL muestra_estado(r_r34.r34_estado)
				END IF
			END IF
			IF INFIELD(r34_bodega) THEN
				CALL fl_ayuda_bodegas_rep(vg_codcia, 'T')
					RETURNING r_r02.r02_codigo,
						  r_r02.r02_nombre 
				LET int_flag = 0
				IF r_r02.r02_codigo IS NOT NULL THEN
					DISPLAY r_r02.r02_codigo TO r34_bodega
					DISPLAY r_r02.r02_nombre TO tit_bodega
				END IF
			END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		AFTER FIELD r34_bodega
			LET rm_r34.r34_bodega = GET_FLDBUF(r34_bodega)	
			IF rm_r34.r34_bodega IS NOT NULL THEN
				CALL fl_lee_bodega_rep(vg_codcia,
							rm_r34.r34_bodega)
					RETURNING r_r02.*
				IF r_r02.r02_compania IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'No existe esa Bodega.','exclamation')
					CALL fl_mostrar_mensaje('No existe esa Bodega.','exclamation')
					NEXT FIELD r34_bodega
				END IF
        	                IF r_r02.r02_estado = 'B' THEN
                	                CALL fl_mensaje_estado_bloqueado()
                        	        NEXT FIELD r34_bodega
	                        END IF
				DISPLAY r_r02.r02_nombre TO tit_bodega
			ELSE
				CALL fl_mostrar_mensaje('Digite bodega.','exclamation')
				NEXT FIELD r34_bodega
			END IF
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(vm_r_rows[vm_row_current], 0)
		ELSE
			CLEAR FORM
			CALL mostrar_botones_detalle()
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = ' r34_cod_tran = "', rm_r34.r34_cod_tran, '"',
	               ' AND r34_num_tran = ', rm_r34.r34_num_tran
END IF
LET query = 'SELECT ROWID FROM rept034 ' ||
		'WHERE r34_compania  = ' || vg_codcia ||
		'  AND r34_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	LET vm_num_repd    = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL mostrar_botones_detalle()
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL muestra_contadores_det(0)
	CALL mostrar_registro(vm_r_rows[vm_row_current], 0)
END IF

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE bodega		LIKE rept036.r36_bodega_real
DEFINE fecha_ent	DATE

LET int_flag = 0
INPUT BY NAME vm_bodega_real, rm_r34.r34_fec_entrega, rm_r34.r34_entregar_a,
	rm_r34.r34_entregar_en
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(vm_bodega_real, rm_r34.r34_fec_entrega,
			rm_r34.r34_entregar_a, rm_r34.r34_entregar_en)
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET vm_flag_grabar = 0
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(vm_bodega_real) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, 'F')
				RETURNING r_r02.r02_codigo,
					  r_r02.r02_nombre 
			LET int_flag = 0
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET vm_bodega_real = r_r02.r02_codigo
				DISPLAY r_r02.r02_codigo TO vm_bodega_real
				DISPLAY r_r02.r02_nombre TO tit_bodega_real
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_bodega_real
		LET bodega = vm_bodega_real
		IF vm_flag_bod = 'S' THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega_real)
				RETURNING r_r02.*
			IF r_r02.r02_tipo <> 'S' THEN
				NEXT FIELD NEXT
			END IF
		END IF
	BEFORE FIELD r34_fec_entrega
		LET fecha_ent = rm_r34.r34_fec_entrega
	AFTER FIELD vm_bodega_real
		LET vm_flag_bod = 'N'
		IF vm_bodega_real IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega_real)
				RETURNING r_r02.*
			DISPLAY r_r02.r02_nombre TO tit_bodega_real
			IF r_r02.r02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe esa Bodega.','exclamation')
				CALL fl_mostrar_mensaje('No existe esa Bodega.','exclamation')
				NEXT FIELD vm_bodega_real
			END IF
                        IF r_r02.r02_estado = 'B' THEN
               	                CALL fl_mensaje_estado_bloqueado()
                       	        NEXT FIELD vm_bodega_real
	                END IF
                        IF r_r02.r02_factura = 'N' THEN
				CALL fl_mostrar_mensaje('Digite una bodega de facturacion.','exclamation')
                       	        NEXT FIELD vm_bodega_real
	                END IF
                        IF r_r02.r02_tipo <> 'F' AND r_r02.r02_area <> 'T' THEN
				CALL fl_mostrar_mensaje('Digite una bodega fisica.','exclamation')
                       	        NEXT FIELD vm_bodega_real
	                END IF
                        IF r_r02.r02_localidad <> vg_codloc THEN
				CALL fl_mostrar_mensaje('Digite una bodega de esta localidad.','exclamation')
                       	        NEXT FIELD vm_bodega_real
	                END IF
		ELSE
			LET vm_bodega_real = bodega
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega_real)
				RETURNING r_r02.*
			DISPLAY BY NAME vm_bodega_real
			DISPLAY r_r02.r02_nombre TO tit_bodega_real
			CALL fl_mostrar_mensaje('No puede dejar en blanco Bodega de Entrega.','info')
			NEXT FIELD vm_bodega_real
		END IF
	AFTER FIELD r34_fec_entrega
		IF rm_r34.r34_fec_entrega IS NOT NULL THEN
			IF rm_r34.r34_fec_entrega < TODAY THEN
				LET rm_r34.r34_fec_entrega = fecha_ent
			END IF
		ELSE
			LET rm_r34.r34_fec_entrega = fecha_ent
		END IF
		DISPLAY BY NAME rm_r34.r34_fec_entrega
END INPUT

END FUNCTION



FUNCTION leer_detalle()
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r35		RECORD LIKE rept035.*
DEFINE salir		SMALLINT

LET i 	     = 1
LET resul    = 0
LET salir    = 0
OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
WHILE NOT salir
	CALL set_count(vm_num_repd)
	LET int_flag = 0
	INPUT ARRAY r_desp WITHOUT DEFAULTS FROM r_desp.*
		ON KEY(INTERRUPT)
       			LET int_flag = 0
	               	CALL fl_mensaje_abandonar_proceso()
		               	RETURNING resp
       			IF resp = 'Yes' THEN
				CALL muestra_lineas_detalle()
				CALL muestra_contadores_det(0)
				LET vm_flag_grabar = 0
 	      			LET int_flag = 1
				EXIT WHILE	
       	       		END IF	
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
			CALL retorna_tam_arr()
			LET vm_scr_lin = vm_size_arr
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
	       		LET i = arr_curr()
       			LET j = scr_line()
			CALL muestra_contadores_det(i)
			CALL muestra_descripciones(r_desp[i].r35_item,
					r_r10.r10_linea, r_r10.r10_sub_linea,
					r_r10.r10_cod_grupo, 
					r_r10.r10_cod_clase)
			DISPLAY r_r10.r10_nombre TO nom_item
		BEFORE INSERT
			EXIT INPUT
		BEFORE FIELD r35_cant_ent
			LET r_r35.r35_cant_ent = r_desp[i].r35_cant_ent
		AFTER FIELD r35_cant_ent
			IF r_desp[i].r35_cant_ent IS NOT NULL THEN
				IF r_desp[i].r35_cant_ent < 0 OR
				   r_desp[i].r35_cant_ent >
				   r_desp[i].r35_cant_des THEN
					NEXT FIELD r35_cant_ent
				END IF
--ESPERAR ORDEN DE HABILITAR CUANDO SE HAGA TRANSF. AUTOMATICA (HABILITADO)
--
				IF vm_flag_bod = 'N' AND
				   r_desp[i].r35_cant_ent > 0 THEN
					CALL fl_lee_stock_rep(vg_codcia,
								vm_bodega_real,
							r_desp[i].r35_item)
						RETURNING r_r11.*
					IF r_r11.r11_compania IS NULL THEN
						LET r_r11.r11_stock_act = 0
					END IF
					IF r_desp[i].r35_cant_ent >
					   r_r11.r11_stock_act THEN
						CALL fl_mostrar_mensaje('Esta cantidad de este item es mayor que el stock de la bodega de entrega.','exclamation')
						NEXT FIELD r35_cant_ent
					END IF
				END IF
			ELSE
				LET r_desp[i].r35_cant_ent = r_r35.r35_cant_ent
				DISPLAY r_desp[i].r35_cant_ent
					TO r_desp[j].r35_cant_ent
				NEXT FIELD r35_cant_ent
			END IF
			CALL sacar_total()
		AFTER INPUT
			IF vm_total_ent < vm_total_des THEN
				LET rm_r34.r34_estado = 'P'
			END IF
			IF vm_total_ent = vm_total_des THEN
				LET rm_r34.r34_estado = 'D'
			END IF
			LET vm_flag_grabar = 1
			LET salir = 1
	END INPUT
END WHILE
LET vm_num_repd = arr_count()
RETURN

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT
DEFINE tot_cant		DECIMAL (8,2)

LET vm_total_des = 0
LET vm_total_ent = 0
FOR i = 1 TO vm_num_repd
	LET vm_total_des = vm_total_des + r_desp[i].r35_cant_des
	LET vm_total_ent = vm_total_ent + r_desp[i].r35_cant_ent
END FOR
DISPLAY BY NAME vm_total_des, vm_total_ent 

END FUNCTION



FUNCTION muestra_siguiente_registro()
                                                                                
IF vm_row_current < vm_num_rows THEN
        LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current], 0)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
                                                                                
END FUNCTION



FUNCTION muestra_anterior_registro()
                                                                                
IF vm_row_current > 1 THEN
        LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current], 0)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_contadores_det(0)
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY row_current, " de ", num_rows AT 1, 68
END IF
                                                                                
END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor                 SMALLINT
                                                                                
DISPLAY "" AT 9, 1
DISPLAY cor, " de ", vm_num_repd AT 9, 63
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_reg, flag_sql)
DEFINE num_reg		INTEGER
DEFINE flag_sql		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE mensaje		VARCHAR(100)

IF vm_num_rows > 0 THEN
        DECLARE q_dt CURSOR FOR SELECT * FROM rept034
                WHERE ROWID = num_reg
        OPEN q_dt
        FETCH q_dt INTO rm_r34.*
        IF STATUS = NOTFOUND THEN
		LET mensaje ='No existe registro con ROWID: ' || vm_row_current
        	--CALL fgl_winmessage (vg_producto, mensaje, 'exclamation')
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
                RETURN
        END IF	
	IF rm_r34.r34_fec_entrega < TODAY THEN
		LET rm_r34.r34_fec_entrega = TODAY
	END IF
	DISPLAY BY NAME rm_r34.r34_num_ord_des, rm_r34.r34_cod_tran,
			rm_r34.r34_num_tran, rm_r34.r34_bodega,
			rm_r34.r34_fec_entrega, rm_r34.r34_entregar_a,
			rm_r34.r34_entregar_en
	CALL fl_lee_bodega_rep(vg_codcia, rm_r34.r34_bodega) RETURNING r_r02.*
        DISPLAY r_r02.r02_nombre TO tit_bodega
	CALL muestra_estado(rm_r34.r34_estado)
	CALL muestra_detalle(rm_r34.r34_bodega, rm_r34.r34_num_ord_des,
				flag_sql)
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION muestra_detalle(bodega, num_ord, flag_sql)
DEFINE flag_sql		SMALLINT
DEFINE bodega		LIKE rept034.r34_bodega
DEFINE num_ord          LIKE rept034.r34_num_ord_des
DEFINE query            CHAR(800)
DEFINE expr_sql         VARCHAR(100)
DEFINE i		SMALLINT
DEFINE r_desp_aux 	RECORD
				r35_item	LIKE rept035.r35_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r35_cant_des	LIKE rept035.r35_cant_des,
				r35_cant_ent	LIKE rept035.r35_cant_ent
			END RECORD
DEFINE orden		LIKE rept035.r35_orden

CALL retorna_tam_arr()
LET vm_scr_lin = vm_size_arr
LET int_flag = 0
FOR i = 1 TO vm_scr_lin
        INITIALIZE r_desp[i].* TO NULL
        CLEAR r_desp[i].*
END FOR
IF flag_sql THEN
	LET expr_sql = ' r35_cant_des - r35_cant_ent, 0, '
ELSE
	LET expr_sql = ' r35_cant_des, r35_cant_ent, '
END IF
LET query = 'SELECT r35_item, r10_nombre, ' || expr_sql CLIPPED ||
		' r35_orden ' ||
		'FROM rept035, rept010 ' ||
                'WHERE r35_compania    = ' || vg_codcia ||
		'  AND r35_localidad   = ' || vg_codloc ||
		'  AND r35_bodega      = "' || bodega || '"',
		'  AND r35_num_ord_des = ' || num_ord ||
		'  AND r35_compania    = r10_compania ' ||
		'  AND r35_item        = r10_codigo ' ||
		'ORDER BY r35_orden'
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET i = 1
LET vm_num_repd = 0
FOREACH q_cons1 INTO r_desp_aux.*, orden
	IF r_desp_aux.r35_cant_des = 0 AND flag_sql THEN
		CONTINUE FOREACH
	END IF
	LET r_desp[i].* = r_desp_aux.*
	LET vm_orden[i] = orden
        LET i = i + 1
        LET vm_num_repd = vm_num_repd + 1
        IF vm_num_repd > vm_max_elm THEN
        	LET vm_num_repd = vm_num_repd - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
        END IF
END FOREACH
IF vm_num_repd > 0 THEN
        LET int_flag = 0
	CALL muestra_contadores_det(0)
	CALL muestra_lineas_detalle()
END IF
CALL sacar_total()
IF int_flag THEN
	INITIALIZE r_desp[1].* TO NULL
        RETURN
END IF

END FUNCTION



FUNCTION muestra_lineas_detalle()
DEFINE i		SMALLINT
DEFINE lineas		SMALLINT

CALL retorna_tam_arr()
LET lineas = vm_size_arr
FOR i = 1 TO lineas
	IF i <= vm_num_repd THEN
		DISPLAY r_desp[i].* TO r_desp[i].*
	ELSE
		CLEAR r_desp[i].*
	END IF
END FOR

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i,j,l,col	SMALLINT
DEFINE query		CHAR(800)
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_desp_aux 	RECORD
				r35_item	LIKE rept035.r35_item,
				r10_nombre	LIKE rept010.r10_nombre,
				r35_cant_des	LIKE rept035.r35_cant_des,
				r35_cant_ent	LIKE rept035.r35_cant_ent
			END RECORD
DEFINE orden		LIKE rept035.r35_orden

CALL mostrar_botones_detalle()
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up2 CURSOR FOR SELECT * FROM rept034
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO r_r34.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current], 0)
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET query = 'SELECT r35_item, r10_nombre, r35_cant_des, r35_cant_ent, ',
		' r35_orden ',
		'FROM rept035, rept010 ',
                'WHERE r35_compania   = ', vg_codcia,
		' AND r35_localidad   = ', vg_codloc,
		' AND r35_bodega      = "', rm_r34.r34_bodega, '"',
		' AND r35_num_ord_des = ',  rm_r34.r34_num_ord_des,
		' AND r35_compania    = r10_compania ', 
		' AND r35_item        = r10_codigo '
PREPARE det FROM query
DECLARE q_det CURSOR FOR det
LET vm_num_repd = 1
FOREACH q_det INTO r_desp_aux.*, orden
	LET r_desp[vm_num_repd].* = r_desp_aux.*
	LET vm_orden[vm_num_repd] = orden
        LET vm_num_repd = vm_num_repd + 1
        IF vm_num_repd > vm_max_elm THEN
		EXIT FOREACH
        END IF
END FOREACH
LET vm_num_repd = vm_num_repd - 1
LET int_flag = 0
CALL set_count(vm_num_repd)
CALL retorna_tam_arr()
LET vm_scr_lin = vm_size_arr
DISPLAY ARRAY r_desp TO r_desp.*
	ON KEY(INTERRUPT)
		CLEAR nom_item, descrip_2, descrip_3, descrip_4	
		EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		CALL llamar_nota_entrega()
		LET int_flag = 0
	ON KEY(F6)
		CALL imprimir_orden()
		LET int_flag = 0
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL fl_lee_item(vg_codcia,r_desp[i].r35_item) 
			RETURNING r_r10.*  
		DISPLAY r_r10.r10_nombre TO nom_item 
		CALL muestra_descripciones(r_desp[i].r35_item,
			r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, 
			r_r10.r10_cod_clase)
	--#BEFORE ROW
		--#LET i = arr_curr()
        	--#LET j = scr_line()
		--#CALL muestra_contadores_det(i)
		--#CALL muestra_descripciones(r_desp[i].r35_item,
				--#r_r10.r10_linea, r_r10.r10_sub_linea,
				--#r_r10.r10_cod_grupo, 
				--#r_r10.r10_cod_clase)
		--#DISPLAY r_r10.r10_nombre TO nom_item
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
		--#CALL dialog.keysetlabel("F5","Nota Entrega")
		--#CALL dialog.keysetlabel("F6","Imprimir Orden")
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
IF int_flag = 1 THEN
	CALL muestra_contadores_det(0)
	ROLLBACK WORK
	RETURN
END IF
COMMIT WORK

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		LIKE rept034.r34_estado
                                                                                
IF estado = 'A' THEN
        DISPLAY 'ACTIVA' TO tit_estado_rep
END IF
IF estado = 'D' THEN
        DISPLAY 'DESPACHADA' TO tit_estado_rep
END IF
IF estado = 'P' THEN
        DISPLAY 'PARCIAL' TO tit_estado_rep
END IF
IF estado = 'E' THEN
        DISPLAY 'ANULADA' TO tit_estado_rep
END IF
DISPLAY estado TO r34_estado
                                                                                
END FUNCTION



FUNCTION mostrar_botones_detalle()

--#DISPLAY 'Item'        TO tit_col1
--#DISPLAY 'Descripción' TO tit_col2
--#DISPLAY 'C.D.'        TO tit_col3
--#DISPLAY 'C.E.'        TO tit_col4

END FUNCTION


 
FUNCTION llamar_nota_entrega()
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp314 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_r34.r34_bodega, ' ', rm_r34.r34_num_ord_des
RUN vm_nuevoprog

END FUNCTION



FUNCTION imprimir_orden()
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'repp431 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ',
	rm_r34.r34_bodega, ' ', rm_r34.r34_num_ord_des
RUN vm_nuevoprog

END FUNCTION



FUNCTION mensaje_sin_cantidad_ent()

IF vm_total_ent = 0 AND vm_total_des = 0 THEN
	--CALL fgl_winmessage(vg_producto,'No se puede generar Nota Entrega sin tener cantidad a despachar.','exclamation')
	CALL fl_mostrar_mensaje('No se puede generar Nota Entrega sin tener cantidad a despachar.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_desp')
IF vg_gui = 0 THEN
	LET vm_size_arr = 5
END IF

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
--DISPLAY r_r03.r03_nombre     TO descrip_1
DISPLAY r_r70.r70_desc_sub   TO descrip_2
DISPLAY r_r71.r71_desc_grupo TO descrip_3
DISPLAY r_r72.r72_desc_clase TO descrip_4

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
DISPLAY '<F5>      Ver Nota Entrega'         AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Imprimir Orden Despacho'  AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

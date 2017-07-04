--------------------------------------------------------------------------------
-- Titulo           : ordp204.4gl - Anulación Recepcion de Ordenes de Compra
-- Elaboracion      : 15-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun ordp204 base modulo compania localidad [orden c.]
-- Ultima Correccion: 15-dic-2001
-- Motivo Correccion: 1
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------
DEFINE rm_c10		RECORD LIKE ordt010.*	-- CABECERA
DEFINE rm_c13		RECORD LIKE ordt013.*	-- DETALLE
DEFINE rm_c14		RECORD LIKE ordt014.*	-- DETALLE
DEFINE rm_p01		RECORD LIKE cxpt001.*	-- PROVEEDORES

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle	ARRAY[250] OF RECORD
				c14_cantidad	LIKE ordt014.c14_cantidad,
				c14_codigo	LIKE ordt014.c14_codigo,
				c14_descrip	LIKE ordt014.c14_descrip,
				c14_descuento	LIKE ordt014.c14_descuento,
				c14_precio	LIKE ordt014.c14_precio
			END RECORD
	---------------------------------------------

DEFINE vm_estado	LIKE ordt010.c10_estado
DEFINE vm_ind_arr	SMALLINT   -- INDICE DE MI ARREGLO  (ARRAY)
DEFINE vm_size_arr	SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_size_arr2	SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_max_detalle	SMALLINT   -- MAXIMO NUMERO DE ELEMENTOS DEL
DEFINE vm_num_recep	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_rows_recep	ARRAY[50] OF INTEGER
DEFINE vg_oc		LIKE ordt013.c13_numero_oc
---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE FORMA DE PAGO ----
	---- ARREGLO PARA LA FORMA DE PAGO ----
DEFINE r_detalle_2	ARRAY[250] OF RECORD
				c15_dividendo	LIKE ordt015.c15_dividendo,
				c15_fecha_vcto	LIKE ordt015.c15_fecha_vcto,
				c15_valor_cap	LIKE ordt015.c15_valor_cap,
				c15_valor_int	LIKE ordt015.c15_valor_int,
				subtotal	LIKE ordt015.c15_valor_cap
			END RECORD
-------------------------------------------------------
DEFINE pagos		SMALLINT
DEFINE tot_dias		SMALLINT	
DEFINE fecha_pago	DATE
DEFINE dias_pagos	SMALLINT
DEFINE tot_recep	LIKE ordt010.c10_tot_compra
DEFINE tot_cap		LIKE ordt010.c10_tot_compra
DEFINE tot_int		LIKE ordt010.c10_tot_compra
DEFINE tot_sub		LIKE ordt010.c10_tot_compra
---------------------------------------------------------------
DEFINE vm_transaccion   LIKE rept019.r19_cod_tran
DEFINE vm_dev_tran      LIKE rept019.r19_cod_tran
DEFINE vm_nota_credito  LIKE rept019.r19_cod_tran
DEFINE vm_fact_nue	LIKE ordt013.c13_factura



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp204.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN    -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_oc      = arg_val(5)
LET vg_proceso = 'ordp204'
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
DEFINE done		SMALLINT
DEFINE command_run	VARCHAR(200)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE resp		CHAR(6)

CALL fl_nivel_isolation()
LET vm_max_detalle  = 250
LET vm_estado       = 'C'
LET vm_dev_tran     = 'CL'       
LET vm_nota_credito = 'NC'
OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
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
OPEN WINDOW w_204 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_204 FROM '../forms/ordf204_1'
ELSE
	OPEN FORM f_204 FROM '../forms/ordf204_1c'
END IF
DISPLAY FORM f_204
CALL control_DISPLAY_botones()
CALL retorna_tam_arr()
INITIALIZE rm_c10.*, rm_c13.*, rm_c14.*, rm_p01.* TO NULL
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Anular'
		HIDE OPTION 'Ver Orden'
		HIDE OPTION 'Ver Recepción'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF num_args() = 5 THEN
			HIDE OPTION 'Anulación'
			SHOW OPTION 'Ver Recepción'
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc, vg_oc)
				RETURNING rm_c10.*
			IF rm_c10.c10_numero_oc IS NULL THEN
				CALL fl_mostrar_mensaje('La orden de compra no existe.','stop')
				EXIT PROGRAM
			END IF
			CALL control_cargar_rowid_recepcion(vg_oc)
			IF vm_num_recep = 0 THEN
				CALL fl_mostrar_mensaje('La orden de compra no tiene ninguna recepción anulada.','stop')
				EXIT PROGRAM
			END IF
			LET vm_row_current = 1
			CALL control_muestra_recepcion(vm_rows_recep[vm_row_current], 2)
			CALL muestra_contadores()
			IF vm_num_recep > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
			IF vm_ind_arr > vm_size_arr THEN
				SHOW OPTION 'Ver Detalle'
			END IF
		END IF
	COMMAND KEY('N') 'Anulación' 'Anulación Recepción de Ordenes de Compra.'
		LET done = control_anulacion()
		IF done = 0 THEN
			CLEAR FORM
			CALL control_DISPLAY_botones()
			HIDE OPTION 'Forma de Pago'
			HIDE OPTION 'Anular'
			HIDE OPTION 'Ver Orden'
		ELSE
			HIDE OPTION 'Anulación'
			SHOW OPTION 'Anular'
			SHOW OPTION 'Ver Orden'
		END IF
		IF rm_c10.c10_tipo_pago = 'R' AND done <> 0 THEN
			SHOW OPTION 'Forma de Pago'
		END IF
	COMMAND KEY('X') 'Ver Recepción' 'Ver la Recepción por Orden de Compra.'
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			LET command_run = run_prog || 'ordp202 ' || vg_base
					|| ' ' || vg_modulo || ' ' || vg_codcia 
					|| ' ' || vg_codloc || ' ' ||
					rm_c13.c13_numero_oc
			RUN command_run
		END IF
	COMMAND KEY('V') 'Ver Orden' 'Ver la Orden de Compra.'
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			LET command_run = run_prog || 'ordp200 ' || vg_base
					|| ' ' || vg_modulo || ' ' || vg_codcia 
					|| ' ' || vg_codloc || ' ' ||
					rm_c13.c13_numero_oc
			RUN command_run
		END IF
	COMMAND KEY('G') 'Anular'  'Anular Recepción.'
		CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET done = control_anular()
			IF done THEN
				HIDE OPTION 'Forma de Pago'
				HIDE OPTION 'Anular'
				HIDE OPTION 'Ver Orden'
				SHOW OPTION 'Anulación'
			END IF
		END IF
	COMMAND KEY('F') 'Forma de Pago'  'Forma de Pago de Recepción.'
		CALL control_forma_pago_recep()
	COMMAND KEY('D') 'Ver Detalle' 'Ver Detalle de la Recepción.'
		CALL control_DISPLAY_array_ordt014()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente anulación.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_recep THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_ind_arr > vm_size_arr THEN
			SHOW OPTION 'Ver Detalle'
		END IF
	COMMAND KEY('R') 'Retroceder' 'Ver anterior anulacióon.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_ind_arr > vm_size_arr THEN
			SHOW OPTION 'Ver Detalle'
		END IF
	COMMAND KEY('S') 'Salir'  'Salir del Programa.'
		EXIT MENU
END MENU
		
END FUNCTION



FUNCTION muestra_contadores()

IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_recep AT 1, 67 
END IF

END FUNCTION



FUNCTION siguiente_registro()

IF vm_row_current < vm_num_recep THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL control_muestra_recepcion(vm_rows_recep[vm_row_current], 2)
CALL muestra_contadores()

END FUNCTION



FUNCTION anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL control_muestra_recepcion(vm_rows_recep[vm_row_current], 2)
CALL muestra_contadores()

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'Cant'		TO tit_col1
--#DISPLAY 'Código'		TO tit_col2
--#DISPLAY 'Descripción' 	TO tit_col3
--#DISPLAY 'Des %'  		TO tit_col4
--#DISPLAY 'Precio'		TO tit_col5

END FUNCTION



FUNCTION control_DISPLAY_botones_2()

--#DISPLAY '#' 	 		TO tit_col1
--#DISPLAY 'Fecha Vcto'		TO tit_col2
--#DISPLAY 'Valor Capital'	TO tit_col3
--#DISPLAY 'Valor Interes'	TO tit_col4
--#DISPLAY 'Subtotal'		TO tit_col5

END FUNCTION



FUNCTION control_cargar_rowid_recepcion(oc)
DEFINE oc 		LIKE ordt013.c13_numero_oc
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE i 		SMALLINT
DEFINE estado 		LIKE ordt013.c13_estado

IF num_args() = 4 THEN
	LET estado = 'A'
ELSE
	LET estado = 'E'
END IF
DECLARE q_ordt013 CURSOR FOR
        SELECT *, ROWID FROM ordt013
               WHERE c13_compania  = vg_codcia
                 AND c13_localidad = vg_codloc
                 AND c13_numero_oc = oc
                 AND c13_estado    = estado
LET i = 1
FOREACH q_ordt013 INTO r_c13.*, vm_rows_recep[i]
        LET i = i + 1
        IF i > 50 THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_recep = i - 1

END FUNCTION



FUNCTION control_muestra_recepcion(row, flag)
DEFINE flag	 	SMALLINT
DEFINE row		INTEGER
DEFINE i 		SMALLINT
DEFINE r_c14		RECORD LIKE ordt014.*

SELECT * INTO rm_c13.* FROM ordt013 WHERE ROWID = row
LET rm_c13.c13_numero_oc = rm_c10.c10_numero_oc 
DISPLAY BY NAME rm_c10.c10_tipo_pago, rm_c13.c13_num_recep,
			rm_c13.c13_numero_oc, rm_c13.c13_tot_bruto,
			rm_c13.c13_tot_dscto, rm_c13.c13_tot_impto,
			rm_c13.c13_tot_recep, rm_c13.c13_fecha_recep,
			rm_c13.c13_usuario,   rm_c13.c13_factura	
IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF
CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING rm_p01.*
DISPLAY rm_p01.p01_nomprov TO nomprov
CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].* 
END FOR
DECLARE q_ordt014 CURSOR FOR
	SELECT c14_cantidad,  c14_codigo, c14_descrip, 
	       c14_descuento, c14_precio
		FROM ordt014
               WHERE c14_compania  = vg_codcia
       		 AND c14_localidad = vg_codloc
        	 AND c14_numero_oc = rm_c13.c13_numero_oc
		 AND c14_num_recep = rm_c13.c13_num_recep
LET i = 1
FOREACH q_ordt014 INTO r_detalle[i].*
	LET i = i + 1
	IF i > vm_max_detalle THEN
		CALL fl_mensaje_arreglo_incompleto()
		IF flag = 1 THEN
			ROLLBACK WORK
		END IF
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_ind_arr = i - 1
IF vm_ind_arr < vm_size_arr THEN
	LET vm_size_arr = vm_ind_arr
END IF
FOR i = 1 TO vm_size_arr
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

END FUNCTION



FUNCTION control_DISPLAY_array_ordt014()
DEFINE i, j 	SMALLINT
	
LET int_flag = 0
CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.* 
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT','')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_anulacion()
DEFINE i 	SMALLINT

CLEAR FORM
CALL control_DISPLAY_botones()
INITIALIZE rm_c13.*, rm_c14.* TO NULL
CALL control_lee_cabecera()
IF int_flag THEN
	RETURN 0
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE 
DECLARE q_ordt010 CURSOR FOR 
	SELECT * FROM ordt010
		WHERE c10_compania  = vg_codcia	
		  AND c10_localidad = vg_codloc
		  AND c10_numero_oc = rm_c13.c13_numero_oc
	FOR UPDATE
OPEN q_ordt010 
FETCH q_ordt010
IF STATUS < 0 THEN
	ROLLBACK WORK 
	WHENEVER ERROR STOP
	INITIALIZE rm_c13.*, rm_c14.* TO NULL
	CALL fl_mostrar_mensaje('La orden de compra esta bloqueada por otro usuario.','exclamation')
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	RETURN 0
END IF
WHENEVER ERROR STOP
IF int_flag THEN
	ROLLBACK WORK 
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	INITIALIZE rm_c13.*, rm_c14.* TO NULL
	RETURN 0
END IF
CALL control_cargar_rowid_recepcion(rm_c13.c13_numero_oc)
IF vm_num_recep = 0 THEN
	ROLLBACK WORK 
	CALL fl_mostrar_mensaje('La orden de compra no tiene ninguna recepción para que pueda ser anulada.','exclamation')
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	INITIALIZE rm_c10.*, rm_c13.*, rm_c14.*TO NULL
	RETURN 0
END IF
CALL control_muestra_recepcion(vm_rows_recep[vm_num_recep], 1)
RETURN 1

END FUNCTION



FUNCTION control_anular()
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_c40		RECORD LIKE ordt040.*
DEFINE r_p27		RECORD LIKE cxpt027.*
DEFINE num_ret		LIKE cxpt027.p27_num_ret

CALL control_update_ordt011()	-- DETALLE DE LA ORDEN DE COMPRA
CALL control_update_ordt013()	-- RECEPCION
IF rm_c10.c10_tipo_pago = 'R' THEN
	LET valor_aplicado = control_rebaja_deuda()  
	IF valor_aplicado < 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
END IF
IF rm_c13.c13_tot_recep = rm_c10.c10_tot_compra THEN
	UPDATE ordt010 SET c10_estado = 'P' WHERE CURRENT OF q_ordt010
END IF		
IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF
CALL control_update_cxpt027()	-- RETENIONES
CALL eliminar_trans_activo_fijo()
COMMIT WORK
IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
	CALL fl_recalcula_valores_ot(vg_codcia, vg_codloc,
					rm_c10.c10_ord_trabajo)
END IF
CALL fl_genera_saldos_proveedor(rm_c13.c13_compania, rm_c13.c13_localidad, 
	rm_c10.c10_codprov)
SELECT * INTO r_c40.* FROM ordt040
	WHERE c40_compania  = rm_c13.c13_compania  AND 
              c40_localidad = rm_c13.c13_localidad AND 
	      c40_numero_oc = rm_c13.c13_numero_oc AND 
              c40_num_recep = rm_c13.c13_num_recep
IF status <> NOTFOUND THEN
	CALL fl_lee_comprobante_contable(r_c40.c40_compania, 
		r_c40.c40_tipo_comp, r_c40.c40_num_comp)
		RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe en ctbt012 comprobante de la ordt040.','stop')
		EXIT PROGRAM
	END IF
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'D')
	SET LOCK MODE TO WAIT 5
	UPDATE ctbt012 SET b12_estado     = 'E',
			   b12_fec_modifi = CURRENT 
		WHERE b12_compania  = r_b12.b12_compania  AND 
		      b12_tipo_comp = r_b12.b12_tipo_comp AND 
		      b12_num_comp  = r_b12.b12_num_comp
END IF
DECLARE q_obtret CURSOR FOR 
	SELECT UNIQUE p28_num_ret
		FROM cxpt028
		WHERE p28_compania  = rm_c10.c10_compania
		  AND p28_localidad = rm_c10.c10_localidad
		  AND p28_codprov   = rm_c10.c10_codprov
		  AND p28_tipo_doc  = 'FA'
		  AND p28_num_doc   = rm_c13.c13_factura
OPEN  q_obtret
FETCH q_obtret INTO num_ret
CLOSE q_obtret
FREE  q_obtret
IF num_ret IS NOT NULL THEN
	CALL fl_lee_retencion_cxp(rm_c13.c13_compania, rm_c13.c13_localidad,
					num_ret)
		RETURNING r_p27.*
	IF r_p27.p27_tip_contable IS NOT NULL THEN
		IF r_p27.p27_estado = 'E' THEN
			CALL fl_lee_comprobante_contable(r_p27.p27_compania,
							r_p27.p27_tip_contable,
							r_p27.p27_num_contable)
				RETURNING r_b12.*
			IF r_b12.b12_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe en ctbt012 comprobante de la retención.','stop')
				EXIT PROGRAM
			END IF
			CALL fl_mayoriza_comprobante(r_b12.b12_compania,
							r_b12.b12_tipo_comp,
							r_b12.b12_num_comp, 'D')
			SET LOCK MODE TO WAIT 5
			UPDATE ctbt012 SET b12_estado     = 'E',
					   b12_fec_modifi = CURRENT 
				WHERE b12_compania  = r_b12.b12_compania  AND 
				      b12_tipo_comp = r_b12.b12_tipo_comp AND 
				      b12_num_comp  = r_b12.b12_num_comp
		END IF
	END IF
END IF
CALL cambiar_numero_fact()
CALL fl_mostrar_mensaje('Proceso realizado Ok.','info')
CLEAR FORM
CALL control_DISPLAY_botones()
RETURN 1

END FUNCTION



FUNCTION control_forma_pago_recep() 

OPEN WINDOW w_204_2 AT 6,8 WITH 16 ROWS, 71 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
	  BORDER, MESSAGE LINE LAST - 2) 
IF vg_gui = 1 THEN
	OPEN FORM f_204_2 FROM '../forms/ordf204_2'
ELSE
	OPEN FORM f_204_2 FROM '../forms/ordf204_2c'
END IF
DISPLAY FORM f_204_2
CALL control_DISPLAY_botones_2()
CALL control_cargar_ordt015()
CALL control_DISPLAY_array_ordt015()
CLOSE WINDOW w_204_2

END FUNCTION



FUNCTION control_cargar_ordt015()
DEFINE r_c15			RECORD LIKE ordt015.*
DEFINE i,k,filas		SMALLINT

CALL retorna_tam_arr2()
FOR k = 1 TO vm_size_arr2
	INITIALIZE r_detalle_2[k].* TO NULL
	CLEAR      r_detalle_2[k].*
END FOR
DECLARE q_ordt015 CURSOR FOR 
	SELECT * FROM ordt015 
		WHERE c15_compania  = vg_codcia
		  AND c15_localidad = vg_codloc
		  AND c15_numero_oc = rm_c13.c13_numero_oc
		  AND c15_num_recep = rm_c13.c13_num_recep
LET tot_cap = 0
LET tot_int = 0
LET tot_sub = 0
LET i = 1
FOREACH q_ordt015 INTO r_c15.*
	LET r_detalle_2[i].c15_dividendo  = r_c15.c15_dividendo
	LET r_detalle_2[i].c15_fecha_vcto = r_c15.c15_fecha_vcto
	LET r_detalle_2[i].c15_valor_cap  = r_c15.c15_valor_cap
	LET r_detalle_2[i].c15_valor_int  = r_c15.c15_valor_int
	LET r_detalle_2[i].subtotal       = r_c15.c15_valor_cap +
					    r_c15.c15_valor_int
	LET tot_cap = tot_cap + r_c15.c15_valor_cap	
	LET tot_int = tot_int + r_c15.c15_valor_int	
	LET tot_sub = tot_sub + r_detalle_2[i].subtotal	
	LET i = i + 1
	IF i > vm_max_detalle THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
LET fecha_pago = r_detalle_2[1].c15_fecha_vcto
LET tot_recep = tot_cap
IF i > 1 THEN
	LET dias_pagos = r_detalle_2[2].c15_fecha_vcto -
		 	 r_detalle_2[1].c15_fecha_vcto 
ELSE
	LET dias_pagos =r_detalle_2[1].c15_fecha_vcto - DATE(rm_c13.c13_fecing) 
END IF
LET tot_dias = r_detalle_2[i].c15_fecha_vcto - TODAY
LET pagos = i
DISPLAY BY NAME tot_recep, dias_pagos, pagos, tot_cap, tot_int, 
		tot_sub,   fecha_pago, tot_dias, rm_c13.c13_interes

END FUNCTION



FUNCTION control_update_ordt011()
DEFINE i 	SMALLINT

FOR i = 1 TO vm_ind_arr
	UPDATE ordt011 
		SET c11_cant_rec = c11_cant_rec - 
				   r_detalle[i].c14_cantidad
		WHERE c11_compania  = vg_codcia
		  AND c11_localidad = vg_codloc
		  AND c11_numero_oc = rm_c13.c13_numero_oc
		  AND c11_codigo    = r_detalle[i].c14_codigo
END FOR 

END FUNCTION



FUNCTION control_update_ordt013()

UPDATE ordt013 
	SET c13_estado      = 'E',
	    c13_fecha_eli   = CURRENT	
	WHERE c13_compania  = vg_codcia
	  AND c13_localidad = vg_codloc
	  AND c13_numero_oc = rm_c13.c13_numero_oc
	  AND c13_num_recep = rm_c13.c13_num_recep

END FUNCTION



FUNCTION control_update_cxpt027()
DEFINE num_ret		LIKE cxpt028.p28_num_ret

DECLARE q_cxpt028 CURSOR FOR 
	SELECT  UNIQUE p28_num_ret FROM cxpt028
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_codprov   = rm_c10.c10_codprov
		  AND p28_tipo_doc  = 'FA'
		  AND p28_num_doc   = rm_c13.c13_factura
OPEN  q_cxpt028
FETCH q_cxpt028 INTO num_ret
CLOSE q_cxpt028
FREE  q_cxpt028
UPDATE cxpt027 
	SET p27_estado      = 'E',
	    p27_fecha_eli   = CURRENT	
	WHERE p27_compania  = vg_codcia
	  AND p27_localidad = vg_codloc
	  AND p27_num_ret   = num_ret

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE resp 		CHAR(6)
DEFINE done, dias	SMALLINT
DEFINE pago		DECIMAL(14,2)
DEFINE r_c10	 	RECORD LIKE ordt010.*
DEFINE r_c01	 	RECORD LIKE ordt001.*
DEFINE r_t23	 	RECORD LIKE talt023.*
DEFINE r_c00	 	RECORD LIKE ordt000.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE aux_fact		LIKE ordt013.c13_factura
DEFINE num_recep	LIKE ordt013.c13_num_recep

SELECT * INTO r_c00.* FROM ordt000
	WHERE c00_compania = vg_codcia
LET INT_FLAG = 0
INPUT BY NAME rm_c13.c13_numero_oc, rm_c13.c13_factura
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
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
		IF INFIELD(c13_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc,
						     0, 0, 'C','00','T')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
							 r_c10.c10_numero_oc)
					RETURNING rm_c10.*
				LET rm_c13.c13_numero_oc = rm_c10.c10_numero_oc
				CALL fl_lee_proveedor(rm_c10.c10_codprov)
					RETURNING rm_p01.*
				DISPLAY rm_p01.p01_nomprov TO nomprov
				DISPLAY BY NAME rm_c13.c13_numero_oc,
						rm_c10.c10_tipo_pago
				IF vg_gui = 0 THEN
				     CALL muestra_tipopago(rm_c10.c10_tipo_pago)
				END IF
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD c13_numero_oc
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
						 rm_c13.c13_numero_oc)
				RETURNING r_c10.*
                	IF r_c10.c10_numero_oc IS  NULL THEN
				CALL fl_mostrar_mensaje('No existe la orden de compra en la Compañía.','exclamation')
				CLEAR nomprov
                        	NEXT FIELD c13_numero_oc
			END IF
			CALL fl_lee_proveedor(r_c10.c10_codprov)
				RETURNING rm_p01.*
			IF r_c10.c10_estado = 'A' THEN
				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fl_mostrar_mensaje('La Orden de Compra no ha sido aprobada.','exclamation')
				NEXT FIELD c13_numero_oc
			END IF
			CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
				RETURNING r_c01.*
			IF r_c01.c01_ing_bodega = 'S' AND 
			   r_c01.c01_modulo     = 'RE'
			   THEN
				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fl_mostrar_mensaje('La orden de compra pertenece a inventarios debe ser anulada por devolución de compra local.', 'exclamation')
                       		NEXT FIELD c13_numero_oc
			END IF 
			LET rm_c10.c10_tipo_pago = r_c10.c10_tipo_pago
			LET rm_c13.c13_interes   = r_c10.c10_interes
			DISPLAY BY NAME rm_c10.c10_tipo_pago
			IF vg_gui = 0 THEN
				CALL muestra_tipopago(rm_c10.c10_tipo_pago)
			END IF
			DISPLAY rm_p01.p01_nomprov TO nomprov
			LET rm_c10.* = r_c10.* 
			IF r_c10.c10_ord_trabajo IS NOT NULL THEN
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
						 r_c10.c10_ord_trabajo)
				RETURNING r_t23.*
				IF r_t23.t23_estado <> 'A' THEN
					CALL fl_mostrar_mensaje('La orden de trabajo asociada a la orden de compra no esta activa.','exclamation')
                       			NEXT FIELD c13_numero_oc
				END IF
			END IF
			LET dias = TODAY - r_c10.c10_fecha_fact
			IF (r_c00.c00_react_mes = 'S' AND 
				(YEAR(TODAY)  <> YEAR(r_c10.c10_fecha_fact) OR
				 MONTH(TODAY) <> MONTH(r_c10.c10_fecha_fact)))
			   OR
			   (r_c00.c00_react_mes = 'N' AND 
				dias > r_c00.c00_dias_react) THEN
				CALL fl_mostrar_mensaje('No se puede anular esta recepción, revise Configuración Compañías en O.C.','exclamation')
                       		NEXT FIELD c13_numero_oc
			END IF
			DECLARE q_num_f CURSOR FOR
				SELECT c13_factura, c13_num_recep
					FROM ordt013
					WHERE c13_compania  = vg_codcia
					  AND c13_localidad = vg_codloc
					  AND c13_numero_oc =
							rm_c10.c10_numero_oc
					  AND c13_estado    = 'A'
					ORDER BY c13_num_recep DESC
			OPEN q_num_f
			FETCH q_num_f INTO rm_c13.c13_factura, num_recep
			CLOSE q_num_f
			FREE q_num_f
			LET aux_fact = rm_c13.c13_factura
			DISPLAY BY NAME rm_c13.c13_factura
			SELECT NVL(SUM((p20_valor_cap + p20_valor_int) -
				(p20_saldo_cap + p20_saldo_int)), 0)
				INTO pago
				FROM cxpt020
				WHERE p20_compania  = r_c10.c10_compania
				  AND p20_localidad = r_c10.c10_localidad
				  AND p20_codprov   = r_c10.c10_codprov
				  AND p20_num_doc   = rm_c13.c13_factura
				  AND p20_numero_oc = r_c10.c10_numero_oc
			IF pago <> 0 THEN
				CALL fl_mostrar_mensaje('Esta recepción de orden compra no puede ser anulada, porque ha sido parcial o totalmente pagada.', 'exclamation')
                       		NEXT FIELD c13_numero_oc
			END IF
		END IF
	AFTER INPUT
		{--
		LET rm_c13.c13_factura = rm_c13.c13_factura CLIPPED
		IF rm_c13.c13_factura IS NULL THEN
			NEXT FIELD c13_factura
		END IF
		IF rm_c13.c13_factura = aux_fact THEN
			CALL fl_mostrar_mensaje('Cambie el numero de factura para generar esta anulacion.','exclamation')
			NEXT FIELD c13_factura
		END IF
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
					rm_c10.c10_codprov, 'FA',
					rm_c13.c13_factura, 1)
			RETURNING r_p20.*
		IF r_p20.p20_num_doc IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Esta factura ya existe para este provedor.', 'exclamation')
			NEXT FIELD c13_factura
		END IF
		LET vm_fact_nue        = rm_c13.c13_factura
		LET rm_c13.c13_factura = aux_fact
		--}
END INPUT

END FUNCTION



FUNCTION control_DISPLAY_array_ordt015()

LET int_flag = 0
CALL set_count(pagos)
DISPLAY ARRAY r_detalle_2 TO r_detalle_2.* 
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT','')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_rebaja_deuda()
DEFINE i		SMALLINT
DEFINE num_row		INTEGER
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE aplicado_cap	DECIMAL(14,2)
DEFINE aplicado_int	DECIMAL(14,2)
DEFINE valor_aplicar	DECIMAL(14,2)
DEFINE valor_favor	LIKE cxpt021.p21_valor
DEFINE tot_ret		DECIMAL(14,2)
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p21		RECORD LIKE cxpt021.*
DEFINE r_doc		RECORD LIKE cxpt020.*
DEFINE r_caju		RECORD LIKE cxpt022.*
DEFINE r_daju		RECORD LIKE cxpt023.*

LET tot_ret = 0
SELECT p27_total_ret INTO tot_ret FROM cxpt027
	WHERE p27_compania  = rm_c13.c13_compania AND 
	      p27_localidad = rm_c13.c13_localidad AND 
	      p27_num_ret   = rm_c13.c13_num_ret 
INITIALIZE r_p21.* TO NULL
LET r_p21.p21_compania     = vg_codcia
LET r_p21.p21_localidad    = vg_codloc
LET r_p21.p21_codprov      = rm_c10.c10_codprov
LET r_p21.p21_tipo_doc     = vm_nota_credito
LET r_p21.p21_num_doc      = nextValInSequence('TE', vm_nota_credito)
LET r_p21.p21_referencia   = 'ANULACION RECEPCION # ',
				rm_c13.c13_num_recep USING "<&", ' OC # ',
				rm_c13.c13_numero_oc USING "<<<<&"
LET r_p21.p21_fecha_emi    = TODAY
LET r_p21.p21_moneda       = rm_c10.c10_moneda
LET r_p21.p21_paridad      = rm_c10.c10_paridad
LET r_p21.p21_valor        = rm_c13.c13_tot_recep - tot_ret
LET r_p21.p21_saldo        = rm_c13.c13_tot_recep - tot_ret
LET r_p21.p21_subtipo      = 1
LET r_p21.p21_origen       = 'A'
LET r_p21.p21_usuario      = vg_usuario
LET r_p21.p21_fecing       = CURRENT
INSERT INTO cxpt021 VALUES(r_p21.*)
-- Para aplicar la nota de credito
DECLARE q_ddev CURSOR FOR 
	SELECT * FROM cxpt020 WHERE p20_compania  = vg_codcia
	                        AND p20_localidad = vg_codloc
	                        AND p20_codprov   = rm_c10.c10_codprov
	                        AND p20_tipo_doc  = 'FA'
	                        AND p20_num_doc   = rm_c13.c13_factura
				AND p20_saldo_cap + p20_saldo_int > 0
		FOR UPDATE
INITIALIZE r_caju.* TO NULL
LET r_caju.p22_compania 	= vg_codcia
LET r_caju.p22_localidad 	= vg_codloc
LET r_caju.p22_codprov		= rm_c10.c10_codprov
LET r_caju.p22_tipo_trn 	= 'AJ'
LET r_caju.p22_num_trn 		= fl_actualiza_control_secuencias(vg_codcia, 
				  vg_codloc, 'TE', 'AA', r_caju.p22_tipo_trn)
IF r_caju.p22_num_trn <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_caju.p22_referencia       = r_p21.p21_referencia CLIPPED
LET r_caju.p22_fecha_emi 	= TODAY
LET r_caju.p22_moneda 		= rm_c10.c10_moneda
LET r_caju.p22_paridad 		= rm_c10.c10_paridad
LET r_caju.p22_tasa_mora 	= 0
LET r_caju.p22_total_cap 	= 0
LET r_caju.p22_total_int 	= 0
LET r_caju.p22_total_mora	= 0
LET r_caju.p22_subtipo 		= 1
LET r_caju.p22_origen 		= 'A'
LET r_caju.p22_fecha_elim 	= NULL
LET r_caju.p22_tiptrn_elim 	= NULL
LET r_caju.p22_numtrn_elim 	= NULL
LET r_caju.p22_usuario 		= vg_usuario
LET r_caju.p22_fecing 		= CURRENT
INSERT INTO cxpt022 VALUES (r_caju.*)
LET num_row = SQLCA.SQLERRD[6]
LET valor_favor = r_p21.p21_valor 
LET i = 0
LET valor_aplicado = 0
FOREACH q_ddev INTO r_doc.*
	LET valor_aplicar = valor_favor - valor_aplicado
	IF valor_aplicar = 0 THEN
		EXIT FOREACH
	END IF
	LET i = i + 1
	LET aplicado_cap  = 0
	LET aplicado_int  = 0
	IF r_doc.p20_saldo_int <= valor_aplicar THEN
		LET aplicado_int = r_doc.p20_saldo_int 
	ELSE
		LET aplicado_int = valor_aplicar
	END IF
	LET valor_aplicar = valor_aplicar - aplicado_int
	IF r_doc.p20_saldo_cap <= valor_aplicar THEN
		LET aplicado_cap = r_doc.p20_saldo_cap 
	ELSE
		LET aplicado_cap = valor_aplicar
	END IF
	LET valor_aplicado = valor_aplicado + aplicado_cap + aplicado_int
	LET r_caju.p22_total_cap        = r_caju.p22_total_cap + 
					  (aplicado_cap * -1)
	LET r_caju.p22_total_int        = r_caju.p22_total_int + 
					  (aplicado_int * -1)
    	LET r_daju.p23_compania 	= vg_codcia
    	LET r_daju.p23_localidad 	= vg_codloc
    	LET r_daju.p23_codprov		= r_caju.p22_codprov
    	LET r_daju.p23_tipo_trn 	= r_caju.p22_tipo_trn
    	LET r_daju.p23_num_trn  	= r_caju.p22_num_trn
    	LET r_daju.p23_orden 		= i
    	LET r_daju.p23_tipo_doc 	= r_doc.p20_tipo_doc
    	LET r_daju.p23_num_doc 	        = r_doc.p20_num_doc
    	LET r_daju.p23_div_doc 		= r_doc.p20_dividendo
    	LET r_daju.p23_tipo_favor 	= r_p21.p21_tipo_doc
    	LET r_daju.p23_doc_favor 	= r_p21.p21_num_doc
    	LET r_daju.p23_valor_cap 	= aplicado_cap * -1
    	LET r_daju.p23_valor_int 	= aplicado_int * -1
    	LET r_daju.p23_valor_mora 	= 0
    	LET r_daju.p23_saldo_cap 	= r_doc.p20_saldo_cap
    	LET r_daju.p23_saldo_int	= r_doc.p20_saldo_int
	INSERT INTO cxpt023 VALUES (r_daju.*)
	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap - aplicado_cap,
	                   p20_saldo_int = p20_saldo_int - aplicado_int
		WHERE CURRENT OF q_ddev
END FOREACH
UPDATE cxpt021 SET p21_saldo = p21_saldo - valor_aplicado
	WHERE p21_compania     = r_p21.p21_compania  AND
	      p21_localidad    = r_p21.p21_localidad AND
	      p21_codprov      = r_p21.p21_codprov   AND
	      p21_tipo_doc     = r_p21.p21_tipo_doc  AND
	      p21_num_doc      = r_p21.p21_num_doc
IF i = 0 THEN
	DELETE FROM cxpt022 WHERE ROWID = num_row
ELSE
	UPDATE cxpt022 SET p22_total_cap = r_caju.p22_total_cap,
	                   p22_total_int = r_caju.p22_total_int
		WHERE ROWID = num_row
END IF
FREE q_ddev
RETURN valor_aplicado

END FUNCTION



FUNCTION nextValInSequence(modulo, tipo_tran)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE tipo_tran 	LIKE rept019.r19_cod_tran
DEFINE resp		CHAR(6)
DEFINE retVal 		SMALLINT

SET LOCK MODE TO WAIT 
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

END WHILE
SET LOCK MODE TO NOT WAIT
RETURN retVal

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 7
END IF

END FUNCTION



FUNCTION retorna_tam_arr2()

--#LET vm_size_arr2 = fgl_scr_size('r_detalle_2')
IF vg_gui = 0 THEN
	LET vm_size_arr2 = 7
END IF

END FUNCTION



FUNCTION muestra_tipopago(tipopago)
DEFINE tipopago		CHAR(1)

CASE tipopago
	WHEN 'C'
		DISPLAY 'CONTADO' TO tit_tipo_pago
	WHEN 'R'
		DISPLAY 'CREDITO' TO tit_tipo_pago
	OTHERWISE
		CLEAR c10_tipo_pago, tit_tipo_pago
END CASE

END FUNCTION



FUNCTION bloqueo_bien(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE resul		SMALLINT

LET resul = 0
SET LOCK MODE TO WAIT 3
WHENEVER ERROR CONTINUE
WHILE TRUE
	DECLARE q_ab CURSOR WITH HOLD FOR
		SELECT * FROM actt010
			WHERE a10_compania    = vg_codcia
			  AND a10_codigo_bien = activo
			FOR UPDATE
	OPEN q_ab
	FETCH q_ab INTO r_a10.*
	IF STATUS = 0 THEN
		LET resul = 1
		EXIT WHILE
	END IF
	IF STATUS < 0 THEN
		IF muestra_mensaje_error_continuar_act(activo, '10',
						'actualizar', 'actualización')
		THEN
			CLOSE q_ab
			FREE q_ab
			CONTINUE WHILE
		END IF
	END IF
	IF STATUS = NOTFOUND THEN
		IF muestra_mensaje_error_continuar_act(activo, '10',
						'encontrar', 'búsqueda')
		THEN
			CLOSE q_ab
			FREE q_ab
			CONTINUE WHILE
		END IF
	END IF
	EXIT WHILE
END WHILE
SET LOCK MODE TO NOT WAIT
WHENEVER ERROR STOP
RETURN resul

END FUNCTION



FUNCTION eliminar_trans_activo_fijo()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c11		RECORD LIKE ordt011.*
DEFINE r_c40		RECORD LIKE ordt040.*

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
IF r_c01.c01_modulo <> 'AF' THEN
	RETURN
END IF
INITIALIZE r_c40.* TO NULL
SELECT * INTO r_c40.*
	FROM ordt040
	WHERE c40_compania  = rm_c13.c13_compania
	  AND c40_localidad = rm_c13.c13_localidad
	  AND c40_numero_oc = rm_c13.c13_numero_oc
	  AND c40_num_recep = rm_c13.c13_num_recep
DECLARE q_c11 CURSOR FOR
	SELECT * FROM ordt011
		WHERE c11_compania  = rm_c10.c10_compania
		  AND c11_localidad = rm_c10.c10_localidad
		  AND c11_numero_oc = rm_c10.c10_numero_oc
FOREACH q_c11 INTO r_c11.*
	IF NOT bloqueo_bien(r_c11.c11_codigo) THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	CALL fl_lee_codigo_bien(r_c11.c11_compania, r_c11.c11_codigo)
		RETURNING r_a10.*
	IF r_a10.a10_estado <> 'S' THEN
		CONTINUE FOREACH
	END IF
	UPDATE actt010 SET a10_estado = 'A' WHERE CURRENT OF q_ab
	INITIALIZE r_a12.* TO NULL
	LET r_a12.a12_compania 	  = vg_codcia
	LET r_a12.a12_codigo_tran = 'EG'
	LET r_a12.a12_numero_tran = fl_retorna_num_tran_activo(vg_codcia, 
							  r_a12.a12_codigo_tran)
	IF r_a12.a12_numero_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_a12.a12_codigo_bien = r_c11.c11_codigo
	LET r_a12.a12_referencia  = 'ANULACION POR RECEP. OC.'
	LET r_a12.a12_locali_ori  = r_a10.a10_localidad
	LET r_a12.a12_depto_ori   = r_a10.a10_cod_depto
	LET r_a12.a12_porc_deprec = r_a10.a10_porc_deprec
	LET r_a12.a12_valor_mb 	  = (r_c11.c11_precio - r_c11.c11_val_descto)
					* (-1)
	LET r_a12.a12_valor_ma 	  = 0
	LET r_a12.a12_tipcomp_gen = r_c40.c40_tipo_comp
	LET r_a12.a12_numcomp_gen = r_c40.c40_num_comp
	LET r_a12.a12_usuario 	  = vg_usuario
	LET r_a12.a12_fecing 	  = CURRENT
	INSERT INTO actt012 VALUES (r_a12.*)
END FOREACH

END FUNCTION



FUNCTION muestra_mensaje_error_continuar_act(activo, prefi, palabra, palabra2)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE prefi		CHAR(2)
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE query		CHAR(1000)
DEFINE varusu		VARCHAR(100)
DEFINE usuario		LIKE gent005.g05_usuario

LET query = 'SELECT UNIQUE s.username ',
		' FROM sysmaster:syslocks l, sysmaster:syssessions s ',
		' WHERE type    = "U" ',
		'   AND sid     <> DBINFO("sessionid") ',
		'   AND owner   = sid ',
		'   AND tabname = "actt0', prefi, '"',
		'   AND rowidlk IN ',
			' (SELECT ROWID FROM actt0', prefi,
				' WHERE a', prefi, '_compania    = ', vg_codcia,
				'   AND a', prefi, '_codigo_bien = ', activo,')'
PREPARE cons_blo FROM query
DECLARE q_blo CURSOR FOR cons_blo
LET varusu = NULL
FOREACH q_blo INTO usuario
	IF varusu IS NULL THEN
		LET varusu = UPSHIFT(usuario) CLIPPED
	ELSE
		LET varusu = varusu CLIPPED, ' ', UPSHIFT(usuario) CLIPPED
	END IF
END FOREACH
RETURN mensaje_error(activo, palabra, palabra2, varusu)

END FUNCTION



FUNCTION mensaje_error(activo, palabra, palabra2, varusu)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE varusu		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(255)

LET mensaje = 'El código de Activo Fijo ', activo USING "<<<<<<&",
		' esta siendo bloqueado por el(los) usuario(s) ',varusu CLIPPED,
		'. Desea intentar nuevamente esta ', palabra2 CLIPPED, ' ?'
CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
IF resp = 'Yes' THEN
	RETURN 1
END IF
LET mensaje = 'No se ha podido ', palabra CLIPPED, ' el registro del ',
		'código de Activo Fijo ', activo USING "<<<<<<&",
		'. LLAME AL ADMINISTRADOR.'
CALL fl_mostrar_mensaje(mensaje, 'stop')
RETURN 0

END FUNCTION



FUNCTION cambiar_numero_fact()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE i, lim		INTEGER
DEFINE query		CHAR(800)

LET i   = 1
LET lim = LENGTH(rm_c13.c13_factura)
CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, rm_c10.c10_codprov, 'FA',
				rm_c13.c13_factura, 1)
	RETURNING r_p20.*
WHILE TRUE
	LET vm_fact_nue = r_p20.p20_num_doc[1, 3],
				r_p20.p20_num_doc[5, lim] CLIPPED,
				i USING "<<<<<<&"
	CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
					rm_c10.c10_codprov, 'FA',
					vm_fact_nue, 1)
		RETURNING r_p20.*
	IF r_p20.p20_compania IS NULL THEN
		EXIT WHILE
	END IF
	LET lim = LENGTH(vm_fact_nue)
	LET i   = i + 1
END WHILE
BEGIN WORK
WHENEVER ERROR STOP 
LET query = 'UPDATE ordt010 ',
		' SET c10_factura = "', vm_fact_nue CLIPPED, '"',
		' WHERE c10_compania  = ', vg_codcia,
		'   AND c10_localidad = ', vg_codloc,
		'   AND c10_numero_oc = ', rm_c10.c10_numero_oc
PREPARE exec_up01 FROM query
EXECUTE exec_up01
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c10.c10_numero_oc)
	RETURNING r_c10.*
LET query = 'UPDATE ordt013 ',
		' SET c13_factura  = "', vm_fact_nue CLIPPED, '", ',
		'     c13_num_guia = "', vm_fact_nue CLIPPED, '"',
		' WHERE c13_compania  = ', vg_codcia,
		'   AND c13_localidad = ', vg_codloc,
		'   AND c13_numero_oc = ', rm_c10.c10_numero_oc,
		'   AND c13_estado    = "E" ',
		'   AND c13_num_recep = ', rm_c13.c13_num_recep
PREPARE exec_up02 FROM query
EXECUTE exec_up02
DECLARE q_p23 CURSOR FOR
	SELECT * FROM cxpt023
		WHERE p23_compania  = vg_codcia
	          AND p23_localidad = vg_codloc
	          AND p23_codprov   = r_c10.c10_codprov
	          AND p23_tipo_doc  = 'FA'
	          AND p23_num_doc   = rm_c13.c13_factura
OPEN q_p23
FETCH q_p23 INTO r_p23.*
IF STATUS = NOTFOUND THEN
	LET query = 'UPDATE cxpt020 ',
			' SET p20_num_doc = "', vm_fact_nue CLIPPED, '"',
			' WHERE p20_compania  = ', vg_codcia,
			'   AND p20_localidad = ', vg_codloc,
			'   AND p20_codprov   = ', r_c10.c10_codprov,
			'   AND p20_tipo_doc  = "FA" ',
			'   AND p20_num_doc   = "', rm_c13.c13_factura, '"'
	PREPARE exec_up03 FROM query
	EXECUTE exec_up03
	COMMIT WORK
	RETURN
END IF
SELECT * FROM cxpt020
	WHERE p20_compania  = vg_codcia
          AND p20_localidad = vg_codloc
          AND p20_codprov   = r_c10.c10_codprov
          AND p20_tipo_doc  = 'FA'
          AND p20_num_doc   = rm_c13.c13_factura
	INTO TEMP tmp_p20
LET query = 'UPDATE tmp_p20 ',
		' SET p20_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p20_compania  = ', vg_codcia,
		'   AND p20_localidad = ', vg_codloc,
		'   AND p20_codprov   = ', r_c10.c10_codprov,
		'   AND p20_tipo_doc  = "FA" ',
		'   AND p20_num_doc   = "', rm_c13.c13_factura, '"'
PREPARE exec_up04 FROM query
EXECUTE exec_up04
INSERT INTO cxpt020 SELECT * FROM tmp_p20
LET query = 'UPDATE cxpt023 ',
		' SET p23_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p23_compania  = ', vg_codcia,
		'   AND p23_localidad = ', vg_codloc,
		'   AND p23_codprov   = ', r_c10.c10_codprov,
		'   AND p23_tipo_doc  = "FA" ',
		'   AND p23_num_doc   = "', rm_c13.c13_factura, '"'
PREPARE exec_up05 FROM query
EXECUTE exec_up05
LET query = 'UPDATE cxpt025 ',
		' SET p25_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p25_compania  = ', vg_codcia,
		'   AND p25_localidad = ', vg_codloc,
		'   AND p25_codprov   = ', r_c10.c10_codprov,
		'   AND p25_tipo_doc  = "FA" ',
		'   AND p25_num_doc   = "', rm_c13.c13_factura, '"'
PREPARE exec_up06 FROM query
EXECUTE exec_up06
LET query = 'UPDATE cxpt028 ',
		' SET p28_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p28_compania  = ', vg_codcia,
		'   AND p28_localidad = ', vg_codloc,
		'   AND p28_codprov   = ', r_c10.c10_codprov,
		'   AND p28_tipo_doc  = "FA" ',
		'   AND p28_num_doc   = "', rm_c13.c13_factura, '"'
PREPARE exec_up07 FROM query
EXECUTE exec_up07
LET query = 'UPDATE cxpt041 ',
		' SET p41_num_doc = "', vm_fact_nue CLIPPED, '"',
		' WHERE p41_compania  = ', vg_codcia,
		'   AND p41_localidad = ', vg_codloc,
		'   AND p41_codprov   = ', r_c10.c10_codprov,
		'   AND p41_tipo_doc  = "FA" ',
		'   AND p41_num_doc   = "', rm_c13.c13_factura, '"'
PREPARE exec_up08 FROM query
EXECUTE exec_up08
LET query = 'DELETE FROM cxpt020 ',
		' WHERE p20_compania  = ', vg_codcia,
		'   AND p20_localidad = ', vg_codloc,
		'   AND p20_codprov   = ', r_c10.c10_codprov,
		'   AND p20_tipo_doc  = "FA" ',
		'   AND p20_num_doc   = "', rm_c13.c13_factura, '"'
PREPARE exec_del01 FROM query
EXECUTE exec_del01
WHENEVER ERROR STOP 
COMMIT WORK

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

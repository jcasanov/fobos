------------------------------------------------------------------------------
-- Titulo           : ordp204.4gl - Anulación Recepcion de Ordenes de Compra
-- Elaboracion      : 15-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun ordp204 base modulo compania localidad
-- Ultima Correccion: 15-dic-2001
-- Motivo Correccion: 1
------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_c10			RECORD LIKE ordt010.*	-- CABECERA
DEFINE rm_c13		 	RECORD LIKE ordt013.*	-- DETALLE
DEFINE rm_c14		 	RECORD LIKE ordt014.*	-- DETALLE
DEFINE rm_p01		 	RECORD LIKE cxpt001.*	-- PROVEEDORES

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[250] OF RECORD
	c14_cantidad		LIKE ordt014.c14_cantidad,
	c14_codigo		LIKE ordt014.c14_codigo,
	c14_descrip		LIKE ordt014.c14_descrip,
	c14_descuento		LIKE ordt014.c14_descuento,
	c14_precio		LIKE ordt014.c14_precio
	END RECORD
	---------------------------------------------

DEFINE vm_ind_arr		SMALLINT   -- INDICE DE MI ARREGLO  (ARRAY)
DEFINE vm_filas_pant		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_max_detalle		SMALLINT   -- MAXIMO NUMERO DE ELEMENTOS DEL

DEFINE vm_num_recep	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_rows_recep	ARRAY[50] OF INTEGER
DEFINE vg_oc		LIKE ordt013.c13_numero_oc

---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE FORMA DE PAGO ----
	---- ARREGLO PARA LA FORMA DE PAGO ----
DEFINE r_detalle_2 ARRAY[250] OF RECORD
	c15_dividendo		LIKE ordt015.c15_dividendo,
	c15_fecha_vcto		LIKE ordt015.c15_fecha_vcto,
	c15_valor_cap		LIKE ordt015.c15_valor_cap,
	c15_valor_int		LIKE ordt015.c15_valor_int,
	subtotal		LIKE ordt015.c15_valor_cap
	END RECORD
-------------------------------------------------------

DEFINE pagos			SMALLINT
DEFINE tot_dias			SMALLINT	
DEFINE fecha_pago		DATE
DEFINE dias_pagos		SMALLINT
DEFINE tot_recep		LIKE ordt010.c10_tot_compra
DEFINE tot_cap			LIKE ordt010.c10_tot_compra
DEFINE tot_int			LIKE ordt010.c10_tot_compra
DEFINE tot_sub			LIKE ordt010.c10_tot_compra
---------------------------------------------------------------

DEFINE vm_nota_credito  LIKE rept019.r19_cod_tran



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp204.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_oc       = arg_val(5)

LET vg_proceso = 'ordp204'
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
DEFINE i,done		SMALLINT
DEFINE command_run	VARCHAR(200)

CALL fl_nivel_isolation()
LET vm_max_detalle  = 250

LET vm_nota_credito = 'NC'

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12,
	INSERT KEY F30,
	DELETE KEY F31

OPEN WINDOW w_204 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_204 FROM '../forms/ordf204_1'
DISPLAY FORM f_204

CALL control_display_botones()

LET vm_filas_pant = fgl_scr_size('r_detalle')
INITIALIZE rm_c10.*, rm_c13.*, rm_c14.*, rm_p01.* TO NULL

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR

LET rm_orden[2] = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Anular'
		HIDE OPTION 'Ver Orden'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF num_args() = 5 THEN
			HIDE OPTION 'Anular'
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc, vg_oc)
				RETURNING rm_c10.*
			IF rm_c10.c10_numero_oc IS NULL THEN
				CALL fgl_winmessage(vg_producto,'La orden de compra no existe.','exclamation')
				EXIT PROGRAM
			END IF
			CALL control_cargar_rowid_recepcion(vg_oc)
			IF vm_num_recep = 0 THEN
				CALL fgl_winmessage(vg_producto,'La orden de compra no tiene ninguna recepción anulada.','exclamation')
				EXIT PROGRAM
			END IF

			LET vm_row_current = 1
			CALL control_muestra_recepcion(vm_rows_recep[vm_row_current])
			CALL muestra_contadores()

			IF vm_num_recep > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
			IF vm_ind_arr > vm_filas_pant THEN
				SHOW OPTION 'Ver Detalle'
			END IF
		END IF

	COMMAND KEY('A') 'Avanzar' 'Ver siguiente anulación.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_recep THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_ind_arr > vm_filas_pant THEN
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
		IF vm_ind_arr > vm_filas_pant THEN
			SHOW OPTION 'Ver Detalle'
		END IF

	COMMAND KEY('D') 'Ver Detalle' 'Ver Detalle de la Recepción.'
		CALL control_display_array_ordt014()

	COMMAND KEY('R') 'Anulación' 'Anulación Recepción de Ordenes de Compra.'
		LET done = control_anulacion()
		IF done = 0 THEN
			HIDE OPTION 'Forma de Pago'
			HIDE OPTION 'Anular'
			HIDE OPTION 'Ver Orden'
		ELSE
			SHOW OPTION 'Anular'
			SHOW OPTION 'Ver Orden'
		END IF
		IF rm_c10.c10_tipo_pago = 'R' THEN
			SHOW OPTION 'Forma de Pago'
		END IF

	COMMAND KEY('V') 'Ver Orden' 'Ver la Orden de Compra.'
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			LET command_run = 'fglrun ordp200 ' || vg_base || ' '
					    || vg_modulo || ' ' || vg_codcia 
					    || ' ' || vg_codloc || ' ' ||
					    rm_c13.c13_numero_oc
			RUN command_run
		END IF

	COMMAND KEY('F') 'Forma de Pago'  'Forma de Pago de Recepción.'
		CALL control_forma_pago_recep()

	COMMAND KEY('G') 'Anular'  'Anular Recepción.'
		LET done = control_anular()
		IF done THEN
			HIDE OPTION 'Forma de Pago'
			HIDE OPTION 'Anular'
			HIDE OPTION 'Ver Orden'
		END IF
			
	COMMAND KEY('S') 'Salir'  'Salir del Programa.'
		EXIT MENU

END MENU
		
END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_recep AT 1, 67 

END FUNCTION



FUNCTION siguiente_registro()

IF vm_row_current < vm_num_recep THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL control_muestra_recepcion(vm_rows_recep[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL control_muestra_recepcion(vm_rows_recep[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'Cant'		TO tit_col1
DISPLAY 'Código'	TO tit_col2
DISPLAY 'Descripción' 	TO tit_col3
DISPLAY 'Des %'  	TO tit_col4
DISPLAY 'Precio'	TO tit_col5

END FUNCTION



FUNCTION control_display_botones_2()

DISPLAY '#' 	 	TO tit_col1
DISPLAY 'Fecha Vcto'	TO tit_col2
DISPLAY 'Valor Capital'	TO tit_col3
DISPLAY 'Valor Interes'	TO tit_col4
DISPLAY 'Subtotal'	TO tit_col5

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



FUNCTION control_muestra_recepcion(row)
DEFINE row	INTEGER
DEFINE i 	SMALLINT
DEFINE r_c14	RECORD LIKE ordt014.*

SELECT * INTO rm_c13.* FROM ordt013 WHERE ROWID = row

LET rm_c13.c13_num_recep = rm_c13.c13_num_recep 
LET rm_c13.c13_numero_oc = rm_c10.c10_numero_oc 
DISPLAY BY NAME rm_c10.c10_tipo_pago, rm_c13.c13_num_recep,
			rm_c13.c13_numero_oc, rm_c13.c13_tot_bruto,
			rm_c13.c13_tot_dscto, rm_c13.c13_tot_impto,
			rm_c13.c13_tot_recep, rm_c13.c13_fecha_recep,
			rm_c13.c13_usuario,   rm_c13.c13_factura	
CALL fl_lee_proveedor(rm_c10.c10_codprov)
	RETURNING rm_p01.*
	DISPLAY rm_p01.p01_nomprov TO nomprov
	
LET vm_filas_pant = fgl_scr_size('r_detalle')

FOR i = 1 TO vm_filas_pant
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
END FOREACH

LET vm_ind_arr = i - 1
IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF
FOR i = 1 TO vm_filas_pant
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

END FUNCTION



FUNCTION control_display_array_ordt014()
DEFINE i, j 	SMALLINT
	
LET INT_FLAG = 0
CALL set_count(vm_ind_arr)

DISPLAY ARRAY r_detalle TO r_detalle.* 
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT','')
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()

        AFTER DISPLAY
                CONTINUE DISPLAY
        ON KEY(INTERRUPT)
                EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_anulacion()
DEFINE i 	SMALLINT

CLEAR FORM
CALL control_display_botones()

INITIALIZE rm_c13.*, rm_c14.* TO NULL

CALL control_lee_cabecera()

WHENEVER ERROR CONTINUE 

BEGIN WORK
	DECLARE q_ordt010 CURSOR FOR 
		SELECT * FROM ordt010
			WHERE c10_compania  = vg_codcia	
			  AND c10_localidad = vg_codloc
			  AND c10_numero_oc = rm_c13.c13_numero_oc
		FOR UPDATE

OPEN q_ordt010 
FETCH q_ordt010

WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK 
	INITIALIZE rm_c13.*, rm_c14.* TO NULL
	CALL fgl_winmessage(vg_producto,'La orden de compra está siendo anulada por otro usuario.','exclamation')
	CLEAR FORM 
	CALL control_display_botones()
	RETURN 0
END IF

IF INT_FLAG THEN
	ROLLBACK WORK 
	CLEAR FORM 
	CALL control_display_botones()
	INITIALIZE rm_c13.*, rm_c14.* TO NULL
	RETURN 0
END IF

CALL control_cargar_rowid_recepcion(rm_c13.c13_numero_oc)

IF vm_num_recep = 0 THEN
	ROLLBACK WORK 
	CALL fgl_winmessage(vg_producto,'La orden de compra no tiene ninguna recepción para que pueda ser anulada.','exclamation')
	CLEAR FORM 
	CALL control_display_botones()
	INITIALIZE rm_c10.*, rm_c13.*, rm_c14.*TO NULL
	RETURN 0
END IF

CALL control_muestra_recepcion(vm_rows_recep[vm_num_recep])

RETURN 1

END FUNCTION



FUNCTION control_anular()
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE valor_aplicado	DECIMAL(14,2)
DEFINE r_c40		RECORD LIKE ordt040.*
DEFINE r_b12		RECORD LIKE ctbt012.*

	CALL control_update_ordt011()	-- DETALLE DE LA ORDEN DE COMPRA
	CALL control_update_ordt013()	-- RECEPCION

	LET valor_aplicado = control_rebaja_deuda()  
	IF valor_aplicado < 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF

	CALL control_update_cxpt027()	-- RETENIONES
--	RUN 'sh'
COMMIT WORK
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
		CALL fgl_winmessage(vg_producto, 'No existe en ctbt012 comprobante de la ordt040.', 'STOP')
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

CALL fgl_winmessage(vg_producto,'Proceso realizado Ok.','info')
CLEAR FORM
CALL control_display_botones()

RETURN 1

END FUNCTION



FUNCTION control_forma_pago_recep() 

OPEN WINDOW w_204_2 AT 6,8 WITH 16 ROWS, 71 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_204_2 FROM '../forms/ordf204_2'
DISPLAY FORM f_204_2

CALL control_display_botones_2()
CALL control_cargar_ordt015()
CALL control_display_array_ordt015()

CLOSE WINDOW w_204_2

END FUNCTION



FUNCTION control_cargar_ordt015()
DEFINE r_c15			RECORD LIKE ordt015.*
DEFINE i,k,filas		SMALLINT

FOR k = 1 TO fgl_scr_size('r_detalle_2')
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
DEFINE done		SMALLINT
DEFINE r_c10	 	RECORD LIKE ordt010.*
DEFINE r_c01	 	RECORD LIKE ordt001.*
DEFINE r_t23	 	RECORD LIKE talt023.*

LET INT_FLAG = 0
INPUT BY NAME rm_c13.c13_numero_oc WITHOUT DEFAULTS

	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF

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
			END IF
		END IF
		LET INT_FLAG = 0

	AFTER FIELD c13_numero_oc
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
						 rm_c13.c13_numero_oc)
				RETURNING r_c10.*
                	IF r_c10.c10_numero_oc IS  NULL THEN
		    		CALL fgl_winmessage (vg_producto, 'No existe la orden de compra en la Compañía. ','exclamation')
				CLEAR nomprov
                        	NEXT FIELD c13_numero_oc
			END IF

			CALL fl_lee_proveedor(r_c10.c10_codprov)
				RETURNING rm_p01.*

			IF r_c10.c10_estado = 'A' THEN
				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fgl_winmessage(vg_producto,'La Orden de Compra no ha sido aprobada.','exclamation')
				NEXT FIELD c13_numero_oc
			END IF

			CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
				RETURNING r_c01.*

			IF r_c01.c01_ing_bodega = 'S' AND 
			   r_c01.c01_modulo     = 'RE'
			   THEN
				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fgl_winmessage(vg_producto,'La orden de compra pertenece a inventarios debe ser anulada por compra local.','exclamation')
                       		NEXT FIELD c13_numero_oc
			END IF 

			LET rm_c10.c10_tipo_pago = r_c10.c10_tipo_pago
			LET rm_c13.c13_interes   = r_c10.c10_interes
			DISPLAY BY NAME rm_c10.c10_tipo_pago
			DISPLAY rm_p01.p01_nomprov TO nomprov
			
			LET rm_c10.* = r_c10.* 
			IF r_c10.c10_ord_trabajo IS NOT NULL THEN
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
						 r_c10.c10_ord_trabajo)
				RETURNING r_t23.*
				IF r_t23.t23_estado <> 'A' THEN
					CALL fgl_winmessage(vg_producto,'La orden de trabajo asociada a la orden de compra no está activa','exclamation')
                       			NEXT FIELD c13_numero_oc
				END IF
			END IF
					
		ELSE
                       	NEXT FIELD c13_numero_oc
		END IF

	AFTER INPUT

END INPUT

END FUNCTION



FUNCTION control_display_array_ordt015()

LET INT_FLAG = 0

CALL set_count(pagos)

DISPLAY ARRAY r_detalle_2 TO r_detalle_2.* 
        BEFORE DISPLAY
                CALL dialog.keysetlabel('ACCEPT','')
        AFTER DISPLAY
                CONTINUE DISPLAY
        ON KEY(INTERRUPT)
                EXIT DISPLAY
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

LET r_p21.p21_referencia   = 'ANULACION DE RECEPCION #  '|| rm_c13.c13_num_recep
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
				  vg_codloc, 'TE', 'AA', 'AJ')
IF r_caju.p22_num_trn <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF

LET r_caju.p22_referencia   = 'ANULACION DE RECEPCION #  ', rm_c13.c13_num_recep
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
DEFINE retVal 		INTEGER

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

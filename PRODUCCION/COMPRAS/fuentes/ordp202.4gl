------------------------------------------------------------------------------
-- Titulo           : ordp202.4gl - Recepci�n de Ordenes de Compra
-- Elaboracion      : 15-nov-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun ordp202 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion:
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_retencion	CHAR(2)
-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_c01		RECORD LIKE ordt001.*
DEFINE rm_c10	 	RECORD LIKE ordt010.*	-- CABECERA O.C.
DEFINE rm_c13	 	RECORD LIKE ordt013.*	-- CABECERA RECEPCION
DEFINE rm_c14	 	RECORD LIKE ordt014.*	-- DETALLE RECEPCION
DEFINE rm_c15	 	RECORD LIKE ordt015.*	-- PAGOS
DEFINE rm_p01	 	RECORD LIKE cxpt001.*	-- PROVEEDORES
DEFINE rm_t23	 	RECORD LIKE talt023.*	-- ORDENES DE TRABAJO
DEFINE rm_g13	 	RECORD LIKE gent013.*	-- MONEDAS
DEFINE rm_g14	 	RECORD LIKE gent014.*	-- CONVERSION MONEDAS

DEFINE rm_c00		RECORD LIKE ordt000.*	-- CONFIGURACION DE OC
DEFINE rm_c02		RECORD LIKE ordt002.*	-- PORCENTAJE DE RETENCIONES OC
DEFINE rm_p02		RECORD LIKE cxpt002.*	-- PROVEEDORES POR LOCALIDAD
DEFINE rm_p05		RECORD LIKE cxpt005.*	-- RETENCIONES CONF * PROVEEDOR
DEFINE rm_p27		RECORD LIKE cxpt027.*	-- RETENCIONES

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[250] OF RECORD
	c11_cant_ped		LIKE ordt011.c11_cant_ped,
	c14_cantidad		LIKE ordt014.c14_cantidad,
	c14_codigo		LIKE ordt014.c14_codigo,
	c14_descrip		LIKE ordt014.c14_descrip,
	c14_descuento		LIKE ordt014.c14_descuento,
	c14_precio		LIKE ordt014.c14_precio,
	paga_iva		LIKE ordt011.c11_paga_iva
	END RECORD

	---- ARREGLO PARA LA FORMA DE PAGO ----
DEFINE r_detalle_2 ARRAY[250] OF RECORD
	c15_dividendo		LIKE ordt015.c15_dividendo,
	c15_fecha_vcto		LIKE ordt015.c15_fecha_vcto,
	c15_valor_cap		LIKE ordt015.c15_valor_cap,
	c15_valor_int		LIKE ordt015.c15_valor_int,
	subtotal		LIKE ordt015.c15_valor_cap
	END RECORD
-------------------------------------------------------

DEFINE r_detalle_1 ARRAY[250] OF RECORD
	c11_tipo		LIKE ordt011.c11_tipo,
	c14_val_descto		LIKE ordt014.c14_val_descto
	END RECORD

DEFINE vm_subtotal_2		LIKE ordt013.c13_tot_bruto

	----------------------------------------------------------

DEFINE vm_impuesto		LIKE ordt010.c10_porc_impto
DEFINE vm_moneda		LIKE ordt010.c10_moneda
DEFINE vm_estado		LIKE ordt010.c10_estado
DEFINE vm_ind_arr		SMALLINT  -- INDICE DE MI ARREGLO (INPUT ARRAY)
DEFINE vm_filas_pant		SMALLINT  -- FILAS EN PANTALLA
DEFINE vm_max_detalle		SMALLINT  -- NUMERO MAXIMO ELEMENTOS DEL DETALLE

DEFINE vm_flag_forma_pago	CHAR(1)		-- S o N o Y.. ok
DEFINE vm_flag_recep		CHAR(1)		-- S o N Si recibio o no todo

DEFINE vg_numero_oc		LIKE ordt013.c13_numero_oc

DEFINE vm_calc_iva		CHAR(1)		-- S: Subtotal
						-- D: Detalle

---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE FORMA DE PAGO ----

DEFINE pagos			SMALLINT
DEFINE tot_dias			SMALLINT	
DEFINE fecha_pago		DATE
DEFINE dias_pagos		SMALLINT
DEFINE tot_recep		LIKE ordt010.c10_tot_compra
DEFINE tot_cap			LIKE ordt010.c10_tot_compra
DEFINE tot_int			LIKE ordt010.c10_tot_compra
DEFINE tot_sub			LIKE ordt010.c10_tot_compra
---------------------------------------------------------------

---- DEFINICION DE LOS CAMPOS DE LA VENTANA DE RETENCIONES ----
DEFINE ind_max_ret	SMALLINT
DEFINE ind_ret		SMALLINT
DEFINE r_ret ARRAY[50] OF RECORD
	check		CHAR(1),
	n_retencion	LIKE ordt002.c02_nombre,
	codigo_sri	LIKE cxpt005.p05_codigo_sri,
	tipo_ret	LIKE cxpt005.p05_tipo_ret, 
	val_base	LIKE rept019.r19_tot_bruto, 
	porc		LIKE cxpt005.p05_porcentaje, 
	subtotal 	LIKE rept019.r19_tot_neto
END RECORD

DEFINE iva_bien 	DECIMAL(11,2)	
DEFINE iva_servi	DECIMAL(11,2)	
DEFINE val_bienes	LIKE rept019.r19_tot_bruto
DEFINE val_servi	LIKE rept019.r19_tot_bruto
DEFINE val_impto	LIKE rept019.r19_tot_dscto
DEFINE val_neto		LIKE rept019.r19_tot_neto
DEFINE val_pagar	LIKE rept019.r19_tot_neto
DEFINE tot_ret		LIKE rept019.r19_tot_neto
---------------------------------------------------------------

DEFINE vg_num_recep	LIKE ordt013.c13_num_recep

DEFINE vm_num_recep	SMALLINT
DEFINE vm_row_current	SMALLINT

DEFINE vm_rows_recep	ARRAY[50] OF INTEGER



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN

CALL startlog('../logs/ordp202.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN 
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vg_numero_oc = arg_val(5)
INITIALIZE vg_num_recep TO NULL
IF num_args() = 6 THEN
	LET vg_num_recep = arg_val(6)
END IF
LET vg_proceso = 'ordp202'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE done 	SMALLINT
DEFINE command_line	CHAR(70)

CALL fl_nivel_isolation()
LET vm_max_detalle  = 250
LET vm_estado       = 'P'
LET ind_max_ret     = 50

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW w_202 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_202 FROM '../forms/ordf202_1'
DISPLAY FORM f_202

CALL control_display_botones()

LET vm_filas_pant = fgl_scr_size('r_detalle')

LET vm_retencion = 'RT'

IF vg_num_recep IS NOT NULL THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Retenciones'
		HIDE OPTION 'Grabar'
		HIDE OPTION 'Ver Orden'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF num_args() = 6 THEN
			SHOW OPTION 'Ver Orden'
			SHOW OPTION 'Retenciones'
			HIDE OPTION 'Ingresar Factura'
			IF rm_c10.c10_tipo_pago = 'C' THEN
				HIDE OPTION 'Forma de Pago'
			ELSE
				LET vm_flag_forma_pago = 'N'
				SHOW OPTION 'Forma de Pago'
			END IF
		END IF
		IF num_args() = 5 THEN
			SHOW OPTION 'Retenciones'
			HIDE OPTION 'Ingresar Factura'
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
						 vg_numero_oc)
				RETURNING rm_c10.*
			IF rm_c10.c10_numero_oc IS NULL THEN
				CALL fgl_winmessage(vg_producto,'La orden de compra no existe.','exclamation')
				EXIT PROGRAM
			END IF
			CALL control_cargar_rowid_recepcion()
			IF vm_num_recep = 0 THEN
				CALL fgl_winmessage(vg_producto,'La orden de compra no tiene ninguna recepci�n.','exclamation')
				EXIT PROGRAM
			END IF

			LET vm_row_current = 1
			CALL control_muestra_recepcion(vm_rows_recep[vm_row_current])
			CALL muestra_contadores()
			IF rm_c10.c10_tipo_pago = 'C' THEN
				HIDE OPTION 'Forma de Pago'
			ELSE
				LET vm_flag_forma_pago = 'N'
				SHOW OPTION 'Forma de Pago'
			END IF
			IF vm_num_recep > 1 THEN
				SHOW OPTION 'Avanzar'
			END IF
			IF vm_ind_arr > vm_filas_pant THEN
				SHOW OPTION 'Ver Detalle'
			END IF
		END IF

	COMMAND KEY('A') 'Avanzar' 'Ver siguiente recepci�n.'
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
		IF rm_c10.c10_tipo_pago = 'C' THEN
			HIDE OPTION 'Forma de Pago'
		ELSE
			SHOW OPTION 'Forma de Pago'
		END IF

	COMMAND KEY('R') 'Retroceder' 'Ver anterior recepci�n.'
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
		IF rm_c10.c10_tipo_pago = 'C' THEN
			HIDE OPTION 'Forma de Pago'
		ELSE
			SHOW OPTION 'Forma de Pago'
		END IF

	COMMAND KEY('D') 'Ver Detalle' 'Ver Detalle de la Recepci�n.'
		CALL control_display_array_ordt014()

	COMMAND KEY('I') 'Ingresar Factura' 'Ingresar Factura de Ordenes de Compra.'
		LET done = control_recepcion()
		IF done = 0 THEN
			HIDE OPTION 'Forma de Pago'
			HIDE OPTION 'Retenciones'
			HIDE OPTION 'Grabar'
			HIDE OPTION 'Ver Orden'
		END IF
		IF rm_c10.c10_tipo_pago = 'R' THEN
			SHOW OPTION 'Forma de Pago'
		END IF
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			SHOW OPTION 'Grabar'
			SHOW OPTION 'Ver Orden'
		ELSE
			HIDE OPTION 'Forma de Pago'
			HIDE OPTION 'Retenciones'
			HIDE OPTION 'Grabar'
			HIDE OPTION 'Ver Orden'
		END IF
		IF rm_c00.c00_cuando_ret = 'P' OR 
		   rm_c13.c13_numero_oc IS NULL 
		   THEN
			HIDE OPTION 'Retenciones'
		ELSE
			CALL control_cargar_retencion()
			SHOW OPTION 'Retenciones'
		END IF

	COMMAND KEY('O') 'Ver Orden' 'Ver la Orden de Compra.'
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			LET command_line = 'fglrun ordp200 ' || vg_base || ' '
					    || vg_modulo || ' ' || vg_codcia 
					    || ' ' || vg_codloc || ' ' ||
					    rm_c13.c13_numero_oc
			RUN command_line
		END IF

	COMMAND KEY('F') 'Forma de Pago'  'Forma de Pago de Ordenes de Compra.'
		IF vm_flag_forma_pago = 'N' THEN
			CALL control_display_detalle_ordt015()
		ELSE
			CALL control_forma_pago()
		END IF

	COMMAND KEY('E') 'Retenciones'  'Retenciones de Ordenes de Compra.'
		IF num_args() = 4 THEN
			CALL control_retencion()
		ELSE
			CALL control_ver_retencion(rm_c10.c10_codprov)
		END IF

	COMMAND KEY('G') 'Grabar'  'Grabar Factuar'
		LET done = control_grabar()
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Retenciones'
		HIDE OPTION 'Grabar'
		HIDE OPTION 'Ver Orden'
		IF NOT done THEN
			CLEAR FORM
			CALL control_display_botones()
			ROLLBACK WORK
		END IF
			
	COMMAND KEY('S') 'Salir'  'Salir del Programa.'
		EXIT MENU

END MENU
		
END FUNCTION



FUNCTION control_ver_retencion(codprov)
DEFINE codprov 		LIKE cxpt001.p01_codprov
DEFINE numret 		LIKE cxpt027.p27_num_ret
DEFINE command_run 	VARCHAR(200)

DECLARE q_cxpt028 CURSOR FOR
	SELECT p28_num_ret FROM cxpt028
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_codprov   = codprov
		  AND p28_num_doc   = rm_c13.c13_factura

OPEN  q_cxpt028
FETCH q_cxpt028 INTO numret
CLOSE q_cxpt028
FREE  q_cxpt028

LET command_run = 'cd ..', vg_separador, '..', vg_separador,
                  'TESORERIA', vg_separador, 'fuentes',
                   vg_separador, '; fglrun cxpp304 ', vg_base,
                  ' ', 'TE', ' ', vg_codcia, ' ', vg_codloc, ' ', 
		   codprov, ' ', numret

RUN command_run

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

DISPLAY 'C Ped'		TO tit_col0
DISPLAY 'C Rec'		TO tit_col1
DISPLAY 'C�digo' 	TO tit_col2
DISPLAY 'Descripci�n'	TO tit_col3
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



FUNCTION control_display_botones_3()

DISPLAY 'Descripci�n' TO bt_nom_ret
DISPLAY 'Cod. SRI'    TO bt_codsri
DISPLAY 'Tipo R.'     TO bt_tipo_ret
DISPLAY 'Valor Base'  TO bt_base 
DISPLAY '%'           TO bt_porc
DISPLAY 'Subtotal'    TO bt_valor

END FUNCTION



FUNCTION control_cargar_rowid_recepcion()
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE i 		SMALLINT

DECLARE q_ordt013 CURSOR FOR
        SELECT *, ROWID FROM ordt013
               WHERE c13_compania  = vg_codcia
                 AND c13_localidad = vg_codloc
                 AND c13_numero_oc = vg_numero_oc
                                                                                
LET i = 1
FOREACH q_ordt013 INTO r_c13.*, vm_rows_recep[i]
        LET i = i + 1
        IF i > ind_max_ret THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_recep = i - 1
                                                                                
END FUNCTION



FUNCTION control_muestra_recepcion(row)
DEFINE row	INTEGER
DEFINE i 	SMALLINT
DEFINE r_c14	RECORD LIKE ordt014.*

DEFINE cont		SMALLINT
DEFINE val_impto	LIKE ordt014.c14_val_impto

SELECT * INTO rm_c13.* FROM ordt013 WHERE ROWID = row

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, vg_numero_oc)
	RETURNING rm_c10.*
	LET rm_c13.c13_num_recep = rm_c13.c13_num_recep 
	LET rm_c13.c13_numero_oc = vg_numero_oc 
	DISPLAY BY NAME rm_c10.c10_tipo_pago, rm_c13.c13_num_recep,
			rm_c13.c13_numero_oc, rm_c13.c13_tot_bruto,
			rm_c13.c13_tot_dscto, rm_c13.c13_tot_impto,
			rm_c13.c13_tot_recep, rm_c13.c13_fecing,
			rm_c13.c13_usuario,   rm_c13.c13_num_guia,
			rm_c13.c13_estado,    rm_c13.c13_fecha_eli	

CASE rm_c13.c13_estado
	WHEN 'E'
		DISPLAY 'ELIMINADA' TO tit_estado
	WHEN 'A'
		DISPLAY 'ACTIVA' TO tit_estado
END CASE

LET vm_filas_pant = fgl_scr_size('r_detalle')

FOR i = 1 TO vm_filas_pant
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].* 
END FOR

CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING rm_p01.*
	DISPLAY rm_p01.p01_nomprov TO nomprov

DECLARE q_ordt014 CURSOR FOR
	SELECT * FROM ordt014
               WHERE c14_compania  = vg_codcia
       		 AND c14_localidad = vg_codloc
        	 AND c14_numero_oc = vg_numero_oc
		 AND c14_num_recep = rm_c13.c13_num_recep
		
LET cont = 0
LET val_impto = 0
LET i = 1
FOREACH q_ordt014 INTO r_c14.*

	SELECT c10_numero_oc, c11_cant_ped INTO r_c14.c14_numero_oc,
						r_detalle[i].c11_cant_ped 
		 FROM ordt010, ordt011
		WHERE c10_compania  = vg_codcia
		  AND c10_localidad = vg_codloc
		  AND c10_numero_oc = r_c14.c14_numero_oc
		  AND c11_compania  = vg_codcia
		  AND c11_localidad = vg_codloc
		  AND c11_numero_oc = r_c14.c14_numero_oc
		  AND c11_codigo    = r_c14.c14_codigo

	LET r_detalle[i].c14_cantidad  = r_c14.c14_cantidad
	LET r_detalle[i].c14_codigo    = r_c14.c14_codigo
	LET r_detalle[i].c14_descrip   = r_c14.c14_descrip
	LET r_detalle[i].c14_descuento = r_c14.c14_descuento
	LET r_detalle[i].c14_precio    = r_c14.c14_precio
	LET r_detalle[i].paga_iva      = r_c14.c14_paga_iva
	IF r_c14.c14_paga_iva = 'N' THEN
		LET cont = cont + 1
	END IF

	LET val_impto = val_impto + r_c14.c14_val_impto

	LET i = i + 1
END FOREACH

IF cont = 0 AND val_impto = 0 THEN
	LET vm_calc_iva = 'S'
ELSE
	LET vm_calc_iva = 'D'
END IF
DISPLAY BY NAME vm_calc_iva

LET vm_ind_arr = i - 1

IF vm_ind_arr < vm_filas_pant THEN
	LET vm_filas_pant = vm_ind_arr
END IF

FOR i = 1 TO vm_filas_pant
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

END FUNCTION



FUNCTION control_display_array_ordt014()
	
LET INT_FLAG = 0
CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.* 
IF int_flag THEN
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_retencion()
DEFINE resp		CHAR(6)
DEFINE c		CHAR(1)
DEFINE salir,i,j	SMALLINT
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_c02		RECORD LIKE ordt002.*

OPEN WINDOW w_214_4 AT 4,5 WITH 20 ROWS, 74 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)		  
OPEN FORM f_214_4 FROM '../forms/ordf202_3'
DISPLAY FORM f_214_4

CALL control_display_botones_3()

CALL fl_lee_proveedor(rm_c10.c10_codprov)	RETURNING rm_p01.*
DISPLAY rm_p01.p01_nomprov TO n_proveedor

DISPLAY BY NAME val_servi, val_bienes, val_impto, val_neto, val_pagar, tot_ret

OPTIONS 
	INSERT KEY F40,
	DELETE KEY F41

LET salir = 0
WHILE NOT salir

IF ind_ret > 0 THEN
	CALL set_count(ind_ret)
ELSE
	CALL fgl_winmessage(vg_producto,
		'No hay datos a mostrar.',
		'exclamation')
	RETURN
END IF

INPUT ARRAY r_ret WITHOUT DEFAULTS FROM ra_ret.*

	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF

	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL dialog.keysetlabel('DELETE', '')

	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()

	BEFORE INSERT
		EXIT INPUT

	BEFORE FIELD check
		LET c = r_ret[i].check
	AFTER FIELD val_base
		IF r_ret[i].val_base IS NULL THEN
			LET r_ret[i].val_base = 0 
		END IF
		IF r_ret[i].val_base = 0 THEN
			LET r_ret[i].check = 'N'
			CALL totales_retenciones_leidas()
			LET r_ret[i].subtotal = 0 
		ELSE
			IF r_ret[i].val_base > val_neto THEN
				CALL fgl_winmessage(vg_producto,'Valor base debe ser menor / igual que el valor de la O.C.','exclamation')
				NEXT FIELD val_base
			END IF
			LET r_ret[i].check = 'S'
		END IF
		CALL totales_retenciones_leidas()
		DISPLAY r_ret[i].* TO ra_ret[j].*
		DISPLAY BY NAME val_pagar, tot_ret
			
	AFTER  FIELD check
		IF c <> r_ret[i].check THEN
			IF r_ret[i].check = 'S' THEN
				CALL fl_lee_tipo_retencion(vg_codcia, 
					r_ret[i].codigo_sri,
					r_ret[i].tipo_ret, 
					r_ret[i].porc
				) RETURNING r_c02.*
				IF r_ret[i].tipo_ret = 'I' THEN
					CASE r_c02.c02_tipo_fuente 
						WHEN 'B'
							LET r_ret[i].val_base = 
								iva_bien 
						WHEN 'S'
							LET r_ret[i].val_base =
								iva_servi
						WHEN 'T'
							LET r_ret[i].val_base =
								val_impto
					END CASE
				ELSE
					CASE r_c02.c02_tipo_fuente 
						WHEN 'B'
							LET r_ret[i].val_base =
								val_bienes
						WHEN 'S'
							LET r_ret[i].val_base = 
								val_servi
						WHEN 'T'
							LET r_ret[i].val_base =
							val_bienes + val_servi
					END CASE
				END IF
				LET r_ret[i].subtotal = 
					(r_ret[i].val_base * 
					(r_ret[i].porc / 100))	
				LET val_pagar = val_pagar - r_ret[i].subtotal
				LET tot_ret = tot_ret + r_ret[i].subtotal
			END IF
			IF r_ret[i].check = 'N' THEN
				LET val_pagar = val_pagar + r_ret[i].subtotal
				LET tot_ret = tot_ret - r_ret[i].subtotal
				LET r_ret[i].val_base = 0
				LET r_ret[i].subtotal = 0 
			END IF
			DISPLAY r_ret[i].* TO ra_ret[j].*
			DISPLAY BY NAME val_pagar, tot_ret
			NEXT FIELD ra_ret[j].check
		END IF
		CALL totales_retenciones_leidas()

	AFTER INPUT 
		LET salir = 1

END INPUT

IF INT_FLAG THEN
	CLOSE WINDOW w_214_4
	RETURN
END IF

END WHILE

END FUNCTION



FUNCTION totales_retenciones_leidas()
DEFINE i		SMALLINT

LET tot_ret   = 0
LET val_pagar = val_neto
FOR i = 1 TO ind_ret
	IF r_ret[i].check = 'N' THEN
		LET r_ret[i].subtotal = 0
	ELSE
		LET r_ret[i].subtotal = (r_ret[i].val_base * 
			                (r_ret[i].porc / 100))	
	END IF
	LET tot_ret = tot_ret + r_ret[i].subtotal
END FOR
LET val_pagar = val_neto - tot_ret
DISPLAY BY NAME val_pagar, tot_ret

END FUNCTION

{
FUNCTION control_cargar_retenciones_aplicadas()
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE i		SMALLINT

DECLARE q_cxpt028 CURSOR FOR 
	SELECT * FROM cxpt028 
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_codprov   = rm_c10.c10_codprov
		  AND p28_num_doc   = rm_c13.c13_factura

FOREACH q_cxpt028 INTO r_p28.*
	FOR i = 1 TO ind_ret 
		IF   THEN
		END IF
		
	END FOR
END FOREACH

END FUNCTION
}



FUNCTION control_cargar_retencion()
DEFINE i 	SMALLINT
DEFINE r_c02	RECORD LIKE ordt002.*	-- PORCENTAJE DE RETENCIONES OC
DEFINE r_p05	RECORD LIKE cxpt005.*	-- RETENCIONES CONF * PROVEEDOR

{
LET val_servi  = rm_c10.c10_tot_mano  * (1 + rm_c10.c10_porc_descto / 100) 
LET val_bienes = rm_c10.c10_tot_repto * (1 + rm_c10.c10_porc_descto / 100) 
}
LET val_impto  = rm_c13.c13_tot_impto
LET val_neto   = rm_c13.c13_tot_recep
LET val_pagar  = val_neto

{
LET iva_bien   = val_bienes * (rm_c10.c10_porc_impto / 100)
LET iva_servi  = val_servi  * (rm_c10.c10_porc_impto / 100)
}

LET tot_ret    = 0

LET ind_ret = 0

DECLARE q_ret CURSOR FOR
	SELECT * FROM ordt002, OUTER cxpt005
		WHERE c02_compania   = vg_codcia
	  	  AND c02_estado     <> 'B'
	  	  AND p05_compania   = c02_compania
	  	  AND p05_codprov    = rm_c10.c10_codprov
		  AND p05_codigo_sri = c02_codigo_sri
	  	  AND p05_tipo_ret   = c02_tipo_ret
	  	  AND p05_porcentaje = c02_porcentaje 

LET i = 1
FOREACH q_ret INTO r_c02.*, r_p05.*
	IF r_c02.c02_tipo_ret = 'F' AND rm_p01.p01_ret_fuente = 'N' 
	THEN
		CONTINUE FOREACH
	END IF
	IF r_c02.c02_tipo_ret = 'I' AND rm_p01.p01_ret_impto = 'N' 
	THEN
		CONTINUE FOREACH
	END IF

	LET r_ret[i].n_retencion = r_c02.c02_nombre
	LET r_ret[i].codigo_sri  = r_c02.c02_codigo_sri
	LET r_ret[i].tipo_ret    = r_c02.c02_tipo_ret
	LET r_ret[i].porc        = r_c02.c02_porcentaje
	LET r_ret[i].check       = 'N'
	LET r_ret[i].val_base    = 0
	LET r_ret[i].subtotal    = 0

	IF r_p05.p05_tipo_ret IS NOT NULL THEN

		LET r_ret[i].check = 'S'
		IF r_p05.p05_tipo_ret = 'I' THEN
			CASE r_c02.c02_tipo_fuente 
				WHEN 'B'
					LET r_ret[i].val_base = iva_bien 
				WHEN 'S'
					LET r_ret[i].val_base = iva_servi
				WHEN 'T'
					LET r_ret[i].val_base = val_impto
			END CASE
		ELSE
			CASE r_c02.c02_tipo_fuente 
				WHEN 'B'
					LET r_ret[i].val_base = val_bienes
				WHEN 'S'
					LET r_ret[i].val_base = val_servi
				WHEN 'T'
					LET r_ret[i].val_base = 
						val_bienes + val_servi
			END CASE
		END IF

		LET r_ret[i].subtotal = 
			      (r_ret[i].val_base * (r_p05.p05_porcentaje / 100))

		LET tot_ret   = tot_ret + r_ret[i].subtotal 
		LET val_pagar = val_pagar - r_ret[i].subtotal

	END IF

	LET i = i + 1
	IF i > ind_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH

LET ind_ret = i - 1

END FUNCTION



FUNCTION control_recepcion()
DEFINE i 	SMALLINT

define r_b12	record like ctbt012.*

CLEAR FORM
CALL control_display_botones()

INITIALIZE rm_c00.*, rm_c13.*, rm_c14.* TO NULL
LET tot_ret = 0

LET vm_flag_forma_pago = 'N'
LET rm_c13.c13_fecing  = CURRENT
LET rm_c13.c13_usuario = vg_usuario
LET rm_c13.c13_estado  = 'A'

DISPLAY 'ACTIVA' TO tit_estado 
DISPLAY BY NAME rm_c13.c13_fecing, rm_c13.c13_usuario, rm_c13.c13_estado

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
FETCH q_ordt010 INTO rm_c10.*

WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK 
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	CALL fgl_winmessage(vg_producto,'La orden de compra est� siendo recibida por otro usuario.','exclamation')
	CLEAR FORM 
	CALL control_display_botones()
	RETURN 0
END IF

IF int_flag THEN
	ROLLBACK WORK 
	CLEAR FORM 
	CALL control_display_botones()
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	RETURN 0
END IF

CALL control_cargar_detalle()

IF vm_ind_arr = 0 THEN
	ROLLBACK WORK 
	CLEAR FORM 
	CALL control_display_botones()
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	RETURN 0
END IF

IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
	WHENEVER ERROR CONTINUE
	DECLARE q_blot CURSOR FOR
		SELECT * FROM talt023
			WHERE t23_compania  = rm_c10.c10_compania  AND 
	      	      	      t23_localidad = rm_c10.c10_localidad AND 
	      	      	      t23_orden     = rm_c10.c10_ord_trabajo
			FOR UPDATE
      	OPEN q_blot
	FETCH q_blot INTO rm_t23.*
	IF status = NOTFOUND THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Orden de trabajo: ' ||
				    rm_c10.c10_ord_trabajo ||
				    ' no existe.', 'stop')
		EXIT PROGRAM
	END IF
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Orden de trabajo: ' ||
				    rm_c10.c10_ord_trabajo ||
				    ' est� bloqueada por otro proceso.', 'stop')
		EXIT PROGRAM
	END IF
	IF rm_t23.t23_estado <> 'A' THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Estado de O.T. ' || 
			    	rm_c10.c10_ord_trabajo ||
			    	' no est� activa.', 'stop')
		EXIT PROGRAM
	END IF
END IF		
WHENEVER ERROR STOP

IF rm_c01.c01_bien_serv = 'S' OR rm_c01.c01_bien_serv = 'T' THEN 

	FOR i = 1 TO  vm_ind_arr
		LET r_detalle[i].c14_cantidad = r_detalle[i].c11_cant_ped
	END FOR
	CALL calcula_totales()
	LET vm_flag_forma_pago = 'N'
	CALL control_display_array_ordt014()
	LET INT_FLAG = 0
	RETURN 1

END IF

CALL control_lee_detalle_ordt014() 

IF int_flag THEN
	ROLLBACK WORK 
	CLEAR FORM
	CALL control_display_botones()
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	RETURN 0
END IF

RETURN 1

END FUNCTION



FUNCTION control_grabar()

DEFINE done 	SMALLINT
DEFINE resp	CHAR(6)
DEFINE estado   LIKE ordt010.c10_estado

DEFINE r_c01	RECORD LIKE ordt001.*
DEFINE r_b00	RECORD LIKE ctbt000.*
DEFINE r_b12	RECORD LIKE ctbt012.*

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*

--- PARA VALIDAR QUE GENERE LA FORMA DE PAGO CUANDO ES UNA RECEPCION PARCIAL ---

IF  rm_c10.c10_tipo_pago = 'R' AND vm_flag_forma_pago = 'S' 
    THEN
	CALL fgl_winmessage(vg_producto,'Debe generar la forma de pago.',
			    'exclamation')
	RETURN 0
END IF
-------------------------------------------------------------------------------

--- PARA VALIDAR QUE GENERE LA RETENCION DE LA ORDEN DE COMPRA ---

IF rm_c00.c00_cuando_ret = 'C' AND tot_ret = 0 AND r_c01.c01_porc_retf_b = 1 
THEN
	CALL fgl_winmessage(vg_producto, 'Debe ingresar las retenciones.',
			    'exclamation')
	RETURN 0
END IF
-----------------------------------------------------------------------

IF vm_flag_recep = 'S' THEN
	CALL fgl_winquestion(vg_producto,'La orden de compra no ha sido recibida completamente desea recibir restante ?','No','Yes|No', 'question',1)
		RETURNING resp
	LET estado = 'P'
	IF resp = 'No' THEN
		LET estado = 'C'
	END IF

	UPDATE ordt010 SET c10_estado      = estado,
			   c10_factura     = rm_c13.c13_num_guia,
			   c10_fecha_fact  = TODAY,
			   c10_fecha_entre = CURRENT	
		WHERE CURRENT OF q_ordt010 
ELSE
	UPDATE ordt010 SET c10_estado      = 'C',
			   c10_factura     = rm_c13.c13_num_guia,
			   c10_fecha_fact  = TODAY,
			   c10_fecha_entre = CURRENT	
		WHERE CURRENT OF q_ordt010 
END IF

CALL control_insert_ordt013()
CALL control_insert_ordt014()
--CALL control_update_ordt011()

IF rm_c10.c10_tipo_pago = 'R' THEN
	IF vm_flag_forma_pago = 'N' THEN
		CALL control_insert_ordt015_1()
	ELSE
		CALL control_insert_ordt015_2()
	END IF
END IF

-- SI la compra es al contado solo grabara un registro
CALL control_insert_cxpt020()

INITIALIZE rm_p27.* TO NULL
IF rm_c00.c00_cuando_ret = 'C' THEN
	LET done = graba_retenciones()
	-- SI done = 1 hubieron retenciones
	-- SI done = 0 no hubieron retenciones y no se hara ajuste
	IF done THEN
		CALL graba_ajuste_retencion()
		-- REGRESA INT_FLAG = 1 CUANDO HUBO UN ERROR EN
		-- LA FUNCION DE SECUENCIAS DE TRANSACCIONES Y 
		-- DEBE DESHACER TODO
	END IF
END IF

IF rm_p27.p27_num_ret IS NOT NULL THEN
	UPDATE ordt013 SET c13_num_ret = rm_p27.p27_num_ret
		WHERE c13_compania  = vg_codcia
		  AND c13_localidad = vg_codloc
		  AND c13_numero_oc = rm_c13.c13_numero_oc
		  AND c13_num_recep = rm_c13.c13_num_recep
END IF

CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_c10.c10_codprov)

--- ACTUALIZAR LA ORDEN DE TRABAJO ASOCIADA ---
IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
	CALL actualiza_ot_x_oc()
END IF
--------------------------------------------------------------------------------

INITIALIZE r_b12.* TO NULL

IF r_c01.c01_gendia_auto = 'N' THEN 
	CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*
	--IF r_b00.b00_inte_online = 'S' THEN
		CALL contabilizacion_online() RETURNING r_b12.*
		IF int_flag THEN
			RETURN 0
		END IF
	--END IF
END IF

COMMIT WORK

IF r_b12.b12_compania IS NOT NULL AND r_b00.b00_mayo_online = 'S' THEN
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp,
				     r_b12.b12_num_comp, 'M')
END IF
IF rm_c10.c10_ord_trabajo IS NOT NULL AND r_b00.b00_inte_online = 'S' THEN
	CALL fl_control_master_contab_compras(vg_codcia, vg_codloc, 
			rm_c13.c13_numero_oc, rm_c13.c13_num_recep)
END IF
IF rm_c00.c00_cuando_ret = 'C' THEN
	CALL imprime_retenciones()
END IF
CALL fl_mensaje_proveedor_documentos_favor(vg_codcia, vg_codloc, 
										   rm_c10.c10_codprov)
										   
CALL fgl_winmessage(vg_producto,'Proceso realizado Ok.','info')
	
CLEAR FORM
CALL control_display_botones()

RETURN 1

END FUNCTION



FUNCTION graba_retenciones()
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE i, done,orden	SMALLINT

LET done = 1
IF (val_neto - val_pagar) = 0 THEN
	-- No se ha retenido nada, no se generara ajuste
	LET done = 0
	RETURN done
END IF

INITIALIZE rm_p27.*, r_p28.* TO NULL

LET rm_p27.p27_compania      = vg_codcia
LET rm_p27.p27_localidad     = vg_codloc
LET rm_p27.p27_estado        = 'A'
LET rm_p27.p27_codprov       = rm_c10.c10_codprov
LET rm_p27.p27_moneda        = rm_c10.c10_moneda
LET rm_p27.p27_paridad       = rm_c10.c10_paridad
LET rm_p27.p27_total_ret     = tot_ret
LET rm_p27.p27_origen        = 'A'
LET rm_p27.p27_usuario       = vg_usuario
LET rm_p27.p27_fecing        = CURRENT

LET rm_p27.p27_num_ret = nextValInSequence('TE', vm_retencion)
IF rm_p27.p27_num_ret = -1 THEN
	LET INT_FLAG = 1
	RETURN
END IF

INSERT INTO cxpt027 VALUES(rm_p27.*) 

-- Graba Detalle Retencion

LET r_p28.p28_compania   = vg_codcia        
LET r_p28.p28_localidad  = vg_codloc
LET r_p28.p28_num_ret    = rm_p27.p27_num_ret
LET r_p28.p28_codprov    = rm_p27.p27_codprov
LET r_p28.p28_tipo_doc   = 'FA'
LET r_p28.p28_num_doc    = rm_c13.c13_factura
LET r_p28.p28_dividendo  = 1			-- Siempre se graba 1
LET r_p28.p28_valor_fact = rm_c13.c13_tot_recep

LET orden = 1
FOR i = 1 TO ind_ret
	IF r_ret[i].check = 'N' THEN
		CONTINUE FOR
	END IF
	LET r_p28.p28_secuencia  = orden
	LET orden = orden + 1
	LET r_p28.p28_codigo_sri = r_ret[i].codigo_sri
	LET r_p28.p28_tipo_ret   = r_ret[i].tipo_ret
	LET r_p28.p28_porcentaje = r_ret[i].porc
	LET r_p28.p28_valor_base = r_ret[i].val_base
	LET r_p28.p28_valor_ret  = r_ret[i].subtotal
	
	INSERT INTO cxpt028 VALUES(r_p28.*)
END FOR

RETURN done

END FUNCTION



FUNCTION graba_ajuste_retencion()
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*
DEFINE i, orden		SMALLINT

INITIALIZE r_p22.* TO NULL
INITIALIZE r_p23.* TO NULL

-- Graba Cabecera Ajuste Documento
LET r_p22.p22_compania   = vg_codcia
LET r_p22.p22_localidad  = vg_codloc
LET r_p22.p22_codprov    = rm_c10.c10_codprov
LET r_p22.p22_tipo_trn   = 'AJ'

LET r_p22.p22_num_trn    = nextValInSequence('TE', r_p22.p22_tipo_trn)

LET r_p22.p22_referencia = 'RET # '|| rm_p27.p27_num_ret, ', RECEP # '|| 
			   rm_c13.c13_num_recep || ', OC # '||
			   rm_c10.c10_numero_oc
LET r_p22.p22_fecha_emi  = TODAY
LET r_p22.p22_moneda     = rm_c10.c10_moneda
LET r_p22.p22_paridad    = rm_c10.c10_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = (val_neto - val_pagar) * (-1)
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'A'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = CURRENT 

INSERT INTO cxpt022 VALUES(r_p22.*)
--------------------------------------------------------------------------

LET r_p23.p23_compania  = r_p22.p22_compania
LET r_p23.p23_localidad = r_p22.p22_localidad
LET r_p23.p23_codprov   = r_p22.p22_codprov
LET r_p23.p23_tipo_trn  = r_p22.p22_tipo_trn
LET r_p23.p23_num_trn   = r_p22.p22_num_trn

	LET r_p23.p23_tipo_doc   = 'FA'
	LET r_p23.p23_num_doc    = rm_c13.c13_factura
	LET r_p23.p23_div_doc    = 1
	LET r_p23.p23_valor_int  = 0
	LET r_p23.p23_valor_mora = 0
	LET r_p23.p23_saldo_int  = 0

LET orden = 1
FOR i = 1 TO ind_ret
	IF r_ret[i].check = 'N' THEN
		CONTINUE FOR
	END IF
	
	LET r_p23.p23_orden     = orden
	LET orden = orden + 1
	LET r_p23.p23_valor_cap = r_ret[i].subtotal * (-1)

	SELECT p20_saldo_cap INTO r_p23.p23_saldo_cap
		FROM cxpt020
		WHERE p20_compania  = vg_codcia
		  AND p20_localidad = vg_codloc
		  AND p20_codprov   = r_p23.p23_codprov
		  AND p20_tipo_doc  = r_p23.p23_tipo_doc
		  AND p20_num_doc   = r_p23.p23_num_doc
		  AND p20_dividendo = r_p23.p23_div_doc
		  
	UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap - r_ret[i].subtotal
		WHERE p20_compania  = vg_codcia
		  AND p20_localidad = vg_codloc
		  AND p20_codprov   = r_p23.p23_codprov
		  AND p20_tipo_doc  = r_p23.p23_tipo_doc
		  AND p20_num_doc   = r_p23.p23_num_doc
		  AND p20_dividendo = r_p23.p23_div_doc
		  
	INSERT INTO cxpt023 VALUES(r_p23.*)
END FOR

END FUNCTION



FUNCTION graba_ajuste_documento_contado()
DEFINE r_p22		RECORD LIKE cxpt022.*
DEFINE r_p23		RECORD LIKE cxpt023.*

INITIALIZE r_p22.*, r_p23.* TO NULL

-- Graba Cabecera Ajuste Documento
LET r_p22.p22_compania   = vg_codcia
LET r_p22.p22_localidad  = vg_codloc
LET r_p22.p22_codprov    = rm_c10.c10_codprov
LET r_p22.p22_tipo_trn   = 'AJ'

LET r_p22.p22_referencia = 'RECEPCION ORDEN DE COMPRA # '|| rm_c13.c13_num_recep || ' PAGO CONTADO'
LET r_p22.p22_fecha_emi  = TODAY
LET r_p22.p22_moneda     = rm_c10.c10_moneda
LET r_p22.p22_paridad    = rm_c10.c10_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = (rm_c13.c13_tot_recep - tot_ret) * -1    --val_pagar
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'A'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = CURRENT 

LET r_p22.p22_num_trn    = nextValInSequence('TE', r_p22.p22_tipo_trn)


INSERT INTO cxpt022 VALUES(r_p22.*)
--------------------------------------------------------------------------

LET r_p23.p23_compania  = r_p22.p22_compania
LET r_p23.p23_localidad = r_p22.p22_localidad
LET r_p23.p23_codprov   = r_p22.p22_codprov
LET r_p23.p23_tipo_trn  = r_p22.p22_tipo_trn
LET r_p23.p23_num_trn   = r_p22.p22_num_trn

LET r_p23.p23_tipo_doc   = 'FA'
LET r_p23.p23_num_doc    = rm_c13.c13_factura
LET r_p23.p23_div_doc    = 1		-- Un solo divividendo 
LET r_p23.p23_valor_int  = 0
LET r_p23.p23_valor_mora = 0
LET r_p23.p23_saldo_int  = 0
LET r_p23.p23_orden      = 1		-- Un solo detalle
LET r_p23.p23_valor_cap  = r_p22.p22_total_cap

SELECT p20_saldo_cap INTO r_p23.p23_saldo_cap
	FROM cxpt020
	WHERE p20_compania  = vg_codcia
	  AND p20_localidad = vg_codloc
	  AND p20_codprov   = r_p23.p23_codprov
	  AND p20_tipo_doc  = r_p23.p23_tipo_doc
	  AND p20_num_doc   = r_p23.p23_num_doc
	  AND p20_dividendo = r_p23.p23_div_doc
		  
LET val_pagar = rm_c13.c13_tot_recep
UPDATE cxpt020 SET p20_saldo_cap = p20_saldo_cap - val_pagar
	--rm_c13.c13_tot_recep
	WHERE p20_compania  = vg_codcia
	  AND p20_localidad = vg_codloc
	  AND p20_codprov   = r_p23.p23_codprov
	  AND p20_tipo_doc  = r_p23.p23_tipo_doc
	  AND p20_num_doc   = r_p23.p23_num_doc
	  AND p20_dividendo = r_p23.p23_div_doc
	  
INSERT INTO cxpt023 VALUES(r_p23.*)

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
	SET LOCK MODE TO NOT WAIT
	CALL fgl_winmessage(vg_producto,'No existe configuracion de secuencias para este tipo de transacci�n.','stop')
	EXIT PROGRAM
END IF

END WHILE

SET LOCK MODE TO NOT WAIT

RETURN retVal

END FUNCTION



FUNCTION control_display_detalle_ordt015() 

OPEN WINDOW w_202_2 AT 6,8 WITH 16 ROWS, 71 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
	  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_202_2 FROM '../forms/ordf202_2'
DISPLAY FORM f_202_2

CALL control_display_botones_2()

IF vm_flag_recep = 'N' THEN
	CALL control_cargar_ordt015_2()
ELSE
	CALL control_cargar_ordt015_1()
END IF

CALL control_display_array_ordt015()

CLOSE WINDOW w_202_2

END FUNCTION


{
FUNCTION control_cargar_ordt015_2()
DEFINE r_c12		RECORD LIKE ordt012.*
DEFINE i,k		SMALLINT

DECLARE q_ordt015_2 CURSOR FOR 
	SELECT * FROM ordt015 
		WHERE c15_compania  = vg_codcia
		  AND c15_localidad = vg_codloc
		  AND c15_numero_oc = rm_c13.c13_numero_oc
		  AND c15_num_recep = rm_c13.c13_num_recep

LET i = 1
FOREACH q_ordt015_2 INTO r_c15.*

	LET r_detalle_2[i].c15_dividendo  = r_c15.c15_dividendo
	LET r_detalle_2[i].c15_fecha_vcto = r_c15.c15_fecha_vcto
	LET r_detalle_2[i].c15_valor_cap  = r_c15.c15_valor_cap
	LET r_detalle_2[i].c15_valor_int  = r_c15.c15_valor_int

	LET i = i + 1

END FOREACH

LET i = i - 1

LET pagos = i

END FUNCTION
}



FUNCTION control_insert_ordt015_1()
DEFINE sql_expr		CHAR(300)

LET sql_expr = 'INSERT INTO ordt015 ',
	       '	SELECT c12_compania, c12_localidad, c12_numero_oc, ',
	         	       rm_c13.c13_num_recep, ', c12_dividendo, ', 
	       '   	       c12_fecha_vcto, c12_valor_cap, c12_valor_int ',
	       '	FROM ordt012 ',
	       '	WHERE c12_compania  = ', vg_codcia,
	       '	AND   c12_localidad = ', vg_codloc,
	       '	AND   c12_numero_oc = ', rm_c13.c13_numero_oc

PREPARE statement1 FROM sql_expr
EXECUTE statement1

END FUNCTION



FUNCTION control_insert_ordt013()

INITIALIZE rm_c13.c13_fecha_eli TO NULL

LET rm_c13.c13_compania    = vg_codcia
LET rm_c13.c13_localidad   = vg_codloc
LET rm_c13.c13_fecing      = CURRENT
LET rm_c13.c13_fecha_recep = CURRENT
LET rm_c13.c13_factura     = rm_c13.c13_num_guia
LET rm_c13.c13_estado      = 'A'

SELECT MAX(c13_num_recep) + 1 INTO rm_c13.c13_num_recep
	 FROM ordt013
	WHERE c13_compania  = vg_codcia
	  AND c13_localidad = vg_codloc
	  AND c13_numero_oc = rm_c13.c13_numero_oc

IF rm_c13.c13_num_recep IS NULL THEN
	LET rm_c13.c13_num_recep = 1
END IF

INSERT INTO ordt013 VALUES(rm_c13.*)
DISPLAY BY NAME rm_c13.c13_num_recep

END FUNCTION



FUNCTION control_cargar_ordt015_1()
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
	LET dias_pagos = r_detalle_2[1].c15_fecha_vcto - DATE(rm_c13.c13_fecing)
END IF
LET tot_dias = dias_pagos * i

LET pagos = i
DISPLAY BY NAME tot_recep, dias_pagos, pagos, tot_cap, tot_int, 
		tot_sub,   fecha_pago, tot_dias, rm_c13.c13_interes

END FUNCTION



FUNCTION control_cargar_ordt015_2()
DEFINE r_c12			RECORD LIKE ordt012.*
DEFINE i,k,filas		SMALLINT

FOR k = 1 TO fgl_scr_size('r_detalle_2')
	INITIALIZE r_detalle_2[k].* TO NULL
	CLEAR      r_detalle_2[k].*
END FOR

DECLARE q_ordt012 CURSOR FOR 
	SELECT * FROM ordt012 
		WHERE c12_compania  = vg_codcia
		  AND c12_localidad = vg_codloc
		  AND c12_numero_oc = rm_c13.c13_numero_oc

LET tot_cap = 0
LET tot_int = 0
LET tot_sub = 0
LET i = 1
FOREACH q_ordt012 INTO r_c12.*

	LET r_detalle_2[i].c15_dividendo  = r_c12.c12_dividendo
	LET r_detalle_2[i].c15_fecha_vcto = r_c12.c12_fecha_vcto
	LET r_detalle_2[i].c15_valor_cap  = r_c12.c12_valor_cap
	LET r_detalle_2[i].c15_valor_int  = r_c12.c12_valor_int
	LET r_detalle_2[i].subtotal       = r_c12.c12_valor_cap +
					    r_c12.c12_valor_int

	LET tot_cap = tot_cap + r_c12.c12_valor_cap	
	LET tot_int = tot_int + r_c12.c12_valor_int	
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
	LET dias_pagos = r_detalle_2[1].c15_fecha_vcto - DATE(rm_c13.c13_fecing)
END IF
LET tot_dias = dias_pagos * i

LET pagos = i
LET rm_c13.c13_interes = rm_c10.c10_interes
DISPLAY BY NAME tot_recep, dias_pagos, pagos, tot_cap, tot_int, 
		tot_sub,   fecha_pago, tot_dias, rm_c13.c13_interes

END FUNCTION



FUNCTION control_insert_ordt014()
DEFINE i,k 	SMALLINT

LET rm_c14.c14_compania   = vg_codcia
LET rm_c14.c14_localidad  = vg_codloc
LET rm_c14.c14_numero_oc  = rm_c13.c13_numero_oc
LET rm_c14.c14_num_recep  = rm_c13.c13_num_recep

LET k = 1
FOR i = 1 TO vm_ind_arr

	IF r_detalle[i].c14_cantidad > 0 THEN
		LET rm_c14.c14_cantidad  = r_detalle[i].c14_cantidad
		LET rm_c14.c14_codigo       = r_detalle[i].c14_codigo
		LET rm_c14.c14_descrip      = r_detalle[i].c14_descrip
		LET rm_c14.c14_descuento    = r_detalle[i].c14_descuento
		LET rm_c14.c14_precio       = r_detalle[i].c14_precio
		LET rm_c14.c14_secuencia    = k
		LET rm_c14.c14_paga_iva     = r_detalle[i].paga_iva
		LET rm_c14.c14_val_descto   = r_detalle_1[i].c14_val_descto
		IF vm_calc_iva = 'D' AND rm_c14.c14_paga_iva = 'S' THEN
			LET rm_c14.c14_val_impto = ((rm_c14.c14_cantidad * 
					             rm_c14.c14_precio)  -
						    rm_c14.c14_val_descto) *
						    vm_impuesto / 100 	
		ELSE
			LET rm_c14.c14_val_impto = 0
		END IF

		INSERT INTO ordt014 VALUES(rm_c14.*)

		LET k = k + 1
		
	END IF
END FOR 

END FUNCTION



FUNCTION control_update_ordt011()
DEFINE i 	SMALLINT

FOR i = 1 TO vm_ind_arr

	IF r_detalle[i].c14_cantidad > 0 THEN

		UPDATE ordt011 
			SET c11_cant_rec = c11_cant_rec + 
					   r_detalle[i].c14_cantidad
			WHERE c11_compania  = vg_codcia
			  AND c11_localidad = vg_codloc
			  AND c11_numero_oc = rm_c13.c13_numero_oc
			  AND c11_codigo    = r_detalle[i].c14_codigo

	END IF

END FOR 

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE resp 		CHAR(6)
DEFINE done		SMALLINT
DEFINE r_c10	 	RECORD LIKE ordt010.*
DEFINE r_p20	 	RECORD LIKE cxpt020.*
DEFINE oc_ant		LIKE ordt010.c10_numero_oc

LET vm_calc_iva = 'S' 

LET int_flag = 0
INPUT BY NAME rm_c13.c13_numero_oc, rm_c13.c13_num_guia, 
	      rm_c13.c13_num_aut,   rm_c13.c13_serie_comp,
	      vm_calc_iva 
	      WITHOUT DEFAULTS

	ON KEY (INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF

	ON KEY(F2)
		IF INFIELD(c13_numero_oc) THEN
			CALL fl_ayuda_ordenes_compra(vg_codcia, vg_codloc,
						     0, 0, 'P','00','T')
				RETURNING r_c10.c10_numero_oc
			IF r_c10.c10_numero_oc IS NOT NULL THEN
				CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
							 r_c10.c10_numero_oc)
					RETURNING r_c10.*
				LET rm_c13.c13_numero_oc = r_c10.c10_numero_oc
				LET rm_c10.c10_tipo_pago = r_c10.c10_tipo_pago
				DISPLAY BY NAME rm_c13.c13_numero_oc,
						rm_c10.c10_tipo_pago
			END IF
		END IF

		LET int_flag = 0
	BEFORE FIELD c13_numero_oc
		LET oc_ant = rm_c13.c13_numero_oc
	AFTER FIELD c13_numero_oc
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
						 rm_c13.c13_numero_oc)
				RETURNING r_c10.*
                	IF r_c10.c10_numero_oc IS  NULL THEN
		    		CALL fgl_winmessage (vg_producto, 'No existe la orden de compra en la Compa��a. ','exclamation')
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

			IF r_c10.c10_estado = 'C' THEN
				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fgl_winmessage(vg_producto,'La Orden de Compra est� cerrada.','exclamation')
				NEXT FIELD c13_numero_oc
			END IF

			CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
				RETURNING rm_c01.*

			IF rm_c01.c01_ing_bodega = 'S' AND 
			   rm_c01.c01_modulo     = 'RE'
			   THEN
				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fgl_winmessage(vg_producto,'La orden de compra pertenece a inventarios debe ser recibida por compra local.','exclamation')
                       		NEXT FIELD c13_numero_oc
			END IF 

			LET rm_c10.c10_tipo_pago = r_c10.c10_tipo_pago
			LET rm_c13.c13_interes   = r_c10.c10_interes
			DISPLAY BY NAME rm_c10.c10_tipo_pago
			DISPLAY rm_p01.p01_nomprov TO nomprov
			IF oc_ant IS NULL OR oc_ant <> rm_c13.c13_numero_oc THEN
				LET rm_c13.c13_num_aut    = rm_p01.p01_num_aut
				LET rm_c13.c13_serie_comp = rm_p01.p01_serie_comp
				DISPLAY BY NAME rm_c13.c13_num_aut,
						rm_c13.c13_serie_comp
			END IF
			LET vm_moneda   = r_c10.c10_moneda
			LET vm_impuesto = r_c10.c10_porc_impto

			LET rm_c10.* = r_c10.* 
			CALL fl_lee_compania_orden_compra(vg_codcia)	
				RETURNING rm_c00.*

		ELSE
                       	NEXT FIELD c13_numero_oc
		END IF

	AFTER INPUT 
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, 
						 rm_c10.c10_codprov, 'FA',
						 rm_c13.c13_num_guia, 1)
			RETURNING r_p20.*
		IF r_p20.p20_num_doc IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'La factura ya ha sido recibida.','exclamation')
			NEXT FIELD c13_num_guia
		END IF

		

END INPUT

END FUNCTION



FUNCTION control_lee_detalle_ordt014()
DEFINE i,j,k,sum_oc, sum_recep	SMALLINT
DEFINE resp			CHAR(6)

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F40

LET vm_filas_pant  = fgl_scr_size('r_detalle')
LET rm_c13.c13_tot_recep = 0
LET i = 1
LET j = 1

	CALL set_count(vm_ind_arr)

	LET int_flag = 0
	DISPLAY ARRAY r_detalle TO r_detalle.*
		
		BEFORE ROW
			LET i = arr_curr()   # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()   # POSICION CORRIENTE EN LA PANTALLA
		BEFORE DISPLAY 
			CALL calcula_totales()

	END DISPLAY

END FUNCTION



FUNCTION calcula_totales()
DEFINE k 		SMALLINT
DEFINE v_impto		LIKE ordt013.c13_tot_impto

LET rm_c13.c13_tot_bruto   = 0	
LET rm_c13.c13_tot_dscto   = 0	
LET rm_c13.c13_tot_impto   = 0	
LET rm_c13.c13_tot_recep   = 0	
LET vm_subtotal_2	   = 0	
LET v_impto		   = 0	
LET iva_bien               = 0
LET iva_servi              = 0
LET val_servi              = 0
LET val_bienes             = 0

FOR k = 1 TO vm_ind_arr
	---- SUBTOTAL CODIGO----
	LET vm_subtotal_2 = r_detalle[k].c14_precio * r_detalle[k].c14_cantidad
	----------------------------

	LET rm_c13.c13_tot_bruto  = rm_c13.c13_tot_bruto + vm_subtotal_2 

	---- DESCUENTO - TOT_DSCTO ----
	LET r_detalle_1[k].c14_val_descto = vm_subtotal_2 * 
					    r_detalle[k].c14_descuento / 100  

	LET r_detalle_1[k].c14_val_descto = 
		fl_retorna_precision_valor(vm_moneda,
		                           r_detalle_1[k].c14_val_descto)

	LET rm_c13.c13_tot_dscto = rm_c13.c13_tot_dscto + 
				   r_detalle_1[k].c14_val_descto
	--------------------------------
	IF r_detalle_1[k].c11_tipo = 'B' THEN
		LET val_bienes = val_bienes + vm_subtotal_2 - 
				 r_detalle_1[k].c14_val_descto
	ELSE
		LET val_servi  = val_servi + vm_subtotal_2 - 
				 r_detalle_1[k].c14_val_descto
	END IF
	IF vm_calc_iva = 'D' AND r_detalle[k].paga_iva = 'S' THEN
		---- IMPUESTO - TOT_IMPTO ------
		LET v_impto =(vm_subtotal_2 - r_detalle_1[k].c14_val_descto) * 
			      vm_impuesto / 100
	
		LET v_impto = fl_retorna_precision_valor(vm_moneda, v_impto)
	
		LET rm_c13.c13_tot_impto = rm_c13.c13_tot_impto + v_impto
		--------------------------------
		IF r_detalle_1[k].c11_tipo = 'B' THEN
			LET iva_bien  = iva_bien  + v_impto
		ELSE
			LET iva_servi = iva_servi + v_impto
		END IF
	END IF

END FOR

IF vm_calc_iva = 'S' THEN
	LET rm_c13.c13_tot_impto = (rm_c13.c13_tot_bruto - rm_c13.c13_tot_dscto)
				   * (vm_impuesto / 100)
	LET rm_c13.c13_tot_impto = fl_retorna_precision_valor(vm_moneda, rm_c13.c13_tot_impto)
	LET iva_bien  = val_bienes * vm_impuesto / 100
	LET iva_bien  = fl_retorna_precision_valor(vm_moneda, iva_bien)
	LET iva_servi = val_servi * vm_impuesto / 100
	LET iva_servi = fl_retorna_precision_valor(vm_moneda, iva_servi)
END IF

LET rm_c13.c13_tot_recep = rm_c13.c13_tot_bruto - rm_c13.c13_tot_dscto +
			   rm_c13.c13_tot_impto	

DISPLAY BY NAME rm_c13.c13_tot_dscto, rm_c13.c13_tot_bruto, 
		rm_c13.c13_tot_impto, rm_c13.c13_tot_recep

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(400)
DEFINE r_c11		RECORD LIKE ordt011.*
DEFINE cant_rec		LIKE ordt014.c14_cantidad

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	INITIALIZE r_detalle_1[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR

LET query = 'SELECT * FROM ordt011 ',
            	'WHERE c11_compania  = ', vg_codcia, 
	    	'  AND c11_localidad = ', vg_codloc,
            	'  AND c11_numero_oc = ', rm_c13.c13_numero_oc,
		' ORDER BY 4 '

PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO r_c11.*

	SELECT SUM(c14_cantidad) INTO cant_rec
	  FROM ordt014, ordt013
	 WHERE c13_compania  = r_c11.c11_compania
	   AND c13_localidad = r_c11.c11_localidad
	   AND c13_numero_oc = r_c11.c11_numero_oc
	   AND c13_estado    <> 'E'
	   AND c14_compania  = c13_compania
	   AND c14_localidad = c13_localidad
	   AND c14_numero_oc = c13_numero_oc
	   AND c14_num_recep = c13_num_recep
       AND c14_codigo    = r_c11.c11_codigo

	IF cant_rec IS NULL THEN
		LET cant_rec = 0
	END IF

	LET r_c11.c11_cant_rec = r_c11.c11_cant_rec - cant_rec

	IF r_c11.c11_cant_ped - cant_rec > 0 
	   THEN
		LET r_detalle[i].c11_cant_ped  = r_c11.c11_cant_ped - cant_rec
		LET r_detalle[i].c14_cantidad  = r_c11.c11_cant_rec - cant_rec 
		LET r_detalle[i].c14_codigo    = r_c11.c11_codigo
		LET r_detalle[i].c14_descrip   = r_c11.c11_descrip
		LET r_detalle[i].c14_descuento = r_c11.c11_descuento
		LET r_detalle[i].c14_precio    = r_c11.c11_precio
		LET r_detalle[i].paga_iva      = r_c11.c11_paga_iva 
		LET r_detalle_1[i].c11_tipo    = r_c11.c11_tipo 
		IF r_c11.c11_paga_iva = 'N' THEN
			LET vm_calc_iva = 'D'
			DISPLAY BY NAME vm_calc_iva
		END IF
		LET i = i + 1
        	IF i > vm_max_detalle THEN
			CALL fgl_winmessage(vg_producto,'La cantidad de elementos del detalle supero la cantidad de elementos del arreglo','stop')
			EXIT PROGRAM
		END IF	
	END IF	

END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fgl_winmessage(vg_producto,
			    'No hay elementos del detalle que recibir',
			    'exclamation')
END IF

LET vm_ind_arr = i

END FUNCTION



FUNCTION control_forma_pago()
DEFINE i 	SMALLINT

OPEN WINDOW w_202_2 AT 6,8 WITH 16 ROWS, 71 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_202_2 FROM '../forms/ordf202_2'
DISPLAY FORM f_202_2

CALL control_display_botones_2()

IF pagos = 0 THEN
	LET tot_recep  = rm_c13.c13_tot_recep
	LET fecha_pago = TODAY + 30
	LET dias_pagos = 30
	LET pagos      = 1
	DISPLAY BY NAME pagos, tot_recep, rm_c13.c13_interes, 
			dias_pagos, fecha_pago
	CALL control_lee_cabecera_ordt015()
	CALL control_cargar_detalle_ordt015()
ELSE
	CALL control_cargar_detalle_ordt015()
	CALL control_lee_cabecera_ordt015()
END IF

IF int_flag THEN
	CLOSE WINDOW w_202_2
	RETURN 
END IF

LET int_flag = 0
IF rm_c13.c13_interes > 0 THEN
	CALL control_display_array_ordt015()
ELSE
	CALL control_lee_detalle_ordt015()
END IF

IF int_flag THEN
	CLOSE WINDOW w_202_2
	RETURN 
END IF

CLOSE WINDOW w_202_2

LET vm_flag_forma_pago = 'Y'
RETURN

END FUNCTION



FUNCTION control_insert_ordt015_2()
DEFINE  i 	SMALLINT

LET rm_c15.c15_compania  = vg_codcia
LET rm_c15.c15_localidad = vg_codloc
LET rm_c15.c15_numero_oc = rm_c13.c13_numero_oc
LET rm_c15.c15_num_recep = rm_c13.c13_num_recep

FOR i = 1 TO pagos
	
	LET rm_c15.c15_dividendo  = i
	LET rm_c15.c15_fecha_vcto = r_detalle_2[i].c15_fecha_vcto
	LET rm_c15.c15_valor_cap  = r_detalle_2[i].c15_valor_cap
	LET rm_c15.c15_valor_int  = r_detalle_2[i].c15_valor_int

	INSERT INTO ordt015 VALUES(rm_c15.*)

END FOR

END FUNCTION



FUNCTION control_lee_cabecera_ordt015()
DEFINE resp 	CHAR(6)

LET int_flag = 0
INPUT BY NAME pagos, rm_c13.c13_interes, fecha_pago, dias_pagos 
	      WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
			RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1 
			RETURN	
		END IF
		CONTINUE INPUT
		
	AFTER FIELD fecha_pago
		IF fecha_pago < TODAY THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar una fecha mayor o igual a la de hoy.','exclamation')
			NEXT FIELD fecha_pago
		END IF

	AFTER FIELD pagos
		IF pagos IS NOT NULL AND dias_pagos IS NOT NULL THEN
			LET tot_dias = pagos * dias_pagos
			DISPLAY BY NAME tot_dias
		END IF

	AFTER FIELD dias_pagos
		IF pagos IS NOT NULL AND dias_pagos IS NOT NULL THEN
			LET tot_dias = pagos * dias_pagos
			DISPLAY BY NAME tot_dias
		END IF

	AFTER INPUT 
		IF pagos IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar el n�mero de pagos para generar el detalle.','exclamation')
			NEXT FIELD pagos
		END IF
			
		IF fecha_pago IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar la fecha del primer pago de la orden de compra.','exclamation')
			NEXT FIELD fecha_pago
		END IF

		IF dias_pagos IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar el n�mero de d�as entre pagos para generar el detalle.','exclamation')
			NEXT FIELD dias_pagos
		END IF
			
END INPUT

END FUNCTION



FUNCTION control_lee_detalle_ordt015()
DEFINE resp 		CHAR(6)
DEFINE i,j,k		SMALLINT
DEFINE fecha_aux 	LIKE rept026.r26_fec_vcto

OPTIONS
	INSERT KEY F30,
	DELETE KEY F40

CALL calcula_interes()
WHILE TRUE

	LET int_flag = 0
	CALL set_count(pagos) 

	INPUT ARRAY r_detalle_2 WITHOUT DEFAULTS FROM r_detalle_2.*

		BEFORE INPUT 
			CALL dialog.keysetlabel ('INSERT','')
			CALL dialog.keysetlabel ('DELETE','')

		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1 
				RETURN	
			END IF
			CONTINUE INPUT

		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()

		BEFORE INSERT
			EXIT INPUT

		BEFORE FIELD c15_fecha_vcto
			LET fecha_aux = r_detalle_2[i].c15_fecha_vcto

		AFTER FIELD c15_fecha_vcto
			IF r_detalle_2[i].c15_fecha_vcto IS NULL THEN
				LET r_detalle_2[i].c15_fecha_vcto = fecha_aux
				DISPLAY r_detalle_2[i].c15_fecha_vcto TO
					r_detalle_2[j].c15_fecha_vcto
			END IF

		AFTER FIELD c15_valor_cap
			IF r_detalle_2[i].c15_valor_cap IS NOT NULL THEN
				CALL calcula_interes()
			ELSE 
				NEXT FIELD c15_valor_cap
			END IF

		AFTER INPUT
			FOR k = 1 TO arr_count() - 1
				IF r_detalle_2[k].c15_fecha_vcto >=
				   r_detalle_2[k + 1].c15_fecha_vcto
				   THEN
					CALL fgl_winmessage(vg_producto,'Existen fechas que resultan menores a las ingresadas anteriormente en los pagos. ','exclamation')
					EXIT INPUT
				END IF
			END FOR	

			IF tot_cap > tot_recep THEN
				CALL fgl_winmessage(vg_producto,'El total del valor capital es mayor al total de la deuda. ','exclamation')
				EXIT INPUT
			END IF

			IF tot_cap < tot_recep THEN
				CALL fgl_winmessage(vg_producto,'El total del valor capital es menor al total de la deuda. ','exclamation')
				EXIT INPUT
			END IF

			LET tot_dias = r_detalle_2[pagos].c15_fecha_vcto - TODAY 	
			DISPLAY BY NAME tot_dias

			EXIT WHILE
	END INPUT

END WHILE	

END FUNCTION



FUNCTION control_cargar_detalle_ordt015()
DEFINE i 		SMALLINT
DEFINE saldo    	LIKE ordt013.c13_tot_recep
DEFINE val_div  	LIKE ordt013.c13_tot_recep

LET saldo   = rm_c13.c13_tot_recep
LET val_div = rm_c13.c13_tot_recep / pagos

FOR i = 1 TO pagos

	LET r_detalle_2[i].c15_dividendo = i

	IF i = 1 THEN
		LET r_detalle_2[i].c15_fecha_vcto = fecha_pago
	ELSE
		LET r_detalle_2[i].c15_fecha_vcto = 
		    r_detalle_2[i-1].c15_fecha_vcto + dias_pagos
	END IF

	IF i <> pagos THEN
		LET r_detalle_2[i].c15_valor_cap = val_div
		LET saldo 			 = saldo - val_div
	ELSE
		LET r_detalle_2[i].c15_valor_cap = saldo
	END IF

END FOR 

	LET vm_filas_pant = fgl_scr_size('r_detalle_2')

	IF pagos < vm_filas_pant THEN
		LET vm_filas_pant = pagos
	END IF 

	FOR i = 1 TO vm_filas_pant
		DISPLAY r_detalle_2[i].* TO r_detalle_2[i].*
	END FOR

END FUNCTION



FUNCTION control_display_array_ordt015()

LET int_flag = 0

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




FUNCTION calcula_interes()
DEFINE valor		LIKE ordt015.c15_valor_cap
DEFINE i 		SMALLINT

LET tot_cap = 0
LET tot_int = 0
LET tot_sub = 0
LET valor   = rm_c13.c13_tot_recep

FOR i = 1 TO pagos

	LET r_detalle_2[i].c15_valor_int = valor * 
			                   (rm_c13.c13_interes / 100) *
		      			   (dias_pagos /360)

	LET valor = valor - r_detalle_2[i].c15_valor_cap

	LET r_detalle_2[i].subtotal = r_detalle_2[i].c15_valor_cap +
				      r_detalle_2[i].c15_valor_int

	LET tot_cap     = tot_cap   + r_detalle_2[i].c15_valor_cap
	LET tot_int     = tot_int   + r_detalle_2[i].c15_valor_int
	LET tot_sub     = tot_sub   + r_detalle_2[i].subtotal

END FOR
DISPLAY BY NAME tot_cap, tot_int, tot_sub

END FUNCTION



FUNCTION control_insert_cxpt020()
DEFINE i		SMALLINT
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_c15		RECORD LIKE ordt015.*

LET r_p20.p20_compania    = vg_codcia
LET r_p20.p20_localidad   = vg_codloc
LET r_p20.p20_codprov     = rm_c10.c10_codprov
LET r_p20.p20_usuario     = vg_usuario
LET r_p20.p20_fecing      = CURRENT
LET r_p20.p20_fecha_emi	  = TODAY
LET r_p20.p20_tipo_doc    = 'FA'
LET r_p20.p20_num_doc     = rm_c13.c13_factura
LET r_p20.p20_referencia  = 'RECEPCION # ' || rm_c13.c13_num_recep
LET r_p20.p20_porc_impto  = rm_c10.c10_porc_impto
LET r_p20.p20_tasa_int    = rm_c13.c13_interes
LET r_p20.p20_tasa_mora   = 0
LET r_p20.p20_moneda	  = rm_c10.c10_moneda
LET r_p20.p20_paridad     = rm_c10.c10_paridad
LET r_p20.p20_valor_fact  = rm_c13.c13_tot_recep
LET r_p20.p20_valor_impto = rm_c13.c13_tot_impto

LET r_p20.p20_cod_depto  = rm_c10.c10_cod_depto 
LET r_p20.p20_cartera    = 6
LET r_p20.p20_numero_oc  = rm_c13.c13_numero_oc
LET r_p20.p20_origen     = 'A'		-- automatico

IF rm_c10.c10_tipo_pago = 'R' THEN
	DECLARE q_c15 CURSOR FOR 
		SELECT * FROM ordt015
			WHERE c15_compania  = vg_codcia
	  	  	  AND c15_localidad = vg_codloc
	  	  	  AND c15_numero_oc = rm_c13.c13_numero_oc
	  	     	  AND c15_num_recep = rm_c13.c13_num_recep

	FOREACH q_c15 INTO r_c15.*
		LET r_p20.p20_dividendo  = r_c15.c15_dividendo
		LET r_p20.p20_fecha_vcto = r_c15.c15_fecha_vcto
		LET r_p20.p20_valor_cap  = r_c15.c15_valor_cap
		LET r_p20.p20_saldo_cap  = r_c15.c15_valor_cap
		LET r_p20.p20_valor_int  = r_c15.c15_valor_int
		LET r_p20.p20_saldo_int  = r_c15.c15_valor_int
	
		INSERT INTO cxpt020 VALUES(r_p20.*)
	END FOREACH
ELSE
	LET r_p20.p20_referencia  = 'RECEPCION # ' || rm_c13.c13_num_recep 
				    || '  DE CONTADO'
	LET r_p20.p20_dividendo  = 1
	LET r_p20.p20_fecha_vcto = TODAY
	LET r_p20.p20_valor_cap  = rm_c13.c13_tot_recep
	LET r_p20.p20_valor_int  = 0
	LET r_p20.p20_saldo_cap  = rm_c13.c13_tot_recep
	LET r_p20.p20_saldo_int  = 0
	
	INSERT INTO cxpt020 VALUES(r_p20.*)
END IF

END FUNCTION



FUNCTION actualiza_ot_x_oc()
DEFINE rp		RECORD LIKE cxpt002.*
DEFINE tot_rep, valor	DECIMAL(12,2)
DEFINE tot_mo		DECIMAL(12,2)
DEFINE tipo		LIKE ordt011.c11_tipo
DEFINE r		RECORD LIKE gent050.*

DECLARE q_detoc CURSOR FOR 
	SELECT c11_tipo, SUM((c11_cant_ped * c11_precio) - c11_val_descto)
		FROM ordt011
		WHERE c11_compania  = rm_c10.c10_compania  AND 
		      c11_localidad = rm_c10.c10_localidad AND 
		      c11_numero_oc = rm_c10.c10_numero_oc
		GROUP BY 1
LET tot_rep = 0
LET tot_mo  = 0
FOREACH q_detoc INTO tipo, valor
	IF tipo = 'B' THEN
		LET tot_rep = valor
	ELSE
		LET tot_mo  = valor
	END IF
END FOREACH
LET tot_rep = tot_rep + (tot_rep * rm_c10.c10_recargo / 100)
LET tot_rep = fl_retorna_precision_valor(rm_c10.c10_moneda, tot_rep)
LET tot_mo  = tot_mo  + (tot_mo  * rm_c10.c10_recargo / 100)
LET tot_mo  = fl_retorna_precision_valor(rm_c10.c10_moneda, tot_mo)
IF rm_c01.c01_bien_serv = 'B' THEN
	LET rm_t23.t23_val_rp_tal = rm_t23.t23_val_rp_tal + tot_rep
ELSE	
	IF rm_c01.c01_bien_serv = 'I' THEN     -- Son Suministros
		LET rm_t23.t23_val_otros2 = tot_rep + tot_mo
	ELSE	
		CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_c10.c10_codprov)
			RETURNING rp.*
		IF rp.p02_int_ext = 'I' THEN
			LET rm_t23.t23_val_mo_cti = rm_t23.t23_val_mo_cti + tot_mo
			LET rm_t23.t23_val_rp_cti = rm_t23.t23_val_rp_cti + tot_rep
		ELSE
			LET rm_t23.t23_val_mo_ext = rm_t23.t23_val_mo_ext + tot_mo
			LET rm_t23.t23_val_rp_ext = rm_t23.t23_val_rp_ext + tot_rep
		END IF
	END IF
END IF
WHENEVER ERROR STOP
CALL fl_totaliza_orden_taller(rm_t23.*) RETURNING rm_t23.*
UPDATE talt023 SET * = rm_t23.* 
	WHERE CURRENT OF q_blot

END FUNCTION



FUNCTION imprime_retenciones()

DEFINE resp			VARCHAR(10)
DEFINE retenciones		SMALLINT
DEFINE comando			VARCHAR(250)

SELECT COUNT(*) INTO retenciones FROM cxpt028
WHERE p28_compania  = rm_p27.p27_compania
  AND p28_localidad = rm_p27.p27_localidad
  AND p28_num_ret   = rm_p27.p27_num_ret

IF retenciones = 0 THEN
	RETURN
END IF

CALL fgl_winquestion(vg_producto, 'Desea imprimir comprobante de retencion?', 
	'No', 'Yes|No', 'question', 1) RETURNING resp
IF resp = 'Yes' THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador,
		      'TESORERIA', vg_separador, 'fuentes', 
		      vg_separador, '; fglrun cxpp405 ', vg_base, ' ',
		      'TE', vg_codcia, ' ', vg_codloc,
		      ' ', rm_p27.p27_num_ret    

	RUN comando
END IF

END FUNCTION



FUNCTION contabilizacion_online()

DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_ctas	ARRAY[25] OF RECORD 
	cuenta		LIKE ctbt013.b13_cuenta,
	n_cuenta	LIKE ctbt010.b10_descripcion,
	valor_db	LIKE ctbt013.b13_valor_base,
	valor_cr	LIKE ctbt013.b13_valor_base
END RECORD

DEFINE i, j, col	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE salir		SMALLINT
DEFINE impto		LIKE ordt013.c13_tot_impto
DEFINE retenciones	LIKE cxpt027.p27_total_ret 
DEFINE cuenta_cxp	LIKE ctbt010.b10_cuenta
DEFINE last_lvl_cta	LIKE ctbt001.b01_nivel
DEFINE cuenta      	LIKE ctbt010.b10_cuenta
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base

DEFINE tot_debito	LIKE ctbt013.b13_valor_base
DEFINE tot_credito	LIKE ctbt013.b13_valor_base

DEFINE resp 		VARCHAR(6)
DEFINE query		VARCHAR(250)
DEFINE orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT

FOR i = 1 TO 10
	LET orden[i] = '' 
END FOR
LET columna_1 = 1
LET columna_2 = 2
LET col       = 2

CREATE TEMP TABLE tmp_cuenta(
	te_cuenta	CHAR(12),
	te_descripcion  CHAR(30),
	te_valor_db	DECIMAL(14,2),
	te_valor_cr	DECIMAL(14,2),
	te_serial	SERIAL,
	te_flag		CHAR(1) 
	-- 'F' -> Fijo, no puede ser elminado
	-- 'V' -> Variable, se puede eliminar
);

LET max_rows = 25

INITIALIZE r_b12.* TO NULL

OPEN WINDOW w_202_4 AT 8,3 WITH 12 ROWS, 76 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST)
OPEN FORM f_202_4 FROM "../forms/ordf202_4"
DISPLAY FORM f_202_4

DISPLAY 'Cuenta' 	TO bt_cuenta
DISPLAY 'Descripci�n'	TO bt_descripcion
DISPLAY 'D�bito'	TO bt_valor_db
DISPLAY 'Cr�dito'	TO bt_valor_cr

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc) 
	RETURNING r_c10.*

CALL fl_lee_auxiliares_generales(vg_codcia, vg_codloc) RETURNING r_b42.*
IF r_b42.b42_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se han configurado auxiliares contables para IVA.',
		'exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_c10.c10_codprov)
	RETURNING r_p02.*
IF r_p02.p02_codprov IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se han configurado auxiliares contables para este ' ||
		'proveedor.',
		'exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

LET impto = rm_c13.c13_tot_impto

IF impto IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha realizado ninguna recepci�n.',
		'exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF 

DECLARE q_p28 CURSOR FOR
	SELECT * FROM cxpt028
		WHERE p28_compania  = vg_codcia
		  AND p28_localidad = vg_codloc
		  AND p28_codprov   = rm_c10.c10_codprov
		  AND p28_tipo_doc  = 'FA'
		  AND p28_num_doc   = rm_c13.c13_factura

IF rm_c10.c10_moneda = rg_gen.g00_moneda_base THEN
	LET cuenta_cxp = r_p02.p02_aux_prov_mb
ELSE
	LET cuenta_cxp = r_p02.p02_aux_prov_ma
END IF

CALL inserta_tabla_temporal(cuenta_cxp, 0, rm_c13.c13_tot_recep, 'F') 
	RETURNING tot_debito, tot_credito

LET retenciones = 0
FOREACH q_p28 INTO r_p28.*
	CALL fl_lee_tipo_retencion(vg_codcia, r_p28.p28_codigo_sri,  
								r_p28.p28_tipo_ret, 
		r_p28.p28_porcentaje) RETURNING r_c02.*
	CALL inserta_tabla_temporal(r_c02.c02_aux_cont, 0, r_p28.p28_valor_ret,
		'F') RETURNING tot_debito, tot_credito
	LET retenciones = retenciones + r_p28.p28_valor_ret
END FOREACH

IF retenciones > 0 THEN
	UPDATE tmp_cuenta SET te_valor_cr = te_valor_cr - retenciones
		WHERE te_cuenta = cuenta_cxp
END IF

CALL inserta_tabla_temporal(r_b42.b42_iva_compra, impto, 0, 'F')
	RETURNING tot_debito, tot_credito

SELECT MAX(b01_nivel) INTO last_lvl_cta FROM ctbt001
IF last_lvl_cta IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha configurado el plan de cuentas, no puede haber ' ||
		'contabilizaci�n en l�nea.',
		'exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

LET salir    = 0
WHILE NOT salir
	LET query = 'SELECT te_cuenta, te_descripcion, te_valor_db, ',
		     	'   te_valor_cr ',
		    '	FROM tmp_cuenta ',
		    '	ORDER BY ', columna_1, ' ', orden[columna_1],
			      ', ', columna_2, ' ', orden[columna_2]
	PREPARE ctas FROM query
	DECLARE q_ctas CURSOR FOR ctas 

	LET i = 1
	FOREACH q_ctas INTO r_ctas[i].*    
		LET i = i + 1
		IF i > max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET int_flag = 0
	CALL set_count(i)
	INPUT ARRAY r_ctas WITHOUT DEFAULTS FROM r_ctas.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ON KEY(F2)
			IF INFIELD(b13_cuenta) AND modificable(r_ctas[i].cuenta)
			THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia, 
					last_lvl_cta) 
					RETURNING r_b10.b10_cuenta, 
        					  r_b10.b10_descripcion 
				IF r_b10.b10_cuenta IS NOT NULL THEN
					LET r_ctas[i].cuenta = r_b10.b10_cuenta
					LET r_ctas[i].n_cuenta = 
						r_b10.b10_descripcion
					DISPLAY r_ctas[i].cuenta
						TO r_ctas[j].b13_cuenta
					DISPLAY r_ctas[i].n_cuenta
						TO r_ctas[j].n_cuenta
				END IF	
			END IF
			LET INT_FLAG = 0	
		ON KEY(F15)
			LET col = 1	
			EXIT INPUT
		ON KEY(F16)
			LET col = 2	
			EXIT INPUT
		ON KEY(F17)
			LET col = 3	
			EXIT INPUT
		ON KEY(F18)
			LET col = 4	
			EXIT INPUT
		BEFORE INPUT
			DISPLAY BY NAME tot_debito, tot_credito
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE DELETE
			IF NOT modificable(r_ctas[i].cuenta) THEN
				EXIT INPUT    
			END IF
			DELETE FROM tmp_cuenta 
				WHERE te_cuenta = r_ctas[i].cuenta
--			LET tot_debito  = tot_debito  - r_ctas[i].valor_db
--			LET tot_credito = tot_credito - r_ctas[i].valor_cr
			SELECT SUM(te_valor_db), SUM(te_valor_cr)
 			  INTO tot_debito, tot_credito
			  FROM tmp_cuenta
			DISPLAY BY NAME tot_debito, tot_credito
		BEFORE FIELD b13_cuenta
			LET cuenta = r_ctas[i].cuenta
		AFTER FIELD b13_cuenta
			IF r_ctas[i].cuenta IS NULL AND modificable(cuenta)
			THEN
				CONTINUE INPUT
			END IF
			IF (r_ctas[i].cuenta IS NULL 
			 OR cuenta <> r_ctas[i].cuenta) 
			AND NOT modificable(cuenta) 
			THEN
				CALL fgl_winmessage(vg_producto,
					'No puede modificar esta cuenta.',  
					'exclamation')
				LET r_ctas[i].cuenta = cuenta
				DISPLAY r_ctas[i].cuenta TO r_ctas[j].b13_cuenta
				CONTINUE INPUT
			END IF
			IF (cuenta IS NULL OR cuenta <> r_ctas[i].cuenta) 
			AND NOT modificable(r_ctas[i].cuenta) 
			THEN
				CALL fgl_winmessage(vg_producto,
					'No puede volver a ingresar esta ' ||
					'cuenta.',  
					'exclamation')
				LET r_ctas[i].cuenta = ' '
				NEXT FIELD b13_cuenta
			END IF
			CALL fl_lee_cuenta(vg_codcia, r_ctas[i].cuenta) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'No existe cuenta contable.',
					'exclamation')
				NEXT FIELD b13_cuenta
			END IF
			IF r_b10.b10_nivel <> last_lvl_cta THEN
				CALL fgl_winmessage(vg_producto,
					'La cuenta ingresada debe ' ||
					'ser del �ltimo nivel.',
					'exclamation')
				NEXT FIELD b13_cuenta
			END IF
			CALL inserta_tabla_temporal(r_ctas[i].cuenta,
				r_ctas[i].valor_db, r_ctas[i].valor_cr, 'V')
				RETURNING tot_debito, tot_credito
			DISPLAY BY NAME tot_debito, tot_credito
			LET r_ctas[i].n_cuenta = r_b10.b10_descripcion
			DISPLAY r_ctas[i].n_cuenta TO r_ctas[j].n_cuenta
		BEFORE FIELD valor_db 
			IF NOT modificable(r_ctas[i].cuenta) THEN
				NEXT FIELD b13_cuenta  
			END IF
			LET debito = r_ctas[i].valor_db
		AFTER FIELD valor_db
			IF r_ctas[i].valor_db IS NULL THEN
				LET r_ctas[i].valor_db = 0
				DISPLAY r_ctas[i].valor_db
					TO r_ctas[j].valor_db
			END IF
			IF r_ctas[i].valor_db > 0 THEN
				LET r_ctas[i].valor_cr = 0
				DISPLAY r_ctas[i].valor_cr
					TO r_ctas[j].valor_cr
			END IF
			IF debito <> r_ctas[i].valor_db OR debito IS NULL 
			THEN
				CALL inserta_tabla_temporal(r_ctas[i].cuenta,
					r_ctas[i].valor_db, r_ctas[i].valor_cr,
					'V') RETURNING tot_debito, tot_credito
				DISPLAY BY NAME tot_debito, tot_credito
			{
				IF cuenta_distribucion(vg_codcia, 
						       r_ctas[i].cuenta) 
				AND rm_cuenta[i].valor_debito > 0
				THEN
					CALL muestra_distribucion(vg_codcia,
						rm_cuenta[i].cuenta,
						rm_cuenta[i].valor_debito)
					LET int_flag = 0
				END IF
			}
			END IF
		BEFORE FIELD valor_cr 
			IF NOT modificable(r_ctas[i].cuenta) THEN
				NEXT FIELD b13_cuenta
			END IF
			LET credito = r_ctas[i].valor_cr
		AFTER FIELD valor_cr
			IF r_ctas[i].valor_cr IS NULL THEN
				LET r_ctas[i].valor_cr = 0
				DISPLAY r_ctas[i].valor_cr TO r_ctas[j].valor_cr
			END IF
			IF r_ctas[i].valor_cr > 0 THEN
				LET r_ctas[i].valor_db = 0
				DISPLAY r_ctas[i].valor_db TO r_ctas[j].valor_db
			END IF
			IF credito <> r_ctas[i].valor_cr OR credito IS NULL 
			THEN
				CALL inserta_tabla_temporal(r_ctas[i].cuenta,
					r_ctas[i].valor_db, r_ctas[i].valor_cr,
					'V') RETURNING tot_debito, tot_credito
				DISPLAY BY NAME tot_debito, tot_credito
			{
				IF cuenta_distribucion(vg_codcia, 
						       rm_cuenta[i].cuenta) 
				AND rm_cuenta[i].valor_credito > 0
				THEN
					CALL muestra_distribucion(vg_codcia,
						rm_cuenta[i].cuenta,
						rm_cuenta[i].valor_credito)
					LET int_flag = 0
				END IF
			}
			END IF
		AFTER INPUT
			IF tot_debito <> tot_credito THEN
				CALL fgl_winmessage(vg_producto, 
					'Los valores en el d�bito y el ' ||
					'cr�dito deben ser iguales.',
					'exclamation')
				CONTINUE INPUT
			END IF
			IF tot_debito > rm_c13.c13_tot_recep THEN
				CALL fgl_winmessage(vg_producto, 
					'Los valores en el d�bito y el ' ||
					'cr�dito deben ser iguales ' ||
					'al total de la recepci�n.',
					'exclamation')
				CONTINUE INPUT
			END IF
			LET salir = 1
	END INPUT
	IF int_flag THEN
		CLOSE WINDOW w_202_4
		RETURN r_b12.*
	END IF

	IF col IS NOT NULL AND NOT salir THEN
        	IF col <> columna_1 THEN
        	        LET columna_2        = columna_1
        	        LET orden[columna_2] = orden[columna_1]
        	        LET columna_1        = col
        	END IF
        	IF orden[columna_1] = 'ASC' THEN
        	        LET orden[columna_1] = 'DESC'
        	ELSE
        	        LET orden[columna_1] = 'ASC'
        	END IF
		INITIALIZE col TO NULL
	END IF
END WHILE	

CALL genera_comprobante_contable() RETURNING r_b12.*
IF r_b12.b12_compania IS NULL THEN
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

DROP TABLE tmp_cuenta
CLOSE WINDOW w_202_4

RETURN r_b12.*

END FUNCTION



FUNCTION modificable(cuenta)

DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE return_value	SMALLINT
DEFINE flag		CHAR(1)

INITIALIZE flag TO NULL

SELECT te_flag INTO flag FROM tmp_cuenta WHERE te_cuenta = cuenta

LET return_value = 1
IF flag = 'F' THEN
	LET return_value = 0
END IF

RETURN return_value

END FUNCTION



FUNCTION inserta_tabla_temporal(cuenta, valor_db, valor_cr, flag)

DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE valor_db		LIKE ctbt013.b13_valor_base
DEFINE valor_cr		LIKE ctbt013.b13_valor_base
DEFINE flag		CHAR(1)

DEFINE query		VARCHAR(255)

DEFINE tot_debito	LIKE ctbt013.b13_valor_base
DEFINE tot_credito	LIKE ctbt013.b13_valor_base

CASE flag
	WHEN 'F'
		SELECT * FROM tmp_cuenta WHERE te_cuenta = cuenta
		IF STATUS = NOTFOUND THEN
			LET query = 'INSERT INTO tmp_cuenta ',
					'SELECT "', cuenta CLIPPED, 
					        '", b10_descripcion, ',
					        valor_db, ', ', valor_cr, 
					 ', 0, "', flag, '"',
				        '  FROM ctbt010 ',
					'  WHERE b10_compania = ',  vg_codcia,
					'    AND b10_cuenta   = "', 
							cuenta CLIPPED, '"' 
			PREPARE stmnt1 FROM query
			EXECUTE stmnt1
		END IF
	WHEN 'V'
		SELECT * FROM tmp_cuenta WHERE te_cuenta = cuenta
		IF STATUS = NOTFOUND THEN
			IF valor_db IS NULL THEN
				LET valor_db = 0
			END IF
			IF valor_cr IS NULL THEN
				LET valor_cr = 0
			END IF
			LET query = 'INSERT INTO tmp_cuenta ',
					'SELECT "', cuenta CLIPPED, 
					        '", b10_descripcion, ',
					        valor_db, ', ', valor_cr, 
					 ', 0, "', flag, '"',
				        '  FROM ctbt010 ',
					'  WHERE b10_compania = ',  vg_codcia,
					'    AND b10_cuenta   = "', 
							cuenta CLIPPED, '"' 
			PREPARE stmnt2 FROM query
			EXECUTE stmnt2
		ELSE
			UPDATE tmp_cuenta SET te_valor_db = valor_db,
					      te_valor_cr = valor_cr
				WHERE te_cuenta = cuenta
		END IF
END CASE

SELECT SUM(te_valor_db), SUM(te_valor_cr) 
	INTO tot_debito, tot_credito 
	FROM tmp_cuenta

RETURN tot_debito, tot_credito

END FUNCTION



FUNCTION genera_comprobante_contable()

DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b03		RECORD LIKE ctbt003.*
DEFINE r_b12		RECORD LIKE ctbt012.*

DEFINE glosa 		LIKE ctbt013.b13_glosa
DEFINE query		VARCHAR(500)
DEFINE expr_valor	VARCHAR(100)

INITIALIZE r_b12.* TO NULL
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING r_c10.*

CALL fl_lee_tipo_comprobante_contable(vg_codcia, 'DO') RETURNING r_b03.*
IF r_b03.b03_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,	
		'No existe tipo de comprobante para Diario de Compras: DO',
		'exclamation')
	ROLLBACK WORK
	EXIT PROGRAM
END IF

--LET glosa = 'OC # ' || rm_c13.c13_numero_oc || 
--	    ' RECEPCION # ' || rm_c13.c13_num_recep   
-- OJO
LET glosa = 'OC # ' || rm_c13.c13_numero_oc || 
	    ' FACTURA # ' || rm_c13.c13_factura   

------------------------
  INITIALIZE rm_c10.* TO NULL
  DECLARE q_num_prov CURSOR FOR
  SELECT * FROM ordt010
   WHERE c10_compania = vg_codcia
     AND c10_localidad= rm_c13.c13_localidad
     AND c10_numero_oc= rm_c13.c13_numero_oc
  OPEN q_num_prov
  FETCH q_num_prov INTO rm_c10.*
  IF STATUS <> NOTFOUND THEN
          INITIALIZE rm_p02.* TO NULL
          DECLARE q_prov CURSOR FOR
          SELECT * FROM cxpt002
           WHERE p02_compania = vg_codcia
             AND p02_localidad= rm_c13.c13_localidad
             AND p02_codprov  = rm_c10.c10_codprov
          OPEN q_prov
          FETCH q_prov INTO rm_p02.*
          IF STATUS <> NOTFOUND THEN
             INITIALIZE rm_p01.* TO NULL
             DECLARE q_cod CURSOR FOR
             SELECT * FROM cxpt001
              WHERE p01_codprov = rm_c10.c10_codprov
             OPEN q_cod
             FETCH q_cod INTO rm_p01.*
             IF STATUS <> NOTFOUND THEN
                   LET glosa = rm_p01.p01_nomprov CLIPPED, ' ', rm_c13.c13_factura CLIPPED
             END IF
          CLOSE q_cod
          FREE  q_cod
          END IF
          CLOSE q_prov
          FREE  q_prov
  END IF
  CLOSE q_num_prov
  FREE  q_num_prov
------------------------

INITIALIZE r_b12.* TO NULL
LET r_b12.b12_compania    = vg_codcia  
-- OjO confirmar
LET r_b12.b12_tipo_comp   = r_b03.b03_tipo_comp
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
                            	r_b12.b12_tipo_comp, YEAR(TODAY), MONTH(TODAY))
LET r_b12.b12_estado      = 'A' 
LET r_b12.b12_glosa       = 'COMPROBANTE: ' || glosa CLIPPED 
LET r_b12.b12_origen      = 'A' 
LET r_b12.b12_moneda      = r_c10.c10_moneda 
LET r_b12.b12_paridad     = r_c10.c10_paridad 
LET r_b12.b12_fec_proceso = TODAY
LET r_b12.b12_modulo      = r_b03.b03_modulo
LET r_b12.b12_usuario     = vg_usuario 
LET r_b12.b12_fecing      = CURRENT

INSERT INTO ctbt012 VALUES(r_b12.*)

--
IF r_b12.b12_moneda = r_b00.b00_moneda_base THEN
	LET expr_valor = ' (te_valor_cr * (-1)), 0 '
ELSE
	LET expr_valor = ' (te_valor_cr * (-1) * ', r_b12.b12_paridad, 
			 '), (te_valor_cr * (-1))'
END IF
--
LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_fec_proceso) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
	               '"', glosa CLIPPED, '", ',
	    		expr_valor CLIPPED, ', ', 
	    ' 		DATE("', r_b12.b12_fec_proceso, '")',
	    '		FROM tmp_cuenta ', 
	    '		WHERE te_valor_cr > 0 '
PREPARE stmnt3 FROM query
EXECUTE stmnt3

--
IF r_b12.b12_moneda = r_b00.b00_moneda_base THEN
	LET expr_valor = ' te_valor_db, 0 '
ELSE
	LET expr_valor = ' (te_valor_db * ', r_b12.b12_paridad, 
			 '), te_valor_db'
END IF
--
LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_fec_proceso) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
	    		'"', glosa CLIPPED, '", ',
	    		expr_valor CLIPPED, ', ', 
	    ' 		DATE("', r_b12.b12_fec_proceso, '")',
	    '		FROM tmp_cuenta ', 
	    '		WHERE te_valor_db > 0 '
PREPARE stmnt4 FROM query
EXECUTE stmnt4
UPDATE ctbt013 SET b13_codprov = rm_c10.c10_codprov
	WHERE b13_compania  = vg_codcia AND 
              b13_tipo_comp = r_b12.b12_tipo_comp AND  
              b13_num_comp  = r_b12.b12_num_comp
INSERT INTO ordt040 VALUES(vg_codcia, vg_codloc, rm_c13.c13_numero_oc,
		           rm_c13.c13_num_recep, r_b12.b12_tipo_comp,
		           r_b12.b12_num_comp)
CALL control_impresion_comprobantes(r_b12.b12_tipo_comp, r_b12.b12_num_comp)
RETURN r_b12.*

END FUNCTION


FUNCTION control_impresion_comprobantes(tipo,numero)
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE numero		LIKE ctbt012.b12_num_comp
DEFINE cocoliso		VARCHAR(300)
DEFINE resp			VARCHAR(10)
CALL fgl_winquestion(vg_producto, 'Desea imprimir comprobante contable?', 
	'No', 'Yes|No', 'question', 1) RETURNING resp
IF resp = 'Yes' THEN
	LET cocoliso = 'cd ..', vg_separador, '..', vg_separador,
		'TESORERIA', vg_separador, 'fuentes', 
		vg_separador, '; fglrun cxpp403 ', vg_base, ' ',
		'TE', vg_codcia, ' ', vg_codloc, ' ',
		tipo, ' ',numero
	RUN cocoliso
END IF
END FUNCTION



FUNCTION execute_query()
                                                                                
LET vm_num_recep   = 1
LET vm_row_current = 1
                                                                                
SELECT ROWID INTO vm_rows_recep[vm_num_recep]
        FROM ordt013
        WHERE c13_compania  = vg_codcia
          AND c13_localidad = vg_codloc
	  AND c13_numero_oc = vg_numero_oc  
          AND c13_num_recep = vg_num_recep
IF STATUS = NOTFOUND THEN
        CALL fgl_winmessage(vg_producto, 
		'No existe recepci�n de orden de compra.',
		'exclamation')
        EXIT PROGRAM
ELSE
        CALL control_muestra_recepcion(vm_rows_recep[vm_row_current])
END IF
                                                                                
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

--------------------------------------------------------------------------------
-- Titulo           : ordp202.4gl - Recepción de Ordenes de Compra
-- Elaboracion      : 15-nov-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun ordp202 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_retencion	CHAR(2)
-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_c01		RECORD LIKE ordt001.*	-- TIPO DE O.C.
DEFINE rm_c10	 	RECORD LIKE ordt010.*	-- CABECERA O.C.
DEFINE rm_c13	 	RECORD LIKE ordt013.*	-- CABECERA RECEPCION
DEFINE rm_c14	 	RECORD LIKE ordt014.*	-- DETALLE RECEPCION
DEFINE rm_c15	 	RECORD LIKE ordt015.*	-- PAGOS
DEFINE rm_g34	 	RECORD LIKE gent034.*	-- DEPARTAMENTOS
DEFINE rm_p01	 	RECORD LIKE cxpt001.*	-- PROVEEDORES
DEFINE rm_t23	 	RECORD LIKE talt023.*	-- ORDENES DE TRABAJO
DEFINE rm_g13	 	RECORD LIKE gent013.*	-- MONEDAS
DEFINE rm_g14	 	RECORD LIKE gent014.*	-- CONVERSION MONEDAS
DEFINE rm_r02	 	RECORD LIKE rept002.*	-- BODEGA
DEFINE rm_b12	 	RECORD LIKE ctbt012.*

DEFINE rm_c00		RECORD LIKE ordt000.*	-- CONFIGURACION DE OC
DEFINE rm_c02		RECORD LIKE ordt002.*	-- PORCENTAJE DE RETENCIONES OC
DEFINE rm_p05		RECORD LIKE cxpt005.*	-- RETENCIONES CONF * PROVEEDOR
DEFINE rm_p27		RECORD LIKE cxpt027.*	-- RETENCIONES
DEFINE rm_p29		RECORD LIKE cxpt029.*
DEFINE vm_size_arr	INTEGER
DEFINE vm_size_arr2	INTEGER

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

CALL startlog('../logs/ordp202.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN 
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
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
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE done 		SMALLINT
DEFINE command_line	CHAR(70)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)

CALL fl_nivel_isolation()
LET vm_max_detalle  = 250
LET vm_estado       = 'P'
LET ind_max_ret     = 50

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
OPEN WINDOW w_202 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_202 FROM '../forms/ordf202_1'
ELSE
	OPEN FORM f_202 FROM '../forms/ordf202_1c'
END IF
DISPLAY FORM f_202

CALL control_DISPLAY_botones()

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr

LET vm_retencion = 'RT'

IF vg_num_recep IS NOT NULL THEN
	CALL execute_query()
END IF
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Retenciones'
		HIDE OPTION 'Contabilizacion'
		HIDE OPTION 'Grabar'
		HIDE OPTION 'Ver Orden'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		IF num_args() = 6 THEN
			SHOW OPTION 'Ver Orden'
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Contabilizacion'
			HIDE OPTION 'Recepción'
			IF rm_c10.c10_tipo_pago = 'C' THEN
				HIDE OPTION 'Forma de Pago'
			ELSE
				LET vm_flag_forma_pago = 'N'
				SHOW OPTION 'Forma de Pago'
			END IF
		END IF
		IF num_args() = 5 THEN
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Contabilizacion'
			HIDE OPTION 'Recepción'
			CALL fl_lee_orden_compra(vg_codcia, vg_codloc, 
						 vg_numero_oc)
				RETURNING rm_c10.*
			IF rm_c10.c10_numero_oc IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'La orden de compra no existe.','stop')
				CALL fl_mostrar_mensaje('La orden de compra no existe.','stop')
				EXIT PROGRAM
			END IF
			CALL control_cargar_rowid_recepcion()
			IF vm_num_recep = 0 THEN
				--CALL fgl_winmessage(vg_producto,'La orden de compra no tiene ninguna recepción.','stop')
				CALL fl_mostrar_mensaje('La orden de compra no tiene ninguna recepción.','stop')
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

	COMMAND KEY('A') 'Avanzar' 'Ver siguiente recepción.'
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

	COMMAND KEY('R') 'Retroceder' 'Ver anterior recepción.'
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

	COMMAND KEY('D') 'Ver Detalle' 'Ver Detalle de la Recepción.'
		CALL control_DISPLAY_array_ordt014()

	COMMAND KEY('I') 'Recepción' 'Recepción de Ordenes de Compra.'
		LET done = control_recepcion()
		IF done = 0 THEN
			HIDE OPTION 'Forma de Pago'
			HIDE OPTION 'Retenciones'
			HIDE OPTION 'Contabilizacion'
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
			HIDE OPTION 'Contabilizacion'
			HIDE OPTION 'Grabar'
			HIDE OPTION 'Ver Orden'
		END IF
		IF rm_c00.c00_cuando_ret = 'P' OR 
		   rm_c13.c13_numero_oc IS NULL 
		   THEN
			HIDE OPTION 'Retenciones'
			HIDE OPTION 'Contabilizacion'
		ELSE
			CALL control_cargar_retencion()
			SHOW OPTION 'Retenciones'
			SHOW OPTION 'Contabilizacion'
		END IF

	COMMAND KEY('O') 'Ver Orden' 'Ver la Orden de Compra.'
		IF rm_c13.c13_numero_oc IS NOT NULL THEN
			LET command_line = run_prog || 'ordp200 ' || vg_base
					|| ' ' || vg_modulo || ' ' || vg_codcia 
					    || ' ' || vg_codloc || ' ' ||
					    rm_c13.c13_numero_oc
			RUN command_line
		END IF

	COMMAND KEY('F') 'Forma de Pago'  'Forma de Pago de Ordenes de Compra.'
		IF vm_flag_forma_pago = 'N' THEN
			CALL control_DISPLAY_detalle_ordt015()
		ELSE
			CALL control_forma_pago()
		END IF

	COMMAND KEY('E') 'Retenciones'  'Retenciones de Ordenes de Compra.'
		IF num_args() = 4 THEN
			CALL control_retencion()
		ELSE
			CALL control_ver_retencion(rm_c10.c10_codprov)
		END IF

	COMMAND KEY('G') 'Grabar'  'Grabar Recepción.'
		LET done = control_grabar()
		IF done = 9 THEN
			CONTINUE MENU
		END IF
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Retenciones'
		HIDE OPTION 'Contabilizacion'
		HIDE OPTION 'Grabar'
		HIDE OPTION 'Ver Orden'
		IF NOT done THEN
			CLEAR FORM
			CALL control_DISPLAY_botones()
			ROLLBACK WORK
		END IF
			
	COMMAND KEY('C') 'Contabilizacion' 'Contabilizacion Recepción de Ordenes Compra.'
		CALL control_ver_contabilizacion()

	COMMAND KEY('S') 'Salir'  'Salir del Programa.'
		EXIT MENU

END MENU
		
END FUNCTION



FUNCTION control_ver_retencion(codprov)
DEFINE codprov 		LIKE cxpt001.p01_codprov
DEFINE numret 		LIKE cxpt027.p27_num_ret
DEFINE command_run 	VARCHAR(200)
DEFINE run_prog		CHAR(10)

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

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET command_run = 'cd ..', vg_separador, '..', vg_separador,
                  'TESORERIA', vg_separador, 'fuentes',
                   vg_separador, run_prog, 'cxpp304 ', vg_base,
                  ' ', 'TE', ' ', vg_codcia, ' ', vg_codloc, ' ', 
		   codprov, ' ', numret

RUN command_run

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



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'C Ped'		TO tit_col0
--#DISPLAY 'C Rec'		TO tit_col1
--#DISPLAY 'Código' 		TO tit_col2
--#DISPLAY 'Descripción'	TO tit_col3
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



FUNCTION control_DISPLAY_botones_3()

--#DISPLAY 'Descripción' TO bt_nom_ret
--#DISPLAY 'Tipo R.'     TO bt_tipo_ret
--#DISPLAY 'Valor Base'  TO bt_base 
--#DISPLAY '%'           TO bt_porc
--#DISPLAY 'Subtotal'    TO bt_valor

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
			rm_c13.c13_num_guia, rm_c13.c13_fecha_cadu,
			rm_c13.c13_estado,    rm_c13.c13_fecha_eli,
			rm_c13.c13_dif_cuadre, 
			rm_c13.c13_flete, rm_c13.c13_otros,
	      		rm_c13.c13_fec_aut, rm_c13.c13_num_aut,
			rm_c13.c13_serie_comp

IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF
CASE rm_c13.c13_estado
	WHEN 'E'
		DISPLAY 'ELIMINADA' TO tit_estado
	WHEN 'A'
		DISPLAY 'ACTIVA' TO tit_estado
END CASE

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr

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



FUNCTION control_DISPLAY_array_ordt014()
DEFINE i, j 	SMALLINT
	
LET INT_FLAG = 0
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



FUNCTION control_retencion()
DEFINE resp		CHAR(6)
DEFINE c		CHAR(1)
DEFINE salir,i,j	SMALLINT
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_c02		RECORD LIKE ordt002.*

OPEN WINDOW w_214_4 AT 4,9 WITH 20 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)		  
IF vg_gui = 1 THEN
	OPEN FORM f_214_4 FROM '../forms/ordf202_3'
ELSE
	OPEN FORM f_214_4 FROM '../forms/ordf202_3c'
END IF
DISPLAY FORM f_214_4

CALL control_DISPLAY_botones_3()

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
	--CALL fgl_winmessage(vg_producto,'No hay datos a mostrar.','exclamation')
	CALL fl_mostrar_mensaje('No hay datos a mostrar.','exclamation')
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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()

	BEFORE INPUT
		--#CALL dialog.keysetlabel('INSERT', '')
		--#CALL dialog.keysetlabel('DELETE', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")

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
				--CALL fgl_winmessage(vg_producto,'Valor base debe ser menor / igual que el valor de la O.C.','exclamation')
				CALL fl_mostrar_mensaje('Valor base debe ser menor / igual que el valor de la O.C.','exclamation')
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
			NEXT FIELD check
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



FUNCTION control_cargar_retencion()
DEFINE i 	SMALLINT
DEFINE r_c02	RECORD LIKE ordt002.*	-- PORCENTAJE DE RETENCIONES OC
DEFINE r_p05	RECORD LIKE cxpt005.*	-- RETENCIONES CONF * PROVEEDOR

LET val_impto  = rm_c13.c13_tot_impto
LET val_neto   = rm_c13.c13_tot_recep
LET val_pagar  = val_neto

LET tot_ret    = 0
LET ind_ret = 0

DECLARE q_ret CURSOR FOR
	SELECT * FROM ordt002, OUTER cxpt005
		WHERE c02_compania   = vg_codcia
	  	  AND p05_compania   = c02_compania
	  	  AND p05_codprov    = rm_c10.c10_codprov
	  	  AND p05_tipo_ret   = c02_tipo_ret
	  	  AND p05_porcentaje = c02_porcentaje 
	  	  AND c02_estado     <> 'B'

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

CLEAR FORM
CALL control_DISPLAY_botones()

INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*,vm_flag_forma_pago TO NULL
LET tot_ret = 0

LET rm_c13.c13_fecing  = fl_current()
LET rm_c13.c13_usuario = vg_usuario
LET rm_c13.c13_estado  = 'A'

DISPLAY 'ACTIVA' TO tit_estado 
DISPLAY BY NAME rm_c13.c13_fecing, rm_c13.c13_estado

CALL control_lee_cabecera()

BEGIN WORK
WHENEVER ERROR CONTINUE 
	DECLARE q_ordt010 CURSOR FOR 
		SELECT * FROM ordt010
			WHERE c10_compania  = vg_codcia	
			  AND c10_localidad = vg_codloc
			  AND c10_numero_oc = rm_c13.c13_numero_oc
		FOR UPDATE

OPEN q_ordt010 
FETCH q_ordt010 INTO rm_c10.*

IF STATUS < 0 THEN
	ROLLBACK WORK 
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	CALL fl_mostrar_mensaje('La orden de compra está siendo recibida por otro usuario.','exclamation')
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP

IF int_flag THEN
	ROLLBACK WORK 
	CLEAR FORM 
	CALL control_DISPLAY_botones()
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	RETURN 0
END IF

CALL control_cargar_detalle()

IF vm_ind_arr = 0 THEN
	ROLLBACK WORK 
	CLEAR FORM 
	CALL control_DISPLAY_botones()
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
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Orden de trabajo: ' ||
				    rm_c10.c10_ord_trabajo || ' no existe.',
				    'stop')
		EXIT PROGRAM
	END IF
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Orden de trabajo: ' ||
				    rm_c10.c10_ord_trabajo ||
				    ' está bloqueada por otro proceso.','stop')
		EXIT PROGRAM
	END IF
	IF rm_t23.t23_estado <> 'A' THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Estado de O.T. ' || 
			    	rm_c10.c10_ord_trabajo ||
			    	' no está activa.','stop')
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
	CALL control_DISPLAY_array_ordt014()
	LET INT_FLAG = 0
	RETURN 1

END IF

CALL control_lee_detalle_ordt014() 

IF int_flag THEN
	ROLLBACK WORK 
	CLEAR FORM
	CALL control_DISPLAY_botones()
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	RETURN 0
END IF

RETURN 1

END FUNCTION



FUNCTION control_grabar()
DEFINE done 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE estado  	 	LIKE ordt010.c10_estado
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

DEFINE fecha_actual DATETIME YEAR TO SECOND

--- PARA VALIDAR QUE GENERE LA FORMA DE PAGO CUANDO ES UNA RECEPCION PARCIAL ---

IF  rm_c10.c10_tipo_pago = 'R' AND vm_flag_forma_pago = 'S' THEN
	CALL fl_mostrar_mensaje('Debe generar la forma de pago.','exclamation')
	RETURN 9
END IF
-------------------------------------------------------------------------------

--- PARA VALIDAR QUE GENERE LA RETENCION DE LA ORDEN DE COMPRA ---

IF rm_c00.c00_cuando_ret = 'C' AND tot_ret = 0 THEN
	CALL fl_mostrar_mensaje('Debe ingresar las retenciones.','exclamation')
	RETURN 9
END IF
-----------------------------------------------------------------------

LET fecha_actual = fl_current()
IF vm_flag_recep = 'S' THEN
	CALL fl_hacer_pregunta('La orden de compra no ha sido recibida completamente desea recibir restante ?','No')
		RETURNING resp
	LET estado = 'P'
	IF resp = 'No' THEN
		LET estado = 'C'
	END IF

	UPDATE ordt010 SET c10_estado      = estado,
			   c10_factura     = rm_c13.c13_num_guia,
			   c10_fecha_fact  = vg_fecha,
			   c10_fecha_entre = fecha_actual	
		WHERE CURRENT OF q_ordt010 
ELSE
	UPDATE ordt010 SET c10_estado      = 'C',
			   c10_factura     = rm_c13.c13_num_guia,
			   c10_fecha_fact  = vg_fecha,
			   c10_fecha_entre = fecha_actual	
		WHERE CURRENT OF q_ordt010 
END IF

CALL control_insert_ordt013()
CALL control_insert_ordt014()
CALL control_update_ordt011()

IF rm_c10.c10_tipo_pago = 'R' THEN
	IF vm_flag_forma_pago = 'N' THEN
		CALL control_insert_ordt015_1()
	ELSE
		CALL control_insert_ordt015_2()
	END IF
END IF
IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF

-- SI la compra es al contado solo grabara un registro
CALL control_insert_cxpt020()

INITIALIZE rm_p27.* TO NULL
IF rm_c00.c00_cuando_ret = 'C' THEN
	LET done = graba_retenciones()
	-- SI done = 1 hubieron retenciones
	-- SI done = 0 no hubieron retenciones y no se hara ajuste
	INITIALIZE rm_p29.* TO NULL
	IF validar_num_sri(1) <> 1 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	CALL genera_num_ret_sri()
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

-- SI la compra local es al contado debe grabarse un ajuste
-- para darse de baja el documento
IF rm_c10.c10_tipo_pago = 'C' THEN
	CALL graba_ajuste_documento_contado()
END IF
IF vg_gui = 0 THEN
	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
END IF

CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_c10.c10_codprov)

--- ACTUALIZAR LA ORDEN DE TRABAJO ASOCIADA ---
IF rm_c10.c10_ord_trabajo IS NOT NULL THEN
	CALL actualiza_ot_x_oc()
END IF
--------------------------------------------------------------------------------

INITIALIZE r_b12.* TO NULL

CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*
IF rm_c10.c10_ord_trabajo IS NULL THEN
		IF (r_c01.c01_modulo <> 'AF' AND r_c01.c01_modulo <> 'CI') OR
		    r_c01.c01_modulo IS NULL
		THEN
			CALL contabilizacion_online() RETURNING r_b12.*
		ELSE
			IF r_c01.c01_modulo = 'AF' OR r_c01.c01_modulo = 'CI'
			THEN
				CALL contabilizacion_activo() RETURNING r_b12.*
			END IF
		END IF
		IF int_flag THEN
			RETURN 0
		END IF
END IF
COMMIT WORK
IF r_b12.b12_compania IS NOT NULL THEN
	LET run_prog = '; fglrun '
	IF vg_gui = 0 THEN
		LET run_prog = '; fglgo '
	END IF
	CALL fl_hacer_pregunta('Desea ver contabilizacion generada?','No')
		RETURNING resp
	IF resp = 'Yes' THEN
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      			'CONTABILIDAD', vg_separador, 'fuentes',
	      			vg_separador, run_prog, 'ctbp201 ',
				vg_base, ' ', 'CB', vg_codcia, ' ',
				r_b12.b12_tipo_comp, ' ', 
				r_b12.b12_num_comp
		RUN comando
	END IF
END IF
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
CALL fl_mostrar_mensaje('Proceso realizado Ok.','info')
	
CLEAR FORM
CALL control_DISPLAY_botones()

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
LET rm_p27.p27_fecing        = fl_current()

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
	LET r_p28.p28_tipo_ret   = r_ret[i].tipo_ret
	LET r_p28.p28_porcentaje = r_ret[i].porc
	LET r_p28.p28_valor_base = r_ret[i].val_base
	LET r_p28.p28_valor_ret  = r_ret[i].subtotal
	
	INSERT INTO cxpt028 VALUES(r_p28.*)
END FOR

RETURN done

END FUNCTION



FUNCTION validar_num_sri(validar)
DEFINE validar		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

CALL fl_validacion_num_sri(vg_codcia, vg_codloc, 'RT', 'N', rm_p29.p29_num_sri)
	RETURNING r_g37.*, rm_p29.p29_num_sri, flag
CASE flag
	WHEN -1
		RETURN -1
	WHEN 0
		RETURN  0
END CASE
IF validar = 1 THEN
	SELECT COUNT(*) INTO cont FROM cxpt029
		WHERE p29_compania  = vg_codcia
		  AND p29_localidad = vg_codloc
  		  AND p29_num_sri   = rm_p29.p29_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_p29.p29_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION genera_num_ret_sri()
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE cuantos		SMALLINT

WHENEVER ERROR CONTINUE
DECLARE q_sri CURSOR FOR
	SELECT * FROM gent037
		WHERE g37_compania   = vg_codcia
		  AND g37_localidad  = vg_codloc
		  AND g37_tipo_doc   = 'RT'
		  AND g37_secuencia IN
			(SELECT MAX(g37_secuencia)
				FROM gent037
				WHERE g37_compania  = vg_codcia
				  AND g37_localidad = vg_codloc
				  AND g37_tipo_doc  = 'RT')
		FOR UPDATE
OPEN q_sri
FETCH q_sri INTO r_g37.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
LET cuantos = 8 + r_g37.g37_num_dig_sri
LET sec_sri = rm_p29.p29_num_sri[9, cuantos] USING "########"
UPDATE gent037
	SET g37_sec_num_sri = sec_sri
	WHERE g37_compania     = r_g37.g37_compania
	  AND g37_localidad    = r_g37.g37_localidad
	  AND g37_tipo_doc     = r_g37.g37_tipo_doc
	  AND g37_secuencia    = r_g37.g37_secuencia
	  AND g37_sec_num_sri <= sec_sri
INSERT INTO cxpt029
	VALUES (vg_codcia, vg_codloc, rm_p27.p27_num_ret, rm_p29.p29_num_sri)
INSERT INTO cxpt032
	VALUES (vg_codcia, vg_codloc, rm_p27.p27_num_ret, r_g37.g37_tipo_doc,
		r_g37.g37_secuencia)

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

LET r_p22.p22_referencia = 'RET # ', rm_p27.p27_num_ret, ', RECEP # ', 
			   rm_c13.c13_num_recep, ', OC # ',
			   rm_c10.c10_numero_oc
LET r_p22.p22_fecha_emi  = vg_fecha
LET r_p22.p22_moneda     = rm_c10.c10_moneda
LET r_p22.p22_paridad    = rm_c10.c10_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = (val_neto - val_pagar) * (-1)
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'A'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = fl_current() 

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
LET r_p22.p22_fecha_emi  = vg_fecha
LET r_p22.p22_moneda     = rm_c10.c10_moneda
LET r_p22.p22_paridad    = rm_c10.c10_paridad
LET r_p22.p22_tasa_mora  = 0
LET r_p22.p22_total_cap  = (rm_c13.c13_tot_recep - tot_ret) * -1    --val_pagar
LET r_p22.p22_total_int  = 0
LET r_p22.p22_total_mora = 0
LET r_p22.p22_origen     = 'A'
LET r_p22.p22_usuario    = vg_usuario
LET r_p22.p22_fecing     = fl_current() + 1 UNITS SECOND

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
UPDATE cxpt020 SET p20_saldo_cap = 0
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
	CALL fl_mostrar_mensaje('No existe configuracion de secuencias para este tipo de transacción.','stop')
	EXIT PROGRAM
END IF

END WHILE

SET LOCK MODE TO NOT WAIT

RETURN retVal

END FUNCTION



FUNCTION control_DISPLAY_detalle_ordt015() 

OPEN WINDOW w_202_2 AT 6,8 WITH 16 ROWS, 71 COLUMNS
ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
	  BORDER, MESSAGE LINE LAST - 2) 
IF vg_gui = 1 THEN
	OPEN FORM f_202_2 FROM '../forms/ordf202_2'
ELSE
	OPEN FORM f_202_2 FROM '../forms/ordf202_2c'
END IF
DISPLAY FORM f_202_2

CALL control_DISPLAY_botones_2()

IF vm_flag_recep = 'N' THEN
	CALL control_cargar_ordt015_2()
ELSE
	CALL control_cargar_ordt015_1()
END IF

CALL control_DISPLAY_array_ordt015()

CLOSE WINDOW w_202_2

END FUNCTION



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
LET rm_c13.c13_fecing      = fl_current()
LET rm_c13.c13_fecha_recep = fl_current()
LET rm_c13.c13_factura     = rm_c13.c13_num_guia
LET rm_c13.c13_estado      = 'A'
LET rm_c13.c13_flete       = rm_c10.c10_flete
LET rm_c13.c13_otros       = rm_c10.c10_otros

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

CALL retorna_tam_arr2()
FOR k = 1 TO vm_size_arr2
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
DEFINE done, lim	SMALLINT
DEFINE r_c10	 	RECORD LIKE ordt010.*
DEFINE r_p20	 	RECORD LIKE cxpt020.*
DEFINE oc_ant		LIKE ordt010.c10_numero_oc

LET vm_calc_iva = 'S' 

LET int_flag = 0
INPUT BY NAME rm_c13.c13_numero_oc, rm_c13.c13_num_guia, rm_c13.c13_fecha_cadu,
	      rm_c13.c13_fec_aut, rm_c13.c13_num_aut, rm_c13.c13_serie_comp,
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

        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()

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
				IF vg_gui = 0 THEN
				     CALL muestra_tipopago(rm_c10.c10_tipo_pago)
				END IF
			END IF
		END IF

		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD c13_numero_oc
		LET oc_ant = rm_c13.c13_numero_oc
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

			IF r_c10.c10_estado = 'C' THEN
				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fl_mostrar_mensaje('La Orden de Compra está cerrada.','exclamation')
				NEXT FIELD c13_numero_oc
			END IF

			CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
				RETURNING rm_c01.*

			IF rm_c01.c01_ing_bodega = 'S' AND 
			   rm_c01.c01_modulo     = 'RE'
			   THEN
				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fl_mostrar_mensaje('La orden de compra pertenece a inventarios debe ser recibida por compra local.','exclamation')
                       		NEXT FIELD c13_numero_oc
			END IF 

			LET rm_c10.c10_tipo_pago = r_c10.c10_tipo_pago
			LET rm_c13.c13_interes   = r_c10.c10_interes
			DISPLAY BY NAME rm_c10.c10_tipo_pago
			IF vg_gui = 0 THEN
		        	CALL muestra_tipopago(rm_c10.c10_tipo_pago)
			END IF
			DISPLAY rm_p01.p01_nomprov TO nomprov
			IF oc_ant IS NULL OR oc_ant <> rm_c13.c13_numero_oc THEN
				LET rm_c13.c13_serie_comp = rm_p01.p01_serie_comp
				CALL retorna_num_aut()
				DISPLAY BY NAME rm_c13.c13_serie_comp
			END IF
			LET vm_moneda   = r_c10.c10_moneda
			LET vm_impuesto = r_c10.c10_porc_impto

			LET rm_c10.* = r_c10.* 
			DISPLAY rm_c10.c10_flete TO c13_flete
			DISPLAY rm_c10.c10_otros TO c13_otros
			CALL fl_lee_compania_orden_compra(vg_codcia)	
				RETURNING rm_c00.*

		ELSE
                       	NEXT FIELD c13_numero_oc
		END IF

	AFTER FIELD c13_num_guia
		IF LENGTH(rm_c13.c13_num_guia) < 14 THEN
			CALL fl_mostrar_mensaje('El número del documento ingresado es incorrecto.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF rm_c13.c13_num_guia[4, 4] <> '-' OR
		   rm_c13.c13_num_guia[8, 8] <> '-' THEN
			CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF LENGTH(rm_c13.c13_num_guia[1, 7]) <> 7 THEN
			CALL fl_mostrar_mensaje('Digite correctamente el punto de venta o el punto de emision.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		LET rm_c13.c13_serie_comp = rm_c13.c13_num_guia[1, 3],
						rm_c13.c13_num_guia[5, 7]
		DISPLAY BY NAME rm_c13.c13_serie_comp
		IF rm_c13.c13_num_guia[1, 3] <> rm_c13.c13_serie_comp[1, 3] THEN
			CALL fl_mostrar_mensaje('El prefijo del local es diferente que el de la serie del comprobante.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF rm_c13.c13_num_guia[5, 7] <> rm_c13.c13_serie_comp[4, 6] THEN
			CALL fl_mostrar_mensaje('El prefijo de venta es diferente que el de la serie del comprobante.', 'exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF NOT fl_valida_numeros(rm_c13.c13_num_guia[1, 3]) THEN
			NEXT FIELD c13_num_guia
		END IF
		IF NOT fl_valida_numeros(rm_c13.c13_num_guia[5, 7]) THEN
			NEXT FIELD c13_num_guia
		END IF
		LET lim = LENGTH(rm_c13.c13_num_guia)
		IF NOT fl_valida_numeros(rm_c13.c13_num_guia[9, lim]) THEN
			NEXT FIELD c13_num_guia
		END IF
		CALL retorna_num_aut()
	AFTER FIELD c13_fecha_cadu
		IF rm_c13.c13_fecha_cadu IS NOT NULL THEN
			DISPLAY BY NAME rm_c13.c13_fecha_cadu
		END IF

	AFTER FIELD c13_fec_aut
		IF rm_c13.c13_fec_aut IS NOT NULL THEN
			IF LENGTH(rm_c13.c13_fec_aut) <> 14 THEN
				CALL fl_mostrar_mensaje('Numero de Fecha de Autorizacion no tiene completo el total de digitos.', 'exclamation')
				NEXT FIELD c13_fec_aut
			END IF
			IF NOT fl_valida_numeros(rm_c13.c13_fec_aut) THEN
				NEXT FIELD c13_fec_aut
			END IF
		END IF

	AFTER FIELD c13_num_aut
		IF rm_c13.c13_num_aut IS NULL THEN
			CALL retorna_num_aut()
		END IF
		IF (LENGTH(rm_c13.c13_num_aut) <> 10 AND
			LENGTH(rm_c13.c13_num_aut) <> 37 AND
			LENGTH(rm_c13.c13_num_aut) <> 47 AND
			LENGTH(rm_c13.c13_num_aut) <> 49)
		THEN
			CALL fl_mostrar_mensaje('El número de autorización debe ser el número electrónico o bien el número específico de 10 digitos.', 'exclamation')
			NEXT FIELD c13_num_aut
		END IF
		IF NOT fl_valida_numeros(rm_c13.c13_num_aut) THEN
			NEXT FIELD c13_num_aut
		END IF

	AFTER FIELD c13_serie_comp
		IF rm_c13.c13_serie_comp IS NOT NULL THEN
			IF LENGTH(rm_c13.c13_serie_comp) <> 6 THEN
				CALL fl_mostrar_mensaje('Serie de Comprobante no tiene completo el numero de digitos.', 'exclamation')
				NEXT FIELD c13_serie_comp
			END IF
		END IF

	AFTER INPUT 
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, 
						 rm_c10.c10_codprov, 'FA',
						 rm_c13.c13_num_guia, 1)
			RETURNING r_p20.*
		IF r_p20.p20_num_doc IS NOT NULL THEN
			CALL fl_mostrar_mensaje('La factura ya ha sido recibida.','exclamation')
			NEXT FIELD c13_num_guia
		END IF
		IF rm_c13.c13_fecha_cadu IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la fecha de caducidad.', 'exclamation')
			NEXT FIELD c13_fecha_cadu
		END IF
		IF rm_c13.c13_fecha_cadu < vg_fecha THEN
			CALL fl_mostrar_mensaje('La fecha de caducidad no puede ser menor a la fecha de hoy.', 'exclamation')
			NEXT FIELD c13_fecha_cadu
		END IF

END INPUT

END FUNCTION



FUNCTION control_lee_detalle_ordt014()
DEFINE i,j,k,sum_oc, sum_recep	SMALLINT
DEFINE resp			CHAR(6)

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F40

CALL retorna_tam_arr()
LET vm_filas_pant  = vm_size_arr
LET rm_c13.c13_tot_recep = 0
LET i = 1
LET j = 1

WHILE TRUE

	CALL set_count(vm_ind_arr)

	LET int_flag = 0

	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		
		BEFORE INPUT 
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")

		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
       	        		RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()

		BEFORE ROW
			LET i = arr_curr()   # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()   # POSICION CORRIENTE EN LA PANTALLA
			CALL calcula_totales()

		BEFORE INSERT	
			EXIT INPUT
	
		AFTER FIELD c14_cantidad
			LET r_detalle[i].c14_cantidad = r_detalle[i].c11_cant_ped 	
			DISPLAY r_detalle[i].c14_cantidad TO
				r_detalle[j].c14_cantidad   
			IF r_detalle[i].c14_cantidad IS NOT NULL THEN
				IF r_detalle[i].c14_cantidad > 
				   r_detalle[i].c11_cant_ped 	
				   THEN
					CALL fl_mostrar_mensaje('La cantidad recibida debe ser menor o igual a la pedida.','exclamation')
					NEXT FIELD c14_cantidad		
				END IF
				CALL calcula_totales()
			ELSE
				LET r_detalle[i].c14_cantidad = 0
				DISPLAY r_detalle[i].c14_cantidad TO
					r_detalle[j].c14_cantidad
			END IF	

		AFTER INPUT
			IF rm_c13.c13_tot_recep = 0 THEN
				CONTINUE INPUT
			END IF

			LET vm_flag_forma_pago = 'N'
			LET vm_flag_recep      = 'N'
			LET sum_oc    = 0
			LET sum_recep = 0

			FOR k = 1 TO vm_ind_arr

				LET sum_recep = sum_recep + 
					        r_detalle[k].c14_cantidad

			END FOR
			LET sum_oc    = control_cargar_cant_oc()
			IF sum_oc <> sum_recep  THEN
				LET vm_flag_forma_pago = 'S'
			END IF
			LET sum_recep = sum_recep + control_cargar_cant_recep()
			IF sum_oc <> sum_recep  THEN
				LET vm_flag_recep      = 'S'
			END IF

			EXIT WHILE
		
	END INPUT

END WHILE

END FUNCTION



FUNCTION control_cargar_cant_oc()
DEFINE r_c11		RECORD LIKE ordt011.*

SELECT c11_numero_oc, SUM(c11_cant_ped)
	INTO r_c11.c11_numero_oc, r_c11.c11_cant_ped
	FROM ordt010, ordt011
	WHERE c10_compania  = vg_codcia
	  AND c10_localidad = vg_codloc
	  AND c10_numero_oc = rm_c13.c13_numero_oc
	  AND c11_compania  = c10_compania
	  AND c11_localidad = c10_localidad
	  AND c11_numero_oc = c10_numero_oc
GROUP BY c11_numero_oc
                             
RETURN r_c11.c11_cant_ped

END FUNCTION



FUNCTION control_cargar_cant_recep()
DEFINE num_oc		LIKE ordt011.c11_numero_oc
DEFINE r_c14		RECORD LIKE ordt014.*

SELECT c14_numero_oc, SUM(c14_cantidad)
	INTO r_c14.c14_numero_oc, r_c14.c14_cantidad
	FROM ordt013, ordt014
	WHERE c13_estado    <> 'E' 
          AND c13_compania  = vg_codcia
	  AND c13_localidad = vg_codloc
	  AND c13_numero_oc = rm_c13.c13_numero_oc
	  AND c14_compania  = vg_codcia
	  AND c14_localidad = vg_codloc
	  AND c14_numero_oc = rm_c13.c13_numero_oc
	  AND c14_num_recep = c13_num_recep
GROUP BY c14_numero_oc

IF r_c14.c14_cantidad IS NULL THEN
	RETURN 0
END IF
                             
RETURN r_c14.c14_cantidad

END FUNCTION



FUNCTION calcula_totales()
DEFINE k 		SMALLINT
DEFINE v_impto		LIKE ordt013.c13_tot_impto

LET rm_c13.c13_tot_bruto   = 0	
LET rm_c13.c13_tot_dscto   = 0	
LET rm_c13.c13_tot_impto   = 0	
LET rm_c13.c13_tot_recep   = 0	
LET rm_c13.c13_dif_cuadre  = rm_c10.c10_dif_cuadre
LET rm_c13.c13_flete       = rm_c10.c10_flete
LET rm_c13.c13_otros       = rm_c10.c10_otros
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
IF val_bienes > 0 THEN
	LET val_bienes = val_bienes + rm_c13.c13_otros
ELSE
	IF val_servi > 0 THEN
		LET val_servi = val_servi + rm_c13.c13_otros
	END IF
END IF
IF vm_calc_iva = 'S' THEN
	LET rm_c13.c13_tot_impto = (rm_c13.c13_tot_bruto - rm_c13.c13_tot_dscto + 
	            		    rm_c13.c13_otros ) * (vm_impuesto / 100)
	LET rm_c13.c13_tot_impto = fl_retorna_precision_valor(vm_moneda, rm_c13.c13_tot_impto)
	LET iva_bien  = val_bienes * vm_impuesto / 100
	LET iva_bien  = fl_retorna_precision_valor(vm_moneda, iva_bien)
	LET iva_servi = val_servi * vm_impuesto / 100
	LET iva_servi = fl_retorna_precision_valor(vm_moneda, iva_servi)
END IF
LET rm_c13.c13_tot_recep = rm_c13.c13_tot_bruto - rm_c13.c13_tot_dscto +
			   rm_c13.c13_tot_impto	+ rm_c13.c13_flete +
			   rm_c13.c13_otros     

DISPLAY BY NAME rm_c13.c13_tot_dscto, rm_c13.c13_tot_bruto, 
		rm_c13.c13_tot_impto, rm_c13.c13_tot_recep,
		rm_c13.c13_dif_cuadre

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(400)
DEFINE r_c11		RECORD LIKE ordt011.*

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
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
	
	IF r_c11.c11_cant_ped - r_c11.c11_cant_rec > 0 
	   THEN
		LET r_detalle[i].c11_cant_ped  = r_c11.c11_cant_ped - 
	 					 r_c11.c11_cant_rec
		LET r_detalle[i].c14_cantidad  = r_detalle[i].c11_cant_ped
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
			CALL fl_mostrar_mensaje('La cantidad de elementos del detalle supero la cantidad de elementos del arreglo','stop')
			EXIT PROGRAM
		END IF	
	END IF	

END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mostrar_mensaje('No hay elementos del detalle que recibir.','exclamation')
END IF

LET vm_ind_arr = i

END FUNCTION



FUNCTION control_forma_pago()
DEFINE i 	SMALLINT

OPEN WINDOW w_202_2 AT 6,8 WITH 16 ROWS, 71 COLUMNS
	ATTRIBUTE(FORM LINE FIRST , COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
IF vg_gui = 1 THEN
	OPEN FORM f_202_2 FROM '../forms/ordf202_2'
ELSE
	OPEN FORM f_202_2 FROM '../forms/ordf202_2c'
END IF
DISPLAY FORM f_202_2

CALL control_DISPLAY_botones_2()

IF pagos = 0 THEN
	LET tot_recep  = rm_c13.c13_tot_recep
	LET fecha_pago = vg_fecha + 30
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
	CALL control_DISPLAY_array_ordt015()
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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD fecha_pago
		IF fecha_pago < vg_fecha THEN
			CALL fl_mostrar_mensaje('Debe ingresar una fecha mayor o igual a la de hoy.','exclamation')
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
			CALL fl_mostrar_mensaje('Debe ingresar el número de pagos para generar el detalle.','exclamation')
			NEXT FIELD pagos
		END IF
			
		IF fecha_pago IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar la fecha del primer pago de la orden de compra.','exclamation')
			NEXT FIELD fecha_pago
		END IF

		IF dias_pagos IS NULL THEN
			CALL fl_mostrar_mensaje('Debe ingresar el número de días entre pagos para generar el detalle.','exclamation')
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
			--#CALL dialog.keysetlabel ('INSERT','')
			--#CALL dialog.keysetlabel ('DELETE','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")

		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1 
				RETURN	
			END IF
			CONTINUE INPUT

        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
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
					CALL fl_mostrar_mensaje('Existen fechas que resultan menores a las ingresadas anteriormente en los pagos.','exclamation')
					EXIT INPUT
				END IF
			END FOR	

			IF tot_cap > tot_recep THEN
				CALL fl_mostrar_mensaje('El total del valor capital es mayor al total de la deuda.','exclamation')
				EXIT INPUT
			END IF

			IF tot_cap < tot_recep THEN
				CALL fl_mostrar_mensaje('El total del valor capital es menor al total de la deuda.','exclamation')
				EXIT INPUT
			END IF

			LET tot_dias = r_detalle_2[pagos].c15_fecha_vcto - vg_fecha 	
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

	CALL retorna_tam_arr()
	LET vm_filas_pant = vm_size_arr2

	IF pagos < vm_filas_pant THEN
		LET vm_filas_pant = pagos
	END IF 

	FOR i = 1 TO vm_filas_pant
		DISPLAY r_detalle_2[i].* TO r_detalle_2[i].*
	END FOR

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

INITIALIZE r_p20.* TO NULL
LET r_p20.p20_compania    = vg_codcia
LET r_p20.p20_localidad   = vg_codloc
LET r_p20.p20_codprov     = rm_c10.c10_codprov
LET r_p20.p20_usuario     = vg_usuario
LET r_p20.p20_fecing      = fl_current()
LET r_p20.p20_fecha_emi	  = vg_fecha
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
	LET r_p20.p20_fecha_vcto = vg_fecha
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
	SELECT c11_tipo, (c11_cant_ped * c11_precio) - c11_val_descto
		FROM ordt011
		WHERE c11_compania  = rm_c10.c10_compania  AND 
		      c11_localidad = rm_c10.c10_localidad AND 
		      c11_numero_oc = rm_c10.c10_numero_oc
LET tot_rep = 0
LET tot_mo  = 0
FOREACH q_detoc INTO tipo, valor
	LET valor = valor + (valor * rm_c10.c10_recargo / 100)
	LET valor = fl_retorna_precision_valor(rm_c10.c10_moneda, valor)
	IF tipo = 'B' THEN
		LET tot_rep = tot_rep + valor
	ELSE
		LET tot_mo  = tot_mo  + valor
	END IF
END FOREACH
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
DEFINE resp		VARCHAR(10)
DEFINE retenciones	SMALLINT
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

SELECT COUNT(*) INTO retenciones FROM cxpt028
	WHERE p28_compania  = rm_p27.p27_compania
	  AND p28_localidad = rm_p27.p27_localidad
	  AND p28_num_ret   = rm_p27.p27_num_ret

IF retenciones = 0 THEN
	RETURN
END IF

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
CALL fl_hacer_pregunta('Desea imprimir comprobante de retencion?','No')
	RETURNING resp
IF resp = 'Yes' THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador,
		      'TESORERIA', vg_separador, 'fuentes', 
		      vg_separador, run_prog, 'cxpp405 ', vg_base, ' ',
		      'TE', vg_codcia, ' ', vg_codloc,
		      ' ', rm_p27.p27_num_ret    

	RUN comando
END IF

END FUNCTION



FUNCTION contabilizacion_online()
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p00		RECORD LIKE cxpt000.*
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

DEFINE i, j, l, col	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE salir		SMALLINT
DEFINE impto		LIKE ordt013.c13_tot_impto
DEFINE retenciones	LIKE cxpt027.p27_total_ret 
DEFINE cuenta_cxp	LIKE ctbt010.b10_cuenta
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

OPEN WINDOW w_202_4 AT 8, 2 WITH 14 ROWS, 78 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_202_4 FROM "../forms/ordf202_4"
ELSE
	OPEN FORM f_202_4 FROM "../forms/ordf202_4c"
END IF
DISPLAY FORM f_202_4

--#DISPLAY 'Cuenta' 		TO bt_cuenta
--#DISPLAY 'Descripción'	TO bt_descripcion
--#DISPLAY 'Débito'		TO bt_valor_db
--#DISPLAY 'Crédito'		TO bt_valor_cr

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc) 
	RETURNING r_c10.*

CALL fl_lee_auxiliares_generales(vg_codcia, vg_codloc) RETURNING r_b42.*
IF r_b42.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado auxiliares contables para IVA.','exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_c10.c10_codprov)
	RETURNING r_p02.*
IF r_p02.p02_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado auxiliares contables para este proveedor.','exclamation')
	LET int_flag = 1
	CLOSE WINDOW w_202_4
	RETURN r_b12.*
END IF

LET impto = rm_c13.c13_tot_impto

IF impto IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha realizado ninguna recepción.','exclamation')
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

IF cuenta_cxp IS NULL THEN
	CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_p00.*
	IF r_p00.p00_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe una compañía configurada en Tesorería.','exclamation')
		LET int_flag = 1
		CLOSE WINDOW w_202_4
		RETURN r_b12.*
	END IF
	IF rm_c10.c10_moneda = rg_gen.g00_moneda_base THEN
		LET cuenta_cxp = r_p00.p00_aux_prov_mb
	ELSE
		LET cuenta_cxp = r_p00.p00_aux_prov_ma
	END IF
END IF
CALL inserta_tabla_temporal(cuenta_cxp, 0, rm_c13.c13_tot_recep, 'F') 
	RETURNING tot_debito, tot_credito

LET retenciones = 0
FOREACH q_p28 INTO r_p28.*
	CALL fl_lee_tipo_retencion(vg_codcia, r_p28.p28_tipo_ret, 
		r_p28.p28_porcentaje) RETURNING r_c02.*
	CALL inserta_tabla_temporal(r_c02.c02_aux_cont, 0, r_p28.p28_valor_ret,
		'F') RETURNING tot_debito, tot_credito
	LET retenciones = retenciones + r_p28.p28_valor_ret
END FOREACH

IF retenciones > 0 THEN
	UPDATE tmp_cuenta SET te_valor_cr = te_valor_cr - retenciones
		WHERE te_cuenta = cuenta_cxp
END IF
IF rm_c01.c01_aux_cont IS NOT NULL THEN 
	LET r_b42.b42_iva_compra = rm_c01.c01_aux_cont
END IF
CALL inserta_tabla_temporal(r_b42.b42_iva_compra, impto, 0, 'F')
	RETURNING tot_debito, tot_credito

INITIALIZE rm_b12.* TO NULL
LET rm_b12.b12_glosa = 'COMPROBANTE: ', rm_p01.p01_nomprov[1,25], ' ',
			rm_c13.c13_factura
LET salir = 0
WHILE NOT salir
	LET int_flag = 0
	INPUT BY NAME rm_b12.b12_glosa
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END INPUT
	IF int_flag THEN
		CLOSE WINDOW w_202_4
		RETURN r_b12.*
	END IF
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
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F2)
			IF INFIELD(b13_cuenta) AND modificable(r_ctas[i].cuenta)
			THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia, -1) 
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
		ON KEY(F5)
			LET int_flag = 0
			EXIT INPUT
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
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		BEFORE DELETE
			IF NOT modificable(r_ctas[i].cuenta) THEN
				EXIT INPUT    
			END IF
			DELETE FROM tmp_cuenta 
				WHERE te_cuenta = r_ctas[i].cuenta
			LET tot_debito  = tot_debito  - r_ctas[i].valor_db
			LET tot_credito = tot_credito - r_ctas[i].valor_cr
			DISPLAY BY NAME tot_debito, tot_credito
		BEFORE FIELD b13_cuenta
			LET cuenta = r_ctas[i].cuenta
		AFTER FIELD b13_cuenta
			IF r_ctas[i].cuenta IS NULL AND modificable(cuenta)
			THEN
				IF cuenta IS NOT NULL THEN
					DELETE FROM tmp_cuenta
						WHERE te_cuenta = cuenta
				END IF
				CONTINUE INPUT
			END IF
			IF (r_ctas[i].cuenta IS NULL 
			 OR cuenta <> r_ctas[i].cuenta) 
			AND NOT modificable(cuenta) 
			THEN
				CALL fl_mostrar_mensaje('No puede modificar esta cuenta.','exclamation')
				LET r_ctas[i].cuenta = cuenta
				DISPLAY r_ctas[i].cuenta TO r_ctas[j].b13_cuenta
				CONTINUE INPUT
			END IF
			IF (cuenta IS NULL OR cuenta <> r_ctas[i].cuenta) 
			AND NOT modificable(r_ctas[i].cuenta) 
			THEN
				CALL fl_mostrar_mensaje('No puede volver a ingresar esta cuenta.','exclamation')
				LET r_ctas[i].cuenta = ' '
				NEXT FIELD b13_cuenta
			END IF
			CALL fl_lee_cuenta(vg_codcia, r_ctas[i].cuenta) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fl_mostrar_mensaje('No existe cuenta contable.','exclamation')
				NEXT FIELD b13_cuenta
			END IF
			IF r_b10.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD b13_cuenta
			END IF
			IF cuenta IS NOT NULL THEN
				DELETE FROM tmp_cuenta
					WHERE te_cuenta = cuenta
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
			END IF
		AFTER INPUT
			IF tot_debito IS NULL THEN
				CALL fl_mostrar_mensaje('No hay lineas de detalle para el débito.','exclamation')
				CONTINUE INPUT
			END IF
			IF tot_credito IS NULL THEN
				CALL fl_mostrar_mensaje('No hay lineas de detalle para el crédito.','exclamation')
				CONTINUE INPUT
			END IF
			LET tot_debito  = 0
			LET tot_credito = 0
			FOR l = 1 TO arr_count()
				IF r_ctas[l].valor_db IS NOT NULL THEN
					LET tot_debito  = tot_debito  +
							r_ctas[l].valor_db
				END IF
				IF r_ctas[l].valor_cr IS NOT NULL THEN
					LET tot_credito = tot_credito +
							r_ctas[l].valor_cr
				END IF
			END FOR
			DISPLAY BY NAME tot_debito, tot_credito
			IF tot_debito <> tot_credito THEN
				CALL fl_mostrar_mensaje('Los valores en el débito y el crédito deben ser iguales.','exclamation')
				CONTINUE INPUT
			END IF
			IF tot_debito > rm_c13.c13_tot_recep THEN
				CALL fl_mostrar_mensaje('Los valores en el débito y el crédito deben ser iguales al total de la recepción.','exclamation')
				CONTINUE INPUT
			END IF
			IF tot_debito = 0 THEN
				CALL fl_mostrar_mensaje('No puede generar un Diario Contable con totales de CERO para el Débito y el Crédito.','exclamation')
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



FUNCTION contabilizacion_activo()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c11		RECORD LIKE ordt011.*
DEFINE r_p00		RECORD LIKE cxpt000.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE cuenta_cxp	LIKE ctbt010.b10_cuenta
DEFINE cta_iva		LIKE ctbt010.b10_cuenta
DEFINE depre_mb		LIKE actt010.a10_val_dep_mb
DEFINE depre_ma		LIKE actt010.a10_val_dep_ma
DEFINE valor_bien	DECIMAL(14,2)
DEFINE valor		DECIMAL(14,2)
DEFINE i		SMALLINT

LET int_flag = 0
INITIALIZE r_b12.*, cuenta_cxp TO NULL
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING r_c10.*
CALL fl_lee_auxiliares_generales(vg_codcia, vg_codloc) RETURNING r_b42.*
IF r_b42.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado auxiliares contables para Activos.','exclamation')
	RETURN r_b12.*
END IF
CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden) RETURNING r_c01.*
LET cta_iva = r_c01.c01_aux_cont
IF r_c01.c01_aux_cont IS NULL THEN
	LET cta_iva = r_b42.b42_iva_compra
END IF
CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, r_c10.c10_codprov)
	RETURNING r_p02.*
IF r_p02.p02_codprov IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado auxiliares contables para este proveedor.','exclamation')
	RETURN r_b12.*
END IF
IF r_c10.c10_moneda = rg_gen.g00_moneda_base THEN
	LET cuenta_cxp = r_p02.p02_aux_prov_mb
ELSE
	LET cuenta_cxp = r_p02.p02_aux_prov_ma
END IF
IF cuenta_cxp IS NULL THEN
	CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_p00.*
	IF r_p00.p00_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe una compañía configurada en Tesorería.','exclamation')
		RETURN r_b12.*
	END IF
	IF r_c10.c10_moneda = rg_gen.g00_moneda_base THEN
		LET cuenta_cxp = r_p00.p00_aux_prov_mb
	ELSE
		LET cuenta_cxp = r_p00.p00_aux_prov_ma
	END IF
END IF
LET r_b12.b12_compania    = vg_codcia
LET r_b12.b12_tipo_comp   = 'DC'
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
                            	r_b12.b12_tipo_comp, YEAR(vg_fecha), MONTH(vg_fecha))
LET r_b12.b12_estado      = 'A'
IF r_c01.c01_modulo = 'AF' THEN
	LET r_b12.b12_subtipo = 60
END IF
CALL fl_lee_proveedor(r_c10.c10_codprov) RETURNING r_p01.*
LET r_b12.b12_glosa       = r_p01.p01_nomprov CLIPPED, ' ORDEN DE COMPRA ',
				rm_c13.c13_numero_oc USING "<<<<<<<<<&"
LET r_b12.b12_benef_che   = NULL
LET r_b12.b12_num_cheque  = NULL
LET r_b12.b12_origen      = 'A'
LET r_b12.b12_moneda      = r_c10.c10_moneda
LET r_b12.b12_paridad     = r_c10.c10_paridad
LET r_b12.b12_fec_proceso = vg_fecha
LET r_b12.b12_fec_reversa = NULL
LET r_b12.b12_tip_reversa = NULL
LET r_b12.b12_num_reversa = NULL
LET r_b12.b12_fec_modifi  = NULL
LET r_b12.b12_modulo      = r_c01.c01_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = fl_current()
INSERT INTO ctbt012 VALUES(r_b12.*)
DECLARE q_c11 CURSOR FOR
	SELECT * FROM ordt011
		WHERE c11_compania  = r_c10.c10_compania
		  AND c11_localidad = r_c10.c10_localidad
		  AND c11_numero_oc = r_c10.c10_numero_oc
LET i = 1
FOREACH q_c11 INTO r_c11.*
	IF r_c01.c01_modulo = 'AF' THEN
		CALL fl_lee_codigo_bien(r_c11.c11_compania, r_c11.c11_codigo)
			RETURNING r_a10.*
		IF r_a10.a10_estado = 'S' OR r_a10.a10_val_dep_mb > 0 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('El Activo ya esta CON STOCK y no puede volverse a ingresar en la compañía.', 'stop')
			EXIT PROGRAM
		END IF
		LET valor_bien = r_c11.c11_precio - r_c11.c11_val_descto
		LET depre_mb   = ((valor_bien * r_a10.a10_porc_deprec) / 100)
					 / 12
		LET depre_ma   = 0
		IF r_c10.c10_moneda <> rg_gen.g00_moneda_base THEN
			LET depre_ma = depre_mb 
			LET depre_mb = depre_mb * r_c10.c10_paridad
		END IF
		UPDATE actt010 SET a10_estado     = 'S',
				   a10_numero_oc  = r_c11.c11_numero_oc,
				   a10_codprov    = r_c10.c10_codprov,
				   a10_fecha_comp = r_c10.c10_fecha_fact,
				   a10_moneda     = r_c10.c10_moneda,
				   a10_paridad    = r_c10.c10_paridad,
				   a10_valor      = valor_bien,
				   a10_valor_mb   = (valor_bien	*
							 r_c10.c10_paridad),
				   a10_val_dep_mb = depre_mb,
				   a10_val_dep_ma = depre_ma
			WHERE a10_compania    = r_c11.c11_compania
			  AND a10_codigo_bien = r_c11.c11_codigo
		CALL fl_lee_codigo_bien(r_c11.c11_compania, r_c11.c11_codigo)
			RETURNING r_a10.*
		CALL fl_lee_grupo_activo(r_a10.a10_compania,r_a10.a10_grupo_act)
			RETURNING r_a01.*
		IF r_a01.a01_aux_activo IS NULL THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No existe auxiliar contable para el codigo ' || r_c11.c11_codigo USING "<<<<<<<<<&" || '.', 'stop')
			EXIT PROGRAM
		END IF
	END IF
	LET valor = r_c11.c11_precio - r_c11.c11_val_descto
	IF r_c01.c01_modulo = 'AF' THEN
		CALL grabar_detalle_cont(r_b12.*, r_a01.a01_aux_activo, valor,i)
	END IF
	IF r_c01.c01_modulo = 'CI' THEN
		CALL grabar_detalle_cont(r_b12.*, r_c01.c01_aux_ot_proc,valor,i)
	END IF
	LET i = i + 1
END FOREACH
CALL grabar_detalle_cont(r_b12.*, cta_iva, r_c10.c10_tot_impto, i)
LET valor = r_c10.c10_tot_compra * (-1)
CALL grabar_detalle_cont(r_b12.*, cuenta_cxp, valor, i + 1)
CALL grabar_conf_cont_compras(r_b12.b12_tipo_comp, r_b12.b12_num_comp)
IF r_c01.c01_modulo = 'CI' THEN
	RETURN r_b12.*
END IF
FOREACH q_c11 INTO r_c11.*
	INITIALIZE r_a12.* TO NULL
	LET r_a12.a12_compania 	  = vg_codcia
	LET r_a12.a12_codigo_tran = 'IN'
	LET r_a12.a12_numero_tran = fl_retorna_num_tran_activo(vg_codcia, 
							  r_a12.a12_codigo_tran)
	IF r_a12.a12_numero_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_a12.a12_codigo_bien = r_c11.c11_codigo
	LET r_a12.a12_referencia  = r_b12.b12_glosa
	CALL fl_lee_codigo_bien(r_c11.c11_compania, r_c11.c11_codigo)
		RETURNING r_a10.*
	LET r_a12.a12_locali_ori  = r_a10.a10_localidad
	LET r_a12.a12_depto_ori   = r_a10.a10_cod_depto
	LET r_a12.a12_porc_deprec = r_a10.a10_porc_deprec
	LET r_a12.a12_valor_mb 	  = r_c11.c11_precio- r_c11.c11_val_descto
	LET r_a12.a12_valor_ma 	  = 0
	LET r_a12.a12_tipcomp_gen = r_b12.b12_tipo_comp
	LET r_a12.a12_numcomp_gen = r_b12.b12_num_comp
	LET r_a12.a12_usuario 	  = vg_usuario
	LET r_a12.a12_fecing 	  = fl_current()
	INSERT INTO actt012 VALUES (r_a12.*)
END FOREACH
RETURN r_b12.*

END FUNCTION



FUNCTION grabar_detalle_cont(r_b12, cuenta, valor, i)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		DECIMAL(14,2)
DEFINE i		SMALLINT
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p02		RECORD LIKE cxpt002.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = i
LET r_b13.b13_tipo_doc    = NULL
LET r_b13.b13_cuenta      = cuenta
CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING r_c10.*
LET r_b13.b13_glosa  = 'PROV. # ', r_c10.c10_codprov
			USING "<<<<&", ' OC # ',
			r_c10.c10_numero_oc USING "<<<<<<<<<&"
CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, r_c10.c10_codprov)
	RETURNING r_p02.*
IF cuenta = r_p02.p02_aux_prov_mb THEN
	LET r_b13.b13_glosa  = 'COMPRA FACT # ',
				rm_c13.c13_num_guia CLIPPED,
				' OC # ', r_c10.c10_numero_oc USING "<<<<<<<<<&"
END IF
IF r_c10.c10_moneda = rg_gen.g00_moneda_base THEN
	LET r_b13.b13_valor_base  = valor
	LET r_b13.b13_valor_aux   = 0
ELSE
	LET r_b13.b13_valor_base  = valor * r_c10.c10_paridad
	LET r_b13.b13_valor_aux   = valor
END IF
LET r_b13.b13_num_concil  = NULL
LET r_b13.b13_filtro      = NULL
LET r_b13.b13_fec_proceso = vg_fecha
LET r_b13.b13_codcli      = NULL
LET r_b13.b13_codprov     = r_c10.c10_codprov
LET r_b13.b13_pedido      = NULL
INSERT INTO ctbt013 VALUES(r_b13.*)

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
DEFINE r_p02		RECORD LIKE cxpt002.*

DEFINE cuenta 		LIKE ctbt010.b10_cuenta
DEFINE glosa, glosa1	LIKE ctbt013.b13_glosa
DEFINE query		CHAR(500)
DEFINE expr_valor	VARCHAR(100)

INITIALIZE r_b12.* TO NULL
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING r_b00.*

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, rm_c13.c13_numero_oc)
	RETURNING r_c10.*

CALL fl_lee_tipo_comprobante_contable(vg_codcia, 'DO') RETURNING r_b03.*
IF r_b03.b03_compania IS NULL THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe tipo de comprobante para Diario de Compras: DO.','exclamation')
	EXIT PROGRAM
END IF
LET glosa = 'OC # ', rm_c13.c13_numero_oc USING "<<<<<<<&", ' RECEPCION # ',
		rm_c13.c13_num_recep USING "<<<<<<<&"
INITIALIZE r_b12.* TO NULL
LET r_b12.b12_compania    = vg_codcia  
LET r_b12.b12_tipo_comp   = r_b03.b03_tipo_comp
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
                            	r_b12.b12_tipo_comp, YEAR(vg_fecha), MONTH(vg_fecha))
LET r_b12.b12_estado      = 'A' 
LET r_b12.b12_glosa       = rm_b12.b12_glosa CLIPPED
LET r_b12.b12_origen      = 'A' 
LET r_b12.b12_moneda      = r_c10.c10_moneda 
LET r_b12.b12_paridad     = r_c10.c10_paridad 
LET r_b12.b12_fec_proceso = vg_fecha
LET r_b12.b12_modulo      = r_b03.b03_modulo
LET r_b12.b12_usuario     = vg_usuario 
LET r_b12.b12_fecing      = fl_current()

INSERT INTO ctbt012 VALUES(r_b12.*)

IF r_b12.b12_moneda = r_b00.b00_moneda_base THEN
	LET expr_valor = ' (te_valor_cr * (-1)), 0 '
ELSE
	LET expr_valor = ' (te_valor_cr * (-1) * ', r_b12.b12_paridad, 
			 '), (te_valor_cr * (-1))'
END IF

CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, r_c10.c10_codprov)
	RETURNING r_p02.*
LET cuenta = NULL
DECLARE q_cta CURSOR FOR
	SELECT UNIQUE te_cuenta
		FROM tmp_cuenta
		WHERE te_cuenta = r_p02.p02_aux_prov_mb
OPEN q_cta
FETCH q_cta INTO cuenta
CLOSE q_cta
FREE q_cta
LET glosa1 = NULL
IF cuenta IS NOT NULL THEN
	LET glosa1  = 'COMPRA FACT # ', rm_c13.c13_num_guia CLIPPED,
			' OC # ', r_c10.c10_numero_oc USING "<<<<<<<<<&"
END IF
LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_num_concil, b13_fec_proceso, b13_codprov) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
			' CASE WHEN te_cuenta = "', cuenta CLIPPED, '"',
				' THEN "', glosa1 CLIPPED, '"',
				' ELSE "', glosa CLIPPED, '"',
			' END, ',
	    		expr_valor CLIPPED, ', 0,', 
	    ' 		DATE("', r_b12.b12_fec_proceso, '"),',
		        rm_c10.c10_codprov,
	    '		FROM tmp_cuenta ', 
	    '		WHERE te_valor_cr > 0 '
PREPARE stmnt3 FROM query
EXECUTE stmnt3

IF r_b12.b12_moneda = r_b00.b00_moneda_base THEN
	LET expr_valor = ' te_valor_db, 0 '
ELSE
	LET expr_valor = ' (te_valor_db * ', r_b12.b12_paridad, 
			 '), te_valor_db'
END IF

LET query = 'INSERT INTO ctbt013 (b13_compania, b13_tipo_comp, b13_num_comp, ',
	    '			  b13_secuencia, b13_cuenta, ',
	    '			  b13_glosa, b13_valor_base, b13_valor_aux, ',
	    '			  b13_num_concil, b13_fec_proceso,b13_codprov) ', 
	    '	SELECT ', vg_codcia, ', "', r_b12.b12_tipo_comp , '", "',
	    		r_b12.b12_num_comp CLIPPED, '", te_serial, te_cuenta, ',
			' CASE WHEN te_cuenta = "', cuenta CLIPPED, '"',
				' THEN "', glosa1 CLIPPED, '"',
				' ELSE "', glosa CLIPPED, '"',
			' END, ',
	    		expr_valor CLIPPED, ', 0, ', 
	    ' 		DATE("', r_b12.b12_fec_proceso, '"),',
		        rm_c10.c10_codprov,
	    '		FROM tmp_cuenta ', 
	    '		WHERE te_valor_db > 0 '
PREPARE stmnt4 FROM query
EXECUTE stmnt4
UPDATE ctbt013 SET b13_codprov = rm_c10.c10_codprov
	WHERE b13_compania  = vg_codcia AND 
	      b13_tipo_comp = r_b12.b12_tipo_comp AND 
	      b13_num_comp  = r_b12.b12_num_comp

CALL grabar_conf_cont_compras(r_b12.b12_tipo_comp, r_b12.b12_num_comp)

RETURN r_b12.*

END FUNCTION



FUNCTION grabar_conf_cont_compras(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp

INSERT INTO ordt040 VALUES(vg_codcia, vg_codloc, rm_c13.c13_numero_oc,
		           rm_c13.c13_num_recep, tipo_comp, num_comp)

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
	CALL fl_mostrar_mensaje('No existe recepción de orden de compra.','stop')
        EXIT PROGRAM
ELSE
        CALL control_muestra_recepcion(vm_rows_recep[vm_row_current])
END IF
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 6
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



FUNCTION retorna_num_tran_activo(codcia, codigo_tran) 
DEFINE codcia 		LIKE actt005.a05_compania
DEFINE codigo_tran	LIKE actt005.a05_codigo_tran
DEFINE numero		LIKE actt005.a05_numero

DECLARE up_tact CURSOR FOR SELECT a05_numero FROM actt005
	WHERE a05_compania    = codcia AND
	      a05_codigo_tran = codigo_tran
	FOR UPDATE
OPEN up_tact
FETCH up_tact INTO numero
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe control secuencia en actt005',
				'stop')
	EXIT PROGRAM
END IF
LET numero = numero + 1
UPDATE actt005 SET a05_numero = numero + 1
	WHERE CURRENT OF up_tact
RETURN numero

END FUNCTION



FUNCTION control_ver_contabilizacion()
DEFINE r_c40		RECORD LIKE ordt040.*
DEFINE command_run 	VARCHAR(200)
DEFINE run_prog		CHAR(10)

INITIALIZE r_c40.* TO NULL
DECLARE q_c40 CURSOR FOR
	SELECT * FROM ordt040
		WHERE c40_compania  = vg_codcia
		  AND c40_localidad = vg_codloc
		  AND c40_numero_oc = rm_c13.c13_numero_oc
		  AND c40_num_recep = rm_c13.c13_num_recep
OPEN q_c40
FETCH q_c40 INTO r_c40.*
CLOSE q_c40
FREE q_c40
IF r_c40.c40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Esta recepcion no tiene un comprobante contable.', 'exclamation')
	RETURN
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
		vg_separador, 'fuentes', vg_separador, run_prog, 'ctbp201 ',
		vg_base, ' CB ', vg_codcia, ' "', r_c40.c40_tipo_comp, '" ',
		r_c40.c40_num_comp
RUN command_run

END FUNCTION



FUNCTION retorna_fin_mes(fecha)
DEFINE fecha		DATE
DEFINE mes, anio	SMALLINT

LET mes  = MONTH(fecha) + 1
LET anio = YEAR(fecha)
IF mes > 12 THEN
	LET mes  = 1
	LET anio = anio + 1
END IF
LET fecha = MDY(mes, 01, anio) - 1 UNITS DAY
RETURN fecha

END FUNCTION



FUNCTION retorna_num_aut()
DEFINE r_s18		RECORD LIKE srit018.*

LET rm_c13.c13_num_aut = vg_fecha USING "ddmmyyyy"
INITIALIZE r_s18.* TO NULL
SELECT * 
  INTO r_s18.*
  FROM srit018
 WHERE s18_compania  = vg_codcia
   AND s18_cod_ident = rm_p01.p01_tipo_doc
   AND s18_tipo_tran = 1

LET rm_c13.c13_num_aut = rm_c13.c13_num_aut, r_s18.s18_sec_tran
LET rm_c13.c13_num_aut = rm_c13.c13_num_aut, rm_p01.p01_num_doc CLIPPED, '2',
					rm_c13.c13_num_guia[1, 3] CLIPPED,
					rm_c13.c13_num_guia[5, 7] CLIPPED,
					rm_c13.c13_num_guia[9, 17] CLIPPED,
					rm_p01.p01_num_aut
DISPLAY BY NAME rm_c13.c13_num_aut

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
DISPLAY '<F5>      Cabecera'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

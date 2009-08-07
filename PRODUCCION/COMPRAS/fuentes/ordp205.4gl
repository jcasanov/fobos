{*
 * Titulo           : ordp205.4gl - Recepción de Ordenes de Compra
 * Elaboracion      : 26-feb-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun ordp205 base modulo compania localidad
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

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

DEFINE rm_c00		RECORD LIKE ordt000.*	-- CONFIGURACION DE OC
DEFINE rm_c02		RECORD LIKE ordt002.*	-- PORCENTAJE DE RETENCIONES OC
DEFINE rm_p02		RECORD LIKE cxpt002.*	-- PROVEEDORES POR LOCALIDAD
DEFINE rm_p05		RECORD LIKE cxpt005.*	-- RETENCIONES CONF * PROVEEDOR

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[250] OF RECORD
	c11_cant_ped		LIKE ordt011.c11_cant_ped,
	c14_cantidad		LIKE ordt014.c14_cantidad,
	c14_codigo			LIKE ordt014.c14_codigo,
	c14_descrip			LIKE ordt014.c14_descrip
	END RECORD

-------------------------------------------------------

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

DEFINE val_impto	LIKE rept019.r19_tot_dscto
DEFINE tot_ret		LIKE rept019.r19_tot_neto
---------------------------------------------------------------

DEFINE vm_num_recep	SMALLINT
DEFINE vm_row_current	SMALLINT

DEFINE vm_rows_recep	ARRAY[50] OF INTEGER



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN

CALL startlog('../logs/ordp205.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 AND num_args() <> 5 THEN 
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vg_numero_oc = arg_val(5)
LET vg_proceso = 'ordp205'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE done 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_detalle  = 250
LET vm_estado       = 'P'
LET ind_max_ret     = 50

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW w_205 AT 3,2 WITH 18 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_205 FROM '../forms/ordf205_1'
DISPLAY FORM f_205

CALL control_display_botones()

LET vm_filas_pant = fgl_scr_size('r_detalle')

MENU 'OPCIONES'
	COMMAND KEY('I') 'Recepción' 'Recepción de Ordenes de Compra.'
		LET done = control_recepcion()

	COMMAND KEY('S') 'Salir'  'Salir del Programa.'
		EXIT MENU

END MENU
		
END FUNCTION



FUNCTION muestra_contadores()

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_recep AT 1, 67 

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'C Ped'		TO tit_col0
DISPLAY 'C Rec'		TO tit_col1
DISPLAY 'Código' 	TO tit_col2
DISPLAY 'Descripción'	TO tit_col3

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
	DISPLAY BY NAME 
			rm_c13.c13_numero_oc,
			rm_c13.c13_fecing,
			rm_c13.c13_usuario 

LET vm_filas_pant = fgl_scr_size('r_detalle')

FOR i = 1 TO vm_filas_pant
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].* 
END FOR

CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING rm_p01.*
--	DISPLAY rm_p01.p01_nomprov TO nomprov

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
	IF r_c14.c14_paga_iva = 'N' THEN
		LET cont = cont + 1
	END IF

	LET val_impto = val_impto + r_c14.c14_val_impto

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



FUNCTION control_recepcion()
DEFINE i 		SMALLINT
DEFINE done 	SMALLINT
DEFINE resp		CHAR(6)
DEFINE estado   LIKE ordt010.c10_estado

CLEAR FORM
CALL control_display_botones()

INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*,vm_flag_forma_pago TO NULL
LET tot_ret = 0

LET rm_c13.c13_fecing  = CURRENT
LET rm_c13.c13_usuario = vg_usuario
LET rm_c13.c13_estado  = 'A'

DISPLAY BY NAME rm_c13.c13_fecing, rm_c13.c13_usuario

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

IF status < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK 
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	CALL fgl_winmessage(vg_producto,'La orden de compra está siendo recibida por otro usuario.','exclamation')
	CLEAR FORM 
	CALL control_display_botones()
	RETURN 0
END IF
WHENEVER ERROR STOP

CALL control_cargar_detalle()

IF vm_ind_arr = 0 THEN
	ROLLBACK WORK 
	CLEAR FORM 
	CALL control_display_botones()
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	RETURN 0
END IF

CALL control_lee_detalle_ordt014() 

IF int_flag THEN
	ROLLBACK WORK 
	CLEAR FORM
	CALL control_display_botones()
	INITIALIZE rm_c00.*, rm_c13.*, rm_c14.*, vm_flag_forma_pago TO NULL
	RETURN 0
END IF


	LET estado = 'P'

	UPDATE ordt010 SET c10_estado      = estado,
			   c10_fecha_entre = CURRENT	
		WHERE CURRENT OF q_ordt010 

CALL control_update_ordt011()

COMMIT WORK

CALL fgl_winmessage(vg_producto,'Proceso realizado Ok.','info')
	
CLEAR FORM
CALL control_display_botones()

RETURN 1

END FUNCTION



FUNCTION control_update_ordt011()
DEFINE i 	SMALLINT

FOR i = 1 TO vm_ind_arr

	IF r_detalle[i].c14_cantidad > 0 THEN

		UPDATE ordt011 
			SET c11_cant_rec = c11_cant_rec + r_detalle[i].c14_cantidad
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
DEFINE oc_ant		LIKE ordt010.c10_numero_oc

LET vm_calc_iva = 'S' 

LET int_flag = 0
INPUT BY NAME rm_c13.c13_numero_oc
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
				DISPLAY BY NAME rm_c13.c13_numero_oc
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
		    		CALL fgl_winmessage (vg_producto, 'No existe la orden de compra en la Compañía. ','exclamation')
				CLEAR nomprov
                        	NEXT FIELD c13_numero_oc
			END IF

			CALL fl_lee_proveedor(r_c10.c10_codprov)
				RETURNING rm_p01.*

			IF r_c10.c10_estado = 'A' THEN
--				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fgl_winmessage(vg_producto,'La Orden de Compra no ha sido aprobada.','exclamation')
				NEXT FIELD c13_numero_oc
			END IF

			IF r_c10.c10_estado = 'C' THEN
--				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fgl_winmessage(vg_producto,'La Orden de Compra está cerrada.','exclamation')
				NEXT FIELD c13_numero_oc
			END IF

			CALL fl_lee_tipo_orden_compra(r_c10.c10_tipo_orden)
				RETURNING rm_c01.*

			IF rm_c01.c01_ing_bodega = 'S' AND 
			   rm_c01.c01_modulo     = 'RE'
			   THEN
--				DISPLAY rm_p01.p01_nomprov TO nomprov
				CALL fgl_winmessage(vg_producto,'La orden de compra pertenece a inventarios debe ser recibida por compra local.','exclamation')
                       		NEXT FIELD c13_numero_oc
			END IF 

			LET rm_c10.c10_tipo_pago = r_c10.c10_tipo_pago
			LET rm_c13.c13_interes   = r_c10.c10_interes
--			DISPLAY rm_p01.p01_nomprov TO nomprov
			LET vm_moneda   = r_c10.c10_moneda
			LET vm_impuesto = r_c10.c10_porc_impto

			LET rm_c10.* = r_c10.* 
			CALL fl_lee_compania_orden_compra(vg_codcia)	
				RETURNING rm_c00.*

		ELSE
                       	NEXT FIELD c13_numero_oc
		END IF
END INPUT

END FUNCTION



FUNCTION control_lee_detalle_ordt014()
DEFINE i,j,k,sum_oc, sum_recep	SMALLINT
DEFINE resp			CHAR(6)

LET vm_filas_pant  = fgl_scr_size('r_detalle')
LET rm_c13.c13_tot_recep = 0
LET i = 1
LET j = 1

WHILE TRUE

	CALL set_count(vm_ind_arr)

	LET int_flag = 0

	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		ATTRIBUTES (INSERT ROW=FALSE, DELETE ROW=FALSE)
		
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
       	        		RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT WHILE
			END IF

		BEFORE ROW
			LET i = arr_curr()   # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()   # POSICION CORRIENTE EN LA PANTALLA

		BEFORE INSERT	
			CANCEL INSERT
	
		AFTER FIELD c14_cantidad
			IF r_detalle[i].c14_cantidad IS NOT NULL THEN
				IF r_detalle[i].c14_cantidad > 
				   r_detalle[i].c11_cant_ped 	
				   THEN
					CALL fgl_winmessage(vg_producto,'La cantidad recibida debe ser menor o igual a la pedida.','exclamation')
					NEXT FIELD c14_cantidad		
				END IF
			ELSE
				LET r_detalle[i].c14_cantidad = 0
				DISPLAY r_detalle[i].c14_cantidad TO r_detalle[j].c14_cantidad
			END IF	

		AFTER INPUT
			LET vm_flag_forma_pago = 'N'
			LET vm_flag_recep      = 'N'
			LET sum_oc    = 0
			LET sum_recep = 0

			FOR k = 1 TO vm_ind_arr
				LET sum_recep = sum_recep + r_detalle[k].c14_cantidad
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
	WHERE c13_compania  = vg_codcia
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



FUNCTION control_cargar_detalle()
DEFINE i 		SMALLINT
DEFINE query 		CHAR(400)
DEFINE r_c11		RECORD LIKE ordt011.*

LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
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
		LET r_detalle[i].c14_cantidad  = 0 
		LET r_detalle[i].c14_codigo    = r_c11.c11_codigo
		LET r_detalle[i].c14_descrip   = r_c11.c11_descrip
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

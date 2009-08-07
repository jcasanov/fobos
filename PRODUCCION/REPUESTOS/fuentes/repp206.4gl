{*
 * Titulo           : repp206.4gl - Recepción de Pedidos
 * Elaboracion      : 08-oct-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp206 base modulo compania localidad
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_detalle	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE
DEFINE vm_max_elm	SMALLINT
-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r10		 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r11		 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r16			RECORD LIKE rept016.*	-- CAB. PEDIDOS
DEFINE rm_r17			RECORD LIKE rept017.*	-- DET. PEDIDOS
DEFINE rm_g13		 	RECORD LIKE gent013.*	-- MONEDAS.
DEFINE rm_b10			RECORD LIKE ctbt010.*   -- MAESTRO DE CUENTAS.
DEFINE rm_p01			RECORD LIKE cxpt001.*   -- PROVEEDORES.

DEFINE rm_ctrn			RECORD LIKE rept019.*	-- CABECERA TRANSACCION

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[1300] OF RECORD
	r17_cantped		LIKE rept017.r17_cantped,
	r17_cantrec		LIKE rept017.r17_cantrec,
	r17_item		LIKE rept017.r17_item,
	r10_nombre		LIKE rept010.r10_nombre
	END RECORD

DEFINE rm_par RECORD 
	r19_bodega_ori	LIKE rept019.r19_bodega_ori
END RECORD
DEFINE total_neto 		DECIMAL(12,2)
	----------------------------------------------------------

DEFINE vm_filas_pant		SMALLINT   -- FILAS EN PANTALLA
DEFINE vg_pedido		LIKE rept016.r16_pedido
DEFINE vm_item			LIKE rept010.r10_codigo
DEFINE vm_tipo_tran		LIKE rept019.r19_cod_tran



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp206.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_pedido   = arg_val(5)
LET vg_proceso = 'repp206'

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
DEFINE done 	SMALLINT

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW w_206 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_206 FROM '../forms/repf206_1'
DISPLAY FORM f_206

LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_max_elm = 1300
LET vm_tipo_tran = 'IX'

WHILE TRUE

	CLEAR FORM
	DISPLAY 'C.Ped'    		TO tit_col1
	DISPLAY 'C.Rec'   		TO tit_col2
	DISPLAY 'Item'     		TO tit_col3
	DISPLAY 'Descripción'	TO tit_col4

	CALL control_ingreso()

END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE done 		SMALLINT

INITIALIZE rm_r16.*, rm_r17.* TO NULL

BEGIN WORK

CALL control_lee_cabecera()

	WHENEVER ERROR CONTINUE
	DECLARE q_read_r16 CURSOR FOR SELECT * FROM rept016
		WHERE  r16_compania  = vg_codcia
		AND    r16_localidad = vg_codloc
		AND    r16_pedido    = rm_r16.r16_pedido
		FOR UPDATE

	OPEN q_read_r16
	FETCH q_read_r16

	WHENEVER ERROR STOP
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF

CALL control_cargar_detalle_pedido()

IF vm_detalle = 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'No hay cantidades a recibir.',
			    'exclamation')
	RETURN
END IF

LET int_flag = 0
CALL control_lee_detalle() 

IF int_flag THEN
	ROLLBACK WORK
	RETURN
END IF

	CALL control_actualiza_cabecera_pedido()
	CALL control_actualiza_detalle_pedido()

	-- Crear documento de ingreso a bodega.
	CALL grabar_documento_ingreso()

COMMIT WORK

CALL fl_control_master_contab_repuestos(rm_ctrn.r19_compania, 
		rm_ctrn.r19_localidad, rm_ctrn.r19_cod_tran, rm_ctrn.r19_num_tran)

CALL fgl_winmessage(vg_producto,'Proceso Realizado Ok.','info')
CALL imprimir()
DISPLAY '' AT 21,8

END FUNCTION



FUNCTION grabar_documento_ingreso()
DEFINE i			SMALLINT
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE rst			RECORD LIKE rept011.*
DEFINE r_det        RECORD LIKE rept020.*
DEFINE r_art 	    RECORD LIKE rept010.*
DEFINE r_r117		RECORD LIKE rept117.*
DEFINE costo_ing    DECIMAL(14,2)
DEFINE r_r17		RECORD LIKE rept017.*


	CALL fl_lee_proveedor(rm_r16.r16_proveedor) RETURNING r_prov.*
	INITIALIZE rm_ctrn.* TO NULL
	LET rm_ctrn.r19_num_tran = 
		fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 
										'AA', vm_tipo_tran)
	IF rm_ctrn.r19_num_tran <= 0 THEN
	    ROLLBACK WORK
	    EXIT PROGRAM
	END IF
	LET rm_ctrn.r19_compania    = vg_codcia
	LET rm_ctrn.r19_localidad   = vg_codloc
	LET rm_ctrn.r19_cod_tran    = vm_tipo_tran
	LET rm_ctrn.r19_cont_cred   = 'C'
	LET rm_ctrn.r19_referencia  = 'Recepcion pedido: ', rm_r16.r16_pedido CLIPPED
	LET rm_ctrn.r19_nomcli      = r_prov.p01_nomprov
	LET rm_ctrn.r19_dircli      = r_prov.p01_direccion1
	LET rm_ctrn.r19_cedruc      = r_prov.p01_num_doc
	SELECT MIN(r01_codigo) INTO rm_ctrn.r19_vendedor
	    FROM rept001 WHERE r01_compania = vg_codcia
	LET rm_ctrn.r19_descuento   = 0
	LET rm_ctrn.r19_porc_impto  = 0
	LET rm_ctrn.r19_bodega_ori  = rm_par.r19_bodega_ori
	LET rm_ctrn.r19_bodega_dest = rm_par.r19_bodega_ori
	LET rm_ctrn.r19_fact_costo  = 0 
	LET rm_ctrn.r19_fact_venta  = 0
	LET rm_ctrn.r19_moneda      = rm_r16.r16_moneda

	CALL fl_lee_cod_transaccion(vm_tipo_tran) RETURNING r_g21.*
	LET rm_ctrn.r19_tipo_tran  = r_g21.g21_tipo
	LET rm_ctrn.r19_calc_costo = r_g21.g21_calc_costo

	IF rg_gen.g00_moneda_base = rm_r16.r16_moneda THEN
	    LET rm_ctrn.r19_paridad = 1
	ELSE
	    CALL fl_lee_factor_moneda(rm_r16.r16_moneda, rg_gen.g00_moneda_base)
  	  	    RETURNING r_g14.*
	    IF r_g14.g14_serial IS NULL THEN
   		    ROLLBACK WORK
    	    CALL fgl_winmessage(vg_producto, 'No hay paridad de conversión de: ' || rm_r16.r16_moneda || ' a ' || rg_gen.g00_moneda_base, 'stop')
   	    	EXIT PROGRAM
		END IF
	    LET rm_ctrn.r19_paridad = r_g14.g14_tasa
	END IF
	CALL fl_lee_moneda(rm_r16.r16_moneda) RETURNING r_g13.*
	LET rm_ctrn.r19_precision   = r_g13.g13_decimales
	LET rm_ctrn.r19_tot_costo   = 0
	LET rm_ctrn.r19_tot_bruto   = 0
	LET rm_ctrn.r19_tot_dscto   = 0
	LET rm_ctrn.r19_tot_neto    = 0
	LET rm_ctrn.r19_flete       = 0
	LET rm_ctrn.r19_usuario     = vg_usuario
	LET rm_ctrn.r19_fecing      = CURRENT
	INSERT INTO rept019 VALUES (rm_ctrn.*)

	FOR i = 1 TO vm_detalle 
		IF r_detalle[i].r17_cantrec <= 0 THEN
			CONTINUE FOR
		END IF
	   SELECT * FROM rept011 
		WHERE r11_compania  = vg_codcia AND
              r11_bodega    = rm_par.r19_bodega_ori AND
              r11_item      = r_detalle[i].r17_item
		IF status = NOTFOUND THEN
        	INSERT INTO rept011 VALUES(vg_codcia, rm_par.r19_bodega_ori,
        	    r_detalle[i].r17_item, 'SN', NULL, 0, 0, 0, 0, NULL, NULL,
        	    NULL, NULL, NULL, NULL)
    	END IF

		CALL fl_lee_item(vg_codcia, r_detalle[i].r17_item) RETURNING r_art.*
		LET costo_ing = r_art.r10_fob 

	    LET costo_ing = fl_retorna_precision_valor(rm_r16.r16_moneda, costo_ing)
    	DECLARE q_ust CURSOR FOR SELECT * FROM rept011
        	WHERE r11_compania  = vg_codcia AND
            	  r11_bodega    = rm_par.r19_bodega_ori AND
            	  r11_item      = r_detalle[i].r17_item
        FOR UPDATE
	    OPEN q_ust
    	FETCH q_ust INTO rst.*
   		SELECT SUM(r11_stock_act) INTO rst.r11_stock_ant FROM rept011
         WHERE r11_compania  = vg_codcia AND
               r11_item      = r_detalle[i].r17_item   
 	    IF rst.r11_stock_ant IS NULL THEN
       		LET rst.r11_stock_ant = 0
    	END IF

	    UPDATE rept011 SET r11_stock_act  = r11_stock_act + r_detalle[i].r17_cantrec,
    			           r11_ing_dia    = r11_ing_dia   + r_detalle[i].r17_cantrec,
    			           r11_fec_ulting = TODAY,
        			       r11_tip_ulting = rm_ctrn.r19_cod_tran,
        			       r11_num_ulting = rm_ctrn.r19_num_tran
         WHERE CURRENT OF q_ust

	    LET r_art.r10_cantped = r_art.r10_cantped - r_detalle[i].r17_cantrec
	    IF r_art.r10_cantped < 0 THEN
	        LET r_art.r10_cantped = 0
	    END IF

		-- OjO esto tambien se debe implementar en CL. 
		-- o simplemente en el maestro de items muestro la suma de los 
		-- pedidos pendientes y elimino este campo?
	    UPDATE rept010 SET r10_cantped = r_art.r10_cantped
         WHERE r10_compania = vg_codcia AND
	           r10_codigo   = r_art.r10_codigo

	    INITIALIZE r_det.* TO NULL
	    LET r_det.r20_compania      = rm_ctrn.r19_compania
	    LET r_det.r20_localidad     = rm_ctrn.r19_localidad
        LET r_det.r20_cod_tran      = rm_ctrn.r19_cod_tran
        LET r_det.r20_num_tran      = rm_ctrn.r19_num_tran
        LET r_det.r20_item          = r_detalle[i].r17_item
        LET r_det.r20_orden         = i
        LET r_det.r20_cant_ped      = r_detalle[i].r17_cantped
        LET r_det.r20_cant_ven      = r_detalle[i].r17_cantrec
        LET r_det.r20_cant_dev      = 0
        LET r_det.r20_cant_ent      = r_detalle[i].r17_cantrec
        LET r_det.r20_descuento     = 0
        LET r_det.r20_val_descto    = 0
        LET r_det.r20_precio        = r_art.r10_precio_mb
        LET r_det.r20_val_impto     = 0
        LET r_det.r20_costo         = r_art.r10_costo_mb
        LET r_det.r20_fob           = r_art.r10_fob
        LET r_det.r20_linea         = r_art.r10_linea
        LET r_det.r20_rotacion      = r_art.r10_rotacion
        LET r_det.r20_ubicacion     = rst.r11_ubicacion
        LET r_det.r20_costant_mb    = r_art.r10_costo_mb
        LET r_det.r20_costant_ma    = r_art.r10_costo_ma
        LET r_det.r20_costnue_mb    = r_art.r10_costo_mb
        LET r_det.r20_costnue_ma    = r_art.r10_costo_ma
        LET r_det.r20_stock_ant     = rst.r11_stock_act
        LET r_det.r20_stock_bd      = rst.r11_stock_ant
        LET r_det.r20_fecing        = rm_ctrn.r19_fecing
    	INSERT INTO rept020 VALUES (r_det.*)
    	LET rm_ctrn.r19_tot_costo       = rm_ctrn.r19_tot_costo +
    	                  (r_det.r20_costo * r_det.r20_cant_ven)

		{*
		 * Se graba un registro de recepcion que indique a que KP hace 
		 * referencia, aqui tambien se indicará luego el número de la 
		 * liquidación
		 *}
		INITIALIZE r_r17.* TO NULL
		SELECT * INTO r_r17.* FROM rept017
		 WHERE r17_compania  = vg_codcia
		   AND r17_localidad = vg_codloc
		   AND r17_pedido    = rm_r16.r16_pedido
		   AND r17_item      = r_detalle[i].r17_item

		INITIALIZE r_r117.* TO NULL
		LET r_r117.r117_compania  = r_r17.r17_compania
		LET r_r117.r117_localidad = r_r17.r17_localidad
		LET r_r117.r117_cod_tran  = r_det.r20_cod_tran
		LET r_r117.r117_num_tran  = r_det.r20_num_tran
		LET r_r117.r117_pedido    = r_r17.r17_pedido
		LET r_r117.r117_item      = r_r17.r17_item
        LET r_r117.r117_fob       = r_r17.r17_fob
        LET r_r117.r117_cantidad  = r_det.r20_cant_ven
		INSERT INTO rept117 VALUES (r_r117.*)

    	CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc,
                            rm_ctrn.r19_cod_tran, rm_ctrn.r19_num_tran, 
							r_det.r20_item)
	END FOR

	LET rm_ctrn.r19_tot_costo = rm_ctrn.r19_tot_costo

	UPDATE rept019 SET r19_tot_costo = rm_ctrn.r19_tot_costo,
    			       r19_tot_neto  = rm_ctrn.r19_tot_costo
     WHERE r19_compania  = rm_ctrn.r19_compania  AND
           r19_localidad = rm_ctrn.r19_localidad AND
           r19_cod_tran  = rm_ctrn.r19_cod_tran  AND
           r19_num_tran  = rm_ctrn.r19_num_tran

END FUNCTION



FUNCTION control_cargar_detalle_pedido()
DEFINE r_r10 	RECORD LIKE rept010.*
DEFINE r_r17 	RECORD LIKE rept017.*
DEFINE i 	SMALLINT

LET vm_filas_pant = fgl_scr_size('r_detalle')

FOR  i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR      r_detalle[i].* 
END FOR


DECLARE q_read_r17 CURSOR FOR SELECT * FROM rept017, rept010
	WHERE r17_compania  = vg_codcia
	  AND r17_localidad = vg_codloc
	  AND r17_pedido    = rm_r16.r16_pedido
	  AND r17_estado NOT IN ('L')  
      AND r10_compania  = r17_compania
      AND r10_codigo    = r17_item    
	ORDER BY r17_orden

LET i = 1 
FOREACH q_read_r17 INTO r_r17.*, r_r10.*

	{*
	 * Pendiente de recibir siempre es:
	 * rept017.r17_cantped - sum(rept117.r117_cantidad)
	 *}
	SELECT SUM(r117_cantidad) INTO r_r17.r17_cantrec
	  FROM rept117
	 WHERE r117_compania  = r_r17.r17_compania
	   AND r117_localidad = r_r17.r17_localidad
	   AND r117_cod_tran  = vm_tipo_tran
	   AND r117_pedido    = r_r17.r17_pedido
	   AND r117_item      = r_r17.r17_item

	IF r_r17.r17_cantrec IS NULL THEN
		LET r_r17.r17_cantrec = 0
	END IF

	LET r_detalle[i].r17_item      = r_r17.r17_item 
	LET r_detalle[i].r10_nombre    = r_r10.r10_nombre
	IF r_r17.r17_cantped - r_r17.r17_cantrec > 0 THEN
		LET r_detalle[i].r17_cantped   = r_r17.r17_cantped - r_r17.r17_cantrec
		LET r_detalle[i].r17_cantrec   = 0 	  
		LET i = i + 1
	END IF
	IF i > vm_max_elm THEN
		EXIT FOREACH
	END IF
END FOREACH

LET vm_detalle = i - 1

END FUNCTION



FUNCTION control_actualiza_cabecera_pedido()

IF total_neto > 0 THEN	
	UPDATE rept016
		  SET r16_estado    = 'R'
		WHERE r16_compania  = vg_codcia
		  AND r16_localidad = vg_codloc
		  AND r16_pedido    = rm_r16.r16_pedido
END IF

END FUNCTION



FUNCTION control_actualiza_detalle_pedido()
DEFINE i,cantrec	SMALLINT
DEFINE r_r11		RECORD LIKE rept011.*

	FOR i = 1 TO vm_detalle
		IF r_detalle[i].r17_cantrec = 0 THEN
			CONTINUE FOR
		END IF
		UPDATE rept017 
			SET   r17_cantrec   = r17_cantrec + r_detalle[i].r17_cantrec, 
			      r17_estado    = 'R'
			WHERE r17_compania  = vg_codcia
			AND   r17_localidad = vg_codloc
			AND   r17_pedido    = rm_r16.r16_pedido
			AND   r17_item      = r_detalle[i].r17_item 
	END FOR 

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE resp 		CHAR(6)
DEFINE done			SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE pendiente	SMALLINT

LET int_flag = 0
INPUT BY NAME rm_r16.r16_pedido, rm_par.r19_bodega_ori  WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
	ON KEY(F2)
		IF INFIELD(r16_pedido) THEN
			CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc,
						  'Z','T')
				RETURNING r_r16.r16_pedido
		      	IF r_r16.r16_pedido IS NOT NULL THEN
				CALL fl_lee_pedido_rep(vg_codcia,vg_codloc,
						       r_r16.r16_pedido)
					RETURNING r_r16.*
				LET rm_r16.* = r_r16.*
				CALL control_display_cabecera()
		      	END IF
		END IF
        IF INFIELD(r19_bodega_ori) THEN
            CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T') 
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
            IF r_r02.r02_codigo IS NOT NULL THEN
                LET rm_par.r19_bodega_ori = r_r02.r02_codigo
                DISPLAY BY NAME rm_par.r19_bodega_ori
                DISPLAY r_r02.r02_nombre TO n_bodega
            END IF
        END IF
		LET int_flag = 0
	AFTER FIELD r16_pedido
		IF rm_r16.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia, vg_codloc,
					       rm_r16.r16_pedido)
				RETURNING r_r16.*
                	IF r_r16.r16_pedido IS  NULL THEN
		    		CALL fgl_winmessage (vg_producto, 'El pedido no existe en la  Compañía. ','exclamation')
                        	NEXT FIELD r16_pedido
			END IF

			IF r_r16.r16_estado = 'A'  THEN
				CALL fgl_winmessage(vg_producto,'El pedido no ha sido confirmado.','exclamation')
				NEXT FIELD r16_pedido
			END IF
			
			{* 
			 * Para verificar si el pedido esta pendiente de liquidacion
			 *}
			SELECT COUNT(*) INTO pendiente
			  FROM rept117
			 WHERE r117_compania  = vg_codcia
			   AND r117_localidad = vg_codloc
			   AND r117_pedido    =r_r16.r16_pedido
			   AND r117_numliq IS NULL
			IF pendiente > 0 THEN
				CALL fgl_winmessage(vg_producto,'Ya hay una recepcion pendiente de liquidar para este pedido.','exclamation')
--				NEXT FIELD r16_pedido
			END IF 

			IF r_r16.r16_estado = 'L'  THEN
				CALL fgl_winmessage(vg_producto,'El pedido está en liquidación.','exclamation')
				NEXT FIELD r16_pedido
			END IF

			LET rm_r16.* = r_r16.*
			CALL control_display_cabecera()

		ELSE 
			NEXT FIELD r16_pedido
		END IF
    AFTER FIELD r19_bodega_ori
        IF rm_par.r19_bodega_ori IS NOT NULL THEN
            CALL fl_lee_bodega_rep(vg_codcia, rm_par.r19_bodega_ori)
                RETURNING r_r02.*
            IF r_r02.r02_codigo IS NULL THEN
                CALL fgl_winmessage(vg_producto, 'Bodega no existe.',
                            		'exclamation')
                CLEAR n_bodega
                NEXT FIELD r19_bodega_ori
            END IF
            IF r_r02.r02_estado = 'B' THEN
                CALL fgl_winmessage(vg_producto, 'Bodega está bloqueada.',
                            		'exclamation')
                CLEAR n_bodega
                NEXT FIELD r19_bodega_ori
            END IF
            IF r_r02.r02_tipo <> 'F' THEN
                CALL fgl_winmessage(vg_producto,
                    'Debe escoger una bodega física.',
                    'exclamation')
                CLEAR n_bodega
                NEXT FIELD r19_bodega_ori
            END IF
            DISPLAY r_r02.r02_nombre TO n_bodega
        ELSE
            CLEAR n_bodega
        END IF
END INPUT

END FUNCTION



FUNCTION control_lee_detalle()
DEFINE i,j,k,l		SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE item		LIKE rept010.r10_codigo

LET total_neto = 0
OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31

LET vm_filas_pant  = fgl_scr_size('r_detalle')
WHILE TRUE
	LET i = 1
	LET j = 1
	LET int_flag = 0
	CALL set_count(vm_detalle)
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		BEFORE INPUT 
			CALL dialog.keysetlabel('DELETE','')
			CALL dialog.keysetlabel('INSERT','')
		BEFORE ROW
			LET i = arr_curr()   # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()   # POSICION CORRIENTE EN LA PANTALLA

			IF r_detalle[i].r17_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, r_detalle[i].r17_item)
					RETURNING rm_r10.*
				DISPLAY '' AT 21,8
				DISPLAY i, ' de ',vm_detalle AT 21,8 
			END IF

		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				DISPLAY '' AT 21,8
				LET int_flag = 1
				RETURN 
			END IF
		
		ON KEY(F5)
			INITIALIZE item TO NULL
			CALL control_buscar_item() RETURNING item
			IF item IS NOT NULL THEN
				LET l = LENGTH(item)
				FOR k = 1 TO arr_count() 
					IF item[1,l] = 
					   r_detalle[k].r17_item[1,l] 
					   THEN
						CALL dialog.setcurrline(j,k)	
						EXIT FOR
					END IF
				END FOR
			END IF
			LET int_flag = 0

		AFTER FIELD r17_cantrec
			IF r_detalle[i].r17_cantrec IS NOT NULL THEN
				IF r_detalle[i].r17_cantrec > r_detalle[i].r17_cantped THEN
					CALL fgl_winmessage(vg_producto,'La cantidad recibida no puede ser superior a la cantidad pedida. Debe ingresar una cantidad igual o menor a la pedida.','exclamation')
					NEXT FIELD r17_cantrec
				END IF
			ELSE
				LET r_detalle[i].r17_cantrec = 0
			END IF
		BEFORE INSERT
			EXIT INPUT
		AFTER INPUT
			LET total_neto = 0
			FOR i = 1 TO arr_count()
				LET total_neto = total_neto + r_detalle[i].r17_cantrec
			END FOR
			EXIT WHILE

	END INPUT
	IF int_flag THEN
		EXIT WHILE
	END IF

END WHILE

END FUNCTION



FUNCTION control_buscar_item()
DEFINE r_r10		RECORD LIKE rept010.*

INITIALIZE r_r10.*, vm_item TO NULL

OPEN WINDOW w_206_2 AT 3,2 WITH 12 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_206_2 FROM '../forms/repf206_2'
DISPLAY FORM f_206_2

LET int_flag = 0
INPUT BY NAME vm_item WITHOUT DEFAULTS 
	ON KEY(INTERRUPT)
		INITIALIZE vm_item TO NULL
		RETURN vm_item
	ON KEY(F2)
		IF infield(vm_item) THEN
			CALL fl_ayuda_maestro_items(vg_codcia,'TODOS')
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre
		END IF
		LET int_flag = 0

	AFTER INPUT 
		IF vm_item IS NOT NULL THEN
			RETURN vm_item
		ELSE
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION control_display_cabecera()

DISPLAY BY NAME rm_r16.r16_tipo,        rm_r16.r16_referencia,
		rm_r16.r16_proveedor,   rm_r16.r16_moneda, 
		rm_r16.r16_demora,      rm_r16.r16_seguridad,
		rm_r16.r16_fec_envio,   rm_r16.r16_fec_llegada, 
		rm_r16.r16_aux_cont,    rm_r16.r16_estado,
		rm_r16.r16_linea,       rm_r16.r16_pedido

CASE rm_r16.r16_estado
	WHEN 'A'
		DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'R'
		DISPLAY 'RECIBIDO' TO tit_estado
	WHEN 'C'
		DISPLAY 'CONFIRMADO' TO tit_estado
	WHEN 'L'
		DISPLAY 'LIQUIDADO' TO tit_estado
	WHEN 'P'
		DISPLAY 'PROCESADO' TO tit_estado
END CASE

CALL fl_lee_moneda(rm_r16.r16_moneda)
	RETURNING rm_g13.*
	DISPLAY rm_g13.g13_nombre TO nom_moneda
CALL fl_lee_proveedor(rm_r16.r16_proveedor) 
	RETURNING rm_p01.*
	DISPLAY rm_p01.p01_nomprov TO nom_proveedor
CALL fl_lee_cuenta(vg_codcia,rm_r16.r16_aux_cont)
	RETURNING rm_b10.*
        DISPLAY rm_b10.b10_descripcion TO nom_aux_cont

END FUNCTION



FUNCTION imprimir()
DEFINE comando		VARCHAR(400)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun repp421 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', 
	rm_ctrn.r19_cod_tran, ' ', rm_ctrn.r19_num_tran
RUN comando

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

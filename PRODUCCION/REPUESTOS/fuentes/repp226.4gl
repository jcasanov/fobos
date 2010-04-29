{*
 * Titulo           : repp226.4gl - Conciliación de recepción contra 
 *                                  importación
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

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[1300] OF RECORD
	r17_cantped		LIKE rept017.r17_cantped,
	r17_cantrec		LIKE rept017.r17_cantrec,
	r17_item		LIKE rept017.r17_item,
	r17_fob			LIKE rept017.r17_fob,
	subtotal_item		DECIMAL(12,2)
	END RECORD

DEFINE nom_item 		LIKE rept010.r10_nombre
DEFINE total_neto 		DECIMAL(12,2)
	----------------------------------------------------------

DEFINE vm_filas_pant		SMALLINT   -- FILAS EN PANTALLA

DEFINE vg_pedido		LIKE rept016.r16_pedido

DEFINE vm_item			LIKE rept010.r10_codigo



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp226.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_pedido   = arg_val(5)
LET vg_proceso = 'repp226'

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

OPEN WINDOW w_226 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_226 FROM '../forms/repf226_1'
DISPLAY FORM f_226

LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_max_elm = 1300

WHILE TRUE

	CLEAR FORM
	DISPLAY 'C.Rec'    TO tit_col1
	DISPLAY 'C.Fac'    TO tit_col2
	DISPLAY 'Item'     TO tit_col3
	DISPLAY 'FOB'      TO tit_col4
	DISPLAY 'Subtotal' TO tit_col5

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

	IF status < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	WHENEVER ERROR STOP

CALL control_cargar_detalle_pedido()

{
IF vm_detalle = 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'No hay cantidades a recibir.',
			    'exclamation')
	RETURN
END IF
}

LET int_flag = 0
CALL control_lee_detalle() 

IF int_flag THEN
	ROLLBACK WORK
	RETURN
END IF

	CALL control_actualiza_cabecera_pedido()

	CALL control_actualiza_detalle_pedido()

COMMIT WORK
CALL fgl_winmessage(vg_producto,'Proceso Realizado Ok.','info')
CALL imprimir()
DISPLAY '' AT 21,8

END FUNCTION



FUNCTION control_cargar_detalle_pedido()
DEFINE r_r17 	RECORD LIKE rept017.*
DEFINE i 	SMALLINT

LET vm_filas_pant = fgl_scr_size('r_detalle')

FOR  i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR      r_detalle[i].* 
END FOR


DECLARE q_read_r17 CURSOR FOR SELECT * FROM rept017
	WHERE r17_compania  = vg_codcia
	  AND r17_localidad = vg_codloc
	  AND r17_pedido    = rm_r16.r16_pedido
	  AND r17_estado NOT IN ('L')  
	ORDER BY r17_orden

LET i = 1 
FOREACH q_read_r17 INTO r_r17.*
	LET r_detalle[i].r17_item      = r_r17.r17_item 

	{*
	 * Obtengo la cantidad recibida
	 *}
	SELECT SUM(r20_cant_ven), SUM(r117_cantidad), MAX(r117_fob) 
      INTO r_detalle[i].r17_cantped, r_detalle[i].r17_cantrec, 
		   r_detalle[i].r17_fob
	  FROM rept117, rept020
	 WHERE r117_compania  = vg_codcia
	   AND r117_localidad = vg_codloc
	   AND r117_cod_tran  = 'IX'
	   AND r117_pedido    = rm_r16.r16_pedido
	   AND r117_item      = r_r17.r17_item
	   AND r117_numliq    IS NULL
	   AND r20_compania   = r117_compania
	   AND r20_localidad  = r117_localidad
	   AND r20_cod_tran   = r117_cod_tran
	   AND r20_num_tran   = r117_num_tran
	   AND r20_item       = r117_item    

	IF r_detalle[i].r17_cantped IS NULL THEN
		CONTINUE FOREACH
	END IF

	LET r_detalle[i].subtotal_item = r_detalle[i].r17_fob * 
									 r_detalle[i].r17_cantrec
	LET i = i + 1

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
DEFINE r_r117		RECORD LIKE rept117.*

DEFINE facturado_actual		LIKE rept117.r117_cantidad
DEFINE difcant			SMALLINT
DEFINE actualiza_cant		INTEGER

IF rm_r16.r16_estado <> 'P' THEN
	FOR i = 1 TO vm_detalle
		INITIALIZE r_r117.* TO NULL
		DECLARE q_r117_1 CURSOR FOR 
			SELECT * FROM rept117
			 WHERE r117_compania  = vg_codcia
			   AND r117_localidad = vg_codloc
			   AND r117_cod_tran  = 'IX'
			   AND r117_pedido    = rm_r16.r16_pedido
			   AND r117_item      = r_detalle[i].r17_item 
			   AND r117_numliq    IS NULL  
			 ORDER BY r117_compania, r117_localidad, r117_cod_tran, r117_num_tran DESC
		
		LET actualiza_cant = 1 
		FOREACH q_r117_1 INTO r_r117.*
			IF actualiza_cant = 1 THEN

				SELECT SUM(r117_cantidad)
				  INTO facturado_actual
				  FROM rept117
				 WHERE r117_compania  = vg_codcia
				   AND r117_localidad = vg_codloc
				   AND r117_cod_tran  = 'IX'
				   AND r117_pedido    = rm_r16.r16_pedido
				   AND r117_item      = r_r117.r117_item
				   AND r117_numliq    IS NULL

				-- cantrec tiene la cantidad facturada y cantped la cantidad recibida
				LET difcant = r_detalle[i].r17_cantrec - facturado_actual 

				UPDATE rept117 
				   SET r117_fob       = r_detalle[i].r17_fob,
				       r117_cantidad  = r117_cantidad + difcant
				 WHERE r117_compania  = r_r117.r117_compania
				   AND r117_localidad = r_r117.r117_localidad
				   AND r117_cod_tran  = r_r117.r117_cod_tran
				   AND r117_num_tran  = r_r117.r117_num_tran
				   AND r117_pedido    = r_r117.r117_pedido
				   AND r117_item      = r_r117.r117_item 
				   AND r117_numliq IS NULL  
				LET actualiza_cant = 0 
			ELSE
				UPDATE rept117 
				   SET r117_fob       = r_detalle[i].r17_fob
				 WHERE r117_compania  = r_r117.r117_compania
				   AND r117_localidad = r_r117.r117_localidad
				   AND r117_cod_tran  = r_r117.r117_cod_tran
				   AND r117_num_tran  = r_r117.r117_num_tran
				   AND r117_pedido    = r_r117.r117_pedido
				   AND r117_item      = r_r117.r117_item 
				   AND r117_numliq IS NULL  
			END IF
		END FOREACH
	END FOR 
ELSE
	FOR i = 1 TO vm_detalle
		IF r_detalle[i].r17_cantrec > 0 THEN
			INITIALIZE r_r117.* TO NULL
			DECLARE q_r117_2 CURSOR FOR 
				SELECT * FROM rept117
				 WHERE r117_compania  = vg_codcia
				   AND r117_localidad = vg_codloc
				   AND r117_cod_tran  = 'IX'
				   AND r117_pedido    = rm_r16.r16_pedido
				   AND r117_item      = r_detalle[i].r17_item 
				   AND r117_numliq IS NULL  
				 ORDER BY r117_compania, r117_localidad, r117_cod_tran, r117_num_tran DESC
		
			LET actualiza_cant = 1
			FOREACH q_r117_2 INTO r_r117.*
				IF actualiza_cant = 1 THEN
					SELECT SUM(r117_cantidad)
					  INTO facturado_actual
					  FROM rept117
					 WHERE r117_compania  = vg_codcia
					   AND r117_localidad = vg_codloc
					   AND r117_cod_tran  = 'IX'
					   AND r117_pedido    = rm_r16.r16_pedido
					   AND r117_item      = r_r117.r117_item
					   AND r117_numliq    IS NULL

					-- cantrec tiene la cantidad facturada y cantped la cantidad recibida
					LET difcant = r_detalle[i].r17_cantrec - facturado_actual 

					UPDATE rept117 
					   SET r117_fob       = r_detalle[i].r17_fob,
						 r117_cantidad  = r117_cantidad + difcant 
					 WHERE r117_compania  = r_r117.r117_compania
					   AND r117_localidad = r_r117.r117_localidad
					   AND r117_cod_tran  = r_r117.r117_cod_tran
					   AND r117_num_tran  = r_r117.r117_num_tran
					   AND r117_pedido    = r_r117.r117_pedido
					   AND r117_item      = r_r117.r117_item 
					   AND r117_numliq IS NULL
					LET actualiza_cant = 0  
				ELSE
					UPDATE rept117 
					   SET r117_fob       = r_detalle[i].r17_fob
					 WHERE r117_compania  = r_r117.r117_compania
					   AND r117_localidad = r_r117.r117_localidad
					   AND r117_cod_tran  = r_r117.r117_cod_tran
					   AND r117_num_tran  = r_r117.r117_num_tran
					   AND r117_pedido    = r_r117.r117_pedido
					   AND r117_item      = r_r117.r117_item 
					   AND r117_numliq IS NULL
				END IF
			END FOREACH
		END IF
	END FOR 
END IF

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE resp 		CHAR(6)
DEFINE done		SMALLINT
DEFINE pendiente	SMALLINT
DEFINE r_r16		RECORD LIKE rept016.*

LET int_flag = 0
INPUT BY NAME rm_r16.r16_pedido  WITHOUT DEFAULTS
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
	AFTER FIELD r16_pedido
		IF rm_r16.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, rm_r16.r16_pedido)
				RETURNING r_r16.*
			IF r_r16.r16_pedido IS  NULL THEN
		    	CALL fgl_winmessage (vg_producto, 'El pedido no existe en la  Compañía. ','exclamation')
               	NEXT FIELD r16_pedido
			END IF

			IF r_r16.r16_estado = 'A'  THEN
				CALL fgl_winmessage(vg_producto,'El pedido no ha sido confirmado.','exclamation')
				NEXT FIELD r16_pedido
			END IF

			IF r_r16.r16_estado = 'L'  THEN
				CALL fgl_winmessage(vg_producto,'El pedido está en liquidación.','exclamation')
				NEXT FIELD r16_pedido
			END IF

			{* 
			 * Para verificar si el pedido esta pendiente de liquidacion
			 *}
			SELECT COUNT(*) INTO pendiente
			  FROM rept117
			 WHERE r117_compania  = vg_codcia
			   AND r117_localidad = vg_codloc
			   AND r117_cod_tran  = 'IX'
			   AND r117_pedido    = r_r16.r16_pedido
			   AND r117_numliq IS NULL

			IF pendiente <= 0 THEN
				CALL fgl_winmessage(vg_producto,'No hay una recepcion pendiente de liquidar para este pedido.','exclamation')
				NEXT FIELD r16_pedido
			END IF 

			IF r_r16.r16_estado = 'R'  THEN
				LET rm_r16.* = r_r16.*
				CALL control_display_cabecera()
			ELSE 
				NEXT FIELD r16_pedido
			END IF
		END IF
			
END INPUT

END FUNCTION



FUNCTION control_lee_detalle()
DEFINE i,j,k,l		SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE item		LIKE rept010.r10_codigo

LET total_neto = 0
DISPLAY BY NAME total_neto
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
			CALL calcula_totales()
			CALL dialog.keysetlabel('DELETE','')
			CALL dialog.keysetlabel('INSERT','')
		BEFORE ROW
			LET i = arr_curr()   # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()   # POSICION CORRIENTE EN LA PANTALLA

			IF r_detalle[i].r17_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, 
						 r_detalle[i].r17_item)
					RETURNING rm_r10.*
				DISPLAY rm_r10.r10_nombre TO nom_item
				DISPLAY '' AT 21,8
				DISPLAY i, ' de ',vm_detalle AT 21,8 
			END IF
		AFTER FIELD r17_fob
			CALL calcula_totales()	
			DISPLAY r_detalle[i].* TO r_detalle[j].*
		AFTER FIELD r17_cantrec
			CALL calcula_totales()	
			DISPLAY r_detalle[i].* TO r_detalle[j].*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				DISPLAY '' AT 21,8
				LET int_flag = 1
				RETURN 
			END IF
		BEFORE INSERT
			EXIT INPUT
		AFTER INPUT
			IF total_neto = 0 THEN
				NEXT FIELD r17_cantrec  
			END IF
			EXIT WHILE

	END INPUT
	IF int_flag THEN
		EXIT WHILE
	END IF

END WHILE

END FUNCTION



FUNCTION calcula_totales()
DEFINE i 	SMALLINT

LET total_neto = 0 	-- TOTAL NETO

FOR i = 1 TO vm_detalle
	LET r_detalle[i].subtotal_item = r_detalle[i].r17_cantrec *
					 r_detalle[i].r17_fob	
	LET total_neto = total_neto + r_detalle[i].subtotal_item	
END FOR
	DISPLAY BY NAME total_neto

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
	vg_separador, 'fuentes', vg_separador, '; fglrun repp407 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', rm_r16.r16_pedido
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

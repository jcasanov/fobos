------------------------------------------------------------------------------
-- Titulo           : repp206.4gl - Recepción de Pedidos
-- Elaboracion      : 08-nov-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp206 base modulo compania localidad
-- Ultima Correccion: 09-nov-2001
-- Motivo Correccion: 1
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_detalle	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE
DEFINE vm_max_elm	SMALLINT
-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r10	 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r11	 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r16		RECORD LIKE rept016.*	-- CAB. PEDIDOS
DEFINE rm_r17		RECORD LIKE rept017.*	-- DET. PEDIDOS
DEFINE rm_g13	 	RECORD LIKE gent013.*	-- MONEDAS.
DEFINE rm_b10		RECORD LIKE ctbt010.*   -- MAESTRO DE CUENTAS.
DEFINE rm_p01		RECORD LIKE cxpt001.*   -- PROVEEDORES.

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle	ARRAY[1300] OF RECORD
				r17_cantped	LIKE rept017.r17_cantped,
				r17_cantrec	LIKE rept017.r17_cantrec,
				r17_item	LIKE rept017.r17_item,
				r17_fob		LIKE rept017.r17_fob,
				subtotal_item	DECIMAL(13,4)
			END RECORD

DEFINE nom_item 		LIKE rept010.r10_nombre
DEFINE total_neto 		DECIMAL(13,4)
	----------------------------------------------------------

	---- ARREGLO PARALELO PARA LOS OTROS CAMPOS ----
DEFINE r_detalle_1 	ARRAY[1300] OF RECORD
				vm_cantrec	LIKE rept017.r17_cantrec
							  -- PARA ALMACENAR
							  -- LA CANT.RECIBIDA
							  -- ANTERIORMENTE
			END RECORD
	----------------------------------------------------------

DEFINE vm_size_arr		SMALLINT   -- FILAS EN PANTALLA

DEFINE vg_pedido		LIKE rept016.r16_pedido



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_pedido  = arg_val(5)
LET vg_proceso = 'repp206'

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
DEFINE done	 	SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
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
OPEN WINDOW w_206 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_206 FROM '../forms/repf206_1'
ELSE
	OPEN FORM f_206 FROM '../forms/repf206_1c'
END IF
DISPLAY FORM f_206

CALL retorna_tam_arr()
LET vm_max_elm = 1300

WHILE TRUE

	CLEAR FORM
	--#DISPLAY 'C.Ped'    TO tit_col1
	--#DISPLAY 'C.Rec'    TO tit_col2
	--#DISPLAY 'Item'     TO tit_col3
	--#DISPLAY 'FOB'      TO tit_col4
	--#DISPLAY 'Subtotal' TO tit_col5

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
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP

CALL control_cargar_detalle_pedido()

IF vm_detalle = 0 THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No hay cantidades a recibir.','exclamation')
	CALL fl_mostrar_mensaje('No hay cantidades a recibir.','exclamation')
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

COMMIT WORK
--CALL fgl_winmessage(vg_producto,'Proceso Realizado Ok.','info')
CALL imprimir()
CALL fl_mostrar_mensaje('Proceso Realizado Ok.','info')
IF vg_gui = 1 THEN
	DISPLAY '' AT 09, 60
END IF

END FUNCTION



FUNCTION control_cargar_detalle_pedido()
DEFINE r_r17 	RECORD LIKE rept017.*
DEFINE i 	SMALLINT

CALL retorna_tam_arr()

FOR  i = 1 TO vm_size_arr 
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
	LET r_detalle[i].r17_fob       = r_r17.r17_fob 
	LET r_detalle_1[i].vm_cantrec  = r_r17.r17_cantrec  
	IF rm_r16.r16_estado <> 'P' THEN
		LET r_detalle[i].r17_cantped = r_r17.r17_cantped
		LET r_detalle[i].r17_cantrec = r_r17.r17_cantrec
		LET r_detalle[i].subtotal_item = r_r17.r17_fob * 
						 r_r17.r17_cantrec
		LET i = i + 1
	ELSE
		IF r_r17.r17_cantped - r_r17.r17_cantrec > 0 THEN
			LET r_detalle[i].r17_cantped   = r_r17.r17_cantped - 
						         r_r17.r17_cantrec
			LET r_detalle[i].r17_cantrec   = 0 	  
			LET r_detalle[i].subtotal_item = r_r17.r17_fob * 
							 r_detalle[i].r17_cantrec
			LET i = i + 1
		END IF
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
DEFINE cantrec		LIKE rept017.r17_cantrec
DEFINE i		SMALLINT
DEFINE r_r11		RECORD LIKE rept011.*

IF rm_r16.r16_estado <> 'P' THEN
	FOR i = 1 TO vm_detalle
{
		IF r_detalle[i].r17_cantrec = 0 THEN
			CONTINUE FOR
		END IF
}
		UPDATE rept017 
			SET   r17_cantrec   = r_detalle[i].r17_cantrec, 
			      r17_estado    = 'R',
			      r17_fob       = r_detalle[i].r17_fob	
			WHERE r17_compania  = vg_codcia
			AND   r17_localidad = vg_codloc
			AND   r17_pedido    = rm_r16.r16_pedido
			AND   r17_item      = r_detalle[i].r17_item 
	END FOR 
ELSE
	FOR i = 1 TO vm_detalle
		IF r_detalle[i].r17_cantrec > 0 THEN
			UPDATE rept017 
				SET   r17_cantped   = r_detalle[i].r17_cantped,
				      r17_cantrec   = r_detalle[i].r17_cantrec,
				      r17_estado    = 'R',	
			      	      r17_fob       = r_detalle[i].r17_fob	
				WHERE r17_compania  = vg_codcia
				AND   r17_localidad = vg_codloc
				AND   r17_pedido    = rm_r16.r16_pedido
				AND   r17_item      = r_detalle[i].r17_item 
		END IF
	END FOR 
END IF

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE resp 		CHAR(6)
DEFINE done, resul	SMALLINT
DEFINE r_r16		RECORD LIKE rept016.*

LET int_flag = 0
INPUT BY NAME rm_r16.r16_pedido  WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
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
				CALL control_DISPLAY_cabecera()
		      	END IF
		END IF
	ON KEY(F5)
		IF rm_r16.r16_pedido IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL reactivar_pedido() RETURNING resul
		IF resul THEN
			CONTINUE INPUT
		END IF
		EXIT PROGRAM
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r16_pedido
		IF rm_r16.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia, vg_codloc,
					       rm_r16.r16_pedido)
				RETURNING r_r16.*
                	IF r_r16.r16_pedido IS  NULL THEN
		    		--CALL fgl_winmessage (vg_producto,'El pedido no existe en la  Compañía. ','exclamation')
				CALL fl_mostrar_mensaje('El pedido no existe en la  Compañía. ','exclamation')
                        	NEXT FIELD r16_pedido
			END IF

			IF r_r16.r16_estado = 'A'  THEN
				--CALL fgl_winmessage(vg_producto,'El pedido no ha sido confirmado.','exclamation')
				CALL fl_mostrar_mensaje('El pedido no ha sido confirmado.','exclamation')
				NEXT FIELD r16_pedido
			END IF

			IF r_r16.r16_estado = 'L'  THEN
				--CALL fgl_winmessage(vg_producto,'El pedido está en liquidación.','exclamation')
				CALL fl_mostrar_mensaje('El pedido está en liquidación.','exclamation')
				NEXT FIELD r16_pedido
			END IF

			LET rm_r16.* = r_r16.*
			CALL control_DISPLAY_cabecera()

		ELSE 
			NEXT FIELD r16_pedido
		END IF
			
END INPUT

END FUNCTION



FUNCTION control_lee_detalle()
DEFINE i, j, resul	SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_r17		RECORD LIKE rept017.*

LET total_neto = 0
DISPLAY BY NAME total_neto
OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
CALL retorna_tam_arr()
WHILE TRUE
	LET i = 1
	LET j = 1
	LET int_flag = 0
	CALL set_count(vm_detalle)
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				IF vg_gui = 1 THEN
					DISPLAY '' AT 09, 60
				END IF
				LET int_flag = 1
				RETURN 
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			CALL reactivar_pedido() RETURNING resul
			IF resul THEN
				CONTINUE INPUT
			END IF
			EXIT PROGRAM
		BEFORE INPUT 
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()   # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()   # POSICION CORRIENTE EN LA PANTALLA

			IF r_detalle[i].r17_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, 
						 r_detalle[i].r17_item)
					RETURNING rm_r10.*
				DISPLAY rm_r10.r10_nombre TO nom_item
				CALL muestra_clase(i)
				IF vg_gui = 1 THEN
					DISPLAY '' AT 09, 60
					DISPLAY i, ' de ',vm_detalle AT 09, 60
				END IF
			END IF
		BEFORE INSERT
			EXIT INPUT
		BEFORE FIELD r17_cantrec
			LET r_r17.r17_cantrec = r_detalle[i].r17_cantrec
		BEFORE FIELD r17_fob
			LET r_r17.r17_fob = r_detalle[i].r17_fob
		AFTER FIELD r17_cantrec
			IF r_detalle[i].r17_cantrec IS NOT NULL THEN
			{
				IF r_detalle[i].r17_cantrec > 
				   r_detalle[i].r17_cantped
				   THEN
					--CALL fgl_winmessage(vg_producto,'La cantidad recibida no puede ser superior a la cantidad pedida. Debe ingresar una cantidad igual o menor a la pedida.','exclamation')
					CALL fl_mostrar_mensaje('La cantidad recibida no puede ser superior a la cantidad pedida. Debe ingresar una cantidad igual o menor a la pedida.','exclamation')
					NEXT FIELD r17_cantrec
				END IF
			}
				CALL calcula_totales()
				DISPLAY r_detalle[i].subtotal_item TO
					r_detalle[j].subtotal_item
			ELSE
				LET r_detalle[i].r17_cantrec = r_r17.r17_cantrec
				DISPLAY r_detalle[i].r17_cantrec TO
					r_detalle[j].r17_cantrec
			END IF
		AFTER FIELD r17_fob
			IF r_detalle[i].r17_fob IS NULL THEN
				LET r_detalle[i].r17_fob = r_r17.r17_fob
				DISPLAY r_detalle[i].r17_fob TO
					r_detalle[j].r17_fob
			END IF
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




FUNCTION control_DISPLAY_cabecera()

DISPLAY BY NAME rm_r16.r16_tipo,        rm_r16.r16_referencia,
		rm_r16.r16_proveedor,   rm_r16.r16_moneda, 
		rm_r16.r16_demora,      rm_r16.r16_seguridad,
		rm_r16.r16_fec_envio,   rm_r16.r16_fec_llegada, 
		rm_r16.r16_aux_cont,    rm_r16.r16_estado,
		rm_r16.r16_linea,       rm_r16.r16_pedido

IF vg_gui = 0 THEN
	CALL muestra_tipo(rm_r16.r16_tipo)
END IF
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
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, run_prog, ' repp407 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', rm_r16.r16_pedido, ' "R" '
RUN comando

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 6
END IF

END FUNCTION



FUNCTION muestra_tipo(tipo)
DEFINE tipo		CHAR(1)

CASE tipo
	WHEN 'S'
		DISPLAY 'SUGERIDO' TO tit_tipo
	WHEN 'E'
		DISPLAY 'EMERGENCIA' TO tit_tipo
	OTHERWISE
		CLEAR r16_tipo, tit_tipo
END CASE

END FUNCTION



FUNCTION muestra_clase(i)
DEFINE i		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_item(vg_codcia, r_detalle[i].r17_item) RETURNING r_r10.*
CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
	RETURNING r_r72.*
DISPLAY r_r72.r72_desc_clase TO tit_clase

END FUNCTION



FUNCTION reactivar_pedido()
DEFINE resp		CHAR(6)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE r_r17		RECORD LIKE rept017.*
DEFINE cantped		LIKE rept010.r10_cantped

CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, rm_r16.r16_pedido)
	RETURNING r_r16.*
IF r_r16.r16_pedido IS NULL THEN
	CALL fl_mostrar_mensaje('El pedido ya no existe en la Compañía.', 'exclamation')
	RETURN 1
END IF
IF r_r16.r16_estado = 'A' THEN
	CALL fl_mostrar_mensaje('El pedido esta Activo.', 'exclamation')
	RETURN 1
END IF
IF r_r16.r16_estado = 'L' THEN
	CALL fl_mostrar_mensaje('El pedido esta en Liquidación.', 'exclamation')
	RETURN 1
END IF
IF r_r16.r16_estado = 'P' THEN
	CALL fl_mostrar_mensaje('El pedido ya ha sido Cerrado.', 'exclamation')
	RETURN 1
END IF
CALL fl_hacer_pregunta('Desea activar nuevamente el pedido, para modificarlo desde el mantenimiento o en la nota de pedido ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN 1
END IF
WHENEVER ERROR CONTINUE
DECLARE q_r16 CURSOR FOR
	SELECT * FROM rept016
		WHERE r16_compania  = vg_codcia
		  AND r16_localidad = vg_codloc
		  AND r16_pedido    = rm_r16.r16_pedido
	FOR UPDATE
OPEN q_r16
FETCH q_r16 INTO r_r16.*
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error de integridad de la base de datos. Favor llame al Administrador.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
UPDATE rept017 SET r17_estado  = 'A',
		   r17_cantrec = 0
	WHERE r17_compania  = r_r16.r16_compania
	  AND r17_localidad = r_r16.r16_localidad
	  AND r17_pedido    = r_r16.r16_pedido
UPDATE rept016 SET r16_estado = 'A' WHERE CURRENT OF q_r16
DECLARE q_r17 CURSOR FOR 
	SELECT * FROM rept017
		WHERE r17_compania  = r_r16.r16_compania
		  AND r17_localidad = r_r16.r16_localidad
		  AND r17_pedido    = r_r16.r16_pedido
FOREACH q_r17 INTO r_r17.*
	DECLARE q_r10 CURSOR FOR 
		SELECT * FROM rept010
			WHERE r10_compania = r_r17.r17_compania
			  AND r10_codigo   = r_r17.r17_item
		FOR UPDATE
	OPEN q_r10
	FETCH q_r10 INTO r_r10.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El ítem ' || r_r10.r10_codigo CLIPPED || ' esta siendo modificado por otro usuario.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	IF r_r10.r10_estado = 'B' THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El ítem ' || r_r10.r10_codigo CLIPPED || ' esta bloqueado. Favor dé mantenimiento al ítem.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	LET cantped = r_r10.r10_cantped - r_r17.r17_cantped
	IF cantped < 0 THEN
		LET cantped = 0
	END IF
	UPDATE rept010 SET r10_cantped = cantped WHERE CURRENT OF q_r10
	CLOSE q_r10
	FREE q_r10
END FOREACH
COMMIT WORK
CALL fl_mostrar_mensaje('El pedido ha sido reactivado OK.', 'info')
RETURN 0

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
DISPLAY '<F5>      Activar Pedido'           AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION

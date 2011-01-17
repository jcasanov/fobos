------------------------------------------------------------------------------
-- Titulo           : repp208.4gl - Cierre de Pedidos           
-- Elaboracion      : 10-nov-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp208 base modulo compania localidad
-- Ultima Correccion: 5 de julio de 2002
-- Motivo Correccion: Si hay stock conserve el PVP, si no hay stock
--		      actualize por Factor Venta (RCA)
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

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
CALL startlog('../logs/repp208.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp208'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_tipo_tran = 'IM'		-- IMPORTACION
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_208 AT 3,2 WITH 16 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_208 FROM '../forms/repf208_1'
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
			SHOW OPTION 'Cerrar'
			SHOW OPTION 'Ver Liquidación'
	
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
		        SHOW OPTION 'Cerrar'
			SHOW OPTION 'Ver Liquidación'
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

OPTIONS 
	INPUT NO WRAP

LET INT_FLAG = 0
INPUT BY NAME rm_r28.r28_numliq WITHOUT DEFAULTS
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
END INPUT

OPTIONS 
	INPUT WRAP

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
	CALL fgl_winmessage(vg_producto,
			    'Número de liquidación no existe',
			    'exclamation')
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

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_r16		RECORD LIKE rept016.*
DEFINE r_r28		RECORD LIKE rept028.*
DEFINE r_mon		RECORD LIKE gent013.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON r28_numliq, r28_fecing, r28_estado, r28_moneda, 
           r28_fob_fabrica, r28_total_fob, r28_tot_cargos, r28_seguro,
           r28_fact_costo, r28_fecha_lleg, r28_fecha_ing
	ON KEY(F2)
		IF INFIELD(r28_numliq) THEN
			CALL fl_ayuda_liquidacion_rep(vg_codcia, vg_codloc, 'P')
				RETURNING r_r28.r28_numliq
			IF r_r28.r28_numliq IS NOT NULL THEN
				LET rm_r28.r28_numliq = r_r28.r28_numliq
				DISPLAY BY NAME rm_r28.r28_numliq
			END IF
		END IF
		IF INFIELD(r28_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_r28.r28_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO r28_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	AFTER FIELD r28_moneda
		LET rm_r28.r28_moneda = GET_FLDBUF(r28_moneda)
		IF rm_r28.r28_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
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
		rm_r28.r28_fecha_lleg,
		rm_r28.r28_fecha_ing,
		rm_r28.r28_moneda,
		rm_r28.r28_fob_fabrica,
		rm_r28.r28_total_fob,
		rm_r28.r28_tot_cargos,
		rm_r28.r28_seguro,    
		rm_r28.r28_fact_costo,
		rm_r28.r28_fecing

CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

--DISPLAY '   ' TO n_estado
--CLEAR n_estado

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

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
DISPLAY nom_estado   TO n_estado

CALL fl_lee_moneda(rm_r28.r28_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda
	
END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por ' ||
	      	     'otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No',
		     'Yes|No', 'question', 1)
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

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

LET command_line = 'fglrun repp207 ', vg_base,   ' ', vg_modulo,
		                 ' ', vg_codcia, ' ', vg_codloc,
				 ' ', rm_r28.r28_numliq
RUN command_line

END FUNCTION



FUNCTION control_cerrar()
DEFINE tot_fob_rec	DECIMAL(14,2)
DEFINE done		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

IF rm_r28.r28_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,
			    'La liquidación ya fue cerrada.',
			    'exclamation')
	RETURN
END IF
IF rm_r28.r28_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
			    'Esta liquidación no está activa', 'exclamation')
	RETURN
END IF
IF rm_r28.r28_fact_costo <= 0 THEN
	CALL fgl_winmessage(vg_producto,
			    'La liquidación no tiene factor costo.',
			    'exclamation')
	RETURN
END IF
IF rm_r28.r28_fob_fabrica <= 0 THEN
	CALL fgl_winmessage(vg_producto,
			    'La liquidación no tiene fob fábrica.',
			    'exclamation')
	RETURN
END IF
SELECT SUM(r117_cantidad * r117_fob) INTO tot_fob_rec FROM rept029, rept117
	WHERE r29_compania  = rm_r28.r28_compania  AND 
	      r29_localidad = rm_r28.r28_localidad AND 
	      r29_numliq    = rm_r28.r28_numliq    AND
	      r29_compania  = r117_compania         AND 
	      r29_localidad = r117_localidad        AND 
	      r29_pedido    = r117_pedido           AND
	      r29_numliq    = r117_numliq
IF rm_r28.r28_fob_fabrica <> tot_fob_rec THEN
	CALL fgl_winmessage(vg_producto,
			    'Fob recibido en liquidación es distinto del fob recibido en pedidos. Verifique y de mantenimiento a la liquidación',
			    'exclamation')
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

COMMIT WORK
CALL fl_control_master_contab_repuestos(rm_ctrn.r19_compania, 
	rm_ctrn.r19_localidad, rm_ctrn.r19_cod_tran, rm_ctrn.r19_num_tran)
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()
--CALL imprimir()

END FUNCTION



FUNCTION imprimir()
DEFINE comando		VARCHAR(400)

{
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun repp407 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', rm_r16.r16_pedido
RUN comando
}
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
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE rst		RECORD LIKE rept011.*
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_det		RECORD LIKE rept020.*
DEFINE r_art, r_aant	RECORD LIKE rept010.*
DEFINE item         	LIKE rept010.r10_codigo
DEFINE cantped, cantrec	INTEGER
DEFINE costo_ing	DECIMAL(14,2)
DEFINE costo_nue	DECIMAL(14,2)
DEFINE fob		LIKE rept017.r17_fob

CREATE TEMP TABLE temp_detped
	(te_item	CHAR(15),
	 te_cantped	SMALLINT,
	 te_cantrec	SMALLINT,
	 te_fob		DECIMAL(12,2))
DECLARE q_dped CURSOR FOR SELECT rept017.* FROM rept029, rept017
	WHERE r29_compania  = vg_codcia     AND 
	      r29_localidad = vg_codloc     AND 
	      r29_numliq    = rm_r28.r28_numliq AND
	      r17_compania  = r29_compania  AND 
	      r17_localidad = r29_localidad AND 
   	      r17_pedido    = r29_pedido    AND
	      r17_estado    = 'L'
FOREACH q_dped INTO r_r17.*

	SELECT SUM(r20_cant_ven), SUM(r117_cantidad), MAX(r117_fob) 
      INTO r_r17.r17_cantped, r_r17.r17_cantrec, r_r17.r17_fob
	  FROM rept117, rept020
	 WHERE r117_compania  = vg_codcia
	   AND r117_localidad = vg_codloc
	   AND r117_cod_tran  = 'IX'
	   AND r117_pedido    = r_r17.r17_pedido
	   AND r117_item      = r_r17.r17_item
	   AND r117_numliq    = rm_r28.r28_numliq
	   AND r20_compania   = r117_compania
	   AND r20_localidad  = r117_localidad
	   AND r20_cod_tran   = r117_cod_tran
	   AND r20_num_tran   = r117_num_tran
	   AND r20_item       = r117_item    

	UPDATE rept017 SET r17_estado = 'P' 
	      WHERE r17_compania  = vg_codcia  AND 
	      	    r17_localidad = vg_codloc  AND 
   	            r17_pedido    = r_r17.r17_pedido AND
	      	    r17_item      = r_r17.r17_item
	IF r_r17.r17_cantped IS NULL OR r_r17.r17_cantrec = 0 THEN
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
END FOREACH
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
LET rm_ctrn.r19_referencia 	= 'LIQUIDACION: ', rm_r28.r28_numliq USING '#####'
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
		CALL fgl_winmessage(vg_producto, 'No hay paridad de conversión de: ' || rm_r28.r28_moneda || ' a ' || rg_gen.g00_moneda_base, 'stop')
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
LET rm_ctrn.r19_fecing 		= CURRENT

CALL fl_lee_cod_transaccion(rm_ctrn.r19_cod_tran) RETURNING r_g21.*
LET rm_ctrn.r19_tipo_tran  = r_g21.g21_tipo
LET rm_ctrn.r19_calc_costo = r_g21.g21_calc_costo

INSERT INTO rept019 VALUES (rm_ctrn.*)
SET LOCK MODE TO WAIT 5
LET i = 0
FOREACH q_tt INTO item, cantped, cantrec, fob
	LET costo_ing = fob * rm_r28.r28_fact_costo
	LET costo_ing = fl_retorna_precision_valor(rm_r28.r28_moneda, costo_ing)
	CALL fl_obtiene_costo_item(vg_codcia, rm_r28.r28_moneda, item, cantrec, costo_ing)
		RETURNING costo_nue
	DECLARE q_ust CURSOR FOR SELECT * FROM rept011
		WHERE r11_compania  = vg_codcia AND
		      r11_bodega    = rm_r28.r28_bodega AND 
		      r11_item      = item
	OPEN q_ust
	FETCH q_ust INTO rst.*
	SELECT SUM(r11_stock_act) INTO rst.r11_stock_ant FROM rept011
		WHERE r11_compania  = vg_codcia AND
		      r11_item      = item   -- Stock anterior todas las bodegas
	IF rst.r11_stock_ant IS NULL THEN
		LET rst.r11_stock_ant = 0
	END IF
	IF rst.r11_ubicacion IS NULL THEN
		LET rst.r11_ubicacion = 'SN'
	END IF

	CALL fl_lee_item(vg_codcia, item) RETURNING r_art.*
	LET r_aant.* = r_art.*
	LET r_art.r10_costo_mb    = costo_nue
	LET r_art.r10_costult_mb  = costo_ing
	INITIALIZE r_det.* TO NULL
	LET i = i + 1
    	LET r_det.r20_compania 		= vg_codcia
    	LET r_det.r20_localidad 	= vg_codloc
    	LET r_det.r20_cod_tran 		= rm_ctrn.r19_cod_tran
    	LET r_det.r20_num_tran 		= rm_ctrn.r19_num_tran
    	LET r_det.r20_item 		= item
    	LET r_det.r20_orden 		= 1
    	LET r_det.r20_cant_ped 		= cantped
    	LET r_det.r20_cant_ven 		= cantrec
    	LET r_det.r20_cant_dev 		= 0
    	LET r_det.r20_cant_ent 		= cantrec
    	LET r_det.r20_descuento 	= 0
    	LET r_det.r20_val_descto 	= 0
    	LET r_det.r20_precio		= r_art.r10_precio_mb 
    	LET r_det.r20_val_impto 	= 0
    	LET r_det.r20_costo 		= costo_ing
    	LET r_det.r20_fob 		= fob
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
	LET rm_ctrn.r19_tot_costo       = rm_ctrn.r19_tot_costo + (r_det.r20_cant_ven * costo_ing) 
	UPDATE rept010 SET r10_costo_mb   = r_art.r10_costo_mb,
					   r10_costult_mb = r_aant.r10_costo_mb,
					   r10_fob        = fob
	 WHERE r10_compania  = vg_codcia
	   AND r10_codigo    = item
	CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc, 
							rm_ctrn.r19_cod_tran, rm_ctrn.r19_num_tran, item)
END FOREACH			   			   	
IF i = 0 THEN 
	CALL fgl_winmessage(vg_producto, 'No se procesó ningún item, verifique pedidos asignados en la liquidación', 'stop')
	EXIT PROGRAM
END IF
UPDATE rept019 SET r19_tot_costo = rm_ctrn.r19_tot_costo,
		   r19_tot_neto  = rm_ctrn.r19_tot_costo
	WHERE r19_compania  = rm_ctrn.r19_compania  AND 
	      r19_localidad = rm_ctrn.r19_localidad AND 
	      r19_cod_tran  = rm_ctrn.r19_cod_tran  AND
	      r19_num_tran  = rm_ctrn.r19_num_tran

DROP TABLE temp_detped
RETURN 1

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

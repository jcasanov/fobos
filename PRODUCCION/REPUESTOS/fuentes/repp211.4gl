--------------------------------------------------------------------------------
-- Titulo           : repp211.4gl - Actualizaciones por EmisiÃ³n Factura
-- Elaboracion      : 30-oct-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp211.4gl base_datos compañía localidad preventa
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_preventa      LIKE rept023.r23_numprev
DEFINE vm_tipo_doc	CHAR(2)
DEFINE vm_tot_costo	DECIMAL(14,2)
DEFINE rm_ccaj		RECORD LIKE cajt010.*
DEFINE rm_cprev		RECORD LIKE rept023.*
DEFINE rm_cpago		RECORD LIKE rept025.*
DEFINE rm_cabt		RECORD LIKE rept019.*
DEFINE rm_dett		RECORD LIKE rept020.*
DEFINE rm_item		RECORD LIKE rept010.*
DEFINE rm_stock		RECORD LIKE rept011.*
DEFINE rm_r21		RECORD LIKE rept021.*
DEFINE rm_r88		RECORD LIKE rept088.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp211.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_codcia   = arg_val(2)
LET vg_codloc   = arg_val(3)
LET vm_preventa = arg_val(4)
LET vg_modulo   = 'RE'
LET vg_proceso  = 'repp211'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fl_validar_parametros()
CALL control_master_caja()

END MAIN



FUNCTION control_master_caja()
DEFINE resp		CHAR(10)
DEFINE comando		VARCHAR(80)
DEFINE hecho		SMALLINT
DEFINE run_prog		CHAR(10)

CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_tipo_doc = 'FA'
BEGIN WORK
CALL valida_preventa()
CALL valida_proforma()
CALL verifica_forma_pago()
CALL actualiza_existencias()
CALL genera_factura()
UPDATE rept023 SET r23_estado   = 'F',
	 	   r23_cod_tran = rm_cabt.r19_cod_tran,
		   r23_num_tran = rm_cabt.r19_num_tran
	WHERE CURRENT OF q_cprev 
IF rm_cpago.r25_valor_cred > 0 THEN
	CALL genera_cuenta_por_cobrar()
END IF
IF rm_cpago.r25_valor_ant > 0 THEN
	CALL actualiza_documentos_favor()
END IF
IF rm_cpago.r25_valor_cred > 0 OR rm_cpago.r25_valor_ant > 0 THEN
	CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, rm_cabt.r19_codcli)
END IF
UPDATE rept025 SET r25_cod_tran = rm_cabt.r19_cod_tran,
                   r25_num_tran = rm_cabt.r19_num_tran
	WHERE r25_compania  = vg_codcia AND 
              r25_localidad = vg_codloc AND 
              r25_numprev   = vm_preventa
UPDATE cajt010 SET j10_estado       = 'P',
		   j10_tipo_destino = rm_cabt.r19_cod_tran,
		   j10_num_destino  = rm_cabt.r19_num_tran,
		   j10_fecha_pro    = fl_current()
	WHERE CURRENT OF q_ccaj
CALL act_ultima_venta()
CALL fl_actualiza_acumulados_ventas_rep(vg_codcia, vg_codloc,
				rm_cabt.r19_cod_tran, rm_cabt.r19_num_tran)
	RETURNING hecho
IF NOT hecho THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF rm_cabt.r19_cont_cred = 'C' THEN
	CALL verifica_pago_tarjeta_credito()
END IF
CALL fl_actualiza_estadisticas_item_rep(vg_codcia, vg_codloc,
				rm_cabt.r19_cod_tran, rm_cabt.r19_num_tran)
	RETURNING hecho
IF NOT hecho THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
--IF rm_cprev.r23_num_ot IS NULL THEN
	CALL genera_orden_despacho()
--END IF
CALL actualiza_item_seriados()
UPDATE rept021 SET r21_cod_tran = rm_cabt.r19_cod_tran,
                   r21_num_tran = rm_cabt.r19_num_tran
	WHERE CURRENT OF q_prof
IF rm_r88.r88_compania IS NOT NULL THEN
	CALL transferir_item_bod_ss_bod_res()
END IF
COMMIT WORK
IF vg_codloc <> 2 AND vg_codloc <> 4 THEN
	CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc, 
		rm_cabt.r19_cod_tran, rm_cabt.r19_num_tran)
END IF
CALL generar_doc_elec()
IF rm_r88.r88_compania IS NOT NULL THEN
	RETURN
END IF
CALL fl_hacer_pregunta('Desea ver factura generada','Yes') RETURNING resp
IF resp = 'Yes' THEN
	LET run_prog = 'fglrun '
	IF vg_gui = 0 THEN
		LET run_prog = 'fglgo '
	END IF
	LET comando = run_prog, 'repp308 ', vg_base, ' ', vg_modulo, ' ', 
			vg_codcia, ' ', vg_codloc, ' ', rm_cabt.r19_cod_tran,
			' ', rm_cabt.r19_num_tran  
	RUN comando
END IF

END FUNCTION



FUNCTION retorna_reg_refact()

INITIALIZE rm_r88.* TO NULL
DECLARE q_r88 CURSOR FOR
	SELECT * FROM rept088
		WHERE r88_compania    = vg_codcia
		  AND r88_localidad   = vg_codloc
		  AND r88_numprof_nue = rm_r21.r21_numprof
OPEN q_r88
FETCH q_r88 INTO rm_r88.*
CLOSE q_r88
FREE q_r88

END FUNCTION



FUNCTION retorna_entregar_en_refacturacion(bodega, entregar_en)
DEFINE bodega		LIKE rept034.r34_bodega
DEFINE entregar_en	LIKE rept034.r34_entregar_en
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE unavez		SMALLINT

CALL retorna_reg_refact()
IF rm_r88.r88_compania IS NULL THEN
	RETURN entregar_en
END IF
DECLARE q_refer CURSOR FOR
	SELECT * FROM rept034
		WHERE r34_compania  = rm_r88.r88_compania
		  AND r34_localidad = rm_r88.r88_localidad
		  AND r34_cod_tran  = rm_r88.r88_cod_fact
		  AND r34_num_tran  = rm_r88.r88_num_fact
		  AND r34_bodega    = bodega
		  AND r34_estado    = "D"
		ORDER BY r34_bodega ASC
LET unavez = 1
FOREACH q_refer INTO r_r34.*
	IF unavez THEN
		IF entregar_en IS NULL THEN
			LET entregar_en = 'ORD. DESP.: '
		ELSE
			LET entregar_en = entregar_en CLIPPED, ' ORD. DESP.: '
		END IF
		LET unavez = 0
	END IF
	LET entregar_en = entregar_en CLIPPED, ' ', r_r34.r34_bodega USING "&&",
			  '-', r_r34.r34_num_ord_des USING "<<<<&"
END FOREACH
RETURN entregar_en

END FUNCTION



FUNCTION valida_preventa()
DEFINE mensaje		VARCHAR(100)
DEFINE preventa		VARCHAR(15)

LET preventa = vm_preventa
LET mensaje  = 'Pre-venta ', preventa CLIPPED
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
DECLARE q_ccaj CURSOR FOR
	SELECT * FROM cajt010 
		WHERE j10_compania    = vg_codcia AND 
		      j10_localidad   = vg_codloc AND 
		      j10_tipo_fuente = 'PR' AND 
		      j10_num_fuente  = vm_preventa
 		FOR UPDATE 
OPEN q_ccaj 
FETCH q_ccaj INTO rm_ccaj.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	LET mensaje = 'No existe ', mensaje CLIPPED, ' en Caja.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	EXIT PROGRAM
END IF
IF rm_ccaj.j10_estado <> "*" THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Registro en Caja no tiene estado *', 'stop')
	EXIT PROGRAM
END IF
DECLARE q_cprev CURSOR FOR
	SELECT * FROM rept023 
		WHERE r23_compania  = vg_codcia AND
		      r23_localidad = vg_codloc AND
		      r23_numprev   = vm_preventa
		FOR UPDATE
OPEN q_cprev
FETCH q_cprev INTO rm_cprev.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	LET mensaje = 'No existe ', mensaje CLIPPED
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	LET mensaje = mensaje CLIPPED, ' está bloqueada por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rm_cprev.r23_estado <> 'P' THEN
	ROLLBACK WORK
	LET mensaje = mensaje CLIPPED, ' no tiene estado de Aprobada.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

END FUNCTION



FUNCTION valida_proforma()
DEFINE mensaje		VARCHAR(100)
DEFINE proforma		VARCHAR(15)

LET proforma = rm_cprev.r23_numprof
LET mensaje  = 'Proforma ', proforma CLIPPED
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
DECLARE q_prof CURSOR FOR
	SELECT * FROM rept021 
		WHERE r21_compania  = vg_codcia
		  AND r21_localidad = vg_codloc
		  AND r21_numprof   = rm_cprev.r23_numprof
		FOR UPDATE
OPEN q_prof
FETCH q_prof INTO rm_r21.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	LET mensaje = 'No existe ', mensaje CLIPPED
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	LET mensaje = mensaje CLIPPED, ' está bloqueada por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

END FUNCTION



FUNCTION verifica_forma_pago()
DEFINE valor_aux	DECIMAL(14,2)
DEFINE r_r27		RECORD LIKE rept027.*
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE mensaje		VARCHAR(100)

WHENEVER ERROR STOP
SET LOCK MODE TO WAIT
INITIALIZE rm_cpago TO NULL
LET rm_cpago.r25_valor_cred = 0
LET rm_cpago.r25_valor_ant  = 0
SELECT * INTO rm_cpago.* FROM rept025 
	WHERE r25_compania  = vg_codcia AND 
              r25_localidad = vg_codloc AND 
              r25_numprev   = vm_preventa
IF rm_cprev.r23_cont_cred = 'R' THEN
	IF rm_cpago.r25_compania IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Preventa no tiene registro de forma de pago.','stop')
		EXIT PROGRAM
	END IF
	IF rm_cpago.r25_valor_cred <= 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor crédito incorrecto en registro de forma de pago.','stop')
		EXIT PROGRAM
	END IF
	IF rm_cprev.r23_tot_neto <> rm_cpago.r25_valor_cred + 
				    rm_cpago.r25_valor_ant THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor crédito más valores a favor es distinto del valor de la factura.', 'stop')
		EXIT PROGRAM
	END IF
ELSE
	IF rm_cpago.r25_valor_cred > 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Preventa es de contado y tiene valor crédito especificado.', 'stop')
		EXIT PROGRAM
	END IF
	IF rm_cprev.r23_tot_neto < rm_cpago.r25_valor_ant THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor a favor es mayor que valor factura.', 'stop')
		EXIT PROGRAM
	END IF
END IF
IF rm_cpago.r25_valor_cred > 0 THEN
	SELECT SUM(r26_valor_cap) INTO valor_aux FROM rept026
		WHERE r26_compania  = vg_codcia AND 
		      r26_localidad = vg_codloc AND 
		      r26_numprev   = vm_preventa
	IF valor_aux IS NULL OR valor_aux <> rm_cpago.r25_valor_cred THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No cuadra total crédito de cabecera con el detalle.', 'stop')
		EXIT PROGRAM
	END IF
END IF
SELECT SUM(r27_valor) INTO valor_aux FROM rept027
	WHERE r27_compania  = vg_codcia AND 
      	      r27_localidad = vg_codloc AND 
      	      r27_numprev   = vm_preventa
IF rm_cpago.r25_valor_ant = 0 AND valor_aux > 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Total anticipos en cabecera es 0, y en el detalle es mayor que 0. Revise preventa.', 'stop')
	EXIT PROGRAM
END IF
IF rm_cpago.r25_valor_ant > 0 THEN
	DECLARE qu_lote CURSOR FOR
		SELECT * FROM rept027
			WHERE r27_compania  = vg_codcia AND 
		      	      r27_localidad = vg_codloc AND 
		      	      r27_numprev   = vm_preventa
	LET valor_aux = 0
	FOREACH qu_lote INTO r_r27.*
		LET valor_aux = valor_aux + r_r27.r27_valor
		CALL fl_lee_documento_favor_cxc(vg_codcia, vg_codloc, 
			rm_cprev.r23_codcli, r_r27.r27_tipo, r_r27.r27_numero)
			RETURNING r_z21.*
		IF r_z21.z21_compania IS NULL THEN
			ROLLBACK WORK
			LET mensaje = 'No existe documento a favor: '
				|| r_r27.r27_tipo || '-' || r_r27.r27_numero
			CALL fl_mostrar_mensaje(mensaje,'stop')
			EXIT PROGRAM
		END IF
		IF r_r27.r27_valor > r_z21.z21_saldo THEN
			ROLLBACK WORK
			LET mensaje = 'Saldo de documento a favor: ' 
				|| r_r27.r27_tipo || '-' || r_r27.r27_numero 
				|| ' es menor que valor a aplicar.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			EXIT PROGRAM
		END IF
	END FOREACH
	IF valor_aux IS NULL OR valor_aux <> rm_cpago.r25_valor_ant THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No cuadra total valor a favor de cabecera con el detalle.', 'stop')
		EXIT PROGRAM
	END IF
END IF
IF rm_ccaj.j10_valor <> rm_cprev.r23_tot_neto - 
		rm_cpago.r25_valor_cred - rm_cpago.r25_valor_ant THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No cuadra valor recaudado en Caja contra valor neto preventa menos total crédito y menos anticipos.', 'stop')
	EXIT PROGRAM
END IF
	
END FUNCTION



FUNCTION actualiza_existencias()
DEFINE r		RECORD LIKE rept024.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE i		SMALLINT
DEFINE costo		DECIMAL(14,2)
DEFINE mensaje		VARCHAR(100)

WHENEVER ERROR STOP
SET LOCK MODE TO WAIT 1
DECLARE q_dprev CURSOR FOR SELECT * FROM rept024
	WHERE r24_compania  = vg_codcia AND 
	      r24_localidad = vg_codloc AND 
	      r24_numprev   = vm_preventa
	ORDER BY r24_orden
LET i = 0
LET vm_tot_costo = 0
FOREACH q_dprev INTO r.*
	IF r.r24_cant_ven = 0 THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_item(r.r24_compania, r.r24_item)
		RETURNING rm_item.*
	IF rm_cprev.r23_moneda = rg_gen.g00_moneda_base THEN
		LET costo = rm_item.r10_costo_mb
	ELSE
		LET costo = rm_item.r10_costo_ma
	END IF
	LET vm_tot_costo = vm_tot_costo + (r.r24_cant_ven * costo)
	CALL fl_lee_bodega_rep(r.r24_compania, r.r24_bodega)
		RETURNING r_r02.*
	CALL fl_lee_stock_rep(r.r24_compania, r.r24_bodega, r.r24_item)
		RETURNING rm_stock.*
	IF status = NOTFOUND AND r_r02.r02_tipo = 'S' THEN
		INITIALIZE rm_stock.* TO NULL
		LET rm_stock.r11_compania  = r.r24_compania
		LET rm_stock.r11_bodega    = r.r24_bodega
		LET rm_stock.r11_item      = r.r24_item
		LET rm_stock.r11_ubicacion = 'NOLOC'
		LET rm_stock.r11_stock_act = 0
		LET rm_stock.r11_stock_ant = 0
		LET rm_stock.r11_ing_dia   = 0
		LET rm_stock.r11_egr_dia   = 0
		INSERT INTO rept011 VALUES (rm_stock.*)
	END IF
	WHENEVER ERROR CONTINUE
	DECLARE q_upexi CURSOR FOR 
		SELECT * FROM rept011 
			WHERE r11_compania = r.r24_compania AND 
			      r11_bodega   = r.r24_bodega AND 
			      r11_item     = r.r24_item
			FOR UPDATE
	OPEN q_upexi
	FETCH q_upexi INTO rm_stock.*
	IF (status = NOTFOUND OR rm_stock.r11_stock_act <= 0) AND 
		r_r02.r02_tipo <> 'S' THEN
		ROLLBACK WORK
		LET mensaje = 'Item ' || r.r24_item || ' no tiene stock'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Registro de existencia está bloqueado por otro usuario.','stop')
		EXIT PROGRAM
	END IF
	IF rm_stock.r11_stock_act < r.r24_cant_ven AND 
		r_r02.r02_tipo <> 'S' THEN
		ROLLBACK WORK
		LET mensaje = 'Item ' || r.r24_item ||
				' no tiene suficiente stock'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	LET rm_stock.r11_stock_act = rm_stock.r11_stock_act - r.r24_cant_ven
	UPDATE rept011 SET r11_stock_act = rm_stock.r11_stock_act,
			   r11_egr_dia   = r11_egr_dia + r.r24_cant_ven
		WHERE CURRENT OF q_upexi
	LET i = i + 1
END FOREACH
IF i = 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('La preventa no tiene detalle de items.','stop')
	EXIT PROGRAM
END IF

END FUNCTION


FUNCTION genera_factura()
DEFINE numero 		INTEGER
DEFINE costo		DECIMAL(14,2)
DEFINE r 		RECORD LIKE rept024.*

WHENEVER ERROR STOP
SET LOCK MODE TO WAIT
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA',
					vm_tipo_doc)
	RETURNING numero
IF numero <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
INITIALIZE rm_cabt.* TO NULL
LET rm_cabt.r19_compania 	= vg_codcia
LET rm_cabt.r19_localidad 	= vg_codloc
LET rm_cabt.r19_cod_tran 	= vm_tipo_doc
LET rm_cabt.r19_num_tran 	= numero
LET rm_cabt.r19_cod_subtipo 	= NULL
LET rm_cabt.r19_cont_cred   	= rm_cprev.r23_cont_cred
LET rm_cabt.r19_ped_cliente 	= rm_cprev.r23_ped_cliente
LET rm_cabt.r19_referencia  	= rm_cprev.r23_referencia
LET rm_cabt.r19_codcli 		= rm_cprev.r23_codcli
LET rm_cabt.r19_nomcli 		= rm_cprev.r23_nomcli
LET rm_cabt.r19_dircli 		= rm_cprev.r23_dircli
LET rm_cabt.r19_telcli 		= rm_cprev.r23_telcli
LET rm_cabt.r19_cedruc 		= rm_cprev.r23_cedruc
LET rm_cabt.r19_vendedor 	= rm_cprev.r23_vendedor
LET rm_cabt.r19_oc_externa  	= rm_cprev.r23_ord_compra
LET rm_cabt.r19_oc_interna  	= NULL
LET rm_cabt.r19_ord_trabajo 	= rm_cprev.r23_num_ot
LET rm_cabt.r19_descuento 	= rm_cprev.r23_descuento
LET rm_cabt.r19_porc_impto  	= rm_cprev.r23_porc_impto
LET rm_cabt.r19_tipo_dev    	= NULL
LET rm_cabt.r19_num_dev     	= NULL
LET rm_cabt.r19_bodega_ori  	= rm_cprev.r23_bodega
LET rm_cabt.r19_bodega_dest 	= rm_cprev.r23_bodega
LET rm_cabt.r19_fact_costo  	= NULL
LET rm_cabt.r19_fact_venta  	= NULL
LET rm_cabt.r19_moneda      	= rm_cprev.r23_moneda
LET rm_cabt.r19_paridad 	= rm_cprev.r23_paridad
LET rm_cabt.r19_precision   	= rm_cprev.r23_precision
LET rm_cabt.r19_tot_costo   	= vm_tot_costo 
LET rm_cabt.r19_tot_bruto   	= rm_cprev.r23_tot_bruto
LET rm_cabt.r19_tot_dscto   	= rm_cprev.r23_tot_dscto
LET rm_cabt.r19_tot_neto 	= rm_cprev.r23_tot_neto
LET rm_cabt.r19_flete 		= rm_cprev.r23_flete
LET rm_cabt.r19_numliq 		= NULL
LET rm_cabt.r19_usuario 	= vg_usuario
CALL obtener_usuario_por_refacturacion()
LET rm_cabt.r19_fecing 		= fl_current()
INSERT INTO rept019 VALUES (rm_cabt.*)
FOREACH q_dprev INTO r.*
	IF r.r24_cant_ven = 0 THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_item(r.r24_compania, r.r24_item)
		RETURNING rm_item.*
	IF rm_cprev.r23_moneda = rg_gen.g00_moneda_base THEN
		LET costo = rm_item.r10_costo_mb
	ELSE
		LET costo = rm_item.r10_costo_ma
	END IF
	CALL fl_lee_stock_rep(r.r24_compania, r.r24_bodega, r.r24_item)
		RETURNING rm_stock.*
    	LET rm_dett.r20_compania 	= vg_codcia
    	LET rm_dett.r20_localidad 	= vg_codloc
    	LET rm_dett.r20_cod_tran 	= rm_cabt.r19_cod_tran
    	LET rm_dett.r20_num_tran 	= rm_cabt.r19_num_tran
    	LET rm_dett.r20_bodega 		= r.r24_bodega
    	LET rm_dett.r20_item 		= r.r24_item
    	LET rm_dett.r20_orden 		= r.r24_orden
    	LET rm_dett.r20_cant_ped 	= r.r24_cant_ped
    	LET rm_dett.r20_cant_ven 	= r.r24_cant_ven
    	LET rm_dett.r20_cant_dev 	= 0
    	LET rm_dett.r20_cant_ent 	= 0
    	LET rm_dett.r20_descuento 	= r.r24_descuento
    	LET rm_dett.r20_val_descto 	= r.r24_val_descto
    	LET rm_dett.r20_precio 		= r.r24_precio
    	LET rm_dett.r20_val_impto 	= r.r24_val_impto
    	LET rm_dett.r20_costo 		= costo
    	LET rm_dett.r20_fob 		= rm_item.r10_fob
    	LET rm_dett.r20_linea 		= r.r24_linea
    	LET rm_dett.r20_rotacion 	= rm_item.r10_rotacion
    	LET rm_dett.r20_ubicacion 	= rm_stock.r11_ubicacion
    	LET rm_dett.r20_costant_mb 	= rm_item.r10_costo_mb
    	LET rm_dett.r20_costant_ma 	= rm_item.r10_costo_ma
    	LET rm_dett.r20_costnue_mb 	= rm_item.r10_costo_mb
    	LET rm_dett.r20_costnue_ma 	= rm_item.r10_costo_ma
    	LET rm_dett.r20_stock_ant 	= rm_stock.r11_stock_act +r.r24_cant_ven
    	LET rm_dett.r20_stock_bd 	= 0
    	LET rm_dett.r20_fecing 		= fl_current()
	INSERT INTO rept020 VALUES (rm_dett.*)
END FOREACH

END FUNCTION



FUNCTION genera_cuenta_por_cobrar()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r		RECORD LIKE rept026.*

WHENEVER ERROR STOP
DECLARE q_dcred CURSOR FOR 
	SELECT * FROM rept026
		WHERE r26_compania  = vg_codcia AND
	      	      r26_localidad = vg_codloc AND
	      	      r26_numprev   = vm_preventa
		ORDER BY r26_dividendo
FOREACH q_dcred INTO r.*
	INITIALIZE r_doc.* TO NULL
    	LET r_doc.z20_compania	= vg_codcia
    	LET r_doc.z20_localidad = vg_codloc
    	LET r_doc.z20_codcli 	= rm_cprev.r23_codcli
    	LET r_doc.z20_tipo_doc 	= rm_cabt.r19_cod_tran
    	LET r_doc.z20_num_doc 	= rm_cabt.r19_num_tran
    	LET r_doc.z20_dividendo = r.r26_dividendo
    	LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
    	LET r_doc.z20_referencia= rm_cprev.r23_referencia
    	LET r_doc.z20_fecha_emi = vg_fecha
    	LET r_doc.z20_fecha_vcto= r.r26_fec_vcto
    	LET r_doc.z20_tasa_int  = rm_cpago.r25_interes
    	LET r_doc.z20_tasa_mora = 0
    	LET r_doc.z20_moneda 	= rm_cprev.r23_moneda
    	LET r_doc.z20_paridad 	= rm_cprev.r23_paridad
    	LET r_doc.z20_val_impto = 0
    	LET r_doc.z20_valor_cap = r.r26_valor_cap
    	LET r_doc.z20_valor_int = r.r26_valor_int
    	LET r_doc.z20_saldo_cap = r.r26_valor_cap
    	LET r_doc.z20_saldo_int = r.r26_valor_int
    	LET r_doc.z20_cartera 	= 1
    	LET r_doc.z20_linea 	= rm_cprev.r23_grupo_linea
    	LET r_doc.z20_origen 	= 'A'
    	LET r_doc.z20_cod_tran  = rm_cabt.r19_cod_tran
    	LET r_doc.z20_num_tran  = rm_cabt.r19_num_tran
    	LET r_doc.z20_usuario 	= vg_usuario
    	LET r_doc.z20_fecing 	= fl_current()
	INSERT INTO cxct020 VALUES (r_doc.*)
END FOREACH

END FUNCTION



FUNCTION actualiza_documentos_favor()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_caju		RECORD LIKE cxct022.*
DEFINE r_daju		RECORD LIKE cxct023.*
DEFINE r		RECORD LIKE rept027.*
DEFINE numero		INTEGER
DEFINE i 		SMALLINT
DEFINE valor_aux	DECIMAL(14,2)
DEFINE mensaje		VARCHAR(100)

SET LOCK MODE TO WAIT 1
INITIALIZE r_doc.* TO NULL
LET r_doc.z20_compania	= vg_codcia
LET r_doc.z20_localidad = vg_codloc
LET r_doc.z20_codcli 	= rm_cprev.r23_codcli
LET r_doc.z20_tipo_doc 	= rm_cabt.r19_cod_tran
LET r_doc.z20_num_doc 	= rm_cabt.r19_num_tran
LET r_doc.z20_dividendo = 00
LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
LET r_doc.z20_referencia= rm_cprev.r23_referencia
LET r_doc.z20_fecha_emi = vg_fecha
LET r_doc.z20_fecha_vcto= vg_fecha 
LET r_doc.z20_tasa_int  = 0
LET r_doc.z20_tasa_mora = 0
LET r_doc.z20_moneda 	= rm_cprev.r23_moneda
LET r_doc.z20_paridad 	= rm_cprev.r23_paridad
LET r_doc.z20_val_impto = 0
LET r_doc.z20_valor_cap = rm_cpago.r25_valor_ant
LET r_doc.z20_valor_int = 0
LET r_doc.z20_saldo_cap = 0
LET r_doc.z20_saldo_int = 0
LET r_doc.z20_cartera 	= 1
LET r_doc.z20_linea 	= rm_cprev.r23_grupo_linea
LET r_doc.z20_origen 	= 'A'
LET r_doc.z20_cod_tran  = rm_cabt.r19_cod_tran
LET r_doc.z20_num_tran  = rm_cabt.r19_num_tran
LET r_doc.z20_usuario 	= vg_usuario
LET r_doc.z20_fecing 	= fl_current()
INSERT INTO cxct020 VALUES (r_doc.*)
INITIALIZE r_caju.* TO NULL
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', 'AJ')
	RETURNING numero
IF numero <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_caju.z22_compania		= vg_codcia
LET r_caju.z22_localidad 	= vg_codloc
LET r_caju.z22_codcli 		= rm_cprev.r23_codcli
LET r_caju.z22_tipo_trn 	= 'AJ'
LET r_caju.z22_num_trn 		= numero
LET r_caju.z22_areaneg 		= rm_ccaj.j10_areaneg
LET r_caju.z22_referencia 	= 'APLICACION ANTICIPO'
LET r_caju.z22_fecha_emi 	= vg_fecha
LET r_caju.z22_moneda 		= rm_cprev.r23_moneda
LET r_caju.z22_paridad 		= rm_cprev.r23_paridad
LET r_caju.z22_tasa_mora 	= 0
LET r_caju.z22_total_cap 	= rm_cpago.r25_valor_ant * -1
LET r_caju.z22_total_int 	= 0
LET r_caju.z22_total_mora 	= 0
LET r_caju.z22_cobrador 	= NULL
LET r_caju.z22_subtipo 		= NULL
LET r_caju.z22_origen 		= 'A'
LET r_caju.z22_fecha_elim	= NULL
LET r_caju.z22_tiptrn_elim 	= NULL
LET r_caju.z22_numtrn_elim 	= NULL
LET r_caju.z22_usuario 		= vg_usuario
LET r_caju.z22_fecing 		= fl_current()
INSERT INTO cxct022 VALUES (r_caju.*)
LET valor_aux = rm_cpago.r25_valor_ant 
DECLARE q_antd CURSOR FOR 
	SELECT * FROM rept027 
		WHERE r27_compania  = vg_codcia AND
		      r27_localidad = vg_codloc AND
		      r27_numprev   = vm_preventa
LET i = 0
FOREACH q_antd INTO r.*
	IF r.r27_valor <= 0 THEN
		ROLLBACK WORK
		LET mensaje = 'Valor de documento <= 0: ' || r.r27_tipo ||
				' ' || r.r27_numero
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	LET i = i + 1
	INITIALIZE r_daju.* TO NULL
    	LET r_daju.z23_compania 	= vg_codcia
    	LET r_daju.z23_localidad 	= vg_codloc
    	LET r_daju.z23_codcli 		= rm_cprev.r23_codcli
    	LET r_daju.z23_tipo_trn 	= r_caju.z22_tipo_trn
    	LET r_daju.z23_num_trn 		= r_caju.z22_num_trn
    	LET r_daju.z23_orden 		= i
    	LET r_daju.z23_areaneg 		= r_caju.z22_areaneg
    	LET r_daju.z23_tipo_doc 	= r_doc.z20_tipo_doc
    	LET r_daju.z23_num_doc 		= r_doc.z20_num_doc
    	LET r_daju.z23_div_doc 		= r_doc.z20_dividendo
    	LET r_daju.z23_tipo_favor 	= r.r27_tipo
    	LET r_daju.z23_doc_favor 	= r.r27_numero
    	LET r_daju.z23_valor_cap 	= r.r27_valor * -1
    	LET r_daju.z23_valor_int 	= 0
    	LET r_daju.z23_valor_mora 	= 0
    	LET r_daju.z23_saldo_cap 	= valor_aux
	LET valor_aux           	= valor_aux - r.r27_valor
    	LET r_daju.z23_saldo_int 	= 0
	INSERT INTO cxct023 VALUES (r_daju.*)
	UPDATE cxct021 SET z21_saldo = z21_saldo - r.r27_valor
		WHERE z21_compania  = vg_codcia AND 
		      z21_localidad = vg_codloc AND 
		      z21_codcli    = rm_cprev.r23_codcli AND 
		      z21_tipo_doc  = r.r27_tipo AND
		      z21_num_doc   = r.r27_numero
END FOREACH	
IF i = 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se procesaron documentos a favor.', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION act_ultima_venta()
DEFINE bod		LIKE rept020.r20_bodega
DEFINE item		LIKE rept020.r20_item

DECLARE q_jojoy CURSOR FOR SELECT r20_bodega, r20_item
	FROM rept020
	WHERE r20_compania  = vg_codcia AND 
	      r20_localidad = vg_codloc AND
	      r20_cod_tran  = rm_cabt.r19_cod_tran AND
	      r20_num_tran  = rm_cabt.r19_num_tran
FOREACH q_jojoy INTO bod, item
	UPDATE rept011 SET r11_fec_ultvta = vg_fecha,
		           r11_tip_ultvta = rm_cabt.r19_cod_tran,
		           r11_num_ultvta = rm_cabt.r19_num_tran
		WHERE r11_compania = vg_codcia AND
	              r11_bodega   = bod       AND
	              r11_item     = item
END FOREACH

END FUNCTION



FUNCTION genera_orden_despacho()
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE r		RECORD LIKE rept020.*
DEFINE bod		LIKE rept020.r20_bodega
DEFINE entregar_en	LIKE rept034.r34_entregar_en
DEFINE i		SMALLINT

INITIALIZE r_r34.* TO NULL
LET r_r34.r34_compania 		= rm_cabt.r19_compania
LET r_r34.r34_localidad		= rm_cabt.r19_localidad
LET r_r34.r34_estado 		= 'A'
LET r_r34.r34_cod_tran 		= rm_cabt.r19_cod_tran
LET r_r34.r34_num_tran 		= rm_cabt.r19_num_tran
LET r_r34.r34_fec_entrega 	= vg_fecha
LET r_r34.r34_entregar_a 	= rm_cabt.r19_nomcli
LET r_r34.r34_entregar_en 	= rm_cabt.r19_dircli
LET r_r34.r34_usuario 		= vg_usuario
LET r_r34.r34_fecing 		= fl_current()
IF rm_cprev.r23_numprof IS NOT NULL THEN
	CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, rm_cprev.r23_numprof)
		RETURNING rm_r21.*
	IF rm_r21.r21_atencion IS NOT NULL THEN
		LET r_r34.r34_entregar_a  = rm_r21.r21_atencion
	END IF
	IF rm_r21.r21_referencia IS NOT NULL THEN
		LET r_r34.r34_entregar_en = rm_r21.r21_referencia
	END IF
END IF
DECLARE qu_nalga CURSOR FOR SELECT UNIQUE r20_bodega FROM rept020
	WHERE r20_compania  = rm_cabt.r19_compania  AND 
	      r20_localidad = rm_cabt.r19_localidad AND
	      r20_cod_tran  = rm_cabt.r19_cod_tran  AND
	      r20_num_tran  = rm_cabt.r19_num_tran
LET i = 0 
LET entregar_en = r_r34.r34_entregar_en
FOREACH qu_nalga INTO bod
	LET i = i + 1
	LET r_r34.r34_bodega = bod
	SELECT MAX(r34_num_ord_des) + 1 INTO r_r34.r34_num_ord_des FROM rept034
		WHERE r34_compania  = rm_cabt.r19_compania  AND 
	      	      r34_localidad = rm_cabt.r19_localidad AND 
	      	      r34_bodega    = bod
	IF r_r34.r34_num_ord_des IS NULL THEN
		LET r_r34.r34_num_ord_des = 1
	END IF
	CALL retorna_entregar_en_refacturacion(r_r34.r34_bodega,
						r_r34.r34_entregar_en)
		RETURNING r_r34.r34_entregar_en
	INSERT INTO rept034 VALUES (r_r34.*)
	LET r_r34.r34_entregar_en = entregar_en
	DECLARE q_muchin CURSOR FOR 
		SELECT * FROM rept020
			WHERE r20_compania  = rm_cabt.r19_compania  AND 
	                      r20_localidad = rm_cabt.r19_localidad AND
	                      r20_cod_tran  = rm_cabt.r19_cod_tran  AND
	                      r20_num_tran  = rm_cabt.r19_num_tran  AND
		              r20_bodega    = bod
	FOREACH q_muchin INTO r.*
		INSERT INTO rept035
			VALUES(r_r34.r34_compania, r_r34.r34_localidad, 
			       r_r34.r34_bodega, 
		               r_r34.r34_num_ord_des, r.r20_item, r.r20_orden, 
			       r.r20_cant_ven, 0)
	END FOREACH
END FOREACH
IF i = 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Error, no se generaron órdenes de despacho.', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION actualiza_item_seriados()

END FUNCTION



FUNCTION verifica_pago_tarjeta_credito()
DEFINE r_j11, r_j11_2	RECORD LIKE cajt011.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE dividendo	LIKE cxct020.z20_dividendo
DEFINE mensaje		VARCHAR(100)

INITIALIZE r_j11.* TO NULL
DECLARE q_pagotj CURSOR FOR
	SELECT UNIQUE j11_compania, j11_localidad, j11_tipo_fuente,
			j11_num_fuente, j11_codigo_pago, j11_cod_bco_tarj
		FROM cajt011
		WHERE j11_compania          = rm_ccaj.j10_compania
		  AND j11_localidad         = rm_ccaj.j10_localidad
		  AND j11_tipo_fuente       = rm_ccaj.j10_tipo_fuente
		  AND j11_num_fuente        = rm_ccaj.j10_num_fuente
		  AND j11_codigo_pago[1, 1] = 'T'
		ORDER BY 5, 6
OPEN q_pagotj
FETCH q_pagotj INTO r_j11.j11_compania, r_j11.j11_localidad,
			r_j11.j11_tipo_fuente, r_j11.j11_num_fuente,
			r_j11.j11_codigo_pago, r_j11.j11_cod_bco_tarj
IF STATUS = NOTFOUND THEN
	CLOSE q_pagotj
	FREE q_pagotj
	RETURN
END IF
FOREACH q_pagotj INTO r_j11.j11_compania, r_j11.j11_localidad,
			r_j11.j11_tipo_fuente, r_j11.j11_num_fuente,
			r_j11.j11_codigo_pago, r_j11.j11_cod_bco_tarj
	CALL fl_lee_tarjeta_credito(r_j11.j11_compania, r_j11.j11_cod_bco_tarj,
				r_j11.j11_codigo_pago, rm_cabt.r19_cont_cred)
		RETURNING r_g10.*
	IF r_g10.g10_codcobr IS NULL THEN
		ROLLBACK WORK
		LET mensaje = 'Tarjeta de crédito: ' , r_g10.g10_nombre CLIPPED,
				' no tiene código cobranzas asignado. ',
				'Por favor asígnelo en el módulo de ',
				'parametros GENERALES.'
		CALL fl_mostrar_mensaje(mensaje,'stop')
		EXIT PROGRAM
	END IF
	DECLARE q_pagotj2 CURSOR FOR
		SELECT * FROM cajt011
			WHERE j11_compania     = r_j11.j11_compania
			  AND j11_localidad    = r_j11.j11_localidad
			  AND j11_tipo_fuente  = r_j11.j11_tipo_fuente
			  AND j11_num_fuente   = r_j11.j11_num_fuente
			  AND j11_codigo_pago  = r_j11.j11_codigo_pago
			  AND j11_cod_bco_tarj = r_j11.j11_cod_bco_tarj
			ORDER BY j11_secuencia
	LET dividendo = 1
	FOREACH q_pagotj2 INTO r_j11_2.*
		INITIALIZE r_doc.* TO NULL
		LET r_doc.z20_compania 	 = vg_codcia
		LET r_doc.z20_localidad  = vg_codloc
		LET r_doc.z20_codcli 	 = r_g10.g10_codcobr
		LET r_doc.z20_tipo_doc 	 = rm_cabt.r19_cod_tran
		LET r_doc.z20_num_doc 	 = rm_cabt.r19_num_tran
		LET r_doc.z20_dividendo  = dividendo
		LET r_doc.z20_areaneg 	 = rm_ccaj.j10_areaneg
		LET r_doc.z20_referencia = 'AUI. #: ', r_j11_2.j11_num_ch_aut
		LET r_doc.z20_fecha_emi  = vg_fecha
		LET r_doc.z20_fecha_vcto = vg_fecha + 30
		LET r_doc.z20_tasa_int   = 0
		LET r_doc.z20_tasa_mora  = 0
		LET r_doc.z20_moneda 	 = rm_cprev.r23_moneda
		LET r_doc.z20_paridad 	 = rm_cprev.r23_paridad
		LET r_doc.z20_val_impto  = 0
		LET r_doc.z20_valor_cap  = r_j11_2.j11_valor
		LET r_doc.z20_valor_int  = 0
		LET r_doc.z20_saldo_cap  = r_j11_2.j11_valor
		LET r_doc.z20_saldo_int  = 0
		LET r_doc.z20_cartera 	 = 1
		LET r_doc.z20_linea 	 = rm_cprev.r23_grupo_linea
		LET r_doc.z20_origen  	 = 'A'
		LET r_doc.z20_cod_tran   = rm_cabt.r19_cod_tran
		LET r_doc.z20_num_tran   = rm_cabt.r19_num_tran
		LET r_doc.z20_usuario 	 = vg_usuario
		LET r_doc.z20_fecing 	 = fl_current()
		WHENEVER ERROR CONTINUE
		INSERT INTO cxct020 VALUES (r_doc.*)
		IF STATUS <> 0 THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No se puede generar el pago con tarjeta de credito. Por favor llame al ADMINISTRADOR.', 'stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
		WHENEVER ERROR STOP
		CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc,
						r_g10.g10_codcobr)
		LET dividendo = dividendo + 1
	END FOREACH
END FOREACH

END FUNCTION



FUNCTION obtener_usuario_por_refacturacion()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_j04		RECORD LIKE cajt004.*
DEFINE r_j90		RECORD LIKE cajt090.*

CALL retorna_reg_refact()
IF rm_r88.r88_compania IS NULL THEN
	RETURN
END IF
DECLARE q_j90 CURSOR FOR SELECT * FROM cajt090 WHERE j90_localidad = vg_codloc
FOREACH q_j90 INTO r_j90.*
	SELECT * INTO r_j04.* FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = r_j90.j90_codigo_caja
		  AND j04_fecha_aper  = vg_fecha
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
	  			FROM cajt004
  				WHERE j04_compania    = vg_codcia
  				  AND j04_localidad   = vg_codloc
  				  AND j04_codigo_caja = r_j90.j90_codigo_caja
  				  AND j04_fecha_aper  = vg_fecha)
	IF STATUS <> NOTFOUND THEN 
		CALL fl_lee_codigo_caja_caja(r_j04.j04_compania,
						r_j04.j04_localidad,
						r_j04.j04_codigo_caja)
			RETURNING r_j02.*
		LET rm_cabt.r19_usuario = r_j02.j02_usua_caja
		EXIT FOREACH
	END IF
END FOREACH

END FUNCTION



FUNCTION transferir_item_bod_ss_bod_res()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE num_tran		LIKE rept019.r19_num_tran

DECLARE q_trans_ori_cab CURSOR FOR
	SELECT * FROM rept019
		WHERE r19_compania  = rm_r88.r88_compania
		  AND r19_localidad = rm_r88.r88_localidad
		  AND r19_cod_tran  = 'TR'
		  AND r19_tipo_dev  = rm_r88.r88_cod_fact
		  AND r19_num_dev   = rm_r88.r88_num_fact
		  AND EXISTS
			(SELECT 1 FROM rept041
				WHERE r41_compania   = r19_compania
				  AND r41_localidad  = r19_localidad
				  AND r41_cod_tran  NOT IN ('DF', 'AF')
				  AND r41_cod_tr     = r19_cod_tran
				  AND r41_num_tr     = r19_num_tran)
		ORDER BY r19_fecing, r19_num_tran
FOREACH q_trans_ori_cab INTO r_r19.*
	LET num_tran = r_r19.r19_num_tran
	CALL fl_actualiza_control_secuencias(r_r19.r19_compania,
						r_r19.r19_localidad, vg_modulo,
						'AA', r_r19.r19_cod_tran)
		RETURNING r_r19.r19_num_tran
	IF r_r19.r19_num_tran = 0 THEN
		ROLLBACK WORK	
		CALL fl_mostrar_mensaje('No existe control de secuencia para esta transacción, no se puede asignar un número de transacción a la operación.','stop')
		EXIT PROGRAM
	END IF
	IF r_r19.r19_num_tran = -1 THEN
		SET LOCK MODE TO WAIT
		WHILE r_r19.r19_num_tran = -1
			CALL fl_actualiza_control_secuencias(r_r19.r19_compania,
						r_r19.r19_localidad, vg_modulo,
						'AA', r_r19.r19_cod_tran)
				RETURNING r_r19.r19_num_tran
		END WHILE
		SET LOCK MODE TO NOT WAIT
	END IF
	LET r_r19.r19_referencia = 'TR. AUTO. FA-',
					rm_r88.r88_num_fact USING "<<<<<<&",' ',
					r_r19.r19_cod_tran CLIPPED, '-',
					num_tran USING "<<<<<<&", ' REFACTU.'
	LET r_r19.r19_tipo_dev   = rm_cabt.r19_cod_tran
	LET r_r19.r19_num_dev    = rm_cabt.r19_num_tran
	LET r_r19.r19_usuario    = vg_usuario
	LET r_r19.r19_fecing     = fl_current()
	INSERT INTO rept019 VALUES (r_r19.*)
	INSERT INTO rept041
		VALUES(r_r19.r19_compania, r_r19.r19_localidad,
			rm_r88.r88_cod_fact, rm_r88.r88_num_fact,
			r_r19.r19_cod_tran, r_r19.r19_num_tran)
	DECLARE q_trans_ori_det CURSOR FOR
		SELECT * FROM rept020
			WHERE r20_compania  = r_r19.r19_compania
			  AND r20_localidad = r_r19.r19_localidad
			  AND r20_cod_tran  = r_r19.r19_cod_tran
			  AND r20_num_tran  = num_tran
			ORDER BY r20_orden
	FOREACH q_trans_ori_det INTO r_r20.*
		LET r_r20.r20_num_tran   = r_r19.r19_num_tran
		CALL fl_lee_item(r_r20.r20_compania, r_r20.r20_item)
			RETURNING r_r10.*
		LET r_r19.r19_tot_costo  = r_r19.r19_tot_costo +
						(r_r20.r20_cant_ven *
						 r_r10.r10_costo_mb)
		LET r_r20.r20_costo      = r_r10.r10_costo_mb 
		LET r_r20.r20_fob        = r_r10.r10_fob 
		LET r_r20.r20_linea      = r_r10.r10_linea 
		LET r_r20.r20_rotacion   = r_r10.r10_rotacion 
		LET r_r20.r20_precio     = r_r10.r10_precio_mb
		LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
		LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
		LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
		LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
		CALL fl_lee_stock_rep(r_r20.r20_compania, r_r19.r19_bodega_ori,
					r_r20.r20_item)
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET r_r20.r20_stock_ant  = r_r11.r11_stock_act 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest,
					r_r20.r20_item)
			RETURNING r_r11.*
		IF r_r11.r11_stock_act IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF
		LET r_r20.r20_stock_bd   = r_r11.r11_stock_act
		LET r_r20.r20_fecing	 = fl_current()
		INSERT INTO rept020 VALUES(r_r20.*)
		UPDATE rept019
			SET r19_tot_costo = r_r19.r19_tot_costo,
			    r19_tot_bruto = r_r19.r19_tot_bruto,
			    r19_tot_neto  = r_r19.r19_tot_bruto
			WHERE r19_compania  = vg_codcia
			  AND r19_localidad = vg_codloc
			  AND r19_cod_tran  = r_r19.r19_cod_tran
			  AND r19_num_tran  = r_r19.r19_num_tran
	END FOREACH
END FOREACH

END FUNCTION



FUNCTION generar_doc_elec()
DEFINE comando		VARCHAR(250)
DEFINE servid		VARCHAR(10)
DEFINE mensaje		VARCHAR(250)

LET servid  = FGL_GETENV("INFORMIXSERVER")
CASE servid
	WHEN "ACGYE01"
		LET servid = "idsgye01"
	WHEN "ACUIO01"
		LET servid = "idsuio01"
	WHEN "ACUIO02"
		LET servid = "idsuio02"
END CASE
LET comando = "fglgo gen_tra_ele ", vg_base CLIPPED, " ", servid CLIPPED, " ",
		vg_codcia, " ", vg_codloc, " ", rm_cabt.r19_cod_tran, " ",
		rm_cabt.r19_num_tran, " FAI"
RUN comando
LET mensaje = FGL_GETENV("HOME"), '/tmp/FA_ELEC/'
CALL fl_mostrar_mensaje('Archivo XML de FACTURA Generado en: ' || mensaje, 'info')

END FUNCTION

------------------------------------------------------------------------------
-- Titulo           : repp211.4gl - Actualizaciones por Emisión Factura
-- Elaboracion      : 30-oct-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp211.4gl base_datos compañía localidad preventa
-- Ultima Correccion: 17-ene-2005 
-- Motivo Correccion: Se permite facturar de varias bodegas simultaneamente 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_preventa	LIKE rept023.r23_numprev
DEFINE vm_tipo_doc	CHAR(2)
DEFINE vm_tot_costo	DECIMAL(14,2)
DEFINE vm_fact_sstock    CHAR(1)   --indica si se puede facturar sin stock
DEFINE rm_ccaj		RECORD LIKE cajt010.*
DEFINE rm_cprev		RECORD LIKE rept023.*
DEFINE rm_cpago		RECORD LIKE rept025.*
DEFINE rm_cabt		RECORD LIKE rept019.*
DEFINE rm_dett		RECORD LIKE rept020.*
DEFINE rm_item		RECORD LIKE rept010.*
DEFINE rm_stock		RECORD LIKE rept011.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp211.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base        = arg_val(1)
LET vg_codcia      = arg_val(2)
LET vg_codloc      = arg_val(3)
LET vm_preventa    = arg_val(4)
LET vm_fact_sstock = arg_val(5)
LET vg_modulo      = 'RE'
LET vg_proceso     = 'repp211'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL validar_parametros()
CALL control_master_caja()

END MAIN



FUNCTION control_master_caja()
DEFINE resp		CHAR(10)
DEFINE comando		VARCHAR(80)
DEFINE hecho		SMALLINT

CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_tipo_doc = 'FA'


BEGIN WORK
CALL valida_preventa()
CALL verifica_forma_pago()

CALL genera_factura()

UPDATE rept023 SET r23_estado = 'F',
	 	   r23_cod_tran = rm_cabt.r19_cod_tran,
		   r23_num_tran = rm_cabt.r19_num_tran
	WHERE CURRENT OF q_cprev 
CALL genera_cuenta_por_cobrar()
IF rm_cpago.r25_valor_ant > 0 THEN
	CALL actualiza_documentos_favor()
END IF
UPDATE rept025 SET r25_cod_tran = rm_cabt.r19_cod_tran,
                   r25_num_tran = rm_cabt.r19_num_tran
	WHERE r25_compania  = vg_codcia AND 
              r25_localidad = vg_codloc AND 
              r25_numprev   = vm_preventa
UPDATE cajt010 SET j10_estado = 'P',
				   j10_fecha_pro    = rm_cabt.r19_fecing,	
				   j10_tipo_destino = rm_cabt.r19_cod_tran,
		   		   j10_num_destino  = rm_cabt.r19_num_tran
	WHERE CURRENT OF q_ccaj
UPDATE rept011 SET r11_fec_ultvta = TODAY,
		   r11_tip_ultvta = rm_cabt.r19_cod_tran,
		   r11_num_ultvta = rm_cabt.r19_num_tran
	WHERE r11_compania = vg_codcia AND
	      r11_bodega   = rm_cabt.r19_bodega_ori AND
	      r11_item    IN 
	      (SELECT r20_item FROM rept020
			WHERE r20_compania  = vg_codcia AND 
			      r20_localidad = vg_codloc AND
			      r20_cod_tran  = rm_cabt.r19_cod_tran AND
			      r20_num_tran  = rm_cabt.r19_num_tran)

CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, retorna_cliente_final())
IF rm_cabt.r19_cont_cred = 'C' THEN
	CALL genera_orden_cobro()
END IF

CALL fl_actualiza_estadisticas_item_rep(vg_codcia, vg_codloc, 
			rm_cabt.r19_cod_tran, rm_cabt.r19_num_tran)
	RETURNING hecho
IF NOT hecho THEN
	CALL fgl_winmessage(vg_producto, 'No se pudieron actualizar las estadisticas de items vendidos.', 'stop')
	ROLLBACK WORK
	EXIT PROGRAM
END IF
COMMIT WORK
CALL fl_control_master_contab_repuestos(vg_codcia, vg_codloc, 
		rm_cabt.r19_cod_tran, rm_cabt.r19_num_tran)
CALL fgl_winquestion(vg_producto,'Desea ver factura generada','Yes','Yes|No|Cancel','question',1)
	RETURNING resp
IF resp = 'Yes' THEN
	LET comando = 'fglrun repp308 ', vg_base, ' ', vg_modulo, ' ', 
			vg_codcia, ' ', vg_codloc, ' ', rm_cabt.r19_cod_tran,
			' ', rm_cabt.r19_num_tran  
	RUN comando
END IF

END FUNCTION



FUNCTION retorna_cliente_final()
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE codcli		LIKE rept023.r23_codcli

	CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_r00.*

	-- Puede pasar que la preventa no tenga un codigo de cliente,
	-- en ese caso facturar a r00_cliente_final
	IF rm_cprev.r23_codcli IS NULL THEN
		LET codcli = r_r00.r00_cliente_final
	ELSE
   		LET codcli = rm_cprev.r23_codcli
	END IF
	RETURN codcli
END FUNCTION



FUNCTION genera_orden_cobro()
DEFINE r_z24				RECORD LIKE cxct024.*
DEFINE r_z25				RECORD LIKE cxct025.*
DEFINE r_j10				RECORD LIKE cajt010.*

	INITIALIZE r_z24.* TO NULL
	LET r_z24.z24_compania   = rm_cabt.r19_compania
	LET r_z24.z24_localidad  = rm_cabt.r19_localidad
	LET r_z24.z24_areaneg    = rm_ccaj.j10_areaneg
	LET r_z24.z24_linea      = rm_cprev.r23_grupo_linea
	LET r_z24.z24_codcli     = retorna_cliente_final()
	LET r_z24.z24_tipo       = 'P'
	LET r_z24.z24_estado     = 'A'
	LET r_z24.z24_referencia = 'COBRO FACTURA CONTADO - ' || rm_cabt.r19_nomcli
	LET r_z24.z24_moneda     = rm_ccaj.j10_moneda
	LET r_z24.z24_paridad    = 1
	LET r_z24.z24_tasa_mora  = 0
	LET r_z24.z24_total_cap  = rm_cabt.r19_tot_neto
	LET r_z24.z24_total_int  = 0
	LET r_z24.z24_total_mora = 0
	LET r_z24.z24_subtipo    = 1 
	LET r_z24.z24_usuario    = vg_usuario
	LET r_z24.z24_fecing     = CURRENT

	SELECT MAX(z05_codigo) INTO r_z24.z24_cobrador
	  FROM cxct005 
	 WHERE z05_compania = rm_cabt.r19_compania
	   AND z05_estado   = 'A'
	   AND z05_tipo     = 'J'

	SELECT MAX(z24_numero_sol) INTO r_z24.z24_numero_sol
	  FROM cxct024 
	 WHERE z24_compania  = rm_cabt.r19_compania
	   AND z24_localidad = rm_cabt.r19_localidad
	IF r_z24.z24_numero_sol IS NULL THEN
		LET r_z24.z24_numero_sol = 0
	END IF
	LET r_z24.z24_numero_sol = r_z24.z24_numero_sol + 1

	INSERT INTO cxct024 VALUES (r_z24.*)

	INITIALIZE r_z25.* TO NULL
	LET r_z25.z25_compania   = r_z24.z24_compania 
	LET r_z25.z25_localidad  = r_z24.z24_localidad
	LET r_z25.z25_numero_sol = r_z24.z24_numero_sol
	LET r_z25.z25_orden      = 1
	LET r_z25.z25_codcli     = r_z24.z24_codcli    
	LET r_z25.z25_tipo_doc   = rm_cabt.r19_cod_tran      
	LET r_z25.z25_num_doc    = rm_cabt.r19_num_tran      
	LET r_z25.z25_dividendo  = 1
	LET r_z25.z25_valor_cap  = rm_cabt.r19_tot_neto   
	LET r_z25.z25_valor_int  = 0
	LET r_z25.z25_valor_mora = 0   
	INSERT INTO cxct025 VALUES (r_z25.*)

	-- CREA REGISTRO DE CAJA
	INITIALIZE r_j10.* TO NULL
	LET r_j10.j10_compania     = rm_cabt.r19_compania 
	LET r_j10.j10_localidad    = rm_cabt.r19_localidad
	LET r_j10.j10_tipo_fuente  = 'SC'
	LET r_j10.j10_num_fuente   = r_z25.z25_numero_sol
	LET r_j10.j10_areaneg      = r_z24.z24_areaneg 
	LET r_j10.j10_estado       = 'A' 
	LET r_j10.j10_codcli       = retorna_cliente_final()
	LET r_j10.j10_nomcli       = rm_cabt.r19_nomcli
	LET r_j10.j10_moneda       = rm_cabt.r19_moneda
	LET r_j10.j10_valor        = rm_cabt.r19_tot_neto
	LET r_j10.j10_referencia   = r_z24.z24_referencia
	LET r_j10.j10_fecha_pro    = CURRENT
	LET r_j10.j10_usuario      = vg_usuario 
	LET r_j10.j10_fecing       = CURRENT
	INSERT INTO cajt010 VALUES (r_j10.*)

END FUNCTION



FUNCTION valida_preventa()

DEFINE r_z01			RECORD LIKE cxct001.*
DEFINE resp			VARCHAR(6)

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
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe preventa en Caja', 'stop')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Registro de Caja está bloqueado por otro usuario', 'stop')
	EXIT PROGRAM
END IF
IF rm_ccaj.j10_estado <> "A" THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Registro en Caja no esta activo.', 'stop')
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
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe preventa', 'stop')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Preventa está bloqueada por otro usuario', 'stop')
	EXIT PROGRAM
END IF
IF rm_cprev.r23_estado <> 'P' THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Preventa no tiene estado de aprobada', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
IF rm_cprev.r23_codcli IS NOT NULL THEN
	INITIALIZE r_z01.* TO NULL
	CALL fl_lee_cliente_general(rm_cprev.r23_codcli) RETURNING r_z01.*
	IF fl_validar_cedruc_dig_ver(r_z01.z01_tipo_doc_id, r_z01.z01_num_doc_id) = 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
END IF

END FUNCTION



FUNCTION verifica_forma_pago()
DEFINE valor_aux	DECIMAL(14,2)
DEFINE r_r27		RECORD LIKE rept027.*
DEFINE r_z21		RECORD LIKE cxct021.*

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
		CALL fgl_winmessage(vg_producto, 'Preventa no tiene registro de forma de pago', 'stop')
		EXIT PROGRAM
	END IF
	IF rm_cpago.r25_valor_cred <= 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor crédito incorrecto en registro de forma de pago', 'stop')
		EXIT PROGRAM
	END IF
	IF rm_cprev.r23_tot_neto <> rm_cpago.r25_valor_cred + 
				    rm_cpago.r25_valor_ant THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor crédito más valores a favor es distinto del valor de la factura', 'stop')
		EXIT PROGRAM
	END IF
ELSE
	IF rm_cpago.r25_valor_cred > 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Preventa es de contado y tiene valor crédito especificado', 'stop')
		EXIT PROGRAM
	END IF
	IF rm_cprev.r23_tot_neto < rm_cpago.r25_valor_ant THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor a favor es mayor que valor factura', 'stop')
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
		CALL fgl_winmessage(vg_producto, 'No cuadra total crédito de cabecera con el detalle', 'stop')
		EXIT PROGRAM
	END IF
END IF
SELECT SUM(r27_valor) INTO valor_aux FROM rept027
	WHERE r27_compania  = vg_codcia AND 
      	      r27_localidad = vg_codloc AND 
      	      r27_numprev   = vm_preventa
IF rm_cpago.r25_valor_ant = 0 AND valor_aux > 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Total anticipos en cabecera es 0, y en el detalle es mayor que 0. Revise preventa.', 'stop')
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
			CALL fgl_winmessage(vg_producto, 'No existe documento '
				|| 'a favor: ' 
				|| r_r27.r27_tipo
				|| '-'
				|| r_r27.r27_numero, 'stop')
			EXIT PROGRAM
		END IF
		IF r_r27.r27_valor > r_z21.z21_saldo THEN
			ROLLBACK WORK
			CALL fgl_winmessage(vg_producto, 'Saldo de documento '
				|| 'a favor: ' 
				|| r_r27.r27_tipo
				|| '-'
				|| r_r27.r27_numero 
				|| 'es menor que valor a aplicar.', 'stop')
			EXIT PROGRAM
		END IF
	END FOREACH
	IF valor_aux IS NULL OR valor_aux <> rm_cpago.r25_valor_ant THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'No cuadra total valor a favor de cabecera con el detalle', 'stop')
		EXIT PROGRAM
	END IF
END IF
	
END FUNCTION



FUNCTION genera_factura()
DEFINE numero 		INTEGER
DEFINE costo		DECIMAL(14,2)
DEFINE vta_perd		LIKE rept020.r20_cant_ped
DEFINE r 			RECORD LIKE rept024.*
DEFINE r_r13		RECORD LIKE rept013.*
DEFINE r_r116		RECORD LIKE rept116.*
DEFINE r_g21		RECORD LIKE gent021.*


WHENEVER ERROR STOP
SET LOCK MODE TO WAIT
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA', vm_tipo_doc)
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
LET rm_cabt.r19_cod_subtipo	= NULL
LET rm_cabt.r19_cont_cred  	= rm_cprev.r23_cont_cred
LET rm_cabt.r19_ped_cliente	= rm_cprev.r23_ped_cliente
LET rm_cabt.r19_referencia 	= rm_cprev.r23_referencia
LET rm_cabt.r19_codcli 		= rm_cprev.r23_codcli
LET rm_cabt.r19_nomcli 		= rm_cprev.r23_nomcli
LET rm_cabt.r19_dircli 		= rm_cprev.r23_dircli
LET rm_cabt.r19_telcli 		= rm_cprev.r23_telcli
LET rm_cabt.r19_cedruc 		= rm_cprev.r23_cedruc
LET rm_cabt.r19_vendedor 	= rm_cprev.r23_vendedor
LET rm_cabt.r19_oc_externa 	= rm_cprev.r23_ord_compra
LET rm_cabt.r19_oc_interna 	= NULL
LET rm_cabt.r19_ord_trabajo	= NULL
LET rm_cabt.r19_descuento 	= rm_cprev.r23_descuento
LET rm_cabt.r19_porc_impto 	= rm_cprev.r23_porc_impto
LET rm_cabt.r19_tipo_dev   	= NULL
LET rm_cabt.r19_num_dev    	= NULL
LET rm_cabt.r19_bodega_ori 	= rm_cprev.r23_bodega
LET rm_cabt.r19_bodega_dest	= rm_cprev.r23_bodega
LET rm_cabt.r19_fact_costo 	= NULL
LET rm_cabt.r19_fact_venta 	= NULL
LET rm_cabt.r19_moneda     	= rm_cprev.r23_moneda
LET rm_cabt.r19_paridad 	= rm_cprev.r23_paridad
LET rm_cabt.r19_precision  	= rm_cprev.r23_precision
LET rm_cabt.r19_tot_costo  	= 0 
LET rm_cabt.r19_tot_bruto  	= rm_cprev.r23_tot_bruto
LET rm_cabt.r19_tot_dscto  	= rm_cprev.r23_tot_dscto
LET rm_cabt.r19_tot_neto 	= rm_cprev.r23_tot_neto
LET rm_cabt.r19_flete 		= rm_cprev.r23_flete
LET rm_cabt.r19_numliq 		= NULL
LET rm_cabt.r19_usuario 	= vg_usuario
LET rm_cabt.r19_fecing 		= CURRENT

CALL fl_lee_cod_transaccion(vm_tipo_doc) RETURNING r_g21.*
LET rm_cabt.r19_tipo_tran  = r_g21.g21_tipo
LET rm_cabt.r19_calc_costo = r_g21.g21_calc_costo

INSERT INTO rept019 VALUES (rm_cabt.*)

WHENEVER ERROR STOP
SET LOCK MODE TO WAIT 1
DECLARE q_dprev CURSOR FOR SELECT * FROM rept024
	WHERE r24_compania  = vg_codcia AND 
	      r24_localidad = vg_codloc AND 
	      r24_numprev   = vm_preventa
	ORDER BY r24_orden
WHENEVER ERROR CONTINUE

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

	-- Si la configuracion no permite facturar sin stock, debo chequear el
	-- disponible
	IF vm_fact_sstock = 'N' THEN
		IF r.r24_cant_ven >
		   r.r24_cant_ven + fl_lee_stock_disponible_rep(vg_codcia, vg_codloc,
														r.r24_item, 'R')
		THEN
			CALL fgl_winmessage(vg_producto, 'Item ' || r.r24_item CLIPPED ||
											 ' no tiene stock suficiente.',
								'stop')
			EXIT PROGRAM
		END IF
	END IF

	CALL fl_lee_stock_rep(r.r24_compania, rm_cabt.r19_bodega_ori, r.r24_item)
		RETURNING rm_stock.*
   	LET rm_dett.r20_compania 	= vg_codcia
   	LET rm_dett.r20_localidad 	= vg_codloc
   	LET rm_dett.r20_cod_tran 	= rm_cabt.r19_cod_tran
   	LET rm_dett.r20_num_tran 	= rm_cabt.r19_num_tran
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
	IF rm_stock.r11_ubicacion IS NULL THEN
   		LET rm_dett.r20_ubicacion 	= 'SN'
   		LET rm_dett.r20_stock_ant 	= 0 
 	ELSE
   		LET rm_dett.r20_ubicacion 	= rm_stock.r11_ubicacion
   		LET rm_dett.r20_stock_ant 	= rm_stock.r11_stock_act + r.r24_cant_ven
	END IF
   	LET rm_dett.r20_costant_mb 	= rm_item.r10_costo_mb
   	LET rm_dett.r20_costant_ma 	= rm_item.r10_costo_ma
   	LET rm_dett.r20_costnue_mb 	= rm_item.r10_costo_mb
   	LET rm_dett.r20_costnue_ma 	= rm_item.r10_costo_ma
   	LET rm_dett.r20_stock_bd 	= 0
   	LET rm_dett.r20_fecing 		= CURRENT
	INSERT INTO rept020 VALUES (rm_dett.*)

	{*
	 * Se graba un registro indicando que hay algo pendiente de entrega en la 
	 * rept116. El valor en la rept116.r116_cantidad debe ser igual a 
	 * rept020.r20_cant_ven - rept020.r20_cant_ent
	 *}
	INITIALIZE r_r116.* TO NULL
	LET r_r116.r116_compania  = rm_dett.r20_compania
	LET r_r116.r116_localidad = rm_dett.r20_localidad
	LET r_r116.r116_cod_tran  = rm_dett.r20_cod_tran
	LET r_r116.r116_num_tran  = rm_dett.r20_num_tran
	LET r_r116.r116_item      = rm_dett.r20_item
	LET r_r116.r116_item_fact = rm_dett.r20_item
	LET r_r116.r116_cantidad  = rm_dett.r20_cant_ven
	INSERT INTO rept116 VALUES (r_r116.*)
	
	{*
	 * Esto es para mantener un registro de las ventas perdidas
	 *}
	LET vta_perd = rm_dett.r20_cant_ped - rm_dett.r20_cant_ven
	{*
	 * Si la cantidad pedida es diferente a la cantidad vendida hay 
	 * ventas perdidas y debe grabarse un registro en la rept013.
	 * Grabo aunque la diferencia sea negativa, hago esto para detectar 
	 * si hay una falla en la preventa. 
	 *}
	IF vta_perd <> 0 THEN
		LET r_r13.r13_serial       = 0 
		LET r_r13.r13_compania     = rm_dett.r20_compania
		LET r_r13.r13_localidad    = rm_dett.r20_localidad 
		LET r_r13.r13_bodega       = rm_cabt.r19_bodega_ori
		LET r_r13.r13_item         = rm_dett.r20_item
		LET r_r13.r13_estado       = 'A' 
		LET r_r13.r13_cantidad     = vta_perd
		LET r_r13.r13_referencia   = rm_cabt.r19_nomcli 
		LET r_r13.r13_cod_tran     = rm_cabt.r19_cod_tran
		LET r_r13.r13_num_tran     = rm_cabt.r19_num_tran  
		LET r_r13.r13_usuario      = vg_usuario
		LET r_r13.r13_fecing       = CURRENT  

		INSERT INTO rept013 VALUES (r_r13.*)
	END IF
	CALL fl_proceso_despues_insertar_linea_tr_rep(vg_codcia, vg_codloc, 
							rm_dett.r20_cod_tran, rm_dett.r20_num_tran, 
							rm_dett.r20_item)

END FOREACH

UPDATE rept019 SET r19_tot_costo = vm_tot_costo
 WHERE r19_compania  = rm_cabt.r19_compania
   AND r19_localidad = rm_cabt.r19_localidad
   AND r19_cod_tran  = rm_cabt.r19_cod_tran
   AND r19_num_tran  = rm_cabt.r19_num_tran

END FUNCTION



FUNCTION genera_cuenta_por_cobrar()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r		RECORD LIKE rept026.*

WHENEVER ERROR STOP
IF rm_cpago.r25_valor_cred > 0 THEN
	-- Esto es a credito
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
	   	LET r_doc.z20_fecha_emi = TODAY
	   	LET r_doc.z20_fecha_vcto= r.r26_fec_vcto
	   	LET r_doc.z20_tasa_int  = rm_cpago.r25_interes
	   	LET r_doc.z20_tasa_mora = 0
	   	LET r_doc.z20_moneda 	= rm_cprev.r23_moneda
	   	LET r_doc.z20_paridad 	= rm_cprev.r23_paridad
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
	   	LET r_doc.z20_fecing 	= CURRENT
		INSERT INTO cxct020 VALUES (r_doc.*)
	END FOREACH
ELSE
	-- Esto es al contado
	INITIALIZE r_doc.* TO NULL
   	LET r_doc.z20_compania	= vg_codcia
   	LET r_doc.z20_localidad = vg_codloc
	LET r_doc.z20_codcli    = retorna_cliente_final()
   	LET r_doc.z20_tipo_doc 	= rm_cabt.r19_cod_tran
   	LET r_doc.z20_num_doc 	= rm_cabt.r19_num_tran
   	LET r_doc.z20_dividendo = 1 
   	LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
   	LET r_doc.z20_referencia= rm_cprev.r23_referencia
   	LET r_doc.z20_fecha_emi = TODAY
   	LET r_doc.z20_fecha_vcto= TODAY 
   	LET r_doc.z20_tasa_int  = 0 
   	LET r_doc.z20_tasa_mora = 0
   	LET r_doc.z20_moneda 	= rm_cprev.r23_moneda
   	LET r_doc.z20_paridad 	= rm_cprev.r23_paridad
   	LET r_doc.z20_valor_cap = rm_cabt.r19_tot_neto 
   	LET r_doc.z20_valor_int = 0 
   	LET r_doc.z20_saldo_cap = rm_cabt.r19_tot_neto 
   	LET r_doc.z20_saldo_int = 0
 	LET r_doc.z20_cartera 	= 10
   	LET r_doc.z20_linea 	= rm_cprev.r23_grupo_linea
   	LET r_doc.z20_origen 	= 'A'
   	LET r_doc.z20_cod_tran  = rm_cabt.r19_cod_tran
   	LET r_doc.z20_num_tran  = rm_cabt.r19_num_tran
   	LET r_doc.z20_usuario 	= vg_usuario
   	LET r_doc.z20_fecing 	= CURRENT
	INSERT INTO cxct020 VALUES (r_doc.*)
END IF

END FUNCTION



FUNCTION actualiza_documentos_favor()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_caju		RECORD LIKE cxct022.*
DEFINE r_daju		RECORD LIKE cxct023.*
DEFINE r		RECORD LIKE rept027.*
DEFINE numero		INTEGER
DEFINE i 		SMALLINT
DEFINE valor_aux	DECIMAL(14,2)

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
LET r_doc.z20_fecha_emi = TODAY
LET r_doc.z20_fecha_vcto= TODAY 
LET r_doc.z20_tasa_int  = 0
LET r_doc.z20_tasa_mora = 0
LET r_doc.z20_moneda 	= rm_cprev.r23_moneda
LET r_doc.z20_paridad 	= rm_cprev.r23_paridad
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
LET r_doc.z20_fecing 	= CURRENT
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
LET r_caju.z22_fecha_emi 	= TODAY
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
LET r_caju.z22_fecing 		= CURRENT
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
		CALL fgl_winmessage(vg_producto, 'Valor de documento <= 0: ' || r.r27_tipo || ' ' || r.r27_numero, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'No se procesaron documentos a favor', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION

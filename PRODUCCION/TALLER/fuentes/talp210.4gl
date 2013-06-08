------------------------------------------------------------------------------
-- Titulo           : talp210.4gl - Actualizaciones por Emisión Factura
-- Elaboracion      : 30-oct-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun talp210.4gl base_datos compañía localidad orden
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_orden		LIKE talt023.t23_orden
DEFINE vm_tipo_doc	CHAR(2)
DEFINE vm_tot_costo	DECIMAL(14,2)
DEFINE rm_ccaj		RECORD LIKE cajt010.*
DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE rm_cpago		RECORD LIKE talt025.*
DEFINE rm_lin		RECORD LIKE talt001.*
DEFINE rm_mod		RECORD LIKE talt004.*
DEFINE rm_t60		RECORD LIKE talt060.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp210.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_codcia  = arg_val(2)
LET vg_codloc  = arg_val(3)
LET vm_orden   = arg_val(4)
LET vg_modulo  = 'TA'
LET vg_proceso = 'talp210'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fl_validar_parametros()
CALL control_master_caja()

END MAIN



FUNCTION control_master_caja()
DEFINE resp		CHAR(10)
DEFINE param		VARCHAR(60)

LET vm_tipo_doc = 'FA'
--CALL facturar_proformas_inventario()
CALL chequear_proformas_facturadas()
BEGIN WORK
CALL valida_orden()
CALL verifica_forma_pago()
CALL fl_lee_tipo_vehiculo(vg_codcia, rm_ord.t23_modelo) RETURNING rm_mod.*
CALL fl_lee_linea_taller(vg_codcia, rm_mod.t04_linea) RETURNING rm_lin.*
CALL genera_factura()
IF rm_cpago.t25_valor_cred > 0 THEN
	CALL genera_cuenta_por_cobrar()
END IF
IF rm_cpago.t25_valor_ant > 0 THEN
	CALL actualiza_documentos_favor()
END IF
IF rm_cpago.t25_valor_cred > 0 OR rm_cpago.t25_valor_ant > 0 THEN
	CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc,
					rm_ord.t23_cod_cliente)
END IF
IF rm_ord.t23_cont_cred = 'C' THEN
	CALL verifica_pago_tarjeta_credito()
END IF
UPDATE cajt010 SET j10_estado = 'P',
		   j10_tipo_destino = vm_tipo_doc,
		   j10_num_destino  = rm_ord.t23_num_factura,
		   j10_fecha_pro    = CURRENT
	WHERE CURRENT OF q_ccaj
CALL fl_actualiza_estadisticas_taller(vg_codcia, vg_codloc, vm_orden, 'S')
CALL fl_actualiza_estadisticas_mecanicos(vg_codcia, vg_codloc, vm_orden, 'S')
CALL genera_transferencia_retorno()
COMMIT WORK
CALL fl_control_master_contab_taller(vg_codcia, vg_codloc, vm_orden, 'F')
IF rm_t60.t60_compania IS NOT NULL THEN
	DROP TABLE te_transf_gen
	RETURN
END IF
CALL fl_hacer_pregunta('Desea ver factura generada','Yes') RETURNING resp
IF resp = 'Yes' THEN
	LET param = vg_codloc, ' ', rm_ord.t23_num_factura
	CALL ejecuta_comando('TALLER', vg_modulo, 'talp308 ', param)
END IF
CALL imprimir_transferencia()
DROP TABLE te_transf_gen

END FUNCTION



FUNCTION retorna_reg_refact()

INITIALIZE rm_t60.* TO NULL
DECLARE q_t60 CURSOR FOR
	SELECT * FROM talt060
		WHERE t60_compania  = vg_codcia
		  AND t60_localidad = vg_codloc
		  AND t60_ot_nue    = rm_ord.t23_orden
OPEN q_t60
FETCH q_t60 INTO rm_t60.*
CLOSE q_t60
FREE q_t60

END FUNCTION



FUNCTION valida_orden()

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
DECLARE q_ccaj CURSOR FOR
	SELECT * FROM cajt010 
		WHERE j10_compania    = vg_codcia AND 
		      j10_localidad   = vg_codloc AND 
		      j10_tipo_fuente = 'OT' AND 
		      j10_num_fuente  = vm_orden
 		FOR UPDATE 
OPEN q_ccaj 
FETCH q_ccaj INTO rm_ccaj.*
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe orden en Caja.','exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Registro de Caja está bloqueado por otro usuario.','exclamation')
	EXIT PROGRAM
END IF
IF rm_ccaj.j10_estado <> "*" THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Registro en Caja no tiene estado *', 'exclamation')
	EXIT PROGRAM
END IF
DECLARE q_ord CURSOR FOR
	SELECT * FROM talt023 
		WHERE t23_compania  = vg_codcia AND
		      t23_localidad = vg_codloc AND
		      t23_orden     = vm_orden
		FOR UPDATE
OPEN q_ord
FETCH q_ord INTO rm_ord.*
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe orden.','exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Orden está bloqueada por otro usuario.','exclamation')
	EXIT PROGRAM
END IF
IF rm_ord.t23_estado <> 'C' THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Orden no tiene estado de cerrada.','exclamation')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

END FUNCTION



FUNCTION verifica_forma_pago()
DEFINE valor_aux	DECIMAL(14,2)
DEFINE r		RECORD LIKE talt005.*
DEFINE r_t27		RECORD LIKE talt027.*
DEFINE r_z21		RECORD LIKE cxct021.*

WHENEVER ERROR STOP
CALL fl_lee_tipo_orden_taller(vg_codcia, rm_ord.t23_tipo_ot)
	RETURNING r.*
IF r.t05_factura <> 'S' THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Tipo de orden no se factura.','exclamation')
	EXIT PROGRAM
END IF
INITIALIZE rm_cpago TO NULL
LET rm_cpago.t25_valor_cred = 0
LET rm_cpago.t25_valor_ant  = 0
SELECT * INTO rm_cpago.* FROM talt025 
	WHERE t25_compania  = vg_codcia AND 
	      t25_localidad = vg_codloc AND 
	      t25_orden     = vm_orden
IF rm_ord.t23_cont_cred = 'R' THEN
	IF rm_cpago.t25_compania IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Orden no tiene registro de forma de pago.','exclamation')
		EXIT PROGRAM
	END IF
	IF rm_cpago.t25_valor_cred <= 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor crédito incorrecto en registro de forma de pago.','exclamation')
		EXIT PROGRAM
	END IF
	IF rm_ord.t23_tot_neto <> rm_cpago.t25_valor_cred + 
				  rm_cpago.t25_valor_ant THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor crédito más valores a favor es distinto del valor de la factura.','exclamation')
		EXIT PROGRAM
	END IF
ELSE
	IF rm_cpago.t25_valor_cred > 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Orden es de contado y tiene valor crédito especificado.','exclamation')
		EXIT PROGRAM
	END IF
	IF rm_ord.t23_tot_neto < rm_cpago.t25_valor_ant THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor a favor es mayor que valor factura.','exclamation')
		EXIT PROGRAM
	END IF
END IF
IF rm_cpago.t25_valor_cred > 0 THEN
	SELECT SUM(t26_valor_cap) INTO valor_aux FROM talt026
		WHERE t26_compania  = vg_codcia AND 
		      t26_localidad = vg_codloc AND 
		      t26_orden     = vm_orden
	IF valor_aux IS NULL OR valor_aux <> rm_cpago.t25_valor_cred THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No cuadra total crédito de cabecera con el detalle.','exclamation')
		EXIT PROGRAM
	END IF
END IF
IF rm_cpago.t25_valor_ant > 0 THEN
	DECLARE qu_lote CURSOR FOR
		SELECT * FROM talt027
			WHERE t27_compania  = vg_codcia AND 
		      	      t27_localidad = vg_codloc AND 
		      	      t27_orden     = vm_orden
	LET valor_aux = 0
	FOREACH qu_lote INTO r_t27.*
		LET valor_aux = valor_aux + r_t27.t27_valor
		CALL fl_lee_documento_favor_cxc(vg_codcia, vg_codloc, 
			rm_ord.t23_cod_cliente, r_t27.t27_tipo,r_t27.t27_numero)
			RETURNING r_z21.*
		IF r_z21.z21_compania IS NULL THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No existe documento '
				|| 'a favor: ' 
				|| r_t27.t27_tipo
				|| '-'
				|| r_t27.t27_numero, 'stop')
			EXIT PROGRAM
		END IF
		IF r_t27.t27_valor > r_z21.z21_saldo THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Saldo de documento '
				|| 'a favor: ' 
				|| r_t27.t27_tipo
				|| '-'
				|| r_t27.t27_numero 
				|| 'es menor que valor a aplicar.', 'stop')
			EXIT PROGRAM
		END IF
	END FOREACH
	IF valor_aux IS NULL OR valor_aux <> rm_cpago.t25_valor_ant THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No cuadra total valor a favor de cabecera con el detalle.','exclamation')
		EXIT PROGRAM
	END IF
END IF
	
END FUNCTION



FUNCTION genera_factura()
DEFINE numero 		INTEGER
DEFINE costo		DECIMAL(14,2)

WHENEVER ERROR STOP
SET LOCK MODE TO WAIT
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'TA', 'AA',
					vm_tipo_doc)
	RETURNING numero
IF numero <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_ord.t23_num_factura = numero
LET rm_ord.t23_fec_factura = CURRENT
UPDATE talt023 SET t23_estado      = 'F',
		   t23_num_factura = numero,
		   t23_fec_factura = CURRENT
	WHERE CURRENT OF q_ord
CALL obtener_usuario_por_refacturacion()
IF rm_t60.t60_compania IS NULL THEN
	RETURN
END IF
UPDATE talt023 SET t23_usuario = rm_ord.t23_usuario WHERE CURRENT OF q_ord

END FUNCTION



FUNCTION genera_cuenta_por_cobrar()
DEFINE r_doc, r_z20	RECORD LIKE cxct020.*
DEFINE r		RECORD LIKE talt026.*

WHENEVER ERROR STOP
DECLARE q_dcred CURSOR FOR 
	SELECT * FROM talt026
		WHERE t26_compania  = vg_codcia AND
	      	      t26_localidad = vg_codloc AND
	      	      t26_orden     = vm_orden
		ORDER BY t26_dividendo
FOREACH q_dcred INTO r.*
	INITIALIZE r_doc.* TO NULL
    	LET r_doc.z20_compania	= vg_codcia
    	LET r_doc.z20_localidad = vg_codloc
    	LET r_doc.z20_codcli 	= rm_ord.t23_cod_cliente
    	LET r_doc.z20_tipo_doc 	= vm_tipo_doc
    	LET r_doc.z20_num_doc 	= rm_ord.t23_num_factura
    	LET r_doc.z20_dividendo = r.t26_dividendo
    	LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
    	LET r_doc.z20_referencia= NULL
    	LET r_doc.z20_fecha_emi = TODAY
    	LET r_doc.z20_fecha_vcto= r.t26_fec_vcto
    	LET r_doc.z20_tasa_int  = rm_cpago.t25_interes
    	LET r_doc.z20_tasa_mora = 0
    	LET r_doc.z20_moneda 	= rm_ord.t23_moneda
    	LET r_doc.z20_paridad 	= rm_ord.t23_paridad
    	LET r_doc.z20_val_impto = 0
    	LET r_doc.z20_valor_cap = r.t26_valor_cap
    	LET r_doc.z20_valor_int = r.t26_valor_int
    	LET r_doc.z20_saldo_cap = r.t26_valor_cap
    	LET r_doc.z20_saldo_int = r.t26_valor_int
    	LET r_doc.z20_cartera 	= 1
    	LET r_doc.z20_linea 	= rm_lin.t01_grupo_linea
    	LET r_doc.z20_origen 	= 'A'
    	LET r_doc.z20_cod_tran  = vm_tipo_doc
    	LET r_doc.z20_num_tran  = rm_ord.t23_num_factura
    	LET r_doc.z20_usuario 	= vg_usuario
    	LET r_doc.z20_fecing 	= CURRENT
	WHILE TRUE	
		CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,
					r_doc.z20_codcli,
					r_doc.z20_tipo_doc, r_doc.z20_num_doc,
					r_doc.z20_dividendo)
			RETURNING r_z20.*
		IF r_z20.z20_compania IS NULL THEN
			EXIT WHILE
		END IF
		SQL
			SELECT ROUND($r_doc.z20_num_doc, 0) + 1
				INTO $r_doc.z20_num_doc
				FROM dual
		END SQL
	END WHILE
	INSERT INTO cxct020 VALUES (r_doc.*)
END FOREACH

END FUNCTION



FUNCTION actualiza_documentos_favor()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_caju		RECORD LIKE cxct022.*
DEFINE r_daju		RECORD LIKE cxct023.*
DEFINE r		RECORD LIKE talt027.*
DEFINE numero		INTEGER
DEFINE i 		SMALLINT
DEFINE valor_aux	DECIMAL(14,2)

SET LOCK MODE TO WAIT 1
INITIALIZE r_doc.* TO NULL
LET r_doc.z20_compania	= vg_codcia
LET r_doc.z20_localidad = vg_codloc
LET r_doc.z20_codcli 	= rm_ord.t23_cod_cliente
LET r_doc.z20_tipo_doc 	= vm_tipo_doc
LET r_doc.z20_num_doc 	= rm_ord.t23_num_factura
LET r_doc.z20_dividendo = 00
LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
LET r_doc.z20_referencia= NULL
LET r_doc.z20_fecha_emi = TODAY
LET r_doc.z20_fecha_vcto= TODAY 
LET r_doc.z20_tasa_int  = 0
LET r_doc.z20_tasa_mora = 0
LET r_doc.z20_moneda 	= rm_ord.t23_moneda
LET r_doc.z20_paridad 	= rm_ord.t23_paridad
LET r_doc.z20_val_impto = 0
LET r_doc.z20_valor_cap = rm_cpago.t25_valor_ant
LET r_doc.z20_valor_int = 0
LET r_doc.z20_saldo_cap = 0
LET r_doc.z20_saldo_int = 0
LET r_doc.z20_cartera 	= 1
LET r_doc.z20_linea 	= rm_lin.t01_grupo_linea
LET r_doc.z20_origen 	= 'A'
LET r_doc.z20_cod_tran  = vm_tipo_doc
LET r_doc.z20_num_tran  = rm_ord.t23_num_factura
LET r_doc.z20_usuario 	= vg_usuario
LET r_doc.z20_fecing 	= CURRENT
INSERT INTO cxct020 VALUES (r_doc.*)
LET valor_aux = rm_cpago.t25_valor_ant 
INITIALIZE r_caju.* TO NULL
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', 'AJ')
	RETURNING numero
IF numero <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_caju.z22_compania		= vg_codcia
LET r_caju.z22_localidad 	= vg_codloc
LET r_caju.z22_codcli 		= rm_ord.t23_cod_cliente
LET r_caju.z22_tipo_trn 	= 'AJ'
LET r_caju.z22_num_trn 		= numero
LET r_caju.z22_areaneg 		= rm_ccaj.j10_areaneg
LET r_caju.z22_referencia 	= 'APLICACION ANTICIPO'
LET r_caju.z22_fecha_emi 	= TODAY
LET r_caju.z22_moneda 		= rm_ord.t23_moneda
LET r_caju.z22_paridad 		= rm_ord.t23_paridad
LET r_caju.z22_tasa_mora 	= 0
LET r_caju.z22_total_cap 	= rm_cpago.t25_valor_ant * -1
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
DECLARE q_antd CURSOR FOR 
	SELECT * FROM talt027 
		WHERE t27_compania  = vg_codcia AND
		      t27_localidad = vg_codloc AND
		      t27_orden     = vm_orden
LET i = 0
FOREACH q_antd INTO r.*
	IF r.t27_valor <= 0 THEN
		ROLLBACK WORK
		--CALL fgl_winmessage(vg_producto,'Valor de documento <= 0: ' || r.t27_tipo || ' ' || r.t27_numero, 'stop')
		CALL fl_mostrar_mensaje('Valor de documento <= 0: ' || r.t27_tipo || ' ' || r.t27_numero,'stop')
		EXIT PROGRAM
	END IF
	LET i = i + 1
	INITIALIZE r_daju.* TO NULL
    	LET r_daju.z23_compania 	= vg_codcia
    	LET r_daju.z23_localidad 	= vg_codloc
    	LET r_daju.z23_codcli 		= rm_ord.t23_cod_cliente
    	LET r_daju.z23_tipo_trn 	= r_caju.z22_tipo_trn
    	LET r_daju.z23_num_trn 		= r_caju.z22_num_trn
    	LET r_daju.z23_orden 		= i
    	LET r_daju.z23_areaneg 		= r_caju.z22_areaneg
    	LET r_daju.z23_tipo_doc 	= r_doc.z20_tipo_doc
    	LET r_daju.z23_num_doc 		= r_doc.z20_num_doc
    	LET r_daju.z23_div_doc 		= r_doc.z20_dividendo
    	LET r_daju.z23_tipo_favor 	= r.t27_tipo
    	LET r_daju.z23_doc_favor 	= r.t27_numero
    	LET r_daju.z23_valor_cap 	= r.t27_valor * -1
    	LET r_daju.z23_valor_int 	= 0
    	LET r_daju.z23_valor_mora 	= 0
    	LET r_daju.z23_saldo_cap 	= valor_aux
	LET valor_aux           	= valor_aux - r.t27_valor
    	LET r_daju.z23_saldo_int 	= 0
	INSERT INTO cxct023 VALUES (r_daju.*)
	UPDATE cxct021 SET z21_saldo = z21_saldo - r.t27_valor
		WHERE z21_compania  = vg_codcia AND 
		      z21_localidad = vg_codloc AND 
		      z21_codcli    = rm_ord.t23_cod_cliente AND 
		      z21_tipo_doc  = r.t27_tipo AND
		      z21_num_doc   = r.t27_numero
END FOREACH	
IF i = 0 THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No se procesaron documentos a favor', 'stop')
	CALL fl_mostrar_mensaje('No se procesaron documentos a favor.','stop')
	EXIT PROGRAM
END IF

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
				r_j11.j11_codigo_pago, rm_ord.t23_cont_cred)
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
		LET r_doc.z20_compania   = vg_codcia
		LET r_doc.z20_localidad  = vg_codloc
		LET r_doc.z20_codcli     = r_g10.g10_codcobr
		LET r_doc.z20_tipo_doc   = vm_tipo_doc
		LET r_doc.z20_num_doc    = rm_ord.t23_num_factura
		LET r_doc.z20_dividendo  = dividendo
		LET r_doc.z20_areaneg    = rm_ccaj.j10_areaneg
		LET r_doc.z20_referencia = 'AUI. #: ', r_j11_2.j11_num_ch_aut
		LET r_doc.z20_fecha_emi  = TODAY
		LET r_doc.z20_fecha_vcto = TODAY + 30
		LET r_doc.z20_tasa_int   = 0
		LET r_doc.z20_tasa_mora  = 0
		LET r_doc.z20_moneda 	 = rm_ord.t23_moneda
		LET r_doc.z20_paridad 	 = rm_ord.t23_paridad
		LET r_doc.z20_val_impto  = 0
		LET r_doc.z20_valor_cap  = r_j11_2.j11_valor
		LET r_doc.z20_valor_int  = 0
		LET r_doc.z20_saldo_cap  = r_j11_2.j11_valor
		LET r_doc.z20_saldo_int  = 0
		LET r_doc.z20_cartera 	 = 1
		LET r_doc.z20_linea 	 = rm_lin.t01_grupo_linea
		LET r_doc.z20_origen 	 = 'A'
		LET r_doc.z20_cod_tran   = vm_tipo_doc
		LET r_doc.z20_num_tran   = rm_ord.t23_num_factura
		LET r_doc.z20_usuario 	 = vg_usuario
		LET r_doc.z20_fecing 	 = CURRENT
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



FUNCTION chequear_proformas_facturadas()
DEFINE numprof		LIKE rept021.r21_numprof
DEFINE mensaje		VARCHAR(80)
DEFINE cant		DECIMAL(8,2)

DECLARE qu_profc CURSOR FOR
	SELECT r21_numprof
		FROM rept021
		WHERE r21_compania  = vg_codcia
		  AND r21_localidad = vg_codloc
		  AND r21_num_ot    = vm_orden
		  AND r21_cod_tran  IS NULL
FOREACH qu_profc INTO numprof
	SELECT SUM(r22_cantidad) INTO cant
		FROM rept022
		WHERE r22_compania  = vg_codcia
		  AND r22_localidad = vg_codloc
		  AND r22_numprof   = numprof
	IF cant > 0 THEN
		LET mensaje = 'La proforma: ', numprof, ' no esta facturada.'
		CALL fl_mostrar_mensaje(mensaje,'exclamation')
		EXIT PROGRAM
	END IF
END FOREACH

END FUNCTION



{--
FUNCTION facturar_proformas_inventario()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE numprev		LIKE rept023.r23_numprev
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

DECLARE q_prev CURSOR WITH HOLD FOR
	SELECT r23_numprev
		FROM rept021, rept023
		WHERE r21_compania  = vg_codcia
		  AND r21_localidad = vg_codloc
		  AND r21_num_ot    = vm_orden
		  AND r21_cod_tran  IS NULL
		  AND r23_compania  = r21_compania
		  AND r23_localidad = r21_localidad
		  AND r23_numprof   = r21_numprof
		  AND r23_num_ot    = r21_num_ot
		  AND r23_estado    <> 'F'
		  AND r23_cod_tran  IS NULL
		ORDER BY 1
FOREACH q_prev INTO numprev
	CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, 'PR', numprev)
		RETURNING rm_j10.*
	IF r_j10.j10_estado = 'A' THEN
IF rm_j10.j10_valor > 0 THEN
	CALL graba_detalle()
	CALL actualiza_acumulados_caja('I')
	IF rm_j10.j10_tipo_fuente = 'SC' THEN
		CALL actualiza_cheques_postfechados('B')
	END IF

END IF

-- 2: actualizar el estado de la cabecera a '*' y el codigo de caja

LET done = actualiza_cabecera('*')
IF NOT done THEN
	DELETE FROM tmp_ret
	ROLLBACK WORK
	RETURN 
END IF 

COMMIT WORK
		LET run_prog = '; fglrun '
		IF vg_gui = 0 THEN
			LET run_prog = '; fglgo '
		END IF
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
				'REPUESTOS', vg_separador, 'fuentes',
				vg_separador, run_prog, 'repp211 ', vg_base,
				' ', vg_codcia, ' ', vg_codloc, ' ', numprev
	END IF
	CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, 'PR', numprev)
		RETURNING r_j10.*
	IF r_j10.j10_estado <> 'P' THEN
		EXIT FOREACH
	END IF
END FOREACH

END FUNCTION
--}



FUNCTION genera_transferencia_retorno()
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran 
DEFINE bodega, bodega_d	LIKE rept020.r20_bodega 
DEFINE bod_taller	LIKE rept020.r20_bodega 
DEFINE bodega_det	LIKE rept020.r20_bodega 
DEFINE item		LIKE rept020.r20_item
DEFINE cantidad		DECIMAL(8,2)
DEFINE i		SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r10		RECORD LIKE rept010.*

SELECT r02_codigo INTO bod_taller
	FROM rept002                               
	WHERE r02_compania  = vg_codcia                                 
	  AND r02_localidad = vg_codloc
	  AND r02_estado    = "A"                                      
	  AND r02_area      = "T"                                       
	  AND r02_factura   = "S"                                       
	  AND r02_tipo      = "L"                                       
CREATE TEMP TABLE te_transf_gen(
		 te_cod_tran	CHAR(2),
		 te_num_tran 	DECIMAL(15,0)
	)
CREATE TEMP TABLE te_silvestre
	(te_bodega	CHAR(2),
	 te_item	CHAR(15),
	 te_cantidad 	DECIMAL(8,2))
DECLARE qu_tasmania CURSOR FOR 
	SELECT r19_cod_tran, r19_num_tran, r19_bodega_ori, r19_bodega_dest,
		r20_bodega, r20_item, r20_cant_ven  
		FROM rept019, rept020
		WHERE r19_compania    = vg_codcia AND 
		      r19_localidad   = vg_codloc AND
		      r19_ord_trabajo = vm_orden AND
		      r19_compania    = r20_compania AND
		      r19_localidad   = r20_localidad AND
		      r19_cod_tran    = r20_cod_tran AND
		      r19_num_tran    = r20_num_tran
		ORDER BY r19_cod_tran DESC
LET i = 0
FOREACH qu_tasmania INTO cod_tran, num_tran, bodega, bodega_d, bodega_det, item,
	 cantidad
	IF cod_tran = 'AF' OR cod_tran = 'DF' THEN
		CONTINUE FOREACH
	END IF
	IF cod_tran = 'FA' THEN
		LET bodega = bodega_det
	END IF
	IF (cod_tran = 'FA' AND bodega   <> bod_taller) OR
	   (cod_tran = 'TR' AND bodega_d <> bod_taller AND
	                        bodega   <> bod_taller) THEN
		LET mensaje = 'La transacción: ', cod_tran, '-',
			       num_tran USING '#####&', 
			      ' hace referencia a la bodega: ', bodega,
			      ' que no es la de proceso del taller: ',
			       bod_taller
		ROLLBACK WORK
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	IF cod_tran = 'FA' THEN
		LET cantidad = cantidad * -1
	ELSE
		IF cod_tran <> 'TR' THEN
			LET mensaje = 'Se encontró la siguiente transacción: ', 
		        	       cod_tran, '-',       
		        	       num_tran USING '#####&', 
		        	       ' que no es FA ni TR.' 
			ROLLBACK WORK       
		        CALL fl_mostrar_mensaje(mensaje, 'stop')
		        EXIT PROGRAM           
		END IF
		IF bodega_d <> bod_taller THEN
			LET cantidad = cantidad * -1
		END IF
	END IF
	LET i = i + 1
	SELECT * FROM te_silvestre WHERE te_item   = item
	IF status = NOTFOUND THEN
		INSERT INTO te_silvestre VALUES (bodega, item, cantidad)
	ELSE
		UPDATE te_silvestre SET te_cantidad = te_cantidad + cantidad     
	        	WHERE te_item   = item                     
	END IF
END FOREACH 	
IF i = 0 THEN
	RETURN
END IF
{--
declare qu_lazo cursor for select * from te_silvestre
foreach qu_lazo into bodega, item, cantidad
	display 'bodega: ', bodega
	display 'item  : ', item
	display 'cantid: ', cantidad
end foreach
--}
DECLARE qu_ermel CURSOR FOR
	SELECT te_item, te_cantidad FROM te_silvestre
		WHERE te_cantidad < 0
OPEN qu_ermel
FETCH qu_ermel INTO item, cantidad
IF status <> NOTFOUND THEN
	LET mensaje = 'El item: ', item CLIPPED, ' queda con saldo negativo: ',
			cantidad USING '-----&', '. Revise las facturas y las ',
			'transferencias asociadas a la orden de trabajo.'
	ROLLBACK WORK
	CALL fl_mostrar_mensaje(mensaje, 'stop');
	EXIT PROGRAM
END IF		
SELECT SUM(te_cantidad) INTO cantidad FROM te_silvestre
IF cantidad = 0 THEN
	RETURN
END IF 
DELETE FROM te_silvestre WHERE te_cantidad = 0
DECLARE q_bugs CURSOR FOR SELECT UNIQUE te_bodega 
	FROM te_silvestre
FOREACH q_bugs INTO bodega
	INITIALIZE r_r19.*, r_r20.* TO NULL
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'RE',   
                             'AA', 'TR')                                      
		RETURNING num_tran   
	IF num_tran <= 0 THEN       
		ROLLBACK WORK      
		EXIT PROGRAM      
	END IF       
	LET r_r19.r19_compania	= vg_codcia
	LET r_r19.r19_localidad	= vg_codloc
	LET r_r19.r19_cod_tran 	= 'TR' 
	LET r_r19.r19_num_tran 	= num_tran
	LET r_r19.r19_cont_cred	= 'C'    
	LET r_r19.r19_referencia= 'MATERIAL SOBRANTE DE O.T. ', 
				   vm_orden USING '<<<<<<' CLIPPED
	LET r_r19.r19_codcli 	= rm_ord.t23_cod_cliente  
	LET r_r19.r19_nomcli 	= rm_ord.t23_nom_cliente 
	LET r_r19.r19_dircli 	= '.'
	LET r_r19.r19_telcli 	= rm_ord.t23_tel_cliente
	LET r_r19.r19_cedruc 	= '1'
	DECLARE qu_ven CURSOR FOR
		SELECT r01_codigo FROM rept001
			WHERE r01_compania   = vg_codcia
			  AND r01_estado     = 'A'
			  AND r01_user_owner = rm_ord.t23_usuario
	OPEN qu_ven
	FETCH qu_ven INTO r_r19.r19_vendedor
	CLOSE qu_ven
	FREE qu_ven
	IF r_r19.r19_vendedor IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('El Usuario ' || rm_ord.t23_usuario CLIPPED || ' no tiene Código de Vendedor asignado. Por favor consulte con el ADMINISTRADOR.', 'stop')
		EXIT PROGRAM
	END IF
	LET r_r19.r19_ord_trabajo= rm_ord.t23_orden 
	LET r_r19.r19_descuento  = 0               
	LET r_r19.r19_porc_impto = 0              
	LET r_r19.r19_bodega_ori = bod_taller
	LET r_r19.r19_bodega_dest= bodega
	LET r_r19.r19_moneda 	 = rm_ord.t23_moneda  
	LET r_r19.r19_paridad    = rm_ord.t23_paridad
	LET r_r19.r19_precision  = rm_ord.t23_precision
	LET r_r19.r19_tot_costo  = 0                  
	LET r_r19.r19_tot_bruto  = 0                 
	LET r_r19.r19_tot_dscto  = 0                
	LET r_r19.r19_tot_neto 	 = 0               
	LET r_r19.r19_flete 	 = 0             
	LET r_r19.r19_usuario 	 = vg_usuario   
	LET r_r19.r19_fecing 	 = CURRENT     
	INSERT INTO rept019 VALUES (r_r19.*)  
	DECLARE qu_pikachu CURSOR FOR SELECT te_item, te_cantidad   
		FROM te_silvestre WHERE te_bodega = bodega 
	LET i = 0                                       
	FOREACH qu_pikachu INTO item, cantidad         
		CALL fl_lee_stock_rep(vg_codcia, bod_taller, item)
			RETURNING r_r11.* 
		IF r_r11.r11_compania IS NULL THEN 
			LET r_r11.r11_stock_act = 0
		END IF                            
		LET mensaje = 'ITEM: ', item     
		IF r_r11.r11_stock_act <= 0 THEN
			ROLLBACK WORK
			LET mensaje = mensaje CLIPPED, ' no tiene stock en bodega taller.'
			CALL fl_mostrar_mensaje(mensaje,'stop')
			EXIT PROGRAM 
		END IF 
		IF r_r11.r11_stock_act < cantidad THEN
			ROLLBACK WORK
			LET mensaje = mensaje CLIPPED, ' solo tiene stock: ',
				r_r11.r11_stock_act USING '###&', 
				' y se nesecita: ', cantidad USING '###&'
			CALL fl_mostrar_mensaje(mensaje,'stop')
			EXIT PROGRAM 
		END IF    
		LET i = i + 1
		LET r_r20.r20_compania 	= r_r19.r19_compania   
		LET r_r20.r20_localidad	= r_r19.r19_localidad 
		LET r_r20.r20_cod_tran 	= r_r19.r19_cod_tran 
		LET r_r20.r20_num_tran 	= r_r19.r19_num_tran
		LET r_r20.r20_bodega 	= bodega           
		LET r_r20.r20_item 	= item        
		LET r_r20.r20_orden 	= i         
		LET r_r20.r20_cant_ped 	= cantidad 
		LET r_r20.r20_cant_ven  = cantidad
		LET r_r20.r20_cant_dev 	= 0      
		LET r_r20.r20_cant_ent  = 0     
		LET r_r20.r20_descuento = 0    
		LET r_r20.r20_val_descto= 0   
		CALL fl_lee_item(r_r19.r19_compania, item) 
			RETURNING r_r10.*                 
		LET r_r20.r20_costant_mb= r_r10.r10_costo_mb
		LET r_r20.r20_costant_ma= r_r10.r10_costo_ma
		LET r_r20.r20_costnue_mb= r_r10.r10_costo_mb
		LET r_r20.r20_costnue_ma= r_r10.r10_costo_ma
		IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
			LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
			LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma 
		END IF
		LET r_r20.r20_precio 	= r_r10.r10_precio_mb
		LET r_r20.r20_val_impto = 0  
		LET r_r20.r20_costo 	= r_r10.r10_costo_mb        
		LET r_r20.r20_fob 	= r_r10.r10_fob            
		LET r_r20.r20_linea 	= r_r10.r10_linea         
		LET r_r20.r20_rotacion 	= r_r10.r10_rotacion     
		LET r_r20.r20_ubicacion = '.'                   
		LET r_r20.r20_stock_ant = r_r11.r11_stock_act  
		UPDATE rept011                                
			SET r11_stock_act  = r11_stock_act - cantidad, 
	            	r11_egr_dia    = r11_egr_dia + cantidad   
			WHERE r11_compania = vg_codcia               
			AND   r11_bodega   = bod_taller
			AND   r11_item     = item                  
		CALL fl_lee_stock_rep(vg_codcia, bodega, item) 
			RETURNING r_r11.* 
		IF r_r11.r11_compania IS NULL THEN  
			LET r_r11.r11_stock_act = 0
			INSERT INTO rept011       
				(r11_compania, r11_bodega, r11_item,  
	 			r11_ubicacion, r11_stock_ant,        
	 			r11_stock_act, r11_ing_dia,         
	 			r11_egr_dia)                       
				VALUES(vg_codcia, bodega, 
	       				item, 'SN', 0, 0, 0, 0)         
		END IF                                                 
		LET r_r20.r20_stock_bd  = r_r11.r11_stock_act         
		LET r_r20.r20_fecing    = CURRENT                    
		INSERT INTO rept020 VALUES (r_r20.*)                
		UPDATE rept011                                     
			SET r11_stock_act  = r11_stock_act + cantidad, 
	            	    r11_ing_dia    = r11_ing_dia   + cantidad 
			WHERE r11_compania = vg_codcia               
			AND   r11_bodega   = bodega  
			AND   r11_item     = item                  
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +   
				  	(cantidad * r_r20.r20_costo)
	END FOREACH                                                  
	IF i = 0 THEN                                               
		DELETE FROM rept019 
			WHERE r19_compania  = r_r19.r19_compania  AND 
	              	      r19_localidad = r_r19.r19_localidad AND
	      	      	      r19_cod_tran  = r_r19.r19_cod_tran  AND
	              	      r19_num_tran  = r_r19.r19_num_tran    
	ELSE                                                       
		UPDATE rept019 SET r19_tot_costo = r_r19.r19_tot_costo,
                           	   r19_tot_bruto = r_r19.r19_tot_costo,
                           	   r19_tot_neto  = r_r19.r19_tot_costo 
		     	WHERE r19_compania  = r_r19.r19_compania  AND  
	                      r19_localidad = r_r19.r19_localidad AND 
	                      r19_cod_tran  = r_r19.r19_cod_tran  AND
	                      r19_num_tran  = r_r19.r19_num_tran    
		INSERT INTO te_transf_gen VALUES(r_r19.r19_cod_tran,
						 r_r19.r19_num_tran)
		LET mensaje = 'Se generó la transferencia: ',
				r_r19.r19_num_tran USING "<<<<<<<<<<<&"
		CALL fl_mostrar_mensaje(mensaje, 'info')            
	END IF
END FOREACH

END FUNCTION



FUNCTION imprimir_transferencia()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE resp		CHAR(6)
DEFINE param		VARCHAR(60)
DEFINE cuantos		INTEGER

SELECT COUNT(*) INTO cuantos FROM te_transf_gen
IF cuantos = 0 THEN
	RETURN
END IF
DECLARE q_imp_trans CURSOR FOR
	SELECT rept019.* FROM rept019, te_transf_gen
		WHERE r19_compania    = vg_codcia
		  AND r19_localidad   = vg_codloc
		  AND r19_cod_tran    = 'TR'
		  AND r19_ord_trabajo = rm_ord.t23_orden 
		  AND r19_cod_tran    = te_cod_tran
		  AND r19_num_tran    = te_num_tran
		ORDER BY r19_num_tran
OPEN q_imp_trans
FETCH q_imp_trans INTO r_r19.*
IF STATUS = NOTFOUND THEN
	CLOSE q_imp_trans
	FREE q_imp_trans
	RETURN
END IF
CALL fl_hacer_pregunta('Desea imprimir transferencia de retorno generada ?','Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	CLOSE q_imp_trans
	FREE q_imp_trans
	RETURN
END IF
FOREACH q_imp_trans INTO r_r19.*
	LET param = vg_codloc, ' "', r_r19.r19_cod_tran, '" ',
			r_r19.r19_num_tran
	CALL ejecuta_comando('REPUESTOS', 'RE', 'repp415 ', param)
END FOREACH

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION obtener_usuario_por_refacturacion()
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_j04		RECORD LIKE cajt004.*
DEFINE r_j90		RECORD LIKE cajt090.*

CALL retorna_reg_refact()
IF rm_t60.t60_compania IS NULL THEN
	RETURN
END IF
DECLARE q_j90 CURSOR FOR SELECT * FROM cajt090 WHERE j90_localidad = vg_codloc
FOREACH q_j90 INTO r_j90.*
	SELECT * INTO r_j04.* FROM cajt004
		WHERE j04_compania    = vg_codcia
		  AND j04_localidad   = vg_codloc
		  AND j04_codigo_caja = r_j90.j90_codigo_caja
		  AND j04_fecha_aper  = TODAY
		  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
	  			FROM cajt004
  				WHERE j04_compania    = vg_codcia
  				  AND j04_localidad   = vg_codloc
  				  AND j04_codigo_caja = r_j90.j90_codigo_caja
  				  AND j04_fecha_aper  = TODAY)
	IF STATUS <> NOTFOUND THEN 
		CALL fl_lee_codigo_caja_caja(r_j04.j04_compania,
						r_j04.j04_localidad,
						r_j04.j04_codigo_caja)
			RETURNING r_j02.*
		LET rm_ord.t23_usuario = r_j02.j02_usua_caja
		EXIT FOREACH
	END IF
END FOREACH

END FUNCTION

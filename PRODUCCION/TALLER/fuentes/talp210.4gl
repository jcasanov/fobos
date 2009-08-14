------------------------------------------------------------------------------
-- Titulo           : talp210.4gl - Actualizaciones por Emisión Factura
-- Elaboracion      : 30-oct-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun talp210.4gl base_datos compañía localidad orden
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_orden	LIKE talt023.t23_orden
DEFINE vm_tipo_doc	CHAR(2)
DEFINE vm_tot_costo	DECIMAL(14,2)
DEFINE rm_ccaj		RECORD LIKE cajt010.*
DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE rm_cpago		RECORD LIKE talt025.*
DEFINE rm_lin		RECORD LIKE talt001.*
DEFINE rm_mod		RECORD LIKE talt004.*
DEFINE rm_t00		RECORD LIKE talt000.*


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp210.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_codcia   = arg_val(2)
LET vg_codloc   = arg_val(3)
LET vm_orden    = arg_val(4)
LET vg_modulo   = 'TA'
LET vg_proceso = 'talp210'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL validar_parametros()
CALL control_master_caja()

END MAIN



FUNCTION control_master_caja()
DEFINE resp		CHAR(10)
DEFINE comando		VARCHAR(80)

LET vm_tipo_doc = 'FA'

CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*

BEGIN WORK
CALL valida_orden()
CALL verifica_forma_pago()
CALL fl_lee_tipo_vehiculo(vg_codcia, rm_ord.t23_modelo)
	RETURNING rm_mod.*
CALL fl_lee_linea_taller(vg_codcia, rm_mod.t04_linea)
	RETURNING rm_lin.*
CALL genera_factura()
CALL genera_cuenta_por_cobrar()
IF rm_cpago.t25_valor_ant > 0 THEN
	CALL actualiza_documentos_favor()
END IF
IF rm_ord.t23_cont_cred = 'C' THEN
	CALL genera_orden_cobro()
END IF
UPDATE cajt010 SET j10_estado = 'P',
				   j10_tipo_destino = vm_tipo_doc,
				   j10_num_destino  = rm_ord.t23_num_factura
	WHERE CURRENT OF q_ccaj
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, retorna_cliente_final())
CALL fl_actualiza_estadisticas_taller(vg_codcia, vg_codloc, vm_orden, 'S')
CALL fl_actualiza_estadisticas_mecanicos(vg_codcia, vg_codloc, vm_orden, 'S')
COMMIT WORK
CALL fl_control_master_contab_taller(vg_codcia, vg_codloc, vm_orden, 'F')
CALL fgl_winquestion(vg_producto,'Desea ver factura generada','Yes','Yes|No|Cancel','question',1)
	RETURNING resp
IF resp = 'Yes' THEN
	LET comando = 'fglrun talp204 ', vg_base, ' ', vg_modulo, ' ', 
			vg_codcia, ' ', vg_codloc, ' ', rm_ord.t23_orden, ' O '
	RUN comando
END IF

END FUNCTION



FUNCTION genera_orden_cobro()
DEFINE r_z24				RECORD LIKE cxct024.*
DEFINE r_z25				RECORD LIKE cxct025.*
DEFINE r_j10				RECORD LIKE cajt010.*

	INITIALIZE r_z24.* TO NULL
	LET r_z24.z24_compania   = rm_ord.t23_compania
	LET r_z24.z24_localidad  = rm_ord.t23_localidad
	LET r_z24.z24_areaneg    = rm_ccaj.j10_areaneg
	LET r_z24.z24_linea      = rm_lin.t01_grupo_linea
	LET r_z24.z24_codcli     = retorna_cliente_final()
	LET r_z24.z24_tipo       = 'P'
	LET r_z24.z24_estado     = 'A'
	LET r_z24.z24_referencia = 'COBRO FACTURA CONTADO - ' || rm_ord.t23_nom_cliente
	LET r_z24.z24_moneda     = rm_ccaj.j10_moneda
	LET r_z24.z24_paridad    = 1
	LET r_z24.z24_tasa_mora  = 0
	LET r_z24.z24_total_cap  = rm_ord.t23_tot_neto
	LET r_z24.z24_total_int  = 0
	LET r_z24.z24_total_mora = 0
	LET r_z24.z24_subtipo    = 1 
	LET r_z24.z24_usuario    = vg_usuario
	LET r_z24.z24_fecing     = CURRENT

	SELECT MAX(z05_codigo) INTO r_z24.z24_cobrador
	  FROM cxct005 
	 WHERE z05_compania = rm_ord.t23_compania
	   AND z05_estado   = 'A'
	   AND z05_tipo     = 'J'

	SELECT MAX(z24_numero_sol) INTO r_z24.z24_numero_sol
	  FROM cxct024 
	 WHERE z24_compania  = rm_ord.t23_compania
	   AND z24_localidad = rm_ord.t23_localidad
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
	LET r_z25.z25_tipo_doc   = vm_tipo_doc      
	LET r_z25.z25_num_doc    = rm_ord.t23_num_factura   
	LET r_z25.z25_dividendo  = 1
	LET r_z25.z25_valor_cap  = rm_ord.t23_tot_neto   
	LET r_z25.z25_valor_int  = 0
	LET r_z25.z25_valor_mora = 0   
	INSERT INTO cxct025 VALUES (r_z25.*)

	-- CREA REGISTRO DE CAJA
	INITIALIZE r_j10.* TO NULL
	LET r_j10.j10_compania     = rm_ord.t23_compania 
	LET r_j10.j10_localidad    = rm_ord.t23_localidad
	LET r_j10.j10_tipo_fuente  = 'SC'
	LET r_j10.j10_num_fuente   = r_z25.z25_numero_sol
	LET r_j10.j10_areaneg      = r_z24.z24_areaneg 
	LET r_j10.j10_estado       = 'A' 
	LET r_j10.j10_codcli       = retorna_cliente_final()
	LET r_j10.j10_nomcli       = rm_ord.t23_nom_cliente
	LET r_j10.j10_moneda       = rm_ord.t23_moneda
	LET r_j10.j10_valor        = rm_ord.t23_tot_neto
	LET r_j10.j10_referencia   = r_z24.z24_referencia
	LET r_j10.j10_fecha_pro    = CURRENT
	LET r_j10.j10_usuario      = vg_usuario 
	LET r_j10.j10_fecing       = CURRENT
	INSERT INTO cajt010 VALUES (r_j10.*)

END FUNCTION


FUNCTION valida_orden()

DEFINE r_z01		RECORD LIKE cxct001.*

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
	CALL fgl_winmessage(vg_producto, 'No existe orden en Caja', 'exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Registro de Caja está bloqueado por otro usuario', 'exclamation')
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
	CALL fgl_winmessage(vg_producto, 'No existe orden', 'exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Orden está bloqueada por otro usuario', 'exclamation')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
IF rm_ord.t23_estado <> 'C' THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Orden no tiene estado de cerrada', 'exclamation')
	EXIT PROGRAM
END IF
IF rm_ord.t23_cod_cliente IS NOT NULL THEN
	INITIALIZE r_z01.* TO NULL
	CALL fl_lee_cliente_general(rm_ord.t23_cod_cliente) RETURNING r_z01.*
	IF fl_validar_cedruc_dig_ver(r_z01.z01_tipo_doc_id, r_z01.z01_num_doc_id) = 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
END IF

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
	CALL fgl_winmessage(vg_producto, 'Tipo de orden no se factura', 'exclamation')
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
		CALL fgl_winmessage(vg_producto, 'Orden no tiene registro de forma de pago', 'exclamation')
		EXIT PROGRAM
	END IF
	IF rm_cpago.t25_valor_cred <= 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor crédito incorrecto en registro de forma de pago', 'exclamation')
		EXIT PROGRAM
	END IF
	IF rm_ord.t23_tot_neto <> rm_cpago.t25_valor_cred + 
				  rm_cpago.t25_valor_ant THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor crédito más valores a favor es distinto del valor de la factura', 'exclamation')
		EXIT PROGRAM
	END IF
ELSE
	IF rm_cpago.t25_valor_cred > 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Orden es de contado y tiene valor crédito especificado', 'exclamation')
		EXIT PROGRAM
	END IF
	IF rm_ord.t23_tot_neto < rm_cpago.t25_valor_ant THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor a favor es mayor que valor factura', 'exclamation')
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
		CALL fgl_winmessage(vg_producto, 'No cuadra total crédito de cabecera con el detalle', 'exclamation')
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
			CALL fgl_winmessage(vg_producto, 'No existe documento '
				|| 'a favor: ' 
				|| r_t27.t27_tipo
				|| '-'
				|| r_t27.t27_numero, 'stop')
			EXIT PROGRAM
		END IF
		IF r_t27.t27_valor > r_z21.z21_saldo THEN
			ROLLBACK WORK
			CALL fgl_winmessage(vg_producto, 'Saldo de documento '
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
		CALL fgl_winmessage(vg_producto, 'No cuadra total valor a favor de cabecera con el detalle', 'exclamation')
		EXIT PROGRAM
	END IF
END IF
	
END FUNCTION



FUNCTION genera_factura()
DEFINE numero 		INTEGER
DEFINE costo		DECIMAL(14,2)
DEFINE r_z20		RECORD LIKE cxct020.*

WHENEVER ERROR STOP
SET LOCK MODE TO WAIT

WHILE TRUE
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 
										 'AA', vm_tipo_doc)
		RETURNING numero
	IF numero <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF

	{*
	 * Verifiquemos que el documento no exista ya. Esto puede ocurrir porque 
	 * el numero interno de las facturas se generan de forma independiente
	 * en cada modulo mientras que el modulo de CXC espera que cada cliente
	 * tenga numeros de facturas que no se repitan independientemente del 
	 * modulo del que venga. Para el caso de los clientes a los que se les
	 * factura frecuentemente es pósible que si se repitan los numeros internos
	 * de los diferentes modulos.
	 * Si el documento ya existe no se genera ningun error, solo se pasa al 
	 * siguiente numero interno.
	 *}	
	 CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc, 
	 								  retorna_cliente_final(), vm_tipo_doc,
									  numero, 1)
			RETURNING r_z20.*								  

	-- El documeno no existe continue con el proceso		
	IF r_z20.z20_compania IS NULL THEN
		EXIT WHILE	
	END IF
END WHILE	

LET rm_ord.t23_num_factura = numero
LET rm_ord.t23_fec_factura = CURRENT
UPDATE talt023 SET t23_estado = 'F',
		   t23_num_factura = numero,
		   t23_fec_factura = CURRENT
	WHERE CURRENT OF q_ord

END FUNCTION



FUNCTION genera_cuenta_por_cobrar()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r		RECORD LIKE talt026.*

WHENEVER ERROR STOP
IF rm_cpago.t25_valor_cred > 0 THEN
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

		INSERT INTO cxct020 VALUES (r_doc.*)
	END FOREACH
ELSE
	INITIALIZE r_doc.* TO NULL
    LET r_doc.z20_compania	= vg_codcia
    LET r_doc.z20_localidad = vg_codloc

   	LET r_doc.z20_codcli 	= retorna_cliente_final()

    LET r_doc.z20_tipo_doc 	= vm_tipo_doc
    LET r_doc.z20_num_doc 	= rm_ord.t23_num_factura
    LET r_doc.z20_dividendo = 1 
    LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
    LET r_doc.z20_referencia= NULL
    LET r_doc.z20_fecha_emi = TODAY
    LET r_doc.z20_fecha_vcto= TODAY 
    LET r_doc.z20_tasa_int  = rm_cpago.t25_interes
    LET r_doc.z20_tasa_mora = 0
    LET r_doc.z20_moneda 	= rm_ord.t23_moneda
    LET r_doc.z20_paridad 	= rm_ord.t23_paridad
    LET r_doc.z20_valor_cap = rm_ord.t23_tot_neto 
    LET r_doc.z20_valor_int = 0 
    LET r_doc.z20_saldo_cap = rm_ord.t23_tot_neto 
    LET r_doc.z20_saldo_int = 0
    LET r_doc.z20_cartera 	= 10
    LET r_doc.z20_linea 	= rm_lin.t01_grupo_linea
    LET r_doc.z20_origen 	= 'A'
    LET r_doc.z20_cod_tran  = vm_tipo_doc
    LET r_doc.z20_num_tran  = rm_ord.t23_num_factura
    LET r_doc.z20_usuario 	= vg_usuario
    LET r_doc.z20_fecing 	= CURRENT
	INSERT INTO cxct020 VALUES (r_doc.*)
END IF

END FUNCTION



FUNCTION retorna_cliente_final()
DEFINE codcli		LIKE talt023.t23_cod_cliente

	-- Puede pasar que la OT no tenga un codigo de cliente,
	-- en ese caso facturar a r00_cliente_final
	IF rm_ord.t23_cod_cliente IS NULL THEN
		LET codcli = rm_t00.t00_cliente_final
	ELSE
   		LET codcli = rm_ord.t23_cod_cliente
	END IF
	RETURN codcli
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
		CALL fgl_winmessage(vg_producto, 'Valor de documento <= 0: ' || r.t27_tipo || ' ' || r.t27_numero, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'No se procesaron documentos a favor', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION verifica_pago_tarjeta_credito()
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE r_doc		RECORD LIKE cxct020.*

SELECT * INTO r_j11.* FROM cajt011
	WHERE j11_compania    = rm_ccaj.j10_compania    AND  
	      j11_localidad   = rm_ccaj.j10_localidad   AND  
	      j11_tipo_fuente = rm_ccaj.j10_tipo_fuente AND  
	      j11_num_fuente  = rm_ccaj.j10_num_fuente  AND 
	      j11_codigo_pago = 'TJ'
IF status = NOTFOUND THEN
	RETURN
END IF
CALL fl_lee_tarjeta_credito(r_j11.j11_cod_bco_tarj) RETURNING r_g10.*
IF r_g10.g10_codcobr IS NULL THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Tarjeta de crédito: ' ||
		r_g10.g10_nombre || ' no tiene código cobranzas asignado. '
		|| 'Por favor asígnelo en el módulo de parámetro GENERALES.',
		'stop')
	EXIT PROGRAM
END IF
INITIALIZE r_doc.* TO NULL
LET r_doc.z20_compania	= vg_codcia
LET r_doc.z20_localidad = vg_codloc
LET r_doc.z20_codcli 	= r_g10.g10_codcobr
LET r_doc.z20_tipo_doc 	= vm_tipo_doc
LET r_doc.z20_num_doc 	= rm_ord.t23_num_factura
LET r_doc.z20_dividendo = 01
LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
LET r_doc.z20_referencia= 'AUI. #: ', r_j11.j11_num_ch_aut
LET r_doc.z20_fecha_emi = TODAY
LET r_doc.z20_fecha_vcto= TODAY + 30
LET r_doc.z20_tasa_int  = 0
LET r_doc.z20_tasa_mora = 0
LET r_doc.z20_moneda 	= rm_ord.t23_moneda
LET r_doc.z20_paridad 	= rm_ord.t23_paridad
LET r_doc.z20_valor_cap = r_j11.j11_valor
LET r_doc.z20_valor_int = 0
LET r_doc.z20_saldo_cap = r_j11.j11_valor
LET r_doc.z20_saldo_int = 0
LET r_doc.z20_cartera 	= 1
LET r_doc.z20_linea 	= rm_lin.t01_grupo_linea
LET r_doc.z20_origen 	= 'A'
LET r_doc.z20_cod_tran  = vm_tipo_doc
LET r_doc.z20_num_tran  = rm_ord.t23_num_factura
LET r_doc.z20_usuario 	= vg_usuario
LET r_doc.z20_fecing 	= CURRENT
INSERT INTO cxct020 VALUES (r_doc.*)
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_g10.g10_codcobr)

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

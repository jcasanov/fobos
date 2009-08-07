------------------------------------------------------------------------------
-- Titulo           : cajp204.4gl - Actualizaciones por Ingreso a Caja por
--				    pagos de facturas de clientes.
-- Elaboracion      : 19-Nov-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun cajp204.4gl base_datos compa��a localidad num_sol
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_numsol	LIKE cxct024.z24_numero_sol
DEFINE vm_tipo_doc	CHAR(2)
DEFINE vm_tot_costo	DECIMAL(14,2)
DEFINE rm_ccaj		RECORD LIKE cajt010.*
DEFINE rm_csol		RECORD LIKE cxct024.*
DEFINE rm_cpag		RECORD LIKE cxct022.*

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp204.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_codcia   = arg_val(2)
LET vg_codloc   = arg_val(3)
LET vm_numsol = arg_val(4)
LET vg_modulo   = 'CG'
LET vg_proceso = 'cajp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL validar_parametros()
CALL control_master_caja()

END MAIN



FUNCTION control_master_caja()
DEFINE resp		CHAR(10)
DEFINE comando		VARCHAR(80)

LET vm_tipo_doc = 'PG'
BEGIN WORK
CALL valida_num_solicitud()
CALL genera_ingreso_caja()
UPDATE cxct024 SET z24_estado = 'P'
	WHERE CURRENT OF q_nsol 
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, rm_csol.z24_codcli)
UPDATE cajt010 SET j10_estado = 'P',
		   j10_tipo_destino = rm_cpag.z22_tipo_trn,
		   j10_num_destino  = rm_cpag.z22_num_trn,
		   j10_fecha_pro    = CURRENT
	WHERE CURRENT OF q_ccaj
COMMIT WORK
CALL fl_control_master_contab_ingresos_caja(vg_codcia, vg_codloc, rm_ccaj.j10_tipo_fuente, rm_ccaj.j10_num_fuente)

END FUNCTION



FUNCTION valida_num_solicitud()
DEFINE r_z01		RECORD LIKE cxct001.*

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
DECLARE q_ccaj CURSOR FOR
	SELECT * FROM cajt010 
		WHERE j10_compania    = vg_codcia AND 
		      j10_localidad   = vg_codloc AND 
		      j10_tipo_fuente = 'SC' AND 
		      j10_num_fuente  = vm_numsol
 		FOR UPDATE 
OPEN q_ccaj 
FETCH q_ccaj INTO rm_ccaj.*
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe solicitud en Caja', 'exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Registro de Caja est� bloqueado por otro usuario', 'exclamation')
	EXIT PROGRAM
END IF
IF rm_ccaj.j10_estado <> "*" THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Registro en Caja no tiene estado *', 'exclamation')
	EXIT PROGRAM
END IF
DECLARE q_nsol CURSOR FOR
	SELECT * FROM cxct024 
		WHERE z24_compania   = vg_codcia AND
		      z24_localidad  = vg_codloc AND
		      z24_numero_sol = vm_numsol
		FOR UPDATE
OPEN q_nsol
FETCH q_nsol INTO rm_csol.*
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe solicitud cobro', 'exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Solicitud cobro est� bloqueada por otro usuario', 'exclamation')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
IF rm_csol.z24_tipo <> 'P' THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Solicitud cobro no es por pago de facturas', 'exclamation')
	EXIT PROGRAM
END IF
IF rm_csol.z24_estado <> 'A' THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Solicitud cobro no est� activa', 'exclamation')
	EXIT PROGRAM
END IF

INITIALIZE r_z01.* TO NULL
CALL fl_lee_cliente_general(rm_csol.z24_codcli) RETURNING r_z01.*
IF fl_validar_cedruc_dig_ver(r_z01.z01_tipo_doc_id, r_z01.z01_num_doc_id) = 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION genera_ingreso_caja()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_dpag		RECORD LIKE cxct023.*
DEFINE r		RECORD LIKE cxct025.*
DEFINE numero		INTEGER
DEFINE i 		SMALLINT
DEFINE tot_cap		DECIMAL(14,2)
DEFINE tot_int		DECIMAL(14,2)
DEFINE tot_mora		DECIMAL(14,2)

SET LOCK MODE TO WAIT 1
INITIALIZE rm_cpag.* TO NULL
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', vm_tipo_doc)
	RETURNING numero
IF numero <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_cpag.z22_compania		= vg_codcia
LET rm_cpag.z22_localidad 	= vg_codloc
LET rm_cpag.z22_codcli 		= rm_csol.z24_codcli
LET rm_cpag.z22_tipo_trn 	= vm_tipo_doc
LET rm_cpag.z22_num_trn 		= numero
LET rm_cpag.z22_areaneg 		= rm_ccaj.j10_areaneg
LET rm_cpag.z22_referencia 	= 'SOLICITUD COBRO: ', rm_csol.z24_numero_sol
				   USING '#####&'
LET rm_cpag.z22_fecha_emi 	= TODAY
LET rm_cpag.z22_moneda 		= rm_csol.z24_moneda
LET rm_cpag.z22_paridad 		= rm_csol.z24_paridad
LET rm_cpag.z22_tasa_mora 	= 0
LET rm_cpag.z22_total_cap 	= rm_csol.z24_total_cap
LET rm_cpag.z22_total_int 	= rm_csol.z24_total_int
LET rm_cpag.z22_total_mora 	= rm_csol.z24_total_mora
LET rm_cpag.z22_cobrador 	= rm_csol.z24_cobrador
LET rm_cpag.z22_subtipo 		= NULL
LET rm_cpag.z22_origen 		= 'A'
LET rm_cpag.z22_fecha_elim	= NULL
LET rm_cpag.z22_tiptrn_elim 	= NULL
LET rm_cpag.z22_numtrn_elim 	= NULL
LET rm_cpag.z22_usuario 		= vg_usuario
LET rm_cpag.z22_fecing 		= CURRENT
INSERT INTO cxct022 VALUES (rm_cpag.*)
DECLARE q_ddoc CURSOR FOR 
	SELECT * FROM cxct025 
		WHERE z25_compania   = vg_codcia AND
		      z25_localidad  = vg_codloc AND
		      z25_numero_sol = vm_numsol
		ORDER BY z25_orden
LET i = 0
LET tot_cap  = 0
LET tot_int  = 0
LET tot_mora = 0
FOREACH q_ddoc INTO r.*
	IF r.z25_valor_cap + r.z25_valor_int <= 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor a pagar <= 0', 'stop')
		EXIT PROGRAM
	END IF
	CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc, 
			rm_cpag.z22_codcli, r.z25_tipo_doc, r.z25_num_doc,
			r.z25_dividendo)
		RETURNING r_doc.*
	IF r_doc.z20_compania IS NULL THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'No existe documento: ' || r.z25_tipo_doc || ' ' || r.z25_num_doc || ' ' || r.z25_dividendo, 'stop')
		EXIT PROGRAM
	END IF
	IF r.z25_valor_cap > r_doc.z20_saldo_cap THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor capital a pagar mayor que saldo del documento: ' || r.z25_tipo_doc || ' ' || r.z25_num_doc || ' ' || r.z25_dividendo, 'stop')
		EXIT PROGRAM
	END IF
	IF r.z25_valor_int > r_doc.z20_saldo_int THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor inter�s a pagar mayor que saldo del documento: ' || r.z25_tipo_doc || ' ' || r.z25_num_doc || ' ' || r.z25_dividendo, 'stop')
		EXIT PROGRAM
	END IF
	LET i = i + 1
	INITIALIZE r_dpag.* TO NULL
    	LET r_dpag.z23_compania 	= vg_codcia
    	LET r_dpag.z23_localidad 	= vg_codloc
    	LET r_dpag.z23_codcli 		= rm_csol.z24_codcli
    	LET r_dpag.z23_tipo_trn 	= rm_cpag.z22_tipo_trn
    	LET r_dpag.z23_num_trn 	= rm_cpag.z22_num_trn
    	LET r_dpag.z23_orden 		= i
    	LET r_dpag.z23_areaneg 	= rm_cpag.z22_areaneg
    	LET r_dpag.z23_tipo_doc 	= r_doc.z20_tipo_doc
    	LET r_dpag.z23_num_doc 	= r_doc.z20_num_doc
    	LET r_dpag.z23_div_doc 	= r_doc.z20_dividendo
    	LET r_dpag.z23_tipo_favor 	= NULL
    	LET r_dpag.z23_doc_favor 	= NULL
    	LET r_dpag.z23_valor_cap 	= r.z25_valor_cap  * -1
    	LET r_dpag.z23_valor_int 	= r.z25_valor_int  * -1
    	LET r_dpag.z23_valor_mora 	= r.z25_valor_mora * -1
    	LET r_dpag.z23_saldo_cap 	= r_doc.z20_saldo_cap 
    	LET r_dpag.z23_saldo_int 	= r_doc.z20_saldo_int
	LET tot_cap                     = tot_cap  + r.z25_valor_cap
	LET tot_int                     = tot_int  + r.z25_valor_int
	LET tot_mora                    = tot_mora + r.z25_valor_mora
	INSERT INTO cxct023 VALUES (r_dpag.*)
	UPDATE cxct020 SET z20_saldo_cap = z20_saldo_cap - r.z25_valor_cap,
	                   z20_saldo_int = z20_saldo_int - r.z25_valor_int
		WHERE z20_compania  = vg_codcia AND 
		      z20_localidad = vg_codloc AND 
		      z20_codcli    = rm_csol.z24_codcli AND 
		      z20_tipo_doc  = r_doc.z20_tipo_doc AND
		      z20_num_doc   = r_doc.z20_num_doc  AND
		      z20_dividendo = r_doc.z20_dividendo
END FOREACH	
IF tot_cap <> rm_csol.z24_total_cap OR tot_int <> rm_csol.z24_total_int THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No cuadran valores en cabecera y detalle de solicitud cobor', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION

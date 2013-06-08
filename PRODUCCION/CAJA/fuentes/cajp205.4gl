------------------------------------------------------------------------------
-- Titulo           : cajp205.4gl - Actualizaciones por Ingresos a Caja por
--		      Pagos Anticipos.
-- Elaboracion      : 20-Nov-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun cajp205.4gl base_datos compañía localidad num_sol
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_numsol	LIKE cxct024.z24_numero_sol
DEFINE vm_tipo_doc	CHAR(2)
DEFINE rm_ccaj		RECORD LIKE cajt010.*
DEFINE rm_csol		RECORD LIKE cxct024.*
DEFINE rm_docf		RECORD LIKE cxct021.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp205.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = 'CG'
LET vg_codcia  = arg_val(2)
LET vg_codloc  = arg_val(3)
LET vm_numsol  = arg_val(4)
LET vg_proceso = 'cajp205'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fl_validar_parametros()
CALL control_master_caja()

END MAIN



FUNCTION control_master_caja()
DEFINE resp		CHAR(10)
DEFINE comando		VARCHAR(80)

LET vm_tipo_doc = 'PA'
BEGIN WORK
CALL valida_num_solicitud()
CALL genera_ingreso_caja()
UPDATE cxct024 SET z24_estado = 'P'
	WHERE CURRENT OF q_nsol 
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, rm_csol.z24_codcli)
UPDATE cajt010 SET j10_estado = 'P',
		   j10_tipo_destino = rm_docf.z21_tipo_doc,
		   j10_num_destino  = rm_docf.z21_num_doc,
		   j10_fecha_pro    = CURRENT
	WHERE CURRENT OF q_ccaj
COMMIT WORK
CALL fl_control_master_contab_ingresos_caja(vg_codcia, vg_codloc,
						rm_ccaj.j10_tipo_fuente,
						rm_ccaj.j10_num_fuente)

END FUNCTION



FUNCTION valida_num_solicitud()

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
	--CALL fgl_winmessage(vg_producto,'No existe solicitud en Caja', 'exclamation')
	CALL fl_mostrar_mensaje('No existe solicitud en Caja.','exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	EXIT PROGRAM
END IF
IF rm_ccaj.j10_estado <> "*" THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'Registro en Caja no tiene estado *', 'exclamation')
	CALL fl_mostrar_mensaje('Registro en Caja no tiene estado *','exclamation')
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
	--CALL fgl_winmessage(vg_producto,'No existe solicitud cobro', 'exclamation')
	CALL fl_mostrar_mensaje('No existe solicitud cobro.','exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	EXIT PROGRAM
END IF
IF rm_csol.z24_tipo <> 'A' THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Solicitud cobro no es por anticipo.','exclamation')
	EXIT PROGRAM
END IF
IF rm_csol.z24_estado <> 'A' THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Solicitud cobro no esta activa.','exclamation')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

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
INITIALIZE rm_docf.* TO NULL
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, 'CO', 'AA', vm_tipo_doc)
	RETURNING numero
IF numero <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_docf.z21_compania 	= vg_codcia
LET rm_docf.z21_localidad 	= vg_codloc
LET rm_docf.z21_codcli 		= rm_csol.z24_codcli
LET rm_docf.z21_tipo_doc 	= vm_tipo_doc
LET rm_docf.z21_num_doc 	= numero
LET rm_docf.z21_areaneg 	= rm_ccaj.j10_areaneg
LET rm_docf.z21_linea	 	= rm_csol.z24_linea
LET rm_docf.z21_referencia 	= 'SOLICITUD ANTICIPO: ', rm_csol.z24_numero_sol
				   USING '#####&'
LET rm_docf.z21_fecha_emi 	= TODAY
LET rm_docf.z21_moneda 		= rm_csol.z24_moneda
LET rm_docf.z21_paridad 	= rm_csol.z24_paridad
LET rm_docf.z21_val_impto	= 0
LET rm_docf.z21_valor		= rm_csol.z24_total_cap
LET rm_docf.z21_saldo 		= rm_csol.z24_total_cap
LET rm_docf.z21_subtipo		= rm_csol.z24_subtipo
LET rm_docf.z21_origen 		= 'A'
LET rm_docf.z21_usuario 	= vg_usuario
LET rm_docf.z21_fecing 		= CURRENT
INSERT INTO cxct021 VALUES (rm_docf.*)

END FUNCTION

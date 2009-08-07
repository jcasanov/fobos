------------------------------------------------------------------------------
-- Titulo           : vehp203.4gl - Actualizaciones por Emisión Factura
-- Elaboracion      : 02-nov-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun vehp203.4gl base_datos compañía localidad preventa
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_preventa	LIKE veht026.v26_numprev
DEFINE vm_tipdoc_veh	CHAR(2)
DEFINE vm_tipdoc_cob	CHAR(2)
DEFINE vm_tot_costo	DECIMAL(14,2)
DEFINE vm_cuota_fin	DECIMAL(14,2)
DEFINE rm_ccaj		RECORD LIKE cajt010.*
DEFINE rm_cprev		RECORD LIKE veht026.*
DEFINE rm_cabt		RECORD LIKE veht030.*
DEFINE rm_dett		RECORD LIKE veht031.*
DEFINE rm_veh		RECORD LIKE veht022.*
DEFINE rm_cli		RECORD LIKE cxct001.*
DEFINE rm_plan		RECORD LIKE veht006.*
DEFINE rm_lin		RECORD LIKE veht003.*

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_codcia   = arg_val(2)
LET vg_codloc   = arg_val(3)
LET vm_preventa = arg_val(4)
LET vg_modulo   = 'VE'
LET vg_proceso = 'vehp203'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL validar_parametros()
CALL control_master_caja()

END MAIN



FUNCTION control_master_caja()
DEFINE resp		CHAR(10)
DEFINE comando		VARCHAR(80)
DEFINE hecho		SMALLINT

LET vm_tipdoc_veh = 'FA'
LET vm_tipdoc_cob = 'DO'
BEGIN WORK
CALL valida_preventa()
CALL verifica_forma_pago()
CALL valida_vehiculos()
CALL genera_factura()
UPDATE veht026 SET v26_estado = 'F',
	 	   v26_cod_tran = rm_cabt.v30_cod_tran,
		   v26_num_tran = rm_cabt.v30_num_tran
	WHERE CURRENT OF q_cprev 
IF rm_cprev.v26_sdo_credito > 0 OR rm_cprev.v26_num_cuotaif > 0 THEN
	CALL genera_cuenta_por_cobrar('I', 'N', 89)
	CALL genera_cuenta_por_cobrar('V', 'N', 0)
	CALL genera_cuenta_por_cobrar('V', 'S', 79)
END IF
IF rm_cprev.v26_tot_pa_nc > 0 THEN
	CALL actualiza_documentos_favor()
END IF
IF rm_cprev.v26_sdo_credito > 0 OR rm_cprev.v26_tot_pa_nc > 0 OR 
	vm_cuota_fin > 0 THEN
	CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, rm_cprev.v26_codcli)
	IF rm_plan.v06_cred_direct = 'N' THEN
		CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, rm_plan.v06_codigo_cobr)
	END IF
END IF
UPDATE cajt010 SET 
		   j10_tipo_destino = rm_cabt.v30_cod_tran,
		   j10_num_destino  = rm_cabt.v30_num_tran
	WHERE CURRENT OF q_ccaj
CALL actualiza_vehiculos()
CALL fl_actualiza_acumulados_ventas_veh(vg_codcia, vg_codloc, 
		rm_cabt.v30_cod_tran, rm_cabt.v30_num_tran)
	RETURNING hecho
IF NOT hecho THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
COMMIT WORK
CALL fl_control_master_contab_vehiculos(vg_codcia, vg_codloc, 
		rm_cabt.v30_cod_tran, rm_cabt.v30_num_tran)
CALL fgl_winquestion(vg_producto,'Desea ver factura generada','Yes','Yes|No|Cancel','question',1)
	RETURNING resp
IF resp = 'Yes' THEN
	LET comando = 'fglrun vehp304 ', vg_base, ' ', vg_modulo, ' ', 
			vg_codcia, ' ', vg_codloc, ' ', rm_cabt.v30_cod_tran,
			' ', rm_cabt.v30_num_tran  
	RUN comando
END IF

END FUNCTION



FUNCTION valida_preventa()

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
DECLARE q_ccaj CURSOR FOR
	SELECT * FROM cajt010 
		WHERE j10_compania    = vg_codcia AND 
		      j10_localidad   = vg_codloc AND 
		      j10_tipo_fuente = 'PV' AND 
		      j10_num_fuente  = vm_preventa
 		FOR UPDATE 
OPEN q_ccaj 
FETCH q_ccaj INTO rm_ccaj.*
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe preventa en Caja', 'exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Registro de Caja está bloqueado por otro usuario', 'exclamation')
	EXIT PROGRAM
END IF
IF rm_ccaj.j10_estado <> "*" THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Registro en Caja no tiene estado *', 'exclamation')
	EXIT PROGRAM
END IF
DECLARE q_cprev CURSOR FOR
	SELECT * FROM veht026 
		WHERE v26_compania  = vg_codcia AND
		      v26_localidad = vg_codloc AND
		      v26_numprev   = vm_preventa
		FOR UPDATE
OPEN q_cprev
FETCH q_cprev INTO rm_cprev.*
IF status = NOTFOUND THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No existe preventa', 'exclamation')
	EXIT PROGRAM
END IF
IF status < 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Preventa está bloqueada por otro usuario', 'exclamation')
	EXIT PROGRAM
END IF
IF rm_cprev.v26_estado <> 'P' THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'Preventa no tiene estado de aprobada', 'exclamation')
	EXIT PROGRAM
END IF
IF rm_cprev.v26_codigo_plan IS NOT NULL THEN
	CALL fl_lee_plan_financiamiento(vg_codcia, rm_cprev.v26_codigo_plan)
		RETURNING rm_plan.*
END IF
WHENEVER ERROR STOP

END FUNCTION



FUNCTION verifica_forma_pago()
DEFINE valor_aux	DECIMAL(14,2)
DEFINE valor		DECIMAL(14,2)

WHENEVER ERROR STOP
LET vm_cuota_fin = 0
IF rm_cprev.v26_num_cuotaif > 0 THEN
	LET vm_cuota_fin = rm_cprev.v26_cuotai_fin 
END IF
IF rm_cprev.v26_cont_cred = 'R' THEN
	IF rm_cprev.v26_sdo_credito <= 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor crédito incorrecto en registro de forma de pago', 'exclamation')
		EXIT PROGRAM
	END IF
	LET valor = vm_cuota_fin + rm_cprev.v26_sdo_credito + 
		    rm_cprev.v26_tot_pa_nc
	IF rm_cprev.v26_tot_neto <> valor THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Saldo crédito más valores a favor es distinto del valor de la factura', 'exclamation')
		EXIT PROGRAM
	END IF
ELSE
	IF rm_cprev.v26_sdo_credito > 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Preventa es de contado y tiene valor crédito especificado', 'exclamation')
		EXIT PROGRAM
	END IF
	IF rm_cprev.v26_tot_neto < rm_cprev.v26_tot_pa_nc THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor a favor es mayor que valor factura', 'exclamation')
		EXIT PROGRAM
	END IF
	LET valor = vm_cuota_fin + rm_cprev.v26_tot_pa_nc
	IF rm_cprev.v26_tot_neto < valor THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor factura contado es menor que anticipos más cuota financiada', 'exclamation')
		EXIT PROGRAM
	END IF
END IF
LET valor = vm_cuota_fin + rm_cprev.v26_sdo_credito
IF valor > 0 THEN
	LET valor_aux = 0
	SELECT SUM(v28_val_cap + v28_val_adi) INTO valor_aux FROM veht028
		WHERE v28_compania  = vg_codcia AND 
		      v28_localidad = vg_codloc AND 
		      v28_numprev   = vm_preventa
	IF valor_aux IS NULL OR valor <> valor_aux THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'No cuadra total crédito de cabecera con el detalle', 'exclamation')
		EXIT PROGRAM
	END IF
END IF
IF rm_cprev.v26_tot_pa_nc > 0 THEN
	SELECT SUM(v29_valor) INTO valor FROM veht029
		WHERE v29_compania  = vg_codcia AND 
		      v29_localidad = vg_codloc AND 
		      v29_numprev   = vm_preventa
	IF valor_aux IS NULL OR valor <> rm_cprev.v26_tot_pa_nc THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'No cuadra total valor a favor de cabecera con el detalle', 'exclamation')
		EXIT PROGRAM
	END IF
END IF
	
END FUNCTION



FUNCTION valida_vehiculos()
DEFINE r		RECORD LIKE veht027.*
DEFINE i		SMALLINT
DEFINE costo		DECIMAL(14,2)

WHENEVER ERROR STOP
SET LOCK MODE TO WAIT 1
DECLARE q_dprev CURSOR FOR SELECT * FROM veht027
	WHERE v27_compania  = vg_codcia AND 
	      v27_localidad = vg_codloc AND 
	      v27_numprev   = vm_preventa
LET i = 0
LET vm_tot_costo = 0
FOREACH q_dprev INTO r.*
	CALL fl_lee_cod_vehiculo_veh(r.v27_compania, r.v27_localidad, 
				     r.v27_codigo_veh)
		RETURNING rm_veh.*
	LET costo = rm_veh.v22_costo_ing + rm_veh.v22_cargo_ing + 
		    rm_veh.v22_costo_adi
	LET vm_tot_costo = vm_tot_costo + costo
	SELECT * INTO rm_veh.* FROM veht022 
		WHERE v22_compania   = r.v27_compania AND 
		      v22_localidad  = vg_codloc AND 
		      v22_codigo_veh = r.v27_codigo_veh
	IF status = NOTFOUND THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Vehículo ' || r.v27_codigo_veh || ' no existe', 'exclamation')
		EXIT PROGRAM
	END IF
	IF rm_veh.v22_bodega <> rm_cprev.v26_bodega THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Vehículo no está en la bodega de facturación', 'exclamation')
		EXIT PROGRAM
	END IF
	IF rm_veh.v22_estado <> 'A' AND rm_veh.v22_estado <> 'R' THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Vehículo no está disponible para la venta', 'exclamation')
		EXIT PROGRAM
	END IF
	LET i = i + 1
END FOREACH
IF i = 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'La preventa no tiene detalle de vehículos', 'exclamation')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION genera_factura()
DEFINE numero 		INTEGER
DEFINE costo		DECIMAL(14,2)
DEFINE r 		RECORD LIKE veht027.*
DEFINE r_mod 		RECORD LIKE veht020.*

WHENEVER ERROR STOP
SET LOCK MODE TO WAIT
CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo, 'AA', vm_tipdoc_veh)
	RETURNING numero
IF numero <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
INITIALIZE rm_cabt.* TO NULL
CALL fl_lee_cliente_general(rm_cprev.v26_codcli)
	RETURNING rm_cli.* 
LET rm_cabt.v30_compania 	= vg_codcia
LET rm_cabt.v30_localidad 	= vg_codloc
LET rm_cabt.v30_cod_tran 	= vm_tipdoc_veh
LET rm_cabt.v30_num_tran 	= numero
LET rm_cabt.v30_cod_subtipo 	= NULL
LET rm_cabt.v30_cont_cred   	= rm_cprev.v26_cont_cred
LET rm_cabt.v30_referencia  	= NULL
LET rm_cabt.v30_codcli 		= rm_cprev.v26_codcli
LET rm_cabt.v30_nomcli 		= rm_cli.z01_nomcli
LET rm_cabt.v30_dircli 		= rm_cli.z01_direccion1
LET rm_cabt.v30_telcli 		= rm_cli.z01_telefono1
LET rm_cabt.v30_cedruc 		= rm_cli.z01_num_doc_id
LET rm_cabt.v30_vendedor 	= rm_cprev.v26_vendedor
LET rm_cabt.v30_oc_externa  	= NULL
LET rm_cabt.v30_oc_interna  	= NULL
LET rm_cabt.v30_descuento 	= 0
LET rm_cabt.v30_porc_impto  	= rg_gen.g00_porc_impto
LET rm_cabt.v30_tipo_dev    	= NULL
LET rm_cabt.v30_num_dev     	= NULL
LET rm_cabt.v30_bodega_ori  	= rm_cprev.v26_bodega
LET rm_cabt.v30_bodega_dest 	= rm_cprev.v26_bodega
LET rm_cabt.v30_fact_costo  	= NULL
LET rm_cabt.v30_fact_venta  	= NULL
LET rm_cabt.v30_moneda      	= rm_cprev.v26_moneda
LET rm_cabt.v30_paridad 	= rm_cprev.v26_paridad
LET rm_cabt.v30_precision   	= rm_cprev.v26_precision
LET rm_cabt.v30_tot_costo   	= vm_tot_costo 
LET rm_cabt.v30_tot_bruto   	= rm_cprev.v26_tot_bruto
LET rm_cabt.v30_tot_dscto   	= rm_cprev.v26_tot_dscto
LET rm_cabt.v30_tot_neto 	= rm_cprev.v26_tot_neto
LET rm_cabt.v30_flete 		= 0
LET rm_cabt.v30_numliq 		= NULL
LET rm_cabt.v30_usuario 	= vg_usuario
LET rm_cabt.v30_fecing 		= CURRENT
INSERT INTO veht030 VALUES (rm_cabt.*)
FOREACH q_dprev INTO r.*
	CALL fl_lee_cod_vehiculo_veh(r.v27_compania, r.v27_localidad, 
		r.v27_codigo_veh) RETURNING rm_veh.*
	CALL fl_lee_modelo_veh(r.v27_compania, rm_veh.v22_modelo)
		RETURNING r_mod.*
	LET costo = rm_veh.v22_costo_ing + rm_veh.v22_cargo_ing + 
		    rm_veh.v22_costo_adi
    	LET rm_dett.v31_compania 	= vg_codcia
    	LET rm_dett.v31_localidad 	= vg_codloc
    	LET rm_dett.v31_cod_tran 	= rm_cabt.v30_cod_tran
    	LET rm_dett.v31_num_tran 	= rm_cabt.v30_num_tran
    	LET rm_dett.v31_codigo_veh	= r.v27_codigo_veh
    	LET rm_dett.v31_nuevo   	= rm_veh.v22_nuevo
    	LET rm_dett.v31_descuento 	= r.v27_descuento
    	LET rm_dett.v31_val_descto 	= r.v27_val_descto
    	LET rm_dett.v31_precio 		= r.v27_precio
    	LET rm_dett.v31_moneda_cost 	= rm_veh.v22_moneda_ing
    	LET rm_dett.v31_costo 		= costo
    	LET rm_dett.v31_fob 		= 0
    	LET rm_dett.v31_costant_mb 	= 0
    	LET rm_dett.v31_costant_ma 	= 0
    	LET rm_dett.v31_costnue_mb 	= 0
    	LET rm_dett.v31_costnue_ma 	= 0
	INSERT INTO veht031 VALUES (rm_dett.*)
END FOREACH
CALL fl_lee_linea_veh(vg_codcia, r_mod.v20_linea)
	RETURNING rm_lin.*

END FUNCTION



FUNCTION genera_cuenta_por_cobrar(tipo, flag_adi, secuencia)
DEFINE tipo, flag_adi	CHAR(1)
DEFINE secuencia	SMALLINT
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r		RECORD LIKE veht028.*
DEFINE i		SMALLINT
DEFINE codcli		LIKE cxct001.z01_codcli

WHENEVER ERROR STOP
LET codcli = rm_cprev.v26_codcli
IF tipo <> 'I' AND rm_plan.v06_cred_direct = 'N' THEN
	LET codcli = rm_plan.v06_codigo_cobr
END IF
DECLARE q_dcred CURSOR FOR 
	SELECT * FROM veht028
		WHERE v28_compania  = vg_codcia AND
	      	      v28_localidad = vg_codloc AND
	      	      v28_numprev   = vm_preventa AND
		      v28_tipo      = tipo
		ORDER BY v28_dividendo
FOREACH q_dcred INTO r.*
	IF flag_adi = 'S' THEN
    		LET r.v28_val_int          = 0
		LET r.v28_val_cap = r.v28_val_adi
    		LET rm_cprev.v26_int_saldo = 0
		IF r.v28_val_adi = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET secuencia = secuencia + 1
    	LET r_doc.z20_compania	= vg_codcia
    	LET r_doc.z20_localidad = vg_codloc
    	LET r_doc.z20_codcli 	= codcli
    	LET r_doc.z20_tipo_doc 	= vm_tipdoc_cob
    	LET r_doc.z20_num_doc 	= rm_cabt.v30_num_tran
    	LET r_doc.z20_dividendo = secuencia
    	LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
    	LET r_doc.z20_referencia= NULL
    	LET r_doc.z20_fecha_emi = TODAY
    	LET r_doc.z20_fecha_vcto= r.v28_fecha_vcto
	IF tipo = 'V' THEN
    		LET r_doc.z20_tasa_int  = rm_cprev.v26_int_saldo
	ELSE
    		LET r_doc.z20_tasa_int  = rm_cprev.v26_int_cuotaif
	END IF
    	LET r_doc.z20_tasa_mora = 0
    	LET r_doc.z20_moneda 	= rm_cprev.v26_moneda
    	LET r_doc.z20_paridad 	= rm_cprev.v26_paridad
    	LET r_doc.z20_valor_cap = r.v28_val_cap
    	LET r_doc.z20_valor_int = r.v28_val_int
    	LET r_doc.z20_saldo_cap = r.v28_val_cap
    	LET r_doc.z20_saldo_int = r.v28_val_int
    	LET r_doc.z20_cartera 	= 1
    	LET r_doc.z20_linea 	= rm_lin.v03_grupo_linea
    	LET r_doc.z20_origen 	= 'A'
    	LET r_doc.z20_cod_tran  = rm_cabt.v30_cod_tran
    	LET r_doc.z20_num_tran  = rm_cabt.v30_num_tran
    	LET r_doc.z20_usuario 	= vg_usuario
    	LET r_doc.z20_fecing 	= CURRENT
	INSERT INTO cxct020 VALUES (r_doc.*)
END FOREACH

END FUNCTION



FUNCTION actualiza_documentos_favor()
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_caju		RECORD LIKE cxct022.*
DEFINE r_daju		RECORD LIKE cxct023.*
DEFINE r_daf		RECORD LIKE cxct021.*
DEFINE r		RECORD LIKE veht029.*
DEFINE numero		INTEGER
DEFINE i 		SMALLINT
DEFINE valor_aux	DECIMAL(14,2)

SET LOCK MODE TO WAIT 1
INITIALIZE r_doc.* TO NULL
LET r_doc.z20_compania	= vg_codcia
LET r_doc.z20_localidad = vg_codloc
LET r_doc.z20_codcli 	= rm_cprev.v26_codcli
LET r_doc.z20_tipo_doc 	= vm_tipdoc_cob
LET r_doc.z20_num_doc 	= rm_cabt.v30_num_tran
LET r_doc.z20_dividendo = 00
LET r_doc.z20_areaneg 	= rm_ccaj.j10_areaneg
LET r_doc.z20_referencia= NULL
LET r_doc.z20_fecha_emi = TODAY
LET r_doc.z20_fecha_vcto= TODAY 
LET r_doc.z20_tasa_int  = 0
LET r_doc.z20_tasa_mora = 0
LET r_doc.z20_moneda 	= rm_cprev.v26_moneda
LET r_doc.z20_paridad 	= rm_cprev.v26_paridad
LET r_doc.z20_valor_cap = rm_cprev.v26_tot_pa_nc
LET r_doc.z20_valor_int = 0
LET r_doc.z20_saldo_cap = 0
LET r_doc.z20_saldo_int = 0
LET r_doc.z20_cartera 	= 1
LET r_doc.z20_linea 	= rm_lin.v03_grupo_linea
LET r_doc.z20_origen 	= 'A'
LET r_doc.z20_cod_tran  = rm_cabt.v30_cod_tran
LET r_doc.z20_num_tran  = rm_cabt.v30_num_tran
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
LET r_caju.z22_codcli 		= rm_cprev.v26_codcli
LET r_caju.z22_tipo_trn 	= 'AJ'
LET r_caju.z22_num_trn 		= numero
LET r_caju.z22_areaneg 		= rm_ccaj.j10_areaneg
LET r_caju.z22_referencia 	= 'APLICACION ANTICIPO'
LET r_caju.z22_fecha_emi 	= TODAY
LET r_caju.z22_moneda 		= rm_cprev.v26_moneda
LET r_caju.z22_paridad 		= rm_cprev.v26_paridad
LET r_caju.z22_tasa_mora 	= 0
LET r_caju.z22_total_cap 	= rm_cprev.v26_tot_pa_nc * -1
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
LET valor_aux = rm_cprev.v26_tot_pa_nc 
DECLARE q_antd CURSOR FOR 
	SELECT * FROM veht029 
		WHERE v29_compania  = vg_codcia AND
		      v29_localidad = vg_codloc AND
		      v29_numprev   = vm_preventa
LET i = 0
FOREACH q_antd INTO r.*
	IF r.v29_valor <= 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Valor de documento <= 0: ' || r.v29_tipo_doc || ' ' || r.v29_numdoc, 'stop')
		EXIT PROGRAM
	END IF
	LET i = i + 1
	INITIALIZE r_daju.* TO NULL
    	LET r_daju.z23_compania 	= vg_codcia
    	LET r_daju.z23_localidad 	= vg_codloc
    	LET r_daju.z23_codcli 		= rm_cprev.v26_codcli
    	LET r_daju.z23_tipo_trn 	= r_caju.z22_tipo_trn
    	LET r_daju.z23_num_trn 		= r_caju.z22_num_trn
    	LET r_daju.z23_orden 		= i
    	LET r_daju.z23_areaneg 		= r_caju.z22_areaneg
    	LET r_daju.z23_tipo_doc 	= r_doc.z20_tipo_doc
    	LET r_daju.z23_num_doc 		= r_doc.z20_num_doc
    	LET r_daju.z23_div_doc 		= r_doc.z20_dividendo
    	LET r_daju.z23_tipo_favor 	= r.v29_tipo_doc
    	LET r_daju.z23_doc_favor 	= r.v29_numdoc
    	LET r_daju.z23_valor_cap 	= r.v29_valor * -1
    	LET r_daju.z23_valor_int 	= 0
    	LET r_daju.z23_valor_mora 	= 0
    	LET r_daju.z23_saldo_cap 	= valor_aux
	LET valor_aux           	= valor_aux - r.v29_valor
    	LET r_daju.z23_saldo_int 	= 0
	INSERT INTO cxct023 VALUES (r_daju.*)
	WHENEVER ERROR CONTINUE
	DECLARE q_daf CURSOR FOR
		SELECT * FROM cxct021 
			WHERE z21_compania  = vg_codcia AND 
		              z21_localidad = vg_codloc AND 
		              z21_codcli    = rm_cprev.v26_codcli AND 
		              z21_tipo_doc  = r.v29_tipo_doc AND
		              z21_num_doc   = r.v29_numdoc
		FOR UPDATE
	OPEN q_daf
	FETCH q_daf INTO r_daf.*
	IF status = NOTFOUND THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Documento a favor no existe: ' || r.v29_tipo_doc || ' ' || r.v29_numdoc, 'stop')
		EXIT PROGRAM
	END IF
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Documento a favor está bloqueado por otro usuario. ' || r.v29_tipo_doc || ' ' || r.v29_numdoc, 'exclamation')
		EXIT PROGRAM
	END IF
	IF r_daf.z21_saldo < r.v29_valor THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Saldo anticipo menor que valor a aplicar' || r.v29_tipo_doc || ' ' || r.v29_numdoc, 'exclamation')
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	UPDATE cxct021 SET z21_saldo = z21_saldo - r.v29_valor
		WHERE CURRENT OF q_daf
END FOREACH	
IF i = 0 THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No se procesaron documentos a favor', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION actualiza_vehiculos()
DEFINE r		RECORD LIKE veht027.*

SET LOCK MODE TO WAIT 10
WHENEVER ERROR CONTINUE
FOREACH q_dprev INTO r.*
	DECLARE q_upexi CURSOR FOR 
		SELECT * FROM veht022 
			WHERE v22_compania   = r.v27_compania AND 
			      v22_localidad  = vg_codloc AND 
			      v22_codigo_veh = r.v27_codigo_veh
			FOR UPDATE
	OPEN q_upexi
	FETCH q_upexi INTO rm_veh.*
	IF status = NOTFOUND THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Vehículo ' || r.v27_codigo_veh || ' no existe', 'exclamation')
		EXIT PROGRAM
	END IF
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Vehículo está bloqueado por otro usuario', 'exclamation')
		EXIT PROGRAM
	END IF
	UPDATE veht022 SET v22_estado = 'F',
		           v22_cod_tran = rm_cabt.v30_cod_tran,
		           v22_num_tran = rm_cabt.v30_num_tran
		WHERE CURRENT OF q_upexi
	UPDATE veht020 SET v20_stock = v20_stock - 1
		WHERE v20_compania = r.v27_compania AND 
		      v20_modelo   = rm_veh.v22_modelo
	IF status < 0 THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Modelo de vehículo está bloqueado por otro usuario', 'exclamation')
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
END FOREACH

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

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_programa      VARCHAR(12)
DEFINE rm_crep		RECORD LIKE rept019.*
DEFINE rm_auxv		RECORD LIKE ctbt040.*
DEFINE rm_auxc		RECORD LIKE ctbt041.*
DEFINE rm_auxg		RECORD LIKE ctbt042.*
DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE rm_r28		RECORD LIKE rept028.*
DEFINE vm_modulo	LIKE gent050.g50_modulo
DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_indice	SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran
DEFINE vm_fact_anu	SMALLINT

FUNCTION fl_control_master_contab_repuestos(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp

INITIALIZE vm_cod_tran, vm_num_tran TO NULL
LET vm_cod_tran = cod_tran
LET vm_num_tran = num_tran
CALL fl_lee_compania_contabilidad(cod_cia) RETURNING rm_ctb.*	
IF rm_ctb.b00_inte_online = 'N' THEN
	RETURN
END IF
LET vm_modulo    = 'RE'
LET vm_tipo_comp = 'DR'
LET vm_indice    = 1
CALL integ_fl_lee_cabecera_transaccion_rep(cod_cia, cod_loc, cod_tran, num_tran)
	RETURNING rm_crep.*
IF rm_crep.r19_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe transacción en módulo Repuestos: ' || cod_tran || ' ' || num_tran, 'stop')
	RETURN
END IF
IF DATE(rm_crep.r19_fecing) <= rm_ctb.b00_fecha_cm THEN
	CALL fl_mostrar_mensaje('La fecha de la transacción corresponde a un mes contable ya cerrado: ' || cod_tran || ' ' || num_tran, 'stop')
	RETURN
END IF
CREATE TEMP TABLE te_master
	(te_tipo_comp		CHAR(2),
         te_num_comp		CHAR(8),
	 te_subtipo		SMALLINT,
	 te_cod_tran		CHAR(2),
	 te_num_tran		DECIMAL(15,0),
         te_cuenta		CHAR(12),
	 te_glosa		CHAR(35),
	 te_tipo_mov		CHAR(1),
	 te_valor		DECIMAL(14,2),
	 te_indice		SMALLINT)
DECLARE q_drep CURSOR FOR SELECT * FROM acero_gc:rept020
	WHERE r20_compania  = rm_crep.r19_compania  AND 
	      r20_localidad = rm_crep.r19_localidad AND 
	      r20_cod_tran  = rm_crep.r19_cod_tran  AND 
	      r20_num_tran  = rm_crep.r19_num_tran
CASE rm_crep.r19_cod_tran 
	WHEN 'FA'
		CALL fl_contabiliza_venta_repuestos(52)
		LET vm_indice = vm_indice + 1
		CALL fl_contabiliza_costo_venta_repuestos(53,0)
		LET vm_indice = vm_indice + 1
	WHEN 'AF'
		CALL fl_contabiliza_anulacion_fact_repuestos(54)
		LET vm_indice = vm_indice + 1
	WHEN 'DF'
		LET vm_fact_anu = 0
		CALL fl_contabiliza_dev_venta_repuestos(54)
		LET vm_indice = vm_indice + 1
		IF vm_fact_anu = 0 THEN
			CALL fl_contabiliza_costo_venta_repuestos(53, 1)
			LET vm_indice = vm_indice + 1
		END IF
END CASE
CALL fl_chequea_cuadre_db_cr()
BEGIN WORK
CALL fl_genera_comprobantes()
COMMIT WORK
IF rm_ctb.b00_mayo_online = 'N' THEN
	DROP TABLE te_master
	RETURN
END IF
DECLARE q_mcomm CURSOR WITH HOLD 
	FOR SELECT UNIQUE te_tipo_comp, te_num_comp
	FROM te_master
FOREACH q_mcomm INTO tipo, num
	CALL fl_mayoriza_comprobante(rm_crep.r19_compania, tipo, num, 'M')
END FOREACH
DROP TABLE te_master

END FUNCTION
	


FUNCTION fl_contabiliza_venta_repuestos(subtipo)
DEFINE tot_efe		DECIMAL(14,2)
DEFINE tot_tar		DECIMAL(14,2)
DEFINE tot_dep		DECIMAL(14,2)
DEFINE tot_ret		DECIMAL(14,2)
DEFINE tot_otr		DECIMAL(14,2)
DEFINE val_iva		DECIMAL(14,2)
DEFINE tot_comp		DECIMAL(14,2)
DEFINE dif, dif_abs	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_fpc		RECORD LIKE rept025.*
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE r_cj		RECORD LIKE cajt010.*
DEFINE r_dj, r_caca	RECORD LIKE cajt011.*
DEFINE r_tj		RECORD LIKE gent010.*
DEFINE r_bco		RECORD LIKE gent009.*
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_z02		RECORD LIKE cxct002.*

LET tot_efe = 0
LET tot_tar = 0
LET tot_otr = 0
LET tot_dep = 0
LET tot_ret = 0
LET rm_crep.r19_tot_bruto = rm_crep.r19_tot_bruto * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_bruto)
	RETURNING rm_crep.r19_tot_bruto
LET rm_crep.r19_tot_dscto = rm_crep.r19_tot_dscto * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_dscto)
	RETURNING rm_crep.r19_tot_dscto
LET rm_crep.r19_tot_neto  = rm_crep.r19_tot_neto  * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_neto)
	RETURNING rm_crep.r19_tot_neto
LET val_iva = rm_crep.r19_tot_neto - rm_crep.r19_flete -
	     (rm_crep.r19_tot_bruto - rm_crep.r19_tot_dscto)
SELECT * INTO r_fpc.* FROM acero_gc:rept025
	WHERE r25_compania  = rm_crep.r19_compania  AND
	      r25_localidad = rm_crep.r19_localidad AND 
	      r25_cod_tran  = rm_crep.r19_cod_tran  AND 
	      r25_num_tran  = rm_crep.r19_num_tran
IF status = NOTFOUND THEN
	LET r_fpc.r25_valor_ant  = 0	
	LET r_fpc.r25_valor_cred = 0	
ELSE
	LET r_fpc.r25_valor_ant = r_fpc.r25_valor_ant * rm_crep.r19_paridad
	CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, r_fpc.r25_valor_ant)
		RETURNING r_fpc.r25_valor_ant
	LET r_fpc.r25_valor_cred = r_fpc.r25_valor_cred * rm_crep.r19_paridad
	CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, r_fpc.r25_valor_cred)
		RETURNING r_fpc.r25_valor_cred
END IF
CALL fl_lee_auxiliares_generales(rm_crep.r19_compania, rm_crep.r19_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
OPEN q_drep
FETCH q_drep INTO r_drep.*
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Factura no tiene detalle: ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_linea_rep(r_drep.r20_compania, r_drep.r20_linea)
	RETURNING r_lr.*
IF r_lr.r03_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe línea de venta: ' || r_drep.r20_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_caja(rm_crep.r19_compania, rm_crep.r19_localidad,
			    vm_modulo, r_lr.r03_grupo_linea)
	RETURNING rm_auxc.*
IF rm_auxc.b41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares de Caja/Cobranzas.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
	vm_modulo, rm_crep.r19_bodega_ori, r_lr.r03_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
SELECT * INTO r_cj.* FROM acero_gc:cajt010
	WHERE j10_compania     = rm_crep.r19_compania  AND 
	      j10_localidad    = rm_crep.r19_localidad AND 
	      j10_tipo_fuente  = 'PR'                  AND 
	      j10_tipo_destino = rm_crep.r19_cod_tran  AND
	      j10_num_destino  = rm_crep.r19_num_tran
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro de caja en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL integ_fl_lee_codigo_caja_caja(rm_crep.r19_compania, rm_crep.r19_localidad, 
	r_cj.j10_codigo_caja) RETURNING r_j02.*
IF r_j02.j02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe en cajt002: ' || r_cj.j10_codigo_caja, 'stop')
	EXIT PROGRAM
END IF
IF r_j02.j02_aux_cont IS NOT NULL THEN
	LET rm_auxc.b41_caja_mb = r_j02.j02_aux_cont
	LET rm_auxc.b41_caja_me = r_j02.j02_aux_cont
END IF
LET glosa = rm_crep.r19_nomcli[1,25], ' ', rm_crep.r19_cod_tran, '-',
	    rm_crep.r19_num_tran USING '<<<<<<<<<<<<<<<'
DECLARE q_dcaj CURSOR FOR SELECT * FROM acero_gc:cajt011
	WHERE j11_compania     = r_cj.j10_compania    AND 
	      j11_localidad    = r_cj.j10_localidad   AND 
	      j11_tipo_fuente  = r_cj.j10_tipo_fuente AND
	      j11_num_fuente   = r_cj.j10_num_fuente
FOREACH q_dcaj INTO r_dj.*
	LET r_dj.j11_valor = r_dj.j11_valor * r_dj.j11_paridad
	CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, r_dj.j11_valor)
		RETURNING r_dj.j11_valor
	CASE r_dj.j11_codigo_pago
		WHEN 'EF'
			LET tot_efe = tot_efe + r_dj.j11_valor 
		WHEN 'CH'
			LET tot_efe = tot_efe + r_dj.j11_valor 
		WHEN 'TJ'
			LET tot_tar = tot_tar + r_dj.j11_valor 
			LET r_caca.* = r_dj.*
		WHEN 'DP'
			LET tot_dep = tot_dep + r_dj.j11_valor 
			CALL fl_lee_banco_compania(r_dj.j11_compania, r_dj.j11_cod_bco_tarj, r_dj.j11_num_cta_tarj)
				RETURNING r_bco.*
			IF r_bco.g09_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe banco/cuenta: ' || r_dj.j11_cod_bco_tarj || ' ' || r_dj.j11_num_cta_tarj, 'stop')
				EXIT PROGRAM
			END IF
			CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, 
				r_bco.g09_aux_cont, 'D', r_dj.j11_valor, glosa,
        		        rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
		WHEN 'RT'
			LET tot_ret = tot_ret + r_dj.j11_valor
		OTHERWISE
			LET tot_efe = tot_efe + r_dj.j11_valor
	END CASE
END FOREACH
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_flete, 
	'H', rm_crep.r19_flete, glosa, rm_crep.r19_cod_tran, 
        rm_crep.r19_num_tran)
LET tot_comp = tot_efe + tot_tar + tot_dep + tot_ret + r_fpc.r25_valor_ant + 
	       r_fpc.r25_valor_cred
LET dif = rm_crep.r19_tot_neto - tot_comp
LET dif_abs = dif
IF dif < 0 THEN
	LET dif_abs = dif_abs * -1
END IF
IF (dif_abs * 100) / rm_crep.r19_tot_neto > 2 THEN  -- Diferencia > 2%
	CALL fl_mostrar_mensaje('No cuadran valores de factura: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET rm_crep.r19_tot_neto = rm_crep.r19_tot_neto - dif
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_venta, 'H',
        rm_crep.r19_tot_bruto, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_descuento, 'D',
        rm_crep.r19_tot_dscto, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxg.b42_iva_venta, 'H',
        val_iva, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
IF rm_crep.r19_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxc.b41_caja_mb, 
        'D', tot_efe, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxg.b42_retencion,
	'D', tot_ret, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb,'D',
        r_fpc.r25_valor_cred, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxc.b41_ant_mb,'D',
	r_fpc.r25_valor_ant, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
IF tot_tar > 0 THEN
	LET r_dj.* = r_caca.*
	CALL fl_lee_tarjeta_credito(r_dj.j11_cod_bco_tarj) RETURNING r_tj.*
	IF r_tj.g10_codcobr IS NOT NULL THEN
		CALL fl_lee_cliente_localidad(rm_crep.r19_compania, rm_crep.r19_localidad, r_tj.g10_codcobr)
			RETURNING r_z02.*
		IF rm_crep.r19_moneda <> rg_gen.g00_moneda_base THEN
			IF r_z02.z02_aux_clte_ma IS NOT NULL THEN
				LET r_z02.z02_aux_clte_mb = r_z02.z02_aux_clte_ma
			END IF
		END IF
		IF r_z02.z02_aux_clte_mb IS NOT NULL THEN
			LET rm_auxc.b41_cxc_mb = r_z02.z02_aux_clte_mb
		END IF
	END IF
	CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb, 'D',
		tot_tar, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
END IF

END FUNCTION



FUNCTION fl_contabiliza_costo_venta_repuestos(subtipo, flag_dev)
DEFINE tot_costo	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE flag_dev		SMALLINT
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE tipo_mov_1 	CHAR(1)
DEFINE tipo_mov_2 	CHAR(1)

LET tot_costo = 0
FOREACH q_drep INTO r_drep.*
	LET tot_costo = tot_costo + (r_drep.r20_cant_ven * r_drep.r20_costo)
END FOREACH
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, tot_costo)
	RETURNING tot_costo
CALL fl_lee_linea_rep(r_drep.r20_compania, r_drep.r20_linea)
	RETURNING r_lr.*
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
	vm_modulo, rm_crep.r19_bodega_ori, r_lr.r03_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_crep.r19_nomcli[1,25], ' ', rm_crep.r19_cod_tran, '-',
	    rm_crep.r19_num_tran USING '<<<<<<<<<<<<<<<'
LET tipo_mov_1 = 'D'
LET tipo_mov_2 = 'H'
IF flag_dev = 1 THEN
	LET rm_auxv.b40_costo_venta = rm_auxv.b40_dev_costo
	LET tipo_mov_1 = 'H'
	LET tipo_mov_2 = 'D'
END IF
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_costo_venta, tipo_mov_1,
        tot_costo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_inventario,
        tipo_mov_2, tot_costo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)

END FUNCTION



FUNCTION fl_contabiliza_anulacion_fact_repuestos(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_fact		RECORD LIKE rept019.*
DEFINE r_r40		RECORD LIKE rept040.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE i		SMALLINT

CALL integ_fl_lee_cabecera_transaccion_rep(rm_crep.r19_compania,rm_crep.r19_localidad,
	rm_crep.r19_tipo_dev, rm_crep.r19_num_dev)
	RETURNING r_fact.*
IF r_fact.r19_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe factura anulada : ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	RETURN
END IF
IF rm_crep.r19_tot_neto <> r_fact.r19_tot_neto THEN
	CALL fl_mostrar_mensaje( 
		'No concuerda neto de la devolución con neto de la factura: ' ||
	        rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	RETURN
END IF
DECLARE cu_repcont CURSOR WITH HOLD FOR 
	SELECT * FROM rept040
		WHERE r40_compania  = r_fact.r19_compania  AND 
	              r40_localidad = r_fact.r19_localidad AND 
	              r40_cod_tran  = r_fact.r19_cod_tran  AND 
	              r40_num_tran  = r_fact.r19_num_tran
	        ORDER BY r40_num_comp DESC
LET i = 0
FOREACH cu_repcont INTO r_r40.*
	LET i = i + 1
	CALL fl_lee_comprobante_contable(r_fact.r19_compania, 
			r_r40.r40_tipo_comp, r_r40.r40_num_comp)
		RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe en ctbt012 comprobante de la rept040.', 'stop')
		EXIT PROGRAM
	END IF
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'D')
	CALL fl_lee_comprobante_contable(r_fact.r19_compania, 
			r_r40.r40_tipo_comp, r_r40.r40_num_comp)
		RETURNING r_b12.*
	SET LOCK MODE TO WAIT 5
	UPDATE ctbt012 SET b12_estado     = 'E',
			   b12_fec_modifi = CURRENT 
		WHERE b12_compania  = r_b12.b12_compania  AND 
		      b12_tipo_comp = r_b12.b12_tipo_comp AND 
		      b12_num_comp  = r_b12.b12_num_comp
	INSERT INTO rept040 VALUES (rm_crep.r19_compania, 
		rm_crep.r19_localidad, rm_crep.r19_cod_tran, 
	        rm_crep.r19_num_tran, r_b12.b12_tipo_comp, 
	        r_b12.b12_num_comp)
	IF i = 2 THEN
		EXIT FOREACH
	END IF
END FOREACH	

END FUNCTION	


 
FUNCTION fl_contabiliza_dev_venta_repuestos(subtipo)
DEFINE val_iva		DECIMAL(14,2)
DEFINE tot_comp		DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_fact		RECORD LIKE rept019.*
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE r_cj		RECORD LIKE cajt010.*
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE r_bco		RECORD LIKE gent009.*
DEFINE saldo_fact	DECIMAL(14,2)
DEFINE val_anticipo	DECIMAL(14,2)
DEFINE val_cobranzas	DECIMAL(14,2)

CALL integ_fl_lee_cabecera_transaccion_rep(rm_crep.r19_compania,rm_crep.r19_localidad,
	rm_crep.r19_tipo_dev, rm_crep.r19_num_dev)
	RETURNING r_fact.*
IF r_fact.r19_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe factura devuelta : ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	RETURN
END IF
IF DATE(rm_crep.r19_fecing) = DATE(r_fact.r19_fecing) AND
	rm_crep.r19_tot_neto = r_fact.r19_tot_neto AND 
	DATE(rm_crep.r19_fecing) <= MDY(09,16,2002) THEN
	LET vm_fact_anu = 1
	CALL fl_contabiliza_anulacion_fact_repuestos(10)
	RETURN
END IF
LET rm_crep.r19_tot_bruto = rm_crep.r19_tot_bruto * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_bruto)
	RETURNING rm_crep.r19_tot_bruto
LET rm_crep.r19_tot_dscto = rm_crep.r19_tot_dscto * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_dscto)
	RETURNING rm_crep.r19_tot_dscto
LET rm_crep.r19_tot_neto  = rm_crep.r19_tot_neto  * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_neto)
	RETURNING rm_crep.r19_tot_neto
LET val_iva = rm_crep.r19_tot_neto - (rm_crep.r19_tot_bruto - rm_crep.r19_tot_dscto)
CALL fl_lee_auxiliares_generales(rm_crep.r19_compania, rm_crep.r19_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
OPEN q_drep
FETCH q_drep INTO r_drep.*
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Dev. Fact. no tiene detalle: ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_linea_rep(r_drep.r20_compania, r_drep.r20_linea)
	RETURNING r_lr.*
IF r_lr.r03_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe línea de venta: ' || r_drep.r20_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_caja(rm_crep.r19_compania, rm_crep.r19_localidad,
			    vm_modulo, r_lr.r03_grupo_linea)
	RETURNING rm_auxc.*
IF rm_auxc.b41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares de Caja/Cobranzas.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
	vm_modulo, rm_crep.r19_bodega_ori, r_lr.r03_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_crep.r19_nomcli[1,25], ' ', rm_crep.r19_cod_tran, '-',
	    rm_crep.r19_num_tran USING '<<<<<<<<<<<<<<<'
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_dev_venta, 'D',
        rm_crep.r19_tot_bruto, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxg.b42_iva_venta, 'D',
        val_iva, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_descuento, 'H',
        rm_crep.r19_tot_dscto, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
IF rm_crep.r19_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
IF rm_crep.r19_cont_cred = 'C' THEN
	CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, 
		rm_auxc.b41_ant_mb, 'H', rm_crep.r19_tot_neto, glosa, 
		rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
	RETURN
END IF
CALL chequea_saldo_fact_devuelta(r_fact.*, rm_crep.r19_fecing) 
	RETURNING saldo_fact
LET val_anticipo = 0
IF rm_crep.r19_tot_neto <= saldo_fact THEN
	LET val_cobranzas = rm_crep.r19_tot_neto
	LET val_anticipo  = 0
ELSE
	LET val_anticipo  = rm_crep.r19_tot_neto - saldo_fact
	LET val_cobranzas = saldo_fact
END IF
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxc.b41_ant_mb, 
	'H', val_anticipo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb, 
	'H', val_cobranzas, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)

END FUNCTION
 


FUNCTION fl_genera_comprobantes()
DEFINE tipo_comp	CHAR(2)
DEFINE num_comp		CHAR(8)
DEFINE subtipo		SMALLINT
DEFINE cod_tran		CHAR(2)
DEFINE num_tran		DECIMAL(15,0)
DEFINE cuenta		CHAR(12)
DEFINE glosa		CHAR(35)
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE indice, i	SMALLINT
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_dcomp		RECORD LIKE ctbt013.*
DEFINE pedido		LIKE rept029.r29_pedido
        
DECLARE q_mast CURSOR FOR SELECT UNIQUE te_tipo_comp, te_subtipo, te_indice 
	FROM te_master
	ORDER BY 3
IF rm_crep.r19_cod_tran = 'IM' THEN
	INITIALIZE pedido TO NULL
	DECLARE qu_y2k CURSOR FOR 
		SELECT r29_pedido FROM acero_gc:rept029
			WHERE r29_compania  = rm_crep.r19_compania  AND 
			      r29_localidad = rm_crep.r19_localidad AND 
			      r29_numliq    = rm_crep.r19_numliq
	OPEN qu_y2k 
	FETCH qu_y2k INTO pedido
END IF
FOREACH q_mast INTO tipo_comp, subtipo, indice
	INITIALIZE r_ccomp.* TO NULL
	LET r_ccomp.b12_num_comp = fl_numera_comprobante_contable(rm_crep.r19_compania,
		tipo_comp, YEAR(rm_crep.r19_fecing), MONTH(rm_crep.r19_fecing))
	IF r_ccomp.b12_num_comp = '-1' THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_ccomp.b12_compania 	= rm_crep.r19_compania
    	LET r_ccomp.b12_tipo_comp 	= tipo_comp
    	LET r_ccomp.b12_estado 		= 'A'
    	LET r_ccomp.b12_subtipo 	= subtipo
	IF vm_cod_tran IS NOT NULL THEN
    		LET r_ccomp.b12_fec_proceso = rm_crep.r19_fecing
    		LET r_ccomp.b12_glosa	= 'COMPROBANTE: ',
			rm_crep.r19_cod_tran, ' ', rm_crep.r19_num_tran 
			USING '<<<<<<<<<<<<<<<'
	ELSE
    		LET r_ccomp.b12_fec_proceso = vm_fecha_fin
    		LET r_ccomp.b12_glosa = 'COMPROBANTES ',
					'DEL ', vm_fecha_ini USING 'dd-mm-yyyy',
				        ' AL ', vm_fecha_fin USING 'dd-mm-yyyy'
		IF vm_fecha_ini = vm_fecha_fin THEN
    			LET r_ccomp.b12_fec_proceso = vm_fecha_ini
    			LET r_ccomp.b12_glosa = 'COMPROBANTES ',
				'DEL: ', vm_fecha_ini USING 'dd-mm-yyyy'
		END IF
	END IF		
    	LET r_ccomp.b12_origen 		= 'A'
    	LET r_ccomp.b12_moneda 		= rg_gen.g00_moneda_base
    	LET r_ccomp.b12_paridad 	= 1
    	LET r_ccomp.b12_modulo	 	= vm_modulo
    	LET r_ccomp.b12_usuario 	= vg_usuario
    	LET r_ccomp.b12_fecing 		= CURRENT
	INSERT INTO ctbt012 VALUES (r_ccomp.*)
	DECLARE q_dmast CURSOR FOR SELECT * FROM te_master
		WHERE te_tipo_comp = tipo_comp AND 
		      te_subtipo   = subtipo
		ORDER BY te_tipo_mov, te_cuenta
	INITIALIZE r_dcomp.* TO NULL
	LET i = 0
	FOREACH q_dmast INTO tipo_comp, num_comp, subtipo, cod_tran, num_tran, 
			   cuenta, glosa, tipo_mov, valor, indice
		LET i = i + 1
    		LET r_dcomp.b13_compania 	= r_ccomp.b12_compania
    		LET r_dcomp.b13_tipo_comp 	= r_ccomp.b12_tipo_comp
    		LET r_dcomp.b13_num_comp 	= r_ccomp.b12_num_comp
    		LET r_dcomp.b13_secuencia 	= i
    		LET r_dcomp.b13_cuenta 		= cuenta
    		LET r_dcomp.b13_glosa 		= glosa
    		LET r_dcomp.b13_valor_base 	= valor
    		LET r_dcomp.b13_valor_aux 	= 0
    		LET r_dcomp.b13_fec_proceso 	= r_ccomp.b12_fec_proceso
    		LET r_dcomp.b13_num_concil 	= 0
		CASE rm_crep.r19_cod_tran
			WHEN 'FA'
    				LET r_dcomp.b13_codcli  = rm_crep.r19_codcli
			WHEN 'AF'
    				LET r_dcomp.b13_codcli  = rm_crep.r19_codcli
			WHEN 'DF'
    				LET r_dcomp.b13_codcli  = rm_crep.r19_codcli
			WHEN 'CL'
    				LET r_dcomp.b13_codprov = rm_c10.c10_codprov
			WHEN 'DC'
    				LET r_dcomp.b13_codprov = rm_c10.c10_codprov
			WHEN 'IM'
    				LET r_dcomp.b13_codprov = rm_r28.r28_codprov
    				LET r_dcomp.b13_pedido  = pedido
		END CASE
		INSERT INTO ctbt013 VALUES(r_dcomp.*)
	END FOREACH
	UPDATE te_master SET te_num_comp = r_ccomp.b12_num_comp
		WHERE te_tipo_comp = r_ccomp.b12_tipo_comp AND
		      te_subtipo   = r_ccomp.b12_subtipo 
END FOREACH
DECLARE q_crc CURSOR FOR 
	SELECT UNIQUE te_cod_tran, te_num_tran, te_tipo_comp, te_num_comp 
	FROM te_master
FOREACH q_crc INTO cod_tran, num_tran, tipo_comp, num_comp
	INSERT INTO rept040 VALUES (rm_crep.r19_compania, rm_crep.r19_localidad,
	    cod_tran, num_tran, tipo_comp, num_comp)
	IF rm_crep.r19_cod_tran = 'CL' THEN
		CALL integ_fl_lee_cabecera_transaccion_rep(rm_crep.r19_compania, 
			rm_crep.r19_localidad, cod_tran, num_tran) 
			RETURNING rm_crep.*
		INSERT INTO ordt040 VALUES (rm_crep.r19_compania, 
			rm_crep.r19_localidad, rm_crep.r19_oc_interna, 1,
	    		tipo_comp, num_comp)
	END IF
END FOREACH

END FUNCTION



FUNCTION fl_chequea_cuadre_db_cr()
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE indice		SMALLINT

DECLARE q_sdbcr CURSOR FOR SELECT te_tipo_comp, te_subtipo, te_indice, 
	te_cod_tran, te_num_tran, SUM(te_valor)
	FROM te_master
	GROUP BY 1, 2, 3, 4, 5
	HAVING SUM(te_valor) <> 0
FOREACH q_sdbcr INTO tipo_comp, subtipo, indice, cod_tran, num_tran, valor
	LET tipo_mov = 'D'
	LET valor = valor * -1
	IF valor < 0 THEN
		LET tipo_mov = 'H'
	END IF	
	INSERT INTO te_master VALUES (tipo_comp, NULL, subtipo, cod_tran,
		num_tran, rm_auxg.b42_cuadre, '** DESCUADRE **', tipo_mov, 
		valor, indice)
END FOREACH

END FUNCTION
	


FUNCTION fl_genera_detalle_comprobante(tipo_comp, subtipo, cuenta, tipo_mov, 
		valor, glosa, cod_tran, num_tran)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE tipo_mov		CHAR(1)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE valor		DECIMAL(14,2)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran

IF valor = 0 THEN
	RETURN
END IF
IF tipo_mov = 'H' THEN
	LET valor = valor * -1
END IF
SELECT * FROM te_master 
	WHERE te_tipo_comp = tipo_comp AND 
	      te_subtipo   = subtipo   AND
	      te_cuenta    = cuenta    AND
	      te_glosa     = glosa
IF status = NOTFOUND THEN
	INSERT INTO te_master VALUES (tipo_comp, NULL, subtipo, cod_tran,
		num_tran, cuenta, glosa, tipo_mov, valor, vm_indice)
ELSE
	UPDATE te_master SET te_valor = te_valor + valor
		WHERE te_tipo_comp = tipo_comp AND 
	              te_subtipo   = subtipo   AND
	              te_cuenta    = cuenta    AND
	              te_glosa     = glosa
END IF

END FUNCTION		



FUNCTION fl_lee_auxiliares_ventas(cod_cia, cod_loc, modulo, bodega, grupo_linea)
DEFINE cod_cia		LIKE ctbt040.b40_compania
DEFINE cod_loc		LIKE ctbt040.b40_localidad
DEFINE modulo		LIKE ctbt040.b40_modulo
DEFINE bodega		LIKE ctbt040.b40_bodega
DEFINE grupo_linea	LIKE ctbt040.b40_grupo_linea
DEFINE r		RECORD LIKE ctbt040.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt040
	WHERE b40_compania    = cod_cia AND 
	      b40_localidad   = cod_loc AND 
	      b40_modulo      = modulo  AND 
	      b40_bodega      = bodega  AND 
	      b40_grupo_linea = grupo_linea
RETURN r.*

END FUNCTION



FUNCTION fl_lee_auxiliares_caja(cod_cia, cod_loc, modulo, grupo_linea)
DEFINE cod_cia		LIKE ctbt040.b40_compania
DEFINE cod_loc		LIKE ctbt040.b40_localidad
DEFINE modulo		LIKE ctbt040.b40_modulo
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE r		RECORD LIKE ctbt041.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt041
	WHERE b41_compania    = cod_cia AND 
	      b41_localidad   = cod_loc AND 
	      b41_modulo      = modulo  AND
	      b41_grupo_linea = grupo_linea
RETURN r.*

END FUNCTION



FUNCTION fl_lee_auxiliares_generales(cod_cia, cod_loc)
DEFINE cod_cia		LIKE ctbt040.b40_compania
DEFINE cod_loc		LIKE ctbt040.b40_localidad
DEFINE r		RECORD LIKE ctbt042.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt042
	WHERE b42_compania    = cod_cia AND 
	      b42_localidad   = cod_loc
RETURN r.*

END FUNCTION



FUNCTION chequea_saldo_fact_devuelta(r_fact, fec_dev)
DEFINE r_fact		RECORD LIKE rept019.*
DEFINE r_r25		RECORD LIKE rept025.*
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE saldo_fact	DECIMAL(14,2)
DEFINE tot_pag		DECIMAL(14,2)
DEFINE fec_dev		LIKE rept019.r19_fecing
DEFINE num_doc		LIKE cxct020.z20_num_doc

SELECT * INTO r_r25.* FROM acero_gc:rept025
	WHERE r25_compania  = r_fact.r19_compania  AND 
	      r25_localidad = r_fact.r19_localidad AND 
	      r25_cod_tran  = r_fact.r19_cod_tran  AND 
	      r25_num_tran  = r_fact.r19_num_tran
IF status = NOTFOUND THEN
	LET r_r25.r25_valor_ant  = 0
	LET r_r25.r25_valor_cred = 0
END IF
SELECT SUM(z20_valor_cap) INTO saldo_fact FROM acero_gc:cxct020
	WHERE z20_compania  = r_fact.r19_compania  AND 
	      z20_localidad = r_fact.r19_localidad AND 
	      z20_cod_tran  = r_fact.r19_cod_tran  AND 
	      z20_num_tran  = r_fact.r19_num_tran  AND 
	      z20_codcli    = r_fact.r19_codcli    AND
	      z20_dividendo <> 0
IF saldo_fact IS NULL THEN
	CALL fl_mostrar_mensaje('Factura crédito no existe en  ' || 
					 'módulo de Cobranzas.', 'stop')
	ROLLBACK WORK
	EXIT PROGRAM
END IF	
LET num_doc = r_fact.r19_num_tran
DECLARE q_lito CURSOR FOR SELECT * FROM acero_gc:cxct023
	WHERE z23_compania  = r_fact.r19_compania  AND 
	      z23_localidad = r_fact.r19_localidad AND 
	      z23_codcli    = r_fact.r19_codcli    AND 
	      z23_tipo_doc  = r_fact.r19_cod_tran  AND 
	      z23_num_doc   = num_doc              AND 
	      z23_div_doc   > 0
LET tot_pag = 0
FOREACH q_lito INTO r_z23.*
	CALL integ_fl_lee_transaccion_cxc(r_z23.z23_compania, r_z23.z23_localidad, 
		r_z23.z23_codcli, r_z23.z23_tipo_trn, r_z23.z23_num_trn)
		RETURNING r_z22.*
	IF r_z22.z22_fecing > fec_dev THEN
		CONTINUE FOREACH
	END IF
	IF r_z23.z23_tipo_trn = 'AJ' AND r_z22.z22_origen = 'A' AND
		DATE(r_z22.z22_fecing) = DATE(fec_dev) THEN
		CONTINUE FOREACH
	END IF
	LET tot_pag = tot_pag + r_z23.z23_valor_cap
END FOREACH 
LET saldo_fact = saldo_fact + tot_pag	
RETURN saldo_fact

END FUNCTION



FUNCTION integ_fl_lee_cabecera_transaccion_rep(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE rept019.r19_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r		RECORD LIKE rept019.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM acero_gc:rept019 
	WHERE r19_compania = cod_cia AND r19_localidad = cod_loc AND 
	      r19_cod_tran = cod_tran AND r19_num_tran = num_tran
RETURN r.*

END FUNCTION



FUNCTION integ_fl_lee_codigo_caja_caja(cod_cia, cod_loc, caja)
DEFINE cod_cia		LIKE cajt002.j02_compania
DEFINE cod_loc		LIKE cajt002.j02_localidad
DEFINE caja		LIKE cajt002.j02_codigo_caja
DEFINE r		RECORD LIKE cajt002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM acero_gc:cajt002 
	WHERE j02_compania    = cod_cia AND 
	      j02_localidad   = cod_loc AND 
	      j02_codigo_caja = caja
RETURN r.*

END FUNCTION



FUNCTION integ_fl_lee_transaccion_cxc(cod_cia, cod_loc, codcli, tipo_trn, num_trn)
DEFINE cod_cia		LIKE cxct022.z22_compania
DEFINE cod_loc		LIKE cxct022.z22_localidad
DEFINE codcli		LIKE cxct022.z22_codcli
DEFINE tipo_trn		LIKE cxct022.z22_tipo_trn
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE r		RECORD LIKE cxct022.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM acero_gc:cxct022 
	WHERE z22_compania  = cod_cia  AND 
	      z22_localidad = cod_loc  AND 
	      z22_codcli    = codcli   AND 
	      z22_tipo_trn  = tipo_trn AND 
	      z22_num_trn   = num_trn 
RETURN r.*

END FUNCTION

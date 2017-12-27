GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_programa      VARCHAR(12)
DEFINE rm_crep			RECORD LIKE rept019.*
DEFINE rm_auxv			RECORD LIKE ctbt040.*
DEFINE rm_auxc			RECORD LIKE ctbt041.*
DEFINE rm_auxg			RECORD LIKE ctbt042.*
DEFINE rm_ctb			RECORD LIKE ctbt000.*
DEFINE rm_c10			RECORD LIKE ordt010.*
DEFINE rm_r28			RECORD LIKE rept028.*
DEFINE vm_modulo		LIKE gent050.g50_modulo
DEFINE vm_tipo_comp		LIKE ctbt012.b12_tipo_comp
DEFINE vm_indice		SMALLINT
DEFINE vm_fecha_ini		DATE
DEFINE vm_fecha_fin		DATE
DEFINE vm_fec_emi_fact	LIKE ordt013.c13_fec_emi_fac
DEFINE vm_cod_tran		LIKE rept019.r19_cod_tran
DEFINE vm_num_tran		LIKE rept019.r19_num_tran
DEFINE vm_fact_anu		SMALLINT



FUNCTION fl_control_master_contab_repuestos(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE cod_tran_a	LIKE rept019.r19_cod_tran
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp
DEFINE hecho		SMALLINT
DEFINE flag_fac_dev	SMALLINT

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
IF cod_tran = 'TC' OR cod_tran = 'CI' THEN
	LET cod_tran_a = cod_tran
	LET cod_tran   = 'AC'
END IF
CALL fl_lee_cabecera_transaccion_rep(cod_cia, cod_loc, cod_tran, num_tran)
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
	 --te_glosa		CHAR(35),
	 te_glosa		CHAR(90),
	 te_tipo_mov		CHAR(1),
	 te_valor		DECIMAL(14,2),
	 te_indice		SMALLINT)
DECLARE q_drep CURSOR FOR SELECT * FROM rept020
	WHERE r20_compania  = rm_crep.r19_compania  AND 
	      r20_localidad = rm_crep.r19_localidad AND 
	      r20_cod_tran  = rm_crep.r19_cod_tran  AND 
	      r20_num_tran  = rm_crep.r19_num_tran
IF cod_tran_a = 'TC' OR cod_tran_a = 'CI' THEN
	LET rm_crep.r19_cod_tran = cod_tran_a
END IF
CASE rm_crep.r19_cod_tran 
	WHEN 'FA'
		CALL fl_contabiliza_venta_repuestos(8)
		LET vm_indice = vm_indice + 1
	WHEN 'NE'
		LET flag_fac_dev = 0
		IF rm_crep.r19_tipo_dev = 'DF' OR rm_crep.r19_tipo_dev = 'AF' THEN
			LET flag_fac_dev = 1
		END IF
		CALL fl_contabiliza_costo_venta_repuestos(27, flag_fac_dev)
		LET vm_indice = vm_indice + 1
	WHEN 'AF'
		CALL fl_contabiliza_anulacion_fact_repuestos(10)
		LET vm_indice = vm_indice + 1
	WHEN 'DF'
		LET vm_fact_anu = 0
		CALL fl_contabiliza_dev_venta_repuestos(10)
		LET vm_indice = vm_indice + 1
		{--
		IF vm_fact_anu = 0 THEN
			CALL fl_contabiliza_costo_venta_repuestos(27, 1)
			LET vm_indice = vm_indice + 1
		END IF
		--}
	WHEN 'IM'
		CALL fl_contabiliza_importaciones(15)
		LET vm_indice = vm_indice + 1
	WHEN 'RQ'
		CALL fl_contabiliza_requisiciones_taller(46)
		LET vm_indice = vm_indice + 1
	WHEN 'DR'
		CALL fl_contabiliza_requisiciones_taller(46)
		LET vm_indice = vm_indice + 1
	WHEN 'TC'
		CALL fl_contabiliza_ajustes_inventario(59)
		LET vm_indice = vm_indice + 1
	WHEN 'CI'
		CALL fl_contabiliza_ajustes_inventario(67)
		LET vm_indice = vm_indice + 1
	WHEN 'AC'
		CALL fl_contabiliza_ajustes_inventario(17)
		LET vm_indice = vm_indice + 1
	WHEN 'A+'
		CALL fl_contabiliza_ajustes_inventario(17)
		LET vm_indice = vm_indice + 1
	WHEN 'A-'
		CALL fl_contabiliza_ajustes_inventario(17)
		LET vm_indice = vm_indice + 1
	WHEN 'CL'
		CALL fl_contabiliza_compras_locales(18)
		LET vm_indice = vm_indice + 1
	WHEN 'DC'
		CALL fl_contabiliza_dev_compras_locales(18)
		LET vm_indice = vm_indice + 1
	WHEN 'TR'
		CALL fl_contabiliza_transferencias(25) RETURNING hecho
		IF NOT hecho THEN
			DROP TABLE te_master
			RETURN
		END IF 
		LET vm_indice = vm_indice + 1
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
DEFINE tot_otros	DECIMAL(14,2)
DEFINE tot_ret		DECIMAL(14,2)
DEFINE val_iva		DECIMAL(14,2)
DEFINE tot_comp		DECIMAL(14,2)
DEFINE dif, dif_abs	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE aux_ret		LIKE ctbt010.b10_cuenta
DEFINE r_fpc		RECORD LIKE rept025.*
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE r_cj		RECORD LIKE cajt010.*
DEFINE r_dj, r_caca	RECORD LIKE cajt011.*
DEFINE r_tj		RECORD LIKE gent010.*
DEFINE r_bco		RECORD LIKE gent009.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_j91		RECORD LIKE cajt091.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_z09		RECORD LIKE cxct009.*

LET tot_efe   = 0
LET tot_tar   = 0
LET tot_dep   = 0
LET tot_otros = 0
LET tot_ret   = 0
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
SELECT * INTO r_fpc.* FROM rept025
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
		vm_modulo, rm_crep.r19_bodega_ori, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_retorna_aux_ventas(r_drep.r20_compania, r_drep.r20_localidad,
				vm_modulo, rm_crep.r19_bodega_ori,
				r_lr.r03_grupo_linea, rm_crep.r19_porc_impto,
				rm_crep.r19_codcli)
	RETURNING rm_auxv.*
SELECT * INTO r_cj.* FROM cajt010
	WHERE j10_compania     = rm_crep.r19_compania  AND 
	      j10_localidad    = rm_crep.r19_localidad AND 
	      j10_tipo_fuente  = 'PR'                  AND 
	      j10_tipo_destino = rm_crep.r19_cod_tran  AND
	      j10_num_destino  = rm_crep.r19_num_tran
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro de caja en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_codigo_caja_caja(rm_crep.r19_compania, rm_crep.r19_localidad, 
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
DECLARE q_dcaj CURSOR FOR SELECT * FROM cajt011
	WHERE j11_compania     = r_cj.j10_compania    AND 
	      j11_localidad    = r_cj.j10_localidad   AND 
	      j11_tipo_fuente  = r_cj.j10_tipo_fuente AND
	      j11_num_fuente   = r_cj.j10_num_fuente
FOREACH q_dcaj INTO r_dj.*
	LET r_dj.j11_valor = r_dj.j11_valor * r_dj.j11_paridad
	CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, r_dj.j11_valor)
		RETURNING r_dj.j11_valor
	IF r_dj.j11_codigo_pago[1, 1] = 'T' THEN
		LET tot_tar  = tot_tar + r_dj.j11_valor 
		LET r_caca.* = r_dj.*
	END IF
	CASE r_dj.j11_codigo_pago
		WHEN 'EF'
			LET tot_efe  = tot_efe + r_dj.j11_valor 
		WHEN 'CH'
			LET tot_efe  = tot_efe + r_dj.j11_valor 
		WHEN 'DP'
			LET tot_dep = tot_dep + r_dj.j11_valor 
			CALL fl_lee_banco_compania(r_dj.j11_compania, r_dj.j11_cod_bco_tarj, r_dj.j11_num_cta_tarj)
				RETURNING r_bco.*
			IF r_bco.g09_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe banco/cuenta: ' || r_dj.j11_cod_bco_tarj || ' ' || r_dj.j11_num_cta_tarj, 'stop')
				EXIT PROGRAM
			END IF
			CALL fl_genera_detalle_comprobante(vm_tipo_comp,subtipo,
				r_bco.g09_aux_cont, 'D', r_dj.j11_valor, glosa,
        		        rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
		--WHEN 'RT' LET tot_ret = tot_ret + r_dj.j11_valor
		OTHERWISE
			IF r_dj.j11_codigo_pago[1, 1] <> 'T' THEN
			IF NOT fl_determinar_si_es_retencion(r_dj.j11_compania,
				r_dj.j11_codigo_pago, rm_crep.r19_cont_cred)
			THEN
				LET tot_otros = tot_otros + r_dj.j11_valor
			-- CODIGO FORMA DE PAGO
				CALL fl_lee_tipo_pago_caja(r_cj.j10_compania,
							r_dj.j11_codigo_pago,
							rm_crep.r19_cont_cred)
					RETURNING r_j01.*
				IF r_j01.j01_aux_cont IS NOT NULL THEN
				CALL fl_genera_detalle_comprobante(vm_tipo_comp,
					subtipo, r_j01.j01_aux_cont, 'D',
					r_dj.j11_valor, glosa,
					r_cj.j10_tipo_destino,
					r_cj.j10_num_destino)
				ELSE
					CALL fl_mostrar_mensaje('No existe Auxiliar Contable para la Forma de Pago ' || r_dj.j11_codigo_pago || '.', 'stop')
					EXIT PROGRAM
				END IF
			--
			ELSE
				LET tot_ret = tot_ret + r_dj.j11_valor
			END IF
			END IF
	END CASE
END FOREACH
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_flete, 
	'H', rm_crep.r19_flete, glosa, rm_crep.r19_cod_tran, 
        rm_crep.r19_num_tran)
LET tot_comp = tot_efe + tot_tar + tot_dep + tot_ret + r_fpc.r25_valor_ant +
		r_fpc.r25_valor_cred + tot_otros
LET dif     = rm_crep.r19_tot_neto - tot_comp
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

{-- FORMA ANTERIOR DE CONTABILIZAR RETENCIONES DE CONTADO
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxg.b42_retencion,
	'D', tot_ret, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
--}
IF tot_ret > 0 THEN
	FOREACH q_dcaj INTO r_dj.*
		IF NOT fl_determinar_si_es_retencion(r_dj.j11_compania,
				r_dj.j11_codigo_pago, rm_crep.r19_cont_cred)
		THEN
			CONTINUE FOREACH
		END IF
		DECLARE q_j14 CURSOR FOR
			SELECT * FROM cajt014
				WHERE j14_compania    = r_dj.j11_compania
				  AND j14_localidad   = r_dj.j11_localidad
				  AND j14_tipo_fuente = r_dj.j11_tipo_fuente
				  AND j14_num_fuente  = r_dj.j11_num_fuente
				  AND j14_secuencia   = r_dj.j11_secuencia
				  AND j14_codigo_pago = r_dj.j11_codigo_pago
				ORDER BY j14_sec_ret
		LET aux_ret = rm_auxg.b42_retencion
		FOREACH q_j14 INTO r_j14.*
			CALL fl_lee_det_retencion_cli(r_j14.j14_compania,
							r_cj.j10_codcli,
							r_j14.j14_tipo_ret,
							r_j14.j14_porc_ret,
							r_j14.j14_codigo_sri,
							r_j14.j14_fec_ini_porc,
							r_dj.j11_codigo_pago,
							rm_crep.r19_cont_cred)
				RETURNING r_z09.*
			IF r_z09.z09_aux_cont IS NOT NULL THEN
				LET aux_ret = r_z09.z09_aux_cont
			ELSE
				CALL fl_lee_det_tipo_ret_caja(r_cj.j10_compania,
							r_dj.j11_codigo_pago,
							rm_crep.r19_cont_cred,
							r_j14.j14_tipo_ret,
							r_j14.j14_porc_ret)
					RETURNING r_j91.*
				IF r_j91.j91_aux_cont IS NOT NULL THEN
					LET aux_ret = r_j91.j91_aux_cont
				ELSE
					CALL fl_lee_tipo_pago_caja(
							r_cj.j10_compania,
							r_dj.j11_codigo_pago,
							rm_crep.r19_cont_cred)
						RETURNING r_j01.*
					IF r_j01.j01_aux_cont IS NOT NULL THEN
						LET aux_ret = r_j01.j01_aux_cont
					END IF
				END IF
			END IF
			CALL fl_genera_detalle_comprobante(vm_tipo_comp,subtipo,
				aux_ret, 'D', r_j14.j14_valor_ret, glosa,
				rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
		END FOREACH
	END FOREACH
END IF

CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb,'D',
        r_fpc.r25_valor_cred, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxc.b41_ant_mb,'D',
	r_fpc.r25_valor_ant, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
IF tot_tar > 0 THEN
	LET r_dj.* = r_caca.*
	DECLARE q_dcaj2 CURSOR FOR
		SELECT * FROM cajt011
			WHERE j11_compania          = r_dj.j11_compania
			  AND j11_localidad         = r_dj.j11_localidad
			  AND j11_tipo_fuente       = r_dj.j11_tipo_fuente
			  AND j11_num_fuente        = r_dj.j11_num_fuente
			  AND j11_codigo_pago[1, 1] = 'T'
	FOREACH q_dcaj2 INTO r_dj.*
		CALL fl_lee_tarjeta_credito(r_dj.j11_compania,
						r_dj.j11_cod_bco_tarj,
						r_dj.j11_codigo_pago,
						rm_crep.r19_cont_cred)
			RETURNING r_tj.*
		IF r_tj.g10_codcobr IS NOT NULL THEN
			CALL fl_lee_cliente_localidad(rm_crep.r19_compania,
							rm_crep.r19_localidad,
							r_tj.g10_codcobr)
				RETURNING r_z02.*
			IF rm_crep.r19_moneda <> rg_gen.g00_moneda_base THEN
				IF r_z02.z02_aux_clte_ma IS NOT NULL THEN
					LET r_z02.z02_aux_clte_mb =
							r_z02.z02_aux_clte_ma
				END IF
			END IF
			IF r_z02.z02_aux_clte_mb IS NOT NULL THEN
				LET rm_auxc.b41_cxc_mb = r_z02.z02_aux_clte_mb
			END IF
			IF rm_auxc.b41_cxc_mb IS NULL THEN
				CALL fl_lee_tipo_pago_caja(r_cj.j10_compania,
							r_dj.j11_codigo_pago,
							rm_crep.r19_cont_cred)
					RETURNING r_j01.*
				LET rm_auxc.b41_cxc_mb = r_j01.j01_aux_cont
			END IF
			IF rm_auxc.b41_cxc_mb IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado auxiliar contable para la Tarjeta de Credito: ' || r_tj.g10_nombre CLIPPED || '. Por favor llame al ADMINISTRADOR.', 'stop')
				EXIT PROGRAM
			END IF
		END IF
		CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo,
				rm_auxc.b41_cxc_mb, 'D', r_dj.j11_valor, glosa,
				rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
	END FOREACH
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
		vm_modulo, rm_crep.r19_bodega_ori, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_retorna_aux_ventas(r_drep.r20_compania, r_drep.r20_localidad,
				vm_modulo, rm_crep.r19_bodega_ori,
				r_lr.r03_grupo_linea, rm_crep.r19_porc_impto,
				rm_crep.r19_codcli)
	RETURNING rm_auxv.*
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



FUNCTION fl_contabiliza_importaciones(subtipo)
DEFINE tot_costo	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE pedido		LIKE rept016.r16_pedido

CALL fl_lee_liquidacion_rep(rm_crep.r19_compania, rm_crep.r19_localidad, 
	rm_crep.r19_numliq)
	RETURNING rm_r28.*
LET tot_costo = 0
FOREACH q_drep INTO r_drep.*
	LET tot_costo = tot_costo + (r_drep.r20_cant_ven * r_drep.r20_costo)
END FOREACH
LET tot_costo = rm_crep.r19_tot_costo		-- OJO NUEVO
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, tot_costo)
	RETURNING tot_costo
CALL fl_lee_linea_rep(r_drep.r20_compania, r_drep.r20_linea)
	RETURNING r_lr.*
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
		vm_modulo, rm_crep.r19_bodega_dest, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
SELECT r29_pedido INTO pedido FROM rept029
	WHERE r29_compania   = rm_crep.r19_compania
	  AND r29_localidad = rm_crep.r19_localidad
	  AND r29_numliq    = rm_crep.r19_numliq
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe pedido en rept029 ' || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_pedido_rep(rm_crep.r19_compania, rm_crep.r19_localidad, pedido)
	RETURNING r_r16.*
IF r_r16.r16_aux_cont IS NOT NULL THEN
	LET rm_auxv.b40_transito = r_r16.r16_aux_cont
END IF
LET glosa = rm_crep.r19_cod_tran, ' - ', rm_crep.r19_num_tran
	    USING '<<<<<<<<<<<<<<<'
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_inventario, 'D',
        tot_costo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_transito,
        'H', tot_costo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)

END FUNCTION



FUNCTION fl_contabiliza_anulacion_fact_repuestos(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_fact		RECORD LIKE rept019.*
DEFINE r_r40		RECORD LIKE rept040.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE i		SMALLINT

DEFINE fecha_actual DATETIME YEAR TO SECOND

CALL fl_lee_cabecera_transaccion_rep(rm_crep.r19_compania,rm_crep.r19_localidad,
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
	LET fecha_actual = fl_current()
	UPDATE ctbt012 SET b12_estado     = 'E',
			   b12_fec_modifi = fecha_actual 
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

CALL fl_lee_cabecera_transaccion_rep(rm_crep.r19_compania,rm_crep.r19_localidad,
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
LET val_iva = rm_crep.r19_tot_neto - rm_crep.r19_flete -
		(rm_crep.r19_tot_bruto - rm_crep.r19_tot_dscto)
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
		vm_modulo, rm_crep.r19_bodega_ori, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_retorna_aux_ventas(r_drep.r20_compania, r_drep.r20_localidad,
				vm_modulo, rm_crep.r19_bodega_ori,
				r_lr.r03_grupo_linea, rm_crep.r19_porc_impto,
				rm_crep.r19_codcli)
	RETURNING rm_auxv.*
LET glosa = rm_crep.r19_nomcli[1,25], ' ', rm_crep.r19_cod_tran, '-',
	    rm_crep.r19_num_tran USING '<<<<<<<<<<<<<<<'
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_flete, 
	'D', rm_crep.r19_flete, glosa, rm_crep.r19_cod_tran, 
        rm_crep.r19_num_tran)
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
 


FUNCTION fl_contabiliza_requisiciones_taller(subtipo)
DEFINE tot_costo	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_b43		RECORD LIKE ctbt043.*
DEFINE signo1		CHAR(1)
DEFINE signo2		CHAR(1)

CALL fl_lee_orden_trabajo(rm_crep.r19_compania, rm_crep.r19_localidad, 
			  rm_crep.r19_ord_trabajo)
	RETURNING r_t23.*
IF r_t23.t23_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe O.T.: ' || 
		rm_crep.r19_ord_trabajo || ' en transacci{on: ' ||
 		r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_tipo_vehiculo(r_t23.t23_compania, r_t23.t23_modelo)
	RETURNING r_t04.*
CALL fl_lee_linea_taller(r_t04.t04_compania, r_t04.t04_linea)
	RETURNING r_t01.*
CALL fl_lee_auxiliares_taller(r_t23.t23_compania, r_t23.t23_localidad,
		r_t01.t01_grupo_linea, r_t23.t23_porc_impto)
	RETURNING r_b43.*
IF r_b43.b43_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables en Taller para grupo-línea: ' || r_t01.t01_grupo_linea || 
	' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET tot_costo = 0
FOREACH q_drep INTO r_drep.*
	LET tot_costo = tot_costo + (r_drep.r20_cant_ven * r_drep.r20_costo)
END FOREACH
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, tot_costo)
	RETURNING tot_costo
CALL fl_lee_linea_rep(r_drep.r20_compania, r_drep.r20_linea)
	RETURNING r_lr.*
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
		vm_modulo, rm_crep.r19_bodega_dest, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_crep.r19_cod_tran, ' - ', rm_crep.r19_num_tran
	    USING '<<<<<<<<<<<<<<<'
LET signo1 = 'D'
LET signo2 = 'H'
IF rm_crep.r19_cod_tran = 'DR' THEN
	LET signo1 = 'H'
	LET signo2 = 'D'
END IF
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, r_b43.b43_pro_rp_alm, signo1,
        tot_costo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_inventario, signo2,
        tot_costo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)

END FUNCTION



FUNCTION fl_contabiliza_ajustes_inventario(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE cod_tran_a	LIKE rept019.r19_cod_tran
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE tot_costo	DECIMAL(14,2)
DEFINE signo1, signo2	CHAR(1)

LET cod_tran_a = 'AC'
IF rm_crep.r19_cod_tran = 'TC' OR rm_crep.r19_cod_tran = 'CI' THEN
	LET rm_crep.r19_cod_tran = 'AC'
END IF
LET tot_costo = 0
FOREACH q_drep INTO r_drep.*
	IF rm_crep.r19_cod_tran = 'AC' THEN
		IF subtipo = 59 OR subtipo = 67 THEN
			IF subtipo = 59 THEN
				LET tot_costo  = tot_costo +
							(r_drep.r20_cant_ven *
							r_drep.r20_costnue_mb)
			END IF
			IF subtipo = 67 THEN
				LET tot_costo  = tot_costo +
							r_drep.r20_costnue_mb
			END IF
			LET cod_tran_a = 'TC'
			IF subtipo = 67 THEN
				LET cod_tran_a = 'CI'
			END IF
		ELSE
			LET tot_costo  = tot_costo + (r_drep.r20_stock_ant *
			    (r_drep.r20_costnue_mb - r_drep.r20_costant_mb))
		END IF
	ELSE 
		LET tot_costo = tot_costo + (r_drep.r20_cant_ven * 
		     		r_drep.r20_costo)
	END IF
END FOREACH
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, tot_costo)
	RETURNING tot_costo
CALL fl_lee_linea_rep(r_drep.r20_compania, r_drep.r20_linea)
	RETURNING r_lr.*
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
		vm_modulo, rm_crep.r19_bodega_dest, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_crep.r19_cod_tran, ' - ', rm_crep.r19_num_tran
	    USING '<<<<<<<<<<<<<<<'
LET signo1 = 'D'
LET signo2 = 'H'
IF tot_costo < 0 OR rm_crep.r19_cod_tran = 'A-' THEN
	LET signo1 = 'H'
	LET signo2 = 'D'
	IF tot_costo < 0 THEN
		LET tot_costo = tot_costo * -1
	END IF
END IF
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo,rm_auxv.b40_inventario,
			signo1, tot_costo, glosa, rm_crep.r19_cod_tran,
			rm_crep.r19_num_tran)
IF cod_tran_a <> 'TC' AND cod_tran_a <> 'CI' THEN
	CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo,
			rm_auxv.b40_ajustes, signo2, tot_costo, glosa,
			rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
ELSE
	CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo,
			rm_auxv.b40_inventario, signo2, tot_costo, glosa,
			rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
END IF

END FUNCTION



FUNCTION fl_contabiliza_compras_locales(subtipo)
DEFINE tot_ret		DECIMAL(14,2)
DEFINE val_iva		DECIMAL(14,2)
DEFINE val_prov		DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_s23		RECORD LIKE srit023.*
DEFINE tributa		LIKE srit023.s23_tributa

LET glosa = rm_crep.r19_cod_tran, ' - ', rm_crep.r19_num_tran
	    USING '<<<<<<<<<<<<<<<'
CALL fl_lee_orden_compra(rm_crep.r19_compania, rm_crep.r19_localidad, 
			 rm_crep.r19_oc_interna)
	RETURNING rm_c10.*
IF rm_c10.c10_compania IS NULL THEN 
	CALL fl_mostrar_mensaje('No existe O/C: ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proveedor(rm_c10.c10_codprov) RETURNING r_p01.*
DECLARE q_clok CURSOR FOR
	SELECT * FROM ordt013
		WHERE c13_compania  = rm_crep.r19_compania   AND 
		      c13_localidad = rm_crep.r19_localidad  AND 
		      c13_numero_oc = rm_crep.r19_oc_interna AND
		      c13_fecha_recep = rm_crep.r19_fecing 
		ORDER BY c13_num_recep DESC
OPEN q_clok 
FETCH q_clok INTO r_c13.*
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No hay recepción en ordt013: ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET vm_fec_emi_fact = r_c13.c13_fec_emi_fac
LET glosa = r_p01.p01_nomprov[1,19], ' ', r_c13.c13_factura
IF rm_crep.r19_tot_neto <> r_c13.c13_tot_recep THEN
	CALL fl_mostrar_mensaje('No cuadra total neto en rept019 y ordt013: ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	EXIT PROGRAM
END IF
DECLARE qu_drt CURSOR FOR SELECT * FROM cxpt028
	WHERE p28_compania  = rm_crep.r19_compania   AND 
	      p28_localidad = rm_crep.r19_localidad  AND 
	      p28_num_ret   = rm_crep.r19_num_ret
LET tot_ret = 0
FOREACH qu_drt INTO r_p28.*
	CALL fl_lee_tipo_retencion(rm_crep.r19_compania, r_p28.p28_tipo_ret,
			   r_p28.p28_porcentaje)
	RETURNING r_c02.*
	IF r_c02.c02_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo retención en ordt002: ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
		EXIT PROGRAM
	END IF
	LET tot_ret = tot_ret + r_p28.p28_valor_ret
	CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, r_c02.c02_aux_cont,'H',
	r_p28.p28_valor_ret, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
END FOREACH
LET rm_crep.r19_tot_bruto = rm_crep.r19_tot_bruto * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_bruto)
	RETURNING rm_crep.r19_tot_bruto
LET rm_crep.r19_tot_dscto = rm_crep.r19_tot_dscto * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_dscto)
	RETURNING rm_crep.r19_tot_dscto
LET rm_crep.r19_tot_neto  = rm_crep.r19_tot_neto  * rm_crep.r19_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_crep.r19_tot_neto)
	RETURNING rm_crep.r19_tot_neto
LET rm_crep.r19_tot_bruto = rm_crep.r19_tot_bruto - rm_crep.r19_tot_dscto +
			    + r_c13.c13_flete + r_c13.c13_otros 
LET val_iva = r_c13.c13_tot_impto
LET val_prov = rm_crep.r19_tot_neto - tot_ret
CALL fl_lee_auxiliares_generales(rm_crep.r19_compania, rm_crep.r19_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
OPEN q_drep
FETCH q_drep INTO r_drep.*
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Compra local no tiene detalle: ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_linea_rep(r_drep.r20_compania, r_drep.r20_linea)
	RETURNING r_lr.*
IF r_lr.r03_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe línea de venta: ' || r_drep.r20_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
		vm_modulo, rm_crep.r19_bodega_ori, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proveedor_localidad(rm_crep.r19_compania, rm_crep.r19_localidad, 
	rm_c10.c10_codprov)
	RETURNING r_p02.*
IF r_p02.p02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe proveedor: ' || rm_crep.r19_codcli || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_inventario, 'D',
        rm_crep.r19_tot_bruto, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
LET tributa = 'S'
IF val_iva = 0 THEN
	LET tributa = 'N'
END IF
CALL fl_obtener_aux_cont_sust(rm_crep.r19_compania, rm_c10.c10_tipo_orden,
				tributa)
	RETURNING r_s23.*
IF r_s23.s23_aux_cont IS NOT NULL THEN
	LET rm_auxg.b42_iva_compra = r_s23.s23_aux_cont
END IF
IF rm_c10.c10_sustento_sri = 'S' THEN
	CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxg.b42_iva_compra, 'D',
        val_iva, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
END IF
IF rm_crep.r19_moneda <> rg_gen.g00_moneda_base THEN
	LET r_p02.p02_aux_prov_mb = r_p02.p02_aux_prov_ma
END IF
LET glosa = 'COMPRA FACT # ', rm_crep.r19_oc_externa CLIPPED, ' ',
		rm_crep.r19_cod_tran, ' # ', rm_crep.r19_num_tran
		USING "<<<<<<<<<&"
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, r_p02.p02_aux_prov_mb,
        'H', val_prov, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)

END FUNCTION



FUNCTION fl_contabiliza_dev_compras_locales(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_comp		RECORD LIKE rept019.*
DEFINE r_r40		RECORD LIKE rept040.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE i		SMALLINT

DEFINE fecha_actual DATETIME YEAR TO SECOND

CALL fl_lee_cabecera_transaccion_rep(rm_crep.r19_compania,rm_crep.r19_localidad,
	rm_crep.r19_tipo_dev, rm_crep.r19_num_dev)
	RETURNING r_comp.*
IF r_comp.r19_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compra local devuelta : ' || rm_crep.r19_cod_tran || ' ' || rm_crep.r19_num_tran, 'stop')
	RETURN
END IF
IF rm_crep.r19_tot_neto = r_comp.r19_tot_neto THEN
	DECLARE cu_cld CURSOR WITH HOLD FOR 
		SELECT * FROM rept040
			WHERE r40_compania  = r_comp.r19_compania  AND 
		              r40_localidad = r_comp.r19_localidad AND 
		              r40_cod_tran  = r_comp.r19_cod_tran  AND 
		              r40_num_tran  = r_comp.r19_num_tran
		        ORDER BY r40_num_comp DESC
	LET i = 0
	OPEN cu_cld
	FETCH cu_cld INTO r_r40.*
	LET i = i + 1
	CALL fl_lee_comprobante_contable(r_comp.r19_compania, 
			r_r40.r40_tipo_comp, r_r40.r40_num_comp)
		RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe en ctbt012 comprobante de la rept040.', 'stop')
		EXIT PROGRAM
	END IF
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'D')
	CALL fl_lee_comprobante_contable(r_comp.r19_compania, 
			r_r40.r40_tipo_comp, r_r40.r40_num_comp)
		RETURNING r_b12.*
	SET LOCK MODE TO WAIT 5
	LET fecha_actual = fl_current()
	UPDATE ctbt012 SET b12_estado     = 'E',
			   b12_fec_modifi = fecha_actual 
		WHERE b12_compania  = r_b12.b12_compania  AND 
		      b12_tipo_comp = r_b12.b12_tipo_comp AND 
		      b12_num_comp  = r_b12.b12_num_comp
	INSERT INTO rept040 VALUES (rm_crep.r19_compania, 
		rm_crep.r19_localidad, rm_crep.r19_cod_tran, 
	        rm_crep.r19_num_tran, r_b12.b12_tipo_comp, 
	        r_b12.b12_num_comp)
END IF

END FUNCTION	



FUNCTION fl_contabiliza_transferencias(subtipo)
DEFINE tot_costo	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_lr		RECORD LIKE rept003.*
DEFINE r1_r02, r2_r02	RECORD LIKE rept002.*
DEFINE cuenta        	LIKE ctbt010.b10_cuenta

CALL fl_lee_bodega_rep(vg_codcia, rm_crep.r19_bodega_ori)
	RETURNING r1_r02.*
IF status = NOTFOUND THEN
	RETURN 0
END IF
CALL fl_lee_bodega_rep(vg_codcia, rm_crep.r19_bodega_dest)
	RETURNING r2_r02.*
IF status = NOTFOUND THEN
	RETURN 0
END IF
IF r1_r02.r02_localidad = r2_r02.r02_localidad THEN
	SELECT * FROM rept002
		WHERE r02_compania   = vg_codcia
		  AND r02_codigo     = r1_r02.r02_codigo
		  AND r02_localidad  = vg_codloc
		  AND r02_area       = 'T'
		  AND r02_estado     = 'A'
		  AND r02_factura    = 'N'
		  AND r02_tipo       = 'F'
		  AND r02_tipo_ident = 'E'
	IF STATUS = NOTFOUND THEN
		SELECT * FROM rept002
			WHERE r02_compania   = vg_codcia
			  AND r02_codigo     = r2_r02.r02_codigo
			  AND r02_localidad  = vg_codloc
			  AND r02_area       = 'T'
			  AND r02_estado     = 'A'
			  AND r02_factura    = 'N'
			  AND r02_tipo       = 'F'
			  AND r02_tipo_ident = 'E'
		IF STATUS = NOTFOUND THEN
			RETURN 0
		END IF
	END IF
END IF
LET glosa = rm_crep.r19_cod_tran, '-', 
            rm_crep.r19_num_tran USING '<<<<<<<<<<<<<<<'
LET tot_costo = 0
FOREACH q_drep INTO r_drep.*
	LET tot_costo = tot_costo + (r_drep.r20_cant_ven * r_drep.r20_costo)
END FOREACH
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, tot_costo)
	RETURNING tot_costo
CALL fl_lee_linea_rep(r_drep.r20_compania, r_drep.r20_linea)
	RETURNING r_lr.*
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
		vm_modulo, rm_crep.r19_bodega_dest, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	--CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_dest || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	RETURN 0
END IF
LET cuenta  = rm_auxv.b40_inventario
CALL fl_lee_auxiliares_ventas(r_drep.r20_compania, r_drep.r20_localidad, 
		vm_modulo, rm_crep.r19_bodega_ori, r_lr.r03_grupo_linea,
		rm_crep.r19_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	--CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_crep.r19_bodega_ori || '/' || r_lr.r03_grupo_linea || ' en transacción: ' || r_drep.r20_cod_tran || ' ' || r_drep.r20_num_tran, 'stop')
	RETURN 0
END IF        
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, cuenta, 'D',
        tot_costo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
CALL fl_genera_detalle_comprobante(vm_tipo_comp, subtipo, rm_auxv.b40_inventario,'H', 
      	tot_costo, glosa, rm_crep.r19_cod_tran, rm_crep.r19_num_tran)
RETURN 1

END FUNCTION



FUNCTION fl_genera_comprobantes()
DEFINE tipo_comp	CHAR(2)
DEFINE num_comp		CHAR(8)
DEFINE subtipo		SMALLINT
DEFINE cod_tran		CHAR(2)
DEFINE num_tran		DECIMAL(15,0)
DEFINE cuenta		CHAR(12)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE indice, i	SMALLINT
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_dcomp		RECORD LIKE ctbt013.*
DEFINE pedido		LIKE rept029.r29_pedido
DEFINE nom_cta		LIKE ctbt010.b10_descripcion
DEFINE est_cta		LIKE ctbt010.b10_estado
DEFINE num_sri		LIKE rept038.r38_num_sri
DEFINE mensaje		VARCHAR(200)
        
DECLARE q_mast CURSOR FOR SELECT UNIQUE te_tipo_comp, te_subtipo, te_indice 
	FROM te_master
	ORDER BY 3
IF rm_crep.r19_cod_tran = 'IM' THEN
	INITIALIZE pedido TO NULL
	DECLARE qu_y2k CURSOR FOR 
		SELECT r29_pedido FROM rept029
			WHERE r29_compania  = rm_crep.r19_compania  AND 
			      r29_localidad = rm_crep.r19_localidad AND 
			      r29_numliq    = rm_crep.r19_numliq
	OPEN qu_y2k 
	FETCH qu_y2k INTO pedido
END IF
FOREACH q_mast INTO tipo_comp, subtipo, indice
	INITIALIZE r_ccomp.* TO NULL
	IF vm_cod_tran = 'CL' THEN
		LET r_ccomp.b12_num_comp = fl_numera_comprobante_contable(
										rm_crep.r19_compania,
										tipo_comp,
										YEAR(vm_fec_emi_fact),
										MONTH(vm_fec_emi_fact))
	ELSE
		LET r_ccomp.b12_num_comp = fl_numera_comprobante_contable(
										rm_crep.r19_compania,
										tipo_comp,
										YEAR(rm_crep.r19_fecing),
										MONTH(rm_crep.r19_fecing))
	END IF
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
			IF vm_cod_tran = 'CL' THEN
    			LET r_ccomp.b12_fec_proceso = vm_fec_emi_fact
			END IF
    		LET r_ccomp.b12_glosa	= 'COMPROBANTE: '
			IF vm_cod_tran <> 'FA' AND vm_cod_tran <> 'CL' THEN
				LET r_ccomp.b12_glosa = r_ccomp.b12_glosa CLIPPED, ' ',
							rm_crep.r19_cod_tran, ' ',
							rm_crep.r19_num_tran USING '<<<<<<<<<<<<<<<'
			ELSE
				IF vm_cod_tran = 'FA' THEN
					LET num_sri = NULL
					DECLARE q_num_sri CURSOR FOR
						SELECT r38_num_sri
							FROM rept038
							WHERE r38_compania    = rm_crep.r19_compania
							  AND r38_localidad   = rm_crep.r19_localidad
							  AND r38_tipo_doc    = rm_crep.r19_cod_tran
							  AND r38_tipo_fuente = "PR"
							  AND r38_cod_tran    = rm_crep.r19_cod_tran
							  AND r38_num_tran    = rm_crep.r19_num_tran
					OPEN q_num_sri
					FETCH q_num_sri INTO num_sri
					CLOSE q_num_sri
					FREE q_num_sri
				ELSE
					LET num_sri = rm_crep.r19_oc_externa CLIPPED
				END IF
				LET r_ccomp.b12_glosa = r_ccomp.b12_glosa CLIPPED, ' ',
							rm_crep.r19_cod_tran, ' No. SRI ', num_sri CLIPPED,
							' No. INT. ', 
							rm_crep.r19_num_tran USING '<<<<<<<<<<<<<<<'
			END IF
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
    	LET r_ccomp.b12_fecing 		= fl_current()
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
    		LET r_dcomp.b13_fec_proceso	= r_ccomp.b12_fec_proceso
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
		SELECT b10_descripcion, b10_estado
			INTO nom_cta, est_cta
			FROM ctbt010
			WHERE b10_compania = r_dcomp.b13_compania
			  AND b10_cuenta   = r_dcomp.b13_cuenta
		IF est_cta = 'B' THEN
			ROLLBACK WORK
			LET mensaje = 'La cuenta ', r_dcomp.b13_cuenta CLIPPED,
					' ', nom_cta CLIPPED,' esta BLOQUEADA.',
					' POR FAVOR LLAME AL ADMINISTRADOR.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			EXIT PROGRAM
		END IF
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
		CALL fl_lee_cabecera_transaccion_rep(rm_crep.r19_compania, 
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
IF subtipo <> 59 AND subtipo <> 67 THEN
	SELECT * FROM te_master
		WHERE te_tipo_comp = tipo_comp
		  AND te_subtipo   = subtipo
		  AND te_cuenta    = cuenta
		  AND te_glosa     = glosa
ELSE
	SELECT * FROM te_master
		WHERE te_tipo_comp  = tipo_comp
		  AND te_subtipo    = subtipo
		  AND te_cuenta    <> cuenta
		  AND te_glosa      = glosa
END IF
IF STATUS = NOTFOUND THEN
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



FUNCTION fl_lee_auxiliares_ventas(cod_cia, cod_loc, modulo, bodega, grupo_linea,
					porc_impto)
DEFINE cod_cia		LIKE ctbt040.b40_compania
DEFINE cod_loc		LIKE ctbt040.b40_localidad
DEFINE modulo		LIKE ctbt040.b40_modulo
DEFINE bodega		LIKE ctbt040.b40_bodega
DEFINE grupo_linea	LIKE ctbt040.b40_grupo_linea
DEFINE porc_impto	LIKE ctbt040.b40_porc_impto
DEFINE r		RECORD LIKE ctbt040.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt040
	WHERE b40_compania    = cod_cia
	  AND b40_localidad   = cod_loc
	  AND b40_modulo      = modulo
	  AND b40_bodega      = bodega
	  AND b40_grupo_linea = grupo_linea
	  AND b40_porc_impto  = porc_impto
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



FUNCTION fl_retorna_aux_ventas(cod_cia, cod_loc, modulo, bodega, grupo_linea,
				porc_impto, codcli)
DEFINE cod_cia		LIKE ctbt044.b44_compania
DEFINE cod_loc		LIKE ctbt044.b44_localidad
DEFINE modulo		LIKE ctbt044.b44_modulo
DEFINE bodega		LIKE ctbt044.b44_bodega
DEFINE grupo_linea	LIKE ctbt044.b44_grupo_linea
DEFINE porc_impto	LIKE ctbt044.b44_porc_impto
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE r_b40		RECORD LIKE ctbt040.*
DEFINE r_b44		RECORD LIKE ctbt044.*
DEFINE r_z01		RECORD LIKE cxct001.*

LET r_b40.* = rm_auxv.*
CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
CALL fl_lee_aux_ventas_tipo(cod_cia, cod_loc, modulo, bodega, grupo_linea,
				porc_impto, r_z01.z01_tipo_clte)
	RETURNING r_b44.*
IF r_b44.b44_compania IS NULL THEN
	RETURN r_b40.*
END IF
LET r_b40.b40_venta       = r_b44.b44_venta
LET r_b40.b40_descuento   = r_b44.b44_descuento
LET r_b40.b40_dev_venta   = r_b44.b44_dev_venta
LET r_b40.b40_costo_venta = r_b44.b44_costo_venta
LET r_b40.b40_dev_costo   = r_b44.b44_dev_costo
LET r_b40.b40_inventario  = r_b44.b44_inventario
LET r_b40.b40_transito    = r_b44.b44_transito
LET r_b40.b40_ajustes     = r_b44.b44_ajustes
LET r_b40.b40_flete       = r_b44.b44_flete
RETURN r_b40.*

END FUNCTION



FUNCTION fl_lee_aux_ventas_tipo(cod_cia, cod_loc, modulo, bodega, grupo_linea,
				porc_impto, tipo_cli)
DEFINE cod_cia		LIKE ctbt044.b44_compania
DEFINE cod_loc		LIKE ctbt044.b44_localidad
DEFINE modulo		LIKE ctbt044.b44_modulo
DEFINE bodega		LIKE ctbt044.b44_bodega
DEFINE grupo_linea	LIKE ctbt044.b44_grupo_linea
DEFINE porc_impto	LIKE ctbt044.b44_porc_impto
DEFINE tipo_cli		LIKE ctbt044.b44_tipo_cli
DEFINE r		RECORD LIKE ctbt044.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt044
	WHERE b44_compania    = cod_cia
	  AND b44_localidad   = cod_loc
	  AND b44_modulo      = modulo
	  AND b44_bodega      = bodega
	  AND b44_grupo_linea = grupo_linea
	  AND b44_porc_impto  = porc_impto
	  AND b44_tipo_cli    = tipo_cli
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

--SELECT * INTO r_r25.* FROM acero_qs:rept025
SELECT * INTO r_r25.* FROM rept025
	WHERE r25_compania  = r_fact.r19_compania  AND 
	      r25_localidad = r_fact.r19_localidad AND 
	      r25_cod_tran  = r_fact.r19_cod_tran  AND 
	      r25_num_tran  = r_fact.r19_num_tran
IF status = NOTFOUND THEN
	LET r_r25.r25_valor_ant  = 0
	LET r_r25.r25_valor_cred = 0
END IF
--SELECT SUM(z20_valor_cap) INTO saldo_fact FROM acero_qs:cxct020
SELECT SUM(z20_valor_cap) INTO saldo_fact FROM cxct020
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
--DECLARE q_lito CURSOR FOR SELECT * FROM acero_qs:cxct023
DECLARE q_lito CURSOR FOR SELECT * FROM cxct023
	WHERE z23_compania  = r_fact.r19_compania  AND 
	      z23_localidad = r_fact.r19_localidad AND 
	      z23_codcli    = r_fact.r19_codcli    AND 
	      z23_tipo_doc  = r_fact.r19_cod_tran  AND 
	      z23_num_doc   = num_doc              AND 
	      z23_div_doc   > 0
LET tot_pag = 0
FOREACH q_lito INTO r_z23.*
	CALL fl_lee_transaccion_cxc(r_z23.z23_compania, r_z23.z23_localidad, 
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

GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"

DEFINE vm_programa      VARCHAR(12)
DEFINE rm_caja		RECORD LIKE cajt010.*
DEFINE rm_auxc		RECORD LIKE ctbt041.*
DEFINE rm_auxg		RECORD LIKE ctbt042.*
DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE vm_modulo	LIKE gent050.g50_modulo
DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_indice	SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_tipo_doc	LIKE cxct021.z21_tipo_doc
DEFINE vm_num_doc	LIKE cxct021.z21_num_doc



FUNCTION fl_control_master_contab_ingresos_caja(cod_cia, cod_loc, tipo_fuente, num_fuente)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp

CALL fl_lee_compania_contabilidad(cod_cia) RETURNING rm_ctb.*	
IF rm_ctb.b00_inte_online = 'N' THEN
	RETURN
END IF
LET vm_tipo_doc	 = tipo_fuente
LET vm_modulo    = 'CO'
LET vm_tipo_comp = 'DC'
LET vm_indice    = 1
CALL fl_lee_cabecera_caja(cod_cia, cod_loc, tipo_fuente, num_fuente)
	RETURNING rm_caja.*
IF rm_caja.j10_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe transacción en Caja: ' || tipo_fuente || ' ' || num_fuente, 'stop')
	RETURN
END IF
IF DATE(rm_caja.j10_fecha_pro) <= rm_ctb.b00_fecha_cm THEN
	CALL fl_mostrar_mensaje('La fecha de la transacción corresponde a un mes contable ya cerrado: ' || tipo_fuente || ' ' || num_fuente, 'stop')
	RETURN
END IF
CALL fl_lee_auxiliares_generales(cod_cia, cod_loc)
	RETURNING rm_auxg.*
CREATE TEMP TABLE te_master
	(te_tipo_comp		CHAR(2),
         te_num_comp		CHAR(8),
	 te_subtipo		SMALLINT,
	 te_codcli		INTEGER,
	 te_tipo_doc		CHAR(2),
	 te_num_doc		INTEGER,
         te_cuenta		CHAR(12),
	 --te_glosa		CHAR(35),
	 te_glosa		CHAR(90),
	 te_tipo_mov		CHAR(1),
	 te_valor		DECIMAL(14,2),
	 te_indice		SMALLINT)
DECLARE q_dic CURSOR FOR SELECT * FROM cajt011
	WHERE j11_compania     = rm_caja.j10_compania    AND 
	      j11_localidad    = rm_caja.j10_localidad   AND 
	      j11_tipo_fuente  = rm_caja.j10_tipo_fuente AND
	      j11_num_fuente   = rm_caja.j10_num_fuente
CASE rm_caja.j10_tipo_destino
	WHEN 'PA'
		CALL fl_contabiliza_anticipos(2)
		LET vm_indice = vm_indice + 1
	WHEN 'PG'
		CALL fl_contabiliza_pagos(3)
		LET vm_indice = vm_indice + 1
END CASE
CALL fl_chequea_cuadre_db_cr_1()
BEGIN WORK
CALL fl_genera_comprobantes_caja()
COMMIT WORK
IF rm_ctb.b00_mayo_online = 'N' THEN
	DROP TABLE te_master
	RETURN
END IF
DECLARE q_icm CURSOR WITH HOLD 
	FOR SELECT UNIQUE te_tipo_comp, te_num_comp
	FROM te_master
FOREACH q_icm INTO tipo, num
	CALL fl_mayoriza_comprobante(rm_caja.j10_compania, tipo, num, 'M')
END FOREACH
DROP TABLE te_master

END FUNCTION



FUNCTION fl_contabiliza_anticipos(subtipo)
DEFINE tot_efe		DECIMAL(14,2)
DEFINE tot_otr		DECIMAL(14,2)
DEFINE tot_ic		DECIMAL(14,2)
DEFINE flag		SMALLINT
DEFINE glosa, glo_aux	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_ica		RECORD LIKE cxct021.*
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_bco		RECORD LIKE gent009.*

LET tot_efe = 0
LET tot_otr = 0
CALL fl_lee_documento_favor_cxc(rm_caja.j10_compania, rm_caja.j10_localidad, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)
	RETURNING r_ica.*
IF r_ica.z21_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe anticipo en cxct021: ' || rm_caja.j10_tipo_destino || ' ' || rm_caja.j10_num_destino, 'stop')
	EXIT PROGRAM
END IF	
CALL fl_lee_area_negocio(rm_caja.j10_compania, r_ica.z21_areaneg)
	RETURNING r_an.* 
CALL fl_lee_auxiliares_caja(rm_caja.j10_compania, rm_caja.j10_localidad,
			    r_an.g03_modulo, r_ica.z21_linea)
	RETURNING rm_auxc.*
IF rm_auxc.b41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares de Caja/Cobranzas.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_codigo_caja_caja(rm_caja.j10_compania, rm_caja.j10_localidad, 
	rm_caja.j10_codigo_caja) RETURNING r_j02.*
IF r_j02.j02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe en cajt002: ' || rm_caja.j10_codigo_caja, 'stop')
	EXIT PROGRAM
END IF
IF r_j02.j02_aux_cont IS NOT NULL THEN
	LET rm_auxc.b41_caja_mb = r_j02.j02_aux_cont
	LET rm_auxc.b41_caja_me = r_j02.j02_aux_cont
END IF
LET glosa = rm_caja.j10_nomcli[1,25], ' ', rm_caja.j10_tipo_destino, ' - ', 
            rm_caja.j10_num_destino USING '<<<<<<'
LET tot_ic = 0
FOREACH q_dic INTO r_dj.*
	LET r_dj.j11_valor = r_dj.j11_valor * r_dj.j11_paridad
	CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, r_dj.j11_valor)
		RETURNING r_dj.j11_valor
	LET tot_ic = tot_ic + r_dj.j11_valor
	CASE r_dj.j11_codigo_pago
		WHEN 'EF'
			LET tot_efe = tot_efe + r_dj.j11_valor 
		WHEN 'CH'
			LET tot_efe = tot_efe + r_dj.j11_valor 
		WHEN 'DP'
			CALL fl_lee_banco_compania(r_dj.j11_compania,
							r_dj.j11_cod_bco_tarj,
							r_dj.j11_num_cta_tarj)
				RETURNING r_bco.*
			IF r_bco.g09_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe banco/cuenta: ' || r_dj.j11_cod_bco_tarj || ' ' || r_dj.j11_num_cta_tarj, 'stop')
				EXIT PROGRAM
			END IF
			LET glosa = glosa CLIPPED, '. CTA. DEP. # ',
						r_dj.j11_num_ch_aut CLIPPED
			CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, r_bco.g09_aux_cont, 
        		'D', r_dj.j11_valor, glosa, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)
		OTHERWISE
			-- LET tot_efe = tot_efe + r_dj.j11_valor
			-- CODIGO FORMA DE PAGO
			LET cont_cred = 'C'
			IF r_dj.j11_tipo_fuente = 'SC' THEN
				LET cont_cred = 'R'
			END IF
			CALL fl_lee_tipo_pago_caja(rm_caja.j10_compania,
							r_dj.j11_codigo_pago,
							cont_cred)
				RETURNING r_j01.*
			IF r_j01.j01_aux_cont IS NOT NULL THEN
				LET glo_aux = glosa
				LET flag    = 0
				IF r_j01.j01_codigo_pago = 'CT' THEN
					LET glosa = 'CT'
					LET flag  = 1
				END IF
				CALL fl_genera_detalle_comprob(vm_tipo_comp,
					subtipo, r_j01.j01_aux_cont, 'D',
					r_dj.j11_valor,glosa,rm_caja.j10_codcli,
					rm_caja.j10_tipo_destino,
					rm_caja.j10_num_destino)
				LET glosa = glo_aux
			ELSE
				CALL fl_mostrar_mensaje('No existe Auxiliar Contable para la Forma de Pago ' || r_dj.j11_codigo_pago || '.', 'stop')
				EXIT PROGRAM
			END IF
			--
	END CASE
END FOREACH
IF rm_caja.j10_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, rm_auxc.b41_caja_mb, 
        'D', tot_efe, glosa, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)
IF flag = 1 THEN
	LET glosa = 'CT.TJ'
END IF
CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, rm_auxc.b41_ant_mb,'H',
	tot_ic, glosa, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)

END FUNCTION



FUNCTION fl_contabiliza_pagos(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE tot_efe		DECIMAL(14,2)
DEFINE tot_ret		DECIMAL(14,2)
DEFINE tot_ic		DECIMAL(14,2)
DEFINE flag		SMALLINT
DEFINE glosa, glo_aux	LIKE ctbt013.b13_glosa
DEFINE aux_ret		LIKE ctbt010.b10_cuenta
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_so		RECORD LIKE cxct024.*
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE r_bco		RECORD LIKE gent009.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_j91		RECORD LIKE cajt091.*
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_z09		RECORD LIKE cxct009.*

LET tot_efe = 0
LET tot_ret = 0
CALL fl_lee_solicitud_cobro_cxc(rm_caja.j10_compania, rm_caja.j10_localidad, rm_caja.j10_num_fuente)
	RETURNING r_so.*
IF r_so.z24_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe I/C en cxct024.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_area_negocio(rm_caja.j10_compania, rm_caja.j10_areaneg)
	RETURNING r_an.* 
CALL fl_lee_auxiliares_caja(rm_caja.j10_compania, rm_caja.j10_localidad,
			    r_an.g03_modulo, r_so.z24_linea)
	RETURNING rm_auxc.*
IF rm_auxc.b41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares de Caja/Cobranzas.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cliente_localidad(rm_caja.j10_compania, rm_caja.j10_localidad, 
	rm_caja.j10_codcli) RETURNING r_z02.*
IF r_z02.z02_aux_clte_mb IS NOT NULL THEN
	LET rm_auxc.b41_cxc_mb = r_z02.z02_aux_clte_mb
END IF
IF r_z02.z02_aux_clte_ma IS NOT NULL THEN
	LET rm_auxc.b41_cxc_me = r_z02.z02_aux_clte_ma
END IF
CALL fl_lee_codigo_caja_caja(rm_caja.j10_compania, rm_caja.j10_localidad, 
	rm_caja.j10_codigo_caja) RETURNING r_j02.*
IF r_j02.j02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe en cajt002: ' || rm_caja.j10_codigo_caja, 'stop')
	EXIT PROGRAM
END IF
IF r_j02.j02_aux_cont IS NOT NULL THEN
	LET rm_auxc.b41_caja_mb = r_j02.j02_aux_cont
	LET rm_auxc.b41_caja_me = r_j02.j02_aux_cont
END IF
LET tot_ic = 0
LET glosa = rm_caja.j10_nomcli[1,25], ' ', rm_caja.j10_tipo_destino, ' - ', 
            rm_caja.j10_num_destino USING '<<<<<<'
FOREACH q_dic INTO r_dj.*
	LET r_dj.j11_valor = r_dj.j11_valor * r_dj.j11_paridad
	CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, r_dj.j11_valor)
		RETURNING r_dj.j11_valor
	LET tot_ic = tot_ic + r_dj.j11_valor
	CASE r_dj.j11_codigo_pago
		WHEN 'EF'
			LET tot_efe = tot_efe + r_dj.j11_valor 
		WHEN 'CH'
			LET tot_efe = tot_efe + r_dj.j11_valor 
		WHEN 'DP'
			CALL fl_lee_banco_compania(r_dj.j11_compania,
							r_dj.j11_cod_bco_tarj,
							r_dj.j11_num_cta_tarj)
				RETURNING r_bco.*
			IF r_bco.g09_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe banco/cuenta: ' || r_dj.j11_cod_bco_tarj || ' ' || r_dj.j11_num_cta_tarj, 'stop')
				EXIT PROGRAM
			END IF
			LET glosa = glosa CLIPPED, '. CTA. DEP. # ',
						r_dj.j11_num_ch_aut CLIPPED
			CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, r_bco.g09_aux_cont, 
        		'D', r_dj.j11_valor, glosa, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)
		{-- FORMA ANTERIOR DE CONTABILIZAR RETENCIONES CREDITO
		WHEN 'RT'
			CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, rm_auxg.b42_reten_cred, 
			--CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, '11300201007',
        		'D', r_dj.j11_valor, glosa, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)
		--}
				
		OTHERWISE
			LET cont_cred = 'C'
			IF r_dj.j11_tipo_fuente = 'SC' THEN
				LET cont_cred = 'R'
			END IF
			IF NOT fl_determinar_si_es_retencion(r_dj.j11_compania,
				r_dj.j11_codigo_pago, cont_cred)
			THEN
			-- CODIGO FORMA DE PAGO
			IF r_dj.j11_codigo_pago = 'EF' THEN
				LET tot_efe = tot_efe + r_dj.j11_valor
			ELSE
				CALL fl_lee_tipo_pago_caja(rm_caja.j10_compania,
					                   r_dj.j11_codigo_pago,
							   cont_cred)
					RETURNING r_j01.*
				IF r_j01.j01_aux_cont IS NOT NULL THEN
					LET glo_aux = glosa
					LET flag    = 0
					IF r_j01.j01_codigo_pago = 'CT' THEN
						LET glosa = 'CT'
						LET flag  = 1
					END IF
					CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, r_j01.j01_aux_cont, 
					
        				'D', r_dj.j11_valor, glosa, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)
					LET glosa = glo_aux
				--ELSE
					--CALL fl_mostrar_mensaje('No existe Auxiliar Contable para la Forma de Pago ' || r_dj.j11_codigo_pago || '.', 'stop')
				END IF
			END IF
			--
			ELSE
				LET tot_ret = tot_ret + r_dj.j11_valor
			END IF
			
	END CASE
END FOREACH
IF rm_caja.j10_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, rm_auxc.b41_caja_mb, 
        'D', tot_efe, glosa, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)
-- FORMA DE CONTABILIZAR RETENCIONES DE CREDITO
IF tot_ret > 0 THEN
	FOREACH q_dic INTO r_dj.*
		IF NOT fl_determinar_si_es_retencion(r_dj.j11_compania,
				r_dj.j11_codigo_pago, 'R')
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
		LET aux_ret = rm_auxg.b42_reten_cred
		FOREACH q_j14 INTO r_j14.*
			CALL fl_lee_det_retencion_cli(r_j14.j14_compania,
							rm_caja.j10_codcli,
							r_j14.j14_tipo_ret,
							r_j14.j14_porc_ret,
							r_j14.j14_codigo_sri,
							r_j14.j14_fec_ini_porc,
							r_dj.j11_codigo_pago,
							'R')
				RETURNING r_z09.*
			IF r_z09.z09_aux_cont IS NOT NULL THEN
				LET aux_ret = r_z09.z09_aux_cont
			ELSE
				CALL fl_lee_det_tipo_ret_caja(
						rm_caja.j10_compania,
						r_dj.j11_codigo_pago, 'R',
						r_j14.j14_tipo_ret,
						r_j14.j14_porc_ret)
					RETURNING r_j91.*
				IF r_j91.j91_aux_cont IS NOT NULL THEN
					LET aux_ret = r_j91.j91_aux_cont
				ELSE
					CALL fl_lee_tipo_pago_caja(
							rm_caja.j10_compania,
							r_dj.j11_codigo_pago,
							'R')
						RETURNING r_j01.*
					IF r_j01.j01_aux_cont IS NOT NULL THEN
						LET aux_ret = r_j01.j01_aux_cont
					END IF
				END IF
			END IF
			CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo,
				aux_ret, 'D', r_j14.j14_valor_ret, glosa,
				rm_caja.j10_codcli, rm_caja.j10_tipo_destino,
				rm_caja.j10_num_destino)
		END FOREACH
	END FOREACH
END IF
--
IF flag = 1 THEN
	LET glosa = 'CT.TJ'
END IF
CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb,'H',
	tot_ic, glosa, rm_caja.j10_codcli, rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)

END FUNCTION



FUNCTION fl_genera_comprobantes_caja()
DEFINE tipo_comp	CHAR(2)
DEFINE num_comp		CHAR(8)
DEFINE subtipo		SMALLINT
DEFINE codcli		INTEGER
DEFINE cod_tran		CHAR(2)
DEFINE num_tran		INTEGER
DEFINE cuenta		CHAR(12)
DEFINE glosa, glo_aux	LIKE ctbt013.b13_glosa
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE indice, i	SMALLINT
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_dcomp		RECORD LIKE ctbt013.*
DEFINE r_z23		RECORD LIKE cxct023.*
        
DECLARE q_mast CURSOR FOR SELECT UNIQUE te_tipo_comp, te_subtipo, te_indice 
	FROM te_master
	ORDER BY 3
FOREACH q_mast INTO tipo_comp, subtipo, indice
	INITIALIZE r_ccomp.* TO NULL
	LET r_ccomp.b12_num_comp = fl_numera_comprobante_contable(rm_caja.j10_compania,
		tipo_comp, YEAR(rm_caja.j10_fecha_pro), MONTH(rm_caja.j10_fecha_pro))
	IF r_ccomp.b12_num_comp = '-1' THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_ccomp.b12_compania 	= rm_caja.j10_compania
    	LET r_ccomp.b12_tipo_comp 	= tipo_comp
    	LET r_ccomp.b12_estado 		= 'A'
    	LET r_ccomp.b12_subtipo 	= subtipo
	IF vm_tipo_doc IS NOT NULL THEN
    		LET r_ccomp.b12_glosa	= 'COMPROBANTE: ',
			rm_caja.j10_tipo_destino, ' ', rm_caja.j10_num_destino 
			USING '<<<<&'
		IF rm_caja.j10_tipo_destino = 'PG' THEN
		     DECLARE q_gva CURSOR FOR SELECT * FROM cxct023
			WHERE z23_compania  = rm_caja.j10_compania  AND 
                      	      z23_localidad = rm_caja.j10_localidad AND 
                              z23_codcli    = rm_caja.j10_codcli    AND 
                              z23_tipo_trn  = rm_caja.j10_tipo_destino  AND 
                              z23_num_trn   = rm_caja.j10_num_destino 
		        ORDER BY z23_orden
    			LET r_ccomp.b12_glosa = 'PAGO: ',
					rm_caja.j10_tipo_destino, '-',
					rm_caja.j10_num_destino USING '<<<<<&',
					' ***'
			LET glo_aux = NULL
			FOREACH q_gva INTO r_z23.*
				LET glo_aux = glo_aux CLIPPED,
			    			' ', 
			    			r_z23.z23_tipo_doc, ' ',
			    			r_z23.z23_num_doc CLIPPED, '-',
			    			r_z23.z23_div_doc USING '&&'
			END FOREACH
			LET r_ccomp.b12_glosa = r_ccomp.b12_glosa CLIPPED, ' ',
						glo_aux CLIPPED
		END IF
    		LET r_ccomp.b12_fec_proceso = rm_caja.j10_fecha_pro
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
	FOREACH q_dmast INTO tipo_comp, num_comp, subtipo, codcli, cod_tran, 
		num_tran, cuenta, glosa, tipo_mov, valor, indice
		LET i = i + 1
    		LET r_dcomp.b13_compania 	= r_ccomp.b12_compania
    		LET r_dcomp.b13_tipo_comp 	= r_ccomp.b12_tipo_comp
    		LET r_dcomp.b13_num_comp 	= r_ccomp.b12_num_comp
    		LET r_dcomp.b13_secuencia 	= i
    		LET r_dcomp.b13_cuenta 		= cuenta
    		LET r_dcomp.b13_glosa 		= glosa
		IF glosa = 'CT' THEN
    			LET r_dcomp.b13_glosa = 'COMI.TAR.CRE', glo_aux CLIPPED
		END IF
		IF glosa = 'CT.TJ' THEN
    			LET r_dcomp.b13_glosa = 'CANCELACION:', glo_aux CLIPPED
		END IF
    		LET r_dcomp.b13_valor_base 	= valor
    		LET r_dcomp.b13_valor_aux 	= 0
    		LET r_dcomp.b13_fec_proceso 	= r_ccomp.b12_fec_proceso
    		LET r_dcomp.b13_num_concil 	= 0
    		LET r_dcomp.b13_codcli   	= rm_caja.j10_codcli
		INSERT INTO ctbt013 VALUES(r_dcomp.*)
	END FOREACH
	UPDATE te_master SET te_num_comp = r_ccomp.b12_num_comp
		WHERE te_tipo_comp = r_ccomp.b12_tipo_comp AND
		      te_subtipo   = r_ccomp.b12_subtipo 
END FOREACH
DECLARE q_crc CURSOR FOR 
	SELECT UNIQUE te_codcli, te_tipo_doc, te_num_doc, te_tipo_comp, te_num_comp 
	FROM te_master
FOREACH q_crc INTO codcli, cod_tran, num_tran, tipo_comp, num_comp
	INSERT INTO cxct040 VALUES (rm_caja.j10_compania, rm_caja.j10_localidad,
	    codcli, cod_tran, num_tran, tipo_comp, num_comp)
END FOREACH

END FUNCTION



FUNCTION fl_chequea_cuadre_db_cr_1()
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE indice		SMALLINT
DEFINE codcli		INTEGER
DEFINE tipo_doc		CHAR(2)
DEFINE num_doc		INTEGER

DECLARE q_sdbcr1 CURSOR FOR SELECT te_tipo_comp, te_subtipo, te_indice, 
	te_codcli, te_tipo_doc, te_num_doc, SUM(te_valor)
	FROM te_master
	GROUP BY 1, 2, 3, 4, 5, 6
	HAVING SUM(te_valor) <> 0
FOREACH q_sdbcr1 INTO tipo_comp, subtipo, indice, codcli, tipo_doc, num_doc, valor
	LET tipo_mov = 'D'
	LET valor = valor * -1
	IF valor < 0 THEN
		LET tipo_mov = 'H'
	END IF	
	INSERT INTO te_master VALUES (tipo_comp, NULL, subtipo, codcli, 
	        tipo_doc, num_doc, rm_auxg.b42_cuadre, '** DESCUADRE **', 
		tipo_mov, valor, indice)
END FOREACH

END FUNCTION



FUNCTION fl_genera_detalle_comprob(tipo_comp, subtipo, cuenta, tipo_mov, 
		valor, glosa, codcli, cod_tran, num_tran)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE tipo_mov		CHAR(1)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE valor		DECIMAL(14,2)
DEFINE codcli		LIKE cajt010.j10_codcli
DEFINE cod_tran		LIKE cxct021.z21_tipo_doc
DEFINE num_tran		LIKE cxct021.z21_num_doc

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
	IF vm_indice = 0 OR vm_indice IS NULL THEN
		LET vm_indice = 1
	END IF
{--
display 'EN EL INSERT ..'
display ' tipo ', tipo_comp, '  subtipo ', subtipo, '  cliente ', codcli, '  ', 
	'cod_tran ', cod_tran, '  num_tran ', num_tran, '  cuenta ', cuenta,
	'  glosa ', glosa, '  tipo_mov ', tipo_mov, '  valor ', valor,
	'  indice ', vm_indice
display ' '
--}
	INSERT INTO te_master VALUES (tipo_comp, NULL, subtipo, codcli, 
	        cod_tran, num_tran, cuenta, glosa, tipo_mov, valor, vm_indice)
ELSE
	UPDATE te_master SET te_valor = te_valor + valor
		WHERE te_tipo_comp = tipo_comp AND 
	              te_subtipo   = subtipo   AND
	              te_cuenta    = cuenta    AND
	              te_glosa     = glosa
END IF

END FUNCTION		

GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"

DEFINE vm_programa      VARCHAR(12)
DEFINE rm_orden		RECORD LIKE talt023.*
DEFINE rm_auxv		RECORD LIKE ctbt043.*
DEFINE rm_auxc		RECORD LIKE ctbt041.*
DEFINE rm_auxg		RECORD LIKE ctbt042.*
DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE rm_t28		RECORD LIKE talt028.*
DEFINE vm_modulo	LIKE gent050.g50_modulo
DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_indice	SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_orden		LIKE talt023.t23_orden
DEFINE vm_flag_fact_dev CHAR(1)
DEFINE vm_fact_anu	SMALLINT

FUNCTION fl_control_master_contab_taller(cod_cia, cod_loc, orden, flag_fact_dev)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE orden		LIKE talt023.t23_orden
DEFINE flag_fact_dev	CHAR(1)
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp

LET vm_flag_fact_dev = flag_fact_dev
LET vm_orden = orden
CALL fl_lee_compania_contabilidad(cod_cia) RETURNING rm_ctb.*	
IF rm_ctb.b00_inte_online = 'N' THEN
	RETURN
END IF
LET vm_modulo    = 'TA'
LET vm_tipo_comp = 'DT'
LET vm_indice    = 1
CALL fl_lee_orden_trabajo(cod_cia, cod_loc, orden)
	RETURNING rm_orden.*
IF rm_orden.t23_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe orden: ' || orden, 'stop')
	RETURN
END IF
IF rm_orden.t23_estado <> 'F' AND rm_orden.t23_estado <> 'D' THEN
	CALL fl_mostrar_mensaje('Orden no está facturada/devuelta', 'stop')
	RETURN
END IF
IF DATE(rm_orden.t23_fec_factura) <= rm_ctb.b00_fecha_cm THEN
	CALL fl_mostrar_mensaje('La fecha de la orden corresponde a un mes contable ya cerrado: ' || orden, 'stop')
--	RETURN
END IF
CREATE TEMP TABLE te_master
	(te_tipo_comp		CHAR(2),
         te_num_comp		CHAR(8),
	 te_subtipo		SMALLINT,
	 te_orden		INTEGER,
	 te_factura		DECIMAL(15,0),
         te_cuenta		CHAR(12),
	 --te_glosa		CHAR(35),
	 te_glosa		CHAR(90),
	 te_tipo_mov		CHAR(1),
	 te_valor		DECIMAL(14,2),
	 te_indice		SMALLINT)
CASE flag_fact_dev
	WHEN 'F'
		CALL fl_contabiliza_venta_taller(41)
		LET vm_indice = vm_indice + 1
		CALL fl_contabiliza_costo_venta_taller(14, 0)
		LET vm_indice = vm_indice + 1
	WHEN 'D'
		LET vm_fact_anu = 0
		CALL fl_contabiliza_dev_venta_taller(10)
		LET vm_indice = vm_indice + 1
		IF vm_fact_anu = 0 THEN
			CALL fl_contabiliza_costo_venta_taller(14, 1)
			LET vm_indice = vm_indice + 1
		END IF
END CASE
CALL fl_chequea_cuadre_db_cr_3()
BEGIN WORK
	CALL fl_genera_comprobantes_taller(flag_fact_dev)
COMMIT WORK
IF rm_ctb.b00_mayo_online = 'N' THEN
	RETURN
END IF
DECLARE q_didi CURSOR WITH HOLD 
	FOR SELECT UNIQUE te_tipo_comp, te_num_comp
	FROM te_master
FOREACH q_didi INTO tipo, num
	CALL fl_mayoriza_comprobante(rm_orden.t23_compania, tipo, num, 'M')
END FOREACH
DROP TABLE te_master

END FUNCTION
	


FUNCTION fl_contabiliza_venta_taller(subtipo)
DEFINE tot_efe		DECIMAL(14,2)
DEFINE tot_tar		DECIMAL(14,2)
DEFINE tot_ret 		DECIMAL(14,2)
DEFINE tot_otros	DECIMAL(14,2)
DEFINE val_iva		DECIMAL(14,2)
DEFINE tot_comp		DECIMAL(14,2)
DEFINE tot_cap		DECIMAL(14,2)
DEFINE tot_int		DECIMAL(14,2)
DEFINE tot_cred		DECIMAL(14,2)
DEFINE dif, dif_abs	DECIMAL(14,2)
DEFINE valor, valor_oc	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE aux_ret		LIKE ctbt010.b10_cuenta
DEFINE r_t25		RECORD LIKE talt025.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z09		RECORD LIKE cxct009.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_cj		RECORD LIKE cajt010.*
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_j91		RECORD LIKE cajt091.*
DEFINE r_tj		RECORD LIKE gent010.*
DEFINE rc		RECORD LIKE ordt010.*
DEFINE rt		RECORD LIKE ordt001.*
DEFINE tipo		CHAR(1)
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE estado		CHAR(1)
DEFINE orden		LIKE talt023.t23_orden

LET tot_efe   = 0
LET tot_tar   = 0
LET tot_otros = 0
LET tot_ret   = 0
SELECT * INTO r_cj.* FROM cajt010
	WHERE j10_compania     = rm_orden.t23_compania  AND 
	      j10_localidad    = rm_orden.t23_localidad AND 
	      j10_tipo_fuente  = 'OT'                   AND 
	      j10_tipo_destino = 'FA'                   AND
	      j10_num_destino  = rm_orden.t23_num_factura
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro de caja de factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_generales(rm_orden.t23_compania, rm_orden.t23_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_tipo_vehiculo(rm_orden.t23_compania, rm_orden.t23_modelo)
	RETURNING r_t04.*
CALL fl_lee_linea_taller(rm_orden.t23_compania, r_t04.t04_linea)
	RETURNING r_t01.*
CALL fl_lee_auxiliares_caja(rm_orden.t23_compania, rm_orden.t23_localidad,
			    vm_modulo, r_t01.t01_grupo_linea)
	RETURNING rm_auxc.*
IF rm_auxc.b41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares de Caja/Cobranzas.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_taller(rm_orden.t23_compania, rm_orden.t23_localidad, 
		r_t01.t01_grupo_linea, rm_orden.t23_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b43_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables taller para grupo línea: ' || r_t01.t01_grupo_linea || ' en factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
CALL fl_retorna_aux_ventas_tal(rm_orden.t23_compania, rm_orden.t23_localidad,
				r_t01.t01_grupo_linea, rm_orden.t23_porc_impto,
				rm_orden.t23_cod_cliente)
	RETURNING rm_auxv.*
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
		LET tot_tar = tot_tar + r_dj.j11_valor 
	END IF
	CASE r_dj.j11_codigo_pago
		WHEN 'EF'
			LET tot_efe = tot_efe + r_dj.j11_valor 
		WHEN 'CH'
			LET tot_efe = tot_efe + r_dj.j11_valor 
		--WHEN 'RT' LET tot_ret = tot_ret + r_dj.j11_valor
		OTHERWISE
			IF r_dj.j11_codigo_pago[1, 1] <> 'T' THEN
			IF NOT fl_determinar_si_es_retencion(r_dj.j11_compania,
				r_dj.j11_codigo_pago, rm_orden.t23_cont_cred)
			THEN
				LET tot_otros = tot_otros + r_dj.j11_valor
			-- CODIGO FORMA DE PAGO
				CALL fl_lee_tipo_pago_caja(r_cj.j10_compania,
							r_dj.j11_codigo_pago,
							rm_orden.t23_cont_cred)
					RETURNING r_j01.*
				IF r_j01.j01_aux_cont IS NOT NULL THEN
				CALL fl_genera_detalle_comp_tal(vm_tipo_comp,
					subtipo, r_j01.j01_aux_cont, 'D',
					r_dj.j11_valor, glosa,
					rm_orden.t23_orden,
					rm_orden.t23_num_factura)
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
CALL fl_lee_cabecera_credito_taller(rm_orden.t23_compania, rm_orden.t23_localidad, 
	rm_orden.t23_orden)
	RETURNING r_t25.*
IF r_t25.t25_valor_ant IS NULL THEN
	LET r_t25.t25_valor_ant = 0
END IF
SELECT SUM(t26_valor_cap), SUM(t26_valor_int) INTO tot_cap, tot_int
	FROM talt026
	WHERE t26_compania  = rm_orden.t23_compania  AND 
	      t26_localidad = rm_orden.t23_localidad AND 
	      t26_orden     = rm_orden.t23_orden
IF tot_cap IS NULL THEN
	LET tot_cap = 0
	LET tot_int = 0
END IF
LET tot_comp = tot_efe + tot_tar + tot_ret + r_t25.t25_valor_ant + tot_cap +
		tot_otros
IF rm_orden.t23_tot_neto <> tot_comp THEN
	CALL fl_mostrar_mensaje('No cuadran valores de factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_orden.t23_nom_cliente[1,25], ' FA-', rm_orden.t23_num_factura 
	USING '<<<<<<<<<<<<<<<'
LET orden = rm_orden.t23_orden
LET estado = rm_orden.t23_estado
WHILE estado = 'D'
	SELECT * INTO rm_t28.* FROM talt028
		WHERE t28_compania  = rm_orden.t23_compania  AND 
                      t28_localidad = rm_orden.t23_localidad AND
                      t28_ot_ant    = orden
	IF status = NOTFOUND THEN
		CALL fl_mostrar_mensaje('Factura está devuelta y no consta en talt028', 'exclamation')
		RETURN
	END IF
	LET orden = rm_t28.t28_ot_nue
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, orden)
		RETURNING r_t23.*
	LET estado = r_t23.t23_estado
END WHILE
DECLARE yi_ec CURSOR FOR SELECT * FROM ordt010
	WHERE c10_compania    = rm_orden.t23_compania  AND
	      c10_localidad   = rm_orden.t23_localidad AND 
	      c10_ord_trabajo = orden
FOREACH yi_ec INTO rc.*
	IF rc.c10_estado <> 'C' OR rc.c10_fecing > rm_orden.t23_fec_factura THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_tipo_orden_compra(rc.c10_tipo_orden) RETURNING rt.*
	DECLARE qu_chichito CURSOR FOR 
	SELECT c11_tipo, (c11_cant_ped * c11_precio) - c11_val_descto
		FROM ordt011
		WHERE c11_compania  = rc.c10_compania  AND 
		      c11_localidad = rc.c10_localidad AND 
		      c11_numero_oc = rc.c10_numero_oc
	LET valor_oc = 0
	FOREACH qu_chichito INTO tipo, valor
		LET valor = valor + (valor * rc.c10_recargo / 100)
		LET valor = fl_retorna_precision_valor(rc.c10_moneda, valor)
		LET valor_oc = valor_oc + valor
	END FOREACH
	--IF rm_orden.t23_porc_impto = 0 THEN
		LET rt.c01_aux_ot_vta = rm_auxv.b43_vta_mo_ext
	--END IF
	CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, 
		rt.c01_aux_ot_vta, 'H', valor_oc, glosa, rm_orden.t23_orden, 
	        rm_orden.t23_num_factura)
END FOREACH

CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_mo_tal, 
	'H', rm_orden.t23_val_mo_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_rp_alm, 
	'H', rm_orden.t23_val_rp_alm, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_otros1, 
	'H', rm_orden.t23_val_otros1, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_otros2, 
	'H', rm_orden.t23_val_otros2, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)

CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_des_mo_tal, 
	'D', rm_orden.t23_vde_mo_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_des_rp_tal, 
	'D', rm_orden.t23_vde_rp_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_des_rp_alm, 
	'D', rm_orden.t23_vde_rp_alm, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)

CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxg.b42_iva_venta, 
	'H', rm_orden.t23_val_impto, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
IF rm_orden.t23_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
LET tot_cred = tot_cap  + tot_int
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxc.b41_caja_mb, 
        'D', tot_efe, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb,
        'D', tot_cred, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxc.b41_ant_mb,
	'D', r_t25.t25_valor_ant, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
{-- FORMA ANTERIOR DE CONTABILIZAR RETENCIONES DE CONTADO
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxg.b42_retencion,
	'D', tot_ret, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
--}
IF tot_ret > 0 THEN
	FOREACH q_dcaj INTO r_dj.*
		IF NOT fl_determinar_si_es_retencion(r_dj.j11_compania,
				r_dj.j11_codigo_pago, rm_orden.t23_cont_cred)
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
							rm_orden.t23_cont_cred)
				RETURNING r_z09.*
			IF r_z09.z09_aux_cont IS NOT NULL THEN
				LET aux_ret = r_z09.z09_aux_cont
			ELSE
				CALL fl_lee_det_tipo_ret_caja(r_cj.j10_compania,
							r_dj.j11_codigo_pago,
							rm_orden.t23_cont_cred,
							r_j14.j14_tipo_ret,
							r_j14.j14_porc_ret)
					RETURNING r_j91.*
				IF r_j91.j91_aux_cont IS NOT NULL THEN
					LET aux_ret = r_j91.j91_aux_cont
				ELSE
					CALL fl_lee_tipo_pago_caja(
							r_cj.j10_compania,
							r_dj.j11_codigo_pago,
							rm_orden.t23_cont_cred)
						RETURNING r_j01.*
					IF r_j01.j01_aux_cont IS NOT NULL THEN
						LET aux_ret = r_j01.j01_aux_cont
					END IF
				END IF
			END IF
			CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo,
				aux_ret, 'D', r_j14.j14_valor_ret, glosa,
				rm_orden.t23_orden, rm_orden.t23_num_factura)
		END FOREACH
	END FOREACH
END IF
IF tot_tar > 0 THEN
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
						rm_orden.t23_cont_cred)
			RETURNING r_tj.*
		IF r_tj.g10_codcobr IS NOT NULL THEN
			CALL fl_lee_cliente_localidad(rm_orden.t23_compania, 
						      rm_orden.t23_localidad,
						      r_tj.g10_codcobr)
				RETURNING r_z02.*
			IF rm_orden.t23_moneda <> rg_gen.g00_moneda_base THEN
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
							rm_orden.t23_cont_cred)
					RETURNING r_j01.*
				LET rm_auxc.b41_cxc_mb = r_j01.j01_aux_cont
			END IF
			IF rm_auxc.b41_cxc_mb IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado auxiliar contable para la Tarjeta de Credito: ' || r_tj.g10_nombre CLIPPED || '. Por favor llame al ADMINISTRADOR.', 'stop')
				EXIT PROGRAM
			END IF
		END IF
		CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo,
				rm_auxc.b41_cxc_mb, 'D', r_dj.j11_valor, glosa,
				rm_orden.t23_orden, rm_orden.t23_num_factura)
	END FOREACH
END IF
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxc.b41_intereses, 
	'H', tot_int, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)

END FUNCTION



FUNCTION fl_contabiliza_costo_venta_taller(subtipo, flag_dev)
DEFINE tot_comp		DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE flag_dev		SMALLINT
DEFINE r_drep		RECORD LIKE rept020.*
DEFINE r_t25		RECORD LIKE talt025.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE rc		RECORD LIKE ordt010.*
DEFINE rt		RECORD LIKE ordt001.*
DEFINE rp		RECORD LIKE cxpt002.*
DEFINE r_t00		RECORD LIKE talt000.*
DEFINE tipo		CHAR(1)
DEFINE valor		DECIMAL(12,2)
DEFINE val_rep, val_mo	DECIMAL(12,2)
DEFINE tot_mo_cti  	DECIMAL(12,2)
DEFINE tot_mo_ext 	DECIMAL(12,2)
DEFINE tot_rp_cti  	DECIMAL(12,2)
DEFINE tot_rp_ext 	DECIMAL(12,2)
DEFINE tot_rp_tal 	DECIMAL(12,2)
DEFINE tot_rp_alm  	DECIMAL(12,2)
DEFINE tot_sumin  	DECIMAL(12,2)
DEFINE val_oc	  	DECIMAL(12,2)
DEFINE tipo_mov_1 	CHAR(1)
DEFINE tipo_mov_2 	CHAR(1)
DEFINE mensaje		VARCHAR(240,0)
DEFINE estado		CHAR(1)
DEFINE cuantos		INTEGER
DEFINE continuar	SMALLINT
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE orden		LIKE talt023.t23_orden

LET orden  = rm_orden.t23_orden
LET estado = rm_orden.t23_estado
WHILE estado = 'D'
	SELECT * INTO rm_t28.* FROM talt028
		WHERE t28_compania  = rm_orden.t23_compania  AND 
                      t28_localidad = rm_orden.t23_localidad AND
                      t28_ot_ant    = orden
	IF status = NOTFOUND THEN
		CALL fl_mostrar_mensaje('Factura está devuelta y no consta en talt028', 'exclamation')
		RETURN
	END IF
	LET orden = rm_t28.t28_ot_nue
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, orden)
		RETURNING r_t23.*
	LET estado = r_t23.t23_estado
END WHILE
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING r_t00.*
CALL fl_lee_auxiliares_generales(rm_orden.t23_compania, rm_orden.t23_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_tipo_vehiculo(rm_orden.t23_compania, rm_orden.t23_modelo)
	RETURNING r_t04.*
CALL fl_lee_linea_taller(rm_orden.t23_compania, r_t04.t04_linea)
	RETURNING r_t01.*
CALL fl_lee_auxiliares_taller(rm_orden.t23_compania, rm_orden.t23_localidad, 
		r_t01.t01_grupo_linea, rm_orden.t23_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b43_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables taller para grupo línea: ' || r_t01.t01_grupo_linea || ' en factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
CALL fl_retorna_aux_ventas_tal(rm_orden.t23_compania, rm_orden.t23_localidad,
				r_t01.t01_grupo_linea, rm_orden.t23_porc_impto,
				rm_orden.t23_cod_cliente)
	RETURNING rm_auxv.*
SELECT COUNT(*) INTO cuantos FROM ordt010
	WHERE c10_compania    = rm_orden.t23_compania
	  AND c10_localidad   = rm_orden.t23_localidad
	  AND c10_ord_trabajo = orden
IF cuantos = 0 THEN
	IF orden = rm_t28.t28_ot_ant THEN
		LET orden = rm_t28.t28_ot_nue
	ELSE
		LET orden = rm_t28.t28_ot_ant
	END IF
END IF
DECLARE cu_peque CURSOR FOR SELECT * FROM ordt010
	WHERE c10_compania    = rm_orden.t23_compania  AND
	      c10_localidad   = rm_orden.t23_localidad AND 
	      c10_ord_trabajo = orden
LET tot_mo_cti = 0
LET tot_mo_ext = 0
LET tot_rp_cti = 0
LET tot_rp_ext = 0
LET tot_rp_tal = 0
LET tot_sumin  = rm_orden.t23_val_otros2
LET glosa = rm_orden.t23_nom_cliente[1,25] CLIPPED, ' FA-',
	rm_orden.t23_num_factura USING '<<<<<<<<<<<<<<<'
LET tipo_mov_1 = 'D'
LET tipo_mov_2 = 'H'
IF flag_dev = 1 THEN
	LET tipo_mov_1 = 'H'
	LET tipo_mov_2 = 'D'
END IF
FOREACH cu_peque INTO rc.*
	IF rc.c10_estado <> 'C' THEN
		IF rc.c10_estado <> 'E' THEN
			CONTINUE FOREACH
		END IF
		IF orden = rm_t28.t28_ot_ant THEN
			DECLARE q_c13_c CURSOR FOR
				SELECT * FROM ordt013
					WHERE c13_compania  = rc.c10_compania
					  AND c13_localidad = rc.c10_localidad
					  AND c13_numero_oc = rc.c10_numero_oc
			LET continuar = 0
			FOREACH q_c13_c INTO r_c13.*
				IF r_c13.c13_fecha_eli < rm_t28.t28_fec_factura
				THEN
					LET continuar = 1
				END IF
			END FOREACH
			IF continuar THEN
				CONTINUE FOREACH
			END IF
		END IF
	END IF
	CALL fl_lee_tipo_orden_compra(rc.c10_tipo_orden) RETURNING rt.*
	IF rt.c01_aux_ot_proc IS NULL THEN
		LET mensaje = 'El tipo de O.C.: ',rc.c10_tipo_orden USING '<<&',
			      ' de la O.C. ', rc.c10_numero_oc USING '<<<<<&', 
			      ' no tiene auxiliar contable para O.T. en ',
			      ' proceso.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	IF rt.c01_aux_ot_cost IS NULL THEN
		LET mensaje = 'El tipo de O.C.: ',rc.c10_tipo_orden USING '<<&',
			      ' de la O.C. ', rc.c10_numero_oc USING '<<<<<&', 
			      ' no tiene auxiliar contable para costo de venta.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	LET val_oc = rc.c10_tot_repto + rc.c10_tot_mano - rc.c10_tot_dscto 
	CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, 
		rt.c01_aux_ot_proc, tipo_mov_2, val_oc, glosa, 
	        rm_orden.t23_orden, rm_orden.t23_num_factura)
	CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, 
		rt.c01_aux_ot_cost, tipo_mov_1, val_oc, glosa, 
	        rm_orden.t23_orden, rm_orden.t23_num_factura)
{
	DECLARE cu_alfa CURSOR FOR 
	SELECT c11_tipo, SUM((c11_cant_ped * c11_precio) - c11_val_descto)
		FROM ordt011
		WHERE c11_compania  = rc.c10_compania  AND 
		      c11_localidad = rc.c10_localidad AND 
		      c11_numero_oc = rc.c10_numero_oc
		GROUP BY 1
	LET val_rep = 0
	LET val_mo  = 0
	FOREACH cu_alfa INTO tipo, valor
		IF tipo = 'B' THEN
			LET val_rep = valor
		ELSE
			LET val_mo  = valor
		END IF
	END FOREACH
	LET val_rep = fl_retorna_precision_valor(rc.c10_moneda, val_rep)
	LET val_mo  = fl_retorna_precision_valor(rc.c10_moneda, val_mo)
	IF rt.c01_bien_serv = 'B' THEN
		LET tot_rp_tal = tot_rp_tal + val_rep
	ELSE	
	--
		--IF rt.c01_bien_serv = 'I' THEN     -- Son Suministros
			--LET tot_sumin = tot_sumin + val_mo + val_rep
		--ELSE
	--
			CALL fl_lee_proveedor_localidad(rc.c10_compania, rc.c10_localidad, rc.c10_codprov)
				RETURNING rp.*
			IF rp.p02_int_ext = 'I' THEN
				LET tot_mo_cti = tot_mo_cti + val_mo
				LET tot_rp_cti = tot_rp_cti + val_rep
			ELSE
				LET tot_mo_ext = tot_mo_ext + val_mo
				LET tot_rp_ext = tot_rp_ext + val_rep
			END IF
		--END IF
	END IF
}
END FOREACH
LET tot_rp_alm = 0
IF r_t00.t00_req_tal = 'S' THEN
	DECLARE cu_memin CURSOR FOR 
		SELECT g21_tipo, SUM(r19_tot_costo)
			FROM rept019, gent021
			WHERE r19_compania    = rm_orden.t23_compania  AND 
	      	              r19_localidad   = rm_orden.t23_localidad AND 
	      	              r19_ord_trabajo = rm_orden.t23_orden     AND 
	      	              g21_cod_tran    = r19_cod_tran
		        GROUP BY 1
	FOREACH cu_memin INTO tipo, valor
		IF tipo <> 'RQ' AND tipo <> 'DR' THEN
			CONTINUE FOREACH
		END IF
		IF tipo = 'I' THEN
			LET valor = valor * -1
		END IF
		LET tot_rp_alm = tot_rp_alm + valor
	END FOREACH
END IF
{
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_mo_ext, 
	tipo_mov_1, tot_mo_ext, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_mo_cti, 
	tipo_mov_1, tot_mo_cti, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_rp_tal, 
	tipo_mov_1, tot_rp_tal, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_rp_ext, 
	tipo_mov_1, tot_rp_ext, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_rp_cti, 
	tipo_mov_1, tot_rp_cti, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
}
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_rp_alm, 
	tipo_mov_1, tot_rp_alm, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_otros1, 
	tipo_mov_1, rm_orden.t23_val_otros1, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_otros2, 
	tipo_mov_1, tot_sumin, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)

{
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_pro_mo_ext, 
	tipo_mov_2, tot_mo_ext, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_pro_mo_cti, 
	tipo_mov_2, tot_mo_cti, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_pro_rp_tal, 
	tipo_mov_2, tot_rp_tal, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_pro_rp_ext, 
	tipo_mov_2, tot_rp_ext, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_pro_rp_cti, 
	tipo_mov_2, tot_rp_cti, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
}
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_pro_rp_alm, 
	tipo_mov_2, tot_rp_alm, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_pro_otros1, 
	tipo_mov_2, rm_orden.t23_val_otros1, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_pro_otros2, 
	tipo_mov_2, tot_sumin, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)

END FUNCTION



FUNCTION fl_contabiliza_dev_venta_taller(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_fact		RECORD LIKE rept019.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE rot		RECORD LIKE talt023.*
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE saldo_fact	DECIMAL(14,2)
DEFINE val_anticipo	DECIMAL(14,2)
DEFINE val_cobranzas	DECIMAL(14,2)
DEFINE valor, valor_oc	DECIMAL(14,2)
DEFINE rc		RECORD LIKE ordt010.*
DEFINE rt		RECORD LIKE ordt001.*
DEFINE tipo		CHAR(1)
DEFINE estado		CHAR(1)
DEFINE cuantos		INTEGER
DEFINE continuar	SMALLINT
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE orden		LIKE talt023.t23_orden

LET orden  = rm_orden.t23_orden
LET estado = rm_orden.t23_estado
WHILE estado = 'D'
	SELECT * INTO rm_t28.* FROM talt028
		WHERE t28_compania  = rm_orden.t23_compania  AND 
                      t28_localidad = rm_orden.t23_localidad AND
                      t28_ot_ant    = orden
	IF status = NOTFOUND THEN
		CALL fl_mostrar_mensaje('Factura está devuelta y no consta en talt028', 'exclamation')
		RETURN
	END IF
	IF DATE(rm_t28.t28_fec_anula) = DATE(rm_t28.t28_fec_factura) THEN
		LET vm_fact_anu = 1
		CALL fl_contab_anulacion_fact_taller()
		RETURN
	END IF
	LET orden = rm_t28.t28_ot_nue
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, orden)
		RETURNING r_t23.*
	LET estado = r_t23.t23_estado
END WHILE
CALL fl_lee_auxiliares_generales(rm_orden.t23_compania, rm_orden.t23_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_tipo_vehiculo(rm_orden.t23_compania, rm_orden.t23_modelo)
	RETURNING r_t04.*
CALL fl_lee_linea_taller(rm_orden.t23_compania, r_t04.t04_linea)
	RETURNING r_t01.*
CALL fl_lee_auxiliares_caja(rm_orden.t23_compania, rm_orden.t23_localidad,
			    vm_modulo, r_t01.t01_grupo_linea)
	RETURNING rm_auxc.*
IF rm_auxc.b41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares de Caja/Cobranzas.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_taller(rm_orden.t23_compania, rm_orden.t23_localidad, 
		r_t01.t01_grupo_linea, rm_orden.t23_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b43_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables taller para grupo línea: ' || r_t01.t01_grupo_linea || ' en factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
CALL fl_retorna_aux_ventas_tal(rm_orden.t23_compania, rm_orden.t23_localidad,
				r_t01.t01_grupo_linea, rm_orden.t23_porc_impto,
				rm_orden.t23_cod_cliente)
	RETURNING rm_auxv.*
LET glosa = rm_orden.t23_nom_cliente[1,25] CLIPPED, ' FA-',
	rm_orden.t23_num_factura USING '<<<<<<<<<<<<<<<'
SELECT COUNT(*) INTO cuantos FROM ordt010
	WHERE c10_compania    = rm_orden.t23_compania
	  AND c10_localidad   = rm_orden.t23_localidad
	  AND c10_ord_trabajo = orden
IF cuantos = 0 THEN
	IF orden = rm_t28.t28_ot_ant THEN
		LET orden = rm_t28.t28_ot_nue
	ELSE
		LET orden = rm_t28.t28_ot_ant
	END IF
END IF
DECLARE yiec CURSOR FOR SELECT * FROM ordt010
	WHERE c10_compania    = rm_orden.t23_compania  AND
	      c10_localidad   = rm_orden.t23_localidad AND 
	      c10_ord_trabajo = orden
FOREACH yiec INTO rc.*
	IF rc.c10_estado <> 'C' THEN
		IF rc.c10_estado <> 'E' THEN
			CONTINUE FOREACH
		END IF
		IF orden = rm_t28.t28_ot_ant THEN
			DECLARE q_c13 CURSOR FOR
				SELECT * FROM ordt013
					WHERE c13_compania  = rc.c10_compania
					  AND c13_localidad = rc.c10_localidad
					  AND c13_numero_oc = rc.c10_numero_oc
			LET continuar = 0
			FOREACH q_c13 INTO r_c13.*
				IF r_c13.c13_fecha_eli < rm_t28.t28_fec_factura
				THEN
					LET continuar = 1
				END IF
			END FOREACH
			IF continuar THEN
				CONTINUE FOREACH
			END IF
		END IF
	END IF
	CALL fl_lee_tipo_orden_compra(rc.c10_tipo_orden) RETURNING rt.*
	DECLARE qu_chicle CURSOR FOR 
		SELECT c11_tipo, (c11_cant_ped * c11_precio) - c11_val_descto
		FROM ordt011
		WHERE c11_compania  = rc.c10_compania  AND 
		      c11_localidad = rc.c10_localidad AND 
		      c11_numero_oc = rc.c10_numero_oc
	LET valor_oc = 0
	FOREACH qu_chicle INTO tipo, valor
		LET valor = valor + (valor * rc.c10_recargo / 100)
		LET valor = fl_retorna_precision_valor(rc.c10_moneda, valor)
		LET valor_oc = valor_oc + valor
	END FOREACH
	LET rt.c01_aux_ot_dvta = rm_auxv.b43_dvt_mo_ext
	CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, 
		rt.c01_aux_ot_dvta, 'D', valor_oc, glosa, rm_orden.t23_orden, 
		rm_orden.t23_num_factura)
END FOREACH

CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_mo_tal, 
	'D', rm_orden.t23_val_mo_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_rp_alm, 
	'D', rm_orden.t23_val_rp_alm, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_otros1, 
	'D', rm_orden.t23_val_otros1, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_otros2, 
	'D', rm_orden.t23_val_otros2, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)

CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_des_mo_tal, 
	'H', rm_orden.t23_vde_mo_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_des_rp_tal, 
	'H', rm_orden.t23_vde_rp_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_des_rp_alm, 
	'H', rm_orden.t23_vde_rp_alm, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)

CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxg.b42_iva_venta, 
	'D', rm_orden.t23_val_impto, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
IF rm_orden.t23_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
IF rm_orden.t23_cont_cred = 'C' THEN
	CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, 
		rm_auxc.b41_ant_mb, 'H', rm_orden.t23_tot_neto, glosa, 
		rm_orden.t23_orden, rm_orden.t23_num_factura)
	RETURN
END IF
CALL chequea_saldo_fact_devuelta_taller() RETURNING saldo_fact
LET val_anticipo = 0
IF rm_orden.t23_tot_neto <= saldo_fact THEN
	LET val_cobranzas = rm_orden.t23_tot_neto
	LET val_anticipo  = 0
ELSE
	LET val_anticipo  = rm_orden.t23_tot_neto - saldo_fact
	LET val_cobranzas = saldo_fact
END IF
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxc.b41_ant_mb, 
        'H', val_anticipo, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb,
        'H', val_cobranzas, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)

END FUNCTION



FUNCTION fl_contab_anulacion_fact_taller()
DEFINE r_t50		RECORD LIKE talt050.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE i		SMALLINT

DEFINE fecha_actual DATETIME YEAR TO SECOND

DECLARE cu_chipi CURSOR WITH HOLD FOR 
	SELECT * FROM talt050
		WHERE t50_compania  = rm_orden.t23_compania  AND 
	              t50_localidad = rm_orden.t23_localidad AND 
	              t50_orden     = rm_orden.t23_orden
	        ORDER BY t50_num_comp DESC
LET i = 0
FOREACH cu_chipi INTO r_t50.*
	LET i = i + 1
	CALL fl_lee_comprobante_contable(rm_orden.t23_compania, 
			r_t50.t50_tipo_comp, r_t50.t50_num_comp)
		RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe en ctbt012 comprobante de la talt050.', 'STOP')
		EXIT PROGRAM
	END IF
	CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'D')
	CALL fl_lee_comprobante_contable(rm_orden.t23_compania, 
			r_t50.t50_tipo_comp, r_t50.t50_num_comp)
		RETURNING r_b12.*
	SET LOCK MODE TO WAIT 5
	LET fecha_actual = fl_current()
	UPDATE ctbt012 SET b12_estado     = 'E',
			   b12_fec_modifi = fecha_actual 
		WHERE b12_compania  = r_b12.b12_compania  AND 
		      b12_tipo_comp = r_b12.b12_tipo_comp AND 
		      b12_num_comp  = r_b12.b12_num_comp
	IF i = 2 THEN
		EXIT FOREACH
	END IF
END FOREACH	

END FUNCTION	



FUNCTION fl_genera_comprobantes_taller(flag_fact_dev)
DEFINE flag_fact_dev	CHAR(1)
DEFINE tipo_comp	CHAR(2)
DEFINE num_comp		CHAR(8)
DEFINE subtipo		SMALLINT
DEFINE orden		LIKE talt023.t23_orden
DEFINE factura		LIKE talt023.t23_num_factura
DEFINE num_tran		DECIMAL(15,0)
DEFINE cuenta		CHAR(12)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE indice, i	SMALLINT
DEFINE anio, mes	SMALLINT
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_dcomp		RECORD LIKE ctbt013.*
DEFINE nom_cta		LIKE ctbt010.b10_descripcion
DEFINE est_cta		LIKE ctbt010.b10_estado
DEFINE mensaje		VARCHAR(200)
        
DECLARE q_roco CURSOR FOR SELECT UNIQUE te_tipo_comp, te_subtipo, te_indice 
	FROM te_master
	ORDER BY 3
FOREACH q_roco INTO tipo_comp, subtipo, indice
	INITIALIZE r_ccomp.* TO NULL
	CASE flag_fact_dev
		WHEN 'F'
			LET anio = YEAR(rm_orden.t23_fec_factura)
			LET mes  = MONTH(rm_orden.t23_fec_factura)
		WHEN 'D'
			LET anio = YEAR(rm_t28.t28_fec_anula)
			LET mes  = MONTH(rm_t28.t28_fec_anula)
	END CASE
	LET r_ccomp.b12_num_comp = fl_numera_comprobante_contable(
					rm_orden.t23_compania, tipo_comp,
					anio, mes)
	IF r_ccomp.b12_num_comp = '-1' THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_ccomp.b12_compania 	= rm_orden.t23_compania
    	LET r_ccomp.b12_tipo_comp 	= tipo_comp
    	LET r_ccomp.b12_estado 		= 'A'
    	LET r_ccomp.b12_subtipo 	= subtipo
	IF vm_orden IS NOT NULL THEN
    		LET r_ccomp.b12_fec_proceso = rm_orden.t23_fec_factura
    		LET r_ccomp.b12_glosa	= 'COMPROBANTE: FA ',
			rm_orden.t23_num_factura 
			USING '<<<<<<<<<<<<<<<'
		IF vm_flag_fact_dev = 'D' THEN
    			LET r_ccomp.b12_glosa	= r_ccomp.b12_glosa CLIPPED,
				'  (DEVOLUCION)'
    			LET r_ccomp.b12_fec_proceso = DATE(rm_t28.t28_fec_anula)
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
	DECLARE q_chicha CURSOR FOR SELECT * FROM te_master
		WHERE te_tipo_comp = tipo_comp AND 
		      te_subtipo   = subtipo
		ORDER BY te_tipo_mov, te_cuenta
	INITIALIZE r_dcomp.* TO NULL
	LET i = 0
	FOREACH q_chicha INTO tipo_comp, num_comp, subtipo, orden, factura, 
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
    		LET r_dcomp.b13_num_concil  	= 0
		LET r_dcomp.b13_codcli          = rm_orden.t23_cod_cliente
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
DECLARE q_pica CURSOR FOR 
	SELECT UNIQUE te_orden, te_factura, te_tipo_comp, te_num_comp 
	FROM te_master
FOREACH q_pica INTO orden, factura, tipo_comp, num_comp
	INSERT INTO talt050 VALUES (rm_orden.t23_compania, rm_orden.t23_localidad,
	    orden, factura, tipo_comp, num_comp)
END FOREACH

END FUNCTION



FUNCTION fl_chequea_cuadre_db_cr_3()
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE orden		LIKE talt023.t23_orden
DEFINE num_fact		LIKE talt023.t23_num_factura
DEFINE indice		SMALLINT

DECLARE q_sdbcr3 CURSOR FOR SELECT te_tipo_comp, te_subtipo, te_indice, 
	te_orden, te_factura, SUM(te_valor)
	FROM te_master
	GROUP BY 1, 2, 3, 4, 5
	HAVING SUM(te_valor) <> 0
FOREACH q_sdbcr3 INTO tipo_comp, subtipo, indice, orden, num_fact, valor
	LET tipo_mov = 'D'
	LET valor = valor * -1
	IF valor < 0 THEN
		LET tipo_mov = 'H'
	END IF	
	INSERT INTO te_master VALUES (tipo_comp, '', subtipo, orden,
		num_fact, rm_auxg.b42_cuadre, '** DESCUADRE **', tipo_mov, 
		valor, indice)
END FOREACH

END FUNCTION



FUNCTION fl_genera_detalle_comp_tal(tipo_comp, subtipo, cuenta, tipo_mov, 
		valor, glosa, orden, factura)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE tipo_mov		CHAR(1)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE valor		DECIMAL(14,2)
DEFINE orden		LIKE talt023.t23_orden
DEFINE factura		LIKE talt023.t23_num_factura

IF valor = 0 THEN
	RETURN
END IF
IF cuenta IS NULL THEN
	CALL fl_mostrar_mensaje('Cuenta nula. Revisar taller.', 'stop')
	EXIT PROGRAM
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
	INSERT INTO te_master VALUES (tipo_comp, NULL, subtipo, orden,
		factura, cuenta, glosa, tipo_mov, valor, vm_indice)
ELSE
	UPDATE te_master SET te_valor = te_valor + valor
		WHERE te_tipo_comp = tipo_comp AND 
	              te_subtipo   = subtipo   AND
	              te_cuenta    = cuenta    AND
	              te_glosa     = glosa
END IF

END FUNCTION		



FUNCTION fl_lee_auxiliares_taller(cod_cia, cod_loc, grupo_linea, porc_impto)
DEFINE cod_cia		LIKE ctbt043.b43_compania
DEFINE cod_loc		LIKE ctbt043.b43_localidad
DEFINE grupo_linea	LIKE ctbt043.b43_grupo_linea
DEFINE porc_impto	LIKE ctbt043.b43_porc_impto
DEFINE r		RECORD LIKE ctbt043.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt043
	WHERE b43_compania    = cod_cia
	  AND b43_localidad   = cod_loc
	  AND b43_grupo_linea = grupo_linea
	  AND b43_porc_impto  = porc_impto
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_aux_ventas_tal(cod_cia, cod_loc, grupo_linea, porc_impto,
					codcli)
DEFINE cod_cia		LIKE ctbt043.b43_compania
DEFINE cod_loc		LIKE ctbt043.b43_localidad
DEFINE grupo_linea	LIKE ctbt043.b43_grupo_linea
DEFINE porc_impto	LIKE ctbt043.b43_porc_impto
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE r_b43		RECORD LIKE ctbt043.*
DEFINE r_b45		RECORD LIKE ctbt045.*
DEFINE r_z01		RECORD LIKE cxct001.*

LET r_b43.* = rm_auxv.*
CALL fl_lee_cliente_general(codcli) RETURNING r_z01.*
CALL fl_lee_aux_taller_tipo(cod_cia, cod_loc, grupo_linea, porc_impto,
				r_z01.z01_tipo_clte)
	RETURNING r_b45.*
IF r_b45.b45_compania IS NULL THEN
	RETURN r_b43.*
END IF
LET r_b43.b43_vta_mo_tal = r_b45.b45_vta_mo_tal
LET r_b43.b43_vta_mo_ext = r_b45.b45_vta_mo_ext
LET r_b43.b43_vta_mo_cti = r_b45.b45_vta_mo_cti
LET r_b43.b43_vta_rp_tal = r_b45.b45_vta_rp_tal
LET r_b43.b43_vta_rp_ext = r_b45.b45_vta_rp_ext
LET r_b43.b43_vta_rp_cti = r_b45.b45_vta_rp_cti
LET r_b43.b43_vta_rp_alm = r_b45.b45_vta_rp_alm
LET r_b43.b43_vta_otros1 = r_b45.b45_vta_otros1
LET r_b43.b43_vta_otros2 = r_b45.b45_vta_otros2
LET r_b43.b43_dvt_mo_tal = r_b45.b45_dvt_mo_tal
LET r_b43.b43_dvt_mo_ext = r_b45.b45_dvt_mo_ext
LET r_b43.b43_dvt_mo_cti = r_b45.b45_dvt_mo_cti
LET r_b43.b43_dvt_rp_tal = r_b45.b45_dvt_rp_tal
LET r_b43.b43_dvt_rp_ext = r_b45.b45_dvt_rp_ext
LET r_b43.b43_dvt_rp_cti = r_b45.b45_dvt_rp_cti
LET r_b43.b43_dvt_rp_alm = r_b45.b45_dvt_rp_alm
LET r_b43.b43_dvt_otros1 = r_b45.b45_dvt_otros1
LET r_b43.b43_dvt_otros2 = r_b45.b45_dvt_otros2
LET r_b43.b43_cos_mo_tal = r_b45.b45_cos_mo_tal
LET r_b43.b43_cos_mo_ext = r_b45.b45_cos_mo_ext
LET r_b43.b43_cos_mo_cti = r_b45.b45_cos_mo_cti
LET r_b43.b43_cos_rp_tal = r_b45.b45_cos_rp_tal
LET r_b43.b43_cos_rp_ext = r_b45.b45_cos_rp_ext
LET r_b43.b43_cos_rp_cti = r_b45.b45_cos_rp_cti
LET r_b43.b43_cos_rp_alm = r_b45.b45_cos_rp_alm
LET r_b43.b43_cos_otros1 = r_b45.b45_cos_otros1
LET r_b43.b43_cos_otros2 = r_b45.b45_cos_otros2
LET r_b43.b43_pro_mo_tal = r_b45.b45_pro_mo_tal
LET r_b43.b43_pro_mo_ext = r_b45.b45_pro_mo_ext
LET r_b43.b43_pro_mo_cti = r_b45.b45_pro_mo_cti
LET r_b43.b43_pro_rp_tal = r_b45.b45_pro_rp_tal
LET r_b43.b43_pro_rp_ext = r_b45.b45_pro_rp_ext
LET r_b43.b43_pro_rp_cti = r_b45.b45_pro_rp_cti
LET r_b43.b43_pro_rp_alm = r_b45.b45_pro_rp_alm
LET r_b43.b43_pro_otros1 = r_b45.b45_pro_otros1
LET r_b43.b43_pro_otros2 = r_b45.b45_pro_otros2
LET r_b43.b43_des_mo_tal = r_b45.b45_des_mo_tal
LET r_b43.b43_des_rp_tal = r_b45.b45_des_rp_tal
LET r_b43.b43_des_rp_alm = r_b45.b45_des_rp_alm
RETURN r_b43.*

END FUNCTION



FUNCTION fl_lee_aux_taller_tipo(cod_cia, cod_loc, grupo_linea, porc_impto,
				tipo_cli)
DEFINE cod_cia		LIKE ctbt045.b45_compania
DEFINE cod_loc		LIKE ctbt045.b45_localidad
DEFINE grupo_linea	LIKE ctbt045.b45_grupo_linea
DEFINE porc_impto	LIKE ctbt045.b45_porc_impto
DEFINE tipo_cli		LIKE ctbt045.b45_tipo_cli
DEFINE r		RECORD LIKE ctbt045.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt045
	WHERE b45_compania    = cod_cia
	  AND b45_localidad   = cod_loc
	  AND b45_grupo_linea = grupo_linea
	  AND b45_porc_impto  = porc_impto
	  AND b45_tipo_cli    = tipo_cli
RETURN r.*

END FUNCTION



FUNCTION chequea_saldo_fact_devuelta_taller()
DEFINE r_r25		RECORD LIKE rept025.*
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE saldo_fact	DECIMAL(14,2)
DEFINE tot_pag		DECIMAL(14,2)
DEFINE fec_dev		LIKE rept019.r19_fecing
DEFINE num_doc		LIKE cxct020.z20_num_doc

SELECT SUM(z20_valor_cap) INTO saldo_fact FROM cxct020
	WHERE z20_compania  = rm_t28.t28_compania  AND 
	      z20_localidad = rm_t28.t28_localidad AND 
	      z20_cod_tran  = 'FA'              AND 
	      z20_num_tran  = rm_t28.t28_factura   AND 
	      z20_codcli    = rm_orden.t23_cod_cliente AND
	      z20_dividendo <> 0
IF saldo_fact IS NULL THEN
	CALL fl_mostrar_mensaje('Factura crédito no existe en  ' || 
					 'módulo de Cobranzas.', 'stop')
	ROLLBACK WORK
	EXIT PROGRAM
END IF	
LET num_doc = rm_t28.t28_factura
DECLARE q_alvarito CURSOR FOR SELECT * FROM cxct023
	WHERE z23_compania  = rm_t28.t28_compania  AND 
	      z23_localidad = rm_t28.t28_localidad AND 
	      z23_codcli    = rm_orden.t23_cod_cliente AND 
	      z23_tipo_doc  = 'FA'              AND
	      z23_num_doc   = num_doc           AND 
	      z23_div_doc   > 0
LET tot_pag = 0
FOREACH q_alvarito INTO r_z23.*
	CALL fl_lee_transaccion_cxc(r_z23.z23_compania, r_z23.z23_localidad, 
		r_z23.z23_codcli, r_z23.z23_tipo_trn, r_z23.z23_num_trn)
		RETURNING r_z22.*
	IF r_z22.z22_fecing > rm_t28.t28_fec_anula THEN
		CONTINUE FOREACH
	END IF
	IF r_z23.z23_tipo_trn = 'AJ' AND r_z22.z22_origen = 'A' AND
		DATE(r_z22.z22_fecing) = DATE(rm_t28.t28_fec_anula) THEN
		CONTINUE FOREACH
	END IF
	LET tot_pag = tot_pag + r_z23.z23_valor_cap
END FOREACH 
LET saldo_fact = saldo_fact + tot_pag	
RETURN saldo_fact

END FUNCTION

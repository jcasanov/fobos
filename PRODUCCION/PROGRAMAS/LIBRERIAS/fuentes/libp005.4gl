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
	RETURN
END IF
CREATE TEMP TABLE te_master
	(te_tipo_comp		CHAR(2),
         te_num_comp		CHAR(8),
	 te_subtipo		SMALLINT,
	 te_orden		INTEGER,
	 te_factura		DECIMAL(15,0),
         te_cuenta		CHAR(12),
	 te_glosa		CHAR(35),
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
CALL fl_genera_comprobantes_taller()
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
DEFINE tot_otr		DECIMAL(14,2)
DEFINE val_iva		DECIMAL(14,2)
DEFINE tot_comp		DECIMAL(14,2)
DEFINE tot_cap		DECIMAL(14,2)
DEFINE tot_int		DECIMAL(14,2)
DEFINE tot_cred		DECIMAL(14,2)
DEFINE dif, dif_abs	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_t25		RECORD LIKE talt025.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_cj		RECORD LIKE cajt010.*
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE r_tj		RECORD LIKE gent010.*

LET tot_efe = 0
LET tot_tar = 0
LET tot_otr = 0
LET tot_ret = 0
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
	r_t01.t01_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b43_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables taller para grupo línea: ' || r_t01.t01_grupo_linea || ' en factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
DECLARE q_oblina CURSOR FOR SELECT * FROM cajt011
	WHERE j11_compania     = r_cj.j10_compania    AND 
	      j11_localidad    = r_cj.j10_localidad   AND 
	      j11_tipo_fuente  = r_cj.j10_tipo_fuente AND
	      j11_num_fuente   = r_cj.j10_num_fuente
FOREACH q_oblina INTO r_dj.*
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
		WHEN 'RT'
			LET tot_ret = tot_ret + r_dj.j11_valor
		OTHERWISE
			LET tot_efe = tot_efe + r_dj.j11_valor
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
LET tot_comp = tot_efe + tot_tar + tot_ret + r_t25.t25_valor_ant + tot_cap
IF rm_orden.t23_tot_neto <> tot_comp THEN
	CALL fl_mostrar_mensaje('No cuadran valores de factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_orden.t23_nom_cliente[1,25], ' FA-', rm_orden.t23_num_factura 
	USING '<<<<<<<<<<<<<<<'
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_mo_tal, 
	'H', rm_orden.t23_val_mo_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_mo_ext, 
	'H', rm_orden.t23_val_mo_ext, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_mo_cti, 
	'H', rm_orden.t23_val_mo_cti, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_rp_tal, 
	'H', rm_orden.t23_val_rp_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_rp_ext, 
	'H', rm_orden.t23_val_rp_ext, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_vta_rp_cti, 
	'H', rm_orden.t23_val_rp_cti, glosa, rm_orden.t23_orden, 
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
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxg.b42_retencion,
	'D', tot_ret, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
IF tot_tar > 0 THEN
	CALL fl_lee_tarjeta_credito(r_dj.j11_cod_bco_tarj) RETURNING r_tj.*
	IF r_tj.g10_codcobr IS NOT NULL THEN
		CALL fl_lee_cliente_localidad(rm_orden.t23_compania, 
					      rm_orden.t23_localidad,
					      r_tj.g10_codcobr)
			RETURNING r_z02.*
		IF rm_orden.t23_moneda <> rg_gen.g00_moneda_base THEN
			IF r_z02.z02_aux_clte_ma IS NOT NULL THEN
				LET r_z02.z02_aux_clte_mb = r_z02.z02_aux_clte_ma
			END IF
		END IF
		IF r_z02.z02_aux_clte_mb IS NOT NULL THEN
			LET rm_auxc.b41_cxc_mb = r_z02.z02_aux_clte_mb
		END IF
	END IF
	CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb, 'D',
		tot_tar, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
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
DEFINE tipo_mov_1 	CHAR(1)
DEFINE tipo_mov_2 	CHAR(1)

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
	r_t01.t01_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b43_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables taller para grupo línea: ' || r_t01.t01_grupo_linea || ' en factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
DECLARE cu_peque CURSOR FOR SELECT * FROM ordt010
	WHERE c10_compania    = rm_orden.t23_compania  AND
	      c10_localidad   = rm_orden.t23_localidad AND 
	      c10_ord_trabajo = rm_orden.t23_orden
LET tot_mo_cti = 0
LET tot_mo_ext = 0
LET tot_rp_cti = 0
LET tot_rp_ext = 0
LET tot_rp_tal = 0
LET tot_sumin  = rm_orden.t23_val_otros2
FOREACH cu_peque INTO rc.*
	IF rc.c10_estado <> 'C' THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_tipo_orden_compra(rc.c10_tipo_orden) RETURNING rt.*
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
	{
		IF rt.c01_bien_serv = 'I' THEN     -- Son Suministros
			LET tot_sumin = tot_sumin + val_mo + val_rep
		ELSE
	}
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
END FOREACH
LET tot_rp_alm = 0
DECLARE cu_memin CURSOR FOR 
	SELECT g21_tipo, SUM(r19_tot_costo)
	FROM rept019, gent021
	WHERE r19_compania    = rm_orden.t23_compania  AND 
	      r19_localidad   = rm_orden.t23_localidad AND 
	      r19_ord_trabajo = rm_orden.t23_orden     AND 
	      g21_cod_tran    = r19_cod_tran
	GROUP BY 1
FOREACH cu_memin INTO tipo, valor
	IF tipo = 'I' THEN
		LET valor = valor * -1
	END IF
	LET tot_rp_alm = tot_rp_alm + valor
END FOREACH
LET glosa = rm_orden.t23_nom_cliente[1,25], ' FA-', rm_orden.t23_num_factura 
	USING '<<<<<<<<<<<<<<<'
LET tipo_mov_1 = 'D'
LET tipo_mov_2 = 'H'
IF flag_dev = 1 THEN
	LET tipo_mov_1 = 'H'
	LET tipo_mov_2 = 'D'
END IF
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
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_rp_alm, 
	tipo_mov_1, tot_rp_alm, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_otros1, 
	tipo_mov_1, rm_orden.t23_val_otros1, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_cos_otros2, 
	tipo_mov_1, tot_sumin, glosa, rm_orden.t23_orden, rm_orden.t23_num_factura)

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

SELECT * INTO rm_t28.* FROM talt028
	WHERE t28_compania  = rm_orden.t23_compania  AND 
              t28_localidad = rm_orden.t23_localidad AND
              t28_ot_ant    = rm_orden.t23_orden
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Factura está devuelta y no consta en talt028', 'exclamation')
	RETURN
END IF
IF DATE(rm_t28.t28_fec_anula) = DATE(rm_t28.t28_fec_factura) THEN
	LET vm_fact_anu = 1
	CALL fl_contab_anulacion_fact_taller()
	RETURN
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
	r_t01.t01_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b43_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables taller para grupo línea: ' || r_t01.t01_grupo_linea || ' en factura: ' || rm_orden.t23_num_factura, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_orden.t23_nom_cliente[1,25], ' FA-', rm_orden.t23_num_factura 
	USING '<<<<<<<<<<<<<<<'
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_mo_tal, 
	'D', rm_orden.t23_val_mo_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_mo_ext, 
	'D', rm_orden.t23_val_mo_ext, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_mo_cti, 
	'D', rm_orden.t23_val_mo_cti, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_rp_tal, 
	'D', rm_orden.t23_val_rp_tal, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_rp_ext, 
	'D', rm_orden.t23_val_rp_ext, glosa, rm_orden.t23_orden, 
	rm_orden.t23_num_factura)
CALL fl_genera_detalle_comp_tal(vm_tipo_comp, subtipo, rm_auxv.b43_dvt_rp_cti, 
	'D', rm_orden.t23_val_rp_cti, glosa, rm_orden.t23_orden, 
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
	UPDATE ctbt012 SET b12_estado     = 'E',
			   b12_fec_modifi = CURRENT 
		WHERE b12_compania  = r_b12.b12_compania  AND 
		      b12_tipo_comp = r_b12.b12_tipo_comp AND 
		      b12_num_comp  = r_b12.b12_num_comp
	IF i = 2 THEN
		EXIT FOREACH
	END IF
END FOREACH	

END FUNCTION	



FUNCTION fl_genera_comprobantes_taller()
DEFINE tipo_comp	CHAR(2)
DEFINE num_comp		CHAR(8)
DEFINE subtipo		SMALLINT
DEFINE orden		LIKE talt023.t23_orden
DEFINE factura		LIKE talt023.t23_num_factura
DEFINE num_tran		DECIMAL(15,0)
DEFINE cuenta		CHAR(12)
DEFINE glosa		CHAR(35)
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE indice, i	SMALLINT
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_dcomp		RECORD LIKE ctbt013.*
        
DECLARE q_roco CURSOR FOR SELECT UNIQUE te_tipo_comp, te_subtipo, te_indice 
	FROM te_master
	ORDER BY 3
FOREACH q_roco INTO tipo_comp, subtipo, indice
	INITIALIZE r_ccomp.* TO NULL
	LET r_ccomp.b12_num_comp = fl_numera_comprobante_contable(rm_orden.t23_compania,
		tipo_comp, YEAR(rm_orden.t23_fec_factura), MONTH(rm_orden.t23_fec_factura))
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
    	LET r_ccomp.b12_fecing 		= CURRENT
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
	INSERT INTO te_master VALUES (tipo_comp, NULL, subtipo, orden,
		factura, rm_auxg.b42_cuadre, '** DESCUADRE **', tipo_mov, 
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



FUNCTION fl_lee_auxiliares_taller(cod_cia, cod_loc, grupo_linea)
DEFINE cod_cia		LIKE ctbt043.b43_compania
DEFINE cod_loc		LIKE ctbt043.b43_localidad
DEFINE grupo_linea	LIKE ctbt043.b43_grupo_linea
DEFINE r		RECORD LIKE ctbt043.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt043
	WHERE b43_compania    = cod_cia AND 
	      b43_localidad   = cod_loc AND
	      b43_grupo_linea = grupo_linea
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

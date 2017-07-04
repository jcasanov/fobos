GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"

DEFINE vm_programa      VARCHAR(12)
DEFINE rm_cveh		RECORD LIKE veht030.*
DEFINE rm_auxv		RECORD LIKE ctbt040.*
DEFINE rm_caja		RECORD LIKE cajt010.*
DEFINE rm_auxc		RECORD LIKE ctbt041.*
DEFINE rm_auxg		RECORD LIKE ctbt042.*
DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE rm_v36		RECORD LIKE veht036.*
DEFINE vm_modulo	LIKE gent050.g50_modulo
DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_indice	SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_cod_tran	LIKE veht030.v30_cod_tran
DEFINE vm_num_tran	LIKE veht030.v30_num_tran

FUNCTION fl_control_master_contab_vehiculos(cod_cia, cod_loc, cod_tran, num_tran)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE cod_tran		LIKE veht030.v30_cod_tran
DEFINE num_tran		LIKE veht030.v30_num_tran
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp

INITIALIZE vm_cod_tran, vm_num_tran TO NULL
LET vm_cod_tran = cod_tran
LET vm_num_tran = num_tran
CALL fl_lee_compania_contabilidad(cod_cia) RETURNING rm_ctb.*	
IF rm_ctb.b00_inte_online = 'N' THEN
	RETURN
END IF
LET vm_modulo    = 'VE'
LET vm_tipo_comp = 'DV'
LET vm_indice    = 1
CALL fl_lee_cabecera_transaccion_veh(cod_cia, cod_loc, cod_tran, num_tran)
	RETURNING rm_cveh.*
IF rm_cveh.v30_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe transacción en módulo Vehículos: ' || cod_tran || ' ' || num_tran, 'stop')
	RETURN
END IF
IF DATE(rm_cveh.v30_fecing) <= rm_ctb.b00_fecha_cm THEN
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
DECLARE q_dveh CURSOR FOR SELECT * FROM veht031
	WHERE v31_compania  = rm_cveh.v30_compania  AND 
	      v31_localidad = rm_cveh.v30_localidad AND 
	      v31_cod_tran  = rm_cveh.v30_cod_tran  AND 
	      v31_num_tran  = rm_cveh.v30_num_tran
CASE rm_cveh.v30_cod_tran 
	WHEN 'FA'
		CALL fl_contabiliza_venta_vehiculos(9)
		LET vm_indice = vm_indice + 1
		CALL fl_contabiliza_costo_venta_vehiculos(42)
		LET vm_indice = vm_indice + 1
	WHEN 'DF'
		CALL fl_contabiliza_dev_venta_vehiculos(10)
		LET vm_indice = vm_indice + 1
	WHEN 'IM'
		CALL fl_contabiliza_importaciones_vehiculos(15)
		LET vm_indice = vm_indice + 1
END CASE
CALL fl_chequea_cuadre_db_cr_2()
BEGIN WORK
CALL fl_genera_comprobantes_veh()
COMMIT WORK
IF rm_ctb.b00_mayo_online = 'N' THEN
	RETURN
END IF
DECLARE q_dexter CURSOR WITH HOLD 
	FOR SELECT UNIQUE te_tipo_comp, te_num_comp
	FROM te_master
FOREACH q_dexter INTO tipo, num
	CALL fl_mayoriza_comprobante(rm_cveh.v30_compania, tipo, num, 'M')
END FOREACH
DROP TABLE te_master

END FUNCTION
	


FUNCTION fl_contabiliza_venta_vehiculos(subtipo)
DEFINE tot_efe		DECIMAL(14,2)
DEFINE tot_tar		DECIMAL(14,2)
DEFINE tot_otr		DECIMAL(14,2)
DEFINE val_iva		DECIMAL(14,2)
DEFINE tot_comp		DECIMAL(14,2)
DEFINE tot_cap		DECIMAL(14,2)
DEFINE tot_int		DECIMAL(14,2)
DEFINE tot_cred		DECIMAL(14,2)
DEFINE dif, dif_abs	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_prv		RECORD LIKE veht026.*
DEFINE r_dveh		RECORD LIKE veht031.*
DEFINE r_lr		RECORD LIKE veht003.*
DEFINE r_cj		RECORD LIKE cajt010.*
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE r_tj		RECORD LIKE gent010.*
DEFINE r_veh		RECORD LIKE veht022.*
DEFINE r_mod		RECORD LIKE veht020.*

LET tot_efe = 0
LET tot_tar = 0
LET tot_otr = 0
LET rm_cveh.v30_tot_bruto = rm_cveh.v30_tot_bruto * rm_cveh.v30_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_cveh.v30_tot_bruto)
	RETURNING rm_cveh.v30_tot_bruto
LET rm_cveh.v30_tot_dscto = rm_cveh.v30_tot_dscto * rm_cveh.v30_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_cveh.v30_tot_dscto)
	RETURNING rm_cveh.v30_tot_dscto
LET rm_cveh.v30_tot_neto  = rm_cveh.v30_tot_neto  * rm_cveh.v30_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_cveh.v30_tot_neto)
	RETURNING rm_cveh.v30_tot_neto
LET val_iva = rm_cveh.v30_tot_neto - (rm_cveh.v30_tot_bruto - rm_cveh.v30_tot_dscto)
SELECT * INTO r_cj.* FROM cajt010
	WHERE j10_compania     = rm_cveh.v30_compania  AND 
	      j10_localidad    = rm_cveh.v30_localidad AND 
	      j10_tipo_fuente  = 'PV'                  AND 
	      j10_tipo_destino = rm_cveh.v30_cod_tran  AND
	      j10_num_destino  = rm_cveh.v30_num_tran
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro de caja en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
SELECT * INTO r_prv.* FROM veht026
	WHERE v26_compania  = rm_cveh.v30_compania  AND
	      v26_localidad = rm_cveh.v30_localidad AND 
	      v26_numprev   = r_cj.j10_num_fuente
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe preventa en veht026: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_generales(rm_cveh.v30_compania, rm_cveh.v30_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
OPEN q_dveh
FETCH q_dveh INTO r_dveh.*
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Factura no tiene detalle: ' || rm_cveh.v30_cod_tran || ' ' || rm_cveh.v30_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cod_vehiculo_veh(rm_cveh.v30_compania, rm_cveh.v30_localidad, 
	r_dveh.v31_codigo_veh)
	RETURNING r_veh.*
CALL fl_lee_modelo_veh(rm_cveh.v30_compania, r_veh.v22_modelo)
	RETURNING r_mod.*
CALL fl_lee_linea_veh(r_dveh.v31_compania, r_mod.v20_linea)
	RETURNING r_lr.*
IF r_lr.v03_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe línea de venta: ' || r_mod.v20_linea || ' en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_caja(rm_cveh.v30_compania, rm_cveh.v30_localidad,
			    vm_modulo, r_lr.v03_grupo_linea)
	RETURNING rm_auxc.*
IF rm_auxc.b41_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares de Caja/Cobranzas.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_ventas(r_dveh.v31_compania, r_dveh.v31_localidad, 
		vm_modulo, rm_cveh.v30_bodega_ori, r_lr.v03_grupo_linea,
		rm_cveh.v30_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_cveh.v30_bodega_ori || '/' || r_lr.v03_grupo_linea || ' en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
DECLARE q_didi CURSOR FOR SELECT * FROM cajt011
	WHERE j11_compania     = r_cj.j10_compania    AND 
	      j11_localidad    = r_cj.j10_localidad   AND 
	      j11_tipo_fuente  = r_cj.j10_tipo_fuente AND
	      j11_num_fuente   = r_cj.j10_num_fuente
FOREACH q_didi INTO r_dj.*
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
		OTHERWISE
			LET tot_efe = tot_efe + r_dj.j11_valor
	END CASE
END FOREACH
SELECT SUM(v28_val_cap + v28_val_adi), SUM(v28_val_int) INTO tot_cap, tot_int
	FROM veht028
	WHERE v28_compania  = r_prv.v26_compania  AND 
	      v28_localidad = r_prv.v26_localidad AND 
	      v28_numprev   = r_prv.v26_numprev
IF tot_cap IS NULL THEN
	LET tot_cap = 0
	LET tot_int = 0
END IF
LET tot_comp = tot_efe + tot_tar + r_prv.v26_tot_pa_nc + tot_cap
IF rm_cveh.v30_tot_neto <> tot_comp THEN
	CALL fl_mostrar_mensaje('No cuadran valores de factura: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_cveh.v30_cod_tran, ' - ', rm_cveh.v30_num_tran
	    USING '<<<<<<<<<<<<<<<'
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxv.b40_venta, 'H',
        rm_cveh.v30_tot_bruto, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxv.b40_descuento, 'D',
        rm_cveh.v30_tot_dscto, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxg.b42_iva_venta, 'H',
        val_iva, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
IF rm_cveh.v30_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
LET tot_cred = tot_cap  + tot_int
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxc.b41_caja_mb, 
        'D', tot_efe, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb,'D',
        tot_cred, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxc.b41_ant_mb,'D',
	r_prv.v26_tot_pa_nc, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
IF tot_tar > 0 THEN
	CALL fl_lee_tarjeta_credito(r_dj.j11_cod_bco_tarj) RETURNING r_tj.*
	IF r_tj.g10_codcobr IS NULL THEN
		LET r_tj.g10_codcobr = rm_auxc.b41_cxc_mb
	END IF
	CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxc.b41_cxc_mb, 'D',
		tot_tar, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
END IF
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxc.b41_intereses, 'H',
		tot_int, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)

END FUNCTION



FUNCTION fl_contabiliza_costo_venta_vehiculos(subtipo)
DEFINE tot_costo	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_dveh		RECORD LIKE veht031.*
DEFINE r_veh		RECORD LIKE veht022.*
DEFINE r_mod		RECORD LIKE veht020.*
DEFINE r_lr		RECORD LIKE veht003.*

LET tot_costo = 0
FOREACH q_dveh INTO r_dveh.*
	LET tot_costo = tot_costo + r_dveh.v31_costo
END FOREACH
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, tot_costo)
	RETURNING tot_costo
CALL fl_lee_cod_vehiculo_veh(rm_cveh.v30_compania, rm_cveh.v30_localidad, 
	r_dveh.v31_codigo_veh)
	RETURNING r_veh.*
CALL fl_lee_modelo_veh(rm_cveh.v30_compania, r_veh.v22_modelo)
	RETURNING r_mod.*
CALL fl_lee_linea_veh(r_dveh.v31_compania, r_mod.v20_linea)
	RETURNING r_lr.*
CALL fl_lee_auxiliares_ventas(r_dveh.v31_compania, r_dveh.v31_localidad, 
		vm_modulo, rm_cveh.v30_bodega_ori, r_lr.v03_grupo_linea,
		rm_cveh.v30_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_cveh.v30_bodega_ori || '/' || r_lr.v03_grupo_linea || ' en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_cveh.v30_cod_tran, ' - ', rm_cveh.v30_num_tran
	    USING '<<<<<<<<<<<<<<<'
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxv.b40_costo_venta, 'D',
        tot_costo, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxv.b40_inventario,
        'H', tot_costo, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)

END FUNCTION



FUNCTION fl_contabiliza_dev_venta_vehiculos(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_fact		RECORD LIKE veht030.*
DEFINE r_v50		RECORD LIKE veht050.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE i		SMALLINT

CALL fl_lee_cabecera_transaccion_veh(rm_cveh.v30_compania,rm_cveh.v30_localidad,
	rm_cveh.v30_tipo_dev, rm_cveh.v30_num_dev)
	RETURNING r_fact.*
IF r_fact.v30_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe factura devuelta : ' || rm_cveh.v30_cod_tran || ' ' || rm_cveh.v30_num_tran, 'stop')
	RETURN
END IF
IF rm_cveh.v30_tot_neto = r_fact.v30_tot_neto THEN
	DECLARE ve_repcont CURSOR WITH HOLD FOR 
		SELECT * FROM veht050
			WHERE v50_compania  = r_fact.v30_compania  AND 
		              v50_localidad = r_fact.v30_localidad AND 
		              v50_cod_tran  = r_fact.v30_cod_tran  AND 
		              v50_num_tran  = r_fact.v30_num_tran
		        ORDER BY v50_num_comp DESC
	LET i = 0
	FOREACH ve_repcont INTO r_v50.*
		LET i = i + 1
		CALL fl_lee_comprobante_contable(r_fact.v30_compania, 
				r_v50.v50_tipo_comp, r_v50.v50_num_comp)
			RETURNING r_b12.*
		IF r_b12.b12_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe en ctbt012 comprobante de la veht050.', 'STOP')
			EXIT PROGRAM
		END IF
		CALL fl_mayoriza_comprobante(r_b12.b12_compania, r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'D')
		CALL fl_lee_comprobante_contable(r_fact.v30_compania, 
				r_v50.v50_tipo_comp, r_v50.v50_num_comp)
			RETURNING r_b12.*
		SET LOCK MODE TO WAIT 5
		UPDATE ctbt012 SET b12_estado     = 'E',
				   b12_fec_modifi = CURRENT 
			WHERE b12_compania  = r_b12.b12_compania  AND 
			      b12_tipo_comp = r_b12.b12_tipo_comp AND 
			      b12_num_comp  = r_b12.b12_num_comp
		INSERT INTO veht050 VALUES (rm_cveh.v30_compania, 
			rm_cveh.v30_localidad, rm_cveh.v30_cod_tran, 
		        rm_cveh.v30_num_tran, r_b12.b12_tipo_comp, 
		        r_b12.b12_num_comp)
		IF i = 2 THEN
			EXIT FOREACH
		END IF
	END FOREACH	
END IF

END FUNCTION	



FUNCTION fl_contabiliza_importaciones_vehiculos(subtipo)
DEFINE tot_costo	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE r_dveh		RECORD LIKE veht031.*
DEFINE r_lr		RECORD LIKE veht003.*
DEFINE r_veh		RECORD LIKE veht022.*
DEFINE r_mod		RECORD LIKE veht020.*

CALL fl_lee_liquidacion_veh(rm_cveh.v30_compania, rm_cveh.v30_localidad, 
	rm_cveh.v30_numliq)
	RETURNING rm_v36.*
LET tot_costo = 0
FOREACH q_dveh INTO r_dveh.*
	LET tot_costo = tot_costo + r_dveh.v31_costo
END FOREACH
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, tot_costo)
	RETURNING tot_costo
CALL fl_lee_cod_vehiculo_veh(rm_cveh.v30_compania, rm_cveh.v30_localidad, 
	r_dveh.v31_codigo_veh)
	RETURNING r_veh.*
CALL fl_lee_modelo_veh(rm_cveh.v30_compania, r_veh.v22_modelo)
	RETURNING r_mod.*
CALL fl_lee_linea_veh(r_dveh.v31_compania, r_mod.v20_linea)
	RETURNING r_lr.*
CALL fl_lee_auxiliares_ventas(r_dveh.v31_compania, r_dveh.v31_localidad, 
		vm_modulo, rm_cveh.v30_bodega_dest, r_lr.v03_grupo_linea,
		rm_cveh.v30_porc_impto)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_cveh.v30_bodega_ori || '/' || r_lr.v03_grupo_linea || ' en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
LET glosa = rm_cveh.v30_cod_tran, ' - ', rm_cveh.v30_num_tran
	    USING '<<<<<<<<<<<<<<<'
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxv.b40_inventario, 'D',
        tot_costo, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)
CALL fl_genera_detalle_comp_veh(vm_tipo_comp, subtipo, rm_auxv.b40_transito,
        'H', tot_costo, glosa, rm_cveh.v30_cod_tran, rm_cveh.v30_num_tran)

END FUNCTION



FUNCTION fl_genera_comprobantes_veh()
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
        
DECLARE q_mast CURSOR FOR SELECT UNIQUE te_tipo_comp, te_subtipo, te_indice 
	FROM te_master
	ORDER BY 3
FOREACH q_mast INTO tipo_comp, subtipo, indice
	INITIALIZE r_ccomp.* TO NULL
	LET r_ccomp.b12_num_comp = fl_numera_comprobante_contable(rm_cveh.v30_compania,
		tipo_comp, YEAR(rm_cveh.v30_fecing), MONTH(rm_cveh.v30_fecing))
	IF r_ccomp.b12_num_comp = '-1' THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_ccomp.b12_compania 	= rm_cveh.v30_compania
    	LET r_ccomp.b12_tipo_comp 	= tipo_comp
    	LET r_ccomp.b12_estado 		= 'A'
    	LET r_ccomp.b12_subtipo 	= subtipo
	IF vm_cod_tran IS NOT NULL THEN
    		LET r_ccomp.b12_fec_proceso = rm_cveh.v30_fecing
    		LET r_ccomp.b12_glosa	= 'COMPROBANTE: ',
			rm_cveh.v30_cod_tran, ' ', rm_cveh.v30_num_tran 
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
		CASE rm_cveh.v30_cod_tran
			WHEN 'FA'
    				LET r_dcomp.b13_codcli  = rm_cveh.v30_codcli
			WHEN 'AF'
    				LET r_dcomp.b13_codcli  = rm_cveh.v30_codcli
			WHEN 'DF'
    				LET r_dcomp.b13_codcli  = rm_cveh.v30_codcli
			WHEN 'CL'
    				LET r_dcomp.b13_codprov = rm_c10.c10_codprov
			WHEN 'DC'
    				LET r_dcomp.b13_codprov = rm_c10.c10_codprov
			WHEN 'IM'
    				LET r_dcomp.b13_pedido  = rm_v36.v36_pedido
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
	INSERT INTO veht050 VALUES (rm_cveh.v30_compania, rm_cveh.v30_localidad,
	    cod_tran, num_tran, tipo_comp, num_comp)
END FOREACH

END FUNCTION



FUNCTION fl_chequea_cuadre_db_cr_2()
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE cod_tran		LIKE veht030.v30_cod_tran
DEFINE num_tran		LIKE veht030.v30_num_tran
DEFINE indice		SMALLINT

DECLARE q_sdbcr2 CURSOR FOR SELECT te_tipo_comp, te_subtipo, te_indice, 
	te_cod_tran, te_num_tran, SUM(te_valor)
	FROM te_master
	GROUP BY 1, 2, 3, 4, 5
	HAVING SUM(te_valor) <> 0
FOREACH q_sdbcr2 INTO tipo_comp, subtipo, indice, cod_tran, num_tran, valor
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



FUNCTION fl_genera_detalle_comp_veh(tipo_comp, subtipo, cuenta, tipo_mov, 
		valor, glosa, cod_tran, num_tran)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE tipo_mov		CHAR(1)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE valor		DECIMAL(14,2)
DEFINE cod_tran		LIKE veht030.v30_cod_tran
DEFINE num_tran		LIKE veht030.v30_num_tran

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



FUNCTION fl_contabilizacion_trans_caja_ret(cod_cia, cod_loc, tipo_fuente,
					num_fuente, vm_tipo_fue, vm_num_sol)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE vm_tipo_fue	LIKE cajt010.j10_tipo_fuente
DEFINE vm_num_sol	LIKE cajt010.j10_num_fuente
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp

CALL fl_lee_compania_contabilidad(cod_cia) RETURNING rm_ctb.*	
IF rm_ctb.b00_inte_online = 'N' THEN
	RETURN
END IF
LET vm_tipo_comp = 'DC'
LET vm_indice    = 1
IF tipo_fuente = 'SC' OR tipo_fuente = 'PR' OR tipo_fuente = 'OT' THEN
	CALL fl_lee_cabecera_caja(cod_cia, cod_loc, tipo_fuente, num_fuente)
		RETURNING rm_caja.*
ELSE
	CALL fl_lee_cabecera_caja(cod_cia, cod_loc, vm_tipo_fue, vm_num_sol)
		RETURNING rm_caja.*
	LET rm_caja.j10_tipo_destino = tipo_fuente
	LET rm_caja.j10_num_destino  = num_fuente
	LET tipo_fuente              = rm_caja.j10_tipo_fuente
	LET num_fuente               = rm_caja.j10_num_fuente
END IF
IF rm_caja.j10_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe transacción en Caja: ' || tipo_fuente || ' ' || num_fuente, 'stop')
	RETURN
END IF
IF DATE(rm_caja.j10_fecha_pro) <= rm_ctb.b00_fecha_cm THEN
	CALL fl_mostrar_mensaje('La fecha de la transacción corresponde a un mes contable ya cerrado: ' || tipo_fuente || ' ' || num_fuente, 'stop')
	RETURN
END IF
CALL fl_lee_auxiliares_generales(cod_cia, cod_loc) RETURNING rm_auxg.*
CREATE TEMP TABLE te_master
	(
		te_tipo_comp		CHAR(2),
		te_num_comp		CHAR(8),
		te_subtipo		SMALLINT,
		te_codcli		INTEGER,
		te_tipo_doc		CHAR(2),
		te_num_doc		INTEGER,
		te_cuenta		CHAR(12),
		te_glosa		CHAR(90),
		te_tipo_mov		CHAR(1),
		te_valor		DECIMAL(14,2),
		te_indice		SMALLINT
	)
DECLARE q_dic CURSOR FOR
	SELECT * FROM cajt011
		WHERE j11_compania     = rm_caja.j10_compania
		  AND j11_localidad    = rm_caja.j10_localidad
		  AND j11_tipo_fuente  = rm_caja.j10_tipo_fuente
		  AND j11_num_fuente   = rm_caja.j10_num_fuente
CASE rm_caja.j10_tipo_destino
	WHEN 'AR' CALL fl_contabiliza_pago_ret(57)
	WHEN 'PG' CALL fl_contabiliza_pago_ret(3)
	WHEN 'PR' CALL fl_contabiliza_anticipo_ret(56)
END CASE
LET vm_indice = vm_indice + 1
CALL fl_chequea_cuadre_db_cr_1()
BEGIN WORK
	CALL fl_genera_comprobantes_caja_ret(tipo_fuente, num_fuente)
COMMIT WORK
IF rm_ctb.b00_mayo_online = 'N' THEN
	DROP TABLE te_master
	RETURN
END IF
DECLARE q_icm CURSOR WITH HOLD FOR
	SELECT UNIQUE te_tipo_comp, te_num_comp
		FROM te_master
FOREACH q_icm INTO tipo, num
	CALL fl_mayoriza_comprobante(vg_codcia, tipo, num, 'M')
END FOREACH
DROP TABLE te_master

END FUNCTION



FUNCTION fl_retorna_cont_cred_ret(r_dj)
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE cont_cred	LIKE cajt014.j14_cont_cred

LET cont_cred = 'R'
DECLARE q_j14_cr2 CURSOR FOR
	SELECT j14_cont_cred
		FROM cajt014
		WHERE j14_compania    = r_dj.j11_compania
		  AND j14_localidad   = r_dj.j11_localidad
		  AND j14_tipo_fuente = r_dj.j11_tipo_fuente
		  AND j14_num_fuente  = r_dj.j11_num_fuente
		  AND j14_secuencia   = r_dj.j11_secuencia
OPEN q_j14_cr2
FETCH q_j14_cr2 INTO cont_cred
CLOSE q_j14_cr2
FREE q_j14_cr2
RETURN cont_cred

END FUNCTION



FUNCTION fl_contabiliza_anticipo_ret(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE tot_ret		DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_ica		RECORD LIKE cxct021.*
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j02		RECORD LIKE cajt002.*

CALL fl_lee_documento_favor_cxc(rm_caja.j10_compania, rm_caja.j10_localidad,
				rm_caja.j10_codcli, rm_caja.j10_tipo_destino,
				rm_caja.j10_num_destino)
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
				rm_caja.j10_codigo_caja)
	RETURNING r_j02.*
IF r_j02.j02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe en cajt002: ' || rm_caja.j10_codigo_caja, 'stop')
	EXIT PROGRAM
END IF
IF r_j02.j02_aux_cont IS NOT NULL THEN
	LET rm_auxc.b41_caja_mb = r_j02.j02_aux_cont
	LET rm_auxc.b41_caja_me = r_j02.j02_aux_cont
END IF
LET glosa   = rm_caja.j10_nomcli[1,25] CLIPPED, ' ', rm_caja.j10_tipo_destino,
		' - ', rm_caja.j10_num_destino USING '<<<<<&'
LET tot_ret = 0
FOREACH q_dic INTO r_dj.*
	LET r_dj.j11_valor = r_dj.j11_valor * r_dj.j11_paridad
	CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, r_dj.j11_valor)
		RETURNING r_dj.j11_valor
	LET tot_ret = tot_ret + r_dj.j11_valor
	CALL fl_retorna_cont_cred_ret(r_dj.*) RETURNING cont_cred
END FOREACH
IF rm_caja.j10_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
-- FORMA DE CONTABILIZAR RETENCIONES DE CONTADO Y/O CREDITO
IF tot_ret > 0 THEN
	CALL fl_generar_registro_ret(r_dj.*, vm_tipo_comp, subtipo, 'D',
			r_j02.j02_aux_cont, glosa, rm_caja.j10_codcli,
			rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)
END IF
-- CONFIGURACION TEMPORAL PARA OBTENER CUENTA TRANSITORIA DE CLIENTES
IF r_ica.z21_saldo = 0 THEN
	CALL fl_lee_tipo_pago_caja(rm_caja.j10_compania, "RR", cont_cred)
		RETURNING r_j01.*
	LET rm_auxc.b41_ant_mb = r_j01.j01_aux_cont
END IF
--
CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, rm_auxc.b41_ant_mb, 'H',
			tot_ret, glosa, rm_caja.j10_codcli,
			rm_caja.j10_tipo_destino, rm_caja.j10_num_destino)

END FUNCTION



FUNCTION fl_contabiliza_pago_ret(subtipo)
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE tot_ret		DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE r_an		RECORD LIKE gent003.*
DEFINE r_so		RECORD LIKE cxct024.*
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE tip_db, tip_cr	CHAR(1)

CALL fl_lee_solicitud_cobro_cxc(rm_caja.j10_compania, rm_caja.j10_localidad,
				rm_caja.j10_num_fuente)
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
				rm_caja.j10_codcli)
	RETURNING r_z02.*
IF r_z02.z02_aux_clte_mb IS NOT NULL THEN
	LET rm_auxc.b41_cxc_mb = r_z02.z02_aux_clte_mb
END IF
IF r_z02.z02_aux_clte_ma IS NOT NULL THEN
	LET rm_auxc.b41_cxc_me = r_z02.z02_aux_clte_ma
END IF
CALL fl_lee_codigo_caja_caja(rm_caja.j10_compania, rm_caja.j10_localidad,
				rm_caja.j10_codigo_caja)
	RETURNING r_j02.*
IF r_j02.j02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe en cajt002: ' || rm_caja.j10_codigo_caja, 'stop')
	EXIT PROGRAM
END IF
IF r_j02.j02_aux_cont IS NOT NULL THEN
	LET rm_auxc.b41_caja_mb = r_j02.j02_aux_cont
	LET rm_auxc.b41_caja_me = r_j02.j02_aux_cont
END IF
LET glosa   = rm_caja.j10_nomcli[1,25] CLIPPED, ' ', rm_caja.j10_tipo_destino,
		' - ', rm_caja.j10_num_destino USING '<<<<<&'
LET tot_ret = 0
FOREACH q_dic INTO r_dj.*
	LET r_dj.j11_valor = r_dj.j11_valor * r_dj.j11_paridad
	CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, r_dj.j11_valor)
		RETURNING r_dj.j11_valor
	LET tot_ret = tot_ret + r_dj.j11_valor
	CALL fl_retorna_cont_cred_ret(r_dj.*) RETURNING cont_cred
END FOREACH
IF rm_caja.j10_moneda <> rg_gen.g00_moneda_base THEN
	LET rm_auxc.b41_caja_mb = rm_auxc.b41_caja_me
	LET rm_auxc.b41_cxc_mb  = rm_auxc.b41_cxc_me
	LET rm_auxc.b41_ant_mb  = rm_auxc.b41_ant_me
END IF
LET tip_db  = 'H'
LET tip_cr  = 'D'
IF subtipo = 3 THEN
	LET tip_db  = 'D'
	LET tip_cr  = 'H'
END IF
IF tip_db = 'D' THEN
	-- FORMA DE CONTABILIZAR RETENCIONES DE CONTADO Y/O CREDITO
	CALL fl_generar_registro_ret(r_dj.*, vm_tipo_comp, subtipo, tip_db,
				r_j02.j02_aux_cont, glosa, rm_caja.j10_codcli,
				rm_caja.j10_tipo_destino,
				rm_caja.j10_num_destino)
	-- CONFIGURACION TEMPORAL PARA OBTENER CUENTA TRANSITORIA DE CLIENTES
	IF subtipo <> 3 THEN
		CALL fl_lee_tipo_pago_caja(rm_caja.j10_compania, "RR",cont_cred)
			RETURNING r_j01.*
		LET rm_auxc.b41_cxc_mb = r_j01.j01_aux_cont
	END IF
	--
	CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo,rm_auxc.b41_cxc_mb,
				tip_cr,	tot_ret, glosa, rm_caja.j10_codcli,
				rm_caja.j10_tipo_destino,
				rm_caja.j10_num_destino)
ELSE
	-- CONFIGURACION TEMPORAL PARA OBTENER CUENTA TRANSITORIA DE CLIENTES
	IF subtipo <> 3 THEN
		CALL fl_lee_tipo_pago_caja(rm_caja.j10_compania, "RR",cont_cred)
			RETURNING r_j01.*
		LET rm_auxc.b41_cxc_mb = r_j01.j01_aux_cont
	END IF
	--
	CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo,rm_auxc.b41_cxc_mb,
				tip_cr,	tot_ret, glosa, rm_caja.j10_codcli,
				rm_caja.j10_tipo_destino,
				rm_caja.j10_num_destino)
	-- FORMA DE CONTABILIZAR RETENCIONES DE CONTADO Y/O CREDITO
	CALL fl_generar_registro_ret(r_dj.*, vm_tipo_comp, subtipo, tip_db,
				r_j02.j02_aux_cont, glosa, rm_caja.j10_codcli,
				rm_caja.j10_tipo_destino,
				rm_caja.j10_num_destino)
END IF

END FUNCTION



FUNCTION fl_genera_comprobantes_caja_ret(tipo_fuente, num_fuente)
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente
DEFINE num_fuente	LIKE cajt010.j10_num_fuente
DEFINE tipo_comp	CHAR(2)
DEFINE num_comp		CHAR(8)
DEFINE subtipo		SMALLINT
DEFINE codcli		INTEGER
DEFINE cod_tran		CHAR(2)
DEFINE num_tran		INTEGER
DEFINE cuenta		CHAR(12)
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE indice, i	SMALLINT
DEFINE limite		SMALLINT
DEFINE query		CHAR(800)
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_dcomp		RECORD LIKE ctbt013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE glosa, glosa_adi	LIKE ctbt013.b13_glosa
        
DECLARE q_mast2 CURSOR FOR
	SELECT UNIQUE te_tipo_comp, te_subtipo, te_indice 
		FROM te_master
		ORDER BY 3
FOREACH q_mast2 INTO tipo_comp, subtipo, indice
	INITIALIZE r_ccomp.* TO NULL
	SELECT fecha_pro INTO r_ccomp.b12_fec_proceso
		FROM tmp_doc
		WHERE tipo_sol = tipo_fuente
		  AND num_sol  = num_fuente
	IF rm_caja.j10_tipo_destino = 'AR' THEN
		LET r_ccomp.b12_fec_proceso = TODAY
	END IF
	CALL fl_numera_comprobante_contable(rm_caja.j10_compania, tipo_comp,
					YEAR(r_ccomp.b12_fec_proceso),
					MONTH(r_ccomp.b12_fec_proceso))
		RETURNING r_ccomp.b12_num_comp
	IF r_ccomp.b12_num_comp = '-1' THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_ccomp.b12_compania  = rm_caja.j10_compania
    	LET r_ccomp.b12_tipo_comp = tipo_comp
    	LET r_ccomp.b12_estado    = 'A'
    	LET r_ccomp.b12_subtipo   = subtipo
	LET r_ccomp.b12_glosa     = 'COMPROBANTE: ', rm_caja.j10_tipo_destino,
					'-', rm_caja.j10_num_destino
					USING '<<<<<&'
	LET query = 'SELECT * FROM cxct023 ',
			' WHERE z23_compania  = ', rm_caja.j10_compania,
			'   AND z23_localidad = ', rm_caja.j10_localidad,
			'   AND z23_codcli    = ', rm_caja.j10_codcli,
			'   AND z23_tipo_trn  = "',rm_caja.j10_tipo_destino,'"',
			'   AND z23_num_trn   = ', rm_caja.j10_num_destino,
			' ORDER BY z23_orden '
	IF rm_caja.j10_tipo_destino = 'PR' THEN
		LET query = 'SELECT * FROM cxct023 ',
			' WHERE z23_compania  = ', rm_caja.j10_compania,
			'   AND z23_localidad = ', rm_caja.j10_localidad,
			'   AND z23_codcli    = ', rm_caja.j10_codcli,
			'   AND z23_tipo_favor= "',rm_caja.j10_tipo_destino,'"',
			'   AND z23_doc_favor = ', rm_caja.j10_num_destino,
			' ORDER BY z23_orden '
	END IF
	IF rm_caja.j10_tipo_destino = 'PR' OR rm_caja.j10_tipo_destino = 'PG'
	THEN
		LET r_ccomp.b12_glosa = 'PAGO: ', rm_caja.j10_tipo_destino, '-',
					rm_caja.j10_num_destino USING '<<<<&',
					'  ***'
	END IF
	PREPARE cons_z23 FROM query
	DECLARE q_z23 CURSOR FOR cons_z23
	CALL fl_lee_cliente_general(rm_caja.j10_codcli) RETURNING r_z01.*
	LET glosa_adi = r_z01.z01_nomcli[1,25] CLIPPED, ' FACT: '
	FOREACH q_z23 INTO r_z23.*
		IF rm_caja.j10_tipo_destino = 'PR' THEN
			CALL fl_lee_documento_deudor_cxc(rm_caja.j10_compania,
						rm_caja.j10_localidad,
						rm_caja.j10_codcli,
						r_z23.z23_tipo_doc,
						r_z23.z23_num_doc,
						r_z23.z23_div_doc)
				RETURNING r_z20.*
			LET r_ccomp.b12_glosa = r_ccomp.b12_glosa CLIPPED, '  ',
					r_z20.z20_cod_tran, '-',
					r_z20.z20_num_tran USING "<<<<<<&"
			LET glosa_adi = glosa_adi CLIPPED, ' ',
					r_z20.z20_num_tran USING "<<<<<<&", ','
		ELSE
			LET r_ccomp.b12_glosa = r_ccomp.b12_glosa CLIPPED, '  ',
						r_z23.z23_tipo_doc, ' ',
						r_z23.z23_num_doc CLIPPED, '-',
						r_z23.z23_div_doc USING '&&'
			LET glosa_adi = glosa_adi CLIPPED, ' ',
					r_z23.z23_num_doc USING "<<<<<<&", ','
		END IF
	END FOREACH
	LET limite              = LENGTH(glosa_adi)
	LET glosa_adi           = glosa_adi[1, limite - 1], ' ',
					rm_caja.j10_tipo_destino, ' - ',
					rm_caja.j10_num_destino USING '<<<<<&'
    	LET r_ccomp.b12_origen  = 'A'
    	LET r_ccomp.b12_moneda  = rm_caja.j10_moneda
    	LET r_ccomp.b12_paridad = 1
    	LET r_ccomp.b12_modulo  = vg_modulo
    	LET r_ccomp.b12_usuario = vg_usuario
    	LET r_ccomp.b12_fecing  = CURRENT
	INSERT INTO ctbt012 VALUES (r_ccomp.*)
	DECLARE q_dmast2 CURSOR FOR
		SELECT * FROM te_master
			WHERE te_tipo_comp = tipo_comp
			  AND te_subtipo   = subtipo
			ORDER BY te_tipo_mov, te_cuenta
	INITIALIZE r_dcomp.* TO NULL
	LET i = 0
	FOREACH q_dmast2 INTO tipo_comp, num_comp, subtipo, codcli, cod_tran,
				num_tran, cuenta, glosa, tipo_mov, valor, indice
		LET i                       = i + 1
    		LET r_dcomp.b13_compania    = r_ccomp.b12_compania
    		LET r_dcomp.b13_tipo_comp   = r_ccomp.b12_tipo_comp
    		LET r_dcomp.b13_num_comp    = r_ccomp.b12_num_comp
    		LET r_dcomp.b13_secuencia   = i
    		LET r_dcomp.b13_cuenta      = cuenta
    		LET r_dcomp.b13_glosa       = glosa CLIPPED, ' ',
						glosa_adi CLIPPED
    		LET r_dcomp.b13_valor_base  = valor
    		LET r_dcomp.b13_valor_aux   = 0
    		LET r_dcomp.b13_fec_proceso = r_ccomp.b12_fec_proceso
    		LET r_dcomp.b13_num_concil  = 0
    		LET r_dcomp.b13_codcli      = rm_caja.j10_codcli
		INSERT INTO ctbt013 VALUES(r_dcomp.*)
	END FOREACH
	UPDATE te_master
		SET te_num_comp = r_ccomp.b12_num_comp
		WHERE te_tipo_comp = r_ccomp.b12_tipo_comp
		  AND te_num_comp  IS NULL
END FOREACH
DECLARE q_crc2 CURSOR FOR 
	SELECT UNIQUE te_codcli, te_tipo_doc, te_num_doc, te_tipo_comp,
			te_num_comp 
		FROM te_master
FOREACH q_crc2 INTO codcli, cod_tran, num_tran, tipo_comp, num_comp
	INSERT INTO cxct040
		VALUES (rm_caja.j10_compania, rm_caja.j10_localidad,
			codcli, cod_tran, num_tran, tipo_comp, num_comp)
END FOREACH

END FUNCTION



FUNCTION fl_generar_registro_ret(r_dj, tipo_comp, subtipo, tipo_mov, cuenta,
				glosa, codcli, cod_tran, num_tran)
DEFINE r_dj		RECORD LIKE cajt011.*
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE tipo_mov		CHAR(1)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE codcli		LIKE cajt010.j10_codcli
DEFINE cod_tran		LIKE cxct021.z21_tipo_doc
DEFINE num_tran		LIKE cxct021.z21_num_doc
DEFINE r_j91		RECORD LIKE cajt091.*
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_z09		RECORD LIKE cxct009.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j02		RECORD LIKE cajt002.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE aux_ret		LIKE ctbt010.b10_cuenta
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE tip_db, tip_cr	CHAR(1)

FOREACH q_dic INTO r_dj.*
	CALL fl_retorna_cont_cred_ret(r_dj.*) RETURNING cont_cred
	IF NOT fl_determinar_si_es_retencion(r_dj.j11_compania,
			r_dj.j11_codigo_pago, cont_cred)
	THEN
		CONTINUE FOREACH
	END IF
	DECLARE q_j14_2 CURSOR FOR
		SELECT * FROM cajt014
			WHERE j14_compania    = r_dj.j11_compania
			  AND j14_localidad   = r_dj.j11_localidad
			  AND j14_tipo_fuente = r_dj.j11_tipo_fuente
			  AND j14_num_fuente  = r_dj.j11_num_fuente
			  AND j14_secuencia   = r_dj.j11_secuencia
			  AND j14_codigo_pago = r_dj.j11_codigo_pago
			ORDER BY j14_sec_ret
	LET aux_ret = rm_auxg.b42_reten_cred
	FOREACH q_j14_2 INTO r_j14.*
		CALL fl_lee_det_retencion_cli(r_j14.j14_compania,
						rm_caja.j10_codcli,
						r_j14.j14_tipo_ret,
						r_j14.j14_porc_ret,
						r_j14.j14_codigo_sri,
						r_dj.j11_codigo_pago,
						r_j14.j14_cont_cred)
			RETURNING r_z09.*
		IF r_z09.z09_aux_cont IS NOT NULL THEN
			LET aux_ret = r_z09.z09_aux_cont
		ELSE
			CALL fl_lee_det_tipo_ret_caja(rm_caja.j10_compania,
						r_dj.j11_codigo_pago,
						r_j14.j14_cont_cred,
						r_j14.j14_tipo_ret,
						r_j14.j14_porc_ret)
				RETURNING r_j91.*
			IF r_j91.j91_aux_cont IS NOT NULL THEN
				LET aux_ret = r_j91.j91_aux_cont
			ELSE
				CALL fl_lee_tipo_pago_caja(rm_caja.j10_compania,
							r_dj.j11_codigo_pago,
							r_j14.j14_cont_cred)
					RETURNING r_j01.*
				IF r_j01.j01_aux_cont IS NOT NULL THEN
					LET aux_ret = r_j01.j01_aux_cont
				END IF
			END IF
		END IF
		IF subtipo <> 56 AND subtipo <> 3 THEN
			LET aux_ret             = cuenta
			LET r_j14.j14_valor_ret = r_j14.j14_valor_ret * (-1)
		END IF
		CALL fl_genera_detalle_comprob(vm_tipo_comp, subtipo, aux_ret,
				tip_db, r_j14.j14_valor_ret, glosa,
				rm_caja.j10_codcli, rm_caja.j10_tipo_destino,
				rm_caja.j10_num_destino)
	END FOREACH
END FOREACH

END FUNCTION

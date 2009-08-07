GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"

DEFINE vm_programa      VARCHAR(12)
DEFINE rm_cveh		RECORD LIKE veht030.*
DEFINE rm_auxv		RECORD LIKE ctbt040.*
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
	CALL fgl_winmessage(vg_producto, 'No existe transacción en módulo Vehículos: ' || cod_tran || ' ' || num_tran, 'stop')
	RETURN
END IF
IF DATE(rm_cveh.v30_fecing) <= rm_ctb.b00_fecha_cm THEN
	CALL fgl_winmessage(vg_producto, 'La fecha de la transacción corresponde a un mes contable ya cerrado: ' || cod_tran || ' ' || num_tran, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'No existe registro de caja en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
SELECT * INTO r_prv.* FROM veht026
	WHERE v26_compania  = rm_cveh.v30_compania  AND
	      v26_localidad = rm_cveh.v30_localidad AND 
	      v26_numprev   = r_cj.j10_num_fuente
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No existe preventa en veht026: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_generales(rm_cveh.v30_compania, rm_cveh.v30_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
OPEN q_dveh
FETCH q_dveh INTO r_dveh.*
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'Factura no tiene detalle: ' || rm_cveh.v30_cod_tran || ' ' || rm_cveh.v30_num_tran, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'No existe línea de venta: ' || r_mod.v20_linea || ' en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_caja(rm_cveh.v30_compania, rm_cveh.v30_localidad,
			    vm_modulo, r_lr.v03_grupo_linea, rm_cveh.v30_codcli)
	RETURNING rm_auxc.*
IF rm_auxc.b41_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No hay configuración de auxiliares de Caja/Cobranzas.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_auxiliares_ventas(r_dveh.v31_compania, r_dveh.v31_localidad, 
	vm_modulo, rm_cveh.v30_bodega_ori, r_lr.v03_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_cveh.v30_bodega_ori || '/' || r_lr.v03_grupo_linea || ' en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'No cuadran valores de factura: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
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
	vm_modulo, rm_cveh.v30_bodega_ori, r_lr.v03_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_cveh.v30_bodega_ori || '/' || r_lr.v03_grupo_linea || ' en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'No existe factura devuelta : ' || rm_cveh.v30_cod_tran || ' ' || rm_cveh.v30_num_tran, 'stop')
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
			CALL fgl_winmessage(vg_producto, 'No existe en ctbt012 comprobante de la veht050.', 'STOP')
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
	vm_modulo, rm_cveh.v30_bodega_dest, r_lr.v03_grupo_linea)
	RETURNING rm_auxv.*
IF rm_auxv.b40_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No hay configuración de auxiliares contables para bodega/grupo línea: ' || rm_cveh.v30_bodega_ori || '/' || r_lr.v03_grupo_linea || ' en transacción: ' || r_dveh.v31_cod_tran || ' ' || r_dveh.v31_num_tran, 'stop')
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
DEFINE glosa		CHAR(35)
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

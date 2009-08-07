DATABASE diteca

GLOBALS 'globales.4gl'


MAIN

-- CONTADORES
DEFINE import	SMALLINT

LET vg_codcia = 1
LET vg_codloc = 1
LET vg_producto = 'fobitos'
LET vg_usuario = 'FOBOS'
CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*



LET facturas_rep = 0
LET facturas_tal = 0
LET pagos_cli    = 0
LET pagos_ant    = 0
LET otros_ing    = 0
LET egr_caja     = 0

DECLARE q_tran CURSOR WITH HOLD  FOR 
	SELECT * FROM cajt010 WHERE j10_compania  = 1
				AND j10_localidad = 1
				AND j10_estado = 'P' 
				AND j10_fecha_pro > mdy(01, 01, 2004)
			      ORDER BY j10_fecha_pro

FOREACH q_tran INTO r_j10.*
	CASE r_j10.j10_tipo_fuente 
		WHEN 'PR'
			DECLARE q_r40 CURSOR FOR
			SELECT * FROM rept040
			 WHERE r40_compania  = r_j10.j10_compania
			   AND r40_localidad = r_j10.j10_localidad
			   AND r40_cod_tran  = r_j10.j10_tipo_destino
			   AND r40_num_tran  = r_j10.j10_num_destino

			OPEN  q_r40
			FETCH q_r40
			IF status = NOTFOUND THEN
				DISPLAY 'PR: ', r_j10.j10_fecha_pro
				DISPLAY 'Contabilizando ...' 
				CALL fl_control_master_contab_repuestos(
					r_j10.j10_compania,
					r_j10.j10_localidad,
					r_j10.j10_tipo_destino,
					r_j10.j10_num_destino
				)
				LET facturas_rep = facturas_rep + 1
			END IF
			CLOSE q_r40
			FREE  q_r40
		WHEN 'OT'
			DECLARE q_t50 CURSOR FOR
			SELECT * FROM talt050
			 WHERE t50_compania  = r_j10.j10_compania
			   AND t50_localidad = r_j10.j10_localidad
			   AND t50_orden     = r_j10.j10_num_fuente  
			   AND t50_factura   = r_j10.j10_num_destino

			OPEN  q_t50
			FETCH q_t50
			IF status = NOTFOUND THEN
				DISPLAY 'OT: ', r_j10.j10_fecha_pro
				DISPLAY 'Contabilizando ...' 
				CALL fl_control_master_contab_taller(
					r_j10.j10_compania,
					r_j10.j10_localidad,
					r_j10.j10_num_fuente,
					'F'
				)
				LET facturas_tal = facturas_tal + 1
			END IF
			CLOSE q_t50
			FREE  q_t50
		WHEN 'SC'
			DECLARE q_z40 CURSOR FOR
			SELECT * FROM cxct040
			 WHERE z40_compania  = r_j10.j10_compania
			   AND z40_localidad = r_j10.j10_localidad
			   AND z40_codcli    = r_j10.j10_codcli
			   AND z40_tipo_doc  = r_j10.j10_tipo_destino
			   AND z40_num_doc   = r_j10.j10_num_destino

			OPEN  q_z40
			FETCH q_z40
			IF status = NOTFOUND THEN
				IF r_j10.j10_tipo_destino = 'PG' THEN
					DISPLAY 'PG: ', r_j10.j10_fecha_pro
					DISPLAY 'Contabilizando ...' 
					CALL fl_control_master_contab_ingresos_caja(
						r_j10.j10_compania,
						r_j10.j10_localidad,
						r_j10.j10_tipo_fuente,
						r_j10.j10_num_fuente
					)
					LET pagos_cli = pagos_cli + 1
				ELSE
					DISPLAY 'PA: ', r_j10.j10_fecha_pro
					DISPLAY 'Contabilizando ...' 
					CALL fl_control_master_contab_ingresos_caja(
						r_j10.j10_compania,
						r_j10.j10_localidad,
						r_j10.j10_tipo_fuente,
						r_j10.j10_num_fuente
					)
					LET pagos_ant = pagos_ant + 1
				END IF
			END IF
			CLOSE q_z40
			FREE  q_z40
		WHEN 'EC'
			IF r_j10.j10_tip_contable IS NULL THEN
				DISPLAY 'EC: ', r_j10.j10_fecha_pro
				LET egr_caja = egr_caja + 1
			END IF
		WHEN 'OI'
			IF r_j10.j10_tip_contable IS NULL THEN
				DISPLAY 'OI: ', r_j10.j10_fecha_pro
				LET otros_ing = otros_ing + 1
			END IF
	END CASE
END FOREACH

DISPLAY 'Se encontraron ', facturas_rep, ' facturas de repuestos que no se han contabilizado.'
DISPLAY 'Se encontraron ', facturas_tal, ' facturas de taller que no se han contabilizado.'
DISPLAY 'Se encontraron ', pagos_cli, ' pagos de clientes que no se han contabilizado.'
DISPLAY 'Se encontraron ', pagos_ant, ' pagos anticipados que no se han contabilizado.'
DISPLAY 'Se encontraron ', egr_caja, ' egresos de caja que no se han contabilizado.'
DISPLAY 'Se encontraron ', otros_ing, ' otros ingresos que no se han contabilizado.'

END MAIN



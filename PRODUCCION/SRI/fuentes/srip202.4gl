--------------------------------------------------------------------------------
-- Titulo           : srip202.4gl - Anexo Transaccional Anulados
-- Elaboracion (Ori): 29-Ago-2006
-- Elaboracion      : 26-Dic-2017
-- Autor            : NPC
-- Formato Ejecucion: fglrun srip202 base módulo compañía localidad
--			             fec_ini fec_fin
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par 			RECORD 
							fecha_ini	DATE,
							fecha_fin	DATE
						END RECORD
DEFINE rm_det 			RECORD
							fecha		DATE,
							t23_num_factura	LIKE talt023.t23_num_factura,
							t23_orden	LIKE talt023.t23_orden,
							t23_val_mo_tal	LIKE talt023.t23_val_mo_tal,
							tot_oc		DECIMAL(14,2),
							tot_fa		DECIMAL(14,2),
							tot_ot		DECIMAL(14,2),
							t23_estado	LIKE talt023.t23_estado
						END RECORD
DEFINE rm_g01			RECORD LIKE gent001.*
DEFINE rm_r00			RECORD LIKE rept000.*
DEFINE vm_tip_anexo		LIKE srit004.s04_codigo
DEFINE vm_fin_mes		DATE



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
LET vg_proceso = arg_val(0)
CALL startlog('../logs/' || vg_proceso CLIPPED || '.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_tip_anexo = 2
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No está creada una compañía para el módulo de inventarios.','stop')
	RETURN
END IF
INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini = MDY(MONTH(vg_fecha), 1, YEAR(vg_fecha))
LET rm_par.fecha_fin = rm_par.fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET vm_fin_mes       = rm_par.fecha_fin
LET rm_par.fecha_ini = arg_val(5)
LET rm_par.fecha_fin = arg_val(6)
CALL generar_archivo()
DROP TABLE tmp_fact
DROP TABLE tmp_tal
CALL generar_archivo_anula_xml()
DROP TABLE tmp_anu

END FUNCTION



{**
	ESTA FUNCION GENERA EL ARCHIVO CONSOLIDADO DE LAS VENTAS USANDO LAS TABLAS:
		rept019
		rept020
		talt021
		talt023
		cxct020
		cxct021
**}

FUNCTION generar_archivo()
DEFINE r_mov		RECORD
						cod_cli		LIKE cxct001.z01_codcli,
						cod_t		LIKE rept019.r19_cod_tran,
						num_t		LIKE rept019.r19_num_tran,
						ced_ruc		LIKE rept019.r19_cedruc
					END RECORD
DEFINE r_tal		RECORD
						z01_tipo_doc_id	LIKE cxct001.z01_tipo_doc_id,
						z01_num_doc_id	LIKE cxct001.z01_num_doc_id,
						val_iva		DECIMAL(12,2),
						val_ci		DECIMAL(12,2),
						val_si		DECIMAL(12,2)
					END RECORD
DEFINE query		VARCHAR(4000)
DEFINE comando		VARCHAR(100)
DEFINE archivo		VARCHAR(50)
DEFINE resul		SMALLINT
DEFINE r_s21		RECORD LIKE srit021.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE porc_imp		LIKE gent000.g00_porc_impto
DEFINE valor_siva_aux	DECIMAL(14,2)
DEFINE ctos			INTEGER

INITIALIZE r_s21.* TO NULL
DECLARE q_estado CURSOR FOR
	SELECT UNIQUE s21_estado
	FROM srit021
	WHERE s21_compania  = vg_codcia
	  AND s21_localidad = vg_codloc
	  AND s21_anio      = YEAR(rm_par.fecha_fin)
	  AND s21_mes       = MONTH(rm_par.fecha_fin)
OPEN q_estado
FETCH q_estado INTO r_s21.s21_estado
CLOSE q_estado
FREE q_estado
IF r_s21.s21_estado = 'D' THEN
	CALL fl_mostrar_mensaje('No puede generar el anexo de ventas para este periodo. Ya esta declarado.', 'exclamation')
	RETURN
END IF
CALL obtener_facturas()
DECLARE q_verif CURSOR FOR
	SELECT codcli, cod_tran, num_tran, cedruc_v
		FROM tmp_fact
		WHERE LENGTH(cedruc_v) = 13
FOREACH q_verif INTO r_mov.*
	CALL fl_validar_cedruc_dig_ver(r_mov.ced_ruc) RETURNING resul
	IF NOT resul THEN
		UPDATE tmp_fact
			SET tipo_doc_id = 'P',
			    cod_tran    = 'FA',
			    cedruc      = r_mov.ced_ruc
			WHERE codcli   = r_mov.cod_cli
			  AND cod_tran = r_mov.cod_t
			  AND num_tran = r_mov.num_t
			  AND cedruc_v = r_mov.ced_ruc
	END IF
END FOREACH
LET query = 'SELECT t23_cod_cliente codcli, t23_num_factura num_tran, ',
				'CASE WHEN t23_val_impto > 0 ',
					'THEN t23_val_mo_tal + ',
					'CASE WHEN t23_estado = "F" ',
						'THEN ',
						'(SELECT NVL(SUM((c11_precio - c11_val_descto) ',
							'* (1 + c10_recargo / 100)), 0) ',
						'FROM ordt010, ordt011 ',
						'WHERE c10_compania    = t23_compania ',
						'  AND c10_localidad   = t23_localidad ',
						'  AND c10_ord_trabajo = t23_orden ',
						'  AND c10_estado      = "C" ',
						'  AND c11_compania    = c10_compania ',
						'  AND c11_localidad   = c10_localidad ',
						'  AND c11_numero_oc   = c10_numero_oc ',
						'  AND c11_tipo        = "S") + ',
						'(SELECT NVL(SUM(((c11_cant_ped * c11_precio) ',
						' - c11_val_descto) * (1 + c10_recargo / 100)), 0) ',
						'FROM ordt010, ordt011 ',
						'WHERE c10_compania    = t23_compania ',
						'  AND c10_localidad   = t23_localidad ',
						'  AND c10_ord_trabajo = t23_orden ',
						'  AND c10_estado      = "C" ',
						'  AND c11_compania    = c10_compania ',
						'  AND c11_localidad   = c10_localidad ',
						'  AND c11_numero_oc   = c10_numero_oc ',
						'  AND c11_tipo        = "B") + ',
							'CASE WHEN ',
									'(SELECT COUNT(*) FROM ordt010 ',
									'WHERE c10_compania    = t23_compania ',
									'  AND c10_localidad   = t23_localidad ',
									'  AND c10_ord_trabajo = t23_orden ',
									'  AND c10_estado      = "C") = 0 ',
								'THEN (t23_val_rp_tal + t23_val_rp_ext + ',
								       't23_val_rp_cti + t23_val_otros2) ',
								'ELSE 0.00 ',
							'END ',
						'ELSE (t23_val_mo_ext + t23_val_mo_cti + ',
								't23_val_rp_tal + t23_val_rp_ext + ',
								't23_val_rp_cti + t23_val_otros2) ',
					'END ',
					'ELSE 0.00 ',
				'END valor_tal_civa, ',
				'CASE WHEN t23_val_impto = 0 ',
					'THEN t23_val_mo_tal + ',
					'CASE WHEN t23_estado = "F" ',
						'THEN ',
						'(SELECT NVL(SUM((c11_precio - c11_val_descto) ',
							' * (1 + c10_recargo / 100)), 0) ',
						'FROM ordt010, ordt011 ',
						'WHERE c10_compania    = t23_compania ',
						'  AND c10_localidad   = t23_localidad ',
						'  AND c10_ord_trabajo = t23_orden ',
						'  AND c10_estado      = "C" ',
						'  AND c11_compania    = c10_compania ',
						'  AND c11_localidad   = c10_localidad ',
						'  AND c11_numero_oc   = c10_numero_oc ',
						'  AND c11_tipo        = "S") + ',
						'(SELECT NVL(SUM(((c11_cant_ped * c11_precio) ',
						' - c11_val_descto) * (1 + c10_recargo / 100)), 0) ',
						'FROM ordt010, ordt011 ',
						'WHERE c10_compania    = t23_compania ',
						'  AND c10_localidad   = t23_localidad ',
						'  AND c10_ord_trabajo = t23_orden ',
						'  AND c10_estado      = "C" ',
						'  AND c11_compania    = c10_compania ',
						'  AND c11_localidad   = c10_localidad ',
						'  AND c11_numero_oc   = c10_numero_oc ',
						'  AND c11_tipo        = "B") + ',
							'CASE WHEN ',
									'(SELECT COUNT(*) FROM ordt010 ',
									'WHERE c10_compania    = t23_compania ',
									'  AND c10_localidad   = t23_localidad ',
									'  AND c10_ord_trabajo = t23_orden ',
									'  AND c10_estado      = "C") = 0 ',
								'THEN (t23_val_rp_tal + t23_val_rp_ext + ',
								       't23_val_rp_cti + t23_val_otros2) ',
								'ELSE 0.00 ',
							'END ',
					'ELSE (t23_val_mo_ext + t23_val_mo_cti + ',
							't23_val_rp_tal + t23_val_rp_ext + ',
							't23_val_rp_cti + t23_val_otros2) ',
					'END ',
					'ELSE 0.00 ',
				'END valor_tal_siva, ',
				't23_val_impto, ',
				'CASE WHEN z01_tipo_doc_id = "R" AND ',
							' t23_cod_cliente <> ', rm_r00.r00_codcli_tal, ' ',
					'THEN "R" ',
					'ELSE "F" ',
				'END tipo_doc_id, ',
				'CASE WHEN z01_tipo_doc_id = "R" AND ',
						' t23_cod_cliente <> ', rm_r00.r00_codcli_tal, ' ',
					'THEN z01_num_doc_id ',
					'ELSE "9999999999999" ',
				'END cedruc, ',
				't23_cont_cred cont_cred, t23_localidad local, t23_estado, ',
				'DATE(t28_fec_anula) fecha_anu ',
			'FROM talt023, cxct001, OUTER talt028 ',
			'WHERE t23_compania           = ', vg_codcia,
			'  AND t23_localidad          = ', vg_codloc,
			'  AND t23_estado            IN ("F", "D") ',
			'  AND DATE(t23_fec_factura) BETWEEN "', rm_par.fecha_ini,
										  '" AND "', rm_par.fecha_fin, '"',
			'  AND z01_codcli             = t23_cod_cliente ',
			'  AND t28_compania           = t23_compania ',
			'  AND t28_localidad          = t23_localidad ',
			'  AND t28_factura            = t23_num_factura ',
			'INTO TEMP tmp_tal '
PREPARE cons_tmp_tal FROM query 
EXECUTE cons_tmp_tal
LET query = 'SELECT num_tran num_anu, z21_tipo_doc ',
				'FROM tmp_tal, OUTER cxct021 ',
				'WHERE t23_estado    = "D" ',
				'  AND z21_compania  = ', vg_codcia,
				'  AND z21_localidad = local ',
				'  AND z21_tipo_doc  = "NC" ',
				'  AND z21_areaneg   = 2 ',
				'  AND z21_cod_tran  = "FA" ',
				'  AND z21_num_tran  = num_tran ',
				'INTO TEMP t2 '
PREPARE cons_t2_tal FROM query 
EXECUTE cons_t2_tal
DELETE FROM t2 WHERE z21_tipo_doc IS NOT NULL
LET query = 'INSERT INTO tmp_anu ',
				'SELECT CASE WHEN r38_cod_tran = "FA" THEN 1 ',
							'WHEN r38_cod_tran = "NV" THEN 2 ',
						'END tipo_comp, ',
		'b.g37_pref_sucurs, b.g37_pref_pto_vta, r38_num_sri[9, 17] ',
		'num_sri_ini, r38_num_sri[9, 17] num_sri_fin, g02_numaut_sri ',
		'FROM tmp_tal, rept038, gent037 b, gent002 ',
		'WHERE t23_estado      = "D" ',
		'  AND num_tran        = ',
				'(SELECT num_anu ',
					'FROM t2 ',
					'WHERE num_anu  = num_tran) ',
		'  AND r38_compania    = ', vg_codcia,
		'  AND r38_localidad   = local ',
		'  AND r38_tipo_fuente = "OT" ',
		'  AND r38_cod_tran    IN ("FA", "NV") ',
		'  AND r38_num_tran    = num_tran ',
		'  AND b.g37_compania  = r38_compania ',
		'  AND b.g37_localidad = r38_localidad ',
		'  AND b.g37_tipo_doc  = r38_cod_tran ',
		'  AND b.g37_secuencia = ',
				'(SELECT MAX(a.g37_secuencia) ',
					'FROM gent037 a ',
					'WHERE a.g37_compania  = b.g37_compania ',
					'  AND a.g37_localidad = b.g37_localidad ',
					'  AND a.g37_tipo_doc  = b.g37_tipo_doc) ',
		'  AND g02_compania    = b.g37_compania ',
		'  AND g02_localidad   = b.g37_localidad '
PREPARE insert_tmp_anu FROM query 
EXECUTE insert_tmp_anu

END FUNCTION



{**
	OBTIENE LAS FACTURAS DE INVENTARIO: rept019
**}

FUNCTION obtener_facturas()
DEFINE query		VARCHAR(4000)

LET query = 'SELECT r19_codcli codcli, ',
		'CASE WHEN LENGTH(r19_cedruc) = 13 AND ',
			' r19_codcli <> ', rm_r00.r00_codcli_tal,
			'THEN r19_cod_tran ',
			'ELSE "NV" ',
		'END cod_tran, ',
		'r19_num_tran num_tran, r19_tipo_dev tipo_dev, ',
		'r19_num_dev num_dev, ',
		'CASE WHEN LENGTH(r19_cedruc) = 13 AND ',
			' r19_codcli <> ', rm_r00.r00_codcli_tal,
			'THEN "R" ',
			'ELSE "F" ',
		'END tipo_doc_id, ',
		'CASE WHEN LENGTH(r19_cedruc) = 13 AND ',
			' r19_codcli <> ', rm_r00.r00_codcli_tal,
			'THEN r19_cedruc ',
			'ELSE "9999999999999" ',
		'END cedruc, ',
		'CASE WHEN r19_porc_impto = 0 THEN ',
			' (r19_tot_neto - r19_flete) ',
			' ELSE 0.00 ',
		'END valor_vta_siva, ',
		'CASE WHEN r19_porc_impto > 0 THEN ',
			' (r19_tot_bruto - r19_tot_dscto) ',
			' ELSE 0.00 ',
		'END valor_vta_civa, ',
		'CASE WHEN r19_porc_impto > 0 THEN ',
			' (r19_tot_neto - r19_tot_bruto + ',
			' r19_tot_dscto - r19_flete) ',
			' ELSE 0.00 ',
		'END valor_iva, "', rm_par.fecha_fin, '" fecha_vta, ',
		' r19_flete, r19_porc_impto porc_impto, r19_cedruc cedruc_v,',
		' r19_cont_cred cont_cred, r19_localidad local ',
		' FROM rept019, cxct001 ',
		' WHERE r19_compania     = ', vg_codcia,
		'   AND r19_localidad    = ', vg_codloc,
		'   AND r19_cod_tran     IN ("FA", "NV") ',
		'   AND DATE(r19_fecing) BETWEEN "', rm_par.fecha_ini,
								  '" AND "', rm_par.fecha_fin, '"',
		'   AND z01_codcli       = r19_codcli ',
		' INTO TEMP tmp_fact ' 
PREPARE cons_tmp_fact FROM query 
EXECUTE cons_tmp_fact
LET query = 'SELECT tipo_dev tipo_anu, num_dev num_anu, z21_tipo_doc ',
		' FROM tmp_fact, OUTER cxct021 ',
		' WHERE tmp_fact.tipo_dev   = "AF" ',
		'   AND z21_compania  = ', vg_codcia,
		'   AND z21_localidad = ', vg_codloc,
		'   AND z21_tipo_doc  = "NC" ',
		'   AND z21_cod_tran  = tmp_fact.tipo_dev ',
		'   AND z21_num_tran  = tmp_fact.num_dev ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query 
EXECUTE cons_t2
DELETE FROM t2 WHERE z21_tipo_doc IS NOT NULL
LET query = 'SELECT ',
				'CASE WHEN LENGTH(cedruc) = 13 AND fp_digito_veri(cedruc) = 1 ',
						'THEN 1 ',
						'ELSE 2 ',
				'END tipo_comp, ',
				'b.g37_pref_sucurs, b.g37_pref_pto_vta, r38_num_sri[9, 17] ',
				'num_sri_ini, r38_num_sri[9, 17] num_sri_fin, g02_numaut_sri ',
			'FROM tmp_fact, rept038, gent037 b, gent002 ',
			'WHERE tipo_dev         = "AF" ',
			'  AND num_dev          = ',
					'(SELECT num_anu ',
					' FROM t2 ',
					' WHERE tipo_anu = tipo_dev ',
					'   AND num_anu  = num_dev) ',
			'  AND r38_compania     = ', vg_codcia,
			'  AND r38_localidad    = local ',
			'  AND r38_tipo_fuente  = "PR" ',
			'  AND r38_cod_tran    IN ("FA", "NV") ',
			'  AND r38_num_tran     = num_tran ',
			'  AND b.g37_compania   = r38_compania ',
			'  AND b.g37_localidad  = r38_localidad ',
			'  AND b.g37_tipo_doc   = r38_cod_tran ',
			'  AND b.g37_secuencia  = ',
			' (SELECT MAX(a.g37_secuencia) ',
				'FROM gent037 a ',
				'WHERE a.g37_compania  = b.g37_compania ',
				'  AND a.g37_localidad = b.g37_localidad ',
				'  AND a.g37_tipo_doc  = b.g37_tipo_doc) ',
			'  AND g02_compania    = b.g37_compania ',
			'  AND g02_localidad   = b.g37_localidad ',
			'INTO TEMP tmp_anu '
PREPARE cons_tmp_anu FROM query 
EXECUTE cons_tmp_anu
DELETE FROM tmp_fact
	WHERE tipo_dev = "AF"
	  AND num_dev  =
		(SELECT num_anu
			FROM t2
			WHERE tipo_anu = tipo_dev
			  AND num_anu  = num_dev)
DROP TABLE t2

END FUNCTION



{**
 * El anexo se genera según la ficha técnica del SRI que se encuentra en: 
 * http://descargas.sri.gob.ec/download/anexos/ats/FICHA_TECNICA_ATS_JULIO2016.pdf
 **}

FUNCTION generar_archivo_anula_xml()
DEFINE r_anu		RECORD
						comp		LIKE srit004.s04_codigo,
						punto		LIKE gent037.g37_pref_sucurs,
						estab		LIKE gent037.g37_pref_pto_vta,
						numini		LIKE rept038.r38_num_sri,
						numfin		LIKE rept038.r38_num_sri,
						autoriz		LIKE gent002.g02_numaut_sri,
						fecha		DATE
					END RECORD
DEFINE registro		CHAR(4000)
DEFINE genero		SMALLINT

DECLARE q_anu CURSOR FOR SELECT * FROM tmp_anu ORDER BY 4
LET genero = 0
FOREACH q_anu INTO r_anu.*
	LET registro = registro CLIPPED, '\t<detalleAnulados>\n',
  			'\t\t<tipoComprobante>', r_anu.comp USING "&&",
			'</tipoComprobante>\n',
			'\t\t<establecimiento>', r_anu.punto CLIPPED,'</establecimiento>\n',
			'\t\t<puntoEmision>', r_anu.estab CLIPPED, '</puntoEmision>\n',
			'\t\t<secuencialInicio>',r_anu.numini USING "&&&&&&&&&",
			'</secuencialInicio>\n',
			'\t\t<secuencialFin>', r_anu.numfin USING "&&&&&&&&&",
			'</secuencialFin>\n',
			'\t\t<autorizacion>', r_anu.autoriz CLIPPED, '</autorizacion>\n',
			'\t</detalleAnulados>'
	DISPLAY registro CLIPPED
	LET registro = ' '
	LET genero = 1
END FOREACH
IF genero THEN
	CALL fl_mostrar_mensaje('Anexo Anulados Generado OK.', 'info')
END IF

END FUNCTION

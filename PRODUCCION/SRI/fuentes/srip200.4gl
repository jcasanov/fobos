--------------------------------------------------------------------------------
-- Titulo              : srip200.4gl - Anexo Transaccional Ventas
-- Elaboracion         : 29-Ago-2006
-- Autor               : NPC
-- Formato de Ejecucion: fglrun srip200 base módulo compañía localidad
--			             [fec_ini] [fec_fin] [[flag_xml]]
-- Ultima Correccion   : 
-- Motivo Correccion   : 
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
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 7 THEN
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
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 10
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_srip200 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_srif200_1 FROM "../forms/srif200_1"
ELSE
	OPEN FORM f_srif200_1 FROM "../forms/srif200_1c"
END IF
DISPLAY FORM f_srif200_1
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
CALL control_generar_archivo()

END FUNCTION



FUNCTION control_generar_archivo()

WHILE TRUE
	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_par.fecha_ini = arg_val(5)
		LET rm_par.fecha_fin = arg_val(6)
		DISPLAY BY NAME rm_par.*
	END IF
	CASE num_args()
		WHEN 6 CALL generar_archivo()
		WHEN 7 CALL generar_archivo_venta_xml()
	END CASE
	IF num_args() <> 4 THEN
		EXIT WHILE
	END IF
END WHILE

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
LET query = 'SELECT tipo_doc_id, cedruc, ',
				'CASE WHEN LENGTH(cedruc) = 13 AND ',
							'codcli <> ', rm_r00.r00_codcli_tal, ' ',
					'THEN cod_tran ',
					'ELSE "NV" ',
				'END cod_tran, ',
				'fecha_vta, porc_impto, ',
				'NVL(SUM(valor_vta_civa), 0) valor_vta_civa, ',
				'NVL(SUM(valor_vta_siva), 0) valor_vta_siva, ',
				'NVL(SUM(valor_iva), 0) valor_iva, ',
				'NVL(SUM(r19_flete), 0) flete, "00000" concepto, ',
				'1111111.11 base_rent, 111.11 porc_rent, 1111111.11 monto_ret ',
			' FROM tmp_fact ',
			' GROUP BY 1, 2, 3, 4, 5, 10, 11, 12, 13 ',
			' INTO TEMP tmp_anexo'
PREPARE cons_tmp_anexo FROM query 
EXECUTE cons_tmp_anexo
SELECT cedruc doccli, cod_tran c_tran, num_tran n_tran, COUNT(*) cuantos
	FROM tmp_fact
	GROUP BY 1, 2, 3
	INTO TEMP tmp_tot
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
				'     WHEN z01_tipo_doc_id = "C" AND ',
							' t23_cod_cliente <> ', rm_r00.r00_codcli_tal, ' ',
					'THEN "C" ',
					'ELSE "F" ',
				'END tipo_doc_id, ',
				'CASE WHEN (z01_tipo_doc_id = "R" OR z01_tipo_doc_id = "C") AND ',
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
IF num_args() = 8 THEN
	RETURN
END IF
DELETE FROM tmp_tal
	WHERE t23_estado = 'D'
	  AND num_tran   =
			(SELECT num_anu
				FROM t2
				WHERE num_anu = num_tran)
DROP TABLE t2
SELECT tipo_doc_id tipo_doc_tal, cedruc cedruc_tal,
		NVL(SUM(t23_val_impto), 0) val_ser_tal,
		NVL(SUM(valor_tal_civa), 0) valor_tal_civa,
		NVL(SUM(valor_tal_siva), 0) valor_tal_siva
	FROM tmp_tal
	GROUP BY 1, 2
	INTO TEMP tmp_tot_ser
SELECT tipo_doc_id tipo_doc_tal, cedruc cedruc_tal, COUNT(*) cuantos_tal
	FROM tmp_tal
	GROUP BY 1, 2
	INTO TEMP tmp_tot_tal
DECLARE q_tal CURSOR FOR
	SELECT * FROM tmp_tot_ser 
FOREACH q_tal INTO r_tal.*
	DECLARE q_tal_a CURSOR FOR
		SELECT * FROM tmp_anexo
			WHERE tipo_doc_id = r_tal.z01_tipo_doc_id
			  AND cedruc      = r_tal.z01_num_doc_id
	OPEN q_tal_a
	FETCH q_tal_a
	IF STATUS <> NOTFOUND THEN
		UPDATE tmp_anexo
			SET valor_vta_civa = valor_vta_civa + r_tal.val_ci,
			    valor_vta_siva = valor_vta_siva + r_tal.val_si
			WHERE tipo_doc_id = r_tal.z01_tipo_doc_id
			  AND cedruc      = r_tal.z01_num_doc_id
		CLOSE q_tal_a
		FREE q_tal_a
		CONTINUE FOREACH
	END IF
	CLOSE q_tal_a
	FREE q_tal_a
	LET porc_imp = 0
	IF r_tal.val_si = 0 THEN
		LET porc_imp = rg_gen.g00_porc_impto
	END IF
	INSERT INTO tmp_anexo
		VALUES (r_tal.z01_tipo_doc_id, r_tal.z01_num_doc_id, "FA",
				rm_par.fecha_fin, porc_imp, r_tal.val_ci, r_tal.val_si, 
				0.00, 0.00, '000', 0, 0, 0)
END FOREACH
CALL obtener_retenciones()

{* tmp_tot_ret: *}
LET query = 'SELECT CASE WHEN (tipo_doc_id = "R" OR tipo_doc_id = "C") AND ',
							'codcli <> ', rm_r00.r00_codcli_tal, ' ',
						'THEN cedruc ',
						'ELSE "9999999999999" ',
					'END cedruc_ret, cod_concep, base_imponible, val_porc, ',
				'NVL(SUM(valor_reten), 0) valor_reten ',
			'FROM tmp_ret ',
			'WHERE j14_tipo_ret = "F" ',
			'GROUP BY 1, 2, 3, 4 ',
			'INTO TEMP tmp_ret_tot '
PREPARE exec_ret_tot FROM query
EXECUTE exec_ret_tot
UPDATE tmp_ret_tot
	SET cod_concep     = '000',
	    base_imponible = 0.00,
	    val_porc       = 0.00
	WHERE valor_reten = 0 
DROP TABLE tmp_ret
UPDATE tmp_tot
	SET cuantos =
			(SELECT cuantos_tal
				FROM tmp_tot_tal
				WHERE cedruc_tal = doccli)
	WHERE EXISTS
		(SELECT cedruc_tal
			FROM tmp_tot_tal
			WHERE cedruc_tal = doccli)
	  AND c_tran = "FA"
DROP TABLE tmp_tot_tal
LET query = 'SELECT CASE WHEN LENGTH(z01_num_doc_id) = 13 ',
						'THEN "R" ',
					' WHEN LENGTH(z01_num_doc_id) = 10 ',
						'THEN "C" ',
						'ELSE "F" ',
					'END z01_tipo_doc_id, z01_num_doc_id, z21_codcli, ',
				'z21_tipo_doc, z21_num_doc, z21_valor, ',
				'CASE WHEN z21_val_impto > 0 ',
					'THEN ', rg_gen.g00_porc_impto, ' ',
					'ELSE 0.00 ',
				'END porc, ',
				'z21_val_impto, z21_cod_tran, z21_num_tran, z21_areaneg, ',
				'"', rm_par.fecha_fin, '" z21_fecha_emi, z21_localidad ',
			'FROM cxct021, cxct001 ',
			'WHERE z21_compania   = ', vg_codcia,
			'  AND z21_tipo_doc   = "NC" ',
			'  AND z21_fecha_emi  BETWEEN "', rm_par.fecha_ini,
								   '" AND "', rm_par.fecha_fin, '"',
			'  AND z01_codcli     = z21_codcli ',
			'INTO TEMP tmp_fav '
PREPARE cons_tmp_fav FROM query 
EXECUTE cons_tmp_fav
CALL obtener_fact_dev_nc('tmp_fav')
UPDATE tmp_fav
	SET z01_tipo_doc_id =
				(SELECT b.z01_tipo_doc_id
				FROM tmp_ncdf b
				WHERE b.num_doc      = z21_num_doc
				  AND b.z21_cod_tran = z21_cod_tran
				  AND b.z21_num_tran = z21_num_tran),
	    z01_num_doc_id  =
				(SELECT b.z01_num_doc_id
				FROM tmp_ncdf b
				WHERE b.num_doc      = z21_num_doc
				  AND b.z21_cod_tran = z21_cod_tran
				  AND b.z21_num_tran = z21_num_tran)
	WHERE EXISTS
		(SELECT a.z21_tipo_doc, a.num_doc, a.z21_cod_tran, a.z21_num_tran
			FROM tmp_ncdf a
			WHERE a.z21_tipo_doc = z21_tipo_doc
			  AND a.num_doc      = z21_num_doc
			  AND a.z21_cod_tran = z21_cod_tran
			  AND a.z21_num_tran = z21_num_tran)
	  AND z21_areaneg = 1
DROP TABLE tmp_ncdf
LET query = 'SELECT UNIQUE z01_tipo_doc_id, z01_num_doc_id, z21_tipo_doc, ',
		' z21_num_doc, z21_fecha_emi, porc, ',
		' CASE WHEN porc = ', rg_gen.g00_porc_impto,
			' THEN z21_valor - z21_val_impto ',
			' ELSE 0.00 ',
		' END valor_civa, ',
		' CASE WHEN porc <> ', rg_gen.g00_porc_impto,
			' THEN z21_valor ',
			' ELSE 0.00 ',
		' END valor_siva, ',
		' z21_val_impto, 0.00 flete_nc ',
		' FROM tmp_fav ',
		' INTO TEMP tmp_nc '
PREPARE cons_tmp_nc FROM query 
EXECUTE cons_tmp_nc
DROP TABLE tmp_fav
{-- SE QUITA HASTA CONFIRMAR QUE PUEDE PONERSE UN NUMERO DE CEDULA
UPDATE tmp_nc
	SET z01_num_doc_id = "9999999999999"
	WHERE LENGTH(z01_num_doc_id) = 10
	  AND z01_tipo_doc_id        = "F"
--}
INSERT INTO tmp_anexo
	SELECT z01_tipo_doc_id, z01_num_doc_id, z21_tipo_doc, z21_fecha_emi,
		0.00, NVL(SUM(valor_civa), 0), NVL(SUM(valor_siva), 0),
		NVL(SUM(z21_val_impto), 0), NVL(SUM(flete_nc), 0),'000', 0, 0, 0
		FROM tmp_nc
		GROUP BY 1, 2, 3, 4, 5, 10, 11, 12, 13
INSERT INTO tmp_tot
	SELECT z01_num_doc_id, z21_tipo_doc, z21_num_doc, COUNT(*)
		FROM tmp_nc
		GROUP BY 1, 2, 3
UPDATE tmp_anexo
	SET porc_impto = rg_gen.g00_porc_impto
	WHERE EXISTS
		(SELECT z01_tipo_doc_id, z01_num_doc_id, z21_tipo_doc, z21_fecha_emi
			FROM tmp_nc
			WHERE tipo_doc_id = z01_tipo_doc_id
			  AND cedruc      = z01_num_doc_id
			  AND cod_tran    = z21_tipo_doc
			  AND fecha_vta   = z21_fecha_emi)
DROP TABLE tmp_nc
LET query = 'SELECT CASE WHEN LENGTH(z01_num_doc_id) = 13 ',
						'THEN "R" ',
					' WHEN LENGTH(z01_num_doc_id) = 10 ',
						'THEN "C" ',
						'ELSE "F" ',
					'END z01_tipo_doc_id, z01_num_doc_id, z20_tipo_doc, ',
				' z20_num_doc, "', rm_par.fecha_fin, '" z20_fecha_emi, ',
			' CASE WHEN z20_val_impto > 0 ',
				' THEN ', rg_gen.g00_porc_impto,
				' ELSE 0.00 ',
			' END porc, ',
			' CASE WHEN z20_val_impto > 0 ',
				' THEN (z20_valor_cap + z20_valor_int) - z20_val_impto',
				' ELSE 0.00 ',
			' END valor_civa, ',
			' CASE WHEN z20_val_impto = 0 ',
				' THEN (z20_valor_cap + z20_valor_int) ',
				' ELSE 0.00 ',
			' END valor_siva, ',
			' z20_val_impto, 0.00 flete_nd ',
		' FROM cxct020, cxct001 ',
		' WHERE z20_compania   = ', vg_codcia,
		'   AND z20_tipo_doc   = "ND" ',
		'   AND z20_fecha_emi  BETWEEN "', rm_par.fecha_ini,
					'" AND "', rm_par.fecha_fin, '"',
		'   AND z01_codcli     = z20_codcli ',
		' INTO TEMP tmp_nd '
PREPARE cons_tmp_nd FROM query 
EXECUTE cons_tmp_nd
{-- SE QUITA HASTA CONFIRMAR QUE PUEDE PONERSE UN NUMERO DE CEDULA
UPDATE tmp_nd
	SET z01_num_doc_id = "9999999999999"
	WHERE LENGTH(z01_num_doc_id) = 10
	  AND z01_tipo_doc_id        = "F"
--}
INSERT INTO tmp_anexo
	SELECT z01_tipo_doc_id, z01_num_doc_id, z20_tipo_doc, z20_fecha_emi,
		0.00, NVL(SUM(valor_civa), 0), NVL(SUM(valor_siva), 0),
		NVL(SUM(z20_val_impto), 0), NVL(SUM(flete_nd), 0),'000', 0, 0, 0
		FROM tmp_nd
		GROUP BY 1, 2, 3, 4, 5, 10, 11, 12, 13
INSERT INTO tmp_tot
	SELECT z01_num_doc_id, z20_tipo_doc, z20_num_doc, COUNT(*)
		FROM tmp_nd
		GROUP BY 1, 2, 3
UPDATE tmp_anexo
	SET porc_impto = rg_gen.g00_porc_impto
	WHERE EXISTS (SELECT z01_tipo_doc_id, z01_num_doc_id, z20_tipo_doc,
				z20_fecha_emi
			FROM tmp_nd
			WHERE tipo_doc_id = z01_tipo_doc_id
			  AND cedruc      = z01_num_doc_id
			  AND cod_tran    = z20_tipo_doc
			  AND fecha_vta   = z20_fecha_emi
			GROUP BY 1, 2, 3, 4)
DROP TABLE tmp_nd
SELECT doccli, c_tran, COUNT(*) cuantos
	FROM tmp_tot
	GROUP BY 1, 2
	INTO TEMP tmp_tot_f
DROP TABLE tmp_tot
UPDATE tmp_anexo
	SET concepto  = "000",
	    base_rent = 0.00,
	    porc_rent = 0.00,
	    monto_ret = 0.00
	WHERE 1 = 1
UPDATE tmp_anexo
	SET concepto  = (SELECT NVL(cod_concep, "000") FROM tmp_ret_tot
				WHERE cedruc_ret = cedruc),
	    base_rent = (SELECT NVL(base_imponible, 0.00) FROM tmp_ret_tot
				WHERE cedruc_ret = cedruc),
	    porc_rent = (SELECT NVL(val_porc, 0.00) FROM tmp_ret_tot
				WHERE cedruc_ret = cedruc),
	    monto_ret = (SELECT NVL(valor_reten, 0.00) FROM tmp_ret_tot
				WHERE cedruc_ret = cedruc)
	WHERE cedruc   = (SELECT cedruc_ret FROM tmp_ret_tot
				WHERE cedruc_ret = cedruc)
	  AND cod_tran IN ('FA', 'NV')
DROP TABLE tmp_ret_tot
LET query = 'SELECT UNIQUE (SELECT s18_sec_tran ',
		' FROM srit018 ',
		' WHERE s18_compania  = ', vg_codcia,
		'   AND s18_cod_ident = tipo_doc_id ',
		'   AND s18_tipo_tran = ', vm_tip_anexo, ') tipo_id, cedruc, ',
		' (SELECT s04_codigo FROM srit019, srit004 ',
			' WHERE s19_compania  = ', vg_codcia,
			'   AND s19_sec_tran  = ',
                        ' (SELECT s18_sec_tran FROM srit018 ',
                                ' WHERE s18_compania  = ', vg_codcia,
                                '   AND s18_cod_ident = tipo_doc_id ',
                                '   AND s18_tipo_tran = ', vm_tip_anexo, ') ',
			'  AND s19_cod_ident = tipo_doc_id ',
			'  AND s19_tipo_doc  = cod_tran ',
			'  AND s04_compania  = s19_compania ',
			'  AND s04_codigo    = s19_tipo_comp) tipo_comp, ',
		' fecha_vta fecha_cont, ',
		' NVL((SELECT cuantos FROM tmp_tot_f ',
		' WHERE doccli = cedruc AND c_tran = cod_tran), 1) num_comp, ',
		' fecha_vta, valor_vta_siva + flete base_imp, "N" iva_pre, ',
		' valor_vta_civa, ',
		' (SELECT s08_codigo FROM srit008 ',
			' WHERE s08_compania   = ', vg_codcia,
			'   AND s08_porcentaje = porc_impto) cod_por_iva, ',
		' valor_iva + ',
		' CASE WHEN (SELECT s04_codigo FROM srit019, srit004 ',
			' WHERE s19_compania  = ', vg_codcia,
			'   AND s19_sec_tran  = ',
			' (SELECT s18_sec_tran FROM srit018 ',
				' WHERE s18_compania  = ', vg_codcia,
				'   AND s18_cod_ident = tipo_doc_id ',
				'   AND s18_tipo_tran = ', vm_tip_anexo, ') ',
			'   AND s19_cod_ident = tipo_doc_id ',
			'   AND s19_tipo_doc  = cod_tran ',
			'   AND s04_compania  = s19_compania ',
			'   AND s04_codigo    = s19_tipo_comp) = 18 THEN ',
			' NVL((SELECT val_ser_tal FROM tmp_tot_ser ',
				' WHERE cedruc_tal   = cedruc ',
				'   AND tipo_doc_tal = tipo_doc_id), 0) ',
				' ELSE 0.00 ',
			' END valor_iva, ',
		' 0.00 base_ice, 0.00 cod_por_ice, 0.00 monto_ice, ',
		' 0.00 monto_iva_bie, ',
		' (SELECT s09_codigo FROM srit009 ',
			' WHERE s09_compania  = ', vg_codcia,
			'   AND s09_codigo    = 0 ',
			'   AND s09_tipo_porc = "B") cod_por_bie, ',
		' 0.00 monto_ret_iva_bie, ',
		' 0.00 monto_iva_ser, "0" cod_ret_ser, ',
		' 0.00 monto_ret_iva_ser, ',
		' "N" ret_pre, concepto, base_rent, porc_rent, monto_ret ',
		' FROM tmp_anexo ',
		' INTO TEMP tmp_s21 '
PREPARE exec_anexo FROM query
EXECUTE exec_anexo
DROP TABLE tmp_fact
DROP TABLE tmp_anexo
DROP TABLE tmp_tot_ser
DROP TABLE tmp_tot_f
LET query = 'DELETE FROM srit021 ',
		' WHERE s21_compania  = ', vg_codcia,
		'   AND s21_localidad = ', vg_codloc,
		'   AND s21_anio      = ', YEAR(rm_par.fecha_fin),
		'   AND s21_mes       = ', MONTH(rm_par.fecha_fin)
PREPARE cons_del FROM query
EXECUTE cons_del
LET query = 'SELECT tipo_id, cedruc, tipo_comp, fecha_cont, num_comp, ',
		' fecha_vta, base_imp, iva_pre, valor_vta_civa, cod_por_iva, ',
		' valor_iva, base_ice, cod_por_ice, monto_ice, monto_iva_bie, ',
		' cod_por_bie, monto_ret_iva_bie, monto_iva_ser, cod_ret_ser, ',
		' monto_ret_iva_ser, ret_pre ',
		' FROM tmp_s21 ',
		' WHERE cedruc    = "9999999999999" ',
		'   AND tipo_comp = 18 ',
		' INTO TEMP tmp_cli_fal '
PREPARE cons_cli_fal FROM query
EXECUTE cons_cli_fal
INITIALIZE valor_siva_aux TO NULL
SELECT base_imp INTO valor_siva_aux
	FROM tmp_s21
	WHERE cedruc    = '9999999999999'
	  AND tipo_comp = '18'
	  AND base_imp  > 0
SELECT COUNT(*) INTO ctos
	FROM tmp_s21
	WHERE cedruc    = '9999999999999'
	  AND tipo_comp = '18'
IF valor_siva_aux IS NOT NULL AND ctos > 1 THEN
	DELETE FROM tmp_s21
		WHERE cedruc         = '9999999999999'
		  AND tipo_comp      = '18'
		  AND base_imp       > 0
		  AND valor_vta_civa = 0
	UPDATE tmp_s21
		SET base_imp = NVL(base_imp, 0) + valor_siva_aux
		WHERE cedruc    = '9999999999999'
		  AND tipo_comp = '18'
END IF
LET query = 'INSERT INTO srit021 ',
		' (s21_compania, s21_localidad, s21_anio, s21_mes,',
		'  s21_ident_cli, s21_num_doc_id, s21_tipo_comp,',
		'  s21_fecha_reg_cont, s21_num_comp_emi, s21_fecha_emi_vta,',
		'  s21_base_imp_tar_0, s21_iva_presuntivo, s21_bas_imp_gr_iva,',
		'  s21_cod_porc_iva, s21_monto_iva, s21_base_imp_ice,',
		'  s21_cod_porc_ice, s21_monto_ice, s21_monto_iva_bie,',
		'  s21_cod_ret_ivabie, s21_mon_ret_ivabie, s21_monto_iva_ser,',
		'  s21_cod_ret_ivaser, s21_mon_ret_ivaser, s21_ret_presuntivo,',
		'  s21_concepto_ret, s21_base_imp_renta, s21_porc_ret_renta,',
		'  s21_monto_ret_rent, s21_estado, s21_usuario, s21_fecing) ',
		' SELECT ', vg_codcia, ', ', vg_codloc, ', ',
			YEAR(rm_par.fecha_fin), ', ', MONTH(rm_par.fecha_fin),
			', tipo_id, cedruc, LPAD(tipo_comp, 2, 0), fecha_cont, num_comp, ',
			' fecha_vta, base_imp, iva_pre, SUM(valor_vta_civa), ',
			' cod_por_iva, SUM(valor_iva), base_ice, cod_por_ice, ',
			' monto_ice, monto_iva_bie, cod_por_bie, ',
			' monto_ret_iva_bie, monto_iva_ser, cod_ret_ser, ',
			' monto_ret_iva_ser, ret_pre, concepto, base_rent, ',
			' porc_rent, monto_ret, "G", "',
			UPSHIFT(vg_usuario) CLIPPED, '", "', fl_current(), '" ',
			' FROM tmp_s21 ',
			' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14,',
				' 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,',
				' 27, 28, 29, 30, 31, 32 '
PREPARE cons_s21 FROM query
EXECUTE cons_s21
DROP TABLE tmp_s21
UPDATE tmp_cli_fal
	SET num_comp          = 0,
	    base_imp          = 0.00,
	    valor_vta_civa    = 0.00,
	    valor_iva         = 0.00,
	    base_ice          = 0.00,
	    monto_ice         = 0.00,
	    monto_iva_bie     = 0.00,
	    monto_ret_iva_bie = 0.00,
	    monto_iva_ser     = 0.00,
	    monto_ret_iva_ser = 0.00
	WHERE 1 = 1
SELECT tmp_cli_fal.*,
		(SELECT s18_sec_tran FROM srit018
			WHERE s18_compania  = vg_codcia
			  AND s18_cod_ident = 'F'
			  AND s18_tipo_tran = vm_tip_anexo) tipo_id_fin,
	s21_compania s21_cia, s21_localidad s21_loc, s21_anio s21_ano,
	s21_mes s21_m, s21_ident_cli s21_id_cl, s21_num_doc_id s21_num_id,
	s21_tipo_comp s21_tp
	FROM tmp_cli_fal, OUTER srit021
	WHERE s21_compania   = vg_codcia
	  AND s21_localidad  = vg_codloc
	  AND s21_anio       = YEAR(rm_par.fecha_fin)
	  AND s21_mes        = MONTH(rm_par.fecha_fin)
	  AND s21_ident_cli  =
			(SELECT s18_sec_tran FROM srit018
				WHERE s18_compania  = vg_codcia
				  AND s18_cod_ident = 'F'
				  AND s18_tipo_tran = vm_tip_anexo)
	  AND s21_num_doc_id = cedruc
	  AND s21_tipo_comp  = tipo_comp
	INTO TEMP tmp_faltantes
LET query = 'INSERT INTO srit021 ',
		' (s21_compania, s21_localidad, s21_anio, s21_mes,',
		'  s21_ident_cli, s21_num_doc_id, s21_tipo_comp,',
		'  s21_fecha_reg_cont, s21_num_comp_emi, s21_fecha_emi_vta,',
		'  s21_base_imp_tar_0, s21_iva_presuntivo, s21_bas_imp_gr_iva,',
		'  s21_cod_porc_iva, s21_monto_iva, s21_base_imp_ice,',
		'  s21_cod_porc_ice, s21_monto_ice, s21_monto_iva_bie,',
		'  s21_cod_ret_ivabie, s21_mon_ret_ivabie, s21_monto_iva_ser,',
		'  s21_cod_ret_ivaser, s21_mon_ret_ivaser, s21_ret_presuntivo,',
		'  s21_concepto_ret, s21_base_imp_renta, s21_porc_ret_renta,',
		'  s21_monto_ret_rent, s21_estado, s21_usuario, s21_fecing) ',
		' SELECT UNIQUE ', vg_codcia, ', ', vg_codloc, ', ',
			YEAR(rm_par.fecha_fin), ', ', MONTH(rm_par.fecha_fin),
		', tipo_id_fin, ',
		' cedruc, LPAD(tipo_comp, 2, 0), fecha_cont, num_comp, fecha_vta,',
		' base_imp, iva_pre, valor_vta_civa, cod_por_iva, valor_iva,',
		' base_ice, cod_por_ice,monto_ice, monto_iva_bie, cod_por_bie,',
		' monto_ret_iva_bie, monto_iva_ser, cod_ret_ser,',
		' monto_ret_iva_ser, ret_pre, "000", 0.00, 0.00, 0.00, "G", "',
		UPSHIFT(vg_usuario) CLIPPED,
		'", CURRENT ',
		' FROM tmp_faltantes ',
		' WHERE s21_cia IS NULL '
PREPARE cons_s21_2 FROM query
EXECUTE cons_s21_2
DROP TABLE tmp_cli_fal
DROP TABLE tmp_faltantes
CALL verificacion_retenciones_negativas()

END FUNCTION



{**
	OBTIENE LAS FACTURAS DE INVENTARIO: rept019
**}

FUNCTION obtener_facturas()
DEFINE query		VARCHAR(4000)

LET query = 'SELECT r19_codcli codcli, ',
		'CASE WHEN (LENGTH(r19_cedruc) = 13 OR LENGTH(r19_cedruc) = 10) AND ',
			' r19_codcli <> ', rm_r00.r00_codcli_tal,
			'THEN r19_cod_tran ',
			'ELSE "NV" ',
		'END cod_tran, ',
		'r19_num_tran num_tran, r19_tipo_dev tipo_dev, ',
		'r19_num_dev num_dev, ',
		'CASE WHEN LENGTH(r19_cedruc) = 13 AND ',
			' r19_codcli <> ', rm_r00.r00_codcli_tal,
			'THEN "R" ',
		'     WHEN LENGTH(r19_cedruc) = 10 AND ',
			' r19_codcli <> ', rm_r00.r00_codcli_tal,
			'THEN "C" ',
			'ELSE "F" ',
		'END tipo_doc_id, ',
		'CASE WHEN (LENGTH(r19_cedruc) = 13 OR LENGTH(r19_cedruc) = 10) AND ',
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
	OBTIENE LAS N/C Y DEVOLUCIONES DE INVENTARIO
**}

FUNCTION obtener_fact_dev_nc(tabla)
DEFINE tabla		VARCHAR(15)
DEFINE query		VARCHAR(3000)

LET query = 'SELECT CASE WHEN (SELECT LENGTH(a.r19_cedruc) ',
				'FROM rept019 a ',
				'WHERE a.r19_compania  = b.r19_compania ',
				'  AND a.r19_localidad = b.r19_localidad ',
				'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
				'  AND a.r19_num_tran  = b.r19_num_dev) = 13',
			' THEN "R" ',
			' WHEN (SELECT LENGTH(a.r19_cedruc) ',
				'FROM rept019 a ',
				'WHERE a.r19_compania  = b.r19_compania ',
				'  AND a.r19_localidad = b.r19_localidad ',
				'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
				'  AND a.r19_num_tran  = b.r19_num_dev) = 10',
			' THEN "C" ',
			' ELSE "F" ',
			' END z01_tipo_doc_id, ',
		' CASE WHEN (SELECT LENGTH(a.r19_cedruc) ',
				'FROM rept019 a ',
				'WHERE a.r19_compania  = b.r19_compania ',
				'  AND a.r19_localidad = b.r19_localidad ',
				'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
				'  AND a.r19_num_tran  = b.r19_num_dev) IN (10, 13)',
			' THEN z01_num_doc_id ',
			' ELSE "9999999999999" ',
			' END z01_num_doc_id, z21_codcli, z21_tipo_doc,',
		' z21_num_doc num_doc, z21_valor, z21_val_impto, z21_cod_tran,',
		' z21_num_tran, z21_areaneg, z21_fecha_emi ',
		' FROM ', tabla CLIPPED, ', rept019 b ',
		' WHERE z21_areaneg     = 1 ',
		'   AND b.r19_compania  = ', vg_codcia,
		'   AND b.r19_localidad = z21_localidad ',
		'   AND b.r19_cod_tran  = z21_cod_tran ',
		'   AND b.r19_num_tran  = z21_num_tran ',
		' INTO TEMP tmp_ncdf '
PREPARE cons_tmp_ncdf FROM query 
EXECUTE cons_tmp_ncdf

END FUNCTION



{**
	OBTIENE LAS RETENCIONES DE LAS FACTURAS DE CLIENTES
    XXX - en la fuente y de iva?
**}

FUNCTION obtener_retenciones()

SELECT codcli, tipo_doc_id, cedruc, j14_codigo_sri AS cod_concep,
		SUM(j14_base_imp) AS base_imponible, j14_porc_ret AS val_porc, j14_tipo_ret, 
		SUM(j14_valor_ret) AS valor_reten
		FROM tmp_fact, cajt014
		WHERE j14_cedruc   = cedruc
		  AND j14_tipo_fue = "PR"
          AND j14_cod_tran = cod_tran 
          AND j14_num_tran = num_tran 
		GROUP BY 1, 2, 3, 4, 6, 7
UNION
SELECT codcli, tipo_doc_id, cedruc, j14_codigo_sri AS cod_concep,
		SUM(j14_base_imp) AS base_imponible, j14_porc_ret AS val_porc, j14_tipo_ret,
		SUM(j14_valor_ret) AS valor_reten
		FROM tmp_tal, cajt014
		WHERE j14_cedruc   = cedruc
		  AND j14_tipo_fue = "OT"
          AND j14_cod_tran = "FA"
          AND j14_num_tran = num_tran 
		GROUP BY 1, 2, 3, 4, 6, 7
	INTO TEMP tmp_ret

DROP TABLE tmp_tal

END FUNCTION



FUNCTION lee_parametros()
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN 
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > vm_fin_mes THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la fecha fin de mes.','exclamation')
				NEXT FIELD fecha_ini
			END IF
			LET rm_par.fecha_fin = rm_par.fecha_ini + 1 UNITS MONTH
						- 1 UNITS DAY
			DISPLAY BY NAME rm_par.fecha_fin
		ELSE
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > vm_fin_mes THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la fecha fin de mes.','exclamation')
				NEXT FIELD fecha_fin
			END IF
		ELSE
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.fecha_ini > vm_fin_mes THEN
			CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la fecha fin de mes.','exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.fecha_fin > vm_fin_mes THEN
			CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la fecha fin de mes.','exclamation')
			NEXT FIELD fecha_fin
		END IF
END INPUT

END FUNCTION



FUNCTION verificacion_retenciones_negativas()

SELECT * FROM srit021
	WHERE s21_compania       = vg_codcia
	  AND s21_localidad      = vg_codloc
	  AND s21_anio           = YEAR(rm_par.fecha_fin)
	  AND s21_mes            = MONTH(rm_par.fecha_fin)
	  AND s21_monto_ret_rent < 0
	 INTO TEMP t1
DELETE FROM srit021
	WHERE EXISTS
		(SELECT t1.s21_tipo_comp FROM t1
		WHERE srit021.s21_compania       = t1.s21_compania
		  AND srit021.s21_localidad      = t1.s21_localidad
		  AND srit021.s21_anio           = t1.s21_anio
		  AND srit021.s21_mes            = t1.s21_mes
		  AND srit021.s21_ident_cli      = t1.s21_ident_cli
		  AND srit021.s21_num_doc_id     = t1.s21_num_doc_id
		  AND srit021.s21_tipo_comp      = t1.s21_tipo_comp
		  AND srit021.s21_base_imp_tar_0 = 0.00
		  AND srit021.s21_bas_imp_gr_iva = 0.00
		  AND srit021.s21_monto_iva      = 0.00)
UPDATE t1
	SET s21_tipo_comp      = '04',
	    s21_base_imp_tar_0 = 0.00,
	    s21_bas_imp_gr_iva = 0.00,
	    s21_monto_iva      = 0.00,
	    s21_base_imp_renta = s21_base_imp_renta * (-1),
	    s21_monto_ret_rent = s21_monto_ret_rent * (-1)
	WHERE 1 = 1
INSERT INTO srit021
	SELECT * FROM t1
		WHERE NOT EXISTS
			(SELECT 1 FROM srit021 a
				WHERE a.s21_compania   = t1.s21_compania
				  AND a.s21_localidad  = t1.s21_localidad
				  AND a.s21_anio       = t1.s21_anio
				  AND a.s21_mes        = t1.s21_mes
				  AND a.s21_ident_cli  = t1.s21_ident_cli
				  AND a.s21_num_doc_id = t1.s21_num_doc_id
				  AND a.s21_tipo_comp  = t1.s21_tipo_comp)
UPDATE srit021
	SET s21_concepto_ret   = (SELECT s21_concepto_ret FROM t1
				WHERE srit021.s21_compania   = t1.s21_compania
				  AND srit021.s21_localidad  = t1.s21_localidad
				  AND srit021.s21_anio       = t1.s21_anio
				  AND srit021.s21_mes        = t1.s21_mes
				  AND srit021.s21_ident_cli  = t1.s21_ident_cli
				  AND srit021.s21_num_doc_id = t1.s21_num_doc_id
				 AND srit021.s21_tipo_comp  = t1.s21_tipo_comp),
	    s21_base_imp_renta = (SELECT s21_base_imp_renta FROM t1
				WHERE srit021.s21_compania   = t1.s21_compania
				  AND srit021.s21_localidad  = t1.s21_localidad
				  AND srit021.s21_anio       = t1.s21_anio
				  AND srit021.s21_mes        = t1.s21_mes
				  AND srit021.s21_ident_cli  = t1.s21_ident_cli
				  AND srit021.s21_num_doc_id = t1.s21_num_doc_id
				 AND srit021.s21_tipo_comp  = t1.s21_tipo_comp),
	    s21_porc_ret_renta = (SELECT s21_porc_ret_renta FROM t1
				WHERE srit021.s21_compania   = t1.s21_compania
				  AND srit021.s21_localidad  = t1.s21_localidad
				  AND srit021.s21_anio       = t1.s21_anio
				  AND srit021.s21_mes        = t1.s21_mes
				  AND srit021.s21_ident_cli  = t1.s21_ident_cli
				  AND srit021.s21_num_doc_id = t1.s21_num_doc_id
				 AND srit021.s21_tipo_comp  = t1.s21_tipo_comp),
	    s21_monto_ret_rent = (SELECT s21_monto_ret_rent FROM t1
				WHERE srit021.s21_compania   = t1.s21_compania
				  AND srit021.s21_localidad  = t1.s21_localidad
				  AND srit021.s21_anio       = t1.s21_anio
				  AND srit021.s21_mes        = t1.s21_mes
				  AND srit021.s21_ident_cli  = t1.s21_ident_cli
				  AND srit021.s21_num_doc_id = t1.s21_num_doc_id
				 AND srit021.s21_tipo_comp  = t1.s21_tipo_comp)
	WHERE EXISTS
		(SELECT 1 FROM t1
		WHERE srit021.s21_compania   = t1.s21_compania
		  AND srit021.s21_localidad  = t1.s21_localidad
		  AND srit021.s21_anio       = t1.s21_anio
		  AND srit021.s21_mes        = t1.s21_mes
		  AND srit021.s21_ident_cli  = t1.s21_ident_cli
		  AND srit021.s21_num_doc_id = t1.s21_num_doc_id
		  AND srit021.s21_tipo_comp  = t1.s21_tipo_comp)
UPDATE srit021
	SET s21_concepto_ret   = '000',
	    s21_base_imp_renta = 0.00,
	    s21_porc_ret_renta = 0.00,
	    s21_monto_ret_rent = 0.00
	WHERE s21_compania       = vg_codcia
	  AND s21_localidad      = vg_codloc
	  AND s21_anio           = YEAR(rm_par.fecha_fin)
	  AND s21_mes            = MONTH(rm_par.fecha_fin)
	  AND s21_monto_ret_rent < 0
DROP TABLE t1

END FUNCTION



{**
 * El anexo se genera según la ficha técnica del SRI que se encuentra en: 
 * http://descargas.sri.gob.ec/download/anexos/ats/FICHA_TECNICA_ATS_JULIO2016.pdf
 **}

FUNCTION generar_archivo_venta_xml()
DEFINE r_s21		RECORD LIKE srit021.*
DEFINE query		CHAR(800)
DEFINE registro		CHAR(4000)

DECLARE q_s21 CURSOR FOR 
	SELECT * FROM srit021
	WHERE s21_compania  = vg_codcia
	  AND s21_localidad = vg_codloc
	  AND s21_anio      = YEAR(rm_par.fecha_fin)
	  AND s21_mes       = MONTH(rm_par.fecha_fin)
FOREACH q_s21 INTO r_s21.*
	LET registro    = registro CLIPPED,
		'\t<detalleVentas>\n',
		'\t\t<tpIdCliente>', r_s21.s21_ident_cli, '</tpIdCliente>\n',
		'\t\t<idCliente>', r_s21.s21_num_doc_id CLIPPED, '</idCliente>\n',
		'\t\t<parteRelVtas>SI</parteRelVtas>\n',
		'\t\t<tipoComprobante>', r_s21.s21_tipo_comp USING "&&",
		'</tipoComprobante>\n',
		'\t\t<tipoEmision>F</tipoEmision>\n',
		'\t\t<numeroComprobantes>', r_s21.s21_num_comp_emi USING "<<<<<<",
		'</numeroComprobantes>\n',
		'\t\t<baseNoGraIva>', r_s21.s21_base_imp_tar_0 USING "<<<<<<<<<<<&.&&",
		'</baseNoGraIva>\n',
		{*
         * XXX 
		 * Este campo va por ahora en cero, pero se debe considerar tarifa 0%
         *}
		'\t\t<baseImponible>0.00</baseImponible>\n',
		'\t\t<baseImpGrav>', r_s21.s21_bas_imp_gr_iva USING "<<<<<<<<<<<&.&&",
		'</baseImpGrav>\n',
		'\t\t<montoIva>', r_s21.s21_monto_iva USING "<<<<<<<<<<<&.&&",
		'</montoIva>\n',
		--
		{*
		 * XXX
         * Etiquetas como <compensaciones> corresponden a funcionalidades que
		 * el sistema aún no tiene así que no aplican
		 *}
		'\t\t<montoIce>', r_s21.s21_monto_ice USING "<<<<<<<<<<<&.&&",
		'</montoIce>\n',
		'\t\t<valorRetIva>', r_s21.s21_mon_ret_ivabie USING "<<<<<<<<<<<&.&&",
		'</valorRetIva>\n',
		'\t\t<valorRetRenta>', r_s21.s21_monto_ret_rent USING "<<<<<<<<<<<&.&&",
		'</valorRetRenta>\n'
		{*
		 * XXX 
		 * Se debe crear la tabla srit026 con la tabla 13 de la ficha tecnica
		 * del SRI y relacionarla con la tabla cajt001.
		 *}
		IF r_s21.s21_tipo_comp <> 4 THEN
			LET registro = registro CLIPPED,
							'\t\t<formasDePago>\n',
							'\t\t\t<formaPago>20</formaPago>\n',
							'\t\t</formasDePago>\n'
		END IF
		LET registro = registro CLIPPED,
						'\t</detalleVentas>'
		DISPLAY registro CLIPPED
		LET registro = ' '
END FOREACH
CALL fl_mostrar_mensaje('Anexo de Ventas Generado OK.', 'info')

END FUNCTION

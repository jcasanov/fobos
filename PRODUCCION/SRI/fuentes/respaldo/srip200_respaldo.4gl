--------------------------------------------------------------------------------
-- Titulo           : srip200.4gl - Anexo Transaccional del Ventas
-- Elaboracion      : 29-Ago-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun srip200 base módulo compañía localidad
--			             [fec_ini] [fec_fin] [flag_xml]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par 		RECORD 
				fecha_ini	DATE,
				fecha_fin	DATE
			END RECORD
DEFINE rm_det 		RECORD
				fecha		DATE,
				t23_num_factura	LIKE talt023.t23_num_factura,
				t23_orden	LIKE talt023.t23_orden,
				t23_val_mo_tal	LIKE talt023.t23_val_mo_tal,
				tot_oc		DECIMAL(14,2),
				tot_fa		DECIMAL(14,2),
				tot_ot		DECIMAL(14,2),
				t23_estado	LIKE talt023.t23_estado
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE vm_fin_mes	DATE



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/srip200.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 AND num_args() <> 7 AND num_args() <> 8
THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'srip200'
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
LET num_rows   = 6
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
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No está creada una compañía para el módulo de inventarios.','stop')
	RETURN
END IF
INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini = MDY(MONTH(TODAY), 1, YEAR(TODAY))
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
		WHEN 8 CALL generar_archivo()
		       CALL generar_archivo_anula_xml()
	END CASE
	IF num_args() = 4 THEN
		CALL generar_archivo()
	END IF
	IF num_args() <> 4 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



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
DEFINE base_suc		VARCHAR(10)
DEFINE comando		VARCHAR(100)
DEFINE archivo		VARCHAR(50)
DEFINE resul		SMALLINT
DEFINE r_s21		RECORD LIKE srit021.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE porc_imp		LIKE gent000.g00_porc_impto
--define valor		integer
--define c		char(20)

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
CALL obtener_facturas(1)
SELECT * FROM t1 INTO TEMP tmp_fact
DROP TABLE t1
SELECT * FROM t3 INTO TEMP tmp_anu
DROP TABLE t3
IF vg_codcia = 1 AND (vg_codloc = 1 OR vg_codloc = 3) THEN
	CALL obtener_facturas(2)
	INSERT INTO tmp_fact SELECT * FROM t1
	DROP TABLE t1
	INSERT INTO tmp_anu SELECT * FROM t3
	DROP TABLE t3
END IF
{--
CALL obtener_devoluciones(1)
SELECT * FROM t1 INTO TEMP tmp_df
DROP TABLE t1
IF vg_codcia = 1 AND (vg_codloc = 1 OR vg_codloc = 3) THEN
	CALL obtener_devoluciones(2)
	INSERT INTO tmp_df SELECT * FROM t1
	DROP TABLE t1
END IF
SELECT tipo_df, num_df
	FROM tmp_fact, tmp_df
	WHERE tipo_df  = cod_tran
	  AND num_df   = num_tran
	  AND valor_df = (valor_vta_civa + valor_vta_siva)
	INTO TEMP tmp_elim
DROP TABLE tmp_df
DELETE FROM tmp_fact
	WHERE EXISTS (SELECT * FROM tmp_elim
			WHERE tipo_df = cod_tran
			  AND num_df  = num_tran)
DROP TABLE tmp_elim
--}
DECLARE q_verif CURSOR FOR
	SELECT codcli, cod_tran, num_tran, cedruc_v FROM tmp_fact
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
			' codcli <> ', rm_r00.r00_codcli_tal,
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
--select count(*) into valor from tmp_anexo where cedruc = '9999999999999'
--display 'en into temp ', valor
SELECT cedruc doccli, cod_tran c_tran, num_tran n_tran, COUNT(*) cuantos
	FROM tmp_fact
	GROUP BY 1, 2, 3
	INTO TEMP tmp_tot
LET query = 'SELECT t23_cod_cliente codcli, t23_num_factura num_tran, ',
		' CASE WHEN t23_val_impto > 0 THEN ',
		' t23_val_mo_tal + ',
		' CASE WHEN t23_estado = "F" THEN ',
			'(SELECT NVL(SUM((c11_precio - c11_val_descto)',
			' * (1 + c10_recargo / 100)), 0) ',
			' FROM ordt010, ordt011 ',
			' WHERE c10_compania    = t23_compania ',
			'   AND c10_localidad   = t23_localidad ',
			'   AND c10_ord_trabajo = t23_orden ',
			'   AND c10_estado      = "C" ',
			'   AND c11_compania    = c10_compania ',
			'   AND c11_localidad   = c10_localidad ',
			'   AND c11_numero_oc   = c10_numero_oc ',
			'   AND c11_tipo        = "S") + ',
			'(SELECT NVL(SUM(((c11_cant_ped * c11_precio)',
			' - c11_val_descto) * (1 + c10_recargo / 100))',
			', 0) ',
			' FROM ordt010, ordt011 ',
			' WHERE c10_compania    = t23_compania ',
			'   AND c10_localidad   = t23_localidad ',
			'   AND c10_ord_trabajo = t23_orden ',
			'   AND c10_estado      = "C" ',
			'   AND c11_compania    = c10_compania ',
			'   AND c11_localidad   = c10_localidad ',
			'   AND c11_numero_oc   = c10_numero_oc ',
			'   AND c11_tipo        = "B") + ',
			' CASE WHEN (SELECT COUNT(*) FROM ordt010 ',
				' WHERE c10_compania    = t23_compania ',
				'   AND c10_localidad   = t23_localidad ',
				'   AND c10_ord_trabajo = t23_orden ',
				'   AND c10_estado      = "C") = 0 ',
			' THEN (t23_val_rp_tal + t23_val_rp_ext + ',
			       't23_val_rp_cti + t23_val_otros2) ',
			' ELSE 0.00 ',
			' END ',
		' ELSE (t23_val_mo_ext + t23_val_mo_cti + ',
			't23_val_rp_tal + t23_val_rp_ext + ',
			't23_val_rp_cti + t23_val_otros2) ',
		' END ',
		' ELSE 0.00 ',
		' END valor_tal_civa, ',
		' CASE WHEN t23_val_impto = 0 THEN ',
		' t23_val_mo_tal + ',
		' CASE WHEN t23_estado = "F" THEN ',
			'(SELECT NVL(SUM((c11_precio - c11_val_descto)',
			' * (1 + c10_recargo / 100)), 0) ',
			' FROM ordt010, ordt011 ',
			' WHERE c10_compania    = t23_compania ',
			'   AND c10_localidad   = t23_localidad ',
			'   AND c10_ord_trabajo = t23_orden ',
			'   AND c10_estado      = "C" ',
			'   AND c11_compania    = c10_compania ',
			'   AND c11_localidad   = c10_localidad ',
			'   AND c11_numero_oc   = c10_numero_oc ',
			'   AND c11_tipo        = "S") + ',
			'(SELECT NVL(SUM(((c11_cant_ped * c11_precio)',
			' - c11_val_descto) * (1 + c10_recargo / 100))',
			', 0) ',
			' FROM ordt010, ordt011 ',
			' WHERE c10_compania    = t23_compania ',
			'   AND c10_localidad   = t23_localidad ',
			'   AND c10_ord_trabajo = t23_orden ',
			'   AND c10_estado      = "C" ',
			'   AND c11_compania    = c10_compania ',
			'   AND c11_localidad   = c10_localidad ',
			'   AND c11_numero_oc   = c10_numero_oc ',
			'   AND c11_tipo        = "B") + ',
			' CASE WHEN (SELECT COUNT(*) FROM ordt010 ',
				' WHERE c10_compania    = t23_compania ',
				'   AND c10_localidad   = t23_localidad ',
				'   AND c10_ord_trabajo = t23_orden ',
				'   AND c10_estado      = "C") = 0 ',
			' THEN (t23_val_rp_tal + t23_val_rp_ext + ',
			       't23_val_rp_cti + t23_val_otros2) ',
			' ELSE 0.00 ',
			' END ',
		' ELSE (t23_val_mo_ext + t23_val_mo_cti + ',
			't23_val_rp_tal + t23_val_rp_ext + ',
			't23_val_rp_cti + t23_val_otros2) ',
		' END ',
		' ELSE 0.00 ',
		' END valor_tal_siva, ',
		' t23_val_impto, ',
		'CASE WHEN z01_tipo_doc_id = "R" AND ',
			' t23_cod_cliente <> ', rm_r00.r00_codcli_tal,
			' THEN "R" ',
			' ELSE "F" ',
		'END tipo_doc_id, ',
		'CASE WHEN z01_tipo_doc_id = "R" AND ',
			' t23_cod_cliente <> ', rm_r00.r00_codcli_tal,
			' THEN z01_num_doc_id ',
			' ELSE "9999999999999" ',
		'END cedruc, t23_cont_cred cont_cred, t23_localidad local, ',
		' t23_estado, DATE(t28_fec_anula) fecha_anu ',
		' FROM talt023, cxct001, OUTER talt028 ',
		' WHERE t23_compania          = ', vg_codcia,
		'   AND t23_localidad         = ', vg_codloc,
		'   AND t23_estado            IN ("F", "D") ',
		'   AND DATE(t23_fec_factura) BETWEEN "', rm_par.fecha_ini,
						'" AND "',rm_par.fecha_fin, '"',
		'   AND z01_codcli            = t23_cod_cliente ',
		'   AND t28_compania          = t23_compania ',
		'   AND t28_localidad         = t23_localidad ',
		'   AND t28_factura           = t23_num_factura ',
		' INTO TEMP tmp_tal '
PREPARE cons_tmp_tal FROM query 
EXECUTE cons_tmp_tal
{--
LET query = 'SELECT t28_factura FROM talt028 ',
		' WHERE t28_compania        = ', vg_codcia,
		'   AND t28_localidad       = ', vg_codloc,
		'   AND DATE(t28_fec_anula) BETWEEN "', rm_par.fecha_ini,
					     '" AND "', rm_par.fecha_fin, '"',
		' INTO TEMP tmp_tal_df '
PREPARE cons_tmp_tal_df FROM query 
EXECUTE cons_tmp_tal_df
DELETE FROM tmp_tal
	WHERE EXISTS (SELECT * FROM tmp_tal_df WHERE t28_factura = num_tran)
DROP TABLE tmp_tal_df
--}
LET query = 'SELECT num_tran num_anu, z21_tipo_doc ',
		' FROM tmp_tal, OUTER cxct021 ',
		' WHERE t23_estado    = "D" ',
		'   AND z21_compania  = ', vg_codcia,
		'   AND z21_localidad = local ',
		'   AND z21_tipo_doc  = "NC" ',
		'   AND z21_areaneg   = 2 ',
		'   AND z21_cod_tran  = "FA" ',
		'   AND z21_num_tran  = num_tran ',
		' INTO TEMP t2 '
PREPARE cons_t2_tal FROM query 
EXECUTE cons_t2_tal
DELETE FROM t2 WHERE z21_tipo_doc IS NOT NULL
LET query = 'INSERT INTO tmp_anu ',
		'SELECT CASE WHEN r38_cod_tran = "FA" THEN 1 ',
			'WHEN r38_cod_tran = "NV" THEN 2 END tipo_comp, ',
		{--
		' SELECT (SELECT s04_codigo FROM srit019, srit004 ',
		' WHERE s19_compania  = ', vg_codcia,
		'   AND s19_sec_tran  = ',
		' (SELECT s03_codigo FROM srit003 ',
		' WHERE s03_compania  = ', vg_codcia,
		'   AND s03_cod_ident = ',
			' (SELECT s12_codigo FROM srit012 ',
			' WHERE s12_compania = s03_compania ',
			'   AND s12_codigo   = tipo_doc_id)) ',
		'   AND s19_cod_ident = tipo_doc_id ',
		'   AND s19_tipo_doc  = "FA" ',
		'   AND s04_compania  = s19_compania ',
		'   AND s04_codigo    = s19_tipo_comp) tipo_comp, ',
		--}
		' b.g37_pref_sucurs, b.g37_pref_pto_vta, r38_num_sri[9, 16]',
		' num_sri_ini, r38_num_sri[9, 16] num_sri_fin, g02_numaut_sri,',
		' fecha_anu fecha ',
		' FROM tmp_tal, rept038, gent037 b, gent002 ',
		' WHERE t23_estado      = "D" ',
		'   AND num_tran        = (SELECT num_anu FROM t2 ',
					' WHERE num_anu  = num_tran) ',
		'   AND r38_compania    = ', vg_codcia,
		'   AND r38_localidad   = local ',
		'   AND r38_tipo_fuente = "OT" ',
		'   AND r38_cod_tran    IN ("FA", "NV") ',
		'   AND r38_num_tran    = num_tran ',
		'   AND b.g37_compania  = r38_compania ',
		'   AND b.g37_localidad = r38_localidad ',
		'   AND b.g37_tipo_doc  = r38_cod_tran ',
		'   AND b.g37_secuencia = ',
			' (SELECT MAX(a.g37_secuencia) ',
				' FROM gent037 a ',
				' WHERE a.g37_compania  = b.g37_compania ',
				'   AND a.g37_localidad = b.g37_localidad ',
				'   AND a.g37_tipo_doc  = b.g37_tipo_doc) ',
		'   AND g02_compania    = b.g37_compania ',
		'   AND g02_localidad   = b.g37_localidad '
PREPARE cons_tmp_anu FROM query 
EXECUTE cons_tmp_anu
IF num_args() = 8 THEN
	RETURN
END IF
DELETE FROM tmp_tal
	WHERE t23_estado = 'D'
	  AND num_tran   = (SELECT num_anu FROM t2 WHERE num_anu = num_tran)
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
DECLARE q_tal CURSOR FOR SELECT * FROM tmp_tot_ser 
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
--select count(*) into valor from tmp_anexo where cedruc = '9999999999999'
--display 'en foreach ', valor
END FOREACH
CALL obtener_retenciones(1, 1)
SELECT * FROM t1 WHERE tipo_doc_id IS NOT NULL INTO TEMP tmp_ret
SELECT b13_codcli, z01_tipo_doc_id tipo_doc_id, z01_num_doc_id cedruc,
	cod_concep, (valor_reten / (1.00 / 100)) base_imponible,
	1.00 val_porc, valor_reten
	FROM t1, cxct001
	WHERE tipo_doc_id IS NULL
	  AND b13_codcli  = z01_codcli
	INTO TEMP tmp_ret_fal
UPDATE tmp_ret_fal SET tipo_doc_id = 'F' WHERE cedruc = '9999999999999'
{--
select count(*) into resul from t1 where tipo_doc_id is null
display resul
unload to "reten_sri_fal.txt"
	select b13_codcli, tipo_doc_id, cedruc, valor_reten from tmp_ret_fal
--}
unload to "reten_sri.txt" select b13_codcli, cedruc, valor_reten from tmp_ret
DROP TABLE t1
DROP TABLE tmp_tal
LET query = 'SELECT CASE WHEN tipo_doc_id = "R" AND ',
			' b13_codcli <> ', rm_r00.r00_codcli_tal,
			' THEN "R" ',
			' ELSE "F" ',
		' END tipo_doc_id, ',
		' CASE WHEN tipo_doc_id = "R" AND ',
			' b13_codcli <> ', rm_r00.r00_codcli_tal,
			' THEN cedruc ',
			' ELSE "9999999999999" ',
		' END cedruc_ret, cod_concep, NVL(SUM(base_imponible), 0) ',
		' base_imponible, val_porc, ',
		' NVL(SUM(valor_reten), 0) valor_reten ',
		' FROM tmp_ret_fal ',
		' GROUP BY 1, 2, 3, 5 ',
		' INTO TEMP tmp_ret_fal_tot '
PREPARE exec_ret_fal_tot FROM query
EXECUTE exec_ret_fal_tot
--unload to "reten_sri_fal.txt"
--	select tipo_doc_id, cedruc_ret, valor_reten from tmp_ret_fal_tot
--select count(*) into resul from tmp_ret_fal_tot
--display resul
DROP TABLE tmp_ret_fal
LET query = 'SELECT CASE WHEN tipo_doc_id = "R" AND ',
			' b13_codcli <> ', rm_r00.r00_codcli_tal,
			' THEN cedruc ',
			' ELSE "9999999999999" ',
		' END cedruc_ret, cod_concep, base_imponible, val_porc, ',
		' NVL(SUM(valor_reten), 0) valor_reten ',
		' FROM tmp_ret ',
		' GROUP BY 1, 2, 3, 4 ',
		' INTO TEMP tmp_ret_tot '
PREPARE exec_ret_tot FROM query
EXECUTE exec_ret_tot
UPDATE tmp_ret_tot
	SET cod_concep     = '000',
	    base_imponible = 0.00,
	    val_porc       = 0.00
	WHERE valor_reten = 0 
UPDATE tmp_ret_tot SET val_porc = 1.00 WHERE valor_reten > 0 
UPDATE tmp_ret_tot
	SET base_imponible = (valor_reten / (val_porc / 100))
	WHERE valor_reten > 0 
DROP TABLE tmp_ret
UPDATE tmp_tot
	SET cuantos = (SELECT cuantos_tal FROM tmp_tot_tal
			WHERE cedruc_tal = doccli)
	WHERE EXISTS (SELECT cedruc_tal FROM tmp_tot_tal
			WHERE cedruc_tal = doccli)
	  AND c_tran = "FA"
DROP TABLE tmp_tot_tal
LET query = 'SELECT CASE WHEN LENGTH(z01_num_doc_id) = 13 ',
			'THEN "R" ',
			'ELSE "F" ',
			'END z01_tipo_doc_id, z01_num_doc_id, z21_codcli, ',
		' z21_tipo_doc, z21_num_doc, z21_valor, ',
		' CASE WHEN z21_val_impto > 0 ',
			' THEN ', rg_gen.g00_porc_impto,
			' ELSE 0.00 ',
		' END porc, ',
		' z21_val_impto, z21_cod_tran, z21_num_tran, z21_areaneg, ',
		'"', rm_par.fecha_fin, '" z21_fecha_emi, z21_localidad ',
		' FROM cxct021, cxct001 ',
		' WHERE z21_compania   = ', vg_codcia,
		'   AND z21_tipo_doc   = "NC" ',
		'   AND z21_fecha_emi  BETWEEN "', rm_par.fecha_ini,
					'" AND "', rm_par.fecha_fin, '"',
		'   AND z01_codcli     = z21_codcli ',
		' INTO TEMP tmp_fav '
PREPARE cons_tmp_fav FROM query 
EXECUTE cons_tmp_fav
IF vg_codcia = 1 AND (vg_codloc = 1 OR vg_codloc = 3) THEN
	CALL obtener_nc_sucursal()
END IF
CASE vg_codloc
	WHEN 1
		LET base_suc = 'acero_gc:'
	WHEN 3
		LET base_suc = 'acero_qs:'
END CASE
CALL obtener_fact_dev_nc(base_suc, 'tmp_fav')
UPDATE tmp_fav
	SET z01_tipo_doc_id = (SELECT b.z01_tipo_doc_id FROM tmp_ncdf b
				WHERE b.num_doc      = z21_num_doc
				  AND b.z21_cod_tran = z21_cod_tran
				  AND b.z21_num_tran = z21_num_tran),
	    z01_num_doc_id  = (SELECT b.z01_num_doc_id FROM tmp_ncdf b
				WHERE b.num_doc      = z21_num_doc
				  AND b.z21_cod_tran = z21_cod_tran
				  AND b.z21_num_tran = z21_num_tran)
	WHERE EXISTS (SELECT a.z21_tipo_doc, a.num_doc, a.z21_cod_tran,
				a.z21_num_tran
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
UPDATE tmp_nc
	SET z01_num_doc_id = "9999999999999"
	WHERE LENGTH(z01_num_doc_id) = 10
	  AND z01_tipo_doc_id        = "F"
INSERT INTO tmp_anexo
	SELECT z01_tipo_doc_id, z01_num_doc_id, z21_tipo_doc, z21_fecha_emi,
		0.00, NVL(SUM(valor_civa), 0), NVL(SUM(valor_siva), 0),
		NVL(SUM(z21_val_impto), 0), NVL(SUM(flete_nc), 0),'000', 0, 0, 0
		FROM tmp_nc
		GROUP BY 1, 2, 3, 4, 5, 10, 11, 12, 13
--select count(*) into valor from tmp_anexo where cedruc = '9999999999999'
--display 'primer insert ', valor
INSERT INTO tmp_tot
	SELECT z01_num_doc_id, z21_tipo_doc, z21_num_doc, COUNT(*)
		FROM tmp_nc
		GROUP BY 1, 2, 3
UPDATE tmp_anexo
	SET porc_impto = rg_gen.g00_porc_impto
	WHERE EXISTS (SELECT z01_tipo_doc_id, z01_num_doc_id, z21_tipo_doc,
				z21_fecha_emi
			FROM tmp_nc
			WHERE tipo_doc_id = z01_tipo_doc_id
			  AND cedruc      = z01_num_doc_id
			  AND cod_tran    = z21_tipo_doc
			  AND fecha_vta   = z21_fecha_emi)
DROP TABLE tmp_nc
LET query = 'SELECT CASE WHEN LENGTH(z01_num_doc_id) = 13 ',
			'THEN "R" ',
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
IF vg_codcia = 1 AND (vg_codloc = 1 OR vg_codloc = 3) THEN
	CALL obtener_nd_sucursal()
END IF
UPDATE tmp_nd
	SET z01_num_doc_id = "9999999999999"
	WHERE LENGTH(z01_num_doc_id) = 10
	  AND z01_tipo_doc_id        = "F"
INSERT INTO tmp_anexo
	SELECT z01_tipo_doc_id, z01_num_doc_id, z20_tipo_doc, z20_fecha_emi,
		0.00, NVL(SUM(valor_civa), 0), NVL(SUM(valor_siva), 0),
		NVL(SUM(z20_val_impto), 0), NVL(SUM(flete_nd), 0),'000', 0, 0, 0
		FROM tmp_nd
		GROUP BY 1, 2, 3, 4, 5, 10, 11, 12, 13
--select count(*) into valor from tmp_anexo where cedruc = '9999999999999'
--display 'segundo insert ', valor
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
			  AND fecha_vta   = z20_fecha_emi)
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
UPDATE tmp_anexo
	SET concepto  = (SELECT NVL(cod_concep, "000") FROM tmp_ret_fal_tot
				WHERE cedruc_ret = cedruc),
	    base_rent = (SELECT NVL(base_imponible, 0.00) FROM tmp_ret_fal_tot
				WHERE cedruc_ret = cedruc),
	    porc_rent = (SELECT NVL(val_porc, 0.00) FROM tmp_ret_fal_tot
				WHERE cedruc_ret = cedruc),
	    monto_ret = (SELECT NVL(valor_reten, 0.00) FROM tmp_ret_fal_tot
				WHERE cedruc_ret = cedruc)
	WHERE cedruc   = (SELECT cedruc_ret FROM tmp_ret_fal_tot
				WHERE cedruc_ret = cedruc)
	  AND cod_tran IN ('FA', 'NV')
DELETE FROM tmp_ret_fal_tot
	WHERE EXISTS (SELECT cedruc FROM tmp_anexo
			WHERE cedruc   = cedruc_ret
	  		  AND cod_tran IN ('FA', 'NV'))
LET query = 'SELECT UNIQUE (SELECT s03_codigo FROM srit003 ',
		' WHERE s03_compania  = ', vg_codcia,
	  	'   AND s03_cod_ident = ',
		' (SELECT s12_codigo FROM srit012 ',
			' WHERE s12_compania = s03_compania ',
		  	'   AND s12_codigo   = tipo_doc_id)) tipo_id, cedruc, ',
		' (SELECT s04_codigo FROM srit019, srit004 ',
			' WHERE s19_compania  = ', vg_codcia,
			'   AND s19_sec_tran  = ',
			' (SELECT s03_codigo FROM srit003 ',
				' WHERE s03_compania  = ', vg_codcia,
				'   AND s03_cod_ident = ',
				' (SELECT s12_codigo FROM srit012 ',
				' WHERE s12_compania = s03_compania ',
				'   AND s12_codigo   = tipo_doc_id)) ',
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
			' (SELECT s03_codigo FROM srit003 ',
				' WHERE s03_compania  = ', vg_codcia,
				'   AND s03_cod_ident = ',
				' (SELECT s12_codigo FROM srit012 ',
				' WHERE s12_compania = s03_compania ',
				'   AND s12_codigo   = tipo_doc_id)) ',
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
		--' valor_iva monto_iva_bie, ',
		' 0.00 monto_iva_bie, ',
		' (SELECT s09_codigo FROM srit009 ',
			' WHERE s09_compania  = ', vg_codcia,
			'   AND s09_codigo    = 0 ',
			'   AND s09_tipo_porc = "B") cod_por_bie, ',
		' 0.00 monto_ret_iva_bie, ',
		{--
		' CASE WHEN (SELECT s04_codigo FROM srit019, srit004 ',
			' WHERE s19_compania  = ', vg_codcia,
			'   AND s19_sec_tran  = ',
			' (SELECT s03_codigo FROM srit003 ',
				' WHERE s03_compania  = ', vg_codcia,
				'   AND s03_cod_ident = ',
				' (SELECT s12_codigo FROM srit012 ',
				' WHERE s12_compania = s03_compania ',
				'   AND s12_codigo   = tipo_doc_id)) ',
			'   AND s19_cod_ident = tipo_doc_id ',
			'   AND s19_tipo_doc  = cod_tran ',
			'   AND s04_compania  = s19_compania ',
			'   AND s04_codigo    = s19_tipo_comp) = 18 THEN ',
			' NVL((SELECT val_ser_tal FROM tmp_tot_ser ',
				' WHERE cedruc_tal   = cedruc ',
				'   AND tipo_doc_tal = tipo_doc_id), 0) ',
				' ELSE 0.00 ',
			' END monto_iva_ser, ',
		--}
		' 0.00 monto_iva_ser, "0" cod_ret_ser, ',
		' 0.00 monto_ret_iva_ser, ',
		' "N" ret_pre, concepto, base_rent, porc_rent, monto_ret ',
		' FROM tmp_anexo ',
		' INTO TEMP tmp_s21 '
PREPARE exec_anexo FROM query
EXECUTE exec_anexo
{
select count(*) into valor from tmp_s21 where cedruc = '9999999999999'
and tipo_id = '04'
display 'en tmp_z21 ', valor
}
DROP TABLE tmp_fact
DROP TABLE tmp_anexo
DROP TABLE tmp_tot_ser
DROP TABLE tmp_tot_f
CASE vg_codloc
	WHEN 1    LET codloc = 2
	WHEN 3    LET codloc = 4
	OTHERWISE LET codloc = vg_codloc
END CASE
LET query = 'DELETE FROM srit021 ',
		' WHERE s21_compania  = ', vg_codcia,
		'   AND s21_localidad IN (', vg_codloc, ', ', codloc, ') ',
		'   AND s21_anio      = ', YEAR(rm_par.fecha_fin),
		'   AND s21_mes       = ', MONTH(rm_par.fecha_fin)
PREPARE cons_del FROM query
EXECUTE cons_del
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
			', tmp_s21.*, "G", "', UPSHIFT(vg_usuario) CLIPPED,
			'", CURRENT ',
			' FROM tmp_s21 '
PREPARE cons_s21 FROM query
EXECUTE cons_s21
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
SELECT tmp_cli_fal.*, (SELECT s03_codigo FROM srit003
			WHERE s03_compania  = vg_codcia
			  AND s03_cod_ident = 
				(SELECT s12_codigo FROM srit012
				WHERE s12_compania = s03_compania
				  AND s12_codigo   = tipo_doc_id)) tipo_id_fin,
	tmp_ret_fal_tot.*, s21_compania s21_cia, s21_localidad s21_loc,
	s21_anio s21_ano, s21_mes s21_m, s21_ident_cli s21_id_cl,
	s21_num_doc_id s21_num_id, s21_tipo_comp s21_tp
	FROM tmp_cli_fal, tmp_ret_fal_tot, OUTER srit021
	WHERE s21_compania   = vg_codcia
	  AND s21_localidad  = vg_codloc
	  AND s21_anio       = YEAR(rm_par.fecha_fin)
	  AND s21_mes        = MONTH(rm_par.fecha_fin)
	  AND s21_ident_cli  = (SELECT s03_codigo FROM srit003
				WHERE s03_compania  = vg_codcia
				  AND s03_cod_ident = 
					(SELECT s12_codigo FROM srit012
					WHERE s12_compania = s03_compania
					  AND s12_codigo   = tipo_doc_id))
	  AND s21_num_doc_id = cedruc_ret
	  AND s21_tipo_comp  = tipo_comp
	INTO TEMP tmp_faltantes
{
DELETE FROM tmp_faltantes
	WHERE cedruc IN (SELECT s21_num_doc_id FROM srit021
		 WHERE s21_compania   = vg_codcia
		   AND s21_localidad  = vg_codloc
		   AND s21_anio       = YEAR(rm_par.fecha_fin)
		   AND s21_mes        = MONTH(rm_par.fecha_fin)
		   AND s21_num_doc_id = cedruc
		   AND s21_tipo_comp  = '18')
}
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
			{--
			', (SELECT s03_codigo FROM srit003 ',
			' WHERE s03_compania  = ', vg_codcia,
			'   AND s03_cod_ident = ',
			' (SELECT s12_codigo FROM srit012 ',
			' WHERE s12_compania = s03_compania ',
			'   AND s12_codigo   = tipo_doc_id)) tipo_id,',
			--}
		', tipo_id_fin, ',
		' cedruc_ret, tipo_comp, fecha_cont, num_comp, fecha_vta,',
		' base_imp, iva_pre, valor_vta_civa, cod_por_iva, valor_iva,',
		' base_ice, cod_por_ice,monto_ice, monto_iva_bie, cod_por_bie,',
		' monto_ret_iva_bie, monto_iva_ser, cod_ret_ser,',
		' monto_ret_iva_ser, ret_pre, cod_concep, base_imponible,',
		' val_porc, valor_reten, "G", "', UPSHIFT(vg_usuario) CLIPPED,
		'", CURRENT ',
		--' FROM tmp_cli_fal, tmp_ret_fal_tot ',
		' FROM tmp_faltantes ',
		' WHERE s21_cia IS NULL '
PREPARE cons_s21_2 FROM query
EXECUTE cons_s21_2
DROP TABLE tmp_cli_fal
DROP TABLE tmp_ret_fal_tot
UPDATE srit021
	SET s21_base_imp_renta = s21_base_imp_renta +  
				(SELECT NVL(SUM(base_imponible), 0)
					FROM tmp_faltantes
					WHERE s21_cia    = s21_compania
					  AND s21_loc    = s21_localidad
					  AND s21_ano    = s21_anio
					  AND s21_m      = s21_mes
					  AND s21_id_cl  = s21_ident_cli
					  AND s21_num_id = s21_num_doc_id
					  AND s21_tp     = s21_tipo_comp),
	    s21_monto_ret_rent = s21_monto_ret_rent +
				(SELECT NVL(SUM(valor_reten), 0)
					FROM tmp_faltantes
					WHERE s21_cia    = s21_compania
					  AND s21_loc    = s21_localidad
					  AND s21_ano    = s21_anio
					  AND s21_m      = s21_mes
					  AND s21_id_cl  = s21_ident_cli
					  AND s21_num_id = s21_num_doc_id
					  AND s21_tp     = s21_tipo_comp)
	WHERE EXISTS (SELECT * FROM tmp_faltantes
			WHERE s21_cia    = s21_compania
			  AND s21_loc    = s21_localidad
			  AND s21_ano    = s21_anio
			  AND s21_m      = s21_mes
			  AND s21_id_cl  = s21_ident_cli
			  AND s21_num_id = s21_num_doc_id
			  AND s21_tp     = s21_tipo_comp)
DROP TABLE tmp_faltantes
LET query = 'SELECT s21_ident_cli, s21_num_doc_id,',
		' CASE WHEN s21_num_doc_id <> "9999999999999" THEN ',
			' (SELECT TRIM(a.z01_nomcli) FROM cxct001 a ',
			' WHERE a.z01_codcli = (SELECT MAX(b.z01_codcli) ',
						'FROM cxct001 b ',
						'WHERE TRIM(b.z01_num_doc_id)=',
							'TRIM(s21_num_doc_id) ',
						'  AND z01_estado = "A")) ',
			' ELSE "CONSUMIDOR FINAL" ',
		' END nomcliente, ',
		' s21_tipo_comp, s21_fecha_reg_cont, s21_num_comp_emi, ',
		' s21_fecha_emi_vta, s21_base_imp_tar_0, s21_iva_presuntivo, ',
		' s21_bas_imp_gr_iva, s21_cod_porc_iva, s21_monto_iva, ',
		' s21_base_imp_ice, s21_cod_porc_ice, s21_monto_ice, ',
		' s21_monto_iva_bie, s21_cod_ret_ivabie, s21_mon_ret_ivabie, ',
		' s21_monto_iva_ser, s21_cod_ret_ivaser, s21_mon_ret_ivaser, ',
		' s21_ret_presuntivo, s21_concepto_ret, s21_base_imp_renta, ',
		' s21_porc_ret_renta, s21_monto_ret_rent ',
		' FROM srit021 ',
		' WHERE s21_compania  = ', vg_codcia,
		'   AND s21_localidad = ', vg_codloc,
		'   AND s21_anio      = ', YEAR(rm_par.fecha_fin),
		'   AND s21_mes       = ', MONTH(rm_par.fecha_fin),
		' INTO TEMP t1 '
PREPARE exec_t1_final FROM query
EXECUTE exec_t1_final
UNLOAD TO 'anexo_ventas.unl' SELECT * FROM t1
LET archivo = 'anexo_ventas_', vg_codloc USING "&&", '-',
		YEAR(rm_par.fecha_fin) USING "&&&&",'-',
		MONTH(rm_par.fecha_fin) USING "&&",
		'.unl ' 
LET comando = 'mv anexo_ventas.unl ', archivo CLIPPED
RUN comando
UNLOAD TO 'anulados.unl' SELECT * FROM tmp_anu
LET archivo = 'anulados_', vg_codloc USING "&&", '-',
		YEAR(rm_par.fecha_fin) USING "&&&&",'-',
		MONTH(rm_par.fecha_fin) USING "&&",
		'.unl ' 
LET comando = 'mv anulados.unl ', archivo CLIPPED
RUN comando
DROP TABLE t1
DROP TABLE tmp_anu
CALL fl_mostrar_mensaje('Anexo de Ventas generado OK.', 'info')

END FUNCTION



FUNCTION obtener_facturas(flag)
DEFINE flag		SMALLINT
DEFINE query		VARCHAR(4000)
DEFINE base_suc		VARCHAR(10)
DEFINE codloc		LIKE rept019.r19_localidad

CASE flag
	WHEN 1
		LET base_suc = NULL
		LET codloc   = vg_codloc
	WHEN 2
		CASE vg_codloc
			WHEN 1
				LET base_suc = 'acero_gc:'
				LET codloc   = 2
			WHEN 3
				LET base_suc = 'acero_qs:'
				LET codloc   = 4
		END CASE
END CASE
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
		' FROM ', base_suc CLIPPED, 'rept019, ',
			base_suc CLIPPED, 'cxct001 ',
		' WHERE r19_compania     = ', vg_codcia,
		'   AND r19_localidad    = ', codloc,
		'   AND r19_cod_tran     IN ("FA", "NV") ',
		--'   AND (r19_tipo_dev    IN ("TR", "DF") ',
		--'    OR r19_tipo_dev     IS NULL) ',
		'   AND DATE(r19_fecing) BETWEEN "', rm_par.fecha_ini,
					  '" AND "', rm_par.fecha_fin, '"',
		'   AND z01_codcli       = r19_codcli ',
		' INTO TEMP t1 ' 
PREPARE cons_t1 FROM query 
EXECUTE cons_t1
LET query = 'SELECT tipo_dev tipo_anu, num_dev num_anu, z21_tipo_doc ',
		' FROM t1, OUTER ', base_suc CLIPPED, 'cxct021 ',
		' WHERE t1.tipo_dev   = "AF" ',
		'   AND z21_compania  = ', vg_codcia,
		'   AND z21_localidad = ', codloc,
		'   AND z21_tipo_doc  = "NC" ',
		'   AND z21_cod_tran  = t1.tipo_dev ',
		'   AND z21_num_tran  = t1.num_dev ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query 
EXECUTE cons_t2
DELETE FROM t2 WHERE z21_tipo_doc IS NOT NULL
LET query = 'SELECT CASE WHEN LENGTH(cedruc) = 13 AND ',
		' fp_digito_veri(cedruc) = 1 THEN 1 ELSE 2',
		{--
		'(SELECT s04_codigo FROM ', base_suc CLIPPED, 'srit019, ',
			base_suc CLIPPED, 'srit004 ',
		' WHERE s19_compania  = ', vg_codcia,
		'   AND s19_sec_tran  = ',
		' (SELECT s03_codigo FROM ', base_suc CLIPPED, 'srit003 ',
		' WHERE s03_compania  = ', vg_codcia,
		'   AND s03_cod_ident = ',
			' (SELECT s12_codigo FROM ',base_suc CLIPPED,'srit012 ',
			' WHERE s12_compania = s03_compania ',
			'   AND s12_codigo   = tipo_doc_id)) ',
		'   AND s19_cod_ident = tipo_doc_id ',
		'   AND s19_tipo_doc  = cod_tran ',
		'   AND s04_compania  = s19_compania ',
		'   AND s04_codigo    = s19_tipo_comp) tipo_comp, ',
		--}
		' END tipo_comp, ',
		' b.g37_pref_sucurs, b.g37_pref_pto_vta, r38_num_sri[9, 16]',
		' num_sri_ini, r38_num_sri[9, 16] num_sri_fin, g02_numaut_sri,',
		' fecha_vta fecha ',
		' FROM t1, ', base_suc CLIPPED, 'rept038, ', base_suc CLIPPED,
			'gent037 b, ', base_suc CLIPPED, 'gent002 ',
		' WHERE tipo_dev        = "AF" ',
		'   AND num_dev         = (SELECT num_anu FROM t2 ',
					' WHERE tipo_anu = tipo_dev ',
					'   AND num_anu  = num_dev) ',
		'   AND r38_compania    = ', vg_codcia,
		'   AND r38_localidad   = local ',
		'   AND r38_tipo_fuente = "PR" ',
		'   AND r38_cod_tran    IN ("FA", "NV") ',
		'   AND r38_num_tran    = num_tran ',
		'   AND b.g37_compania  = r38_compania ',
		'   AND b.g37_localidad = r38_localidad ',
		'   AND b.g37_tipo_doc  = r38_cod_tran ',
		'   AND b.g37_secuencia = ',
			' (SELECT MAX(a.g37_secuencia) ',
				' FROM ', base_suc CLIPPED, 'gent037 a ',
				' WHERE a.g37_compania  = b.g37_compania ',
				'   AND a.g37_localidad = b.g37_localidad ',
				'   AND a.g37_tipo_doc  = b.g37_tipo_doc) ',
		'   AND g02_compania    = b.g37_compania ',
		'   AND g02_localidad   = b.g37_localidad ',
		' INTO TEMP t3 '
PREPARE cons_t3 FROM query 
EXECUTE cons_t3
DELETE FROM t1
	WHERE tipo_dev = "AF"
	  AND num_dev  = (SELECT num_anu FROM t2
				WHERE tipo_anu = tipo_dev
				  AND num_anu  = num_dev)
DROP TABLE t2

END FUNCTION



FUNCTION obtener_devoluciones(flag)
DEFINE flag		SMALLINT
DEFINE query		VARCHAR(2000)
DEFINE base_suc		VARCHAR(10)
DEFINE codloc		LIKE rept019.r19_localidad

CASE flag
	WHEN 1
		LET base_suc = NULL
		LET codloc   = vg_codloc
	WHEN 2
		CASE vg_codloc
			WHEN 1
				LET base_suc = 'acero_gc:'
				LET codloc   = 2
			WHEN 3
				LET base_suc = 'acero_qs:'
				LET codloc   = 4
		END CASE
END CASE
LET query = 'SELECT CASE WHEN LENGTH(r19_cedruc) = 13 ',
			' THEN r19_tipo_dev ',
			' ELSE "NV" ',
			' END tipo_df, ',
		' r19_num_dev num_df, ',
		' r19_porc_impto, ',
		' NVL(CASE WHEN r19_porc_impto > 0 ',
			' THEN SUM(r19_tot_bruto - r19_tot_dscto) ',
			' ELSE SUM(r19_tot_neto - r19_flete) ',
		' END, 0) valor_df',
		' FROM rept019, cxct001 ',
		' WHERE r19_compania     = ', vg_codcia,
		'   AND r19_localidad    = ', codloc,
		'   AND r19_cod_tran     = "DF" ',
		'   AND DATE(r19_fecing) BETWEEN "', rm_par.fecha_ini,
					  '" AND "', rm_par.fecha_fin, '"',
		'   AND z01_codcli       = r19_codcli ',
		' GROUP BY 1, 2, 3 ',
		' INTO TEMP t1 '
PREPARE cons_tdf FROM query 
EXECUTE cons_tdf

END FUNCTION



FUNCTION obtener_nc_sucursal()
DEFINE query		VARCHAR(3000)
DEFINE base_suc		VARCHAR(10)
DEFINE codloc		LIKE rept019.r19_localidad
--define valor		integer

CASE vg_codloc
	WHEN 1
		LET base_suc = 'acero_gc:'
		LET codloc   = 2
	WHEN 3
		LET base_suc = 'acero_qs:'
		LET codloc   = 4
END CASE
LET query = 'SELECT CASE WHEN LENGTH(z01_num_doc_id) = 13 ',
			'THEN "R" ',
			'ELSE "F" ',
			'END z01_tipo_doc_id, z01_num_doc_id, z21_codcli, ',
		' z21_tipo_doc, z21_num_doc, z21_valor, ',
		' CASE WHEN z21_val_impto > 0 ',
			' THEN ', rg_gen.g00_porc_impto,
			' ELSE 0.00 ',
		' END porc, ',
		' z21_val_impto, z21_cod_tran, z21_num_tran, z21_areaneg, ',
		'"', rm_par.fecha_fin, '" z21_fecha_emi, z21_localidad ',
		' FROM ', base_suc CLIPPED, 'cxct021, ',
			base_suc CLIPPED, 'cxct001 ',
		' WHERE z21_compania   = ', vg_codcia,
		'   AND z21_localidad  = ', codloc,
		'   AND z21_tipo_doc   = "NC" ',
		'   AND z21_fecha_emi  BETWEEN "', rm_par.fecha_ini,
					'" AND "', rm_par.fecha_fin, '"',
		'   AND z21_saldo      = 0 ',
		'   AND z21_origen     = "A" ',
		'   AND z21_valor      = (SELECT NVL(SUM(z23_valor_cap + ',
						'z23_valor_int), 0) * (-1) ',
					' FROM ', base_suc CLIPPED, 'cxct023, ',
						base_suc CLIPPED, 'cxct022 ',
					' WHERE z23_compania  = z21_compania ',
					'   AND z23_localidad = z21_localidad ',
					'   AND z23_codcli    = z21_codcli ',
					'   AND z23_tipo_favor= z21_tipo_doc ',
					'   AND z23_doc_favor = z21_num_doc ',
					'   AND z22_compania  = z23_compania ',
					'   AND z22_localidad = z23_localidad ',
					'   AND z22_codcli    = z23_codcli ',
					'   AND z22_tipo_trn  = z23_tipo_trn ',
					'   AND z22_num_trn   = z23_num_trn ',
					' AND DATE(z22_fecing)= z21_fecha_emi)',
		'   AND z01_codcli     = z21_codcli ',
		' INTO TEMP tmp_nc_suc '
PREPARE cons_tmp_nc_suc FROM query 
EXECUTE cons_tmp_nc_suc
CALL obtener_fact_dev_nc(base_suc, 'tmp_nc_suc')
UPDATE tmp_nc_suc
	SET z01_tipo_doc_id = (SELECT b.z01_tipo_doc_id FROM tmp_ncdf b
				WHERE b.num_doc = z21_num_doc),
	    z01_num_doc_id  = (SELECT b.z01_num_doc_id FROM tmp_ncdf b
				WHERE b.num_doc = z21_num_doc)
	WHERE EXISTS (SELECT a.z21_tipo_doc, a.num_doc, a.z21_cod_tran,
				a.z21_num_tran
			FROM tmp_ncdf a
			WHERE a.z21_tipo_doc = z21_tipo_doc
			  AND a.num_doc      = z21_num_doc
			  AND a.z21_cod_tran = z21_cod_tran
			  AND a.z21_num_tran = z21_num_tran)
	  AND z21_areaneg = 1
DROP TABLE tmp_ncdf
--select count(*) into valor from t2
--display valor
INSERT INTO tmp_fav SELECT * FROM tmp_nc_suc
DROP TABLE tmp_nc_suc

END FUNCTION



FUNCTION obtener_fact_dev_nc(base_suc, tabla)
DEFINE base_suc		VARCHAR(10)
DEFINE tabla		VARCHAR(15)
DEFINE query		VARCHAR(3000)

LET query = 'SELECT CASE WHEN (SELECT LENGTH(a.r19_cedruc) ',
				'FROM rept019 a ',
				'WHERE a.r19_compania  = b.r19_compania ',
				'  AND a.r19_localidad = b.r19_localidad ',
				'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
				'  AND a.r19_num_tran  = b.r19_num_dev) = 13',
			' THEN "R" ',
			' ELSE "F" ',
			' END z01_tipo_doc_id, ',
		' CASE WHEN (SELECT LENGTH(a.r19_cedruc) ',
				'FROM rept019 a ',
				'WHERE a.r19_compania  = b.r19_compania ',
				'  AND a.r19_localidad = b.r19_localidad ',
				'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
				'  AND a.r19_num_tran  = b.r19_num_dev) = 13',
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
		'   AND b.r19_num_tran  = z21_num_tran '
IF vg_codcia = 1 THEN
	LET query = query CLIPPED,
		' UNION ',
		' SELECT CASE WHEN (SELECT LENGTH(a.r19_cedruc) ',
				'FROM ', base_suc CLIPPED, 'rept019 a ',
				'WHERE a.r19_compania  = b.r19_compania ',
				'  AND a.r19_localidad = b.r19_localidad ',
				'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
				'  AND a.r19_num_tran  = b.r19_num_dev) = 13',
			' THEN "R" ',
			' ELSE "F" ',
			' END z01_tipo_doc_id, ',
		' CASE WHEN (SELECT LENGTH(a.r19_cedruc) ',
				'FROM ', base_suc CLIPPED, 'rept019 a ',
				'WHERE a.r19_compania  = b.r19_compania ',
				'  AND a.r19_localidad = b.r19_localidad ',
				'  AND a.r19_cod_tran  = b.r19_tipo_dev ',
				'  AND a.r19_num_tran  = b.r19_num_dev) = 13',
			' THEN z01_num_doc_id ',
			' ELSE "9999999999999" ',
			' END z01_num_doc_id, z21_codcli, z21_tipo_doc,',
		' z21_num_doc num_doc, z21_valor, z21_val_impto, z21_cod_tran,',
		' z21_num_tran, z21_areaneg, z21_fecha_emi ',
		' FROM ', tabla CLIPPED, ', ', base_suc CLIPPED, 'rept019 b ',
		' WHERE z21_areaneg     = 1 ',
		'   AND b.r19_compania  = ', vg_codcia,
		'   AND b.r19_localidad = z21_localidad ',
		'   AND b.r19_cod_tran  = z21_cod_tran ',
		'   AND b.r19_num_tran  = z21_num_tran '
END IF
LET query = query CLIPPED, ' INTO TEMP tmp_ncdf '
PREPARE cons_tmp_ncdf FROM query 
EXECUTE cons_tmp_ncdf

END FUNCTION



FUNCTION obtener_nd_sucursal()
DEFINE query		VARCHAR(3000)
DEFINE base_suc		VARCHAR(10)
DEFINE codloc		LIKE rept019.r19_localidad

CASE vg_codloc
	WHEN 1
		LET base_suc = 'acero_gc:'
		LET codloc   = 2
	WHEN 3
		LET base_suc = 'acero_qs:'
		LET codloc   = 4
END CASE
LET query = 'INSERT INTO tmp_nd ',
 		'SELECT CASE WHEN LENGTH(z01_num_doc_id) = 13 ',
			'THEN "R" ',
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
		' FROM ', base_suc CLIPPED, 'cxct020, ',
			base_suc CLIPPED, 'cxct001 ',
		' WHERE z20_compania   = ', vg_codcia,
		'   AND z20_localidad  = ', codloc,
		'   AND z20_tipo_doc   = "ND" ',
		'   AND z20_fecha_emi  BETWEEN "', rm_par.fecha_ini,
					'" AND "', rm_par.fecha_fin, '"',
		'   AND z01_codcli     = z20_codcli '
PREPARE cons_tmp_nd_suc FROM query 
EXECUTE cons_tmp_nd_suc

END FUNCTION



FUNCTION obtener_retenciones(flag, flag_join)
DEFINE flag, flag_join	SMALLINT
DEFINE query		VARCHAR(4000)
DEFINE tabla_fact	VARCHAR(15)
DEFINE localidad	VARCHAR(15)

CASE flag
	WHEN 1
		LET localidad = ' local '
	WHEN 2
		CASE vg_codloc
			WHEN 1
				LET localidad = ' 2 '
			WHEN 3
				LET localidad = ' 4 '
		END CASE
END CASE
CASE flag_join
	WHEN 1
		LET tabla_fact  = 'tmp_fact'
	WHEN 2
		LET tabla_fact  = 'tmp_tal'
END CASE
LET query = 'SELECT UNIQUE codcli, tipo_doc_id, cedruc ',
		--' FROM ', tabla_fact CLIPPED,
		' FROM tmp_fact ',
		' UNION ',
			' SELECT UNIQUE codcli, tipo_doc_id, cedruc ',
			' FROM tmp_tal ',
		' INTO TEMP t2 '
PREPARE cli_t2 FROM query
EXECUTE cli_t2
LET query = 'SELECT UNIQUE b13_codcli, tipo_doc_id, cedruc, "307" cod_concep,',
		' 1111111.11 base_imponible, 1.11 val_porc,',
		' NVL(SUM(b13_valor_base), 0) valor_reten ',
		' FROM ctbt012, ctbt013, ctbt042, OUTER t2 ',
		' WHERE b12_compania    = ', vg_codcia,
		'   AND b12_estado      = "M" ',
		'   AND b12_fec_proceso BETWEEN "', rm_par.fecha_ini,
					 '" AND "', rm_par.fecha_fin, '"',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b13_codcli      = codcli ',
		'   AND b13_cuenta      IN ("11300201002", b42_retencion) ',
		'   AND b42_compania    = b12_compania ',
		--'   AND b42_localidad   = 1 ',
		'   AND b42_localidad   = ', vg_codloc,
		' GROUP BY 1, 2, 3, 4, 5, 6 ',
		' INTO TEMP t1 '
PREPARE exec_tmp_ret FROM query
EXECUTE exec_tmp_ret
DROP TABLE t2

END FUNCTION



{-- OJO FUNNCION QUE OBTIENE LA RETENCION DE LA FORMA PAGO 
FUNCTION obtener_retenciones2(flag, flag_join)
DEFINE flag, flag_join	SMALLINT
DEFINE query		VARCHAR(4000)
DEFINE base_suc		VARCHAR(10)
DEFINE tabla_fact	VARCHAR(15)
DEFINE localidad	VARCHAR(15)
DEFINE areaneg		LIKE cxct024.z24_areaneg
DEFINE tipo_fuente	LIKE cajt010.j10_tipo_fuente

CASE flag
	WHEN 1
		LET base_suc  = NULL
		LET localidad = ' local '
	WHEN 2
		CASE vg_codloc
			WHEN 1
				LET base_suc  = 'acero_gc:'
				LET localidad = ' 2 '
			WHEN 3
				LET base_suc  = 'acero_qs:'
				LET localidad = ' 4 '
		END CASE
END CASE
CASE flag_join
	WHEN 1
		LET tabla_fact  = 'tmp_fact'
		LET tipo_fuente = 'PR'
		LET areaneg     = 1
	WHEN 2
		LET tabla_fact  = 'tmp_tal'
		LET tipo_fuente = 'OT'
		LET areaneg     = 2
END CASE
LET query = 'SELECT UNIQUE j10_codcli, tipo_doc_id, cedruc, "307" cod_concep,',
		' 1111111.11 base_imponible, 1.11 val_porc,',
		' NVL(SUM(j11_valor), 0) valor_reten',
		' FROM ', tabla_fact CLIPPED, ', ', base_suc CLIPPED,
			'cajt010, ', base_suc CLIPPED, 'cajt011 ' ,
		' WHERE cont_cred        = "C" ',
		'   AND j10_compania     = ', vg_codcia,
		'   AND j10_localidad    = ', localidad,
		'   AND j10_tipo_fuente  = "', tipo_fuente, '"',
		'   AND j10_codcli       = codcli ',
		'   AND j10_tipo_destino IN ("FA", "NV") ',
		'   AND j10_num_destino  = num_tran ',
		'   AND j10_estado       = "P" ',
		'   AND j11_compania     = j10_compania ',
		'   AND j11_localidad    = j10_localidad ',
		'   AND j11_tipo_fuente  = j10_tipo_fuente ',
		'   AND j11_num_fuente   = j10_num_fuente ',
		'   AND j11_codigo_pago  = "RT" ',
		' GROUP BY 1, 2, 3, 4, 5, 6 '
IF flag = 1 THEN
	LET query = query CLIPPED,
		' UNION ',
		' SELECT UNIQUE j10_codcli, tipo_doc_id, cedruc, "307"',
			' cod_concep, 1111111.11 base_imponible,1.11 val_porc,',
			' NVL(SUM(j11_valor), 0) valor_reten ',
			' FROM ', tabla_fact CLIPPED, ', cxct024, cxct025,',
				' cajt010, cajt011 ' ,
			' WHERE cont_cred        = "R" ',
			'   AND z24_compania     = ', vg_codcia,
			'   AND z24_localidad    = ', localidad,
			'   AND z24_codcli       = codcli ',
			'   AND z24_areaneg      = ', areaneg,
			'   AND z25_compania     = z24_compania ',
			'   AND z25_localidad    = z24_localidad ',
			'   AND z25_numero_sol   = z24_numero_sol ',
			'   AND z25_tipo_doc     IN ("FA", "NV") ',
			'   AND z25_num_doc      = num_tran ',
			'   AND j10_compania     = z25_compania ',
			'   AND j10_localidad    = z25_localidad ',
			'   AND j10_tipo_fuente  = "SC" ',
			'   AND j10_num_fuente   = z25_numero_sol ',
			'   AND j10_estado       = "P" ',
			'   AND j11_compania     = j10_compania ',
			'   AND j11_localidad    = j10_localidad ',
			'   AND j11_tipo_fuente  = j10_tipo_fuente ',
			'   AND j11_num_fuente   = j10_num_fuente ',
			'   AND j11_codigo_pago  = "RT" ',
			' GROUP BY 1, 2, 3, 4, 5, 6 '
END IF
LET query = query CLIPPED, ' INTO TEMP t1 '
PREPARE exec_tmp_ret FROM query
EXECUTE exec_tmp_ret

END FUNCTION
--}



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



FUNCTION generar_archivo_venta_xml()
DEFINE r_s21		RECORD LIKE srit021.*
DEFINE registro		CHAR(4000)

DECLARE q_s21 CURSOR FOR 
	SELECT * FROM srit021
	WHERE s21_compania  = vg_codcia
	  AND s21_localidad = vg_codloc
	  AND s21_anio      = YEAR(rm_par.fecha_fin)
	  AND s21_mes       = MONTH(rm_par.fecha_fin)
DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
DISPLAY '<iva xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
DISPLAY '<numeroRuc>1790008959001</numeroRuc>'
DISPLAY '<razonSocial>ACERO COMERCIAL ECUATORIANO S.A.</razonSocial>'
DISPLAY '<direccionMatriz>AV. LA PRENSA</direccionMatriz>'
DISPLAY '<telefono>022454333</telefono>'
DISPLAY '<email>infouio@acerocomercial.com</email>'
DISPLAY '<tpIdRepre>C</tpIdRepre>'
DISPLAY '<idRepre>0915392880</idRepre>'
DISPLAY '<rucContador>0915392880001</rucContador>'
DISPLAY '<anio>', YEAR(rm_par.fecha_fin), '</anio>'
DISPLAY '<mes>', MONTH(rm_par.fecha_fin) USING "&&", '</mes>'
DISPLAY '<compras>'
DISPLAY '</compras>'
LET registro = '<ventas>'
FOREACH q_s21 INTO r_s21.*
	LET registro = registro CLIPPED, '<detalleVentas>',
			'<tpIdCliente>', r_s21.s21_ident_cli, '</tpIdCliente>',
			'<idCliente>', r_s21.s21_num_doc_id, '</idCliente>',
		'<tipoComprobante>', r_s21.s21_tipo_comp, '</tipoComprobante>',
		'<fechaRegistro>', r_s21.s21_fecha_reg_cont USING "dd/mm/yyyy", '</fechaRegistro>',
		'<numeroComprobantes>', r_s21.s21_num_comp_emi, '</numeroComprobantes> ',
		'<fechaEmision>', r_s21.s21_fecha_emi_vta USING "dd/mm/yyyy", '</fechaEmision> ',
		'<baseImponible>', r_s21.s21_base_imp_tar_0, '</baseImponible> ',
		'<ivaPresuntivo>', r_s21.s21_iva_presuntivo, '</ivaPresuntivo> ',
		'<baseImpGrav>', r_s21.s21_bas_imp_gr_iva, '</baseImpGrav> ',
		'<porcentajeIva>', r_s21.s21_cod_porc_iva, '</porcentajeIva> ',
		'<montoIva>', r_s21.s21_monto_iva, '</montoIva> ',
		'<baseImpIce>', r_s21.s21_base_imp_ice, '</baseImpIce> ',
		'<porcentajeIce>', r_s21.s21_cod_porc_ice, '</porcentajeIce> ',
		'<montoIce>', r_s21.s21_monto_ice, '</montoIce> ',
		'<montoIvaBienes>', r_s21.s21_monto_iva_bie, '</montoIvaBienes> ',
		'<porRetBienes>', r_s21.s21_cod_ret_ivabie, '</porRetBienes> ',
		'<valorRetBienes>', r_s21.s21_mon_ret_ivabie, '</valorRetBienes> ',
		'<montoIvaServicios>', r_s21.s21_monto_iva_ser, '</montoIvaServicios> ',
		'<porRetServicios>', r_s21.s21_cod_ret_ivaser, '</porRetServicios> ',
		'<valorRetServicios>', r_s21.s21_mon_ret_ivaser, '</valorRetServicios> ',
		'<retPresuntiva>', r_s21.s21_ret_presuntivo, '</retPresuntiva>'
	IF r_s21.s21_concepto_ret <> '000' THEN
		LET registro = registro CLIPPED, '<air>','<detalleAir>',
			'<codRetAir>', r_s21.s21_concepto_ret, '</codRetAir>',
			'<baseImpAir>',r_s21.s21_base_imp_renta,'</baseImpAir>',
			'<porcentajeAir>', r_s21.s21_porc_ret_renta,'</porcentajeAir>',
			'<valRetAir>', r_s21.s21_monto_ret_rent,'</valRetAir>',
			'</detalleAir>','</air>'
	ELSE
		LET registro = registro CLIPPED, '<air/>'
	END IF
	LET registro = registro CLIPPED, '</detalleVentas>'
	DISPLAY registro CLIPPED
	LET registro = ' '
END FOREACH
DISPLAY '</ventas>'
DISPLAY '<importaciones>'
DISPLAY '</importaciones>'
DISPLAY '<exportaciones>'
DISPLAY '</exportaciones>'
DISPLAY '<recap>'
DISPLAY '</recap>'
DISPLAY '<fideicomisos>'
DISPLAY '</fideicomisos>'
DISPLAY '<anulados>'
DISPLAY '</anulados>'
DISPLAY '<rendFinancieros>'
DISPLAY '</rendFinancieros>'
DISPLAY '</iva>'
CALL fl_mostrar_mensaje('Archivo XML de ventas generado OK.', 'info')

END FUNCTION



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

DECLARE q_anu CURSOR FOR SELECT * FROM tmp_anu ORDER BY 4
LET registro = '<anulados>'
FOREACH q_anu INTO r_anu.*
	LET registro = registro CLIPPED, '<detalleAnulados>',
  			'<tipoComprobante>', r_anu.comp, '</tipoComprobante>',
			'<establecimiento>', r_anu.punto, '</establecimiento>',
			'<puntoEmision>', r_anu.estab, '</puntoEmision>',
			'<secuencialInicio>',r_anu.numini,'</secuencialInicio>',
			'<secuencialFin>', r_anu.numfin, '</secuencialFin>',
			'<autorizacion>', r_anu.autoriz, '</autorizacion>',
			'<fechaAnulacion>', r_anu.fecha, '</fechaAnulacion>',
			'</detalleAnulados>'
	DISPLAY registro CLIPPED
	LET registro = ' '
END FOREACH
DISPLAY '</anulados>'
CALL fl_mostrar_mensaje('Archivo XML de anulados generado OK.', 'info')

END FUNCTION

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
				fecha_fin	DATE,
				tipo_gye	CHAR(1),
				tipo_uio	CHAR(1),
				tipo_nac	CHAR(1)
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
DEFINE vm_tip_anexo	LIKE srit004.s04_codigo
DEFINE vm_fin_mes	DATE



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/srip200.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND NOT (num_args() >= 9 AND num_args() <= 15) THEN
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
LET num_rows   = 9
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
LET rm_par.fecha_ini = MDY(MONTH(TODAY), 1, YEAR(TODAY))
LET rm_par.fecha_fin = rm_par.fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET vm_fin_mes       = rm_par.fecha_fin
CALL control_generar_archivo()

END FUNCTION



FUNCTION control_generar_archivo()
DEFINE codloc		LIKE srit021.s21_localidad

WHILE TRUE
	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_par.fecha_ini = arg_val(5)
		LET rm_par.fecha_fin = arg_val(6)
		LET rm_par.tipo_gye  = arg_val(7)
		LET rm_par.tipo_uio  = arg_val(8)
		LET rm_par.tipo_nac  = arg_val(9)
		DISPLAY BY NAME rm_par.*
	END IF
	CALL retorna_localidad() RETURNING codloc
	CASE num_args()
		WHEN 9	CALL generar_archivo()
		WHEN 10	IF generar_archivo_s21('tmp_ane1', codloc) THEN
				IF rm_par.tipo_gye = 'S' THEN
					CALL generar_archivo_venta_xml('G',
									codloc)
					DROP TABLE tmp_ane1
				END IF
			END IF
		WHEN 11	IF generar_archivo_s21('tmp_ane2', codloc) THEN
				IF rm_par.tipo_uio = 'S' THEN
					CALL generar_archivo_venta_xml('Q',
									codloc)
					DROP TABLE tmp_ane2
				END IF
			END IF
		WHEN 12	IF generar_archivo_s21('tmp_ane3', codloc) THEN
				IF rm_par.tipo_nac = 'S' THEN
					CALL generar_archivo_venta_xml('N',
									codloc)
					DROP TABLE tmp_ane3
				END IF
			END IF
		WHEN 13	CALL generar_archivo()
			IF rm_par.tipo_gye = 'S' THEN
				CALL generar_archivo_anula_xml('G')
				DROP TABLE tmp_anu1
			END IF
		WHEN 14	CALL generar_archivo()
			IF rm_par.tipo_uio = 'S' THEN
				CALL generar_archivo_anula_xml('Q')
				DROP TABLE tmp_anu2
			END IF
		WHEN 15	CALL generar_archivo()
			IF rm_par.tipo_nac = 'S' THEN
				CALL generar_archivo_anula_xml('N')
				DROP TABLE tmp_anu3
			END IF
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
DEFINE r_s21		RECORD LIKE srit021.*
DEFINE codloc		LIKE srit021.s21_localidad

INITIALIZE r_s21.* TO NULL
CALL retorna_localidad() RETURNING codloc
DECLARE q_estado CURSOR FOR
	SELECT UNIQUE s21_estado
		FROM srit021
		WHERE s21_compania  = vg_codcia
		  AND s21_localidad = codloc
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
IF num_args() < 13 THEN
	CALL generar_anexo_tabla_temporal()
END IF
IF num_args() >= 10 AND num_args() <= 12 THEN
	RETURN
END IF
CALL obtener_anulaciones()
IF num_args() >= 13 THEN
	RETURN
END IF
CALL retorna_localidad() RETURNING codloc
IF rm_par.tipo_gye = 'S' THEN
	CALL generar_s21('tmp_ane1', codloc)
	CALL generar_unl('G', codloc)
	DROP TABLE tmp_ane1
	DROP TABLE tmp_anu1
END IF
IF rm_par.tipo_uio = 'S' THEN
	CALL generar_s21('tmp_ane2', codloc)
	CALL generar_unl('Q', codloc)
	DROP TABLE tmp_ane2
	DROP TABLE tmp_anu2
END IF
IF rm_par.tipo_nac = 'S' THEN
	CALL generar_s21('tmp_ane3', codloc)
	CALL generar_unl('N', codloc)
	DROP TABLE tmp_ane3
	DROP TABLE tmp_anu3
END IF
CALL fl_mostrar_mensaje('Anexo de Ventas generado OK.', 'info')

END FUNCTION



FUNCTION generar_archivo_s21(tabla, codloc)
DEFINE tabla		VARCHAR(10)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE query		CHAR(1200)
DEFINE expr_loc		VARCHAR(100)
DEFINE cuantos		INTEGER

LET expr_loc = '   AND s21_localidad = ', codloc
IF rm_par.tipo_nac = 'S' THEN
	LET expr_loc = NULL
END IF
LET query = 'SELECT s21_localidad loc, s21_ident_cli tipocli, ',
			's21_num_doc_id docid, s21_tipo_comp tipodoc, ',
			's21_num_comp_emi ndocs, s21_base_imp_tar_0 subtotal, ',
			's21_bas_imp_gr_iva subtotalGrav, ',
			's21_monto_iva impuesto, s21_monto_ret_rent ret ',
		' FROM srit021 ',
		' WHERE s21_compania  = ', vg_codcia,
		expr_loc CLIPPED,
		'   AND s21_anio      = ', YEAR(rm_par.fecha_fin),
		'   AND s21_mes       = ', MONTH(rm_par.fecha_fin),
		' INTO TEMP ', tabla CLIPPED
PREPARE exec_tmp_tra FROM query
EXECUTE exec_tmp_tra
LET query = 'SELECT COUNT(*) ctos FROM ', tabla CLIPPED, ' INTO TEMP t1 '
PREPARE exec_cts FROM query
EXECUTE exec_cts
SELECT * INTO cuantos FROM t1
DROP TABLE t1
IF cuantos = 0 THEN
	CALL fl_mostrar_mensaje('No se ha generado el Anexo de Ventas.', 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION lee_parametros()
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
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



FUNCTION retorna_localidad()
DEFINE codloc		LIKE srit021.s21_localidad

CASE vg_codcia
	WHEN 1 
		IF rm_par.tipo_gye = 'S' THEN
			LET codloc = 1
		END IF
		IF rm_par.tipo_uio = 'S' THEN
			LET codloc = 3
		END IF
		IF rm_par.tipo_nac = 'S' THEN
			LET codloc = vg_codloc
		END IF
	WHEN 2 
		IF rm_par.tipo_gye = 'S' THEN
			LET codloc = 6
		END IF
		IF rm_par.tipo_uio = 'S' THEN
			LET codloc = 7
		END IF
		IF rm_par.tipo_nac = 'S' THEN
			LET codloc = vg_codloc
		END IF
END CASE
RETURN codloc

END FUNCTION



FUNCTION retorna_bases(tip_ane)
DEFINE tip_ane		CHAR(1)
DEFINE base1, base2	VARCHAR(30)
DEFINE serv1, serv2	VARCHAR(10)
DEFINE serv3		VARCHAR(10)
DEFINE codloc1, codloc2	LIKE srit021.s21_localidad

CASE vg_codcia
	WHEN 1
		IF vg_servidor = 'acgyede' OR vg_servidor = 'ACUIORE' OR
		   vg_servidor = 'acuiopr'
		THEN
			LET base1 = 'aceros'
			LET serv1 = 'acgyede'
			LET serv2 = 'acuiopr'
			LET serv3 = serv2
		END IF
		IF vg_servidor = 'ACGYE01' OR vg_servidor = 'ACUIO01' THEN
			LET base1 = 'acero_gm'
			LET serv1 = 'idsgye01'
			LET serv2 = 'idsuio01'
			#LET serv3 = 'idsuio02'
			LET serv3 = 'idsuio01'
		END IF
		CASE tip_ane
			WHEN 'G'
				LET base1   = base1 CLIPPED, '@', serv1 CLIPPED,
						':'
				LET base2   = 'acero_gc@', serv1 CLIPPED, ':'
				LET codloc1 = 2
				LET codloc2 = vg_codloc
			WHEN 'Q'
				LET base1   = 'acero_qm@', serv2 CLIPPED,
						':'
				LET base2   = 'acero_qs@', serv3 CLIPPED, ':'
				LET codloc1 = 4
				LET codloc2 = 5
		END CASE
	WHEN 2
		IF vg_servidor = 'acgyede' THEN
			LET serv1 = 'acgyede'
			LET serv2 = serv1
		END IF
		IF vg_servidor = 'ACUIORE' OR vg_servidor = 'acuiopr' THEN
			LET serv1 = 'acuiopr'
			LET serv2 = serv1
		END IF
		IF vg_servidor = 'segye01' OR vg_servidor = 'seuio01' THEN
			LET serv1 = 'segye01'
			LET serv2 = 'seuio01'
		END IF
		CASE tip_ane
			WHEN 'G'
				LET base1   = 'sermaco_gm@', serv1 CLIPPED, ':'
			WHEN 'Q'
				LET base1   = 'sermaco_qm@', serv2 CLIPPED, ':'
		END CASE
		LET base2   = NULL
		LET codloc1 = 6
		LET codloc2 = 7
END CASE
RETURN base1, base2, codloc1, codloc2

END FUNCTION



FUNCTION generar_anexo_tabla_temporal()
DEFINE query		CHAR(50000)
DEFINE base1, base2	VARCHAR(30)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE codloc1, codloc2	LIKE srit021.s21_localidad

IF rm_par.tipo_gye = 'S' THEN
	LET codloc = 1
	IF vg_codcia = 2 THEN
		LET codloc = 6
	END IF
	CALL retorna_bases('G')
		RETURNING base1, base2, codloc1, codloc2
	LET query = query_anexo_ventas(base1, base2, codloc, codloc1,
					codloc2) CLIPPED,
			' ORDER BY 5 ',
			' INTO TEMP t1 '
	PREPARE exec_t1 FROM query
	EXECUTE exec_t1
	CALL genera_temp_ane('t1', 'tmp_ane1')
END IF
IF rm_par.tipo_uio = 'S' THEN
	LET codloc = 3
	IF vg_codcia = 2 THEN
		LET codloc = 7
	END IF
	CALL retorna_bases('Q')
		RETURNING base1, base2, codloc1, codloc2
	LET query = query_anexo_ventas(base1, base2, codloc, codloc1,
					codloc2) CLIPPED,
			' ORDER BY 5 ',
			' INTO TEMP t2 '
	PREPARE exec_t2 FROM query
	EXECUTE exec_t2
	CALL genera_temp_ane('t2', 'tmp_ane2')
END IF
IF rm_par.tipo_nac = 'S' THEN
	LET codloc = 1
	IF vg_codcia = 2 THEN
		LET codloc = 6
	END IF
	CALL retorna_bases('G')
		RETURNING base1, base2, codloc1, codloc2
	LET query = query_anexo_ventas(base1, base2, codloc, codloc1,
					codloc2) CLIPPED
	LET codloc = 3
	IF vg_codcia = 2 THEN
		LET codloc = 7
	END IF
	CALL retorna_bases('Q')
		RETURNING base1, base2, codloc1, codloc2
	LET query = query CLIPPED,
			' UNION ',
		query_anexo_ventas(base1, base2, codloc, codloc1,
					codloc2) CLIPPED,
			' ORDER BY 5 ',
			' INTO TEMP t3 '
	PREPARE exec_t3 FROM query
	EXECUTE exec_t3
	CALL genera_temp_ane('t3', 'tmp_ane3')
END IF

END FUNCTION



FUNCTION query_anexo_ventas(base1, base2, codloc, codloc1, codloc2)
DEFINE query		CHAR(22000)
DEFINE base1, base2	VARCHAR(30)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE codloc1, codloc2	LIKE srit021.s21_localidad

LET query = 'SELECT "18" tipodoc, r19_localidad loc, "9999" codcli, ',
		'CASE WHEN r19_codcli = 99 ',
			'THEN "9999999999999" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = r19_codcli) = "R" ',
			'AND LENGTH(r19_cedruc) = 13 ',
			'THEN r19_cedruc ',
		      'ELSE "9999999999999" ',
		'END docid, ',
		'CASE WHEN r19_codcli = 99 ',
			'THEN "CONSUMIDOR FINAL" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = r19_codcli) = "R" ',
			'AND LENGTH(r19_cedruc) = 13 ',
			'THEN r19_nomcli ',
		     'ELSE "CONSUMIDOR FINAL" ',
		'END nomcli, ',
		'SUM(CASE WHEN r19_cod_tran = "FA" THEN 1 ELSE -1 END) ndocs, ',
		'SUM(CASE WHEN r19_cod_tran = "FA" AND r19_porc_impto = 0 ',
				'THEN r19_tot_neto ',
			 'WHEN r19_cod_tran = "AF" AND r19_porc_impto = 0 ',
				'THEN r19_tot_neto * (-1) ',
			 'WHEN r19_cod_tran = "FA" AND r19_porc_impto = 12 ',
				'THEN r19_flete ',
			 'WHEN r19_cod_tran = "AF" AND r19_porc_impto = 12 ',
				'THEN r19_flete * (-1) ',
			 'ELSE 0 ',
			'END) subtotal, ',
		'SUM(CASE WHEN r19_cod_tran = "FA" AND r19_porc_impto <> 0 ',
				'THEN (r19_tot_bruto - r19_tot_dscto) ',
			 'WHEN r19_cod_tran = "AF" AND r19_porc_impto <> 0 ',
				'THEN (r19_tot_bruto - r19_tot_dscto) * (-1) ',
			 'ELSE 0 ',
			'END) subtotalGrav, ',
		'SUM(CASE WHEN r19_cod_tran = "FA" ',
				'THEN (r19_tot_neto - r19_tot_bruto + ',
					'r19_tot_dscto - r19_flete) ',
				'ELSE (r19_tot_neto - r19_tot_bruto + ',
					'r19_tot_dscto - r19_flete) * (-1) ',
			'END) impuesto, ',
		'SUM(r19_tot_neto) total, 0 ret ',
		' FROM ', base1 CLIPPED, 'rept019 ',
		' WHERE r19_compania   = ', vg_codcia,
		'   AND r19_localidad IN (', codloc, ', ', codloc2, ') ',
		'   AND r19_cod_tran  IN ("FA", "NV", "AF") ',
		'   AND EXTEND(r19_fecing, YEAR TO MONTH) = ',
			'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH)',
		' GROUP BY 1, 2, 3, 4, 5, 11 ',
	'UNION ALL ',
	'SELECT "18" tipodoc, r19_localidad loc, "9999" codcli, ',
		'CASE WHEN r19_codcli = 99 ',
			'THEN "9999999999999" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base2 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = r19_codcli) = "R" ',
			'AND LENGTH(r19_cedruc) = 13 ',
			'THEN r19_cedruc ',
		      'ELSE "9999999999999" ',
		'END docid, ',
		'CASE WHEN r19_codcli = 99 ',
			'THEN "CONSUMIDOR FINAL" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base2 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = r19_codcli) = "R" ',
			'AND LENGTH(r19_cedruc) = 13 ',
			'THEN r19_nomcli ',
		     'ELSE "CONSUMIDOR FINAL" ',
		'END nomcli, ',
		'SUM(CASE WHEN r19_cod_tran = "FA" THEN 1 ELSE -1 END) ndocs, ',
		'SUM(CASE WHEN r19_cod_tran = "FA" AND r19_porc_impto = 0 ',
				'THEN r19_tot_neto ',
			 'WHEN r19_cod_tran = "AF" AND r19_porc_impto = 0 ',
				'THEN r19_tot_neto * (-1) ',
			 'WHEN r19_cod_tran = "FA" AND r19_porc_impto = 12 ',
				'THEN r19_flete ',
			 'WHEN r19_cod_tran = "AF" AND r19_porc_impto = 12 ',
				'THEN r19_flete * (-1) ',
			 'ELSE 0 ',
			'END) subtotal, ',
		'SUM(CASE WHEN r19_cod_tran = "FA" AND r19_porc_impto <> 0 ',
				'THEN (r19_tot_bruto - r19_tot_dscto) ',
			 'WHEN r19_cod_tran = "AF" AND r19_porc_impto <> 0 ',
				'THEN (r19_tot_bruto - r19_tot_dscto) * (-1) ',
			 'ELSE 0 ',
			'END) subtotalGrav, ',
		'SUM(CASE WHEN r19_cod_tran = "FA" ',
				'THEN (r19_tot_neto - r19_tot_bruto + ',
					'r19_tot_dscto - r19_flete) ',
				'ELSE (r19_tot_neto - r19_tot_bruto + ',
					'r19_tot_dscto - r19_flete) * (-1) ',
			'END) impuesto, ',
		'SUM(r19_tot_neto) total, 0 ret ',
		' FROM ', base2 CLIPPED, 'rept019 ',
		' WHERE r19_compania   = ', vg_codcia,
		'   AND r19_localidad  = ', codloc1,
		'   AND r19_cod_tran  IN ("FA", "NV", "AF") ',
		'   AND EXTEND(r19_fecing, YEAR TO MONTH) = ',
			'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH)',
		' GROUP BY 1, 2, 3, 4, 5, 11 ',
	'UNION ALL ',
	'SELECT "18" tipodoc, t23_localidad loc, "9999" codcli, ',
		'CASE WHEN t23_cod_cliente = 99 ',
			'THEN "9999999999999" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = t23_cod_cliente) = "R" ',
			'AND LENGTH(t23_cedruc) = 13 ',
			'THEN t23_cedruc ',
		     'ELSE "9999999999999" ',
		'END docid, ',
		'CASE WHEN t23_cod_cliente = 99 ',
			'THEN "CONSUMIDOR FINAL" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = t23_cod_cliente) = "R" ',
			'AND LENGTH(t23_cedruc) = 13 ',
			'THEN t23_nom_cliente ',
		     'ELSE "CONSUMIDOR FINAL" ',
		'END nomcli, ',
		'COUNT(*) ndocs, ',
		'SUM(CASE WHEN t23_porc_impto = 0 ',
				'THEN CASE WHEN t23_estado = "F" ',
					'THEN ',
				'NVL((SELECT NVL(SUM(ROUND((c11_precio - ',
						'c11_val_descto) * (1 + ',
						'c10_recargo / 100), 2)), 0) ',
				'FROM ', base1 CLIPPED, 'ordt010, ',
					base1 CLIPPED, 'ordt011 ',
				'WHERE c10_compania    = t23_compania ',
				'  AND c10_localidad   = t23_localidad ',
				'  AND c10_ord_trabajo = t23_orden ',
				'  AND c10_estado      = "C" ',
				'  AND c11_compania    = c10_compania ',
				'  AND c11_localidad   = c10_localidad ',
				'  AND c11_numero_oc   = c10_numero_oc ',
				'  AND c11_tipo        = "S"), 0) + ',
				'NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * ',
					'c11_precio) - c11_val_descto) ',
					'* (1 + c10_recargo / 100), 2)),0) ',
				'FROM ', base1 CLIPPED, 'ordt010, ',
					base1 CLIPPED, 'ordt011 ',
				'WHERE c10_compania    = t23_compania ',
				'  AND c10_localidad   = t23_localidad ',
				'  AND c10_ord_trabajo = t23_orden ',
				'  AND c10_estado      = "C" ',
				'  AND c11_compania    = c10_compania ',
				'  AND c11_localidad   = c10_localidad ',
				'  AND c11_numero_oc   = c10_numero_oc ',
				'  AND c11_tipo        = "B"), 0) + ',
				'CASE WHEN (SELECT COUNT(*) ',
				'FROM ', base1 CLIPPED, 'ordt010 ',
				'WHERE c10_compania    = t23_compania ',
				'  AND c10_localidad   = t23_localidad ',
				'  AND c10_ord_trabajo = t23_orden ',
				'  AND c10_estado      = "C") = 0 ',
				'THEN (t23_val_mo_ext + t23_val_mo_cti + ',
					't23_val_rp_tal + t23_val_rp_ext + ',
					't23_val_rp_cti + t23_val_otros2) ',
			'ELSE 0.00 ',
		'END ',
		'+ (t23_val_mo_tal - t23_vde_mo_tal) ',
		'WHEN t23_estado = "D" ',
			'THEN ',
		'NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto) ',
				'* (1 + c10_recargo / 100), 2)), 0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "S" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura), 0) + ',
		'NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio) ',
				'- c11_val_descto) * (1 + c10_recargo / 100), ',
				'2)), 0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "B" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura), 0) + ',
			'CASE WHEN (SELECT COUNT(*) ',
				'FROM ', base1 CLIPPED, 'ordt010, ',
					base1 CLIPPED, 'talt028 ',
				'WHERE c10_compania    = t23_compania ',
				'  AND c10_localidad   = t23_localidad ',
				'  AND c10_ord_trabajo = t28_ot_nue ',
				'  AND c10_estado      = "C" ',
				'  AND t28_compania    = t23_compania ',
				'  AND t28_localidad   = t23_localidad ',
				'  AND t23_num_factura = t28_factura) = 0 ',
				'THEN (t23_val_mo_ext + t23_val_mo_cti + ',
					't23_val_rp_tal + t23_val_rp_ext + ',
					't23_val_rp_cti	+ t23_val_otros2) ',
			     'ELSE 0.00 ',
			'END ',
			'+ (t23_val_mo_tal - t23_vde_mo_tal) ',
			'ELSE 0.00 ',
			'END ',
		'ELSE 0.00 ',
		'END) subtotal, ',
		'SUM(CASE WHEN t23_porc_impto <> 0 ',
			'THEN CASE WHEN t23_estado = "F" ',
				'THEN ',
		'NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto) ',
				'* (1 + c10_recargo / 100), 2)), 0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t23_orden ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "S"), 0) + ',
		'NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio) ',
				'- c11_val_descto) * (1 + c10_recargo / 100), ',
				'2)), 0) ',
				'FROM ', base1 CLIPPED, 'ordt010, ',
					base1 CLIPPED, 'ordt011 ',
				'WHERE c10_compania    = t23_compania ',
				'  AND c10_localidad   = t23_localidad ',
				'  AND c10_ord_trabajo = t23_orden ',
				'  AND c10_estado      = "C" ',
				'  AND c11_compania    = c10_compania ',
				'  AND c11_localidad   = c10_localidad ',
				'  AND c11_numero_oc   = c10_numero_oc ',
				'  AND c11_tipo        = "B"), 0) + ',
			'CASE WHEN (SELECT COUNT(*) ',
				'FROM ', base1 CLIPPED, 'ordt010 ',
				'WHERE c10_compania    = t23_compania ',
				'  AND c10_localidad   = t23_localidad ',
				'  AND c10_ord_trabajo = t23_orden ',
				'  AND c10_estado      = "C") = 0 ',
				'THEN (t23_val_mo_ext + t23_val_mo_cti + ',
					't23_val_rp_tal + t23_val_rp_ext + ',
					't23_val_rp_cti + t23_val_otros2) ',
				'ELSE 0.00 ',
			'END ',
			'+ (t23_val_mo_tal - t23_vde_mo_tal) ',
		'WHEN t23_estado = "D" ',
			'THEN ',
		'NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto) ',
				'* (1 + c10_recargo / 100), 2)), 0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "S" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura), 0) + ',
		'NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio) ',
			'- c11_val_descto) * (1 + c10_recargo / 100), 2)),0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
		  	'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "B" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura), 0) + ',
		'CASE WHEN (SELECT COUNT(*) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura) = 0 ',
			'THEN (t23_val_mo_ext + t23_val_mo_cti + ',
				't23_val_rp_tal + t23_val_rp_ext + ',
				't23_val_rp_cti + t23_val_otros2) ',
			'ELSE 0.00 ',
			'END ',
			'+ (t23_val_mo_tal - t23_vde_mo_tal) ',
			'ELSE 0.00 ',
			'END ',
		'ELSE 0.00 ',
	'END)  subtotalGrav, ',
	'SUM(t23_val_impto) impuesto, ',
	'SUM(t23_tot_neto)  neto, 0 ret	',
	' FROM ', base1 CLIPPED, 'talt023 ',
	' WHERE t23_compania          = ', vg_codcia,
	'   AND t23_localidad        IN (', codloc, ', ', codloc2, ') ',
	'   AND (t23_estado           = "F" ',
	'    OR (t23_estado           = "D" ',
	'   AND DATE(t23_fec_factura) < ',
		'(SELECT DATE(t28_fec_anula) ',
			'FROM ', base1 CLIPPED, 'talt028 ',
			'WHERE t23_compania      = t28_compania ',
			'  AND t23_localidad     = t28_localidad ',
			'  AND t23_num_factura   = t28_factura))) ',
	'   AND EXTEND(t23_fec_factura, YEAR TO MONTH) = ',
		'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH) ',
	' GROUP BY 1, 2, 3, 4, 5, 11 ',
	'UNION ALL ',
	'SELECT "04" tipodoc, r19_localidad loc, "9999" codcli, ',
		'CASE WHEN r19_codcli = 99 ',
			'THEN "9999999999999" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = r19_codcli) = "R" ',
			'AND LENGTH(r19_cedruc) = 13 ',
			'THEN r19_cedruc ',
		     'ELSE "9999999999999" ',
		'END docid, ',
		'CASE WHEN r19_codcli = 99 ',
			'THEN "CONSUMIDOR FINAL" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = r19_codcli) = "R" ',
			'AND LENGTH(r19_cedruc) = 13 ',
			'THEN r19_nomcli ',
		     'ELSE "CONSUMIDOR FINAL" ',
		'END nomcli, ',
		'SUM(1) ndocs, ',
		'SUM(CASE WHEN r19_cod_tran = "DF" AND r19_porc_impto = 0 ',
				'THEN r19_tot_neto ',
			 'WHEN r19_cod_tran = "DF" AND r19_porc_impto = 12 ',
				'THEN r19_flete ',
			 'ELSE 0 ',
			'END) subtotal, ',
		'SUM(CASE WHEN r19_cod_tran = "DF" AND r19_porc_impto <> 0 ',
				'THEN (r19_tot_bruto - r19_tot_dscto) ',
			 'ELSE 0 ',
			'END) subtotalGrav, ',
		'SUM(CASE WHEN r19_cod_tran = "DF" ',
				'THEN (r19_tot_neto - r19_tot_bruto + ',
					'r19_tot_dscto - r19_flete) ',
			 'ELSE 0 ',
			'END) impuesto, ',
		'SUM(r19_tot_neto) total, 0 ret ',
		' FROM ', base1 CLIPPED, 'rept019 ',
		' WHERE r19_compania      = ', vg_codcia,
		'   AND r19_localidad    IN (', codloc, ', ', codloc2, ') ',
		'   AND r19_cod_tran     IN ("DF") ',
		'   AND EXTEND(r19_fecing, YEAR TO MONTH) = ',
			'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH)',
		' GROUP BY 1, 2, 3, 4, 5, 11 ',
	'UNION ALL ',
	'SELECT "04" tipodoc, r19_localidad loc, "9999" codcli, ',
		'CASE WHEN r19_codcli = 99 ',
			'THEN "9999999999999" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base2 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = r19_codcli) = "R" ',
			'AND LENGTH(r19_cedruc) = 13 ',
			'THEN r19_cedruc ',
		     'ELSE "9999999999999" ',
		'END docid, ',
		'CASE WHEN r19_codcli = 99 ',
			'THEN "CONSUMIDOR FINAL" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base2 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = r19_codcli) = "R" ',
			'AND LENGTH(r19_cedruc) = 13 ',
			'THEN r19_nomcli ',
		     'ELSE "CONSUMIDOR FINAL" ',
		'END nomcli, ',
		'SUM(1) ndocs, ',
		'SUM(CASE WHEN r19_cod_tran = "DF" AND r19_porc_impto = 0 ',
				'THEN r19_tot_neto ',
			 'WHEN r19_cod_tran = "DF" AND r19_porc_impto = 12 ',
				'THEN r19_flete ',
			 'ELSE 0 ',
			'END) subtotal, ',
		'SUM(CASE WHEN r19_cod_tran = "DF" AND r19_porc_impto <> 0 ',
				'THEN (r19_tot_bruto - r19_tot_dscto) ',
			 'ELSE 0 ',
			'END) subtotalGrav, ',
		'SUM(CASE WHEN r19_cod_tran = "DF" ',
				'THEN (r19_tot_neto - r19_tot_bruto + ',
					'r19_tot_dscto - r19_flete) ',
			 'ELSE 0 ',
			'END) impuesto, ',
		'SUM(r19_tot_neto) total, 0 ret ',
		' FROM ', base2 CLIPPED, 'rept019 ',
		' WHERE r19_compania      = ', vg_codcia,
		'   AND r19_localidad     = ', codloc1,
		'   AND r19_cod_tran     IN ("DF") ',
		'   AND EXTEND(r19_fecing, YEAR TO MONTH) = ',
			'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH)',
		' GROUP BY 1, 2, 3, 4, 5, 11 ',
	'UNION ALL ',
	'SELECT "04" tipodoc, t23_localidad loc, "9999" codcli, ',
		'CASE WHEN t23_cod_cliente = 99 ',
			'THEN "9999999999999" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = t23_cod_cliente) = "R" ',
			'AND LENGTH(t23_cedruc) = 13 ',
			'THEN t23_cedruc ',
		     'ELSE "9999999999999" ',
		'END docid, ',
		'CASE WHEN t23_cod_cliente = 99 ',
			'THEN "CONSUMIDOR FINAL" ',
		     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = t23_cod_cliente) = "R" ',
			'AND LENGTH(t23_cedruc) = 13 ',
			'THEN t23_nom_cliente ',
		     'ELSE "CONSUMIDOR FINAL" ',
		'END nomcli, ',
		'COUNT(*) ndocs, ',
		'SUM(CASE WHEN t23_porc_impto = 0 ',
			'THEN ',
			'CASE WHEN t23_estado = "D" ',
			'THEN ',
		'NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto) ',
				'* (1 + c10_recargo / 100), 2)), 0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "S" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura), 0) + ',
		'NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio) ',
				'- c11_val_descto) * (1 + c10_recargo / 100), ',
				'2)), 0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "B" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura), 0) + ',
		'CASE WHEN (SELECT COUNT(*) ',
				'FROM ', base1 CLIPPED, 'ordt010, ',
					base1 CLIPPED, 'talt028 ',
				'WHERE c10_compania    = t23_compania ',
				'  AND c10_localidad   = t23_localidad ',
				'  AND c10_ord_trabajo = t28_ot_nue ',
				'  AND c10_estado      = "C" ',
				'  AND t28_compania    = t23_compania ',
				'  AND t28_localidad   = t23_localidad ',
				'  AND t23_num_factura = t28_factura) = 0 ',
			'THEN (t23_val_mo_ext + t23_val_mo_cti + ',
				't23_val_rp_tal + t23_val_rp_ext + ',
				't23_val_rp_cti + t23_val_otros2) ',
			'ELSE 0.00 ',
		'END ',
		'+ (t23_val_mo_tal - t23_vde_mo_tal) ',
		'ELSE 0.00 ',
		'END ',
		'ELSE 0.00 ',
	'END) subtotal, ',
	'SUM(CASE WHEN t23_porc_impto <> 0 THEN	',
		'CASE WHEN t23_estado = "D" THEN ',
		'NVL((SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto) ',
			'* (1 + c10_recargo / 100), 2)), 0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "S" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura), 0) + ',
		'NVL((SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio) ',
			'- c11_val_descto) * (1 + c10_recargo / 100), 2)), 0) ',
			'FROM ', base1 CLIPPED, 'ordt010, ',
				base1 CLIPPED, 'ordt011, ',
				base1 CLIPPED, 'talt028 ',
			'WHERE c10_compania    = t23_compania ',
			'  AND c10_localidad   = t23_localidad ',
			'  AND c10_ord_trabajo = t28_ot_nue ',
			'  AND c10_estado      = "C" ',
			'  AND c11_compania    = c10_compania ',
			'  AND c11_localidad   = c10_localidad ',
			'  AND c11_numero_oc   = c10_numero_oc ',
			'  AND c11_tipo        = "B" ',
			'  AND t28_compania    = t23_compania ',
			'  AND t28_localidad   = t23_localidad ',
			'  AND t23_num_factura = t28_factura), 0) + ',
			'CASE WHEN (SELECT COUNT(*) ',
				'FROM ', base1 CLIPPED, 'ordt010, ',
					base1 CLIPPED, 'talt028 ',
				'WHERE c10_compania    = t23_compania ',
				'  AND c10_localidad   = t23_localidad ',
				'  AND c10_ord_trabajo = t28_ot_nue ',
				'  AND c10_estado      = "C" ',
				'  AND t28_compania    = t23_compania ',
				'  AND t28_localidad   = t23_localidad ',
				'  AND t23_num_factura = t28_factura) = 0 ',
				'THEN (t23_val_mo_ext + t23_val_mo_cti + ',
					't23_val_rp_tal + t23_val_rp_ext + ',
					't23_val_rp_cti + t23_val_otros2) ',
				'ELSE 0.00 ',
			'END ',
			'+ (t23_val_mo_tal - t23_vde_mo_tal) ',
			'ELSE 0.00 ',
		'END ',
		'ELSE 0.00 ',
		'END) subtotalGrav, ',
		'SUM(t23_val_impto) impuesto, ',
		'SUM(t23_tot_neto) neto, 0 ret ',
	'FROM ', base1 CLIPPED, 'talt023, ', base1 CLIPPED, 'talt028 ',
	'WHERE t23_compania                         = ', vg_codcia,
	'  AND t23_localidad                       IN (', codloc, ', ',
								codloc2, ') ',
	'  AND t23_estado                           = "D" ',
	'  AND t23_compania                         = t28_compania ',
	'  AND t23_localidad                        = t28_localidad ',
	'  AND t23_num_factura                      = t28_factura ',
	'  AND EXTEND(t28_fec_anula, YEAR TO MONTH) = ',
		'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH) ',
	'  AND DATE(t23_fec_factura) <  DATE(t28_fec_anula) ',
	'GROUP BY 1, 2, 3, 4, 5, 11 ',
	'UNION ALL ',
	'SELECT "04" tipodoc, z21_localidad loc, "9999" codcli, ',
	'CASE WHEN z21_codcli = 99 ',
		'THEN "9999999999999" ',
	     'WHEN z01_tipo_doc_id = "R" AND LENGTH(z01_num_doc_id) = 13 ',
		'THEN z01_num_doc_id ',
		'ELSE "9999999999999" ',
	'END docid, ',
	'CASE WHEN z21_codcli = 99 ',
		'THEN "CONSUMIDOR FINAL" ',
	     'WHEN z01_tipo_doc_id  = "R" AND LENGTH(z01_num_doc_id) = 13 ',
		'THEN z01_nomcli ',
		'ELSE "CONSUMIDOR FINAL" ',
	'END nomcli, ',
	'SUM(1) ndocs, ',
	'SUM(CASE WHEN z21_val_impto = 0 ',
		'THEN z21_valor ',
		'ELSE 0 ',
	'END) subtotal, ',
	'SUM(CASE WHEN z21_val_impto <> 0 ',
		'THEN (z21_valor - z21_val_impto) ',
		'ELSE 0 ',
	'END) subtotalGrav, ',
	'SUM(z21_val_impto) impuesto, ',
	'SUM(z21_valor + z21_val_impto) neto, 0 ret ',
	'FROM ', base1 CLIPPED, 'cxct021, ', base1 CLIPPED, 'cxct001 ',
	'WHERE z21_compania   = ', vg_codcia,
	'  AND z21_localidad IN (', codloc, ', ', codloc1, ', ',codloc2,') ',
	'  AND z21_tipo_doc   = "NC" ',
	'  AND z21_origen     = "M" ',
	'  AND z01_codcli     = z21_codcli ',
	'  AND EXTEND(z21_fecha_emi, YEAR TO MONTH) = ',
		'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH) ',
	'GROUP BY 1, 2, 3, 4, 5 ',
	'UNION ALL ',
	'SELECT "05" tipodoc, z20_localidad loc, "9999" codcli, ',
	'CASE WHEN z20_codcli = 99 ',
		'THEN "9999999999999" ',
	     'WHEN z01_tipo_doc_id = "R" AND LENGTH(z01_num_doc_id) = 13 ',
		'THEN z01_num_doc_id ',
		'ELSE "9999999999999"',
	'END docid, ',
	'CASE WHEN z20_codcli = 99 ',
		'THEN "CONSUMIDOR FINAL" ',
	     'WHEN z01_tipo_doc_id  = "R" AND LENGTH(z01_num_doc_id) = 13 ',
		'THEN z01_nomcli ',
		'ELSE "CONSUMIDOR FINAL" ',
	'END nomcli, ',
	'SUM(1) ndocs, ',
	'SUM(CASE WHEN z20_val_impto = 0 ',
		'THEN z20_valor_cap ',
		'ELSE 0 ',
	'END) subtotal, ',
	'SUM(CASE WHEN z20_val_impto <> 0 ',
		'THEN (z20_valor_cap - z20_val_impto) ',
		'ELSE 0 ',
	'END) subtotalGrav, ',
	'SUM(z20_val_impto) impuesto, ',
	'SUM(z20_valor_cap) neto, 0 ret ',
	'FROM ', base1 CLIPPED, 'cxct020, ', base1 CLIPPED, 'cxct001 ',
	'WHERE z20_compania   = ', vg_codcia,
	'  AND z20_localidad IN (', codloc, ', ', codloc1, ', ', codloc2,')',
	'  AND z20_tipo_doc   = "ND" ',
	'  AND z20_origen     = "M" ',
	'  AND z01_codcli     = z20_codcli ',
	'  AND EXTEND(z20_fecha_emi, YEAR TO MONTH) = ',
		'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH) ',
	'GROUP BY 1, 2, 3, 4, 5 ',
	'UNION ALL ',
	'SELECT "18" tipodoc, ', codloc, ' loc, "9999" codcli, ',
	'CASE WHEN b13_codcli = 99 ',
		'THEN "9999999999999" ',
	     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = b13_codcli) = "R" ',
			'AND LENGTH(z01_num_doc_id) = 13 ',
		'THEN z01_num_doc_id ',
		'ELSE "9999999999999" ',
	'END docid, ',
	'CASE WHEN b13_codcli = 99 ',
		'THEN "CONSUMIDOR FINAL" ',
	     'WHEN (SELECT DISTINCT z01_tipo_doc_id ',
				'FROM ', base1 CLIPPED, 'cxct001 ',
				'WHERE z01_codcli = b13_codcli) = "R" ',
			'AND LENGTH(z01_num_doc_id) = 13 ',
		'THEN z01_nomcli ',
		'ELSE "CONSUMIDOR FINAL" ',
	'END nomcli, ',
	'0 ndocs, 0 subtotal, 0 subtotalGrav, 0 impuesto, 0 total, ',
	'NVL(SUM(b13_valor_base), 0) ret ',
	'FROM ', base1 CLIPPED, 'ctbt012, ', base1 CLIPPED, 'ctbt013, ',
		base1 CLIPPED, 'cxct001 ',
	'WHERE b12_compania                           = ', vg_codcia,
	'  AND z01_codcli                             = b13_codcli ',
	'  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) = ',
		'EXTEND(DATE("', rm_par.fecha_fin, '"), YEAR TO MONTH) ',
	'  AND b12_estado                             <> "E" ',
	'  AND b12_compania	                      = b13_compania ',
	'  AND b12_tipo_comp                          = b13_tipo_comp ',
	'  AND b12_num_comp                           = b13_num_comp ',
	'  AND b13_cuenta                             MATCHES "113*" ',
	'  AND (b13_cuenta                            IN ',
		'(SELECT UNIQUE z09_aux_cont ',
			'FROM ', base1 CLIPPED, 'cxct009 ',
			'WHERE z09_codigo_pago <> "RI" ',
			'  AND z09_aux_cont    IS NOT NULL) ',
	'   OR  b13_cuenta                            IN ',
		'(SELECT UNIQUE j91_aux_cont ',
			'FROM ', base1 CLIPPED, 'ordt002, ',
				base1 CLIPPED, 'cajt091 ',
			'WHERE c02_compania     = j91_compania ',
			'  AND c02_tipo_ret     = j91_tipo_ret ',
			'  AND c02_porcentaje   = j91_porcentaje ',
			'  AND j91_codigo_pago <> "RI" ',
			'  AND j91_aux_cont    IS NOT NULL) ',
	'   OR  b13_cuenta                            IN ',
		'(SELECT UNIQUE j01_aux_cont ',
			'FROM ', base1 CLIPPED, 'cajt001 ',
			'WHERE j01_retencion    = "S" ',
			'  AND j01_codigo_pago <> "RI" ',
			'  AND j01_aux_cont    IS NOT NULL)) ',
	'GROUP BY 1, 2, 3, 4, 5 '
	--'ORDER BY 5 '
RETURN query CLIPPED

END FUNCTION



FUNCTION generar_s21(tabla, codloc)
DEFINE tabla		VARCHAR(10)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE query		CHAR(1500)
DEFINE expr_loc		VARCHAR(100)

BEGIN WORK
WHENEVER ERROR CONTINUE
LET expr_loc = '  AND s21_localidad = ', codloc
IF rm_par.tipo_nac = 'S' THEN
	LET expr_loc = NULL
END IF
LET query = 'DELETE FROM srit021 ',
		'WHERE s21_compania  = ', vg_codcia,
		expr_loc CLIPPED,
		'  AND s21_anio      = ', YEAR(rm_par.fecha_fin),
		'  AND s21_mes       = ', MONTH(rm_par.fecha_fin),
		--'  AND s21_estado    = "G"'
		'  AND s21_estado    IN ("P", "G")'
PREPARE elim_s21 FROM query
EXECUTE elim_s21
IF STATUS <> 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se ha podido eliminar los datos del anexo que ya estaban generados en la tabla de Anexo Transacional. Por favor llame al ADMINISTRADOR.', 'exclamation')
	ROLLBACK WORK
	RETURN
END IF
LET expr_loc = ' WHERE loc = ', codloc
IF rm_par.tipo_nac = 'S' THEN
	LET expr_loc = NULL
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
		' SELECT ', vg_codcia, ', loc, ', YEAR(rm_par.fecha_fin), ', ',
			MONTH(rm_par.fecha_fin),', LPAD(tipocli, 2, 0), docid,',
			' tipodoc, "', rm_par.fecha_fin, '", ndocs, "',
			rm_par.fecha_fin, '", subtotal, "N", subtotalGrav, ',
			'"2", impuesto, 0.00, "0", 0.00, 0.00, "0", 0.00, ',
			'0.00, "0", 0.00, "N", "000", 0.00, 0.00, ret, "G", "',
			UPSHIFT(vg_usuario) CLIPPED, '", CURRENT ',
			' FROM ', tabla CLIPPED,
			expr_loc CLIPPED
PREPARE exec_s21 FROM query
EXECUTE exec_s21
WHENEVER ERROR STOP
COMMIT WORK

END FUNCTION



FUNCTION genera_temp_ane(tabla, tab_tmp)
DEFINE tabla		VARCHAR(5)
DEFINE tab_tmp		VARCHAR(10)
DEFINE query		CHAR(500)

LET query = 'SELECT CASE WHEN loc IN (1, 2) THEN 1 ',
				'WHEN loc IN (3, 4, 5) THEN 3 ',
				'ELSE loc ',
			'END loc, ',
		'CASE WHEN ret > 0 ',
				'THEN "18" ',
			'WHEN ret < 0 ',
				'THEN "04" ',
			'ELSE tipodoc ',
		'END tipodoc, ',
		'CASE WHEN TRIM(docid) = "9999999999999" ',
			'THEN 7 ',
			'ELSE 4 ',
		'END tipocli, ',
		'codcli, docid, ',
		'SUM(ndocs) ndocs, SUM(subtotal) subtotal, ',
		'SUM(subtotalgrav) subtotalGrav, ',
		'SUM(impuesto) impuesto, ',
		'SUM(total) total, ',
		'SUM(ABS(ret)) ret ',
		' FROM ', tabla CLIPPED,
		' GROUP BY 1, 2, 3, 4, 5 ',
		' ORDER BY 5 ',
		' INTO TEMP ', tab_tmp CLIPPED
PREPARE exec_tmp_ane FROM query
EXECUTE exec_tmp_ane

END FUNCTION



FUNCTION obtener_anulaciones()
DEFINE query		CHAR(60000)
DEFINE base1, base2	VARCHAR(30)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE codloc1, codloc2	LIKE srit021.s21_localidad

IF rm_par.tipo_gye = 'S' THEN
	LET codloc = 1
	IF vg_codcia = 2 THEN
		LET codloc = 6
	END IF
	CALL retorna_bases('G')
		RETURNING base1, base2, codloc1, codloc2
	LET query = query_anuladas_inv(base1, codloc, codloc1, codloc2) CLIPPED,
			' UNION ',
			query_anuladas_inv(base2, codloc, codloc1,
						codloc2) CLIPPED,
			' UNION ',
			query_anuladas_tal(base2, codloc, codloc1,
						codloc2) CLIPPED,
		' INTO TEMP tmp_anu1 '
	PREPARE cons_tmp_anu_g FROM query 
	EXECUTE cons_tmp_anu_g
END IF
IF rm_par.tipo_uio = 'S' THEN
	LET codloc = 3
	IF vg_codcia = 2 THEN
		LET codloc = 7
	END IF
	CALL retorna_bases('Q')
		RETURNING base1, base2, codloc1, codloc2
	LET query = query_anuladas_inv(base1, codloc, codloc1, codloc2) CLIPPED,
			' UNION ',
			query_anuladas_inv(base2, codloc, codloc1,
						codloc2) CLIPPED,
			' UNION ',
			query_anuladas_tal(base2, codloc, codloc1,
						codloc2) CLIPPED,
		' INTO TEMP tmp_anu2 '
	PREPARE cons_tmp_anu_q FROM query 
	EXECUTE cons_tmp_anu_q
END IF
IF rm_par.tipo_nac = 'S' THEN
	LET codloc = 1
	IF vg_codcia = 2 THEN
		LET codloc = 6
	END IF
	CALL retorna_bases('G')
		RETURNING base1, base2, codloc1, codloc2
	LET query = query_anuladas_inv(base1, codloc, codloc1,
						codloc2) CLIPPED,
			' UNION ',
			query_anuladas_inv(base2, codloc, codloc1,
						codloc2) CLIPPED,
			' UNION ',
			query_anuladas_tal(base2, codloc, codloc1,
						codloc2) CLIPPED
	LET codloc = 3
	IF vg_codcia = 2 THEN
		LET codloc = 7
	END IF
	CALL retorna_bases('Q')
		RETURNING base1, base2, codloc1, codloc2
	LET query = query CLIPPED,
			' UNION ',
			query_anuladas_inv(base1, codloc, codloc1,
						codloc2) CLIPPED,
			' UNION ',
			query_anuladas_inv(base2, codloc, codloc1,
						codloc2) CLIPPED,
			' UNION ',
			query_anuladas_tal(base2, codloc, codloc1,
						codloc2) CLIPPED,
		' INTO TEMP tmp_anu3 '
	PREPARE cons_tmp_anu_n FROM query 
	EXECUTE cons_tmp_anu_n
END IF

END FUNCTION



FUNCTION query_anuladas_inv(bas_ser, codloc, codloc1, codloc2)
DEFINE bas_ser		VARCHAR(30)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE codloc1, codloc2	LIKE srit021.s21_localidad
DEFINE query		CHAR(2000)

LET query = 'SELECT CASE WHEN LENGTH(CASE WHEN LENGTH(r19_cedruc) = 13 AND ',
				' r19_codcli <> ', rm_r00.r00_codcli_tal,
					' THEN r19_cedruc ',
					' ELSE "9999999999999" ',
				'END) = 13 ',
			'AND fp_digito_veri(',
				'CASE WHEN LENGTH(r19_cedruc) = 13 AND',
				' r19_codcli <> ', rm_r00.r00_codcli_tal,
					' THEN r19_cedruc ',
					' ELSE "9999999999999" ',
				'END) = 1 ',
			'THEN 1 ',
			'ELSE 2 ',
		'END tipo_comp, ',
		' b.g37_pref_sucurs, b.g37_pref_pto_vta, r38_num_sri[9, 16]',
		' num_sri_ini, r38_num_sri[9, 16] num_sri_fin, g02_numaut_sri,',
		'"', rm_par.fecha_fin, '" fecha ',
		' FROM ', bas_ser CLIPPED, 'rept019, ',
			bas_ser CLIPPED, 'cxct001, ',
			bas_ser CLIPPED, 'rept038, ',
			bas_ser CLIPPED, 'gent037 b, ',
			bas_ser CLIPPED, 'gent002 ',
		' WHERE r19_compania      = ', vg_codcia,
		'   AND r19_localidad    IN (', codloc, ', ', codloc1, ', ',
						codloc2, ') ',
		'   AND r19_cod_tran     IN ("FA", "NV") ',
		'   AND DATE(r19_fecing) BETWEEN "', rm_par.fecha_ini,
					  '" AND "', rm_par.fecha_fin, '"',
		'   AND r19_tipo_dev      = "AF" ',
		'   AND NOT EXISTS ',
			'(SELECT 1 FROM ', bas_ser CLIPPED, 'cxct021 ',
			' WHERE z21_compania  = r19_compania ',
			'   AND z21_localidad = r19_localidad ',
			'   AND z21_tipo_doc  = "NC" ',
			'   AND z21_codcli    = r19_codcli ',
			'   AND z21_areaneg   = 1 ',
			'   AND z21_cod_tran  = r19_tipo_dev ',
			'   AND z21_num_tran  = r19_num_dev) ',
		'   AND z01_codcli        = r19_codcli ',
		'   AND r38_compania      = r19_compania ',
		'   AND r38_localidad     = r19_localidad ',
		'   AND r38_tipo_fuente   = "PR" ',
		'   AND r38_cod_tran      = r19_cod_tran ',
		'   AND r38_num_tran      = r19_num_tran ',
		'   AND b.g37_compania    = r38_compania ',
		'   AND b.g37_localidad   = r38_localidad ',
		'   AND b.g37_tipo_doc    = r38_cod_tran ',
		'   AND b.g37_secuencia   = ',
			' (SELECT MAX(a.g37_secuencia) ',
				' FROM ', bas_ser CLIPPED, 'gent037 a ',
				' WHERE a.g37_compania  = b.g37_compania ',
				'   AND a.g37_localidad = b.g37_localidad ',
				'   AND a.g37_tipo_doc  = b.g37_tipo_doc) ',
		'   AND g02_compania    = b.g37_compania ',
		'   AND g02_localidad   = b.g37_localidad '
RETURN query CLIPPED

END FUNCTION



FUNCTION query_anuladas_tal(bas_ser, codloc, codloc1, codloc2)
DEFINE bas_ser		VARCHAR(30)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE codloc1, codloc2	LIKE srit021.s21_localidad
DEFINE query		CHAR(2000)

LET query = 'SELECT CASE WHEN LENGTH(CASE WHEN LENGTH(t23_cedruc) = 13 AND ',
				' t23_cod_cliente <> ', rm_r00.r00_codcli_tal,
					' THEN t23_cedruc ',
					' ELSE "9999999999999" ',
				'END) = 13 ',
			'AND fp_digito_veri(',
				'CASE WHEN LENGTH(t23_cedruc) = 13 AND',
				' t23_cod_cliente <> ', rm_r00.r00_codcli_tal,
					' THEN t23_cedruc ',
					' ELSE "9999999999999" ',
				'END) = 1 ',
			'THEN 1 ',
			'ELSE 2 ',
		'END tipo_comp, ',
		' b.g37_pref_sucurs, b.g37_pref_pto_vta, r38_num_sri[9, 16]',
		' num_sri_ini, r38_num_sri[9, 16] num_sri_fin, g02_numaut_sri,',
		'"', rm_par.fecha_fin, '" fecha ',
		' FROM ', bas_ser CLIPPED, 'talt023, ',
			bas_ser CLIPPED, 'talt028, ',
			bas_ser CLIPPED, 'cxct001, ',
			bas_ser CLIPPED, 'rept038, ',
			bas_ser CLIPPED, 'gent037 b, ',
			bas_ser CLIPPED, 'gent002 ',
		' WHERE t23_compania      = ', vg_codcia,
		'   AND t23_localidad    IN (', codloc, ', ', codloc1, ', ',
						codloc2, ') ',
		'   AND t23_estado        = "D" ',
		'   AND t28_compania      = t23_compania ',
		'   AND t28_localidad     = t23_localidad ',
		'   AND t28_ot_ant        = t23_orden ',
		'   AND t28_factura       = t23_num_factura ',
		'   AND DATE(t28_fecing) BETWEEN "', rm_par.fecha_ini,
					  '" AND "', rm_par.fecha_fin, '"',
		'   AND NOT EXISTS ',
			'(SELECT 1 FROM ', bas_ser CLIPPED, 'cxct021 ',
			' WHERE z21_compania  = t23_compania ',
			'   AND z21_localidad = t23_localidad ',
			'   AND z21_tipo_doc  = "NC" ',
			'   AND z21_codcli    = t23_cod_cliente ',
			'   AND z21_areaneg   = 2 ',
			'   AND z21_cod_tran  = "FA" ',
			'   AND z21_num_tran  = t28_factura) ',
		'   AND z01_codcli        = t23_cod_cliente ',
		'   AND r38_compania      = t23_compania ',
		'   AND r38_localidad     = t23_localidad ',
		'   AND r38_tipo_fuente   = "OT" ',
		'   AND r38_cod_tran      = "FA" ',
		'   AND r38_num_tran      = t23_num_factura ',
		'   AND b.g37_compania    = r38_compania ',
		'   AND b.g37_localidad   = r38_localidad ',
		'   AND b.g37_tipo_doc    = r38_cod_tran ',
		'   AND b.g37_secuencia   = ',
			' (SELECT MAX(a.g37_secuencia) ',
				' FROM ', bas_ser CLIPPED, 'gent037 a ',
				' WHERE a.g37_compania  = b.g37_compania ',
				'   AND a.g37_localidad = b.g37_localidad ',
				'   AND a.g37_tipo_doc  = b.g37_tipo_doc) ',
		'   AND g02_compania    = b.g37_compania ',
		'   AND g02_localidad   = b.g37_localidad '
RETURN query CLIPPED

END FUNCTION



FUNCTION generar_unl(tip_ane, codloc)
DEFINE tip_ane		CHAR(1)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE comando		VARCHAR(100)
DEFINE archivo		VARCHAR(50)

CASE tip_ane
	WHEN 'G'
		UNLOAD TO '../../../tmp/anexo_ventas.unl'
			SELECT tipodoc, tipocli, codcli, docid,
				SUM(ndocs) ndocs, SUM(subtotal) subtotal,
				SUM(subtotalgrav) subtotalGrav,
				SUM(impuesto) impuesto, SUM(total) total,
				SUM(ABS(ret)) ret
				FROM tmp_ane1
				WHERE loc = codloc
				GROUP BY 1, 2, 3, 4
				ORDER BY 4
		UNLOAD TO '../../../tmp/anulados.unl'
			SELECT * FROM tmp_anu1
	WHEN 'Q'
		UNLOAD TO '../../../tmp/anexo_ventas.unl'
			SELECT tipodoc, tipocli, codcli, docid,
				SUM(ndocs) ndocs, SUM(subtotal) subtotal,
				SUM(subtotalgrav) subtotalGrav,
				SUM(impuesto) impuesto, SUM(total) total,
				SUM(ABS(ret)) ret
				FROM tmp_ane2
				WHERE loc = codloc
				GROUP BY 1, 2, 3, 4
				ORDER BY 4
		UNLOAD TO '../../../tmp/anulados.unl'
			SELECT * FROM tmp_anu2
	WHEN 'N'
		UNLOAD TO '../../../tmp/anexo_ventas.unl'
			SELECT tipodoc, tipocli, codcli, docid,
				SUM(ndocs) ndocs, SUM(subtotal) subtotal,
				SUM(subtotalgrav) subtotalGrav,
				SUM(impuesto) impuesto, SUM(total) total,
				SUM(ABS(ret)) ret
				FROM tmp_ane3
				GROUP BY 1, 2, 3, 4
				ORDER BY 4
		UNLOAD TO '../../../tmp/anulados.unl'
			SELECT * FROM tmp_anu3
END CASE
LET archivo = 'anexo_ventas_', MONTH(rm_par.fecha_fin) USING "&&", '-',
		YEAR(rm_par.fecha_fin) USING "&&&&", '_', tip_ane CLIPPED,
		'.unl ' 
LET comando = 'mv ../../../tmp/anexo_ventas.unl $HOME/tmp/', archivo CLIPPED
RUN comando
LET archivo = 'anulados_', MONTH(rm_par.fecha_fin) USING "&&", '-',
		YEAR(rm_par.fecha_fin) USING "&&&&", '_', tip_ane CLIPPED,
		'.unl ' 
LET comando = 'mv ../../../tmp/anulados.unl $HOME/tmp/', archivo CLIPPED
RUN comando

END FUNCTION



FUNCTION generar_archivo_venta_xml(tip_ane, codloc)
DEFINE tip_ane		CHAR(1)
DEFINE codloc		LIKE srit021.s21_localidad
DEFINE r_reg		RECORD
				tip_cr		LIKE srit018.s18_sec_tran,
				docid		LIKE srit021.s21_num_doc_id,
				tipodoc		LIKE srit004.s04_codigo,
				ndocs		INTEGER,
				basenograiva	DECIMAL(12,2),
				baseimponible	DECIMAL(12,2),
				baseimpgrav	DECIMAL(12,2),
				impuesto	LIKE srit021.s21_monto_iva,
				valorretiva	DECIMAL(12,2),
				ret		LIKE srit021.s21_monto_ret_rent,
				nomcli		LIKE cxct001.z01_nomcli
			END RECORD
DEFINE r_s21		RECORD LIKE srit021.*
DEFINE query		CHAR(1000)
DEFINE registro		CHAR(4000)
DEFINE expr_loc		VARCHAR(100)
DEFINE tabla		VARCHAR(10)

LET expr_loc = ' WHERE loc = ', codloc
CASE tip_ane
	WHEN 'G' LET tabla = 'tmp_ane1'
	WHEN 'Q' LET tabla = 'tmp_ane2'
	WHEN 'N' LET tabla = 'tmp_ane3'
		 LET expr_loc = NULL
END CASE
LET query = 'SELECT tipocli tip_cr, docid, tipodoc, SUM(ndocs), 0.00, ',
			'SUM(subtotal), SUM(subtotalgrav), SUM(impuesto), ',
			'0.00, SUM(ABS(ret)) ',
		' FROM ', tabla CLIPPED,
		expr_loc CLIPPED,
		' GROUP BY 1, 2, 3, 5, 9 ',
		' ORDER BY docid '
PREPARE cons_ane_xml FROM query
DECLARE q_s21 CURSOR FOR cons_ane_xml
DISPLAY '<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>'
DISPLAY '<iva>'
IF vg_codcia = 1 THEN
	DISPLAY '<numeroRuc>1790008959001</numeroRuc>'
	DISPLAY '<razonSocial>ACERO COMERCIAL ECUATORIANO S.A.</razonSocial>'
ELSE
	DISPLAY '<numeroRuc>1790217515001</numeroRuc>'
	DISPLAY '<razonSocial>SERMACO S.A.</razonSocial>'
END IF
DISPLAY '<anio>', YEAR(rm_par.fecha_fin), '</anio>'
DISPLAY '<mes>', MONTH(rm_par.fecha_fin) USING "&&", '</mes>'
DISPLAY '<compras>'
DISPLAY '</compras>'
LET registro = '<ventas>'
FOREACH q_s21 INTO r_reg.*
	LET registro = registro CLIPPED, '<detalleVentas>',
		'<tpIdCliente>', r_reg.tip_cr USING "&&", '</tpIdCliente>',
		'<idCliente>', r_reg.docid, '</idCliente>',
		'<tipoComprobante>', r_reg.tipodoc, '</tipoComprobante>',
		'<numeroComprobantes>', r_reg.ndocs, '</numeroComprobantes> ',
		'<baseNoGraIva>', r_reg.basenograiva, '</baseNoGraIva> ',
		'<baseImponible>', r_reg.baseimponible, '</baseImponible> ',
		'<baseImpGrav>', r_reg.baseimpgrav, '</baseImpGrav> ',
		'<montoIva>', r_reg.impuesto, '</montoIva> ',
		'<valorRetIva>', r_reg.valorretiva, '</valorRetIva> ',
		'<valorRetRenta>', r_reg.ret, '</valorRetRenta> '
	LET registro = registro CLIPPED, '</detalleVentas>'
	DISPLAY registro CLIPPED
	LET registro = ' '
END FOREACH
DISPLAY '</ventas>'
DISPLAY '</iva>'
--CALL fl_mostrar_mensaje('Archivo XML de ventas generado OK.', 'info')

END FUNCTION



FUNCTION generar_archivo_anula_xml(tip_ane)
DEFINE tip_ane		CHAR(1)
DEFINE r_anu		RECORD
				comp		LIKE srit004.s04_codigo,
				punto		LIKE gent037.g37_pref_sucurs,
				estab		LIKE gent037.g37_pref_pto_vta,
				numini		LIKE rept038.r38_num_sri,
				numfin		LIKE rept038.r38_num_sri,
				autoriz		LIKE gent002.g02_numaut_sri,
				fecha		DATE
			END RECORD
DEFINE query		CHAR(200)
DEFINE tabla		VARCHAR(10)
DEFINE registro		CHAR(4000)

CASE tip_ane
	WHEN 'G' LET tabla = 'tmp_anu1'
	WHEN 'Q' LET tabla = 'tmp_anu2'
	WHEN 'N' LET tabla = 'tmp_anu3'
END CASE
LET query = 'SELECT * FROM ', tabla CLIPPED, ' ORDER BY 4'
PREPARE cons_anu FROM query
DECLARE q_anu CURSOR FOR cons_anu
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
--CALL fl_mostrar_mensaje('Archivo XML de anulados generado OK.', 'info')

END FUNCTION

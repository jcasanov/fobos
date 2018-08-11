--------------------------------------------------------------------------------
-- Titulo           : talp313.4gl - Consulta ventas por cliente del taller
-- Elaboracion      : 25-Ago-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp313 base módulo compañía localidad
--		             [fec_ini] [fec_fin] [tipo_vta] [todo_inv]
--			     [[vendedor]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE total_gen	DECIMAL(14,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par 		RECORD 
				fecha_ini	DATE,
				fecha_fin	DATE,
				tipo_vta	CHAR(1),
				tit_tipo_vta	VARCHAR(9),
				vendedor	LIKE talt061.t61_cod_vendedor,
				tit_vendedor	LIKE rept001.r01_nombres,
				cliente		LIKE cxct001.z01_codcli,
				tit_cliente	LIKE cxct001.z01_nomcli,
				venta_may	DECIMAL(10,2),
				todo_inv	CHAR(1)
			END RECORD
DEFINE rm_det 		ARRAY [30000] OF RECORD
				r01_iniciales	LIKE rept001.r01_iniciales,
				t23_cod_cliente	LIKE talt023.t23_cod_cliente,
				t23_nom_cliente	LIKE talt023.t23_nom_cliente,
				total_ot	DECIMAL(14,2)
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp313.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 AND num_args() <> 9 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp313'
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
LET vm_max_det = 30000
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 22
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_talp313 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_talf313_1 FROM "../forms/talf313_1"
ELSE
	OPEN FORM f_talf313_1 FROM "../forms/talf313_1c"
END IF
DISPLAY FORM f_talf313_1
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
LET vm_size_arr = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE i, j		SMALLINT
DEFINE query		CHAR(600)
DEFINE col, salir	SMALLINT
DEFINE r_r01		RECORD LIKE rept001.*

INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini = TODAY
LET rm_par.fecha_fin = TODAY
LET rm_par.tipo_vta  = 'T'
LET rm_par.todo_inv  = 'N'
CALL muestra_tipo_vta()
WHILE TRUE
	LET vm_num_det = 0
	CALL borrar_detalle()
	CALL muestra_contadores_det(0)
	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_par.fecha_ini = arg_val(5)
		LET rm_par.fecha_fin = arg_val(6)
		LET rm_par.tipo_vta  = arg_val(7)
		LET rm_par.todo_inv  = arg_val(8)
		IF num_args() = 9 THEN
			LET rm_par.vendedor = arg_val(9)
		END IF
		CALL fl_lee_vendedor_rep(vg_codcia, rm_par.vendedor)
			RETURNING r_r01.*
		LET rm_par.tit_vendedor = r_r01.r01_nombres
		DISPLAY BY NAME rm_par.*
		CALL muestra_tipo_vta()
	END IF
	SELECT DATE(t23_fec_factura) fecha_tran, t23_num_factura num_tran,
		t23_orden ord_t, t23_tot_bruto valor_mo, t23_tot_bruto valor_fa,
		t23_tot_bruto valor_oc, t23_tot_bruto valor_tot, t23_estado est,
		t23_cod_cliente codcli, t23_nom_cliente nomcli,
		t23_tel_cliente[1, 3] ini_ven
		FROM talt023
		WHERE t23_compania = 17
		INTO TEMP tmp_det
	CALL preparar_tabla_de_trabajo('F', 1)
	CALL preparar_tabla_de_trabajo('D', 1)
	CALL preparar_tabla_de_trabajo('D', 2)
	SELECT ini_ven, codcli, z01_nomcli t23_nom_cliente,
		NVL(SUM(valor_tot), 0) valor_ot
		FROM tmp_det, cxct001
		WHERE z01_codcli = codcli
		GROUP BY 1, 2, 3
		INTO TEMP t1
	DROP TABLE tmp_det
	IF rm_par.venta_may IS NULL THEN
		SELECT * FROM t1 INTO TEMP tmp_det
	ELSE
		SELECT * FROM t1 WHERE valor_ot >= rm_par.venta_may
			INTO TEMP tmp_det
	END IF
	DROP TABLE t1
	LET vm_columna_1           = 4
	LET vm_columna_2           = 3
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'ASC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT * FROM tmp_det ",
                   	" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
		PREPARE ordtal FROM query
		DECLARE q_ordtal CURSOR FOR ordtal
		LET total_gen = 0
		LET i         = 1
		FOREACH q_ordtal INTO rm_det[i].*
			LET total_gen = total_gen + rm_det[i].total_ot
			LET i         = i + 1
			IF i > vm_max_det THEN
				EXIT FOREACH
			END IF
		END FOREACH
		LET i = i - 1
		IF i = 0 THEN
	        	CALL fl_mensaje_consulta_sin_registros()
			IF num_args() <> 4 THEN
				EXIT PROGRAM
			END IF
			EXIT WHILE
		END IF
		LET vm_num_det = i
		DISPLAY BY NAME total_gen
		LET int_flag = 0
		CALL set_count(vm_num_det)
		DISPLAY ARRAY rm_det TO rm_det.*
			ON KEY(INTERRUPT)
				LET int_flag = 1
				IF num_args() <> 4 THEN
					LET salir = 1
				END IF
				EXIT DISPLAY
			ON KEY(F5)
				LET i = arr_curr()
				CALL ver_detalle_venta(i)
				LET int_flag = 0
			ON KEY(F6)
				LET i = arr_curr()
				CALL ver_estado_cuenta(i)
				LET int_flag = 0
			ON KEY(F7)
				CALL imprimir_listado()
				LET int_flag = 0
	                ON KEY(F15)
        	                LET col = 1
                	        EXIT DISPLAY
	                ON KEY(F16)
        	                LET col = 2
                	        EXIT DISPLAY
	                ON KEY(F17)
        	                LET col = 3
                	        EXIT DISPLAY
	                ON KEY(F18)
        	                LET col = 4
                	        EXIT DISPLAY
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#CALL muestra_contadores_det(j)
			--#AFTER DISPLAY
				--#CONTINUE DISPLAY
		END DISPLAY
        	IF int_flag = 1 THEN
			DELETE FROM tmp_det
                	EXIT WHILE
	        END IF
        	IF col IS NOT NULL AND NOT salir THEN
                	IF col <> vm_columna_1 THEN
                        	LET vm_columna_2           = vm_columna_1
	                        LET rm_orden[vm_columna_2] =
							rm_orden[vm_columna_1]
        	                LET vm_columna_1           = col
	                END IF
        	        IF rm_orden[vm_columna_1] = 'ASC' THEN
                	        LET rm_orden[vm_columna_1] = 'DESC'
	                ELSE
        	                LET rm_orden[vm_columna_1] = 'ASC'
                	END IF
	                INITIALIZE col TO NULL
        	END IF
	END WHILE
	DROP TABLE tmp_det
	IF salir THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION preparar_tabla_de_trabajo(flag, tr_ant)
DEFINE flag		CHAR(1)
DEFINE tr_ant		SMALLINT
DEFINE factor		CHAR(8)
DEFINE expr_out		CHAR(5)
DEFINE expr_fec1	VARCHAR(200)
DEFINE expr_fec2	VARCHAR(200)
DEFINE expr_cli		VARCHAR(100)
DEFINE expr_ven		VARCHAR(100)
DEFINE expr_vta_inv	VARCHAR(100)
DEFINE expr_vta_tal	VARCHAR(100)
DEFINE expr_fec_inv	VARCHAR(200)
DEFINE expr_dev_inv	VARCHAR(200)
DEFINE query		CHAR(8000)

IF flag = 'F' OR tr_ant = 2 THEN
	LET expr_fec1 = "   AND DATE(t23_fec_factura) BETWEEN '",
			rm_par.fecha_ini, "' AND '", rm_par.fecha_fin, "'"
	LET expr_fec2 = NULL
	LET expr_out  = 'OUTER'
END IF
IF flag = 'D' AND tr_ant = 1 THEN
	LET expr_out  = NULL
	LET expr_fec1 = NULL
	LET expr_fec2 = "   AND DATE(t28_fec_anula) BETWEEN '",
				rm_par.fecha_ini, "' AND '",
				rm_par.fecha_fin, "'"
END IF
LET expr_cli = NULL
IF rm_par.cliente IS NOT NULL THEN
	LET expr_cli = "   AND t23_cod_cliente = ", rm_par.cliente
END IF
LET expr_ven = NULL
IF rm_par.vendedor IS NOT NULL THEN
	LET expr_ven = "   AND t61_cod_vendedor = ", rm_par.vendedor
END IF
CASE tr_ant
	WHEN 1
		LET factor = ' * (-1) '
	WHEN 2
		LET factor = NULL
END CASE
LET expr_vta_inv = NULL
IF rm_par.tipo_vta <> 'T' THEN
	LET expr_vta_inv = "   AND r19_cont_cred    = '", rm_par.tipo_vta, "'"
END IF
LET expr_vta_tal = NULL
IF rm_par.tipo_vta <> 'T' THEN
	LET expr_vta_tal = "   AND t23_cont_cred = '", rm_par.tipo_vta, "'"
END IF
LET expr_fec_inv = NULL
LET expr_dev_inv = NULL
IF rm_par.todo_inv = 'N' THEN
	LET expr_fec_inv = '   AND EXTEND(r19_fecing, YEAR TO MONTH) >= ',
				'EXTEND(t23_fec_factura, YEAR TO MONTH) ',
			   '   AND EXTEND(r19_fecing, YEAR TO MONTH) <= ',
				'EXTEND(t23_fec_factura, YEAR TO MONTH) '
	LET expr_dev_inv = '   AND EXTEND(r19_fecing, YEAR TO MONTH) >= ',
				'EXTEND(t28_fec_anula, YEAR TO MONTH) ',
			   '   AND EXTEND(r19_fecing, YEAR TO MONTH) <= ',
				'EXTEND(t28_fec_anula, YEAR TO MONTH) '
END IF
LET query = "INSERT INTO tmp_det ",
		"SELECT CASE WHEN t23_estado = 'D' AND ", tr_ant, " = 1 ",
			" THEN (SELECT DATE(t28_fec_anula) ",
				"FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE DATE(t23_fec_factura) ",
			" END, ",
			" CASE WHEN t23_estado = 'D' AND ", tr_ant, " = 1 ",
			" THEN (SELECT t28_num_dev FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE t23_num_factura ",
			" END, ",
			" CASE WHEN t23_estado = 'D' ",
			" THEN (SELECT t28_ot_ant FROM talt028 ",
				"WHERE t28_compania  = t23_compania ",
				"  AND t28_localidad = t23_localidad ",
				"  AND t28_factura   = t23_num_factura)",
			" ELSE t23_orden ",
			" END, ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN (t23_val_mo_tal - t23_vde_mo_tal) ",
			" ELSE (t23_val_mo_tal - t23_vde_mo_tal) ",
							factor CLIPPED,
		" END, ",
		" CASE WHEN t23_estado = 'F' THEN ",
			"CASE WHEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2))",
			", 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') >= (t23_val_mo_ext + t23_val_rp_tal) ",
			"THEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2))",
			", 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') ",
			"ELSE t23_val_mo_ext + t23_val_rp_tal ",
			"END + ",
			" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
			" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
			       "t23_val_rp_cti + t23_val_otros2) ",
			" ELSE 0.00 ",
			" END ",
		" ELSE (t23_val_mo_ext + t23_val_mo_cti + ",
			"t23_val_rp_tal + t23_val_rp_ext + ",
			"t23_val_rp_cti + t23_val_otros2) ", factor CLIPPED,
		" END, ",
		" CASE WHEN t23_estado = 'F' THEN ",
			" (SELECT NVL(SUM(r19_tot_bruto - ",
					"r19_tot_dscto), 0) ",
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran     = 'FA' ",
			expr_vta_inv CLIPPED,
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_fec_inv CLIPPED, ") ",
		"      WHEN t23_estado = 'D' THEN ",
			" (SELECT NVL(SUM(r19_tot_bruto - ",
					"r19_tot_dscto), 0) ", factor CLIPPED,
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran    IN ('DF', 'AF') ",
			expr_vta_inv CLIPPED,
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_dev_inv CLIPPED, ") ",
		"      ELSE 0 ",
		" END, ",
		" CASE WHEN t23_estado = 'F' ",
			" THEN (t23_val_mo_tal - t23_vde_mo_tal) ",
			" ELSE (t23_val_mo_tal - t23_vde_mo_tal) ",
							factor CLIPPED,
		" END + ",
		" CASE WHEN t23_estado = 'F' THEN ",
			"CASE WHEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2))",
			", 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') >= (t23_val_mo_ext + t23_val_rp_tal) ",
			"THEN ",
			"(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)",
			" * (1 + c10_recargo / 100), 2)), 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'S') + ",
			"(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)",
			" - c11_val_descto) * (1 + c10_recargo / 100), 2))",
			", 0) ",
			" FROM ordt010, ordt011 ",
			" WHERE c10_compania    = t23_compania ",
			"   AND c10_localidad   = t23_localidad ",
			"   AND c10_ord_trabajo = t23_orden ",
			"   AND c10_estado      = 'C' ",
			"   AND c11_compania    = c10_compania ",
			"   AND c11_localidad   = c10_localidad ",
			"   AND c11_numero_oc   = c10_numero_oc ",
			"   AND c11_tipo        = 'B') ",
			"ELSE t23_val_mo_ext + t23_val_rp_tal ",
			"END + ",
			" CASE WHEN (SELECT COUNT(*) FROM ordt010 ",
				" WHERE c10_compania    = t23_compania ",
				"   AND c10_localidad   = t23_localidad ",
				"   AND c10_ord_trabajo = t23_orden ",
				"   AND c10_estado      = 'C') = 0 ",
			" THEN (t23_val_rp_tal + t23_val_rp_ext + ",
			       "t23_val_rp_cti + t23_val_otros2) ",
			" ELSE 0.00 ",
			" END ",
		" ELSE (t23_val_mo_ext + t23_val_mo_cti + ",
			"t23_val_rp_tal + t23_val_rp_ext + ",
			"t23_val_rp_cti + t23_val_otros2) ", factor CLIPPED,
		" END + ",
		" CASE WHEN t23_estado = 'F' THEN ",
			" (SELECT NVL(SUM(r19_tot_bruto - ",
					"r19_tot_dscto), 0) ",
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran     = 'FA' ",
			expr_vta_inv CLIPPED,
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_fec_inv CLIPPED, ") ",
		"      WHEN t23_estado = 'D' THEN ",
			" (SELECT NVL(SUM(r19_tot_bruto - ",
					"r19_tot_dscto), 0) ", factor CLIPPED,
			" FROM rept019 ",
			" WHERE r19_compania     = t23_compania ",
			"   AND r19_localidad    = t23_localidad ",
			"   AND r19_cod_tran    IN ('DF', 'AF') ",
			expr_vta_inv CLIPPED,
			"   AND r19_ord_trabajo  = t23_orden ",
			expr_dev_inv CLIPPED, ") ",
		"      ELSE 0 ",
		" END, ",
		" CASE WHEN ", tr_ant, " = 1 THEN t23_estado ELSE 'F' END, ",
		" t23_cod_cliente, t23_nom_cliente, r01_iniciales ",
		" FROM talt023, talt061, rept001, ", expr_out, " talt028 ",
		" WHERE t23_compania   = ", vg_codcia,
		"   AND t23_localidad  = ", vg_codloc,
		expr_cli CLIPPED,
		"   AND t23_estado     = '", flag, "'",
		expr_vta_tal CLIPPED,
		"   AND t61_compania   = t23_compania ",
		"   AND t61_cod_asesor = t23_cod_asesor ",
		expr_ven CLIPPED,
		"   AND r01_compania   = t61_compania ",
		"   AND r01_codigo     = t61_cod_vendedor ",
		expr_fec1 CLIPPED,
		"   AND t28_compania   = t23_compania ",
		"   AND t28_localidad  = t23_localidad ",
		"   AND t28_factura    = t23_num_factura ",
		expr_fec2 CLIPPED,
		" GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 "
PREPARE cons_tmp FROM query
EXECUTE cons_tmp
IF tr_ant <> 2 THEN
	RETURN
END IF
LET query = 'DELETE FROM tmp_det ',
		' WHERE fecha_tran < "', rm_par.fecha_ini, '"',
		'    OR fecha_tran > "', rm_par.fecha_fin, '"'
PREPARE cons_del FROM query
EXECUTE cons_del

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN 
	ON KEY(F2)
		IF INFIELD(vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'T', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par.vendedor     = r_r01.r01_codigo
				LET rm_par.tit_vendedor = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.vendedor
				DISPLAY r_r01.r01_nombres TO tit_vendedor
			END IF
		END IF
		IF INFIELD(cliente) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.cliente     = r_z01.z01_codcli
				LET rm_par.tit_cliente = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.cliente,
						rm_par.tit_cliente
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
		ELSE
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER FIELD tipo_vta
		CALL muestra_tipo_vta()
	AFTER FIELD vendedor
		IF rm_par.vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.vendedor)
				RETURNING r_r01.*
			IF r_r01.r01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este vendedor en la compania.','exclamation')
				NEXT FIELD vendedor
			END IF
			LET rm_par.tit_vendedor = r_r01.r01_nombres
			DISPLAY r_r01.r01_nombres TO tit_vendedor
		ELSE
			LET rm_par.tit_vendedor = NULL
			DISPLAY BY NAME rm_par.tit_vendedor
		END IF
	AFTER FIELD cliente
		IF rm_par.cliente IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.cliente)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD cliente
			END IF
			LET rm_par.tit_cliente = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.tit_cliente
		ELSE
			LET rm_par.tit_cliente = NULL
			DISPLAY BY NAME rm_par.tit_cliente
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION borrar_cabecera()

INITIALIZE rm_par.* TO NULL
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
--#LET vm_size_arr = fgl_scr_size('rm_det')
IF vg_gui = 0 THEN
	LET vm_size_arr = 12
END IF
FOR i = 1 TO vm_size_arr
        INITIALIZE rm_det[i].* TO NULL
        CLEAR rm_det[i].*
END FOR
CLEAR total_gen, num_row, vm_num_det

END FUNCTION



FUNCTION muestra_contadores_det(num_row)
DEFINE num_row		SMALLINT

DISPLAY BY NAME num_row, vm_num_det

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Ven.'		TO tit_col1
--#DISPLAY "Código"		TO tit_col2
--#DISPLAY "C l i e n t e s"	TO tit_col3
--#DISPLAY "Total Venta"	TO tit_col4

END FUNCTION



FUNCTION muestra_tipo_vta()

CASE rm_par.tipo_vta
	WHEN 'C' LET rm_par.tit_tipo_vta = 'CONTADO'
	WHEN 'R' LET rm_par.tit_tipo_vta = 'CREDITO'
	WHEN 'T' LET rm_par.tit_tipo_vta = 'T O D O S'
END CASE
DISPLAY BY NAME rm_par.tit_tipo_vta

END FUNCTION



FUNCTION ver_detalle_venta(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(100)

LET param = ' T ', rm_par.tipo_vta, ' "', rm_par.fecha_ini, '" "',
		rm_par.fecha_fin, '" ', rm_det[i].t23_cod_cliente, ' "',
		rm_par.todo_inv, '"'
CALL ejecuta_comando('TALLER', vg_modulo, 'talp309', param)

END FUNCTION



FUNCTION ver_estado_cuenta(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(100)

LET param = rg_gen.g00_moneda_base, ' ', rm_par.fecha_fin, ' "T" 0.01 "N" 0 ',
		rm_det[i].t23_cod_cliente
CALL ejecuta_comando('COBRANZAS', 'CO', 'cxcp314', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(100)
DEFINE comando 		CHAR(400)
DEFINE run_prog		VARCHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog, ' ',
		vg_base, ' ', mod, ' ', vg_codcia, ' ', vg_codloc, ' ',
		param CLIPPED
RUN comando

END FUNCTION



FUNCTION imprimir_listado()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_list_trans TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT report_list_trans(i)
END FOR
FINISH REPORT report_list_trans

END FUNCTION



REPORT report_list_trans(i)
DEFINE i		SMALLINT
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 024, "DETALLE VENTAS POR CLIENTE TALLER",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 022, "** FECHA INICIAL : ", rm_par.fecha_ini
							USING "dd-mm-yyyy"
	PRINT COLUMN 022, "** FECHA FINAL   : ", rm_par.fecha_fin
							USING "dd-mm-yyyy"
	PRINT COLUMN 022, "** TIPO VENTA    : ", rm_par.tipo_vta, " ",
		rm_par.tit_tipo_vta CLIPPED
	IF rm_par.vendedor IS NOT NULL THEN
		PRINT COLUMN 022, "** VENDEDOR      : ",
			rm_par.vendedor USING "<<<&", ' ', rm_par.tit_vendedor
	ELSE
		PRINT " "
	END IF
	IF rm_par.cliente IS NOT NULL THEN
		PRINT COLUMN 022, "** CLIENTE       : ",
			rm_par.cliente USING "<<<<<&", ' ', rm_par.tit_cliente
	ELSE
		PRINT " "
	END IF
	IF rm_par.venta_may IS NOT NULL THEN
		PRINT COLUMN 022, "** VENTA MAYOR A : ",
					rm_par.venta_may USING "---,--&.##"
	ELSE
		PRINT " "
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "VEN.",
	      COLUMN 006, "CODIGO",
	      COLUMN 030, "C L I E N T E S",
	      COLUMN 068, "     TOTAL OT"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_det[i].r01_iniciales,
	      COLUMN 006, rm_det[i].t23_cod_cliente	USING "<<<<<&",
	      COLUMN 013, rm_det[i].t23_nom_cliente[1,54] CLIPPED,
	      COLUMN 068, rm_det[i].total_ot		USING "--,---,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 070, "-------------"
	PRINT COLUMN 057, "TOTAL ==>  ", total_gen	USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT

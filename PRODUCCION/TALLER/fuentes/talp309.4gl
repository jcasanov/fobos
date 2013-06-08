--------------------------------------------------------------------------------
-- Titulo           : talp309.4gl - Consulta transacciones de taller
-- Elaboracion      : 23-Ago-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp309 base módulo compañía localidad
--		             [tipo_tran] [tipo_vta] [fec_ini] [fec_fin] [codcli]
--			     [todo_inv]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_size_arr      SMALLINT
DEFINE tot_neto		DECIMAL(14,2)
DEFINE total_oc		DECIMAL(14,2)
DEFINE total_fa		DECIMAL(14,2)
DEFINE total_ot		DECIMAL(14,2)
DEFINE rm_par 		RECORD 
				tipo		CHAR(1),
				tit_tipo	VARCHAR(12),
				tipo_vta	CHAR(1),
				tit_tipo_vta	VARCHAR(9),
				fecha_ini	DATE,
				fecha_fin	DATE,
				todo_inv	CHAR(1)
			END RECORD
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_det 		ARRAY [30000] OF RECORD
				fecha		DATE,
				t23_num_factura	LIKE talt023.t23_num_factura,
				t23_orden	LIKE talt023.t23_orden,
				t23_val_mo_tal	LIKE talt023.t23_val_mo_tal,
				tot_oc		DECIMAL(12,2),
				tot_fa		DECIMAL(12,2),
				tot_ot		DECIMAL(12,2),
				t23_estado	LIKE talt023.t23_estado
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp309.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 10 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'talp309'
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
OPEN WINDOW w_talp309 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_talf309_1 FROM "../forms/talf309_1"
ELSE
	OPEN FORM f_talf309_1 FROM "../forms/talf309_1c"
END IF
DISPLAY FORM f_talf309_1
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
LET vm_size_arr = 0
CALL muestra_contadores_det(0)
CALL borrar_cabecera()
CALL borrar_detalle()
CALL mostrar_cabecera_forma()
CALL control_consulta()

END FUNCTION



FUNCTION control_consulta()
DEFINE r_cli		ARRAY [30000] OF RECORD
				t23_cod_cliente	LIKE talt023.t23_cod_cliente,
				t23_nom_cliente	LIKE talt023.t23_nom_cliente
			END RECORD
DEFINE i, j, factor	SMALLINT
DEFINE query		CHAR(600)
DEFINE col, salir	SMALLINT
DEFINE cuantos		INTEGER
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE estado		LIKE talt023.t23_estado

INITIALIZE rm_par.* TO NULL
LET rm_par.fecha_ini = TODAY
LET rm_par.fecha_fin = TODAY
LET rm_par.tipo      = 'T'
LET rm_par.tipo_vta  = 'T'
LET rm_par.todo_inv  = 'N'
CALL muestra_tipo()
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
		LET rm_par.tipo      = arg_val(5)
		LET rm_par.tipo_vta  = arg_val(6)
		LET rm_par.fecha_ini = arg_val(7)
		LET rm_par.fecha_fin = arg_val(8)
		LET rm_par.todo_inv  = arg_val(10)
		DISPLAY BY NAME rm_par.*
		CALL muestra_tipo()
		CALL muestra_tipo_vta()
	END IF
	SELECT DATE(t23_fec_factura) fecha_tran, t23_num_factura num_tran,
		t23_orden ord_t, t23_tot_bruto valor_mo, t23_tot_bruto valor_fa,
		t23_tot_bruto valor_oc, t23_tot_bruto valor_tot, t23_estado est,
		t23_cod_cliente codcli, t23_nom_cliente nomcli
		FROM talt023
		WHERE t23_compania = 17
		INTO TEMP tmp_det
	CASE rm_par.tipo
		WHEN 'F' CALL preparar_tabla_de_trabajo(rm_par.tipo, 1)
			 CALL preparar_tabla_de_trabajo('D', 2)
		WHEN 'D' CALL preparar_tabla_de_trabajo(rm_par.tipo, 1)
		WHEN 'N' CALL preparar_tabla_de_trabajo('N', 1)
		WHEN 'T' CALL preparar_tabla_de_trabajo('F', 1)
			 CALL preparar_tabla_de_trabajo('D', 1)
		         CALL preparar_tabla_de_trabajo('N', 1)
			 CALL preparar_tabla_de_trabajo('D', 2)
	END CASE
	LET vm_columna_1           = 1
	LET vm_columna_2           = 2
	LET rm_orden[vm_columna_1] = 'DESC'
	LET rm_orden[vm_columna_2] = 'DESC'
	INITIALIZE col TO NULL
	LET salir = 0
	WHILE NOT salir
		LET query = "SELECT * FROM tmp_det ",
                   	" ORDER BY ", vm_columna_1, " ", rm_orden[vm_columna_1],
				", ", vm_columna_2, " ", rm_orden[vm_columna_2]
		PREPARE ordtal FROM query
		DECLARE q_ordtal CURSOR FOR ordtal
		LET tot_neto = 0
		LET total_oc = 0
		LET total_fa = 0
		LET total_ot = 0
		LET i        = 1
		FOREACH q_ordtal INTO rm_det[i].*, r_cli[i].*
			LET tot_neto = tot_neto + rm_det[i].t23_val_mo_tal
			LET total_oc = total_oc + rm_det[i].tot_oc
			LET total_fa = total_fa + rm_det[i].tot_fa
			LET total_ot = total_ot + rm_det[i].tot_ot
			LET i        = i + 1
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
		DISPLAY BY NAME tot_neto, total_oc, total_fa, total_ot
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
				CALL fl_mostrar_contable_tal(vg_codcia,
							vg_codloc,
							rm_det[i].t23_orden)
					RETURNING tipo_comp, num_comp
				IF tipo_comp IS NOT NULL AND cuantos = 1 THEN
					CALL fl_ver_contabilizacion(tipo_comp, 
							     num_comp)
				END IF
				LET int_flag = 0
			ON KEY(F6)
				LET i = arr_curr()
				CALL fl_ver_factura_dev_tal(
						rm_det[i].t23_num_factura,
						rm_det[i].t23_estado)
				LET int_flag = 0
			ON KEY(F7)
				LET i = arr_curr()
				CALL fl_ver_orden_trabajo(rm_det[i].t23_orden,
								'O')
				LET int_flag = 0
			ON KEY(F8)
				LET i = arr_curr()
				LET factor = 1
				IF rm_det[i].t23_estado = 'D' OR
				   rm_det[i].t23_estado = 'N'
				THEN
					LET factor = -1
				END IF
				CALL fl_muestra_mano_obra_orden_trabajo(
							vg_codcia, vg_codloc,
							rm_det[i].t23_orden,
							factor)
				LET int_flag = 0
			ON KEY(F9)
				LET i = arr_curr()
				CALL fl_muestra_det_ord_compra_orden_trabajo(
							vg_codcia, vg_codloc,
							rm_det[i].t23_orden,
							rm_det[i].t23_estado)
				LET int_flag = 0
			ON KEY(F10)
				LET i = arr_curr()
				IF rm_det[i].tot_fa = 0 THEN
					--#CONTINUE DISPLAY
				END IF
				CALL fl_control_prof_trans(vg_codcia, vg_codloc,
							rm_det[i].t23_orden)
				LET int_flag = 0
			ON KEY(F11)
				LET i = arr_curr()
				IF rm_det[i].tot_fa = 0 THEN
					--#CONTINUE DISPLAY
				END IF
				LET estado = rm_det[i].t23_estado
				IF rm_det[i].t23_estado = 'N' THEN
					LET estado = "D"
				END IF
				CALL fl_muestra_repuestos_orden_trabajo(
							vg_codcia, vg_codloc,
							rm_det[i].t23_orden,
							estado)
				LET int_flag = 0
			ON KEY(CONTROL-V)
				LET i = arr_curr()
				CALL control_imprimir(i)
				LET int_flag = 0
			ON KEY(CONTROL-W)
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
	                ON KEY(F19)
        	                LET col = 5
                	        EXIT DISPLAY
	                ON KEY(F20)
        	                LET col = 6
                	        EXIT DISPLAY
	                ON KEY(F21)
        	                LET col = 7
                	        EXIT DISPLAY
	                ON KEY(F22)
				IF rm_par.tipo = 'T' THEN
	        	                LET col = 8
        	        	        EXIT DISPLAY
				END IF
			--#BEFORE DISPLAY
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("CONTROL-V","Imprimir Comp.")
				--#CALL dialog.keysetlabel("CONTROL-W","Imprimir Listado")
			--#BEFORE ROW
				--#LET j = arr_curr()
				--#CALL muestra_contadores_det(j)
				--#DISPLAY BY NAME r_cli[j].*
				--#SELECT COUNT(*) INTO cuantos FROM talt050 
				--#	WHERE t50_compania  = vg_codcia	
				--#	  AND t50_localidad = vg_codloc
				--#	  AND t50_orden     =rm_det[j].t23_orden
				--#IF cuantos > 0 THEN
					--#CALL dialog.keysetlabel('F5', 
					--#	'Contabilización')
				--#ELSE
					--#CALL dialog.keysetlabel('F5', '')
				--#END IF
				--#IF rm_det[j].tot_fa > 0 THEN
					--#CALL dialog.keysetlabel('F10', 
					--#	'Detalle Proforma')
					--#CALL dialog.keysetlabel('F11', 
					--#	'Detalle Inv. Venta')
				--#ELSE
					--#CALL dialog.keysetlabel('F10', '')
					--#CALL dialog.keysetlabel('F11', '')
				--#END IF
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
DEFINE expr_est		VARCHAR(100)
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
IF (flag = 'D' OR flag = 'N') AND tr_ant = 1 THEN
	LET expr_out  = NULL
	LET expr_fec1 = NULL
	LET expr_fec2 = "   AND DATE(t28_fec_anula) BETWEEN '",
				rm_par.fecha_ini, "' AND '",
				rm_par.fecha_fin, "'"
END IF
LET expr_cli = NULL
IF num_args() <> 4 THEN
	LET expr_cli = "   AND t23_cod_cliente = ", arg_val(9)
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
LET expr_est = "   AND t23_estado    = '", flag, "'"
IF rm_par.tipo = 'N' THEN
	LET expr_est = "   AND t23_estado    = 'D'"
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
		" END tot_oc, ",
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
		" t23_cod_cliente, t23_nom_cliente ",
		" FROM talt023, ", expr_out, " talt028 ",
		" WHERE t23_compania  = ", vg_codcia,
		"   AND t23_localidad = ", vg_codloc,
		expr_cli CLIPPED,
		expr_est CLIPPED,
		expr_vta_tal CLIPPED,
		expr_fec1 CLIPPED,
		"   AND t28_compania  = t23_compania ",
		"   AND t28_localidad = t23_localidad ",
		"   AND t28_factura   = t23_num_factura ",
		expr_fec2 CLIPPED,
		" GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 "
PREPARE cons_tmp FROM query
EXECUTE cons_tmp
IF tr_ant = 2 THEN
	LET query = 'DELETE FROM tmp_det ',
			' WHERE fecha_tran < "', rm_par.fecha_ini, '"',
			'    OR fecha_tran > "', rm_par.fecha_fin, '"'
	PREPARE cons_del FROM query
	EXECUTE cons_del
	RETURN
END IF
LET query = 'SELECT num_tran num_anu, z21_tipo_doc ',
		' FROM tmp_det, talt028, OUTER cxct021 ',
		' WHERE est           = "D" ',
		'   AND t28_compania  = ', vg_codcia,
		'   AND t28_localidad = ', vg_codloc,
		'   AND t28_num_dev   = num_tran ',
		'   AND z21_compania  = t28_compania ',
		'   AND z21_localidad = t28_localidad ',
		'   AND z21_tipo_doc  = "NC" ',
		'   AND z21_areaneg   = 2 ',
		'   AND z21_cod_tran  = "FA" ',
		'   AND z21_num_tran  = t28_factura ',
		' INTO TEMP t2 '
PREPARE cons_t2 FROM query 
EXECUTE cons_t2
CASE flag
	WHEN 'N' SELECT * FROM t2 WHERE z21_tipo_doc IS NULL INTO TEMP t3
		 DELETE FROM t2 WHERE z21_tipo_doc IS NULL
	WHEN 'D' DELETE FROM t2 WHERE z21_tipo_doc IS NOT NULL
END CASE
IF rm_par.tipo <> 'T' THEN
	DELETE FROM tmp_det
		WHERE est      = "D"
		  AND num_tran = (SELECT num_anu FROM t2
					WHERE num_anu = num_tran)
END IF
DROP TABLE t2
IF flag = 'N' THEN
	UPDATE tmp_det SET est = flag WHERE est = "D"
		  AND num_tran = (SELECT num_anu FROM t3
					WHERE num_anu = num_tran)
	DROP TABLE t3
END IF

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
	AFTER FIELD tipo
		CALL muestra_tipo()
	AFTER FIELD tipo_vta
		CALL muestra_tipo_vta()
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
CLEAR tot_neto, total_oc, total_fa, total_ot, t23_cod_cliente, t23_nom_cliente,
	num_row, vm_num_det

END FUNCTION



FUNCTION muestra_contadores_det(num_row)
DEFINE num_row		SMALLINT

DISPLAY BY NAME num_row, vm_num_det

END FUNCTION


 
FUNCTION mostrar_cabecera_forma()

--#DISPLAY 'Fecha'		TO tit_col1
--#DISPLAY 'Número'		TO tit_col2
--#DISPLAY "Ord Tra."		TO tit_col3
--#DISPLAY "Total MO"		TO tit_col4
--#DISPLAY "Total OC"		TO tit_col5
--#DISPLAY "Tot. FA"		TO tit_col6
--#DISPLAY "Total OT"		TO tit_col7
--#DISPLAY "E"			TO tit_col8

END FUNCTION



FUNCTION muestra_tipo()

CASE rm_par.tipo
	WHEN 'F' LET rm_par.tit_tipo = 'FACTURAS'
	WHEN 'D' LET rm_par.tit_tipo = 'DEVOLUCIONES'
	WHEN 'N' LET rm_par.tit_tipo = 'ANULACIONES'
	WHEN 'T' LET rm_par.tit_tipo = 'T O D A S'
END CASE
DISPLAY BY NAME rm_par.tit_tipo

END FUNCTION



FUNCTION muestra_tipo_vta()

CASE rm_par.tipo_vta
	WHEN 'C' LET rm_par.tit_tipo_vta = 'CONTADO'
	WHEN 'R' LET rm_par.tit_tipo_vta = 'CREDITO'
	WHEN 'T' LET rm_par.tit_tipo_vta = 'T O D O S'
END CASE
DISPLAY BY NAME rm_par.tit_tipo_vta

END FUNCTION



FUNCTION control_imprimir(i)
DEFINE i		SMALLINT
DEFINE r_t28		RECORD LIKE talt028.*
DEFINE impresion	CHAR(1)
DEFINE row_max		SMALLINT
DEFINE col_max		SMALLINT
DEFINE param		VARCHAR(100)

LET row_max = 12
LET col_max = 42
IF vg_gui = 0 THEN
	LET row_max = 11
	LET col_max = 43
END IF
OPEN WINDOW w_308_2 AT 07, 20 WITH row_max ROWS, col_max COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
IF vg_gui = 1 THEN
	OPEN FORM f_308_2 FROM '../forms/talf308_2'
ELSE
	OPEN FORM f_308_2 FROM '../forms/talf308_2c'
END IF
DISPLAY FORM f_308_2
LET impresion = 'F'
DISPLAY rm_det[i].t23_num_factura TO num_fac
DISPLAY BY NAME impresion
WHILE TRUE
	LET int_flag = 0
	INPUT BY NAME impresion
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT INPUT
	END INPUT
	IF int_flag THEN
		EXIT WHILE
	END IF
	CASE impresion
		WHEN 'F'
			LET param = rm_det[i].t23_num_factura
			CALL ejecuta_comando('TALLER', vg_modulo, 'talp403',
						param)
		WHEN 'A'
			LET param = rm_det[i].t23_orden
			CALL ejecuta_comando('TALLER', vg_modulo, 'talp408',
						param)
		WHEN 'D'
			INITIALIZE r_t28.* TO NULL
			SELECT * INTO r_t28.*
				FROM talt028
				WHERE t28_compania  = vg_codcia
				  AND t28_localidad = vg_codloc
				  AND t28_ot_ant    = rm_det[i].t23_orden
			IF r_t28.t28_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Esta Factura no esta Anulada/Devuelta.', 'exclamation')
				CONTINUE WHILE
			END IF
			LET param = ' ', r_t28.t28_num_dev
			CALL ejecuta_comando('TALLER', vg_modulo, 'talp413 ',
						param)
		WHEN 'T'
			LET param = rm_det[i].t23_num_factura
			CALL ejecuta_comando('TALLER', vg_modulo, 'talp403',
						param)
			LET param = rm_det[i].t23_orden
			CALL ejecuta_comando('TALLER', vg_modulo, 'talp408',
						param)
			INITIALIZE r_t28.* TO NULL
			SELECT * INTO r_t28.*
				FROM talt028
				WHERE t28_compania  = vg_codcia
				  AND t28_localidad = vg_codloc
				  AND t28_ot_ant    = rm_det[i].t23_orden
			IF r_t28.t28_compania IS NULL THEN
				CONTINUE WHILE
			END IF
			LET param = ' ', r_t28.t28_num_dev
			CALL ejecuta_comando('TALLER', vg_modulo, 'talp413 ',
						param)
	END CASE
END WHILE
CLOSE WINDOW w_308_2
LET int_flag = 0
RETURN

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
DEFINE factura		VARCHAR(15)
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
	      COLUMN 025, "DETALLE TRANSACCIONES DEL TALLER",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 022, "** TIPO TRANSAC. : ", rm_par.tipo," ",rm_par.tit_tipo
	PRINT COLUMN 022, "** TIPO VENTA    : ", rm_par.tipo_vta, " ",
		rm_par.tit_tipo_vta
	PRINT COLUMN 022, "** FECHA INICIAL : ", rm_par.fecha_ini
							USING "dd-mm-yyyy"
	PRINT COLUMN 022, "** FECHA FINAL   : ", rm_par.fecha_fin
							USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario
	PRINT "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "FECHA",
	      COLUMN 012, "NUMER",
	      COLUMN 018, "ORD.T",
	      COLUMN 024, "     TOTAL MO",
	      COLUMN 038, "     TOTAL OC",
	      COLUMN 052, "     TOTAL FA",
	      COLUMN 066, "     TOTAL OT",
	      COLUMN 080, "E"
	PRINT "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	LET factura = rm_det[i].t23_num_factura
	CALL fl_justifica_titulo('I', factura, 5) RETURNING factura
	PRINT COLUMN 001, rm_det[i].fecha		USING "dd-mm-yyyy",
	      COLUMN 012, factura CLIPPED,
	      COLUMN 018, rm_det[i].t23_orden		USING "<<<<&",
	      COLUMN 024, rm_det[i].t23_val_mo_tal	USING "--,---,--&.##",
	      COLUMN 038, rm_det[i].tot_oc		USING "--,---,--&.##",
	      COLUMN 052, rm_det[i].tot_fa		USING "--,---,--&.##",
	      COLUMN 066, rm_det[i].tot_ot		USING "--,---,--&.##",
	      COLUMN 080, rm_det[i].t23_estado
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 026, "-------------",
	      COLUMN 040, "-------------",
	      COLUMN 054, "-------------",
	      COLUMN 068, "-------------"
	PRINT COLUMN 013, "TOTAL ==>  ", tot_neto	USING "--,---,--&.##",
	      COLUMN 038, total_oc			USING "--,---,--&.##",
	      COLUMN 052, total_fa			USING "--,---,--&.##",
	      COLUMN 066, total_ot			USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT

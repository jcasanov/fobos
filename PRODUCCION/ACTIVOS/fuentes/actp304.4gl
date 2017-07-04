--------------------------------------------------------------------------------
-- Titulo            : actp304.4gl - Saldo por Grupo Activos Fijos
-- Elaboracion       : 19-Mar-2010
-- Autor             : NPC
-- Formato Ejecucion : fglrun actp304 base modulo compania
-- Ultima Correccion :
-- Motivo Correccion :
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par		RECORD 
				anio_ini	LIKE actt000.a00_anopro,
				mes_ini		LIKE actt000.a00_mespro,
				anio_fin	LIKE actt000.a00_anopro,
				mes_fin		LIKE actt000.a00_mespro
			END RECORD
DEFINE rm_imp		RECORD 
				imp_sal		CHAR(1),
				imp_det		CHAR(1),
				imp_tod		CHAR(1)
			END RECORD
DEFINE rm_det_grp	ARRAY[50] OF RECORD
				grupo_act	LIKE actt010.a10_grupo_act,
				a01_nombre	LIKE actt001.a01_nombre,
				a10_valor_mb	LIKE actt010.a10_valor_mb,
				tot_dep_ant	LIKE actt010.a10_tot_dep_mb,
				tot_dep_act	LIKE actt010.a10_tot_dep_mb,
				a10_tot_dep_mb	LIKE actt010.a10_tot_dep_mb
			END RECORD
DEFINE rm_det_ctb	ARRAY[50] OF RECORD
				cuenta		LIKE ctbt010.b10_cuenta,
				saldo_ant	DECIMAL(14,2),
				mov_neto_db	DECIMAL(14,2),
				mov_neto_cr	DECIMAL(14,2),
				saldo_fin	DECIMAL(14,2)
			END RECORD
DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE vm_gru_max	INTEGER
DEFINE vm_gru_det	INTEGER
DEFINE vm_ctb_max	INTEGER
DEFINE vm_ctb_det	INTEGER
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp304.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp304'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE cuantos		INTEGER

CALL fl_nivel_isolation()
SELECT a01_compania cia_gru, a01_grupo_act grupo, a01_nombre nom_gru,
	a01_aux_activo[1, 8] cta_gru
	FROM actt001
	WHERE a01_compania = vg_codcia
UNION
SELECT a01_compania cia_gru, a01_grupo_act grupo, a01_nombre nom_gru,
	a01_aux_dep_act[1, 8] cta_gru
	FROM actt001
	WHERE a01_compania = vg_codcia
	INTO TEMP tmp_gru
SELECT COUNT(*) INTO cuantos FROM tmp_gru
IF cuantos = 0 THEN
	DROP TABLE tmp_gru
	CALL fl_mostrar_mensaje('No existen grupos de activos.', 'stop')
	EXIT PROGRAM
END IF
LET vm_gru_max = 50
LET vm_ctb_max = 50
OPEN WINDOW w_actf304_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST - 1)
OPEN FORM f_actf304_1 FROM '../forms/actf304_1'
DISPLAY FORM f_actf304_1
CALL setea_botones()
LET vm_gru_det = 0
LET vm_ctb_det = 0
CALL muestra_contadores(0, 0, 0, 0)
INITIALIZE rm_par.*, rm_imp.* TO NULL
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en ACTIVOS FIJOS.', 'stop')
	DROP TABLE tmp_gru
	CLOSE WINDOW w_actf304_1
	EXIT PROGRAM
END IF
LET vm_fecha_ini = MDY(01, 01, YEAR(TODAY))
LET vm_fecha_fin = MDY(rm_a00.a00_mespro, 01, rm_a00.a00_anopro) - 1 UNITS DAY
IF vm_fecha_ini > vm_fecha_fin THEN
	LET vm_fecha_ini = MDY(01, 01, YEAR(vm_fecha_fin))
END IF
LET rm_par.anio_ini = YEAR(vm_fecha_ini)
LET rm_par.mes_ini  = MONTH(vm_fecha_ini)
LET rm_par.anio_fin = YEAR(vm_fecha_fin)
LET rm_par.mes_fin  = MONTH(vm_fecha_fin)
LET rm_imp.imp_sal  = 'S'
LET rm_imp.imp_det  = 'N'
LET rm_imp.imp_tod  = 'N'
WHILE TRUE
	CALL borrar_detalle()
	CALL control_lee_cabecera()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF NOT preparar_consulta() THEN
		CONTINUE WHILE
	END IF
	CALL control_muestra_detalle_gru()
	DROP TABLE tmp_mov
	DROP TABLE tmp_ctb
END WHILE
DROP TABLE tmp_gru
CLOSE WINDOW w_actf304_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE a_ini, m_ini	SMALLINT
DEFINE a_fin, m_fin	SMALLINT
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE FIELD anio_ini
		LET a_ini = rm_par.anio_ini
	BEFORE FIELD mes_ini
		LET m_ini = rm_par.mes_ini
	BEFORE FIELD anio_fin
		LET a_fin = rm_par.anio_fin
	BEFORE FIELD mes_fin
		LET m_fin = rm_par.mes_fin
	AFTER FIELD anio_ini
		IF rm_par.anio_ini IS NULL THEN
			LET rm_par.anio_ini = a_ini
			DISPLAY BY NAME rm_par.anio_ini
		END IF
	AFTER FIELD mes_ini
		IF rm_par.mes_ini IS NULL THEN
			LET rm_par.mes_ini = m_ini
			DISPLAY BY NAME rm_par.mes_ini
		END IF
	AFTER FIELD anio_fin
		IF rm_par.anio_fin IS NULL THEN
			LET rm_par.anio_fin = a_fin
			DISPLAY BY NAME rm_par.anio_fin
		END IF
	AFTER FIELD mes_fin
		IF rm_par.mes_fin IS NULL THEN
			LET rm_par.mes_fin = m_fin
			DISPLAY BY NAME rm_par.mes_fin
		END IF
	AFTER INPUT
		LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
		LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin)
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF fec_ini > fec_fin THEN
			CALL fl_mostrar_mensaje('El periodo inicial debe ser menor o igual que el periodo final.', 'exclamation')
                        CONTINUE INPUT
                END IF
		IF EXTEND(fec_fin, YEAR TO MONTH) > EXTEND(TODAY, YEAR TO MONTH)
		THEN
			CALL fl_mostrar_mensaje('El periodo final no puede ser mayor al periodo actual.', 'exclamation')
                        CONTINUE INPUT
                END IF
END INPUT

END FUNCTION



FUNCTION preparar_consulta()
DEFINE query		CHAR(3500)
DEFINE fec_ini, fec_fin	DATE

LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET query   = ' SELECT grupo, nom_gru, 0.00 saldo_ini, ',
			'SUM(CASE WHEN a12_valor_mb >= 0 ',
				'THEN a12_valor_mb ',
				'ELSE 0 ',
			'END) valor_ing, ',
			'SUM(CASE WHEN a12_valor_mb <= 0 ',
				'THEN a12_valor_mb ',
				'ELSE 0 ',
			'END) valor_egr ',
		' FROM tmp_gru, actt010, OUTER actt012 ',
		' WHERE a10_compania      = cia_gru ',
		'   AND a10_grupo_act     = grupo ',
		'   AND a10_estado       <> "B" ',
		'   AND a12_compania      = a10_compania ',
		'   AND a12_codigo_bien   = a10_codigo_bien ',
		'   AND DATE(a12_fecing) BETWEEN "', fec_ini,
					  '" AND "', fec_fin, '"',
		' GROUP BY 1, 2, 3 ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
SELECT COUNT(*) INTO vm_gru_det FROM t1
IF vm_gru_det = 0 THEN
	DROP TABLE t1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
LET query = ' SELECT grupo, nom_gru, NVL(SUM(a12_valor_mb), 0) saldo_ini, ',
			'0.00 valor_ing, 0.00 valor_egr ',
		' FROM tmp_gru, actt010, actt012 ',
		' WHERE grupo            <> 1 ',
		'   AND a10_compania      = cia_gru ',
		'   AND a10_grupo_act     = grupo ',
		'   AND a10_estado       <> "B" ',
		'   AND a12_compania      = a10_compania ',
		'   AND a12_codigo_bien   = a10_codigo_bien ',
		'   AND DATE(a12_fecing)  < "', fec_ini, '"',
		' GROUP BY 1, 2, 4, 5 ',
		' UNION ',
		' SELECT grupo, nom_gru, NVL(SUM(a12_valor_mb), 0) saldo_ini, ',
			'0.00 valor_ing, 0.00 valor_egr ',
		' FROM tmp_gru, actt010, actt012 ',
		' WHERE grupo             = 1 ',
		'   AND a10_compania      = cia_gru ',
		'   AND a10_grupo_act     = grupo ',
		'   AND a10_estado       <> "B" ',
		'   AND a12_compania      = a10_compania ',
		'   AND a12_codigo_bien   = a10_codigo_bien ',
		'   AND DATE(a12_fecing)  < "', fec_ini, '"',
		'   AND a12_valor_mb      > 0 ',
		' GROUP BY 1, 2, 4, 5 ',
		' UNION ',
		' SELECT grupo, nom_gru, NVL(SUM(a12_valor_mb), 0) saldo_ini, ',
			'0.00 valor_ing, 0.00 valor_egr ',
		' FROM tmp_gru, actt010, actt012 ',
		' WHERE grupo             = 1 ',
		'   AND a10_compania      = cia_gru ',
		'   AND a10_grupo_act     = grupo ',
		'   AND a10_estado       <> "B" ',
		'   AND a12_compania      = a10_compania ',
		'   AND a12_codigo_bien   = a10_codigo_bien ',
		'   AND YEAR(a12_fecing) <= ', YEAR(fec_ini - 1 UNITS YEAR),
		'   AND a12_valor_mb      < 0 ',
		' GROUP BY 1, 2, 4, 5 ',
		' INTO TEMP t2 '
PREPARE exec_t2 FROM query
EXECUTE exec_t2
SELECT grupo, nom_gru, NVL(SUM(saldo_ini), 0) saldo_ini,
	NVL(SUM(valor_ing), 0) valor_ing, NVL(SUM(valor_egr), 0) valor_egr
	FROM t2
	GROUP BY 1, 2
	INTO TEMP t3
DROP TABLE t2
SELECT t1.grupo, t1.nom_gru, t1.saldo_ini + NVL(t3.saldo_ini, 0) saldo_ini,
	t1.valor_ing + NVL(t3.valor_ing, 0) valor_ing,
	t1.valor_egr + NVL(t3.valor_egr, 0) valor_egr,
	t1.saldo_ini + NVL(t3.saldo_ini, 0) + t1.valor_ing +
	NVL(t3.valor_ing, 0) + t1.valor_egr + NVL(t3.valor_egr, 0) saldo_fin
	FROM t1, OUTER t3
	WHERE t1.grupo = t3.grupo
	INTO TEMP tmp_mov
DROP TABLE t1
DROP TABLE t3
SELECT COUNT(*) INTO vm_gru_det FROM tmp_mov
SELECT b13_compania, b13_tipo_comp, b13_num_comp, b13_cuenta, b13_valor_base
	FROM ctbt013
	WHERE b13_compania      = vg_codcia
	  AND b13_fec_proceso  <= fec_fin
	  AND b13_cuenta[1, 8] IN (SELECT cta_gru FROM tmp_gru)
	INTO TEMP tmp_b13
SELECT grupo, NVL(b13_cuenta, cta_gru) cuenta,
	NVL(SUM(b13_valor_base), 0) sal_ant
	FROM ctbt012, tmp_b13, OUTER tmp_gru
	WHERE b12_compania    = b13_compania
	  AND b12_tipo_comp   = b13_tipo_comp
	  AND b12_num_comp    = b13_num_comp
	  AND b12_estado      = "M"
	  AND b12_fec_proceso < fec_ini
	  AND cta_gru         = b13_cuenta[1, 8]
	GROUP BY 1, 2
UNION
SELECT grupo, NVL(b13_cuenta[1, 8], cta_gru[1, 8]) cuenta,
	NVL(SUM(b13_valor_base), 0) sal_ant
	FROM ctbt012, tmp_b13, OUTER tmp_gru
	WHERE b12_compania    = b13_compania
	  AND b12_tipo_comp   = b13_tipo_comp
	  AND b12_num_comp    = b13_num_comp
	  AND b12_estado      = "M"
	  AND b12_fec_proceso < fec_ini
	  AND cta_gru         = b13_cuenta[1, 8]
	GROUP BY 1, 2
	INTO TEMP t1
LET query = 'SELECT grupo, NVL(b13_cuenta, cta_gru) cuenta, ',
		'SUM(CASE WHEN b13_valor_base >= 0 ',
				'THEN b13_valor_base ',
				'ELSE 0.00 ',
			'END) val_db, ',
		'SUM(CASE WHEN b13_valor_base < 0 ',
				'THEN b13_valor_base ',
				'ELSE 0.00 ',
			'END) val_cr ',
		'FROM ctbt012, tmp_b13, OUTER tmp_gru ',
		'WHERE b12_compania    = b13_compania ',
		'  AND b12_tipo_comp   = b13_tipo_comp ',
		'  AND b12_num_comp    = b13_num_comp ',
		'  AND b12_estado      = "M" ',
		'  AND b12_fec_proceso BETWEEN "', fec_ini,
					'" AND "', fec_fin, '"',
		'  AND cta_gru         = b13_cuenta[1, 8] ',
		'GROUP BY 1, 2 ',
		'UNION ',
		'SELECT grupo, NVL(b13_cuenta[1, 8], cta_gru[1, 8]) cuenta, ',
		'SUM(CASE WHEN b13_valor_base > 0 ',
				'THEN b13_valor_base ',
				'ELSE 0.00 ',
			'END) val_db, ',
		'SUM(CASE WHEN b13_valor_base < 0 ',
				'THEN b13_valor_base ',
				'ELSE 0.00 ',
			'END) val_cr ',
		'FROM ctbt012, tmp_b13, OUTER tmp_gru ',
		'WHERE b12_compania    = b13_compania ',
		'  AND b12_tipo_comp   = b13_tipo_comp ',
		'  AND b12_num_comp    = b13_num_comp ',
		'  AND b12_estado      = "M" ',
		'  AND b12_fec_proceso BETWEEN "', fec_ini,
					'" AND "', fec_fin, '"',
		'  AND cta_gru         = b13_cuenta[1, 8] ',
		'GROUP BY 1, 2 ',
		'INTO TEMP t2 '
PREPARE exec_ctb FROM query
EXECUTE exec_ctb
DROP TABLE tmp_b13
SELECT t1.grupo, t1.cuenta, NVL(SUM(t1.sal_ant), 0) sal_ant,
	NVL(SUM(t2.val_db), 0) val_db, NVL(SUM(t2.val_cr), 0) val_cr,
	NVL(SUM(t1.sal_ant + NVL(t2.val_db, 0) + NVL(t2.val_cr, 0)), 0) sal_fin
	FROM t1, OUTER t2
	WHERE t1.grupo  = t2.grupo
	  AND t1.cuenta = t2.cuenta
	GROUP BY 1, 2
UNION
SELECT t2.grupo, t2.cuenta, NVL(SUM(t1.sal_ant), 0) sal_ant,
	NVL(SUM(t2.val_db), 0) val_db, NVL(SUM(t2.val_cr), 0) val_cr,
	NVL(SUM(NVL(t1.sal_ant, 0) + NVL(t2.val_db, 0) +
	NVL(t2.val_cr, 0)), 0) sal_fin
	FROM t2, OUTER t1
	WHERE t2.grupo  = t1.grupo
	  AND t2.cuenta = t1.cuenta
	GROUP BY 1, 2
UNION
SELECT grupo, '12010101002', 0.00, 0.00, 0.00, 0.00
	FROM tmp_gru
	WHERE grupo = 1
	INTO TEMP tmp_ctb
DROP TABLE t1
DROP TABLE t2
SELECT COUNT(*) INTO vm_ctb_det FROM tmp_ctb
RETURN 1

END FUNCTION



FUNCTION setea_botones()

DISPLAY "GR" 			TO tit_col1
DISPLAY "Nombre Grupo" 		TO tit_col2
DISPLAY "Val.Ant.Lib." 		TO tit_col3
DISPLAY "Valor Bien"		TO tit_col4
DISPLAY "Dep/Vta/Baj"		TO tit_col5
DISPLAY "Valor Libros"		TO tit_col6

DISPLAY "Cuenta"		TO tit_col7
DISPLAY "Saldo Anterior"	TO tit_col8
DISPLAY "Debito"		TO tit_col9
DISPLAY "Credito"		TO tit_col10
DISPLAY "Saldo Final"		TO tit_col11

END FUNCTION



FUNCTION control_muestra_detalle_gru()
DEFINE i, j, col	SMALLINT
DEFINE fec_fin		DATE
DEFINE query		CHAR(1500)

LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin)
		+ 1 UNITS MONTH - 1 UNITS DAY
FOR i = 1 TO 10
	LET rm_orden[i] = ''
END FOR
LET col           = 1
LET vm_columna_1  = col
LET vm_columna_2  = 2
LET rm_orden[col] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM tmp_mov ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE mov FROM query
	DECLARE q_mov CURSOR FOR mov
	LET vm_gru_det = 1
	FOREACH q_mov INTO rm_det_grp[vm_gru_det].*
		LET vm_gru_det = vm_gru_det + 1
		IF vm_gru_det > vm_gru_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_gru_det = vm_gru_det - 1
	IF vm_gru_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	CALL mostrar_total_gru()
	LET int_flag = 0
	CALL set_count(vm_gru_det)
	DISPLAY ARRAY rm_det_grp TO rm_det_grp.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY                 
		ON KEY(F5)
			LET i = arr_curr()
			CALL ubicarse_detalle_ctb()
			IF int_flag THEN
				EXIT DISPLAY                 
			END IF
			CALL muestra_contadores(i, vm_gru_det, 0, vm_ctb_det)
			LET int_flag = 0
		ON KEY(F6)
			IF fec_fin <= vm_fecha_fin THEN
				LET i = arr_curr()
				CALL ver_cons_impr_activos(
						rm_det_grp[i].grupo_act, 'C')
				LET int_flag = 0
			END IF
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_movimientos(rm_det_grp[i].grupo_act)
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_transacciones(rm_det_grp[i].grupo_act)
			LET int_flag = 0
		ON KEY(F9)
			IF fec_fin <= vm_fecha_fin THEN
				LET i = arr_curr()
				CALL ver_depreciaciones(rm_det_grp[i].grupo_act)
				LET int_flag = 0
			END IF
		ON KEY(F10)
			LET i = arr_curr()
			CALL control_imprimir_gru(i)
			CALL cargar_detalle_ctb(rm_det_grp[i].grupo_act)
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
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
			CALL dialog.keysetlabel('F5','Detalle')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			DISPLAY rm_det_grp[i].a01_nombre TO descripcion
			CALL mostrar_detalle_ctb(rm_det_grp[i].grupo_act)
			CALL muestra_contadores(i, vm_gru_det, 0, vm_ctb_det)
			IF fec_fin > vm_fecha_fin THEN
				CALL dialog.keysetlabel('F6','')
				CALL dialog.keysetlabel('F9','')
			ELSE
				CALL dialog.keysetlabel('F6','Datos')
				CALL dialog.keysetlabel('F9','Depreciaciones')
			END IF
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE

END FUNCTION



FUNCTION ubicarse_detalle_ctb()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE i, j		SMALLINT
DEFINE query		CHAR(1500)

LET int_flag = 0
CALL set_count(vm_ctb_det)
DISPLAY ARRAY rm_det_ctb TO rm_det_ctb.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY                 
	ON KEY(F5)
		LET int_flag = 0
		EXIT DISPLAY                 
	ON KEY(F7)
		LET i = arr_curr()
		CALL ver_movimientos_ctb(rm_det_ctb[i].cuenta)
		LET int_flag = 0
	ON KEY(F10)
		CALL imprimir_balance_comp()
		LET int_flag = 0
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT','')
		CALL dialog.keysetlabel('F5','Cabecera')
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL muestra_contadores(0, vm_gru_det, i, vm_ctb_det)
		CALL fl_lee_cuenta(vg_codcia, rm_det_ctb[i].cuenta)
			RETURNING r_b10.*
		DISPLAY BY NAME r_b10.b10_descripcion
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION mostrar_detalle_ctb(grupo_act)
DEFINE grupo_act	LIKE actt001.a01_grupo_act
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE i		SMALLINT

CALL limpiar_detalle_ctb()
CALL cargar_detalle_ctb(grupo_act)
FOR i = 1 TO vm_ctb_det
	DISPLAY rm_det_ctb[i].* TO rm_det_ctb[i].*
END FOR
CALL fl_lee_cuenta(vg_codcia, rm_det_ctb[1].cuenta) RETURNING r_b10.*
DISPLAY BY NAME r_b10.b10_descripcion
CALL mostrar_total_ctb()

END FUNCTION



FUNCTION cargar_detalle_ctb(grupo_act)
DEFINE grupo_act	LIKE actt001.a01_grupo_act
DEFINE i		SMALLINT

DECLARE q_ctb CURSOR FOR
	SELECT cuenta, sal_ant, val_db, val_cr, sal_fin
		FROM tmp_ctb
		WHERE grupo = grupo_act
		ORDER BY 1
LET vm_ctb_det = 1
FOREACH q_ctb INTO rm_det_ctb[vm_ctb_det].*
	LET vm_ctb_det = vm_ctb_det + 1
	IF vm_ctb_det > vm_ctb_max THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_ctb_det = vm_ctb_det - 1

END FUNCTION



FUNCTION mostrar_total_gru()
DEFINE i		SMALLINT
DEFINE valor_mb_g	DECIMAL(14,2)
DEFINE tot_dep_ant_g	DECIMAL(14,2)
DEFINE tot_dep_act_g	DECIMAL(14,2)
DEFINE tot_dep_mb_g	DECIMAL(14,2)

LET valor_mb_g    = 0
LET tot_dep_ant_g = 0
LET tot_dep_act_g = 0
LET tot_dep_mb_g  = 0
FOR i = 1 TO vm_gru_det
	LET valor_mb_g    = valor_mb_g    + rm_det_grp[i].a10_valor_mb
	LET tot_dep_ant_g = tot_dep_ant_g + rm_det_grp[i].tot_dep_ant
	LET tot_dep_act_g = tot_dep_act_g + rm_det_grp[i].tot_dep_act
	LET tot_dep_mb_g  = tot_dep_mb_g  + rm_det_grp[i].a10_tot_dep_mb
END FOR
DISPLAY BY NAME valor_mb_g, tot_dep_ant_g, tot_dep_act_g, tot_dep_mb_g

END FUNCTION



FUNCTION mostrar_total_ctb()
DEFINE tot_mov_neto_db	DECIMAL(14,2)
DEFINE tot_mov_neto_cr	DECIMAL(14,2)
DEFINE i		SMALLINT

LET tot_mov_neto_db = 0
LET tot_mov_neto_cr = 0
FOR i = 1 TO vm_ctb_det
	LET tot_mov_neto_db = tot_mov_neto_db + rm_det_ctb[i].mov_neto_db
	LET tot_mov_neto_cr = tot_mov_neto_cr + rm_det_ctb[i].mov_neto_cr
END FOR
DISPLAY BY NAME tot_mov_neto_db, tot_mov_neto_cr

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row, num_row2, max_row2)
DEFINE num_row, max_row	SMALLINT
DEFINE num_row2		SMALLINT
DEFINE max_row2		SMALLINT

DISPLAY BY NAME num_row, max_row, num_row2, max_row2

END FUNCTION



FUNCTION borrar_detalle()

CALL limpiar_detalle_gru()
CALL limpiar_detalle_ctb()
CLEAR num_row, max_row, valor_mb_g, tot_dep_ant_g, tot_dep_act_g, tot_dep_mb_g,
	descripcion, num_row2, max_row2, tot_mov_neto_db, tot_mov_neto_cr,
	b10_descripcion

END FUNCTION



FUNCTION limpiar_detalle_gru()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_det_grp')
	CLEAR rm_det_grp[i].*
END FOR
FOR i = 1 TO vm_gru_max
	INITIALIZE rm_det_grp[i].* TO NULL
END FOR

END FUNCTION



FUNCTION limpiar_detalle_ctb()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_det_ctb')
	CLEAR rm_det_ctb[i].*
END FOR
FOR i = 1 TO vm_ctb_max
	INITIALIZE rm_det_ctb[i].* TO NULL
END FOR

END FUNCTION



FUNCTION ver_cons_impr_activos(grupo, tipo)
DEFINE grupo		LIKE actt001.a01_grupo_act
DEFINE tipo		CHAR(1)
DEFINE param		VARCHAR(120)
DEFINE prog		VARCHAR(10)
DEFINE fec_ini, fec_fin	DATE

LET param = NULL
IF tipo = 'I' THEN
	LET param = ' ', vg_codloc
END IF
LET param   = param CLIPPED, ' "X" ', grupo, ' 0 ', ' 0 '
LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET param = param CLIPPED, ' "', fec_fin, '" "', fec_ini, '"'
CASE tipo
	WHEN 'C' LET prog = 'actp300'
	WHEN 'I' LET prog = 'actp400'
END CASE
CALL ejecuta_comando('ACTIVOS', vg_modulo, prog, param)

END FUNCTION



FUNCTION ver_movimientos(grupo)
DEFINE grupo		LIKE actt001.a01_grupo_act
DEFINE param		VARCHAR(120)
DEFINE fec_ini, fec_fin	DATE

LET param = ' 0 ', grupo, ' 0 '
LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET param = param CLIPPED, ' "', fec_ini, '" "', fec_fin, '"'
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp301', param)

END FUNCTION



FUNCTION ver_transacciones(grupo)
DEFINE grupo		LIKE actt001.a01_grupo_act
DEFINE cod_tran		LIKE actt012.a12_codigo_tran
DEFINE i		SMALLINT
DEFINE param		VARCHAR(120)
DEFINE fec_ini, fec_fin	DATE

LET param   = ' 0 ', grupo, ' 0 "XX" '
LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET param = param CLIPPED, ' "', fec_ini, '" "', fec_fin, '"'
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp302', param)

END FUNCTION



FUNCTION ver_depreciaciones(grupo)
DEFINE grupo		LIKE actt001.a01_grupo_act
DEFINE param		VARCHAR(120)

LET param = rm_par.anio_ini, ' ', rm_par.mes_ini, ' ', rm_par.anio_fin, ' ',
		rm_par.mes_fin, ' 0 ', grupo, ' 0 "X" '
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp303', param)

END FUNCTION



FUNCTION ver_movimientos_ctb(cuenta)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE param		VARCHAR(120)
DEFINE fec_ini, fec_fin	DATE

LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET param = ' "', cuenta CLIPPED, '" "', fec_ini, '" "', fec_fin, '" "',
		rg_gen.g00_moneda_base, '"'
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp302', param)

END FUNCTION



FUNCTION imprimir_balance_comp()
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE param		VARCHAR(120)

SQL
	SELECT MIN(cta_gru[1, 7]) || '0'  INTO $cuenta FROM tmp_gru
END SQL
LET param = ' "', cuenta CLIPPED, '"'
SQL
	SELECT MAX(cta_gru) || '002'  INTO $cuenta FROM tmp_gru
END SQL
LET param = param CLIPPED, ' "', cuenta CLIPPED, '" ', rm_par.anio_fin
IF rm_par.anio_ini < rm_par.anio_fin THEN
	LET param = param CLIPPED, ' 1'
ELSE
	LET param = param CLIPPED, ' ', rm_par.mes_ini
END IF
LET param = param CLIPPED, ' ', rm_par.mes_fin, ' "N" "S" "S"'
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp401', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(120)
DEFINE run_prog		VARCHAR(10)
DEFINE comando          CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo, vg_separador,
		'fuentes', vg_separador, run_prog, prog, ' ', vg_base, ' ',
		mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION control_imprimir_gru(pos)
DEFINE pos		SMALLINT

OPEN WINDOW w_actf304_2 AT 07, 17 WITH 09 ROWS, 48 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST)
OPEN FORM f_actf304_2 FROM '../forms/actf304_2'
DISPLAY FORM f_actf304_2
WHILE TRUE
	CALL ejecutar_reportes(pos)
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_actf304_2
RETURN

END FUNCTION



FUNCTION ejecutar_reportes(pos)
DEFINE pos		SMALLINT
DEFINE r_imp		RECORD 
				imp_sal		CHAR(1),
				imp_det		CHAR(1),
				imp_tod		CHAR(1)
			END RECORD
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

MESSAGE 'Presione F12 para mostrar el reporte...'
LET r_imp.* = rm_imp.*
LET int_flag = 0
INPUT BY NAME rm_imp.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		LET rm_imp.* = r_imp.*
		EXIT INPUT
	AFTER INPUT
		IF rm_imp.imp_sal IS NULL THEN
			LET rm_imp.imp_sal = 'S'
		END IF
		IF rm_imp.imp_det IS NULL THEN
			LET rm_imp.imp_det = 'N'
		END IF
		IF rm_imp.imp_tod IS NULL THEN
			LET rm_imp.imp_tod = 'N'
		END IF
		DISPLAY BY NAME rm_imp.*
END INPUT
IF int_flag THEN
	RETURN
END IF
MESSAGE '                                       '
IF rm_imp.imp_sal = 'S' THEN
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		RETURN
	END IF
	START REPORT reporte_grupo_activo TO PIPE comando
	FOR i = 1 TO vm_gru_det
		OUTPUT TO REPORT reporte_grupo_activo(i)
	END FOR
	FINISH REPORT reporte_grupo_activo
END IF
IF int_flag THEN
	RETURN
END IF
IF rm_imp.imp_det = 'S' THEN
	CALL ver_cons_impr_activos(rm_det_grp[pos].grupo_act, 'I')
END IF
IF rm_imp.imp_tod = 'S' THEN
	CALL ver_cons_impr_activos(0, 'I')
END IF

END FUNCTION



REPORT reporte_grupo_activo(i)
DEFINE i		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape, j	SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	96
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
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 003, r_g01.g01_razonsocial,
  	      COLUMN 088, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 033, "SALDO POR GRUPO DE ACTIVOS FIJOS",
	      COLUMN 090, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 032, "** PERIODO: ",
	      COLUMN 045, rm_par.anio_ini USING "&&&&", ' - ',
				rm_par.mes_ini USING "&&",
	      COLUMN 057, rm_par.anio_fin USING "&&&&", ' - ',
				rm_par.mes_fin USING "&&"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 078, usuario CLIPPED
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "GR",
	      COLUMN 005, "NOMBRE DEL GRUPO",
	      COLUMN 031, "VALOR ANT. LIB.", 
	      COLUMN 048, " VALOR DEL BIEN",
	      COLUMN 065, "DEPR/VENTA/BAJA",
	      COLUMN 082, "   VALOR LIBROS"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 10 LINES
	PRINT COLUMN 001, rm_det_grp[i].grupo_act	USING "&&",
	      COLUMN 005, rm_det_grp[i].a01_nombre	CLIPPED
	CALL cargar_detalle_ctb(rm_det_grp[i].grupo_act)
	FOR j = 1 TO vm_ctb_det
		CALL fl_lee_cuenta(vg_codcia, rm_det_ctb[j].cuenta)
			RETURNING r_b10.*
		PRINT COLUMN 003, rm_det_ctb[j].cuenta	CLIPPED,
		      COLUMN 016, r_b10.b10_descripcion[1, 14] CLIPPED,
		      COLUMN 031, rm_det_ctb[j].saldo_ant
					USING '(((,(((,((&.##)',
		      COLUMN 048, rm_det_ctb[j].mov_neto_db
					USING '(((,(((,((&.##)',
		      COLUMN 065, rm_det_ctb[j].mov_neto_cr
					USING '(((,(((,((&.##)',
		      COLUMN 082, rm_det_ctb[j].saldo_fin
					USING '(((,(((,((&.##)'
	END FOR
	SKIP 1 LINES
	PRINT COLUMN 005, "TOT. DE ", rm_det_grp[i].a01_nombre[1, 16],
	      COLUMN 031, rm_det_grp[i].a10_valor_mb	USING "----,---,--&.##",
	      COLUMN 048, rm_det_grp[i].tot_dep_ant	USING "(((,(((,((&.##)",
	      COLUMN 065, rm_det_grp[i].tot_dep_act	USING "----,---,--&.##",
	      COLUMN 082, rm_det_grp[i].a10_tot_dep_mb	USING "----,---,--&.##"
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 033, "---------------",
	      COLUMN 050, "---------------",
	      COLUMN 067, "---------------",
	      COLUMN 084, "---------------"
	PRINT COLUMN 005, "TOTALES DE LOS GRUPOS ==>",
	      COLUMN 031, SUM(rm_det_grp[i].a10_valor_mb)
					USING "----,---,--&.##",
	      COLUMN 048, SUM(rm_det_grp[i].tot_dep_ant)
					USING "(((,(((,((&.##)",
	      COLUMN 065, SUM(rm_det_grp[i].tot_dep_act)
					USING "----,---,--&.##",
	      COLUMN 082, SUM(rm_det_grp[i].a10_tot_dep_mb)
					USING "----,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp

END REPORT

--------------------------------------------------------------------------------
-- Titulo            : actp301.4gl - Consulta de Movimientos de Activos Fijos
-- Elaboracion       : 18-Nov-2009
-- Autor             : NPC
-- Formato Ejecucion : fglrun actp301 base modulo compania
--				[localidad grupo tipo fec_ini fec_fin [activo]]
-- Ultima Correccion :
-- Motivo Correccion :
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par		RECORD 
				a10_localidad	LIKE actt010.a10_localidad,
				g02_nombre	LIKE gent002.g02_nombre,
				a10_grupo_act 	LIKE actt010.a10_grupo_act,
				a01_nombre 	LIKE actt001.a01_nombre,
				a10_tipo_act	LIKE actt010.a10_tipo_act,
				a02_nombre 	LIKE actt002.a02_nombre,
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_descripcion	LIKE actt010.a10_descripcion,
				fecha_inicial	LIKE actt010.a10_fecha_comp,
				fecha_final	LIKE actt010.a10_fecha_comp,
				saldo_ini	LIKE actt010.a10_valor_mb
			END RECORD
DEFINE rm_detalle	ARRAY[10000] OF RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				valor_ing	LIKE actt012.a12_valor_mb,
				valor_egr	LIKE actt012.a12_valor_mb,
				saldo_fin	LIKE actt012.a12_valor_mb
			END RECORD
DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE vm_max_det	INTEGER
DEFINE vm_num_det	INTEGER



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp301.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 8 AND num_args() <> 9 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp301'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_det = 10000
OPEN WINDOW w_actf301_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST - 1)
OPEN FORM f_actf301_1 FROM '../forms/actf301_1'
DISPLAY FORM f_actf301_1
CALL setea_botones()
LET vm_num_det = 0
CALL muestra_contadores(0, 0)
INITIALIZE rm_par.* TO NULL 
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en ACTIVOS FIJOS.', 'stop')
	CLOSE WINDOW w_actf301_1
	EXIT PROGRAM
END IF
IF num_args() <> 3 THEN
	CALL llamada_de_otro_programa()
	CLOSE WINDOW w_actf301_1
	EXIT PROGRAM
END IF
LET rm_par.fecha_inicial = MDY(01, 01, rm_a00.a00_anopro)
LET rm_par.fecha_final   = TODAY
WHILE TRUE
	CALL borrar_detalle()
	CALL control_lee_cabecera()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF NOT preparar_consulta('C') THEN
		DROP TABLE tmp_mov
		CONTINUE WHILE
	END IF
	CALL control_muestra_detalle()
	DROP TABLE tmp_mov
END WHILE
CLOSE WINDOW w_actf301_1

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g02		RECORD LIKE gent002.*

LET rm_par.a10_localidad = arg_val(4)
IF rm_par.a10_localidad = 0 THEN
	LET rm_par.a10_localidad = NULL
END IF
LET rm_par.a10_grupo_act = arg_val(5)
IF rm_par.a10_grupo_act = 0 THEN
	LET rm_par.a10_grupo_act = NULL
END IF
LET rm_par.a10_tipo_act  = arg_val(6)
IF rm_par.a10_tipo_act = 0 THEN
	LET rm_par.a10_tipo_act = NULL
END IF
LET rm_par.fecha_inicial = arg_val(7)
LET rm_par.fecha_final   = arg_val(8)
IF num_args() > 8 THEN
	LET rm_par.a10_codigo_bien = arg_val(9)
END IF
IF rm_par.a10_localidad IS NOT NULL THEN
	CALL fl_lee_localidad(vg_codcia, rm_par.a10_localidad) RETURNING r_g02.*
	IF r_g02.g02_localidad IS NULL THEN
		CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
		RETURN
	END IF	
	LET rm_par.g02_nombre = r_g02.g02_nombre
END IF
IF rm_par.a10_grupo_act IS NOT NULL THEN
	CALL fl_lee_grupo_activo(vg_codcia, rm_par.a10_grupo_act)
		RETURNING r_a01.*
	IF r_a01.a01_grupo_act IS NULL THEN
		CALL fl_mostrar_mensaje('No existe grupo de activo.', 'exclamation')
		RETURN
	END IF
	LET rm_par.a01_nombre = r_a01.a01_nombre
END IF
IF rm_par.a10_tipo_act IS NOT NULL THEN
	CALL fl_lee_tipo_activo(vg_codcia, rm_par.a10_tipo_act)
		RETURNING r_a02.*
	IF r_a02.a02_tipo_act IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de activo.', 'exclamation')
		RETURN
	END IF
	LET rm_par.a02_nombre = r_a02.a02_nombre
END IF
IF rm_par.a10_codigo_bien IS NOT NULL THEN
	CALL fl_lee_codigo_bien(vg_codcia, rm_par.a10_codigo_bien)
		RETURNING r_a10.*
	IF r_a10.a10_codigo_bien IS NULL THEN
		CALL fl_mostrar_mensaje('No existe este Activo Fijo en la compañía.', 'exclamation')
		RETURN
	END IF
	LET rm_par.a10_descripcion = r_a10.a10_descripcion
END IF
IF rm_par.fecha_inicial > rm_par.fecha_final THEN
	CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.', 'exclamation')
	RETURN
END IF
CALL borrar_detalle()
DISPLAY BY NAME rm_par.*
IF NOT preparar_consulta('C') THEN
	DROP TABLE tmp_mov
	RETURN
END IF
CALL control_muestra_detalle()
DROP TABLE tmp_mov

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(a10_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_par.a10_localidad = r_g02.g02_localidad
				LET rm_par.g02_nombre    = r_g02.g02_nombre
				DISPLAY BY NAME rm_par.a10_localidad,
						r_g02.g02_nombre
			END IF
		END IF
		IF INFIELD(a10_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia)
				RETURNING r_a01.a01_grupo_act, r_a01.a01_nombre
			IF r_a01.a01_grupo_act IS NOT NULL THEN
				LET rm_par.a10_grupo_act = r_a01.a01_grupo_act
				LET rm_par.a01_nombre    = r_a01.a01_nombre
				DISPLAY BY NAME rm_par.a10_grupo_act,
						rm_par.a01_nombre
			END IF
		END IF
		IF INFIELD(a10_tipo_act) THEN
			CALL fl_ayuda_tipo_activo(vg_codcia,
							rm_par.a10_grupo_act)
				RETURNING r_a02.a02_tipo_act, r_a02.a02_nombre
			IF r_a02.a02_tipo_act IS NOT NULL THEN
				LET rm_par.a10_tipo_act = r_a02.a02_tipo_act
				LET rm_par.a02_nombre   = r_a02.a02_nombre
				DISPLAY BY NAME rm_par.a10_tipo_act,
						rm_par.a02_nombre
			END IF
		END IF
		IF INFIELD(a10_codigo_bien) THEN
			CALL fl_ayuda_codigo_bien(vg_codcia,
						rm_par.a10_grupo_act,
						rm_par.a10_tipo_act, 'T', 1)
				RETURNING r_a10.a10_codigo_bien,
					  r_a10.a10_descripcion
			IF r_a10.a10_codigo_bien IS NOT NULL THEN
				LET rm_par.a10_codigo_bien =
							r_a10.a10_codigo_bien
				LET rm_par.a10_descripcion =
							r_a10.a10_descripcion
				DISPLAY BY NAME rm_par.a10_codigo_bien,
						rm_par.a10_descripcion
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_inicial
		LET fec_ini = rm_par.fecha_inicial
	BEFORE FIELD fecha_final
		LET fec_fin = rm_par.fecha_final
	AFTER FIELD a10_localidad
		IF rm_par.a10_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.a10_localidad)
				RETURNING r_g02.*
			IF r_g02.g02_localidad IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
				NEXT FIELD a10_localidad
			END IF	
			LET rm_par.g02_nombre = r_g02.g02_nombre
		ELSE
			LET rm_par.g02_nombre = NULL
		END IF
		DISPLAY BY NAME rm_par.g02_nombre 
	AFTER FIELD a10_grupo_act
		IF rm_par.a10_grupo_act IS NOT NULL THEN
			CALL fl_lee_grupo_activo(vg_codcia,rm_par.a10_grupo_act)
				RETURNING r_a01.*
			IF r_a01.a01_grupo_act IS NULL THEN
				CALL fl_mostrar_mensaje('No existe grupo de activo.', 'exclamation')
				NEXT FIELD a10_grupo_act
			END IF
			LET rm_par.a01_nombre = r_a01.a01_nombre
		ELSE
			LET rm_par.a01_nombre = NULL
		END IF
		DISPLAY BY NAME rm_par.a01_nombre
	AFTER FIELD a10_tipo_act
		IF rm_par.a10_tipo_act IS NOT NULL THEN
			CALL fl_lee_tipo_activo(vg_codcia, rm_par.a10_tipo_act)
				RETURNING r_a02.*
			IF r_a02.a02_tipo_act IS NULL THEN
				CALL fl_mostrar_mensaje('No existe tipo de activo.', 'exclamation')
				NEXT FIELD a10_tipo_act
			END IF
			LET rm_par.a02_nombre = r_a02.a02_nombre
		ELSE
			LET rm_par.a02_nombre = NULL
		END IF
		DISPLAY BY NAME rm_par.a02_nombre
	AFTER FIELD a10_codigo_bien
		IF rm_par.a10_codigo_bien IS NOT NULL THEN
			CALL fl_lee_codigo_bien(vg_codcia,
						rm_par.a10_codigo_bien)
				RETURNING r_a10.*
			IF r_a10.a10_codigo_bien IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este Activo Fijo en la compañía.', 'exclamation')
				NEXT FIELD a10_codigo_bien
			END IF
			LET rm_par.a10_descripcion = r_a10.a10_descripcion
		ELSE
			LET rm_par.a10_descripcion = NULL
		END IF
		DISPLAY BY NAME rm_par.a10_descripcion
	AFTER FIELD fecha_inicial
		IF rm_par.fecha_inicial IS NULL THEN
			LET rm_par.fecha_inicial = fec_ini
			DISPLAY BY NAME rm_par.fecha_inicial
		END IF
	AFTER FIELD fecha_final
		IF rm_par.fecha_final IS NULL THEN
			LET rm_par.fecha_final = fec_fin
			DISPLAY BY NAME rm_par.fecha_final
		END IF
	AFTER INPUT
		{--
		IF rm_par.a10_localidad   IS NULL AND
		   rm_par.a10_grupo_act   IS NULL AND
		   rm_par.a10_tipo_act    IS NULL AND
		   rm_par.a10_codigo_bien IS NULL
		THEN
			CALL fl_mostrar_mensaje('Al menos debe digitar un criterio de busqueda para mostrar movimientos.', 'exclamation')
			CONTINUE INPUT
		END IF
		--}
		IF rm_par.fecha_inicial > rm_par.fecha_final THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION preparar_consulta(flag)
DEFINE flag		CHAR(1)
DEFINE query		CHAR(3500)
DEFINE exp_sel		CHAR(800)
DEFINE exp_loc		VARCHAR(100)
DEFINE exp_gru		VARCHAR(100)
DEFINE exp_tip		VARCHAR(100)
DEFINE exp_act		VARCHAR(100)
DEFINE exp_fec		VARCHAR(100)
DEFINE exp_grp		VARCHAR(100)

LET exp_loc = NULL
IF rm_par.a10_localidad IS NOT NULL THEN
	LET exp_loc = '   AND a10_localidad    = ', rm_par.a10_localidad
END IF
LET exp_gru = NULL
IF rm_par.a10_grupo_act IS NOT NULL THEN
	LET exp_gru = '   AND a10_grupo_act    = ', rm_par.a10_grupo_act  
END IF
LET exp_tip = NULL
IF rm_par.a10_tipo_act IS NOT NULL THEN
	LET exp_tip = '   AND a10_tipo_act     = ', rm_par.a10_tipo_act 
END IF
IF rm_par.a10_codigo_bien IS NOT NULL THEN
	LET exp_sel = 'a12_codigo_tran, a12_numero_tran, a12_fecing, ',
			'a12_referencia, ',
			'CASE WHEN a12_valor_mb >= 0 ',
				'THEN a12_valor_mb ',
				'ELSE 0 ',
			'END valor_ing, ',
			'CASE WHEN a12_valor_mb <= 0 ',
				'THEN a12_valor_mb ',
				'ELSE 0 ',
			'END valor_egr, '
	LET exp_act = '   AND a10_codigo_bien  = ', rm_par.a10_codigo_bien
	LET exp_grp = NULL
ELSE
	LET exp_sel = 'a12_codigo_tran, 0 a12_numero_tran, a12_fecing, ',
			'"VARIAS TRANSACCIONES" a12_referencia, ',
			'SUM(CASE WHEN a12_valor_mb >= 0 ',
				'THEN a12_valor_mb ',
				'ELSE 0 ',
			'END) valor_ing, ',
			'SUM(CASE WHEN a12_valor_mb <= 0 ',
				'THEN a12_valor_mb ',
				'ELSE 0 ',
			'END) valor_egr, '
	LET exp_act = NULL
	LET exp_grp = ' GROUP BY 1, 2, 3, 4, 7 '
END IF
CASE flag
	WHEN 'C'
		LET exp_fec = '   AND DATE(a12_fecing) BETWEEN "',
				rm_par.fecha_inicial, '" AND "',
				rm_par.fecha_final, '"'
	WHEN 'S'
		LET exp_fec = '   AND DATE(a12_fecing) < "',
					rm_par.fecha_inicial, '"'
END CASE
LET query = ' SELECT ', exp_sel CLIPPED,
			'0.00 saldo_fin ',
		' FROM actt010, actt012 ',
		' WHERE a10_compania     = ', vg_codcia,
		'   AND a10_estado      <> "B" ',
		exp_loc CLIPPED,
		exp_gru CLIPPED,
		exp_tip CLIPPED,
		exp_act CLIPPED,
		'   AND a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		exp_fec CLIPPED,
		exp_grp CLIPPED
CASE flag
	WHEN 'C' LET query = query CLIPPED, ' INTO TEMP tmp_mov '
	WHEN 'S'
		IF rm_par.a10_grupo_act = 1 OR rm_par.a10_grupo_act IS NULL THEN
			LET query = ' SELECT ', exp_sel CLIPPED,
					'0.00 saldo_fin ',
					' FROM actt010, actt012 ',
					' WHERE a10_compania     = ', vg_codcia,
					'   AND a10_estado      <> "B" ',
					exp_loc CLIPPED,
					exp_gru CLIPPED,
					exp_tip CLIPPED,
					exp_act CLIPPED,
				'   AND a12_compania     = a10_compania ',
				'   AND a12_codigo_bien  = a10_codigo_bien ',
					exp_fec CLIPPED,
					'   AND a10_grupo_act   <> 1 ',
					exp_grp CLIPPED,
				' UNION ',
				' SELECT ', exp_sel CLIPPED,
					'0.00 saldo_fin ',
					' FROM actt010, actt012 ',
					' WHERE a10_compania     = ', vg_codcia,
					'   AND a10_estado      <> "B" ',
					exp_loc CLIPPED,
					exp_gru CLIPPED,
					exp_tip CLIPPED,
					exp_act CLIPPED,
				'   AND a12_compania     = a10_compania ',
				'   AND a12_codigo_bien  = a10_codigo_bien ',
					exp_fec CLIPPED,
					'   AND a10_grupo_act    = 1 ',
					'   AND a12_valor_mb     > 0 ',
					exp_grp CLIPPED,
				' UNION ',
				' SELECT ', exp_sel CLIPPED,
					'0.00 saldo_fin ',
					' FROM actt010, actt012 ',
					' WHERE a10_compania     = ', vg_codcia,
					'   AND a10_estado      <> "B" ',
					exp_loc CLIPPED,
					exp_gru CLIPPED,
					exp_tip CLIPPED,
					exp_act CLIPPED,
				'   AND a12_compania     = a10_compania ',
				'   AND a12_codigo_bien  = a10_codigo_bien ',
					'   AND YEAR(a12_fecing) = ',
				YEAR(rm_par.fecha_inicial - 1 UNITS YEAR),
					'   AND a10_grupo_act    = 1 ',
					'   AND a12_valor_mb     < 0 ',
					exp_grp CLIPPED
		END IF
		LET query = query CLIPPED, ' INTO TEMP tmp_sal '
END CASE
PREPARE expresion FROM query
EXECUTE expresion
IF flag <> 'C' THEN
	RETURN 1
END IF
SELECT COUNT(*) INTO vm_num_det FROM tmp_mov
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION setea_botones()

DISPLAY "TP"		TO tit_col1
DISPLAY "Número"	TO tit_col2
DISPLAY "Fecha"		TO tit_col3
DISPLAY "Referencia"	TO tit_col4
DISPLAY "Valor Bien"	TO tit_col5
DISPLAY "Dep/Vta/Baj"	TO tit_col6
DISPLAY "Valor Libros"	TO tit_col7

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE rm_detalle[i].* TO NULL
END FOR
LET rm_par.saldo_ini = NULL
CLEAR saldo_ini, num_row, max_row, total_ing, total_egr, referencia

END FUNCTION



FUNCTION control_muestra_detalle()
DEFINE r_reg		RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				valor_ing	LIKE actt012.a12_valor_mb,
				valor_egr	LIKE actt012.a12_valor_mb,
				saldo_fin	LIKE actt012.a12_valor_mb
			END RECORD
DEFINE i, j, flag	SMALLINT
DEFINE query		CHAR(1500)

CALL retorna_saldo_inicial()
LET query = 'SELECT a12_codigo_tran, a12_numero_tran, a12_fecing, ',
			'a12_referencia, valor_ing, valor_egr, saldo_fin',
		' FROM tmp_mov ',
		' ORDER BY a12_fecing, a12_codigo_tran '
PREPARE mov FROM query
DECLARE q_mov CURSOR FOR mov
LET vm_num_det = 1
FOREACH q_mov INTO r_reg.*
	LET rm_detalle[vm_num_det].a12_codigo_tran = r_reg.a12_codigo_tran
	IF r_reg.a12_numero_tran <> 0 THEN
		LET rm_detalle[vm_num_det].a12_numero_tran =
							r_reg.a12_numero_tran
	ELSE
		LET rm_detalle[vm_num_det].a12_numero_tran = NULL
	END IF
	LET rm_detalle[vm_num_det].a12_fecing      = DATE(r_reg.a12_fecing)
	LET rm_detalle[vm_num_det].a12_referencia  = r_reg.a12_referencia
	LET rm_detalle[vm_num_det].valor_ing       = r_reg.valor_ing
	LET rm_detalle[vm_num_det].valor_egr       = r_reg.valor_egr
	IF vm_num_det = 1 THEN
		LET rm_detalle[vm_num_det].saldo_fin =
			rm_par.saldo_ini + r_reg.valor_ing + r_reg.valor_egr
	ELSE
		LET rm_detalle[vm_num_det].saldo_fin = 
			rm_detalle[vm_num_det - 1].saldo_fin +
			(r_reg.valor_ing + r_reg.valor_egr)
	END IF
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CALL mostrar_total(vm_num_det)
LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY                 
	ON KEY(F5)
		IF rm_par.a10_codigo_bien IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL ver_activo(rm_par.a10_codigo_bien)
		LET int_flag = 0
	ON KEY(F6)
		IF rm_par.a10_codigo_bien IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL ver_orden_compra(rm_par.a10_codigo_bien)
		LET int_flag = 0
	ON KEY(F7)
		IF rm_par.a10_codigo_bien IS NULL THEN
			CALL ver_transaccion("XX", 0, 0)
			LET int_flag = 0
		END IF
	ON KEY(F8)
		LET i = arr_curr()
		LET flag = 1
		IF rm_par.a10_codigo_bien IS NULL THEN
			LET flag = 0
		END IF
		CALL ver_transaccion(rm_detalle[i].a12_codigo_tran,
					rm_detalle[i].a12_numero_tran, flag)
		LET int_flag = 0
	ON KEY(F9)
		LET i = arr_curr()
		IF rm_par.a10_codigo_bien IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL control_contabilizacion(rm_par.a10_codigo_bien,
						rm_detalle[i].*)
		LET int_flag = 0
	ON KEY(F10)
		CALL control_imprimir_mov()
		LET int_flag = 0
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT','')
		IF rm_par.a10_codigo_bien IS NULL THEN
			CALL dialog.keysetlabel('F5','')
			CALL dialog.keysetlabel('F6','')
			CALL dialog.keysetlabel('F7','Transacciones')
			CALL dialog.keysetlabel('F9','')
		ELSE
			CALL dialog.keysetlabel('F5','El Bien')
			CALL dialog.keysetlabel('F6','Orden Compra')
			CALL dialog.keysetlabel('F7','')
			CALL dialog.keysetlabel('F8','Transaccion')
			CALL dialog.keysetlabel('F9','Contabilizacion')
		END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL muestra_contadores(i, vm_num_det)
		DISPLAY rm_detalle[i].a12_referencia TO referencia
		IF rm_par.a10_codigo_bien IS NULL THEN
			CALL dialog.keysetlabel('F8','Transacciones ' ||
						rm_detalle[i].a12_codigo_tran)
		END IF
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION retorna_saldo_inicial()

IF NOT preparar_consulta('S') THEN
	DROP TABLE tmp_sal
	RETURN 0
END IF
SQL
	SELECT NVL(SUM(valor_ing + valor_egr), 0)
		INTO $rm_par.saldo_ini
		FROM tmp_sal
END SQL
DROP TABLE tmp_sal
DISPLAY BY NAME rm_par.saldo_ini

END FUNCTION



FUNCTION mostrar_total(m)
DEFINE m, i		SMALLINT
DEFINE total_ing	DECIMAL(14,2)
DEFINE total_egr	DECIMAL(14,2)

LET total_ing = 0
LET total_egr = 0
FOR i = 1 TO m
	LET total_ing = total_ing + rm_detalle[i].valor_ing
	LET total_egr = total_egr + rm_detalle[i].valor_egr
END FOR
DISPLAY BY NAME total_ing, total_egr

END FUNCTION



FUNCTION control_contabilizacion(activo, r_mov)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_mov		RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				valor_ing	LIKE actt012.a12_valor_mb,
				valor_egr	LIKE actt012.a12_valor_mb,
				saldo_fin	LIKE actt012.a12_valor_mb
			END RECORD
DEFINE r_det		ARRAY[500] OF RECORD
				tipo_comp	LIKE actt015.a15_tipo_comp,
				num_comp	LIKE actt015.a15_num_comp,
				cuenta		LIKE ctbt010.b10_cuenta,
				descripcion	LIKE ctbt010.b10_descripcion,
				valor_db	LIKE ctbt013.b13_valor_base,
				valor_cr	LIKE ctbt013.b13_valor_base
			END RECORD
DEFINE r_adi		ARRAY[500] OF RECORD
				subtipo		LIKE ctbt004.b04_subtipo,
				desc_sub	LIKE ctbt004.b04_nombre,
				glosa		LIKE ctbt013.b13_glosa
			END RECORD
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE tipo		LIKE actt012.a12_tipcomp_gen
DEFINE num		LIKE actt012.a12_numcomp_gen
DEFINE tipo_cta		LIKE ctbt010.b10_tipo_cta
DEFINE total_db		LIKE ctbt013.b13_valor_base
DEFINE total_cr		LIKE ctbt013.b13_valor_base
DEFINE util_per		LIKE ctbt013.b13_valor_base
DEFINE query		CHAR(1500)
DEFINE num_row, i	SMALLINT
DEFINE max_row		SMALLINT

IF r_mov.a12_codigo_tran <> 'VE' THEN
	SELECT a12_tipcomp_gen, a12_numcomp_gen
		INTO tipo, num
		FROM actt012
		WHERE a12_compania    = vg_codcia
		  AND a12_codigo_tran = r_mov.a12_codigo_tran
		  AND a12_numero_tran = r_mov.a12_numero_tran
	CALL ver_contabilizacion(tipo, num)
	RETURN
END IF
LET query = 'SELECT a15_tipo_comp, a15_num_comp, b13_cuenta, b10_descripcion, ',
		' CASE WHEN b13_valor_base > 0 ',
			'THEN b13_valor_base ',
			'ELSE 0.00 ',
		' END, ',
		' CASE WHEN b13_valor_base <= 0 ',
			'THEN b13_valor_base ',
			'ELSE 0.00 ',
		' END * (-1), ',
		' b12_subtipo, b04_nombre, b13_glosa, b10_tipo_cta, ',
		' b13_secuencia, b12_fecing ',
		' FROM actt015, ctbt012, ctbt013, ctbt010, ctbt004 ',
		' WHERE a15_compania    = ', vg_codcia,
		'   AND a15_codigo_tran = "', r_mov.a12_codigo_tran, '"',
		'   AND a15_numero_tran = ', r_mov.a12_numero_tran,
		'   AND b12_compania    = a15_compania ',
		'   AND b12_tipo_comp   = a15_tipo_comp ',
		'   AND b12_num_comp    = a15_num_comp ',
		'   AND b13_compania    = b12_compania ',
		'   AND b13_tipo_comp   = b12_tipo_comp ',
		'   AND b13_num_comp    = b12_num_comp ',
		'   AND b10_compania    = b13_compania ',
		'   AND b10_cuenta      = b13_cuenta ',
		'   AND b04_compania    = b12_compania ',
		'   AND b04_subtipo     = b12_subtipo ',
		' ORDER BY b12_fecing, b12_subtipo, b13_secuencia '
PREPARE cons_dett FROM query
DECLARE q_cursor1 CURSOR FOR cons_dett
LET max_row  = 500
LET num_row  = 1
LET total_db = 0
LET total_cr = 0
LET util_per = 0
FOREACH q_cursor1 INTO r_det[num_row].*, r_adi[num_row].*, tipo_cta
	LET total_db = total_db + r_det[num_row].valor_db
	LET total_cr = total_cr + r_det[num_row].valor_cr
	IF tipo_cta = 'R' THEN
		LET util_per = util_per +
			(r_det[num_row].valor_db - r_det[num_row].valor_cr)
	END IF
	LET num_row  = num_row + 1
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
IF num_row = 0 THEN
	CALL fl_mostrar_mensaje('No se ha generado ningun diario contable. Llame al Administrador.', 'exclamation')
	RETURN
END IF
OPEN WINDOW w_actf202_4 AT 03, 02 WITH 21 ROWS, 78 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_actf202_4 FROM '../forms/actf202_4'
ELSE
	OPEN FORM f_actf202_4 FROM '../forms/actf202_4c'
END IF
DISPLAY FORM f_actf202_4
--#DISPLAY 'Comprobante' TO tit_col1
--#DISPLAY 'Cuenta'      TO tit_col2
--#DISPLAY 'Descripcion' TO tit_col3
--#DISPLAY 'Debito'      TO tit_col4
--#DISPLAY 'Credito'     TO tit_col5
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
DISPLAY BY NAME r_a10.a10_grupo_act, r_a10.a10_codigo_bien,
		r_a10.a10_descripcion, r_a10.a10_valor_mb, r_a10.a10_tot_dep_mb,
		r_a01.a01_nombre, r_mov.a12_codigo_tran, r_mov.a12_numero_tran,
		r_mov.a12_fecing, r_mov.a12_referencia, total_db, total_cr,
		util_per
IF r_mov.valor_ing > 0 THEN
	DISPLAY r_mov.valor_ing TO a12_valor_mb
ELSE
	DISPLAY r_mov.valor_egr TO a12_valor_mb
END IF
LET int_flag = 0
CALL set_count(num_row)
DISPLAY ARRAY r_det TO r_det.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET i = arr_curr()
		IF r_det[i].tipo_comp IS NOT NULL THEN
			CALL ver_contabilizacion(r_det[i].tipo_comp,
							r_det[i].num_comp)	
			LET int_flag = 0
		END IF
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('ACCEPT', '')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#DISPLAY i       TO num_row
		--#DISPLAY num_row TO max_row
		--#DISPLAY BY NAME r_adi[i].*
		--#IF r_det[i].tipo_comp IS NOT NULL THEN
			--#CALL dialog.keysetlabel('F5', 'Contabilizacion')
		--#ELSE
			--#CALL dialog.keysetlabel('F5', '')
		--#END IF
	--#AFTER DISPLAY
		--#CONTINUE DISPLAY
END DISPLAY
LET int_flag = 0
CLOSE WINDOW w_actf202_4
RETURN

END FUNCTION



FUNCTION ver_activo(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE param		VARCHAR(60)

LET param = ' ', activo
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp104', param)

END FUNCTION



FUNCTION ver_orden_compra(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE param		VARCHAR(60)

CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
IF r_a10.a10_numero_oc IS NULL THEN
	CALL fl_mostrar_mensaje('Este Bien no tiene una orden de compra asociada.', 'exclamation')
	RETURN
END IF
LET param = ' ', vg_codloc, ' ', r_a10.a10_numero_oc
CALL ejecuta_comando('COMPRAS', 'OC', 'ordp200', param)

END FUNCTION



FUNCTION ver_transaccion(codtran, numtran, flag)
DEFINE codtran		LIKE actt012.a12_codigo_tran
DEFINE numtran		LIKE actt012.a12_numero_tran
DEFINE flag		SMALLINT
DEFINE param		VARCHAR(120)

IF flag THEN
	LET param = ' "', codtran, '" ', numtran
	CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp200', param)
	RETURN
END IF
IF rm_par.a10_localidad IS NOT NULL THEN
	LET param = ' ', rm_par.a10_localidad
ELSE
	LET param = ' 0 '
END IF
IF rm_par.a10_grupo_act IS NOT NULL THEN
	LET param = param CLIPPED, ' ', rm_par.a10_grupo_act
ELSE
	LET param = param CLIPPED, ' 0 '
END IF
IF rm_par.a10_tipo_act IS NOT NULL THEN
	LET param = param CLIPPED, ' ', rm_par.a10_tipo_act
ELSE
	LET param = param CLIPPED, ' 0 '
END IF
LET param = param CLIPPED, ' "', codtran, '" "', rm_par.fecha_inicial, '" "',
		rm_par.fecha_final, '"'
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp302', param)

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE param		VARCHAR(60)

IF tipo_comp IS NULL THEN
	CALL fl_mostrar_mensaje('No se ha generado contabilización de este movimiento.', 'exclamation')
	RETURN
END IF
LET param = ' "', tipo_comp, '" ', num_comp CLIPPED
CALL ejecuta_comando('CONTABILIDAD', 'CB', 'ctbp201', param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(120)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo, vg_separador,
		'fuentes', vg_separador, run_prog, prog, ' ', vg_base, ' ',
		mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION control_imprimir_mov()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_movimiento_activo TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT reporte_movimiento_activo(i)
END FOR
FINISH REPORT reporte_movimiento_activo

END FUNCTION



REPORT reporte_movimiento_activo(i)
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE fecha		DATE
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
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
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 074, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 027, "MOVIMIENTOS DE ACTIVOS FIJOS",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	IF rm_par.a10_grupo_act IS NOT NULL THEN
		PRINT COLUMN 010, "** GRUPO ACTIVO: ",
			rm_par.a10_grupo_act USING "&&", " ",
			rm_par.a01_nombre CLIPPED
	END IF
	IF rm_par.a10_tipo_act IS NOT NULL THEN
		PRINT COLUMN 010, "** TIPO ACTIVO : ",
			rm_par.a10_tipo_act USING "&&", " ",
			rm_par.a02_nombre CLIPPED
	END IF
	IF rm_par.a10_codigo_bien IS NOT NULL THEN
		PRINT COLUMN 010, "** ACTIVO FIJO : ",
			rm_par.a10_codigo_bien USING "<<<&&&", " ",
			rm_par.a10_descripcion CLIPPED
	END IF
	PRINT COLUMN 010, "** PERIODO     : ",
		rm_par.fecha_inicial USING "dd-mm-yyyy", '  -  ',
		rm_par.fecha_final USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario CLIPPED
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "TP",
	      COLUMN 004, "NUMERO",
	      COLUMN 011, "FECHA TRAN",
	      COLUMN 023, "R E F E R E N C I A",
	      COLUMN 043, "  VALOR BIEN",
	      COLUMN 056, "DEP/VTA/BAJA",
	      COLUMN 069, "VALOR LIBROS"
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"

ON EVERY ROW
	IF i = 1 THEN
		LET fecha = rm_detalle[i].a12_fecing - 1 UNITS DAY
		PRINT COLUMN 033, 'VALOR ANT. LIBROS AL ',
			fecha USING "dd-mm-yyyy", ' ==> ',
		      COLUMN 069, rm_par.saldo_ini	USING "-,---,--&.##"
		SKIP 1 LINES
	END IF
	NEED 4 LINES
	PRINT COLUMN 001, rm_detalle[i].a12_codigo_tran	CLIPPED,
	      COLUMN 004, rm_detalle[i].a12_numero_tran	USING "<<<<&&",
	      COLUMN 011, rm_detalle[i].a12_fecing	USING "dd-mm-yyyy",
	      COLUMN 022, rm_detalle[i].a12_referencia[1, 20] CLIPPED,
	      COLUMN 043, rm_detalle[i].valor_ing	USING "#,###,##&.##",
	      COLUMN 056, rm_detalle[i].valor_egr	USING "#,###,##&.##",
	      COLUMN 069, rm_detalle[i].saldo_fin	USING "#,###,##&.##"

ON LAST ROW
	NEED 3 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 045, "------------",
	      COLUMN 058, "------------"
	PRINT COLUMN 031, "TOTALES ==>",
	      COLUMN 043, SUM(rm_detalle[i].valor_ing) USING "#,###,##&.##",
	      COLUMN 056, SUM(rm_detalle[i].valor_egr) USING "#,###,##&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT

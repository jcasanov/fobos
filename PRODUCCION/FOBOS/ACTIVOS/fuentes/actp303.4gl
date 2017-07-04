--------------------------------------------------------------------------------
-- Titulo            : actp303.4gl - Consulta de Depreciaciones de Activos Fijos
-- Elaboracion       : 20-Nov-2009
-- Autor             : NPC
-- Formato Ejecucion : fglrun actp303 base modulo compania
-- Ultima Correccion :
-- Motivo Correccion :
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par		RECORD 
				anio_ini	LIKE actt000.a00_anopro,
				mes_ini		LIKE actt000.a00_mespro,
				anio_fin	LIKE actt000.a00_anopro,
				mes_fin		LIKE actt000.a00_mespro,
				a10_localidad	LIKE actt010.a10_localidad,
				g02_nombre	LIKE gent002.g02_nombre,
				a10_grupo_act 	LIKE actt010.a10_grupo_act,
				a01_nombre 	LIKE actt001.a01_nombre,
				a10_tipo_act	LIKE actt010.a10_tipo_act,
				a02_nombre 	LIKE actt002.a02_nombre,
				a10_estado	LIKE actt010.a10_estado,
				a06_descripcion	LIKE actt006.a06_descripcion
			END RECORD
DEFINE rm_detalle	ARRAY[20000] OF RECORD
				tit_localidad	LIKE actt010.a10_localidad,
				grupo_act	LIKE actt010.a10_grupo_act,
				tipo_act	LIKE actt010.a10_tipo_act,
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				estado		LIKE actt010.a10_estado,
				a10_valor_mb	LIKE actt010.a10_valor_mb,
				tot_dep_ant	LIKE actt010.a10_tot_dep_mb,
				tot_dep_act	LIKE actt010.a10_tot_dep_mb,
				a10_tot_dep_mb	LIKE actt010.a10_tot_dep_mb
			END RECORD
DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE vm_max_det	INTEGER
DEFINE vm_num_det	INTEGER
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp303.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 11 THEN   -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp303'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_det = 20000
OPEN WINDOW w_actf303_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST - 1)
OPEN FORM f_actf303_1 FROM '../forms/actf303_1'
DISPLAY FORM f_actf303_1
CALL setea_botones()
LET vm_num_det = 0
CALL muestra_contadores(0, 0)
INITIALIZE rm_par.* TO NULL 
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en ACTIVOS FIJOS.', 'stop')
	CLOSE WINDOW w_actf303_1
	EXIT PROGRAM
END IF
LET vm_fecha_ini = MDY(01, 01, YEAR(TODAY))
LET vm_fecha_fin = MDY(rm_a00.a00_mespro, 01, rm_a00.a00_anopro) - 1 UNITS DAY
IF vm_fecha_ini > vm_fecha_fin THEN
	LET vm_fecha_ini = MDY(01, 01, YEAR(vm_fecha_fin))
END IF
IF num_args() <> 3 THEN
	CALL llamada_de_otro_programa()
	CLOSE WINDOW w_actf303_1
	EXIT PROGRAM
END IF
LET rm_par.anio_ini   = YEAR(vm_fecha_ini)
LET rm_par.mes_ini    = MONTH(vm_fecha_ini)
LET rm_par.anio_fin   = YEAR(vm_fecha_fin)
LET rm_par.mes_fin    = MONTH(vm_fecha_fin)
LET rm_par.a10_estado = 'X'
CALL muestra_estado(rm_par.a10_estado)
WHILE TRUE
	CALL borrar_detalle()
	CALL control_lee_cabecera()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF preparar_consulta() THEN
		CALL control_muestra_detalle()
		DROP TABLE tmp_mov
		CONTINUE WHILE
	END IF
	IF int_flag = 0 THEN
		DROP TABLE tmp_mov
	END IF
END WHILE
CLOSE WINDOW w_actf303_1
EXIT PROGRAM

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_g02		RECORD LIKE gent002.*

LET rm_par.anio_ini = arg_val(4)
LET rm_par.mes_ini  = arg_val(5)
LET rm_par.anio_fin = arg_val(6)
LET rm_par.mes_fin  = arg_val(7)
LET rm_par.a10_localidad = arg_val(8)
IF rm_par.a10_localidad = 0 THEN
	LET rm_par.a10_localidad = NULL
END IF
LET rm_par.a10_grupo_act = arg_val(9)
IF rm_par.a10_grupo_act = 0 THEN
	LET rm_par.a10_grupo_act = NULL
END IF
LET rm_par.a10_tipo_act  = arg_val(10)
IF rm_par.a10_tipo_act = 0 THEN
	LET rm_par.a10_tipo_act = NULL
END IF
LET rm_par.a10_estado    = arg_val(11)
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
CALL borrar_detalle()
DISPLAY BY NAME rm_par.*
CALL muestra_estado(rm_par.a10_estado)
IF NOT preparar_consulta() THEN
	DROP TABLE tmp_mov
	RETURN
END IF
CALL control_muestra_detalle()
DROP TABLE tmp_mov

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_a06		RECORD LIKE actt006.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE estado		LIKE actt006.a06_estado
DEFINE a_ini, m_ini	SMALLINT
DEFINE a_fin, m_fin	SMALLINT
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
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
		IF INFIELD(a10_estado) THEN
			CALL fl_ayuda_estado_activos(vg_codcia, 1)
				RETURNING r_a06.a06_estado,r_a06.a06_descripcion
			IF r_a06.a06_estado IS NOT NULL THEN
				LET rm_par.a10_estado = r_a06.a06_estado
				CALL muestra_estado(rm_par.a10_estado)
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD anio_ini
		LET a_ini = rm_par.anio_ini
	BEFORE FIELD mes_ini
		LET m_ini = rm_par.mes_ini
	BEFORE FIELD anio_fin
		LET a_fin = rm_par.anio_fin
	BEFORE FIELD mes_fin
		LET m_fin = rm_par.mes_fin
	BEFORE FIELD a10_estado
		LET estado = rm_par.a10_estado
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
	AFTER FIELD a10_estado
		IF rm_par.a10_estado IS NULL THEN
			LET rm_par.a10_estado = estado
		END IF
		IF rm_par.a10_estado = 'A' OR rm_par.a10_estado = 'B' THEN
			CALL fl_mostrar_mensaje('No puede escojer estado ACTIVO o BLOQUEADO.', 'exclamation')
			LET rm_par.a10_estado = 'X'
		END IF
		CALL muestra_estado(rm_par.a10_estado)
	AFTER INPUT
		LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
		LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin)
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF fec_ini > fec_fin THEN
			CALL fl_mostrar_mensaje('El periodo inicial debe ser menor o igual que el periodo final.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF fec_fin > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('El periodo final no puede ser mayor al periodo actual de ACTIVOS FIJOS.', 'exclamation')
			CONTINUE INPUT
		END IF
		{--
		IF EXTEND(fec_fin, YEAR TO MONTH) > EXTEND(TODAY, YEAR TO MONTH)
		THEN
			CALL fl_mostrar_mensaje('El periodo final no puede ser mayor al periodo actual.', 'exclamation')
			CONTINUE INPUT
                END IF
		--}
END INPUT

END FUNCTION



FUNCTION preparar_consulta()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE query		CHAR(6000)
DEFINE expr_sql		CHAR(800)
DEFINE fec_ini, fec_fin	DATE
DEFINE campov		VARCHAR(15)
DEFINE campot		VARCHAR(15)
DEFINE campov1		VARCHAR(15)
DEFINE campot1		VARCHAR(15)

LET expr_sql = ' 1 = 1 '
IF num_args() = 3 THEN
	LET expr_sql = NULL
	OPTIONS INPUT WRAP
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON a10_codigo_bien, a10_valor_mb,
			a10_tot_dep_mb
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
		ON KEY(F2)
			IF INFIELD(a10_codigo_bien) THEN
				CALL fl_ayuda_codigo_bien(vg_codcia,
						rm_par.a10_grupo_act,
						rm_par.a10_tipo_act, 'X', 1)
					RETURNING r_a10.a10_codigo_bien,
						  r_a10.a10_descripcion
				IF r_a10.a10_codigo_bien IS NOT NULL THEN
					DISPLAY BY NAME r_a10.a10_codigo_bien
				END IF
			END IF
			LET int_flag = 0
		AFTER FIELD a10_codigo_bien
			LET r_a10.a10_codigo_bien = GET_FLDBUF(a10_codigo_bien)
			IF r_a10.a10_codigo_bien IS NOT NULL THEN
				CALL fl_lee_codigo_bien(vg_codcia,
							r_a10.a10_codigo_bien)
					RETURNING r_a10.*
				IF r_a10.a10_codigo_bien IS NULL THEN
					CALL fl_mostrar_mensaje('No existe este Activo Fijo en la compañía.', 'exclamation')
					NEXT FIELD a10_codigo_bien
				END IF
				IF r_a10.a10_estado = 'A' OR
				   r_a10.a10_estado = 'B'
				THEN
					CALL fl_mostrar_mensaje('No puede escojer un codigo de activo fijo con estado ACTIVO o BLOQUEADO.', 'exclamation')
					NEXT FIELD a10_codigo_bien
				END IF
			END IF
	END CONSTRUCT
	IF int_flag THEN
		RETURN 0
	END IF
END IF
LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET campov = 'a10_valor_mb'
LET campot = '0.00'
IF rm_par.anio_fin < 2011 THEN
	LET campov = 'a10_valor'
	LET campot = 'a10_tot_dep_mb'
END IF
LET campov1 = campov
LET campot1 = campot
IF fec_fin > MDY(01, 31, 2013) THEN
	LET campov1 = 'a10_valor_mb'
	LET campot1 = 'a10_tot_dep_mb'
END IF
SELECT UNIQUE a12_compania cia, a12_codigo_bien cod_bien, DATE(a12_fecing) fecha
	FROM actt012
	WHERE a12_compania      = vg_codcia
	  AND a12_codigo_tran  IN ("BA", "VE", "BV", "ES")
	  AND DATE(a12_fecing) <= fec_fin
UNION
SELECT UNIQUE a.a12_compania cia, a.a12_codigo_bien cod_bien,
	DATE(a.a12_fecing) fec_baj
	FROM actt012 a
	WHERE a.a12_compania      = vg_codcia
	  AND a.a12_codigo_tran  IN ("AA", "AD")
	  AND DATE(a.a12_fecing) BETWEEN MDY(01, 03, 2011)
				     AND fec_fin
	  AND NOT EXISTS
		(SELECT 1 FROM actt012 b
			WHERE b.a12_compania    = a.a12_compania
			  AND b.a12_codigo_tran = "RV"
			  AND b.a12_codigo_bien = a.a12_codigo_bien)
	INTO TEMP tmp_baj
CALL genera_temp_a10(1, expr_sql, fec_ini)
LET query = 'SELECT a.* FROM actt012 a ',
		' WHERE a.a12_compania      = ', vg_codcia,
	  	'   AND a.a12_codigo_tran  NOT IN ("EG", "BA", "VE", "BV", ',
							'"AA", "AD", "ES") ',
		'   AND a.a12_codigo_bien  IN ',
				'(SELECT a10_codigo_bien ',
				'FROM tmp_a10 ',
				'WHERE a10_compania = a.a12_compania) ',
		'   AND a.a12_valor_mb     <= 0 ',
		'   AND DATE(a.a12_fecing) <= "', fec_fin, '"',
		'   AND EXISTS (SELECT UNIQUE b.a12_codigo_tran ',
				'FROM actt012 b ',
				'WHERE b.a12_compania    = a.a12_compania ',
				'  AND b.a12_codigo_tran = "DP" ',
				'  AND b.a12_codigo_bien = a.a12_codigo_bien) ',
		' UNION ',
		' SELECT a.* FROM actt012 a ',
			' WHERE a.a12_compania      = ', vg_codcia,
			'   AND a.a12_codigo_tran   = "AD" ',
			'   AND a.a12_codigo_bien  IN ',
				'(SELECT a10_codigo_bien ',
				'FROM tmp_a10 ',
				'WHERE a10_compania  = a.a12_compania ',
				'  AND a10_grupo_act = 2) ',
			'   AND a.a12_valor_mb      > 0 ',
			'   AND DATE(a.a12_fecing) <= "', fec_fin, '"',
		' UNION ',
		' SELECT a.* FROM actt012 a ',
			' WHERE a.a12_compania      = ', vg_codcia,
			'   AND a.a12_codigo_tran  NOT IN ("EG", "AA", "ES") ',
			'   AND a.a12_codigo_bien  IN ',
				'(SELECT a10_codigo_bien ',
				'FROM tmp_a10 ',
				'WHERE a10_compania  = a.a12_compania ',
				'  AND a10_grupo_act = 1) ',
			'   AND a.a12_valor_mb     <= 0 ',
			'   AND DATE(a.a12_fecing) <= "', fec_fin, '"',
		' INTO TEMP tmp_a12 '
PREPARE exec_a12 FROM query
EXECUTE exec_a12
LET query = 'SELECT a10_compania, a10_localidad, a10_grupo_act, a10_tipo_act,',
			' a10_codigo_bien, a10_estado, ', campov CLIPPED,
			' a10_valor_mb, ',
			'NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_ant, ',
			campot CLIPPED, ' a10_tot_dep_mb ',
		' FROM tmp_a10, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) < "', fec_ini, '"',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 9 ',
		' UNION',
		' SELECT a10_compania, a10_localidad, a10_grupo_act, ',
			'a10_tipo_act, a10_codigo_bien, a10_estado, ',
			campov CLIPPED, ' a10_valor_mb, 0.00 tot_dep_ant, ',
			campot CLIPPED, ' a10_tot_dep_mb ',
		' FROM tmp_a10, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND EXTEND(a12_fecing, YEAR TO MONTH) <= ',
			'EXTEND(DATE("', fec_fin, '"), YEAR TO MONTH) ',
		' INTO TEMP tt '
PREPARE exec_tt FROM query
EXECUTE exec_tt
SELECT a10_compania, a10_localidad, a10_grupo_act, a10_tipo_act,
	a10_codigo_bien, a10_estado, a10_valor_mb,
	NVL(SUM(tot_dep_ant), 0) tot_dep_ant, a10_tot_dep_mb
	FROM tt
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 9
	INTO TEMP t1
DROP TABLE tt
LET query = 'SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
		'a10_codigo_bien, a10_estado, a10_valor_mb, tot_dep_ant, ',
		'NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_act, a10_tot_dep_mb ',
		' FROM t1, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) BETWEEN "', fec_ini,
					  '" AND "', fec_fin, '"',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 9 ',
		' UNION ',
		' SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_codigo_bien, a10_estado, a10_valor_mb, ',
			'tot_dep_ant, 0.00 tot_dep_act, a10_tot_dep_mb ',
		' FROM t1, tmp_a12 ',
		' WHERE a10_estado      IN ("N", "E", "V", "D")',
		'   AND a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) < "', fec_ini, '"',
		' INTO TEMP t2 '
PREPARE expresion FROM query
EXECUTE expresion
DROP TABLE tmp_a12
DROP TABLE t1
LET query = 'SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_codigo_bien, a10_estado, a10_valor_mb, ',
			'NVL(tot_dep_ant, 0) tot_dep_ant, ',
			'NVL(SUM(tot_dep_act), 0) tot_dep_act, a10_tot_dep_mb ',
		'FROM t2 ',
		'GROUP BY 1, 2, 3, 4, 5, 6, 7, 9 ',
		'UNION ',
		'SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_codigo_bien, a10_estado, ',
			campov CLIPPED, ' a10_valor_mb, 0.00 tot_dep_ant, ',
			'0.00 tot_dep_act, ', campot CLIPPED,' a10_tot_dep_mb ',
		'FROM tmp_a10 ',
		'WHERE a10_grupo_act = 1 ',
		'  AND NOT EXISTS ',
		'	(SELECT 1 FROM t2 ',
		'		WHERE t2.a10_codigo_bien = ',
		'			tmp_a10.a10_codigo_bien) ',
		'INTO TEMP t3 '
PREPARE exec_t3 FROM query
EXECUTE exec_t3
DROP TABLE tmp_a10
DROP TABLE t2
SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien, a10_estado,
	a10_valor_mb, NVL(SUM(tot_dep_ant), 0) tot_dep_ant,
	NVL(SUM(tot_dep_act), 0) tot_dep_act
	FROM t3
	GROUP BY 1, 2, 3, 4, 5, 6
	INTO TEMP t2
DROP TABLE t3
LET query = 'SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_codigo_bien, a10_estado, ',
			'CASE WHEN NVL((SELECT COUNT(*) FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND cod_bien <> 418 ',
					'  AND fecha    <= "', fec_fin, '"), ',
					'0) = 0 ',
				'THEN a10_valor_mb ',
				'ELSE 0.00 ',
			'END a10_valor_mb, ',
			'CASE WHEN NVL((SELECT COUNT(*) FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND cod_bien <> 418 ',
					'  AND fecha    <= "', fec_fin, '"), ',
					'0) = 0 ',
				'THEN tot_dep_ant ',
				'ELSE CASE WHEN a10_estado = "V" ',
					'THEN (tot_dep_act) * (-1) ',
					'ELSE 0.00 ',
					'END ',
			'END tot_dep_ant, ',
			'tot_dep_act, ',
			'CASE WHEN NVL((SELECT 1 FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND cod_bien <> 418 ',
					'  AND fecha    <= "', fec_fin, '"), ',
					'0) = 0 ',
				'THEN (tot_dep_ant + tot_dep_act) ',
				'ELSE 0.00 ',
			'END a10_tot_dep_mb ',
		' FROM t2 ',
		' INTO TEMP tmp_mov '
PREPARE exec_mov FROM query
EXECUTE exec_mov
DROP TABLE t2
DROP TABLE tmp_baj
SELECT COUNT(*) INTO vm_num_det FROM tmp_mov
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION genera_temp_a10(flag, expr_sql, fec_ini)
DEFINE flag		SMALLINT
DEFINE expr_sql		CHAR(800)
DEFINE fec_ini		DATE
DEFINE exp_loc		VARCHAR(100)
DEFINE exp_gru		VARCHAR(100)
DEFINE exp_tip		VARCHAR(100)
DEFINE query		CHAR(6000)

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
IF flag THEN
	LET query = 'SELECT * FROM actt010 '
ELSE
	LET query = 'SELECT NVL(MIN(a10_fecha_comp),MDY(01, 01, 1990)) fec_min',
			' FROM actt010 '
END IF
LET query = query CLIPPED,
		' WHERE a10_compania     = ', vg_codcia,
		exp_loc CLIPPED,
		exp_gru CLIPPED,
		exp_tip CLIPPED,
		fl_retorna_expr_estado_act(vg_codcia, rm_par.a10_estado,
						1) CLIPPED,
		'   AND ', expr_sql CLIPPED
IF flag THEN
	LET query = query CLIPPED,
		'   AND a10_codigo_bien NOT IN ',
				'(SELECT cod_bien ',
					'FROM tmp_baj ',
					'WHERE fecha < "', fec_ini, '") ',
		' INTO TEMP tmp_a10 '
ELSE
	LET query = query CLIPPED, ' INTO TEMP t1 '
END IF
PREPARE exec_a10 FROM query
EXECUTE exec_a10

END FUNCTION



FUNCTION setea_botones()

DISPLAY 'LC' 		TO tit_col1
DISPLAY 'GR' 		TO tit_col2
DISPLAY 'Tip' 		TO tit_col3
DISPLAY 'Bien' 		TO tit_col4
DISPLAY 'E' 		TO tit_col5
DISPLAY 'Valor Bien' 	TO tit_col6
DISPLAY 'Depr. Ant.'	TO tit_col7
--DISPLAY 'Depr. Act.'	TO tit_col8
DISPLAY 'Dep/Vta/Baj'	TO tit_col8
DISPLAY 'Depr. Acum.'	TO tit_col9

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
CLEAR num_row, max_row, valor_mb_g, tot_dep_ant_g, tot_dep_act_g, tot_dep_mb_g,
	descripcion, valor_libros, valor_actual

END FUNCTION



FUNCTION control_muestra_detalle()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE valor_libros	LIKE actt010.a10_valor_mb
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(1500)

FOR i = 1 TO 10
	LET rm_orden[i] = ''
END FOR
LET col           = 2
LET vm_columna_1  = col
LET vm_columna_2  = 3
LET rm_orden[col] = 'ASC'
WHILE TRUE
	LET query = 'SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
				'a10_codigo_bien, a10_estado, a10_valor_mb, ',
				'tot_dep_ant, tot_dep_act, a10_tot_dep_mb ',
			' FROM tmp_mov ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE mov FROM query
	DECLARE q_mov CURSOR FOR mov
	LET vm_num_det = 1
	FOREACH q_mov INTO rm_detalle[vm_num_det].*
		LET vm_num_det = vm_num_det + 1
		IF vm_num_det > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_det = vm_num_det - 1
	IF vm_num_det = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	CALL mostrar_total()
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY                 
		ON KEY(F5)
			CALL ver_activo(rm_detalle[i].a10_codigo_bien)
			LET int_flag = 0
		ON KEY(F6)
			CALL ver_orden_compra(rm_detalle[i].a10_codigo_bien)
			LET int_flag = 0
		ON KEY(F7)
			CALL ver_consulta_activos()
			LET int_flag = 0
		ON KEY(F8)
			CALL ver_movimientos(0)
			LET int_flag = 0
		ON KEY(F9)
			CALL ver_movimientos(i)
			LET int_flag = 0
		ON KEY(F10)
			CALL ver_transacciones("XX", 0)
			LET int_flag = 0
		ON KEY(F11)
			CALL ver_transacciones("DP", 0)
			LET int_flag = 0
		ON KEY(CONTROL-W)
			CALL ver_transacciones("DP", i)
			LET int_flag = 0
		ON KEY(CONTROL-X)
			CALL control_imprimir_dep()
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
			LET col = 8
			EXIT DISPLAY
		ON KEY(F23)
			LET col = 9
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
			CALL dialog.keysetlabel('CONTROL-W','Transacc. Bien')
			CALL dialog.keysetlabel('CONTROL-X','Imprimir')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			LET valor_libros = rm_detalle[i].a10_valor_mb -
						rm_detalle[i].a10_tot_dep_mb
			CALL fl_lee_codigo_bien(vg_codcia,
						rm_detalle[i].a10_codigo_bien)
				RETURNING r_a10.*
			CALL muestra_contadores(i, vm_num_det)
			DISPLAY r_a10.a10_descripcion TO descripcion
			DISPLAY BY NAME valor_libros
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



FUNCTION mostrar_total()
DEFINE i		SMALLINT
DEFINE valor_mb_g	DECIMAL(14,2)
DEFINE tot_dep_ant_g	DECIMAL(14,2)
DEFINE tot_dep_act_g	DECIMAL(14,2)
DEFINE tot_dep_mb_g	DECIMAL(14,2)
DEFINE valor_actual	LIKE actt010.a10_valor_mb

LET valor_mb_g    = 0
LET tot_dep_ant_g = 0
LET tot_dep_act_g = 0
LET tot_dep_mb_g  = 0
FOR i = 1 TO vm_num_det
	LET valor_mb_g    = valor_mb_g    + rm_detalle[i].a10_valor_mb
	LET tot_dep_ant_g = tot_dep_ant_g + rm_detalle[i].tot_dep_ant
	LET tot_dep_act_g = tot_dep_act_g + rm_detalle[i].tot_dep_act
	LET tot_dep_mb_g  = tot_dep_mb_g  + rm_detalle[i].a10_tot_dep_mb
END FOR
LET valor_actual = valor_mb_g - tot_dep_mb_g
DISPLAY BY NAME valor_mb_g, tot_dep_ant_g, tot_dep_act_g, tot_dep_mb_g,
		valor_actual

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



FUNCTION ver_consulta_activos()
DEFINE param		VARCHAR(120)
DEFINE fec_ini, fec_fin	DATE

LET param = ' "', rm_par.a10_estado, '"'
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
IF rm_par.a10_localidad IS NOT NULL THEN
	LET param = param CLIPPED, ' ', rm_par.a10_localidad
ELSE
	LET param = param CLIPPED, ' 0 '
END IF
LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET param = param CLIPPED, ' "', fec_fin, '" "', fec_ini, '"'
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp300', param)

END FUNCTION



FUNCTION ver_movimientos(i)
DEFINE i		SMALLINT
DEFINE param		VARCHAR(120)
DEFINE fec_ini, fec_fin	DATE

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
LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
IF i > 0 THEN
	IF rm_detalle[i].estado = 'D' THEN
		CALL genera_temp_a10(0, ' 1 = 1 ', fec_ini)
		SELECT * INTO fec_ini FROM t1
		DROP TABLE t1
	END IF
END IF
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET param = param CLIPPED, ' "', fec_ini, '" "', fec_fin, '"'
IF i > 0 THEN
	LET param = param CLIPPED, ' ', rm_detalle[i].a10_codigo_bien
END IF
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp301', param)

END FUNCTION



FUNCTION ver_transacciones(cod_tran, i)
DEFINE cod_tran		LIKE actt012.a12_codigo_tran
DEFINE i		SMALLINT
DEFINE param		VARCHAR(120)
DEFINE fec_ini, fec_fin	DATE

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
LET param   = param CLIPPED, ' "', cod_tran, '" '
LET fec_ini = MDY(rm_par.mes_ini, 01, rm_par.anio_ini)
IF i > 0 THEN
	IF rm_detalle[i].estado = 'D' THEN
		CALL genera_temp_a10(0, ' 1 = 1 ', fec_ini)
		SELECT * INTO fec_ini FROM t1
		DROP TABLE t1
	END IF
END IF
LET fec_fin = MDY(rm_par.mes_fin, 01, rm_par.anio_fin) + 1 UNITS MONTH
		- 1 UNITS DAY
LET param = param CLIPPED, ' "', fec_ini, '" "', fec_fin, '"'
IF i > 0 THEN
	LET param = param CLIPPED, ' ', rm_detalle[i].a10_codigo_bien
END IF
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp302', param)

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



FUNCTION control_imprimir_dep()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_depreciacion_activo TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT reporte_depreciacion_activo(i)
END FOR
FINISH REPORT reporte_depreciacion_activo

END FUNCTION



REPORT reporte_depreciacion_activo(i)
DEFINE i		SMALLINT
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
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
	RIGHT MARGIN	132
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
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 126, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 051, "DEPRECIACIONES DE ACTIVOS FIJOS",
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 041, "** PERIODO     : ",
	      COLUMN 057, rm_par.anio_ini USING "&&&&", ' - ',
				rm_par.mes_ini USING "&&",
	      COLUMN 069, rm_par.anio_fin USING "&&&&", ' - ',
				rm_par.mes_fin USING "&&"
	IF rm_par.a10_localidad IS NOT NULL THEN
		PRINT COLUMN 041, "** LOCALIDAD   : ",
			rm_par.a10_localidad USING "&&", " ",
			rm_par.g02_nombre CLIPPED
	END IF
	IF rm_par.a10_grupo_act IS NOT NULL THEN
		PRINT COLUMN 041, "** GRUPO ACTIVO: ",
			rm_par.a10_grupo_act USING "&&", " ",
			rm_par.a01_nombre CLIPPED
	END IF
	IF rm_par.a10_tipo_act IS NOT NULL THEN
		PRINT COLUMN 041, "** TIPO ACTIVO : ",
			rm_par.a10_tipo_act USING "&&", " ",
			rm_par.a02_nombre CLIPPED
	END IF
	PRINT COLUMN 041, "** ESTADO      : ", rm_par.a10_estado, " ",
		rm_par.a06_descripcion CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 114, usuario CLIPPED
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "LC",
	      COLUMN 004, "GR",
	      COLUMN 008, "TIP",
	      COLUMN 013, "CODIGO",
	      COLUMN 027, "D E S C R I P C I O N",
	      COLUMN 057, "E",
	      COLUMN 060, "VALOR ACTIVOS",
	      COLUMN 075, " DEP. ACU. ANT",
	      --COLUMN 090, "DEP. ACU. ACT",
	      COLUMN 090, " DEP/VTA/BAJA",
	      COLUMN 105, "DEPREC. ACUM.",
	      COLUMN 120, " VALOR LIBROS"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	CALL fl_lee_codigo_bien(vg_codcia, rm_detalle[i].a10_codigo_bien)
		RETURNING r_a10.*
	PRINT COLUMN 001, rm_detalle[i].tit_localidad	USING "&&",
	      COLUMN 004, rm_detalle[i].grupo_act	USING "&&",
	      COLUMN 008, rm_detalle[i].tipo_act	USING "#&&",
	      COLUMN 013, rm_detalle[i].a10_codigo_bien	USING "<<<&&&",
	      COLUMN 020, r_a10.a10_descripcion[1, 35]	CLIPPED,
	      COLUMN 057, rm_detalle[i].estado,
	      COLUMN 060, rm_detalle[i].a10_valor_mb	USING "--,---,--&.##",
	      COLUMN 075, rm_detalle[i].tot_dep_ant	USING '((,(((,((&.##)',
	      COLUMN 090, rm_detalle[i].tot_dep_act	USING "--,---,--&.##",
	      COLUMN 105, rm_detalle[i].a10_tot_dep_mb	USING "--,---,--&.##",
	      COLUMN 120, (rm_detalle[i].a10_valor_mb -
			rm_detalle[i].a10_tot_dep_mb)	USING "--,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 062, "-------------",
	      COLUMN 077, "--------------",
	      COLUMN 092, "-------------",
	      COLUMN 107, "-------------",
	      COLUMN 122, "-------------"
	PRINT COLUMN 048, "TOTALES ==>",
	      COLUMN 060, SUM(rm_detalle[i].a10_valor_mb) USING "--,---,--&.##",
	      COLUMN 075, SUM(rm_detalle[i].tot_dep_ant) USING '((,(((,((&.##)',
	      COLUMN 090, SUM(rm_detalle[i].tot_dep_act)  USING "--,---,--&.##",
	      COLUMN 105, SUM(rm_detalle[i].a10_tot_dep_mb)
						USING "--,---,--&.##",
	      COLUMN 120, SUM(rm_detalle[i].a10_valor_mb -
			rm_detalle[i].a10_tot_dep_mb)	USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION muestra_estado(estado)
DEFINE estado		LIKE actt010.a10_estado
DEFINE r_a06		RECORD LIKE actt006.*

CALL fl_lee_estado_activos(vg_codcia, estado) RETURNING r_a06.*
IF r_a06.a06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Estado no existe.', 'exclamation')
	LET rm_par.a10_estado = NULL
END IF
LET rm_par.a06_descripcion = r_a06.a06_descripcion
IF r_a06.a06_estado = 'S' THEN
	LET rm_par.a06_descripcion = 'DEPRECIANDOSE'
END IF
DISPLAY BY NAME rm_par.a10_estado, rm_par.a06_descripcion

END FUNCTION

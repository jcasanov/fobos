--------------------------------------------------------------------------------
-- Titulo               : actp300.4gl - Consulta de Activos Fijos
-- Elaboración          : 10-Ene-2003
-- Autor                : RRM
-- Formato de Ejecución : fglrun actp1300.4gl base AF compañía
--				[estado grupo tipo localidad fec_fin [fec_ini]
--				[activo]]
-- Ultima Correción     : 10-jun-2003
-- Motivo Corrección    : (RCA) Revisión y Correccion Aceros 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_activos	RECORD 
				a10_localidad 	LIKE actt010.a10_localidad,
				a10_grupo_act 	LIKE actt010.a10_grupo_act,
				a10_tipo_act	LIKE actt010.a10_tipo_act,
				a10_estado	LIKE actt010.a10_estado,
				fecha_inicial	LIKE actt010.a10_fecha_comp,
				fecha_final	LIKE actt010.a10_fecha_comp
			END RECORD
DEFINE rm_detalle	ARRAY[10000] OF RECORD
				tit_localidad	LIKE actt010.a10_localidad,
				grupo_act	LIKE actt010.a10_grupo_act,
				tipo_act	LIKE actt010.a10_tipo_act,
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a10_fecha_comp	LIKE actt010.a10_fecha_comp,
				a10_valor	LIKE actt010.a10_valor,
				valor_dep	LIKE actt010.a10_tot_dep_mb,
				estado		LIKE actt010.a10_estado
			END RECORD
DEFINE rm_movact	ARRAY[1000] OF RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_tipcomp_gen	LIKE actt012.a12_tipcomp_gen,
				a12_numcomp_gen	LIKE actt012.a12_numcomp_gen,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				a12_porc_deprec	LIKE actt012.a12_porc_deprec,
				a12_valor_mb	LIKE actt012.a12_valor_mb
			END RECORD
DEFINE vm_indice	INTEGER       
DEFINE vm_num_movact	INTEGER
DEFINE vm_max_movact	INTEGER
DEFINE vm_max_detalle	INTEGER
DEFINE vm_num_detalle	INTEGER
DEFINE vm_activo	INTEGER
DEFINE vm_fec_ini_dep	DATE
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp300.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 8 AND num_args() <> 9 AND num_args() <> 10
THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp300'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
EXIT PROGRAM

END MAIN



FUNCTION funcion_master()
DEFINE tit_est		VARCHAR(30)

CALL fl_nivel_isolation()
LET vm_max_detalle = 10000
LET vm_max_movact  = 1000
CREATE TEMP TABLE tmp_consulta
	(
		tit_localidad		SMALLINT,
		grupo_act		SMALLINT,
		tipo_act		SMALLINT,
		codigo_bien		INTEGER,
		decripcion		VARCHAR(40),
		fecha_compra		DATE,
		valor_compra		DECIMAL(12,2),
		valor_dep		DECIMAL(12,2),
		estado			CHAR(1),
		valor_actual		DECIMAL(12,2)
	)
OPEN WINDOW w_actf300_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST - 1)
OPEN FORM f_actf300_1 FROM '../forms/actf300_1'
DISPLAY FORM f_actf300_1
CALL setea_botones()
LET vm_indice      = 0
LET vm_num_detalle = 0
CALL muestra_contadores()
INITIALIZE rm_activos.*, vm_activo, vm_fec_ini_dep TO NULL
SELECT NVL(MIN(a10_fecha_comp), MDY(01, 01, 1990))
	INTO rm_activos.fecha_inicial
	FROM actt010
	WHERE a10_compania  = vg_codcia
	  AND a10_estado   IN ("S", "D", "V", "E", "R", "N")
IF num_args() <> 3 THEN
	CALL llamada_de_otro_programa()
	CLOSE WINDOW w_actf300_1
	EXIT PROGRAM
END IF
LET rm_activos.fecha_final   = TODAY
LET rm_activos.a10_estado    = 'T'
CALL muestra_estado(rm_activos.a10_estado, 1) RETURNING tit_est
WHILE TRUE
	CALL borrar_detalle()
	DELETE FROM tmp_consulta
	CALL control_lee_cabecera()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF preparar_consulta() THEN
		CALL control_muestra_detalle()
	END IF
END WHILE
DROP TABLE tmp_consulta
CLOSE WINDOW w_actf300_1

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE tit_est		LIKE actt006.a06_descripcion

LET rm_activos.a10_estado    = arg_val(4)
LET rm_activos.a10_grupo_act = arg_val(5)
IF rm_activos.a10_grupo_act = 0 THEN
	LET rm_activos.a10_grupo_act = NULL
END IF
LET rm_activos.a10_tipo_act  = arg_val(6)
IF rm_activos.a10_tipo_act = 0 THEN
	LET rm_activos.a10_tipo_act = NULL
END IF
LET rm_activos.a10_localidad = arg_val(7)
IF rm_activos.a10_localidad = 0 THEN
	LET rm_activos.a10_localidad = NULL
END IF
LET rm_activos.fecha_final   = arg_val(8)
IF num_args() > 8 THEN
	LET vm_fec_ini_dep = arg_val(9)
	IF rm_activos.a10_estado <> 'X' THEN
		LET vm_fec_ini_dep = NULL
	END IF
	LET vm_activo = arg_val(10)
END IF
DISPLAY BY NAME rm_activos.*
IF rm_activos.a10_grupo_act IS NOT NULL THEN
	CALL fl_lee_grupo_activo(vg_codcia, rm_activos.a10_grupo_act)
		RETURNING r_a01.*
	IF r_a01.a01_grupo_act IS NULL THEN
		CALL fl_mostrar_mensaje('No existe grupo de activo', 'exclamation')
		RETURN
	END IF
	DISPLAY r_a01.a01_nombre TO desc_grupo
END IF
IF rm_activos.a10_tipo_act IS NOT NULL THEN
	CALL fl_lee_tipo_activo(vg_codcia, rm_activos.a10_tipo_act)
		RETURNING r_a02.*
	IF r_a02.a02_tipo_act IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de activo', 'exclamation')
		RETURN
	END IF
	DISPLAY r_a02.a02_nombre TO desc_tipo
END IF
IF rm_activos.a10_localidad IS NOT NULL THEN
	CALL fl_lee_localidad(vg_codcia, rm_activos.a10_localidad)
		RETURNING r_g02.*
	IF r_g02.g02_localidad IS NULL THEN
		CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
		RETURN
	END IF	
	DISPLAY BY NAME r_g02.g02_nombre 
END IF
CALL muestra_estado(rm_activos.a10_estado, 1) RETURNING tit_est
IF rm_activos.fecha_inicial > rm_activos.fecha_final THEN
	CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.', 'exclamation')
	RETURN
END IF
CALL borrar_detalle()
IF NOT preparar_consulta() THEN
	RETURN
END IF
CALL control_muestra_detalle()
DROP TABLE tmp_consulta

END FUNCTION



FUNCTION setea_botones()

DISPLAY 'LC' 		TO tit_col1
DISPLAY 'GR' 		TO tit_col2
DISPLAY 'Tip' 		TO tit_col3
DISPLAY 'Bien' 		TO tit_col4
DISPLAY 'Descripcion' 	TO tit_col5
DISPLAY 'F. Compra' 	TO tit_col6
DISPLAY 'Valor Compra' 	TO tit_col7
DISPLAY 'Depr. Acum.'	TO tit_col8
DISPLAY 'E' 		TO tit_col9

END FUNCTION



FUNCTION control_lee_cabecera()
DEFINE grupo		LIKE actt001.a01_grupo_act
DEFINE descripcion	LIKE actt001.a01_nombre
DEFINE tipo		LIKE actt002.a02_tipo_act
DEFINE descripcion1	LIKE actt002.a02_nombre
DEFINE estado		LIKE actt010.a10_estado
DEFINE r_grupo		RECORD LIKE actt001.*
DEFINE r_tipo		RECORD LIKE actt002.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE tit_est		LIKE actt006.a06_descripcion

LET int_flag = 0
INPUT BY NAME rm_activos.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(a10_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
			     RETURNING grupo, descripcion
			IF grupo IS NOT NULL THEN
				LET rm_activos.a10_grupo_act = grupo
				DISPLAY grupo       TO a10_grupo_act
				DISPLAY descripcion TO desc_grupo 
			END IF
		END IF
		IF INFIELD(a10_tipo_act) THEN
			CALL fl_ayuda_tipo_activo(vg_codcia,
						rm_activos.a10_grupo_act)
				RETURNING tipo, descripcion1
			IF tipo IS NOT NULL THEN
				LET rm_activos.a10_tipo_act = tipo
				DISPLAY tipo         TO a10_tipo_act  
				DISPLAY descripcion1 TO desc_tipo 
			END IF 
		END IF
		IF INFIELD(a10_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_activos.a10_localidad =
							r_g02.g02_localidad
				DISPLAY BY NAME rm_activos.a10_localidad,
						r_g02.g02_nombre
			END IF 
		END IF
		IF INFIELD(a10_estado) THEN
			CALL fl_ayuda_estado_activos(vg_codcia, 0)
				RETURNING rm_activos.a10_estado, tit_est
			IF rm_activos.a10_estado IS NOT NULL THEN
				DISPLAY BY NAME rm_activos.a10_estado
				CALL muestra_estado(rm_activos.a10_estado, 1)	
					RETURNING tit_est
			END IF
		END IF
		LET int_flag = 0 
	BEFORE FIELD a10_estado
		LET estado = rm_activos.a10_estado
	AFTER FIELD a10_grupo_act
		IF rm_activos.a10_grupo_act IS NOT NULL THEN
			CALL fl_lee_grupo_activo(vg_codcia,
						rm_activos.a10_grupo_act)
				RETURNING r_grupo.*
			IF r_grupo.a01_grupo_act IS NULL THEN
				CALL fl_mostrar_mensaje('No existe grupo de activo', 'exclamation')
				NEXT FIELD a10_grupo_act
			END IF
			DISPLAY r_grupo.a01_nombre TO desc_grupo
		ELSE
			CLEAR desc_grupo
		END IF
	AFTER FIELD a10_tipo_act
		IF rm_activos.a10_tipo_act IS NOT NULL THEN
			CALL fl_lee_tipo_activo(vg_codcia,
						rm_activos.a10_tipo_act)
				RETURNING r_tipo.*
			IF r_tipo.a02_tipo_act IS NULL THEN
				CALL fl_mostrar_mensaje('No existe tipo de activo', 'exclamation')
				NEXT FIELD a10_tipo_act
			END IF
			DISPLAY r_tipo.a02_nombre TO desc_tipo
		ELSE
			CLEAR desc_tipo
		END IF
	AFTER FIELD a10_localidad
		IF rm_activos.a10_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia,
						rm_activos.a10_localidad)
				RETURNING r_g02.*
			IF r_g02.g02_localidad IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
				NEXT FIELD a10_localidad
			END IF	
			DISPLAY BY NAME r_g02.g02_nombre 
		ELSE
			CLEAR g02_nombre
		END IF
	AFTER FIELD a10_estado
		IF rm_activos.a10_estado IS NULL THEN
			LET rm_activos.a10_estado = estado
		END IF
		CALL muestra_estado(rm_activos.a10_estado, 1) RETURNING tit_est
	AFTER INPUT
		IF (rm_activos.fecha_inicial IS NULL     AND
		    rm_activos.fecha_final IS NOT NULL)  OR
		   (rm_activos.fecha_inicial IS NOT NULL AND
		    rm_activos.fecha_final IS NULL)
		THEN
			CONTINUE INPUT
		END IF
		IF rm_activos.fecha_inicial > rm_activos.fecha_final THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION preparar_consulta()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE query		CHAR(3000)
DEFINE expr_sql		CHAR(800)
DEFINE grupo		VARCHAR(100)
DEFINE tipo		VARCHAR(100)
DEFINE fecha		VARCHAR(100)
DEFINE bien		VARCHAR(100)
DEFINE expr_loc		VARCHAR(100)

LET expr_sql = ' 1 = 1 '
IF num_args() = 3 THEN
	OPTIONS INPUT WRAP
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON a10_codigo_bien, a10_descripcion,
					a10_fecha_comp, a10_valor
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
		ON KEY(F2)
			IF INFIELD(a10_codigo_bien) THEN
				CALL fl_ayuda_codigo_bien(vg_codcia,
						rm_activos.a10_grupo_act,
						rm_activos.a10_tipo_act,
						rm_activos.a10_estado, 0)
				RETURNING r_a10.a10_codigo_bien,
					  r_a10.a10_descripcion
			IF r_a10.a10_codigo_bien IS NOT NULL THEN
				DISPLAY BY NAME r_a10.a10_codigo_bien
			END IF
		END IF
		LET int_flag = 0
	END CONSTRUCT
	IF int_flag = 1 THEN
		RETURN 0
	END IF
	LET vm_fec_ini_dep = rm_activos.fecha_inicial
END IF
LET grupo = NULL
IF rm_activos.a10_grupo_act IS NOT NULL THEN
	LET grupo = '   AND a10_grupo_act   = ', rm_activos.a10_grupo_act  
END IF
LET tipo = NULL
IF rm_activos.a10_tipo_act IS NOT NULL THEN
	LET tipo = '   AND a10_tipo_act    = ', rm_activos.a10_tipo_act 
END IF
LET bien = NULL
IF vm_activo IS NOT NULL THEN
	LET bien = '   AND a10_codigo_bien = ', vm_activo
END IF
LET fecha = NULL
IF rm_activos.fecha_inicial IS NOT NULL AND rm_activos.fecha_final IS NOT NULL
THEN
	LET fecha = '   AND a10_fecha_comp  BETWEEN "',rm_activos.fecha_inicial,
					     '" AND "',rm_activos.fecha_final,
						   '"'
END IF
LET expr_loc = NULL
IF rm_activos.a10_localidad IS NOT NULL THEN
	LET expr_loc = '   AND a10_localidad   = ', rm_activos.a10_localidad
END IF
IF rm_activos.a10_estado <> 'X' THEN
	LET query = 'INSERT INTO tmp_consulta ',
		' SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_codigo_bien, a10_descripcion, a10_fecha_comp, ',
			'a10_valor, a10_tot_dep_mb, a10_estado, ',
			'((a10_valor - a10_tot_dep_mb) + a10_tot_reexpr ',
			'- a10_tot_dep_ree) valor_act ',
		' FROM actt010 ',
		' WHERE a10_compania    = ', vg_codcia,
			expr_loc CLIPPED,
			fl_retorna_expr_estado_act(vg_codcia,
					rm_activos.a10_estado, 0) CLIPPED,
			grupo CLIPPED,
			tipo CLIPPED,
			bien CLIPPED,
			fecha CLIPPED,
		'   AND ', expr_sql CLIPPED
	PREPARE expresion FROM query
	EXECUTE expresion
ELSE
	SELECT UNIQUE a12_compania cia, a12_codigo_bien cod_bien,
		DATE(a12_fecing) fec_baj
		FROM actt012
		WHERE a12_compania      = vg_codcia
		  AND a12_codigo_tran  IN ("BA", "VE", "BV")
		  AND DATE(a12_fecing) <= rm_activos.fecha_final
		INTO TEMP tmp_baj
	LET query = 'SELECT * FROM actt010 ',
		' WHERE a10_compania     = ', vg_codcia,
		expr_loc CLIPPED,
		grupo CLIPPED,
		tipo CLIPPED,
		bien CLIPPED,
		fl_retorna_expr_estado_act(vg_codcia, rm_activos.a10_estado,
						0) CLIPPED,
		'   AND ', expr_sql CLIPPED,
		'   AND a10_codigo_bien NOT IN ',
				'(SELECT cod_bien ',
					'FROM tmp_baj ',
					'WHERE fec_baj < "',
						rm_activos.fecha_inicial, '") ',
		' INTO TEMP tmp_a10 '
	PREPARE exec_a10 FROM query
	EXECUTE exec_a10
	LET query = 'SELECT a.* FROM actt012 a ',
		' WHERE a.a12_compania      = ', vg_codcia,
	  	'   AND a.a12_codigo_tran  NOT IN ("EG", "BA", "VE", "BV") ',
		'   AND a.a12_codigo_bien  IN ',
				'(SELECT a10_codigo_bien ',
				'FROM tmp_a10 ',
				'WHERE a10_compania = a.a12_compania) ',
		'   AND a.a12_valor_mb     <= 0 ',
		'   AND DATE(a.a12_fecing) <= "', rm_activos.fecha_final, '"',
		'   AND EXISTS (SELECT UNIQUE b.a12_codigo_tran ',
				'FROM actt012 b ',
				'WHERE b.a12_compania    = a.a12_compania ',
				'  AND b.a12_codigo_tran = "DP" ',
				'  AND b.a12_codigo_bien = a.a12_codigo_bien) ',
		' UNION ',
		' SELECT a.* FROM actt012 a ',
			' WHERE a.a12_compania      = ', vg_codcia,
			'   AND a.a12_codigo_tran  <> "EG" ',
			'   AND a.a12_codigo_bien  IN ',
				'(SELECT a10_codigo_bien ',
				'FROM tmp_a10 ',
				'WHERE a10_compania  = a.a12_compania ',
				'  AND a10_grupo_act = 1) ',
			'   AND a.a12_valor_mb     <= 0 ',
			'   AND DATE(a.a12_fecing) <= "',
						rm_activos.fecha_final, '"',
		' INTO TEMP tmp_a12 '
	PREPARE exec_a12 FROM query
	EXECUTE exec_a12
	LET query = 'SELECT a10_compania, a10_localidad, a10_grupo_act, ',
			'a10_tipo_act, a10_codigo_bien, a10_estado, ',
			'a10_valor_mb, ',
			'NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_ant, ',
			'a10_tot_dep_mb, a10_descripcion, a10_fecha_comp ',
		' FROM tmp_a10, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) < "', vm_fec_ini_dep, '"',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 9, 10, 11 ',
		' UNION',
		' SELECT a10_compania, a10_localidad, a10_grupo_act, ',
			'a10_tipo_act, a10_codigo_bien, a10_estado, ',
			'a10_valor_mb, 0.00 tot_dep_ant, a10_tot_dep_mb, ',
			'a10_descripcion, a10_fecha_comp ',
		' FROM tmp_a10, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND EXTEND(a12_fecing, YEAR TO MONTH) <= ',
			'EXTEND(DATE("', rm_activos.fecha_final,
					'"), YEAR TO MONTH) ',
		' INTO TEMP tt '
	PREPARE exec_tt FROM query
	EXECUTE exec_tt
	SELECT a10_compania, a10_localidad, a10_grupo_act, a10_tipo_act,
		a10_codigo_bien, a10_estado, a10_valor_mb,
		NVL(SUM(tot_dep_ant), 0) tot_dep_ant, a10_tot_dep_mb,
		a10_descripcion, a10_fecha_comp
		FROM tt
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 9, 10, 11
		INTO TEMP t1
	DROP TABLE tt
	LET query = 'SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_codigo_bien, a10_estado, a10_valor_mb, ',
			'tot_dep_ant, ',
			'NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_act, ',
			'a10_tot_dep_mb, a10_descripcion, a10_fecha_comp ',
		' FROM t1, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) BETWEEN "', vm_fec_ini_dep,
					  '" AND "', rm_activos.fecha_final,'"',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 9, 10, 11 ',
		' UNION ',
		' SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_codigo_bien, a10_estado, a10_valor_mb, ',
			'tot_dep_ant, 0.00 tot_dep_act, a10_tot_dep_mb, ',
			'a10_descripcion, a10_fecha_comp ',
		' FROM t1, tmp_a12 ',
		' WHERE a10_estado      IN ("N", "E", "V", "D")',
		'   AND a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) < "', vm_fec_ini_dep, '"',
		' INTO TEMP t2 '
	PREPARE exec_t2 FROM query
	EXECUTE exec_t2
	DROP TABLE tmp_a12
	DROP TABLE t1
	SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien,
		a10_estado, a10_valor_mb, NVL(tot_dep_ant, 0) tot_dep_ant,
		NVL(SUM(tot_dep_act), 0) tot_dep_act, a10_tot_dep_mb,
		a10_descripcion, a10_fecha_comp
		FROM t2
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 9, 10, 11
		UNION
		SELECT a10_localidad, a10_grupo_act, a10_tipo_act,
			a10_codigo_bien, a10_estado, a10_valor_mb,
			0.00 tot_dep_ant, 0.00 tot_dep_act, a10_tot_dep_mb,
			a10_descripcion, a10_fecha_comp
			FROM tmp_a10
			WHERE a10_grupo_act = 1
			  AND NOT EXISTS
				(SELECT 1 FROM t2
				WHERE t2.a10_codigo_bien =
					tmp_a10.a10_codigo_bien)
		UNION
		SELECT a10_localidad, a10_grupo_act, a10_tipo_act,
			a10_codigo_bien, a10_estado, a10_valor_mb,
			0.00 tot_dep_ant, 0.00 tot_dep_act, a10_tot_dep_mb,
			a10_descripcion, a10_fecha_comp
			FROM tmp_a10, actt012 a
			WHERE a.a12_compania      = a10_compania
			  AND a.a12_codigo_tran   = 'IN'
			  AND a.a12_codigo_bien   = a10_codigo_bien
			  AND DATE(a.a12_fecing) <= rm_activos.fecha_final
			  AND NOT EXISTS
				(SELECT UNIQUE b.a12_codigo_tran
				FROM actt012 b
				WHERE b.a12_compania      = a.a12_compania
		  		  AND b.a12_codigo_tran   = 'DP'
		  		  AND b.a12_codigo_bien   = a.a12_codigo_bien
				  AND DATE(b.a12_fecing) >=
						rm_activos.fecha_inicial)
		INTO TEMP t3
	DROP TABLE tmp_a10
	DROP TABLE t2
	SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien,
		a10_estado, a10_valor_mb, NVL(SUM(tot_dep_ant), 0) tot_dep_ant,
		NVL(SUM(tot_dep_act), 0) tot_dep_act, a10_descripcion,
		a10_fecha_comp
		FROM t3
		GROUP BY 1, 2, 3, 4, 5, 6, 9, 10
		INTO TEMP t2
	DROP TABLE t3
	LET query = 'SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
				'a10_codigo_bien, a10_estado, ',
				'CASE WHEN NVL((SELECT 1 FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND fec_baj  <= "',
						rm_activos.fecha_final, '"), ',
					'0) = 0 ',
					'THEN a10_valor_mb ',
					'ELSE 0.00 ',
				'END a10_valor_mb, ',
				'tot_dep_ant, tot_dep_act, ',
				'CASE WHEN NVL((SELECT 1 FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND fec_baj  <= "',
						rm_activos.fecha_final, '"), ',
					'0) = 0 ',
					'THEN (tot_dep_ant + tot_dep_act) ',
					'ELSE 0.00 ',
				'END valor_dep, ',
				'a10_descripcion, a10_fecha_comp ',
			' FROM t2 ',
			' INTO TEMP tmp_mov '
	PREPARE exec_mov FROM query
	EXECUTE exec_mov
	DROP TABLE t2
	DROP TABLE tmp_baj
	DROP TABLE tmp_consulta
	LET query = 'SELECT a10_localidad tit_localidad, ',
				'a10_grupo_act grupo_act, ',
				'a10_tipo_act tipo_act, ',
				'a10_codigo_bien codigo_bien, ',
				'a10_descripcion decripcion, ',
				'a10_fecha_comp fecha_compra, ',
				'a10_valor_mb valor_compra, valor_dep, ',
				'a10_estado estado, ',
				'CASE WHEN a10_estado = "V" OR ',
						'a10_estado = "E" ',
					'THEN a10_valor_mb - valor_dep ',
					'ELSE (a10_valor_mb - (tot_dep_ant ',
						'+ tot_dep_act)) ',
				'END valor_actual ',
			'FROM tmp_mov ',
			'INTO TEMP tmp_consulta '
	PREPARE exec_cons FROM query
	EXECUTE exec_cons
	DROP TABLE tmp_mov
	DELETE FROM tmp_consulta
		WHERE estado       IN ("V", "E")
		  AND valor_actual <= 0
		  AND codigo_bien  IN
			(SELECT a10_codigo_bien
				FROM actt010
				WHERE a10_compania    = vg_codcia
				  AND a10_fecha_baja <= rm_activos.fecha_final)
END IF
SELECT COUNT(*) INTO vm_num_detalle FROM tmp_consulta
IF vm_num_detalle = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY vm_indice      TO num_rows
DISPLAY vm_num_detalle TO max_rows

END FUNCTION



FUNCTION control_muestra_detalle()
DEFINE val_act		ARRAY[10000] OF LIKE actt010.a10_valor
DEFINE activo		LIKE actt012.a12_codigo_bien
DEFINE i, j, col, m	SMALLINT
DEFINE query		VARCHAR(800)
DEFINE tit_est		VARCHAR(30)

FOR i = 1 TO 10
	LET rm_orden[i] = ''
END FOR
LET col           = 2
LET vm_columna_1  = col
LET vm_columna_2  = 3
LET rm_orden[col] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM tmp_consulta ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE consulta_2 FROM query
	DECLARE q_consulta_2 CURSOR FOR consulta_2
	LET m = 1
	FOREACH q_consulta_2 INTO rm_detalle[m].*, val_act[m]
		LET m = m + 1
		IF m > vm_num_detalle THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET m = m - 1
	CALL mostrar_total_det(vm_num_detalle)
	LET int_flag = 0
	CALL set_count(vm_num_detalle)
	DISPLAY ARRAY rm_detalle TO rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_activo(rm_detalle[i].a10_codigo_bien)
			LET int_flag = 0
		ON KEY(F6)
			IF activo IS NULL THEN
				CONTINUE DISPLAY
			END IF
			LET i = arr_curr()
			CALL control_movimientos(rm_detalle[i].a10_codigo_bien)
			LET int_flag = 0
		ON KEY(F7)
			CALL control_imprimir_det()
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
			CALL dialog.keysetlabel('F7','Imprimir')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			LET vm_indice = i
			CALL muestra_contadores()
			CALL muestra_estado(rm_detalle[i].estado, 2)
				RETURNING tit_est
			DISPLAY val_act[i] TO valor_actual
			INITIALIZE activo TO NULL
			SELECT UNIQUE a12_codigo_bien
				INTO activo
				FROM actt012
				WHERE a12_compania    = vg_codcia
				  AND a12_codigo_bien =
						rm_detalle[i].a10_codigo_bien
			IF activo IS NULL THEN
				CALL dialog.keysetlabel('F6', '')
			ELSE
				CALL dialog.keysetlabel('F6', 'Movimientos')
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



FUNCTION control_movimientos(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_reg		RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_tipcomp_gen	LIKE actt012.a12_tipcomp_gen,
				a12_numcomp_gen	LIKE actt012.a12_numcomp_gen,
				a12_fecing	LIKE actt012.a12_fecing,
				a12_referencia	LIKE actt012.a12_referencia,
				a12_porc_deprec	LIKE actt012.a12_porc_deprec,
				a12_valor_mb	LIKE actt012.a12_valor_mb
			END RECORD
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE num_row, max_row	SMALLINT
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(1500)

OPEN WINDOW w_movact AT 04, 02 WITH 20 ROWS, 80 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST)
OPEN FORM frm_movact FROM '../forms/actf300_2'
DISPLAY FORM frm_movact
DISPLAY "TP"		TO tit_col1
DISPLAY "Número"	TO tit_col2
DISPLAY "DC"		TO tit_col3
DISPLAY "Compr."	TO tit_col4
DISPLAY "Fecha"		TO tit_col5
DISPLAY "Referencia"	TO tit_col6
DISPLAY "%"		TO tit_col7
DISPLAY "Valor"		TO tit_col8
CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
CALL fl_lee_grupo_activo(r_a10.a10_compania, r_a10.a10_grupo_act)
	RETURNING r_a01.*
DISPLAY BY NAME r_a10.a10_grupo_act, r_a10.a10_codigo_bien,
		r_a10.a10_descripcion, r_a10.a10_valor_mb, r_a10.a10_tot_dep_mb,
		r_a01.a01_nombre
FOR i = 1 TO vm_max_movact
	INITIALIZE rm_movact[i].* TO NULL
END FOR
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col           = 5
LET vm_columna_1  = col
LET vm_columna_2  = 1
LET rm_orden[col] = 'ASC'
WHILE TRUE
	LET query = 'SELECT a12_codigo_tran, a12_numero_tran, a12_tipcomp_gen,',
				' a12_numcomp_gen, a12_fecing, a12_referencia,',
				' a12_porc_deprec, a12_valor_mb ',
			' FROM actt012 ',
			' WHERE a12_compania    = ', r_a10.a10_compania,
			'   AND a12_codigo_bien = ', r_a10.a10_codigo_bien,
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE mov FROM query
	DECLARE q_mov CURSOR FOR mov
	LET vm_num_movact = 1
	FOREACH q_mov INTO r_reg.*
		LET rm_movact[vm_num_movact].a12_codigo_tran =
							r_reg.a12_codigo_tran
		LET rm_movact[vm_num_movact].a12_numero_tran =
							r_reg.a12_numero_tran
		LET rm_movact[vm_num_movact].a12_tipcomp_gen =
							r_reg.a12_tipcomp_gen
		LET rm_movact[vm_num_movact].a12_numcomp_gen =
							r_reg.a12_numcomp_gen
		LET rm_movact[vm_num_movact].a12_fecing      =
							DATE(r_reg.a12_fecing)
		LET rm_movact[vm_num_movact].a12_referencia  =
							r_reg.a12_referencia
		LET rm_movact[vm_num_movact].a12_porc_deprec =
							r_reg.a12_porc_deprec
		LET rm_movact[vm_num_movact].a12_valor_mb    =
							r_reg.a12_valor_mb
		LET vm_num_movact = vm_num_movact + 1
		IF vm_num_movact > vm_max_movact THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_movact = vm_num_movact - 1
	IF vm_num_movact = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	CALL mostrar_total(vm_num_movact)
	LET int_flag = 0
	CALL set_count(vm_num_movact)
	DISPLAY ARRAY rm_movact TO rm_movact.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY                 
		ON KEY(F5)
			CALL ver_activo(activo)
			LET int_flag = 0
		ON KEY(F6)
			CALL ver_orden_compra(activo)
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_transaccion(rm_movact[i].a12_codigo_tran,
						rm_movact[i].a12_numero_tran)
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			CALL control_contabilizacion(activo, rm_movact[i].*)
			LET int_flag = 0
		ON KEY(F9)
			CALL control_imprimir_mov(activo)
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
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			DISPLAY i             TO num_row
			DISPLAY vm_num_movact TO max_row
			DISPLAY rm_movact[i].a12_referencia TO referencia
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
CLOSE WINDOW w_movact
RETURN

END FUNCTION



FUNCTION mostrar_total(m)
DEFINE m, i		SMALLINT
DEFINE total		DECIMAL(14,2)

LET total = 0
FOR i = 1 TO m
	LET total = total + rm_movact[i].a12_valor_mb
END FOR
DISPLAY BY NAME total

END FUNCTION



FUNCTION mostrar_total_det(m)
DEFINE m, i		SMALLINT
DEFINE total_comp	DECIMAL(12,2)
DEFINE total_act	DECIMAL(12,2)
DEFINE valor_libros	DECIMAL(12,2)

LET total_comp = 0
LET total_act  = 0
FOR i = 1 TO m
	LET total_comp = total_comp + rm_detalle[i].a10_valor
	LET total_act  = total_act + rm_detalle[i].valor_dep
END FOR
LET valor_libros = total_comp - total_act
DISPLAY BY NAME total_comp, total_act, valor_libros

END FUNCTION



FUNCTION control_contabilizacion(activo, r_mov)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE r_mov		RECORD
				a12_codigo_tran	LIKE actt012.a12_codigo_tran,
				a12_numero_tran	LIKE actt012.a12_numero_tran,
				a12_tipcomp_gen	LIKE actt012.a12_tipcomp_gen,
				a12_numcomp_gen	LIKE actt012.a12_numcomp_gen,
				a12_fecing	DATE,
				a12_referencia	LIKE actt012.a12_referencia,
				a12_porc_deprec	LIKE actt012.a12_porc_deprec,
				a12_valor_mb	LIKE actt012.a12_valor_mb
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
		r_mov.a12_fecing, r_mov.a12_referencia, r_mov.a12_valor_mb,
		total_db, total_cr, util_per
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



FUNCTION ver_transaccion(codtran, numtran)
DEFINE codtran		LIKE actt012.a12_codigo_tran
DEFINE numtran		LIKE actt012.a12_numero_tran
DEFINE param		VARCHAR(60)

LET param = ' "', codtran, '" ', numtran
CALL ejecuta_comando('ACTIVOS', vg_modulo, 'actp200', param)

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
DEFINE param		VARCHAR(60)
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



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detalle')
	CLEAR rm_detalle[i].*
END FOR
FOR i = 1 TO vm_max_detalle
	INITIALIZE rm_detalle[i].* TO NULL
END FOR
CLEAR num_rows, max_rows, desc_estado, total_comp, total_act, valor_actual,
	valor_libros

END FUNCTION



FUNCTION muestra_estado(estado, flag)
DEFINE estado		LIKE actt010.a10_estado
DEFINE flag		SMALLINT
DEFINE tit_estado	LIKE actt006.a06_descripcion
DEFINE r_a06		RECORD LIKE actt006.*

LET tit_estado = NULL
CALL fl_lee_estado_activos(vg_codcia, estado) RETURNING r_a06.*
IF r_a06.a06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Estado no existe.', 'exclamation')
	RETURN tit_estado
END IF
LET tit_estado = r_a06.a06_descripcion
CASE flag
	WHEN 1 DISPLAY BY NAME tit_estado
	WHEN 2 DISPLAY tit_estado TO desc_estado
END CASE
RETURN tit_estado

END FUNCTION



FUNCTION control_imprimir_det()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_detalle_activo TO PIPE comando
FOR i = 1 TO vm_num_detalle
	OUTPUT TO REPORT reporte_detalle_activo(i)
END FOR
FINISH REPORT reporte_detalle_activo

END FUNCTION



REPORT reporte_detalle_activo(i)
DEFINE i		SMALLINT
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
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
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 005, r_g01.g01_razonsocial,
  	      COLUMN 090, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 028, "CONSULTA DE ACTIVOS FIJOS",
	      COLUMN 090, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 010, "** ESTADO ACTIVOS FIJOS  : ", rm_activos.a10_estado,
		" ", muestra_estado(rm_activos.a10_estado, 0) CLIPPED
	IF rm_activos.a10_grupo_act IS NOT NULL THEN
		CALL fl_lee_grupo_activo(vg_codcia, rm_activos.a10_grupo_act)
			RETURNING r_a01.*
		PRINT COLUMN 010, "** GRUPO DE ACTIVOS FIJOS: ",
			rm_activos.a10_grupo_act USING "<<<&&", " ",
			r_a01.a01_nombre CLIPPED
	END IF
	IF rm_activos.a10_tipo_act IS NOT NULL THEN
		CALL fl_lee_tipo_activo(vg_codcia, rm_activos.a10_tipo_act)
			RETURNING r_a02.*
		PRINT COLUMN 010, "** TIPO DE ACTIVOS FIJOS : ",
			rm_activos.a10_tipo_act USING "<<<&&", " ",
			r_a02.a02_nombre CLIPPED
	END IF
	IF rm_activos.a10_localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, rm_activos.a10_localidad)
			RETURNING r_g02.*
		PRINT COLUMN 010, "** LOCALIDAD DE ORIGEN   : ",
			rm_activos.a10_localidad USING "&&", " ",
			r_g02.g02_nombre CLIPPED
	END IF
	PRINT COLUMN 010, "** PERIODO DE COMPRA     : ",
		rm_activos.fecha_inicial USING "dd-mm-yyyy", "  -  ",
		rm_activos.fecha_final USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 078, usuario CLIPPED
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "LC",
	      COLUMN 004, "GR",
	      COLUMN 007, "TIP",
	      COLUMN 011, "CODIGO",
	      COLUMN 026, "D E S C R I P C I O N",
	      COLUMN 057, "FECHA COMP",
	      COLUMN 068, "VALOR ACTIVOS",
	      COLUMN 082, "DEPREC. ACUM.",
	      COLUMN 096, "E"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, rm_detalle[i].tit_localidad	USING "&&",
	      COLUMN 004, rm_detalle[i].grupo_act	USING "&&",
	      COLUMN 007, rm_detalle[i].tipo_act	USING "&&&",
	      COLUMN 011, rm_detalle[i].a10_codigo_bien	USING "<<<&&&",
	      COLUMN 018, rm_detalle[i].a10_descripcion[1, 38] CLIPPED,
	      COLUMN 057, rm_detalle[i].a10_fecha_comp	USING "dd-mm-yyyy",
	      COLUMN 068, rm_detalle[i].a10_valor	USING "--,---,--&.##",
	      COLUMN 082, rm_detalle[i].valor_dep	USING "--,---,--&.##",
	      COLUMN 096, rm_detalle[i].estado		CLIPPED

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 070, "-------------",
	      COLUMN 084, "-------------"
	PRINT COLUMN 055, "TOTALES ==>",
	      COLUMN 068, SUM(rm_detalle[i].a10_valor)	USING "--,---,--&.##",
	      COLUMN 082, SUM(rm_detalle[i].valor_dep)	USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT



FUNCTION control_imprimir_mov(activo)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_movimiento_activo TO PIPE comando
FOR i = 1 TO vm_num_movact
	OUTPUT TO REPORT reporte_movimiento_activo(activo, i)
END FOR
FINISH REPORT reporte_movimiento_activo

END FUNCTION



REPORT reporte_movimiento_activo(activo, i)
DEFINE activo		LIKE actt010.a10_codigo_bien
DEFINE i		SMALLINT
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE util_per		LIKE ctbt013.b13_valor_base
DEFINE etiqueta		VARCHAR(12)
DEFINE col		SMALLINT
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
	      COLUMN 027, "MOVIMIENTOS DEL ACTIVO FIJO",
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	CALL fl_lee_codigo_bien(vg_codcia, activo) RETURNING r_a10.*
	PRINT COLUMN 010, "** ACTIVO FIJO: ", activo USING "<<<&&&",
		" ", r_a10.a10_descripcion CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 062, usuario CLIPPED
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "TP",
	      COLUMN 004, "NUMERO",
	      COLUMN 011, "COMP. CONT.",
	      COLUMN 023, "FECHA TRAN",
	      COLUMN 038, "R E F E R E N C I A",
	      COLUMN 062, "% DEP",
	      COLUMN 069, "VALOR TRANS."
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 4 LINES
	PRINT COLUMN 001, rm_movact[i].a12_codigo_tran	CLIPPED,
	      COLUMN 004, rm_movact[i].a12_numero_tran	USING "<<<<&&",
	      COLUMN 011, rm_movact[i].a12_tipcomp_gen	CLIPPED,
	      COLUMN 014, rm_movact[i].a12_numcomp_gen	CLIPPED,
	      COLUMN 023, rm_movact[i].a12_fecing	USING "dd-mm-yyyy",
	      COLUMN 034, rm_movact[i].a12_referencia[1, 27] CLIPPED,
	      COLUMN 062, rm_movact[i].a12_porc_deprec	USING "#&.##",
	      COLUMN 068, rm_movact[i].a12_valor_mb	USING "--,---,--&.##"

ON LAST ROW
	NEED 3 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 070, "-------------"
	PRINT COLUMN 057, "TOTAL ==>",
	      COLUMN 068, SUM(rm_movact[i].a12_valor_mb) USING "--,---,--&.##"
	SELECT NVL(SUM(b13_valor_base), 0)
		INTO util_per
		FROM actt012, actt015, ctbt012, ctbt013, ctbt010
		WHERE a12_compania    = vg_codcia
		  AND a12_codigo_tran = 'VE'
		  AND a12_codigo_bien = activo
		  AND a15_compania    = a12_compania
		  AND a15_codigo_tran = a12_codigo_tran
		  AND a15_numero_tran = a12_numero_tran
		  AND b12_compania    = a15_compania
		  AND b12_tipo_comp   = a15_tipo_comp
		  AND b12_num_comp    = a15_num_comp
		  AND b12_estado      <> 'E'
		  AND b13_compania    = b12_compania
		  AND b13_tipo_comp   = b12_tipo_comp
		  AND b13_num_comp    = b12_num_comp
		  AND b10_compania    = b13_compania
		  AND b10_cuenta      = b13_cuenta
		  AND b10_tipo_cta    = 'R'
	IF util_per <> 0 THEN
		LET etiqueta = 'PERDIDA ==>'
		LET col      = 55
		IF util_per < 0 THEN
			LET util_per = util_per * (-1)
			LET etiqueta = 'UTILIDAD ==>'
			LET col      = 54
		END IF
		SKIP 1 LINES
		PRINT COLUMN col, etiqueta	CLIPPED,
		      COLUMN 068, util_per	USING "--,---,--&.##";
	ELSE
		PRINT ' ';
	END IF
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_comp

END REPORT

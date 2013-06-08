DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE vm_tipo_doc	LIKE cxct004.z04_tipo_doc
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE base, base1	CHAR(20)
DEFINE vm_dias_mes	SMALLINT



MAIN

	IF num_args() <> 3 AND num_args() <> 4 THEN
		DISPLAY 'Número de Parametros Incorrectos. Falta BASE LOCALIDAD TIPO_DOC [SERVER].'
		EXIT PROGRAM
	END IF
	LET base        = arg_val(1)
	LET codcia      = 1
	LET codloc      = arg_val(2)
	LET vm_tipo_doc = arg_val(3)
	LET base1       = base CLIPPED
	IF num_args() = 4 THEN
		LET base = base CLIPPED, '@', arg_val(4)
	END IF
	CALL activar_base()
	CALL validar_parametros()
	CALL ejecuta_proceso()

END MAIN



FUNCTION activar_base()
DEFINE r_g51		RECORD LIKE gent051.*

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051
	WHERE g51_basedatos = base1
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base1
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()

INITIALIZE r_g02.* TO NULL
SELECT * INTO r_g02.* FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la Localidad ', codloc USING '<<&', '.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_g39		RECORD LIKE gent039.*
DEFINE diferencia	INTEGER
DEFINE tope, num_dias	INTEGER
DEFINE prom_diario	DECIMAL(9,2)
DEFINE diferencia_c	VARCHAR(10)
DEFINE num_dias_c	VARCHAR(10)

LET vm_dias_mes = 20
CALL ejecuta_proceso_documentos() RETURNING prom_diario
INITIALIZE r_g37.*, r_g39.* TO NULL
SELECT * INTO r_g39.* FROM gent039
	WHERE g39_compania  = codcia
	  AND g39_localidad = codloc
	  AND g39_tipo_doc  = vm_tipo_doc
	  AND g39_secuencia IN
		(SELECT MAX(g39_secuencia) FROM gent039
			WHERE g39_compania  = codcia
			  AND g39_localidad = codloc
			  AND g39_tipo_doc  = vm_tipo_doc)
	  AND g39_fec_entrega IN
		(SELECT MAX(g39_fec_entrega) FROM gent039
			WHERE g39_compania  = codcia
			  AND g39_localidad = codloc
			  AND g39_tipo_doc  = vm_tipo_doc
			  AND g39_secuencia IN
				(SELECT MAX(g39_secuencia) FROM gent039
					WHERE g39_compania  = codcia
					  AND g39_localidad = codloc
					  AND g39_tipo_doc  = vm_tipo_doc))
IF r_g39.g39_compania IS NULL THEN
	IF vm_tipo_doc = 'ND' AND codloc = 2 THEN
		EXIT PROGRAM
	END IF
	DISPLAY 'No ha Ingresado el Documento ', vm_tipo_doc,
		' en la tabla de control. -- LOCALIDAD: ',
		r_g02.g02_nombre CLIPPED, '.'
	EXIT PROGRAM
END IF
SELECT * INTO r_g37.* FROM gent037
	WHERE g37_compania  = codcia
	  AND g37_localidad = r_g39.g39_localidad
	  AND g37_tipo_doc  = r_g39.g39_tipo_doc
	  AND g37_secuencia IN
		(SELECT MAX(g37_secuencia) FROM gent037
			WHERE g37_compania  = codcia
			  AND g37_localidad = r_g39.g39_localidad
			  AND g37_tipo_doc  = r_g39.g39_tipo_doc)
IF r_g37.g37_compania IS NULL THEN
	DISPLAY 'No existe el Documento ', vm_tipo_doc,
		' en la tabla de control del SRI (gent037).',
		' -- LOCALIDAD: ', r_g02.g02_nombre CLIPPED, '.'
	EXIT PROGRAM
END IF
LET diferencia = r_g39.g39_num_sri_fin - r_g37.g37_sec_num_sri
SELECT ROUND(prom_diario * g39_num_dias_col, 0) INTO tope
	FROM gent039
	WHERE g39_compania    = r_g39.g39_compania
	  AND g39_localidad   = r_g39.g39_localidad
	  AND g39_tipo_doc    = r_g39.g39_tipo_doc
	  AND g39_secuencia   = r_g39.g39_secuencia
	  AND g39_fec_entrega = r_g39.g39_fec_entrega
IF diferencia <= tope THEN
	SELECT * INTO r_z04.* FROM cxct004 WHERE z04_tipo_doc = vm_tipo_doc
	SELECT ROUND(diferencia / prom_diario, 0) INTO num_dias FROM dual
	LET diferencia_c = diferencia USING "-----&"
	LET num_dias_c   = num_dias   USING "---&"
	DISPLAY	r_g02.g02_abreviacion CLIPPED, ' - ', r_z04.z04_nombre CLIPPED,
 		'. QUEDAN ', diferencia_c USING "-<<<<&", ' Formularios de ',
		r_z04.z04_nombre CLIPPED, 	--' en LOCALIDAD: ',
 		'. Y que son para ',num_dias_c USING "-<<&", ' dias laborables.'
END IF

END FUNCTION



FUNCTION ejecuta_proceso_documentos()
DEFINE v_prom_m		DECIMAL(9,2)
DEFINE v_prom_d		DECIMAL(9,2)

SELECT COUNT(*) cuantas, MONTH(t23_fecing) mes, YEAR(t23_fecing) anio,'TA' mod
 	FROM talt023
	WHERE t23_compania = 10
	GROUP BY 2, 3, 4
	INTO TEMP t1
CASE vm_tipo_doc
	WHEN 'FA'
		CALL ejecuta_query_principal('TA')
		CALL ejecuta_query_principal('RE')
	WHEN 'NC'
		CALL ejecuta_query_principal('XX')
	WHEN 'ND'
		CALL ejecuta_query_principal('XX')
END CASE
SELECT anio, 0 t_mes, NVL(SUM(cuantas), 0) tot_mes
	FROM t1
	GROUP BY 1, 2
	INTO TEMP t2
SELECT anio, max(mes) t_m FROM t1 GROUP BY 1 INTO TEMP t3
DROP TABLE t1
UPDATE t2 SET t_mes = (SELECT t_m FROM t3 WHERE t3.anio = t2.anio)
	WHERE t2.anio in (SELECT t3.anio FROM t3)
DROP TABLE t3
SELECT anio, ROUND((tot_mes / t_mes), 2) prom_mes
	FROM t2
	GROUP BY 1, 2
	INTO TEMP t3
UPDATE t3 SET t3.anio = (SELECT COUNT(t2.anio) FROM t2) WHERE 1 = 1
DROP TABLE t2
SELECT UNIQUE anio, SUM(prom_mes) tot_fact FROM t3 GROUP BY 1 INTO TEMP t2
DROP TABLE t3
SELECT ROUND(tot_fact / anio) prom_mes_anio,
		ROUND(ROUND(tot_fact / anio) / vm_dias_mes, 2) prom_dia_anio
	INTO v_prom_m, v_prom_d 
	FROM t2
DROP TABLE t2
RETURN v_prom_d

END FUNCTION



FUNCTION ejecuta_query_principal(modulo)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE prefijo		CHAR(3)
DEFINE tabla		VARCHAR(10)
DEFINE expr_fact	VARCHAR(100)
DEFINE query		CHAR(800)

CASE modulo
	WHEN 'TA'
		LET prefijo   = 't23'
		LET tabla     = 'talt023'
		LET expr_fact = '   AND ', prefijo, '_estado    = "F"'
	WHEN 'RE'
		LET prefijo   = 'r19'
		LET tabla     = 'rept019'
		LET expr_fact = '   AND ', prefijo, '_cod_tran  = "FA"'
END CASE
CASE vm_tipo_doc
	WHEN 'NC'
		LET prefijo   = 'z21'
		LET tabla     = 'cxct021'
	WHEN 'ND'
		LET prefijo   = 'z20'
		LET tabla     = 'cxct020'
END CASE
IF modulo = 'XX' THEN
	LET expr_fact = '   AND ', prefijo, '_tipo_doc  = "', vm_tipo_doc, '"'
END IF
LET query = 'INSERT INTO t1 ',
		'SELECT COUNT(*) cuantas, MONTH(', prefijo, '_fecing) mes, ',
			' YEAR(', prefijo, '_fecing) anio, "', modulo, '" mod ',
			' FROM ', tabla CLIPPED,
			' WHERE ', prefijo, '_compania  = ', codcia,
			'   AND ', prefijo, '_localidad = ', codloc,
				expr_fact CLIPPED,
			'   AND EXTEND(', prefijo, '_fecing, YEAR TO MONTH) < ',
			'	(SELECT EXTEND(mdy(r00_mespro, 1, r00_anopro),',
			' 		YEAR TO MONTH) ',
			'		FROM rept000 ',
			'		WHERE r00_compania = ', prefijo,
								'_compania)',
			' GROUP BY 2, 3, 4 '
PREPARE ej_temp FROM query
EXECUTE ej_temp

END FUNCTION

DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base		CHAR(20)



MAIN

	IF num_args() <> 1 THEN
		DISPLAY 'Error de Parametros. Falta la Localidad.'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	LET codloc = arg_val(1)
	CASE codloc
		WHEN 1
			LET base = 'acero_gm'
		WHEN 2
			LET base = 'acero_gc'
		WHEN 3
			LET base = 'acero_qm'
		WHEN 4
			LET base = 'acero_qs'
	END CASE
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
	WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros()
DEFINE r_g02		RECORD LIKE gent002.*

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
DEFINE total_facturas	INTEGER
DEFINE v_anio, v_mes	INTEGER
DEFINE v_tot_mes	INTEGER
DEFINE v_prom_m		DECIMAL(9,2)
DEFINE v_prom_d		DECIMAL(9,2)

SELECT COUNT(*) cuantas, MONTH(t23_fecing) mes, YEAR(t23_fecing) anio,'TA' mod
 	FROM talt023
	WHERE t23_compania = 10
	GROUP BY 2, 3, 4
	INTO TEMP t1
CALL ejecuta_query_principal('TA')
CALL ejecuta_query_principal('RE')
SELECT NVL(SUM(cuantas), 0) INTO total_facturas FROM t1
DISPLAY ' '
DISPLAY '     TOTAL FACTURAS'
DISPLAY '         ', total_facturas USING "###,##&.##"
DISPLAY ' '
DISPLAY ' '
SELECT anio, 0 t_mes, NVL(SUM(cuantas), 0) tot_mes
	FROM t1
	GROUP BY 1, 2
	INTO TEMP t2
SELECT anio, max(mes) t_m FROM t1 GROUP BY 1 INTO TEMP t3
DROP TABLE t1
UPDATE t2 SET t_mes = (SELECT t_m FROM t3 WHERE t3.anio = t2.anio)
	WHERE t2.anio in (SELECT t3.anio FROM t3)
DROP TABLE t3
DECLARE q_tot1 CURSOR FOR SELECT anio, t_mes, tot_mes FROM t2
DISPLAY 'AÑOS          MESES    TOT. F. MESES'
FOREACH q_tot1 INTO v_anio, v_mes, v_tot_mes
	DISPLAY v_anio USING "&&&&", '             ', v_mes USING "&#",
		'        ', v_tot_mes USING "##,##&.##"
END FOREACH
DISPLAY ' '
DECLARE q_tot2 CURSOR FOR
	SELECT anio, ROUND((tot_mes / t_mes), 2) prom_mes,
		ROUND(ROUND((tot_mes / t_mes), 2) / 20, 2) prom_dia
		FROM t2
		GROUP BY 1, 2, 3
DISPLAY 'AÑOS    PROM. MESES       PROM. DIAS'
FOREACH q_tot2 INTO v_anio, v_prom_m, v_prom_d
	DISPLAY v_anio USING "&&&&", '       ', v_prom_m USING "#,##&.##",
		'           ', v_prom_d USING "##&.##"
END FOREACH
DISPLAY ' '
SELECT anio, ROUND((tot_mes / t_mes), 2) prom_mes
	FROM t2
	GROUP BY 1, 2
	INTO TEMP t3
UPDATE t3 SET t3.anio = (SELECT COUNT(t2.anio) FROM t2) WHERE 1 = 1
DROP TABLE t2
SELECT UNIQUE anio, SUM(prom_mes) tot_fact FROM t3 GROUP BY 1 INTO TEMP t2
DROP TABLE t3
SELECT ROUND(tot_fact / anio) prom_mes_anio,
		ROUND(ROUND(tot_fact / anio) / 20, 2) prom_dia_anio
	INTO v_prom_m, v_prom_d 
	FROM t2
DISPLAY ' '
DISPLAY '      PROM. MES AÑO    PROM. DIA AÑO'
DISPLAY '           ', v_prom_m USING "#,##&.##", '           ',
	v_prom_d USING "##&.##"
DISPLAY ' '
DROP TABLE t2

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

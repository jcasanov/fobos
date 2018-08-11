DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc1, codloc2	LIKE gent002.g02_localidad
DEFINE base1, base2	CHAR(20)
DEFINE anio		SMALLINT



MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'ERRO EN PARAMETROS: COMPANIA ANIO BASE1 BASE2'
		EXIT PROGRAM
	END IF
	LET codcia = arg_val(1)
	LET anio   = arg_val(2)
	LET base1  = arg_val(3)
	LET base2  = arg_val(4)
	CASE codcia
		WHEN 1	LET codloc1 = 1
			LET codloc2 = 3
		WHEN 2	LET codloc1 = 6
			LET codloc2 = 7
	END CASE
	CALL ejecutar_proceso()
	DISPLAY 'Proceso Terminado OK.'

END MAIN



FUNCTION ejecutar_proceso()
DEFINE r_tp		RECORD
				loc		SMALLINT,
				t_emp		SMALLINT,
				t_car		SMALLINT,
				puntos_trab	INTEGER,
				puntos_carg	INTEGER
			END RECORD
DEFINE r_val		RECORD
				local		SMALLINT,
				utilidad	DECIMAL(12,2)
			END RECORD
DEFINE r_emp		RECORD
				loc		SMALLINT,
				cod		CHAR(3),
				empleado	VARCHAR(38),
				val_ut		DECIMAL(12,2),
				val_c		DECIMAL(12,2),
				tot_ut		DECIMAL(12,2)
			END RECORD
DEFINE r_tot		RECORD
				loc		SMALLINT,
				val_rep_trab	DECIMAL(12,2),
				val_rep_carg	DECIMAL(12,2),
				partic_15	DECIMAL(12,2)
			END RECORD
DEFINE utilidad_neta1	DECIMAL(12,2)
DEFINE val_rep_trab1	DECIMAL(12,2)
DEFINE val_rep_carg1	DECIMAL(12,2)
DEFINE puntos_trab1	DECIMAL(12,2)
DEFINE puntos_carg1	DECIMAL(12,2)
DEFINE val_ut_trab1	DECIMAL(12,2)
DEFINE val_ut_carg1	DECIMAL(12,2)
DEFINE query		CHAR(3000)
DEFINE fila		SMALLINT

LET query = 'SELECT ', codloc1, ' loc_c, n31_cod_trab, n31_tipo_carga, ',
		'COUNT(n31_secuencia) tot_carg ',
		' FROM ', base1 CLIPPED, ':rolt031, ',base1 CLIPPED, ':rolt030',
		' WHERE n31_compania     = ', codcia,
		'   AND n31_tipo_carga  <> "H"',
		'   AND n31_fecha_nacim <= MDY(12, 31, ', anio, ')',
		'   AND n30_compania     = n31_compania ',
		'   AND n30_cod_trab     = n31_cod_trab ',
		'   AND (n30_est_civil   = "C"',
		'    OR  n30_est_civil   = "U")',
		' GROUP BY 1, 2, 3 ',
		' UNION ALL ',
		' SELECT ', codloc1, ' loc_c, n31_cod_trab, n31_tipo_carga, ',
			' COUNT(n31_secuencia) tot_carg ',
			' FROM ', base1 CLIPPED, ':rolt031 ',
			' WHERE n31_compania     = ', codcia,
			'   AND n31_tipo_carga   = "H"',
			'   AND n31_fecha_nacim >= MDY(12, 31, ', anio, ')',
					' - 19 UNITS YEAR + 1 UNITS DAY ',
		 	'  AND n31_fecha_nacim <= MDY(12, 31, ', anio, ')',
			' GROUP BY 1, 2, 3 ',
		' UNION ALL ',
		' SELECT ', codloc2, ' loc_c, n31_cod_trab, n31_tipo_carga, ',
			' COUNT(n31_secuencia) tot_carg ',
			' FROM ', base2 CLIPPED, ':rolt031, ',
				base2 CLIPPED, ':rolt030 ',
			' WHERE n31_compania     = ', codcia,
			'   AND n31_tipo_carga  <> "H"',
			'   AND n31_fecha_nacim <= MDY(12, 31, ', anio, ')',
			'   AND n30_compania     = n31_compania ',
			'   AND n30_cod_trab     = n31_cod_trab ',
			'   AND (n30_est_civil   = "C"',
			'    OR  n30_est_civil   = "U")',
			' GROUP BY 1, 2, 3 ',
		' UNION ALL ',
		' SELECT ', codloc2, ' loc_c, n31_cod_trab, n31_tipo_carga, ',
			' COUNT(n31_secuencia) tot_carg ',
			' FROM ', base2 CLIPPED, ':rolt031 ',
			' WHERE n31_compania     = ', codcia,
			'   AND n31_tipo_carga   = "H"',
			'   AND n31_fecha_nacim >= MDY(12, 31, ', anio, ')',
					' - 19 UNITS YEAR + 1 UNITS DAY ',
			'   AND n31_fecha_nacim <= MDY(12, 31, ', anio, ')',
			' GROUP BY 1, 2, 3 ',
		' INTO TEMP tmp_car '
PREPARE exec_car FROM query
EXECUTE exec_car

LET query = 'SELECT ', codloc1, ' localidad, n30_cod_trab cod_trab, ',
		'n30_nombres nombres, n30_fecha_ing fecha_ing, ',
		'n30_fecha_reing fecha_reing, n30_fecha_sal fecha_sal, ',
		'CASE WHEN YEAR(n30_fecha_ing) = ', anio,
			' THEN ((MDY(12, 31, ', anio, ') - n30_fecha_ing) + 1)',
			' ELSE (SELECT n90_dias_ano_ut FROM ', base1 CLIPPED,
								':rolt090 ',
				' WHERE n90_compania = n30_compania) ',
		'END dias_trab, ',
		'(SELECT SUM(tot_carg) ',
			'FROM tmp_car ',
			'WHERE loc_c        = ', codloc1,
			'  AND n31_cod_trab = n30_cod_trab) num_cargas ',
		' FROM ', base1 CLIPPED, ':rolt030 ',
		' WHERE n30_compania    = ', codcia,
		'   AND n30_fecha_ing  <= MDY(12, 31, ', anio, ')',
		'   AND n30_fecha_sal  IS NULL ',
		'   AND n30_tipo_contr  = "F"',
	 	'   AND n30_estado     <> "J"',
		'   AND n30_tipo_trab   = "N"',
		'   AND n30_fec_jub    IS NULL ',
		' UNION ALL ',
		' SELECT ', codloc1, ' localidad, n30_cod_trab cod_trab, ',
			'n30_nombres nombres, n30_fecha_ing fecha_ing, ',
			'n30_fecha_reing fecha_reing, n30_fecha_sal fecha_sal,',
			' CASE WHEN YEAR(n30_fecha_sal) = ', anio,
				' THEN (n30_fecha_sal - MDY(01, 01, ',anio,'))',
				' ELSE (SELECT n90_dias_ano_ut FROM ',
						base1 CLIPPED, ':rolt090 ',
					'WHERE n90_compania = n30_compania) ',
			'END dias_trab, ',
			'(SELECT SUM(tot_carg) ',
				'FROM tmp_car ',
				'WHERE loc_c        = ', codloc1,
				'  AND n31_cod_trab = n30_cod_trab) num_cargas',
			' FROM ', base1 CLIPPED, ':rolt030 ',
			' WHERE n30_compania    = ', codcia,
			'   AND n30_fecha_ing  <= MDY(12, 31, ', anio, ')',
			'   AND n30_fecha_sal  <= MDY(12, 31, ', anio, ' + 1)',
			'   AND n30_tipo_contr  = "F"',
			'   AND n30_estado     <> "J"',
			'   AND n30_tipo_trab   = "N"',
		 	'   AND n30_fec_jub    IS NULL ',
		' UNION ALL ',
		' SELECT ', codloc2, ' localidad, n30_cod_trab cod_trab, ',
			'n30_nombres nombres, n30_fecha_ing fecha_ing, ',
			'n30_fecha_reing fecha_reing, n30_fecha_sal fecha_sal,',
			' CASE WHEN YEAR(n30_fecha_ing) = ', anio,
				' THEN ((MDY(12, 31, ', anio, ') - ',
					'n30_fecha_ing) + 1) ',
				' ELSE (SELECT n90_dias_ano_ut FROM ',
					base2 CLIPPED, ':rolt090 ',
					'WHERE n90_compania = n30_compania) ',
			' END dias_trab, ',
			'(SELECT SUM(tot_carg) ',
				'FROM tmp_car ',
				'WHERE loc_c        = ', codloc2,
				'  AND n31_cod_trab = n30_cod_trab) num_cargas',
			' FROM ', base2 CLIPPED, ':rolt030 ',
			' WHERE n30_compania    = ', codcia,
			'   AND n30_fecha_ing  <= MDY(12, 31, ', anio, ')',
			'   AND n30_fecha_sal  IS NULL ',
			'   AND n30_tipo_contr  = "F"',
			'   AND n30_estado     <> "J"',
			'   AND n30_tipo_trab   = "N"',
			'   AND n30_fec_jub    IS NULL ',
		' UNION ALL ',
		' SELECT ', codloc2, ' localidad, n30_cod_trab cod_trab, ',
			'n30_nombres nombres, n30_fecha_ing fecha_ing, ',
			'n30_fecha_reing fecha_reing, n30_fecha_sal fecha_sal,',
			' CASE WHEN YEAR(n30_fecha_sal) = ', anio,
				' THEN (n30_fecha_sal - MDY(01, 01, ',anio,'))',
				' ELSE (SELECT n90_dias_ano_ut FROM ',
						base2 CLIPPED, ':rolt090 ',
					'WHERE n90_compania = n30_compania) ',
			' END dias_trab, ',
			' (SELECT SUM(tot_carg) ',
				'FROM tmp_car ',
				'WHERE loc_c        = ', codloc2,
				'  AND n31_cod_trab = n30_cod_trab) num_cargas',
			' FROM ', base2 CLIPPED, ':rolt030 ',
			' WHERE n30_compania    = ', codcia,
			'   AND n30_fecha_ing  <= MDY(12, 31, ', anio, ')',
			'   AND n30_fecha_sal  <= MDY(12, 31, ', anio, ' + 1) ',
			'   AND n30_tipo_contr  = "F"',
			'   AND n30_estado     <> "J"',
			'   AND n30_tipo_trab   = "N"',
			'   AND n30_fec_jub    IS NULL ',
		' INTO TEMP te_trab '
PREPARE exec_trab FROM query
EXECUTE exec_trab

DROP TABLE tmp_car

DELETE FROM te_trab
	WHERE fecha_reing > MDY(12, 31, anio)

DELETE FROM te_trab
	WHERE  te_trab.fecha_sal < MDY(01, 01, anio)
	  AND (fecha_reing       IS NULL
	   OR  fecha_reing       > MDY(12, 31, anio))

{--
SELECT LPAD(localidad, 2, 0) loc, LPAD(cod_trab, 3, 0) cod,
	nombres[1, 40] empleado, LPAD(dias_trab, 3, 0) dias,
	LPAD(num_cargas, 2, 0) car, LPAD(dias_trab * num_cargas, 4, 0) p_car,
	LPAD(dias_trab + NVL(dias_trab * num_cargas, 0), 4, 0) tot_p
	FROM te_trab
	ORDER BY 1, 3
--}

SELECT LPAD(localidad, 2, 0) loc, COUNT(cod_trab) t_emp,
	ROUND(SUM(NVL(num_cargas, 0)), 2) t_car,
	NVL(ROUND(SUM(dias_trab), 2), 0) puntos_trab, 
	NVL(ROUND(SUM(dias_trab * num_cargas), 2), 0) puntos_carg
	FROM te_trab
	GROUP BY 1
	INTO TEMP t1

LET query = 'SELECT ', codloc1, ' local, ',
		'NVL(ROUND(SUM(b13_valor_base), 2), 0) utilidad ',
		' FROM ', base1 CLIPPED, ':ctbt012, ',base1 CLIPPED,':ctbt013 ',
		' WHERE b12_compania           = ', codcia,
		'   AND b12_estado            <> "E"',
		'   AND YEAR(b12_fec_proceso)  = ', anio,
		'   AND NOT EXISTS ',
			'(SELECT 1 FROM ', base1 CLIPPED, ':ctbt050 ',
				'WHERE b50_compania  = b12_compania ',
				'  AND b50_tipo_comp = b12_tipo_comp ',
				'  AND b50_num_comp  = b12_num_comp ',
				'  AND b50_anio      = YEAR(b12_fec_proceso)) ',
		'   AND b13_compania           = b12_compania ',
		'   AND b13_tipo_comp          = b12_tipo_comp ',
		'   AND b13_num_comp           = b12_num_comp ',
		'   AND b13_cuenta[1, 1]       > 3 ',
		' GROUP BY 1 ',
		' UNION ALL ',
		' SELECT ', codloc2, ' local, ',
			'NVL(ROUND(SUM(b13_valor_base), 2), 0) utilidad ',
			' FROM ', base2 CLIPPED, ':ctbt012, ',
				base2 CLIPPED, ':ctbt013 ',
			' WHERE b12_compania           = ', codcia,
			'   AND b12_estado            <> "E"',
			'   AND YEAR(b12_fec_proceso)  = ', anio,
			'   AND NOT EXISTS ',
				'(SELECT 1 FROM ', base2 CLIPPED, ':ctbt050 ',
				' WHERE b50_compania  = b12_compania ',
				'   AND b50_tipo_comp = b12_tipo_comp ',
			'   AND b50_num_comp  = b12_num_comp ',
			'   AND b50_anio      = YEAR(b12_fec_proceso)) ',
			'   AND b13_compania           = b12_compania ',
			'   AND b13_tipo_comp          = b12_tipo_comp ',
			'   AND b13_num_comp           = b12_num_comp ',
			'   AND b13_cuenta[1, 1]       > 3 ',
			' GROUP BY 1 ',
		' INTO TEMP tmp_ctb '
PREPARE exec_ctb FROM query
EXECUTE exec_ctb

DECLARE q_tot_ptos CURSOR FOR SELECT * FROM t1 ORDER BY 1
DISPLAY 'loc            t_emp            t_car      puntos_trab      ',
	'puntos_carg'
LET fila = 03
FOREACH q_tot_ptos INTO r_tp.*
	DISPLAY r_tp.loc         USING "&&"	AT fila, 02
	DISPLAY r_tp.t_emp       USING "##&"	AT fila, 18
	DISPLAY r_tp.t_car       USING "##&"	AT fila, 35
	DISPLAY r_tp.puntos_trab USING "####&"	AT fila, 50
	DISPLAY r_tp.puntos_carg USING "####&"	AT fila, 67
	LET fila = fila + 1
END FOREACH
LET fila = fila + 2

DECLARE q_loc_ut CURSOR FOR SELECT * FROM tmp_ctb ORDER BY 1
DISPLAY 'local         utilidad' AT fila, 01
LET fila = fila + 2
FOREACH q_loc_ut INTO r_val.*
	DISPLAY r_val.local    USING "&&"		AT fila, 04
	DISPLAY r_val.utilidad USING "--,---,--&.##"	AT fila, 10
	LET fila = fila + 1
END FOREACH
LET fila = fila + 2

SELECT NVL(ROUND(SUM(utilidad), 2), 0) utilidad_neta
        FROM tmp_ctb
        INTO TEMP t2

DROP TABLE tmp_ctb

SELECT * INTO utilidad_neta1 FROM t2
DISPLAY 'utilidad_neta' AT fila, 01
LET fila = fila + 2
DISPLAY utilidad_neta1 USING "--,---,--&.##" AT fila, 01

SELECT ROUND((((utilidad_neta * (-0.15)) / 3) * 2), 2) val_rep_trab,
	ROUND(((utilidad_neta * (-0.15)) / 3), 2) val_rep_carg
	FROM t2
	INTO TEMP t3

SELECT NVL(ROUND(SUM(puntos_trab), 2), 0) puntos_trab, 
	NVL(ROUND(SUM(puntos_carg), 2), 0) puntos_carg
	FROM t1
	INTO TEMP t4

DROP TABLE t1

DROP TABLE t2

LET fila = fila + 2
SELECT * INTO val_rep_trab1, val_rep_carg1 FROM t3
DISPLAY ' val_rep_trab     val_rep_carg' AT fila, 01
LET fila = fila + 2
DISPLAY val_rep_trab1 USING "--,---,--&.##" AT fila, 01
LET fila = fila + 1
DISPLAY val_rep_carg1 USING "--,---,--&.##" AT fila, 18

LET fila = fila + 2
SELECT * INTO puntos_trab1, puntos_carg1 FROM t4
DISPLAY 'puntos_trab      puntos_carg' AT fila, 01
LET fila = fila + 2
DISPLAY puntos_trab1 USING "####&" AT fila, 07
LET fila = fila + 1
DISPLAY puntos_carg1 USING "####&" AT fila, 24

SELECT (val_rep_trab / puntos_trab) fact_ut_trab,
	(val_rep_carg / puntos_carg) fact_ut_carg
	FROM t3, t4
	INTO TEMP tmp_fact

LET fila = fila + 2
SELECT ROUND((val_rep_trab / puntos_trab) * 365, 2) val_ut_trab,
	ROUND((val_rep_carg / puntos_carg) * 365, 2) val_ut_carg
	INTO val_ut_trab1, val_ut_carg1
	FROM t3, t4
DISPLAY 'val_ut_trab      val_ut_carg' AT fila, 01
LET fila = fila + 2
DISPLAY val_ut_trab1 USING "-,---,--&.##" AT fila, 01
LET fila = fila + 1
DISPLAY val_ut_carg1 USING "-,---,--&.##" AT fila, 17

DROP TABLE t3

DROP TABLE t4

DECLARE q_emp CURSOR FOR
	SELECT LPAD(localidad, 2, 0) loc, LPAD(cod_trab, 3, 0) cod,
		nombres empleado, ROUND(fact_ut_trab * dias_trab, 2) val_ut,
		ROUND(NVL(fact_ut_carg * dias_trab * num_cargas, 0), 2) val_c,
		ROUND((fact_ut_trab * dias_trab) + NVL(fact_ut_carg *
			dias_trab * num_cargas, 0), 2) tot_ut
		FROM te_trab, tmp_fact
		ORDER BY 1, 3
LET fila = fila + 2
DISPLAY 'loc cod empleado                                  val_ut       val_c',
	'      tot_ut' AT fila, 01
LET fila = fila + 2
FOREACH q_emp INTO r_emp.*
	DISPLAY r_emp.loc         USING "&&"		AT fila, 02
	DISPLAY r_emp.cod         USING "##&"		AT fila, 05
	DISPLAY r_emp.empleado    			AT fila, 09
	DISPLAY r_emp.val_ut      USING "---,--&.##"	AT fila, 47
	DISPLAY r_emp.val_c       USING "---,--&.##"	AT fila, 59
	DISPLAY r_emp.tot_ut      USING "---,--&.##"	AT fila, 71
	LET fila = fila + 1
END FOREACH
LET fila = fila + 2

DECLARE q_tot CURSOR FOR
	SELECT LPAD(localidad, 2, 0), ROUND(SUM(fact_ut_trab * dias_trab), 2),
		ROUND(SUM(NVL(fact_ut_carg * dias_trab * num_cargas,0)),2),
		ROUND(SUM((fact_ut_trab * dias_trab) + NVL(fact_ut_carg
			* dias_trab * num_cargas, 0)), 2)
		FROM te_trab, tmp_fact
		GROUP BY 1
		ORDER BY 1
LET fila = fila + 2
DISPLAY 'loc     val_rep_trab     val_rep_carg        partic_15' AT fila, 01
LET fila = fila + 2
FOREACH q_tot INTO r_tot.*
	DISPLAY r_tot.loc          USING "&&"		AT fila, 02
	DISPLAY r_tot.val_rep_trab USING "-,---,--&.##"	AT fila, 09
	DISPLAY r_tot.val_rep_carg USING "-,---,--&.##"	AT fila, 26
	DISPLAY r_tot.partic_15    USING "-,---,--&.##"	AT fila, 43
	LET fila = fila + 1
END FOREACH

DROP TABLE te_trab

DROP TABLE tmp_fact

END FUNCTION

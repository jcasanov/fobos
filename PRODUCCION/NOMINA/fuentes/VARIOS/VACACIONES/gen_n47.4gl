DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE vm_proceso	LIKE rolt039.n39_proceso



MAIN

	IF num_args() <> 2 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. Faltan: base de datos y ',
			'compañía.'
		EXIT PROGRAM
	END IF
	CALL activar_base_datos(arg_val(1))
	LET codcia     = arg_val(2)
	LET vm_proceso = 'VA'
	CALL generar_rolt047_partiendo_rolt033()
	DISPLAY 'Proceso Ejecutado OK.'

END MAIN



FUNCTION activar_base_datos(base)
DEFINE base		CHAR(20)
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_loc		RECORD LIKE gent002.*

CLOSE DATABASE 
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base CLIPPED
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
SELECT * FROM gent051 WHERE g51_basedatos = base
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se pudo abrir base de datos: ', base CLIPPED
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION generar_rolt047_partiendo_rolt033()
DEFINE r_emp		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				nombre		LIKE rolt030.n30_nombres,
				liq		LIKE rolt033.n33_cod_liqrol,
				fec_ini		LIKE rolt033.n33_fecha_ini,
				fec_fin		LIKE rolt033.n33_fecha_fin,
				valor		LIKE rolt033.n33_valor,
				per_ini		LIKE rolt039.n39_periodo_ini,
				per_fin		LIKE rolt039.n39_periodo_fin
			END RECORD
DEFINE i		SMALLINT

DISPLAY 'Obteniendo empleado para genear dias gozados de vacaciones en rolt047.'
DISPLAY '  Por favor espere ...'
DISPLAY ' '
IF NOT generar_tabla_temporal() THEN
	DISPLAY 'No hay ningun empleado para generar en rolt047.'
	DISPLAY ' '
	RETURN
END IF
DISPLAY 'Procesando los Empleados... '
DECLARE q_emp CURSOR WITH HOLD FOR
	SELECT * FROM tmp_emp ORDER BY nom ASC, fec_fin ASC
DISPLAY ' '
BEGIN WORK
LET i = 0
FOREACH q_emp INTO r_emp.*
	DISPLAY 'Procesando vacaciones del Empleado: '
	DISPLAY '   ', r_emp.cod_trab USING "<<&&", ' ', r_emp.nombre CLIPPED,
		' Liq.: ', r_emp.liq, ' ', r_emp.fec_ini USING "dd-mm-yyyy",' ',
		r_emp.fec_fin USING "dd-mm-yyyy", ' ', r_emp.valor USING "<<<&&"
if r_emp.cod_trab = 25 then
	--exit foreach
end if
	CALL generar_rolt047(r_emp.*)
	LET i = i + 1
END FOREACH
COMMIT WORK
DISPLAY 'Se procesaron ', i USING "<<<&&", ' registros de vacaciones. OK '
DISPLAY ' '

END FUNCTION



FUNCTION generar_tabla_temporal()
DEFINE r_reg		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				nombre		LIKE rolt030.n30_nombres,
				liq		LIKE rolt033.n33_cod_liqrol,
				fec_ini		LIKE rolt033.n33_fecha_ini,
				fec_fin		LIKE rolt033.n33_fecha_fin,
				valor		LIKE rolt033.n33_valor
			END RECORD
DEFINE r_t5		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				nombre		LIKE rolt030.n30_nombres,
				tot_dias	SMALLINT,
				dias_v		SMALLINT,
				per_ini		LIKE rolt039.n39_periodo_ini,
				per_fin		LIKE rolt039.n39_periodo_fin
			END RECORD
DEFINE c_au		LIKE rolt033.n33_cod_trab
DEFINE query		CHAR(1200)
DEFINE cuantos		INTEGER
DEFINE val_a, tope_dia	SMALLINT
DEFINE val_t, c		SMALLINT

SELECT MIN(UNIQUE n39_perfin_real) fecha_ini
	FROM rolt039
	WHERE n39_compania     = codcia
	  AND n39_proceso      = vm_proceso
	  AND n39_perfin_real <= MDY(12,31,2004)
	INTO TEMP caca
SELECT MDY(MONTH(fecha_ini), 01, YEAR(fecha_ini)) fecha_ini
	FROM caca
	INTO TEMP tmp_fec
DROP TABLE caca
SELECT n33_cod_trab cod, n30_nombres nom, n33_cod_liqrol lq, n33_fecha_ini
	fec_ini, n33_fecha_fin fec_fin, n33_valor valor
	FROM rolt033, rolt030
	WHERE n33_compania    = codcia
	  AND n33_cod_liqrol IN('Q1', 'Q2')
	  AND n33_fecha_ini  >= (SELECT fecha_ini FROM tmp_fec)
	  AND n33_fecha_fin  BETWEEN MDY(01, 01, 2003) AND MDY(02, 28, 2007)
	  AND n33_cod_rubro   = 11
	  AND n33_valor       > 0
	  AND n30_compania    = n33_compania
	  AND n30_cod_trab    = n33_cod_trab
	  AND n30_estado      = 'A'
	  AND not exists      (SELECT * FROM rolt047
				WHERE n47_compania   = n30_compania
				  AND n47_proceso    = vm_proceso
				  AND n47_cod_trab   = n30_cod_trab
				  AND n47_fecha_ini >= n33_fecha_ini
				  AND n47_fecha_fin <= n33_fecha_fin)
	INTO TEMP t1
DROP TABLE tmp_fec
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	DROP TABLE t1
	RETURN 0
END IF
SELECT cod, nom, NVL(SUM(valor), 0) tot_d_va FROM t1 GROUP BY 1, 2 INTO TEMP t2
LET query = 'SELECT n39_cod_trab cod_t, n39_periodo_ini per_ini, ',
		'n39_periodo_fin per_fin, NVL(SUM((n39_dias_vac +',
		'CASE WHEN n39_gozar_adic = "S" THEN n39_dias_adi else 0 END))',
		',0) dias_v ',
		' FROM rolt039 ',
		' WHERE n39_compania = ', codcia,
		'   AND n39_proceso  = "', vm_proceso, '"',
		'   AND n39_estado   = "P" ',
		'   AND n39_tipo     = "G" ',
		'   AND not exists (SELECT * FROM rolt047 ',
				' WHERE n47_compania    = n39_compania ',
				'   AND n47_proceso     = n39_proceso ',
				'   AND n47_cod_trab    = n39_cod_trab ',
				'   AND n47_periodo_ini = n39_periodo_ini ',
				'   AND n47_periodo_fin = n39_periodo_fin) ',
		' GROUP BY 1, 2, 3 ',
		' INTO TEMP t3 '
PREPARE exec_t3 FROM query
EXECUTE exec_t3
SELECT cod, nom, tot_d_va, NVL(SUM(dias_v), 0) dias_v
	FROM t2, t3
	WHERE cod = cod_t
	GROUP BY 1, 2, 3
	INTO TEMP t4
DROP TABLE t2
SELECT t4.*, t3.per_ini, t3.per_fin
	FROM t4, t3
	WHERE t4.tot_d_va <= t4.dias_v
	  AND t4.cod       = t3.cod_t
	INTO TEMP t5
DROP TABLE t4
SELECT t1.*, t5.per_ini, t5.per_fin
	FROM t1, t5
	WHERE t1.cod     = 999
	  AND t1.cod     = t5.cod
	  AND t1.fec_fin > t5.per_fin
	INTO TEMP tmp_emp
DELETE FROM t1 WHERE NOT EXISTS (SELECT t5.* FROM t5 WHERE t5.cod = t1.cod)
DECLARE q_t5 CURSOR FOR SELECT * FROM t5 ORDER BY nom ASC, per_fin ASC
OPEN q_t5
FETCH q_t5 INTO r_t5.*
LET c_au = r_t5.cod_trab
DECLARE q_ins CURSOR FOR SELECT * FROM t1 ORDER BY nom ASC, fec_fin ASC
LET val_a = 0
let c = 0
FOREACH q_ins INTO r_reg.*
	IF c_au <> r_reg.cod_trab THEN
		LET val_a = 0
		WHILE TRUE
			FETCH q_t5 INTO r_t5.*
			IF c_au <> r_t5.cod_trab THEN
				LET c_au = r_t5.cod_trab
				EXIT WHILE
			END IF
		END WHILE
	END IF
	SELECT t3.dias_v INTO tope_dia
		FROM t3
		WHERE t3.cod_t   = r_t5.cod_trab
		  AND t3.per_ini = r_t5.per_ini
		  AND t3.per_fin = r_t5.per_fin
	IF val_a > tope_dia THEN
		FETCH q_t5 INTO r_t5.*
		LET val_a = 0
	ELSE
		LET val_t = 0
		SELECT NVL(SUM(valor), 0) INTO val_t
			FROM tmp_emp
			WHERE cod     = r_reg.cod_trab
			  AND per_ini = r_t5.per_ini
			  AND per_fin = r_t5.per_fin
		LET val_t = val_t + r_reg.valor
		LET val_a = val_a + r_reg.valor
		IF val_t > tope_dia THEN
			FETCH q_t5 INTO r_t5.*
			LET val_a = 0
if r_reg.cod_trab = 105 then
--display r_reg.*, ' ', r_t5.per_ini, ' ', r_t5.per_fin, ' ', val_a, ' ', tope_dia
let c = c + 1
end if
			INSERT INTO tmp_emp
				VALUES(r_reg.*, r_t5.per_ini, r_t5.per_fin)
			CONTINUE FOREACH
		END IF
	END IF
if r_reg.cod_trab = 105 then
--display r_reg.*, ' ', r_t5.per_ini, ' ', r_t5.per_fin, ' ', val_a, ' ', tope_dia
let c = c + 1
end if
	INSERT INTO tmp_emp VALUES(r_reg.*, r_t5.per_ini, r_t5.per_fin)
	LET c_au = r_reg.cod_trab
if c = 5 then
--exit program
end if
END FOREACH
CLOSE q_t5
FREE q_t5
DROP TABLE t1
DROP TABLE t3
DROP TABLE t5
RETURN 1

END FUNCTION



FUNCTION generar_rolt047(r_emp)
DEFINE r_emp		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				nombre		LIKE rolt030.n30_nombres,
				liq		LIKE rolt033.n33_cod_liqrol,
				fec_ini		LIKE rolt033.n33_fecha_ini,
				fec_fin		LIKE rolt033.n33_fecha_fin,
				valor		LIKE rolt033.n33_valor,
				per_ini		LIKE rolt039.n39_periodo_ini,
				per_fin		LIKE rolt039.n39_periodo_fin
			END RECORD
DEFINE r_n47		RECORD LIKE rolt047.*
DEFINE fecha		DATE
DEFINE d_rea		SMALLINT

INITIALIZE r_n47.* TO NULL
LET d_rea = r_emp.valor
LET fecha = r_emp.fec_fin - r_emp.valor UNITS DAY
IF MONTH(fecha) = 2 AND DAY(fecha) >= 13 AND DAY(fecha) < 15 THEN
	LET fecha = MDY(MONTH(fecha), 15, YEAR(fecha))
	IF r_emp.valor > 13 THEN
		LET d_rea = 13
	END IF
END IF
LET r_n47.n47_compania    = codcia
LET r_n47.n47_proceso     = vm_proceso
LET r_n47.n47_cod_trab    = r_emp.cod_trab
LET r_n47.n47_periodo_ini = r_emp.per_ini
LET r_n47.n47_periodo_fin = r_emp.per_fin
SELECT NVL(MAX(n47_secuencia) + 1, 1)
	INTO r_n47.n47_secuencia
	FROM rolt047
	WHERE n47_compania    = codcia
	  AND n47_proceso     = vm_proceso
	  AND n47_cod_trab    = r_emp.cod_trab
	  AND n47_periodo_ini = r_emp.per_ini
	  AND n47_periodo_fin = r_emp.per_fin
LET r_n47.n47_fecini_vac  = fecha
LET r_n47.n47_fecfin_vac  = r_emp.fec_fin
LET r_n47.n47_estado      = "G"
LET r_n47.n47_max_dias    = r_emp.valor
LET r_n47.n47_dias_real   = d_rea
LET r_n47.n47_dias_goza   = r_emp.valor
LET r_n47.n47_cod_liqrol  = r_emp.liq
LET r_n47.n47_fecha_ini   = r_emp.fec_ini
LET r_n47.n47_fecha_fin   = r_emp.fec_fin
LET r_n47.n47_usuario     = "FOBOS"
LET r_n47.n47_fecing      = CURRENT
WHENEVER ERROR CONTINUE
INSERT INTO rolt047 VALUES(r_n47.*)
IF STATUS = -691 THEN
	WHENEVER ERROR STOP
	DISPLAY '  No se insertó: ', r_emp.cod_trab USING "<<&&", ' ',
		r_emp.nombre CLIPPED, ' Liq.: ', r_emp.liq, ' ',
		r_emp.fec_ini USING "dd-mm-yyyy",' ',
		r_emp.fec_fin USING "dd-mm-yyyy", ' ', r_emp.valor USING "<<<&&"
	RETURN
END IF
WHENEVER ERROR STOP
UPDATE rolt039
	SET n39_dias_goza = n39_dias_goza + r_emp.valor
	WHERE n39_compania    = r_n47.n47_compania
	  AND n39_proceso     = r_n47.n47_proceso
	  AND n39_cod_trab    = r_n47.n47_cod_trab
	  AND n39_periodo_ini = r_n47.n47_periodo_ini
	  AND n39_periodo_fin = r_n47.n47_periodo_fin

END FUNCTION

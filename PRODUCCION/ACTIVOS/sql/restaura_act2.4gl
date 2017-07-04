DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE base, base1	CHAR(20)
DEFINE baseser		CHAR(40)



MAIN

	IF num_args() <> 2 THEN
		DISPLAY 'No. Parametros Incorrectos. Faltan BASE_D SERVER_D'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	CALL reprocesar_diario_contable_activos_baja()
	DISPLAY 'Proceso Terminado OK.'

END MAIN



FUNCTION reprocesar_diario_contable_activos_baja()
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE resul, i		INTEGER

CALL alzar_base_ser(arg_val(1), arg_val(2))
SET ISOLATION TO DIRTY READ
DISPLAY 'Obteniendo diarios contables activos fijos en baja ...'
DECLARE q_diarios CURSOR WITH HOLD FOR
	SELECT * FROM actt012
		WHERE a12_compania     = codcia
		  AND a12_codigo_tran  = 'BA'
		  AND YEAR(a12_fecing) = 2008
		ORDER BY a12_tipcomp_gen, a12_numcomp_gen
DISPLAY ' '
DISPLAY 'Reprocesando diarios contables activos fijos en baja ...'
LET i = 0
FOREACH q_diarios INTO r_a12.*
	CALL regenerar_contabilizacion(r_a12.*) RETURNING resul
	IF NOT resul THEN
		EXIT FOREACH
	END IF
	LET i = i + 1
END FOREACH
DISPLAY 'Se Reprocesaron ', i USING "<<<<&", ' diarios contables  OK.'
DISPLAY ' '

END FUNCTION



FUNCTION alzar_base_ser(b, s)
DEFINE b, s		CHAR(20)

LET base  = b
LET base1 = base CLIPPED
LET base  = base CLIPPED, '@', s
CALL activar_base()

END FUNCTION



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



FUNCTION regenerar_contabilizacion(r_a12)
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE secuencia	LIKE ctbt013.b13_secuencia

DISPLAY '  Regenerando diario: ', r_a12.a12_tipcomp_gen, '-',
	r_a12.a12_numcomp_gen, '  Activo Fijo: ',
	r_a12.a12_codigo_bien USING "<<<<<<&"
INITIALIZE r_a01.*, r_a10.* TO NULL
SELECT * INTO r_a10.*
	FROM actt010
	WHERE a10_compania    = r_a12.a12_compania
	  AND a10_codigo_bien = r_a12.a12_codigo_bien
SELECT * INTO r_a01.*
	FROM actt001
	WHERE a01_compania  = r_a10.a10_compania
	  AND a01_grupo_act = r_a10.a10_grupo_act
CALL fl_mayoriza_comprobante(r_a10.a10_compania, r_a12.a12_tipcomp_gen,
				r_a12.a12_numcomp_gen, 'D')
BEGIN WORK
SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
DECLARE q_upd2 CURSOR FOR 
	SELECT * FROM ctbt012
		WHERE b12_compania  = r_a12.a12_compania
		  AND b12_tipo_comp = r_a12.a12_tipcomp_gen
		  AND b12_num_comp  = r_a12.a12_numcomp_gen
	FOR UPDATE
OPEN q_upd2
FETCH q_upd2
IF STATUS < 0 THEN
	ROLLBACK WORK
	DISPLAY '    ERROR: No se puede regenerar el diario: ',
		r_a12.a12_tipcomp_gen, '-', r_a12.a12_numcomp_gen
	WHENEVER ERROR STOP
	CALL fl_mayoriza_comprobante(r_a10.a10_compania, r_a12.a12_tipcomp_gen,
					r_a12.a12_numcomp_gen, 'M')
	RETURN 0
END IF  
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
SELECT * FROM ctbt013
	WHERE b13_compania   = r_a12.a12_compania
	  AND b13_tipo_comp  = r_a12.a12_tipcomp_gen
	  AND b13_num_comp   = r_a12.a12_numcomp_gen
	  AND b13_cuenta    IN (r_a01.a01_aux_activo, r_a01.a01_aux_dep_act)
	INTO TEMP tmp_b13
DELETE FROM ctbt013
	WHERE b13_compania  = r_a12.a12_compania
	  AND b13_tipo_comp = r_a12.a12_tipcomp_gen
	  AND b13_num_comp  = r_a12.a12_numcomp_gen
DECLARE q_b13 CURSOR FOR SELECT * FROM tmp_b13 ORDER BY b13_valor_base DESC
LET secuencia = 1
FOREACH q_b13 INTO r_b13.*
	IF r_b13.b13_valor_base < 0 THEN
		LET r_b13.b13_valor_base = r_a10.a10_tot_dep_mb * (-1)
	ELSE
		LET r_b13.b13_valor_base = r_a10.a10_tot_dep_mb
	END IF
	UPDATE tmp_b13
		SET b13_valor_base = r_b13.b13_valor_base,
		    b13_secuencia  = secuencia
		WHERE b13_compania  = r_b13.b13_compania
		  AND b13_tipo_comp = r_b13.b13_tipo_comp
		  AND b13_num_comp  = r_b13.b13_num_comp
		  AND b13_secuencia = r_b13.b13_secuencia
	LET secuencia = secuencia + 1
END FOREACH
INSERT INTO ctbt013 SELECT * FROM tmp_b13
DROP TABLE tmp_b13
COMMIT WORK
CALL fl_mayoriza_comprobante(r_a10.a10_compania, r_a12.a12_tipcomp_gen,
				r_a12.a12_numcomp_gen, 'M')
RETURN 1

END FUNCTION

DATABASE aceros


DEFINE db1		CHAR(20)
DEFINE serv1		CHAR(20)
DEFINE codcia1		LIKE gent001.g01_compania
DEFINE codloc1		LIKE gent002.g02_localidad



MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. '
		DISPLAY 'SON: BASE1 SERVIDOR_BASE1 COMPAÑIA LOCALIDAD'
		EXIT PROGRAM
	END IF
	LET db1     = arg_val(1)
	LET serv1   = arg_val(2)
	LET codcia1 = arg_val(3)
	LET codloc1 = arg_val(4)
	CALL activar_base(db1, serv1)
	CALL validar_parametros(codcia1, codloc1)
	CALL reproceso_activos_fijos()
	DISPLAY 'Reproceso Transacciones de Activos Fijos Terminado OK.'

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base, ' en la tabla gent051.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros(codcia, codloc)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g01.*, r_g02.* TO NULL
SELECT * INTO r_g01.*
	FROM gent001
	WHERE g01_compania = codcia
IF r_g01.g01_compania IS NULL THEN
	DISPLAY 'No existe la compania ', codcia USING "<<<&", ' en la base.'
	EXIT PROGRAM
END IF
SELECT * INTO r_g02.*
	FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la localidad ', codloc USING "<<<&", ' en la base.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION reproceso_activos_fijos()

SET ISOLATION TO DIRTY READ
DISPLAY 'Iniciando reproceso transaccional de Activos Fijos. Espere por favor..'
DISPLAY ' '
BEGIN WORK
	CALL generar_trans_ingreso()
	CALL generar_trans_depreciacion()
	CALL regenerar_secuencias()
COMMIT WORK

END FUNCTION



FUNCTION generar_trans_ingreso()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE i		SMALLINT

DISPLAY '  Generando TRANS. DE INGRESO...'
DECLARE q_a10 CURSOR FOR
	SELECT * FROM actt010
		WHERE a10_compania  = codcia1
		  AND a10_estado   IN ('V', 'D', 'S', 'E')
		  AND NOT EXISTS
			(SELECT 1 FROM actt012
				WHERE a12_compania    = a10_compania
				  AND a12_codigo_tran IN ('IN', 'TR')
				  AND a12_codigo_bien = a10_codigo_bien)
		ORDER BY a10_fecha_comp, a10_codigo_bien
DISPLAY ' '
LET i = 0
FOREACH q_a10 INTO r_a10.*
	INITIALIZE r_a12.* TO NULL
	LET r_a12.a12_compania 	  = r_a10.a10_compania
	LET r_a12.a12_codigo_tran = 'IN'
	LET r_a12.a12_numero_tran =
			fl_retorna_num_tran_activo(r_a10.a10_compania,
							r_a12.a12_codigo_tran)
	IF r_a12.a12_numero_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_a12.a12_codigo_bien = r_a10.a10_codigo_bien
	LET r_a12.a12_referencia  = 'MIGRACION: ',r_a10.a10_descripcion CLIPPED,
					'. POR REPROCESO'
	LET r_a12.a12_locali_ori  = r_a10.a10_localidad
	LET r_a12.a12_depto_ori   = r_a10.a10_cod_depto
	LET r_a12.a12_porc_deprec = r_a10.a10_porc_deprec
	LET r_a12.a12_valor_mb 	  = r_a10.a10_valor_mb
	LET r_a12.a12_valor_ma 	  = 0
	LET r_a12.a12_usuario 	  = 'FOBOS'
	LET r_a12.a12_fecing 	  = EXTEND(r_a10.a10_fecha_comp, YEAR TO SECOND)
	INSERT INTO actt012 VALUES (r_a12.*)
	DISPLAY '    Codigo Act.: ', r_a10.a10_codigo_bien USING "<<&&&", ' ',
		r_a12.a12_codigo_tran, '-', r_a12.a12_numero_tran USING "####&"
	LET i = i + 1
END FOREACH
DISPLAY ' '
DISPLAY '  Se generaron ', i USING "<<<&", ' TRANS. DE INGRESO. OK'
DISPLAY ' '

END FUNCTION



FUNCTION generar_trans_depreciacion()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE tot_dep_acu	LIKE actt010.a10_tot_dep_mb
DEFINE i		SMALLINT

DISPLAY '  Generando TRANS. DE DEPRECIACION...'
SELECT * FROM actt010
	WHERE a10_compania    = codcia1
	  AND a10_estado     IN ('V', 'D', 'E')
	  AND (SELECT NVL(SUM(a12_valor_mb), 0)
		FROM actt012
		WHERE a12_compania    = a10_compania
		  AND a12_codigo_bien = a10_codigo_bien) <> 0
UNION
SELECT * FROM actt010
	WHERE a10_compania    = codcia1
	  AND a10_estado     IN ('V', 'D', 'S')
	  AND a10_tot_dep_mb  > (SELECT NVL(SUM(a12_valor_mb), 0) * (-1)
				FROM actt012
				WHERE a12_compania    = a10_compania
				  AND a12_codigo_tran = 'DP'
				  AND a12_codigo_bien = a10_codigo_bien)
	INTO TEMP tmp_a10
DECLARE q_a10_2 CURSOR FOR
	SELECT * FROM tmp_a10
		ORDER BY a10_fecha_comp, a10_codigo_bien
DISPLAY ' '
LET i = 0
FOREACH q_a10_2 INTO r_a10.*
	IF codloc1 = 1 THEN
		IF r_a10.a10_codigo_bien = 17 OR r_a10.a10_codigo_bien = 128
		THEN
			CONTINUE FOREACH
		END IF
	END IF
	IF codloc1 = 3 THEN
		IF r_a10.a10_codigo_bien = 295 OR r_a10.a10_codigo_bien = 360
		THEN
			CONTINUE FOREACH
		END IF
	END IF
	INITIALIZE r_a12.* TO NULL
	LET r_a12.a12_compania 	  = r_a10.a10_compania
	LET r_a12.a12_codigo_tran = 'DP'
	LET r_a12.a12_numero_tran =
			fl_retorna_num_tran_activo(r_a10.a10_compania,
							r_a12.a12_codigo_tran)
	IF r_a12.a12_numero_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	LET r_a12.a12_codigo_bien = r_a10.a10_codigo_bien
	LET r_a12.a12_referencia  = 'MIGRACION: DEPRECIACION MENSUAL ACUMULADA',
					'. POR REPROCESO'
	LET r_a12.a12_locali_ori  = r_a10.a10_localidad
	LET r_a12.a12_depto_ori	  = r_a10.a10_cod_depto
	LET r_a12.a12_porc_deprec = r_a10.a10_porc_deprec
	SELECT NVL(SUM(a12_valor_mb), 0)
		INTO tot_dep_acu
		FROM actt012
		WHERE a12_compania    = r_a10.a10_compania
		  AND a12_codigo_tran = r_a12.a12_codigo_tran
		  AND a12_codigo_bien = r_a10.a10_codigo_bien
	LET r_a12.a12_valor_mb	  = (r_a10.a10_tot_dep_mb + tot_dep_acu) * (-1)
	LET r_a12.a12_valor_ma	  = 0
	LET r_a12.a12_usuario 	  = 'FOBOS'
	DECLARE q_fec CURSOR FOR
		SELECT MDY(MONTH(a12_fecing), 01, YEAR(a12_fecing))
			- 1 UNITS DAY
			FROM actt012
			WHERE a12_compania    = r_a10.a10_compania
			  AND a12_codigo_tran = r_a12.a12_codigo_tran
			  AND a12_codigo_bien = r_a10.a10_codigo_bien
			ORDER BY a12_fecing
	OPEN q_fec
	FETCH q_fec INTO r_a12.a12_fecing
	CLOSE q_fec
	FREE q_fec
	IF r_a12.a12_fecing IS NULL THEN
		LET r_a12.a12_fecing = MDY(01, 01, YEAR(r_a10.a10_fecha_comp)
					+ 1) - 1 UNITS DAY
	END IF
	LET r_a12.a12_fecing 	  = r_a12.a12_fecing + 1 UNITS HOUR
	IF r_a12.a12_valor_mb = 0 THEN
		CONTINUE FOREACH
	END IF
	INSERT INTO actt012 VALUES (r_a12.*)
	DISPLAY '    Codigo Act.: ', r_a10.a10_codigo_bien USING "<<&&&", ' ',
		r_a12.a12_codigo_tran, '-', r_a12.a12_numero_tran USING "####&"
	LET i = i + 1
END FOREACH
DROP TABLE tmp_a10
DISPLAY ' '
DISPLAY '  Se generaron ', i USING "<<<&", ' TRANS. DE DEPRECIACION. OK'
DISPLAY ' '

END FUNCTION



FUNCTION regenerar_secuencias()
DEFINE r_a05		RECORD LIKE actt005.*
DEFINE numero		LIKE actt005.a05_numero
DEFINE i		SMALLINT

DISPLAY '  Regenerando SECUENCIAS TRANSACCIONES...'
DISPLAY ' '
DECLARE q_a05 CURSOR FOR
	SELECT * FROM actt005
		WHERE a05_compania = codcia1
		ORDER BY a05_codigo_tran
LET i = 0
FOREACH q_a05 INTO r_a05.*
	LET numero = r_a05.a05_numero
	CALL regenerar_secuencia_trans(r_a05.*) RETURNING r_a05.a05_numero
	UPDATE actt005
		SET a05_numero = r_a05.a05_numero
		WHERE a05_compania    = r_a05.a05_compania
		  AND a05_codigo_tran = r_a05.a05_codigo_tran
		  AND a05_numero      = numero
	DISPLAY '    Codigo Tra.:     ', r_a05.a05_codigo_tran, '-',
		r_a05.a05_numero USING "<<##&"
	LET i = i + 1
	DISPLAY ' '
END FOREACH
DISPLAY '  Se regeneraron ', i USING "<<<&", ' SECUENCIAS TRANSACCIONES. OK'
DISPLAY ' '

END FUNCTION



FUNCTION regenerar_secuencia_trans(r_a05)
DEFINE r_a05		RECORD LIKE actt005.*
DEFINE r_a12		RECORD LIKE actt012.*
DEFINE grupo		LIKE actt010.a10_grupo_act
DEFINE tipo		LIKE actt010.a10_tipo_act
DEFINE cuantos		INTEGER

CREATE TEMP TABLE tmp_a12
	(
		compania		INTEGER,
		codigo_tran		CHAR(2),
		numero_tran		SERIAL,
		codigo_bien		INTEGER,
		referencia		VARCHAR(100,40),
		locali_ori		SMALLINT,
		depto_ori		SMALLINT,
		locali_dest		SMALLINT,
		depto_dest		SMALLINT,
		porc_deprec		SMALLINT,
		porc_reval		SMALLINT,
		valor_mb		DECIMAL(12,2),
		valor_ma		DECIMAL(12,2),
		tipcomp_gen		CHAR(2),
		numcomp_gen		CHAR(8),
		usuario			VARCHAR(10,5),
		fecing			DATETIME YEAR TO SECOND,
		numero_ant		INTEGER
	)
SELECT * FROM actt015
	WHERE a15_compania = 999
	INTO TEMP tmp_a15
DISPLAY '    Generando  Secuencia Trans.: ', r_a05.a05_codigo_tran
SELECT a12_compania, a12_codigo_tran, a12_numero_tran, a12_codigo_bien,
	a12_referencia, a12_locali_ori, a12_depto_ori, a12_locali_dest,
	a12_depto_dest, a12_porc_deprec, a12_porc_reval, a12_valor_mb,
	a12_valor_ma, a12_tipcomp_gen, a12_numcomp_gen, a12_usuario,
	a12_fecing, a10_grupo_act, a10_tipo_act
	FROM actt012, actt010
	WHERE a12_compania    = r_a05.a05_compania
	  AND a12_codigo_tran = r_a05.a05_codigo_tran
	  AND a10_compania    = a12_compania
	  AND a10_codigo_bien = a12_codigo_bien
	ORDER BY a12_fecing, a10_grupo_act, a10_tipo_act, a12_codigo_bien
	INTO TEMP t1
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	DISPLAY '    No se Genero Secuencia Tra.: ', r_a05.a05_codigo_tran
	DROP TABLE t1
	DROP TABLE tmp_a12
	DROP TABLE tmp_a15
	RETURN 0
END IF
INSERT INTO tmp_a12
	SELECT a12_compania, a12_codigo_tran, 0, a12_codigo_bien,
		a12_referencia, a12_locali_ori, a12_depto_ori, a12_locali_dest,
		a12_depto_dest, a12_porc_deprec, a12_porc_reval, a12_valor_mb,
		a12_valor_ma, a12_tipcomp_gen, a12_numcomp_gen, a12_usuario,
		a12_fecing, a12_numero_tran
	FROM t1
DROP TABLE t1
INSERT INTO tmp_a15
	SELECT a15_compania, a15_codigo_tran, numero_tran,a15_tipo_comp,
		a15_num_comp, a15_usuario, a15_fecing
		FROM actt015, tmp_a12
		WHERE a15_compania    = compania
		  AND a15_codigo_tran = codigo_tran
		  AND a15_numero_tran = numero_ant
{--
DECLARE q_a12 CURSOR FOR
	SELECT actt012.*, a10_grupo_act, a10_tipo_act
		FROM actt012, actt010
		WHERE a12_compania    = r_a05.a05_compania
		  AND a12_codigo_tran = r_a05.a05_codigo_tran
		  AND a10_compania    = a12_compania
		  AND a10_codigo_bien = a12_codigo_bien
		ORDER BY a12_fecing, a10_grupo_act, a10_tipo_act,
			a12_codigo_bien
DISPLAY '    Generando  Secuencia Trans.: ', r_a05.a05_codigo_tran
FOREACH q_a12 INTO r_a12.*, grupo, tipo
	INSERT INTO tmp_a12
		VALUES (r_a12.a12_compania, r_a05.a05_codigo_tran, 0,
			r_a12.a12_codigo_bien, r_a12.a12_referencia,
			r_a12.a12_locali_ori, r_a12.a12_depto_ori,
			r_a12.a12_locali_dest, r_a12.a12_depto_dest,
			r_a12.a12_porc_deprec, r_a12.a12_porc_reval,
			r_a12.a12_valor_mb, r_a12.a12_valor_ma,
			r_a12.a12_tipcomp_gen, r_a12.a12_numcomp_gen,
			r_a12.a12_usuario, r_a12.a12_fecing,
			r_a12.a12_numero_tran)
	INSERT INTO tmp_a15
		SELECT a15_compania, a15_codigo_tran, numero_tran,a15_tipo_comp,
			a15_num_comp, a15_usuario, a15_fecing
			FROM actt015, tmp_a12
			WHERE compania        = r_a12.a12_compania
			  AND codigo_tran     = r_a12.a12_codigo_tran
			  AND numero_ant      = r_a12.a12_numero_tran
			  AND a15_compania    = compania
			  AND a15_codigo_tran = codigo_tran
			  AND a15_numero_tran = numero_ant
END FOREACH
--}
DISPLAY '    Borrando   Secuencia Trans.: ', r_a05.a05_codigo_tran, ' Anterior'
DELETE FROM actt015
	WHERE a15_compania    = r_a05.a05_compania
	  AND a15_codigo_tran = r_a05.a05_codigo_tran
DELETE FROM actt012
	WHERE a12_compania    = r_a05.a05_compania
	  AND a12_codigo_tran = r_a05.a05_codigo_tran
DISPLAY '    Insertando Secuencia Trans.: ', r_a05.a05_codigo_tran, ' Nueva'
INSERT INTO actt012
	SELECT compania, codigo_tran, numero_tran, codigo_bien, referencia,
		locali_ori, depto_ori, locali_dest, depto_dest, porc_deprec,
		porc_reval, valor_mb, valor_ma, tipcomp_gen, numcomp_gen,
		usuario, fecing
		FROM tmp_a12
INSERT INTO actt015
	SELECT * FROM tmp_a15
DROP TABLE tmp_a12
DROP TABLE tmp_a15
SELECT NVL(MAX(a12_numero_tran), 0)
	INTO r_a05.a05_numero
	FROM actt012
	WHERE a12_compania    = r_a05.a05_compania
	  AND a12_codigo_tran = r_a05.a05_codigo_tran
RETURN r_a05.a05_numero

END FUNCTION



FUNCTION fl_retorna_num_tran_activo(codcia, codigo_tran) 
DEFINE codcia 		LIKE actt005.a05_compania
DEFINE codigo_tran	LIKE actt005.a05_codigo_tran
DEFINE numero		LIKE actt005.a05_numero
DEFINE mensaje		VARCHAR(60)

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 5
DECLARE up_tact CURSOR FOR
	SELECT a05_numero FROM actt005
		WHERE a05_compania    = codcia
		  AND a05_codigo_tran = codigo_tran
	FOR UPDATE
OPEN up_tact
FETCH up_tact INTO numero
IF STATUS = NOTFOUND THEN
	LET mensaje = 'No existe control secuencia en actt005: ',
		       codcia USING '<&', ' transaccion: ', codigo_tran
	DISPLAY mensaje
	LET numero = 0
ELSE
	IF STATUS < 0 THEN
		DISPLAY 'Secuencia esta bloqueada por otro proceso'
		LET numero = -1
	ELSE
		LET numero = numero + 1
		UPDATE actt005 SET a05_numero = numero
			WHERE CURRENT OF up_tact
		IF STATUS < 0 THEN
			DISPLAY 'No se actualiza control secuencia'
			LET numero = -1
		END IF
	END IF
END IF
WHENEVER ERROR STOP
SET LOCK MODE TO NOT WAIT
RETURN numero

END FUNCTION

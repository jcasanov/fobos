DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad



MAIN
	
	IF num_args() <> 4 THEN
		DISPLAY 'ERROR DE PARAMETROS. FALTAN: base servidor_base ',
			'compañía localidad.'
		EXIT PROGRAM
	END IF
	CALL activar_base(arg_val(1), arg_val(2))
	LET codcia = arg_val(3)
	LET codloc = arg_val(4)
	CALL validar_parametros()
	IF NOT respalda_datos() THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		DISPLAY 'Respaldo no pudo realizarse.'
	ELSE
		WHENEVER ERROR STOP
		COMMIT WORK
		DISPLAY 'Respaldo Terminado OK.'
	END IF

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



FUNCTION validar_parametros()
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g01.*, r_g02.* TO NULL
SELECT * INTO r_g01.*
	FROM gent001
	WHERE g01_compania = codcia
IF r_g01.g01_compania IS NULL THEN
	DISPLAY 'No existe la compañía ', codcia USING "<<<&", ' en la base.'
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



FUNCTION respalda_datos()
DEFINE cuantos, i	INTEGER
DEFINE items		LIKE rept010.r10_codigo

SET ISOLATION TO DIRTY READ
DISPLAY 'Obteniendo items involucrados en TR de intercambio. Favor espere ...'
{--
SELECT UNIQUE r20_item item_tr
	FROM rept019, rept002, rept020
	WHERE r19_compania    = codcia
	  AND r19_localidad   = codloc
	  AND r19_cod_tran    = 'TR'
	  AND YEAR(r19_fecing) >= 2009
	  AND ((r02_compania  = r19_compania
	  AND  r02_codigo     = r19_bodega_ori
	  AND  r02_localidad <> r19_localidad)
	   OR (r02_compania   = r19_compania
	  AND  r02_codigo     = r19_bodega_dest
	  AND  r02_localidad <> r19_localidad))
	  AND r20_compania    = r19_compania
	  AND r20_localidad   = r19_localidad
	  AND r20_cod_tran    = r19_cod_tran
	  AND r20_num_tran    = r19_num_tran
	INTO TEMP tmp_ite
--}
SELECT UNIQUE r20_item item_tr
	FROM rept020
	WHERE r20_compania      = codcia
	  AND r20_localidad     = codloc
	  AND YEAR(r20_fecing) >= 2009
	INTO TEMP tmp_ite
DECLARE q_item_tr CURSOR FOR SELECT * FROM tmp_ite
DISPLAY '  Los Item: '
LET i = 0
FOREACH q_item_tr INTO items
	DISPLAY '    ', items CLIPPED
	LET i = i + 1
END FOREACH
DISPLAY '  Total de items involucrados ', i USING "<<<<<&", '.'
DISPLAY ' '
{--
SELECT r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num_t
	FROM rept019
	WHERE r19_compania      = codcia
	  AND r19_localidad     = codloc
	  AND YEAR(r19_fecing) >= 2009
	  AND EXISTS (SELECT 1 FROM rept020
			WHERE r20_compania  = r19_compania
			  AND r20_localidad = r19_localidad
			  AND r20_cod_tran  = r19_cod_tran
			  AND r20_num_tran  = r19_num_tran
			  AND r20_item      = (SELECT item_tr
						FROM tmp_ite
						WHERE item_tr = r20_item))
	INTO TEMP tmp_trans
--}
BEGIN WORK
WHENEVER ERROR CONTINUE
DISPLAY 'Inicia proceso de Respaldo. Por favor espere ...'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos
	FROM rept019_res
	WHERE r19_compania  = codcia
	  AND r19_localidad = codloc
IF cuantos > 0 THEN
	DISPLAY 'No se puede respaldar tabla rept019. ',
		'Ya tiene datos la tabla rept019_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY 'Respaldando tabla rept019. Por favor espere ...'
INSERT INTO rept019_res
	(r19_compania, r19_localidad, r19_cod_tran, r19_num_tran, r19_tot_costo,
	 r19_tot_neto, r19_comito, r19_usuario, r19_fecing)
	SELECT a.r19_compania, a.r19_localidad, a.r19_cod_tran, a.r19_num_tran,
		a.r19_tot_costo, a.r19_tot_neto, 'N', "FOBOS", CURRENT
		FROM rept019 a
		WHERE a.r19_compania      = codcia
		  AND a.r19_localidad     = codloc
		  AND YEAR(a.r19_fecing) >= 2009
		  AND EXISTS (SELECT 1 FROM rept020
				WHERE r20_compania  = a.r19_compania
				  AND r20_localidad = a.r19_localidad
				  AND r20_cod_tran  = a.r19_cod_tran
				  AND r20_num_tran  = a.r19_num_tran
				  AND r20_item      =
					(SELECT item_tr
						FROM tmp_ite
						WHERE item_tr = r20_item))
		{--
		WHERE a.r19_compania  = codcia
		  AND a.r19_localidad = codloc
		  AND YEAR(a.r19_fecing) >= 2009
		  AND EXISTS (SELECT * FROM tmp_trans
				WHERE cia   = a.r19_compania
				  AND loc   = a.r19_localidad
				  AND tp    = a.r19_cod_tran
				  AND num_t = a.r19_num_tran)
		  AND a.r19_fecing  >= (SELECT MIN(b.r19_fecing)
					FROM rept019 b, rept002
					WHERE b.r19_compania   = a.r19_compania
					  AND b.r19_localidad  = a.r19_localidad
					  AND b.r19_cod_tran   = 'TR'
					  AND YEAR(b.r19_fecing) >= 2009
					  AND r02_compania     = b.r19_compania
					  AND r02_codigo     = b.r19_bodega_dest
					  AND r02_localidad  <> b.r19_localidad)
		--}
IF STATUS < 0 THEN
	DISPLAY 'Ha ocurrido un error al insertar los registros en rept019_res.'
	DISPLAY ' '
	RETURN 0
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se han podido insertar los registros en rept019_res.'
	DISPLAY ' '
	RETURN 0
END IF
--DROP TABLE tmp_trans
DISPLAY '  Respaldada tabla rept019. OK'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos
	FROM rept020_res
	WHERE r20_compania  = codcia
	  AND r20_localidad = codloc
IF cuantos > 0 THEN
	DISPLAY 'No se puede respaldar tabla rept020. ',
		'Ya tiene datos la tabla rept020_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY 'Respaldando tabla rept020. Por favor espere ...'
INSERT INTO rept020_res
	(r20_compania, r20_localidad, r20_cod_tran, r20_num_tran, r20_bodega,
	 r20_item, r20_orden, r20_costo, r20_costant_mb, r20_costant_ma,
	 r20_costnue_mb, r20_costnue_ma, r20_comito, r20_fecing)
	SELECT a.r20_compania, a.r20_localidad, a.r20_cod_tran, a.r20_num_tran,
		a.r20_bodega, a.r20_item, a.r20_orden, a.r20_costo,
		a.r20_costant_mb, a.r20_costant_ma, a.r20_costnue_mb,
		a.r20_costnue_ma, 'N', CURRENT
		FROM rept019_res, rept020 a
		WHERE r19_compania    = codcia
		  AND r19_localidad   = codloc
		  AND a.r20_compania  = r19_compania
		  AND a.r20_localidad = r19_localidad
		  AND a.r20_cod_tran  = r19_cod_tran
		  AND a.r20_num_tran  = r19_num_tran
IF STATUS < 0 THEN
	DISPLAY 'Ha ocurrido un error al insertar los registros en rept020_res.'
	DISPLAY ' '
	RETURN 0
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se han podido insertar los registros en rept020_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY '  Respaldada tabla rept020. OK'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos
	FROM rept010_res
	WHERE r10_compania = codcia
IF cuantos > 0 THEN
	DISPLAY 'No se puede respaldar tabla rept010. ',
		'Ya tiene datos la tabla rept010_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY 'Respaldando tabla rept010. Por favor espere ...'
SELECT UNIQUE r20_compania cia, r20_item item FROM rept020_res INTO TEMP t1
INSERT INTO rept010_res
	(r10_compania, r10_codigo, r10_costo_mb, r10_costo_ma, r10_costult_mb,
	 r10_costult_ma, r10_comito, r10_usuario, r10_fecing)
	SELECT a.r10_compania, a.r10_codigo, a.r10_costo_mb, a.r10_costo_ma,
		a.r10_costult_mb, a.r10_costult_ma, 'N', "FOBOS", CURRENT
		FROM rept010 a, t1
		WHERE a.r10_compania = cia
		  AND a.r10_codigo   = item
		  AND EXISTS (SELECT * FROM tmp_ite
				WHERE item_tr = a.r10_codigo)
IF STATUS < 0 THEN
	DISPLAY 'Ha ocurrido un error al insertar los registros en rept010_res.'
	DISPLAY ' '
	RETURN 0
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se han podido insertar los registros en rept010_res.'
	DISPLAY ' '
	RETURN 0
END IF
DROP TABLE t1
DROP TABLE tmp_ite
DISPLAY '  Respaldada tabla rept010. OK'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos
	FROM ctbt013_res
	WHERE b13_compania = codcia
IF cuantos > 0 THEN
	DISPLAY 'No se puede respaldar tabla ctbt013. ',
		'Ya tiene datos la tabla ctbt013_res.'
	DISPLAY ' '
	RETURN 0
END IF
DISPLAY 'Respaldando tabla ctbt013. Por favor espere ...'
{--
SELECT UNIQUE b13_compania cia, b13_tipo_comp tp, b13_num_comp num,
	b13_secuencia secu, b13_cuenta cuenta, b13_valor_base valor
	FROM rept019_res, rept040, ctbt013
	WHERE r19_compania  = codcia
	  AND r19_localidad = codloc
	  AND r19_cod_tran  = 'TR'
	  AND r40_compania  = r19_compania
	  AND r40_localidad = r19_localidad
	  AND r40_cod_tran  = r19_cod_tran
	  AND r40_num_tran  = r19_num_tran
	  AND b13_compania  = r40_compania
	  AND b13_tipo_comp = r40_tipo_comp
	  AND b13_num_comp  = r40_num_comp
	INTO TEMP t1
SELECT rept040.*
	FROM rept019_res, rept040
	WHERE r19_compania  = codcia
	  AND r19_localidad = codloc
	  AND r19_cod_tran  IN ('FA', 'DF')
	  AND r40_compania  = r19_compania
	  AND r40_localidad = r19_localidad
	  AND r40_cod_tran  = r19_cod_tran
	  AND r40_num_tran  = r19_num_tran
	INTO TEMP tmp_r40
SELECT UNIQUE b12_compania, b12_tipo_comp, b12_num_comp
	FROM tmp_r40, ctbt012
	WHERE b12_compania  = r40_compania
	  AND b12_tipo_comp = r40_tipo_comp
	  AND b12_num_comp  = r40_num_comp
	  AND b12_subtipo   = 27
	INTO TEMP tmp_b12
DROP TABLE tmp_r40
INSERT INTO t1
	SELECT UNIQUE b13_compania cia, b13_tipo_comp tp, b13_num_comp num,
		b13_secuencia secu, b13_cuenta cuenta, b13_valor_base valor
		FROM tmp_b12, ctbt013
		WHERE b13_compania  = b12_compania
		  AND b13_tipo_comp = b12_tipo_comp
		  AND b13_num_comp  = b12_num_comp
DROP TABLE tmp_b12
--}
INSERT INTO ctbt013_res
	(b13_compania, b13_tipo_comp, b13_num_comp, b13_secuencia, b13_cuenta,
	 b13_valor_base, b13_comito, b13_usuario, b13_fecing)
	--SELECT cia, tp, num, secu, cuenta, valor, 'N', "FOBOS", CURRENT FROM t1
	SELECT UNIQUE b13_compania cia, b13_tipo_comp tp, b13_num_comp num,
		b13_secuencia secu, b13_cuenta cuenta, b13_valor_base valor,
		'N', "FOBOS", CURRENT
		FROM rept019_res, rept040, ctbt013, ctbt012
		WHERE r19_compania   = codcia
		  AND r19_localidad  = codloc
		  AND r40_compania   = r19_compania
		  AND r40_localidad  = r19_localidad
		  AND r40_cod_tran   = r19_cod_tran
		  AND r40_num_tran   = r19_num_tran
		  AND b13_compania   = r40_compania
		  AND b13_tipo_comp  = r40_tipo_comp
		  AND b13_num_comp   = r40_num_comp
		  AND b12_compania   = b13_compania
		  AND b12_tipo_comp  = b13_tipo_comp
		  AND b12_num_comp   = b13_num_comp
		  AND b12_estado    <> 'E'
		  AND b12_subtipo   IN (25, 27, 53)
IF STATUS < 0 THEN
	DISPLAY 'Ha ocurrido un error al insertar los registros en ctbt013_res.'
	DISPLAY ' '
	RETURN 0
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se han podido insertar los registros en ctbt013_res.'
	DISPLAY ' '
	RETURN 0
END IF
DROP TABLE t1
DISPLAY '  Respaldada tabla ctbt013. OK'
DISPLAY ' '
RETURN 1

END FUNCTION

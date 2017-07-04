SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                    CREANDO PARTIDAS DE QUITO EN GUAYAQUIL                  --
--------------------------------------------------------------------------------

SELECT g16_partida FROM acero_qm@idsuio01:gent016 INTO TEMP t1;
SELECT g16_partida FROM acero_gm@idsgye01:gent016 INTO TEMP t2;

SELECT a.*, b.g16_partida partida
	FROM t1 a, OUTER t2 b
	WHERE a.g16_partida = b.g16_partida
	INTO TEMP t3;

DELETE FROM t3
	WHERE partida IS NOT NULL;

SELECT COUNT(*) tot_par_uio
	FROM t3;

SELECT b.* FROM acero_qm@idsuio01:gent016 b, t3 a
	WHERE b.g16_partida = a.g16_partida
	INTO TEMP t4;

DROP TABLE t3;

SELECT g16_partida par_uio, g16_fecing fec_uio
	FROM t4
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:gent016
		SELECT g16_capitulo, g16_partida, g16_desc_par, g16_niv_par,
			g16_nacional, g16_verifcador, g16_porcentaje,
			g16_salvagu, 'FOBOS', CURRENT
			FROM t4;

COMMIT WORK;

DROP TABLE t4;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                    CREANDO PARTIDAS DE GUAYAQUIL EN QUITO                  --
--------------------------------------------------------------------------------

SELECT a.*, b.g16_partida partida
	FROM t2 a, OUTER t1 b
	WHERE b.g16_partida = a.g16_partida
	INTO TEMP t3;

DELETE FROM t3
	WHERE partida IS NOT NULL;

SELECT COUNT(*) tot_par_gye
	FROM t3;

SELECT b.* FROM acero_gm@idsgye01:gent016 b, t3 a
	WHERE b.g16_partida = a.g16_partida
	INTO TEMP t4;

DROP TABLE t3;

SELECT g16_partida par_gye, g16_fecing fec_gye
	FROM t4
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:gent016
		SELECT g16_capitulo, g16_partida, g16_desc_par, g16_niv_par,
			g16_nacional, g16_verifcador, g16_porcentaje,
			g16_salvagu, 'FOBOS', CURRENT
			FROM t4;

COMMIT WORK;

DROP TABLE t1;
DROP TABLE t2;
DROP TABLE t4;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

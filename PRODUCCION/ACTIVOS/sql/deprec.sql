SELECT UNIQUE a12_compania cia, a12_codigo_bien cod_bien
	FROM actt012
	WHERE a12_compania      = 1
	  AND a12_codigo_tran  IN ('BA', 'VE')
	  AND DATE(a12_fecing)  < "04/30/1987"
	INTO TEMP tmp_baj;

SELECT * FROM actt010
	WHERE a10_compania     = 1
	  AND a10_grupo_act    = 2
	  AND a10_estado      IN ("N", "R", "E", "S", "V", "D")
	  AND a10_codigo_bien NOT IN (SELECT cod_bien FROM tmp_baj)
	INTO TEMP tmp_a10;

DROP TABLE tmp_baj;

--select a10_codigo_bien act_a10 from tmp_a10;

SELECT a.* FROM actt012 a
	WHERE a.a12_compania      = 1
	  AND a.a12_codigo_tran  NOT IN ("EG", "BA", "VE", "AA", "AD", "RV")
	  AND a.a12_codigo_bien  IN
		(SELECT a10_codigo_bien
			FROM tmp_a10
			WHERE a10_compania = a.a12_compania)
	  AND DATE(a.a12_fecing) <= TODAY
	  AND a.a12_valor_mb      < 0
	  AND EXISTS (SELECT UNIQUE b.a12_codigo_tran
				FROM actt012 b
				WHERE b.a12_compania    = a.a12_compania
				  AND b.a12_codigo_tran = "DP"
				  AND b.a12_codigo_bien = a.a12_codigo_bien)
UNION
SELECT a.* FROM actt012 a
	WHERE a.a12_compania      = 1
	  AND a.a12_codigo_tran  <> "EG"
	  AND a.a12_codigo_bien  IN
		(SELECT a10_codigo_bien
			FROM tmp_a10
			WHERE a10_compania  = a.a12_compania
			  AND a10_grupo_act = 1)
	  AND DATE(a.a12_fecing) <= TODAY
	  AND a.a12_valor_mb      < 0
	INTO TEMP tmp_a12;

--select unique a12_codigo_bien act_a12 from tmp_a12 where a12_codigo_bien = 2;
--select a12_codigo_tran, a12_valor_mb from tmp_a12 where a12_codigo_bien = 17;
--select a12_codigo_tran, a12_valor_mb from tmp_a12 where a12_codigo_bien = 5;
select a12_codigo_tran, a12_valor_mb from tmp_a12 where a12_codigo_bien = 159;

SELECT a10_compania, a10_localidad, a10_grupo_act, a10_tipo_act,
	a10_codigo_bien, a10_estado, a10_valor_mb,
	NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_ant, a10_tot_dep_mb
	FROM tmp_a10, tmp_a12
	WHERE a12_compania     = a10_compania
	  AND a12_codigo_bien  = a10_codigo_bien
	  AND DATE(a12_fecing) < "04/30/1987"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 9
UNION
SELECT a10_compania, a10_localidad, a10_grupo_act, a10_tipo_act,
	a10_codigo_bien, a10_estado, a10_valor_mb, 0.00 tot_dep_ant,
	a10_tot_dep_mb
	FROM tmp_a10, tmp_a12
	WHERE a12_compania     = a10_compania
	  AND a12_codigo_bien  = a10_codigo_bien
	  AND EXTEND(a12_fecing, YEAR TO MONTH) <=
		EXTEND(DATE(TODAY), YEAR TO MONTH)
	INTO TEMP tt;

--select unique a10_codigo_bien act_tt from tt;
--select * from tt where a10_codigo_bien = 145;
--select * from tt where a10_codigo_bien = 5;
select * from tt where a10_codigo_bien = 159;

SELECT a10_compania, a10_localidad, a10_grupo_act, a10_tipo_act,
        a10_codigo_bien, a10_estado, a10_valor_mb,
        NVL(SUM(tot_dep_ant), 0) tot_dep_ant, a10_tot_dep_mb
        FROM tt
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 9
        INTO TEMP t1;
DROP TABLE tt;

--select unique a10_codigo_bien act_t1 from t1;
--select * from t1 where a10_codigo_bien = 145;
--select * from t1 where a10_codigo_bien = 5;
select * from t1 where a10_codigo_bien = 159;

SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien, a10_estado,
	a10_valor_mb, tot_dep_ant, NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_act,
	a10_tot_dep_mb
	FROM t1, tmp_a12
	WHERE a12_compania     = a10_compania
	  AND a12_codigo_bien  = a10_codigo_bien
	  AND DATE(a12_fecing) BETWEEN "04/30/1987" AND TODAY
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 9
UNION
SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien, a10_estado,
	a10_valor_mb, tot_dep_ant, 0.00 tot_dep_act, a10_tot_dep_mb
	FROM t1, tmp_a12
	WHERE a10_estado      IN ("N", "E", "V", "D")
	  AND a12_compania     = a10_compania
	  AND a12_codigo_bien  = a10_codigo_bien
	  AND DATE(a12_fecing) < "04/30/1987"
	INTO TEMP t2;

--select * from t2 where a10_codigo_bien = 17;

DROP TABLE tmp_a12;
DROP TABLE t1;
SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien, a10_estado,
        a10_valor_mb, NVL((tot_dep_ant), 0) tot_dep_ant,
        NVL(SUM(tot_dep_act), 0) tot_dep_act, a10_tot_dep_mb
        FROM t2
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 9
	UNION
	SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien,
		a10_estado, a10_valor_mb, 0.00 tot_dep_ant, 0.00 tot_dep_act,
		a10_tot_dep_mb
		FROM tmp_a10
		WHERE a10_grupo_act = 1
		  AND NOT EXISTS
			(SELECT 1 FROM t2
				WHERE t2.a10_codigo_bien =
					tmp_a10.a10_codigo_bien)
        INTO TEMP t3;
DROP TABLE tmp_a10;
DROP TABLE t2;

SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien, a10_estado,
	a10_valor_mb, NVL(SUM(tot_dep_ant), 0) tot_dep_ant,
	NVL(SUM(tot_dep_act), 0) tot_dep_act
	FROM t3
	GROUP BY 1, 2, 3, 4, 5, 6
	INTO TEMP t2;
DROP TABLE t3;
SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_codigo_bien, a10_estado,
	a10_valor_mb, tot_dep_ant, tot_dep_act,
	(tot_dep_ant + tot_dep_act) a10_tot_dep_mb
	FROM t2
	INTO TEMP tmp_mov;
DROP TABLE t2;
--select * from tmp_mov where a10_codigo_bien = 17;
--select * from tmp_mov where a10_codigo_bien = 5;
select * from tmp_mov where a10_codigo_bien = 159;
drop table tmp_mov;

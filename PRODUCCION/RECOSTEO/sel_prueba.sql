--OP TABLE t1;
--OP TABLE t2;
drop table tmp_r20;
SELECT * FROM rept020 WHERE r20_compania = 999 INTO TEMP t1;
CREATE TEMP TABLE t2
        (
                item            INTEGER
        );
SELECT t1.*, item
        FROM t1, t2
        WHERE r20_item = item
        INTO TEMP tmp_r20;
DROP TABLE t1;
DROP TABLE t2;
INSERT INTO tmp_r20
        SELECT rept020.*, item
                FROM ite_cos_rea, rept020
                WHERE compania         = 1
                  AND localidad        = 1
                  AND r20_compania     = compania
                  AND r20_localidad    = localidad
                  AND r20_item         = item
                  AND DATE(r20_fecing) BETWEEN MDY(01, 01, 2009)
                                           AND MDY(11, 06, 2009);
SELECT item, r20_fecing, r20_cod_tran, r20_num_tran
--select *
	FROM tmp_r20
                ORDER BY item, r20_fecing, r20_num_tran;
drop table tmp_r20;

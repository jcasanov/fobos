
SELECT
        1 mes, b11_cuenta, b11_db_mes_01 db, b11_cr_mes_01 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        2 mes, b11_cuenta, b11_db_mes_02 db, b11_cr_mes_02 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        3 mes, b11_cuenta, b11_db_mes_03 db, b11_cr_mes_03 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        4 mes, b11_cuenta, b11_db_mes_04 db, b11_cr_mes_04 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        5 mes, b11_cuenta, b11_db_mes_05 db, b11_cr_mes_05 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        6 mes, b11_cuenta, b11_db_mes_06 db, b11_cr_mes_06 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        7 mes, b11_cuenta, b11_db_mes_07 db, b11_cr_mes_07 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        8 mes, b11_cuenta, b11_db_mes_08 db, b11_cr_mes_08 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        9 mes, b11_cuenta, b11_db_mes_09 db, b11_cr_mes_09 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        10 mes, b11_cuenta, b11_db_mes_10 db, b11_cr_mes_10 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        11 mes, b11_cuenta, b11_db_mes_11 db, b11_cr_mes_11 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
UNION
SELECT
        12 mes, b11_cuenta, b11_db_mes_12 db, b11_cr_mes_12 cr FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "1*"
INTO TEMP t1;


--set explain on;
select
	month(b13_fec_proceso) mes,
        b13_cuenta,
        sum(CASE WHEN b13_valor_base > 0 THEN
                b13_valor_base
        END) db,
        sum(CASE WHEN b13_valor_base < 0 THEN
                abs(b13_valor_base)
        END) cr

from ctbt012, ctbt013
where
        b12_compania            = 1
        and b12_compania        = b13_compania
        and b12_tipo_comp       = b13_tipo_comp
        and b12_num_comp        = b13_num_comp
        and b12_estado          <> "E"
        and b13_cuenta          matches "1*"
        and year(b13_fec_proceso) = 2009
--	and month(b13_fec_proceso) <= 6
GROUP BY 1,2
ORDER BY 1
INTO TEMP t2;
SELECT 
	t1.mes, 
	(t1.db - t2.db) dif_db,
	(t1.cr - t2.cr) dif_cr
FROM t1, t2
WHERE 
	t1.mes 		  = t2.mes
	AND t1.b11_cuenta = t2.b13_cuenta
INTO TEMP t3;
SELECT * FROM t3 WHERE dif_db <> 0 OR dif_cr <> 0;
DROP TABLE t1;
DROP TABLE t2;
DROP TABLE t3;
--set explain off;

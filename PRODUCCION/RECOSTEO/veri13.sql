
SELECT
        1, b11_cuenta, b11_db_mes_01, b11_cr_mes_01 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        2, b11_cuenta, b11_db_mes_02, b11_cr_mes_02 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        3, b11_cuenta, b11_db_mes_03, b11_cr_mes_03 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        4, b11_cuenta, b11_db_mes_04, b11_cr_mes_04 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        5, b11_cuenta, b11_db_mes_05, b11_cr_mes_05 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        6, b11_cuenta, b11_db_mes_06, b11_cr_mes_06 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        7, b11_cuenta, b11_db_mes_07, b11_cr_mes_07 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        8, b11_cuenta, b11_db_mes_08, b11_cr_mes_08 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        9, b11_cuenta, b11_db_mes_09, b11_cr_mes_09 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        10, b11_cuenta, b11_db_mes_10, b11_cr_mes_10 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        11, b11_cuenta, b11_db_mes_11, b11_cr_mes_11 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"
UNION
SELECT
        12, b11_cuenta, b11_db_mes_12, b11_cr_mes_12 FROM ctbt011
WHERE
        b11_compania    = 1
        and b11_ano     = "2009"
        and b11_cuenta matches "11400101001"

;
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
        and b13_cuenta          = "11400101001"
        and year(b13_fec_proceso) = 2009
--	and month(b13_fec_proceso) <= 6
GROUP BY 1,2
ORDER BY 1;
--set explain off;

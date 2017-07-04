SELECT * FROM actt010
        WHERE a10_compania  = 1
          AND a10_estado   IN ('V', 'D', 'S')
          AND NOT EXISTS
                (SELECT 1 FROM actt012
                        WHERE a12_compania    = a10_compania
                          AND a12_codigo_tran = 'IN'
                          AND a12_codigo_bien = a10_codigo_bien)
{
UNION
SELECT * FROM actt010
        WHERE a10_compania  = 1
          AND a10_estado   IN ('V', 'D', 'S')
          AND NOT EXISTS
                (SELECT 1 FROM actt012
                        WHERE a12_compania    = a10_compania
                          AND a12_codigo_bien = a10_codigo_bien)
UNION
SELECT * FROM actt010
        WHERE a10_compania  = 1
          AND a10_estado   IN ('D')
          AND a10_valor_mb <>
		(SELECT SUM(a12_valor_mb) * (-1)
                 FROM actt012
                 WHERE a12_compania    = a10_compania
                   AND a12_codigo_tran = 'DP'
                   AND a12_codigo_bien = a10_codigo_bien)
}
        INTO TEMP tmp_a10;
select a10_codigo_bien from tmp_a10 order by 1;
drop table tmp_a10;

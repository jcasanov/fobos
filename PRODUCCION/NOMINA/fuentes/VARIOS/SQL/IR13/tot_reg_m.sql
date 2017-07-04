SELECT n32_mes_proceso, COUNT(UNIQUE n32_cod_trab)
        FROM rolt032
        WHERE n32_compania     = 1
          AND n32_cod_liqrol  IN ("Q1", "Q2")
          AND n32_ano_proceso  = 2013
          AND n32_mes_proceso <> 4
        GROUP BY 1
UNION
SELECT 04, COUNT(UNIQUE n42_cod_trab)
        FROM rolt042
        WHERE n42_compania = 1
          AND n42_ano      = 2012
        GROUP BY 1
        ORDER BY 1;
SELECT n15_base_imp_ini
        FROM rolt015
        WHERE n15_compania   = 1
          AND n15_ano       IN
                (SELECT NVL(MAX(n15_ano), YEAR(TODAY)) FROM rolt015)
          AND n15_secuencia IN
                (SELECT NVL(MIN(n15_secuencia), 0) + 1 FROM rolt015);
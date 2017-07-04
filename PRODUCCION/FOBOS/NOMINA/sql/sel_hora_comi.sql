SELECT NVL(SUM(n33_valor), 0) valor
        FROM rolt033
        WHERE n33_compania    = 1
          AND n33_cod_liqrol IN ('Q1', 'Q2')
          AND n33_fecha_ini  >= MDY(07,01,2004)
          AND n33_fecha_fin  <= MDY(12,31,2004)
          AND n33_cod_rubro  IN (2, 8, 10, 13, 17)

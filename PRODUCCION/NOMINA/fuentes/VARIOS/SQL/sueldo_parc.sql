--SELECT NVL(SUM(n33_valor), 0) sueldo_parc
SELECT n33_cod_rubro, n33_valor
        FROM rolt032, rolt033
        WHERE n32_compania    = 1
          AND n32_cod_liqrol IN ("Q1", "Q2")
          AND n32_fecha_ini  >= mdy(08,01,2008)
          AND n32_fecha_fin  <= mdy(08,31,2008)
          AND n32_cod_trab    = 377
          AND n32_estado     <> "E"
          AND n33_compania    = n32_compania
          AND n33_cod_liqrol  = n32_cod_liqrol
          AND n33_fecha_ini   = n32_fecha_ini
          AND n33_fecha_fin   = n32_fecha_fin
          AND n33_cod_trab    = n32_cod_trab
          AND n33_cod_rubro  IN (SELECT n08_rubro_base
                                FROM rolt008
                                WHERE n08_cod_rubro  =
                                        (SELECT n06_cod_rubro
                                        FROM rolt006
                                        WHERE n06_flag_ident = "AP")
                                  AND n08_rubro_base IN
                                        (SELECT n06_cod_rubro
                                        FROM rolt006
                                        WHERE n06_flag_ident IN ("VT", "VE",
                                                        "VM", "VV", "SX")))
          AND n33_valor       > 0;

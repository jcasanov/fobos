SELECT n30_cod_trab AS cod_trab,
        n30_nombres AS empleados,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END AS estado
        FROM acero_gm@idsgye01:rolt030
        WHERE n30_compania             = 1
          AND n30_estado               = 'A'
          AND ((YEAR(n30_fecha_ing)   <= 2013
          AND   n30_fecha_sal         IS NULL)
           OR  (YEAR(n30_fecha_reing) <= 2013
          AND   n30_fecha_sal         IS NOT NULL))
          AND n30_tipo_contr           = 'F'
          AND n30_fec_jub             IS NULL
UNION
SELECT n30_cod_trab AS cod_trab,
        n30_nombres AS empleados,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END AS estado
        FROM acero_gm@idsgye01:rolt030
        WHERE n30_compania         = 1
          AND n30_estado           = 'I'
          AND YEAR(n30_fecha_sal) >= 2013
          AND YEAR(n30_fecha_sal) <= YEAR(TODAY)
          AND n30_tipo_contr       = 'F'
          AND n30_tipo_trab        = 'N'
          AND n30_fec_jub         IS NULL
UNION
SELECT n42_cod_trab AS cod_trab,
        n30_nombres AS empleados,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END AS estado
        FROM acero_gm@idsgye01:rolt042,
                acero_gm@idsgye01:rolt030
        WHERE n42_compania = 1
          AND n42_ano      = 2012
          AND n30_compania = n42_compania
          AND n30_cod_trab = n42_cod_trab
        ORDER BY n30_nombres;
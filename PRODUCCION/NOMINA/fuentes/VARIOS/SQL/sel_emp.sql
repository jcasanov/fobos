SELECT n30_nombres AS empleados, n30_num_doc_id AS cedula,
        g35_nombre AS cargo, g34_nombre AS area,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END AS estado
        FROM rolt030, gent035, gent034
        WHERE n30_compania  = 1
	  AND n30_estado    = 'A'
          AND g35_compania  = n30_compania
          AND g35_cod_cargo = n30_cod_cargo
          AND g34_compania  = n30_compania
          AND g34_cod_depto = n30_cod_depto
        ORDER BY n30_nombres ASC;

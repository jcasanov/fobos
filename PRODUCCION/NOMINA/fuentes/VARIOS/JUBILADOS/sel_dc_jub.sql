SELECT n30_num_doc_id AS cedula, n30_nombres AS empleado,
        n36_fecha_fin AS fec_fin, n36_fecha_ing AS fec_ing,
        g35_nombre AS cargo, n30_sexo AS genero, n36_valor_bruto AS valor,
        CASE WHEN n36_tipo_pago = "T"
                THEN "A"
                ELSE "P"
        END AS tipo,
        "" AS contrato, "" AS horas
        FROM rolt036, rolt030, gent035
        WHERE n36_compania    = 1
          AND n36_proceso     = "DC"
          AND n36_ano_proceso = 2011
          AND n30_compania    = n36_compania
          AND n30_cod_trab    = n36_cod_trab
          AND g35_compania    = n30_compania
          AND g35_cod_cargo   = n30_cod_cargo
UNION
SELECT n30_num_doc_id AS cedula, n30_nombres AS empleado,
        n48_fecha_fin AS fec_fin,
        CASE WHEN n30_fec_jub IS NULL
                THEN DATE(n30_fecha_sal + 1 UNITS DAY)
                ELSE n30_fec_jub
        END AS fec_ing,
        "JUBILADO" AS cargo, n30_sexo AS genero, n48_val_jub_pat AS valor,
	"P" AS tipo, "" AS contrato, "" AS horas
        FROM rolt048, rolt030
	WHERE n48_compania    = 1
	  AND n48_proceso     = 'JU'
	  AND n48_cod_liqrol  = 'DC'
	  AND n48_ano_proceso = 2011
	  AND n30_compania    = n48_compania
	  AND n30_cod_trab    = n48_cod_trab
        ORDER BY 2;

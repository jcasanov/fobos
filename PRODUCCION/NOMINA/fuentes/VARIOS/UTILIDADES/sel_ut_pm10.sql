SELECT n30_num_doc_id AS cedula, n30_nombres AS empleados,
	n42_cta_empresa AS cta_emp,
	n42_cta_trabaj AS cta_trab,
	(n42_val_trabaj + n42_val_cargas) AS valor_ut,
	NVL((SELECT SUM(n49_valor)
		FROM rolt049
		WHERE n49_compania  = n42_compania
		  AND n49_proceso   = n42_proceso
		  AND n49_cod_trab  = n42_cod_trab
		  AND n49_fecha_ini = n42_fecha_ini
		  AND n49_fecha_fin = n42_fecha_fin
		  AND n49_num_prest IS NOT NULL), 0) AS anticipos,
	NVL((SELECT SUM(n49_valor)
		FROM rolt049
		WHERE n49_compania  = n42_compania
		  AND n49_proceso   = n42_proceso
		  AND n49_cod_trab  = n42_cod_trab
		  AND n49_fecha_ini = n42_fecha_ini
		  AND n49_fecha_fin = n42_fecha_fin
		  AND n49_cod_rubro = 57
		  AND n49_num_prest IS NULL), 0) AS trib_men,
	(n42_val_trabaj + n42_val_cargas - n42_descuentos) AS valor_neto,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END estado
        FROM rolt042, rolt030, gent035
        WHERE n42_compania  = 1
          AND n42_ano       = 2010
	  AND n42_tipo_pago = 'T'
          AND n30_compania  = n42_compania
          AND n30_cod_trab  = n42_cod_trab
          AND g35_compania  = n30_compania
          AND g35_cod_cargo = n30_cod_cargo
        ORDER BY n30_nombres ASC;

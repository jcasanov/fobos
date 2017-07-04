SELECT YEAR(b12_fec_proceso) AS anio,
	CASE WHEN MONTH(b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	b12_tipo_comp AS tipo, b12_num_comp AS numero, b13_cuenta AS cuenta,
	b10_descripcion AS nom_cta,
	TRIM(b12_glosa) || " " || TRIM(b13_glosa) AS glosa,
	SUM(CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base -
			(SELECT NVL(SUM(n47_valor_pag), 0)
				FROM rolt057, rolt047
				WHERE n57_compania    = b12_compania
				  AND n57_tipo_comp   = b12_tipo_comp
				  AND n57_num_comp    = b12_num_comp
				  AND n47_compania    = n57_compania
				  AND n47_proceso     = n57_proceso
				  AND n47_cod_trab    = n57_cod_trab
				  AND n47_periodo_ini = n57_periodo_ini
				  AND n47_periodo_fin = n57_periodo_fin
				  AND YEAR(n47_fecha_fin)=YEAR(b12_fec_proceso))
		ELSE 0.00
	END) AS debito,
	SUM(CASE WHEN b13_valor_base < 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS credito,
	CASE WHEN b12_estado = "A" THEN "ACTIVO"
	     WHEN b12_estado = "M" THEN "MAYORIZADO"
	     WHEN b12_estado = "E" THEN "ELIMINADO"
	END AS estado,
	CASE WHEN b12_origen = "A" THEN "AUTOMATICO"
	     WHEN b12_origen = "M" THEN "MANUAL"
	END AS origen
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania    IN (1, 2)
	  AND b12_estado      <> "E"
	  AND b12_tipo_comp   <> "DN"
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b10_cuenta      BETWEEN "51010100"
				  AND "51010103001"
	  AND b10_compania     = b13_compania
	  AND b10_cuenta       = b13_cuenta
	  AND b10_descripcion MATCHES "*SUE*"
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 10, 11
	ORDER BY 1, 2;

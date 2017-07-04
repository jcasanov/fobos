SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 1) AS local,
	YEAR(b12_fec_proceso) AS anio,
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
	TO_CHAR(b12_fec_proceso, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(b12_fec_proceso)), 2, 0) AS num_sem,
	b12_tipo_comp AS tip_comp,
	b12_num_comp AS num_comp,
	TRIM(b12_glosa) || " " || TRIM(b13_glosa) AS glos,
	b12_fec_proceso AS fec_pro,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	NVL((SELECT TRIM(b04_nombre)
		FROM ctbt004
		WHERE b04_compania = b12_compania
		  AND b04_subtipo  = b12_subtipo), "SIN SUBTIPO") AS subt,
	b13_cuenta AS cta,
	b10_descripcion AS nomcta,
{
	NVL(NVL((SELECT UNIQUE j02_nombre_caja
			FROM rept040, rept019, cajt010, cajt002
			WHERE r40_compania     = b12_compania
			  AND r40_tipo_comp    = b12_tipo_comp
			  AND r40_num_comp     = b12_num_comp
			  AND r19_compania     = r40_compania
			  AND r19_localidad    = r40_localidad
			  AND r19_cod_tran     = r40_cod_tran
			  AND r19_num_tran     = r40_num_tran
			  AND j10_compania     = r19_compania
			  AND j10_localidad    = r19_localidad
			  AND j10_tipo_destino = r19_cod_tran
			  AND j10_num_destino  = r19_num_tran
			  AND j02_compania     = j10_compania
			  AND j02_localidad    = j10_localidad
			  AND j02_codigo_caja  = j10_codigo_caja),
		 (SELECT UNIQUE j02_nombre_caja
			FROM talt050, talt023, cajt010, cajt002
			WHERE t50_compania     = b12_compania
			  AND t50_tipo_comp    = b12_tipo_comp
			  AND t50_num_comp     = b12_num_comp
			  AND t23_compania     = t50_compania
			  AND t23_localidad    = t50_localidad
			  AND t23_num_factura  = t50_factura
			  AND j10_compania     = t23_compania
			  AND j10_localidad    = t23_localidad
			  AND j10_tipo_fuente  = "OT"
			  AND j10_tipo_destino = "FA"
			  AND j10_num_destino  = t23_num_factura
			  AND j02_compania     = j10_compania
			  AND j02_localidad    = j10_localidad
			  AND j02_codigo_caja  = j10_codigo_caja)),
		 (SELECT UNIQUE j02_nombre_caja
			FROM cajt010, cajt002
			WHERE j10_compania     = b12_compania
			  AND j10_localidad    = 1
			  AND j10_tip_contable = b12_tipo_comp
			  AND j10_num_contable = b12_num_comp
			  AND j02_compania     = j10_compania
			  AND j02_localidad    = j10_localidad
			  AND j02_codigo_caja  = j10_codigo_caja)) AS nomcaj,
}
	CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_db,
	CASE WHEN b13_valor_base < 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_cr
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania      = 1
	  AND b12_estado        = "M"
	  AND EXISTS
		(SELECT 1 FROM rept040, rept019
			WHERE r40_compania  = b12_compania
			  AND r40_tipo_comp = b12_tipo_comp
			  AND r40_num_comp  = b12_num_comp
			  AND r40_localidad = 1
			  AND r19_compania  = r40_compania
			  AND r19_localidad = r40_localidad
			  AND r19_cod_tran  = r40_cod_tran
			  AND r19_num_tran  = r40_num_tran
			  AND r19_cont_cred = "C"
		 UNION ALL
		 SELECT 1 FROM talt050, talt023
			WHERE t50_compania    = b12_compania
			  AND t50_tipo_comp   = b12_tipo_comp
			  AND t50_num_comp    = b12_num_comp
			  AND t23_compania    = t50_compania
			  AND t23_localidad   = t50_localidad
			  AND t23_num_factura = t50_factura
			  AND t23_cont_cred   = "C"
		 UNION ALL
		 SELECT 1 FROM cajt010
			WHERE j10_compania     = b12_compania
			  AND j10_localidad    = 1
			  AND j10_tip_contable = b12_tipo_comp
			  AND j10_num_contable = b12_num_comp)
	  AND b13_compania      = b12_compania
	  AND b13_tipo_comp     = b12_tipo_comp
	  AND b13_num_comp      = b12_num_comp
	  AND b13_cuenta[1, 8] IN ("11010101", "11210107", "11300201")
	  AND b10_compania      = b13_compania
	  AND b10_cuenta        = b13_cuenta
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)

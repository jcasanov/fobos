SELECT TO_CHAR(b12_fec_proceso, "%Y-%m") AS periodo,
	b12_tipo_comp AS tc,
	b12_num_comp AS num,
	b12_fec_proceso AS fecha,
	b13_cuenta AS cuenta,
	b10_descripcion AS nom_cta,
	b13_glosa AS glosa,
	CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END AS valor_db,
	CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS valor_cr,
	CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END +
	CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS sal_cta,
	CASE WHEN b12_origen = 'A' THEN "AUTOMATICO"
	     WHEN b12_origen = 'M' THEN "MANUAL"
	END AS origen,
	NVL((SELECT b04_nombre
		FROM ctbt004
		WHERE b04_compania = b12_compania
		  AND b04_subtipo  = b12_subtipo), "SIN SUBTIPO") AS subtipo
	FROM ctbt012, ctbt013, ctbt010
	WHERE  b12_compania      = 1
	  AND  b12_estado        = 'M'
	  AND  b13_compania      = b12_compania
	  AND  b13_tipo_comp     = b12_tipo_comp
	  AND  b13_num_comp      = b12_num_comp
	  AND (b13_cuenta       IN ('11400102003', '41010102004', '41010102005',
				    '41010102006', '41010102007', '41010102008',
				    '41010102011', '41010102104', '41010102105',
				    '41010102106', '41010102107', '41010102108',
				    '41010102011', '41010102008', '41010102011',
				    '41020102002', '41020102005', '41020202002',
				    '41020202005')
	   OR  b13_cuenta[1, 8]  = '61010102')
	  AND  b10_compania      = b13_compania
	  AND  b10_cuenta        = b13_cuenta
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
UNION
SELECT TO_CHAR(b12_fec_proceso, "%Y-%m") AS periodo,
	b12_tipo_comp AS tc,
	b12_num_comp AS num,
	b12_fec_proceso AS fecha,
	b13_cuenta AS cuenta,
	b10_descripcion AS nom_cta,
	b13_glosa AS glosa,
	CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END AS valor_db,
	CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS valor_cr,
	CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END +
	CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS sal_cta,
	CASE WHEN b12_origen = 'A' THEN "AUTOMATICO"
	     WHEN b12_origen = 'M' THEN "MANUAL"
	END AS origen,
	NVL((SELECT b04_nombre
		FROM ctbt004
		WHERE b04_compania = b12_compania
		  AND b04_subtipo  = b12_subtipo), "SIN SUBTIPO") AS subtipo
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania    = 1
	  AND b12_estado      = 'M'
	  AND b12_tipo_comp   = 'DT'
	  AND b12_num_comp    = '07110009'
	  AND b13_compania    = b12_compania
	  AND b13_tipo_comp   = b12_tipo_comp
	  AND b13_num_comp    = b12_num_comp
	  AND b13_cuenta      = '41010102003'
	  AND b10_compania    = b13_compania
	  AND b10_cuenta      = b13_cuenta
	ORDER BY 4, 2, 3, 1;
{--
	INTO TEMP t1;
SELECT * FROM t1
	WHERE valor_ + valor_cr <> 0
	INTO TEMP t2;
DROP TABLE t1;
SELECT * FROM t2
	ORDER BY 3, 1, 2;
DROP TABLE t2;
--}

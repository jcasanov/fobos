SELECT n30_cod_trab AS CODIGO,
	TRIM(n30_nombres) AS EMPLEADOS,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS ESTADO,
	ROUND(((TODAY - n30_fecha_nacim) / 365), 0) AS EDAD,
	n56_aux_val_vac AS CUENTA_CTB,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 01
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_ENE,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 02
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_FEB,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 03
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_MAR,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 04
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_ABR,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 05
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_MAY,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 06
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_JUN,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 07
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_JUL,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 08
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_AGO,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 09
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_SEP,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 10
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_OCT,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 11
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_NOV,
	ROUND(NVL(SUM(CASE WHEN MONTH(b12_fec_proceso) = 12
			THEN b13_valor_base * (-1)
			ELSE 0.00
		END), 0), 2) AS VALOR_IR_RET_DIC
	FROM rolt030, OUTER(rolt056, ctbt013, ctbt012)
	WHERE  n30_compania                            = 1
	  AND (n30_estado                              = "A"
	   OR (n30_estado                              = "I"
	  AND  YEAR(n30_fecha_sal)                     BETWEEN 2012
							   AND 2013))
	  AND  n56_compania                            = n30_compania
	  AND  n56_proceso                             = "IR"
	  AND  n56_cod_depto                           = n30_cod_depto
	  AND  n56_cod_trab                            = n30_cod_trab
	  AND  b13_compania                            = n56_compania
	  AND  b13_tipo_comp                          IN ("DN", "DC")
	  AND  b13_cuenta                              = n56_aux_val_vac
	  AND  EXTEND(b13_fec_proceso, YEAR TO MONTH) >= '2013-01'
	  AND  EXTEND(b13_fec_proceso, YEAR TO MONTH) <= '2013-12'
	  AND  b13_valor_base                          < 0
	  AND  b12_compania                            = b13_compania
	  AND  b12_tipo_comp                           = b13_tipo_comp
	  AND  b12_num_comp                            = b13_num_comp
	  AND  b12_estado                             <> 'E'
	GROUP BY 1, 2, 3, 4, 5
	ORDER BY 2;
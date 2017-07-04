SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados,
	n31_tipo_carga AS tip_c,
	n31_cod_trab_e AS cod_ace,
	n31_nombres AS carga,
	n31_fecha_nacim AS fec_nacim,
	n31_secuencia AS orden,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030, OUTER rolt031
	WHERE n30_compania = 1
	  AND n30_estado   = 'A'
	  AND n31_compania = n30_compania
	  AND n31_cod_trab = n30_cod_trab
UNION
SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados,
	n31_tipo_carga AS tip_c,
	n31_cod_trab_e AS cod_ace,
	n31_nombres AS carga,
	n31_fecha_nacim AS fec_nacim,
	n31_secuencia AS orden,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030, rolt031
	WHERE n30_compania         = 1
	  AND n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal) >= 2011
	  AND n31_compania         = n30_compania
	  AND n31_cod_trab         = n30_cod_trab
	ORDER BY 2 ASC, 7 ASC;

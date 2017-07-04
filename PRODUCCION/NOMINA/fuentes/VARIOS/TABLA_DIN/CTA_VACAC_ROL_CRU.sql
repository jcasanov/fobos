SELECT n52_compania AS cia,
	n52_cod_rubro AS rub,
	n06_nombre AS nom_rub,
	n52_cod_trab AS cod_trab,
	n30_nombres AS empleados,
	n52_aux_cont,
	(SELECT b10_descripcion
		FROM ctbt010
		WHERE b10_compania = n52_compania
		  AND b10_cuenta   = n52_aux_cont) AS nom_aux_cont,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS est_emp
	FROM rolt052, rolt006, rolt030
	WHERE n52_compania    = 1
	  AND n06_cod_rubro   = n52_cod_rubro
	  AND n06_flag_ident IN ("XV", "AG", "GV")
	  AND n30_compania    = n52_compania
	  AND n30_cod_trab    = n52_cod_trab
	ORDER BY 2, 5;

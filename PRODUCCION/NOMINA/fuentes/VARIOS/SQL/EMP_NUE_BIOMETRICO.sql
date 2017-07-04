SELECT n30_cod_trab AS codigo,
	n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	n30_telef_domic AS telf1,
	n30_telef_fami AS telf2,
	n30_domicilio AS direc,
	n30_fecha_nacim AS fec_nac,
	CASE WHEN n30_est_civil = "C" THEN "CASADO"
	     WHEN n30_est_civil = "S" THEN "SOLTERO"
	     WHEN n30_est_civil = "U" THEN "UNION LIBRE"
	     WHEN n30_est_civil = "V" THEN "VIUDO"
	     WHEN n30_est_civil = "D" THEN "DIVORCIADO"
	END AS est_civ,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2014)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2014)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2014))), 0)
	AS cargas,
	n30_sueldo_mes AS remune,
	g35_nombre AS cargo
	FROM rolt030, gent035
	WHERE n30_compania  = 1
	  AND n30_estado    = "A"
	  AND g35_compania  = n30_compania
	  AND g35_cod_cargo = n30_cod_cargo
	ORDER BY 3 ASC;

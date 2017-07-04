DATABASE acero_gm



MAIN

	CALL ejecuta_proceso()

END MAIN



FUNCTION ejecuta_proceso()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n32_aux	RECORD LIKE rolt032.*
DEFINE diferencia	DECIMAL(10,2)

DECLARE q_caca CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania   = 1
		  AND n32_cod_liqrol = 'Q2'
		  AND n32_fecha_ini  = MDY(07,16,2004)
		  AND n32_fecha_fin  = MDY(07,31,2004)
		ORDER BY n32_cod_trab
FOREACH q_caca INTO r_n32.*
	INITIALIZE r_n32_aux.*, r_n30.* TO NULL
	SELECT * INTO r_n32_aux.* FROM rolt032
		WHERE n32_compania    = r_n32.n32_compania
		  AND n32_cod_liqrol  = 'Q3'
		  AND n32_fecha_ini   = MDY(08,01,2004)
		  AND n32_fecha_fin   = MDY(08,15,2004)
		  AND n32_cod_trab    = r_n32.n32_cod_trab
		  AND n32_sueldo     <> r_n32.n32_sueldo
	UNION
	SELECT * FROM rolt032
		WHERE n32_compania    = r_n32.n32_compania
		  AND n32_cod_liqrol  = 'Q2'
		  AND n32_fecha_ini   = MDY(08,16,2004)
		  AND n32_fecha_fin   = MDY(08,31,2004)
		  AND n32_cod_trab    = r_n32.n32_cod_trab
		  AND n32_sueldo     <> r_n32.n32_sueldo
	IF r_n32_aux.n32_compania IS NULL THEN
		CONTINUE FOREACH
	END IF
	LET diferencia = r_n32_aux.n32_sueldo - r_n32.n32_sueldo
	IF r_n32_aux.n32_cod_liqrol = "Q2" THEN
		LET diferencia = diferencia / 2
	END IF
	SELECT * INTO r_n30.* FROM rolt030
		WHERE n30_compania = r_n32.n32_compania
		  AND n30_cod_trab = r_n32.n32_cod_trab
	DISPLAY r_n30.n30_num_doc_id, ' ', r_n30.n30_nombres, ' ',
		r_n32_aux.n32_sueldo USING "#,##&.##", ' ',
		diferencia USING "##&.##"
END FOREACH

END FUNCTION

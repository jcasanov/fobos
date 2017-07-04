DATABASE acero_gm


DEFINE anio		SMALLINT



MAIN

	SELECT NVL(MIN(a13_ano), 2004) INTO anio
		FROM actt013
		WHERE a13_compania    = 1
		  AND a13_codigo_bien = 130
	DISPLAY 'El año es: ', anio USING "&&&&"

END MAIN

DATABASE diteca

MAIN

DEFINE contador		INTEGER 
DEFINE r_r10		RECORD LIKE rept010.*

DECLARE q_filtro CURSOR FOR
	SELECT * FROM rept010 WHERE r10_compania = 1 AND r10_filtro = '.'

LET contador = 1
FOREACH q_filtro INTO r_r10.*
	IF r_r10.r10_filtro = '.' THEN
		DISPLAY contador, ' Actualizando item ', r_r10.r10_codigo, ' con filtro ', r_r10.r10_filtro 
		LET contador = contador + 1
		UPDATE rept010 SET r10_filtro = NULL 
			WHERE r10_compania = r_r10.r10_compania
			  AND r10_codigo = r_r10.r10_codigo
	ELSE
		DISPLAY 'ESTE ITEM NO: ', r_r10.r10_filtro
	END IF

END FOREACH

END MAIN

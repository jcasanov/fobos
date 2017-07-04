DATABASE aceros


DEFINE base		CHAR(20)
DEFINE codcia		LIKE gent001.g01_compania



MAIN

	IF num_args() <> 2 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. SON: BASE COMPAÑIA.'
		EXIT PROGRAM
	END IF
	LET base   = arg_val(1)
	LET codcia = arg_val(2)
	CALL activar_base()
	CALL actualizar_referencia()
	DISPLAY 'Proceso Terminado. OK'

END MAIN



FUNCTION activar_base()

CLOSE DATABASE 
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base CLIPPED
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
SELECT * FROM gent051 WHERE g51_basedatos = base
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se pudo abrir base de datos: ', base CLIPPED
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION actualizar_referencia()
DEFINE r_p21		RECORD LIKE cxpt021.*
DEFINE referencia_nc	LIKE cxpt021.p21_referencia
DEFINE referencia	LIKE cxpt022.p22_referencia
DEFINE loc		LIKE cxpt022.p22_localidad
DEFINE codprov		LIKE cxpt022.p22_codprov
DEFINE tipo_doc		LIKE cxpt023.p23_tipo_favor
DEFINE num_doc		LIKE cxpt023.p23_doc_favor
DEFINE pos_ini, pos_fin	INTEGER
DEFINE i		INTEGER

DISPLAY 'Seleccionando Notas de Crédito de proveedor ... espere.'
DECLARE q_p22 CURSOR WITH HOLD FOR
	SELECT UNIQUE p22_referencia, p22_localidad, p22_codprov,
		p23_tipo_favor, p23_doc_favor
		FROM cxpt022, cxpt023
		WHERE p22_compania   = codcia
		  AND p22_referencia MATCHES 'DEV. COMPRA LOCAL #*'
		  AND p23_compania   = p22_compania
		  AND p23_localidad  = p22_localidad
		  AND p23_codprov    = p22_codprov
		  AND p23_tipo_trn   = p22_tipo_trn
		  AND p23_num_trn    = p22_num_trn
		ORDER BY p22_referencia
DISPLAY ' '
LET i = 0
FOREACH q_p22 INTO referencia, loc, codprov, tipo_doc, num_doc
	INITIALIZE r_p21.* TO NULL
	SELECT * INTO r_p21.* FROM cxpt021
		WHERE p21_compania  = codcia
		  AND p21_localidad = loc
		  AND p21_codprov   = codprov
		  AND p21_tipo_doc  = tipo_doc
		  AND p21_num_doc   = num_doc
	IF r_p21.p21_referencia IS NOT NULL THEN
		CONTINUE FOREACH
	END IF
	LET pos_ini       = LENGTH('DEV. COMPRA LOCAL # ') + 1
	LET pos_fin       = LENGTH(referencia)
	LET referencia_nc = 'DEVOLUCION (COMPRA LOCAL) #',
				referencia[pos_ini, pos_fin] CLIPPED
	DISPLAY 'Actualizando: ', tipo_doc, '-', num_doc USING "<<<<<<&", '  ',
		referencia_nc
	BEGIN WORK
		UPDATE cxpt021
			SET p21_referencia = referencia_nc
			WHERE p21_compania  = r_p21.p21_compania
			  AND p21_localidad = r_p21.p21_localidad
			  AND p21_codprov   = r_p21.p21_codprov
			  AND p21_tipo_doc  = r_p21.p21_tipo_doc
			  AND p21_num_doc   = r_p21.p21_num_doc
	COMMIT WORK
	LET i = i + 1
END FOREACH
DISPLAY ' '
DISPLAY 'Se actualizaron ', i USING "<<<<&", ' Notas de Crédito.'
DISPLAY ' '

END FUNCTION

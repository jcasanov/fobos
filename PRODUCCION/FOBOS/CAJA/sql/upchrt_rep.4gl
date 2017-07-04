DATABASE aceros




DEFINE base1		CHAR(20)
DEFINE codcia1		LIKE gent001.g01_compania
DEFINE codloc1		LIKE gent002.g02_localidad
DEFINE codigo_pago	LIKE cajt011.j11_codigo_pago



MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'Parametros Incorrectos. BASE@SERVIDOR COMPAÑIA ',
			'LOCALIDAD CODIGO_PAGO'
		EXIT PROGRAM
	END IF
	LET base1       = arg_val(1)
	LET codcia1     = arg_val(2)
	LET codloc1     = arg_val(3)
	LET codigo_pago = arg_val(4)
	CALL ejecuta_proceso()
	DISPLAY ' '
	DISPLAY 'Corrección Terminada OK.'

END MAIN



FUNCTION ejecuta_proceso()
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE codigo, num	LIKE cajt011.j11_num_ch_aut
DEFINE cuantos, i, j, l	INTEGER

CLOSE DATABASE
DATABASE base1
SET ISOLATION TO DIRTY READ
DISPLAY 'Descargando código de pago repetidos ', codigo_pago CLIPPED,
	'. Por favor espere ...'
SELECT j11_num_ch_aut num_ch_aut, COUNT(*) total
	FROM cajt011
	WHERE j11_compania    = codcia1
	  AND j11_localidad   = codloc1
	  AND j11_codigo_pago = codigo_pago
	GROUP BY 1
	HAVING COUNT(*) > 1
	INTO TEMP tmp_codrep
DISPLAY ' '
SELECT COUNT(*) INTO i FROM tmp_codrep
IF i = 0 THEN
	DISPLAY 'No hay ningun código repetido.'
	EXIT PROGRAM
END IF
DISPLAY 'Total de códigos a corregir ', i USING "<<<<<&", '.'
DISPLAY ' '
DISPLAY 'Detalle de códigos repetidos ...'
DECLARE q_tmp CURSOR FOR SELECT * FROM tmp_codrep
FOREACH q_tmp INTO codigo, cuantos
	DISPLAY codigo_pago, ': ', codigo CLIPPED, '  un total de: ',
		cuantos USING "<<<<&"
END FOREACH
DISPLAY ' '
DISPLAY 'Corrigiendo los códigos repetidos ...'
LET i = 0
FOREACH q_tmp INTO codigo, cuantos
	DISPLAY ' '
	DECLARE q_j11 CURSOR FOR
		SELECT * FROM cajt011
			WHERE j11_compania    = codcia1
			  AND j11_localidad   = codloc1
			  AND j11_codigo_pago = codigo_pago
			  AND j11_num_ch_aut  = codigo
			ORDER BY j11_num_fuente, j11_secuencia
	DISPLAY '  Corrigiendo ', codigo_pago, '-', codigo, ' un total de: ',
		cuantos USING "<<<<&"
	LET j = 1
	FOREACH q_j11 INTO r_j11.*, cuantos
		IF LENGTH(r_j11.j11_num_ch_aut) = 15 THEN
			LET num = NULL
			FOR l = 1 TO 15
				IF r_j11.j11_num_ch_aut[l, l] = '-' THEN
					CONTINUE FOR
				END IF
				LET num = num, r_j11.j11_num_ch_aut[l, l]
			END FOR
			LET r_j11.j11_num_ch_aut = num
		END IF
		LET r_j11.j11_num_ch_aut = r_j11.j11_num_ch_aut CLIPPED, '-',
						j USING "<&"
		DISPLAY '    Actualizando: ', r_j11.j11_num_ch_aut CLIPPED,
			' con valor de: ', r_j11.j11_valor USING "--,---,--&.##"
		UPDATE cajt011
			SET j11_num_ch_aut = r_j11.j11_num_ch_aut
			WHERE j11_compania    = r_j11.j11_compania
			  AND j11_localidad   = r_j11.j11_localidad
			  AND j11_tipo_fuente = r_j11.j11_tipo_fuente
			  AND j11_num_fuente  = r_j11.j11_num_fuente
			  AND j11_secuencia   = r_j11.j11_secuencia
		LET j = j + 1
	END FOREACH
	LET i = i + 1
END FOREACH
DISPLAY ' '
DISPLAY 'Se corrigeron un total de ', i USING "<<<<&", ' registros. OK'

END FUNCTION

DATABASE aceros



DEFINE localidad	LIKE gent002.g02_localidad
DEFINE vg_codloc	LIKE gent002.g02_localidad



MAIN

	LET localidad = arg_val(1)
	LET vg_codloc = 1
	CALL enviar_transferencia_otra_loc()

END MAIN



FUNCTION enviar_transferencia_otra_loc()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE localidad_des	LIKE gent002.g02_localidad
DEFINE opc		SMALLINT
DEFINE comando		VARCHAR(250)

CASE localidad
	WHEN 2
		LET opc = 3
	WHEN 3
		LET opc = 2
	OTHERWISE
		LET opc = NULL
END CASE
IF opc IS NULL THEN
	RETURN
END IF
ERROR 'Se esta enviando la Transferencia. Por favor espere ... '
LET comando = 'cd /acero/fobos/PRODUCCION/TRANSMISION/; fglgo transfer ',
		opc, ' X &> /acero/fobos/PRODUCCION/TRANSMISION/transfer.log '
RUN comando CLIPPED
ERROR '                                                        '
--CALL fl_lee_localidad(vg_codcia, localidad_des) RETURNING r_g02.*
--CALL fl_mostrar_mensaje('Transferencia enviada a Localidad: ' || r_g02.g02_nombre CLIPPED || '.', 'info')
DISPLAY 'Transferencia enviada a Localidad: '

END FUNCTION

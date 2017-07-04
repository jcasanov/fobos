DATABASE acero_gm


DEFINE base		CHAR(20)



MAIN

	IF num_args() <> 1 THEN
		DISPLAY 'Parametros Incorrectos. Falta la BASE.'
		EXIT PROGRAM
	END IF
	LET base = arg_val(1)
	CALL activar_base_datos()
	CALL ejecutar_proceso()
	DISPLAY 'Chequeo Terminado OK.'

END MAIN



FUNCTION activar_base_datos()
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_loc		RECORD LIKE gent002.*

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



FUNCTION ejecutar_proceso()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE i, j, l, k	INTEGER
DEFINE m, n, o, p, q, r	INTEGER
DEFINE s, t, u		INTEGER
DEFINE resp, resul	INTEGER

DECLARE q_cli CURSOR FOR SELECT * FROM cxct001 WHERE z01_estado = 'A'
DISPLAY ' '
DISPLAY 'Verificando identificación de clientes. Por favor espere ...'
DISPLAY ' '
LET i = 0
LET j = 0
LET l = 0
LET k = 0
LET m = 0
LET n = 0
LET o = 0
LET p = 0
LET q = 0
LET r = 0
LET s = 0
LET t = 0
LET u = 0
FOREACH q_cli INTO r_z01.*
	CALL fl_validar_cedruc_dig_ver(r_z01.z01_num_doc_id) RETURNING resul
	SELECT fp_digito_veri(r_z01.z01_num_doc_id) INTO resp FROM dual
	IF resul = 1 AND resp = 1 THEN
		IF r_z01.z01_tipo_doc_id = 'P' THEN
			DISPLAY 'El cliente: ', r_z01.z01_codcli USING "<<<<<&",
				' ', r_z01.z01_nomcli CLIPPED, ' con CEDRUC ',
				'tiene tipo pasaporte '
			LET k = k + 1
			CONTINUE FOREACH
		END IF
		IF LENGTH(r_z01.z01_num_doc_id) = 10 THEN
			IF r_z01.z01_tipo_doc_id = 'R' THEN
				LET r_z01.z01_tipo_doc_id = 'C'
			END IF
			IF r_z01.z01_tipo_doc_id = 'C' THEN
				LET r_z01.z01_personeria = 'N'
			END IF
			DISPLAY 'El cliente: ', r_z01.z01_codcli USING "<<<<<&",
				' ', r_z01.z01_nomcli CLIPPED, ' con cedula ',
				'tiene tipo: ', r_z01.z01_tipo_doc_id CLIPPED
			LET j = j + 1
		END IF
		IF LENGTH(r_z01.z01_num_doc_id) = 13 THEN
			IF r_z01.z01_tipo_doc_id = 'C' THEN
				LET r_z01.z01_tipo_doc_id = 'R'
			END IF
			IF r_z01.z01_tipo_doc_id = 'R' THEN
				LET r_z01.z01_personeria = 'J'
			END IF
			DISPLAY 'El cliente: ', r_z01.z01_codcli USING "<<<<<&",
				' ', r_z01.z01_nomcli CLIPPED, ' con RUC ',
				'tiene tipo: ', r_z01.z01_tipo_doc_id CLIPPED
			LET l = l + 1
		END IF
		DISPLAY '  Actualizando cliente: ',
				r_z01.z01_codcli USING "<<<<<&",
				' ', r_z01.z01_nomcli CLIPPED, ' OK '
		UPDATE cxct001
			SET z01_tipo_doc_id = r_z01.z01_tipo_doc_id,
			    z01_personeria  = r_z01.z01_personeria
			WHERE z01_codcli = r_z01.z01_codcli
	END IF
	IF resul = 0 AND resp = 0 THEN
		IF LENGTH(r_z01.z01_num_doc_id) = 10 THEN
			CASE r_z01.z01_tipo_doc_id
				WHEN 'C' LET m = m + 1
				WHEN 'R' LET n = n + 1
				WHEN 'P' LET o = o + 1
			END CASE
		ELSE
			IF LENGTH(r_z01.z01_num_doc_id) = 13 THEN
				CASE r_z01.z01_tipo_doc_id
					WHEN 'C' LET p = p + 1
					WHEN 'R' LET q = q + 1
					WHEN 'P' LET r = r + 1
				END CASE
			ELSE
				CASE r_z01.z01_tipo_doc_id
					WHEN 'C' LET s = s + 1
					WHEN 'R' LET t = t + 1
					WHEN 'P' LET u = u + 1
				END CASE
			END IF
		END IF
	END IF
	IF resul = resp THEN
		CONTINUE FOREACH
	END IF
	DISPLAY 'El cliente: ', r_z01.z01_codcli USING "<<<<&", ' ',
		r_z01.z01_nomcli CLIPPED, ' con # ',
		r_z01.z01_num_doc_id CLIPPED, ' no coincide. fl = ',
		resul USING "<<&", ' fp = ', resp USING "<<&"
	LET i = i + 1
END FOREACH
DISPLAY ' '
DISPLAY 'TOTAL CLIENTES NO COINCIDEN: ', i USING "<<<<<&"
DISPLAY ' '
DISPLAY 'TOTAL CLIENTES 10 DIGITOS VALIDADOS CON OTRO TIPO: ', j USING "<<<<<&"
DISPLAY 'TOTAL CLIENTES 13 DIGITOS VALIDADOS CON OTRO TIPO: ', l USING "<<<<<&"
DISPLAY ' '
DISPLAY 'TOTAL CLIENTES VALIDADOS CON TIPO PASAPORTE : ', k USING "<<<<<<&"
DISPLAY ' '
DISPLAY ' '
DISPLAY 'TOTAL CLIENTES 10 DIGITOS TIPO CEDULA   : ', m USING "<<<<<<&"
DISPLAY 'TOTAL CLIENTES 10 DIGITOS TIPO RUC      : ', n USING "<<<<<<&"
DISPLAY 'TOTAL CLIENTES 10 DIGITOS TIPO PASAPORTE: ', o USING "<<<<<<&"
DISPLAY ' '
DISPLAY 'TOTAL CLIENTES 13 DIGITOS TIPO CEDULA   : ', p USING "<<<<<<&"
DISPLAY 'TOTAL CLIENTES 13 DIGITOS TIPO RUC      : ', q USING "<<<<<<&"
DISPLAY 'TOTAL CLIENTES 13 DIGITOS TIPO PASAPORTE: ', r USING "<<<<<<&"
DISPLAY ' '
DISPLAY 'TOTAL CLIENTES NI 10 NI 13 TIPO CEDULA   : ', s USING "<<<<<<&"
DISPLAY 'TOTAL CLIENTES NI 10 NI 13 TIPO RUC      : ', t USING "<<<<<<&"
DISPLAY 'TOTAL CLIENTES NI 10 NI 13 TIPO PASAPORTE: ', u USING "<<<<<<&"
DISPLAY ' '

END FUNCTION



FUNCTION fl_validar_cedruc_dig_ver(cedruc)
DEFINE cedruc		VARCHAR(15)
DEFINE valor		ARRAY[15] OF SMALLINT
DEFINE suma, i, lim	SMALLINT
DEFINE residuo_suma	SMALLINT

LET lim    = 10
LET cedruc = cedruc CLIPPED
IF (LENGTH(cedruc) <> lim) AND (LENGTH(cedruc) <> 13) THEN
	DISPLAY 'El número de digitos de cédula/ruc es incorrecto.'
	RETURN 0
END IF
IF (cedruc[1, 2] > 22) OR (cedruc[1, 2] = 00) THEN
	DISPLAY 'Los digitos iniciales de cédula/ruc son incorrectos.'
	RETURN 0
END IF
IF LENGTH(cedruc) = 13 THEN
	IF cedruc[11, 13] <> '001' OR cedruc[11, 12] <> '00' THEN
		DISPLAY 'El número de digitos del ruc es incorrecto.'
		RETURN 0
	END IF
END IF
FOR i = 1 TO lim
	LET valor[i] = 0
END FOR
LET residuo_suma = NULL
IF cedruc[3, 3] = 9 THEN
	LET valor[1]   = cedruc[1, 1] * 4
	LET valor[2]   = cedruc[2, 2] * 3
	LET valor[3]   = cedruc[3, 3] * 2
	LET valor[4]   = cedruc[4, 4] * 7
	LET valor[5]   = cedruc[5, 5] * 6
	LET valor[6]   = cedruc[6, 6] * 5
	LET valor[7]   = cedruc[7, 7] * 4
	LET valor[8]   = cedruc[8, 8] * 3
	LET valor[9]   = cedruc[9, 9] * 2
	LET valor[lim] = cedruc[lim, lim]
	LET suma       = 0
	FOR i = 1 TO lim - 1
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 11 - (suma mod 11)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 11 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
IF (cedruc[3, 3] = 6) OR (cedruc[3, 3] = 8) THEN
	LET valor[1]   = cedruc[1, 1] * 3
	LET valor[2]   = cedruc[2, 2] * 2
	LET valor[3]   = cedruc[3, 3] * 7
	LET valor[4]   = cedruc[4, 4] * 6
	LET valor[5]   = cedruc[5, 5] * 5
	LET valor[6]   = cedruc[6, 6] * 4
	LET valor[7]   = cedruc[7, 7] * 3
	LET valor[8]   = cedruc[8, 8] * 2
	LET valor[lim] = cedruc[9, 9]
	LET suma       = 0
	FOR i = 1 TO lim - 2
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 11 - (suma mod 11)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 11 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
IF ((cedruc[3, 3] < 3) OR (cedruc[3, 3] > 5)) AND (cedruc[3, 3] <> 7) THEN
	FOR i = 1 TO lim - 1
		LET valor[i] = cedruc[i, i]
		IF (i mod 2) <> 0 THEN
			LET valor[i] = valor[i] * 2
			IF valor[i] > 9 THEN
				LET valor[i] = valor[i] - 9
			END IF
		END IF
	END FOR
	LET valor[lim] = cedruc[lim, lim]
	LET suma       = 0
	FOR i = 1 TO lim - 1
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 10 - (suma mod 10)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 10 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
DISPLAY 'El número de cédula/ruc no es valido.'
RETURN 0

END FUNCTION

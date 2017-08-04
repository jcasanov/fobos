DATABASE aceros


DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)



MAIN

	IF num_args() <> 2 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE SERVIDOR '
		EXIT PROGRAM
	END IF
	LET base_ori  = arg_val(1)
	LET serv_ori  = arg_val(2)
	CALL ejecuta_proceso()

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION ejecuta_proceso()
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE nomprov		LIKE cxpt001.p01_nomprov
DEFINE correo		LIKE cxpt002.p02_email
DEFINE i, lim		SMALLINT
DEFINE encontro, cont	INTEGER
DEFINE total		INTEGER

CALL activar_base(base_ori, serv_ori)
SET ISOLATION TO DIRTY READ
DISPLAY "Seleccionando proveedores para el analisis y/o correccion del mail ..."
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_mail CURSOR WITH HOLD FOR
	SELECT cxpt002.*, cxpt001.p01_nomprov
		FROM cxpt002, cxpt001
		WHERE p02_compania = 1
		  AND p02_email    IS NOT NULL
		  AND p01_codprov  = p02_codprov
		ORDER BY p01_nomprov
OPEN q_mail
FETCH q_mail INTO r_p02.*, nomprov
IF STATUS < 0 THEN
	ROLLBACK WORK
	DISPLAY " "
	DISPLAY "ERROR: No se puede generar el cursor de los proveedores."
	DISPLAY " "
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF	
WHENEVER ERROR STOP
LET total = 0
LET cont  = 0
DISPLAY " "
FOREACH q_mail INTO r_p02.*, nomprov
	LET total  = total + 1
	LET nomprov = nomprov[1, 45]
	DISPLAY "  Chequeando proveedor: ", r_p02.p02_codprov USING "#####&",
		" ", nomprov
	LET r_p02.p02_email = r_p02.p02_email CLIPPED
	LET lim             = LENGTH(r_p02.p02_email) 
	LET correo          = " "
	LET encontro        = 0
	FOR i = 1 TO lim
		IF r_p02.p02_email[i, i] = '
		   r_p02.p02_email[i, i] = '�' THEN
			LET correo   = correo CLIPPED, ""
			LET encontro = 1
		ELSE
			LET correo = correo CLIPPED, r_p02.p02_email[i, i]
		END IF
	END FOR
	IF NOT encontro THEN
		CONTINUE FOREACH
	END IF
	LET r_p02.p02_email = correo CLIPPED
	WHENEVER ERROR CONTINUE
	UPDATE cxpt002
		SET p02_email = r_p02.p02_email
		WHERE p02_compania  = r_p02.p02_compania
		  AND p02_localidad = r_p02.p02_localidad
		  AND p02_codprov   = r_p02.p02_codprov
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		DISPLAY " "
		DISPLAY "ERROR: No se puede actualizar el mail del proveedor: ",
			r_p02.p02_codprov USING "#####&"
		DISPLAY " "
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF	
	WHENEVER ERROR STOP
	LET cont = cont + 1
	DISPLAY "    Actualizando email: ", r_p02.p02_email CLIPPED
	DISPLAY " "
END FOREACH
COMMIT WORK
IF cont > 0 THEN
	DISPLAY " "
	DISPLAY "Se actualizaron ", cont USING "<<<<<&",
		" mails de proveedores.  OK"
	DISPLAY " "
ELSE
	DISPLAY " "
END IF
DISPLAY "Analisis y/o correccion de mails a ", total USING "<<<<<&",
	" proveedores terminado  OK."

END FUNCTION
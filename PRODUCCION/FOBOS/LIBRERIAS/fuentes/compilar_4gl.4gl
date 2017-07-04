DATABASE syspgm4gl


DEFINE opc		CHAR(1)



MAIN

	CALL compila_prog()

END MAIN



FUNCTION compila_prog()
DEFINE file_ext		CHAR(255)
DEFINE file		CHAR(255)
DEFINE fuera		CHAR(100)
DEFINE mens		CHAR(100)
DEFINE librerias	CHAR(200)
DEFINE compil		CHAR(400)
DEFINE r_id		RECORD LIKE id_prog4gl.*
DEFINE prog		RECORD LIKE source4gl.*
DEFINE glob		RECORD LIKE global.*
DEFINE libr		RECORD LIKE otherobj.*
DEFINE i		SMALLINT

IF num_args() <> 1 AND num_args() <> 2 THEN
	EXIT PROGRAM
END IF
LET file_ext = arg_val(1)
LET opc = "k"
IF num_args() = 2 THEN
	LET opc = arg_val(2)
	IF opc <> 'S' AND opc <> 'N' THEN
		EXIT PROGRAM
	END IF
END IF
IF file_ext[1, 8] = "compilar" THEN
	EXIT PROGRAM
END IF
FOR i = 1 TO length(file_ext) - 4
	LET file[i] = file_ext[i]
END FOR	
DECLARE q_existe CURSOR FOR SELECT * FROM id_prog4gl WHERE progname = file
OPEN q_existe
FETCH q_existe INTO r_id.*
IF STATUS = NOTFOUND THEN
	CLOSE q_existe
	IF opc <> 'S' THEN
		DISPLAY 'El programa ', file_ext CLIPPED,
			' no está para caracter.'
	END IF
	IF NOT inserta_sn() THEN
		INSERT INTO id_prog4gl VALUES (file, 'N')
		EXIT PROGRAM
	END IF
	INSERT INTO id_prog4gl VALUES (file, 'S')
	OPEN q_existe
	FETCH q_existe INTO r_id.*
END IF
IF r_id.crea_4gl = 'N' THEN
	CLOSE q_existe
	DISPLAY 'El programa ', file_ext CLIPPED, ' no está para caracter'
	EXIT PROGRAM
END IF
DECLARE q1 CURSOR FOR SELECT * FROM source4gl WHERE progname = file
OPEN q1
FETCH q1 INTO prog.*
IF STATUS = NOTFOUND THEN
	CLOSE q1
	INSERT INTO source4gl VALUES (file, '', file, '.')
	INSERT INTO global
		VALUES (file, '', 'globales', '../../LIBRERIAS/fuentes/')
	FOR i = 0 TO 6
		IF file[4, 5] <> "p2" THEN
			IF i > 1 THEN
				EXIT FOR
			END IF
		END IF
		LET librerias = 'libp00', i USING '&'
		INSERT INTO otherobj VALUES (file, '', librerias, '.')
	END FOR
	OPEN q1
	FETCH q1 INTO prog.*
END IF
DECLARE q2 CURSOR FOR SELECT * FROM global WHERE progname = file
OPEN q2
FETCH q2 INTO glob.*
CLOSE q2
DECLARE q3 CURSOR FOR SELECT * FROM otherobj WHERE progname = file
LET librerias = ' '
FOREACH q3 INTO libr.*
	LET librerias = librerias CLIPPED, ' ', libr.othername CLIPPED, '.4go'
END FOREACH
LET mens = 'Compiling in caracter 4gl ' || file_ext CLIPPED || '...'
DISPLAY mens CLIPPED
LET compil = 'fglpc ', prog.progname CLIPPED, '.4gl'
RUN compil
LET compil = 'cat ', prog.progname CLIPPED, '.4go ', glob.gpath CLIPPED,
		glob.globname CLIPPED, '.4go ', librerias, '> ',
 		prog.progname CLIPPED, '.4gi'
RUN compil
LET fuera = 'Done ' || file CLIPPED
DISPLAY fuera CLIPPED

END FUNCTION



FUNCTION inserta_sn()
DEFINE opcion		CHAR(1)

LET opcion = opc
WHILE opcion NOT MATCHES "[SsNnXx]" 
	PROMPT "Desea crearlo (S/N) ==> " 
		FOR CHAR opcion   
     		ON KEY(INTERRUPT)
     			LET opcion = "q"
 	END PROMPT
	IF opcion IS NULL THEN
		LET opcion = "k"
		CONTINUE WHILE
 	END IF
END WHILE
IF opcion MATCHES "[Xx]" THEN
	EXIT PROGRAM
END IF
IF opcion MATCHES "[Nn]" THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION

DATABASE syspgm4gl



DEFINE r_id		RECORD LIKE id_prog4js.*
DEFINE file_ext		CHAR(255)
DEFINE file		CHAR(255)
DEFINE i		SMALLINT
DEFINE opc		CHAR(1)



MAIN

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
	
DECLARE q_existe CURSOR FOR SELECT * FROM id_prog4js WHERE progname = file
OPEN q_existe
FETCH q_existe INTO r_id.*
IF STATUS = NOTFOUND THEN
	CLOSE q_existe
	IF opc <> 'S' THEN
		DISPLAY 'El programa ', file_ext CLIPPED, ' no está para 4js.'
	END IF
	IF NOT inserta_sn() THEN
		INSERT INTO id_prog4js VALUES (file, 'N')
		EXIT PROGRAM
	END IF
	INSERT INTO id_prog4js VALUES (file, 'S')
	OPEN q_existe
	FETCH q_existe INTO r_id.*
END IF
IF r_id.crea_4js = 'N' THEN
	CLOSE q_existe
	DISPLAY 'El programa ', file_ext CLIPPED, ' no está para 4js'
	EXIT PROGRAM
END IF

DISPLAY 'Compiling in 4js ' || file_ext CLIPPED || '...'
RUN 'fgl2p -O -o ' || file CLIPPED || '.42r ' || file_ext CLIPPED || 
    ' libp000.42m libp001.42m libp002.42m libp003.42m libp004.42m ' ||
    ' libp005.42m libp006.42m'
DISPLAY 'Done ' || file CLIPPED

END MAIN



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

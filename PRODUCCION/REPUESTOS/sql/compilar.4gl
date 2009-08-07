MAIN

DEFINE file_ext		CHAR(255)
DEFINE file		CHAR(255)

DEFINE i		SMALLINT

	IF num_args() <> 1 THEN
		EXIT PROGRAM
	END IF

	LET file_ext = arg_val(1)
	
	FOR i = 1 TO length(file_ext) - 4
		LET file[i] = file_ext[i]
	END FOR	
	
	DISPLAY 'Compiling ' || file_ext CLIPPED || '...'
	RUN 'fgl2p -O -o ' || file CLIPPED || '.42r ' || file_ext CLIPPED || 
	    ' libp000.42m libp001.42m libp002.42m libp003.42m libp004.42m'
	DISPLAY 'Done ' || file CLIPPED

END MAIN

MAIN

DEFINE base	VARCHAR(50)
DEFINE opcion	SMALLINT

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN

CALL fgl_init4js()

IF num_args() <> 1 THEN
	CALL fgl_winmessage('FOBOS', 'Debe indicar la base de datos.', 'stop')
	EXIT PROGRAM
END IF

LET base = arg_val(1)

OPEN WINDOW w_inst AT 1,1 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE (FORM LINE FIRST, COMMENT LINE LAST, BORDER, 
  		   MESSAGE LINE LAST)
OPEN FORM f_inst FROM 'menu_comp' 
DISPLAY FORM f_inst

OPTIONS 
	INPUT WRAP

WHILE TRUE

	INPUT BY NAME opcion
		AFTER FIELD opcion
			IF opcion IS NULL THEN
				NEXT FIELD opcion
			END IF
			IF opcion < 0 AND opcion > 13 THEN
				NEXT FIELD opcion
			END IF
	END INPUT
	IF int_flag THEN
		EXIT WHILE
	END IF
	
	CASE opcion 
		WHEN 0
			EXIT WHILE
		WHEN 1 
			RUN 'sh gen_schema.sh ' || base CLIPPED
		WHEN 2 
			RUN 'sh comp_libp.sh'
		WHEN 3 
			RUN 'sh comp_modulo.sh REPUESTOS'
		WHEN 4 
			RUN 'sh comp_modulo.sh TALLER'
		WHEN 5 
			RUN 'sh comp_modulo.sh COBRANZAS'
		WHEN 6 
			RUN 'sh comp_modulo.sh TESORERIA'
		WHEN 7 
			RUN 'sh comp_modulo.sh CONTABILIDAD'
		WHEN 8 
			RUN 'sh comp_modulo.sh GENERALES'
		WHEN 9 
			RUN 'sh comp_modulo.sh COMPRAS'
		WHEN 10 
			RUN 'sh comp_modulo.sh CAJA'
		WHEN 11 
			RUN 'sh comp_modulo.sh VEHICULOS'
		WHEN 12 
			RUN 'sh comp_modulo.sh COMISIONES'
		WHEN 13 
			RUN 'sh compila_all.sh '
	END CASE

END WHILE

CLOSE WINDOW w_inst

END MAIN

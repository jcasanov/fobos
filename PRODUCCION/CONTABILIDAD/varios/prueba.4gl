DATABASE diteca

MAIN

DEFINE i				SMALLINT
DEFINE fecha			DATE

LET fecha = TODAY - 5 UNITS DAY

FOR i = 1 TO 5
	DISPLAY 'Saldo al ', fecha, ': ', fl_obtiene_saldo_contable(1, '11010201001', 'DO', fecha, 'A') 
	LET fecha = fecha + 1 UNITS DAY
END FOR

END MAIN

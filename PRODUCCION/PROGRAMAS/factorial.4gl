DEFINE fact, valor	INTEGER
DEFINE num		CHAR(1)


MAIN

	PROMPT 'Digite un numero: ' FOR CHAR num
	LET valor = num
	LET fact  = factorial(valor)
	DISPLAY 'El factorial de ', valor USING '<<<<&', ' es ',
		fact USING '<<<<<<&'

END MAIN



FUNCTION factorial(numero)
DEFINE numero		INTEGER

IF numero = 0 OR numero = 1 THEN
	RETURN 1
ELSE
	RETURN numero * factorial(numero - 1)
END IF

END FUNCTION

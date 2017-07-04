DEFINE fibo, valor	INTEGER
DEFINE num		CHAR(1)


MAIN

	PROMPT 'Digite un numero: ' FOR CHAR num
	LET valor = num
	LET fibo  = fibonacci(valor)
	DISPLAY 'La serie fibonacci de ', valor USING '<<<<&', ' es ',
		fibo USING '<<<<<<&'

END MAIN



FUNCTION fibonacci(numero)
DEFINE numero		INTEGER

IF numero = 0 OR numero = 1 THEN
	RETURN 1
ELSE
	RETURN fibonacci(numero - 1) + fibonacci(numero - 2)
END IF

END FUNCTION

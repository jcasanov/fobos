database aceros

define x	decimal(14,2)
define y	smallint
define a, m, d	smallint
define f1, f2	date

main
	if num_args() <> 2 THEN
		exit program
	end if
	let f1 = arg_val(1)
	let f2 = arg_val(2)
	let x = 12315.17091
--	let y = trunc(x)
	select trunc(3.2) into y from dual
	display 'la y = ', y
	let y = x USING "&&&&&&&&&&&&"
	display 'la y = ', y
	--call fl_retorna_anios_meses_dias(mdy(12,15,2003), mdy(1,15,2002))
	call fl_retorna_anios_meses_dias(date(f1), date(f2))
		returning a, m, d
	display 'la edad es: ', a using '&&', ' años ', m using '&&', ' meses ',
		d using '&&', ' días.'
end main



FUNCTION fl_retorna_anios_meses_dias(fecha1, fecha2)
DEFINE fecha1		DATE
DEFINE fecha2		DATE
DEFINE anios		SMALLINT
DEFINE meses		SMALLINT
DEFINE dias, i		SMALLINT
DEFINE expr_fec		CHAR(200)
DEFINE query		CHAR(600)

LET anios = 0
LET meses = 0
LET dias  = 0
IF fecha1 <= fecha2 THEN
	display 'La primera fecha debe ser mayor a la segunda fecha.'
	RETURN 0, 0, 0 
END IF
LET anios = YEAR(fecha1) - YEAR(fecha2)
LET expr_fec = ' TRUNC(((DATE("', fecha1, '") - DATE("', fecha2, '")) / ',
		'365 - TRUNC((DATE("', fecha1, '") - DATE("', fecha2, '")) / ',
		'365))'
LET query = 'SELECT ', expr_fec CLIPPED, ' * (365 / 30))',
		' FROM dual'
PREPARE trunc_mes FROM query
EXECUTE trunc_mes INTO meses
LET query = 'SELECT ', expr_fec CLIPPED, ' * 365) - ((', expr_fec CLIPPED,
		' * (365 / 30))) * 30)',
		' FROM dual'
PREPARE trunc_dia FROM query
EXECUTE trunc_dia INTO dias
IF YEAR(fecha2) <> YEAR(fecha1) THEN
	FOR i = YEAR(fecha2) TO YEAR(fecha1)
		IF ((i MOD 4) <> 0) THEN
			CONTINUE FOR
		END IF
		LET dias = dias + 1
		IF dias > 30 THEN
			LET dias  = 0
			LET meses = meses + 1
			IF meses > 12 THEN
				LET meses = 0
				LET anios = anios + 1
			END IF
		END IF
	END FOR
ELSE
	IF meses = 12 THEN
		LET meses = 0
		LET anios = anios + 1
	END IF
END IF
RETURN anios, meses, dias

END FUNCTION

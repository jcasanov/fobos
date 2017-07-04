begin work;
update srit021
	set s21_estado = 'D'
	where 1 = 1;
update srit021
	set s21_estado = 'P'
	where s21_anio = 2009
	  and s21_mes  = 10;
commit work;

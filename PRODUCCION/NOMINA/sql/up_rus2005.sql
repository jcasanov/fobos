begin work;

select n30_nombres, n30_sueldo_mes, n30_factor_hora
	from rolt030
	where n30_estado = 'A'
	order by 1 asc;

update rolt030 set n30_sueldo_mes = n30_sueldo_mes + 8
	where n30_estado = 'A';

update rolt030 set n30_factor_hora = n30_sueldo_mes / 240
	where n30_estado = 'A';

select n30_nombres, n30_sueldo_mes, n30_factor_hora
	from rolt030
	where n30_estado = 'A'
	order by 1 asc;

commit work;

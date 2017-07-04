begin work;

update gent050 set g50_estado = 'B'
	where g50_modulo in ('CH', 'VE');

update gent054 set g54_estado = 'B'
	where g54_modulo in (select g50_modulo from gent050
				where g50_estado = 'B');

commit work;

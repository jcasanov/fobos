begin work;

select * from gent050 where g50_estado = 'B' order by g50_modulo;

select g54_modulo, count(*) hay from gent054
	where g54_modulo in (select g50_modulo from gent050
				where g50_estado = 'B')
	group by 1;

update gent050 set g50_estado = 'B'
	where g50_modulo in ('CH', 'VE');

update gent054 set g54_estado = 'B'
	where g54_modulo in (select g50_modulo from gent050
				where g50_estado = 'B');

select * from gent050 where g50_estado = 'B' order by g50_modulo;

select g54_modulo, count(*) hay from gent054
	where g54_modulo in (select g50_modulo from gent050
				where g50_estado = 'B')
	group by 1;

commit work;

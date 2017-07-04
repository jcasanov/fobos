begin work;

insert into gent005
	select * from acero_qm:gent005
		where g05_usuario = 'E1ALERIO';

insert into gent052
	select * from acero_qm:gent052
		where g52_usuario = 'E1ALERIO';

insert into gent053
	select * from acero_qm:gent053
		where g53_usuario = 'E1ALERIO';

insert into gent055
	select g55_user, g55_compania, g55_modulo, g55_proceso, 'FOBOS',
			current
		from acero_qm:gent055
		where g55_user     = 'E1ALERIO'
		  and g55_compania = 1;

commit work;

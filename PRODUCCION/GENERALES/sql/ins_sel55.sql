insert into gent055
	select g05_usuario, 1, 'GE', 'genp140', 'FOBOS', current
		from gent005
 		where g05_estado <> 'B'

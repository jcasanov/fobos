begin work;

	alter table "fobos".rept095
		add (r95_proc_orden	varchar(60, 40)	before r95_usuario);

commit work;

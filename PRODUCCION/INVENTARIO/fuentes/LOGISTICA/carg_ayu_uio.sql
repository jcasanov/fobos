begin work;

insert into rept115
	(r115_compania, r115_localidad, r115_cod_trans, r115_cod_ayud,
	 r115_estado, r115_nombre, r115_usuario, r115_fecing)
	values (1, 3, 1, 1, "A", "AYUDANTE 1", "FOBOS", current);

insert into rept115
	(r115_compania, r115_localidad, r115_cod_trans, r115_cod_ayud,
	 r115_estado, r115_nombre, r115_usuario, r115_fecing)
	values (1, 3, 1, 2, "A", "AYUDANTE 2", "FOBOS", current);

insert into rept115
	(r115_compania, r115_localidad, r115_cod_trans, r115_cod_ayud,
	 r115_estado, r115_nombre, r115_usuario, r115_fecing)
	values (1, 3, 2, 1, "A", "AYUDANTE 3", "FOBOS", current);

commit work;

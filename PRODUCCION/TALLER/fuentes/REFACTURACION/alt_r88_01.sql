begin work;

alter table "fobos".rept088 drop r88_modulo;

alter table "fobos".rept088 add (r88_ord_trabajo integer before r88_usuario);

create index "fobos".i02_fk_rept088 on "fobos".rept088
	(r88_compania, r88_localidad, r88_ord_trabajo) in idxdbs;

alter table "fobos".rept088
	add constraint
		(foreign key (r88_compania, r88_localidad, r88_ord_trabajo)
			references "fobos".talt060);

commit work;

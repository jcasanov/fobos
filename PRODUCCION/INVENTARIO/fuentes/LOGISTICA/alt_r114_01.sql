begin work;

alter table "fobos".rept114 drop r114_codcli;

alter table "fobos".rept114 modify (r114_guia_remision	decimal(15,0));

alter table "fobos".rept114
	add (r114_codcli	integer		before r114_cod_zona);

create index "fobos".i05_fk_rept114
	on "fobos".rept114
		(r114_codcli)
	in idxdbs;

alter table "fobos".rept114
	add constraint
		(foreign key (r114_codcli)
			references "fobos".cxct001
			constraint "fobos".fk_06_rept114);

commit work;

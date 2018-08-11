begin work;

alter table "fobos".rept116 drop r116_codprov;

alter table "fobos".rept116
	add (r116_codprov	integer		before r116_usuario);

create index "fobos".i02_fk_rept116
	on "fobos".rept116
		(r116_codprov)
	in idxdbs;

alter table "fobos".rept116
	add constraint
		(foreign key (r116_codprov)
			references "fobos".cxpt001
			constraint "fobos".fk_02_rept116);

commit work;

begin work;

alter table "fobos".rept108 drop r108_cia_trans;

alter table "fobos".rept108
	add (r108_cia_trans	smallint	before r108_usuario);

create index "fobos".i03_fk_rept108
	on "fobos".rept108
		(r108_compania, r108_localidad, r108_cia_trans)
	in idxdbs;

alter table "fobos".rept108
	add constraint
		(foreign key (r108_compania, r108_localidad, r108_cia_trans)
			references "fobos".rept116
			constraint "fobos".fk_03_rept108);

commit work;

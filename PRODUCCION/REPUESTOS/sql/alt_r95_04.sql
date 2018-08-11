begin work;

	alter table "fobos".rept095
		add (r95_usu_elim	varchar(10,5)
				before r95_usuario);

	alter table "fobos".rept095
		add (r95_fec_elim	datetime year to second
				before r95_usuario);

	create index "fobos".i03_fk_rept095
		on "fobos".rept095
			(r95_usu_elim)
		in idxdbs;

	alter table "fobos".rept095
		add constraint
			(foreign key (r95_usu_elim)
				references "fobos".gent005
				constraint "fobos".fk_02_rept095);

commit work;

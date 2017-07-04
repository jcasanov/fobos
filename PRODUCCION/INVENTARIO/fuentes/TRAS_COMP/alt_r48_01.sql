begin work;

	drop index "fobos".i04_fk_rept048;

	alter table "fobos".rept048
		drop constraint "fobos".fk_04_rept048;

	alter table "fobos".rept048
		drop constraint "fobos".ck_01_rept048;

	alter table "fobos".rept048
		add (r48_usu_elimin	varchar(10,5)	before r48_usu_cierre);

	alter table "fobos".rept048
		add (r48_fec_elimin	datetime year to second
						before r48_usu_cierre);

	create index "fobos".i04_fk_rept048
		on "fobos".rept048
			(r48_usu_elimin)
		in idxdbs;

	create index "fobos".i05_fk_rept048
		on "fobos".rept048
			(r48_usu_cierre)
		in idxdbs;

	create index "fobos".i06_fk_rept048
		on "fobos".rept048
			(r48_usuario)
		in idxdbs;

	alter table "fobos".rept048
		add constraint
			(foreign key (r48_usu_elimin)
				references "fobos".gent005
				constraint "fobos".fk_04_rept048);

	alter table "fobos".rept048
		add constraint
			(foreign key (r48_usu_cierre)
				references "fobos".gent005
				constraint "fobos".fk_05_rept048);

	alter table "fobos".rept048
		add constraint
			(foreign key (r48_usuario)
				references "fobos".gent005
				constraint "fobos".fk_06_rept048);

	alter table "fobos".rept048
		add constraint
			check (r48_estado in ('C', 'P', 'E'))
				constraint "fobos".ck_01_rept048;

commit work;

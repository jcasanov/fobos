begin work;

	--drop table gent100;

	create table "fobos".gent100

		(

			g100_compania		integer					not null,
			g100_localidad		smallint				not null,
			g100_usuario		varchar(10,5),
			g100_fecha			date					not null

		) lock mode row;

	revoke all on "fobos".gent100 from "public";

	create unique index "fobos".i01_pk_gent100
		on "fobos".gent100
			(g100_compania, g100_localidad)
		in idxdbs;

	create index "fobos".i01_fk_gent100
		on "fobos".gent100
			(g100_usuario)
		in idxdbs;

	alter table "fobos".gent100
		add constraint
			primary key (g100_compania, g100_localidad)
				constraint "fobos".pk_gent100;

	alter table "fobos".gent100
		add constraint
			(foreign key (g100_usuario)
				references "fobos".gent005
				constraint "fobos".fk_01_gent100);

--rollback work;
commit work;

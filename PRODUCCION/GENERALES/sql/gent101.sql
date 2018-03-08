begin work;

	--drop table gent101;

	create table "fobos".gent101

		(
	
			g101_compania		integer					not null,
			g101_localidad		smallint				not null,
			g101_modulo			char(2)					not null,
			g101_tipo			char(2)					not null,
			g101_numero_ini		integer					not null,
			g101_numero_fin		integer					not null

		) lock mode row;

	revoke all on "fobos".gent101 from "public";

	create unique index "fobos".i01_pk_gent101
		on "fobos".gent101
			(g101_compania, g101_localidad, g101_modulo, g101_tipo)
		in idxdbs;

	create index "fobos".i01_fk_gent101
		on "fobos".gent101
			(g101_compania, g101_localidad)
		in idxdbs;

	alter table "fobos".gent101
		add constraint
			primary key (g101_compania, g101_localidad, g101_modulo, g101_tipo)
				constraint "fobos".pk_gent101;

	alter table "fobos".gent101
		add constraint
			(foreign key (g101_compania, g101_localidad)
				references "fobos".gent100
				constraint "fobos".fk_01_gent101);

--rollback work;
commit work;

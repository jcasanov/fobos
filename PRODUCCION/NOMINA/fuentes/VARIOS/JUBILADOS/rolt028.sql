drop table rolt028;

begin work;

	create table "fobos".rolt028

		(
			n28_compania	integer			not null,
			n28_proceso	char(2)			not null,
			n28_cod_liqrol	char(2)			not null,
			n28_usuario	varchar(10,5)		not null,
			n28_fecing	datetime year to second	not null

		) in datadbs lock mode row;


	revoke all on "fobos".rolt028 from "public";


	create unique index "fobos".i01_pk_rolt028
		on "fobos".rolt028
			(n28_compania, n28_proceso, n28_cod_liqrol)
		in idxdbs;

	create index "fobos".i01_fk_rolt028
		on "fobos".rolt028
			(n28_compania)
		in idxdbs;

	create index "fobos".i02_fk_rolt028
		on "fobos".rolt028
			(n28_proceso)
		in idxdbs;

	create index "fobos".i03_fk_rolt028
		on "fobos".rolt028
			(n28_cod_liqrol)
		in idxdbs;

	create index "fobos".i04_fk_rolt028
		on "fobos".rolt028
			(n28_usuario)
		in idxdbs;


	alter table "fobos".rolt028
		add constraint
			primary key (n28_compania, n28_proceso, n28_cod_liqrol)
				constraint "fobos".pk_rolt028;

	alter table "fobos".rolt028
		add constraint
			(foreign key (n28_compania)
				references "fobos".rolt001
				constraint "fobos".fk_01_rolt028);

	alter table "fobos".rolt028
		add constraint
			(foreign key (n28_proceso)
				references "fobos".rolt003
				constraint "fobos".fk_02_rolt028);

	alter table "fobos".rolt028
		add constraint
			(foreign key (n28_cod_liqrol)
				references "fobos".rolt003
				constraint "fobos".fk_03_rolt028);

	alter table "fobos".rolt028
		add constraint
			(foreign key (n28_usuario)
				references "fobos".gent005
				constraint "fobos".fk_04_rolt028);


	insert into rolt028
		values (1, 'JU', 'ME', 'FOBOS', current);

	insert into rolt028
		values (1, 'JU', 'DT', 'FOBOS', current);

	insert into rolt028
		values (1, 'JU', 'DC', 'FOBOS', current);


commit work;

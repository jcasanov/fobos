--drop table rolt019;

begin work;

create table "fobos".rolt019
	(

		n19_compania		integer			not null,
		n19_horario		char(2)			not null,
		n19_descripcion		varchar(50,20)		not null,
		n21_hor_ini_ent		datetime hour to second	not null,
		n21_hor_ini_alm		datetime hour to second,
		n21_hor_fin_alm		datetime hour to second,
		n21_hor_fin_ent		datetime hour to second	not null,
		n19_usuario		varchar(10,5)		not null,
		n19_fecing		datetime year to second	not null

	) in datadbs lock mode row;


revoke all on "fobos".rolt019 from "public";


create unique index "fobos".i01_pk_rolt019
	on "fobos".rolt019
		(n19_compania, n19_horario)
	in idxdbs;

create index "fobos".i01_fk_rolt019
	on "fobos".rolt019
		(n19_compania)
	in idxdbs;

create index "fobos".i02_fk_rolt019
	on "fobos".rolt019
		(n19_usuario)
	in idxdbs;


alter table "fobos".rolt019
	add constraint
		primary key (n19_compania, n19_horario)
			constraint "fobos".pk_rolt019;

alter table "fobos".rolt019
	add constraint
		(foreign key (n19_compania)
			references "fobos".rolt001
			constraint "fobos".fk_01_rolt019);

alter table "fobos".rolt019
	add constraint
		(foreign key (n19_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rolt019);


commit work;

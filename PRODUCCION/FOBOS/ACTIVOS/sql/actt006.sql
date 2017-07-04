begin work;

drop table actt006;

create table "fobos".actt006

	(

		a06_compania		integer			not null,
		a06_estado		char(1)			not null,
		a06_descripcion		varchar(40,20)		not null,
		a06_usuario		varchar(10,5)		not null,
		a06_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".actt006 from "public";

create unique index "fobos".i01_pk_actt006
	on "fobos".actt006
		(a06_compania, a06_estado)
	in idxdbs;

create index "fobos".i01_fk_actt006
	on "fobos".actt006
		(a06_usuario)
	in idxdbs;

alter table "fobos".actt006
	add constraint
		primary key (a06_compania, a06_estado)
			constraint "fobos".pk_actt006;

alter table "fobos".actt006
	add constraint
		(foreign key (a06_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_actt006);

insert into actt006
	values (1, 'A', 'ACTIVO', 'FOBOS', current);

insert into actt006
	values (1, 'B', 'BLOQUEADO', 'FOBOS', current);

insert into actt006
	values (1, 'S', 'CON STOCK', 'FOBOS', current);

insert into actt006
	values (1, 'D', 'DEPRECIADO', 'FOBOS', current);

insert into actt006
	values (1, 'V', 'VENDIDO', 'FOBOS', current);

insert into actt006
	values (1, 'E', 'DADO DE BAJA', 'FOBOS', current);

insert into actt006
	values (1, 'X', 'EN DEPRECIACION Y DEPRECIADOS', 'FOBOS', current);

insert into actt006
	values (1, 'T', 'T O D O S', 'FOBOS', current);

commit work;

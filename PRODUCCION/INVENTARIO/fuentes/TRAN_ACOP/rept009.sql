drop table rept009;

begin work;

create table "fobos".rept009

	(

		r09_compania		integer			not null,
		r09_tipo_ident		char(1)			not null,
		r09_descripcion		varchar(40,20)		not null,
		r09_estado		char(1)			not null,
		r09_usuario		varchar(10,5)		not null,
		r09_fecing		datetime year to second	not null,

		check (r09_estado	in ('A', 'B'))
			constraint "fobos".ck_01_rept009

	) in datadbs lock mode row;

revoke all on "fobos".rept009 from "public";

create unique index "fobos".i01_pk_rept009
	on "fobos".rept009
		(r09_compania, r09_tipo_ident)
	in idxdbs;

create index "fobos".i01_fk_rept009
	on "fobos".rept009
		(r09_usuario)
	in idxdbs;

alter table "fobos".rept009
	add constraint
		primary key
			(r09_compania, r09_tipo_ident)
			constraint "fobos".pk_rept009;

alter table "fobos".rept009
	add constraint
		(foreign key
			(r09_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rept009);

insert into rept009
	(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado,
	 r09_usuario, r09_fecing)
	select g02_compania, 'C', 'CONTRATOS', 'A', 'FOBOS', current
		from gent002
		where g02_matriz = 'S'
		  and g02_estado = 'A';

insert into rept009
	(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado,
	 r09_usuario, r09_fecing)
	select g02_compania, 'I', 'IMPORTACION', 'A', 'FOBOS',
			current + 1 units second
		from gent002
		where g02_matriz = 'S'
		  and g02_estado = 'A';

insert into rept009
	(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado,
	 r09_usuario, r09_fecing)
	select g02_compania, 'R', 'RESERVA', 'A', 'FOBOS',
			current + 2 units second
		from gent002
		where g02_matriz = 'S'
		  and g02_estado = 'A';

insert into rept009
	(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado,
	 r09_usuario, r09_fecing)
	select g02_compania, 'V', 'COMUN', 'A', 'FOBOS',
			current + 3 units second
		from gent002
		where g02_matriz = 'S'
		  and g02_estado = 'A';

insert into rept009
	(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado,
	 r09_usuario, r09_fecing)
	select g02_compania, 'T', 'TRANSFERENCIA', 'A', 'FOBOS',
			current + 4 units second
		from gent002
		where g02_matriz = 'S'
		  and g02_estado = 'A';

insert into rept009
	(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado,
	 r09_usuario, r09_fecing)
	select g02_compania, 'S', 'SUBFACTORY', 'A', 'FOBOS',
			current + 5 units second
		from gent002
		where g02_matriz = 'S'
		  and g02_estado = 'A';

insert into rept009
	(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado,
	 r09_usuario, r09_fecing)
	select g02_compania, 'X', 'CARGA POR COMPOSICION', 'A', 'FOBOS',
			current + 6 units second
		from gent002
		where g02_matriz = 'S'
		  and g02_estado = 'A';

commit work;

drop table srit025;

begin work;

--------------------------------------------------------------------------------
create table "fobos".srit025
	(

		s25_compania		integer			not null,
		s25_tipo_ret		char(1)			not null,
		s25_porcentaje		decimal(5,2)		not null,
		s25_codigo_sri		char(6)			not null,
		s25_cliprov		char(1)			not null,
		s25_usuario		varchar(10,5)		not null,
		s25_fecing		datetime year to second	not null,

		check (s25_tipo_ret in ('F', 'I'))
			constraint "fobos".ck_01_srit025,

		check (s25_cliprov in ('C', 'P'))
			constraint "fobos".ck_02_srit025

	) in datadbs lock mode row;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
revoke all on "fobos".srit025 from "public";
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_srit025
	on "fobos".srit025
		(s25_compania, s25_tipo_ret, s25_porcentaje, s25_codigo_sri,
		 s25_cliprov)
	in idxdbs;

create index "fobos".i01_fk_srit025
	on "fobos".srit025
		(s25_compania, s25_tipo_ret, s25_porcentaje, s25_codigo_sri)
	in idxdbs;

create index "fobos".i02_fk_srit025
	on "fobos".srit025
		(s25_usuario)
	in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".srit025
	add constraint
		primary key (s25_compania, s25_tipo_ret, s25_porcentaje,
				s25_codigo_sri, s25_cliprov)
			constraint "fobos".pk_srit025;

alter table "fobos".srit025
	add constraint
		(foreign key (s25_compania, s25_tipo_ret, s25_porcentaje,
				s25_codigo_sri)
			references "fobos".ordt003
			constraint "fobos".fk_01_srit025);

alter table "fobos".srit025
	add constraint
		(foreign key (s25_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_srit025);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
insert into srit025 values (1, 'F', 1.00, '307', 'C', 'FOBOS', current);
insert into srit025 values (1, 'F', 2.00, '307', 'C', 'FOBOS', current);

insert into srit025 values (1, 'F', 1.00, '307', 'P', 'FOBOS', current);
insert into srit025 values (1, 'F', 2.00, '307', 'P', 'FOBOS', current);
--------------------------------------------------------------------------------

commit work;

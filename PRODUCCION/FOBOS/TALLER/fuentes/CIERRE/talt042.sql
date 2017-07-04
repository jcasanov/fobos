--drop table talt042;

{-- TABLA: CIERRE MENSUAL DEL TALLER --}

begin work;

create table "fobos".talt042

	(
		t42_compania		integer			not null,
		t42_localidad		smallint		not null,
		t42_anio		integer			not null,
		t42_mes			smallint		not null,
		t42_num_ot		integer			not null,
		t42_estado		char(1)			not null,
		t42_fecha		date			not null,
		t42_cod_cliente		integer			not null,
		t42_total_mo		decimal(12,2)		not null,
		t42_total_oc		decimal(12,2)		not null,
		t42_total_in		decimal(12,2)		not null,
		t42_total_nt		decimal(12,2)		not null,
		t42_usuario		varchar(10,5)		not null,
		t42_fecing		datetime year to second	not null,

		check 	(t42_estado	in	('A', 'C', 'F', 'E', 'D'))
			constraint "fobos".ck_01_talt042

	) in datadbs lock mode row;

revoke all on "fobos".talt042 from "public";


create unique index "fobos".i01_pk_talt042
	on "fobos".talt042
		(t42_compania, t42_localidad, t42_anio, t42_mes, t42_num_ot)
	in idxdbs;

create index "fobos".i01_fk_talt042
	on "fobos".talt042
		(t42_compania, t42_localidad, t42_num_ot)
	in idxdbs;

create index "fobos".i02_fk_talt042
	on "fobos".talt042
		(t42_compania)
	in idxdbs;

create index "fobos".i03_fk_talt042
	on "fobos".talt042
		(t42_cod_cliente)
	in idxdbs;

create index "fobos".i04_fk_talt042
	on "fobos".talt042
		(t42_usuario)
	in idxdbs;


alter table "fobos".talt042
	add constraint
		primary key (t42_compania, t42_localidad, t42_anio, t42_mes,
				t42_num_ot)
			constraint "fobos".pk_talt042;

alter table "fobos".talt042
	add constraint
		(foreign key (t42_compania, t42_localidad, t42_num_ot)
			references "fobos".talt023
			constraint "fobos".fk_01_talt042);

alter table "fobos".talt042
	add constraint
		(foreign key (t42_compania)
			references "fobos".talt000
			constraint "fobos".fk_02_talt042);

alter table "fobos".talt042
	add constraint
		(foreign key (t42_cod_cliente)
			references "fobos".cxct001
			constraint "fobos".fk_03_talt042);

alter table "fobos".talt042
	add constraint
		(foreign key (t42_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_talt042);

commit work

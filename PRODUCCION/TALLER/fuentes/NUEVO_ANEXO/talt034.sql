drop table talt034;

begin work;

create table "fobos".talt034

	(

		t34_compania		integer			not null,
		t34_localidad		smallint		not null,
		t34_num_ot		integer			not null,
		t34_num_reg		integer			not null,
		t34_num_fact		decimal(15,0)		not null,
		t34_estado		char(1)			not null,
		t34_fecha		date			not null,
		t34_referencia		varchar(80,40)		not null,
		t34_usuario		varchar(10,5)		not null,
		t34_fecing		datetime year to second	not null,

		check (t34_estado in ("A", "C", "E"))
			constraint "fobos".ck_01_talt034

	) in datadbs lock mode row;

revoke all on "fobos".talt034 from "public";

create unique index "fobos".i01_pk_talt034
	on "fobos".talt034
		(t34_compania, t34_localidad, t34_num_ot, t34_num_reg)
	in idxdbs;

create index "fobos".i01_fk_talt034
	on "fobos".talt034
		(t34_compania, t34_localidad, t34_num_ot)
	in idxdbs;

create index "fobos".i02_fk_talt034
	on "fobos".talt034
		(t34_usuario)
	in idxdbs;

alter table "fobos".talt034
	add constraint
		primary key (t34_compania, t34_localidad, t34_num_ot,
				t34_num_reg)
		constraint "fobos".pk_talt034;

alter table "fobos".talt034
	add constraint
		(foreign key (t34_compania, t34_localidad, t34_num_ot)
			references "fobos".talt023
			constraint "fobos".fk_01_talt034);

alter table "fobos".talt034
	add constraint
		(foreign key (t34_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_talt034);

commit work;

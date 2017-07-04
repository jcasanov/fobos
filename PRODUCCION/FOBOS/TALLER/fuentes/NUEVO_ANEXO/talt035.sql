drop table talt035;

begin work;

create table "fobos".talt035

	(

		t35_compania		integer			not null,
		t35_localidad		smallint		not null,
		t35_num_ot		integer			not null,
		t35_num_reg		integer			not null,
		t35_secuencia		smallint		not null,
		t35_item		char(15)		not null,
		t35_descripcion		varchar(70,20)		not null,
		t35_marca		char(6)			not null,
		t35_serie		varchar(60,30)		not null,
		t35_desc_prueb		varchar(90,40)		not null,
		t35_tecnico		smallint		not null,
		t35_observacion		varchar(120,60)		not null

	) in datadbs lock mode row;

revoke all on "fobos".talt035 from "public";

create unique index "fobos".i01_pk_talt035
	on "fobos".talt035
		(t35_compania, t35_localidad, t35_num_ot, t35_num_reg,
		 t35_secuencia)
	in idxdbs;

create index "fobos".i01_fk_talt035
	on "fobos".talt035
		(t35_compania, t35_localidad, t35_num_ot, t35_num_reg)
	in idxdbs;

create index "fobos".i02_fk_talt035
	on "fobos".talt035
		(t35_compania, t35_item)
	in idxdbs;

create index "fobos".i03_fk_talt035
	on "fobos".talt035
		(t35_compania, t35_marca)
	in idxdbs;

create index "fobos".i04_fk_talt035
	on "fobos".talt035
		(t35_compania, t35_tecnico)
	in idxdbs;

alter table "fobos".talt035
	add constraint
		primary key (t35_compania, t35_localidad, t35_num_ot,
				t35_num_reg, t35_secuencia)
		constraint "fobos".pk_talt035;

alter table "fobos".talt035
	add constraint
		(foreign key (t35_compania, t35_localidad, t35_num_ot,
				t35_num_reg)
			references "fobos".talt034
			constraint "fobos".fk_01_talt035);

alter table "fobos".talt035
	add constraint
		(foreign key (t35_compania, t35_item)
			references "fobos".rept010
			constraint "fobos".fk_02_talt035);

alter table "fobos".talt035
	add constraint
		(foreign key (t35_compania, t35_marca)
			references "fobos".rept073
			constraint "fobos".fk_03_talt035);

alter table "fobos".talt035
	add constraint
		(foreign key (t35_compania, t35_tecnico)
			references "fobos".talt003
			constraint "fobos".fk_04_talt035);

commit work;

drop table rept113;

begin work;

create table "fobos".rept113

	(
		r113_compania		integer			not null,
		r113_localidad		smallint		not null,
		r113_num_hojrut		smallint		not null,
		r113_estado		char(1)			not null,
		r113_observacion	varchar(30,20),
		r113_fecha		date			not null,
		r113_cod_trans		smallint		not null,
		r113_cod_chofer		smallint		not null,
		--r113_cod_ayudan		smallint,
		r113_km_ini		integer			not null,
		r113_km_fin		integer			not null,
		r113_usu_cierre		varchar(10,5),
		r113_fec_cierre		datetime year to second,
		r113_usu_elim		varchar(10,5),
		r113_fec_elim		datetime year to second,
		r113_usuario		varchar(10,5)		not null,
		r113_fecing		datetime year to second	not null,

		check (r113_estado in ("A", "P", "C", "E"))
			constraint "fobos".ck_01_rept113

	) in datadbs lock mode row;

revoke all on "fobos".rept113 from "public";

create unique index "fobos".i01_pk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_num_hojrut)
	in idxdbs;

create index "fobos".i01_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_cod_trans)
	in idxdbs;

create index "fobos".i02_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_cod_trans, r113_cod_chofer)
	in idxdbs;

{--
create index "fobos".i03_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_cod_trans, r113_cod_ayudan)
	in idxdbs;
--}

create index "fobos".i03_fk_rept113
	on "fobos".rept113
		(r113_usuario)
	in idxdbs;

alter table "fobos".rept113
	add constraint
		primary key (r113_compania, r113_localidad, r113_num_hojrut)
			constraint "fobos".pk_rept113;

alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_localidad, r113_cod_trans)
			references "fobos".rept110
			constraint "fobos".fk_01_rept113);

alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_localidad, r113_cod_trans,
				r113_cod_chofer)
			references "fobos".rept111
			constraint "fobos".fk_02_rept113);

{--
alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_localidad, r113_cod_trans,
				r113_cod_ayudan)
			references "fobos".rept111
			constraint "fobos".fk_03_rept113);
--}

alter table "fobos".rept113
	add constraint
		(foreign key (r113_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rept113);

commit work;

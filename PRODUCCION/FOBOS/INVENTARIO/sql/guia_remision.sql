----------------------------------------------
------- CREACION DE GUIAS DE REMISION --------
----------------------------------------------

--rollback work;

begin work;

--drop table rept095;
--drop table rept096;
--drop table rept097;

-- CREACION DE TABLA GUIA DE REMISION --
create table "fobos".rept095
	(

		r95_compania		integer			not null,
		r95_localidad		smallint		not null,
		r95_guia_remision	decimal(15, 0)		not null,
		r95_motivo		char(1)			not null,
		r95_entre_local		char(1)			not null,
		r95_fecha_initras	date			not null,
		r95_fecha_fintras	date,
		r95_fecha_emi		date			not null,
		r95_punto_part		varchar(150, 80)	not null,
		r95_autoriz_sri		varchar(15, 10)		not null,
		r95_persona_guia	varchar(100, 70)	not null,
		r95_persona_id		varchar(15, 10)		not null,
		r95_num_sri		char(16)		not null,
		r95_usuario		varchar(10, 5)		not null,
		r95_fecing		datetime year to second	not null,

		check (r95_motivo in ('V', 'D', 'I')) constraint ck_01_rept095,

		check (r95_entre_local in ('S', 'N')) constraint ck_02_rept095

	) in datadbs lock mode row;
--

revoke all on "fobos".rept095 from "public";

-- CREACION DE INDICES EN TABLA GUIA DE REMISION --
create unique index "fobos".i01_pk_rept095 on "fobos".rept095
	(r95_compania, r95_localidad, r95_guia_remision) in idxdbs;

create index "fobos".i01_fk_rept095 on "fobos".rept095 (r95_usuario) in idxdbs;

create index "fobos".i02_fk_rept095 on "fobos".rept095
	(r95_persona_id) in idxdbs;
--

-- CREACION DE CONSTRAINT EN TABLA GUIA DE REMISION --
alter table "fobos".rept095
	add constraint
		primary key (r95_compania, r95_localidad, r95_guia_remision)
			constraint pk_rept095;
alter table "fobos".rept095
	add constraint (foreign key (r95_usuario) references "fobos".gent005
			constraint fk_01_rept095);
--
--

-- CREACION DE TABLA RELACIONAL GUIA DE REMISION / NOTA DE ENTREGA --
create table "fobos".rept096
	(

		r96_compania		integer			not null,
		r96_localidad		smallint		not null,
		r96_guia_remision	decimal(15, 0)		not null,
		r96_bodega		char(2)			not null,
		r96_num_entrega		integer			not null

	) in datadbs lock mode row;
--

revoke all on "fobos".rept096 from "public";

-- CREACION DE INDICES EN TABLA RELACIONAL GUIA DE REMISION / NOTA DE ENTREGA --
create unique index "fobos".i01_pk_rept096 on "fobos".rept096
	(r96_compania, r96_localidad, r96_guia_remision, r96_bodega,
		r96_num_entrega) in idxdbs;

create index "fobos".i01_fk_rept096 on "fobos".rept096
	(r96_compania, r96_localidad, r96_guia_remision) in idxdbs;

create index "fobos".i02_fk_rept096 on "fobos".rept096
	(r96_compania, r96_localidad, r96_bodega, r96_num_entrega) in idxdbs;
--

-- CREACION CONSTRAINT EN TABLA RELACIONAL GUIA DE REMISION / NOTA DE ENTREGA --
alter table "fobos".rept096
	add constraint
		primary key (r96_compania, r96_localidad, r96_guia_remision,
				r96_bodega, r96_num_entrega)
			constraint pk_rept096;

alter table "fobos".rept096
	add constraint
		(foreign key (r96_compania, r96_localidad, r96_guia_remision)
			references "fobos".rept095 constraint fk_01_rept096);

alter table "fobos".rept096
	add constraint
		(foreign key (r96_compania, r96_localidad, r96_bodega,
				r96_num_entrega)
			references "fobos".rept036 constraint fk_02_rept096);
--
--

-- CREACION DE TABLA RELACIONAL GUIA DE REMISION / FACTURA --
create table "fobos".rept097
	(

		r97_compania		integer			not null,
		r97_localidad		smallint		not null,
		r97_guia_remision	decimal(15, 0)		not null,
		r97_cod_tran		char(2)			not null,
		r97_num_tran		decimal(15,0)		not null

	) in datadbs lock mode row;
--

revoke all on "fobos".rept097 from "public";

-- CREACION DE INDICES EN TABLA RELACIONAL GUIA DE REMISION / FACTURA --
create unique index "fobos".i01_pk_rept097 on "fobos".rept097
	(r97_compania, r97_localidad, r97_guia_remision, r97_cod_tran,
		r97_num_tran) in idxdbs;

create index "fobos".i01_fk_rept097 on "fobos".rept097
	(r97_compania, r97_localidad, r97_guia_remision) in idxdbs;
	
create index "fobos".i02_fk_rept097 on "fobos".rept097
	(r97_compania, r97_localidad, r97_cod_tran, r97_num_tran) in idxdbs;
--

-- CREACION DE CONSTRAINT EN TABLA RELACIONAL GUIA DE REMISION / FACTURA --
alter table "fobos".rept097
	add constraint
		primary key (r97_compania, r97_localidad, r97_guia_remision,
				r97_cod_tran, r97_num_tran)
			constraint pk_rept097;

alter table "fobos".rept097
	add constraint
		(foreign key (r97_compania, r97_localidad, r97_guia_remision)
			references "fobos".rept095 constraint fk_01_rept097);

alter table "fobos".rept097
	add constraint
		(foreign key (r97_compania, r97_localidad, r97_cod_tran,
				r97_num_tran)
			references "fobos".rept019 constraint fk_02_rept097);
--
--

commit work;

drop table "fobos".rolt058;
drop table "fobos".rolt059;

begin work;

-- CREACION DE TABLA CONFIGURACION ANTICIPOS EMPLADOS, DISTRIBUCION DE ANT. --
create table "fobos".rolt058
	(

		n58_compania		integer			not null,
		n58_num_prest		integer			not null,
		n58_proceso		char(2)			not null,
		n58_div_act		smallint		not null,
		n58_num_div		smallint		not null,
		n58_valor_dist		decimal(12,2)		not null,
		n58_saldo_dist		decimal(12,2)		not null,
		n58_usuario		varchar(10,5)		not null,
		n58_fecing		datetime year to second	not null

	) in datadbs lock mode row;
--

revoke all on "fobos".rolt058 from "public";

-- CREACION DE INDICES EN TABLA CONFIGURACION ANTICIPOS EMPLADOS --
create unique index "fobos".i01_pk_rolt058 on "fobos".rolt058
	(n58_compania, n58_num_prest, n58_proceso) in idxdbs;

create index "fobos".i01_fk_rolt058 on "fobos".rolt058
	(n58_compania, n58_num_prest) in idxdbs;

create index "fobos".i02_fk_rolt058 on "fobos".rolt058 (n58_proceso) in idxdbs;

create index "fobos".i03_fk_rolt058 on "fobos".rolt058 (n58_usuario) in idxdbs;
--

-- CREACION DE CONSTRAINTS EN TABLA CONFIGURACION ANTICIPOS EMPLADOS --
alter table "fobos".rolt058
	add constraint
		primary key (n58_compania, n58_num_prest, n58_proceso)
			constraint "fobos".pk_rolt058;

alter table "fobos".rolt058
	add constraint (foreign key (n58_compania, n58_num_prest)
			references "fobos".rolt045
			constraint "fobos".fk_01_rolt058);

alter table "fobos".rolt058
	add constraint (foreign key (n58_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt058);

alter table "fobos".rolt058
	add constraint (foreign key (n58_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rolt058);
--
--

-- CREACION DE TABLA RELACIONAL CONTABILIDAD/ANTICIPOS --
create table "fobos".rolt059
	(

		n59_compania		integer			not null,
		n59_num_prest		integer			not null,
		n59_tipo_comp		char(2)			not null,
		n59_num_comp		char(8)			not null

	) in datadbs lock mode row;
--

revoke all on "fobos".rolt059 from "public";

-- CREACION DE INDICES EN TABLA RELACIONAL CONTABILIDAD/ANTICIPOS --
create unique index "fobos".i01_pk_rolt059 on "fobos".rolt059
	(n59_compania, n59_num_prest, n59_tipo_comp, n59_num_comp) in idxdbs;

create index "fobos".i01_fk_rolt059 on "fobos".rolt059
	(n59_compania, n59_num_prest) in idxdbs;

create index "fobos".i02_fk_rolt059 on "fobos".rolt059
	(n59_compania, n59_tipo_comp, n59_num_comp) in idxdbs;
--

-- CREACION DE CONSTRAINTS EN TABLA RELACIONAL CONTABILIDAD/ANTICIPOS --
alter table "fobos".rolt059
	add constraint
		primary key (n59_compania, n59_num_prest, n59_tipo_comp,
				n59_num_comp)
			constraint "fobos".pk_rolt059;

alter table "fobos".rolt059
	add constraint (foreign key (n59_compania, n59_num_prest)
			references "fobos".rolt045
			constraint "fobos".fk_01_rolt059);

alter table "fobos".rolt059
	add constraint (foreign key (n59_compania, n59_tipo_comp, n59_num_comp)
			references "fobos".ctbt012
			constraint "fobos".fk_02_rolt059);
--
--

commit work;

drop table rolt074;

begin work;

create table "fobos".rolt074

	(
		n74_compania		integer			not null,
		n74_proceso		char(2)			not null,
		n74_num_acta		integer			not null,
		n74_estado		char(1)			not null,
		n74_ano_proceso		smallint		not null,
		n74_mes_proceso		smallint		not null,
		n74_cod_trab		integer			not null,
		n74_tipo_acta		smallint		not null,
		n74_fecha_ent		date			not null,
		n74_fecha_sal		date			not null,
		n74_ano_sect		smallint		not null,
		n74_sectorial		char(15)		not null,
		n74_sueldo_prom		decimal(12,2)		not null,
		n74_sueldo_ult		decimal(12,2)		not null,
		n74_dias_anio		smallint		not null,
		n74_desah_parc		char(1)			not null,
		n74_dias_desah_p	smallint		not null,
		n74_anios_desah		smallint		not null,
		n74_anios_desp		smallint		not null,
		n74_porc_desp		decimal(5,2)		not null,
		n74_motivo		varchar(60,40)		not null,
		n74_tot_ing		decimal(12,2)		not null,
		n74_tot_egr		decimal(12,2)		not null,
		n74_tot_neto		decimal(12,2)		not null,
		n74_tipo_pago		char(1)			not null,
		n74_bco_empresa		integer,
		n74_cta_empresa		char(15),
		n74_cta_trabaj		char(15),
		n74_tipo_comp		char(2),
		n74_num_comp		char(8),
		n74_usu_elimin		varchar(10,5),
		n74_fec_elimin		datetime year to second,
		n74_usuario		varchar(10,5)		not null,
		n74_fecing		datetime year to second	not null,

		check (n74_estado	in ("A", "P", "E"))
			constraint "fobos".ck_01_rolt074,

		check (n74_desah_parc	in ("S", "N"))
			constraint "fobos".ck_02_rolt074,

		check (n74_tipo_pago	in ("E", "C", "T"))
			constraint "fobos".ck_03_rolt074

	) in datadbs lock mode row;

revoke all on "fobos".rolt074 from "public";

create unique index "fobos".i01_pk_rolt074
	on "fobos".rolt074
		(n74_compania, n74_proceso, n74_num_acta)
	in idxdbs;

create index "fobos".i01_fk_rolt074
	on "fobos".rolt074
		(n74_proceso)
	in idxdbs;

create index "fobos".i02_fk_rolt074
	on "fobos".rolt074
		(n74_compania, n74_cod_trab)
	in idxdbs;

create index "fobos".i03_fk_rolt074
	on "fobos".rolt074
		(n74_compania, n74_tipo_acta)
	in idxdbs;

create index "fobos".i04_fk_rolt074
	on "fobos".rolt074
		(n74_compania, n74_ano_sect, n74_sectorial)
	in idxdbs;

create index "fobos".i05_fk_rolt074
	on "fobos".rolt074
		(n74_compania, n74_bco_empresa, n74_cta_empresa)
	in idxdbs;

create index "fobos".i06_fk_rolt074
	on "fobos".rolt074
		(n74_compania, n74_tipo_comp, n74_num_comp)
	in idxdbs;

create index "fobos".i07_fk_rolt074
	on "fobos".rolt074
		(n74_usu_elimin)
	in idxdbs;

create index "fobos".i08_fk_rolt074
	on "fobos".rolt074
		(n74_usuario)
	in idxdbs;

alter table "fobos".rolt074
	add constraint
		primary key (n74_compania, n74_proceso, n74_num_acta)
			constraint "fobos".pk_rolt074;

alter table "fobos".rolt074
	add constraint
		(foreign key (n74_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_01_rolt074);

alter table "fobos".rolt074
	add constraint
		(foreign key (n74_compania, n74_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_02_rolt074);

alter table "fobos".rolt074
	add constraint
		(foreign key (n74_compania, n74_tipo_acta)
			references "fobos".rolt073
			constraint "fobos".fk_03_rolt074);

alter table "fobos".rolt074
	add constraint
		(foreign key (n74_compania, n74_ano_sect, n74_sectorial)
			references "fobos".rolt017
			constraint "fobos".fk_04_rolt074);

alter table "fobos".rolt074
	add constraint
		(foreign key (n74_compania, n74_bco_empresa, n74_cta_empresa)
			references "fobos".gent009
			constraint "fobos".fk_05_rolt074);

alter table "fobos".rolt074
	add constraint
		(foreign key (n74_compania, n74_tipo_comp, n74_num_comp)
			references "fobos".ctbt012
			constraint "fobos".fk_06_rolt074);

alter table "fobos".rolt074
	add constraint
		(foreign key (n74_usu_elimin)
			references "fobos".gent005
			constraint "fobos".fk_07_rolt074);

alter table "fobos".rolt074
	add constraint
		(foreign key (n74_usuario)
			references "fobos".gent005
			constraint "fobos".fk_08_rolt074);

commit work;

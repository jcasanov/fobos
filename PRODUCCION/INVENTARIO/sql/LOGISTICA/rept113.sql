drop table rept113;

begin work;

create table "fobos".rept113

	(
		r113_compania		integer			not null,
		r113_localidad		smallint		not null,
		r113_num_hojrut		smallint		not null,
		r113_secuencia		smallint		not null,
		r113_guia_remision	decimal(15,0)		not null,
		r113_cod_tran		char(2)			not null,
		r113_num_tran		decimal(15,0)		not null,
		r113_cod_zona		smallint		not null,
		r113_cod_subzona	smallint		not null,
		r113_hora_lleg		datetime hour to second	not null,
		r113_hora_sali		datetime hour to second	not null,
		r113_recibido_por	varchar(40,20)		not null,
		r113_observacion	varchar(60,40)		not null

	) in datadbs lock mode row;

revoke all on "fobos".rept113 from "public";

create unique index "fobos".i01_pk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_num_hojrut, r113_secuencia)
	in idxdbs;

create index "fobos".i01_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_num_hojrut)
	in idxdbs;

create index "fobos".i02_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_guia_remision,
		 r113_cod_tran, r113_num_tran)
	in idxdbs;

create index "fobos".i03_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_cod_zona)
	in idxdbs;

create index "fobos".i04_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_cod_zona, r113_cod_subzona)
	in idxdbs;

alter table "fobos".rept113
	add constraint
		primary key (r113_compania, r113_localidad, r113_num_hojrut,
				r113_secuencia)
			constraint "fobos".pk_rept113;

alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_localidad, r113_num_hojrut)
			references "fobos".rept110
			constraint "fobos".fk_01_rept113);

alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_localidad, r113_guia_remision,
				 r113_cod_tran, r113_num_tran)
			references "fobos".rept097
			constraint "fobos".fk_02_rept113);

alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_localidad, r113_cod_zona)
			references "fobos".rept108
			constraint "fobos".fk_03_rept113);

alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_localidad, r113_cod_zona,
				r113_cod_subzona)
			references "fobos".rept109
			constraint "fobos".fk_04_rept113);

commit work;

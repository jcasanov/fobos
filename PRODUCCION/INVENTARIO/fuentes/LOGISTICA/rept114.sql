drop table rept114;

begin work;

create table "fobos".rept114

	(
		r114_compania		integer			not null,
		r114_localidad		smallint		not null,
		r114_num_hojrut		smallint		not null,
		r114_secuencia		smallint		not null,
		r114_guia_remision	decimal(15,0)		not null,
		--r114_cod_tran		char(2)			not null,
		--r114_num_tran		decimal(15,0)		not null,
		r114_cod_zona		smallint, --		not null,
		r114_cod_subzona	smallint, --		not null,
		r114_hora_lleg		datetime hour to second,
		r114_hora_sali		datetime hour to second,
		r114_recibido_por	varchar(40,20),
		r114_cod_obser		smallint,
		r114_estado		char(1)			not null,

		check (r114_estado in ("E", "N"))
			constraint "fobos".ck_01_rept114

	) in datadbs lock mode row;

revoke all on "fobos".rept114 from "public";

create unique index "fobos".i01_pk_rept114
	on "fobos".rept114
		(r114_compania, r114_localidad, r114_num_hojrut, r114_secuencia)
	in idxdbs;

create index "fobos".i01_fk_rept114
	on "fobos".rept114
		(r114_compania, r114_localidad, r114_num_hojrut)
	in idxdbs;

{--
create index "fobos".i02_fk_rept114
	on "fobos".rept114
		(r114_compania, r114_localidad, r114_guia_remision,
		 r114_cod_tran, r114_num_tran)
	in idxdbs;
--}

create index "fobos".i02_fk_rept114
	on "fobos".rept114
		(r114_compania, r114_localidad, r114_cod_zona)
	in idxdbs;

create index "fobos".i03_fk_rept114
	on "fobos".rept114
		(r114_compania, r114_localidad, r114_cod_zona, r114_cod_subzona)
	in idxdbs;

create index "fobos".i04_fk_rept114
	on "fobos".rept114
		(r114_compania, r114_localidad, r114_cod_obser)
	in idxdbs;

alter table "fobos".rept114
	add constraint
		primary key (r114_compania, r114_localidad, r114_num_hojrut,
				r114_secuencia)
			constraint "fobos".pk_rept114;

alter table "fobos".rept114
	add constraint
		(foreign key (r114_compania, r114_localidad, r114_num_hojrut)
			references "fobos".rept113
			constraint "fobos".fk_01_rept114);

{--
alter table "fobos".rept114
	add constraint
		(foreign key (r114_compania, r114_localidad, r114_guia_remision,
				 r114_cod_tran, r114_num_tran)
			references "fobos".rept097
			constraint "fobos".fk_02_rept114);
--}

alter table "fobos".rept114
	add constraint
		(foreign key (r114_compania, r114_localidad, r114_cod_zona)
			references "fobos".rept108
			constraint "fobos".fk_02_rept114);

alter table "fobos".rept114
	add constraint
		(foreign key (r114_compania, r114_localidad, r114_cod_zona,
				r114_cod_subzona)
			references "fobos".rept109
			constraint "fobos".fk_03_rept114);

alter table "fobos".rept114
	add constraint
		(foreign key (r114_compania, r114_localidad, r114_cod_obser)
			references "fobos".rept112
			constraint "fobos".fk_04_rept114);

commit work;

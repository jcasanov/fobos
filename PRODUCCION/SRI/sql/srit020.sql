create table "fobos".srit020
	(

		s20_compania		integer			not null,
		s20_tipo_tran		smallint		not null,
		s20_tipo_comp		smallint		not null

	) in datadbs lock mode row;

revoke all on "fobos".srit020 from "public";


create unique index "fobos".i01_pk_srit020
	on "fobos".srit020
		(s20_compania, s20_tipo_tran, s20_tipo_comp) in idxdbs;

create index "fobos".i01_fk_srit020
	on "fobos".srit020 (s20_compania, s20_tipo_tran) in idxdbs;

create index "fobos".i02_fk_srit020
	on "fobos".srit020 (s20_compania, s20_tipo_comp) in idxdbs;


alter table "fobos".srit020
	add constraint
		primary key
			(s20_compania, s20_tipo_tran, s20_tipo_comp)
			constraint pk_srit020;

alter table "fobos".srit020
	add constraint (foreign key (s20_compania, s20_tipo_tran)
			references "fobos".srit004
			constraint fk_01_srit020);

alter table "fobos".srit020
	add constraint (foreign key (s20_compania, s20_tipo_comp)
			references "fobos".srit005
			constraint fk_02_srit020);

drop table rept045;

begin work;

create table "fobos".rept045

	(

		r45_compania		integer			not null,
		r45_localidad		smallint		not null,
		r45_traspaso		integer			not null,
		r45_cod_tran		char(2)			not null,
		r45_num_tran		decimal(15,0)		not null,
		r45_usuario		varchar(10,5)		not null,
		r45_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept045 from "public";

create unique index "fobos".i01_pk_rept045
	on "fobos".rept045
		(r45_compania, r45_localidad, r45_traspaso, r45_cod_tran,
		 r45_num_tran)
	in idxdbs;

create index "fobos".i01_fk_rept045
	on "fobos".rept045
		(r45_compania, r45_localidad, r45_cod_tran, r45_num_tran)
	in idxdbs;

create index "fobos".i02_fk_rept045
	on "fobos".rept045
		(r45_compania, r45_localidad, r45_traspaso)
	in idxdbs;

create index "fobos".i03_fk_rept045
	on "fobos".rept045
		(r45_usuario)
	in idxdbs;

alter table "fobos".rept045
	add constraint
		primary key (r45_compania, r45_localidad, r45_traspaso,
				r45_cod_tran, r45_num_tran)
			constraint "fobos".pk_rept045;

alter table "fobos".rept045
	add constraint
		(foreign key (r45_compania, r45_localidad, r45_cod_tran,
				r45_num_tran)
			references "fobos".rept019
			constraint "fobos".fk_01_rept045);

alter table "fobos".rept045
	add constraint
		(foreign key (r45_compania, r45_localidad, r45_traspaso)
			references "fobos".rept043
			constraint "fobos".fk_02_rept045);

alter table "fobos".rept045
	add constraint
		(foreign key (r45_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rept045);

commit work;

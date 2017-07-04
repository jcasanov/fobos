--drop table rept041;

begin work;

create table "fobos".rept041
	(
		r41_compania		integer			not null,
		r41_localidad		smallint		not null,
		r41_cod_tran		char(2)			not null,
		r41_num_tran		decimal(15,0)		not null,
		r41_cod_tr		char(2)			not null,
		r41_num_tr		decimal(15,0)		not null

	) in datadbs lock mode row;

revoke all on "fobos".rept041 from "public";

create unique index "fobos".i01_pk_rept041 on "fobos".rept041
	(r41_compania, r41_localidad, r41_cod_tran, r41_num_tran, r41_cod_tr,
		r41_num_tr)
	in idxdbs;

create index "fobos".i01_fk_rept041 on "fobos".rept041
	(r41_compania, r41_localidad, r41_cod_tran, r41_num_tran) in idxdbs;

create index "fobos".i02_fk_rept041 on "fobos".rept041
	(r41_compania, r41_localidad, r41_cod_tr, r41_num_tr) in idxdbs;

alter table "fobos".rept041
	add constraint
		primary key (r41_compania, r41_localidad, r41_cod_tran,
				r41_num_tran, r41_cod_tr, r41_num_tr)
			constraint "fobos".pk_rept041;

commit work;

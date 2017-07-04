--drop table rept042;

begin work;

create table "fobos".rept042
	(
		r42_compania		integer			not null,
		r42_localidad		smallint		not null,
		r42_cod_tran		char(2)			not null,
		r42_num_tran		decimal(15,0)		not null,
		r42_cod_tr_re		char(2)			not null,
		r42_num_tr_re		decimal(15,0)		not null

	) in datadbs lock mode row;

revoke all on "fobos".rept042 from "public";

create unique index "fobos".i01_pk_rept042 on "fobos".rept042
	(r42_compania, r42_localidad, r42_cod_tran, r42_num_tran, r42_cod_tr_re,
		r42_num_tr_re)
	in idxdbs;

create index "fobos".i01_fk_rept042 on "fobos".rept042
	(r42_compania, r42_localidad, r42_cod_tran, r42_num_tran) in idxdbs;

create index "fobos".i02_fk_rept042 on "fobos".rept042
	(r42_compania, r42_localidad, r42_cod_tr_re, r42_num_tr_re) in idxdbs;

alter table "fobos".rept042
	add constraint
		primary key (r42_compania, r42_localidad, r42_cod_tran,
				r42_num_tran, r42_cod_tr_re, r42_num_tr_re)
			constraint "fobos".pk_rept042;

commit work;

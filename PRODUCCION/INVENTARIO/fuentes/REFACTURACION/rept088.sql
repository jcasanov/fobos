drop table "fobos".rept088;

create table "fobos".rept088
	(
		r88_compania		integer			not null,
		r88_localidad		smallint		not null,
		r88_cod_fact		char(2)			not null,
		r88_num_fact		decimal(15,0)		not null,
		r88_modulo		char(2)			not null,
		r88_motivo_refact	varchar(70,20)		not null,
		r88_numprev		integer			not null,
		r88_numprof		integer			not null,
		r88_cod_dev		char(2),
		r88_num_dev		decimal(15,0),
		r88_numprof_nue		integer,
		r88_numprev_nue		integer,
		r88_cod_fact_nue	char(2),
		r88_num_fact_nue	decimal(15,0),
		r88_codcli_nue		integer,
		r88_nomcli_nue		varchar(50,20),
		r88_usuario		varchar(10,5)		not null,
		r88_fecing		datetime year to second	not null
	);

create unique index "fobos".i01_pk_rept088 on "fobos".rept088
	(r88_compania, r88_localidad, r88_cod_fact, r88_num_fact);

create index "fobos".i01_fk_rept088 on "fobos".rept088 (r88_codcli_nue);

alter table "fobos".rept088
	add constraint
		primary key (r88_compania, r88_localidad, r88_cod_fact,
				r88_num_fact)
			constraint "fobos".pk_rept088;

alter table "fobos".rept088 lock mode (row);

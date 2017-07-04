begin work;

drop table "fobos".talt060;

create table "fobos".talt060
	(
		t60_compania		integer			not null,
		t60_localidad		smallint		not null,
		t60_num_fact		decimal(15,0)		not null,
		t60_motivo_refact	varchar(70,40)		not null,
		t60_ot_ant		integer			not null,
		t60_num_dev		decimal(15,0),
		t60_ot_nue		integer,
		t60_estado_nue		char(1)			not null,
		t60_codcli_nue		integer,
		t60_nomcli_nue		varchar(50,20),
		t60_usuario		varchar(10,5)		not null,
		t60_fecing		datetime year to second	not null,

		check (t60_estado_nue	in ('A', 'C', 'F', 'E', 'D', 'N'))
	);

create unique index "fobos".i01_pk_talt060 on "fobos".talt060
	(t60_compania, t60_localidad, t60_num_fact);

create index "fobos".i01_fk_talt060 on "fobos".talt060 (t60_codcli_nue);

alter table "fobos".talt060
	add constraint
		primary key (t60_compania, t60_localidad, t60_num_fact)
			constraint "fobos".pk_talt060;

alter table "fobos".talt060 lock mode (row);

commit work;

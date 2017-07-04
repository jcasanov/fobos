begin work;

create table "fobos".talt060
	(
		t60_compania		integer			not null,
		t60_localidad		smallint		not null,
		t60_ot_ant		integer			not null,
		t60_fac_ant		decimal(15,0)		not null,
		t60_motivo_refact	varchar(70,20)		not null,
		t60_num_dev		decimal(15,0),
		t60_ot_nue		integer,
		t60_fac_nue		decimal(15,0),
		t60_codcli_nue		integer,
		t60_nomcli_nue		varchar(100,50),
		t60_usuario		varchar(10,5)		not null,
		t60_fecing		datetime year to second	not null 
	) lock mode row;

    
create unique index "fobos".i01_pk_talt060 on "fobos".talt060
	(t60_compania, t60_localidad, t60_ot_ant) in idxdbs;

create index "fobos".i01_fk_talt060 on "fobos".talt060 (t60_compania) in idxdbs;

create index "fobos".i02_fk_talt060 on "fobos".talt060
	(t60_compania, t60_localidad) in idxdbs;

create index "fobos".i03_fk_talt060 on "fobos".talt060
	(t60_compania, t60_localidad, t60_num_dev) in idxdbs;

create index "fobos".i04_fk_talt060 on "fobos".talt060
	(t60_compania, t60_localidad, t60_ot_nue) in idxdbs;

create index "fobos".i05_fk_talt060 on "fobos".talt060
	(t60_codcli_nue) in idxdbs;

create index "fobos".i06_fk_talt060 on "fobos".talt060 (t60_usuario) in idxdbs;
    

alter table "fobos".talt060
	add constraint
		primary key (t60_compania, t60_localidad, t60_ot_ant)
			constraint "fobos".pk_talt060;

commit work;

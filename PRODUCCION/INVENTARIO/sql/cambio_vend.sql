drop table rept099;
drop table rept098;

begin work;

create table "fobos".rept098
	(

		r98_compania		integer			not null,
		r98_localidad		smallint		not null,
		r98_vend_ant		smallint		not null,
		r98_vend_nue		smallint		not null,
		r98_secuencia		integer			not null,
		r98_estado		char(1)			not null,
		r98_codcli		integer,
		r98_fecha_ini		date,
		r98_fecha_fin		date,
		r98_cod_tran		char(2),
		r98_num_tran		decimal(15,0),
		r98_usuario		varchar(10,5)		not null,
		r98_fecing		datetime year to second	not null,

		check (r98_estado in ('P', 'R'))
			constraint "fobos".ck_01_rept098

	) in datadbs lock mode row;


revoke all on "fobos".rept098 from "public";


create unique index "fobos".i01_pk_rept098
	on "fobos".rept098
		(r98_compania, r98_localidad, r98_vend_ant, r98_vend_nue,
			r98_secuencia)
		in idxdbs;

create index "fobos".i01_fk_rept098 on "fobos".rept098
	(r98_compania, r98_localidad, r98_cod_tran, r98_num_tran) in idxdbs;

create index "fobos".i02_fk_rept098 on "fobos".rept098 (r98_codcli) in idxdbs;

create index "fobos".i03_fk_rept098 on "fobos".rept098 (r98_usuario) in idxdbs;


alter table "fobos".rept098
	add constraint
		primary key (r98_compania, r98_localidad, r98_vend_ant,
				r98_vend_nue, r98_secuencia)
			constraint "fobos".pk_rept098;

alter table "fobos".rept098
	add constraint (foreign key (r98_compania, r98_localidad, r98_cod_tran,
					r98_num_tran)
			references "fobos".rept019
			constraint "fobos".fk_01_rept098);

alter table "fobos".rept098
	add constraint (foreign key (r98_codcli) references "fobos".cxct001
			constraint "fobos".fk_02_rept098);

alter table "fobos".rept098
	add constraint (foreign key (r98_usuario) references "fobos".gent005
			constraint "fobos".fk_03_rept098);


create table "fobos".rept099
	(

		r99_compania		integer			not null,
		r99_localidad		smallint		not null,
		r99_vend_ant		smallint		not null,
		r99_vend_nue		smallint		not null,
		r99_secuencia		integer			not null,
		r99_orden		smallint		not null,
		r99_cod_tran		char(2)			not null,
		r99_num_tran		decimal(15,0)		not null

	) in datadbs lock mode row;


revoke all on "fobos".rept099 from "public";


create unique index "fobos".i01_pk_rept099
	on "fobos".rept099
		(r99_compania, r99_localidad, r99_vend_ant, r99_vend_nue,
			r99_secuencia, r99_orden)
		in idxdbs;

create index "fobos".i01_fk_rept099
	on "fobos".rept099
		(r99_compania, r99_localidad, r99_vend_ant, r99_vend_nue,
			r99_secuencia)
		in idxdbs;

create index "fobos".i02_fk_rept099 on "fobos".rept099
	(r99_compania, r99_localidad, r99_cod_tran, r99_num_tran) in idxdbs;


alter table "fobos".rept099
	add constraint
		primary key (r99_compania, r99_localidad, r99_vend_ant,
				r99_vend_nue, r99_secuencia, r99_orden)
			constraint "fobos".pk_rept099;

alter table "fobos".rept099
	add constraint (foreign key (r99_compania, r99_localidad, r99_vend_ant,
				r99_vend_nue, r99_secuencia)
			references "fobos".rept098
			constraint "fobos".fk_01_rept099);

alter table "fobos".rept099
	add constraint (foreign key (r99_compania, r99_localidad, r99_cod_tran,
					r99_num_tran)
			references "fobos".rept019
			constraint "fobos".fk_02_rept099);

commit work;

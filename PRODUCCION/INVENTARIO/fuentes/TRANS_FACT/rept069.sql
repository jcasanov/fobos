drop table rept069;

begin work;

	create table "fobos".rept069

		(

		 r69_compania		integer			not null,
		 r69_localidad		smallint		not null,
		 r69_cod_tran		char(2)			not null,
		 r69_num_tran		decimal(15,0)		not null,
		 r69_loc_tr		smallint		not null,
		 r69_cod_tr		char(2)			not null,
		 r69_num_tr		decimal(15,0)		not null,
		 r69_fecing		datetime year to second	not null

		) in datadbs lock mode row;

	revoke all on "fobos".rept069 from "public";

	create unique index "fobos".i01_pk_rept069
		on "fobos".rept069
			(r69_compania, r69_localidad, r69_cod_tran,
			 r69_num_tran, r69_loc_tr, r69_cod_tr, r69_num_tr)
		in idxdbs;

	create index "fobos".i01_fk_rept069
		on "fobos".rept069
			(r69_compania, r69_localidad, r69_cod_tran,r69_num_tran)
		in idxdbs;

	create index "fobos".i02_fk_rept069
		on "fobos".rept069
			(r69_compania, r69_loc_tr, r69_cod_tr, r69_num_tr)
		in idxdbs;

	alter table "fobos".rept069
		add constraint
			primary key (r69_compania, r69_localidad, r69_cod_tran,
					r69_num_tran, r69_loc_tr, r69_cod_tr,
					r69_num_tr)
				constraint "fobos".pk_rept069;

commit work;

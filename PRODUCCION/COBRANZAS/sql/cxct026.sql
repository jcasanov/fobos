begin work;

	drop table "fobos".cxct026;

	create table "fobos".cxct026

		(

		 z26_compania				integer					not null,
		 z26_localidad				smallint				not null,
		 z26_codcli					integer					not null,
		 z26_banco					integer					not null,
		 z26_num_cta				char(15)				not null,
		 z26_num_cheque				char(15)				not null,
		 z26_secuencia				smallint				not null,
		 z26_estado					char(1)					not null,
		 z26_referencia				varchar(40,10)			not null,
		 z26_valor					decimal(12,2)			not null,
		 z26_fecha_cobro			date					not null,
		 z26_areaneg				smallint,
		 z26_tipo_doc				char(2),
		 z26_num_doc				char(15),
		 z26_dividendo				smallint,
		 z26_usuario				varchar(10,5)			not null,
		 z26_fecing					datetime year to second	not null

		) lock mode row;

	revoke all on "fobos".cxct026 from "public";

	create unique index "fobos".i01_pk_cxct026
		on "fobos".cxct026
			(z26_compania, z26_localidad, z26_codcli, z26_banco, z26_num_cta,
			 z26_num_cheque, z26_secuencia)
		in idxdbs;

	create index "fobos".i01_fk_cxct026
		on "fobos".cxct026
			(z26_compania, z26_localidad, z26_codcli, z26_tipo_doc, z26_num_doc,
			 z26_dividendo)
		in idxdbs;

	create index "fobos".i02_fk_cxct026
		on "fobos".cxct026
			(z26_compania, z26_localidad, z26_codcli)
		in idxdbs;

	create index "fobos".i03_fk_cxct026
		on "fobos".cxct026
			(z26_banco)
		in idxdbs;

	create index "fobos".i04_fk_cxct026
		on "fobos".cxct026
			(z26_compania, z26_areaneg)
		in idxdbs;

	create index "fobos".i05_fk_cxct026
		on "fobos".cxct026
			(z26_usuario)
		in idxdbs;

	alter table "fobos".cxct026
		add constraint
			primary key
				(z26_compania, z26_localidad, z26_codcli, z26_banco,
				 z26_num_cta, z26_num_cheque, z26_secuencia)
			constraint "fobos".pk_cxct026;

	alter table "fobos".cxct026
		add constraint
			(foreign key
				(z26_compania, z26_localidad, z26_codcli, z26_tipo_doc,
				 z26_num_doc, z26_dividendo)
			references "fobos".cxct020
			constraint "fobos".fk_01_cxct026);

	alter table "fobos".cxct026
		add constraint
			(foreign key
				(z26_compania, z26_localidad, z26_codcli)
			references "fobos".cxct002
			constraint "fobos".fk_02_cxct026);

	alter table "fobos".cxct026
		add constraint
			(foreign key
				(z26_banco)
			references "fobos".gent008
			constraint "fobos".fk_03_cxct026);

	alter table "fobos".cxct026
		add constraint
			(foreign key
				(z26_compania, z26_areaneg)
			references "fobos".gent003
			constraint "fobos".fk_04_cxct026);

	alter table "fobos".cxct026
		add constraint
			(foreign key
				(z26_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_cxct026);

	alter table "fobos".cxct026
		add constraint
			check
				(z26_estado in ('A', 'B', 'C'))
			constraint "fobos".ck_01_cxct026;

--rollback work;
commit work;

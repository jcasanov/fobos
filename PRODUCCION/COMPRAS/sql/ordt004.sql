drop table "fobos".ordt004;

begin work;

	create table "fobos".ordt004
		(

			c04_compania		integer					not null,
			c04_localidad		smallint				not null,
			c04_codprov			integer					not null,
			c04_cod_pedido		char(20)				not null,
			c04_fecha_vigen		date					not null,
			c04_pvp_prov_sug	decimal(13,4),
			c04_desc_prov		decimal(5,2),
			c04_costo_prov		decimal(13,4),
			c04_usuario			varchar(10,5)			not null,
			c04_fecing			datetime year to second	not null

		) in datadbs lock mode row;

	revoke all on "fobos".ordt004 from "public";

	create unique index "fobos".i01_pk_ordt004
		on "fobos".ordt004
			(c04_compania, c04_localidad, c04_codprov, c04_cod_pedido,
			 c04_fecha_vigen)
		in idxdbs;

	create index "fobos".i01_fk_ordt004
		on "fobos".ordt004
			(c04_compania)
		in idxdbs;

	create index "fobos".i02_fk_ordt004
		on "fobos".ordt004
			(c04_compania, c04_localidad)
		in idxdbs;

	create index "fobos".i03_fk_ordt004
		on "fobos".ordt004
			(c04_codprov)
		in idxdbs;

	create index "fobos".i04_fk_ordt004
		on "fobos".ordt004
			(c04_usuario)
		in idxdbs;

	alter table "fobos".ordt004
		add constraint
			primary key (c04_compania, c04_localidad, c04_codprov,
						 c04_cod_pedido, c04_fecha_vigen)
				constraint "fobos".pk_ordt004;

	alter table "fobos".ordt004
		add constraint
			(foreign key (c04_compania)
				references "fobos".ordt000
				constraint "fobos".fk_01_ordt004);

	alter table "fobos".ordt004
		add constraint
			(foreign key (c04_compania, c04_localidad)
				references "fobos".gent002
				constraint "fobos".fk_02_ordt004);

	alter table "fobos".ordt004
		add constraint
			(foreign key (c04_codprov)
				references "fobos".cxpt001
				constraint "fobos".fk_03_ordt004);

	alter table "fobos".ordt004
		add constraint
			(foreign key (c04_usuario)
				references "fobos".gent005
				constraint "fobos".fk_04_ordt004);

	alter table "fobos".ordt004
		add constraint
			check ((c04_pvp_prov_sug is null and c04_desc_prov is not null)
				or (c04_pvp_prov_sug is not null and c04_desc_prov is null))
			constraint "fobos".ck_01_ordt004;

--rollback work;
commit work;

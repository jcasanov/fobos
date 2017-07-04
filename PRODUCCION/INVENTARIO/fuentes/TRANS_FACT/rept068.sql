drop table rept068;

begin work;

	create table "fobos".rept068

		(

		 r68_compania		integer			not null,
		 r68_localidad		smallint		not null,
		 r68_cod_tran		char(2)			not null,
		 r68_num_tran		decimal(15,0)		not null,
		 r68_loc_tr		smallint		not null,
		 r68_cod_tr		char(2)			not null,
		 r68_num_tr		decimal(15,0)		not null,
		 r68_bodega		char(2)			not null,
		 r68_item		char(15)		not null,
		 r68_secuencia		smallint		not null,
		 r68_cantidad		decimal(8,2)		not null,
		 r68_usuario		varchar(10,5)		not null,
		 r68_fecing		datetime year to second	not null

		) in datadbs lock mode row;

	revoke all on "fobos".rept068 from "public";

	create unique index "fobos".i01_pk_rept068
		on "fobos".rept068
			(r68_compania, r68_localidad, r68_cod_tran,
			 r68_num_tran, r68_loc_tr, r68_cod_tr, r68_num_tr,
			 r68_bodega, r68_item, r68_secuencia)
		in idxdbs;

	create index "fobos".i01_fk_rept068
		on "fobos".rept068
			(r68_compania, r68_localidad, r68_cod_tran,r68_num_tran)
		in idxdbs;

	create index "fobos".i02_fk_rept068
		on "fobos".rept068
			(r68_compania, r68_loc_tr, r68_cod_tr, r68_num_tr)
		in idxdbs;

	create index "fobos".i03_fk_rept068
		on "fobos".rept068
			(r68_compania, r68_loc_tr, r68_cod_tr, r68_num_tr,
			 r68_bodega, r68_item, r68_secuencia)
		in idxdbs;

	create index "fobos".i04_fk_rept068
		on "fobos".rept068
			(r68_usuario)
		in idxdbs;

	alter table "fobos".rept068
		add constraint
			primary key (r68_compania, r68_localidad, r68_cod_tran,
					r68_num_tran, r68_loc_tr, r68_cod_tr,
					r68_num_tr, r68_bodega, r68_item,
					r68_secuencia)
				constraint "fobos".pk_rept068;

	alter table "fobos".rept068
		add constraint
			(foreign key (r68_compania, r68_localidad, r68_cod_tran,
					r68_num_tran)
				references "fobos".rept091
				constraint "fobos".fk_01_rept068);

	alter table "fobos".rept068
		add constraint
			(foreign key (r68_compania, r68_loc_tr, r68_cod_tr,
					r68_num_tr)
				references "fobos".rept019
				constraint "fobos".fk_02_rept068);

	alter table "fobos".rept068
		add constraint
			(foreign key (r68_compania, r68_loc_tr, r68_cod_tr,
					r68_num_tr, r68_bodega, r68_item,
					r68_secuencia)
				references "fobos".rept020
				constraint "fobos".fk_03_rept068);

	alter table "fobos".rept068
		add constraint
			(foreign key (r68_usuario)
				references "fobos".gent005
				constraint "fobos".fk_04_rept068);

commit work;

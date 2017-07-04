drop table "fobos".ctbt017;

begin work;

create table "fobos".ctbt017

	(

		b17_compania		integer			not null,
		b17_cuenta		char(12)		not null,
		b17_descripcion		varchar(40,20)		not null,
		b17_descri_alt		varchar(40,20),
		b17_estado		char(1)			not null,
		b17_tipo_cta		char(1)			not null,
		b17_tipo_mov		char(1)			not null,
		b17_nivel		smallint		not null,
		b17_cod_ccosto		smallint,
		b17_saldo_ma		char(1)			not null,
		b17_cuenta_fobos	char(12)		not null,
		b17_localidad		smallint		not null,
		b17_usuario		varchar(10,5)		not null,
		b17_fecing		datetime year to second	not null,

		check (b17_estado in ('A', 'B'))
			constraint "fobos".ck_01_ctbt017,
    
		check (b17_tipo_cta in ('B', 'R'))
			constraint "fobos".ck_02_ctbt017,
    
		check (b17_tipo_mov in ('D', 'C'))
			constraint "fobos".ck_03_ctbt017,
    
		check (b17_saldo_ma in ('S', 'N'))
			constraint "fobos".ck_04_ctbt017

	) in datadbs lock mode row;

revoke all on "fobos".ctbt017 from "public";

create unique index "fobos".i01_pk_ctbt017
	on "fobos".ctbt017
		(b17_compania, b17_cuenta)
	in idxdbs;

create index "fobos".i01_fk_ctbt017
	on "fobos".ctbt017
		(b17_compania) 
	in idxdbs;

create index "fobos".i02_fk_ctbt017
	on "fobos".ctbt017
		(b17_compania, b17_localidad) 
	in idxdbs;

create index "fobos".i03_fk_ctbt017
	on "fobos".ctbt017
		(b17_compania, b17_cuenta_fobos) 
	in idxdbs;

create index "fobos".i04_fk_ctbt017
	on "fobos".ctbt017
		(b17_nivel)
	in idxdbs;

create index "fobos".i05_fk_ctbt017
	on "fobos".ctbt017
		(b17_compania, b17_cod_ccosto)
	in idxdbs;

create index "fobos".i06_fk_ctbt017
	on "fobos".ctbt017
		(b17_usuario)
	in idxdbs;

alter table "fobos".ctbt017
	add constraint
		primary key (b17_compania, b17_cuenta)
			constraint "fobos".pk_ctbt017;

alter table "fobos".ctbt017
	add constraint
		(foreign key (b17_compania)
			references "fobos".ctbt000
			constraint "fobos".fk_01_ctbt017);

alter table "fobos".ctbt017
	add constraint
		(foreign key (b17_compania, b17_localidad)
			references "fobos".gent002
			constraint "fobos".fk_02_ctbt017);

alter table "fobos".ctbt017
	add constraint
		(foreign key (b17_compania, b17_cuenta_fobos)
			references "fobos".ctbt010
			constraint "fobos".fk_03_ctbt017);

alter table "fobos".ctbt017
	add constraint
		(foreign key (b17_nivel)
			references "fobos".ctbt001
			constraint "fobos".fk_04_ctbt017);

alter table "fobos".ctbt017
	add constraint
		(foreign key (b17_compania, b17_cod_ccosto)
			references "fobos".gent033
			constraint "fobos".fk_05_ctbt017);

alter table "fobos".ctbt017
	add constraint
		(foreign key (b17_usuario)
			references "fobos".gent005
			constraint "fobos".fk_06_ctbt017);

commit work;

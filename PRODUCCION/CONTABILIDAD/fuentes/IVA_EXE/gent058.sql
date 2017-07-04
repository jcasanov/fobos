drop table gent058;

begin work;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
create table "fobos".gent058

	(
		g58_compania		integer			not null,
		g58_localidad		smallint		not null,
		g58_tipo_impto		char(1)			not null,
		g58_porc_impto		decimal(5,2)		not null,
		g58_tipo		char(1)			not null,
		g58_estado		char(1)			not null,
		g58_desc_impto		varchar(40,20)		not null,
		g58_desc_abr		varchar(15,10)		not null,
		g58_impto_sist		char(1)			not null,
		g58_aux_cont		char(12),
		g58_usuario		varchar(10,5)		not null,
		g58_fecing		datetime year to second	not null,

		check (g58_tipo_impto in ('I', 'F'))
			constraint "fobos".ck_01_gent058,

		check (g58_tipo in ('V', 'C')) constraint "fobos".ck_02_gent058,

		check (g58_estado in ('A', 'B'))
			constraint "fobos".ck_03_gent058,

		check (g58_impto_sist in ('S', 'N'))
			constraint "fobos".ck_04_gent058

	) in datadbs lock mode row;

revoke all on "fobos".gent058 from "public";


create unique index "fobos".i01_pk_gent058 on "fobos".gent058
	(g58_compania, g58_localidad, g58_tipo_impto, g58_porc_impto, g58_tipo)
	in idxdbs;

create index "fobos".i01_fk_gent058 on "fobos".gent058 (g58_compania) in idxdbs;

create index "fobos".i02_fk_gent058 on "fobos".gent058
	(g58_compania, g58_localidad) in idxdbs;

create index "fobos".i03_fk_gent058 on "fobos".gent058
	(g58_compania, g58_aux_cont) in idxdbs;

create index "fobos".i04_fk_gent058 on "fobos".gent058 (g58_usuario) in idxdbs;


alter table "fobos".gent058
	add constraint
		primary key (g58_compania, g58_localidad, g58_tipo_impto,
				g58_porc_impto, g58_tipo)
			constraint "fobos".pk_gent058;

alter table "fobos".gent058
	add constraint (foreign key (g58_compania)
			references "fobos".gent001
			constraint "fobos".fk_01_gent058);

alter table "fobos".gent058
	add constraint (foreign key (g58_compania, g58_localidad)
			references "fobos".gent002
			constraint "fobos".fk_02_gent058);

alter table "fobos".gent058
	add constraint (foreign key (g58_compania, g58_aux_cont)
			references "fobos".ctbt010
			constraint "fobos".fk_03_gent058);

alter table "fobos".gent058
	add constraint (foreign key (g58_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_gent058);
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--
insert into gent058
	values(1, 1, 'I', 12.00, 'V', 'A', 'IVA 12%', 'IVA 12%', 'S', null,
		'FOBOS', current);
insert into gent058
	values(1, 1, 'I', 10.00, 'V', 'A', 'IVA 10%', 'IVA 10%', 'N', null,
		'FOBOS', current);
insert into gent058
	values(1, 1, 'I', 0.00, 'V', 'A', 'IVA 0%', 'IVA 0%', 'N', null,
		'FOBOS', current);

insert into gent058
	values(1, 2, 'I', 12.00, 'V', 'A', 'IVA 12%', 'IVA 12%', 'S', null,
		'FOBOS', current);
insert into gent058
	values(1, 2, 'I', 10.00, 'V', 'A', 'IVA 10%', 'IVA 10%', 'N', null,
		'FOBOS', current);
insert into gent058
	values(1, 2, 'I', 0.00, 'V', 'A', 'IVA 0%', 'IVA 0%', 'N', null,
		'FOBOS', current);
--

{--
insert into gent058
	values(1, 3, 'I', 12.00, 'V', 'A', 'IVA 12%', 'IVA 12%', 'S', null,
		'FOBOS', current);
insert into gent058
	values(1, 3, 'I', 10.00, 'V', 'A', 'IVA 10%', 'IVA 10%', 'N', null,
		'FOBOS', current);
insert into gent058
	values(1, 3, 'I', 0.00, 'V', 'A', 'IVA 0%', 'IVA 0%', 'N', null,
		'FOBOS', current);

insert into gent058
	values(1, 4, 'I', 12.00, 'V', 'A', 'IVA 12%', 'IVA 12%', 'S', null,
		'FOBOS', current);
insert into gent058
	values(1, 4, 'I', 10.00, 'V', 'A', 'IVA 10%', 'IVA 10%', 'N', null,
		'FOBOS', current);
insert into gent058
	values(1, 4, 'I', 0.00, 'V', 'A', 'IVA 0%', 'IVA 0%', 'N', null,
		'FOBOS', current);

insert into gent058
	values(1, 5, 'I', 12.00, 'V', 'A', 'IVA 12%', 'IVA 12%', 'S', null,
		'FOBOS', current);
insert into gent058
	values(1, 5, 'I', 10.00, 'V', 'A', 'IVA 10%', 'IVA 10%', 'N', null,
		'FOBOS', current);
insert into gent058
	values(1, 5, 'I', 0.00, 'V', 'A', 'IVA 0%', 'IVA 0%', 'N', null,
		'FOBOS', current);
--}

commit work;

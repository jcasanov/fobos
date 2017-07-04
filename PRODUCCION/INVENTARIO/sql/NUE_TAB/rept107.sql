drop table rept107;

begin work;

create table "fobos".rept107

	(
		r107_compania		integer			not null,
		r107_localidad		smallint		not null,
		r107_item		char(15)		not null,
		r107_categoria		char(2)			not null,
		r107_fec_ini		date			not null,
		r107_fec_fin		date			not null,
		r107_usuario		varchar(10,5)		not null,
		r107_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept107 from "public";

create unique index "fobos".i01_pk_rept107
	on "fobos".rept107
		(r107_compania, r107_localidad, r107_item, r107_categoria,
		 r107_fec_ini, r107_fec_fin)
	in idxdbs;

create index "fobos".i01_fk_rept107
	on "fobos".rept107
		(r107_compania, r107_item)
	in idxdbs;

create index "fobos".i02_fk_rept107
	on "fobos".rept107
		(r107_usuario)
	in idxdbs;

alter table "fobos".rept107
	add constraint
		primary key (r107_compania, r107_localidad, r107_item,
			     r107_categoria, r107_fec_ini, r107_fec_fin)
			constraint "fobos".pk_rept107;

alter table "fobos".rept107
	add constraint
		(foreign key (r107_compania, r107_item)
			references "fobos".rept010
			constraint "fobos".fk_01_rept107);

alter table "fobos".rept107
	add constraint
		(foreign key (r107_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rept107);

select r107_localidad loc, r107_item item, r107_categoria categoria,
	r107_fec_ini fec_ini, r107_fec_fin fec_fin, r107_fecing fecing,
	r107_usuario usuario
	from rept107
	where r107_compania = 999
	into temp t1;

load from "rept107.csv" delimiter "," insert into t1;

select loc, item, categoria, fec_ini, fec_fin, fecing, usuario
	from t1
	group by 1, 2, 3, 4, 5, 6, 7
	into temp t2;

drop table t1;

insert into rept107
	(r107_compania, r107_localidad, r107_item, r107_categoria,
	 r107_fec_ini, r107_fec_fin, r107_usuario, r107_fecing)
	select 1 cia, loc, item, categoria, fec_ini, fec_fin, usuario, fecing
		from t2;

drop table t2;

commit work;

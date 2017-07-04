drop table rept106;

begin work;

create table "fobos".rept106

	(
		r106_compania		integer			not null,
		r106_localidad		smallint		not null,
		r106_anio		smallint		not null,
		r106_mes		smallint		not null,
		r106_dia		smallint		not null,
		r106_porcentaje		decimal(16,6)		not null,
		r106_usuario		varchar(10,5)		not null,
		r106_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept106 from "public";

create unique index "fobos".i01_pk_rept106
	on "fobos".rept106
		(r106_compania, r106_localidad, r106_anio, r106_mes, r106_dia)
	in idxdbs;

create index "fobos".i01_fk_rept106
	on "fobos".rept106
		(r106_usuario)
	in idxdbs;

alter table "fobos".rept106
	add constraint
		primary key (r106_compania, r106_localidad, r106_anio,
			     r106_mes, r106_dia)
			constraint "fobos".pk_rept106;

alter table "fobos".rept106
	add constraint
		(foreign key (r106_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rept106);

select r106_compania cia, r106_localidad loc, r106_anio pl_anio,
	r106_mes pl_mes, r106_dia pl_dia, r106_porcentaje porc
	from rept106
	where r106_compania = 999
	into temp t1;

load from "rept106.csv" delimiter "," insert into t1;

insert into rept106
	(r106_compania, r106_localidad, r106_anio, r106_mes,
	 r106_dia, r106_porcentaje, r106_usuario, r106_fecing)
	select t1.*, "FOBOS", current
		from t1;

drop table t1;

commit work;

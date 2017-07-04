drop table rept100;

begin work;

create table "fobos".rept100

	(
		r100_compania		integer			not null,
		r100_cod_linea		smallint		not null,
		r100_descrip_lin	varchar(20,10)		not null,
		r100_estado		char(1)			not null,
		r100_usuario		varchar(10,5)		not null,
		r100_fecing		datetime year to second	not null,

		check (r100_estado in ("A", "B"))
			constraint "fobos".ck_01_rept100

	) in datadbs lock mode row;

revoke all on "fobos".rept100 from "public";

create unique index "fobos".i01_pk_rept100
	on "fobos".rept100
		(r100_compania, r100_cod_linea)
	in idxdbs;

create index "fobos".i01_fk_rept100
	on "fobos".rept100
		(r100_usuario)
	in idxdbs;

alter table "fobos".rept100
	add constraint
		primary key (r100_compania, r100_cod_linea)
			constraint "fobos".pk_rept100;

alter table "fobos".rept100
	add constraint
		(foreign key (r100_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rept100);

select r100_compania cia, r100_cod_linea lin, r100_descrip_lin descrip,
	r100_estado est
	from rept100
	where r100_compania = 999
	into temp t1;

load from "rept100.csv" delimiter "," insert into t1;

insert into rept100
	(r100_compania, r100_cod_linea, r100_descrip_lin, r100_estado,
	 r100_usuario, r100_fecing)
	select t1.*, "FOBOS", current
		from t1;

drop table t1;

commit work;

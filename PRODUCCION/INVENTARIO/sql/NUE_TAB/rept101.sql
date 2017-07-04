drop table rept101;

begin work;

create table "fobos".rept101

	(
		r101_compania		integer			not null,
		r101_cod_filtro		char(15)		not null,
		r101_descrip_fil	varchar(25,10)		not null,
		r101_estado		char(1)			not null,
		r101_usuario		varchar(10,5)		not null,
		r101_fecing		datetime year to second	not null,

		check (r101_estado in ("A", "B"))
			constraint "fobos".ck_01_rept101

	) in datadbs lock mode row;

revoke all on "fobos".rept101 from "public";

create unique index "fobos".i01_pk_rept101
	on "fobos".rept101
		(r101_compania, r101_cod_filtro)
	in idxdbs;

create index "fobos".i01_fk_rept101
	on "fobos".rept101
		(r101_usuario)
	in idxdbs;

alter table "fobos".rept101
	add constraint
		primary key (r101_compania, r101_cod_filtro)
			constraint "fobos".pk_rept101;

alter table "fobos".rept101
	add constraint
		(foreign key (r101_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rept101);

select r101_compania cia, r101_cod_filtro lin, r101_descrip_fil descrip,
	r101_estado est
	from rept101
	where r101_compania = 999
	into temp t1;

load from "rept101.csv" delimiter "," insert into t1;

insert into rept101
	(r101_compania, r101_cod_filtro, r101_descrip_fil, r101_estado,
	 r101_usuario, r101_fecing)
	select t1.*, "FOBOS", current
		from t1;

drop table t1;

commit work;

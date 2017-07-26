drop table rept105;

begin work;

create table "fobos".rept105

	(
		r105_compania		integer			not null,
		r105_localidad		smallint		not null,
		r105_cod_origen		char(15)		not null,
		r105_descrip_ori	varchar(25,10)		not null,
		r105_usuario		varchar(10,5)		not null,
		r105_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept105 from "public";

create unique index "fobos".i01_pk_rept105
	on "fobos".rept105
		(r105_compania, r105_localidad, r105_cod_origen)
	in idxdbs;

create index "fobos".i01_fk_rept105
	on "fobos".rept105
		(r105_usuario)
	in idxdbs;

alter table "fobos".rept105
	add constraint
		primary key (r105_compania, r105_localidad, r105_cod_origen)
			constraint "fobos".pk_rept105;

alter table "fobos".rept105
	add constraint
		(foreign key (r105_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rept105);

select r105_compania cia, r105_localidad loc, r105_cod_origen lin,
	r105_descrip_ori descrip
	from rept105
	where r105_compania = 999
	into temp t1;

load from "rept105.csv" delimiter "," insert into t1;

insert into rept105
	(r105_compania, r105_localidad, r105_cod_origen, r105_descrip_ori,
	 r105_usuario, r105_fecing)
	select t1.*, "FOBOS", current
		from t1;

drop table t1;

commit work;

--drop table rolt018;

begin work;

--------------------------------------------------------------------------------

create table "fobos".rolt018
	(

		n18_cod_rubro		smallint		not null,
		n18_flag_ident		char(2)			not null,
		n18_usuario		varchar(10,5)		not null,
		n18_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rolt018 from "public";

--------------------------------------------------------------------------------

create unique index "fobos".i01_pk_rolt018 on "fobos".rolt018
	(n18_cod_rubro, n18_flag_ident) in idxdbs;

create index "fobos".i01_fk_rolt018 on "fobos".rolt018
	(n18_cod_rubro) in idxdbs;

create index "fobos".i02_fk_rolt018 on "fobos".rolt018
	(n18_flag_ident) in idxdbs;

create index "fobos".i03_fk_rolt018 on "fobos".rolt018 (n18_usuario) in idxdbs;

--------------------------------------------------------------------------------

alter table "fobos".rolt018
	add constraint
		primary key (n18_cod_rubro, n18_flag_ident)
			constraint "fobos".pk_rolt018;

alter table "fobos".rolt018
	add constraint
		(foreign key (n18_cod_rubro)
			references "fobos".rolt006
			constraint "fobos".fk_01_rolt018);

alter table "fobos".rolt018
	add constraint
		(foreign key (n18_flag_ident)
			references "fobos".rolt016
			constraint "fobos".fk_02_rolt018);

alter table "fobos".rolt018
	add constraint
		(foreign key (n18_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rolt018);

--------------------------------------------------------------------------------

insert into rolt018
	select n06_cod_rubro, n06_flag_ident, "FOBOS", current
		from rolt006
		where n06_estado      = 'A'
		  and n06_flag_ident in ('AN', 'AI', 'AC');

--------------------------------------------------------------------------------

commit work;

select n18_cod_rubro cr, n06_nombre rubro, n18_flag_ident fl
        from rolt018, rolt006
        where n18_cod_rubro = n06_cod_rubro
	order by 2;

begin work;

--------------------------------------------------------------------------------
drop index "fobos".i01_pk_gent010;

alter table "fobos".gent010 drop constraint "fobos".pk_gent010;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".gent010
	add (g10_compania		integer		before g10_tarjeta);

alter table "fobos".gent010
	add (g10_cod_tarj		char(2)		before g10_nombre);

alter table "fobos".gent010
	add (g10_cont_cred		char(1)		before g10_nombre);

alter table "fobos".gent010
	add (g10_estado			char(1)		before g10_nombre);
--------------------------------------------------------------------------------


update gent010
	set g10_compania = (select g01_compania
				from gent001
				where g01_principal = 'S'),
	    g10_cod_tarj  = 'TJ',
	    g10_cont_cred = 'C',
	    g10_estado    = 'A'
	where 1 = 1;


--------------------------------------------------------------------------------
alter table "fobos".gent010
	modify (g10_compania		integer		not null);

alter table "fobos".gent010
	modify (g10_tarjeta		integer		not null);

alter table "fobos".gent010
	modify (g10_cod_tarj		char(2)		not null);

alter table "fobos".gent010
	modify (g10_cont_cred		char(1)		not null);

alter table "fobos".gent010
	modify (g10_estado		char(1)		not null);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_gent010
	on "fobos".gent010
		(g10_compania, g10_tarjeta, g10_cod_tarj, g10_cont_cred)
	in idxdbs;

create index "fobos".i02_fk_gent010
	on "fobos".gent010
		(g10_compania)
	in idxdbs;

create index "fobos".i03_fk_gent010
	on "fobos".gent010
		(g10_codcobr)
	in idxdbs;

create index "fobos".i04_fk_gent010
	on "fobos".gent010
		(g10_compania, g10_cod_tarj, g10_cont_cred)
	in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".gent010
	add constraint
		primary key (g10_compania, g10_tarjeta, g10_cod_tarj,
				g10_cont_cred)
			constraint "fobos".pk_gent010;

alter table "fobos".gent010
	add constraint
		(foreign key (g10_compania)
			references "fobos".gent001
			constraint "fobos".fk_02_gent010);

alter table "fobos".gent010
	add constraint
		(foreign key (g10_codcobr)
			references "fobos".cxct001
			constraint "fobos".fk_03_gent010);

alter table "fobos".gent010
	add constraint
		(foreign key (g10_compania, g10_cod_tarj, g10_cont_cred)
			references "fobos".cajt001
			constraint "fobos".fk_04_gent010);

alter table "fobos".gent010
	add constraint
		check (g10_estado in ('A', 'B'))
		constraint "fobos".ck_01_gent010;
--------------------------------------------------------------------------------

commit work;

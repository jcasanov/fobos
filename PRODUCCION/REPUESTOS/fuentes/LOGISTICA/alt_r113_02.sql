begin work;

alter table "fobos".rept113 drop r113_cod_ayud;

alter table "fobos".rept113 drop r113_areaneg;

alter table "fobos".rept113
	add (r113_cod_ayud	smallint	before r113_km_ini);

alter table "fobos".rept113
	add (r113_areaneg	smallint	before r113_usu_cierre);

update rept113
	set r113_areaneg = 1
	where 1 = 1;

alter table "fobos".rept113
	modify (r113_areaneg	smallint	not null);

create index "fobos".i04_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_localidad, r113_cod_trans, r113_cod_ayud)
	in idxdbs;

alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_localidad, r113_cod_trans,
				r113_cod_ayud)
			references "fobos".rept115
			constraint "fobos".fk_04_rept113);

create index "fobos".i05_fk_rept113
	on "fobos".rept113
		(r113_compania, r113_areaneg)
	in idxdbs;

alter table "fobos".rept113
	add constraint
		(foreign key (r113_compania, r113_areaneg)
			references "fobos".gent003
			constraint "fobos".fk_05_rept113);

commit work;

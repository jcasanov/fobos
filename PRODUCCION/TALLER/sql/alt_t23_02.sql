begin work;

alter table "fobos".talt023
	add (t23_fec_modifi	datetime year to second	before t23_usuario);
alter table "fobos".talt023
	add (t23_usu_modifi	varchar(10,5)		before t23_usuario);

create index "fobos".i15_fk_talt023
	on "fobos".talt023
		(t23_usu_modifi)
	in idxdbs;
alter table "fobos".talt023
	add constraint (foreign key (t23_usu_modifi)
			references "fobos".gent005
			constraint "fobos".fk_15_talt023);

alter table "fobos".talt023
	add (t23_fec_elimin	datetime year to second	before t23_usuario);
alter table "fobos".talt023
	add (t23_usu_elimin	varchar(10,5)		before t23_usuario);

create index "fobos".i16_fk_talt023
	on "fobos".talt023
		(t23_usu_elimin)
	in idxdbs;
alter table "fobos".talt023
	add constraint (foreign key (t23_usu_elimin)
			references "fobos".gent005
			constraint "fobos".fk_16_talt023);

update talt023
	set t23_fec_elimin = t23_fecing,
	    t23_usu_elimin = t23_usuario
	where t23_estado = 'E';

alter table "fobos".talt020
	add (t20_fec_modifi	datetime year to second	before t20_usuario);
alter table "fobos".talt020
	add (t20_usu_modifi	varchar(10,5)		before t20_usuario);

create index "fobos".i06_fk_talt020
	on "fobos".talt020
		(t20_usu_modifi)
	in idxdbs;
alter table "fobos".talt020
	add constraint (foreign key (t20_usu_modifi)
			references "fobos".gent005
			constraint "fobos".fk_06_talt020);

alter table "fobos".talt020
	add (t20_fec_elimin	datetime year to second	before t20_usuario);
alter table "fobos".talt020
	add (t20_usu_elimin	varchar(10,5)		before t20_usuario);

create index "fobos".i07_fk_talt020
	on "fobos".talt020
		(t20_usu_elimin)
	in idxdbs;
alter table "fobos".talt020
	add constraint (foreign key (t20_usu_elimin)
			references "fobos".gent005
			constraint "fobos".fk_07_talt020);

alter table "fobos".talt020
	drop constraint "fobos".c504_4590;
	--drop constraint "fobos".c441_3851;

alter table "fobos".talt020
	add constraint
		check (t20_estado in ('A', 'P', 'E'))
			constraint "fobos".ck_01_talt020;

commit work;

begin work;

alter table "fobos".talt007
	add (t07_dscmax_ger	decimal(4,2)	before t07_usuario);

alter table "fobos".talt007
	add (t07_dscmax_jef	decimal(4,2)	before t07_usuario);

alter table "fobos".talt007
	add (t07_dscmax_ven	decimal(4,2)	before t07_usuario);

alter table "fobos".talt007
	add (t07_modif_desc	char(1)		before t07_usuario);


update talt007
	set t07_dscmax_ger = 0.00,
	    t07_dscmax_jef = 0.00,
	    t07_dscmax_ven = 0.00,
	    t07_modif_desc = 'N'
	where 1 = 1;

alter table "fobos".talt007
	modify (t07_dscmax_ger	decimal(4,2)	not null);

alter table "fobos".talt007
	modify (t07_dscmax_jef	decimal(4,2)	not null);

alter table "fobos".talt007
	modify (t07_dscmax_ven	decimal(4,2)	not null);

alter table "fobos".talt007
	modify (t07_modif_desc	char(1)		not null);

alter table "fobos".talt007
	add constraint check (t07_modif_desc in ('S', 'N'))
		constraint "fobos".ck_03_talt007;

commit work;

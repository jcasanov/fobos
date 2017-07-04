begin work;

alter table "fobos".talt020
	add (t20_por_mo_tal	decimal(4,2)	before t20_total_impto);

alter table "fobos".talt020
	add (t20_vde_mo_tal	decimal(10,2)	before t20_total_impto);

update talt020
	set t20_por_mo_tal = 0.00,
	    t20_vde_mo_tal = 0.00
	where 1 = 1;

alter table "fobos".talt020
	modify (t20_por_mo_tal	decimal(4,2)	not null);

alter table "fobos".talt020
	modify (t20_vde_mo_tal	decimal(10,2)	not null);

commit work;

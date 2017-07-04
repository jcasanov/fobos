begin work;

alter table "fobos".talt021
	add (t21_porc_descto	decimal(4,2)	before t21_valor);

alter table "fobos".talt021
	add (t21_val_descto	decimal(10,2)	before t21_valor);

update talt021
	set t21_porc_descto = 0.00,
	    t21_val_descto  = 0.00
	where 1 = 1;

alter table "fobos".talt021
	modify (t21_porc_descto	decimal(4,2)	not null);

alter table "fobos".talt021
	modify (t21_val_descto	decimal(10,2)	not null);

commit work;

begin work;

alter table "fobos".talt024
	add (t24_porc_descto	decimal(4,2)	before t24_valor_tarea);

alter table "fobos".talt024
	add (t24_val_descto	decimal(10,2)	before t24_valor_tarea);

update talt024
	set t24_porc_descto = 0.00,
	    t24_val_descto  = 0.00
	where 1 = 1;

alter table "fobos".talt024
	modify (t24_porc_descto	decimal(4,2)	not null);

alter table "fobos".talt024
	modify (t24_val_descto	decimal(10,2)	not null);

commit work;

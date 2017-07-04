begin work;

alter table "fobos".actt001
	add (a01_aux_pago	char(12)	before a01_usuario);

alter table "fobos".actt001
	add (a01_aux_iva	char(12)	before a01_usuario);

alter table "fobos".actt001
	add (a01_aux_venta	char(12)	before a01_usuario);

alter table "fobos".actt001
	add (a01_aux_gasto	char(12)	before a01_usuario);


create index "fobos".i07_fk_actt001
	on "fobos".actt001
		(a01_compania, a01_aux_pago)
	in idxdbs;

create index "fobos".i08_fk_actt001
	on "fobos".actt001
		(a01_compania, a01_aux_iva)
	in idxdbs;

create index "fobos".i09_fk_actt001
	on "fobos".actt001
		(a01_compania, a01_aux_venta)
	in idxdbs;

create index "fobos".i10_fk_actt001
	on "fobos".actt001
		(a01_compania, a01_aux_gasto)
	in idxdbs;


alter table "fobos".actt001
	add constraint
		(foreign key (a01_compania, a01_aux_pago)
			references "fobos".ctbt010
			constraint "fobos".fk_07_actt001);

alter table "fobos".actt001
	add constraint
		(foreign key (a01_compania, a01_aux_iva)
			references "fobos".ctbt010
			constraint "fobos".fk_08_actt001);

alter table "fobos".actt001
	add constraint
		(foreign key (a01_compania, a01_aux_venta)
			references "fobos".ctbt010
			constraint "fobos".fk_09_actt001);

alter table "fobos".actt001
	add constraint
		(foreign key (a01_compania, a01_aux_gasto)
			references "fobos".ctbt010
			constraint "fobos".fk_10_actt001);

update actt001
	set a01_aux_pago = '11020101002'
	where 1 = 1;

update actt001
	set a01_aux_iva = '21040201005'
	where 1 = 1;

update actt001
	set a01_aux_venta = '41010101001'
	where 1 = 1;

update actt001
	set a01_aux_gasto = '41010101001'
	where 1 = 1;

commit work;

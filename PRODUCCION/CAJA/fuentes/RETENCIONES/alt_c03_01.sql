--alter table "fobos".ordt003 drop c03_tipo_fuente;

begin work;

alter table "fobos".ordt003
	add (c03_tipo_fuente		char(1)	before	c03_usuario_modifi);

update ordt003
	set c03_tipo_fuente = (select c02_tipo_fuente
				from ordt002
				where c02_compania   = c03_compania
				  and c02_tipo_ret   = c03_tipo_ret
				  and c02_porcentaje = c03_porcentaje)
	where 1 = 1;

alter table "fobos".ordt003
	modify (c03_tipo_fuente		char(1)		not null);

alter table "fobos".ordt003
	add constraint
		check (c03_tipo_fuente in ('B', 'S', 'T'))
			constraint "fobos".ck_04_ordt003;

commit work;

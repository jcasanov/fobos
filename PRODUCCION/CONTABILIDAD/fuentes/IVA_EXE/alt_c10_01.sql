begin work;

alter table "fobos".ordt010
	add (c10_cod_ice     smallint      before c10_usuario);
alter table "fobos".ordt010
	add (c10_porc_ice    decimal(5,2)  before c10_usuario);
alter table "fobos".ordt010
	add (c10_cod_ice_imp varchar(15,6) before c10_usuario);

alter table "fobos".ordt010
	add (c10_base_ice    decimal(12,2)  before c10_usuario);
alter table "fobos".ordt010
	add (c10_valor_ice   decimal(12,2)  before c10_usuario);

update ordt010
	set c10_base_ice  = 0.00,
	    c10_valor_ice = 0.00
	where 1 = 1;

alter table "fobos".ordt010 modify (c10_base_ice  decimal(12,2) not null);
alter table "fobos".ordt010 modify (c10_valor_ice decimal(12,2) not null);

create index "fobos".i11_fk_ordt010 on "fobos".ordt010
	(c10_compania, c10_cod_ice, c10_porc_ice, c10_cod_ice_imp,
	 c10_tipo_orden)
	in idxdbs;

{-- NO PONER ESTE CONSTRAINT
alter table "fobos".ordt010
	add constraint
		(foreign key (c10_compania, c10_cod_ice, c10_porc_ice,
				c10_cod_ice_imp, c10_tipo_orden)
			references "fobos".srit024
			constraint "fobos".fk_11_ordt010);
--}

commit work;

rollback work;
begin work;
alter table "fobos".ordt010 add (c10_cod_sust_sri char(2) before c10_usuario);
update ordt010
        set c10_cod_sust_sri = nvl((select s23_sustento_sri
                                        from srit023
                                        where s23_compania   = c10_compania
                                          and s23_tipo_orden = c10_tipo_orden
                                          and s23_tributa    = 'S'), '01')
	where 1 = 1;
alter table "fobos".ordt010 modify (c10_cod_sust_sri char(2) not null);
create index "fobos".i10_fk_ordt010 on "fobos".ordt010
        (c10_compania, c10_cod_sust_sri) in idxdbs;
alter table "fobos".ordt010
        add constraint
                (foreign key (c10_compania, c10_cod_sust_sri)
                        references "fobos".srit006
                        constraint "fobos".fk_10_ordt010);
commit work;
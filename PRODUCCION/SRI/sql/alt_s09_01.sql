begin work;

alter table "fobos".srit009 drop constraint "fobos".ck_01_srit009;

alter table "fobos".srit009
        add constraint check (s09_tipo_porc in ('S', 'B', 'T'))
                        constraint "fobos".ck_01_srit009;

commit work;

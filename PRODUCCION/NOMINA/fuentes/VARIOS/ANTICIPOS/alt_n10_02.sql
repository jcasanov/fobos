begin work;

alter table "fobos".rolt010 add (n10_fecha_ini date before n10_valor);

alter table "fobos".rolt010 add (n10_fecha_fin date before n10_valor);

commit work;

begin work;

alter table "fobos".rept113 modify (r113_km_ini	integer		not null);

alter table "fobos".rept113 modify (r113_km_fin	integer);

commit work;

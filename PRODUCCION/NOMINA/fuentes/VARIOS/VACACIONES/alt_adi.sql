begin work;

alter table "fobos".rolt047 add (n47_dias_real smallint before n47_dias_goza);

update "fobos".rolt047 set n47_dias_real = n47_dias_goza where 1 = 1;

alter table "fobos".rolt047 modify (n47_dias_real smallint not null);


alter table "fobos".rolt056 modify (n56_aux_iess char(12));

commit work;

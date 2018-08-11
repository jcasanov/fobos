begin work;

alter table "fobos".ordt001 modify (c01_nombre varchar(60,40) not null);

commit work;

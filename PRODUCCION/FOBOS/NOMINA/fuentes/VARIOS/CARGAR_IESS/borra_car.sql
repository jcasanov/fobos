drop table rolt027;
drop table rolt026;

drop index "fobos".i04_fk_rolt025;
alter table "fobos".rolt025
	drop constraint "fobos".fk_04_rolt025;

alter table "fobos".rolt025
	drop constraint "fobos".ck_02_rolt025;

drop table rolt025;
drop table rolt024;
drop table rolt023;
drop table rolt022;

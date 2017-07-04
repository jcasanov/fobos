begin work;

drop index "fobos".i11_fk_rept010;

drop index "fobos".i12_fk_rept010;

drop index "fobos".i13_fk_rept010;

drop index "fobos".i14_fk_rept010;

alter table "fobos".rept010 drop constraint r379_5472;

alter table "fobos".rept010 drop constraint r379_5473;

alter table "fobos".rept010 drop constraint r379_5474;

alter table "fobos".rept010 drop constraint r379_5475;

commit work;

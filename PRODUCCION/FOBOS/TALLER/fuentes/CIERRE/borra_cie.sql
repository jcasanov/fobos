begin work;

alter table "fobos".talt000 drop t00_dias_elim;

alter table "fobos".talt000 drop t00_elim_mes;

alter table "fobos".talt000 drop t00_dias_pres;

alter table "fobos".talt000 drop t00_anopro;

alter table "fobos".talt000 drop t00_mespro;

drop table talt042;

commit work

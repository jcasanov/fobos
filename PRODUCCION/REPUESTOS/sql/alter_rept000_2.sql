begin;
alter table rept000 add r00_fact_sstock char(1) before r00_anopro;
update rept000 set r00_fact_sstock = 'N' where 1=1;
alter table rept000 modify r00_fact_sstock char(1) not null;
alter table rept000 add constraint (check (r00_fact_sstock in ('S', 'N')));
commit;

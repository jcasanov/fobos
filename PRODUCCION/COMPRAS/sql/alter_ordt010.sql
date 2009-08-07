begin work;

alter table ordt010 drop constraint c198_1063;
alter table ordt010 add constraint (
     check (c10_estado in ('A', 'P', 'C', 'E'))
);

commit work;

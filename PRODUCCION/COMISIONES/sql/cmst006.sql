
create table "fobos".cmst006 
  (
    c06_compania integer not null ,
    c06_codcomi integer not null ,
    c06_modulo char(2) not null ,
    c06_vendedor smallint not null 
  );
revoke all on "fobos".cmst006 from "public";



create index "fobos".i01_fk_cmst006 on "fobos".cmst006 (c06_compania,
    c06_codcomi) using btree ;
create unique index "fobos".i01_pk_cmst006 on "fobos".cmst006 
    (c06_compania,c06_codcomi,c06_modulo,c06_vendedor) using 
    btree ;
alter table "fobos".cmst006 add constraint primary key (c06_compania,
    c06_codcomi,c06_modulo,c06_vendedor) constraint "fobos".pk_cmst006 
     ;
alter table "fobos".cmst006 add constraint (foreign key (c06_compania,
    c06_codcomi) references "fobos".cmst002 );


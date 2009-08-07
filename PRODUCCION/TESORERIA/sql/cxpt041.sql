
create table "fobos".cxpt041 
  (
    p41_compania integer not null ,
    p41_localidad smallint not null ,
    p41_codprov integer not null ,
    p41_tipo_doc char(2) not null ,
    p41_num_doc char(5) not null ,
    p41_dividendo integer not null ,
    p41_tipo_comp char(2) not null ,
    p41_num_comp char(8) not null 
  );
revoke all on "fobos".cxpt041 from "public";



create unique index "fobos".i01_pk_cxpt041 on "fobos".cxpt041 
    (p41_compania,p41_localidad,p41_codprov,p41_tipo_doc,p41_num_doc,
    p41_dividendo,p41_tipo_comp,p41_num_comp) using btree ;
alter table "fobos".cxpt041 add constraint primary key (p41_compania,
    p41_localidad,p41_codprov,p41_tipo_doc,p41_num_doc,p41_dividendo,
    p41_tipo_comp,p41_num_comp) constraint "fobos".pk_cxpt041 
     ;



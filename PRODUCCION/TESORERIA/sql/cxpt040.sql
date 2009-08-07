
create table "fobos".cxpt040 
  (
    p40_compania integer not null ,
    p40_localidad smallint not null ,
    p40_codprov integer not null ,
    p40_tipo_doc char(2) not null ,
    p40_num_doc integer not null ,
    p40_tipo_comp char(2) not null ,
    p40_num_comp char(8) not null 
  );
revoke all on "fobos".cxpt040 from "public";



create unique index "fobos".i01_pk_cxpt040 on "fobos".cxpt040 
    (p40_compania,p40_localidad,p40_codprov,p40_tipo_doc,p40_num_doc,
    p40_tipo_comp,p40_num_comp) using btree ;
alter table "fobos".cxpt040 add constraint primary key (p40_compania,
    p40_localidad,p40_codprov,p40_tipo_doc,p40_num_doc,p40_tipo_comp,
    p40_num_comp) constraint "fobos".pk_cxpt040  ;



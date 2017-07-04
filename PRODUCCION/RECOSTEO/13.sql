
DBSCHEMA Schema Utility       INFORMIX-SQL Version 9.40.UC7    
Copyright IBM Corporation 1996, 2004 All rights reserved
Software Serial Number AAA#B000000
{ TABLE "fobos".ctbt013 row size = 168 number of columns = 15 index size = 112 }
create table "fobos".ctbt013 
  (
    b13_compania integer not null ,
    b13_tipo_comp char(2) not null ,
    b13_num_comp char(8) not null ,
    b13_secuencia smallint not null ,
    b13_cuenta char(12) not null ,
    b13_tipo_doc char(3),
    b13_glosa varchar(90,40),
    b13_valor_base decimal(14,2) not null ,
    b13_valor_aux decimal(14,2) not null ,
    b13_num_concil integer,
    b13_filtro integer,
    b13_fec_proceso date not null ,
    b13_codcli integer,
    b13_codprov integer,
    b13_pedido char(10)
  );
revoke all on "fobos".ctbt013 from "public";



create index "fobos".i01_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_tipo_comp,b13_num_comp) using btree ;
create unique index "fobos".i01_pk_ctbt013 on "fobos".ctbt013 
    (b13_compania,b13_tipo_comp,b13_num_comp,b13_secuencia) using 
    btree ;
create index "fobos".i02_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_cuenta) using btree ;
create index "fobos".i03_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_num_concil) using btree ;
create index "fobos".i04_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_filtro) using btree ;
create index "fobos".idx_cta on "fobos".ctbt013 (b13_compania,
    b13_cuenta,b13_fec_proceso) using btree ;
alter table "fobos".ctbt013 add constraint primary key (b13_compania,
    b13_tipo_comp,b13_num_comp,b13_secuencia) constraint "fobos"
    .pk_ctbt013  ;




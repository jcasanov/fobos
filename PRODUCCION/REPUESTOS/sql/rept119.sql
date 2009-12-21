
create table "fobos".rept119 
  (
    r119_compania integer not null ,
    r119_localidad smallint not null ,
    r119_cod_factant char(2) not null ,
    r119_num_factant decimal(15,0) not null ,
    r119_cod_factnue char(2) not null,
    r119_num_factnue decimal(15,0) not null
  ) in datadbs;
revoke all on "fobos".rept119 from "public";

create unique index "fobos".i01_pk_rept119 on "fobos".rept119 
    (r119_compania,r119_localidad,r119_cod_factant,r119_num_factant
    ) using btree in idxdbs;
create        index "fobos".i01_fk_rept119 on "fobos".rept119 
    (r119_compania,r119_localidad,r119_cod_factnue,r119_num_factnue
    ) using btree in idxdbs;
    
alter table "fobos".rept119 add constraint primary key (r119_compania,
    r119_localidad,r119_cod_factant,r119_num_factant) 
    constraint "fobos".pk_rept119  ;

alter table "fobos".rept119 add constraint (foreign key (r119_compania,
    r119_localidad,r119_cod_factant,r119_num_factant) 
    references "fobos".rept019 );
alter table "fobos".rept119 add constraint (foreign key (r119_compania,
    r119_localidad,r119_cod_factnue,r119_num_factnue) 
    references "fobos".rept019 );




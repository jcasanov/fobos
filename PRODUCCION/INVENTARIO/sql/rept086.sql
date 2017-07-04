{ TABLE "fobos".rept086 row size = 56 number of columns = 8 index size = 76 }
create table "fobos".rept086 
  (
    r86_compania integer not null ,
    r86_codigo integer not null ,
    r86_secuencia integer not null ,
    r86_item char(15) not null ,
    r86_precio_mb decimal(11,2) not null ,
    r86_precio_ant decimal(11,2) not null ,
    r86_fec_camprec datetime year to second,
    r86_precio_nue decimal(11,2) not null 
  );
revoke all on "fobos".rept086 from "public";

create unique index "fobos".i01_pk_rept086 on "fobos".rept086 
    (r86_compania,r86_codigo,r86_secuencia);
create index "fobos".i01_fk_rept086 on "fobos".rept086 (r86_compania,
    r86_codigo);
create index "fobos".i02_fk_rept086 on "fobos".rept086 (r86_compania,
    r86_item);
alter table "fobos".rept086 add constraint primary key (r86_compania,
    r86_codigo,r86_secuencia) constraint "fobos".pk_rept086  ;
    

alter table "fobos".rept086 add constraint (foreign key (r86_compania,
    r86_codigo) references "fobos".rept085 );





begin work;

drop table cxpt005;
create table "fobos".cxpt005
  (
    p05_compania integer not null ,
    p05_codprov integer not null ,
    p05_tipo_ret char(1) not null ,
    p05_porcentaje decimal(5,2) not null
  ) lock mode row;
revoke all on "fobos".cxpt005 from "public";

alter table cxpt005 add p05_codigo_sri char(3) before p05_tipo_ret;
update cxpt005 set p05_codigo_sri = '---' where 1 = 1;
alter table cxpt005 modify p05_codigo_sri char(3) not null;


unload to 'cxpt026_data.unl' select * from cxpt026;
drop table cxpt026;
create table "fobos".cxpt026
  (
    p26_compania integer not null ,
    p26_localidad smallint not null ,
    p26_orden_pago integer not null ,
    p26_secuencia smallint not null ,
    p26_tipo_ret char(1) not null ,
    p26_porcentaje decimal(5,2) not null ,
    p26_valor_base decimal(12,2) not null ,
    p26_valor_ret decimal(11,2) not null
  ) lock mode row;
revoke all on "fobos".cxpt026 from "public";
load from 'cxpt026_data.unl' insert into cxpt026;

alter table cxpt026 add p26_codigo_sri char(3) before p26_tipo_ret;
update cxpt026 set p26_codigo_sri = '---' where 1 = 1;
alter table cxpt026 modify p26_codigo_sri char(3) not null;


unload to 'ordt002_data.unl' select * from ordt002;
drop table ordt002;
create table "fobos".ordt002
  (
    c02_compania integer not null ,
    c02_tipo_ret char(1) not null ,
    c02_porcentaje decimal(5,2) not null ,
    c02_estado char(1) not null ,
    c02_nombre varchar(20,10) not null ,
    c02_tipo_fuente char(1) not null ,
    c02_codigo_sri char(3),
    c02_aux_cont char(12) not null ,
    c02_usuario varchar(10,5) not null ,
    c02_fecing datetime year to second not null ,
    check (c02_tipo_ret IN ('F' ,'I' )),
    check (c02_estado IN ('A' ,'B' )),
    check (c02_tipo_fuente IN ('B' ,'S' ,'T' ))
  ) lock mode row;
revoke all on "fobos".ordt002 from "public";
load from 'ordt002_data.unl' insert into ordt002;

update ordt002 set c02_estado = 'B' where 1 = 1;

alter table ordt002 drop c02_codigo_sri;
alter table ordt002 add c02_codigo_sri char(3) before c02_tipo_ret;
update ordt002 set c02_codigo_sri = '---' where 1 = 1;
alter table ordt002 modify c02_codigo_sri char(3) not null;


create index "fobos".i01_fk_ordt002 on "fobos".ordt002 (c02_compania)
    using btree ;
create unique index "fobos".i01_pk_ordt002 on "fobos".ordt002
    (c02_compania,c02_codigo_sri,c02_tipo_ret,c02_porcentaje) using btree ;
create index "fobos".i02_fk_ordt002 on "fobos".ordt002 (c02_compania,
    c02_aux_cont) using btree ;
create index "fobos".i03_fk_ordt002 on "fobos".ordt002 (c02_usuario)
    using btree ;
alter table "fobos".ordt002 add constraint primary key (c02_compania,
    c02_codigo_sri,c02_tipo_ret,c02_porcentaje) constraint "fobos".pk_ordt002
     ;
alter table "fobos".ordt002 add constraint (foreign key (c02_compania,
    c02_aux_cont) references "fobos".ctbt010 );

alter table "fobos".ordt002 add constraint (foreign key (c02_compania)
    references "fobos".ordt000 );

alter table "fobos".ordt002 add constraint (foreign key (c02_usuario)
    references "fobos".gent005 );



create index "fobos".i01_fk_cxpt005 on "fobos".cxpt005 (p05_compania)
    using btree ;
create unique index "fobos".i01_pk_cxpt005 on "fobos".cxpt005
    (p05_compania,p05_codprov,p05_codigo_sri,p05_tipo_ret,p05_porcentaje) using
    btree ;
create index "fobos".i02_fk_cxpt005 on "fobos".cxpt005 (p05_codprov)
    using btree ;
create index "fobos".i03_fk_cxpt005 on "fobos".cxpt005 (p05_compania,
   p05_codigo_sri,p05_tipo_ret,p05_porcentaje) using btree ;
alter table "fobos".cxpt005 add constraint primary key (p05_compania,
    p05_codprov,p05_codigo_sri,p05_tipo_ret,p05_porcentaje) constraint "fobos"
    .pk_cxpt005  ;
alter table "fobos".cxpt005 add constraint (foreign key (p05_compania)
    references "fobos".cxpt000 );

alter table "fobos".cxpt005 add constraint (foreign key (p05_codprov)
    references "fobos".cxpt001 );

alter table "fobos".cxpt005 add constraint (foreign key (p05_compania,
   p05_codigo_sri,p05_tipo_ret,p05_porcentaje) references "fobos".ordt002 );


create index "fobos".i01_fk_cxpt026 on "fobos".cxpt026 (p26_compania,
    p26_codigo_sri,p26_tipo_ret,p26_porcentaje) using btree ;
create unique index "fobos".i01_pk_cxpt026 on "fobos".cxpt026
    (p26_compania,p26_localidad,p26_orden_pago,p26_secuencia,
  p26_codigo_sri,p26_tipo_ret,p26_porcentaje) using btree ;
create index "fobos".i02_fk_cxpt026 on "fobos".cxpt026 (p26_compania,
    p26_localidad,p26_orden_pago,p26_secuencia) using btree ;

alter table "fobos".cxpt026 add constraint primary key (p26_compania,
    p26_localidad,p26_orden_pago,p26_secuencia,p26_codigo_sri,p26_tipo_ret,
    p26_porcentaje)
    constraint "fobos".pk_cxpt026  ;
alter table "fobos".cxpt026 add constraint (foreign key (p26_compania,
   p26_codigo_sri,p26_tipo_ret,p26_porcentaje) references "fobos".ordt002 );


alter table "fobos".cxpt026 add constraint (foreign key (p26_compania,
    p26_localidad,p26_orden_pago,p26_secuencia) references "fobos".cxpt025 );

alter table "fobos".cxpt028 add p28_codigo_sri char(3) before p28_tipo_ret;
update "fobos".cxpt028 set p28_codigo_sri = '---' where 1 = 1;
alter table "fobos".cxpt028 modify p28_codigo_sri char(3) not null;

create index "fobos".i03_fk_cxpt028 on "fobos".cxpt028 (p28_compania,
    p28_codigo_sri,p28_tipo_ret,p28_porcentaje) using btree ;
alter table "fobos".cxpt028 add constraint (foreign key (p28_compania,
   p28_codigo_sri,p28_tipo_ret,p28_porcentaje) references "fobos".ordt002 );

commit work;

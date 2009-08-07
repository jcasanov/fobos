
create table "fobos".cxct101 
  (
    z101_compania integer not null ,
    z101_localidad smallint not null ,
	z101_numero_sol integer not null,
    z101_secuencia smallint not null ,
    z101_codigo_pago char(2) not null ,
    z101_moneda char(2) not null ,
    z101_paridad decimal(17,10) not null ,
    z101_valor decimal(12,2) not null ,
    z101_cod_bco_tarj smallint,
    z101_num_ch_aut varchar(15),
    z101_num_cta_tarj varchar(25)
  );
revoke all on "fobos".cxct101 from "public";

create index "fobos".i01_fk_cxct101 on "fobos".cxct101 (z101_compania,
    z101_localidad,z101_numero_sol);
create unique index "fobos".i01_pk_cxct101 on "fobos".cxct101 
    (z101_compania,z101_localidad,z101_numero_sol,z101_secuencia);
create index "fobos".i02_fk_cxct101 on "fobos".cxct101 (z101_compania,
    z101_codigo_pago);
create index "fobos".i03_fk_cxct101 on "fobos".cxct101 (z101_moneda);
    
alter table "fobos".cxct101 add constraint primary key (z101_compania,
    z101_localidad,z101_numero_sol,z101_secuencia) 
    constraint "fobos".pk_cxct101  ;

alter table "fobos".cxct101 add constraint (foreign key (z101_compania,
    z101_localidad,z101_numero_sol) references 
    "fobos".cxct024 );

alter table "fobos".cxct101 add constraint (foreign key (z101_moneda) 
    references "fobos".gent013 );

alter table "fobos".cxct101 add constraint (foreign key (z101_compania, z101_codigo_pago) 
    references "fobos".cajt001 );




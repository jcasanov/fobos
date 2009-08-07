begin work;

create table "fobos".ordt100 
  (
    c100_compania integer not null ,
    c100_localidad smallint not null ,
    c100_numero_oc integer not null ,
    c100_tipo_orden integer not null ,
    c100_cod_depto smallint not null ,
    c100_solicitado varchar(25,15) not null ,
--    c100_estado char(1) not null ,
    c100_codprov integer not null ,
    c100_atencion varchar(25,15) not null ,
    c100_referencia varchar(120,20) not null ,
--    c100_usua_aprob varchar(10,5),
--    c100_fecha_aprob datetime year to second,
--    c100_fecha_entre datetime year to second,
    c100_ord_trabajo integer,
    c100_recargo decimal(4,2) not null ,
    c100_porc_descto decimal(4,2) not null ,
    c100_porc_impto decimal(4,2) not null ,
    c100_moneda char(2) not null ,
    c100_paridad decimal(17,10) not null ,
    c100_precision smallint not null ,
    c100_tipo_pago char(1) not null ,
    c100_interes decimal(4,2) not null ,
    c100_tot_repto decimal(12,2) not null ,
    c100_tot_mano decimal(12,2) not null ,
    c100_tot_dscto decimal(12,2) not null ,
    c100_tot_impto decimal(11,2) not null ,
    c100_tot_compra decimal(12,2) not null ,
--    c100_factura char(15),
--    c100_fecha_fact date,
--    c100_usuario varchar(10,5) not null ,
--    c100_fecing datetime year to second not null ,
    
--    check (c100_estado IN ('A' ,'P' ,'C' )),
    
    check (c100_precision IN (0 ,1 ,2 )),
    
    check (c100_tipo_pago IN ('C' ,'R' ))
) lock mode row;
revoke all on "fobos".ordt100 from "public";



create index "fobos".i01_fk_ordt100 on "fobos".ordt100 (c100_compania) 
    using btree ;
create unique index "fobos".i01_pk_ordt100 on "fobos".ordt100 
    (c100_compania,c100_localidad,c100_numero_oc) using btree ;
create index "fobos".i02_fk_ordt100 on "fobos".ordt100 (c100_compania,
    c100_localidad) using btree ;
create index "fobos".i03_fk_ordt100 on "fobos".ordt100 (c100_tipo_orden) 
    using btree ;
create index "fobos".i04_fk_ordt100 on "fobos".ordt100 (c100_compania,
    c100_cod_depto) using btree ;
create index "fobos".i05_fk_ordt100 on "fobos".ordt100 (c100_compania,
    c100_localidad,c100_codprov) using btree ;
create index "fobos".i06_fk_ordt100 on "fobos".ordt100 (c100_compania,
    c100_localidad,c100_ord_trabajo) using btree ;
create index "fobos".i07_fk_ordt100 on "fobos".ordt100 (c100_moneda) 
    using btree ;
alter table "fobos".ordt100 add constraint primary key (c100_compania,
    c100_localidad,c100_numero_oc) constraint "fobos".pk_ordt100 
     ;
alter table "fobos".ordt100 add constraint (foreign key (c100_compania) 
    references "fobos".ordt000 );

alter table "fobos".ordt100 add constraint (foreign key (c100_compania,
    c100_localidad) references "fobos".gent002 );

alter table "fobos".ordt100 add constraint (foreign key (c100_tipo_orden) 
    references "fobos".ordt001 );

alter table "fobos".ordt100 add constraint (foreign key (c100_compania,
    c100_cod_depto) references "fobos".gent034 );

alter table "fobos".ordt100 add constraint (foreign key (c100_compania,
    c100_localidad,c100_codprov) references "fobos".cxpt002 );


alter table "fobos".ordt100 add constraint (foreign key (c100_compania,
    c100_localidad,c100_ord_trabajo) references "fobos".talt023 
    );

alter table "fobos".ordt100 add constraint (foreign key (c100_moneda) 
    references "fobos".gent013 );




create table "fobos".ordt101 
  (
    c101_compania integer not null ,
    c101_localidad smallint not null ,
    c101_numero_oc integer not null ,
    c101_secuencia smallint not null ,
    c101_tipo char(1) not null ,
    c101_cant_ped smallint not null ,
    c101_cant_rec smallint not null ,
    c101_codigo char(15) not null ,
    c101_descrip varchar(60,30) not null ,
    c101_descuento decimal(4,2) not null ,
    c101_paga_iva char(1) not null ,
    c101_val_descto decimal(18,10) not null ,
    c101_val_impto decimal(18,10) not null ,
    c101_precio decimal(20,10) not null ,
    
    check (c101_tipo IN ('B' ,'S' )),
    
    check (c101_paga_iva IN ('S' ,'N' ))
) lock mode row;
revoke all on "fobos".ordt101 from "public";



create index "fobos".i01_fk_ordt101 on "fobos".ordt101 (c101_compania,
    c101_localidad,c101_numero_oc) using btree ;
create unique index "fobos".i01_pk_ordt101 on "fobos".ordt101 
    (c101_compania,c101_localidad,c101_numero_oc,c101_secuencia) 
    using btree ;
alter table "fobos".ordt101 add constraint primary key (c101_compania,
    c101_localidad,c101_numero_oc,c101_secuencia) constraint "fobos"
    .pk_ordt101  ;
alter table "fobos".ordt101 add constraint (foreign key (c101_compania,
    c101_localidad,c101_numero_oc) references "fobos".ordt100 );
    




create table "fobos".ordt102 
  (
    c102_compania integer not null ,
    c102_localidad smallint not null ,
    c102_numero_oc integer not null ,
    c102_dividendo smallint not null ,
    c102_fecha_vcto date not null ,
    c102_valor_cap decimal(12,2) not null ,
    c102_valor_int decimal(12,2) not null 
) lock mode row;
revoke all on "fobos".ordt102 from "public";



create index "fobos".i01_fk_ordt102 on "fobos".ordt102 (c102_compania,
    c102_localidad,c102_numero_oc) using btree ;
create unique index "fobos".i01_pk_ordt102 on "fobos".ordt102 
    (c102_compania,c102_localidad,c102_numero_oc,c102_dividendo) 
    using btree ;
alter table "fobos".ordt102 add constraint primary key (c102_compania,
    c102_localidad,c102_numero_oc,c102_dividendo) constraint "fobos"
    .pk_ordt102  ;
alter table "fobos".ordt102 add constraint (foreign key (c102_compania,
    c102_localidad,c102_numero_oc) references "fobos".ordt100 );
    


-- Esta tabla es para mantener la relacion entre OC periodicas y OC generadas

create table "fobos".ordt103 (
    c103_compania integer not null ,
    c103_localidad smallint not null ,
    c103_oc_per integer not null ,
    c103_oc_gen integer not null 
) lock mode row;

create unique index "fobos".i01_pk_ordt103 on "fobos".ordt103 (c103_compania,
    c103_localidad,c103_oc_per, c103_oc_gen) using btree ;

create index "fobos".i01_fk_ordt103 on "fobos".ordt103 (c103_compania,
    c103_localidad,c103_oc_per) using btree ;
create index "fobos".i02_fk_ordt103 on "fobos".ordt103 (c103_compania,
    c103_localidad,c103_oc_gen) using btree ;

alter table "fobos".ordt103 add constraint primary key (c103_compania,
    c103_localidad,c103_oc_per,c103_oc_gen) constraint "fobos".pk_ordt103  ;

alter table "fobos".ordt103 add constraint (foreign key (c103_compania,
    c103_localidad,c103_oc_per) references "fobos".ordt100 );
alter table "fobos".ordt103 add constraint (foreign key (c103_compania,
    c103_localidad,c103_oc_gen) references "fobos".ordt010 );

commit work;

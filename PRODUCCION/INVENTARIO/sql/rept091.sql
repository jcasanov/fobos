{ TABLE "fobos".rept091 row size = 329 number of columns = 37 index size = 31 }
create table "fobos".rept091 
  (
    r91_compania integer not null ,
    r91_localidad smallint not null ,
    r91_cod_tran char(2) not null ,
    r91_num_tran decimal(15,0) not null ,
    r91_cod_subtipo integer,
    r91_cont_cred char(1) not null ,
    r91_ped_cliente char(10),
    r91_referencia varchar(40,20),
    r91_codcli integer,
    r91_nomcli varchar(50,20) not null ,
    r91_dircli varchar(40,20) not null ,
    r91_telcli char(10),
    r91_cedruc char(15) not null ,
    r91_vendedor smallint not null ,
    r91_oc_externa varchar(15,8),
    r91_oc_interna integer,
    r91_ord_trabajo integer,
    r91_descuento decimal(4,2) not null ,
    r91_porc_impto decimal(4,2) not null ,
    r91_tipo_dev char(2),
    r91_num_dev decimal(15,0),
    r91_bodega_ori char(2) not null ,
    r91_bodega_dest char(2) not null ,
    r91_fact_costo decimal(9,2),
    r91_fact_venta decimal(9,2),
    r91_moneda char(2) not null ,
    r91_paridad decimal(16,9) not null ,
    r91_precision smallint not null ,
    r91_tot_costo decimal(12,2) not null ,
    r91_tot_bruto decimal(12,2) not null ,
    r91_tot_dscto decimal(11,2) not null ,
    r91_tot_neto decimal(12,2) not null ,
    r91_flete decimal(11,2) not null ,
    r91_numliq integer,
    r91_num_ret integer,
    r91_usuario varchar(10,5) not null ,
    r91_fecing datetime year to second not null ,
    
    check (r91_cont_cred IN ('C' ,'R' )),
    
    check (r91_precision IN (0 ,1 ,2 ))
  );
revoke all on "fobos".rept091 from "public";

create unique index "fobos".i01_pk_rept091 on "fobos".rept091 
    (r91_compania,r91_localidad,r91_cod_tran,r91_num_tran);
alter table "fobos".rept091 add constraint primary key (r91_compania,
    r91_localidad,r91_cod_tran,r91_num_tran) constraint "fobos"
    .pk_rept091  ;





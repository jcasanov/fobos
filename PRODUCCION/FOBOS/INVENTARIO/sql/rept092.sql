{ TABLE "fobos".rept092 row size = 158 number of columns = 27 index size = 91 }
create table "fobos".rept092 
  (
    r92_compania integer not null ,
    r92_localidad smallint not null ,
    r92_cod_tran char(2) not null ,
    r92_num_tran decimal(15,0) not null ,
    r92_bodega char(2) not null ,
    r92_item char(15) not null ,
    r92_orden smallint not null ,
    r92_cant_ped decimal(8,2) not null ,
    r92_cant_ven decimal(8,2) not null ,
    r92_cant_dev decimal(8,2) not null ,
    r92_cant_ent decimal(8,2) not null ,
    r92_descuento decimal(4,2) not null ,
    r92_val_descto decimal(10,2) not null ,
    r92_precio decimal(13,4) not null ,
    r92_val_impto decimal(11,2) not null ,
    r92_costo decimal(13,4) not null ,
    r92_fob decimal(11,2) not null ,
    r92_linea char(5) not null ,
    r92_rotacion char(2) not null ,
    r92_ubicacion char(10) not null ,
    r92_costant_mb decimal(11,2) not null ,
    r92_costant_ma decimal(11,2) not null ,
    r92_costnue_mb decimal(11,2) not null ,
    r92_costnue_ma decimal(11,2) not null ,
    r92_stock_ant decimal(8,2) not null ,
    r92_stock_bd decimal(8,2) not null ,
    r92_fecing datetime year to second not null ,
    primary key (r92_compania,r92_localidad,r92_cod_tran,r92_num_tran,r92_bodega,r92_item,r92_orden) 
               constraint "fobos".pk_rept092
  );
revoke all on "fobos".rept092 from "public";


alter table "fobos".rept092 add constraint (foreign key (r92_compania,
    r92_localidad,r92_cod_tran,r92_num_tran) references "fobos"
    .rept091 );





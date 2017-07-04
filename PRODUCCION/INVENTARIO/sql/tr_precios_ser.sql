create table "fobos".tr_precios_ser 
  (
    te_compania smallint not null ,
    te_item char(15) not null ,
    te_precio decimal(12,2) not null ,
    te_marca char(6) not null 
  )lock mode row;
revoke all on "fobos".tr_precios_ser from "public";


create unique index "fobos".i1_tr_precios_ser on "fobos".tr_precios_ser 
    (te_compania,te_item) in idxdbs;

create unique index "fobos".i2_tr_precios_ser on "fobos".tr_precios_ser 
    (te_compania,te_item,te_marca) in idxdbs;




{ TABLE "fobos".tr_stock_uio row size = 22 number of columns = 3 index size = 31 }
create table "fobos".tr_stock_uio 
  (
    te_bodega char(2) not null ,
    te_item char(15) not null ,
    te_stock decimal(8,2) not null 
  );
revoke all on "fobos".tr_stock_uio from "public";

create unique index "fobos".i1_tr_stock_uio on "fobos".tr_stock_uio (te_bodega,
    te_item);





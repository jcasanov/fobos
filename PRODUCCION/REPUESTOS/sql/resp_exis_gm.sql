{ TABLE "fobos".resp_exis row size = 99 number of columns = 16 index size = 70 }
create table "fobos".resp_exis 
  (
    r11_compania integer not null ,
    r11_bodega char(2) not null ,
    r11_item char(15) not null ,
    r11_ubicacion char(10) not null ,
    r11_ubica_ant char(10),
    r11_stock_ant decimal(8,2) not null ,
    r11_stock_act decimal(8,2) not null ,
    r11_ing_dia decimal(8,2) not null ,
    r11_egr_dia decimal(8,2) not null ,
    r11_fec_ultvta date,
    r11_tip_ultvta char(2),
    r11_num_ultvta decimal(15,0),
    r11_fec_ulting date,
    r11_tip_ulting char(2),
    r11_num_ulting decimal(15,0),
    r11_fec_corte datetime year to second not null 
  )  extent size 10353 next size 1035 lock mode row;
revoke all on "fobos".resp_exis from "public";



create index "fobos".i01_fk_resp_exis on "fobos".resp_exis (r11_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_resp_exis on "fobos".resp_exis 
    (r11_compania,r11_bodega,r11_item) using btree  in idxdbs 
    ;
create index "fobos".i02_fk_resp_exis on "fobos".resp_exis (r11_compania,
    r11_bodega) using btree  in idxdbs ;
create index "fobos".i03_fk_resp_exis on "fobos".resp_exis (r11_compania,
    r11_item) using btree  in idxdbs ;
alter table "fobos".resp_exis add constraint primary key (r11_compania,
    r11_bodega,r11_item) constraint "fobos".pk_resp_exis  ;
alter table "fobos".resp_exis add constraint (foreign key (r11_compania) 
    references "fobos".rept000 );





create table "fobos".rept011 
  (
    r11_compania integer not null ,
    r11_bodega char(2) not null ,
    r11_item char(15) not null ,
    r11_ubicacion char(10) not null ,
    r11_ubica_ant char(10),
    r11_stock_ant smallint not null ,
    r11_stock_act smallint not null ,
    r11_ing_dia smallint not null ,
    r11_egr_dia smallint not null ,
    r11_fec_ultvta date,
    r11_tip_ultvta char(2),
    r11_num_ultvta decimal(15,0),
    r11_fec_ulting date,
    r11_tip_ulting char(2),
    r11_num_ulting decimal(15,0)
  );
create unique index "fobos".i01_pk_rept011 on "fobos".rept011 
    (r11_compania,r11_bodega,r11_item) in idxdbs;
create index "fobos".i01_fk_rept011 on "fobos".rept011 (r11_compania) in idxdbs;
    
create index "fobos".i02_fk_rept011 on "fobos".rept011 (r11_compania,
    r11_bodega) in idxdbs;
create index "fobos".i03_fk_rept011 on "fobos".rept011 (r11_compania,
    r11_item) in idxdbs;
alter table "fobos".rept011 add constraint primary key (r11_compania,
    r11_bodega,r11_item) constraint "fobos".pk_rept011;
alter table "fobos".rept011 add constraint (foreign key (r11_compania) 
    references "fobos".rept000 );

alter table "fobos".rept011 add constraint (foreign key (r11_compania,
    r11_bodega) references "fobos".rept002 );

alter table "fobos".rept011 add constraint (foreign key (r11_compania,
    r11_item) references "fobos".rept010 );




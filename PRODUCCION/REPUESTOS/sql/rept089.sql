{ TABLE "fobos".rept089 row size = 106 number of columns = 18 index size = 176 }
create table "fobos".rept089 
  (
    r89_compania integer not null ,
    r89_localidad smallint not null ,
    r89_bodega char(2) not null ,
    r89_item char(15) not null ,
    r89_usuario varchar(10,5) not null ,
    r89_anio smallint not null ,
    r89_mes smallint not null ,
    r89_secuencia integer not null ,
    r89_stock_act decimal(8,2) not null ,
    r89_fec_corte datetime year to second not null ,
    r89_bueno decimal(8,2) 
        default 0.00 not null ,
    r89_incompleto decimal(8,2) 
        default 0.00 not null ,
    r89_mal_est decimal(8,2) 
        default 0.00 not null ,
    r89_suma decimal(8,2) 
        default 0.00 not null ,
    r89_fecha date not null ,
    r89_usu_modifi varchar(10,5),
    r89_fec_modifi datetime year to second,
    r89_fecing datetime year to second not null 
  )  extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept089 from "public";



create index "fobos".i01_fk_rept089 on "fobos".rept089 (r89_compania) 
    using btree  in idxdbs ;
create unique index "fobos".i01_pk_rept089 on "fobos".rept089 
    (r89_compania,r89_localidad,r89_bodega,r89_item,r89_usuario,
    r89_anio,r89_mes) using btree  in idxdbs ;
create index "fobos".i02_fk_rept089 on "fobos".rept089 (r89_compania,
    r89_localidad) using btree  in idxdbs ;
create index "fobos".i03_fk_rept089 on "fobos".rept089 (r89_compania,
    r89_bodega) using btree  in idxdbs ;
create index "fobos".i04_fk_rept089 on "fobos".rept089 (r89_compania,
    r89_item) using btree  in idxdbs ;
create index "fobos".i05_fk_rept089 on "fobos".rept089 (r89_compania,
    r89_bodega,r89_item) using btree  in idxdbs ;
create index "fobos".i06_fk_rept089 on "fobos".rept089 (r89_usuario) 
    using btree  in idxdbs ;
create index "fobos".i07_fk_rept089 on "fobos".rept089 (r89_usu_modifi) 
    using btree  in idxdbs ;
create index "fobos".i08_fk_rept089 on "fobos".rept089 (r89_usuario,
    r89_secuencia) using btree  in idxdbs ;
alter table "fobos".rept089 add constraint primary key (r89_compania,
    r89_localidad,r89_bodega,r89_item,r89_usuario,r89_anio,r89_mes) 
    constraint "fobos".pk_rept089  ;
alter table "fobos".rept089 add constraint (foreign key (r89_compania) 
    references "fobos".rept000 );

alter table "fobos".rept089 add constraint (foreign key (r89_compania,
    r89_localidad) references "fobos".gent002 );

alter table "fobos".rept089 add constraint (foreign key (r89_compania,
    r89_bodega) references "fobos".rept002 );

alter table "fobos".rept089 add constraint (foreign key (r89_compania,
    r89_item) references "fobos".rept010 );

alter table "fobos".rept089 add constraint (foreign key (r89_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept089 add constraint (foreign key (r89_usu_modifi) 
    references "fobos".gent005 );





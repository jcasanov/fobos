{ TABLE "fobos".te_stofis row size = 79 number of columns = 13 index size = 177 }
create table "fobos".te_stofis 
  (
    te_compania integer not null ,
    te_localidad smallint not null ,
    te_bodega char(2) not null ,
    te_item char(15) not null ,
    te_stock_act decimal(8,2) not null ,
    te_bueno decimal(8,2) 
        default 0.00 not null ,
    te_incompleto decimal(8,2) 
        default 0.00 not null ,
    te_mal_est decimal(8,2) 
        default 0.00 not null ,
    te_suma decimal(8,2) 
        default 0.00 not null ,
    te_fecha date not null ,
    te_fec_modifi datetime year to second,
    te_usuario varchar(10,5) not null ,
    te_fecing datetime year to second not null 
  );
revoke all on "fobos".te_stofis from "public";

create index "fobos".i01_fk_te_stofis on "fobos".te_stofis (te_compania);
    
create index "fobos".i02_fk_te_stofis on "fobos".te_stofis (te_compania,
    te_localidad);
create unique index "fobos".i01_pk_te_stofis on "fobos".te_stofis 
    (te_compania,te_localidad,te_bodega,te_item);
create index "fobos".i03_fk_te_stofis on "fobos".te_stofis (te_compania,
    te_bodega);
create index "fobos".i04_fk_te_stofis on "fobos".te_stofis (te_compania,
    te_item);
create index "fobos".i05_fk_te_stofis on "fobos".te_stofis (te_compania,
    te_bodega,te_item);
create index "fobos".i06_fk_te_stofis on "fobos".te_stofis (te_usuario);
    
alter table "fobos".te_stofis add constraint primary key (te_compania,
    te_localidad,te_bodega,te_item) constraint "fobos".pk_te_stofis 
     ;

alter table "fobos".te_stofis add constraint (foreign key (te_compania) 
    references "fobos".rept000 );

alter table "fobos".te_stofis add constraint (foreign key (te_compania,
    te_localidad) references "fobos".gent002 );

alter table "fobos".te_stofis add constraint (foreign key (te_compania,
    te_bodega) references "fobos".rept002 );

alter table "fobos".te_stofis add constraint (foreign key (te_compania,
    te_item) references "fobos".rept010 );

alter table "fobos".te_stofis add constraint (foreign key (te_usuario) 
    references "fobos".gent005 );





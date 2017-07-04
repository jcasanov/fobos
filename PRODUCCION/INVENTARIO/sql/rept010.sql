{ TABLE "fobos".rept010 row size = 533 number of columns = 51 index size = 306 }
create table "fobos".rept010 
  (
    r10_compania integer not null ,
    r10_codigo char(15) not null ,
    r10_nombre varchar(70,20) not null ,
    r10_estado char(1) not null ,
    r10_tipo smallint not null ,
    r10_peso decimal(7,3) not null ,
    r10_uni_med char(7) not null ,
    r10_cantpaq decimal(8,2) not null ,
    r10_cantveh decimal(8,2) not null ,
    r10_partida varchar(15,8) not null ,
    r10_modelo varchar(20,5) not null ,
    r10_cod_pedido char(20),
    r10_cod_comerc char(15),
    r10_cod_util char(5) not null ,
    r10_linea char(5) not null ,
    r10_sub_linea char(2) not null ,
    r10_cod_grupo char(4) not null ,
    r10_cod_clase char(8) not null ,
    r10_marca char(6) not null ,
    r10_rotacion char(2) not null ,
    r10_paga_impto char(1) not null ,
    r10_fob decimal(13,4) not null ,
    r10_monfob char(2) not null ,
    r10_precio_mb decimal(11,2) not null ,
    r10_precio_ma decimal(11,2) not null ,
    r10_costo_mb decimal(11,2) not null ,
    r10_costo_ma decimal(11,2) not null ,
    r10_costult_mb decimal(11,2) not null ,
    r10_costult_ma decimal(11,2) not null ,
    r10_costrepo_mb decimal(11,2),
    r10_usu_cosrepo varchar(10,5),
    r10_fec_cosrepo datetime year to second,
    r10_cantped decimal(8,2) not null ,
    r10_cantback decimal(8,2) not null ,
    r10_comentarios varchar(120),
    r10_precio_ant decimal(11,2) not null ,
    r10_fec_camprec datetime year to second,
    r10_proveedor integer,
    r10_filtro char(10),
    r10_electrico char(13),
    r10_color char(10),
    r10_serie_lote char(1),
    r10_stock_max integer,
    r10_stock_min integer,
    r10_vol_cuft decimal(5,2),
    r10_dias_mant integer,
    r10_dias_inv integer,
    r10_sec_item integer not null ,
    r10_usuario varchar(10,5) not null ,
    r10_fecing datetime year to second not null ,
    r10_feceli datetime year to second,
    
    check (r10_estado IN ('A' ,'B' ,'S' )),
    
    check (r10_paga_impto IN ('S' ,'N' )),
    
    check (r10_serie_lote IN ('S' ,'L' ,'G' ))
  ) extent size 19120 next size 1912 lock mode row;
revoke all on "fobos".rept010 from "public";

create index "fobos".i10_fk_rept010 on "fobos".rept010 (r10_compania,
    r10_cod_util) in idxdbs ;
create index "fobos".i01_fk_rept010 on "fobos".rept010 (r10_compania) 
    in idxdbs ;
create unique index "fobos".i01_pk_rept010 on "fobos".rept010 
    (r10_compania,r10_codigo) in idxdbs ;
create index "fobos".i02_fk_rept010 on "fobos".rept010 (r10_tipo) 
    in idxdbs ;
create index "fobos".i03_fk_rept010 on "fobos".rept010 (r10_uni_med) 
    in idxdbs ;
create index "fobos".i04_fk_rept010 on "fobos".rept010 (r10_partida) 
    in idxdbs ;
create index "fobos".i05_fk_rept010 on "fobos".rept010 (r10_compania,
    r10_linea) in idxdbs ;
create index "fobos".i06_fk_rept010 on "fobos".rept010 (r10_compania,
    r10_rotacion) in idxdbs ;
create index "fobos".i07_fk_rept010 on "fobos".rept010 (r10_monfob) 
    in idxdbs ;
create index "fobos".i08_fk_rept010 on "fobos".rept010 (r10_usuario) 
    in idxdbs ;
create index "fobos".i9_co_rept010 on "fobos".rept010 (r10_compania,
    r10_filtro) in idxdbs ;
alter table "fobos".rept010 add constraint primary key (r10_compania,
    r10_codigo) constraint "fobos".pk_rept010  ;

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_cod_util) references "fobos".rept077 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania) 
    references "fobos".rept000 );

alter table "fobos".rept010 add constraint (foreign key (r10_tipo) 
    references "fobos".rept006 );

alter table "fobos".rept010 add constraint (foreign key (r10_uni_med) 
    references "fobos".rept005 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_linea) references "fobos".rept003 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_rotacion) references "fobos".rept004 );

alter table "fobos".rept010 add constraint (foreign key (r10_monfob) 
    references "fobos".gent013 );

alter table "fobos".rept010 add constraint (foreign key (r10_usuario) 
    references "fobos".gent005 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_linea,r10_sub_linea) references "fobos".rept070 );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_linea,r10_sub_linea,r10_cod_grupo) references "fobos".rept071 
    );

alter table "fobos".rept010 add constraint (foreign key (r10_compania,
    r10_linea,r10_sub_linea,r10_cod_grupo,r10_cod_clase) references 
    "fobos".rept072 );

alter table "fobos".rept010 add constraint (foreign key (r10_partida) 
    references "fobos".gent016 );





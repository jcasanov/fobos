{ TABLE "fobos".actt010 row size = 212 number of columns = 30 index size = 193 }
create table "fobos".actt010 
  (
    a10_compania integer not null ,
    a10_codigo_bien integer not null ,
    a10_estado char(1) not null ,
    a10_descripcion varchar(40,20) not null ,
    a10_grupo_act smallint not null ,
    a10_tipo_act smallint not null ,
    a10_anos_util smallint not null ,
    a10_porc_deprec decimal(4,2) not null ,
    a10_modelo varchar(15),
    a10_serie varchar(25),
    a10_locali_ori smallint not null ,
    a10_numero_oc integer,
    a10_localidad smallint not null ,
    a10_cod_depto smallint not null ,
    a10_codprov integer not null ,
    a10_fecha_comp date not null ,
    a10_moneda char(2) not null ,
    a10_paridad decimal(16,9) not null ,
    a10_valor decimal(12,2) not null ,
    a10_valor_mb decimal(12,2) not null ,
    a10_responsable smallint,
    a10_fecha_baja date,
    a10_val_dep_mb decimal(11,2) not null ,
    a10_val_dep_ma decimal(11,2) not null ,
    a10_tot_dep_mb decimal(12,2) not null ,
    a10_tot_dep_ma decimal(12,2) not null ,
    a10_tot_reexpr decimal(12,2) not null ,
    a10_tot_dep_ree decimal(12,2) not null ,
    a10_usuario varchar(10,5) not null ,
    a10_fecing datetime year to second not null ,
    
    check (a10_estado IN ('A' ,'B' ,'V' ,'D' ,'S' ,'E' ))
  );
revoke all on "fobos".actt010 from "public";

create index "fobos".i01_fk_actt010 on "fobos".actt010 (a10_compania);
    
create unique index "fobos".i01_pk_actt010 on "fobos".actt010 
    (a10_compania,a10_codigo_bien);
create index "fobos".i02_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_grupo_act);
create index "fobos".i03_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_tipo_act);
create index "fobos".i04_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_locali_ori);
create index "fobos".i05_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_localidad);
create index "fobos".i06_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_locali_ori,a10_numero_oc);
create index "fobos".i07_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_cod_depto);
create index "fobos".i08_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_locali_ori,a10_codprov);
create index "fobos".i09_fk_actt010 on "fobos".actt010 (a10_moneda);
    
create index "fobos".i10_fk_actt010 on "fobos".actt010 (a10_compania,
    a10_responsable);
create index "fobos".i11_fk_actt010 on "fobos".actt010 (a10_usuario);
    
alter table "fobos".actt010 add constraint primary key (a10_compania,
    a10_codigo_bien) constraint "fobos".pk_actt010  ;

alter table "fobos".actt010 add constraint (foreign key (a10_compania) 
    references "fobos".actt000 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_grupo_act) references "fobos".actt001 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_tipo_act) references "fobos".actt002 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori) references "fobos".gent002 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_localidad) references "fobos".gent002 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori,a10_numero_oc) references "fobos".ordt010 );
    

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_cod_depto) references "fobos".gent034 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_locali_ori,a10_codprov) references "fobos".cxpt002 );

alter table "fobos".actt010 add constraint (foreign key (a10_moneda) 
    references "fobos".gent013 );

alter table "fobos".actt010 add constraint (foreign key (a10_compania,
    a10_responsable) references "fobos".actt003 );

alter table "fobos".actt010 add constraint (foreign key (a10_usuario) 
    references "fobos".gent005 );





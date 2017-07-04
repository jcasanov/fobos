{ TABLE "fobos".actt012 row size = 102 number of columns = 17 index size = 163 }
create table "fobos".actt012 
  (
    a12_compania integer not null ,
    a12_codigo_tran char(2) not null ,
    a12_numero_tran integer not null ,
    a12_codigo_bien integer not null ,
    a12_referencia varchar(30),
    a12_locali_ori smallint not null ,
    a12_depto_ori smallint not null ,
    a12_locali_dest smallint,
    a12_depto_dest smallint,
    a12_porc_deprec decimal(4,2),
    a12_porc_reval decimal(4,2),
    a12_valor_mb decimal(12,2) not null ,
    a12_valor_ma decimal(12,2) not null ,
    a12_tipcomp_gen char(2),
    a12_numcomp_gen char(8),
    a12_usuario varchar(10,5) not null ,
    a12_fecing datetime year to second not null 
  );
revoke all on "fobos".actt012 from "public";

create index "fobos".i01_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_codigo_tran);
create unique index "fobos".i01_pk_actt012 on "fobos".actt012 
    (a12_compania,a12_codigo_tran,a12_numero_tran);
create index "fobos".i02_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_codigo_bien);
create index "fobos".i03_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_locali_ori);
create index "fobos".i04_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_locali_dest);
create index "fobos".i05_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_depto_ori);
create index "fobos".i06_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_depto_dest);
create index "fobos".i07_fk_actt012 on "fobos".actt012 (a12_compania,
    a12_tipcomp_gen,a12_numcomp_gen);
create index "fobos".i08_fk_actt012 on "fobos".actt012 (a12_usuario);
    
alter table "fobos".actt012 add constraint primary key (a12_compania,
    a12_codigo_tran,a12_numero_tran) constraint "fobos".pk_actt012 
     ;

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_codigo_tran) references "fobos".actt005 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_codigo_bien) references "fobos".actt010 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_locali_ori) references "fobos".gent002 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_locali_dest) references "fobos".gent002 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_depto_ori) references "fobos".gent034 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_depto_dest) references "fobos".gent034 );

alter table "fobos".actt012 add constraint (foreign key (a12_compania,
    a12_tipcomp_gen,a12_numcomp_gen) references "fobos".ctbt012 
    );

alter table "fobos".actt012 add constraint (foreign key (a12_usuario) 
    references "fobos".gent005 );





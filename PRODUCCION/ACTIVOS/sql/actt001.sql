{ TABLE "fobos".actt001 row size = 110 number of columns = 12 index size = 169 }
create table "fobos".actt001 
  (
    a01_compania integer not null ,
    a01_grupo_act smallint not null ,
    a01_nombre varchar(30,15) not null ,
    a01_depreciable char(1) not null ,
    a01_anos_util smallint not null ,
    a01_porc_deprec decimal(4,2) not null ,
    a01_aux_activo char(12),
    a01_aux_reexpr char(12),
    a01_aux_dep_act char(12),
    a01_aux_dep_reex char(12),
    a01_usuario varchar(10,5) not null ,
    a01_fecing datetime year to second not null ,
    
    check (a01_depreciable IN ('S' ,'N' ))
  );
revoke all on "fobos".actt001 from "public";

create index "fobos".i01_fk_actt001 on "fobos".actt001 (a01_compania);
    
create unique index "fobos".i01_pk_actt001 on "fobos".actt001 
    (a01_compania,a01_grupo_act);
create index "fobos".i02_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_activo);
create index "fobos".i03_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_reexpr);
create index "fobos".i04_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_dep_act);
create index "fobos".i05_fk_actt001 on "fobos".actt001 (a01_compania,
    a01_aux_dep_reex);
create index "fobos".i06_fk_actt001 on "fobos".actt001 (a01_usuario);
    
alter table "fobos".actt001 add constraint primary key (a01_compania,
    a01_grupo_act) constraint "fobos".pk_actt001  ;

alter table "fobos".actt001 add constraint (foreign key (a01_compania) 
    references "fobos".actt000 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_activo) references "fobos".ctbt010 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_reexpr) references "fobos".ctbt010 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_dep_act) references "fobos".ctbt010 );

alter table "fobos".actt001 add constraint (foreign key (a01_compania,
    a01_aux_dep_reex) references "fobos".ctbt010 );

alter table "fobos".actt001 add constraint (foreign key (a01_usuario) 
    references "fobos".gent005 );






create table "fobos".rept107 
  (
    r107_compania integer not null ,
    r107_codigo char(2) not null ,
    r107_descripcion varchar(30,15) not null ,
    r107_estado char(1) not null ,
    r107_usuario varchar(10,5) not null ,
    r107_fecing datetime year to second not null ,
    
    check (r107_estado IN ('A' ,'B' ))
    
  );
revoke all on "fobos".rept107 from "public";

create unique index "fobos".i01_pk_rept107 on "fobos".rept107 
    (r107_compania,r107_codigo);
create index "fobos".i01_fk_rept107 on "fobos".rept107 (r107_compania);
create index "fobos".i02_fk_rept107 on "fobos".rept107 (r107_usuario);
    
alter table "fobos".rept107 add constraint primary key (r107_compania,
    r107_codigo) constraint "fobos".pk_rept107  ;

alter table "fobos".rept107 add constraint (foreign key (r107_compania
    ) references "fobos".rept000 );

alter table "fobos".rept107 add constraint (foreign key (r107_usuario) 
    references "fobos".gent005 );


--------


create table "fobos".rept108 
  (
    r108_compania integer not null ,
    r108_codigo char(2) not null ,
    r108_descripcion varchar(30,15) not null ,
    r108_estado char(1) not null ,
    r108_usuario varchar(10,5) not null ,
    r108_fecing datetime year to second not null ,
    
    check (r108_estado IN ('A' ,'B' ))
    
  );
revoke all on "fobos".rept108 from "public";

create unique index "fobos".i01_pk_rept108 on "fobos".rept108 
    (r108_compania,r108_codigo);
create index "fobos".i01_fk_rept108 on "fobos".rept108 (r108_compania);
create index "fobos".i02_fk_rept108 on "fobos".rept108 (r108_usuario);
    
alter table "fobos".rept108 add constraint primary key (r108_compania,
    r108_codigo) constraint "fobos".pk_rept108  ;

alter table "fobos".rept108 add constraint (foreign key (r108_compania
    ) references "fobos".rept000 );

alter table "fobos".rept108 add constraint (foreign key (r108_usuario) 
    references "fobos".gent005 );

------

create table "fobos".rept109 
  (
    r109_compania integer not null ,
    r109_codigo char(2) not null ,
    r109_descripcion varchar(30,15) not null ,
    r109_estado char(1) not null ,
    r109_usuario varchar(10,5) not null ,
    r109_fecing datetime year to second not null ,
    
    check (r109_estado IN ('A' ,'B' ))
    
  );
revoke all on "fobos".rept109 from "public";

create unique index "fobos".i01_pk_rept109 on "fobos".rept109 
    (r109_compania,r109_codigo);
create index "fobos".i01_fk_rept109 on "fobos".rept109 (r109_compania);
create index "fobos".i02_fk_rept109 on "fobos".rept109 (r109_usuario);
    
alter table "fobos".rept109 add constraint primary key (r109_compania,
    r109_codigo) constraint "fobos".pk_rept109  ;

alter table "fobos".rept109 add constraint (foreign key (r109_compania
    ) references "fobos".rept000 );

alter table "fobos".rept109 add constraint (foreign key (r109_usuario) 
    references "fobos".gent005 );


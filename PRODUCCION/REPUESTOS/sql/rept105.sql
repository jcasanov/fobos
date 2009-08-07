
create table "fobos".rept105 
  (
    r105_compania integer not null ,
    r105_parametro char(3) not null ,
    r105_item char(15) not null ,
    r105_fecha_ini date not null ,
    r105_secuencia integer not null ,
    r105_valor decimal(5,2) not null ,
    r105_origen char(1) not null ,
    r105_usuario varchar(10,5) not null ,
    r105_fecha_fin date,
    
    check (r105_origen IN ('A' ,'M' ))
  ) extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept105 from "public";

create unique index "fobos".i01_pk_rept105 on "fobos".rept105 
    (r105_compania,r105_parametro,r105_item,r105_fecha_ini,r105_secuencia);
    
create index "fobos".i01_fk_rept105 on "fobos".rept105 (r105_compania,
    r105_item);
create index "fobos".i02_fk_rept105 on "fobos".rept105 (r105_compania,
    r105_parametro);
create index "fobos".i03_fk_rept105 on "fobos".rept105 (r105_usuario);
    
alter table "fobos".rept105 add constraint primary key (r105_compania,
    r105_parametro,r105_item,r105_fecha_ini,r105_secuencia) constraint 
    "fobos".pk_rept105  ;

alter table "fobos".rept105 add constraint (foreign key (r105_compania,
    r105_item) references "fobos".rept010 );

alter table "fobos".rept105 add constraint (foreign key (r105_compania,
    r105_parametro) references "fobos".rept104 );

alter table "fobos".rept105 add constraint (foreign key (r105_usuario) 
    references "fobos".gent005 );





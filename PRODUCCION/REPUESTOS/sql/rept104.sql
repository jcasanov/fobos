
create table "fobos".rept104 
  (
    r104_compania integer not null ,
    r104_codigo char(3) not null ,
    r104_descripcion varchar(30,10) not null ,
	r104_valor_default decimal(5,2), 
    r104_usuario varchar(10,5) not null ,
    r104_fecing datetime year to second not null 
  ) extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept104 from "public";

create unique index "fobos".i01_pk_rept104 on "fobos".rept104 
    (r104_compania,r104_codigo);
create index "fobos".i01_fk_rept104 on "fobos".rept104 (r104_compania);
    
create index "fobos".i02_fk_rept104 on "fobos".rept104 (r104_usuario);
    
alter table "fobos".rept104 add constraint primary key (r104_compania,
    r104_codigo) constraint "fobos".pk_rept104  ;

alter table "fobos".rept104 add constraint (foreign key (r104_compania) 
    references "fobos".rept000 );

alter table "fobos".rept104 add constraint (foreign key (r104_usuario) 
    references "fobos".gent005 );





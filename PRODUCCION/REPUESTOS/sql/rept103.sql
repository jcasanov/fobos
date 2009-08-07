-- Esta es una tabla de clasificadores y/o datos adicionales
-- del item.
-- Esta tabla va a tener una relacion 1:1 con la rept010

create table "fobos".rept103 
  (
    r103_compania integer not null ,
    r103_item char(15) not null ,
    r103_familia_vta integer ,
    r103_maquina  integer ,
	r103_componente integer,
    r103_proveedor integer,
    r103_pais_origen integer, 
  ) extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept103 from "public";

create unique index "fobos".i01_pk_rept103 on "fobos".rept103 
    (r103_compania,r103_item);
create index "fobos".i01_fk_rept103 on "fobos".rept103 (r103_compania);
create index "fobos".i02_fk_rept103 on "fobos".cxpt001 (r103_proveedor);
create index "fobos".i03_fk_rept103 on "fobos".cxpt001 (r103_pais_origen);
    
alter table "fobos".rept103 add constraint primary key (r103_compania,
    r103_item) constraint "fobos".pk_rept103  ;

alter table "fobos".rept103 add constraint (foreign key (r103_compania, 
    r103_item) references "fobos".rept010 );
alter table "fobos".rept103 add constraint (foreign key (r103_compania) 
    references "fobos".rept000 );
alter table "fobos".rept103 add constraint (foreign key (r103_proveedor) 
    references "fobos".cxpt001 );
alter table "fobos".rept103 add constraint (foreign key (r103_pais_origen) 
    references "fobos".gent030 );





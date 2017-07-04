{ TABLE "fobos".actt002 row size = 58 number of columns = 6 index size = 52 }
create table "fobos".actt002 
  (
    a02_compania integer not null ,
    a02_tipo_act smallint not null ,
    a02_nombre varchar(30,15) not null ,
    a02_grupo_act smallint not null ,
    a02_usuario varchar(10,5) not null ,
    a02_fecing datetime year to second not null 
  );
revoke all on "fobos".actt002 from "public";

create index "fobos".i01_fk_actt002 on "fobos".actt002 (a02_compania,
    a02_grupo_act);
create unique index "fobos".i01_pk_actt002 on "fobos".actt002 
    (a02_compania,a02_tipo_act);
create index "fobos".i02_fk_actt002 on "fobos".actt002 (a02_usuario);
    
alter table "fobos".actt002 add constraint primary key (a02_compania,
    a02_tipo_act) constraint "fobos".pk_actt002  ;

alter table "fobos".actt002 add constraint (foreign key (a02_compania,
    a02_grupo_act) references "fobos".actt001 );

alter table "fobos".actt002 add constraint (foreign key (a02_usuario) 
    references "fobos".gent005 );





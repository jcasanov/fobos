{ TABLE "fobos".talt003 row size = 109 number of columns = 20 index size = 102 }
create table "fobos".talt003 
  (
    t03_compania integer not null ,
    t03_mecanico smallint not null ,
    t03_nombres varchar(30,15) not null ,
    t03_iniciales char(3) not null ,
    t03_codrol integer,
    t03_tipo char(1) not null ,
    t03_seccion smallint not null ,
    t03_linea char(5) not null ,
    t03_hora_ini datetime hour to minute,
    t03_hora_fin datetime hour to minute,
    t03_cost_hvn decimal(5,2),
    t03_cost_hve decimal(5,2),
    t03_cost_htn decimal(5,2),
    t03_cost_hte decimal(5,2),
    t03_fact_hvn decimal(5,2),
    t03_fact_hve decimal(5,2),
    t03_fact_htn decimal(5,2),
    t03_fact_hte decimal(5,2),
    t03_usuario varchar(10,5) not null ,
    t03_fecing datetime year to second not null ,
    
    check (t03_tipo IN ('M' ,'A' ))
  );
revoke all on "fobos".talt003 from "public";

create unique index "fobos".i01_pk_talt003 on "fobos".talt003 
    (t03_compania,t03_mecanico);
create index "fobos".i01_fk_talt003 on "fobos".talt003 (t03_compania);
    
create index "fobos".i02_fk_talt003 on "fobos".talt003 (t03_compania,
    t03_codrol);
create index "fobos".i03_fk_talt003 on "fobos".talt003 (t03_compania,
    t03_seccion);
create index "fobos".i04_fk_talt003 on "fobos".talt003 (t03_compania,
    t03_linea);
create index "fobos".i05_fk_talt003 on "fobos".talt003 (t03_usuario);
    
alter table "fobos".talt003 add constraint primary key (t03_compania,
    t03_mecanico) constraint "fobos".pk_talt003  ;

alter table "fobos".talt003 add constraint (foreign key (t03_compania) 
    references "fobos".talt000 );

alter table "fobos".talt003 add constraint (foreign key (t03_compania,
    t03_codrol) references "fobos".rolt030 );

alter table "fobos".talt003 add constraint (foreign key (t03_compania,
    t03_seccion) references "fobos".talt002 );

alter table "fobos".talt003 add constraint (foreign key (t03_compania,
    t03_linea) references "fobos".talt001 );

alter table "fobos".talt003 add constraint (foreign key (t03_usuario) 
    references "fobos".gent005 );





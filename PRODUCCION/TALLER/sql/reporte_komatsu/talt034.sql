drop table talt034;

create table "fobos".talt034 
  (
    t34_compania integer not null ,
    t34_localidad smallint not null ,
    t34_orden integer not null ,
    t34_modelo char(15) not null ,
    t34_codtarea char(12) not null ,
    t34_secuencia smallint not null ,
    t34_fecha	date not null ,
    t34_hora_ini datetime hour to minute not null,
    t34_hora_fin datetime hour to minute not null,
    t34_usuario varchar(10,5) not null ,
    t34_fecing datetime year to second not null 
  );
revoke all on "fobos".talt034 from "public";

create unique index "fobos".i01_pk_talt034 on "fobos".talt034 
    (t34_compania,t34_localidad,t34_orden,t34_modelo,t34_codtarea,
    t34_secuencia, t34_fecha, t34_hora_ini) in idxdbs;
create  index "fobos".i01_fk_talt034 on "fobos".talt034 
    (t34_compania,t34_localidad,t34_orden,t34_modelo,t34_codtarea,
    t34_secuencia) in idxdbs;
create index "fobos".i02_fk_talt034 on "fobos".talt034 (t34_usuario) in idxdbs;
    
alter table "fobos".talt034 add constraint primary key (t34_compania,
    t34_localidad,t34_orden,t34_modelo,t34_codtarea,t34_secuencia, t34_fecha,
    t34_hora_ini) 
    constraint "fobos".pk_talt034  ;

alter table "fobos".talt034 add constraint (foreign key (t34_compania,
    t34_localidad,t34_orden,t34_modelo,t34_codtarea,t34_secuencia) 
                             references "fobos".talt024 );

alter table "fobos".talt034 add constraint (foreign key (t34_usuario) 
    references "fobos".gent005 );


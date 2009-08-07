drop table maqt013;
create table "fobos".maqt013 
  (
    m13_compania   integer not null ,
    m13_modelo     char(15) not null ,
    m13_secuencia  smallint not null ,
    m13_fecha      date not null ,
    m13_orden      smallint not null,
    m13_comentario varchar(240, 120) not null  
  );
revoke all on "fobos".maqt013 from "public";

create unique index "fobos".pk_maqt013 on "fobos".maqt013 (m13_compania,
    m13_modelo,m13_secuencia,m13_fecha, m13_orden);
create index "fobos".i01_fk_maqt013 on "fobos".maqt013 (m13_compania,
    m13_modelo,m13_secuencia);
alter table "fobos".maqt013 add constraint primary key (m13_compania,
    m13_modelo,m13_secuencia,m13_fecha, m13_orden)  ;

alter table "fobos".maqt013 add constraint (foreign key (m13_compania,
    m13_modelo,m13_secuencia) references "fobos".maqt011 );





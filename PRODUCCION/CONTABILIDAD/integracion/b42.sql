{ TABLE "fobos".ctbt042 row size = 102 number of columns = 10 index size = 15 }
create table "fobos".ctbt042 
  (
    b42_compania integer not null ,
    b42_localidad smallint not null ,
    b42_iva_venta char(12) not null ,
    b42_iva_compra char(12) not null ,
    b42_iva_import char(12),
    b42_retencion char(12) not null ,
    b42_reten_cred char(12),
    b42_flete_comp char(12),
    b42_otros_comp char(12),
    b42_cuadre char(12)
  );
revoke all on "fobos".ctbt042 from "public";

create unique index "fobos".i01_pk_ctbt042 on "fobos".ctbt042 
    (b42_compania,b42_localidad);
alter table "fobos".ctbt042 add constraint primary key (b42_compania,
    b42_localidad) constraint "fobos".pk_ctbt042  ;





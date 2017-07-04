{ TABLE "fobos".rept090 row size = 46 number of columns = 9 index size = 31 }
create table "fobos".rept090 
  (
    r90_compania integer not null ,
    r90_localidad smallint not null ,
    r90_cod_tran char(2) not null ,
    r90_num_tran decimal(15,0) not null ,
    r90_fecing datetime year to second not null ,
    r90_locali_fin smallint 
        default 1 not null ,
    r90_codtra_fin char(2),
    r90_numtra_fin decimal(15,0),
    r90_fecing_fin datetime year to second 
        default current year to second
  );
revoke all on "fobos".rept090 from "public";

create unique index "fobos".i01_pk_rept090 on "fobos".rept090 
    (r90_compania,r90_localidad,r90_cod_tran,r90_num_tran);
alter table "fobos".rept090 add constraint primary key (r90_compania,
    r90_localidad,r90_cod_tran,r90_num_tran) constraint "fobos"
    .pk_rept090  ;





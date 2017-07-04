{ TABLE "fobos".rept085 row size = 162 number of columns = 18 index size = 222 }
create table "fobos".rept085 
  (
    r85_compania integer not null ,
    r85_codigo integer not null ,
    r85_estado char(1) not null ,
    r85_referencia varchar(60,30) not null ,
    r85_division char(5),
    r85_linea char(2),
    r85_cod_grupo char(4),
    r85_cod_clase char(8),
    r85_marca char(6),
    r85_cod_util char(5),
    r85_partida varchar(15,8),
    r85_precio_nue decimal(11,2) not null ,
    r85_porc_aum decimal(5,2) not null ,
    r85_porc_dec decimal(5,2) not null ,
    r85_fec_camprec date not null ,
    r85_fec_reversa datetime year to second,
    r85_usuario varchar(10,5) not null ,
    r85_fecing datetime year to second not null ,
    
    check (r85_estado IN ('A' ,'R' ))
  );
revoke all on "fobos".rept085 from "public";

create unique index "fobos".i01_pk_rept085 on "fobos".rept085 
    (r85_compania,r85_codigo);
create index "fobos".i01_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_division);
create index "fobos".i02_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_division,r85_linea);
create index "fobos".i03_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_division,r85_linea,r85_cod_grupo);
create index "fobos".i04_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_division,r85_linea,r85_cod_grupo,r85_cod_clase);
create index "fobos".i05_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_marca);
create index "fobos".i06_fk_rept085 on "fobos".rept085 (r85_compania,
    r85_cod_util);
create index "fobos".i07_fk_rept085 on "fobos".rept085 (r85_partida);
    
create index "fobos".i08_fk_rept085 on "fobos".rept085 (r85_usuario);
    
alter table "fobos".rept085 add constraint primary key (r85_compania,
    r85_codigo) constraint "fobos".pk_rept085  ;





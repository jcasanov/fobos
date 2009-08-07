
DBSCHEMA Schema Utility       INFORMIX-SQL Version 7.31.UD1   
Copyright (C) Informix Software, Inc., 1984-1998
Software Serial Number AAA#E439387
{ TABLE "fobos".talt023 row size = 471 number of columns = 53 index size = 328 }
create table "fobos".talt023 
  (
    t23_compania integer not null ,
    t23_localidad smallint not null ,
    t23_orden integer not null ,
    t23_estado char(1) not null ,
    t23_tipo_ot char(1) not null ,
    t23_subtipo_ot char(1) not null ,
    t23_descripcion varchar(120,60),
    t23_cod_cliente integer,
    t23_nom_cliente varchar(40,20) not null ,
    t23_tel_cliente char(10),
    t23_codcli_est integer,
    t23_numpre integer,
    t23_valor_tope decimal(11,2),
    t23_seccion smallint not null ,
    t23_cod_asesor smallint not null ,
    t23_cod_mecani smallint not null ,
    t23_moneda char(2) not null ,
    t23_paridad decimal(16,9) not null ,
    t23_precision smallint not null ,
    t23_fecini date not null ,
    t23_fecfin date not null ,
    t23_cont_cred char(1) not null ,
    t23_porc_impto decimal(4,2) not null ,
    t23_modelo char(15) not null ,
    t23_chasis char(25) not null ,
    t23_placa char(10) not null ,
    t23_color char(15) not null ,
    t23_kilometraje integer,
    t23_orden_cheq integer,
    t23_val_mo_tal decimal(11,2) not null ,
    t23_val_mo_ext decimal(11,2) not null ,
    t23_val_mo_cti decimal(11,2) not null ,
    t23_val_rp_tal decimal(11,2) not null ,
    t23_val_rp_ext decimal(11,2) not null ,
    t23_val_rp_cti decimal(11,2) not null ,
    t23_val_rp_alm decimal(11,2) not null ,
    t23_val_otros1 decimal(11,2) not null ,
    t23_val_otros2 decimal(11,2) not null ,
    t23_por_mo_tal decimal(4,2) not null ,
    t23_por_rp_tal decimal(4,2) not null ,
    t23_por_rp_alm decimal(4,2) not null ,
    t23_vde_mo_tal decimal(10,2) not null ,
    t23_vde_rp_tal decimal(10,2) not null ,
    t23_vde_rp_alm decimal(10,2) not null ,
    t23_tot_bruto decimal(12,2) not null ,
    t23_tot_dscto decimal(11,2) not null ,
    t23_val_impto decimal(11,2) not null ,
    t23_tot_neto decimal(12,2) not null ,
    t23_fec_cierre datetime year to second,
    t23_num_factura decimal(15,0),
    t23_fec_factura datetime year to second,
    t23_usuario varchar(10,5) not null ,
    t23_fecing datetime year to second not null ,
    
    check (t23_estado IN ('A' ,'C' ,'F' ,'E' ,'D' )),
    
    check (t23_precision IN (0 ,1 ,2 )),
    
    check (t23_cont_cred IN ('C' ,'R' ))
  );
revoke all on "fobos".talt023 from "public";

create unique index "fobos".i01_pk_talt023 on "fobos".talt023 
    (t23_compania,t23_localidad,t23_orden);
create index "fobos".i01_fk_talt023 on "fobos".talt023 (t23_compania);
    
create index "fobos".i02_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_localidad);
create index "fobos".i03_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_tipo_ot);
create index "fobos".i04_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_tipo_ot,t23_subtipo_ot);
create index "fobos".i05_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_localidad,t23_cod_cliente);
create index "fobos".i06_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_localidad,t23_codcli_est);
create index "fobos".i07_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_seccion);
create index "fobos".i08_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_cod_asesor);
create index "fobos".i09_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_cod_mecani);
create index "fobos".i10_fk_talt023 on "fobos".talt023 (t23_moneda);
    
create index "fobos".i11_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_modelo);
create index "fobos".i12_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_cod_cliente,t23_modelo,t23_chasis);
create index "fobos".i13_fk_talt023 on "fobos".talt023 (t23_usuario);
    
create index "fobos".i14_fk_talt023 on "fobos".talt023 (t23_compania,
    t23_localidad,t23_numpre);
alter table "fobos".talt023 add constraint primary key (t23_compania,
    t23_localidad,t23_orden) constraint "fobos".pk_talt023  ;

alter table "fobos".talt023 add constraint (foreign key (t23_compania) 
    references "fobos".talt000 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_localidad) references "fobos".gent002 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_tipo_ot) references "fobos".talt005 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_tipo_ot,t23_subtipo_ot) references "fobos".talt006 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_localidad,t23_cod_cliente) references "fobos".cxct002 
    );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_localidad,t23_codcli_est) references "fobos".cxct002 );
    

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_seccion) references "fobos".talt002 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_cod_asesor) references "fobos".talt003 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_cod_mecani) references "fobos".talt003 );

alter table "fobos".talt023 add constraint (foreign key (t23_moneda) 
    references "fobos".gent013 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_modelo) references "fobos".talt004 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_cod_cliente,t23_modelo,t23_chasis) references "fobos".talt010 
    );

alter table "fobos".talt023 add constraint (foreign key (t23_usuario) 
    references "fobos".gent005 );

alter table "fobos".talt023 add constraint (foreign key (t23_compania,
    t23_localidad,t23_numpre) references "fobos".talt020 );





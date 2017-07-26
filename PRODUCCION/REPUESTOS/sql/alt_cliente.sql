begin work;

alter table "fobos".cxct001 modify z01_nomcli      varchar(100,50) not null;

alter table "fobos".tr_cxct001 modify z01_nomcli   varchar(100,50) not null;

alter table "fobos".cajt010 modify j10_nomcli      varchar(100,50) not null;

alter table "fobos".rept019 modify r19_nomcli      varchar(100,50) not null;
alter table "fobos".rept021 modify r21_nomcli      varchar(100,50) not null;
alter table "fobos".rept023 modify r23_nomcli      varchar(100,50) not null;
alter table "fobos".rept088 modify r88_nomcli_nue  varchar(100,50);
alter table "fobos".rept091 modify r91_nomcli      varchar(100,50) not null;

alter table "fobos".talt020 modify t20_nom_cliente varchar(100,50) not null;
alter table "fobos".talt023 modify t23_nom_cliente varchar(100,50) not null;

alter table "fobos".cxpt001 modify p01_nomprov     varchar(100,50) not null;

alter table "fobos".rept081 modify r81_nom_prov    varchar(100,50) not null;

commit work;

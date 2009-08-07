create table "fobos".ctbt100 
  (
    b100_compania 	integer  not null,
    b100_localidad 	smallint not null,
    b100_modulo 	char(2)  not null,
    b100_grupo_linea 	char(5)  not null,
    b100_cxc_mb 	char(12) not null,
    b100_cxc_me 	char(12) not null,
    b100_ant_mb 	char(12) not null,
    b100_ant_me 	char(12) not null  
  ) lock mode row;
revoke all on "fobos".ctbt100 from "public";

create unique index "fobos".i01_pk_ctbt100 on "fobos".ctbt100 
    (b100_compania,b100_localidad,b100_modulo,b100_grupo_linea);

alter table "fobos".ctbt100 
	add constraint primary key (b100_compania, b100_localidad,b100_modulo,b100_grupo_linea) constraint "fobos".pk_ctbt100  ;





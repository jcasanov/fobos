drop table "fobos".rept087;

create table "fobos".rept087
	(
		r87_compania		integer			not null,
		r87_item		char(15)		not null,
		r87_secuencia		smallint		not null,
		r87_precio_act		decimal(11,2)		not null,
		r87_precio_ant		decimal(11,2)		not null,
		r87_usu_camprec		varchar(10,5)		not null,
		r87_fec_camprec		datetime year to second	not null
	);

revoke all on "fobos".rept087 from "public";

create unique index "fobos".i01_pk_rept087 on "fobos".rept087 
    (r87_compania, r87_item, r87_secuencia);
    
create index "fobos".i01_fk_rept087 on "fobos".rept087 (r87_compania, r87_item);
    
alter table "fobos".rept087
	add constraint
		primary key (r87_compania, r87_item, r87_secuencia)
			constraint "fobos".pk_rept087;

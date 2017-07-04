{--
alter table "fobos".rolt045 drop n45_porc_int;
alter table "fobos".rolt045 drop n45_valor_int;
alter table "fobos".rolt045 drop n45_mes_gracia;
--}

begin work;

alter table "fobos".rolt045 add (n45_porc_int decimal(5,2) before n45_moneda);
alter table "fobos".rolt045 add (n45_valor_int decimal(12,2) before n45_moneda);
alter table "fobos".rolt045 add (n45_mes_gracia smallint before n45_moneda);

update "fobos".rolt045
	set n45_porc_int   = 0.00,
	    n45_valor_int  = 0.00,
	    n45_mes_gracia = 0
	where 1 = 1;

alter table "fobos".rolt045 modify (n45_porc_int decimal(5,2) not null);
alter table "fobos".rolt045 modify (n45_valor_int decimal(12,2) not null);
alter table "fobos".rolt045 modify (n45_mes_gracia smallint not null);

commit work;

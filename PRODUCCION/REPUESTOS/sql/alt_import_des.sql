--begin work;

-- MODIFICANDO rept019 PARA CUADRE DE IMPORTACIONES --
alter table "fobos".rept019
	modify (r19_tot_costo decimal(12,2) not null);
alter table "fobos".rept019
	modify (r19_tot_bruto decimal(12,2) not null);
alter table "fobos".rept019
	modify (r19_tot_dscto decimal(11,2) not null);
alter table "fobos".rept019
	modify (r19_tot_neto  decimal(12,2) not null);
alter table "fobos".rept019
	modify (r19_flete     decimal(11,2) not null);
--

-- MODIFICANDO rept020 PARA CUADRE DE IMPORTACIONES --
alter table "fobos".rept020
	modify (r20_val_descto decimal(10,2) not null);
alter table "fobos".rept020
	modify (r20_precio     decimal(13,4) not null);
alter table "fobos".rept020
	modify (r20_val_impto  decimal(11,2) not null);
alter table "fobos".rept020
	modify (r20_costo      decimal(13,4) not null);
alter table "fobos".rept020
	modify (r20_fob        decimal(11,2) not null);
alter table "fobos".rept020
	modify (r20_costant_mb decimal(11,2) not null);
alter table "fobos".rept020
	modify (r20_costant_ma decimal(11,2) not null);
alter table "fobos".rept020
	modify (r20_costnue_mb decimal(11,2) not null);
alter table "fobos".rept020
	modify (r20_costnue_ma decimal(11,2) not null);
--

--commit work;

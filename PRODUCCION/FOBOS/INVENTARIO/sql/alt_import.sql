begin work;

-- MODIFICANDO rept019 PARA CUADRE DE IMPORTACIONES --
alter table "fobos".rept019
	modify (r19_tot_costo decimal(22,10) not null);
alter table "fobos".rept019
	modify (r19_tot_bruto decimal(22,10) not null);
alter table "fobos".rept019
	modify (r19_tot_dscto decimal(22,10) not null);
alter table "fobos".rept019
	modify (r19_tot_neto  decimal(22,10) not null);
alter table "fobos".rept019
	modify (r19_flete     decimal(22,10) not null);
--

-- MODIFICANDO rept020 PARA CUADRE DE IMPORTACIONES --
alter table "fobos".rept020
	modify (r20_val_descto decimal(22,10) not null);
alter table "fobos".rept020
	modify (r20_precio     decimal(22,10) not null);
alter table "fobos".rept020
	modify (r20_val_impto  decimal(22,10) not null);
alter table "fobos".rept020
	modify (r20_costo      decimal(22,10) not null);
alter table "fobos".rept020
	modify (r20_fob        decimal(22,10) not null);
alter table "fobos".rept020
	modify (r20_costant_mb decimal(22,10) not null);
alter table "fobos".rept020
	modify (r20_costant_ma decimal(22,10) not null);
alter table "fobos".rept020
	modify (r20_costnue_mb decimal(22,10) not null);
alter table "fobos".rept020
	modify (r20_costnue_ma decimal(22,10) not null);
--

commit work;

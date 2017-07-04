--drop table srit023;

create table "fobos".srit023
	(

		s23_compania		integer			not null,
		s23_tipo_orden		integer			not null,
		s23_sustento_tri	char(2)			not null

	) in datadbs lock mode row;

revoke all on "fobos".srit023 from "public";


create unique index "fobos".i01_pk_srit023
	on "fobos".srit023
		(s23_compania, s23_tipo_orden, s23_sustento_tri) in idxdbs;

create index "fobos".i01_fk_srit023
	on "fobos".srit023 (s23_tipo_orden) in idxdbs;

create index "fobos".i02_fk_srit023
	on "fobos".srit023 (s23_compania, s23_sustento_tri) in idxdbs;


alter table "fobos".srit023
	add constraint
		primary key (s23_compania, s23_tipo_orden, s23_sustento_tri)
			constraint pk_srit023;

alter table "fobos".srit023
	add constraint
		(foreign key (s23_tipo_orden)
			references "fobos".ordt001
			constraint fk_01_srit023);

alter table "fobos".srit023
	add constraint
		(foreign key (s23_compania, s23_sustento_tri)
			references "fobos".srit006
			constraint fk_02_srit023);
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
insert into "fobos".srit006
	values (1, '00', 'No aplica', 'FOBOS', current);

insert into "fobos".srit006
	values (1, '01', 'Compras netas de servicios y bienes distintos de inventario y activos fijos que sustentan crédito tributario',
		'FOBOS', current);

insert into "fobos".srit006
	values (1, '02', 'Compras netas de servicios y bienes distintos de inventario y activos fijos que NO sustentan crédito tributario',
		'FOBOS', current);

insert into "fobos".srit006
	values (1, '03', 'Compras netas de activos fijos que sustentas crédito tributario',
		'FOBOS', current);

insert into "fobos".srit006
	values (1, '04', 'Compras netas de activos fijos que NO sustentas crédito tributario',
		'FOBOS', current);

insert into "fobos".srit006
	values (1, '05', 'Liquidación de gastos de viaje a nombre de empleados y no de la empresa',
		'FOBOS', current);

insert into "fobos".srit006
	values (1, '06', 'Compras netas de inventario que sustentan crédito tributario',
		'FOBOS', current);

insert into "fobos".srit006
	values (1, '07', 'Compras netas de inventario que sustentan NO crédito tributario',
		'FOBOS', current);

insert into "fobos".srit006
	values (1, '08', 'Valor pagado o recibido por Reembolso de gasto.',
		'FOBOS', current);

insert into "fobos".srit006
	values (1, '09', 'Reembolso por gastos médicos y medicina prepagada',
		'FOBOS', current);

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
{--
insert into srit023 values(1,15,"01");
insert into srit023 values(1,7,"01");
insert into srit023 values(1,23,"01");
insert into srit023 values(1,35,"01");
insert into srit023 values(1,4,"01");
insert into srit023 values(1,10,"01");
insert into srit023 values(1,11,"01");
insert into srit023 values(1,40,"01");
insert into srit023 values(1,41,"01");
insert into srit023 values(1,13,"01");
insert into srit023 values(1,20,"01");
insert into srit023 values(1,22,"01");
insert into srit023 values(1,24,"01");
insert into srit023 values(1,25,"01");
insert into srit023 values(1,26,"01");
insert into srit023 values(1,27,"01");
insert into srit023 values(1,29,"01");
insert into srit023 values(1,30,"01");
insert into srit023 values(1,34,"01");
insert into srit023 values(1,44,"01");
insert into srit023 values(1,3,"01");

insert into srit023 values(1,32,"03");
insert into srit023 values(1,1,"06");
insert into srit023 values(1,14,"06");

insert into srit023 values(1,2,"02");
insert into srit023 values(1,27,"02");
insert into srit023 values(1,29,"02");
insert into srit023 values(1,34,"02");
--}
-------------------------------------------------------------------------------

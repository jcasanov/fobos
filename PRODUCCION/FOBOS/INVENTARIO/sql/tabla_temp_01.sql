drop table tr_compvtasto;
create table "fobos".tr_compvtasto
	(
		compania	integer			not null,
		anio		smallint		not null,
		mes		varchar(10)		not null,
		loc		varchar(30,15)		not null,
		tipo		varchar(15)		not null,
		linea		varchar(35,20)		not null,
		grupo		varchar(40,20)		not null,
		cod_cla		char(8)			not null,
		clase		varchar(50,20)		not null,
		item		char(15)		not null,
		desc_item	varchar(70,20)		not null,
		marca		char(6)			not null,
		cantidad	decimal(8,2)		not null,
		valor		decimal(14,2)		not null,
		stock		decimal(8,2)		not null
	) in datadbs lock mode row;

select anio, mes, loc, tipo, linea, grupo, cod_cla, clase, item, desc_item,
	marca, cantidad, valor
	from tr_compvtasto
	into temp t1;

select item, cantidad stock from t1 into temp caca;

load from "compra_venta_01.unl" insert into t1;
load from "compra_venta_02.unl" insert into t1;
load from "compra_venta_03.unl" insert into t1;
load from "compra_venta_04.unl" insert into t1;

load from "stock_gye_01.unl" insert into caca;
load from "stock_gye_02.unl" insert into caca;
load from "stock_uio_03.unl" insert into caca;
load from "stock_uio_04.unl" insert into caca;

select item, nvl(sum(stock), 0) stock from caca group by 1 into temp t2;

--select * from caca where item = '22586';
drop table caca;

--select * from t2 where item = '22586';

insert into tr_compvtasto
	select 1, t1.anio, t1.mes, t1.loc, t1.tipo, t1.linea, t1.grupo,
		t1.cod_cla, t1.clase, t1.item, t1.desc_item, t1.marca,
		t1.cantidad, t1.valor, nvl((select stock from t2
						where t2.item = t1.item), 0)
		from t1;

drop table t1;
drop table t2;

select anio, mes, loc, tipo, linea, grupo, cod_cla, clase, item, desc_item,
	marca, cantidad, valor
	from tr_compvtasto
	where compania = 99
	into temp t1;

select item, cantidad stock from t1 into temp caca;

load from "compra_venta_06.unl" insert into t1;
load from "compra_venta_07.unl" insert into t1;

load from "stock_ser_06.unl" insert into caca;
load from "stock_ser_07.unl" insert into caca;

select item, nvl(sum(stock), 0) stock from caca group by 1 into temp t2;

drop table caca;

insert into tr_compvtasto
	select 2, t1.anio, t1.mes, t1.loc, t1.tipo, t1.linea, t1.grupo,
		t1.cod_cla, t1.clase, t1.item, t1.desc_item, t1.marca,
		t1.cantidad, t1.valor, nvl((select stock from t2
						where t2.item = t1.item), 0)
		from t1;

drop table t1;
drop table t2;

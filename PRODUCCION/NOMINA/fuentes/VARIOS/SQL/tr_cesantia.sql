drop table tr_censatia;

begin work;

--------------------------------------------------------------------------------
create table "fobos".tr_cesantia
	(

		compania		integer			not null,
		cod_liqrol		char(2)			not null,
		anio_cen		smallint		not null,
		mes_cen			smallint		not null,
		cod_trab		integer			not null,
		fecha_repar		date			not null,
		fecha_prox		date			not null,
		valor_repar		decimal(14,2)		not null,
		usuario			varchar(10,5)		not null,
		fecing			datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".tr_cesantia from "public";

create unique index "fobos".i01_pk_tr_cesa on "fobos".tr_cesantia
	(compania, cod_liqrol, anio_cen, mes_cen, cod_trab) in idxdbs;

alter table "fobos".tr_cesantia
	add constraint
		primary key (compania, cod_liqrol, anio_cen, mes_cen, cod_trab)
			constraint "fobos".pk_tr_cesa;
--------------------------------------------------------------------------------

{
select compania, cod_liqrol, anio_cen, mes_cen, cod_trab, fecha_repar,
	 fecha_prox, valor_repar, usuario
	from tr_cesantia
	where compania = 999
	into temp t1;

load from "tr_cesantia200709.unl" insert into t1;

insert into tr_cesantia
	(compania, cod_liqrol, anio_cen, mes_cen, cod_trab, fecha_repar,
	 fecha_prox, valor_repar, usuario, fecing)
	select t1.compania, t1.cod_liqrol, t1.anio_cen, t1.mes_cen,
		t1.cod_trab, t1.fecha_repar, t1.fecha_prox, t1.valor_repar,
		t1.usuario, current
		from t1;

drop table t1;
}

commit work;

--------------------------------------------------------------------------------
begin work;
--------------------------------------------------------------------------------


--drop table rolt085;


--------------------------------------------------------------------------------
create table "fobos".rolt085

	(

		n85_compania		integer			not null,
		n85_proceso		char(2)			not null,
		n85_cod_trab		integer			not null,
		n85_ano_proceso		smallint		not null,
		n85_mes_proceso		smallint		not null,
		n85_estado		char(1)			not null,
		n85_ing_roles		decimal(12,2)		not null,
		n85_dec_cuarto		decimal(12,2)		not null,
		n85_dec_tercero		decimal(12,2)		not null,
		n85_roles_varios	decimal(12,2)		not null,
		n85_utilidades		decimal(12,2)		not null,
		n85_vacaciones		decimal(12,2)		not null,
		n85_iess_rol		decimal(11,2)		not null,
		n85_iess_vac		decimal(11,2)		not null,
		n85_bonificacion	decimal(12,2)		not null,
		n85_otros_ing		decimal(12,2)		not null,
		n85_total_gan		decimal(14,2)		not null,
		n85_base_imp_ini	decimal(12,2)		not null,
		n85_base_impto		decimal(11,2)		not null,
		n85_porc_exced		decimal(5,2)		not null,
		n85_valor_impto		decimal(11,2)		not null,
		n85_fracc_base		decimal(11,2)		not null,
		n85_valor_fracc		decimal(12,2)		not null,
		n85_valor_acum		decimal(12,2)		not null,
		n85_valor_deduc		decimal(12,2)		not null,
		n85_impto_pagar		decimal(11,2)		not null,
		n85_impto_reten		decimal(11,2)		not null,
		n85_usu_modifi		varchar(10,5),
		n85_fec_modifi		datetime year to second,
		n85_usu_cierre		varchar(10,5),
		n85_fec_cierre		datetime year to second,
		n85_usuario		varchar(10,5)		not null,
		n85_fecing		datetime year to second	not null,

		check (n85_estado in ('A', 'P'))
			constraint "fobos".ck_01_rolt085

	) in datadbs lock mode row;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
revoke all on "fobos".rolt085 from "public";
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_rolt085
	on "fobos".rolt085
		(n85_compania, n85_proceso, n85_cod_trab, n85_ano_proceso,
		 n85_mes_proceso)
	in idxdbs;

create index "fobos".i01_fk_rolt085
	on "fobos".rolt085
		(n85_compania, n85_proceso, n85_cod_trab, n85_ano_proceso)
	in idxdbs;

create index "fobos".i02_fk_rolt085
	on "fobos".rolt085
		(n85_compania)
	in idxdbs;

create index "fobos".i03_fk_rolt085
	on "fobos".rolt085
		(n85_proceso)
	in idxdbs;

create index "fobos".i04_fk_rolt085
	on "fobos".rolt085
		(n85_compania, n85_cod_trab)
	in idxdbs;

create index "fobos".i05_fk_rolt085
	on "fobos".rolt085
		(n85_usuario)
	in idxdbs;

create index "fobos".i06_fk_rolt085
	on "fobos".rolt085
		(n85_usu_modifi)
	in idxdbs;

create index "fobos".i07_fk_rolt085
	on "fobos".rolt085
		(n85_usu_cierre)
	in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".rolt085
	add constraint
		primary key (n85_compania, n85_proceso, n85_cod_trab,
				n85_ano_proceso, n85_mes_proceso)
			constraint "fobos".pk_rolt085;

alter table "fobos".rolt085
	add constraint
		(foreign key (n85_compania, n85_proceso, n85_cod_trab,
				n85_ano_proceso)
			references "fobos".rolt084
			constraint "fobos".fk_01_rolt085);

alter table "fobos".rolt085
	add constraint
		(foreign key (n85_compania)
			references "fobos".rolt001
			constraint "fobos".fk_02_rolt085);

alter table "fobos".rolt085
	add constraint
		(foreign key (n85_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_03_rolt085);

alter table "fobos".rolt085
	add constraint
		(foreign key (n85_compania, n85_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_04_rolt085);

alter table "fobos".rolt085
	add constraint
		(foreign key (n85_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_rolt085);

alter table "fobos".rolt085
	add constraint
		(foreign key (n85_usu_modifi)
			references "fobos".gent005
			constraint "fobos".fk_06_rolt085);

alter table "fobos".rolt085
	add constraint
		(foreign key (n85_usu_cierre)
			references "fobos".gent005
			constraint "fobos".fk_07_rolt085);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
commit work;
--------------------------------------------------------------------------------

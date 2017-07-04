drop table "fobos".rolt090;

begin work;

--------------------------------------------------------------------------------
-- CREACION DE TABLA CONFIGURACION ADICIONAL NOMINA --
--------------------------------------------------------------------------------
create table "fobos".rolt090

	(

		n90_compania		integer			not null,
		n90_dias_anio		smallint		not null,
		n90_dias_min_par	smallint		not null,
		n90_tiem_max_vac	smallint		not null,
		n90_dias_ano_vac	smallint		not null,
		n90_anio_ini_vac	smallint		not null,
		n90_gen_cont_vac	char(1)			not null,
		n90_dias_ano_ant	smallint		not null,
		n90_mes_gra_ant		smallint		not null,
		n90_anio_ini_ant	smallint		not null,
		n90_gen_cont_ant	char(1)			not null,
		n90_porc_int_ant	decimal(5,2)		not null,
		n90_dias_ano_ut		smallint		not null,
		n90_anio_ini_ut		smallint		not null,
		n90_gen_cont_ut		char(1)			not null,
		n90_usuario		varchar(10,5)		not null,
		n90_fecing		datetime year to second	not null,

		check (n90_gen_cont_vac in ('S', 'N'))
			constraint "fobos".ck_01_rolt090,

		check (n90_gen_cont_ant in ('S', 'N'))
			constraint "fobos".ck_02_rolt090,

		check (n90_gen_cont_ut in ('S', 'N'))
			constraint "fobos".ck_03_rolt090

	) in datadbs lock mode row;
--

revoke all on "fobos".rolt090 from "public";
--

-- CREACION DE INDICES EN TABLA CONFIGURACION ADICIONAL NOMINA --
create unique index "fobos".i01_pk_rolt090 on "fobos".rolt090
	(n90_compania) in idxdbs;

create index "fobos".i01_fk_rolt090 on "fobos".rolt090 (n90_usuario) in idxdbs;
--

-- CREACION DE CONSTRAINT EN TABLA CONFIGURACION ADICIONAL NOMINA --
alter table "fobos".rolt090
	add constraint primary key (n90_compania)
			constraint "fobos".pk_rolt090;

alter table "fobos".rolt090
	add constraint (foreign key (n90_compania)
			references "fobos".rolt001
			constraint "fobos".fk_01_rolt090);

alter table "fobos".rolt090
	add constraint (foreign key (n90_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rolt090);
--
--
--------------------------------------------------------------------------------

commit work;

--
--
load from "rolt090.unl" insert into "fobos".rolt090;

load from "gent054.unl" insert into "fobos".gent054;

load from "gent057.unl" insert into "fobos".gent057;
--
--

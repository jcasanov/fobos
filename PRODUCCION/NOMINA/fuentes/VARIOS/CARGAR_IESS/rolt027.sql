--drop table rolt027;

{-- TABLA: DETALLE DEL ARCHIVO BATCH PARA IESS --}

begin work;

create table "fobos".rolt027
	(

		n27_compania		integer			not null,
		n27_ano_proceso		integer			not null,
		n27_mes_proceso		smallint		not null,
		n27_codigo_arch		smallint		not null,
		n27_tipo_arch		char(3)			not null,
		n27_secuencia		smallint		not null,
		n27_cod_trab		integer			not null,
		n27_estado		char(1)			not null,
		n27_cedula_trab		char(10)		not null,
		n27_fecha_ini		date,
		n27_fecha_fin		date,
		n27_cargo		varchar(64,32),
		n27_sectorial		char(10),
		n27_valor_ext		decimal(12,2)		not null,
		n27_valor_adi		decimal(12,2)		not null,
		n27_valor_net		decimal(12,2)		not null,
		n27_tipo_causa		char(1),
		n27_sec_cau		smallint,
		n27_tipo_pago		char(1),
		n27_flag_pago		char(1),
		n27_num_dia_mes		char(2),
		n27_tipo_per		char(1)			not null,
		n27_usua_elimin		varchar(10,5),
		n27_fec_elimin		datetime year to second,
		n27_usua_modifi		varchar(10,5),
		n27_fec_modifi		datetime year to second,

		check	(n27_estado	in	('G', 'M', 'E'))
			constraint "fobos".ck_01_rolt027,

		check	(n27_tipo_per	in	('P', 'A', 'M', 'X'))
			constraint "fobos".ck_02_rolt027

	) in datadbs lock mode row;


revoke all on "fobos".rolt027 from "public";


create unique index "fobos".i01_pk_rolt027
	on "fobos".rolt027
		(n27_compania, n27_ano_proceso, n27_mes_proceso,n27_codigo_arch,
		 n27_tipo_arch, n27_secuencia, n27_cod_trab)
	in idxdbs;

create index "fobos".i01_fk_rolt027
	on "fobos".rolt027
		(n27_compania, n27_ano_proceso, n27_mes_proceso,n27_codigo_arch,
		 n27_tipo_arch, n27_secuencia)
	in idxdbs;

create index "fobos".i02_fk_rolt027
	on "fobos".rolt027
		(n27_compania)
	in idxdbs;

create index "fobos".i03_fk_rolt027
	on "fobos".rolt027
		(n27_compania, n27_cod_trab)
	in idxdbs;

create index "fobos".i04_fk_rolt027
	on "fobos".rolt027
		(n27_sectorial)
	in idxdbs;

create index "fobos".i05_fk_rolt027
	on "fobos".rolt027
		(n27_compania, n27_codigo_arch, n27_tipo_arch, n27_tipo_causa,
		 n27_sec_cau)
	in idxdbs;

create index "fobos".i06_fk_rolt027
	on "fobos".rolt027
		(n27_compania, n27_codigo_arch, n27_tipo_arch, n27_tipo_pago,
		 n27_flag_pago)
	in idxdbs;

create index "fobos".i07_fk_rolt027
	on "fobos".rolt027
		(n27_usua_elimin)
	in idxdbs;

create index "fobos".i08_fk_rolt027
	on "fobos".rolt027
		(n27_usua_modifi)
	in idxdbs;


alter table "fobos".rolt027
	add constraint
		primary key (n27_compania, n27_ano_proceso, n27_mes_proceso,
				n27_codigo_arch, n27_tipo_arch, n27_secuencia,
				n27_cod_trab)
			constraint "fobos".pk_rolt027;

alter table "fobos".rolt027
	add constraint
		(foreign key (n27_compania, n27_ano_proceso, n27_mes_proceso,
				n27_codigo_arch, n27_tipo_arch, n27_secuencia)
			references "fobos".rolt026
			constraint "fobos".fk_01_rolt027);

alter table "fobos".rolt027
	add constraint
		(foreign key (n27_compania)
			references "fobos".rolt001
			constraint "fobos".fk_02_rolt027);

alter table "fobos".rolt027
	add constraint
		(foreign key (n27_compania, n27_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_03_rolt027);

alter table "fobos".rolt027
	add constraint
		(foreign key (n27_sectorial)
			references "fobos".rolt017
			constraint "fobos".fk_04_rolt027);

alter table "fobos".rolt027
	add constraint
		(foreign key (n27_compania, n27_codigo_arch, n27_tipo_arch,
				n27_tipo_causa, n27_sec_cau)
			references "fobos".rolt023
			constraint "fobos".fk_05_rolt027);

alter table "fobos".rolt027
	add constraint
		(foreign key (n27_compania, n27_codigo_arch, n27_tipo_arch,
				n27_tipo_pago, n27_flag_pago)
			references "fobos".rolt024
			constraint "fobos".fk_06_rolt027);

alter table "fobos".rolt027
	add constraint
		(foreign key (n27_usua_elimin)
			references "fobos".gent005
			constraint "fobos".fk_07_rolt027);

alter table "fobos".rolt027
	add constraint
		(foreign key (n27_usua_modifi)
			references "fobos".gent005
			constraint "fobos".fk_08_rolt027);


commit work;

--drop table rolt026;

{-- TABLA: CABECERA DEL ARCHIVO BATCH PARA IESS --}

begin work;

create table "fobos".rolt026
	(

		n26_compania		integer			not null,
		n26_ano_proceso		integer			not null,
		n26_mes_proceso		smallint		not null,
		n26_codigo_arch		smallint		not null,
		n26_tipo_arch		char(3)			not null,
		n26_secuencia		smallint		not null,
		n26_estado		char(1)			not null,
		n26_nombre_arch		varchar(30,10)		not null,
		n26_ruc_patronal	varchar(15,0)		not null,
		n26_sucursal		char(4)			not null,
		n26_ano_carga		integer			not null,
		n26_mes_carga		smallint		not null,
		n26_jornada		char(1),
		n26_sec_jor		smallint,
		n26_codigo_seg		char(1),
		n26_tipo_seg		char(1),
		n26_codigo_empl		char(2),
		n26_tipo_empl		char(3),
		n26_codigo_rela		char(2),
		n26_tipo_rela		char(3),
		n26_total_ext		decimal(14,2)		not null,
		n26_total_adi		decimal(14,2)		not null,
		n26_total_net		decimal(14,2)		not null,
		n26_usua_elimin		varchar(10,5),
		n26_fec_elimin		datetime year to second,
		n26_usua_cierre		varchar(10,5),
		n26_fec_cierre		datetime year to second,
		n26_usuario		varchar(10,5)		not null,
		n26_fecing		datetime year to second	not null,

		check	(n26_estado	in	('G', 'C', 'E'))
			constraint "fobos".ck_01_rolt026,

		check	(n26_mes_carga	between 1 and 12)
			constraint "fobos".ck_02_rolt026

	) in datadbs lock mode row;


revoke all on "fobos".rolt026 from "public";


create unique index "fobos".i01_pk_rolt026
	on "fobos".rolt026
		(n26_compania, n26_ano_proceso, n26_mes_proceso,n26_codigo_arch,
		 n26_tipo_arch, n26_secuencia)
	in idxdbs;

create index "fobos".i01_fk_rolt026
	on "fobos".rolt026
		(n26_compania)
	in idxdbs;

create index "fobos".i02_fk_rolt026
	on "fobos".rolt026
		(n26_compania, n26_codigo_arch, n26_tipo_arch)
	in idxdbs;

create index "fobos".i03_fk_rolt026
	on "fobos".rolt026
		(n26_compania, n26_codigo_arch, n26_tipo_arch, n26_jornada,
		 n26_sec_jor)
	in idxdbs;

create index "fobos".i04_fk_rolt026
	on "fobos".rolt026
		(n26_compania, n26_codigo_arch, n26_tipo_arch, n26_codigo_seg,
		 n26_tipo_seg)
	in idxdbs;

create index "fobos".i05_fk_rolt026
	on "fobos".rolt026
		(n26_compania, n26_codigo_arch, n26_tipo_arch, n26_codigo_empl,
		 n26_tipo_empl)
	in idxdbs;

create index "fobos".i06_fk_rolt026
	on "fobos".rolt026
		(n26_compania, n26_codigo_arch, n26_tipo_arch, n26_codigo_rela,
		 n26_tipo_rela)
	in idxdbs;

create index "fobos".i07_fk_rolt026
	on "fobos".rolt026
		(n26_usua_elimin)
	in idxdbs;

create index "fobos".i08_fk_rolt026
	on "fobos".rolt026
		(n26_usua_cierre)
	in idxdbs;

create index "fobos".i09_fk_rolt026
	on "fobos".rolt026
		(n26_usuario)
	in idxdbs;


alter table "fobos".rolt026
	add constraint
		primary key (n26_compania, n26_ano_proceso, n26_mes_proceso,
				n26_codigo_arch, n26_tipo_arch, n26_secuencia)
			constraint "fobos".pk_rolt026;

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_compania)
			references "fobos".rolt001
			constraint "fobos".fk_01_rolt026);

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_compania, n26_codigo_arch, n26_tipo_arch)
			references "fobos".rolt022
			constraint "fobos".fk_02_rolt026);

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_compania, n26_codigo_arch, n26_tipo_arch,
				n26_jornada, n26_sec_jor)
			references "fobos".rolt023
			constraint "fobos".fk_03_rolt026);

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_compania, n26_codigo_arch, n26_tipo_arch,
				n26_codigo_seg, n26_tipo_seg)
			references "fobos".rolt024
			constraint "fobos".fk_04_rolt026);

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_compania, n26_codigo_arch, n26_tipo_arch,
				n26_codigo_empl, n26_tipo_empl)
			references "fobos".rolt025
			constraint "fobos".fk_05_rolt026);

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_compania, n26_codigo_arch, n26_tipo_arch,
				n26_codigo_rela, n26_tipo_rela)
			references "fobos".rolt025
			constraint "fobos".fk_06_rolt026);

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_usua_elimin)
			references "fobos".gent005
			constraint "fobos".fk_07_rolt026);

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_usua_cierre)
			references "fobos".gent005
			constraint "fobos".fk_08_rolt026);

alter table "fobos".rolt026
	add constraint
		(foreign key (n26_usuario)
			references "fobos".gent005
			constraint "fobos".fk_09_rolt026);


commit work;

drop table rolt091;

begin work;


-- TABLA PARA ANTICIPOS DE VACACIONES DE EMPLEADOS --

create table "fobos".rolt091
	(

		n91_compania		integer			not null,
		n91_proceso		char(2)			not null,
		n91_cod_trab		integer			not null,
		n91_num_ant		smallint		not null,
		n91_fecha_ant		date			not null,
		n91_motivo_ant		varchar(50,30)		not null,
		n91_prov_aport		char(1)			not null,
		n91_valor_gan		decimal(12,2)		not null,
		n91_val_vac_par		decimal(12,2)		not null,
		n91_val_pro_apor	decimal(11,2)		not null,
		n91_valor_tope		decimal(12,2)		not null,
		n91_valor_ant		decimal(12,2)		not null,
		n91_tipo_pago		char(1)			not null,
		n91_bco_empresa		integer,
		n91_cta_empresa		char(15),
		n91_cta_trabaj		char(15),
		n91_proc_vac		char(2)			not null,
		n91_periodo_ini		date			not null,
		n91_periodo_fin		date			not null,
		n91_tipo_comp		char(2),
		n91_num_comp		char(8),
		n91_usuario		varchar(10,5)		not null,
		n91_fecing		datetime year to second	not null,

		check (n91_prov_aport	in ("S", "N"))
			constraint "fobos".ck_01_rolt091,

		check (n91_tipo_pago	in ("E", "C", "T"))
			constraint "fobos".ck_02_rolt091

	) in datadbs lock mode row;

revoke all on "fobos".rolt091 from "public";


create unique index "fobos".i01_pk_rolt091 on "fobos".rolt091
	(n91_compania, n91_proceso, n91_cod_trab, n91_num_ant) in idxdbs;
	
create index "fobos".i01_fk_rolt091 on "fobos".rolt091 (n91_compania) in idxdbs;

create index "fobos".i02_fk_rolt091 on "fobos".rolt091 (n91_proceso) in idxdbs;

create index "fobos".i03_fk_rolt091 on "fobos".rolt091
	(n91_compania, n91_cod_trab) in idxdbs;

create index "fobos".i04_fk_rolt091 on "fobos".rolt091
	(n91_bco_empresa) in idxdbs;

create index "fobos".i05_fk_rolt091 on "fobos".rolt091
	(n91_compania, n91_bco_empresa, n91_cta_empresa) in idxdbs;

create index "fobos".i06_fk_rolt091 on "fobos".rolt091 (n91_proc_vac) in idxdbs;

create index "fobos".i07_fk_rolt091 on "fobos".rolt091 (n91_usuario) in idxdbs;

create index "fobos".i08_fk_rolt091 on "fobos".rolt091
	(n91_compania, n91_tipo_comp, n91_num_comp) in idxdbs;


alter table "fobos".rolt091
	add constraint
		primary key (n91_compania, n91_proceso, n91_cod_trab,
				n91_num_ant)
			constraint "fobos".pk_rolt091;

alter table "fobos".rolt091
	add constraint (foreign key (n91_compania)
			references "fobos".rolt000
			constraint "fobos".fk_01_rolt091);

alter table "fobos".rolt091
	add constraint (foreign key (n91_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt091);

alter table "fobos".rolt091
	add constraint (foreign key (n91_compania, n91_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_03_rolt091);

alter table "fobos".rolt091
	add constraint (foreign key (n91_bco_empresa)
			references "fobos".gent008
			constraint "fobos".fk_04_rolt091);

alter table "fobos".rolt091
	add constraint (foreign key (n91_compania, n91_bco_empresa,
				n91_cta_empresa)
			references "fobos".gent009
			constraint "fobos".fk_05_rolt091);

alter table "fobos".rolt091
	add constraint (foreign key (n91_proc_vac)
			references "fobos".rolt003
			constraint "fobos".fk_06_rolt091);

alter table "fobos".rolt091
	add constraint (foreign key (n91_usuario)
			references "fobos".gent005
			constraint "fobos".fk_07_rolt091);

alter table "fobos".rolt091
	add constraint (foreign key (n91_compania, n91_tipo_comp, n91_num_comp)
			references "fobos".ctbt012
			constraint "fobos".fk_08_rolt091);


commit work;

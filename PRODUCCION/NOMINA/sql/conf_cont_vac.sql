--drop table rolt056;
--drop table rolt057;

--alter table "fobos".rolt039 drop n39_gozar_adic;


begin work;

-- CREACION DE TABLA CONFIGURACION CONTABLE VACACIONES --
create table "fobos".rolt056
	(

		n56_compania		integer			not null,
		n56_proceso		char(2)			not null,
		n56_cod_depto		smallint		not null,
		n56_cod_trab		integer			not null,
		n56_aux_val_vac		char(12)		not null,
		n56_aux_val_adi		char(12),
		n56_aux_otr_ing		char(12),
		n56_aux_iess		char(12)		not null,
		n56_aux_otr_egr		char(12),
		n56_aux_banco		char(12)		not null,
		n56_usuario		varchar(10,5)		not null,
		n56_fecing		datetime year to second	not null

	) in datadbs lock mode row;
--

revoke all on "fobos".rolt056 from "public";

-- CREACION DE INDICES EN TABLA CONFIGURACION CONTABLE VACACIONES --
create unique index "fobos".i01_pk_rolt056 on "fobos".rolt056
	(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab) in idxdbs;

create index "fobos".i01_fk_rolt056 on "fobos".rolt056 (n56_proceso) in idxdbs;

create index "fobos".i02_fk_rolt056 on "fobos".rolt056
	(n56_compania, n56_cod_depto) in idxdbs;

create index "fobos".i03_fk_rolt056 on "fobos".rolt056
	(n56_compania, n56_cod_trab) in idxdbs;

create index "fobos".i04_fk_rolt056 on "fobos".rolt056
	(n56_compania, n56_aux_val_vac) in idxdbs;

create index "fobos".i05_fk_rolt056 on "fobos".rolt056
	(n56_compania, n56_aux_val_adi) in idxdbs;

create index "fobos".i06_fk_rolt056 on "fobos".rolt056
	(n56_compania, n56_aux_otr_ing) in idxdbs;

create index "fobos".i07_fk_rolt056 on "fobos".rolt056
	(n56_compania, n56_aux_iess) in idxdbs;

create index "fobos".i08_fk_rolt056 on "fobos".rolt056
	(n56_compania, n56_aux_otr_egr) in idxdbs;

create index "fobos".i09_fk_rolt056 on "fobos".rolt056
	(n56_compania, n56_aux_banco) in idxdbs;

create index "fobos".i10_fk_rolt056 on "fobos".rolt056 (n56_usuario) in idxdbs;
--

-- CREACION DE CONSTRAINT EN TABLA CONFIGURACION CONTABLE VACACIONES --
alter table "fobos".rolt056
	add constraint
		primary key (n56_compania, n56_proceso, n56_cod_depto,
				n56_cod_trab)
			constraint "fobos".pk_rolt056;

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_01_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_compania, n56_cod_depto)
			references "fobos".gent034
			constraint "fobos".fk_02_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_compania, n56_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_03_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_compania, n56_aux_val_vac)
			references "fobos".ctbt010
			constraint "fobos".fk_04_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_compania, n56_aux_val_adi)
			references "fobos".ctbt010
			constraint "fobos".fk_05_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_compania, n56_aux_otr_ing)
			references "fobos".ctbt010
			constraint "fobos".fk_06_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_compania, n56_aux_iess)
			references "fobos".ctbt010
			constraint "fobos".fk_07_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_compania, n56_aux_otr_egr)
			references "fobos".ctbt010
			constraint "fobos".fk_08_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_compania, n56_aux_banco)
			references "fobos".ctbt010
			constraint "fobos".fk_09_rolt056);

alter table "fobos".rolt056
	add constraint
		(foreign key (n56_usuario)
			references "fobos".gent005
			constraint "fobos".fk_10_rolt056);
--
--

-- CREACION DE TABLA RELACIONAL CONTABILIDAD/VACACIONES --
create table "fobos".rolt057
	(

		n57_compania		integer			not null,
		n57_cod_trab		integer			not null,
		n57_periodo_ini		date			not null,
		n57_periodo_fin		date			not null,
		n57_secuencia		smallint		not null,
		n57_tipo_comp		char(2)			not null,
		n57_num_comp		char(8)			not null

	) in datadbs lock mode row;
--

revoke all on "fobos".rolt057 from "public";

-- CREACION DE INDICES EN TABLA RELACIONAL CONTABILIDAD/VACACIONES --
create unique index "fobos".i01_pk_rolt057 on "fobos".rolt057
	(n57_compania, n57_cod_trab, n57_periodo_ini, n57_periodo_fin,
		n57_secuencia, n57_tipo_comp, n57_num_comp)
	in idxdbs;

create index "fobos".i01_fk_rolt057 on "fobos".rolt057
	(n57_compania, n57_cod_trab, n57_periodo_ini, n57_periodo_fin,
		n57_secuencia)
	in idxdbs;

create index "fobos".i02_fk_rolt057 on "fobos".rolt057
	(n57_compania, n57_tipo_comp, n57_num_comp) in idxdbs;
--

-- CREACION DE CONSTRAINT EN TABLA RELACIONAL CONTABILIDAD/VACACIONES --
alter table "fobos".rolt057
	add constraint
		primary key (n57_compania, n57_cod_trab, n57_periodo_ini,
				n57_periodo_fin, n57_secuencia, n57_tipo_comp,
				n57_num_comp)
			constraint "fobos".pk_rolt057;

alter table "fobos".rolt057
	add constraint
		(foreign key (n57_compania, n57_cod_trab, n57_periodo_ini,
				n57_periodo_fin, n57_secuencia)
			references "fobos".rolt039
			constraint "fobos".fk_01_rolt057);

alter table "fobos".rolt057
	add constraint
		(foreign key (n57_compania, n57_tipo_comp, n57_num_comp)
			references "fobos".ctbt012
			constraint "fobos".fk_02_rolt057);
--
--

-- CREACION DE CONSTRAINT EN TABLA DE VACACIONES --
alter table "fobos".rolt039 add (n39_gozar_adic char(1) before n39_usuario);

update "fobos".rolt039 set n39_gozar_adic = 'S' where 1 = 1;

alter table "fobos".rolt039 modify (n39_gozar_adic char(1) not null);

alter table "fobos".rolt039
	add constraint check (n39_gozar_adic in ('S', 'N'))
		constraint "fobos".ck_01_rolt039;
--
--

commit work;

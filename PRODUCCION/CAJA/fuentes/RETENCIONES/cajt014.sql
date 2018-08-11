drop table cajt014;

begin work;

--------------------------------------------------------------------------------
create table "fobos".cajt014
	(

		j14_compania		integer			not null,
		j14_localidad		smallint		not null,
		j14_tipo_fuente		char(2)			not null,
		j14_num_fuente		integer			not null,
		j14_secuencia		smallint		not null,
		j14_codigo_pago		char(2)			not null,
		j14_num_ret_sri		char(16)		not null,
		j14_sec_ret		smallint		not null,
		j14_fecha_emi		date			not null,
		j14_cedruc		char(15)		not null,
		j14_razon_social	varchar(100,50)		not null,
		j14_num_fact_sri	char(16)		not null,
		j14_autorizacion	varchar(15,10)		not null,
		j14_fec_emi_fact	date			not null,
		j14_tipo_ret		char(1)			not null,
		j14_porc_ret		decimal(5,2)		not null,
		j14_codigo_sri		char(6)			not null,
		j14_base_imp		decimal(12,2)		not null,
		j14_valor_ret		decimal(12,2)		not null,
		j14_cont_cred		char(1)			not null,
		j14_tipo_doc		char(2),
		j14_tipo_fue		char(2),
		j14_cod_tran		char(2),
		j14_num_tran		decimal(15,0),
		j14_tipo_comp		char(2),
		j14_num_comp		char(8),
		j14_usuario		varchar(10,5)		not null,
		j14_fecing		datetime year to second	not null,

		check (j14_tipo_ret in ("F", "I"))
			constraint "fobos".ck_01_cajt014,

		check (j14_cont_cred in ("C", "R"))
			constraint "fobos".ck_02_cajt014

	) in datadbs lock mode row;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
revoke all on "fobos".cajt014 from "public";
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_cajt014
	on "fobos".cajt014
		(j14_compania, j14_localidad, j14_tipo_fuente,
		 j14_num_fuente, j14_secuencia, j14_codigo_pago,
		 j14_num_ret_sri, j14_sec_ret)
	in idxdbs;

create index "fobos".i01_fk_cajt014
	on "fobos".cajt014
		(j14_compania, j14_localidad, j14_tipo_fuente,
		 j14_num_fuente, j14_secuencia)
	in idxdbs;

create index "fobos".i02_fk_cajt014
	on "fobos".cajt014
		(j14_compania, j14_tipo_ret, j14_porc_ret)
	in idxdbs;

create index "fobos".i03_fk_cajt014
	on "fobos".cajt014
		(j14_compania, j14_tipo_ret, j14_porc_ret, j14_codigo_sri)
	in idxdbs;

create index "fobos".i04_fk_cajt014
	on "fobos".cajt014
		(j14_compania, j14_codigo_pago, j14_cont_cred)
	in idxdbs;

create index "fobos".i05_fk_cajt014
	on "fobos".cajt014
		(j14_compania, j14_localidad, j14_tipo_doc, j14_tipo_fue,
		 j14_cod_tran, j14_num_tran)
	in idxdbs;

create index "fobos".i06_fk_cajt014
	on "fobos".cajt014
		(j14_compania, j14_tipo_comp, j14_num_comp)
	in idxdbs;

create index "fobos".i07_fk_cajt014
	on "fobos".cajt014
		(j14_usuario)
	in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".cajt014
	add constraint
		primary key (j14_compania, j14_localidad, j14_tipo_fuente,
				j14_num_fuente, j14_secuencia, j14_codigo_pago,
				j14_num_ret_sri, j14_sec_ret)
			constraint "fobos".pk_cajt014;

alter table "fobos".cajt014
	add constraint
		(foreign key (j14_compania, j14_localidad, j14_tipo_fuente,
				j14_num_fuente, j14_secuencia)
			references "fobos".cajt011
			constraint "fobos".fk_01_cajt014);

alter table "fobos".cajt014
	add constraint
		(foreign key (j14_compania, j14_tipo_ret, j14_porc_ret)
			references "fobos".ordt002
			constraint "fobos".fk_02_cajt014);

alter table "fobos".cajt014
	add constraint
		(foreign key (j14_compania, j14_tipo_ret, j14_porc_ret,
				j14_codigo_sri)
			references "fobos".ordt003
			constraint "fobos".fk_03_cajt014);

alter table "fobos".cajt014
	add constraint
		(foreign key (j14_compania, j14_codigo_pago, j14_cont_cred)
			references "fobos".cajt001
			constraint "fobos".fk_04_cajt014);

alter table "fobos".cajt014
	add constraint
		(foreign key (j14_compania, j14_localidad, j14_tipo_doc,
				j14_tipo_fue, j14_cod_tran, j14_num_tran)
			references "fobos".rept038
			constraint "fobos".fk_05_cajt014);

alter table "fobos".cajt014
	add constraint
		(foreign key (j14_compania, j14_tipo_comp, j14_num_comp)
			references "fobos".ctbt012
			constraint "fobos".fk_06_cajt014);

alter table "fobos".cajt014
	add constraint
		(foreign key (j14_usuario)
			references "fobos".gent005
			constraint "fobos".fk_07_cajt014);
--------------------------------------------------------------------------------

commit work;

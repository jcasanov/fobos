begin work;

--------------------------------------------------------------------------------
create table "fobos".cxct009
	(

		z09_compania		integer			not null,
		z09_codcli		integer			not null,
		z09_tipo_ret		char(1)			not null,
		z09_porcentaje		decimal(5,2)		not null,
		z09_codigo_sri		char(6)			not null,
		z09_codigo_pago		char(2)			not null,
		z09_cont_cred		char(1)			not null,
		z09_aux_cont		char(12),
		z09_usuario		varchar(10,5)		not null,
		z09_fecing		datetime year to second	not null

	) in datadbs lock mode row;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
revoke all on "fobos".cxct009 from "public";
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_cxct009
	on "fobos".cxct009
		(z09_compania, z09_codcli, z09_tipo_ret, z09_porcentaje,
		 z09_codigo_sri, z09_codigo_pago, z09_cont_cred)
	in idxdbs;

create index "fobos".i01_fk_cxct009
	on "fobos".cxct009
		(z09_compania, z09_codcli, z09_tipo_ret, z09_porcentaje,
		 z09_codigo_sri)
	in idxdbs;

create index "fobos".i02_fk_cxct009
	on "fobos".cxct009
		(z09_compania)
	in idxdbs;

create index "fobos".i03_fk_cxct009
	on "fobos".cxct009
		(z09_codcli)
	in idxdbs;

create index "fobos".i04_fk_cxct009
	on "fobos".cxct009
		(z09_compania, z09_tipo_ret, z09_porcentaje)
	in idxdbs;

create index "fobos".i05_fk_cxct009
	on "fobos".cxct009
		(z09_compania, z09_tipo_ret, z09_porcentaje, z09_codigo_sri)
	in idxdbs;

create index "fobos".i06_fk_cxct009
	on "fobos".cxct009
		(z09_compania, z09_codigo_pago, z09_cont_cred)
	in idxdbs;

create index "fobos".i07_fk_cxct009
	on "fobos".cxct009
		(z09_compania, z09_aux_cont)
	in idxdbs;

create index "fobos".i08_fk_cxct009
	on "fobos".cxct009
		(z09_usuario)
	in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".cxct009
	add constraint
		primary key (z09_compania, z09_codcli, z09_tipo_ret,
				z09_porcentaje, z09_codigo_sri, z09_codigo_pago,
				z09_cont_cred)
			constraint "fobos".pk_cxct009;

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_compania, z09_codcli, z09_tipo_ret,
				z09_porcentaje, z09_codigo_sri)
			references "fobos".cxct008
			constraint "fobos".fk_01_cxct009);

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_compania)
			references "fobos".cxct000
			constraint "fobos".fk_02_cxct009);

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_codcli)
			references "fobos".cxct001
			constraint "fobos".fk_03_cxct009);

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_compania, z09_tipo_ret, z09_porcentaje)
			references "fobos".ordt002
			constraint "fobos".fk_04_cxct009);

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_compania, z09_tipo_ret, z09_porcentaje,
				z09_codigo_sri)
			references "fobos".ordt003
			constraint "fobos".fk_05_cxct009);

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_compania, z09_codigo_pago, z09_cont_cred)
			references "fobos".cajt001
			constraint "fobos".fk_06_cxct009);

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_compania, z09_aux_cont)
			references "fobos".ctbt010
			constraint "fobos".fk_07_cxct009);

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_usuario)
			references "fobos".gent005
			constraint "fobos".fk_08_cxct009);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
select z08_compania, z08_codcli, z08_tipo_ret, z08_porcentaje, z08_codigo_sri,
	j01_codigo_pago, j01_cont_cred, 'FOBOS' usuario, current fecing
	from cxct008, cajt001
	where z08_compania     = j01_compania
	  and z08_tipo_ret     = 'F'
	  and j01_codigo_pago in ('RT', 'RJ')
	  and j01_estado       = 'A'
union
select z08_compania, z08_codcli, z08_tipo_ret, z08_porcentaje, z08_codigo_sri,
	j01_codigo_pago, j01_cont_cred, 'FOBOS' usuario, current fecing
	from cxct008, cajt001
	where z08_compania     = j01_compania
	  and z08_tipo_ret     = 'I'
	  and j01_codigo_pago in ('RI')
	  and j01_estado       = 'A'
	into temp t1;
insert into cxct009
	(z09_compania, z09_codcli, z09_tipo_ret, z09_porcentaje, z09_codigo_sri,
	 z09_codigo_pago, z09_cont_cred, z09_usuario, z09_fecing)
	select * from t1;
drop table t1;
--------------------------------------------------------------------------------

commit work;

drop table cajt091;

begin work;

--------------------------------------------------------------------------------
create table "fobos".cajt091
	(

		j91_compania		integer			not null,
		j91_codigo_pago		char(2)			not null,
		j91_cont_cred		char(1)			not null,
		j91_tipo_ret		char(1)			not null,
		j91_porcentaje		decimal(5,2)		not null,
		j91_aux_cont		char(12),
		j91_usuario		varchar(10,5)		not null,
		j91_fecing		datetime year to second	not null

	) in datadbs lock mode row;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
revoke all on "fobos".cajt091 from "public";
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_cajt091
	on "fobos".cajt091
		(j91_compania, j91_codigo_pago, j91_cont_cred, j91_tipo_ret,
			j91_porcentaje)
	in idxdbs;

create index "fobos".i01_fk_cajt091
	on "fobos".cajt091
		(j91_compania, j91_codigo_pago, j91_cont_cred)
	in idxdbs;

create index "fobos".i02_fk_cajt091
	on "fobos".cajt091
		(j91_compania, j91_tipo_ret, j91_porcentaje)
	in idxdbs;

create index "fobos".i03_fk_cajt091
	on "fobos".cajt091
		(j91_compania, j91_aux_cont)
	in idxdbs;

create index "fobos".i04_fk_cajt091
	on "fobos".cajt091
		(j91_usuario)
	in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".cajt091
	add constraint
		primary key (j91_compania, j91_codigo_pago, j91_cont_cred,
				j91_tipo_ret, j91_porcentaje)
			constraint "fobos".pk_cajt091;

alter table "fobos".cajt091
	add constraint
		(foreign key (j91_compania, j91_codigo_pago, j91_cont_cred)
			references "fobos".cajt001
			constraint "fobos".fk_01_cajt091);

alter table "fobos".cajt091
	add constraint
		(foreign key (j91_compania, j91_tipo_ret, j91_porcentaje)
			references "fobos".ordt002
			constraint "fobos".fk_02_cajt091);

alter table "fobos".cajt091
	add constraint
		(foreign key (j91_compania, j91_aux_cont)
			references "fobos".ctbt010
			constraint "fobos".fk_03_cajt091);

alter table "fobos".cajt091
	add constraint
		(foreign key (j91_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_cajt091);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
select j01_compania, j01_codigo_pago, j01_cont_cred,c02_tipo_ret,c02_porcentaje,
	'FOBOS' usuario, current fecing
	from cajt001, ordt002
	where j01_codigo_pago in ('RT', 'RJ')
	  and j01_estado       = 'A'
	  and c02_compania     = j01_compania
	  and c02_tipo_ret     = 'F'
	  and c02_estado       = 'A'
union
select j01_compania, j01_codigo_pago, j01_cont_cred,c02_tipo_ret,c02_porcentaje,
	'FOBOS' usuario, current fecing
	from cajt001, ordt002
	where j01_codigo_pago  = 'RI'
	  and j01_estado       = 'A'
	  and c02_compania     = j01_compania
	  and c02_tipo_ret     = 'I'
	  and c02_estado       = 'A'
	into temp t1;

insert into cajt091
	(j91_compania, j91_codigo_pago, j91_cont_cred, j91_tipo_ret,
	 j91_porcentaje, j91_usuario, j91_fecing)
	select * from t1;

drop table t1;
--------------------------------------------------------------------------------

commit work;

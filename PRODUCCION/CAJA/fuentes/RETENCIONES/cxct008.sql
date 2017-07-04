drop table cxct009;
drop table cxct008;

begin work;

--------------------------------------------------------------------------------
create table "fobos".cxct008
	(

		z08_compania		integer			not null,
		z08_codcli		integer			not null,
		z08_tipo_ret		char(1)			not null,
		z08_porcentaje		decimal(5,2)		not null,
		z08_codigo_sri		char(6)			not null,
		z08_defecto		char(1)			not null,
		z08_flete		char(1)			not null,
		z08_usuario		varchar(10,5)		not null,
		z08_fecing		datetime year to second	not null,

		check (z08_defecto in ("S", "N"))
			constraint "fobos".ck_01_cxct008,

		check (z08_flete in ("S", "N"))
			constraint "fobos".ck_02_cxct008

	) in datadbs lock mode row;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
revoke all on "fobos".cxct008 from "public";
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_cxct008
	on "fobos".cxct008
		(z08_compania, z08_codcli, z08_tipo_ret, z08_porcentaje,
		 z08_codigo_sri)
	in idxdbs;

create index "fobos".i01_fk_cxct008
	on "fobos".cxct008
		(z08_compania)
	in idxdbs;

create index "fobos".i02_fk_cxct008
	on "fobos".cxct008
		(z08_codcli)
	in idxdbs;

create index "fobos".i03_fk_cxct008
	on "fobos".cxct008
		(z08_compania, z08_tipo_ret, z08_porcentaje)
	in idxdbs;

create index "fobos".i04_fk_cxct008
	on "fobos".cxct008
		(z08_compania, z08_tipo_ret, z08_porcentaje, z08_codigo_sri)
	in idxdbs;

create index "fobos".i05_fk_cxct008
	on "fobos".cxct008
		(z08_usuario)
	in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".cxct008
	add constraint
		primary key (z08_compania, z08_codcli, z08_tipo_ret,
				z08_porcentaje, z08_codigo_sri)
			constraint "fobos".pk_cxct008;

alter table "fobos".cxct008
	add constraint
		(foreign key (z08_compania)
			references "fobos".cxct000
			constraint "fobos".fk_01_cxct008);

alter table "fobos".cxct008
	add constraint
		(foreign key (z08_codcli)
			references "fobos".cxct001
			constraint "fobos".fk_02_cxct008);

alter table "fobos".cxct008
	add constraint
		(foreign key (z08_compania, z08_tipo_ret, z08_porcentaje)
			references "fobos".ordt002
			constraint "fobos".fk_03_cxct008);

alter table "fobos".cxct008
	add constraint
		(foreign key (z08_compania, z08_tipo_ret, z08_porcentaje,
				z08_codigo_sri)
			references "fobos".ordt003
			constraint "fobos".fk_04_cxct008);

alter table "fobos".cxct008
	add constraint
		(foreign key (z08_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_cxct008);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
select (select case when g02_localidad <= 5
			then 1
			else 2
		end 
	from gent002
	where g02_estado = 'A'
	  and g02_matriz = 'S') codcia, z01_codcli, c03_tipo_ret,
	c03_porcentaje, c03_codigo_sri,
	case when c03_porcentaje = 1 and c03_codigo_sri = 313
		then 'S' else 'N' end defecto,
	case when c03_porcentaje = 1 then 'S' else 'N' end flete,
	'FOBOS' usuario, current fecing
	from cxct001, ordt003
	where z01_estado      = 'A'
	  and c03_tipo_ret    = 'F'
	  and c03_porcentaje in (1, 2)
	  and c03_codigo_sri in (307, 313)
	  and c03_estado      = 'A'
	union
	select (select case when g02_localidad <= 5
				then 1
				else 2
			end 
		from gent002
		where g02_estado = 'A'
		  and g02_matriz = 'S') codcia, z01_codcli, c03_tipo_ret,
		c03_porcentaje, c03_codigo_sri,
		case when c03_porcentaje = 1 then 'S' else 'N' end defecto,
		case when c03_porcentaje = 1 then 'S' else 'N' end flete,
		'FOBOS' usuario, current fecing
		from cxct001, ordt003
		where z01_estado      = 'A'
		  and z01_paga_impto  = 'S'
		  and c03_tipo_ret    = 'I'
		  and c03_porcentaje in (30, 70)
		  and c03_codigo_sri in (819, 813)
		  and c03_estado      = 'A'
	into temp t1;
insert into cxct008
	(z08_compania, z08_codcli, z08_tipo_ret, z08_porcentaje, z08_codigo_sri,
	 z08_defecto, z08_flete, z08_usuario, z08_fecing)
	select * from t1;
drop table t1;
--------------------------------------------------------------------------------

commit work;

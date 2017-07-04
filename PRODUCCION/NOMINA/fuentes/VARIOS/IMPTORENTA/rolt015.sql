--------------------------------------------------------------------------------
begin work;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
drop table rolt015;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create table "fobos".rolt015

	(

		n15_compania		integer			not null,
		n15_ano			smallint		not null,
		n15_secuencia		smallint		not null,
		n15_base_imp_ini	decimal(12,2)		not null,
		n15_base_imp_fin	decimal(12,2)		not null,
		n15_fracc_base		decimal(12,2)		not null,
		n15_porc_ir		decimal(5,2)		not null,
		n15_usuario		varchar(10,5)		not null,
		n15_fecing		datetime year to second	not null

	) in datadbs lock mode row;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
revoke all on "fobos".rolt015 from "public";
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_rolt015
	on "fobos".rolt015
		(n15_compania, n15_ano, n15_secuencia)
	in idxdbs;

create index "fobos".i01_fk_rolt015
	on "fobos".rolt015
		(n15_compania)
	in idxdbs;

create index "fobos".i02_fk_rolt015
	on "fobos".rolt015
		(n15_usuario)
	in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".rolt015
	add constraint
		primary key (n15_compania, n15_ano, n15_secuencia)
			constraint "fobos".pk_rolt015;

alter table "fobos".rolt015
	add constraint
		(foreign key (n15_compania)
			references "fobos".rolt001
			constraint "fobos".fk_01_rolt015);

alter table "fobos".rolt015
	add constraint
		(foreign key (n15_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rolt015);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
select * from rolt015 where n15_compania = 999 into temp t1;

load from "tabla_ir.unl" insert into t1;

select n15_compania, n15_ano, n15_secuencia, n15_base_imp_ini,
	n15_base_imp_fin, n15_fracc_base,
	case when n15_ano = 2003
		then n15_porc_ir
		else n15_porc_ir * 100
	end n15_porc_ir, n15_usuario,
	nvl(case when n15_ano = 2003 then n15_fecing end, current) fecing
	from t1
	into temp t2;

drop table t1;

--select * from t2 order by n15_ano, n15_secuencia;
insert into rolt015 select * from t2;

drop table t2;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
commit work;
--------------------------------------------------------------------------------

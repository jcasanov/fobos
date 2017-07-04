begin work;

--drop table rolt049;

create table "fobos".rolt049
	(
		n49_compania			integer		not null,
		n49_proceso			char(2)		not null,
		n49_cod_trab			integer		not null,
		n49_fecha_ini			date		not null,
		n49_fecha_fin			date		not null,
		n49_cod_rubro			smallint	not null,
		n49_num_prest			integer,
		n49_orden			smallint	not null,
		n49_det_tot			char(2)		not null,
		n49_imprime_0			char(1)		not null,
		n49_valor			decimal(12,2)	not null,

		check (n49_det_tot in ('DI', 'DE', 'TI', 'TE', 'TN'))
			constraint "fobos".ck_01_rolt049,
		
		check (n49_imprime_0 in ('S', 'N'))
			constraint "fobos".ck_02_rolt049
	
	) in datadbs lock mode row;


revoke all on "fobos".rolt049 from "public";


create unique index "fobos".i01_pk_rolt049
	on "fobos".rolt049
		(n49_compania, n49_proceso, n49_cod_trab, n49_fecha_ini,
		 n49_fecha_fin, n49_cod_rubro)
	in idxdbs;

create index "fobos".i01_fk_rolt049
	on "fobos".rolt049
		(n49_compania, n49_proceso, n49_cod_trab, n49_fecha_ini,
		 n49_fecha_fin)
	in idxdbs;

create index "fobos".i02_fk_rolt049
	on "fobos".rolt049
		(n49_proceso)
	in idxdbs;

create index "fobos".i03_fk_rolt049
	on "fobos".rolt049
		(n49_compania, n49_cod_rubro)
	in idxdbs;

create index "fobos".i04_fk_rolt049
	on "fobos".rolt049
		(n49_compania, n49_num_prest)
	in idxdbs;


alter table "fobos".rolt049
	add constraint
		primary key (n49_compania, n49_proceso, n49_cod_trab,
				n49_fecha_ini,n49_fecha_fin, n49_cod_rubro)
		constraint "fobos".pk_rolt049;

alter table "fobos".rolt049
	add constraint
		(foreign key (n49_compania, n49_proceso, n49_cod_trab,
				n49_fecha_ini, n49_fecha_fin)
			references "fobos".rolt042
			constraint "fobos".fk_01_rolt049);

alter table "fobos".rolt049
	add constraint
		(foreign key (n49_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt049);

alter table "fobos".rolt049
	add constraint
		(foreign key (n49_compania, n49_cod_rubro)
			references "fobos".rolt009
			constraint "fobos".fk_03_rolt049);

alter table "fobos".rolt049
	add constraint
		(foreign key (n49_compania, n49_num_prest)
			references "fobos".rolt045
			constraint "fobos".fk_04_rolt049);


select n42_compania, n42_proceso, n42_cod_trab, n42_fecha_ini, n42_fecha_fin,
	n45_cod_rubro rubro, n45_num_prest, n06_orden, n06_det_tot,
	n06_imprime_0, n46_valor valor
	from rolt042, rolt045, rolt046, rolt006
	where n45_compania    = n42_compania
	  and n45_cod_trab    = n42_cod_trab
	  and n45_estado     <> 'E'
	  and n46_compania    = n45_compania
	  and n46_num_prest   = n45_num_prest
	  and n46_cod_liqrol  = 'UT'
          and n46_saldo       = 0
	  and n06_cod_rubro   = n45_cod_rubro
union
select n42_compania, n42_proceso, n42_cod_trab, n42_fecha_ini, n42_fecha_fin,
	57 rubro, 0 n45_num_prest, n06_orden, n06_det_tot, n06_imprime_0,
	n42_descuentos - n46_valor valor
	from rolt042, rolt045, rolt046, rolt006
	where n45_compania    = n42_compania
	  and n45_cod_trab    = n42_cod_trab
	  and n45_estado     <> 'E'
	  and n46_compania    = n45_compania
	  and n46_num_prest   = n45_num_prest
	  and n46_cod_liqrol  = 'UT'
          and n46_saldo       = 0
	  and n06_cod_rubro   = 57
	  and n42_descuentos  > n46_valor
union
select n42_compania, n42_proceso, n42_cod_trab, n42_fecha_ini, n42_fecha_fin,
	57 rubro, 0 n45_num_prest, n06_orden, n06_det_tot, n06_imprime_0,
	n42_descuentos valor
	from rolt042, rolt006
	where n42_descuentos  > 0
	  and not exists (select 1 from rolt045, rolt046
				where n45_compania    = n42_compania
				  and n45_cod_trab    = n42_cod_trab
				  and n45_estado     <> 'E'
				  and n46_compania    = n45_compania
				  and n46_num_prest   = n45_num_prest
				  and n46_cod_liqrol  = 'UT'
			          and n46_saldo       = 0)
	  and n06_cod_rubro   = 57
	into temp t1;

update t1 set n45_num_prest = null where n45_num_prest = 0;

insert into rolt049 select * from t1;

drop table t1;

commit work;

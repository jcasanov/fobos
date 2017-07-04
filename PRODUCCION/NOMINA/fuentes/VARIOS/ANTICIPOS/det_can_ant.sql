--drop table rolt092;

begin work;

alter table "fobos".rolt056 add (n56_estado char(1) before n56_aux_val_vac);
update "fobos".rolt056 set n56_estado = 'A' where 1 = 1;
alter table "fobos".rolt056 modify (n56_estado char(1) not null);
alter table "fobos".rolt056
	add constraint check (n56_estado in ('A', 'B'))
		constraint "fobos".ck_01_rolt056;

alter table "fobos".rolt091 modify (n91_proc_vac    char(2));
alter table "fobos".rolt091 modify (n91_periodo_ini date);
alter table "fobos".rolt091 modify (n91_periodo_fin date);

create table "fobos".rolt092
	(

		n92_compania		integer			not null,
		n92_proceso		char(2)			not null,
		n92_cod_trab		integer			not null,
		n92_num_ant		smallint		not null,
		n92_num_prest		integer			not null,
		n92_secuencia		smallint		not null,
		n92_cod_liqrol		char(2)			not null,
		n92_fecha_ini		date			not null,
		n92_fecha_fin		date			not null,
		n92_valor		decimal(12,2)		not null,
		n92_saldo		decimal(12,2)		not null,
		n92_valor_pago		decimal(12,2)		not null

	) in datadbs lock mode row;

revoke all on "fobos".rolt092 from "public";


create unique index "fobos".i01_pk_rolt092 on "fobos".rolt092
	(n92_compania, n92_proceso, n92_cod_trab, n92_num_ant, n92_num_prest,
		n92_secuencia)
	in idxdbs;
	
create index "fobos".i01_fk_rolt092 on "fobos".rolt092
	(n92_compania, n92_proceso, n92_cod_trab, n92_num_ant) in idxdbs;
	
create index "fobos".i02_fk_rolt092 on "fobos".rolt092 (n92_compania) in idxdbs;

create index "fobos".i03_fk_rolt092 on "fobos".rolt092 (n92_proceso) in idxdbs;

create index "fobos".i04_fk_rolt092 on "fobos".rolt092
	(n92_compania, n92_cod_trab) in idxdbs;

create index "fobos".i05_fk_rolt092 on "fobos".rolt092
	(n92_compania, n92_num_prest, n92_secuencia) in idxdbs;

create index "fobos".i06_fk_rolt092 on "fobos".rolt092
	(n92_cod_liqrol) in idxdbs;


alter table "fobos".rolt092
	add constraint
		primary key (n92_compania, n92_proceso, n92_cod_trab,
				n92_num_ant, n92_num_prest, n92_secuencia)
			constraint "fobos".pk_rolt092;

alter table "fobos".rolt092
	add constraint (foreign key (n92_compania, n92_proceso, n92_cod_trab,
				n92_num_ant)
			references "fobos".rolt091
			constraint "fobos".fk_01_rolt092);

alter table "fobos".rolt092
	add constraint (foreign key (n92_compania)
			references "fobos".rolt000
			constraint "fobos".fk_02_rolt092);

alter table "fobos".rolt092
	add constraint (foreign key (n92_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_03_rolt092);

alter table "fobos".rolt092
	add constraint (foreign key (n92_compania, n92_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_04_rolt092);

alter table "fobos".rolt092
	add constraint
		(foreign key (n92_compania, n92_num_prest, n92_secuencia)
			references "fobos".rolt046
			constraint "fobos".fk_05_rolt092);

alter table "fobos".rolt092
	add constraint (foreign key (n92_cod_liqrol)
			references "fobos".rolt003
			constraint "fobos".fk_06_rolt092);

commit work;

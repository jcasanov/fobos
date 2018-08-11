--------------------------------------------------------------------------------
begin work;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- ELIMINADO COLUMNA Y CLAVE PRIMARIA INNECESARIA
--------------------------------------------------------------------------------

drop index "fobos".i01_pk_rolt084;

alter table "fobos".rolt084
	drop constraint "fobos".pk_rolt084;

alter table "fobos".rolt084
	drop n84_ano;

alter table "fobos".rolt084
	drop n84_fondo_reserva;

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- AUMENTANDO NUEVAS COLUMNAS
--------------------------------------------------------------------------------

alter table "fobos".rolt084
	add (n84_proceso	char(2)		not null before n84_cod_trab);

alter table "fobos".rolt084
	add (n84_ano_proceso	smallint	not null before n84_estado);

alter table "fobos".rolt084
	add (n84_bonificacion	decimal(12,2)	not null before n84_otros_ing);

alter table "fobos".rolt084
	add (n84_total_gan	decimal(14,2)	not null before n84_imp_basico);

alter table "fobos".rolt084
	add (n84_usu_modifi	varchar(10,5));

alter table "fobos".rolt084
	add (n84_fec_modifi	datetime year to second);

alter table "fobos".rolt084
	add (n84_usu_elimin	varchar(10,5));

alter table "fobos".rolt084
	add (n84_fec_elimin	datetime year to second);

alter table "fobos".rolt084
	add (n84_usu_cierre	varchar(10,5));

alter table "fobos".rolt084
	add (n84_fec_cierre	datetime year to second);

alter table "fobos".rolt084
	add (n84_usuario	varchar(10,5)		not null);

alter table "fobos".rolt084
	add (n84_fecing		datetime year to second	not null);

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- CONSTRUYENDO NUEVA CLAVE PRIMARIA, INDICES Y CONSTRAINTS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- INDICES:
--------------------------------------------------------------------------------

create unique index "fobos".i01_pk_rolt084
	on "fobos".rolt084
		(n84_compania, n84_proceso, n84_cod_trab, n84_ano_proceso)
	in idxdbs;

create index "fobos".i04_fk_rolt084
	on "fobos".rolt084
		(n84_proceso)
	in idxdbs;

create index "fobos".i05_fk_rolt084
	on "fobos".rolt084
		(n84_usuario)
	in idxdbs;

create index "fobos".i06_fk_rolt084
	on "fobos".rolt084
		(n84_usu_modifi)
	in idxdbs;

create index "fobos".i07_fk_rolt084
	on "fobos".rolt084
		(n84_usu_elimin)
	in idxdbs;

create index "fobos".i08_fk_rolt084
	on "fobos".rolt084
		(n84_usu_cierre)
	in idxdbs;

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- NUEVA CLAVE PRIMARIA Y CONSTRAINTS:
--------------------------------------------------------------------------------

alter table "fobos".rolt084
	add constraint
		primary key (n84_compania, n84_proceso, n84_cod_trab,
				n84_ano_proceso)
			constraint "fobos".pk_rolt084;

alter table "fobos".rolt084
	add constraint
		(foreign key (n84_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_04_rolt084);

alter table "fobos".rolt084
	add constraint
		(foreign key (n84_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_rolt084);

alter table "fobos".rolt084
	add constraint
		(foreign key (n84_usu_modifi)
			references "fobos".gent005
			constraint "fobos".fk_06_rolt084);

alter table "fobos".rolt084
	add constraint
		(foreign key (n84_usu_elimin)
			references "fobos".gent005
			constraint "fobos".fk_07_rolt084);

alter table "fobos".rolt084
	add constraint
		(foreign key (n84_usu_cierre)
			references "fobos".gent005
			constraint "fobos".fk_08_rolt084);

--------------------------------------------------------------------------------

rename column rolt084.n84_decimo_cuarto  to n84_dec_cuarto;

rename column rolt084.n84_decimo_tercero to n84_dec_tercero;

--------------------------------------------------------------------------------
commit work;
--------------------------------------------------------------------------------

--drop table rolt021;

begin work;

create table "fobos".rolt021
	(

		n21_compania		integer			not null,
		n21_proceso		char(2)			not null,
		n21_fecha_ini		date			not null,
		n21_fecha_fin		date			not null,
		n21_cod_trab		integer			not null,
		n21_cod_rubro		smallint		not null,
		n21_fecha_trab		date			not null,
		n21_hor_ini_ent		datetime hour to second,
		n21_hor_ini_alm		datetime hour to second,
		n21_hor_fin_alm		datetime hour to second,
		n21_hor_fin_ent		datetime hour to second,
		n21_tot_hor_alm		decimal(11,2)		not null,
		n21_tot_hor_tra		decimal(11,2)		not null,
		n21_tot_dia_tra		decimal(11,2)		not null,
		n21_usuario		varchar(10,5)		not null,
		n21_fecing		datetime year to second	not null

	) in datadbs lock mode row;


revoke all on "fobos".rolt021 from "public";


create unique index "fobos".i01_pk_rolt021
	on "fobos".rolt021
		(n21_compania, n21_proceso, n21_fecha_ini, n21_fecha_fin,
		 n21_cod_trab, n21_cod_rubro, n21_fecha_trab)
	in idxdbs;

create index "fobos".i01_fk_rolt021
	on "fobos".rolt021
		(n21_compania)
	in idxdbs;

create index "fobos".i02_fk_rolt021
	on "fobos".rolt021
		(n21_proceso)
	in idxdbs;

create index "fobos".i03_fk_rolt021
	on "fobos".rolt021
		(n21_cod_rubro)
	in idxdbs;

create index "fobos".i04_fk_rolt021
	on "fobos".rolt021
		(n21_compania, n21_cod_trab)
	in idxdbs;

create index "fobos".i05_fk_rolt021
	on "fobos".rolt021
		(n21_usuario)
	in idxdbs;


alter table "fobos".rolt021
	add constraint
		primary key (n21_compania, n21_proceso, n21_fecha_ini,
				n21_fecha_fin, n21_cod_trab, n21_cod_rubro,
				n21_fecha_trab)
			constraint "fobos".pk_rolt021;

alter table "fobos".rolt021
	add constraint
		(foreign key (n21_compania)
			references "fobos".rolt001
			constraint "fobos".fk_01_rolt021);

alter table "fobos".rolt021
	add constraint
		(foreign key (n21_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt021);

alter table "fobos".rolt021
	add constraint
		(foreign key (n21_cod_rubro)
			references "fobos".rolt006
			constraint "fobos".fk_03_rolt021);

alter table "fobos".rolt021
	add constraint
		(foreign key (n21_compania, n21_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_04_rolt021);

alter table "fobos".rolt021
	add constraint
		(foreign key (n21_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_rolt021);


commit work;

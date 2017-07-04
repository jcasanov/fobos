drop table rolt073;

begin work;

create table "fobos".rolt073

	(
		n73_compania		integer			not null,
		n73_tipo_acta		smallint		not null,
		n73_estado		char(1)			not null,
		n73_abrevia		varchar(6,3)		not null,
		n73_concepto		varchar(100,40)		not null,
		n73_conc_abr		varchar(30,15)		not null,
		n73_usu_elimin		varchar(10,5),
		n73_fec_elimin		datetime year to second,
		n73_usuario		varchar(10,5)		not null,
		n73_fecing		datetime year to second	not null,

		check (n73_estado in ("A", "B"))
			constraint "fobos".ck_01_rolt073

	) in datadbs lock mode row;

revoke all on "fobos".rolt073 from "public";

create unique index "fobos".i01_pk_rolt073
	on "fobos".rolt073
		(n73_compania, n73_tipo_acta)
	in idxdbs;

create index "fobos".i01_fk_rolt073
	on "fobos".rolt073
		(n73_usu_elimin)
	in idxdbs;

create index "fobos".i02_fk_rolt073
	on "fobos".rolt073
		(n73_usuario)
	in idxdbs;

alter table "fobos".rolt073
	add constraint
		primary key (n73_compania, n73_tipo_acta)
			constraint "fobos".pk_rolt073;

alter table "fobos".rolt073
	add constraint
		(foreign key (n73_usu_elimin)
			references "fobos".gent005
			constraint "fobos".fk_01_rolt073);

alter table "fobos".rolt073
	add constraint
		(foreign key (n73_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rolt073);

insert into rolt073
	(n73_compania, n73_tipo_acta, n73_estado, n73_abrevia, n73_concepto,
	 n73_conc_abr, n73_usuario, n73_fecing)
	values (1, 1, "A", "R. VO.",
		"RENUNCIA VOLUNTARIA POR PARTE DEL EMPLEADO",
		"RENUNCIA VOLUNTARIA", "FOBOS", current);

insert into rolt073
	(n73_compania, n73_tipo_acta, n73_estado, n73_abrevia, n73_concepto,
	 n73_conc_abr, n73_usuario, n73_fecing)
	values (1, 2, "A", "D. IN.",
		"DESPIDO UNILATERAL POR PARTE DEL EMPLEADOR",
		"DESPIDO INTEMPESTIVO", "FOBOS", current);

insert into rolt073
	(n73_compania, n73_tipo_acta, n73_estado, n73_abrevia, n73_concepto,
	 n73_conc_abr, n73_usuario, n73_fecing)
	values (1, 3, "A", "V. BU.",
		"DESPIDO POR VISTO BUENO",
		"VISTO BUENO", "FOBOS", current);

commit work;

create table "fobos".srit021
	(

		s21_compania		integer			not null,
		s21_localidad		smallint		not null,
		s21_anio		smallint		not null,
		s21_mes			smallint		not null,
		s21_ident_cli		char(2)			not null,
		s21_num_doc_id		char(13)		not null,
		s21_tipo_comp		char(2)			not null,
		s21_fecha_reg_cont	date			not null,
		s21_num_comp_emi	integer			not null,
		s21_fecha_emi_vta	date			not null,
		s21_base_imp_tar_0	decimal(12,2)		not null,
		s21_iva_presuntivo	char(1)			not null,
		s21_bas_imp_gr_iva	decimal(12,2)		not null,
		s21_cod_porc_iva	char(1)			not null,
		s21_monto_iva		decimal(12,2)		not null,
		s21_base_imp_ice	decimal(12,2)		not null,
		s21_cod_porc_ice	char(2)			not null,
		s21_monto_ice		decimal(12,2)		not null,
		s21_monto_iva_bie	decimal(12,2)		not null,
		s21_cod_ret_ivabie	char(1)			not null,
		s21_mon_ret_ivabie	decimal(12,2)		not null,
		s21_monto_iva_ser	decimal(12,2)		not null,
		s21_cod_ret_ivaser	char(1)			not null,
		s21_mon_ret_ivaser	decimal(12,2)		not null,
		s21_ret_presuntivo	char(1)			not null,
		s21_concepto_ret	char(5)			not null,
		s21_base_imp_renta	decimal(12,2)		not null,
		s21_porc_ret_renta	decimal(5,2)		not null,
		s21_monto_ret_rent	decimal(12,2)		not null,
		s21_estado		char(1)			not null,
		s21_usuario_modif	varchar(10,5)		default null,
		s21_fec_modif		datetime year to second	default null,
		s21_usuario		varchar(10,5)		not null,
		s21_fecing		datetime year to second	not null,

		check (s21_estado in ('G', 'P', 'C', 'D'))
			constraint "fobos".ck_01_srit021,

		check (s21_iva_presuntivo in ('S', 'N'))
			constraint "fobos".ck_02_srit021,

		check (s21_ret_presuntivo in ('S', 'N'))
			constraint "fobos".ck_03_srit021

	) in datadbs lock mode row;

revoke all on "fobos".srit021 from "public";


create unique index "fobos".i01_pk_srit021
	on "fobos".srit021 (s21_compania, s21_localidad, s21_anio, s21_mes,
				s21_ident_cli, s21_num_doc_id, s21_tipo_comp)
		in idxdbs;

create index "fobos".i01_fk_srit021 on "fobos".srit021 (s21_usuario) in idxdbs;

create index "fobos".i02_fk_srit021
	on "fobos".srit021 (s21_usuario_modif) in idxdbs;


alter table "fobos".srit021
	add constraint
		primary key (s21_compania, s21_localidad, s21_anio, s21_mes,
				s21_ident_cli, s21_num_doc_id, s21_tipo_comp)
			constraint "fobos".pk_srit021;

alter table "fobos".srit021
	add constraint
		(foreign key (s21_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_srit021);

alter table "fobos".srit021
	add constraint
		(foreign key (s21_usuario_modif)
			references "fobos".gent005
			constraint "fobos".fk_02_srit021);

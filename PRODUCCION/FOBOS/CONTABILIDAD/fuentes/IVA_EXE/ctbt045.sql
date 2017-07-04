drop table ctbt045;

begin work;

create table "fobos".ctbt045 
	(

		b45_compania		integer			not null,
		b45_localidad		smallint		not null,
		b45_grupo_linea		char(5)			not null,
		b45_porc_impto		decimal(5,2)		not null,
		b45_tipo_cli		smallint		not null,
		b45_vta_mo_tal		char(12)		not null,
		b45_vta_mo_ext		char(12)		not null,
		b45_vta_mo_cti		char(12)		not null,
		b45_vta_rp_tal		char(12)		not null,
		b45_vta_rp_ext		char(12)		not null,
		b45_vta_rp_cti		char(12)		not null,
		b45_vta_rp_alm		char(12)		not null,
		b45_vta_otros1		char(12)		not null,
		b45_vta_otros2		char(12)		not null,
		b45_dvt_mo_tal		char(12),
		b45_dvt_mo_ext		char(12),
		b45_dvt_mo_cti		char(12),
		b45_dvt_rp_tal		char(12),
		b45_dvt_rp_ext		char(12),
		b45_dvt_rp_cti		char(12),
		b45_dvt_rp_alm		char(12),
		b45_dvt_otros1		char(12),
		b45_dvt_otros2		char(12),
		b45_cos_mo_tal		char(12),
		b45_cos_mo_ext		char(12),
		b45_cos_mo_cti		char(12),
		b45_cos_rp_tal		char(12),
		b45_cos_rp_ext		char(12),
		b45_cos_rp_cti		char(12),
		b45_cos_rp_alm		char(12),
		b45_cos_otros1		char(12),
		b45_cos_otros2		char(12),
		b45_pro_mo_tal		char(12),
		b45_pro_mo_ext		char(12),
		b45_pro_mo_cti		char(12),
		b45_pro_rp_tal		char(12),
		b45_pro_rp_ext		char(12),
		b45_pro_rp_cti		char(12),
		b45_pro_rp_alm		char(12),
		b45_pro_otros1		char(12),
		b45_pro_otros2		char(12),
		b45_des_mo_tal		char(12)		not null,
		b45_des_rp_tal		char(12)		not null,
		b45_des_rp_alm		char(12)		not null,
		b45_usuario		varchar(10,5)		not null,
		b45_fecing		datetime year to second	not null

	) in datadbs lock mode row;


revoke all on "fobos".ctbt045 from "public";


create unique index "fobos".i01_pk_ctbt045
	on "fobos".ctbt045
		(b45_compania, b45_localidad, b45_grupo_linea, b45_porc_impto,
		 b45_tipo_cli)
	in idxdbs;

create index "fobos".i01_fk_ctbt045 on "fobos".ctbt045 (b45_usuario) in idxdbs;


alter table "fobos".ctbt045
	add constraint
		primary key (b45_compania, b45_localidad, b45_grupo_linea,
				b45_porc_impto, b45_tipo_cli)
			constraint "fobos".pk_ctbt045;

alter table "fobos".ctbt045
	add constraint
		(foreign key (b45_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_ctbt045);


commit work;

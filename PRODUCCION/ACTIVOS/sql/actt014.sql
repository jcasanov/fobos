create table "fobos".actt014
	(
		a14_compania		integer			not null,
		a14_codigo_bien		integer			not null,
		a14_anio		smallint		not null,
		a14_mes			smallint		not null,
		a14_referencia		varchar(40,20)		not null,
		a14_grupo_act		smallint		not null,
		a14_tipo_act		smallint		not null,
		a14_anos_util		smallint		not null,
		a14_porc_deprec		decimal(4,2)		not null,
		a14_locali_ori		smallint		not null,
		a14_localidad		smallint		not null,
		a14_cod_depto		smallint		not null,
		a14_moneda		char(2)			not null,
		a14_paridad		decimal(16,9)		not null,
		a14_valor		decimal(12,2)		not null,
		a14_valor_mb		decimal(12,2)		not null,
		a14_fecha_baja		date,
		a14_val_dep_mb		decimal(11,2)		not null,
		a14_val_dep_ma		decimal(11,2)		not null,
		a14_dep_acum_act	decimal(14,2)		not null,
		a14_tot_dep_mb		decimal(12,2)		not null,
		a14_tot_dep_ma		decimal(12,2)		not null,
		a14_tot_reexpr		decimal(12,2)		not null,
		a14_tot_dep_ree		decimal(12,2)		not null,
		a14_tipo_comp		char(2),
		a14_num_comp		char(8),
		a14_usuario		varchar(10,5)		not null,
		a14_fecing		datetime year to second	not null
	);


create unique index "fobos".i01_pk_actt014 on "fobos".actt014
	(a14_compania, a14_codigo_bien, a14_anio, a14_mes);

create index "fobos".i01_fk_actt014 on "fobos".actt014 (a14_compania);

create index "fobos".i02_fk_actt014 on "fobos".actt014
	(a14_compania, a14_grupo_act);

create index "fobos".i03_fk_actt014 on "fobos".actt014
	(a14_compania, a14_tipo_act);

create index "fobos".i04_fk_actt014 on "fobos".actt014
	(a14_compania, a14_locali_ori);

create index "fobos".i05_fk_actt014 on "fobos".actt014
	(a14_compania, a14_localidad);

create index "fobos".i06_fk_actt014 on "fobos".actt014
	(a14_compania, a14_cod_depto);

create index "fobos".i07_fk_actt014 on "fobos".actt014 (a14_moneda);
    
create index "fobos".i08_fk_actt014 on "fobos".actt014
	(a14_compania, a14_tipo_comp, a14_num_comp);

create index "fobos".i09_fk_actt014 on "fobos".actt014 (a14_usuario);
    

alter table "fobos".actt014
	add constraint
		primary key (a14_compania, a14_codigo_bien, a14_anio, a14_mes)
			constraint "fobos".pk_actt014;

alter table "fobos".actt014
	add constraint (foreign key (a14_compania) references "fobos".actt000);

alter table "fobos".actt014
	add constraint (foreign key (a14_compania, a14_grupo_act)
			references "fobos".actt001);

alter table "fobos".actt014
	add constraint (foreign key (a14_compania, a14_tipo_act)
			references "fobos".actt002);

alter table "fobos".actt014
	add constraint (foreign key (a14_compania, a14_locali_ori)
			references "fobos".gent002);

alter table "fobos".actt014
	add constraint (foreign key (a14_compania, a14_localidad)
			references "fobos".gent002);

alter table "fobos".actt014
	add constraint (foreign key (a14_compania, a14_cod_depto)
			references "fobos".gent034);

alter table "fobos".actt014
	add constraint (foreign key (a14_moneda) references "fobos".gent013);

alter table "fobos".actt014
	add constraint (foreign key (a14_compania, a14_tipo_comp, a14_num_comp)
			references "fobos".ctbt012);

alter table "fobos".actt014
	add constraint (foreign key (a14_usuario) references "fobos".gent005);

alter table "fobos".actt014 lock mode (row);

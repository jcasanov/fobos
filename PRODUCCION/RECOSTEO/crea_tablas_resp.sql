begin work;

create table "fobos".rept019_res
	(

		r19_compania		integer			not null,
		r19_localidad		smallint		not null,
		r19_cod_tran		char(2)			not null,
		r19_num_tran		decimal(15,0)		not null,
		r19_tot_costo		decimal(12,2)		not null,
		r19_tot_neto		decimal(12,2)		not null,
		r19_comito		char(1)			not null,
		r19_usuario		varchar(10,5)		not null,
		r19_fecing		datetime year to second	not null,

		check (r19_comito in ('S', 'N'))
			constraint "fobos".ck_01_rept019_res

	) in datadbs lock mode row;

revoke all on "fobos".rept019_res from "public";

create unique index "fobos".i01_pk_rept019_res
	on "fobos".rept019_res
		(r19_compania, r19_localidad, r19_cod_tran, r19_num_tran)
	in idxdbs;

create index "fobos".i01_fk_rept019_res
	on "fobos".rept019_res
		(r19_usuario)
	in idxdbs;

alter table "fobos".rept019_res
	add constraint
		primary key (r19_compania, r19_localidad, r19_cod_tran,
				r19_num_tran)
			constraint "fobos".pk_rept019_res;

alter table "fobos".rept019_res
	add constraint
		(foreign key (r19_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rept019_res);


create table "fobos".rept020_res
	(

		r20_compania		integer			not null,
		r20_localidad		smallint		not null,
		r20_cod_tran		char(2)			not null,
		r20_num_tran		decimal(15,0)		not null,
		r20_bodega		char(2)			not null,
		r20_item		char(15)		not null,
		r20_orden		smallint		not null,
		r20_costo		decimal(13,4)		not null,
		r20_costant_mb		decimal(11,2)		not null,
		r20_costant_ma		decimal(11,2)		not null,
		r20_costnue_mb		decimal(11,2)		not null,
		r20_costnue_ma		decimal(11,2)		not null,
		r20_comito		char(1)			not null,
		r20_fecing		datetime year to second	not null,

		check (r20_comito in ('S', 'N'))
			constraint "fobos".ck_01_rept020_res

	) in datadbs lock mode row;

revoke all on "fobos".rept020_res from "public";

create unique index "fobos".i01_pk_rept020_res
	on "fobos".rept020_res
		(r20_compania, r20_localidad, r20_cod_tran, r20_num_tran,
		 r20_bodega, r20_item, r20_orden)
	in idxdbs;

create index "fobos".i01_fk_rept020_res
	on "fobos".rept020_res
		(r20_compania, r20_localidad, r20_cod_tran, r20_num_tran)
	in idxdbs;

alter table "fobos".rept020_res
	add constraint
		primary key (r20_compania, r20_localidad, r20_cod_tran,
				r20_num_tran, r20_bodega, r20_item, r20_orden)
			constraint "fobos".pk_rept020_res;

alter table "fobos".rept020_res
	add constraint
		(foreign key (r20_compania, r20_localidad, r20_cod_tran,
				r20_num_tran)
			references "fobos".rept019_res
			constraint "fobos".fk_01_rept020_res);


create table "fobos".rept010_res
	(

		r10_compania		integer			not null,
		r10_codigo		char(15)		not null,
		r10_costo_mb		decimal(11,2)		not null,
		r10_costo_ma		decimal(11,2)		not null,
		r10_costult_mb		decimal(11,2)		not null,
		r10_costult_ma		decimal(11,2)		not null,
		r10_comito		char(1)			not null,
		r10_usuario		varchar(10,5)		not null,
		r10_fecing		datetime year to second	not null,

		check (r10_comito in ('S', 'N'))
			constraint "fobos".ck_01_rept010_res

	) in datadbs lock mode row;

revoke all on "fobos".rept010_res from "public";

create unique index "fobos".i01_pk_rept010_res
	on "fobos".rept010_res
		(r10_compania, r10_codigo)
	in idxdbs;

create index "fobos".i01_fk_rept010_res
	on "fobos".rept010_res
		(r10_usuario)
	in idxdbs;

alter table "fobos".rept010_res
	add constraint
		primary key (r10_compania, r10_codigo)
			constraint "fobos".pk_rept010_res;

alter table "fobos".rept010_res
	add constraint
		(foreign key (r10_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rept010_res);


create table "fobos".ctbt013_res
	(

		b13_compania		integer			not null,
		b13_tipo_comp		char(2)			not null,
		b13_num_comp		char(8)			not null,
		b13_secuencia		smallint		not null,
		b13_cuenta		char(12)		not null,
		b13_valor_base		decimal(14,2)		not null,
		b13_comito		char(1)			not null,
		b13_usuario		varchar(10,5)		not null,
		b13_fecing		datetime year to second	not null,

		check (b13_comito in ('S', 'N'))
			constraint "fobos".ck_01_ctbt013_res

	) in datadbs lock mode row;

revoke all on "fobos".ctbt013_res from "public";

create unique index "fobos".i01_pk_ctbt013_res
	on "fobos".ctbt013_res
		(b13_compania, b13_tipo_comp, b13_num_comp, b13_secuencia)
	in idxdbs;

create index "fobos".i01_fk_ctbt013_res
	on "fobos".ctbt013_res
		(b13_usuario)
	in idxdbs;

alter table "fobos".ctbt013_res
	add constraint
		primary key (b13_compania, b13_tipo_comp, b13_num_comp,
				b13_secuencia)
			constraint "fobos".pk_ctbt013_res;

alter table "fobos".ctbt013_res
	add constraint
		(foreign key (b13_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_ctbt013_res);


create table "fobos".trans_ent

	(

		compania		integer			not null,
		localidad		smallint		not null,
		cod_tran		char(2)			not null,
		num_tran		decimal(15,0)		not null,
		item_ent		char(15)		not null,
		usuario			varchar(10,5)		not null,
		fecing			datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".trans_ent from "public";

create unique index "fobos".i01_pk_tra_ent
	on "fobos".trans_ent
		(compania, localidad, cod_tran, num_tran, item_ent)
	in idxdbs;

alter table "fobos".trans_ent
	add constraint
		primary key (compania, localidad, cod_tran, num_tran, item_ent)
			constraint "fobos".pk_tra_ent;


create table "fobos".trans_salida

	(

		compania		integer			not null,
		local_ent		smallint		not null,
		codtran_ent		char(2)			not null,
		numtran_ent		decimal(15,0)		not null,
		item_ent		char(15)		not null,
		local_sal		smallint		not null,
		codtran_sal		char(2)			not null,
		numtran_sal		decimal(15,0)		not null,
		item_sal		char(15)		not null,
		usuario			varchar(10,5)		not null,
		fecing			datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".trans_salida from "public";

create unique index "fobos".i01_pk_tra_sal
	on "fobos".trans_salida
		(compania, local_ent, codtran_ent, numtran_ent, item_ent)
	in idxdbs;

create unique index "fobos".i02_pk_tra_sal
	on "fobos".trans_salida
		(compania, local_sal, codtran_sal, numtran_sal, item_sal)
	in idxdbs;

alter table "fobos".trans_salida
	add constraint
		primary key (compania, local_ent, codtran_ent, numtran_ent,
				item_ent)
			constraint "fobos".pk_tra_sal;


create table "fobos".ite_cos_rea

	(

		compania		integer			not null,
		localidad		smallint		not null,
		item			char(15)		not null,
		desc_clase		varchar(50,20)		not null,
		desc_item		varchar(70,20)		not null,
		precio			decimal(11,2)		not null,
		costo			decimal(11,2)		not null,
		sto_dic_08		decimal(8,2)		not null,
		factor			decimal(10,4)		not null,
		costo_teo		decimal(11,2)		not null,
		costo_real		decimal(14,4)		not null,
		costo_sist		decimal(11,2)		not null,
		diferencia		decimal(14,4)		not null,
		margen			decimal(14,4)		not null

	) in datadbs lock mode row;

revoke all on "fobos".ite_cos_rea from "public";

create unique index "fobos".i01_pk_ite_cr
	on "fobos".ite_cos_rea
		(compania, localidad, item)
	in idxdbs;

alter table "fobos".ite_cos_rea
	add constraint
		primary key (compania, localidad, item)
			constraint "fobos".pk_ite_cr;

select localidad, item, desc_clase, desc_item, precio, costo, sto_dic_08,
	factor, costo_teo, costo_real, costo_sist, diferencia, margen
	from ite_cos_rea
	where compania = 999
	into temp t1;

load from "items_cos_real_gye.csv" delimiter "|" insert into t1;
load from "items_cos_real_uio.csv" delimiter "|" insert into t1;

insert into ite_cos_rea
	select 1, localidad, item, desc_clase, desc_item, precio, costo,
		sto_dic_08, factor, costo_teo, costo_real, costo_sist,
		diferencia, margen
		from t1
		where costo_teo > 0;

drop table t1;

commit work;

update statistics;

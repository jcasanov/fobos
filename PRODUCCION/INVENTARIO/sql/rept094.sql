begin work;

create table "fobos".rept094
	(r94_compania			integer			not null,
	r94_localidad			smallint		not null,
	r94_cod_tran			char(2)			not null,
	r94_num_tran			decimal(15,0)		not null,
	r94_fecing			datetime year to second	not null,
	r94_locali_fin			smallint default 3	not null,
	r94_codtra_fin			char(2),
	r94_numtra_fin			decimal(15,0),
	r94_fecing_fin			datetime year to second
						default current year to second,
	r94_traspasada			char(1)			not null,
	
	check (r94_traspasada IN ('S' ,'N'))
	) lock mode row;

create unique index "fobos".i01_pk_rept094 on "fobos".rept094
	(r94_compania, r94_localidad, r94_cod_tran, r94_num_tran) in idxdbs;

alter table "fobos".rept094
	add constraint
		primary key(r94_compania, r94_localidad, r94_cod_tran,
				r94_num_tran)
			constraint "fobos".pk_rept094;

commit work;

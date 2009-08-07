create table rept106 (
	r106_compania		integer			not null,
	r106_localidad		smallint		not null,
	r106_anio			smallint		not null,
	r106_mes			smallint		not null,
	r106_item			char(15)		not null,
	r106_unid_vtas		integer			not null,
	r106_valor_vtas		decimal(12, 2)	not null,
	r106_costo_vtas		decimal(12, 2)	not null,
	r106_pto_reorden	integer			not null,
	r106_eoq			integer			not null,	
	r106_stock_min		integer			not null,	
	r106_stock_seg		integer			not null,	
	r106_ult_cpp		decimal(12,2)	not null,
	r106_rota_und		integer			not null,
	r106_rota_finan		decimal(12,2)	not null,
	check (r106_anio >= 2002 and r106_anio <= 2100),
	check (r106_mes >= 1 and r106_mes <= 12),
	check (r106_pto_reorden >= 0),
	check (r106_eoq >= 0),
	check (r106_stock_min >= 0),
	check (r106_stock_seg >= 0),
	check (r106_ult_cpp >=0),
	check (r106_rota_und >=0),
	check (r106_rota_finan >=0)
) lock mode row;
revoke all on "fobos".rept106 from "public";

create unique index "fobos".i01_pk_rept106 on "fobos".rept106 
	(r106_compania, r106_localidad, r106_anio, r106_mes, r106_item);

create index "fobos".i01_fk_rept106 on "fobos".rept106 (r106_compania, r106_localidad)
	in idxdbs;
create index "fobos".i02_fk_rept106 on "fobos".rept106 (r106_compania, r106_item)
	in idxdbs;
create index "fobos".i03_oq_rept106 on "fobos".rept106 (r106_anio, r106_mes)
	in idxdbs;
    
alter table "fobos".rept106 add 
	constraint primary key (r106_compania, r106_localidad, r106_anio, r106_mes, r106_item)
    constraint "fobos".pk_rept106;

alter table "fobos".rept106 add constraint (foreign key (r106_compania, r106_item) 
	references "fobos".rept010 );
alter table "fobos".rept106 add constraint (foreign key (r106_compania, r106_localidad) 
    references "fobos".gent002 );

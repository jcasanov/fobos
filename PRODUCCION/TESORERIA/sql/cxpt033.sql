--drop table cxpt033;

begin work;


create table "fobos".cxpt033

	(

		p33_compania		integer			not null,
		p33_localidad		smallint		not null,
		p33_numero_oc		integer			not null,
		p33_secuencia		smallint		not null,
		p33_cod_prov_ant	integer			not null,
		p33_nom_prov_ant	varchar(100,50)		not null,
		p33_num_fac_ant		char(15)		not null,
		p33_num_aut_ant		char(10)		not null,
		p33_fec_cad_ant		date			not null,
		p33_cod_tran		char(2),
		p33_num_tran		decimal(15,0),
		p33_cod_prov_nue	integer,
		p33_nom_prov_nue	varchar(100,50),
		p33_num_fac_nue		char(15),
		p33_num_aut_nue		char(10),
		p33_fec_cad_nue		date,
		p33_usuario		varchar(10,5)		not null,
		p33_fecing		datetime year to second	not null

	) in datadbs lock mode row;


revoke all on "fobos".cxpt033 from "public";


create unique index "fobos".i01_pk_cxpt033
	on "fobos".cxpt033
		(p33_compania, p33_localidad, p33_numero_oc, p33_secuencia)
	in idxdbs;

create index "fobos".i01_fk_cxpt033
	on "fobos".cxpt033
		(p33_compania, p33_localidad, p33_numero_oc)
	in idxdbs;

create index "fobos".i02_fk_cxpt033
	on "fobos".cxpt033
		(p33_compania, p33_localidad, p33_cod_tran, p33_num_tran)
	in idxdbs;

create index "fobos".i03_fk_cxpt033
	on "fobos".cxpt033
		(p33_cod_prov_ant)
	in idxdbs;

create index "fobos".i04_fk_cxpt033
	on "fobos".cxpt033
		(p33_cod_prov_nue)
	in idxdbs;

create index "fobos".i05_fk_cxpt033
	on "fobos".cxpt033
		(p33_usuario)
	in idxdbs;


alter table "fobos".cxpt033
	add constraint
		primary key (p33_compania, p33_localidad, p33_numero_oc,
				p33_secuencia)
			constraint "fobos".pk_cxpt033;

alter table "fobos".cxpt033
	add constraint
		(foreign key (p33_compania, p33_localidad, p33_numero_oc)
			references "fobos".ordt010
			constraint "fobos".fk_01_cxpt033);

alter table "fobos".cxpt033
	add constraint
		(foreign key (p33_compania, p33_localidad, p33_cod_tran,
				p33_num_tran)
			references "fobos".rept019
			constraint "fobos".fk_02_cxpt033);

alter table "fobos".cxpt033
	add constraint
		(foreign key (p33_cod_prov_ant)
			references "fobos".cxpt001
			constraint "fobos".fk_03_cxpt033);

alter table "fobos".cxpt033
	add constraint
		(foreign key (p33_cod_prov_nue)
			references "fobos".cxpt001
			constraint "fobos".fk_04_cxpt033);

alter table "fobos".cxpt033
	add constraint
		(foreign key (p33_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_cxpt033);


commit work;

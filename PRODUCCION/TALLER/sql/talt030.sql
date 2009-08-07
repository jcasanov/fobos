begin work;

create table "fobos".talt030(
	t30_compania		integer			not null,
	t30_localidad		smallint		not null,
	t30_num_gasto		integer 		not null,
	t30_num_ot		integer			not null,
	t30_estado		char(1)			not null
			check (t30_estado in ('A', 'E')),
	t30_origen		varchar(30,15)		not null,
	t30_destino		varchar(30,15)		not null,
	t30_fec_ini_viaje	date			not null,
	t30_fec_fin_viaje	date,
	t30_recargo		decimal(5,2)		not null,
	t30_desc_viaje		varchar(120,60)		not null,
	t30_moneda		char(2)			not null,
	t30_tot_gasto		decimal(12,2)		not null,
	t30_usuario		varchar(10,5)		not null,
	t30_fecing		datetime year to second not null
);

-- Indices
create unique index "fobos".i01_pk_talt030
	on talt030(t30_compania, t30_localidad, t30_num_gasto)
	in idxdbs;

create index "fobos".i01_fk_talt030 on talt030(t30_compania) in idxdbs;

create index "fobos".i02_fk_talt030
	on talt030(t30_compania, t30_localidad) in idxdbs;

create index "fobos".i03_fk_talt030
	on talt030(t30_compania, t30_localidad, t30_num_ot) in idxdbs;

create index "fobos".i04_fk_talt030 on talt030(t30_moneda) in idxdbs;

create index "fobos".i05_fk_talt030 on talt030(t30_usuario) in idxdbs;

-- Constraints
alter table talt030 add constraint
	primary key(t30_compania, t30_localidad, t30_num_gasto);

alter table talt030 add constraint(
	foreign key(t30_compania) references talt000(t00_compania)
);

alter table talt030 add constraint(
	foreign key(t30_compania, t30_localidad) 
	references gent002(g02_compania, g02_localidad)
);

alter table talt030 add constraint(
	foreign key(t30_compania, t30_localidad, t30_num_ot) 
	references talt023(t23_compania, t23_localidad, t23_orden)
);

alter table talt030 add constraint(
	foreign key(t30_moneda) references gent013(g13_moneda)
);

alter table talt030 add constraint(
	foreign key(t30_usuario) references gent005(g05_usuario)
);

commit work;

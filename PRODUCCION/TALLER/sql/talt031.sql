begin work;

create table "fobos".talt031(
	t31_compania		integer			not null,
	t31_localidad		smallint		not null,
	t31_num_gasto		integer 		not null,
	t31_secuencia		smallint		not null,
	t31_descripcion		varchar(40,20)		not null,
	t31_moneda		char(2)			not null,
	t31_valor     		decimal(11,2)		not null
);

-- Indices
create unique index "fobos".i01_pk_talt031
	on talt031(t31_compania, t31_localidad, t31_num_gasto, t31_secuencia) 
	in idxdbs;

create index "fobos".i01_fk_talt031
	on talt031(t31_compania, t31_localidad, t31_num_gasto) 
	in idxdbs;

create index "fobos".i02_fk_talt031 on talt031(t31_moneda) in idxdbs;

-- Constraints
alter table talt031 add constraint
	primary key(t31_compania, t31_localidad, t31_num_gasto, t31_secuencia);

alter table talt031 add constraint(
	foreign key(t31_compania, t31_localidad, t31_num_gasto) 
	references talt030(t30_compania, t30_localidad, t30_num_gasto)
);

alter table talt031 add constraint(
	foreign key(t31_moneda) references gent013(g13_moneda)
);

commit work;

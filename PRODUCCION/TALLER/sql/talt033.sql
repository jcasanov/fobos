begin work;

create table "fobos".talt033(
	t33_compania		integer			not null,
	t33_localidad		smallint		not null,
	t33_num_gasto		integer 		not null,
	t33_fecha      		date	 		not null,
	t33_hor_sal_viaje	datetime hour to minute	not null,
	t33_hor_lleg_dest1	datetime hour to minute	not null,
	t33_hor_sal_rep		datetime hour to minute	not null,
	t33_hor_lleg_dest2	datetime hour to minute	not null
);

-- Indices
create unique index "fobos".i01_pk_talt033
	on talt033(t33_compania, t33_localidad, t33_num_gasto, t33_fecha) 
	in idxdbs;

create index "fobos".i01_fk_talt033
	on talt033(t33_compania, t33_localidad, t33_num_gasto) 
	in idxdbs;

-- Constraints
alter table talt033 add constraint
	primary key(t33_compania, t33_localidad, t33_num_gasto, t33_fecha);

alter table talt033 add constraint(
	foreign key(t33_compania, t33_localidad, t33_num_gasto) 
	references talt030(t30_compania, t30_localidad, t30_num_gasto)
);

commit work;

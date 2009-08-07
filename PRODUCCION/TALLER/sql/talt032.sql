begin work;

create table "fobos".talt032(
	t32_compania		integer			not null,
	t32_localidad		smallint		not null,
	t32_num_gasto		integer 		not null,
	t32_mecanico 		smallint		not null,
	t32_principal  		char(1)    		not null
			check(t32_principal in ('S', 'N'))
);

-- Indices
create unique index "fobos".i01_pk_talt032
	on talt032(t32_compania, t32_localidad, t32_num_gasto, t32_mecanico) 
	in idxdbs;

create index "fobos".i01_fk_talt032
	on talt032(t32_compania, t32_localidad, t32_num_gasto) 
	in idxdbs;

create index "fobos".i02_fk_talt032 on talt032(t32_mecanico) in idxdbs;

-- Constraints
alter table talt032 add constraint
	primary key(t32_compania, t32_localidad, t32_num_gasto, t32_mecanico);

alter table talt032 add constraint(
	foreign key(t32_compania, t32_localidad, t32_num_gasto) 
	references talt030(t30_compania, t30_localidad, t30_num_gasto)
);

alter table talt032 add constraint(
	foreign key(t32_compania, t32_mecanico) 
	references talt003(t03_compania, t03_mecanico)
);

commit work;

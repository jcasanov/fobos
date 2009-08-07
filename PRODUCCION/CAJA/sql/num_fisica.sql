begin work;

drop table cxct100;
drop table cajt102;
drop table cajt101;
drop table cajt100;


-- COBRANZAS
-- Tabla para el mantenimiento de blocks de documentos en cxc
create table cxct100 (		
	z100_compania		integer		not null,
	z100_localidad		smallint	not null,
	z100_tipo_doc		char(2)		not null,
	z100_block_nro		smallint	not null,
	z100_fecha_ini		date		not null,
	z100_fecha_fin		date		not null,
	z100_num_inicial	integer		not null,
	z100_num_final		integer		not null,
	z100_num_actual		integer		not null,
	 check (z100_num_inicial > 0),
	 check (z100_num_inicial <= z100_num_final),
	 check (z100_num_actual  between z100_num_inicial and z100_num_final),
	 check (z100_fecha_ini < z100_fecha_fin) 
);

create unique index pk_cxct100 on cxct100 (z100_compania, z100_localidad,
					   z100_tipo_doc, z100_block_nro);
create   index i01_fk_cxct100 on cxct100 (z100_compania, z100_localidad);
create   index i02_fk_cxct100 on cxct100 (z100_tipo_doc);
alter table cxct100 add constraint (
	primary key (z100_compania, z100_localidad, 
 		     z100_tipo_doc, z100_block_nro) 
);
alter table cxct100 add constraint(
	foreign key (z100_compania, z100_localidad) references gent002
);
alter table cxct100 add constraint(
	foreign key (z100_tipo_doc) references cxct004
);

-- Tabla para el mantenimiento de numeros anulados    
create table cxct101 (		
	z101_compania		integer		not null,
	z101_localidad		smallint	not null,
	z101_tipo_doc		char(2)		not null,
	z101_block_nro		smallint	not null,	
	z101_num_anulado	integer		not null,
	 check (z101_num_anulado > 0) 
);

create unique index pk_cxct101 on cxct101 (z101_compania, z101_localidad,
					   z101_tipo_doc, z101_block_nro,
					   z101_num_anulado);
create   index i01_fk_cxct101 on cxct101 (z101_compania, z101_localidad,
					  z101_tipo_doc, z101_block_nro);
alter table cxct101 add constraint (
	primary key (z101_compania, z101_localidad, 
 		     z101_tipo_doc, z101_block_nro, z101_num_anulado) 
);
alter table cxct101 add constraint(
	foreign key (z101_compania, z101_localidad, z101_tipo_doc, z101_block_nro) references cxct100
);

-- Relacion de documento fisico con documento del sistema
create table cxct100 (
	z100_compania		integer		not null,
	z100_localidad		smallint	not null,
	z100_codcli		integer		not null,
	z100_tipo_doc		char(2)		not null,
	z100_num_doc		integer		not null,
	z100_modulo		char(2)		not null,
	z100_cod_tran		char(2)		        ,
	z100_num_tran		decimal(15,0)	not null,
	z100_block_nro		integer		        ,
	z100_num_fisico		integer 	
);

create unique index pk_cxct100 on cxct100 (z100_compania, z100_localidad,
					   z100_codcli,
					   z100_tipo_doc, z100_num_doc);
create index i01_fk_cxct100 on cxct100 (z100_modulo);
create index i02_fk_cxct100 on cxct100 (z100_compania, z100_localidad,
					   z100_tipo_doc, z100_block_nro);
alter table cxct100 add constraint (
	primary key (z100_compania, z100_localidad, z100_codcli, 
 		     z100_tipo_doc, z100_num_doc) 
);
alter table cxct100 add constraint(
	foreign key (z100_compania, z100_localidad, z100_codcli, 
                     z100_tipo_doc, z100_num_doc) references cxct021
);
alter table cxct100 add constraint(
	foreign key (z100_modulo) references gent050
);
alter table cxct100 add constraint(
	foreign key (z100_compania, z100_localidad, 
                     z100_tipo_doc, z100_block_nro) references cajt101
);

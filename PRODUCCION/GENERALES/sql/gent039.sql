begin work;

create table "fobos".gent039 
  (
    g39_compania		integer			not null,
    g39_localidad		smallint		not null,
    g39_tipo_doc		char(2)			not null,
    g39_secuencia		smallint		not null,
    g39_fec_entrega		date			not null,
    g39_num_sri_ini		integer			not null,
    g39_num_sri_fin		integer			not null,
    g39_num_dias_col		integer			not null,
    g39_usuario			varchar(10,5)		not null,
    g39_fecing			datetime year to second not null
  );

revoke all on "fobos".gent039 from "public";


-- Indices de la Tabla

create unique index "fobos".i01_pk_gent039 on "fobos".gent039 
    (g39_compania, g39_localidad, g39_tipo_doc, g39_secuencia, g39_fec_entrega);

create index "fobos".i01_fk_gent039 on "fobos".gent039 (g39_compania);
    
create index "fobos".i02_fk_gent039 on "fobos".gent039
	(g39_compania, g39_localidad);

create index "fobos".i03_fk_gent039 on "fobos".gent039
	(g39_compania, g39_localidad, g39_tipo_doc);

create index "fobos".i04_fk_gent039 on "fobos".gent039 (g39_usuario);

--
    

-- Constraints de la Tabla

alter table "fobos".gent039
	add constraint
		primary key (g39_compania, g39_localidad, g39_tipo_doc,
				g39_secuencia, g39_fec_entrega)
			constraint "fobos".pk_gent039;

alter table "fobos".gent039
	add constraint (foreign key (g39_compania) references "fobos".gent001);

alter table "fobos".gent039
	add constraint (foreign key (g39_compania, g39_localidad)
			references "fobos".gent002);

alter table "fobos".gent039
	add constraint (foreign key (g39_usuario) references "fobos".gent005);

--

commit work;

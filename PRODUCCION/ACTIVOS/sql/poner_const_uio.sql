begin work;

-- CONSTRAINT DE LA TABLA actt001

alter table "fobos".actt001
	add constraint (foreign key (a01_compania) references "fobos".actt000);

alter table "fobos".actt001
	add constraint (foreign key (a01_compania, a01_aux_activo)
			references "fobos".ctbt010);

alter table "fobos".actt001
	add constraint (foreign key (a01_compania, a01_aux_reexpr)
			references "fobos".ctbt010);

alter table "fobos".actt001
	add constraint (foreign key (a01_compania, a01_aux_dep_act)
			references "fobos".ctbt010);

alter table "fobos".actt001
	add constraint (foreign key (a01_compania, a01_aux_dep_reex)
			references "fobos".ctbt010);

alter table "fobos".actt001
	add constraint (foreign key (a01_usuario) references "fobos".gent005);

--------------------------------------------------------------------------------

-- CONSTRAINT DE LA TABLA actt002

alter table "fobos".actt002
	add constraint (foreign key (a02_compania, a02_grupo_act)
			references "fobos".actt001);

alter table "fobos".actt002
	add constraint (foreign key (a02_usuario) references "fobos".gent005);

--------------------------------------------------------------------------------

-- CONSTRAINT DE LA TABLA actt010

alter table "fobos".actt010
	add constraint (foreign key (a10_compania) references "fobos".actt000);

alter table "fobos".actt010
	add constraint (foreign key (a10_compania, a10_grupo_act)
			references "fobos".actt001);

alter table "fobos".actt010
	add constraint (foreign key (a10_compania, a10_tipo_act)
			references "fobos".actt002);

alter table "fobos".actt010
	add constraint (foreign key (a10_compania, a10_locali_ori)
			references "fobos".gent002);

alter table "fobos".actt010
	add constraint (foreign key (a10_compania, a10_localidad)
			references "fobos".gent002);

alter table "fobos".actt010
	add constraint (foreign key (a10_compania, a10_locali_ori,a10_numero_oc)
			references "fobos".ordt010);

alter table "fobos".actt010
	add constraint (foreign key (a10_compania, a10_cod_depto)
			references "fobos".gent034);

alter table "fobos".actt010
	add constraint (foreign key (a10_compania, a10_locali_ori, a10_codprov)
			references "fobos".cxpt002);

alter table "fobos".actt010
	add constraint (foreign key (a10_moneda) references "fobos".gent013);

alter table "fobos".actt010
	add constraint (foreign key (a10_compania, a10_responsable)
			references "fobos".actt003);

alter table "fobos".actt010
	add constraint (foreign key (a10_usuario) references "fobos".gent005);

--------------------------------------------------------------------------------

-- CONSTRAINT DE LA TABLA actt012

alter table "fobos".actt012
	add constraint (foreign key (a12_compania, a12_codigo_tran)
			references "fobos".actt005);

alter table "fobos".actt012
	add constraint (foreign key (a12_compania, a12_codigo_bien)
			references "fobos".actt010);

alter table "fobos".actt012
	add constraint (foreign key (a12_compania, a12_locali_ori)
			references "fobos".gent002);

alter table "fobos".actt012
	add constraint (foreign key (a12_compania, a12_locali_dest)
			references "fobos".gent002);

alter table "fobos".actt012
	add constraint (foreign key (a12_compania, a12_depto_ori)
			references "fobos".gent034);

alter table "fobos".actt012
	add constraint (foreign key (a12_compania, a12_depto_dest)
			references "fobos".gent034);

alter table "fobos".actt012
	add constraint (foreign key (a12_compania, a12_tipcomp_gen,
					a12_numcomp_gen)
			references "fobos".ctbt012);

alter table "fobos".actt012
	add constraint (foreign key (a12_usuario) references "fobos".gent005);

--------------------------------------------------------------------------------

commit work;

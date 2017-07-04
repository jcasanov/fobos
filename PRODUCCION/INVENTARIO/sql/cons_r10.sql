begin work;

create index "fobos".i11_fk_rept010
	on "fobos".rept010 (r10_compania, r10_linea, r10_sub_linea);

create index "fobos".i12_fk_rept010
	on "fobos".rept010 (r10_compania, r10_linea, r10_sub_linea,
				r10_cod_grupo);

create index "fobos".i13_fk_rept010
	on "fobos".rept010 (r10_compania, r10_linea, r10_sub_linea,
				r10_cod_grupo, r10_cod_clase);

create index "fobos".i14_fk_rept010
	on "fobos".rept010 (r10_compania, r10_marca);

alter table "fobos".rept010
	add constraint (foreign key (r10_compania, r10_linea, r10_sub_linea)
				references "fobos".rept070);

alter table "fobos".rept010
	add constraint (foreign key (r10_compania, r10_linea, r10_sub_linea,
					r10_cod_grupo)
				references "fobos".rept071);

alter table "fobos".rept010
	add constraint (foreign key (r10_compania, r10_linea, r10_sub_linea,
					r10_cod_grupo, r10_cod_clase)
				references "fobos".rept072);

alter table "fobos".rept010
	add constraint (foreign key (r10_compania, r10_marca)
				references "fobos".rept073);

commit work;

begin work;

	create index "fobos".i01_fk_ordt040
		on "fobos".ordt040
			(c40_compania, c40_tipo_comp, c40_num_comp)
		in idxdbs;

	alter table "fobos".ordt040
		add constraint
			(foreign key (c40_compania, c40_tipo_comp, c40_num_comp)
				references "fobos".ctbt012
				constraint "fobos".fk_01_ordt040);

	create index "fobos".i02_fk_ordt040
		on "fobos".ordt040
			(c40_compania, c40_localidad, c40_numero_oc,
				c40_num_recep)
		in idxdbs;

	alter table "fobos".ordt040
		add constraint
			(foreign key (c40_compania, c40_localidad,
					c40_numero_oc, c40_num_recep)
				references "fobos".ordt013
				constraint "fobos".fk_02_ordt040);

commit work;

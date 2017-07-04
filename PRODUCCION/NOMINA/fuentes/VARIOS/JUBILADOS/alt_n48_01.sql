begin work;

	alter table "fobos".rolt048
		add (n48_tipo_comp	char(2)		before n48_usuario);

	alter table "fobos".rolt048
		add (n48_num_comp	char(8)		before n48_usuario);

	create index "fobos".i06_fk_rolt048
		on "fobos".rolt048
			(n48_compania, n48_tipo_comp, n48_num_comp)
		in idxdbs;

	alter table "fobos".rolt048
		add constraint
			(foreign key (n48_compania, n48_tipo_comp, n48_num_comp)
				references "fobos".ctbt012
				constraint "fobos".fk_06_rolt048);

commit work;

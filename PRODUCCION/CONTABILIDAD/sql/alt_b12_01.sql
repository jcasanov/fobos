begin work;

	create index "fobos".i06_fk_ctbt012
		on "fobos".ctbt012
			(b12_compania, b12_tipo_comp, b12_num_comp, b12_estado)
		in idxdbs;

commit work;

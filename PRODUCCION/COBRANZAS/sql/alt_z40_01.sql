begin work;

	create index "fobos".i01_fk_cxct040
		on "fobos".cxct040
			(z40_compania, z40_localidad, z40_codcli, z40_tipo_doc,
			 z40_num_doc)
		in idxdbs;

	create index "fobos".i02_fk_cxct040
		on "fobos".cxct040
			(z40_compania, z40_tipo_comp, z40_num_comp)
		in idxdbs;

commit work;

begin work;

	create index "fobos".i01_fk_talt050
		on "fobos".talt050
			(t50_compania, t50_localidad, t50_orden)
		in idxdbs;

	create index "fobos".i02_fk_talt050
		on "fobos".talt050
			(t50_compania, t50_localidad, t50_factura)
		in idxdbs;

	create index "fobos".i03_fk_talt050
		on "fobos".talt050
			(t50_compania, t50_tipo_comp, t50_num_comp)
		in idxdbs;

	alter table "fobos".talt050
		add constraint
			(foreign key (t50_compania, t50_localidad, t50_orden)
				references "fobos".talt023
				constraint "fobos".fk_01_talt050);

	alter table "fobos".talt050
		add constraint
			(foreign key (t50_compania, t50_tipo_comp,
				t50_num_comp)
				references "fobos".ctbt012
				constraint "fobos".fk_03_talt050);

--rollback work;
commit work;

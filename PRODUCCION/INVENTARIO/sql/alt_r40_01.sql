begin work;

	create index "fobos".i01_fk_rept040
		on "fobos".rept040
			(r40_compania, r40_localidad, r40_cod_tran,
			 r40_num_tran)
		in idxdbs;

	create index "fobos".i02_fk_rept040
		on "fobos".rept040
			(r40_compania, r40_tipo_comp, r40_num_comp)
		in idxdbs;

	{--
	alter table "fobos".rept040
		add constraint
			(foreign key (r40_compania, r40_localidad,
				r40_cod_tran, r40_num_tran)
				references "fobos".rept019
				constraint "fobos".fk_01_rept040);
	--}

	alter table "fobos".rept040
		add constraint
			(foreign key (r40_compania, r40_tipo_comp,
				r40_num_comp)
				references "fobos".ctbt012
				constraint "fobos".fk_02_rept040);

--rollback work;
commit work;

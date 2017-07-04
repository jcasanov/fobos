begin work;

	create index "fobos".i13_fk_rept021
		on "fobos".rept021
			(r21_compania, r21_localidad, r21_cod_tran,
			 r21_num_tran)
		in idxdbs;

	alter table "fobos".rept021
		add constraint
			(foreign key (r21_compania, r21_localidad,
				r21_cod_tran, r21_num_tran)
				references "fobos".rept019
				constraint "fobos".fk_13_rept021);

commit work;

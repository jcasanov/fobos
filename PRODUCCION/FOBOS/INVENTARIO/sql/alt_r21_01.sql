begin work;

	alter table "fobos".rept021
		add constraint
			(foreign key (r21_compania, r21_localidad,
					r21_num_presup)
				references "fobos".talt020
				constraint "fobos".fk_10_rept021);

commit work;

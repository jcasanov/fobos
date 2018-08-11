begin work;

	alter table "fobos".cxpt021
		add (p21_cod_tran			char(2)				before p21_usuario);

	alter table "fobos".cxpt021
		add (p21_num_tran			decimal(15,0)		before p21_usuario);

	create index "fobos".i07_pk_cxpt021
		on "fobos".cxpt021
			(p21_compania, p21_localidad, p21_cod_tran, p21_num_tran)
		in idxdbs;

	alter table "fobos".cxpt021
		add constraint
			(foreign key (p21_compania, p21_localidad,
							p21_cod_tran, p21_num_tran)
				references "fobos".rept019
				constraint "fobos".fk_07_cxpt021);

--rollback work;
commit work;

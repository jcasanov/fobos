begin work;

	drop index "fobos".i01_fk_cxct026;

	alter table "fobos".cxct026
		drop constraint "fobos".pk_cxct026;

	-- TIENES QUE VER COMO SE LLAMA EN TU SERVIDOR EL check constraint del
	-- campo z26_estado
	alter table "fobos".cxct026 drop constraint "fobos".c205_1053;

	alter table "fobos".cxct026 drop z26_secuencia;

	alter table "fobos".cxct026
		add (z26_secuencia			smallint		before z26_estado);

	update "fobos".cxct026
		set z26_secuencia = 1
		where 1 = 1;

	alter table "fobos".cxct026
		modify (z26_secuencia		smallint		not null);

	create unique index "fobos".i01_fk_cxct026
		on "fobos".cxct026
			(z26_compania, z26_localidad, z26_codcli, z26_tipo_doc, z26_num_doc,
			 z26_dividendo, z26_secuencia)
		in idxdbs;

	alter table "fobos".cxct026
		add constraint
			primary key (z26_compania, z26_localidad, z26_codcli, z26_tipo_doc,
						 z26_num_doc, z26_dividendo, z26_secuencia)
			constraint "fobos".pk_cxct026;

	alter table "fobos".cxct026
		add constraint check (z26_estado in ('A', 'B', 'C'))
			constraint "fobos".ck_01_cxct026;

--rollback work;
commit work;

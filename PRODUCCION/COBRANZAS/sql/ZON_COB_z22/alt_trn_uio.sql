begin work;

	alter table "fobos".cxct022
		add constraint
			(foreign key (z22_compania, z22_localidad, z22_codcli)
			 references "fobos".cxct002
			 constraint "fobos".fk_01_cxct022);

	alter table "fobos".cxct022
		add constraint
			(foreign key (z22_compania, z22_localidad, z22_codcli,
					z22_tiptrn_elim, z22_numtrn_elim)
			 references "fobos".cxct022
			 constraint "fobos".fk_02_cxct022);

	alter table "fobos".cxct022
		add constraint
			(foreign key (z22_tipo_trn)
			 references "fobos".cxct004
			 constraint "fobos".fk_03_cxct022);

	alter table "fobos".cxct022
		add constraint
			(foreign key (z22_compania, z22_areaneg)
			 references "fobos".gent003
			 constraint "fobos".fk_04_cxct022);

	alter table "fobos".cxct022
		add constraint
			(foreign key (z22_moneda)
			 references "fobos".gent013
			 constraint "fobos".fk_05_cxct022);

	alter table "fobos".cxct022
		add constraint
			(foreign key (z22_compania, z22_cobrador)
			 references "fobos".cxct005
			 constraint "fobos".fk_06_cxct022);

	alter table "fobos".cxct022
		add constraint
			(foreign key (z22_usuario)
			 references "fobos".gent005
			 constraint "fobos".fk_07_cxct022);

	alter table "fobos".cxct023
		add constraint
			(foreign key (z23_compania, z23_localidad, z23_codcli,
					z23_tipo_doc, z23_num_doc, z23_div_doc)
			 references "fobos".cxct020
			 constraint "fobos".fk_01_cxct023);

	alter table "fobos".cxct023
		add constraint
			(foreign key (z23_compania, z23_localidad, z23_codcli,
					z23_tipo_trn, z23_num_trn)
			 references "fobos".cxct022
			 constraint "fobos".fk_02_cxct023);

	alter table "fobos".cxct023
		add constraint
			(foreign key (z23_compania, z23_areaneg)
			 references "fobos".gent003
			 constraint "fobos".fk_03_cxct023);

	alter table "fobos".cxct023
		add constraint
			(foreign key (z23_compania, z23_localidad, z23_codcli,
					z23_tipo_favor, z23_doc_favor)
			 references "fobos".cxct021
			 constraint "fobos".fk_04_cxct023);

	alter table "fobos".cxct024
		add constraint
			(foreign key (z24_compania, z24_linea)
			 references "fobos".gent020
			 constraint "fobos".fk_01_cxct024);

	alter table "fobos".cxct024
		add constraint
			(foreign key (z24_compania, z24_localidad, z24_codcli)
			 references "fobos".cxct002
			 constraint "fobos".fk_02_cxct024);

	alter table "fobos".cxct024
		add constraint
			(foreign key (z24_compania, z24_areaneg)
			 references "fobos".gent003
			 constraint "fobos".fk_03_cxct024);

	alter table "fobos".cxct024
		add constraint
			(foreign key (z24_moneda)
			 references "fobos".gent013
			 constraint "fobos".fk_04_cxct024);

	alter table "fobos".cxct024
		add constraint
			(foreign key (z24_compania, z24_cobrador)
			 references "fobos".cxct005
			 constraint "fobos".fk_05_cxct024);

	alter table "fobos".cxct024
		add constraint
			(foreign key (z24_usuario)
			 references "fobos".gent005
			 constraint "fobos".fk_06_cxct024);

	alter table "fobos".cxct025
		add constraint
			(foreign key (z25_compania, z25_localidad, z25_codcli,
					z25_tipo_doc, z25_num_doc,z25_dividendo)
			 references "fobos".cxct020
			 constraint "fobos".fk_01_cxct025);

	alter table "fobos".cxct025
		add constraint
			(foreign key (z25_compania, z25_localidad,
					z25_numero_sol)
			 references "fobos".cxct024
			 constraint "fobos".fk_02_cxct025);

commit work;

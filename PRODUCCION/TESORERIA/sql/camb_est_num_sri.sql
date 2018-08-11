begin work;

--------------------------------------------------------------------------------
--------------- AUMENTO DE 6 caracteres EN p20_num_doc TESORERIA ---------------
--------------------------------------------------------------------------------

	alter table "fobos".cxpt020
		modify (p20_num_doc	char(21)	not null);

	alter table "fobos".cxpt023
		modify (p23_num_doc	char(21)	not null);

	alter table "fobos".cxpt025
		modify (p25_num_doc	char(21)	not null);

	alter table "fobos".cxpt028
		modify (p28_num_doc	char(21)	not null);

	alter table "fobos".cxpt041
		modify (p41_num_doc	char(21)	not null);

	alter table "fobos".cxpt050
		modify (p50_num_doc	char(21)	not null);

	alter table "fobos".cxpt023
		add constraint
			(foreign key (p23_compania, p23_localidad, p23_codprov,
					p23_tipo_doc, p23_num_doc, p23_div_doc)
				references "fobos".cxpt020
				constraint "fobos".fk_02_cxpt023);

	alter table "fobos".cxpt025
		add constraint
			(foreign key (p25_compania, p25_localidad, p25_codprov,
					p25_tipo_doc, p25_num_doc,p25_dividendo)
				references "fobos".cxpt020
				constraint "fobos".fk_01_cxpt025);

	alter table "fobos".cxpt028
		add constraint
			(foreign key (p28_compania, p28_localidad, p28_codprov,
					p28_tipo_doc, p28_num_doc,p28_dividendo)
				references "fobos".cxpt020
				constraint "fobos".fk_01_cxpt028);

	create index "fobos".i01_fk_cxpt041
		on "fobos".cxpt041
			(p41_compania, p41_localidad, p41_codprov, p41_tipo_doc,
			 p41_num_doc, p41_dividendo)
		in idxdbs;

	{--
	alter table "fobos".cxpt041
		add constraint
			(foreign key (p41_compania, p41_localidad, p41_codprov,
					p41_tipo_doc, p41_num_doc,
					p41_dividendo)
				references "fobos".cxpt020
				constraint "fobos".fk_01_cxpt041);

	alter table "fobos".cxpt050
		add constraint
			(foreign key (p50_compania, p50_localidad, p50_codprov,
					p50_tipo_doc, p50_num_doc,p50_dividendo)
				references "fobos".cxpt020
				constraint "fobos".fk_07_cxpt050);
	--}

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
------------- AUMENTO DE 6 caracteres EN No. fact. y ret. COMPRAS --------------
--------------------------------------------------------------------------------

	alter table "fobos".ordt010
		modify (c10_factura	char(21));

	alter table "fobos".ordt013
		modify (c13_num_guia	char(21)	not null);

	alter table "fobos".ordt013
		modify (c13_factura	char(21));

	alter table "fobos".rept019
		modify (r19_oc_externa	varchar(21,15));

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
---------------- AUMENTO DE 6 caracteres EN No. SRI DEL SISTEMA ----------------
--------------------------------------------------------------------------------

	alter table "fobos".cxct020
		modify (z20_num_sri		char(21));

	alter table "fobos".cxct021
		modify (z21_num_sri		char(21));

	alter table "fobos".cajt011
		modify (j11_num_ch_aut		varchar(21,0));

	alter table "fobos".cajt014
		modify (j14_num_ret_sri		char(21)	not null);

	alter table "fobos".cajt014
		modify (j14_num_fact_sri	char(21)	not null);

	alter table "fobos".cxpt029
		modify (p29_num_sri		char(21)	not null);

	alter table "fobos".cxpt033
		modify (p33_num_fac_ant		char(21)	not null);

	alter table "fobos".cxpt033
		modify (p33_num_fac_nue		char(21));

	alter table "fobos".rept038
		modify (r38_num_sri		char(21)	not null);

	alter table "fobos".rept095
		modify (r95_num_sri		char(21)	not null);

	alter table "fobos".rept095
		add (r95_placa		char(10)	before r95_num_sri);

--------------------------------------------------------------------------------

--rollback work;
commit work;

begin work;


--------------------------------------------------------------------------------
	alter table "fobos".cxpt001
		add constraint
			(foreign key (p01_pais)
				references "fobos".gent030
				constraint "fobos".fk_01_cxpt001);

	alter table "fobos".cxpt001
		add constraint
			(foreign key (p01_ciudad)
				references "fobos".gent031
				constraint "fobos".fk_02_cxpt001);

	alter table "fobos".cxpt001
		add constraint
			(foreign key (p01_usuario)
				references "fobos".gent005
				constraint "fobos".fk_03_cxpt001);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt005
		add constraint
			(foreign key (p05_compania)
				references "fobos".cxpt000
				constraint "fobos".fk_01_cxpt005);

	alter table "fobos".cxpt005
		add constraint
			(foreign key (p05_codprov)
				references "fobos".cxpt001
				constraint "fobos".fk_02_cxpt005);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt020
		add constraint
			(foreign key (p20_compania, p20_localidad, p20_codprov)
				references "fobos".cxpt002
				constraint "fobos".fk_01_cxpt020);

	alter table "fobos".cxpt020
		add constraint
			(foreign key (p20_tipo_doc)
				references "fobos".cxpt004
				constraint "fobos".fk_02_cxpt020);

	alter table "fobos".cxpt020
		add constraint
			(foreign key (p20_moneda)
				references "fobos".gent013
				constraint "fobos".fk_03_cxpt020);

	alter table "fobos".cxpt020
		add constraint
			(foreign key (p20_compania, p20_localidad,
					p20_numero_oc)
				references "fobos".ordt010
				constraint "fobos".fk_04_cxpt020);

	alter table "fobos".cxpt020
		add constraint
			(foreign key (p20_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_cxpt020);

	alter table "fobos".cxpt020
		add constraint
			(foreign key (p20_compania, p20_cod_depto)
				references "fobos".gent034
				constraint "fobos".fk_06_cxpt020);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt021
		add constraint
			(foreign key (p21_compania, p21_localidad,
					p21_orden_pago)
				references "fobos".cxpt024
				constraint "fobos".fk_01_cxpt021);

	alter table "fobos".cxpt021
		add constraint
			(foreign key (p21_compania, p21_localidad, p21_codprov)
				references "fobos".cxpt002
				constraint "fobos".fk_02_cxpt021);

	alter table "fobos".cxpt021
		add constraint
			(foreign key (p21_tipo_doc)
				references "fobos".cxpt004
				constraint "fobos".fk_03_cxpt021);

	alter table "fobos".cxpt021
		add constraint
			(foreign key (p21_moneda)
				references "fobos".gent013
				constraint "fobos".fk_04_cxpt021);

	alter table "fobos".cxpt021
		add constraint
			(foreign key (p21_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_cxpt021);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt022
		add constraint
			(foreign key (p22_compania, p22_localidad,
					p22_orden_pago)
				references "fobos".cxpt024
				constraint "fobos".fk_01_cxpt022);

	alter table "fobos".cxpt022
		add constraint
			(foreign key (p22_compania, p22_localidad, p22_codprov)
				references "fobos".cxpt002
				constraint "fobos".fk_02_cxpt022);

	alter table "fobos".cxpt022
		add constraint
			(foreign key (p22_tipo_trn)
				references "fobos".cxpt004
				constraint "fobos".fk_03_cxpt022);

	alter table "fobos".cxpt022
		add constraint
			(foreign key (p22_moneda)
				references "fobos".gent013
				constraint "fobos".fk_04_cxpt022);

	alter table "fobos".cxpt022
		add constraint
			(foreign key (p22_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_cxpt022);

	alter table "fobos".cxpt022
		add constraint
			(foreign key (p22_compania, p22_localidad, p22_codprov,
					p22_tiptrn_elim, p22_numtrn_elim)
				references "fobos".cxpt022
				constraint "fobos".fk_06_cxpt022);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt023
		add constraint
			(foreign key (p23_compania, p23_localidad, p23_codprov,
					p23_tipo_trn, p23_num_trn)
				references "fobos".cxpt022
				constraint "fobos".fk_01_cxpt023);

	alter table "fobos".cxpt023
		add constraint
			(foreign key (p23_compania, p23_localidad, p23_codprov,
					p23_tipo_doc, p23_num_doc, p23_div_doc)
				references "fobos".cxpt020
				constraint "fobos".fk_02_cxpt023);

	alter table "fobos".cxpt023
		add constraint
			(foreign key (p23_compania, p23_localidad, p23_codprov,
					p23_tipo_favor, p23_doc_favor)
				references "fobos".cxpt021
				constraint "fobos".fk_03_cxpt023);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt024
		add constraint
			(foreign key (p24_compania, p24_localidad, p24_codprov)
				references "fobos".cxpt002
				constraint "fobos".fk_01_cxpt024);

	alter table "fobos".cxpt024
		add constraint
			(foreign key (p24_moneda)
				references "fobos".gent013
				constraint "fobos".fk_02_cxpt024);

	alter table "fobos".cxpt024
		add constraint
			(foreign key (p24_compania, p24_banco, p24_numero_cta)
				references "fobos".gent009
				constraint "fobos".fk_03_cxpt024);

	alter table "fobos".cxpt024
		add constraint
			(foreign key (p24_compania, p24_tip_contable,
					p24_num_contable)
				references "fobos".ctbt012
				constraint "fobos".fk_04_cxpt024);

	alter table "fobos".cxpt024
		add constraint
			(foreign key (p24_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_cxpt024);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt027
		add constraint
			(foreign key (p27_compania, p27_localidad, p27_codprov)
				references "fobos".cxpt002
				constraint "fobos".fk_01_cxpt027);

	alter table "fobos".cxpt027
		add constraint
			(foreign key (p27_moneda)
				references "fobos".gent013
				constraint "fobos".fk_02_cxpt027);

	alter table "fobos".cxpt027
		add constraint
			(foreign key (p27_compania, p27_tip_contable,
					p27_num_contable)
				references "fobos".ctbt012
				constraint "fobos".fk_03_cxpt027);

	alter table "fobos".cxpt027
		add constraint
			(foreign key (p27_compania, p27_tip_cont_eli,
					p27_num_cont_eli)
				references "fobos".ctbt012
				constraint "fobos".fk_04_cxpt027);

	alter table "fobos".cxpt027
		add constraint
			(foreign key (p27_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_cxpt027);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt050
		add constraint
			(foreign key (p50_compania, p50_localidad, p50_codprov)
				references "fobos".cxpt002
				constraint "fobos".fk_01_cxpt050);

	alter table "fobos".cxpt050
		add constraint
			(foreign key (p50_tipo_doc)
				references "fobos".cxpt004
				constraint "fobos".fk_02_cxpt050);

	alter table "fobos".cxpt050
		add constraint
			(foreign key (p50_moneda)
				references "fobos".gent013
				constraint "fobos".fk_03_cxpt050);

	alter table "fobos".cxpt050
		add constraint
			(foreign key (p50_compania, p50_localidad,
					p50_numero_oc)
				references "fobos".ordt010
				constraint "fobos".fk_04_cxpt050);

	alter table "fobos".cxpt050
		add constraint
			(foreign key (p50_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_cxpt050);

	alter table "fobos".cxpt050
		add constraint
			(foreign key (p50_compania, p50_cod_depto)
				references "fobos".gent034
				constraint "fobos".fk_06_cxpt050);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".cxpt051
		add constraint
			(foreign key (p51_compania, p51_localidad, p51_codprov)
				references "fobos".cxpt002
				constraint "fobos".fk_02_cxpt051);

	alter table "fobos".cxpt051
		add constraint
			(foreign key (p51_tipo_doc)
				references "fobos".cxpt004
				constraint "fobos".fk_03_cxpt051);

	alter table "fobos".cxpt051
		add constraint
			(foreign key (p51_moneda)
				references "fobos".gent013
				constraint "fobos".fk_04_cxpt051);

	alter table "fobos".cxpt051
		add constraint
			(foreign key (p51_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_cxpt051);
--------------------------------------------------------------------------------

--rollback work;
commit work;

update statistics;

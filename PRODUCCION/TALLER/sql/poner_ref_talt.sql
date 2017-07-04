begin work;


--------------------------------------------------------------------------------
	alter table "fobos".talt020
		add constraint
			(foreign key (t20_compania)
				references "fobos".talt000
				constraint "fobos".fk_01_talt020);

	alter table "fobos".talt020
		add constraint
			(foreign key (t20_compania, t20_localidad)
				references "fobos".gent002
				constraint "fobos".fk_02_talt020);

	alter table "fobos".talt020
		add constraint
			(foreign key (t20_moneda)
				references "fobos".gent013
				constraint "fobos".fk_03_talt020);

	alter table "fobos".talt020
		add constraint
			(foreign key (t20_usuario)
				references "fobos".gent005
				constraint "fobos".fk_04_talt020);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt021
		add constraint
			(foreign key (t21_compania, t21_localidad, t21_numpre)
				references "fobos".talt020
				constraint "fobos".fk_01_talt021);

	alter table "fobos".talt021
		add constraint
			(foreign key (t21_compania, t21_codtarea)
				references "fobos".talt007
				constraint "fobos".fk_02_talt021);

	alter table "fobos".talt021
		add constraint
			(foreign key (t21_usuario)
				references "fobos".gent005
				constraint "fobos".fk_03_talt021);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt022
		add constraint
			(foreign key (t22_compania, t22_localidad, t22_numpre)
				references "fobos".talt020
				constraint "fobos".fk_01_talt022);

	alter table "fobos".talt022
		add constraint
			(foreign key (t22_compania, t22_item)
				references "fobos".rept010
				constraint "fobos".fk_02_talt022);

	alter table "fobos".talt022
		add constraint
			(foreign key (t22_usuario)
				references "fobos".gent005
				constraint "fobos".fk_03_talt022);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_localidad,
					t23_cod_cliente)
				references "fobos".cxct002
				constraint "fobos".fk_01_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania)
				references "fobos".talt000
				constraint "fobos".fk_02_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_localidad)
				references "fobos".gent002
				constraint "fobos".fk_03_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_tipo_ot)
				references "fobos".talt005
				constraint "fobos".fk_04_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_tipo_ot, t23_subtipo_ot)
				references "fobos".talt006
				constraint "fobos".fk_05_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_localidad,
					t23_codcli_est)
				references "fobos".cxct002
				constraint "fobos".fk_06_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_seccion)
				references "fobos".talt002
				constraint "fobos".fk_07_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_cod_asesor)
				references "fobos".talt003
				constraint "fobos".fk_08_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_cod_mecani)
				references "fobos".talt003
				constraint "fobos".fk_09_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_moneda)
				references "fobos".gent013
				constraint "fobos".fk_10_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_modelo)
				references "fobos".talt004
				constraint "fobos".fk_11_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_usuario)
				references "fobos".gent005
				constraint "fobos".fk_12_talt023);

	alter table "fobos".talt023
		add constraint
			(foreign key (t23_compania, t23_localidad, t23_numpre)
				references "fobos".talt020
				constraint "fobos".fk_13_talt023);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt024
		add constraint
			(foreign key (t24_compania, t24_localidad,
					t24_orden)
				references "fobos".talt023
				constraint "fobos".fk_01_talt024);

	alter table "fobos".talt024
		add constraint
			(foreign key (t24_compania, t24_mecanico)
				references "fobos".talt003
				constraint "fobos".fk_02_talt024);

	alter table "fobos".talt024
		add constraint
			(foreign key (t24_compania, t24_seccion)
				references "fobos".talt002
				constraint "fobos".fk_03_talt024);

	alter table "fobos".talt024
		add constraint
			(foreign key (t24_compania, t24_localidad,
					t24_ord_compra)
				references "fobos".ordt010
				constraint "fobos".fk_04_talt024);

	alter table "fobos".talt024
		add constraint
			(foreign key (t24_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_talt024);

	alter table "fobos".talt024
		add constraint
			(foreign key (t24_compania, t24_codtarea)
				references "fobos".talt007
				constraint "fobos".fk_06_talt024);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt025
		add constraint
			(foreign key (t25_compania, t25_localidad,
					t25_orden)
				references "fobos".talt023
				constraint "fobos".fk_01_talt025);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt026
		add constraint
			(foreign key (t26_compania, t26_localidad,
					t26_orden)
				references "fobos".talt023
				constraint "fobos".fk_01_talt026);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt027
		add constraint
			(foreign key (t27_compania, t27_localidad,
					t27_orden)
				references "fobos".talt023
				constraint "fobos".fk_01_talt027);

	alter table "fobos".talt027
		add constraint
			(foreign key (t27_tipo)
				references "fobos".cxct004
				constraint "fobos".fk_02_talt027);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt028
		add constraint
			(foreign key (t28_compania)
				references "fobos".talt000
				constraint "fobos".fk_01_talt028);

	alter table "fobos".talt028
		add constraint
			(foreign key (t28_compania, t28_localidad)
				references "fobos".gent002
				constraint "fobos".fk_02_talt028);

	alter table "fobos".talt028
		add constraint
			(foreign key (t28_compania, t28_localidad, t28_ot_ant)
				references "fobos".talt023
				constraint "fobos".fk_03_talt028);

	alter table "fobos".talt028
		add constraint
			(foreign key (t28_compania, t28_localidad, t28_ot_nue)
				references "fobos".talt023
				constraint "fobos".fk_04_talt028);

	alter table "fobos".talt028
		add constraint
			(foreign key (t28_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_talt028);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt029
		add constraint
			(foreign key (t29_compania, t29_localidad, t29_num_dev)
				references "fobos".talt028
				constraint "fobos".fk_01_talt029);

	alter table "fobos".talt029
		add constraint
			(foreign key (t29_compania, t29_localidad, t29_oc_ant)
				references "fobos".ordt010
				constraint "fobos".fk_02_talt029);

	alter table "fobos".talt029
		add constraint
			(foreign key (t29_compania, t29_localidad, t29_oc_nue)
				references "fobos".ordt010
				constraint "fobos".fk_03_talt029);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt030
		add constraint
			(foreign key (t30_compania)
				references "fobos".talt000
				constraint "fobos".fk_01_talt030);

	alter table "fobos".talt030
		add constraint
			(foreign key (t30_compania, t30_localidad)
				references "fobos".gent002
				constraint "fobos".fk_02_talt030);

	alter table "fobos".talt030
		add constraint
			(foreign key (t30_compania, t30_localidad, t30_num_ot)
				references "fobos".talt023
				constraint "fobos".fk_03_talt030);

	alter table "fobos".talt030
		add constraint
			(foreign key (t30_moneda)
				references "fobos".gent013
				constraint "fobos".fk_04_talt030);

	alter table "fobos".talt030
		add constraint
			(foreign key (t30_usuario)
				references "fobos".gent005
				constraint "fobos".fk_05_talt030);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt031
		add constraint
			(foreign key (t31_compania, t31_localidad,
					t31_num_gasto)
				references "fobos".talt030
				constraint "fobos".fk_01_talt031);

	alter table "fobos".talt031
		add constraint
			(foreign key (t31_moneda)
				references "fobos".gent013
				constraint "fobos".fk_02_talt031);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt032
		add constraint
			(foreign key (t32_compania, t32_localidad,
					t32_num_gasto)
				references "fobos".talt030
				constraint "fobos".fk_01_talt032);

	alter table "fobos".talt032
		add constraint
			(foreign key (t32_compania, t32_mecanico)
				references "fobos".talt003
				constraint "fobos".fk_02_talt032);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt033
		add constraint
			(foreign key (t33_compania, t33_localidad,
					t33_num_gasto)
				references "fobos".talt030
				constraint "fobos".fk_01_talt033);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt040
		add constraint
			(foreign key (t40_compania)
				references "fobos".talt000
				constraint "fobos".fk_01_talt040);

	alter table "fobos".talt040
		add constraint
			(foreign key (t40_compania, t40_localidad)
				references "fobos".gent002
				constraint "fobos".fk_02_talt040);

	alter table "fobos".talt040
		add constraint
			(foreign key (t40_compania, t40_tipo_orden)
				references "fobos".talt005
				constraint "fobos".fk_03_talt040);

	alter table "fobos".talt040
		add constraint
			(foreign key (t40_moneda)
				references "fobos".gent013
				constraint "fobos".fk_04_talt040);

	alter table "fobos".talt040
		add constraint
			(foreign key (t40_compania, t40_modelo)
				references "fobos".talt004
				constraint "fobos".fk_05_talt040);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
	alter table "fobos".talt041
		add constraint
			(foreign key (t41_compania)
				references "fobos".talt000
				constraint "fobos".fk_01_talt041);

	alter table "fobos".talt041
		add constraint
			(foreign key (t41_compania, t41_localidad)
				references "fobos".gent002
				constraint "fobos".fk_02_talt041);

	alter table "fobos".talt041
		add constraint
			(foreign key (t41_compania, t41_mecanico)
				references "fobos".talt003
				constraint "fobos".fk_03_talt041);

	alter table "fobos".talt041
		add constraint
			(foreign key (t41_moneda)
				references "fobos".gent013
				constraint "fobos".fk_04_talt041);

	alter table "fobos".talt041
		add constraint
			(foreign key (t41_compania, t41_modelo)
				references "fobos".talt004
				constraint "fobos".fk_05_talt041);
--------------------------------------------------------------------------------

--rollback work;
commit work;

update statistics;

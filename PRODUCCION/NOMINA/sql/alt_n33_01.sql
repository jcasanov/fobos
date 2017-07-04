begin work;

--------------------------------------------------------------------------------
--revoke all on "fobos".rolt033 from "public";
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
alter table "fobos".rolt033
	add constraint
		(foreign key (n33_compania, n33_cod_liqrol, n33_fecha_ini,
				n33_fecha_fin, n33_cod_trab)
			references "fobos".rolt032
			constraint "fobos".fk_01_rolt033);

alter table "fobos".rolt033
	add constraint
		(foreign key (n33_compania, n33_cod_rubro)
			references "fobos".rolt009
			constraint "fobos".fk_02_rolt033);

alter table "fobos".rolt033
	add constraint
		(foreign key (n33_compania, n33_num_prest)
			references "fobos".rolt045
			constraint "fobos".fk_03_rolt033);
--------------------------------------------------------------------------------

commit work;

update statistics;

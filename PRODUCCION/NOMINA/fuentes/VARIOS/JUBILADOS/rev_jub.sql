select n48_compania cia, n48_ano_proceso anio, n48_mes_proceso mes,
	n48_cod_trab cod_trab, n48_estado est, n48_moneda mone,
	n48_val_jub_pat valor, n48_paridad pari, n48_tipo_pago tip,
	n48_bco_empresa banco, n48_cta_empresa cta, n48_cta_trabaj cta_t,
	n48_tipo_comp tp, n48_num_comp num, n48_usuario usuario,
	n48_fecing fecing
	from rolt048
	into temp t1;

begin work;

--------------------------------------------------------------------------------
	delete from rolt048
		where 1 = 1;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	drop index "fobos".i01_pk_rolt048;

	alter table "fobos".rolt048
		drop constraint "fobos".pk_rolt048;

	alter table "fobos".rolt048
		drop n48_ano_proceso;

	alter table "fobos".rolt048
		drop n48_mes_proceso;

	alter table "fobos".rolt048
		drop n48_paridad;

	alter table "fobos".rolt048
		drop n48_num_dias;

	alter table "fobos".rolt048
		drop n48_tot_gan;

	alter table "fobos".rolt048
		drop n48_proceso;

	alter table "fobos".rolt048
		drop n48_cod_liqrol;

	alter table "fobos".rolt048
		drop n48_fecha_ini;

	alter table "fobos".rolt048
		drop n48_fecha_fin;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	alter table "fobos".rolt048
		add (n48_ano_proceso	smallint	before n48_cod_trab);

	alter table "fobos".rolt048
		add (n48_mes_proceso	smallint	before n48_cod_trab);

	alter table "fobos".rolt048
		add (n48_paridad	decimal(16,9)	before n48_tipo_pago);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	alter table "fobos".rolt048
		modify (n48_ano_proceso	smallint	not null);

	alter table "fobos".rolt048
		modify (n48_mes_proceso	smallint	not null);

	alter table "fobos".rolt048
		modify (n48_paridad	decimal(16,9)	not null);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	create unique index "fobos".i01_pk_rolt048
		on "fobos".rolt048
			(n48_compania, n48_ano_proceso, n48_mes_proceso,
				n48_cod_trab)
		in idxdbs;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	alter table "fobos".rolt048
		add constraint
			primary key
				(n48_compania, n48_ano_proceso, n48_mes_proceso,
					n48_cod_trab)
				constraint "fobos".pk_rolt048;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	insert into rolt048
		select * from t1;
--------------------------------------------------------------------------------

--rollback work;
commit work;

drop table t1;

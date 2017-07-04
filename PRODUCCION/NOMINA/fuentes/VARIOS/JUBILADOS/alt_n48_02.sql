select n48_compania cia, 'JU' proc, 'ME' lq,
	date(mdy(n48_mes_proceso, 01, n48_ano_proceso)) fec_ini,
	date(mdy(n48_mes_proceso, 01, n48_ano_proceso)
		+ 1 units month - 1 units day) fec_fin,
	n48_cod_trab cod_trab, n48_estado est, n48_ano_proceso anio,
	n48_mes_proceso mes, n48_moneda mone, n48_paridad pari,
	case when (extend(n30_fec_jub, year to month) =
		extend(mdy(n48_mes_proceso, 01, n48_ano_proceso),year to month))
		and (day(n30_fec_jub) <> 1)
			then (date(mdy(n48_mes_proceso, 01, n48_ano_proceso)
					+ 1 units month - 1 units day) -
				n30_fec_jub) + 1
			else 30
	end dias,
	n48_val_jub_pat tot_gan, n48_val_jub_pat valor, n48_tipo_pago tip,
	n48_bco_empresa banco, n48_cta_empresa cta, n48_cta_trabaj cta_t,
	n48_tipo_comp tp, n48_num_comp num, n48_usuario usuario,
	n48_fecing fecing
	from rolt048, rolt030
	where n30_compania = n48_compania
	  and n30_cod_trab = n48_cod_trab
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
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	alter table "fobos".rolt048
		add (n48_proceso	char(2)		before n48_cod_trab);

	alter table "fobos".rolt048
		add (n48_cod_liqrol	char(2)		before n48_cod_trab);

	alter table "fobos".rolt048
		add (n48_fecha_ini	date		before n48_cod_trab);

	alter table "fobos".rolt048
		add (n48_fecha_fin	date		before n48_cod_trab);

	alter table "fobos".rolt048
		add (n48_ano_proceso	smallint	before n48_moneda);

	alter table "fobos".rolt048
		add (n48_mes_proceso	smallint	before n48_moneda);

	alter table "fobos".rolt048
		add (n48_paridad	decimal(16,9)	before n48_val_jub_pat);

	alter table "fobos".rolt048
		add (n48_num_dias	smallint	before n48_val_jub_pat);

	alter table "fobos".rolt048
		add (n48_tot_gan	decimal(12,2)	before n48_val_jub_pat);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	alter table "fobos".rolt048
		modify (n48_proceso	char(2)		not null);

	alter table "fobos".rolt048
		modify (n48_cod_liqrol	char(2)		not null);

	alter table "fobos".rolt048
		modify (n48_fecha_ini	date		not null);

	alter table "fobos".rolt048
		modify (n48_fecha_fin	date		not null);

	alter table "fobos".rolt048
		modify (n48_ano_proceso	smallint	not null);

	alter table "fobos".rolt048
		modify (n48_mes_proceso	smallint	not null);

	alter table "fobos".rolt048
		modify (n48_paridad	decimal(16,9)	not null);

	alter table "fobos".rolt048
		modify (n48_num_dias	smallint	not null);

	alter table "fobos".rolt048
		modify (n48_tot_gan	decimal(12,2)	not null);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	create unique index "fobos".i01_pk_rolt048
		on "fobos".rolt048
			(n48_compania, n48_proceso, n48_cod_liqrol,
				n48_fecha_ini, n48_fecha_fin, n48_cod_trab)
		in idxdbs;

	create index "fobos".i07_fk_rolt048
		on "fobos".rolt048
			(n48_proceso)
		in idxdbs;

	create index "fobos".i08_fk_rolt048
		on "fobos".rolt048
			(n48_cod_liqrol)
		in idxdbs;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	alter table "fobos".rolt048
		add constraint
			primary key
				(n48_compania, n48_proceso, n48_cod_liqrol,
					n48_fecha_ini, n48_fecha_fin,
					n48_cod_trab)
				constraint "fobos".pk_rolt048;

	alter table "fobos".rolt048
		add constraint
			(foreign key (n48_proceso)
				references "fobos".rolt003
				constraint "fobos".fk_07_rolt048);

	alter table "fobos".rolt048
		add constraint
			(foreign key (n48_cod_liqrol)
				references "fobos".rolt003
				constraint "fobos".fk_08_rolt048);
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
	insert into rolt048
		select * from t1;
--------------------------------------------------------------------------------

--rollback work;
commit work;

drop table t1;

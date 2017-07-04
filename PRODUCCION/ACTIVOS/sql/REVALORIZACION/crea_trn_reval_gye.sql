select a10_codigo_bien codigo, a10_fecha_comp fecha, a10_val_dep_mb val_dep,
	a10_anos_util anio, a10_porc_deprec porc, a10_valor_mb valor,
	a10_tot_dep_mb depr_acum, a10_tot_dep_mb val_lib, a10_estado estado
	from actt010
	where a10_compania = 999
	into temp t1;

load from "act_reval_gm.unl" insert into t1;

delete from t1 where estado = 'D';

delete from t1 where codigo in (17, 128);

create temp table tmp_a12
	(
	 	 a12_compania         integer,
		 a12_codigo_tran      char(2),
		 a12_numero_tran      serial,
		 a12_codigo_bien      integer,
		 a12_referencia       varchar(100,40),
		 a12_locali_ori       smallint,
		 a12_depto_ori        smallint,
		 a12_locali_dest      smallint,
		 a12_depto_dest       smallint,
		 a12_porc_deprec      decimal(4,2),
		 a12_porc_reval       decimal(4,2),
		 a12_valor_mb         decimal(12,2),
		 a12_valor_ma         decimal(12,2),
		 a12_tipcomp_gen      char(2),
		 a12_numcomp_gen      char(8),
		 a12_usuario          varchar(10,5),
		 a12_fecing           datetime year to second

	) in datadbs lock mode row;

select a10_grupo_act grupo, codigo, fecha, val_dep, anio, porc, valor,
	depr_acum, val_lib, estado
	from t1, actt010
	where a10_codigo_bien = codigo
	into temp tmp_rev;

drop table t1;

select a10_codigo_bien cod_bien, a10_estado est, a10_anos_util ano,
	a10_porc_deprec porc_d, a10_valor valor1, a10_valor_mb valor2,
	a10_tot_dep_mb dep_acu, a10_val_dep_mb val_dep2
	from actt010
	where a10_compania = 999
	into temp t1;

load from "act_nue_gye.unl" insert into t1;

delete from tmp_rev
	where codigo not in
		(select cod_bien from t1)
	  and grupo  <> 3;

drop table t1;

insert into tmp_a12
	(a12_compania, a12_codigo_tran, a12_numero_tran, a12_codigo_bien,
	 a12_referencia, a12_locali_ori, a12_depto_ori, a12_porc_deprec,
	 a12_valor_mb, a12_valor_ma, a12_usuario, a12_fecing)
	select a10_compania, "AD", 0, codigo,
		"BAJA DEPRECIACION POR REVALORIZACION NIIF",
		a10_locali_ori, a10_cod_depto, a10_porc_deprec,
		nvl((select sum(a12_valor_mb * (-1))
			from actt012
			where a12_compania     = a10_compania
			  and a12_codigo_tran  = 'DP'
			  and a12_codigo_bien  = a10_codigo_bien
			  and a12_valor_mb     < 0
			  and year(a10_fecing) < 2011), 0.00),
		0.00, "FOBOS", "2011-01-03 00:00:00"
		from tmp_rev, actt010
		where a10_compania     = 1
		  and a10_codigo_bien  = codigo
		  and a10_grupo_act   <> 1;

insert into tmp_a12
	(a12_compania, a12_codigo_tran, a12_numero_tran, a12_codigo_bien,
	 a12_referencia, a12_locali_ori, a12_depto_ori, a12_porc_deprec,
	 a12_valor_mb, a12_valor_ma, a12_usuario, a12_fecing)
	select a10_compania, "AA", 0, codigo,
		"BAJA DEL ACTIVO POR REVALORIZACION NIIF",
		a10_locali_ori, a10_cod_depto, a10_porc_deprec,
		nvl((select sum(a12_valor_mb * (-1))
			from actt012
			where a12_compania     = a10_compania
			  and a12_codigo_bien  = a10_codigo_bien
			  and a12_valor_mb     > 0
			  and year(a10_fecing) < 2011), 0.00),
		0.00, "FOBOS", "2011-01-03 00:00:00"
		from tmp_rev, actt010
		where a10_compania    = 1
		  and a10_codigo_bien = codigo;

insert into tmp_a12
	(a12_compania, a12_codigo_tran, a12_numero_tran, a12_codigo_bien,
	 a12_referencia, a12_locali_ori, a12_depto_ori, a12_porc_deprec,
	 a12_valor_mb, a12_valor_ma, a12_usuario, a12_fecing)
	select a10_compania, "RV", 0, codigo,
		"ACTIVO REVALORIZADO Y NUEVAMENTE EN USO POR NIIF",
		a10_locali_ori, a10_cod_depto, porc, valor, 0.00,
		"FOBOS", "2011-01-03 00:00:00"
		from tmp_rev, actt010
		where estado          = 'S'
		  and a10_compania    = 1
		  and a10_codigo_bien = codigo;

begin work;

	update actt005
		set a05_numero = 0
		where a05_codigo_tran in ('RV', 'AD', 'AA');

	delete from actt012
		where a12_codigo_tran in ('RV', 'AD', 'AA');

	insert into actt012
		select * from tmp_a12;

	update actt005
		set a05_numero =
			(select max(a12_numero_tran)
				from tmp_a12
				where a12_codigo_tran = a05_codigo_tran)
		where a05_codigo_tran in ('RV', 'AD', 'AA');

	update actt010
		set a10_estado     = "E",
		    a10_fecha_baja = mdy(01, 03, 2011)
		where a10_compania  = 1
		  and a10_grupo_act = 3;

	update actt010
		set a10_estado      = (select estado
					from tmp_rev
					where codigo = a10_codigo_bien),
		    a10_fecha_comp  = (select fecha
					from tmp_rev
					where codigo = a10_codigo_bien),
		    a10_anos_util   = (select anio
					from tmp_rev
					where codigo = a10_codigo_bien),
		    a10_porc_deprec = (select porc
					from tmp_rev
					where codigo = a10_codigo_bien),
		    a10_valor_mb    = (select valor
					from tmp_rev
					where codigo = a10_codigo_bien),
		    a10_tot_dep_mb  = (select depr_acum
					from tmp_rev
					where codigo = a10_codigo_bien),
		    a10_val_dep_mb  = (select val_dep
					from tmp_rev
					where codigo = a10_codigo_bien)
		where a10_compania     = 1
		  and a10_codigo_bien in
			(select codigo
				from tmp_rev
				where grupo  <> 3
				  and estado  = 'S');

	update actt010
		set a10_estado     = "E",
		    a10_fecha_baja = mdy(01, 03, 2011)
		where a10_compania     = 1
		  and a10_codigo_bien in
			(select codigo
				from tmp_rev
				where grupo  <> 3
				  and estado  = 'E');

	update actt010
		set a10_fecha_comp = mdy(01, 03, 2011)
		where a10_compania     = 1
		  and a10_codigo_bien in (1, 4, 8, 5, 159);

--rollback work;
commit work;

drop table tmp_a12;
drop table tmp_rev;

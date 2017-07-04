select a10_codigo_bien codigo, a10_estado estado, a10_anos_util anio,
	a10_porc_deprec porc, a10_valor valor1, a10_valor_mb valor2,
	a10_tot_dep_mb dep_acu, a10_val_dep_mb val_dep
	from actt010
	where a10_compania = 999
	into temp t1;

load from "act_nue_gye.unl"
	insert into t1;

begin work;

	update actt010
		set a10_porc_deprec = 0.00,
		    a10_valor       = 0.00,
		    a10_valor_mb    = 0.00,
		    a10_tot_dep_mb  = 0.00,
		    a10_val_dep_mb  = 0.00,
		    a10_estado      = "D"
		where a10_compania  = 1
		  and a10_grupo_act = 3;

	update actt010
		set a10_estado      = (select estado
					from t1
					where codigo = a10_codigo_bien),
		    a10_anos_util   = (select anio
					from t1
					where codigo = a10_codigo_bien),
		    a10_porc_deprec = (select porc
					from t1
					where codigo = a10_codigo_bien),
		    a10_valor       = (select valor1
					from t1
					where codigo = a10_codigo_bien),
		    a10_valor_mb    = (select valor1
					from t1
					where codigo = a10_codigo_bien),
		    a10_tot_dep_mb  = (select dep_acu
					from t1
					where codigo = a10_codigo_bien),
		    a10_val_dep_mb  = (select val_dep
					from t1
					where codigo = a10_codigo_bien)
		where a10_compania    = 1
		  and a10_codigo_bien in (select codigo from t1);

	update actt012
		set a12_porc_deprec = (select porc
					from t1
					where codigo = a12_codigo_bien),
		    a12_valor_mb    = (select valor1
					from t1
					where codigo = a12_codigo_bien)
		where a12_compania    = 1
		  and a12_codigo_tran = 'IN'
		  and a12_codigo_bien in (select codigo from t1);

--rollback work;
commit work;

drop table t1;

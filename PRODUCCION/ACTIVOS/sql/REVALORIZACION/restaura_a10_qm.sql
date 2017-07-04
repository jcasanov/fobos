select a10_codigo_bien codigo, a10_fecha_comp fecha, a10_val_dep_mb val_dep,
	a10_anos_util anio, a10_porc_deprec porc, a10_valor_mb valor,
	a10_tot_dep_mb depr_acum, a10_tot_dep_mb val_lib, a10_estado estado,
	a10_fecha_baja fec_baj
	from acero_qm@idsuio01:actt010
	where a10_compania = 1
	into temp tmp_rev;

begin work;

	update actt010
		set a10_estado      = (select estado
					from tmp_rev
					where codigo = a10_codigo_bien),
		    a10_fecha_comp  = (select fecha
					from tmp_rev
					where codigo = a10_codigo_bien),
		    a10_fecha_baja  = (select fec_baj
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
		  and a10_codigo_bien in (select codigo	from tmp_rev);

	update actt000
		set a00_anopro = 2011,
		    a00_mespro = 1
		where 1 = 1;

	update actt005
		set a05_numero = 0
		where a05_codigo_tran in ('RV', 'AD', 'AA');

	delete from actt012
		where a12_codigo_tran in ('RV', 'AD', 'AA');

commit work;

drop table tmp_rev;

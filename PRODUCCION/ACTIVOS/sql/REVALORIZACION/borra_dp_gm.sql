select a12_compania cia, a12_codigo_tran cod_tran, a12_numero_tran num_tran,
	a12_codigo_bien codigo, a12_valor_mb val_dep
	from actt012
	where a12_compania     = 1
	  and a12_codigo_tran  = 'DP'
	  and year(a12_fecing) > 2010
	into temp t1;

begin work;

	update actt010
		set a10_tot_dep_mb = a10_tot_dep_mb +
				(select sum(val_dep)
					from t1
					where codigo = a10_codigo_bien)
		where a10_compania     = 1
		  and a10_codigo_bien in (select unique codigo from t1);

	update actt010
		set a10_estado = 'S'
		where a10_compania     = 1
		  and a10_codigo_bien in (select unique codigo from t1)
		  and a10_estado      <> 'S'
		  and a10_valor_mb     > a10_tot_dep_mb;

	delete from actt012
		where a12_compania     = 1
		  and a12_codigo_tran  = 'DP'
		  and year(a12_fecing) > 2010;

	delete from actt014
		where a14_anio > 2010;

	delete from actt013
		where a13_ano > 2010;

	update actt005
		set a05_numero =
			(select max(a12_numero_tran)
				from actt012
				where a12_compania    = a05_compania
				  and a12_codigo_tran = a05_codigo_tran)
		where a05_codigo_tran = 'DP';

	update actt000
		set a00_anopro = 2011,
		    a00_mespro = 1
		where 1 = 1;

--rollback work;
commit work;

drop table t1;

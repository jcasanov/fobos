select a12_compania cia, a12_codigo_tran tp, a12_numero_tran num,
	a12_codigo_bien activo, a12_valor_mb valor
	from actt012
	where a12_compania      = 1
	  and a12_codigo_tran   = 'DP'
	  and year(a12_fecing) >= 2011
	into temp tmp_a12;

--select * from actt010 where a10_codigo_bien = 396;

--select sum(valor) from tmp_a12 where activo = 396;

begin work;

	update actt010
		set a10_tot_dep_mb = a10_tot_dep_mb +
				(select sum(valor)
					from tmp_a12
					where cia    = a10_compania
					  and activo = a10_codigo_bien),
		    a10_estado     = 'S'
		where a10_compania    = 1
		  and a10_codigo_bien in (select unique activo from tmp_a12);

	delete from actt012
		where exists
			(select 1 from tmp_a12
				where cia    = a12_compania
				  and tp     = a12_codigo_tran
				  and num    = a12_numero_tran
				  and activo = a12_codigo_bien);

	delete from actt013
		where a13_compania     = 1
		  and a13_codigo_bien in (select unique activo from tmp_a12)
		  and a13_ano         >= 2011;

	delete from actt014
		where a14_compania     = 1
		  and a14_codigo_bien in (select unique activo from tmp_a12)
		  and a14_anio        >= 2011;

--select * from actt010 where a10_codigo_bien = 396;

--rollback work;
commit work;

drop table tmp_a12;

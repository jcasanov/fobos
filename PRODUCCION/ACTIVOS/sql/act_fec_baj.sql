select a12_compania cia, a12_codigo_tran cod_tr, a12_numero_tran num_tr,
	a12_codigo_bien activo, a12_fecing fecha
	from actt012
	where a12_compania = 999
	into temp t1;

select a12_compania cia, a12_codigo_tran cod_tr, a12_numero_tran num_tr,
	a12_codigo_bien activo,
	extend(b12_fec_proceso, year to day) || " " ||
	extend(a12_fecing, hour to second) fecha
	from actt012, ctbt012
	where a12_compania    in (1, 2)
	  and a12_codigo_tran  = 'BA'
	  and b12_compania     = a12_compania
	  and b12_tipo_comp    = a12_tipcomp_gen
	  and b12_num_comp     = a12_numcomp_gen
	into temp t2;

--select cod_tr, num_tr, activo, fecha from t2 order by 2;

insert into t1
	select cia, cod_tr, num_tr, activo, fecha
		from t2;

drop table t2;

begin work;

	update actt012
		set a12_fecing = (select fecha
					from t1
					where cia    = a12_compania
					  and cod_tr = a12_codigo_tran
					  and num_tr = a12_numero_tran
					  and activo = a12_codigo_bien)
	where a12_compania    in (1, 2)
	  and a12_codigo_tran  = 'BA'
	  and exists (select 1 from t1
			where cia    = a12_compania
			  and cod_tr = a12_codigo_tran
			  and num_tr = a12_numero_tran
			  and activo = a12_codigo_bien);

commit work;

drop table t1;

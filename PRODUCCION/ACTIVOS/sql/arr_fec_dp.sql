select a.a12_compania cia, a.a12_codigo_tran tp, a.a12_numero_tran num,
	a.a12_codigo_bien activo,
	(select b.a12_fecing + 1 units hour
		from actt012 b
		where b.a12_compania    = a.a12_compania
		  and b.a12_codigo_tran = 'IN'
		  and b.a12_codigo_bien = a.a12_codigo_bien) fecha
	from actt012 a
	where a.a12_compania    in (1, 2)
	  and a.a12_codigo_tran = 'DP'
	  and a.a12_valor_mb    = 0
	into temp t1;
--select * from t1 where fecha is null;
begin work;
	update actt012
		set a12_fecing = (select fecha
					from t1
					where cia    = a12_compania
					  and tp     = a12_codigo_tran
					  and num    = a12_numero_tran
					  and activo = a12_codigo_bien)
		where a12_compania    in (1, 2)
		  and a12_codigo_tran = 'DP'
		  and a12_codigo_bien in (select activo
						from t1
						where cia    = a12_compania
						  and tp     = a12_codigo_tran
						  and num    = a12_numero_tran)
		  and a12_valor_mb    = 0;
commit work;
drop table t1;

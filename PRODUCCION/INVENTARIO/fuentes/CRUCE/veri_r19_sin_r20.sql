select r19_cod_tran tp, r19_num_tran num, r19_tipo_dev tt, r19_num_dev num_d,
	date(r19_fecing) fecha
	from rept019
	where not exists
		(select 1 from rept020
			where r20_compania  = r19_compania
			  and r20_localidad = r19_localidad
			  and r20_cod_tran  = r19_cod_tran
			  and r20_num_tran  = r19_num_tran)
	order by 1, 2, 5;

select r19_fecing, r38_num_tran, r38_num_sri
	from rept019, rept038
	where r19_compania  = 1
	  and r19_localidad = 2
	  and r19_cod_tran  = 'FA'
	  and date(r19_fecing) between mdy(12, 27, 2005) and mdy(12, 31, 2005)
	  and r38_compania  = r19_compania
	  and r38_localidad = r19_localidad
	  and r38_cod_tran  = r19_cod_tran
	  and r38_num_tran  = r19_num_tran
	order by 1, 2;

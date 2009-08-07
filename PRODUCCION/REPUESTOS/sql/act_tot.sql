update rept019
	set r19_tot_costo = 
	(select sum(r20_cant_ven * r20_costo)
		from rept020
	where r20_compania = r19_compania and
		r20_localidad = r19_localidad and
		r20_cod_tran  = r19_cod_tran and
		r20_num_tran  = r19_num_tran)
	where r19_cod_tran = 'IM'

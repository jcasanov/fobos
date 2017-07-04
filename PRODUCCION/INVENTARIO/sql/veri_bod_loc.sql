select r19_cod_tran, r19_num_tran, r19_fecing
	from rept019
  	where r19_compania    = 1
	  and r19_localidad   = 2
	  and r19_cod_tran    = 'TR'
	  and r19_bodega_ori  = 70
	  and r19_bodega_dest in
		(select r02_codigo from rept002
			where r02_localidad <> r19_localidad)
	order by r19_fecing desc;

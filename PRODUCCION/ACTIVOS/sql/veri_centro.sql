select a12_codigo_tran tp, a12_numero_tran num, a12_codigo_bien acti,
	a12_locali_ori lc
	from actt010, actt012
	where a10_compania    = 1
	  and a12_locali_ori  = 2
	  and a12_compania    = a10_compania
	  and a12_codigo_bien = a10_codigo_bien
	  and a12_locali_ori  <> a10_localidad
	order by 3, 1, 2

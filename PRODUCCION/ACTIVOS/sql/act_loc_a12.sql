begin work;

	update actt012
		set a12_locali_ori =
			(select a10_localidad
				from actt010
				where a10_compania    = a12_compania
				  and a10_codigo_bien = a12_codigo_bien)
		where a12_compania     = 1
		  and a12_codigo_bien in
			(select a10_codigo_bien
				from actt010
				where a10_compania  = a12_compania
				  and a10_localidad = 2);

commit work;

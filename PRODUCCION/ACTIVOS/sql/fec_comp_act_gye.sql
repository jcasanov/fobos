begin work;

	update actt010
		set a10_fecha_comp = mdy (01,03,2011)
		where a10_compania    = 1
		  and a10_codigo_bien in (1,4,8,5,159);

commit work;

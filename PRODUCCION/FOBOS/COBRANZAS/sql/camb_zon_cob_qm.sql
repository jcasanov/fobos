begin work;

	update cxct002
		set z02_zona_cobro = 27
		where z02_compania    = 1
		  and z02_zona_cobro in (12, 7, 24, 16);

commit work;

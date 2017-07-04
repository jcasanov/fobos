begin work;

	update cxct002
		set z02_zona_cobro = 4
		where z02_compania   = 1
		  and z02_zona_cobro = 1;

commit work;

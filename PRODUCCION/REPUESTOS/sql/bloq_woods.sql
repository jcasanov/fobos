set isolation to dirty read;
begin work;
	update rept010
		set r10_estado = 'B',
		    r10_feceli = current
	where r10_compania = 1
	  and r10_estado   = 'A'
	  and r10_marca    = 'WOODS';
commit work;
